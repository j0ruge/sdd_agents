---
missao: 20261121-l4-preflight-health-e-sensores
fase: QA
status: done
sessao: c61f48ad-5428-4f3e-88b8-9c327bb1b957
data: 2026-11-22 01:00
gate: "sem interface (E2E_CMD e APP_URL vazios), jornadas de CLI andadas no sha 9b3634d. (1) `env -u CLAUDECODE ./bin/sdd preflight` no worktree → rc 0, `preflight ok`, 23 linhas ok; observado: a linha `hooks the probe session ran — SessionStart: 3 hook(s), exit codes 0 0 0, 3616 bytes`, `ok TEST_CMD ran green (tests/run-all.sh)` (o TEST_CMD inteiro rodou dentro do preflight), `ok TODO_FILE holds its shape (TODO.md): 91 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`, a linha neutra `the preamble of TODO.md matches no revision of templates/todo.pt-BR.md — an author's preamble`, `ok third-party skills present (codereview:codereview)`, a sonda do Bash e a dos templates verdes, nenhum straggler avisado, 0 ocorrências de `erro de escrita`/`write error` (grep -c na saída em /tmp/qa-l4-preflight.log). (2) censo: `grep -cE '^ +if [a-z_]+_escalation \"\\$phase\"; then' bin/sdd` → 15; `grep -cE '^ *hat_guard_check \"' bin/sdd` → 6; `grep -cE '^ *kit_guard_check \"' bin/sdd` → 4. (3) `bash tests/check-todo.sh --count TODO.md` → 91. (4) `bash tests/check-checkpoint.sh --check docs/handoffs/20261121-l4-preflight-health-e-sensores/checkpoint.md` → `ok checkpoint.md: 13 row(s), 12 under the anchor rule, none blind`. (5) `./bin/sdd run <missão> --dry-run` de dentro da sessão → CHECKOUT-BUSY (pipeline recursivo recusado, como desenhado)."
---

# Handoff — QA — L4: preflight, health e sensores

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

QA de CLI (sem interface): 5 jornadas andadas no terminal, no sha `9b3634d`, todas como prometido.
Achados confirmados: 0. Specs e2e novas: 0 (não há `E2E_DIR`; nada a reproduzir). Incrementos de
fix: 0. Para o humano: 0. O `./bin/sdd preflight` do worktree respondeu `preflight ok` (rc 0) com
as linhas novas do lote (hooks por evento, forma do `TODO_FILE`, preâmbulo de autor, skills) e sem
`erro de escrita`.

## Estado do repo

- **Branch:** `fix/l4-preflight-health-e-sensores` — local, não empurrada (o push é da fase PR)
- **Último commit:** `9b3634d` `chore(checkpoint): I13 done em 54a8ffe` (antes deste handoff)
- **Working tree:** limpo antes do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde, rodada pelo próprio `sdd preflight` (`ok TEST_CMD ran green`)
- **E2E:** `E2E_CMD` vazio — o kit não tem interface de produto; não se aplica

## O que foi feito

- jornada 1 — `env -u CLAUDECODE ./bin/sdd preflight`: rc 0; trouxe tudo o que o boot pediu (veja `gate:`).
- jornada 2 — censo das portas: escaladas 13 → 15, `hat_guard_check` 4 → 6, `kit_guard_check` 4 (inalterado).
- jornada 3 — `check-todo.sh --count TODO.md` → 91 (catraca igual; os 15 do lote carregam `RESOLVED by`, apagados só depois do merge).
- jornada 4 — `check-checkpoint.sh --check` sobre o checkpoint da missão (inclui a regra 7 nova do `atualizado:`): ok.
- jornada 5 — `sdd run --dry-run` de dentro da sessão de fase: `CHECKOUT-BUSY`, a recusa de pipeline recursivo, correta.
- Os mundos do I6 (skill não coberta, plugin sem a skill), do I7 (straggler), do I8 (kit fora da `main`) e do I9 (`sdd kaizen` com guarda do chapéu) são reproduzidos pelos probes de `check-preflight.sh`, `check-dry-run.sh` e `check-kaizen.sh`, que rodaram verdes dentro do `TEST_CMD` do preflight. Não rodei `sdd run` real contra o kit (regra do `CLAUDE.md`).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261121-l4-preflight-health-e-sensores/30-handoff-qa.md` | este handoff, com a evidência no `gate:` |
| `/tmp/qa-l4-preflight.log` | saída inteira do preflight (efêmera, fora do repo) |

## Boot da próxima fase

REVIEW: a QA não achou defeito. O que ela viu e o revisor pode querer conferir:

1. O `kit_stale_check` cala num worktree ligado (`gd != common-dir` → `return 0`), então o
   preflight desta QA, rodado do worktree num branch fora da `main`, não avisou nada. É o desenho
   do I8 (o aviso é para o checkout principal do kit), mas vale o revisor confirmar que é a intenção.
2. A linha do preâmbulo do `TODO.md` sai sem prefixo (`the preamble of TODO.md matches no revision…`),
   a "linha neutra" que o I5 promete para o preâmbulo de autor.
3. O `CLAUDE.md` ainda diz 13 portas de escalada; o número medido é 15 — é a linha ⛔ que a DOCS
   já tem anotada (nota do I9).

## Pendências / Decisions for a Human

- Nenhuma.

## Riscos e não-feitos

- Não rodei `sdd run`/`sdd retry`/`sdd kaizen` reais: as paradas novas (I6, I8, I9) foram verificadas só pelos probes da suíte, por regra do kit.
- O `kit_stale_check` não foi exercitado no checkout principal (lá o `sdd` do PATH é o runner velho, sem o I8).

## Achados fora de escopo

- Nenhum.
