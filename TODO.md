# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).

Formato:

```md
- [ ] <o quê> — `arquivo:linha` — <por que importa> — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
```

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

## Aberto

> Um item cujo corpo traz **RESOLVIDO por `<hash>`** já está fechado: fica nesta seção, com a
> caixa ainda desmarcada, só até o PR da missão que o fechou ser mergeado — é dali que o PR cita
> a evidência. Depois do merge ele desce para "Feito". Ler a caixa sem ler o corpo dá falso
> positivo; o corpo é a fonte da verdade.

- [ ] **BLOQUEANTE — a sessão de fase headless não tem permissão para rodar `TEST_CMD`** —
  `bin/sdd:491-499` — `run_phase()` invoca `claude -p … --permission-mode "$PERMISSION_MODE"`
  (`acceptEdits`) sem `--allowedTools`; `acceptEdits` auto-aprova **edição de arquivo**, não
  `Bash`. Na prática a sessão EXEC só consegue ler (`git`, `ls`, `cat`, `Read`): `tests/run-all.sh`,
  `bash -n bin/sdd` e até `bash -c 'echo hello'` são negados com "This command requires approval".
  **`git add` também é negado** (só o `git` de leitura passa), então a sessão não consegue nem
  commitar — e `gate_EXEC` exige hash real no `git log`. A fase EXEC é, hoje, insatisfazível por
  construção: o agente não roda a suíte na abertura, não vê o Red, não verifica o Green e não
  produz o artefato que o gate cobra. Vale igual para QA/REVIEW, cujos gates também rodam
  `TEST_CMD`, e para PR, que precisa de `git push`/`gh`. Direção: passar `--allowedTools` em
  `run_phase()` cobrindo `TEST_CMD`/`E2E_CMD`/`LINT_CMD` e o `git` de escrita (ou fazer
  `sdd install` escrever `permissions.allow` no `.claude/settings.json` do alvo). Sensor durável: um check no `sdd preflight` que dispara uma sessão headless real e
  afirma que ela **consegue executar** `TEST_CMD` — hoje o preflight só valida `claude -p`
  respondendo (`bin/sdd:646`), o que não cobre este modo de falha. — descoberto por `sdd-executor`
  na missão `20260814-dry-run-completo` (2026-08-14)
  **Atualização (2026-08-14):** a **causa** foi corrigida por `2083680` (`--allowedTools` em
  `run_phase()` + `ALLOWED_TOOLS` no config) e a sessão EXEC `357b401` provou o conserto — rodou
  `tests/run-all.sh`, viu o Red, viu o Green e commitou. Deixa de ser BLOQUEANTE. **Continua
  aberto pelo que falta: o sensor durável.** Não há nada que impeça a regressão silenciosa —
  o `sdd preflight` ainda não afirma que uma sessão headless de fato executa `TEST_CMD`.
- [ ] Incremento `blocked` no checkpoint deveria escalar na hora, não gastar o orçamento de
  sessões — `bin/sdd:276` + `bin/sdd:830-844` — `gate_EXEC` já sabe dizer "Jidoka: a linha para",
  mas `cmd_run` só distingue gate-insatisfeito de gate-insatisfeito-e-sem-progresso; como a
  sessão que marca `blocked` mexe no `checkpoint.md`, o `state_fingerprint` muda e o runner
  entende "a sessão avançou — seguindo", rebootando EXEC até estourar `phase_budget` (aqui,
  4 sessões). `blocked` é decisão deliberada de parar a linha: deveria dar `return 3` imediato.
  — descoberto por `sdd-executor` na missão `20260814-dry-run-completo` (2026-08-14)
  **RESOLVIDO por `2083680`**: `cmd_run` passou a checar o checkpoint por `blocked` **antes** de
  gastar sessão e escalar na hora com `return 3` — exatamente o `return 3` imediato que este item
  pedia. Endurecido depois por `1807d75`: o teste usava `… | grep -qx`, que sob `pipefail` devolve
  **141** quando o `grep` fecha o pipe cedo, e o runner leria "não há blocked" **havendo** blocked
  — um Jidoka que dependia de corrida. O status sai para uma variável antes do `grep`. Documentado
  em `docs/failure-modes.md` ("Incremento `blocked`") e `docs/pipeline.md` (gate EXEC, Jidoka).
  — `sdd-docs`, mesma missão (2026-08-14)
