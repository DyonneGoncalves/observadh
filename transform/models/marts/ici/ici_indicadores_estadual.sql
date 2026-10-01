{{ config(materialized='table') }}

-- Relatório ESTADUAL — recorte do mart longo ici_indicadores.
select
    recorte_codigo as uf_codigo,
    recorte_nome   as uf_nome,
    uf_sigla,
    indice, ano_referencia, valor, classificacao,
    media_nacional,
    grupo_comparacao_nome as regiao,
    media_grupo_comparacao as media_regiao
from {{ ref('ici_indicadores') }}
where nivel = 'estadual'
