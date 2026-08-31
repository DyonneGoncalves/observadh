{% macro ondh_breakdown_percentual(src, indicador, pairs, ano=2024) %}
-- Gera, no formato longo, um indicador "% de denúncias por <categoria>" a
-- partir de uma tabela ONDH em formato largo (1 linha por município, uma
-- coluna por categoria). `pairs` é uma lista [rótulo, expressão SQL] — a
-- expressão usa o alias `s`. O denominador do % é a SOMA de todos os pares
-- (por isso categorias tipo "Não informado" ficam de fora quando o relatório
-- não as considera: basta não incluí-las em `pairs`).
    select
        agg.nivel,
        agg.recorte_codigo,
        '{{ indicador }}'::text as indicador,
        agg.categoria,
        {{ calcula_percentual('agg.q', 'agg.q_total') }} as valor,
        'percentual'::text     as valor_tipo,
        {{ ano }}              as ano_referencia
    from (
        select
            nivel,
            recorte_codigo,
            categoria,
            sum(quantidade)                                                        as q,
            sum(sum(quantidade)) over (partition by nivel, recorte_codigo)         as q_total
        from (
            {% for escopo in [
                ("'nacional'::text",  "null::int"),
                ("'estadual'::text",  codigo_num('s.cod_uf')),
                ("'municipal'::text", codigo_num('s.cod_ibge7'))
            ] %}
            select
                {{ escopo[0] }}                          as nivel,
                {{ escopo[1] }}                          as recorte_codigo,
                v.categoria,
                coalesce(v.quantidade, 0)::numeric       as quantidade
            from {{ src }} s
            cross join lateral (values
                {%- for p in pairs %}
                ('{{ p[0] }}', {{ p[1] }}){{ "," if not loop.last }}
                {%- endfor %}
            ) as v(categoria, quantidade)
            {{ "union all" if not loop.last }}
            {% endfor %}
        ) unpiv
        group by nivel, recorte_codigo, categoria
    ) agg
{% endmacro %}
