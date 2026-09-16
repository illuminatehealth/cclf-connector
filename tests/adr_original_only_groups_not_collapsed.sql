{{ config(tags=['connector']) }}

/*
    A natural-key group that holds no cancel or replacement is a set of distinct
    final-action claims. The adjustment key must fall back to the claim ID for
    those groups, so every such group contains exactly one claim ID.
*/

with physician as (

    select 'physician' as claim_type, natural_key, cur_clm_uniq_id, clm_adjsmt_type_cd
    from {{ ref('int_physician_claim_adr') }}

)

, dme as (

    select 'dme' as claim_type, natural_key, cur_clm_uniq_id, clm_adjsmt_type_cd
    from {{ ref('int_dme_claim_adr') }}

)

, institutional as (

    select 'institutional' as claim_type, natural_key, cur_clm_uniq_id, clm_adjsmt_type_cd
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
    , natural_key
    , count(distinct cur_clm_uniq_id) as claim_ids_in_group
from all_versions
group by claim_type, natural_key
having sum(case when clm_adjsmt_type_cd in ('1', '2') then 1 else 0 end) = 0
   and count(distinct cur_clm_uniq_id) > 1
