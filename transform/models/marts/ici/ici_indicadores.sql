-- Mart: TODOS os sub-índices ICI (estadual + municipal) no formato longo.
--
-- Uma linha por (nivel, recorte_codigo, indice, ano_referencia). É a tabela
-- que a aplicação consulta para montar a tabela de série histórica e o
-- resumo de cada relatório (Filtro_Estadual / Filtro_Municipal). Ver
-- docs/ici/consumo-ici_indicadores.md.
--
-- Sem nível nacional: o ICI não tem relatório nacional (Filtro_Nacional_V1
-- é só texto institucional, sem variável — ver catálogo, seção 1). Sem
-- ICI-PSR: planilha não recebida (catálogo, Problema 3).

select * from {{ ref('int_ici_estadual') }}

union all
select * from {{ ref('int_ici_municipal') }}
