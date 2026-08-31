-- Mart: TODOS os indicadores do relatório LGBTQIA+ no formato longo.
--
-- Uma linha por (nivel, recorte_codigo, secao, indicador, categoria). É a
-- tabela que a aplicação consulta para preencher o texto-base do relatório,
-- filtrando por nivel + recorte + secao.
--
-- Cada (sub)seção do relatório é um modelo intermediate
-- `int_lgbtqia_plus_<secao>_*` que já devolve neste mesmo formato. Aqui só
-- fazemos a UNIÃO. As views lgbtqia_plus_indicadores_{nacional,estadual,
-- municipal} filtram por nível para conveniência da aplicação.
--
-- Contrato de colunas: ver cabeçalho de qualquer int_lgbtqia_plus_*.

select * from {{ ref('int_lgbtqia_plus_5_1_servicos_saude_trans') }}

union all
select * from {{ ref('int_lgbtqia_plus_2_5_casamentos_registro_civil') }}

union all
select * from {{ ref('int_lgbtqia_plus_2_5_perfil_conjugal_pns') }}
