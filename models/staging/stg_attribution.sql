{% if var('custom_attribution_enabled', true) %}

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

{% else %}

select
    cast(null as {{ dbt.type_string() }}) as member_id
  , cast(null as {{ dbt.type_string() }}) as custom_attributed_provider
  , cast(null as {{ dbt.type_string() }}) as custom_attributed_provider_practice
  , cast(null as {{ dbt.type_string() }}) as file_name
  , cast(null as {{ dbt.type_timestamp() }}) as ingest_ts
  , cast(null as {{ dbt.type_int() }}) as year_nbr
where 1 = 0

{% endif %}
