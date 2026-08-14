---
missao: <YYYYMMDD>-<slug>
titulo: <uma linha — o que o usuário ganha quando isto estiver pronto>
data: <YYYY-MM-DD>
versao: <ex.: 0.7.0 — obrigatório quando JIRA_ENABLED=true; confirmado pelo humano no planejamento>
branch: <nome da branch de trabalho>
aprovacao: <auto | humano-YYYY-MM-DD>
ddd: <aplicado | n/a>
---

# Missão — <título>

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

<O que está acontecendo hoje, verificado no repo/produto — não suposto. Cite arquivo:linha,
comportamento observado, print de erro. Se você não foi olhar, não escreva aqui.>

## Métrica

<Como saberemos que resolveu, em número ou em fato binário verificável. Ex.: "spinner aparece em
<200ms em 3 jornadas medidas" / "0 ocorrências de text-[10px] no componente".>

## Resultado esperado

<O estado do mundo depois da missão, em 3–5 linhas. Escreva para alguém que não participou do grill.>

## Fora de escopo

<O que deliberadamente NÃO será feito nesta missão, e para onde foi (TODO.md, missão futura).>

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | <✅/✗> | <onde ver> |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | <✅/✗> | <seção abaixo> |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | <✅/✗> | <como foi testado> |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | <✅/✗> | <contagem> |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | <✅/✗> | <valor / n/a> |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | <✅/✗> | |
| K2 | Problema declarado com métrica | <✅/✗> | |
| K3 | Desperdícios identificados e cortados | <✅/✗> | |
| K4 | Fatiamento incremental, cada fatia verificável | <✅/✗> | |
| K5 | Check por artefato (rótulo ≠ artefato) | <✅/✗> | |
| K6 | Jidoka — o que para a linha está definido | <✅/✗> | |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | <✅/✗> | |
| K8 | Registro no KAIZEN_LOG | <✅/✗> | |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

<`n/a — sem toque de domínio: <justificativa em 1 linha>` OU a tabela D1–D6 preenchida>

## Decisões do grill (não re-litigar)

1. <decisão + porquê em uma linha>

## Pendências para o humano

<Vazio, ou itens que exigem julgamento humano genuíno. Não bloqueiam o pipeline: viram seção do PR.>
