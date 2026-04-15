-- Seed a fictional retail banking source estate for dbt pipeline demos.
--
-- Usage with DuckDB CLI:
--   duckdb data/bank_demo.duckdb < scripts/seed_duckdb.sql
--
-- The script is intentionally self-contained and idempotent. It recreates
-- the raw source schema and inserts deterministic demo data.

BEGIN TRANSACTION;

DROP SCHEMA IF EXISTS raw_bank CASCADE;
CREATE SCHEMA raw_bank;

CREATE TABLE raw_bank.core_customers (
    customer_id VARCHAR PRIMARY KEY,
    customer_type VARCHAR NOT NULL,
    given_name VARCHAR,
    family_name VARCHAR,
    business_name VARCHAR,
    date_of_birth DATE,
    email_address VARCHAR,
    mobile_number VARCHAR,
    tax_residency_country VARCHAR,
    residency_status VARCHAR,
    customer_status VARCHAR NOT NULL,
    privacy_opt_out BOOLEAN NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    closed_at TIMESTAMP
);

CREATE TABLE raw_bank.core_accounts (
    account_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR NOT NULL,
    product_code VARCHAR NOT NULL,
    account_type VARCHAR NOT NULL,
    bsb VARCHAR,
    masked_account_number VARCHAR,
    currency_code VARCHAR NOT NULL,
    account_status VARCHAR NOT NULL,
    branch_id VARCHAR,
    opened_at TIMESTAMP NOT NULL,
    closed_at TIMESTAMP,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE raw_bank.account_relationships (
    relationship_id VARCHAR PRIMARY KEY,
    account_id VARCHAR NOT NULL,
    customer_id VARCHAR NOT NULL,
    relationship_type VARCHAR NOT NULL,
    relationship_start_date DATE NOT NULL,
    relationship_end_date DATE,
    is_authorized_to_transact BOOLEAN NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE raw_bank.core_transactions (
    transaction_id VARCHAR PRIMARY KEY,
    account_id VARCHAR NOT NULL,
    posted_at TIMESTAMP NOT NULL,
    effective_date DATE NOT NULL,
    transaction_type VARCHAR NOT NULL,
    transaction_description VARCHAR,
    amount DECIMAL(18,2) NOT NULL,
    currency_code VARCHAR NOT NULL,
    debit_credit_indicator VARCHAR NOT NULL,
    transaction_status VARCHAR NOT NULL,
    reversal_indicator BOOLEAN NOT NULL,
    original_transaction_id VARCHAR,
    ingested_at TIMESTAMP NOT NULL
);

CREATE TABLE raw_bank.card_transactions (
    card_transaction_id VARCHAR PRIMARY KEY,
    account_id VARCHAR NOT NULL,
    card_id_hash VARCHAR NOT NULL,
    authorization_at TIMESTAMP NOT NULL,
    cleared_at TIMESTAMP,
    card_transaction_type VARCHAR NOT NULL,
    merchant_name VARCHAR,
    merchant_category_code VARCHAR,
    merchant_country_code VARCHAR,
    authorization_amount DECIMAL(18,2) NOT NULL,
    authorization_currency_code VARCHAR NOT NULL,
    settlement_amount DECIMAL(18,2),
    settlement_currency_code VARCHAR,
    card_transaction_status VARCHAR NOT NULL,
    fraud_indicator VARCHAR,
    decline_reason_code VARCHAR,
    ingested_at TIMESTAMP NOT NULL
);

CREATE TABLE raw_bank.daily_account_balances (
    account_id VARCHAR NOT NULL,
    balance_date DATE NOT NULL,
    ledger_balance DECIMAL(18,2) NOT NULL,
    available_balance DECIMAL(18,2) NOT NULL,
    overdraft_limit DECIMAL(18,2),
    arrears_days INTEGER,
    currency_code VARCHAR NOT NULL,
    snapshot_created_at TIMESTAMP NOT NULL,
    PRIMARY KEY (account_id, balance_date)
);

CREATE TABLE raw_bank.risk_customer_flags (
    risk_flag_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR NOT NULL,
    flag_type VARCHAR NOT NULL,
    flag_status VARCHAR NOT NULL,
    flag_start_date DATE NOT NULL,
    flag_end_date DATE,
    severity VARCHAR,
    source_case_id VARCHAR,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE raw_bank.branch_reference (
    branch_id VARCHAR PRIMARY KEY,
    branch_name VARCHAR NOT NULL,
    state_code VARCHAR NOT NULL,
    region_name VARCHAR,
    is_active BOOLEAN NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE raw_bank.product_reference (
    product_code VARCHAR PRIMARY KEY,
    product_name VARCHAR NOT NULL,
    product_family VARCHAR NOT NULL,
    account_type VARCHAR NOT NULL,
    is_offset_eligible BOOLEAN NOT NULL,
    is_interest_bearing BOOLEAN NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

INSERT INTO raw_bank.branch_reference (
    branch_id,
    branch_name,
    state_code,
    region_name,
    is_active,
    updated_at
) VALUES
    ('B001', 'Sydney CBD', 'NSW', 'Sydney Metro', true, TIMESTAMP '2026-04-01 00:00:00'),
    ('B014', 'Parramatta', 'NSW', 'Sydney Metro', true, TIMESTAMP '2026-04-01 00:00:00'),
    ('B027', 'Melbourne Central', 'VIC', 'Melbourne Metro', true, TIMESTAMP '2026-04-01 00:00:00'),
    ('B033', 'Brisbane City', 'QLD', 'South East Queensland', true, TIMESTAMP '2026-04-01 00:00:00'),
    ('B044', 'Adelaide North', 'SA', 'South Australia', false, TIMESTAMP '2026-04-01 00:00:00');

INSERT INTO raw_bank.product_reference (
    product_code,
    product_name,
    product_family,
    account_type,
    is_offset_eligible,
    is_interest_bearing,
    updated_at
) VALUES
    ('TXN_EVERYDAY', 'Everyday Transaction Account', 'DEPOSITS', 'TRANSACTION', false, false, TIMESTAMP '2026-04-01 00:00:00'),
    ('SAV_BONUS', 'Bonus Saver Account', 'DEPOSITS', 'SAVINGS', false, true, TIMESTAMP '2026-04-01 00:00:00'),
    ('TD_12M', 'Twelve Month Term Deposit', 'DEPOSITS', 'TERM_DEPOSIT', false, true, TIMESTAMP '2026-04-01 00:00:00'),
    ('OFFSET_HOME', 'Home Loan Offset Account', 'DEPOSITS', 'OFFSET', true, false, TIMESTAMP '2026-04-01 00:00:00'),
    ('CC_REWARDS', 'Rewards Credit Card', 'CARDS', 'CREDIT_CARD', false, false, TIMESTAMP '2026-04-01 00:00:00');

INSERT INTO raw_bank.core_customers (
    customer_id,
    customer_type,
    given_name,
    family_name,
    business_name,
    date_of_birth,
    email_address,
    mobile_number,
    tax_residency_country,
    residency_status,
    customer_status,
    privacy_opt_out,
    created_at,
    updated_at,
    closed_at
) VALUES
    ('C100001', 'PERSON', 'Ava', 'Nguyen', NULL, DATE '1984-11-02', 'ava.nguyen@example.test', '+61400111001', 'AU', 'RESIDENT', 'ACTIVE', false, TIMESTAMP '2019-03-14 02:43:12', TIMESTAMP '2026-04-14 21:10:03', NULL),
    ('C100002', 'PERSON', 'Liam', 'Patel', NULL, DATE '1978-06-21', 'liam.patel@example.test', '+61400111002', 'AU', 'RESIDENT', 'ACTIVE', false, TIMESTAMP '2018-12-03 04:11:00', TIMESTAMP '2026-04-14 20:59:10', NULL),
    ('C100003', 'PERSON', 'Mia', 'O''Connor', NULL, DATE '1992-01-15', 'mia.oconnor@example.test', '+61400111003', 'AU', 'RESIDENT', 'ACTIVE', true, TIMESTAMP '2021-01-25 08:23:44', TIMESTAMP '2026-04-14 22:01:04', NULL),
    ('C100004', 'PERSON', 'Noah', 'Kim', NULL, DATE '1965-09-08', 'noah.kim@example.test', '+61400111004', 'NZ', 'NON_RESIDENT', 'DORMANT', false, TIMESTAMP '2016-05-11 01:05:33', TIMESTAMP '2026-04-14 20:33:57', NULL),
    ('C100005', 'COMPANY', NULL, NULL, 'Harbour Lane Pty Ltd', NULL, 'accounts@harbourlane.example.test', '+61290000005', 'AU', 'RESIDENT', 'ACTIVE', false, TIMESTAMP '2020-10-19 05:45:00', TIMESTAMP '2026-04-14 23:18:39', NULL),
    ('C100006', 'PERSON', 'Ethan', 'Brown', NULL, DATE '2001-03-30', 'ethan.brown@example.test', '+61400111006', 'AU', 'RESIDENT', 'SUSPENDED', false, TIMESTAMP '2022-08-02 03:39:12', TIMESTAMP '2026-04-14 18:45:00', NULL),
    ('C100007', 'TRUST', NULL, NULL, 'Williams Family Trust', NULL, 'trustee@williams.example.test', '+61390000007', 'AU', 'RESIDENT', 'ACTIVE', false, TIMESTAMP '2017-04-20 06:00:00', TIMESTAMP '2026-04-14 19:07:41', NULL),
    ('C100008', 'PERSON', 'Grace', 'Taylor', NULL, DATE '1942-12-04', 'grace.taylor@example.test', '+61400111008', 'AU', 'RESIDENT', 'ACTIVE', false, TIMESTAMP '2014-02-13 00:14:22', TIMESTAMP '2026-04-14 23:50:00', NULL),
    ('C100009', 'SOLE_TRADER', 'Oliver', 'Singh', 'Oliver Singh Consulting', DATE '1988-07-19', 'oliver.singh@example.test', '+61400111009', 'AU', 'RESIDENT', 'ACTIVE', false, TIMESTAMP '2023-03-01 07:20:00', TIMESTAMP '2026-04-14 22:33:12', NULL),
    ('C100010', 'PERSON', 'Charlotte', 'Wilson', NULL, DATE '1955-05-17', 'charlotte.wilson@example.test', '+61400111010', 'AU', 'RESIDENT', 'DECEASED', true, TIMESTAMP '2015-07-22 02:25:00', TIMESTAMP '2026-04-14 16:00:00', TIMESTAMP '2026-03-30 00:31:00');

INSERT INTO raw_bank.core_accounts (
    account_id,
    customer_id,
    product_code,
    account_type,
    bsb,
    masked_account_number,
    currency_code,
    account_status,
    branch_id,
    opened_at,
    closed_at,
    updated_at
) VALUES
    ('A900001', 'C100001', 'TXN_EVERYDAY', 'TRANSACTION', '062000', '****1001', 'AUD', 'OPEN', 'B014', TIMESTAMP '2020-07-10 04:22:00', NULL, TIMESTAMP '2026-04-14 20:05:48'),
    ('A900002', 'C100001', 'SAV_BONUS', 'SAVINGS', '062000', '****1002', 'AUD', 'OPEN', 'B014', TIMESTAMP '2020-08-05 02:00:00', NULL, TIMESTAMP '2026-04-14 20:05:48'),
    ('A900003', 'C100002', 'TXN_EVERYDAY', 'TRANSACTION', '062100', '****2001', 'AUD', 'OPEN', 'B001', TIMESTAMP '2019-02-18 01:10:00', NULL, TIMESTAMP '2026-04-14 20:07:00'),
    ('A900004', 'C100002', 'OFFSET_HOME', 'OFFSET', '062100', '****2002', 'AUD', 'OPEN', 'B001', TIMESTAMP '2021-11-01 00:05:00', NULL, TIMESTAMP '2026-04-14 20:07:00'),
    ('A900005', 'C100003', 'CC_REWARDS', 'CREDIT_CARD', '062000', '****3001', 'AUD', 'OPEN', 'B014', TIMESTAMP '2022-01-12 23:59:00', NULL, TIMESTAMP '2026-04-14 21:00:00'),
    ('A900006', 'C100004', 'TD_12M', 'TERM_DEPOSIT', '063000', '****4001', 'AUD', 'CLOSED', 'B027', TIMESTAMP '2024-04-01 00:00:00', TIMESTAMP '2026-04-01 00:00:00', TIMESTAMP '2026-04-14 19:33:00'),
    ('A900007', 'C100005', 'TXN_EVERYDAY', 'TRANSACTION', '064000', '****5001', 'AUD', 'OPEN', 'B033', TIMESTAMP '2021-09-13 01:45:00', NULL, TIMESTAMP '2026-04-14 23:18:39'),
    ('A900008', 'C100006', 'TXN_EVERYDAY', 'TRANSACTION', '062000', '****6001', 'AUD', 'FROZEN', 'B014', TIMESTAMP '2022-08-02 03:40:00', NULL, TIMESTAMP '2026-04-14 18:45:00'),
    ('A900009', 'C100007', 'SAV_BONUS', 'SAVINGS', '063000', '****7001', 'AUD', 'OPEN', 'B027', TIMESTAMP '2017-04-20 06:03:00', NULL, TIMESTAMP '2026-04-14 19:07:41'),
    ('A900010', 'C100008', 'TXN_EVERYDAY', 'TRANSACTION', '062100', '****8001', 'AUD', 'OPEN', 'B001', TIMESTAMP '2014-02-13 00:15:00', NULL, TIMESTAMP '2026-04-14 23:50:00'),
    ('A900011', 'C100009', 'TXN_EVERYDAY', 'TRANSACTION', '064000', '****9001', 'AUD', 'PENDING_CLOSE', 'B033', TIMESTAMP '2023-03-01 07:21:00', NULL, TIMESTAMP '2026-04-14 22:33:12');

INSERT INTO raw_bank.account_relationships (
    relationship_id,
    account_id,
    customer_id,
    relationship_type,
    relationship_start_date,
    relationship_end_date,
    is_authorized_to_transact,
    updated_at
) VALUES
    ('R700001', 'A900001', 'C100001', 'PRIMARY_OWNER', DATE '2020-07-10', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700002', 'A900002', 'C100001', 'PRIMARY_OWNER', DATE '2020-08-05', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700003', 'A900003', 'C100002', 'PRIMARY_OWNER', DATE '2019-02-18', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700004', 'A900003', 'C100003', 'JOINT_OWNER', DATE '2021-04-01', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700005', 'A900004', 'C100002', 'PRIMARY_OWNER', DATE '2021-11-01', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700006', 'A900004', 'C100003', 'JOINT_OWNER', DATE '2021-11-01', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700007', 'A900005', 'C100003', 'PRIMARY_OWNER', DATE '2022-01-12', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700008', 'A900006', 'C100004', 'PRIMARY_OWNER', DATE '2024-04-01', DATE '2026-04-01', false, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700009', 'A900007', 'C100005', 'PRIMARY_OWNER', DATE '2021-09-13', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700010', 'A900007', 'C100009', 'SIGNATORY', DATE '2024-06-01', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700011', 'A900008', 'C100006', 'PRIMARY_OWNER', DATE '2022-08-02', NULL, false, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700012', 'A900009', 'C100007', 'PRIMARY_OWNER', DATE '2017-04-20', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700013', 'A900009', 'C100008', 'TRUSTEE', DATE '2017-04-20', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700014', 'A900010', 'C100008', 'PRIMARY_OWNER', DATE '2014-02-13', NULL, true, TIMESTAMP '2026-04-14 20:07:22'),
    ('R700015', 'A900011', 'C100009', 'PRIMARY_OWNER', DATE '2023-03-01', NULL, true, TIMESTAMP '2026-04-14 20:07:22');

INSERT INTO raw_bank.core_transactions (
    transaction_id,
    account_id,
    posted_at,
    effective_date,
    transaction_type,
    transaction_description,
    amount,
    currency_code,
    debit_credit_indicator,
    transaction_status,
    reversal_indicator,
    original_transaction_id,
    ingested_at
) VALUES
    ('T202604130001', 'A900001', TIMESTAMP '2026-04-13 00:05:20', DATE '2026-04-13', 'DEP', 'PAYROLL SOUTHERN HEALTH', 3150.00, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130002', 'A900001', TIMESTAMP '2026-04-13 03:22:11', DATE '2026-04-13', 'BPAY', 'BPAY ENERGY PROVIDER', 182.65, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130003', 'A900002', TIMESTAMP '2026-04-13 05:35:45', DATE '2026-04-13', 'INT_CR', 'MONTHLY INTEREST', 8.42, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130004', 'A900003', TIMESTAMP '2026-04-13 06:04:17', DATE '2026-04-13', 'OSKO_OUT', 'OSKO RENT PAYMENT', 850.00, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130005', 'A900004', TIMESTAMP '2026-04-13 06:40:01', DATE '2026-04-13', 'DEP', 'TRANSFER FROM SAVINGS', 500.00, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130006', 'A900007', TIMESTAMP '2026-04-13 08:12:57', DATE '2026-04-13', 'FEE', 'ACCOUNT SERVICE FEE', 12.00, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130007', 'A900008', TIMESTAMP '2026-04-13 09:44:03', DATE '2026-04-13', 'WDR', 'ATM WITHDRAWAL', 200.00, 'AUD', 'D', 'FAILED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130008', 'A900010', TIMESTAMP '2026-04-13 10:25:31', DATE '2026-04-13', 'OSKO_IN', 'OSKO FROM FAMILY', 125.00, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604130009', 'A900011', TIMESTAMP '2026-04-13 11:45:00', DATE '2026-04-13', 'BPAY', 'BPAY ATO', 620.45, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-13 14:15:00'),
    ('T202604140001', 'A900001', TIMESTAMP '2026-04-14 03:17:45', DATE '2026-04-14', 'OSKO_IN', 'PAYMENT FROM J SMITH', 245.75, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140002', 'A900001', TIMESTAMP '2026-04-14 04:31:18', DATE '2026-04-14', 'WDR', 'ATM CASH OUT', 100.00, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140003', 'A900003', TIMESTAMP '2026-04-14 05:10:00', DATE '2026-04-14', 'DEP', 'SALARY ACME PTY LTD', 4200.00, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140004', 'A900003', TIMESTAMP '2026-04-14 05:45:10', DATE '2026-04-14', 'BPAY', 'BPAY WATER PROVIDER', 92.15, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140005', 'A900004', TIMESTAMP '2026-04-14 06:00:00', DATE '2026-04-14', 'INT_DR', 'OFFSET INTEREST ADJUSTMENT', 1.35, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140006', 'A900007', TIMESTAMP '2026-04-14 06:35:40', DATE '2026-04-14', 'DEP', 'MERCHANT SETTLEMENT', 9850.10, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140007', 'A900007', TIMESTAMP '2026-04-14 07:10:22', DATE '2026-04-14', 'OSKO_OUT', 'SUPPLIER FAST PAYMENT', 4120.00, 'AUD', 'D', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140008', 'A900008', TIMESTAMP '2026-04-14 08:11:00', DATE '2026-04-14', 'FEE', 'INVESTIGATION FEE', 35.00, 'AUD', 'D', 'PENDING', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140009', 'A900010', TIMESTAMP '2026-04-14 09:41:36', DATE '2026-04-14', 'DEP', 'PENSION PAYMENT', 1022.40, 'AUD', 'C', 'POSTED', false, NULL, TIMESTAMP '2026-04-14 14:15:00'),
    ('T202604140010', 'A900011', TIMESTAMP '2026-04-14 10:03:15', DATE '2026-04-14', 'REV', 'REVERSAL BPAY ATO', 620.45, 'AUD', 'C', 'POSTED', true, 'T202604130009', TIMESTAMP '2026-04-14 14:15:00');

INSERT INTO raw_bank.card_transactions (
    card_transaction_id,
    account_id,
    card_id_hash,
    authorization_at,
    cleared_at,
    card_transaction_type,
    merchant_name,
    merchant_category_code,
    merchant_country_code,
    authorization_amount,
    authorization_currency_code,
    settlement_amount,
    settlement_currency_code,
    card_transaction_status,
    fraud_indicator,
    decline_reason_code,
    ingested_at
) VALUES
    ('CT202604130001', 'A900005', 'cardhash-3001-a', TIMESTAMP '2026-04-13 00:21:11', TIMESTAMP '2026-04-13 22:40:00', 'PURCHASE', 'SYDNEY METRO', '4111', 'AU', 8.40, 'AUD', 8.40, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-14 03:30:00'),
    ('CT202604130002', 'A900005', 'cardhash-3001-a', TIMESTAMP '2026-04-13 01:05:09', TIMESTAMP '2026-04-14 00:12:00', 'PURCHASE', 'THE GROCER MARKET', '5411', 'AU', 86.35, 'AUD', 86.35, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-14 03:30:00'),
    ('CT202604130003', 'A900005', 'cardhash-3001-a', TIMESTAMP '2026-04-13 05:45:00', TIMESTAMP '2026-04-14 01:02:11', 'PURCHASE', 'SYDNEY BOOKS', '5942', 'AU', 42.00, 'AUD', 42.00, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-14 03:30:00'),
    ('CT202604130004', 'A900003', 'cardhash-2001-a', TIMESTAMP '2026-04-13 08:30:22', TIMESTAMP '2026-04-14 02:14:31', 'REFUND', 'HOMEWARES ONLINE', '5712', 'AU', 119.99, 'AUD', 119.99, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-14 03:30:00'),
    ('CT202604130005', 'A900001', 'cardhash-1001-a', TIMESTAMP '2026-04-13 11:59:05', NULL, 'PURCHASE', 'UNKNOWN MERCHANT 8842', '5812', 'AU', 299.95, 'AUD', NULL, NULL, 'AUTHORIZED', 'Y', NULL, TIMESTAMP '2026-04-14 03:30:00'),
    ('CT202604140001', 'A900005', 'cardhash-3001-a', TIMESTAMP '2026-04-14 00:12:18', TIMESTAMP '2026-04-15 00:50:01', 'PURCHASE', 'MELBOURNE HOTEL', '7011', 'AU', 220.00, 'AUD', 220.00, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-15 03:30:00'),
    ('CT202604140002', 'A900005', 'cardhash-3001-a', TIMESTAMP '2026-04-14 02:42:09', TIMESTAMP '2026-04-15 01:17:14', 'CASH_ADVANCE', 'CITY ATM', '6011', 'AU', 300.00, 'AUD', 300.00, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-15 03:30:00'),
    ('CT202604140003', 'A900003', 'cardhash-2001-a', TIMESTAMP '2026-04-14 03:28:40', NULL, 'PURCHASE', 'AIRLINE GLOBAL', '4511', 'SG', 640.00, 'SGD', NULL, NULL, 'AUTHORIZED', NULL, NULL, TIMESTAMP '2026-04-15 03:30:00'),
    ('CT202604140004', 'A900001', 'cardhash-1001-a', TIMESTAMP '2026-04-14 06:41:19', TIMESTAMP '2026-04-15 01:02:11', 'PURCHASE', 'SYDNEY METRO', '4111', 'AU', 8.40, 'AUD', 8.40, 'AUD', 'CLEARED', 'N', NULL, TIMESTAMP '2026-04-15 03:30:00'),
    ('CT202604140005', 'A900011', 'cardhash-9001-a', TIMESTAMP '2026-04-14 07:52:01', NULL, 'PURCHASE', 'SOFTWARE SUBSCRIPTION', '5734', 'US', 49.00, 'USD', NULL, NULL, 'DECLINED', 'N', 'INSUFFICIENT_FUNDS', TIMESTAMP '2026-04-15 03:30:00');

INSERT INTO raw_bank.daily_account_balances (
    account_id,
    balance_date,
    ledger_balance,
    available_balance,
    overdraft_limit,
    arrears_days,
    currency_code,
    snapshot_created_at
) VALUES
    ('A900001', DATE '2026-04-13', 4215.75, 3915.80, 500.00, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900002', DATE '2026-04-13', 18922.42, 18922.42, NULL, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900003', DATE '2026-04-13', 642.88, 762.87, 1000.00, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900004', DATE '2026-04-13', 5020.00, 5020.00, NULL, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900005', DATE '2026-04-13', -136.75, -436.75, 0.00, 2, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900006', DATE '2026-04-13', 0.00, 0.00, NULL, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900007', DATE '2026-04-13', 12850.44, 12850.44, NULL, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900008', DATE '2026-04-13', -125.00, -125.00, 250.00, 5, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900009', DATE '2026-04-13', 75420.00, 75420.00, NULL, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900010', DATE '2026-04-13', 902.12, 902.12, 300.00, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900011', DATE '2026-04-13', 215.20, 215.20, NULL, 0, 'AUD', TIMESTAMP '2026-04-13 15:30:00'),
    ('A900001', DATE '2026-04-14', 4361.50, 4053.10, 500.00, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900002', DATE '2026-04-14', 18922.42, 18922.42, NULL, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900003', DATE '2026-04-14', 4750.73, 4110.73, 1000.00, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900004', DATE '2026-04-14', 5518.65, 5518.65, NULL, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900005', DATE '2026-04-14', -436.75, -736.75, 0.00, 3, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900006', DATE '2026-04-14', 0.00, 0.00, NULL, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900007', DATE '2026-04-14', 18568.54, 18568.54, NULL, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900008', DATE '2026-04-14', -125.00, -125.00, 250.00, 6, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900009', DATE '2026-04-14', 75420.00, 75420.00, NULL, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900010', DATE '2026-04-14', 1924.52, 1924.52, 300.00, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00'),
    ('A900011', DATE '2026-04-14', 215.20, 215.20, NULL, 0, 'AUD', TIMESTAMP '2026-04-14 15:30:00');

INSERT INTO raw_bank.risk_customer_flags (
    risk_flag_id,
    customer_id,
    flag_type,
    flag_status,
    flag_start_date,
    flag_end_date,
    severity,
    source_case_id,
    updated_at
) VALUES
    ('F600001', 'C100001', 'KYC_EXPIRED', 'ACTIVE', DATE '2026-04-10', NULL, 'MEDIUM', 'CASE-10001', TIMESTAMP '2026-04-14 23:05:00'),
    ('F600002', 'C100003', 'PRIVACY_RESTRICTED', 'ACTIVE', DATE '2025-12-01', NULL, 'LOW', 'CASE-10002', TIMESTAMP '2026-04-14 22:01:04'),
    ('F600003', 'C100004', 'AML_REVIEW', 'CLEARED', DATE '2026-02-02', DATE '2026-03-15', 'HIGH', 'CASE-10003', TIMESTAMP '2026-03-15 05:00:00'),
    ('F600004', 'C100005', 'AML_REVIEW', 'ACTIVE', DATE '2026-04-11', NULL, 'HIGH', 'CASE-10004', TIMESTAMP '2026-04-14 23:18:39'),
    ('F600005', 'C100006', 'SANCTIONS_HIT', 'ACTIVE', DATE '2026-04-12', NULL, 'CRITICAL', 'CASE-10005', TIMESTAMP '2026-04-14 18:45:00'),
    ('F600006', 'C100008', 'VULNERABLE_CUSTOMER', 'ACTIVE', DATE '2026-01-20', NULL, 'MEDIUM', 'CASE-10006', TIMESTAMP '2026-04-14 23:50:00'),
    ('F600007', 'C100010', 'PRIVACY_RESTRICTED', 'ACTIVE', DATE '2026-03-30', NULL, 'HIGH', 'CASE-10007', TIMESTAMP '2026-04-14 16:00:00'),
    ('F600008', 'C100009', 'FINANCIAL_HARDSHIP', 'ACTIVE', DATE '2026-04-05', NULL, 'MEDIUM', 'CASE-10008', TIMESTAMP '2026-04-14 22:33:12');

COMMIT;

SELECT 'raw_bank.core_customers' AS table_name, COUNT(*) AS row_count FROM raw_bank.core_customers
UNION ALL
SELECT 'raw_bank.core_accounts' AS table_name, COUNT(*) AS row_count FROM raw_bank.core_accounts
UNION ALL
SELECT 'raw_bank.account_relationships' AS table_name, COUNT(*) AS row_count FROM raw_bank.account_relationships
UNION ALL
SELECT 'raw_bank.core_transactions' AS table_name, COUNT(*) AS row_count FROM raw_bank.core_transactions
UNION ALL
SELECT 'raw_bank.card_transactions' AS table_name, COUNT(*) AS row_count FROM raw_bank.card_transactions
UNION ALL
SELECT 'raw_bank.daily_account_balances' AS table_name, COUNT(*) AS row_count FROM raw_bank.daily_account_balances
UNION ALL
SELECT 'raw_bank.risk_customer_flags' AS table_name, COUNT(*) AS row_count FROM raw_bank.risk_customer_flags
UNION ALL
SELECT 'raw_bank.branch_reference' AS table_name, COUNT(*) AS row_count FROM raw_bank.branch_reference
UNION ALL
SELECT 'raw_bank.product_reference' AS table_name, COUNT(*) AS row_count FROM raw_bank.product_reference
ORDER BY table_name;
