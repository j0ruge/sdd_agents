---
missao: 20261121-l3-gates-do-fim-da-linha
fase: DOCS
status: done
sessao: b5508336
data: 2026-11-21 14:39
gate: "docs em `2b16aa0` (failure-modes.md, CONTEXT.md, KAIZEN_LOG.md) e `a56767d` (a linha F6 da gaveta); `bash tests/check-todo.sh --check TODO.md` em `a56767d` → `91 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `bash tests/check-lang.sh` em `2b16aa0` → `0 of 73 surface path(s) still in the allowlist, 0 new`"
---

# Documentação — L3: gates do fim da linha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O `docs/pipeline.md`, a ADR 0024, os dois chapéus e os três templates mudaram no commit de cada
incremento, e conferi que descrevem o código. Esta fase escreveu o que ficou para trás: quatro modos
de falha novos e a saída do conflito com a base por `git merge` no `docs/failure-modes.md`, o
verbete "Head verificado" no `CONTEXT.md`, a entrada do `KAIZEN_LOG.md` (devida: `kaizen_log:` vazio)
com a EXEC em `medium` ao lado do L1 e do L2, e a linha F6 da gaveta. Uma linha `⛔`: a §4 da rule
`anatomia-do-agente.md`, com o texto proposto abaixo. Nenhum item novo no `TODO.md`.

## Estado do repo

- **Branch:** `fix/l3-gates-do-fim-da-linha`, no worktree `/home/joruge/repos/sdd_agents-l3`,
  merge-base `a0004df` (PR #457) com a `origin/main`; sem push nesta fase.
- **Último commit:** o deste `45-docs.md`, sobre `a56767d`.
- **Working tree:** limpo depois do commit.
- **Suíte:** não rodou inteira nesta fase. O diff da fase é só prosa (`docs/`, `CONTEXT.md`,
  `KAIZEN_LOG.md`, este handoff); rodei os sensores que leem esses arquivos (`check-lang.sh`,
  `check-todo.sh --check` e `--anchors`), todos rc 0. A última suíte verde é a da r2, em `0d3f87c`.

## O que foi feito

- `2b16aa0`: no `docs/failure-modes.md`, a seção "A conflict with the base branch on push" manda
  `git merge origin/<DEFAULT_BRANCH>`, nunca rebase (item 7); "A handoff that declares `status:
  blocked`" ganha o `50-pr.md` e a rodada (item 6); três seções novas: `TEST_CMD did not run`
  (item 5), "REVIEW reopens after a round graded A" (item 4) e a recusa do `gate_PR` pelo head ou
  pelo `verified_head:` (itens 1 e 2). No `CONTEXT.md`, o verbete **Head verificado**
  (`verified_head:`, `mission_tip`, irmão do `reviewed_head:`). No `KAIZEN_LOG.md`, a entrada
  `## 2026-11-21 — O L3: …` com o antes (`a0004df`, 926 `mut_`), o depois (943 `mut_`, 32
  asserções), a tabela da EXEC (L1 1,32, L2 3,43, L3 2,73 US$ por sessão), a ressalva de que a
  comparação não isola o effort, e a segunda medida da rodada delta (r2/r1 0,39).
