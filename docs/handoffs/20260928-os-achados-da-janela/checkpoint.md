---
missao: 20260928-os-achados-da-janela
atualizado: 2026-09-28 00:00
---

# Checkpoint — os achados da janela do juiz

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** Check que precisaria de pipe vira herestring:
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``. O sensor é `tests/check-checkpoint.sh`.
>
> ⚠️ **A célula Commit leva o hash curto NU, sem crase.**
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Registrar os 5 achados não consertados + recorrência do achado 4, catraca 83 → 88 | `o=$(bash tests/check-todo.sh --count TODO.md); b=$(grep -c '^todo-findings 88$' tests/health-baseline.txt); echo "$o/$b"` → `88/1` | pending | — |
| I2 | `sdd close` faz fast-forward da `DEFAULT_BRANCH` e avisa na divergência | `o=$(bash tests/check-autonomy.sh 2>&1); a=$(grep -c '^  ok    close: fast-forwards the default branch to its upstream' <<< "$o"); b=$(grep -c '^  ok    close: a diverged default branch is warned, never forced' <<< "$o"); echo "$a$b"` → `11` | pending | — |
| I3 | `CHECKOUT-UNAVAILABLE` nomeia o interpretador e o requisito que caiu | `o=$(bash tests/check-coordination.sh 2>&1); grep -c '^  ok    unavailable: names the interpreter and the missing requirement' <<< "$o"` → `1` | pending | — |
| I4 | `qa_substep` e Âncora 1 do `gate_QA` só aceitam o relatório da própria missão | `o=$(bash tests/check-gates.sh 2>&1); a=$(grep -c '^  ok    QA gate refuses a closed report from another mission' <<< "$o"); b=$(grep -c '^  ok    qa_substep does not close on another mission.s report' <<< "$o"); c=$(grep -c '^  ok    QA gate accepts the mission.s own closed report' <<< "$o"); echo "$a$b$c"` → `111` | pending | — |
| I5 | `RESOLVED by` no item do achado 4, KAIZEN_LOG, anatomia § 4 e gaveta | `o=$(grep -c 'RESOLVED by' TODO.md); k=$(grep -c '^## 2026-09-.. — .*achados da janela' KAIZEN_LOG.md); echo "$o/$k"` → `2/1` | pending | — |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo.

## Incrementos de fix (QA e REVIEW)

> **`F<n>` — `sdd-qa`**, quando um bug sanável é reprovado. O Check obrigatoriamente inclui
> **regression test passa** + **re-walk da jornada impactada verde**.
>
> **`R<n>` — `sdd-reviewer`**, um por achado CRITICAL/HIGH da rodada; os MEDIUM/LOW baratos entram
> num único `R<n>` de lote por rodada.
