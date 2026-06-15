/* adding clm_blg_prvdr_oscar_num to data years prior to 2022 since it defines the natural key.
Using the previous field prvdr_oscar_num was did not match between <2022 and >= 2022 so that could not be directly substituted.
*/

with cleaned_source as (

    select
          {{ clean_string('cur_clm_uniq_id') }} as cur_clm_uniq_id
        , {{ clean_string('prvdr_oscar_num') }} as prvdr_oscar_num
        , {{ clean_string('bene_mbi_id') }} as bene_mbi_id
        , {{ clean_string('bene_hic_num') }} as bene_hic_num
        , {{ clean_string('clm_type_cd') }} as clm_type_cd
        , {{ clean_string('clm_from_dt') }} as clm_from_dt
        , {{ clean_string('clm_thru_dt') }} as clm_thru_dt
        , {{ clean_string('clm_bill_fac_type_cd') }} as clm_bill_fac_type_cd
        , {{ clean_string('clm_bill_clsfctn_cd') }} as clm_bill_clsfctn_cd
        , {{ clean_string('prncpl_dgns_cd') }} as prncpl_dgns_cd
        , {{ clean_string('admtg_dgns_cd') }} as admtg_dgns_cd
        , {{ clean_string('clm_mdcr_npmt_rsn_cd') }} as clm_mdcr_npmt_rsn_cd
        , {{ clean_string('clm_pmt_amt') }} as clm_pmt_amt
        , {{ clean_string('clm_nch_prmry_pyr_cd') }} as clm_nch_prmry_pyr_cd
        , {{ clean_string('prvdr_fac_fips_st_cd') }} as prvdr_fac_fips_st_cd
        , {{ clean_string('bene_ptnt_stus_cd') }} as bene_ptnt_stus_cd
        , {{ clean_string('dgns_drg_cd') }} as dgns_drg_cd
        , {{ clean_string('clm_op_srvc_type_cd') }} as clm_op_srvc_type_cd
        , {{ clean_string('fac_prvdr_npi_num') }} as fac_prvdr_npi_num
        , {{ clean_string('oprtg_prvdr_npi_num') }} as oprtg_prvdr_npi_num
        , {{ clean_string('atndg_prvdr_npi_num') }} as atndg_prvdr_npi_num
        , {{ clean_string('othr_prvdr_npi_num') }} as othr_prvdr_npi_num
        , {{ clean_string('clm_adjsmt_type_cd') }} as clm_adjsmt_type_cd
        , {{ clean_string('clm_efctv_dt') }} as clm_efctv_dt
        , {{ clean_string('clm_idr_ld_dt') }} as clm_idr_ld_dt
        , {{ clean_string('bene_eqtbl_bic_hicn_num') }} as bene_eqtbl_bic_hicn_num
        , {{ clean_string('clm_admsn_type_cd') }} as clm_admsn_type_cd
        , {{ clean_string('clm_admsn_src_cd') }} as clm_admsn_src_cd
        , {{ clean_string('clm_bill_freq_cd') }} as clm_bill_freq_cd
        , {{ clean_string('clm_query_cd') }} as clm_query_cd
        , {{ clean_string('dgns_prcdr_icd_ind') }} as dgns_prcdr_icd_ind
        , {{ clean_string('clm_mdcr_instnl_tot_chrg_amt') }} as clm_mdcr_instnl_tot_chrg_amt
        , {{ clean_string('clm_mdcr_ip_pps_cptl_ime_amt') }} as clm_mdcr_ip_pps_cptl_ime_amt
        , {{ clean_string('clm_oprtnl_ime_amt') }} as clm_oprtnl_ime_amt
        , {{ clean_string('clm_mdcr_ip_pps_dsprprtnt_amt') }} as clm_mdcr_ip_pps_dsprprtnt_amt
        , {{ clean_string('clm_hipps_uncompd_care_amt') }} as clm_hipps_uncompd_care_amt
        , {{ clean_string('clm_oprtnl_dsprprtnt_amt') }} as clm_oprtnl_dsprprtnt_amt
        , {{ clean_string('clm_blg_prvdr_oscar_num') }} as clm_blg_prvdr_oscar_num
        , {{ clean_string('clm_blg_prvdr_npi_num') }} as clm_blg_prvdr_npi_num
        , {{ clean_string('clm_oprtg_prvdr_npi_num') }} as clm_oprtg_prvdr_npi_num
        , {{ clean_string('clm_atndg_prvdr_npi_num') }} as clm_atndg_prvdr_npi_num
        , {{ clean_string('clm_othr_prvdr_npi_num') }} as clm_othr_prvdr_npi_num
        , {{ clean_string('clm_cntl_num') }} as clm_cntl_num
        , {{ clean_string('clm_org_cntl_num') }} as clm_org_cntl_num
        , {{ clean_string('clm_cntrctr_num') }} as clm_cntrctr_num
        , {{ clean_string('filename') }} as filename
        , ingest_datetime
    from {{ source('lakehouse','cclf_1') }}

)

