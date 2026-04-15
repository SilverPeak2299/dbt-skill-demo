{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'core_customers') }}

),

renamed as (

    select
        cast(customer_id as varchar) as customer_id,
        upper(trim(cast(customer_type as varchar))) as customer_type,
        cast(date_of_birth as date) as date_of_birth,
        upper(trim(cast(tax_residency_country as varchar))) as tax_residency_country,
        coalesce(nullif(upper(trim(cast(residency_status as varchar))), ''), 'UNKNOWN') as residency_status,
        upper(trim(cast(customer_status as varchar))) as customer_status,
        cast(privacy_opt_out as boolean) as privacy_opt_out,
        cast(created_at as timestamp) as created_at_utc,
        (created_at at time zone 'UTC') at time zone 'Australia/Sydney' as customer_created_at,
        cast(updated_at as timestamp) as updated_at_utc,
        (updated_at at time zone 'UTC') at time zone 'Australia/Sydney' as customer_updated_at,
        cast(closed_at as timestamp) as closed_at_utc,
        (closed_at at time zone 'UTC') at time zone 'Australia/Sydney' as customer_closed_at
    from source

)

select * from renamed
