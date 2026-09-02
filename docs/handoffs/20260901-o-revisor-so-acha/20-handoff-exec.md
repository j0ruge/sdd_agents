---
missao: 20260901-o-revisor-so-acha
fase: EXEC
status: done
sessao: 4f9b8b16-dc64-41d4-a9bc-df5b66469fa1
data: 2026-09-02 06:40
gate: "tests/run-all.sh → 866 asserções `ok`, última linha `suite green`, rc 0 (era 842 em `35863d9`, 855 ao fim dos I1–I4, 858 ao fim do ciclo QA 1, 861 ao fim da rodada r1, 864 ao fim da r2); checkpoint sem linha `pending|doing` — I1 `88432ee`, I2 `03187e8`, I3 `c8c8ec7`, I4 `a84adeb`, o ciclo QA 1 `384e36c` (F1), `48097cd` (F2), `c05b43b` (F3), `b1cfc27` (F4), a rodada REVIEW r1 `d06840a` (R1), `045d8dd` (R2), `24ee7bf` (R3), `bffc79f` (R4), `541b524` (R5), a rodada REVIEW r2 `348a80f` (R6), `8cdec98` (R7), `6ebed3a` (R8) e a rodada REVIEW r3 `604d280` (R9), `f8fcb49` (R10), todos ancestrais de HEAD (`git merge-base --is-ancestor` ok em 18 de 18); working tree limpa"
---

# Handoff — EXEC — O revisor só acha

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os quatro incrementos fecharam: o ledger carrega `turns` e imprime `review loop US$ X (N%)` por
missão (I1), o contrato mudou em cinco lugares no mesmo commit — o `sdd-reviewer` **só acha** e o
achado vira incremento `R<n>` (I2), a guarda de aviso `REVIEW-EDITED-CODE` registra a rodada que
voltou a consertar (I3), e a documentação + o "antes" do `KAIZEN_LOG` estão em disco (I4). Suíte
855 asserções verde; catálogo de mutação 218 → 222 mutantes, mas o **carimbo está morto** — quem
re-emite é a fase DOCS, depois do último commit de código. A fase REVIEW desta missão é o
**primeiro teste real** do desenho novo, e é dela que sai a coluna "Depois" do `KAIZEN_LOG`.

**Ciclo QA 1 (atualização de 2026-09-02):** os quatro `F<n>` que a QA levantou também fecharam —
`384e36c`, `48097cd`, `c05b43b`, `b1cfc27`. Suíte **858**, catálogo **223**. Detalhe na seção
`## Ciclo QA 1` abaixo; o resto deste arquivo descreve os I1–I4 e continua válido.

**Rodada REVIEW r1 (atualização de 2026-09-02):** a primeira rodada do contrato novo **achou e não
consertou** — 12 achados, nota `B`, cinco linhas `R<n>` `pending` e zero conserto na sessão dela.
Os cinco fecharam em cinco sessões de contexto próprio: `d06840a`, `045d8dd`, `24ee7bf`, `bffc79f`,
`541b524`. Suíte **861**, catálogo **224**. Detalhe na seção `## Rodada REVIEW r1` abaixo. O laço
que esta missão existe para criar **rodou de ponta a ponta pela primeira vez**, e o que ele produziu
é a evidência da M2/M3 — a próxima rodada (r2) re-avalia sem ter escrito nenhum destes consertos.

**Rodada REVIEW r2 (atualização de 2026-09-02):** a r2 re-julgou os cinco consertos que **não**
escreveu (5 de 5 passam, dois reproduzidos nos dois sentidos), achou **8** novos e não fechou — 1
HIGH, 3 MEDIUM, 4 LOW, nota `B`, três linhas `R<n>`. As três fecharam: `348a80f` (R6), `8cdec98`
(R7), `6ebed3a` (R8). Suíte **864**, catálogo **225**. Detalhe na seção `## Rodada REVIEW r2`
abaixo. Duas rodadas seguidas acharam sem consertar, e a segunda achou um fail-open **no próprio
sensor** que a primeira tinha usado como atalho de conferência.

**Rodada REVIEW r3 (atualização de 2026-09-02):** a r3 re-julgou os três consertos que **não**
escreveu (3 de 3 passam, e o mutante do `R8` foi aplicado numa cópia para matar exatamente uma
asserção, a nomeada), achou **3** novos e não fechou — 2 MEDIUM, 1 LOW, nota `B`, duas linhas
`R<n>`. As duas fecharam: `604d280` (R9), `f8fcb49` (R10). Suíte **866**, catálogo **227**. Detalhe
na seção `## Rodada REVIEW r3` abaixo. ⚠️ **Aqui a série muda de assunto:** os três achados da r3
**nasceram do ciclo de conserto da r2**, a curva é `12 → 8 → 3` sem HIGH pela primeira vez, e o
teto de rodadas foi alcançado — a próxima coisa que o runner faz é encerrar em `BLOCKED` com a
`ceiling_note`, o que é Jidoka e não gate insatisfazível. As três portas do humano estão no
`§ Boot da próxima fase`.

## Estado do repo

> ⚠️ Atualizado em 2026-09-02, no fim da **rodada REVIEW r3**. Os números abaixo são os de agora;
> os do fim dos I1–I4 (9 commits, `a84adeb`, 855 asserções), os do fim do ciclo QA 1 (19 commits,
> `b1cfc27`, 858), os do fim da r1 (31 commits, `541b524`, 861) e os do fim da r2 (38 commits,
> `6ebed3a`, 864) estão no `git log` e nos `gate:` anteriores deste arquivo, recuperáveis por
> `git log -p` neste caminho.

- **Branch:** `feat/o-revisor-so-acha` — 43 commits à frente de `main` (`35863d9`); **não** há push
  nesta fase.
- **Último commit de código:** `f8fcb49` `docs(runner): o censo de pipeline_log_line vira comando, e a frase passa a falar de todo chamador` — é **dele** que o carimbo de mutação depende.
- **Working tree:** limpo (só falta o commit de checkpoint desta sessão, que acompanha este arquivo).
- **Suíte:** `tests/run-all.sh` → **verde**, 866 asserções `ok`, rc 0 (~85 s).
- **E2E:** `E2E_CMD=""` — o kit não tem interface; não rodou por não existir.

## O que foi feito

- `88432ee` — **I1, o instrumento.** `run_phase` publica `LAST_PHASE_TURNS` lendo `.num_turns` do
  mesmo JSON destilado de onde já lia o custo; `autonomy_session_row` ganha `turns` **lido do
  global** (sem argumento novo, sem tocar os quatro chamadores); escalada e `gate_pass` **não**
  carregam o campo. `cmd_autonomy --by-mission` ganha o sufixo `· review loop US$ X (N%)`, que
  soma as sessões `REVIEW` mais as sessões `EXEC` **posteriores** à primeira REVIEW da mesma
  `(repo, missão)`. Esquema aditivo, `v` continua `1`.
