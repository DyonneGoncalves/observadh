-- Testes estruturais do indicador vitimas_paefi_serie_historica (seção 6.1).
--
-- Não valida os números em si (não há um valor de referência publicado por
-- UF/município para a série completa, só o agregado nacional de 2024 — ver
-- lgbt_6_1_valores.sql). Valida que a série está íntegra:
--   1) nunca aparece em nível nacional (a especificação só pede a série em
--      estadual/municipal — ver comentário em
--      int_lgbt_6_1_protecao_social_especial.sql);
--   2) `categoria` sempre igual a `ano_referencia` (mesmo padrão das demais
--      séries anuais, ex. notificacoes_por_ano);
--   3) nenhum recorte com dado de PAEFI 2024 (`vitimas_paefi`) fica com
--      menos anos na série do que a fonte (int_lgbt_paefi_por_municipio)
--      tem disponíveis para aquele recorte — pega regressão silenciosa
--      (ex. um group by que "some" com um ano).

with serie as (
    select nivel, recorte_codigo, categoria, ano_referencia
    from {{ ref('lgbt_indicadores') }}
    where secao = '6.1' and indicador = 'vitimas_paefi_serie_historica'
),

falha_nivel_nacional as (
    select nivel, recorte_codigo, categoria, ano_referencia,
           'nivel=nacional nao deveria ter serie historica' as motivo
    from serie
    where nivel = 'nacional'
),

falha_categoria_ano as (
    select nivel, recorte_codigo, categoria, ano_referencia,
           'categoria diferente de ano_referencia' as motivo
    from serie
    where categoria <> ano_referencia::text
),

paefi_fonte as (
    select 'estadual'::text as nivel, uf_codigo as recorte_codigo, ano_referencia
    from {{ ref('int_lgbt_paefi_por_municipio') }}
    group by uf_codigo, ano_referencia
    union all
    select 'municipal', municipio_codigo_ibge, ano_referencia
    from {{ ref('int_lgbt_paefi_por_municipio') }}
    group by municipio_codigo_ibge, ano_referencia
),

anos_por_recorte_fonte as (
    select nivel, recorte_codigo, count(distinct ano_referencia) as anos_na_fonte
    from paefi_fonte
    group by nivel, recorte_codigo
),

anos_por_recorte_serie as (
    select nivel, recorte_codigo, count(distinct ano_referencia) as anos_na_serie
    from serie
    group by nivel, recorte_codigo
),

recortes_com_2024 as (
    select nivel, recorte_codigo
    from {{ ref('lgbt_indicadores') }}
    where secao = '6.1' and indicador = 'vitimas_paefi' and nivel in ('estadual', 'municipal')
),

falha_serie_incompleta as (
    select r.nivel, r.recorte_codigo, null::text as categoria, null::int as ano_referencia,
           'serie historica com menos anos que a fonte (' || coalesce(s.anos_na_serie, 0)
               || ' de ' || f.anos_na_fonte || ')' as motivo
    from recortes_com_2024 r
    join anos_por_recorte_fonte f using (nivel, recorte_codigo)
    left join anos_por_recorte_serie s using (nivel, recorte_codigo)
    where coalesce(s.anos_na_serie, 0) < f.anos_na_fonte
)

select * from falha_nivel_nacional
union all
select * from falha_categoria_ano
union all
select * from falha_serie_incompleta
