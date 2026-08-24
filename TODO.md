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

- [ ] **O `stub-argv.txt` do `check-health.sh` nunca é apagado entre mundos de fixture** —
  `tests/check-health.sh:930` — todo `health_run` sobrescreve, ninguém remove. Hoje não reproduz
  fail-open (medido: sem chamada nenhuma à suíte, o arquivo some e a asserção acusa certo), mas no
  dia em que `cmd_health` ganhar um segundo caminho para a suíte a última escrita vence calada.
  Direção: apagar no `green_world`, como as outras fixtures fazem.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Dois resíduos de sensor que precisam de DUAS edições, e nenhum tem testemunha externa** —
  `tests/check-todo.sh:66` — neutralizar um helper E descartar o `cfail` do controle; apagar o
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
  `bin/sdd:668` contra `tests/check-mutation.sh:1485` — a chave lê `bin tests templates config`,
  mas `sandbox()` também copia `agents/`, `CLAUDE.md`, `TODO.md` e `docs/adr`. Mudança confinada a
  esses quatro mantém o carimbo válido sobre conteúdo que o catálogo de fato mede — a
  regra 12 do `check-health.sh` lê o `CLAUDE.md`. Estreitamento deliberado (a fase DOCS edita
  `CLAUDE.md`, e chavear nele custaria uma segunda rodada de ~20 min por missão). Direção: ler a
  lista do próprio `sandbox()`, decidido o custo. — descoberto por `sdd-executor` na missão
  `20260819-fecho-...` (2026-08-19)

- [ ] **Quatro regras do `check-health.sh` sobrevivem à passada adversarial** —
  `tests/check-health.sh:826` — o probe aritmético conclui no vazio (`n=$((n+1))` não tem `)"`,
  então some com e sem `[^(]`); `CAPTURE_FLOOR=12` contra 16 capturas reais e a constante sem probe;
  as alternativas `:` e `return` da guarda nunca usadas e sem probe; e a chamada de topo
  `policy_report "$ROOT"` sem probe **e** fora do alcance do catálogo, que só sabota `bin/sdd`.
  Direção: lista contável de reports, como o `check-entrypoint.sh` faz.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O `guard:` fala alto em três formas que NÃO abortam, e é cego a helper fora da região** —
  `tests/check-health.sh:754` — `if x="$(cmd)"`, `local x="$(cmd)"` e corpo de here-doc são
  seguros sob `set -e` e viram offender, e a mensagem manda pôr `|| true`, que quebraria o `if`.
  No outro sentido, um `health_*()` definido depois da âncora `cmd_status()` não é censurado.
  Regra que reprova código correto é regra que o próximo autor apaga. Direção: pular
  `if`/`while`/`until`/`local`/here-doc e censurar todo `health_*()` onde ele estiver.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Quatro regras do `check-todo.sh` que o selftest diz medir e não mede** —
  `tests/check-todo.sh:1190` — a contagem de violações trocada pela constante `3` passa (o fixture
  tem exatamente 3); o `^` do `grep '^## Aberto'` é load-bearing e o probe não o exercita; o
  `flush()` do ramo da caixa marcada não tem probe (esconde 3 de 4 violações); e o probe
  `--check ''` é vácuo quando `$ROOT/TODO.md` não existe. Direção: segundo fixture com contagem
  DIFERENTE, e prosa contendo `## Aberto` fora da coluna 0.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **Os dois literais "ESTRUTURAIS" da regra 3 do `check-checkpoint.sh` afrouxam em verde** —
  `tests/check-checkpoint.sh:227` — `PIPE_MECH="awk"` vira `"aw"` e `PIPE_ESCAPE='\|'` vira `'\'`
  com o selftest verde; só `"a"` mata, e por acidente do fixture. O cabeçalho lista oito sabotagens
  mortas, todas de APAGAR — afrouxar, que é a regra do `CLAUDE.md`, não está coberto. Degradado
  assim, qualquer doc com "raw" e uma barra satisfaz a regra. Direção: um probe por literal, contra
  um doc de quase-acerto (`awk` sem `-F'|'`).
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O `pushd "$(…)"` tem o mesmo bug de CDPATH e não é medido nem declarado** —
  `tests/check-pipefail.sh:252` — `pushd` consulta `$CDPATH` e ecoa o diretório resolvido
  exatamente como `cd`. Medido: `tests/check-pipefail.sh --check` sobre um arquivo com
  `pushd "$(dirname "$0")"` responde rc 0. Não está entre os dois limites que o comentário do
  `CD_RE` declara nem entre os do `TODO.md`. Nenhuma instância viva hoje. Direção: `(cd|pushd)` no
  `CD_RE`, ou entrar no bloco de limites declarados.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O braço 1 da guarda de forma do `ledger_repo_root` não tem probe, e a mutação junta os
  dois** — `bin/sdd:946` — sob o shim pré-2.31 o valor não começa com `/`, então quem dispara é
  sempre o braço 2; o braço 1 (uma linha só, caminho absoluto) só é alcançado por um repo cujo
  CAMINHO contém `\n`, e nenhum fixture tem um. `mut_LEDGER_repo_root_shape_blind` apaga os dois de
  uma vez, então o catálogo não os distingue. Direção: fixture com `\n` no caminho e dividir a
  mutação em duas. — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-19)

