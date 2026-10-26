---
missao: 20261026-health-pula-catalogo
fase: EXEC
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 09:20
gate: `tests/run-all.sh` em `705aa95` (rodada pelo relay) → rc 0, 534 s, 2055 linhas `ok`, 0 `FAIL` (eram 2046 na base `f7f6cc2`); depois dele, `TODO.md`, a pasta da missão e a onda `291d9af`; Checks medidos no HEAD `db5a09a` — I1 → `1` (`check-gates.sh` rc 0, 142 s, 0 FAIL), I2 → `5` (`check-health.sh` rc 0, 48 s), I3 → `1` (`check-mutation.sh --anchors` rc 0, 787 mutantes aplicando), I4 → `1` (`check-hat.sh` rc 0), I5 → `2 0`; `tests/check-checkpoint.sh --check` → `5 row(s), 4 under the anchor rule, none blind`; os cinco incrementos `done`; onda de conserto da revisão final (`291d9af`): `check-health.sh` rc 0 (49 s, 61 ok, 5 `skip:`), `check-gates.sh` rc 0 (148 s, 481 ok, 0 FAIL), `check-hat.sh` rc 0, `check-preflight.sh` rc 0, `check-mutation.sh --anchors` rc 0 (789), `--only HEALTH_skip_writes` e `--only HEALTH_skip_line_unsourced` contra `check-health.sh` → rc 1 antes da asserção e exit 0 depois; `tests/run-all.sh` no `096c625` (o HEAD da onda, rodada pelo relay) → rc 0, 541 s, 2055 `ok`, 0 `FAIL` (`suite-096c625.log`); ciclo de QA 1 (F1 `c0adac8`, F2 `f98846d`): `tests/run-all.sh` no `6233cc2` (F1, rodada pelo relay) → rc 0, 547 s, 2057 `ok`, 0 `FAIL` (`suite-6233cc2.log`); no `f98846d`, `check-health.sh` rc 0 (47 s, 61 ok, I2 → `5`), `check-gates.sh` rc 0 (148 s, 481 ok, 0 FAIL, I1 → `1`), `check-preflight.sh` rc 0 (94 s, 162 ok, F1 → `1`), `check-mutation.sh --anchors` rc 0 (792, I3 → `1`), I4 → `1`, I5 → `2 0`, F2 → `0` (`--only HEALTH_skip_needs_score check-health.sh`: rc 1 antes dos stubs, exit 0 depois), `--only PRE_path_format_kit_note_never check-preflight.sh` → exit 0, `check-checkpoint.sh --check` → `7 row(s), 5 under the anchor rule, none blind`; `tests/run-all.sh` no `8328a7e` (o código do F2, rodada pelo relay) → rc 0, 714 s, 2057 `ok`, 0 `FAIL` (`suite-8328a7e.log`)
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
QA-1 → F1 e QA-2 → F2. Os dois estão `done`, cada um com um commit de código e um de checkpoint. As outras seções
deste handoff contam o estado depois do ciclo: números de linha medidos no `f98846d`, catálogo de 792.

| ID | Commit | O que consertou |
|---|---|---|
| F1 | `c0adac8` (checkpoint `6233cc2`) | o `warn` do `sdd preflight` para git < 2.31 citava o carimbo e o mapa do kit (`mutation_stamp_dir`, `tests/check-mutation.sh`, `killers_paths`) em todo repo, inclusive num repo-alvo. Agora a frase só sai onde `has_mutation_catalogue "$REPO_ROOT"` (`kit_fallback`, `bin/sdd:6487–6493`), a mesma pergunta com que o `gate_PR` limita o carimbo. Duas asserções novas no `check-preflight.sh` (a negativa do Check e o controle positivo) e o `mut_PRE_path_format_kit_note_unscoped` (`if true`) |
| F2 | `f98846d` (checkpoint `f72cad4`) | os dois stubs em que o `sdd health` chega ao pulo, o `write_stub_suite` (`tests/check-health.sh:262`) e o `i4_write_suite` (`tests/check-gates.sh:3288`), imprimiam o `score:` sempre. O `tests/run-all.sh` real só o imprime com `--with-mutation`. Agora os dois o imprimem só com a flag, e o `mut_HEALTH_skip_needs_score` (`if [ "$skip" = 1 ] && [ -n "$score_line" ]; then`) entrou no `CATALOG`: `NOT caught` antes (rc 1, 42 s) e morto depois (exit 0, 42 s e 45 s no commit), por `skip: 1`, `skip: 3` e `skip: 5` |

**O que mudou de mundo no F2.** Só um mundo dependia do `score:` sem flag: a sonda de armação do mundo de dois
scores (bloco 17 do `check-health.sh`), que chamava o stub sem argumento. Com só o stub trocado, o sensor parou em
`SENSOR-BROKEN` (rc 90). A sonda agora passa `--with-mutation`, o argv que o `cmd_health` dá ao catálogo. Os mundos
do catálogo seguem lendo o score, porque o `health_run` sem chave passa a flag, e os mundos do pulo rodam sem score,
como a suíte real. O `check-gates.sh` não teve FAIL com o stub novo. Nenhuma asserção foi enfraquecida e nenhuma
nova entrou; o Check do I2 segue `5`.

