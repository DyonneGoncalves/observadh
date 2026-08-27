-- Mart: indicadores de Proteção Social Especial (categoria 6.1) por
-- município — piloto da nova arquitetura.
--
-- Grão: 1 linha por município. Full outer join entre as 5 fontes porque a
-- cobertura de município varia por fonte (nem todo município tem CREAS,
-- Centro POP ou unidade de acolhimento).
--
-- PAEFI tem série 2017-2024; pegamos o ano mais recente por município para
-- representar o "valor atual" do relatório (TODO: confirmar com a equipe se
-- essa é a leitura certa, ou se o relatório deveria mostrar a série completa).

with paefi_mais_recente as (

    select *
    from (
        select
            *,
            row_number() over (partition by municipio_codigo_ibge order by ano_referencia desc) as rn
        from {{ ref('int_lgbtqia_plus_paefi_por_municipio') }}
    ) t
    where rn = 1

),

base_municipios as (

    select codigo_municipio as municipio_codigo_ibge, nome_municipio as municipio_nome, sigla_uf as uf_sigla, codigo_uf as uf_codigo
    from {{ ref('dim_municipio') }}
    where codigo_uf != 99   -- exclui a linha "outros / não informado" (codigo_uf=99, ver catálogo)

)

select
    m.municipio_codigo_ibge,
    m.municipio_nome,
    m.uf_sigla,
    m.uf_codigo,

    p.ano_referencia                          as ano_referencia_paefi,
    p.qtd_vitimas_paefi,

    co.ano_referencia                         as ano_referencia_creas_orientacao,
    co.qtd_total_creas                        as qtd_total_creas_orientacao,
    co.qtd_creas_nao_atende_orientacao,
    co.pct_creas_nao_atende_orientacao,

    ci.ano_referencia                         as ano_referencia_creas_identidade,
    ci.qtd_total_creas                        as qtd_total_creas_identidade,
    ci.qtd_creas_nao_atende_identidade,
    ci.pct_creas_nao_atende_identidade,

    cp.ano_referencia                         as ano_referencia_centros_pop,
    cp.qtd_total_centros_pop,
    cp.qtd_atenderam_lgbtqia,
    cp.pct_centros_pop_atenderam_lgbtqia,

    ac.ano_referencia                         as ano_referencia_acolhimento,
    ac.qtd_unidades_acolhimento,
    ac.qtd_unidades_com_pessoas_trans,
    ac.pct_unidades_com_pessoas_trans,
    ac.qtd_pessoas_acolhidas_total,
    ac.qtd_pessoas_trans_acolhidas_total

from base_municipios m
left join paefi_mais_recente                                             p  on p.municipio_codigo_ibge = m.municipio_codigo_ibge
left join {{ ref('int_lgbtqia_plus_creas_orientacao_por_municipio') }}   co on co.municipio_codigo_ibge = m.municipio_codigo_ibge
left join {{ ref('int_lgbtqia_plus_creas_identidade_por_municipio') }}   ci on ci.municipio_codigo_ibge = m.municipio_codigo_ibge
left join {{ ref('int_lgbtqia_plus_centros_pop_por_municipio') }}        cp on cp.municipio_codigo_ibge = m.municipio_codigo_ibge
left join {{ ref('int_lgbtqia_plus_acolhimento_por_municipio') }}        ac on ac.municipio_codigo_ibge = m.municipio_codigo_ibge
