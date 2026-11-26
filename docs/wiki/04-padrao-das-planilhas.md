# Padrão das planilhas

Regras para as **áreas que enviam as planilhas**. O processamento é
automático: cada aba de cada arquivo vira uma tabela, e as regras de cálculo
procuram as colunas **pelo nome**. Planilha fora do padrão quebra o ciclo ou,
pior, gera número errado sem aviso.

## Regras

1. **Mesmo arquivo, mesmas abas, mesmos cabeçalhos de um ano para o outro.** Para acrescentar ou mudar algo, avise a equipe de dados **antes** de enviar.
2. **Uma linha por município** (ou por município e ano, nas séries históricas), com o **código IBGE** numa coluna própria (`Código IBGE`, 6 ou 7 dígitos, sempre o mesmo padrão dentro da mesma aba).
3. **Sem linhas de total, subtotal ou percentual** misturadas aos dados. Os totais estadual e nacional são calculados a partir dos municípios.
4. **Sem células mescladas, títulos acima do cabeçalho ou notas no meio da tabela.** O cabeçalho fica na linha 1 e os dados começam na linha 2.
5. **Números como número**, sem texto ("15 pessoas"), sem `%` digitado e sem separador de milhar como texto.
6. **Dado suprimido ou inexistente:** use `-` (o processamento trata como "sem dado"), nunca texto livre como "n/d" ou "sem informação".
7. **Ano de referência** numa coluna (`Ano de referência`) sempre que a aba misturar anos.
8. **Abas auxiliares** (tabelas dinâmicas, cálculos, legendas): avise quais são para que fiquem de fora da ingestão.
9. **Nomes de arquivo** sem caracteres especiais além de acentos comuns. O padrão é `<TEMA>_<Assunto>_<Fonte>_<período>.xlsx`, ex.: `PSR_Perfil_CadÚnico_dez_2024.xlsx`.

## Ao enviar, informe

- Ano de referência de cada planilha.
- O que mudou em relação ao ano anterior (abas, colunas, indicadores, correções).
- Os **valores de conferência** do ano (planilha de cálculo ou relatório aprovado), que a equipe de dados usa para validar os indicadores.
