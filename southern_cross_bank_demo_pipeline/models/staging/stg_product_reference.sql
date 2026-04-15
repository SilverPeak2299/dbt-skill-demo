{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'product_reference') }}

),

renamed as (

    select
        upper(trim(cast(product_code as varchar))) as product_code,
        trim(cast(product_name as varchar)) as product_name,
        upper(trim(cast(product_family as varchar))) as product_family,
        upper(trim(cast(account_type as varchar))) as account_type,
        cast(is_offset_eligible as boolean) as is_offset_eligible,
        cast(is_interest_bearing as boolean) as is_interest_bearing,
        cast(updated_at as timestamp) as updated_at_utc,
        (updated_at at time zone 'UTC') at time zone 'Australia/Sydney' as product_updated_at
    from source

)

select * from renamed
