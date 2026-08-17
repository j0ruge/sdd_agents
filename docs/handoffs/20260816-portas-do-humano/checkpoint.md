---
missao: 20260816-portas-do-humano
atualizado: 2026-08-17 00:37
---

# Checkpoint — as portas de controle do humano

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`. O `gate_EXEC` reprova por "invalid status" e o
> `sdd status` imprime algo de aparência saudável — custou uma missão inteira até alguém olhar.
> Check que precisaria de pipe vira herestring: `` o=$(cmd 2>&1); grep -c 'x' <<< "$o" ``.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> Todo sensor da suíte imprime `  ok    <asserção>` na **stdout** e `  FAIL  <asserção>` na
> **stderr**, com o *mesmo* `<asserção>`. Um Check que faz `2>&1` e grepa o texto solto devolve o
> mesmo número com a asserção verde e com ela vermelha: ele responde "a asserção existe", nunca
> "a asserção passou". Custou uma missão inteira, achado só na fase QA. A forma certa:
> `` o=$(bash tests/check-x.sh 2>&1); grep -c '^  ok    <asserção>' <<< "$o" `` → `1`.
> O sensor é `tests/check-checkpoint.sh`.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | `sdd approve`: o gate humano ganha comando | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve' <<< "$o"` → `3` | done | 96a1f68 |
| I2 | o runner troca para a branch declarada | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    branch ' <<< "$o"` → `3` | done | b3b8c2f |
| I3 | `sdd retry` vira a quarta porta com aviso | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    retry ' <<< "$o"` → `2` | done | 3ffa586 |
| I4 | plano kaizen-born nunca se auto-aprova | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    kaizen-born' <<< "$o"` → `3` | done | 2510c3c |
| F1 | `sdd approve` destrava o plano kaizen-born que o próprio gate manda ele destravar | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    approve resolves' <<< "$o"` → `1`, e a jornada re-andada: `./bin/sdd health` → verde nos 5 checks | done | 5c3d118 |
| F2 | `sdd approve` é a quinta porta que commita: avisa a branch base como as outras quatro | `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    approve warns' <<< "$o"` → `1`, e a jornada re-andada: `./bin/sdd health` → verde nos 5 checks | done | 88ae514 |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-16 21:15 · `PLAN` · os 4 Checks rodados contra o HEAD (`c2c8e73`): todos `0`
  (vermelhos), `tests/check-gates.sh` verde (rc 0) — nenhum Check nasce verde.
- 2026-08-16 21:15 · `PLAN` · prefixos de asserção são contrato com os Checks: `sdd approve `,
  `branch `, `retry `, `kaizen-born` — nomear exatamente assim em `tests/check-gates.sh`.
- 2026-08-16 · `I1` · **desvio da decisão 2 do grill, deliberado:** o assunto do commit do
  `sdd approve` é `chore(missao): plan <missão> approved by the human` (inglês, escopo `missao`
  mantido), não a frase pt-BR do `00-missao.md`. O runner é superfície do kit e roda em repo de
  qualquer `OUTPUT_LANG`, e aqui é o único escritor — não há sessão para escrever no idioma alvo.
  Além disso `pelo` está na lista de stopwords do `tests/check-lang.sh`, que mede o `bin/sdd`: a
  frase original é insatisfazível ali. Quem depender do assunto exato (I2/I3/I4, DOCS, PR) leia
  esta linha antes de "corrigir".
- 2026-08-16 · `I1` · o comando imprime o **corpo inteiro** da missão, não seção por seção: os
  headings (`## Pendências para o humano`) são conteúdo em `OUTPUT_LANG`, e um runner que os
  grepasse funcionaria só em repo pt-BR. O fixture do sensor, por isso, não precisa dos headings
  pt-BR — quem guarda esse contrato é o `tests/check-templates.sh`.
- 2026-08-16 · `I1` · passada de sabotagem adversarial: **11 degradações, 10 vermelhas** pela
  asserção pretendida (resposta ignorada, commit varrendo a árvore, sem idempotência, `sed` no
  arquivo inteiro, corpo/incrementos/`titulo:` não impressos, gate ignorando `humano-*`, sem
  `git add`). A 11ª — remover a guarda de read-back — sobrevive verde e está no `TODO.md`.