- `03187e8` — **I2, o contrato, em cinco lugares no mesmo commit.** `phase_task REVIEW` passa a
  dizer *"…every finding that must be fixed becomes an R<n> increment in the checkpoint — you do
  NOT fix the code"* e `phase_extra REVIEW` foi reescrito para o laço achar → `R<n>` → (EXEC
  conserta) → a rodada seguinte re-avalia; `agents/sdd-reviewer.md § 3` virou *"findings become
  increments"* com as regras de rigor **intactas**; `agents/sdd-executor.md` aprendeu a linha
  `R<n>`; `templates/review.md` ganhou `## Incrementos de conserto (R<n>)` e
  `templates/checkpoint.md` virou `## Incrementos de fix (QA e REVIEW)`; `docs/pipeline.md § REVIEW`
  descreve o laço. Espelhos `.claude/agents/` sincronizados por `./bin/sdd install --force`.
- `c8c8ec7` — **I3, a guarda.** `review_scope_check` compara o HEAD anterior (o primeiro campo do
  `state_fingerprint`) com o HEAD de agora; qualquer arquivo fora de `<HANDOFF_DIR>/<missão>/`,
  `TODO_FILE` e `tests/health-baseline.txt` gera `warn` + `REVIEW-EDITED-CODE` no `pipeline.log`.
  **Três portas** (`cmd_run` ×2 + `cmd_retry`), aviso e não fronteira.
- `a84adeb` — **I4, a documentação e o "antes".** `config/schema.md` (`BUDGET_REVIEW_USD` fica 40,
  com o porquê; `REVIEW_MAX_ITER` ganha a consequência das duas rodadas), `docs/failure-modes.md`
  (três formas e três diagnósticos quando a review não fecha em A), `CONTEXT.md` (o verbete
  conferido contra o que pousou), `KAIZEN_LOG.md` (entrada no topo, coluna Depois em aberto) e
  `tests/check-lang.sh` (`docs/graphify.md` entra na superfície; piso 37 → **41**).

## Ciclo QA 1 — os quatro `F<n>`, um commit cada

> Seção acrescentada em 2026-09-02, quando o último `F<n>` fechou. A fase QA
> (`30-handoff-qa.md`) caminhou 9 jornadas de terminal, confirmou 4 defeitos **reproduzindo cada um
> antes de virar linha**, e não consertou nenhum — é o mesmo desenho que o I2 acabou de dar à
> REVIEW, exercitado uma fase antes. Nenhum `BUG-<id>` foi aberto: o registry `docs/qa/bugs/` é das
> skills e não tem uma linha `Status: open`.

- `384e36c` — **F1, o template parava de contradizer o contrato que o I2 acabou de escrever.**
  `templates/review.md:19` mandava o TL;DR dizer "o que foi corrigido" e `:64-65` mandavam o achado
  que "virou correção" reaparecer com hash — apontando para uma seção cuja primeira frase é
  *"Esta rodada não conserta."* e que não tem coluna de hash. Era o mais urgente dos quatro porque
  a REVIEW **desta** missão é a primeira a ler esse arquivo. O conserto **não foi só de prosa**:
  `tests/check-templates.sh` ganhou `refute()`, o espelho de `check()` que passa quando a regex
  **não** casa — nenhuma asserção positiva enxerga prosa deixada para trás, e o sensor imprimia
  `template contract intact` sobre um arquivo que mandava fazer o contrário do contrato.
  `REVIEW_FLOOR` 24 → 26 no mesmo diff.
- `48097cd` — **F2, um fail-open medido nos dois sentidos.** A asserção do heading do checkpoint
  casava `'^## Incrementos de fix'`, que serve ao nome **antigo** tão bem quanto ao novo, enquanto
  o rótulo jurava pinar `Incrementos de fix (QA e REVIEW)`. Reproduzido: revertendo o heading do
  template para o antigo o sensor respondia `rc=0` — afirmava medir o que não media. A regex
  apertou; nenhuma asserção nova (857 antes e depois), então nenhum piso se moveu.
- `c05b43b` — **F3, o sexto lugar do contrato que o I2 mudou em cinco.** `README.md:152` ainda
  prometia que o `sdd-reviewer` entrega `+ fixes`. A célula do Check pina a **palavra** e não a
  promessa, o que mordeu no meio da sessão: a primeira redação (`never fixes`) dizia o contrato
  certo e deixava o Check vermelho. A linha passou a dizer `read-only over the code`, que é a
  frase do frontmatter do agente — a fonte, não uma paráfrase.
- `b1cfc27` — **F4, a allowlist da guarda normaliza `HANDOFF_DIR`.** A allowlist de
  `review_scope_check` casa um **glob** contra o que `git diff --name-only` imprime, e os dois
  lados vinham de mundos diferentes: o git já normalizou, mas a chave chega **verbatim** do
  `.sdd/config.sh` do repo-alvo. Com `HANDOFF_DIR="docs/handoffs/"` o padrão virava
  `docs/handoffs//<missão>/*`, que não casa nada, e a guarda gritava `REVIEW-EDITED-CODE` sobre o
  próprio `40-review-r<N>.md` em **toda rodada saudável** — o aviso que dispara quando nada está
  errado ensina seu único leitor a rolar por cima da vez em que algo está. Um **laço** e não
  `${HANDOFF_DIR%/}`, que tiraria uma barra só. Junto veio a segunda metade da linha: o braço
  `tests/health-baseline.txt` é **incondicional** embora o comentário o escope "in the kit's own
  repo" — declarado agora no cabeçalho da função **e** em `docs/pipeline.md`, porque condicioná-lo
  seria mudança de comportamento sem probe. Regime 5 novo em `check-autonomy.sh`, com o piso
  `slash:1` provado por sabotagem; mutante `mut_RUN_review_scope_handoff_dir_verbatim`; catálogo
  222 → 223.

**O que o ciclo custou e o que ele diz:** quatro sessões, quatro commits de conserto, e os quatro
defeitos são da **mesma família** — contrato mudado em N lugares e sobrevivendo em N+1. Três deles
(`F1`, `F3` e o achado do diagrama abaixo) só apareceram porque um agente caminhou o artefato à
mão; a suíte estava verde nos quatro casos. É o achado de instrumento mais forte desta missão e
está registrado abaixo.

## Rodada REVIEW r1 — os cinco `R<n>`, um commit cada

> Seção acrescentada em 2026-09-02, quando o último `R<n>` fechou. É a **primeira** rodada do
> desenho que esta missão escreveu: `40-review-r1.md` registra 12 achados (4 HIGH, 3 MEDIUM, 5 LOW),
> nota `B`, e a sessão da rodada **não editou código nenhum** — cinco achados viraram linha `R<n>`
> no checkpoint, quatro foram para os achados fora de escopo e três foram **refutados com
> evidência**. A r1 em `B` é a rodada saudável do desenho novo, não uma falha.

