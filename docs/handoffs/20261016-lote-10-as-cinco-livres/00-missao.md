---
missao: 20261016-lote-10-as-cinco-livres
titulo: as cinco issues livres saem do backlog — a regra 2 do check-checkpoint lê a substituição de processo da stderr como mescla e a família dela fecha pelo critério do corpus, e o /sdd-plan corta uma branch provisória e mantém o planner fora do checkout principal
data: 2026-10-16
versao:
branch: fix/lote-10-as-cinco-livres
aprovacao: humano-2026-10-16
adr: none
ddd: n/a
qa:
kaizen_log:
---

# Missão — o lote 10: as cinco livres

> Escrito pelo `sdd-planner` com o humano presente (relay do `/sdd-plan`, 2026-10-16 18:16–18:44).
> É a única fonte da **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão começa lendo
> estes dois.
>
> ⚠️ **Missão do próprio kit: executada INTERATIVA, no worktree ligado
> `/home/joruge/repos/sdd_agents-lote-10`, nunca por `sdd run` a partir do checkout principal**
> (ADR 0016 §2, `commands/sdd-plan.md` passo 2). Todo comando roda como
> `cd /home/joruge/repos/sdd_agents-lote-10 && …`; rascunho e medição vão para caminho absoluto no
> scratchpad, nunca para caminho relativo. Dentro do worktree, `health`, `preflight` e `install` rodam
> como `./bin/sdd`. O checkout principal `/home/joruge/repos/sdd_agents` é o kit que o `sdd` do PATH
> executa para os alvos: nada se escreve nele (é o #281 desta missão).

## Problema (Gemba)

O backlog do kit tem 17 itens abertos, espelhados em 17 issues de label `todo`
(`bash tests/check-todo.sh --count TODO.md` → `17`; `tests/health-baseline.txt` → `todo-findings 17`).
O kit está **congelado desde o merge do lote 7** (D11 de `20261012-a-rota-da-qa`): nada entra em
`bin agents templates config` até o veredito da janela do lote 7, que segue em 1 de 3 missões
(`./bin/sdd kaizen --series` às 18:41: `kit_sha: bad6168`, `missions: 1`). `git diff
fec0cca..origin/main -- bin agents templates config` está vazio. **Cinco** dos 17 itens só tocam
`tests/` e `commands/`, que não partem a janela (os lotes 8 e 9 provaram):

- **#278 — `tests/check-checkpoint.sh:463` (`r2_merges`).** `o=$(bash t.sh 2> >(cat)); grep -c 'caso' <<<
  "$o"` → `1` sai `0 under the anchor rule` com rc 0 no HEAD `3208161` (fixture medido pelo planner);
  a mesma célula com `2>&1` é recusada. No bash 5.2.21 a stderr cai na captura com `2> >(cat)`, `2>>
  >(cat)`, `2>| >(cat)`, `2<> >(cat)` e `2>  >(tee /dev/null)` (medido). Falha aberta, decidível pelo texto.
- **#279 — `tests/check-checkpoint.sh:925` (`r2_anchored`).** Um padrão entre aspas duplas que começa
  pela âncora e segue com uma expansão (`"^  ok    caso$alt"`) é aceito (fixture medido no HEAD). O
  cabeçalho do sensor já o declara (decisão 8(a) do lote 9). Recusá-lo deixaria vermelha a varredura do
  kit em **2** checkpoints fechados — a I10 de `20261002-onde-o-comando-do-humano-escreve` e a I20 de
  `20261003-lote-3-a-catraca-desce`, que leem `"^  ok    $n finding(s)"` com `$n` tirado da catraca.
- **#277 — `tests/check-checkpoint.sh:444` (`R2_STDOUT_RE`).** Os casos da regra 2 que só o runtime
  decide (terceiro descritor, `2>$f`, `/dev/./stdout`, `$'…'`, palavra que abre com expansão lida como
  operando, `POSIXLY_CORRECT` ou outro grep, `grep () (echo 0)`). A direção do item é "outra peça (o
  Check medido em execução)".
- **#280 — `commands/sdd-plan.md:35` (`git worktree add`).** O passo 2 manda criar o worktree "on the
  branch the mission will declare in `branch:`", mas a branch sai do id, que só o grill decide. Nos
  lotes 9 e 10 o relay cortou `fix/lote-N` provisória e o planner a renomeou com `git branch -m`.
- **#281 — `commands/sdd-plan.md:72` (`sdd-planner`).** O subagente herda o cwd da sessão, que é o
  checkout principal. No lote 9 um `2>e` relativo do planner gravou `?? e` lá às 08:02; um `sdd run` de
  alvo em voo teria parado com `KIT-TOUCHED` (rc 3), porque o `kit_guard_check` compara o `HEAD` e o
  `status --porcelain` daquele checkout.

**A família da regra 2 não converge sob revisão adversária.** O lote 9 (PR #274) teve 5 rodadas do
Codex, com 7 P2, todos grafias novas da regra 2; o PR #267 (lote 8) já tinha tido 6 rodadas na mesma
regra (K3 do `00-missao.md` do lote 9). O sensor foi de 1811 linhas (`9c13855`) para 3254 (`3208161`) e
os probes de 128 para 398 (`PROBE_FLOOR`). No corpus de **67 checkpoints** (30 do kit e 37 dos alvos: 6
do `lighthouse_project` em `3794fc9`, 31 do `sales_quote` em `a1ad4b74`), **0** linhas escrevem `>(`,
um terceiro descritor, `2>$f`, `2>"$f"`, `/dev/./stdout`, `/dev/stdout`, `/proc/…/fd/1`, `grep () `,
`POSIXLY_CORRECT` ou `exec N>&1` (grep do planner sobre as linhas de tabela); a forma do #279 aparece só nos 2
checkpoints fechados acima.

## Métrica

- **M1 (#278):** as 5 grafias que mesclam pela substituição de processo (`2> >(…)`, `2>> >(…)`, `2>|
  >(…)`, `2<> >(…)`, com brancos opcionais antes do `>(`) põem a célula sob a regra (hoje 0 de 5); os
  controles (`> >(cat)`, `1> >(cat)`, `12> >(cat)`, `2>/dev/null`) continuam fora. Uma linha nova
  `ok    rule: a process substitution that takes stderr counts as a merge` (0 hoje, 1 depois);
  `RULE_FLOOR` 8 → 9. As recusas da regra 2 nos alvos **não sobem**: **106 → 106** (37 checkpoints,
  medido às 18:42 com o sensor do HEAD `3208161`).
- **M2 (#277, #279):** os dois itens saem da seção aberta do `TODO.md` e viram dois registros decididos
  de uma linha, cada um com o evento que o reabre; a catraca vai de **17 → 15** no mesmo commit
  (`--count` e `tests/health-baseline.txt`). O cabeçalho do sensor deixa de apontar "the TODO.md item
  of round 3".
- **M3 (#280, #281):** duas linhas novas no `tests/check-hat.sh` (`ok    command: /sdd-plan cuts a
  provisional branch…` e `ok    command: /sdd-plan keeps the planner out of the main checkout…`), 0
  hoje e 1 cada depois; as linhas `command:` do sensor vão de **11 → 13**.
- **M4 (sem regressão):** a varredura do kit continua limpa (`ok    no checkpoint Check reads a red
  assertion as green`, hoje `197 cell(s) under the rule, 262 row(s) in 31 file(s)` sem o checkpoint desta
  missão); `tests/run-all.sh` verde no fecho; `git diff fec0cca..HEAD -- bin agents templates config`
  vazio em todo commit.
- **M5 (o fecho):** #278, #280 e #281 carregam `RESOLVED by <hash>`; a entrada do `KAIZEN_LOG.md` cita o
  id inteiro da missão e os números da família; depois do chore pós-merge o backlog fica em **12**, os 12
  congelados.

## Resultado esperado

A regra 2 do `tests/check-checkpoint.sh` lê `2> >(…)` (e `2>>`, `2>|`, `2<>`) como mescla, e a família
dela fecha: os casos que só o runtime decide e o padrão `dq` com expansão depois da âncora ficam como
limites declarados no cabeçalho e registros decididos no `TODO.md`, até uma Check real escrever um deles.
O `/sdd-plan` corta a branch provisória no passo 2 e manda o planner renomeá-la na decisão do id; o relay
exige `cd <worktree> &&` de todo comando do planner e confere o checkout principal a cada devolução. O
backlog sai de 17 para 12 itens depois do chore, todos congelados.

## Fora de escopo

- **Os 12 itens congelados** (#255, #256, #259, #260, #261, #262, #263, #265, #266, #271, #273, #282):
  tocam `bin/`, `agents/`, `templates/` ou o conserto é do runner; esperam o veredito e a triagem do
  `sdd kaizen`.
- **A peça de runtime do #277** (medir a Check em execução): decidida sem conserto (decisão 1). No PLAN a
  asserção ainda não existe (é por isso que a Check nasce vermelha), então não há FAIL para injetar; o
  gate não executa texto de modelo (`.claude/rules/anatomia-do-agente.md` §4); e ligar ferramenta nova ao
  `agents/sdd-planner.md` esbarra no congelamento.
- **Recusar o `dq` com expansão depois da âncora (#279):** decidido sem conserto (decisão 1); confirma a
  decisão 8(a) do lote 9.
- **Renomear o diretório do worktree:** fica com o nome provisório (decisão 2).
- **O carimbo de mutação:** o `./bin/sdd health` só roda quando a catraca zerar (decisão do humano no PR
  #267); esta missão a deixa em 12.
- **Sincronizar o espelho, apagar os itens resolvidos e fechar #277/#279 como `not planned`:** chore
  pós-merge, da `main` (Pendências).

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 6 decisões, cada uma com a sua linha `- answer:`; os 12 congelados têm dono (triagem do `sdd kaizen`); o fechamento de #277/#279 como `not planned` tem dono (chore do humano, Pendências) |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✅ | K1–K8 ✅ abaixo; DDD `n/a` (um sensor de markdown e a prosa de um comando) |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | o I1 nomeia os dois itens, o texto dos registros, as duas frases do cabeçalho (linhas 155 e 179), a catraca e o Check; ver `01-plano.md` § Teste de autocontenção |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 4 de 4 vermelhos no HEAD `3208161`; `--check` rc 0 e `--red` rc 0 (o "antes" de cada Check está no `01-plano.md`) |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` (`.sdd/config.sh` do worktree) |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `none`, decisão 6: `tests/` e `commands/`, reversível num commit; o "não reabrir" mora na seção decidida do `TODO.md` |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | #278 e #279 reproduzidos em fixture no HEAD `3208161`; as grafias de `>(…)` medidas no bash 5.2.21; o corpus de 67 checkpoints varrido pelas grafias abertas; as 106 recusas dos alvos medidas; o `ensure_mission_branch` (`bin/sdd:6068`) lido; o `check-hat.sh` rodado numa cópia `git archive` com um probe sabotado |
| K2 | Problema declarado com métrica | ✅ | M1–M5, cada uma com número de antes |
| K3 | Desperdícios identificados e cortados | ✅ | o laço de revisão por grafia (11 rodadas em 2 PRs, 0 casos reais) para por um critério escrito (decisão 1, decisão 5); a branch chutada antes do grill vira provisória |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | 4 incrementos, cada Check vermelho no HEAD |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | toda Check lê a linha `ok` do sensor ancorada em `^  ok    `, ou o arquivo |
| K6 | Jidoka — o que para a linha está definido | ✅ | selftest vermelho (rc 90–92) para a suíte; `PROBE_FLOOR`/`RULE_FLOOR` apertados; `check-hat.sh` rc 1; `tests/run-all.sh` no fecho; a regra de parada da revisão (decisão 5) |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | probes duráveis no selftest e no `check-hat.sh` da suíte rápida; o cabeçalho do sensor declara os limites; o `/sdd-plan` carrega as duas regras do relay |
| K8 | Registro no KAIZEN_LOG | ✅ | entrada no fecho (I4) com os números da família e o critério que a fecha (decisão 6) |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio`: a missão muda um sensor de markdown (`tests/check-checkpoint.sh`), a prosa de
um comando (`commands/sdd-plan.md`) e os probes dele (`tests/check-hat.sh`). Nenhum aggregate, contexto,
evento ou contrato entre módulos.

## Decisões do grill (não re-litigar)

1. **A família da regra 2: conserta-se o #278; o #277 e o #279 vão para a seção decidida do `TODO.md`,
   sem conserto, cada um com o evento que o reabre — uma Check real escrita numa dessas grafias.** O
   #278 é o único barato e decidível pelo texto; o #279 reabriria a decisão 8(a) do lote 9 e deixaria
   vermelhos 2 checkpoints fechados do kit; a peça do #277 não tem dono (PLAN sem asserção, gate sem
   texto de modelo, planner congelado). 0 de 67 checkpoints escrevem uma grafia aberta. Pela D15 um
   fail-open fica no backlog mesmo declarado: esta é a decisão explícita de que estes dois não têm
   conserto que compense. A catraca termina em 12, como no plano original.
   - answer: (recommended)
2. **#280: o passo 2 corta uma branch provisória e o diretório mantém o nome provisório; o "Then" manda
   o relay passar ao planner a ordem de renomear a branch (`git branch -m <provisória> <definitiva>`) na
   decisão do id, enquanto ela não tem upstream, e de escrever a definitiva em `branch:`.** Por quê: é o
   fluxo dos lotes 9 e 10, medido; daí em diante o worktree está na branch que o `sdd approve` lê, e
   não sobra branch.
   - answer: (recommended)
3. **#281: o "Then" manda o relay exigir `cd <worktree> &&` em todo comando do planner, com rascunho só
   em caminho absoluto fora do checkout principal; a cada devolução o relay compara `git -C <principal>
   status --porcelain` e `git -C <principal> rev-parse HEAD` com o estado de antes da delegação; se
   algo mudou, para antes de repassar a pergunta, mostra os caminhos ao humano e nunca apaga nada por
   conta própria.** Por quê: confere as duas coisas que a guarda de kit compara; apagar por conta
   própria poderia remover o arquivo de outro escritor.
   - answer: (recommended)
4. **O id é `20261016-lote-10-as-cinco-livres`, branch `fix/lote-10-as-cinco-livres`**, sem upstream
   (renomeada de `fix/lote-10` pelo planner com `git branch -m`, logo depois da resposta). Por quê:
   nomeia o escopo exato.
   - answer: (recommended)
5. **A revisão do PR para na rodada limpa do Codex com `local/ci` verde.** Achado no modelo do #278
   (substituição de processo como alvo da stderr, em qualquer grafia) ou nas duas regras novas do
   `/sdd-plan`: conserta no PR. Grafia nova da regra 2 fora disso: não conserta; vai para os limites
   declarados no cabeçalho do sensor, pelo critério da decisão 1, sem item no `TODO.md`. Da 4ª rodada em
   diante, qualquer achado vai ao `TODO.md` e o humano decide o merge. Por quê: aplica a decisão 1 ao
   próprio PR e mantém a válvula que encerrou o lote 9.
   - answer: (recommended)
6. **`adr: none`, K8 ✅ e DDD `n/a`.** O fecho escreve no `KAIZEN_LOG.md` uma entrada com os números da
   família (rodadas, P2, linhas e probes do sensor, 0 de 67 checkpoints, catraca) e o critério que a
   fecha. Por quê: segue o precedente do lote 9; a decisão 1 se reverte num commit, e o "não reabrir" já
   mora na seção decidida.
   - answer: (recommended)

## Pendências para o humano

1. **O PR e a revisão (decisão 5).** `git push -u origin HEAD`, o PR com o corpo do
   `templates/pr-body.md`, `@codex review` num comentário (neste repo o Codex só revisa a pedido), depois
   de conferir que `gh api repos/j0ruge/sdd_agents/pulls/<n> --jq .head.sha` é o sha empurrado; o
   `local/ci` pela API de Statuses só com a suíte rodada naquele sha. A parada é a rodada limpa; a
   válvula é a 4ª.
2. **O merge.** As autorizações de merge do lote 9 não se estendem a este: o relay pergunta de novo. Merge
   commit (`gh pr merge --merge`), nunca squash. Sem carimbo (`./bin/sdd health` não roda: a catraca fica
   em 12).
3. **O pull ocioso.** Depois do merge, `git -C /home/joruge/repos/sdd_agents pull --ff-only` só quando
   `ps -eo pid,etime,cmd | grep -E 'bin/sdd (run|retry|close)'` vier vazio. Sem ele o conserto não chega
   ao `/sdd-plan` nem ao `check-checkpoint.sh` que os alvos rodam pelo checkout principal.
4. **O chore pós-merge, da `main`, com a `todo-to-github-issues`.** `--fix --write` apaga #278, #280 e
   #281 (`RESOLVED by` ancestral da `main`), catraca 15 → 12, e o espelho (plano → `--apply --limit 1` →
   `--apply` → `--close-orphans` → replano `create=0 update=0`). **O #277 e o #279 saem por decisão, sem
   `RESOLVED by`:** o plano os lista `ORPHAN … no RESOLVED by` e o `--close-orphans` os pula; feche-os à
   mão com `gh issue close 277 --reason "not planned" --comment "<registro decidido do TODO.md, decisão 1
   de 20261016-lote-10-as-cinco-livres>"` (idem 279).
5. **A triagem depois do veredito** recebe os 12 congelados.
