---
missao: 20260901-o-revisor-so-acha
fase: REVIEW
rodada: 3
status: done
sessao: ff0eebee-f116-4c57-8c07-9bb9d3e36fed
data: 2026-09-02 01:05
gate: "`tests/run-all.sh` → **864** asserções `ok`, última linha `suite green`, rc 0; árvore limpa antes e depois (`git status --short` → 0 linhas), HEAD `a04103b`. Secrets pre-scan determinístico sobre `git diff 51ce74c..HEAD -- bin/ tests/ templates/ config/ agents/` → **1** casamento, e é a palavra inglesa *token* num comentário do `check-templates.sh`: nenhum segredo. Os três `R6`–`R8` da r2 foram re-verificados de fora com o Check de cada linha: **3 de 3 passam**, e o mutante `RUN_journal_write_stops_the_line` aplicado numa cópia da árvore mata **exatamente uma** asserção, a nomeada (`warns:0 journal:0 rc:1 rows:0`). **A rodada NÃO fecha:** 3 achados (2 MEDIUM, 1 LOW), os 3 reproduzidos com comando nesta sessão, e os 3 nascidos do ciclo de conserto da r2; 2 incrementos `R9`–`R10` `pending` no `checkpoint.md`. Nota real **B** em Code Quality, Error Handling e Test Coverage. M2 medida e **não fecha**: r1 US$ 17,92 · r2 US$ 16,38 (teto 15), laço de revisão **US$ 75,07 (61%)** de US$ 123,10 contra o teto de US$ 40 — com a outra metade do número no corpo, porque o custo **por rodada** caiu 48%. ⚠️ `REVIEW_MAX_ITER=3` e esta é a rodada 3: o caminho derivado não abre uma r4."
---