- `d06840a` — **R1, achado #1 (HIGH): a guarda acusava arquivo acentuado da própria missão.**
  `review_scope_check` casava a allowlist contra a saída de `git diff --name-only`, e o
  `core.quotePath` padrão do git devolve `"docs/handoffs/M/relat\303\263rio.md"` — entre aspas e em
  octal — para qualquer nome não-ASCII. Num repo de `OUTPUT_LANG=pt-BR` isso é o caso **normal**, e
  a rodada saudável levava `REVIEW-EDITED-CODE` sobre o próprio relatório. Conserto:
  `-c core.quotePath=false`. Regime 6 do bloco da guarda, com o veneno **armado** pela fixture
  (`git config core.quotePath true`) em vez de herdado do `~/.gitconfig` de quem roda. Mutante
  `RUN_review_scope_quotepath_default`; catálogo 223 → 224.
- `045d8dd` — **R2, achado #2 (HIGH): as regras `refute()` do `F1` eram cegas à maiúscula.**
  Reintroduzir `## O que foi corrigido` (O maiúsculo) **ao lado** da seção nova deixava o sensor em
  `rc=0` — o cenário que o comentário três linhas acima delas dizia temer. `-i` no `refute()` e não
  no `check()` (heading é contrato de byte; refutação é fail-safe quando é mais larga), duas probes
  novas — uma unitária e uma de **ponta a ponta** que roda o sensor inteiro sobre um `templates/`
  adulterado —, mais o **controle negativo** que impede a probe de certificar a si mesma. A
  terceira regra que o relatório pediu **não** entrou, com medição: sob `-i` ela seria decoração.
- `24ee7bf` — **R3, achado #3 (HIGH): a D22 do `CONTEXT.md` carregava o `60%` já refutado.** É a
  linha de base contra a qual a janela 3 vai julgar esta missão, e estava errada na direção que faz
  o alvo parecer mais fácil. O número novo foi **lido do instrumento** (`sdd autonomy --all-repos
  --by-mission` → `25 · 29 · 57`), não copiado da prosa do achado — achado e conserto com fontes
  independentes. O alvo (mediana ≤ 25%, máximo ≤ 50%) **não** se moveu.
- `bffc79f` — **R4, achado #4 (HIGH): a verificação da própria guarda era vácua.** O
  `grep -c REVIEW-EDITED-CODE → 0` que o plano manda ler como saúde responde `0` idêntico quando a
  guarda **não está carregada** — que é o caso desta missão, medido: o processo `sdd run` (PID
  3080293) começou `17:56:48` e o commit que criou a guarda pousou `18:58:11`, então ele carrega o
  `bin/sdd` anterior em memória. Terceiro fail-open **declarado** no cabeçalho da função e em
  `docs/pipeline.md`; o conserto durável (o `sdd run` comparar o hash do `bin/sdd` na entrada) é
  decisão humana e está em `40-review-r1.md § Pendências`.
- `541b524` — **R5, o lote dos achados #5, #6, #8 e #9 (MEDIUM/LOW baratos).** Um `R<n>` de lote,
  pela decisão 6 do `00-missao.md`. **#5** era a irmã exata do `F2`: `review_check '^## Incrementos
  de conserto'` parava antes do qualificador que a descrição promete, e sem ele no template o
  sensor imprimia o `ok` e saía **rc 0**. **#6**, o `GATE_WHY` de árvore suja ainda dizia "fixes
  must be committed" sobre a fase que não conserta mais — a checagem não muda e o comportamento é
  idêntico (`gate_REVIEW` sem comentários difere de `main` em **exatamente uma linha**, a da
  frase), e as palavras antes do travessão ficam verbatim porque três lugares as citam como uma das
  duas recusas que não nomeiam arquivo. **#8**, prosa PT-BR numa fixture de `tests/`, superfície
  declarada inglesa; as três linhas mudam juntas e a guarda `grep -qF` prova o acoplamento (meia
  tradução ⇒ `FAIL R1-done fixture`, medido). **#9**, duas contas do mesmo gemba sem reconciliação
  — o conserto é a **data** e não um número mais novo, porque o ledger lido hoje já dá um
  **terceiro** par (US$ 654,59 de US$ 1.697,75, 28 sessões).

**O que a rodada custou e o que ela prova.** O laço REVIEW⇄EXEC rodou como desenhado: a sessão que
achou não escreveu conserto nenhum, e cada conserto nasceu em contexto zerado com Red próprio,
commit isolado e reversível. Dois dos cinco achados HIGH eram **fail-opens de sensor** (`R1` e
`R2`) — sensores que afirmavam medir o que não mediam —, e nenhum deles é o tipo de coisa que a
suíte verde acusa: apareceram porque um revisor **reproduziu** cada um à mão antes de escrever a
linha. É a mesma família do ciclo QA 1, e a terceira instância seguida em três fases diferentes.

## Rodada REVIEW r2 — os três `R<n>`, um commit cada

> Seção acrescentada em 2026-09-02, quando o último `R<n>` da r2 fechou. A r2 fez o que a r1 não
> podia fazer: **re-julgou consertos que não escreveu**. Os cinco `R<n>` da r1 foram re-verificados
> de fora, um a um, com o Check da própria linha — 5 de 5 passam —, e a rodada achou **8** novos
> (1 HIGH, 3 MEDIUM, 4 LOW), nota `B`, sem editar código nenhum.

- `348a80f` — **R6, achado #1 (HIGH): o auto-teste do `check-templates.sh` era desarmável pelo
  ambiente.** `SDD_TPL_SELFTEST_CHILD=1` pulava o `selftest()` inteiro **e** forçava
  `SELFTEST_RAN=1` — o valor exato que a guarda de vacuidade do fim do arquivo lê —, então o sensor
  imprimia `template contract intact` tendo verificado **nada** sobre si. Fail-open no próprio
  instrumento, que é o pior modo possível segundo o `CLAUDE.md`. O filho do probe end-to-end
  continua pulando (senão recursa); o que mudou é que pular virou estado próprio e passa a **dizer
  alto** que pulou. ⚠️ O Check do `R5` usava essa variável como atalho e mudou no mesmo diff.
- `8cdec98` — **R7, o lote dos achados #2, #3, #4 e #7 (MEDIUM/LOW, todos texto).** Quatro
  afirmações trocadas pelo que foi medido: o limite declarado do `commit --amend` parou de afirmar
  o que a r2 refutou (o objeto continua legível, `git diff` responde, a guarda **avisa** — o mundo
  vazio é o de depois do `gc`); `docs/failure-modes.md` ganhou a ressalva que o `R4` já tinha posto
  nos outros dois sítios da mesma família; as duas células "Depois" do `KAIZEN_LOG` viraram
  auto-declarantes como as seis irmãs, em vez de carregar número duro que apodrece a cada commit;
  e `agents/sdd-reviewer.md` parou de prometer que "the runner notices".
