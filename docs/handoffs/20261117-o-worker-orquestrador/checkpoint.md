---
missao: 20261117-o-worker-orquestrador
atualizado: 2026-11-18 05:21
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
| I7 | O verbo next | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    next: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 14; echo "$a $?"` → `5 0` | done | 9de910a |
| I8 | O verbo pr-ready | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    pr-ready: ' <<< "$o"); c=$(grep -c '^mut_WORKER_' tests/check-mutation.sh); test "$c" -ge 19; echo "$a $?"` → `7 0` | done | 26adfe4 |
| I9 | O comando da sessão (commands/sdd-worker.md) | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    command: ' <<< "$o"` → `3` | done | 5721c92 |
| I10 | Documentação e vocabulário | `o=$(bash tests/check-worker.sh 2>&1); grep -c '^  ok    docs: ' <<< "$o"` → `1` | done | 30bc8cd |
| I11 | A campanha do kit e a gaveta | `o=$(bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues 2>/dev/null); a=$(grep -c '^level assisted' <<< "$o"); b=$(grep -c '^- \[ \] ' docs/superpowers/campaigns/20261117-zerar-as-issues/campaign.md 2>/dev/null); echo "$a $b"` → `1 83` | done | 3fe5d3e |
| F1 | A assinatura cobre o teto de cada lote: hoje o `Ceiling` mora no `campaign.md`, fora do digest, e trocar o `plan` do L6 por `-` depois de assinar `full` faz `allows approve --lot L6` responder `allowed` com a assinatura válida (Q1 do `30-handoff-qa.md`); o `delegate` também passa a mostrar os tetos que assina. Fecha com o Check E o re-walk da jornada J5 do `30-handoff-qa.md` verde | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    seal: ' <<< "$o"); c=$(grep -c '^mut_WORKER_seal_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` | done | 42d1a56 |
| F2 | O `campaign:` da delegação e o do `campaign.md` têm de ser o nome do diretório, e o `expires:` um instante que existe: hoje os dois ids divergem sem aviso (o `budget` soma as missões de um, o `next` anda nas do outro), o id placeholder do template vira fila no `next` (`plan L1`, rc 0), e `2026-11-18 99:99` é assinado e lido como prazo (Q2 e Q3 do `30-handoff-qa.md`). Fecha com o Check E o re-walk da jornada J6 do `30-handoff-qa.md` verde | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    legible: ' <<< "$o"); c=$(grep -c '^mut_WORKER_legible_' tests/check-mutation.sh); test "$c" -ge 2; echo "$a $?"` → `2 0` | done | 8add018 |
| R1 | O teto por missão assinado chega ao `sdd run` ou o worker para: hoje o `.sdd/config.sh` que fixa `BUDGET_MISSION_USD` (o starter fixa 150) passa por cima do ambiente no `load_config`, e `BUDGET_MISSION_USD=40 sdd run --dry-run` lê `of 150`; sem editar `bin/sdd`, o `budget` sai rc 1 nomeando a chave quando o arquivo a fixa acima do teto assinado ou em 0, e a prosa do `schema.md`, do `templates/delegation.md` e do `run` do comando diz a regra real (achado #1 da r1) | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    cap: ' <<< "$o"); c=$(grep -c '^mut_WORKER_cap_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` | done | 328087f |
| R2 | Achados #2–#4 da r1, em lote: o `review` do `pr-ready` recusa justificativa e `gate:` placeholder pela régua do `gate_REVIEW` (`rationale: `); um ato pedido sem `--lot` nunca é permitido acima de um teto de lote da fila (`lot: `); o `delegate` não assina termos que mudaram depois de mostrados (`shown: `). Uma família e ao menos um mutante por achado | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    rationale: ' <<< "$o"); b=$(grep -c '^  ok    lot: ' <<< "$o"); d=$(grep -c '^  ok    shown: ' <<< "$o"); r=$(grep -c '^mut_WORKER_rationale_' tests/check-mutation.sh); l=$(grep -c '^mut_WORKER_lot_' tests/check-mutation.sh); s=$(grep -c '^mut_WORKER_shown_' tests/check-mutation.sh); test "$r" -ge 1 && test "$l" -ge 1 && test "$s" -ge 1; echo "$a $b $d $?"` → `1 1 1 0` | pending | — |

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
