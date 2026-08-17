# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).

Formato:

```md
- [ ] <o quê> — `arquivo:linha` — <por que importa> — descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)
```

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

## Aberto

> **Ciclo de vida.** Um item cujo corpo traz **RESOLVIDO por `<hash>`** já está fechado: fica
> aqui, com a caixa ainda desmarcada, só até o PR da missão que o fechou ser mergeado — é dali
> que o PR cita a evidência. **Depois do merge ele é apagado**, não arquivado: a memória durável
> é o `git log -S`, o `KAIZEN_LOG.md` e os handoffs, e cada item já cita o hash que o fecha.
> Ler a caixa sem ler o corpo dá falso positivo; o corpo é a fonte da verdade.
>
> **Uma convenção só.** `- [x]` e `[FEITO em <hash>]` no título **não** existem mais neste
> arquivo — fechado é apagado, e caixa marcada era invisível para a triagem do kaizen, que
> procura `RESOLVIDO por`. Apagar prova por artefato: `git merge-base --is-ancestor <hash> main`
> antes de remover, nunca o rótulo do PR.
>
> **Teto de tamanho.** Um item cabe em ~6 linhas: o quê + `arquivo:linha` + por que importa +
> direção + quem descobriu. A análise longa mora no handoff da missão citada. `tests/check-todo.sh`
> mede a forma e o teto.

### Sensores que faltam

- [ ] **A linha `N kit agent(s) checked` não é observável por nenhum fixture** — `bin/sdd:1356` —
  ela só sai com `fails -eq 0`, e todo fixture offline reprova antes (o probe do `claude` e o
  `gh auth status`). O I3 provou o ramo de falha por diferencial, mas o ramo de sucesso — a frase
  que o operador de fato lê — segue sem sensor. Direção: um `--skip-session` no preflight, ou um
  contador de agentes impresso fora da guarda de `fails`.
  — descoberto por `sdd-executor` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **A guarda de read-back do `sdd approve` é regra sem probe** — `bin/sdd:1766` — o comando
  relê o `aprovacao:` pelo mesmo parser do gate antes de commitar, para o caso de a chave não
  existir no frontmatter (aí o `frontmatter_write` é no-op e o commit aprovaria nada). Sabotar a
  guarda deixa as 3 asserções verdes: nenhum fixture tem missão sem a chave. Direção: um quarto
  fixture, junto de rever o Check que fixa a contagem em 3.
  — descoberto por `sdd-executor` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **A ordem checkout-antes-do-aviso é regra sem probe no `cmd_run`** — `bin/sdd:1865-1869` —
  inverter as duas linhas deixa a suíte inteira verde: o fixture do par diferencial da branch base
  não declara `branch:`, então os dois usos são indistinguíveis nele. Invertido, o `sdd run` avisa
  que vai commitar na base um humano que ele tira da base na linha seguinte — aviso falso, e é
  assim que se aprende a não ler aviso. O `cmd_retry` ganhou a asserção (`3ffa586`); o `cmd_run`
  não. Direção: espelhar a asserção com fixture que declara branch inexistente.
  — descoberto por `sdd-executor` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **Aprovar plano é editar frontmatter à mão — o gate humano é a única interação sem
  comando** — `bin/sdd` (não existe `cmd_approve`) vs `gate_PLAN` (`:261`) — destravar a fase
  PLAN exige abrir o `00-missao.md` e digitar `aprovacao: humano-YYYY-MM-DD` no formato exato.
  Sem apresentação do que se aprova, sem data automática, sem commit: convida a errar o formato
  ou a delegar à sessão, que é justamente quem não pode decidir. RESOLVIDO por `96a1f68`:
  `sdd approve <missão>` imprime, pergunta `[y/N]`, escreve com `date +%F` e commita só o
  `00-missao.md`. — descoberto por `humano` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **Duas regras conflitantes sobre `aprovacao:`, e só um comando aplica a restrição** —
  `agents/sdd-planner.md:111` ("all ✅ → `aprovacao: auto`") vs `agents/sdd-kaizen.md:113`
  ("EMPTY, always") — plano kaizen-born com PLAN-AUTO toda ✅ dá ao planner licença textual para
  `auto`, e a premissa que a justifica ("the human was present") é falsa em sessão headless.
  `gate_PLAN` aceita `auto` e o pipeline vai até o PR; quem reclama é a volta seguinte do
  `sdd kaizen`, com rc 3 (`bin/sdd:2151`). Direção: o prompt da fase PLAN dizer ao planner que o
  plano nasceu do kaizen. — descoberto por `humano` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **O parser do checkpoint não conhece `\|`, o escape padrão de pipe em tabela GFM** —
  `bin/sdd:174` (`checkpoint_rows`, `awk -F'|'`) — o split é cru, então célula com `\|` vira
  duas. Medido no checkpoint nascido em `df86387`: 3 dos 4 incrementos deram `NF=8` contra `NF=7`
  do limpo, e o runner leu Status=`` `grep -c '…'` `` e Commit=`pending`. `gate_EXEC` reprova com
  "invalid status", e `sdd status` imprime `pending` na coluna Commit — plausível e errado. O
  gatilho é Check que canaliza sensor para `grep`; nem o template nem checkpoint anterior o tinha.
  Direção: tratar `\|` antes do split, com asserção. — descoberto por `sdd status` na missão
  `20260816-kit-como-alvo` (2026-08-16)

