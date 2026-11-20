---
missao: 20261119-l1b-a-rodada-delta
fase: EXEC
status: done
sessao: 0ebc5bba-4917-40b6-a2ad-cea438824a90
data: 2026-11-20 11:16
atualizado: 2026-11-20 13:10
gate: "R1 (c6c381f): tests/run-all.sh rc=0 (suite green, 0 FAIL), --anchors 915 mutantes aplicam, --only REVIEW_head_reads_last_touch contra check-gates.sh rc 1; I5: tests/run-all.sh rc=0 (suite green, 2203 linhas ok, 0 FAIL); Check do I5 → 1 0; check-todo.sh --check TODO.md rc 0 (91 achados); --anchors 91 medidas, 0 off target; sdd review-base da missão → full — no earlier round"
---

# Handoff — EXEC — L1b: a rodada delta

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os cinco incrementos estão `done`. Da segunda rodada em diante a REVIEW revisa só o delta: o runner lê
o `reviewed_head:` da rodada anterior (`review_base_line`, uma definição) e o prompt manda
`/codereview:codereview base=<sha>`. O `sdd review-base <missão>` responde o mesmo juízo ao worker, o
`gate_REVIEW` confere a chave, e o #436 do `TODO.md` ganhou `RESOLVED by a3d0b72`. Suíte verde.
A r1 achou 1 MEDIUM, consertado no `R1` (`c6c381f`): o `review_head_ok` lê o commit que **adicionou**
a rodada. A próxima fase é a REVIEW r2, a primeira **delta** (`base=a6f1817`).

## Estado do repo

- **Branch:** `feat/l1b-a-rodada-delta`, à frente da `origin` pelos commits deste EXEC (nada foi empurrado)
- **Último commit:** o do `chore(checkpoint): I5 done`, depois deste handoff
- **Working tree:** limpo
- **Suíte:** `tests/run-all.sh` → verde (rc 0, 2203 linhas `ok`, 0 `FAIL`)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)

## O que foi feito

- `1ffe344` — I1: `review_base_line` (o juízo do delta: `base=<40 hex>` e a rodada, ou `full` e o
  motivo: sem rodada, sem chave, chave que não é sha, não ancestral, merge no intervalo) e o verbo
  `sdd review-base <missão>`, consulta admitida sem o lock do checkout (braço `*)` do `coordination_enter`). 5 asserções em `check-gates.sh`, 5 mutantes.
- `963e181` — I2: `review_delta_prompt`, chamado pelo `phase_extra REVIEW`: rodada 1 diz `full` e o
  motivo; rodada delta leva `base=` e nomeia a rodada anterior como lista de achados abertos. O chapéu
  do revisor manda o achado fora do delta ao `TODO_FILE`, nunca a um `R<n>`. 3 asserções, 1 mutante.
- `1d23ca7` — I3: `reviewed_head:` no `templates/review.md` e no chapéu; `review_head_ok` no
  `gate_REVIEW`, antes da suíte: recusa a chave que não é sha, não ancestral do `HEAD` ou com código
  alterado entre ela e o commit da rodada; aceita a rodada sem a chave. 5 mundos, 4 mutantes.
- `a3d0b72` — I4: o ato `review` do `commands/sdd-worker.md` roda `sdd review-base` depois do merge
  da base e passa a linha ao subagente; `docs/pipeline.md` (seção REVIEW e o parágrafo do
  `reviewed_head:`) para de dizer que a chave é só do worker. 1 asserção `command:`.
- o commit `docs(todo)` deste handoff — I5: `RESOLVED by a3d0b72` no item #436 do `TODO.md` (dentro da linha `Fonte:`, antes do
  descoberto-por; título intacto, item fica, catraca não muda) e este handoff.

## Consertos da REVIEW r1

