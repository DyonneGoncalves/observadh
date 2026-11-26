# Dados ObservaDH

Documentação da **camada de dados** do Observatório Nacional dos Direitos
Humanos: como as planilhas recebidas das áreas viram os indicadores que a
aplicação usa para montar os relatórios nacional, estadual e municipal.

> **Escopo.** A camada de dados recebe as planilhas, calcula e valida os
> indicadores e entrega tabelas prontas para a aplicação. Páginas, textos e
> gráficos do relatório são responsabilidade do desenvolvimento.

## Comece por aqui

| Página | Para quê |
|---|---|
| [Arquitetura](/Dados-ObservaDH/Arquitetura) | Visão geral do fluxo planilha → indicador → aplicação e das ferramentas usadas |
| [Instalação do ambiente](/Dados-ObservaDH/Instalação-do-ambiente) | Preparar uma máquina para rodar o pipeline (feito uma vez) |
| [Ciclo anual de atualização](/Dados-ObservaDH/Ciclo-anual-de-atualização) | Passo a passo para processar as planilhas de um ano novo, válido para qualquer temática |
| [Padrão das planilhas](/Dados-ObservaDH/Padrão-das-planilhas) | Regras que as áreas devem seguir ao enviar planilhas, para não quebrar o processamento |
| [Entrega para o desenvolvimento](/Dados-ObservaDH/Entrega-para-o-desenvolvimento) | O que é entregue ao desenvolvimento e como é carregado |

## Temáticas

Cada temática tem uma página com as planilhas esperadas, a configuração, as
regras de cálculo, a validação e o checklist do ano seguinte.

| Temática | Situação | Tabelas entregues |
|---|---|---|
| [Pessoas em situação de rua (PSR)](/Dados-ObservaDH/Temáticas/Pessoas-em-situação-de-rua) | Implementada — dados de 2024 | `psr_indicadores_{nacional,estadual,municipal}` |
| LGBTQIA+ | Implementada — página em elaboração | `lgbt_indicadores_{nacional,estadual,municipal}` |
| Índice de Capacidade Institucional (ICI) | Implementada — página em elaboração | `ici_indicadores_{estadual,municipal}` |
| Pessoa idosa (PI), Pessoa com deficiência (PCD) | Próximas temáticas | — |

## Onde estão as coisas

- **Repositório:** `<URL do repositório no git do MDHC>`
- **Documentação técnica de cada temática** (catálogo de indicadores, guia de
  consumo, dicionário): pasta `docs/<temática>/` do repositório.
- **Linhagem e descrição de cada tabela e coluna:** documentação do dbt,
  gerada com `make docs` (abre em http://localhost:8080). Veja
  [Arquitetura](/Dados-ObservaDH/Arquitetura).
