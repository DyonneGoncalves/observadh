-- Intermediate: % de CREAS que não atendem discriminação por orientação
-- sexual no PAEFI, por município.
-- Fórmula (calculo_nacional.md, 6.1): (Não atende / Total de CREAS) x 100

select
    municipio_codigo_ibge,
    municipio_nome,
    uf_codigo,
    uf_sigla,
    ano_referencia,
    qtd_total_creas,
    qtd_creas_nao_atende_orientacao,
    {{ calcula_percentual('qtd_creas_nao_atende_orientacao', 'qtd_total_creas') }} as pct_creas_nao_atende_orientacao,
    pct_nao_atende_orientacao_fonte
from {{ ref('stg_lgbtqia_plus_creas_discriminacao_orientacao') }}
