# TODO — `sdd_agents`

Achados que **não cabem na missão atual**, registrados por qualquer agente ou humano
(kaizen princípio 10: oportunidade registrada, nunca desvio de escopo, nunca achado perdido).
Formato, esqueleto e ciclo de vida: [`templates/todo.pt-BR.md`](templates/todo.pt-BR.md) — a
semente que o `sdd install` grava nos repos-alvo, uma variante por `OUTPUT_LANG`, com a forma
medida por `tests/check-todo.sh`. Os planos estacionados do kit moram na gaveta,
[`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`](docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md).

Achados sobre **repos-alvo** vão para o `TODO.md` daquele repo. Este arquivo é só sobre o kit.

> **Catraca do volume — crescer é permitido, crescer calado não.** Quantos itens este arquivo
> carrega é o achado `todo-findings <N>` do `sdd health`, congelado em `tests/health-baseline.txt`.
> Reprova nos **dois** sentidos: número que subiu sem registro, e baseline que ficou para trás
> depois de uma faxina. Quem acrescenta item aqui **e** move a linha da baseline no mesmo commit
> está certo — o número tem dono e aparece no diff. Quem só acrescenta descobre no `sdd health`.
> Ela mora lá e não no `TEST_CMD` porque um teto dentro da suíte reprovaria toda missão em voo.
> ⚠️ A contagem sai de `tests/check-todo.sh`, nunca de um `grep -c '^- \[ \]'`, que não sabe
> onde a seção aberta termina.

## Aberto
<!-- sdd:open -->

### Sensores que faltam

- [ ] **`gate_QA` aceita relatório de QA de OUTRA missão** — `bin/sdd:1123` — a Âncora 1 pega o
  relatório mais recente do glob por `latest_matching` e só exige `closed` sem linhas `Pending`;
  nada o amarra à missão corrente. Em `20260827-condicoes-pagamento-mesmo-cliente` o gate passou
  lendo o `2026-08-24-sq107-status-material-frete.md`, de duas missões antes. Fail-open: promete
  "a QA desta missão fechou" e mede "existe alguma QA fechada no disco". Direção: casar o
  relatório com o slug da missão ou com a janela de datas dela.
  — descoberto por `sdd-qa` na missão `20260827-condicoes-pagamento-mesmo-cliente` (2026-08-27)

- [ ] **Citação NÃO-cercada acima do cabeçalho ainda vira o gênero do bug** — `bin/sdd:1189` — o
  extrator da Âncora 3 pula blocos cercados e pega a primeira linha com forma de campo fora de um,
  então prosa nua abrindo com `- **Closable by:** human` acima do campo real ainda é lida como o
  campo. É fail-open (o gate responde `registry clean` com bug sanável aberto), na direção que a
  decisão 3 do grill recusa. Alcance baixo: exige arquivo que viole a ordem do template. Declarado
  no comentário do `bin/sdd`; entra aqui porque fail-open declarado continua entrando (régua D15).
  Direção: ancorar o gênero no MESMO bloco contíguo de `- **…:**` que traz a linha `Status:`.
  — descoberto por `sdd-reviewer` na missão `20260826-o-laco-da-qa` (2026-08-26)

- [ ] **O `stub-argv.txt` do `check-health.sh` nunca é apagado entre mundos de fixture** —
  `tests/check-health.sh:222` — todo `health_run` sobrescreve, ninguém remove. Hoje não reproduz
  fail-open (medido: sem chamada nenhuma à suíte, o arquivo some e a asserção acusa certo), mas no
  dia em que `cmd_health` ganhar um segundo caminho para a suíte a última escrita vence calada.
  Direção: apagar no `green_world`, como as outras fixtures fazem.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Dois resíduos de sensor que precisam de DUAS edições, e nenhum tem testemunha externa** —
  `tests/check-todo.sh:107` — neutralizar um helper E descartar o `cfail` do controle; apagar o
  `selftest ||` E o acoplamento do `check_file`. Estão declarados nos cabeçalhos, o que é dívida
  honesta e não fail-open — mas `check-todo.sh` e `check-templates.sh` seguem fora do catálogo, que
  só sabota `bin/sdd`. Direção: catálogo que também sabote `tests/`, ou a última linha fica sem juiz.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Nada impede a próxima invocação de `sdd health` sem `cd`, e ela mede a árvore de quem
  chamou** — `tests/check-health.sh:291` — desde o F2 o `health_kit_root` deixa o diretório
  corrente escolher a árvore medida, então um chamador que não fixa o `cd` mede o que estiver em
  volta. Medido, não temido: o fixture do sensor passou a medir ESTE repo (catálogo real, 20 a 50
  min) e, dentro de uma sandbox do `check-mutation.sh`, recursaria num segundo catálogo por
  mutante. O sítio foi fixado; nenhum sensor recusa o próximo. Direção: regra que enumere as
  invocações de `bin/sdd` dos fixtures e exija `cd` fixado. — descoberto por `sdd-executor` na
  missão `20260819-fecho-...` (2026-08-19)

- [ ] **O carimbo de mutação cobre 4 dos 8 caminhos que a sandbox do catálogo copia** —
  `bin/sdd:1595` contra `tests/check-mutation.sh:4518` — a chave lê `bin tests templates config`,
  mas `sandbox()` também copia `agents/`, `CLAUDE.md`, `TODO.md` e `docs/adr`. Mudança confinada a
  esses quatro mantém o carimbo válido sobre conteúdo que o catálogo de fato mede — a
  regra 12 do `check-health.sh` lê o `CLAUDE.md`. Estreitamento deliberado (a fase DOCS edita
  `CLAUDE.md`, e chavear nele custaria uma segunda rodada de ~20 min por missão). Direção: ler a
  lista do próprio `sandbox()`, decidido o custo. — descoberto por `sdd-executor` na missão
  `20260819-fecho-...` (2026-08-19)

