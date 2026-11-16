-- Intermediate: seção 2 — Perfil das pessoas LGBTQIA+ (PNS 2019). Formato LONGO.
-- 2.0 (% por orientação) existe em NACIONAL e ESTADUAL; 2.1–2.4 só NACIONAL
-- (a PNS não publica esses cruzamentos por UF).
--
-- ESTADUAL (chamado 27607, item 1): a aba "Orientação sexual por UF" já traz
-- os percentuais prontos, 1 linha por UF e 1 coluna por orientação — não há
-- recálculo, só "despivotamos" as colunas. As colunas são lidas de forma
-- genérica (to_jsonb + jsonb_each_text) e mapeadas pelo prefixo do nome,
-- porque a ingestão normaliza os cabeçalhos ("homosexual", "outra_orient"...)
-- e só 3 deles eram usados até aqui. As 6 categorias de saída são as mesmas
-- do nacional (Heterossexual, Bissexual, Homossexual, Outra orientação,
-- Não sabe, Recusou-se a responder). O teste lgbt_2_valores_estadual
-- garante as 6 categorias por UF e confere Alagoas.
--
-- As tabelas de origem já estão no nível Brasil: 1 linha por orientação sexual
-- + 1 linha "Total com info". O % é calculado LINHA A LINHA (categoria da
-- orientação X / total da orientação X × 100), sem agregação entre municípios.
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+_Nacional, 2 / 2.1-2.4):
--   pct_populacao_por_orientacao       total da orientação X / total geral × 100
--   pct_orientacao_por_sexo            homens|mulheres da orient. X / total da orient. X
--   pct_orientacao_por_faixa_etaria    faixa Y da orient. X / total com info de faixa da orient. X
--   pct_orientacao_por_raca_cor        cor Y da orient. X / total com info de cor da orient. X
--   pct_orientacao_por_localidade      área Y da orient. X / total com info de localidade da orient. X

with sexo_total as (
    select {{ orientacao_canonica('tipo_de_orient_sexual') }} as orientacao,
           total_da_pop::numeric        as total_pop,
           total_de_homens::numeric     as homens,
           total_de_mulheres::numeric   as mulheres
    from {{ source('raw_lgbt', 'raw_lgbt_pessoas_orientacao_sexo_total') }}
),
total_geral as (
    select total_pop from sexo_total where orientacao ilike 'total%'
),

-- as abas trazem uma linha "Total com info de Orientação Sexual" que não é
-- uma orientação — descartada aqui.
faixa as (
    select * from {{ source('raw_lgbt', 'raw_lgbt_pessoas_faixa_etaria') }}
    where tipo_de_orient_sexual not ilike 'total%' and coalesce(trim(tipo_de_orient_sexual), '') <> ''
),
raca as (
    select * from {{ source('raw_lgbt', 'raw_lgbt_pessoas_cor_ou_raca') }}
    where tipo_de_orient_sexual not ilike 'total%' and coalesce(trim(tipo_de_orient_sexual), '') <> ''
),
localidade as (
    select * from {{ source('raw_lgbt', 'raw_lgbt_pessoas_area_localidade') }}
    where tipo_de_orient_sexual not ilike 'total%' and coalesce(trim(tipo_de_orient_sexual), '') <> ''
),

-- 2.0 estadual — colunas da aba por UF -> linhas
orient_uf as (
    select
        (j.linha ->> 'cod_uf')::numeric::int as uf_codigo,
        kv.key                               as coluna,
        nullif(trim(kv.value), '')           as valor_txt
    from (
        select to_jsonb(t) as linha
        from {{ source('raw_lgbt', 'raw_lgbt_orientacao_sexual_por_uf') }} t
    ) j
    cross join lateral jsonb_each_text(j.linha) as kv
),
orient_uf_canonica as (
    select
        uf_codigo,
        case
            when coluna like 'hetero%'                          then 'Heterossexual'
            when coluna like 'homo%'                            then 'Homossexual'
            when coluna like 'bi%'                              then 'Bissexual'
            when coluna like 'outra%'                           then 'Outra orientação'
            when coluna like 'n%o_sab%' or coluna like 'nao%'   then 'Não sabe'
            when coluna like 'recus%'                           then 'Recusou-se a responder'
        end                                                     as orientacao,
        valor_txt
    from orient_uf
    where uf_codigo is not null
),

