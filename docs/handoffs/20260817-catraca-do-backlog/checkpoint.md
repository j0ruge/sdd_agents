---
missao: 20260817-catraca-do-backlog
atualizado: 2026-08-17 21:58
---

# Checkpoint — a catraca do backlog

> **Este arquivo é lido por máquina.** O runner faz parse da tabela abaixo para decidir a
> próxima fase. Não mude as colunas, não mude os tokens de status, não quebre linhas dentro de
> uma célula. Detalhe narrativo vai no `01-plano.md`, não aqui.
>
> ⚠️ **Nada de `|` na célula do Check — nem escapado como `\|`.** O parser é `awk -F'|'` cru e
> não conhece o escape do GFM: a célula vira duas, o Status lido passa a ser um pedaço do
> comando e o Commit passa a ser `pending`.
>
> ⚠️ **Check que lê a saída de um sensor ancora em `^  ok    ` — quatro espaços, com o `^`.**
> O runner imprime `  ok   ` com TRÊS espaços; nenhum Check daqui lê saída do runner.
>
> Atualizar o checkpoint é o **último ato** de cada incremento — depois do commit, nunca antes.
> Status válidos: `pending` · `doing` · `done` · `blocked`.

| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | sensor `check-health.sh` sobre `cmd_health` | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet fails on a stale baseline line' <<< "$o"` → `1` | done | afe5db6 |
| I2 | catraca da contagem de achados | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    a baseline off by one fails both ways' <<< "$o"` → `1` | done | 36a6eb6 |
| I3 | cinco defeitos de saída do `cmd_autonomy` | `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    output:' <<< "$o"` → `5` | done | 02e5da6 |
| I4 | mutações que faltam no catálogo | `grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' tests/check-mutation.sh` → `81` | done | f0bbf82 |
| I5 | política escrita e baseline no número real | `o=$(bash tests/check-health.sh 2>&1); grep -c '^  ok    the ratchet policy is written where the next mission meets it' <<< "$o"` → `1` | pending | — |

## Notas de execução

> Uma linha por evento relevante: bloqueio, decisão tomada, desvio do plano com justificativa.
> É o que a próxima sessão lê para não repetir um erro que já custou caro.

- 2026-08-17 17:44 · `PLAN` · Os cinco Checks foram rodados contra o HEAD `6d68dfc` no
  planejamento e **os cinco deram vermelho**: I1 `0`, I2 `0`, I3 `0`, I4 `70`, I5 `0`. Registrado
  porque o `TODO.md` traz um achado aberto sobre o gate PLAN-AUTO aceitar Check que já nasce verde.
- 2026-08-17 17:44 · `PLAN` · Âncoras do cluster 1 re-derivadas: as do `TODO.md` estão ~870 linhas
  defasadas. A tabela correta está no `01-plano.md`, seção "Contexto verificado". Não use as do
  `TODO.md`.
- 2026-08-17 17:44 · `PLAN` · O esperado `77` do I4 é derivado (`70 + 2 + 1 + 4`). Se a
  re-derivação do I4 fechar item por evidência em vez de por código, recalcule e registre aqui.
- 2026-08-17 19:52 · `I1` · Catálogo em **72** como o plano previu, então o `77` do I4 segue de pé
  (`72 + 1` do I2 `+ 4` do I4). `sdd health` → `kit healthy`, `score: 72 caught, 0 known gap(s)`.
- 2026-08-17 19:52 · `I1` · **Desvio do plano, deliberado:** a asserção 4 chama-se `provenance
  fails when the fixture diverges from an installed skill`, não "...when an installed skill is
  missing". Skill ausente **não reprova** — `health_provenance` a PULA por desenho (`bin/sdd:1806`),
  como o linter ausente é pulado. Escrita contra o caminho que de fato falha, e diferencial.
- 2026-08-17 19:52 · `I1` · O fixture hermético achou **dois abortos calados do `sdd health`**: com
  `~/.claude/plugins/cache` ausente o `find` devolve 1, e com baseline sem linha viva o `grep -vE`
  também — sob `set -e` + `pipefail` os dois matam o comando no meio, rc 1 e nenhuma palavra dita.
  Fora de escopo (I1 é o sensor, não o conserto): foi para o `TODO.md`, e o fixture modela máquina
  com o diretório, com o porquê comentado em `reset_home()`.
