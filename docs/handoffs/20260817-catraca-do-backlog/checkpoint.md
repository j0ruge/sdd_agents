---
missao: 20260817-catraca-do-backlog
atualizado: 2026-08-17 17:44
---

# Checkpoint — a catraca do backlog

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> O runner imprime `  ok   ` com TRÊS espaços; nenhum Check daqui lê saída do runner.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | sensor `check-health.sh` sobre `cmd_health` | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet fails on a stale baseline line' <<< "$o"` → `1` | pending | — |
| I2 | catraca da contagem de achados | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    a baseline off by one fails both ways' <<< "$o"` → `1` | pending | — |
| I3 | cinco defeitos de saída do `cmd_autonomy` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output:' <<< "$o"` → `5` | pending | — |
| I4 | mutações que faltam no catálogo | `grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' tests/check-mutation.sh` → `77` | pending | — |
| I5 | política escrita e baseline no número real | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet policy is written where the next mission meets it' <<< "$o"` → `1` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-17 17:44 · `PLAN` · Os cinco Checks foram rodados contra o HEAD `6d68dfc` no
  planejamento e **os cinco deram vermelho**: I1 `0`, I2 `0`, I3 `0`, I4 `70`, I5 `0`. Registrado
  porque o `TODO.md` traz um achado aberto sobre o gate PLAN-AUTO aceitar Check que já nasce verde.
- 2026-08-17 17:44 · `PLAN` · Âncoras do cluster 1 re-derivadas: as do `TODO.md` estão ~870 linhas
  defasadas. A tabela correta está no `01-plano.md`, seção "Contexto verificado". Não use as do
  `TODO.md`.
- 2026-08-17 17:44 · `PLAN` · O esperado `77` do I4 é derivado (`70 + 2 + 1 + 4`). Se a
  re-derivação do I4 fechar item por evidência em vez de por código, recalcule e registre aqui.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
