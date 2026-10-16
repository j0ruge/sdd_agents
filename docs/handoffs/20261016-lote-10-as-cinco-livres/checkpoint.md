---
missao: 20261016-lote-10-as-cinco-livres
atualizado: 2026-10-16 18:49
---

# Checkpoint — o lote 10: as cinco livres

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
| I1 | #277 e #279 para a seção decidida (decisão 1): dois registros de uma linha com o evento que os reabre, catraca 17 → 15, o cabeçalho do sensor aponta o registro | `a=$(awk '/<!-- sdd:decided -->/{d=1} d && /^- \*\*A regra 2 do check-checkpoint deixa abertos os casos que só o runtime decide\*\* — /{c++} END{print c+0}' TODO.md); b=$(awk '/<!-- sdd:decided -->/{d=1} d && /^- \*\*A regra 2 aceita a âncora seguida de uma expansão no padrão\*\* — /{c++} END{print c+0}' TODO.md); n=$(bash tests/check-todo.sh --count TODO.md 2>/dev/null); k=$(grep -cx 'todo-findings 15' tests/health-baseline.txt); echo "$a $b $n $k"` → `1 1 15 1` | pending | — |
| I2 | a substituição de processo da stderr é mescla (#278): toda grafia do `2>` seguida de `>(` no `r2_merges`, grupo de probes com o seu `rule_ok`, `RULE_FLOOR` 8 → 9, sabotagem, 106 → 106 nos alvos | `o=$(bash tests/check-checkpoint.sh 2>&1); grep -c '^  ok    rule: a process substitution that takes stderr counts as a merge' <<< "$o"` → `1` | pending | — |
| I3 | o `/sdd-plan` corta uma branch provisória e o planner a renomeia na decisão do id (#280); o relay exige `cd <worktree> &&` e confere status e HEAD do checkout principal a cada devolução (#281); dois pares no `check-hat.sh` | `o=$(bash tests/check-hat.sh 2>&1); a=$(grep -c '^  ok    command: /sdd-plan cuts a provisional branch and has the planner rename it' <<< "$o"); b=$(grep -c '^  ok    command: /sdd-plan keeps the planner out of the main checkout' <<< "$o"); echo "$a $b"` → `1 1` | pending | — |
| I4 | fecho: `RESOLVED by` no #278, #280 e #281 (com a skill), medida final nos alvos, `KAIZEN_LOG.md`, gaveta F3, `20-handoff-exec.md` e a suíte inteira | `a=$(grep -c '^## [0-9-]* — Lote 10: as cinco livres$' KAIZEN_LOG.md); b=$(grep -q '20261016-lote-10-as-cinco-livres' KAIZEN_LOG.md; echo $?); c=$(awk '/<!-- sdd:open -->/{o=1} /<!-- sdd:decided -->/{o=0} o && /RESOLVED by [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/{n++} END{print n+0}' TODO.md); d=$(test -f docs/handoffs/20261016-lote-10-as-cinco-livres/20-handoff-exec.md; echo $?); echo "$a $b $c $d"` → `1 0 3 0` | pending | — |

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
