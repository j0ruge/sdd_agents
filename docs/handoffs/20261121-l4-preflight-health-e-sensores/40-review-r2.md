---
missao: 20261121-l4-preflight-health-e-sensores
fase: REVIEW
rodada: 2
status: done
sessao: 0f01b532-0c2d-4411-8117-0387bf1ac37d
data: 2026-11-22 03:26
gate: "tests/run-all.sh em 5d705acd21009cdc170472c8b0d59ae5f888c0b7 → rc 0, suite green, 2336 linhas ok, 0 FAIL (grep -cE '^  FAIL'), anchors: all 986 mutants still apply and leave valid code; árvore limpa antes da rodada (git status --short vazio); varredura de segredos do codereview sobre 74d35db...HEAD: 0 achados (regex + gitleaks, 9 arquivos, 204 linhas)"
reviewed_head: 5d705acd21009cdc170472c8b0d59ae5f888c0b7
---

# Review — rodada r2 — L4: preflight, health e sensores

## TL;DR

Rodada delta sobre `74d35db...5d705ac`, com 4 commits: o R1 (`5369a53`), o handoff, o checkpoint e a
própria r1. O delta tem 9 arquivos e +204/−33 linhas, das quais 70 são código em `bin/sdd` e em três
sensores. Os seis LOW da r1 estão fechados e cada um tem a asserção que o Check pede. Nenhum achado
novo de severidade MEDIUM ou maior. Sobrou um LOW, que reproduzi numa cópia: o `hat_guard_check` da
porta do retry do `cmd_kaizen` não tem mutante, mas o sensor o pega. Fica como limite medido, sem
`R<n>`. A suíte está verde e a nota é A em todos os critérios.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O delta é pequeno e local. O `if ! x="$(…)"` troca a sentinela `?? ` por um ramo próprio, e o `unread` entra como um quarto estado nomeado, sem reaproveitar o `none`. |
| Type Safety | A | Em bash não há tipos. Os estados do `probe_ran` (`ran`, `none`, `unread`) são despachados com `=` literal, e o `${fo_…:-0}` protege a aritmética do lado vazio. |
| Error Handling | A | As duas leituras que falhavam caladas agora dizem a falha delas: `git status` (`bin/sdd:7829`) e o jq da sonda do `Bash` (`bin/sdd:7318`, ramo `unread` em 7334). Nenhuma grafia antiga sobrou (o grep de `git status failed)` e de `probe_ran=none` não acha nada em `bin/`, `tests/` nem `docs/`). |
| Security | A | Sem segredos: regex e gitleaks deram 0 achados. O `_fail` novo do `unread` corta a resposta em 120 bytes, como os ramos vizinhos. |
| Performance | A | Custo novo, só em teste: um `jq -c` e um `preflight` stub a mais no `check-preflight.sh`, e um `sed` no `check-checkpoint.sh`. A suíte rodou verde. |
| Test Coverage | A | Os seis LOW da r1 têm asserção com controle (índice corrompido com testemunha do erro do git, jq rc 5 com o marcador presente na resposta, mundos wt/det medidos, as duas contagens lidas, CRLF), e a sabotagem foi registrada nas notas do R1. O resíduo é o achado #1, e o sensor o pega: `FAIL  kaizen: the retry session that crosses stops too, by its own read`. |
| Documentation | A | Cada bloco novo traz um comentário com o porquê e a rodada que o pediu (`r1 #N of the L4`). As 21 âncoras do `TODO.md` remapeadas passam no `check-todo.sh --anchors` da suíte. |
| **Overall** | **A** | Os seis LOW da r1 estão fechados num commit só (`5369a53`), revertível sozinho. O delta não tem achado acima de LOW nem de comportamento. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | O R1 fechou o #6 da r1 só na primeira porta. O achado dizia que nenhum mutante tirava "um dos dois" `hat_guard_check` do `cmd_kaizen`. O `mut_KAIZEN_hat_guard_check_dropped` tira o `"${before%%\|*}"`, mas o `"${after%%\|*}"` da porta do retry continua sem mutante. Reproduzido numa cópia (`git archive` em `mktemp -d`, a linha trocada por `:`): `check-kaizen.sh` deu rc 1, com 233 ok e o FAIL `kaizen: the retry session that crosses stops too, by its own read`. O sensor mede, e o que falta é só a prova do catálogo. | `bin/sdd:12964`, `tests/check-mutation.sh:3062-3066` |

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. O achado #1 é LOW e o comportamento que ele cobre já está medido por um sensor,
que reproduzi vermelho. Um `R<n>` compraria uma sessão de EXEC e mais uma rodada para acrescentar um
mutante redundante. Pela régua D15 do `CLAUDE.md`, também não é item do `TODO.md`: não há fail-open
nem consumidor fora da suíte. Fica registrado aqui como limite medido, e o mutante pode entrar quando
alguém mexer nesse catálogo.

