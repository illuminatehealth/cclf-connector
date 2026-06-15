with cte as (
    select
        filename as file_name
    from {{ source('lakehouse','alr_1_1') }}
    group by filename
)

, file_crosswalk as (
select
    case 
        when substring(file_name, 18, 1) = 'D' then cast(substring(file_name, 19, 2) as int) + 2000 
        when substring(file_name, 18, 1) = 'Y' then cast(substring(file_name, 19, 4) as int)
        else cast(substring(file_name, 18, 4) as int)
    end as file_year
  , file_name
from cte
)

, file_rank as (
select
    file_year
  , file_name
  , row_number() over ( partition by file_year
        order by
            case 
                when file_name like '%Y%' then 1   -- matches files with 'Y' in the middle section
                when file_name like '%Q1%' then 5
                when file_name like '%Q2%' then 4
                when file_name like '%Q3%' then 3
                when file_name like '%Q4%' then 2
                else 6  -- other files rank last
            end asc
          , file_name asc  -- ensures a consistent ordering for files with the same ranking type
    ) as file_year_rank
from file_crosswalk
)


select
    file_year
  , base.filename as file_name
  , file_year_rank
  , bene_mbi_id 
  , bene_1st_name 
  , bene_last_name
  , bene_sex_cd 
  , bene_brth_dt
  , bene_death_dt 
  , geo_ssa_cnty_cd_name 
  , geo_ssa_state_name 
  , state_county_cd 
  , assignment_type 
  , asg_status 
  , partd_months 
  , excluded
  , deceased_excluded 
  , other_reasons_excluded
  , part_a_b_only_excluded 
  , ghp_excluded 
  , other_shared_sav_init 
  , enrollflag1 
  , enrollflag2 
  , enrollflag3 
  , enrollflag4 
  , enrollflag5 
  , enrollflag6 
  , enrollflag7 
  , enrollflag8 
  , enrollflag9 
  , enrollflag10 
  , enrollflag11 
  , enrollflag12 
from {{ source('lakehouse', 'alr_1_1') }} as base
inner join file_rank
  on base.filename = file_rank.file_name
