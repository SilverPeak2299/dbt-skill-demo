{{ config(materialized='table') }}

with accounts as (

    select * from {{ ref('stg_core_accounts') }}

),

products as (

    select * from {{ ref('stg_product_reference') }}

),

branches as (

    select * from {{ ref('stg_branch_reference') }}

),

relationship_distinct as (

    select distinct
        account_id,
        relationship_type,
        related_customer_id,
        is_authorized_to_transact
    from {{ ref('int_customer_account_relationships') }}
    where is_current_relationship

),

relationship_summary as (

    select
        account_id,
        string_agg(relationship_type, ', ' order by relationship_type) as account_holder_type_summary,
        count(distinct related_customer_id) as related_customer_count,
        count(distinct case when is_authorized_to_transact then related_customer_id end) as authorized_customer_count
    from relationship_distinct
    group by account_id

),

final as (

    select
        a.account_id,
        a.customer_id as primary_customer_id,
        coalesce(rs.account_holder_type_summary, 'UNMAPPED') as account_holder_type_summary,
        coalesce(rs.related_customer_count, 0) as related_customer_count,
        coalesce(rs.authorized_customer_count, 0) as authorized_customer_count,
        a.product_code,
        p.product_name,
        p.product_family,
        coalesce(a.account_type, p.account_type) as account_type,
        coalesce(a.currency_code, 'AUD') as currency_code,
        a.account_status,
        a.branch_id,
        b.branch_name,
        b.state_code,
        b.region_name,
        p.is_offset_eligible,
        p.is_interest_bearing,
        a.opened_at,
        a.closed_at,
        a.account_updated_at
    from accounts a
    left join products p
        on a.product_code = p.product_code
    left join branches b
        on a.branch_id = b.branch_id
    left join relationship_summary rs
        on a.account_id = rs.account_id

)

select * from final