**Um terceiro stub ficou como estava, e é inofensivo.** O do `TREE_KIT` (`tests/check-gates.sh:3743–3748`), o kit
instalado do bloco da árvore, ainda imprime `$I4_SCORE_GREEN` sem olhar a flag. Ali nunca há pulo: o `tree_health`
(`:3780`) tira todo carimbo do `$FIX`, do `TREE_KIT` e do `TREE_PLAIN` antes de cada rodada (`fixture_unstamp`,
`:3783`), então todo `sdd health` desse bloco roda o catálogo, onde a suíte real também imprime o `score:`. Se um
mundo dele passar a pular, o stub precisa da mesma condição dos outros dois.

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

**Âncoras, `CAPTURE_FLOOR` e catraca.** O F1 reancorou 16 âncoras do `TODO.md`, e o F2 reancorou uma: a do
`KILLERS_FILE` (`TODO.md:503`), que o diff do F2 empurrou 21 linhas e hoje é `tests/check-mutation.sh:7818`. Cada
uma aponta para a mesma linha de código de antes, conferida com `cmp`. O `--anchors TODO.md` dá `0 off target`, e o `--audit` da skill sai igual antes e depois (só o `RECURRED 7`
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
  - A receita de *Boot da próxima fase*, copiada como está, deu o mesmo no `8328a7e`. O `--full` voltou a passar
    `--with-mutation` e regravou o carimbo, e o `echo 1 > "$d/rc"` deu rc 1 com `suite red (rc 1) — run
    tests/run-all.sh to see it` e a chave mantida.

**Para a QA que volta.** A rodada é a mesma da QA 1, mais estes dois pontos:

- percorra de novo a **J-target-repo-ships** pelo F1, com a receita S17b do `30-handoff-qa.md`, e confira que a
  frase volta num alvo que tem `tests/check-mutation.sh`;
- percorra de novo a **J-health-verdict** pelo F2, com a receita S1–S2 e o stub realista. O stub da QA 1 já era
  realista, então os outros cenários dela (S3–S19) não mudam com o F2. Quem mudou foram os sensores: a 2ª rodada
  da `skip: 1` (o pulo), a `skip: 3` (suíte vermelha no pulo) e a `skip: 5` (worktree) agora rodam sem `score:`,
  como o S2, o S7 e o S13 da QA já rodavam.

**Riscos novos.** O `mut_HEALTH_skip_needs_score` só morre no `check-health.sh`. Contra o `check-gates.sh` ele
sobrevive (`--only … check-gates.sh` rc 1, 159 s, `NOT caught`): os mundos i4 ignoram o rc do `sdd health` e leem o
gate, e um pulo cego mantém a chave. É o desenho, porque o catálogo inteiro roda a suíte toda, e o mapa vai nomear o
`check-health.sh`. Mas é um sensor só. Ninguém mede ainda se outros stubs do kit divergem da suíte real em outra
linha que o `cmd_health` lê (a contagem do `TODO.md`, o `FAIL`). A QA 1 deixou essa pergunta para a REVIEW.

## REVIEW r1 — R1

A REVIEW r1 (`4a3d412`, `40-review-r1.md`) deu Overall B e juntou os LOW baratos #3–#6 num `R1` de lote, com quatro
Checks, todos vermelhos no `9a7ee1b` e de novo no `4a3d412` (`0 0 0 0`; `check-gates.sh` rc 0, 140 s, 481 ok). O R1
está `done` num commit de código, `96fd555`, que só toca `tests/` (checkpoint `500cdf7`). Os quatro Checks, rodados como a
célula os escreve, deram `1 1 1 1`. O `check-gates.sh` deu rc 0, 149 s, 483 ok (481 + as 2 asserções novas) e 0 FAIL,
e o `check-health.sh` deu rc 0, 52 s, 61 ok. O estado do repo depois do merge `9a7ee1b` segue no `40-review-r1.md`
§ *O estado depois do merge*, e não foi copiado para cá.

| Achado | O que consertou |
|---|---|
| #3 | Uma guarda logo depois do `fixture_stamped` (`tests/check-gates.sh:3274–3288`), antes de qualquer mundo ler um carimbo. Se o `fixture_stamps "$FIX"` não der um caminho absoluto (git < 2.31, que responde relativo, ou `$FIX` fora do git), o sensor cai em `SENSOR-BROKEN: stamp: …`. Se der, imprime o `ok` que o Check lê. Tem a forma do `wt_dirty` do mundo 14 e uma metade `ok`. Sem ela, as metades `absent` dos mundos 8, 8b, 9, 12 e 13 e o `tree_stamped "$TREE_PLAIN"` passavam sem resposta. |
| #4 | O mundo 7b, logo depois do 7 (`:3515–3527`). O 7 lista o lugar antes da remoção (`:3509–3511`). O 7b pega o único nome que saiu dali, roda `i4_verdict 0 "$I4_SCORE_GREEN"; i4_health --full` e exige que o arquivo dessa chave tenha voltado, com a própria chave na 1ª linha (o que o `mutation_stamp_valid` compara). Lê o artefato, não a fase. A asserção é própria, fora do tally, e não abre sítio novo de `sdd health`. O mundo 8 segue começando pelo `fixture_unstamp`. |
| #5 | O cabeçalho do bloco (`:3163–3188`) agora conta e lista todos os mundos com asserção própria. Depois do tally são nove: os sete da chave e do lugar, com `A LINKED WORKTREE (14)`, mais o 8b e o 9b. Dentro do tally ficam o 1b, o 4b e o 7b. "three pairs plus one" virou "two pairs, a triple and one", e o "in all eight" da `:3753` virou "every one of them", com o mundo 14. |
| #6 | O censo (`tests/check-health.sh:82–93`) nomeia as duas grafias e mede `13 sites`: 11 de `"$X/bin/sdd" health` e 2 de `./bin/sdd health` que rodam o comando (`check-gates.sh:3724`, `check-health.sh:1199`). O driver Python do `check-coordination.sh` fica nomeado e fora da conta. Medi de novo depois das edições e deu 13: o R1 não abriu sítio. |

**Sabotagem.** O diff acrescenta 13 linhas de código. Degradei cada uma, uma por vez, numa cópia da worktree sem
`.git`: foram 14 sabotagens, e o `esac` só admite erro de sintaxe. Treze deixaram uma probe vermelha. A 14ª tirou o
`--full` do 7b e é equivalente: depois que o mundo 7 tira a chave não há pulo, e o `cmd_health` roda o mesmo catálogo
com ou sem a flag. As degradações do tipo sempre-passa só aparecem num mundo defeituoso, e para elas usei três
mundos de controle. O primeiro é o `fixture_stamps` cego, sem `--path-format`, a resposta relativa do git < 2.31. O
segundo é uma trava no `bin/sdd`: a remoção deixa `<chave>.removed`, e a gravação recusa enquanto ele existe. O
terceiro é uma remoção que não acontece, o `mut_HEALTH_survivor_keeps_key`. Sob a trava, o 7b é a única asserção do
`check-gates.sh` que cai. No mundo cego, o sensor já caía sem a guarda, mas em cinco asserções que culpavam o gate. A
guarda põe o nome da causa numa linha. Cada sabotagem tem a sua linha no `checkpoint-notas.md`.

**Mutante.** Não entrou mutante no `CATALOG`, porque não existe um natural. A regra de gravação do `cmd_health` não
guarda estado entre rodadas. A remoção é um `rm -f` que não deixa rastro, e a gravação lê só o veredito desta rodada
(`catalogue_green`, `catalogue_against`) e a chave. Uma trava precisaria gravar uma lápide num lugar e lê-la em outro,
ou seja, duas edições, não um sítio só. O mundo de controle "trava" é essa forma de duas edições, e o 7b o pega.

**Âncoras e catraca.** Nenhuma âncora do `TODO.md` aponta para `tests/check-gates.sh` ou `tests/check-health.sh`, e o
`check-mutation.sh` não mudou. Por isso o `--anchors TODO.md` deu `62 measured, 0 off target` sem reancorar nada, e o
`--audit` da skill deu o mesmo de antes (a `RECURRED 7`, conhecida). A catraca segue em 62.

**Próxima:** a REVIEW r2, que reavalia o R1 sem tê-lo escrito. O boot dela é o do `40-review-r1.md`, e só o
estado do R1 muda: a tabela de incrementos não tem mais linha `pending`.

## Estado do repo

- **Branch:** `fix/health-pula-catalogo`, sem upstream, não empurrada. Até o merge, o `sdd` do PATH não é o desta
  branch: ver *A pendência do operador* (a frase vale para o PR e para tudo que vem antes do merge).
- **Último commit de conteúdo:** `f98846d` (o F2: os stubs do `check-health.sh` e do `check-gates.sh`, dois mutantes
  no `check-mutation.sh` e uma âncora do `TODO.md`). Antes dele vieram o `c0adac8` (o F1: `bin/sdd`,
  `check-preflight.sh`, um mutante e 16 âncoras do `TODO.md`) e o `291d9af` (a onda de conserto da revisão final:
  `bin/sdd`, `check-health.sh`, `check-mutation.sh` e 13 âncoras). Entre eles e depois deles, só commits da pasta da
  missão: `2d5d31a` (este handoff), `096c625` (nota), `199105f` (o handoff da QA e as linhas F1–F2), `6233cc2` e
  `f72cad4` (checkpoint), `8328a7e` e o commit desta reescrita (este handoff).
- **Working tree:** limpa antes do commit deste handoff.
- **Suíte:** `tests/run-all.sh` em `8328a7e` (o código do F2) → rc 0, 714 s, 2057 `ok`, 0 `FAIL`. Por HEAD,
  rodada pelo relay (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-<HEAD>.log`):

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
  | `cb98bca` (I5 e handoff) | 0 | 538 | 2055 | 0 | o I5 (`7e68e7d`) só mudou o `TODO.md` |
  | `096c625` (onda `291d9af`) | 0 | 541 | 2055 | 0 | a suíte que a QA leu |
  | `6233cc2` (F1) | 0 | 547 | 2057 | 0 | as duas asserções do F1 |
  | `8328a7e` (F2) | 0 | 714 | 2057 | 0 | o F2 não acrescentou asserção |

- **E2E:** não se aplica (sem `E2E_CMD`; o kit não tem interface). A rodada à mão está em *Boot da próxima fase*.
- **Checkout principal:** `git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio, e
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/` **não existe**, medido de novo depois do F2. Nenhum
  `./bin/sdd health` rodou na worktree nem no principal; ele só rodou em clones isolados (`mktemp -d`), no re-walk do
  F2 e no percurso da QA.

## O que foi feito

Antes do I1, as duas ordens do `01-plano.md` § Onde e como, mais a aprovação:

- `f4ac7fd`: o `sdd approve` do humano, com a pasta da missão e a ADR 0021
  (`docs/adr/0021-the-stamp-lives-in-the-common-dir.md`), pelo `adr:` do `00-missao.md`. O `approve` commita o
  arquivo que o `adr:` nomeia: o `case` sobre o `adr_value` em `bin/sdd:9099–9104` (`paths+=( "$adr_value" )`
  em `:9102`), e a mensagem `dim` que o diz em `:9014–9015`.
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
    o pulo, `bin/sdd:7374`) sobrevivia ao `check-health.sh` e ao `check-gates.sh`. Cada pulo regravaria
    `stamps/<chave>` com `measured: <agora>` e o `score:` vazio. Agora a `skip: 1` e a `skip: 3` exigem que nada
    seja carimbado (`! grep -qF "$STAMPED"`, `tests/check-health.sh:1098` e `:1139`). De carona, a `skip: 1` exige
    uma linha `catalogue skipped` **única** e com a procedência `(measured: …`, segurada pelo
    `mut_HEALTH_skip_line_unsourced`. Os nomes das asserções não mudaram, e o Check do I2 segue `5`. Os dois mutantes
    entraram no `CATALOG`, que foi a 789, endereçados a `/^cmd_health() {/,/^}/`. RED: `--only … check-health.sh` →
    rc 1, `NOT caught`, nos dois. GREEN: exit 0 nos dois (44–45 s).
  - *Carona 1:* o comentário sobre a `skip: 4` (`tests/check-health.sh:1147–1153`) agora diz a verdade. O mundo
    `abort:` também roda o catálogo sobre suíte vermelha e score limpo, mas nunca lê o `$STAMPED`.
  - *Carona 2 (D15):* o comentário do `catalogue_against` (`bin/sdd:7443–7452`) declara os braços `gap` e
    `census` inalcançáveis sobre chave carimbada, com a razão. Os mutantes `gap_keeps_key` e `census_keeps_key`
    seriam equivalentes e ficam fora do catálogo.
  - *Carona 3:* a linha 6 do `--release` (`bin/sdd:7273`) diz "the mutation catalogue measured this content green,
    over a suite green in that same run (its key is stamped; --release re-runs nothing)". Ela não afirma mais a
    suíte de agora, nem a catraca, que o `cmd_health` lê só depois de gravar o carimbo (verificação 3). A frase
    vermelha não repetia a ideia e ficou. Nenhum sensor grepa a frase (a `release_probes` lê só `ok`/vermelho da
    `line 6 ·`), então a carona não recuou e a emenda da ADR 0007 ficou fora da lista da DOCS. A linha 6 da tabela
    da ADR 0007 (`:28`) ainda descreve o critério com a frase velha.
  - *Carona 4:* o aviso do `sdd preflight` para git < 2.31 ganhou a frase de que o carimbo (`mutation_stamp_dir`,
    pelo `git_common_dir_abs`) e o mapa (`killers_paths`) usam o mesmo caminho de reserva. O prefixo que o
    `check-preflight.sh:263` e o `mut_PRE_path_format_warn_silent` leem não mudou. Sem escopo, a frase saía também num
    repo-alvo: foi o QA-1, e o F1 (`c0adac8`) a limitou ao kit (abaixo).
  - 13 âncoras da seção aberta do `TODO.md` reancoradas pelas linhas que o diff acrescentou. As três da seção
    decidida que o diff empurrou (`:533`, `:537`, `:556`) já não apontavam o símbolo antes da onda, e o sensor não as
    mede: ficaram.

A QA (`199105f`) devolveu dois `F<n>`, e o detalhe de cada um está em *Ciclo de QA 1*, no topo:

- `c0adac8`, **F1**: a frase do carimbo e do mapa no aviso do git < 2.31 só sai onde `has_mutation_catalogue
  "$REPO_ROOT"` (`kit_fallback`, `bin/sdd:6487–6493`). O `check-preflight.sh` ganhou a asserção negativa e o controle
  positivo (`tests/check-preflight.sh:269–285`), e o catálogo ganhou o `mut_PRE_path_format_kit_note_unscoped`.
- `f98846d`, **F2**: os stubs do `check-health.sh` e do `check-gates.sh` imprimem o `score:` só com
  `--with-mutation`. O catálogo ganhou o `mut_HEALTH_skip_needs_score` e, de carona, o
  `mut_PRE_path_format_kit_note_never`, e foi a 792.

Os commits `chore(checkpoint): …` (`e14a51f`, `0a29c20`, `a70a188`, `1cd00bd`, `b91b9f5`, `629bea5`, `705aa95`,
`db5a09a`, `096c625`, `6233cc2`, `f72cad4`) só fecham a linha do checkpoint ou acrescentam uma nota.

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
| `bin/sdd` | `git_common_dir_abs`, `mutation_stamp_dir`, `mutation_stamp_valid`; `gate_PR`, linha 6 do `--release` e `cmd_health` (opções, pulo, 2c) lendo o lugar novo; a ajuda com `[--full]`; na onda `291d9af`, a linha 6 que afirma só o que a chave prova e o D15 do `catalogue_against`; o aviso do `preflight` para git < 2.31 com a frase do carimbo e do mapa só no kit (`kit_fallback`, F1) |
| `tests/check-mutation.sh` | `killers_paths`, `load_killer_maps`, `write_killer_map`, `killers_selftest`; os 17 mutantes novos da missão (o catálogo foi de 775 a 792), entre eles os dois da onda `291d9af`, o `PRE_path_format_kit_note_unscoped` do F1, e o `HEALTH_skip_needs_score` e o `PRE_path_format_kit_note_never` do F2 |
| `tests/check-health.sh` | `health_run` apaga o lugar e o `stub-argv.txt`; `health_run_keep`; as cinco `skip:` (a 1 e a 3 exigem, desde `291d9af`, que o pulo não grave); o `write_stub_suite` que imprime o `score:` só com `--with-mutation` (F2), e a sonda do mundo de dois scores que passa a flag; o `CAPTURE_FLOOR` com a linha do registro |
| `tests/check-gates.sh` | `fixture_stamps`/`fixture_unstamp`; os mundos 6 e 7 reescritos, o 8b e o 14; o `i4_write_suite` que imprime o `score:` só com `--with-mutation` (F2) |
| `tests/check-preflight.sh` | as duas asserções do F1: o git < 2.31 num repo-alvo não ouve falar do carimbo nem do mapa, e no kit ainda ouve (o controle positivo) |
| `tests/check-hat.sh` | a sonda da linha 6 do `--release`; a `command_worktree_return_probes` reescrita |
| `commands/sdd-plan.md` | o passo 2 (`:49–53`) sem a volta do mapa e do carimbo |
| `docs/adr/0021-the-stamp-lives-in-the-common-dir.md` | a decisão; emenda as 0004 e 0016 |
| `TODO.md` | os dois `RESOLVED by`; a `RECURRED 7` em `:225`; as âncoras reancoradas: 13 na onda `291d9af`, 16 no F1 e 1 no F2 |
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
   health --full measures it again` (`bin/sdd:7464`). Uma suíte vermelha no pulo dá `suite red (rc N) — run
   tests/run-all.sh to see it` (`:7392`), as linhas FAIL e rc 1, e a chave fica. O pulo não grava nada (desde
   `291d9af`, a `skip: 1` e a `skip: 3` o exigem).
2. **O `--full`**, que roda o catálogo sobre chave já medida. Verde regrava a chave; o veredito vermelho do catálogo
   a apaga.
3. **A recusa `--full --release`:** `sdd health: --full measures the catalogue, and --release never runs the suite —
   pick one` (`:7328`). A ordem inversa (`--release --full`) não tem teste (Minor adiado). O `die` de opção
   desconhecida lista as três (`:7321`).
4. **A ajuda** (`bin/sdd:12030–12032`): a linha do `sdd health` diz que pula o catálogo sobre chave medida, e ganhou
   `[--full]      run the catalogue anyway, over a key already measured`.
5. **A frase do `/sdd-plan`** (`commands/sdd-plan.md:49–53`): "Copy no killer map into the worktree, and ask for
   nothing to come back after the merge: the map and the stamp live in `<git-common-dir>/sdd-mutation/`, which the
   worktree shares with this checkout, so both outlive `git worktree remove` (ADR 0021)."
6. **A linha 6 do `--release`** (`bin/sdd:7273`), reescrita na onda `291d9af`: verde, ela diz "the mutation
   catalogue measured this content green, over a suite green in that same run (its key is stamped; --release re-runs
   nothing)", e não afirma mais a suíte de agora (um pulo com suíte vermelha mantém a chave). A vermelha não mudou.
7. Menos visível, mas mudou: o `gate_PR` e a linha 6 leem o lugar novo, e a frase do `gate_PR` não mudou; o
   catálogo imprime `== killer map: N …` lendo o compartilhado mais a semente (`check-mutation.sh:8215`, `:8297`).
8. **O aviso do `sdd preflight` para git < 2.31** (`bin/sdd:6484–6498`). No kit, onde há `tests/check-mutation.sh`,
   ele diz que o carimbo e o mapa tomam o mesmo caminho de reserva do ledger (`kit_fallback`, `:6487–6493`). Num
   repo-alvo ele fala só do ledger, termina em `ledger stays correct. Upgrading git removes the extra rev-parse.`, e
   não cita `check-mutation`, `mutation stamp` nem `killer map` (F1, `c0adac8`).

**As jornadas tocadas:** `docs/qa/journeys/J-health-verdict.md` (o fluxo ganha o ramo do pulo e do `--full`; o
`:24–25` ainda diz "any existing stamp is REMOVED" e `.sdd/logs/mutation-stamp`) e
`docs/qa/journeys/J-certify-mission-close.md` (`:16` "stamp file == key?", `:21` e `:64` no lugar velho). O texto
delas fica velho de propósito até a fase DOCS: a QA anda pelo comportamento novo e registra a divergência como
deriva de doc da DOCS, não como bug do código.

**Como subir o ambiente:** não há app. O ambiente são os sensores e um fixture.

- `bash tests/check-health.sh` (46–49 s; as cinco `skip:`), `bash tests/check-gates.sh` (142–148 s; mundos 6, 7,
  8b, 14), `bash tests/check-preflight.sh` (90–94 s; as duas asserções do F1), `bash tests/check-mutation.sh
  --anchors` (7 s; `killers:` e 792 mutantes aplicando), `bash tests/check-hat.sh` (3 s). O `--only <slug>
  <sensor>` de cada mutante novo já foi rodado e está nas notas. Rodar de novo custa minutos por mutante.
- **A verificação end-to-end do plano** (§ Verificação end-to-end), a rodada à mão do pulo sem catálogo, num
  clone isolado. A QA 1 a percorreu (S1–S2 do `30-handoff-qa.md`), e o EXEC a rodou de novo no F2, sobre o
  `f98846d`: a 2ª rodada pulou com rc 0, argv vazio e nenhum `went blind` (*Ciclo de QA 1*). Custa segundos e é a
  M1 fora do sensor. O stub tem a forma do `write_stub_suite` (`tests/check-health.sh:262`) e imprime o `score:`
  **só com `--with-mutation`**, como o `tests/run-all.sh` real. Um stub que o imprimisse sempre deixaria passar o
  pulo que passou a exigir a linha, que é o QA-2:

  ```bash
  d="$(mktemp -d)"; git clone -q /home/pc_admin/repos/sdd_agents-health-pula-catalogo "$d/k"
  n="$(grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' "$d/k/tests/check-mutation.sh")"
  cat > "$d/k/tests/run-all.sh" <<EOF
  #!/usr/bin/env bash
  printf '%s\n' "\$*" > "$d/argv"
  if [ "\${1:-}" = --with-mutation ]; then
    printf '%s\n' 'score: $n caught, 0 known gap(s), of $n'
  fi
  printf '  ok    61 finding(s), all within 8 lines, carrying anchor + date, every anchor on target\n'
  exit "\$(cat "$d/rc" 2>/dev/null || echo 0)"
  EOF
  git -C "$d/k" -c user.email=qa@example.com -c user.name=QA commit -qam 'qa: stub suite'; mkdir -p "$d/home"
  ( cd "$d/k" && HOME="$d/home" NO_COLOR=1 ./bin/sdd health ); cat "$d/argv"   # 1ª: o catálogo; grava a chave
  ( cd "$d/k" && HOME="$d/home" NO_COLOR=1 ./bin/sdd health ); cat "$d/argv"   # 2ª: o pulo
  ```

  O que se lê:
  - o stub sem argumento não imprime `score:`, e com `--with-mutation` imprime;
  - depois da 1ª rodada, o argv traz `--with-mutation` e `ls "$d/k/.git/sdd-mutation/stamps/"` mostra uma chave;
  - a 2ª sai rc 0, com o argv vazio, uma linha `catalogue skipped … ./bin/sdd health --full measures it again` e
    nenhum `went blind`;
  - `( cd "$d/k" && HOME="$d/home" NO_COLOR=1 ./bin/sdd health --full )` volta a passar `--with-mutation`;
  - `echo 1 > "$d/rc"` deixa a suíte vermelha sem mover a chave (o S7).

  O argv e o rc moram fora do clone, mas um arquivo não rastreado também ficaria fora da chave. Com o `HOME`
  redirecionado, outras verificações do health podem sair vermelhas; esta rodada mede só o pulo e o argv. O clone
  tem o próprio `.git`, então nada chega ao `git-common-dir` do kit. Isso é a M1 fora do sensor; a M3 de verdade é
  do humano. Para a rodada inteira da QA (S0–S19), a receita é a do `30-handoff-qa.md` § O fixture.
- **Nunca** rode `./bin/sdd health` na worktree nem no checkout principal antes do carimbo do operador, e nunca o
  `sdd health` do PATH nesta worktree (a frase em negrito do começo desta seção). O `./bin/sdd health` grava em
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation/`, roda o catálogo de 792 mutantes (cerca de metade das 10 h 58
  com o mapa) e é a pendência dele, depois dos bots.

## Pendências / Decisions for a Human

- **A ressurreição pela semente** (I3, `3e728d6`). Onde a semente `.sdd/cache/mutation-killers.tsv` conhece um slug,
  a leitura seguinte o traz de volta com a linha velha, mesmo depois de a gravação o tirar do compartilhado por não
  ter matador. Medido isolado: compartilhado `{A step1 10}`, semente `{A step9 99}`, `CATALOG=(A)` sem matador; a
  gravação deixa o compartilhado vazio, e a leitura seguinte dá `KILLER[A]=step9 SECS[A]=99`. Junto dela:
  - o matador velho que volta entra em `distinct_killers` (`check-mutation.sh:7668`, +1 controle);
  - `CATALOGUE-BROKEN`, `missing` e `killer_of` vazio também voltam;
  - o `echo` de `:8215` conta as linhas ressuscitadas;
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
catálogo sobre a semente. Os 17 mutantes novos da missão não têm linha nela (792 no catálogo, 775 na base `c114e36`).

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
- **O `mut_HEALTH_skip_needs_score` tem um sensor só**, o `check-health.sh`; contra o `check-gates.sh` ele sobrevive
  (*Ciclo de QA 1*, Riscos novos).

## Achados fora de escopo

Todos do **kit** (este repositório). Por decisão do relay, **não** entraram no `TODO.md` desta branch, porque a M4
fixa a catraca em 61. Cada um vai para o **chore pós-merge do `TODO.md`**, com a âncora medida de novo no `f98846d`:

- **Um `sed` de mutante que vira no-op passa calado pelo `--anchors`.** O `apply_mutant`
  (`tests/check-mutation.sh:7611`, o `diff -qr` em `:7614`) só exige que `bin/` mude no todo. Num mutante de vários
  `sed`, um deles pode não casar mais e ninguém acusa. Foi medido pelo re-revisor no `cdpath_leak`, cujo 1º `sed`
  virou no-op depois da extração do `git_common_dir_abs` (já reancorado no I1 r1). Ficou em aberto se já era assim
  no `19dbe32`. → chore pós-merge.
- **O "nearest" do `check-todo.sh --anchors` sugeriu a ocorrência errada duas vezes**, no GREEN do I2 (`6dbd63c`):
  `--no-gates` em 7919 em vez de 7932, e `KILLERS_FILE` em 7552 em vez de 7640. Os números são os daquele HEAD e
  não se medem de novo: o defeito é o critério do "nearest", não a linha. → chore pós-merge.
- **`load_killer_map` (`tests/check-mutation.sh:152`) lê `A<TAB><TAB>10` como passo `10`**, porque o `IFS` de tab
  colapsa. A união espalha uma linha torta da semente para o compartilhado. Direção: ler com `IFS= read -r` e
  partir por expansão. → chore pós-merge.
- **Pré-existente:** o comentário `tests/check-gates.sh:3787` ("The control file still says `move-the-tree` from
  world 8") já era velho na base. → chore pós-merge.
- **Pré-existente:** o censo do `tests/check-health.sh:85–86` (`grep -n 'sdd" health' tests/*.sh`) não conta a
  forma `./bin/sdd health` (`check-gates.sh:3684`, `check-health.sh:1194`). → chore pós-merge.
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
- `docs/qa/journeys/J-target-repo-ships.md`: o F1 condicionou a frase do carimbo e do mapa no aviso do git < 2.31,
  em vez de tirá-la. A nota da jornada pode registrar que essa frase é do kit e não sai num repo-alvo
  (`30-handoff-qa.md` § Para a fase DOCS).
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

Nenhum bloqueia; a REVIEW decide se algum vira `R<n>`. Os números de linha foram medidos de novo no `f98846d`,
cada um pelo conteúdo que o item descreve.

**Triagem da revisão final.** Os marcados **consertado em `291d9af`** saíram na onda de conserto. O resto **pode
esperar**, e cada item diz por quê.

- **I1:**
  - nenhum sensor mede a regra "primeira linha igual à chave" do `mutation_stamp_valid` (`bin/sdd:7303–7304`).
    *Pode esperar:* o nome do arquivo já é a chave, e o runner sempre grava a chave na primeira linha;
    um arquivo com o nome certo e a primeira linha errada só nasce de edição à mão;
  - a sonda da linha 6 (`check-hat.sh:818`) grafa o lugar à mão, sem a guarda de resposta absoluta. *Pode esperar:*
    num git < 2.31 a chave da sonda iria para outro caminho e a metade verde sairia vermelha; ela falha fechada,
    nunca passa sem medir;
  - `fixture_stamps` dá rc 1 num git < 2.31 e o `fixture_unstamp` vira no-op calado, mas o comentário
    (`check-gates.sh:3255–3256`) só fala em "fora de git". *Pode esperar:* é comentário de fixture, e o git < 2.31 já
    é avisado pelo `sdd preflight`;
  - o temporário da gravação mora dentro de `stamps/` (`bin/sdd:7613–7616`, e o `rm` dele em `:7624`), e um
    `<chave>.tmp.<pid>` órfão conta no `fixture_stamped` (`ls -A`). *Pode esperar:* o órfão só nasce de um kill entre
    o `printf` e o `mv`, e o `mutation_stamp_valid` lê o arquivo pelo nome exato da chave, então um órfão nunca abre
    gate; ele só confundiria a contagem de um fixture;
  - as âncoras do `TODO.md` foram mexidas antes de a skill `todo-to-github-issues` ser carregada (sem dano). *Pode
    esperar:* é só o registro;
  - **consertado em `291d9af`:** o aviso do `sdd preflight` para git < 2.31 citava só o `ledger_repo_root`; agora cita
    o carimbo e o mapa, só no kit desde o F1 (`kit_fallback`, `bin/sdd:6487–6493`), e saiu da lista da DOCS.
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
  - as contagens divergem: `check-hat.sh:785` diz "ten handoffs", e `bin/sdd:7314` diz "sixteen handoffs and in
    CLAUDE.md". *Pode esperar:* são dois comentários, e a DOCS pode alinhar a contagem;
  - as `skip: 3` e `4` forjam a chave pela receita, o que falha fechado. A alternativa é o rc do stub num arquivo de
    controle não rastreado, como no `check-gates.sh:3191–3197`. *Pode esperar:* uma receita que derive deixa os
    mundos vermelhos, nunca verdes;
  - **consertado em `291d9af`:** o comentário da `skip: 4` dizia "the only world of the kit where a catalogue run
    meets a red suite over a clean score", e era falso, porque o mundo `abort:` (`tests/check-health.sh:816–819`)
    também roda esse catálogo. Agora (`:1147–1153`) ele diz que esta é a única que pergunta se esse catálogo carimba;
  - nit: o comentário do mundo 9 (`check-gates.sh:3548`) diz "never a leftover of world 8", mas o anterior agora é o
    8b, que deixa a chave K (o `fixture_unstamp` segura a propriedade). *Pode esperar:* é comentário, e a propriedade
    tem quem a segure.
- **I3:**
  - os `load_killer_maps` dos três leitores não têm sensor durável: a sabotagem sobrevive à suíte rápida (fiação de
    modo, falha ruidosa ou única por clone). Um sensor barato seria `--touched <rev> --list` num fixture com o
    compartilhado ausente e a semente presente (~3 s). *Pode esperar:* o mapa é dica de ordem, e um leitor quebrado
    custa tempo, nunca veredito (ADR 0021 §5);
  - as linhas `== killer map: N …` (`check-mutation.sh:8215`, `:8297`) passam a contar slugs fora do `CATALOG`. *Pode esperar:* é uma
    linha informativa, que nenhum veredito lê;
  - `bin/sdd:3608–3610` ("ONE resolution … a repair here reaches both") não aponta a cópia do `check-mutation.sh`, e o
    comentário da cópia (`check-mutation.sh:7804–7806`) diz "copied" sem nomear a recusa de `\n` que ficou de fora
    (`bin/sdd:3658`). *Pode esperar:* são dois comentários;
  - em `check-mutation.sh:7704`, a recusa do `--touched` nomeia só o compartilhado quando faltam os dois; e o `:7825`
    ("The seed is never written") é falso fora de git, onde os dois são um arquivo só. *Pode esperar:* são uma mensagem e um
    comentário, e a recusa continua recusando;
  - a frase nova (`check-mutation.sh:7827–7835`) restringe a volta a "checkout com semente". Medido: um catálogo que
    não lista o slug copia a linha da semente para o compartilhado (a união, `:7846–7847`), e ela chega a um
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
