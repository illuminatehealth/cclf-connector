{#
    Keep only complete releases (all eight file types present). For each performance
    year and selection month, a complete monthly release wins; complete weekly releases
    are used only for months with no complete monthly release.
#}

with releases as (

    select
          file_cadence
        , file_priority
        , performance_year
        , file_year
        , file_month
        , file_date
        , count(distinct file_number) as file_count
        , max(ingest_datetime) as ingest_datetime
    from {{ ref('int_cclf_file_manifest') }}
    group by
          file_cadence
        , file_priority
        , performance_year
        , file_year
        , file_month
        , file_date

)

, complete_releases as (

    select *
    from releases
    where file_count = 8

)

, complete_monthly_months as (

    select distinct
          performance_year
        , file_year
        , file_month
    from complete_releases
    where file_cadence = 'monthly'

)

, selected_releases as (

    select
          file_cadence
        , file_priority
        , performance_year
        , file_year
        , file_month
        , file_date
    from complete_releases
    where file_cadence = 'monthly'

    union all

    select
          file_cadence
        , file_priority
        , performance_year
        , file_year
        , file_month
        , file_date
    from complete_releases
    where file_cadence = 'weekly'
      and not exists (
          select 1
          from complete_monthly_months
          where complete_monthly_months.performance_year = complete_releases.performance_year
            and complete_monthly_months.file_year = complete_releases.file_year
            and complete_monthly_months.file_month = complete_releases.file_month
      )

)

select
      manifest.file_number
    , manifest.file_group
    , manifest.file_cadence
    , manifest.file_priority
    , manifest.file_name
    , manifest.performance_year
    , manifest.file_year
    , manifest.file_month
    , manifest.file_date
    , manifest.ingest_datetime
from {{ ref('int_cclf_file_manifest') }} as manifest
inner join selected_releases
    on selected_releases.file_cadence = manifest.file_cadence
   and selected_releases.performance_year = manifest.performance_year
   and selected_releases.file_date = manifest.file_date
