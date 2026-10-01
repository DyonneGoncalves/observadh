Catálogo de Indicadores — ICI (Índice de Capacidade Institucional) — Nacional / Estadual / Municipal

> Gerado a partir dos documentos `Filtro_{Nacional,Estadual,Municipal}_V1.docx` e das planilhas `V1_ICI_Estadual_RelatoriosObservaDH.xlsx`, `V1_ICI_Municipal_2014_2019_RelatoriosObservaDH.xlsx` e `V1_ICI_Municipal_2023_RelatoriosObservaDH.xlsx` fornecidas pela equipe. Cópia deste documento também vive no projeto Claude, junto com o código — mesmo padrão já usado para o LGBTQIA+ (`docs/lgbt/catalogo-indicadores-lgbt.md`).

---

## 0. Diferença estrutural chave em relação aos outros temas

Nos temas já mapeados (LGBTQIA+, PCD, PI, PSR), a planilha traz **dado bruto de pesquisa** e a regra de cálculo do indicador precisa ser aplicada por nós (fórmulas descritas nos documentos de cálculo). **No ICI isso não acontece.** As seis planilhas-fonte já trazem o **valor final do índice, pronto (0 a 1), por território/ano/subtema** — o cálculo composto (que combina de 4 a 6 indicadores binários/categóricos em um único número) já foi feito a montante, provavelmente pela equipe do IBGE/MDHC, não por nós.

Isso muda o escopo da "camada de processamento" para este tema: não há regra de negócio de cálculo de indicador para implementar (não temos, e aparentemente não precisamos, do dado bruto que originou cada ICI). O trabalho da nossa camada de dados aqui é: ingestão, padronização de schema (que varia bastante entre abas — ver seção 3), derivação das médias nacional/regional que os relatórios pedem (não vêm prontas), e derivação/normalização da classificação Baixa/Moderada/Alta (só vem pronta, e com grafia inconsistente, no arquivo estadual). É um pipeline mais simples de staging→intermediate→marts, sem uma camada de regras de cálculo de indicador propriamente dita.

---

## 1. O que é o ICI

O ICI é um índice composto (0 a 1) que mede a capacidade institucional dos governos estaduais e municipais de promover, proteger e garantir direitos humanos — não um ranking, mas um diagnóstico de estruturas institucionais (existência de órgão gestor, plano, fundo, canal de denúncias, conselho, conferência) por território.

Não é um único índice: existem **6 sub-índices**, um "geral" e cinco por grupo/tema específico:

| Sub-índice | Nº de indicadores componentes (conforme Filtro) | Componentes |
|---|---|---|
| ICI-DH (Direitos Humanos, geral) | 6 | órgão gestor de políticas de DH · plano de DH · fundo de DH · órgão/canal para denúncias · conselho de DH · conferência de DH |
| ICI-CA (Crianças e Adolescentes) | 5 | política/programa · legislação específica · fundo · conselho · conferência |
| ICI-LGBTQIA+ | 4 | política/programa · legislação específica · conselho · conferência (**sem indicador de fundo**, diferente de CA/PCD/PI) |
| ICI-PCD (Pessoas com Deficiência) | 5 | política/programa · legislação específica · fundo · conselho · conferência |
| ICI-PI (Pessoas Idosas) | 5 | política/programa · legislação específica · fundo · conselho · conferência |
| ICI-PSR (Pessoas em Situação de Rua) | 5 | órgão/unidade de gestão · legislação/regulamentação anti-arquitetura hostil · plano municipal específico · política/programa · Comitê Ciamp Rua |

Classificação por faixa (regra documentada na aba `Classificação valores ICI` do arquivo estadual, como fórmula Excel — reproduzida no código como a macro dbt `classifica_ici()`):

```
SE(ICI >= 0 E ICI <= 0,59) → "Baixa capacidade institucional"
SE(ICI >= 0,6 E ICI <= 0,79) → "Moderada capacidade institucional"
SE(ICI >= 0,8) → "Alta capacidade institucional"
(senão → "Fora do intervalo")
```

