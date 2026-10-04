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

- [ ] **Check com `test -f` passa num arquivo que o `.gitignore` do alvo ignora** —
  `tests/check-checkpoint.sh:194` (`scan_file`) — o I10 da S8 do `ui24_agent` mandava `test -f` num
  `docs/qa/reports/…-review.md`, e o alvo ignora `*-review.md`: o Check daria verde com um artefato
  que nunca chega ao git (só o `git add` pegou: `paths are ignored … .gitignore:20`). O incremento
  fecharia `done` e o clone novo reprovaria. Direção: o sensor roda `git check-ignore -q` em cada path
  do repo citado num Check e reprova o ignorado; o `sdd-planner` confere ao nomear o artefato.
  — descoberto por `sessão interativa` na missão `20261003-fase8-s8-dinamica-eq-restantes` (2026-10-03)

- [ ] **O Red do `R<n>` prova o achado, não o conserto: nenhum passo sabota a linha nova** —
  `agents/sdd-executor.md:76` (`Watch it fail`) — o conserto tira o sintoma e pode abrir um fail-open
  ao lado com o probe verde. Medido só no laço interativo (PR #45, #46; `coderabbit-pr` 2.4.0 já
  sabota); no headless, nunca. Direção: medir antes. O `40-review-r*.md` não grava o commit que
  gerou o achado, então um achado da rodada N+1 só conta se o `git blame` da âncora dele cair num
  commit `R<n>` da N; se houver caso, o executor sabota o conserto antes do commit.
  — descoberto pela sessão interativa ao avaliar o `/insights`, sem missão (2026-10-01)

- [ ] **A regra da âncora aceita qualquer símbolo citado que reapareça perto, e uma âncora podre passa** —
  `tests/check-todo.sh:2081` (`ANCHOR_REACH`) — um span de 4+ letras citado no item a até 10 linhas
  basta; identificador que se repete no arquivo inteiro casa em qualquer lugar. Medido em `b3b6b98`:
  `tests/check-autonomy.sh:6486` apontava para `exit 0` e passou verde porque `GIT_REFLOG_ACTION`
  está em 6400 — o sensor disse `every anchor on target`. Direção: exigir o símbolo na própria linha
  (ou no bloco da função), ou contar ocorrências e recusar símbolo que aparece em todo canto.
  — descoberto por `revisor de tarefa` na missão `20261001-a-janela-nao-se-parte` (2026-10-01)

- [ ] **Mundo de sensor reescrito pode perder o mutante que matava, e só o catálogo de 30 min vê** —
  `tests/check-mutation.sh:5940` (`KILLERS_FILE`) — o I4 de `20261001-a-janela-nao-se-parte` fez o
  mundo 8 restaurar o arquivo antes do gate; o `--anchors` ficou verde e duas revisões aprovaram, e
  só o `sdd health` (531 de 532) achou `HEALTH_stamp_window_blind` vivo. O mapa de assassinos já sabe
  qual sensor matou cada mutante. Direção: um modo barato que roda, isolados, os mutantes cujo
  assassino é um sensor tocado pelo diff, para o EXEC rodar antes do commit.
  — descoberto por `sdd health` na missão `20261001-a-janela-nao-se-parte` (2026-10-01)

- [ ] **Citação NÃO-cercada acima do cabeçalho ainda vira o gênero do bug** — `bin/sdd:1453` — o
  extrator da Âncora 3 pula blocos cercados e pega a primeira linha com forma de campo fora de um,
  então prosa nua abrindo com `- **Closable by:** human` acima do campo real ainda é lida como o
  campo. É fail-open (o gate responde `registry clean` com bug sanável aberto), na direção que a
  decisão 3 do grill recusa. Alcance baixo: exige arquivo que viole a ordem do template. Declarado
  no comentário do `bin/sdd`; entra aqui porque fail-open declarado continua entrando (régua D15).
  Direção: ancorar o gênero no MESMO bloco contíguo de `- **…:**` que traz a linha `Status:`.
  — descoberto por `sdd-reviewer` na missão `20260826-o-laco-da-qa` (2026-08-26)

