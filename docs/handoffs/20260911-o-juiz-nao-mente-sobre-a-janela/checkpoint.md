---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
atualizado: 2026-09-12 13:05
---

# Checkpoint — o juiz não mente sobre a janela

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` cru na célula do Check.** A tabela é lida com `awk -F'|'`: um pipe cru parte a
> célula em duas, o Status lido passa a ser um pedaço do comando e o Commit passa a ser `pending`.
> Check que precisaria de pipe vira herestring:
> `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto responde
> "a asserção existe", nunca "a asserção passou".
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.
>
> ⚠️ **A ordem importa.** I1 é pré-requisito de tudo: sem ledger limpo e protegido, nenhum número
> de I2–I5 vale. I6 é o **último**, e o `sdd health` roda depois dele — `tests/health-baseline.txt`
> está dentro da chave do carimbo de mutação.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | Ledger real inescrivível por fixture, e as 11 linhas `/tmp` saem | `grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl` → `0` | done | 5956e80 |
| I2 | `$order` e `comparable_row` concordam por asserção diferencial | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    differential' <<< "$o"` → `1` ou mais | done | 7e6b3f5 |
| I3 | `reopened` e a fronteira do laço de revisão leem a população que prometem | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    reopened' <<< "$o"` → `1` ou mais | done | 392f526 |
| I4 | `sdd close` e `sdd retry` escrevem a linha de ledger que devem | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    close writes' <<< "$o"` → `1` ou mais | done | aa3c0a2 |
| I5 | A guarda recusa fatia com duas versões de harness e percebe janela rompida | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    guard: two harness' <<< "$o"` → `1` ou mais | done | 5e3c427 |
| I6 | Dez itens de dívida declarada saem para o cabeçalho do sensor dono; catraca 105 → 95 | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    95 finding(s)' <<< "$o"` → `1` | done | 4d9b7b8 |
| R1 | r1 #1 — a linha `event:"close"` entra no total do cabeçalho de `sdd autonomy` e não cai em bucket nenhum | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the buckets still sum to the header total (a close row)' <<< "$o"` → `1` ou mais | done | 1563bc8 |
| R2 | r1 #2 — a exclusão `$meta` (KAIZEN) infla o mesmo total, e o comentário ao lado afirma o contrário | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    the buckets still sum to the header total (a judge KAIZEN row)' <<< "$o"` → `1` ou mais | done | a26d489 |
| R3 | r1 #3 — `window_missions_stranded` falha aberto na missão que atravessa o sha julgado | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    guard: a mission straddling the kit change is stranded' <<< "$o"` → `1` ou mais | done | 154f58f |
| R4 | r1 #4 — o juiz aprende a ler `why`, `harness` e a janela rompida; espelho por `sdd install --force` | `grep -c 'window_broken' agents/sdd-kaizen.md` → `1` ou mais | done | 477cb9a |
| R5 | r1 lote dos achados #6–#9 — custo na linha de `close`, porta do chapéu cruzado, regime de `close` no juiz, contagens podres | `o=$(bash tests/run-all.sh 2>&1); a=$(grep -c '^  ok    close row carries cost_usd' <<< "$o"); b=$(grep -c '^  ok    close writes its row even when the hat guard fires' <<< "$o"); c=$(grep -c '^  ok    guard: a close row mints no version and no mission' <<< "$o"); echo "$a$b$c"` → `111` | done | c78b167 |

> **As notas de execução não moram aqui.** Elas ficam em `checkpoint-notas.md`, ao lado deste
> arquivo, append-only, e o prompt de boot inlina as últimas 10 — a sessão nunca abre aquele
> arquivo. Este aqui é a **tabela** que o runner parseia, e só ela.

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
