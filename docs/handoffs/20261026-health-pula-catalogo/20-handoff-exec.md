---
missao: 20261026-health-pula-catalogo
fase: EXEC
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 08:57
gate: `tests/run-all.sh` em `705aa95` (rodada pelo relay) → rc 0, 534 s, 2055 linhas `ok`, 0 `FAIL` (eram 2046 na base `f7f6cc2`); depois dele, `TODO.md`, a pasta da missão e a onda `291d9af`; Checks medidos no HEAD `db5a09a` — I1 → `1` (`check-gates.sh` rc 0, 142 s, 0 FAIL), I2 → `5` (`check-health.sh` rc 0, 48 s), I3 → `1` (`check-mutation.sh --anchors` rc 0, 787 mutantes aplicando), I4 → `1` (`check-hat.sh` rc 0), I5 → `2 0`; `tests/check-checkpoint.sh --check` → `5 row(s), 4 under the anchor rule, none blind`; os cinco incrementos `done`; onda de conserto da revisão final (`291d9af`): `check-health.sh` rc 0 (49 s, 61 ok, 5 `skip:`), `check-gates.sh` rc 0 (148 s, 481 ok, 0 FAIL), `check-hat.sh` rc 0, `check-preflight.sh` rc 0, `check-mutation.sh --anchors` rc 0 (789), `--only HEALTH_skip_writes` e `--only HEALTH_skip_line_unsourced` contra `check-health.sh` → rc 1 antes da asserção e exit 0 depois; a suíte inteira do HEAD da onda é rodada pelo controller (ver nota do checkpoint); ciclo de QA 1 (F1 `c0adac8`, F2 `f98846d`): `tests/run-all.sh` no `6233cc2` (F1, rodada pelo relay) → rc 0, 547 s, 2057 `ok`, 0 `FAIL` (`suite-6233cc2.log`); no `f98846d`, `check-health.sh` rc 0 (47 s, 61 ok, I2 → `5`), `check-gates.sh` rc 0 (148 s, 481 ok, 0 FAIL, I1 → `1`), `check-preflight.sh` rc 0 (94 s, 162 ok, F1 → `1`), `check-mutation.sh --anchors` rc 0 (792, I3 → `1`), I4 → `1`, I5 → `2 0`, F2 → `0` (`--only HEALTH_skip_needs_score check-health.sh`: rc 1 antes dos stubs, exit 0 depois), `--only PRE_path_format_kit_note_never check-preflight.sh` → exit 0, `check-checkpoint.sh --check` → `7 row(s), 5 under the anchor rule, none blind`; a suíte inteira do `f98846d` é do relay
---

# Handoff — EXEC — o `sdd health` pula o catálogo com a chave já medida

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

I1–I5 feitos na worktree, com conserto de revisão em I1–I3, a onda da revisão final (`291d9af`) e o ciclo de QA 1.
O carimbo é um arquivo por chave em `<git-common-dir>/sdd-mutation/stamps/`; o `sdd health` pula o catálogo sobre
chave já medida, e o `--full` força; o mapa mora em `<git-common-dir>/sdd-mutation/killers.tsv`, semeado pelo `.sdd/cache/`.
QA 1: o F1 (`c0adac8`) tira o kit do aviso do git < 2.31 num repo-alvo; o F2 (`f98846d`) mede o pulo sobre a suíte real.
Próximo: a QA de novo (J-target-repo-ships, J-health-verdict); nunca o `sdd` do PATH nem `./bin/sdd health` na worktree.

## Ciclo de QA 1 — F1 e F2

A QA (`199105f`, `30-handoff-qa.md`) percorreu três jornadas num clone isolado e devolveu dois achados sanáveis,
QA-1 → F1 e QA-2 → F2. Os dois estão `done`, cada um com um commit de código e um de checkpoint. O resto deste
handoff descreve o estado antes do ciclo e segue valendo, com as três correções do fim desta seção.

| ID | Commit | O que consertou |
|---|---|---|
| F1 | `c0adac8` (checkpoint `6233cc2`) | o `warn` do `sdd preflight` para git < 2.31 citava o carimbo e o mapa do kit (`mutation_stamp_dir`, `tests/check-mutation.sh`, `killers_paths`) em todo repo, inclusive num repo-alvo. Agora a frase só sai onde `has_mutation_catalogue "$REPO_ROOT"` (`kit_fallback`, `bin/sdd:6487–6493`), a mesma pergunta com que o `gate_PR` limita o carimbo. Duas asserções novas no `check-preflight.sh` (a negativa do Check e o controle positivo) e o `mut_PRE_path_format_kit_note_unscoped` (`if true`) |
| F2 | `f98846d` (checkpoint `f72cad4`) | os stubs que rodam o caminho principal do `sdd health`, o `write_stub_suite` (`tests/check-health.sh`) e o `i4_write_suite` (`tests/check-gates.sh`), imprimiam o `score:` sempre. O `tests/run-all.sh` real só o imprime com `--with-mutation`. Agora os dois o imprimem só com a flag, e o `mut_HEALTH_skip_needs_score` (`if [ "$skip" = 1 ] && [ -n "$score_line" ]; then`) entrou no `CATALOG`: `NOT caught` antes (rc 1, 42 s) e morto depois (exit 0, 42 s e 45 s no commit), por `skip: 1`, `skip: 3` e `skip: 5` |

**O que mudou de mundo no F2.** Só um mundo dependia do `score:` sem flag: a sonda de armação do mundo de dois
scores (bloco 17 do `check-health.sh`), que chamava o stub sem argumento. Com só o stub trocado, o sensor parou em
`SENSOR-BROKEN` (rc 90). A sonda agora passa `--with-mutation`, o argv que o `cmd_health` dá ao catálogo. Os mundos
do catálogo seguem lendo o score, porque o `health_run` sem chave passa a flag, e os mundos do pulo rodam sem score,
como a suíte real. O `check-gates.sh` não teve FAIL com o stub novo. Nenhuma asserção foi enfraquecida e nenhuma
nova entrou; o Check do I2 segue `5`.

**A célula Check do F2 foi corrigida** (decisão do relay, com nota no `checkpoint-notas.md`). A QA a escreveu com
`--only HEALTH_skip_needs_score tests/check-health.sh`, e o harness recusa o caminho sempre, com rc 2: `the sensor
is a file name under tests/, like check-gates.sh (got 'tests/check-health.sh')`. Medi isso com o slug já no
`CATALOG`. Então a célula nunca ficaria verde, e o rc 2 que a QA mediu no HEAD era a recusa do slug, não o vermelho
do sensor. Agora ela diz `check-health.sh`, sem o caminho, e o resto da célula não mudou. O vermelho de verdade
(rc 1, `NOT caught`) foi medido nessa forma antes de tocar nos stubs.

