{{ config(materialized='table') }}

-- Relatório ESTADUAL — recorte do mart longo psr_indicadores.
-- recorte_codigo = codigo_uf, recorte_nome = nome da UF.
select
    recorte_codigo as uf_codigo,
    recorte_nome   as uf_nome,
    secao, secao_nome, indicador, categoria, valor, valor_tipo, ano_referencia
from {{ ref('psr_indicadores') }}
where nivel = 'estadual'
