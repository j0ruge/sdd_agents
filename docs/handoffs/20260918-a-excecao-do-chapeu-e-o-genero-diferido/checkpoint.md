---
missao: 20260918-a-excecao-do-chapeu-e-o-genero-diferido
atualizado: 2026-09-18 00:00
---

# Checkpoint — a exceção do chapéu e o gênero diferido

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
| I0 | A missão existe para o kit: diretório, branch, ADR 0009 alocado por `sdd adr new` | `./bin/sdd adr check --mission 20260918-a-excecao-do-chapeu-e-o-genero-diferido; echo rc=$?` → `rc=0` | done | `79dd4df` |
| I1 | `HAT_WRITES_EXTRA` no `load_config` + `hat_extra_path_ok` + soma em `hat_writes` + schema/starter | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    HAT_WRITES_EXTRA with ../ is refused' <<< "$o"` → `1` | pending | — |
| I2 | Par diferencial da fronteira no `check-autonomy.sh`, remédio na mensagem, 3 mutantes | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    HAT_WRITES_EXTRA lets the declared path through' <<< "$o"` → `1` | pending | — |
| I3 | `deferred` na Âncora 3, nomes no `GATE_WHY` de sucesso, 4 regimes, `sdd-qa` § 5.1, 1 mutante | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    deferred passes and the reason names the bug' <<< "$o"` → `1` | pending | — |
| I4 | `sdd install` semeia `Closable by:`; `sdd preflight` cobra; 3 regimes, 2 mutantes | `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    install --force seeds Closable by: below Status:' <<< "$o"` → `1` | pending | — |
| I5 | ADR 0009, `Amended by: 0009` na 0006, D26, pipeline, failure-modes, rule § 6 | `grep -c 'Amended by: 0009' docs/adr/0006-*.md` → `1` | pending | — |
| I6 | Yokoten no alvo (passo do humano, depois do merge) | `grep -c HAT_WRITES_EXTRA ~/repos/sales_quote/.sdd/config.sh` → `1` | pending | — |
| I7 | Fecha: `TODO.md` (4 RESOLVIDO), `ACHADOS`, `KAIZEN_LOG.md` | `o=$(bash tests/check-todo.sh 2>&1); grep -c '^  ok    105 finding(s)' <<< "$o"` → `1` | pending | — |

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
