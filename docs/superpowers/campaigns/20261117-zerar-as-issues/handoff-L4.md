# Handoff do lote L4 — fechado em 2026-11-22 09:57

**Missão:** `20261121-l4-preflight-health-e-sensores`. O `sdd preflight` deixa de afirmar o que não mediu,
o `sdd run` e o `sdd retry` param antes da sessão que o harness vai negar, o juiz do `sdd kaizen` passa
pela guarda do chapéu, e quatro sensores recusam o que deixavam passar. São 15 itens do `TODO.md` em 13
incrementos e um `R1`.
**PR #464** entrou por merge commit em `cef90b1`, no `ready 5c8436a` do `pr-ready`, pelo worker sob a
delegação `full`.

## O que custou

- **Corrida (`sdd run`, duas por causa da pausa):** 20 sessões, 34 518 s, US$ 46,51 (linhas `session` da
  missão no ledger, `LC_ALL=C`), contra um teto de US$ 60.
  - A primeira corrida saiu com rc 3 às 04:25 (`handoff-blocked` na PR): o publisher parou num conflito
    com a `main` (5a4f76f) no `TODO.md` e na F6 da gaveta. Com a autorização do dono, o worker o
    resolveu pela união (`67d69db`) e apagou o `50-pr.md` bloqueado (`4ea7018`).
  - O dono pausou o `sdd run` às 08:08 para guardar os tokens da semana, e às 08:29 liberou só o fim do
    L4. A segunda corrida (só a PR) saiu com rc 2 às 09:10: o PR aberto, só o carimbo faltando.
  - EXEC: 14 sessões em `medium`, US$ 34,51. São I1 a I13, mais o R1.
  - QA: 1 sessão, US$ 1,25, sem interface.
  - REVIEW: 2 sessões, US$ 6,21. A r1 deu 12 LOW e abriu o R1 (seis num lote); a r2, delta, deu A.
  - DOCS: 1 sessão, US$ 3,46, com 1 `⛔` (a anatomia §2, §4, §6 e §7).
  - PR: 2 sessões, US$ 1,08 (a do bloqueio e a da reabertura).
- **Atos do worker, fora dos dois tetos:**
  - `pr`: o corpo ganhou "Revisores e atos do worker": o CodeRabbit (rate limited) e o Copilot (sem
    cota) não revisaram, e o que toca regra do dono foi destacado (a decisão 3 muda todo alvo, o
    `CLAUDE.md` editado direto pela DOCS em `8a36baa`).
  - `review`:
    - O `⛔` da anatomia foi aplicado pelo worker com o texto proposto da DOCS (`e0b17e5`).
    - O `sdd review-base` deu `full` (o merge `84cdd5a` depois da r2). A r3 inteira, por subagente
      (sonnet), focou no que ninguém revisou depois da r2, sem rodar a skill por arquivo, e deu B em
      Documentation por três LOW de prosa (`db861e4`).
    - O lote dos três LOW (`221b8f7`) e a r4 delta, A em todo critério (`5c8436a`).
    - O Codex deu completed sem achado em `5c8436a`.
  - `merge`.

## O que foi para o pós-merge

O chore `chore/l4-pos-merge` cobre:
- o `TODO.md`: os 15 itens do lote saem pelo `--fix --write` da skill `todo-to-github-issues`, com a linha
  `RECURRED` do item do `sdd adr new` reunida à mão depois do wrap de 120 colunas, e a catraca vai de 86
  para 71;
- os seis LOW da r5 do #460 (o exemplo do 127 no `check-gates.sh`, os três sítios do `test_cmd_red_why`, o
  `TMPDIR` do `DECLARED LIMIT`, a conta do lote do CodeRabbit no diário e no `handoff-L3.md`, a frase
  vencida do L1 na F6, os vizinhos e a atribuição no `TODO.md`) e o Minor do CodeRabbit no #460 (o limiar
  do 126/127 no `docs/failure-modes.md`);
- os contadores do `KAIZEN_LOG.md` e a F6 da gaveta com o merge do L4;
- o diário desde o `ccacdc3` (27 linhas) e este handoff.

Fica para o dono aceitar, pelo corpo do PR do L4 (#464):
- as escolhas feitas sob delegação, a decisão 3 à frente;
- o texto `⛔` da anatomia (`e0b17e5`);
- o yokoten: todo alvo sem a entrada do `codereview` no `READ_EXTRA` para no primeiro `sdd run`.

O PR #463 (o item do `$1` trocado no `/sdd-worker`, catraca +1) espera o merge do dono. O espelho de
issues sincroniza depois do último merge do dia.

## O próximo lote

O L5 (`20261121-l5-saida-humana-e-contrato-do-runner`, ADR 0025 no branch dele) está aprovado (`ec0f995`),
no worktree `~/repos/sdd_agents-l5`. O `sdd run` dele espera o fim da semana, por decisão do dono (sobra de
tokens). Antes de lançar: `git merge origin/main` no branch, e de novo `--anchors`, `--check` e `--red`
(pendência 1 do `00-missao.md` dele).
