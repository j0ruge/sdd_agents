---
missao: 20260911-o-juiz-nao-mente-sobre-a-janela
titulo: o juiz do kaizen para de afirmar medidas que não faz, e o ledger que ele lê deixa de ser contaminado pelos próprios testes
data: 2026-09-11
versao:
branch: feat/o-juiz-nao-mente-sobre-a-janela
aprovacao: humano-2026-09-11
ddd: n/a
---

# Missão — o juiz não mente sobre a janela

> Nascida pela triagem do `sdd kaizen` em 2026-09-11, ao lado do veredito `melhorou` sobre
> `a0e34df` (`05-verdict.md`). É a única fonte da **intenção**; o `01-plano.md` é a fonte do
> **como**.

## Problema (Gemba)

O veredito da janela 4 saiu `melhorou` com `guard.sufficient: true` — a primeira fatia em muitas
janelas a satisfazer o piso por artefato. E foi escrito com um instrumento que o próprio backlog
declara mentiroso em nove pontos. Verificado nesta sessão, não suposto:

- **O ledger real está contaminado por fixtures.** `~/.sdd/autonomy-log.jsonl` tem 291 linhas, das
  quais **11 estão sob `/tmp`** (`/tmp/qa-portas/clone` 5, `/tmp/sddrev.q49jXD/r7b` 3, três
  `/tmp/manual-*` 1 cada). São missões de teste dos próprios sensores escrevendo na fonte da
  verdade do juiz (`TODO.md:798`). Enquanto isso for verdade, qualquer antes/depois medido pelos
  outros itens é ruído.
- **O juiz vê duas versões de harness numa fatia e não recusa** (`TODO.md:856`). Na fatia julgada
  hoje, `harness: ["2.1.263"]` — uma só, por sorte e não por guarda. O sha que acabou de ser
  julgado é exatamente o que consertou um estrago causado por um bump de harness: a fatia em que
  esse fail-open dispara é a mais cara que existe.
- **A janela não percebe a própria ruptura** (`TODO.md:497`): a janela 3 foi declarada partida à
  mão e `degenerate_axis` continuou `false`.
- **Dois programas divergem sobre o `gate_pass` e um comentário jura paridade** — `$order` do
  `cmd_autonomy` × `comparable_row` do `kaizen_series` (`TODO.md:815`) —, e missão que só tem
  `gate_pass` numa fatia entra em `missions` sem produzir célula (`TODO.md:824`). As duas metades
  da guarda que decide se o veredito pode existir.
- **`reopened` é cego à closure** e a resposta depende de a fase ter custado dinheiro
  (`TODO.md:807`); a fronteira do laço de revisão é calculada sobre o subconjunto `comparable` e
  **sub-reporta** (`TODO.md:630`) — justamente a métrica que o veredito de hoje cita em 52/23/66%.
- **Duas escaladas não chegam ao ledger:** `sdd close` abre sessão e não escreve linha
  (`TODO.md:772`), `sdd retry` devolve 3 sem linha de escalada nem `BLOCKED` no `pipeline.log`
  (`TODO.md:62`). O juiz lê um ledger sem eventos que aconteceram.

Pela régua D15 os nove são **fail-open** (o instrumento afirma medir o que não mede) e sete têm
**consumidor fora da suíte**: o veredito do kit, a D12 e a decisão humana de continuar ou parar.

Além disso o backlog cresce por acúmulo de verdades: 105 itens hoje (`tests/check-todo.sh`:
`105 finding(s)`), e uma parte deles é dívida **declarável**, não defeito.

## Métrica

Três números, todos verificáveis por comando:

1. `tests/check-todo.sh` responde **95 finding(s)** (105 − 10: 9 itens de código fechados ficam com
   `RESOLVIDO por <hash>` no corpo, e 10 itens de dívida declarada saem do arquivo para o cabeçalho
   do sensor de cada um). `tests/health-baseline.txt` carrega `todo-findings 95`, movido num diff
   com autor.
2. `grep -c '"repo":"/tmp' ~/.sdd/autonomy-log.jsonl` responde **0**, e um probe novo prova que uma
   corrida de fixture **não consegue** escrever no ledger real.
3. `sdd kaizen --series` sobre um ledger de fixture com **duas** versões de harness na mesma fatia
   responde `guard.sufficient: false` com motivo nomeado — hoje responde `true`.

## Resultado esperado

O juiz do kaizen passa a recusar as fatias sobre as quais não pode responder (duas versões de
harness, janela rompida) em vez de responder alto sobre elas, e as duas metades da guarda
(`$order` × `comparable_row`) concordam por **asserção diferencial** em vez de por comentário. As
duas escaladas que hoje somem — `sdd close` e `sdd retry` — passam a escrever sua linha, então a
população que o juiz conta deixa de ter buracos. O ledger real fica limpo de fixture e passa a ser
**inescrivível** por corrida de teste, o que é a pré-condição de todo número acima.

E o `TODO.md` encolhe de 105 para 95 sem perder um fato: dez itens que são limites e não defeitos
passam a morar no cabeçalho do sensor a que pertencem, onde quem lê o sensor os encontra.

## Fora de escopo

- **O laço de revisão a 66%** — o maior desperdício medido na janela 4. É a pendência 2 do veredito
  e uma decisão humana de prioridade; fica no `05-verdict.md`, não aqui.
