---
missao: 20260901-o-revisor-so-acha
titulo: O REVIEW acha e o EXEC conserta — a fase mais cara do pipeline perde o chapéu duplo sem perder a nota
data: 2026-09-01
versao:
branch: feat/o-revisor-so-acha
aprovacao: auto
ddd: n/a
---

# Missão — O revisor só acha

> Escrito pelo `sdd-planner` com o humano presente (grill de 2026-09-01: 5 perguntas, 5 decisões,
> 🚩 vazia; duas restrições ditas pelo humano no meio do caminho viraram as decisões 2 e 3). É a
> única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão headless começa
> lendo estes dois.

## Problema (Gemba)

O M2 fechou (PR #33, `main` = `35863d9`) e o kit está descongelado. A semente que toda missão
recente apontou é a **fase mais cara do pipeline**, e agora o instrumento que a mede é honesto
(desde `20260831-a-rodada-que-andou` uma rodada que pousou `40-review-r<N>.md` lê `advanced`).

**Quanto custa.** No ledger real (`~/.sdd/autonomy-log.jsonl`, 197 linhas, todos os repos):
REVIEW = 27 sessões, **US$ 636,66 = 39,4%** de US$ 1.614,87 — mais que o EXEC (89 sessões,
US$ 542,72). Na janela 2 (`bf001fe`, `sales_quote`), o REVIEW foi 25% · 29% · **60%** de cada
missão (a-tela: US$ 47,81 de 79,00, duas rodadas). Na missão #33 do kit: US$ 66,34 (r1 37,10 em
104 turnos; r2 29,24 em 154).

**Onde o dinheiro vai** (6 rodadas recentes, `.sdd/logs/*/REVIEW-*.json` + `.stream.jsonl`, lidas
turno a turno): US$ 29–37 por rodada, 100–170 turnos, 135–345 chamadas `Bash`, 11–46 execuções da
suíte, 2–5 subagentes, pico de contexto 263–366k tokens e **zero compactações** em qualquer fase.
O laço de **conserto** — tudo depois do primeiro `Edit` — responde por **70–95%** do cache-read da
rodada; achar responde por 5–30%. A saída da suíte é só **1–7%** dos bytes de tool_result (as
sessões já fazem `tail`); o contexto é exploração: `Bash` ≈ 60%, `Read`s de 19–43 KB. Regressão
sobre 28 rodadas (R² 0,36 — ordem de grandeza): cache-read ≈ 30%, cache-creation ≈ 30%,
saída/thinking ≈ 41%; o cache-read cresce com **turnos²** (corr 0,94).

**A causa raiz é um chapéu duplo.** `agents/sdd-reviewer.md § 3` manda o mesmo agente **achar e
consertar na mesma sessão** (`phase_task REVIEW`: *"review and fix, INSIDE this session"*,
`bin/sdd:1517`). Cada conserto carrega a exploração inteira da revisão em cada turno, e a nota A da
r1 é o revisor dando A ao próprio conserto. O kit já tem o desenho certo para isso uma fase antes:
a QA **não conserta** — escreve incrementos `F<n>` no checkpoint e o EXEC conserta
(`agents/sdd-qa.md § 4`; `docs/pipeline.md:16`, *"the QA⇄EXEC loop falls out for free"*).

**O que a rodada compra e não pode perder:** no alvo, 8–12 achados por rodada; a-tela r1 achou
1 CRITICAL + 2 HIGH; condicoes r1, 3 HIGH. A revisão está funcionando — o que se corta é o
contexto carregado, nunca o rigor.

## Métrica

1. **M1 — janela 3, alvo, o que o `sdd kaizen` lê:** parcela do **laço de revisão** por missão
   (sessões REVIEW + sessões EXEC posteriores à primeira linha REVIEW da mesma `(repo, missão)`,
   ÷ custo da missão), impressa por `sdd autonomy --all-repos --by-mission` (campo novo, I1):
   **mediana ≤ 25% e máximo ≤ 50%** nas missões da janela 3 (janela 2: 25 · 29 · 60 → mediana
   29%, máximo 60%). Limite declarado: QA que re-bloqueie depois do REVIEW cai no laço.
