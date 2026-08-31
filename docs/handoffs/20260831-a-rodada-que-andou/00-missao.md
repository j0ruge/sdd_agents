---
missao: 20260831-a-rodada-que-andou
titulo: O ledger diz se a rodada de REVIEW andou, e a fase que fechou de graça para de ler `refez`
data: 2026-08-31
versao:
branch: feat/a-rodada-que-andou
aprovacao: humano-2026-08-31
ddd: n/a
---

# Missão — A rodada que andou

> ⚠️ **Plano nascido do `sdd kaizen`, não do `sdd-planner`.** Não houve humano na sala e não houve
> grill. `aprovacao:` fica **vazio** por contrato (`plan_approves_itself()`, `gate_PLAN`): a
> premissa que licencia o PLAN-AUTO — "o humano estava presente" — é falsa aqui. O destravamento é
> `sdd approve 20260831-a-rodada-que-andou`, e a tabela abaixo existe para o humano decidir com
> evidência, não para se auto-aprovar.
>
> O veredito que motivou este plano está ao lado, em `05-verdict.md`.

## Problema (Gemba)

A janela de medição 2 fechou e produziu a **primeira fatia da história do kit com
`guard.sufficient: true`**: `kit_sha bf001fe`, 3 missões de `sales_quote`, 23 sessões, US$ 175,96,
`escalations: {}`. Dezoito células de rótulo, **16 `ok`**.

As **duas** que não são `ok` são as duas metades do mesmo defeito: **o instrumento não sabe ler o
que aconteceu.**

**(a) O laço desenhado do REVIEW é lido como desperdício.** Célula `leve`, REVIEW de
`20260830-a-tela-que-mente-o-pagamento`: 2 sessões, `1 advanced · 1 churned`, **US$ 47,81** — a
célula mais cara da fatia inteira. O REVIEW é um laço **por desenho**: `REVIEW_MAX_ITER=3`
(`bin/sdd:116`) e as rodadas são derivadas do disco por `review_rounds_on_disk()`
(`bin/sdd:2512`), que conta os arquivos `40-review-r<N>.md`. Uma r1 que aterrissa
`40-review-r1.md` com achados reais e não alcança Grade A **avançou uma rodada** — e o `def
outcome` (`bin/sdd:1925`) a lê como `churned`, porque o único braço de progresso que ele conhece é
`pending_after < pending_before`, que só existe para o EXEC.

Isto é, letra por letra, o defeito que `20260829-o-incremento-que-andou` consertou para o EXEC. O
comentário deixado por aquela missão está em `bin/sdd:4924` e diz o porquê: *"gate_EXEC refuses
once per increment BY DESIGN. A rubric that cannot tell the designed loop of the pipeline from a
phase that spun is not stricter, it is blind in a new direction."* Está vivo uma fase adiante, na
fase que consome **41% de todo o gasto** da janela (US$ 72,39 de US$ 175,96, somando as células
`cost_usd` do `detail` da própria série).

**(b) A fase que fechou sem gastar sessão lê `refez` para sempre.** Célula `refez`, QA de
`20260830-o-rascunho-fantasma-do-mount`: 1 sessão, `0 advanced · 1 churned`. `refez` é o sinal de
fricção **mais forte** da rubrica, e aqui é falso. A cláusula (`bin/sdd:4938`) carimba `refez`
quando *"the phase's last session still failing its gate"*. Os fatos fecham num relato só:
`escalations: {}` (a QA não escalou), **1 lançamento** para a missão inteira em
`sdd autonomy --all-repos --by-mission` (nenhum `sdd retry`, nenhum segundo `sdd run`), e REVIEW,
DOCS e PR todos com sessão e todos `ok` depois dela. Logo o `gate_QA` passou mais tarde, dentro do
mesmo run e **sem gastar sessão** — e uma passagem que não compra sessão não escreve linha nenhuma
no ledger. A rubrica pergunta *"a última **sessão** passou?"* quando quer dizer *"a **fase**
fechou?"*.

