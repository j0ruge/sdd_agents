---
missao: 20261117-o-worker-orquestrador
fase: REVIEW
rodada: 7
status: done
sessao: rodada do worker (o ato review do commands/sdd-worker.md), feita por um subagente sdd-reviewer da sessão orquestradora, fora do runner, com escopo delta d99302e..3a77d92 (a skill invocada com base=d99302ecf69c7538834f98051ceda65085664d31, rodada de verificação)
data: 2026-11-18 22:51
gate: tests/run-all.sh no 3a77d92 verde, rodado pela sessão orquestradora (rc 0, suite green, 2164 linhas ok e nenhuma linha FAIL, anchors 901 de 901, 872 s, 22:19:47 a 22:34:19, HEAD igual antes e depois) e run-checks.py sobre as 28 linhas done do checkpoint (28 de 28 no esperado, rc 0, 2378 s); nesta rodada shellcheck -S warning limpo e bash -n rc 0 no bin/sdd-worker, no tests/check-worker.sh e no tests/check-mutation.sh, check-todo.sh rc 0 (90 achados, igual à catraca), segredos (regex e gitleaks, 16 arquivos, 2072 linhas acrescentadas) sem achado, os mundos da r6 refeitos em cópias mktemp (budget US$ 85.00 depois do worktree removido, next plan L2, no room em 190.50 de 200 e em 160.01, merge sobre o L6a ask, merge --lot rc 2), check-checkpoint --check rc 0 e --red com R16 e R17 vermelhos no head; árvore limpa no 3a77d92; nota B, um MEDIUM reproduzido no budget (R16) e um lote de LOW (R17); as letras sobem contra a r6 (Security, Test Coverage e Documentation de B para A), com 6c77751, 254867c, ddcef9d, 7113bbe e 170f818 atrás
reviewed_head: 3a77d92647a2df7b6b1ab4002ab9095bcff839dd
---

# Review — rodada r7 — O worker orquestrador

## TL;DR

Rodada delta do worker sobre `d99302e..3a77d92` (R11 a R15 e os commits de checkpoint), pela régua do dono das 20:30.
Os seis achados da r6 e as quatro decisões das 17:05 fecharam como os parágrafos prometiam, refeitos por fora do sensor.
Um MEDIUM novo, reproduzido num verbo de confiança: o `budget` esquece calado o gasto de uma missão que nunca chegou à base e cujo worktree saiu (R16).
Cinco LOW de forma e de medida viram o lote R17, que não segura a nota. Nada foi consertado aqui.
Nota B em Error Handling e Overall; Security, Test Coverage e Documentation sobem para A.

## Nota da rodada

### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | Os consertos R11 a R15 mantêm uma definição por fato (`LOT_ACTS`, `REVIEW_CRITERIA`, o `tmp_sweep` como único trap de saída, o `base_copies` chamado só pelo `campaign_set`), todo símbolo novo tem leitor e o `shellcheck -S warning` passa limpo nos três arquivos. |
| Type Safety | A | O teto de missão vai a centavos a partir do texto assinado, o lote sai do `lot:` da missão e não da chamada, e flag ou valor fora da forma é rc 2, refeito aqui em cópia. |
| Error Handling | B | O `budget` esquece calado o gasto de uma missão que nunca chegou à base e cujo worktree saiu: US$ 0.00 e 0 mission(s) no lugar de US$ 85, rc 0, sob um teto que o R14 chama de limite duro (achado #1, R16). |
| Security | A | Os dois verbos que concedem fecharam nos mundos da r6: a rodada sem a linha de um critério dá not-ready nomeando o que falta, e `merge` sobre a missão do L6a pergunta (`effective plan`) enquanto `--lot L1` é rc 2. |
| Performance | A | A base custa um `ls-tree` e um `show` por missão, 0,16 s para as 34 missões do kit, e `next` respondeu em 1,3 s sobre a campanha real. |
| Test Coverage | A | As oito famílias novas (criteria, gone, stamp, reuse, blind, cut, ceiling, derived) estão verdes no head, com 20 mutantes novos e passadas de sabotagem anotadas; o mundo do achado #1 chega com o R16 e conta uma vez, em Error Handling. |
| Documentation | A | Os consertos dizem o que o código faz no comando, no `docs/pipeline.md`, na ADR e no template; sobram cinco LOW de forma e de medida, no lote R17, que pela régua da rodada não seguram a nota. |
| **Overall** | **B** | Os seis achados da r6 e as quatro decisões das 17:05 fecharam como prometido; sobra um MEDIUM reproduzido no `budget`, entregue como R16, e o lote R17. |

## Movimento contra a r6

Na r6, cinco linhas abaixo de A (Error Handling, Security, Test Coverage, Documentation e o
Overall); aqui, duas. Security, Test Coverage e Documentation sobem de B para A, nenhuma letra desce,
e há commits de conserto atrás de cada subida (`6c77751`, `254867c`, `ddcef9d`, `7113bbe`,
`170f818`). Error Handling segue em B por um achado novo, não pelo da r6: o #2 da r6 fechou, e o
R16 é a mesma família (a missão que o conjunto não acha) num mundo que o R12 não cobriu. O laço
anda.

## Relatório da skill

- **Round:** verificação sobre `d99302e...3a77d92` (`base=` colado do `40-review-r6.md`,
  `git merge-base --is-ancestor` rc 0, os achados abertos da r6 lidos da tabela dela). Não rodou
  inteira.
- **Secrets Detection:** PASS, 0 linhas (`scan_secrets.sh`, regex e gitleaks, 16 arquivos, 2072
  linhas acrescentadas, nenhum erro).
- **Fase B:** três arquivos de código (`bin/sdd-worker`, `tests/check-worker.sh`,
  `tests/check-mutation.sh`), lidos inline pela sessão, como a skill manda com até três. A varredura
  de código morto também foi inline: as 31 funções e as 7 globais que o delta define têm leitor
  (Bucket A vazio).
- **Verificadores:** dois agentes sobre a prosa, cada um relançado uma vez, como o contrato manda
  quando o `Units read:` fica abaixo do que recebeu. Voltaram curtos nas duas passadas: 43 e 41 de
  46 unidades num, 49 e 29 de 58 no outro, contando unidades vizinhas juntas. Os arquivos deles
  tomaram então o fluxo de hoje, feito inline pela sessão sobre o diff (as regiões mudadas do
  comando e do `docs/pipeline.md` lidas, e as afirmações dos verbos refeitas em cópia), não por um
  agente por arquivo, para manter o custo de uma rodada delta. As duas passadas de cada verificador
  deram os mesmos achados.
- **Fora dos verificadores:** o `40-review-r6.md`, o relatório da rodada anterior, cujas afirmações
  datam do `d99302e`. Os achados dele fecham na seção "O que virou incremento", refeitos aqui.
- **Cost footprint:** quatro verificadores sonnet (cerca de 595 mil tokens somados), nenhum agente
  por arquivo, Fases A, B, B2 e C no modelo principal.

## Achados da rodada

| # | Severidade | Achado | Onde |
|---|---|---|---|
| 1 | MEDIUM | O `budget` esquece calado o gasto de uma missão que nunca chegou à base e cujo worktree saiu (PR fechado sem merge, ou missão largada depois de um `budget-exhausted`): `campaign US$ 0.00 of 200.00 — 0 mission(s)`, rc 0, com US$ 85 no ledger para ela; com o worktree vivo, `US$ 85.00 … 1 mission(s)`. O R14 chama o teto de limite duro, e o R12 prometia que o que a leitura não alcança ficaria declarado, nunca como soma menor calada; nenhum cabeçalho nem documento declara esse mundo | `bin/sdd-worker:645` (`campaign_set`), `bin/sdd-worker:734` (`cmd_budget`), `templates/delegation.md:65`, `docs/pipeline.md:1985` |
| 2 | LOW | A linha `no spend — the upstream <ref> of <checkout> does not read: …` não cobre a falha do `for-each-ref` (que imprime `the upstream of <root> does not read`, sem `<ref>`) nem a cópia que não se faz; e um upstream `[gone]`, o branch remoto apagado depois do merge, é um upstream que não lê (`git ls-tree` rc 128), que para `budget`, `level` e `next`, e que nenhum texto nomeia | `docs/pipeline.md:1965`, `bin/sdd-worker:606` (`base_copies`) |
| 3 | LOW | A medida `0 of 160 merged pull requests … 161` não tem o comando ao lado; o verificador recontou 162 hoje, um PR a mais depois da data que a frase dá | `docs/pipeline.md:2008`, `bin/sdd-worker:902` |
| 4 | LOW | O template que o dono assina diz que a campanha "só passa do assinado pelo que o runner gasta além do próprio teto" e cala o gasto da sessão que orquestra e dos subagentes dela, que os Declared limits do `docs/pipeline.md:2072` e a ADR 0022 (Consequences) põem fora dos dois tetos | `templates/delegation.md:72` |
| 5 | LOW (form) | A linha do R11 no handoff diz que o `gate_REVIEW` do runner "tem a mesma régua", o que se lê como se ele já exigisse os oito critérios; o item do `TODO.md` diz o contrário (tem a mesma lacuna) | `docs/handoffs/20261117-o-worker-orquestrador/20-handoff-exec.md:80` |
| 6 | LOW (form) | O cabeçalho do sensor lista R60 e R63 a R67 como as famílias de prosa com controle negativo e deixa de fora a R68 (`derived: `), que também roda `tree_control` | `tests/check-worker.sh:318` |

### Reprodução

Cada mundo foi montado num `git init` em scratchpad, com um remoto nu, um `gh` falso no `PATH` quando
o verbo o chama e o `bin/sdd-worker` do worktree, e com `SDD_STATE_DIR` apontando para um ledger da
cópia:

- **#1:** campanha `c1` (L1 e L2 sem teto, `budget_mission_usd: 40`, `budget_campaign_usd: 200`), a
  missão `20990101-m1` (`campaign: c1`, `lot: L1`) num worktree `fix/l1` nunca levado à base, e
  `{"mission":"20990101-m1","cost_usd":85}` no ledger. Com o worktree vivo:
  `campaign US$ 85.00 of 200.00 — 1 mission(s); mission cap US$ 40`, rc 0. Depois de
  `git worktree remove --force`: `campaign US$ 0.00 of 200.00 — 0 mission(s); mission cap US$ 40`,
  rc 0. O ledger não tem campo de campanha (tabela do ledger no `docs/pipeline.md`), e o conjunto lê
  só o disco e a base.
- **#2:** num clone cujo branch acompanha `origin/feat`, o `origin/feat` apagado e um
  `git fetch --prune`: `%(upstream)` segue imprimindo `refs/remotes/origin/feat` (`%(upstream:track)`
  dá `[gone]`), e o `git ls-tree` dele sai com rc 128 (`Not a valid object name`).

## Incrementos de conserto (R<n>)

| R<n> | Achado | Check escrito no checkpoint |
|---|---|---|
| R16 | #1 | `o=$(bash tests/check-worker.sh 2>&1); a=$(grep -c '^  ok    discarded: ' <<< "$o"); c=$(grep -c '^mut_WORKER_discarded_' tests/check-mutation.sh); test "$c" -ge 1; echo "$a $?"` → `1 0` |
| R17 | #2 a #6 | `a=$(grep -cF 'upstream <ref> of <checkout> does not read' docs/pipeline.md); b=$(grep -cF '[gone]' bin/sdd-worker); c=$(grep -cF '[gone]' docs/pipeline.md); d=$(grep -cF 'gh pr list --state all' docs/pipeline.md); e=$(grep -c 'subagente' templates/delegation.md); f=$(grep -c 'tem a mesma régua' docs/handoffs/20261117-o-worker-orquestrador/20-handoff-exec.md); g=$(grep -c 'R60 and R63 to R67 carry' tests/check-worker.sh); test "$b" -ge 1 && test "$c" -ge 1 && test "$d" -ge 1 && test "$e" -ge 1; echo "$a $? $f $g"` → `0 0 0 0` |

Os dois nasceram vermelhos no head (`check-checkpoint.sh --red`: R16 imprime `0 1`, R17 `1 1 1 1`).
A família `discarded: ` é nova: nenhuma linha `done` a conta. O R17 não acrescenta linha `ok` a
família nenhuma; a frase do `reuse: ` (a medida no comentário do `cmd_next` e no parágrafo do
`next`) continua tendo de casar `0 of <n> merged pull requests` no mesmo parágrafo.

## O que virou incremento

- **#1 virou `R16`** (MEDIUM, linha própria). A fonte que acharia a missão largada é decisão do dono
  (pendência 1). Até ela, o limite fica declarado onde o leitor do `budget` lê: o cabeçalho do
  `campaign_set` (Declared limits), o comentário do `cmd_budget`, os Declared limits do
  `docs/pipeline.md` e o `templates/delegation.md`, que é o que o dono assina. A frase diz que uma
  missão que nunca chegou à base e cujo worktree saiu não é achada, e que o gasto dela sai da soma.
  O probe monta o mundo da reprodução, nomeia o que o verbo responde e lê as frases, com controle
  negativo como o `reuse: `. Leva um mutante `mut_WORKER_discarded_*` sobre o comentário do `bin/`.
  O achado vai ao `<!-- sdd:open -->` do `TODO.md` como fail-open (D15: escrever não conserta, só
  deixa de mentir), com a direção da pendência 1, e a catraca `tests/health-baseline.txt` sobe junto.
- **#2 a #6 viraram o lote `R17`**, com Check de comando e a suíte, sem passada de sabotagem nem
  mutante (régua do dono, item 3):
  - (a) a linha do upstream que não lê cobre as três grafias, e o `[gone]` fica nomeado no
    cabeçalho do `base_copies` e no `docs/pipeline.md` como upstream que não lê;
  - (b) a medida ganha o comando ao lado;
  - (c) o template nomeia o gasto da sessão que orquestra e dos subagentes dela, fora dos tetos;
  - (d) a frase do handoff vira "a mesma lacuna";
  - (e) o cabeçalho do sensor conta a R68.

**Achados da r6 e decisões das 17:05, fechados pelos consertos e conferidos aqui:**

- **#1 → R11, `6c77751`.** O `round_missing` lê os oito nomes de `REVIEW_CRITERIA`, e o item `review`
  recusa a rodada a que falta um, nomeando-o. A família `criteria: ` está verde no head e monta onze
  mundos, entre eles o da r6 (só o `**Overall**`, que nomeia os sete outros). O sensor segura
  `REVIEW_CRITERIA` igual às linhas do `templates/review.md`, com três controles negativos. As oito
  linhas do template são as do `report-template.md` da skill (2.30.1).
- **#2 → R12, `254867c`.** Refeito por fora do sensor: a missão do L1 levada ao `origin/main`, o
  checkout da campanha atrás e o worktree removido. O `budget` responde `US$ 85.00 … 1 mission(s)`,
  rc 0 (na r6, US$ 0.00), e o `next` responde `plan L2` (na r6, `plan L1`).
- **#3 → R14, `7113bbe`** (decisão 2). Refeito: 190.50 de 200 com teto de missão 40 dá
  `no room — … leaves US$ 9.50, below the mission cap US$ 40 …`, rc 1. Resto igual ao teto
  (160 de 200) abre, rc 0. Um centavo a menos (160.01) para, rc 1, e manda assinar no máximo 39.99.
- **#4 → R13, `ddcef9d`.** A tabela `## The transitions` tem a linha do rc 2 de uma missão do kit,
  com o PR aberto e só o carimbo faltando, levada ao `pr`. A retomada pelo diário e a seção "A mission
  of the kit" dizem o mesmo, e a família `stamp: ` está verde.
- **#5 → R13.** O limite do reuso do nome de branch está no comentário do `cmd_next` e no
  `docs/pipeline.md`, com a medida (`reuse: `). Falta o comando da medida, que é o #3 desta rodada.
- **#6 → R13.** O `KAIZEN_LOG.md` conta quinze `R<n>` (2+2+1+5+3+2 pelas rodadas), e o Check do R13
  dá 0 para a grafia antiga.
- **Decisão 1 → R13, `blind: `.** O cabeçalho do `cmd_pr_ready` e o item do `pr-ready` declaram o que
  ele não lê, e o sexto item está aberto no `TODO.md:164`.
- **Decisão 3 → R15, `170f818`.** Refeito numa delegação assinada em `merge`, com L1 sem teto e L6a em
  `plan`. `allows merge --lot L1` é rc 2 (`allows merge takes --mission <mission-dir>, not --lot`).
  `allows merge --mission <L6a>` dá `ask merge needs merge, effective plan`, rc 1, e a mesma chamada
  sobre uma missão do L1 dá `allowed merge at merge`, rc 0. `plan --lot L6a` dá `allowed plan at plan`,
  `plan --mission` é rc 2, e `approve --mission` dá `ask approve needs full`.
- **Decisão 4 → R13, `cut: `.** O ato `plan` do comando diz que, num alvo, a sessão corta o worktree
  da missão antes do `/sdd-plan`, com o `git worktree add` e o `branch -m` escritos.
- **Interfaces que o delta mudou, procuradas pela grafia antiga** em `bin/`, `tests/`, `commands/`,
  `docs/` e `templates/`:
  - `allows … --lot` fora do `plan` aparece só como exemplo do que era (`docs/pipeline.md:1915`) e
    nos controles negativos do sensor;
  - o `level --lot` ficou como era, de propósito: o `level` informa e não concede ato.

## O que foi refutado

- **A linha `R15` do checkpoint nomeia cinco atos com `--mission`, e o código seis (o `approve`
  também).** Não é achado: a linha é o pedido das 17:05, e a escolha (1) do executor, com o porquê
  (o `sdd approve` roda sobre missão já planejada), está na nota das 21:25 e no handoff. A célula de
  uma linha `done` não se reescreve.
- **Um `allows postmerge --mission` depois de o worktree sair seria rc 2.** É o lado seguro: a
  recusa é rc 2, nunca `allowed`, e o ato `postmerge` roda logo depois do `merge`, com o worktree
  ainda lá, porque o worker nunca remove worktree ("Never").
- **O R14 pararia antes de um `merge` que não gasta.** É a regra declarada ("the stop holds before
  every act, a merge among them") e o lado seguro da decisão 2, não um defeito.

## Achados fora de escopo

- Nenhum novo nesta rodada. O fail-open do achado #1 entra no `TODO.md` pelo R16, porque está no
  escopo da missão e a declaração é dela; a direção sai da pendência 1.

## Pendências / Decisions for a Human

1. **De onde o `budget` acha a missão largada.** O R16 só declara. Para o gasto dela contar, há três
   rotas:
   - (a) o ato `run` grava o id da missão na linha do `journal.md` e o `budget` soma todo id que o
     diário nomeia. Fica dentro da missão, mas o diário é uma linha que a sessão escreve (um rótulo,
     princípio 1), e a campanha do kit guarda as linhas fora do checkout enquanto um run vive;
   - (b) a linha `session` do ledger ganha `campaign:`, lida pelo runner do `00-missao.md`. É o
     artefato que o `budget` já lê, e quem o escreve é o runner, mas pede o `bin/sdd`, que esta
     missão não edita;
   - (c) fica declarado, e o dono que remove o worktree de uma missão largada assina um teto de
     campanha menor pelo que ela gastou.

   Recomendo (b) pelo `TODO.md` (o item do R16 leva essa direção), com o R16 agora.
2. **Seguem as da r6 e da missão.** O `pr-ready` não lê o corpo de uma revisão nem o `local/ci`
   (item aberto no `TODO.md`). Seguem as pendências do `00-missao.md`: assinar a delegação, o pager
   do kit, o espelho de issues, o `aprovacao:` sob `full`, a rule e o carimbo. O merge do PR #414
   continua com você.

## Boot da próxima fase

EXEC, um incremento por sessão, na ordem R16 → R17, no worktree
`/home/joruge/repos/sdd_agents-worker`. Leia a linha do incremento no `checkpoint.md` e o parágrafo
dele em "O que virou incremento" acima. A reprodução do #1 está em "Reprodução".

- **R16** é um achado de código declarado: a família `discarded: ` nova, com controle negativo e um
  mutante `mut_WORKER_discarded_*` provado por `tests/check-mutation.sh --only <slug> check-worker.sh`.
  O item do `TODO.md` entra com a catraca.
- **R17** é o lote de LOW: Check de comando e a suíte, sem passada de sabotagem nem mutante. Não
  quebre a frase que o `reuse: ` lê.

Rode `shellcheck -S warning` nos arquivos tocados antes do commit, e não a suíte inteira: a sessão
orquestradora a roda no fim. Se houver rodada seguinte, ela é do worker, delta, com
`base=3a77d92647a2df7b6b1ab4002ab9095bcff839dd` e esta tabela de achados.