Fontes: Estadic (estados) e Munic (municípios), pesquisas do IBGE aplicadas a cada 4 anos, complementadas por formulários específicos do MDHC/CGIE para os temas CA, LGBTQIA+, PCD, PI e PSR (Estadic/Munic não cobrem esses recortes diretamente em todos os ciclos).

**Nacional não tem relatório** — `Filtro_Nacional_V1.docx` é só um texto institucional/explicativo para a tela de seleção (explica o que é o ICI e pede para o usuário escolher UF ou município); não há variáveis, tabela ou indicador nacional a preencher. Por isso não existe mart `ici_indicadores_nacional`.

---

## 2. Cobertura por nível geográfico

| Sub-índice | Nacional | Estadual | Municipal |
|---|---|---|---|
| ICI-DH | texto institucional, sem dado | ✅ 2014 / 2019 / 2023 | ✅ 2014 / 2019 / 2023 |
| ICI-CA | texto institucional, sem dado | ✅ 2014 / 2019 / 2023 | ✅ 2014 / 2019 / 2023 |
| ICI-LGBTQIA+ | texto institucional, sem dado | ✅ 2014 / 2019 / 2023 | ✅ 2014 / 2019 / 2023 |
| ICI-PCD | texto institucional, sem dado | ✅ 2014 / 2019 / 2023 | ✅ 2014 / 2019 / 2023 |
| ICI-PI | texto institucional, sem dado | ✅ 2014 / 2019 / 2023 | ✅ 2014 / 2019 / 2023 |
| ICI-PSR | texto institucional, sem dado | ❌ não existe — Estadic nunca teve perguntas sobre PSR (confirmado explicitamente no texto do Filtro_Estadual) | descrito em detalhe no Filtro_Municipal (só 22 capitais responderam a um formulário específico de ago/2023) — **mas nenhuma planilha com esse dado foi enviada** (ver Problema 3). **Não implementado nesta rodada.** |

O `RESUMO DOS ÍNDICES DE CAPACIDADE INSTITUCIONAL` no fim de cada relatório já reflete essa cobertura corretamente: a versão estadual lista só DH/CA/LGBTQIA+/PCD/PI (sem linha de PSR); a versão municipal lista as 6, com PSR marcado como "Não se aplica – apenas capitais" quando o município não é uma das 22.

---

## 3. Estrutura das planilhas fornecidas

### 3.1 Estadual (`V1_ICI_Estadual_RelatoriosObservaDH.xlsx`) — 1 arquivo, 7 abas, 27 UFs

- **`ICI Estadual 2023`** — resumo consolidado: 1 linha por UF (`Cod UF`, `Sigla UF`, `Nome UF`, `PopUF`, `Região`), com o valor 2023 + classificação dos 5 sub-índices lado a lado. Redundante com as 5 abas detalhadas (mesmos valores 2023, checado) — não foi ingerida como tabela própria, só as 5 abas detalhadas.
- **`Estadual ICI {DH,CA,LGBTQIA,PCD,PI} 2023`** (5 abas) — uma aba por sub-índice, com série histórica: valor + classificação para 2014, 2019 e 2023, mesma linha por UF. Fonte dos modelos `stg_ici_estadual_*`.
- **`Classificação valores ICI`** — não é dado, é a especificação da regra de classificação (ver seção 1), com a fórmula Excel original. Não ingerida como raw — reproduzida como macro dbt (`macros/classifica_ici.sql`), para não depender de uma tabela de configuração à parte.
- Todas as 27 UFs presentes em todas as abas, sem nenhum valor nulo (checado programaticamente).

### 3.2 Municipal — 2 arquivos, porque o layout mudou entre ciclos de coleta

