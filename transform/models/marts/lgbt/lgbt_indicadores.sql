-- Mart: TODOS os indicadores do relatório LGBTQIA+ no formato longo.
--
-- Uma linha por (nivel, recorte_codigo, secao, indicador, categoria). É a
-- tabela que a aplicação consulta para preencher o texto-base do relatório,
-- filtrando por nivel + recorte + secao.
--
-- Cada (sub)seção do relatório é um modelo intermediate
-- `int_lgbt_<secao>_*` que já devolve neste mesmo formato. Aqui só
-- fazemos a UNIÃO. As views lgbt_indicadores_{nacional,estadual,
-- municipal} filtram por nível para conveniência da aplicação.
--
-- Contrato de colunas: ver cabeçalho de qualquer int_lgbt_*.

select * from {{ ref('int_lgbt_5_1_servicos_saude_trans') }}

union all
select * from {{ ref('int_lgbt_1_populacao') }}

union all
select * from {{ ref('int_lgbt_2_perfil_pns') }}

union all
select * from {{ ref('int_lgbt_3_trabalho_renda') }}

union all
select * from {{ ref('int_lgbt_4_0_educacao') }}

union all
select * from {{ ref('int_lgbt_5_0_saude') }}

union all
select * from {{ ref('int_lgbt_2_5_casamentos_registro_civil') }}

union all
select * from {{ ref('int_lgbt_2_5_perfil_conjugal_pns') }}

union all
select * from {{ ref('int_lgbt_4_1_projetos_escolares') }}

union all
select * from {{ ref('int_lgbt_6_0_assistencia_social') }}

union all
select * from {{ ref('int_lgbt_6_1_protecao_social_especial') }}

union all
select * from {{ ref('int_lgbt_7_0_violencia_sinan') }}

union all
select * from {{ ref('int_lgbt_7_1_denuncias_ondh') }}
