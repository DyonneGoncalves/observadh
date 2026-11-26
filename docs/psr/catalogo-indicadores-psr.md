Catálogo de Indicadores — PSR (Pessoas em Situação de Rua) — Nacional / Estadual / Municipal

> Gerado a partir de `Cálculo Indicadores PSR_v2.docx`, dos textos-base `Texto Base_Filtro {Nacional,Estado,Município}_v1.docx`, das 8 planilhas `PSR_*.xlsx` e dos relatórios em PDF validados pela área (nacional; estados AC, AL, DF, TO; municípios São Paulo e Rio de Janeiro), todos em `docs/psr/referencia/`. Mesmo padrão do LGBTQIA+ e do ICI: ingestão automática → staging → intermediate por seção → mart longo `psr_indicadores` + tabelas por nível. Consumo pela aplicação: `consumo-psr_indicadores.md`. Inventário de indicadores: `dicionario-psr_indicadores.csv`.

---

## 0. Características do tema

- As planilhas chegam **por município** (5.570 linhas, ou 5.570 × ano nas séries históricas), com contagens brutas. Estadual e nacional são **somas dos municípios** e o percentual é calculado depois da soma (nunca média de percentuais). Isso fica concentrado em dois intermediates (`int_psr_municipio_base` → `int_psr_recortes`), de onde saem todas as seções.
- Os textos-base usam placeholders genéricos (`XXXX`, `YYYY`, `Y%`, `ZZZZ`). O mapa "trecho do texto → chave do indicador" está em `consumo-psr_indicadores.md`.
- Ano de referência 2024 (CadÚnico dez/2024, SINAN, ONDH, CNES/Sisab), exceto Centros Pop (Censo SUAS 2023) e população geral por cor e analfabetismo (Censo 2022). Os anos ficam em `vars` do `dbt_project.yml` (`psr_ano_*`) e vão para a coluna `ano_referencia`. No ciclo seguinte, basta atualizar ali.

---

## 1. Planilhas e abas

| Arquivo | Aba | Grão | Usada? |
|---|---|---|---|
| Quantas são (CadÚnico/Censo 2015-2024) | `Série Histórica Cad Único` | município × ano (2015–2024) | ✅ seções 1 e 1.1 |
| | `Distribuição Territorial CadÚni` | município (2024) | ✅ 1.2 (% da população) |
| Perfil (CadÚnico dez/2024) | `Gênero`, `Faixa etária`, `Raça ou cor`, `Existência de Deficiência`, `Tipo de Deficiência` | município | ✅ 2.1–2.4 |
| Violência ONDH (2020-2024) | `Série histc denúncia violação` | município (6 díg.) × ano | ✅ 3 |
| | `Denunciante`, `Tipos de violação`, `Frequência`, `Relação do suspeito com vítima`, `Natureza Jurídica do Suspeito` | município | ingeridas, fora do relatório |
| Violência interpessoal SINAN (2015-2024) | `Série histórica Notifica SINAN` | município (6 díg.) × ano | ✅ 3 |
| | `Viol interpessoal Gênero`, `… Raça cor`, `… Tipo` | município | ✅ 3, 3.1, 3.2 |
| | `Viol interpessoal Local`, `Viol interpessoal Agressor` | município | ingeridas (estão no doc de cálculo 3.2, mas não no relatório) |
| Trabalho e Rendimento (CadÚnico dez/2024) | `Pessoas Ocupadas`, `Funções ocupadas`, `Formas de ganhar dinheiro`, `Rendimento e pobreza` | município | ✅ 4 |
| | `Carteira assinada` | município | ingerida, fora do relatório |
| Saúde (CNES/Sisab 2015-2024) | `Nº eCR`, `Atendimentos eCR` | município × ano | ✅ 5.1 |
| Assistência social (Censo SUAS/RMA/CadÚnico) | `Nº Centros Pop CENSO SUAS` (2017–2023), `Situação atendimento_CadUnico`, `BPC`, `Bolsa Família` | município | ✅ 5.2 |
| | `Apoio à moradia UF e Reg` | tabela dinâmica por região | ignorada na ingestão (não é dado bruto) |
| Educação (CadÚnico dez/2024) | `Não sabem ler e escrever`, `Taxa de Analfabetismo`, `Frequência escolar` | município | ✅ 5.3 |

---

## 2. Particularidades das planilhas (tratadas no staging)