- [ ] **`gate_QA` com `status: done` é insatisfazível em projeto sem interface** — `bin/sdd:303`
  + `bin/sdd:444` — `qa_substep` manda projeto sem `E2E_CMD`/`APP_URL` direto para `QA:close`,
  pulando as skills `qa-report`/`qa-execution` que são as donas de `docs/qa/` — logo a árvore
  nunca existe. Mas `gate_QA`, quando o status **não** é `skipped`, exige a Âncora 1: um
  relatório datado em `$QA_DOCS_PATH/reports/` marcado `closed`. Resultado: num projeto sem
  browser mas **com** mudança user-visible (o kit é o próprio caso — a jornada é `sdd` no
  terminal), o `sdd-qa` não tem status que seja ao mesmo tempo honesto e satisfazível:
  `skipped` mente (o diff chega ao usuário e a QA achou bug de verdade andando a jornada),
  `done` bate na Âncora 1 e reprova para sempre, `blocked` reprova por definição. A QA roda,
  encontra defeito real, e mesmo assim não consegue fechar o gate. Direção possível (é **decisão
  de contrato**, não conserto mecânico — por isso não virou incremento de fix): quando
  `qa_substep` = `close` por ausência de interface, `gate_QA` aceitar como Âncora 1 alternativa
  o próprio `30-handoff-qa.md` com `status: done` + campo `gate:` preenchido, já que ali está a
  evidência da jornada andada. Sensor durável junto: caso em `tests/check-gates.sh` afirmando
  que um projeto sem interface, com handoff `done`, passa no `gate_QA`. — descoberto por
  `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)
  **RESOLVIDO por `53cf63a`** (decisão humana, exatamente a direção sugerida): sem `E2E_CMD` e
  sem `APP_URL`, a âncora passa a ser o campo `gate:` do próprio handoff. O sensor pedido veio
  junto — `tests/check-gates.sh` testa o `gate_QA` nos **dois** contratos. Verificado andando a
  jornada na volta 2 da QA: `sdd why <m> QA` → `jornada andada sem interface de browser
  (evidência no handoff), suíte verde`. — `sdd-qa`, mesma missão (2026-08-14)
- [ ] `sdd install` não ignora o `pipeline.log` das missões — `bin/sdd:706-712` — o install só
  acrescenta `.sdd/logs/` ao `.gitignore` do alvo. O `pipeline_log_line` (`bin/sdd:557`) escreve
  em `$HANDOFF_DIR/<missão>/pipeline.log`, que fica **untracked** em qualquer repo-alvo recém
  instalado e suja o `git status`. Tree sujo reprova `gate_REVIEW` (`bin/sdd:361`) e o
  `sdd preflight` (`bin/sdd:814`) — ou seja, o próprio diário do runner pode derrubar o gate de
  outra fase. Este repo não sente porque o `.gitignore` dele ganhou `*.log` à mão, fora do
  install; o piloto `sales_quote` vai sentir. Decidir se o `pipeline.log` é efêmero (entra no
  ignore do install) ou durável (é commitado como os handoffs) — hoje ele é as duas coisas
  dependendo do repo. — descoberto por `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)
  **RESOLVIDO por `53cf63a`**: decidido **efêmero**. `PIPELINE_LOG` passou a ser
  `$(log_dir)/pipeline.log` = `.sdd/logs/<missão>/`, que o `sdd install` já ignora; o registro
  durável do que aconteceu continua sendo os handoffs commitados. A volta 2 da QA andou o
  caminho real e confirmou: o diário cai em `.sdd/logs/<missão>/pipeline.log`, `git status`
  fica limpo e não sobra nada em `docs/handoffs/`. Agora com sensor
  (`tests/check-dry-run.sh`, seção "o caminho real (não-dry) ainda escreve no diário"), que
  falha se o diário voltar para a árvore commitada. — `sdd-qa`, mesma missão (2026-08-14)