- `c6c381f` — R1 (achado #1 da r1, MEDIUM): o `review_head_ok` tomava como commit da rodada o
  **último** que tocou o `40-review-rN.md`; uma DOCS que corrigisse a rodada junto com um doc reprovava
  o `gate_REVIEW` já verde. Agora é o que a **adicionou** (`--diff-filter=A`), como o comentário e a
  ADR 0023 já diziam. O `write_r12` do `check-gates.sh` recria a rodada a cada mundo, um mundo novo
  prova que o commit posterior fica fora do intervalo, e o mutante `REVIEW_head_reads_last_touch`
  entrou no catálogo. Sabotagens nas notas.
- Achado #3 da r1 (LOW, prosa deste handoff): a linha do I1 dizia que o `sdd review-base` pega o lock;
  corrigida acima. O #2 (LOW, a resolução do sha escrita duas vezes) fica como está, sem rota.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | `review_base_line`, `cmd_review_base`, `review_delta_prompt`, `review_head_ok` no fim do arquivo; uma linha no `phase_extra REVIEW` e uma no `gate_REVIEW` |
| `templates/review.md` | a chave `reviewed_head:` no frontmatter |
| `agents/sdd-reviewer.md` (+ espelho `.claude/agents/`) | §1 grava o `reviewed_head:`; §4 o achado fora do delta vai ao `TODO_FILE` |
| `commands/sdd-worker.md`, `bin/sdd-worker` | o ato `review` passa a linha do `sdd review-base` |
| `docs/pipeline.md` | o delta na `### REVIEW` e o `reviewed_head:` como chave das duas rodadas |
| `tests/check-{gates,dry-run,hat,worker,mutation}.sh` | 14 asserções novas e 10 mutantes |
| `docs/adr/0023-the-next-round-reviews-the-delta.md` | a decisão (escrita no PLAN) |

## Boot da próxima fase

Próxima fase: **REVIEW r2**, delta sobre `a6f1817..` (o `reviewed_head:` da r1). O delta é o
`c6c381f` mais os artefatos da missão; leia o `40-review-r1.md` para o achado que ele deixou aberto.
`./bin/sdd review-base 20261119-l1b-a-rodada-delta` → `base=a6f1817… — 40-review-r1.md reviewed this head`.
O que segue abaixo é o boot escrito para a r1, ainda válido.


- O que chega a quem usa o kit: o verbo novo `sdd review-base <missão>` (na ajuda do `sdd`), a linha
  nova do prompt da REVIEW (`full — <motivo>` na r1; `base=<sha>` e a rodada anterior da r2 em diante),
  a chave `reviewed_head:` que **toda** rodada passa a gravar (o `gate_REVIEW` a confere quando
  presente), e o ato `review` do worker.
- A r1 desta missão roda com o prompt novo e diz `full — no earlier round`: grave o `reviewed_head:`
  (o `HEAD` que você revisou) no `40-review-r1.md`, ou a r2 também sai inteira.
- Jornada de verificação, na raiz do worktree:

  ```bash
  o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    review-base: ' <<< "$o"          # 5
  grep -c '^  ok    gate_REVIEW: reviewed_head' <<< "$o"                                # 6 (5 do I3 + 1 do R1)
  grep -c '^  ok    the REVIEW boot prompt of a delta round carries base= and names the round' <<< "$o"   # 1
  ./bin/sdd review-base 20261119-l1b-a-rodada-delta     # full — no earlier round
  bash tests/run-all.sh                                 # rc 0
  ```

- Mutantes novos (`mut_RUN_review_base_*` ×4, `mut_RUN_review_prompt_delta_dropped`,
  `mut_REVIEW_head_*` ×4, `mut_COORD_review_base_locked`): cada um provado por `--only`; o catálogo inteiro é do `sdd health`.

## Pendências / Decisions for a Human

- **A métrica em dinheiro vem do L2** (decisão 7): custo da REVIEW r≥2 ÷ r1, lido do ledger; antes
  1,0–1,5, alvo ≤ 0,5. Já está nas pendências do `00-missao.md`.
- **O item #436 sai do `TODO.md` no chore depois do merge**, provado por `git merge-base --is-ancestor a3d0b72`.

## Riscos e não-feitos

- A REVIEW desta missão roda com o runner da própria branch só se o `sdd` do PATH apontar para ela;
  com o principal, o prompt é o de antes e a r2 não mede o delta. É a decisão 7, não defeito.
- O ato `review` do worker mergeia a base antes de cada rodada: com a `main` andando, o merge no
  intervalo faz a rodada sair inteira (`full — merge …`). Fora de escopo por decisão (ver `00-missao.md`).
- Nenhum `sdd health` rodou: o carimbo é depois do último commit de código, no PR.

## Achados fora de escopo

- Nenhum novo neste EXEC.
