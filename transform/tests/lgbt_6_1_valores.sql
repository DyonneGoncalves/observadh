-- Valida a seção 6.1 (nível nacional) — os mesmos números do antigo mart
-- largo lgbt_relatorio_nacional, conferidos na primeira execução real
-- do piloto contra a planilha de cálculo da equipe.

with esperado (indicador, valor) as (
    values
        ('vitimas_paefi',                              1517.0),
        ('pct_creas_nao_atende_orientacao',              60.60),
        ('pct_creas_nao_atende_identidade',              69.61),
        ('pct_centros_pop_atenderam_lgbt',            97.25),
        -- Acolhimento: a aba ingerida tinha 897 linhas 100% duplicadas
        -- (stg_lgbt_unidades_acolhimento faz `select distinct`). Pós-dedup:
        -- 6.568 unidades / 492 com pessoas trans / 1.124 pessoas trans acolhidas.
        -- Referência da equipe (conta NU_IDENTIFICADOR_UNIDADE, coluna ausente
        -- nesta aba): 6.538 / 485 / 1.126. Gap residual ~0,5% — some quando
        -- a aba com o identificador da unidade chegar.
        ('unidades_acolhimento_total',                 6568.0),
        ('pct_unidades_acolhimento_com_pessoas_trans',    7.49)
),

obtido as (
    select indicador, valor
    from {{ ref('lgbt_indicadores') }}
    where secao = '6.1' and nivel = 'nacional'
)

select e.indicador, e.valor as valor_esperado, o.valor as valor_obtido
from esperado e
left join obtido o on o.indicador = e.indicador
where o.valor is null or abs(o.valor - e.valor) > 0.01
