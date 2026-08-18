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
>
> **Catraca do volume — crescer é permitido, crescer calado não.** Quantos itens este arquivo
> carrega é o achado `todo-findings <N>` do `sdd health`, congelado em `tests/health-baseline.txt`.
> Reprova nos **dois** sentidos: número que subiu sem registro, e baseline que ficou para trás
> depois de uma faxina. Quem acrescenta item aqui **e** move a linha da baseline no mesmo commit
> está certo — o número tem dono e aparece no diff. Quem só acrescenta descobre no `sdd health`.
> Ela mora lá e não no `TEST_CMD` porque um teto dentro da suíte reprovaria toda missão em voo.
> ⚠️ A contagem sai de `tests/check-todo.sh`, nunca de um `grep -c '^- \[ \]'` — este responde um
> a mais, contando a linha de exemplo do bloco cercado acima.

### Sensores que faltam

- [ ] **A rubrica do auto-teste no `CLAUDE.md` conta cinco sensores e o `grep` devolve seis** —
  `CLAUDE.md:163` — a linha manda conferir por `grep -l selftest tests/` e declara o resultado
  esperado; medido na `main` e no HEAD, os dois devolvem **6**, porque o `jobs_selftest()` do
  escalonador (`tests/check-mutation.sh:63`, entrou em `52414e4`) casa o grep sem ser auto-teste de
  regra. Número escrito à mão em rubrica é a mesma classe do `44 caught of 44` que esta missão já
  tirou de lá. Direção: contar a propriedade (`grep -l '^selftest()' `) ou citar os nomes.
  — descoberto por `sdd-docs` na missão `20260816-portas-do-humano` (2026-08-17)

- [ ] **Fase que morre com a árvore suja faz o runner rederivar EXEC para sempre** —
  `bin/sdd:426` — `gate_EXEC` roda o `TEST_CMD` sobre o working tree, então o vermelho de QUALQUER
  fase em voo é lido como vermelho do EXEC. Medido nesta missão: a REVIEW morreu antes de commitar,
  o `sdd why` respondeu `EXEC: TEST_CMD failed` com os 6 incrementos `done` e o HEAD verde, e sem
  intervenção o runner reabriria o EXEC a ~US$ 25 a volta. Direção: gate que distingue árvore suja
  de HEAD vermelho e escala em vez de rederivar.
  — descoberto por `sdd-executor` na missão `20260816-portas-do-humano` (2026-08-17)

- [ ] **`sdd approve` diz "next: sdd run" com o `gate_PLAN` ainda fechado por outro motivo** —
  `bin/sdd:1950` — o comando roda o gate uma vez no topo, só desiste em `missing *`, e depois de
  commitar imprime o próximo passo sem reperguntar. Medido: com `JIRA_ENABLED=true` e `versao:`
  placeholder, ele aprova, commita, manda `sdd run` — e o `sdd why` seguinte recusa por `versao`.
  Todo motivo novo do gate herda o defeito de graça. Direção: reperguntar o gate depois do commit e
  imprimir `GATE_WHY` em vez do próximo passo (some também o `warn` do checkpoint feito à mão).
  — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **`frontmatter_write` confia em três coisas que não valem sempre** — `bin/sdd:188-218` — o
  `chmod --reference … || true` engole a falha e deixa o artefato 0600 para sempre em userland não
  GNU; o `mv` troca um `00-missao.md` que seja SYMLINK por arquivo comum (o alvo real fica com o
  valor velho, e o commit leva a troca de tipo); e `awk -v v="$valor"` interpreta escape de barra
  invertida — inócuo no único chamador de hoje, armadilha para o segundo. Direção: `warn` no chmod,
  `readlink -f` (ou `die`) no alvo, e valor por `ENVIRON` no awk.
  — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **A branch que a fase TICKET cria nunca chega ao campo que o runner lê** —
  `agents/sdd-publisher.md:98` grava `branch:` no `10-ticket.md`, e `ensure_mission_branch`
  (`bin/sdd:1363`) só lê o `00-missao.md`. Com `JIRA_ENABLED=true` o campo fica no placeholder para
  sempre e a guarda da classe SQ-97 não existe nesses repos — a missão fechou a porta no caminho
  sem JIRA, e a decisão 6 do `00-missao.md` manteve o TICKET fora de escopo de propósito.
  Direção: a fase TICKET escreve o nome criado no `00-missao.md` via `frontmatter_write`.
  — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-17)

