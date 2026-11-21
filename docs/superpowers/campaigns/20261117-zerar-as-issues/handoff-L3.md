# Handoff do lote L3 — fechado em 2026-11-21 17:21

**Missão:** `20261121-l3-gates-do-fim-da-linha`. Os gates do fim da linha (`gate_EXEC`, `gate_QA`, `gate_REVIEW`,
`gate_PR`) passam a ler o head que conferem (ADR 0024, emenda da 0023), e o `TEST_CMD` que não rodou deixa de ser
suíte vermelha. São 13 itens do `TODO.md` em 9 incrementos.
**PR #458** entrou por merge commit em `86e16c0`, no `ready c378415` do `pr-ready`, pelo worker sob a delegação
`full`.

## O que custou

- **Corrida (`sdd run`, uma):** 15 sessões, 34 939 s, US$ 37,03 (ledger e log da corrida, `LC_ALL=C`), contra um
  teto de US$ 60. Saiu com rc 2 às 15:2x: o PR aberto, só o carimbo faltando.
  - EXEC: 10 sessões em `medium`, US$ 27,32. São I1 a I9, mais o R1.
  - QA: 1 sessão, US$ 1,19, sem interface.
  - REVIEW: 2 sessões, US$ 5,60. A r1 deu B em Error Handling (2 MEDIUM) e abriu o R1; a r2, delta, deu A.
  - DOCS: 1 sessão, US$ 2,38, com 1 `⛔` (a anatomia § 4).
  - PR: 1 sessão, US$ 0,55.
- **Atos do worker, fora dos dois tetos:**
  - `pr`: o `⛔` da anatomia § 4 foi aplicado pelo worker (`0125046`) e marcado no corpo para o aceite do dono.
  - `review`:
    - O CodeRabbit deixou 15 achados inline e 1 "unverified" sobre `4ef8e23`. Um subagente os conferiu: 13
      consertados com asserção e mutante (`0143fec`, `e41809f`, `bfbc460`, `39ad63f`), 2 refutados no thread, e o
      "unverified" foi ao `TODO.md`.
    - A r3 do worker (delta sobre `39ad63f`) deu A.
    - O Codex deu 1 P2 no `f2559cb`, o 126/127 de uma linha só sobre a árvore suja, que a r3 tinha como LOW. O
      worker o consertou em TDD (`3000409`).
    - A r4 (delta sobre `3000409`) deu A, e o Codex deu completed sem achado no `c378415`.
    - O Copilot não revisou, por falta de cota. O CodeRabbit também não revisou `4ef8e23..f2559cb` (*"Review
      limit reached"*), mas resolveu sozinho 12 threads, todos já conferidos pelo relatório do lote.
  - `merge`.

## O que foi para o pós-merge

O chore `chore/l3-pos-merge` cobre:
- o `TODO.md`:
  - os 13 itens do lote saem pelo `--fix --write` da skill `todo-to-github-issues`. A quebra automática em 120
    colunas partia duas linhas `RECURRED`, e o sensor as recusava; elas foram reunidas à mão;
  - entram 3 itens: o rename que esconde caminho no `review_head_ok` e no `hat_diff_names`, o handoff já
    `blocked` que compra uma sessão, e o `sdd approve` com o `branch:` no placeholder fora da base;
  - a catraca vai de 91 para 81;
- o lote de prosa das r3 e r4 do L3 e da r5 do chore do L2: o comentário do `test_cmd_red_why` com os dois
  limites declarados, a linha do journal do `dirty-tree`, o escopo da seção do `failure-modes.md`, os contadores
  do `KAIZEN_LOG.md` e da anatomia (954 mutantes; 28 da missão), a linha F6 da gaveta, e o
  `commands/sdd-plan.md` sobre de onde a TICKET corta;
- este diário, com a correção do custo da linha das 15:24, e este handoff.

Fica para o dono aceitar, pelo corpo do PR do chore:
- o texto `⛔` da anatomia § 4 (`0125046`, contadores corrigidos aqui);
- a inversão do I1 do plano do L3 (`3000409`): o 126/127 "não rodou" arma a parada da árvore suja;
- o texto novo do `commands/sdd-plan.md` sobre o relay fora da base.

O espelho de issues sincroniza depois do último merge do dia.

## O próximo lote

O L4 ("Preflight, health e sensores") está aprovado (`d70ee5d`). A missão é
`20261121-l4-preflight-health-e-sensores`, no branch `fix/l4-preflight-health-e-sensores`, worktree
`~/repos/sdd_agents-l4`. A `main` do L3 entrou no branch em `9931c77`, e o `--red` deu 13 de 13 vermelhos, iguais
ao medido no plano. O `sdd run` sai depois do `./bin/sdd preflight` com rc 0, com a EXEC em `medium`. O `next` também
responde `ahead plan L5`.