- [ ] **O piso do shim pré-2.31 prova que o shim é um git falso, não que o runner o consulta** —
  `tests/check-autonomy.sh:1443` — o piso invoca `git` diretamente sob o `PATH` do shim, e nada
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
  `bin/sdd:1591` — a guarda que ela anuncia (`ledger_repo_root` recusando a resposta de duas
  linhas) tem par diferencial e mutação; a linha que **fala** com o operador não tem. O
  `check-preflight.sh` já carrega a receita pronta — o shim `$FIX/.bsd` faz exatamente isto para
  a userland GNU. Direção: um shim `.oldgit` e o par (fala com git velho, cala com git novo).
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **Três frouxidões da regra da caixa pelada passam pelo selftest** —
  `tests/check-todo.sh:278` — tirar o limite final `([ \t]|$)`, alargar `[ xX]` para `.` e tirar
  o `>` do ancoramento deixam os 86 probes verdes. A terceira estreita a regra: caixa dentro de
  bloco de citação deixaria de ser pega e nada diria. Regra sem probe é o que a passada
  adversarial existe para achar. Direção: um probe por frouxidão, como `inlinebox.md` já faz.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `tail_of` aceita qualquer par de crases como se fosse a atribuição** —
  `tests/check-todo.sh:190` — a regra pergunta "o rabo tem um code span", não "o rabo nomeia um
  agente", então um título com código inline satisfaz a metade da atribuição do mesmo jeito que
  já satisfaz a da âncora (fraqueza espelhada, e só a da âncora está declarada no cabeçalho).
  A forma aguda virou conserto; a que sobra é REGRESSÃO desta missão, medida em diferencial (o
  sensor do merge-base recusa o item, este aceita). Fechar exige a re-derivação semântica posta
  fora de escopo: toda regra sintática tentada inventa 5 violações no arquivo real.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **A regra `cdpath:` não vê `cd --` nem comando quebrado com `\`** —
  `tests/check-pipefail.sh:252` — o grupo de flags é `-[[:alpha:]]+`, e `--` não tem alfa
  nenhum depois do segundo traço, então `cd -- "$(...)"` sem guarda passa limpo; e as três
  regras leem linha física, então operando na linha seguinte a um `\` é invisível. Nenhuma
  instância viva hoje. Direção: alargar para `(--|-[[:alpha:]]+)` e declarar a continuação.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `moved2` do `cmd_kaizen` não tem asserção que morra ao apagá-lo** —
  `bin/sdd:2453` — a asserção `covered:` do `moved` cobre a primeira atribuição; neutralizar a
  do retry deixa `check-kaizen.sh`, `check-autonomy.sh` e o catálogo verdes, porque o default
  local `false` coincide com o que o regime do fixture espera. Só o hardcode para `true` morre.
  Direção: um mundo em que o retry mexe no disco de verdade, ou estreitar o que a asserção diz.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **Duas mutações têm `sed` sem endereço e sabotam um segundo sítio calado** —
  `tests/check-mutation.sh:203` e `:508` — a `RUN_inverted_journal` também vira a guarda
  `DRY_RUN` de `ensure_mission_branch` (`bin/sdd:1489`), a única que impede `--dry-run` de fazer
  `git checkout` de verdade; a `RUN_on_axis_forked` também edita o `on_axis` do juiz. Inertes
  hoje, e é a classe que o `_cdpath_leak` já custou. Direção: endereçar ao corpo da função.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `check-templates.sh` não tem auto-teste e nenhuma mutação o alcança** —
  `tests/check-templates.sh:30` (a função `check()`) — ele mede `templates/`, então o catálogo,
  que sabota o `bin/sdd`, nunca o mata; e `check()` não tem probe nenhum. Regex quebrada ali
  reporta "template contract intact" para sempre sobre 60 asserções, inclusive as do
  `40-review-r<N>.md` que o `gate_REVIEW` lê. Está nas duas situações que o `CLAUDE.md` manda
  cobrir com `selftest()`. Direção: `--check <arquivo>` mais probes, como o `check-todo.sh` fez.
  — descoberto por `sdd-executor` na missão `20260818-lote-facil` (2026-08-18)

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

- [ ] **A releitura pós-checkout confere o campo `branch:`, não a identidade do plano** —
  `bin/sdd:1405` — se a branch declarada carrega uma cópia ANTIGA do mesmo `00-missao.md` (slug
  reusado, branch velha de mesmo nome), o campo bate, a guarda passa e o pipeline roda contra um
  plano que ninguém aprovou nesta sessão. O comentário da própria função já enuncia o risco ("a
  branch carrying an OLDER copy"). Direção: comparar hash do artefato antes e depois do checkout.
  — descoberto por `sdd-reviewer` na missão `20260816-portas-do-humano` (2026-08-17)

- [ ] **A linha `N kit agent(s) checked` não é observável por nenhum fixture** — `bin/sdd:1356` —
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
  `tests/check-entrypoint.sh:234` — a passada adversarial da r2 matou 20 de 25 degradações, e o
  que sobra sem probe é a comparação do próprio diferencial: neutralizá-la faz o sensor ler "1 vs
  1" e seguir verde, então o dia em que o fall-through parar de reproduzir neste bash passa
  despercebido. Hoje o limite é o par de contagens ser IMPRESSO na linha `ok`. Direção: um gancho
  de contagem falsa, como o `SDD_EP_FORCE_FAIL` da composição, com um probe por ramo.
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

- [ ] **O formato de achado vale para os repos-alvo, mas o sensor só guarda o arquivo do kit** —
  `tests/check-todo.sh` vs `CLAUDE.md` (princípio 5) — a regra de formato e o ciclo "fechado é
  apagado" são prescritos para o `TODO.md` de **qualquer** repo, e os agentes escrevem nos dois;
  o sensor mora na suíte do kit e nunca é instalado. Um alvo acumula o mesmo inchaço sem nada
  medindo. Direção: `sdd install` copiar o sensor (ou uma versão dele) e o `starter.conf` sugerir
  incluí-lo no `TEST_CMD`. ⚠️ As regras já são estruturais e language-neutral de propósito, então
  ele roda num alvo `OUTPUT_LANG="en"` sem mudança. — descoberto por `humano` revisando o sensor
  novo (2026-08-16)

- [ ] **A economia de `current_phase()`/`next_pending_phase()` depende da memoização e ninguém
  conta** — `bin/sdd:475-492` vs `:193-210` — as duas reavaliam o gate de toda fase a cada
  chamada, e isso só é barato porque `run_check_cmd` cacheia por `$cmd`. Quem mexer em **quando**
  `invalidate_checks` roda reintroduz N execuções de `TEST_CMD` por projeção, em silêncio.
  Direção: `TEST_CMD` que incrementa contador em arquivo, afirmando que o número não cresce com
  o número de fases pendentes. — descoberto por `sdd-reviewer` na missão
  `20260815-i13.1-autonomy-log` (2026-08-15)

- [ ] **A asserção "the retry carries its own moved" não falha pela propriedade que promete** —
  `tests/check-autonomy.sh:208` — no fixture, `moved` sai `false` com qualquer baseline: o retry
  só é alcançado quando `before == after`, então a asserção nunca observa um `moved:true` genuíno
  pelo caminho real. Ainda pega campo ausente ou `moved` sempre-`true`; só o nome discrimina mais
  do que ela. — descoberto por `/codereview` na missão `20260815-i13.1-autonomy-log` (2026-08-15)

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

- [ ] **O conjunto de fronteira do `MAXC_RE` não tem probe, e o comentário jura paridade com o
  `PIPE_RE`** — `tests/check-pipefail.sh:219` — o `PIPE_RE` ganha quatro probes de falso-positivo
  para essa mesma classe; o `MAXC_RE` copia a grafia e não ganha nenhuma. Trocado por `.+`, o
  selftest fica verde e a regra passa a INVENTAR violação nas quatro formas que os probes do
  vizinho existem para recusar. É a classe "comentário afirmando paridade não é paridade" que o
  `CLAUDE.md` já nomeia duas vezes. Direção: derivar o miolo comum de UMA variável, ou dar ao
  `MAXC_RE` os mesmos quatro probes. — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `gate:` do frontmatter só é cobrado quando existe, e 6 das 14 rodadas não o têm** —
  `bin/sdd:568` — a recusa de placeholder no `gate:` deixa AUSENTE em paz de propósito, para não
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
  `bin/sdd:461` — em projeto sem interface a única âncora é `frontmatter gate`, testada só por
  `-z`. O `templates/handoff.md:7` entrega `gate: <a evidência...>`: um handoff copiado sem tocar
  a linha passa o gate com `journey walked without a browser interface`. É o defeito que o I3
  fechou no `gate_REVIEW`, vivo um gate adiante, e a `placeholder()` está presa dentro do awk.
  Direção: extrair a regra para uma função e cobrá-la nos dois gates.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O ramo de forma do `score:` no `cmd_health` não tem asserção nem mutante** —
  `bin/sdd:1982` — é ele que impede que um `score:` presente e ilegível caminhe até `ok` e carimbe:
  sem ele os três `[ "" -ne … ]` devolvem rc 2, o `if` lê falso e o `else` credita a rodada.
  Nenhum `write_stub_suite` usa score malformado. Mesma linha: `grep -m1` pega a PRIMEIRA linha
  `^score: ` e a autoritativa é a última. Direção: fixture com score torto + mutante, e `tail -1`.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O piso do catálogo mora só no consumidor; quem imprime o `score:` segue sem nenhum** —
  `tests/check-mutation.sh:1631` — com `CATALOG=()` o laço roda zero vezes, `errors` fica 0 e o
  arquivo imprime `score: 0 caught, 0 known gap(s), of 0` saindo 0. O F1 pôs o piso no `cmd_health`,
  hoje o único chamador — mas duas frases do próprio runner (`bin/sdd:1961` e `:2030`) mandam o
  operador rodar `tests/run-all.sh --with-mutation` à mão, e aí o verde volta a mentir.
  Direção: comparar `${#CATALOG[@]}` com as definições `mut_*()` no próprio catálogo.
  — descoberto por `sdd-executor` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **`FIXME` e `XXX` são recusados pelo `gate_REVIEW` sem nenhum mundo que prove** —
  `bin/sdd:578` — a lista de palavras de preenchimento tem sete entradas e só cinco têm mundo no
  `check-gates.sh`. Medido na passada de sabotagem do F3: tirar `WIP` ou `FILLME` deixa a asserção
  vermelha, tirar `FIXME` ou `XXX` a deixa **verde**. As duas nasceram assim no I3 e a lista cresceu
  por cima. Regra sem probe é decoração e some calada no dia em que alguém a reescreve.
  Direção: um mundo para cada, ou tirá-las da lista.
  — descoberto por `sdd-executor` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O censo `guard:` conta captura escrita dentro de COMENTÁRIO** —
  `tests/check-health.sh:1352` — a regra varre a região do `sdd health` linha a linha e não sabe
  distinguir código de comentário. Medido nesta rodada: um exemplo de reprodução colado num
  comentário do `cmd_health`, na forma `o="$( … )"`, virou a 23ª captura e a catraca de duas mãos
  reprovou a suíte. Falha FECHADA, então não certifica nada de errado — mas proíbe documentar a
  armadilha com o comando que a demonstra, que é justamente como esta casa documenta.
  Direção: pular linha cujo primeiro caractere não-branco é `#`, com probe nos dois sentidos.
  — descoberto por `sdd-reviewer` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **A guarda de vazio do `mutation_stamp_key` só cobre a ausência TOTAL dos quatro caminhos** —
  `bin/sdd:806` — com `tests/` presente e `bin/` ausente, o `find` imprime o que achou, sai não-zero,
  o `2>/dev/null` engole o aviso e a chave sai de uma listagem PARCIAL, sem sinal nenhum de que
  faltou diretório. Hoje inalcançável (as duas pontas só perguntam por raiz cujo `tests/` tem
  catálogo), e o comentário da função declara só o caso "todos ausentes".
  Direção: exigir que cada caminho de `MUTATION_STAMP_PATHS` exista, ou carimbar a lista na chave.
  — descoberto por `sdd-reviewer` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

### Contrato e configuração

- [ ] **`.sdd/config.sh` que não parseia é reportado como "declares no TEST_CMD"** —
  `bin/sdd:2183` — a checagem 2b lê o `TEST_CMD` sourceando o config num subshell com
  `>/dev/null 2>&1`, então o erro de sintaxe é engolido e o valor chega vazio: o operador ouve que
  a chave não existe quando o arquivo inteiro está quebrado. Medido nesta rodada que o `set -e`
  NÃO derruba a substituição (sem `inherit_errexit`), então o ramo existe e é alcançável.
  Direção: capturar a stderr do source e, se ela não estiver vazia, dizer "não parseia" e mostrá-la.
  — descoberto por `sdd-reviewer` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **A catraca do backlog e o carimbo de mutação colidem em toda missão** —
  `tests/health-baseline.txt` — o arquivo mora DENTRO dos quatro diretórios da chave do carimbo,
  então cumprir o princípio 5 (achado fora de escopo vira item) obriga a bumpar a catraca, o que
  invalida o carimbo e cobra outra rodada de 20 a 50 min antes do `gate_PR`. Medido nesta sessão:
  o carimbo `0575d68…` foi ganho e perdido pelo commit que registra estes achados. Direção: tirar
  o baseline da chave, ou aceitar o custo declarando-o no boot da fase PR.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **A regra do `--list` é só de espaço, e o `eval` que roda o `TEST_CMD` não é** —
  `bin/sdd:2039` — o `case " $kit_test_cmd " in *" --list "*` não vê `TEST_CMD` com TAB antes da
  flag, nem `"--list"` entre aspas; o `eval` do `run_check_cmd` (`bin/sdd:263`) entrega `--list`
  à suíte nos três casos. O `sdd health` responde `ok TEST_CMD runs the suite` e todo gate passa
  contra uma suíte que não rodou — o buraco que o I2 existe para fechar, outra grafia.
  Direção: normalizar o espaço em branco antes do `case`.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **Lixo ignorado pelo git dentro dos quatro diretórios move a chave do carimbo** —
  `bin/sdd:688` — a chave é `find -type f` sobre a árvore, não sobre o que o git rastreia: um
  `tests/debug.log` (ignorado por `*.log`, invisível no `git status`) muda a chave, e um swap de
  editor que nasce e morre durante a rodada dispara a guarda de janela, jogando fora um verde
  legitimamente ganho. O mundo 8 do `check-gates.sh` depende desse mecanismo de propósito.
  Direção: basear a chave nos arquivos rastreados, ou podar dotfiles.
  — descoberto por `sdd-qa` na missão `20260819-fecho-que-nao-mente` (2026-08-19)

- [ ] **O ciclo de vida do `RESOLVIDO por` e a catraca do backlog não cabem juntos** —
  `TODO.md:16` — o cabeçalho manda o item fechado ficar aqui, caixa desmarcada, até o PR mergear;
  `tests/check-todo.sh` conta `- [ ]` e não conhece `RESOLVIDO por`, então `todo-findings` não pode
  descer na missão que consertou. As duas últimas apagaram na hora (`6136d39`) e a convenção ficou
  descrevendo outra prática. Direção: o sensor pular o corpo marcado, ou o cabeçalho adotar o
  apagar-na-hora. — descoberto por `sdd-executor` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **`sdd kaizen` recusa rodar de um worktree do próprio kit** — `bin/sdd:2963` — a porta
  "estou no repo do kit?" compara `kit_root` (`--show-toplevel` de `$SDD_HOME`) com `$REPO_ROOT`,
  e o toplevel é por worktree: de um worktree do kit os dois divergem e o comando morre em
  "run it in the kit repo". Mesma classe que `c514e36` acabou de fechar no ledger, em outra
  porta — e o kit recomenda worktree para isolar missão. Direção: `ledger_repo_root` dos dois
  lados, com par diferencial. — descoberto por `sdd-executor` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **`E2E_DIR` tem default no runner e é lida só pelo agente** — `bin/sdd:99` vs
  `agents/sdd-qa.md:45` — `: "${E2E_DIR:=e2e}"` era a única ocorrência no runner: nenhum gate ou
  prompt a consultava, e quem usava o valor era a prosa do `sdd-qa`. Mudar a chave **não mudava
  onde as specs são commitadas**, e a coincidência entre default e convenção escondia isso.
  **RESOLVIDO por `a2d1840`**: entra na linha 5 do prompt de boot com a guarda do `E2E_CMD`, e a
  linha sai da `tests/health-baseline.txt`. — descoberto por `sdd health` na missão
  `20260814-i13.2-mutacao-health` (2026-08-14)

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

- [ ] **`templates/` é single-language** — `templates/*.md` — são conteúdo em `OUTPUT_LANG` mas
  moram no kit em cópia única PT-BR, e o `sdd install` nem os copia (o `sdd-planner` lê direto de
  `$SDD_HOME`). Um alvo com `OUTPUT_LANG="en"` recebe prompt certo e template em português. Não
  morde hoje porque todo alvo é PT-BR. Direção: `templates/<lang>/` com fallback, ou estrutura
  inglesa com prosa-guia que o agente reescreve — a segunda mexe no contrato que
  `check-templates.sh` mede, então vem depois da entrada acima. — descoberto por `humano` na
  missão `20260815-i13.5-kit-em-ingles` (2026-08-15)

- [ ] **A regra `cdpath:` certifica como limpo o `cd` de operando VARIÁVEL** —
  `tests/check-pipefail.sh:231` (o comentário do `CD_RE` declara o limite) — a regra só mede
  operando que é substituição de comando, porque `cd "$FIX"` é indecidível no scanner e os ~150
  sítios de `tests/` têm variável absoluta. Só que a única instância histórica da classe era
  exatamente essa forma (`cd "$common"` do `ledger_repo_root`, uma CRITICAL), então a forma que
  mais custou é a que o sensor não vê. Direção: medir em runtime, não por linha.
  — descoberto por `sdd-executor` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **A regra 3 nomeia o comando errado quando a linha tem DOIS greps** —
  `tests/check-pipefail.sh` (o comentário de `maxc_violations` declara o limite) — linha que
  carrega quiet **e** `-m<N>` é reportada só pela regra 1, de propósito: mesmo defeito, mesmo
  conserto, uma mensagem. Só que em `foo | grep -q a | grep -m1 b` os dois flags são de comandos
  diferentes, e o leitor recebe a mensagem da regra 1 apontando para o `-m` do outro. Nenhuma
  instância no kit hoje. Direção: casar por comando, o que pede parser de shell.
  — descoberto por `sdd-executor` na missão `20260818-lote-facil` (2026-08-18)

### Saída humana e cosmética

- [ ] **43% do `docs/pipeline.md` é um subsistema só, e ele cresce toda missão do ledger** —
  `docs/pipeline.md:326-570` — as seções "The autonomy ledger" (149 linhas) e "The kaizen loop" (96)
  somam **245 de 570** num arquivo que é o índice do pipeline; esta missão engordou as duas. Índice
  que carrega profundidade é o doc que a próxima sessão não lê inteiro. Direção: `references/` para
  o ledger + juiz, com o índice roteando — **não** executar no meio de outra missão, é refator de
  estrutura e merece a sua. — descoberto por `sdd-docs` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **A contabilidade do `sdd autonomy` não fecha na tela: o cabeçalho conta o escopo, o
  parágrafo mistura duas populações** — `bin/sdd:2568` — `total` conta só as linhas locais, e as
  quatro linhas de exclusão somam a ele duas que **já estavam fora** (`foreign`, `norepo`). Medido
  no repo real: cabeçalho `75 row(s)` sobre arquivo de 86 linhas, `11 excluded: born in another
  repo`, tabela somando 73 sessões — 75 − 2 − 11 ≠ 73. Direção: **decisão humana** entre o cabeçalho
  contar o arquivo (quebra as 7 asserções `assert_bucket_sum`) ou as duas linhas fora de escopo
  saírem do parágrafo. — descoberto por `sdd-qa` na missão `20260818-lote-facil` (2026-08-18)

### Comentário e registro

- [ ] **22 das 33 âncoras do `TODO.md` apontam para a linha errada** —
  `tests/check-todo.sh:1` — auditadas uma a uma contra o HEAD: várias erram por centenas de
  linhas e uma cai fora do arquivo (`tests/run-all.sh:180`, num arquivo de 173). O sensor mede
  **forma**, nunca se a âncora ainda acerta o alvo, então o número não se move sozinho — e esta
  missão empurrou parte delas ao crescer o `bin/sdd` em 162 linhas. Direção: re-derivar em lote.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `check-health.sh` diz "the four silent aborts" e o catálogo tem cinco** —
  `tests/check-health.sh:31` — o `mut_HEALTH_ratchet_eats_verdict` não tem asserção própria: ele
  morre no fixture da asserção 11, que produz o outro defeito por tabela. Os dois mutantes são
  pegos, então não é fail-open — é o cabeçalho subcontando, e é ele que um leitor usa para mapear
  mutação em asserção. Direção: dizer os cinco e por que dois dividem um fixture.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `rows=13` do `gate:` da QA não sai do extrator do `gate_REVIEW`** —
  `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` — o awk literal do gate responde `rows=8`
  sobre `templates/review.md`; 13 é a contagem sem o filtro de cabeçalho e separador. A conclusão
  da J6 está certa e foi refeita nesta rodada (`##` devolve `NO-TABLE`), mas o número citado como
  evidência não reproduz. Direção: recontar com o extrator, ou dizer qual variante foi usada.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `README.md` diz "the 6 agents" e existem 7** — `README.md:111` — o `sdd-kaizen` não
  aparece nem no rótulo nem na tabela de `agents/`, embora o `sdd preflight` conte `7 kit
  agent(s) checked`. Pré-existente (nasceu com o agente, fora do diff desta missão). Direção:
  derivar o número de `ls agents/*.md` em vez de escrevê-lo à mão.
  — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

- [ ] **O `CLAUDE.md` chama de "quatro" os sensores fora do alcance da mutação e agora são cinco**
  — `CLAUDE.md:163` — o `check-templates.sh` mede `templates/`, o catálogo sabota o `bin/sdd`, e
  ele não tem `selftest()` — a rubrica da casa exigiria um. A exceção está declarada no cabeçalho
  do próprio sensor e em nenhum lugar da regra. Direção: admitir a quinta com o porquê, ou dar-lhe
  o auto-teste. — descoberto por `sdd-reviewer` na missão `20260818-lote-facil` (2026-08-18)

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

- [ ] **O memo do `run_check_cmd` marca ZERO acertos num `sdd run` inteiro: substituição de comando
  é subshell** — `bin/sdd:310` — todo leitor pega a fase como `"$(current_phase)"`, e o `_CHECK_RC`
  escrito lá dentro morre com o fork. Medido em ordem no fixture: 4 chamadas, 4 execuções, 2
  invalidações — e as duas primeiras caem na MESMA época, ou seja uma suíte inteira rodada à toa por
  volta (~60 s aqui, `vitest run` no alvo). O `sdd status` chama os gates direto e acerta (3
  chamadas, 2 hits, 1 execução), então o comentário de `bin/sdd:303` está certo sobre ele e calado
  sobre o `run`. Direção: publicar num global, como `run_phase` faz com `LAST_PHASE_*`.
  — descoberto por `sdd-executor` na missão `m1-20260824` (2026-08-24)

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