- **`V1_ICI_Municipal_2014_2019_RelatoriosObservaDH.xlsx`** — 10 abas: um sub-índice × ano por aba. Cada aba tem 5.570 linhas (uma por município) e só o valor daquele ano específico.
- **`V1_ICI_Municipal_2023_RelatoriosObservaDH.xlsx`** — 5 abas, uma por sub-índice, só com o valor 2023.
- **Chave de junção `CodMun`/`Cod Munic` é confiável**: os 5.570 códigos do arquivo 2014/2019 batem exatamente com os 5.570 do arquivo 2023 (checado — zero código presente em um e ausente no outro).
- **Nenhuma aba municipal tem coluna de classificação** — só o valor numérico do ICI. Derivada no `intermediate` com a mesma macro `classifica_ici()` usada no estadual (fonte única da regra, sem duplicar string).
- 5.570 linhas, sem nenhum valor nulo em nenhuma das 15 abas municipais (checado programaticamente, coluna a coluna).
- **UF/Região do município**: o código `cod_uf` é a única coluna geográfica confiável em todas as abas (sempre numérico, sempre presente); `UF`/`Região` como texto variam de formato entre abas e anos (sigla vs. nome por extenso, com/sem prefixo numérico — ver Problema 5). Por isso os modelos `intermediate` ignoram essas colunas de texto e obtêm sigla/nome/região por join com o seed `dim_uf` a partir de `cod_uf`.

### 3.3 O que os relatórios pedem que não vem pronto em nenhuma planilha

As tabelas de série histórica em ambos os relatórios (`Filtro_Estadual`/`Filtro_Municipal`) têm 4 colunas: **valor do ICI · Classificação · Média nacional · Média da região do estado** (estadual) ou **Média dos ICI municipais do estado** (municipal). Só a primeira coluna existe pronta nas planilhas — as duas médias e a classificação (no municipal) são calculadas nos modelos `int_ici_estadual`/`int_ici_municipal`, e o nível de agrupamento do "par" muda por nível geográfico:

- **Estadual**: compara cada UF com a **Região** (5 grupos: Norte/Nordeste/Sudeste/Sul/Centro-Oeste).
- **Municipal**: compara cada município com o **Estado/UF** (27 grupos), não com a região.
- Em nenhum lugar dos documentos está especificado se essas médias são simples (uma UF/município = um voto) ou ponderadas por população — ver Problema 10. **Implementado como média simples (`avg`)** por ora; isolado em uma única CTE (`medias`) em cada `intermediate`, fácil de trocar por uma média ponderada por população quando a equipe decidir.

---

## 4. Variáveis de template (mail-merge)

Os dois documentos com relatório real (`Filtro_Estadual_V1`, `Filtro_Municipal_V1`) usam placeholders genéricos (`XXXX`, `Xxx (número)`, `XXXX (texto)`) em vez de nomes semânticos — mesmo padrão já visto no tema LGBTQIA+. `Filtro_Nacional_V1` não é um template (não tem variável nenhuma — é texto institucional fixo).

Estrutura do relatório é idêntica nos dois níveis (estadual/municipal), só muda o texto de abertura e a presença/ausência da seção ICI-PSR:
1. Explicação do que é o ICI + tabela de faixas de classificação (texto fixo, idêntico nos dois documentos)
2. Uma seção por sub-índice (DH, CA, LGBTQIA+, PCD, PI, [PSR só no municipal]): lista dos indicadores componentes (texto fixo) + 1 frase de contexto nacional (texto fixo, com alguns números fixos tipo "105 municípios" — não são variáveis, ver Problema 11) + tabela de série histórica (variável) + fonte (texto fixo)
3. Tabela-resumo final com os N sub-índices lado a lado, ano 2023
4. Bloco fixo "Fontes de informações que compõem o ICI"

O mart `ici_indicadores` (ver `docs/ici/consumo-ici_indicadores.md`) cobre o item 2 (série histórica + médias + classificação) e o item 3 (basta filtrar `ano_referencia = 2023`). As queries prontas pra esses dois formatos, uma por nível, estão em `docs/ici/query-relatorio-estadual.sql` e `docs/ici/query-relatorio-municipal.sql`.

---

## 5. Problemas encontrados nos documentos-fonte (precisam de decisão humana antes de fechar o tema)