- `6ebed3a` — **R8, achado #5 (LOW): a guarda podia derrubar a linha que ela diz nunca parar.**
  `pipeline_log_line` terminava numa redirecção e, sob `set -e`, redirecção que falha mata o shell
  no ponto em que falha: com o `pipeline.log` sem permissão de escrita, a chamada que três páginas
  deste kit descrevem como "avisa e registra; não para a linha" virava o lugar onde a corrida
  morre. ⚠️ **A medição mudou onde o conserto mora, e as duas premissas do achado caíram:** o
  primeiro morto **não** é a guarda, e sim a linha de sessão do próprio `run_phase`, um chamador
  antes (medido: rc 1, zero linhas de ledger, guarda nunca alcançada); e a irmã `kit_guard_check`
  **não** está salva por terminar em atribuição, porque o shell já se foi uma linha acima, dentro
  do escritor. Um `|| true` no sítio da guarda teria consertado a **frase** do cabeçalho e não o
  runner. A guarda foi para a única definição, na forma que o irmão `autonomy_append` já carregava
  duas telas abaixo — uma regra, uma grafia nos dois escritores —, com o aviso **one-shot** por
  caminho de journal (duas escritas falham por corrida; aviso por linha ensina a rolar a tela).

**O que a r2 prova, e que a r1 não podia provar.** A r1 mostrou que uma rodada consegue achar sem
consertar; a r2 mostrou o outro lado do desenho — **a nota deixou de ser o revisor certificando o
próprio conserto**. Ela re-verificou cinco consertos alheios, confirmou os cinco, refutou uma
hipótese que a própria r1 mandara conferir, e ainda achou um fail-open no sensor que a r1 tinha
usado como atalho. Nenhuma letra desceu entre as rodadas (Type Safety subiu B→A), e o `R8` é o
terceiro caso seguido em que **reproduzir antes de escrever a linha** derrubou parte do achado que
a originou: o conserto que foi para o disco não é o que o relatório pediu, é o que o mundo montado
mostrou ser necessário.

## Rodada REVIEW r3 — os dois `R<n>`, um commit cada

> Seção acrescentada em 2026-09-02, quando o último `R<n>` da r3 fechou. ⚠️ **É a última rodada
> que o caminho derivado abre:** `review_rounds_on_disk` conta arquivos, e com `40-review-r3.md`
> em disco a contagem chega a 3 = `REVIEW_MAX_ITER`. A r3 achou **3** (2 MEDIUM, 1 LOW), nota `B`,
> sem editar código — e os **três nasceram do ciclo de conserto da r2**, o que é a primeira vez
> que a série tem essa propriedade inteira.

- `604d280` — **R9, o lote dos achados #1 e #3 (MEDIUM + LOW, os dois que precisavam de asserção
  nova).** O `2>/dev/null` do `>> "$PIPELINE_LOG"` estava **à direita** da redirecção que falha, e
  o bash aplica redirecção da esquerda para a direita: quando o `open` do journal falhava, a
  queixa do shell saía numa fd 2 ainda não redirigida. O one-shot que o `R8` construiu era, no
  canal que o humano lê, derrotado por um `Permissão negada` cru por linha de journal. Consertado
  nos **dois** escritores (`pipeline_log_line` e `autonomy_append`), porque o `R8` os alinhou de
  propósito e consertar um só é fazê-los derivar pela terceira vez. Junto, o resíduo declarado do
  `R6` ganhou o consumidor que faltava: `tests/run-all.sh` **recusa** a corrida com
  `SDD_TPL_SELFTEST_CHILD` no ambiente, como já recusa `SDD_MUTANT`.
- `f8fcb49` — **R10, achado #2 (MEDIUM): o censo de dez contra os 13 medidos.** O cabeçalho de
  `pipeline_log_line` dizia "it holds for all ten callers, and the eleventh is born with it" e
  "CALLED and never substituted at all ten sites"; medidos, são **13 sítios em 8 funções**, e
  nenhuma das duas leituras — nem chamadores, nem funções — dá dez. A segunda frase não é
  ornamento: é a asserção de que o global `PIPELINE_LOG_WARNED` nunca morre num subshell, escrita
  sobre uma população menor que a real. ⚠️ **O conserto não é escrever 13** — número em rubrica
  nasce velho no próximo chamador, que é como este mesmo cabeçalho chegou a dez. É a forma do
  `CLAUDE.md` para o `44 caught of 44`: a frase fala de **todo** chamador e carrega ao lado o
  comando que conta.

**O que o `R10` acrescenta à série, e que nenhum `R<n>` anterior tinha.** O segundo censo embutido
derruba linha de comentário **de propósito**, e isso foi medido em vez de suposto: o bloco exibe a
grafia proibida (`$(pipeline_log_line …)`) um parágrafo abaixo, então o `grep` cru responde `1` e
não `0` — exatamente o um-a-mais que a rubrica do `CLAUDE.md` nomeia com o `44 caught of 44`. Um
censo que caísse nessa armadilha teria trocado um número podre por um comando mentiroso, que é
estritamente pior: o número podre pelo menos não se diz medição. Os dois comandos foram copiados
do comentário e rodados verbatim — `13` e `0`.

