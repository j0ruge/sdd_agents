---
missao: 20261124-worker-codex
data: 2026-11-24
---

# Plano — Worker de campanhas com Codex

## Contexto verificado (não re-descobrir)

A base é `4bb31d7`. O teste do adaptador confirma a estimativa e a distinção entre estimativa
e cobrança real. `bin/sdd-codex --preflight` verifica se o host pode executar comandos isolados.

## Arquitetura da mudança

O runner seleciona o Codex por campanha e usa os checks existentes. Os turnos gravam
telemetria com custo efetivo separado da estimativa. A decisão está no [ADR 0026](../../adr/0026-the-worker-runs-codex-campaigns.md).

## Incrementos

- **I1** — Verificar em cenário isolado o planner, o runner, o modelo por fase, a delegação e o
  orçamento. Rodar a regressão do Claude e registrar a revisão testada.
- **I2** — Rodar a campanha real descartável em host compatível. Guardar as evidências do mesmo
  ID de retomada, dos gates e do handoff de publicação. O repositório do piloto não terá remoto
  de publicação.

## Riscos e não-feitos

Se o sandbox recusar a execução de comandos, interromper no preflight e manter o aceite real
pendente. Os fixtures não substituem o piloto.

## Verificação end-to-end

Preparar uma campanha com delegação assinada e worktree isolado, retomar uma pergunta do planner
e rodar EXEC, QA, REVIEW e DOCS até o handoff de PR. Registrar a execução em `record-I2.md` com o host,
a revisão, o ID da retomada, os resultados dos gates e a ausência de publicação.