- 2026-08-16 · `I2` · **o placeholder que o plano cita não existe.** `00-missao.md` (decisão 6) e
  `01-plano.md` dizem `<criada pela fase TICKET>`; `templates/missao.md:6` ship `<nome da branch
  de trabalho>`, e `grep -r` não acha a primeira em lugar nenhum do kit. A guarda casa `'<'*`,
  então cobre as duas — mas o fixture agora **lê** o placeholder do template, e foi ler que achou.
  Quem for escrever fixture nesta missão: copie da fonte, não da prosa do plano.
- 2026-08-16 · `I2` · `templates/missao.md` entrou no commit do incremento, fora do "Onde" do
  plano (que dizia só `bin/sdd`): o campo `branch:` deixou de ser decorativo e virou carga lida
  pelo runner, e contrato de artefato muda nos três lugares no MESMO commit (regra do `CLAUDE.md`).
  **Sobra para a fase DOCS:** `docs/pipeline.md` não documenta o campo em lugar nenhum — não é
  drift criado aqui, mas agora é drift que importa.
- 2026-08-16 · `I2` · o sensor tem **5** asserções, e só 3 levam o prefixo `branch ` que o Check
  conta. As outras duas (checkout recusado ⇒ `die`; `sdd retry` como segundo call site) nasceram
  da sabotagem e são nomeadas fora do prefixo de propósito: `branch ` e `retry ` são os Checks
  deste incremento e do I3, e asserção que infla a contagem do vizinho transforma contrato em
  coincidência.
- 2026-08-16 · `I2` · passada de sabotagem: **21 degradações em 3 rodadas**, parando na rodada que
  não achou nada. As 2 sobreviventes da r1 viraram asserção (`die`→`warn`, a pior: o run SEGUE, que
  é a classe SQ-97; e a linha BRANCH do `pipeline.log`). A r2 achou um **fail-open no que a r1
  tinha acabado de consertar**: sem a asserção positiva do anúncio, a de "no-op silencioso" fica
  verde num runner que nunca anuncia nada — par presente/ausente, nunca só a ausência.

- 2026-08-16 · `I3` · a chamada entra **depois** de `ensure_mission_branch`, não "no início de
  `cmd_retry`" como o `01-plano.md` diz — espelha a ordem já decidida no `cmd_run` (`bin/sdd:1865`)
  e pelo mesmo motivo: o checkout é quem decide onde o retry commita, então avisar antes grita lobo
  para um humano que o runner tira da base na linha seguinte. Não é desvio de intenção, é a mesma
  regra aplicada ao segundo call site.
- 2026-08-16 · `I3` · passada de sabotagem: **10 degradações em 4 rodadas**, parando na rodada sem
  achado novo. 3 sobreviventes. Duas viraram asserção no mesmo commit — aviso **duplicado** (o par
  diferencial remove TODAS as cópias da linha antes de comparar, então "pelo menos um" passava) e
  aviso **antes** do checkout (indistinguível num fixture que não declara `branch:`). A terceira é
  a mesma inversão de ordem no `cmd_run`: vizinha, fora do escopo, foi para o `TODO.md`.
- 2026-08-16 · `I3` · o sensor tem **3** asserções e o Check conta **2**: a da ordem é nomeada fora
  do prefixo `retry ` de propósito, como as duas do I2 fora de `branch `. Prefixo é contrato com o
  Check; asserção que infla a contagem transforma contrato em coincidência.
- 2026-08-16 · `I3` · a mutação `RETRY_base_branch_warn_dead` sabota o **call site**, exceção
  deliberada à regra da casa ("sabote a definição"): o defeito desta fatia É o call site ausente, e
  a definição já tem `RUN_base_branch_warn_dead`. O `sed` é endereçado ao corpo de `cmd_retry` —
  depois deste commit a linha `  warn_if_on_base_branch` aparece **4×** e um `sed` sem endereço
  mataria as quatro, creditando esta entrada pelo que a outra quebrou. Score 46 → 47, `0 known gaps`.

- 2026-08-16 · `I4` · o marcador kaizen-born é lido **por missão** (`$MISSION_DIR/05-verdict.md`),
  nunca por repo. A sabotagem construiu a versão que pergunta `ls $HANDOFF_DIR/*/05-verdict.md` e
  ela passou por **todas** as asserções: recusaria todo plano `auto` em qualquer repo que já tenha
  rodado `sdd kaizen` — o próprio kit, para começar. Quem a mata é uma missão **irmã**, `auto` e sem
  verdict, lida depois de o verdict existir. Ausência sozinha não distingue escopo.
