{{ config(tags=['connector']) }}

select
      performance_year
    , file_year
    , file_month
    , file_date
    , count(distinct file_number) as file_count
from {{ ref('int_selected_cclf_file_manifest') }}
where file_cadence = 'weekly'
group by
      performance_year
    , file_year
    , file_month
    , file_date
having count(distinct file_number) <> 8
