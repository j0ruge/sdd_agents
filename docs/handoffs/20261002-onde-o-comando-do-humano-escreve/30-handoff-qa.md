---
missao: 20261002-onde-o-comando-do-humano-escreve
fase: QA
status: done
sessao: 53e210ff-bd2d-4864-b87a-a498b8ca330d
data: 2026-10-02 17:07
gate: "sem interface (E2E_CMD e APP_URL vazios); jornadas percorridas no terminal sobre baea108, em rascunho /tmp/qa-walk-* com SDD_STATE_DIR isolado. J1: na main, com branch feat/x e file.txt sujo, `echo y | sdd approve 20261002-walk` → rc 0, 'ok branch: main → feat/x', HEAD=feat/x, main intacta, commit chore(missao) com 00-missao.md, 01-plano.md, checkpoint.md e checkpoint-notas.md, file.txt fora. J2: `sdd close` com JIRA_ENABLED=false em feat/x, sem 50-pr.md → rc 0, 'back on main'; o caso PR OPEN/MERGED com 50-pr.md é o probe 9b/9c de check-gates.sh (verde na suíte). J3: 00-missao.md como symlink → approve rc 1, 'frontmatter_write: … is a symbolic link', alvo com aprovacao: vazio, link mantido, HEAD sem commit novo; install --force com sdd-qa.md ligado a arquivo de fora e sdd-docs.md ligado a destino inexistente → rc 0, dois 'warn agent … is a link … not touched', destino de fora intacto, nenhum arquivo criado no link quebrado. J4: `bash -c 'tests/check-coordination.sh & wait $!'` → rc 0, 3 de 3 asserções de sinal ok, 0 FAIL; `GIT_REFLOG_ACTION=sdd:REVIEW:deadbeef bash tests/check-autonomy.sh` → rc 0, 448 ok, 0 FAIL. TEST_CMD `tests/run-all.sh` → rc 0 em 298 s, 'suite green', anchors 541 de 541, 0 'timed out after', /tmp/sdd-ck-* 52 antes e 52 depois."
---

# Handoff — QA — Onde o comando do humano escreve

## TL;DR

