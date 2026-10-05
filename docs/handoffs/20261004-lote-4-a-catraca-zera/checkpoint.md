---
missao: 20261004-lote-4-a-catraca-zera
atualizado: 2026-10-04 23:47
---

# Checkpoint — Lote 4: a catraca zera

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
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Saídas por decisão escrita: #88 Y7, #130, #155, #109; catraca 23 → 19 | `o=$(bash tests/check-todo.sh 2>&1); a=$(grep -c '^  ok    19 finding(s)' <<< "$o"); b=$(awk '/^todo-findings 19$/{c++} END{print c+0}' tests/health-baseline.txt); c=$(awk '/^. Y7 /{c++} END{print c+0}' CONTEXT.md); d=$(awk '/<!-- sdd:decided -->/{d=1;next} d && /^- [*][*]/{c++} END{print c+0}' TODO.md); e=$(awk '/DECLARED LIMIT [(]D15[)], moved here from TODO.md in 20261004-lote-4-a-catraca-zera/{c++} END{print c+0}' tests/check-templates.sh); f=$(awk '/se desfez em 2026-10-04/{c++} END{print c+0}' docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md); echo "$a $b $c $d $e $f"` → `1 1 1 23 1 2` | done | b120607 |
| I2 | #180 + #218: commit de registro no checkpoint; token adiado (Y8); catraca 19 → 17 | `o=$(bash tests/check-templates.sh 2>&1); a=$(grep -c '^  ok    checkpoint.md: an act outside git commits a record' <<< "$o"); b=$(grep -c '^  ok    checkpoint.md: a step after the merge or in an external window leaves the table' <<< "$o"); h=$(bash tests/check-hat.sh 2>&1); c=$(grep -c '^  ok    hat: the executor commits a record for an act outside git' <<< "$h"); t=$(bash tests/check-todo.sh 2>&1); d=$(grep -c '^  ok    17 finding(s)' <<< "$t"); e=$(awk '/^todo-findings 17$/{c++} END{print c+0}' tests/health-baseline.txt); f=$(awk '/^. Y8 /{c++} END{print c+0}' CONTEXT.md); g=$(awk '/commits a RECORD/{c++} END{print c+0}' agents/sdd-planner.md); cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md && cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md && m=same; echo "$a $b $c $d $e $f $g ${m:-diff}"` → `1 1 1 1 1 1 1 same` | done | a1e4f12 |
| I3 | #194: o executor sabota a linha nova de um R<n> | `o=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    hat: the executor sabotages the new line of an R<n>' <<< "$o"); b=$(awk '/^[0-9][.] [*][*]Sabotage/{c++} END{print c+0}' agents/sdd-executor.md); cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md && m=same; echo "$a $b ${m:-diff}"` → `1 1 same` | pending | — |
| I4 | #178 + #135: o ticket para de prometer o acli; comentário de código tem dono; catraca 17 → 16 | `o=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    hat: the ticket hat promises no Jira check the gate does not make' <<< "$o"); b=$(grep -c '^  ok    hat: the docs hat leaves a code comment to the code' <<< "$o"); c=$(awk '/DECLARED LIMIT [(]D15[)].*this gate never asks Jira/{c++} END{print c+0}' bin/sdd); t=$(bash tests/check-todo.sh 2>&1); d=$(grep -c '^  ok    16 finding(s)' <<< "$t"); e=$(awk '/^todo-findings 16$/{c++} END{print c+0}' tests/health-baseline.txt); cmp -s agents/sdd-ticket.md .claude/agents/sdd-ticket.md && cmp -s agents/sdd-docs.md .claude/agents/sdd-docs.md && m=same; echo "$a $b $c $d $e ${m:-diff}"` → `1 1 1 1 1 same` | pending | — |
| I5 | A âncora mede só o símbolo designado (#191) | `o=$(bash tests/check-todo.sh 2>&1); grep -c -e '^  ok    rule: an anchor designates one symbol, and only that symbol is measured' -e '^  ok    [0-9]* finding(s), all within 8 lines, carrying anchor + date, every anchor on target' <<< "$o"` → `2` | pending | — |
| I6 | decisão 7: o /sdd-plan pergunta YES/NO e roda o sdd approve | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan asks the human YES or NO before it runs sdd approve' <<< "$o"` → `1` | pending | — |
| I7 | #92a: check-checkpoint --red recusa Check que nasce verde | `o=$(bash tests/check-checkpoint.sh 2>&1); r=$?; a=$(grep -c '^  ok    rule: a Check already green at HEAD is refused by --red' <<< "$o"); echo "$r $a"` → `0 1` | pending | — |
| I8 | #92b+#93: o planner mede o vermelho; critério d e regra de redação | `o=$(bash tests/check-checkpoint.sh 2>&1); a=$(grep -c '^  ok    the planner agent teaches the --red run before PLAN-AUTO' <<< "$o"); t=$(bash tests/check-templates.sh 2>&1); b=$(grep -c '^  ok    missao.md: PLAN-AUTO criterion d cites the --red run' <<< "$t"); cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md && m=same; echo "$a $b ${m:-diff}"` → `1 1 same` | pending | — |
| I9 | #95: o starter.conf sugere o lint do TODO.md no TEST_CMD | `o=$(bash tests/check-preflight.sh 2>&1); a=$(grep -c '^  ok    the TODO.md lint the starter suggests runs as a TEST_CMD' <<< "$o"); b=$(awk '/check-todo[.]sh. --check/{c++} END{print c+0}' config/starter.conf); c=$(awk '/Opt-in: the .TODO[.]md. lint inside .TEST_CMD./{c++} END{print c+0}' config/schema.md); echo "$a $b $c"` → `1 1 1` | pending | — |
| I10 | #134: ADRs 0003/0004/0006 ganham Spec:, 11 missões adr: none, ADR_CHECK=block | `o=$(env -u CLAUDECODE ./bin/sdd adr check 2>/dev/null); a=$(grep -c 'have no decided' <<< "$o"); b=$(grep -c '^  ok    ADR_CHECK=block, ' <<< "$o"); c=$(awk '/^Spec: docs[/]handoffs[/]/{c++} END{print c+0}' docs/adr/0003-judge-axis-evidence-from-target-repos.md docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md docs/adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md); echo "$a $b $c"` → `0 1 3` | pending | — |
| I11 | MEC: kaizen_reminder num worktree do kit | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    reminder: a linked worktree of the kit answers with the kit sentence' <<< "$o"` → `1` | pending | — |
| I12 | #67: agents/ na chave do carimbo | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    stamp-key: a commit touching only agents/ moves the key' <<< "$o"` → `1` | pending | — |
| I13 | #142+#198a: o sdd run para no carimbo | `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    run stops at the stamp' -e '^  ok    gate_PR: the mutation stamp is demanded only where the catalogue lives' <<< "$o"` → `4` | pending | — |
| I14 | #142+#198b: o publisher não roda o health | `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    hat: the publisher never runs the stamp' -e '^  ok    hat: and the stamp is no reason for the publisher' -e '^  ok    hat: and the PR body carries the order' <<< "$o"` → `3` | pending | — |
| I15 | #129a: runner_sha em toda linha do ledger | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    ledger: every row carries the launch-time runner' <<< "$o"` → `1` | pending | — |
| I16 | #129b: o config relido no topo de cada volta | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    config: the next lap runs the edited TEST_CMD' <<< "$o"` → `1` | pending | — |
| I17 | os dois leitores aprendem o evento `manual` | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-kaizen.sh 2>&1; env -u CLAUDECODE TMPDIR=/tmp bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    guard: a manual row mints no version' -e '^  ok    the human reader names the manual row' <<< "$o"` → `2` | pending | — |
| I18 | `sdd note-manual` escreve a nota e a linha `manual` | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-autonomy.sh 2>&1; env -u CLAUDECODE TMPDIR=/tmp bash tests/check-coordination.sh 2>&1); grep -c -e '^  ok    sdd note-manual writes one note committed alone' -e '^  ok    busy: note-manual' <<< "$o"` → `2` | pending | — |
| I19 | o `sdd status` sugere o `note-manual` | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    the full page names the green phases with no session' -e '^  ok    a manual row of the phase takes it off the page' <<< "$o"` → `2` | pending | — |
| I20 | relatório na ponta da base pergunta quem o adicionou | `o=$(env -u CLAUDECODE TMPDIR=/tmp bash tests/check-gates.sh 2>&1); grep -c '^  ok    a report from the base tip counts only when the commit that added it carries this mission dir' <<< "$o"` → `1` | pending | — |
| I21 | #141+#108a+decisão 8: check-lang lê docs/ por censo, piso derivado, commands/*.md na régua | `o=$(bash tests/check-lang.sh 2>&1); r=$?; a=$(grep -c '^  ok    census: every tracked docs/' <<< "$o"); b=$(grep -c '^  ok    self-test: the census refuses' <<< "$o"); c=$(grep -c '^  ok    0 of ' <<< "$o"); s=$(awk '/^SURFACE_SPECS=/,/[)]$/' tests/check-lang.sh); d=$(awk 'index($0, "commands/*.md"){n++} END{print n+0}' <<< "$s"); e=$(awk '/Este reposit/{n++} END{print n+0}' commands/sdd-plan.md); f=$(awk '/n_surface" -lt [0-9]/{n++} END{print n+0}' tests/check-lang.sh); echo "$r $a $b $c $d $e $f"` → `0 1 1 1 1 0 0` | pending | — |
| I22 | #108b: LINT/pipefail/CALIBRATE declaram o limite | `n=0; for f in tests/run-all.sh tests/check-pipefail.sh tests/check-checkpoint.sh; do s=$(awk '/anti-vacuity, not a tracker of the surface/{c++} END{print c+0}' "$f"); [ "$s" -gt 0 ] && n=$((n+1)); done; c=$(awk '/Entra lá. são quatro lugares/{p=1} p && /CALIBRATE_FLOOR/{c++} /quinto lugar é o/{p=0} END{print c+0}' CLAUDE.md); echo "$n $c"` → `3 1` | pending | — |
| I23 | Toda chave da série nomeada no pipeline.md (#98) | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c -e '^  ok    every series key is named in docs/pipeline.md' -e '^  ok    and every name in that block is a key the series prints' <<< "$o"` → `2` | pending | — |
| I24 | Fecho: RESOLVED by, emendas da ADR, glossário, drift, KAIZEN_LOG, handoff, suíte | `a=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by/{n++} END{print n+0}' TODO.md); b=$(awk '/^## .* — Lote 4: a catraca zera/{c++} END{print c+0}' KAIZEN_LOG.md); c=$(cat docs/adr/0004-*.md docs/adr/0011-*.md docs/adr/0013-*.md docs/adr/0014-*.md); d=$(awk '/Amended by.*0015/{n++} END{print n+0}' <<< "$c"); e=$(awk '/^- [*][*]Status[*][*]: accepted/{n++} END{print n+0}' docs/adr/0015-the-stamp-is-not-headless.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261004-lote-4-a-catraca-zera/20-handoff-exec.md 2>/dev/null); echo "$a $b $d $e ${f:-0}"` → `16 1 4 1 1` | pending | — |

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
