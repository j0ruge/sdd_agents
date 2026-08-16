---
missao: 20260815-ledger-sem-ponto-cego
fase: EXEC
status: done
sessao: 53d2d711-671c-49c9-9004-d98971244bbd
data: 2026-08-16 02:05
gate: "`./tests/run-all.sh` → rc 0 · saída final `suite green` · `score: 29 caught, 0 known gap(s), of 29` (baseline da missão: 25) · 68,7 s (`time`, default de `SDD_MUTATION_JOBS`; 55,8 s medidos na abertura desta mesma sessão, antes do F1). `shellcheck -S warning bin/sdd` limpo; `./bin/sdd health` verde nos 5 checks (suíte, mutação 29/29, mutação por gate, proveniência dos 3 fixtures, catraca de dívida sem item novo). Os quatro Checks do `checkpoint.md` batem com os commits `3521b9a`, `6853796`, `e9a74aa` e `56b2365`, todos ancestrais de `HEAD`. A segunda metade do Check do F1 — re-walk da jornada J2 fora da suíte, com stub que move o disco a cada sessão — foi andada contra os dois runners: `06af132` (pré-F1) → `rc 3`, ramo `draft` entrado 3×, sequência `REVIEW PR PR`, **3** linhas `event:\"degraded\"`, **3** `DEGRADED` no diário, `review-to-draft: 3` no `sdd autonomy` e na série; working tree (pós-F1) → tudo idêntico **menos o registro**: **1** linha, **1** `DEGRADED`, `review-to-draft: 1` nos dois leitores, `excluded.unrecognized: 0`."
---

# Handoff — EXEC — o ledger e o Jidoka param de mentir

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

> **Quatro passagens pelo EXEC** (I1, I2, I3 e o fix `F1` que a fase QA abriu). Este handoff cobre
> as quatro; o detalhe de cada uma está nas notas de execução do `checkpoint.md`, que é onde as
> lições caras ficaram registradas linha a linha.
>
> ⚠️ **Este arquivo foi reescrito depois do `F1`.** A versão anterior fechava a missão em `e9a74aa`
> e não sabia do achado do QA. Se algo aqui contradiz uma memória de leitura anterior, vale este.

## TL;DR

Os três pontos cegos do ledger fecharam, e o quarto — achado pelo próprio QA da missão — fechou
junto: o Jidoka do incremento `blocked` parou de depender do tamanho do checkpoint, a
auto-degradação `review→draft` passou a existir no ledger e nos dois leitores, as escaladas do
`sdd autonomy` foram para o mesmo eixo de `kit_sha` que a série já usava, e a degradação passou a
valer **uma linha por run** em vez de uma por volta do laço. Suíte verde com mutação **29/29**
(baseline 25). Mudança 100% em `bin/sdd` + `tests/`: **nenhuma interface de usuário final**,
nenhum contrato de artefato, nenhum agente ou template.

## Estado do repo

- **Branch:** `missao/20260815-ledger-sem-ponto-cego` — nunca empurrada; `origin` não conhece
  este trabalho. `git push` é da fase PR, não desta.
- **Último commit:** `56b2365` `fix(runner): a auto-degradação vira UMA linha por run, não uma por volta`
  (mais o commit de checkpoint/handoff que fecha esta sessão).
- **Working tree:** limpo.
- **Suíte:** `./tests/run-all.sh` → **verde**, `score: 29 caught, 0 known gap(s), of 29`,
  `KNOWN_GAPS` vazio, 68,7 s.
- **E2E:** `E2E_CMD` vazio em `.sdd/config.sh:7` — este repo é bash + markdown, não tem jornada de
  navegador. Não rodou por não existir.

## O que foi feito