1. **Código de município com 6 ou 7 dígitos**, conforme a fonte: CadÚnico/Censo SUAS usam 7; ONDH e SINAN usam 6. O staging traduz 6 → 7 pela `dim_municipio`. Um teste `not_null` faz o build falhar se um ciclo novo trouxer código fora da dimensão.
2. **ONDH tem uma linha "Ignorado" (código 0)** por ano: denúncias sem município identificado. Ela entra **só no total nacional** (por isso o nacional tem 3.389 denúncias e a soma dos municípios dá 3.343).
3. **`Raça ou cor`**: `Total Amarela` e `Total Indígena` (população do Censo) trazem `'-'` (supressão do IBGE) em 575 e 745 municípios. No municipal o % daquela cor fica `NULL` (sem dado); nas somas estadual e nacional, conta 0. A aba também tem linhas de soma sem código no rodapé, descartadas.
4. **`Nº eCR`** traz `'-'` para "sem equipe" (= 0). `Tipo de Deficiência` tem linhas `TOTAL`/`PERCENT` no rodapé, descartadas.
5. `Série Histórica Cad Único` traz o ano como texto; cabeçalhos têm espaços sobrando. A ingestão normaliza os nomes e o staging converte os tipos.
6. Abas sem coluna de ano (`Formas de ganhar dinheiro`, `Rendimento e pobreza`): ano = `psr_ano_referencia`.
7. Os nomes de arquivo chegaram com acentuação corrompida (`Assistˆncia`, `Educa‡Ćo`, `Sa｣de`). Foram renomeados com a grafia correta em `ingestion/input/psr/<ano>/`, e `psr_config.yml` usa esses nomes.

---

## 3. Indicadores

Inventário completo (48 indicadores, com categorias e níveis) em `dicionario-psr_indicadores.csv`. Regras principais:

| Seção | Indicador | Regra |
|---|---|---|
| 1 | `qtd_psr` | Σ PSR no CadÚnico, dez/2024 |
| 1.1 | `qtd_psr_por_ano` | Σ por ano (2015–2024) |
| 1.2 | `pct_psr_sobre_total_nacional` | PSR do recorte / PSR Brasil |
| 1.2 | `pct_psr_sobre_populacao` | PSR / população IBGE 2024 |
| 1.2 | `qtd_municipios_com_psr` | municípios com PSR > 0 (2015 e 2024) |
| 1.2 | `uf_maior_concentracao_psr_{1,2,3}`, `uf_maior_proporcao_psr` | ranking das UFs por PSR e por PSR/população |
| 2.1 | `pct_psr_por_genero` | gênero / total com informação |
| 2.2 | `qtd_` / `pct_psr_por_faixa_etaria` | faixa / total com informação de idade |
| 2.3 | `pct_psr_por_raca_cor`, `pct_populacao_por_raca_cor` | cor / total com informação (PSR: CadÚnico 2024; população: Censo 2022) |
| 2.4 | `pct_psr_com_deficiencia`, `pct_psr_por_tipo_deficiencia`, `tipo_deficiencia_principal_{1,2,3}` | / total com informação sobre deficiência; categorias originais da planilha |
| 3 | `qtd_denuncias_ondh`, `qtd_notificacoes_sinan`, `pct_notificacoes_viol_interpessoal`, `tipo_violencia_principal` | base do % do tipo principal: ver 5.1 |
| 3.1 | `pct_vitimas_por_genero`, `pct_vitimas_por_raca_cor`, `pct_vitimas_negras`, `pct_psr_negras` | negras = preta + parda |
| 3.2 | `pct_viol_interpessoal_por_tipo` | tipo / notificações com resposta de tipo (doc de cálculo) |
| 4 | `pct_psr_por_ocupacao`, `pct_ocupadas_por_vinculo` | formal = empregado e doméstico com carteira + militar/servidor + estagiário + aprendiz; sem vínculo = conta própria + temporário rural + empregado e doméstico sem carteira + não remunerado (empregador fica fora dos dois) |
| 4 | `pct_psr_por_forma_ganhar_dinheiro`, `forma_ganhar_dinheiro_principal` | / quem informou |
| 4 | `pct_psr_abaixo_linha_pobreza`, `pct_psr_extrema_pobreza` | / total com informação de renda (R$ 665 e R$ 209) |
| 5.1 | `qtd_ecr`, `qtd_municipios_com_ecr`, `qtd_atendimentos_ecr` | CNES / Sisab 2024 |
| 5.2 | `qtd_centros_pop`, `qtd_municipios_com_centros_pop` | Censo SUAS 2023 |
| 5.2 | `qtd_psr_atendidas_por_servico` | CRAS, CREAS, instituição governamental e não governamental |
| 5.2 | `qtd_psr_elegiveis_bpc` / `_bolsa_familia`, `pct_elegiveis_*_recebem` | elegíveis = beneficiárias + elegíveis sem benefício |
| 5.3 | `pct_psr_nao_sabem_ler_escrever`, `taxa_analfabetismo_psr`, `taxa_analfabetismo_populacao`, `pct_frequencia_escolar_por_faixa` | taxas sobre a população de 15+ |

