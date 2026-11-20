---
missao: 20261119-l1b-a-rodada-delta
fase: DOCS
status: done
data: 2026-11-20 13:59
gate: "docs em `e6941d6` (README.md, CONTEXT.md e a F6 da gaveta); `tests/check-todo.sh --check TODO.md` → `91 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`; `tests/check-lang.sh` rc 0"
---

# Handoff — DOCS — L1b: a rodada delta

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

O EXEC já tinha escrito o contrato nos lugares que o leem: `docs/pipeline.md` (§ REVIEW e o parágrafo do
`reviewed_head:`), o chapéu `sdd-reviewer` e o espelho dele, o `templates/review.md`, o ato `review` do
`commands/sdd-worker.md` e a ajuda do `bin/sdd`; a ADR 0023 está `accepted`. Esta fase fechou a deriva que
sobrava, em `e6941d6`: o verbo `sdd review-base` na lista de uso do `README.md`, o verbete **Rodada delta**
no `CONTEXT.md` e a linha F6 da gaveta do kit, que ainda dizia que o L1b só estava aprovado.
Uma linha `⛔`: a rule `.claude/rules/anatomia-do-agente.md` (§ 3 e § 4) descreve o boot e o `gate_REVIEW`
sem o delta, e o caminho está fora do `writes:` desta fase; texto proposto abaixo.
`KAIZEN_LOG.md` é `n/a` (`kaizen_log: skipped`, decisão 7). Nenhum item novo no `TODO.md`.

## Estado do repo

- **Branch:** `feat/l1b-a-rodada-delta`, merge-base `336640e` com a `origin/main`; sem push nesta fase.
- **Último commit:** o deste `45-docs.md`, sobre `e6941d6` (os docs).
- **Working tree:** limpo depois do commit.
- **Suíte:** não rodada inteira nesta fase (o diff da fase é só prosa fora da chave do carimbo:
  `README.md`, `CONTEXT.md`, `docs/` e este handoff); a última verde é a da r2 (rc 0, 0 `FAIL`).

## O que foi feito

- `e6941d6` — `README.md`, § Usage: linha do `sdd review-base <mission>`, no texto da ajuda do `bin/sdd`.
- `e6941d6` — `CONTEXT.md`: verbete **Rodada delta** (`reviewed_head:`), logo abaixo do Laço REVIEW⇄EXEC.
- `e6941d6` — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`, linha F6: o L1b rodou até a DOCS, PR a
  abrir, e o L2 mede a razão r≥2/r1 (regra do `CLAUDE.md`: frente que anda atualiza o índice).

## Drift checklist

| Área tocada pelo diff | Documento correspondente | Status | Evidência |
|---|---|---|---|
| `bin/sdd` (`review_base_line`, `cmd_review_base`, `cmd_help`) | `README.md` | ✅ | linha do `sdd review-base` na § Usage, commit `e6941d6` |
| `bin/sdd` (`review_delta_prompt`, `review_head_ok`, `gate_REVIEW`) | `docs/pipeline.md` | ✅ | § REVIEW ("From the second round on…") e o parágrafo "`reviewed_head:` is one key for two programs", commit `a3d0b72` |
| `bin/sdd` (o conceito novo de rodada delta) | `CONTEXT.md` | ✅ | verbete **Rodada delta**, commit `e6941d6` |
| `bin/sdd` (`boot_prompt`/`phase_extra` e `gate_REVIEW`) | `.claude/rules/anatomia-do-agente.md` | ⛔ | § 3 "Onde mora hoje" e § 4 "Onde mora hoje"; texto proposto abaixo |
| `bin/sdd` (o contrato do runner) | `CLAUDE.md` | n/a | nenhuma convenção de trabalho no kit mudou: a missão acrescenta um verbo e uma chave, e o `CLAUDE.md` não lista verbos nem chaves de rodada |
| `agents/sdd-reviewer.md` | `agents/sdd-reviewer.md` | ✅ | o chapéu é o doc: § 1 e § 4 (delta, `reviewed_head:`, achado fora do delta), commits `963e181` e `1d23ca7` |
| `.claude/agents/sdd-reviewer.md` | — | n/a | cópia gerada por `sdd install --force`; `cmp` com a fonte rc 0 nesta fase |
| `templates/review.md` | `templates/review.md` | ✅ | a chave `reviewed_head:` no frontmatter, commit `1d23ca7` |
| `commands/sdd-worker.md` | `commands/sdd-worker.md` | ✅ | o ato `review` roda `sdd review-base` e passa a linha ao subagente, commit `a3d0b72` |
| `bin/sdd-worker` (comentários do `cmd_pr_ready`) | `bin/sdd-worker` | ✅ | os dois comentários que diziam "a chave é só do worker" reescritos, commit `a3d0b72` |
| `docs/adr/0023-the-next-round-reviews-the-delta.md` | `docs/adr/0023-the-next-round-reviews-the-delta.md` | ✅ | `accepted`, emenda a §5 da 0022, commit `e5ceb46` |
| `docs/adr/0023-the-next-round-reviews-the-delta.md` | `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | ✅ | linha F6, commit `e6941d6` |
| `tests/check-gates.sh`, `check-dry-run.sh`, `check-hat.sh`, `check-worker.sh`, `check-coordination.sh` | — | n/a | asserções novas de sensores; o censo de sensores do `CLAUDE.md` não muda (nenhum sensor novo, ainda dezessete) |
| `tests/check-mutation.sh` | — | n/a | mutantes novos no catálogo (`RUN_review_*`, `REVIEW_head_*`); nenhum doc enumera mutantes, e o número de hoje sai da linha `score:` |
| `TODO.md` | `TODO.md` | ✅ | `RESOLVED by a3d0b72` no #436 (`7f7e32f`) e duas âncoras do chapéu deslocadas (`963e181`); `check-todo.sh --check` verde |
| `docs/handoffs/20261119-l1b-a-rodada-delta/*` | — | n/a | artefatos da própria missão |
| `KAIZEN_LOG.md` | `KAIZEN_LOG.md` | n/a | `kaizen_log: skipped` no frontmatter do `00-missao.md` (decisão 7): o número do depois nasce no L2 |

