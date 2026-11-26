-- Mart: TODOS os indicadores do relatório PSR (Pessoas em Situação de Rua) no
-- formato longo — mesmo contrato do lgbt_indicadores.
--
-- Uma linha por (nivel, recorte_codigo, secao, indicador, categoria,
-- ano_referencia). É a tabela que a aplicação consulta para preencher o
-- texto-base do relatório, filtrando por nivel + recorte (+ secao).
--
-- Cada seção do relatório é um intermediate int_psr_<secao>_* que já devolve
-- neste formato; aqui só fazemos a UNIÃO. As tabelas
-- psr_indicadores_{nacional,estadual,municipal} recortam por nível.
-- Ver docs/psr/consumo-psr_indicadores.md.

select * from {{ ref('int_psr_1_populacao') }}
union all
select * from {{ ref('int_psr_2_perfil') }}
union all
select * from {{ ref('int_psr_3_violencia') }}
union all
select * from {{ ref('int_psr_4_renda') }}
union all
select * from {{ ref('int_psr_5_politicas_publicas') }}
