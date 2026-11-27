---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
atualizado: 2026-11-27 16:33
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
| I7 | Medição da revisão | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    grade and ancestry failures have distinct witnesses$' <<< "$o"` → `1` | done | f7b8071 |
| I8 | Suíte no head | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    merge requires local ci on the tested head$' <<< "$o"` → `1` | done | 6ed4ddc |
| I9 | Tratamento dos achados | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    review findings have verified dispositions$' <<< "$o"` → `1` | done | 2d81fe7 |
| I10 | Escolhas e consentimento | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    merge binds answers and consent to head$' <<< "$o"` → `1` | done | 4edda89 |
| I11 | Base de revisão | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    review preserves the eligible delta$' <<< "$o"` → `1` | done | 20ffaab |
| I12 | Fila e pós-merge | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    queue changes and followup reviews resume safely$' <<< "$o"` → `1` | done | f3b4056 |
| I13 | Preflight antes do run | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    run launch requires successful worktree preflight$' <<< "$o"` → `1` | done | 2e8bd53 |
| I14 | Planejamento antecipado | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    authorized ahead planning starts once before wait$' <<< "$o"` → `1` | done | 6344f01 |
| F1 | Reutilizar a reserva que outra retomada concluiu durante a consulta de orçamento | `if python3 tests/check-worker-ahead.py "$PWD" && python3 e2e/check-worker-lookahead-race.py "$PWD" >/dev/null; then echo 1; else echo 0; fi` → `1` | done | 5ac9b42 |
| F2 | Fazer a sonda medir a seleção do delta e reprovar quando o bloco não carrega | `if python3 e2e/check-worker-review-probe.py "$PWD" >/dev/null; then echo 1; else echo 0; fi` → `1` | done | 9837b00 |
| R1 | Exigir que `TEST_CMD` termine antes de publicar sucesso em `local/ci` | `o=$(bash tests/check-worker.sh 2>&1) && grep -c '^  ok    local ci refuses success without a completed test command$' <<< "$o"` → `1` | done | 297f072 |
| R2 | Entregar ao relay o lote e a fonte canônica da fila, mesmo sem cópia na base | `o=$(bash tests/check-worker.sh 2>&1) && grep -c '^  ok    ahead planner receives the canonical queue outside its base$' <<< "$o"` → `1` | done | a83df3e |
| R3 | Manter a sugestão quando a referência local do pedido não é recuperável | `o=$(bash tests/check-worker.sh 2>&1) && grep -c '^  ok    ahead planning refuses stale owner request references$' <<< "$o"` → `1` | done | 9b0e168 |
| R4 | Separar aprovação informativa de achado humano e recusar metadados ilegíveis de threads | `o=$(bash tests/check-worker.sh 2>&1) && [ "$(grep -c '^  ok    plain human approvals do not hide actionable findings$' <<< "$o")" = 1 ] && grep -c '^  ok    review findings and readiness reject malformed resolved threads$' <<< "$o"` → `1` | pending | — |

## Incrementos de fix (QA e REVIEW)

QA usa F<n> para regressão e nova caminhada. REVIEW usa R<n> para achados da rodada. Registrar o hash sem crases depois do commit.
