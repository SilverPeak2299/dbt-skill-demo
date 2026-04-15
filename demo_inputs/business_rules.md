# Business Rules And Target Requirements

## Scenario

Retail banking analytics needs a governed dbt pipeline for a demo data mart that tracks customer account balances, card and account transactions, overdraft behaviour, fraud indicators, and regulatory reporting flags.

The pipeline is for a fictional Australian bank, Southern Cross Mutual Bank. The data is not production data. It is designed to test whether a dbt pipeline-generation skill can convert source table information, business rules, and source context into models, tests, and documentation.

## Business Objectives

1. Provide a trusted daily view of active retail customers and their open deposit accounts.
2. Produce an account transaction fact table with normalized transaction types, signed amounts, merchant enrichment, and fraud flags.
3. Create daily account balance snapshots for liquidity, overdraft, and customer activity reporting.
4. Identify customers and accounts subject to AML, KYC, sanctions, vulnerability, hardship, or privacy restrictions.
5. Serve generated dbt documentation through GitHub Pages after CI validation.

## Regulatory And Control Expectations

The generated dbt project should treat banking data as sensitive by default.

1. Personally identifiable information must not be exposed in marts unless explicitly required.
2. Raw customer names, email addresses, phone numbers, tax identifiers, and document numbers must be excluded from public documentation examples.
3. Customer identifiers in marts should use `customer_id` and not expose raw source natural keys where an internal surrogate can be generated.
4. Transaction models must preserve original source transaction identifiers for audit traceability.
5. Financial amounts must use decimal-compatible numeric types, not floating point.
6. Models should include tests for uniqueness, not-null constraints, accepted values, and referential integrity.
7. Hard-deleted customers must not be physically removed from history tables; they should be represented with status and validity dates.
8. Accounts closed during the reporting period must remain visible in historical snapshots.
9. All reporting dates must be interpreted in `Australia/Sydney` unless explicitly stated otherwise.
10. Any model that can drive customer decisions must include source freshness and data quality documentation.

## Target Model Overview

| Layer | Target model | Grain | Purpose |
| --- | --- | --- | --- |
| Staging | `stg_core_customers` | One row per source customer record | Clean customer identifiers, status, risk flags, and lifecycle dates |
| Staging | `stg_core_accounts` | One row per source account record | Clean account metadata, ownership, product, and open/close dates |
| Staging | `stg_core_transactions` | One row per source transaction | Standardize transaction types, amounts, timestamps, and status |
| Staging | `stg_core_card_transactions` | One row per card authorization or clearing record | Standardize card transaction details and merchant fields |
| Staging | `stg_risk_customer_flags` | One row per customer risk flag event | Normalize AML, KYC, sanctions, hardship, and vulnerability flags |
| Intermediate | `int_customer_account_relationships` | One row per customer-account relationship | Resolve owners, joint account holders, and authorized signatories |
| Intermediate | `int_transactions_normalized` | One row per financial transaction event | Union account and card transactions into a consistent signed transaction structure |
| Intermediate | `int_account_daily_balances` | One row per account per calendar day | Generate daily balance, overdraft, and activity indicators |
| Mart | `dim_customers` | One row per current customer | Current customer attributes safe for analytics |
| Mart | `dim_accounts` | One row per current account | Current account/product attributes and ownership summary |
| Mart | `fact_transactions` | One row per posted financial transaction | Customer and account transaction analytics |
| Mart | `fact_account_daily_snapshot` | One row per account per day | Balance, activity, and regulatory snapshot reporting |
| Mart | `mart_customer_risk_profile` | One row per customer per day | AML, KYC, hardship, vulnerability, and sanctions reporting flags |

## Source To Target Mappings

### Customer Dimension