- [ ] **O `40-review-r<N>.md` é o único artefato com gate e sem template** — `templates/` — os
  outros cinco têm (`missao`, `plano`, `checkpoint`, `handoff`, `pr-body`), e é justamente o do
  review que o `gate_REVIEW` lê por regex literal (`^###[[:space:]]+Overall Grade`, `bin/sdd:409`).
  Evidência: as rodadas r1 E r2 desta missão escreveram `## Overall Grade` e o gate devolveu
  `NO-TABLE` — duas sessões independentes derivando igual. Direção: `templates/review.md` com o
  heading e a tabela, mais a linha no `check-templates.sh`.
  — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **Os dois ramos de diagnóstico do `differential()` não têm probe** —
  `tests/check-entrypoint.sh:234` — a passada adversarial da r2 matou 20 de 25 degradações, e o
  que sobra sem probe é a comparação do próprio diferencial: neutralizá-la faz o sensor ler "1 vs
  1" e seguir verde, então o dia em que o fall-through parar de reproduzir neste bash passa
  despercebido. Hoje o limite é o par de contagens ser IMPRESSO na linha `ok`. Direção: um gancho
  de contagem falsa, como o `SDD_EP_FORCE_FAIL` da composição, com um probe por ramo.
  — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **A regra do `|` na célula do Check é ensinada em prosa e medida no scan, mas nenhum
  `doc_rule` a cobra** — `tests/check-checkpoint.sh:239-241` — as duas asserções de documento
  exigem só o âncora `^  ok    `; apagar o banner do `|` de `templates/checkpoint.md` e do
  `sdd-planner` deixa o sensor **verde**, e a regra que custou uma missão inteira volta a nascer
  desconhecida. Direção: um `pipe_rule()` gêmeo, com probe no `selftest()`.
  — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **O `check-todo.sh` mede a FORMA da âncora, nunca se ela ainda aponta o que o item diz** —
  `tests/check-todo.sh:1` — a regra exige `arquivo:linha` e o sensor confere que existe e está bem
  escrito; nada re-deriva o alvo. Medido na fase DOCS desta missão: **15 âncoras em 11 itens**
  apontavam linha errada — a maioria apodreceu (o `bin/sdd` foi de 2287 para 2324 linhas na própria
  missão que as escreveu), três nasceram erradas. É "rótulo, não artefato" dentro do arquivo que
  cataloga essa família. Direção: resolver cada âncora e cobrar que a linha contenha um termo do
  título. — descoberto por `sdd-docs` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O fixture de `stream-json` não tem checagem de proveniência** — `tests/check-autonomy.sh:127`
  — as três linhas replayadas pelos stubs foram copiadas de sessão real (CLI 2.1.233) e o comentário
  registra o comando, mas `health_provenance` (`bin/sdd:1393`) só confere as 3 fixtures de skill
  contra arquivo instalado. Se o CLI renomear `type`/`total_cost_usd`, o stub segue verde e o
  runner quebra só em missão real — o modo de falha que a regra de proveniência existe para matar.
  Direção: probe que rode o CLI de verdade, ou capturar o schema num arquivo versionado.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`.sdd/logs/` não tem poda e agora guarda o stream inteiro** — `bin/sdd:213` — desde o I10
  cada sessão deixa três arquivos, e o `.stream.jsonl` é a sessão toda (a de teste, trivial, deu
  ~40 KB; uma fase real de 10 min é ordens de grandeza maior). Nada apaga nada: o diretório cresce
  por missão para sempre, e é justamente o que o humano vai querer abrir. Não é urgente — é
  gitignored e local. Direção: reter as N sessões mais recentes por missão, ou comprimir o stream
  ao fim da fase. — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O `sdd preflight` não prova que a sessão headless executa `TEST_CMD`** — `bin/sdd:646` —
  a causa original (falta de `--allowedTools`) foi corrigida em `2083680` e provada pela sessão
  EXEC `357b401`, mas nada impede a regressão silenciosa: o preflight só valida que o `claude -p`
  responde, não que ele **roda comando**. Sem isso, a fase EXEC volta a ser insatisfazível por
  construção sem nenhum sensor gritar. Direção: probe headless real que execute `TEST_CMD`.
  — descoberto por `sdd-executor` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **Sensor pulado por `SDD_MUTANT` vira ponto cego sem aviso** — `tests/run-all.sh:103,112,119` —
  três sensores são pulados dentro do mutante (dois por "não é gate, nunca pontua"; o do I5,
  `check-pipefail.sh`, por motivo próprio). É aposta que vence sozinha: no I3 o `check-preflight.sh`
  ganhou asserção de comportamento do runner, e a linha que o pulava virou a escondedora da única
  sensora de `RUN_install_no_guard`. O sintoma chega como "mutação não capturada", e o conserto
  tentador é `KNOWN_GAPS`. Direção: reprovar guarda de `SDD_MUTANT` em arquivo que invoca `bin/sdd`.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`check-autonomy.sh` é vermelho intermitente, causa desconhecida** — `bin/sdd:972` —
  ⚠️ **A causa registrada foi REFUTADA; o sintoma segue aberto.** Era "colisão de nome de log em
  repo que versiona `.sdd/logs/`", e não se sustenta: `check-autonomy.sh:140` chama
  `sdd install` ANTES de existir log, e `bin/sdd:1125` já põe `.sdd/logs/` no `.gitignore` —
  `git ls-files` no fixture lista só `.sdd/config.sh`. Colisão é a norma (8 sessões EXEC no mesmo
  segundo num run) e a árvore fecha limpa. Não reproduziu em **152 runs**. Direção: `%N` é no-op;
  medir de novo antes de consertar. — refutado por `sdd-reviewer` (r2), descoberto por
  `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`grep -m<N>` é a mesma corrida do `grep -q`, e nenhum sensor a vê** —
  `tests/check-dry-run.sh:234` — `-m1` também sai no primeiro casamento e mata o escritor com
  SIGPIPE, então sob `pipefail` o pipeline devolve 141 igual. A ocorrência de hoje é inofensiva
  (está no ramo de `fail`, capturada em substituição, não em condição), mas o
  `tests/check-pipefail.sh` do I5 declara a lacuna em vez de fechá-la. Direção: estender a regex
  para o par `-m`/`--max-count` e converter as ocorrências no mesmo commit.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O gate PLAN-AUTO aceita Check que já nasce verde** — `templates/missao.md:44` — o critério
  `d` cobra "Check executável (comando → esperado)", não "Check que
  reprova o HEAD de hoje". Medido: o Check do I1 desta missão era `grep -c 'gate_DOCS reprova'
  TODO.md` → `0`, mas o título no `TODO.md` traz crases (`` `gate_DOCS` reprova ``), então o
  comando já devolvia `0` **antes** da remoção — verde por construção, exatamente o que a casa
  proíbe em teste. Direção: o planner roda cada Check contra o HEAD e registra o vermelho.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **Check de ausência (`grep -c X` → `0`) reprova o conserto que precisa citar o defeito** —
  `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` — o comentário honesto que
  **desmente** a promessa "CHARACTER slice" precisa nomeá-la, e o Check literal deu `1`, não `0`.
  Distinto do item acima: rodar o Check contra o HEAD dá vermelho de verdade e a armadilha fica.
  Direção: Check de ausência mira o código, nunca a prosa. — descoberto por `sdd-executor` na
  missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **A asserção "dry-run não toca no disco" promete mais do que entrega** —
  `tests/check-dry-run.sh:116` — ela roda sobre fixture parado em EXEC, cujo gate reprova antes de
  chegar ao `TEST_CMD`. Num fixture que alcance `gate_REVIEW`, o dry-run escreve
  `.sdd/logs/<missão>/gate-*-test-*.log` (reconfirmado no repo real, volta 2 da QA). Não é bug —
  é comportamento aceito e gitignored —, mas o nome garante mais que o teste. Direção: renomear
  para "não toca nos artefatos da missão" ou exercitar também num fixture que chegue ao REVIEW.
  — descoberto por `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **Nenhum gate confere a branch declarada, e ninguém faz o checkout** — todos os `gate_*` +
  `templates/missao.md` (campo `branch:`) — no SQ-97 o checkout mudou entre `QA:plan` e `QA:exec`
  e **cinco fases commitaram na branch errada**: 16 commits sobre um PR alheio, todos os gates
  verdes, pego só pelo `sdd-publisher` no fim da linha, a ~US$ 45 de `rebase --onto`. Repetiu um
  passo antes hoje: plano declarando `missao/20260816-kit-como-alvo`, humano trocando à mão.
  RESOLVIDO por b3b8c2f: `ensure_mission_branch()`, uma definição em `cmd_run` e `cmd_retry` —
  existe ⇒ checkout, não existe ⇒ cria da ATUAL, placeholder ⇒ no-op, git recusa ⇒ `die`.
  — descoberto por `sdd-publisher` e `humano` no piloto SQ-97 (2026-08-14)

