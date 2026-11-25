# I2 — Aceite do piloto real do worker Codex

Em 2026-11-24, com Ubuntu 24.04, Codex CLI 0.172.0 e kit em `5e2a3a9` (implementação
`0abeee2`), a campanha descartável `20261124-sdd466-pilot` percorreu PLAN, EXEC, QA,
REVIEW e DOCS e parou no handoff de PR. O lote L1 tinha delegação de teste assinada no
nível `plan`, com `harness: codex`, `exec_model: gpt-6.2-sol` e
`allow_unknown_cost: true`. O preflight passou com autenticação ChatGPT e sandbox
operacional após o procedimento em [checkpoint-notas.md](checkpoint-notas.md).

## Artefatos e gates

| Fase | Modelo e esforço | Evidência |
|---|---|---|
| PLAN | Astra `high` | O relay foi interrompido com uma pergunta pendente. A retomada em outro processo preservou o ID nativo `01a21015-2d0f-78b2-b5db-e1574aef588c`. O teste falhou na base. Depois da materialização e de `sdd approve` (`e57dd40` no piloto), o gate confirmou `humano-2026-11-24`. |
| EXEC | Sol `medium` | `20-handoff-exec.md`, I1 concluído em `d5898ba`, suíte verde. |
| QA | Sol `xhigh` | `30-handoff-qa.md`, jornada CLI comprovada sem browser, suíte verde. |
| REVIEW | Sol `xhigh` | `40-review-r1.md`, nota geral A, suíte verde e árvore limpa. |
| DOCS | Sol `medium` | `45-docs.md`, checklist de drift completo, HEAD final do piloto `72eecb9`. |

O aceite independente reavaliou os cinco gates com `sdd why`, reproduziu
`bash test-greeting.sh` vermelho na base (rc 1) e verde no piloto (rc 0) e verificou
os bytes da saudação em UTF-8 com um único LF final. O runner saiu com rc 2 e
`PR needs worker publish`. O piloto permaneceu sem remoto, referências remotas,
`50-pr.md` ou sessão de publicação. O ato `pr` não foi executado nesse repo.
A rechecagem local do piloto original após as correções do adaptador executou
`git remote` e `git for-each-ref refs/remotes` e exigiu saída vazia nos dois.
Também exigiu que não existissem `50-pr.md` nem logs `PR-*` da missão.
A rechecagem registrou `git_remotes=0`, `git_remote_refs=0`, `pr_artifacts=0`,
`pr_session_logs=0` e `new_ledger_rows=0`. Não abriu uma nova sessão de modelo.

## Telemetria

| Fase | Entrada (em cache) | Saída | Custo efetivo | Equivalente Standard API (USD) |
|---|---:|---:|---|---:|
| EXEC | 231294 (173696) | 3432 | `null` | 0,1668856 |
| QA | 206836 (172288) | 4682 | `null` | 0,1331448 |
| REVIEW | 1113089 (1018752) | 11480 | `null` | `null` |
| DOCS | 508652 (462464) | 4231 | `null` | `null` |

A autenticação ChatGPT não informou cobrança efetiva. Em REVIEW e DOCS, o resumo
por turno não permitiu distinguir as faixas de preço de contexto. Não há estimativa
total da campanha. As quatro linhas foram conferidas no ledger isolado do piloto.

Evidência local do piloto descartável em `/tmp/sdd466-pilot.fGNHKo`, nos arquivos
`resume-proof`, `approve.log`, `preflight.log`, `run.log`, `run.rc` e
`state/autonomy-log.jsonl`.

## Extrato sanitizado do piloto

O extrato preserva os resultados da corrida de `5e2a3a9`, sem dados de autenticação.

```text
planner session same: 01a21015-2d0f-78b2-b5db-e1574aef588c
  ok   gate EXEC: 1 increment(s) done, suite green, handoff written
  ok   gate QA: journey walked without a browser interface (evidence in the handoff), suite green
  ok   gate REVIEW: 40-review-r1.md Grade A on every criterion, at least B on the prose ones, suite green, tree clean
  ok   gate DOCS: drift checklist complete
PR needs worker publish — use the campaign's separately authorized pr act, then resume sdd run for gate verification.
rc=2
```
