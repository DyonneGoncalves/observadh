{#- Macros do tema PSR. Percentuais usam calcula_percentual() (macro comum). -#}

{% macro psr_num(col) -%}
{#- Valor numérico vindo do Excel que pode ser texto ('-' = supressão/sem dado,
    '' ou espaço). Retorna numeric ou NULL — quem chama decide se NULL vira 0. #}
(case
    when trim(coalesce(({{ col }})::text, '')) ~ '^-?[0-9]+(\.[0-9]+)?$'
    then trim(({{ col }})::text)::numeric
end)
{%- endmacro %}


{% macro psr_secao(nomes) -%}
{#- Fecha um intermediate de seção no MESMO contrato de colunas dos int_lgbt_*:
    nivel, recorte_codigo, recorte_nome, secao, secao_nome, indicador,
    categoria, valor, valor_tipo, ano_referencia.
    Espera um CTE `linhas` (nivel, recorte_codigo, secao, indicador,
    categoria, valor, valor_tipo, ano_referencia); `nomes` = {secao: nome}. #}
select
    l.nivel::text            as nivel,
    l.recorte_codigo::int    as recorte_codigo,
    r.recorte_nome::text     as recorte_nome,
    l.secao::text            as secao,
    (case l.secao
        {%- for s, n in nomes.items() %}
        when '{{ s }}' then '{{ n }}'
        {%- endfor %}
    end)::text               as secao_nome,
    l.indicador::text        as indicador,
    l.categoria::text        as categoria,
    l.valor::numeric         as valor,
    l.valor_tipo::text       as valor_tipo,
    l.ano_referencia::int    as ano_referencia
from linhas l
join {{ ref('int_psr_recortes') }} r
  on r.nivel = l.nivel and coalesce(r.recorte_codigo, -1) = coalesce(l.recorte_codigo, -1)
{%- endmacro %}


{% macro psr_pct(numerador, denominador) -%}
{#- Percentual do PSR: calcula_percentual() com 4 casas e NULL quando o
    denominador é 0 ("sem dado": ex. município sem PSR não tem % de homens).
    Mesma convenção dos percentuais do SINAN no LGBTQIA+. Numerador e
    denominador vão entre parênteses (aceitam somas: 'a + b'). #}
{{ calcula_percentual('(' ~ numerador ~ ')', '(' ~ denominador ~ ')', 4, 'null') }}
{%- endmacro %}
