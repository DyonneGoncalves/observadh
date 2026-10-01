-- Intermediate: ICI estadual, todos os 5 sub-índices no formato longo.
--
-- Responsabilidades desta camada (não há "regra de cálculo de indicador" no
-- ICI — os valores já chegam prontos, ver catálogo seção 0):
--   1. Une os 5 stg_ici_estadual_* com um rótulo de índice.
--   2. Junta com o seed dim_uf para nome/sigla/região canônicos.
--   3. Calcula a média nacional (todas as 27 UFs) e a média da região do
--      estado — pedidas nas tabelas do relatório (Filtro_Estadual), mas não
--      vêm prontas em nenhuma planilha.
--   4. Classifica cada valor com classifica_ici() (única fonte da regra —
--      a coluna de classificação da planilha original é ignorada desde o
--      staging por ter 9 grafias distintas para as mesmas 3 categorias).
--
-- Médias implementadas como MÉDIA SIMPLES (uma UF = um voto), não ponderada
-- por população — decisão pendente de confirmação com a equipe (catálogo,
-- Problema 10). Isolado na CTE `medias` para troca fácil.

with valores as (

    select 'ici_dh' as indice, * from {{ ref('stg_ici_estadual_dh') }}
    union all
    select 'ici_ca', * from {{ ref('stg_ici_estadual_ca') }}
    union all
    select 'ici_lgbtqia', * from {{ ref('stg_ici_estadual_lgbtqia') }}
    union all
    select 'ici_pcd', * from {{ ref('stg_ici_estadual_pcd') }}
    union all
    select 'ici_pi', * from {{ ref('stg_ici_estadual_pi') }}

),

dim_uf as (
    select codigo_uf, sigla_uf, nome_uf, regiao from {{ ref('dim_uf') }}
),

com_regiao as (

    select
        v.indice,
        v.ano_referencia,
        v.uf_codigo,
        u.sigla_uf,
        u.nome_uf,
        u.regiao,
        v.ici_valor
    from valores v
    inner join dim_uf u on u.codigo_uf = v.uf_codigo

),

medias as (

    select
        indice,
        ano_referencia,
        avg(ici_valor) over (partition by indice, ano_referencia)          as media_nacional,
        avg(ici_valor) over (partition by indice, ano_referencia, regiao)  as media_regiao,
        uf_codigo, sigla_uf, nome_uf, regiao, ici_valor
    from com_regiao

)

select
    'estadual'::text        as nivel,
    uf_codigo                as recorte_codigo,
    nome_uf                  as recorte_nome,
    uf_codigo,
    sigla_uf                 as uf_sigla,
    indice,
    ano_referencia,
    ici_valor                as valor,
    {{ classifica_ici('ici_valor') }} as classificacao,
    round(media_nacional::numeric, 4) as media_nacional,
    regiao                   as grupo_comparacao_nome,
    round(media_regiao::numeric, 4)   as media_grupo_comparacao
from medias
