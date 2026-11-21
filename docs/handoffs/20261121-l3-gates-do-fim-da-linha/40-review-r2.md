---
missao: 20261121-l3-gates-do-fim-da-linha
fase: REVIEW
rodada: 2
status: done
sessao: 301c422a-58b5-4368-bccd-095695a7d506
data: 2026-11-21 14:20
gate: "tests/run-all.sh em 0d3f87c → rc 0, 'suite green', 0 linhas '^  FAIL', 'anchors: all 943 mutants still apply and leave valid code'; as três asserções do R1 em '^  ok    '; árvore limpa (git status --short vazio) antes do commit da rodada"
reviewed_head: 0d3f87c6d2f726caa432cc3d84bf8eb5d92ab7ac
---

# Review — rodada r2 — L3: gates do fim da linha

## TL;DR

Rodada delta sobre `58c1274..0d3f87c` (quatro commits: a r1, o R1 em `d4c4e97`, o handoff e o
checkpoint). O código mudou em `bin/sdd` (`test_cmd_red_why`, comentário do `review_later_code_ok`),
`tests/check-gates.sh`, `tests/check-mutation.sh` e `tests/check-templates.sh`; o resto é deslocamento
de âncora do `TODO.md`. Os cinco achados da r1 estão fechados ou refutados com evidência. Dois LOW
novos, nenhum abre rodada. Segredos limpos. Suíte verde. Nota A em todo critério.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O ramo novo do rc 126/127 mora na mesma definição (test_cmd_red_why), com a captura guardada e uma frase estável que não cita log. |
| Type Safety | A | A contagem de linhas passa por ${printed:-0} antes do -gt, então um log ilegível vira 0 e não erro de aritmética. |
| Error Handling | A | O #1 da r1 está fechado (a suíte que começou e saiu 127 tem frase própria) e o #2 foi refutado no código: o load_config tira a barra final do HANDOFF_DIR. |
| Security | A | Segredos limpos (regex + gitleaks, 0 achados em 226 linhas adicionadas); nenhuma fronteira de chapéu mudou. |
| Performance | A | Um grep -c a mais sobre o log, só no ramo 126/127. |
| Test Coverage | A | As três asserções novas passam na suíte inteira, o mutante da cerca entrou no catálogo e se aplica (943 âncoras), e o literal do pr-body.md ancora na frase do Como verificar. |
| Documentation | A | O comentário falso do review_later_code_ok saiu e o limite da rodada que entra por merge ficou declarado. |
| **Overall** | **A** | Os cinco achados da r1 fechados com commit do executor por trás; dois LOW sem consumidor que pague uma rodada. |

Movimento: a r1 tinha Error Handling e Test Coverage em B; a r2 tem os sete em A, e o commit
`d4c4e97` do `sdd-executor` está entre as duas rodadas (`git log 58c1274..HEAD`).

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | Um `TEST_CMD` com dois comandos ausentes (`a; b`) imprime duas mensagens do shell e sai 127: o log tem duas linhas não vazias e o motivo diz "after it printed output — the suite started", que é falso nesse caso. Reproduzido: `( eval 'sdd_x1; sdd_x2' )` → rc 127, duas linhas. A frase ainda nomeia o comando e o remédio (o que falta na árvore) é o mesmo | `bin/sdd`, `test_cmd_red_why`, o `-gt 1` |
| 2 | LOW | O ramo novo do `test_cmd_red_why` tem asserção e sabotagem manual registrada nas notas do R1, mas nenhum mutante no catálogo; o `mut_RUN_test_cmd_not_run_reads_red` cobre só o ramo antigo | `tests/check-mutation.sh` |

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. Os dois achados são LOW, e nenhum é sensor que afirme medir o que não mede:
o #1 dá o mesmo remédio com uma frase imprecisa num caso de borda, e o #2 é asserção viva (a
sabotagem manual do R1 a deixou vermelha) sem a prova durável do catálogo.

## O que virou incremento

- #1 da r1 (rc 127 de suíte que começou) — fechado em `d4c4e97` — `^  ok    gate_EXEC does not say the suite never started for a TEST_CMD that printed output before it exited 127` na suíte desta rodada.
- #2 da r1 (HANDOFF_DIR com barra final) — refutado pelo executor em `d4c4e97`, e conferido aqui: `bin/sdd` normaliza o `HANDOFF_DIR` no `load_config` (`while [ "${hd%/}" != "$hd" ]`), e o probe `gate_PR admits a later commit in the mission folder when HANDOFF_DIR ends in a slash` fica como regressão, verde, com a testemunha de que o `sed` armou a barra (`prv_slash_cfg`).
- #3 da r1 (comentário falso) — fechado em `d4c4e97` — `grep -c 'refusal below covers it' bin/sdd` → `0`, e o comentário declara o limite da rodada que entra por merge.
- #4 da r1 (mutante da cerca) — fechado em `d4c4e97` — `mut_PR_kit_lines_counted_in_fence` no `CATALOG`, e a linha `    fence { next }` que ele apaga existe no `mission_kit_lines` (a âncora se aplica: 943 de 943).
- #5 da r1 (literal do pr-body.md) — fechado em `d4c4e97` — a asserção lê `a linha do gate é \`sdd preflight\``, que aparece uma vez em `templates/pr-body.md`.

## O que foi refutado

- Nada novo a refutar. Os dois achados de cima não viram `R<n>` pela severidade (LOW) e pela
  régua D15: nenhum é fail-open e nenhum tem consumidor fora da suíte que pague uma sessão EXEC e
  mais uma rodada.

## Achados fora de escopo

Nenhum registrado nesta rodada.

## Pendências / Decisions for a Human

Nenhuma.