## O que virou incremento

Nada nesta rodada. Os incrementos da rodada anterior fecharam assim:

- r1 #1 (`git status` que falha era lido como "tudo não versionado"): fechado em `5369a53`. Prova:
  `preflight says git status failed, and never that the dirty paths are untracked, when git status fails`,
  num mundo de índice corrompido com a testemunha `index file smaller than expected`, `exclude=0`.
- r1 #2 (jq que falha era lido como marcador repetido): fechado em `5369a53`. Prova: a asserção
  `…could not be read when jq fails on it…` dá `unread=1,ok=0,repeat=0,cannot=0,marker=yes`, ou seja,
  o marcador está na resposta e mesmo assim a culpa não vai para o modelo.
- r1 #3 (mundos wt/det sem testemunha): fechado em `5369a53`. Prova: a asserção `the silent worlds of
  kit_stale_check are a linked worktree and a detached HEAD…` mede `--absolute-git-dir` ≠
  `--git-common-dir` e `symbolic-ref` vazio com `HEAD` válido.
- r1 #4 (`fails_of` vazio pulava a asserção): fechado em `5369a53`. Prova: `the hooks block reads both
  failure counts it subtracts`, e o `${fo_…:-0}` faz a subtração seguinte rodar mesmo assim.
- r1 #5 (CRLF sem probe na regra 7): fechado em `5369a53`. Prova: `rule: an atualizado later than the
  clock is refused in a checkpoint with CRLF line ends`, com `PROBE_FLOOR` 461 e `RULE_FLOOR` 12.
- r1 #6 (`hat_guard_check` do `cmd_kaizen` sem mutante): fechado em parte em `5369a53` com o
  `mut_KAIZEN_hat_guard_check_dropped`, que o `--anchors` diz aplicar. O resíduo é o achado #1 acima.

Os seis Checks do R1 dão `1 1 1 1 1 1` na saída da suíte desta rodada (2336 ok).

## O que foi refutado

- Hipótese: o ramo `unread` estaria fora de ordem e engoliria um `ran`. Refutada. O `probe_ran` só
  vira `unread` quando o jq sai com erro, e aí ele não pode ser `ran`. O ramo vem depois dos dois
  `ran` e antes do teste do marcador na resposta (`bin/sdd:7330-7339`), que é a ordem que o achado
  pedia.
- Hipótese: o `fails_of` poderia matar o sensor quando a contagem é zero. Refutada. O
  `check-preflight.sh` roda sob `set -uo pipefail`, sem `-e` (linha 32), e o `fails_of` termina num
  `printf`.
- Hipótese: o mundo do índice corrompido não seria restaurado se o `preflight` falhasse. Refutada. O
  `dt_run` termina em `|| true` (`tests/check-preflight.sh:2282`), então o `mv` da linha seguinte
  sempre roda.

## Achados fora de escopo

Nenhum. O achado #1 fica como limite medido nesta rodada, pela régua D15, e não entra no `TODO.md`.

## Pendências / Decisions for a Human

Nenhuma.

Uma nota de método, sem decisão pendente. O delta tem 4 arquivos de código (bash), e a skill
manda agentes por arquivo acima de 3. Como o diff de código tem 70 linhas, fiz a Fase B na sessão
principal. Também não rodei o verificador de prosa sobre o `TODO.md`: as mudanças nele são só
âncoras remapeadas, e quem as mede é o `check-todo.sh --anchors` da suíte, que passou.