# Review — rodada r3 — O revisor só acha

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Terceira rodada, e a segunda que julga consertos que não escreveu. Os três `R6`–`R8` fecharam de
verdade — re-rodei o Check de cada um de fora, e apliquei o mutante do `R8` numa cópia da árvore
para conferir que a asserção nova mede a propriedade e não o fixture. **3 achados novos**, 2 MEDIUM
e 1 LOW, os três reproduzidos com comando, e a coisa que os une é o achado da rodada: **os três
nasceram do ciclo de conserto da r2**. Nota **B**, dois incrementos `R9`–`R10`. Nada foi consertado
aqui. ⚠️ Esta é a última rodada que o caminho derivado abre (`REVIEW_MAX_ITER=3`) — a seção de
pendências diz o que isso deixa na mão do humano.

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O censo escrito no cabeçalho de `pipeline_log_line` diz **dez** — "all ten callers", "all ten sites" — e o comando responde **13** sítios em **8** funções; tentei as duas leituras e nenhuma dá dez. É a classe que o `CLAUDE.md` nomeia com o `44 caught of 44`, e aqui o número não é ornamento: ele guarda a propriedade "nunca substituída em `$( )`", que um leitor confere em dez e para. |
| Type Safety | A | Toda captura nova do ciclo é guardada (`2>/dev/null \|\| true` no `mkdir`, `\|\| { … return 0; }` no `>>`), o ramo de aviso devolve 0 explicitamente e o marcador one-shot é global escrito por função **chamada**, nunca substituída — conferido nos 13 sítios. O mutante prova que a guarda é a única coisa entre este mundo e `rc 1`. |
| Error Handling | B | O `2>/dev/null` do `>> "$PIPELINE_LOG"` está **depois** da redireção que falha, então não suprime o erro dela: reproduzido com o corpo real da função, três linhas contra um journal em `chmod 000` dão **1** aviso curado e **3** `Permissão negada` crus na mesma stderr — exatamente o "aviso repetido por linha" que o commit do `R8` diz ter evitado. A propriedade grande (a linha não para) vale e está provada; o que não vale é o silêncio prometido. |
| Security | A | Secrets pre-scan determinístico sobre o código novo do ciclo (`51ce74c..HEAD` em `bin/ tests/ templates/ config/ agents/`): 1 casamento, a palavra inglesa *token* num comentário. Nenhuma superfície nova — o `R8` só acrescentou uma redireção guardada e um global de processo, e o `chmod 000` do regime 7 vive dentro do `$OUTSIDE` que a fixture já destrói. |
| Performance | A | O ciclo não acrescentou execução de suíte a gate nenhum: o custo por linha de journal continua sendo um `>>`, o one-shot troca N avisos por um, e a suíte foi de 861 para 864 asserções sem mudança mensurável nos ~105 s. Os dois probes novos do `R6` leem um `ctl.out` que a rodada anterior já tinha em mãos, sem abrir processo extra. |
| Test Coverage | B | O regime 7 e o mutante do `R8` são exemplares — piso `armed:1` provando o veneno ligado, `warns:1` provando a guarda disparada, e o mutante matando **uma** asserção, a nomeada. Mas o resíduo que o `R6` declarou tem um consumidor que o cabeçalho não nomeia: `tests/run-all.sh` é literalmente "um leitor que lê só o rc" (`run()`, `bin`-agnóstico), então com `SDD_TPL_SELFTEST_CHILD` exportada a suíte imprime `suite green` com 4 asserções `self-test:` a menos e nenhuma guarda — e o `run-all.sh` já sabe recusar um ambiente (`SDD_MUTANT`). |
| Documentation | A | O `R7` fechou a deriva que a r2 achou e a conferência é por comando, não por leitura: as 6 células "Depois" auto-declarantes do `KAIZEN_LOG` viraram 8, o censo das **três** portas da guarda bate (1 definição, 3 portas), o piso de superfície do `check-lang.sh` é 41 sobre 41 reais, o catálogo dá 225 definições contra 225 entradas, os 7 espelhos de `agents/` estão `diff -q` vazios e o `config/schema.md` descreve o desenho novo em `REVIEW_MAX_ITER` e `BUDGET_REVIEW_USD` sem número podre. |
| **Overall** | **B** | Dois MEDIUM e um LOW, os três reproduzidos, os três criados pelo ciclo de conserto da r2 — 12 → 8 → 3 achados, sem CRITICAL desde sempre e **sem HIGH pela primeira vez**. O desenho novo se provou pela terceira vez (a r2 achou sem consertar, o EXEC fechou os três, esta rodada re-julgou sem ter escrito o patch), mas o diff não fecha em A nesta passada. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | o `2>/dev/null` está **à direita** do `>>` que falha, e o bash processa redireções da esquerda para a direita: quando o `open` do journal falha, a mensagem do shell sai na stderr que ainda não foi redirecionada. Resultado — 1 aviso curado (one-shot, correto) **mais um `Permissão negada` cru por linha de journal**, na mesma stderr do operador. O one-shot que o commit do `R8` construiu e que o probe pina com `journal:1` é derrotado no canal que o humano lê. A grafia irmã de `autonomy_append` tem o mesmo defeito, e o `R8` alinhou as duas de propósito | `bin/sdd:1721` (irmã em `:1775`) |
| 2 | MEDIUM | o censo do cabeçalho diz "it holds for all **ten** callers, and the eleventh is born with it" e "CALLED and never substituted at **all ten sites**"; medido, são **13** sítios em **8** funções distintas — nenhuma das duas leituras dá dez. A segunda frase não é ornamento: é a asserção de que o global `PIPELINE_LOG_WARNED` nunca morre num subshell, e ela foi escrita sobre uma população 30% menor que a real | `bin/sdd:1681` e `:1696` |
| 3 | LOW | o limite que o `R6` declarou — "um leitor que seta a variável, ignora duas linhas altas e lê o rc sozinho" — tem um consumidor **dentro do kit** que o cabeçalho não nomeia: `run()` do `tests/run-all.sh` lê o rc e nada mais, e é o `TEST_CMD` que todo gate roda. Medido: `SDD_TPL_SELFTEST_CHILD=1` no ambiente ⇒ `check-templates.sh` sai `rc 0`, 4 linhas `ok    self-test:` a menos, e `run()` conta o passo como verde. O `run-all.sh` já recusa um ambiente (`SDD_MUTANT`, `:191`) e não recusa este | `tests/check-templates.sh:25-30`; `tests/run-all.sh` (`run()`) |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.
>
> ⚠️ Nada de `|` cru na célula do Check — a tabela é lida com `awk -F'|'`. Herestring.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R9 | lote dos achados #1 e #3 — os dois que precisam de asserção nova | duas asserções novas, uma no `check-autonomy.sh` e uma no `check-templates.sh`, ambas ancoradas em `^  ok    ` |
| R10 | achado #2 — o censo de dez contra os 13 medidos | três termos de `grep` sobre o corpo da função mais a suíte verde — ver a linha no `checkpoint.md` |