- `3521b9a` — **I1**: o Jidoka do incremento `blocked` (`bin/sdd`, ramo EXEC) trocou
  `printf … | grep -qx` por herestring, nas duas ocorrências vivas (a do Jidoka e a do probe do
  `sdd preflight`). Sob `pipefail` o pipeline devolvia **141** quando o `grep` **achava** — a linha
  não parava justamente quando devia, e o runner queimava o `phase_budget` inteiro contra a parede
  que já sabia estar lá. Sensor: `RUN_jidoka_pipefail` + asserção sobre um checkpoint de 20000
  linhas (o regime de falha só aparece acima de ~5000).
- `6853796` — **I2**: a auto-degradação `PUBLISH_ON_REVIEW_BLOCKED=draft` passou a escrever uma
  linha `event: "degraded"`, `kind: "review-to-draft"` no ledger **e** no diário do pipeline — o
  `force_phase="PR"; continue` saltava os dois. Quatro pontos tocados, não dois: o escritor, o
  `select` da série, o `is_escalation` do `cmd_autonomy` e o `pipeline_log_line`. Sensor:
  `RUN_degraded_row_dropped`.
- `e9a74aa` — **I3**: as escaladas do `sdd autonomy` passaram a ser agrupadas por
  `(kit_sha, kind)`, com kit sujo / sha nulo excluídos e contados como o bloco de sessões já fazia.
  A série **não** foi tocada: ela já estava certa, e mexer nos dois lados recriaria a divergência.
  Sensor: `RUN_escalations_no_axis` + uma asserção que compara, dado contra dado, a tabela do
  `sdd autonomy` com o mapa `escalations` do `sdd kaizen --series` para o mesmo `kit_sha`.
- `56b2365` — **F1** (fix aberto pelo QA): a degradação passou a valer **uma** linha por `sdd run`.
  `force_phase="PR"` não encerra o laço — PR roda, o gate falha, `current_phase()` devolve REVIEW
  com o orçamento ainda estourado, e o ramo `draft` era reentrado a cada volta escrevendo um
  registro por volta. O QA mediu 3 linhas para 1 degradação, com os dois leitores **de acordo entre
  si e errados juntos**, contra a "exatamente uma" da métrica 3 do `00-missao.md`. Guarda one-shot
  por run (local de `cmd_run`) cobrindo o ledger **e** o diário; o `warn` ficou fora dela de
  propósito. Sensor: `RUN_degraded_repeats` + a mudança de **regime** do fixture da degradação em
  `tests/check-autonomy.sh` — o stub passou a mover o disco a cada chamada, com asserção explícita
  de que o ramo foi entrado ≥2 vezes. A metade de **laço** (o runner girar REVIEW→PR→REVIEW)
  continua aberta e sozinha no `TODO.md`.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260815-ledger-sem-ponto-cego/checkpoint.md` | A tabela dos 4 incrementos, todos `done` com hash, e as notas de execução — inclusive as **quatro** lições sobre asserção vácua que custaram caro |
| `bin/sdd` | Os quatro consertos: Jidoka com herestring, `autonomy_escalation_row` + o ramo `draft` que escreve, o eixo de `kit_sha` no `cmd_autonomy`, e a guarda one-shot `degraded_logged` em `cmd_run` |
| `tests/check-gates.sh` | A asserção do Jidoka sobre checkpoint de 20000 linhas (I1) |
| `tests/check-autonomy.sh` | O fixture caro da degradação — agora no **regime de repetição** (I2 + F1) — e o bloco `reader: escalations carry the kit_sha axis` (I3) |
| `tests/check-mutation.sh` | Catálogo 29/29 — os quatro mutantes novos desta missão |
| `docs/pipeline.md` | Vocabulário do evento `degraded` (I2), a regra do eixo compartilhado entre os dois leitores (I3) e a cardinalidade "no máximo uma linha `review-to-draft` por `run_id`" (F1) |
| `TODO.md` | 6 achados fora de escopo registrados durante a execução, mais a entrada da auto-degradação repetida com a metade de registro marcada como fechada |

## Boot da próxima fase

A próxima fase é **REVIEW**: o QA já rodou (`30-handoff-qa.md`, `status: done`, `gate:` com a
evidência das 3 jornadas), abriu o `F1`, e o `F1` está `done` — o laço QA⇄EXEC fechou. Leia, nesta
ordem: `00-missao.md` (a métrica), este handoff, o `30-handoff-qa.md` (as jornadas andadas) e as
notas de execução do `checkpoint.md` — é lá que estão as **quatro** lições de asserção vácua, que
são o fio condutor desta missão inteira e o que mais merece olhar crítico na revisão.

**O que no diff é visível para o usuário:** só a saída de **um comando de CLI**, `sdd autonomy`.
O bloco `escalations` mudou de forma:

```
escalations
  <kit_sha>  <kind>: <n>
