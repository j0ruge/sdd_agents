---
missao: 20261002-onde-o-comando-do-humano-escreve
atualizado: 2026-10-02 10:38
---

# Checkpoint — Onde o comando do humano escreve

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
| I1 | #186: o mundo da ida e volta roda sob rótulo REVIEW armado pelo sensor | `o=$(GIT_REFLOG_ACTION=sdd:REVIEW:deadbeef bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    a round trip through another branch inside the window is not a crossing' -e '^  ok    the round-trip world runs under an armed session label' <<< "$o"` → `2` | done | 4815fe0 |
| I2 | #157: o probe de sinal nasce com SIGINT ignorado e o filho o recebe em SIG_DFL | `o=$(bash -c 'tests/check-coordination.sh 2>&1 & wait $!'); grep -c -e '^  ok    signal status: 2' -e '^  ok    signal recovers: 2' -e '^  ok    the signal probes start with SIGINT ignored, as a detached launch leaves it' <<< "$o"` → `3` | done | d0a6aa4 |
| I3 | #193: a nota de intervenção cria o temporário só no ramo que o usa | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c -e '^  ok    the intervention note leaves no temporary file behind' -e '^  ok    the notes-file path writes the note with an unwritable TMPDIR' <<< "$o"` → `2` | done | 813f808 |
| I4 | #182: o close sem JIRA confere o PR e volta à base | `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    close: with JIRA off the tree goes back to the default branch' -e '^  ok    close: with JIRA off an unmerged PR is still refused' <<< "$o"` → `2` | done | 46919f6 |
| I5 | #81: frontmatter_write recusa symlink, avisa no chmod e lê o valor por ENVIRON | `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    sdd approve refuses a symlinked 00-missao.md and writes nothing' -e '^  ok    frontmatter_write warns when it cannot keep the mode' <<< "$o"` → `2` | done | ce1d2ed |
| I6 | #173: o install nunca escreve através de agente ligado, link quebrado incluído | `o=$(bash tests/check-preflight.sh 2>&1); grep -c -e '^  ok    install --force never writes through a linked agent' -e '^  ok    install never creates a file through a dangling link' <<< "$o"` → `2` | done | e303e4f |
| I7 | #156: o approve entra na branch declarada e commita o diretório da missão | `o=$(bash tests/check-gates.sh 2>&1); grep -c -e '^  ok    sdd approve commits the mission directory and nothing else' -e '^  ok    sdd approve with JIRA off lands on the declared branch' -e '^  ok    sdd approve refuses a declared branch that carries another plan' -e '^  ok    sdd approve with a placeholder branch stays, warns and commits the whole directory' <<< "$o"` → `4` | done | a64a69c |
| I8 | #112 parte 1: todo passo da suíte tem prazo, e o estouro é vermelho nomeado | `o=$(bash tests/check-health.sh 2>&1); grep -c -e '^  ok    surface: a step that outlives its timeout is red and named, and the suite goes on' -e '^  ok    surface: every step of the suite carries a timeout' -e '^  ok    surface: an interrupt still stops the suite while a step runs' <<< "$o"` → `3` | done | a3d3996 |
| I9 | #112 parte 2: dentro do mutante o estouro é inconclusivo, nunca pego | `o=$(bash tests/check-health.sh 2>&1); grep -c -e '^  ok    surface: inside a mutant a timeout is not a kill' -e '^  ok    surface: the catalogue reads a timed-out mutant as inconclusive, never caught' <<< "$o"` → `2` | done | 8449ab8 |
| I10 | TODO.md: RESOLVED by nos oito itens, achado do adr_declare e catraca +1 | `awk '/RESOLVED by [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/ {n++} END {print n + 0}' TODO.md; o=$(bash tests/check-todo.sh 2>&1); n=$(sed -n 's/^todo-findings //p' tests/health-baseline.txt); grep -c "^  ok    $n finding(s), all within 8 lines" <<< "$o"` → `8` e `1` | pending | — |

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