- 2026-08-16 · `I4` · **o slug do fixture entregava a agulha.** Com a missão chamada
  `20260106-kaizen-born`, a asserção `grep 'kaizen-born'` era satisfeita pelo nome que a própria
  recusa imprime (`run 'sdd approve <missão>'`) — degradar a mensagem para largar a palavra ficava
  verde. Fixture não pode carregar no slug a palavra que o probe procura na saída do runner; os dois
  foram renomeados (`20260106-selfapproved`, `20260106-planner-written`).
- 2026-08-16 · `I4` · passada de sabotagem: **27 degradações em 4 rodadas**, parando na rodada sem
  achado novo. 2 sobreviventes, as duas acima, ambas viraram asserção. A rodada 3 (10 mutantes) e a
  4 (4 mutantes frescos: `GATE_WHY` não escrito, teste invertido, marcador exigindo tamanho, guarda
  antes do `case`) morreram todas.
- 2026-08-16 · `I4` · o `docs/pipeline.md` **não tem seção para o `sdd approve`** — a prosa nova cita
  o comando em texto, não em link, porque a âncora não existe. **Sobra para a fase DOCS**, junto com
  o campo `branch:` que o I2 já anotou: os dois comandos/campos novos desta missão precisam de casa
  na superfície de comandos do `pipeline.md`.

- 2026-08-16 · `QA` · **as quatro jornadas foram andadas na linha de comando** num clone real
  (`/tmp/qa-portas/clone`), com stub de `claude` e `TEST_CMD="true"`, nunca em fixture de sensor.
  Verde: approve (preview, `n`, `y`, idempotência, stdin fechado, árvore suja, chave ausente),
  troca de branch (dry-run não troca, inexistente criada da atual, existente checkout, placeholder
  no-op, git recusa ⇒ `die` sem gastar sessão), retry (avisa na base, silencia fora, honra a branch,
  avisa **depois** do checkout) e kaizen-born (auto+verdict recusa, auto sem verdict passa,
  `humano-*`+verdict passa). Os dois achados abaixo saíram das costuras ENTRE incrementos, que
  nenhum sensor de incremento mediu.
- 2026-08-16 · `QA` · **F1 nasce do achado "o remédio que o gate nomeia não existe"** (§Achados do
  `30-handoff-qa.md`). `gate_PLAN` recusa `auto`+verdict e manda `run 'sdd approve <missão>'`;
  `cmd_approve` (`bin/sdd:1774`) lê `auto` como "already approved — nothing to do" e volta 0 sem
  escrever. Os conjuntos são **aninhados**, não sobrepostos: o gate só recusa quando o valor é
  `auto`, e `auto` é exatamente o que faz o approve desistir — o remédio nunca funciona, não é
  "às vezes". Andado: `sdd why`, `sdd status` (2×) e `sdd run` imprimem a instrução; obedecê-la
  deixa `aprovacao: auto` e a fase em PLAN. Saída só editando o frontmatter à mão, que é a falha
  que esta missão existe para matar.
- 2026-08-16 · `QA` · **F2 nasce do achado "a quinta porta commita em silêncio"**. `cmd_approve`
  commita e não chama `warn_if_on_base_branch`; o comentário da definição (`bin/sdd:1271`) enumera
  "the four doors that can end up committing" e o approve, escrito na MESMA missão, é a quinta.
  Andado: de pé na base, `sdd approve` deixou `chore(missao): plan … approved by the human` na
  branch base sem uma palavra — a classe SQ-97, reaberta pela porta nova.
- 2026-08-16 · `QA` · **por que o I4 passou verde com o remédio morto:** a última asserção
  kaizen-born do `tests/check-gates.sh` alcança o estado aprovado com `sed -i`. Simular o remédio
  prova que o **gate aceita** o que o comando escreveria, nunca que o **comando chega lá** — e o
  comentário dessa asserção já dizia, por escrito, "unrunnable FOREVER, `sdd approve` included".
  A asserção nova invoca o remédio que o runner imprime, em vez de imitá-lo.
