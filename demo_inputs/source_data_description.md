# Source Data Description

## Purpose

This file describes fictional raw source tables that can later be generated as CSV, Parquet, or direct DuckDB tables for the demo. The source data represents a small retail banking estate with core banking, card processing, customer risk, and balance snapshot feeds.

All source tables should be loaded into the DuckDB schema `raw_bank`.

## Source Tables

| Source table | Source system | Load type | Expected volume for demo | Primary key |
| --- | --- | --- | --- | --- |
| `core_customers` | Core banking customer master | Full daily snapshot | 500 to 2,000 rows | `customer_id` |
| `core_accounts` | Core banking account master | Full daily snapshot | 800 to 3,000 rows | `account_id` |
| `account_relationships` | Core banking relationship service | Full daily snapshot | 900 to 4,000 rows | `relationship_id` |
| `core_transactions` | Core banking transaction ledger | Incremental daily extract | 10,000 to 100,000 rows | `transaction_id` |
| `card_transactions` | Card processor | Incremental daily extract | 5,000 to 50,000 rows | `card_transaction_id` |
| `daily_account_balances` | Core banking balance snapshot | Daily snapshot partition | One row per account per date | `account_id`, `balance_date` |
| `risk_customer_flags` | Financial crime and customer care systems | Incremental event extract | 100 to 5,000 rows | `risk_flag_id` |
| `branch_reference` | Branch reference data | Full monthly snapshot | 20 to 200 rows | `branch_id` |
| `product_reference` | Product reference data | Full monthly snapshot | 20 to 100 rows | `product_code` |

## Table: `core_customers`

One row per customer in the customer master. Contains sensitive PII and lifecycle data.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `customer_id` | `VARCHAR` | No | Stable customer identifier from core banking | `C100045` |
| `customer_type` | `VARCHAR` | No | Customer legal type | `PERSON` |
| `given_name` | `VARCHAR` | Yes | Customer first name; PII | `Ava` |
| `family_name` | `VARCHAR` | Yes | Customer last name; PII | `Nguyen` |
| `business_name` | `VARCHAR` | Yes | Business or trust name when applicable; PII | `Nguyen Family Trust` |
| `date_of_birth` | `DATE` | Yes | Date of birth for natural persons; PII | `1984-11-02` |
| `email_address` | `VARCHAR` | Yes | Primary email address; PII | `ava.nguyen@example.test` |
| `mobile_number` | `VARCHAR` | Yes | Primary mobile phone; PII | `+61400111222` |
| `tax_residency_country` | `VARCHAR` | Yes | ISO country code used for tax reporting | `AU` |
| `residency_status` | `VARCHAR` | Yes | Customer residency status | `RESIDENT` |
| `customer_status` | `VARCHAR` | No | Current customer lifecycle status | `ACTIVE` |
| `privacy_opt_out` | `BOOLEAN` | No | Customer has opted out of optional marketing analytics | `false` |
| `created_at` | `TIMESTAMP` | No | Source creation timestamp, UTC | `2019-03-14 02:43:12` |
| `updated_at` | `TIMESTAMP` | No | Last source update timestamp, UTC | `2026-04-14 21:10:03` |
| `closed_at` | `TIMESTAMP` | Yes | Customer closure timestamp, UTC | `NULL` |

## Table: `core_accounts`

One row per deposit, offset, term deposit, or credit card account in the core banking platform.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `account_id` | `VARCHAR` | No | Stable account identifier | `A90001234` |
| `customer_id` | `VARCHAR` | No | Primary customer owner | `C100045` |
| `product_code` | `VARCHAR` | No | Product code from product catalogue | `TXN_EVERYDAY` |
| `account_type` | `VARCHAR` | No | High-level account type | `TRANSACTION` |
| `bsb` | `VARCHAR` | Yes | Six-digit Australian BSB; sensitive | `062000` |
| `masked_account_number` | `VARCHAR` | Yes | Masked account number only | `****1234` |
| `currency_code` | `VARCHAR` | No | ISO currency code | `AUD` |
| `account_status` | `VARCHAR` | No | Account lifecycle status | `OPEN` |
| `branch_id` | `VARCHAR` | Yes | Origination branch | `B014` |
| `opened_at` | `TIMESTAMP` | No | Account opened timestamp, UTC | `2020-07-10 04:22:00` |
| `closed_at` | `TIMESTAMP` | Yes | Account closed timestamp, UTC | `NULL` |
| `updated_at` | `TIMESTAMP` | No | Last source update timestamp, UTC | `2026-04-14 20:05:48` |

## Table: `account_relationships`

