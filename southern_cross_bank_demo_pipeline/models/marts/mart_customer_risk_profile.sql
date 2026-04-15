{{ config(materialized='table') }}

with customers as (

    select * from {{ ref('dim_customers') }}

),

snapshot_dates as (

    select distinct snapshot_date from {{ ref('fact_account_daily_snapshot') }}

),

risk_flags as (

    select * from {{ ref('stg_risk_customer_flags') }}

),

customer_dates as (

    select
        c.customer_id,
        c.customer_type,
        c.customer_status,
        c.privacy_opt_out,
        d.snapshot_date
    from customers c
    cross join snapshot_dates d

),

final as (

    select
        cd.customer_id,
        cd.snapshot_date,
        cd.customer_type,
        cd.customer_status,
        cd.privacy_opt_out,
        coalesce(bool_or(r.flag_status = 'ACTIVE' and r.flag_type = 'AML_REVIEW'), false) as aml_review_required,
        coalesce(bool_or(r.flag_status = 'ACTIVE' and r.flag_type = 'KYC_EXPIRED'), false) as kyc_expired,
        coalesce(bool_or(r.flag_status = 'ACTIVE' and r.flag_type = 'SANCTIONS_HIT'), false) as sanctions_screening_hit,
        coalesce(bool_or(r.flag_status = 'ACTIVE' and r.flag_type = 'FINANCIAL_HARDSHIP'), false) as hardship_active,
        coalesce(bool_or(r.flag_status = 'ACTIVE' and r.flag_type = 'VULNERABLE_CUSTOMER'), false) as vulnerable_customer,
        coalesce(bool_or(r.flag_status = 'ACTIVE' and r.flag_type = 'PRIVACY_RESTRICTED'), false) as privacy_restricted,
        coalesce(bool_or(r.flag_status = 'ACTIVE'), false) as has_any_active_risk_flag,
        max(r.risk_flag_updated_at) as latest_risk_flag_updated_at
    from customer_dates cd
    left join risk_flags r
        on cd.customer_id = r.customer_id
       and r.flag_start_date <= cd.snapshot_date
       and coalesce(r.flag_end_date, date '9999-12-31') >= cd.snapshot_date
    group by
        cd.customer_id,
        cd.snapshot_date,
        cd.customer_type,
        cd.customer_status,
        cd.privacy_opt_out

)

select * from final