- 2026-08-16 · `QA` · a asserção do F1 é **par diferencial** de propósito: `auto`+verdict tem de ser
  destravado E `auto` sem verdict tem de continuar recusado. Sem a segunda metade o conserto mais
  barato é tirar `auto` do `case` de bail — medido: essa sabotagem deixa a asserção **vermelha**,
  como tem de ficar. Um approve que reescreve todo `auto` em `humano-<hoje>` apagaria a procedência
  do PLAN-AUTO em silêncio.
- 2026-08-16 · `QA` · **enquanto F1/F2 estiverem `pending` o `check-mutation.sh` reporta
  `HARNESS-BROKEN` e sai 1** — é a guarda de controle dele (`tests/check-mutation.sh:653`), que
  recusa pontuar quando a cópia sem sabotagem já está vermelha. É comportamento desenhado, não um
  terceiro bug: sem ela o score leria 48/48 por vacuidade. Volta a pontuar quando os dois fixes
  fecharem.
- 2026-08-16 · `QA` · prefixos novos são contrato com os Checks e foram escolhidos para **não**
  inflar os vizinhos: `approve resolves` e `approve warns` não casam `^  ok    sdd approve`. Medido
  depois de escrever as asserções — os quatro Checks do EXEC continuam 3/3/2/3.

- 2026-08-16 · `F1` · a condição virou `plan_approves_itself` (`bin/sdd:316`), lida pelo `gate_PLAN`
  e pelo `cmd_approve`. Não é refactor de gosto: o defeito ERA dois pontos lendo a mesma regra e
  discordando, então deixar a segunda leitura restatada em linha reabriria a mesma porta na próxima
  vez. Sem verdict, `auto` continua sendo "already approved" — o conserto preguiçoso (tirar `auto`
  do `case`) reescreveria toda aprovação do planner em `humano-<hoje>` e apagaria a procedência.
- 2026-08-16 · `F1` · **a asserção do QA ganhou uma cláusula, não uma vizinha.** A sabotagem achou
  que remover o aviso deixava o approve trocando um `auto` commitado por `humano-<hoje>` em
  silêncio, com todas as outras cláusulas verdes. Virou `grep 'born of sdd kaizen'` exigido presente
  no lado kaizen-born e AUSENTE no irmão sem verdict — dentro da asserção existente, para o Check
  seguir contando 1. Medido depois: os quatro Checks do EXEC continuam 3/3/2/3.
- 2026-08-16 · `F1` · passada de sabotagem: **17 degradações em 4 rodadas**, parando na rodada sem
  achado novo. 1 sobrevivente real (o aviso, acima). Três degradações sobrevivem à asserção do F1 e
  morrem em OUTRA da suíte — commit pulado, remédio não nomeado, idempotência de `humano-*` — e
  isso é escopo certo, não buraco: são território do I1 e do I4.
- 2026-08-16 · `F1` · ⚠️ **a rodada 1 estava ancorada em número de linha e media as linhas erradas.**
  O probe "remove o aviso" apagava a segunda linha do aviso e o `;;`, deixando viva a linha que o
  grep procura, e devolvia "sobrevive" sem ter testado a regra. Probe de sabotagem ancora em CÓDIGO,
  exatamente como o cabeçalho do `check-mutation.sh` já manda — e conclusão de probe vacuoso não
  vale, nem quando por acaso aponta para o lado certo. Rodadas 3 e 4 refeitas ancoradas.
- 2026-08-16 · `F1` · mutação **48 → 49**. `RUN_approve_bails_on_kaizen_born` sabota o call site —
  2ª exceção deliberada à regra "sabote a definição", pelo motivo declarado do
  `RETRY_base_branch_warn_dead`: o defeito É o leitor que não consulta a condição, e
  `PLAN_kaizen_born_blind` (reancorada na definição compartilhada) já cega os dois leitores de uma
  vez. As duas foram medidas **à mão** em sandbox — `check-mutation.sh` recusa pontuar enquanto o
  F2 mantiver a cópia de controle vermelha, e essa recusa é a guarda dele, não um bug.
