{{ config(materialized='table') }}

with customers as (

    select * from {{ ref('stg_core_customers') }}

),

active_flags as (

    select
        customer_id,
        bool_or(flag_status = 'ACTIVE') as has_active_risk_flag,
        bool_or(flag_status = 'ACTIVE' and flag_type = 'PRIVACY_RESTRICTED') as privacy_restricted,
        bool_or(flag_status = 'ACTIVE' and flag_type = 'KYC_EXPIRED') as kyc_expired
    from {{ ref('stg_risk_customer_flags') }}
    where flag_status = 'ACTIVE'
      and flag_start_date <= current_date
      and coalesce(flag_end_date, date '9999-12-31') >= current_date
    group by customer_id

),

customer_ages as (

    select
        *,
        case
            when date_of_birth is null then null
            else date_diff('year', date_of_birth, current_date)
                - case
                    when strftime(current_date, '%m-%d') < strftime(date_of_birth, '%m-%d') then 1
                    else 0
                end
        end as age_years
    from customers

),

final as (

    select
        c.customer_id,
        c.customer_type,
        case
            when c.age_years is null then 'NOT_APPLICABLE'
            when c.age_years < 18 then 'UNDER_18'
            when c.age_years between 18 and 24 then '18_24'
            when c.age_years between 25 and 34 then '25_34'
            when c.age_years between 35 and 44 then '35_44'
            when c.age_years between 45 and 54 then '45_54'
            when c.age_years between 55 and 64 then '55_64'
            else '65_PLUS'
        end as age_band,
        c.tax_residency_country,
        c.residency_status,
        c.customer_status,
        c.privacy_opt_out,
        coalesce(f.has_active_risk_flag, false) as has_active_risk_flag,
        coalesce(f.privacy_restricted, false) as privacy_restricted,
        coalesce(f.kyc_expired, false) as kyc_expired,
        c.customer_created_at,
        c.customer_updated_at,
        c.customer_closed_at
    from customer_ages c
    left join active_flags f
        on c.customer_id = f.customer_id

)

select * from final
