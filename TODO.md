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
- [ ] **Nenhum gate confere se a missão ainda está na branch que ela declarou** — `bin/sdd`
  (todos os `gate_*`) + `templates/missao.md` (campo `branch:`) — o `00-missao.md` declara a
  branch e **ninguém mais olha para esse campo**. Medido no piloto SQ-97: entre `QA:plan` e
  `QA:exec` o checkout mudou para a branch de outra frente (`SQ-90_rotacao_senha_it`), e **cinco
  fases seguidas — QA:exec, QA:close, REVIEW, DOCS e a 1ª PR — commitaram lá**, empilhando 16
  commits em cima do HEAD de um PR alheio já aberto (#104). Todos os gates passaram: eles medem
  artefato e suíte, e ambos estavam corretos — só estavam no lugar errado.

  Quem pegou foi o `sdd-publisher`, na última fase, ao conferir a branch antes do push — e
  recusou publicar duas vezes, refazendo a medição na segunda sessão. **O sensor existia, mas no
  fim da linha**: o custo de detectar tarde foi ~US$ 45 em fases que precisaram de cirurgia de
  `rebase --onto` para serem separadas.

  Direção: um check barato no **início** de cada fase — `git branch --show-current` contra o
  campo `branch:` do `00-missao.md`; divergiu, `BLOCKED` na hora com a instrução de voltar.
  Custa um comando; teria economizado cinco fases. Sensor durável: caso em `check-gates.sh` com
  a branch trocada no meio, afirmando que a fase seguinte reprova antes de abrir sessão.
  ⚠️ Relacionado: o campo `branch:` do `00-missao.md` é preenchido pela fase TICKET **depois** do
  planejamento — o check tem que tolerar o valor `<criada pela fase TICKET>` antes disso.
  — descoberto por `sdd-publisher` e por `humano` no piloto SQ-97 (2026-08-14)

- [ ] **`printf | grep -q` com `pipefail` inverte a lógica em silêncio — duas ocorrências vivas** —
  `bin/sdd:838` (probe do `sdd preflight`) e `bin/sdd:1229` (escalação Jidoka do `blocked`) —
  o arquivo roda com `set -o pipefail`. Quando o `grep -q` **acha**, ele sai imediatamente e
  fecha o pipe; o `printf` que ainda escrevia morre de SIGPIPE (141), e o `pipefail` faz o
  pipeline inteiro devolver 141. Ou seja: **achou → devolve erro**. Medido nesta missão com o
  mesmo idioma escrito por engano no `cmd_health`, e reproduzido isoladamente:
  `printf '%s' "$(cat bin/sdd)" | grep -qE '\bTEST_CMD\b'` → `rc=141`, enquanto
  `grep -qE '\bTEST_CMD\b' <<< "$corpo"` → `rc=0`.

  **Por que não morde hoje:** as duas entradas são pequenas (a saída do probe e as poucas
  linhas de `ckstatus`), e o `printf` termina de escrever antes de o `grep` sair — o buffer do
  pipe (64 KB) absorve tudo. A falha depende do TAMANHO da entrada, então passa nos testes e
  aparece no repo-alvo grande. A 1229 é a pior das duas: é o Jidoka que escala incremento
  `blocked` **antes** de gastar sessão; com um `checkpoint.md` grande o suficiente, ele
  simplesmente para de disparar, e a linha não para quando devia. Direção: herestring
  (`grep -qx "blocked" <<< "$ckstatus"`), que é o que o `cmd_health` já usa, e uma asserção com
  checkpoint grande. **Pré-existente — não corrigido aqui de propósito:** é mudança de
  comportamento em caminho de escalação, fora do escopo do I13.2, que era ferramenta de medição.
  A convenção já entrou no `CLAUDE.md`. — descoberto por `humano` na missão
  `20260814-i13.2-mutacao-health` (2026-08-14)
- [ ] **`E2E_DIR` tem default no runner e é lida só pelo agente** — `bin/sdd:81` vs
  `agents/sdd-qa.md:44` — `: "${E2E_DIR:=e2e}"` é a única ocorrência da chave no `bin/sdd`:
  nenhum gate, nenhum prompt de boot e nenhum comando do runner a consultam. Quem usa o valor é
  o texto do `sdd-qa`, que fala de `e2e/` por conta própria — ou seja, mudar `E2E_DIR` no
  `.sdd/config.sh` **não muda onde as specs são commitadas**, e o usuário não tem como saber
  disso. É a mesma família dos cinco comportamentos que o `config/schema.md` promete e o runner
  não tem, mas com um agravante: aqui a chave parece funcionar porque o default e a convenção
  do agente coincidem. Direção: ou o runner passa `E2E_DIR` ao prompt da fase QA, ou a chave sai
  do schema. Está congelada na catraca `tests/health-baseline.txt` até então. — descoberto por
  `sdd health` na missão `20260814-i13.2-mutacao-health` (2026-08-14)
- [ ] **`cmd_health` é o único comando do runner sem sensor** — `bin/sdd` (`cmd_health`,
  `health_proveniencia`, `health_catraca`) — o catálogo de mutação cobre os 7 gates e o diário,
  e o próprio `sdd health` cobra mutação por gate; mas o `cmd_health` **não é gate**, então
  ninguém sabota as sete checagens dele. O risco é concreto e já se materializou durante esta
  missão: duas das checagens nasceram com a lógica invertida pelo `pipefail` e passaram a
  impressão de estar medindo. Elas foram pegas à mão, não por sensor. Direção: mutações
  `mut_HEALTH_*` (catraca que não reprova achado novo, proveniência que passa com skill
  ausente, contagem de gates sem piso) e um fixture de kit sabotado para o health julgar.
  — descoberto por `humano` na missão `20260814-i13.2-mutacao-health` (2026-08-14)
- [x] **[I13.2 — FEITO em 935ec39] Teste de mutação: a suíte verde não prova que os gates funcionam** —
  **Fechado:** `tests/check-mutation.sh` sabota o `bin/sdd` numa cópia com 15 mutações — uma
  por gate, as três da tabela abaixo e a do diário invertido — e exige a suíte vermelha em
  cada uma. Score **15/15**. `sdd health` reprova abaixo de 100% e cobra mutação por gate.
  As duas lacunas que o catálogo revelou foram fechadas com asserção nova (`TEST_CMD`
  vermelho) e fixture verbatim (legenda do enum do registry de bugs). Suíte: 3,7s → 12,2s.
  Registro completo no `KAIZEN_LOG.md`.
  Detalhe histórico preservado abaixo —
  `tests/check-mutation.sh` (novo) + `sdd health` — **evidência acumulada: três bugs de gate da
  MESMA família, todos passando pela suíte verde, todos só descobertos em uso real, cada um
  custando sessão paga:**

  | # | Bug | Como apareceu | Custo |
  |---|---|---|---|
  | 1 | `gate_QA` exigia `**Status:**` no início da linha; o template da skill põe `- **Started:** … · **Status:** …` | relatório nunca casava; runner re-rodou `qa-execution` | ~US$ 15/volta |
  | 2 | A mesma âncora vivia **duplicada** em `gate_QA` e `qa_substep`; corrigi uma e a outra divergiu | gate aceitava, sub-passo mandava re-executar | ~US$ 15/volta |
  | 3 | `gate_REVIEW` parava a leitura só em `###`; a seção seguinte real é `##`, então engolia as tabelas posteriores | reprovou relatório com 8 critérios A alegando `Commit = O que` | ~US$ 10 |

  O padrão: **toda âncora de formato de skill de terceiro falhou, e nenhuma falhou na suíte.**
  Os fixtures testavam o formato que eu *imaginei*, não o que a skill *emite* — e um fixture
  errado passa verde para sempre. Mutação é o único sensor que pega esta classe: sabotar o gate
  e exigir que a suíte fique vermelha prova que a asserção mede alguma coisa.
  Direção: catálogo de mutações conhecidas em `bin/sdd` (uma por gate, no mínimo), score =
  pegas/aplicadas, e `sdd health` reprovando abaixo de 100%. Complemento obrigatório: os fixtures
  passam a usar o formato **copiado da skill**, não escrito de memória.
  — descoberto por `sdd-qa` e por `humano` nas missões `20260814-dry-run-completo` e
  `20260814-sq94-spinner-reblur` (2026-08-14)
- [x] **[FEITO em 935ec39] A suíte não tem teste de mutação, e por isso não percebe asserção que virou decoração** —
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
- [ ] **`gate_DOCS` reprova o `45-docs.md` que menciona o arquivo de achados pelo nome** —
  `bin/sdd:394` — a sentinela de item pendente é `grep -qE '✗|\bTODO\b|<preencher>'`. O `\b` casa
  com o ponto, então a string `TODO.md` **reprova o gate**. Pior: `agents/sdd-docs.md:81` manda o
  agente fechar o artefato com uma seção intitulada *"Entradas de TODO desta missão"* — um título
  que contém a palavra nua e **reprova o gate por construção**. A instrução do agente colide
  frontalmente com o gate que a mede: seguir o agente ao pé da letra garante a reprovação. Verificado empiricamente nesta sessão:
  `ver TODO.md` reprova, `ver TODO_FILE` passa. Consequências: (a) a fase DOCS falha por citar um
  caminho, o que parece bug do agente e não do gate; (b) quem descobrir vai contornar escrevendo
  o nome errado, e o contorno vira convenção silenciosa; (c) pior, um `45-docs.md` legitimamente
  incompleto e um que só cita o arquivo reprovam com a **mesma** mensagem. Direção: ancorar a
  sentinela na coluna Status da tabela em vez do arquivo inteiro (é lá que `✗`/`TODO` significam
  "pendente"), ou trocar por um marcador que não seja também um nome de arquivo do repo —
  `<preencher>` já é dessa família e não tem o problema. Sensor junto: caso em
  `tests/check-gates.sh` com um `45-docs.md` completo que cita o arquivo de achados, afirmando
  que `gate_DOCS` **passa**. — descoberto por `sdd-docs` na missão `20260814-dry-run-completo`
  (2026-08-14)
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
  **RESOLVIDO por `be63c8b`**: os quatro entraram (`sdd why`, `sdd phase`, `--phase`,
  `--max-phases`), exatamente na direção sugerida — uma linha cada, profundidade nos docs. Fechou
  de carona no I13.5.6: o bloco estava sendo reescrito para inglês de qualquer forma, e reescrevê-lo
  duas vezes (uma para traduzir, outra para completar) seria o retrabalho que o kaizen chama de
  desperdício. — `humano` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)
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
  **RESOLVIDO por `be63c8b`**: virou um aviso de três linhas logo abaixo do bloco de instalação,
  dizendo o que o probe prova, quanto custa e para não rodar em laço. Ficou maior que a meia linha
  sugerida de propósito — o que torna o preflight caro é justamente o que o torna valioso, e essa
  parte precisava caber na mesma frase. — `humano` na missão `20260815-i13.5-kit-em-ingles`
  (2026-08-15)
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
- [ ] **`BUDGET_PER_PHASE_USD` é global, mas o custo por fase não é** — `config/schema.md`,
  `bin/sdd` (`run_phase`) — o teto único de US$ 15/sessão foi calibrado por palpite. Medido em
  duas missões: as fases de julgamento encostam nele e as mecânicas ficam longe. Piloto SQ-97:
  TICKET 2,56 · EXEC 7,37 · QA:plan 6,90 · **QA:exec 14,84** · QA:close 9,08; missão do kit:
  **REVIEW 14,76**. Duas fases a menos de 2% do teto significa que a próxima sessão um pouco
  mais pesada morre por dinheiro no meio do trabalho — e o runner interpreta isso como "a sessão
  não avançou", gastando a retentativa contra a mesma parede. Direção: teto **por fase**
  (`BUDGET_EXEC_USD`, `BUDGET_QA_USD`, …) com o global de default. Sensor durável: o gate reprovar
  com motivo explícito quando o custo da sessão ficar a menos de 5% do teto, em vez de tratar
  como sessão improdutiva. — descoberto por `humano` no piloto SQ-97 (2026-08-14)