- 2026-08-16 · `F1` · **a segunda metade do Check (`sdd health` verde nos 5 checks) é insatisfazível
  enquanto o F2 estiver `pending`**, por construção: a asserção do F2 mantém a suíte vermelha e o
  `check-mutation.sh` no `HARNESS-BROKEN` que a própria QA registrou como desenhado. Em vez de
  carimbar um verde que não existe, a jornada foi **re-andada à mão** num clone real
  (`/tmp/f1-walk/clone`): plano kaizen-born com `auto` ⇒ `sdd why` recusa nomeando o remédio ⇒
  `sdd approve` (com `y`) grava `humano-2026-08-16` e commita 1 arquivo ⇒ `sdd why` responde
  `EXEC: 1 of 1`. O laço infinito fechou. A sessão do F2 re-mede as duas metades.
- 2026-08-16 · `F1` · e o `sdd health` tem um defeito **próprio**, pré-existente (conferido em
  `HEAD` sem este diff): com a suíte vermelha ele morre mudo na primeira linha, porque
  `out="$( … run-all.sh )"` sob `set -e` mata o script antes do `health_bad "suite red"`. Fora do
  escopo desta missão, registrado no `TODO.md` — quem for medir o Check do F2 não se assuste.

- 2026-08-17 · `F2` · a chamada entra **no bloco do prompt**, não no topo do comando como nas outras
  quatro portas — desvio deliberado da frase "no início de `cmd_approve`" do texto do F2. Só este
  comando imprime a missão inteira antes de perguntar: um aviso no topo teria rolado para fora da
  tela na hora da decisão, e a regra que as outras enunciam ("à frente do que possa rolar a tela")
  lida num comando que pergunta vira "no fôlego antes da decisão". Fica **depois** do bail de
  idempotência pelo segundo motivo que aqueles comentários dão: aviso em caminho que não commita é
  o lobo que ensina a não ler avisos.
- 2026-08-17 · `F2` · a asserção da QA ganhou **três cláusulas, não três vizinhas** (mesma escolha
  do F1, e pelo mesmo motivo: o Check conta 1). Uma por sobrevivente da sabotagem — **ordem** (o
  aviso antes da pergunta; movê-lo para depois do `read` deixava as duas cláusulas antigas verdes e
  o humano sabendo da branch depois de já ter respondido), **contagem** (exatamente um, a regra que
  o par do `retry ` já cobrava) e uma **terceira invocação com o checkpoint ilegível** (a sabotagem
  pôs a chamada dentro do braço `if [ -n "$rows" ]` e tudo ficou verde, porque o fixture satisfazia
  a condição alheia). Medido depois: os Checks seguem 3/3/2/3/1/1.
- 2026-08-17 · `F2` · ⚠️ **a rodada 1 da sabotagem produziu quatro probes vazios e um "sobrevivente"
  que não existia.** `perl -0pe 's/^  warn_if_on_base_branch\n//m'` sem `/g` casa a PRIMEIRA
  ocorrência do arquivo, que é a do `cmd_preflight` — os probes removiam a chamada da porta errada e
  concluíam que a de `cmd_approve` sobrevivia. Mesma família da lição do F1 (probe ancorado em linha
  mede as linhas erradas). A saída foi um probe que **prova ter mudado o bloco do `cmd_approve`**
  antes de a conclusão valer; sem essa guarda, quatro conclusões falsas teriam virado asserção.
- 2026-08-17 · `F2` · passada de sabotagem: **26 degradações em 5 rodadas**, parando na rodada sem
  achado novo. 3 sobreviventes reais viraram cláusula. **2 sobrevivem de propósito e são controle:**
  mover a chamada para o topo do `cmd_approve` ou uma linha acima das `dim` continua correto, e uma
  asserção que as matasse estaria medindo estilo, não a propriedade.
- 2026-08-17 · `F2` · mutação **49 → 50**. `APPROVE_base_branch_warn_dead` sabota o call site — 3ª
  exceção deliberada à regra "sabote a definição", pelo motivo já declarado no
  `RETRY_base_branch_warn_dead`. O `sed` é endereçado ao corpo do `cmd_approve`: a linha
  `  warn_if_on_base_branch` aparece agora **5×** e um `sed` sem endereço mataria as cinco. Medido:
  o mutante mata **só** a asserção do F2 (77 `ok`, 1 `FAIL`).
- 2026-08-17 · `F2` · o `HARNESS-BROKEN` do `check-mutation.sh` **liberou-se sozinho** ao fechar o
  F2, exatamente como a QA previu: `score: 50 caught, 0 known gap(s), of 50`, suíte verde e
  `./bin/sdd health` verde nos 5 checks — as duas metades dos Checks do F1 e do F2 agora são
  medidas, não carimbadas.

