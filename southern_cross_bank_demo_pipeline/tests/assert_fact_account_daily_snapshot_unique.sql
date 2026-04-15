select
    account_id,
    snapshot_date,
    count(*) as row_count
from {{ ref('fact_account_daily_snapshot') }}
group by account_id, snapshot_date
having count(*) > 1
