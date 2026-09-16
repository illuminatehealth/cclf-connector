{{ config(enabled=var('bnex_enabled', false)) }}

select
      mbi
    , performance_year
    , report_month
    , bene_exc_reason
from {{ source('lakehouse', 'cclf_bnex') }}