| Source table | Source column | Target model | Target column | Transformation rule |
| --- | --- | --- | --- | --- |
| `core_customers` | `customer_id` | `dim_customers` | `customer_id` | Preserve as stable source identifier |
| `core_customers` | `customer_type` | `dim_customers` | `customer_type` | Accepted values: `PERSON`, `SOLE_TRADER`, `COMPANY`, `TRUST` |
| `core_customers` | `date_of_birth` | `dim_customers` | `age_band` | Derive age band at `current_date`; do not expose raw date of birth in mart |
| `core_customers` | `residency_status` | `dim_customers` | `residency_status` | Standardize blank or unknown values to `UNKNOWN` |
| `core_customers` | `customer_status` | `dim_customers` | `customer_status` | Accepted values: `ACTIVE`, `DORMANT`, `DECEASED`, `OFFBOARDED`, `SUSPENDED` |
| `core_customers` | `created_at` | `dim_customers` | `customer_created_at` | Convert to `Australia/Sydney` timestamp |
| `core_customers` | `closed_at` | `dim_customers` | `customer_closed_at` | Convert to `Australia/Sydney` timestamp; nullable |
| `risk_customer_flags` | `flag_type` | `dim_customers` | `has_active_risk_flag` | True if any current active flag exists for the customer |
| `risk_customer_flags` | `flag_type` | `mart_customer_risk_profile` | `aml_review_required` | True when active flag type is `AML_REVIEW` |
| `risk_customer_flags` | `flag_type` | `mart_customer_risk_profile` | `sanctions_screening_hit` | True when active flag type is `SANCTIONS_HIT` |
| `risk_customer_flags` | `flag_type` | `mart_customer_risk_profile` | `hardship_active` | True when active flag type is `FINANCIAL_HARDSHIP` |
| `risk_customer_flags` | `flag_type` | `mart_customer_risk_profile` | `vulnerable_customer` | True when active flag type is `VULNERABLE_CUSTOMER` |

### Account Dimension

| Source table | Source column | Target model | Target column | Transformation rule |
| --- | --- | --- | --- | --- |
| `core_accounts` | `account_id` | `dim_accounts` | `account_id` | Preserve as stable source identifier |
| `core_accounts` | `customer_id` | `dim_accounts` | `primary_customer_id` | Primary owner from source account record |
| `account_relationships` | `customer_id` | `int_customer_account_relationships` | `related_customer_id` | Include all owners, joint holders, trustees, and signatories |
| `account_relationships` | `relationship_type` | `dim_accounts` | `account_holder_type_summary` | Aggregate relationship types into comma-separated ordered list |
| `core_accounts` | `product_code` | `dim_accounts` | `product_code` | Preserve source product code |
| `core_accounts` | `account_type` | `dim_accounts` | `account_type` | Accepted values: `TRANSACTION`, `SAVINGS`, `TERM_DEPOSIT`, `OFFSET`, `CREDIT_CARD` |
| `core_accounts` | `currency_code` | `dim_accounts` | `currency_code` | Default to `AUD` only when null and product is domestic retail |
| `core_accounts` | `account_status` | `dim_accounts` | `account_status` | Accepted values: `OPEN`, `CLOSED`, `FROZEN`, `PENDING_CLOSE`, `CHARGED_OFF` |
| `core_accounts` | `opened_at` | `dim_accounts` | `opened_at` | Convert to `Australia/Sydney` timestamp |
| `core_accounts` | `closed_at` | `dim_accounts` | `closed_at` | Nullable; account remains available for history |

### Transaction Fact

| Source table | Source column | Target model | Target column | Transformation rule |
| --- | --- | --- | --- | --- |
| `core_transactions` | `transaction_id` | `fact_transactions` | `transaction_id` | Prefix with `ACCT-` in normalized layer to avoid collision with card transaction ids |
| `card_transactions` | `card_transaction_id` | `fact_transactions` | `transaction_id` | Prefix with `CARD-` in normalized layer |
| `core_transactions` | `account_id` | `fact_transactions` | `account_id` | Must join to `dim_accounts.account_id` |
| `card_transactions` | `account_id` | `fact_transactions` | `account_id` | Must join to `dim_accounts.account_id` |
| `core_transactions` | `posted_at` | `fact_transactions` | `posted_at` | Convert to `Australia/Sydney` timestamp |
| `card_transactions` | `cleared_at` | `fact_transactions` | `posted_at` | Use clearing timestamp when present; otherwise use authorization timestamp with `is_pending = true` |
| `core_transactions` | `transaction_type` | `fact_transactions` | `transaction_category` | Map source values to normalized categories listed below |
| `card_transactions` | `merchant_category_code` | `fact_transactions` | `merchant_category_code` | Preserve as string to keep leading zeroes |
| `card_transactions` | `merchant_name` | `fact_transactions` | `merchant_name_clean` | Trim, uppercase, collapse repeated spaces |
| `core_transactions` | `amount` | `fact_transactions` | `signed_amount` | Debits are negative, credits are positive |
| `card_transactions` | `settlement_amount` | `fact_transactions` | `signed_amount` | Purchases and cash advances are negative; refunds are positive |
| `core_transactions` | `currency_code` | `fact_transactions` | `currency_code` | Preserve source currency |
| `card_transactions` | `settlement_currency_code` | `fact_transactions` | `currency_code` | Preserve settlement currency |
| `core_transactions` | `transaction_status` | `fact_transactions` | `transaction_status` | Include only `POSTED` in default mart; retain pending in staging |
| `card_transactions` | `fraud_indicator` | `fact_transactions` | `is_fraud_suspected` | True when source is `Y`; false when `N`; null only when unavailable |