Associates customers with accounts. An account can have multiple customers and a customer can relate to multiple accounts.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `relationship_id` | `VARCHAR` | No | Stable relationship identifier | `R700001` |
| `account_id` | `VARCHAR` | No | Account identifier | `A90001234` |
| `customer_id` | `VARCHAR` | No | Related customer identifier | `C100045` |
| `relationship_type` | `VARCHAR` | No | `PRIMARY_OWNER`, `JOINT_OWNER`, `SIGNATORY`, `TRUSTEE`, `GUARANTOR` | `PRIMARY_OWNER` |
| `relationship_start_date` | `DATE` | No | Date relationship became active | `2020-07-10` |
| `relationship_end_date` | `DATE` | Yes | Date relationship ended | `NULL` |
| `is_authorized_to_transact` | `BOOLEAN` | No | Whether the customer can transact on the account | `true` |
| `updated_at` | `TIMESTAMP` | No | Last source update timestamp, UTC | `2026-04-14 20:07:22` |

## Table: `core_transactions`

One row per non-card financial transaction in the core banking ledger.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `transaction_id` | `VARCHAR` | No | Core banking transaction identifier | `T2026041400001` |
| `account_id` | `VARCHAR` | No | Account posted to | `A90001234` |
| `posted_at` | `TIMESTAMP` | No | Posting timestamp, UTC | `2026-04-14 03:17:45` |
| `effective_date` | `DATE` | No | Accounting effective date | `2026-04-14` |
| `transaction_type` | `VARCHAR` | No | Source transaction code | `OSKO_IN` |
| `transaction_description` | `VARCHAR` | Yes | Free-text transaction description | `PAYMENT FROM J SMITH` |
| `amount` | `DECIMAL(18,2)` | No | Absolute transaction amount before signing | `245.75` |
| `currency_code` | `VARCHAR` | No | ISO currency code | `AUD` |
| `debit_credit_indicator` | `VARCHAR` | No | Source direction marker: `D` or `C` | `C` |
| `transaction_status` | `VARCHAR` | No | `PENDING`, `POSTED`, `REVERSED`, `FAILED` | `POSTED` |
| `reversal_indicator` | `BOOLEAN` | No | Whether this transaction reverses another transaction | `false` |
| `original_transaction_id` | `VARCHAR` | Yes | Original transaction when reversed | `NULL` |
| `ingested_at` | `TIMESTAMP` | No | Ingestion timestamp, UTC | `2026-04-14 14:15:00` |

## Table: `card_transactions`

One row per card authorization or clearing record from the card processor.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `card_transaction_id` | `VARCHAR` | No | Card processor transaction identifier | `CT99887766` |
| `account_id` | `VARCHAR` | No | Funding account identifier | `A90001234` |
| `card_id_hash` | `VARCHAR` | No | Hashed card identifier | `6d7f8c9b3a` |
| `authorization_at` | `TIMESTAMP` | No | Authorization timestamp, UTC | `2026-04-14 06:41:19` |
| `cleared_at` | `TIMESTAMP` | Yes | Clearing timestamp, UTC | `2026-04-15 01:02:11` |
| `card_transaction_type` | `VARCHAR` | No | `PURCHASE`, `REFUND`, `CASH_ADVANCE`, `CHARGEBACK` | `PURCHASE` |
| `merchant_name` | `VARCHAR` | Yes | Merchant display name | `SYDNEY METRO` |
| `merchant_category_code` | `VARCHAR` | Yes | MCC as string | `4111` |
| `merchant_country_code` | `VARCHAR` | Yes | ISO country code | `AU` |
| `authorization_amount` | `DECIMAL(18,2)` | No | Amount authorized in transaction currency | `8.40` |
| `authorization_currency_code` | `VARCHAR` | No | ISO currency code at authorization | `AUD` |
| `settlement_amount` | `DECIMAL(18,2)` | Yes | Final settlement amount | `8.40` |
| `settlement_currency_code` | `VARCHAR` | Yes | ISO currency code at settlement | `AUD` |
| `card_transaction_status` | `VARCHAR` | No | `AUTHORIZED`, `CLEARED`, `DECLINED`, `REVERSED` | `CLEARED` |
| `fraud_indicator` | `VARCHAR` | Yes | `Y`, `N`, or null when not assessed | `N` |
| `decline_reason_code` | `VARCHAR` | Yes | Processor decline reason when applicable | `NULL` |
| `ingested_at` | `TIMESTAMP` | No | Ingestion timestamp, UTC | `2026-04-15 03:30:00` |

## Table: `daily_account_balances`