- [ ] **A releitura pós-checkout confere o campo `branch:`, não a identidade do plano** —
  `bin/sdd:1405` — se a branch declarada carrega uma cópia ANTIGA do mesmo `00-missao.md` (slug
  reusado, branch velha de mesmo nome), o campo bate, a guarda passa e o pipeline roda contra um
  plano que ninguém aprovou nesta sessão. O comentário da própria função já enuncia o risco ("a
  branch carrying an OLDER copy"). Direção: comparar hash do artefato antes e depois do checkout.
  — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-17)

- [ ] **O `die` de artefato faltando do `sdd approve` é regra sem probe** — `bin/sdd:1842` — o
  comando repete o diagnóstico do `gate_PLAN` (`missing 01-plano.md`) e morre antes de imprimir
  qualquer coisa; os cinco fixtures de approve carregam sempre os três artefatos, então trocar o
  `die` por um `return 0` deixa a suíte inteira verde e o comando passa a commitar aprovação de uma
  missão sem plano. Direção: um sexto fixture só com `00-missao.md`, nomeado fora dos prefixos
  contados. — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **`sdd health` morre mudo quando a suíte está vermelha — o caso que ele existe para relatar**
  — `bin/sdd:1588` — `out="$( … run-all.sh )"; rc=$?` é atribuição de substituição de comando: sob
  `set -e` a suíte vermelha mata o script ali, e o `health_bad "suite red (rc $rc)"` da linha
  seguinte é código morto. Medido: 1 linha de saída e rc 1, sem dizer o que quebrou — os 4 checks
  restantes nunca rodam. Direção: `if out="$(…)"; then` ou `|| rc=$?`, com fixture de suíte vermelha.
  — descoberto por `sdd-executor` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **A linha `N kit agent(s) checked` não é observável por nenhum fixture** — `bin/sdd:1356` —
  ela só sai com `fails -eq 0`, e todo fixture offline reprova antes (o probe do `claude` e o
  `gh auth status`). O I3 provou o ramo de falha por diferencial, mas o ramo de sucesso — a frase
  que o operador de fato lê — segue sem sensor. Direção: um `--skip-session` no preflight, ou um
  contador de agentes impresso fora da guarda de `fails`.
  — descoberto por `sdd-executor` na missão `20260816-kit-como-alvo` (2026-08-16)

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

- [ ] **`check-autonomy.sh` é vermelho intermitente, causa desconhecida** — `bin/sdd:989` —
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

- [ ] **A asserção "the retry carries its own moved" não falha pela propriedade que promete** —
  `tests/check-autonomy.sh:208` — no fixture, `moved` sai `false` com qualquer baseline: o retry
  só é alcançado quando `before == after`, então a asserção nunca observa um `moved:true` genuíno
  pelo caminho real. Ainda pega campo ausente ou `moved` sempre-`true`; só o nome discrimina mais
  do que ela. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **O `moved` do `cmd_kaizen` não tem asserção, logo não pode ter mutação** — `bin/sdd:3103` —
  as outras duas cópias de `[ "$before" != "$after" ] && moved="true"` ganharam mutação nesta
  missão (`cmd_run`, `cmd_retry`); esta foi sabotada à mão e `check-kaizen.sh` **e**
  `check-autonomy.sh` ficaram verdes. Sessão de KAIZEN que move o disco entra no ledger como
  desperdício. Direção: a asserção primeiro, a entrada do catálogo depois.
  — descoberto por `sdd-executor` na missão `20260817-catraca-do-backlog` (2026-08-17)

