{{ config(materialized='view') }}

with balances as (

    select * from {{ ref('stg_daily_account_balances') }}

),

accounts as (

    select * from {{ ref('stg_core_accounts') }}

),

transactions as (

    select * from {{ ref('int_transactions_normalized') }}

),

transaction_activity as (

    select
        account_id,
        posted_date as snapshot_date,
        count(*) as transaction_count,
        cast(sum(signed_amount) as decimal(18, 2)) as net_transaction_amount
    from transactions
    where transaction_status = 'POSTED'
      and not is_pending
    group by account_id, posted_date

),

transformed as (

    select
        b.account_id,
        b.balance_date as snapshot_date,
        b.ledger_balance,
        b.available_balance,
        b.overdraft_limit,
        case
            when b.arrears_days is null and a.account_status = 'OPEN' then 0
            else b.arrears_days
        end as arrears_days,
        b.currency_code,
        coalesce(ta.transaction_count, 0) as transaction_count,
        coalesce(ta.net_transaction_amount, cast(0 as decimal(18, 2))) as net_transaction_amount,
        b.available_balance < 0 as is_overdrawn,
        case
            when b.available_balance >= 0 then false
            when coalesce(b.overdraft_limit, cast(0 as decimal(18, 2))) = 0 then true
            else b.available_balance < -b.overdraft_limit
        end as is_over_limit,
        coalesce(ta.transaction_count, 0) > 0 as has_transaction_activity,
        a.account_status,
        a.account_type,
        b.snapshot_created_at
    from balances b
    left join accounts a
        on b.account_id = a.account_id
    left join transaction_activity ta
        on b.account_id = ta.account_id
       and b.balance_date = ta.snapshot_date

)

select * from transformed
