select
    customer_id,
    snapshot_date,
    count(*) as row_count
from {{ ref('mart_customer_risk_profile') }}
group by customer_id, snapshot_date
having count(*) > 1