- 2026-08-17 19:52 · `I1` · **Custo medido, e é o risco da tabela do plano acontecendo:** o sensor
  roda em **1,5 s** sozinho (dentro do teto de 2 s), mas a suíte foi de **2m34s para 7m15s** —
  porque roda dentro dos 73 mutantes (+4 s cada) e a contenção é super-linear. Aceito e registrado
  no `TODO.md`: o sensor cabe no seu orçamento, o multiplicador é do harness de mutação e a saída
  ("rodar por mutante só o sensor que o alcança") é decisão do humano, junto com o alvo da D7.
- 2026-08-17 19:52 · `I1` · Três pisos de superfície andaram junto com o arquivo novo, o que o
  plano não listou: `LINT_FLOOR` 14→15, `check-pipefail` 13→14 e `check-lang` 36→37. O do
  `check-pipefail` arrastou o fixture do próprio selftest, construído **exatamente** no piso —
  três probes passaram a falhar com "surface shrank" em vez de medir o que nomeiam. Quem for
  acrescentar sensor à suíte de novo: são quatro lugares, não um.
- 2026-08-17 19:52 · `I1` · Sabotagem adversarial: **9 probes, 9 vermelhos**. Toda asserção morre
  em pelo menos uma, e a 3 (diferencial) e a 5 (piso) morrem **sozinhas** em probes próprios —
  nenhuma das duas é redundante. O par que o plano previu se confirmou: `ratchet_one_way` mata a 2
  e a 3 e deixa a 1 viva. Cada mutação foi verificada matando a suíte **só** por este sensor
  (`1 suite(s) failed`), não por rc compartilhado com outro.
- 2026-08-17 19:42 · `I2` · **A sabotagem adversarial achou uma falha-aberta na asserção 7, que a
  auto-revisão não teria achado.** Com a linha da contagem na baseline daquele mundo, o `rc != 0`
  que a asserção lia era escrito pelo ramo de **baseline órfã** (o achado deixa de ser emitido, a
  linha fica sem par) — não pelo check novo. Medido: rebaixar o `health_bad` do check para `warn`
  passava verde nas 7 asserções. Conserto: retirar a linha da baseline naquele mundo, o que faz o
  check ser o único autor possível da falha. É o modo "rc compartilhado com outro ramo" do
  `CLAUDE.md`, e ele apareceu numa asserção escrita justamente contra ele.
- 2026-08-17 19:42 · `I2` · **Um conjunto foi escrito e depois REMOVIDO por decisão de regra.**
  `grep -qF '1 check(s) failed'` entrou como o conserto da falha-aberta acima; a matriz provou que
  quem consertava era a baseline enxuta, e que nenhuma sabotagem de ponto único quebrava o
  conjunto. `CLAUDE.md`: regra que a sabotagem não alcança é decoração — removida, não documentada.
- 2026-08-17 19:42 · `I2` · Matriz da sabotagem: **5 defeitos × 3 degradações**, todos os 5 pegos
  pelo sensor íntegro, e cada degradação deixa escapar exatamente o seu defeito (D1→F1, D2→F2,
  D3→F6), com o kit saudável ainda verde nas três. Os três conjuntos são carga, nenhum é enfeite.
  ⚠️ A primeira rodada da matriz concluiu errado em 2 probes: `D2`/`D3` **apagavam** a linha que
  carrega o `; then`, quebrando o `if` — o probe morria de sintaxe e o resultado não dizia nada.
  Degradação **substitui** por `true`, nunca apaga, e o harness roda `bash -n` no **sensor** além
  do `bin/sdd`.
- 2026-08-17 19:42 · `I2` · **Terceiro aborto calado da família, e o pior deles:** a checagem do
  `score:` (`bin/sdd:1721`) promete `health_bad` e morre antes — `score_line="$(grep …)"` devolve 1
  sob `set -e` e mata o runner na atribuição. Provado por probe. Fora de escopo (I2 é a contagem):
  foi para o `TODO.md`. O check novo já nasce com `|| true` por causa dele — copiar "o padrão
  inteiro" como o plano mandava teria replicado o defeito, e a asserção 7 foi quem barrou.
- 2026-08-17 19:42 · `I2` · A baseline foi escrita em **71**, não nos 68 do plano: o I1 registrou
  dois achados e este incremento registrou um terceiro. É o risco "a missão descobre itens novos"
  da tabela do plano acontecendo — e é o desenho, não o desvio. O I5 remede no fim.