⚠️ **Por que dois e não um.** A régua do lote pede **um** `R<n>` para os MEDIUM/LOW baratos da
rodada, e o que a separa aqui é o `tests/check-checkpoint.sh`, não a preguiça: a presença de uma
captura `$(bash tests/…)` na célula põe **todos** os padrões da célula sob a regra do `^  ok    `,
e o achado #2 é um `grep` de arquivo que nenhum sensor lê. Foi exatamente o que reprovou a primeira
versão das linhas do `R6`/`R7` da r2. O preço da separação está medido nesta mesma missão e é
**US$ 5,10** (a média das 16 sessões EXEC) — declarado aqui para que a decisão seja com o número na
mão, e não com o "US$ 1–2 por boot" que a decisão 6 do grill estimou.

## O que virou incremento

> Um `R<n>` por item, com a linha exata que foi para o `checkpoint.md`. Achado "resolvido" sem
> incremento é rótulo: quem prova que fechou é o commit do executor, na rodada seguinte.

- **Achado #1** — virou `R9`. O conserto é mover o `2>/dev/null` para **antes** do `>>`
  (`printf '%s\n' "$*" 2>/dev/null >> "$PIPELINE_LOG" || { … }`), medido nos dois sentidos nesta
  sessão: com o `2>` à direita saem 3 erros crus em 3 chamadas; com ele à esquerda sai **zero**, e
  o ramo de aviso continua disparando (`GUARD-FIRED` na reprodução mínima). ⚠️ A asserção tem de
  cobrir **os dois escritores** — `pipeline_log_line` e `autonomy_append` carregam a mesma grafia,
  e o `R8` alinhou as duas com o argumento "uma regra, uma grafia, nos dois escritores"; consertar
  só uma é fazê-las derivar de novo pela terceira vez. Por isso o Check nomeia **uma** asserção que
  fala dos dois, e não duas que se possam fechar pela metade. ⚠️ O Check tem de ler o **sensor**:
  o regime 7 já tem o `RS7_ERR` na mão e simplesmente não asseverou sobre ele — a evidência estava
  no fixture e a asserção olhava para o outro canal.
- **Achado #3** — virou `R9` (mesmo lote, porque também precisa de asserção ancorada em
  `^  ok    `). O conserto **não** é tirar a variável de ambiente: o filho do probe de ponta a ponta
  precisa dela, ou recursa — isso o `R6` já resolveu certo. O que muda é que o `tests/run-all.sh`
  passa a recusar a corrida quando a variável está no **seu** ambiente, na forma que ele já usa
  para o `SDD_MUTANT`, e o `check-templates.sh` ganha o probe que prova a recusa. ⚠️ O cabeçalho
  do `check-templates.sh` (`:25-30`) muda junto: o resíduo declarado deixa de ser "um leitor" no
  abstrato e passa a nomear quem era.
