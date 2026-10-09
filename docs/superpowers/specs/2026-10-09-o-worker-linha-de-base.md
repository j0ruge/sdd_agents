# Linha de base do worker noturno — como as missões `sdd` rodaram no `sales_quote`

> Medido em 2026-10-09, somente leitura, sobre o ledger de autonomia (`~/.sdd/autonomy-log.jsonl`,
> 636 linhas, 347 do `sales_quote`), os journals `.sdd/logs/<missão>/pipeline.log`, os
> artefatos em `docs/handoffs/<missão>/` e os 21 PRs das missões no GitHub
> (`JRC-Brasil/sales_quote`, privado). Objetivo: saber, pelo histórico, onde o humano foi de fato
> necessário e o que um worker sem humano na sala (spec
> `docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md`, W1–W7) teria encontrado.

## TL;DR

- **21 missões, US$ 1 636 no runner.** Por missão: mediana **US$ 52,94**, p90 **US$ 159,38**;
  sessões mediana **15** (p90 22); tempo de máquina mediana **2,6 h** (p90 4,3 h). Até 2026-09-18 a
  mediana era US$ 84; desde 2026-09-24, US$ 35.
- **Só 4 de 21 (19 %) foram do TICKET ao PR sem toque humano.** 16 missões precisaram de mais de um
  `sdd run`: 46 relançamentos antes do PR, mediana de 10 min entre parar e relançar (o humano estava
  olhando). As 11 esperas acima de 30 min somam 35,4 h, e 29,2 h delas são quatro noites inteiras.
- **25 escaladas rc 3** (KIT 12 · decisão humana 9 · ambiente 4) e **27 paradas sem escalada**
  (operador 14 · ambiente 7 · decisão 3 · sem explicação 2 · kit 1). `sdd retry` nunca foi usado;
  `app-down` e `session-died` nunca dispararam.
- **8 das 25 escaladas foram concorrência no checkout do humano:** 6 `kit-touched` (o kit editado
  durante a corrida) e 2 sujeiras de outra sessão. O clone dedicado elimina 2. Os 6 `kit-touched`
  pedem um **kit fixo** para o worker, coisa que nenhum degrau W1–W7 nomeia hoje.
- **O ambiente é a dependência universal.** As 18 missões com interface rodaram e2e contra o stack
  que o humano deixou no ar, e não existe `ENV_UP_CMD` (só `stack:check`) → **W4**. O único
  `sdd run` lançado por `systemd-run` morreu com rc 127 (nvm fora do PATH), que é o regime do timer
  → **W6**.
- **9 missões (43 %) pararam por decisão humana ou por teto de custo:** 8 por decisão e 1
  (`destino-frete-cif`) por teto. Nelas o worker tem de parar e avisar, mas `ON_ESCALATION_CMD`
  está **vazio** no `sales_quote`.
- **Bots:** o Copilot revisou 0 de 21 PRs (cota) e o CodeRabbit não aparece em nenhum. O Codex
  revisou 12 de 21, achou algo em 10 (14 achados, P1 = 6), sempre numa leva só e em 3–5 min.
  10 de 21 PRs (48 %) ganharam commit de conserto depois de abertos → **W7**.
- **Estimativa:** com W2, W4 e W6 prontos e o kit de hoje, ≈ **12 de 21 (57 %)** teriam chegado ao
  PR sozinhas. É contrafactual e aproximada (ver §5.1).

## 1. Fontes e o que cada uma consegue dizer

| Fonte | O que dá | O que não dá |
|---|---|---|
| Ledger (`event: session/blocked/gate_pass/manual/close`) | sessão por fase, custo, duração, `gate`/`gate_why`, `run_id` (um por `sdd run`), `invocation` (`run`/`retry`/`note-manual`/`close`), `kind` da escalada, `kit_sha`, `harness` (desde 2026-09-06), `runner_sha` (desde 2026-10-05), `rounds_after` (desde 2026-09-02), `step`/`step_after` da QA | o que o humano fez entre dois lançamentos; sessão morta antes da linha (1 caso); `--phase`/`--max-phases` antes do lote 5 (não deixava nota); trabalho interativo fora do runner |
| `pipeline.log` | as mesmas sessões (312 × 311 no ledger — a diferença é 1 sessão de EXEC da `aviso-diretoria`, US$ 1,08, cujo `sdd run` morreu antes de gravar a linha), `PHASE reason=` (desde 2026-09-22), `KIT-TOUCHED`/`HAT-CROSSED`/`HAT-REMEDY`, `CLOSE` | idem |
| `checkpoint-notas.md` / `checkpoint.md` | notas `intervention:` (as do runner dizem `written by the runner`), narrativa do que o humano decidiu | só existe quando alguém escreveu; antes do lote 5 o runner só escrevia a nota do `--budget-override` |
| GitHub (`gh pr view`, `gh api …/pulls/<n>/comments`) | data de abertura e merge, revisores, achados inline do Codex (com P1/P2), commits empurrados depois da abertura | quem empurrou (humano interativo × sessão); tempo humano de leitura |

