---
missao: 20261006-lote-5-o-que-o-lote-4-deixou
fase: EXEC
status: done
sessao: 773a289e-20ea-4203-817a-084658e86831
data: 2026-10-06 14:03
gate: "tests/run-all.sh → rc 0, 'suite green' (1890 linhas '  ok ', 0 FAIL, 592 s com TMPDIR=/tmp/l5-exec); anchors: all 656 mutants still apply and leave valid code; checkpoint I1–I12 done, cada Commit um sha no git log; check-todo: '13 finding(s), all within 8 lines, carrying anchor + date, every anchor on target' = todo-findings 13, 12 com RESOLVED by"
---

# Handoff — EXEC — Lote 5: o que o lote 4 deixou

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 12 incrementos estão `done`, executados de forma interativa no worktree ligado
`~/repos/sdd_agents-lote-5` (ADR 0016 §2), cada um com o Check do plano medido vermelho antes e
verde depois. As 12 issues (#223–#230, #232–#235) carregam `RESOLVED by` no `TODO.md`; a 13ª (o
`sdd kaizen` no checkout principal, #236) fica aberta, decisão 11b. Comportamento novo: a suíte, o
catálogo e todo sensor limpam o `GIT_DIR` de quem chama (I1); a linha curta da tabela é recusada
pelo nome (I2); `deferred` sem `## Decis…` no bug barra a QA (I4); o relatório da base exige blob de
checkpoint da missão (I5, ADR 0016 §1); a guarda do kit vê o kit sujo editado de novo e diz o que
mudou (I6); a nota `intervention:` só existe na volta que abre sessão, nas três portas (I7); a
página do `sdd status` cala sem `session` local e o `ok` do `note-manual` diz o que fez (I8); o
supervisor nomeia quem segura o checkout e o `turn_rule` avisa toda fase (I9); o `/sdd-plan` no kit
abre um worktree ligado (I10). ADR 0016 aceita, 0015 ganha `Amended by: 0016`. Catálogo 619 → 656,
todos aplicam. Catraca 13 na branch (N = 0 nascidos) → 1 depois do chore. Próximo: push, PR, todos
os bots, uma leva de consertos, `./bin/sdd health` UMA vez no worktree (com o `mutation-killers.tsv`
copiado), merge pelo humano.

## Estado do repo

- **Branch:** `fix/lote-5-o-que-o-lote-4-deixou`, só local, no worktree `~/repos/sdd_agents-lote-5`
  (nunca empurrada; base `origin/main` = `89df2e5`)
- **Último commit:** o commit deste handoff (I11)
- **Working tree:** limpo depois do commit deste handoff
- **Suíte:** `tests/run-all.sh` → verde (rc 0, 592 s; 1890 linhas `ok`; 656 mutantes com âncora válida)
- **E2E:** não se aplica (o kit não tem `E2E_CMD`)
- **Carimbo de mutação:** inválido para esta branch desde o I12 (esperado); o `sdd health` roda UMA
  vez, depois dos bots, no worktree

## O que foi feito

- `5df5176` — I12 (feito no planejamento): o `/sdd-plan` commita o que o `sdd approve` deixa; o relay segura o que não é resposta
- `fc763ef` — I1 (#226): `tests/isolate-git.sh` em 17 arquivos; 12 de 16 sensores moviam a isca, 0 depois
- `dfd9ab5` — I2 (#224): a linha `|`-led com menos de cinco células é recusada pelo nome nos dois leitores
- `802b6d5` — I3 (#223): o `red_norm` guarda o array vazio (docker `bash:4.3`: 1 → 0)
- `4d72973` — I4 (#232): `deferred` só vale com `## Decis…` fora de cerca no corpo do bug
- `ed5ef44` — I5 (#225): relatório da ponta da base exige blob de checkpoint escrito pela missão
- `6a5c3bb` — I6 (#233): a guarda do kit compara a árvore suja por caminho e conteúdo, e diz o que mudou
- `8778be8`, `0f5ad85`, `92f7d5c` — I7 (#228, #227, decisão 11a): remédio do carimbo impossível; nota só com sessão nas três portas
- `e892814`, `57ea34f` — I8 (#229, #230): status cala sem `session` local; o `ok` do `note-manual` lê `CHECKPOINT_NOTE`
- `daf3a8e` — I9 (#234): `name_stragglers` no supervisor; o `turn_rule` ganha o processo em background
- `4e9c854` — I10 (#235): passo 2 do `/sdd-plan` (worktree ligado no próprio kit)
- este commit — I11: `RESOLVED by` nos 12, ADR 0016 aceita, emenda na 0015, drift, `KAIZEN_LOG.md` e este handoff

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/checkpoint-notas.md` | uma nota por incremento: Red medido, desvios, sabotagens, re-provas |
| `docs/adr/0016-the-mission-checkpoint-and-the-kit-worktree.md` | §1 posse do relatório (emenda a 0015 §3), §2 missão do kit em worktree; `accepted` |
| `tests/isolate-git.sh` | a definição única que limpa as variáveis de repositório do git |
| `KAIZEN_LOG.md` | entrada `2026-10-06 — Lote 5: o que o lote 4 deixou` |

## Boot da próxima fase

Execução interativa (decisão 2 do grill), no worktree, nunca `sdd run` no kit. Ordem, a mesma do
lote 4 (`CLAUDE.md` § carimbo):

1. `git push -u origin fix/lote-5-o-que-o-lote-4-deixou` e abrir o PR com o corpo do
   `templates/pr-body.md`, declarando as quatro mudanças de comportamento (abaixo);
2. esperar **todos** os bots (`@codex review`; `@coderabbitai review` se pausar) e consertar numa leva;
3. `mkdir -p .sdd/cache && cp /home/joruge/repos/sdd_agents/.sdd/cache/mutation-killers.tsv .sdd/cache/`
   no worktree, e só então `./bin/sdd health` UMA vez (lançador `setsid`, env sem `CLAUDE*`/`GIT_*`,
   `TMPDIR` curto, vigiar pelo PID);
4. merge pelo humano; depois o chore pós-merge (catraca 13 → 1) e o re-sync do espelho de issues.

**Mudanças de comportamento a declarar no PR:** I4 (um bug `deferred` sem a seção de decisão
bloqueia a QA); I6 (um kit sujo editado durante a fase de um alvo para a linha); I7 (a nota
`intervention:` do `--phase`, do `retry` e do `--budget-override` só existe quando a volta abre
sessão, e a da override carrega a fase da sessão comprada); I9 (o supervisor imprime uma linha a
mais no stderr).

## Pendências / Decisions for a Human

- O momento do `sdd health` (passo 3 acima) — o carimbo é do humano (ADR 0015 §1).
- O merge, o chore pós-merge e o re-sync do espelho de issues (`todo_issues.py --apply`, depois
  `--apply --close-orphans`).
- A remoção do worktree e da branch local depois do merge; o yokoten nos repos-alvo.
- O desenho da #236 (`sdd kaizen` no checkout principal), aberta de propósito (decisão 11b).

## Riscos e não-feitos

- **Carimbo não medido:** o catálogo de 656 mutantes só roda no `sdd health`; as re-provas desta
  leva foram por `--only` (dica), cada mutante novo e os vizinhos que o plano nomeia.
- **`TMPDIR` longo:** cinco `--only` contra o `check-autonomy.sh` deram `HARNESS-BROKEN` com o nome
  do mutante no `TMPDIR` (limite já declarado no sensor desde `0c0e13a`); com `TMPDIR` curto, todos
  pegos. O `sdd health` roda com `TMPDIR=/tmp`.
- **Sem probe, declarados no código:** o `GIT_OPTIONAL_LOCKS=0` do `kit_guard_tree` (I6); o
  `GITENV_FLOOR=0` sozinho (I1); o reset do `CHECKPOINT_NOTE` e o braço `*` do `case` (I8); o grace e
  o "não nomear quando chegou sinal" (I9); o re-arm da árvore do kit (I6).
- **Desvios do protótipo, todos medidos e anotados nas notas do checkpoint:** I6 ganhou o
  `GIT_OPTIONAL_LOCKS=0` que o plano pedia e o patch não tinha; I10 ganhou a frase do `./bin/sdd` e a
  8ª verificação do probe; I7 corrigiu "decision 10a" para 11a.

## Achados fora de escopo

Nenhum achado novo nesta leva (N = 0): a catraca fica em 13 na branch.