- **Achado #2** — virou **`R10`**, linha própria pela regra do `check-checkpoint.sh` explicada
  acima. ⚠️ O conserto **não é escrever 13**: o número nasce velho no próximo `pipeline_log_line`
  acrescentado, que é como o `KAIZEN_LOG` chegou a `855` asserções e o achado #4 da r2 nasceu. O
  conserto é a forma que o `CLAUDE.md` já prescreve — a frase passa a falar de **todo** chamador e
  carrega ao lado o comando que conta, como os censos de `grep -cE` daquele arquivo. É por isso que
  o Check exige as duas grafias mortas **e** a presença de um `grep -cE` no corpo da função.

### O que a rodada anterior fechou, verificado de fora

- **`R6`** — fechado em `348a80f`. Check re-rodado verbatim: as duas asserções novas
  (`the probes cannot be skipped from the environment`, `skipping the probes is announced, never
  silent`) respondem `1` e `1`. Conferido nos dois sentidos: a corrida saudável imprime 4 linhas
  `ok    self-test:` e termina em `template contract intact`; com a variável setada imprime **0** e
  termina em `template rules checked, self-test NOT run`. O fail-open HIGH da r2 está morto — o que
  sobrou dele é o achado #3 acima, que é o resíduo declarado, não o buraco original.
- **`R7`** — fechado em `8cdec98`. Check re-rodado verbatim: `1`, `0`, `8`, `0`. As duas células
  "Depois" com número duro viraram auto-declarantes (6 → 8 na coluna), `docs/failure-modes.md`
  ganhou a ressalva do `R4`, o enunciado refutado do `commit --amend` saiu dos **três** lugares em
  que vivia, e `agents/sdd-reviewer.md` parou de prometer que "the runner notices" — com o espelho
  `.claude/agents/` sincronizado (`diff -q` vazio nos 7).
- **`R8`** — fechado em `6ebed3a`. Check re-rodado verbatim: `1`. E a asserção foi medida em vez de
  lida: apliquei `mut_RUN_journal_write_stops_the_line` numa cópia da árvore (`bin tests templates
  config agents` + `CLAUDE.md TODO.md docs/adr`, a mesma caixa que o `check-mutation.sh` monta), o
  sed mudou **exatamente 1 linha**, `bash -n` compilou, e `check-autonomy.sh` ficou vermelho em
  **uma** asserção — a nomeada — com `armed:1 sessions:1 warns:0 journal:0 rc:1 rows:0`. Vermelho
  pelo motivo certo: o piso `armed:1` continuou em pé, então o veneno estava ligado e o que caiu foi
  a propriedade.

## O que foi refutado

> Achado que você acredita estar errado **não** se resolve mudando o código para agradá-lo.
> Verifique; se estiver errado, registre aqui o porquê, com evidência.

- **"O censo de dez conta funções, não sítios — `bin/sdd:1681` está certo e só `:1696` erra"** —
  **refutado com comando, e era a leitura caridosa que eu tinha de tentar antes de acusar duas
  linhas.** `awk` amarrando cada sítio à função que o contém dá **13 sítios** em **8 funções**
  distintas (`app_down_escalation`, `cmd_close`, `cmd_run`, `ensure_mission_branch`,
  `handoff_blocked_escalation`, `kit_guard_check`, `review_scope_check`, `run_phase`). Nenhuma das
  duas leituras dá dez, então as duas frases erram e as duas entram no `R10`.
- **"O `R6` deixou o resíduo por descuido"** — **refutado**: o cabeçalho declara o limite na forma
  que o `CLAUDE.md` exige ("qual é o resíduo", não "esse mundo não existe"), e o rc 0 é **obrigatório**
  — o controle de ponta a ponta lê o rc do filho, e um filho vermelho ali significa "templates/ está
  quebrado de verdade". O achado #3 não pede o rc de volta; pede que o único leitor de rc que o kit
  tem seja nomeado e recuse.
