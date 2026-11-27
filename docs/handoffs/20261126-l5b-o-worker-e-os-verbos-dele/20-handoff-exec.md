---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: EXEC
status: done
sessao: 01a21da1-b535-7f20-adb4-122585336b56
data: 2026-11-27 13:13
gate: tests/run-all.sh em 9837b00 → suite green, 21 etapas, 101 sondas do worker, 100 âncoras do TODO e 1.017 do catálogo. Checks F1 e F2 do checkpoint → 1 cada.
---

# Handoff — EXEC — O worker e os verbos dele

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.


## TL;DR

Os 16 incrementos estão concluídos. F1 corrige a retomada concorrente e F2 restaura a medição dos 13 cenários de revisão.
Os dois Checks imprimiram `1` e `tests/run-all.sh` passou. QA deve repassar as jornadas e reescrever `30-handoff-qa.md`.

## Estado do repo

- **Branch:** `fix/l5b-o-worker-e-os-verbos-dele` — sem upstream configurado.
- **Último commit de implementação:** `9837b00` — fix(tests): faz a sonda de revisão reprovar casos abortados.
- **Working tree:** o commit de fechamento registra apenas o checkpoint, a nota e este handoff.
- **Suíte:** `tests/run-all.sh` → `suite green`, 21 etapas e 101 sondas do worker.
- **E2E:** não há `E2E_CMD` configurado. A fixture do worker usa Git local e simula runner, relay, fila e aprovação.

## O que foi feito

- `064098e` — I1 — Preservou a lista de worktrees com separadores NUL.
- `d1e8d0f` — I2 — Exportou o teto ao ler o config e conferiu a validade ao conceder autoridade.
- `1af340a` — I3 — Incluiu o gasto de missão removida sem dupla contagem.
- `ac581c8` — I4 — Revalidou o teto delegado antes de novas sessões.
- `d7ca654` — I5 — Conservou a causa original da parada e distinguiu teto de fase de teto de missão.
- `9ce1943` — I6 — Impediu que páginas de forks ocultassem o PR próprio.
- `f7b8071` — I7 — Separou a prova do ancestral da prova das notas de revisão.
- `6ed4ddc` — I8 — Vinculou `local/ci` ao SHA testado.
- `2d81fe7` — I9 — Exigiu o tratamento verificável do corpo da revisão e dos threads.
- `4edda89` — I10 — Vinculou as escolhas publicadas e o aceite do merge ao head.
- `20ffaab` — I11 — Preservou o delta elegível e releu a revisão depois de integrar conflito.
- `f3b4056` — I12 — Documentou a fila assinada e retomou o PR de acompanhamento.
- `2e8bd53` — I13 — Fez do pré-voo no worktree e no engine da missão uma condição para iniciar o runner.
- `6344f01` — I14 — Disparou um único relay Codex autorizado antes da espera, com retomada e aprovação revalidada.

## Correções do ciclo de QA

- `5ac9b42` — F1 (BUG-01) — Reutilizou a reserva concorrente validada durante a leitura do orçamento. A jornada simulada registrou um único `start` e a retomada via `status`.
- `9837b00` — F2 (BUG-02) — Passou a extrair o bloco que define `review_scope` e a exigir que cada cenário termine depois de conferir o código de saída, a resposta e a ordem das chamadas. Os controles rejeitaram um carregamento interrompido e uma rodada `full` no lugar do delta elegível.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `checkpoint.md` | Checks e commits de implementação dos 16 incrementos. |
| `commands/sdd-worker.md` | Procedimentos de despacho, retomada, aprovação e espera. |
| `bin/sdd-worker-ahead` | Confirmação do dono do checkout, reserva do sucessor e chamada ao relay. |
| `tests/check-worker-ahead.py` | Jornada de três lotes, concorrência, recusas e revalidação. |
| `tests/check-worker.sh` | Executa o bloco público de seleção da revisão e mede os 13 cenários com controles negativos. |
| `e2e/check-worker-lookahead-race.py` e `e2e/check-worker-review-probe.py` | Reproduções dos dois achados de QA. |

## Boot da próxima fase

Leia `00-missao.md`, `01-plano.md`, `checkpoint.md` e os registros BUG-01 e BUG-02 de `30-handoff-qa.md`. Refaça os Checks F1 e F2 do checkpoint e rode `tests/run-all.sh` neste checkout. Repita as jornadas CLI de planejamento e retomada, parada e merge, e reescreva `30-handoff-qa.md` com o reteste. Em F2, confira o delta sem integração em PR mergeável, a integração apenas no conflito e a nova leitura no head integrado. Use `bash tests/check-worker.sh` para isolar as jornadas de planning, parada e merge, e `python3 tests/check-worker-ahead.py "$PWD"` para reproduzir só I14. Não é necessário subir uma aplicação, chamar o GitHub ou iniciar um planner pago para reproduzir essas sondas.

Reveja concorrência e retomada antes de `00-missao.md`, a ordem runner → relay → espera, as recusas de orçamento e delegação, e o bloqueio de aprovação até integração da base e revalidação do plano. No merge, confira evidência no SHA e tratamento dos achados. Para a campanha `20261117-zerar-as-issues`, aponte com `ahead-request` no handoff de retomada para a instrução original do dono, identificada nas decisões 1 e 7 de `00-missao.md`. A delegação e o orçamento devem ser relidos no primário quando cada ato for autorizado.

## Pendências / Decisions for a Human

- Nenhuma decisão nova de produto em aberto. A emissão de termos assinados continua com o dono.

## Riscos e não-feitos

- O fluxo real com Codex e GitHub não foi iniciado nesta fase. A fixture não prova permissões de publicação, status ou threads.
- O despacho automático usa o relay Codex. Sem pedido verificável, ou em outro harness, a rota manual permanece disponível.
- Não foi alterada a política por lote do `curso-ddd`. Não houve publicação, aprovação externa nem merge real.

## Achados fora de escopo

- Nenhum achado novo no ciclo de correções de QA.
