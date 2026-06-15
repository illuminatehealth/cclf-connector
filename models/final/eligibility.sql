/* prep address details for concat */
with demographics as (

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
        , bene_part_a_enrlmt_bgn_dt
        , bene_part_b_enrlmt_bgn_dt
        , bene_line_1_adr
        , case
            when bene_line_2_adr is null then ''
            else cast({{ dbt.concat(["', '","bene_line_2_adr"]) }} as {{ dbt.type_string() }} )
          end as bene_line_2_adr
        , case
            when bene_line_3_adr is null then ''
            else cast({{ dbt.concat(["', '","bene_line_3_adr"]) }} as {{ dbt.type_string() }} )
          end as bene_line_3_adr
        , case
            when bene_line_4_adr is null then ''
            else cast({{ dbt.concat(["', '","bene_line_4_adr"]) }} as {{ dbt.type_string() }} )
          end as bene_line_4_adr
        , case
            when bene_line_5_adr is null then ''
            else cast({{ dbt.concat(["', '","bene_line_5_adr"]) }} as {{ dbt.type_string() }} )
          end as bene_line_5_adr
        , case
            when bene_line_6_adr is null then ''
            else cast({{ dbt.concat(["', '","bene_line_6_adr"]) }} as {{ dbt.type_string() }} )
          end as bene_line_6_adr
        , geo_zip_plc_name
        , geo_usps_state_cd
        , geo_zip5_cd
        , case
            when geo_zip4_cd is null then ''
            else cast({{ dbt.concat(["'-'","geo_zip4_cd"]) }} as {{ dbt.type_string() }} )
            end as geo_zip4_cd
        , file_name
        , file_date
        , ingest_datetime
    from {{ ref('int_beneficiary_demographics_deduped') }}
    where row_num = 1

)



, enrollment as (

    select current_bene_mbi_id, file_date, file_name, enrollment_start_date, enrollment_end_date
    from {{ ref('int_enrollment_stage') }}

)

, monthly_demographics as (
    select
          current_bene_mbi_id
        , file_date
        , bene_mdcr_stus_cd
        , bene_dual_stus_cd
        , bene_entlmt_buyin_ind
    from {{ ref('int_beneficiary_demographics_monthly') }}
)