- 2026-08-17 19:42 · `I2` · Catálogo em **73** (`72 + 1`), `0 known gap(s)`; `sdd health` →
  `kit healthy`, `ratchet: 7 known debt(s), none new`. O `77` do I4 segue de pé (`73 + 4`).
- 2026-08-17 19:42 · `I2` · Métrica 1 provada **fora do fixture**, no repo real: baseline por 1
  errada reprova com as duas mensagens (`finding outside the baseline: todo-findings 71` e
  `stale baseline: 'todo-findings 70'`), rc 1. Baseline restaurada por `trap`.

- 2026-08-17 20:26 · `I3` · **Os cinco Checks re-derivados antes de escrever: os cinco reproduzidos
  à mão** (`US$ 2` e `US$ 1.5`; as duas mensagens de `die` idênticas; os dois blocos "no data"
  byte a byte iguais; `zzzzzzz` escrito primeiro saindo depois de `aaaaaaa`; duas linhas em branco).
  As cinco asserções nasceram vermelhas **cada uma pelo seu motivo**, lidas uma a uma na saída.
- 2026-08-17 20:26 · `I3` · **Desvio do plano, deliberado: `printf` não entrou.** O plano e o
  `TODO.md` diziam "`printf` no lugar da interpolação"; a linha inteira da tabela nasce dentro de um
  único programa `jq`, e o `jq` 1.7 não tem `printf` — buscar o número de volta no bash partiria uma
  linha em duas linguagens. Saiu `def usd`, que arredonda para centavo INTEIRO e re-parte, com o
  porquê no comentário do ponto de mudança.
- 2026-08-17 20:26 · `I3` · **Uma das duas mensagens de `die` foi mantida de propósito.** Só a do
  *shape* ganhou frase nova: `kaizen_series` (`bin/sdd:2565`) recusa o mesmo ledger ilegível com as
  mesmas palavras da outra, e renomeá-la moveria a colisão de dentro de um comando para entre dois —
  a versão mais difícil de notar. Quem chegar aqui querendo "terminar o serviço": não termine.
- 2026-08-17 20:26 · `I3` · **O programa `jq` do `cmd_autonomy` é UMA string em aspas simples, e um
  apóstrofo de comentário a encerra no meio.** Custou dois ciclos: `human's` e `judge's` num
  comentário novo, e `bash -n` acusou erro de sintaxe ~30 linhas depois da frase que quebrou. Toda
  a prosa de lá é escrita contornando o possessivo — agora com o ⚠️ no topo do programa, que era o
  lugar onde a regra faltava.
- 2026-08-17 20:26 · `I3` · Sabotagem adversarial: **10 degradações, 10 pegas**. Em laboratório
  limpo (baseline 0 falhas) cada uma reprova **exatamente uma** asserção — a sua. Nenhum rc
  compartilhado, nenhuma asserção redundante. As quatro últimas miram só os **pisos** contra
  vacuidade (coluna de dinheiro some, contabilidade some, frase some do fonte, tabela some): os
  quatro são carga, nenhum é enfeite.
  ⚠️ A primeira rodada concluiu **nada** em 3 dos 4 probes de piso — o `perl -0pe` não casou por
  escape de `\(`. O harness grita `SABOTAGE-BROKEN` quando a edição não muda o arquivo ou quebra o
  `bash -n`, e foi ele que barrou as três conclusões vazias. Probe sem prova de que sabotou não vale.
- 2026-08-17 20:26 · `I3` · **A baseline da catraca subiu 71 → 72 neste commit**, e não no I5. Este
  incremento registrou um achado (a linha em branco que sobra ENTRE exclusões consecutivas — mesma
  família, fora do item relatado). O plano reserva o número ao I5, mas deixar a catraca vermelha por
  dois incrementos é o oposto do que ela existe para fazer: crescer é permitido, aparecer no diff é
  a regra. `sdd health` → `kit healthy`, `ratchet: 7 known debt(s), none new`. O I5 remede no fim.
- 2026-08-17 20:26 · `I3` · Catálogo segue em **73**, `0 known gap(s)` — o I3 não acrescenta
  mutação por desenho (o plano só prevê as 4 do I4). Logo o `77` do I4 continua de pé (`73 + 4`).
