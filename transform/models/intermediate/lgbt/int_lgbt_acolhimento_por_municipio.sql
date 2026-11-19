-- Intermediate: acolhimento institucional de pessoas trans/travestis, por
-- município. Agrega o grão de UNIDADE (staging) para município.
--
-- Fórmula (calculo_nacional.md, 6.1):
--   "% dos número de pessoas travestis, transexuais ou transgêneros
--   acolhidas (%) = (Possui pessoas trans ou travestis acolhidas hoje (Sim)/
--   Possui pessoas trans ou travestis acolhidas hoje (Sim e Não)) x 100"
--   Denominador = unidades que RESPONDERAM Sim ou Não (chamado 27607: a CGTI
--   apontou 7,1% -> 7,55% em Alagoas; antes dividíamos pelo total de unidades,
--   incluindo as sem resposta).
--   -> % de UNIDADES (não de pessoas) com pelo menos uma pessoa
--   trans/travesti acolhida. CONFIRMADO pela aba "Cálculo_Atendimentos
--   Trans" da equipe (tabela dinâmica: SIM 485 / Total 6.538 = 7,42%).
--   A mesma aba também calcula "% de pessoas trans ou travestis"
--   (1.126 / 157.205 = 0,72%) — derivável a partir de
--   pessoas_trans_acolhidas_total / pessoas_acolhidas_total.
--   O 7,1% -> 7,55% de Alagoas só fechou com a aba que traz o
--   NU_IDENTIFICADOR_UNIDADE (53 unidades, não 56 — ver staging).
--
-- Join com dim_municipio pelo código IBGE de 7 dígitos (a aba nova traz
-- Cod_IBGE_7); nome e UF canônicos vêm do seed.

with unidades as (

    select * from {{ ref('stg_lgbt_unidades_acolhimento') }}

),

agregado_por_municipio as (

    -- Agrega SÓ pelo código IBGE. O campo "Município" do raw
    -- vem com grafias inconsistentes para o mesmo município ("Belem" vs
    -- "Belém", caixa, abreviações) — agrupar também por nome/UF quebraria o
    -- grão de 1 linha por município (o join com dim_municipio no mart
    -- multiplicaria as linhas). Nome e UF canônicos vêm de dim_municipio.
    select
        municipio_codigo_ibge,
        ano_referencia,
        count(*)                                                         as qtd_unidades_acolhimento,
        sum(case when possui_pessoas_trans_acolhidas then 1 else 0 end)  as qtd_unidades_com_pessoas_trans,
        sum(case when respondeu_pessoas_trans_acolhidas then 1 else 0 end) as qtd_unidades_responderam_trans,
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
    a.qtd_unidades_responderam_trans,
    {{ calcula_percentual('a.qtd_unidades_com_pessoas_trans', 'a.qtd_unidades_responderam_trans') }} as pct_unidades_com_pessoas_trans,
    a.qtd_pessoas_acolhidas_total,
    a.qtd_pessoas_trans_acolhidas_total
from agregado_por_municipio a
left join {{ ref('dim_municipio') }} dm
    on dm.codigo_municipio = a.municipio_codigo_ibge
