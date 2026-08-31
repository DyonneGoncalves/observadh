-- Intermediate: seção 7.1 — Denúncias de violações de direitos humanos (ONDH
-- 2020-2024). Saída no FORMATO LONGO. Níveis NACIONAL / ESTADUAL / MUNICIPAL.
--
-- Indicadores (Cálculo_Indicadores_LGBTQIA+, 7.1 + "Cálculo ONDH *"):
--   denuncias_por_ano / violacoes_por_ano        série 2020..2024 (nº absoluto)
--   denuncias_total_2020_2024                    soma das denúncias no período
--   pct_participacao_denuncias_2024              denúncias do recorte / Brasil 2024 *100
--   pct_denuncias_por_sexo                       Fem/Intersexo/Masc (exclui não informado)
--   pct_denuncias_por_faixa_etaria               Até 29 / 30-39 / 40-49 / 50-59 / Idosos 60+
--   pct_denuncias_por_raca_cor                   Negra (parda+preta) / Branca / Amarela / Indígena
--   pct_denuncias_por_identidade_genero          8 categorias (inclui não informado)
--   pct_denuncias_por_orientacao_sexual          6 categorias (inclui não informado)
--   pct_denuncias_por_tipo_violacao              1 categoria por tipo
--
-- NÃO modelados ainda (mesma mecânica, listas de colunas longas — ver catálogo):
--   local de ocorrência (ONDH_Local, 32 colunas) e relação do suspeito
--   (ONDH_Relação_Suspeito, 50 colunas).

with dim_uf as (
    select codigo_uf, nome_uf from {{ ref('dim_uf') }}
),
dim_mun as (
    select codigo_municipio, nome_municipio from {{ ref('dim_municipio') }}
),

-- ------------------------------------------------------------ SÉRIE HISTÓRICA
serie_long as (
    select s.cod_uf::int as uf_codigo, s.cod_ibge7::int as municipio_codigo_ibge,
           m.ano, m.metrica, coalesce(m.qtd, 0)::numeric as qtd
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_serie_historica') }} s
    cross join lateral (values
        (2020, 'denuncias', s.qtd_denuncias_2020), (2020, 'violacoes', s.qtd_violacoes_2020),
        (2021, 'denuncias', s.qtd_denuncias_2021), (2021, 'violacoes', s.qtd_violacoes_2021),
        (2022, 'denuncias', s.qtd_denuncias_2022), (2022, 'violacoes', s.qtd_violacoes_2022),
        (2023, 'denuncias', s.qtd_denuncias_2023), (2023, 'violacoes', s.qtd_violacoes_2023),
        (2024, 'denuncias', s.qtd_denuncias_2024), (2024, 'violacoes', s.qtd_violacoes_2024)
    ) as m(ano, metrica, qtd)
),

serie_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, ano, metrica, sum(qtd) as q
    from serie_long group by ano, metrica
    union all
    select 'estadual', uf_codigo, ano, metrica, sum(qtd) from serie_long group by uf_codigo, ano, metrica
    union all
    select 'municipal', municipio_codigo_ibge, ano, metrica, sum(qtd) from serie_long group by municipio_codigo_ibge, ano, metrica
),

serie_ind as (
    select nivel, recorte_codigo,
           case metrica when 'denuncias' then 'denuncias_por_ano' else 'violacoes_por_ano' end as indicador,
           ano::text as categoria, q as valor, 'numero_absoluto'::text as valor_tipo, ano as ano_referencia
    from serie_agg

    union all
    select nivel, recorte_codigo, 'denuncias_total_2020_2024', null, sum(q), 'numero_absoluto', 2024
    from serie_agg where metrica = 'denuncias' group by nivel, recorte_codigo

    union all
    select nivel, recorte_codigo, 'pct_participacao_denuncias_2024', null,
           round(100.0 * q / nullif(
               (select sum(q) from serie_agg where metrica = 'denuncias' and ano = 2024 and nivel = 'nacional'), 0), 4),
           'percentual', 2024
    from serie_agg
    where metrica = 'denuncias' and ano = 2024 and nivel <> 'nacional'
),

-- ------------------------------------------------------------- QUEBRAS (%)
brk_sexo as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_sexo'),
        'pct_denuncias_por_sexo',
        [['Feminino', 's.fem'], ['Intersexo', 's.intersexo'], ['Masculino', 's.masc']]
    ) }}
),