O achado já está aberto no `TODO.md` (`bin/sdd:1080`, *"gate que passa sem abrir sessão não gera
evento nenhum"*, descoberto por `humano` na missão `20260817-eixo-do-juiz`). O que a janela 2
acrescenta é o **consumidor**: não é só o humano que acompanha que fica sem ver — é o juiz que
carimba o sinal mais forte da rubrica sobre uma fase que fechou limpa, com zero intervenções.

## Métrica

Três fatos verificáveis, nesta ordem:

1. **(a), no ledger real.** `"$SDD_HOME/bin/sdd" autonomy --all-repos` na linha `bf001fe` lê hoje
   `23 session(s) · 21 advanced · 2 churned · 0 idle · 8% waste`. Depois de I1–I3 tem de ler
   `22 advanced · 1 churned · 0 idle · 4% waste`, sobre **as mesmas 23 linhas do ledger** — nenhuma
   migração, nenhuma linha reescrita.
2. **(b), por sensor.** Um mundo de fixture em que uma fase gasta uma sessão que reprova o gate e
   o gate passa depois **sem sessão** deixa de rotular a fase `refez`. ⚠️ A promessa é **`refez`
   deixar de ser afirmado**, e não a célula ficar verde: a sessão sobrevivente continua `churned`
   pela sua própria conta, e a cascata pode legitimamente pousar em `leve`. Prometer `ok` seria
   trocar um rótulo falso por outro.
3. **Régua reprodutível.** O antes/depois de (1) entra no `KAIZEN_LOG.md` com os dois comandos e as
   duas saídas. Sem número medido não é kaizen — é opinião.

## Resultado esperado

O ledger passa a saber, para a fase REVIEW, o mesmo que já sabe para o EXEC desde 2026-08-29: se a
**rodada andou**. Três campos aditivos na linha REVIEW (`rounds_before`, `rounds_after`,
`rounds_max`), esquema com `v` ainda `1` e zero migração; o "antes" é uma **foto** tirada antes de
`run_phase`, o "depois" é publicado pelo `gate_REVIEW`. As linhas de REVIEW anteriores ao esquema
recuperam o mesmo fato por um caminho **datado, declarado e contado na tela**, exatamente como
`historic_progress` faz hoje para o EXEC.

E a rubrica para de afirmar `refez` sobre fase que fechou: o runner passa a **gravar o fato** de
que um gate passou sem gastar sessão, em vez de deixar o juiz inferi-lo da ausência.

Com isso a janela 3 nasce com um instrumento que sabe distinguir o laço desenhado do pipeline de
uma fase que girou — nas duas fases que ainda não sabiam — e a missão do custo do REVIEW que a D19
parou "para depois do veredito" passa a ter um número em que confiar antes de alguém tentar cortá-lo.

## Fora de escopo

- **Cortar o custo do REVIEW.** Esta missão torna o número honesto; ela não o reduz. A D19 mediu a
  semente em 39% e a janela 2 re-mediu em 41% — a missão de corte vem **depois** desta, pelo mesmo
  argumento que fez `20260828-instrumento-honesto` vir antes de qualquer decisão sobre o EXEC:
  otimizar contra instrumento que mente é como o `frete-cif-fob` custou US$ 73,32.
- **A faxina D15 do backlog.** Três itens triados nesta sessão são dívida declarada e vão para o
  cabeçalho do próprio sensor; estão nomeados com destino em `01-plano.md` § "Triagem D15" e
  **não** são executados aqui. A faxina completa já está listada como missão própria no handoff da
  janela 2 (`docs/superpowers/specs/2026-08-30-janela-2-handoff.md:178`).
- **A contaminação do ledger real por missões de fixture** (`clone/20260901-jornada-qa`,
  `clone/20260903-placeholder`). Item aberto no `TODO.md`; **não** alcançou a fatia julgada
  (`other_repo: 0`, `no_repo: 0`, composição 100% `sales_quote`), então não bloqueia esta missão.
- **`PROGRESS <fase> <motivo>` e o `sdd monitor`** — a direção larga do item `bin/sdd:1080`. O I4
  paga a metade que o juiz consome e deixa a metade que o humano-que-acompanha consome onde está.

## Gate PLAN-AUTO

Preenchido pelo `sdd-kaizen` **com evidência**. ⚠️ Neste plano o resultado da tabela **não**
destrava nada: plano kaizen-born nunca carrega `aprovacao: auto` (`plan_approves_itself()`), e o
único destravamento é `sdd approve`. A tabela é a evidência com que o humano decide.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | **Grill humano em 2026-08-31** (posterior ao nascimento headless): 5 perguntas, 5 decisões — a escolha do I4 fechada com condição estreita medida na Gemba (`current_phase()` re-avalia gates), D11 confirmada, assimetria aceita, D7 direcionada à triagem. Registrado em "Decisões do grill". ⚠️ `aprovacao:` segue vazia mesmo assim — plano kaizen-born só destrava por `sdd approve`. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | Tabela K1–K8 abaixo, 8/8; DDD `n/a` justificado abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | `01-plano.md` § "Contexto verificado" carrega os 9 fatos com `arquivo:linha` e saída de comando; nenhum incremento depende de ler o `05-verdict.md` |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 4 de 4, todos ancorados em `^  ok    ` com herestring, sem `\|` na célula (`templates/checkpoint.md:21`) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no kit — `versao:` vazio satisfaz o critério |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Série real lida (`sdd kaizen --series`), `review_rounds_on_disk` lido em `bin/sdd:2512`, rubrica em `:4935-4943`, `ledger_outcome_defs` em `:1926`, os 7 `GATE_WHY` de `gate_REVIEW` enumerados |
| K2 | Problema declarado com métrica | ✅ | `21 advanced · 2 churned · 8% waste` → `22 advanced · 1 churned · 4% waste` na linha `bf001fe`, sobre as mesmas 23 linhas |
| K3 | Desperdícios identificados e cortados | ✅ | O desperdício **medido** é o do instrumento, não o do pipeline: 2 de 18 células mentem. Cortar custo do REVIEW fica fora de escopo, declarado |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | I1 (campos) → I2 (leitura) → I3 (caminho datado) → I4 (a fase que fechou); I1–I3 entregam a métrica sozinhos se o I4 parar a linha |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os 4 Checks leem a linha `^  ok` de um sensor da suíte; a verificação E2E lê o ledger real, nunca a prosa da sessão |
| K6 | Jidoka — o que para a linha está definido | ✅ | Se o raio de alcance do I4 exceder os cinco leitores enumerados em `01-plano.md` § I4, o I4 vira `blocked` e missão própria — I1–I3 já entregaram a métrica |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Mutante por regra no `tests/check-mutation.sh` (`sdd health` reprova regra nova sem mutação); enum de `event` atualizado em `docs/pipeline.md` no **mesmo commit** do I4 |
| K8 | Registro no KAIZEN_LOG | ✅ | Métrica (3): antes/depois com os dois comandos e as duas saídas |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a mudança é no instrumento de medição do próprio runner (campos de
ledger e duas definições `jq`), sem aggregate, bounded context, evento de domínio ou contrato entre
módulos de negócio.`

## Decisões do grill (não re-litigar)

> O plano nasceu headless, e **o grill aconteceu depois, com o humano — 2026-08-31**, orquestrado
> por `kaizen-software` (Gemba antes de opinar) com `brainstorming` + `grill-with-docs`: 5
> perguntas, 5 decisões, e uma re-Gemba que confirmou as alegações factuais do plano e achou o
> fato do `current_phase()` que a decisão 3 abaixo incorpora. As decisões 1–3 originais da sessão
> headless foram mantidas (1, 2) ou tornadas precisas (3); as 4–6 são do grill.

1. **A régua muda no meio da janela, de propósito.** Consertar depois da janela 3 significaria uma
   segunda janela medida com instrumento sabidamente errado. Mitigação é a que `20260829` já usou e
   provou: campos **aditivos**, caminho datado para as linhas antigas, e o antes/depois medido no
   `KAIZEN_LOG.md` — o `05-verdict.md` desta missão já carrega o aviso de régua para quem citar os
   números da janela 2 depois.
2. **`rounds_after` é publicado quando o arquivo da rodada é resolvido, não quando o gate aprova** —
   assimetria deliberada com o `pending_after` do EXEC, e ela tem razão: o `pending_after` do EXEC é
   um **veredito** porque o checkpoint é um rótulo que o executor escreve sobre si mesmo
   (`done` sem commit), enquanto o `N` de `40-review-r<N>.md` é **estrutural** — está no nome do
   arquivo, ninguém o auto-declara. O porquê vai no comentário da função.
3. **O I4 grava o fato, não o infere — com condição ESTREITA, decidida pelo humano no grill.**
   A linha `gate_pass` só nasce no laço do `cmd_run` e só quando `sessions[$phase] > 0` na
   corrida (1 linha por fase por corrida; `sdd status` nunca escreve; limite declarado no
   `01-plano.md` § I4). A inferência via `phase_index` segue como plano B apenas sob o Jidoka do
   K6 — é a forma que `f00c2dc` recusou com *"uma inferência não passa na frente do que o runner
   mediu"*.
4. **A assimetria do `rounds_after` está aceita** (grill, 2026-08-31): o `N` é estrutural (nome do
   arquivo, `latest_matching` compartilhado com o gate), publicar no resolve é o que faz a r1
   reprovada contar como rodada que andou. O porquê vai no comentário + mutante.
5. **D11 confirmada pelo humano** (grill, 2026-08-31): `event: "degraded"` próprio, como já opera
   no código desde o laço da QA. A 🚩 sai do `CONTEXT.md` no commit deste grill.
6. **Os 6 mutantes entram; o destino do alvo "suíte < 30 s" da D7** (subir × aposentar) **fica
   para a triagem do próximo `sdd kaizen`**, com o número medido na mesa. Não se corta mutação
   para ganhar relógio.

## Pendências para o humano

**Todas as três originais foram resolvidas no grill de 2026-08-31** — viraram as decisões 3, 5 e 6
acima (I4 com condição estreita; D11 confirmada e a 🚩 removida do `CONTEXT.md` no commit do
grill; D7 direcionada à triagem do próximo kaizen). Nada pendente além do próprio `sdd approve`.
