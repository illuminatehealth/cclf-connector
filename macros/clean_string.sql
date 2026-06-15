{% macro clean_string(value) %}
    nullif(ltrim(rtrim(replace({{ value }}, '~', ''))), '')
{% endmacro %}
