

with cte as 
(
select file_date
,bene_mbi_id
,bene_death_dt
,file_year
,row_number () over (partition by bene_mbi_id, file_year order by file_date desc) file_row_num
from {{ ref('stg_beneficiary_demographics') }} d 
where bene_death_dt is not null
group by file_date
,bene_mbi_id
,bene_death_dt
,file_year
)

, alr_eligible as (
select distinct coalesce(x.crnt_num,d.bene_mbi_id) as bene_mbi_id
     , file_year
from {{ ref('int_alr_1_1_union') }} d
left join {{ ref('int_beneficiary_xref_deduped') }} x on d.bene_mbi_id = x.prvs_num
where file_year_rank = 1
  and excluded = 0
)

,bd_xref as (
    select *
    ,coalesce(x.crnt_num,d.bene_mbi_id) as current_id
    from {{ ref('stg_beneficiary_demographics') }} d
    left join {{ ref('int_beneficiary_xref_deduped') }} x on d.bene_mbi_id = x.prvs_num
)

, base_months as (
  select distinct
      d.file_date
    , d.file_name
    , d.file_year
    , c.first_day_of_month  as enrollment_start_date
    , c.last_day_of_month   as enrollment_end_date
    , cte.bene_death_dt
    , current_id as bene_mbi_id_no_death_date
  from bd_xref d
  left join {{ ref('reference_data__calendar') }} c on d.file_date = c.full_date
  left join cte on d.current_id = cte.bene_mbi_id 
    and d.file_year = cte.file_year
    and file_row_num = 1
)

, eligible_months as (
  select
      bm.*
    , alr.file_year as alr_year
  from base_months bm
  inner join alr_eligible alr
    on bm.bene_mbi_id_no_death_date = alr.bene_mbi_id
   and year(bm.enrollment_start_date) = alr.file_year
)

, alive_months as (
  select *
  from eligible_months e
  where {{ dbt.dateadd('month', 1, 'cast(bene_death_dt as date)') }} > enrollment_end_date
     or bene_death_dt is null
)

, pick_one_file_per_month as (
  select
      file_date
    , file_name
    , file_year
    , alr_year
    , enrollment_start_date
    , enrollment_end_date
    , bene_death_dt
    , bene_mbi_id_no_death_date as current_bene_mbi_id
    , row_number() over (
        partition by bene_mbi_id_no_death_date, enrollment_start_date, enrollment_end_date
        order by 
          case 
            when year(file_date) = alr_year then 1
            when year(file_date) = alr_year + 1 then 2
            else 3
          end,
          file_date desc,
          file_name desc
      ) as rn
  from alive_months
)

select
    file_date
  , file_name
  , file_year
  , enrollment_start_date
  , enrollment_end_date
  , bene_death_dt
  , current_bene_mbi_id
from pick_one_file_per_month
where rn = 1
