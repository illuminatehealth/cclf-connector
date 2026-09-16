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
    , case when len(trim(bene_death_dt))>0 then  bene_death_dt else null end as bene_death_dt
    , bene_rng_bgn_dt
    , bene_rng_end_dt
    , bene_1st_name
    , bene_midl_name
    , bene_last_name
    , nullif(trim(bene_orgnl_entlmt_rsn_cd),'') as bene_orgnl_entlmt_rsn_cd
    , bene_entlmt_buyin_ind
    , bene_part_a_enrlmt_bgn_dt
    , bene_part_b_enrlmt_bgn_dt
    , nullif(trim(bene_line_1_adr),'') as bene_line_1_adr
    , nullif(trim(bene_line_2_adr),'') as bene_line_2_adr
    , nullif(trim(bene_line_3_adr),'') as bene_line_3_adr
    , nullif(trim(bene_line_4_adr),'') as bene_line_4_adr
    , nullif(trim(bene_line_5_adr),'') as bene_line_5_adr
    , nullif(trim(bene_line_6_adr),'') as bene_line_6_adr
    , geo_zip_plc_name
    , geo_usps_state_cd
    , geo_zip5_cd
    , geo_zip4_cd
    , filename as file_name
    , {{ cclf_file_date('filename') }} as file_date
    , {{ cclf_performance_year('filename') }} as file_year
    , ingest_datetime
    , file_cadence
    , file_priority
from {{ ref('int_selected_cclf_8') }}