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
if command -v shellcheck >/dev/null 2>&1; then
  run "shellcheck do runner" shellcheck -S warning "$ROOT/bin/sdd"
else
  printf '\n  (shellcheck ausente — pulado)\n'
fi
run "contrato dos templates" "$ROOT/tests/check-templates.sh"
run "máquina de estados dos gates" "$ROOT/tests/check-gates.sh"

printf '\n'
if [ "$fails" -eq 0 ]; then printf '\033[32m\033[1msuíte verde\033[0m\n'; exit 0; fi
printf '\033[31m\033[1m%d suíte(s) falharam\033[0m\n' "$fails" >&2
exit 1