- [ ] **O schema da série não tem sensor de drift contra a prosa que o descreve** — `bin/sdd:2738`
  vs `:2735`, `:2926`, `docs/pipeline.md:501`, `docs/adr/0003:57`, `agents/sdd-kaizen.md:40` e
  `docs/failure-modes.md:99` — produzido em dois lugares (o `jq` e o literal vazio, `:2558`) e
  descrito em **dez**, QUATRO deles dentro do `bin/sdd`. Cobrado 6×: na DOCS de
  `20260817-eixo-do-juiz`, **oito** dos dez diziam a unidade que o F1 da r3 trocara horas antes
  (sessão → missão) — o ADR que o runner cita, a folha do juiz, e a própria frase que o runner
  IMPRIME. Direção: extrair os campos do `jq` e cobrá-los na doc.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **A fase corrente de um `sdd run` em background só existe na leitura de quem acompanha** —
  `bin/sdd:1080` (`pipeline_log_line`) — o feed durável tem a linha por sessão e as escaladas, mas
  não o `$GATE_WHY` ("2 of 4 increment(s)"), que só vai para stdout. Pior: gate que passa **sem
  abrir sessão** não gera evento nenhum — medido nesta missão, o `QA` passou em silêncio quando o
  `F1` devolveu a suíte ao verde. Direção: emitir `PROGRESS <fase> <motivo>` a cada tentativa, mais
  `sdd monitor <missão>` seguindo o feed e `--no-monitor` para desligar, ligado por default.
  — descoberto por `humano` na missão `20260817-eixo-do-juiz` (2026-08-17)

### Contrato e configuração

- [ ] **O lembrete pós-pipeline manda o humano a um comando que não enxerga o que ele contou** —
  `bin/sdd:2757` (`kaizen_reminder`) vs `:2924` (`cmd_kaizen`) — o lembrete roda com
  `REPO_ROOT` = repo-ALVO e conta as missões dele; o juiz roda no repo do KIT e, com o filtro por
  repo, lê `latest: null` e `other_repo: N`. ⚠️ `--all-repos` (`d62f08c`) **não** fecha isto: o
  lembrete só é chamado de `cmd_run`, e `sdd run` não tem a flag — segue aberto, não estampar.
  Direção: silenciar o lembrete fora do kit, ou responder se o juiz pode pesar linha de outro
  projeto — ADR 0004. — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **`sdd kaizen` recusa rodar de um worktree do próprio kit** — `bin/sdd:2963` — a porta
  "estou no repo do kit?" compara `kit_root` (`--show-toplevel` de `$SDD_HOME`) com `$REPO_ROOT`,
  e o toplevel é por worktree: de um worktree do kit os dois divergem e o comando morre em
  "run it in the kit repo". Mesma classe que `c514e36` acabou de fechar no ledger, em outra
  porta — e o kit recomenda worktree para isolar missão. Direção: `ledger_repo_root` dos dois
  lados, com par diferencial. — descoberto por `sdd-executor` na missão `20260817-eixo-do-juiz` (2026-08-17)

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
  `run_phase` — teto único calibrado por palpite (default do kit US$ 15; **este repo em US$ 40**
  desde 2026-08-17). Medido: SQ-97 TICKET 2,56 · EXEC 7,37 · QA:plan 6,90 · **QA:exec 14,84** ·
  QA:close 9,08; kit **REVIEW 14,76**, e **REVIEW 23,13 contra teto 25** em `catraca-do-backlog` —
  uma r2 teria morrido por dinheiro. Fase a 1% do teto morre no meio e o runner lê "não avançou".
  Direção: teto por fase com o global de default, e gate que reprove com motivo explícito.
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

- [ ] **A identidade do ledger resolve caminho com dois `cd`, e cada camada custou uma rodada de
  review** — `bin/sdd:894` (`ledger_repo_root`) — a sequência foi `--show-toplevel` (errava
  worktree) → `--git-common-dir` (submódulo colapsava) → `cd` para o pai (bare devolvia o pai) →
  `CDPATH` (tudo colapsava, CRITICAL). O git resolve sozinho: `rev-parse --path-format=absolute
  --git-common-dir` (2.31+, aqui é 2.43) dispensa os dois `cd`, o `pwd -P` e a guarda de CDPATH.
  Não é conserto — o código de hoje está correto e medido; é remover a classe inteira. Direção:
  trocar e reancorar os dois mutantes.
  — descoberto por `humano` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **`sdd health` aborta calado no meio quando `~/.claude/plugins/cache` não existe** —
  `bin/sdd:1854` — `find` em diretório ausente devolve 1 e, sob o `set -e` + `pipefail` do runner,
  a atribuição mata o comando no meio da proveniência: rc 1, nenhuma palavra dita, e nem a catraca
  nem o veredito final rodam. O irmão em `:1882` faz o mesmo quando a baseline não tem linha viva;
  os dois foram achados pelo fixture hermético do sensor novo, que precisou modelar máquina com o
  diretório. Direção: `|| true` nos dois, com asserção em `tests/check-health.sh`.
  — descoberto por `sdd-executor` na missão `20260817-catraca-do-backlog` (2026-08-17)

