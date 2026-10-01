-- Queries que alimentam o Filtro_Estadual_V1.docx (relatório estadual do ICI).
-- Troque :uf_codigo pelo código IBGE da UF desejada (ex.: 12 = Acre, 35 = São Paulo).
-- Ver a lista de códigos em transform/seeds/dim_uf.csv.

-- =====================================================================
-- QUERY 1 — Série histórica por sub-índice (alimenta as 5 tabelas do
-- relatório: uma seção por ICI-DH/CA/LGBTQIA+/PCD/PI, cada uma com uma
-- tabela 2014/2019/2023). Uma única query traz os 15 valores (5 índices
-- x 3 anos); a aplicação agrupa por `indice` pra montar cada tabela.
-- Não existe ICI-PSR estadual (confirmado no próprio Filtro_Estadual:
-- a Estadic nunca incluiu perguntas sobre PSR) — por isso não aparece
-- aqui, e não é erro/lacuna.
-- =====================================================================
select
    indice,
    ano_referencia                 as "Ano",
    round(valor, 4)                as "Valor do ICI",
    classificacao                  as "Classificação",
    round(media_nacional, 4)       as "Média nacional",
    round(media_regiao, 4)         as "Média da região do estado"
from dev_marts.ici_indicadores_estadual
where uf_codigo = :uf_codigo
order by
    array_position(array['ici_dh','ici_ca','ici_lgbtqia','ici_pcd','ici_pi'], indice),
    ano_referencia;

-- =====================================================================
-- QUERY 2 — Tabela-resumo final do relatório ("RESUMO DOS ÍNDICES DE
-- CAPACIDADE INSTITUCIONAL NO ESTADO"): os 5 sub-índices lado a lado,
-- fixo no ano de 2023.
-- =====================================================================
select
    case indice
        when 'ici_dh'       then 'ICI-DH'
        when 'ici_ca'       then 'ICI-CA'
        when 'ici_lgbtqia'  then 'ICI-LGBTQIA+'
        when 'ici_pcd'      then 'ICI-PCD'
        when 'ici_pi'       then 'ICI-PI'
    end                             as "Índice de Capacidade Institucional",
    round(valor, 4)                 as "Resultado do ICI estadual",
    round(media_regiao, 4)          as "Média dos ICI estaduais da mesma região",
    round(media_nacional, 4)        as "Média nacional dos ICI estaduais"
from dev_marts.ici_indicadores_estadual
where uf_codigo = :uf_codigo and ano_referencia = 2023
order by array_position(array['ici_dh','ici_ca','ici_lgbtqia','ici_pcd','ici_pi'], indice);

-- =====================================================================
-- Exemplo pronto pra rodar (Acre, uf_codigo = 12) — sem bind variable,
-- pra testar direto no DBeaver sem precisar configurar parâmetro:
-- =====================================================================
select
    indice,
    ano_referencia                 as "Ano",
    round(valor, 4)                as "Valor do ICI",
    classificacao                  as "Classificação",
    round(media_nacional, 4)       as "Média nacional",
    round(media_regiao, 4)         as "Média da região do estado"
from dev_marts.ici_indicadores_estadual
where uf_codigo = 12
order by
    array_position(array['ici_dh','ici_ca','ici_lgbtqia','ici_pcd','ici_pi'], indice),
    ano_referencia;
