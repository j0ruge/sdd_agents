---
missao: 20261004-lote-4-a-catraca-zera
titulo: a catraca do backlog do kit zera — os 23 achados saem (16 consertos com sensor, 7 decisões escritas), e o carimbo de mutação deixa de rodar dentro de uma sessão headless
data: 2026-10-04
versao: n/a (JIRA_ENABLED=false)
branch: fix/lote-4-a-catraca-zera
aprovacao: auto
adr: docs/adr/0015-the-stamp-is-not-headless.md
ddd: aplicado
---

# Missão — Lote 4: a catraca zera

> Escrito pelo `sdd-planner` com o humano presente, via a sessão coordenadora, que repassou oito
> perguntas de grill em 2026-10-04: as seis do roteiro e duas que nasceram no meio dele (decisões 7 e 8). É a única fonte da **intenção**; o `01-plano.md` é a fonte do
> **como**. Toda sessão que executar esta missão começa lendo estes dois, mais o `checkpoint.md`.

## Problema (Gemba)

Depois do lote 3 (PR #219, merge `d21f30b`) e do chore pós-merge (PR #220, `fe9441d`), o `TODO.md`
do kit tem **23 achados abertos**: `bash tests/check-todo.sh` → `  ok    23 finding(s), all within
8 lines, carrying anchor + date, every anchor on target`, e `tests/health-baseline.txt` →
`todo-findings 23`. São os 22 itens que a triagem do lote 3 classificou como **decisão de desenho**
(`docs/handoffs/20261003-lote-3-a-catraca-desce/triagem-57.md`) e 1 mecânico nascido no lote 3 (o
`kaizen_reminder`). Sete são de agosto: o núcleo que sobreviveu a todos os lotes porque pedia
decisão humana, não código. Quatro verificadores conferiram os 23 em `fe9441d`:

1. **Nove são fail-open vivos ou de classe**: o sensor ou o chapéu afirma uma medição que ninguém
   faz. Os casos reproduzidos:
   - #141: `docs/plan-only.md` está fora da superfície de idioma, com 10 linhas pt-BR, e o sensor diz
     `0 of 56`.
   - #191: duas âncoras do `TODO.md` estão podres e verdes. `README.md:158` passa por `templates/`,
     e `bin/sdd:1198` passa por `gate_EXEC`, num comentário a 7 linhas, enquanto o símbolo do item
     está em `:1251`.
   - #67: editar `agents/` não move a chave do carimbo, mas o runner lê o chapéu.
   - #129: 22 de 35 `sdd run` do kit carimbaram mais de um `kit_sha` no mesmo processo.
   - #178: o chapéu do TICKET promete uma conferência por `acli` que o gate não faz.
   - #179: um relatório de QA de outra missão conta como desta (reproduzido em fixture).
   - #153: zero linhas no ledger para fases feitas à mão.
   - #194: ≥8 achados de revisão em 4 missões foram criados pelo conserto da rodada anterior.
   - #92: um Check nasceu verde (I7 de `20260918-a-excecao-do-chapeu-e-o-genero-diferido`).
2. **O carimbo de mutação roda dentro de uma sessão headless e antes dos bots** (#142, #198).
   - O `agents/sdd-publisher.md:41-47` manda o publisher rodar `./bin/sdd health` (20–50 min).
   - No PR #196 o health saiu às 18:13 e o CodeRabbit às 18:27, com achado num arquivo da chave. A
     sessão PR vigiava o health num laço `sleep 20`, foi morta de fora (US$ 0,54) e não deixou
     linha no ledger.
   - As 19 sessões PR do kit somam US$ 39,13 e 4,6 h.
   - O carimbo só existe no kit: `has_mutation_catalogue`, `bin/sdd:2311`.
3. **Três premissas estavam erradas e foram corrigidas antes de virar plano:**
   - #179: a direção "blob na ponta" não distingue os dois casos (blobs iguais).
   - #178: o `acli` não pegaria o caso LH-5, porque a issue duplicada estava no sprint ativo.
   - #134: 3 das 7 ADRs antigas têm missão, ligada pelo merge.
4. **A janela do juiz não mede o kit há dias.** `sdd kaizen --series` → `guard:
   missions_after_change 1, floor 3, window_broken true`; a única missão sobre a versão atual é
   do próprio kit.

## Métrica

Fatos binários, todos verificáveis por comando (detalhe no `01-plano.md` § Verificação end-to-end):

1. **Os 7 itens decididos saíram da seção aberta nesta branch** (#88, #130, #155, #109, #180, #218,
   #135), cada um pelo destino da decisão: seção decidida, YAGNI Y7/Y8 do `CONTEXT.md` ou limite
   declarado. A catraca desceu no mesmo diff: `bash tests/check-todo.sh` → `16 finding(s)` ao fim
   do I4, mais N, se nascerem achados (decisão 5 do lote 3, mantida). `tests/health-baseline.txt`
   diz o mesmo número.
2. **Os 16 consertados carregam `RESOLVED by <hash>`**, cada hash ancestral do topo da branch, cada
   um com Red observado pelo motivo certo e sensor durável: probe e, onde é comportamento do runner,
   mutante no `CATALOG` provado com `--only`.
3. **A ADR 0015 está escrita e ligada.** Ela traz `Amends: 0004, 0011, 0013, 0014`, e as quatro
   ganham `Amended by: 0015`. `./bin/sdd adr check` → rc 0 sob `ADR_CHECK=block`, com 0 missões
   sem `adr:` decidido.
4. **Suíte verde** (`bash tests/run-all.sh` → `suite green`) e **um** `sdd health` verde depois da
   revisão dos bots, que dá o carimbo válido para o `gate_PR`.
5. **Depois do merge** (fora da branch, pelo humano): o chore apaga os 16 e a catraca vai a **0 + N**;
   o espelho de issues é re-sincronizado. Saldo declarado no PR: "23 → 0 + N nascidos".

## Resultado esperado

O backlog do kit fica vazio de dívida antiga: só sobra o que nascer nesta leva. Os nove fail-open
fecham com sensor, e as sete saídas sem conserto ficam onde a próxima sessão as encontra. O `sdd run`
deixa de pedir a uma sessão de LLM que vigie 40 minutos de catálogo: ele para no carimbo, e o humano
carimba uma vez depois dos bots. A âncora do `TODO.md` passa a medir o símbolo que o item designa,
e a régua de idioma lê `docs/` por censo, sem número escrito à mão. O repo do kit passa a
`ADR_CHECK=block`.

## Fora de escopo

- **Casos legados presos nos checkpoints antigos.** Ficam como estão, porque handoff fechado não se
  reescreve (decidido no #137):
  - o I6 `pending` de `20260918-a-excecao-do-chapeu-e-o-genero-diferido`;
  - os I1–I3 `blocked` de `sales_quote/20260825-cif-forma-pagamento`;
  - o I5 do LH-3.

  A regra nova do commit de registro (I2) vale daqui para a frente.
- **Yokoten nos repos-alvo** — passo do humano, listado em § Pendências: os espelhos do chapéu do
  TICKET e do publisher, o `TEST_CMD` com o lint do `TODO.md`, e os templates.
- **O token `waiting` do checkpoint** — adiado como YAGNI Y8, com o evento que o reabre (decisão 2).
- **Dividir o `docs/pipeline.md`** — decidido no #130, com o evento que o reabre.
- **Gaveta: F1-P1/P3/P4, F6 (worker), F7 (Astra), a T3** — a T3 encolhe nesta leva: o #6 sai pelo
  I17–I19, e a "T5" sai decidida no I1.
- **Congelar o kit para a janela do juiz** — decisão humana depois do merge (§ Pendências).
- **Achado nascido no meio da leva** — passa pela régua D15 e vai ao `TODO.md` com catraca +1 no
  mesmo commit; não é consertado aqui. Defeito criado pela própria leva se conserta nela.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | As 8 perguntas foram respondidas pelo humano, via relay (§ Decisões do grill, 1–8). A missão não abriu nenhum 🚩. As pendências têm dono, o humano: o momento do health; merge, chore e re-sync; yokoten e retrofit da skill; congelar o kit; preservar protótipos. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 todos ✅, com evidência na tabela abaixo. DDD acionado (evento `manual`, campo `runner_sha`, posse do relatório de QA), com D1–D6 ✅. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Um subagente sem memória leu só os 3 arquivos e o código (clone `fe9441d` + passo 0) e testou I1, I6, I13 e I21. Veredito: "sim, com ressalvas". As ressalvas foram fechadas no plano: (1) a única bloqueante era o `n_surface` do I21, que o texto mandava apagar; (2) as decisões 7 e 8 entraram no 00; (3) o fallback do passo 0 sem `auto`; (4) o fluxo de cada incremento; (5) a anatomia no mesmo commit, numa tabela; (6) as âncoras medidas antes do I5, com uma regra explícita; (7) os ajudantes de fora do repo, com o caminho à mão. Ele conferiu ~40 fatos citados, e ~37 bateram; os 3 que não bateram eram números de protótipo, e o texto foi corrigido. Custo que sobra, declarado: o código do censo do I21 é especificação mais protótipo opcional. |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 24 de 24 linhas com Check na forma estrita. `tests/check-checkpoint.sh --check` → `24 row(s), 21 under the anchor rule, none blind`. O protótipo do `--red` (I7) sobre `fe9441d` + passo 0 deu `24 pending Check(s), every one red at HEAD` (754 s), com o "antes" de cada um igual ao da seção. O Check do I21, mudado depois da varredura, foi re-medido: `0 0 0 1 0 1 1`, contra o esperado `0 1 1 1 1 0 0`. |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`), `versao: n/a`. |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: docs/adr/0015-the-stamp-is-not-headless.md`, alocada por `sdd adr new` (decisão 6), com o corpo escrito (§1–§4 e as descartadas). `./bin/sdd adr check --mission 20261004-lote-4-a-catraca-zera --phase plan` → `ok … and that ADR points back`, rc 0. |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | **4 verificadores** conferiram os 23 itens em `fe9441d`, reproduzindo: #141 (`docs/plan-only.md`), #191 (2 âncoras podres e verdes), #179 (fixture), o `kaizen_reminder` (2 FAIL), #67 (chave igual depois de editar `agents/`) e #129 (22 de 35 runs). Três premissas foram refutadas antes do plano: #179, #178 e #134. **5 designers** prototiparam cada incremento num clone de `fe9441d`, com o Red medido antes do conserto e o verde depois, e a suíte rodou inteira no topo de cada protótipo. |
| K2 | Problema declarado com métrica | ✅ | Catraca 23 → 16 + N na branch → 0 + N depois do chore. 16 `RESOLVED by` com sensor; ADR 0015 ligada e `ADR_CHECK=block` com rc 0; suíte verde e um carimbo. Tudo por comando (§ Métrica). |
| K3 | Desperdícios identificados e cortados | ✅ | **Superprocessamento:** 7 itens saem sem código; o `--red` fica fora do `run-all.sh`; alcance 2 recusado (+7% de re-ancoragem); re-exec recusado; o caminho estreito "só hunk de comentário" recusado. **Espera:** o carimbo sai da sessão headless (US$ 39,13 e 4,6 h medidos); um `sdd health` só, depois dos bots. **Custo:** `agents/` na chave custa 0 health em 30 merges, contra 14 com os outros quatro caminhos; execução interativa. **Defeito:** protótipos antes do plano. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 24 incrementos de uma sessão cada. Um item por incremento, ou um item em 2–3 (#92, #142/#198, #129, #153, #108). O I5 é um commit só porque a regra entra obrigatória. Cada um tem o Red medido no protótipo, com o "antes" anotado na seção. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem a linha `^  ok    ` do sensor (herestring) ou o arquivo via `awk`. `tests/check-checkpoint.sh --check` → `24 row(s), 21 under the anchor rule, none blind`. Os mutantes são provados com `--only`. A varredura de Red está no critério d. |
| K6 | Jidoka — o que para a linha está definido | ✅ | Sensor vermelho para o commit. Âncora deslocada para o commit (`check-todo.sh` no `TEST_CMD`). Mutante que não aplica para o commit (`--anchors`). Defeito criado pela leva se conserta nela. O carimbo só nasce verde. O próprio produto da leva também para a linha no ponto certo: o `sdd run` para no carimbo. |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Todo conserto entra com probe durável, e com mutante quando é `bin/`. As regras novas de chapéu têm probe no `check-hat.sh` e espelho sincronizado. ADR 0015; verbetes no `CONTEXT.md` (I24); saídas decididas, Y7 e Y8. Os pisos e a lista de lugares do `CLAUDE.md` são atualizados. |
| K8 | Registro no KAIZEN_LOG | ✅ | Planejado no I24, cujo Check exige a entrada `— Lote 4: a catraca zera` no `KAIZEN_LOG.md`, com o antes já medido e listado no incremento. |

## Checklist DDD (`ddd`) — condicional

Acionado, e não `n/a`. A leva acrescenta um evento ao ledger de autonomia, o contrato publicado
entre o runner que escreve e os dois contextos que leem (a visão humana do `sdd autonomy` e o juiz
do `sdd kaizen`). Também acrescenta um campo a toda linha desse ledger e muda o que conta como
relatório de QA de uma missão. O enum de status do checkpoint foi avaliado e **não** muda
(decisão 2).

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | **Fase feita à mão:** evento `manual` do ledger, escrito por `sdd note-manual <missão> <fase>`. **Retrato de lançamento** (`runner_sha`): o runner que escreveu a linha, tirado uma vez por processo, contra o `kit_sha` lido do disco. **Commit de registro:** o commit que traz a evidência de um ato fora do git. **Símbolo designado:** o slot `` (`<símbolo>`) `` do item do `TODO.md`. **Censo de superfície:** todo `docs/**/*.md` rastreado está na régua ou numa subárvore declarada. **O carimbo não é headless:** quem carimba é o operador, depois dos bots. Entram no `CONTEXT.md` no I24 |
| D2 | Fronteira do contexto | ✅ | O evento `manual` é **visto** pela visão humana (`cmd_autonomy`) e **admitido sem pontuar** pelo juiz (`kaizen_series`): ele não é sessão, nem escalada, e não cunha versão. A guarda do kit e o carimbo não leem o ledger. O discriminador do relatório de QA fica dentro de `mission_qa_report`; os dois consumidores (`gate_QA`, `gate_PR`) não mudam |
| D3 | Invariante | ✅ | (i) Uma linha `manual` nunca muda veredito, versão nem `degenerate_axis`: o par diferencial com e sem a linha dá a mesma série. (ii) O predicado de admissão se escreve **positivamente**, e o evento entra pela definição única de cada programa (regra do `CLAUDE.md`). (iii) O `runner_sha` é constante por `run_id`. (iv) Reler o config entre voltas nunca troca o código em execução, e um config quebrado falha fechado antes de abrir sessão. (v) Nenhum commit da leva deixa o escritor emitir um evento que algum leitor ainda não reconhece |
| D4 | Eventos | ✅ | Um evento novo, `manual`, o 6º (`session`, `blocked`, `degraded`, `gate_pass`, `close`). O nome segue o vocabulário publicado do ledger, que é de substantivos (`session`, `close`), e não o passado perfeito da literatura [Domain Events catalog: Naming]: a consistência da Published Language vence. Um campo aditivo, `runner_sha`, que os leitores leem com `has()`; a regra é acrescentar campo com default, nunca mudar a semântica do campo existente [Domain Events catalog: Schema evolution] |
| D5 | Contrato entre módulos | ✅ | O `docs/pipeline.md` (enum de eventos e referência de campos do ledger) muda no mesmo commit do escritor. Os dois leitores aprendem `manual` no mesmo incremento, ou antes do escritor, com probes diferenciais em `check-autonomy.sh` e `check-kaizen.sh` e um mutante por leitor [Evans Reference: Published Language] |
| D6 | Decisão registrada | ✅ | ADR 0015, para o carimbo, a âncora, o relatório e a superfície (`Amends: 0004, 0011, 0013, 0014`). O evento `manual` entra sem ADR, pelo precedente do `gate_pass` (`715da79`) e do `close` (`aa3c0a2`): é admitido pelos dois leitores e nunca pontua (decisão 3) |

## Decisões do grill (não re-litigar)

1. **Escopo: os 23 itens, numa leva final do "zerar".** Cada um sai por conserto com sensor ou
   por decisão escrita (seção decidida, YAGNI com o evento que reabre, limite declarado); o grill
   foi feito em quatro pacotes temáticos. — Porquê: é a decisão 1 do lote 3 ("zerar a catraca em
   levas"), a triagem já tinha medido as opções, e decisão escrita custa só texto. (humano,
   "Os 23 itens (Recomendado)", 2026-10-04)
2. **Pacote 1, o contrato do checkpoint e do plano, aceito como está.** (humano, 2026-10-04)
   - **#92:** modo `tests/check-checkpoint.sh --red <checkpoint>`, que o planner roda antes de
     fechar o PLAN-AUTO, mais a regra de redação de Check prometida no decidido #93. Fica fora do
     `run-all.sh`. O `gate_PLAN` **não** roda Check, porque giraria a linha: o `derive_phase` o chama
     sempre, e com o I1 `done` a missão voltaria para PLAN.
   - **#180+#218:** sem token novo. Ato fora do git deixa um **commit de registro**, e passo
     pós-merge ou de janela externa sai do checkpoint para § Pendências ou para a missão seguinte. O
     token `waiting` fica adiado (Y8). — Porquê: os 4 casos reais têm 4 semânticas, nenhum token
     cobre todos, e a falha de hoje é fechada e alta.
   - **#95:** o `config/starter.conf` e o `config/schema.md` sugerem anexar o
     `check-todo.sh --check "$TODO_FILE" --baseline "origin/$DEFAULT_BRANCH"` ao `TEST_CMD` do alvo.
     É opt-in, e verde hoje nos 3 alvos.
   - **#134:** o mapeamento foi confirmado pelo humano: 0003 → `20260817-eixo-do-juiz`, 0004 →
     `20260819-fecho-que-nao-mente`, 0006 → `20260826-o-laco-da-qa`. As outras 11 missões levam
     `adr: none`, e 0001, 0002, 0005 e 0007 ficam sem `Spec:` (limite declarado). Este repo passa a
     `ADR_CHECK=block`.
3. **Pacote 2, o carimbo, a fase PR e o estado do runner, aceito como está.** (humano, 2026-10-04)
   - **#142+#198:** "o carimbo não é headless" (ADR 0015 §1). O `gate_PR` não muda. Quando a única
     recusa é o carimbo, o `sdd run` sai com rc 2 sem abrir sessão, e o publisher só abre o PR.
   - **#67:** `agents/` entra na chave. `docs/adr`, `CLAUDE.md` e `TODO.md` ficam fora, declarados.
   - **#129:** o config é relido no topo de cada volta, e cada linha do ledger ganha o campo
     aditivo `runner_sha`. Re-exec entre voltas está recusado: o código não revisado da missão
     julgaria a própria REVIEW.
   - **#88:** YAGNI Y7.
   - **#153:** `sdd note-manual <missão> <fase>` escreve a nota `intervention:` e um 6º evento,
     `manual`, que não pontua; o `sdd status` sugere o comando. Sem ADR, pelo precedente.
4. **Pacote 3, os sensores que medem sensor e os docs, aceito como está.** (humano, 2026-10-04)
   - **#141+#108:** glob `docs/*.md` mais censo, com as subárvores declaradas `handoffs`, `qa` e
     `superpowers`. O bloco pt-BR sai de `docs/plan-only.md`, e o piso do `check-lang` passa a ser
     derivado. Os outros pisos ganham limite declarado, e o `CALIBRATE_FLOOR` entra na lista do
     `CLAUDE.md` (ADR 0015 §4).
   - **#191:** símbolo designado obrigatório. Nos alvos entra via `--baseline` (ADR 0015 §2).
   - **#109:** decidido: a DOCS é dona da prosa de contrato, com limite no cabeçalho do
     `check-templates.sh`.
   - **#98:** sensor de chave no `check-kaizen.sh`, sobre o bloco `<!-- sdd:series-fields -->`.
   - **#130:** decidido, com o evento que o reabre.
5. **Pacote 4, a revisão como evidência e as promessas dos chapéus, aceito como está.** (humano,
   2026-10-04)
   - **#194:** o executor sabota a linha nova de um `R<n>`, e o `R<n>` de prosa relê o parágrafo.
   - **#155:** decidido como limite declarado (anatomia §4). A "T5" sai da T3.
   - **#135:** decidido, mais uma frase no `sdd-docs` § `⛔`: comentário de código é do código.
   - **#178:** o chapéu do TICKET para de prometer o `acli`.
   - **#179:** discriminador pelo diretório da missão (ADR 0015 §3).
   - **`kaizen_reminder`:** espelha o `188ca87`.
6. **Logística.** (humano, "Interativa + ADR 0015 (Recomendado)", 2026-10-04)
   - **Execução interativa,** como os lotes 1–3: uma sessão executa incremento a incremento, com o
     checkpoint como trilha. Depois vêm o PR, a espera de **todos** os bots, os consertos numa leva,
     **um** `sdd health` e o merge pelo humano. **Não** é `sdd run`.
   - **Nomes:** missão `20261004-lote-4-a-catraca-zera`, branch `fix/lote-4-a-catraca-zera`
     cortada de `origin/main`.
   - **ADR:** uma só, nova, a 0015, alocada por `sdd adr new`, com `Amends: 0004, 0011, 0013, 0014`.
   - Porquê: modo provado três vezes, e o padrão de emenda da casa é a ADR nova (0009 → 0006,
     0014 → 0003). A missão declara um `adr:` só. A fase PR e o espelho `.claude/` mudam dentro
     da própria leva, o que um `sdd run` desta missão atravessaria.
7. **I6: o `/sdd-plan` pede a aprovação com uma pergunta YES/NO e roda o `sdd approve`.** Com
   `aprovacao:` vazia, o comando pergunta pela ferramenta de pergunta do harness, citando o critério
   ✗ e a branch atual. YES roda `printf 'y\n' | sdd approve <missão>`; NO para; com `auto`, só
   informa. Só a resposta do humano a essa pergunta aprova. — Porquê: é pedido do humano, feito no
   meio do grill ("coloca ai como melhoria, esse sdd approve … deveria vir no claude code com um
   YES , NO no final e resolveri aminha permissao dentro do harness"). O `sdd approve` lê o `y` do
   stdin sem exigir TTY e nunca soube quem o digitou, então a garantia mora no comando, com probe.
   (humano, "Entra como I6 (Recomendado)", 2026-10-04)
8. **`commands/*.md` entra na régua de idioma no I21**, com a mensagem pt-BR das linhas 18–20 do
   `commands/sdd-plan.md` traduzida e o `CLAUDE.md` § Idioma listando `commands/`. — Porquê: é a
   mesma classe do #141, achada pelo designer do I21; custa um padrão e três linhas, e mantém o
   "zera" sem item novo. (humano, "Entra no I21 (Recomendado)", 2026-10-04)

## Pendências para o humano

- **O momento do `sdd health`:** depois de todos os bots, uma vez (decisão 6). Quem dispara é o
  humano (~40–50 min com ~600 mutantes; lançador desanexado).
- **Merge do PR e, depois dele, o chore pós-merge e o re-sync do espelho de issues** (`01-plano.md`
  § Depois do checkpoint): os 16 `RESOLVED by` saem, a catraca vai a 0 + N, e as 7 saídas
  decididas fecham à mão como "not planned".
- **Yokoten nos repos-alvo** (`sales_quote`, `lighthouse_project`, `ui24-agent`):
  - re-sincronizar os espelhos `.claude/agents/`: o chapéu do TICKET deixa de prometer o `acli`, e
    publisher, executor, docs e planner mudam (I2–I4, I8, I14);
  - anexar o lint do `TODO.md` ao `TEST_CMD`, se quiser (opt-in, #95);
  - adotar o slot de símbolo nos itens novos;
  - fazer o retrofit da skill `todo-to-github-issues` no marketplace, fora do kit: o `SKILL.md:124`
    descreve a regra antiga da âncora, e a skill roda `--check` sem `--baseline`.
- **Congelar ou não o kit para a janela do juiz depois do merge:** esta leva muda `bin/` e cunha um
  `kit_rev` novo.
- **Preservar os protótipos, se quiser:** os patches dos designers estão no scratchpad do
  planejamento (`01-plano.md` § Fatos que atravessam incrementos). São opcionais, e o plano é a fonte.