Convenções: percentuais com 4 casas, sem arredondar para exibição; denominador zero → `NULL` (sem dado); `categoria_predominante` sem linha quando não há casos e, em empate, vence a primeira na ordem das colunas da planilha.

**Validação** (`transform/tests/psr_valores.sql`): 62 valores conferidos contra os relatórios validados pela área (nacional, Acre, município de São Paulo). Na conferência inicial, feita fora do dbt, todos os números dos 7 PDFs (nacional, AC, AL, DF, TO, São Paulo, Rio de Janeiro) foram reproduzidos a partir das planilhas, exceto 3 barras do gráfico nacional 3.2 (seção 5.2).

---

## 4. Implementação no repositório

```
ingestion/temas/psr_config.yml            planilhas → raw.psr_<planilha>_<aba>
transform/models/staging/psr/             1 stg_psr_* por aba usada: tipagem, '-' → NULL, código 6 → 7 dígitos
transform/models/intermediate/psr/
  int_psr_municipio_base                  1 linha por município, todas as contagens do ano (formato largo)
  int_psr_recortes                        municipal / estadual (soma) / nacional (soma) + contagens de municípios
  int_psr_1_populacao … int_psr_5_politicas_publicas   1 por seção, formato longo (contrato dos int_lgbt_*)
transform/models/marts/psr/
  psr_indicadores                         união das seções (formato longo)
  psr_indicadores_{nacional,estadual,municipal}   recortes por nível (o que vai para a aplicação)
transform/macros/psr_macros.sql           psr_num (texto/'-' → numeric), psr_pct (percentual), psr_secao
transform/tests/psr_valores.sql           valores dos relatórios validados
scripts/entrega/psr.*                     pacote de entrega (scripts/exporta_entrega.sh psr)
docs/psr/                                 este catálogo, consumo, dicionário e referências
```

Ciclo: `make ciclo TEMA=psr ANO=<ano de recebimento>`.

---

## 5. Regras adotadas onde o doc de cálculo e o relatório validado divergem

### 5.1 Base do % do "tipo de violência principal"
O modelo segue o relatório validado. **Estadual**: tipo principal / violência interpessoal (AC: 14/14 = 100,0%). **Municipal** e nacional: tipo principal / total de notificações SINAN, incluindo autoprovocada (São Paulo: 573/699 = 82,0%). O doc de cálculo indica "notificações com resposta de tipo" como base.

### 5.2 Gráfico nacional de tipos de violência (3.2)
O indicador `pct_viol_interpessoal_por_tipo` segue a fórmula do doc de cálculo (base = notificações com resposta de tipo; nacional 5.490). 7 dos 10 tipos coincidem com o PDF nacional. Física (PDF 91,7% × 92,8%), Psicológica/moral (12,0 × 12,2) e Trabalho infantil (1,4 × 1,5) diferem. Uma busca no banco que alimenta a aplicação não encontrou esses valores do PDF em nenhuma tabela: os números do gráfico atual não vêm da camada de dados (provavelmente estão fixos na aplicação). Ao adotar o `psr_indicadores`, o gráfico passa a ler `pct_viol_interpessoal_por_tipo|<tipo>`. **Avisar o dev.**

### 5.3 Deficiência "visual"
O doc de cálculo manda somar Cegueira + Baixa visão como "visual". O relatório validado não soma (3º tipo nacional = **Intelectual, 2,0%**). O modelo segue o relatório e usa as categorias originais da planilha.

### 5.4 Textos-base v1 desatualizados
Não afeta a camada de dados, mas vale avisar quem mantém os `.docx`. Assistência social diz "em 2023" (os dados e o relatório usam 2024). O texto nacional traz números de outra versão dos dados (interpessoal 91%, deficiência ~14%, visual 2,6%; o relatório validado mostra 87,3%, 13,8% e Intelectual 2,0%).

---

## 6. Status

- [x] Material recebido e catalogado (8 planilhas / 38 abas, doc de cálculo v2, 3 textos-base, 7 relatórios validados).
- [x] Regras reproduzidas e conferidas contra os relatórios validados.
- [x] Ingestão, staging, intermediates por seção e marts no padrão LGBTQIA+/ICI.
- [x] Teste de valores, dicionário, guia de consumo e configuração da entrega.
- [ ] Execução do ciclo (`make ciclo TEMA=psr ANO=2026`).
- [ ] Avisar o dev sobre o gráfico 3.2 (seção 5.2).
