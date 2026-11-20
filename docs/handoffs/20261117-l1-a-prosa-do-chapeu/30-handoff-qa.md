---
missao: 20261117-l1-a-prosa-do-chapeu
fase: QA
status: done
sessao: bd74d1e3-77a4-4ab3-a70c-aa764a8f4f5e
data: 2026-11-19 20:02
gate: "sem interface, jornada no terminal em 84d13e8. (1) ./bin/sdd help → a entrada do sdd why diz 'The gate RUNS: for EXEC, QA or REVIEW, or with no PHASE ... that is the whole TEST_CMD (and E2E_CMD for QA), as in sdd boot'. (2) ./bin/sdd install → 'ok agent sdd-<nome>.md identical' para os oito chapéus (docs, executor, kaizen, planner, publisher, qa, reviewer, ticket). (3) README.md:45 '# git clone https://github.com/j0ruge/sdd_agents.git'; grep -i private README.md → nada. (4) docs/failure-modes.md:793-815 lido; pgrep -af '[b]in/sdd run' sozinho → rc 0, três linhas, todas da corrida viva desta missão (wrapper 3562088, helper 3562102, runner 3562103), nenhuma da shell que buscou. (5) consulta de threads do docs/finding-prs.md:52 → PR 414 'head 7555d22 threads 38 more false unresolved: 0'; PR 445 'head 50c68b4 threads 0 more false unresolved: 0'. TEST_CMD tests/run-all.sh → 'suite green', rc 0, 2181 linhas ok, 0 FAIL, 'all 904 mutants still apply and leave valid code'."
---

# Handoff — QA — L1: a prosa do chapéu e dos docs

## TL;DR

5 passos de jornada percorridos no terminal (os do `01-plano.md`, "Verificação end-to-end"), 0
achados, 0 specs, 0 incrementos `F<n>`, 0 decisões para o humano. A ajuda do `sdd why`, os oito
chapéus iguais ao espelho, o README sem "PRIVATE", a receita do `pgrep` destacado e a consulta de
threads se comportam como o diff promete. Suíte verde. Próximo: REVIEW.

## Estado do repo

- **Branch:** `fix/l1-a-prosa-do-chapeu` — worktree `sdd_agents-l1`
- **Último commit antes deste handoff:** `84d13e8` `chore(checkpoint): I9 done (c27e8c7)`
- **Working tree:** limpo antes do handoff
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 2181 `ok`, 0 `FAIL`, 904 mutantes aplicáveis
- **E2E:** `E2E_CMD` vazio — o kit não tem interface; a jornada foi andada no terminal (`gate:`)

## O que foi feito

- Jornada 1 — `./bin/sdd help`: a entrada do `sdd why` (linhas 79-82 da saída) diz que o gate roda
  o `TEST_CMD` inteiro para EXEC, QA ou REVIEW (e o `E2E_CMD` na QA), como o `sdd boot`.
- Jornada 2 — `./bin/sdd install` (sem `--force`): `agent sdd-<nome>.md identical` nos oito.
- Jornada 3 — `README.md:45`: linha do `git clone` sem "PRIVATE"; `grep -i private` vazio.
- Jornada 4 — `docs/failure-modes.md`, seção "The `sdd run` process itself disappeared": o
  `pgrep -af '[b]in/sdd run'` lista a corrida viva e não a shell que procura. Observado de
  passagem: num comando composto em que o literal **sem** colchetes aparece em outro trecho (um
  `grep 'bin/sdd run' …` no mesmo `-c`), a shell volta a casar — o doc ensina o `pgrep` sozinho, e
  sozinho ele não casa. Não é defeito do diff.
- Jornada 5 — `docs/finding-prs.md:52` contra os PRs reais 414 e 445: a saída traz `head`,
  `threads`, `more` e `unresolved: 0`, como a receita pede para comparar com o `<sha>`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261117-l1-a-prosa-do-chapeu/30-handoff-qa.md` | este handoff |

Nenhuma spec nova (não há jornada de navegador), nenhum bug registrado, nenhum `F<n>`.
O `docs/qa/` do kit não foi tocado.

## Boot da próxima fase

REVIEW (`sdd-reviewer`). A QA não viu nada a consertar. As 15 asserções novas estão em
`tests/check-hat.sh` (13) e `tests/check-templates.sh` (2); o que vale revisar é se cada uma
reprova pelo motivo certo (a frase do chapéu, não um acaso do arquivo) — as notas de red do
I1–I8 no `checkpoint-notas.md` dizem que cada uma foi vista `FAIL` antes da prosa. Use `./bin/sdd`,
nunca o `sdd` do PATH (o checkout principal tem os chapéus de antes, `agent … stale` é esperado
até o merge).

## Pendências / Decisions for a Human

- Nenhuma.

## Riscos e não-feitos

- Os chapéus chegam às sessões das fases, e o efeito deles numa sessão real (o planner falando no
  idioma, o executor escrevendo o `20-handoff-exec.md` no último incremento) só se mede na próxima
  missão que os carregar; aqui foi lida a prosa e a asserção, não o comportamento de uma sessão.
- `sdd install --force` não foi rodado (o espelho já está igual).

## Achados fora de escopo

- Nenhum.
