{% macro codigo_num(col) -%}
-- Coerção segura de código numérico (UF/IBGE) que pode ter vindo do Excel como
-- texto, double ("33.0") ou com valores não-numéricos (ex.: hash de
-- anonimização em denúncias sobre outros países). Retorna int ou NULL.
(case
    when regexp_replace(coalesce(({{ col }})::text, ''), '\.0+$', '') ~ '^[0-9]+$'
    then regexp_replace(({{ col }})::text, '\.0+$', '')::int
end)
{%- endmacro %}
