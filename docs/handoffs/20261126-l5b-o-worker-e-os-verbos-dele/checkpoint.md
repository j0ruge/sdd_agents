---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
atualizado: 2026-11-27 00:28
---

# Checkpoint — O worker e os verbos dele

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Inventário de worktrees | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    nul worktree inventory is complete$' <<< "$o"` → `1` | done | 064098e |
| I2 | Config e validade | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    permission reflects exported cap and final clock$' <<< "$o"` → `1` | done | d1e8d0f |
| I3 | Gasto por campanha | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    removed mission spend is counted once$' <<< "$o"` → `1` | done | 1af340a |
| I4 | Teto em voo | `o=$(bash tests/check-codex-runner.sh 2>&1); grep -c '^  ok    delegated sessions respect cap changes$' <<< "$o"` → `1` | done | ac581c8 |
| I5 | Diagnóstico de parada | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    stop preserves cause and original line$' <<< "$o"` → `1` | done | d7ca654 |
| I6 | Histórico de PRs | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    fork pages cannot hide the mission pull request$' <<< "$o"` → `1` | done | 9ce1943 |
| I7 | Medição da revisão | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    grade and ancestry failures have distinct witnesses$' <<< "$o"` → `1` | pending | — |
| I8 | Suíte no head | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    merge requires local ci on the tested head$' <<< "$o"` → `1` | pending | — |
| I9 | Tratamento dos achados | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    review findings have verified dispositions$' <<< "$o"` → `1` | pending | — |
| I10 | Escolhas e consentimento | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    merge binds answers and consent to head$' <<< "$o"` → `1` | pending | — |
| I11 | Base de revisão | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    review preserves the eligible delta$' <<< "$o"` → `1` | pending | — |
| I12 | Fila e pós-merge | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    queue changes and followup reviews resume safely$' <<< "$o"` → `1` | pending | — |
| I13 | Preflight antes do run | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    run launch requires successful worktree preflight$' <<< "$o"` → `1` | pending | — |
| I14 | Planejamento antecipado | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` | pending | — |

## Incrementos de fix (QA e REVIEW)

QA usa F<n> para regressão e nova caminhada. REVIEW usa R<n> para achados da rodada. Registrar o hash sem crases depois do commit.
