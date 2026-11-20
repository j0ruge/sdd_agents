---
missao: 20261119-l1b-a-rodada-delta
titulo: Da segunda rodada em diante, a REVIEW revisa só o que mudou desde a rodada anterior, e o worker usa o mesmo delta
data: 2026-11-19
versao:
branch: feat/l1b-a-rodada-delta
aprovacao: humano-2026-11-19
adr: docs/adr/0023-the-next-round-reviews-the-delta.md
ddd: n/a
qa:
kaizen_log: skipped
campaign: 20261117-zerar-as-issues
lot: L1b
---

# Missão — L1b: a rodada delta

> Escrito pelo `sdd-planner` com o humano presente (por relay), em 2026-11-19. É a única fonte da
> **intenção**; o `01-plano.md` é a fonte do **como**. Toda sessão headless começa lendo estes dois.
> Item da campanha: o #436 do espelho (`TODO.md`, seção *Sem seção*, título
> **A rodada de revisão relê a missão inteira, porque o chapéu não passa `base=` à skill**).

## Problema (Gemba)

Toda rodada de REVIEW revisa a branch inteira, da primeira à última, e nada guarda o head que ela
leu.

- **O chapéu manda revisar "over the mission diff".** O `agents/sdd-reviewer.md:46` diz
  ``Invoke `/codereview:codereview` over the mission diff``. Sem `base=`, a skill (`codereview` 2.30.1,
  a cópia que `~/.claude/plugins/installed_plugins.json` grava) usa `git merge-base main HEAD`
  (passo 4 do `SKILL.md` dela). A mesma skill já aceita `base=<sha>` e já tem uma rodada de verificação
  própria para re-revisão; a régua dela é "Re-review the fix, not the branch".
- **O runner não diz nada à REVIEW sobre isso.** O `phase_extra REVIEW` (`bin/sdd:3173`) é um heredoc
  fixo, sem base nem head, e a sessão chama a skill pela ferramenta `Skill`.
- **Nada guarda o head revisado.** O `templates/review.md` não tem `reviewed_head:`. Essa chave existe
  só para o worker (`bin/sdd-worker:1258`, ADR 0022), que por isso escreve uma rodada própria, uma
  acima da do runner (`commands/sdd-worker.md:199-203`; `docs/pipeline.md:2078`).
- **A rodada 2 em diante custa o mesmo que a 1.** No ledger (`~/.sdd/autonomy-log.jsonl`, linhas
  `session` de REVIEW de `20261117-o-worker-orquestrador`): r1 US$ 5,12 em 1 013 s; r2 US$ 6,31 em
  1 287 s; r3 US$ 7,50 em 929 s; r4 US$ 5,36 em 946 s. A razão r≥2/r1 fica entre 1,0 e 1,5.
- **No #414 as rodadas do worker custaram ~1h30 cada**, e as três rodadas delta feitas à mão
  (r9, r10, r11) custaram 36 min, 37 min e 9 min, com 181 a 269 k tokens.
- **A frase de briefing já falhou.** Na r7 do #414 o dono pegou a rodada sem `base=` revisando a
  branch inteira, apesar de o briefing pedir o delta: o delta se impõe pelo argumento da skill, nunca
  por frase.

## Métrica

Nesta missão, fatos binários, cada um com sensor na suíte (decisão 7):

1. Com uma rodada anterior que tem `reviewed_head:` (ancestral do `HEAD`, sem merge depois dele), o
   prompt de boot da REVIEW e o `sdd review-base <missão>` trazem `base=<40 hex>` e nomeiam a rodada.
2. Sem rodada anterior, o prompt de boot da REVIEW diz `full` e o motivo (`check-dry-run.sh`, cuja
   missão não tem rodada). Sem a chave, com a chave errada ou com um merge no intervalo, o
   `sdd review-base` diz `full` e o motivo (`check-gates.sh`). Os dois leem a mesma função.
3. O `gate_REVIEW` recusa os três casos de chave errada (não é sha, não é ancestral do `HEAD`,
   código alterado entre ela e o commit da rodada) e aceita a rodada sem a chave.
4. O ato `review` do `commands/sdd-worker.md` passa a linha do `sdd review-base` ao subagente.

O número vem depois do merge (decisão 7): na primeira missão do kit que rodar com este runner (o L2),
custo da REVIEW r≥2 dividido pelo da r1, lido do ledger. Antes: 1,0 a 1,5. Alvo: ≤ 0,5.

## Resultado esperado

