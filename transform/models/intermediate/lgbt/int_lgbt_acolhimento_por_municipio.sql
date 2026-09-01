-- Intermediate: acolhimento institucional de pessoas trans/travestis, por
-- município. Agrega o grão de UNIDADE (staging) para município.
--
-- Fórmula (calculo_nacional.md, 6.1):
--   "% dos número de pessoas travestis, transexuais ou transgêneros
--   acolhidas (%) = (Possui pessoas trans ou travestis acolhidas hoje (Sim)/
--   Possui pessoas trans ou travestis acolhidas hoje (Sim e Não)) x 100"
--   -> interpretado como % de UNIDADES (não de pessoas) com pelo menos uma
--   pessoa trans/travesti acolhida. TODO: confirmar essa interpretação com
--   a equipe — a redação da fórmula é ambígua entre "% de unidades" e
--   "% de pessoas acolhidas que são trans".
--
-- Join com dim_municipio: esta aba só traz código IBGE de 6 dígitos e UF
-- (sigla) — usamos o seed para obter o código de 7 dígitos e o código de UF,
-- consistentes com as demais tabelas de Assistência Social.

with unidades as (

    select * from {{ ref('stg_lgbt_unidades_acolhimento') }}

),

agregado_por_municipio as (

    -- Agrega SÓ pelo código IBGE de 6 dígitos. O campo "Município" do raw
    -- vem com grafias inconsistentes para o mesmo município ("Belem" vs
    -- "Belém", caixa, abreviações) — agrupar também por nome/UF quebraria o
    -- grão de 1 linha por município (o join com dim_municipio no mart
    -- multiplicaria as linhas). Nome e UF canônicos vêm de dim_municipio.
    select
        municipio_codigo_ibge_6dig,
        ano_referencia,
        count(*)                                                         as qtd_unidades_acolhimento,
        sum(case when possui_pessoas_trans_acolhidas then 1 else 0 end)  as qtd_unidades_com_pessoas_trans,
        sum(qtd_pessoas_acolhidas_unidade)                               as qtd_pessoas_acolhidas_total,
        sum(qtd_pessoas_trans_acolhidas_unidade)                         as qtd_pessoas_trans_acolhidas_total
    from unidades
    group by 1, 2

)

select
    dm.codigo_municipio       as municipio_codigo_ibge,
    dm.nome_municipio         as municipio_nome,
    dm.codigo_uf              as uf_codigo,
    dm.sigla_uf               as uf_sigla,
    a.ano_referencia,
    a.qtd_unidades_acolhimento,
    a.qtd_unidades_com_pessoas_trans,
    {{ calcula_percentual('a.qtd_unidades_com_pessoas_trans', 'a.qtd_unidades_acolhimento') }} as pct_unidades_com_pessoas_trans,
    a.qtd_pessoas_acolhidas_total,
    a.qtd_pessoas_trans_acolhidas_total
from agregado_por_municipio a
left join {{ ref('dim_municipio') }} dm
    on dm.codigo_municipio_6dig = a.municipio_codigo_ibge_6dig
