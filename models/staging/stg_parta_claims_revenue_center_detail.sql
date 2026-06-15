select
      cur_clm_uniq_id
    , clm_line_num
    , bene_mbi_id
    , bene_hic_num
    , clm_type_cd
    , clm_line_from_dt
    , clm_line_thru_dt
    , clm_line_prod_rev_ctr_cd
    , clm_line_instnl_rev_ctr_dt
    , clm_line_hcpcs_cd
    , bene_eqtbl_bic_hicn_num
    , prvdr_oscar_num
    , clm_from_dt
    , clm_thru_dt
    , clm_line_srvc_unit_qty
    , clm_line_cvrd_pd_amt
    , hcpcs_1_mdfr_cd
    , hcpcs_2_mdfr_cd
    , hcpcs_3_mdfr_cd
    , hcpcs_4_mdfr_cd
    , hcpcs_5_mdfr_cd
    , clm_rev_apc_hipps_cd
    , filename as file_name
    , cast({{ dbt.concat(["'20'", "substring(filename, 21, 2)", "'-'", "substring(filename, 23, 2)", "'-'", "substring(filename, 25, 2)"]) }} as date)  AS file_date
    , ingest_datetime
from {{ source('lakehouse','cclf_2') }}
