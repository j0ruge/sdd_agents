---
missao: 20260926-a-carona-antes-do-congelamento
atualizado: 2026-09-26 19:50
---

# Checkpoint — a carona antes do congelamento

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
| I1 | #50 e o yokoten da crase: `**Spec:**`, caminho entre crases e "not a path" no adr_link; nota e Status entre crases no gate_REVIEW e no gate_DOCS | `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    the bold-colon Spec dialect is read by the same rule' <<< "$o"; g=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a backticked grade is read as the grade it carries' <<< "$g"` → `1` e `1` | done | b6cc2bd |
| I2 | #52: sdd approve sem nenhuma resposta sai 66 e não escreve nada; n, Enter e y ficam como estão | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve with no answer at all exits 66 and writes nothing' <<< "$o"` → `1` | done | f935ca5 |
| I3 | #51 parte 1: run_phase e cmd_close exportam GIT_REFLOG_ACTION=sdd:passo:sid8 (session_git_label), a projeção mostra o rótulo | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every session runs under its own git label, the close session too' <<< "$o"; d=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every projected phase labels its git moves with the session' <<< "$d"` → `1` e `1` | done | 0931547 |
| I4 | #51 parte 2: hat_guard_check lê a janela pelo reflog; commit sem rótulo fora do writes para a linha como foreign-commit; sem reflog, como hoje; contrato do kind novo | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a commit without the session label stops the line as foreign-commit, the same commit with it as hat-crossed' <<< "$o"; grep -c '^  ok    without a reflog the guard blames the session as before' <<< "$o"` → `1` e `1` | done | a707b3f |
| I5 | lacuna 2: sem Jira o gate_PLAN recusa branch vazio ou placeholder; fixtures declaram a branch; planner, kaizen, template, schema e pipeline | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    JIRA off with no branch stalls PLAN and names the fix' <<< "$o"; grep -c '^  ok    JIRA on leaves an empty branch to the TICKET phase' <<< "$o"` → `1` e `1` | done | 81d50aa |
| I6 | lacuna 3: run_check_cmd roda o comando com stdin em /dev/null (gates, preflight, E2E) | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    TEST_CMD runs with stdin closed, whatever stdin the caller holds' <<< "$o"` → `1` | done | 1f66743 |
| I7 | faxina: ADRs 0010, 0011 e 0012 accepted; sai o TODO.md:244; entram as lacunas 4 e 5; catraca 83; KAIZEN_LOG; gaveta | `c=$(bash tests/check-todo.sh --count TODO.md); b=$(cat tests/health-baseline.txt); grep -c "^todo-findings $c\$" <<< "$b"; grep -c '^todo-findings 83$' <<< "$b"; a=$(cat docs/adr/0010-o-motivo-da-fase.md docs/adr/0011-ancora-do-todo-carrega-simbolo.md docs/adr/0012-o-commit-tem-dono.md); grep -c '^- \*\*Status\*\*: accepted' <<< "$a"` → `1`, `1` e `3` | pending | — |

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
