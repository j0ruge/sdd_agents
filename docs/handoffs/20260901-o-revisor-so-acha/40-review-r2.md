---
missao: 20260901-o-revisor-so-acha
fase: REVIEW
rodada: 2
status: done
sessao: 0d2dcb68-41a1-4ab4-a811-ec569adb4336
data: 2026-09-02 03:35
gate: "`tests/run-all.sh` → **861** asserções `ok`, última linha `suite green`, rc 0; árvore limpa antes e depois (`git status --short` → 0 linhas), HEAD `b129012`. Secrets pre-scan do `codereview` sobre `git diff main...HEAD --unified=0` → `{\"findings\":[],\"scanners\":[\"regex\"],\"errors\":[]}`. **A rodada NÃO fecha:** 8 achados (1 HIGH, 3 MEDIUM, 4 LOW), 7 deles reproduzidos com comando nesta sessão; 3 incrementos `R6`–`R8` `pending` no `checkpoint.md`. Nota real **B** em Code Quality, Test Coverage e Documentation — três critérios, contra os quatro da r1, e **nenhuma letra desceu** (Type Safety B→A). Os cinco `R1`–`R5` da r1 foram re-verificados de fora, um a um, com o Check de cada linha: 5 de 5 passam. M3 conferida: `gate_REVIEW` difere de `main` em **uma** linha não-comentário (a frase do `GATE_WHY`), 7 de 7 espelhos `diff -q` vazios, nenhuma regra de reprodução/refutação removida. M2 medida e **não fecha**: r1 = 48 turnos (≤ 60 ✅) e **US$ 17,92** (≤ 15 ❌); laço de revisão da missão = **US$ 40,92 (46%)** de US$ 88,94, contra o teto de US$ 40 — lido pelo instrumento do I1 e reconferido à mão."
---

# Review — rodada r2 — O revisor só acha

> Escrito ao fim de cada rodada de revisão, em `docs/handoffs/<missão>/40-review-r<N>.md`.
> O runner lê **a mais recente**. Uma rodada que não fechou também escreve o arquivo, com a nota
> real: nota inflada para passar no gate desliga o único sensor de qualidade da missão.

## TL;DR

Segunda rodada, e a primeira que julga um conserto que **não escreveu**. Os cinco `R1`–`R5` da r1
fecharam de verdade: re-rodei o Check de cada linha de fora e os cinco passam, e reproduzi os dois
piores (a guarda com nome acentuado, as regras `refute()` cegas à maiúscula) nos dois sentidos.
**8 achados novos** — 1 HIGH, 3 MEDIUM, 4 LOW —, 7 reproduzidos com comando. O HIGH é um fail-open
no auto-teste do `check-templates.sh`: a variável de ambiente que o probe end-to-end usa para não
recursar **desarma o auto-teste inteiro** e ainda força `SELFTEST_RAN=1`, satisfazendo a própria
guarda de vacuidade — e o `checkpoint.md` desta missão ensina um humano a passá-la. Nota **B**,
três incrementos `R6`–`R8`. Nada foi consertado aqui.

## Nota da rodada

