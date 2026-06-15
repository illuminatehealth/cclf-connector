with current_alr as (
    select
        file_year
      , file_name
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
    from {{ ref('stg_alr_1_1') }}
)

, retro_alr as (
    select
        file_year
      , file_name
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
      , 0 as excluded
      , 0 as deceased_excluded
      , 0 as other_reasons_excluded
      , 0 as part_a_b_only_excluded
      , 0 as ghp_excluded
      , null as other_shared_sav_init
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
    from {{ ref('stg_alr_1_1_retro') }}
)

select *
from current_alr

union all

select *
from retro_alr