- 2026-08-17 20:26 · `I3` · **Os 5 itens que este incremento fecha ainda NÃO levam `RESOLVIDO por`**
  — é tarefa do I5, e ficam em `TODO.md:440`, `:446`, `:453`, `:459` e `:466` (seção "Saída humana e
  cosmética"), todos com hash `02e5da6`. As âncoras `bin/sdd:` que eles citam continuam defasadas;
  a tabela boa está no `01-plano.md`.

- 2026-08-17 21:58 · `I4` · **O `77` foi recalculado para `81`, e o Check da linha foi ajustado** —
  a rota que o próprio plano abre ("o `77` é derivado, não sagrado"). A aritmética nova é
  `73 + 1 (retry/branch) + 2 (ledger) + 2 (kaizen) + 3 (degraded)`. O plano previu 4 porque contou
  um item = uma mutação; três dos quatro itens pedem mais de uma. A **verificação end-to-end** do
  `01-plano.md` passa a esperar `score: 81 caught, 0 known gap(s), of 81` — medido, `sdd health` →
  `kit healthy`, `ratchet: 7 known debt(s), none new`.
- 2026-08-17 21:58 · `I4` · **A re-derivação contradisse o plano nos dois pontos em que ele mandava
  conferir, e nas duas vezes para MAIS trabalho, não menos.** (a) `mut_RUN_moved_never_true` **não**
  cobre o `moved` do `cmd_retry`: ele ancora na cópia de QUATRO espaços do `cmd_run`, e `cmd_retry`
  e `cmd_kaizen` têm a sua com DOIS — sob aquela sabotagem a asserção da linha 326 do
  `check-autonomy.sh` fica verde. Medido por probe, não por leitura. (b) Nenhuma das quatro
  `mut_RUN_degraded_*` alcança as três metades do item: elas cobrem o escritor do ledger, a guarda
  one-shot, o `phase_label` do `kaizen_series` e o número de voltas. As três (journal, predicado do
  `cmd_autonomy`, admissão da série) estavam mesmo descobertas.
- 2026-08-17 21:58 · `I4` · **As oito nasceram sabotadas à mão, cada uma contra o sensor que a
  pega, e cada uma morre pela asserção que o comentário nomeia** — nunca por rc compartilhado. Duas
  precisaram de endereçamento por FAIXA depois de a primeira tentativa sabotar demais: `return
  "$out_rc"` aparece **6×** dentro do `cmd_kaizen` (um `sed` sem faixa colapsa todos os bailouts do
  comando num mutante só) e `def is_escalation` é byte a byte igual no `cmd_autonomy` e no
  `kaizen_series`. Todas as oito verificadas mudando **exatamente uma linha** (`diff` contado) e
  passando `bash -n`.
- 2026-08-17 21:58 · `I4` · **Achado fora de escopo, com probe:** o `moved` do próprio `cmd_kaizen`
  (`bin/sdd:3103`) sabotado à mão deixa `check-kaizen.sh` **e** `check-autonomy.sh` verdes — não há
  asserção, logo não pode haver entrada no catálogo (é a regra do I4: sabotagem que deixa tudo verde
  vira achado, não entrada). Foi para o `TODO.md`, e a baseline da catraca subiu **72 → 73 no mesmo
  commit**, pelo mesmo motivo registrado no I3: catraca vermelha atravessando incremento é o oposto
  do que ela existe para fazer.
- 2026-08-17 21:58 · `I4` · **Os 4 itens que este incremento fecha ainda NÃO levam `RESOLVIDO por`**
  — é tarefa do I5, e ficam em `TODO.md:80`, `:284`, `:304` e `:310` (os dois últimos deslocaram de
  `:297` e `:303` com a entrada nova acima), todos com hash `f0bbf82`. ⚠️ As âncoras `bin/sdd:` que os quatro citam
  estão ~800 linhas defasadas; as reais estão nos comentários das entradas novas do catálogo.

## Incrementos de fix (QA)

> Escritos pelo `sdd-qa` quando um bug sanável é reprovado. Entram na mesma tabela acima com ID
> `F<n>`, e o Check obrigatoriamente inclui **regression test passa** + **re-walk da jornada
> impactada verde**. Bug que exige julgamento humano NÃO vira fix — vai para
> "Decisions for a Human" no handoff de QA.