**O que a r3 prova.** Terceira rodada seguida em que o desenho novo se sustenta: a r3 re-verificou
de fora os três consertos que não escreveu (`R6`, `R7`, `R8` — 3 de 3 passam pelo Check da própria
linha, e o mutante do `R8` foi **aplicado** numa cópia da caixa do `check-mutation.sh` para matar
exatamente uma asserção, a nomeada). A curva de achados é `12 → 8 → 3`, sem CRITICAL desde sempre
e **sem HIGH pela primeira vez**. ⚠️ O que a série também mostra é o custo do laço: os três
achados da r3 **nasceram do ciclo de conserto da r2** — consertar cria trabalho de revisão, e é
essa a alavanca que a M2 mede e não fecha.

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20260901-o-revisor-so-acha/checkpoint.md` | I1–I4, F1–F4 e R1–R5 `done` com hash; notas de execução com cada desvio do plano e o porquê medido |
| `docs/handoffs/20260901-o-revisor-so-acha/40-review-r1.md` | a primeira rodada do desenho novo: 12 achados, nota `B`, 5 `R<n>`, 3 refutações com evidência — e **nenhum** conserto escrito pela própria rodada |
| `docs/handoffs/20260901-o-revisor-so-acha/40-review-r2.md` | a segunda rodada: re-julga os cinco consertos que não escreveu (5 de 5 passam), acha 8 novos, nota `B`, 3 `R<n>` — e a medição da M2 registrada **antes** de o resultado do laço ser conhecido |
| `docs/handoffs/20260901-o-revisor-so-acha/40-review-r3.md` | a terceira e **última** rodada que o teto permite: re-julga os três consertos da r2 (3 de 3 passam), acha 3 novos — todos nascidos do ciclo de conserto anterior —, nota `B`, 2 `R<n>`; a M2 medida nas duas metades (por rodada melhorou 48%, por laço piorou) e as três opções do humano no `§ Pendências` |
| `KAIZEN_LOG.md` (entrada de 2026-09-01) | o "antes" medido, a régua reprodutível, a correção do 60% → 57% da janela 2, e a coluna **Depois em aberto** |
| `CONTEXT.md` (verbete *Laço REVIEW⇄EXEC*, D22, D23) | o desenho novo e como ele pousou, um hash por fatia |
| `config/schema.md` · `docs/failure-modes.md` · `docs/pipeline.md § REVIEW` | o contrato onde alguém procura quando algo dá errado |
| `agents/sdd-reviewer.md` · `agents/sdd-executor.md` · `templates/review.md` · `templates/checkpoint.md` | o contrato dos artefatos que a próxima fase escreve |

## Boot da próxima fase

> ⚠️ **Atualizado em 2026-09-02.** Quando esta seção foi escrita a próxima fase era a QA; ela
> rodou (`30-handoff-qa.md`), levantou `F1`–`F4`, e o laço QA⇄EXEC os fechou. Com o checkpoint sem
> nenhuma linha `pending`, a fase derivada do disco agora é a **REVIEW** — e é ela o primeiro teste
> real do contrato que esta missão escreveu. O que segue vale para as duas: descreve o diff.

A QA já rodou. No kit não há interface: `E2E_CMD` é vazio, o runner só abre `QA:close` — a sessão
de QA caminhou a jornada ela mesma, e a jornada aqui é **de linha de comando**.

**O que no diff é visível ao usuário do kit** (o humano que roda `sdd`):

1. `./bin/sdd autonomy --by-mission` e `--all-repos --by-mission` ganharam o sufixo
   `· review loop US$ X (N%)`, que só aparece em missão que teve sessão REVIEW. Hoje **16 células**
   o imprimem no ledger real. Confirmação independente: `20260831-a-rodada-que-andou` lê
   `review loop US$ 66.34 (50%)`, exatamente o número que o `00-missao.md` cita para o PR #33.
2. Linha de sessão do ledger tem campo novo `turns`; linhas de escalada e `gate_pass` **não**.
   Leitor antigo ignora campo desconhecido.
3. `./bin/sdd run <missão> --phase REVIEW --dry-run` imprime um boot prompt **diferente**: manda
   achar e escrever `R<n>`, e não contém mais `review and fix, INSIDE`.
4. Uma sessão REVIEW que commitar código fora do diretório da missão passa a emitir um `warn` na
   stderr e uma linha `REVIEW-EDITED-CODE` em `.sdd/logs/<missão>/pipeline.log`. **Desde `b1cfc27`
   isso vale também para quem escreveu `HANDOFF_DIR` com barra final** — antes, esse repo-alvo
   receberia o aviso em toda rodada saudável, sobre o relatório da própria rodada.
5. `sdd install --force` re-sincroniza dois agentes (`sdd-reviewer`, `sdd-executor`); os espelhos
   já estão em dia nesta branch (`diff -q` vazio para os sete).

**Como subir o ambiente:** não há ambiente para subir. `cd ~/repos/sdd_agents && ./bin/sdd preflight`
e `tests/run-all.sh` são o mundo inteiro. ⚠️ **Não rodar `./bin/sdd health` nas fases QA/REVIEW** —
ele leva 15–50 min (roda o catálogo de mutação) e o carimbo pertence à fase DOCS, depois do último
commit de código.

⚠️ **Atualização de 2026-09-02 — a próxima fase é a rodada `r2`.** Os cinco `R<n>` da r1 fecharam,
o checkpoint não tem linha `pending`, e a bola volta para a REVIEW. O que a r2 precisa saber, e que
não está em nenhum outro lugar:

1. **Ela re-avalia consertos que não escreveu** — é exatamente para isso que o desenho existe. Os
   cinco commits a auditar são `d06840a`, `045d8dd`, `24ee7bf`, `bffc79f` e `541b524`; o que cada um
   fez está na seção `## Rodada REVIEW r1` acima, e o que a r1 alegou está em `40-review-r1.md`.
2. **Dois consertos mexeram em SENSOR, não em código de produção** (`R2` e o `#5` do `R5`, ambos em
   `tests/check-templates.sh`), e sensor consertado por quem leu o achado é o lugar clássico de um
   fail-open novo. O `R5` mediu o seu nos dois sentidos, com o mundo isolado por
   `SDD_TPL_SELFTEST_CHILD=1` — a forma está na célula do Check e o porquê nas notas do checkpoint.
3. **O `R4` não consertou nada de comportamento, de propósito** — declarou um limite. Se a r2
   discordar de que declarar bastava, o lugar da discordância é um achado, não um `R<n>` silencioso.
4. **Achado que só um humano pode fechar continua não virando `R<n>`** (Jidoka): vai para
   `## Pendências`, a nota fica honesta e a linha para. Duas dessas já existem na r1.

⚠️ **Atualização de 2026-09-02 — a próxima fase é a rodada `r3`, e ela é a ÚLTIMA.**
`REVIEW_MAX_ITER=3` e `review_rounds_on_disk` conta rodadas **em total** (o `sdd run` não zera):
com `40-review-r1.md` e `r2` em disco, a r3 é a última rodada que o teto permite — se ela também
não fechar em A, o runner escala (`BLOCKED`, ou PR em draft conforme `PUBLISH_ON_REVIEW_BLOCKED`).
O que a r3 precisa saber, além do que já está acima:

1. **Os três commits a auditar são `348a80f`, `8cdec98` e `6ebed3a`**, e o que cada um fez está na
   seção `## Rodada REVIEW r2` acima; o que a r2 alegou está em `40-review-r2.md`.
2. **O `R8` conserta em lugar diferente do que o achado pediu, de propósito e com medição.** O
   achado #5 apontava o ramo de aviso de `review_scope_check`; o conserto está em
   `pipeline_log_line`, porque o mundo montado mostrou que o primeiro morto é a linha do
   `run_phase`, um chamador antes. Se a r3 discordar, o lugar da discordância é um achado com
   reprodução — a reprodução do `R8` está no corpo do commit e no regime 7 do sensor.
3. **Dois dos três `R<n>` mexeram em SENSOR** (`R6` no `check-templates.sh`, `R8` no
   `check-autonomy.sh`), e sensor consertado por quem leu o achado continua sendo o lugar clássico
   de um fail-open novo. O `R8` traz a passada de sabotagem no corpo do commit (quatro degradações,
   cada uma derrubando só a sua) e **declara** no cabeçalho o arm que ficou sem probe, com o mundo
   que foi construído para tentar quebrá-lo.
4. **A M2 já não fecha e isso está registrado** (`40-review-r2.md`): r1 custou US$ 17,92 contra o
   teto de 15, e o laço passou de US$ 40 antes mesmo da r2. Medir de novo é útil; **reescrever o
   alvo depois de conhecer o resultado não é** — é o modo de falha que o `KAIZEN_LOG` de
   2026-08-31 nomeia.

