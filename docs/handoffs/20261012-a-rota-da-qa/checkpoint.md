---
missao: 20261012-a-rota-da-qa
atualizado: 2026-10-13 14:38
---

# Checkpoint — o lote 7: a rota da QA e o aceite que lê o plano

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
| I1 | a rota do `skipped` declarado (D2): o `qa_substep` devolve `close` quando o `00-missao.md` diz `qa: skipped`, com interface; e o motivo do `skipped` diz o que leu (d) | `a=$(bash tests/check-dry-run.sh 2>&1); b=$(bash tests/check-gates.sh 2>&1); x=$(grep -c '^  ok    a plan that declares qa: skipped goes straight to QA:close with an interface' <<< "$a"); y=$(grep -c '^  ok    the skipped reason names the handoff that declares it' <<< "$b"); echo "$x $y"` → `1 1` | pending | — |
| I2 | o contrato da chave `qa:` (D2): template da missão, `sdd-qa` § 0 e § 2 (confere o diff; visível vira `blocked`), planner, `docs/pipeline.md` | `a=$(bash tests/check-templates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c "^  ok    missao.md: frontmatter key 'qa'" <<< "$a"); y=$(grep -c '^  ok    hat: sdd-qa confirms a declared qa: skipped against the diff' <<< "$b"); echo "$x $y"` → `1 1` | pending | — |
| I3 | a rota do reteste (D3): `qa_fix_ahead_of`, o `qa_substep` devolve `exec` quando um `F<n>` feito não tem commit no relatório da missão depois dele; comentários das skills, tarefa do `QA:exec`, `sdd-qa` § 4 | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    a fix increment done after the closed report sends QA back to exec for the retest' <<< "$o"` → `1` | pending | — |
| I4 | o frescor do handoff de QA (D3): o `gate_QA` recusa, nos dois caminhos, um `30-handoff-qa.md` sem commit depois do último `F<n>` feito; `sdd-qa` reescreve; o fixture do `check-autonomy.sh` e a âncora `bin/sdd:1800` do `TODO.md` acompanham | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    freshness: ' <<< "$o"` → `4` | pending | — |
| I5 | o spec do bug que nenhum agente fecha (f): `sdd-qa` § 3 nomeia o `test.fail()` chamado depois das pré-condições | `o=$(bash tests/check-hat.sh 2>&1); grep -c '^  ok    hat: sdd-qa writes the spec of a bug no agent closes with test.fail' <<< "$o"` → `1` | pending | — |
| I6 | o aceite lê o plano (D4, D5 (h), D8, (a), (b)): o `/sdd-plan` renderiza o plano, refaz `--check`/`--red`, nomeia os ✗ ou diz todos ✅, conta as recomendadas, e o aviso final proíbe prosa | `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    command: /sdd-plan renders the plan' -e '^  ok    command: /sdd-plan names every unmet criterion' -e '^  ok    command: /sdd-plan forbids approval prose' <<< "$o"` → `3` | pending | — |
| I7 | o planner (D4, D5 (g) e (i), D8): `aprovacao:` vazio sob `/sdd-plan` salvo pedido, decisão marcada `(recommended)`/`(other: …)`, regras de nome do alvo, reestimativa a 2×; template da missão | `o=$(bash tests/check-hat.sh 2>&1); grep -c -e '^  ok    hat: the planner marks each grill decision' -e '^  ok    hat: the planner leaves aprovacao empty' -e '^  ok    hat: the planner reads the naming rules' -e '^  ok    command: /sdd-plan re-estimates long work' <<< "$o"` → `4` | pending | — |
| I8 | o carimbo de hora sai de `date` (D6): uma frase no `turn_rule` do `boot_prompt`, lida em toda fase projetada | `o=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every projected phase is told that a timestamp it writes comes from date' <<< "$o"` → `1` | pending | — |
| I9 | o K8 contra a DOCS (D7, D13, D16, D18): com uma linha K8 ✅ ou ⏳ no `## Checklist kaizen` do `00-missao.md` (título seguido de espaço ou fim de linha, fora de cerca; sem K8 na seção, no arquivo), o `gate_DOCS` exige, no diff de cada merge-base até HEAD, um bloco `## ` do `KAIZEN_LOG.md` cujo título e uma linha citando o id inteiro da missão são novos; `sdd-docs` § 3 manda ler o K8, abrir a entrada com o seu `## ` e citar a missão | `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c '^  ok    kaizen-log: ' <<< "$a"); y=$(grep -c '^  ok    hat: the docs hat reads K8 of the plan' <<< "$b"); echo "$x $y"` → `20 1` | pending | — |
| I10 | onde vai o `RESOLVED by` num item no teto (c): os dois templates do `TODO.md` dizem a posição que passa no `check-todo.sh` | `o=$(cat templates/todo.pt-BR.md templates/todo.md); grep -c -e 'nunca numa linha própria' -e 'never on a line of its own' <<< "$o"` → `2` | pending | — |
| I11 | a gramática do id da missão (D17): o `resolve_mission` recusa, em todo comando, um id fora de `^[0-9]{8}-[a-z0-9-]+$` (classe enumerada, lida sem as barras do argumento), a âncora do K8 cita o id sem barras, e o planner e o `/sdd-plan` dizem a gramática | `a=$(bash tests/check-gates.sh 2>&1); b=$(bash tests/check-hat.sh 2>&1); x=$(grep -c '^  ok    mission-id: ' <<< "$a"); y=$(grep -c '^  ok    hat: the planner names the mission id grammar' <<< "$b"); echo "$x $y"` → `5 1` | pending | — |
| I12 | fecho: `CONTEXT.md`, anatomia § 7, gaveta, ADR 0018 `accepted`, `./bin/sdd install --force`, a entrada do `KAIZEN_LOG.md` e o `20-handoff-exec.md` | `a=$(grep -c -E '^## .*Lote 7: a rota da QA' KAIZEN_LOG.md); b=$(grep -c -E '^- [*][*]Status[*][*]: accepted' docs/adr/0018-the-qa-route-and-the-read-plan.md); f=$(awk 'END{print (NR>0)}' docs/handoffs/20261012-a-rota-da-qa/20-handoff-exec.md 2>/dev/null); echo "$a $b ${f:-0}"` → `1 1 1` | pending | — |

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
