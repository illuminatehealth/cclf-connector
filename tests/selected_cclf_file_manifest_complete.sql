{{ config(tags=['connector']) }}

select
      file_cadence
    , performance_year
    , file_date
    , count(distinct file_number) as selected_file_count
from {{ ref('int_selected_cclf_file_manifest') }}
group by
      file_cadence
    , performance_year
    , file_date
having count(distinct file_number) <> 8
