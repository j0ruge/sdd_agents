---
missao: 20261026-health-pula-catalogo
fase: QA
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 09:55
gate: sem interface (`E2E_CMD` e `APP_URL` vazios); ciclo 1 fechado. QA 1 (`199105f`, clone do `096c625`): J-health-verdict, J-certify-mission-close e J-target-repo-ships percorridas (S0–S19), 2 achados → F1 e F2. Re-walk (clone `--no-hardlinks` do `fe065d9` em `mktemp -d`, stub realista commitado no clone que imprime `score: 792 caught, 0 known gap(s), of 792` só com `--with-mutation`, `HOME` temporário, sempre `( cd <checkout> && HOME=$d/home NO_COLOR=1 ./bin/sdd health … )`). J-health-verdict (F2): 1ª rodada → rc 0, argv `--with-mutation`, `mutation stamp written … stamps/d0c807bf…`; 2ª → rc 0, argv vazio, uma linha `catalogue skipped — this content (key d0c807bf…) was measured green (…); ./bin/sdd health --full measures it again`, 0 `went blind`, carimbo com md5 e mtime iguais; `--with-mutation` → pula; `--full` → argv `--with-mutation`, regrava; suíte vermelha no pulo → rc 1 `suite red (rc 1) — run tests/run-all.sh to see it`, chave mantida; janela no pulo → rc 1 `moved WHILE the suite was running`; worktree ligada → pula, `--release` linha 6 verde; `--full` com `791 of 792` → rc 1 e chave apagada; o verde regrava, e o clone pula depois do `git worktree remove`. J-target-repo-ships (F1, S17b: repo-alvo `git init` com o `./bin/sdd install` do clone, `claude` e `gh` falhando, o shim de git < 2.31 do `check-preflight.sh`, armado `old:2 new:1`): o `warn` termina em `ledger stays correct. Upgrading git removes the extra rev-parse.`, e `grep -ciE 'check-mutation|mutation stamp|killer map'` → 0; com git 2.43 → 0 e a linha `git speaks --path-format`; no próprio kit (o clone) com o shim → a frase do carimbo e do mapa sai (2 linhas); num alvo com `tests/check-mutation.sh` → sai também, pela mesma pergunta de artefato do `gate_PR`. Checks da tabela, cada célula rodada como está, da raiz da worktree: I1 → `1` (`check-gates.sh`, 140 s), I2 → `5` (`check-health.sh`, 47 s), I3 → `1` (`--anchors`, 7 s), I4 → `1` (`check-hat.sh`, 3 s), I5 → `2 0`, F1 → `1` (`check-preflight.sh`, 93 s), F2 → `0` (`--only HEALTH_skip_needs_score check-health.sh`, 43 s): 7 de 7 verdes. TEST_CMD `tests/run-all.sh` no `8328a7e` (o `fe065d9` só mudou a pasta da missão), rodado pelo relay: rc 0, 714 s, 2057 `ok`, 0 `FAIL` (`suite-8328a7e.log`). Resultado: QA-1 consertado em `c0adac8`, QA-2 em `f98846d`, nenhum achado novo, nenhum `F<n>` aberto, 0 ao humano. Checkout principal: `status --porcelain` vazio e sem `.git/sdd-mutation`
---

# Handoff — QA — o `sdd health` pula o catálogo com a chave já medida

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Ciclo de QA 1 fechado. A QA 1 percorreu três jornadas num clone isolado (S0–S19) e achou dois defeitos sanáveis do diff.
QA-1 → F1 (`c0adac8`): o aviso do git < 2.31 parou de falar do kit num repo-alvo. QA-2 → F2 (`f98846d`): os stubs só
imprimem `score:` com `--with-mutation`, e o `mut_HEALTH_skip_needs_score` morre. O re-walk de J-target-repo-ships e
J-health-verdict no `fe065d9` saiu verde, e os sete Checks da tabela também; nenhum achado novo, 0 spec, 0 ao humano.
Próximo: REVIEW.

## Estado do repo