A primeira rodada de REVIEW continua inteira. Da segunda em diante, o runner lê o `reviewed_head:`
que a rodada anterior gravou e manda a sessão invocar `/codereview:codereview base=<sha>`, com a
rodada anterior nomeada como a lista dos achados abertos. Um achado em código que o delta não tocou
vai ao `TODO_FILE`, nunca a um `R<n>`. O mesmo juízo responde por `sdd review-base`, que o worker
passa ao subagente do seu ato `review`. Quando o delta não é confiável (sem chave, chave errada,
merge no meio), a rodada volta a ser inteira e o prompt diz por quê.

## Fora de escopo

- **O #340** (o carimbo tudo ou nada): fica como o L6a da campanha, com o seu próprio `/sdd-plan`
  (decisão 1).
- **O #417** (nenhum sensor relê os Checks `done`): segue aberto no `TODO.md`.
- **A régua de severidade** (só HIGH+ ou MEDIUM reproduzido abre rodada; o LOW que não move a nota):
  é o L6k da campanha. Esta missão só dá destino ao achado **fora do delta** (decisão 9).
- **A ordem do ato `review` do worker** (ele mergeia a base antes de cada rodada, e com a decisão 5
  isso faz a rodada inteira sempre que a `main` andou): não muda aqui.
- **A medida em dinheiro**: fica para o L2 (decisão 7), como pendência abaixo.

## Gate PLAN-AUTO

Preenchido pelo `sdd-planner` **com evidência**. Todos ✅ → `aprovacao` fica vazio do mesmo jeito: o
humano lê o plano no passo de aceite do `/sdd-plan` e aprova com `sdd approve`. O `auto` só entra
quando o humano o pediu no grill, e aí o pipeline segue sozinho até o PR (ADR 0018 §3). Qualquer ✗ →
`aprovacao` fica vazio e o runner para pedindo aprovação humana explícita, nomeando o critério.

| # | Critério | Status | Evidência |
|---|---|---|---|
| a | Grill sem perguntas abertas não endereçadas (🚩 vazia ou itens deferidos com dono) | ✅ | 10 perguntas, 10 respostas marcadas nas Decisões; o leitor do aceite responde `10 (recommended) of 10`. Nenhuma aberta. Quatro pendências, todas com dono, em "Pendências para o humano" |
| b | Checklist kaizen 100% ✅ e checklist DDD 100% ✅ ou `n/a` justificado | ✗ | K1 a K7 ✅; K8 ✗ por decisão 7 (`kaizen_log: skipped`: o "depois" em número só existe no L2, e a entrada nasce lá); DDD `n/a` com a justificativa de uma linha |
| c | Plano passa no teste de autocontenção (sessão nova só com 00/01/checkpoint executa) | ✅ | Uma sessão nova (subagente sem contexto, somente leitura) recebeu só os três arquivos e o repo. Conferiu I1, I2 e I3 por inteiro, e I4 e I5 só nos lugares citados. Veredito: "only-if", com 4 bloqueios: o Check do I3 contaria 7 ou 8, porque o `assert_phase` também imprime a frase; quatro mutantes sobreviveriam às asserções escritas; uma regex com `^` nunca casaria a saída do `sdd why`; e a linha no `coordination_enter` era inócua, por causa do braço `*)`. Também 9 lacunas (o idioma do merge no fixture, o `gate:` real, o sha curto, o lugar exato no fim do `bin/sdd`, dois comentários velhos do `check-worker.sh`, e outras). Conferi cada achado no repo e corrigi tudo no `01-plano.md`; os Checks não mudaram. A segunda passada, depois das correções, não foi rodada. Foi leitura com verificação, não execução |
| d | Todo incremento do `checkpoint.md` tem Check executável (comando → esperado), vermelho no HEAD pelo `tests/check-checkpoint.sh --red` do kit | ✅ | 5 incrementos; `tests/check-checkpoint.sh --check` → `5 row(s), 4 under the anchor rule, none blind`, rc 0; `--red` → `5 pending Check(s), every one red at HEAD`, rc 0, 497 s, de 2026-11-19 17:44 a 17:53, sobre `cc8509a` |
| e | `versao:` confirmada pelo humano (ou `JIRA_ENABLED=false`) | ✅ | `JIRA_ENABLED=false` no `.sdd/config.sh` |
| f | `adr:` é uma decisão — um caminho, ou o literal `none` (alocado por `sdd adr new`) | ✅ | `adr: docs/adr/0023-the-next-round-reviews-the-delta.md` (decisão 10), alocada por `./bin/sdd adr new` no worktree, em 2026-11-19 17:55. Corpo escrito em inglês, emendando a §5 da 0022; fica `proposed` até o `sdd approve`. `./bin/sdd adr check --mission 20261119-l1b-a-rodada-delta --phase plan` → `… and that ADR points back`, rc 0; `tests/check-lang.sh` rc 0 com o arquivo |

## Checklist kaizen (`kaizen-software`)

