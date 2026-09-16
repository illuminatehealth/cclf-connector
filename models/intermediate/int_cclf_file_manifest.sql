{#
    One row per CCLF file delivered, across monthly and (optionally) weekly releases.
    A release is the set of CCLF 1, 2, 3, 4, 5, 6, 8 and 9 files sharing a cadence and
    release date. Monthly files are dated the month after the claims they cover, so the
    selection month for a monthly file is the prior month; a weekly file keeps its own.
#}

{%- set file_numbers = [1, 2, 3, 4, 5, 6, 8, 9] -%}
{%- set weekly_enabled = var('cclf_weekly_enabled', false) -%}

with source_files as (
{% for n in file_numbers %}
    select distinct
          {{ n }} as file_number
        , cast('CCLF{{ n }}' as {{ dbt.type_string() }}) as file_group
        , cast('monthly' as {{ dbt.type_string() }}) as file_cadence
        , 1 as file_priority
        , cast(filename as {{ dbt.type_string() }}) as file_name
        , {{ cclf_performance_year('filename') }} as performance_year
        , {{ cclf_file_date('filename') }} as file_date
        , ingest_datetime
    from {{ source('lakehouse', 'cclf_' ~ n) }}
    where {{ dbt.position("'.D'", 'filename') }} > 0
{%- if weekly_enabled %}

    union all

    select distinct
          {{ n }} as file_number
        , cast('CCLF{{ n }}' as {{ dbt.type_string() }}) as file_group
        , cast('weekly' as {{ dbt.type_string() }}) as file_cadence
        , 2 as file_priority
        , cast(filename as {{ dbt.type_string() }}) as file_name
        , {{ cclf_performance_year('filename') }} as performance_year
        , {{ cclf_file_date('filename') }} as file_date
        , ingest_datetime
    from {{ source('lakehouse_weekly', 'cclf_' ~ n ~ '_weekly') }}
    where {{ dbt.position("'.D'", 'filename') }} > 0
{%- endif %}
{%- if not loop.last %}

    union all
{% endif %}
{%- endfor %}

)

, release_periods as (

    select
          source_files.*
        , case
            when file_cadence = 'monthly' then {{ dbt.dateadd('month', -1, 'file_date') }}
            else file_date
          end as selection_month_date
    from source_files

)

select
      file_number
    , file_group
    , file_cadence
    , file_priority
    , file_name
    , performance_year
    , year(selection_month_date) as file_year
    , month(selection_month_date) as file_month
    , file_date
    , max(ingest_datetime) as ingest_datetime
from release_periods
where file_date is not null
  and performance_year is not null
group by
      file_number
    , file_group
    , file_cadence
    , file_priority
    , file_name
    , performance_year
    , year(selection_month_date)
    , month(selection_month_date)
    , file_date