- `a56767d`: linha F6 de `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` (L2 mergeado, L3
  rodado até a DOCS), pela regra do `CLAUDE.md`: frente que anda atualiza o índice no mesmo commit.

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` — `test_cmd_red_why` (rc 126/127, I1 e R1) | `docs/pipeline.md` | ✅ | parágrafo "A `TEST_CMD` that did not run is not a red suite", commit `83b2b3e` |
| `bin/sdd` — `test_cmd_red_why` | `docs/failure-modes.md` | ✅ | seção "A gate says `TEST_CMD did not run`", commit `2b16aa0` |
| `bin/sdd` — `gate_PR`/`gate_REVIEW` armam `GATE_HANDOFF_BLOCKED` (I2) | `docs/pipeline.md` | ✅ | "`status: blocked` in `50-pr.md` stops the line", commit `c42fa76` |
| `bin/sdd` — `status: blocked` no `50-pr.md` e na rodada | `docs/failure-modes.md` | ✅ | seções do `blocked` e do conflito com a base, commit `2b16aa0` |
| `bin/sdd` — `mission_tip`, head do PR e `verified_head:` (I3) | `docs/pipeline.md` | ✅ | "The PR has to carry what the mission closed", commit `5da09d6` |
| `bin/sdd` — `mission_tip` e `verified_head:` | `CONTEXT.md` | ✅ | verbete "Head verificado", commit `2b16aa0` |
| `bin/sdd` — `gate_PR` (head e `verified_head:`) | `docs/failure-modes.md` | ✅ | seção "The `PR` gate refuses: the head of the PR, or `verified_head:`", commit `2b16aa0` |
| `bin/sdd` — `review_later_code_ok` (I4) | `docs/pipeline.md` | ✅ | parágrafo do `gate_REVIEW` ("Code committed after the round reopens REVIEW"), commit `7be7b47` |
| `bin/sdd` — `review_later_code_ok` | `docs/failure-modes.md` | ✅ | seção "REVIEW reopens after a round graded A", commit `2b16aa0` |
| `bin/sdd` — K8 do `gate_DOCS` lê `mission_tip` (I5) | `docs/pipeline.md` | ✅ | `### DOCS`, a recusa nomeia o branch, commit `66a9bd0` |
| `bin/sdd` — histórico do e2e vermelho no `gate_QA` (I6) | `docs/pipeline.md` | ✅ | seção do `gate_QA`, commit `45c8434` |
| `bin/sdd` — contagem das linhas `kit:` no `gate_PR` (I7) | `docs/pipeline.md` | ✅ | "When the handoffs carry `- kit:` lines", commit `5e8b000` |
| `bin/sdd` — `gate_REVIEW`, `gate_PR` e K8 | `.claude/rules/anatomia-do-agente.md` | ⛔ | §4, logo depois do parágrafo "Desde `20261119-l1b-a-rodada-delta` (ADR 0023) o `gate_REVIEW` lê o `reviewed_head:`"; texto em "Texto proposto" |
| `bin/sdd` (nenhum comando, flag ou chave nova) | `README.md` | n/a | o uso do `sdd` não mudou: os gates leem mais, e nenhum verbo nem opção entrou |
| `bin/sdd` (nenhuma chave de config nova) | `config/schema.md` | n/a | `verified_head:` é chave de artefato do `50-pr.md`, documentada no `docs/pipeline.md` e no chapéu, não do `.sdd/config.sh` |
| `bin/sdd` e `tests/*` (nenhum sensor novo) | `CLAUDE.md` | n/a | asserções em sensores que já existem; a lista "Os dezessete" segue certa e nenhuma convenção mudou |
| `docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md` | `docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md` | ✅ | a ADR é o doc, escrita e corrigida no plano, commit `24b9653` (o único da branch que a toca); `sdd adr check` verde no plano |
| `agents/sdd-publisher.md` (merge, `verified_head:`, REST, `kit:`, "how to verify", pendência respondida) | `agents/sdd-publisher.md` | ✅ | o chapéu é o doc; frases em `c42fa76`, `5da09d6` e `5e8b000`, cada uma com asserção em `tests/check-hat.sh` |
| `agents/sdd-reviewer.md` (`blocked` da rodada, código depois da rodada) | `agents/sdd-reviewer.md` | ✅ | o chapéu é o doc; frases em `c42fa76` e `7be7b47`, com asserção em `tests/check-hat.sh` |
| `.claude/agents/sdd-publisher.md` e `.claude/agents/sdd-reviewer.md` | — | n/a | espelhos gerados por `sdd install --force`; `cmp -s` contra `agents/` → rc 0 (métrica 5) |
| `templates/review.md` (`blocked`, `gate:`) | `templates/review.md` | ✅ | o template é o doc; `c42fa76` e `b912a33`, com asserção em `tests/check-templates.sh` |
| `templates/handoff.md` (`gate:`) | `templates/handoff.md` | ✅ | o template é o doc; `b912a33`, com asserção em `tests/check-templates.sh` |
| `templates/pr-body.md` (`kit:`, pendência respondida, linha do preflight) | `templates/pr-body.md` | ✅ | o template é o doc; `5e8b000`, com asserção (o R1, `d4c4e97`, endureceu a asserção, não o template) em `tests/check-templates.sh` |
| `tests/check-gates.sh`, `check-autonomy.sh`, `check-hat.sh`, `check-templates.sh`, `check-mutation.sh`, `check-kaizen.sh` | — | n/a | asserções e mutantes em sensores que já existem; o porquê de cada um mora no comentário do próprio teste, e nenhum doc descreve as asserções uma a uma |
| `TODO.md` (13 `RESOLVED by`, âncoras deslocadas) | `TODO.md` | ✅ | `e8d7f4b` e os commits de cada incremento; `--check` e `--anchors` → 91, 0 fora do alvo |
| a missão inteira (`kaizen_log:` vazio) | `KAIZEN_LOG.md` | ✅ | entrada `## 2026-11-21 — O L3: …`, que cita `20261121-l3-gates-do-fim-da-linha`, commit `2b16aa0` |
| a frente F6 (o L3 rodou) | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | linha F6, commit `a56767d` |
| `docs/handoffs/20261121-l3-gates-do-fim-da-linha/*` | — | n/a | artefatos da própria missão |

## Texto proposto
<!-- sdd:proposed -->

