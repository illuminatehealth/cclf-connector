with year_grain as (
  select 
      member_id 
    , custom_attributed_provider
    , custom_attributed_provider_practice
    , file_name
    , year_nbr
  from {{ ref('stg_attribution') }} 
)

, cal as 
(
    select distinct year_month_int as year_month
          ,year as year_nbr
  from {{ ref('reference_data__calendar')}}
)

select
      coalesce(xref.crnt_num,e.member_id) as person_id
      ,coalesce(xref.crnt_num,e.member_id) as member_id
      ,e.member_id as original_member_id
    , m.year_month

    , met.payer
    , met.{{ quote_column('plan') }}
    , met.data_source

    , cast(null as varchar(10)) as payer_attributed_provider
    , cast(null as varchar(10)) as payer_attributed_provider_practice
    , cast(null as varchar(50)) as payer_attributed_provider_organization
    , cast(null as varchar(10)) as payer_attributed_provider_lob

    , UPPER(cast(e.custom_attributed_provider           as varchar(10))) as custom_attributed_provider
    , UPPER(cast(e.custom_attributed_provider_practice  as varchar(10))) as custom_attributed_provider_practice
    , cast(null as varchar(10))                   as custom_attributed_provider_organization
    , cast(null as varchar(10))                   as custom_attributed_provider_lob

from year_grain e
inner join cal m on e.year_nbr = m.year_nbr
cross join {{ ref('metadata_fields') }} met
left join {{ ref('int_beneficiary_xref_deduped') }} xref on e.member_id = xref.prvs_num
where e.year_nbr <2025

