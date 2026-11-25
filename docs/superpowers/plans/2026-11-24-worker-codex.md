# Worker de campanhas no Codex — issue #466

Base da missão: `4bb31d7`. A decisão de implementação foi dada na sessão de planejamento da issue.
A rota apresenta `harness: codex` para o worker. O agente de PLAN é Astra, EXEC usa Sol em
`medium`, e QA e REVIEW usam Sol em `xhigh`. A rota Claude continua disponível.

## Incrementos

1. Dar ao worker uma entrada no Codex, com o planner em um worktree próprio e retomada do grill
   pelo ID nativo. Levar as três minutas para o gate de PLAN com a aprovação em branco.
2. Selecionar o harness no runner sem trocar os gates, o lock ou o contrato dos handoffs. Medir
   os eventos do Codex, testar o sandbox no preflight e permitir retry nativo dentro da execução.
3. Guardar custo desconhecido como `null`. Calcular o equivalente em USD quando a telemetria
   permitir aplicar uma tarifa Standard da API. Exigir consentimento assinado para prosseguir
   quando o custo efetivo da assinatura for desconhecido.
4. Manter a publicação no ato `pr` sob a delegação do worker. O runner retorna o handoff
   `PR needs worker publish` antes de abrir uma sessão de publicação em Codex. O ato `merge`
   continua separado e exige a delegação correspondente e `pr-ready`.

## Aceite da campanha

Em ambiente com sandbox Codex operacional, usar um repositório descartável, sem remoto de
publicação. Criar uma campanha Codex e uma delegação de teste assinada, preparar o worktree,
iniciar o planner, interromper o relay com uma pergunta pendente e retomá-lo. Confirmar pela
autorização e pelos artefatos de PLAN antes de prosseguir. Rodar EXEC, QA, REVIEW e DOCS e
parar no handoff de PR. Conferir o modelo, esforço, evidências dos gates e registro de orçamento.
O teste de publicação usa repositório e comandos isolados. A regressão Claude roda em
`tests/run-all.sh`.

No teste de telemetria com o Sol, a sessão informou 22.474 tokens de entrada, dos quais 12.672
vieram do cache, e 5 de saída. O equivalente Standard da API é US$ 0,0209212. O harness da
assinatura não informou um valor cobrado. O teste real de retomada confirmou o mesmo ID de
thread. O preflight inicialmente falhou com
`bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`. Após aplicar o perfil
AppArmor oficial para o Bubblewrap, o piloto passou por todos os gates planejados e chegou
ao handoff de PR sem publicação. As evidências estão no [registro do piloto](../../handoffs/20261124-worker-codex/record-I2.md).
