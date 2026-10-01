-- Queries que alimentam o Filtro_Municipal_V1.docx (relatório municipal do ICI).
-- Troque :municipio_codigo_ibge pelo código IBGE do município (ex.: 3550308 = São Paulo capital).
-- Ver a lista de códigos em transform/seeds/dim_municipio.csv.

-- =====================================================================
-- QUERY 1 — Série histórica por sub-índice (alimenta as 5 tabelas do
-- relatório: uma seção por ICI-DH/CA/LGBTQIA+/PCD/PI, cada uma com uma
-- tabela 2014/2019/2023). Mesma lógica da versão estadual, só troca
-- "média da região" por "média dos ICI municipais do estado".
-- =====================================================================
select
    indice,
    ano_referencia                 as "Ano",
    round(valor, 4)                as "Valor do ICI",
    classificacao                  as "Classificação",
    round(media_nacional, 4)       as "Média nacional",
    round(media_estado, 4)         as "Média dos ICI municipais do estado"
from dev_marts.ici_indicadores_municipal
where municipio_codigo_ibge = :municipio_codigo_ibge
order by
    array_position(array['ici_dh','ici_ca','ici_lgbtqia','ici_pcd','ici_pi'], indice),
    ano_referencia;

-- =====================================================================
-- QUERY 2 — Tabela-resumo final do relatório ("RESUMO DOS ÍNDICES DE
-- CAPACIDADE INSTITUCIONAL NO MUNICÍPIO"): os 5 sub-índices que temos
-- dado lado a lado, fixo no ano de 2023.
-- A linha de ICI-PSR do template (6ª linha da tabela 96 no .docx) NÃO
-- está incluída aqui — ver nota abaixo.
-- =====================================================================
select
    case indice
        when 'ici_dh'       then 'ICI-DH'
        when 'ici_ca'       then 'ICI-CA'
        when 'ici_lgbtqia'  then 'ICI-LGBTQIA+'
        when 'ici_pcd'      then 'ICI-PCD'
        when 'ici_pi'       then 'ICI-PI'
    end                              as "Índice de Capacidade Institucional",
    round(valor, 4)                  as "Resultado do ICI municipal",
    round(media_estado, 4)           as "Média dos ICI municipais do estado",
    round(media_nacional, 4)         as "Média nacional dos ICI municipais"
from dev_marts.ici_indicadores_municipal
where municipio_codigo_ibge = :municipio_codigo_ibge and ano_referencia = 2023
order by array_position(array['ici_dh','ici_ca','ici_lgbtqia','ici_pcd','ici_pi'], indice);

-- =====================================================================
-- Exemplo pronto pra rodar (São Paulo capital, código IBGE 3550308):
-- =====================================================================
select
    indice,
    ano_referencia                 as "Ano",
    round(valor, 4)                as "Valor do ICI",
    classificacao                  as "Classificação",
    round(media_nacional, 4)       as "Média nacional",
    round(media_estado, 4)         as "Média dos ICI municipais do estado"
from dev_marts.ici_indicadores_municipal
where municipio_codigo_ibge = 3550308
order by
    array_position(array['ici_dh','ici_ca','ici_lgbtqia','ici_pcd','ici_pi'], indice),
    ano_referencia;

-- =====================================================================
-- ICI-PSR — NÃO IMPLEMENTADO (ver catálogo, Problema 3: planilha nunca
-- recebida). O relatório municipal tem uma 6ª seção condicional:
--   - Para as 22 capitais que responderam o formulário CGIE/MDHC de
--     ago/2023, mostra uma tabela com o valor 2023 + classificação +
--     média nacional (SEM "média do estado" — o próprio template diz
--     "Não se aplica – apenas capitais" nessa célula da tabela-resumo).
--   - Para todos os outros municípios, mostra um texto fixo dizendo que
--     não há ICI-PSR disponível (sem tabela nenhuma).
-- As 22 capitais citadas no documento: Aracaju, Belém, Belo Horizonte,
-- Boa Vista, Brasília, Campo Grande, Cuiabá, Curitiba, Florianópolis,
-- Fortaleza, João Pessoa, Manaus, Natal, Palmas, Porto Alegre,
-- Porto Velho, Recife, Salvador, São Luís, São Paulo, Teresina, Vitória.
-- (Goiânia, Macapá, Maceió, Rio Branco e Rio de Janeiro foram
-- consultadas mas não responderam.)
-- Enquanto a planilha não chega, a aplicação deve tratar TODO município
-- como "sem ICI-PSR disponível" (a versão de texto fixo do template),
-- mesmo os 22 citados acima — não há como distinguir sem o dado.
-- Quando a planilha chegar, o padrão de implementação é idêntico ao dos
-- outros 5 sub-índices (stg_ici_municipal_psr → entra no int_ici_municipal
-- → aparece em ici_indicadores_municipal com indice = 'ici_psr'), com uma
-- diferença: não existe "média do estado" pro PSR (só 22 municípios no
-- Brasil inteiro têm dado, a maioria dos estados teria 0 ou 1 capital só
-- — grupo de comparação não faz sentido estatístico como está definido
-- pros outros índices).
-- =====================================================================
