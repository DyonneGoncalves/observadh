-- Intermediate: seção 5 (abertura) — Saúde: autoavaliação da saúde, atividade
-- esportiva e diagnóstico de depressão, por orientação sexual (PNS 2019).
-- Formato LONGO. Só nível NACIONAL.
--
-- Fórmulas (Cálculo_Indicadores_LGBTQIA+_Nacional, 5):
--   pct_autoavaliacao_saude_por_orientacao   grupo X / total da orientação × 100
--     grupos: "Muito boa e boa" (= muito_boa + boa), "Regular",
--             "Muito ruim e ruim" (= ruim + muito_ruim)
--   pct_atividade_esportiva_por_orientacao    frequência X / total da orientação × 100
--   pct_depressao_por_orientacao              diagnóstico X / total da orientação × 100
--   autoavaliacao_saude_predominante_homossexual
--       grupo de autoavaliação com MAIOR % entre homossexuais — é a expressão
--       do texto ("avaliaram a própria saúde como <muito boa e boa>"), com o
--       rótulo da planilha, na coluna `categoria`; `valor` = % de homossexuais nesse
--       grupo. Os % de bissexuais/heterossexuais citados na mesma frase são do
--       MESMO grupo (ver docs/lgbt/consumo-lgbt_indicadores.md).
--       Regra de escolha (maior % entre homossexuais) é inferência do
--       texto-base — o Cálculo_Indicadores não define. Confirmar com a área.

with autoaval as (
    select {{ orientacao_canonica('tipo_de_orient_sexual') }} as orientacao, *
    from {{ source('raw_lgbt', 'raw_lgbt_autoavaliacao_saude') }}
    where tipo_de_orient_sexual not ilike 'total%'
),
esporte as (
    select {{ orientacao_canonica('tipo_de_orient_sexual') }} as orientacao, *
    from {{ source('raw_lgbt', 'raw_lgbt_atividade_esportiva') }}
    where tipo_de_orient_sexual not ilike 'total%'
),
depressao as (
    select {{ orientacao_canonica('tipo_de_orient_sexual') }} as orientacao, *
    from {{ source('raw_lgbt', 'raw_lgbt_taxa_depressao') }}
    where tipo_de_orient_sexual not ilike 'total%'
),

autoaval_grupos as (
    select a.orientacao, v.grupo,
           {{ calcula_percentual('v.qtd', 'a.total::numeric') }} as valor
    from autoaval a
    cross join lateral (values
        ('Muito boa e boa',   (a.muito_boa + a.boa)::numeric),
        ('Regular',           a.regular::numeric),
        ('Muito ruim e ruim', (a.ruim + a.muito_ruim)::numeric)
    ) as v(grupo, qtd)
),

linhas as (

    select 'pct_autoavaliacao_saude_por_orientacao'::text as indicador,
           a.orientacao || ' / ' || v.grupo               as categoria,
           {{ calcula_percentual('v.qtd', 'a.total::numeric') }} as valor
    from autoaval a
    cross join lateral (values
        ('Muito boa e boa',   (a.muito_boa + a.boa)::numeric),
        ('Regular',           a.regular::numeric),
        ('Muito ruim e ruim', (a.ruim + a.muito_ruim)::numeric)
    ) as v(grupo, qtd)

    union all

    select 'pct_atividade_esportiva_por_orientacao',
           e.orientacao || ' / ' || v.freq,
           {{ calcula_percentual('v.qtd', 'e.total::numeric') }}
    from esporte e
    cross join lateral (values
        ('Mais de uma vez por semana', e.mais_de_uma_vez_por_semana::numeric),
        ('Uma vez por semana',         e.uma_vez_por_semana::numeric),
        ('De 2 a 3 vezes por mês',     e.de_2_a_3_vezes_por_mes::numeric),
        ('Algumas vezes no ano',       e.algumas_vezes_no_ano::numeric),
        ('Uma vez no ano',             e.uma_vez_no_ano::numeric),
        ('Nenhuma vez',                e.nenhuma_vez::numeric)
    ) as v(freq, qtd)

    union all

    select 'pct_depressao_por_orientacao',
           d.orientacao || ' / ' || v.diag,
           {{ calcula_percentual('v.qtd', 'd.total::numeric') }}
    from depressao d
    cross join lateral (values
        ('Já teve diagnóstico de depressão', d.ja_teve_diagnostico_de_depressao::numeric),
        ('Não teve diagnóstico de depressão', d.nao_teve_diagnostico_de_depressao::numeric)
    ) as v(diag, qtd)
)

, predominante as (
    -- 1 linha: grupo com maior % entre homossexuais
    select 'autoavaliacao_saude_predominante_homossexual'::text as indicador,
           grupo                                                as categoria,
           valor
    from autoaval_grupos
    where orientacao = 'Homossexual'
    order by valor desc, grupo
    limit 1
)

select
    'nacional'::text                as nivel,
    null::int                       as recorte_codigo,
    'Brasil'::text                  as recorte_nome,
    '5'::text                       as secao,
    'Saúde — Perfil de saúde'::text  as secao_nome,
    indicador, categoria, valor,
    'percentual'::text             as valor_tipo,
    2019                           as ano_referencia
from linhas

union all

select
    'nacional', null::int, 'Brasil', '5', 'Saúde — Perfil de saúde',
    indicador, categoria, valor,
    'categoria_predominante',
    2019
from predominante