Em `.claude/rules/anatomia-do-agente.md`, § 4 ("Mecanismos de verificação"), logo depois do
parágrafo que começa "Desde `20261119-l1b-a-rodada-delta` (ADR 0023) o `gate_REVIEW` lê o
`reviewed_head:`", acrescente:

> Desde `20261121-l3-gates-do-fim-da-linha` ([ADR 0024](../../docs/adr/0024-the-end-of-line-gates-read-the-head-they-check.md),
> que emenda a 0023) os gates do fim da linha leem o head que conferem. O `gate_REVIEW` reabre a fase
> quando um commit da missão posterior ao da rodada, que não é merge, toca caminho fora do `writes:`
> da REVIEW e da DOCS (`review_later_code_ok`), nomeando o commit e o caminho; a prosa da DOCS fica
> para o L6b, e a resolução de um merge da base fica com o `sdd-worker pr-ready`. O `gate_PR` exige o
> `headRefOid` do PR igual à ponta da missão (`mission_tip`: o `HEAD` no `branch:` declarado, senão a
> ponta desse branch) e, com o `verified_head:` do `50-pr.md`, que só a pasta da missão mudou entre o
> sha em que o publisher rodou a suíte e esse head; PR `MERGED` não é comparado. O K8 do `gate_DOCS`
> mede a mesma `mission_tip`, e o branch apagado ou já na base dá intervalo vazio. O `status: blocked`
> do `50-pr.md` e da rodada mais nova arma o `GATE_HANDOFF_BLOCKED` (rc 3, `handoff-blocked`); na
> rodada, `blocked` é a que não pôde ser feita ou espera decisão humana. Um `TEST_CMD` que sai 126 ou
> 127 sem ter começado tem motivo próprio (`test_cmd_red_why`), nunca "suíte vermelha". Cada leitura
> tem asserção em `tests/check-gates.sh` e um mutante no catálogo (`mut_PR_head_unread`,
> `mut_REVIEW_later_code_unread`, `mut_DOCS_k8_reads_head_off_branch`, entre os 17 da missão).

## Achados do `TODO_FILE` conferidos nesta missão

- **Forma do arquivo:** `bash tests/check-todo.sh --check TODO.md` → `91 finding(s), all within 8
  lines, carrying anchor + date, every anchor on target`; `--anchors` → `91 measured, 0 off target`.
- **Os 13 itens do lote** levam `RESOLVED by <hash>` com o hash do incremento que os consertou (I9,
  `e8d7f4b`), e os títulos estão byte a byte iguais. Seguem abertos até o chore de pós-merge.
- **Nenhum item novo** nasceu nesta missão: o diff do `TODO.md` contra `a0004df` é `RESOLVED by` e
  deslocamento de âncora (inclusive nos registros de `<!-- sdd:decided -->`, só número de linha).
- **Os dois LOW da r2** (127 de dois comandos ausentes lido como suíte que começou; o ramo novo do
  `test_cmd_red_why` sem mutante no catálogo) não entraram no `TODO.md`, e concordo: pela régua de
  admissão (D15) nenhum é sensor que afirme medir o que não mede, e o primeiro ainda nomeia o comando
  e o remédio certos. Ficam registrados na `40-review-r2.md`.
- Nada foi refutado nem decidido nesta fase.

## Boot da próxima fase

A PR lê o TL;DR e a tabela acima. Há **uma linha `⛔`**: o corpo do PR tem de nomear
`.claude/rules/anatomia-do-agente.md` numa linha com `⛔` e levar o texto proposto ao humano. O
corpo lista as escolhas feitas sob delegação (pendência 3 do `00-missao.md`: os `◆` das decisões 2,
3, 4, 5 e 6, e as decisões 3, 7, 11 e 12, que tocam regra do dono). O merge é por **merge commit**,
nunca squash, para os 13 hashes chegarem à `main`. O rc 2 do `gate_PR` por falta do carimbo de
mutação quer dizer "PR pronto para revisão" (pendência 7). As regras novas só valem depois do merge
(pendência 5): os gates que julgam esta corrida são os de antes.

## Pendências / Decisions for a Human

- **Aplicar o `⛔`** da §4 da `anatomia-do-agente.md` (pendência 9 do `00-missao.md`).
- **O chore de pós-merge** (pendência 6): apagar os 13 itens provados por `git merge-base
  --is-ancestor`, descer `todo-findings` e sincronizar o espelho de issues.
- **O effort da EXEC** segue `medium`: a tabela do `KAIZEN_LOG.md` não refuta nem prova o veredito,
  porque o L3 é trabalho de outra natureza que o L1 e o L2.

## Riscos e não-feitos

- A suíte inteira não rodou nesta fase (só prosa no diff); os sensores que leem os arquivos tocados
  rodaram.
- A tabela do `KAIZEN_LOG.md` conta as sessões até a abertura da DOCS; a DOCS e a PR fecham no
  diário da campanha.

## Achados fora de escopo

Nenhum novo nesta fase.