Escopo: as **21 missões do `sales_quote` com linha no ledger** (2026-08-25 → 2026-10-06). Ficam fora:
o piloto `20260814-sq94-spinner-reblur` (anterior ao ledger; pelo journal: 11 sessões, US$ 72,47,
PR #105) e sete pastas de `docs/handoffs/` que nunca passaram pelo `sdd run`
(`20260908-cliente-fala-com-o-erp…`, `20260914-destino-cif-e-coleta-fob`,
`20260915-aprovacao-sem-logistica`, `20260916-release-notes-0.8.0`, `20260917-release-notes-0.8.1`,
`20260922-aceite-po-storage`, `20260928-painel-gerencial`) — trabalho interativo ou abandonado.

Conferência cruzada: soma das sessões no journal (era do ledger) = US$ 1 633,45; no ledger =
US$ 1 632,38 + 1 sessão ausente (US$ 1,08) = US$ 1 633,46. Os dois instrumentos concordam ao centavo.

## 2. Tabela por missão

Legenda: **lanç.** = `run_id` distintos com `invocation: run` (lançamentos de `sdd run` que deixaram
ao menos uma linha — aproximação por baixo); **sessões T/E/Q/R/D/P** = TICKET/EXEC/QA/REVIEW/DOCS/PR;
**US$ total** inclui o `sdd close` (sessão paga, pós-merge) quando houve; **rodadas R** = arquivos
`40-review-r<N>.md` da missão (o campo `rounds_after` do ledger só existe desde 2026-09-02);
**kit shas** = versões distintas do kit carimbadas nas linhas da missão; **Codex achados** =
comentários inline do `chatgpt-codex-connector[bot]`; **commits de conserto pós-PR** = commits com
`committedDate` > abertura do PR, menos o commit do próprio publisher ("PR #N aberto…").

| # | missão | início | span h | lanç. | sessões T/E/Q/R/D/P | US$ total | US$ E / Q / R | escaladas (kind@fase) | manual | rodadas R | QA sess. | kit shas | harness | PR | Codex achados | commits de conserto pós-PR |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `20260825-cif-forma-pagamento` | 08-25 02:06 | 0.1 | 1 | 1/1/0/0/0/0 (2) | 6.94 | 5.7 / 0 / 0 | increment-blocked@EXEC×1 | — | 0 | 0 | 2 | — | — | — | — |
| 2 | `20260825-frete-cif-fob` | 08-25 21:27 | 13.4 | 2 | 1/7/12/1/1/1 (23) | 144.88 | 34 / 73.3 / 22.4 | no-progress@QA×1 | — | 1 | 12 | 1 | — | #127 merged | 0 | 0 |
| 3 | `20260827-condicoes-pagamento-mesmo-cliente` | 08-27 17:33 | 3.7 | 3 | 1/1/2/1/1/1 (7) | 76.48 | 11.8 / 21.8 / 37.3 | — | — | 1 | 2 | 1 | — | #132 merged | 0 | 0 |
| 4 | `20260830-a-tela-que-mente-o-pagamento` | 08-30 22:38 | 2.7 | 1 | 1/2/1/2/1/1 (8) | 84.42 | 14.9 / 12.6 / 47.8 | — | — | 1 | 1 | 1 | — | #137 merged | 0 | 0 |
| 5 | `20260830-invariante-do-frete-no-agregado` | 08-30 13:42 | 2.6 | 3 | 1/2/1/1/1/1 (7) | 44.43 | 10 / 15.3 / 11.1 | — | — | 1 | 1 | 1 | — | #135 merged | 0 | 0 |
| 6 | `20260830-o-rascunho-fantasma-do-mount` | 08-30 16:45 | 2.1 | 1 | 1/3/1/1/1/1 (8) | 47.11 | 15 / 11.4 / 13.5 | — | — | 1 | 1 | 1 | — | #136 merged | 0 | 0 |
| 7 | `20260902-o-rascunho-legado-fala-cru` | 09-02 18:26 | 5.3 | 4 | 1/9/1/4/1/2 (18) | 174.11 | 67.1 / 10.1 / 88.3 | budget-exhausted@REVIEW×2, no-progress@PR×1 | — | 4 | 1 | 1 | — | #139 merged | 0 | 0 |
| 8 | `20260906-o-contato-sobrevive-ao-notfound` | 09-06 10:26 | 4.7 | 2 | 4/4/1/3/1/1 (14) | 64.62 | 20.1 / 10.2 / 22.5 | no-progress@TICKET×1 | — | 3 | 1 | 2 | 2.1.263 | #143 merged | 0 | 0 |
| 9 | `20260906-o-pagamento-e-do-consultor` | 09-06 18:34 | 2.3 | 2 | 2/3/1/1/1/1 (9) | 50.88 | 22.1 / 7.3 / 11.7 | increment-blocked@EXEC×1 | — | 1 | 1 | 1 | 2.1.263 | #144 merged | 0 | 0 |
| 10 | `20260907-o-descarte-do-pagamento-fala` | 09-07 01:25 | 10.6 | 5 | 1/11/1/4/0/0 (17) | 152.3 | 88.7 / 9.2 / 53 | budget-exhausted@REVIEW×3 | — | 4 | 1 | 1 | 2.1.263 | #145 merged | 1 | 2 |
| 11 | `20260916-destino-frete-cif` | 09-16 15:45 | 4.7 | 6 | 1/18/3/3/1/0 (26) | 170.32 | 117.1 / 15.9 / 27.7 | hat-crossed@QA×1, no-progress@QA×1 | — | 3 | 3 | 1 | 2.1.273 | #167 merged | 1 | 4 |
| 12 | `20260916-quatro-silencios-da-tela` | 09-16 23:31 | 12.9 | 12 | 1/15/1/3/1/1 (22) | 127.92 | 63.2 / 14.7 / 38.6 | hat-crossed@DOCS×1 | — | 3 | 1 | 1 | 2.1.273 | #168 merged | 1 | 1 |
| 13 | `20260917-papeis-consultor-admin` | 09-18 00:57 | 7.6 | 4 | 1/16/1/2/1/1 (22) | 159.38 | 107.1 / 16.9 / 25.8 | budget-exhausted@DOCS×1, hat-crossed@DOCS×1, increment-blocked@EXEC×1, kit-touched@PR×1 | — | 2 | 1 | 2 | 2.1.274 | #172 merged | 4 | 2 |
| 14 | `20260924-todo-no-esqueleto` | 09-24 16:53 | 1.9 | 4 | 1/12/1/3/1/1 (19) | 50.03 | 33 / 1.5 / 5.5 | kit-touched@EXEC×1, no-work@REVIEW×1 | — | 1 | 1 | 2 | 2.1.282 | #180 merged | 1 | 0 |
| 15 | `20260924-transacao-honra-o-timeout` | 09-24 21:59 | 0.9 | 2 | 1/8/1/1/1/1 (13) | 25.97 | 13.3 / 1.6 / 2.2 | no-progress@EXEC×1 | — | 1 | 1 | 1 | 2.1.282 | #377 merged | 0 | 0 |
| 16 | `20260927-breadcrumb-numero-cotacao` | 09-27 17:48 | 4.2 | 1 | 1/4/2/2/1/1 (11) | 18.66 | 5.4 / 2.8 / 2.8 | — | — | 2 | 2 | 1 | 2.1.283 | #382 merged | 1 | 1 |
| 17 | `20260928-ver-vira-olho-na-lista` | 09-28 08:35 | 2.2 | 1 | 1/2/1/1/1/1 (7) | 13.31 | 2.5 / 2.1 / 1.4 | — | — | 1 | 1 | 1 | 2.1.283 | #383 merged | 1 | 1 |
| 18 | `20260929-aviso-diretoria-por-email` | 09-29 17:45 | 5.3 | 3 | 1/11/4/3/1/1 (21) | 52.94 | 21.8 / 6.8 / 15.1 | — | — | 3 | 4 | 1 | 2.1.283 | #395 merged | 1 | 1 |
| 19 | `20260930-e2e-local-diz-por-que-caiu` | 09-30 19:46 | 2.8 | 2 | 1/6/4/2/1/1 (15) | 23.18 | 5.9 / 6 / 2.7 | — | — | 2 | 4 | 2 | 2.1.283 | #401 merged | 2 | 2 |
| 20 | `20260930-justificativa-pedido-alcada` | 09-30 11:29 | 3.7 | 2 | 1/8/5/3/2/1 (20) | 43.31 | 10.7 / 12.9 / 8 | hat-crossed@REVIEW×1 | — | 2 | 5 | 1 | 2.1.283 | #398 merged | 1 | 2 |
| 21 | `20261005-mascaras-ncm-e-painel` | 10-05 20:00 | 13.2 | 6 | 0/12/7/1/1/1 (22) | 104.88 | 36.2 / 57.1 / 10 | kit-touched@EXEC×2, kit-touched@QA×2 | TICKET | 1 | 7 | 4 | 2.1.289 | #406 merged | 0 | 15 |

`retry` (`invocation: retry`): **zero** linhas em todo o histórico do `sales_quote` — `sdd retry`
nunca foi usado. `auto_retry: true`: zero. `session_error` (sessão morta pelo harness): zero.
`rc != 0`: zero. Escaladas `app-down`, `session-died`, `dirty-tree`, `handoff-blocked`,
`retry-gate-red`, `foreign-commit`: **nenhuma**. `degraded`: nenhuma (`PUBLISH_ON_REVIEW_BLOCKED=off`).

### 2.1 Lançamentos (como cada `sdd run` terminou)

`end` é a última linha do `run_id`: `rc3:<kind>@<fase>` = escalada; `PR-open(rc0)` = sessão de PR
com gate verde; `stopped-after:<fase>/<gate>` = o processo terminou sem escalada e sem PR (fase
única pedida pelo operador, Ctrl-C, ou morte do processo — o ledger não distingue).

| missão | n | invocação | início → fim | sessões | US$ | fases | fim |
|---|---|---|---|---|---|---|---|
| `cif-forma-pagamento` | 1 | run | 08-25 02:06 → 02:14 | 2 | 6.94 | EXEC TICKET | rc3:increment-blocked@EXEC |
| `frete-cif-fob` | 1 | run | 08-25 21:27 → 00:33 | 20 | 108.89 | EXEC QA TICKET | rc3:no-progress@QA |
| `frete-cif-fob` | 2 | run | 08-26 10:11 → 10:47 | 3 | 35.98 | DOCS PR REVIEW | PR-open(rc0) |
| `condicoes-pagamento-mesmo-cliente` | 1 | run | 08-27 17:33 → 18:21 | 3 | 27.33 | EXEC QA TICKET | stopped-after:QA/fail (E2E_CMD failed (npm run e2e) — see /home/joruge/repos/sales_quote/.sdd) |
| `condicoes-pagamento-mesmo-cliente` | 2 | run | 08-27 19:24 → 19:24 | 1 | 37.3 | REVIEW | stopped-after:REVIEW/pass (40-review-r1.md all Grade A, suite green, tree clean) |
| `condicoes-pagamento-mesmo-cliente` | 3 | run | 08-27 20:31 → 21:14 | 3 | 11.84 | DOCS PR QA | stopped-after:QA/fail (E2E_CMD failed (VITE_API_BASE_URL='http://localhost:3007/api/sales-quo) |
| `a-tela-que-mente-o-pagamento` | 1 | run | 08-30 22:38 → 01:19 | 8 | 84.42 | DOCS EXEC PR QA REVIEW TICKET | PR-open(rc0) |
| `invariante-do-frete-no-agregado` | 1 | run | 08-30 13:42 → 13:42 | 1 | 1.72 | TICKET | stopped-after:TICKET/pass (issue SQ-112 in the sprint) |
| `invariante-do-frete-no-agregado` | 2 | run | 08-30 13:50 → 14:41 | 3 | 25.35 | EXEC QA | stopped-after:QA/pass (report 2026-08-24-sq107-status-material-frete.md closed, registry clea) |
| `invariante-do-frete-no-agregado` | 3 | run | 08-30 15:36 → 16:17 | 3 | 17.36 | DOCS PR REVIEW | PR-open(rc0) |
| `o-rascunho-fantasma-do-mount` | 1 | run | 08-30 16:45 → 18:51 | 8 | 47.11 | DOCS EXEC PR QA REVIEW TICKET | PR-open(rc0) |
| `o-rascunho-legado-fala-cru` | 1 | run | 09-02 18:26 → 22:12 | 14 | 139.27 | EXEC QA REVIEW TICKET | rc3:budget-exhausted@REVIEW |
| `o-rascunho-legado-fala-cru` | 2 | run | 09-02 22:46 → 22:46 | 1 | 27.83 | REVIEW | stopped-after:REVIEW/fail (40-review-r4.md: Documentation = B — the gate requires Grade A on ever) |
| `o-rascunho-legado-fala-cru` | 3 | run | 09-02 23:32 → 23:37 | 1 | 4.31 | DOCS | rc3:budget-exhausted@REVIEW |
| `o-rascunho-legado-fala-cru` | 4 | run | 09-02 23:43 → 23:43 | 2 | 2.71 | PR | rc3:no-progress@PR |
| `o-contato-sobrevive-ao-notfound` | 1 | run | 09-06 10:26 → 10:34 | 3 | 3.39 | TICKET | rc3:no-progress@TICKET |
| `o-contato-sobrevive-ao-notfound` | 2 | run | 09-06 12:32 → 15:07 | 11 | 61.23 | DOCS EXEC PR QA REVIEW TICKET | PR-open(rc0) |
| `o-pagamento-e-do-consultor` | 1 | run | 09-06 18:34 → 18:52 | 3 | 10.5 | EXEC TICKET | rc3:increment-blocked@EXEC |
| `o-pagamento-e-do-consultor` | 2 | run | 09-06 19:13 → 20:54 | 6 | 40.37 | DOCS EXEC PR QA REVIEW | PR-open(rc0) |
| `o-descarte-do-pagamento-fala` | 1 | run | 09-07 01:25 → 04:11 | 11 | 104.49 | EXEC QA REVIEW TICKET | stopped-after:EXEC/fail (1 of 8 increment(s) still to execute) |
| `o-descarte-do-pagamento-fala` | 2 | run | 09-07 10:37 → 10:50 | 2 | 19.06 | EXEC REVIEW | rc3:budget-exhausted@REVIEW |
| `o-descarte-do-pagamento-fala` | 3 | run | 09-07 11:04 → 11:04 | 1 | 3.97 | EXEC | stopped-after:EXEC/fail (TEST_CMD failed (npm test && npm run lint && npm run build) — see /hom) |
| `o-descarte-do-pagamento-fala` | 4 | run | 09-07 11:12 → 11:12 | 0 | 0 |  | rc3:budget-exhausted@REVIEW |
| `o-descarte-do-pagamento-fala` | 5 | run | 09-07 11:36 → 12:01 | 3 | 24.78 | EXEC REVIEW | rc3:budget-exhausted@REVIEW |
| `destino-frete-cif` | 1 | run | 09-16 15:45 → 16:42 | 12 | 72.46 | EXEC QA TICKET | rc3:hat-crossed@QA |
| `destino-frete-cif` | 2 | run | 09-16 16:56 → 17:05 | 3 | 13.6 | EXEC QA | rc3:no-progress@QA |
| `destino-frete-cif` | 3 | run | 09-16 17:50 → 18:46 | 8 | 62.88 | EXEC REVIEW | stopped-after:EXEC/pass (17 increment(s) done, suite green, handoff written) |
| `destino-frete-cif` | 4 | run | 09-16 19:02 → 19:02 | 1 | 4.53 | REVIEW | stopped-after:REVIEW/pass (40-review-r3.md Grade A on every criterion, at least B on the prose on) |
| `destino-frete-cif` | 5 | run | 09-16 19:27 → 19:27 | 1 | 7.82 | DOCS | stopped-after:DOCS/pass (drift checklist complete) |
| `destino-frete-cif` | 6 | run | 09-16 20:25 → 20:25 | 1 | 9.03 | EXEC | stopped-after:EXEC/pass (18 increment(s) done, suite green, handoff written) |
| `quatro-silencios-da-tela` | 1 | run | 09-16 23:31 → 23:31 | 1 | 1.92 | TICKET | stopped-after:TICKET/pass (issue SQ-130 in the sprint) |
| `quatro-silencios-da-tela` | 2 | run | 09-16 23:34 → 23:34 | 1 | 6.72 | EXEC | stopped-after:EXEC/fail (6 of 7 increment(s) still to execute) |
| `quatro-silencios-da-tela` | 3 | run | 09-16 23:38 → 23:38 | 1 | 5.23 | EXEC | stopped-after:EXEC/fail (5 of 7 increment(s) still to execute) |
| `quatro-silencios-da-tela` | 4 | run | 09-16 23:43 → 23:43 | 1 | 6.28 | EXEC | stopped-after:EXEC/fail (4 of 7 increment(s) still to execute) |
| `quatro-silencios-da-tela` | 5 | run | 09-16 23:47 → 23:47 | 1 | 4.99 | EXEC | stopped-after:EXEC/fail (3 of 7 increment(s) still to execute) |
| `quatro-silencios-da-tela` | 6 | run | 09-16 23:50 → 23:50 | 1 | 4.69 | EXEC | stopped-after:EXEC/fail (2 of 7 increment(s) still to execute) |
| `quatro-silencios-da-tela` | 7 | run | 09-16 23:53 → 23:53 | 1 | 3.41 | EXEC | stopped-after:EXEC/fail (1 of 7 increment(s) still to execute) |
| `quatro-silencios-da-tela` | 8 | run | 09-16 23:58 → 23:58 | 1 | 6.56 | EXEC | stopped-after:EXEC/pass (7 increment(s) done, suite green, handoff written) |
| `quatro-silencios-da-tela` | 9 | run | 09-17 00:42 → 00:42 | 1 | 14.67 | QA | stopped-after:QA/pass (report 2026-09-15-sq128-aprovacao-sem-logistica.md closed, registry cl) |
| `quatro-silencios-da-tela` | 10 | run | 09-17 10:13 → 10:13 | 1 | 20.05 | REVIEW | stopped-after:REVIEW/fail (40-review-r1.md: Code Quality (Zen) = B — the gate requires Grade A on) |
| `quatro-silencios-da-tela` | 11 | run | 09-17 10:28 → 11:31 | 11 | 50.03 | DOCS EXEC REVIEW | rc3:hat-crossed@DOCS |
| `quatro-silencios-da-tela` | 12 | run | 09-17 11:57 → 11:57 | 1 | 2.53 | PR | PR-open(rc0) |
| `quatro-silencios-da-tela` | 13 | close | 09-17 12:22 → 12:22 | 0 | 0.86 |  | close |
| `papeis-consultor-admin` | 1 | run | 09-18 00:57 → 01:26 | 6 | 34.67 | EXEC TICKET | rc3:increment-blocked@EXEC |
| `papeis-consultor-admin` | 2 | run | 09-18 01:32 → 03:28 | 14 | 116.77 | EXEC QA REVIEW | rc3:budget-exhausted@DOCS |
| `papeis-consultor-admin` | 3 | run | 09-18 08:11 → 08:11 | 1 | 5.55 | DOCS | rc3:hat-crossed@DOCS |
| `papeis-consultor-admin` | 4 | run | 09-18 08:32 → 08:32 | 1 | 2.38 | PR | rc3:kit-touched@PR |
| `todo-no-esqueleto` | 1 | run | 09-24 16:53 → 17:14 | 5 | 18.57 | EXEC TICKET | stopped-after:EXEC/fail (6 of 10 increment(s) still to execute) |
| `todo-no-esqueleto` | 2 | run | 09-24 17:44 → 17:48 | 2 | 5.36 | EXEC | rc3:kit-touched@EXEC |
| `todo-no-esqueleto` | 3 | run | 09-24 18:05 → 18:23 | 7 | 15.58 | EXEC QA REVIEW | rc3:no-work@REVIEW |
| `todo-no-esqueleto` | 4 | run | 09-24 18:26 → 18:45 | 5 | 10.52 | DOCS EXEC PR REVIEW | PR-open(rc0) |
| `transacao-honra-o-timeout` | 1 | run | 09-24 21:59 → 22:19 | 9 | 15.46 | EXEC TICKET | rc3:no-progress@EXEC |
| `transacao-honra-o-timeout` | 2 | run | 09-24 22:27 → 22:51 | 4 | 10.51 | DOCS PR QA REVIEW | PR-open(rc0) |
| `breadcrumb-numero-cotacao` | 1 | run | 09-27 17:48 → 19:40 | 11 | 17.81 | DOCS EXEC PR QA REVIEW TICKET | PR-open(rc0) |
| `breadcrumb-numero-cotacao` | 2 | close | 09-27 22:01 → 22:01 | 0 | 0.85 |  | close |
| `ver-vira-olho-na-lista` | 1 | run | 09-28 08:35 → 09:46 | 7 | 12.54 | DOCS EXEC PR QA REVIEW TICKET | PR-open(rc0) |
| `ver-vira-olho-na-lista` | 2 | close | 09-28 10:47 → 10:47 | 0 | 0.77 |  | close |
| `aviso-diretoria-por-email` | 1 | run | 09-29 17:45 → 19:38 | 12 | 23.7 | EXEC QA TICKET | stopped-after:QA/pass (report 2026-09-29-sq150-aviso-diretoria-por-email.md closed, registry ) |
| `aviso-diretoria-por-email` | 2 | run | 09-29 20:08 → 20:38 | 3 | 13.8 | EXEC REVIEW | stopped-after:EXEC/pass (10 increment(s) done, suite green, handoff written) |
| `aviso-diretoria-por-email` | 3 | run | 09-29 20:53 → 22:20 | 6 | 14.72 | DOCS EXEC PR REVIEW | PR-open(rc0) |
| `aviso-diretoria-por-email` | 4 | close | 09-29 23:04 → 23:04 | 0 | 0.72 |  | close |
| `e2e-local-diz-por-que-caiu` | 1 | run | 09-30 19:46 → 21:05 | 12 | 14.65 | EXEC QA REVIEW TICKET | stopped-after:REVIEW/fail (working tree dirty after the review — the round and its R<n> rows must) |
| `e2e-local-diz-por-que-caiu` | 2 | run | 09-30 22:00 → 22:31 | 3 | 8.53 | DOCS PR QA | PR-open(rc0) |
| `justificativa-pedido-alcada` | 1 | run | 09-30 11:29 → 13:16 | 14 | 30.75 | EXEC QA REVIEW TICKET | rc3:hat-crossed@REVIEW |
| `justificativa-pedido-alcada` | 2 | run | 09-30 13:54 → 15:09 | 6 | 12.56 | DOCS PR QA REVIEW | PR-open(rc0) |
| `mascaras-ncm-e-painel` | 1 | note-manual | 10-05 20:00 → 20:00 | 0 | 0 |  | manual@TICKET |
| `mascaras-ncm-e-painel` | 2 | run | 10-05 20:21 → 21:48 | 8 | 33.01 | EXEC QA | rc3:kit-touched@QA |
| `mascaras-ncm-e-painel` | 3 | run | 10-05 22:37 → 22:37 | 1 | 8.47 | QA | rc3:kit-touched@QA |
| `mascaras-ncm-e-painel` | 4 | run | 10-05 22:57 → 23:09 | 2 | 7.68 | EXEC | rc3:kit-touched@EXEC |
| `mascaras-ncm-e-painel` | 5 | run | 10-05 23:18 → 23:18 | 1 | 3.28 | EXEC | rc3:kit-touched@EXEC |
| `mascaras-ncm-e-painel` | 6 | run | 10-05 23:53 → 00:31 | 4 | 22.48 | DOCS PR QA REVIEW | PR-open(rc0) |
| `mascaras-ncm-e-painel` | 7 | run | 10-06 01:06 → 03:01 | 6 | 29.47 | EXEC QA | stopped-after:QA/pass (report 2026-10-06-sq155-mascaras-ncm-e-painel-r4.md closed, registry c) |
| `mascaras-ncm-e-painel` | 8 | close | 10-06 09:11 → 09:11 | 0 | 0.49 |  | close |

## 3. Agregados

### 3.1 Custo, sessões, tempo

| Métrica | Valor | Nota |
|---|---|---|
| Missões | 21 (20 com PR; `cif-forma-pagamento` parou no EXEC e foi encerrada com `90-fecho.md`) | |
| Custo total | **US$ 1 636,07** (sessões + 5 `sdd close`) | |
| Custo por missão | **mediana US$ 52,94 · p90 US$ 159,38** · média 77,91 · mín 6,94 · máx 174,11 | p90 = posto mais próximo (19º de 21). Só as 20 com PR: mediana 58,78 |
| Por época | ≤ 2026-09-18 (13 missões): mediana **US$ 84,42**; ≥ 2026-09-24 (8): mediana **US$ 34,64** | correlação, não causa: tamanho de missão e kit mudaram juntos |
| Missões acima do teto de US$ 150 | 4 (`legado-fala-cru` 174, `destino-frete-cif` 170, `papeis` 159, `descarte` 152) | todas ≤ 2026-09-18 |
| Sessões por missão | **mediana 15 · p90 22** · total 311 | |
| Lançamentos `sdd run` por missão | **mediana 2 · p90 6** · total 67 | `quatro-silencios`: 12 (7 deles com UMA sessão de EXEC cada, 0–1 min entre si) |
| Span (1ª → última linha) | mediana 3,7 h · p90 12,9 h | inclui espera humana e o `close` pós-merge |
| Tempo de máquina (soma por lançamento, 1ª sessão → última linha) | **mediana 2,6 h** · total 56,8 h | sessões puras: mediana 2,2 h, total 46,6 h; o resto são gates (`TEST_CMD`, `E2E_CMD`) entre sessões |
| Gate entre duas sessões do MESMO lançamento > 30 min | **0 casos** | o tempo de gate nunca foi o gargalo |

Custo por fase (todas as missões):

| Fase | Sessões | US$ | % do custo | mediana US$/missão |
|---|---|---|---|---|
| EXEC | 155 | 705,51 | 43 % | 20,05 |
| REVIEW | 42 | 447,18 | 27 % | 14,30 |
| QA | 51 | 309,58 | 19 % | 10,81 |
| DOCS | 20 | 94,37 | 6 % | 4,66 |
| TICKET | 24 | 39,03 | 2 % | 1,69 |
| PR | 19 | 36,67 | 2 % | 2,15 |

Rodadas de REVIEW (arquivos `40-review-r<N>.md`): mediana **1**; 10 missões com 1, 4 com 2, 4 com 3,
2 com 4 (`legado-fala-cru` e `descarte`, ambas antes de 2026-09-03, quando o gate passou a tolerar
B nos critérios de prosa). Sessões de QA: mediana **1**; desde 2026-09-29 (QA escreve o próprio
relatório, `QA:exec`) 4, 4, 5 e 7 sessões.

### 3.2 Toque humano

| Métrica | Valor | Como |
|---|---|---|
| Missões do início ao PR **com zero toque humano** depois da aprovação | **4 de 21 (19 %)** — `a-tela-que-mente-o-pagamento`, `o-rascunho-fantasma-do-mount`, `breadcrumb-numero-cotacao`, `ver-vira-olho-na-lista` | 1 lançamento `run`, terminou em `PR-open`, nenhuma escalada, nenhuma fase manual. ⚠️ É teto: as quatro tinham interface e dependeram do stack local que o humano deixou no ar (o gate de QA roda `E2E_CMD` contra `localhost:5173`/`:3000`) |
| Missões com ao menos uma escalada rc 3 | 13 de 21 (62 %) | 25 escaladas |
| Missões com mais de um lançamento | 16 de 21 (76 %) | |
| Relançamentos antes do PR | **46** em 16 missões | `run_id` novo depois do anterior parar |
| Intervalo entre parar e relançar | **mediana 10 min**; depois de rc 3: n=21, mediana 9 min; depois de parada sem escalada: n=25, mediana 11 min | o humano estava olhando |
| Intervalos > 30 min (proxy de "esperando humano") | **11**, somando **35,4 h**; 4 deles são noite inteira (547, 560, 371 e 271 min = 29,2 h) | a linha parou de madrugada e voltou de manhã |
| Sessões já rodadas entre 22h e 07h | 101 de 311 (32 %) — **nenhuma entre 05h e 08h** | o humano roda à noite, mas acordado, e para por volta das 04h |
| `ON_ESCALATION_CMD` no `.sdd/config.sh` do `sales_quote` | **vazio** — nenhuma escalada chegou a pager | |
| `sdd retry` / `auto_retry` | 0 / 0 | |
| Fase feita à mão registrada (`manual`) | 1 (TICKET de `mascaras-ncm-e-painel`) | antes do #153 a fase à mão não deixava linha — ver §6 |
| Notas `intervention:` escritas pelo runner | 6 (5 `--budget-override`, 1 `note-manual`) | |
| Notas `intervention:` escritas pelo humano | 6 (frete-cif-fob, pagamento-e-do-consultor, papeis, descarte ×3) | ver §4 |

Escaladas por `kind` (ledger, `event: blocked`):

| kind | n | missões | fase |
|---|---|---|---|
| `kit-touched` | 6 | 3 (`mascaras` ×4, `todo-no-esqueleto`, `papeis`) | QA ×2, EXEC ×3, PR ×1 |
| `budget-exhausted` | 6 | 3 (`legado` ×2, `descarte` ×3, `papeis` ×1) | REVIEW ×5, DOCS ×1 — 4 são `REVIEW_MAX_ITER` esgotado, 2 o teto de missão |
| `no-progress` | 5 | 5 | QA ×2, PR, TICKET, EXEC |
| `hat-crossed` | 4 | 4 | QA, DOCS ×2, REVIEW |
| `increment-blocked` | 3 | 3 | EXEC |
| `no-work` | 1 | 1 | REVIEW |
| `app-down`, `session-died`, `dirty-tree`, `handoff-blocked`, `retry-gate-red`, `foreign-commit` | 0 | — | — |

### 3.3 QA nas missões com interface

18 das 21 têm interface (fora: `cif-forma-pagamento`, sem QA; `todo-no-esqueleto` e
`transacao-honra-o-timeout`, `qa: skipped (diff has no user-visible change)`).

| Regime | Missões | QA US$ | Sessões de QA | % do custo da missão |
|---|---|---|---|---|
| Até 2026-09-28 — só `QA:close`; em 6 missões o gate passou com relatório de **outra** missão (`2026-08-24-sq107-…` em 4, `sq128`, `sq143`; o buraco que a ADR 0013 fechou) | 14 | mediana 12,01 | mediana 1 (frete-cif-fob: 12, US$ 73,32) | — |
| Desde 2026-09-29 — `QA:exec` (`/qa-execution`) escreve o relatório da missão | 4 | 6,81 · 6,00 · 12,87 · **57,13** | 4 · 4 · 5 · 7 | **37 %** (soma) |
| Todas as 18 | 18 | mediana 12,01, total 306,40 | | 20 % |

A QA "de verdade" (relatório próprio) é recente, tem quatro pontos e uma cauda gorda
(`mascaras-ncm-e-painel`: US$ 57,13 em 7 sessões, três delas **depois** do PR aberto). O custo de
QA do regime antigo subestima o que o worker vai pagar.

### 3.4 Bots do PR (o que a W7 encontraria)

21 PRs, **21 mergeados**, todos por humano. Abertura → merge: mediana ≈ 1 h, p90 8,2 h.

| Bot | Resultado |
|---|---|
| Copilot (`copilot-pull-request-reviewer`) | pedido em 21/21, **revisou 0/21** — "unable to review … quota limit" em todos |
| CodeRabbit | **ausente** nos 21 |
| Codex (`chatgpt-codex-connector`) | "usage limits" nos 9 primeiros (#105–#144, até 2026-09-06); desde #145 revisou **12/12**: 10 com achados, 2 limpos (#377, #406) |
| Achados do Codex | **14** (P1 = 6, P2 = 8), sempre numa leva só (mesmo timestamp); 1º achado chega **3–5 min** depois da abertura (um caso, #145, em 51 min) |
| Segunda rodada de achados do Codex depois do conserto | **0** — a regra "uma leva, segunda rodada escala" da W7 nunca teria disparado |
| PRs com commit de conserto depois da abertura | **10 de 21 (48 %)**; dos 10 com achado do Codex, 9 ganharam commit (o #180 não) — 1 a 4 commits, 15–60 min depois |
| Commits pós-PR que não vêm de bot | #398, #401, #406: humano aplicando o texto `⛔` do DOCS (rule proposta que o chapéu não pode escrever); #406: 15 commits de uma volta QA⇄EXEC **depois** do PR, aberta por decisão humana sobre o CEP; #145: `AGENTS.md` para o Codex ler o `CLAUDE.md` |
| Resposta inline do humano ao Codex | 5 PRs (#145, #167, #168, #382, #383) — "procede, corrigido em <sha>" |

Sessões do runner **depois** de o PR estar aberto: **8 em 3 missões, US$ 46,10** —
`destino-frete-cif` (1 EXEC, o R5 que consertou o P1 do Codex, sob `--budget-override`),
`condicoes-pagamento` (1 QA:close) e `mascaras-ncm-e-painel` (6 sessões, a volta QA⇄EXEC aberta
pela decisão humana sobre o CEP). É o tamanho do que a W7 teria de fazer pelo runner.

## 4. Classificação das paradas (ambiente × julgamento × kit)

Cada uma das 25 escaladas e das 27 paradas sem escalada foi lida nas notas da missão
(`checkpoint-notas.md`/`checkpoint.md`, handoffs, `pipeline.log`, e o relatório
`/home/joruge/repos/sdd_agents/ACHADOS-20260917-sales-quote.md`). Classes: **ENV** (ambiente,
credencial, máquina, concorrência no checkout), **JULG** (decisão humana de produto/plano/custo),
**KIT** (defeito ou limite do kit, inclusive o humano editando o kit durante a corrida),
**OPER** (o operador limitou a corrida de propósito, `--max-phases 1`), **?** (as notas não dizem).
Nenhum caso foi erro do próprio agente que um retry consertaria.

**Totais.** Escaladas (25): KIT 12 · JULG 9 · ENV 4. Paradas sem escalada (27): OPER 14 · ENV 7 ·
JULG 3 · ? 2 · KIT 1.

### 4.1 Escaladas rc 3

| missão | quando | kind@fase | classe | causa | o que o humano fez |
|---|---|---|---|---|---|
| cif-forma-pagamento | 08-25 02:14 | increment-blocked@EXEC | JULG | I1 nasceu verde: o defeito não reproduzia; o ramo de escape do plano pedia decisão | ditou a regra; missão fechada como refutada (`90-fecho.md`) |
| frete-cif-fob | 08-26 00:33 | no-progress@QA | JULG | 4 bugs `open` antigos eram escolha de produto; 8 voltas de QA (Âncora 3 insatisfazível) | assinou `wont-fix` e virou o handoff para `done` à mão |
| rascunho-legado | 09-02 22:12 | budget-exhausted@REVIEW | JULG | `REVIEW_MAX_ITER=3` esgotado com só Documentation = B | forçou r4 com `--phase REVIEW` |
| rascunho-legado | 09-02 23:37 | budget-exhausted@REVIEW | KIT | o gate não registrava o aceite humano do B (platô) | relançou direto para PR |
| rascunho-legado | 09-02 23:43 | no-progress@PR | KIT | o publisher encerrou o turno "aguardando tarefa em background" (fatal em `claude -p`) | push, corpo do PR e `50-pr.md` à mão |
| contato-notfound | 09-06 10:34 | no-progress@TICKET | KIT | harness 2.1.263 leu `disallowedTools:` e tirou o Bash do chapéu (3 sessões) | consertou o kit (PR #40) e relançou 2 h depois |
| pagamento-e-do-consultor | 09-06 18:52 | increment-blocked@EXEC | JULG | regra D2 do plano exigia decisão de produto | revisou a D2; I1 voltou a `pending` |
| descarte | 09-07 10:50 | budget-exhausted@REVIEW | JULG | 3 rodadas gastas, a r3 julgou a árvore de antes do R5 | relançou sem subir o teto (erro admitido) |
| descarte | 09-07 11:12 | budget-exhausted@REVIEW | JULG | mesmo veredito no disco | subiu `REVIEW_MAX_ITER` 3 → 4 |
| descarte | 09-07 12:01 | budget-exhausted@REVIEW | JULG | teto de missão (US$ 152,30 > 150) antes da r5 | não subiu o teto; DOCS e PR à mão |
| destino-frete-cif | 09-16 16:42 | hat-crossed@QA | KIT | a QA subiu o piso do `e2e-staging.yml`, exigência do repo, fora do `writes:` | manteve; virou `HAT_WRITES_EXTRA` |
| destino-frete-cif | 09-16 17:05 | no-progress@QA | ENV | sessões morreram por **OAuth expirado**; o gate mostrou "5 bugs open" | reautenticou; marcou 5 bugs `Closable by: human` |
| quatro-silencios | 09-17 11:31 | hat-crossed@DOCS | KIT | DOCS escreveu item correto em `.claude/napkin.md`, fora do `writes:` | manteve, relançou (depois `HAT_WRITES_EXTRA`) |
| papeis | 09-18 01:26 | increment-blocked@EXEC | JULG | I5 era subconjunto do I6: ordem impossível no plano | corrigiu o plano (fundiu I5 no I6) |
| papeis | 09-18 03:28 | budget-exhausted@DOCS | JULG | teto de missão (US$ 151,44) | `--budget-override` para DOCS e PR (5 h depois) |
| papeis | 09-18 08:11 | hat-crossed@DOCS | KIT | DOCS corrigiu drift legítimo em `PRODUCT.md` | alargou o chapéu no kit (796e334) |
| papeis | 09-18 08:32 | kit-touched@PR | KIT | o próprio conserto do chapéu caiu no kit durante o PR | aceitou; o PR #172 já estava aberto |
| todo-no-esqueleto | 09-24 17:48 | kit-touched@EXEC | KIT | kit sujo por edição paralela do humano | commitou no kit e relançou |
| todo-no-esqueleto | 09-24 18:23 | no-work@REVIEW | ENV | linha de ledger de **outra** missão (ansible-jrc) sujou um arquivo | relançou; `git stash` |
| transacao-timeout | 09-24 22:19 | no-progress@EXEC | ENV | `TEST_CMD` rodando com node v18 (config antiga em memória) | reiniciou depois do `nvm use` no `TEST_CMD` |
| justificativa | 09-30 13:16 | hat-crossed@REVIEW | ENV | **outra sessão** instalou uma skill no checkout; a guarda culpou a REVIEW | `git stash` e relançou |
| mascaras | 10-05 21:48 | kit-touched@QA | KIT | kit editado em paralelo (lote 4) | decidiu 3 bugs e relançou |
| mascaras | 10-05 22:37 | kit-touched@QA | KIT | HEAD do kit avançou durante a QA | relançou |
| mascaras | 10-05 23:09 | kit-touched@EXEC | KIT | commit do PR #222 do kit durante o EXEC | relançou |
| mascaras | 10-05 23:18 | kit-touched@EXEC | KIT | merge #231 no kit durante o EXEC | relançou |

### 4.2 Paradas sem escalada (o processo terminou sem rc 3 e sem PR)

| missão | lançamento | fim | classe | causa | o que o humano fez |
|---|---|---|---|---|---|
| condicoes | L1 | QA/fail E2E | ENV | **stack fora do ar** (proxy JRC `:9998` recusando), 17 e2e vermelhos | subiu o stack; o gate passou 86/86 |
| condicoes | L2 | REVIEW/pass | ? | duas sessões de DOCS morreram (exit 137), sem nota | relançou |
| condicoes | L3 | QA/fail E2E | ENV | gate de QA **depois do PR** com o stack inteiro fora (`:3007`, `:5173`, `:9998`) | matou; fechou o SQ-111 de manhã |
| invariante | L1, L2 | TICKET/pass, QA/pass | ENV | `sdd run` lançado como tarefa de fundo de uma sessão Claude, morreu junto | relançou com `setsid nohup env -u CLAUDE_*` |
| rascunho-legado | L2 | REVIEW/fail r4 | JULG | r4 forçada repetiu o B (platô) | aceitou o platô; achados para o `TODO.md` |
| descarte | L1 | EXEC/fail | ENV | runner e sessão do R4 morreram sem escalada nem linha (causa não confirmada) | salvou o trabalho órfão à mão |
| descarte | L3 | EXEC/fail TEST_CMD | ENV | relançado por `systemd-run` **sem shell de login**: npm do nvm fora do PATH (rc 127) | relançou com `zsh -lic` |
| destino | L3 | EXEC/pass | ENV | corrida em background morta por **pressão de memória** (outro processo com 6,5 GB, swap cheio) | passou a `--max-phases 1` em primeiro plano |
| destino | L4–L6 | REVIEW, DOCS, EXEC /pass | OPER | `--max-phases 1`; o lançamento de PR morreu 3× por memória; L6 = R5 do P1 do Codex, depois do PR | PR #167 aberto à mão; `--budget-override` |
| quatro-silencios | L1–L10 | TICKET, EXEC×7, QA, REVIEW | OPER | `--max-phases 1` fase a fase, para fugir das mortes por memória | relançou fase a fase (10 lançamentos) |
| todo-no-esqueleto | L1 | EXEC/fail 6 de 10 | ? | sessão do I5 morreu no meio do `TEST_CMD`, sem nota | relançou 25 min depois |
| aviso-diretoria | L1, L2 | QA/pass, EXEC/pass | JULG | contas do IdP erradas (o F1 mudou o teste em vez da conta); crítica visual do e-mail | corrigiu IdP e `.env.local`; inseriu F3 e F4 |
| e2e-local | L1 | REVIEW/fail árvore suja | KIT | `01-plano.md` e notas nunca versionados desde o PLAN | commitou e relançou (kit corrigiu em 5df5176) |
| mascaras | L7 | QA/pass | OPER | relançamento deliberado **depois** do PR #406 para F4/F5 (decisão sobre o CEP) | escolheu a opção do bug; fechou SQ-155 |

### 4.3 Outras intervenções humanas que nenhum dos dois instrumentos registra

- `quatro-silencios`: backend subido à mão com `NODE_EXTRA_CA_CERTS` (o caminho padrão dá
  `jwks:fail`); `develop` local resetado depois do squash do #167.
- `mascaras`: TICKET feito à mão (`sdd note-manual`); 3 bugs decididos e a frase do aviso do NCM
  ditada pelo humano.
- Textos `⛔` aplicados à mão no PR (o `claude -p` recusa `Edit` em `.claude/`): `e2e-local`
  (`techspec.md`, `napkin.md`), `justificativa` (`techspec.md`), `mascaras` (dois itens).
- `papeis`: o papel `quote.consultor` não existia no IdP local — pendência humana em outro repo.
- `justificativa`: `docs/adr/0051` e `skills-lock.json` sujos, decisão de commitar deixada ao humano.
- PRs abertos à mão depois de o publisher morrer: #139 (`legado`), #145 (`descarte`), #167 (`destino`).

### 4.4 Regrupado pelo que o worker precisa

| Grupo | Escaladas | Paradas | Missões |
|---|---|---|---|
| **Concorrência no checkout/máquina do humano** (kit editado em paralelo, outra sessão ou outra missão sujando a árvore) | 8 (`kit-touched` ×6, `no-work`, `hat-crossed` da justificativa) | — | 4 |
| **Processo/credencial/máquina** (OAuth expirado, node errado, PATH sem login shell, morte por memória, `sdd run` filho de sessão Claude, mortes sem causa) | 2 | 5 + 2 ? | 6 |
| **Stack local fora do ar** | 0 | 2 | 1 |
| **Decisão humana** (plano, produto, teto, platô de revisão, IdP) | 9 | 3 | 7 (+ `mascaras`, decisão depois do PR) |
| **Defeito de kit já consertado** (chapéu sem Bash, `writes:` estreito ×3, publisher em background, aceite do B, plano não versionado) | 6 | 1 | 6 |
| **Operador contornando o ambiente** (`--max-phases 1` por causa da memória) | 0 | 14 | 3 |

## 5. O que um worker noturno teria encontrado

Legenda: **(a)** o worker seguiria sozinho · **(b)** tem de parar e chamar o humano (pager) ·
**(c)** precisa de capacidade nova, com o degrau do roadmap (W1 checkout · W2 clone/identidade/segredos ·
W3 entrega/rastreador · W4 ambiente · W5 olhar · W6 executar/teto/pager · W7 bots).

| O que aconteceu (casos) | Worker | Por quê / o que falta |
|---|---|---|
| **Kit editado em paralelo durante a corrida** — `kit-touched` ×6 em 3 missões (o humano trabalhando no kit, inclusive mergeando PRs do kit no meio do EXEC) | **(c)** fora do W1–W7 como escrito; mais perto de **W2** | O clone dedicado do alvo não resolve: `kit_guard_check` compara o checkout do kit para onde o `sdd` do PATH resolve. O worker precisa rodar contra um **kit fixo** (sha ou worktree próprio que o humano não edita), senão toda noite em que o humano mexe no kit para a linha. A regra do lote 5 (missão do kit em worktree ligado) já tira parte da causa do lado humano. |
| **Outra sessão/missão sujando o checkout** — `no-work@REVIEW` (ledger de outra missão), `hat-crossed@REVIEW` (outra sessão instalou skill) | **(a)** com **W1** + clone dedicado (D3) | É exatamente a colisão que o clone separado elimina. |
| **Ambiente do processo** — `TEST_CMD` com node v18 (`no-progress@EXEC`); `sdd run` por `systemd-run` sem shell de login, npm do nvm fora do PATH, rc 127; `sdd run` filho de sessão Claude morrendo junto (2×) | **(c) W6** | ⚠️ O único lançamento já feito por `systemd-run` no `sales_quote` (`descarte` L3) morreu assim — é o regime do timer do worker. A unit precisa de ambiente declarado (login shell ou `PATH`/nvm explícitos) e de um `sdd preflight` no tick, antes de comprar sessão. |
| **Credencial expirada** — OAuth do Claude expirou e o gate mostrou "5 bugs open" (`no-progress@QA`; `docs/pipeline.md` mede US$ 4,56 numa sessão mais o retry) | **(b)**, e **(c) W2/W6** para antecipar | Desde 2026-09-18 isso sai como `session-died` (correto). Sem humano, falta checar a validade da credencial (Claude, `gh`, Jira) **antes** do tick, onde a W2 declara de onde os segredos vêm. |
| **Morte por memória / mortes sem causa** — 1 parada por pressão de memória (swap cheio), 2 sem nota, 1 runner que morreu sem linha no ledger; 14 lançamentos `--max-phases 1` foram o contorno manual disso | **(b)** + **(c) W6** | Morte silenciosa é o pior caso sem ninguém olhando: não há rc 3, não há linha, não há pager. O tick precisa tratar "processo morreu / rc fora de 0/2/3" como parada própria e avisar. |
| **Stack local fora do ar** — 2 paradas (`condicoes`: proxy `:9998` recusando, 17–20 e2e vermelhos) | **(c) W4** | Dependência universal: as 18 missões com interface rodaram `E2E_CMD` contra o stack que o humano deixou no ar (`:5173`, `:3000`, proxy JRC, IdP local, `NODE_EXTRA_CA_CERTS`, `.env.local` com a audience). Existe `npm run stack:check` (sonda), **não existe** comando de subir — o `ENV_UP_CMD` está por escrever. Zero `app-down` no histórico **não** prova ambiente estável (ver §6). |
| **Decisão humana** — 9 escaladas + 3 paradas em 7 missões (plano com ordem impossível, regra de produto, bug que é escolha, platô de revisão, contas do IdP) | **(b)** | Nenhuma capacidade substitui; o worker só precisa parar na hora e avisar. ⚠️ `ON_ESCALATION_CMD` está **vazio** no `sales_quote`: hoje nenhuma escalada chega a pager — W6 deve recusar repo sem pager. |
| **Teto de custo** — `budget-exhausted` ×6 (4 de `REVIEW_MAX_ITER`, 2 de `BUDGET_MISSION_USD`) + 5 `--budget-override` (2 missões) | **(b)** + **W6** | Override é decisão humana (D1/§6 do spec). 4 missões passaram de US$ 150, todas até 2026-09-18. O teto diário da W6 fica acima disso (números na §3.1). |
| **Defeito de kit já consertado** — chapéu sem Bash (harness 2.1.263), `writes:` estreito ×3, publisher encerrando turno com background, aceite do B, plano não versionado | **(a)** hoje | Cada um tem conserto mergeado. Mas o ritmo foi ~1 defeito de kit novo a cada 3–4 missões até 2026-09-30 (7 casos em 6 de 21) — a próxima noite deve ser esperada a achar o seguinte, e o W5 (`--dry-run`) não o pegaria (aparecem na sessão, não na derivação). |
| **Fase TICKET** — feita à mão uma vez (`note-manual`), presa uma vez (placeholder) | **(c) W3** | Adotar o cartão em vez de criar. |
| **PR aberto à mão** porque o publisher morreu (#139, #145, #167) | **(a)** hoje | Consertado pela `turn_rule` no `boot_prompt`. |
| **Bots do PR** — Codex revisou 12/21 (10 com achado, 14 achados, P1 = 6, sempre uma leva, 3–5 min; um caso 51 min); Copilot 0/21 por cota; CodeRabbit ausente; 9/21 PRs sem revisão de bot nenhuma; conserto em 1–4 commits, um deles pelo runner (R5 do #167, com `--budget-override`) | **(c) W7** | Timeout que cubra a cauda (≥ 60 min) e tratar "quota / usage limits" como **"não revisou"** — nem esperar para sempre, nem anunciar "limpo". A regra "segunda leva escala" nunca teria disparado (0 segundas rodadas). |
| **Texto `⛔` de rule** aplicado à mão no PR (3 PRs) | **(b)** por desenho | `claude -p` recusa `.claude/`; o aviso "pronto para merge" da W7 deve listar os `⛔` pendentes. |
| **QA humana depois do PR** (`mascaras`: decisão sobre o CEP reabriu QA⇄EXEC, 6 sessões, US$ 29) | **(b)** | Fora do escopo do worker; é julgamento sobre o produto. |
| **Parada à noite, retomada de manhã** — 4 esperas de noite inteira (29,2 h das 35,4 h de espera > 30 min) | **(a)** com **W6** | O worker não encurta a espera pela decisão, mas o tick seguinte pode pegar **outra** missão em vez de deixar a máquina parada. |

### 5.1 Quanto teria passado sozinho

- **Histórico real:** 4 de 21 (19 %) do TICKET ao PR sem toque humano depois da aprovação.
- **Com o kit de hoje + W2 (clone, kit fixo) + W4 (stack) + W6 (ambiente do processo, pager):**
  ≈ **12 de 21 (57 %)** não tiveram nenhuma parada de julgamento nem de teto antes do PR
  (`condicoes`, `a-tela`, `invariante`, `fantasma`, `contato`, `quatro-silencios`, `todo`,
  `transacao`, `breadcrumb`, `ver-vira`, `e2e-local`, `justificativa`) e o worker poderia tê-las
  levado ao PR. As outras 9 (43 %) parariam ao menos uma vez por decisão humana ou teto
  (`cif-forma`, `frete-cif-fob`, `legado`, `pagamento`, `descarte`, `destino` — teto, com override
  pré-emptivo —, `papeis`, `aviso`, `mascaras`). ⚠️ Estimativa contrafactual: supõe que cada
  conserto de kit vale retroativamente e que nenhum defeito novo apareceria.
- **Ritmo de uma noite:** tempo de máquina mediana 2,6 h, p90 4,3 h por missão; numa janela de 8 h
  cabem 2–3 missões medianas ou 1–2 de p90. Custo de uma noite assim: ~US$ 105–160 (2–3 × mediana),
  até ~US$ 320 com duas missões de p90.

## 6. Lacunas — o que o ledger não sabe dizer

- **Tempo humano de planejamento.** O PLAN é interativo e não grava linha; o ledger começa no
  TICKET. Não há como medir quanto o humano gastou no `/sdd-plan`, no grill e no `sdd approve`.
- **Preparo do ambiente.** Subir backend (`:3000`), SPA (`:5173`), IdP local e certificados
  (`mkcert`, `NODE_EXTRA_CA_CERTS`, `.env.local` com a audience do Zitadel — ver
  `scripts/stack-check.mjs`) não deixa rastro. Toda missão com interface dependeu disso, e o
  ledger não tem nenhuma linha que diga "o stack estava no ar porque o humano o subiu". O zero de
  `app-down` não prova que o ambiente nunca caiu: prova que, quando o `E2E_CMD` falhou, o app
  respondia em `APP_URL` (o `app-down` só dispara com TCP recusado ou página errada).
- **O que o humano fez entre dois lançamentos.** O ledger mostra a parada e o relançamento, não o
  conserto. A §4 recupera isso das notas e do journal; 2 das 27 paradas sem escalada seguem sem
  explicação, e várias notas trazem horário errado (casadas por `pipeline.log`, ledger e git).
- **`--phase` / `--max-phases` / Ctrl-C.** Antes do lote 5 (2026-10) o runner não escrevia nota
  para `--phase`; uma parada "sem escalada" pode ser fase única pedida, processo morto ou
  interrupção. Os 10 lançamentos de uma fase cada da `quatro-silencios` eram `--max-phases 1`
  (as notas confirmam); o ledger sozinho não diria.
- **Lançamento que morreu antes da 1ª linha** não existe para o ledger (o `ts` é gravado depois do
  gate). Medido uma vez (`aviso-diretoria`, 1 sessão de US$ 1,08 só no journal). Lançamentos e
  sessões são, portanto, contagens por baixo.
- **Trabalho interativo fora do runner.** Consertos pós-PR (os commits do §3.4), o texto `⛔`
  aplicado à mão, a resposta ao Codex e as 7 pastas de missão que nunca passaram pelo `sdd run`
  não têm custo no ledger. O US$ por missão é o custo **do runner**, não o custo da missão.
- **Quem empurrou o commit pós-PR.** O autor git é o mesmo para humano e sessão; não dá para
  separar "sessão interativa do humano usando `/coderabbit-pr`" de "humano editando".
- **Harness antes de 2026-09-06** (`harness` ausente) e `runner_sha` antes de 2026-10-05: a
  atribuição de custo a versão de harness/kit só é exata nas missões recentes.
- **Amostra pequena e não estacionária.** 21 missões, kit mudando o tempo todo (6 missões com 2–4
  `kit_sha` distintos na mesma missão), QA de verdade só em 4. Medianas são indicativas; p90 com
  n = 21 é o 19º valor e muda com uma missão.

## 7. Método e comandos (reprodutíveis, somente leitura)

Tudo somente leitura. Nenhum `sdd status/phase/why/run/retry/health/preflight` foi rodado; nenhum
`sdd autonomy`/`census` também (os cálculos saem direto do JSONL com `jq`). Os campos foram lidos dos
construtores do runner: `autonomy_escalation_row`, `autonomy_phase_fact_row`, `autonomy_close_row` e
`autonomy_session_row` (`bin/sdd`, ~4640–4920); `run_id` é um `uuidgen` por invocação de
`cmd_run`/`cmd_retry`/`note-manual`/`close` (`AUTONOMY_INVOCATION`). Todas as linhas têm offset
`-03:00`, então `ts[0:19]+"Z" | fromdateiso8601` dá relógio local consistente.

Definições:
- **sessão** = `event == "session"`; início = `ts − dur_s` (o `ts` é gravado depois do gate).
- **lançamento** = `run_id` distinto com `invocation == "run"`; só conta lançamento que gravou linha.
- **relançamento antes do PR** = início do lançamento k+1 − última linha do lançamento k, quando k+1
  começa antes da 1ª sessão de PR com `gate == "pass"`.
- **zero toque** = 1 lançamento `run`, termina em sessão de PR verde, sem `blocked`/`degraded`/`manual`.
- **commit de conserto pós-PR** = `committedDate > createdAt`, menos o commit do publisher
  (`messageHeadline` casando `PR #?[0-9]+|fase PR|abre o PR|50-pr|fecha a fase PR|PR —`).
- p90 = posto mais próximo (`sort | .[ceil(0.9·n) − 1]`).

```bash
L=~/.sdd/autonomy-log.jsonl
S=<scratchpad>
# 1. resumo por missão
jq -s -f $S/mission.jq $L > $S/missions.json
# 2. lançamentos e como cada um terminou
jq -s -f $S/launches.jq $L > $S/launches.json
# 3. intervalos entre lançamentos
jq -s -f $S/gaps.jq $L > $S/launch_gaps.json
# 4. conferência ledger × journal (sessões por id)
for f in /home/joruge/repos/sales_quote/.sdd/logs/*/pipeline.log; do m=$(basename $(dirname $f));
  LC_ALL=C awk -v m=$m '$2 ~ /^(TICKET|EXEC|QA|REVIEW|DOCS|PR)$/ && /session=/ {…}' $f; done
jq -r 'select(.repo|test("/sales_quote$")) | select(.event=="session") | .session' $L | sort > ledger_sids.txt
comm -13 ledger_sids.txt journal_sids.txt     # → 1 sessão (aviso-diretoria, EXEC 19:51:32)
# 5. escaladas
jq -r 'select(.repo|test("/sales_quote$")) | select(.event=="blocked") | .kind' $L | sort | uniq -c
# 6. PRs (número tirado do 50-pr.md de cada missão)
gh pr view <n> -R JRC-Brasil/sales_quote --json number,title,headRefName,createdAt,mergedAt,state,commits,comments,reviews
gh api --paginate repos/JRC-Brasil/sales_quote/pulls/<n>/comments      # achados inline (Codex P1/P2)
# 7. notas de intervenção (fora do bloco-modelo `>` do template)
grep -rnE 'intervention' --include='checkpoint*.md' docs/handoffs | grep -vE ':[0-9]+:>'
# 8. hora do dia
jq -r 'select(.repo|test("/sales_quote$")) | select(.event=="session") | .ts[11:13]' $L | LC_ALL=C awk '…'
```

Programa `mission.jq` (o núcleo dos números da §2 e §3):

```jq
# per-mission summary from the autonomy ledger, sales_quote only
def t: .ts[0:19] + "Z" | fromdateiso8601;          # all rows are -03:00; treated as local wall clock
def r2: (. * 100 | round) / 100;
[ .[] | select(.repo | test("/sales_quote$")) ]
| group_by(.mission)
| map(
    sort_by(t) as $rows
    | ($rows | map(select(.event=="session"))) as $s
    | ($rows | map(. + {end: t, start: (t - (if (.event=="session" or .event=="close") then (.dur_s // 0) else 0 end))})) as $tl
    | [range(1; $tl|length) as $i
        | {gap: ($tl[$i].start - $tl[$i-1].end),
           cross: ($tl[$i].run_id != $tl[$i-1].run_id),
           after: ($tl[$i-1].event + ":" + ($tl[$i-1].kind // $tl[$i-1].phase // "")),
           next:  ($tl[$i].event + ":" + ($tl[$i].phase // ""))}] as $gaps
    | {
      mission: $rows[0].mission,
      first: $rows[0].ts[0:16], last: $rows[-1].ts[0:16],
      span_h: ((($rows[-1]|t) - ($rows[0]|t)) / 3600 | r2),
      launches: ($rows | map(select(.invocation=="run")) | map(.run_id) | unique | length),
      retries: ($rows | map(select(.invocation=="retry")) | map(.run_id) | unique | length),
      sessions: ($s|length),
      by_phase: ($s | group_by(.phase) | map({key: .[0].phase, value: {n: length, usd: (map(.cost_usd // 0)|add|r2)}}) | from_entries),
      usd_sessions: ($s | map(.cost_usd // 0) | add | r2),
      usd_close: ($rows | map(select(.event=="close") | .cost_usd // 0) | add // 0 | r2),
      esc: ($rows | map(select(.event=="blocked" or .event=="degraded")) | map(.event + ":" + .kind + "@" + .phase)),
      gate_pass: ($rows | map(select(.event=="gate_pass")) | map(.phase)),
      manual: ($rows | map(select(.event=="manual")) | map(.phase)),
      auto_retry: ($s | map(select(.auto_retry)) | length),
      died: ($s | map(select(.session_error != null)) | length),
      rc_nonzero: ($s | map(select((.rc // 0) != 0)) | length),
      review_rounds: ([$s[] | select(.phase=="REVIEW") | .rounds_after // empty] | max // null),
      review_sessions: ($s | map(select(.phase=="REVIEW")) | length),
      qa_sessions: ($s | map(select(.phase=="QA")) | length),
      qa_steps: ($s | map(select(.phase=="QA") | .step) | group_by(.) | map({key: .[0], value: length}) | from_entries),
      exec_sessions: ($s | map(select(.phase=="EXEC")) | length),
      incr_total_max: ([$s[] | .increments_total // empty] | max // null),
      kit_shas: ($rows | map(.kit_sha) | unique | length),
      kit_first: $rows[0].kit_sha, kit_last: $rows[-1].kit_sha,
      harness: ($s | map(.harness // empty) | unique),
      pr_ts: ([$s[] | select(.phase=="PR" and .gate=="pass") | .ts[0:16]] | first // null),
      gaps_gt30_cross: ($gaps | map(select(.gap > 1800 and .cross)) | length),
      wait_h_cross: ($gaps | map(select(.gap > 1800 and .cross) | .gap) | add // 0 | ./3600 | r2),
      gaps_gt30_same: ($gaps | map(select(.gap > 1800 and (.cross|not))) | length),
      wait_h_same: ($gaps | map(select(.gap > 1800 and (.cross|not)) | .gap) | add // 0 | ./3600 | r2),
      gaps_detail: ($gaps | map(select(.gap > 1800)) | map("\(.gap/60|round)min \(if .cross then "X" else "=" end) after \(.after) -> \(.next)"))
    })
```

Programa `launches.jq`:

```jq
def t: .ts[0:19] + "Z" | fromdateiso8601;
[ .[] | select(.repo | test("/sales_quote$")) ]
| group_by(.mission) | map(sort_by(t)) | map(
   . as $m
   | [ $m | to_entries[] ] as $e
   | ($m | map(.run_id) | reduce .[] as $r ([]; if (.|index($r)) then . else . + [$r] end)) as $order
   | $order | to_entries | map(
       .key as $k | .value as $rid
       | ($m | map(select(.run_id == $rid))) as $rows
       | {mission: $m[0].mission, n: ($k+1), inv: $rows[0].invocation,
          start: ($rows[0] | (t - (.dur_s // 0))), first_ts: $rows[0].ts[5:16], last_ts: $rows[-1].ts[5:16],
          rows: ($rows|length),
          sessions: ($rows|map(select(.event=="session"))|length),
          usd: ($rows|map(.cost_usd // 0)|add),
          phases: ($rows|map(select(.event=="session")|.phase)|unique|join("+")),
          end: ($rows[-1] | if .event=="blocked" then "rc3:" + .kind + "@" + .phase
                 elif .event=="close" then "close"
                 elif .event=="manual" then "manual@" + .phase
                 elif .event=="session" and .phase=="PR" and .gate=="pass" then "PR-open(rc0)"
                 elif .event=="session" then "stopped-after:" + .phase + "/" + .gate + " (" + ((.gate_why//"")[0:70]) + ")"
                 else .event + "@" + (.phase//"") end)}))
| flatten
```

Programa `gaps.jq`:

```jq
def t: .ts[0:19] + "Z" | fromdateiso8601;
def med: sort | if length==0 then null elif length%2==1 then .[length/2|floor] else ((.[length/2-1] + .[length/2])/2) end;
[ .[] | select(.repo | test("/sales_quote$")) ] | group_by(.mission) | map(sort_by(t))
| map( . as $m
  | ([$m[] | select(.event=="session" and .phase=="PR" and .gate=="pass") | t] | first) as $pr
  | ($m | map(.run_id) | reduce .[] as $r ([]; if index($r) then . else . + [$r] end)) as $ids
  | [ $ids[] as $id | ($m | map(select(.run_id==$id))) | {id: $id, inv: .[0].invocation, start: (.[0] | t - (.dur_s // 0)), end: (.[-1]|t), last: .[-1]} ] as $L
  | [ range(1; $L|length) as $i | select($L[$i].inv != "close")
      | {mission: $m[0].mission, gap_min: (($L[$i].start - $L[$i-1].end)/60|round),
         prepr: ($pr == null or $L[$i].start < $pr),
         after: ($L[$i-1].last | if .event=="blocked" then "rc3:"+.kind else .event+":"+(.phase//"")+"/"+(.gate//"") end)} ] )
| flatten
```
