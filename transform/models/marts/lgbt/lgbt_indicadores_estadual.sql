{{ config(materialized='view') }}

-- Relatório ESTADUAL — recorte do mart longo lgbt_indicadores.
-- recorte_codigo = codigo_uf, recorte_nome = nome da UF.
select
    recorte_codigo as uf_codigo,
    recorte_nome   as uf_nome,
    secao, secao_nome, indicador, categoria, valor, valor_tipo, ano_referencia
from {{ ref('lgbt_indicadores') }}
where nivel = 'estadual'