- [ ] **O carimbo de mutação cobre 4 dos 8 caminhos que a sandbox do catálogo copia** —
  `bin/sdd:2041` contra `tests/check-mutation.sh:5845` — a chave lê `bin tests templates config`,
  mas `sandbox()` também copia `agents/`, `CLAUDE.md`, `TODO.md` e `docs/adr`. Mudança confinada a
  esses quatro mantém o carimbo válido sobre conteúdo que o catálogo de fato mede — a
  regra 12 do `check-health.sh` lê o `CLAUDE.md`. Estreitamento deliberado (a fase DOCS edita
  `CLAUDE.md`, e chavear nele custaria uma segunda rodada de ~20 min por missão). Direção: ler a
  lista do próprio `sandbox()`, decidido o custo. — descoberto por `sdd-executor` na missão
  `20260819-fecho-...` (2026-08-19)

- [ ] **O fixture de `stream-json` não tem checagem de proveniência** — `tests/check-autonomy.sh:135`
  — as três linhas replayadas pelos stubs foram copiadas de sessão real (CLI 2.1.233) e o comentário
  registra o comando, mas `health_provenance` (`bin/sdd:6376`) só confere as 3 fixtures de skill
  contra arquivo instalado. Se o CLI renomear `type`/`total_cost_usd`, o stub segue verde e o
  runner quebra só em missão real — o modo de falha que a regra de proveniência existe para matar.
  Direção: probe que rode o CLI de verdade, ou capturar o schema num arquivo versionado.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **`.sdd/logs/` não tem poda e agora guarda o stream inteiro** — `bin/sdd:816` — desde o I10
  cada sessão deixa três arquivos, e o `.stream.jsonl` é a sessão toda (a de teste, trivial, deu
  ~40 KB; uma fase real de 10 min é ordens de grandeza maior). Nada apaga nada: o diretório cresce
  por missão para sempre, e é justamente o que o humano vai querer abrir. Não é urgente — é
  gitignored e local. Direção: reter as N sessões mais recentes por missão, ou comprimir o stream
  ao fim da fase. — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O gate PLAN-AUTO aceita Check que já nasce verde** — `templates/missao.md:45` — o critério
  `d` cobra `Check executável (comando → esperado)`, não "Check que
  reprova o HEAD de hoje". Medido: o Check do I1 desta missão era `grep -c 'gate_DOCS reprova'
  TODO.md` → `0`, mas o título no `TODO.md` traz crases (`` `gate_DOCS` reprova ``), então o
  comando já devolvia `0` **antes** da remoção — verde por construção, exatamente o que a casa
  proíbe em teste. Direção: o planner roda cada Check contra o HEAD e registra o vermelho.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **O formato de achado vale para os repos-alvo, mas o sensor só guarda o arquivo do kit** —
  `tests/check-todo.sh` vs `CLAUDE.md` (princípio 5) — o esqueleto de duas seções e o ciclo
  "fechado é apagado" valem para o `TODO.md` de **qualquer** repo. Desde o marcador, o sensor roda
  num alvo (`--check <arquivo> --allow-empty`, e a skill `todo-to-github-issues` o chama antes de
  espelhar), mas nada o põe na suíte do alvo: o inchaço volta sem ninguém medir a cada missão.
  Direção: o `starter.conf` sugerir o `--check` do kit no `TEST_CMD` do alvo.
  — descoberto por `humano` revisando o sensor novo (2026-08-16)

- [ ] **O schema da série não tem sensor de drift contra a prosa que o descreve** — `bin/sdd:9554`
  (`kaizen_series`) vs `docs/pipeline.md:1374`, `docs/adr/0003:59`, `agents/sdd-kaizen.md:40` e
  `docs/failure-modes.md:102` — produzido em dois lugares (o `jq` e o literal vazio, `:9350`) e
  descrito em **dez**, QUATRO deles dentro do `bin/sdd`. Cobrado 6×: na DOCS de
  `20260817-eixo-do-juiz`, **oito** dos dez diziam a unidade que o F1 da r3 trocara horas antes
  (sessão → missão) — o ADR que o runner cita, a folha do juiz, e a própria frase que o runner
  IMPRIME. Direção: extrair os campos do `jq` e cobrá-los na doc.
  — descoberto por `sdd-executor` na missão `20260816-runner-sem-dividas` (2026-08-16)

- [ ] **Piso anti-vacuidade que fica para trás continua PASSANDO, e nada avisa** —
  `tests/check-lang.sh:180` — o piso dizia 37 caminhos contra 40 reais: as ADRs 0004–0006 entraram
  pelo glob `docs/adr/*.md` sem tocar o número, e piso menor que a superfície certifica menos do
  que lê. Corrigido para 41 no I4, mas a **classe** segue viva — todo piso que convive com um glob
  (`REVIEW_FLOOR`, `LINT_FLOOR`, os de `check-pipefail.sh`) falha igual, e é a segunda vez que este
  mesmo piso paga. Direção: derivar o piso, ou um sensor que compare piso × superfície real.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-01)

- [ ] **Nenhum instrumento mede prosa de CONTRATO fora de `templates/`** — `README.md:158` — o
  `refute()` do `tests/check-templates.sh` só lê `templates/`, e `README.md`/`docs/*.md` entram na
  `surface()` do `check-lang.sh`, que mede **idioma** e nada mais. Medido nesta missão: o I2 mudou
  o contrato do revisor em cinco lugares, o sexto sobreviveu à suíte verde e caiu numa jornada de
  QA; o sétimo (os diagramas de ordem canônica) sobreviveu à própria QA e só a DOCS o pegou.
  Direção: um `refute()` sobre a superfície de docs, ou ligar a tabela de agentes ao frontmatter.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-01)

- [ ] **A âncora `^  ok    ` do Check não alcança 82 das 866 asserções da suíte** —
  `tests/check-templates.sh:65` — as primitivas `check()`/`refute()` imprimem `ok` com **três**
  espaços enquanto `tests/check-checkpoint.sh:129` cobra quatro em todo repo adotante, e o
  `calibrate()` que existe para casar as duas pontas é cego a elas: lê só linhas com `pass() {`,
  logo enxerga 7 de 13 sensores e deixa 2 dos 8 comportamentais de fora prometendo "every
  behavioural sensor". Direção: unificar em quatro espaços **e** dar cobertura ao `calibrate()`.
  — descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **`gate_TICKET` não confere no Jira a issue que o chapéu diz que ele confirma** — `bin/sdd:1083`
  (`gate_TICKET`) — o `agents/sdd-ticket.md:18` promete que o runner confirma a issue por `acli`,
  mas o gate só lê `issue:` e `sprint:` do frontmatter do `10-ticket.md`. Uma issue duplicada (LH-5
  no lugar da LH-4) passa verde, e a LH-4 só se defendeu com um Check próprio no I1. Fail-open: o
  chapéu afirma uma medição que ninguém faz. Direção: o gate chama o `acli` (a issue existe e está
  no sprint ativo), ou o chapéu deixa de prometer.
  — descoberto por `sdd-planner` na missão `20260927-idioma-da-spa-pelo-idp` (2026-09-27)

- [ ] **Relatório trazido do histórico POSTERIOR da base conta como da missão** —
  `bin/sdd:875` (`path_in_commits`) — a posse exige caminho ausente da árvore do merge-base; um
  relatório que outra missão mergeou em `origin/<base>` DEPOIS do corte, trazido por `git checkout
  origin/<base> -- f`, `merge --squash` ou `cherry-pick`, é novo para o merge-base e conta: a SQ-146
  por outra porta. Checar a ponta da base recusaria o próprio relatório de missão mergeada por
  squash (o fluxo do `sales_quote`). Direção: distinguir pelo blob na ponta, não pelo caminho.
  — descoberto por `revisor de contexto novo` na missão `20260928-os-achados-da-janela` (2026-09-29)

- [ ] **Um `done` abaixo de um `blocked` passa, e o Check de fechamento pode medir só o rótulo** —
  `tests/check-checkpoint.sh:449` (`none blind`) — na S8 do `ui24_agent` o I12 (docs de fechamento)
  fechou `done` com o I11 (smoke ao vivo) `blocked`. O Check dele, `grep -c 'S8 ✅' CLAUDE.md`, cobra
  a palavra ✅ e não a prova do smoke, e o sensor respondeu `none blind`. Só não afirmou demais porque
  a sessão escreveu "smoke PENDENTE" na mesma linha. Direção: o sensor avisar `done` abaixo de
  `blocked`, e o `sdd-planner` fazer o Check de fechamento cobrar o artefato do smoke.
  — descoberto por `sessão interativa` na missão `20261003-fase8-s8-dinamica-eq-restantes` (2026-10-03)

- [ ] **O lint do `TODO.md` não separa violação nova da herdada: alvo com dívida fica sempre vermelho** —
  `tests/check-todo.sh:65` (`--allow-empty`) — o `TODO.md` do `ui24_agent` carrega 15 violações de
  forma herdadas, e quem o edita não sabe se acrescentou alguma. Na S8 a prova foi copiar a `HEAD`
  para a raiz do alvo e contar de novo (15 = 15); a cópia no scratchpad deu 21, porque a âncora
  resolve pela raiz do repo do arquivo. Direção: `--check <file> --baseline <ref>`, que reprove só o
  que a ref não tinha.
  — descoberto por `sessão interativa` na missão `20261003-fase8-s8-dinamica-eq-restantes` (2026-10-03)

### Contrato e configuração

- [ ] **Fase interrompida depois do REVIEW faz o pipeline REGREDIR para o REVIEW** —
  `bin/sdd:1808` (`git status --porcelain`) — o `gate_REVIEW` reprova com árvore suja e não distingue "o revisor deixou
  sujeira" de "uma fase POSTERIOR está no meio do voo". Sessão de DOCS morta deixa arquivo não
  commitado, `current_phase()` volta a responder REVIEW, e o `sdd run` seguinte abre sessão nova
  da fase mais cara do kit — US$ 37,30 medidos nesta missão. Morte de sessão é o caso normal que
  o princípio 4 promete resolver de graça. Direção: escopar a checagem ao que o REVIEW pode sujar.
  — descoberto por `operador` na missão `20260827-condicoes-pagamento-mesmo-cliente` (2026-08-27)

- [ ] **`sdd kaizen` recusa rodar de um worktree do próprio kit** — `bin/sdd:10272` — a porta
  "estou no repo do kit?" compara `kit_root` (`--show-toplevel` de `$SDD_HOME`) com `$REPO_ROOT`,
  e o toplevel é por worktree: com o `sdd` do checkout principal e o cwd num worktree os dois
  divergem e o `die` da `:10086` mata. ⚠️ **`--series` NÃO passa por ela** — sai na `:10073`, medido
  nas duas formas de invocação, saída idêntica. Direção: `ledger_repo_root` dos dois lados, com par
  diferencial. — descoberto por `sdd-executor` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **Nenhuma chave de caminho do `.sdd/config.sh` é normalizada antes de virar padrão de `case`**
  — `bin/sdd:2505` — `hat_expand` troca `$TODO_FILE` **literalmente** no `writes:` do chapéu, lido contra
  `git diff --name-only`; um repo-alvo com `TODO_FILE="./TODO.md"` — ou `HANDOFF_DIR="./docs/handoffs"`,
  que a normalização do `F4` também não pega — reproduz o defeito que o `F4` acabou de consertar,
  com raio menor. Direção: normalização **única** na leitura do config, com um probe por chave.
  — descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha` (2026-09-02)

- [ ] **Uma sessão escreve o ledger com o `bin/sdd` que tinha em MEMÓRIA ao ser lançada** —
  `bin/sdd:4261` — a missão que ACRESCENTA um campo é a única que não o registra (3 de 4 rodadas
  com `turns` nulo), e o ledger não distingue "medido nulo" de "não medido": fail-open de leitura.
  O `.sdd/config.sh` tem o mesmo defeito (`bin/sdd:147`, `source` único): o `TEST_CMD` consertado
  a meio do run não vale, e o EXEC da SQ-141 queimou 4 retries (~US$ 5,90) num gate insatisfazível.
  Direção: o `sdd run` avisar quando `bin/sdd` ou config mudou sob ele (ou reler o config por gate).
  — descoberto por `sdd-qa` na missão `20260901-o-revisor-so-acha` (2026-09-01); config por
  `claude` na missão `20260924-transacao-honra-o-timeout` (2026-09-24)

- [ ] **O checkpoint não tem grafia para incremento cujo produto não é commit** — `bin/sdd:1179`
  (`GATE_EXEC_CELL`) — o `gate_EXEC` exige 7 a 64 dígitos hex na célula Commit, e o
  `templates/checkpoint.md` não diz o que escrever quando o incremento é e-mail enviado, config no
  IdP ou issue adotada. Na LH-3 o I5 foi o e-mail aos diretores, e o `sdd status` da missão aponta
  EXEC para sempre. Direção: uma grafia do kit para evidência fora do git que o gate aceite com o
  Check verde, ou a regra de que todo incremento deixa um commit de registro.
  — descoberto por `sessão coordenadora` na missão `20260922-email-mvp-diretores` (2026-09-27)

- [ ] **Incremento que espera uma janela externa só tem `blocked`, e o `blocked` para a missão inteira** —
  `bin/sdd:1320` (`GATE_WHY`) — no I11 da S8 do `ui24_agent`, um smoke ao vivo que exige a mesa sem
  uso, a pré-condição falhou (master a −2,9 dBFS) e o humano mandou fazer o I12 (docs e PR) antes. O
  `sdd status` respondeu `Jidoka: the line stops`, o template põe o smoke antes do fechamento, e a
  inversão foi improviso (`blocked`, `intervention:`, PR em rascunho). Irmão do item acima, com outra
  causa. Direção: um status "espera evento externo", com motivo, que não pare as fases seguintes.
  — descoberto por `sessão interativa` na missão `20261003-fase8-s8-dinamica-eq-restantes` (2026-10-03)

- [ ] **O checkpoint semeado no alvo cita um sensor que só existe no kit** —
  `templates/checkpoint.md:33` (`tests/check-checkpoint.sh`) — o texto diz que ele recusa as formas
  cegas "nos checkpoints deste repo", mas no alvo o caminho relativo não existe: no `ui24_agent`,
  `bash tests/check-checkpoint.sh` deu `No such file or directory`. Quem segue o banner para ali ou
  crê validada uma tabela que guarda nenhum leu. O modo certo já existe e serve: `--check` pelo
  caminho do kit deu `rc=0` no checkpoint da S8. Direção: o template citá-lo assim, como o
  `templates/todo.pt-BR.md` já faz ("do kit"). Parente do item do formato de achado nos alvos.
  — descoberto por `retrofit-watch` na missão `20261003-fase8-s8-dinamica-eq-restantes` (2026-10-03)

### Saída humana e cosmética

- [ ] **35% do `docs/pipeline.md` é um subsistema só, e ele cresce toda missão do ledger** —
  `docs/pipeline.md:1022` — as seções `The autonomy ledger` (323 linhas) e `The kaizen loop` (174)
  somam **497 de 1419** (eram 245 de 570 em 2026-08-17) num arquivo que é o índice do pipeline.
  Índice que carrega profundidade é o doc que a próxima sessão não lê inteiro. Direção: `references/` para
  o ledger + juiz, com o índice roteando — **não** executar no meio de outra missão, é refator de
  estrutura e merece a sua. — descoberto por `sdd-docs` na missão `20260817-eixo-do-juiz` (2026-08-17)

- [ ] **As ADRs 0001–0007 não têm `Spec:`, e por isso 14 missões deste repo não podem declarar
  `adr:`** — `docs/adr/0001-judge-split-deterministic-series-model-verdict.md:1` — nenhuma das sete
  liga-se a uma missão por artefato (`git log --diff-filter=A` de cada uma não toca
  `docs/handoffs/`), então o par das duas direções não fecha e `adr: none` seria rótulo sem
  artefato. É o que segura este repo em `ADR_CHECK=warn`: o `sdd adr check` conta 14 sem decisão, e
  `block` mandaria as 14 de volta para PLAN. Direção: o humano mapeia as sete, `sdd adr new --spec`
  escreve os dois lados, o resto vira `adr: none`, e aí a chave volta para `block`. — descoberto
  por `codereview` na missão `20260917-o-numero-do-adr-nao-e-prosa` (2026-09-17)

- [ ] **O `kaizen --series` morre com o erro cru do `jq` e contradiz o pipeline.md sobre linha não-objeto** —
  `bin/sdd:9554` (`kaizen_series`) — irmão da #206 no segundo leitor: uma linha objeto com
  `"cost_usd":"4.0"` sai com rc 5 e `jq: error (at <stdin>:2)`, sem nomear o arquivo nem passar pelo
  `die`; uma linha array sai rc 0, contada em `excluded.unrecognized`, e o `docs/pipeline.md:1062`
  diz que ela "still dies loudly naming the file". Direção: o mesmo par de recusas do `cmd_autonomy`
  (forma primeiro, stderr do `jq` no `die`), ou a doc dizer o que a série faz.
  — descoberto pela triagem cética do lote 2 no branch `fix/lote-2-sensores` (2026-10-03)

### Comentário e registro

- [ ] **Drift de comentário em código não tem dono: nem a DOCS nem a EXEC** — `agents/sdd-docs.md:9`
  — comentário de código É documentação viva, mas o `writes:` da DOCS não lista `bin/sdd` e o
  `hat_guard_check` para a linha quando ela o conserta. `HAT_WRITES_EXTRA` não é a saída: declarar
  `bin/sdd` para a DOCS entrega o runner inteiro a quem não edita código, e a fronteira existe para
  isso. Direção: a REVIEW endereça o achado à EXEC, ou a DOCS ganha um caminho estreito.
  — descoberto por `sdd-docs` na missão `20260911-o-juiz-nao-mente-sobre-a-janela` (2026-09-12)

### Idioma

- [ ] **`surface()` do `check-lang.sh` ENUMERA arquivos em vez de casar `docs/*.md`** —
  `tests/check-lang.sh:52` — um doc novo em `docs/` nasce **fora** da régua de idioma enquanto o
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

- [ ] **O carimbo da fase PR é medido antes da revisão dos bots, e o primeiro achado de código o descarta** —
  `agents/sdd-publisher.md:42` (`./bin/sdd health`) — o `CLAUDE.md` manda esperar os revisores,
  consertar numa leva e carimbar uma vez; a fase PR carimba logo depois de abrir o PR. Medido no #196:
  health às 18:13, CodeRabbit às 18:27 com um achado em `bin/sdd`, run interrompido com 123 de 542
  mutantes. A direção do item acima (o runner carimbar antes da sessão de PR) agrava isto. Direção, à
  luz do ADR 0004: abrir o PR, esperar a rodada dos bots e só então carimbar.
  — descoberto pela sessão interativa que monitorava `20261002-onde-o-comando-do-humano-escreve` (2026-10-02)

### Sem seção — chegaram depois da última classificação

> ⚠️ Esta seção **chamava-se "Adiados por YAGNI"** e não guarda mais nenhum adiamento: os três que
> havia (espelho global de vereditos, multi-missão por `git worktree`, `sdd digest`) viraram Y1–Y3
> da tabela **Decisões adiadas por YAGNI** do [`CONTEXT.md`](CONTEXT.md), onde cada um nomeia o
> evento que o reabre — pela régua D15, ausência de consumidor é decisão adiada, não achado. Os
> itens abaixo são achados de verdade que foram apendados ao fim do arquivo e nunca classificados;
> quem mexer num deles o move para a seção a que ele pertence.

- [ ] **Fase executada à mão não tem como ser registrada, e o ledger afirma que ela não aconteceu** —
  `agents/sdd-publisher.md:1` — a fase PR da SQ-129 foi montada à mão depois de três mortes por
  memória; não há sessão de publisher no ledger e o custo não entra na soma (US$ 161,29 é o total
  que o journal conhece, e ele para na DOCS). A lacuna virou prosa no `50-pr.md`, que nem o
  `sdd autonomy` nem o `sdd kaizen` leem. Direção: `sdd note-manual <fase>`, irmão do `intervention:`
  — ⚠️ pede o **sexto** `event` do ledger, com dois leitores a ensinar no mesmo commit.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)

- [ ] **`Test Coverage` = A do revisor não implica que os casos negativos existam** —
  `agents/sdd-reviewer.md:178` — um P1 real passou por **três** rodadas de `sdd-reviewer` (a última
  com essa nota) e quatro checks de CI verdes; o caso que faltava era o negativo, e nenhum sensor
  era obrigado a cair. O `@codex review` o achou no PR #167. Direção: o revisor enumera qual
  sabotagem provou cada nota — hoje narra em prosa, e prosa não é verificável.
  — descoberto por `sessão coordenadora` na missão `20260916-destino-frete-cif` (2026-09-16)

- [ ] **O mapa de assassinos reordena a suíte e confia que nenhum sensor muda de resposta por rodar primeiro** —
  `tests/run-all.sh:386` — sob `SDD_MUTANT_FIRST` o CONJUNTO de passos de um mutante é o mesmo (as probes
  `surface:` do `check-health.sh` o provam), mas a ORDEM muda, e um passo que ficasse vermelho só por rodar
  primeiro faria um sobrevivente ler como pego: fail-open. Medido 13 de 13 verde em 2026-09-25 (kit sem
  sabotagem, cada passo nomeado primeiro), sem sensor que o repita. Direção: o controle do catálogo roda
  também uma vez por assassino distinto do mapa, com ele na frente, e exige verde.
  — descoberto por `revisão final` no PR #168 `perf/catalogo-assassino-primeiro` (2026-09-25)

## Decidido — não reabrir
<!-- sdd:decided -->
- **O laço de melhoria da sessão interativa não enxergaria o kit** — resolvido fora do kit, sem commit deste repo: `retrofit-watch` 0.2.0 (`j0ruge/skills@960e47b`) reconhece `/sdd-*`, subagente `sdd-*` e o CLI `sdd` (2026-10-01)
- **O `sdd preflight` não provaria que a sessão headless executa comando** — refutado: `bin/sdd:5168` manda rodar `bash -c 'echo sdd-preflight-ok'` sob as flags do `run_phase` desde `2083680`, e sob o chapéu do executor desde 2026-09-06 (2026-09-25)
- **O `RESOLVED by` não deixa a catraca descer na missão que conserta** — decidido: o item fica até o merge e sai no chore pós-merge, `templates/todo.pt-BR.md` § Ciclo de vida (2026-09-25)
- **O stub do `sdd adr new` manda escrever em `OUTPUT_LANG`, e o `check-lang.sh` lê `docs/adr/` como inglês** — limite declarado pela D15, não achado: `bin/sdd:7030` (2026-09-25)
- **Aviso de merge durante a janela do juiz** — decidido fora: depois do conserto do eixo (I2) só mudança real do kit rompe a janela, e essa é ruptura legítima — `docs/adr/0014`, missão `20261001-a-janela-nao-se-parte` (2026-10-01)
- **A refutação R2 do handoff de QA citaria evidência que não existe** — refutado: o prompt renderizado nomeava o arquivo, porque o boot_prompt expande `$TODO_FILE` para TODO.md; o item conferiu a fonte, não o prompt — `148f693:bin/sdd:1621` (2026-10-03)
- **O sdd status travaria mais de 2 min segurando a trava do checkout** — refutado: sem `--no-gates` o status avalia todo gate sob a trava, TEST_CMD e E2E_CMD incluídos, e a trava é não-bloqueante, então quem chega depois recebe CHECKOUT-BUSY com o dono; a leitura sem trava é `sdd status --no-gates` — `bin/sdd-coordination.py:504` (2026-10-03)
- **O cmd_kaizen escalaria no-progress como fricção no rubric depois de um retry que moveu** — decidido: o código escala sem olhar o moved2, mas as linhas KAIZEN são `$meta` e ficam fora do eixo do juiz nos dois leitores; o humano lê "two sessions without satisfying the gate", que é verdade — `bin/sdd:9943` (2026-10-03)
- **A Âncora 3 do gate_QA bloquearia a missão com bug aberto de OUTRA missão** — decidido por desenho: a ADR 0009 mantém recusada a alternativa (A) da 0006, porque contar só o bug da missão troca o laço por dívida calada; a saída humana é `deferred` — `docs/adr/0009-the-genre-gains-deferred-and-hats-gain-project-exceptions.md` (2026-10-03)
- **Slug de missão em pt-BR não poderia ser citado na superfície inglesa** — decidido: o selftest do check-lang afirma de propósito que slug em prosa é pego (exit 95); slug se cita numa linha `Spec:`/`ADR:` ou sem stopword — `tests/check-lang.sh:130` (2026-10-03)
- **As skills qa-report e qa-execution não conhecem o campo Closable by** — decidido: o lado do kit fechou (o sdd install semeia o campo, o sdd preflight reprova sem ele, o sdd-qa marca); ensinar a skill de terceiro é retrofit no marketplace, não item do kit — `f7bcf10` (2026-10-03)
- **O rows=13 do gate: da QA de 20260818-lote-facil não sai do extrator** — decidido: o número citado não reproduz (o extrator dá 8, o próprio item o mediu) e a conclusão da J6 segue certa; handoff de fase encerrada não se reescreve — `docs/handoffs/20260818-lote-facil/30-handoff-qa.md:7` (2026-10-03)
- **Nada mediria se o esperado de um Check do checkpoint ainda reproduz** — limite declarado: o cabeçalho do sensor diz que ele não mede o valor ao lado da seta, de propósito; rodar os Checks custaria a suíte por célula — `tests/check-checkpoint.sh:45` (2026-10-03)
- **O kit não tem CHANGELOG.md, e a fase DOCS cobraria um** — decidido: a linha do CHANGELOG na DOCS é condicional (só quando a missão entrega algo visível) e nenhum gate a cobra; o registro do kit é KAIZEN_LOG.md, handoffs, git log e corpo do PR — `agents/sdd-docs.md:49` (2026-10-03)
- **O teto de orçamento não conhece "missão reaberta"** — decidido: a porta humana para gastar mais é `--budget-override` com a nota intervention: que o runner escreve (anatomia §7) — `bin/sdd:5031` (2026-10-03)
- **O gate: do frontmatter da revisão só é cobrado quando existe** — decidido, sem conserto: as 6 rodadas sem o campo (de 30) são de 2026-08-16/17, anteriores a ele, e as 24 seguintes o trazem — `bin/sdd:1773` (2026-10-03)
- **run_phase cria o diretório de log da sessão sem guarda** — decidido, sem conserto: a falha é alta e fechada (rc 1 antes de abrir sessão, zero gasto) e nunca foi observada — `bin/sdd:4670` (2026-10-03)
- **Check de ausência reprovaria o conserto que precisa citar o defeito** — decidido: falha fechada, um caso em 2026-08-16; a regra de redação de Check do planner vem com o achado do Check que nasce verde, na leva 4 — `docs/handoffs/20260816-runner-sem-dividas/checkpoint.md:20` (2026-10-03)
- **A suíte segue acima do alvo "<30 s" da D7** — decidido: o critério (4) da D7 passa a ser o prazo por passo do step_timeout (8× o tempo ocioso, piso 60 s), que já é o orçamento medido e cobrado; o 🚩 do CONTEXT.md fecha — `tests/run-all.sh:168` (2026-10-03)
- **O 2º Python do worker custa ~30 ms em toda chamada coordenada** — decidido: 30 ms por chamada não chega ao humano; provar o worker por FD herdado pede ADR e fica na gaveta, F1 P1 — `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md:63` (2026-10-03)
