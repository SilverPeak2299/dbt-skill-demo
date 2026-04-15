{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'core_accounts') }}

),

renamed as (

    select
        cast(account_id as varchar) as account_id,
        cast(customer_id as varchar) as customer_id,
        upper(trim(cast(product_code as varchar))) as product_code,
        upper(trim(cast(account_type as varchar))) as account_type,
        cast(masked_account_number as varchar) as masked_account_number,
        coalesce(nullif(upper(trim(cast(currency_code as varchar))), ''), 'AUD') as currency_code,
        upper(trim(cast(account_status as varchar))) as account_status,
        cast(branch_id as varchar) as branch_id,
        cast(opened_at as timestamp) as opened_at_utc,
        (opened_at at time zone 'UTC') at time zone 'Australia/Sydney' as opened_at,
        cast(closed_at as timestamp) as closed_at_utc,
        (closed_at at time zone 'UTC') at time zone 'Australia/Sydney' as closed_at,
        cast(updated_at as timestamp) as updated_at_utc,
        (updated_at at time zone 'UTC') at time zone 'Australia/Sydney' as account_updated_at
    from source

)

select * from renamed
