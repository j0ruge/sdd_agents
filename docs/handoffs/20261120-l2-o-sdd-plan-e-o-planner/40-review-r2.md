---
missao: 20261120-l2-o-sdd-plan-e-o-planner
fase: REVIEW
rodada: 2
status: done
sessao: sdd-reviewer r2 (REVIEW delta sobre 2fc48ac)
data: 2026-11-20 22:54
gate: tests/run-all.sh rc 0 (2231 ok, 0 FAIL, suite green) no head 5430393; Check do R1 → 96; check-checkpoint.sh rc 0 e 0 FAIL; shellcheck -S warning rc 0; pre-scan de segredos (regex e gitleaks) com 0 achados em 7 arquivos; a rodada escreve só o 40-review-r2.md, o checkpoint e as notas
reviewed_head: 5430393026a202269a985f8efbdc04c7d25dfda0
---

# Review — rodada r2 — L2: o `/sdd-plan` e o planner

## TL;DR

Rodada delta sobre `2fc48ac...5430393`: 7 arquivos, e um só de código (`tests/check-checkpoint.sh`,
o R1 em `502ab59`). A revisão foi inline, porque há só um arquivo de código. O R1 fecha o achado #1
da r1, e conferi o Check (rc 96), o sensor e a suíte inteira. Não saiu achado novo. A suspeita de um
fail-open por glob na lista do `--only` foi reproduzida e refutada. Nenhum `R<n>` novo. Os dois
achados de prosa da r1 continuam abertos no `TODO.md`, e é por eles que Documentation fica em B.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O R1 é um ramo a mais no case da gramática do red_args, no lugar certo (depois da lista vazia e do -*), e o comentário diz o porquê. |
| Type Safety | A | Não se aplica a bash; o ramo novo usa ${4-} já guardado pelo ramo anterior e nada de novo fica sem guarda de set -u. |
| Error Handling | A | A lista com espaço, tab ou quebra de linha é recusada com rc 96 antes de qualquer Check (reproduzido: o Check do R1 responde 96), e ids com glob caem na recusa de id desconhecido, rc 1. |
| Security | A | O pre-scan de segredos (regex e gitleaks) não achou nada nos 7 arquivos do delta. |
| Performance | A | Um case a mais por chamada do --red; nada roda a mais. |
| Test Coverage | A | São 4 probes novos (quebra de linha, quebra de linha sem rodar Check, espaço, tab), com PROBE_FLOOR 447, e 9 de 10 sabotagens mortas; o sobrevivente (o piso de volta a 443) é limite declarado. |
| Documentation | B | O delta não piorou a prosa, mas os dois achados de prosa da r1 (o pgrep do passo 1 do /sdd-plan e a ordem do gate_EXEC no plan-only.md) seguem abertos no TODO.md. |
| **Overall** | **A** | A suíte está verde, o único fail-open da r1 está fechado e medido, e a dívida que sobra é só prosa, registrada no backlog. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| — | — | Nenhum achado novo no delta. | — |

## Incrementos de conserto (R<n>)

Nenhum incremento novo nesta rodada.

## O que virou incremento

- Achado #1 da r1 (`--red --only` com quebra de linha na lista rodava 0 Checks e saía 0 com `ok`):
  fechado em `502ab59` pelo `sdd-executor`. A prova: `bash tests/check-checkpoint.sh --red
  docs/handoffs/20261120-l2-o-sdd-plan-e-o-planner/checkpoint.md --only $'R1\nR1' >/dev/null 2>&1;
  echo $?` → `96`, medido neste head (era `0` na r1). O `tests/check-checkpoint.sh` sai rc 0 com 0
  `FAIL` e com a linha `ok    rule: --red --list runs no Check, and --red --only never says every one
  red at HEAD (35 probe(s))`.

## O que foi refutado

- Suspeita minha desta rodada: um id com glob na lista do `--only` (`*`, `I?`, `I[12]`) passaria
  pela validação do `red_one`, que casa `case "$pend" in *",$i,"*)`, e depois não rodaria nenhum
  Check. Refutada por reprodução numa cópia em `mktemp -d`, com um checkpoint de I1 e I2 `pending`.
  As quatro listas saem rc 1 com `--red --only names <id>, which is not a pending row — no Check was
  run`. O `$i` está entre aspas dentro do padrão, então o glob é literal. Já o `--only I1` puro roda 1
  Check e sai rc 0.

## Achados fora de escopo

- Nenhum novo. Os achados #2 e #3 da r1 continuam no `TODO.md`, nos itens "Sem pasta de missão, o
  passo 1 do `/sdd-plan` lê corrida de qualquer repo como dona do checkout" e "O `docs/plan-only.md`
  diz a ordem do `gate_EXEC` e a lista não segue a ordem do gate". A catraca segue em 105.

## Pendências / Decisions for a Human

Nenhuma.
