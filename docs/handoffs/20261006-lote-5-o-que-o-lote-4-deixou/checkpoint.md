---
missao: 20261006-lote-5-o-que-o-lote-4-deixou
atualizado: 2026-10-06 11:31
---

# Checkpoint — Lote 5: o que o lote 4 deixou

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
| I1 | #226: tests/isolate-git.sh carregado pela suíte, pelo catálogo e por todo sensor | `o=$(bash tests/check-health.sh 2>&1); grep -c -e '^  ok    surface: .* clears the repository a git-driven caller hands it' -e '^  ok    surface: every sensor sources tests/isolate-git.sh before its first git' <<< "$o"` → `4` | done | fc763ef |
| I2 | #224: linha com menos de cinco células recusada pelo nome nos dois leitores | `o=$(bash tests/check-checkpoint.sh --selftest 2>&1; bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    rule: a row with fewer than five cells is refused by name' -e '^  ok    the row with fewer than five cells is refused by name' <<< "$o"` → `2` | done | dfd9ab5 |
| I3 | #223: red_norm guarda o array vazio | `o=$(bash tests/check-checkpoint.sh --selftest 2>&1); grep -c '^  ok    red_norm guards its empty array' <<< "$o"` → `1` | done | 802b6d5 |
| I4 | #232: deferred só vale com a decisão escrita no bug | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    .*## Decision' <<< "$o"` → `3` | pending | — |
| I5 | #225: relatório da base exige checkpoint que a missão já teve (ADR 0016 §1) | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    another mission.s report whose squash also edited this mission.s checkpoint is not' <<< "$o"` → `1` | pending | — |
| I6 | #233: a guarda do kit vê o kit sujo editado de novo e diz o que mudou | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    kit-guard: a kit already dirty and edited again' -e '^  ok    kit-guard: the BLOCKED line names the commit' <<< "$o"` → `2` | pending | — |
| I7 | #228 + #227 + decisão 11a: remédio do carimbo impossível; nota intervention só com sessão | `a=$(bash tests/check-autonomy.sh 2>&1); b=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    run stops at an impossible stamp with the remedy that can work' -e '^  ok    sdd run --phase PLAN stops before any session and writes no note' -e '^  ok    the draft jump is the runner' -e '^  ok    run --phase PR stops at the stamp and writes no intervention note' -e '^  ok    sdd retry stopped by the mission ceiling writes no intervention note' -e '^  ok    sdd retry --budget-override buys its session' -e '^  ok    --budget-override on a lap that stops before any session writes no note' -e '^  ok    --budget-override on a lap that opens a session writes exactly one note' -e '^  ok    --budget-override lifted on the draft jump' -e '^  ok    --budget-override over two sessions of one run writes one note' <<< "$a"$'\n'"$b"` → `10` | pending | — |
| I8 | #229 + #230: status cala sem session local; ok do note-manual diz o que fez | `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    a mission with no session in this machine.s ledger ran elsewhere, and the page asks nothing$' -e '^  ok    note-manual.s ok says what the note writer did, and the manual row is written in every case$' <<< "$a"$'\n'"$b"` → `2` | pending | — |
| I9 | #234: o supervisor nomeia quem segura o checkout; turn_rule de toda fase | `a=$(bash tests/check-dry-run.sh 2>&1); b=$(bash tests/check-coordination.sh 2>&1); grep -c -e '^  ok    every projected phase is told a background process holds the run' -e '^  ok    a process the worker leaves behind is named once' -e '^  ok    a hook.s straggler is waited for in silence' <<< "$a"$'\n'"$b"` → `3` | pending | — |
| I10 | #235: o /sdd-plan no próprio kit usa worktree ligado (ADR 0016 §2) | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    command: /sdd-plan moves a mission of the kit sdd runs from into a linked worktree before writing it' <<< "$o"` → `1` | pending | — |
| I11 | Fecho: RESOLVED by nos 12, ADR 0016 aceita, glossário, drift, KAIZEN_LOG, handoff, suíte | `a=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by/{n++} END{print n+0}' TODO.md); b=$(awk '/^## .* — Lote 5: o que o lote 4 deixou/{c++} END{print c+0}' KAIZEN_LOG.md); c=$(awk '/Amended by.*0016/{n++} END{print n+0}' docs/adr/0015-the-stamp-is-not-headless.md); d=$(awk '/^- [*][*]Status[*][*]: accepted/{n++} END{print n+0}' docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/20-handoff-exec.md 2>/dev/null); echo "$a $b $c $d ${f:-0}"` → `12 1 1 1 1` | pending | — |
| I12 | /sdd-plan: commit do que o sdd approve deixa; o relay segura mensagem que não é resposta | `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    command: /sdd-plan commits what sdd approve leaves behind' -e '^  ok    command: /sdd-plan holds a relay message until the next answer' <<< "$o"` → `2` | done | 5df5176 |

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
