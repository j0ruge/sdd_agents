---
missao: 20261117-o-worker-orquestrador
fase: EXEC
status: done
sessao: ca2c615d-f566-467c-a40f-214652493596 (a sessão orquestradora, fora do runner, escreve a seção da r7 depois do subagente sdd-executor do R17)
data: 2026-11-19 00:19
gate: "no 35a0753 com a ADR em a8b09ee, sensor a sensor, pela sessão orquestradora (a suíte inteira, tests/run-all.sh, roda no head deste handoff antes da r8): tests/check-worker.sh → rc 0, worker verbs: 67 probe(s) em 41 famílias, nenhuma linha FAIL, 95 s; grep -c '^mut_WORKER_' tests/check-mutation.sh → 90; tests/check-todo.sh → rc 0, 91 finding(s), every anchor on target; tests/check-lang.sh e tests/check-adr.sh rc 0; pelo subagente do R16, no 998d077: check-mutation.sh --anchors 903 de 903, os dois mutantes discarded mortos por --only, os Checks I6 R7 R12 R14 no esperado; pelo do R17, no af6b320: os Checks R12 R13 R16 no esperado, shellcheck -S warning limpo; checkpoint 30 de 30 done (I1–I11, F1, F2, R1–R17)"
---

# Handoff — EXEC — O worker orquestrador

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Os onze incrementos, os dois consertos da QA (`F1`, `F2`) e os dezessete da REVIEW (`R1`–`R17`) estão
feitos. `R6`–`R10` consertam os 28 achados reais do CodeRabbit no PR #414 (r5). `R11`–`R15` consertam
os seis da r6 e as quatro decisões do dono das 17:05: o `pr-ready` exige os oito critérios, a missão
mergeada sem worktree segue da campanha (lida na base), o teto da campanha é limite duro (`no room`),
e o lote de um ato sobre uma missão sai do `lot:` dela (`allows … --mission`). `R16` e `R17` fecham
a r7: o `budget` declara a missão largada que ele não acha, e um lote de cinco LOW. O sensor tem 67
asserções em 41 famílias e 90 mutantes; a suíte inteira no head é da sessão orquestradora, que a roda
antes da r8, e nada foi empurrado depois da r5.

## Estado do repo

