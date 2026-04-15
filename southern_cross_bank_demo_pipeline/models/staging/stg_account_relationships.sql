{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'account_relationships') }}

),

renamed as (

    select
        cast(relationship_id as varchar) as relationship_id,
        cast(account_id as varchar) as account_id,
        cast(customer_id as varchar) as customer_id,
        upper(trim(cast(relationship_type as varchar))) as relationship_type,
        cast(relationship_start_date as date) as relationship_start_date,
        cast(relationship_end_date as date) as relationship_end_date,
        cast(is_authorized_to_transact as boolean) as is_authorized_to_transact,
        cast(updated_at as timestamp) as updated_at_utc,
        (updated_at at time zone 'UTC') at time zone 'Australia/Sydney' as relationship_updated_at
    from source

)

select * from renamed