- **Branch:** `fix/health-pula-catalogo`, sem upstream, não empurrada.
- **Último commit antes deste fecho:** `fe065d9` `docs(missao): handoff EXEC reescrito no lugar — o estado depois do F2,
  sem errata`. Código do ciclo: `c0adac8` (F1) e `f98846d` (F2). Este fecho commita só este handoff e uma nota no
  `checkpoint-notas.md`; a tabela do `checkpoint.md` não muda (F1 e F2 já estão `done`).
- **Working tree:** limpa depois do commit deste fecho. A QA não tocou em arquivo de produção.
- **Suíte:** `tests/run-all.sh` no `8328a7e`, rodada pelo relay → rc 0, 714 s, 2057 `ok`, 0 `FAIL`
  (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-8328a7e.log`; contei as linhas no log: as cinco `skip:`, as
  duas asserções novas do F1 e `anchors: all 792 mutants still apply`). Depois dele só a pasta da missão mudou.
- **E2E:** `E2E_CMD=""`; o kit não tem interface. Nenhuma spec: os dois achados moravam na suíte `TEST_CMD`.
- **Checkout principal:** `git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio;
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation` → **inexistente**; `git worktree list` sem entrada de fixture.
  Nenhum `sdd` do PATH rodou, e nenhum `./bin/sdd health`, `run` ou `status` rodou na worktree.

## O que foi feito

A QA não commita código. Os dois ciclos desta fase:

- `199105f`: a QA 1. Três jornadas percorridas, QA-1 → F1 e QA-2 → F2 no `checkpoint.md`.
- `c0adac8` e `f98846d` (o EXEC, com os checkpoints `6233cc2` e `f72cad4`): F1 e F2 consertados.
- Este fecho: o re-walk das duas jornadas impactadas, os sete Checks da tabela e este handoff reescrito.

### O fixture

Nos dois ciclos foi um clone do HEAD em `mktemp -d` (no scratchpad da sessão), com `--no-hardlinks`, para não dividir
nem um objeto com o `.git` do kit. É outro repositório, e o `.git/sdd-mutation/` que ele grava é o dele. O
`tests/run-all.sh` do clone virou um stub commitado no clone (nunca neste repo), na forma do `write_stub_suite`
(`tests/check-health.sh:262`):

- imprime `score:` **só** com `--with-mutation`, como o `tests/run-all.sh` real (`:76`, `:403–404`). Desde o F2, os
  stubs dos sensores fazem o mesmo;
- lê rc, score, `FAIL`, sono e "mover a árvore" de arquivos de controle **fora** do clone, então nenhum cenário edita um
  arquivo rastreado, e a chave só anda quando o cenário quer;
- tem um arquivo rastreado, `tests/qa-window.txt`, ao qual o stub acrescenta uma linha no cenário da janela.

O `HOME` foi redirecionado para `$d/home`. No fim, o fixture foi removido. A receita:

```bash
d="$(mktemp -d)"; git clone -q --no-hardlinks /home/pc_admin/repos/sdd_agents-health-pula-catalogo "$d/k"
n="$(grep -cE '^mut_[A-Za-z0-9_]+\(\) \{' "$d/k/tests/check-mutation.sh")"
cat > "$d/k/tests/run-all.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" > "$d/argv"
if [ "\${1:-}" = --with-mutation ]; then
  if [ -f "$d/score" ]; then cat "$d/score"; else printf '%s\n' 'score: $n caught, 0 known gap(s), of $n'; fi
fi
printf '  ok    61 finding(s), all within 8 lines, carrying anchor + date, every anchor on target\n'
exit "\$(cat "$d/rc" 2>/dev/null || echo 0)"
EOF
git -C "$d/k" -c user.email=qa@example.com -c user.name=QA commit -qam 'qa: stub suite'; mkdir -p "$d/home"
( cd "$d/k" && HOME="$d/home" NO_COLOR=1 ./bin/sdd health ); cat "$d/argv"   # S1: o catálogo, grava a chave
( cd "$d/k" && HOME="$d/home" NO_COLOR=1 ./bin/sdd health ); cat "$d/argv"   # S2: o pulo, argv vazio
```

### Ciclo 1: o re-walk no `fe065d9`

**J-health-verdict, pelo F2** (clone do `fe065d9`, catálogo de 792, stub realista):

| # | Cenário | rc | argv | Observado | Chave |
|---|---|---|---|---|---|
| R1 | 1ª rodada | 0 | `--with-mutation` | `mutation: score: 792 caught, 0 known gap(s), of 792`, `mutation stamp written — … stamps/d0c807bf…`, `kit healthy` | gravada |
| R2 | 2ª rodada | 0 | vazio | **uma** linha `catalogue skipped — this content (key d0c807bf…) was measured green (measured: …; root: …; score: 792 …); ./bin/sdd health --full measures it again`; **0** `went blind`; `kit healthy` | md5 e mtime iguais |
| R3 | `--full` | 0 | `--with-mutation` | `mutation stamp written` | regravada |
| R4 | pulo com a suíte vermelha (rc 1, uma linha `FAIL`) | 1 | vazio | `suite red (rc 1) — run tests/run-all.sh to see it`, a linha do pulo, `1 check(s) failed` | intacta |
| R5 | janela no pulo | 1 | vazio | `the measured tree moved WHILE the suite was running — nothing was stamped and no key was taken away` | intacta |
| R6 | `--with-mutation` (o hábito) | 0 | vazio | o mesmo pulo | intacta |
| R7 | worktree ligada (`worktree add --detach`), health e `--release` nela | 0 | vazio | `kit sensor at …/wt`, a linha do pulo; `ok line 6 · the mutation catalogue measured this content green …` | — |
| R8 | `--full` com `791 of 792` | 1 | `--with-mutation` | `1 survivor(s) … run tests/run-all.sh --with-mutation` | **apagada** |
| R9–R10 | a rodada verde seguinte, depois `git worktree remove` e health no clone | 0, 0 | `--with-mutation`, depois vazio | o verde regrava; depois do remove, o clone pula | regravada |

**J-target-repo-ships, pelo F1** (S17b: um repo-alvo `git init` com o `./bin/sdd install` do clone, `claude` e `gh`
falhando como no `check-preflight.sh`, o shim de git < 2.31 de `tests/check-preflight.sh:243–256`, armado `old:2 new:1`):

| # | Onde | git | Observado | `grep -ciE 'check-mutation\|mutation stamp\|killer map'` |
|---|---|---|---|---|
| F1a | repo-alvo | shim < 2.31 | o `warn` termina em `ledger stays correct. Upgrading git removes the extra rev-parse.` | **0** |
| F1b | repo-alvo | 2.43 | `ok git speaks --path-format (2.31+)` | 0 |
| F1c | o próprio kit (o clone) | shim < 2.31 | a frase `The mutation stamps ('mutation_stamp_dir', …) and the killer map (tests/check-mutation.sh, 'killers_paths') take that same fallback …` sai inteira | 2 linhas |
| F1d | repo-alvo com um `tests/check-mutation.sh` | shim < 2.31 | a frase sai: é a mesma pergunta de artefato (`has_mutation_catalogue`) com que o `gate_PR` limita o carimbo, e o caso já está declarado na `J-target-repo-ships` (abandono do passo 3) | 2 linhas |

O `gate_PR` do repo-alvo (S17c da QA 1) não foi repetido: nem o F1 nem o F2 tocam o `gate_PR`.

**Os Checks da tabela**, cada célula rodada como está escrita (o comando entre crases antes da seta), da raiz da
worktree, um por vez:

| ID | Esperado | Obtido | Tempo |
|---|---|---|---|
| I1 | `1` | `1` | 140 s (`check-gates.sh`) |
| I2 | `5` | `5` | 47 s (`check-health.sh`) |
| I3 | `1` | `1` | 7 s (`check-mutation.sh --anchors`) |
| I4 | `1` | `1` | 3 s (`check-hat.sh`) |
| I5 | `2 0` | `2 0` | 0 s |
| F1 | `1` | `1` | 93 s (`check-preflight.sh`) |
| F2 | `0` | `0` | 43 s (`--only HEALTH_skip_needs_score check-health.sh`) |

Sete de sete verdes. A metade "re-walk" das células F1 e F2 é o R1–R10 e o F1a–F1d acima.

### QA 1: o percurso no `096c625` (`199105f`)

O stub da QA 1 já era o realista, então o F2 não muda nenhum cenário abaixo; mudaram os sensores (QA-2). Os números
de linha desta seção são do `096c625`.

**J-health-verdict.** Cada linha é uma rodada de `./bin/sdd health` no clone, e a última coluna diz o que aconteceu
com `<common>/sdd-mutation/stamps/`:

| # | Cenário | rc | argv da suíte | Observado | Chave |
|---|---|---|---|---|---|
| S0 | `--release` antes de tudo | 1 | — | `fail line 6 · mutation stamp absent or stale` (as linhas 1–5 vermelhas pelo `HOME` vazio, sem relação) | nenhum diretório |
| S1 | 1ª rodada | 0 | `--with-mutation` | `mutation stamp written — … (<clone>/.git/sdd-mutation/stamps/68b56f03…)`, `kit healthy` | gravada. A 1ª linha é a chave, depois `measured:`, `root:` e `score:`; o nome bate com a receita do `docs/failure-modes.md:1085` |
| S2 | 2ª rodada | 0 | vazio | **uma** linha `catalogue skipped — … ./bin/sdd health --full measures it again`; nenhum `went blind`, embora a suíte não tenha impresso `score:` | intacta (md5 e mtime iguais) |
| S3 | `--with-mutation` (o hábito) | 0 | vazio | o mesmo pulo | intacta |
| S4 | `--full` | 0 | `--with-mutation` | `mutation stamp written` | regravada (`measured:` novo) |
| S5 | `--full --release`, `--release --full`, `--full --with-mutation --release` | 1 | não chamada | `sdd health: --full measures the catalogue, and --release never runs the suite — pick one` nas três ordens; `--bogus` → `unknown option '--bogus' (accepted: --release, --with-mutation, --full)` | — |
| S6 | `--release` com a chave | 1 | — | `ok line 6 · the mutation catalogue measured this content green, over a suite green in that same run (its key is stamped; --release re-runs nothing)` | — |
| S7 | pulo com a suíte vermelha | 1 | vazio | `suite red (rc 1) — run tests/run-all.sh to see it` (sem a flag), a linha `FAIL` repassada; o `--release` logo depois segue com a linha 6 **verde** (decisão 3) | intacta |
| S8 | `--full`, suíte vermelha, score limpo | 1 | `--with-mutation` | `suite red (rc 1) — run tests/run-all.sh --with-mutation to see it`, nada gravado | intacta |
| S10 | `--full`, sem `score:` / `score:` torto | 1 | `--with-mutation` | `health went blind` / `no longer parses` | intacta |
| S9 | `--full`, `788 of 789` | 1 | `--with-mutation` | `1 survivor(s) … run tests/run-all.sh --with-mutation`; o `--release` passa a `fail line 6` | **apagada** |
| S9b–d | sem chave: sobrevivente, gap, verde | 1, 1, 0 | `--with-mutation` | o catálogo volta a rodar sozinho; o gap diz `open gap`; o verde regrava | regravada no S9d |
| S11 | janela, no pulo e sob `--full` | 1 | vazio / `--with-mutation` | `moved WHILE the suite/catalogue was running — nothing was stamped and no key was taken away` | intacta, nenhuma chave nova |
| S12 | `timeout -s INT 3 ./bin/sdd health --full`, com o stub dormindo 20 s | 124 | `--with-mutation` | só o cabeçalho; nenhum `.tmp.` órfão; a rodada seguinte pula, e a trava não ficou presa | intacta |
| S19 | cópia sem `.git`, duas rodadas | 0, 0 | `--with-mutation` nas duas | `warn … is not a git checkout — no gate can demand a mutation stamp here; none written`: nunca pula (ADR 0021 §1) | — |

**M2: a worktree e o lugar compartilhado.**

| # | Cenário | Observado |
|---|---|---|
| S13 | `worktree add --detach`, health na worktree | rc 0, argv vazio, `kit sensor at …/wt`, o pulo com `root: …/k`; `--release` com a linha 6 verde; o git dir próprio da worktree não tem `sdd-mutation/` |
| S14 | commit em `tests/` na worktree, health nela, `merge --ff-only` no clone, health no clone, `worktree remove`, health no clone | a worktree grava `99f01c18…` no common dir; o clone pula sobre ela (`root: …/wt`), e segue pulando depois do remove. É a M3 em miniatura, sem passo manual |
| S15 | o shim de git < 2.31, no clone e numa worktree nova | pula nos dois, pelo braço de reserva do `git_common_dir_abs` |
| S18 | `bash tests/check-mutation.sh --touched c114e36 --list` na worktree (com o `run-all.sh` real devolvido a ela) | só a semente → rc 0, `302 mutant(s) of the map`; nada → rc 2, `--touched has no killer map to read (<clone>/.git/sdd-mutation/killers.tsv)`; só o compartilhado (50 linhas) → rc 0, `15 mutant(s)`; mapa e chaves sobrevivem ao `worktree remove` |

**J-certify-mission-close, no passo do `gate_PR`** (`./bin/sdd why 20261026-health-pula-catalogo PR` no clone, com um
`gh` falso e um `50-pr.md` não rastreado):

- com a chave → `PR open`;
- sem → `no green mutation catalogue for this content — run 'sdd health' (since 4c86712 …)`;
- só o `.sdd/logs/mutation-stamp` velho com a chave certa → a mesma recusa, e o health não pula sobre ele;
- a worktree carimba → `PR open` no clone e na worktree.

**J-target-repo-ships:**

- o `gate_PR` do repo-alvo → `PR open`, sem palavra de carimbo nem de catálogo, e nenhum `sdd-mutation/` no `.git` dele;
- o `preflight` com git 2.43 → limpo;
- o `preflight` com o shim < 2.31 → citava o carimbo e o mapa do kit. Foi o QA-1.

**J-suite-runs-something: não percorrida, de propósito.** O diff não toca o `tests/run-all.sh`, a verificação 2b
(`test_cmd_lists_only`), o `--list` nem o `TEST_CMD` que os gates rodam. O pulo chama `tests/run-all.sh` sem flag, que
é a própria suíte que o `TEST_CMD` nomeia, e a verificação 2b continua rodando nele (`ok TEST_CMD runs the suite
(tests/run-all.sh)` em todo pulo). O F2 mexeu nos stubs, não nela.

**A frase nova do `/sdd-plan`** (`commands/sdd-plan.md:49–53`), conferida contra o medido: o lugar é
`<git-common-dir>/sdd-mutation/` (S1, S13, S18); os dois sobrevivem ao `worktree remove` (S14, S18, R10); a worktree
sem cópia lê o mapa do principal (S18). A metade "escrever o mapa" só um catálogo real mede; aqui ela tem só o
`killers_selftest`. O Minor do I4 ("ask for nothing" diz mais que a justificativa, porque os logs `.sdd/logs/<missão>`
seguem por worktree) continua de pé.

## Achados

### QA-1 → F1, consertado em `c0adac8`

- **O que era:** o `warn` do `cmd_preflight` para git < 2.31 (no `096c625`, `bin/sdd:6482–6488`; a frase entrou na onda
  `291d9af`) citava `mutation_stamp_dir`, `tests/check-mutation.sh` e `killers_paths` em todo repo. A `J-target-repo-ships`
  promete que a Priya nunca ouve falar da maquinaria do kit.
- **O conserto:** a frase só sai onde `has_mutation_catalogue "$REPO_ROOT"` (`kit_fallback`, hoje `bin/sdd:6487–6497`).
  O `check-preflight.sh` ganhou a negativa (`an old git in a repo without the catalogue is not told about the mutation
  stamps or the killer map`) e o controle positivo (`an old git in a repo that carries the catalogue is still told the
  stamps and the killer map share the fallback`). Entraram dois mutantes, um em cada direção do escopo:
  `PRE_path_format_kit_note_unscoped` e `PRE_path_format_kit_note_never`.
- **Re-walk:** F1a–F1d acima.

### QA-2 → F2, consertado em `f98846d`

- **O que era:** os stubs que rodam o caminho principal do `sdd health`, o `write_stub_suite` (`tests/check-health.sh`)
  e o `i4_write_suite` (`tests/check-gates.sh`), imprimiam o `score:` sempre, e a suíte rápida real nunca o imprime.
  Medido na QA 1: o mutante `if [ "$skip" = 1 ] && [ -n "$score_line" ]; then` sobrevivia às cinco `skip:` e ao
  `check-gates.sh` (rc 0, 481 `ok`, 0 `FAIL`), e no clone fazia todo pulo sair rc 1, `health went blind to the mutation`.
- **O conserto:** os dois stubs imprimem o `score:` só com `--with-mutation` (`tests/check-health.sh:262`,
  `tests/check-gates.sh:3288`). O `mut_HEALTH_skip_needs_score` (`tests/check-mutation.sh:1825`) entrou no `CATALOG` e
  morre no `check-health.sh`, pelas `skip: 1`, `skip: 3` e `skip: 5`. O mundo de dois scores do `check-health.sh` passou
  a armar a sonda com `--with-mutation`.
- **Um erro desta QA na célula do Check, corrigido pelo EXEC.** Eu escrevi `--only HEALTH_skip_needs_score
  tests/check-health.sh`, com o caminho, copiado do `01-plano.md:235–236`. O harness recusa o caminho sempre, com rc 2
  (`the sensor is a file name under tests/, like check-gates.sh`, `tests/check-mutation.sh:8062`). O `CLAUDE.md:465`
  traz a forma certa, `--only <slug> [sensor.sh]`. Então o "vermelho, rc 2" que registrei no HEAD era a recusa do
  slug, não o sensor dizendo "não pego", e com o mutante no catálogo a célula seguiria sem ficar verde nunca. A célula
  hoje diz `check-health.sh`; o EXEC mediu o vermelho de verdade nessa forma (rc 1, `NOT caught`) antes de tocar nos
  stubs. É o limite que o próprio `--red` declara ("not green, never red for the right reason",
  `tests/check-checkpoint.sh:77`): um Check cujo vermelho vem de uma recusa parece com o vermelho certo.
- **Re-walk:** R1–R10 acima.

### Nenhum achado novo no ciclo 1

O re-walk e os Checks não mostraram defeito novo, então não há `F3`. Dois pontos que o EXEC registrou e esta QA
confirmou pelo código, sem repetir a medida:

- o `mut_HEALTH_skip_needs_score` só morre no `check-health.sh`. Contra o `check-gates.sh` ele sobrevive (medido pelo
  EXEC: rc 1, 159 s, `NOT caught`), porque os mundos i4 leem o gate e não o rc do health. É o desenho, e o mapa vai
  nomear o `check-health.sh`;
- o stub do `TREE_KIT` (`tests/check-gates.sh:3743–3748`) ainda imprime o score sem olhar a flag. Ali nunca há pulo:
  o `tree_health` tira todo carimbo antes de cada rodada.

### Hipóteses levantadas e descartadas (QA 1)

- **O `--touched` recusa o clone** (`SELFTEST FAIL touched`): era o fixture. O `touched_selftest` lê os passos do
  `tests/run-all.sh` real, e o clone tinha o stub.
- **A ordem `--release --full` passaria:** recusada nas três ordens (S5). O sensor durável dessa ordem fica para a REVIEW.
- **Um Ctrl-C deixaria a trava ou um temporário:** nenhum dos dois (S12).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261026-health-pula-catalogo/30-handoff-qa.md` | este handoff: os dois ciclos, os achados e a receita do fixture |
| `docs/handoffs/20261026-health-pula-catalogo/checkpoint.md` | F1 e F2 `done` (`c0adac8`, `f98846d`), escritos pela QA 1 e fechados pelo EXEC |
| `docs/handoffs/20261026-health-pula-catalogo/checkpoint-notas.md` | as notas da QA 1 e deste fecho (append) |
| `/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/qa-report.md` | o relatório da QA ao relay (fora do repo), com a seção "Fecho do ciclo 1" |

Nenhuma spec e2e (não há `E2E_DIR`). Nenhum `docs/qa/` foi criado nem tocado; esta fase só leu as jornadas.

## Boot da próxima fase

**Próxima: REVIEW.** A tabela não tem linha `pending`: I1–I5, F1 e F2 estão `done`. A missão segue **interativa, na
worktree**, com todo comando como `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`. Valem as regras do
boot do `20-handoff-exec.md`: nunca o `sdd` do PATH (é o kit velho, `c114e36`, até o merge), e nenhum `./bin/sdd
health`, `run` ou `status` na worktree. O `./bin/sdd health` da worktree é o carimbo do operador, depois dos bots.

O que a REVIEW precisa saber do que a QA viu:

- **O comportamento bate com as oito decisões do grill** em todo cenário percorrido, nos dois ciclos. A única
  divergência de código foi o QA-1, já consertado.
- **A fidelidade dos stubs era o ponto fraco dos sensores desta missão** (QA-2). O F2 a corrigiu para o `score:`.
  Ninguém mediu ainda se os stubs divergem da suíte real em outra linha que o `cmd_health` lê: a contagem do
  `TODO.md`, as linhas `FAIL`, a cauda. Vale perguntar isso de cada mundo do `check-health.sh` e do i4.
- **Um mutante, um sensor:** o `mut_HEALTH_skip_needs_score` só morre no `check-health.sh` (acima). A REVIEW decide se
  isso basta.
- **A célula do F2 já foi corrigida uma vez** (QA-2). Hoje, o `--only` na forma com o nome do sensor é o que os Checks
  e o `CLAUDE.md:465` usam.
- **Os Minor adiados do EXEC** seguem para a triagem da REVIEW como estão (`20-handoff-exec.md` § *Minor adiados*). A QA
  confirmou dois pelo comportamento: a ordem `--release --full` recusada (S5), e a recusa do `--touched` que nomeia só o
  compartilhado quando faltam os dois (S18).
- **A `main` andou durante a QA:** `cc993f7`, o merge do PR #329 (`1c41d3a`), mexe só no `TODO.md` (+8) e no
  `tests/health-baseline.txt` (`todo-findings 61` → `62`). Os dois estão fora da chave (`git diff --quiet c114e36
  cc993f7 -- bin tests templates config agents ':(exclude)tests/health-baseline.txt'` → sem diferença), então o carimbo
  e a M3 não mudam. Mas a branch precisa trazer a base antes do PR, e o `TODO.md` e a baseline divergem dos dela: a
  "catraca 61" da M4 é a da base `c114e36`.
- **A tensão entre o §4 do `agents/sdd-qa.md` e o `check-checkpoint.sh --red`** (abaixo) faz o `--red` recusar as
  células de F1 e F2. O vermelho das duas foi medido à mão: o do F1 pela QA, e o do F2 pelo EXEC, já que o da QA era a
  recusa.

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

- **Nada novo da QA.** As duas perguntas do EXEC seguem com o dono, sem mudança: a ressurreição pela semente
  (`20-handoff-exec.md` § *Pendências*, I3 `3e728d6`) e a cópia do kit sem `.git` dentro de outro repositório.
- **A pendência do operador, a M3 e o chore pós-merge** seguem como o `20-handoff-exec.md` os descreve. O S14 é a M3 em
  miniatura, mas o número real (≤ 20 min no checkout principal depois do merge) só o humano mede.

## Riscos e não-feitos

- **Nenhum catálogo real rodou**, em nenhum dos dois ciclos. O stub responde o `score:`, então a QA mediu o caminho do
  `cmd_health` e o lugar do carimbo e do mapa, nunca os 792 mutantes. A gravação do mapa (`write_killer_map`) só tem o
  `killers_selftest`.
- **O fixture não é o kit:** o `run-all.sh` do clone é um stub, e as sondas de superfície do `check-health.sh` saem
  `SENSOR-BROKEN` (rc 90) num clone assim. Por isso, os sensores deste fecho rodaram na worktree, que tem a suíte real.
- **A J-suite-runs-something não foi percorrida** (razão acima).
- **O `HOME` redirecionado** deixa vermelhas as linhas 1–5 do `--release` e pula a proveniência (`0 fixture(s)
  checked, 3 skipped`). Nenhuma das duas é da missão; a linha 6 é a única lida.
- **A doc das jornadas segue velha até a DOCS** (lista abaixo). A QA andou pelo comportamento novo.

## Achados fora de escopo

Todos do **kit**. Pela M4, a catraca fica em 61 nesta branch, então nenhum entra no `TODO.md` aqui. Vão para o **chore
pós-merge do `TODO.md`**, junto dos que o `20-handoff-exec.md` já listou:

- **O §4 do `agents/sdd-qa.md` e o `check-checkpoint.sh --red` se contradizem.** O contrato manda o Check de um `F<n>`
  levar "regression test passa **e** re-walk da jornada" (o modelo `` `<cmd>` → green AND re-walk of <journey> green ``),
  e o `--red` (`tests/check-checkpoint.sh:72–82`) recusa como "outside the strict form" toda célula com prosa depois da
  seta. Medido: `--red` → rc 1 nas linhas F1 e F2, como recusaria as `F<n>` de missões anteriores
  (`20260826-o-laco-da-qa`, `20260901-o-revisor-so-acha`). Nenhum `F<n>` escrito pelo contrato pode ser provado
  vermelho pela ferramenta. O ciclo 1 mostrou o custo: o vermelho do F2, medido à mão, era uma recusa (QA-2). Direção:
  uma forma estrita para o re-walk (o comando dele, com o esperado junto), ou o `--red` lendo só o primeiro par. →
  chore pós-merge.
- **Observado, sem defeito:** com uma saída de suíte curta, a linha `FAIL` sai duas vezes no `sdd health`: o `grep
  '^  FAIL  '` e depois a cauda de 15 linhas (`bin/sdd:7396–7397`). É pré-existente e é o desenho ("every FAIL line
  first, then the tail"). Fica registrado para o chore decidir se vale um item.

## Para a fase DOCS

O que o percurso mostrou velho, além da lista do `20-handoff-exec.md` § *Para a fase DOCS* (que segue valendo):

- `docs/qa/journeys/J-health-verdict.md`:
  - `:11` "Check 2: run the mutation catalogue — 20 to 50 min": o catálogo agora é condicional (o pulo), e o tempo real
    é de horas (10 h 58 no #327);
  - `:24` a janela "any existing stamp is REMOVED", e `:80` "removes the stamp": hoje nada é gravado nem apagado (S11, R5);
  - `:25` `.sdd/logs/mutation-stamp`;
  - `:63` `stamp-removed-on-failure`, e `:66–68` "on any red, no stamp may remain on disk": a decisão 3 inverteu isso,
    porque uma suíte vermelha, um score ausente e a janela mantêm a chave, e só o veredito do catálogo a apaga (S7, S8,
    S10, S11, R4, R5, R8). O `true_end_state` precisa ser reescrito, não só o caminho;
  - faltam o ramo do pulo, o `--full` e a recusa `--full --release` no fluxo e nos `actions`.
- `docs/qa/journeys/J-certify-mission-close.md`:
  - `:16` "stamp file == key?";
  - `:18` "20 to 50 min" (agora: o pulo, ou o catálogo de horas);
  - `:21` e `:64` `.sdd/logs/mutation-stamp`;
  - o `true_end_state` (`:63–64`) pode citar a receita e o `stamps/<chave>`, e ganhar a worktree que carimba para o
    principal (S14, S16).
- `docs/qa/journeys/J-target-repo-ships.md`: a nota da jornada pode registrar que o aviso do git < 2.31 fala do carimbo e
  do mapa só onde há `tests/check-mutation.sh` (F1; F1c e F1d), a mesma condição de artefato do `gate_PR`.
- `docs/failure-modes.md:1086` "compare with .sdd/logs/mutation-stamp": a receita continua certa (S1 a usou), e o que
  muda é o lugar com que se compara (`<git-common-dir>/sdd-mutation/stamps/<chave>`).
