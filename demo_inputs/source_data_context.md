# Source Data Context

## Source Estate Summary

Southern Cross Mutual Bank uses a legacy core banking platform for customer, account, balance, and ledger records. Card events are received from a separate card processor. Risk and care flags are sourced from financial crime, KYC, hardship, and customer vulnerability case-management tools.

The demo assumes the raw data has already landed in object storage or local files and is then loaded into DuckDB under the schema `raw_bank`.

## Systems Of Record

| Domain | System of record | Tables | Notes |
| --- | --- | --- | --- |
| Customer master | Core banking platform | `core_customers` | Source of truth for customer lifecycle status and basic identity attributes |
| Account master | Core banking platform | `core_accounts`, `account_relationships` | Source of truth for account ownership, product assignment, and account status |
| Ledger transactions | Core banking platform | `core_transactions` | Source of truth for posted non-card account movements |
| Card activity | Card processor | `card_transactions` | Source of truth for card authorizations, clearings, refunds, and card fraud indicators |
| Balances | Core banking end-of-day process | `daily_account_balances` | Source of truth for end-of-day ledger and available balances |
| Risk and customer care | Case-management platforms | `risk_customer_flags` | Source of active regulatory, financial crime, hardship, and care flags |
| Reference data | Product and branch administration | `product_reference`, `branch_reference` | Low-volume slowly changing reference data |

## Data Delivery Pattern

| Feed | Frequency | Arrival expectation | Late-arriving behaviour |
| --- | --- | --- | --- |
| Customer snapshot | Daily | By 06:00 Australia/Sydney | Same-day corrections arrive in next daily snapshot |
| Account snapshot | Daily | By 06:15 Australia/Sydney | Same-day corrections arrive in next daily snapshot |
| Account relationships | Daily | By 06:20 Australia/Sydney | Relationship end dates may be backdated |
| Core transactions | Daily incremental | By 07:00 Australia/Sydney | Reversals can arrive up to 30 days after original posting |
| Card transactions | Multiple daily batches | By 09:00, 13:00, 18:00 Australia/Sydney | Clearings can arrive 1 to 5 days after authorization |
| Daily balances | Daily | By 07:30 Australia/Sydney | Balance reruns can replace the prior day's partition |
| Risk customer flags | Hourly event extract | Within 90 minutes of case update | Cleared flags may arrive after downstream reporting windows |
| Reference data | Monthly | First calendar day of month | Product and branch corrections are manually reissued |

## Time Zone Rules

1. Source timestamps are stored in UTC.
2. Reporting dates are based on `Australia/Sydney`.
3. Daily balance dates are already expressed as `Australia/Sydney` business dates.
4. Transaction facts should expose both the converted local timestamp and local posting date when useful.
5. Daylight saving changes should rely on the warehouse timestamp conversion function rather than fixed UTC offsets.

## Customer Data Context

The customer master contains direct identifiers and contact details. These fields are useful for operational systems but should not be promoted into analytics marts for this demo.

Sensitive fields include:

1. `given_name`
2. `family_name`
3. `business_name`
4. `date_of_birth`
5. `email_address`
6. `mobile_number`
7. Any unmasked account number or document number if added in later demo data

Analytical models can use derived values such as age band, customer type, status, residency status, and lifecycle dates.

## Account Data Context

The account master identifies the primary customer on the account, but ownership and authority should be resolved using `account_relationships`.

Important relationship interpretation:

| Relationship type | Meaning | Can transact |
| --- | --- | --- |
| `PRIMARY_OWNER` | Main customer responsible for the account | Usually yes |
| `JOINT_OWNER` | Joint owner with legal ownership rights | Usually yes |
| `SIGNATORY` | Authorized party who can transact but may not own the account | Source flag determines authority |
| `TRUSTEE` | Trustee relationship for trust accounts | Source flag determines authority |
| `GUARANTOR` | Guarantor relationship for lending products | Usually no |

For demos, `dim_accounts.primary_customer_id` should come from `core_accounts.customer_id`, while relationship models should preserve all related customers.

## Transaction Data Context

Core transactions and card transactions have different lifecycle semantics.