⚠️ **Atualizado em 2026-09-02, com o `R10` fechado: a próxima coisa que acontece NÃO é uma r4, e a
sequência é determinada.** A r3 rodou, achou 3, deu `B`, e com `40-review-r3.md` em disco
`review_rounds_on_disk` = 3 = `REVIEW_MAX_ITER`. Com o checkpoint agora sem nenhuma linha
`pending`, `gate_EXEC` passa, `gate_REVIEW` lê a nota `B` da r3 e reprova, e o runner bate no teto
e encerra em **`BLOCKED` com a `ceiling_note`**. **Isso é Jidoka, não gate insatisfazível** — a r3
refutou essa hipótese com a leitura do código (`bin/sdd:4511`, o caminho `--phase REVIEW` é
**isento** do teto por construção, "refusing that would leave no way to run the round that unblocks
the mission"). O artefato tem dono e o humano tem porta. As três portas, em ordem de preço e com a
recomendação da própria r3, estão em `40-review-r3.md § Pendências`: **(a)** `sdd run <missão>
--phase REVIEW`, isento do teto, abre uma r4 que re-julga `R9`/`R10` — **recomendada**, custa uma
rodada de achar (US$ 16–18 nesta missão); **(b)** `REVIEW_MAX_ITER=4`, que muda a régua de toda
missão futura e por isso é a mais cara; **(c)** aceitar o `B` e seguir para o PR com
`PUBLISH_ON_REVIEW_BLOCKED=draft`.

**Se a porta escolhida for (a), o que a r4 precisa saber além do que já está acima:**

1. **Os dois commits a auditar são `604d280` (R9) e `f8fcb49` (R10)**, e o que cada um fez está na
   seção `## Rodada REVIEW r3` acima; o que a r3 alegou está em `40-review-r3.md`.
2. **O `R10` é o primeiro `R<n>` desta missão que não move comportamento nenhum** — `git diff -U0
   bin/sdd` filtrado por linha não-comentário devolve **vazio**, e por isso não traz asserção nem
   mutante novo (régua de admissão do D15: probe ali sondaria a existência de um comentário). O que
   ele traz para ser auditado é **o texto de dois censos executáveis**: rode-os verbatim, copiados
   do comentário, e confira que respondem `13` e `0`. Censo que mente é pior que número podre.
3. **O `R9` mexeu em `bin/sdd` E em `tests/`, e apodreceu a âncora de um mutante vizinho** —
   `mut_RUN_journal_write_stops_the_line` casava exatamente a grafia que o conserto trocou, e
   passou a aplicar **zero**. Foi reancorado no mesmo commit e os 227 do catálogo foram reaplicados
   um a um (`checked=227 rotten=0`). O `R10` refez a conferência na vizinhança que tocou: os
   **cinco** mutantes ancorados na faixa de `pipeline_log_line` continuam aplicando, mudando 1
   linha cada e compilando.
4. **A M2 não fecha e as duas metades apontam para lados diferentes** — está medido e registrado em
   `40-review-r3.md` **antes** de a janela 3 abrir. Medir de novo é útil; reescrever o alvo depois
   de conhecer o resultado não é.

⚠️ **Para a fase REVIEW, que é a primeira a rodar o contrato novo:** o desenho que ela deve seguir
está no seu próprio boot prompt e em `agents/sdd-reviewer.md`. Duas coisas que a M2 do
`00-missao.md` mede sobre esta própria missão: cada sessão REVIEW **≤ 60 turnos e ≤ US$ 15**, e o
laço de revisão inteiro (REVIEW + EXEC dos `R<n>`) **≤ US$ 40**. A M3 é invariante: o
`gate_REVIEW` **não mudou** (A em toda linha + `Rationale` com frase), e o diff de
`agents/sdd-reviewer.md` **não removeu** nenhuma regra de reprodução ou refutação — isso é para ser
**conferido** na revisão, não assumido.

## Pendências / Decisions for a Human

- **A coluna "Depois" do `KAIZEN_LOG.md` está em aberto de propósito.** Ela só pode ser preenchida
  depois de a REVIEW desta missão rodar, e quem a preenche é a fase DOCS com os comandos de
  `01-plano.md § Para a fase DOCS`. Não é bloqueio: é a recusa deste repo em registrar previsão
  como medição.
- **A janela 3 abre no sha do merge desta missão** (padrão D19) e o veredito é do `sdd kaizen`
  depois de 2–3 missões reais do `sales_quote`, sem commit na `main` do kit. Decisão de quando
  abrir e fechar é humana.

## Riscos e não-feitos

- **Nenhum número de custo mudou ainda.** O diff é contrato, instrumento e guarda; o efeito é a
  próxima rodada de REVIEW. A M1 (mediana ≤ 25%, máximo ≤ 50%) só fecha na janela 3.
- **O carimbo de mutação (`.sdd/logs/mutation-stamp`) está morto** desde `88432ee`: `bin/`,
  `tests/` e `templates/` mudaram. `gate_PR` o exige. Re-emitir é tarefa da DOCS, **depois** do
  último commit de código — e registrar achado no `TODO.md` invalida a chave outra vez
  (`tests/health-baseline.txt` está dentro dela). Ordem: achados → catraca → `./bin/sdd health`.
- ⚠️ **Atualizado em 2026-09-02 (`R10`): o último commit de código da missão é agora `f8fcb49`,
  e o catálogo está em 227.** O `R9` acrescentou dois mutantes (um por metade da asserção) e
  **reancorou** um terceiro cuja âncora o próprio conserto tinha apodrecido; o `R10` não
  acrescentou nenhum, porque não mudou comportamento nenhum. É depois de `f8fcb49` que o
  `./bin/sdd health` re-emite o carimbo — e só depois de a DOCS ter transportado os achados para o
  `TODO.md`, porque a catraca está na chave. ⚠️ **Se o humano escolher a porta (a) e a r4 achar
  algo**, cada `R<n>` novo empurra esse ponto para a frente outra vez: o carimbo pertence ao último
  commit de código **da missão**, nunca ao da fase corrente.
- **O catálogo de mutação (225 depois do `R8`) não foi rodado ponta a ponta nesta fase** — é
  opt-in desde `4c86712` e seguraria a árvore por >10 min por gate. Cada um dos **sete** mutantes
  novos foi provado numa cópia da árvore (aplica, `cmp` acusa diferença, `bash -n` compila, e o
  sensor nomeado fica vermelho **só** na asserção nomeada), mas a verificação do catálogo inteiro
  é da DOCS. ⚠️ `6ebed3a` é o **último commit de código** até aqui — é depois dele que o
  `./bin/sdd health` re-emite o carimbo, e só depois de a DOCS já ter transportado os achados para
  o `TODO.md` (a catraca está na chave). ⚠️ Se a **r2 achar algo**, cada `R<n>` novo empurra esse
  ponto para a frente: o carimbo pertence ao último commit de código da missão, não ao desta fase.
  O `R5` acrescentou uma verificação que vale repetir na DOCS: os **8** mutantes endereçados a
  `gate_REVIEW` foram reaplicados numa cópia **depois** da inserção dos comentários novos e todos
  os 8 continuam aplicando e compilando — comentário inserido perto de âncora de mutante é
  exatamente como uma âncora apodrece em silêncio.
- **A guarda `REVIEW-EDITED-CODE` avisa, não impede**, e tem três cegueiras declaradas no
  cabeçalho da própria função: um `commit --amend` que reescreva o HEAD anterior, o braço
  `tests/health-baseline.txt` que é **incondicional** apesar de existir só para o repo do kit, e a
  normalização de `HANDOFF_DIR` que tira só barra **final** (um `./` na frente ou um caminho
  absoluto ainda erram, e nenhum tem probe).
- **`turns` é um contador do harness, não uma medida de contexto.** Correlaciona com o cache-read
  (corr 0,94 sobre 28 rodadas, R² 0,36 — ordem de grandeza) e não o substitui.
- **O desenho novo gasta duas rodadas no caminho normal** (r1 é B por desenho quando há o que
  consertar), então `rounds` deixa de ser comparável entre janelas. Régua declarada no
  `KAIZEN_LOG.md`, no `CONTEXT.md` (D22) e no `config/schema.md`.
- ~~**Não verificado:** nenhuma sessão REVIEW real rodou ainda no contrato novo.~~ **Verificado na
  r1** (`40-review-r1.md`): a sessão achou 12 defeitos, escreveu cinco `R<n>` e **não editou
  código**. ⚠️ Com um limite que a própria rodada mediu e que a M2 precisa saber: aquele processo
  `sdd run` carrega o `bin/sdd` **pré-I1** em memória (achado #4 / `R4`), então o prompt de boot que
  a r1 recebeu ainda dizia `review and fix, INSIDE` — o chapéu novo chegou por
  `agents/sdd-reviewer.md`, que é lido do disco a cada sessão. A rodada seguiu o contrato novo
  **apesar** do prompt velho, o que é evidência mais forte para o agente e **nenhuma** evidência
  para o `phase_task`: o caminho do prompt continua verificado só pelo dry-run.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta fase, e é deliberado:** `tests/health-baseline.txt` está
> na chave do carimbo de mutação, então registrar achado aqui mataria o carimbo outra vez
> (`01-plano.md § Configuração e pitfalls`). Os itens abaixo são para a **fase DOCS** transportar
> ao `TODO.md` **com a catraca no mesmo diff**, antes do `./bin/sdd health`. Este repo **é** o kit,
> então o destino é o `TODO.md` daqui — nenhum item precisa da rota `kit:`.

- ⚠️ **Widening do item que a QA já escreveu (janela cega do runner velho), não item novo:** o
  `R4` mediu a mesma janela numa **segunda** superfície — `review_scope_check` (`bin/sdd`), e não
  só o ledger. O item que a DOCS transportar deve citar as duas âncoras, porque a consequência é
  diferente em cada uma: no ledger o campo novo não é escrito; na guarda o `grep -c
  REVIEW-EDITED-CODE` responde `0` **sem** distinguir "medido limpo" de "não medido", que é um
  fail-open de leitura. O limite já está **declarado** no cabeçalho da função e em
  `docs/pipeline.md` (é o que o `R4` fez); o que segue pendente e é decisão humana é o conserto
  durável (r1 § Pendências).
- **Achado novo desta fase (`R10`): o censo de dez tem uma segunda casa, e a varredura que fechou
  a primeira a encontrou.** `tests/check-entrypoint.sh:419` diz *"makes all ten assertions above
  pass at once and none of them can notice"* sobre as asserções acima dela; medido agora,
  `grep -cE '^ *probe ' ` responde **14**, e as 14 estão todas acima daquela linha. É a mesma
  classe do achado #2 da r3 — censo escrito em prosa, que envelhece no próximo probe acrescentado
  — num arquivo que o `CLAUDE.md` cita nominalmente como exemplo da régua. ⚠️ **Duas ressalvas que
  a triagem precisa, para não abrir item maior que o defeito:** (i) é mais **fraco** que o do
  `pipeline_log_line`, porque ali o número guardava uma propriedade viva ("nunca substituída em
  `$( )`") e aqui ele descreve uma sabotagem que já foi medida; (ii) as outras duas ocorrências
  (`:60` e `:329`) são **história honesta** e não devem ser tocadas — dizem que a versão frouxa
  passou nos dez probes **que existiam então**, e a frase seguinte de `:60` já anuncia "Probes 11
  and 12 close it". Conserto sugerido: a forma do `R10` — a frase fala de **todas** as asserções e
  carrega ao lado `grep -cE '^ *probe ' tests/check-entrypoint.sh` —, nunca escrever 14 → `TODO.md`
  (descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha`, 2026-09-02)
- `run_phase` não limpa o ambiente do harness antes do `claude -p` — `bin/sdd` (função
  `run_phase`) — um `sdd run` lançado de dentro de uma sessão do Claude Code herda
  `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_MESSAGING_SOCKET` e afins e é morto pelo harness sem
  ação humana (2× em 2026-08-30); a saída é `env -u CLAUDECODE -u CLAUDE_CODE_* …` no próprio
  `run_phase`, com o probe correspondente — descoberto por `humano` na missão
  `20260830-invariante-do-frete-no-agregado` (2026-08-30), registrado em `01-plano.md § Achados do
  planejamento` por `sdd-planner` (2026-09-01) → `TODO.md`
- `tests/check-lang.sh` `surface()` **enumera** arquivos em vez de casar `docs/*.md` —
  `tests/check-lang.sh:50` — um doc novo em `docs/` nasce **fora** da régua de idioma enquanto o
  `CLAUDE.md § Idioma` promete `docs/` inteiro; o I4 cobriu `docs/graphify.md` **um arquivo por
  vez**, o glob fica como decisão — descoberto por `sdd-planner` na missão
  `20260901-o-revisor-so-acha` (2026-09-01) → `TODO.md`
- **Achado novo desta fase (I4):** o piso anti-vacuidade do `tests/check-lang.sh` **ficou três
  caminhos para trás** e ninguém percebeu — ele dizia 37 enquanto a superfície real já era 40,
  porque as ADRs 0004, 0005 e 0006 entraram pelo glob `docs/adr/*.md` sem tocar o número. Piso que
  fica para trás continua **passando** medindo uma superfície menor que a que lê, que é a falha
  que o próprio comentário do sensor já nomeia uma vez (r1 de `20260817-eixo-do-juiz`). Corrigido
  aqui para 41, mas a **classe** continua viva: todo piso deste repo que convive com um glob tem o
  mesmo modo de falha, e nenhum instrumento avisa quando um deles fica para trás — só o humano
  que recontar. Candidato: derivar o piso, ou um sensor que compare piso × superfície real em
  todos os sensores que têm um → `TODO.md` (descoberto por `sdd-executor` na missão
  `20260901-o-revisor-so-acha`, 2026-09-01)
- ~~**Achado novo desta fase (F2):** a asserção vizinha `review_check '^## Incrementos de
  conserto'` para antes do qualificador que o rótulo promete.~~ **RESOLVIDO por `541b524`, NÃO
  transportar para o `TODO.md`.** O item foi escrito aqui pelo `F2` por ser "o já que estou aqui
  que aquela fase recusa"; a rodada r1 o achou de forma independente (achado #5), ele virou parte
  do lote `R5`, e o conserto está em disco com a medição nos dois sentidos. Fica registrado
  riscado, e não apagado, porque a **rota** é a lição: um achado deixado fora de escopo com o
  motivo escrito foi encontrado outra vez pelo instrumento seguinte, que é o comportamento que se
  quer de um pipeline com fases de chapéu único.
- **Achado novo desta fase (R8), medido e deliberadamente NÃO consertado:** o `R8` fechou a última
  escrita de I/O desguardada do **journal**, e sobrou a irmã dela um nível acima —
  `run_phase` cria o diretório de log da sessão sem guarda nenhuma. Medido nesta sessão, montando
  o mundo: com `.sdd/logs` em modo 500, `sdd run --phase REVIEW` morre com um `mkdir: Permissão
  negada` cru na stderr, **rc 1, nenhuma linha de ledger e nenhum `warn` do kit** — a mesma classe
  que o `R8` acabou de consertar duas funções abaixo, e a razão de o arm do `mkdir` de
  `pipeline_log_line` não ter probe (o mundo dele é dominado por esta morte anterior). Consertar
  aqui seria o "já que estou aqui" que esta fase recusa: é outra função, outro contrato (o log da
  sessão **é** a evidência da fase, então talvez a resposta certa seja um `die` com frase, e não um
  `warn` que segue) — decisão que merece um achado próprio, não um remendo de escopo. `bin/sdd`
  (função `run_phase`, criação do `log_dir`) → `TODO.md` (descoberto por `sdd-executor` na missão
  `20260901-o-revisor-so-acha`, 2026-09-02)
- **Achado novo desta fase (F3):** os dois diagramas de ordem canônica — `README.md:12`
  (`TICKET → EXEC → QA ⇄ EXEC → REVIEW → DOCS → PR`) e `docs/pipeline.md:26`
  (`PLAN → TICKET → EXEC ⇄ QA → REVIEW → DOCS → PR`) — desenham o laço da QA e deixam `REVIEW` em
  linha reta, mas desde o I2 o laço `REVIEW ⇄ EXEC` é o **espelho** dele: achado vira `R<n>`
  `pending`, `gate_EXEC` volta a reprovar e o runner devolve a bola ao executor. O leitor do README
  sai hoje com o modelo mental que esta missão existe para apagar. Ficou fora do diff do `F3`
  porque a linha nomeia `README.md:152` e porque consertar só o README o poria **à frente** do doc
  de referência — é sync de documentação viva, isto é, decisão da fase DOCS desta mesma missão
  → `TODO.md` se a DOCS não o fizer (descoberto por `sdd-executor` na missão
  `20260901-o-revisor-so-acha`, 2026-09-01)
- **Achado novo desta fase (F3):** **nenhum instrumento mede prosa de contrato fora de
  `templates/`.** O `refute()` que o `F1` acabou de criar (`tests/check-templates.sh`) só lê
  `templates/`; `README.md` e `docs/*.md` entram na `surface()` do `tests/check-lang.sh`, que mede
  **idioma** e nada mais. Consequência medida nesta missão: o I2 mudou o contrato em cinco lugares,
  o sexto (`README.md:152`) sobreviveu à suíte verde e só apareceu numa jornada de QA caminhada por
  um agente — e o sétimo (o diagrama, acima) sobreviveu à própria QA. Candidato: um `refute()`
  sobre a superfície de docs, ou uma regra que ligue a tabela dos 6 agentes do `README.md` ao
  frontmatter de `agents/*.md`. Tem consumidor **fora** da suíte do kit (quem adota o kit lê o
  README), então passa a régua de admissão do D15 → `TODO.md` (descoberto por `sdd-executor` na
  missão `20260901-o-revisor-so-acha`, 2026-09-01)
- **Achado novo desta fase (F4):** **nenhuma chave de caminho do `.sdd/config.sh` é normalizada
  antes de virar padrão de `case`, e o `F4` fechou só uma delas.** `review_scope_check` compara
  `$TODO_FILE` **literalmente** contra a saída de `git diff --name-only`; um repo-alvo que escreva
  `TODO_FILE="./TODO.md"` — ou `HANDOFF_DIR="./docs/handoffs"`, que a normalização nova também não
  pega — reproduz exatamente o defeito que o `F4` acabou de consertar, com um raio menor.
  `grep -c 'TODO_FILE#\./' bin/sdd` → `0`; o mesmo vale para toda outra chave de caminho lida do
  config. Ficou **fora** do diff porque a linha do `F4` nomeia a barra final de `HANDOFF_DIR`, que
  foi a grafia reproduzida, e porque uma regra escrita para um mundo que este autor não construiu é
  a sobre-confiança que o `d4deb35`/`7cbc8e2` é a cicatriz — o limite está **declarado** no
  cabeçalho da função em vez de adivinhado. Passa a régua de admissão do D15 por **consumidor fora
  da suíte do kit** (é a config de qualquer repo adotante), e o conserto certo é provavelmente uma
  normalização **única** na leitura do config, com um probe por chave — não um `%/` espalhado
  → `TODO.md` (descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha`, 2026-09-02)
- **Achado novo desta fase (R3):** **o `templates/checkpoint.md` afirma um universal que o próprio
  kit viola — `check-templates.sh` imprime `  ok   ` com TRÊS espaços.** O template diz, em tantas
  palavras, *"Todo sensor da suíte imprime `  ok    <asserção>` na stdout"*, e
  `tests/check-checkpoint.sh:111` transforma isso em `OK_ANCHOR='^  ok    '` **cobrado** nos
  checkpoints do repo-alvo. Mas `tests/check-templates.sh:50` e `:87` (as primitivas `check()` e
  `refute()`) imprimem três espaços; só o `selftest()` do mesmo arquivo (`:171`, `:208`) imprime
  quatro. Medido nesta sessão: `779` linhas casam `^  ok    ` contra `861` asserções reais — **82**
  linhas fora do universal. A `R2` desta missão escapou por acidente, não por desenho: o Check dela
  ancora numa linha de `selftest()`, que é do lado de quatro espaços; `F1` e `F2` ancoraram em
  `rc=$?` e nenhuma nota registra que a razão era essa. Falha **fechada** (o Check responde `0`
  parecendo vermelho), então não é o fail-open do D15 — entra pela **outra** metade da régua:
  `templates/checkpoint.md` é embarcado em todo repo adotante e ensina a regra como universal, e
  `check-checkpoint.sh` a cobra lá. Conserto candidato: alinhar as duas primitivas do
  `check-templates.sh` em quatro espaços (diff de dois caracteres, mas move 82 linhas de saída e
  quer conferência dos Checks vivos), **ou** o template deixar de afirmar o universal e nomear a
  exceção. Não entrou neste diff porque a linha do `R3` nomeia o número da D22 e porque a escolha
  entre os dois consertos é da fase DOCS, dona do contrato do template
  → `TODO.md` (descoberto por `sdd-executor` na missão `20260901-o-revisor-so-acha`, 2026-09-02)
