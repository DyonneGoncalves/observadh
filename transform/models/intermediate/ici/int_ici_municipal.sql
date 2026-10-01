-- Intermediate: ICI municipal, todos os 5 sub-índices no formato longo.
-- Mesmo racional do int_ici_estadual.sql, com duas diferenças:
--   1. O grupo de comparação é a UF do município (não a região) — é o que
--      o Filtro_Municipal pede ("Média dos ICI municipais do estado"), não
--      confundir com o agrupamento do relatório estadual (ver catálogo,
--      seção 3.3).
--   2. Não existe coluna de classificação em nenhuma planilha municipal —
--      100% derivada por classifica_ici() aqui, não só "recalculada".
--
-- ICI-PSR não está incluído: nenhuma planilha com esse dado foi recebida
-- (catálogo, Problema 3). Quando chegar, adicionar um stg_ici_municipal_psr
-- e uma linha na união abaixo.

with valores as (

    select 'ici_dh' as indice, * from {{ ref('stg_ici_municipal_dh') }}
    union all
    select 'ici_ca', * from {{ ref('stg_ici_municipal_ca') }}
    union all
    select 'ici_lgbtqia', * from {{ ref('stg_ici_municipal_lgbtqia') }}
    union all
    select 'ici_pcd', * from {{ ref('stg_ici_municipal_pcd') }}
    union all
    select 'ici_pi', * from {{ ref('stg_ici_municipal_pi') }}

),

dim_municipio as (
    select codigo_municipio, nome_municipio, codigo_uf from {{ ref('dim_municipio') }}
),

dim_uf as (
    select codigo_uf, sigla_uf, nome_uf from {{ ref('dim_uf') }}
),

com_uf as (

    select
        v.indice,
        v.ano_referencia,
        v.municipio_codigo,
        m.nome_municipio,
        v.uf_codigo,
        u.sigla_uf,
        u.nome_uf,
        v.ici_valor
    from valores v
    inner join dim_municipio m on m.codigo_municipio = v.municipio_codigo
    inner join dim_uf u         on u.codigo_uf = v.uf_codigo

),

medias as (

    select
        indice,
        ano_referencia,
        avg(ici_valor) over (partition by indice, ano_referencia)            as media_nacional,
        avg(ici_valor) over (partition by indice, ano_referencia, uf_codigo) as media_uf,
        municipio_codigo, nome_municipio, uf_codigo, sigla_uf, nome_uf, ici_valor
    from com_uf

)

select
    'municipal'::text        as nivel,
    municipio_codigo         as recorte_codigo,
    nome_municipio           as recorte_nome,
    uf_codigo,
    sigla_uf                 as uf_sigla,
    indice,
    ano_referencia,
    ici_valor                as valor,
    {{ classifica_ici('ici_valor') }} as classificacao,
    round(media_nacional::numeric, 4) as media_nacional,
    nome_uf                  as grupo_comparacao_nome,
    round(media_uf::numeric, 4)       as media_grupo_comparacao
from medias
