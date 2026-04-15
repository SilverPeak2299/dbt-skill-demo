{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'core_transactions') }}

),

renamed as (

    select
        cast(transaction_id as varchar) as transaction_id,
        cast(account_id as varchar) as account_id,
        cast(posted_at as timestamp) as posted_at_utc,
        (posted_at at time zone 'UTC') at time zone 'Australia/Sydney' as posted_at,
        cast(((posted_at at time zone 'UTC') at time zone 'Australia/Sydney') as date) as posted_date,
        cast(effective_date as date) as effective_date,
        upper(trim(cast(transaction_type as varchar))) as transaction_type,
        cast(transaction_description as varchar) as transaction_description,
        cast(amount as decimal(18, 2)) as amount,
        upper(trim(cast(currency_code as varchar))) as currency_code,
        upper(trim(cast(debit_credit_indicator as varchar))) as debit_credit_indicator,
        upper(trim(cast(transaction_status as varchar))) as transaction_status,
        cast(reversal_indicator as boolean) as reversal_indicator,
        cast(original_transaction_id as varchar) as original_transaction_id,
        cast(ingested_at as timestamp) as ingested_at_utc,
        (ingested_at at time zone 'UTC') at time zone 'Australia/Sydney' as ingested_at
    from source

)

select * from renamed
