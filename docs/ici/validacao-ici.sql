-- Queries de validação do pipeline ICI, usando exatamente o padrão de
-- consumo da aplicação (ver docs/ici/consumo-ici_indicadores.md).
-- Abra este arquivo no DBeaver e rode cada bloco separado, conectado
-- no banco "observadh" (não "postgres").

-- 1. Série histórica do Acre, ICI-DH.
--    Esperado (conferido contra o relatório original): 2023 = 0,06,
--    classificação "Baixa capacidade institucional".
select ano_referencia, valor, classificacao, media_nacional, media_regiao
from dev_marts.ici_indicadores_estadual
where uf_codigo = 12 and indice = 'ici_dh'
order by ano_referencia;

-- 2. Tabela-resumo do Acre, 2023, todos os sub-índices
--    (a tabela final de cada relatório estadual).
select indice, valor, classificacao
from dev_marts.ici_indicadores_estadual
where uf_codigo = 12 and ano_referencia = 2023
order by indice;

-- 3. Série histórica de São Paulo capital (cód. IBGE 3550308), ICI-DH.
select ano_referencia, valor, classificacao, media_nacional, media_estado
from dev_marts.ici_indicadores_municipal
where municipio_codigo_ibge = 3550308 and indice = 'ici_dh'
order by ano_referencia;

-- 4. Conferência de volume total — deve bater com o resultado do dbt build:
--    estadual = 405 linhas (27 UFs x 5 índices x 3 anos)
--    municipal = 83.550 linhas (5.570 municípios x 5 índices x 3 anos)
select nivel, count(*) as linhas
from dev_marts.ici_indicadores
group by nivel
order by nivel;

-- 5. Checagem extra: nenhum valor fora do intervalo [0,1] e nenhuma
--    classificação "Fora do intervalo" deveria existir.
select *
from dev_marts.ici_indicadores
where valor < 0 or valor > 1 or classificacao = 'Fora do intervalo';
