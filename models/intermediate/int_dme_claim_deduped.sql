with sort_adjusted_claims as (

    select
          cur_clm_uniq_id
        , clm_line_num
        , current_bene_mbi_id
        , clm_type_cd
        , clm_from_dt
        , clm_thru_dt
        , clm_pos_cd
        , clm_line_from_dt
        , clm_line_thru_dt
        , clm_line_hcpcs_cd
        , clm_line_cvrd_pd_amt
        , payto_prvdr_npi_num
        , ordrg_prvdr_npi_num
        , clm_adjsmt_type_cd
        , clm_efctv_dt
        , clm_cntl_num
        , clm_line_alowd_chrg_amt
        , file_name
        , file_date
        , row_num
        , natural_key
        , ingest_datetime
        , file_cadence
        , file_priority
    from {{ ref('int_dme_claim_adr') }}

)

, filter_claims as (

    select
          sort_adjusted_claims.cur_clm_uniq_id
        , sort_adjusted_claims.clm_line_num
        , sort_adjusted_claims.current_bene_mbi_id
        , sort_adjusted_claims.clm_type_cd
        , sort_adjusted_claims.clm_from_dt
        , sort_adjusted_claims.clm_thru_dt
        , sort_adjusted_claims.clm_pos_cd
        , sort_adjusted_claims.clm_line_from_dt
        , sort_adjusted_claims.clm_line_thru_dt
        , sort_adjusted_claims.clm_line_hcpcs_cd
        , clm_line_cvrd_pd_amt as clm_line_cvrd_pd_amt
        , sort_adjusted_claims.payto_prvdr_npi_num
        , sort_adjusted_claims.ordrg_prvdr_npi_num
        , sort_adjusted_claims.clm_adjsmt_type_cd
        , sort_adjusted_claims.clm_efctv_dt
        , sort_adjusted_claims.clm_cntl_num
        , clm_line_alowd_chrg_amt as clm_line_alowd_chrg_amt
        , sort_adjusted_claims.file_name
        , sort_adjusted_claims.file_date
        , sort_adjusted_claims.natural_key
        , sort_adjusted_claims.ingest_datetime
        , sort_adjusted_claims.file_cadence
        , sort_adjusted_claims.file_priority
    from sort_adjusted_claims
    where sort_adjusted_claims.row_num = 1
      /* a winning cancel means the claim version was voided: drop it so the set nets to zero */
      and (sort_adjusted_claims.clm_adjsmt_type_cd is null or sort_adjusted_claims.clm_adjsmt_type_cd <> '1')


)

, max_row_num as (
  select natural_key
  ,max(row_num) as max_row_num_key
  from sort_adjusted_claims
  group by natural_key
)

,first_paid_date_cte as (
select s.natural_key
,clm_efctv_dt as first_paid_date
from sort_adjusted_claims s
inner join max_row_num m on s.natural_key=m.natural_key 
and
s.row_num = m.max_row_num_key 
)

/*
    remove claim lines where claim ID+line number not unique
    even after adjustments have been applied
*/
, claim_dupes as (

    select cur_clm_uniq_id, clm_line_num
    from filter_claims
    group by cur_clm_uniq_id, clm_line_num
    having count(*) > 1

)

, remove_dupes as (

    select filter_claims.*
    from filter_claims
        left join claim_dupes
            on filter_claims.cur_clm_uniq_id = claim_dupes.cur_clm_uniq_id
            and filter_claims.clm_line_num = claim_dupes.clm_line_num
    where claim_dupes.cur_clm_uniq_id is null

)

