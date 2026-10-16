---
missao: 20261016-lote-9-o-papel-de-cada-palavra
titulo: a regra 2 do check-checkpoint lê o grep como o grep se lê — toda grafia de mescla da stderr entra na regra, só o padrão deve a âncora, e o grep contador de um par que espera só zeros sai dela
data: 2026-10-16
versao:
branch: fix/lote-9-o-papel-de-cada-palavra
aprovacao: humano-2026-10-16
adr: none
ddd: n/a
qa:
kaizen_log:
---

# Missão — o lote 9: o papel de cada palavra

> Escrito pelo `sdd-planner` com o humano presente (relay do `/sdd-plan`, 2026-10-16 02:39–08:18).
> É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão começa lendo
> estes dois.
>
> ⚠️ **Missão do próprio kit: executada INTERATIVA, no worktree ligado
> `/home/joruge/repos/sdd_agents-lote-9`, nunca por `sdd run` a partir do checkout principal**
> (ADR 0016 §2, `commands/sdd-plan.md` passo 2). Dentro do worktree, `health`, `preflight` e
> `install` rodam como `./bin/sdd`. O checkout principal `/home/joruge/repos/sdd_agents` é o kit que
> o `sdd` do PATH executa para os alvos: nada se escreve nele.

## Problema (Gemba)

