-- Intermediate: seção 6.1 — Proteção Social Especial. Formato LONGO. N/E/M.
--
-- Reagrupa os 5 intermediates por município (que continuam sendo o ponto de
-- cálculo) para os 3 níveis e devolve no contrato de indicadores. Substitui
-- os marts largos lgbt_relatorio_{nacional,estadual,municipal}.
--
-- Percentuais são recalculados a partir dos totais agregados por nível (nunca
-- como média dos percentuais municipais). PAEFI = somente o ano mais recente
-- disponível (2024) — bate com o relatório publicado (1.517). Não é "o último
-- ano de cada município": municípios sem registro em 2024 ficam de fora.
--
-- SÉRIE HISTÓRICA DO PAEFI (indicador vitimas_paefi_serie_historica): a
-- especificação de cálculo pede, além do valor de 2024 acima, a série
-- 2017-2024 completa — é o dado que alimenta o gráfico da seção 6.1 nos
-- relatórios estadual e municipal ("Série histórica dos anos de 2017 a
-- 2024", calculo_estadual.md/calculo_municipal.md). Essa linha NÃO existe
-- no documento nacional (só estadual/municipal) — por isso só é gerada
-- para esses dois níveis. Uma linha por ano, com o ano em `categoria`
-- (seguindo o mesmo padrão de quebra usado nas demais seções) e também em
-- `ano_referencia`, diferente do restante da seção 6.1 (que é sempre 2024).
--
-- CHAMADO 27607:
--   vitimas_paefi_2017_2024 (E/M): o texto estadual/municipal diz "entre 2017
--     e 2024, XXXX pessoas..." — é a SOMA da série (Alagoas = 141). Antes o
--     template usava vitimas_paefi (só 2024 = 9). vitimas_paefi segue igual
--     (nacional usa o valor de 2024, que bate com o relatório publicado).
--   pct_unidades_acolhimento_com_pessoas_trans: denominador passa a ser as
--     unidades que responderam Sim ou Não (fórmula da especificação), não o
--     total de unidades. Alagoas: 7,1% -> 7,55%.

with paefi_recente as (
    select municipio_codigo_ibge, uf_codigo, qtd_vitimas_paefi
    from {{ ref('int_lgbt_paefi_por_municipio') }}
    where ano_referencia = (select max(ano_referencia) from {{ ref('int_lgbt_paefi_por_municipio') }})
),
paefi_serie as (
    -- série completa (todos os anos disponíveis), sem o filtro de "ano mais
    -- recente" acima — fonte do gráfico de 6.1 em estadual/municipal.
    select municipio_codigo_ibge, uf_codigo, ano_referencia, qtd_vitimas_paefi
    from {{ ref('int_lgbt_paefi_por_municipio') }}
),
creas_o as ( select * from {{ ref('int_lgbt_creas_orientacao_por_municipio') }} ),
creas_i as ( select * from {{ ref('int_lgbt_creas_identidade_por_municipio') }} ),
cpop    as ( select * from {{ ref('int_lgbt_centros_pop_por_municipio') }} ),
acolh   as ( select * from {{ ref('int_lgbt_acolhimento_por_municipio') }} ),

-- agregações por nível (nacional / estadual / municipal)
paefi_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, sum(qtd_vitimas_paefi) as vitimas from paefi_recente
    union all select 'estadual', uf_codigo, sum(qtd_vitimas_paefi) from paefi_recente group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(qtd_vitimas_paefi) from paefi_recente group by municipio_codigo_ibge
),
-- só estadual/municipal — a série histórica não é pedida no relatório nacional.
-- soma 2017-2024 (o número do texto estadual/municipal)
paefi_periodo_agg as (
    select 'estadual'::text as nivel, uf_codigo as recorte_codigo,
           sum(qtd_vitimas_paefi) as vitimas, min(ano_referencia) as ano_ini, max(ano_referencia) as ano_fim
    from paefi_serie group by uf_codigo
    union all
    select 'municipal', municipio_codigo_ibge,
           sum(qtd_vitimas_paefi), min(ano_referencia), max(ano_referencia)
    from paefi_serie group by municipio_codigo_ibge
),
paefi_serie_agg as (
    select 'estadual'::text as nivel, uf_codigo as recorte_codigo, ano_referencia, sum(qtd_vitimas_paefi) as vitimas
    from paefi_serie
    group by uf_codigo, ano_referencia
    union all
    select 'municipal', municipio_codigo_ibge, ano_referencia, sum(qtd_vitimas_paefi)
    from paefi_serie
    group by municipio_codigo_ibge, ano_referencia
),
creas_o_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           sum(qtd_total_creas) as total_creas, sum(qtd_creas_nao_atende_orientacao) as nao_atende from creas_o
    union all select 'estadual', uf_codigo, sum(qtd_total_creas), sum(qtd_creas_nao_atende_orientacao) from creas_o group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(qtd_total_creas), sum(qtd_creas_nao_atende_orientacao) from creas_o group by municipio_codigo_ibge
),
creas_i_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           sum(qtd_total_creas) as total_creas, sum(qtd_creas_nao_atende_identidade) as nao_atende from creas_i
    union all select 'estadual', uf_codigo, sum(qtd_total_creas), sum(qtd_creas_nao_atende_identidade) from creas_i group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(qtd_total_creas), sum(qtd_creas_nao_atende_identidade) from creas_i group by municipio_codigo_ibge
),
cpop_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           sum(qtd_total_centros_pop) as total_cpop, sum(qtd_atenderam_lgbt) as atenderam from cpop
    union all select 'estadual', uf_codigo, sum(qtd_total_centros_pop), sum(qtd_atenderam_lgbt) from cpop group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(qtd_total_centros_pop), sum(qtd_atenderam_lgbt) from cpop group by municipio_codigo_ibge
),
acolh_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo,
           sum(qtd_unidades_acolhimento) as unidades, sum(qtd_unidades_com_pessoas_trans) as unidades_trans,
           sum(qtd_unidades_responderam_trans) as unidades_responderam,
           sum(qtd_pessoas_acolhidas_total) as pessoas, sum(qtd_pessoas_trans_acolhidas_total) as pessoas_trans
    from acolh
    union all select 'estadual', uf_codigo, sum(qtd_unidades_acolhimento), sum(qtd_unidades_com_pessoas_trans),
                     sum(qtd_unidades_responderam_trans),
                     sum(qtd_pessoas_acolhidas_total), sum(qtd_pessoas_trans_acolhidas_total) from acolh group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(qtd_unidades_acolhimento), sum(qtd_unidades_com_pessoas_trans),
                     sum(qtd_unidades_responderam_trans),
                     sum(qtd_pessoas_acolhidas_total), sum(qtd_pessoas_trans_acolhidas_total) from acolh group by municipio_codigo_ibge
),

