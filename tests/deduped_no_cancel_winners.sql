{{ config(tags=['connector']) }}

/*
    A claim version whose winning row is a cancel was voided and must not reach
    the deduped models. Any deduped claim line that maps back to a winning cancel
    in the ADR models is a failure.
*/

with physician_winners as (

    select
          'physician' as claim_type
        , cur_clm_uniq_id
        , cast(clm_line_num as {{ dbt.type_string() }}) as clm_line_num
        , clm_adjsmt_type_cd
    from {{ ref('int_physician_claim_adr') }}
    where row_num = 1

)

, dme_winners as (

    select
          'dme' as claim_type
        , cur_clm_uniq_id
        , cast(clm_line_num as {{ dbt.type_string() }}) as clm_line_num
        , clm_adjsmt_type_cd
    from {{ ref('int_dme_claim_adr') }}
    where row_num = 1

)

, institutional_winners as (

    select
          'institutional' as claim_type
        , cur_clm_uniq_id
        , cast(null as {{ dbt.type_string() }}) as clm_line_num
        , clm_adjsmt_type_cd
    from {{ ref('int_institutional_claim_adr') }}
    where row_num = 1

)

, deduped as (

    select 'physician' as claim_type, claim_id, cast(claim_line_number as {{ dbt.type_string() }}) as claim_line_number
    from {{ ref('int_physician_claim_deduped') }}
    union all
    select 'dme' as claim_type, claim_id, cast(claim_line_number as {{ dbt.type_string() }}) as claim_line_number
    from {{ ref('int_dme_claim_deduped') }}
    union all
    select distinct 'institutional' as claim_type, claim_id, cast(null as {{ dbt.type_string() }}) as claim_line_number
    from {{ ref('int_institutional_claim_deduped') }}

)

select
      d.claim_type
    , d.claim_id
    , d.claim_line_number
from deduped d
inner join (
    select * from physician_winners
    union all
    select * from dme_winners
    union all
    select * from institutional_winners
) w
    on w.claim_type = d.claim_type
   and w.cur_clm_uniq_id = d.claim_id
   and coalesce(w.clm_line_num, '') = coalesce(d.claim_line_number, '')
where w.clm_adjsmt_type_cd = '1'