**A carona do Minor da revisão do F1.** O `mut_PRE_path_format_kit_note_never` troca o mesmo `if
has_mutation_catalogue` do `cmd_preflight` por `if false`, que é a frase que nunca sai, nem no kit.
`--only PRE_path_format_kit_note_never check-preflight.sh` → exit 0 (93 s, e 99 s no commit). Numa cópia mutada cai
só o controle positivo (160 ok, 1 FAIL). Com isso as duas direções do escopo têm mutante, e o catálogo foi de 789
para 792 (o `unscoped` do F1 e os dois do F2).

**Âncoras, `CAPTURE_FLOOR` e catraca.** O F1 reancorou 16 âncoras do `TODO.md`, e o F2 reancorou uma
(`tests/check-mutation.sh:7797` → `:7818`, `KILLERS_FILE`). Cada uma aponta para a mesma linha de antes, conferida
com `cmp`. O `--anchors TODO.md` dá `0 off target`, e o `--audit` da skill sai igual antes e depois (só o `RECURRED 7`
conhecido). O `CAPTURE_FLOOR` ficou em 44 e a catraca em 61.

**Re-walks feitos no EXEC**, os dois num clone em `mktemp -d`, removido depois:

- **J-target-repo-ships (F1, S17b):** num repo-alvo com o `./bin/sdd install` da worktree e o shim < 2.31, o `warn`
  termina em `ledger stays correct. Upgrading git removes the extra rev-parse.`, e
  `grep -ciE 'check-mutation|mutation stamp|killer map'` → `0`.
- **J-health-verdict (F2, S1–S2):** o clone do `f98846d` com o stub realista do `30-handoff-qa.md` § O fixture, que
  imprime `score: 792 caught, 0 known gap(s), of 792` só com `--with-mutation`.
  - A 1ª rodada sai rc 0, com argv `--with-mutation`, e grava `stamps/593cd784…`.
  - A 2ª sai rc 0, com argv vazio e uma linha `catalogue skipped — this content (key 593cd784…) was measured green
    (measured: …; root: …; score: 792 …); ./bin/sdd health --full measures it again`. Não aparece nenhum
    `went blind`, e o carimbo sai com md5 e mtime iguais.
  - Contraste: com o mutante commitado no clone, a 2ª rodada sai rc 1, `the suite did not print the 'score:' line —
    health went blind to the mutation`.

**Para a QA que volta.** A rodada é a mesma da QA 1, mais estes dois pontos:

- percorra de novo a **J-target-repo-ships** pelo F1, com a receita S17b do `30-handoff-qa.md`, e confira que a
  frase volta num alvo que tem `tests/check-mutation.sh`;
- percorra de novo a **J-health-verdict** pelo F2, com a receita S1–S2 e o stub realista. O stub da QA 1 já era
  realista, então os outros cenários dela (S3–S19) não mudam com o F2. Quem mudou foram os sensores: a `skip: 3`
  (suíte vermelha no pulo) e a `skip: 5` (worktree) agora rodam sem `score:`, como o S7 e o S13 da QA já rodavam.

**Três correções a este handoff, que valem sobre o texto abaixo:**

- em *Boot da próxima fase*, a receita da verificação end-to-end tem um stub que imprime `score:` sempre, que é a
  forma que o QA-2 condenou. Vale a receita do `30-handoff-qa.md` § O fixture;
- em *O que é visível ao usuário*, o item 7 diz que o aviso do `preflight` para git < 2.31 cita o carimbo e o mapa.
  Desde o `c0adac8`, ele só os cita onde há `tests/check-mutation.sh`;
- o catálogo tem 792 mutantes, e não 789.

**Riscos novos.** O `mut_HEALTH_skip_needs_score` só morre no `check-health.sh`. Contra o `check-gates.sh` ele
sobrevive (`--only … check-gates.sh` rc 1, 159 s, `NOT caught`): os mundos i4 ignoram o rc do `sdd health` e leem o
gate, e um pulo cego mantém a chave. É o desenho, porque o catálogo inteiro roda a suíte toda, e o mapa vai nomear o
`check-health.sh`. Mas é um sensor só. Ninguém mede ainda se outros stubs do kit divergem da suíte real em outra
linha que o `cmd_health` lê (a contagem do `TODO.md`, o `FAIL`). A QA 1 deixou essa pergunta para a REVIEW.

## Estado do repo

- **Branch:** `fix/health-pula-catalogo`, sem upstream, não empurrada. Até o merge, o `sdd` do PATH não é o desta
  branch: ver *A pendência do operador* (a frase vale para o PR e para tudo que vem antes do merge).
- **Último commit de conteúdo:** `291d9af` (a onda de conserto da revisão final: `bin/sdd`, `check-health.sh`,
  `check-mutation.sh` e 13 âncoras do `TODO.md`). Antes dele vieram o `7e68e7d` (o I5, só `TODO.md`) e três commits
  só da pasta da missão: `db5a09a` (checkpoint), `cb98bca` e `68b47a2` (este handoff). Depois dele, só o commit que
  traz esta seção da onda para o handoff.
- **Working tree:** limpa antes do commit deste handoff.
- **Suíte:** `tests/run-all.sh` em `705aa95` → rc 0, 534 s, 2055 `ok`, 0 `FAIL`. Por HEAD, rodada pelo relay:

  | HEAD | rc | s | `ok` | `FAIL` | nota |
  |---|---|---|---|---|---|
  | `f7f6cc2` (base) | 0 | 545 | 2046 | 0 | `baseline-f7f6cc2.log` |
  | `e14a51f` (I1) | 0 | 531 | 2048 | 0 | Check do I1 = 1 |
  | `0a29c20` (I1 r1) | 0 | 539 | 2048 | 0 | Check do I1 = 1; principal limpo, sem `.git/sdd-mutation` |
  | `a70a188` (I2) | 0 | 557 | 2053 | 0 | |
  | `1cd00bd` (I2 r1) | 0 | 538 | 2054 | 0 | `skip:` = 5; principal limpo |
  | `b91b9f5` (I3) | 0 | 536 | 2055 | 0 | `killers:` = 1 |
  | `629bea5` (I3 r1) | 0 | 536 | 2055 | 0 | principal limpo |
  | `705aa95` (I4) | 0 | 534 | 2055 | 0 | Check do I4 = 1 |

  O I5 (`7e68e7d`) mudou só o `TODO.md`: `check-todo` rc 0, `--anchors TODO.md` → `0 off target`, `check-lang`,
  `check-pipefail` e `check-mutation.sh --anchors` rc 0. A onda da revisão final (`291d9af`) rodou os sensores que
  tocou (frontmatter `gate:` e *O que foi feito*); a suíte inteira do HEAD da onda é rodada pelo controller (ver nota
  do checkpoint).
- **E2E:** não se aplica (sem `E2E_CMD`; o kit não tem interface). A rodada à mão está em *Boot da próxima fase*.
- **Checkout principal:** `git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio, e
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/` **não existe**: nenhum `sdd health` real rodou no EXEC
  (medido de novo depois da onda `291d9af`).

