-- Validação: nosso cálculo de % (via macro calcula_percentual) precisa bater
-- com o percentual que a própria planilha já trazia pré-calculado por
-- município (golden value). Teste falha se algum município divergir em mais
-- de 0,5 ponto percentual (tolerância para arredondamento da fonte).

select
    municipio_codigo_ibge,
    municipio_nome,
    pct_creas_nao_atende_orientacao as pct_calculado,
    pct_nao_atende_orientacao_fonte as pct_fonte
from {{ ref('int_lgbtqia_plus_creas_orientacao_por_municipio') }}
where abs(coalesce(pct_creas_nao_atende_orientacao, 0) - coalesce(pct_nao_atende_orientacao_fonte, 0)) > 0.5
