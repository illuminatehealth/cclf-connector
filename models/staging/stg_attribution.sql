select
    member_id
  , custom_attributed_provider
  , custom_attributed_provider_practice
  , file_name
  , ingest_ts
  , cast(substring(file_name, 3, 2) as int) + 2000 as year_nbr
from {{ source('lakehouse', 'mssp_attribution') }}
where 
  member_id is not null
