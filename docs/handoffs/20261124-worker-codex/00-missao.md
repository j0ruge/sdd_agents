---
missao: 20261124-worker-codex
titulo: Worker de campanhas com Codex
data: 2026-11-24
versao:
branch: plan/466-worker-codex
aprovacao: humano-2026-11-24
adr: docs/adr/0026-the-worker-runs-codex-campaigns.md
ddd: n/a
---

# Missão — Worker de campanhas com Codex

## Problema (Gemba)

A [issue #466](https://github.com/j0ruge/sdd_agents/issues/466) parte do worker que orquestrava
campanhas no Claude Code. A primeira checagem da assinatura Codex retornou tokens em cache, de
entrada e de saída, sem custo cobrado em USD. O teste independente do sandbox reproduziu uma
recusa do host ao configurar a interface de loopback.

## Métrica

Uma campanha descartável no Codex real passa por PLAN, EXEC, QA, REVIEW e DOCS, retoma o mesmo
planner e para antes de publicar. A suíte de regressão do Claude continua verde.

## Resultado esperado

O campo `harness: codex` seleciona a rota nova. Os gates e a delegação continuam amarrados à
missão. O custo cobrado permanece desconhecido se o harness não o informar, mesmo quando houver
estimativa de tarifa da API.

## Fora de escopo

Publicar o piloto ou alterar a política do sandbox para contornar o preflight.

## Decisões do grill (não re-litigar)

1. Astra no PLAN, Sol `medium` na EXEC, Sol `xhigh` na QA e REVIEW. Manter a rota Claude.
2. Calcular a estimativa quando houver base, guardar custo efetivo desconhecido como `null` e só
   iniciar turnos delegados sujeitos ao teto sem esse dado sob consentimento assinado.
3. Manter publicação e merge como atos distintos do worker. O piloto termina antes do PR.
4. Aprovação explícita do dono na conversa. A confirmação foi executada por delegação com
   `sdd approve`. Essa aprovação é do plano. O aceite do piloto depende do sandbox.

## Pendências para o humano

Nenhuma decisão de plano pendente. A campanha de aceite precisa de um host que passe no preflight
do sandbox.
