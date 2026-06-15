with cte as (
    select
        filename as file_name
    from {{ source('lakehouse','alr_1_1_retro') }}
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
      , row_number() over (
            partition by file_year
            order by
                case 
                    when file_name like '%Y%' then 5   -- Matches files with 'Y' in the middle section
                    when file_name like '%Q1%' then 4
                    when file_name like '%Q2%' then 3
                    when file_name like '%Q3%' then 2
                    when file_name like '%Q4%' then 1
                    else 6  -- Other files rank last
                end asc
              , file_name asc  -- Ensures a consistent ordering for files with the same ranking type
        ) as file_year_rank
    from file_crosswalk
)

select
    file_year
  , base.filename as file_name
  , file_year_rank
  , bene_mbi_id as bene_mbi_id
  , bene_1st_name as bene_1st_name
  , bene_last_name as bene_last_name
  , bene_sex_cd as bene_sex_cd
  , bene_brth_dt as bene_brth_dt
  , bene_death_dt as bene_death_dt
  , geo_ssa_cnty_cd_name as geo_ssa_cnty_cd_name
  , geo_ssa_state_name as geo_ssa_state_name
  , state_county_cd as state_county_cd
  , assignment_type as assignment_type
  , asg_status as asg_status
  , partd_months as partd_months
  , enrollflag1 as enrollflag1
  , enrollflag2 as enrollflag2
  , enrollflag3 as enrollflag3
  , enrollflag4 as enrollflag4
  , enrollflag5 as enrollflag5
  , enrollflag6 as enrollflag6
  , enrollflag7 as enrollflag7
  , enrollflag8 as enrollflag8
  , enrollflag9 as enrollflag9
  , enrollflag10 as enrollflag10
  , enrollflag11 as enrollflag11
  , enrollflag12 as enrollflag12
  , case when base.filename like '%Q1%' then 1
        when base.filename like '%Q2%' then 2
        when base.filename like '%Q3%' then 3
        when base.filename like '%Q4%' then 4
        when base.filename like '%Y%'  then 4 
        when base.filename like '%D%' then 0 end
        as quarter_number
from {{ source('lakehouse','alr_1_1_retro') }} as base
inner join file_rank
  on base.filename = file_rank.file_name