, mapping as (

    select
          cur_clm_uniq_id as claim_id
        , clm_line_num as claim_line_number
        , 'professional' as claim_type
        , clm_type_cd as claim_type_code
        , clm_type_cd as x_claim_type_code
        , current_bene_mbi_id as person_id
        , current_bene_mbi_id as member_id
        , m.payer as payer
        , m.{{ quote_column('plan') }} as {{ quote_column('plan') }}
        , cast(null as {{ dbt.type_string() }} ) as ccn
        , case
            when clm_from_dt in ('1000-01-01', '9999-12-31') then null
            else clm_from_dt
          end as claim_start_date
        , case
            when clm_thru_dt in ('1000-01-01', '9999-12-31') then null
            else clm_thru_dt
          end as claim_end_date
        , case
            when clm_line_from_dt in ('1000-01-01', '9999-12-31') then null
            else clm_line_from_dt
          end as claim_line_start_date
        , case
            when clm_line_thru_dt in ('1000-01-01', '9999-12-31') then null
            else clm_line_thru_dt
          end as claim_line_end_date
        , null as admission_date
        , null as discharge_date
        , null as admit_source_code
        , null as admit_type_code
        , null as discharge_disposition_code
        , clm_pos_cd as place_of_service_code
        , null as bill_type_code
        , null as drg_code
        , null as revenue_center_code
        , null as service_unit_quantity
        , clm_line_hcpcs_cd as hcpcs_code
        , null as hcpcs_modifier_1
        , null as hcpcs_modifier_2
        , null as hcpcs_modifier_3
        , null as hcpcs_modifier_4
        , null as hcpcs_modifier_5
        , ordrg_prvdr_npi_num as rendering_npi
        , null as rendering_tin
        , payto_prvdr_npi_num as billing_npi
        , null as billing_tin
        , null as facility_npi
        , cast(null as {{ dbt.type_string() }}) as x_facility_fips_state_code
        , cast(null as {{ dbt.type_string() }}) as x_rendering_fips_state_code
        , null as claim_provider_specialty_code
        , case
            when clm_efctv_dt in ('1000-01-01', '9999-12-31') then null
            else clm_efctv_dt
          end as paid_date
        , clm_line_cvrd_pd_amt as paid_amount
        , clm_line_cvrd_pd_amt/.98 as net_paid_amount/* seq */
        , clm_line_alowd_chrg_amt as allowed_amount
        , clm_line_alowd_chrg_amt as charge_amount
        , null as coinsurance_amount
        , null as copayment_amount
        , null as deductible_amount
        , null as total_cost_amount
        , null as diagnosis_code_type
        , null as diagnosis_code_1
        , null as diagnosis_code_2
        , null as diagnosis_code_3
        , null as diagnosis_code_4
        , null as diagnosis_code_5
        , null as diagnosis_code_6
        , null as diagnosis_code_7
        , null as diagnosis_code_8
        , null as diagnosis_code_9
        , null as diagnosis_code_10
        , null as diagnosis_code_11
        , null as diagnosis_code_12
        , null as diagnosis_code_13
        , null as diagnosis_code_14
        , null as diagnosis_code_15
        , null as diagnosis_code_16
        , null as diagnosis_code_17
        , null as diagnosis_code_18
        , null as diagnosis_code_19
        , null as diagnosis_code_20
        , null as diagnosis_code_21
        , null as diagnosis_code_22
        , null as diagnosis_code_23
        , null as diagnosis_code_24
        , null as diagnosis_code_25
        , null as diagnosis_poa_1
        , null as diagnosis_poa_2
        , null as diagnosis_poa_3
        , null as diagnosis_poa_4
        , null as diagnosis_poa_5
        , null as diagnosis_poa_6
        , null as diagnosis_poa_7
        , null as diagnosis_poa_8
        , null as diagnosis_poa_9
        , null as diagnosis_poa_10
        , null as diagnosis_poa_11
        , null as diagnosis_poa_12
        , null as diagnosis_poa_13
        , null as diagnosis_poa_14
        , null as diagnosis_poa_15
        , null as diagnosis_poa_16
        , null as diagnosis_poa_17
        , null as diagnosis_poa_18
        , null as diagnosis_poa_19
        , null as diagnosis_poa_20
        , null as diagnosis_poa_21
        , null as diagnosis_poa_22
        , null as diagnosis_poa_23
        , null as diagnosis_poa_24
        , null as diagnosis_poa_25
        , null as procedure_code_type
        , null as procedure_code_1
        , null as procedure_code_2
        , null as procedure_code_3
        , null as procedure_code_4
        , null as procedure_code_5
        , null as procedure_code_6
        , null as procedure_code_7
        , null as procedure_code_8
        , null as procedure_code_9
        , null as procedure_code_10
        , null as procedure_code_11
        , null as procedure_code_12
        , null as procedure_code_13
        , null as procedure_code_14
        , null as procedure_code_15
        , null as procedure_code_16
        , null as procedure_code_17
        , null as procedure_code_18
        , null as procedure_code_19
        , null as procedure_code_20
        , null as procedure_code_21
        , null as procedure_code_22
        , null as procedure_code_23
        , null as procedure_code_24
        , null as procedure_code_25
        , null as procedure_date_1
        , null as procedure_date_2
        , null as procedure_date_3
        , null as procedure_date_4
        , null as procedure_date_5
        , null as procedure_date_6
        , null as procedure_date_7
        , null as procedure_date_8
        , null as procedure_date_9
        , null as procedure_date_10
        , null as procedure_date_11
        , null as procedure_date_12
        , null as procedure_date_13
        , null as procedure_date_14
        , null as procedure_date_15
        , null as procedure_date_16
        , null as procedure_date_17
        , null as procedure_date_18
        , null as procedure_date_19
        , null as procedure_date_20
        , null as procedure_date_21
        , null as procedure_date_22
        , null as procedure_date_23
        , null as procedure_date_24
        , null as procedure_date_25
        , 1 as in_network_flag
        , m.data_source as data_source
        , file_name
        , file_date
        , ingest_datetime as ingest_datetime
        , file_cadence as file_cadence
        , file_priority as file_priority
        , r.natural_key
        , f.first_paid_date
    from remove_dupes r
    cross join {{ ref('metadata_fields') }} m 
    inner join first_paid_date_cte f on r.natural_key = f.natural_key

)