Core banking transactions:

1. Usually represent posted account movements.
2. Use `transaction_status` to distinguish pending, posted, reversed, and failed events.
3. Store transaction amounts as absolute values and rely on transaction type plus debit or credit indicator for direction.
4. Can include reversals that point to an original transaction.

Card transactions:

1. Can exist as authorization-only events before clearing.
2. Can have a different authorization amount and settlement amount.
3. Can include overseas merchants and settlement currency differences.
4. Include processor fraud indicators, but a fraud flag is not the same as confirmed fraud.
5. Should use `cleared_at` as the posted timestamp when present.

## Balance Data Context

`daily_account_balances` is created after the core banking end-of-day process. It is the preferred source for official ledger and available balances.

Balance caveats:

1. Balance snapshots are daily, not intraday.
2. Balance reruns may replace a prior partition after operational incidents.
3. Closed accounts can appear after closure for historical reporting.
4. Negative available balance does not always mean the customer is in arrears because overdraft limits may apply.
5. `arrears_days` is primarily relevant for credit and lending products.

## Risk Flag Context

Risk flags are intentionally broad for demo purposes and combine operational, regulatory, financial crime, and customer care concepts.

| Flag type | Business meaning | Mart handling |
| --- | --- | --- |
| `AML_REVIEW` | Customer requires anti-money-laundering review | Expose as boolean only |
| `KYC_EXPIRED` | Customer due diligence is expired or incomplete | Expose as boolean only |
| `SANCTIONS_HIT` | Potential sanctions-screening match | Expose as boolean only; do not expose case detail |
| `FINANCIAL_HARDSHIP` | Customer has active hardship support | Expose as boolean only |
| `VULNERABLE_CUSTOMER` | Customer has an active vulnerability marker | Expose as boolean only |
| `PRIVACY_RESTRICTED` | Customer has restrictions on data usage | Use to suppress unnecessary sensitive attributes |

Risk flag case identifiers are operational references and should not be exposed in marts unless specifically required for audit models.

## Data Quality Expectations

The generated dbt project should include quality checks aligned to banking controls.

| Check area | Expectation |
| --- | --- |
| Referential integrity | Transactions and balances should reference known accounts |
| Key uniqueness | Natural source keys should be unique in staging models |
| Accepted values | Status, type, flag, and indicator fields should be constrained |
| Amount validity | Source absolute amounts should be non-negative and non-null |
| Timestamp validity | `updated_at` and `ingested_at` should be populated where supplied |
| Snapshot uniqueness | Daily balance rows should be unique by account and balance date |
| Privacy controls | PII fields should be excluded from marts unless explicitly documented |
| Freshness | Daily feeds should have freshness checks based on arrival expectations |

## Known Demo Limitations

1. The data model is simplified and does not represent a full banking regulatory reporting platform.
2. It does not include mortgages, loan schedules, interest accrual engines, general ledger accounting, or bureau data.
3. It does not implement full slowly changing dimensions unless the pipeline-generation skill chooses to add them.
4. Risk flags are simplified booleans and do not represent real case-management workflow complexity.
5. Currency conversion is out of scope; preserve source currencies rather than converting amounts.
6. Fraud indicators are suspicion markers, not confirmed loss events.

## Suggested dbt Source Freshness Rules

| Source | Warn after | Error after |
| --- | --- | --- |
| `core_customers` | 30 hours | 48 hours |
| `core_accounts` | 30 hours | 48 hours |
| `account_relationships` | 30 hours | 48 hours |
| `core_transactions` | 30 hours | 48 hours |
| `card_transactions` | 12 hours | 24 hours |
| `daily_account_balances` | 30 hours | 48 hours |
| `risk_customer_flags` | 3 hours | 6 hours |
| `branch_reference` | 45 days | 60 days |
| `product_reference` | 45 days | 60 days |

## Documentation Tone For Generated dbt Docs

Generated docs should be direct and operational. They should explain what each model is for, its grain, how it handles privacy, and how it supports downstream banking analytics. Avoid claiming that demo data is production-grade or fit for regulatory submission.
