---
missao: 20260930-a-sub-etapa-que-andou
fase: REVIEW
rodada: 1
status: done
sessao: c994f4f8
data: 2026-10-01 02:20
gate: "tests/run-all.sh no checkout em 2d07186: 1650 ok, 1 FAIL (rc 1, 4m38s). O FAIL é ambiental e pré-existente, `a round trip through another branch inside the window is not a crossing` em check-autonomy.sh, vermelho também na main (git archive). Some com env -u GIT_REFLOG_ACTION (check-autonomy rc 0). O gate do runner roda sem o rótulo. Árvore limpa depois do commit desta rodada."
---

# Review: rodada r1, o sub-passo da QA que andou

## TL;DR

Revisados o escritor (`step_after` e a foto de `pending` na linha QA, nas três portas), os dois braços
novos da rubrica, `historic_steps`, os 18 mutantes novos e a documentação. A métrica foi reproduzida
sobre o ledger real, e o diferencial com a `main` mudou só as três linhas previstas mais a frase de
contagem. Houve **1 achado MEDIUM**, que virou `R1`: a recuperação histórica atravessa corridas e
credita à sessão o que aconteceu entre elas. Um achado pré-existente, fora do escopo, foi para o
`TODO.md`. Nota B.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O `historic_steps` lê a próxima linha QA de qualquer corrida, e o comentário do `ledger_outcome_defs` declara que o erro "só cai do lado conservador", o que é falso no caso entre corridas (achado #1, R1). |
| Type Safety | A | Os ranks nulos são guardados dos dois lados (`2 > null` verdadeiro em jq), `has("step_after")` distingue a chave ausente da foto nula, e a contagem de `pending` sai do `checkpoint_tally`, nunca do global do EXEC. |
| Error Handling | A | As três portas guardam por fase, `.moved != false` está nos dois braços novos, e o `$(phase_step QA)` é seguro porque `qa_substep` não seta global. |
| Security | A | clean |
| Performance | A | `sdd autonomy --all-repos --by-mission`: 0,18 s → 0,20 s no ledger real (585 linhas) e 5,56 s → 5,10 s num ledger 30× maior. O `historic_steps` é linear. |
| Test Coverage | B | 18 mutantes, com um probe por porta e por guarda e a paridade juiz × janela humana. Falta o mundo do achado #1: nenhuma asserção põe a próxima linha QA em outro `run_id`. |
| Documentation | A | O `docs/pipeline.md` (campo e rubrica), a 4ª emenda da D16, o Churn, o `sdd-kaizen.md` e o KAIZEN_LOG descrevem o que o código faz, com o antes/depois medido. |
| **Overall** | **B** | O escritor e os braços estão certos e bem sondados. O caminho datado tem um defeito de atribuição sem efeito no ledger de hoje e um limite declarado ao contrário. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | O `historic_steps` recupera o `step_after` de uma linha antiga a partir do `step` da próxima linha QA da mesma `(repo, missão)`, **de qualquer corrida**. Quando a próxima linha é de outro `run_id`, o `step` dela inclui o que aconteceu entre as corridas: um humano que fechou o relatório, ou uma sessão interativa. Esse avanço é creditado à sessão antiga. O escritor novo, que deriva o sub-passo logo depois da sessão, diria `churned` no mesmo mundo, e o caminho datado diz `advanced`. O comentário declara o oposto ("the error can only land on the conservative side"). | `bin/sdd:3335` (`def historic_steps`), comentário em `bin/sdd:3327` |
| 2 | LOW (fora do escopo, pré-existente) | `tests/check-autonomy.sh:6409` herda o `GIT_REFLOG_ACTION` de quem roda a suíte. Dentro de uma sessão REVIEW, os `git checkout` do fixture ganham o rótulo `sdd:REVIEW:<sid8>` e `trips:2` passa a ler `trips:4`. | `tests/check-autonomy.sh:6409` (`foreign_elsewhere`) |

**Reprodução do #1.** Ledger de duas linhas em `/tmp/rvfx`:

- linha 1: `QA:exec`, `run_id r1`, `moved: true`, `gate: fail`, `missing 30-handoff-qa.md`;
- linha 2: no dia seguinte, `QA:close`, `run_id r2`, `pass`.

Resultado de `SDD_STATE_DIR=/tmp/rvfx sdd autonomy --all-repos --by-mission`:

| Árvore | `p1/m1` |
|---|---|
| HEAD | `2 advanced · 0 churned` e `(1 QA row(s) older than step_after read their sub-step from the next row)` |
| `main` | `1 advanced · 1 churned` |

**Alcance no ledger real.** Das 28 linhas recuperadas, 22 têm a próxima linha na mesma corrida e 6 em
outra corrida. Nenhuma das 6 muda de balde hoje: as três que mudaram, as da métrica, são todas da
mesma corrida (`1448f31d…`, `3bcd93e5…`, `95bba51c…`). Por isso o conserto não mexe na métrica. A
contagem na tela deve cair de 28 para cerca de 22.

**Reprodução do #2.**

| Comando | Resultado |
|---|---|
| `echo $GIT_REFLOG_ACTION` | `sdd:REVIEW:c994f4f8` |
| `bash tests/check-autonomy.sh` (branch e `main`) | FAIL com `trips:4` |
| `env -u GIT_REFLOG_ACTION bash tests/check-autonomy.sh` | rc 0 |

O gate não é afetado: o runner passa o rótulo só para o `claude -p` (`bin/sdd:4335`), e o
`run_check_cmd` do `gate_REVIEW` roda sem ele. A QA viu a suíte verde porque o rótulo dela é
`sdd:QA:…`, que a asserção não conta.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R1 | achado #1 | `o=$(bash tests/check-kaizen.sh 2>&1); grep -c '^  ok    a QA row older than step_after is not recovered from the next row of another run' <<< "$o"` → `1` (hoje responde `0`) |

## O que virou incremento

- Achado #1 virou `R1`. Para fechar, o Check exige duas coisas:
  - uma asserção nova em `tests/check-kaizen.sh`: uma linha QA antiga cuja próxima linha QA é de outro
    `run_id` não é recuperada e continua `churned`;
  - as três linhas da métrica intactas no ledger real. Quem cobra isso é o Check do `I4`, que o
    executor re-roda (o `check-checkpoint.sh` recusa as duas leituras na mesma célula).

  Direção sugerida, que o executor decide em TDD: a memória do `historic_steps` guarda `{step, run_id}`
  e só recupera quando o `run_id` é igual e não nulo (hoje 0 linhas QA têm `run_id` nulo). Junto vão
  um mutante que tira a guarda e a correção do limite declarado no comentário em `bin/sdd:3327`. Pela
  régua D15, a corrida diferente deixa de ser recuperada, em vez de ser declarada.

## O que foi refutado

A ressalva 3 do handoff de QA era o rodapé `1 QA row(s)` aparecendo sem mudar número na forma padrão.
Não é defeito: a frase conta as linhas lidas pelo caminho datado, não as que mudaram de balde. É o
mesmo contrato das frases irmãs do EXEC e do REVIEW (`bin/sdd`, comentário "DELETION SIGNALS").

A ressalva 2 do handoff de QA era o escritor nunca visto em produção. Não há defeito a apontar:

- `LAST_PHASE_STEP` é fixado no `run_phase` **antes** da sessão (`bin/sdd:4487`), e `step_after` é
  derivado depois do gate, então os dois não colapsam no mesmo valor;
- as três portas têm um probe e um mutante cada.

A primeira linha real sai na próxima corrida subida depois do merge.

## Achados fora de escopo

- Achado #2 (fixture herda `GIT_REFLOG_ACTION`) foi registrado no `TODO.md`, seção aberta, em
  2026-10-01, e a catraca foi de 85 para 86 em `tests/health-baseline.txt` no mesmo commit.
  ⚠️ O Check do `I6` (`check-todo.sh --count` → `85`) passa a responder `86`. Era a foto do commit
  `7ee1c3e` e continua verdadeira lá; nenhum gate re-executa a célula.

## Pendências / Decisions for a Human

Nenhuma.
