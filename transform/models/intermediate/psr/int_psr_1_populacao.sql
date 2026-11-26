-- Intermediate: seção 1 — População em situação de rua. Formato LONGO.
--
-- Indicadores (Cálculo Indicadores PSR_v2, seção 1):
--   1    qtd_psr                          PSR no CadÚnico em dez/<ano>                         N E M
--   1.1  qtd_psr_por_ano                  série dez/2015 a dez/<ano>; categoria = ano          N E M
--   1.2  pct_psr_sobre_total_nacional     PSR do recorte / PSR do Brasil × 100                 E M
--        pct_psr_sobre_populacao          PSR / população total IBGE × 100                     N E M
--        qtd_municipios_com_psr           nº de municípios com 1+ PSR; categoria = ano         N E
--                                         (início da série e ano de referência)
--        uf_maior_concentracao_psr_{1,2,3} 1ª/2ª/3ª UF com mais PSR — categoria = nome da UF,  N
--                                         valor = % do total nacional
--        uf_maior_proporcao_psr           UF com maior PSR / população — categoria = UF,       N
--                                         valor = % da população da UF

{% set ano = var('psr_ano_referencia') %}
{% set ano_ini = var('psr_ano_inicio_serie') %}

with r as (
    select * from {{ ref('int_psr_recortes') }}
),

brasil as (
    select qtd_psr_ano as qtd_psr_brasil from r where nivel = 'nacional'
),

-- série histórica por recorte (todos os anos)
serie_mun as (
    select s.municipio_codigo_ibge, m.codigo_uf, s.ano_referencia as ano, sum(s.qtd_psr) as qtd
    from {{ ref('stg_psr_serie_historica') }} s
    join {{ ref('dim_municipio') }} m on m.codigo_municipio::int = s.municipio_codigo_ibge
    group by 1, 2, 3
),
serie as (
    select 'municipal'::text as nivel, municipio_codigo_ibge::int as recorte_codigo, ano, qtd from serie_mun
    union all
    select 'estadual', codigo_uf::int, ano, sum(qtd) from serie_mun group by codigo_uf, ano
    union all
    select 'nacional', null::int, ano, sum(qtd) from serie_mun group by ano
),

ufs as (
    select recorte_nome, qtd_psr_ano,
           {{ psr_pct('qtd_psr_ano', '(select qtd_psr_brasil from brasil)') }} as pct_nacional,
           {{ psr_pct('qtd_psr_distrib', 'qtd_pop_total_ibge') }}             as pct_populacao,
           row_number() over (order by qtd_psr_ano desc, recorte_nome) as pos_qtd,
           row_number() over (order by qtd_psr_distrib / nullif(qtd_pop_total_ibge, 0) desc nulls last, recorte_nome) as pos_proporcao
    from r where nivel = 'estadual'
),

linhas as (
    -- 1 — total de PSR no ano de referência
    select nivel, recorte_codigo, '1' as secao, 'qtd_psr' as indicador, null as categoria,
           qtd_psr_ano as valor, 'numero_absoluto' as valor_tipo, {{ ano }} as ano_referencia
    from r

    union all
    -- 1.1 — evolução anual
    select nivel, recorte_codigo, '1.1', 'qtd_psr_por_ano', ano::text, qtd, 'numero_absoluto', ano
    from serie

    union all
    -- 1.2 — participação no total nacional (estadual e municipal)
    select nivel, recorte_codigo, '1.2', 'pct_psr_sobre_total_nacional', null,
           {{ psr_pct('qtd_psr_ano', '(select qtd_psr_brasil from brasil)') }}, 'percentual', {{ ano }}
    from r where nivel <> 'nacional'

    union all
    -- 1.2 — PSR como % da população total (IBGE)
    select nivel, recorte_codigo, '1.2', 'pct_psr_sobre_populacao', null,
           {{ psr_pct('qtd_psr_distrib', 'qtd_pop_total_ibge') }}, 'percentual', {{ ano }}
    from r

    union all
    -- 1.2 — nº de municípios com PSR (início da série e ano de referência)
    select nivel, recorte_codigo, '1.2', 'qtd_municipios_com_psr', '{{ ano_ini }}',
           qtd_municipios_com_psr_inicio, 'numero_absoluto', {{ ano_ini }}
    from r where nivel <> 'municipal'
    union all
    select nivel, recorte_codigo, '1.2', 'qtd_municipios_com_psr', '{{ ano }}',
           qtd_municipios_com_psr_ano, 'numero_absoluto', {{ ano }}
    from r where nivel <> 'municipal'

    union all
    -- 1.2 — UFs com maior concentração (nacional)
    select 'nacional', null, '1.2', 'uf_maior_concentracao_psr_' || pos_qtd, recorte_nome,
           pct_nacional, 'categoria_predominante', {{ ano }}
    from ufs where pos_qtd <= 3

    union all
    -- 1.2 — UF com maior proporção de PSR na população (nacional)
    select 'nacional', null, '1.2', 'uf_maior_proporcao_psr', recorte_nome,
           pct_populacao, 'categoria_predominante', {{ ano }}
    from ufs where pos_proporcao = 1
)

{{ psr_secao({
    '1': 'População em situação de rua',
    '1.1': 'Evolução anual da população em situação de rua',
    '1.2': 'Distribuição da população em situação de rua'
}) }}
