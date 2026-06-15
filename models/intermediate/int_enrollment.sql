
with enrollment_data as (
    select
        max(case when year(enrollment_end_date) > file_year then cast(concat(file_year, '-12-31') as date) else enrollment_end_date end) as enrollment_end_date
      , file_year
      , current_bene_mbi_id
    from {{ ref('int_enrollment_stage') }}
    group by 
        current_bene_mbi_id
      , file_year
)

,enrollment_start as (
select
    enrollment_end_date
  , case 
        when year(enrollment_end_date) = file_year 
        then cast(concat(file_year, '-01-01') as date) 
        else null 
    end as enrollment_start_date
  , file_year
  , current_bene_mbi_id
from enrollment_data
)

select distinct enrollment_start_date
,enrollment_end_date
,file_year
,current_bene_mbi_id
from enrollment_start
where enrollment_start_date is not null