# Catálogo de indicadores — LGBTQIA+

Guia de trabalho que liga cada **seção do relatório** à sua **fórmula**, à **aba do Excel** de
origem, à **tabela `raw`** já ingerida e ao **modelo dbt** que a produz (ou "a fazer").

Fonte de verdade: os 6 documentos nesta pasta.

| Documento | Papel |
|---|---|
| `Cálculo_Indicadores_LGBTQIA+_Nacional_V2.docx` | Especificação dos cálculos — nível **Nacional** (Brasil) |
| `Cálculo_Indicadores_LGBTQIA+_Estadual_V2.docx` | Especificação dos cálculos — nível **Estadual** (por UF) |
| `Cálculo_Indicadores_LGBTQIA+_Municipal_V2.docx` | Especificação dos cálculos — nível **Municipal** |
| `LGBTQIA - TEXTO BASE_FILTRO NACIONAL_V3.docx` | Template da narrativa do relatório (prosa com lacunas) — Nacional |
| `LGBTQIA - TEXTO BASE_FILTRO ESTADUAL_V3.docx` | Idem — Estadual |
| `LGBTQIA - TEXTO BASE_FILTRO MUNICIPAL_V3.docx` | Idem — Municipal |

Os números **`X` / `X.Y`** são o **sumário do relatório**: `X` = seção, `X.Y` = subseção.
O relatório é gerado nos 3 níveis geográficos; nem toda seção existe em todos (ver coluna N/E/M
abaixo — **N**acional, **E**stadual, **M**unicipal).

---

## 1. Mapa de fontes — aba do Excel → tabela `raw`

Nome da tabela = `lgbt_<planilha>_<aba>`, onde `<planilha>` é a abreviação definida em
`ingestion/temas/lgbtqia_plus_config.yml` (`prefixos_planilha`) e `<aba>` é o nome **inteiro**
da aba, só normalizado. Reconferir após nova carga com
`python ingestion/ingest.py --tema lgbtqia_plus --ano <ano> --dry-run`.

