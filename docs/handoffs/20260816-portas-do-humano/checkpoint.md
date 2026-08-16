---
missao: 20260816-portas-do-humano
atualizado: 2026-08-16 21:15
---

# Checkpoint — as portas de controle do humano

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`. O `gate_EXEC` reprova por "invalid status" e o
> `sdd status` imprime algo de aparência saudável — custou uma missão inteira até alguém olhar.
> Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
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
| I1 | `sdd approve`: o gate humano ganha comando | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve' <<< "$o"` → `3` | pending | — |
| I2 | o runner troca para a branch declarada | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    branch ' <<< "$o"` → `3` | pending | — |
| I3 | `sdd retry` vira a quarta porta com aviso | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    retry ' <<< "$o"` → `2` | pending | — |
| I4 | plano kaizen-born nunca se auto-aprova | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    kaizen-born' <<< "$o"` → `3` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 21:15 · `PLAN` · os 4 Checks rodados contra o HEAD (`c2c8e73`): todos `0`
  (vermelhos), `tests/check-gates.sh` verde (rc 0) — nenhum Check nasce verde.
- 2026-08-16 21:15 · `PLAN` · prefixos de asserção são contrato com os Checks: `sdd approve `,
  `branch `, `retry `, `kaizen-born` — nomear exatamente assim em `tests/check-gates.sh`.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
