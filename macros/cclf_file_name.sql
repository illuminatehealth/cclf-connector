{#
    CCLF file names follow P.A****.ACO.ZC*Y**.Dyymmdd.Thhmmsst. These macros read the
    performance year and the release date out of the name without relying on fixed
    character positions, so a path prefix on the file name does not break them.
#}

{% macro cclf_file_date(column_name) -%}
    {{ dbt.safe_cast(
        dbt.concat([
            "'20'",
            "substring(" ~ column_name ~ ", " ~ dbt.position("'.D'", column_name) ~ " + 2, 2)",
            "'-'",
            "substring(" ~ column_name ~ ", " ~ dbt.position("'.D'", column_name) ~ " + 4, 2)",
            "'-'",
            "substring(" ~ column_name ~ ", " ~ dbt.position("'.D'", column_name) ~ " + 6, 2)"
        ]),
        "date"
    ) }}
{%- endmacro %}

{% macro cclf_performance_year(column_name) -%}
    {{ dbt.safe_cast(
        "substring(" ~ column_name ~ ", " ~ dbt.position("'Y'", column_name) ~ " + 1, 2)",
        dbt.type_int()
    ) }} + 2000
{%- endmacro %}
