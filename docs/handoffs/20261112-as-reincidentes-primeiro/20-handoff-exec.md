---
missao: 20261112-as-reincidentes-primeiro
fase: EXEC
status: done
sessao: 6f75daaf-9250-42a8-982d-3bd58897e713
data: 2026-11-12 17:35
gate: bash tests/run-all.sh em 5ee401c (clone de rascunho) → rc 0, suite green, 615 s, 2088 ok, 0 FAIL, anchors: all 812 mutants still apply
---

# Handoff — EXEC — Os 13 achados do kit que já voltaram pelo menos uma vez deixam de voltar

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os 15 incrementos, o R1 da revisão final e os R2–R4 da revisão do PR #391 estão `done`: os 13 itens
com `RECURRED` do `TODO.md` têm conserto, asserção nova num sensor e `RESOLVED by <hash>`; os do runner
têm mutante (catálogo 792 → 812). A execução foi fora do `sdd run`, à mão, num worktree ligado, pelo
`superpowers:executing-plans` (decisão 5). Sem `sdd health` nem carimbo (decisão 6). O PR é o #391,
com os achados dos bots consertados numa leva; o próximo passo é o merge, que é do humano.

## Estado do repo

- **Branch:** `fix/as-reincidentes-primeiro` — empurrada, PR #391 contra `main`
- **Último commit:** o do checkpoint de R2–R4 (esta versão do arquivo entra nele)
- **Working tree:** limpo
- **Suíte:** `bash tests/run-all.sh` → verde em `5ee401c`, 615 s, 2088 `ok`, 0 `FAIL`
- **E2E:** não se aplica (o kit não tem interface; `E2E_CMD` vazio)

## O que foi feito

- `60042c9` — I1 (item A): o `/sdd-plan` nomeia a saída quando o agente `sdd-planner` não está registrado
- `01a20ae` — I2 (item B): pergunta nenhuma do planner fica atrás de tarefa viva em segundo plano
- `6841138` — I3 (item D): o planner pode usar o `Monitor` e espera a tarefa viva com ele
- `4fb7109` — I4 (item M): o planner chama as skills `grilling` e `domain-modeling`
- `11556b3` — I5 (item K): o `/sdd-plan` diz o que fazer com a aprovação dada antes do plano
- `92f87fc` — I6 (item L): a fila de PRs de achado ganha receita em `docs/finding-prs.md`
- `21f2278` — I7 (item J): o corpo do PR só promete CI onde há workflow
- `5cde830` — I8 (item C): o `check-todo.sh` recusa o `#N` solto que nomeia um item
- `c40c25a` — I9 (item E): `--help` depois do subcomando só imprime a ajuda
- `f93ed48` — I10 (item F): o `sdd install` não adota a branch de trabalho como base
- `5e8da5e` — I11 (item G): o `sdd approve` aceita o ADR que commita
- `39a3bac` — I12 (item I): o `sdd status` fala antes de rodar o `TEST_CMD`
- `1022cc8` — I13 (item H, 1ª metade): o `sdd status` mostra o stream órfão e a árvore suja
- `59b5f96` — I14 (item H, 2ª metade): o boot da fase cita a sobra da sessão morta
- `0985ff5` — I15: `RESOLVED by` nos 13 itens, entrada do `KAIZEN_LOG.md`, este handoff e a gaveta
- `215fd54` — R1 (revisão final do branch): sujeira sozinha não é sessão morta no boot da fase
- `820787e` — R2 e R3 (revisão do PR #391): o `adr:` do approve dentro do checkout, e o `--help` antes da admissão
- `5ee401c` — R4 (revisão do PR #391): sem workflow, o corpo do PR não afirma que não há CI; o `ls-remote` manual com prazo

Cada incremento tem a sua linha `done` no `checkpoint.md`, num commit `chore(missao)` próprio.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261112-as-reincidentes-primeiro/checkpoint.md` | a tabela, 19 de 19 `done`, com o hash de cada incremento |
| `docs/handoffs/20261112-as-reincidentes-primeiro/checkpoint-notas.md` | as medidas de cada incremento e os desvios |
| `TODO.md` | os 13 itens com `RESOLVED by`, ainda abertos (catraca 86) |
| `KAIZEN_LOG.md` | a entrada de 2026-11-12, com antes e depois medidos |
| `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md` | o parágrafo "Hoje (2026-11-12)" |

## Boot da próxima fase

Não há fase do runner depois desta nesta missão (decisão 5). O PR #391 está aberto. A revisão dos bots
rodou sobre o `f7f94b2`: o CodeRabbit deixou 5 achados (R2, R3, R4, o prazo do `ls-remote` manual e a
reserva do `/sdd-plan`, que o humano decidiu manter), o Codex 1 (o mesmo do R3) e o Copilot não revisou
(sem cota). Uma rodada nova dos bots sobre os consertos vira outra leva `R<n>`; o merge é do humano.
Nunca `./bin/sdd health`.

## Pendências / Decisions for a Human

- Chore pós-merge: apagar os 13 itens com `RESOLVED by` e levar a catraca a 73, pela receita de
  `docs/finding-prs.md`, depois de `git merge-base --is-ancestor <hash> main` valer para cada hash
  (com squash merge os hashes não entram na `main`) — `00-missao.md`, Pendências.
- A `main` fica sem carimbo de mutação até a catraca zerar (decisão 6).
- O `Monitor` liberado ao planner (I3) só se prova no próximo `/sdd-plan`.

## Riscos e não-feitos

- Nenhum catálogo mediu os mutantes antigos depois de os sensores mudarem: o `--anchors` prova que
  todos se aplicam, e o `--only` prova cada um dos 20 novos e os dois reapontados; o resto espera o
  `sdd health` do zero.
- `./bin/sdd why 20261112-as-reincidentes-primeiro EXEC` respondeu `16 increment(s) done, suite green,
  handoff written` no `f7f94b2`; ele lê este arquivo e roda a suíte, então roda de novo depois deste
  commit, e o corpo do PR traz a resposta.

## Achados fora de escopo

- Nenhum item novo no `TODO.md` nesta missão.
