{{ config(materialized='table') }}

-- Relatório NACIONAL — recorte do mart longo lgbt_indicadores.
select
    secao, secao_nome, indicador, categoria, valor, valor_tipo, ano_referencia
from {{ ref('lgbt_indicadores') }}
where nivel = 'nacional'