- **Branch:** `feat/o-worker-orquestrador`, upstream `origin/feat/o-worker-orquestrador` no `3b8c711` (o head do PR #414), 47 commits à frente antes deste handoff, nada empurrado depois da r5
- **Último commit de código:** `af6b320` `fix(worker): o lote de LOW da r7 — o upstream que não lê, a medida com o comando, o terceiro gasto` (R17); o checkpoint dele em `35a0753`, a ADR 0022 §8 em `a8b09ee`, e este handoff num commit logo depois
- **Working tree:** limpo depois do commit do handoff
- **Suíte:** a última corrida inteira é a do `3a77d92` (antes da r7: rc 0, 2164 `ok`, anchors 901 de 901, 14 min 32 s); o `R16` e o `R17` rodaram os sensores que tocaram, não a suíte, e a sessão orquestradora a roda no head deste handoff antes da r8
- **E2E:** não há `E2E_CMD`: o kit é bash e markdown, sem interface

## O que foi feito

- `bdfa30e` — I1: `templates/campaign.md` e `templates/delegation.md` novos, e `templates/missao.md` com as chaves opcionais `campaign:` e `lot:`; três asserções `worker templates:` no `tests/check-templates.sh`
- `f7f99ea` — I2: `bin/sdd-worker` (uso e despacho) e `tests/check-worker.sh`, ligados nos lugares da suíte (`run-all.sh`, os pisos, o censo, o `check-lang.sh`, o catálogo); o `apply_mutant` faz `bash -n` no `bin/sdd-worker`
- `3b6d636` — I3: `delegate`, a leitura de frontmatter, a "legível" e o digest
- `dc66ce2` — I4: `level`, os nove passos do nível efetivo, a escada e a costura `SDD_WORKER_NOW`
- `5bafad6` — I5: `allows`, a tabela de atos (5 níveis × 7 atos, 35 de 35)
- `4095baa` — I6: `budget`, a soma do ledger por `jq`, com as missões achadas também nos worktrees ligados
- `9de910a` — I7: `next`, a fila sobre as missões em disco e o `gh` (`campaign_mission_dirs`, uma definição para o `budget` e o `next`)
- `26adfe4` — I8: `pr-ready`, os cinco itens da régua, e a fixture `tests/fixtures/codex-review-state.txt` copiada do PR 409
- `5721c92` — I9: `commands/sdd-worker.md`, o laço, os sete atos com a chamada `allows`, as cinco paradas, a lista do "nunca" e as regras de contexto
- `30bc8cd` — I10: `docs/pipeline.md` (`## The worker`), `README.md`, `config/schema.md`, `CONTEXT.md` (cinco verbetes), a exceção no `commands/sdd-plan.md` e a nota no roadmap de setembro
- `3fe5d3e` — I11: a campanha `docs/superpowers/campaigns/20261117-zerar-as-issues/` (seis lotes, 83 itens, 24 `◆`, L6 com teto `plan`) e a delegação sem assinatura; a gaveta passa a F6 para "em construção"; o §4 do caderno do worker registra o que a ADR 0022 respondeu

### Ciclo 1 da QA (`F1`, `F2`, dos achados Q1 a Q3 do `30-handoff-qa.md`)

- `42d1a56` — F1 (Q1): o `delegation_terms` é a única definição do que a assinatura concede, as seis chaves e uma linha `ceiling <lote>: <teto>` por linha da tabela de lotes; o `delegate` mostra exatamente o que assina, e subir, baixar, pôr ou tirar o teto de um lote depois de assinar responde `assisted — edited after signing`. Família nova `seal: ` (1 linha), dois mutantes `mut_WORKER_seal_*`. Re-walk da J5 verde numa cópia
- `8add018` — F2 (Q2, Q3): o `id_is_dir` é a regra única do id, o `campaign:` de um arquivo igual ao nome do diretório resolvido (`readlink -f`: `.`, barra no fim e symlink são o diretório). O `delegation_legible` a aplica à `delegation.md` e ao `campaign.md` (o que falta é ilegível), então `level`/`allows` → `assisted`, `budget` → `no ceiling`, `delegate` recusa; o `next` a aplica ao `campaign.md` e para com rc 1 nomeando os dois valores (o ramo do `campaign:` vazio saiu, a regra o cobre). O `expires:` tem de voltar do `date -d` como foi. Família nova `legible: ` (2 linhas), cinco mutantes `mut_WORKER_legible_*`, o fixture do R16 com cada delegação em `<pai>/b-cap`, e o R4 passando a cobrar o motivo da regex. Re-walk da J6 verde numa cópia

### Rodada r1 da REVIEW (`R1`, `R2`, dos achados #1 a #4 do `40-review-r1.md`)

- `328087f` — R1 (#1, HIGH): o `budget` lê o `.sdd/config.sh` do repo da campanha como o runner o carrega, com o teto assinado no ambiente (`config_key` ganhou o terceiro argumento), e sai rc 1 com `no mission cap — <arquivo> sets BUDGET_MISSION_USD=<valor>, …` quando o valor que o `sdd run` aplicaria está acima do teto assinado, em zero, vazio ou fora de número; o starter que o `sdd install` escreve (150) cai aqui. Sem editar `bin/sdd`. Família nova `cap: ` (1 linha), três mutantes `mut_WORKER_cap_*`
- `6bc1755` — R2 (#2, #3, #4): o item `review` do `pr-ready` recusa a linha graduada A cuja justificativa é preenchimento, e o `gate:` de preenchimento ou ausente, pela regra do `gate_REVIEW` (cópia do `PLACEHOLDER_AWK`, comparada com a do runner pelo probe); o `allows` sem `--lot` é rc 2, nomeando a falta; o `delegate` relê os termos depois do `y` e não assina o que mudou com a pergunta aberta, e o digest gravado é o dos termos mostrados. Famílias novas `rationale: `, `lot: ` e `shown: ` (1 linha cada), quatro mutantes (`rationale_*` 2, `lot_optional`, `shown_terms_unchecked`)

### Rodada r2 da REVIEW (`R3`, `R4`, dos achados #1 a #3 do `40-review-r2.md`)

- `7747f6b` — R3 (#1, HIGH): o `budget` aplica a regra do R1 ao `.sdd/config.sh` de todo checkout que o `checkouts_of` lista, o da campanha primeiro e cada worktree ligado depois, guarde ele missão da campanha ou não (o conjunto mais largo, o lado seguro), e a parada nomeia o arquivo do worktree. Família nova `worktree: ` (1 linha), dois mutantes `mut_WORKER_worktree_*`
- `756fed3` — R4 (#2 e #3, LOW): o `round_grades` e o `round_unjustified` dividem a linha pelo `cells()` do `GRADE_ROW_AWK`, cópia do `escaped_pipe` e da reemenda do `gate_REVIEW` — a justificativa `<why \| in one sentence>` deixa de passar, e um critério com `\|` deixa de deslocar um B para fora da coluna da nota (mesmo corte no outro leitor, com o lado aberto pior, consertado junto); o `budget_mission_usd: 0` assinado para o `budget` antes de qualquer config, nomeando a delegação. Famílias novas `pipe: ` (diferencial contra o split do `gate_REVIEW` lido do `bin/sdd`) e `zero: ` (1 linha cada), quatro mutantes (`pipe_*` 3, `zero_signed_unchecked`)

### Rodada r3 da REVIEW (`R5`, do achado #1 do `40-review-r3.md`)

- `7fde4ed` — R5 (#1, MEDIUM): a regra `no pager` do `effective_level` lê o `ON_ESCALATION_CMD` no `.sdd/config.sh` de todo checkout que o `checkouts_of` lista, o da campanha primeiro e cada worktree ligado depois, guarde ele missão ou não (o conjunto do `budget`), e o motivo nomeia o primeiro arquivo vazio; `level` e `allows` respondem pela mesma definição. O ramo fora de checkout git virou guarda própria antes do laço (o `checkouts_of ""` leria os worktrees do cwd) e responde o de antes, `(no repo)`. Família nova `pager: ` (1 linha, o R44 do sensor: worktree com missão, sem missão, o inverso, o controle e o mundo fora de git), dois mutantes `mut_WORKER_pager_*`; o worktree do fixture do R15 ganhou o config do repo do fixture, como um worktree real ganha o config commitado

### Rodada r5 da REVIEW (`R6` a `R10`, dos 38 achados do CodeRabbit no PR #414, `40-review-r5.md`)

- `ecc2dee` — R6 (#8 a #11, #13, #18): o `pr-ready` reconhece o cabeçalho e o separador da tabela pela forma da linha (a nota `---` é lida e não é A), recusa a pasta da missão suja, exige o `reviewed_head:` ancestral do head e cada commit da faixa só na pasta da missão, e lê o recibo mais novo do bot que traz o marcador. Famílias `sep: `, `committed: `, `range: ` e `receipt: `
- `af3babf` — R7 (#3 a #5, #21, #24, #37, #38): o `budget` e o `level` leem só o config do checkout da campanha e dos worktrees que guardam missão dela (o conjunto estreito, decisão do dono), a listagem de worktrees que falha para com rc 1, o dinheiro é contado em centavos, e o `config_key` faz `cd` antes do `source`. Famílias `narrow: `, `listed: `, `spend: ` e `cwd: `
- `600d45c` — R8 (#1, #6, #7, #23, #25): `lots:` é `all` ou lotes da tabela, PR de fork não conta, o merge é lido antes do `approve`, e a edição no meio da assinatura ou do digest não passa. Famílias `lots: `, `fork: `, `stale: `, `kept: ` e `once: `
- `adf68fd` — R9 (#26 a #29, #36): os sensores do worker medem o que dizem sob qualquer `TMPDIR` (o veneno do R58, provado armado), o `check-templates.sh` recusa o frontmatter sem fecho e o lote fora de `## Lotes`, e o prazo do `check-worker.sh` no `run-all.sh` é 550 s, medido; o `4a71667` registrou no `TODO.md` o `git add` cru do `delegate` (catraca 85 → 86), e o `5565a41`, da sessão orquestradora, acertou o esperado do I1 para `5`
- `cbaf6be` — R10, o achado do `4a71667`: o caminho e o id da linha de commit do `delegate` saem por `%q`; o sensor roda a linha sob um git falso no PATH (R59) e cobra um argumento por palavra, nada depois de um add que falha e o newline final; mutante `mut_WORKER_delegate_commit_path_raw`
- `5fbddec` — R10 (#12, #14 a #17, #19, #20, #30 a #35): o comando ganha `## The transitions` (`run` → `pr` → `review` → `merge`, e toda espera de volta ao `budget`), o lançamento por `setsid -w`, a `campaign-ceiling` só para o gasto medido e as linhas que não mediram nomeadas pelo que o verbo imprimiu, o diagnóstico por variável, o `exec_model:` e o `MODEL_EXEC`, o diário fora do checkout do `sdd` do PATH com corrida viva, o recibo do Codex obrigatório na ADR §5, o L6 da campanha do kit em L6a a L6k (um item cada, teto `plan`), e a frase do README e a do `CLAUDE.md` conferidas contra o código. Linha nova `command: ` (R60) e a R32 cobrando #30 e #31; o item do `TODO.md` ganha `RESOLVED by cbaf6be`

### Rodada r6 da REVIEW (`R11` a `R15`, dos achados #1 a #6 do `40-review-r6.md` e das decisões do dono das 17:05)

A r6 é a primeira rodada do worker com `reviewed_head:` (`d99302e`), e deu B por dois HIGH. As quatro
decisões do dono sobre as pendências dela (`71dc576`) refizeram o R13 e criaram o R14 e o R15.

- `6c77751` — R11 (#1, HIGH): o item `review` do `pr-ready` recusa a rodada a que falta a linha de um dos oito critérios do `templates/review.md` (`REVIEW_CRITERIA`, uma definição, na grafia do template) e nomeia todos os ausentes; o critério escrito duas vezes não cobre o que falta, e linha a mais continua tendo de ser A. Família `criteria: ` (R61), três mutantes `mut_WORKER_criteria_*`. O `gate_REVIEW` do runner tem a mesma lacuna e está no `TODO.md` desde `d99302e`
- `254867c` — R12 (#2, HIGH): o `campaign_set` lê também a base (a árvore do upstream do branch do checkout da campanha, pelo git) e materializa o `00-missao.md` de cada missão dela, então o lote mergeado cujo worktree saiu não é replanejado pelo `next` e o gasto dele conta no `budget`; missão em disco e na base é uma só. Upstream que não lê para `budget`, `level` e `next` com rc 1, nomeando-o. Família `gone: ` (R62), três mutantes `mut_WORKER_gone_*`
- `ddcef9d` — R13 (#4 a #6, decisões 1 e 4), prosa e limites: o rc 2 do kit (PR aberto, só o carimbo faltando) leva ao ato `pr` como o rc 0; o `next` declara que o `--head` casa o nome da branch, não o uso (0 de 160 PRs do kit dividem o nome); o `pr-ready` declara o que não lê (o corpo de uma revisão, a `CHANGES_REQUESTED` sem comentário, o `local/ci`), e o sexto item vai ao `TODO.md` (catraca 88 → 89); o ato `plan` diz quem corta o worktree num alvo, e o `approve` roda no worktree da missão. A ADR 0022 §2 e o `KAIZEN_LOG.md` (quinze `R<n>`) acompanham. Famílias `stamp: `, `reuse: `, `blind: ` e `cut: ` (R63 a R66), dois mutantes
- `7113bbe` — R14 (#3, decisão 2): o teto da campanha é limite duro: abaixo dele, o `budget` sai rc 1 com `no room — campaign US$ <gasto> of <teto> leaves US$ <resto>, below the mission cap …` quando o resto, em centavos, não cabe o teto de missão assinado (resto igual ainda abre o run); o comando avisa essa linha como `no-room`, separada da `campaign-ceiling`. Família `ceiling: ` (R67), seis mutantes `mut_WORKER_ceiling_*`
- `170f818` — R15 (decisão 3, nascida da pendência 3 da r6): o `allows` ganha `--mission <dir>`, e o lote de todo ato sobre uma missão que existe (`run`, `pr`, `review`, `merge`, `postmerge` e `approve`) é o `lot:` do `00-missao.md` dela; `--lot` nesses atos é rc 2, e só o `plan` (`LOT_ACTS=(plan)`, escrita positivamente) segue com `--lot`. Missão sem `lot:`, de outra campanha ou de lote fora de `lots:` ou da tabela pergunta (rc 1, nomeando o arquivo); pasta sem `00-missao.md` é rc 2. Família `derived: ` (R68), seis mutantes `mut_WORKER_derived_*`, e o `allows_ignores_lot` e o `lot_optional` reancorados
- `769b593` — a retro da sessão orquestradora sobre a r6, aprovada pelo dono: `RECURRED 1` no item do LOW sem destino, e um item novo sobre a rodada que não passa `base=` à skill (catraca 89 → 90)

### Rodada r7 da REVIEW (`R16`, `R17`, dos achados #1 a #6 do `40-review-r7.md` e da decisão do dono das 23:15)

A r7 é a primeira rodada delta (`d99302e..3a77d92`, `base=` passado à skill), pela régua do dono das
20:30. Ela deu B por um MEDIUM reproduzido no `budget` e abriu um lote de cinco LOW. A pendência 1
dela voltou com a recomendada (`e59e163`): a fonte da missão largada é o `campaign:` na linha
`session` do ledger, que pede o `bin/sdd` e por isso vai ao `TODO.md`.

- `998d077` — R16 (#1, MEDIUM): o `budget` declara que uma missão da campanha que nunca chegou à base e cujo worktree saiu não é achada, e que o gasto dela sai da soma. A frase está no cabeçalho do `campaign_set`, no comentário do `cmd_budget`, nos Declared limits do `docs/pipeline.md` e no `templates/delegation.md`. O remédio escrito é assinar um teto de campanha menor pelo que ela gastou antes de remover o worktree, porque manter o worktree trava o `next` em `stop … closed without merge` (medido com um `gh` falso). O item vai ao `TODO.md` como fail-open, com a direção do dono (catraca 90 → 91). Família `discarded: ` (R69), que fixa as respostas de hoje (102 → 102 → 17 → 10) e fica vermelha no dia em que o ledger levar a campanha; dois mutantes `mut_WORKER_discarded_*`
- `af6b320` — R17 (#2 a #6, lote de LOW, sem sabotagem nem mutante): a linha do upstream que não lê cobre as três grafias que o código imprime, e o upstream `[gone]` fica nomeado no `base_copies` e no `docs/pipeline.md`; a medida do reuso de nome de branch ganha o comando ao lado (`0 of 161 merged pull requests`, de 162, em 2026-11-19 00:00); o template e o `docs/pipeline.md` contam o terceiro gasto fora dos tetos, o da sessão que orquestra e dos subagentes dela; a frase do R11 acima passa a "a mesma lacuna"; o cabeçalho do sensor conta a R68. Uma sexta parte, que o R16 achou: o `KAIZEN_LOG.md` passa a contar dezessete `R<n>`
- `a8b09ee` — a sessão orquestradora acerta a ADR 0022 §8 e as Consequences, que ainda diziam que a campanha só passa do teto pelo excesso do runner (o subagente do R17 apontou e deixou fora do lote)

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd-worker` | o programa: `delegate`, `level`, `allows`, `budget`, `next`, `pr-ready` |
| `tests/check-worker.sh` | o sensor, 67 asserções em 41 famílias (as da QA e as da REVIEW inclusas, até a `discarded: ` do `R16`), com controle negativo nas famílias de prosa (`command: `, `docs: `, `stamp: `, `reuse: `, `blind: `, `cut: `, `discarded: ` e a metade de prosa de `ceiling: ` e `derived: `) |
| `tests/check-mutation.sh` | 90 mutantes `mut_WORKER_*` no `CATALOG` |
| `tests/fixtures/codex-review-state.txt` | o comentário de máquina do Codex, copiado do PR 409 (proveniência no sensor) |
| `commands/sdd-worker.md` | o comando da sessão orquestradora: o laço, `## The transitions`, os sete atos, as cinco paradas |
| `templates/campaign.md`, `templates/delegation.md` | os dois contratos da campanha |
| `docs/superpowers/campaigns/20261117-zerar-as-issues/` | a campanha do kit: `campaign.md` (L1 a L5, e L6a a L6k com teto `plan`) e `delegation.md` sem assinatura |
| `docs/adr/0022-the-worker-is-a-session-orchestrator.md` | a decisão (escrita no PLAN) |
| `docs/handoffs/20261117-o-worker-orquestrador/checkpoint-notas.md` | uma nota por incremento, com as saídas do plano e as sabotagens |

## Boot da próxima fase

**Depois do `R17`: a r7 fecha os seus dois incrementos, e a próxima é a r8, a rodada delta do
worker.** Pela mesma régua do dono de 20:30 (nota `REVIEW` do `checkpoint-notas.md`, `aebbc70`), a r8
lê só `3a77d92..HEAD` e se cada achado da r7 fechou como o R dele dizia, invocando
`/codereview:codereview base=3a77d92647a2df7b6b1ab4002ab9095bcff839dd`. Ela confere também o lote
R17, porque existe pelo R16. Só CRITICAL/HIGH, ou MEDIUM reproduzido num verbo de confiança, abre
rodada. Antes dela, a sessão orquestradora relê os Checks `done` e roda a suíte inteira no head. O
merge continua com o dono. O que mudou e é visível desde a r7:

- **`budget`** (R16): nenhuma resposta mudou. A missão que nunca chegou à base e cujo worktree saiu
  segue fora da soma, e agora o limite está escrito nos quatro lugares onde quem lê o `budget` lê,
  com o remédio (assinar um teto menor antes de remover o worktree).
- **`docs/pipeline.md`, `templates/delegation.md`, ADR 0022 §8** (R17, `a8b09ee`): o upstream
  `[gone]` nomeado como upstream que não lê, e os três gastos que passam o teto da campanha.

E o que mudou na r6:

- **`allows`** (R15): ato sobre missão pergunta por `allows <campanha> <ato> --mission <pasta>`, e o
  lote é o `lot:` do `00-missao.md` dela; `--lot` nesses atos é rc 2. Só `plan` leva `--lot`.
- **`budget`** (R14): a linha nova `no room — campaign US$ … leaves US$ …, below the mission cap …`,
  rc 1, que o comando avisa como `no-room`.
- **`pr-ready`** (R11): recusa a rodada a que falta um dos oito critérios, nomeando todos.
- **`budget`, `level`, `next`** (R12): leem também a base, pelo upstream do branch do checkout da
  campanha; upstream que não lê é rc 1, nomeando-o.
- **`commands/sdd-worker.md`** (R13 a R15): a linha do rc 2 em `## The transitions`, o corte do
  worktree no ato `plan`, o `approve` no worktree da missão, o `no-room` e o `--mission` em cada ato.

As escolhas, os limites e cada sabotagem de `R11`–`R17` estão nas notas do `checkpoint-notas.md`.

**O que vale desde a primeira QA, num repo sem interface.** O que é visível para quem usa o kit:

- **A CLI `bin/sdd-worker`.** Sem verbo, ou com um verbo desconhecido, imprime o uso e sai com rc 2.
  Os seis verbos, as saídas e os rc estão na tabela "Os seis verbos" do `01-plano.md` e em
  `docs/pipeline.md`, `## The worker`.
- **Os templates** `templates/campaign.md` e `templates/delegation.md`, e as chaves `campaign:` e
  `lot:` do `templates/missao.md`.
- **O comando** `commands/sdd-worker.md`, que é prosa para uma sessão interativa: o kit não o instala
  em lugar nenhum.
- **A campanha real.** Os comandos abaixo, rodados da raiz do worktree, respondem assim hoje:
  `bin/sdd-worker level docs/superpowers/campaigns/20261117-zerar-as-issues` →
  `level assisted — illegible: expires '<YYYY-MM-DD HH:MM, hora local>' is not YYYY-MM-DD HH:MM`;
  `budget` → `no ceiling — illegible: …`, rc 1;
  `allows … run --mission /home/joruge/repos/sdd_agents-l1/docs/handoffs/20261117-l1-a-prosa-do-chapeu` →
  `ask run needs pr, effective assisted — …`, rc 1 (o `allows … run --lot L1` é rc 2 desde o R15);
  `allows … plan --lot L2` → `ask plan needs plan, effective assisted — …`, rc 1;
  `next` → `run L1 20261117-l1-a-prosa-do-chapeu — approved, and no pull request of the repository has the head fix/l1-a-prosa-do-chapeu`
  e `ahead plan L2`, rc 0. O `next` acha a missão do L1 porque ela já existe, aprovada (`469971a`), no
  worktree `/home/joruge/repos/sdd_agents-l1`: é o desenho do I7 (as missões são lidas também nos
  worktrees ligados), não um defeito.

**Ambiente.** Nada a subir. O `next` e o `pr-ready` chamam o `gh` real (só leitura) quando rodam
contra o repo de verdade, e o `gh` precisa estar autenticado. O `budget` lê
`${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl`, também só leitura.

**Cuidados que não são opcionais:**

1. **Nunca assine a delegação real.** Exercite o `delegate` numa cópia da campanha em `mktemp -d`,
   dentro de um repo git de fixture com `.sdd/config.sh` (o `tests/check-worker.sh` tem o molde).
   A delegação real é do dono e tem de continuar sem `signed:`.
2. A suíte leva uns 14 min. `pgrep -f run-all` casa a própria sessão `claude -p` (o prompt cita o
   `TEST_CMD`); espere por `pgrep -f '^bash tests/run-all\.sh'` e `tail --pid`.
3. O harness nega `Write` e `Read` fora do repo (seis linhas `DENIED` no `pipeline.log` desta
   corrida, todas sob `/tmp`): rascunho em `mktemp -d` se escreve pelo `Bash`.
4. Esta missão não edita `bin/sdd` nem `agents/`, e não toca `.claude/`.

**Para a DOCS:** a decisão 12 pede que o que aconteceu nesta corrida vá para o caderno do worker
(`docs/superpowers/specs/2026-10-09-o-worker-caderno-de-campo.md`). Medido até aqui: o EXEC andou em
11 sessões, uma por incremento, de 2026-11-17 18:06 a 2026-11-18 01:20, pelo `sdd` do PATH no
worktree ligado, sem `KIT-TOUCHED`, `hat-crossed` nem escalada no `pipeline.log`, com US$ 43,65 nas
10 primeiras (ledger; esta ainda não estava gravada). O arranjo não derrubou a corrida.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

- **Assinar a delegação da campanha do kit**, depois do merge: preencher `level`, `expires` e os dois tetos em `docs/superpowers/campaigns/20261117-zerar-as-issues/delegation.md` e rodar `bin/sdd-worker delegate docs/superpowers/campaigns/20261117-zerar-as-issues` num terminal — o prazo e os tetos são do dono (pendência 1 do `00-missao.md`)
- **Configurar o `ON_ESCALATION_CMD`** do kit: sem ele, todo nível assinado vale `assisted` (pendência 2)
- **Sincronizar o espelho de issues** depois do último merge do dia, pela skill `todo-to-github-issues` (pendência 3)
- **`aprovacao:` sob `full`**: um valor próprio do contrato (`delegated-…`) mexe no `gate_PLAN`, nos templates e no `docs/pipeline.md`; decida se vira missão (pendência 4)
- **A rule `.claude/rules/anatomia-do-agente.md`** recebe texto proposto pela DOCS, como linha ⛔ (pendência 5)
- **O carimbo de mutação não rodou**, pela regra do dono; o `gate_PR` deve sair com rc 2 pedindo `./bin/sdd health`, e isso se lê como "PR pronto para revisão" (pendência 6)
- **A quarta pergunta do §4 do caderno** (missão sem jornada num repo com interface) não foi decidida pela ADR 0022: o caderno a registra como deixada ao W4 (`ENV_UP_CMD`). Decidir se vira missão é seu
- **A missão do L1 já existe aprovada** (`20261117-l1-a-prosa-do-chapeu`, `469971a`, no worktree `~/repos/sdd_agents-l1`): com a delegação assinada, o primeiro ato do worker é `run L1`, não `plan L1`
- **O Check do I9 espera `3`, e a família `command:` imprime `4` desde o R10**, cujo Check (`4`) conta a mesma família: o mesmo conflito entre duas células do plano que o R9 teve com o I1 (acertado em `5565a41`). Acertado pela sessão orquestradora em `995c4ad` (o esperado do I9 passa a `4`)
- **O `--mission` do R15 vale para seis atos, não só para o `merge` da decisão 3:** `run`, `pr`, `review`, `merge`, `postmerge` e `approve` tiram o lote do `00-missao.md`, porque é nos lotes de teto `plan` (L6a a L6k) que o lote dito pela sessão deixava passar também o `run` e a aprovação. Se o dono quiser só o `merge`, é uma linha a mais no `LOT_ACTS` por ato, com os probes da família `derived: ` acompanhando
- **A missão largada da campanha** (pendência 1 da r7, decidida às 23:15 com a recomendada): a linha `session` do ledger ganha `campaign:`, lida pelo runner do `00-missao.md`, e o `budget` soma por ela. Pede o `bin/sdd`, que esta missão não edita, e está no `TODO.md` (item do R16, no `campaign_set`). Até lá, quem remove o worktree de uma missão que não chegará à base assina antes um teto de campanha menor pelo que ela gastou

## Riscos e não-feitos

- **A campanha não tem sensor durável**, por desenho (`01-plano.md`, I11): o Check foi efêmero. Os títulos foram copiados de `5221477:TODO.md`, e nada compara a campanha com o `TODO.md` depois disso: um item retitulado ou um item novo não aparece nela.
- **Os 33 mutantes foram provados um a um com `--only`**, que é dica e não carimbo; o catálogo inteiro e o carimbo são do `./bin/sdd health`, que não rodou.
- **Dois limites que o F2 declara, medidos na sabotagem:** a comparação do que o `date -d` devolve com o que foi escrito não tem mundo no GNU date 9 (ele recusa 24:00, 23:60 e o buraco do horário de verão, e devolve igual todo o resto), e fica para um `date` que role 24:00 para o dia seguinte, com o limite escrito no comentário do `delegation_legible`; e o `${1%/}` do `delegation_legible` só tira a barra dupla do caminho impresso no motivo. Um `date` sem `-d` (o do BSD) faria toda delegação ilegível, isto é, `assisted`: o lado seguro, num kit que já exige Linux para a coordenação.
- **A ADR 0022 §3** diz "a digest of the other fields", e desde o F1 o digest cobre também os tetos dos lotes. O texto ficou menos preciso, não falso; mexer numa ADR aceita fica para a REVIEW ou a DOCS (nota do F1).
- **Os limites declarados na ADR 0022 continuam valendo:** a assinatura prova uma resposta no stdin, não uma pessoa; os tetos leem o ledger desta máquina, e o gasto da sessão orquestradora e dos subagentes fica fora deles; as missões de uma campanha são casadas pelo id, não pelo repositório.
- **O `pr-ready` exige `reviewed_head:`**, que as rodadas da fase REVIEW do `sdd run` não escrevem. Depois de uma corrida ele responde `not-ready review: the newest round names no head` até a rodada da sessão do worker. É desenho (M5 do caderno), não defeito.
- **O `next` não deriva o `postmerge`**, e nenhum verbo age: quem roda, abre PR e mergeia é a sessão.
- **Dois limites que o R2 declara:** o `gate:` ausente é recusado pelo `pr-ready` (o `gate_REVIEW` o deixa passar, para as rodadas anteriores à chave; a do worker nasce do template); e o `allows` sem `--lot` deixou de responder, uma mudança de uso para quem o chamava assim (nenhum chamador do kit: o comando já passava o lote em todo ato). O terceiro, o `\|` que cortava a justificativa, deixou de ser limite com o R4, que também achou o mesmo corte no `round_grades`, com o lado aberto.
- **Dois limites que o R3 declara, no comentário do `cmd_budget`:** um worktree criado depois da chamada não é lido (o laço do comando chama o `budget` a cada volta, então a volta que roda uma missão lê o worktree que o plano dela criou); e um worktree alheio à campanha cujo config vence o teto também para (o lado seguro: o dono conserta o arquivo ou poda o worktree).
- **A reemenda do pipe mora em três lugares** (`checkpoint_rows` e `gate_REVIEW` no `bin/sdd`, `GRADE_ROW_AWK` no `bin/sdd-worker`). Quem segura a do worker igual à do `gate_REVIEW` é o probe `pipe: `, que lê o `escaped_pipe` e o laço do runner e compara os veredictos; o `n > 0 &&` e o `n = 0` da cópia não têm mundo no worker e ficam para ela seguir a do runner linha a linha (notas do `R4`).
- **A regra do preenchimento mora em dois programas** (`bin/sdd` e `bin/sdd-worker`). Quem as segura iguais é o probe `rationale: `, que lê a do runner e compara os veredictos; uma mudança numa só deixa o sensor vermelho.
- **O pager fora do commit agora tem de estar em cada worktree** (R5): o dono que deixa o
  `ON_ESCALATION_CMD` só no checkout da campanha, sem commitar a linha, vê o `level` cair para
  `assisted — no pager` nomeando o worktree da missão, até escrevê-la lá. É a regra da decisão 10
  aplicada onde o runner avisa, e a prosa do `templates/delegation.md` e da campanha do kit diz isso.
  Dois limites no comentário do `effective_level`: worktree sem pasta (prunable) lê sem pager até o
  `git worktree prune` (o lado seguro), e worktree criado depois da chamada não é lido (o laço
  pergunta `allows` antes de cada ato).
- **A catraca está em 90** (`todo-findings 90`): a `b05d039` da `main` a levou a 85, o R9 a 86, a `c90ffc7` (os Checks `done` que nenhum sensor relê) a 87, a `d99302e` (o `gate_REVIEW` que aprova a tabela a que falta um critério) a 88, o R13 (o que o `pr-ready` não lê) a 89 e a `769b593` (a rodada que não passa `base=` à skill) a 90; o item do R9 tem `RESOLVED by cbaf6be` e só sai depois do merge, provado por `git merge-base --is-ancestor`. O R10 e a `769b593` acrescentaram linhas `RECURRED`, que não contam.
- **O comando tem prosa que nenhum probe lê** (R10): o `exec_model:` e o `MODEL_EXEC`, o diário fora do checkout do `sdd` do PATH e o recibo do Codex no ato `pr` foram conferidos à mão contra o código e relidos em todo lugar que repete a frase; o probe cobre as transições, o `setsid -w` e as paradas.

## Achados fora de escopo

> Dois destinos, e a diferença já custou uma `main` vermelha (`2d28d13`).
>
> **Achado sobre o repo-alvo:** registrado no `TODO.md` dele; aqui fica só o ponteiro, para o PR
> conseguir citar.
>
> **Achado sobre o kit** (runner, agente, template), numa missão cujo repo NÃO é o kit: a sessão
> não escreve, não commita e não entra no repositório do kit. A linha **completa** do achado mora
> aqui, marcada `kit:`, e quem a transporta é um humano ou a triagem do `sdd kaizen`. Ponteiro para
> um arquivo que ninguém escreveu é achado perdido.
>
> O exemplo abaixo mora **dentro** desta citação pelo mesmo motivo que o `- intervention:` do
> `checkpoint.md` (`cd49351`): exemplo que abre a linha com `-` é contado verbatim por quem vier
> varrer os handoffs atrás de `kit:`, e todo handoff nasceria devendo um achado fantasma. Copie a
> forma para fora da citação ao registrar um achado de verdade.
>
> - kit: <o quê> — <arquivo:linha do kit> — <por que importa>

Esta missão é do próprio kit, então não há linha `kit:`. Os dois achados abaixo **não** entraram no
`TODO.md`, pela régua de admissão do D15, e cada um diz por quê:

- **O limite declarado do `health_provenance` conta uma fixture de terceiro a menos.** `bin/sdd:7862` declara "the kit has a fourth captured third-party fixture and this function does not reach it" (o `acli-workitem-search-done.json`), e o I8 trouxe a quinta, `tests/fixtures/codex-review-state.txt`, que também não é alcançada. A linha de resumo do `sdd health` fala só das fixtures "das skills instaladas", então nenhum sensor afirma medir o que não mede: pelo D15 é limite a escrever no cabeçalho da função, não item do backlog. Esta missão não edita `bin/sdd`. A rota é a próxima missão que tocar o `bin/sdd` (o L4 da campanha, "Preflight, health e sensores", é a vizinhança): acrescentar a quinta ao `DECLARED LIMIT`, onde a proveniência dela já está escrita ao lado do probe do `tests/check-worker.sh`.
- **Para a DOCS, uma deriva anterior a esta missão:** o verbete "Carimbo de mutação" do `CONTEXT.md` diz que a chave "cobre 4 dos 8 caminhos que a `sandbox()` copia" (#67), e a `sandbox()` já copiava mais de 8 antes do I10, que lhe acrescentou o `README.md` e o `CONTEXT.md`. É prosa do `CONTEXT.md`, que a DOCS escreve.