dim_uf  as ( select codigo_uf, nome_uf from {{ ref('dim_uf') }} ),
dim_mun as ( select codigo_municipio, nome_municipio from {{ ref('dim_municipio') }} ),

linhas as (
    select nivel, recorte_codigo, 'vitimas_paefi'::text as indicador, null::text as categoria,
           vitimas::numeric as valor, 'numero_absoluto'::text as valor_tipo, 2024 as ano_referencia from paefi_agg

    -- soma 2017-2024, o "XXXX pessoas" do texto estadual/municipal.
    union all select nivel, recorte_codigo, 'vitimas_paefi_2017_2024', null,
                     vitimas::numeric, 'numero_absoluto', ano_fim from paefi_periodo_agg

    -- série histórica 2017-2024, só para o gráfico de 6.1 em estadual/municipal.
    union all select nivel, recorte_codigo, 'vitimas_paefi_serie_historica', ano_referencia::text,
                     vitimas::numeric, 'numero_absoluto', ano_referencia from paefi_serie_agg

    union all select nivel, recorte_codigo, 'creas_total', null, total_creas::numeric, 'numero_absoluto', 2024 from creas_o_agg
    union all select nivel, recorte_codigo, 'creas_nao_atende_orientacao', null, nao_atende::numeric, 'numero_absoluto', 2024 from creas_o_agg
    union all select nivel, recorte_codigo, 'pct_creas_nao_atende_orientacao', null,
                     {{ calcula_percentual('nao_atende', 'total_creas') }}, 'percentual', 2024 from creas_o_agg

    union all select nivel, recorte_codigo, 'creas_nao_atende_identidade', null, nao_atende::numeric, 'numero_absoluto', 2024 from creas_i_agg
    union all select nivel, recorte_codigo, 'pct_creas_nao_atende_identidade', null,
                     {{ calcula_percentual('nao_atende', 'total_creas') }}, 'percentual', 2024 from creas_i_agg

    union all select nivel, recorte_codigo, 'centros_pop_total', null, total_cpop::numeric, 'numero_absoluto', 2024 from cpop_agg
    union all select nivel, recorte_codigo, 'pct_centros_pop_atenderam_lgbt', null,
                     {{ calcula_percentual('atenderam', 'total_cpop') }}, 'percentual', 2024 from cpop_agg

    union all select nivel, recorte_codigo, 'unidades_acolhimento_total', null, unidades::numeric, 'numero_absoluto', 2024 from acolh_agg
    union all select nivel, recorte_codigo, 'pct_unidades_acolhimento_com_pessoas_trans', null,
                     {{ calcula_percentual('unidades_trans', 'unidades_responderam') }}, 'percentual', 2024 from acolh_agg
    union all select nivel, recorte_codigo, 'pessoas_acolhidas_total', null, pessoas::numeric, 'numero_absoluto', 2024 from acolh_agg
    union all select nivel, recorte_codigo, 'pessoas_trans_acolhidas_total', null, pessoas_trans::numeric, 'numero_absoluto', 2024 from acolh_agg
)

select
    l.nivel,
    l.recorte_codigo,
    case l.nivel
        when 'nacional'  then 'Brasil'
        when 'estadual'  then u.nome_uf
        when 'municipal' then m.nome_municipio
    end                                                       as recorte_nome,
    '6.1'::text                                               as secao,
    'Assistência social — Proteção social especial'::text      as secao_nome,
    l.indicador, l.categoria, l.valor, l.valor_tipo,
    l.ano_referencia
from linhas l
left join dim_uf  u on l.nivel = 'estadual'  and u.codigo_uf = l.recorte_codigo
left join dim_mun m on l.nivel = 'municipal' and m.codigo_municipio = l.recorte_codigo
where l.nivel = 'nacional'
   or (l.nivel = 'estadual'  and u.codigo_uf is not null)
   or (l.nivel = 'municipal' and m.codigo_municipio is not null)
