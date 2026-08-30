---
missao: 20260829-o-incremento-que-andou
titulo: o ledger diz se o incremento andou, e o juiz para de carimbar leve no laço desenhado
data: 2026-08-29
versao: n/a — JIRA_ENABLED=false
branch: feat/o-incremento-que-andou
aprovacao: auto
ddd: n/a
---

# Missão — o incremento que andou

> Escrito pelo `sdd-planner` com o humano presente. É a única fonte da **intenção**; o `01-plano.md`
> é a fonte do **como**. Toda sessão headless começa lendo estes dois.

## Problema (Gemba)

Medido em 2026-08-29 sobre o ledger real (`~/.sdd/autonomy-log.jsonl`, 151 linhas, 13 missões com
EXEC), **um dia depois de `20260828-instrumento-honesto` mergear** a tri-estado
`advanced · churned · idle`:

- Uma sessão de EXEC executa **um** incremento e o `gate_EXEC` reprova com
  `"N of M increment(s) still to execute"` até o último (`bin/sdd:738`). A definição de `outcome`
  (`bin/sdd:1777`: `gate == pass ⇒ advanced; moved ⇒ churned; senão idle`) lê cada uma dessas
  sessões como **`churned`** — o laço desenhado do pipeline, contado como desperdício.
- Sobre as 72 linhas EXEC do ledger, o instrumento diz `19 advanced · 46 churned · 7 idle`.
  Separando "o `N` caiu em relação à sessão EXEC anterior da missão" (laço desenhado) de "o `N`
  ficou onde estava" (churn de verdade), o churn real é **~5 sessões em 13 missões** — `frete-cif-fob`
  1 (US$ 3,64), `fecho-que-nao-mente` 1 (US$ 9,81), `o-laco-da-qa` 1 (US$ 3,26), `portas-do-humano` 1,
  `lote-facil` 1; `runner-sem-dividas` (10 "churned") tem **zero**.
- A tabela por versão (`sdd autonomy --all-repos`) imprime **49 de 107 versões com `100% waste`** —
  cada uma é um commit do kit cuja única sessão foi um incremento do meio de uma missão (o eixo
  degenerado da ADR 0003, lido pela régua errada).
- A rubrica do juiz (`bin/sdd:4703-4711`, cláusula de `adfc884`: qualquer `gate: fail` na fase ⇒ ao
  menos `leve`) carimba `leve` em **toda** fase EXEC com 2+ incrementos, e `advance_rate`
  (`bin/sdd:4767`, "gates que passaram ÷ sessões") lê `0.10` sobre uma fase que andou dez vezes sem
  tropeçar.
- O instrumento parou de lisonjear (`0 stalled`) e passou a acusar (`10 churned`) — nas duas
  direções, errado; e o juiz lê a régua errada na missão que viria consertar qualquer outra coisa.

A raiz é uma só: **o `outcome` não tem como saber se o incremento andou**, porque a linha do ledger
carrega o veredito do gate (`gate`) e o disco (`moved`), mas o fato que o gate já calcula — quantos
incrementos faltam — só sai como **prosa** em `gate_why`.

## Métrica

1. **Binário, na sessão real:** uma linha EXEC escrita por `sdd run` carrega `pending_before`,
   `pending_after` e `increments_total` como números (asserção e2e em `tests/check-autonomy.sh`
   sobre um checkpoint de dois incrementos com o `claude` stub que fecha um deles).
2. **Número, no ledger real, antes → depois** (`./bin/sdd autonomy --all-repos --by-mission` e
   `./bin/sdd autonomy --all-repos`, comandos e saída de hoje congelados em `01-plano.md`):
   - linha `sdd_agents/20260816-runner-sem-dividas`: `5 advanced · 10 churned` → **`14 advanced · 1 churned`**
     (as 9 sessões EXEC do laço passam a `advanced`; o `1 churned` que sobra é a r1 do REVIEW,
     reprovada por `Test Coverage = B` — churn de verdade, e é bom que continue lendo assim);
   - sessões EXEC lidas `churned` em todo o ledger: **46 → ≤ 6**;
   - versões com `100% waste` na tabela por versão: **49 de 107 → ≤ 10**.
