{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'card_transactions') }}

),

renamed as (

    select
        cast(card_transaction_id as varchar) as card_transaction_id,
        cast(account_id as varchar) as account_id,
        cast(card_id_hash as varchar) as card_id_hash,
        cast(authorization_at as timestamp) as authorization_at_utc,
        (authorization_at at time zone 'UTC') at time zone 'Australia/Sydney' as authorization_at,
        cast(cleared_at as timestamp) as cleared_at_utc,
        (cleared_at at time zone 'UTC') at time zone 'Australia/Sydney' as cleared_at,
        upper(trim(cast(card_transaction_type as varchar))) as card_transaction_type,
        regexp_replace(upper(trim(cast(merchant_name as varchar))), '\\s+', ' ', 'g') as merchant_name_clean,
        cast(merchant_category_code as varchar) as merchant_category_code,
        upper(trim(cast(merchant_country_code as varchar))) as merchant_country_code,
        cast(authorization_amount as decimal(18, 2)) as authorization_amount,
        upper(trim(cast(authorization_currency_code as varchar))) as authorization_currency_code,
        cast(settlement_amount as decimal(18, 2)) as settlement_amount,
        upper(trim(cast(settlement_currency_code as varchar))) as settlement_currency_code,
        upper(trim(cast(card_transaction_status as varchar))) as card_transaction_status,
        upper(trim(cast(fraud_indicator as varchar))) as fraud_indicator,
        cast(decline_reason_code as varchar) as decline_reason_code,
        cast(ingested_at as timestamp) as ingested_at_utc,
        (ingested_at at time zone 'UTC') at time zone 'Australia/Sydney' as ingested_at
    from source

)

select * from renamed
