select
      cur_clm_uniq_id
    , bene_mbi_id
    , bene_hic_num
    , clm_type_cd
    , clm_val_sqnc_num
    , clm_prcdr_cd
    , clm_prcdr_prfrm_dt
    , bene_eqtbl_bic_hicn_num
    , prvdr_oscar_num
    , clm_from_dt
    , clm_thru_dt
    , dgns_prcdr_icd_ind
    , filename as file_name
    , {{ cclf_file_date('filename') }} as file_date
    , ingest_datetime
    , file_cadence
    , file_priority
from {{ ref('int_selected_cclf_3') }}