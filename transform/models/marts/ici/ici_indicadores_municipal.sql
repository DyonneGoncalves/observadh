{{ config(materialized='table') }}

-- Relatório MUNICIPAL — recorte do mart longo ici_indicadores.
select
    recorte_codigo as municipio_codigo_ibge,
    recorte_nome   as municipio_nome,
    uf_codigo,
    uf_sigla,
    indice, ano_referencia, valor, classificacao,
    media_nacional,
    grupo_comparacao_nome as uf_nome,
    media_grupo_comparacao as media_estado
from {{ ref('ici_indicadores') }}
where nivel = 'municipal'