, joined as (

    select
          cast(demographics.current_bene_mbi_id as {{ dbt.type_string() }} ) as person_id
        , cast(demographics.current_bene_mbi_id as {{ dbt.type_string() }} ) as member_id
        , cast(null as {{ dbt.type_string() }} ) as subscriber_id
        , case demographics.bene_sex_cd
            when '0' then 'unknown'
            when '1' then 'male'
            when '2' then 'female'
          end as gender
        , case demographics.bene_race_cd
            when '0' then 'unknown'
            when '1' then 'white'
            when '2' then 'black'
            when '3' then 'other'
            when '4' then 'asian'
            when '5' then 'hispanic'
            when '6' then 'north american native'
          end as race
        , {{ try_to_cast_date('demographics.bene_dob', 'YYYY-MM-DD') }} as birth_date
        , {{ try_to_cast_date('demographics.bene_death_dt', 'YYYY-MM-DD') }} as death_date
        , cast(case
               when demographics.bene_death_dt is null then 0
               else 1
          end as integer) as death_flag
        , {{ try_to_cast_date('demographics.bene_part_b_enrlmt_bgn_dt', 'YYYY-MM-DD') }} as medicare_part_b_enrollment_start_date
        , year(cast(enrollment.enrollment_start_date as date)) as reference_year
        , cast(enrollment.enrollment_start_date as date) as enrollment_start_date
        , cast(enrollment.enrollment_end_date as date) as enrollment_end_date
        , m.payer
        , m.payer as  payer_type
        , m.{{ quote_column('plan') }} as {{ quote_column('plan') }}
        , cast(i.bene_orgnl_entlmt_rsn_cd as {{ dbt.type_string() }} ) as original_reason_entitlement_code
        , cast(md.bene_dual_stus_cd as {{ dbt.type_string() }} ) as dual_status_code
        , cast(md.bene_mdcr_stus_cd as {{ dbt.type_string() }} ) as medicare_status_code
        , cast(null as {{ dbt.type_string() }} ) as enrollment_status
        , cast(0 as integer) as hospice_flag
        , cast(0 as integer) as institutional_snp_flag
        , cast(0 as integer) as long_term_institutional_flag
        , cast(md.bene_entlmt_buyin_ind as {{ dbt.type_string() }} ) as medicare_entitlement_buyin_indicator
        , cast(null as {{ dbt.type_string() }}) as group_id
        , cast(null as {{ dbt.type_string() }}) as group_name
        , upper(cast(demographics.bene_1st_name as {{ dbt.type_string() }} )) as first_name
        , upper(cast(demographics.bene_last_name as {{ dbt.type_string() }} )) as last_name
        , cast(null as {{ dbt.type_string() }}) as social_security_number
        , cast('self' as {{ dbt.type_string() }} ) as subscriber_relation
        , {{ dbt.concat(
            [
                "demographics.bene_line_1_adr",
                "demographics.bene_line_2_adr",
                "demographics.bene_line_3_adr",
                "demographics.bene_line_4_adr",
                "demographics.bene_line_5_adr",
                "demographics.bene_line_6_adr"
            ]
          ) }} as address
        , upper(cast(demographics.geo_zip_plc_name as {{ dbt.type_string() }} )) as city
        , upper(cast(demographics.geo_usps_state_cd as {{ dbt.type_string() }} )) as state
        , {{ dbt.concat(
            [
                "demographics.geo_zip5_cd",
                "demographics.geo_zip4_cd"
            ]
          ) }} as zip_code
        , cast(NULL as {{ dbt.type_string() }} ) as phone
        , m.data_source as data_source
        , cast(enrollment.file_name as {{ dbt.type_string() }} ) as file_name
        , cast(enrollment.file_date as date) as file_date
        , cast(demographics.ingest_datetime as {{ dbt.type_timestamp() }} ) as ingest_datetime
        , UPPER(cast(bene_midl_name as {{dbt.type_string() }})) AS middle_name
    from demographics
    cross join {{ ref('metadata_fields') }} m 
    inner join {{ ref('int_orec_code') }} i on demographics.current_bene_mbi_id = i.current_bene_mbi_id
    left join enrollment
      on demographics.current_bene_mbi_id = enrollment.current_bene_mbi_id
    left join monthly_demographics md
      on enrollment.current_bene_mbi_id = md.current_bene_mbi_id
     and enrollment.file_date = md.file_date

)

select
      person_id 
    , member_id
    , subscriber_id
    , gender
    , race
    , birth_date
    , death_date
    , death_flag
    , medicare_part_b_enrollment_start_date
    , reference_year
    , enrollment_start_date
    , enrollment_end_date
    , payer
    , payer_type
    , {{ quote_column('plan') }}
    , original_reason_entitlement_code
    , dual_status_code
    , medicare_status_code
    , enrollment_status
    , hospice_flag
    , institutional_snp_flag
    , long_term_institutional_flag
    , medicare_entitlement_buyin_indicator
    , group_id
    , group_name
    , first_name
    , last_name
    , social_security_number
    , subscriber_relation
    , address
    , city
    , state
    , zip_code
    , phone
    , data_source
    , file_name
    , file_date
    , ingest_datetime
    , cast({{ dbt.current_timestamp() }} as {{ dbt.type_timestamp() }}) as tuva_last_run
    , cast(null as {{ dbt.type_string() }}) as name_suffix
    , middle_name
    , cast(null as {{ dbt.type_string() }}) as email
    , cast(null as {{ dbt.type_string() }}) as ethnicity
from joined
where enrollment_start_date is not null
