{% macro sinan_breakdown_percentual(src, indicador, total_col, pairs, ano=2024) %}
-- Igual ao ondh_breakdown_percentual, mas o DENOMINADOR do % é uma coluna de
-- total explícita (`total_col`), não a soma dos pares. Necessário nas tabelas
-- SINAN porque algumas categorias do relatório se sobrepõem (ex.: "até 29
-- anos" e "crianças e adolescentes") e o total tem sua própria coluna.
-- `pairs` = lista [rótulo, expressão SQL] usando o alias `s`.
    select
        cat.nivel,
        cat.recorte_codigo,
        '{{ indicador }}'::text as indicador,
        cat.categoria,
        {{ calcula_percentual('cat.q', 'den.q_total') }} as valor,
        'percentual'::text     as valor_tipo,
        {{ ano }}             as ano_referencia
    from (
        {% for e in [
            ("'nacional'::text",  "null::int"),
            ("'estadual'::text",  codigo_num('s.cod_uf')),
            ("'municipal'::text", codigo_num('s.cod_ibge7'))
        ] %}
        select
            {{ e[0] }} as nivel,
            {{ e[1] }} as recorte_codigo,
            v.categoria,
            sum(coalesce(v.q, 0))::numeric as q
        from {{ src }} s
        cross join lateral (values
            {%- for p in pairs %}
            ('{{ p[0] }}', {{ p[1] }}){{ "," if not loop.last }}
            {%- endfor %}
        ) as v(categoria, q)
        group by 1, 2, 3
        {{ "union all" if not loop.last }}
        {% endfor %}
    ) cat
    join (
        {% for e in [
            ("'nacional'::text",  "null::int"),
            ("'estadual'::text",  codigo_num('s.cod_uf')),
            ("'municipal'::text", codigo_num('s.cod_ibge7'))
        ] %}
        select
            {{ e[0] }} as nivel,
            {{ e[1] }} as recorte_codigo,
            sum(coalesce(s.{{ total_col }}, 0))::numeric as q_total
        from {{ src }} s
        group by 1, 2
        {{ "union all" if not loop.last }}
        {% endfor %}
    ) den
      on den.nivel = cat.nivel
     and den.recorte_codigo is not distinct from cat.recorte_codigo
{% endmacro %}