O tema do humano foi "continuar a missão de analisar e tratar as issues abertas até zerar todas".
O espelho tem 14 issues (label `todo`) ↔ 14 itens no `TODO.md` (`bash tests/check-todo.sh` →
`14 finding(s) … every anchor on target`). Mas **o kit está congelado desde o merge do lote 7** (D11
de `20261012-a-rota-da-qa`, PR #252 `bad6168`): nada entra em `bin agents templates config` até o
veredito da janela do lote 7. `./bin/sdd kaizen --series` (2026-10-16 02:40) responde
`latest.kit_sha: bad6168`, `missions: 1`, `guard.floor: 3`, `sufficient: false`, `why: [floor]`,
`window_broken: false`; a missão paga é a `20261014-amep-entrada-em-dois-niveis` do
`lighthouse_project` (46 sessões, US$ 192,80). `git diff fec0cca..HEAD -- bin agents templates config`
está vazio. O eixo do juiz agrupa pelo último commit nesses quatro caminhos, então `tests/`, `docs/`,
`TODO.md` e a catraca não partem a janela (o lote 8 provou: mergeou e o `latest` seguiu `bad6168`).

Das 14 issues, **3 têm o conserto só em `tests/check-checkpoint.sh`**, todas na regra 2 (a que recusa
a Check que grepa a saída mesclada de um sensor sem a âncora `^  ok    `). Reproduzidas no HEAD
`9c13855` com checkpoints de fixture e `--check`:

- **#269 — a regra só vê a mescla escrita `2>&1`.** `bash tests/check-a.sh &> out.log; grep -c
  'alpha holds' out.log` → rc 0; `>&` e `&>>` também; a mesma Check com `> out.log 2>&1` → rc 1.
  Medido no bash 5.2.21: mesclam a stderr na stdout também `2>& 1`, `2>&1-`, `2<&1`, `2>&01`,
  `2>&"1"`, `2>&$x`, `&>f`, `&> f`, `&>>f`, `>&f`, `>& f` e `1>&f`. A regra hoje pega só 2 das 13
  grafias (`2>&1` e `2>&1-`). Falha aberta.
- **#270 — a regra não sabe o papel de cada palavra do grep.** `r2_grep_at`
  (`tests/check-checkpoint.sh:307`) guarda as palavras entre aspas numa lista solta (`R2_LITS`) e as
  opções em outra (`R2_BARE`), e `r2_grep_anchored` (`:412`) não sabe qual palavra é padrão, argumento
  de opção ou arquivo. Passam com rc 0, todas cegas no GNU grep 3.11 (`/usr/bin/grep`):
  - `grep --label='^  ok    x' -H -c 'caso' <<< "$o"` (o rótulo conta como padrão; imprime
    `^  ok    x:1` sobre `  FAIL  caso`);
  - `grep -c -e 'caso' '^  ok    x' <<< "$o"` (o FILE conta como padrão);
  - `grep '-v' -c '^  ok    x' <<< "$o"` e `grep "-F" -c '^ ✓ caso' <<< "$o"` (opção entre aspas
    não é lida como opção) — achado no gemba deste plano;
  - `grep --fixed-regexp -c '^ ✓ caso' <<< "$o"` (o GNU grep tem esse sinônimo de `-F`) e
    `grep -cz '^  ok    a.*b' <<< "$o"` (com `-z` o `.*` atravessa linhas: `1` sobre
    `  ok    a` + `  FAIL  b`) — achados no gemba deste plano.

  E falham fechado, por acidente: `grep -c ^\ \ ok\ \ \ \ x <<< "$o"` (padrão ancorado escrito com
  escape) é recusado, e `grep -c -- '^  ok    x' grep <<< "$o"` também, porque o FILE chamado `grep`
  conta como um segundo grep.
- **#272 — a regra recusa o grep de esperado `0` na saída mesclada de um build.** A I8 da LH-4
  (`lighthouse_project/docs/handoffs/20260927-idioma-da-spa-pelo-idp/checkpoint.md:37`) tem o par
  `` `b=$(npm run build -w packages/frontend 2>&1); grep -ci 'chunks larger than' <<< "$b"` → `0` ``,
  recusado. Um `grep -c` de esperado `0` só fica verde se nenhuma linha casar, então nunca fica verde
  sobre uma linha `FAIL` que o padrão casa. Falha fechada, com consumidor fora da suíte (D15).

O alcance hoje, pelo comando de leitura só do `01-plano.md` (§ Contexto): o `--check` sobre os 36
checkpoints dos dois alvos recusa **114** células pela regra 2 (16 no `lighthouse_project`, 98 no
`sales_quote`), **2** delas na LH-4 (a I8 do zero e a I9, que lê `^Total:` e continua recusada).

As outras 11 issues tocam `bin/`, `agents/` ou `templates/` e esperam o veredito (decisão 1).

## Métrica

- **M1 (#269):** as 13 grafias de mescla do gemba põem a célula sob a regra (hoje 2 de 13); as 6
  grafias que não mesclam (`&>/dev/null`, `&>>/dev/null`, `>&/dev/null`, `>&2`, `1>&2`, `2>&-`)
  continuam fora. Uma linha nova `ok    rule: every spelling that merges stderr into stdout puts the
  cell under the anchor rule` (0 hoje, 1 depois). As recusas nos alvos **não sobem** com o I1: 114 → 114
  (as Checks do `lighthouse_project` que usam `&>/dev/null` não entram na regra).
- **M2 (#270):** os 6 fail-opens acima recusados (hoje 0 de 6) e os 2 fechados acima aceitos (hoje 0
  de 2). Duas linhas novas `ok    rule:` (a palavra e o papel), 0 hoje e 1 cada depois.
- **M3 (#272):** a I8 da LH-4 aceita; a LH-4 vai de **2** recusas para **1** (a I9). O total nos alvos
  sai de 114; o protótipo descartável do planner prevê **103** (11 células inteiras liberadas, 25 com
  pelo menos um grep liberado). O número de depois é o do sensor real, medido no fecho e escrito no
  `KAIZEN_LOG.md`. Os controles continuam recusados: o par de esperado misto (`3 0`), o `-v`, o `-q`,
  o `-m`, o grep dentro de `$(…)` e o grep com a stdout redirecionada. Uma linha nova `ok    rule: a
  counting grep whose pair expects only zeros owes no anchor` (0 hoje, 1 depois).
- **M4 (sem regressão):** a varredura do kit continua limpa (`ok    no checkpoint Check reads a red
  assertion as green`, hoje `193 cell(s) under the rule, 257 row(s) in 30 file(s)` antes desta missão
  ganhar o seu `checkpoint.md`; 197 cells e 31 arquivos com ele); todos os probes de hoje mantêm o rc
  (quatro fixtures trocam só o esperado, no I4); `RULE_FLOOR` 4 → 8 e `PROBE_FLOOR` igual à contagem
  real (128 hoje).
- **M5 (o fecho):** os 3 itens carregam `RESOLVED by <hash>`, o #271 ganha uma linha, a catraca
  `tests/health-baseline.txt` é igual à contagem do `check-todo.sh --count`, e a entrada do
  `KAIZEN_LOG.md` cita o id inteiro da missão.

## Resultado esperado

A regra 2 do `tests/check-checkpoint.sh` lê o shell e o grep como eles se leem: toda grafia que mescla a
stderr na stdout põe a célula sob a regra, e uma mescla para `/dev/null` não. Cada grep é lido palavra
por palavra, pelo valor (aspas e escapes removidos), e o argv pelo getopt_long com a tabela do GNU grep
3.11, então só o padrão deve a âncora, e toda opção que desarma o `^` (`-F` em qualquer grafia, `-v`,
`-z`, `-X fgrep`, `-f`) desarma. O `grep -c` de um par `` `cmd` → `0` `` deixa de dever âncora. O backlog
sai de 14 para 11 itens depois do chore pós-merge, todos congelados e com dono na triagem do `sdd kaizen`.

## Fora de escopo

- **Os 11 itens congelados** (#255, #256, #259, #260, #261, #262, #263, #265, #266, #271 e #273): vão
  para a triagem do `sdd kaizen` depois do veredito (decisão 1). O #271 só ganha uma linha de texto
  (decisão 6), não conserto.
- **O par de esperado misto** (`echo "$a $b"` → `3 0`): continua recusado, como limite declarado no
  cabeçalho do sensor (decisão 3). Seguir o `$(…)` até o `echo` seria fazer o leitor crescer de novo.
- **A mescla por um terceiro descritor** (`3>&1 2>&3`), a ordem de `>/dev/null 2>&1` (que hoje já põe a
  célula sob a regra, fechado) e `>&`/`&>` dentro de aspas (lido como mescla, fechado): limites
  declarados no cabeçalho, sem conserto.
- **Uma palavra dinâmica (`"$l"`, `$f`) em posição de FILE**: lida como operando, como hoje; o valor
  dela poderia ser uma opção. Limite declarado, porque o controle do kit (`grep -c '^  ok    x' "$l"`,
  F1 de 2026-08-16) tem de continuar aceito.
- **O carimbo de mutação:** não roda nesta missão. O humano decidiu no PR #267 que o `sdd health` só
  roda quando a catraca das issues zerar, e esta missão a deixa em 11.
- **Sincronizar o espelho de issues e apagar os itens resolvidos:** chore pós-merge, do humano, da
  `main`.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 7 decisões com a sua linha `- answer:` (1–6 e 8), mais a instrução do humano sobre o `TODO.md` (7); os 11 itens congelados têm dono (triagem do `sdd kaizen`) |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 ✅ abaixo; DDD `n/a` (um sensor de markdown, sem domínio) |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | o I1 nomeia as três linhas, a função, os fixtures, a linha `ok` e os pisos; ver `01-plano.md` § Teste de autocontenção |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 5 de 5 vermelhos no HEAD; `--check` rc 0 e `--red` rc 0 (antes de cada Check no `01-plano.md`) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh`) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`, decisão 6: só `tests/`, reversível num commit, o porquê no cabeçalho do sensor |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | os três defeitos e quatro membros novos da família reproduzidos em fixture no HEAD; as grafias de mescla medidas no bash 5.2.21; a tabela de opções medida no `/usr/bin/grep` 3.11; o `--check` rodado sobre os 36 checkpoints dos alvos |
| K2 | Problema declarado com métrica | ✅ | M1–M5, cada uma com número de antes |
| K3 | Desperdícios identificados e cortados | ✅ | a heurística de seis rodadas (PR #267) vira um modelo com tabela; o contorno dos alvos (`2>/dev/null` no build) deixa de ser preciso |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 5 incrementos, uma linha `ok    rule:` por fatia, cada Check vermelho no HEAD |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | toda Check lê a linha `ok` do sensor ancorada em `^  ok    `, ou o arquivo |
| K6 | Jidoka — o que para a linha está definido | ✅ | selftest vermelho (rc 90–92) para a suíte; `PROBE_FLOOR` e `RULE_FLOOR` apertados; `tests/run-all.sh` no fecho; a regra de parada da revisão (decisão 4) |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | probes duráveis no selftest da suíte rápida; o cabeçalho do sensor declara os limites; a prosa congelada vai para o #271 (decisão 6) |
| K8 | Registro no KAIZEN_LOG | ✅ | entrada no fecho (I5), com os números remedidos pelo sensor real (decisão 6) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: a missão muda um sensor de markdown (`tests/check-checkpoint.sh`) e o
texto de três itens do `TODO.md`. Nenhum aggregate, contexto, evento ou contrato entre módulos.

## Decisões do grill (não re-litigar)

1. **O lote 9 leva só os três de `tests/`: #269, #270 e #272.** Os 11 que tocam `bin/`, `agents/` ou
   `templates/` esperam o veredito da janela do lote 7 e a triagem do `sdd kaizen`. Por quê: não parte a
   janela (1 de 3, US$ 192,80 pagos), segue a decisão 1 do lote 8, e o conserto do #272 chega ao planner
   do L5 do `sales_quote`, que pode retomar em paralelo e encher a janela.
   - answer: (recommended)
2. **O #270 se conserta lendo o argv do grep como o getopt_long.** Um tokenizador de palavras do shell
   (aspas, escape, partes coladas) e, sobre ele, a tabela de opções do GNU grep 3.11 copiada do
   `--help` com proveniência: prefixo de opção longa, `--`, opções em qualquer posição, o primeiro
   operando como padrão quando não há `-e`, os demais como arquivos. A âncora é cobrada só dos padrões;
   o que o leitor não souber classificar é recusado. Por quê: é a direção do item e a lição do lote 8
   (parar de remendar e modelar o estado que falta, a palavra e o papel dela).
   - answer: (recommended)
3. **A exceção do #272 vale por par.** O grep contador (`-c` sem `-v`) de um par `` `cmd` → `esperado` ``
   cujo esperado é só zeros (`0`, `0 0`) não deve âncora; o esperado misto (`3 0`) continua recusado, como
   limite declarado. Por quê: fecha o consumidor medido (a I8 da LH-4, 11 das 114 recusas pelo protótipo)
   sem seguir variável nenhuma. O `01-plano.md` (I4) escreve as condições que fazem o zero ser a contagem
   do grep, e não outra saída.
   - answer: (recommended)
4. **A revisão do PR para na rodada limpa, com escopo fechado e uma válvula na 4ª.** Achado de bot que
   cai num dos três itens e cabe no modelo (uma linha da tabela de opções, uma grafia de mescla, um caso
   do par de zeros) é consertado no PR; achado de classe nova (outro estado, ou fora dos três itens) vai
   ao `TODO.md` com a catraca; a partir da 4ª rodada todo achado vai ao `TODO.md` e o humano decide o
   merge. Por quê: segue a regra da casa e evita que as seis rodadas do PR #267 virem padrão, sem deixar
   fail-open calado.
   - answer: (recommended)
5. **O id é `20261016-lote-9-o-papel-de-cada-palavra`, branch `fix/lote-9-o-papel-de-cada-palavra`**,
   sem upstream. Por quê: nomeia o núcleo da decisão 2, de que o #272 depende.
   - answer: (recommended)
6. **`adr: none`, K8 ✅ e o #271 ganha uma linha.** A entrada do `KAIZEN_LOG.md` vai no fecho, com os
   números remedidos pelo sensor real; o #271 (a prosa congelada mais estrita que os sensores) ganha uma
   linha, sem mudar o título, nomeando as regras novas do lote 9. Por quê: só `tests/`, reversível num
   commit, e o precedente do mesmo sensor foi `none` (decisão 9 do lote 8); a triagem recebe a prosa
   completa num item só.
   - answer: (recommended)
7. **Instrução do humano, dada no meio do grill: "sempre que alterar a estrutura do Todo.md, consulte
   antes a /todo-to-github-issues".** Antes de qualquer edição no `TODO.md` — reancorar, pôr o
   `RESOLVED by`, acrescentar a linha do #271, registrar achado novo —, o executor invoca a skill
   `todo-to-github-issues` (ferramenta `Skill`) e segue o formato dela; depois da edição roda o
   `--audit` dela, que só lê. Nunca `--apply` da branch da missão, e nunca muda o título de um item
   (a chave do espelho é o título).
8. **As duas leituras do gemba valem.** (a) Na decisão 2, "padrão vindo de variável" é o padrão cujo
   **começo** é uma expansão (`"$p"`, `$p`): esse é recusado; o padrão com a âncora literal antes da
   expansão (`"^  ok    $k finding(s)"`, escrito em `20261003-lote-3-a-catraca-desce` I20 e em
   `20261002-onde-o-comando-do-humano-escreve` I10) continua ancorado, com limite declarado. (b) Na
   decisão 3, a isenção exige o grep no topo do comando do par, a stdout dele não redirecionada, padrões
   literais e toda opção numa lista positiva (sem `-q`, `-m`, `-F`, `-f`, `-z`); quatro fixtures de hoje
   com esperado `0` por acaso trocam só o esperado. Por quê: ao pé da letra, (a) deixaria a varredura do
   kit vermelha em 2 checkpoints fechados, e (b) abriria quatro fail-opens novos (`-qc …; echo 0`,
   `-m 0`, contagem capturada, stdout redirecionada) dentro do próprio conserto; o protótipo dá as mesmas
   11 células liberadas com as condições.
   - answer: (recommended)

## Pendências para o humano

1. **O PR e a revisão (decisão 4).** `git push -u origin HEAD`, o PR com o corpo do `templates/pr-body.md`,
   `@codex review` num comentário (neste repo o Codex só revisa a pedido) e o `local/ci` pela API de
   Statuses só com a suíte rodada naquele sha. A parada é a rodada limpa; a válvula é a 4ª.
2. **Sem carimbo.** Pela decisão do humano no PR #267, o `./bin/sdd health` não roda nesta missão (a
   catraca fica em 11, não zera). O merge é por merge commit, nunca squash.
3. **O pull ocioso.** Depois do merge no GitHub, `git -C /home/joruge/repos/sdd_agents pull --ff-only`
   só quando `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vier vazio (decisão 2 do lote 8).
   Sem o pull o conserto não chega ao planner de nenhum alvo, que roda o `check-checkpoint.sh` pelo
   caminho do checkout principal.
4. **O chore pós-merge, da `main`, com a `todo-to-github-issues`.** Apagar os 3 itens com `RESOLVED by`
   (prova: `git merge-base --is-ancestor <hash> main`), descer a catraca de 14 para 11 e sincronizar o
   espelho (plano → `--apply` → `--close-orphans`). Isso fecha #269, #270 e #272 e atualiza o texto do
   #271 (`UPDATE (text)`).
5. **A triagem depois do veredito** recebe 11 itens, todos congelados.
