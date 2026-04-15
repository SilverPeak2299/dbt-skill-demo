# Source-To-Target Mapping

Pipeline context: Southern Cross Mutual Bank retail banking analytics demo.

| Target model | Target column | Source table | Source column | Transformation logic | Business rule reference | Data quality expectation | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `dim_customers` | `customer_id` | `core_customers` | `customer_id` | Preserve stable source identifier. | Customer Dimension | Not null, unique. | Raw natural customer key is acceptable for the demo mart. |
| `dim_customers` | `customer_type` | `core_customers` | `customer_type` | Uppercase and trim. | Customer Dimension | Accepted values: `PERSON`, `SOLE_TRADER`, `COMPANY`, `TRUST`. | No names or contact details exposed. |
| `dim_customers` | `age_band` | `core_customers` | `date_of_birth` | Derive completed-age band at `current_date`; do not expose date of birth. | Customer Dimension, Privacy Controls | Null dates become `NOT_APPLICABLE`. | Uses DuckDB date functions and adjusts for birthdays not yet reached. |
| `dim_customers` | `tax_residency_country` | `core_customers` | `tax_residency_country` | Uppercase and trim ISO country code. | Customer Dimension | Nullable. | Not a direct contact identifier. |
| `dim_customers` | `residency_status` | `core_customers` | `residency_status` | Standardize blank or unknown values to `UNKNOWN`. | Customer Dimension | Not null after standardization. |  |
| `dim_customers` | `customer_status` | `core_customers` | `customer_status` | Uppercase and trim. | Customer Dimension | Accepted values: `ACTIVE`, `DORMANT`, `DECEASED`, `OFFBOARDED`, `SUSPENDED`. | Hard-deleted customers are represented by status and dates. |
| `dim_customers` | `privacy_opt_out` | `core_customers` | `privacy_opt_out` | Preserve boolean. | Privacy Controls | Not null in source. |  |
| `dim_customers` | `has_active_risk_flag` | `risk_customer_flags` | `flag_status`, `flag_start_date`, `flag_end_date` | True when any active flag is effective at `current_date`. | Risk Flag Context | Boolean, defaults false. | Source case id is not exposed. |
| `dim_customers` | `privacy_restricted` | `risk_customer_flags` | `flag_type` | True when active `PRIVACY_RESTRICTED` flag is effective. | Risk Flag Context | Boolean, defaults false. |  |
| `dim_customers` | `kyc_expired` | `risk_customer_flags` | `flag_type` | True when active `KYC_EXPIRED` flag is effective. | Risk Flag Context | Boolean, defaults false. |  |
| `dim_customers` | `customer_created_at` | `core_customers` | `created_at` | Convert UTC timestamp to `Australia/Sydney`. | Time Zone Rules | Not null in source. |  |
| `dim_customers` | `customer_updated_at` | `core_customers` | `updated_at` | Convert UTC timestamp to `Australia/Sydney`. | Time Zone Rules | Not null in source. |  |
| `dim_customers` | `customer_closed_at` | `core_customers` | `closed_at` | Convert UTC timestamp to `Australia/Sydney`; nullable. | Customer Dimension | Nullable. |  |
| `dim_accounts` | `account_id` | `core_accounts` | `account_id` | Preserve stable source identifier. | Account Dimension | Not null, unique. |  |
| `dim_accounts` | `primary_customer_id` | `core_accounts` | `customer_id` | Preserve primary owner from account master. | Account Dimension | References `dim_customers.customer_id`. | Full relationship set is retained in the intermediate model. |
| `dim_accounts` | `account_holder_type_summary` | `account_relationships` | `relationship_type` | Aggregate active relationship types into comma-separated ordered list. | Account Dimension | Defaults `UNMAPPED` when no relationship exists. | Uses current relationships only. |
| `dim_accounts` | `related_customer_count` | `account_relationships` | `customer_id` | Count distinct active related customers. | Account Relationship Context | Non-negative integer. |  |
| `dim_accounts` | `authorized_customer_count` | `account_relationships` | `is_authorized_to_transact` | Count distinct active related customers authorized to transact. | Account Relationship Context | Non-negative integer. |  |
| `dim_accounts` | `product_code` | `core_accounts` | `product_code` | Preserve product code. | Account Dimension | References product reference where available. |  |
| `dim_accounts` | `product_name` | `product_reference` | `product_name` | Join by product code. | Reference Data Context | Nullable if reference data missing. |  |
| `dim_accounts` | `product_family` | `product_reference` | `product_family` | Join by product code. | Reference Data Context | Accepted values in staging. |  |
| `dim_accounts` | `account_type` | `core_accounts`, `product_reference` | `account_type` | Use account source value; fall back to product reference value. | Account Dimension | Accepted values in staging. |  |
| `dim_accounts` | `currency_code` | `core_accounts` | `currency_code` | Preserve source currency; default `AUD` only when null. | Account Dimension | Not null after standardization. | Currency conversion is out of scope. |
| `dim_accounts` | `account_status` | `core_accounts` | `account_status` | Uppercase and trim. | Account Dimension | Accepted values in staging. | Closed accounts remain visible. |
| `dim_accounts` | `branch_id` | `core_accounts` | `branch_id` | Preserve branch id. | Reference Data Context | Nullable. |  |
| `dim_accounts` | `branch_name` | `branch_reference` | `branch_name` | Join by branch id. | Reference Data Context | Nullable if reference data missing. |  |
| `dim_accounts` | `state_code` | `branch_reference` | `state_code` | Join by branch id. | Reference Data Context | Nullable if reference data missing. |  |
| `dim_accounts` | `region_name` | `branch_reference` | `region_name` | Join by branch id. | Reference Data Context | Nullable. |  |
| `dim_accounts` | `is_offset_eligible` | `product_reference` | `is_offset_eligible` | Join by product code. | Reference Data Context | Boolean. |  |
| `dim_accounts` | `is_interest_bearing` | `product_reference` | `is_interest_bearing` | Join by product code. | Reference Data Context | Boolean. |  |
| `dim_accounts` | `opened_at` | `core_accounts` | `opened_at` | Convert UTC timestamp to `Australia/Sydney`. | Time Zone Rules | Not null in source. |  |
| `dim_accounts` | `closed_at` | `core_accounts` | `closed_at` | Convert UTC timestamp to `Australia/Sydney`; nullable. | Account Dimension | Nullable. |  |
| `dim_accounts` | `account_updated_at` | `core_accounts` | `updated_at` | Convert UTC timestamp to `Australia/Sydney`. | Time Zone Rules | Not null in source. |  |
| `fact_transactions` | `transaction_id` | `core_transactions`, `card_transactions` | `transaction_id`, `card_transaction_id` | Prefix core ids with `ACCT-`; prefix card ids with `CARD-`. | Transaction Fact | Not null, unique. | Preserves audit traceability. |
| `fact_transactions` | `source_transaction_id` | `core_transactions`, `card_transactions` | `transaction_id`, `card_transaction_id` | Preserve original source transaction id. | Regulatory Controls | Not null for all fact rows. |  |
| `fact_transactions` | `source_system` | Source table | Source table | Derive `CORE_BANKING` or `CARD_PROCESSOR`. | Systems Of Record | Accepted by transformation logic. |  |
| `fact_transactions` | `account_id` | `core_transactions`, `card_transactions` | `account_id` | Preserve and join to `dim_accounts`. | Transaction Fact | References `dim_accounts.account_id`. |  |
| `fact_transactions` | `customer_id` | `dim_accounts` | `primary_customer_id` | Assign primary customer owner of the account. | Account Dimension | References `dim_customers.customer_id` through account dimension. | Joint relationships remain in intermediate model. |
| `fact_transactions` | `product_code` | `dim_accounts` | `product_code` | Enrich from account dimension. | Reporting Needs | Nullable only if source account missing product. |  |
| `fact_transactions` | `account_type` | `dim_accounts` | `account_type` | Enrich from account dimension. | Reporting Needs | Accepted values in account dimension. |  |
| `fact_transactions` | `posted_at` | `core_transactions`, `card_transactions` | `posted_at`, `cleared_at`, `authorization_at` | Convert core posted timestamp; use card clearing timestamp when present, otherwise authorization timestamp. | Time Zone Rules, Transaction Fact | Not null for included rows. | Pending card authorizations use authorization timestamp. |
| `fact_transactions` | `posted_date` | `posted_at` | Derived | Cast local posted timestamp to date. | Time Zone Rules | Not null for included rows. |  |
| `fact_transactions` | `transaction_category` | `core_transactions`, `card_transactions` | `transaction_type`, `card_transaction_type` | Map source transaction codes to normalized categories. | Transaction Category Normalization | Should not be `UNMAPPED` for known source values. |  |
| `fact_transactions` | `merchant_category_code` | `card_transactions` | `merchant_category_code` | Preserve as string. | Transaction Fact | Nullable for core transactions. | Retains leading zeroes. |
| `fact_transactions` | `merchant_name_clean` | `card_transactions` | `merchant_name` | Trim, uppercase, collapse repeated spaces. | Transaction Fact | Nullable for core transactions. |  |
| `fact_transactions` | `merchant_country_code` | `card_transactions` | `merchant_country_code` | Uppercase and trim. | Transaction Fact | Nullable for core transactions. |  |
| `fact_transactions` | `signed_amount` | `core_transactions`, `card_transactions` | `amount`, `settlement_amount`, `authorization_amount` | Debits negative and credits positive using source type and direction rules. | Transaction Category Normalization | Not null. | Decimal-compatible numeric type. |
| `fact_transactions` | `currency_code` | `core_transactions`, `card_transactions` | `currency_code`, `settlement_currency_code`, `authorization_currency_code` | Preserve source or settlement currency. | Known Demo Limitations | Not null for included rows. | No currency conversion. |
| `fact_transactions` | `transaction_status` | `core_transactions`, `card_transactions` | `transaction_status`, `card_transaction_status` | Normalize cleared card transactions to `POSTED`; authorization-only rows become `PENDING`. | Transaction Fact | Must be `POSTED` unless `is_pending` is true. | Declined and failed rows excluded from mart. |
| `fact_transactions` | `is_pending` | `core_transactions`, `card_transactions` | `transaction_status`, `card_transaction_status`, `cleared_at` | True for pending core rows and authorization-only card transactions. | Transaction Fact | Boolean. |  |
| `fact_transactions` | `is_fraud_suspected` | `card_transactions` | `fraud_indicator` | `Y` -> true, `N` -> false, null when unavailable. | Transaction Fact | Nullable for core transactions. | Fraud indicator is suspicion only. |
| `fact_transactions` | `reversal_indicator` | `core_transactions` | `reversal_indicator` | Preserve for core transactions; false for card transactions. | Transaction Fact | Boolean. |  |
| `fact_transactions` | `original_transaction_id` | `core_transactions` | `original_transaction_id` | Preserve original source transaction when reversed. | Regulatory Controls | Nullable. |  |
| `fact_transactions` | `ingested_at` | `core_transactions`, `card_transactions` | `ingested_at` | Convert UTC ingestion timestamp to `Australia/Sydney`. | Data Quality Expectations | Not null in sources. |  |
| `fact_account_daily_snapshot` | `account_id` | `daily_account_balances` | `account_id` | Preserve and join to `dim_accounts`. | Daily Account Snapshot | Not null, part of unique composite key. |  |
| `fact_account_daily_snapshot` | `customer_id` | `dim_accounts` | `primary_customer_id` | Assign primary customer owner. | Account Dimension | References customer dimension through account dimension. |  |
| `fact_account_daily_snapshot` | `snapshot_date` | `daily_account_balances` | `balance_date` | Preserve Australia/Sydney business date. | Daily Account Snapshot | Not null, part of unique composite key. |  |
| `fact_account_daily_snapshot` | `ledger_balance` | `daily_account_balances` | `ledger_balance` | Preserve decimal amount. | Daily Account Snapshot | Not null. |  |
| `fact_account_daily_snapshot` | `available_balance` | `daily_account_balances` | `available_balance` | Preserve decimal amount. | Daily Account Snapshot | Not null. |  |
| `fact_account_daily_snapshot` | `overdraft_limit` | `daily_account_balances` | `overdraft_limit` | Preserve decimal amount; null means no approved overdraft. | Daily Account Snapshot | Nullable. |  |
| `fact_account_daily_snapshot` | `arrears_days` | `daily_account_balances` | `arrears_days` | Default null to zero only for open accounts. | Daily Account Snapshot | Nullable for closed or non-applicable accounts. |  |
| `fact_account_daily_snapshot` | `currency_code` | `daily_account_balances` | `currency_code` | Preserve source currency. | Daily Account Snapshot | Not null. |  |
| `fact_account_daily_snapshot` | `transaction_count` | `fact_transactions` | `transaction_id` | Count posted non-pending transactions by account and snapshot date. | Daily Account Snapshot | Non-negative integer. | Pending rows excluded from activity count. |
| `fact_account_daily_snapshot` | `net_transaction_amount` | `fact_transactions` | `signed_amount` | Sum posted signed amounts by account and snapshot date. | Daily Account Snapshot | Defaults to zero when no activity. |  |
| `fact_account_daily_snapshot` | `is_overdrawn` | `daily_account_balances` | `available_balance` | True when available balance is negative. | Balance Data Context | Boolean. |  |
| `fact_account_daily_snapshot` | `is_over_limit` | `daily_account_balances` | `available_balance`, `overdraft_limit` | True when available balance is below approved overdraft coverage. | Balance Data Context | Boolean. |  |
| `fact_account_daily_snapshot` | `has_transaction_activity` | `fact_transactions` | `transaction_id` | True when posted transaction count is greater than zero. | Daily Account Snapshot | Boolean. |  |
| `fact_account_daily_snapshot` | `account_status` | `dim_accounts` | `account_status` | Enrich from account dimension. | Account Dimension | Accepted values. | Closed accounts remain visible. |
| `fact_account_daily_snapshot` | `account_type` | `dim_accounts` | `account_type` | Enrich from account dimension. | Account Dimension | Accepted values. |  |
| `fact_account_daily_snapshot` | `product_code` | `dim_accounts` | `product_code` | Enrich from account dimension. | Reporting Needs | Nullable only when account reference missing. |  |
| `fact_account_daily_snapshot` | `product_family` | `dim_accounts` | `product_family` | Enrich from account dimension. | Reporting Needs | Nullable only when product reference missing. |  |
| `fact_account_daily_snapshot` | `snapshot_created_at` | `daily_account_balances` | `snapshot_created_at` | Convert UTC timestamp to `Australia/Sydney`. | Data Delivery Pattern | Not null in source. |  |
| `mart_customer_risk_profile` | `customer_id` | `dim_customers` | `customer_id` | Preserve customer identifier. | Risk Flag Context | Not null, part of unique composite key. |  |
| `mart_customer_risk_profile` | `snapshot_date` | `fact_account_daily_snapshot` | `snapshot_date` | Use available account snapshot dates as risk profile dates. | Target Model Overview | Not null, part of unique composite key. | Assumption: demo risk profiles align to balance snapshot dates. |
| `mart_customer_risk_profile` | `customer_type` | `dim_customers` | `customer_type` | Enrich from customer dimension. | Customer Dimension | Accepted values in staging. |  |
| `mart_customer_risk_profile` | `customer_status` | `dim_customers` | `customer_status` | Enrich from customer dimension. | Customer Dimension | Accepted values in staging. |  |
| `mart_customer_risk_profile` | `privacy_opt_out` | `dim_customers` | `privacy_opt_out` | Enrich from customer dimension. | Privacy Controls | Boolean. |  |
| `mart_customer_risk_profile` | `aml_review_required` | `risk_customer_flags` | `flag_type`, `flag_status` | True when active `AML_REVIEW` flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `kyc_expired` | `risk_customer_flags` | `flag_type`, `flag_status` | True when active `KYC_EXPIRED` flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `sanctions_screening_hit` | `risk_customer_flags` | `flag_type`, `flag_status` | True when active `SANCTIONS_HIT` flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `hardship_active` | `risk_customer_flags` | `flag_type`, `flag_status` | True when active `FINANCIAL_HARDSHIP` flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `vulnerable_customer` | `risk_customer_flags` | `flag_type`, `flag_status` | True when active `VULNERABLE_CUSTOMER` flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `privacy_restricted` | `risk_customer_flags` | `flag_type`, `flag_status` | True when active `PRIVACY_RESTRICTED` flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `has_any_active_risk_flag` | `risk_customer_flags` | `flag_status` | True when any active flag is effective on snapshot date. | Risk Flag Context | Boolean, defaults false. |  |
| `mart_customer_risk_profile` | `latest_risk_flag_updated_at` | `risk_customer_flags` | `updated_at` | Latest local risk flag update timestamp across flags effective on snapshot date. | Data Quality Expectations | Nullable when no flags exist. | Source case id is not exposed. |