## Proposed text
<!-- sdd:proposed -->

Em `.claude/rules/anatomia-do-agente.md`, § 3 "Gestão de contexto", parágrafo "Onde mora hoje", acrescentar
depois da frase que termina em "nomeia os templates da fase (`phase_templates`).":

> Desde `20261119-l1b-a-rodada-delta` ([ADR 0023](../../docs/adr/0023-the-next-round-reviews-the-delta.md))
> o orçamento vale também para o diff da REVIEW: da segunda rodada em diante o `phase_extra REVIEW`
> (`review_delta_prompt`) escreve a linha do `review_base_line`, e a sessão invoca
> `/codereview:codereview base=<sha>` sobre o `reviewed_head:` da rodada anterior, com essa rodada nomeada
> como a lista dos achados abertos; sem rodada anterior, sem a chave, chave errada ou um merge depois
> dela, a rodada é inteira e o prompt diz por quê. O delta se impõe pelo argumento da skill, nunca por
> frase (r7 do #414). O mesmo juízo responde por `sdd review-base <missão>`, que o ato `review` do worker
> passa ao subagente. A medida em dinheiro (r≥2/r1, antes 1,0 a 1,5) é do L2.

Em `.claude/rules/anatomia-do-agente.md`, § 4 "Mecanismos de verificação", parágrafo "Onde mora hoje",
acrescentar antes de "Desde `20261117-o-worker-orquestrador` (ADR 0022 §5)":

> Desde `20261119-l1b-a-rodada-delta` (ADR 0023) o `gate_REVIEW` lê o `reviewed_head:` da rodada
> (`review_head_ok`): recusa a chave presente e errada (não é commit, o `HEAD` não a carrega, ou código
> fora do `hat_writes REVIEW` mudou entre ela e o commit que **adicionou** a rodada) e aceita a rodada sem
> a chave, como as antigas.

## Achados do TODO_FILE conferidos nesta missão

- **A rodada de revisão relê a missão inteira, porque o chapéu não passa `base=` à skill** (#436, seção
  *Sem seção*): bem formado; ganhou `RESOLVED by a3d0b72` na linha `Fonte:` (`7f7e32f`) e continua aberto
  até o merge, quando é apagado (`git merge-base --is-ancestor`).
- **O platô da REVIEW lê só as letras, e pararia um laço que converge**: só a âncora mudou
  (`agents/sdd-reviewer.md:62` → `:68`, `963e181`); o símbolo `Overall Grade` está no alvo.
- **O revisor não tem destino para o LOW que não move a nota**: só a âncora mudou (`:95` → `:106`,
  `963e181`); o símbolo `MEDIUM/LOW, cheap` está no alvo. Segue aberto: é o L6k da campanha.
- Nenhum item novo nasceu nesta missão; os LOW sem rota das rodadas r1 e r2 ficaram registrados nas
  próprias rodadas. `tests/check-todo.sh --check TODO.md` → `91 finding(s), … every anchor on target`.

## Boot da próxima fase

- A fase seguinte é a PR. O corpo do PR leva a linha `⛔` de `.claude/rules/anatomia-do-agente.md` com o
  texto proposto acima, para o humano aplicar.
- ⚠️ O commit desta fase (`e6941d6`) mexe fora da pasta da missão depois da r2: pelo comentário do
  `cmd_pr_ready` (`bin/sdd-worker`), o `sdd-worker pr-ready` responde `not-ready` sobre a r2 do runner, e o
  worker escreve a rodada própria dele (ADR 0022 §5), como antes desta missão.
- Pendências do humano seguem no `00-missao.md`: a entrada do `KAIZEN_LOG.md` com o número nasce no L2.