### Daily Account Snapshot

| Source table | Source column | Target model | Target column | Transformation rule |
| --- | --- | --- | --- | --- |
| `daily_account_balances` | `balance_date` | `fact_account_daily_snapshot` | `snapshot_date` | Date in `Australia/Sydney` |
| `daily_account_balances` | `account_id` | `fact_account_daily_snapshot` | `account_id` | Must join to `dim_accounts.account_id` |
| `daily_account_balances` | `ledger_balance` | `fact_account_daily_snapshot` | `ledger_balance` | Decimal amount in account currency |
| `daily_account_balances` | `available_balance` | `fact_account_daily_snapshot` | `available_balance` | Decimal amount in account currency |
| `daily_account_balances` | `overdraft_limit` | `fact_account_daily_snapshot` | `overdraft_limit` | Null means no approved overdraft |
| `daily_account_balances` | `arrears_days` | `fact_account_daily_snapshot` | `arrears_days` | Default null to zero only for open accounts |
| `fact_transactions` | `signed_amount` | `fact_account_daily_snapshot` | `transaction_count` | Count posted transactions for the account on the snapshot date |
| `fact_transactions` | `signed_amount` | `fact_account_daily_snapshot` | `net_transaction_amount` | Sum signed transaction amounts for the account on the snapshot date |

## Transaction Category Normalization

| Source system | Source value | Normalized `transaction_category` | Signed amount rule |
| --- | --- | --- | --- |
| Core banking | `DEP` | `DEPOSIT` | Positive |
| Core banking | `WDR` | `WITHDRAWAL` | Negative |
| Core banking | `FEE` | `FEE` | Negative |
| Core banking | `INT_CR` | `INTEREST_CREDIT` | Positive |
| Core banking | `INT_DR` | `INTEREST_DEBIT` | Negative |
| Core banking | `BPAY` | `BPAY_PAYMENT` | Negative unless reversal flag is true |
| Core banking | `OSKO_IN` | `FAST_PAYMENT_IN` | Positive |
| Core banking | `OSKO_OUT` | `FAST_PAYMENT_OUT` | Negative |
| Core banking | `REV` | `REVERSAL` | Use source `debit_credit_indicator` |
| Card processor | `PURCHASE` | `CARD_PURCHASE` | Negative |
| Card processor | `REFUND` | `CARD_REFUND` | Positive |
| Card processor | `CASH_ADVANCE` | `CASH_ADVANCE` | Negative |
| Card processor | `CHARGEBACK` | `CHARGEBACK` | Positive |

## Required dbt Tests

| Model | Test requirement |
| --- | --- |
| `stg_core_customers` | `customer_id` is unique and not null |
| `stg_core_customers` | `customer_status` accepted values match the business rule list |
| `stg_core_accounts` | `account_id` is unique and not null |
| `stg_core_accounts` | `customer_id` is not null and references `stg_core_customers.customer_id` |
| `stg_core_transactions` | `transaction_id` is unique and not null |
| `stg_core_transactions` | `account_id` references `stg_core_accounts.account_id` |
| `stg_core_transactions` | `amount` is not null and greater than or equal to zero before signing |
| `stg_core_card_transactions` | `card_transaction_id` is unique and not null |
| `stg_core_card_transactions` | `merchant_category_code` is string typed |
| `int_transactions_normalized` | `transaction_id` is unique and not null after prefixing |
| `int_transactions_normalized` | `signed_amount` is not null |
| `fact_transactions` | `transaction_status` equals `POSTED` unless `is_pending` is true |
| `fact_account_daily_snapshot` | Composite key `account_id`, `snapshot_date` is unique |
| `mart_customer_risk_profile` | Composite key `customer_id`, `snapshot_date` is unique |

## Required Documentation

Each generated model should include:

1. A plain-English model description.
2. Grain.
3. Source tables used.
4. Key business rules.
5. Important tests.
6. Any privacy or regulatory handling.
7. Known limitations for demo data.

## Acceptance Criteria For The Demo

1. The skill can generate a dbt project using DuckDB as the local warehouse.
2. The skill creates source definitions for all source tables described in `source_data_description.md`.
3. The skill creates staging, intermediate, and mart models based on the target model overview.
4. The skill creates schema YAML files with descriptions and tests.
5. The skill creates a GitHub Actions workflow that runs dbt build and publishes dbt docs to GitHub Pages.
6. The skill keeps sensitive fields out of mart models unless a business rule explicitly requires them.
7. The generated documentation explains lineage from source to mart models.
