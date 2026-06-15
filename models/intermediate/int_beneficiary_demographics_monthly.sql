with base as (
    select
          current_bene_mbi_id
        , file_date
        , file_name
        , ingest_datetime
        , bene_mdcr_stus_cd
        , bene_dual_stus_cd
        , bene_entlmt_buyin_ind
    from {{ ref('int_beneficiary_demographics_deduped') }}
)

, monthly_dedup as (
    select
          current_bene_mbi_id
        , file_date
        , file_name
        , bene_mdcr_stus_cd
        , bene_dual_stus_cd
        , bene_entlmt_buyin_ind
        , row_number() over (
            partition by current_bene_mbi_id, file_date
            order by ingest_datetime desc, file_name desc
          ) as rn
    from base
)

select
      current_bene_mbi_id
    , file_date
    , file_name
    , bene_mdcr_stus_cd
    , bene_dual_stus_cd
    , bene_entlmt_buyin_ind
from monthly_dedup
where rn = 1