- [ ] **A checagem do `score:` do `sdd health` promete reprovar e morre calada** — `bin/sdd:1721` —
  `score_line="$(grep -m1 …)"` devolve 1 quando a linha não existe e, sob `set -e`, mata o runner
  na atribuição: o `health_bad "…went blind to the mutation"` seguinte é código morto e o
  comentário acima dele afirma o contrário. Terceiro da família (`:1854` e `:1882`), e o mais caro,
  porque é a checagem escrita para impedir cegueira. Provado por probe nesta sessão. Direção:
  `|| true`, como o check 3 já faz, com asserção diferencial em `tests/check-health.sh`.
  — descoberto por `sdd-executor` na missão `20260817-catraca-do-backlog` (2026-08-17)

- [ ] **Duas das três comparações de `health_provenance` não têm fixture nem mutação** —
  `bin/sdd:1829` (qa-execution) e `:1850` (a tabela de notas do codereview) — só a de `qa-report`
  tem template instalado pelo fixture de `tests/check-health.sh`, então as outras duas ficam
  permanentemente no ramo "skipped" e nada mede se ainda discriminam. A do codereview é a mais
  exposta: é um laço `awk` de forma diferente das outras duas, e nenhuma `mut_HEALTH_*` a alcança.
  Direção: um par match/divergência para cada, como a asserção 4 já faz.
  — descoberto por `sdd-reviewer` na missão `20260817-catraca-do-backlog` (2026-08-17)

- [ ] **Os 14 `ROOT="$(cd …)"` de `tests/` não levam `CDPATH=''`** — `tests/check-health.sh:61` e
  os 13 irmãos — o operando é relativo (`tests/..`), então com `CDPATH` setado o `cd` resolve pelo
  path de busca **e imprime o destino na stdout**: `ROOT` vira o diretório errado, duplicado em
  duas linhas. Reproduzido. É a mesma família da CRITICAL que `ledger_repo_root` pagou, consertada
  só lá. Exposto na invocação manual; via `run-all.sh` o caminho é absoluto. Direção: `CDPATH=''`
  nos 14, de uma vez, com probe no `check-pipefail.sh` (que já varre a mesma superfície).
  — descoberto por `sdd-reviewer` na missão `20260817-catraca-do-backlog` (2026-08-17)

### Saída humana e cosmética

- [ ] **43% do `docs/pipeline.md` é um subsistema só, e ele cresce toda missão do ledger** —
  `docs/pipeline.md:326-570` — as seções "The autonomy ledger" (149 linhas) e "The kaizen loop" (96)
  somam **245 de 570** num arquivo que é o índice do pipeline; esta missão engordou as duas. Índice
  que carrega profundidade é o doc que a próxima sessão não lê inteiro. Direção: `references/` para
  o ledger + juiz, com o índice roteando — **não** executar no meio de outra missão, é refator de
  estrutura e merece a sua. — descoberto por `sdd-docs` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **`BLOCKED in <FASE> — N sessions` conta voltas do laço, não sessões** — `bin/sdd:1626` —
  `attempts[$phase]` sobe em toda volta que chega ao topo com a fase, inclusive as que não abrem
  sessão nenhuma. Medido no fixture do I9: REVIEW imprime `3 sessions without satisfying the gate`
  com **1** sessão de REVIEW no ledger, e desde o I9 essa é a última linha que o humano lê quando
  o run encerra. Direção: contar sessões, ou dizer `attempts`. — descoberto por `sdd-executor` na
  missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **As linhas de exclusão do `sdd autonomy` levam uma linha em branco entre cada duas** —
  `bin/sdd:2557-2560` — as quatro strings abrem com `\n` cada uma, então três exclusões saem como
  bloco+branco+bloco+branco+bloco em vez de um parágrafo só. O I3 tirou a linha em branco DUPLA (a
  que o `else ""` produzia com contagem zero); esta é a que sobra, mesma família, e agora é visível
  porque nada mais a esconde. Direção: juntar as não-vazias num array e emitir um `\n` só na frente.
  — descoberto por `sdd-executor` na missão `20260817-catraca-do-backlog` (2026-08-17)

