select *
from {{ ref('stg_core_transactions') }}
where amount is null
   or amount < 0
