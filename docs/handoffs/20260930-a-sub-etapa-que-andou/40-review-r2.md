---
missao: 20260930-a-sub-etapa-que-andou
fase: REVIEW
rodada: 2
status: done
sessao: r2-2026-10-01
data: 2026-10-01 03:05
gate: "env -u GIT_REFLOG_ACTION tests/run-all.sh em 7627404: suite green, rc 0, 0 FAIL, 4m33s, anchors 515 de 515 aplicam. O env -u é o contorno do achado #2 da r1, já no TODO.md. Árvore limpa depois do commit desta rodada."
---

# Review: rodada r2, o sub-passo da QA que andou

## TL;DR

Esta rodada revisou o `R1` (`8a1b3a5`), o conserto do achado #1 da r1, e regraduou a missão inteira.
O conserto está certo. O `historic_steps` só recupera `step_after` da próxima linha QA com o mesmo
`run_id`, e nunca quando esse `run_id` é nulo. Os dois mutantes novos morrem pelo motivo certo numa
cópia, e o ledger real mantém as três linhas da métrica. Houve um achado LOW, só de prosa: duas
descrições ainda omitem "da mesma corrida". Ele foi para o `TODO.md`. Nenhum `R<n>` novo.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | O `historic_steps` guarda `{step, run_id}` e só recupera dentro da mesma corrida. O comentário do `ledger_outcome_defs` agora limita a declaração "lado conservador" ao laço dentro de uma corrida, que é onde ela vale. |
| Type Safety | A | `$r.run_id != null` vem antes da igualdade, então duas linhas sem `run_id` (null == null em jq) não contam como a mesma corrida. A asserção m85 e `mut_KAIZEN_historic_steps_null_run_is_a_run` seguram isso. |
| Error Handling | A | Linha não recuperada cai na rubrica sem `step_after` e lê `churned`, nunca `advanced` por omissão. A memória por chave é sobrescrita a cada linha QA, então uma linha de outra corrida no meio corta a recuperação. |
| Security | A | clean |
| Performance | A | O `reduce` continua linear, uma passada de trás para frente. A suíte inteira levou 4m33s, contra 4m38s na r1. |
| Test Coverage | A | Há duas asserções novas (m84 entre corridas, m85 sem `run_id`), uma por metade da guarda, e o par paritário foi recalibrado (`8 5 0`). Os dois mutantes foram reproduzidos nesta rodada numa cópia (`git archive HEAD`). O `crosses_runs` derruba 4 asserções, o `null_run_is_a_run` derruba 3, e as duas nomeadas estão entre elas. |
| Documentation | B | O `bin/sdd`, o `KAIZEN_LOG.md` e a D16 do `CONTEXT.md` dizem "da mesma corrida". O `docs/pipeline.md:1398` e o verbete Churn do `CONTEXT.md` ainda descrevem a regra antiga (achado #1, foi para o `TODO.md`). |
| **Overall** | **A** | A falha de atribuição da r1 está fechada, com sensor e mutantes medidos. A métrica da missão foi re-medida intacta no ledger real. O que sobra é prosa em duas frases, registrada no backlog. |

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | LOW | Duas descrições da recuperação histórica ainda dizem só "próxima linha QA da mesma `(repo, missão)`", sem a guarda de corrida que o `R1` introduziu. É drift de prosa, e o código e a D16 estão certos. | `docs/pipeline.md:1398`, `CONTEXT.md:20` (verbete Churn) |

O que foi verificado e não deu achado:

- **Check do `R1`**: `a QA row older than step_after is not recovered from the next row of another run` → `ok` na suíte.
- **Check do I4 re-rodado sobre o ledger real** → `4`. As três linhas da métrica (`19·2`, `14·1`, `17·3`) ficaram intactas. Só o rodapé mudou, de 28 para 22 linhas recuperadas, que é o que o commit afirma.
- **Mutantes do `R1` aplicados numa cópia, com `check-kaizen.sh` rodado sobre ela.** Os dois se aplicam (`cmp` acusa diferença). `crosses_runs` dá 4 FAIL, incluindo a asserção m84. `null_run_is_a_run` dá 3 FAIL, incluindo a m85. Os dois morrem pelo motivo nomeado no catálogo, e não só por vermelho incidental.
- **Pre-scan de segredos** sobre `8c79f2d..HEAD`: 0 achados.

## Incrementos de conserto (R<n>)

Nenhum nesta rodada. O único achado é só de prosa (`Documentation` = B). Pela regra da fase, ele vai
para o `TODO_FILE` e nunca vira `R<n>`.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| — | nenhum | — |

## O que virou incremento

- Achado #1 da r1 (`historic_steps` atravessa corridas): fechado em `8a1b3a5` pelo `sdd-executor`.
  A prova é a asserção m84 verde na suíte desta rodada e o mutante
  `mut_KAIZEN_historic_steps_crosses_runs` morto numa cópia nesta mesma sessão. A metade "não nulo"
  da guarda tem a própria asserção (m85) e o próprio mutante, que também morreu.

## O que foi refutado

- Nada a refutar. Considerei uma suspeita: uma linha de outra corrida entre duas da mesma corrida
  esconderia uma recuperação legítima. Ela não é defeito. A memória por `(repo, missão)` é
  sobrescrita por toda linha QA, então a linha intermediária corta a recuperação e a sessão fica
  `churned`, que é o lado conservador. Isso está coerente com a regra D15 aplicada no `R1`.

## Achados fora de escopo

- Achado #1 desta rodada (drift de prosa em `docs/pipeline.md` e no verbete Churn): registrado no
  `TODO.md`, seção "Comentário e registro" (2026-10-01). A catraca `todo-findings` subiu de 86 para
  87 em `tests/health-baseline.txt`, no mesmo commit. A fase DOCS desta missão é a candidata natural
  a fechá-lo.

## Pendências / Decisions for a Human

Nenhuma.
