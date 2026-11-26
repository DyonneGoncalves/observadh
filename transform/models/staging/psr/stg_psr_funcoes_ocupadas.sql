-- Staging: Função principal das PSR ocupadas (CadÚnico dez/2024). Grão: município.
-- Só limpeza/tipagem/renome — sem regra de negócio.

with origem as (
    select * from {{ source('raw_psr', 'raw_psr_funcoes_ocupadas') }}
),

tipado as (
    select
        {{ codigo_num('o.cod_ibge') }} as municipio_codigo_ibge,
        {{ codigo_num('o.ano_de_referencia') }} as ano_referencia,
        {{ psr_num('o.trabalhador_por_conta_propria_bico_autonomo') }} as qtd_conta_propria,
        {{ psr_num('o.trabalhador_temporario_em_area_rural') }} as qtd_temporario_rural,
        {{ psr_num('o.empregado_sem_carteira_de_trab_assinada') }} as qtd_empregado_sem_carteira,
        {{ psr_num('o.empregado_com_carteira_de_trab_assinada') }} as qtd_empregado_com_carteira,
        {{ psr_num('o.trabalhador_domestico_sem_carteira_de_trab_assinada') }} as qtd_domestico_sem_carteira,
        {{ psr_num('o.trabalhador_domestico_com_carteira_de_trab_assinada') }} as qtd_domestico_com_carteira,
        {{ psr_num('o.trabalhador_nao_remunerado') }} as qtd_nao_remunerado,
        {{ psr_num('o.militar_ou_servidor_publico') }} as qtd_militar_servidor,
        {{ psr_num('o.empregador') }} as qtd_empregador,
        {{ psr_num('o.estagiario') }} as qtd_estagiario,
        {{ psr_num('o.aprendiz') }} as qtd_aprendiz,
        {{ psr_num('o.total_com_info_de_funcao_principal') }} as qtd_total_com_info,
        o.nm_arquivo_origem,
        o.nm_aba_origem,
        o.dt_importacao
    from origem o
)

select * from tipado
where municipio_codigo_ibge is not null
