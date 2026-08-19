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
# This file has no selftest and the mutation catalogue cannot reach it (that catalogue sabotages
# bin/sdd; this one reads templates/). What stands in for one is the REVIEW_FLOOR below plus an
# adversarial pass: writing the review heading at level 2, renaming the table columns, dropping the
# **Overall** row and deleting the assertion loop each turn this file red. What survives by
# construction, named rather than hidden and not reachable in one edit: lowering REVIEW_FLOOR while
# the assertions are still there. Inert alone — the paired sabotage, deleting the assertions, dies
# on the floor.
#
# Usage: tests/check-templates.sh   (exit 0 = contract intact)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# == templates/review.md ==
#
# The review round report was the ONE artifact with a gate and no template. gate_REVIEW reads it
# with a literal `^###[[:space:]]+Overall Grade` (bin/sdd) and answers NO-TABLE when the heading
# is written at any other level — which two independent review sessions did, both writing `##`,
# because there was nothing to copy from. A template is what stops a third from deriving it again.
#
# These assertions are DERIVED from the gate rather than restated beside it: the heading regex and
# the column names are what the awk in gate_REVIEW actually reads. Note the `###` in the check
# below is the whole point — a `##` here would ship the exact defect the template exists to stop.
# REVIEW_ASSERTIONS counts CALLS, never passes, and `fails` alone decides the verdict — one
# mechanism per question. A first draft counted only the assertions that held, which duplicated
# the `fails` accounting: an adversarial pass neutered the duplicate and the sensor went on
# printing an `ok rule:` line about a template that had just failed fourteen checks.
REVIEW_ASSERTIONS=0
REVIEW_FAILS_BEFORE="$fails"
review_check() { # review_check <regex> <description> — check(), counted for the floor below
  check review.md "$1" "$2"
  REVIEW_ASSERTIONS=$((REVIEW_ASSERTIONS + 1))
}

echo "== templates/review.md =="
for k in missao fase rodada status sessao data gate; do
  review_check "^${k}:" "frontmatter key '${k}'"
done
review_check '^### Overall Grade' "the '### Overall Grade' heading gate_REVIEW greps, at level 3"
review_check '^\| Criterion \| Grade \| Rationale \|' "the exact table header the gate parses"
review_check '^\| \*\*Overall\*\* \|'  "the '**Overall**' row"
review_check '^## Achados da rodada'   "section 'Achados da rodada'"
review_check '^## O que foi corrigido' "section 'O que foi corrigido'"
review_check '^## O que foi refutado'  "section 'O que foi refutado'"
review_check '^## Achados fora de escopo' "section 'Achados fora de escopo'"

# The floor is what turns "no assertion failed" into "the assertions ran". Deleting the loop above
# would otherwise leave this file green while measuring nothing about the file it names — the
# vacuity every sensor in this suite carries a floor against.
REVIEW_FLOOR=14
if [ "$REVIEW_ASSERTIONS" -lt "$REVIEW_FLOOR" ]; then
  printf '  FAIL review.md: only %d assertion(s) ran, expected at least %d — a clean report over\n' \
    "$REVIEW_ASSERTIONS" "$REVIEW_FLOOR" >&2
  printf '       a rule that never ran is what this floor exists to refuse\n' >&2
  fails=$((fails + 1))
elif [ "$fails" -ne "$REVIEW_FAILS_BEFORE" ]; then
  # An assertion above failed and check() has already said which. No ok line: a sensor whose two
  # verdicts share a stream cannot be read by a grep, and this one IS read by a grep.
  :
else
  printf '  ok    rule: the review template carries the heading and table gate_REVIEW parses (%d assertion(s))\n' \
    "$REVIEW_ASSERTIONS"
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "template contract intact"
  exit 0
fi
echo "$fails check(s) failed" >&2
exit 1
