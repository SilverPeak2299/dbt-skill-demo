{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'branch_reference') }}

),

renamed as (

    select
        cast(branch_id as varchar) as branch_id,
        trim(cast(branch_name as varchar)) as branch_name,
        upper(trim(cast(state_code as varchar))) as state_code,
        trim(cast(region_name as varchar)) as region_name,
        cast(is_active as boolean) as is_active,
        cast(updated_at as timestamp) as updated_at_utc,
        (updated_at at time zone 'UTC') at time zone 'Australia/Sydney' as branch_updated_at
    from source

)

select * from renamed