4 jornadas de CLI percorridas no terminal (approve, close, symlink em approve e install, sensores sob ambiente
envenenado), mais a suíte inteira: tudo verde. 1 achado, sem spec e sem fix: o `sdd close` sem `50-pr.md`
sai da branch da missão e afirma que ela foi mergeada. O plano decidiu esse caso (I4, "nos outros casos,
`close_return_home`"), então o que sobra é escolha do humano. Foi para "Decisions for a Human" e para o
`TODO.md` (catraca 87 → 88). Nenhum `F<n>`, nenhum e2e (o repo não tem interface). Próximo: REVIEW.

## Estado do repo

- **Branch:** `feat/onde-o-comando-do-humano-escreve` — local, sem push.
- **Último commit:** o commit desta fase, sobre `baea108` `chore(checkpoint): I10 done (41d8837) e handoff do EXEC`.
- **Working tree:** limpo depois do commit desta fase.
- **Suíte:** `tests/run-all.sh` → verde, rc 0, 298 s, `anchors: all 541 mutants still apply`.
- **E2E:** não se aplica. `E2E_CMD` está vazio e o kit não tem interface.

## O que foi feito

- este commit — achado do close sem PR no `TODO.md` (`<!-- sdd:open -->`, fim da seção), catraca
  `tests/health-baseline.txt` 87 → 88, e este handoff.

Jornadas, todas sobre `baea108` num repo de rascunho (`/tmp/qa-walk-*`, `SDD_STATE_DIR` próprio, config
mínima com `JIRA_ENABLED=false`):

1. **approve na `main` com `branch: feat/x`** → o HEAD termina em `feat/x` e a `main` não anda. O commit
   leva os quatro arquivos da missão, e o `file.txt` sujo fica fora. Verde.
2. **close sem JIRA em `feat/x`** → volta à `main` (`no upstream, nothing to fast-forward`). A recusa
   do PR `OPEN` só existe quando `50-pr.md` tem `pr_url:`, e esse mundo é o probe 9c do
   `check-gates.sh`, verde na suíte. Sem `50-pr.md`, o close volta à base com qualquer estado do PR.
   É o achado abaixo.
3. **symlink**: o approve com `00-missao.md` ligado morre antes de escrever. O link e o alvo ficam
   intactos e não há commit. No `install --force`, um agente ligado a um arquivo de fora e um ligado a
   um destino inexistente geram dois avisos `not touched`. O destino de fora fica intacto e nada é
   criado no link quebrado. Verde.
4. **sensores sob o ambiente de quem chama**: coordenação lançada com `&` (SIGINT ignorado) → 3 de 3
   probes de sinal ok. Autonomia sob `GIT_REFLOG_ACTION=sdd:REVIEW:deadbeef` → 448 ok, 0 FAIL. Verde.
5. **suíte inteira**: verde. Nenhum passo estourou o prazo. Nenhum `sdd-ck-*` novo em `/tmp`: eram 52
   antes, de corridas anteriores à missão, e continuaram 52.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261002-onde-o-comando-do-humano-escreve/30-handoff-qa.md` | este handoff |
| `TODO.md` | item `sdd close` sem `50-pr.md` sai da branch da missão e diz que ela foi mergeada |
| `tests/health-baseline.txt` | `todo-findings 88` |

O `docs/qa/` existe neste repo e é de outra origem. Esta fase não o leu para escrever nem o tocou.

## Boot da próxima fase

- **REVIEW**: a superfície é de CLI, e as quatro jornadas acima reproduzem cada uma em menos de um minuto
  num rascunho. O ponto que a QA quer que o revisor julgue é o do close:
  `bin/sdd:10681` (`if [ -n "$prurl" ]`) pula a conferência quando não há `pr_url:`, e
  `close_return_home` (`bin/sdd:10637`) imprime `the mission branch is merged and spent` mesmo assim.
  O plano escolheu esse comportamento no I4, então não é desvio de plano. É afirmação sem evidência,
  e o I4 a estendeu ao ramo sem JIRA.
- Ordem do approve: `ensure_mission_branch` roda antes da recusa de symlink do `frontmatter_write`. Num
  `00-missao.md` ligado, o approve recusa sem escrever nem commitar, mas deixa a árvore já na branch
  declarada. Não vale `R<n>` (não perde nada, e o approve seguinte funciona dali), mas vale um olhar.
- A DOCS continua com a lista de drift do `01-plano.md`, § "Para a fase DOCS".

## Pendências / Decisions for a Human

- **O `sdd close` deve recusar quando não há `50-pr.md`/`pr_url:`?** Hoje ele volta à base e afirma o
  merge sem conferir. Isso já era verdade no ramo JIRA, e o I4 levou ao ramo sem JIRA porque o plano
  pedia (`01-plano.md`, § I4, "Nos outros casos, `close_return_home`"). As opções: (a) recusar sem PR
  registrado; (b) voltar à base, mas trocar a frase por uma que não afirme o merge; (c) manter. Agente
  nenhum decide isso, porque muda a promessa do comando. Registrado no `TODO.md`.

## Riscos e não-feitos

- A recusa de PR `OPEN` no ramo sem JIRA não foi refeita à mão com `50-pr.md`. Ela foi lida no probe 9c
  e confirmada verde na suíte, e o percurso manual sem `50-pr.md` revelou o achado acima.
- O approve recusado por symlink deixa a branch declarada criada e em uso (ver Boot).
- O `TMPDIR` inacessível da nota de intervenção não foi refeito à mão. Ele vem do probe do I3, verde na
  suíte. O que foi medido à mão é a ausência de vazamento em `/tmp` na suíte inteira.
- `sdd health` (catálogo de mutação e carimbo) não rodou nesta fase. Ele roda uma vez, depois do último
  commit de código.

## Achados fora de escopo

- `sdd close` sem `50-pr.md` sai da branch da missão e diz que ela foi mergeada → `TODO.md`, seção
  `<!-- sdd:open -->` › fim da lista (catraca 87 → 88).
