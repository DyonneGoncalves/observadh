-- Mesma validação de lgbt_valida_pct_creas_orientacao.sql, para a
-- aba de identidade de gênero.

select
    municipio_codigo_ibge,
    municipio_nome,
    pct_creas_nao_atende_identidade as pct_calculado,
    pct_nao_atende_identidade_fonte as pct_fonte
from {{ ref('int_lgbt_creas_identidade_por_municipio') }}
where abs(coalesce(pct_creas_nao_atende_identidade, 0) - coalesce(pct_nao_atende_identidade_fonte, 0)) > 0.5
