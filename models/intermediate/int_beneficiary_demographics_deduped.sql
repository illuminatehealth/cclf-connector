with staged_data as (

    select
          bene_mbi_id
        , bene_hic_num
        , bene_fips_state_cd
        , bene_fips_cnty_cd
        , bene_zip_cd
        , bene_dob
        , bene_sex_cd
        , bene_race_cd
        , bene_age
        , bene_mdcr_stus_cd
        , bene_dual_stus_cd
        , bene_death_dt
        , bene_rng_bgn_dt
        , bene_rng_end_dt
        , bene_1st_name
        , bene_midl_name
        , bene_last_name
        , bene_orgnl_entlmt_rsn_cd
        , bene_entlmt_buyin_ind
        , bene_part_a_enrlmt_bgn_dt
        , bene_part_b_enrlmt_bgn_dt
        , bene_line_1_adr
        , bene_line_2_adr
        , bene_line_3_adr
        , bene_line_4_adr
        , bene_line_5_adr
        , bene_line_6_adr
        , geo_zip_plc_name
        , geo_usps_state_cd
        , geo_zip5_cd
        , geo_zip4_cd
        , file_name
        , file_date
        , ingest_datetime
    from {{ ref('stg_beneficiary_demographics') }}

)
, beneficiary_xref as (

    select
          crnt_num
        , prvs_num
    from {{ ref('int_beneficiary_xref_deduped') }}

)

, add_mbi_xref as (

    select
          staged_data.bene_mbi_id
        , coalesce(beneficiary_xref.crnt_num, staged_data.bene_mbi_id) as current_bene_mbi_id
        , staged_data.bene_hic_num
        , staged_data.bene_fips_state_cd
        , staged_data.bene_fips_cnty_cd
        , staged_data.bene_zip_cd
        , staged_data.bene_dob
        , staged_data.bene_sex_cd
        , staged_data.bene_race_cd
        , staged_data.bene_mdcr_stus_cd
        , staged_data.bene_dual_stus_cd
        , staged_data.bene_death_dt
        , staged_data.bene_rng_bgn_dt
        , staged_data.bene_rng_end_dt
        , staged_data.bene_1st_name
        , staged_data.bene_midl_name
        , staged_data.bene_last_name
        , staged_data.bene_orgnl_entlmt_rsn_cd
        , staged_data.bene_entlmt_buyin_ind
        , staged_data.bene_part_a_enrlmt_bgn_dt
        , staged_data.bene_part_b_enrlmt_bgn_dt
        , staged_data.bene_line_1_adr
        , staged_data.bene_line_2_adr
        , staged_data.bene_line_3_adr
        , staged_data.bene_line_4_adr
        , staged_data.bene_line_5_adr
        , staged_data.bene_line_6_adr
        , staged_data.geo_zip_plc_name
        , staged_data.geo_usps_state_cd
        , staged_data.geo_zip5_cd
        , staged_data.geo_zip4_cd
        , staged_data.file_name
        , staged_data.file_date
        , staged_data.ingest_datetime
    from staged_data
        left join beneficiary_xref
            on staged_data.bene_mbi_id = beneficiary_xref.prvs_num
 

)

, get_latest_mbi as (

    select
          bene_mbi_id
        , current_bene_mbi_id
        , bene_hic_num
        , bene_fips_state_cd
        , bene_fips_cnty_cd
        , bene_zip_cd
        , bene_dob
        , bene_sex_cd
        , bene_race_cd
        , bene_mdcr_stus_cd
        , bene_dual_stus_cd
        , bene_death_dt
        , bene_rng_bgn_dt
        , bene_rng_end_dt
        , bene_1st_name
        , bene_midl_name
        , bene_last_name
        , bene_orgnl_entlmt_rsn_cd
        , bene_entlmt_buyin_ind
        , bene_part_a_enrlmt_bgn_dt
        , bene_part_b_enrlmt_bgn_dt
        , bene_line_1_adr
        , bene_line_2_adr
        , bene_line_3_adr
        , bene_line_4_adr
        , bene_line_5_adr
        , bene_line_6_adr
        , geo_zip_plc_name
        , geo_usps_state_cd
        , geo_zip5_cd
        , geo_zip4_cd
        , file_name
        , file_date
        , ingest_datetime
        , row_number() over (
            partition by current_bene_mbi_id
            order by file_date desc
          ) as row_num
    from add_mbi_xref

)

select
      current_bene_mbi_id
    , bene_hic_num
    , bene_fips_state_cd
    , bene_fips_cnty_cd
    , bene_zip_cd
    , bene_dob
    , bene_sex_cd
    , bene_race_cd
    , bene_mdcr_stus_cd
    , bene_dual_stus_cd
    , bene_death_dt
    , bene_rng_bgn_dt
    , bene_rng_end_dt
    , bene_1st_name
    , bene_midl_name
    , bene_last_name
    , bene_orgnl_entlmt_rsn_cd
    , bene_entlmt_buyin_ind
    , bene_part_a_enrlmt_bgn_dt
    , bene_part_b_enrlmt_bgn_dt
    , bene_line_1_adr
    , bene_line_2_adr
    , bene_line_3_adr
    , bene_line_4_adr
    , bene_line_5_adr
    , bene_line_6_adr
    , geo_zip_plc_name
    , geo_usps_state_cd
    , geo_zip5_cd
    , geo_zip4_cd
    , file_name
    , file_date
    , ingest_datetime
    , row_num
from get_latest_mbi
/* commenting out the row_num to include all rows (with joined xref mbi) for pulling OREC code from last non null value*/
-- where row_num = 1 