- [ ] **A alternativa `|| :` da guarda do `guard:` não tem probe** —
  `tests/check-health.sh:1586` — a guarda aceita `(true|:)`, e só `|| true` tem mundo no `cap_world`.
  Medido em 2026-09-25: tirar o `:` da alternância deixa o `check-health.sh` inteiro verde. Das quatro
  sobreviventes da r2, três fecharam em `a948f68` (piso exato de capturas, probe aritmético, lista
  `RULE_REPORTS`). Direção: um `cap_world` com `|| :` e o censo afirmado, como os vizinhos.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O `guard:` é cego a helper `health_*()` definido fora da região** —
  `tests/check-health.sh:1605` — a região vai de `# Sensor of the KIT` até `cmd_status()`, então um
  `health_*()` definido depois dela não é censurado. A outra metade do achado (`if x=`, `local x=` e
  here-doc lidos como offender) fechou: as três formas são isentas e declaradas no cabeçalho da regra.
  Direção: censurar todo `health_*()` onde ele estiver.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Os dois literais "ESTRUTURAIS" da regra 3 do `check-checkpoint.sh` afrouxam em verde** —
  `tests/check-checkpoint.sh:227` — `PIPE_MECH="awk"` vira `"aw"` e `PIPE_ESCAPE='\|'` vira `'\'`
  com o selftest verde; só `"a"` mata, e por acidente do fixture. O cabeçalho lista oito sabotagens
  mortas, todas de APAGAR — afrouxar, que é a regra do `CLAUDE.md`, não está coberto. Degradado
  assim, qualquer doc com "raw" e uma barra satisfaz a regra. Direção: um probe por literal, contra
  um doc de quase-acerto (`awk` sem `-F'|'`).
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O braço 1 da guarda de forma do `ledger_repo_root` não tem probe, e a mutação junta os
  dois** — `bin/sdd:2570` (`case "$gitdir" in`) — sob o shim pré-2.31 o valor não começa com `/`, então quem dispara é
  sempre o braço 2; o braço 1 (uma linha só, caminho absoluto) só é alcançado por um repo cujo
  CAMINHO contém `\n`, e nenhum fixture tem um. `mut_LEDGER_repo_root_shape_blind` apaga os dois de
  uma vez, então o catálogo não os distingue. Direção: fixture com `\n` no caminho e dividir a
  mutação em duas. — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O piso do shim pré-2.31 prova que o shim é um git falso, não que o runner o consulta** —
  `tests/check-autonomy.sh:4225` — o piso invoca `git` diretamente sob o `PATH` do shim, e nada
  ancora no caminho de resolução do runner. Medido: trocar `git` por `/usr/bin/git` no
  `ledger_repo_root` E apagar a guarda deixa `check-autonomy.sh` inteiro verde, porque o shim segue
  um impostor correto que nunca é chamado. Direção: termo provando INTERCEPTAÇÃO — a resposta do
  runner sob o shim tem de diferir da resposta sem ele.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Nada mede se o esperado de um Check do checkpoint ainda reproduz** —
  `tests/check-checkpoint.sh:1` — o sensor mede a FORMA da célula (âncora `^  ok    `, ausência de
  `|`, cinco colunas) e nunca o VALOR. Medido nesta missão: o Check do I2 dizia `3` e responde `4`
  desde `8812a9c`, com a suíte verde o tempo todo — e o commit seguinte, que re-derivou âncoras,
  passou ao lado. Direção: não é rodar os Checks (custa a suíte por célula); é a fase que move uma
  contagem re-rodar os Checks do mesmo predicado.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **A sonda de `--path-format` do preflight não tem asserção nenhuma** —
  `bin/sdd:4520` — a guarda que ela anuncia (`ledger_repo_root` recusando a resposta de duas
  linhas) tem par diferencial e mutação; a linha que **fala** com o operador não tem. O
  `check-preflight.sh` já carrega a receita pronta — o shim `$FIX/.bsd` faz exatamente isto para
  a userland GNU. Direção: um shim `.oldgit` e o par (fala com git velho, cala com git novo).
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **Três frouxidões da regra da caixa pelada passam pelo selftest** —
  `tests/check-todo.sh:406` — tirar o limite final `([ \t]|$)`, alargar `[ xX]` para `.` e tirar
  o `>` do ancoramento deixam os 86 probes verdes. A terceira estreita a regra: caixa dentro de
  bloco de citação deixaria de ser pega e nada diria. Regra sem probe é o que a passada
  adversarial existe para achar. Direção: um probe por frouxidão, como `inlinebox.md` já faz.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `tail_of` aceita qualquer par de crases como se fosse a atribuição** —
  `tests/check-todo.sh:293` — a regra pergunta "o rabo tem um code span", não "o rabo nomeia um
  agente", então um título com código inline satisfaz a metade da atribuição do mesmo jeito que
  já satisfaz a da âncora (fraqueza espelhada, e só a da âncora está declarada no cabeçalho).
  A forma aguda virou conserto; a que sobra é REGRESSÃO desta missão, medida em diferencial (o
  sensor do merge-base recusa o item, este aceita). Fechar exige a re-derivação semântica posta
  fora de escopo: toda regra sintática tentada inventa 5 violações no arquivo real.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `moved2` do `cmd_kaizen` não tem asserção que morra ao apagá-lo** —
  `bin/sdd:7247` — a asserção `covered:` do `moved` cobre a primeira atribuição; neutralizar a
  do retry deixa `check-kaizen.sh`, `check-autonomy.sh` e o catálogo verdes, porque o default
  local `false` coincide com o que o regime do fixture espera. Só o hardcode para `true` morre.
  Direção: um mundo em que o retry mexe no disco de verdade, ou estreitar o que a asserção diz.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **`frontmatter_write` confia em três coisas que não valem sempre** — `bin/sdd:356` — o
  `chmod --reference … || true` engole a falha e deixa o artefato 0600 para sempre em userland não
  GNU; o `mv` troca um `00-missao.md` que seja SYMLINK por arquivo comum (o alvo real fica com o
  valor velho, e o commit leva a troca de tipo); e `awk -v v="$valor"` interpreta escape de barra
  invertida — inócuo no único chamador de hoje, armadilha para o segundo. Direção: `warn` no chmod,
  `readlink -f` (ou `die`) no alvo, e valor por `ENVIRON` no awk.
  — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-16)

- [ ] **A linha `N kit agent(s) checked` não é observável por nenhum fixture** — `bin/sdd:4743` —
  ela só sai com `fails -eq 0`, e todo fixture offline reprova antes (o probe do `claude` e o
  `gh auth status`). O I3 provou o ramo de falha por diferencial, mas o ramo de sucesso — a frase
  que o operador de fato lê — segue sem sensor. Direção: um `--skip-session` no preflight, ou um
  contador de agentes impresso fora da guarda de `fails`.
  — descoberto por `sdd-executor` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **A metade "nenhuma sessão foi gasta" do `assert_jidoka` é vácua** —
  `tests/check-gates.sh:281` — ela grepa o marcador do stub (`the test invoked the real claude`)
  na saída do `sdd run`, e `run_phase` manda stdout E stderr da sessão para o arquivo de log: o
  marcador nunca chega ao terminal, então a asserção fica verde tenha havido sessão ou não. É
  justamente o discriminador que o comentário acima dela chama de "o que 'no session spent'
  significa". Direção: contar o `pipeline.log`, como as duas asserções novas desta missão fazem
  (`phase_sessions_spent`). — descoberto por `humano` na missão `20260820-missao-porteira` (2026-08-21)

- [ ] **Os dois ramos de diagnóstico do `differential()` não têm probe** —
  `tests/check-entrypoint.sh:222` — a passada adversarial da r2 matou 20 de 25 degradações, e o
  que sobra sem probe é a comparação do próprio diferencial: neutralizá-la faz o sensor ler "1 vs
  1" e seguir verde, então o dia em que o fall-through parar de reproduzir neste bash passa
  despercebido. Hoje o limite é o par de contagens ser IMPRESSO na linha `ok`. Direção: um gancho
  de contagem falsa, como o `SDD_EP_FORCE_FAIL` da composição, com um probe por ramo.
  — descoberto por `sdd-reviewer` na missão `20260816-kit-como-alvo` (2026-08-16)

