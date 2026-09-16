{{ config(tags=['connector']) }}

with complete_monthly_months as (

    select
          performance_year
        , file_year
        , file_month
    from {{ ref('int_cclf_file_manifest') }}
    where file_cadence = 'monthly'
    group by
          performance_year
        , file_year
        , file_month
        , file_date
    having count(distinct file_number) = 8

)

select selected.*
from {{ ref('int_selected_cclf_file_manifest') }} as selected
where selected.file_cadence = 'weekly'
  and exists (
      select 1
      from complete_monthly_months
      where complete_monthly_months.performance_year = selected.performance_year
        and complete_monthly_months.file_year = selected.file_year
        and complete_monthly_months.file_month = selected.file_month
  )
