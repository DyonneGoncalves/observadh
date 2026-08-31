{{ config(materialized='view') }}

-- Relatório NACIONAL — recorte do mart longo lgbtqia_plus_indicadores.
select
    secao, secao_nome, indicador, categoria, valor, valor_tipo, ano_referencia
from {{ ref('lgbtqia_plus_indicadores') }}
where nivel = 'nacional'
