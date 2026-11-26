---
missao: 20261121-l5-saida-humana-e-contrato-do-runner
atualizado: 2026-11-26 14:17
---

# Checkpoint — L5: saída humana e contrato do runner

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
| I1 | O sdd adr new lê os números de todo ref e de todo worktree (item 17) | `a=$(bash tests/check-adr.sh 2>&1); echo "$(grep -c '^  ok    an id used only on another local branch is never handed out again, and the answer names the ref' <<< "$a") $(grep -c '^  ok    an id used only on a remote-tracking ref is never handed out again' <<< "$a") $(grep -c '^  ok    an id used only on the disk of another worktree is never handed out again, and the answer names the worktree' <<< "$a") $(grep -c '^  ok    a repository with a single ref and a single worktree allocates from the disk and names no other source' <<< "$a")"` → `1 1 1 1` | done | 436b1f2 |
| I2 | O link-agents liga os comandos do kit, e o preflight avisa a falta do /sdd-plan (item 5) | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents links every kit command into .claude/commands of the target, and a second run links nothing' <<< "$p") $(grep -c '^  ok    link-agents ignores the linked commands by one .gitignore rule, appended once' <<< "$p") $(grep -c '^  ok    preflight warns that /sdd-plan is in neither commands directory, naming sdd-link-agents and the ln -s by hand' <<< "$p") $(grep -c '^  ok    preflight says nothing about /sdd-plan when the repo or the user directory has it' <<< "$p") $(grep -c '^  ok    in the kit itself the warning names only the ln -s into the user directory' <<< "$p")"` → `1 1 1 1 1` | done | 8718ccf |
| I3 | A ajuda do sdd run mostra a forma destacada e onde ler o progresso (item 14) | `h=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    help: sdd run shows its detached form and where to read the progress afterwards' <<< "$h") $(grep -c 'setsid nohup sdd run' README.md)"` → `1 1` | done | 03091ed |
| I4 | O git status de leitura não reescreve o índice (item 9) | `g=$(bash tests/check-gates.sh 2>&1); w=$(bash tests/check-worker.sh 2>&1); echo "$(grep -c '^  ok    sdd status --no-gates reads the tree without rewriting the index of the checkout' <<< "$g") $(grep -c '^  ok    index: pr-ready reads the tree without rewriting the index of the checkout' <<< "$w")"` → `1 1` | done | 012044b |
| I5 | O argumento de missão que começa com hífen é recusado (item 6) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    a mission argument that starts with a dash is refused by name in why, phase, boot, census, approve, close and note-manual' <<< "$g") $(grep -c '^  ok    the refusal of a dash argument resolves no mission, with a folder whose name contains it on disk' <<< "$g")"` → `1 1` | done | f7709e3 |
| I6 | O remédio do sdd kaizen recusado leva --no-track (item 3) | `d=$(cat docs/failure-modes.md docs/pipeline.md); k=$(bash tests/check-kaizen.sh 2>&1); echo "$(grep -c '^  ok    the refusal in the checkout the targets run names a worktree add with --no-track' <<< "$k") $(grep -c -e '--no-track -b kaizen/' <<< "$d")"` → `1 2` | done | 0fe8217 |
| I7 | O CHECKOUT-BUSY aponta o sdd status --no-gates (item 16) | `c=$(bash tests/check-coordination.sh 2>&1); echo "$(grep -c '^  ok    a CHECKOUT-BUSY refusal names sdd status --no-gates as the read that takes no lock' <<< "$c")"` → `1` | done | 1f8b722 |
| I8 | O sdd status com o app fora do ar manda subir o app (item 10) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    sdd status with the e2e red and the app down names starting the app, never sdd run' <<< "$g") $(grep -c '^  ok    sdd status with the app down says the QA is closed on disk when 30-handoff-qa.md is done' <<< "$g") $(grep -c '^  ok    sdd status with the e2e red and the app answering still names sdd run' <<< "$g")"` → `1 1 1` | done | 51203f0 |
| I9 | O fim da corrida, o sdd status e o corpo do PR nomeiam o sdd close (item 11) | `k=$(bash tests/check-kaizen.sh 2>&1); t=$(bash tests/check-templates.sh 2>&1); echo "$(grep -c '^  ok    the end of sdd run names sdd close as the step after the merge' <<< "$k") $(grep -c '^  ok    sdd status of a complete mission names sdd close as the step after the merge' <<< "$k") $(grep -c '^  ok    pr-body.md: names sdd close as the step after the merge' <<< "$t")"` → `1 1 1` | done | 70c956f |
| I10 | O ciclo de vida diz as duas provas, e o check-todo.sh lista os resolvidos (item 1) | `s=$(bash tests/check-todo.sh --selftest 2>&1); t=$(bash tests/check-templates.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved prints one line per open item that carries RESOLVED by' <<< "$s") $(grep -c '^  ok    todo.md: the lifecycle names both proofs of a resolution' <<< "$t") $(grep -c '^  ok    todo.pt-BR.md: the lifecycle names both proofs of a resolution' <<< "$t") $(grep -c '^  ok    kaizen: the sweep of the judge names both proofs of a resolution' <<< "$h")"` → `1 1 1 1` | done | 5348c7d |
| I11 | O sdd close lista os RESOLVED by que já podem sair (item 12) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    sdd close lists the open item whose RESOLVED by hash is an ancestor of the base, with file, line, title and proof' <<< "$g") $(grep -c '^  ok    sdd close lists the item whose hash is an ancestor of the head of the mission PR it saw MERGED, the squash case' <<< "$g") $(grep -c '^  ok    sdd close lists no item whose hash passes neither proof, and none without RESOLVED by' <<< "$g") $(grep -c '^  ok    sdd close lists the resolved items with and without JIRA, and deletes nothing' <<< "$g")"` → `1 1 1 1` | done | 891712d |
| I12 | O sdd close lista as linhas que ainda dão o PR mergeado como aberto (item 8) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    sdd close lists the tracked lines that still give the merged PR as open, outside the handoff directory' <<< "$g") $(grep -c '^  ok    sdd close says nothing about open-PR lines when none is left, or when the merge was not verified' <<< "$g")"` → `1 1` | done | e30971f |
| I13 | O sdd run não grita que commita na base quando a TICKET vai cortar o branch (item 13) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    sdd run on the base branch is silent about committing into it while the branch field is the placeholder and the TICKET is still to run' <<< "$g") $(grep -c '^  ok    sdd run on the base branch still warns once 10-ticket.md exists, and when the mission declares the base itself' <<< "$g")"` → `1 1` | done | f27e0f8 |
| I14 | O lembrete do sdd kaizen diz o backlog e o custo (item 15) | `k=$(bash tests/check-kaizen.sh 2>&1); echo "$(grep -c '^  ok    the reminder says how many open findings the kit backlog holds and what one judge session may cost' <<< "$k") $(grep -c '^  ok    the reminder still prints, without the count, when the kit backlog cannot be counted' <<< "$k")"` → `1 1` | done | ca5260b |
| I15 | O sdd install troca a semente intocada de outro idioma (item 4) | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    the first install with no OUTPUT_LANG says the TODO was seeded in English and how to reseed it' <<< "$p") $(grep -c '^  ok    install replaces a TODO that is still the untouched seed of another language with the seed of OUTPUT_LANG' <<< "$p") $(grep -c '^  ok    install preserves a TODO one byte away from a seed' <<< "$p") $(grep -c '^  ok    preflight warns that the TODO is still the untouched seed of another language, naming sdd install' <<< "$p")"` → `1 1 1 1` | done | 0c457ab |
| I16 | A prosa diz a regra 2 e o teto de largura como os sensores medem (item 2) | `t=$(bash tests/check-templates.sh 2>&1); h=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    checkpoint.md: the anchor rule names the pass mark of a test runner and the count that expects only zeros' <<< "$t") $(grep -c '^  ok    todo.md: the width cap exempts the line that carries only the anchor' <<< "$t") $(grep -c '^  ok    todo.pt-BR.md: the width cap exempts the line that carries only the anchor' <<< "$t") $(grep -c '^  ok    prose: the planner and the executor state the anchor rule and the width cap as the sensors measure them' <<< "$h")"` → `1 1 1 1` | done | 3faad6c |
| I17 | A citação de ADR do kit nomeia o kit (item 7) | `h=$(bash tests/check-hat.sh 2>&1); echo "$(grep -c '^  ok    adr citation: no hat, template or command cites a kit ADR by its bare number' <<< "$h") $(grep -c '^  ok    adr citation: a bare ADR number in a fixture hat is refused by name' <<< "$h")"` → `1 1` | done | dfd5f25 |
| I18 | Fecho: RESOLVED by nos 17 itens | `b=$(git show "$(git merge-base HEAD origin/main)":TODO.md); echo $(( $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' TODO.md) - $(grep -cE 'RESOLVED by [0-9a-f]{7,40}' <<< "$b") ))` → `17` | done | a033008 |
| R1 | Achado #1 da r1 — preservar comandos locais conflitantes no link-agents | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents preserves conflicting tracked edits and untracked local commands$' <<< "$p") $(grep -c '^  ok    link-agents still installs missing kit commands and is idempotent$' <<< "$p")"` → `1 1` | done | 21482a2 |
| R2 | Achado #2 da r1 — ler ADRs de outros worktrees também no Git que não aceita -z | `a=$(bash tests/check-adr.sh 2>&1); echo "$(grep -c '^  ok    adr allocation falls back when git worktree list refuses NUL output$' <<< "$a") $(grep -c '^  ok    adr new names the other worktree and advances beyond its uncommitted id on older Git$' <<< "$a")"` → `1 1` | done | 4376e32 |
| R3 | Achados #3–#5 da r1 — distinguir resolução não provada e avisar sobre EXEC forçado na base | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved refuses a mixed valid and malformed resolution item' <<< "$t") $(grep -c '^  ok    sdd close omits a finding with any malformed resolution token$' <<< "$g") $(grep -c '^  ok    sdd close does not use a ref as proof for an abbreviated resolution hash$' <<< "$g") $(grep -c '^  ok    sdd run warns on the base before a forced EXEC even when TICKET is pending$' <<< "$g")"` → `1 1 1 1` | done | 234b734 |
| R4 | Achado 1 da r2 — restaurar links do kit depois de mudar o caminho da instalação | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents refreshes a command link from a previous kit installation$' <<< "$p") $(grep -c '^  ok    link-agents restores a dangling kit command link after relocation$' <<< "$p") $(grep -c '^  ok    link-agents preserves conflicting tracked edits and untracked local commands$' <<< "$p")"` → `1 1 1` | done | b23f936 |
| R5 | Achados 1 e 2 da r3 — retomar a migração de links sem substituir comandos locais | `p=$(bash tests/check-preflight.sh 2>&1); echo "$(grep -c '^  ok    link-agents retries a kit relocation after a failed command symlink update$' <<< "$p") $(grep -c '^  ok    link-agents preserves a local command symlink that shares a root with a local planner$' <<< "$p")"` → `1 1` | done | 6ac31be |
| R6 | Achados 1 e 2 da r4 — ignorar exemplos de resolução e entradas que não são arquivos de ADR | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); a=$(bash tests/check-adr.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved distinguishes inline examples from resolution records' <<< "$t") $(grep -c '^  ok    sdd close lists the real resolution and omits its quoted example$' <<< "$g") $(grep -c '^  ok    adr new does not count a directory named like an ADR on another ref$' <<< "$a")"` → `1 1 1` | done | 0426916 |
| R7 | Achado 1 da r5 — distinguir exemplo e prova de resolução em parágrafos distintos | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved keeps inline code within its paragraph' <<< "$t") $(grep -c '^  ok    sdd close distinguishes example and proof in separate TODO paragraphs$' <<< "$g")"` → `1 1` | done | a3518ea |
| R8 | Achado 1 da r6 — processar sequências de linhas vazias sem atrasar a listagem de provas | `t=$(bash tests/check-todo.sh --selftest 2>&1); g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    rule: --resolved bounds work on consecutive blank lines' <<< "$t") $(grep -c '^  ok    sdd close lists the same proof after consecutive blank TODO lines$' <<< "$g")"` → `1 1` | done | 2defd63 |

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