```

antes era `  <kind>: <n>`, sem versão, somando escaladas de kits diferentes e incluindo linhas de
kit sujo. Linhas não atribuíveis a uma versão agora entram na contagem
`(N non-comparable row(s) excluded: …)`, que já existia. Nada mais mudou de saída: `sdd run`,
`sdd why`, `sdd kaizen --series` e `sdd health` imprimem o que imprimiam.

O `F1` **não** mudou saída de comando nenhum: ele muda quantas linhas o `sdd run` escreve nos dois
trilhos de registro. O `warn` `PUBLISH_ON_REVIEW_BLOCKED=draft — moving on to PR in draft mode`
continua saindo uma vez por volta do laço, de propósito.

**Jornadas tocadas:** nenhuma jornada de navegador — este repo não tem interface. As jornadas de
CLI que o diff toca são (1) `sdd run` numa missão com incremento `blocked` (deve parar com rc 3 e
`The line stopped on purpose`, sem abrir sessão), (2) `sdd run` que estoura `REVIEW_MAX_ITER` com
`PUBLISH_ON_REVIEW_BLOCKED=draft` (deve degradar para PR, deixar rastro no diário e no ledger, e
deixar **exatamente um** de cada por run, mesmo que o laço gire) e (3) `sdd autonomy` sobre um
ledger com escaladas em mais de um `kit_sha`.

**Como subir o ambiente:** não há ambiente para subir. Basta `bash` + `jq` + `git`. O comando
único que exercita tudo é `./tests/run-all.sh` (≈60 s); `./bin/sdd health` roda a suíte mais as
checagens de drift de doc/config do próprio kit.

⚠️ **Não rode a suíte com `SDD_MUTANT` exportado no seu shell** — a variável é o mecanismo
anti-recursão do `check-mutation.sh`, não uma opção de usuário, e exportá-la pula linter **e**
mutação da suíte inteira.

## Pendências / Decisions for a Human

- **O vocabulário do evento de degradação (I2)** — o plano deixou a escolha registrada em
  "Pendências para o humano" do `00-missao.md` e implementou a primeira opção: `event: "degraded"`
  com `kind: "review-to-draft"`, reservando `blocked` para run que de fato para. A alternativa
  (reusar `blocked` com um `kind` novo) era mais barata mas gravaria "parou" para um run que
  continuou. Se o humano preferir a alternativa, é um valor de campo e as asserções
  correspondentes — ver `bin/sdd` (`autonomy_degraded_row`) e `tests/check-autonomy.sh`.
- **Alvo de tempo da suíte** — a D7 do `CONTEXT.md` fixou "<30 s"; a baseline desta missão já
  estava em 37,4 s e o fim dela está em **68,7 s**. Os quatro mutantes novos custam tempo por
  construção (cada um roda a suíte inteira numa cópia), e o `F1` custa duas vezes: um mutante a
  mais **e** um fixture que agora abre mais sessões de stub por rodada. Subir `SDD_MUTATION_JOBS`
  (default 4; `nproc` é GNU-only, por isso não foi mexido aqui), subir o alvo, ou aceitar.
  Registrado no `TODO.md` com a medição.

## Riscos e não-feitos

- **A evidência de mutação de três das quatro metades do I2 é de sessão, não de CI.** O `select`
  da série, o `pipeline_log_line` e o `is_escalation` do `cmd_autonomy` foram sabotados à mão e os
  três mataram a suíte, mas só o escritor virou mutante permanente — o Check do incremento fixava
  o score em 27, e um mutante que sabota várias âncoras derruba a detecção de "âncora apodreceu".
  Está no `TODO.md`.
- **O runner ainda gira REVIEW→PR→REVIEW depois de se degradar.** O `F1` fechou a metade de
  **registro** (uma linha por run); a de **laço** continua aberta e sozinha no `TODO.md`: com o
  orçamento de REVIEW estourado e a fase PR mexendo no disco sem passar no gate, `current_phase()`
  devolve REVIEW indefinidamente até o `no-progress` do PR encerrar. Medido no re-walk: o ramo é
  entrado **3** vezes. Registrar uma vez não faz o run parar de girar — são dois defeitos.
- **`KAIZEN_LOG.md` ainda não tem o registro desta missão.** É trabalho da fase DOCS, com o
  antes/depois já medido e disponível aqui: mutação **25 → 29**, suíte **37,4 s → 68,7 s** (a
  baseline de 37,4 s foi medida em máquina descarregada; medições intermediárias sob carga:
  48,5 s no `HEAD` `7751ce1`, 53,3 s no `0976fc9`, 59,9 s no I2, 59,4 s no I3, 56,7 s no QA e
  55,8 s na abertura da sessão do F1 — a mesma máquina varia ±10%, então só o par medido lado a
  lado na mesma sessão vale como antes/depois).
- **A vacuidade de asserção foi o defeito recorrente desta missão, quatro vezes.** I1 (`rc 3`
  compartilhado com outro ramo de escalada), I2 (ramo `draft` que o fixture nunca alcançava, pego
  antes do prejuízo), F1 (cardinalidade garantida pelo regime do stub, pego pelo QA depois de dois
  commits) e, no próprio F1, a necessidade de uma asserção que prove o **regime**. Vale como lente
  para a revisão: onde mais uma asserção verde desta missão pode estar medindo o fixture?
- **Nada foi verificado num `sdd run` real de ponta a ponta** — toda a evidência vem da suíte, com
  `claude` stubado. É a mesma limitação que o maior item aberto do `TODO.md` descreve (o preflight
  headless nunca executa `TEST_CMD` de verdade) e não é regressão desta missão.
- **A suíte ainda usa `printf | grep -q` do lado do teste** (`check-gates.sh` e cinco pontos do
  `check-dry-run.sh`) — mesma família que o I1 fechou no runner, fora do Check do I1.
  `shellcheck -S warning tests/` também reprova (SC2318, pré-existente), e o `LINT_CMD` deste repo
  só olha `bin/sdd`. Ambos no `TODO.md`.

## Achados fora de escopo

> Registrados no `TODO.md` do repo-alvo (ou do `sdd_agents`, se for melhoria do kit). Aqui fica
> só o ponteiro, para o PR conseguir citar.

- `printf | grep -q` sobrevivendo no lado do teste + `shellcheck` de `tests/` fora do `LINT_CMD` (I1) → `TODO.md`
- Três metades do evento `degraded` sem mutante permanente (I2) → `TODO.md`
- Auto-degradação repetida no mesmo `sdd run` (I2) — metade de **registro** fechada pelo `F1`, metade de **laço** ainda aberta → `TODO.md`
- Dois testes de comparabilidade dentro do mesmo `jq` do `cmd_autonomy` (I3) → `TODO.md`
- Tabela do `sdd autonomy` ordenada lexicograficamente contra a ordem de aparição da série (I3) → `TODO.md`
- `sdd install` imprime `ok .sdd/config.sh created` com rc 0 depois de o `sed` falhar por `starter.conf` ausente — o arquivo nasce **vazio** (F1) → `TODO.md`