- [ ] **Contexto não é gargalo hoje, e isso deveria estar escrito** — `docs/pipeline.md`,
  `config/schema.md` — medição das 6 sessões do piloto SQ-97: picos de 184k a **289k tokens**,
  **zero compactações** em todas (`claude-opus-5`). O anti-estouro do plano funciona por
  construção — sessão por fase mantém a mais pesada em 289k em vez de somar ~1,4M —, mas isso
  nunca foi medido nem documentado, então é fé, não evidência. Registrar os números no
  `docs/pipeline.md` e documentar que `--autocompact` (aceita `auto` ou 100k–1M) é uma alavanca
  disponível e hoje **não usada** pelo runner, para um repo-alvo maior que estoure. — descoberto
  por `humano` no piloto SQ-97 (2026-08-14)

- [ ] **O kit fala PT-BR na prosa, e isso o tranca a um idioma** — `agents/*.md`, `bin/sdd`
  (mensagens e comentários), `docs/`, `README.md` — o **contrato** já é inglês (`pending`, `doing`,
  `done`, `blocked`, `auto`, `skipped`, todas as chaves de config); o que está em PT-BR é a prosa.
  Para o kit ser usável por quem não fala português, a forma certa **não** é traduzir tudo e
  perder os artefatos em PT-BR: é **o kit falar inglês e o idioma de saída virar config**
  (`OUTPUT_LANG` no `.sdd/config.sh`), de modo que os agentes escrevam handoffs, commits e PR no
  idioma do repo-alvo. Sensor: nenhuma string PT-BR fora de `templates/` e `config/examples/`.
  Zero mudança de comportamento. ⚠️ **Dívida de tradução**: todo incremento escrito antes disto
  precisa ser re-traduzido depois — por isso a ordem importa mais que o tamanho. — decidido por
  `humano` em 2026-08-14
  **RESOLVIDO por `be63c8b`** (I13.5, 6 commits): a superfície do kit — `bin/sdd`, os 6 agentes
  (mais as cópias em `.claude/agents/`), `docs/`, `README.md`, `config/schema.md`,
  `config/starter.conf` e `tests/` — passou de **1.517 linhas acentuadas em 24 arquivos para 0**.
  `OUTPUT_LANG` entrou em `load_config()` e no `boot_prompt()` com default **vazio**, então repo
  já instalado produz prompt byte a byte igual ao de antes; a mutação 16 (`RUN_ignores_output_lang`)
  prova que o runner não engole o pedido em silêncio. O sensor pedido virou `tests/check-lang.sh`
  com catraca bidirecional, e o escopo dele ficou mais estreito do que esta entrada supunha (ver
  as duas entradas novas abaixo): `templates/`, `config/examples/`, `TODO.md`, `KAIZEN_LOG.md`,
  `CLAUDE.md` e `docs/handoffs/` são **conteúdo em `OUTPUT_LANG`**, não superfície — este repo
  declara `pt-BR` e por isso eles continuam em português por decisão, não por dívida.
  — `humano` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **O contrato de artefato ainda é PT-BR em cinco pontos** — `bin/sdd` (as chamadas de
  `frontmatter`), `templates/missao.md`, `agents/*.md`, `tests/` — o I13.5 traduziu a superfície,
  mas sobraram 3 chaves de frontmatter (`aprovacao`, `versao`, `titulo` — 45 referências) e 2 nomes
  de artefato (`00-missao.md`, `01-plano.md` — 72 referências). É o único lugar onde um repo-alvo
  anglófono ainda vê português **obrigatório**, e o `OUTPUT_LANG` não resolve: isso é contrato, não
  prosa. ⚠️ A entrada do I13.5 afirmava que "o contrato já é inglês" — **estava errada**, medido
  nesta missão. Deixado fora do escopo de propósito, mas **o motivo que escrevi primeiro estava
  errado e vale corrigir**: eu disse "renomear quebra toda missão em voo (o `sales_quote` tem
  uma)" e fui conferir — o **PR #105 foi mergeado em 2026-08-14**, e a única missão que resta lá
  (`20260814-sq94-spinner-reblur`) deriva `EXEC` por estado **pós-merge**, não por trabalho
  pendente: `sdd why` responde que o commit `5048fe5` do checkpoint existe mas não é alcançável a
  partir do HEAD atual (o checkout está noutra branch e o merge reescreveu o hash). Não há missão
  em voo. O que sobra de custo real são as 117 referências e os diretórios de missão **já
  encerrados**, que só quebrariam num `sdd status` sobre história antiga. Continua sendo missão
  própria pelo **tamanho**, não por risco de perder trabalho — o que sobe a prioridade dela.
  Direção: `approval`/`version`/`title` + `00-mission.md`/`01-plan.md`, com o runner aceitando os
  dois nomes por uma janela. — descoberto por `humano` na missão `20260815-i13.5-kit-em-ingles`
  (2026-08-15)