> O K8 desta tabela é prosa: quem dispensa a entrada do KAIZEN_LOG.md é só o literal kaizen_log: skipped no frontmatter, decidido com o humano no grill.

| # | Item | Status | Nota |
|---|---|---|---|
| K1 | Gemba — fui ver onde o trabalho acontece | ✅ | `gate_REVIEW`, `phase_extra`, `coordination_enter`, o `pr-ready` do worker, a skill instalada e o ledger, lidos; os sensores tocados foram cronometrados no HEAD (contexto verificado do plano) |
| K2 | Problema declarado com métrica | ✅ | quatro fatos binários com sensor nesta missão; a razão r≥2/r1 (hoje 1,0–1,5, alvo ≤ 0,5) medida no L2 |
| K3 | Desperdícios identificados e cortados | ✅ | o #340 e o #417 ficaram de fora; uma definição só do juízo (`bin/sdd`), sem cópia no `sdd-worker`; o código novo vai para o fim do `bin/sdd`, para não deslocar as âncoras do `TODO.md` |
| K4 | Fatiamento incremental, cada fatia verificável | ✅ | cinco incrementos, cada um com um Check vermelho no HEAD |
| K5 | Check por artefato (rótulo ≠ artefato) | ✅ | os Checks leem linhas `^  ok    ` dos sensores; o prompt é lido da projeção e do `sdd boot`; o gate confere o `reviewed_head:` pelo git, nunca pela palavra da rodada |
| K6 | Jidoka — o que para a linha está definido | ✅ | sensor, `--anchors` do `check-todo.sh` ou do `check-mutation.sh` vermelhos param o incremento; `CHECKOUT-BUSY` no `install --force` vira `blocked` com nota |
| K7 | SDCA — a melhoria vira padrão (doc/rule/teste) | ✅ | asserções em quatro sensores, mutantes no catálogo, a chave no `templates/review.md`, o chapéu e os dois docs |
| K8 | Registro no KAIZEN_LOG | ✗ | decidido com o humano (decisão 7): nesta missão não há o "depois" em número, porque a REVIEW dela roda com o runner de antes; `kaizen_log: skipped`, e a entrada nasce no L2, com o número |

## Checklist DDD (`ddd`) — condicional

`n/a — sem toque de domínio: a missão estende o escritor de uma chave de artefato que dois programas
já dividem (o `reviewed_head:` da ADR 0022) e acrescenta um verbo de leitura ao runner; nenhum
agregado, contexto, evento ou entidade nova.`

## Decisões do grill (não re-litigar)

1. **Escopo: só o #436.** O #340 fica como o L6a, com o seu próprio `/sdd-plan` depois. Porquê: é o
   único dos dois que acelera a campanha em voo (toda REVIEW dos lotes que faltam); o #340 só paga a
   partir do segundo `sdd health`, depois da campanha.
   - answer: (recommended)
2. **A missão é o lote novo `L1b — A rodada delta`, com teto `-`, logo abaixo do L1.** A delegação
   assina `lots: L1 L1b` (sem o L2), e esta missão declara `campaign: 20261117-zerar-as-issues` e
   `lot: L1b`. Porquê: o `allows --mission` só sobe acima de `assisted` com `campaign:` e `lot:`
   (`bin/sdd-worker:581`), e um `lot: L2` faria o `next` dar o L2 por feito no merge, com os 14 itens
   dele abertos (`bin/sdd-worker:991`). A linha da tabela e o `lots:` são do relay, no PR #445
   (`chore/delegacao-full-l1-l1b`), antes da assinatura, porque o selo cobre o teto de toda linha
   (`delegation_terms`, `bin/sdd-worker:202-206`).
   - answer: (recommended)
3. **O runner deriva o `base=`, e o chapéu grava o head.** Com um `reviewed_head:` ancestral do
   `HEAD` na rodada mais nova, o `phase_extra REVIEW` escreve no prompt
   `/codereview:codereview base=<40 hex>` e nomeia o `40-review-r<N-1>.md` com os achados abertos;
   sem rodada anterior, a revisão é inteira. O `templates/review.md` ganha `reviewed_head:` (a mesma
   chave que o worker lê), e o `gate_REVIEW` confere que é um sha ancestral e que, de lá até o commit
   da rodada, só mudou o que o chapéu do revisor escreve (`hat_writes REVIEW`: a pasta da missão, o
   `TODO_FILE` e a catraca). Porquê: o argumento sai de um comando, não de uma frase, e a chave é uma
   só para o runner e para o worker.
   - answer: (recommended)
4. **A rodada sem `reviewed_head:` é aceita, como hoje (legado).** A rodada seguinte a ela é inteira,
   e o prompt diz por quê. O gate recusa só a chave presente e errada: um valor que não é sha, um sha
   que não é ancestral do `HEAD`, ou código alterado entre esse sha e o commit da rodada. Porquê:
   nenhuma missão em voo (o L1, os alvos) volta à REVIEW por uma chave que o runner dela nunca pediu.
   - answer: (recommended)