2. **M2 — kit, imediato:** a fase REVIEW **desta própria missão** roda o desenho novo. Cada
   sessão REVIEW desta missão **≤ 60 turnos e ≤ US$ 15** (`turns` e `cost_usd` na linha do
   ledger; #33: 104 turnos / US$ 37,10 e 154 / 29,24); o laço de revisão desta missão (REVIEW +
   EXEC `R<n>`) **≤ US$ 40** (#33: US$ 66,34).
3. **M3 — qualidade, invariante:** cada `40-review-r<N>.md` da janela 3 carrega a tabela de
   achados por severidade (8–12 por rodada na janela 2, CRITICAL/HIGH onde houver); o
   `gate_REVIEW` **não muda** (A em toda linha, `Rationale` com frase); o diff de
   `agents/sdd-reviewer.md` **não remove** nenhuma regra de reprodução ou refutação — conferido na
   REVIEW desta missão. Rodada da janela 3 sem achado onde o humano depois achar CRITICAL/HIGH ⇒
   `piorou`, mesmo com custo menor.
4. **M4 — régua reprodutível:** antes/depois no `KAIZEN_LOG.md` com os comandos e as saídas — o
   "antes" nesta missão (I4), o "depois" desta missão preenchido pela fase DOCS a partir do ledger,
   e o veredito da janela 3 pelo `sdd kaizen`.

## Resultado esperado

O `sdd-reviewer` passa a ser **read-only** sobre o código: roda `codereview`, reproduz e refuta
com evidência, escreve `40-review-r<N>.md` com a nota honesta e transforma cada achado a consertar
num incremento `R<n>` do `checkpoint.md`. O `sdd-executor` conserta em TDD numa sessão de
contexto zerado, e a rodada seguinte re-avalia de forma **independente** — o A deixa de ser o
revisor certificando o próprio conserto. Nada muda nos gates, na derivação de fase ou no teto de
rodadas; o que muda é o contrato da sessão REVIEW e entram dois instrumentos (`turns` +
`review loop` no ledger; aviso `REVIEW-EDITED-CODE`). A janela 3 abre no sha do merge desta
missão — a primeira mudança do kit nascida com número atrás.

## Fora de escopo

- **Disciplina de suíte no laço de conserto** — **refutada pelo gemba** (saída de teste = 1–7% do
  contexto); não se faz.
- **Subagentes do revisor em sonnet por padrão** e qualquer redução de rigor — decisão 2.
- **Manter a sessão para a rodada seguinte enquanto o contexto < 50%** — vale para o laço
  interativo do humano (decisão 3); no runner só entra medida, em missão futura, com o `turns`
  do I1 na mão.
- **Mexer em `BUDGET_REVIEW_USD` (40) e `REVIEW_MAX_ITER` (3)** — decisão 9; só o texto da
  justificativa muda (I4).
- **O env-cleanup do `run_phase`** (o `sdd run` aninhado morre: o `claude -p` herda
  `CLAUDE_CODE_CHILD_SESSION`/socket do harness) — achado do planejamento, registrado em
  `01-plano.md § Achados do planejamento`; a fase DOCS o leva ao `TODO.md` com a catraca no mesmo
  diff (registrar no EXEC mataria o carimbo de mutação).
- **Integrar o graphify no pipeline headless** (comando no boot prompt, regra de agente) — parado
  até o ledger de `docs/graphify.md` fechar a janela (D23).
- **JIRA** (decisão 7) e **segundo repo adotante** (decisão 1).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 5 perguntas, 5 decisões + 2 restrições do humano (decisões 1–9 abaixo); `CONTEXT.md` D22/D23 escritas no commit do grill; nenhuma 🚩 nova |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 abaixo, 8/8; DDD `n/a` justificado |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | `01-plano.md § Contexto verificado` carrega cada função, sensor e doc que o I1 toca com `arquivo:linha` e a forma do fixture; o I1 não depende de nada fora dos três arquivos |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 4 de 4, ancorados em `^  ok    ` com herestring, sem `\|` cru; `tests/check-checkpoint.sh` verde |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no kit; o humano decidiu **não** abrir ticket nesta missão (decisão 7) |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | ledger real, 30 JSONs de rodada, 6 streams lidos turno a turno (contagem de ferramentas, bytes por tool_result, cache-read antes/depois do 1º `Edit`), `cmd_run`, `gate_REVIEW`, os dois agentes, os quatro sensores — tudo com `arquivo:linha` no `01-plano.md` |
| K2 | Problema declarado com métrica | ✅ | M1–M4 |
| K3 | Desperdícios identificados e cortados | ✅ | o chapéu duplo do revisor (contexto da revisão carregado em cada turno de conserto); a disciplina de suíte foi **medida e refutada** antes de virar plano |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | I1 instrumento → I2 contrato → I3 guarda → I4 docs; o I1 vale sozinho (o laço passa a ser medido mesmo sem o corte) |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | 4 Checks leem `^  ok    ` de sensores da suíte + `diff -q` do espelho do agente; a verificação E2E lê o ledger, nunca a prosa da sessão |
| K6 | Jidoka — o que para a linha está definido | ✅ | achado que só um humano pode fechar **não** vira `R<n>`: vai às pendências, a nota fica honesta e a linha para como hoje; lote MEDIUM/LOW grande demais para uma sessão → o executor divide e marca `blocked` |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | contrato em `templates/` + agente + `docs/pipeline.md` no **mesmo commit** (I2); mutante por regra nova; `CONTEXT.md` D22 + verbete já escritos |
| K8 | Registro no KAIZEN_LOG | ✅ | I4 escreve o "antes"; a fase DOCS preenche o "depois" desta missão a partir do ledger; a janela 3 dá o veredito |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a mudança é no contrato de uma sessão do runner (o que o revisor
escreve) e em instrumentos do ledger; nenhum aggregate, bounded context, evento ou contrato entre
módulos de negócio.`

## Decisões do grill (não re-litigar)

1. **O problema é o custo do REVIEW** (Q1). Uma mudança por sha — a janela 3 julga o sha desta
   missão —, então atrito operacional (env-cleanup, health longo) não entra no diff, e o segundo
   repo adotante vem depois do corte (cada missão custa US$ 45–80 hoje).
2. **Qualidade não é trade-off** (humano, mid-turn). Mesmo skill `codereview` com o mesmo
   roteamento; `gate_REVIEW` inalterado; regras de reprodução/refutação mantidas; nenhum critério
   removido; subagentes em sonnet **não** é padrão; "reduzir rigor" fora da mesa.
3. **Manter sessão enquanto o contexto < 50% só entra medida** (humano, mid-turn): zero
   compactações em qualquer fase, mas cache-read cresce com turnos² e é ~30% do custo. Vale para
   o laço interativo do humano (`/codereview` até A: várias rodadas na mesma sessão enquanto
   longe de 50%), não para o runner.
4. **Métrica primária = parcela do laço de revisão na missão** (Q2), lida do ledger por
   `(repo, missão)`; D12 (US$ por PR) segue como secundária, de graça.
5. **Alavanca = "REVIEW acha, EXEC conserta"** (Q3) — um chapéu por agente. Estimativa honesta
   declarada: **20–35%** no laço (não 50%); o que o corte compra além do custo é a nota
   independente.
6. **Lote de achados:** CRITICAL e HIGH → um `R<n>` cada (Red próprio, commit isolado,
   reversível); MEDIUM/LOW baratos → **um `R<n>` de lote por rodada** (boot de sessão EXEC custa
   ~US$ 1–2; seis sessões para seis LOW custariam mais que o conserto in-session); MEDIUM/LOW
   caros → `TODO_FILE`; decisão humana → pendências do relatório, sem `R<n>`.
7. **Sem JIRA nesta missão** (Q4): `versao:` vazia; `JIRA_ENABLED=false` satisfaz o critério (e).
8. **Graphify enxuto, no commit do grill** (Q5): zona bash medida antes de escrita, grafo fora do
   git, sem hooks, sem cópia da skill; ledger em inglês em `docs/graphify.md` (D23).
9. **`BUDGET_REVIEW_USD` fica 40 e `REVIEW_MAX_ITER` fica 3**: teto que morde no meio da sessão
   joga dinheiro fora com nada em disco; a distribuição das sessões de achar sai do I1 e decide o
   teto na missão seguinte.

## Pendências para o humano

Nenhuma bloqueia o pipeline. Protocolo pedido pelo humano no planejamento:

- **Executar no Opus, do terminal** (`/model opus`, `/clear`, e `sdd run` fora do Bash tool —
  o `claude -p` aninhado morre; comando pronto em `01-plano.md § Como rodar`).
- **Depois do pipeline:** `qa-report`/`qa-execution` interativos sobre a branch, se quiser
  confirmar os critérios de aceite à mão (no kit o runner só abre `QA:close`), e
  `/codereview:codereview` até A aplicando a decisão 3.
- **Depois do merge:** a janela 3 abre no sha do merge (padrão D19) — 2–3 missões reais do
  `sales_quote`, sem commit na `main` do kit, e então `sdd kaizen`. Retrofit lean da lição bash na
  skill `graphify` do `sales_quote`.