- [ ] **O fixture de `stream-json` não tem checagem de proveniência** — `tests/check-autonomy.sh:127`
  — as três linhas replayadas pelos stubs foram copiadas de sessão real (CLI 2.1.233) e o comentário
  registra o comando, mas `health_provenance` (`bin/sdd:1405`) só confere as 3 fixtures de skill
  contra arquivo instalado. Se o CLI renomear `type`/`total_cost_usd`, o stub segue verde e o
  runner quebra só em missão real — o modo de falha que a regra de proveniência existe para matar.
  Direção: probe que rode o CLI de verdade, ou capturar o schema num arquivo versionado.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`.sdd/logs/` não tem poda e agora guarda o stream inteiro** — `bin/sdd:719` — desde o I10
  cada sessão deixa três arquivos, e o `.stream.jsonl` é a sessão toda (a de teste, trivial, deu
  ~40 KB; uma fase real de 10 min é ordens de grandeza maior). Nada apaga nada: o diretório cresce
  por missão para sempre, e é justamente o que o humano vai querer abrir. Não é urgente — é
  gitignored e local. Direção: reter as N sessões mais recentes por missão, ou comprimir o stream
  ao fim da fase. — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **Sensor pulado por `SDD_MUTANT` vira ponto cego sem aviso** — `tests/run-all.sh:218` —
  sensores são pulados dentro do mutante (hoje o lint e os quatro de `:198-221`). É aposta que vence
  sozinha: no I3 o `check-preflight.sh`
  ganhou asserção de comportamento do runner, e a linha que o pulava virou a escondedora da única
  sensora de `RUN_install_no_guard`. O sintoma chega como "mutação não capturada", e o conserto
  tentador é `KNOWN_GAPS`. Direção: reprovar guarda de `SDD_MUTANT` em arquivo que invoca `bin/sdd`.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`check-autonomy.sh` é vermelho intermitente, causa desconhecida** — `bin/sdd:4341` —
  ⚠️ **A causa registrada foi REFUTADA; o sintoma segue aberto.** Era "colisão de nome de log em
  repo que versiona `.sdd/logs/`", e não se sustenta: `check-autonomy.sh:140` chama
  `sdd install` ANTES de existir log, e o `sdd install` já põe `.sdd/logs/` no `.gitignore` —
  `git ls-files` no fixture lista só `.sdd/config.sh`. Colisão é a norma (8 sessões EXEC no mesmo
  segundo num run) e a árvore fecha limpa. Não reproduziu em **152 runs**. Direção: `%N` é no-op;
  medir de novo antes de consertar. — refutado por `sdd-reviewer` (r2), descoberto por
  `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O gate PLAN-AUTO aceita Check que já nasce verde** — `templates/missao.md:45` — o critério
  `d` cobra `Check executável (comando → esperado)`, não "Check que
  reprova o HEAD de hoje". Medido: o Check do I1 desta missão era `grep -c 'gate_DOCS reprova'
  TODO.md` → `0`, mas o título no `TODO.md` traz crases (`` `gate_DOCS` reprova ``), então o
  comando já devolvia `0` **antes** da remoção — verde por construção, exatamente o que a casa
  proíbe em teste. Direção: o planner roda cada Check contra o HEAD e registra o vermelho.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **Check de ausência (`grep -c X` → `0`) reprova o conserto que precisa citar o defeito** —
  `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` — o comentário honesto que
  **desmente** a promessa `CHARACTER slice` precisa nomeá-la, e o Check literal deu `1`, não `0`.
  Distinto do item acima: rodar o Check contra o HEAD dá vermelho de verdade e a armadilha fica.
  Direção: Check de ausência mira o código, nunca a prosa. — descoberto por `sdd-executor` na
  missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **A asserção "dry-run não toca no disco" promete mais do que entrega** —
  `tests/check-dry-run.sh:177` (`does not touch the disk`) — roda sobre fixture parado em EXEC, cujo gate
  reprova antes de chegar ao `TEST_CMD`. Num fixture que alcance `gate_REVIEW`, o dry-run escreve
  `.sdd/logs/<missão>/gate-*-test-*.log` (reconfirmado no repo real, volta 2 da QA). Não é bug —
  é comportamento aceito e gitignored —, mas o nome garante mais que o teste. Direção: renomear
  para "não toca nos artefatos da missão" ou exercitar também num fixture que chegue ao REVIEW.
  — descoberto por `sdd-qa` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **O formato de achado vale para os repos-alvo, mas o sensor só guarda o arquivo do kit** —
  `tests/check-todo.sh` vs `CLAUDE.md` (princípio 5) — o esqueleto de duas seções e o ciclo
  "fechado é apagado" valem para o `TODO.md` de **qualquer** repo. Desde o marcador, o sensor roda
  num alvo (`--check <arquivo> --allow-empty`, e a skill `todo-to-github-issues` o chama antes de
  espelhar), mas nada o põe na suíte do alvo: o inchaço volta sem ninguém medir a cada missão.
  Direção: o `starter.conf` sugerir o `--check` do kit no `TEST_CMD` do alvo.
  — descoberto por `humano` revisando o sensor novo (2026-08-16)

- [ ] **A economia de `current_phase()`/`next_pending_phase()` depende da memoização e ninguém
  conta** — `bin/sdd:1742` vs `:675` — as duas reavaliam o gate de toda fase a cada
  chamada, e isso só é barato porque `run_check_cmd` cacheia por `$cmd`. Quem mexer em **quando**
  `invalidate_checks` roda reintroduz N execuções de `TEST_CMD` por projeção, em silêncio.
  Direção: `TEST_CMD` que incrementa contador em arquivo, afirmando que o número não cresce com
  o número de fases pendentes. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A asserção `the retry carries its own moved` não falha pela propriedade que promete** —
  `tests/check-autonomy.sh:424` — no fixture, `moved` sai `false` com qualquer baseline: o retry
  só é alcançado quando `before == after`, então a asserção nunca observa um `moved:true` genuíno
  pelo caminho real. Ainda pega campo ausente ou `moved` sempre-`true`; só o nome discrimina mais
  do que ela. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **O schema da série não tem sensor de drift contra a prosa que o descreve** — `bin/sdd:8385`
  (`kaizen_series`) vs `docs/pipeline.md:501`, `docs/adr/0003:57`, `agents/sdd-kaizen.md:40` e
  `docs/failure-modes.md:99` — produzido em dois lugares (o `jq` e o literal vazio, `:8394`) e
  descrito em **dez**, QUATRO deles dentro do `bin/sdd`. Cobrado 6×: na DOCS de
  `20260817-eixo-do-juiz`, **oito** dos dez diziam a unidade que o F1 da r3 trocara horas antes
  (sessão → missão) — o ADR que o runner cita, a folha do juiz, e a própria frase que o runner
  IMPRIME. Direção: extrair os campos do `jq` e cobrá-los na doc.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O conjunto de fronteira do `MAXC_RE` não tem probe, e o comentário jura paridade com o
  `PIPE_RE`** — `tests/check-pipefail.sh:219` — o `PIPE_RE` ganha quatro probes de falso-positivo
  para essa mesma classe; o `MAXC_RE` copia a grafia e não ganha nenhuma. Trocado por `.+`, o
  selftest fica verde e a regra passa a INVENTAR violação nas quatro formas que os probes do
  vizinho existem para recusar. É a classe "comentário afirmando paridade não é paridade" que o
  `CLAUDE.md` já nomeia duas vezes. Direção: derivar o miolo comum de UMA variável, ou dar ao
  `MAXC_RE` os mesmos quatro probes. — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `gate:` do frontmatter só é cobrado quando existe, e 6 das 14 rodadas não o têm** —
  `bin/sdd:1359` — a recusa de placeholder no `gate:` deixa AUSENTE em paz de propósito, para não
  reprovar rodadas anteriores ao campo; mas ausente e placeholder afirmam o mesmo nada, e o
  `check-templates.sh` cobra a chave no template sem que gate nenhum a cobre no artefato. Direção:
  exigir o campo a partir de uma data/versão, ou cobrá-lo no `sdd health` como dívida congelada.
  — descoberto por `sdd-executor` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **Slug de missão em pt-BR não pode ser citado na superfície inglesa** —
  `tests/check-lang.sh:51` — `que`, `nao`, `sem` e `sobre` são stopwords, e `-w` as casa dentro de
  um slug hifenizado: citar `20260819-fecho-que-nao-mente` num comentário de `tests/` reprova o
  sensor. A proveniência degrada para uma data, que é o dado mais fraco — o slug é o que liga o
  comentário ao handoff. Direção: isentar o casamento `^[0-9]{8}-` do escaneamento de stopwords.
  — descoberto por `sdd-executor` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O `gate_QA` compra o placeholder do próprio template como evidência de jornada** —
  `bin/sdd:1117` — em projeto sem interface a única âncora é `frontmatter gate`, testada só por
  `-z "$evidence"`. O `templates/handoff.md:7` entrega `gate: <a evidência...>`: um handoff copiado sem tocar
  a linha passa o gate com `journey walked without a browser interface`. É o defeito que o I3
  fechou no `gate_REVIEW`, vivo um gate adiante, e a `placeholder()` está presa dentro do awk.
  Direção: extrair a regra para uma função e cobrá-la nos dois gates.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O ramo de forma do `score:` no `cmd_health` não tem asserção nem mutante** —
  `bin/sdd:5103` — é ele que impede que um `score:` presente e ilegível caminhe até `ok` e carimbe:
  sem ele os três `[ "" -ne … ]` devolvem rc 2, o `if` lê falso e o `else` credita a rodada.
  Nenhum `write_stub_suite` usa score malformado. Mesma linha: `grep -m1` pega a PRIMEIRA linha
  `^score: ` e a autoritativa é a última. Direção: fixture com score torto + mutante, e `tail -1`.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O piso do catálogo mora só no consumidor; quem imprime o `score:` segue sem nenhum** —
  `tests/check-mutation.sh:4781` — com `CATALOG=()` o laço roda zero vezes, `errors` fica 0 e o
  arquivo imprime `score: 0 caught, 0 known gap(s), of 0` saindo 0. O F1 pôs o piso no `cmd_health`,
  hoje o único chamador — mas duas frases do próprio runner (`bin/sdd:5055` e `:5108`) mandam o
  operador rodar `tests/run-all.sh --with-mutation` à mão, e aí o verde volta a mentir.
  Direção: comparar `${#CATALOG[@]}` com as definições `mut_*()` no próprio catálogo.
  — descoberto por `sdd-executor` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **`FIXME` e `XXX` são recusados pelo `gate_REVIEW` sem nenhum mundo que prove** —
  `bin/sdd:1407` — a lista de palavras de preenchimento tem sete entradas e só cinco têm mundo no
  `check-gates.sh`. Medido na passada de sabotagem do F3: tirar `WIP` ou `FILLME` deixa a asserção
  vermelha, tirar `FIXME` ou `XXX` a deixa **verde**. As duas nasceram assim no I3 e a lista cresceu
  por cima. Regra sem probe é decoração e some calada no dia em que alguém a reescreve.
  Direção: um mundo para cada, ou tirá-las da lista.
  — descoberto por `sdd-executor` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **A guarda de vazio do `mutation_stamp_key` só cobre a ausência TOTAL dos quatro caminhos** —
  `bin/sdd:1669` — com `tests/` presente e `bin/` ausente, o `find` imprime o que achou, sai não-zero,
  o `2>/dev/null` engole o aviso e a chave sai de uma listagem PARCIAL, sem sinal nenhum de que
  faltou diretório. Hoje inalcançável (as duas pontas só perguntam por raiz cujo `tests/` tem
  catálogo), e o comentário da função declara só o caso "todos ausentes".
  Direção: exigir que cada caminho de `MUTATION_STAMP_PATHS` exista, ou carimbar a lista na chave.
  — descoberto por `sdd-reviewer` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **Piso anti-vacuidade que fica para trás continua PASSANDO, e nada avisa** —
  `tests/check-lang.sh:178` — o piso dizia 37 caminhos contra 40 reais: as ADRs 0004–0006 entraram
  pelo glob `docs/adr/*.md` sem tocar o número, e piso menor que a superfície certifica menos do
  que lê. Corrigido para 41 no I4, mas a **classe** segue viva — todo piso que convive com um glob
  (`REVIEW_FLOOR`, `LINT_FLOOR`, os de `check-pipefail.sh`) falha igual, e é a segunda vez que este
  mesmo piso paga. Direção: derivar o piso, ou um sensor que compare piso × superfície real.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-01)