5. **Com um merge no intervalo (`git rev-list --merges <reviewed_head>..HEAD` não vazio), a rodada é
   inteira, e o prompt nomeia o merge.** Porquê: a skill revisa `base..HEAD`, e um merge da `main`
   despejaria no delta tudo o que veio dela; sob `sdd run` ninguém mergeia entre as rodadas.
   - answer: (recommended)
6. **O ato `review` do worker também usa o delta, por um verbo do runner.** `sdd review-base <missão>`
   imprime `base=<sha>` ou `full — <motivo>` pela mesma função que o `phase_extra REVIEW` usa, e o ato
   `review` do worker passa essa linha ao subagente. Porquê: o "~1h30 por rodada" do #436 foi medido
   nas rodadas do worker, e uma definição só no `bin/sdd` evita a segunda cópia no `sdd-worker`.
   - answer: (recommended)
7. **Métrica: fatos binários aqui, o número no L2.** Cada fato com sensor (ver Métrica). O número é o
   custo da REVIEW r≥2 dividido pelo da r1, hoje 1,0 a 1,5, alvo ≤ 0,5, medido no L2. A missão
   escreve `kaizen_log: skipped`, e a entrada do `KAIZEN_LOG.md` nasce com o número na missão que o
   medir. Porquê: a REVIEW desta missão roda com o `sdd` do PATH (o checkout principal, o runner de
   antes, ADR 0022 §7), então o "depois" não existe aqui.
   - answer: (recommended)
8. **O id é `20261119-l1b-a-rodada-delta`, e o branch, `feat/l1b-a-rodada-delta`.** Porquê: o mesmo
   formato do L1, com `feat` porque a missão cria um verbo.
   - answer: (recommended)
9. **Numa rodada delta, um achado em código que o delta não tocou vai ao `TODO_FILE`, nunca a um
   `R<n>`.** O chapéu `sdd-reviewer` e o `phase_extra REVIEW` dizem isso, e a única leitura fora do
   delta é um `grep` pela grafia antiga de uma interface que o delta mudou. Porquê: sem a regra, a
   rodada delta ainda abriria um R por um LOW fora dela e voltaria a custar como uma inteira.
   - answer: (recommended)
10. **A missão ganha a ADR 0023, que emenda a §5 da 0022.** O arquivo é
    `docs/adr/0023-the-next-round-reviews-the-delta.md`, em inglês, porque o `tests/check-lang.sh:68`
    cobra `docs/adr/*.md`. Ela fica `proposed` até o `sdd approve`. Porquê: a missão muda um contrato
    de artefato que dois programas leem (o `docs/pipeline.md:2078` diz hoje que o `reviewed_head:` é
    só do worker, "on purpose"). E toma três escolhas caras de desfazer: a rodada sem a chave passa,
    o merge no intervalo força a rodada inteira, e o gate confere o intervalo pelo `hat_writes REVIEW`.
    - answer: (recommended)

## Pendências para o humano

- **A entrada do `KAIZEN_LOG.md` com o número** (decisão 7): dono, a sessão orquestradora do worker
  (ou o dono) na missão do L2. Ler do ledger o `cost_usd` das linhas `session` de REVIEW do L2
  (`LC_ALL=C jq … ~/.sdd/autonomy-log.jsonl`) e escrever r≥2/r1 contra o antes desta missão (1,0 a
  1,5, `20261117-o-worker-orquestrador`). Se o L2 mudar o effort da REVIEW, a razão mistura duas
  variáveis: diga isso na entrada.
- **O PR #445 mergeado antes de o worker lançar esta missão** (decisão 2): dono, o dono do kit. Sem a
  linha `L1b` na tabela de lotes e o `lots: L1 L1b` assinados, o `allows --mission` responde `assisted`.
- **A `main` trazida ao branch antes do `sdd run`**: dono, o relay (ou o dono). O L1
  (`fix/l1-a-prosa-do-chapeu`) também edita o `agents/sdd-reviewer.md` e o `TODO.md`. Depois do merge
  dele, rodar `git merge origin/main` no worktree e, de novo, `tests/check-checkpoint.sh --check` e
  `--red` sobre este checkpoint. Os números de linha do `01-plano.md` são de `cc8509a`, e os lugares
  estão nomeados por símbolo.
- **O effort das fases desta missão** (`EFFORT_*` no `.sdd/config.sh` do worktree, como o commit
  `c59d1d3` fez no L1): decisão do dono antes do `sdd run`, depois de lida a r1 do L1, que mede o
  executor em `medium`. O plano não depende do valor.