, add_data_types as (

    select
          cast(claim_id as {{ dbt.type_string() }} ) as claim_id
        , cast(claim_line_number as integer) as claim_line_number
        , cast(claim_type as {{ dbt.type_string() }} ) as claim_type
        , cast(claim_type_code as {{ dbt.type_string() }} ) as claim_type_code
        , cast(x_claim_type_code as {{ dbt.type_string() }} ) as x_claim_type_code
        , cast(person_id as {{ dbt.type_string() }} ) as person_id
        , cast(member_id as {{ dbt.type_string() }} ) as member_id
        , cast(payer as {{ dbt.type_string() }} ) as payer
        , cast({{ quote_column('plan') }} as {{ dbt.type_string() }} ) as {{ quote_column('plan') }}
        , cast(ccn as {{ dbt.type_string() }} ) as ccn
        , {{ try_to_cast_date('claim_start_date', 'YYYY-MM-DD') }} as claim_start_date
        , {{ try_to_cast_date('claim_end_date', 'YYYY-MM-DD') }} as claim_end_date
        , {{ try_to_cast_date('claim_line_start_date', 'YYYY-MM-DD') }} as claim_line_start_date
        , {{ try_to_cast_date('claim_line_end_date', 'YYYY-MM-DD') }} as claim_line_end_date
        , {{ try_to_cast_date('admission_date', 'YYYY-MM-DD') }} as admission_date
        , {{ try_to_cast_date('discharge_date', 'YYYY-MM-DD') }} as discharge_date
        , cast(admit_source_code as {{ dbt.type_string() }} ) as admit_source_code
        , cast(admit_type_code as {{ dbt.type_string() }} ) as admit_type_code
        , cast(discharge_disposition_code as {{ dbt.type_string() }} ) as discharge_disposition_code
        , cast(place_of_service_code as {{ dbt.type_string() }} ) as place_of_service_code
        , cast(bill_type_code as {{ dbt.type_string() }} ) as bill_type_code
        , cast(drg_code as {{ dbt.type_string() }} ) as drg_code
        , cast(revenue_center_code as {{ dbt.type_string() }} ) as revenue_center_code
        , cast(service_unit_quantity as float) as service_unit_quantity
        , cast(hcpcs_code as {{ dbt.type_string() }} ) as hcpcs_code
        , cast(hcpcs_modifier_1 as {{ dbt.type_string() }} ) as hcpcs_modifier_1
        , cast(hcpcs_modifier_2 as {{ dbt.type_string() }} ) as hcpcs_modifier_2
        , cast(hcpcs_modifier_3 as {{ dbt.type_string() }} ) as hcpcs_modifier_3
        , cast(hcpcs_modifier_4 as {{ dbt.type_string() }} ) as hcpcs_modifier_4
        , cast(hcpcs_modifier_5 as {{ dbt.type_string() }} ) as hcpcs_modifier_5
        , cast(rendering_npi as {{ dbt.type_string() }} ) as rendering_npi
        , cast(rendering_tin as {{ dbt.type_string() }} ) as rendering_tin
        , cast(billing_npi as {{ dbt.type_string() }} ) as billing_npi
        , cast(billing_tin as {{ dbt.type_string() }} ) as billing_tin
        , cast(facility_npi as {{ dbt.type_string() }} ) as facility_npi
        , cast(x_facility_fips_state_code as {{ dbt.type_string() }} ) as x_facility_fips_state_code
        , cast(x_rendering_fips_state_code as {{ dbt.type_string() }} ) as x_rendering_fips_state_code
        , cast(claim_provider_specialty_code as {{ dbt.type_string() }} ) as claim_provider_specialty_code
        , {{ try_to_cast_date('paid_date', 'YYYY-MM-DD') }} as paid_date
        , {{ try_to_cast_date('first_paid_date', 'YYYY-MM-DD') }} as first_paid_date
        , {{ cast_numeric('paid_amount') }} as paid_amount
        , {{ cast_numeric('net_paid_amount') }} as net_paid_amount
        , {{ cast_numeric('allowed_amount') }} as allowed_amount
        , {{ cast_numeric('charge_amount') }} as charge_amount
        , {{ cast_numeric('coinsurance_amount') }} as coinsurance_amount
        , {{ cast_numeric('copayment_amount') }} as copayment_amount
        , {{ cast_numeric('deductible_amount') }} as deductible_amount
        , {{ cast_numeric('total_cost_amount') }} as total_cost_amount
        , cast(diagnosis_code_type as {{ dbt.type_string() }} ) as diagnosis_code_type
        , cast(diagnosis_code_1 as {{ dbt.type_string() }} ) as diagnosis_code_1
        , cast(diagnosis_code_2 as {{ dbt.type_string() }} ) as diagnosis_code_2
        , cast(diagnosis_code_3 as {{ dbt.type_string() }} ) as diagnosis_code_3
        , cast(diagnosis_code_4 as {{ dbt.type_string() }} ) as diagnosis_code_4
        , cast(diagnosis_code_5 as {{ dbt.type_string() }} ) as diagnosis_code_5
        , cast(diagnosis_code_6 as {{ dbt.type_string() }} ) as diagnosis_code_6
        , cast(diagnosis_code_7 as {{ dbt.type_string() }} ) as diagnosis_code_7
        , cast(diagnosis_code_8 as {{ dbt.type_string() }} ) as diagnosis_code_8
        , cast(diagnosis_code_9 as {{ dbt.type_string() }} ) as diagnosis_code_9
        , cast(diagnosis_code_10 as {{ dbt.type_string() }} ) as diagnosis_code_10
        , cast(diagnosis_code_11 as {{ dbt.type_string() }} ) as diagnosis_code_11
        , cast(diagnosis_code_12 as {{ dbt.type_string() }} ) as diagnosis_code_12
        , cast(diagnosis_code_13 as {{ dbt.type_string() }} ) as diagnosis_code_13
        , cast(diagnosis_code_14 as {{ dbt.type_string() }} ) as diagnosis_code_14
        , cast(diagnosis_code_15 as {{ dbt.type_string() }} ) as diagnosis_code_15
        , cast(diagnosis_code_16 as {{ dbt.type_string() }} ) as diagnosis_code_16
        , cast(diagnosis_code_17 as {{ dbt.type_string() }} ) as diagnosis_code_17
        , cast(diagnosis_code_18 as {{ dbt.type_string() }} ) as diagnosis_code_18
        , cast(diagnosis_code_19 as {{ dbt.type_string() }} ) as diagnosis_code_19
        , cast(diagnosis_code_20 as {{ dbt.type_string() }} ) as diagnosis_code_20
        , cast(diagnosis_code_21 as {{ dbt.type_string() }} ) as diagnosis_code_21
        , cast(diagnosis_code_22 as {{ dbt.type_string() }} ) as diagnosis_code_22
        , cast(diagnosis_code_23 as {{ dbt.type_string() }} ) as diagnosis_code_23
        , cast(diagnosis_code_24 as {{ dbt.type_string() }} ) as diagnosis_code_24
        , cast(diagnosis_code_25 as {{ dbt.type_string() }} ) as diagnosis_code_25
        , cast(diagnosis_poa_1 as {{ dbt.type_string() }} ) as diagnosis_poa_1
        , cast(diagnosis_poa_2 as {{ dbt.type_string() }} ) as diagnosis_poa_2
        , cast(diagnosis_poa_3 as {{ dbt.type_string() }} ) as diagnosis_poa_3
        , cast(diagnosis_poa_4 as {{ dbt.type_string() }} ) as diagnosis_poa_4
        , cast(diagnosis_poa_5 as {{ dbt.type_string() }} ) as diagnosis_poa_5
        , cast(diagnosis_poa_6 as {{ dbt.type_string() }} ) as diagnosis_poa_6
        , cast(diagnosis_poa_7 as {{ dbt.type_string() }} ) as diagnosis_poa_7
        , cast(diagnosis_poa_8 as {{ dbt.type_string() }} ) as diagnosis_poa_8
        , cast(diagnosis_poa_9 as {{ dbt.type_string() }} ) as diagnosis_poa_9
        , cast(diagnosis_poa_10 as {{ dbt.type_string() }} ) as diagnosis_poa_10
        , cast(diagnosis_poa_11 as {{ dbt.type_string() }} ) as diagnosis_poa_11
        , cast(diagnosis_poa_12 as {{ dbt.type_string() }} ) as diagnosis_poa_12
        , cast(diagnosis_poa_13 as {{ dbt.type_string() }} ) as diagnosis_poa_13
        , cast(diagnosis_poa_14 as {{ dbt.type_string() }} ) as diagnosis_poa_14
        , cast(diagnosis_poa_15 as {{ dbt.type_string() }} ) as diagnosis_poa_15
        , cast(diagnosis_poa_16 as {{ dbt.type_string() }} ) as diagnosis_poa_16
        , cast(diagnosis_poa_17 as {{ dbt.type_string() }} ) as diagnosis_poa_17
        , cast(diagnosis_poa_18 as {{ dbt.type_string() }} ) as diagnosis_poa_18
        , cast(diagnosis_poa_19 as {{ dbt.type_string() }} ) as diagnosis_poa_19
        , cast(diagnosis_poa_20 as {{ dbt.type_string() }} ) as diagnosis_poa_20
        , cast(diagnosis_poa_21 as {{ dbt.type_string() }} ) as diagnosis_poa_21
        , cast(diagnosis_poa_22 as {{ dbt.type_string() }} ) as diagnosis_poa_22
        , cast(diagnosis_poa_23 as {{ dbt.type_string() }} ) as diagnosis_poa_23
        , cast(diagnosis_poa_24 as {{ dbt.type_string() }} ) as diagnosis_poa_24
        , cast(diagnosis_poa_25 as {{ dbt.type_string() }} ) as diagnosis_poa_25
        , cast(procedure_code_type as {{ dbt.type_string() }} ) as procedure_code_type
        , cast(procedure_code_1 as {{ dbt.type_string() }} ) as procedure_code_1
        , cast(procedure_code_2 as {{ dbt.type_string() }} ) as procedure_code_2
        , cast(procedure_code_3 as {{ dbt.type_string() }} ) as procedure_code_3
        , cast(procedure_code_4 as {{ dbt.type_string() }} ) as procedure_code_4
        , cast(procedure_code_5 as {{ dbt.type_string() }} ) as procedure_code_5
        , cast(procedure_code_6 as {{ dbt.type_string() }} ) as procedure_code_6
        , cast(procedure_code_7 as {{ dbt.type_string() }} ) as procedure_code_7
        , cast(procedure_code_8 as {{ dbt.type_string() }} ) as procedure_code_8
        , cast(procedure_code_9 as {{ dbt.type_string() }} ) as procedure_code_9
        , cast(procedure_code_10 as {{ dbt.type_string() }} ) as procedure_code_10
        , cast(procedure_code_11 as {{ dbt.type_string() }} ) as procedure_code_11
        , cast(procedure_code_12 as {{ dbt.type_string() }} ) as procedure_code_12
        , cast(procedure_code_13 as {{ dbt.type_string() }} ) as procedure_code_13
        , cast(procedure_code_14 as {{ dbt.type_string() }} ) as procedure_code_14
        , cast(procedure_code_15 as {{ dbt.type_string() }} ) as procedure_code_15
        , cast(procedure_code_16 as {{ dbt.type_string() }} ) as procedure_code_16
        , cast(procedure_code_17 as {{ dbt.type_string() }} ) as procedure_code_17
        , cast(procedure_code_18 as {{ dbt.type_string() }} ) as procedure_code_18
        , cast(procedure_code_19 as {{ dbt.type_string() }} ) as procedure_code_19
        , cast(procedure_code_20 as {{ dbt.type_string() }} ) as procedure_code_20
        , cast(procedure_code_21 as {{ dbt.type_string() }} ) as procedure_code_21
        , cast(procedure_code_22 as {{ dbt.type_string() }} ) as procedure_code_22
        , cast(procedure_code_23 as {{ dbt.type_string() }} ) as procedure_code_23
        , cast(procedure_code_24 as {{ dbt.type_string() }} ) as procedure_code_24
        , cast(procedure_code_25 as {{ dbt.type_string() }} ) as procedure_code_25
        , {{ try_to_cast_date('procedure_date_1', 'YYYY-MM-DD') }} as procedure_date_1
        , {{ try_to_cast_date('procedure_date_2', 'YYYY-MM-DD') }} as procedure_date_2
        , {{ try_to_cast_date('procedure_date_3', 'YYYY-MM-DD') }} as procedure_date_3
        , {{ try_to_cast_date('procedure_date_4', 'YYYY-MM-DD') }} as procedure_date_4
        , {{ try_to_cast_date('procedure_date_5', 'YYYY-MM-DD') }} as procedure_date_5
        , {{ try_to_cast_date('procedure_date_6', 'YYYY-MM-DD') }} as procedure_date_6
        , {{ try_to_cast_date('procedure_date_7', 'YYYY-MM-DD') }} as procedure_date_7
        , {{ try_to_cast_date('procedure_date_8', 'YYYY-MM-DD') }} as procedure_date_8
        , {{ try_to_cast_date('procedure_date_9', 'YYYY-MM-DD') }} as procedure_date_9
        , {{ try_to_cast_date('procedure_date_10', 'YYYY-MM-DD') }} as procedure_date_10
        , {{ try_to_cast_date('procedure_date_11', 'YYYY-MM-DD') }} as procedure_date_11
        , {{ try_to_cast_date('procedure_date_12', 'YYYY-MM-DD') }} as procedure_date_12
        , {{ try_to_cast_date('procedure_date_13', 'YYYY-MM-DD') }} as procedure_date_13
        , {{ try_to_cast_date('procedure_date_14', 'YYYY-MM-DD') }} as procedure_date_14
        , {{ try_to_cast_date('procedure_date_15', 'YYYY-MM-DD') }} as procedure_date_15
        , {{ try_to_cast_date('procedure_date_16', 'YYYY-MM-DD') }} as procedure_date_16
        , {{ try_to_cast_date('procedure_date_17', 'YYYY-MM-DD') }} as procedure_date_17
        , {{ try_to_cast_date('procedure_date_18', 'YYYY-MM-DD') }} as procedure_date_18
        , {{ try_to_cast_date('procedure_date_19', 'YYYY-MM-DD') }} as procedure_date_19
        , {{ try_to_cast_date('procedure_date_20', 'YYYY-MM-DD') }} as procedure_date_20
        , {{ try_to_cast_date('procedure_date_21', 'YYYY-MM-DD') }} as procedure_date_21
        , {{ try_to_cast_date('procedure_date_22', 'YYYY-MM-DD') }} as procedure_date_22
        , {{ try_to_cast_date('procedure_date_23', 'YYYY-MM-DD') }} as procedure_date_23
        , {{ try_to_cast_date('procedure_date_24', 'YYYY-MM-DD') }} as procedure_date_24
        , {{ try_to_cast_date('procedure_date_25', 'YYYY-MM-DD') }} as procedure_date_25
        , cast(in_network_flag as integer) as in_network_flag
        , cast(data_source as {{ dbt.type_string() }} ) as data_source
        , cast(file_name as {{ dbt.type_string() }} ) as file_name
        , {{ try_to_cast_date('file_date', 'YYYY-MM-DD') }} as file_date
        , cast(ingest_datetime as date ) as ingest_datetime
        , cast(file_cadence as {{ dbt.type_string() }}) as file_cadence
        , cast(file_priority as {{ dbt.type_int() }}) as file_priority
    from mapping

)

