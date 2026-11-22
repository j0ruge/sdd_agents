---
missao: 20261121-l4-preflight-health-e-sensores
atualizado: 2026-11-21 22:44
---

# Checkpoint — L4: preflight, health e sensores

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
| I1 | O preflight sem ruído de pipe, e a árvore suja com os caminhos (itens 12 e 11) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    preflight prints no write error with READ_EXTRA filled under a caller that ignores SIGPIPE' <<< "$o") $(grep -c '^  ok    preflight names the dirty paths, and the exclude file only when every one of them is untracked' <<< "$o")"` → `1 1` | done | 81f6ec6 |
| I2 | A sonda do Bash dá ok pelo comando rodado (item 6) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    preflight says the Bash probe executes only when a Bash tool_result of the stream carries the marker' <<< "$o") $(grep -c '^  ok    preflight fails a Bash probe whose answer repeats the marker with no Bash call behind it' <<< "$o") $(grep -c '^  ok    preflight claims Bash in the tool list only over an init line' <<< "$o")"` → `1 1 1` | done | 641529b |
| I3 | Os hooks que toda fase carrega, e a skill pelo .skills da init (item 15) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    preflight lists the hooks the probe session ran, one line per event, with the count, the exit codes and the bytes' <<< "$o") $(grep -c '^  ok    preflight warns by name about a hook that exits non-zero or does not report success, and only about it' <<< "$o") $(grep -c '^  ok    preflight fails a skill a phase will invoke when the init line of the probe does not list it' <<< "$o") $(grep -c '^  ok    preflight says nothing about hooks or the skills list without an init line' <<< "$o")"` → `1 1 1 1` | done | 3612cb9 |
| I4 | O preflight mede a forma do TODO_FILE (item 1) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    preflight measures the shape of TODO_FILE by itself: ok when clean, a warning with the count when not, never a failure' <<< "$o") $(grep -c '^  ok    preflight names the opt-in line with --baseline only when TEST_CMD does not carry check-todo.sh' <<< "$o") $(grep -c '^  ok    preflight says the shape of TODO_FILE was not measured when the file or the sensor is missing' <<< "$o")"` → `1 1 1` | done | 9ef4cdc |
| I5 | O preâmbulo do TODO_FILE contra as revisões do template (item 10) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    the TODO preamble equal to the template of today is ok, in preflight and in install' <<< "$o") $(grep -c '^  ok    the TODO preamble equal to an older revision of the template is a warning with the revision, its date and the diff to run, and the file is not rewritten' <<< "$o") $(grep -c '^  ok    the TODO preamble equal to no revision of the template is an author preamble, said in one neutral line' <<< "$o") $(grep -c '^  ok    a kit that is not a git checkout answers nothing about the TODO preamble' <<< "$o")"` → `1 1 1 1` | done | 6ca6f20 |
| I6 | O sdd run para antes da sessão que será negada (item 7) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    sdd run stops before any session when a skill a phase invokes is found where no read rule covers it, naming the READ_EXTRA entry to add' <<< "$o") $(grep -c '^  ok    sdd retry stops before any session on the same uncovered skill' <<< "$o") $(grep -c '^  ok    sdd run stops before any session on a plugin install that does not hold the skill' <<< "$o") $(grep -c '^  ok    sdd run --dry-run only warns about an uncovered skill, and still projects' <<< "$o") $(grep -c '^  ok    sdd run only warns about a skill it does not find, and about one whose target the grammar refuses' <<< "$o") $(grep -c '^  ok    preflight and sdd run say the same sentence about the same uncovered skill' <<< "$o")"` → `1 1 1 1 1 1` | done | 95598f4 |
| I7 | O TEST_CMD que deixa processo vivo, e a suíte sem o linter (itens 3 e 13) | `o=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    preflight warns before its verdict, by pid and executable and never by arguments, about a process TEST_CMD left running' <<< "$o") $(grep -c '^  ok    preflight says nothing of the kind when TEST_CMD leaves nothing behind' <<< "$o") $(grep -c '^  ok    preflight warns that the lint step of the suite will be skipped when shellcheck is absent, only in a tree that carries the suite' <<< "$o")"` → `1 1 1` | done | dfaeeb4 |
| I8 | O clone velho do kit, e o worktree sem o espelho dos chapéus (itens 2 e 14) | `o=$(bash tests/check-preflight.sh 2>&1); d=$(bash tests/check-dry-run.sh 2>&1); echo "$(grep -c '^  ok    a kit checkout off its default branch is named once per process, with the branch it is on' <<< "$o") $(grep -c '^  ok    a kit checkout behind its fetched upstream is named with the count of commits' <<< "$o") $(grep -c '^  ok    a kit on its default branch and level with it says nothing, and so does a linked worktree, a detached HEAD and a kit that is not a git checkout' <<< "$o") $(grep -c '^  ok    the default branch of the kit is its own remote HEAD, never the DEFAULT_BRANCH of the target' <<< "$o") $(grep -c '^  ok    sdd run in a linked worktree with no agent mirror names sdd link-agents, in the stop and in the projection' <<< "$d") $(grep -c '^  ok    sdd run in a main checkout with no agent mirror still names sdd install --force' <<< "$d")"` → `1 1 1 1 1 1` | done | a3e4c86 |
| I9 | O juiz passa pela guarda do chapéu (item 4) | `k=$(bash tests/check-kaizen.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); cmp -s agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md; c=$?; echo "$(grep -c '^  ok    kaizen: a judge session that writes outside its hat stops the line as hat-crossed, after its session row' <<< "$k") $(grep -c '^  ok    kaizen: the retry session that crosses stops too, by its own read' <<< "$k") $(grep -c '^  ok    kaizen: a judge session that writes only the mission folder, KAIZEN_LOG.md and the findings file is not accused' <<< "$k") $(grep -c '^  ok    kaizen: the projection arms no hat guard' <<< "$k") $(grep -c '^  ok    hat: the judge names the base every hat may write, the findings file and the ratchet' <<< "$h") $c"` → `1 1 1 1 1 0` | done | 261acc8 |
| I10 | O atualizado: no futuro é recusado (item 5) | `o=$(bash tests/check-checkpoint.sh 2>&1); echo "$(grep -c '^  ok    rule: an atualizado later than the clock is refused, in --check and in the scan, and one at or before it passes' <<< "$o")"` → `1` | pending | — |
| I11 | A sonda de interrupção lê o grupo depois que a suíte roda (item 8) | `o=$(bash tests/check-health.sh 2>&1); echo "$(grep -c '^  ok    surface: the interrupt probe tells a suite in its own process group from one left in the caller group' <<< "$o")"` → `1` | pending | — |
| I12 | O PR #N sem rastro no histórico (item 9) | `o=$(bash tests/check-todo.sh --selftest 2>&1); t=$(bash tests/check-templates.sh 2>&1); echo "$(grep -c '^  ok    rule: under --baseline a bare PR number in a new item passes only when a commit subject of the local history cites it' <<< "$o") $(grep -c '^  ok    todo.md: a bare PR number is said to be a merged pull request of this repository' <<< "$t") $(grep -c '^  ok    todo.pt-BR.md: a bare PR number is said to be a merged pull request of this repository' <<< "$t")"` → `1 1 1` | pending | — |
| I13 | Fecho: RESOLVED by nos 15 itens | `b=$(git show "$(git merge-base HEAD origin/main)":TODO.md); echo $(( $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md) - $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' <<< "$b") ))` → `15` | pending | — |

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