- [ ] **Nenhum instrumento mede prosa de CONTRATO fora de `templates/`** — `README.md:152` — o
  `refute()` do `tests/check-templates.sh` só lê `templates/`, e `README.md`/`docs/*.md` entram na
  `surface()` do `check-lang.sh`, que mede **idioma** e nada mais. Medido nesta missão: o I2 mudou
  o contrato do revisor em cinco lugares, o sexto sobreviveu à suíte verde e caiu numa jornada de
  QA; o sétimo (os diagramas de ordem canônica) sobreviveu à própria QA e só a DOCS o pegou.
  Direção: um `refute()` sobre a superfície de docs, ou ligar a tabela de agentes ao frontmatter.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-01)

- [ ] **O braço `else ""` da célula do laço de revisão não tem fixture** — `bin/sdd:8250` — a
  guarda contra a divisão por zero do `jq` (`$whole > 0`) está correta e **não é medida**: uma
  frouxidão futura (`$whole >= 0`) abortaria o `--by-mission` inteiro sobre um ledger real com
  missão de custo nulo, e nada nesta suíte avisaria. Direção: fixture diferencial de missão de
  custo todo nulo **com** rodada REVIEW.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **Comentário afirma que a segunda asserção é o que torna a primeira não-vácua, e não é** —
  `tests/check-gates.sh:1163` — medido sob a sabotagem realista (`checkpoint_rows` cego a `R<n>`):
  só a primeira cai, e a segunda fica verde por um motivo diferente do alegado. É a classe
  *"comentário que afirma paridade não é paridade"* que o `CLAUDE.md` já nomeia. Direção: ou o
  comentário baixa a alegação, ou a asserção ganha o mundo que a distingue.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **A suíte não tem `timeout` em lugar nenhum** — `tests/run-all.sh:95` (`run()`) — regra quebrada que
  recursa sai como **travamento sem mensagem**, e não como vermelho; medido em `rc=124` sob
  `timeout 20` na r2 desta missão. É a classe que já custou três sessões de REVIEW deste repo
  (`4c86712`), e o probe de ponta a ponta do `check-templates.sh` está a uma edição dela.
  Direção: barato, mas o número tem de ser escolhido a dedo por passo.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **A âncora `^  ok    ` do Check não alcança 82 das 866 asserções da suíte** —
  `tests/check-templates.sh:64` — as primitivas `check()`/`refute()` imprimem `ok` com **três**
  espaços enquanto `tests/check-checkpoint.sh:111` cobra quatro em todo repo adotante, e o
  `calibrate()` que existe para casar as duas pontas é cego a elas: lê só linhas com `pass() {`,
  logo enxerga 7 de 13 sensores e deixa 2 dos 8 comportamentais de fora prometendo "every
  behavioural sensor". Direção: unificar em quatro espaços **e** dar cobertura ao `calibrate()`.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **A proveniência do `sdd health` lê "a mais nova em cache", não "a que roda"** —
  `bin/sdd:5416` — o `report-template.md` da `codereview` sai de `find … | sort -V | tail -1` sobre
  `~/.claude/plugins/cache`, e o resumo promete `fixtures match the installed skills` (`:5437`); quem
  fixa a versão que a fase REVIEW carrega é o `installPath` de `~/.claude/plugins/installed_plugins.json`.
  Com uma 1.19.0 em cache e a 1.18.0 fixada, o health confere o fixture contra um arquivo que a sessão
  nunca lê — e diz que conferiu. Fail-open (D15). Direção: ler o `installPath` do registro, `find` só
  como fallback, mutante no catálogo. — descoberto por `claude` na faxina `20260904-faxina-do-backlog` (2026-09-04)

