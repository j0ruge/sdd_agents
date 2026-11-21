# Handoff do lote L2 — fechado em 2026-11-21 01:58

**Missão:** `20261120-l2-o-sdd-plan-e-o-planner`: o relay do `/sdd-plan` e o `sdd-planner` ganham regra escrita
com asserção para os 14 itens do lote e um 15º (`model: fable` no chapéu); o `--red` ganha `--list` e `--only`.
**PR #456** entrou por merge commit em `6198b68`, no `ready 794ec54` do `pr-ready`, pelo worker sob a
delegação `full`.

## O que custou

- **Corridas (`sdd run`, duas):** 15 sessões, 22 022 s, US$ 38,03 (ledger, `LC_ALL=C`), contra um teto de US$ 60.
  - A primeira (2026-11-20 16:20 → 23:56) saiu com rc 3 em PR. As duas sessões do publisher bloquearam no
    conflito da catraca com a `main` (`tests/health-baseline.txt`), e o ledger gravou o `kind`
    `budget-exhausted`, que aqui é o teto de sessões da fase, não o de dinheiro (item novo do L5b).
  - A segunda (2026-11-21 00:22 → 01:09) rodou depois de o worker mesclar a `main` (`4b60b47`, catraca 106) e
    de um `sdd preflight` com rc 0. Saiu com rc 2: o PR aberto, só o carimbo faltando.
  - EXEC: 8 sessões em `xhigh`, US$ 27,89. São I1 a I6, mais o I7 (`3672ea89`), nascido do gate vermelho
    porque o `EFFORT_EXEC` exportado no lançamento chegava às fixtures, mais o R1.
  - QA: 1 sessão, 843 s, US$ 1,50, sem interface.
  - REVIEW: 2 sessões, US$ 5,16. A r1 (US$ 3,80) deu B em Error Handling e abriu o R1. A r2 (US$ 1,36), delta,
    deu A: razão r2/r1 de 0,36.
  - DOCS: 1 sessão em `medium`, 252 s, sem `⛔`.
  - PR: 3 sessões, US$ 1,22 (duas bloqueadas pelo conflito, uma que abriu o PR).
- **O teste de effort:** veredito no `KAIZEN_LOG.md` (2026-11-21). O `xhigh` custou 1,8× por item sem ganho
  no critério escrito antes. A EXEC volta a `medium` do L3 em diante.
- **Atos do worker, fora dos dois tetos:**
  - `pr`: o corpo do PR levou as decisões 1, 5, 6 e 7 do grill, os relays de config (`220648f`, `5569266`), o
    I7 como commit fora do plano, e os achados fora de escopo. O Copilot não revisou, por falta de cota.
  - `review`: o CodeRabbit deixou 6 achados sobre `cec8c9b`, 1 Major e 5 Minor. Cinco foram consertados
    (`00b8fad`, `4c44ac6`, `a1d4338`, `7a168ad`), com 5 asserções e a sabotagem das duas metades do `--only`.
    O sexto foi refutado: o Check do I6, linha `done`, não é re-rodado. A r3 do worker foi **inteira**, por
    causa do merge da `main` depois da r2, e deu A em todo critério, sem `R<n>`. A primeira suíte saiu rc 1
    com 4 FAIL no `check-autonomy` (`kit-touched`), porque a rodada foi escrita no worktree durante a suíte.
    A segunda, com a árvore parada, deu rc 0 (2 237 ok). O Codex deu completed sem achado no `cec8c9b` e no
    `794ec54`. O CodeRabbit não revisou o head dos consertos.
  - `merge`.

## O que foi para o pós-merge

O chore `chore/l2-pos-merge` cobre:
- os 16 itens resolvidos apagados: os 14 do lote, o do I7 e o da DOCS, cada hash ancestral da `main`. A catraca
  vai de 106 para 90, e de volta a 91 com o item do `budget-exhausted`;
- os 6 LOW da r4 do #454 e o "fora do diff", os 6 achados da r3 do L2, e o terceiro sensor que lia o `EFFORT_*`
  herdado (`check-gates.sh`, `EFFORT_TICKET`), reproduzido com 2 FAIL e consertado;
- as listas do `campaign.md`: o `rm` de `$(…)` e as skills do grill → L5c, os hooks do preflight → L4, o `run`
  sem preflight e o `budget-exhausted` → L5b;
- o `KAIZEN_LOG.md` (o veredito do effort e a razão r2/r1), este diário e este handoff.

Fica para o dono aceitar, pelo corpo do PR do chore: o texto da anatomia § 3 (`544ff8c`). O espelho de issues
precisa de re-sync, porque o título de um item do L5b mudou.

## O próximo lote

O L3 ("Gates do fim da linha", 13 itens, 5 `◆`) está em plano. A missão é `20261121-l3-gates-do-fim-da-linha`,
no branch `fix/l3-gates-do-fim-da-linha`, worktree `~/repos/sdd_agents-l3`, cortado de `6198b68`. O planner roda
em Fable, e o grill foi respondido pela recomendada, delegado, em 12 de 12. A EXEC roda em `medium`. O `sdd run`
só começa depois de este chore mergear e de a `main` entrar no branch do L3, com o `--check` e o `--red` de novo.
