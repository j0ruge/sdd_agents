---
missao: 20260928-os-achados-da-janela
titulo: A QA fecha com o relatório da própria missão, o app errado tem nome, a DOCS propõe o que o harness recusa, o close traz a base e o Python recusado diz por quê
data: 2026-09-28
versao:
branch: fix/os-achados-da-janela
aprovacao:
adr: docs/adr/0013-o-relatorio-da-missao-e-o-texto-proposto.md
ddd: aplicado
---

# Missão — os achados da janela do juiz

> Escrito pelo `sdd-planner` com o humano presente (grill de 2026-09-28, sete perguntas, todas
> respondidas). É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**.
>
> O plano nasceu do `sdd kaizen` (o `05-verdict.md` ao lado é o veredito `melhorou` sobre
> `4fd0f31`) e foi **replanejado** com o humano na sala: escopo, critérios e branch mudaram. Por
> ter nascido do kaizen, `aprovacao:` fica vazio mesmo com o gate todo ✅ — o `gate_PLAN` recusa
> `auto` ao lado de um veredito, e quem fecha é o humano com `sdd approve`.

## Problema (Gemba)

A janela do juiz (3 missões sobre `4fd0f31`: LH-4 no `lighthouse_project`, SQ-145 e SQ-146 no
`sales_quote`) deixou oito achados `kit:` medidos. O grill escolheu **consertar cinco** — os que
custaram sessão, humano ou uma fase inteira na janela e cabem sem reverter ADR — e **registrar três**.

Os cinco consertados, verificados nesta sessão (`bin/sdd` em `038a314`, idêntico a `4fd0f31`):

- **Achado 4 — a QA fecha com o relatório de OUTRA missão (fail-open).** `qa_substep`
  (`bin/sdd:1873`) e a Âncora 1 do `gate_QA` (`bin/sdd:1161`) escolhem
  `latest_matching "$qa/reports/*.md"`, e nada amarra o arquivo à missão. Na SQ-146
  (`20260928-ver-vira-olho-na-lista`) o mais recente era o `2026-09-25-sq143-alcada-diretoria.md`,
  o sub-passo respondeu `close` e as skills de QA **não rodaram**. Na LH-4 o `gate:` do
  `30-handoff-qa.md` diz com todas as letras: "Relatório datado mais recente … 2026-09-22-i14-release-0-1-0.md
  … as skills qa-report/qa-execution não rodaram nesta missão". Já é item aberto do `TODO.md`
  (`gate_QA aceita relatório de QA de OUTRA missão`, de 2026-08-27).
- **Achado 7 — o `sdd close` volta à base sem trazer o merge.** `close_return_home`
  (`bin/sdd:9877`) só faz `git checkout "$DEFAULT_BRANCH"`. Na SQ-145 a `develop` local ficou atrás
  do PR recém-mergeado; na SQ-146 a sessão do close rodou `git pull` por conta própria. Não é
  determinístico, e a missão seguinte nasce sobre base velha.
- **Achado 8 — o `CHECKOUT-UNAVAILABLE` não diz o que caiu.** `COORDINATION_PYTHON=(python3 -I -S)`
  (`bin/sdd:9718`) é o primeiro `python3` do `PATH`; no terminal do humano, o CPython 3.11 do venv do
  hermes (build do `uv`, sem `os.pidfd_open`), enquanto o `/usr/bin/python3` 3.12 serve. A recusa
  (`bin/sdd-coordination.py:430-437`) lista todos os requisitos e cola o erro cru; o `die` do
  `bin/sdd:9754` idem. Todo comando coordenado parou, e o humano diagnosticou à mão.
- **Achado 3 — o preflight aprova o app de outro produto (fail-open).** `app_probe`
  (`bin/sdd:657`) só faz connect TCP; o preflight imprime `ok "something is listening at … (APP_URL)"`
  (`bin/sdd:4864`). Os dois produtos usam `APP_URL="http://localhost:5173"`. Na LH-4 a sessão de QA
  das 18:40 abriu, achou o `dev.sh` do `sales_quote` (`<title>JRC Sales Quote`) e parou `blocked`.
- **Achado 6 — a DOCS contorna pelo Bash a negativa do harness em `.claude/rules/`.**
  `agents/sdd-docs.md:9` declara `.claude/rules/**` no `writes:`; o `claude -p` headless nega
  `Edit`/`Write` em `.claude/` (caminho sensível). Na SQ-145 e na SQ-146 a sessão escreveu o
  `.claude/rules/techspec.md` com `python3` pelo Bash (streams `DOCS-20260927-190735-f56b8aca` e
  `DOCS-20260928-091239-822e7bf8`), e o `hat_guard_check` aceitou porque o caminho está no `writes:`.
  Na LH-4 a sessão não contornou, deixou `⛔` com texto proposto, e o `gate_DOCS` (`bin/sdd:1560`)
  reprova todo Status que não seja `✅`/`n/a` — sem saída, a fase giraria até o `no-progress`; o
  humano aplicou o texto à mão em `eacbc45`.