## O que foi feito

Antes do I1, as duas ordens do `01-plano.md` § Onde e como, mais a aprovação:

- `f4ac7fd`: o `sdd approve` do humano, com a pasta da missão e a ADR 0021
  (`docs/adr/0021-the-stamp-lives-in-the-common-dir.md`), pelo `adr:` do `00-missao.md`. O `approve` commita o
  arquivo que o `adr:` nomeia: o `case` sobre o `adr_value` em `bin/sdd:9091–9096` (`paths+=( "$adr_value" )`
  em `:9093`), e a mensagem `dim` que o diz em `:9005–9006` (medido em `291d9af`).
- `73420e7`: só o `Amended by: 0021` das ADRs 0004 e 0016, que ficaram fora do commit do `approve`.
- `f7f6cc2`: a `RECURRED 5 → 6` do achado "O `/sdd-plan` delega ao `sdd-planner` sem saída para o agente não
  registrado" (`TODO.md:218`), pedida pelo humano no grill.

Os incrementos (a célula Commit, depois o conserto da revisão):

- `956bd24`, **I1**: o carimbo é `<git-common-dir>/sdd-mutation/stamps/<chave>`, com a primeira linha igual à
  chave e a procedência embaixo (`measured:`, `root:`, a linha `score:`). `mutation_stamp_dir` e
  `mutation_stamp_valid` são a única pergunta do `gate_PR`, da linha 6 do `--release` e (desde o I2) do `cmd_health`.
  O `MUTATION_STAMP_REL` saiu, e ninguém lê nem grava `.sdd/logs/mutation-stamp`. O `check-gates.sh` ganhou o mundo
  14 (a worktree ligada carimba, o principal abre o `gate_PR`, e o arquivo velho sozinho não abre nada), e o
  `check-hat.sh` ganhou a sonda da linha 6. Três mutantes novos.
- `b7667e4`, **I1 r1**: o `git_common_dir_abs` é uma resolução só do `git-common-dir`, lida pelo
  `ledger_repo_root` e pelo carimbo. Antes, o carimbo tinha uma cópia sem sensor, com o braço do git < 2.31. Medido
  idêntico byte a byte em 36 casos. Nenhum mutante novo: cinco reancorados, quatro `LEDGER_repo_root_*`
  (`common_parent`, `cdpath_leak`, `newline_emptied`, `toplevel`) e o `PR_stamp_dir_per_worktree`.
- `19dbe32`, **fora do plano, pedido do dono**: a `RECURRED 6 → 7` do mesmo achado do `/sdd-plan`
  (`TODO.md:225`). A sessão do relay abriu em `rea-projects/`, fora da worktree, e a lista de tipos de agente veio sem
  nenhum `sdd-*`. Por isso o EXEC rodou cada incremento num agente genérico mandado ler `agents/sdd-executor.md`
  como contrato. É a mesma causa (a lista sai de quando a sessão abriu), agora no executor.
- `6dbd63c`, **I2**: o pulo. Uma chave no conjunto roda a suíte rápida **sem** `--with-mutation`, mais a catraca e as
  verificações estáticas, e imprime uma linha que cita `./bin/sdd health --full`. O `--with-mutation` segue sinônimo
  do padrão. O `--full` força o catálogo e é recusado pelo nome junto do `--release`. Só o veredito do catálogo
  apaga a chave (censo, gap, sobrevivente ou TIMED-OUT); uma suíte vermelha deixa o health vermelho e mantém a
  chave. O `check-health.sh` ganhou as cinco asserções `skip:`, o `check-gates.sh` teve os mundos 6 e 7 reescritos,
  e o catálogo ganhou sete mutantes.
- `11fe1fe`, **I2 r1**: os dois Important da revisão. A metade "suíte" do `catalogue_green` ganhou sensor (a metade
  vermelha da `skip: 4` exige que nada seja carimbado; `mut_HEALTH_red_suite_stamps`). A janela do pulo também
  ganhou sensor (o mundo 8b do `check-gates.sh`; `mut_HEALTH_skip_window_blind`).
- `4ae37c9`, **I3**: `killers_paths <raiz>` publica `KILLERS_FILE` (o `git-common-dir`, ou o `.sdd/cache/` fora de
  git) e `LEGACY_KILLERS_FILE`. `load_killer_maps` lê o compartilhado e depois a semente, só para os slugs que o
  compartilhado não conhece, nos três leitores. `write_killer_map` grava por união lida na hora de gravar, só no
  compartilhado. O `killers_selftest` (casos a–d) roda em todo `--anchors`. Âncora `TODO.md:503` reancorada.
- `3e728d6`, **I3 r1**: só comentário. A semente traz de volta o slug que a gravação tirou (medido isolado);
  `write_killer_map`, `launch_order` e o caso (c) do selftest passaram a declarar isso. O código não mudou; a escolha
  vai como pergunta ao dono (abaixo).
- `20ea32e`, **I4**: o passo 2 do `commands/sdd-plan.md` diz que o mapa e o carimbo moram em
  `` `<git-common-dir>/sdd-mutation/` `` e sobrevivem ao `git worktree remove`. Ele não manda mais copiar o mapa
  para a worktree nem trazer nada de volta, e parou de citar a receita do `docs/failure-modes.md`. A
  `command_worktree_return_probes` segura a frase nova e recusa as duas ordens velhas.
- `7e68e7d`, **I5**: ``RESOLVED by 6dbd63c e `11fe1fe` `` no achado do pulo (`TODO.md:32`) e
  ``RESOLVED by 4ae37c9 e `3e728d6` `` no do mapa (`TODO.md:508`). O primeiro hash vai nu (o Check do I5 o lê)
  e o segundo com crase (o `MORE_HASH_RE` da skill `todo-to-github-issues` 2.8.2 só lê o segundo assim). Para
  caber, as linhas 505–508 do item do mapa foram refeitas em 4 sem mudar palavra (provado tirando os dois tokens: o
  texto fica idêntico); o item segue em 8 linhas. A catraca segue 61.

A revisão da branch inteira deu "com consertos": nenhum Critical, dois Important e caronas. Uma onda só, fora da
tabela (nenhuma linha nova no `checkpoint.md`):