- [ ] **`templates/` é single-language, e o kit não tem como servir dois idiomas** —
  `templates/*.md` — os templates são conteúdo em `OUTPUT_LANG`, mas moram no kit numa cópia só,
  em PT-BR. Um repo-alvo com `OUTPUT_LANG="en"` recebe o prompt de boot certo e um template em
  português, e o `sdd install` nem os copia: o `sdd-planner` os lê direto de `$SDD_HOME`. Não morde
  hoje porque todo repo-alvo é PT-BR. Direção: ou `templates/<lang>/` com fallback, ou templates
  com estrutura inglesa e prosa-guia curta que o agente reescreve em `OUTPUT_LANG` — a segunda
  opção mexe no contrato que `check-templates.sh` mede, então vem depois da entrada acima.
  — descoberto por `humano` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **O `bin/sdd` promete macOS na mensagem de erro e não roda lá** — `bin/sdd:18-21` vs
  `state_fingerprint()` e `pipeline_log_line()` — a checagem de versão diz *"On macOS: brew install
  bash"*, o que promete que resolvido o bash o kit roda. Não roda: o runner usa `md5sum` (3
  ocorrências) e `date -Iseconds` (5), que **não existem** no macOS de fábrica (é `md5` e o `date`
  do BSD não tem `-I`). A suíte é pior — `sed -i` sem argumento aparece **43 vezes**, forma que o
  `sed` do BSD rejeita, e o `tests/check-lang.sh` acrescentou 1 `grep -P` (PCRE, ausente no `grep`
  do BSD). **Pré-existente, e a nova dependência não muda a classe**: o kit já era GNU-only antes
  do I13.5 (41 `sed -i`, 3 `md5sum`, 5 `date -Iseconds` em `origin/main`). O defeito é a
  **mensagem prometendo um mundo que não existe** — a mesma família do `config/schema.md`
  prometendo chave não implementada. Decidir um dos dois: (a) assumir GNU e trocar a linha 21 por
  um aviso honesto ("o kit exige coreutils GNU; no macOS: brew install coreutils gnu-sed grep"), ou
  (b) portar de verdade (`md5` fallback, `date -u +%FT%TZ`, `sed -i ''`, `grep -E` no lugar do
  `-P`). A (a) custa uma linha e para de mentir; a (b) é missão própria. — descoberto por
  `/codereview` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)
  **RESOLVIDO por `fc2fa50`** — escolhida a (a) (decisão humana), com uma correção de rota: parar
  de mentir por mensagem é fraco, então a suposição passou a ser **medida**. Três mudanças:
  (1) a mensagem da linha 21 declara bash 4+ **e** a userland GNU, com o `gnubin` no `PATH`
  (`brew install coreutils` instala como `gmd5sum`/`gdate`, e o kit chama `md5sum`/`date` —
  detalhe que a direção original não previa); (2) `sdd preflight` ganhou um probe **por
  comportamento**, não por presença: `md5sum </dev/null`, `date -Iseconds`, `sort -V </dev/null`
  — presença passaria num mac com o `gnubin` fora do `PATH` e o kit quebraria mesmo assim;
  (3) `tests/check-preflight.sh` (novo, na suíte) prova o probe com shims que respondem como o
  BSD responde. Provado por sabotagem: **probe removido → 3 asserções morrem**; **`command -v`
  no lugar do probe comportamental → 1 asserção morre**. Custo: +0,2s na suíte (medido; o total
  ficou em 15,9s contra 16,1s do HEAD sem a mudança — dentro do ruído da máquina). Escopo do
  probe é o que o **runner** precisa; `sed -i` e `grep -P` são do `TEST_CMD` deste repo, e uma
  suíte vermelha já grita sozinha. Segue **GNU-only por decisão declarada** — a (b) continua
  sendo missão própria, agora sem urgência: o ambiente errado é detectado antes da primeira fase.
  — `humano` (2026-08-15)

