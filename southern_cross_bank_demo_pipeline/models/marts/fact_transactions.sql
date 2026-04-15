{{ config(materialized='table') }}

with transactions as (

    select * from {{ ref('int_transactions_normalized') }}

),

accounts as (

    select * from {{ ref('dim_accounts') }}

),

final as (

    select
        t.transaction_id,
        t.source_transaction_id,
        t.source_system,
        t.account_id,
        a.primary_customer_id as customer_id,
        a.product_code,
        a.account_type,
        t.posted_at,
        t.posted_date,
        t.transaction_category,
        t.merchant_category_code,
        t.merchant_name_clean,
        t.merchant_country_code,
        t.signed_amount,
        t.currency_code,
        t.transaction_status,
        t.is_pending,
        t.is_fraud_suspected,
        t.reversal_indicator,
        t.original_transaction_id,
        t.ingested_at
    from transactions t
    inner join accounts a
        on t.account_id = a.account_id
    where t.transaction_status = 'POSTED'
       or t.is_pending

)

select * from final
