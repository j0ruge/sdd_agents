---
missao: 20260930-a-sub-etapa-que-andou
titulo: o sub-passo da QA que fechou o relatório deixa de contar como desperdício na régua do juiz
data: 2026-09-30
versao:
branch: kaizen/a-sub-etapa-que-andou
aprovacao: humano-2026-09-30
adr: none
ddd: n/a
---

# Missão — o sub-passo da QA que andou

> Nascida do laço `sdd kaizen` (sessão `sdd-kaizen`, 2026-09-30), **sem humano na sala**. O veredito
> que a originou está ao lado, em `05-verdict.md`. `aprovacao:` fica vazio por regra: o laço não
> aprova o próprio plano.

## Problema (Gemba)

A rubrica de `outcome` do ledger (`ledger_outcome_defs`, `bin/sdd:3291`, um `printf` de `jq` que
`cmd_autonomy` e `kaizen_series` incluem igual) tem três braços de progresso: `gate == "pass"`, o
braço do incremento do EXEC (`pending_after < pending_before`, desde `20260829-o-incremento-que-andou`)
e o braço da rodada do REVIEW (`rounds_after > rounds_before`, desde `20260831-a-rodada-que-andou`).
**A QA não tem nenhum**, e a QA também é um laço desenhado: `qa_substep` (`bin/sdd:2228`) roteia
`plan → exec → close`, e o `gate_QA` reprova na **primeira** linha (`bin/sdd:1299`,
`missing 30-handoff-qa.md`) toda sessão anterior ao `close`.

Medido na janela 2 (`5b98087`, `sdd kaizen --series`, campo `previous`): **7 das 9 sessões
`churned` da fatia são de QA**. Nas três missões, a primeira sessão de QA tem `step: "QA:exec"`
(a skill `qa-execution`, que fecha o relatório) e reprova com `missing 30-handoff-qa.md` — o
sub-passo fez o que o desenho manda e foi lido como volta comprada à toa. O `gate_why` de cada
linha está no ledger (`~/.sdd/autonomy-log.jsonl`); a próxima linha QA de cada missão tem
`step: "QA:close"`, ou seja, o sub-passo **andou**. Uma quarta é o laço QA⇄EXEC desenhado
(`2 bug(s) with Status: open … they become fix increments`). Três são fricção real (E2E vermelho
com o app respondendo).

É a régua D15 na sua forma mais clara: o instrumento afirma medir desperdício e conta o laço do
próprio pipeline. Consumidor fora da suíte: o veredito do juiz e o humano que lê `sdd autonomy`.

## Métrica

Fato binário, lido pelo instrumento sobre o ledger real (`sdd autonomy --all-repos --by-mission`):

- `sales_quote/20260929-aviso-diretoria-por-email`: `18 advanced · 3 churned` → **`19 advanced · 2 churned`**;
- `sales_quote/20260930-e2e-local-diz-por-que-caiu`: `13 advanced · 2 churned` → **`14 advanced · 1 churned`**;
- `sales_quote/20260930-justificativa-pedido-alcada`: `16 advanced · 4 churned` → **`17 advanced · 3 churned`**
  (o laço QA⇄EXEC histórico **não** é recuperado — ver Fora de escopo).

E nenhuma outra linha do `--by-mission` muda além das que têm sessão `QA:exec`/`QA:plan` seguida de
sub-passo posterior (diferencial antes × depois, no I4).

## Resultado esperado

A linha QA do ledger passa a carregar `step_after`, o sub-passo derivado **depois** da sessão. A
rubrica ganha um quarto braço, escrito positivamente: sessão QA que moveu o disco e cujo sub-passo
avançou na ordem `plan < exec < close` é `advanced`. Linhas antigas recuperam o mesmo fato do
`step` da próxima linha QA da mesma `(repo, missão)`, por caminho contado na tela, como o EXEC e o
REVIEW já fazem. Linhas QA novas também carregam `pending_before`/`pending_after`, e o `close` que
escreveu incrementos `F<n>` passa a ser lido como o laço QA⇄EXEC desenhado. Quatro itens do
`TODO.md` que não passam na régua D15 saem para o cabeçalho que lhes cabe, e um quinto, resolvido
fora do kit pelo `retrofit-watch` 0.2.0, sai para a seção decidida (incluído pelo humano).