Os três registrados (não consertados): **1** (a célula Commit não tem grafia para incremento cujo
produto não é commit — LH-3, anterior à janela, falha fechado), **2** (`gate_TICKET` só lê o
frontmatter — latente, a LH-4 se defendeu com Check próprio), **5** (a Âncora 3 conta bug legado
de outra missão — reverter o escopo exige ADR que supere a alternativa (A) da ADR 0006, mantida
pela 0009).

## Métrica

Seis fatos binários, cada um com sensor na suíte:

1. Num fixture em que o único relatório `closed` foi **adicionado antes** da branch da missão, o
   `qa_substep` responde `exec` (não `close`) e o `gate_QA` reprova com motivo que diz que o
   relatório é de antes da branch. Hoje: `close` e aprova.
2. Num fixture de `sdd close` com a `DEFAULT_BRANCH` local **atrás** do upstream, ela termina
   **igual** ao upstream; divergida, termina com o sha intacto e um aviso. Hoje: fica atrás.
3. Com um `python3` sem `os.pidfd_open` primeiro no `PATH`, a recusa `CHECKOUT-UNAVAILABLE` nomeia
   o requisito (`pidfd_open`), o interpretador resolvido e o remédio. Hoje: a lista genérica.
4. Com `APP_EXPECT` declarado e ausente da página da `APP_URL`, o preflight reprova (com
   `E2E_CMD`) e o `gate_QA` com e2e vermelho nomeia o app errado. Hoje: "something is listening".
5. Uma sessão DOCS que escreve em `.claude/rules/` para a linha com `hat-crossed`; uma linha `⛔`
   com a seção de texto proposto passa no `gate_DOCS` **nomeada** no motivo. Hoje: o contorno passa
   calado e o `⛔` honesto não tem saída.
6. `bash tests/check-todo.sh --count TODO.md` → `86` e `tests/health-baseline.txt` com
   `todo-findings 86` (83 + os três registrados).

## Resultado esperado

A QA de uma missão só fecha com a QA **dela**: o fail-open aberto desde 2026-08-27, que repetiu em
duas das três missões da janela, deixa de comprar um verde com o relatório do vizinho, e as skills
de QA voltam a rodar. O preflight e o gate de QA sabem dizer "responde, mas não é este produto". A
DOCS deixa de passar por cima da proteção do harness: o que ela não pode escrever vira texto
proposto no PR, e o humano aplica onde já está. O `sdd close` entrega a base em dia, e quem cai no
`CHECKOUT-UNAVAILABLE` lê qual Python foi recusado e o comando que resolve. Os três achados que
ficaram de fora moram no `TODO.md` com âncora e dono.

## Fora de escopo

- **Achados 1, 2 e 5** — registrados no `TODO.md` pelo I1, não consertados. O 5 com a direção
  "missão própria com ADR que supere a alternativa (A) da ADR 0006, mantida pela 0009".
- **Recuo automático para outro Python** (achado 8): o runner nunca usa o `/usr/bin/python3`; só o
  sonda para escrever o remédio (decisão 3 do grill).
- **Parada antes da sessão de QA por app errado** (achado 3): o `wrong` vale no preflight e no
  `gate_QA` depois de e2e vermelho; porta nova no laço do `cmd_run` ficou de fora (decisão 5).
- **Conceder ao harness permissão em `.claude/rules/`** (achado 6): recusado (decisão 4).
- **O charter de QA** continua escolhido como hoje (existência = árvore inicializada): é doc viva
  que atravessa ciclos (decisão 2, pelo Gemba).
- Passos humanos pós-merge: `sdd install --force` em cada alvo (espelho do `sdd-docs` e do
  `sdd-publisher`), tirar o `DISABLE_AUTOUPDATER` (depende do PR do veredito, não desta missão),
  espelhar o `TODO.md` em issues.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Mesmo todo ✅, `aprovacao` fica **vazio**: o
