{{ config(materialized='view') }}

with relationships as (

    select * from {{ ref('stg_account_relationships') }}

),

accounts as (

    select * from {{ ref('stg_core_accounts') }}

),

customers as (

    select * from {{ ref('stg_core_customers') }}

),

transformed as (

    select
        r.relationship_id,
        r.account_id,
        a.customer_id as primary_customer_id,
        r.customer_id as related_customer_id,
        r.relationship_type,
        r.relationship_start_date,
        r.relationship_end_date,
        r.is_authorized_to_transact,
        r.relationship_end_date is null or r.relationship_end_date >= current_date as is_current_relationship,
        c.customer_type as related_customer_type,
        c.customer_status as related_customer_status,
        a.account_status,
        a.product_code,
        a.account_type,
        r.relationship_updated_at
    from relationships r
    left join accounts a
        on r.account_id = a.account_id
    left join customers c
        on r.customer_id = c.customer_id

)

select * from transformed
