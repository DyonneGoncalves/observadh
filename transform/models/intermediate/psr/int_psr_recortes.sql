{{ config(materialized='table') }}

-- Intermediate: contagens do PSR nos três níveis geográficos, formato largo —
-- uma linha por (nivel, recorte). Estadual e nacional são SOMAS da base
-- municipal (int_psr_municipio_base): nenhum número vem de outra fonte.
--
--   nivel      recorte_codigo          recorte_nome           linhas
--   municipal  cód. IBGE 7 dígitos     nome do município      5.570
--   estadual   cód. IBGE da UF         nome da UF             27
--   nacional   NULL                    'Brasil'               1
--
-- Mesmo contrato de recorte dos int_lgbt_* (nivel / recorte_codigo /
-- recorte_nome). As denúncias ONDH sem município identificado (linha
-- Ignorado) entram só no total nacional.
--
-- Também conta municípios (com PSR, com eCR, com Centro Pop), usados nos
-- textos estadual e nacional, e guarda a população IBGE para o "% da
-- população" por UF.

{%- set chaves = ['municipio_codigo_ibge', 'is_ignorado'] %}
{%- set colunas = [] %}
{%- if execute %}
  {%- for c in adapter.get_columns_in_relation(ref('int_psr_municipio_base')) %}
    {%- if c.name not in chaves %}{% do colunas.append(c.name) %}{% endif %}
  {%- endfor %}
{%- endif %}

with base as (
    select b.*, m.codigo_uf, m.nome_municipio, u.nome_uf
    from {{ ref('int_psr_municipio_base') }} b
    left join {{ ref('dim_municipio') }} m on m.codigo_municipio::int = b.municipio_codigo_ibge
    left join {{ ref('dim_uf') }} u        on u.codigo_uf = m.codigo_uf
),

municipal as (
    select
        'municipal'::text          as nivel,
        municipio_codigo_ibge::int as recorte_codigo,
        nome_municipio::text       as recorte_nome,
        {%- for c in colunas %}
        {{ c }},
        {%- endfor %}
        (case when qtd_psr_ano > 0 then 1 else 0 end)::numeric     as qtd_municipios_com_psr_ano,
        (case when qtd_psr_inicio > 0 then 1 else 0 end)::numeric  as qtd_municipios_com_psr_inicio,
        (case when qtd_ecr > 0 then 1 else 0 end)::numeric         as qtd_municipios_com_ecr,
        (case when qtd_centros_pop > 0 then 1 else 0 end)::numeric as qtd_municipios_com_centros_pop
    from base
    where not is_ignorado
),

estadual as (
    select
        'estadual'::text  as nivel,
        codigo_uf::int    as recorte_codigo,
        nome_uf::text     as recorte_nome,
        {%- for c in colunas %}
        sum({{ c }}) as {{ c }},
        {%- endfor %}
        sum(case when qtd_psr_ano > 0 then 1 else 0 end)::numeric     as qtd_municipios_com_psr_ano,
        sum(case when qtd_psr_inicio > 0 then 1 else 0 end)::numeric  as qtd_municipios_com_psr_inicio,
        sum(case when qtd_ecr > 0 then 1 else 0 end)::numeric         as qtd_municipios_com_ecr,
        sum(case when qtd_centros_pop > 0 then 1 else 0 end)::numeric as qtd_municipios_com_centros_pop
    from base
    where not is_ignorado
    group by codigo_uf, nome_uf
),

nacional as (
    select
        'nacional'::text as nivel,
        null::int        as recorte_codigo,
        'Brasil'::text   as recorte_nome,
        {%- for c in colunas %}
        sum({{ c }}) as {{ c }},
        {%- endfor %}
        sum(case when qtd_psr_ano > 0 then 1 else 0 end)::numeric     as qtd_municipios_com_psr_ano,
        sum(case when qtd_psr_inicio > 0 then 1 else 0 end)::numeric  as qtd_municipios_com_psr_inicio,
        sum(case when qtd_ecr > 0 then 1 else 0 end)::numeric         as qtd_municipios_com_ecr,
        sum(case when qtd_centros_pop > 0 then 1 else 0 end)::numeric as qtd_municipios_com_centros_pop
    from base
)

select * from municipal
union all
select * from estadual
union all
select * from nacional
