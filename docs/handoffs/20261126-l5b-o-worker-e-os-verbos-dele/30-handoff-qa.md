---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: QA
status: done
sessao: 01a21d5f-190c-7d61-9d20-d27d7cdb3a60
data: 2026-11-27 11:32
gate: No SHA 283b863, python3 tests/check-worker-ahead.py "$PWD" saiu 0 com um relay antes da espera, retomada sem 00-missao.md e três lotes até done. bash tests/check-worker.sh saiu 0 com 100 sondas declaradas, parada com diagnóstico original e merge retido sem local/ci no SHA ou com pendência de revisão. tests/run-all.sh saiu 0 com suite green em 21 etapas e 1.017 âncoras. As novas regressões CLI python3 e2e/check-worker-lookahead-race.py "$PWD" e python3 e2e/check-worker-review-probe.py "$PWD" saíram 1 pelos defeitos reproduzidos. F1 e F2 pendentes devolvem a missão a EXEC.
---

# Handoff — QA — O worker e os verbos dele

## TL;DR

Percorri 3 jornadas CLI no SHA `283b863`: planejamento e retomada, parada e merge.
Confirmei 2 achados, ambos com regressão vermelha e incrementos `F1` e `F2` em `pending`.
Nenhuma decisão humana. O próximo passo é EXEC, depois o reteste em QA.

## Estado do repo

- **Branch:** `fix/l5b-o-worker-e-os-verbos-dele`, sem upstream configurado. Ancestral comum com `origin/main` em `8a56249`.
- **Último commit avaliado:** `283b863` `docs(exec): encerra a execução da L5b`.
- **Working tree:** limpa no início. Só os artefatos de QA mudaram nesta sessão.
- **Suíte:** `tests/run-all.sh` em `283b863` → `suite green`, rc 0 nas 21 etapas da suíte padrão. A etapa Codex registrou 3 casos `skipped`. O catálogo validou 1.017 âncoras, sem executar a mutação completa.
- **E2E:** sem `E2E_CMD` ou `APP_URL`. As jornadas e regressões são CLI, com Git local e executáveis simulados.

## O que foi feito

- `6344f01` — `python3 tests/check-worker-ahead.py "$PWD"` em `283b863`, rc 0. No cenário positivo, o runner ainda detinha o checkout quando o relay abriu no worktree do sucessor, antes da espera. A retomada no grill sem `00-missao.md` recuperou a pergunta, sem repetir `start`. A fila simulada percorreu três lotes até `done`. Sem pedido inequívoco, dono vivo do checkout, delegação válida, orçamento ou sucessor, não houve lançamento. A aprovação ficou retida até o merge verificado, a base integrada e os Checks do plano revalidados.
- `d7ca654`, `ac581c8`, `2e8bd53` — `bash tests/check-worker.sh` em `283b863`, rc 0. A jornada de parada preservou o primeiro diagnóstico no journal e no pager, distinguiu os tetos de fase e missão e recusou preflight sem a evidência requerida. O `TEST_CMD` também mediu a recusa de aumento e a retomada apenas em nova invocação com o teto reduzido. A sonda de gasto contou uma vez a missão removida identificada pelo ledger (`1af340a`).
- `6ed4ddc`, `2d81fe7`, `4edda89`, `20ffaab`, `f3b4056` — no mesmo `bash tests/check-worker.sh`, a jornada de merge exigiu `local/ci` no SHA testado, recusou achado sem disposição e pedido vigente de alterações, vinculou escolhas e aceite ao head e retomou a revisão pós-merge sem PR duplicado. A aferição do delta pela sonda I11 tem a ressalva do BUG-02 abaixo.
- Conferi os 18 pares da matriz de `01-plano.md` por título e pelo resultado de `bash tests/check-todo.sh --resolved TODO.md`. Cada marcador aponta para um commit ancestral de `283b863`, verificado com `git merge-base --is-ancestor`. Para #419, o marcador aponta para `2d81fe7` e a evidência complementar de `local/ci` está em `6ed4ddc`. Esta conferência não mudou o estado das issues no GitHub.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `checkpoint.md` | `F1` e `F2` em `pending`, com a regressão e a nova caminhada em cada Check. |
| `checkpoint-notas.md` | Uma linha anexada por achado, com o vínculo ao respectivo fix. |
| `e2e/check-worker-lookahead-race.py` | Regressão da corrida entre duas retomadas no bloco público de `run`. |
| `e2e/check-worker-review-probe.py` | Regressão do falso verde da sonda de revisão, com nova rodada da suíte do worker. |

Não houve relatório Playwright ou registro novo em `docs/qa/`. O acervo histórico ficou intacto.

## Boot da próxima fase

EXEC começa em `F1` e `F2` de `checkpoint.md`. Integre as regressões à cobertura do `TEST_CMD` no próprio sensor do worker, sem duplicar a execução integral dele. Refaça os dois Checks até imprimirem `1` e rode `tests/run-all.sh`. Depois dos fixes, QA repete as jornadas e reescreve este handoff. REVIEW começa por `F1`, `F2`, ownership e pelo vínculo do status e das disposições ao SHA do PR.

Para retomar `20261117-zerar-as-issues`, use a instrução original do dono para planejar durante a execução, identificada nas [decisões 1 e 7 de `00-missao.md`](00-missao.md#decisões-do-grill-não-re-litigar) (`8c5c30513c5c44c2b284fe2ecab9e63d` e `c5f0ad29961443e387457881b8556e7f`). Aponte para a fonte escrita original com `ahead-request` no handoff de retomada. Se ela não puder ser recuperada, conserve a sugestão. Releia delegação e orçamento no primário a cada ato.

## Pendências / Decisions for a Human

- Nenhuma decisão humana para os dois achados. Ambos têm correção técnica e voltam a EXEC.

## Riscos e não-feitos

- **BUG-01 / F1, retomada concorrente.** Em `bin/sdd-worker-ahead:144`, uma retomada entra sem reserva e é detida no orçamento da fixture. A outra reserva, cria o worktree, inicia o relay e registra a espera. Quando a primeira sai do orçamento, o teste de worktree já existente a recusa como `unreserved successor`, antes de reconciliar a reserva válida. `python3 e2e/check-worker-lookahead-race.py "$PWD"` em `283b863` saiu 1 com a trilha `start, wait, wait` e nenhum `status` do relay. O esperado é `start, wait, status, wait`, sem parada falsa e com um único `start`. Conservar a recusa quando o checkout de fato não corresponde à reserva e refazer a jornada de três lotes.
- **BUG-02 / F2, falso verde da revisão.** Em `tests/check-worker.sh:2749`, a extração carrega o primeiro bloco Bash de `review`. Desde `6344f01`, esse bloco é o da retomada, não o que define `review_scope`. Os 13 cenários abortam com `kit: unbound variable`. A captura que só verifica stdout fica vazia e imprime `review preserves the eligible delta` mesmo assim. `python3 e2e/check-worker-review-probe.py "$PWD"` em `283b863` saiu 1 com esse diagnóstico. Em controle isolado, executei os 13 cenários com o bloco que de fato define `review_scope` e eles passaram. No fix, selecione o bloco pela função e faça a sonda reprovar se o carregamento ou a execução do caso falhar. Confirme com um controle negativo em que a função devolve o delta errado.
- Nenhuma campanha real foi iniciada, nenhum planner pago foi aberto e nenhuma permissão real de publicação de status, resolução de thread ou merge no GitHub foi testada. As regressões novas ainda não fazem parte do `TEST_CMD` deste SHA.

## Achados fora de escopo

- Nenhum achado novo fora do escopo. `TODO.md` não foi alterado.