- **"O `2>/dev/null` do `>>` não faz nada e devia sair"** — **refutado pela metade, e a metade
  importa.** Ele não cobre a falha do `open`, que é o mundo do probe; mas cobre erro do próprio
  `printf` **depois** de o open ter dado certo (disco cheio, EPIPE), e esses também caem no ramo
  `||`. O conserto é **mover**, nunca remover — foi por isso que o Check pede zero erro cru e não
  a ausência do `2>`.
- **"O mutante do `R8` pode ter apodrecido a âncora de outro mutante"** — **refutado por medição**,
  o mesmo risco que a r2 conferiu para os 11 dela. O `mut_RUN_journal_write_stops_the_line` ancora
  na faixa `/^pipeline_log_line()/,/^}/`, e o `^}` casa só a chave de coluna zero — o `}` do bloco
  `|| { … }` é indentado. Aplicado, mudou 1 linha e compilou; o catálogo continua com 225
  definições contra 225 entradas de `CATALOG=(`, sem órfão dos dois lados.
- **"O `chmod 000` do regime 7 pode ficar para trás e envenenar a limpeza da fixture"** —
  **refutado**: o arquivo mora dentro de `$OUTSIDE`, e `rm -rf` de um diretório gravável remove um
  arquivo em modo 000 sem reclamar. A suíte inteira rodou verde depois dele nesta sessão (864
  asserções), e o regime 7 restaura o stub como os seis anteriores.
- **"O teto de rodadas torna o `gate_REVIEW` insatisfazível — a classe que o princípio 1 proíbe"** —
  **refutado com a leitura do código.** No teto o runner **para a linha e escala** (`bin/sdd:4518`,
  `bad "BLOCKED in $phase"` mais a `ceiling_note`), que é Jidoka e não gate insatisfazível; e o
  caminho `--phase REVIEW` é **isento** por construção (`:4511`, `[ -z "$force_phase" ]`), com o
  comentário dizendo exatamente por quê: "refusing that would leave no way to run the round that
  unblocks the mission". O artefato tem dono e o humano tem porta.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta rodada, e é deliberado**, pelo mesmo motivo que o EXEC, a
> QA, a r1 e a r2 declararam: `tests/health-baseline.txt` está na chave do carimbo de mutação. Os
> itens abaixo são para a **fase DOCS** transportar ao `TODO.md` com a catraca no mesmo diff,
> **antes** do `./bin/sdd health`. Este repo é o kit, então nenhum item precisa da rota `kit:`.

- Nenhum item novo. Os **oito** que a r1 e a r2 deixaram para a DOCS continuam de pé e não foram
  re-listados aqui para não fazer a DOCS transportar metade: os seis da r1 (o braço `else ""` da
  célula do laço sem fixture em `bin/sdd:5124`, o `turns` sem view humana em `bin/sdd:2517`, o
  comentário de `tests/check-gates.sh:897`, a evidência inexistente citada na refutação R2 do
  `30-handoff-qa.md:79`, e os 4 itens já mergeados que o `TODO.md:691` devia ter apagado) e os dois
  da r2 (a suíte sem `timeout` em lugar nenhum, medida em `rc=124`; o limite não declarado de
  `reviewscope_files()` em `tests/check-autonomy.sh:4398`). Ver
  `40-review-r1.md § Achados fora de escopo` e `40-review-r2.md § Achados fora de escopo`.

## Pendências / Decisions for a Human

> O que exige julgamento humano: trade-off de arquitetura, quebra de contrato, decisão de produto.

