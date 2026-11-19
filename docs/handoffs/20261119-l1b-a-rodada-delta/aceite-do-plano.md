# Aceite do plano — L1b: a rodada delta

> Extrato que o dono leu antes do `sdd approve` (ato `approve` do `commands/sdd-worker.md`).
> Escrito pela sessão orquestradora em 2026-11-19, sobre `cc8509a`. A fonte é o `00-missao.md` e o
> `01-plano.md` ao lado; este arquivo não os substitui.

**Goal:** da segunda rodada em diante, a REVIEW revisa só o que mudou desde a rodada anterior
(`/codereview:codereview base=<sha>`), e o ato `review` do worker usa o mesmo delta. Fecha o #436.

**Architecture:** um juízo só no `bin/sdd`, com três leitores:
- `review_base_line` lê o `reviewed_head:` da rodada mais nova e responde `base=<40 hex>` ou
  `full — <motivo>`. Os motivos: sem rodada, sem a chave, a chave não é commit, não é ancestral do
  `HEAD`, ou houve merge no intervalo.
- Leem esse juízo o `phase_extra REVIEW` (o prompt da sessão), o verbo novo `sdd review-base <missão>`
  (o ato `review` do worker) e, por meio do `review_head_ok`, o `gate_REVIEW`, que recusa a chave
  presente e errada e aceita a ausente como legado.

**Tech Stack:** bash (`bin/sdd`), markdown (chapéu, template, comando do worker, docs) e sensores
em `tests/`. ADR 0023, que emenda a §5 da 0022.

## Restrições

- **Escopo:** só o #436. O #340 fica para o L6a, o #417 segue aberto, a régua de severidade é do
  L6k, e a medida em dinheiro fica para o L2.
- **Grill:** `10 (recommended) of 10`, com as decisões no `00-missao.md`.
- **Código novo vai no fim do `bin/sdd`**, para não tirar do alvo as âncoras do `TODO.md`. O
  `coordination_enter` não muda.

## Tarefas

### Task I1 — o juízo do delta e o verbo `sdd review-base`
**Files:** `bin/sdd` (fim, `main`, `cmd_help`), `tests/check-gates.sh`, `tests/check-coordination.sh`, `tests/check-mutation.sh`
- [ ] Cinco asserções `review-base: …` no `check-gates.sh`, vermelhas com `unknown command`.
- [ ] Implementar `review_base_line` e `cmd_review_base`.
- [ ] Escrever cinco mutantes: `RUN_review_base_{absent_as_base,commit_unchecked,ancestry_unchecked,merge_ignored}` e `COORD_review_base_locked`.
- **Check:** `grep -c '^  ok    review-base: '` → `5`

### Task I2 — o prompt da REVIEW diz qual rodada é
**Files:** `bin/sdd` (`phase_extra`), `agents/sdd-reviewer.md` (+ espelho por `install --force`), `tests/check-{dry-run,gates,hat}.sh`, `tests/check-mutation.sh`
- [ ] Três asserções:
  - o prompt da primeira rodada diz `FULL round (no earlier round)`;
  - o da rodada delta traz `base=<sha>` e nomeia o r12;
  - o chapéu manda o achado fora do delta ao `TODO_FILE`.
- [ ] Escrever o mutante `RUN_review_prompt_delta_dropped`.
- **Check:** `1 1 1`

### Task I3 — a rodada grava o head, e o gate confere
**Files:** `templates/review.md`, `agents/sdd-reviewer.md`, `bin/sdd` (`review_head_ok` + uma linha no `gate_REVIEW`), `tests/check-{gates,worker}.sh`, `tests/check-mutation.sh`
- [ ] Cinco mundos `gate_REVIEW: reviewed_head …`:
  - três recusas: não é sha, não é ancestral, código mudado antes do commit da rodada;
  - duas aprovações: a chave ausente e a chave válida.
- [ ] Escrever quatro mutantes `REVIEW_head_*`.
- **Check:** `5 1`

### Task I4 — o ato `review` do worker usa o delta
**Files:** `commands/sdd-worker.md`, `docs/pipeline.md`, `bin/sdd-worker` (comentários), `tests/check-worker.sh`
- [ ] A asserção `command: the review act passes the line of sdd review-base to its subagent`.
- [ ] Reescrever as frases que diziam que a rodada do runner não tem a chave, sem mudar o número de linhas dos comentários.
- **Check:** `1 0`

### Task I5 — fecho
**Files:** `TODO.md`, `20-handoff-exec.md`
- [ ] O `RESOLVED by <hash do I4>` no #436, e o `check-todo.sh --check` e `--anchors` limpos.
- **Check:** `1 0`

## Medidas do aceite (2026-11-19)

- `sdd why … PLAN`: `aprovacao: <empty>`, pede `sdd approve`.
- `tests/check-checkpoint.sh --check`: `5 row(s), 4 under the anchor rule, none blind`, rc 0, às 18:19.
- `tests/check-checkpoint.sh --red`: `5 pending Check(s), every one red at HEAD`, das 18:19:52 às 18:27:22.
  Os valores que cada Check imprime: I1 `0`, I2 `0 0 0`, I3 `0 0`, I4 `0 1`, I5 `0 1`.
- O sim do dono: "Sim, aprovo", dado já sabendo do ✗ do critério b.

## PLAN-AUTO

| # | Status | Nota |
|---|---|---|
| a | ✅ | 10 perguntas e 10 respostas; quatro pendências com dono |
| b | ✗ | só o K8, pela decisão 7: `kaizen_log: skipped`, e a entrada nasce no L2 |
| c | ✅ | autocontenção "only-if": quatro bloqueios e nove lacunas corrigidos; a segunda passada não rodou |
| d | ✅ | 5 de 5 vermelhos no HEAD |
| e | ✅ | `JIRA_ENABLED=false` |
| f | ✅ | ADR 0023, e o `sdd adr check --phase plan` com rc 0 |

## Pendências para o humano

1. A entrada do `KAIZEN_LOG.md` com o número r≥2/r1, no L2.
2. Mergear o PR #445 antes de o worker lançar esta missão.
3. Trazer a `main` ao branch depois do merge do L1, e rodar `--check` e `--red` de novo.
4. Decidir o effort das fases (`EFFORT_*`) antes do `sdd run`.