`05-verdict.md` ao lado marca plano nascido do `sdd kaizen`, e o `gate_PLAN` recusa `auto` ali. O
humano fecha com `sdd approve 20260928-os-achados-da-janela`.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | sete perguntas respondidas pelo humano (escopo, pertença do relatório, Python, close, DOCS, app, branch) — "Decisões do grill"; as pendências abaixo são passos pós-merge com dono humano |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 e D1–D6 abaixo |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | leitura fria por sessão sem memória desta conversa, só com os três arquivos (nota no `checkpoint-notas.md`) |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 7 de 7, nenhum pipe cru, âncora `^  ok    ` onde o Check lê sensor (`tests/check-checkpoint.sh` verde) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` do kit; `versao:` vazio |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | ADR 0013, alocada por `sdd adr new` nesta sessão: as duas decisões de contrato (pertença do relatório; `⛔` com texto proposto) |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `bin/sdd`, `bin/sdd-coordination.py`, sensores, ADRs 0006/0009/0012, skills `qa-report`/`qa-execution` e os handoffs da LH-4 lidos nesta sessão; âncoras no `01-plano.md` |
| K2 | Problema declarado com métrica | ✅ | seis fatos binários, cada um com asserção nomeada |
| K3 | Desperdícios identificados e cortados | ✅ | fase QA pulada com relatório alheio; sessão de QA contra o app errado; DOCS girando num `⛔` sem saída; base velha depois do close; humano diagnosticando Python à mão. Cortado do escopo o que não teve dano medido (1, 2) e o que exigia reverter ADR (5) |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 7 incrementos, um defeito cada; o I1 (backlog) vem antes do código para a catraca mover num diff próprio |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | todo Check lê a linha `^  ok    ` do sensor, nunca a asserção solta |
| K6 | Jidoka — o que para a linha está definido | ✅ | sensor vermelho para; `check-mutation.sh --anchors` antes de cada commit de código; `sdd health` carimba antes do PR |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | poka-yoke onde coube: o corte no `writes:` torna o contorno da DOCS um `hat-crossed` (não uma frase); asserções nos sensores + mutantes no catálogo; contrato em três lugares no mesmo commit |
| K8 | Registro no KAIZEN_LOG | ✅ | I7 |

## Checklist DDD (`ddd`) — condicional

Acionado, e não `n/a`: a missão introduz um conceito ("o relatório **da** missão"), um estado novo
num contrato lido por dois chamadores (`wrong` no `app_probe`) e muda o contrato entre três fases
(DOCS escreve o `⛔`, o `gate_DOCS` o admite, o PR o carrega).

| # | Item | Status | Nota |
|---|---|---|---|
| D1 | Linguagem ubíqua nomeada | ✅ | **relatório da missão** (adicionado em `merge-base(DEFAULT_BRANCH, HEAD)..HEAD`, ou novo na árvore); **range vazio** (HEAD alcançável da base: missão na base ou já mergeada ⇒ resposta de hoje); **app errado** (`wrong`: algo responde na `APP_URL`, mas sem `APP_EXPECT` na página); **texto proposto** (seção do `45-docs.md` sob o marcador `<!-- sdd:proposed -->`). Os quatro entram no `CONTEXT.md` no I7 [Evans Reference: Ubiquitous Language] |
| D2 | Fronteira do contexto | ✅ | O runner decide a pertença pelo git (artefato), nunca pelo nome do arquivo, que é da skill de terceiro. A árvore `docs/qa/` continua das skills; o kit só **lê**. O `.claude/rules/` passa a ser do humano (o harness já dizia isso; o `writes:` passa a concordar) |
| D3 | Invariante | ✅ | (i) a Âncora 1 e o `qa_substep` respondem sobre o **mesmo** arquivo (uma função, dois leitores); (ii) range vazio nunca muda a resposta de hoje; (iii) o `wrong` só nasce com `APP_EXPECT` declarado e connect `up` — o probe continua unilateral (nunca verde → vermelho por falta de ferramenta); (iv) `⛔` só passa com o marcador de texto proposto |
| D4 | Eventos | ✅ | Nenhum `event` nem `kind` novo no ledger: o app errado arma o `GATE_APP_DOWN` que já existe (`kind: app-down`, com motivo próprio); o contorno da DOCS sai pelo `hat-crossed` que já existe |
| D5 | Contrato entre módulos | ✅ | `docs/pipeline.md` (Âncora 1 do QA, `sdd close`, DOCS, coluna `kind` do `app-down`), `config/schema.md` + `config/starter.conf` (`APP_EXPECT`), `agents/sdd-docs.md`, `agents/sdd-publisher.md`, `templates/pr-body.md` — cada um no mesmo commit do código que o muda [Evans Reference: Published Language] |
| D6 | Decisão registrada | ✅ | ADR 0013 (as duas decisões de contrato, com as alternativas descartadas no grill) |

## Decisões do grill (não re-litigar)

1. **Escopo B: conserta 3, 4, 6, 7 e 8; registra 1, 2 e 5.** Critério do humano ("o que incomodou
   o fluxo, e bugs"): os cinco custaram sessão, humano ou uma fase na janela; 1 e 2 não têm dano
   medido na janela; 5 esbarra na ADR 0006 (alternativa A) mantida pela 0009.
2. **Pertença do relatório (achado 4): merge-base com recuo.** Pertence se foi **adicionado**
   (`--diff-filter=A`, não modificado) em `git merge-base "$DEFAULT_BRANCH" HEAD..HEAD`, ou está novo
   na árvore; range vazio ⇒ comportamento de hoje. Por quê: pega as duas recorrências, não faz
   missão mergeada regredir para QA, e o fixture de QA atual (na base) segue verde. Resíduo
   declarado: missão cuja `branch:` é a própria base. Descartados: merge-base puro (missão mergeada
   volta a QA e um `sdd run` sobre ela gasta sessão), data no nome (falha aberto em missões
   sobrepostas), descendência do commit do plano (falha aberto com plano commitado antes do merge
   da anterior).
3. **O charter não segue o critério** (decidido pelo Gemba, sem pergunta): é doc durável que
   atravessa ciclos (`~/.claude/skills/qa-report/references/qa-docs-layout.md:54`), e a
   `qa-execution` recorta pelo diff e escreve o charter que faltar. Exigir charter da missão
   tornaria o `QA:plan` insatisfazível num ciclo que reusa charters.
4. **Python (achado 8): diagnóstico com remédio sondado.** A recusa nomeia o requisito, o
   `command -v python3` (bash), o `sys.executable` e a versão (helper); o `bin/sdd` sonda o
   `/usr/bin/python3` só para escrever `PATH=/usr/bin:$PATH sdd …` quando ele serve. O runner
   **nunca** usa esse interpretador; os quatro probes do mundo sem pidfd ficam como estão.
5. **Close (achado 7): fetch + `merge --ff-only @{upstream}`, avisa na falha.** Na base, árvore
   limpa, inclusive quando a sessão já estava nela; `GIT_TERMINAL_PROMPT=0` e tempo limitado; sem
   rede, sem upstream ou divergida ⇒ `warn`, nunca `die`; o `ok` diz se houve fast-forward.
6. **DOCS (achado 6): fronteira + pendência nomeada no PR.** `.claude/rules/**` sai do `writes:` do
   `sdd-docs` (o `.claude/agents/**` e a rota `sdd install --force` ficam); o `hat-crossed` é o
   sensor do contorno; `⛔` com a seção de texto proposto passa no `gate_DOCS` em voz alta; o
   `sdd-publisher` leva o texto às pendências do PR; o humano aplica no PR. Descartados: parar a
   linha (toda missão do `sales_quote` pararia), permissão explícita (não verificada e dá a um
   agente headless poder sobre as regras de toda sessão futura), só a frase (sem sensor).
7. **App (achado 3): `APP_EXPECT` no `app_probe`, pelos dois chamadores.** Texto literal procurado
   no corpo de um `GET` à `APP_URL` (`curl`, `APP_PROBE_TIMEOUT`); vazio ⇒ hoje byte a byte; sem
   `curl` ⇒ `unknown`. Estado novo `wrong`: preflight `_fail` com `E2E_CMD` e `warn` sem; `gate_QA`
   com e2e vermelho arma o `GATE_APP_DOWN` existente com motivo próprio, sem porta nova. Resíduo
   declarado: preflight pulado ⇒ a primeira sessão de QA ainda abre.
8. **ADR 0013** com as decisões 2 e 6 (as de contrato entre fases), alocada por `sdd adr new`.
9. **Branch `fix/os-achados-da-janela`, nascida da `main`** depois que o PR só de docs da
   `kaizen/o-veredito-da-janela-do-juiz` (veredito + este plano + ADR 0013) for mergeado. Diretório
   `20260928-os-achados-da-janela` reaproveitado, editado em lugar.

## Pendências para o humano

1. **Antes do `sdd run`:** mergear o PR só de docs da `kaizen/o-veredito-da-janela-do-juiz` (não
   re-carimba: `bin/ tests/ templates/ config/` não mudam), fazer checkout da `main` atualizada e
   rodar `sdd approve 20260928-os-achados-da-janela`. O approve **commita na branch corrente**:
   aprove já sobre a `fix/os-achados-da-janela` (crie-a da `main`) ou aceite o aviso de base branch.
2. **Depois do merge desta missão:** `sdd install --force` em cada alvo (`sales_quote`,
   `lighthouse_project`) para o espelho novo do `sdd-docs`/`sdd-publisher`; declarar `APP_EXPECT`
   no `.sdd/config.sh` de cada alvo que divide porta com outro produto (ex.: o `<title>` do SPA);
   apagar o item do achado 4 do `TODO.md` quando o `RESOLVED by` for ancestral da `main`.
