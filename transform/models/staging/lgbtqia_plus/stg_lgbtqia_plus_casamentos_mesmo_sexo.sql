-- Staging: registros de casamento entre pessoas do mesmo sexo, por município,
-- categoria (entre homens / entre mulheres) e ano — seção 2.5.
--
-- A planilha traz um ano por coluna (2013..2023); aqui viramos para o formato
-- longo (1 linha por município x categoria x ano) para facilitar as agregações
-- por nível e a série histórica no intermediate.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_casamento_mesmo_sexo_ano') }}

),

renomeado as (

    select
        cod_ibge_7::bigint    as municipio_codigo_ibge,
        nome_do_municipio     as municipio_nome,
        cod_uf::int           as uf_codigo,
        uf                    as uf_sigla,
        categoria_de_casam    as categoria_casamento,
        "2013"::bigint as q2013, "2014"::bigint as q2014, "2015"::bigint as q2015,
        "2016"::bigint as q2016, "2017"::bigint as q2017, "2018"::bigint as q2018,
        "2019"::bigint as q2019, "2020"::bigint as q2020, "2021"::bigint as q2021,
        "2022"::bigint as q2022, "2023"::bigint as q2023
    from origem

),

longo as (

    select
        r.municipio_codigo_ibge,
        r.municipio_nome,
        r.uf_codigo,
        r.uf_sigla,
        r.categoria_casamento,
        v.ano::int         as ano,
        v.quantidade::int  as quantidade
    from renomeado r
    cross join lateral (values
        (2013, r.q2013), (2014, r.q2014), (2015, r.q2015), (2016, r.q2016),
        (2017, r.q2017), (2018, r.q2018), (2019, r.q2019), (2020, r.q2020),
        (2021, r.q2021), (2022, r.q2022), (2023, r.q2023)
    ) as v(ano, quantidade)

)

select * from longo
