---
missao: 20261117-l1-a-prosa-do-chapeu
atualizado: 2026-11-19 19:06
---

# Checkpoint — L1: a prosa do chapéu e dos docs

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de pipe cru na célula do Check**, e a célula Commit leva o hash curto **nu**, sem crase.
> Check que lê a saída de um sensor ancora em `^  ok    ` (quatro espaços, com o `^`).
> As frases de asserção de cada Check estão escritas, uma a uma, no `01-plano.md`.
>
> ⚠️ **Passo depois do merge ou numa janela externa não é incremento.** Trazer a base, o chore que
> apaga os itens e a sincronização do espelho estão em `## Pendências para o humano` do `00-missao.md`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | O planner: a base pelo DEFAULT_BRANCH, a devolução no idioma, a Check que aceita RECURRED (itens A, B, C) | `o=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md; c=$?; echo "$(grep -c '^  ok    hat: the planner names the base branch by DEFAULT_BRANCH of the target, never by the literal main' <<< "$o") $(grep -c '^  ok    hat: the planner writes every hand-back to the relay in OUTPUT_LANG' <<< "$o") $(grep -c '^  ok    hat: a planner Check for a new TODO_FILE item also accepts a RECURRED entry on an equivalent open item' <<< "$o") $c"` → `1 1 1 0` | done | 2b01f33 |
| I2 | O executor: o handoff no mesmo incremento, e o mutante restaurado com cp (itens D, E) | `o=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md; c=$?; echo "$(grep -c '^  ok    hat: the executor writes 20-handoff-exec.md in the increment that leaves no row pending, and its answer says whether it did' <<< "$o") $(grep -c '^  ok    hat: the executor restores a mutant with cp and rm, so an incremental build sees a new mtime' <<< "$o") $c"` → `1 1 0` | done | abe5808 |
| I3 | O revisor: esperar sem Monitor, e a sonda fora do repo (itens F, G) | `o=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-reviewer.md .claude/agents/sdd-reviewer.md; c=$?; echo "$(grep -c '^  ok    hat: the reviewer waits for a slow command in the foreground, under a ceiling below the Bash limit' <<< "$o") $(grep -c '^  ok    hat: the reviewer writes a probe outside the repo by heredoc, and a test filter that matches nothing is a failure' <<< "$o") $c"` → `1 1 0` | done | b51657d |
| I4 | A DOCS: a lição reincidente ganha destino (item H) | `o=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-docs.md .claude/agents/sdd-docs.md; c=$?; echo "$(grep -c '^  ok    hat: the docs phase turns a lesson its own log calls recurrent into a proposed rule, or writes why not' <<< "$o") $c"` → `1 0` | done | 781fe39 |
| I5 | A QA: o qa: skipped confirma nos dois caminhos (item I) | `o=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-qa.md .claude/agents/sdd-qa.md; c=$?; echo "$(grep -c '^  ok    hat: the qa hat sends a declared qa: skipped to the confirmation of section 2 on both paths' <<< "$o") $c"` → `1 0` | done | 40c836b |
| I6 | Os docs do operador: o README, o sdd run destacado e os threads abertos (itens J, K, L) | `o=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    doc: the README shows the clone line without calling the repository private' <<< "$o") $(grep -c '^  ok    doc: failure-modes.md finds a detached sdd run without matching the watcher, and says how to wait for its end' <<< "$o") $(grep -c '^  ok    doc: the finding-PR recipe merges only with zero unresolved review threads on the head, with the command beside it' <<< "$o")"` → `1 1 1` | done | 596627b |
| I7 | As duas sementes do TODO.md: número que muda não vai no título (item M) | `o=$(bash tests/check-templates.sh 2>&1); grep -c '^  ok    todo.*: a number that changes goes in the body, never in the title' <<< "$o"` → `2` | done | bc8710f |
| I8 | A ajuda do sdd why diz que o gate roda a suíte (item N) | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    help: sdd why says its gate runs TEST_CMD for EXEC, QA or REVIEW, as sdd boot does' <<< "$o"` → `1` | done | c02da26 |
| I9 | Fecho: RESOLVED by nos 14 itens e o 20-handoff-exec.md | `b=$(git show origin/main:TODO.md); echo $(( $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md) - $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' <<< "$b") ))` → `14` | pending | — |

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