### Contrato e configuração

- [ ] **Fase interrompida depois do REVIEW faz o pipeline REGREDIR para o REVIEW** —
  `bin/sdd:1505` (`git status --porcelain`) — o `gate_REVIEW` reprova com árvore suja e não distingue "o revisor deixou
  sujeira" de "uma fase POSTERIOR está no meio do voo". Sessão de DOCS morta deixa arquivo não
  commitado, `current_phase()` volta a responder REVIEW, e o `sdd run` seguinte abre sessão nova
  da fase mais cara do kit — US$ 37,30 medidos nesta missão. Morte de sessão é o caso normal que
  o princípio 4 promete resolver de graça. Direção: escopar a checagem ao que o REVIEW pode sujar.
  — descoberto por `operador` na missão `20260827-condicoes-pagamento-mesmo-cliente` (2026-08-27)

- [ ] **A catraca do backlog e o carimbo de mutação colidem em toda missão** —
  `tests/health-baseline.txt` (`todo-findings`) — o arquivo mora DENTRO dos quatro diretórios da chave do carimbo,
  então cumprir o princípio 5 (achado fora de escopo vira item) obriga a bumpar a catraca, o que
  invalida o carimbo e cobra outra rodada de 20 a 50 min antes do `gate_PR`. Medido nesta sessão:
  o carimbo `0575d68…` foi ganho e perdido pelo commit que registra estes achados. Direção: tirar
  o baseline da chave, ou aceitar o custo declarando-o no boot da fase PR.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **Lixo ignorado pelo git dentro dos quatro diretórios move a chave do carimbo** —
  `bin/sdd:1663` (`mutation_stamp_key`) — a chave é `find -type f` sobre a árvore, não sobre o que o git rastreia: um
  `tests/debug.log` (ignorado por `*.log`, invisível no `git status`) muda a chave, e um swap de
  editor que nasce e morre durante a rodada dispara a guarda de janela, jogando fora um verde
  legitimamente ganho. O mundo 8 do `check-gates.sh` depende desse mecanismo de propósito.
  Direção: basear a chave nos arquivos rastreados, ou podar dotfiles.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **`sdd kaizen` recusa rodar de um worktree do próprio kit** — `bin/sdd:9145` — a porta
  "estou no repo do kit?" compara `kit_root` (`--show-toplevel` de `$SDD_HOME`) com `$REPO_ROOT`,
  e o toplevel é por worktree: com o `sdd` do checkout principal e o cwd num worktree os dois
  divergem e o `die` da `:9126` mata. ⚠️ **`--series` NÃO passa por ela** — sai na `:9113`, medido
  nas duas formas de invocação, saída idêntica. Direção: `ledger_repo_root` dos dois lados, com par
  diferencial. — descoberto por `sdd-executor` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **O kit não tem `CHANGELOG.md`, e a fase DOCS cobra um** — `agents/sdd-docs.md` (tabela "O
  que atualizar") — o registro durável aqui é `KAIZEN_LOG.md` + handoffs + corpo do PR, e nenhum
  é changelog por versão; há `SDD_VERSION="0.1.0"` em `bin/sdd:5` sem nada que o acompanhe. Toda
  missão cai num `n/a` honesto e repetido. Decidir: criar o arquivo com política amarrada ao
  `SDD_VERSION`, ou tirar a linha do agente. Vale para os repos-alvo também. — descoberto por
  `sdd-docs` na missão `20260814-dry-run-completo` (2026-08-14)

- [ ] **O contrato de artefato ainda é PT-BR em cinco pontos** — chamadas de `frontmatter` em
  `bin/sdd`, `templates/missao.md`, `agents/*.md`, `tests/` — sobraram 3 chaves (`aprovacao`,
  `versao`, `titulo` — 45 refs) e 2 nomes de artefato (`00-missao.md`, `01-plano.md` — 72 refs).
  É o único português **obrigatório** para um repo-alvo anglófono, e `OUTPUT_LANG` não resolve
  contrato. Não há missão em voo que a renomeação quebre (PR #105 mergeado): o custo é tamanho,
  não risco. Direção: `approval`/`version`/`title` + `00-mission.md`/`01-plan.md`, com o runner
  aceitando os dois nomes por uma janela. — descoberto por `humano` na missão
  `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **`templates/` é single-language** — `templates/handoff.md:2` (`missao:`) — são conteúdo em `OUTPUT_LANG` mas
  moram no kit em cópia única PT-BR, e o `sdd install` nem os copia (o `sdd-planner` lê direto de
  `$SDD_HOME`). Um alvo com `OUTPUT_LANG="en"` recebe prompt certo e template em português. Não
  morde hoje porque todo alvo é PT-BR. Direção: `templates/<lang>/` com fallback, ou estrutura
  inglesa com prosa-guia que o agente reescreve — a segunda mexe no contrato que
  `check-templates.sh` mede. Precedente: o `todo.md` já tem uma variante por idioma (`todo.<lang>.md`,
  paridade cobrada). — descoberto por `humano` na
  missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **A regra `cdpath:` certifica como limpo o `cd` de operando VARIÁVEL** —
  `tests/check-pipefail.sh:283` (o comentário do `CD_RE` declara o limite) — a regra só mede
  operando que é substituição de comando, porque `cd "$FIX"` é indecidível no scanner e os ~150
  sítios de `tests/` têm variável absoluta. Só que a única instância histórica da classe era
  exatamente essa forma (`cd "$common"` do `ledger_repo_root`, uma CRITICAL), então a forma que
  mais custou é a que o sensor não vê. Direção: medir em runtime, não por linha.
  — descoberto por `sdd-executor` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **Nenhuma chave de caminho do `.sdd/config.sh` é normalizada antes de virar padrão de `case`**
  — `bin/sdd:1914` — `hat_expand` troca `$TODO_FILE` **literalmente** no `writes:` do chapéu, lido contra
  `git diff --name-only`; um repo-alvo com `TODO_FILE="./TODO.md"` — ou `HANDOFF_DIR="./docs/handoffs"`,
  que a normalização do `F4` também não pega — reproduz o defeito que o `F4` acabou de consertar,
  com raio menor. Direção: normalização **única** na leitura do config, com um probe por chave.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **`run_phase` cria o diretório de log da sessão sem guarda nenhuma** — `bin/sdd:3738` (`mkdir -p`) — é a
  irmã, um nível acima, da escrita que o `R8` guardou: com `.sdd/logs` em modo 500 o `sdd run`
  morre com um `mkdir: Permissão negada` cru, **rc 1, zero linha de ledger e zero `warn` do kit**.
  Não é remendo de escopo: o log da sessão **é** a evidência da fase, então talvez a resposta certa
  seja um `die` com frase e não um `warn` que segue — decisão que merece achado próprio.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **Uma sessão escreve o ledger com o `bin/sdd` que tinha em MEMÓRIA ao ser lançada** —
  `bin/sdd:3503` — logo a missão que ACRESCENTA um campo é, por construção, a única que não o
  registra: 3 das 4 rodadas desta missão saíram com o `turns` nulo, e o ledger não distingue
  "medido nulo" de "não medido" — fail-open de leitura (o `review_scope_check` que era a 2ª
  superfície virou `hat_guard_check`, que lê commits e árvore). Direção: o
  `sdd run` avisar quando o `bin/sdd` mudou sob ele; a métrica citar `.sdd/logs/` na estreia.
  — descoberto por `sdd-qa` na missão `20260901-o-revisor-so-acha` (2026-09-01)

### Saída humana e cosmética

- [ ] **35% do `docs/pipeline.md` é um subsistema só, e ele cresce toda missão do ledger** —
  `docs/pipeline.md:923` — as seções `The autonomy ledger` (323 linhas) e `The kaizen loop` (174)
  somam **497 de 1419** (eram 245 de 570 em 2026-08-17) num arquivo que é o índice do pipeline.
  Índice que carrega profundidade é o doc que a próxima sessão não lê inteiro. Direção: `references/` para
  o ledger + juiz, com o índice roteando — **não** executar no meio de outra missão, é refator de
  estrutura e merece a sua. — descoberto por `sdd-docs` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **`turns` não aparece em nenhuma view humana** — `bin/sdd:3503` — o campo está na tabela de
  campos do `docs/pipeline.md` e é lido só por `jq` ad-hoc, então quem instala o kit não descobre
  que ele existe — e ele é metade da M2 desta missão. Direção: dizer no `§ Field reference` que é
  instrumento cru, ou pendurá-lo na célula do `review loop` do `--by-mission`.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **`sdd adr check` só fala texto + rc; não existe `--json`** — `bin/sdd:6404` (`check)`) — quem quiser
  mais que "passou/não passou" (um job de CI que anota o PR, um painel de migração contando o que
  falta num repo em `warn`) hoje parseia a saída humana, que não é contrato. Direção: acrescentar
  `--format json` **quando houver consumidor** — sem um, é superprodução, e a decisão 8 do grill
  recusou construí-lo agora. — descoberto por `sdd-planner` na missão
  `20260917-o-numero-do-adr-nao-e-prosa` (2026-09-17)

- [ ] **As ADRs 0001–0007 não têm `Spec:`, e por isso 14 missões deste repo não podem declarar
  `adr:`** — `docs/adr/0001-judge-split-deterministic-series-model-verdict.md:1` — nenhuma das sete
  liga-se a uma missão por artefato (`git log --diff-filter=A` de cada uma não toca
  `docs/handoffs/`), então o par das duas direções não fecha e `adr: none` seria rótulo sem
  artefato. É o que segura este repo em `ADR_CHECK=warn`: o `sdd adr check` conta 14 sem decisão, e
  `block` mandaria as 14 de volta para PLAN. Direção: o humano mapeia as sete, `sdd adr new --spec`
  escreve os dois lados, o resto vira `adr: none`, e aí a chave volta para `block`. — descoberto
  por `codereview` na missão `20260917-o-numero-do-adr-nao-e-prosa` (2026-09-17)

### Comentário e registro

- [ ] **Drift de comentário em código não tem dono: nem a DOCS nem a EXEC** — `agents/sdd-docs.md:9`
  — comentário de código É documentação viva, mas o `writes:` da DOCS não lista `bin/sdd` e o
  `hat_guard_check` para a linha quando ela o conserta. `HAT_WRITES_EXTRA` não é a saída: declarar
  `bin/sdd` para a DOCS entrega o runner inteiro a quem não edita código, e a fronteira existe para
  isso. Direção: a REVIEW endereça o achado à EXEC, ou a DOCS ganha um caminho estreito.
  — descoberto por `sdd-docs` na missão `20260911-o-juiz-nao-mente-sobre-a-janela` (2026-09-12)

- [ ] **O `rows=13` do `gate:` da QA não sai do extrator do `gate_REVIEW`** —
  `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` — o awk literal do gate responde `rows=8`
  sobre `templates/review.md`; 13 é a contagem sem o filtro de cabeçalho e separador. A conclusão
  da J6 está certa e foi refeita nesta rodada (`##` devolve `NO-TABLE`), mas o número citado como
  evidência não reproduz. Direção: recontar com o extrator, ou dizer qual variante foi usada.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **Refutação de handoff cita evidência que não existe** —
  `docs/handoffs/20260901-o-revisor-so-acha/30-handoff-qa.md:79` — a refutação R2 afirma que "o
  prompt nomeia `TODO.md` explicitamente", e nem `phase_extra REVIEW` nem `agents/sdd-reviewer.md`
  contêm essa string (só a variável `TODO_FILE`). A **conclusão** segue certa e tem probe; a
  evidência citada é que não existe. Imprecisão em artefato de trilha de auditoria: não se conserta
  reescrevendo o handoff de uma fase encerrada, e sim registrando aqui.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **A linha `kit-touched` do ledger afirma uma atribuição que o runner nunca mediu** —
  `bin/sdd:2903` — o `warn` da tela ressalva (*"if that was you working on the kit in another
  terminal, this is that"*, `:2889`); o `KIT_TOUCHED_WHY`, que vai para o ledger e para a escalada,
  afirma *"a session committing outside its mission's repo"*. Medido no `796e334`: a única escalada
  da fatia foi o HUMANO commitando o kit durante a fase PR do `sales_quote`, e o juiz a lê como
  fricção daquela versão — a mesma classe que a T1 fechou para `session-died`. Direção: a linha diz
  o que o runner sabe (o sha do kit mudou durante a fase), ou ele mede a atribuição.
  — descoberto por `claude` na leitura do juiz de 2026-09-20 (2026-09-20)

### Idioma

- [ ] **Dois arquivos ficam fora do sensor de idioma** — `tests/check-lang.sh` (função
  `surface()`) — as exclusões são corretas e documentadas (em `check-templates.sh` as regexes
  PT-BR **são** o contrato dos templates; em `check-lang.sh` o dicionário precisa conter o que
  detecta), mas nesses dois arquivos prosa portuguesa passa despercebida. Direção: mover o
  contrato dos templates para `tests/template-contract.txt` (dados), deixando a lógica inglesa;
  sobra o `check-lang.sh`, irredutível e por isso com `selftest()`. — descoberto por
  `sdd health`/`check-lang` na missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **`surface()` do `check-lang.sh` ENUMERA arquivos em vez de casar `docs/*.md`** —
  `tests/check-lang.sh:50` — um doc novo em `docs/` nasce **fora** da régua de idioma enquanto o
  `CLAUDE.md § Idioma` promete `docs/` inteiro; o I4 cobriu `docs/graphify.md` **um arquivo por
  vez**, que é o remendo e não o conserto. Direção: glob, com o piso derivado junto — é decisão,
  porque glob e piso enumerado são a mesma discussão do item do piso acima.
  — descoberto por `sdd-planner` na missão `20260901-o-revisor-so-acha` (2026-09-01)

### Custo e escala

- [ ] **O `sdd-publisher` não consegue esperar o `sdd health` dentro de uma sessão headless** —
  `agents/sdd-publisher.md:41` — o agente iniciou o health "em background" e encerrou o turno
  "esperando a notificação": em `claude -p` encerrar o turno encerra a sessão, e o health morreu
  com ela (US$ 1,46 por nada); a sessão seguinte rodou em primeiro plano e levou 82 min (US$ 2,73).
  É a classe do *"waiting for the suite"* de `4c86712`, agora na fase PR. Direção: o **runner** roda
  `sdd health` antes de abrir a sessão de PR quando o carimbo está inválido — é comando, não
  julgamento. — descoberto por `humano` na missão `20260829-o-incremento-que-andou` (2026-08-30)

- [ ] **A suíte segue acima do alvo "<30 s" da D7, mesmo depois do paralelismo** —
  `tests/run-all.sh:95` (`run()`) — a saída "subir o default" foi tomada e executada (pool + `min(núcleos, 8)`,
  ver KAIZEN_LOG de 2026-08-16): mediana 54,13 s → **32,87 s** na mesma sessão, score 30/30
  intacto. Restam as duas saídas de régua, ambas do humano: subir o alvo da D7 (o "≤15 s" do
  I13.1 já é história) ou aceitar o estouro — hoje ~300 s (2026-09-25). — medido por
  `sdd-executor` e `humano` nas missões `20260815-ledger-sem-ponto-cego` e no kaizen do
  paralelismo (2026-08-16)

- [ ] **Sensor novo na suíte é multiplicador, não parcela: custa uma vez por mutante** —
  `tests/run-all.sh:200` — `check-health.sh` roda em ~1,5 s sozinho e roda **dentro de cada
  mutante**, hoje 81. Medido em passadas sequenciais e máquina quieta, `main` (`6d68dfc`) contra o
  HEAD desta missão: **155,97 s → 210,81 s**, +55 s com 11 mutações a mais no mesmo diff (o +281 s
  do EXEC não reproduz: era contenção). Direção: rodar por mutante só o sensor que o alcança.
  RESOLVED by b874141 (o passo que matou o mutante roda primeiro; amostra de 40: 389 → 171 s).
  — descoberto por `sdd-executor` na missão `20260817-catraca-do-backlog` (2026-08-17)

### Sem seção — chegaram depois da última classificação

> ⚠️ Esta seção **chamava-se "Adiados por YAGNI"** e não guarda mais nenhum adiamento: os três que
> havia (espelho global de vereditos, multi-missão por `git worktree`, `sdd digest`) viraram Y1–Y3
> da tabela **Decisões adiadas por YAGNI** do [`CONTEXT.md`](CONTEXT.md), onde cada um nomeia o
> evento que o reabre — pela régua D15, ausência de consumidor é decisão adiada, não achado. Os
> itens abaixo são achados de verdade que foram apendados ao fim do arquivo e nunca classificados;
> quem mexer num deles o move para a seção a que ele pertence.

- [ ] **`gate_EXEC` valida por uma leitura e conta por outra, e uma célula vazia as separa** —
  `bin/sdd:993` — o laço lê com `IFS=$'\t' read`, que COLAPSA tabs por serem whitespace de IFS; o
  `checkpoint_tally` lê com `awk -F'\t' $4`, que não colapsa. Uma célula vazia e os dois caem em
  colunas diferentes — o que desmente o cabeçalho da própria função ("the runner's ONE count").
  Fail-open pela D15: diferencial sobre `| I1 | a |  | done | pending |` dá `MAIN rc=1` contra
  `HEAD rc=0`, o gate passa onde recusava. Direção: o laço para de depender de IFS, e os dois
  leitores são provados iguais por asserção DIFERENCIAL, nunca pelo comentário.
  — descoberto por `sdd-reviewer` na missão `20260829-o-incremento-que-andou` (2026-08-30)

- [ ] **O caminho histórico infere `M` quando a memória está vazia, e M é o maior valor possível** —
  `bin/sdd:2876` — sem memória o braço `advanced` passa a ser satisfeito por qualquer prosa que não
  seja `M of M`: certo na primeira linha de uma missão (14 linhas reais), fabricação depois de um
  `pass` (4) ou com `M` mudado (2). A guarda `.moved != false` (`f00c2dc`) fechou o buraco
  alcançável; a inferência segue para quem mexeu no disco. Direção prototipada e medida: memória
  guarda o total FEITO, `pending_before := M - done_before` — um invariante que muda **0 de 158**
  linhas do ledger real. Não aplicado: reescreve a decisão 3 do grill — julgamento humano.
  — descoberto por `sdd-reviewer` na missão `20260829-o-incremento-que-andou` (2026-08-30)

- [ ] **A regra `doing` conta como pendente não tem probe, e sem ela o `gate_EXEC` fecha a fase por
  cima de um incremento em voo** — `bin/sdd:527` — degradar `$4 == "pending" || $4 == "doing"` para
  só `pending` deixa a suíte inteira VERDE, e o `sdd status` passa de `1 of 1 increment(s) still to
  execute` para `1 increment(s) done, suite green` com `next phase: QA`. É herdada da `main`, mas
  esta missão MOVEU a regra para uma função nova e a reafirmou no cabeçalho dela — que é
  exatamente quando "gate novo entra com mutação" morde. Direção: fixture com uma linha `doing` e
  `mut_EXEC_tally_doing_is_done`.
  — descoberto por `sdd-reviewer` na missão `20260829-o-incremento-que-andou` (2026-08-30)

- [ ] **A metade `repo` da chave de memória do caminho histórico não tem probe** — `bin/sdd:2876` —
  trocar `([$r.repo, $r.mission] | tostring)` por `($r.mission // "")` deixa a suíte verde, e sob
  `--all-repos` duas missões de mesmo slug em repos diferentes colapsam numa identidade só:
  `2 advanced · 0% waste` vira `1 advanced · 1 churned · 50% waste`. É a mesma classe do
  `ledger_repo_root`/`CDPATH` que já custou uma CRITICAL — contaminação silenciosa entre repos.
  Direção: um par de linhas de mesmo slug em dois repos na família de fixtures `--all-repos`.
  — descoberto por `sdd-reviewer` na missão `20260829-o-incremento-que-andou` (2026-08-30)

- [ ] **A guarda `$r.phase == "EXEC"` do `historic_progress` não tem probe e falha na direção da
  lisonja** — `bin/sdd:2876` — removida, a suíte fica verde e uma linha NÃO-EXEC que passou o gate
  passa a zerar a memória do EXEC, de modo que a próxima linha antiga é medida contra `M` em vez de
  contra a linha acima dela: `EXEC(3 of 4) → QA(pass) → EXEC(3 of 4)` lê `2 advanced · 1 churned ·
  33% waste` íntegro e `3 advanced · 0 churned · 0% waste` sabotado. Direção: uma linha QA `pass`
  entre duas linhas EXEC de prosa no fixture `histfix` que já existe.
  — descoberto por `sdd-reviewer` na missão `20260829-o-incremento-que-andou` (2026-08-30)
- [ ] **Nenhuma das skills `qa-report`/`qa-execution` conhece o campo `Closable by:`** —
  `agents/sdd-qa.md:118` — `grep -rn Closable ~/.claude/skills/qa-*` responde **zero**, então o
  campo só chega ao disco pelo template local do repo ou pelo `sdd-qa` marcando arquivo por arquivo.
  Em repo-alvo novo a Âncora 3 inteira roda em regime "ausente ⇒ bloqueia". `f7bcf10` ESTREITOU o
  raio — semeia o campo no template de que elas copiam e o `sdd preflight` cobra —, mas NÃO fechou
  este item: as skills seguem sem o conhecer. Direção: ensinar o campo às skills, ou o `sdd-qa`
  assumir a marcação como passo declarado.
  — descoberto por `sessão coordenadora` na missão `20260918-a-sessao-morreu-e-o-gate-levou-a-culpa` (2026-09-18)

- [ ] **Fase executada à mão não tem como ser registrada, e o ledger afirma que ela não aconteceu** —
  `agents/sdd-publisher.md:1` — a fase PR da SQ-129 foi montada à mão depois de três mortes por
  memória; não há sessão de publisher no ledger e o custo não entra na soma (US$ 161,29 é o total
  que o journal conhece, e ele para na DOCS). A lacuna virou prosa no `50-pr.md`, que nem o
  `sdd autonomy` nem o `sdd kaizen` leem. Direção: `sdd note-manual <fase>`, irmão do `intervention:`
  — ⚠️ pede o **sexto** `event` do ledger, com dois leitores a ensinar no mesmo commit.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)

- [ ] **O teto de orçamento não conhece "missão reaberta"** — `bin/sdd` (`BUDGET_MISSION_USD`) — o
  conserto pós-review paga o preço do estouro que a entrega causou, então o teto pune justamente o
  ciclo que deveria ser incentivado. Medido na SQ-129: fechou o PR com US$ 161,29 de 150 sob
  override, o `@codex review` achou um P1 real, a missão reabriu num `R5` e a EXEC do conserto
  precisou do mesmo override — com o número já estourado pela entrega. O conserto custou US$ 9,03.
  Direção: distinguir gasto de entrega de gasto de conserto pós-review, ou estender o teto ao reabrir.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)