- [ ] **A regra da âncora é satisfeita por código inline no título** — `tests/check-todo.sh` (regra
  3) — ela pede crase não-vazia antes do último ` — `, e o título entra nesse trecho: medido, **45
  dos 46 itens passariam com o `file:line` apagado**. Apertar exige teste de forma que os dados
  reais não sustentam (`git worktree` e `KAIZEN_LOG` são âncoras legítimas). Não esconde achado
  fechado — para isso servem a regra 2 e a lista-branca. — descoberto por `revisao-adversarial`
  na 8ª rodada de revisão do sensor (2026-08-16)

- [ ] **A regra da cauda quebra com travessão dentro das crases de atribuição** —
  `tests/check-todo.sh` (`last_sep`) — o corte é no último ` — ` e não conhece code span, então
  `— por \`x\` na missão \`a — b\` (data)` reporta "the last field names no `<agent>`" num item
  bem formado. Direção: mascarar code spans antes de cortar. — descoberto por
  `revisao-adversarial` na 8ª rodada de revisão do sensor (2026-08-16)

- [ ] **O formato de achado vale para os repos-alvo, mas o sensor só guarda o arquivo do kit** —
  `tests/check-todo.sh` vs `CLAUDE.md` (princípio 5) — a regra de formato e o ciclo "fechado é
  apagado" são prescritos para o `TODO.md` de **qualquer** repo, e os agentes escrevem nos dois;
  o sensor mora na suíte do kit e nunca é instalado. Um alvo acumula o mesmo inchaço sem nada
  medindo. Direção: `sdd install` copiar o sensor (ou uma versão dele) e o `starter.conf` sugerir
  incluí-lo no `TEST_CMD`. ⚠️ As regras já são estruturais e language-neutral de propósito, então
  ele roda num alvo `OUTPUT_LANG="en"` sem mudança. — descoberto por `humano` revisando o sensor
  novo (2026-08-16)

