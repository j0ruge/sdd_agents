---
missao: 20260814-dry-run-completo
titulo: dry-run mostra o pipeline inteiro, não só a primeira fase
data: 2026-08-14
versao:
branch: missao/20260814-dry-run-completo
aprovacao: humano-2026-08-14
ddd: n/a
---

# Missão — dry-run mostra o pipeline inteiro

> Missão-fixture do incremento I6 do plano do kit: o plano foi escrito à mão (o `sdd-planner`
> ainda não existe) para exercitar a fase EXEC headless de ponta a ponta pela primeira vez.

## Problema (Gemba)

`sdd run <missão> --dry-run` existe para responder *"o que vai acontecer se eu rodar isto?"*
antes de gastar token. Hoje ele responde pela metade: imprime **só a primeira fase** e para
(`bin/sdd`, no bloco `if [ "$DRY_RUN" = "1" ]` dentro de `cmd_run`, que dá `return 0` logo
após a primeira `run_phase`).

Verificado: numa missão com `checkpoint.md` de incremento pendente e nenhum outro artefato,
`sdd run <m> --dry-run` imprime a fase EXEC e encerra — o usuário não fica sabendo que depois
viriam QA, REVIEW, DOCS e PR, nem com que modelo e agente cada uma rodaria.

## Métrica

`tests/check-dry-run.sh` sai 0: o dry-run de uma missão recém-planejada nomeia **todas** as
fases que o pipeline percorreria (EXEC, QA, REVIEW, DOCS, PR), cada uma com o agente e o
modelo configurados. Hoje esse teste sai 1.

## Resultado esperado

`sdd run <missão> --dry-run` imprime a sequência completa de fases que executaria a partir do
estado atual, na ordem, cada uma com agente, modelo e prompt de boot. Nada é executado e nada
no disco muda. Fases já satisfeitas não aparecem; a fase PLAN, quando pendente, aparece como a
instrução interativa que o runner daria.

## Fora de escopo

- Simular o efeito das fases (o dry-run projeta a ordem a partir do estado de **hoje**; não
  tenta adivinhar que o EXEC vai satisfazer o gate e destravar a QA — ele lista as fases cujos
  gates estão insatisfeitos agora, que é a informação honesta).
- Qualquer mudança em gate, em template ou em agente.

## Gate PLAN-AUTO

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✅ | plano-fixture manual, sem grill |
| b | Checklist kaizen ✅ e DDD `n/a` justificado | ✅ | seções abaixo |
| c | Plano passa no teste de autocontenção | ✅ | `01-plano.md` traz arquivo, função e linha exatos |
| d | Todo incremento com Check executável | ✅ | 1 incremento, Check = `tests/check-dry-run.sh` → 0 |
| e | `versao:` confirmada ou `JIRA_ENABLED=false` | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba | ✅ | comportamento medido rodando o dry-run numa missão real |
| K2 | Problema com métrica | ✅ | `tests/check-dry-run.sh` sai 0 |
| K3 | Desperdícios cortados | ✅ | não simula estado futuro (adivinhação seria desperdício e mentira) |
| K4 | Fatiamento verificável | ✅ | 1 fatia, reversível por `git revert` |
| K5 | Check por artefato | ✅ | teste executável, não inspeção visual |
| K6 | Jidoka | ✅ | `tests/run-all.sh` vermelho para a linha |
| K7 | SDCA | ✅ | o teste novo entra na suíte e vira padrão |
| K8 | Registro | ✅ | KAIZEN_LOG na fase DOCS |

## Checklist DDD (`ddd`)

`n/a — sem toque de domínio: a mudança é na apresentação de um comando de CLI; não cria nem
altera entidade, agregado, evento ou contrato entre módulos.`

## Decisões do grill (não re-litigar)

1. O dry-run projeta a partir do estado de **hoje**, não do estado futuro simulado — informação
   honesta vale mais do que informação completa e potencialmente errada.
2. O teste vive em `tests/`, junto dos outros sensores do kit, e entra no `tests/run-all.sh`.

## Pendências para o humano

Nenhuma.