- [ ] A asserção "dry-run não toca no disco" é mais fraca do que parece —
  `tests/check-dry-run.sh:116` — ela vale sobre um fixture parado em EXEC, cujo `gate_EXEC`
  reprova por incremento pendente **antes** de chegar a rodar `TEST_CMD`. Num fixture que
  alcança um gate que roda a suíte (`gate_REVIEW`, por exemplo), o dry-run escreve
  `.sdd/logs/<missão>/gate-review-test-*.log` — verificado à mão nesta sessão. É subproduto de
  comportamento **aceito** pelo plano ("gates rodando `TEST_CMD` no dry-run é aceitável") e é
  gitignored, então não é bug; mas a asserção sugere uma garantia mais forte do que a que existe.
  Vale renomear para "não toca nos artefatos da missão" ou passar a exercitá-la também num
  fixture que chegue a `gate_REVIEW`. — descoberto por `sdd-qa` na missão
  `20260814-dry-run-completo` (2026-08-14)
  **Continua aberto — reconfirmado na volta 2 da QA** com evidência nova, agora no repo real e
  não em fixture: `bin/sdd run 20260814-dry-run-completo --dry-run` (missão parada em `QA:close`)
  cria `.sdd/logs/<missão>/gate-exec-test-<ts>.log` a cada invocação. A árvore de arquivos
  **muda**; o `git status` não, porque é gitignored. Segue não sendo bug (é o `TEST_CMD` que os
  gates rodam de propósito), mas a asserção continua prometendo mais do que entrega.
- [ ] **`gate_EXEC` aceita commit órfão: `git cat-file -e` não é "está no `git log`"** —
  `bin/sdd:270` — o gate afirma cobrar "hash real no `git log`" (é o `rótulo não é artefato` do
  incremento `done`), mas verifica com `git cat-file -e "${commit}^{commit}"`, que só pergunta se
  o **objeto existe no banco** — não se ele está alcançável a partir da branch. Depois de um
  `git commit --amend`, `rebase` ou `reset`, o hash antigo continua no object database (dangling,
  vivo até o `gc`), então um `checkpoint.md` que cite o hash pré-amend **passa no gate apontando
  para um commit que não está na história**. Verificado nesta sessão sem querer: amendei o próprio
  commit da QA, o handoff ficou citando `d161282`, e `git cat-file -e d161282^{commit}` → 0
  enquanto `git merge-base --is-ancestor d161282 HEAD` → 1 e `git log` não o lista. O modo de
  falha é silencioso e exatamente do tipo que o kit existe para impedir: o artefato citado some,
  o gate continua verde. Direção: trocar por `git merge-base --is-ancestor "$commit" HEAD` (ou
  `git rev-list HEAD | grep -q`), que responde a pergunta que o gate realmente quer fazer. Sensor
  durável junto: caso em `tests/check-gates.sh` com um checkpoint citando commit órfão, afirmando
  que `gate_EXEC` **reprova**. — descoberto por `sdd-qa` na missão `20260814-dry-run-completo`
  (2026-08-14)
- [ ] **A suíte não tem teste de mutação, e por isso não percebe asserção que virou decoração** —
  `tests/` — quando `53cf63a` moveu o `pipeline.log` para `.sdd/logs/`, a asserção
  `projeção blocked não cria pipeline.log` continuou apontando para `$MDIR/pipeline.log`, um
  caminho onde o runner **não escreve mais em nenhuma circunstância**. Ela seguiu imprimindo
  `ok` — mas por vacuidade: com o bug do F1 reintroduzido à mão, continuava verde. Nenhum sinal
  na suíte, porque uma asserção que não pode falhar não se distingue de uma que passa. Só
  apareceu porque a QA rodou mutação à mão. Foi corrigida, mas a **classe** do problema continua:
  qualquer refactor que mude um caminho pode esvaziar um sensor em silêncio. Direção: um
  `tests/check-mutation.sh` que aplique um punhado de mutações conhecidas em `bin/sdd` e afirme
  que a suíte fica **vermelha** em cada uma — sensor do sensor (se a suíte não morre quando o
  código é sabotado, ela não está medindo nada). — descoberto por `sdd-qa` na missão
  `20260814-dry-run-completo` (2026-08-14)