- [ ] **Caixa marcada na linha SEGUINTE ao marcador escapa da regra 2** — `tests/check-todo.sh`
  (regra 2) — a regra é por linha e exige marcador e `[x]` juntos; o GFM marca a caixa quando o
  primeiro bloco do item é um parágrafo abrindo com `[x] `, e a linha do marcador pode sumir do
  AST (marcador vazio, ou link-reference definition). Achado fechado renderiza marcado com rc 0
  num arquivo de aparência saudável, contra o que o cabeçalho do sensor afirma (linhas 67-69,
  179). Patch e repros: [handoff](docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md).
  — descoberto por `revisao-adversarial` na 12ª rodada de revisão do sensor (2026-08-16)

- [ ] **`cmd_health` é o único comando do runner sem sensor** — `bin/sdd` (`cmd_health`,
  `health_proveniencia`, `health_catraca`) — o catálogo cobre os gates e o diário, e o próprio
  health cobra mutação por gate, mas ninguém sabota as checagens dele. Já mordeu: duas nasceram
  com a lógica invertida pelo `pipefail` e foram pegas à mão, não por sensor. Direção: mutações
  `mut_HEALTH_*` (catraca que não reprova achado novo, proveniência que passa com skill ausente).
  — descoberto por `humano` na missão `20260814-i13.2-mutacao-health` (2026-08-14)

