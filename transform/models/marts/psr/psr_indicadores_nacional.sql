{{ config(materialized='table') }}

-- Relatório NACIONAL — recorte do mart longo psr_indicadores.
select
    secao, secao_nome, indicador, categoria, valor, valor_tipo, ano_referencia
from {{ ref('psr_indicadores') }}
where nivel = 'nacional'
