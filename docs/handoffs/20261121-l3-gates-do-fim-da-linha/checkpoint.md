---
missao: 20261121-l3-gates-do-fim-da-linha
atualizado: 2026-11-21 05:32
---

# Checkpoint — L3: gates do fim da linha

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas, o Status lido passa a ser um pedaço do comando e o Commit passa a ser `pending`.
> O `gate_EXEC` reprova por "invalid status" e o `sdd status` imprime algo de aparência saudável —
> custou uma missão inteira até alguém olhar. O escape do GFM, `\|`, o runner **hoje entende**:
> `checkpoint_rows` remonta a célula por paridade de `\`, como o `gate_REVIEW` já fazia. Isso é
> rede de segurança, não licença — Check que precisaria de pipe continua virando herestring:
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``, e o `tests/check-checkpoint.sh --check <checkpoint>` do
> kit recusa as duas formas em qualquer checkpoint.
>
> ⚠️ **A célula Commit leva o hash curto NU, sem crase.** `` `abc1234` `` renderiza igual ao hash
> nu, mas é a célula que o runner lê: o `checkpoint_rows` hoje tira a crase dessa coluna, e uma
> célula que não tem forma de SHA reprova o `gate_EXEC` com motivo próprio e para a linha como
> `no-work` antes de abrir sessão. Custou duas sessões EXEC sem trabalho em
> `20260921-amep-backend-0-1-0`.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é o `tests/check-checkpoint.sh --check <este checkpoint>` do kit (pelo caminho do kit).
>
> ⚠️ **Ato fora do git deixa um commit de registro.** O `gate_EXEC` lê 7 a 64 dígitos hex na
> célula Commit e nada mais. Quando o produto do incremento não é código — e-mail enviado, página da
> KB publicada, config no IdP, issue adotada —, o executor grava a evidência num arquivo da pasta da
> missão (`record-<ID>.md`: o que foi feito, a URL ou o ID que o prova, a data) e commita esse
> arquivo; o hash dele vai na célula. Palavra na célula é rótulo, e o gate a recusa.
>
> ⚠️ **Passo depois do merge ou numa janela externa não é incremento.** O merge do humano, um
> yokoten nos repos-alvo, um smoke que exige a mesa livre: na tabela, cada um vira um `pending` que
> nunca fecha ou um `blocked` que para a linha inteira.
> O passo vai para `## Pendências para o humano` do `00-missao.md`, ou para a missão seguinte.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | O TEST_CMD que não rodou não é suíte vermelha: rc 126 e 127 com motivo próprio (item 5) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    gate_EXEC says the TEST_CMD did not run when it exits 126 or 127, and names what the tree misses' <<< "$g") $(grep -c '^  ok    gate_QA and gate_REVIEW say the same of a TEST_CMD that did not run' <<< "$g") $(grep -c -e '^mut_RUN_test_cmd_not_run_reads_red()' tests/check-mutation.sh)"` → `1 1 1` | done | 83b2b3e |
| I2 | O blocked do 50-pr.md e da rodada para a linha, e a saída do conflito é git merge (itens 6 e 7) | `g=$(bash tests/check-gates.sh 2>&1); a=$(bash tests/check-autonomy.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); t=$(bash tests/check-templates.sh 2>&1); cmp -s agents/sdd-publisher.md .claude/agents/sdd-publisher.md; c0=$?; cmp -s agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; c1=$?; echo "$(grep -c '^  ok    gate_PR arms the blocked marker on a 50-pr.md that declares status blocked, and names the merge of the base' <<< "$g") $(grep -c '^  ok    gate_REVIEW arms the blocked marker on a round that declares status blocked' <<< "$g") $(grep -c '^  ok    PR: status blocked in 50-pr.md escalates as handoff-blocked with no second publisher session' <<< "$a") $(grep -c '^  ok    REVIEW: status blocked in the newest round escalates as handoff-blocked with no further round' <<< "$a") $(grep -c '^  ok    hat: the publisher names the merge of the base as the way out of a conflict, never a rebase' <<< "$h") $(grep -c '^  ok    hat: the reviewer writes status blocked only for a round that could not be done, never for one with findings' <<< "$h") $(grep -c '^  ok    review.md: status blocked is the round that could not be done, never the round with findings' <<< "$t") $(grep -c -e '^mut_RUN_pr_blocked_not_armed()' -e '^mut_RUN_review_blocked_not_armed()' tests/check-mutation.sh) $c0 $c1"` → `1 1 1 1 1 1 1 2 0 0` | done | c42fa76 |
| I3 | O gate_PR lê o head do PR e o verified_head, e o corpo se edita pela REST (itens 1, 2 e 13) | `g=$(bash tests/check-gates.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-publisher.md .claude/agents/sdd-publisher.md; c0=$?; echo "$(grep -c '^  ok    gate_PR refuses a pull request whose head is not the head of the mission, and names both' <<< "$g") $(grep -c '^  ok    gate_PR refuses a verified_head that does not cover the head, and passes when only the mission folder changed after it' <<< "$g") $(grep -c '^  ok    gate_PR passes a 50-pr.md with no verified_head, and does not read the head of a merged pull request' <<< "$g") $(grep -c '^  ok    gate_PR says it could not read the head, never that the head differs' <<< "$g") $(grep -c '^  ok    hat: the publisher records verified_head, commits 50-pr.md alone in the mission folder and pushes it' <<< "$h") $(grep -c '^  ok    hat: the publisher and gate_PR edit the body of a pull request through the REST PATCH' <<< "$h") $(grep -c -e '^mut_PR_head_unread()' -e '^mut_PR_verified_head_unchecked()' -e '^mut_PR_merged_head_read()' -e '^mut_PR_head_unreadable_passes()' tests/check-mutation.sh) $c0"` → `1 1 1 1 1 1 4 0` | pending | — |
| I4 | Código commitado depois da rodada reabre a REVIEW (item 4) | `g=$(bash tests/check-gates.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; c0=$?; echo "$(grep -c '^  ok    gate_REVIEW reopens the phase for code committed after the round, and names the commit and the path' <<< "$g") $(grep -c '^  ok    gate_REVIEW passes later commits in what the REVIEW and DOCS hats write, a merge of the base, a merged mission and a round with no reviewed_head' <<< "$g") $(grep -c '^  ok    hat: the reviewer is told that code committed after the round reopens REVIEW' <<< "$h") $(grep -c -e '^mut_REVIEW_later_code_unread()' -e '^mut_REVIEW_later_docs_writes_counted()' -e '^mut_REVIEW_later_merged_mission_refused()' tests/check-mutation.sh) $c0"` → `1 1 1 3 0` | pending | — |
| I5 | O K8 mede o branch que a missão declara (item 11) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    K8 measures the branch the mission declares when HEAD is on another branch, and names it' <<< "$g") $(grep -c '^  ok    K8 reads an empty range when the declared branch is gone or already in the base' <<< "$g") $(grep -c -e '^mut_DOCS_k8_reads_head_off_branch()' -e '^mut_DOCS_k8_gone_branch_refused()' tests/check-mutation.sh)"` → `1 1 2` | pending | — |
| I6 | O e2e vermelho diz se o caso já caiu antes (item 10) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    gate_QA says how often each red e2e case already failed in the earlier e2e gate logs' <<< "$g") $(grep -c '^  ok    gate_QA adds nothing for a log with no failed block, and counts no case that passed' <<< "$g") $(grep -c -e '^mut_QA_e2e_history_uncounted()' -e '^mut_QA_e2e_history_counts_passed()' tests/check-mutation.sh)"` → `1 1 2` | pending | — |
| I7 | O corpo do PR leva as linhas kit:, um Como verificar que roda e a pendência respondida (itens 8, 9 e 12) | `g=$(bash tests/check-gates.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); t=$(bash tests/check-templates.sh 2>&1); cmp -s agents/sdd-publisher.md .claude/agents/sdd-publisher.md; c0=$?; echo "$(grep -c '^  ok    gate_PR refuses a body with fewer kit lines than the handoffs of the mission, and counts none in a quote or a fence' <<< "$g") $(grep -c '^  ok    gate_PR reads the body once for the blocked rows and the kit lines, and not at all without either' <<< "$g") $(grep -c '^  ok    hat: the publisher carries every kit line of the handoffs into the body of the pull request, whole' <<< "$h") $(grep -c '^  ok    hat: the publisher writes in how to verify only what the shell of the reader runs, and sends a TEST_CMD with a runner variable to sdd preflight' <<< "$h") $(grep -c '^  ok    hat: the publisher keeps a question of the plan that a later handoff answered, ticked and with the answer' <<< "$h") $(grep -c '^  ok    pr-body.md: the body has a place for the kit lines, the answered question and the preflight line' <<< "$t") $(grep -c -e '^mut_PR_kit_lines_uncounted()' -e '^mut_PR_kit_lines_counted_in_quote()' tests/check-mutation.sh) $c0"` → `1 1 1 1 1 1 2 0` | pending | — |
| I8 | O gate: só cita medida com comando e sha, ou saída que está no caminho (item 3) | `t=$(bash tests/check-templates.sh 2>&1); echo "$(grep -c '^  ok    handoff.md: the gate field cites a measure with its command and the sha it ran on, or the path that holds the output' <<< "$t") $(grep -c '^  ok    review.md: the gate field cites a measure with its command and the sha it ran on, or the path that holds the output' <<< "$t")"` → `1 1` | pending | — |
| I9 | Fecho: RESOLVED by nos 13 itens e o 20-handoff-exec.md | `b=$(git show "$(git merge-base HEAD origin/main)":TODO.md); echo $(( $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md) - $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' <<< "$b") ))` → `13` | pending | — |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo. Medido: as notas eram 69% deste arquivo, e este arquivo era 44,7% de tudo que a missão
> releu. Este aqui é a **tabela** que o runner parseia, e só ela.
>
> ⚠️ Missão começada **antes** de `20260904-a-dieta-de-contexto` mantém as notas dentro do próprio
> `checkpoint.md`: o runner detecta pela presença do arquivo irmão e não migra nada em voo.

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
