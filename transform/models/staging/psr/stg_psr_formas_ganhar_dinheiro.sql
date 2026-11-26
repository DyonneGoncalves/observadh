-- Staging: Formas de ganhar dinheiro (CadÚnico dez/2024; uma pessoa pode informar mais de uma). Grão: município.
-- Sem coluna de ano na aba: fixado em 2024 (var psr_ano_referencia).
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_formas_ganhar_dinheiro') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ var('psr_ano_referencia') }}::int as ano_referencia,
        {{ psr_num('o.construcao_civil') }} as qtd_construcao_civil,
        {{ psr_num('o.guardador_de_carro') }} as qtd_guardador_carro,
        {{ psr_num('o.carregador') }} as qtd_carregador,
        {{ psr_num('o.catador') }} as qtd_catador,
        {{ psr_num('o.servicos_gerais') }} as qtd_servicos_gerais,
        {{ psr_num('o.pedinte') }} as qtd_pedinte,
        {{ psr_num('o.vendas') }} as qtd_vendas,
        {{ psr_num('o.outra_forma') }} as qtd_outra_forma,
        {{ psr_num('o.total_com_info_sobre_formas_de_ganhar_dinheiro_total_de') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