linhas as (

    -- 2.0 — % da população por orientação
    select 'pct_populacao_por_orientacao'::text as indicador,
           orientacao                           as categoria,
           {{ calcula_percentual('total_pop', '(select total_pop from total_geral)') }} as valor
    from sexo_total
    where orientacao not ilike 'total%'

    union all
    -- 2.1 — % da orientação por sexo
    select 'pct_orientacao_por_sexo', s.orientacao || ' / ' || v.sexo,
           {{ calcula_percentual('v.qtd', 's.total_pop') }}
    from sexo_total s
    cross join lateral (values ('Homens', s.homens), ('Mulheres', s.mulheres)) as v(sexo, qtd)
    where s.orientacao not ilike 'total%'

    union all
    -- 2.2 — % da orientação por faixa etária
    select 'pct_orientacao_por_faixa_etaria',
           {{ orientacao_canonica('f.tipo_de_orient_sexual') }} || ' / ' || v.faixa,
           {{ calcula_percentual('v.qtd', 'f.total_com_info_de_fx_etaria::numeric') }}
    from faixa f
    cross join lateral (values
        ('18 a 29 anos', f."18_a_29_anos"::numeric), ('30 a 39 anos', f."30_a_39_anos"::numeric),
        ('40 a 49 anos', f."40_a_49_anos"::numeric), ('50 a 59 anos', f."50_a_59_anos"::numeric),
        ('60 a 69 anos', f."60_a_69_anos"::numeric), ('70 a 79 anos', f."70_a_79_anos"::numeric),
        ('80 anos ou mais', f."80_anos_ou_mais"::numeric)
    ) as v(faixa, qtd)

    union all
    -- 2.3 — % da orientação por cor/raça
    select 'pct_orientacao_por_raca_cor',
           {{ orientacao_canonica('r.tipo_de_orient_sexual') }} || ' / ' || v.cor,
           {{ calcula_percentual('v.qtd', 'r.total_com_info_de_cor_ou_raca::numeric') }}
    from raca r
    cross join lateral (values
        ('Branca', r.branca::numeric), ('Preta', r.preta::numeric), ('Parda', r.parda::numeric),
        ('Amarela', r.amarela::numeric), ('Indígena', r.indigena::numeric)
    ) as v(cor, qtd)

    union all
    -- 2.4 — % da orientação por localidade
    select 'pct_orientacao_por_localidade',
           {{ orientacao_canonica('l.tipo_de_orient_sexual') }} || ' / ' || v.area,
           {{ calcula_percentual('v.qtd', 'l.total_com_info_de_localidade::numeric') }}
    from localidade l
    cross join lateral (values ('Urbana', l.urbano::numeric), ('Rural', l.rural::numeric)) as v(area, qtd)
)

select
    'nacional'::text                        as nivel,
    null::int                               as recorte_codigo,
    'Brasil'::text                          as recorte_nome,
    '2'::text                               as secao,
    'Perfil das pessoas LGBTQIA+'::text      as secao_nome,
    indicador,
    categoria,
    valor,
    'percentual'::text                      as valor_tipo,
    2019                                    as ano_referencia
from linhas

union all

-- 2.0 — % da população por orientação, ESTADUAL (valor já é % na origem)
select
    'estadual'::text,
    o.uf_codigo,
    u.nome_uf,
    '2'::text,
    'Perfil das pessoas LGBTQIA+'::text,
    'pct_populacao_por_orientacao'::text,
    o.orientacao,
    round(coalesce(o.valor_txt::numeric, 0), 4),
    'percentual'::text,
    2019
from orient_uf_canonica o
join {{ ref('dim_uf') }} u on u.codigo_uf = o.uf_codigo
where o.orientacao is not null