- [ ] **Dois arquivos ficam fora do sensor de idioma, e prosa PT-BR pode entrar neles sem ninguém
  ver** — `tests/check-lang.sh` (a função `surface()`) — as exclusões são corretas e estão
  documentadas no arquivo: em `check-templates.sh` as regexes PT-BR **são** o contrato dos
  templates, e em `check-lang.sh` o dicionário e os probes precisam conter o que detectam. Mas o
  custo é real: nesses dois arquivos, prosa em português passa despercebida. Direção que devolve a
  cobertura sem enfraquecer nenhum dos dois: mover o contrato dos templates para um arquivo de
  dados (`tests/template-contract.txt`, colunas arquivo/regex/descrição), deixando o
  `check-templates.sh` como lógica inglesa pura; só o arquivo de dados fica fora da superfície.
  Sobra `check-lang.sh`, que é irredutível e por isso tem o `selftest()`. — descoberto por
  `sdd health`/`check-lang` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **A suíte linta só o `bin/sdd`; `tests/*.sh` ninguém linta** — `tests/run-all.sh:23` — o
  passo "runner lint" roda `shellcheck -S warning` **apenas** no runner. Rodando à mão sobre
  `tests/*.sh` aparece 1 achado real: `tests/check-mutation.sh:164` (`local slug="$1"
  box="$WORK/$slug"` — SC2318). Medido: `local a=1 b=$a` expande `$a` **antes** de o `local`
  rodar, então o `$slug` que vale ali é a variável **global** do laço `for slug in "${CATALOG[@]}"`
  (`:196`), que por coincidência tem o mesmo valor. Funciona hoje; renomeie a variável do laço e
  todo mutante passa a escrever em `$WORK/.rc`, os 16 compartilham um sandbox e correm um por cima
  do outro. Não é vacuidade — o laço de resultados lê `$WORK/<slug>.rc`, não acha, e reprova alto
  com "produced no result" —, mas é armadilha: duas variáveis acopladas por nome através de
  escopos. Direção: `local slug="$1"; local box="$WORK/$slug"` (duas linhas) e estender o passo de
  lint da suíte a `tests/*.sh`. — descoberto por `humano` fechando o achado GNU-only (2026-08-15)
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

