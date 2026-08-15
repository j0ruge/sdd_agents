#!/usr/bin/env bash
# Suíte do kit. É bash + markdown, então os "testes" são os sensores do próprio kit:
# sintaxe do runner, contrato dos templates e a máquina de estados dos gates.
#
# Uso: tests/run-all.sh

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fails=0

run() { # run <nome> <comando...>
  printf '\n\033[1m▸ %s\033[0m\n' "$1"; shift
  if "$@"; then :; else printf '\033[31m  ✗ falhou\033[0m\n' >&2; fails=$((fails + 1)); fi
}

run "sintaxe do runner (bash -n)" bash -n "$ROOT/bin/sdd"

# Dentro de um mutante (SDD_MUTANT=1) rodam só os sensores COMPORTAMENTAIS. O shellcheck fica
# de fora porque mutante pego pelo lint não prova nada sobre os gates — a asserção que a
# mutação quer é "o gate percebeu", não "o linter reclamou".
if [ -z "${SDD_MUTANT:-}" ]; then
  if command -v shellcheck >/dev/null 2>&1; then
    run "shellcheck do runner" shellcheck -S warning "$ROOT/bin/sdd"
  else
    printf '\n  (shellcheck ausente — pulado)\n'
  fi
fi

# check-lang lê caminhos (docs/, README.md, agents/) que o sandbox da mutação não copia — dentro
# de um mutante ele falharia por arquivo ausente, não por idioma, e o mutante contaria ponto pelo
# motivo errado. Mesma guarda do shellcheck, pela mesma razão.
[ -n "${SDD_MUTANT:-}" ] || run "idioma: nenhuma prosa PT-BR na superfície do kit" \
  "$ROOT/tests/check-lang.sh"

run "contrato dos templates" "$ROOT/tests/check-templates.sh"
run "máquina de estados dos gates" "$ROOT/tests/check-gates.sh"
run "projeção do dry-run" "$ROOT/tests/check-dry-run.sh"

# Sensor do sensor. Fora da guarda isto seria recursão infinita: cada mutante roda esta mesma
# suíte. `check-mutation.sh` tem a guarda gêmea e morre se nascer com SDD_MUTANT setada.
[ -n "${SDD_MUTANT:-}" ] || run "mutação: a suíte morre quando o runner é sabotado" \
  "$ROOT/tests/check-mutation.sh"

printf '\n'
if [ "$fails" -eq 0 ]; then printf '\033[32m\033[1msuíte verde\033[0m\n'; exit 0; fi
printf '\033[31m\033[1m%d suíte(s) falharam\033[0m\n' "$fails" >&2
exit 1