- **`BUDGET_MISSION_USD` calibrado abaixo do custo real** (3 escaladas `budget-exhausted` em 3
  missões) — pendência 1 do veredito, decisão humana.
- **`TODO.md:841` e `:849`** (probes da metade `repo` da chave de memória e da guarda
  `$r.phase == "EXEC"`): mesma vizinhança, mas o lote já está no tamanho de uma missão. Ficam
  abertos, intocados.
- **`TODO.md:264`** (o sensor mede a FORMA da âncora e nunca se ela aponta o alvo) e o `:662` que
  depende dele. Medido nesta sessão: vários anchors de `bin/sdd` citados no `TODO.md` já não caem
  na linha que nomeiam. É um item real e continua aberto — esta missão apenas **não confia** em
  número de linha (ver `01-plano.md`).
- Qualquer mudança em gate de fase que possa tornar missão em voo insatisfazível (princípio 1).

## Gate PLAN-AUTO

Preenchido pelo `sdd-kaizen` **com evidência**. `aprovacao:` fica **vazio** por regra: o laço de
kaizen não aprova os próprios planos — quem decide é o humano.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas | ✗ | Não houve grill: plano nascido de triagem headless. As duas decisões abertas estão em "Pendências para o humano" com dono |
| b | Checklist kaizen 100% ✅ e DDD `n/a` justificado | ✅ | Seções abaixo; DDD `n/a` (nenhum toque de domínio — bash + jq + sensores) |
| c | Plano passa no teste de autocontenção | ✅ | `01-plano.md` § "Contexto verificado" carrega comando e saída de cada fato; nenhum incremento depende de memória desta sessão |
| d | Todo incremento tem Check executável | ✅ | 6 de 6 no `checkpoint.md`, cada um comando → esperado |
| e | `versao:` confirmada (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no kit; `versao:` vazio satisfaz o critério |

Um ✗ em (a) ⇒ `aprovacao` vazio e o runner para pedindo aprovação humana explícita. É o resultado
correto aqui, e seria o resultado mesmo com (a) ✅.

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Série lida uma vez; ledger real contado (291 linhas, 11 sob `/tmp`); `check-todo.sh` rodado (105) |
| K2 | Problema declarado com métrica | ✅ | Três números, todos por comando, em "Métrica" |
| K3 | Desperdícios identificados e cortados | ✅ | O desperdício-raiz é **retrabalho de decisão**: veredito escrito sobre instrumento que se declara mentiroso. Dez itens de dívida declarável saem do backlog para onde são úteis |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 6 incrementos, cada um com Check próprio; I1 é pré-requisito dos demais |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Todo Check lê saída de sensor ancorada em `^  ok    `, ou conta linha de ledger — nunca "o agente disse" |
| K6 | Jidoka — o que para a linha está definido | ✅ | I1 falhando para a missão: sem ledger limpo e protegido, nenhum número de I2–I5 vale. Está escrito no `01-plano.md` |
| K7 | SDCA — a melhoria vira padrão | ✅ | Cada conserto entra com mutante no catálogo (`sdd health` reprova gate sem mutação); os 10 declarados viram limite escrito no cabeçalho do sensor |
| K8 | Registro no KAIZEN_LOG | ✅ | I6 exige a entrada com antes/depois medido (105 → 95, 11 → 0 linhas de fixture) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a missão mexe em bash, jq e sensores de teste do próprio kit; não há
aggregate, bounded context, evento nem entidade de domínio envolvida.`

## Decisões do grill (não re-litigar)

1. **I1 vem primeiro e é pré-requisito** — enquanto o ledger de `$HOME` carregar linhas de fixture,
   todo antes/depois dos outros cinco incrementos é medido sobre dado sujo.
2. **O lote é o juiz, não a faxina geral** — dos ~24 itens classificáveis como dívida declarada,
   só 10 entram (os que têm dono óbvio num cabeçalho de sensor). O resto fica intocado: item que
   não passa no corte fica onde está.
3. **Nenhum gate de fase é tocado** — o lote inteiro é leitura de ledger e sensores. É o que o
   mantém de risco baixo: nada aqui pode tornar uma missão em voo insatisfazível.
4. **Guarda nova se escreve positivamente** — a recusa de fatia com duas versões de harness declara
   o que **entra**, nunca `not <o que sai>`, pela regra do `CLAUDE.md` medida em `bin/sdd:5207`.
5. **Nenhum incremento ancora em número de linha do `TODO.md` ou do `bin/sdd`** — medido nesta
   sessão que as âncoras derivaram. Ancorar em código.

## Pendências para o humano

1. **`BUDGET_MISSION_USD`** (pendência 1 do veredito): 3 escaladas `budget-exhausted` em 3 missões,
   a mais cara US$ 152,30. Subir o teto ou aceitar a parada como ritual — decisão humana, e ela
   afeta esta missão, que vai custar dinheiro.
2. **Prioridade: o juiz ou o dólar?** (pendência 2 do veredito). Esta missão conserta o
   instrumento. O laço de revisão a 66% é o maior desperdício medido e **não** está aqui. Se a
   prioridade for o custo, este plano é o plano errado e deve ser recusado na aprovação.
3. **O que fazer com as 11 linhas de fixture já no ledger** — I1 as remove com backup ao lado. Se a
   preferência for preservar o arquivo intacto e filtrar na leitura, diga antes do EXEC: são
   desenhos diferentes.
