#!/usr/bin/env bash
# Sensor do contrato dos templates.
#
# Os templates não são decoração: o runner faz grep neles (frontmatter do handoff, tabela do
# checkpoint, gate PLAN-AUTO da missão). Se um heading ou uma chave some, o gate correspondente
# passa a mentir em silêncio. Este teste falha primeiro, alto e barato.
#
# Uso: tests/check-templates.sh   (exit 0 = contrato íntegro)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/templates"
fails=0

check() { # check <arquivo> <regex> <descrição>
  if grep -qE "$2" "$T/$1"; then
    printf '  ok   %s: %s\n' "$1" "$3"
  else
    printf '  FALHA %s: falta %s (regex: %s)\n' "$1" "$3" "$2" >&2
    fails=$((fails + 1))
  fi
}

echo "== templates/missao.md =="
for k in missao titulo data versao branch aprovacao ddd; do
  check missao.md "^${k}:" "chave de frontmatter '${k}'"
done
check missao.md '^## Problema \(Gemba\)'      "seção 'Problema (Gemba)'"
check missao.md '^## Métrica'                 "seção 'Métrica'"
check missao.md '^## Resultado esperado'      "seção 'Resultado esperado'"
check missao.md '^## Fora de escopo'          "seção 'Fora de escopo'"
check missao.md '^## Gate PLAN-AUTO'          "seção 'Gate PLAN-AUTO'"
check missao.md '^## Checklist kaizen'        "checklist kaizen"
check missao.md '^## Checklist DDD'           "checklist DDD"
check missao.md '^## Decisões do grill'       "decisões do grill"
check missao.md '^## Pendências para o humano' "pendências para o humano"
for c in a b c d e; do
  check missao.md "^\| ${c} \|" "critério PLAN-AUTO '${c}'"
done

echo "== templates/plano.md =="
check plano.md '^## Contexto verificado'      "seção 'Contexto verificado'"
check plano.md '^## Arquitetura da mudança'   "seção 'Arquitetura da mudança'"
check plano.md '^## Incrementos'              "seção 'Incrementos'"
check plano.md '\*\*Check:\*\*'               "campo 'Check' por incremento"
check plano.md '\*\*Sensor durável:\*\*'      "campo 'Sensor durável' por incremento"
check plano.md '^## Riscos e não-feitos'      "seção 'Riscos e não-feitos'"
check plano.md '^## Verificação end-to-end'   "seção 'Verificação end-to-end'"

echo "== templates/checkpoint.md =="
check checkpoint.md '^\| ID \| Incremento \| Check \(comando → esperado\) \| Status \| Commit \|' \
  "cabeçalho exato da tabela (o runner faz parse por posição de coluna)"
check checkpoint.md 'pending'                 "token de status 'pending'"
check checkpoint.md '`done`'                  "token de status 'done'"
check checkpoint.md '`blocked`'               "token de status 'blocked'"
check checkpoint.md '^## Notas de execução'   "seção 'Notas de execução'"
check checkpoint.md '^## Incrementos de fix'  "seção 'Incrementos de fix (QA)'"

echo "== templates/handoff.md =="
for k in missao fase status sessao data gate; do
  check handoff.md "^${k}:" "chave de frontmatter '${k}'"
done
check handoff.md '^## TL;DR'                  "seção 'TL;DR'"
check handoff.md '^## Estado do repo'         "seção 'Estado do repo'"
check handoff.md '^## O que foi feito'        "seção 'O que foi feito'"
check handoff.md '^## Artefatos'              "seção 'Artefatos'"
check handoff.md '^## Boot da próxima fase'   "seção 'Boot da próxima fase'"
check handoff.md '^## Pendências / Decisions for a Human' "seção de pendências"
check handoff.md '^## Riscos e não-feitos'    "seção 'Riscos e não-feitos'"
check handoff.md '^## Achados fora de escopo' "seção 'Achados fora de escopo'"

echo "== templates/pr-body.md =="
check pr-body.md '^## O que mudou'            "seção 'O que mudou'"
check pr-body.md '^## Como verificar'         "seção 'Como verificar'"
check pr-body.md '^## Evidências'             "seção 'Evidências'"
check pr-body.md '^## Plano'                  "seção 'Plano'"
check pr-body.md '^## Pendências \(Decisions for a Human\)' "seção de pendências"
check pr-body.md '^## Achados fora de escopo' "seção 'Achados fora de escopo'"
check pr-body.md '^## Riscos e não-feitos'    "seção 'Riscos e não-feitos'"

echo
if [ "$fails" -eq 0 ]; then
  echo "contrato dos templates íntegro"
  exit 0
fi
echo "$fails verificação(ões) falharam" >&2
exit 1
