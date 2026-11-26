# Pessoas em situação de rua (PSR)

Roteiro de instalação, configuração e atualização da temática **Pessoas em
situação de rua** na camada de dados do ObservaDH.

| | |
|---|---|
| **Relatórios** | Nacional, estadual (27 UFs) e municipal (5.570 municípios) |
| **Dados atuais** | CadÚnico dez/2024 · SINAN e ONDH 2024 · CNES/Sisab 2024 · Censo SUAS 2023 · Censo Demográfico 2022 |
| **Tabelas entregues** | `psr_indicadores_nacional` · `psr_indicadores_estadual` · `psr_indicadores_municipal` |
| **Indicadores** | 48, em 14 (sub)seções do relatório |
| **Comando do ciclo** | `make ciclo TEMA=psr ANO=<ano de recebimento>` |

> Pré-requisito: ambiente instalado ([Instalação do ambiente](/Relatórios-Observa-DH/Arquitetura-de-Dados/Instalação-do-ambiente)).
> O roteiro geral do ciclo está em [Ciclo anual de atualização](/Relatórios-Observa-DH/Arquitetura-de-Dados/Ciclo-anual-de-atualização).
> Esta página traz o que é **específico do PSR**.

---

## 1. Planilhas esperadas

8 arquivos, colocados em `ingestion/input/psr/<ano>/`:

| Arquivo | Abas usadas | Seções do relatório |
|---|---|---|
| `PSR_Quantas são_CadÚnico_Censo_2015-2024.xlsx` | Série Histórica Cad Único · Distribuição Territorial CadÚni | 1, 1.1, 1.2 |
| `PSR_Perfil_CadÚnico_dez_2024.xlsx` | Gênero · Faixa etária · Raça ou cor · Existência de Deficiência · Tipo de Deficiência | 2.1 a 2.4 |
| `PSR_Violência_ONDH_2020_2024.xlsx` | Série histc denúncia violação | 3 |
| `PSR_Violência interpessoal_Sinan_2015_2024.xlsx` | Série histórica Notifica SINAN · Viol interpessoal Gênero / Raça cor / Tipo | 3, 3.1, 3.2 |
| `PSR_Trabalho e Rendimento_CadÚnico_dez_2024.xlsx` | Pessoas Ocupadas · Funções ocupadas · Formas de ganhar dinheiro · Rendimento e pobreza | 4 |
| `PSR_Saúde_Cnes_Sisab_Sinan_2015_2024.xlsx` | Nº eCR · Atendimentos eCR | 5.1 |
| `PSR_Assistência social_Censo SUAS_RMA_CadÚnico_dez_2017_2024.xlsx` | Nº Centros Pop CENSO SUAS · Situação atendimento_CadUnico · BPC · Bolsa Família | 5.2 |
| `PSR_Educação_CadÚnico_dez_2024.xlsx` | Não sabem ler e escrever · Taxa de Analfabetismo · Frequência escolar | 5.3 |

As demais abas (ONDH: denunciante, tipos de violação etc.; SINAN: local,
agressor; carteira assinada) também são ingeridas e ficam disponíveis no
schema `raw`, mas não entram no relatório. A aba `Apoio à moradia UF e Reg` é
ignorada (é uma tabela dinâmica, não dado bruto).

> **Atenção aos nomes de arquivo.** Planilhas que passam por zip ou e-mail
> podem chegar com acentos corrompidos (ex.: `Assistˆncia`, `Educa‡Ćo`,
> `Sa｣de`). Renomeie com a grafia correta acima antes de rodar. É por esse
> nome que a configuração identifica cada arquivo.

## 2. Configuração

| Arquivo | O que define |
|---|---|
| `ingestion/temas/psr_config.yml` | nome curto de cada planilha (prefixo das tabelas `raw`) e abas ignoradas |
| `transform/dbt_project.yml` → `vars: psr_*` | anos de referência, listas de categorias (faixas etárias, cores, tipos de deficiência e de violência, formas de renda) e os rótulos exibidos |
| `transform/models/staging/psr/_psr__sources.yml` | ligação entre cada tabela `raw` e os modelos |

Anos em uso (`vars`):

| Variável | Valor atual | Usado em |
|---|---|---|
| `psr_ano_referencia` | 2024 | CadÚnico, SINAN, ONDH, eCR (quase todos os indicadores) |
| `psr_ano_inicio_serie` | 2015 | início da série histórica e "municípios com PSR em 2015" |
| `psr_ano_censo_suas` | 2023 | Centros Pop |
| `psr_ano_censo_ibge` | 2022 | população geral por cor e analfabetismo da população |