⚠️ **O heading abaixo é `###` — três sustenidos — e a tabela é a do `codereview`.** O
`gate_REVIEW` procura o literal `^###[[:space:]]+Overall Grade`.

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | B | O limite declarado do `commit --amend` em `bin/sdd:2245-2247` é **falso**: reproduzi duas vezes que `git diff` tem sucesso e a guarda avisa corretamente, porque o objeto continua no ODB mesmo inalcançável — e o comentário do `\|\| true` em `:2283` se apoia na mesma premissa ("a real world"). Limite declarado que descreve mal a realidade é pior que limite ausente sob a régua do D15. |
| Type Safety | A | O achado #1 da r1 fechou e foi provado nos **dois** sentidos: com `-c core.quotePath=false` o caminho não-ASCII sai literal e a rodada saudável lê `nonascii:1 … lines:0 warns:0`; revertendo o conserto, `lines:1 warns:1`. O resíduo (aspas, contrabarra, controle) está declarado no cabeçalho e só produz falso-positivo, nunca fail-open — conferido contra o `case` da allowlist com `M10` e `M1-extra`, que não casam. |
| Error Handling | A | Toda captura nova é guardada (`\|\| true`, sentinela `-` sem HEAD anterior), herestring no lugar de pipe, `n=$(( n + 1 ))` como atribuição. Cinco hipóteses de `set -e` foram levantadas e **refutadas com reprodução**; a única que sobreviveu (o rabo do warn) precisa de um `pipeline.log` sem permissão de escrita, é instância de um padrão que já existia nas três escaladas e vai na linha `R8`. |
| Security | A | Secrets pre-scan determinístico sobre o diff inteiro: `{"findings":[],"scanners":["regex"],"errors":[]}`. Nenhuma superfície nova: a guarda **lê** nomes de arquivo e nunca os executa, todo `git` roda com `-C "$REPO_ROOT"`, e o `*` da allowlist não é alcançável por travessia porque o git recusa rastrear caminho com componente `..`. |
| Performance | A | O acréscimo por sessão continua sendo um `git diff --name-only` entre dois shas e uma passada `jq` por grupo `(repo, missão)`; a suíte foi de 858 para 861 asserções sem mudança mensurável nos ~105 s, e os cinco commits de conserto não acrescentaram nenhuma execução de suíte a gate nenhum. |
| Test Coverage | B | O regime 6 e o mutante do `R1` são exemplares — piso `nonascii:1` provado **armado** (desarmá-lo derruba a asserção), diferencial byte a byte contra o regime 2, catálogo 224 = 224 sem órfão dos dois lados, e os 11 mutantes de `gate_REVIEW`/guarda aplicam exatamente uma linha e compilam. Mas o `check-templates.sh` tem um fail-open **no próprio auto-teste** (achado #1) e sua remoção produz travamento em vez de vermelho, sem `timeout` em lugar nenhum da suíte. |
| Documentation | B | `docs/failure-modes.md:433` é o único lugar que manda um humano diagnosticar pelo `grep REVIEW-EDITED-CODE` e é justamente o que o `R4` **não** alcançou (o limite entrou em `bin/sdd` e em `docs/pipeline.md:458`), então ausência do marcador lê como "a rodada não consertou". E as células "Depois" de `KAIZEN_LOG.md:69-70` dizem 855 asserções e 222 mutantes contra 861 e 224 medidos hoje, enquanto as células irmãs da mesma tabela usam a fórmula auto-declarante. |
| **Overall** | **B** | Um HIGH e três MEDIUM com reprodução, quatro LOW; três incrementos `R6`–`R8` `pending`. O desenho novo se provou pela segunda vez — a r1 achou sem consertar, o EXEC fechou os cinco, e esta rodada re-julgou sem ter escrito o patch —, mas o diff não fecha em A nesta passada. |

## Achados da rodada

> Um item por achado, com severidade e âncora em `arquivo:linha`. O achado que precisa de conserto
> aparece de novo na seção seguinte, como incremento `R<n>` — nunca com hash: quem conserta é o
> executor, na sessão de depois. O que foi refutado vai para `## O que foi refutado`, com evidência.

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | `SDD_TPL_SELFTEST_CHILD` setada no ambiente pula o `selftest()` inteiro **e força `SELFTEST_RAN=1`**, satisfazendo a guarda de vacuidade de `:409` que existe exatamente para recusar a corrida em que o auto-teste não rodou. O sensor imprime `template contract intact` tendo verificado **zero** coisas sobre si mesmo. O comentário de `:216-218` justifica a variável dizendo que uma flag seria pior porque "um humano poderia passá-la" — e o `checkpoint.md:46` desta missão documenta um humano passando **esta** | `tests/check-templates.sh:219` (guarda em `:409`) |
| 2 | MEDIUM | o limite declarado do `commit --amend` afirma que `git diff` **falha** e que a função "não diz nada"; medido duas vezes, `git diff` sai `rc=0` e devolve a lista certa, porque objeto inalcançável continua no ODB — a guarda avisa corretamente. O comentário do `\|\| true` em `:2283` chama esse mundo de "a real world" apoiado na mesma premissa | `bin/sdd:2245-2247` (e `:2283`) |
| 3 | MEDIUM | o único lugar do kit que ensina a **diagnosticar** pelo `grep REVIEW-EDITED-CODE` é o que ficou sem o limite que o `R4` declarou nos outros dois (`bin/sdd` e `docs/pipeline.md:458`): quem seguir esta linha lê ausência do marcador como "a rodada não consertou", que é a direção do fail-open | `docs/failure-modes.md:433` |
| 4 | MEDIUM | as células "Depois" dizem `855` asserções e `222` mutantes; o medido hoje é **861** e **224**. As irmãs da mesma tabela carregam `*(medido pela fase DOCS desta missão)*` — estas duas carregam número duro que era verdade quando escrito e apodrece a cada commit, sem nada dizer que é provisório | `KAIZEN_LOG.md:69-70` |
| 5 | LOW | o ramo de aviso da guarda termina em `pipeline_log_line`, cujo status sobe para as **três** portas, todas chamadas sem guarda sob `set -e`: com o `pipeline.log` sem permissão de escrita o runner morre antes da linha seguinte. A irmã `kit_guard_check` termina numa **atribuição** e não consegue fazer isso, e três lugares do kit afirmam que esta guarda "stops nothing" | `bin/sdd:2327` (portas em `:4534`, `:4647`, `:4756`) |
| 6 | LOW | remover a condicional da guarda de recursão faz o probe end-to-end recursar sem fim: `timeout 20` corta em `rc=124` sem nenhum `SENSOR-BROKEN`. Não há `timeout` no `run-all.sh` nem no `run_check_cmd`, então essa sabotagem sai como silêncio-por-travamento — a mesma classe que já matou três sessões de REVIEW deste repo com as palavras *"waiting for the suite"* | `tests/check-templates.sh:219`; `tests/run-all.sh` |
| 7 | LOW | "the runner notices and logs `REVIEW-EDITED-CODE`" afirma sem a ressalva que o `R4` declarou: um runner anterior ao commit da guarda não nota nada. É a frase que dissuade o próprio revisor, e ela promete mais do que o instrumento entrega | `agents/sdd-reviewer.md:76` |
| 8 | LOW | `reviewscope_files()` explica a escolha do `-F': '` mas não usa a fórmula `DECLARED LIMIT:` que o arquivo usa em `:1891`, `:2400` e `:3605`, nem diz que um caminho com `": "` volta sem split. Pré-existente, e o regime 6 **não** o chama — lê o `git diff` cru | `tests/check-autonomy.sh:4398` |

## Incrementos de conserto (R<n>)

> **Esta rodada não conserta.** Cada achado que precisa de conserto vira uma linha `R<n>` na tabela
> de incrementos do `checkpoint.md`, e o `sdd-executor` a fecha em TDD, numa sessão de contexto
> próprio; a rodada seguinte re-avalia sem ter escrito o conserto.
>
> ⚠️ Nada de `|` cru na célula do Check — a tabela é lida com `awk -F'|'`. Herestring.

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R6 | #1 — o auto-teste do `check-templates.sh` é desarmável pelo ambiente, em silêncio e verde | duas asserções novas do `selftest()`, ambas ancoradas em `^  ok    ` |
| R7 | lote dos achados #2, #3, #4 e #7 (texto: comentário, doc, `KAIZEN_LOG`, agente) | quatro termos de `grep` em arquivo mais a suíte verde — ver a linha no `checkpoint.md` |
| R8 | #5 — o ramo de aviso da guarda pode derrubar a linha que ele diz não derrubar | uma asserção nova do `check-autonomy.sh`, com o mundo montado (log sem permissão de escrita) |

⚠️ **A primeira versão destas linhas foi reprovada pelo `tests/check-checkpoint.sh`, e isso é o
sensor funcionando sobre o revisor.** O `R6` original misturava um padrão ancorado em `^  ok    `
com um `grep -c 'template contract intact'` **não** ancorado sobre a saída fundida de um sensor —
e `FAIL` imprime o mesmo texto que `ok`, então aquela célula responderia "a asserção existe" e
nunca "a asserção passou". O `R7` original tinha o mesmo problema em 4 dos 5 termos, porque a
presença de uma captura `$(bash tests/…)` na célula põe **todos** os padrões sob a regra. A saída
foi separar por natureza: `R6` e `R8` leem sensor e ancoram tudo; `R7` só lê arquivo. O achado #5
ganhou linha própria por ser o único do lote que precisa de asserção nova.

## O que virou incremento

> Um `R<n>` por item, com a linha exata que foi para o `checkpoint.md`. Achado "resolvido" sem
> incremento é rótulo: quem prova que fechou é o commit do executor, na rodada seguinte.

- **Achado #1** — virou `R6`, linha própria por ser HIGH e por ser fail-open de sensor, que este
  repo trata como o pior modo possível. O conserto **não** é "rodar o auto-teste sempre": o filho
  que o probe end-to-end abre precisa mesmo pulá-lo, ou recursa. O que tem de mudar são duas
  coisas, e a segunda é a que fecha o buraco: (a) o ramo que pula **não pode** forçar
  `SELFTEST_RAN=1` — a guarda de `:409` deixa de ser satisfeita por quem ela existe para pegar; e
  (b) a corrida de topo com a variável setada tem de dizer alto que pulou, em vez de imprimir
  `template contract intact`. ⚠️ O `checkpoint.md:46` (o Check do `R5`) usa a variável como atalho
  de conferência: ou ele muda junto, ou o conserto quebra um Check já `done`. ⚠️ O piso do
  `selftest` e o `REVIEW_FLOOR` (hoje 26, e hoje **correto** — medi 26 asserções reais) se recontam
  no mesmo diff se alguma regra nova nascer.
- **Achado #2** — virou `R7` (lote). As três linhas do bullet passam a dizer o que foi medido: o
  objeto continua legível depois do amend, `git diff` responde, e a guarda **avisa**. O mundo em que
  o bullet estaria certo existe — depois de um `gc`/`prune` que remova o objeto solto —, e é esse
  que deve ser escrito, pela regra que o `CLAUDE.md` já nomeia: diga **qual mundo você não
  conseguiu construir**, nunca que ele não existe. O comentário de `:2283` perde o "a real world" e
  mantém o `\|\| true`, que continua certo por outro motivo (o `gc` futuro).
- **Achado #3** — virou `R7` (lote). A mesma frase que o `R4` pôs em `bin/sdd` e em
  `docs/pipeline.md` entra em `docs/failure-modes.md:433`, ao lado do `grep` que ela qualifica. É
  um terceiro sítio de uma família que o `R4` fechou em dois — pela régua do D15, dívida declarada
  é limite, e este sítio é o que um humano abre quando o laço está estranho.
- **Achado #4** — virou `R7` (lote). ⚠️ O conserto **não é escrever 861 e 224**: o `R6` mexe em
  `tests/`, então qualquer número escrito agora nasce velho outra vez — foi exatamente por isso que
  a r1 não fez disso um `R<n>`. O conserto é mudar a **classe** da célula: as duas passam a
  `*(medido pela fase DOCS desta missão — ver `01-plano.md § Para a fase DOCS`)*`, como as seis
  irmãs da mesma tabela, e a DOCS as preenche junto com o resto da coluna, uma vez, no fim.
- **Achado #5** — virou **`R8`**, linha própria: é o único do lote que precisa de asserção nova, e
  misturá-lo com `grep` de arquivo foi o que o `check-checkpoint.sh` reprovou (ver o aviso acima).
  O ramo de aviso passa a não poder derrubar a linha, como a irmã `kit_guard_check` já não pode.
  ⚠️ O Check tem de ler um **sensor**, não o texto do conserto: a asserção nova monta o mundo (log
  sem permissão de escrita, guarda disparando) e exige que o runner chegue à linha seguinte. Sem
  esse mundo montado, a asserção é decoração — é a regra do "prove primeiro que sabotou o que dizia
  sabotar". Reprodução desta rodada, num harness com o corpo real da função: `pipeline.log` em
  `chmod 000` ⇒ o script morre antes da linha seguinte; `chmod 644` ⇒ chega nela. Diferencial.
- **Achado #7** — virou `R7` (lote). Uma oração em `agents/sdd-reviewer.md:76` dizendo que o
  registro depende de o runner em memória já carregar a guarda. ⚠️ `agents/*.md` sincroniza com
  `sdd install --force`, nunca com `cp` nem com Edit no espelho — senão o `sdd preflight` fica
  vermelho em `agent sdd-reviewer stale`.

## O que foi refutado

> Achado que você acredita estar errado **não** se resolve mudando o código para agradá-lo.
> Verifique; se estiver errado, registre aqui o porquê, com evidência.

- **"O `REVIEW_FLOOR` ficou para trás — o `R2` acrescentou regra e não mexeu no piso (26)"** —
  **refutado, e era a hipótese que a própria r1 mandou conferir.** O `R2` não acrescentou sítio
  nenhum: consertou a **primitiva compartilhada**, trocando `grep -qE` por `grep -qiE` dentro de
  `refute()`, o que conserta as duas chamadas de uma vez e é melhor do que a r1 prescreveu (ela
  pedia a mudança nas duas chamadas). O piso conta asserções **executadas**
  (`CHECKS_RUN - REVIEW_MARK`), não chamadas, e a suíte imprime `26 assertion(s)` contra
  `REVIEW_FLOOR=26`. Não está para trás.
- **"A terceira regra que a r1 prescreveu (refutar o heading `^## O que foi corrigido` inteiro) não
  foi escrita"** — **verdadeiro como fato e refutado como defeito.** Reproduzi o cenário exato da
  r1 numa cópia: com `## O que foi corrigido` reintroduzido **ao lado** da seção nova, o sensor sai
  vermelho com `FAIL review.md: still carries … (regex: o que foi corrigido)`, e o mesmo vale para
  a grafia minúscula. A regra dedicada seria redundante, e o `CLAUDE.md` manda **remover** regra
  que a sabotagem não consegue quebrar, não escrever probe para ela.
- **"O `GATE_WHY` do `R5` mudou o `gate_REVIEW` e fere a M3"** — **refutado com comando.** A função
  sem comentários difere de `main` em exatamente **2** linhas de `diff` (uma removida, uma
  acrescentada) — a frase, e só ela. As palavras antes do travessão ficaram verbatim, e conferi que
  os três lugares que as citam como limite declarado continuam achando a string
  (`bin/sdd:2011`, `docs/pipeline.md:702`, `tests/check-autonomy.sh:2431`). A recuperação
  `historic_rounds` ancora em `^40-review-r` e em `^no 40-review-r<N>.md`; esta recusa não estava
  em nenhum dos dois ramos antes e continua não estando.
- **"Comentário novo perto de âncora de mutante apodreceu a âncora"** — **refutado por medição**, e
  era o risco que o próprio handoff do EXEC pediu para reconferir. Apliquei os **11** mutantes que
  tocam `gate_REVIEW` e a guarda numa cópia: os 11 mudam **exatamente uma linha** cada, e os 11
  compilam (`bash -n`). Nenhum sed virou no-op.
- **"O catálogo não bate depois do `R1`"** — **refutado**: 224 definições `^mut_…() {` contra 224
  entradas do `CATALOG=(`, sem duplicata e sem órfão dos dois lados.
- **"A quarta porta da guarda está faltando (`cmd_close`)"** — **refutado outra vez, agora pelo
  censo**: 1 definição, 3 portas, e a primeira linha de `review_scope_check` só responde a
  `REVIEW`, enquanto o `sdd close` roda como fase `CLOSE`. Os censos do `CLAUDE.md` continuam
  batendo: 2 definições de escalada, 4 portas delas, 4 portas da guarda de kit, 6 sensores com
  `^selftest()` e 7 com `selftest` solto, 13 sensores.
- **"O regime 6 é o regime 2 com outro nome — o piso não está armado"** — **refutado com sabotagem
  dirigida.** A fixture pina `git config core.quotePath true` (`:4299`) e o piso lê o `git diff`
  **cru**, sem o override do runner, exigindo a grafia escapada `round\302\267one.md`. Trocando o
  pin para `false`, a asserção fica vermelha com `nonascii:0`. E a expectativa depois do piso é a do
  regime 2 caractere por caractere — é diferencial, não constante com roupa de medição.
- **"O `turns` continua sem ser escrito, então o I1 não funciona"** — **refutado quanto ao código e
  confirmado quanto à janela.** As 15 linhas desta missão têm `turns` vazio porque o processo
  `sdd run` é anterior ao commit que criou o campo — o mesmo achado #4 da r1. O instrumento em si
  funciona: `sdd autonomy --by-mission` imprime `review loop US$ 40.92 (46%) · US$ 88.94`, e a
  recomputação independente por `jq` sobre o ledger cru dá o mesmo `88.9447514` de 15 sessões.
- **"O prompt de boot desta sessão manda consertar, então o contrato não pousou"** — **refutado, e
  é evidência do limite já declarado.** O `phase_task` que esta sessão recebeu diz *"review and fix,
  INSIDE this session"*, que é o texto **pré-`03187e8`**: o processo `sdd run` carrega o `bin/sdd`
  que parseou na largada. O contrato novo chegou por `agents/sdd-reviewer.md`, lido do disco a cada
  sessão — e é ele que esta rodada seguiu. O `bin/sdd` em disco já diz *"you do NOT fix the code"*
  (`:1532`), conferido.

## Achados fora de escopo

> ⚠️ **Nada foi escrito no `TODO.md` nesta rodada, e é deliberado**, pelo mesmo motivo que o EXEC, a
> QA e a r1 declararam: `tests/health-baseline.txt` está na chave do carimbo de mutação. Os itens
> abaixo são para a **fase DOCS** transportar ao `TODO.md` com a catraca no mesmo diff, **antes** do
> `./bin/sdd health`. Este repo é o kit, então nenhum item precisa da rota `kit:`.

- **Achado #6** — a suíte não tem `timeout` em lugar nenhum — `tests/run-all.sh:65` e
  `bin/sdd:488` — então uma regra quebrada que recursa sai como travamento sem mensagem, e não como
  vermelho; medido em `rc=124` sob `timeout 20`. É a classe que já custou três sessões de REVIEW
  deste repo (`4c86712`), e o conserto é barato mas precisa de um número escolhido a dedo —
  descoberto por `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02) → `TODO.md`
- **Achado #8** — `reviewscope_files()` não declara seu limite na fórmula do arquivo —
  `tests/check-autonomy.sh:4398` — um caminho com `": "` volta sem split e o diagnóstico trunca em
  silêncio; o arquivo usa `DECLARED LIMIT:` em `:1891`, `:2400` e `:3605` e este não usa. **Já
  estava na lista da r1**; repetido aqui só para a DOCS não transportar metade — descoberto por
  `sdd-reviewer` na missão `20260901-o-revisor-so-acha` (2026-09-02) → `TODO.md`
- Os **seis** itens que a r1 deixou para a DOCS continuam de pé e não foram re-listados: o braço
  `else ""` da célula do laço sem fixture (`bin/sdd:5124`), o `turns` sem view humana
  (`bin/sdd:2517`), o comentário de `tests/check-gates.sh:897`, a evidência inexistente citada na
  refutação R2 do `30-handoff-qa.md:79`, e os 4 itens já mergeados que o `TODO.md:691` devia ter
  apagado. Ver `40-review-r1.md § Achados fora de escopo`.

## Pendências / Decisions for a Human

> O que exige julgamento humano: trade-off de arquitetura, quebra de contrato, decisão de produto.

- **A M2 não fecha, e agora os dois números existem.** A r1 gastou **48 turnos** (teto 60 ✅) e
  **US$ 17,92** (teto 15 ❌, e 16% acima do que ela própria estimou em prosa). O laço de revisão da
  missão está em **US$ 40,92 (46%)** de US$ 88,94 contra o teto de US$ 40 — já estourado **antes**
  desta sessão, que o empurra mais. Registrado agora, antes de o resultado ser conhecido, para que
  ninguém reescreva o alvo depois. ⚠️ O que o número **também** diz: contra a missão de kit
  anterior (`20260831`, `review loop US$ 66,34 (50%)`), o desenho novo já derrubou o absoluto em
  38% e a parcela em 4 pontos — o teto foi errado por pouco, não por muito, e a M1 da janela 3
  continua sendo quem julga.
- **Fechar a janela cega do runner velho segue sendo decisão humana**, e esta rodada é a segunda
  prova de que ela morde: o prompt de boot que recebi ainda é o pré-`03187e8`. As duas formas
  (comparar o hash do `bin/sdd` na entrada e avisar, ou parar) têm preços diferentes e (a) pode
  reprovar missão em voo que está saudável. **Não bloqueia o pipeline.**
- **O carimbo de mutação está morto e o `R6`/`R7` o empurram mais para a frente.** Chave em disco
  `2d0cb366…`, recomputada `e11bb2cb…`. `gate_PR` o exige. A ordem continua sendo: achados →
  catraca do `TODO.md` → `./bin/sdd health`, **depois** do último commit de código — que agora será
  o do `R7`, não o do `R5`.
- **As pendências que EXEC, QA e r1 abriram seguem de pé:** a coluna "Depois" do `KAIZEN_LOG.md`
  (preenchida pela DOCS, e o achado #4 acima muda **duas** células para o formato dela) e quando
  abrir/fechar a janela 3 (no sha do merge, padrão D19).