- 2026-08-17 00:37 · `EXEC` · **sessão sem incremento: a fase foi rederivada por engano.** Nenhuma
  linha estava `pending` e nenhuma mudou de status aqui. O runner abriu EXEC porque `gate_EXEC` roda
  o `TEST_CMD` sobre o **working tree** (`bin/sdd:426`) e a árvore estava suja: a sessão da REVIEW
  morreu depois de escrever a rodada inteira e antes de commitar. `sdd why` respondia
  `EXEC: TEST_CMD failed` com os seis incrementos `done`. Antes de tocar em nada, medido num clone
  limpo do HEAD (`274ee45`): `suite green`, `52 caught, 0 known gap(s), of 52` — **nenhum incremento
  quebrado**, por isso nada foi marcado `blocked`. O vermelho era de outra fase, não de uma fatia
  daqui.
- 2026-08-17 00:37 · `EXEC` · o vermelho tinha **uma** causa: SC2010 (`ls "$AMDIR" | grep -c .`) numa
  linha que a própria rodada da REVIEW acrescentara — o passo de lint da suíte cobre `tests/*.sh`.
  Virou glob (`( "$AMDIR"/* )`), medido equivalente antes de trocar: 3 no diretório limpo, 4 com um
  `00-missao.md.aBc123` ao lado (a pegada do `mktemp`, que é o que a asserção existe para pegar) e 1
  no diretório vazio sem `nullglob`, que também não é 3 — falha fechado. Commit `7f9e660`.
- 2026-08-17 00:37 · `EXEC` · **descartar a árvore suja teria sido o conserto caro.** A rodada em voo
  carregava o achado que as cinco asserções de branch não conseguiam enxergar: o fixture nunca dava
  `git add` nos artefatos, e nesse regime `git checkout` não pode removê-los — a família inteira
  concordava sobre uma propriedade que nenhuma delas podia ver (regime do fixture ≠ propriedade,
  `CLAUDE.md`). Preservada, com a mutação `RUN_branch_orphan_blind`: score **52 → 53**, `0 known
  gaps`. Os seis Checks foram remedidos **depois** do commit e seguem `3/3/2/3/1/1`; `./bin/sdd
  health` verde nos 5 checks.
- 2026-08-17 00:37 · `EXEC` · **o que esta sessão NÃO fez, de propósito:** não escreveu
  `40-review-r2.md`. O artefato é da fase REVIEW e o `gate_REVIEW` é quem o cobra — carimbá-lo aqui
  seria rótulo, não artefato. Com a árvore limpa o runner já rederiva sozinho:
  `sdd why` → `REVIEW: no 40-review-r<N>.md`. A próxima sessão de REVIEW encontra a **própria rodada
  já commitada** em `7f9e660` (asserção da branch órfã, mutação nova, `die` de `ensure_mission_branch`,
  `frontmatter_write` endurecido, 3 TODOs) e deve fechar o artefato em vez de refazer o trabalho.
- 2026-08-17 00:37 · `EXEC` · o defeito sistêmico — `gate_EXEC` não distingue **árvore suja** de
  **HEAD vermelho**, então o vermelho de qualquer fase em voo rederiva EXEC em laço a ~US$ 25 a volta
  — foi para o `TODO.md` em vez de virar diff nesta missão.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.

**F1** — em `cmd_approve`, o `case` que trata `auto|humano-*)` como "já aprovado" precisa distinguir
o plano kaizen-born: com `05-verdict.md` ao lado, `auto` não é aprovação, é a máquina se
certificando — o mesmo teste que o `gate_PLAN` já faz. A condição existe em UM lugar hoje (o gate);
lida em dois, vira uma definição, pela regra do enum do `CLAUDE.md`. Sem verdict, `auto` continua
sendo "already approved" e o comando continua no-op.

**F2** — `warn_if_on_base_branch` no início de `cmd_approve`, e o comentário da definição
(`bin/sdd:1271`) passa de "four doors" para cinco. **Aviso, nunca `die`:** o plano legitimamente
vive na branch base antes de a branch da missão ser cortada — é de lá que `ensure_mission_branch`
corta —, então recusar quebraria o fluxo normal. Vale a mutação de call site, como o
`RETRY_base_branch_warn_dead` do I3 fez pelo mesmo motivo.
