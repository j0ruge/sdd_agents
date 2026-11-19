---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 6
status: done
sessao: rodada do worker (o ato review do commands/sdd-worker.md), feita por um subagente sdd-reviewer da sessão orquestradora, fora do runner
data: 2026-11-18 16:59
gate: tests/run-all.sh no c12c871 verde, rodado pela sessão orquestradora (rc 0, 2156 ok, nenhuma linha FAIL, anchors 881 de 881, 14 min 5 s); o d99302e difere dele só no TODO.md e na catraca (check-todo.sh rc 0, 88 achados, anchors 88 de 88); nesta rodada tests/check-worker.sh rc 0 (59 linhas ok, 50 s), shellcheck -S warning limpo no bin/sdd-worker e nos sensores tocados, check-templates rc 0 (worker templates 5), check-checkpoint --check rc 0 e --red com os 3 R novos vermelhos no head, segredos (regex e gitleaks, 44 arquivos) sem achado, WORKER_receipt_parsed_first, WORKER_sep_by_grade e WORKER_narrow_every_checkout mortos por --only (rc 1); nota B, dois HIGH e um lote reproduzidos em cópias, que viraram R11 a R13; as letras sobem contra a r5 (Code Quality e Type Safety de B para A), com os commits de conserto ecc2dee, af3babf, 600d45c, adf68fd, cbaf6be e 5fbddec atrás
reviewed_head: d99302ecf69c7538834f98051ceda65085664d31
---

# Review — rodada r6 — O worker orquestrador

## TL;DR

