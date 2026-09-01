-- Staging: por UF, total de casamentos entre cônjuges masculino/feminino e
-- total de casamentos lesbohomoafetivos (base do indicador "% de casamentos
-- lesbohomoafetivos", seção 2.5). Grão: 1 linha por UF.

with origem as (

    select *
    from {{ source('raw_lgbt', 'raw_lgbt_total_casamentos_uf') }}

)

select
    cod_uf::int                              as uf_codigo,
    uf                                       as uf_sigla,
    unid_da_federacao                        as uf_nome,
    ano_de_referencia::int                   as ano_referencia,
    total_de_casam_entre_conj_masc_e_fem::bigint as qtd_casamentos_masc_fem,
    total_de_casam_lesbohomoafetivos::bigint     as qtd_casamentos_lesbohomoafetivos
from origem