- [ ] **`${var:0:200}` só corta por caractere se o locale do processo for multibyte** —
  `bin/sdd:756` (`autonomy_blocked_row`) e `bin/sdd:777` (`autonomy_session_row`) — o comentário
  nas duas funções (`bin/sdd:750-751` e `:773`) promete "character slice", mas isso é verdade só
  sob um locale UTF-8; em `C`/`POSIX` o bash volta a contar **byte**, e nem `bin/sdd` nem
  `tests/run-all.sh` fixam `LC_ALL`/`LANG`. Não é regressão — é igual ou melhor que o `head -c`
  que havia antes — mas a promessa escrita é maior do que a entrega: depende do ambiente de quem
  roda, e ninguém declara isso. Direção: ou fixar o locale no topo de `bin/sdd`, ou trocar o
  comentário por algo que não prometa mais do que garante. — descoberto por `sdd-reviewer` na
  missão `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **O corte UTF-8 de `${var:0:200}` não tem asserção que o cubra** — `bin/sdd:756,777` —
  o guarda natural seria uma mutação em `tests/check-mutation.sh` que restaurasse `head -c 200`
  (a forma antiga, que corta byte a byte). Não entrou: alcançar um `gate_why` longo o bastante e
  multibyte pelo caminho real exige um fixture com ID de incremento gigante, e no jq 1.7 instalado
  o byte inválido resultante vira U+FFFD e sobrevive — o risco degrada em vez de quebrar alto.
  Pode não valer o custo do fixture para o risco que cobre. — descoberto por `sdd-reviewer` na
  missão `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **O fallback `"?"` de `cost_usd` nunca é exercitado por teste nenhum** — `bin/sdd:852`
  (`cost="$(jq -r '.total_cost_usd // .cost_usd // "?"' "$logfile" ...)"`) vs `bin/sdd:794`
  (`cost_usd: ($cost | tonumber? // null)` no construtor do ledger) — todo stub `claude` de
  `tests/check-autonomy.sh` escreve um log de sessão **vazio** (`exit 1` sem stdout, ou `echo
  '{}'`), então o campo chega **vazio** (`""`) para o `jq`, não a string `"?"` que o fallback
  produziria se `total_cost_usd`/`cost_usd` estivessem simplesmente ausentes de um JSON válido.
  O caminho que o fallback existe para cobrir — uma sessão que respondeu, mas sem custo no JSON —
  segue sem sensor. Direção: um stub que emita `{"other_field": 1}` (JSON válido, sem custo) e
  afirme `cost_usd == null` no ledger. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **`--max-phases` custa uma avaliação de gate a mais, e nenhum teste do repo o exercita** —
  `bin/sdd:1489-1498` vs `bin/sdd:1369` — a ordem ficou: `gate_"$phase"` roda (`:1490`) e escreve a
  linha do ledger **antes** de checar `$phases_run -ge $max_phases` (`:1496`), de propósito — é o
  que garante que a última fase projetada ainda ganhe registro no ledger. O custo é um `TEST_CMD`
  a mais rodando na última iteração de um `sdd run --max-phases N`, que ninguém mediu porque
  `--max-phases` não aparece em `tests/check-dry-run.sh`, `tests/check-gates.sh` nem
  `tests/check-autonomy.sh` — a flag existe desde antes do I13.1 e segue sem sensor próprio.
  Direção: um caso em `check-dry-run.sh` ou `check-autonomy.sh` com `--max-phases 1`, afirmando
  que só uma linha de ledger é escrita e que a mensagem "reached" aparece. — descoberto por
  `sdd-reviewer` na missão `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **`current_phase()`/`next_pending_phase()` dependem inteiramente da memoização do
  `run_check_cmd` para serem baratas, e isso não tem sensor** — `bin/sdd:475-492`
  (`current_phase`, `next_pending_phase`) vs `bin/sdd:193-210` (`run_check_cmd`,
  `invalidate_checks`) — as duas reavaliam o gate de **toda** fase a cada chamada (um `for ph in
  $PHASES` completo), e isso só é barato porque `run_check_cmd` cacheia por `$cmd` em
  `_CHECK_RC`/`_CHECK_LOG` e `invalidate_checks` só é chamado depois de um `run_phase` de verdade.
  Quem mexer em **quando** `invalidate_checks` roda (por exemplo, chamá-lo também numa iteração de
  dry-run) reintroduz N execuções de `TEST_CMD` por projeção, em silêncio — nenhum teste do repo
  conta quantas vezes `run_check_cmd` de fato executa `eval "$cmd"` versus quantas vezes serve do
  cache. Direção: um sensor que conte invocações reais do `TEST_CMD` (por exemplo, um `TEST_CMD`
  que incrementa um contador em arquivo) num dry-run com várias fases pendentes, afirmando que o
  número não cresce com o número de fases. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **`sdd autonomy` imprime `US$ 2` em vez de `US$ 2.00` para somas em dólar fechado** —
  `bin/sdd:1617` — a expressão `\($cost | . * 100 | round / 100)` do `jq` arredonda certo, mas o
  `jq` imprime número, não string formatada: um total de `2.0` vira `2` na saída, derrubando o
  `.00`. Cosmético — o número está certo — mas quebra o alinhamento de uma tabela que existe
  para ser lida rápido, e um leitor apressado pode ler `2` como "sem casas decimais calculadas"
  em vez de "duas sessões de um dólar". Direção: `printf` no lugar da interpolação do `jq`, ou
  `\($cost * 100 | round / 100 | tostring | if test("\\.") then . else . + ".00" end)`. —
  descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **`cmd_autonomy` usa a mesma mensagem de `die` para dois defeitos diferentes** —
  `bin/sdd:1583` e `bin/sdd:1626` — as duas chamadas escrevem exatamente `"malformed row in $file
  — the ledger is not readable"`: uma cobre JSON **sintaticamente inválido** (`jq -se .` falha) e
  a outra cobre JSON **válido mas de shape errada** (um array em vez de um objeto — indexar `.event`
  nele é erro de runtime do `jq`, não uma comparação falsa). São causas distintas com correções
  distintas (uma pede editar a linha à mão; a outra pede entender por que o produtor do ledger
  escreveu um valor não-objeto), e quem lê a mensagem não tem como saber qual das duas aconteceu.
  Direção: duas mensagens, ou uma mensagem só com o detalhe do `jq` anexado. — descoberto por
  `sdd-reviewer` na missão `20260815-i13.1-autonomy-log` (2026-08-15)
- [ ] **A suíte estourou o alvo de ≤15s do plano do I13.1** — `tests/run-all.sh` +
  `tests/check-mutation.sh` (`SDD_MUTATION_JOBS`) — medido nesta missão, mesma máquina, 3 rodadas
  de cada lado: merge-base pré-I13.1 (`c8bb535`, mutação 16/16) em 13,88s/13,98s/14,11s (mediana
  13,98s) contra a árvore completa do I13.1 (mutação 19/19) em 22,08s/22,34s/22,35s (mediana
  22,34s) — um aumento de ~8,3s (~60%). A maior parte é o catálogo de mutação: 19 mutantes contra
  16, cada um rodando a suíte inteira num sandbox isolado. `SDD_MUTATION_JOBS` default é 4 e a
  máquina tem 20 núcleos — subir o paralelismo é uma alavanca não usada que poderia absorver boa
  parte do aumento sem cortar cobertura. Decisão fica para o humano: subir o alvo do plano, subir
  o default de `SDD_MUTATION_JOBS`, ou aceitar o custo como o preço de medir a própria autonomia.
  Não "consertado" cortando mutação ou asserção — isso violaria o próprio princípio que motivou a
  missão. — descoberto por `sdd-executor` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

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
