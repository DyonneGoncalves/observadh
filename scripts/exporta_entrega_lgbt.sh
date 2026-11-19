#!/usr/bin/env bash
# Mantido por compatibilidade: a exportação agora é genérica por tema.
#   scripts/exporta_entrega.sh lgbt [DIR_SAIDA]
# Configuração do LGBTQIA+ em scripts/entrega/lgbt.*
exec "$(dirname "$0")/exporta_entrega.sh" lgbt "$@"