select
      claim_id
    , claim_line_number
    , claim_type
    , claim_type_code
    , x_claim_type_code
    , person_id
    , member_id
    , payer
    , {{ quote_column('plan') }}
    , claim_start_date
    , claim_end_date
    , claim_line_start_date
    , claim_line_end_date
    , admission_date
    , discharge_date
    , admit_source_code
    , admit_type_code
    , discharge_disposition_code
    , place_of_service_code
    , bill_type_code
    , drg_code
    , revenue_center_code
    , service_unit_quantity
    , hcpcs_code
    , hcpcs_modifier_1
    , hcpcs_modifier_2
    , hcpcs_modifier_3
    , hcpcs_modifier_4
    , hcpcs_modifier_5
    , rendering_npi
    , rendering_tin
    , billing_npi
    , billing_tin
    , facility_npi
    , x_facility_fips_state_code
    , x_rendering_fips_state_code
    , claim_provider_specialty_code
    , paid_date
    , first_paid_date
    , paid_amount
    , net_paid_amount
    , allowed_amount
    , charge_amount
    , coinsurance_amount
    , copayment_amount
    , deductible_amount
    , total_cost_amount
    , diagnosis_code_type
    , diagnosis_code_1
    , diagnosis_code_2
    , diagnosis_code_3
    , diagnosis_code_4
    , diagnosis_code_5
    , diagnosis_code_6
    , diagnosis_code_7
    , diagnosis_code_8
    , diagnosis_code_9
    , diagnosis_code_10
    , diagnosis_code_11
    , diagnosis_code_12
    , diagnosis_code_13
    , diagnosis_code_14
    , diagnosis_code_15
    , diagnosis_code_16
    , diagnosis_code_17
    , diagnosis_code_18
    , diagnosis_code_19
    , diagnosis_code_20
    , diagnosis_code_21
    , diagnosis_code_22
    , diagnosis_code_23
    , diagnosis_code_24
    , diagnosis_code_25
    , diagnosis_poa_1
    , diagnosis_poa_2
    , diagnosis_poa_3
    , diagnosis_poa_4
    , diagnosis_poa_5
    , diagnosis_poa_6
    , diagnosis_poa_7
    , diagnosis_poa_8
    , diagnosis_poa_9
    , diagnosis_poa_10
    , diagnosis_poa_11
    , diagnosis_poa_12
    , diagnosis_poa_13
    , diagnosis_poa_14
    , diagnosis_poa_15
    , diagnosis_poa_16
    , diagnosis_poa_17
    , diagnosis_poa_18
    , diagnosis_poa_19
    , diagnosis_poa_20
    , diagnosis_poa_21
    , diagnosis_poa_22
    , diagnosis_poa_23
    , diagnosis_poa_24
    , diagnosis_poa_25
    , procedure_code_type
    , procedure_code_1
    , procedure_code_2
    , procedure_code_3
    , procedure_code_4
    , procedure_code_5
    , procedure_code_6
    , procedure_code_7
    , procedure_code_8
    , procedure_code_9
    , procedure_code_10
    , procedure_code_11
    , procedure_code_12
    , procedure_code_13
    , procedure_code_14
    , procedure_code_15
    , procedure_code_16
    , procedure_code_17
    , procedure_code_18
    , procedure_code_19
    , procedure_code_20
    , procedure_code_21
    , procedure_code_22
    , procedure_code_23
    , procedure_code_24
    , procedure_code_25
    , procedure_date_1
    , procedure_date_2
    , procedure_date_3
    , procedure_date_4
    , procedure_date_5
    , procedure_date_6
    , procedure_date_7
    , procedure_date_8
    , procedure_date_9
    , procedure_date_10
    , procedure_date_11
    , procedure_date_12
    , procedure_date_13
    , procedure_date_14
    , procedure_date_15
    , procedure_date_16
    , procedure_date_17
    , procedure_date_18
    , procedure_date_19
    , procedure_date_20
    , procedure_date_21
    , procedure_date_22
    , procedure_date_23
    , procedure_date_24
    , procedure_date_25
    , in_network_flag
    , ccn
    , data_source
    , file_name
    , file_date
    , ingest_datetime
    , file_cadence
    , file_priority
from add_data_types