3. **Juiz, em fixture:** em `tests/check-kaizen.sh`, uma fase EXEC de três incrementos que fechou
   sem retry nem escalada lê `ok` (hoje `leve`) e `advance_rate` conta os incrementos que andaram;
   a fase de `frete-cif-fob` (7 sessões, 5 reprovações, **1** churn real) continua lendo `leve`.
4. **Paridade preservada:** a janela humana e a série do juiz contam o mesmo histograma sobre um
   arquivo (asserção diferencial existente, `tests/check-autonomy.sh:1453`), inclusive sobre um
   ledger que mistura linhas com e sem os campos novos.

## Resultado esperado

O runner escreve em cada linha EXEC do ledger quantos incrementos faltavam antes e depois da sessão
(e o total), lidos do mesmo lugar de onde o `gate_EXEC` já tira o `N of M`. O `outcome` vira local à
linha: `advanced` quando o gate passou **ou** quando `pending_after < pending_before`; `churned` e
`idle` como hoje. As 49 linhas EXEC históricas, que não têm os campos, leem o mesmo fato do
`gate_why` por um caminho **declarado e datado**, comparando com a linha EXEC anterior da missão — e
a janela humana diz quantas linhas leu por esse caminho. O juiz lê `outcome` na rubrica (`leve` só
com churn real, `auto_retry` ou `idle`) e no `advance_rate`. Docs, agente do juiz, `CONTEXT.md` e
`KAIZEN_LOG.md` dizem o que o número passou a significar, com antes/depois medidos.

## Fora de escopo

- **O custo do REVIEW** (39% de todo o gasto do ledger; US$ 22–37 por rodada; r1 fecha em A nas 4
  últimas missões). Medido durante este planejamento — semente da missão seguinte, com o comando —
  na seção "Próxima missão" do `01-plano.md`. Nenhum código desta missão toca o REVIEW.
- **`sdd close` fora do ledger** — item aberto no `TODO.md` (`b79bfc6`); não é este escritor.
- **Migrar ou reescrever linhas antigas do ledger** — append-only por contrato; o caminho histórico
  é de leitura, nunca de escrita.
- **Faxina D15 do backlog** — recusada pela régua do handoff anterior ("polir o eixo errado").
- **Um quarto rótulo do juiz** (`refez`/`leve`/`ok` ficam três; a magnitude mora em `outcomes`).
- **`step` nomeando o incremento** (`EXEC:I3`): tentador, mas o executor escolhe o incremento
  dentro da sessão e o runner não sabe qual — a contagem antes/depois responde a mesma pergunta sem
  inventar um contrato que ninguém escreve.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 6 perguntas, 6 respostas (`A` em todas) — seção "Decisões do grill"; 🚩 vazia |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 abaixo; DDD `n/a` com justificativa |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | `01-plano.md` § Contexto verificado: cada função, linha, fixture e mutante que o I1 toca está citado com `bin/sdd:linha` e `tests/…:linha`, medidos em 2026-08-29 sobre `ebe9702` |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 5 incrementos, 5 Checks ancorados em `^  ok    ` com herestring, nenhum `\|` cru |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `.sdd/config.sh:27` `JIRA_ENABLED=false` |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | ledger real recontado com `jq` (72 linhas EXEC, 49 com `N of M` na prosa), `gate_EXEC` lido, os dois leitores lidos, fixtures lidos |
