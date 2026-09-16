{% macro model_contract_column_types() %}
    {# Use the model contract as the single source of truth for union casts. #}
    {% if not execute %}
        {{ return({}) }}
    {% endif %}

    {% set column_types = {} %}

    {% for column_name, column_config in model.get('columns', {}).items() %}
        {% set data_type = column_config.get('data_type') %}
        {% if data_type %}
            {% do column_types.update({column_name: data_type}) %}
        {% endif %}
    {% endfor %}

    {% if column_types | length == 0 %}
        {{ exceptions.raise_compiler_error(
            'No contracted column types are defined for model ' ~ model.name
        ) }}
    {% endif %}

    {{ return(column_types) }}
{% endmacro %}
