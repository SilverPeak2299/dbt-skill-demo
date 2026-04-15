{{ config(materialized='view') }}

with core_transactions as (

    select * from {{ ref('stg_core_transactions') }}

),

card_transactions as (

    select * from {{ ref('stg_core_card_transactions') }}

),

normalized_core as (

    select
        concat('ACCT-', transaction_id) as transaction_id,
        transaction_id as source_transaction_id,
        'CORE_BANKING' as source_system,
        account_id,
        posted_at,
        posted_date,
        transaction_type as source_transaction_type,
        case transaction_type
            when 'DEP' then 'DEPOSIT'
            when 'WDR' then 'WITHDRAWAL'
            when 'FEE' then 'FEE'
            when 'INT_CR' then 'INTEREST_CREDIT'
            when 'INT_DR' then 'INTEREST_DEBIT'
            when 'BPAY' then 'BPAY_PAYMENT'
            when 'OSKO_IN' then 'FAST_PAYMENT_IN'
            when 'OSKO_OUT' then 'FAST_PAYMENT_OUT'
            when 'REV' then 'REVERSAL'
            else 'UNMAPPED'
        end as transaction_category,
        cast(null as varchar) as merchant_category_code,
        cast(null as varchar) as merchant_name_clean,
        cast(null as varchar) as merchant_country_code,
        case
            when transaction_type in ('DEP', 'INT_CR', 'OSKO_IN') then amount
            when transaction_type in ('WDR', 'FEE', 'INT_DR', 'OSKO_OUT') then -amount
            when transaction_type = 'BPAY' and reversal_indicator then
                case when debit_credit_indicator = 'D' then -amount else amount end
            when transaction_type = 'BPAY' then -amount
            when transaction_type = 'REV' then
                case when debit_credit_indicator = 'D' then -amount else amount end
            else
                case when debit_credit_indicator = 'D' then -amount else amount end
        end as signed_amount,
        currency_code,
        transaction_status,
        transaction_status = 'PENDING' as is_pending,
        cast(null as boolean) as is_fraud_suspected,
        reversal_indicator,
        original_transaction_id,
        ingested_at
    from core_transactions

),

normalized_card as (

    select
        concat('CARD-', card_transaction_id) as transaction_id,
        card_transaction_id as source_transaction_id,
        'CARD_PROCESSOR' as source_system,
        account_id,
        coalesce(cleared_at, authorization_at) as posted_at,
        cast(coalesce(cleared_at, authorization_at) as date) as posted_date,
        card_transaction_type as source_transaction_type,
        case card_transaction_type
            when 'PURCHASE' then 'CARD_PURCHASE'
            when 'REFUND' then 'CARD_REFUND'
            when 'CASH_ADVANCE' then 'CASH_ADVANCE'
            when 'CHARGEBACK' then 'CHARGEBACK'
            else 'UNMAPPED'
        end as transaction_category,
        merchant_category_code,
        merchant_name_clean,
        merchant_country_code,
        case
            when card_transaction_type in ('REFUND', 'CHARGEBACK') then coalesce(settlement_amount, authorization_amount)
            when card_transaction_type in ('PURCHASE', 'CASH_ADVANCE') then -coalesce(settlement_amount, authorization_amount)
            else -coalesce(settlement_amount, authorization_amount)
        end as signed_amount,
        coalesce(settlement_currency_code, authorization_currency_code) as currency_code,
        case
            when card_transaction_status = 'CLEARED' then 'POSTED'
            when card_transaction_status = 'AUTHORIZED' and cleared_at is null then 'PENDING'
            else card_transaction_status
        end as transaction_status,
        card_transaction_status = 'AUTHORIZED' and cleared_at is null as is_pending,
        case
            when fraud_indicator = 'Y' then true
            when fraud_indicator = 'N' then false
            else null
        end as is_fraud_suspected,
        false as reversal_indicator,
        cast(null as varchar) as original_transaction_id,
        ingested_at
    from card_transactions

),

unioned as (

    select * from normalized_core
    union all
    select * from normalized_card

)

select * from unioned