- [ ] **`Test Coverage` = A do revisor não implica que os casos negativos existam** —
  `agents/sdd-reviewer.md:178` — um P1 real passou por **três** rodadas de `sdd-reviewer` (a última
  com essa nota) e quatro checks de CI verdes; o caso que faltava era o negativo, e nenhum sensor
  era obrigado a cair. O `@codex review` o achou no PR #167. Direção: o revisor enumera qual
  sabotagem provou cada nota — hoje narra em prosa, e prosa não é verificável.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)

- [ ] **`sdd approve` commita na branch corrente, mesmo a padrão, e só o `00-missao.md`** —
  `bin/sdd:6562` — medido aqui: o commit da aprovação caiu na `main` local, com o `01-plano.md`, o
  `checkpoint.md` e o ADR citado fora do git, ou seja, uma missão aprovada sem plano no histórico.
  Em repo-alvo, alguém que dê `push` na `main` publica isso. Direção: recusar ou avisar quando a
  branch é o `DEFAULT_BRANCH`, e commitar o diretório da missão inteiro.
  — descoberto por `sessão coordenadora` na missão `20260922-o-motivo-da-fase` (2026-09-22)

- [ ] **`check-coordination.sh` reprova quando herda SIGINT ignorado** — `tests/check-coordination.sh:616`
  — o probe `signal status` (sinal 2) manda SIGINT ao `sdd run` e espera a morte; lançada com `&` de shell
  não interativo (o `setsid nohup … &` que se usa para `sdd run`), a suíte nasce com `SigIgn 0x7`, o
  bash não desfaz sinal ignorado na entrada, e o probe estoura 8 s: vermelho 3 de 3, verde 3 de 3 em
  primeiro plano. O `TEST_CMD` de um gate num `sdd run` destacado herdaria a máscara (não medido).
  Direção: SIG_DFL no filho do probe, ou declarar a pré-condição no cabeçalho.
  — descoberto por `sessão coordenadora` no PR #58 `fix/ancoras-do-catalogo` (2026-09-23)

- [ ] **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — `bin/sdd:9449` — o
  worker relê o `bin/sdd` e sobe um 2º Python (`check`) só para provar a reentrada. Medido: sem ele
  o `sdd install` cai de ~160 para ~130 ms, e o #48 levou a suíte comportamental de 117 para 251 s.
  A parte barata já saiu no branch `perf/catalogo-para-no-primeiro-vermelho` (`-I -S` e acordar pelo
  pidfd, 158 → 147 ms). Direção: provar o worker direto por um FD do flock herdado, fechado antes do
  1º fork, sem afrouxar "ambiente sozinho não autoriza" — pede ADR.
  — descoberto por `sessão coordenadora` no branch `perf/catalogo-para-no-primeiro-vermelho` (2026-09-23)

## Decidido — não reabrir
<!-- sdd:decided -->
- **O `sdd preflight` não provaria que a sessão headless executa comando** — refutado: `bin/sdd:4524` manda rodar `bash -c 'echo sdd-preflight-ok'` sob as flags do `run_phase` desde `2083680`, e sob o chapéu do executor desde 2026-09-06 (2026-09-25)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:6128` (2026-09-25)
