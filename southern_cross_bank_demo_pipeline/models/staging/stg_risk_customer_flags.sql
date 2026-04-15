{{ config(materialized='view') }}

with source as (

    select * from {{ source('raw_bank', 'risk_customer_flags') }}

),

renamed as (

    select
        cast(risk_flag_id as varchar) as risk_flag_id,
        cast(customer_id as varchar) as customer_id,
        upper(trim(cast(flag_type as varchar))) as flag_type,
        upper(trim(cast(flag_status as varchar))) as flag_status,
        cast(flag_start_date as date) as flag_start_date,
        cast(flag_end_date as date) as flag_end_date,
        upper(trim(cast(severity as varchar))) as severity,
        cast(source_case_id as varchar) as source_case_id,
        cast(updated_at as timestamp) as updated_at_utc,
        (updated_at at time zone 'UTC') at time zone 'Australia/Sydney' as risk_flag_updated_at
    from source

)

select * from renamed
