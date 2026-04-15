{{ config(materialized='table') }}

with daily_balances as (

    select * from {{ ref('int_account_daily_balances') }}

),

accounts as (

    select * from {{ ref('dim_accounts') }}

),

final as (

    select
        b.account_id,
        a.primary_customer_id as customer_id,
        b.snapshot_date,
        b.ledger_balance,
        b.available_balance,
        b.overdraft_limit,
        b.arrears_days,
        b.currency_code,
        b.transaction_count,
        b.net_transaction_amount,
        b.is_overdrawn,
        b.is_over_limit,
        b.has_transaction_activity,
        a.account_status,
        a.account_type,
        a.product_code,
        a.product_family,
        b.snapshot_created_at
    from daily_balances b
    inner join accounts a
        on b.account_id = a.account_id

)

select * from final