- `291d9af`, **onda de conserto da revisão final** (código e sensores):
  - *Important 1, "o pulo não grava" sem sensor.* O `mut_HEALTH_skip_writes` (`catalogue_green=1` na linha que toma
    o pulo, `bin/sdd:7365`) sobrevivia ao `check-health.sh` e ao `check-gates.sh`. Cada pulo regravaria
    `stamps/<chave>` com `measured: <agora>` e o `score:` vazio. Agora a `skip: 1` e a `skip: 3` exigem que nada
    seja carimbado (`! grep -qF "$STAMPED"`, `tests/check-health.sh:1094` e `:1135`). De carona, a `skip: 1` exige
    uma linha `catalogue skipped` **única** e com a procedência `(measured: …`, segurada pelo
    `mut_HEALTH_skip_line_unsourced`. Os nomes das asserções não mudaram, e o Check do I2 segue `5`. Os dois mutantes
    estão no `CATALOG` (789), endereçados a `/^cmd_health() {/,/^}/`. RED: `--only … check-health.sh` → rc 1,
    `NOT caught`, nos dois. GREEN: exit 0 nos dois (44–45 s).
  - *Carona 1:* o comentário sobre a `skip: 4` (`tests/check-health.sh:1145–1149`) agora diz a verdade. O mundo
    `abort:` também roda o catálogo sobre suíte vermelha e score limpo, mas nunca lê o `$STAMPED`.
  - *Carona 2 (D15):* o comentário do `catalogue_against` (`bin/sdd:7434–7443`) declara os braços `gap` e
    `census` inalcançáveis sobre chave carimbada, com a razão. Os mutantes `gap_keeps_key` e `census_keeps_key`
    seriam equivalentes e ficam fora do catálogo.
  - *Carona 3:* a linha 6 do `--release` (`bin/sdd:7264`) diz "the mutation catalogue measured this content green,
    over a suite green in that same run (its key is stamped; --release re-runs nothing)". Ela não afirma mais a
    suíte de agora, nem a catraca, que o `cmd_health` lê só depois de gravar o carimbo (verificação 3). A frase
    vermelha não repetia a ideia e ficou. Nenhum sensor grepa a frase (a `release_probes` lê só `ok`/vermelho da
    `line 6 ·`), então a carona não recuou e a emenda da ADR 0007 ficou fora da lista da DOCS. A linha 6 da tabela
    da ADR 0007 (`:28`) ainda descreve o critério com a frase velha.
  - *Carona 4:* o aviso do `sdd preflight` para git < 2.31 (`bin/sdd:6482–6488`) diz que o carimbo
    (`mutation_stamp_dir`, pelo `git_common_dir_abs`) e o mapa (`killers_paths`) usam o mesmo caminho de reserva. O
    prefixo que o `check-preflight.sh:263` e o `mut_PRE_path_format_warn_silent` leem não mudou.
  - 13 âncoras da seção aberta do `TODO.md` reancoradas pelas linhas que o diff acrescentou. As três da seção
    decidida que o diff empurrou (`:533`, `:537`, `:556`) já não apontavam o símbolo antes da onda, e o sensor não as
    mede: ficaram.

Os commits `chore(checkpoint): …` (`e14a51f`, `0a29c20`, `a70a188`, `1cd00bd`, `b91b9f5`, `629bea5`, `705aa95`,
`db5a09a`) só fecham a linha do checkpoint ou acrescentam uma nota.

**A métrica:**

