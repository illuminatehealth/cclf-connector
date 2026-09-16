{%- set weekly_enabled = var('cclf_weekly_enabled', false) -%}

with source_data as (
{%- if weekly_enabled %}

    {{ dbt_utils.union_relations(
        relations=[
            source('lakehouse', 'cclf_9'),
            source('lakehouse_weekly', 'cclf_9_weekly')
        ],
        column_override=model_contract_column_types(),
        source_column_name=none
    ) }}

{%- else %}

    select *
    from {{ source('lakehouse', 'cclf_9') }}

{%- endif %}

)

select
      source_data.*
    , cast(manifest.file_cadence as {{ dbt.type_string() }}) as file_cadence
    , cast(manifest.file_priority as {{ dbt.type_int() }}) as file_priority
from source_data
inner join {{ ref('int_selected_cclf_file_manifest') }} as manifest
    on manifest.file_number = 9
   and manifest.file_name = source_data.filename