- [ ] **O `def usd` erra o dólar inteiro com entrada negativa** — `bin/sdd:2516` — `round` arredonda
  ao mais próximo e `floor` desce para −∞, então o par não fecha: `-1.5` sai `-2.50` e `-0.005` sai
  `-1.99`. Nenhum escritor do ledger produz `cost_usd` negativo, então hoje é inalcançável — o custo
  é uma linha ilegível se uma linha for editada à mão. Mesma função perde um centavo em `1.005`
  (`100.49999…` em ponto flutuante). Direção: decidir se vale guarda para mundo que o escritor não
  produz; se valer, `fabs` mais o sinal de volta, com fixture que só um teste consegue montar.
  — descoberto por `sdd-reviewer` na missão `20260817-catraca-do-backlog` (2026-08-17)

### Comentário e registro

- [ ] **O `.claude/napkin.md` é rastreado, cita números da suíte e nenhuma fase pode editá-lo** —
  `.claude/napkin.md:18` — o item 3 diz "~33s no default, mutação 30/30" e "alvo <30s estourado
  por ~3s"; o real de hoje é ~3m30s e **81/81**, com o alvo estourado em ~7×. Runbook lido toda
  sessão que afirma uma catraca vencida convida a aceitar score menor. **Duas** fases DOCS já
  tentaram consertar e o harness barrou `.claude/` como sensível nas duas — só sessão com humano.
  Direção: decidir se o napkin entra na superfície que o DOCS mantém ou sai do versionamento.
  — descoberto por `sdd-docs` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **A regra manda sincronizar `.claude/agents/` e não diz como; `cp` e Edit são barrados** —
  `CLAUDE.md` (seção "Ao mexer nos agentes") — o harness trata `.claude/` como caminho sensível,
  então a sessão headless leva negativa nas duas ferramentas e a fase parece travada com o
  preflight vermelho em `agent stale`. Quem resolve é `sdd install --force`, citado só na
  mensagem de falha do preflight. Direção: dizer isso na regra. — descoberto por `sdd-executor`
  na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **O `KAIZEN_LOG.md` não fixa o instrumento das próprias linhas, e uma delas já mentiu** —
  `KAIZEN_LOG.md:261` — a entrada de `20260816-portas-do-humano` registrou "asserções `ok`: 490" para
  um `main` que mede **435** pela âncora de 4 espaços; `490` é a contagem solta `^  ok`, que soma 55
  linhas de 3 espaços impressas pelo runner dentro dos fixtures. O tree é o mesmo
  (`git diff c821ade..96a9bf1 -- tests/ bin/sdd` vazio), então a série 408 → 457 → 490 do arquivo tem
  degrau fantasma. Direção: nomear o comando ao lado do número, como a linha do `score:` já faz.
  — descoberto por `sdd-docs` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **O `kaizen_axis_note` promete não repetir o piso e o repete duas linhas abaixo** —
  `bin/sdd:2924` vs `:2928` — o comentário diz "no count in the sentence on purpose: writing '3'
  here would be a third copy of a number the jq program already owns", e o `dim` seguinte imprime
  "The floor of 3 missions per kit version". O `guard_floor` do `jq` é o dono; esta é a cópia que
  drifta calada no dia em que o piso mudar, e é a **única** das seis vozes do schema que o humano lê
  em voz alta. Direção: interpolar o `guard_floor` da série, ou tirar o número da frase.
  — descoberto por `sdd-docs` na missão `20260817-eixo-do-juiz` (2026-08-17)

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

- [ ] **Sensor novo na suíte é multiplicador, não parcela: custa uma vez por mutante** —
  `tests/run-all.sh:180` — `check-health.sh` roda em ~1,5 s sozinho e roda **dentro de cada
  mutante**, hoje 81. Medido em passadas sequenciais e máquina quieta, `main` (`6d68dfc`) contra o
  HEAD desta missão: **155,97 s → 210,81 s**, +55 s com 11 mutações a mais no mesmo diff.
  ⚠️ O EXEC registrou **+281 s** para a mesma família e isso não reproduz — era contenção, não o
  mecanismo. O item acima fala em crescer com o catálogo; este é outro mecanismo.
  Direção: rodar por mutante só o sensor que o alcança — decisão do humano, junto com o alvo da D7.
  — descoberto por `sdd-executor` na missão `20260817-catraca-do-backlog` (2026-08-17)

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
