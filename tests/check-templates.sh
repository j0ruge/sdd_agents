#!/usr/bin/env bash
# Sensor for the template contract.
#
# The templates are not decoration: the runner greps them (the handoff frontmatter, the checkpoint
# table, the mission's PLAN-AUTO gate). If a heading or a key disappears, the matching gate starts
# lying in silence. This test fails first, loudly and cheaply.
#
# NOTE on the regexes below: they are deliberately Portuguese. They assert the contract of
# templates/, which is mission CONTENT in this repo's OUTPUT_LANG (pt-BR), not kit surface. The
# prose of this file is English because the file itself IS kit surface. Both are correct, and the
# split is the whole point of OUTPUT_LANG: a target repo declaring another language gets its
# artifacts in that language, while the kit stays readable to everyone.
#
# Usage: tests/check-templates.sh   (exit 0 = contract intact)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/templates"
fails=0

check() { # check <file> <regex> <description>
  if grep -qE "$2" "$T/$1"; then
    printf '  ok   %s: %s\n' "$1" "$3"
  else
    printf '  FAIL %s: missing %s (regex: %s)\n' "$1" "$3" "$2" >&2
    fails=$((fails + 1))
  fi
}

echo "== templates/missao.md =="
for k in missao titulo data versao branch aprovacao ddd; do
  check missao.md "^${k}:" "frontmatter key '${k}'"
done
check missao.md '^## Problema \(Gemba\)'      "section 'Problema (Gemba)'"
check missao.md '^## Métrica'                 "section 'Métrica'"
check missao.md '^## Resultado esperado'      "section 'Resultado esperado'"
check missao.md '^## Fora de escopo'          "section 'Fora de escopo'"
check missao.md '^## Gate PLAN-AUTO'          "section 'Gate PLAN-AUTO'"
check missao.md '^## Checklist kaizen'        "kaizen checklist"
check missao.md '^## Checklist DDD'           "DDD checklist"
check missao.md '^## Decisões do grill'       "grill decisions"
check missao.md '^## Pendências para o humano' "open questions for the human"
for c in a b c d e; do
  check missao.md "^\| ${c} \|" "PLAN-AUTO criterion '${c}'"
done

echo "== templates/plano.md =="
check plano.md '^## Contexto verificado'      "section 'Contexto verificado'"
check plano.md '^## Arquitetura da mudança'   "section 'Arquitetura da mudança'"
check plano.md '^## Incrementos'              "section 'Incrementos'"
check plano.md '\*\*Check:\*\*'               "per-increment 'Check' field"
check plano.md '\*\*Sensor durável:\*\*'      "per-increment 'Sensor durável' field"
check plano.md '^## Riscos e não-feitos'      "section 'Riscos e não-feitos'"
check plano.md '^## Verificação end-to-end'   "section 'Verificação end-to-end'"

echo "== templates/checkpoint.md =="
check checkpoint.md '^\| ID \| Incremento \| Check \(comando → esperado\) \| Status \| Commit \|' \
  "exact table header (the runner parses by column position)"
check checkpoint.md 'pending'                 "status token 'pending'"
check checkpoint.md '`done`'                  "status token 'done'"
check checkpoint.md '`blocked`'               "status token 'blocked'"
check checkpoint.md '^## Notas de execução'   "section 'Notas de execução'"
check checkpoint.md '^## Incrementos de fix'  "section 'Incrementos de fix (QA)'"

echo "== templates/handoff.md =="
for k in missao fase status sessao data gate; do
  check handoff.md "^${k}:" "frontmatter key '${k}'"
done
check handoff.md '^## TL;DR'                  "section 'TL;DR'"
check handoff.md '^## Estado do repo'         "section 'Estado do repo'"
check handoff.md '^## O que foi feito'        "section 'O que foi feito'"
check handoff.md '^## Artefatos'              "section 'Artefatos'"
check handoff.md '^## Boot da próxima fase'   "section 'Boot da próxima fase'"
check handoff.md '^## Pendências / Decisions for a Human' "open-questions section"
check handoff.md '^## Riscos e não-feitos'    "section 'Riscos e não-feitos'"
check handoff.md '^## Achados fora de escopo' "section 'Achados fora de escopo'"

echo "== templates/pr-body.md =="
check pr-body.md '^## O que mudou'            "section 'O que mudou'"
check pr-body.md '^## Como verificar'         "section 'Como verificar'"
check pr-body.md '^## Evidências'             "section 'Evidências'"
check pr-body.md '^## Plano'                  "section 'Plano'"
check pr-body.md '^## Pendências \(Decisions for a Human\)' "open-questions section"
check pr-body.md '^## Achados fora de escopo' "section 'Achados fora de escopo'"
check pr-body.md '^## Riscos e não-feitos'    "section 'Riscos e não-feitos'"

echo
if [ "$fails" -eq 0 ]; then
  echo "template contract intact"
  exit 0
fi
echo "$fails check(s) failed" >&2
exit 1