- [ ] **A suíte não exercita `--max-phases`, e ele custa uma avaliação de gate a mais** —
  `bin/sdd:1489-1498` vs `:1369` — o gate roda e escreve a linha do ledger **antes** de checar o
  limite, de propósito (a última fase projetada ainda ganha registro), mas o `TEST_CMD` extra na
  última iteração nunca foi medido: a flag não aparece em nenhum dos três sensores de runner.
  Direção: caso com `--max-phases 1` afirmando uma linha de ledger e a mensagem "reached".
  — descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A economia de `current_phase()`/`next_pending_phase()` depende da memoização e ninguém
  conta** — `bin/sdd:475-492` vs `:193-210` — as duas reavaliam o gate de toda fase a cada
  chamada, e isso só é barato porque `run_check_cmd` cacheia por `$cmd`. Quem mexer em **quando**
  `invalidate_checks` roda reintroduz N execuções de `TEST_CMD` por projeção, em silêncio.
  Direção: `TEST_CMD` que incrementa contador em arquivo, afirmando que o número não cresce com
  o número de fases pendentes. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **O fallback `"?"` de `cost_usd` nunca é exercitado** — `bin/sdd:852` vs `:794` — todo stub
  `claude` da suíte escreve log **vazio**, então o campo chega `""` ao `jq`, não a string `"?"`
  que o fallback produz quando o JSON é válido mas não traz custo. O caminho que o fallback
  existe para cobrir segue sem sensor. Direção: stub que emita `{"other_field": 1}` afirmando
  `cost_usd == null` no ledger. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **O corte UTF-8 de `${var:0:200}` não tem asserção** — `bin/sdd:756,777` — a guarda natural
  seria uma mutação restaurando `head -c 200` (corte por byte), mas alcançar um `gate_why` longo
  e multibyte pelo caminho real exige fixture com ID de incremento gigante, e no jq 1.7 o byte
  inválido vira U+FFFD e sobrevive: o risco degrada em vez de quebrar alto. Pode não valer o
  custo do fixture. — descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log`
  (2026-08-15)

- [ ] **Duas asserções do ledger não têm mutação catalogada** — `tests/check-autonomy.sh` ("the
  two session rows share one session id" e "sdd retry that changed the disk records moved:true")
  — a revisora verificou à mão que as duas discriminam (reverter `LAST_PHASE_SID` derruba a
  primeira; no-op no `moved` do `cmd_retry` derruba a segunda), mas nenhuma sabotagem está no
  catálogo. A regra "gate novo entra com mutação" é sobre gate, não sobre toda asserção nova.
  — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A asserção "the retry carries its own moved" não falha pela propriedade que promete** —
  `tests/check-autonomy.sh:208` — no fixture, `moved` sai `false` com qualquer baseline: o retry
  só é alcançado quando `before == after`, então a asserção nunca observa um `moved:true` genuíno
  pelo caminho real. Ainda pega campo ausente ou `moved` sempre-`true`; só o nome discrimina mais
  do que ela. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **`cmd_kaizen` tem partes sem mutação própria** — `bin/sdd` (`kaizen_reminder`, ramo
  "already judged" idempotente) — as 5 mutações do catálogo cobrem `gate_KAIZEN` cego, Jidoka
  morto, guarda ignorada, bailout de aprovação morto e a régua de rótulos; o lembrete e a
  idempotência têm asserções em `tests/check-kaizen.sh` sem sabotagem que prove que medem algo.
  — descoberto na execução do `i13.3-sdd-kaizen` (2026-08-15)

- [ ] **Três das quatro metades do evento `degraded` não têm mutação** — `bin/sdd:1796` (o
  `select` da série), `:1544` (`pipeline_log_line`) e `:1707` (`is_escalation` do `cmd_autonomy`)
  — o I2 entrou com uma mutação só porque o Check do incremento fixava o score, e sabotar várias
  âncoras num mutante derrubaria a detecção de "âncora apodreceu". As três foram sabotadas à mão
  e as três mataram a suíte, mas evidência de sessão não roda no CI. Vale um mutante para cada
  quando houver folga de régua. — descoberto por `sdd-executor` na missão
  `20260815-ledger-sem-ponto-cego` (2026-08-16)

- [ ] **A guarda do juiz é insatisfazível quando o kit desenvolve a si mesmo** — `bin/sdd:2024`
  (`sufficient: ($observed >= 3)`) vs `autonomy_kit_stamp` — o eixo é o `HEAD` do kit no instante
  de CADA linha, e a fase EXEC commita no `bin/sdd` entre sessões: medido, **24 kit_sha distintos
  no ledger, todos com exatamente 1 sessão, nenhum com 2**. A guarda pede 3 missões no MESMO sha,
  então `sufficient` é `false` por construção aqui. Não é bug em alvo (lá o kit não muda na
  missão) — é o eixo degenerando no repo que o desenvolve, e trava o I13.4. Direção: rodar missão
  em alvo real, ou carimbar o sha uma vez por missão — decidir qual pergunta o juiz responde.
  — descoberto por `humano` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O schema da série não tem sensor de drift contra a prosa que o descreve** — `bin/sdd:1976`
  vs `docs/pipeline.md:366` e `agents/sdd-kaizen.md:30` — o objeto que o juiz é mandado citar é
  produzido em dois lugares (o `jq` e o literal do ledger vazio, `:1902`) e descrito em dois
  outros; o `sdd health` mede drift de doc/config e gate-sem-mutação, mas nada casa os campos do
  `guard` com quem os promete. Campo novo esquecido passa verde. Direção: extrair os campos do
  `jq` e cobrá-los na doc. — descoberto por `sdd-executor` na missão
  `20260816-runner-sem-dividas` (2026-08-16)

### Contrato e configuração

- [ ] **O lembrete pós-pipeline manda o humano a um comando que não enxerga o que ele contou** —
  `bin/sdd:2147` (`kaizen_reminder`) vs `:2300` (`cmd_kaizen`) — o lembrete roda com
  `REPO_ROOT` = repo-ALVO e conta as missões dele; o juiz roda no repo do KIT e, com o filtro por
  repo, lê `latest: null` e `other_repo: N`. Medido em fixture: 3 missões viram "run 'sdd kaizen'
  in the kit repo", e lá a guarda é `0/0/0`. Direção: silenciar o lembrete fora do kit, ou decidir
  o eixo (item da guarda). — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **`sdd retry` é a quarta porta que commita e não avisa da branch base** — `bin/sdd:1868`
  (`cmd_retry` chama `run_phase` sem `warn_if_on_base_branch`) — o comentário da função
  (`bin/sdd:1209`) declara "as três portas que commitam" e o I4 fechou três; a quarta abre sessão
  que commita igual. `sdd retry` na `main` commita na `main` em silêncio. RESOLVIDO por `3ffa586`:
  a chamada entra depois de `ensure_mission_branch` (avisar antes gritaria lobo), o comentário diz
  quatro, e o par diferencial `retry ` + `RETRY_base_branch_warn_dead` seguram.
  — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **Worktree do git parte a identidade do repo no ledger** — `bin/sdd:768`
  (`ledger_repo_root` usa `--show-toplevel`) — o toplevel é por worktree, então missão rodada num
  worktree grava `repo: .../wt` e a mesma leitura do checkout principal a devolve como
  `other_repo` e a série vem vazia. Worktree é fluxo de primeira classe aqui. Direção:
  `git rev-parse --git-common-dir` como identidade, com asserção diferencial.
  — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **Linha sem `repo` é "local" em TODO repo, e o comentário afirma o contrário** —
  `bin/sdd:785` — o comentário diz que os leitores classificam essas linhas em voz alta
  (`unrecognized`, ou morte alta), mas `is_unrecognized` olha `.event` e não `.repo`: linha de
  sessão bem-formada sem `repo` é sessão comparável em toda máquina — 3 delas bastaram para virar
  `guard.sufficient` para `true` em fixture. Hoje são 0 no ledger real. Direção: contar num balde
  próprio. — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **O juiz no repo do kit deixou de enxergar missão de repo-alvo** — `bin/sdd:790`
  (`ledger_row_is_local`) — a leitura por repo é o conserto certo para contaminação de fixture,
  mas o ledger existe para medir maturidade **entre** projetos (`docs/pipeline.md:274`) e nenhum
  leitor consegue mais fazê-lo. Hoje não morde: as 26 linhas reais são todas do kit. Direção: um
  `--all-repos` explícito, ou o eixo do juiz decidido por ADR (item da guarda, acima).
  — descoberto por `sdd-executor` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **`config/schema.md` promete cinco comportamentos que o runner não tem** —
  `config/schema.md:24-25,32-34` vs `bin/sdd:81-82` — `LINT_CMD`, `BUILD_CMD`, `DEV_UP_CMD`,
  `DEV_READY_CMD` e `DEV_READY_TIMEOUT` estão documentados como se o gate de REVIEW e a fase QA
  os usassem; nenhum é lido em lugar nenhum. Um `LINT_CMD` preenchido dá ao usuário um sensor que
  ele acha que tem — pior que não ter. Direção: implementar, ou marcar as chaves como reservadas.
  — descoberto por `sdd-reviewer` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **`E2E_DIR` tem default no runner e é lida só pelo agente** — `bin/sdd:81` vs
  `agents/sdd-qa.md:44` — `: "${E2E_DIR:=e2e}"` é a única ocorrência no runner: nenhum gate ou
  prompt a consulta, e quem usa o valor é a prosa do `sdd-qa`. Mudar a chave **não muda onde as
  specs são commitadas**, e a coincidência entre default e convenção esconde isso. Direção: o
  runner passa `E2E_DIR` ao prompt da fase QA, ou a chave sai do schema. Congelada na catraca
  `tests/health-baseline.txt`. — descoberto por `sdd health` na missão
  `20260814-i13.2-mutacao-health` (2026-08-14)

- [ ] **A fase TICKET recebe agente E slash ao mesmo tempo** — `bin/sdd:491` + `:501` — o
  comentário do `phase_agent()` fixa o invariante ("dois system prompts disputando a sessão é
  ruído"), `QA:plan`/`QA:exec` respeitam e TICKET não: nasce com `--agent sdd-publisher` **e** o
  slash `/ticket open` prependado. É redundante — a skill `ticket` não tem
  `disable-model-invocation` e o `sdd-publisher` já invoca o slash sozinho. Não morde com
  `JIRA_ENABLED=false`. Direção: escolher um dos dois. — descoberto por `sdd-reviewer` na missão
  `20260814-dry-run-completo` (2026-08-14)

- [ ] **O kit não tem `CHANGELOG.md`, e a fase DOCS cobra um** — `agents/sdd-docs.md` (tabela "O
  que atualizar") — o registro durável aqui é `KAIZEN_LOG.md` + handoffs + corpo do PR, e nenhum
  é changelog por versão; há `SDD_VERSION="0.1.0"` em `bin/sdd:5` sem nada que o acompanhe. Toda
  missão cai num `n/a` honesto e repetido. Decidir: criar o arquivo com política amarrada ao
  `SDD_VERSION`, ou tirar a linha do agente. Vale para os repos-alvo também. — descoberto por
  `sdd-docs` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **`BUDGET_PER_PHASE_USD` é global, mas o custo por fase não é** — `config/schema.md` +
  `run_phase` — teto único de US$ 15 calibrado por palpite. Medido: SQ-97 TICKET 2,56 · EXEC 7,37
  · QA:plan 6,90 · **QA:exec 14,84** · QA:close 9,08; missão do kit **REVIEW 14,76**. Fase a 1%
  do teto morre por dinheiro no meio do trabalho e o runner lê como "não avançou". Direção: teto
  por fase com o global de default, e gate que reprove com motivo explícito nesse caso.
  — descoberto por `humano` no piloto SQ-97 (2026-08-14)

- [ ] **O contrato de artefato ainda é PT-BR em cinco pontos** — chamadas de `frontmatter` em
  `bin/sdd`, `templates/missao.md`, `agents/*.md`, `tests/` — sobraram 3 chaves (`aprovacao`,
  `versao`, `titulo` — 45 refs) e 2 nomes de artefato (`00-missao.md`, `01-plano.md` — 72 refs).
  É o único português **obrigatório** para um repo-alvo anglófono, e `OUTPUT_LANG` não resolve
  contrato. Não há missão em voo que a renomeação quebre (PR #105 mergeado): o custo é tamanho,
  não risco. Direção: `approval`/`version`/`title` + `00-mission.md`/`01-plan.md`, com o runner
  aceitando os dois nomes por uma janela. — descoberto por `humano` na missão
  `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **`templates/` é single-language** — `templates/*.md` — são conteúdo em `OUTPUT_LANG` mas
  moram no kit em cópia única PT-BR, e o `sdd install` nem os copia (o `sdd-planner` lê direto de
  `$SDD_HOME`). Um alvo com `OUTPUT_LANG="en"` recebe prompt certo e template em português. Não
  morde hoje porque todo alvo é PT-BR. Direção: `templates/<lang>/` com fallback, ou estrutura
  inglesa com prosa-guia que o agente reescreve — a segunda mexe no contrato que
  `check-templates.sh` mede, então vem depois da entrada acima. — descoberto por `humano` na
  missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

### Saída humana e cosmética

- [ ] **`BLOCKED in <FASE> — N sessions` conta voltas do laço, não sessões** — `bin/sdd:1626` —
  `attempts[$phase]` sobe em toda volta que chega ao topo com a fase, inclusive as que não abrem
  sessão nenhuma. Medido no fixture do I9: REVIEW imprime `3 sessions without satisfying the gate`
  com **1** sessão de REVIEW no ledger, e desde o I9 essa é a última linha que o humano lê quando
  o run encerra. Direção: contar sessões, ou dizer `attempts`. — descoberto por `sdd-executor` na
  missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`sdd autonomy` imprime `US$ 2` em vez de `US$ 2.00`** — `bin/sdd:1617` — o `jq` imprime
  número, não string formatada: um total de `2.0` vira `2` e derruba o alinhamento de uma tabela
  feita para ser lida rápido; um leitor apressado lê "sem casas calculadas". Direção: `printf` no
  lugar da interpolação. — descoberto por `sdd-reviewer` na missão `20260815-i13.1-autonomy-log`
  (2026-08-15)

- [ ] **`cmd_autonomy` usa a mesma mensagem de `die` para dois defeitos** — `bin/sdd:1583` e
  `:1626` — as duas escrevem `"malformed row … the ledger is not readable"`: uma cobre JSON
  inválido, a outra JSON válido de shape errada. As correções são distintas (editar a linha vs
  entender por que o produtor escreveu não-objeto) e quem lê não sabe qual aconteceu. Direção:
  duas mensagens, ou o detalhe do `jq` anexado. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **`sdd autonomy` imprime duas linhas em branco em vez de uma** — `bin/sdd:1649-1652` —
  quando não há escaladas e há linha não reconhecida, sobra espaçamento entre o bloco "no
  comparable sessions" e a linha de exclusão. Cosmético, confirmado por reprodução: nenhuma
  contagem some. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log`
  (2026-08-15)

- [ ] **`cmd_autonomy` repete o bloco "no data" literalmente** — `bin/sdd:1603-1605` e
  `:1620-1622` — as mesmas três linhas (`warn` + `dim` + `return 1`), palavra por palavra. As
  duas guardas são necessárias e checam coisas diferentes; a dívida é de manutenção: quem
  reescrever uma passa a ter duas vozes para a mesma recusa, e é essa mensagem que separa "ledger
  vazio" de "ledger corrompido". Direção: um helper local chamado dos dois pontos. — descoberto
  por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A tabela do `sdd autonomy` ordena versões lexicograficamente** — `bin/sdd:1848` faz
  `group_by(.kit_sha)` (o jq ordena pela chave) enquanto `kaizen_series` deriva
  `latest`/`previous` por primeira aparição no arquivo (`:1969`). Quem ler a última linha da
  tabela como "a versão mais recente" pode ler a errada. É ordem de saída humana, não contagem —
  o I3 alinhou o eixo, não a ordem. Família do `latest_matching`, já fechado. — descoberto por
  `sdd-executor` na missão `20260815-ledger-sem-ponto-cego` (2026-08-16)

### Comentário e registro

- [ ] **O `.claude/napkin.md` é rastreado, cita números da suíte e nenhuma fase pode editá-lo** —
  `.claude/napkin.md:18` — o item 3 diz "~33s no default, mutação 30/30" e "alvo <30s estourado
  por ~3s"; o real desta missão é 44,55 s, 38/38 e ~15 s. Runbook lido toda sessão que afirma um
  ratchet vencido convida a aceitar score menor. A fase DOCS tentou consertar e o harness barrou
  `.claude/` como arquivo sensível, então a drift só é corrigível por sessão com humano presente.
  Direção: decidir se o napkin entra na superfície que o DOCS mantém ou sai do versionamento.
  — descoberto por `sdd-docs` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O que arma a corrida do Jidoka é a POSIÇÃO da linha `blocked`, não o tamanho do
  checkpoint** — `tests/check-gates.sh:229-232` — a grandeza real é quantos bytes sobram para o
  `printf` escrever **depois** do casamento do `grep`: com a linha no fim de um checkpoint de
  1,1 MB o runner pré-conserto parava certo; no começo, queimou 2 sessões. Hoje quem segura é o
  mutante `RUN_jidoka_pipefail`, então não há defeito vivo — é comentário impreciso sobre uma
  invariante não escrita. Direção: dizer "linhas DEPOIS da `blocked`". — descoberto por `sdd-qa`
  na missão `20260815-ledger-sem-ponto-cego` (2026-08-16)

- [ ] **`after2` passou a ser amostrado antes do gate do retry, sem registro da decisão** —
  `bin/sdd:1533-1537` — antes o `after` do retry era lido depois de avaliar o gate; agora é
  antes. Benigno e talvez mais honesto (`state_fingerprint` lê HEAD, listagem e md5 do
  checkpoint, e nenhum gate toca nos três), mas é mudança de comportamento em caminho raro que
  ninguém decidiu nem documentou. — descoberto por `/codereview` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **Contexto não é gargalo hoje, e isso deveria estar escrito** — `docs/pipeline.md`,
  `config/schema.md` — medidas as 6 sessões do SQ-97: picos de 184k a **289k tokens**, **zero
  compactações** (`claude-opus-5`). O anti-estouro funciona por construção — sessão por fase
  mantém a mais pesada em 289k em vez de somar ~1,4M —, mas nunca foi medido nem documentado,
  então é fé e não evidência. Registrar os números e que `--autocompact` é alavanca disponível e
  hoje não usada. — descoberto por `humano` no piloto SQ-97 (2026-08-14)

### Idioma

- [ ] **Dois arquivos ficam fora do sensor de idioma** — `tests/check-lang.sh` (função
  `surface()`) — as exclusões são corretas e documentadas (em `check-templates.sh` as regexes
  PT-BR **são** o contrato dos templates; em `check-lang.sh` o dicionário precisa conter o que
  detecta), mas nesses dois arquivos prosa portuguesa passa despercebida. Direção: mover o
  contrato dos templates para `tests/template-contract.txt` (dados), deixando a lógica inglesa;
  sobra o `check-lang.sh`, irredutível e por isso com `selftest()`. — descoberto por
  `sdd health`/`check-lang` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

### Custo e escala

- [ ] **A suíte segue acima do alvo "<30 s" da D7, mesmo depois do paralelismo** —
  `tests/run-all.sh` — a saída "subir o default" foi tomada e executada (pool + `min(núcleos, 8)`,
  ver KAIZEN_LOG de 2026-08-16): mediana 54,13 s → **32,87 s** na mesma sessão, score 30/30
  intacto. Restam as duas saídas de régua, ambas do humano: subir o alvo da D7 (o "≤15 s" do
  I13.1 já é história) ou aceitar os ~3 s de estouro, que crescem com o catálogo. — medido por
  `sdd-executor` e `humano` nas missões `20260815-ledger-sem-ponto-cego` e no kaizen do
  paralelismo (2026-08-16)

### Adiados por YAGNI

- [ ] **Espelho global de vereditos legível por máquina (JSONL em `~/.sdd/`)** — D3 do
  `CONTEXT.md` adiou até o I13.4 pedir: hoje o veredito vive só no handoff da missão nascida, e
  "vereditos ao longo do tempo" exige varrer `docs/handoffs/*/05-verdict.md`. Criar junto com a
  graduação, nunca antes. — registrado na execução do `i13.3-sdd-kaizen` (2026-08-15)

- [ ] **Multi-missão concorrente exigiria `git worktree` por missão** — hoje é 1 missão por
  branch por vez (YAGNI declarado no plano). Reavaliar se aparecer demanda real. — descoberto por
  `humano` no planejamento (2026-08-14)

- [ ] **Destilar handoffs/`KAIZEN_LOG` para o vault Obsidian continua manual** — avaliar um
  `sdd digest` que gere o rascunho. — descoberto por `humano` no planejamento (2026-08-14)