1. **`Filtro_Municipal_V1.docx`, seção ICI-DH**: o parágrafo de contexto menciona anos **"2009, 2014 e 2019"**, mas a tabela de série histórica logo abaixo tem colunas **2014 / 2019 / 2023**. Não existe nenhuma planilha com dado de 2009 no pacote recebido — texto desatualizado.
2. **Mesmo documento, seções ICI-CA/LGBTQIA+/PCD/PI**: o parágrafo de contexto de cada uma menciona só **"2014 e 2019"**, mas a tabela logo abaixo tem 2014/2019/2023. Mesma causa do Problema 1, repetido em 4 seções.
3. **ICI-PSR municipal está descrito em detalhe no `Filtro_Municipal_V1.docx`** (5 indicadores, 22 capitais, formulário CGIE/MDHC de agosto/2023) **— mas nenhuma das 3 planilhas enviadas contém essa aba/esses dados.** Bloqueante — não implementado nesta rodada, precisa ser solicitado à equipe. Detalhes relevantes pra quando a planilha chegar:
   - A seção é **condicional**: o template tem uma versão com tabela (só pras 22 capitais que responderam: Aracaju, Belém, Belo Horizonte, Boa Vista, Brasília, Campo Grande, Cuiabá, Curitiba, Florianópolis, Fortaleza, João Pessoa, Manaus, Natal, Palmas, Porto Alegre, Porto Velho, Recife, Salvador, São Luís, São Paulo, Teresina, Vitória) e uma versão só de texto fixo ("não há ICI-PSR disponível") pra todos os outros municípios — inclusive os 5 que foram consultados mas não responderam (Goiânia, Macapá, Maceió, Rio Branco, Rio de Janeiro).
   - A tabela do ICI-PSR (quando existe) só tem **3 colunas** (valor, classificação, média nacional) — **sem** "média do estado", diferente dos outros 5 sub-índices. Faz sentido: com só 22 municípios no Brasil inteiro, a maioria dos estados teria 0 ou 1 capital no grupo — média por estado não é estatisticamente útil aqui.
   - Na tabela-resumo final, a linha do ICI-PSR tem a célula de "média do estado" com o texto fixo "Não se aplica – apenas capitais" (não é um `XXXX` calculável).
   - Enquanto a planilha não chega, a aplicação deve tratar **todo** município com a versão "sem dado disponível", mesmo os 22 citados acima — não dá pra saber quais são sem o dado real carregado.
4. **ICI-PSR estadual**: inexistente por definição (Estadic nunca incluiu perguntas sobre PSR), não por lacuna de dado. Não é um problema a resolver.
5. **Nomenclatura e formato das colunas geográficas mudam entre as 10 abas do arquivo municipal 2014/2019**, sem schema único (sigla vs. nome por extenso da UF; região com/sem prefixo numérico; `   Região` com espaços sobrando no nome da própria coluna). **Mitigado no código**: os modelos `intermediate` usam só `cod_uf` (sempre numérico e presente) e o seed `dim_uf` para obter sigla/nome/região canônicos — as colunas de texto da origem são descartadas.
6. **O arquivo municipal 2023 renomeou praticamente todas as colunas** em relação ao 2014/2019 (`CodMun`→`Cod Munic`, `UF`→`Uf`, `NOME MUNIC`→`Desc Mun`, `POP EST`→`PopMun`, `CLASSE POP`→`Faixa_pop`, `REGIAO`/`Região`→`Regiao`). Os buckets de `CLASSE POP`/`Faixa_pop` usam os mesmos 7 valores nos dois arquivos — só remapeamento de nome de coluna, já tratado nos `stg_ici_municipal_*`.
7. **A coluna de classificação, no arquivo estadual, tem 9 grafias distintas** para as mesmas 3 categorias (espaço comum e não-quebrável `\xa0` sobrando de forma inconsistente). **Resolvido no código**: a classificação de origem é descartada nos modelos `stg_ici_estadual_*` e recalculada pela macro `classifica_ici()` a partir do valor numérico — uma única fonte de verdade para as 3 categorias, sem variação de grafia.
8. A aba `Municipal ICI-LGBTQIA+ - 2014` tem 6 colunas extras totalmente vazias — resíduo do Excel, sem impacto (o `ingest.py` já descarta colunas/linhas totalmente vazias — ver `tratar_dataframe`).
9. A aba `Estadual ICI DH 2023` tem uma linha extra totalmente vazia — mesmo tipo de resíduo do Problema 8, também descartado automaticamente pela ingestão.
10. **Não está especificado** se "Média nacional" e "Média da região/estado" são simples ou ponderadas por população — implementado como média simples por ora (ver seção 3.3). Pendente de confirmação.
11. Números fixos citados no texto de contexto de cada sub-índice (ex.: "105 municípios com ICI-CA máximo") não são variáveis de template — ficam desatualizados a cada novo ciclo, do mesmo jeito que os Problemas 1 e 2. Fora do escopo da camada de dados, mas vale sinalizar a quem mantém os `Filtro_*.docx`.
12. Convenção de nome das abas difere entre os arquivos (com/sem `+`, com/sem hífen) — cosmético, sem impacto no código porque o mapeamento aba→tabela usa o nome completo de cada aba explicitamente na ingestão, não regex.
13. Havia uma tabela extra gerada na ingestão real, `raw.ici_estadual_ici_estadual_2023` (vinda da aba-resumo `ICI Estadual 2023`, ver 3.1) — não é consumida por nenhum model, fica ociosa no schema `raw`. Sem ação necessária.