, cte as (

    select
          cur_clm_uniq_id
        , clm_blg_prvdr_oscar_num
        , row_number() over (
            partition by cur_clm_uniq_id
            order by filename
          ) as row_num
    from cleaned_source
    where clm_blg_prvdr_oscar_num is not null

)

select
      s.cur_clm_uniq_id
    , s.prvdr_oscar_num
    , s.bene_mbi_id
    , s.bene_hic_num
    , s.clm_type_cd
    , s.clm_from_dt
    , s.clm_thru_dt
    , s.clm_bill_fac_type_cd
    , s.clm_bill_clsfctn_cd
    , s.prncpl_dgns_cd
    , s.admtg_dgns_cd
    , s.clm_mdcr_npmt_rsn_cd
    , s.clm_pmt_amt
    , s.clm_nch_prmry_pyr_cd
    , s.prvdr_fac_fips_st_cd
    , s.bene_ptnt_stus_cd
    , s.dgns_drg_cd
    , s.clm_op_srvc_type_cd
    , s.fac_prvdr_npi_num
    , s.oprtg_prvdr_npi_num
    , s.atndg_prvdr_npi_num
    , s.othr_prvdr_npi_num
    , s.clm_adjsmt_type_cd
    , s.clm_efctv_dt
    , s.clm_idr_ld_dt
    , s.bene_eqtbl_bic_hicn_num
    , s.clm_admsn_type_cd
    , s.clm_admsn_src_cd
    , s.clm_bill_freq_cd
    , s.clm_query_cd
    , s.dgns_prcdr_icd_ind
    , cast(s.clm_mdcr_instnl_tot_chrg_amt as decimal(18, 2)) as clm_mdcr_instnl_tot_chrg_amt
    , cast(s.clm_mdcr_ip_pps_cptl_ime_amt as decimal(18, 2)) as clm_mdcr_ip_pps_cptl_ime_amt
    , cast(s.clm_oprtnl_ime_amt as decimal(18, 2)) as clm_oprtnl_ime_amt
    , cast(s.clm_mdcr_ip_pps_dsprprtnt_amt as decimal(18, 2)) as clm_mdcr_ip_pps_dsprprtnt_amt
    , cast(s.clm_hipps_uncompd_care_amt as decimal(18, 2)) as clm_hipps_uncompd_care_amt
    , cast(s.clm_oprtnl_dsprprtnt_amt as decimal(18, 2)) as clm_oprtnl_dsprprtnt_amt
    , case
        when c.clm_blg_prvdr_oscar_num is null then s.prvdr_oscar_num
        else c.clm_blg_prvdr_oscar_num
      end as clm_blg_prvdr_oscar_num --claims never updated in 22+ won't have clm_blg_prvdr_oscar_num, use prvdr_oscar_num for the natural key.
    , s.clm_blg_prvdr_npi_num
    , s.clm_oprtg_prvdr_npi_num
    , s.clm_atndg_prvdr_npi_num
    , s.clm_othr_prvdr_npi_num
    , s.clm_cntl_num
    , s.clm_org_cntl_num
    , s.clm_cntrctr_num
    , s.filename as file_name
    , cast({{ dbt.concat(["'20'", "substring(s.filename, 21, 2)", "'-'", "substring(s.filename, 23, 2)", "'-'", "substring(s.filename, 25, 2)"]) }} as date) as file_date
    , s.ingest_datetime
from cleaned_source s
left join cte c on s.cur_clm_uniq_id = c.cur_clm_uniq_id
    and c.row_num = 1