| | Antes | Depois | Sensor |
|---|---|---|---|
| M1: `^  ok    skip: ` do `check-health.sh` | 0 | 5 | Check do I2 |
| M2: `stamp: gate_PR reads the key a linked worktree stamped…` do `check-gates.sh` | 0 | 1 | Check do I1 |
| M2: `^  ok    killers: ` do `check-mutation.sh --anchors` | 0 | 1 | Check do I3 |
| M3: primeiro `./bin/sdd health` no principal depois do merge | 10 h 58 min (#327) | **não medido** | pendência do humano |
| M4: suíte, catraca, âncoras | verde, 61, `0 off target` | verde em todo HEAD, 61, `0 off target` | tabela acima |

## Artefatos

| Arquivo | O que contém |
|---|---|
| `bin/sdd` | `git_common_dir_abs`, `mutation_stamp_dir`, `mutation_stamp_valid`; `gate_PR`, linha 6 do `--release` e `cmd_health` (opções, pulo, 2c) lendo o lugar novo; a ajuda com `[--full]`; na onda `291d9af`, a linha 6 que afirma só o que a chave prova, o D15 do `catalogue_against` e o aviso do `preflight` para git < 2.31 |
| `tests/check-mutation.sh` | `killers_paths`, `load_killer_maps`, `write_killer_map`, `killers_selftest`; os mutantes novos (789 no catálogo, os dois últimos da onda `291d9af`) |
| `tests/check-health.sh` | `health_run` apaga o lugar e o `stub-argv.txt`; `health_run_keep`; as cinco `skip:` (a 1 e a 3 exigem, desde `291d9af`, que o pulo não grave); o `CAPTURE_FLOOR` com a linha do registro |
| `tests/check-gates.sh` | `fixture_stamps`/`fixture_unstamp`; os mundos 6 e 7 reescritos, o 8b e o 14 |
| `tests/check-hat.sh` | a sonda da linha 6 do `--release`; a `command_worktree_return_probes` reescrita |
| `commands/sdd-plan.md` | o passo 2 (`:49–53`) sem a volta do mapa e do carimbo |
| `docs/adr/0021-the-stamp-lives-in-the-common-dir.md` | a decisão; emenda as 0004 e 0016 |
| `TODO.md` | os dois `RESOLVED by`; a `RECURRED 7` em `:225`; 13 âncoras reancoradas na onda `291d9af` |
| `docs/handoffs/20261026-health-pula-catalogo/checkpoint-notas.md` | uma nota por passo: Red, Green, sabotagens, `--only` de cada mutante |

## Boot da próxima fase

Missão do kit: a QA roda **interativa, na worktree**, com todo comando como
`cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`. Nunca rode `sdd run` do checkout principal,
nem `./bin/sdd status` ou `./bin/sdd run` (eles reavaliam os gates e rodam o `TEST_CMD`). Leia este TL;DR, o
`00-missao.md` § Decisões do grill e a nota do incremento no `checkpoint-notas.md` quando precisar de um porquê.

**Até o merge, só o `./bin/sdd` da worktree lê `sdd-mutation/`; o `sdd` do PATH é o do checkout principal
(`c114e36`) e grava o arquivo velho — sempre `./bin/sdd health`, nunca `sdd health`, nesta worktree.** O porquê e o
custo estão em *A pendência do operador*; vale também para `sdd status`, `sdd why` e `sdd run` do PATH.

**O que é visível ao usuário** (a superfície do operador do kit):

1. **A linha do pulo.** Com a chave no conjunto: a suíte roda sem `--with-mutation`, e a verificação 2 vira uma linha
   só: `ok    mutation: catalogue skipped — this content (key <k>) was measured green (<procedência>); ./bin/sdd
   health --full measures it again` (`bin/sdd:7455`). Uma suíte vermelha no pulo dá `suite red (rc N) — run
   tests/run-all.sh to see it` (`:7383`), as linhas FAIL e rc 1, e a chave fica. O pulo não grava nada (desde
   `291d9af`, a `skip: 1` e a `skip: 3` o exigem).
2. **O `--full`**, que roda o catálogo sobre chave já medida. Verde regrava a chave; o veredito vermelho do catálogo
   a apaga.
3. **A recusa `--full --release`:** `sdd health: --full measures the catalogue, and --release never runs the suite —
   pick one` (`:7319`). A ordem inversa (`--release --full`) não tem teste (Minor adiado). O `die` de opção
   desconhecida lista as três (`:7312`).
4. **A ajuda** (`bin/sdd:12021–12023`): a linha do `sdd health` diz que pula o catálogo sobre chave medida, e ganhou
   `[--full]      run the catalogue anyway, over a key already measured`.
5. **A frase do `/sdd-plan`** (`commands/sdd-plan.md:49–53`): "Copy no killer map into the worktree, and ask for
   nothing to come back after the merge: the map and the stamp live in `<git-common-dir>/sdd-mutation/`, which the
   worktree shares with this checkout, so both outlive `git worktree remove` (ADR 0021)."
6. **A linha 6 do `--release`** (`bin/sdd:7264`), reescrita na onda `291d9af`: verde, ela diz "the mutation
   catalogue measured this content green, over a suite green in that same run (its key is stamped; --release re-runs
   nothing)", e não afirma mais a suíte de agora (um pulo com suíte vermelha mantém a chave). A vermelha não mudou.
7. Menos visível, mas mudou: o `gate_PR` e a linha 6 leem o lugar novo, e a frase do `gate_PR` não mudou; o
   catálogo imprime `== killer map: N …` lendo o compartilhado mais a semente (`check-mutation.sh:8184`, `:8266`); o
   aviso do `sdd preflight` para git < 2.31 (`bin/sdd:6482–6488`) cita o carimbo e o mapa.

**As jornadas tocadas:** `docs/qa/journeys/J-health-verdict.md` (o fluxo ganha o ramo do pulo e do `--full`; o
`:24–25` ainda diz "any existing stamp is REMOVED" e `.sdd/logs/mutation-stamp`) e
`docs/qa/journeys/J-certify-mission-close.md` (`:16` "stamp file == key?", `:21` e `:64` no lugar velho). O texto
delas fica velho de propósito até a fase DOCS: a QA anda pelo comportamento novo e registra a divergência como
deriva de doc da DOCS, não como bug do código.

**Como subir o ambiente:** não há app. O ambiente são os sensores e um fixture.

- `bash tests/check-health.sh` (46–49 s; as cinco `skip:`), `bash tests/check-gates.sh` (142–148 s; mundos 6, 7,
  8b, 14), `bash tests/check-mutation.sh --anchors` (7 s; `killers:` e 789 mutantes aplicando),
  `bash tests/check-hat.sh` (3 s). O `--only <slug> <sensor>` de cada mutante novo já foi rodado e está nas notas.
  Rodar de novo custa minutos por mutante.
- **A verificação end-to-end do plano** (§ Verificação end-to-end), a rodada à mão do pulo sem catálogo, num
  clone isolado. **Ela não rodou no EXEC**, porque o relay proibiu todo `./bin/sdd health` nesta fase.
  **Recomendação da revisão final: rode-a na QA.** Custa segundos e é a M1 fora do sensor. A receita segue o plano,
  e o stub segue a forma do `write_stub_suite` (`tests/check-health.sh:258`):

  ```bash
  d="$(mktemp -d)" && cd "$d" && git clone -q /home/pc_admin/repos/sdd_agents-health-pula-catalogo k && cd k
  n="$(grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' tests/check-mutation.sh)"
  cat > tests/run-all.sh <<EOF
  #!/usr/bin/env bash
  printf '%s\n' "\$*" > "$d/argv"
  printf '%s\n' "score: $n caught, 0 known gap(s), of $n"
  printf '  ok    61 finding(s), all within 8 lines, carrying anchor + date, every anchor on target\n'
  EOF
  git commit -qam 'stub suite' && mkdir -p "$d/home"
  HOME="$d/home" NO_COLOR=1 ./bin/sdd health; cat "$d/argv"   # 1ª: o catálogo; grava a chave
  HOME="$d/home" NO_COLOR=1 ./bin/sdd health; cat "$d/argv"   # 2ª: o pulo
  ```

  O que se lê:
  - depois da 1ª rodada, o argv traz `--with-mutation` e `ls "$d/k/.git/sdd-mutation/stamps/"` mostra uma chave;
  - a 2ª imprime `catalogue skipped … ./bin/sdd health --full measures it again`, e o argv dela vem vazio;
  - `./bin/sdd health --full` volta a passar `--with-mutation`.

  O argv mora fora do clone, mas um arquivo não rastreado também ficaria fora da chave. Com o `HOME`
  redirecionado, outras verificações do health podem sair vermelhas; esta rodada mede só o pulo e o argv. O clone
  tem o próprio `.git`, então nada chega ao `git-common-dir` do kit. Isso é a M1 fora do sensor; a M3 de verdade é
  do humano.
- **Nunca** rode `./bin/sdd health` na worktree nem no checkout principal antes do carimbo do operador, e nunca o
  `sdd health` do PATH nesta worktree (a frase em negrito do começo desta seção). O `./bin/sdd health` grava em
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/`, roda o catálogo de 789 mutantes (cerca de metade das 10 h 58
  com o mapa) e é a pendência dele, depois dos bots.

## Pendências / Decisions for a Human

- **A ressurreição pela semente** (I3, `3e728d6`). Onde a semente `.sdd/cache/mutation-killers.tsv` conhece um slug,
  a leitura seguinte o traz de volta com a linha velha, mesmo depois de a gravação o tirar do compartilhado por não
  ter matador. Medido isolado: compartilhado `{A step1 10}`, semente `{A step9 99}`, `CATALOG=(A)` sem matador; a
  gravação deixa o compartilhado vazio, e a leitura seguinte dá `KILLER[A]=step9 SECS[A]=99`. Junto dela:
  - o matador velho que volta entra em `distinct_killers` (`check-mutation.sh:7637`, +1 controle);
  - `CATALOGUE-BROKEN`, `missing` e `killer_of` vazio também voltam;
  - o `echo` de `:8184` conta as linhas ressuscitadas;
  - a ADR 0021:62–63 "(and leaving when they have no killer, as before)" induz à leitura errada.

  O ruling do relay foi o conserto mínimo: o comentário declara a volta, e o código fica. Custa tempo, nunca
  veredito: o sobrevivente novo roda o matador velho primeiro, em vez de ir na frente. As saídas são do dono:
  - a lápide `slug TAB TAB` muda o formato do mapa, que a Arquitetura fixa ("no formato de hoje");
  - "semente só sem compartilhado" reabre a decisão 4 do grill (ADR 0021 §5);
  - declarar e deixar.

  O custo, se a escolha estiver errada: os sobreviventes do checkout principal saem ordenados pelo matador velho
  até alguém apagar a semente. A declaração na *Consequences* da ADR é da DOCS.
- **A cópia do kit sem `.git` dentro de outro repositório** resolve o `git-common-dir` do **outro** repositório, e
  isso vale para o carimbo (`bin/sdd`) e para o mapa juntos. Ficou fora do escopo por decisão do dono, e não é
  defeito do I3. A pergunta: guardar (exigir que o `--show-toplevel` seja a própria raiz) ou declarar.
- **As pendências do `00-missao.md`.** Duas já foram feitas, antes do I1: as emendas das ADRs (`73420e7`) e a
  `RECURRED 6` (`f7f6cc2`). A pendência "o que o PLAN deixou fora de commit" foi escrita antes do `approve`: a ADR
  0021 já entrou pelo próprio `approve` (`f4ac7fd`). Seguem com o humano o carimbo do operador, a M3 e o chore
  pós-merge, descritos abaixo.

### A pendência do operador

O carimbo da missão, uma vez, depois dos bots (ADR 0015 §1):
`cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && ./bin/sdd health`, com o `bin/sdd` da branch. Ele grava
a chave em `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/stamps/` e lê como semente o mapa de 775 linhas desta
worktree. O health na worktree tem de imprimir
`== killer map: 775 mutant(s) run their last killer first, 775 with a recorded time ==`: é a prova do leitor do
catálogo sobre a semente. Os 14 mutantes novos não têm linha (789 no catálogo).

**Até o merge, só o `./bin/sdd` da worktree lê `sdd-mutation/`; o `sdd` do PATH é o do checkout principal
(`c114e36`) e grava o arquivo velho — sempre `./bin/sdd health`, nunca `sdd health`, nesta worktree.** Medido em
2026-10-26: `~/.local/bin/sdd` aponta para `/home/pc_admin/repos/sdd_agents/bin/sdd`, que ainda tem o
`MUTATION_STAMP_REL` (`:2451`), e o `health_kit_root` velho escolhe a worktree como raiz. Um `sdd health`, ou o hábito
`sdd health --with-mutation` do `CLAUDE.md:299`, digitado aqui roda o `cmd_health` velho: paga o catálogo inteiro sem
pulo e grava `.sdd/logs/mutation-stamp`, que ninguém mais lê. A linha 6 fica vermelha, a M3 se perde, e o principal
paga o catálogo de novo depois do merge. Um `sdd status`, `sdd why` ou `sdd run` do PATH sobre a missão lê o lugar
velho e manda rodar esse mesmo `sdd health` velho. A frase vale para o PR e para tudo que vem antes do merge; o
`sdd` do PATH só passa a ser o kit novo quando o checkout principal avançar para o merge. Depois do carimbo:
- `ls /home/pc_admin/repos/sdd_agents/.git/sdd-mutation/stamps/` mostra a chave da branch;
- `./bin/sdd health --release` na worktree dá a linha 6 verde;
- **M3:** no principal, já avançado para o merge, `./bin/sdd health` dá a linha do pulo em ≤ 20 min. Se outro PR
  mover a chave antes, a M3 se mede no merge seguinte que não a mova.

**O chore pós-merge do `TODO.md`**, da `main`, com a `todo-to-github-issues`: o `--fix --write` apaga os dois itens
quando `6dbd63c`, `11fe1fe`, `4ae37c9` e `3e728d6` estiverem na `main` (o merge tem de ser merge commit: o ciclo de
vida não sobrevive a squash, `TODO.md:128`). A catraca vai de 61 a 59, e o espelho sincroniza. Os dois itens viram
`UPDATE (text)` no plano da branch, por causa do `RESOLVED by` e das linhas refeitas; o título, que é a chave, não
mudou. É também nesse chore que entram os achados do kit da seção abaixo.

## Riscos e não-feitos

- **Nenhum catálogo real rodou no EXEC**, por desenho. Cada mutante novo foi provado por `--only` contra o seu
  sensor (notas), mas a M3 e o mapa compartilhado de verdade só existem depois do carimbo do operador.
- **A transição:** até o primeiro catálogo depois da branch (o carimbo do operador, semeado pela cópia de 775
  linhas), não há mapa compartilhado. Uma worktree nova sem cópia roda sem mapa nesse intervalo, e isso custa só
  tempo.
- **A ressurreição pela semente** está declarada, não consertada (pergunta acima).
- **Duas rodadas do catálogo gravando o mapa no mesmo instante** podem perder uma linha. Está declarado na ADR 0021
  e custa tempo, nunca veredito.
- **A chave não vê troca de máquina nem de ferramenta**; está declarado, e o remédio é o `--full`.
- **A doc conta a regra velha** até a DOCS: as jornadas, o `failure-modes.md`, o `README.md`, o `CLAUDE.md` e o
  `docs/pipeline.md` (lista abaixo).
- **As âncoras de `commands/sdd-plan.md`** no `TODO.md` (nove itens) estão a um passo do símbolo, dentro da
  tolerância de 10, e não foram reancoradas, porque o sensor não sugeriu. Sete estão a −1, e esse −1 vem do I4, que
  encolheu o passo 2. Duas estão a +1 e não vêm do I4: a `:30` (`KIT-TOUCHED`, em `:31`) já estava a +1 antes dele, e
  a `:201` (`Anywhere else`, em `:202`) estava a +2.
- **O `sdd` do PATH é o kit velho até o merge** (`c114e36`): um `sdd health` digitado nesta worktree paga o catálogo
  e grava o lugar velho. A frase e o custo estão em *A pendência do operador*.
- **A suíte inteira do HEAD da onda** (`291d9af`) é rodada pelo controller (ver nota do checkpoint). A última rodada
  inteira registrada neste handoff foi em `705aa95`. Depois dele vieram o `TODO.md`, a pasta da missão e a onda
  `291d9af`, que mexeu no `bin/sdd`, no `check-health.sh`, no `check-mutation.sh` e no `TODO.md`.

## Achados fora de escopo

Todos do **kit** (este repositório). Por decisão do relay, **não** entraram no `TODO.md` desta branch, porque a M4
fixa a catraca em 61. Cada um vai para o **chore pós-merge do `TODO.md`**, com a âncora medida no HEAD `db5a09a` e,
onde a onda `291d9af` a empurrou, medida de novo nele:

- **Um `sed` de mutante que vira no-op passa calado pelo `--anchors`.** O `apply_mutant`
  (`tests/check-mutation.sh:7580`, o `diff -qr` em `:7583`) só exige que `bin/` mude no todo. Num mutante de vários
  `sed`, um deles pode não casar mais e ninguém acusa. Foi medido pelo re-revisor no `cdpath_leak`, cujo 1º `sed`
  virou no-op depois da extração do `git_common_dir_abs` (já reancorado no I1 r1). Ficou em aberto se já era assim
  no `19dbe32`. → chore pós-merge.
- **O "nearest" do `check-todo.sh --anchors` sugeriu a ocorrência errada duas vezes:** `--no-gates` em 7919 em vez
  de 7932, e `KILLERS_FILE` em 7552 em vez de 7640. → chore pós-merge.
- **`load_killer_map` (`tests/check-mutation.sh:152`) lê `A<TAB><TAB>10` como passo `10`**, porque o `IFS` de tab
  colapsa. A união espalha uma linha torta da semente para o compartilhado. Direção: ler com `IFS= read -r` e
  partir por expansão. → chore pós-merge.
- **Pré-existente:** o comentário `tests/check-gates.sh:3782` ("The control file still says `move-the-tree` from
  world 8") já era velho na base. → chore pós-merge.
- **Pré-existente:** o censo do `tests/check-health.sh:85–86` (`grep -n 'sdd" health' tests/*.sh`) não conta a
  forma `./bin/sdd health` (`check-gates.sh:3679`, `check-health.sh:1190`). → chore pós-merge.
- **Lição sem conserto verificado (relay):** o contrato do `sdd-executor` (§2) manda rodar o `TEST_CMD` antes de
  tocar em nada. Só que a suíte leva 531–557 s, e o Bash de um subagente para em 600 s. Por isso o relay rodou a
  suíte por todos os incrementos. → chore pós-merge, como achado do contrato.
- **O `sessao:` de um relay interativo não tem fonte escrita.** O diretório de tarefas em segundo plano
  (`/tmp/claude-1000/<projeto>/<uuid>/tasks/`) leva o uuid da sessão em que o **processo** nasceu (`e2687dd3…`, de
  2026-10-24), e não o da conversa. Este handoff leva `4b9c28f8…`, o transcript que cita a missão (`sessionId` em
  968 linhas) e que um `--resume` reabre. O template diz "serve para --resume" e não diz onde ler o uuid. → chore
  pós-merge.
- **Não é do kit:** na skill `todo-to-github-issues` 2.8.2, o AUTO do `--audit`/`--fix` quebra a linha `RECURRED` em
  120 colunas, e a regra 6 do `check-todo.sh` isenta essa linha (`sensor: before clean → after the AUTO fixes 3
  violation(s)`). → retro da skill (`/retrofit-skill`), não para o `TODO.md`.

## Para a fase DOCS

Do `01-plano.md` § Para a fase DOCS, com o que os incrementos acrescentaram:

- `README.md:173–182`, `CLAUDE.md:299` e `:311` (o mapa em `.sdd/cache/`), `CONTEXT.md:32` (o verbete "Carimbo de
  mutação") e `docs/pipeline.md:528–545`: o lugar velho.
- Os mesmos quatro (`README.md`, `docs/pipeline.md`, `CLAUDE.md:299` e `CONTEXT.md`) precisam também do **pulo** e da
  flag nova **`--full`**, não só do lugar novo: hoje nenhum deles diz que o `sdd health` pula o catálogo sobre chave
  já medida, nem que o `--full` força. O `CLAUDE.md:299` ensina `sdd health --with-mutation` como "a cara", e o
  `--with-mutation` agora é sinônimo do padrão, pulo incluído.
- `docs/failure-modes.md`:
  - a receita da chave (`:1085–1086`, `:1086`) compara com `.sdd/logs/mutation-stamp`;
  - a seção `:1104–1150` ("`sdd health` in the main checkout is slow again after a kit mission") perde o motivo:
    ela ensina a união do mapa e a cópia do carimbo, a `:1114–1115` diz "ADR 0016 tells you to copy the map into
    the worktree" e a `:1140` ensina copiar `<worktree>/.sdd/logs/mutation-stamp`, o que contradiz o `/sdd-plan`
    novo;
  - a `:1003` ("the catalogue came back red, so the stamp was removed") conta a regra velha.
- `docs/qa/journeys/J-health-verdict.md`: o ramo do pulo e do `--full`; a `:24–25` (a janela "any existing stamp is
  REMOVED", `.sdd/logs/mutation-stamp`).
- `docs/qa/journeys/J-certify-mission-close.md:21` e `:64`: o lugar velho.
- A anatomia (`.claude/rules/anatomia-do-agente.md` §6), se ela citar a cópia do mapa.
- A ADR 0021: declarar a ressurreição pela semente na *Consequences* e corrigir a `:62–63` ("and leaving when they
  have no killer, as before").
- A transição: até o primeiro catálogo depois da branch não há mapa compartilhado, e uma worktree nova sem cópia
  roda sem mapa nesse intervalo (só tempo).
- A entrada do `KAIZEN_LOG.md` (K8): antes e depois. O catálogo de 10 h 58 vira o pulo; a volta manual vira
  nenhuma.
- As ADRs 0004 e 0016 já têm o `Amended by: 0021` (`73420e7`).
- Conferir a convenção do status `proposed` da ADR 0021 (`- **Status**: proposed (—, 2026-10-26)`): a 0020 também
  ficou `proposed`, e o achado do `sdd approve` que commita o ADR sem tirar o `proposed` (`TODO.md:370`) é o mesmo
  assunto. A DOCS decide se a 0021 sai `accepted` no PR ou segue a 0020.

## Minor adiados das revisões (para a REVIEW triar)

Nenhum bloqueia; a REVIEW decide se algum vira `R<n>`. Os números de linha são os do HEAD da revisão de cada
incremento e podem ter andado, salvo onde o item diz "medido em `291d9af`": as linhas `== killer map:` do I3, por
exemplo, estão hoje em `:8184` e `:8266`.

**Triagem da revisão final.** Os marcados **consertado em `291d9af`** saíram na onda de conserto. O resto **pode
esperar**, e cada item diz por quê.

- **I1:**
  - nenhum sensor mede a regra "primeira linha igual à chave" do `mutation_stamp_valid` (`bin/sdd:7294–7295`, medido
    em `291d9af`). *Pode esperar:* o nome do arquivo já é a chave, e o runner sempre grava a chave na primeira linha;
    um arquivo com o nome certo e a primeira linha errada só nasce de edição à mão;
  - a sonda da linha 6 (`check-hat.sh:811`) grafa o lugar à mão, sem a guarda de resposta absoluta. *Pode esperar:*
    num git < 2.31 a chave da sonda iria para outro caminho e a metade verde sairia vermelha; ela falha fechada,
    nunca passa sem medir;
  - `fixture_stamps` dá rc 1 num git < 2.31 e o `fixture_unstamp` vira no-op calado, mas o comentário
    (`check-gates.sh:3248–3249`) só fala em "fora de git". *Pode esperar:* é comentário de fixture, e o git < 2.31 já
    é avisado pelo `sdd preflight`;
  - o temporário da gravação mora dentro de `stamps/` (`bin/sdd:7606–7615`, medido em `291d9af`), e um
    `<chave>.tmp.<pid>` órfão conta no `fixture_stamped` (`ls -A`). *Pode esperar:* o órfão só nasce de um kill entre
    o `printf` e o `mv`, e o `mutation_stamp_valid` lê o arquivo pelo nome exato da chave, então um órfão nunca abre
    gate; ele só confundiria a contagem de um fixture;
  - as âncoras do `TODO.md` foram mexidas antes de a skill `todo-to-github-issues` ser carregada (sem dano). *Pode
    esperar:* é só o registro;
  - **consertado em `291d9af`:** o aviso do `sdd preflight` para git < 2.31 citava só o `ledger_repo_root`; agora cita
    o carimbo e o mapa (`bin/sdd:6482–6488`), e saiu da lista da DOCS.
- **I2:**
  - **consertado em `291d9af`:** "o pulo não grava" não tinha asserção. O mutante medido pela revisão final foi o
    `catalogue_green=1` na linha do pulo (`mut_HEALTH_skip_writes`), e não o `&& [ "$skip" != 1 ]` lido aqui. O
    conserto é o previsto: `! grep -qF "$STAMPED"` no `$OUT_SKIP` (a `skip: 1`) e no `$OUT_SKIP_RED` (a `skip: 3`);
  - **consertado em `291d9af`:** a `skip: 1` só pedia `catalogue skipped.*--full`. Agora conta a linha como única e lê
    a procedência `(measured: …` (`mut_HEALTH_skip_line_unsourced`). Fica a ordem `--release --full`, que não tem
    teste. *Pode esperar:* a recusa vem depois do parse inteiro, então a ordem não entra nela por construção, e o
    `mut_HEALTH_full_with_release_accepted` já mata a recusa;
  - o cabeçalho do bloco i4 (`check-gates.sh:3166`) diz que os mundos 2–6 passam com um gate que recusa tudo, mas
    o 6 agora espera `DONE`. *Pode esperar:* é comentário de sensor;
  - as contagens divergem: `check-hat.sh:779` diz "ten handoffs", e `bin/sdd:7297` diz "sixteen handoffs and in
    CLAUDE.md". *Pode esperar:* são dois comentários, e a DOCS pode alinhar a contagem;
  - as `skip: 3` e `4` forjam a chave pela receita, o que falha fechado. A alternativa é o rc do stub num arquivo de
    controle não rastreado, como no `check-gates.sh:3186–3196`. *Pode esperar:* uma receita que derive deixa os
    mundos vermelhos, nunca verdes;
  - **consertado em `291d9af`:** o comentário de `tests/check-health.sh:1138–1140` ("the only world of the kit where a
    catalogue run meets a red suite over a clean score") era falso, porque o mundo `abort:` (`:811–814`) também roda
    esse catálogo. Agora (`:1145–1149`) ele diz que esta é a única que pergunta se esse catálogo carimba;
  - nit: o comentário do mundo 9 (`check-gates.sh:3543`) diz "never a leftover of world 8", mas o anterior agora é o
    8b, que deixa a chave K (o `fixture_unstamp` segura a propriedade). *Pode esperar:* é comentário, e a propriedade
    tem quem a segure.
- **I3:**
  - os `load_killer_maps` dos três leitores não têm sensor durável: a sabotagem sobrevive à suíte rápida (fiação de
    modo, falha ruidosa ou única por clone). Um sensor barato seria `--touched <rev> --list` num fixture com o
    compartilhado ausente e a semente presente (~3 s). *Pode esperar:* o mapa é dica de ordem, e um leitor quebrado
    custa tempo, nunca veredito (ADR 0021 §5);
  - as linhas `== killer map: N …` (`:8160`, `:8242`) passam a contar slugs fora do `CATALOG`. *Pode esperar:* é uma
    linha informativa, que nenhum veredito lê;
  - `bin/sdd:3608–3610` ("ONE resolution … a repair here reaches both") não aponta a cópia do `check-mutation.sh`, e o
    comentário da cópia (`:7754–7756`) diz "copied" sem nomear a recusa de `\n` que ficou de fora
    (`bin/sdd:3656`). *Pode esperar:* são dois comentários;
  - em `:7654`, a recusa do `--touched` nomeia só o compartilhado quando faltam os dois; e o `:7776` ("The seed is
    never written") é falso fora de git, onde os dois são um arquivo só. *Pode esperar:* são uma mensagem e um
    comentário, e a recusa continua recusando;
  - a frase nova (`check-mutation.sh:7778–7783`) restringe a volta a "checkout com semente". Medido: um catálogo que
    não lista o slug copia a linha da semente para o compartilhado (a união, `:7797–7798`), e ela chega a um
    checkout sem semente até um catálogo que liste o slug. É raro e custa só tempo; falta uma oração. *Pode
    esperar:* pelo mesmo motivo, e a DOCS pode levar a oração junto da ressurreição na ADR 0021.
- **I4:**
  - `commands/sdd-plan.md:51` "ask for nothing to come back" diz mais que a justificativa, porque os logs
    `.sdd/logs/<missão>` seguem por worktree. Sugestão: "ask for neither to come back". *Pode esperar:* a ordem que
    importa (não copiar o mapa, não trazer mapa nem carimbo) está certa;
  - `tests/check-hat.sh:585` diz "the presence is read in the step", mas o `sec` é a seção
    `## Before anything else` inteira. *Pode esperar:* é comentário de sensor;
  - a probe fixa a grafia `` `<git-common-dir>/sdd-mutation/` `` com a crase (`check-hat.sh:593`); fica só o registro.
    *Pode esperar:* uma grafia nova deixa a probe vermelha, nunca verde.

### Recusados por julgamento (revisão final)

Levantados pela revisão da branch e recusados, cada um com o motivo. Não voltam como achado sem fato novo.

1. **A janela sob `--full` não apaga a chave.** Decisão do planner (`00-missao.md`, "a janela … não grava nem apaga
   nada").
2. **A corrida de carimbos entre duas worktrees na mesma chave.** Vence o último `rm`/`mv`; fora do plano e raríssimo.
3. **A chave não cobre `commands/`, `CLAUDE.md`, `TODO.md`, `docs/adr` nem `docs/pipeline.md`.** É a confiança herdada
   do `gate_PR`, que sempre leu a chave assim.
4. **Não há aviso sobre o `.sdd/logs/mutation-stamp` órfão.** Depois do merge ninguém mais o lê nem o grava (até lá,
   só o `sdd` do PATH, ver *A pendência do operador*), e ele não abre nenhum gate do kit novo.
5. **O kit sem git nunca pula.** É o desenho (ADR 0021 §1): fora de git não há carimbo.
6. **O TOCTOU entre o pulo e um `--full` concorrente.** É uma corrida entre duas rodadas, como a do item 2: fora do
   plano e raríssima.
7. **Um `stamps/<chave>` que fosse diretório.** Só aparece por sabotagem manual.