Rodada do worker sobre o `d99302e` (o `c90ffc7` mais o achado de `TODO.md` desta rodada), com o `/codereview` e reprodução em cópias `mktemp -d`.
Os consertos da r5 (R6 a R10) fecham o que os parágrafos prometiam: os mundos do `pr-ready`, do `next` e do `budget` foram refeitos por fora do sensor e respondem não.
Dois HIGH novos, nos verbos de confiança: o `pr-ready` dá `ready` a uma rodada a que falta a linha de um critério (R11), e uma missão mergeada cujo worktree saiu some do `next` e do `budget` (R12).
Um MEDIUM e três LOW de prosa e de limite viram o lote R13; o `gate_REVIEW` com a mesma régua do R11 foi ao `TODO.md`. Nada foi consertado aqui.
Nota B em Error Handling, Security, Test Coverage, Documentation e Overall; Code Quality e Type Safety sobem para A.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os consertos da r5 mantêm uma definição por fato (o `campaign_set` para o conjunto, o `GRADE_ROW_AWK` para os dois leitores da tabela, os centavos num jq só), nenhum símbolo ficou sem leitor e o `shellcheck -S warning` passa limpo. |
| Type Safety | A | Dinheiro em centavos, a gramática do runner para o override, o sha de 40 hex, o número do PR e o `isCrossRepository` booleano são conferidos antes do uso, refeitos aqui em cópia. |
| Error Handling | B | O `campaign_set` só acha missão em disco: removido o worktree de um lote mergeado com o checkout da campanha atrás da base, o `budget` soma US$ 0.00 no lugar de US$ 85 e o `next` responde `plan L1`, os dois com rc 0 (achado #2). |
| Security | B | O `pr-ready`, a única régua mecânica do merge delegado, lê "A em toda linha presente" como "A em todo critério": uma rodada só com a linha `**Overall**` em A responde `ready`, rc 0 (achado #1). |
| Performance | A | Os consertos trocam leituras sem laço novo sobre o repo: o conjunto estreito lê menos configs, e o sensor inteiro roda em 50 s, dentro do prazo de 550 s. |
| Test Coverage | B | São 58 asserções e 68 mutantes vivos, mas nenhum probe monta a rodada a que falta um critério nem a missão mergeada cujo worktree saiu, os dois regimes que escondem os HIGH. |
| Documentation | B | O teto da campanha pode ser atravessado por um teto de missão sem que nada o declare (MEDIUM), e a tabela de transições leva só o rc 0 do `run` ao `pr`, quando o `run` de uma missão do kit sai com rc 2 (LOW). |
| **Overall** | **B** | Os consertos da r5 estão provados; sobram dois HIGH reproduzidos nos verbos de confiança e um lote de prosa, entregues ao executor como R11 a R13. |

## Movimento contra a r5

Na r5, sete linhas abaixo de A (seis critérios e o Overall); aqui, cinco. Code Quality (Zen) e Type
Safety sobem de B para A, nenhuma letra desce, e há commits de conserto atrás de cada subida
(`ecc2dee`, `af3babf`, `600d45c`, `adf68fd`, `cbaf6be`, `5fbddec`). Não é platô: o laço anda.
Error Handling, Security e Test Coverage seguem em B por achados novos, não pelos da r5.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | HIGH | O `pr-ready` aceita a rodada a que falta a linha de um critério: só `**Overall**` A, ou dois critérios, dá `ready <sha>`, rc 0; a mesma tabela com `Security` B dá `not-ready`. É a classe do #8 da r5 (um critério sem A lido como aprovado), agora no nível da linha, e o `templates/review.md` promete "Revisão parcial não é revisão" | `bin/sdd-worker:1014` (`cmd_pr_ready`), `bin/sdd-worker:876` (`round_grades`) |
| 2 | HIGH | Missão mergeada some do conjunto quando o worktree dela sai antes de o checkout da campanha puxar a base: o `next` responde `plan L1 - — no mission … declares lot: L1`, rc 0, e o `budget` passa de `US$ 85.00 … 1 mission(s)` a `US$ 0.00 … 0 mission(s)`, rc 0. O checkout principal do kit fica atrás da base por regra (não se move com corrida viva), e o dono remove worktree mergeado na faxina | `bin/sdd-worker:557` (`campaign_set`), `bin/sdd-worker:566`, `docs/pipeline.md:1857` |
| 3 | MEDIUM | O teto da campanha é lido entre atos: `campaign US$ 190.50 of 200.00 — 1 mission(s); mission cap US$ 40`, rc 0, e o `run` seguinte pode terminar perto de 230. O template chama o valor de "o teto da campanha inteira", e nenhum texto declara o excesso de até um teto de missão (mais a sessão que o próprio runner deixa passar do teto de missão) | `bin/sdd-worker:670` (`cmd_budget`), `templates/delegation.md:7`, `docs/adr/0022-the-worker-is-a-session-orchestrator.md:124` |
| 4 | LOW | A tabela `## The transitions` leva só `run, rc 0` ao `pr`, e a retomada pelo diário fala só do rc 0; o `run` de uma missão do kit sai com rc 2 (PR aberto, só o carimbo faltando), que o comando manda ler como "ready for review". Na campanha do kit, a única que existe, o ato `pr` (as respostas do grill e os ◆ no corpo, decisão 8) fica pulado pela letra do comando | `commands/sdd-worker.md:91`, `commands/sdd-worker.md:264` |
| 5 | LOW | Um PR mergeado de um uso antigo do mesmo nome de branch faz o lote feito (`gh pr list --head` casa o nome), e nem o `cmd_next` nem o `docs/pipeline.md` declaram isso. Medido: 0 de 161 PRs do kit reusam um nome de head, então é limite, não conserto | `bin/sdd-worker:790` (`cmd_next`), `docs/pipeline.md:1961` |
| 6 | LOW (form) | A entrada do `KAIZEN_LOG.md` diz "cinco `R<n>` da REVIEW"; a missão tem dez | `KAIZEN_LOG.md:11` |

### Reprodução

Cada mundo foi montado num `git init` em `mktemp -d`, com um `gh` falso no `PATH` que serve as
respostas de arquivos, e o `bin/sdd-worker` do worktree:

- **#1:** rodada `40-review-r1.md` com `gate:` e `reviewed_head:` preenchidos, recibo do Codex para o
  head, zero threads, `MERGEABLE`. Só a linha `| **Overall** | **A** | Every criterion read; nothing
  to say. |` → `ready 8ac36b1…`, rc 0; `Code Quality (Zen)` e `**Overall**` → `ready`, rc 0; as oito
  linhas com `Security | B` → `not-ready review: … grades B`, rc 1 (o controle).
- **#2:** campanha com L1 e L2 no checkout `main` em `z0`, a missão do L1 aprovada num worktree
  `fix/l1`, o PR dela `MERGED` e US$ 85 no ledger. Com o worktree vivo: `plan L2`, `US$ 85.00 …
  1 mission(s)`. Depois de `git worktree remove`: `plan L1`, `US$ 0.00 … 0 mission(s)`, os dois rc 0.
- **#3:** delegação legível com `budget_mission_usd: 40` e `budget_campaign_usd: 200`, uma missão
  da campanha com `cost_usd: 190.5` no ledger → `campaign US$ 190.50 of 200.00 — 1 mission(s);
  mission cap US$ 40`, rc 0.

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R11 | #1 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    criteria: ' <<< "$o"); c=$(grep -c '^mut_WORKER_criteria_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` |
| R12 | #2 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    gone: ' <<< "$o"); c=$(grep -c '^mut_WORKER_gone_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` |
| R13 | #3 a #6 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    ceiling: ' <<< "$o"); b=$(grep -c '^  ok    stamp: ' <<< "$o"); c=$(grep -c '^  ok    reuse: ' <<< "$o"); d=$(grep -c 'cinco .R<n>. da REVIEW' KAIZEN_LOG.md); echo "$a $b $c $d"` → `1 1 1 0` |

As cinco famílias são novas: nenhuma linha `done` conta `criteria:`, `gone:`, `ceiling:`, `stamp:`
ou `reuse:`. Não acrescente linhas às famílias que as linhas `done` contam com número exato
(`pr-ready:` 7 do I8, `next:` 5 do I7, `budget:` 3 do I6, `command:` 4 do I9 e do R10, `docs:` 1 do
I10, `worker templates:` 5 do I1). Uma linha nova na tabela `TRANSITION_ROWS` do R60 não muda a
contagem do `command:`, mas o `stamp:` é uma linha `ok` própria.

## O que virou incremento

- **#1 virou `R11`.** O item `review` do `pr-ready` recusa a rodada a que falta a linha de um
  critério e o nomeia no motivo. Os oito nomes do `templates/review.md` (os sete critérios e o
  `Overall`) ficam numa definição só no `bin/sdd-worker`, e o sensor a compara com as linhas do
  template, para as duas nunca divergirem. Linha a mais continua tendo de ser A. Os mundos do sensor
  que hoje montam tabela parcial passam a carregar as oito linhas. O item 1 do `pr-ready` no
  `docs/pipeline.md` diz a regra, e a ADR 0022 §5 já a diz ("grades every criterion A").
- **#2 virou `R12`.** O `campaign_set` acha também as missões que a base carrega: a árvore do
  upstream do checkout da campanha, lida pelo `git` (`ls-tree` e `show`), sem depender de worktree
  nem de checkout atualizado. Assim o `budget` conta o gasto delas e o `next` lê o `branch:` e não
  replaneja o lote. O executor escolhe a leitura, e o que ela não alcança (sem upstream, ref ausente)
  fica declarado no cabeçalho do `campaign_set`, nunca como soma menor calada. Uma `HANDOFF_DIR`
  divergente segue a regra do R7. A frase "until the merge" do `docs/pipeline.md:1857` passa a dizer
  onde a missão mergeada é achada.
- **#3 a #6 viraram o lote `R13`.** (a) `ceiling:`: o comentário do `cmd_budget`, o `docs/pipeline.md`
  (o parágrafo do `budget` e os Declared limits) e o `templates/delegation.md` dizem que o teto da
  campanha é lido antes de cada ato, e que um `run` aberto abaixo dele pode passar dele por até o teto
  de missão assinado (e o runner, por mais uma fase além do próprio teto). Probe de prosa com controle
  negativo, como o `docs:`. (b) `stamp:`: a tabela `## The transitions` ganha a linha do rc 2 de uma
  missão do kit com o PR aberto e só o carimbo faltando, levando-o ao `pr` como o rc 0. A frase da
  retomada pelo diário e a seção "A mission of the kit" dizem o mesmo. (c) `reuse:`: o comentário do
  `cmd_next` e o `docs/pipeline.md` declaram que um PR mergeado de um uso antigo do nome da branch faz
  o lote feito, com a medida 0 de 161. (d) A entrada do `KAIZEN_LOG.md` conta os dez `R<n>`, ou data a
  contagem de cinco na r4.

**Achados da r5, fechados pelos consertos e conferidos aqui:**

- **R6 — `ecc2dee`** (#8, #9, #10, #11, #13, #18). Refeitos por fora do sensor, numa cópia cada:
  - a nota `---` dá `grades ---`, rc 1;
  - um `reviewed_head:` numa branch irmã dá `is not an ancestor of the head`;
  - um commit fora da pasta depois da rodada dá `src.txt changed in … outside docs/handoffs/m1/`;
  - a rodada editada no disco dá `not committed (status ' M')`, e a não rastreada dá `(status '??')`;
  - um recibo mais novo truncado, depois de um bom, dá `the newest receipt … does not parse`.

  `WORKER_receipt_parsed_first` e `WORKER_sep_by_grade` morrem por `--only`. O #13 está declarado no
  cabeçalho do `cmd_pr_ready` e no `docs/pipeline.md`.
- **R7 — `af3babf`** (#3, #4, #5, #21, #24, #37, #38). O conjunto estreito está no `campaign_set`, e
  `WORKER_narrow_every_checkout` morre. O dinheiro sai em centavos (`US$ 190.50` exato na reprodução
  do #3), e o `config_key` entra no checkout antes do `source`.
- **R8 — `600d45c`** (#1, #6, #7, #23, #25). O `lots:` do template dá
  `illegible: lots '<all, ou L1 L2 … separados por espaço>' … '<all,' has no row`. Um PR mergeado de
  fork na branch do lote fica fora, e o `next` responde `run L1`.
- **R9 — `adf68fd`** (#26 a #29, #36). O sensor passa na caixa envenenada (`[ci]q"x @&*$1\`,
  provada armada). O prazo do passo é 550 s, e o sensor rodou aqui em 50 s.
- **R10 — `cbaf6be` e `5fbddec`** (#12, #14 a #17, #19, #20, #30 a #35). As quatro linhas de
  transição, o `setsid -w`, a `campaign-ceiling` só para o gasto medido, o `SDD_GATE_WHY` por
  variável e o L6a a L6k estão no disco, e o `command:` dá 4 linhas. O rc 2 do kit é o #4 desta
  rodada.
- **`5565a41` e `995c4ad`.** Acertaram os esperados do I1 (`worker templates:` dá 5 aqui) e do I9
  (`command:` dá 4).

## O que foi refutado

- **#2 da r5 (o pager herdado), conferido de novo.** O `config_key` sem o terceiro argumento deixa
  o `ON_ESCALATION_CMD` exportado chegar ao subshell quando o arquivo não cita a chave, e o runner faz
  o mesmo. A refutação vale.
- **Linha de critério com menos de quatro células** (`| Security | B`). O `gate_REVIEW` a pula
  (`n < 4`), e o `pr-ready` a lê (`graded` devolve 1, nota `B`, not-ready). É mais estrito, como a
  ADR 0022 quer, e não é achado.
- **Ler o `mergeStateStatus` no lugar do `mergeable`.** A régua §3 diz "o `mergeable` está limpo", e
  o código lê exatamente o campo. Um status vermelho ou uma revisão `CHANGES_REQUESTED` não estão
  na régua, e por isso vão como decisão (pendência 1), não como defeito.

## Achados fora de escopo

- O `gate_REVIEW` do runner tem a régua do #1: o comentário diz "a partial review is not a review" e
  conta linhas, não critérios (`rows > 0`). A missão não edita o `bin/sdd`, então o achado foi
  registrado no `TODO.md` (seção "Sensores que faltam"), com a catraca de 87 para 88, em `d99302e`,
  o `reviewed_head:` desta rodada (2026-11-18).

## Pendências / Decisions for a Human

1. **O que o `pr-ready` não lê.** Ele não lê revisão fora de thread: o corpo de uma revisão do
   CodeRabbit (18 dos 38 achados do PR #414 moravam lá, 17 Minor e 1 Major) e uma revisão
   `CHANGES_REQUESTED` sem comentário inline. Também não lê o estado da suíte no head (o status
   `local/ci` que o `CLAUDE.md` manda publicar). A régua §3 do caderno e a decisão 9 nomeiam só
   threads. Acrescentar um sexto item muda a régua, e a escolha é sua.
2. **O teto da campanha como limite duro.** O R13 só declara o que o código faz hoje. Para não
   passar do teto, o `budget` pode recusar o `run` cujo teto de missão passa do que resta, ou imprimir
   `min(teto, resto)`. A segunda tem uma pegadinha: o `.sdd/config.sh` do worktree vence o ambiente,
   então o `no mission cap` teria de comparar com o teto efetivo.
3. **O `--lot` vem da sessão.** `allows merge --lot L1` sobre o PR do L6a (teto `plan`) responde
   `allowed`, e o `pr-ready` não sabe de lote. Derivar o lote do `lot:` da missão fecha isso (um
   `allows … --mission <dir>`, ou o `ready` imprimindo o lote), e muda a interface.
4. **O worktree da missão de um alvo.** O comando diz "each mission runs in its own worktree", e só
   o `/sdd-plan` do kit cria um. Num alvo, o plano mora no checkout da campanha, e nada diz quem corta
   o worktree antes do `run`.
5. **Seguem as da missão** (`00-missao.md`): assinar a delegação, o pager do kit, o espelho de
   issues, o `aprovacao:` sob `full`, a rule e o carimbo. O merge do PR #414 continua com você
   (decisão 1 da r5).

## Boot da próxima fase

EXEC, um incremento por sessão, na ordem R11 → R12 → R13, no worktree
`/home/joruge/repos/sdd_agents-worker`. Leia a linha do incremento no `checkpoint.md` e o parágrafo
dele em "O que virou incremento" acima; a reprodução de cada achado está em "Reprodução". Cada
achado de código ganha probe na família nomeada e ao menos um mutante `mut_WORKER_<família>_*`,
provado por `tests/check-mutation.sh --only <slug> check-worker.sh`, e uma passada de sabotagem
anotada. As famílias de prosa do R13 carregam controle negativo, como `command:` e `docs:`. Rode
`shellcheck -S warning` nos arquivos tocados antes do commit, e não a suíte inteira: a sessão
orquestradora a roda no fim. Depois do R13, a rodada seguinte é do worker, sobre o head novo, com
`reviewed_head:`.
