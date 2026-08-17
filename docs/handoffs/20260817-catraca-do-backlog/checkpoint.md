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
| I1 | sensor `check-health.sh` sobre `cmd_health` | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet fails on a stale baseline line' <<< "$o"` → `1` | done | afe5db6 |
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
- 2026-08-17 19:52 · `I1` · Catálogo em **72** como o plano previu, então o `77` do I4 segue de pé
  (`72 + 1` do I2 `+ 4` do I4). `sdd health` → `kit healthy`, `score: 72 caught, 0 known gap(s)`.
- 2026-08-17 19:52 · `I1` · **Desvio do plano, deliberado:** a asserção 4 chama-se `provenance
  fails when the fixture diverges from an installed skill`, não "...when an installed skill is
  missing". Skill ausente **não reprova** — `health_provenance` a PULA por desenho (`bin/sdd:1806`),
  como o linter ausente é pulado. Escrita contra o caminho que de fato falha, e diferencial.
- 2026-08-17 19:52 · `I1` · O fixture hermético achou **dois abortos calados do `sdd health`**: com
  `~/.claude/plugins/cache` ausente o `find` devolve 1, e com baseline sem linha viva o `grep -vE`
  também — sob `set -e` + `pipefail` os dois matam o comando no meio, rc 1 e nenhuma palavra dita.
  Fora de escopo (I1 é o sensor, não o conserto): foi para o `TODO.md`, e o fixture modela máquina
  com o diretório, com o porquê comentado em `reset_home()`.
- 2026-08-17 19:52 · `I1` · **Custo medido, e é o risco da tabela do plano acontecendo:** o sensor
  roda em **1,5 s** sozinho (dentro do teto de 2 s), mas a suíte foi de **2m34s para 7m15s** —
  porque roda dentro dos 73 mutantes (+4 s cada) e a contenção é super-linear. Aceito e registrado
  no `TODO.md`: o sensor cabe no seu orçamento, o multiplicador é do harness de mutação e a saída
  ("rodar por mutante só o sensor que o alcança") é decisão do humano, junto com o alvo da D7.
- 2026-08-17 19:52 · `I1` · Três pisos de superfície andaram junto com o arquivo novo, o que o
  plano não listou: `LINT_FLOOR` 14→15, `check-pipefail` 13→14 e `check-lang` 36→37. O do
  `check-pipefail` arrastou o fixture do próprio selftest, construído **exatamente** no piso —
  três probes passaram a falhar com "surface shrank" em vez de medir o que nomeiam. Quem for
  acrescentar sensor à suíte de novo: são quatro lugares, não um.
- 2026-08-17 19:52 · `I1` · Sabotagem adversarial: **9 probes, 9 vermelhos**. Toda asserção morre
  em pelo menos uma, e a 3 (diferencial) e a 5 (piso) morrem **sozinhas** em probes próprios —
  nenhuma das duas é redundante. O par que o plano previu se confirmou: `ratchet_one_way` mata a 2
  e a 3 e deixa a 1 viva. Cada mutação foi verificada matando a suíte **só** por este sensor
  (`1 suite(s) failed`), não por rc compartilhado com outro.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