## Fora de escopo

- Recuperar o laço QA⇄EXEC das linhas **antigas**: o `gate_why` diz que os bugs *viram* incrementos,
  não que a sessão os escreveu; inferir isso seria a lisonja que o `f00c2dc` recusou. Fica como está
  e o limite é declarado no comentário do `ledger_outcome_defs`.
- O eixo do juiz ignorar commit sem código (o item "Registrar achado durante a janela do juiz parte
  a janela", no `TODO.md`): mexe na D4 e na ADR 0003, pede ADR e humano.
- A fricção real de E2E local no `sales_quote` — é do alvo, e a missão `e2e-local-diz-por-que-caiu`
  já a tratou lá.
- A T3 da gaveta (F3): pede três decisões humanas, via `/sdd-plan`.

## Gate PLAN-AUTO

Preenchido pelo `sdd-kaizen` **com evidência**. Sem humano na sala, `aprovacao` fica vazio de
qualquer forma.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✗ | Não houve grill — sessão headless do laço kaizen. As duas escolhas que um grill decidiria estão nas Decisões abaixo, marcadas para o humano confirmar |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | seções abaixo; DDD `n/a` |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✗ | Não testado com sessão nova; o `01-plano.md` traz arquivo:linha de cada ponto tocado, mas nenhuma sessão fria o leu |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 6 de 6 incrementos, todos com comando e esperado |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh:47`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`: é o terceiro braço da mesma forma (os dois anteriores foram emendas da D16 no `CONTEXT.md`, sem ADR); nenhum trade-off arquitetural novo |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | linhas QA do ledger real lidas uma a uma (`step`, `gate_why`); `gate_QA` e `qa_substep` lidos no código |
| K2 | Problema declarado com métrica | ✅ | três linhas do `--by-mission`, antes e depois |
| K3 | Desperdícios identificados e cortados | ✅ | o desperdício é de **medida**: 4 sessões desenhadas lidas como churn numa fatia de 9 |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | escritor, leitor, laço F, histórico, docs, varredura D15 |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Checks ancorados em `^  ok    ` e na saída do instrumento sobre o ledger real |
| K6 | Jidoka — o que para a linha está definido | ✅ | o diferencial do I4 para a linha se qualquer linha fora das previstas mudar |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | asserções em `check-autonomy.sh`/`check-kaizen.sh`, mutantes no catálogo, `docs/pipeline.md` § Field reference, emenda da D16 |
| K8 | Registro no KAIZEN_LOG | ✅ | I5 escreve a entrada com o antes/depois do I4 |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: muda a leitura de um campo do ledger do próprio kit, nenhum contrato entre módulos de produto.`

## Decisões do grill (não re-litigar)

Não houve grill. As escolhas abaixo são do `sdd-kaizen` e ficam para o humano confirmar ao aprovar:

1. Ordem dos sub-passos `plan < exec < close`, e só **avanço** conta — sub-passo que volta ou repete
   continua `churned`, a direção conservadora.
2. Histórico recuperado pelo `step` da **próxima** linha QA da mesma `(repo, missão)`, nunca pelo
   `gate_why`: `missing 30-handoff-qa.md` sai igual com e sem o relatório fechado.
3. O laço QA⇄EXEC só conta em linha **nova**, com a foto de `pending` antes e depois da sessão.

## Pendências para o humano

- Decidir se a janela 2 é refeita ou se a próxima janela abre depois desta missão (ver o veredito):
  esta missão muda a régua de `outcome`, e números lidos antes dela deixam de ser comparáveis sem
  ressalva.
