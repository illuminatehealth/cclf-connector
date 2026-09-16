{{ config(tags=['connector']) }}

select *
from {{ ref('medical_claim') }}
where file_cadence not in ('monthly', 'weekly')
   or file_priority not in (1, 2)
   or file_cadence is null
   or file_priority is null
