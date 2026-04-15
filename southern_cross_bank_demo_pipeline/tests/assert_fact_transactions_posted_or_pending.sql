select *
from {{ ref('fact_transactions') }}
where transaction_status <> 'POSTED'
  and not is_pending
