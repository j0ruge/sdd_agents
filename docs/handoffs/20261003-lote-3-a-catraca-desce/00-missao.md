---
missao: 20261003-lote-3-a-catraca-desce
titulo: a catraca do backlog do kit desce de 57 para 22 + N (os achados que nascem na leva) — 13 consertos com sensor, 22 saídas pelo ciclo de vida, e o /sdd-plan ensina o planner a falar com o humano quando roda em segundo plano
data: 2026-10-03
versao: n/a (JIRA_ENABLED=false)
branch: fix/lote-3-a-catraca-desce
aprovacao: auto
adr: none
ddd: n/a
---

# Missão — Lote 3: a catraca desce

> Escrito pelo `sdd-planner` com o humano presente (via a sessão coordenadora, que repassou sete
> perguntas de grill em 2026-10-03). É a única fonte da **intenção**; o `01-plano.md` é a fonte do
> **como**. Toda sessão que executar esta missão começa lendo estes dois, mais o `checkpoint.md`.

## Problema (Gemba)

O `TODO.md` do kit tem **57 achados abertos** (`bash tests/check-todo.sh` →
`57 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`), espelhados em
57 issues `todo` do `j0ruge/sdd_agents`; a catraca `todo-findings 57` mora em
`tests/health-baseline.txt:26`. O humano quer levá-la a zero em levas sucessivas. Medido em
2026-10-03 sobre `5d55571`:

1. **Triagem cética dos 57.** Quatro verificadores paralelos, só leitura, conferiram cada alegação
   no código; quatro foram reproduzidas em rascunho (#213, #63, #127, contagem do #88). Resultado:
   - **13 MEC** — conserto mecânico com sensor claro: #63, #87, #113 (resíduo), #115, #121, #127,
     #169, #211, #212, #213, #216 (pequenos) e #192, #217 (médios). Cinco são fail-open (#63, #87,
     #113, #127, #169).
   - **22 DEC** — pedem decisão de desenho do humano antes de código (~17 decisões).
   - **20 D15** — saem sem código: limite já declarado no cabeçalho do sensor, decidido por ADR,
     YAGNI, ou assinatura do humano.
   - **2 refutados** — #138 (a evidência existia no prompt renderizado: `148f693:bin/sdd:1621`
     expande `$TODO_FILE`) e #187 (o `sdd status` sem `--no-gates` roda TEST_CMD e E2E sob a trava,
     `bin/sdd:6567`; a trava é `LOCK_NB`, `bin/sdd-coordination.py:504`, e não enfileira).
   Três premissas mudaram desde o registro: #127 é **pior** (`TODO_FILE='*'` casa `bin/sdd` e
   alarga a fronteira de todo chapéu), #113 está **pela metade** (`eb0ee9e` consertou os 3 espaços,
   sobra o `calibrate()`), #214 tem a premissa **falsa** (linhas KAIZEN são `$meta`, fora do eixo do
   juiz, `bin/sdd:9943`, `:9210`).
2. **Velocidade da catraca** (`git log` de `tests/health-baseline.txt`): nas últimas ~24 h fecharam
   42 itens e nasceram ~10, metade de sessões em repo-alvo. 24 dos 57 são de agosto: o núcleo que
   sobreviveu a todos os lotes porque pede decisão humana, não código.
3. **O `/sdd-plan` não diz como o planner fala com o humano.** `commands/sdd-plan.md:41-47` manda
   delegar ao subagente `sdd-planner` e afirma que ele conduz o grill "with the human present"; o
   subagente roda em segundo plano, sem `AskUserQuestion`, e não alcança o humano. Nesta própria
   sessão o orquestrador inventou um protocolo de repasse — o planner encerra o turno com UMA
   pergunta e opções, o orquestrador pergunta e devolve a resposta verbatim — e ele funcionou nas
   sete perguntas. Sem ele escrito, a próxima sessão ou deixa o planner decidir o grill sozinho
   (o que o comando proíbe) ou trava esperando resposta que nunca chega.

