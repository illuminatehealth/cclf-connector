select
      cur_clm_uniq_id
    , bene_mbi_id
    , bene_hic_num
    , clm_type_cd
    , clm_prod_type_cd
    , clm_val_sqnc_num
    , clm_dgns_cd
    , bene_eqtbl_bic_hicn_num
    , prvdr_oscar_num
    , clm_from_dt
    , clm_thru_dt
    , clm_poa_ind
    , dgns_prcdr_icd_ind
    , filename as file_name
    , cast({{ dbt.concat(["'20'", "substring(filename, 21, 2)", "'-'", "substring(filename, 23, 2)", "'-'", "substring(filename, 25, 2)"]) }} as date)  AS file_date
    , ingest_datetime
from {{ source('lakehouse','cclf_4') }}