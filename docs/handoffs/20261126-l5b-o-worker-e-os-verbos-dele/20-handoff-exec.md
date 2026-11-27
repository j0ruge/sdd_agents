---
missao: 20261126-l5b-o-worker-e-os-verbos-dele
fase: EXEC
status: done
sessao: 01a21d27-f46d-7280-8380-cb01bb6ea06e
data: 2026-11-27 10:58
gate: tests/run-all.sh em 6344f01 → suite green, 21 etapas, 100 sondas do worker, 100 âncoras do TODO e 1017 do catálogo. bash tests/check-worker.sh em 6344f01 → Check I14 = 1.
---

# Handoff — EXEC — O worker e os verbos dele

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.


## TL;DR

Os 14 incrementos estão concluídos. O worker inicia o plano Codex do sucessor depois de comprovar a posse do checkout do predecessor.
A suíte está verde e a fixture percorreu três lotes até `done`. Começar QA pela jornada de retomada antes de `00-missao.md`.

## Estado do repo

- **Branch:** `fix/l5b-o-worker-e-os-verbos-dele` — sem upstream configurado.
- **Último commit de implementação:** `6344f01` — fix(worker): inicia o plano antecipado após confirmar o run.
- **Working tree:** somente o checkpoint, a nota e este handoff entraram no commit de fechamento.
- **Suíte:** `tests/run-all.sh` → `suite green`, 21 etapas e 100 sondas do worker.
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

## Artefatos

| Arquivo | O que contém |
|---|---|
| `checkpoint.md` | Checks e commits de implementação dos 14 incrementos. |
| `commands/sdd-worker.md` | Procedimentos de despacho, retomada, aprovação e espera. |
| `bin/sdd-worker-ahead` | Confirmação do dono do checkout, reserva do sucessor e chamada ao relay. |
| `tests/check-worker-ahead.py` | Jornada de três lotes, concorrência, recusas e revalidação. |

## Boot da próxima fase

Leia `00-missao.md`, `01-plano.md` e `checkpoint.md`. Rode `tests/run-all.sh` neste checkout. Use `bash tests/check-worker.sh` para isolar as jornadas de planning, parada e merge, e `python3 tests/check-worker-ahead.py "$PWD"` para reproduzir só I14. Não é necessário subir uma aplicação, chamar o GitHub ou iniciar um planner pago para reproduzir essas sondas.

Reveja concorrência e retomada antes de `00-missao.md`, a ordem runner → relay → espera, as recusas de orçamento e delegação, e o bloqueio de aprovação até integração da base e revalidação do plano. No merge, confira evidência no SHA e tratamento dos achados. Para a campanha `20261117-zerar-as-issues`, aponte no handoff de retomada para a instrução original do dono, identificada nas decisões 1 e 7 de `00-missao.md`. A delegação e o orçamento devem ser relidos no primário quando cada ato for autorizado.

## Pendências / Decisions for a Human

- Nenhuma decisão nova de produto em aberto. A emissão de termos assinados continua com o dono.

## Riscos e não-feitos

- O fluxo real com Codex e GitHub não foi iniciado nesta fase. A fixture não prova permissões de publicação, status ou threads.
- O despacho automático usa o relay Codex. Sem pedido verificável, ou em outro harness, a rota manual permanece disponível.
- Não foi alterada a política por lote do `curso-ddd`. Não houve publicação, aprovação externa nem merge real.

## Achados fora de escopo

- Nenhum achado novo registrado no I14.
