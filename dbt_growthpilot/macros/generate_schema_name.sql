{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none -%}

        {{ target.schema }}

    {%- elif custom_schema_name == 'staging' -%}

        growthpilot_staging

    {%- elif custom_schema_name == 'marts' -%}

        growthpilot_marts

    {%- elif custom_schema_name == 'analytics' -%}

        growthpilot_analytics

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}