brk_faixa as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_faixa_etaria'),
        'pct_denuncias_por_faixa_etaria',
        [
            ['Até 29 anos', 's."00_a_04_anos" + s."05_a_11_anos" + s."12_a_17_anos" + s."18_a_29_anos"'],
            ['30 a 39 anos', 's."30_a_39_anos"'],
            ['40 a 49 anos', 's."40_a_49_anos"'],
            ['50 a 59 anos', 's."50_a_59_anos"'],
            ['Idosos (60 anos ou mais)', 's."60_a_69_anos" + s."70_a_79_anos" + s."80_anos_ou_mais"']
        ]
    ) }}
),

brk_raca as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_raca_cor'),
        'pct_denuncias_por_raca_cor',
        [['Negra', 's.parda + s.preta'], ['Branca', 's.branca'],
         ['Amarela', 's.amarela'], ['Indígena', 's.indigena']]
    ) }}
),

brk_identidade as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_identidade_genero'),
        'pct_denuncias_por_identidade_genero',
        [['Homem cis', 's.homem_cis'], ['Homem trans', 's.homem_trans'],
         ['Mulher cis', 's.mulher_cis'], ['Mulher trans', 's.mulher_trans'],
         ['Travesti', 's.travesti'], ['Outro', 's.outro'],
         ['Não informado', 's.nao_informado'], ['Não se aplica', 's.nao_se_aplica']]
    ) }}
),

brk_orientacao as (
    {{ ondh_breakdown_percentual(
        source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_orientacao_sexual'),
        'pct_denuncias_por_orientacao_sexual',
        [['Bissexual', 's.bissexual'], ['Heterossexual', 's.heterossexual'],
         ['Homossexual', 's.homossexual'], ['Outro', 's.outro'],
         ['Não informado', 's.nao_informado'], ['Não se aplica', 's.nao_se_aplica']]
    ) }}
),

-- --------------------------------------------------------- TIPO DE VIOLAÇÃO
tv_agg as (
    select 'nacional'::text as nivel, null::int as recorte_codigo, tipo_de_violacao as categoria,
           sum(total_com_info) as q
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_tipo_de_violacao') }}
    group by tipo_de_violacao
    union all
    select 'estadual', cod_uf::int, tipo_de_violacao, sum(total_com_info)
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_tipo_de_violacao') }}
    group by cod_uf, tipo_de_violacao
    union all
    select 'municipal', cod_ibge7::int, tipo_de_violacao, sum(total_com_info)
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_ondh_tipo_de_violacao') }}
    group by cod_ibge7, tipo_de_violacao
),

tv_ind as (
    select nivel, recorte_codigo, 'pct_denuncias_por_tipo_violacao'::text as indicador,
           categoria,
           round(100.0 * q / nullif(sum(q) over (partition by nivel, recorte_codigo), 0), 4) as valor,
           'percentual'::text as valor_tipo, 2024 as ano_referencia
    from tv_agg
),

-- ------------------------------------------------------------------ UNIÃO
todos as (
    select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from serie_ind
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_sexo
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_faixa
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_raca
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_identidade
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from brk_orientacao
    union all select nivel, recorte_codigo, indicador, categoria, valor, valor_tipo, ano_referencia from tv_ind
)

select
    t.nivel,
    t.recorte_codigo,
    case t.nivel
        when 'nacional'  then 'Brasil'
        when 'estadual'  then u.nome_uf
        when 'municipal' then m.nome_municipio
    end                                                     as recorte_nome,
    '7.1'::text                                             as secao,
    'Violência — Denúncias de violações de DH (ONDH)'::text  as secao_nome,
    t.indicador,
    t.categoria,
    t.valor,
    t.valor_tipo,
    t.ano_referencia
from todos t
left join dim_uf  u on t.nivel = 'estadual'  and u.codigo_uf = t.recorte_codigo
left join dim_mun m on t.nivel = 'municipal' and m.codigo_municipio = t.recorte_codigo
-- descarta recortes sem correspondência nas dimensões (cod_uf/cod_ibge inválidos
-- na origem, ex.: "Não se aplica"). O total nacional acima já os contabiliza.
where t.nivel = 'nacional'
   or (t.nivel = 'estadual'  and u.codigo_uf is not null)
   or (t.nivel = 'municipal' and m.codigo_municipio is not null)