## Métrica

Fatos binários, todos verificáveis por comando (detalhe no `01-plano.md` § Verificação end-to-end):

1. **Os 22 nomeados saíram da seção aberta nesta branch**, cada um pelo destino da decisão 4, e a
   catraca desceu no mesmo diff. `bash tests/check-todo.sh` → `35 finding(s)` ao fim do I3, e
   `36` depois do I14, que registra o achado já nascido no planejamento (o `kaizen_reminder` tem o
   defeito do #121). Mais N, se nascerem outros (decisão 5). `tests/health-baseline.txt` diz o mesmo
   número.
2. **Os 13 MEC carregam `RESOLVED by <hash>`**, cada hash ancestral do topo da branch, cada um com
   Red observado pelo motivo certo e sensor durável (probe e, onde é comportamento do runner ou do
   catálogo, mutante no `CATALOG` provado com `--only`).
3. **O `/sdd-plan` traz o protocolo de repasse e o aviso de trabalho longo** (`commands/sdd-plan.md`,
   decisões 3 e 10), e o chapéu do planner traz a regra de encerrar o turno com a pergunta e de
   avisar antes de trabalho longo (`agents/sdd-planner.md`). O espelho
   `.claude/agents/sdd-planner.md` fica byte a byte igual.
4. **Suíte verde** (`bash tests/run-all.sh` → `suite green`) e **um** `sdd health` verde depois da
   revisão dos bots (carimbo válido para o `gate_PR`).
5. **Depois do merge** (fora da branch, pelo humano): chore apaga os 13, catraca em **22 + N**
   (N ≥ 1: o achado do `kaizen_reminder`), espelho de issues re-sincronizado. Saldo declarado no PR:
   "57 → 22 + N nascidos".

## Resultado esperado

O backlog do kit fica com só o que pede decisão humana (~22 itens, ~17 decisões) mais o que nascer.
Os cinco fail-open mecânicos ficam fechados com sensor; as 22 saídas sem código param de pesar na
catraca com o destino escrito onde a próxima sessão o encontra (seção decidida, cabeçalho do
sensor, tabela YAGNI do `CONTEXT.md`). A leva 4 começa por um grill das decisões DEC, sem precisar
re-triar nada. E a próxima sessão de `/sdd-plan` sabe repassar o grill ao humano.

## Fora de escopo

- **Os 22 DEC** — 67, 88, 92, 95, 98, 108, 109, 129, 130, 134, 135, 141, 142, 153, 155, 178, 179,
  180, 191, 194, 198, 218. Ficam no `TODO.md`, intocados; viram o grill da leva 4 (decisão 2).
  As opções medidas de cada um estão em `triagem-57.md`, neste diretório.
  Quatro deles foram reescopados pela triagem e o grill da leva 4 deve partir disso, não do texto
  do item: #179 (a direção "blob na ponta" não distingue os dois casos), #142+#198 (uma decisão
  só), #180+#218 (enum de status), #141+#108 (superfície de idioma e pisos).
- **Achado nascido no meio da leva** — passa pela régua D15 e vai ao `TODO.md` com catraca +1 no
  mesmo commit; não é consertado aqui (decisão 5). Exceção: defeito criado pela própria leva é bug
  da missão e se conserta nela.
- **Os dois irmãos do #121.** O `kaizen_reminder` tem o mesmo defeito, reproduzido no planejamento:
  do worktree, o `sdd` do checkout principal imprime a frase de repo-alvo. É achado novo (decisão 5):
  o I14 o **registra** no `TODO.md` com catraca +1 e não o conserta. O `kit_guard_check` usa a mesma
  grafia, mas não é defeito: o carimbo é de checkout, e trocá-lo desarmaria a guarda.
- **Prosa de contrato fora de `templates/`** — o incremento do `/sdd-plan` não ganha sensor
  durável porque medir prosa de contrato fora de `templates/` é exatamente a decisão #109 da leva 4.