- **⚠️ ESTA É A ÚLTIMA RODADA QUE O CAMINHO DERIVADO ABRE.** `review_rounds_on_disk` conta
  **arquivos**, e com o `40-review-r3.md` em disco a contagem chega a 3 = `REVIEW_MAX_ITER`. A
  sequência a partir daqui é determinada: `gate_EXEC` reprova pelas linhas `R9`/`R10` `pending` →
  duas sessões EXEC as fecham → `gate_REVIEW` lê a nota **B** desta rodada e reprova → o runner
  tenta REVIEW e bate no teto, encerrando em `BLOCKED` com a `ceiling_note`. **Isso é Jidoka
  funcionando, não bug** (refutado acima). As três portas do humano, em ordem de preço: (a)
  `sdd run <missão> --phase REVIEW`, que é **isento** do teto por construção e abre uma r4 que
  re-julga os dois consertos; (b) `REVIEW_MAX_ITER=4` no `.sdd/config.sh`, que muda a régua para
  toda missão futura e por isso é a mais cara; (c) aceitar o B e seguir para o PR com
  `PUBLISH_ON_REVIEW_BLOCKED=draft`. **A recomendação desta rodada é (a)**: os dois achados são
  baratos e a r4 custa uma rodada de achar, que nesta missão saiu por US$ 16–18.
- **A M2 não fecha, e a leitura honesta tem duas metades que apontam para lados diferentes.**
  Por **rodada**, o desenho novo entregou o que prometeu: US$ 17,92 (r1) e US$ 16,38 (r2), média
  **US$ 17,15**, contra US$ 37,10 e US$ 29,24 (média 33,17) da missão de kit anterior — **48% menos
  por rodada**, com o teto de US$ 15 estourado por pouco nas duas. Por **laço**, piorou: **US$ 75,07
  (61%)** de US$ 123,10, contra US$ 66,34 (50%) da `20260831` e contra o teto de US$ 40. O que move
  o número é a conta que ninguém tinha: **16 sessões EXEC, US$ 79,00, média US$ 5,10 por
  incremento** — 3 a 5× o "US$ 1–2 por boot" que a decisão 6 do grill usou para desenhar a régua de
  lote. **A régua de lote está certa na direção e errada na constante**, e a alavanca dominante do
  desenho novo passa a ser *quantas linhas `R<n>` uma rodada escreve*, não quanto uma rodada de
  achar custa. Registrado antes de a janela 3 abrir, para que ninguém reescreva o alvo depois.
- **O sinal de parada do laço disparou, e ele merece o julgamento do humano.** A régua do agente
  manda parar num platô ou numa regressão de letra: Documentation subiu B → A, mas Error Handling
  **desceu** A → B, e a razão é a que mais importa — **os 3 achados desta rodada foram criados ou
  deixados pelo ciclo de conserto da r2** (`R8` escreveu o `2>/dev/null` fora de ordem e o censo de
  dez; `R6` deixou o resíduo do #3). É o padrão que o `CLAUDE.md` manda tratar como sinal: "três
  vezes seguidas o conserto de uma rodada criou o defeito que a seguinte encontrou … pare de
  remendar e pergunte que estado está faltando". A leitura desta rodada é que o estado faltante
  **não** é de desenho, e sim de instrumento: as três famílias (ordem de redireção, censo em
  comentário, resíduo declarado sem consumidor nomeado) são as três coisas que este repo já sabe
  que não tem sensor — e as duas primeiras são candidatas naturais a regra de scanner no
  `check-pipefail.sh`, que já varre `bin/` e `tests/` linha a linha. **Isso é missão seguinte, não
  esta**; fica aqui porque é a semente que a magnitude sugere (12 → 8 → 3, sem HIGH pela primeira
  vez).
- **O carimbo de mutação continua morto e o `R9`/`R10` o empurram mais para a frente.**
  `gate_PR` o exige. A ordem não mudou: achados → catraca do `TODO.md` → `./bin/sdd health`,
  **depois** do último commit de código, que agora será o do `R10` (ou o do `R9`, se o executor os
  fechar fora de ordem).
- **As pendências que EXEC, QA, r1 e r2 abriram seguem de pé:** a coluna "Depois" do `KAIZEN_LOG.md`
  (agora **8** células auto-declarantes, preenchidas pela DOCS de uma vez), quando abrir e fechar a
  janela 3 (no sha do merge, padrão D19), e fechar a janela cega do runner velho — que esta rodada
  confirma pela terceira vez, porque o prompt de boot que recebi ainda é o pré-`03187e8`.
