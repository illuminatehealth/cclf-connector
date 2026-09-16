{{ config(enabled=var('bnex_enabled', false)) }}

/* beneficiaries who declined data sharing (BNEX reason BD), by performance year */
select distinct
      coalesce(x.crnt_num, b.mbi) as current_bene_mbi_id
    , b.performance_year
from {{ ref('stg_bnex') }} b
left join {{ ref('int_beneficiary_xref_deduped') }} x
    on b.mbi = x.prvs_num
where b.bene_exc_reason = 'BD'