One row per account per calendar day from the core banking end-of-day balance process.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `account_id` | `VARCHAR` | No | Account identifier | `A90001234` |
| `balance_date` | `DATE` | No | Balance date in Australia/Sydney | `2026-04-14` |
| `ledger_balance` | `DECIMAL(18,2)` | No | Posted ledger balance | `1420.36` |
| `available_balance` | `DECIMAL(18,2)` | No | Available balance after holds and limits | `1378.26` |
| `overdraft_limit` | `DECIMAL(18,2)` | Yes | Approved overdraft limit | `500.00` |
| `arrears_days` | `INTEGER` | Yes | Days in arrears for credit products | `0` |
| `currency_code` | `VARCHAR` | No | ISO currency code | `AUD` |
| `snapshot_created_at` | `TIMESTAMP` | No | Snapshot creation timestamp, UTC | `2026-04-14 15:30:00` |

## Table: `risk_customer_flags`

Event-style feed of active and inactive risk or care flags from financial crime and customer care platforms.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `risk_flag_id` | `VARCHAR` | No | Stable flag event identifier | `F600012` |
| `customer_id` | `VARCHAR` | No | Customer identifier | `C100045` |
| `flag_type` | `VARCHAR` | No | `AML_REVIEW`, `KYC_EXPIRED`, `SANCTIONS_HIT`, `FINANCIAL_HARDSHIP`, `VULNERABLE_CUSTOMER`, `PRIVACY_RESTRICTED` | `KYC_EXPIRED` |
| `flag_status` | `VARCHAR` | No | `ACTIVE`, `CLEARED`, `FALSE_POSITIVE`, `EXPIRED` | `ACTIVE` |
| `flag_start_date` | `DATE` | No | Date flag became effective | `2026-04-10` |
| `flag_end_date` | `DATE` | Yes | Date flag stopped being effective | `NULL` |
| `severity` | `VARCHAR` | Yes | `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` | `MEDIUM` |
| `source_case_id` | `VARCHAR` | Yes | Case identifier in source system | `CASE-12345` |
| `updated_at` | `TIMESTAMP` | No | Last source update timestamp, UTC | `2026-04-14 23:05:00` |

## Table: `branch_reference`

Reference data for branch and channel reporting.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `branch_id` | `VARCHAR` | No | Branch identifier | `B014` |
| `branch_name` | `VARCHAR` | No | Branch display name | `Parramatta` |
| `state_code` | `VARCHAR` | No | Australian state or territory | `NSW` |
| `region_name` | `VARCHAR` | Yes | Internal operating region | `Sydney Metro` |
| `is_active` | `BOOLEAN` | No | Active branch flag | `true` |
| `updated_at` | `TIMESTAMP` | No | Last source update timestamp, UTC | `2026-04-01 00:00:00` |

## Table: `product_reference`

Reference data for retail banking products.

| Column | Type | Nullable | Description | Example |
| --- | --- | --- | --- | --- |
| `product_code` | `VARCHAR` | No | Product identifier | `TXN_EVERYDAY` |
| `product_name` | `VARCHAR` | No | Product display name | `Everyday Transaction Account` |
| `product_family` | `VARCHAR` | No | `DEPOSITS`, `CARDS`, `MORTGAGES`, `PERSONAL_LENDING` | `DEPOSITS` |
| `account_type` | `VARCHAR` | No | Account type used for grouping | `TRANSACTION` |
| `is_offset_eligible` | `BOOLEAN` | No | Product can offset a mortgage | `false` |
| `is_interest_bearing` | `BOOLEAN` | No | Product accrues customer interest | `false` |
| `updated_at` | `TIMESTAMP` | No | Last source update timestamp, UTC | `2026-04-01 00:00:00` |

## DuckDB Type Guidance

The demo generator should prefer these type mappings when creating local source data:

| Logical field | DuckDB type |
| --- | --- |
| Identifiers and codes | `VARCHAR` |
| Dates | `DATE` |
| Timestamps | `TIMESTAMP` |
| Money | `DECIMAL(18,2)` |
| Counts and days | `INTEGER` |
| Booleans | `BOOLEAN` |

## Demo Data Generation Notes

1. Use deterministic fake data and avoid real customer data.
2. Keep `customer_id`, `account_id`, and transaction identifiers stable across generated runs where possible.
3. Generate a mix of active, dormant, closed, frozen, hardship, and AML-review examples.
4. Include at least five joint accounts to test relationship logic.
5. Include at least one account with a negative available balance and an approved overdraft.
6. Include card authorizations that have not cleared to test pending transaction logic.
7. Include reversed transactions to test reversal handling.
8. Include merchant category codes with leading zeroes if possible to ensure string preservation.
9. Include one or two privacy-restricted customers to verify marts exclude unnecessary PII.
10. Use source timestamps in UTC and reporting dates in `Australia/Sydney`.