- [ ] **`config/schema.md` promete cinco comportamentos que o runner não tem** —
  `config/schema.md:24-25,32-34` vs `bin/sdd:81-82` — `LINT_CMD` e `BUILD_CMD` estão
  documentados como "roda no gate de REVIEW quando definido", e `DEV_UP_CMD`/`DEV_READY_CMD`/
  `DEV_READY_TIMEOUT` como "sobe o ambiente antes do QA / o runner faz poll por até N segundos".
  Nenhum dos cinco é lido em lugar nenhum: `load_config()` atribui o default e o nome nunca mais
  aparece — `gate_REVIEW` (`bin/sdd:347-385`) roda só `TEST_CMD` e `git status`. Um `.sdd/config.sh`
  com `LINT_CMD` preenchido dá ao usuário a impressão de que o lint está sendo cobrado no gate,
  e não está: é um sensor que ele acha que tem e não tem — pior do que não ter. Direção: ou
  implementar (`gate_REVIEW` roda `LINT_CMD`/`BUILD_CMD` quando definidos; a fase QA sobe o
  ambiente), ou tirar a promessa do schema e marcar as chaves como reservadas. **Pré-existente
  — já estava em `main`, não foi introduzido por esta missão.** — descoberto por `sdd-reviewer`
  na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] **A fase TICKET recebe agente E slash ao mesmo tempo, contra a regra escrita ao lado** —
  `bin/sdd:491` + `bin/sdd:501` — o comentário sobre `phase_agent()` estabelece o invariante:
  "vazio ⇒ quem dirige é a skill do slash, não um agente do kit (dois system prompts disputando
  a sessão é ruído, não reforço)". `QA:plan`/`QA:exec` respeitam — agente vazio onde há slash.
  `TICKET` não: `phase_agent` devolve `sdd-publisher` **e** `phase_slash` devolve
  `/ticket open <título>`, então a sessão nasce com `--agent sdd-publisher` e o slash literal
  prependado ao prompt — exatamente o cenário que o comentário condena, sem nota explicando a
  exceção. E é redundante: a skill `ticket` não tem `disable-model-invocation` (não precisa do
  workaround do slash, ao contrário de `qa-report`/`qa-execution`), e o `agents/sdd-publisher.md`
  já manda o agente invocar `/ticket open` por conta própria. Decidir um dos dois: `phase_agent
  (TICKET)` vazio, ou tirar `TICKET` do `phase_slash`. **Não corrigido aqui de propósito**: é
  decisão de contrato de fase, e o `00-missao.md` desta missão põe mudança de agente/gate fora de
  escopo. Não morde hoje porque `JIRA_ENABLED=false` no kit — o piloto `sales_quote` é onde
  aparece. — descoberto por `sdd-reviewer` na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] `latest_matching` ordena lexicograficamente e quebra a partir da 10ª rodada —
  `bin/sdd:205-211` — `ls -1d $pattern | sort | tail -1` escolhe o "mais recente" por ordem de
  string: com `40-review-r10.md` presente, `sort` põe `r10` **antes** de `r2`, e o `tail -1`
  devolve `40-review-r9.md` como se fosse o último. `gate_REVIEW` e `gate_QA` passariam a medir
  um relatório velho — gate verde apontando para artefato obsoleto, a classe de falha que o kit
  existe para impedir. Não morde hoje porque `REVIEW_MAX_ITER`/`QA_MAX_ITER` são 3, mas o valor
  é configurável e nada avisa quem o subir para 10+. Direção: `sort -V` (version sort), ou
  zero-padding no nome do artefato. Sensor junto: caso com `r1`, `r2` e `r10` afirmando que o
  escolhido é `r10`. — descoberto por `sdd-reviewer` na missão `20260814-dry-run-completo`
  (2026-08-14)
