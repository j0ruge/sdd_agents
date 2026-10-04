---
missao: 20261003-lote-3-a-catraca-desce
atualizado: 2026-10-04 09:07
---

# Checkpoint — Lote 3: a catraca desce

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
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``, e o `tests/check-checkpoint.sh` recusa as duas formas
> nos checkpoints deste repo.
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
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | 13 saídas decididas sem doc acoplado; catraca 57 → 44 | `o=$(bash tests/check-todo.sh 2>&1); a=$(grep -c '^  ok    44 finding(s)' <<< "$o"); n=$(awk '/<!-- sdd:decided -->/{d=1;next} d && /^- [*][*]/{c++} END{print c+0}' TODO.md); b=$(awk '/^todo-findings 44$/{c++} END{print c+0}' tests/health-baseline.txt); echo "$a $n $b"` → `1 18 1` | done | 8577df6 |
| I2 | 4 saídas com doc acoplado (#143, #123, #124, #158); catraca 44 → 40 | `o=$(bash tests/check-todo.sh 2>&1); a=$(grep -c '^  ok    40 finding(s)' <<< "$o"); b=$(awk '/^. Y[56] /{c++} END{print c+0}' CONTEXT.md); c=$(awk '/O critério [(]4[)] da D7/{c++} END{print c+0}' CONTEXT.md); d=$(awk '/coordenada, está no/{c++} END{print c+0}' .claude/rules/anatomia-do-agente.md); echo "$a $b $c $d"` → `1 2 0 0` | done | db2eee1 |
| I3 | 5 limites declarados nos cabeçalhos (#66, #77, #90, #125, #140); catraca 40 → 35 | `o=$(bash tests/check-todo.sh 2>&1); n=0; for f in tests/check-health.sh tests/check-todo.sh tests/run-all.sh tests/check-pipefail.sh tests/check-lang.sh; do s=$(awk '/20261003-lote-3-a-catraca-desce/{c++} END{print c+0}' "$f"); [ "$s" -gt 0 ] && n=$((n+1)); done; echo "$(grep -c '^  ok    35 finding(s)' <<< "$o") $n"` → `1 5` | done | 4af9d0c |
| I4 | /sdd-plan: protocolo de repasse + aviso de trabalho longo (decisões 3 e 10) | `a=$(awk '/^## Relaying the grill to the human/{c++} END{print c+0}' commands/sdd-plan.md); b=$(awk '/^- [*][*]Long work between two questions:[*][*]/{c++} END{print c+0}' commands/sdd-plan.md); c=$(awk '/the session that delegated you is the relay/{c++} END{print c+0}' agents/sdd-planner.md); o=$(bash tests/check-checkpoint.sh 2>&1); d=$(grep -c '^  ok    the planner agent teaches the ok-anchor rule' <<< "$o"); cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md && m=same; echo "$a $b $c $d ${m:-diff}"` → `1 1 1 1 same` | done | 921e95e |
| I5 | #113 resíduo: calibrate() enxerga os 16 sensores | `o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    the ok anchor is the prefix the suite.s sensors actually print (16 sensor(s))' <<< "$o"` → `1` | done | 0521972 |
| I6 | #211: Check com test -f num caminho ignorado reprova | `bash tests/check-checkpoint.sh --selftest && grep -c 'a Check that tests an ignored path is caught' tests/check-checkpoint.sh` → `1` | done | 41ac7a1 |
| I7 | #216: done abaixo de blocked reprova | `bash tests/check-checkpoint.sh --selftest && grep -c 'a done below a blocked row is caught' tests/check-checkpoint.sh` → `1` | done | 9e521d1 |
| I8 | #212: template cita o --check do kit + linha do planner | `o=$(bash tests/check-templates.sh 2>&1); a=$(grep -c '^  ok    checkpoint.md: the checkpoint sensor cited in its --check form' <<< "$o"); b=$(awk '/check-checkpoint.sh --check/{c++} END{print c+0}' agents/sdd-planner.md); cmp -s agents/sdd-planner.md .claude/agents/sdd-planner.md && m=same; echo "$a $b ${m:-diff}"` → `1 1 same` | done | bf660f8 |
| I9 | #217a: check-todo --baseline, diff chaveado | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a --baseline run fails only on what the ref did not have (6 probe(s))' <<< "$o"` → `1` | pending | — |
| I10 | #217b: a ref resolve as âncoras contra o repo real | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    rule: a --baseline run fails only on what the ref did not have (7 probe(s))' <<< "$o"` → `1` | pending | — |
| I11 | #127: chaves de caminho normalizadas e validadas no load_config | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    path key [A-Z0-9_]*: ' <<< "$o"` → `8` | pending | — |
| I12 | #115: gate_REVIEW escopado + gate_DOCS recusa 45-docs.md sujo | `o=$(bash tests/check-gates.sh 2>&1); a=$(grep -c '^  ok    a dirty tree a later phase left does not send the mission back to REVIEW → DOCS$' <<< "$o"); b=$(grep -c '^  ok    an uncommitted 45-docs.md holds DOCS, it does not ride to PR → DOCS$' <<< "$o"); echo "$a $b"` → `1 1` | pending | — |
| I13 | #63: gênero do bug lido do bloco do Status | `o=$(bash tests/check-gates.sh 2>&1); a=$(grep -c '^  ok    the genre is read from the Status block: ' <<< "$o"); b=$(grep -c '^  ok    a whole header quoted inside a fence above the real one does not become the genre' <<< "$o"); echo "$a $b"` → `2 1` | pending | — |
| I14 | #121: porta do kaizen aceita worktree do kit; kaizen_reminder vira achado (catraca 35 → 36) | `o=$(bash tests/check-kaizen.sh 2>&1); a=$(grep -c '^  ok    kit-repo guard: ' <<< "$o"); b=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && index($0,"- [ ] ")==1 && /kaizen_reminder/{c++} END{print c+0}' TODO.md); t=$(bash tests/check-todo.sh 2>&1); e=$(grep -c '^  ok    36 finding(s)' <<< "$t"); f=$(awk '/^todo-findings 36$/{c++} END{print c+0}' tests/health-baseline.txt); echo "$a $b $e $f"` → `2 1 1 1` | pending | — |
| I15 | #213: kaizen --series recusa com frase e arquivo | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    series: .* is refused with rc 1, naming the file' <<< "$o"` → `2` | pending | — |
| I16 | #87: preflight cobra total_cost_usd e num_turns numéricos | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    a result line ' <<< "$o"` → `3` | pending | — |
| I17 | #169: um controle por assassino do mapa, ele na frente | `o=$(tests/check-mutation.sh --anchors 2>&1); grep -c '^  ok    controls: one control per distinct killer of the map' <<< "$o"` → `1` | pending | — |
| I18 | #192a: --touched seleciona os mutantes dos sensores tocados | `o=$(tests/check-mutation.sh --anchors 2>&1); grep -c '^  ok    touched: the diff selects the mutants its sensors killed' <<< "$o"` → `1` | pending | — |
| I19 | #192b: --touched roda o assassino, dá veredito e dica | `o=$(SDD_KILLERS_FILE=tests/fixtures/killers-touched.tsv tests/check-mutation.sh --touched 6ad41f7~1..6ad41f7 2>&1); grep -c '^  ok    touched: 2 of 2 selected mutant(s) still caught by their killer' <<< "$o"` → `1` | pending | — |
| I20 | Fecho: RESOLVED by nos 13, KAIZEN_LOG, 20-handoff-exec.md, suíte inteira | `bash tests/run-all.sh >/dev/null 2>&1; r=$?; o=$(bash tests/check-todo.sh 2>&1); k=$(awk '/^todo-findings /{print $2}' tests/health-baseline.txt); a=$(grep -c "^  ok    $k finding(s)" <<< "$o"); n=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by [0-9a-f]{7}/{c++} END{print c+0}' TODO.md); d=$(awk '/<!-- sdd:decided -->/{d=1;next} d && /^- [*][*]/{c++} END{print c+0}' TODO.md); g=$(awk '/20261003-lote-3-a-catraca-desce/{c++} END{print (c>0)}' KAIZEN_LOG.md); echo "$r $a $n $d $g"` → `0 1 13 20 1` | pending | — |

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
