# Handoff do lote L1b — fechado em 2026-11-20 16:04

**Missão:** `20261119-l1b-a-rodada-delta`, só o #436: da segunda rodada em diante a REVIEW revisa o delta
desde o `reviewed_head:` da rodada anterior (ADR 0023, que emenda a §5 da 0022). **PR #452** entrou por
merge commit em `079bc39`, no `ready 9be3e94` do `pr-ready`, pelo worker sob a delegação `full`
(`lots: all`, #451).

## O que custou

- **Corrida (`sdd run`, 08:30 → 15:07):** 11 sessões, US$ 18,92 de um teto de US$ 60. Saiu com `rc=2`: o PR
  estava aberto e faltava só o carimbo, que missão do kit dispensa. Nenhuma escalada.
  - EXEC: 6 sessões em `medium` (5 do plano e o R1): 1 837, 3 077, 2 112, 1 315, 1 620 e 2 880 s.
  - QA: 1 sessão, 1 266 s, sem interface.
  - REVIEW: 2 sessões. A r1 (1 116 s, US$ 2,24) deu B em Error Handling e abriu o R1; a r2 (1 179 s,
    US$ 2,16) deu A, já como rodada delta.
  - DOCS: 1 sessão em `medium`, 132 s, com uma linha `⛔` (a anatomia).
  - PR: 1 sessão, 2 423 s.
  - Negativas do harness: um `DENIED REVIEW tool=Bash` na r1 (o `rm` de um `$(…)`, refeito com o caminho
    literal) e um `DENIED REVIEW tool=Read` na r2 (um `references/` da skill `codereview`, sem `READ_EXTRA`).
    Viraram itens no branch do L2 (`b91d13d`, `c83ad3d`).
- **Atos do worker, fora dos dois tetos:**
  - `pr`: as decisões 2, 7, 9 e 10 do grill foram para o corpo do PR; o Copilot não revisou, por falta
    de cota; o texto `⛔` da anatomia foi aplicado pelo worker em `feb1078`, para o aceite do dono.
  - `review`: a `main` entrou sem conflito (`59be5eb`); os 7 comentários do CodeRabbit (1 Major: a
    rodada não commitada servia de base do delta) foram consertados em 7 commits, com 7 asserções e 8
    mutantes novos; suíte verde em `f6ea5fe`; a r3 do worker foi **inteira** (o merge da `main` no
    intervalo) e deu A em todo critério; o recibo do Codex veio limpo no `9be3e94`.
  - `merge`.

## O que foi para o pós-merge

O chore `chore/l1b-pos-merge` cobre:
- o #436 apagado (`RESOLVED by a3d0b72`, ancestral da `main`) e a catraca de 98 para 97;
- os 4 LOW da r3: o `git status` do `review_base_line` sem `GIT_OPTIONAL_LOCKS=0` (também `RECURRED 1` no
  item aberto do `sdd status --no-gates`), o intervalo do `review_head_ok` sem `core.quotePath=false`, a
  quarta recusa ausente da prosa e o ramo "git status cannot say" sem cenário;
- um item novo para o L5b: o ato `review` do worker mergeia a base antes da rodada, então o
  `review-base` responde `full` toda vez que a `main` andou, e a rodada do worker, a mais cara, nunca
  chega a ser delta;
- este diário.

Os três itens que a corrida do L1b abriu, e o das skills do grill do L2, estão no branch do L2 e não na
`main`: as linhas deles nas listas do `campaign.md` (A → L5c, B1 → L4, B2 → L5b, skills → L5c) vão no chore
do L2.

## O próximo lote

O L2 (`20261120-l2-o-sdd-plan-e-o-planner`) está aprovado (`b7c68b5`) no worktree `~/repos/sdd_agents-l2`,
com a `main` mergeada (`20ada71`, catraca 102) e o relay do `EFFORT_EXEC` em `220648f`. Roda com
`EFFORT_EXEC=xhigh BUDGET_MISSION_USD=60`, depois do `sdd preflight` no worktree, e é a primeira missão
cuja REVIEW roda com o runner do L1b: a razão r≥2/r1 do `KAIZEN_LOG.md` nasce dela (decisão 7 do L1b).
