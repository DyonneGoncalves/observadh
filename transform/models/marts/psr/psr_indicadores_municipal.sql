{{ config(materialized='table') }}

-- Relatório MUNICIPAL — recorte do mart longo psr_indicadores.
-- recorte_codigo = código IBGE de 7 dígitos, recorte_nome = nome do município.
select
    recorte_codigo as municipio_codigo_ibge,
    recorte_nome   as municipio_nome,
    secao, secao_nome, indicador, categoria, valor, valor_tipo, ano_referencia
from {{ ref('psr_indicadores') }}
where nivel = 'municipal'
