---
missao: 20261121-l3-gates-do-fim-da-linha
fase: REVIEW
rodada: 1
status: done
sessao: af4798e0-5586-4efa-a124-82f483f8d159
data: 2026-11-21 12:38
gate: "tests/run-all.sh em 58c1274 → rc 0, 'suite green', 0 linhas '^  FAIL', 'anchors: all 942 mutants still apply'; árvore limpa (git status --short vazio) antes do commit da rodada"
reviewed_head: 58c1274e7393a83deb071c176bcb9b8959e2907d
---

# Review — rodada r1 — L3: gates do fim da linha

## TL;DR

Rodada inteira sobre `git diff main...HEAD` (merge-base `a0004df`, 24 arquivos): `bin/sdd`, cinco
sensores, dois chapéus, três templates, `docs/pipeline.md` e a ADR 0024. Varredura de segredos
limpa. Nove achados, todos MEDIUM ou LOW: dois MEDIUM e três LOW viram **um** `R1` de lote, dois
foram refutados com reprodução e os outros dois são de forma, que a régua D15 não admite. Nenhum
CRITICAL/HIGH. A suíte está verde em `58c1274`. Nota B em Error Handling e Test Coverage.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Cada leitura nova tem uma definição só (mission_tip, test_cmd_red_why, e2e_failed_keys, mission_kit_lines, review_later_code_ok), captura guardada e o comentário nomeia o dono do artefato. |
| Type Safety | A | Bash sem tipos: o sha do head passa por regex de 40–64 hex, o status do 50-pr.md é lido positivamente e as listas vazias usam a guarda ${x[@]+…}. |
| Error Handling | B | Dois MEDIUM: o rc 127 de uma suíte que começou é lido como "never started" (#1), e um HANDOFF_DIR terminado em barra torna o verified_head do gate_PR impossível de satisfazer (#2). |
| Security | A | Segredos limpos (regex + gitleaks, 0 achados em 2830 linhas); o PATCH da REST não leva credencial e a fronteira do chapéu não foi alargada. |
| Performance | A | O histórico do e2e lê no máximo 50 logs e cinco casos; o corpo do PR é pedido ao gh uma vez só, e só quando há ⛔ ou kit: a procurar. |
| Test Coverage | B | Os 16 mutantes se aplicam e são pegos, mas a regra da cerca do mission_kit_lines não tem mutante (#4), e o literal sdd preflight do check-templates casa em qualquer lugar do template (#5). |
| Documentation | A | ADR 0024, docs/pipeline.md, chapéus e templates batem com o código; o comentário do review_later_code_ok afirma uma cobertura falsa (#3) e entra no R1 como código. |
| **Overall** | **B** | Nenhum CRITICAL/HIGH; dois MEDIUM e três LOW baratos num R1 de lote; o laço segue para a EXEC. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | `test_cmd_red_why` lê qualquer rc 126/127 como "the suite never started", mas um `TEST_CMD` que começou e cujo comando interno faltou também sai 127 (`bash -c 'true; nao_existe'` → rc 127). O motivo afirma uma coisa falsa e, por ser estável de propósito, o `no_work_check` para a segunda volta como `no-work` com essa frase | `bin/sdd`, `test_cmd_red_why` |
| 2 | MEDIUM | `gate_PR` monta o prefixo `mdir_rel="$HANDOFF_DIR/$MISSION/"` sem tirar a barra final, coisa que o resto do runner faz (`${HANDOFF_DIR%/}`, `hat_expand`). Com `HANDOFF_DIR="docs/handoffs/"` o commit do próprio `50-pr.md` cai "fora da pasta da missão", e o publisher regrava o `verified_head:` e commita de novo, a cada volta: um gate insatisfazível. O prefixo vai ao `awk -v`, que interpreta `\` (o comentário diz "a literal") | `bin/sdd`, `gate_PR`, bloco do `verified_head` |
| 3 | LOW | `review_later_code_ok` devolve 0 quando o `git log --diff-filter=A` não acha o commit que adicionou a rodada, e o comentário diz que "a recusa da árvore suja cobre". Não cobre a rodada que entrou por um merge (o `git log` sem `-m` não mostra caminho para merge, e a árvore está limpa): o código posterior passa calado | `bin/sdd`, `review_later_code_ok` |
| 4 | LOW | A regra `fence { next }` do `mission_kit_lines` tem probe (o fixture tem uma linha `kit:` cercada) e não tem mutante; o título da asserção promete "none in a quote or a fence", e só a metade da citação tem mutante | `tests/check-mutation.sh`, `mut_PR_kit_lines_counted_in_quote` |
| 5 | LOW | A asserção do `pr-body.md` em `tests/check-templates.sh` procura `sdd preflight` em qualquer lugar do template; outra seção que cite o comando deixa a regra do "Como verificar" sem probe | `tests/check-templates.sh`, bloco do `pr-body.md` |
| 6 | LOW | `mut_PR_merged_head_read` troca as **duas** linhas `if [ "$pr_live_state" != MERGED ]` do `gate_PR`, a do head e a do corpo | `tests/check-mutation.sh`, `mut_PR_merged_head_read` |
| 7 | LOW | `kit_n="$(mission_kit_lines)"` sem guarda de captura | `bin/sdd`, `gate_PR` |
| 8 | LOW | Frases de chapéu numa linha física muito longa (`agents/sdd-reviewer.md`, `agents/sdd-publisher.md`), comentário de ~400 caracteres antes do `blocked` no `gate_REVIEW` | chapéus; `gate_REVIEW` |
| 9 | LOW | Testes: o `fail` do `blocked_way_out_probes` repete o texto do `pass`; `norun_why` restaura `TEST_CMD` por padrão largo; a metade QA do par do 127 é capturada ~970 linhas antes de ser julgada; o braço `writes:` vazio do `review_later_code_ok` não tem mundo | `tests/check-hat.sh`, `tests/check-gates.sh` |

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | achados #1–#5 da r1 (lote MEDIUM/LOW) | `g=$(bash tests/check-gates.sh 2>&1); echo "$(grep -c '^  ok    gate_EXEC does not say the suite never started for a TEST_CMD that printed output before it exited 127' <<< "$g") $(grep -c '^  ok    gate_PR admits a later commit in the mission folder when HANDOFF_DIR ends in a slash' <<< "$g") $(grep -c 'refusal below covers it' bin/sdd) $(grep -c -e '^mut_PR_kit_lines_counted_in_fence()' tests/check-mutation.sh) $(grep -c 'a linha do gate é' tests/check-templates.sh)"` → `1 1 0 1 1` |

## O que virou incremento

- #1: o motivo do rc 126/127 deixa de afirmar "never started" quando o log mostra que a suíte
  começou. Virou `R1`, primeira posição do Check: uma asserção nova no `check-gates.sh` com um
  `TEST_CMD` que imprime e depois sai 127. Se o executor mudar a frase em vez de mudar o ramo,
  tudo bem, desde que o motivo continue estável, sem citar o log.
- #2: o prefixo do `verified_head` tira a barra final do `HANDOFF_DIR` e é comparado como literal
  (`ENVIRON`, ou `case` do bash). Virou `R1`, segunda posição: mundo com `HANDOFF_DIR` terminado em
  `/`, em que o commit do `50-pr.md` depois do `verified_head:` passa.
- #3: o comentário falso sai, e ou o limite fica declarado (a rodada que entrou por merge não é
  lida) ou o caso ganha um recuo. Virou `R1`, terceira posição: a frase "the dirty-tree refusal
  below covers it" sai de `bin/sdd`.
- #4: mutante `mut_PR_kit_lines_counted_in_fence`, provado com `--only` contra o `check-gates.sh`.
  Virou `R1`, quarta posição.
- #5: o literal da asserção do `pr-body.md` ancora na frase do comentário do "Como verificar"
  (`a linha do gate é`). Virou `R1`, quinta posição.

## O que foi refutado

- #6, como ponto cego: o mutante troca dois sítios, mas o sítio do head **sozinho** é pego pela
  asserção certa. Reproduzi numa cópia (`git archive HEAD` em `mktemp -d`, só a linha seguida de
  `tip="$(mission_tip)"` trocada por `if true`): `bash tests/check-gates.sh` → rc 1, com uma única
  linha `FAIL`, `gate_PR passes a 50-pr.md with no verified_head, and does not read the head of a
  merged pull request`, e 536 `ok`. O mutante é largo, mas a asserção mede o que diz medir.
- #7: a captura sem guarda não mata o runner. Os gates só são chamados como `gate_"$phase" || …`
  (`bin/sdd`, as quatro chamadas de despacho em `cmd_run`, `cmd_retry` e `cmd_status`), e o bash
  ignora o `set -e` dentro de função chamada à esquerda de `||`. O mundo em que o `awk` falharia
  (handoff ilegível entre o `[ -f ]` e a abertura) não tem consumidor fora da suíte, e a D15 não o
  admite.
- #8 e #9: forma de prosa e de teste. Nenhum deles é sensor que afirma medir o que não mede, e
  nenhum tem consumidor fora da suíte do kit. O braço `writes:` vazio (#9) admite mais caminhos, e
  o comentário do gate o declara ("An empty answer is writes anywhere"). Não viram `R<n>` nem item.

## Achados fora de escopo

Nenhum registrado nesta rodada.

## Pendências / Decisions for a Human

Nenhuma.