## 3. Rodar

```bash
make ciclo TEMA=psr ANO=2026
```

Resultado esperado (ciclo de 2024):

- dbt: `Done. PASS=19 WARN=0 ERROR=0` (36 modelos e 19 testes)
- `entrega/psr/<data>/MANIFEST.txt`:

| Tabela | Linhas |
|---|---|
| `psr_indicadores_nacional` | 124 |
| `psr_indicadores_estadual` | 3.267 |
| `psr_indicadores_municipal` | 631.254 |

## 4. Como os indicadores são calculados

- As planilhas trazem contagens **por município**. Estadual e nacional são **somas dos municípios**, e o percentual é calculado depois da soma (nunca média de percentuais).
- Fluxo no dbt: `stg_psr_*` (1 por aba) → `int_psr_municipio_base` (todas as contagens por município) → `int_psr_recortes` (municipal, estadual e nacional) → `int_psr_1_populacao` … `int_psr_5_politicas_publicas` (1 por seção) → `psr_indicadores`.
- Percentuais com 4 casas. Denominador zero → `NULL` ("sem dado", ex.: município sem PSR).
- Lista completa de indicadores, categorias e níveis: `docs/psr/dicionario-psr_indicadores.csv`. Regras detalhadas: `docs/psr/catalogo-indicadores-psr.md`.

Particularidades das planilhas, já tratadas no processamento:

| Situação | Tratamento |
|---|---|
| ONDH e SINAN usam código de município com **6 dígitos** | convertido para 7 pela tabela de municípios (`dim_municipio`) |
| ONDH tem a linha **"Ignorado"** (denúncias sem município) | entra só no total nacional |
| `Raça ou cor`: população do Censo com `-` (supressão do IBGE) | `NULL` no município; conta 0 nas somas estadual e nacional |
| `Nº eCR` com `-` | sem equipe (0) |
| Linhas de total no rodapé de algumas abas | descartadas (não têm código IBGE) |

## 5. Validação

O teste `transform/tests/psr_valores.sql` confere **62 valores de conferência**
validados pela área, nos três níveis (nacional, Acre e município de São Paulo).
Se um valor sair da tolerância (0,06 ponto percentual nos percentuais; exato
nas quantidades), o ciclo para antes de gerar a entrega.

Regras de cálculo adotadas (detalhes no catálogo, seção 5):

| Ponto | Regra adotada |
|---|---|
| % do "tipo de violência principal" | estadual: sobre a violência interpessoal; municipal e nacional: sobre o total de notificações SINAN |
| Tipos de deficiência | categorias originais da planilha, sem agrupar cegueira e baixa visão |
| % por tipo de violência interpessoal (gráfico nacional 3.2) | base = notificações com resposta de tipo |

## 6. Entrega

`entrega/psr/<data>.zip`, conforme [Entrega para o desenvolvimento](/Relatórios-Observa-DH/Arquitetura-de-Dados/Entrega-para-o-desenvolvimento).
O guia `consumo-psr_indicadores.md` (dentro do pacote) mapeia cada trecho do
texto-base do relatório para a chave do indicador.

## 7. Checklist do ano seguinte

- [ ] Receber os 8 arquivos e conferir abas e cabeçalhos com a tabela da seção 1 ([Padrão das planilhas](/Relatórios-Observa-DH/Arquitetura-de-Dados/Padrão-das-planilhas)).
- [ ] Pedir à área os **valores de conferência** do ano (relatório ou planilha de cálculo validados).
- [ ] Criar a branch `psr-<ano>` e a pasta `ingestion/input/psr/<ano>/`. Copiar as planilhas com os nomes corretos e atualizar `psr_config.yml` se os nomes mudaram (ex.: `2015-2024` → `2015-2025`).
- [ ] Atualizar em `transform/dbt_project.yml`: `psr_ano_referencia` e `psr_ano_censo_suas` (e `psr_ano_censo_ibge` só se houver Censo novo).
- [ ] Atualizar os valores esperados em `transform/tests/psr_valores.sql` com os números de conferência do ano.
- [ ] `make dry-run TEMA=psr ANO=<ano>`: conferir se as tabelas batem com `_psr__sources.yml`.
- [ ] `make ciclo TEMA=psr ANO=<ano>`: tudo `PASS`.
- [ ] Conferir as contagens no `MANIFEST.txt` (mesma ordem de grandeza da tabela da seção 3).
- [ ] Commit, push e pull request. Enviar o `.zip` ao desenvolvimento.
- [ ] Atualizar esta página (anos, contagens e qualquer mudança de planilha).
