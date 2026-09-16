with staged_data as (

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
        , file_name
        , file_date
        , ingest_datetime
        , file_cadence
        , file_priority
    from {{ ref('stg_parta_claims_revenue_center_detail') }}

)

, beneficiary_xref as (

  select * from {{ ref('int_beneficiary_xref_deduped') }}

)

, allowed_header_versions as (

    select
          cur_clm_uniq_id
        , file_date as header_file_date
    from {{ ref('int_institutional_claim_adr') }}
    where row_num = 1

)

/* coalesce current MBI from XREF if exists and MBI on claim */
, add_current_mbi as (

    select
          staged_data.cur_clm_uniq_id
        , staged_data.clm_line_num
        , coalesce(beneficiary_xref.crnt_num, staged_data.bene_mbi_id) as current_bene_mbi_id
        , staged_data.bene_hic_num
        , staged_data.clm_type_cd
        , staged_data.clm_line_from_dt
        , staged_data.clm_line_thru_dt
        , staged_data.clm_line_prod_rev_ctr_cd
        , staged_data.clm_line_instnl_rev_ctr_dt
        , staged_data.clm_line_hcpcs_cd
        , staged_data.bene_eqtbl_bic_hicn_num
        , staged_data.prvdr_oscar_num
        , staged_data.clm_from_dt
        , staged_data.clm_thru_dt
        , staged_data.clm_line_srvc_unit_qty
        , staged_data.clm_line_cvrd_pd_amt
        , staged_data.hcpcs_1_mdfr_cd
        , staged_data.hcpcs_2_mdfr_cd
        , staged_data.hcpcs_3_mdfr_cd
        , staged_data.hcpcs_4_mdfr_cd
        , staged_data.hcpcs_5_mdfr_cd
        , staged_data.clm_rev_apc_hipps_cd
        , staged_data.file_name
        , staged_data.file_date
        , staged_data.ingest_datetime
        , staged_data.file_cadence
        , staged_data.file_priority
    from staged_data
        inner join allowed_header_versions
            on staged_data.cur_clm_uniq_id = allowed_header_versions.cur_clm_uniq_id
           and staged_data.file_date <= allowed_header_versions.header_file_date
        left join beneficiary_xref
            on staged_data.bene_mbi_id = beneficiary_xref.prvs_num

)

/* dedupe to the claim line level pulling most recent file. Changes here are only made to other fields in claim, not to paid amount, therefore we can pull only the most recent without having to sum paid amounts. */
, add_row_num as (

    select *, row_number() over (
        partition by
              cur_clm_uniq_id
            , clm_line_num
        order by file_priority asc, file_date desc, ingest_datetime desc, file_name desc
        ) as row_num
    from add_current_mbi

)
    select
          cur_clm_uniq_id
        , clm_line_num
        , current_bene_mbi_id
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
        , file_name
        , file_date
    from add_row_num
    where row_num = 1