---

## 6. Status da implementação

- [x] **Catálogo de indicadores** (este documento).
- [x] **Ingestão configurada** (`ingestion/temas/ici_config.yml`) e planilhas copiadas para `ingestion/input/ici/2026/`. Validada primeiro em modo `--dry-run`, depois **executada de verdade contra o Postgres do projeto** — `python ingestion/ingest.py --tema ici --ano 2026` populou as 20 tabelas em `raw` com 83.712 linhas, batendo exatamente com o esperado (27 UFs × 5 índices no estadual; 5.570 municípios × 15 combinações ano/índice).
- [x] **Staging** — 1 modelo por sub-índice e nível (`stg_ici_estadual_{dh,ca,lgbtqia,pcd,pi}`, reshape wide→long das 3 colunas de ano; `stg_ici_municipal_{dh,ca,lgbtqia,pcd,pi}`, union dos 3 anos + renomeio de coluna por ano/arquivo).
- [x] **Intermediate** — `int_ici_estadual` e `int_ici_municipal`: juntam os 5 sub-índices, fazem join com `dim_uf`/`dim_municipio`, calculam média nacional e média do grupo de comparação (região para estadual, UF para municipal) e a classificação (macro `classifica_ici`).
- [x] **Mart** — `ici_indicadores` (união dos dois intermediates, formato longo) + views `ici_indicadores_estadual` / `ici_indicadores_municipal`.
- [x] **Testes** — estrutura (contagem de linhas por nível/sub-índice/ano: 27 UFs, 5.570 municípios) e `accepted_values`/`not_null` no schema.yml.
- [x] **Executado de ponta a ponta contra o Postgres real do projeto** (01/10/2026): `dbt build --select tag:ici` rodou os 12 models de staging/intermediate + os 3 objetos de mart + os 18 testes — **33/33 PASS, 0 erro**. Resultado: `ici_indicadores` com 83.955 linhas, `ici_indicadores_estadual` com 405 linhas (27 UFs × 5 índices × 3 anos) e `ici_indicadores_municipal` com 83.550 linhas (5.570 municípios × 5 índices × 3 anos) — todos os números batendo com o esperado. Teste de cobertura (`ici_cobertura_valores`) e de unicidade (`nivel`/`recorte_codigo`/`indice`/`ano_referencia`) passaram, confirmando que nenhum território caiu fora dos joins com `dim_uf`/`dim_municipio` e que não há duplicatas.
- [x] **Queries de consumo validadas contra dado real** — `docs/ici/query-relatorio-estadual.sql` e `docs/ici/query-relatorio-municipal.sql`, uma série histórica + uma tabela-resumo por nível, com nomes de coluna já no padrão dos cabeçalhos do `Filtro_*`. Rodadas pra Acre (uf_codigo 12): valores, classificações e médias batem com o relatório original (ICI-DH 2023 = 0,06 → "Baixa capacidade institucional"), e os valores de 2023 da série histórica batem exatamente com os da tabela-resumo.
- [ ] **ICI-PSR municipal** — não implementado (Problema 3, planilha não recebida).
- [ ] **Decisão sobre peso das médias** (Problema 10) — implementado como média simples, pendente de confirmação.
