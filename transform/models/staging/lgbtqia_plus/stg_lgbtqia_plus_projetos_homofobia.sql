-- Staging: escolas com projeto de enfrentamento à LGBTQIAfobia, por UF e ano
-- (SAEB 2019 e 2021) — seção 4.1. Junta as duas abas num formato só.
--
-- Denominador do indicador (%) muda por ano, conforme os docs de cálculo:
--   2019 -> "total com informação" (total menos os "ignorado")
--   2021 -> "total" (a aba 2021 não tem coluna "ignorado")
-- Aqui já resolvemos isso em `qtd_base`.

with p2019 as (

    select
        cod_uf::int                as uf_codigo,
        uf                         as uf_sigla,
        2019                       as ano,
        possui_projeto::bigint     as qtd_possui_projeto,
        total_com_informacao::bigint as qtd_base
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_projetos_contra_homofobia_2019') }}

),

p2021 as (

    select
        cod_uf::int             as uf_codigo,
        uf                      as uf_sigla,
        2021                    as ano,
        possui_projeto::bigint  as qtd_possui_projeto,
        total::bigint           as qtd_base
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_projetos_contra_homofobia_2021') }}

)

select * from p2019
union all
select * from p2021
