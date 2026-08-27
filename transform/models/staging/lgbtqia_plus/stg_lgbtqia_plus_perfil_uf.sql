-- Staging: só limpeza/renomeação/tipagem. Nenhuma regra de negócio aqui.
--
-- TODO: substituir as colunas de exemplo abaixo pelas colunas reais assim
-- que a planilha "Perfil UF" do tema LGBTQIA+ for mapeada. Este arquivo é
-- um template mostrando o padrão a seguir, não um modelo funcional ainda.

with origem as (

    select *
    from {{ source('raw_lgbtqia_plus', 'raw_lgbtqia_plus_perfil_uf') }}

),

renomeado as (

    select
        -- TODO: mapear para os nomes de coluna reais da planilha
        -- codigo_uf::int                  as codigo_uf,
        -- populacao_lgbtqia_estimada::int as populacao_estimada,
        ano_referencia_carga               as ano_referencia,
        id_carga,
        arquivo_origem,
        data_processamento
    from origem

)

select * from renomeado
