{{ config(tags=['connector']) }}

/*
    After the identity dedupe, each claim version (claim ID, line, adjustment type,
    effective date) must appear once in the ADR models. Re-delivered copies that
    differ only in descriptive columns must have been collapsed.
*/

with physician as (

    select
          'physician' as claim_type
        , cur_clm_uniq_id
        , cast(clm_line_num as {{ dbt.type_string() }}) as clm_line_num
        , clm_adjsmt_type_cd
        , clm_efctv_dt
    from {{ ref('int_physician_claim_adr') }}

)

, dme as (

    select
          'dme' as claim_type
        , cur_clm_uniq_id
        , cast(clm_line_num as {{ dbt.type_string() }}) as clm_line_num
        , clm_adjsmt_type_cd
        , clm_efctv_dt
    from {{ ref('int_dme_claim_adr') }}

)

, institutional as (

    select
          'institutional' as claim_type
        , cur_clm_uniq_id
        , '1' as clm_line_num
        , clm_adjsmt_type_cd
        , clm_efctv_dt
    from {{ ref('int_institutional_claim_adr') }}

)

, all_versions as (

    select * from physician
    union all
    select * from dme
    union all
    select * from institutional

)

select
      claim_type
    , cur_clm_uniq_id
    , clm_line_num
    , clm_adjsmt_type_cd
    , clm_efctv_dt
    , count(*) as version_rows
from all_versions
group by
      claim_type
    , cur_clm_uniq_id
    , clm_line_num
    , clm_adjsmt_type_cd
    , clm_efctv_dt
having count(*) > 1
