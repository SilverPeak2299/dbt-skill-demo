{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'daily_account_balances') }}

),

renamed as (

    select
        cast(account_id as varchar) as account_id,
        cast(balance_date as date) as balance_date,
        cast(ledger_balance as decimal(18, 2)) as ledger_balance,
        cast(available_balance as decimal(18, 2)) as available_balance,
        cast(overdraft_limit as decimal(18, 2)) as overdraft_limit,
        cast(arrears_days as integer) as arrears_days,
        upper(trim(cast(currency_code as varchar))) as currency_code,
        cast(snapshot_created_at as timestamp) as snapshot_created_at_utc,
        (snapshot_created_at at time zone 'UTC') at time zone 'Australia/Sydney' as snapshot_created_at
    from source

)

select * from renamed