- **Merge, chore pós-merge e re-sync do espelho** — passos do humano depois do PR, descritos no
  `01-plano.md` § Depois do checkpoint; não são incrementos.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao: auto` e o pipeline segue
sozinho. Qualquer ✗ → `aprovacao` fica vazio e o runner para pedindo aprovação humana explícita.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 10 decisões em § Decisões do grill: 7 perguntas, 2 decisões que nasceram dos protótipos (8, 9) e 1 acréscimo do humano (10). Nenhum 🚩 aberto por esta missão. As 3 pendências têm dono, o humano: merge, grill da leva 4 e momento do `sdd health`. Os 22 DEC estão deferidos para a leva 4, com nome e reescopo em § Fora de escopo. |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 todos ✅, com evidência na tabela abaixo. DDD `n/a`, justificado: nenhum enum, evento, token, chave nem artefato novo; os contratos entre módulos são DEC e estão fora. |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Um subagente sem memória leu só os 3 arquivos e o código e testou I1, I12 e I17: 0 lacuna bloqueante de fato. 18 conferências pontuais, 0 erradas. Os 13 registros do I1 foram medidos num clone: `44 finding(s) … every anchor on target` e o Check do I1 deu `1 18 1`, com controle negativo. As lacunas de custo achadas foram fechadas no plano: o I17 deixou de ser esboço, o I12 ganhou corpos e 4 sítios de drift, mais as 2 cópias de "6 of the 14", a política de commit do checkpoint, um só significado de N, 592 mutantes e a catraca no Check do I14. Uma varredura confirmou que não sobrou contradição. |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado) | ✅ | 20 de 20 linhas com Check. Os 20 rodados contra HEAD `5d55571` deram VERMELHO com o valor de antes que o plano cita (ex.: I1 `0 5 0`, I4 `0 0 0 1 same`, I20 `0 1 0 5 0`). `tests/check-checkpoint.sh --check` → `20 row(s), 18 under the anchor rule, none blind`; a varredura do sensor fica verde com este arquivo (25 arquivos). |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`), `versao: n/a`. |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: none`, decidido pelo humano (decisão 7): nenhum conserto emenda ADR. `./bin/sdd adr check --mission 20261003-lote-3-a-catraca-desce --phase plan` → `ok … adr: none — the mission declares no architectural decision`, rc 0. |

## Checklist kaizen (`kaizen-software`)

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | Os 57 itens foram conferidos no código por 4 verificadores; 4 alegações reproduzidas e 2 refutadas. Os 13 consertos foram prototipados num clone de `5d55571` por 4 designers: probe vermelho em HEAD, verde com o conserto, mutantes pegos por `--only`. Os 20 Checks foram rodados contra HEAD. |
| K2 | Problema declarado com métrica | ✅ | Catraca 57 → 35/36 na branch → 22 + N depois do merge; os 13 com `RESOLVED by` e sensor; suíte e carimbo verdes. Tudo por comando (`00-missao.md` § Métrica). |
| K3 | Desperdícios identificados e cortados | ✅ | **Superprodução:** 22 itens saem sem código, e o #192 é só dica (sem obrigação nova no chapéu). **Superprocessamento:** sem sensor novo para a prosa do `/sdd-plan` (fica com o #109); a opção maior do #115 foi recusada. **Espera:** um `sdd health` só, depois dos bots. **Custo:** execução interativa, não `sdd run`. **Defeito:** protótipos antes do plano. |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 20 incrementos de uma sessão cada, um item por incremento (o #217 e o #192 em dois). Cada um tem Check medido vermelho em HEAD, com o valor de antes anotado no plano. |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | Os Checks leem a linha `ok` do sensor (âncora `^  ok    `), o arquivo ou o rc da suíte; mutante provado com `--only`. Ressalva honesta: o Check do I4 mede a presença da prosa, porque sensor de prosa de contrato fora de `templates/` é a decisão #109 (leva 4). |
| K6 | Jidoka — o que para a linha está definido | ✅ | Sensor vermelho para o commit. Âncora deslocada para o commit (`check-todo.sh` no `TEST_CMD`). Defeito criado pela leva se conserta nela (decisão 5). Controle por assassino vermelho no I17 para a linha. O carimbo só nasce verde. |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | Todo conserto entra com probe durável (e mutante, quando é `bin/`). As saídas viram registro decidido, cabeçalho de sensor ou linha YAGNI. O repasse vira texto do `/sdd-plan` e do chapéu do planner. |
| K8 | Registro no KAIZEN_LOG | ✅ | Planejado no I20, cujo Check exige o slug no `KAIZEN_LOG.md`, com o antes e o depois medidos (catraca, consertos, mutantes novos). |

## Checklist DDD (`ddd`) — condicional

> Acionado **só** quando a missão toca modelagem de domínio/arquitetura (aggregates, bounded
> contexts, eventos, entidades novas, contratos entre módulos). Missão mecânica/visual/trivial →
> marque `n/a — sem toque de domínio` com uma linha de justificativa. Em dúvida, acione.

`n/a — sem toque de domínio:` a leva não cria enum, evento do ledger, token de status, chave de
config nem artefato novo; todo conserto aperta uma guarda que já existe (validação de chave de
config, escopo do `gate_REVIEW`, gênero da Âncora 3, regra de sensor, leitura do stream no
preflight, modo do catálogo). Os itens que mexeriam em contrato entre módulos — o enum de status do
checkpoint (#180, #218), o 6º evento do ledger (#153), a posse do relatório de QA (#179) — são DEC e
estão fora (decisão 2).

## Decisões do grill (não re-litigar)

1. **"Zerar a catraca" = todo item sai da seção aberta por uma das saídas do ciclo de vida** —
   conserto por commit (`RESOLVED by` → apagado depois do merge), decisão humana (seção decidida),
   limite declarado no cabeçalho do sensor, YAGNI no `CONTEXT.md`, refutado ou duplicata; os 14
   fail-open (MEC 63, 87, 113, 127, 169; DEC 67, 95, 108, 129, 141, 155, 178, 179, 191) só saem
   por commit ou por decisão que retire a promessa falsa. — Porquê: é o contrato do
   `templates/todo.pt-BR.md` e a régua D15; 22 itens não têm defeito a consertar.
2. **Leva 3 = 13 MEC + 20 D15 + 2 refutados, com um `sdd health` só; catraca 57 → ~22.** As ~17
   decisões DEC ficam para um grill próprio logo depois, que gera a leva 4. — Porquê: o código tem o
   tamanho dos lotes 1 e 2 (13 consertos cada, já provados), as saídas D15 são texto, e os 5
   cabeçalhos de `tests/*.sh` cabem no mesmo carimbo.
3. **Incremento extra, fora do `TODO.md`: o `/sdd-plan` ganha o protocolo de repasse** no
   `commands/sdd-plan.md`, e o `agents/sdd-planner.md` uma regra de como encerrar o turno quando
   roda como subagente. Não se registra no `TODO.md`. — Porquê: sem ele a próxima sessão deixa o
   planner decidir o grill sozinho ou trava esperando resposta que nunca chega.
4. **As 22 saídas sem código, com o destino de cada uma** (tabela no `01-plano.md` § Saídas sem
   código): decididos 138, 187, 214, 181, 102, 152, 137, 74, 143, 122, 154, 158, 101, 128, 93;
   YAGNI 123 e 124; cabeçalho 66, 77, 90, 125, 140. Incluídos: #143 troca o critério (4) da D7 pela
   tabela de prazos do `step_timeout` e fecha o 🚩 do `CONTEXT.md`; #123/#124 mudam o `CLAUDE.md`
   § Idioma junto; #158 muda a anatomia §6 junto; #101 e #128 saem decididos, **sem** conserto. —
   Porquê: o grupo A já está decidido por artefato; cada proposta do grupo B segue a postura que o
   kit já escreveu.
5. **Achado nascido no meio da leva passa pela régua D15 na hora**; o que passar entra no
   `TODO.md` com catraca +1 no mesmo commit e fica para a leva 4; defeito criado pela própria leva
   se conserta nela. Saldo no PR: "57 → 22 + N nascidos". — Porquê: segura o escopo, e a regressão
   da leva não escapa como achado.
6. **Execução interativa, como os lotes 1 e 2** — uma sessão executa incremento a incremento com o
   checkpoint como trilha; depois PR, espera de todos os bots, consertos numa leva, `sdd health`
   uma vez, merge. **Não** é `sdd run`. — Porquê: provado duas vezes, consegue editar `.claude/`
   (espelho do planner, anatomia §6), e missão de kit via `sdd run` custou US$ 48–230.
7. **Missão `20261003-lote-3-a-catraca-desce`, branch `fix/lote-3-a-catraca-desce`, `adr: none`.**
   — Porquê: segue o padrão dos lotes, o slug não tem stopword do `check-lang` (pode ser citado em
   comentário de `tests/`), e nenhum conserto desta leva emenda ADR.
8. **#115 fecha com escopo nos dois gates.** O `gate_REVIEW` olha só `40-review-r*.md`,
   `checkpoint.md` e `checkpoint-notas.md`. O `gate_DOCS` passa a recusar o próprio `45-docs.md`
   sujo ou não rastreado, e a DOCS morta re-deriva DOCS. Resíduo declarado: uma DOCS que commitou o
   `45-docs.md` mas deixou outro documento sujo chega ao PR com a árvore suja. — Porquê: escopar só o
   REVIEW abriria o caminho "DOCS morta com `45-docs.md` completo → PR sobre árvore suja", que é
   defeito criado pela leva (decisão 5); o `gate_DOCS` tem dono para o artefato
   (`agents/sdd-docs.md:115`, "Commit everything"), então a recusa é satisfazível.
9. **As recomendações técnicas dos protótipos são adotadas como estão** (detalhe em cada incremento
   do `01-plano.md`):
   - #127: normalizar e validar no `load_config` com a gramática do `adr_dir_ok`;
   - #63: gênero lido do bloco do `Status:`, com o 3º probe;
   - #213: conserto no código, não só a doc;
   - #87: checagem estrita das chaves numéricas;
   - #216: reprova, não avisa;
   - #211: dois limites declarados no cabeçalho;
   - #169: controle por assassino como pseudo-job;
   - #192: dois incrementos, só dica (o `sdd-executor.md` não muda);
   - #217: dois incrementos.
   — Porquê: cada uma foi prototipada e medida num clone de `5d55571`, e nenhuma muda contrato entre
   módulos.
10. **O incremento do `/sdd-plan` também exige o aviso de trabalho longo.** Antes de um trabalho
    longo entre duas perguntas do grill (por exemplo, prototipar consertos com subagentes
    paralelos), o planner devolve primeiro um aviso de UMA linha com o que vai fazer e a estimativa
    de tempo, e só então começa. — Porquê: entre a Pergunta 7 e a 8 desta sessão o planner ficou
    ~45 min sem sinal; o humano perguntou "Desenvolvendo a mais de 20 minutos?" e o orquestrador só
    tinha mtimes no disco. Sem o aviso, o grill parece travado e o humano interrompe ou abandona uma
    sessão que estava trabalhando. (humano, "Sim", 2026-10-03)

## Pendências para o humano

- **Merge do PR** e, depois dele, o chore pós-merge e o re-sync do espelho (`01-plano.md` § Depois
  do checkpoint).
- **O grill da leva 4** — as ~17 decisões dos 22 DEC.
- **O momento do `sdd health`** — a decisão 6 o põe depois da revisão dos bots, uma vez; quem o
  dispara é o humano (~40–50 min, lançador desanexado).
