-- Intermediate: seção 6.1 — Proteção Social Especial. Formato LONGO. N/E/M.
--
-- Reagrupa os 5 intermediates por município (que continuam sendo o ponto de
-- cálculo) para os 3 níveis e devolve no contrato de indicadores. Substitui
-- os marts largos lgbt_relatorio_{nacional,estadual,municipal}.
--
-- Percentuais são recalculados a partir dos totais agregados por nível (nunca
-- como média dos percentuais municipais). PAEFI usa o ano mais recente por
-- município (o relatório mostra o valor "atual" — TODO da equipe: série?).

with paefi_recente as (
    select municipio_codigo_ibge, uf_codigo, qtd_vitimas_paefi
    from (
        select *, row_number() over (partition by municipio_codigo_ibge order by ano_referencia desc) as rn
        from {{ ref('int_lgbt_paefi_por_municipio') }}
    ) t
    where rn = 1
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
           sum(qtd_pessoas_acolhidas_total) as pessoas, sum(qtd_pessoas_trans_acolhidas_total) as pessoas_trans
    from acolh
    union all select 'estadual', uf_codigo, sum(qtd_unidades_acolhimento), sum(qtd_unidades_com_pessoas_trans),
                     sum(qtd_pessoas_acolhidas_total), sum(qtd_pessoas_trans_acolhidas_total) from acolh group by uf_codigo
    union all select 'municipal', municipio_codigo_ibge, sum(qtd_unidades_acolhimento), sum(qtd_unidades_com_pessoas_trans),
                     sum(qtd_pessoas_acolhidas_total), sum(qtd_pessoas_trans_acolhidas_total) from acolh group by municipio_codigo_ibge
),

dim_uf  as ( select codigo_uf, nome_uf from {{ ref('dim_uf') }} ),
dim_mun as ( select codigo_municipio, nome_municipio from {{ ref('dim_municipio') }} ),

linhas as (
    select nivel, recorte_codigo, 'vitimas_paefi'::text as indicador, null::text as categoria,
           vitimas::numeric as valor, 'numero_absoluto'::text as valor_tipo from paefi_agg

    union all select nivel, recorte_codigo, 'creas_total', null, total_creas::numeric, 'numero_absoluto' from creas_o_agg
    union all select nivel, recorte_codigo, 'creas_nao_atende_orientacao', null, nao_atende::numeric, 'numero_absoluto' from creas_o_agg
    union all select nivel, recorte_codigo, 'pct_creas_nao_atende_orientacao', null,
                     {{ calcula_percentual('nao_atende', 'total_creas') }}, 'percentual' from creas_o_agg

    union all select nivel, recorte_codigo, 'creas_nao_atende_identidade', null, nao_atende::numeric, 'numero_absoluto' from creas_i_agg
    union all select nivel, recorte_codigo, 'pct_creas_nao_atende_identidade', null,
                     {{ calcula_percentual('nao_atende', 'total_creas') }}, 'percentual' from creas_i_agg

    union all select nivel, recorte_codigo, 'centros_pop_total', null, total_cpop::numeric, 'numero_absoluto' from cpop_agg
    union all select nivel, recorte_codigo, 'pct_centros_pop_atenderam_lgbt', null,
                     {{ calcula_percentual('atenderam', 'total_cpop') }}, 'percentual' from cpop_agg

    union all select nivel, recorte_codigo, 'unidades_acolhimento_total', null, unidades::numeric, 'numero_absoluto' from acolh_agg
    union all select nivel, recorte_codigo, 'pct_unidades_acolhimento_com_pessoas_trans', null,
                     {{ calcula_percentual('unidades_trans', 'unidades') }}, 'percentual' from acolh_agg
    union all select nivel, recorte_codigo, 'pessoas_acolhidas_total', null, pessoas::numeric, 'numero_absoluto' from acolh_agg
    union all select nivel, recorte_codigo, 'pessoas_trans_acolhidas_total', null, pessoas_trans::numeric, 'numero_absoluto' from acolh_agg
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
    2024 as ano_referencia
from linhas l
left join dim_uf  u on l.nivel = 'estadual'  and u.codigo_uf = l.recorte_codigo
left join dim_mun m on l.nivel = 'municipal' and m.codigo_municipio = l.recorte_codigo
where l.nivel = 'nacional'
   or (l.nivel = 'estadual'  and u.codigo_uf is not null)
   or (l.nivel = 'municipal' and m.codigo_municipio is not null)
