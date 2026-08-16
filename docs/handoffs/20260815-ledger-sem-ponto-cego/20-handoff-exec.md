---
missao: 20260815-ledger-sem-ponto-cego
fase: EXEC
status: done
sessao: 7fd89d3c-6663-4090-a53d-d764d2a17f49
data: 2026-08-16 01:10
gate: "`./tests/run-all.sh` → rc 0 · saída final `suite green` · `score: 28 caught, 0 known gap(s), of 28` (baseline da missão: 25) · 59,4 s (`time`, default de `SDD_MUTATION_JOBS`). Os três Checks do `checkpoint.md` batem com os commits `3521b9a`, `6853796` e `e9a74aa`, todos ancestrais de `HEAD`."
---

# Handoff — EXEC — o ledger e o Jidoka param de mentir

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

> **Três passagens pelo EXEC, uma por incremento** (I1, I2, I3). Este handoff cobre as três; o
> detalhe de cada uma está nas notas de execução do `checkpoint.md`, que é onde as lições
> caras ficaram registradas linha a linha.

## TL;DR

Os três pontos cegos do ledger fecharam: o Jidoka do incremento `blocked` parou de depender do
tamanho do checkpoint, a auto-degradação `review→draft` passou a existir no ledger e nos dois
leitores, e as escaladas do `sdd autonomy` foram para o mesmo eixo de `kit_sha` que a série já
usava. Suíte verde com mutação **28/28** (baseline 25). Mudança 100% em `bin/sdd` + `tests/`:
**nenhuma interface de usuário final**, nenhum contrato de artefato, nenhum agente ou template.

## Estado do repo

- **Branch:** `missao/20260815-ledger-sem-ponto-cego` — nunca empurrada; `origin` não conhece
  este trabalho. `git push` é da fase PR, não desta.
- **Último commit:** `e9a74aa` `fix(runner): as escaladas do sdd autonomy passam a viver no eixo de kit_sha`
  (mais o commit de checkpoint/handoff que fecha esta sessão).
- **Working tree:** limpo.
- **Suíte:** `./tests/run-all.sh` → **verde**, `score: 28 caught, 0 known gap(s), of 28`,
  `KNOWN_GAPS` vazio, 59,4 s.
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

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260815-ledger-sem-ponto-cego/checkpoint.md` | A tabela dos 3 incrementos, todos `done` com hash, e as notas de execução — inclusive as duas lições sobre asserção vácua que custaram caro |
| `bin/sdd` | Os três consertos: Jidoka com herestring, `autonomy_escalation_row` + o ramo `draft` que escreve, e o eixo de `kit_sha` no `cmd_autonomy` |
| `tests/check-gates.sh` | A asserção do Jidoka sobre checkpoint de 20000 linhas (I1) |
| `tests/check-autonomy.sh` | O fixture caro da degradação (I2) e o bloco `reader: escalations carry the kit_sha axis` (I3) |
| `tests/check-mutation.sh` | Catálogo 28/28 — os três mutantes novos desta missão |
| `docs/pipeline.md` | Vocabulário do evento `degraded` (I2) e a regra do eixo compartilhado entre os dois leitores (I3) |
| `TODO.md` | 5 achados fora de escopo registrados durante a execução |

## Boot da próxima fase

A próxima fase é **QA**. Leia, nesta ordem: `00-missao.md` (a métrica), este handoff, e as notas
de execução do `checkpoint.md` (é lá que estão as duas lições de asserção vácua).

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

**Jornadas tocadas:** nenhuma jornada de navegador — este repo não tem interface. As jornadas de
CLI que o diff toca são (1) `sdd run` numa missão com incremento `blocked` (deve parar com rc 3 e
`The line stopped on purpose`, sem abrir sessão), (2) `sdd run` que estoura `REVIEW_MAX_ITER` com
`PUBLISH_ON_REVIEW_BLOCKED=draft` (deve degradar para PR e deixar rastro no diário e no ledger) e
(3) `sdd autonomy` sobre um ledger com escaladas em mais de um `kit_sha`.

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
  estava em 37,4 s e o fim dela está em **59,4 s**. Os três mutantes novos custam tempo por
  construção (cada um roda a suíte inteira numa cópia). Subir `SDD_MUTATION_JOBS` (default 4;
  `nproc` é GNU-only, por isso não foi mexido aqui), subir o alvo, ou aceitar. Registrado no
  `TODO.md` com a medição.

## Riscos e não-feitos

- **A evidência de mutação de três das quatro metades do I2 é de sessão, não de CI.** O `select`
  da série, o `pipeline_log_line` e o `is_escalation` do `cmd_autonomy` foram sabotados à mão e os
  três mataram a suíte, mas só o escritor virou mutante permanente — o Check do incremento fixava
  o score em 27, e um mutante que sabota várias âncoras derruba a detecção de "âncora apodreceu".
  Está no `TODO.md`.
- **O runner pode se auto-degradar mais de uma vez no mesmo `sdd run`.** Depois do
  `force_phase="PR"`, se a fase PR mexer no disco e não passar no gate, o laço volta a REVIEW com o
  orçamento ainda estourado e o ramo dispara de novo — uma linha `degraded` por volta. Honesto
  quanto ao fato, mas o humano leria "degradou N vezes" onde degradou uma e ficou preso. É mudança
  de laço, não de registro; fora do escopo do I2. Está no `TODO.md`.
- **`KAIZEN_LOG.md` ainda não tem o registro desta missão.** É trabalho da fase DOCS, com o
  antes/depois já medido e disponível aqui: mutação **25 → 28**, suíte **37,4 s → 59,4 s** (a
  baseline de 37,4 s foi medida em máquina descarregada; medições intermediárias sob carga:
  48,5 s no `HEAD` `7751ce1`, 53,3 s no `0976fc9`, 59,9 s no I2).
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
- Auto-degradação repetida no mesmo `sdd run` (I2) → `TODO.md`
- Dois testes de comparabilidade dentro do mesmo `jq` do `cmd_autonomy` (I3) → `TODO.md`
- Tabela do `sdd autonomy` ordenada lexicograficamente contra a ordem de aparição da série (I3) → `TODO.md`
