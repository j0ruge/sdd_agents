---
missao: 20261117-o-worker-orquestrador
atualizado: 2026-11-17 21:35
---

# Checkpoint — O worker orquestrador

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de pipe cru na célula do Check**, e a célula Commit leva o hash curto **nu**, sem crase.
> Check que lê a saída de um sensor ancora em `^  ok    ` (quatro espaços, com o `^`).
> As frases de asserção de cada Check estão escritas, uma a uma, no `01-plano.md`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Templates da campanha e da delegação | `o=$(bash tests/check-templates.sh 2>&1); grep -c '^  ok    worker templates: ' <<< "$o"` → `3` | done | bdfa30e |
| I2 | O programa e o sensor, ligados na suíte | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    usage: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` | done | f7f99ea |
| I3 | O verbo delegate | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    delegate: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 3; echo "$a $?"` → `3 0` | done | 3b6d636 |
| I4 | O verbo level | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    level: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 6; echo "$a $?"` → `6 0` | done | dc66ce2 |
| I5 | O verbo allows | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    allows: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 9; echo "$a $?"` → `4 0` | done | 5bafad6 |
| I6 | O verbo budget | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    budget: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 11; echo "$a $?"` → `3 0` | done | 4095baa |
| I7 | O verbo next | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    next: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 14; echo "$a $?"` → `5 0` | pending | — |
| I8 | O verbo pr-ready | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    pr-ready: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 19; echo "$a $?"` → `7 0` | pending | — |
| I9 | O comando da sessão (commands/sdd-worker.md) | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    command: ' <<< "$o"` → `3` | pending | — |
| I10 | Documentação e vocabulário | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    docs: ' <<< "$o"` → `1` | pending | — |
| I11 | A campanha do kit e a gaveta | `o=$(bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues 2>/dev/null); a=$(grep -c '^level assisted' <<< "$o"); b=$(grep -c '^- \[ \] ' docs/superpowers/campaigns/20261117-zerar-as-issues/campaign.md 2>/dev/null); echo "$a $b"` → `1 83` | pending | — |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo. Este aqui é a **tabela** que o runner parseia, e só ela.

## Incrementos de fix (QA e REVIEW)

> Duas fases escrevem na tabela acima depois do EXEC, pelo mesmo motivo e pela mesma rota: quem
> **acha** não conserta, e o `current_phase()` devolve a bola ao EXEC sozinho porque uma linha
> `pending` reprova o `gate_EXEC` antes de o gate da fase que a escreveu ser lido.
>
> **`F<n>` — `sdd-qa`**, quando um bug sanável é reprovado. O Check obrigatoriamente inclui
> **regression test passa** + **re-walk da jornada impactada verde**. Bug que exige julgamento
> humano NÃO vira fix — vai para "Decisions for a Human" no handoff de QA.
>
> **`R<n>` — `sdd-reviewer`**, um por achado CRITICAL/HIGH da rodada; os MEDIUM/LOW baratos entram
> num único `R<n>` de lote por rodada (`"achados #4–#7 da r1"`), com um Check por achado dentro da
> célula. Caro demais vai para o `TODO_FILE`; o que exige julgamento humano vai para as pendências
> do `40-review-r<N>.md`, sem `R<n>`. O detalhe de cada achado mora na rodada mais recente, e a nota
> dela é honesta: um `B` com incrementos escritos é a rodada saudável.