- [ ] `bad_rows` é escrito e nunca lido — `bin/sdd:262,276` — o contador é incrementado no mesmo
  comando que dá `return 1`, então o valor final nunca é inspecionado; lido de fora, sugere um
  "conte quantas linhas estão ruins" que não existe. Ou entra no `GATE_WHY` (útil: "3 linhas do
  checkpoint malformadas" diz mais do que a primeira), ou sai. Pré-existente. — descoberto por
  `sdd-reviewer` na missão `20260814-dry-run-completo` (2026-08-14)
- [ ] **O `## Uso` do README documenta metade da superfície do CLI** — `README.md:42-48` vs
  `bin/sdd:1085-1096` — o bloco lista `run`, `status`, `retry`, `close` e `--dry-run`. Ficam de
  fora, existindo e funcionando: `sdd why <missão> [FASE]` (o comando que o próprio
  `docs/failure-modes.md:5` manda rodar **primeiro** em qualquer diagnóstico), `sdd phase`,
  `--phase <FASE>` e `--max-phases <N>`. Quem lê só o README não descobre a ferramenta de
  diagnóstico que o resto da documentação pressupõe. **Pré-existente** — os quatro já estavam em
  `main`, nenhum foi introduzido por esta missão; por isso registrado e não corrigido aqui.
  Direção: uma linha por comando no bloco `## Uso`, mantendo a profundidade em `docs/pipeline.md`
  (o README roteia, não aprofunda). — descoberto por `sdd-docs` na missão
  `20260814-dry-run-completo` (2026-08-14)
- [ ] **`sdd preflight` gasta uma sessão paga e o README não avisa** — `README.md:35` vs
  `bin/sdd:768-774` — o README apresenta o preflight como "sensor de ambiente: claude, gh,
  agent-browser, plugins, tree limpo", que soa como checagem local e barata. Ele dispara um
  `claude -p` real (teto `--max-budget-usd 1`) para provar que a sessão headless **consegue
  executar** um comando — que é justamente o que o torna valioso, e o que o torna pago. Quem roda
  preflight em laço (CI, script de bootstrap) paga sem saber. `docs/pipeline.md` (Permissões) e
  `docs/failure-modes.md` descrevem o probe corretamente; o buraco é só no índice. Pré-existente:
  o probe já estava em `main`. Direção: meia linha no README (`sdd preflight # …; dispara uma
  sessão real, custa ≤ US$ 1`). — descoberto por `sdd-docs` na missão
  `20260814-dry-run-completo` (2026-08-14)
- [ ] **O kit não tem `CHANGELOG.md`, e a fase DOCS cobra um** — `agents/sdd-docs.md` (tabela "O
  que atualizar") manda atualizar o `CHANGELOG.md` "quando a missão entrega algo visível ao
  usuário". Este repo não tem esse arquivo: o registro durável é `KAIZEN_LOG.md` (melhoria com
  número) + os handoffs commitados + o corpo do PR — e nenhum dos três é um changelog por versão.
  Resultado: toda missão do kit que muda comportamento do `sdd` cai num `n/a` que é honesto mas
  repetido, e quem instala o kit num repo-alvo não tem onde ler "o que mudou entre duas versões
  do runner" (há `SDD_VERSION="0.1.0"` em `bin/sdd:5`, sem nada que o acompanhe). Decidir **um**
  dos dois, e o que for decidido vale para os repos-alvo também: (a) criar `CHANGELOG.md` no kit,
  com política de versionamento amarrada ao `SDD_VERSION`, ou (b) tirar a linha do
  `agents/sdd-docs.md` e assumir que o par KAIZEN_LOG+handoffs é o registro. Hoje o agente cobra
  um artefato que a constituição do repo não prevê — a mesma classe de defeito do
  `config/schema.md` prometendo chave não implementada. Não corrigido aqui: criar changelog do
  zero é decisão de convenção do repo inteiro e retroagiria a toda a história, o que é escopo de
  missão própria, não de uma fase DOCS. — descoberto por `sdd-docs` na missão
  `20260814-dry-run-completo` (2026-08-14)
- [ ] O `sdd-planner` ainda não foi exercitado numa missão real — as missões planejadas até aqui
  tiveram plano escrito à mão. Primeira missão planejada por ele deve conferir se o gate PLAN-AUTO
  é preenchido com evidência de verdade. — descoberto por `humano` na implementação (2026-08-14)
- [ ] Multi-missão concorrente exigiria `git worktree` por missão — hoje é 1 missão por branch por
  vez (YAGNI declarado no plano). Reavaliar se aparecer demanda real. — descoberto por `humano` no
  planejamento (2026-08-14)
- [ ] Destilar handoffs/KAIZEN_LOG para o vault Obsidian continua manual/editorial. Avaliar um
  `sdd digest` que gere o rascunho. — descoberto por `humano` no planejamento (2026-08-14)
- [ ] A suíte não exercita o caminho **real** (não-dry-run) de `pipeline_log_line` — `bin/sdd:557`
  — todo sensor que temos afirma que a projeção **não** escreve; nenhum afirma que uma fase de
  verdade **escreve**. Escrever no `pipeline.log` exige uma `run_phase` real, que chamaria o
  `claude`, então nenhum fixture chega lá. Consequência: um refactor que quebre a guarda ao
  contrário (por exemplo trocá-la por um `return 0` incondicional, ou pôr `[ … ] && return 0`
  como última linha da função, onde o `set -e` do caller morde) mata o diário da missão em
  silêncio e a suíte segue verde. Nesta sessão a garantia só existiu porque provei o caminho
  não-dry à mão, num probe descartável — o oposto de sensor durável. Direção: extrair as funções
  puras de `bin/sdd` para um arquivo sourceável, ou dar ao runner um modo `--self-test` que
  exercite `pipeline_log_line` com os dois valores de `DRY_RUN`. — descoberto por `sdd-executor`
  na missão `20260814-dry-run-completo` (2026-08-14)
  **RESOLVIDO por `85dfc9f`** (volta 2 da QA) — sem precisar de `--self-test` nem de extrair funções: o
  caminho de escalação `blocked` **loga e retorna 3 antes de qualquer `run_phase`**, então dá
  para exercitar o caminho real sem gastar token nem rede. Virou a seção "o caminho real
  (não-dry) ainda escreve no diário" em `tests/check-dry-run.sh`. O modo de falha exato que este
  item descrevia (guarda invertida → diário morto, suíte verde) foi reproduzido por mutação e
  agora **falha em 4 asserções**. — `sdd-qa`, mesma missão (2026-08-14)

## Feito

- [x] Re-link do shim quebrado do `agent-browser` (I0) — resolvido em 2026-08-14, com sensor
  permanente no `sdd preflight`.
- [x] **Boot por slash literal funciona headless** — verificado em 2026-08-14: `claude -p
  "/qa-report docs/qa …"` carrega as instruções da skill mesmo com `disable-model-invocation:
  true` (a sessão citou o Step 1 dela de volta). O fallback `--append-system-prompt` fica sem uso.
  A fase QA passou a ser três sessões — `/qa-report`, `/qa-execution`, `sdd-qa` — com o sub-passo
  **derivado dos artefatos** (`qa_substep`), não de um contador.
- [x] **`/goal` NÃO existe neste ambiente** — verificado em 2026-08-14 (`~/.claude/commands/`
  vazio, nada no cache de plugins). O padrão `/goal /codereview:codereview até Grade A` do
  template do usuário não é reproduzível headless; o `sdd-reviewer` conduz o laço por instrução
  própria, que era o fallback previsto no plano.
- [x] `claude -p --agent <nome>` funciona headless — verificado em 2026-08-14 num repo-fixture:
  a sessão encarnou o `sdd-executor` e recitou a primeira instrução do arquivo do agente. O
  fallback `--append-system-prompt` fica sem uso. `--setting-sources user,project,local` é
  passado explicitamente pelo runner para garantir que `.claude/agents/` do alvo carregue.