### Assistência social — `lgbt_assist_social_*`
(`LGBTQIA_Assistência social_RMA_Censo SUAS_2017_2024.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| CRAS - Temas abordados | `lgbt_assist_social_cras_temas_abordados` |
| Centros de Convivência - Temas | `lgbt_assist_social_centros_de_convivencia_temas` |
| Série atendimentos PAEFI | `lgbt_assist_social_serie_atendimentos_paefi` |
| Atendim CREAS discri orient sex | `lgbt_assist_social_atendim_creas_discri_orient_sex` |
| Atendim CREAS discri ident gên | `lgbt_assist_social_atendim_creas_discri_ident_gen` |
| Centros Pop | `lgbt_assist_social_centros_pop` |
| Unidades de Acolhimento 2024 | `lgbt_assist_social_unidades_de_acolhimento_2024` |
| dLocalizacao | *(não ingerida — vira seed `dim_municipio`)* |

### Perfil / Registro Civil — `lgbt_perfil_pns_est_reg_civil_*`
(`LGBTQIA_Perfil_PNS_Estatísticas Registro Civil_2019_2013_2023_V2.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Pessoas_Orientacao_Sexo_Total | `lgbt_perfil_pns_est_reg_civil_pessoas_orientacao_sexo_total` |
| Pessoas_Faixa_Etaria | `lgbt_perfil_pns_est_reg_civil_pessoas_faixa_etaria` |
| Pessoas_Cor_ou_Raça | `lgbt_perfil_pns_est_reg_civil_pessoas_cor_ou_raca` |
| Pessoas_Area_Localidade | `lgbt_perfil_pns_est_reg_civil_pessoas_area_localidade` |
| Pessoas_Estado_civil | `lgbt_perfil_pns_est_reg_civil_pessoas_estado_civil` |
| Natureza_Jurídica_União | `lgbt_perfil_pns_est_reg_civil_natureza_juridica_uniao` |
| Casamento_Mesmo_Sexo_Ano | `lgbt_perfil_pns_est_reg_civil_casamento_mesmo_sexo_ano` |
| Total_Casamentos_UF | `lgbt_perfil_pns_est_reg_civil_total_casamentos_uf` |
| Orientação sexual por UF | `lgbt_perfil_pns_est_reg_civil_orientacao_sexual_por_uf` |

### Quantas são — `lgbt_quantas_sao_pns_censo_*`
(`LGBTQIA_Quantas são_PNS_2019_Censo_2010_2022.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Orientação sexual 2019 | `lgbt_quantas_sao_pns_censo_orientacao_sexual_2019` |
| Cônjuges do mesmo sexo 2022 | `lgbt_quantas_sao_pns_censo_conjuges_do_mesmo_sexo_2022` |
| Censo_2010_Munic | `lgbt_quantas_sao_pns_censo_censo_2010_munic` |
| Censo_2010_UF | `lgbt_quantas_sao_pns_censo_censo_2010_uf` |
| Censo_2010_Reg | `lgbt_quantas_sao_pns_censo_censo_2010_reg` |

### Trabalho — `lgbt_trab_pns_*`
(`LGBTQIA_Trabalho_PNS_2019.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Taxa de ocupação por orient sex | `lgbt_trab_pns_taxa_de_ocupacao_por_orient_sex` |
| Renda per capta | `lgbt_trab_pns_renda_per_capta` |

### Educação — `lgbt_educ_pns_saeb_*`
(`LGBTQIA_Educação_PNS_SAEB_2019_2021.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Nível de instrução | `lgbt_educ_pns_saeb_nivel_de_instrucao` |
| Projetos contra homofobia 2019 | `lgbt_educ_pns_saeb_projetos_contra_homofobia_2019` |
| Projetos contra homofobia 2021 | `lgbt_educ_pns_saeb_projetos_contra_homofobia_2021` |
| projeto_homofobia_local 2021 | `lgbt_educ_pns_saeb_projeto_homofobia_local_2021` |

### Saúde / CNES — `lgbt_saude_pns_cnes_*`
(`LGBTQIA_Saúde_PNS_Cnes_2019_2025_V2.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Autoavaliacao_saude_PNS | `lgbt_saude_pns_cnes_autoavaliacao_saude_pns` |
| Atividade_Esportiva_PNS | `lgbt_saude_pns_cnes_atividade_esportiva_pns` |
| Taxa_Depressao_PNS | `lgbt_saude_pns_cnes_taxa_depressao_pns` |
| Estabelecimento_CNES | `lgbt_saude_pns_cnes_estabelecimento_cnes` |

### Violência / ONDH — `lgbt_viol_ondh_*`
(`LGBTQIA_Violência_ONDH_2020_2024.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| ONDH_Serie_Historica_2020_2024 | `lgbt_viol_ondh_ondh_serie_historica_2020_2024` |
| ONDH_Sexo | `lgbt_viol_ondh_ondh_sexo` |
| ONDH_Faixa_Etária | `lgbt_viol_ondh_ondh_faixa_etaria` |
| ONDH_Raca_Cor | `lgbt_viol_ondh_ondh_raca_cor` |
| ONDH_Local | `lgbt_viol_ondh_ondh_local` |
| ONDH_Relação_Suspeito | `lgbt_viol_ondh_ondh_relacao_suspeito` |
| ONDH_Tipo_de_Violação | `lgbt_viol_ondh_ondh_tipo_de_violacao` |
| ONDH_Identidade_Genero | `lgbt_viol_ondh_ondh_identidade_genero` |
| ONDH_Orientacao_Sexual | `lgbt_viol_ondh_ondh_orientacao_sexual` |

### Violência / SINAN — `lgbt_viol_sinan_*`
(`LGBTQIA_Violências_Sinan_2015_2024.xlsx`)

| Aba | Tabela `raw` |
|---|---|
| Notificações_2015_2024_SINAN | `lgbt_viol_sinan_notificacoes_2015_2024_sinan` |
| Interpessoal_Local_Ocorrencia | `lgbt_viol_sinan_interpessoal_local_ocorrencia` |
| Autoprovocada_Local_Ocorrencia | `lgbt_viol_sinan_autoprovocada_local_ocorrencia` |
| Violências_Orientacao_Sexual | `lgbt_viol_sinan_violencias_orientacao_sexual` |
| Violencias_Identidade_Genero | `lgbt_viol_sinan_violencias_identidade_genero` |
| Interpessoal_Sexo_SINAN | `lgbt_viol_sinan_interpessoal_sexo_sinan` |
| Interpessoal_Faixa_Etária_SINAN | `lgbt_viol_sinan_interpessoal_faixa_etaria_sinan` |
| Interpessoal_Cor_ou_Raça | `lgbt_viol_sinan_interpessoal_cor_ou_raca` |
| Interpessoal-Tipos de violência | `lgbt_viol_sinan_interpessoal_tipos_de_violencia` |
| Autoprovocada_Sexo_SINAN | `lgbt_viol_sinan_autoprovocada_sexo_sinan` |
| Autoprovocada_Faixa_Etária | `lgbt_viol_sinan_autoprovocada_faixa_etaria` |
| Autoprovocada_Cor_ou_Raça | `lgbt_viol_sinan_autoprovocada_cor_ou_raca` |
| Interpessoal_Perfil_Agressor | `lgbt_viol_sinan_interpessoal_perfil_agressor` |
| ONDH - Identidade de gênero *(cópia dentro do arquivo SINAN)* | `lgbt_viol_sinan_ondh_identidade_de_genero` |

---

## 2. Catálogo por seção

Legenda **N/E/M**: níveis em que a subseção existe (**N**acional, **E**stadual, **M**unicipal).
"Modelo dbt" = "—" significa **a fazer**.

### 1. População LGBTQIA+ no Brasil — ✅ **MODELADA (formato longo)**

Modelo: `int_lgbtqia_plus_1_populacao`. Validação: `tests/lgbtqia_plus_1_2_valores.sql`.

| `indicador` (slug) | `categoria` | fórmula | N/E/M | esperado (nacional) |
|---|---|---|---|---|
| `pct_populacao_lgbtqia_18_mais` | — | (homossexual + bissexual + outra) / total ×100 (E: soma das 3 colunas de % de `Orientação sexual por UF`) | N E | 1,89% |
| `conjuges_mesmo_sexo_2010` | — | nº absoluto, Censo 2010 (`Censo_2010_Reg` linha Brasil / `Censo_2010_UF`) | N E | 60.035 |
| `conjuges_mesmo_sexo_2022` | — | nº absoluto, Censo 2022 (`Cônjuges do mesmo sexo 2022`; "-" = 0) | N E M | 391.080 |
| `pessoas_uniao_mesmo_sexo_estimativa` | — | cônjuges 2022 × 2 | N | 782.160 |

### 2. Perfil das pessoas LGBTQIA+ — ✅ **MODELADA (2.0–2.4, formato longo)**

Modelo: `int_lgbtqia_plus_2_perfil_pns`. Só nível **NACIONAL** (PNS 2019). Cálculo linha
a linha (categoria da orientação X / total da orientação X). Validação: `tests/lgbtqia_plus_1_2_valores.sql`.

| `indicador` (slug) | `categoria` | Aba Excel | esperado (nacional) |
|---|---|---|---|
| `pct_populacao_por_orientacao` | Heterossexual / Bissexual / … | Pessoas_Orientacao_Sexo_Total | Het 94,75 · Bi 0,68 · Homo 1,15 |
| `pct_orientacao_por_sexo` | `<orientação> / Homens\|Mulheres` | Pessoas_Orientacao_Sexo_Total | Homossexual/Mulheres 43,07 |
| `pct_orientacao_por_faixa_etaria` | `<orientação> / <faixa>` | Pessoas_Faixa_Etaria | Heterossexual/50-59 = 17,33 |
| `pct_orientacao_por_raca_cor` | `<orientação> / <cor>` | Pessoas_Cor_ou_Raça | Bissexual/Parda = 43,24 |
| `pct_orientacao_por_localidade` | `<orientação> / Urbana\|Rural` | Pessoas_Area_Localidade | Homossexual/Urbana = 94,22 |

| Sub | Indicador | Aba Excel | Modelo dbt |
|---|---|---|---|
| 2.5 | Casamentos e uniões | (ver abaixo) | ✅ |
| 2.6 | **População Trans** — percentuais fixos no texto, **sem base de dados** ("Sinalização CGTI") | — | n/a |

> `..._` = prefixo `lgbt_perfil_pns_est_reg_civil_`.

**2.5. Casamentos e uniões** — ✅ **MODELADA (formato longo)**

| `indicador` (slug) | `categoria` | fórmula | N/E/M | `valor_tipo` |
|---|---|---|---|---|
| `casamentos_mesmo_sexo_total_ano` | ano `2013`..`2023` | soma (entre homens + entre mulheres) no recorte/ano | N E M | numero_absoluto |
| `variacao_casamentos_mesmo_sexo_13_23` | — | (total 2023 − total 2013) / total 2013 ×100 | N E M | variacao_percentual |
| `pct_casamentos_mesmo_sexo_por_genero_23` | `Casamentos entre homens` / `... mulheres` | gênero / total do recorte em 2023 ×100 | N E M | percentual |
| `pct_casamentos_lesbohomoafetivos` | — | lesbohomoafetivos / casamentos masc-fem ×100 (Total_Casamentos_UF, ano_ref 2022) | N E | percentual |
| `pct_estado_civil_por_orientacao` | `<orientação> / <estado civil>` | estado civil / total com info da orientação ×100 (PNS 2019) | N | percentual |
| `pct_natureza_juridica_por_orientacao` | `<orientação> / <natureza>` | natureza / total com info da orientação ×100 (PNS 2019) | N | percentual |

Abas → tabelas `raw`: `Casamento_Mesmo_Sexo_Ano` → `..._casamento_mesmo_sexo_ano`;
`Total_Casamentos_UF` → `..._total_casamentos_uf`; `Pessoas_Estado_civil` →
`..._pessoas_estado_civil`; `Natureza_Jurídica_União` → `..._natureza_juridica_uniao`.
Modelos: `stg_lgbtqia_plus_{casamentos_mesmo_sexo, total_casamentos_uf, pessoas_estado_civil,
natureza_juridica_uniao}` → `int_lgbtqia_plus_2_5_{casamentos_registro_civil, perfil_conjugal_pns}`
→ `lgbtqia_plus_indicadores`. Validação: `tests/lgbtqia_plus_2_5_valores.sql`.

Ainda **não modelado** da 2.5: "% de casamentos do mesmo sexo por estado" (indicador
nacional que se sobrepõe a `pct_casamentos_lesbohomoafetivos` e tem denominador ambíguo —
confirmar com a equipe).

> No corpo dos docs Estadual e Municipal a subseção aparece renumerada como **"2.1. Casamentos e uniões"** (o índice mantém 2.5). É a mesma coisa.

### 3. Trabalho e renda — `N` apenas (E e M = "Sem dados")

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|---|
| 3.0 | % total Brasil por orientação sexual, 18+ | Taxa de ocupação por orient sex | `lgbt_trab_pns_taxa_de_ocupacao_por_orient_sex` | — |
| 3.0 | % 18+ por orientação sexual com renda per capita > 5 salários mínimos | Renda per capta | `lgbt_trab_pns_renda_per_capta` | — |
| 3.1 | **Pessoas Trans** — destaque de estudo do Ipea (2025), **sem base de dados** ("Sinalização CGTI") | — | — | n/a |

### 4. Educação — `N E` (M = "Sem dados")

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | N/E | Modelo dbt |
|---|---|---|---|---|---|
| 4.0 | % por orientação sexual e nível de instrução | Nível de instrução | `lgbt_educ_pns_saeb_nivel_de_instrucao` | N | — |
| 4.0 | "O Censo Trans" — destaque **sem base de dados** ("Sinalização CGTI") | — | — | N | n/a |

**4.1. Projetos escolares de enfrentamento à LGBTQIAfobia** — `N E` — ✅ **MODELADA (formato longo)**

| `indicador` (slug) | `categoria` | fórmula | N/E | Valor esperado (nacional) |
|---|---|---|---|---|
| `pct_escolas_com_projeto` | `2019` / `2021` | possui projeto / base ×100. base = "total com informação" (2019) ou "total" (2021) | N E | 28,52 / 22,12 |
| `pct_escolas_com_projeto_uf_maior` | nome da UF | UF com maior % em 2021 | N | Rio Grande do Sul — 29,94 |
| `pct_escolas_com_projeto_uf_menor` | nome da UF | UF com menor % em 2021 | N | Roraima — 9,39 |
| `pct_escolas_com_projeto_localizacao_2021` | `Urbana` / `Rural` | escolas com projeto / total com info ×100 | N E | 24,47 / 14,36 |

Abas → `raw`: `Projetos contra homofobia 2019/2021` → `lgbt_educ_pns_saeb_projetos_contra_homofobia_2019` / `_2021`;
`projeto_homofobia_local 2021` → `lgbt_educ_pns_saeb_projeto_homofobia_local_2021`.
Modelos: `stg_lgbtqia_plus_projetos_homofobia` (+ `_local`) → `int_lgbtqia_plus_4_1_projetos_escolares`
→ `lgbtqia_plus_indicadores`. Validação: `tests/lgbtqia_plus_4_1_valores.sql`.

### 5. Saúde — `N E` (M = "Sem dados")

| Sub | Indicador (resumo) | Aba Excel | Tabela `raw` | N/E | Modelo dbt |
|---|---|---|---|---|---|
| 5.0 | % por tipo de autoavaliação da saúde, por orientação sexual (junta "muito boa+boa", "muito ruim+ruim") | Autoavaliacao_saude_PNS | `lgbt_saude_pns_cnes_autoavaliacao_saude_pns` | N | — |
| 5.0 | % por autoavaliação x atividade esportiva, por orientação sexual | Atividade_Esportiva_PNS | `lgbt_saude_pns_cnes_atividade_esportiva_pns` | N | — |
| 5.0 | % com/sem diagnóstico de depressão, por orientação sexual | Taxa_Depressao_PNS | `lgbt_saude_pns_cnes_taxa_depressao_pns` | N | — |

**5.1. Serviços de saúde para pessoas trans** — `N E` — ✅ **MODELADA (formato longo)**

| Indicador | `indicador` (slug) | `categoria` | N/E | Valor esperado (nacional) |
|---|---|---|---|---|
| Nº total de estabelecimentos | `estabelecimentos_total` | — | N E | 26 |
| Nº de estabelecimentos por tipo de habilitação | `estabelecimentos_por_habilitacao` | `Ambulatorial` / `Hospitalar` / `Ambulatorial/Hospitalar` | N E | 16 / 3 / 7 |
| Nº de UFs com habilitação hospitalar (Hospitalar ou Ambulatorial/Hospitalar) | `estados_com_habilitacao_hospitalar` | — | N | 8 |
| Nº de UFs só com habilitação ambulatorial | `estados_apenas_ambulatorial` | — | N | 7 |
| Nº de UFs sem nenhum serviço | `estados_sem_servico` | — | N | 12 |

Aba `Estabelecimento_CNES` → `lgbt_saude_pns_cnes_estabelecimento_cnes` →
`stg_lgbtqia_plus_estabelecimentos_saude_trans` →
`int_lgbtqia_plus_5_1_servicos_saude_trans` → mart `lgbtqia_plus_indicadores`.
Validação: `tests/lgbtqia_plus_5_1_valores_nacionais.sql` (contra a planilha de cálculo da equipe).

### 6. Assistência social — `N E M`

**6.0 (abre a seção)** — cobertura de CRAS e Centros de Convivência (Serviço de Convivência):

| Indicador (resumo) | Aba Excel | Tabela `raw` | N/E/M | Modelo dbt |
|---|---|---|---|---|
| % de CRAS que abordaram frequentemente orientação sexual/identidade de gênero = abordaram / ofertavam SCFV ×100 (também por UF) | CRAS - Temas abordados | `lgbt_assist_social_cras_temas_abordados` | N E | — |
| % de Centros de Convivência que abordaram o tema = abordaram / total de Centros ×100 (também por UF) | Centros de Convivência - Temas | `lgbt_assist_social_centros_de_convivencia_temas` | N E | — |

**6.1. Proteção social especial** — `N E M` — ✅ **PILOTO IMPLEMENTADO**

| Indicador (resumo) | Aba Excel | Tabela `raw` | Modelo dbt |
|---|---|---|---|
| Nº de vítimas de discriminação por orientação sexual que ingressaram no PAEFI (soma; série 2017–2024 no M) | Série atendimentos PAEFI | `lgbt_assist_social_serie_atendimentos_paefi` | `stg_lgbtqia_plus_paefi` → `int_lgbtqia_plus_paefi_por_municipio` |
| Nº total de CREAS | Atendim CREAS discri orient sex | `lgbt_assist_social_atendim_creas_discri_orient_sex` | `stg_lgbtqia_plus_creas_discriminacao_orientacao` |
| % de CREAS que **não** atendem discriminação por orientação sexual = não atende / total de CREAS ×100 | Atendim CREAS discri orient sex | idem | `int_lgbtqia_plus_creas_orientacao_por_municipio` (valida contra o % da planilha em `tests/`) |
| % de CREAS que **não** atendem discriminação por identidade de gênero = não atende / total de CREAS ×100 | Atendim CREAS discri ident gên | `lgbt_assist_social_atendim_creas_discri_ident_gen` | `int_lgbtqia_plus_creas_identidade_por_municipio` (idem) |
| Nº total de Centros POP | Centros Pop | `lgbt_assist_social_centros_pop` | `stg_lgbtqia_plus_centros_pop` |
| % de Centros POP que atenderam LGBTQIA+ = atenderam / total ×100 | Centros Pop | idem | `int_lgbtqia_plus_centros_pop_por_municipio` |
| % de unidades de acolhimento com pessoas trans/travestis = "possui (Sim)" / "possui (Sim + Não)" ×100 | Unidades de Acolhimento 2024 | `lgbt_assist_social_unidades_de_acolhimento_2024` | `int_lgbtqia_plus_acolhimento_por_municipio` |
| Nº de pessoas trans/travestis acolhidas (soma) | Unidades de Acolhimento 2024 | idem | idem |

Marts: `lgbtqia_plus_relatorio_nacional` / `_estadual` / `_municipal`.

### 7. Violência contra pessoas LGBTQIA+ — `N E M`

**7.0. Notificações de violência (SINAN)** — `N E M` — ✅ **MODELADA (formato longo)**

Modelo: `int_lgbtqia_plus_7_0_violencia_sinan` (macro `sinan_breakdown_percentual`).
Validação: `tests/lgbtqia_plus_7_0_valores.sql`. Dados de perfil são de 2024.

| `indicador` (slug) | `categoria` | fonte | N/E/M | esperado (nacional) |
|---|---|---|---|---|
| `notificacoes_por_ano` / `notificacoes_total_2024` | ano / — | Notificações_2015_2024_SINAN | N E M | 2024 = 22.906 |
| `pct_notificacoes_por_tipo_2024` | Interpessoal / Autoprovocada / Origem desconhecida | idem | N E M | 55,21 / 42,29 / 2,51 |
| `pct_municipios_com_notificacao_2024` | — | idem | N E | 47,56 (N ÷5.570; E ÷ nº de municípios da UF) |
| `pct_viol_interpessoal_por_sexo` · `pct_viol_autoprovocada_por_sexo` | Feminino / Masculino / Indefinido | Interpessoal_Sexo_SINAN · Autoprovocada_Sexo_SINAN | N E M | interp. Fem 66,04 · autop. Fem 61,52 |
| `pct_viol_interpessoal_por_faixa_etaria` · `..._autoprovocada_...` | Até 29 / Crianças e adol. / 18-29 / 30-39 … | Interpessoal_Faixa_Etária_SINAN · Autoprovocada_Faixa_Etária | N E M | interp. até 29 = 57,46 · autop. = 70,83 |
| `pct_viol_interpessoal_por_raca_cor` · `..._autoprovocada_...` | Negra / Branca / Amarela / Indígena | Interpessoal_Cor_ou_Raça · Autoprovocada_Cor_ou_Raça | N E M | interp. Negra 60,02 · autop. 52,30 |
| `pct_viol_interpessoal_por_orientacao_sexual` · `..._autoprovocada_...` | Heterossexual (derivado) / Bissexual / Homossexual / Ignorado / Não se aplica | Violências_Orientacao_Sexual | N E M | interp. Homo 52,27 · Bi 20,46 |
| `pct_viol_interpessoal_por_identidade_genero` · `..._autoprovocada_...` | Travesti / Transexual mulher / Transexual homem / Ignorado / Não se aplica | Violencias_Identidade_Genero | N E M | interp. Trans mulher 25,62 · Travesti 4,80 |

> "Heterossexual" não é coluna nas abas de orientação — é derivado (total − bissexual − homossexual − não se aplica − ignorado), como na planilha.

**Ainda não modelado da 7.0**: local de ocorrência
(`lgbt_viol_sinan_{interpessoal,autoprovocada}_local_ocorrencia`) e perfil do agressor
(`lgbt_viol_sinan_interpessoal_perfil_agressor`). A aba `Interpessoal-Tipos de violência`
foi ingerida mas não tem indicador no catálogo.

**7.1. Denúncias de violações de direitos humanos (ONDH)** — `N E M` — ✅ **MODELADA (formato longo)**

Modelo: `int_lgbtqia_plus_7_1_denuncias_ondh` (usa o macro `ondh_breakdown_percentual`
para as quebras). Validação: `tests/lgbtqia_plus_7_1_valores.sql`.

| `indicador` (slug) | `categoria` | fonte | N/E/M | valor esperado (nacional) |
|---|---|---|---|---|
| `denuncias_por_ano` / `violacoes_por_ano` | ano `2020`..`2024` | ONDH_Serie_Historica | N E M | 2024: 8.176 den. / 48.599 viol. |
| `denuncias_total_2020_2024` | — | idem | N E M | 21.672 |
| `pct_participacao_denuncias_2024` | — | idem | E M | (recorte / 8.176 ×100) |
| `pct_denuncias_por_sexo` | Feminino / Intersexo / Masculino | ONDH_Sexo | N E M | 44,69 / 0,94 / 54,36 (denom exclui "não informado") |
| `pct_denuncias_por_faixa_etaria` | Até 29 / 30-39 / 40-49 / 50-59 / Idosos 60+ | ONDH_Faixa_Etária | N E M | 48,03 / … / 4,04 (denom = soma das 10 faixas) |
| `pct_denuncias_por_raca_cor` | Negra / Branca / Amarela / Indígena | ONDH_Raca_Cor | N E M | 54,98 / 43,37 / 0,50 / 1,14 |
| `pct_denuncias_por_identidade_genero` | 8 categorias | ONDH_Identidade_Genero | N E M | Homem trans 6,85 · Mulher trans 10,95 |
| `pct_denuncias_por_orientacao_sexual` | 6 categorias | ONDH_Orientacao_Sexual | N E M | Homossexual 54,97 · Bissexual 14,51 |
| `pct_denuncias_por_tipo_violacao` | 1 por tipo (~103) | ONDH_Tipo_de_Violação (`total_com_info` = contagem do tipo) | N E M | Tortura Psíquica 12,48 · Constrangimento 10,99 |

**Ainda não modelado da 7.1** (mesma mecânica, listas de colunas longas):
`ONDH_Local` (`lgbt_viol_ondh_ondh_local`, 32 colunas) e `ONDH_Relação_Suspeito`
(`lgbt_viol_ondh_ondh_relacao_suspeito`, 50 colunas). Denúncias com local no exterior
(hash no lugar do código IBGE) são contadas só no nacional.

---

## 3. Situação atual

- ✅ **1 População** — N/E/M (parte), formato longo.
- ✅ **2 Perfil (2.0–2.4)** — N, formato longo.
- ✅ **2.5 Casamentos e uniões** — N/E/M (PNS só N), formato longo.
- ✅ **4.1 Projetos escolares contra LGBTQIAfobia** — N, E, formato longo.
- ✅ **5.1 Serviços de saúde para pessoas trans** — N, E, formato longo.
- ✅ **7.0 Notificações de violência (SINAN)** — N/E/M, formato longo (falta local e perfil do agressor).
- ✅ **7.1 Denúncias de violações de DH (ONDH)** — N/E/M, formato longo (falta local e relação do suspeito).
- ✅ **6.1 Proteção social especial** — N/E/M (piloto). Ainda no **formato largo** (`lgbtqia_plus_relatorio_*`). A migrar para o formato longo.
- ⬜ **3 Trabalho e renda** — só N. Falta modelar.
- ⬜ **2.6 / 3.1 / "Censo Trans"** — sem base de dados ("Sinalização CGTI"), não viram modelo.

### Formato longo — `lgbtqia_plus_indicadores`

Mart único, uma linha por `(nivel, recorte_codigo, secao, indicador, categoria)`:

| coluna | conteúdo |
|---|---|
| `nivel` | `nacional` / `estadual` / `municipal` |
| `recorte_codigo` / `recorte_nome` | `null`/`Brasil` · `codigo_uf`/nome · `cod_ibge`/nome |
| `secao` / `secao_nome` | ex. `5.1` / `Saúde — Serviços de saúde para pessoas trans` |
| `indicador` | slug estável (ex. `estabelecimentos_total`) |
| `categoria` | quebra dentro do indicador (`null` se não houver) |
| `valor` / `valor_tipo` | numérico · `numero_absoluto` / `percentual` / `variacao_pp` |
| `ano_referencia` | |

Views de conveniência: `lgbtqia_plus_indicadores_{nacional,estadual,municipal}`.
Cada (sub)seção é um `int_lgbtqia_plus_<secao>_*` que já devolve nesse formato; o mart só faz `union all`.

## 4. Observações e inconsistências

- **"Sinalização CGTI"** = indicador que fica no relatório como texto fixo, **sem cálculo nem base de dados** (2.6 População Trans; 3.1 Pessoas Trans; "O Censo Trans" em 4). Não vira modelo dbt.
- **Renumeração 2.5 ↔ 2.1**: nos docs Estadual/Municipal a subseção "Casamentos e uniões" aparece como "2.1" no corpo, mas "2.5" no índice. É a mesma subseção.
- **"7. Violência contra pessoas idosas"**: título no índice/corpo dos docs Estadual e Municipal — resíduo de copiar do relatório de Pessoa Idosa. O conteúdo é de LGBTQIA+.
- **Aba "ONDH - Identidade de gênero" dentro do arquivo SINAN**: duplica parte do arquivo ONDH separado. Ingerida como `lgbt_viol_sinan_ondh_identidade_de_genero`. Confirmar com a equipe se é intencional.
- **Nomes de aba divergentes entre "V2" e o citado nos docs**: ex. doc diz "Unidade de Acolhimento 2024" (singular) e "Unidades de Acolhimento 2024" (plural) na mesma página; "Conjuges" vs "Cônjuges". Usar sempre o nome real da aba no arquivo `.xlsx`.
- **Ano de referência**: alguns docs dizem "2024" onde a planilha traz série histórica (PAEFI 2017–2024). O piloto 6.1 usa o ano mais recente por município e deixou TODO para a equipe confirmar se o relatório quer o valor pontual ou a série.
- As 11 inconsistências mencionadas no README vêm deste conjunto de observações + do catálogo original da equipe.