| K2 | Problema declarado com métrica | ✅ | § Métrica: 1 binário na sessão real, 3 números no ledger real, 1 no juiz |
| K3 | Desperdícios identificados e cortados | ✅ | cortados: `step:EXEC:I<n>`, quarto rótulo, migração, um `reduce` obrigatório no caminho novo (a linha nova é local); o histórico paga o `reduce` uma vez, declarado |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | I1 escritor → I2 leitor local → I3 caminho histórico → I4 juiz → I5 registro; cada um cabe numa sessão e tem Red descrito em uma frase |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | todo Check lê `^  ok    <asserção>` de um sensor, nunca o texto solto; o I1 ainda exige `bash -n bin/sdd` |
| K6 | Jidoka — o que para a linha está definido | ✅ | mutante que não aplica (rc 90) ou sobrevive (`N-1 caught`) reprova o `sdd health` e o `gate_PR` recusa; `check-lang` reprova português em `bin/ tests/` |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | `docs/pipeline.md` (tabela do ledger + rubrica), `agents/sdd-kaizen.md` + espelho, `CONTEXT.md` (Churn, D16), 5 mutantes novos, 2 re-ancorados |
| K8 | Registro no KAIZEN_LOG | ✅ | I5, com os números do § Métrica antes → depois, medidos e não estimados |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a mudança é no instrumento de medição do próprio kit (três campos numa
linha de log e duas definições jq), sem entidade, agregado ou contrato entre módulos de produto.`

## Decisões do grill (não re-litigar)

1. **Atacar o ponto cego do EXEC no instrumento, não o custo do REVIEW nem a faxina do backlog.**
   Sem isto, qualquer missão seguinte é carimbada `leve` pelo juiz — e o custo do REVIEW foi medido
   de graça durante o planejamento (§ Próxima missão do plano), não precisa de sessão.
2. **O fato entra na linha como `pending_before` / `pending_after` / `increments_total`**, contados
   antes da sessão (helper puro, sem `TEST_CMD`) e publicados pelo `gate_EXEC` depois — e não como
   um campo só com `reduce` no leitor, nem como parse de `gate_why` para linha nova. O `outcome`
   fica **local à linha**: `sdd retry`, `--phase EXEC` humano e QA que abre `F1/F2` (o total cresce)
   não confundem a leitura.
3. **As 49 linhas EXEC antigas leem o mesmo fato do `gate_why`, por um caminho declarado, datado e
   contado** — só quando `pending_before` está ausente; comparando com a linha EXEC anterior da
   mesma missão em ordem de arquivo (primeira linha: `N < M`; `M` mudou ⇒ compara com o `M` novo;
   `gate: pass` zera a memória). Nunca migração (append-only), nunca "linha antiga fica `churned`"
   (a janela humana ficaria mentindo para sempre e o kaizen não teria número real).
4. **O juiz lê `outcome`, não `gate`**: `leve` ⇐ alguma sessão com `outcome != advanced` ou
   `auto_retry`; `advance_rate = advanced ÷ sessões`. Uma régua, a mesma nos dois leitores e na
   manchete — enum lido em mais de um lugar é uma definição.
5. **O spike do REVIEW é gemba do planejamento, não incremento.** Está no `01-plano.md` com o
   comando; zero sessão paga por um `jq`.
6. **A missão mora em `docs/handoffs/20260829-o-incremento-que-andou/` e roda pelo `sdd run` com o
   kit como alvo** — é a segunda missão do eixo do juiz (`sufficient: false` hoje) e a primeira
   medida pela régua que ela mesma conserta. As duas de 2026-08-28 rodaram fora do runner e não
   existem no ledger.

## Pendências para o humano

- Nenhuma que bloqueie. Para o PR: (a) o número exato de `churned` que sobra em
  `runner-sem-dividas` e o de versões a `100% waste` vêm da execução, e o `KAIZEN_LOG` cita o
  medido, não o alvo; (b) a missão seguinte (custo do REVIEW) fica desenhada no `01-plano.md` com
  os números de hoje, para ser grilada com o humano — não nasce de `sdd kaizen`.
