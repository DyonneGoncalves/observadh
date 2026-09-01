-- Intermediate: % de CREAS que não atendem discriminação por identidade de
-- gênero no PAEFI, por município.

select
    municipio_codigo_ibge,
    municipio_nome,
    uf_codigo,
    uf_sigla,
    ano_referencia,
    qtd_total_creas,
    qtd_creas_nao_atende_identidade,
    {{ calcula_percentual('qtd_creas_nao_atende_identidade', 'qtd_total_creas') }} as pct_creas_nao_atende_identidade,
    pct_nao_atende_identidade_fonte
from {{ ref('stg_lgbt_creas_discriminacao_identidade') }}
