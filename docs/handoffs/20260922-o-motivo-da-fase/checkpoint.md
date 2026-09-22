---
missao: 20260922-o-motivo-da-fase
atualizado: 2026-09-22 18:06
---

# Checkpoint — o motivo da fase

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
| I1 | crase na célula de commit é lida como o SHA (#55) | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a backticked commit cell is read as the SHA it carries' <<< "$o"` → `1` | done | 74e294c |
| I2 | célula que não é SHA ganha motivo próprio + marcador GATE_EXEC_CELL | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a commit cell that is not a SHA gets its own reason' <<< "$o"` → `1` | done | f35189f |
| I3 | derive_phase publica fase e motivo; linha PHASE no journal; contador do TEST_CMD (#56) | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every derived phase writes its reason to the journal' <<< "$o"` → `1` | done | 3245bfd |
| I4 | boot_prompt diz por que a fase foi aberta (toda fase) | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the boot prompt carries the phase reason' <<< "$o"` → `1` | done | bb2a9f7 |
| I5 | kind no-work: célula ilegível para a linha antes da sessão (portas 1 e 3) + contrato do kind | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    door 1: an unreadable cell stops the line before any session' <<< "$o"` → `1` | done | d767689 |
| I6 | mesmo motivo duas vezes para a linha (forma a) + porta 2 no retry inline | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    door 1: the same reason twice stops the line as no-work' <<< "$o"` → `1` | done | 7295ef4 |
| I7 | executor e template: célula nua e caso zero pending; install --force | `grep -c 'no-op commit' agents/sdd-executor.md; cmp -s agents/sdd-executor.md .claude/agents/sdd-executor.md && echo espelho-ok` → `1` (ou mais) e `espelho-ok` | pending | — |
| I8 | replay do incidente + anatomia, CONTEXT D27, KAIZEN_LOG | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    incident replay: a missing commit ends rc 3 no-work with zero sessions' <<< "$o"` → `1` | pending | — |

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
