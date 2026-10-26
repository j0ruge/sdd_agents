---
missao: 20261026-health-pula-catalogo
fase: QA
status: done
sessao: 4b9c28f8-7152-4e88-aae7-0bf05f85f18c
data: 2026-10-26 08:20
gate: sem interface (`E2E_CMD` e `APP_URL` vazios); 3 jornadas percorridas no terminal e 1 decidida, num clone isolado do HEAD `096c625` (`git clone --no-hardlinks` em `mktemp -d`; `tests/run-all.sh` trocado por um stub commitado que grava o argv fora do clone, imprime `score: 789 caught, 0 known gap(s), of 789` só com `--with-mutation`, como a suíte real, e lê rc, score e efeitos de arquivos de controle fora da chave; sempre `( cd <checkout> && HOME=$d/home NO_COLOR=1 ./bin/sdd health … )`). J-health-verdict: 1ª rodada → rc 0, argv `--with-mutation`, `mutation stamp written … (<clone>/.git/sdd-mutation/stamps/68b56f03…)`, nome do arquivo igual à receita da chave do `docs/failure-modes.md`; 2ª → rc 0, argv vazio, uma linha `catalogue skipped — this content (key 68b56f03…) was measured green (measured: …; root: …; score: …); ./bin/sdd health --full measures it again`, carimbo com md5 e mtime iguais; `--with-mutation` → pula; `--full` → argv `--with-mutation`, carimbo regravado; `--full --release`, `--release --full` → rc 1 `pick one`, suíte não chamada; suíte vermelha no pulo → rc 1 `suite red (rc 1) — run tests/run-all.sh to see it`, chave mantida, linha 6 do `--release` verde; sob `--full`, sobrevivente → rc 1 e chave apagada (linha 6 vermelha), suíte vermelha com score limpo, score ausente e score torto → chave mantida; janela no pulo e no catálogo → rc 1 `moved WHILE the suite/catalogue was running`, nada gravado nem apagado; Ctrl-C (`timeout -s INT 3 … --full`) → chave intacta e a rodada seguinte pula; worktree ligada do clone → pula sobre a chave do clone, `--release` linha 6 verde; commit na worktree → o catálogo grava `99f01c18…` no common dir, o clone avança `--ff-only` e pula, e segue pulando depois do `git worktree remove`; git < 2.31 (shim) → pula no clone e na worktree; cópia sem `.git` → nunca pula, `warn … is not a git checkout`. J-certify-mission-close (`./bin/sdd why <missão> PR`, `gh` falso): com a chave → `PR open`; sem → `no green mutation catalogue for this content — run 'sdd health' …`; só o `.sdd/logs/mutation-stamp` velho com a chave certa → a mesma recusa, e o health não pula sobre ele; a worktree carimba → clone e worktree abrem. Mapa: `check-mutation.sh --touched c114e36 --list` na worktree → lê o `killers.tsv` do common dir do clone (15 slugs), a semente `.sdd/cache` (302), e sem nenhum rc 2 nomeando `<common>/sdd-mutation/killers.tsv`; mapa e chaves sobrevivem ao `git worktree remove`. J-target-repo-ships (repo-alvo com o `./bin/sdd install` do clone): `gate_PR` → `PR open`, sem citar carimbo; `preflight` com git 2.43 limpo, e com o shim < 2.31 cita `The mutation stamps ('mutation_stamp_dir' …) and the killer map (tests/check-mutation.sh, 'killers_paths')` → F1. O mutante que exige `score:` para pular → `check-health.sh` com as 5 `skip:` ok, `check-gates.sh` rc 0 com 481 ok e 0 FAIL, e no clone o pulo realista sai rc 1 `health went blind to the mutation` → F2. J-suite-runs-something: não percorrida (o diff não toca a verificação 2b, o `run-all.sh` nem o TEST_CMD dos gates; a linha `TEST_CMD runs the suite (tests/run-all.sh)` saiu em todo pulo). TEST_CMD `tests/run-all.sh` no `096c625`, rodado pelo relay: rc 0, 541 s, 2055 `ok`, 0 `FAIL` (`suite-096c625.log`). Resultado: 2 achados → `F1` e `F2` `pending`, vermelhos no HEAD (F1 → `0`, F2 → rc `2`); 0 ao humano; `check-checkpoint.sh --check` → `7 row(s), 5 under the anchor rule, none blind`. Checkout principal: `status --porcelain` vazio e sem `.git/sdd-mutation`
---

# Handoff — QA — o `sdd health` pula o catálogo com a chave já medida

> Escrito no fim de cada fase. A próxima fase é uma **sessão nova sem memória**: se algo que ela
> precisa saber não está aqui (ou nos artefatos linkados), está perdido.

## TL;DR

Três jornadas percorridas no terminal, cenários S0–S19 num clone isolado; a J-suite-runs-something, decidida sem percurso.
O pulo, o `--full`, a recusa, a regra de apagar, a janela, a worktree e o `gate_PR` fazem o que a missão promete (M1
e M2 fora do sensor). Dois achados, os dois sanáveis e dentro do diff: **F1** (o `preflight` com git < 2.31 fala do
carimbo e do mapa do kit num repo-alvo) e **F2** (nenhum sensor segura o pulo sobre a suíte real, que não imprime `score:`).
0 spec (sem interface), 0 ao humano. Próximo: o runner devolve a bola ao EXEC para F1–F2; depois, a QA de novo.

## Estado do repo

- **Branch:** `fix/health-pula-catalogo`, sem upstream, não empurrada.
- **Último commit antes desta fase:** `096c625` `chore(checkpoint): note of the final review's fix wave (291d9af, 2d5d31a)`.
  Esta fase commita só este handoff, as duas linhas `F<n>` do `checkpoint.md` e uma nota no `checkpoint-notas.md`.
- **Working tree:** limpa depois do commit desta fase. Nenhum arquivo de produção foi tocado, porque a QA não conserta.
- **Suíte:** `tests/run-all.sh` no `096c625`, rodada pelo relay → rc 0, 541 s, 2055 `ok`, 0 `FAIL`
  (`/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/suite-096c625.log`; contei as linhas `ok` e `FAIL` no log).
  A QA não a rodou de novo.
- **E2E:** `E2E_CMD=""`; o kit não tem interface. Nenhuma spec, porque os dois achados moram na suíte `TEST_CMD`.
- **Checkout principal:** `git -C /home/pc_admin/repos/sdd_agents status --porcelain` → vazio;
  `/home/pc_admin/repos/sdd_agents/.git/sdd-mutation` → **inexistente**; `git worktree list` sem entrada do fixture.
  Nenhum `sdd` do PATH rodou, e nenhum `./bin/sdd health`, `run` ou `status` rodou na worktree.

## O que foi feito

QA não commita código. O que esta sessão produziu: o percurso das jornadas (abaixo), dois `F<n>` e este handoff.

### O fixture

Um clone do HEAD `096c625` em `mktemp -d` (no scratchpad da sessão), com `--no-hardlinks` para não dividir nem um
objeto com o `.git` do kit. É outro repositório, e o `.git/sdd-mutation/` que ele grava é o dele. O `tests/run-all.sh`
do clone virou um stub commitado (`2efc0e7` do clone, nunca deste repo), na forma do `write_stub_suite`
(`tests/check-health.sh:258`), com três diferenças de propósito:

- imprime `score:` **só** com `--with-mutation`, como o `tests/run-all.sh` real (`:76`, `:403–404`); o stub do sensor o imprime sempre;
- lê rc, score, `FAIL`, sono e "mover a árvore" de arquivos de controle **fora** do clone, então nenhum cenário edita
  um arquivo rastreado, e a chave só anda quando o cenário quer;
- um arquivo rastreado `tests/qa-window.txt`, ao qual o stub acrescenta uma linha no cenário da janela.

O `HOME` foi redirecionado para `$d/home`. A receita, para o re-walk dos `F<n>`:

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

### Jornadas percorridas

**J-health-verdict** (a jornada principal do diff). Cada linha é uma rodada de `./bin/sdd health` no clone, e a última
coluna diz o que aconteceu com `<common>/sdd-mutation/stamps/`:

| # | Cenário | rc | argv da suíte | Observado | Chave |
|---|---|---|---|---|---|
| S0 | `--release` antes de tudo | 1 | — | `fail line 6 · mutation stamp absent or stale` (as linhas 1–5 vermelhas pelo `HOME` vazio, sem relação) | nenhum diretório |
| S1 | 1ª rodada | 0 | `--with-mutation` | `mutation: score: 789 caught…`, `mutation stamp written — … (<clone>/.git/sdd-mutation/stamps/68b56f03…)`, `kit healthy` | `68b56f03…` gravada. A 1ª linha é a chave, depois `measured:`, `root:` e `score:`. O nome bate com a receita do `docs/failure-modes.md:1085` |
| S2 | 2ª rodada | 0 | vazio | **uma** linha `catalogue skipped — this content (key 68b56f03…) was measured green (measured: …; root: …; score: …); ./bin/sdd health --full measures it again`; `suite green`, `TEST_CMD runs the suite`, `ratchet: … none new`, `kit healthy`; nenhum `went blind`, embora a suíte não tenha impresso `score:` | intacta (md5 e mtime iguais) |
| S3 | `--with-mutation` (o hábito) | 0 | vazio | o mesmo pulo | intacta |
| S4 | `--full` | 0 | `--with-mutation` | `mutation: score: …`, `mutation stamp written` | regravada (`measured:` novo) |
| S5 | `--full --release`, `--release --full`, `--full --with-mutation --release` | 1 | não chamada | `sdd health: --full measures the catalogue, and --release never runs the suite — pick one` nas três ordens; `--bogus` → `unknown option '--bogus' (accepted: --release, --with-mutation, --full)` | — |
| S6 | `--release` com a chave | 1 | — | `ok line 6 · the mutation catalogue measured this content green, over a suite green in that same run (its key is stamped; --release re-runs nothing)` | — |
| S7 | pulo com a suíte vermelha (rc 1 e uma linha `FAIL`) | 1 | vazio | `suite red (rc 1) — run tests/run-all.sh to see it` (sem a flag), a linha `FAIL` repassada, `1 check(s) failed`; o `--release` logo depois segue com a linha 6 **verde** (decisão 3, e a frase de `291d9af` não afirma a suíte de agora) | intacta |
| S8 | `--full`, suíte vermelha, score limpo | 1 | `--with-mutation` | `suite red (rc 1) — run tests/run-all.sh --with-mutation to see it`, `ok mutation: score…`, nada gravado | intacta |
| S10 | `--full`, sem `score:` / `score:` torto | 1 | `--with-mutation` | `did not print the 'score:' line — health went blind` / `no longer parses` | intacta |
| S9 | `--full`, `788 of 789` | 1 | `--with-mutation` | `mutation: 788 of 789 caught — 1 survivor(s) … run tests/run-all.sh --with-mutation`; o `--release` passa a `fail line 6` | **apagada** |
| S9b–d | sem chave: sobrevivente, gap, e por fim verde | 1, 1, 0 | `--with-mutation` | o catálogo volta a rodar sozinho; o gap diz `open gap`; o verde regrava | regravada no S9d |
| S11 | janela, no pulo e sob `--full` (o stub muda um arquivo rastreado) | 1 | vazio / `--with-mutation` | `the measured tree moved WHILE the suite was running` / `WHILE the catalogue was running — nothing was stamped and no key was taken away` | K intacta, nenhuma chave nova |
| S12 | Ctrl-C: `timeout -s INT 3 ./bin/sdd health --full`, com o stub dormindo 20 s | 124 | `--with-mutation` | só o cabeçalho; nenhum `.tmp.` órfão; a rodada seguinte pula, e a trava não ficou presa | intacta |
| S19 | cópia sem `.git` (fora de qualquer repo), duas rodadas | 0, 0 | `--with-mutation` nas duas | `warn … is not a git checkout — no gate can demand a mutation stamp here; none written`: nunca pula (desenho, ADR 0021 §1) | — |

**M2: a worktree e o lugar compartilhado.**

| # | Cenário | Observado |
|---|---|---|
| S13 | `git -C "$d/k" worktree add --detach "$d/wt"`, `./bin/sdd health` na worktree | rc 0, argv vazio, `kit sensor at …/wt`, a linha do pulo com `root: …/k`; `--release` na worktree → linha 6 verde; o git dir próprio da worktree (`.git/worktrees/wt/`) não tem `sdd-mutation/` |
| S14 | um commit em `tests/` na worktree (chave nova), health na worktree, `git -C k merge --ff-only`, health no clone, `git worktree remove`, health no clone | a worktree roda o catálogo e grava `99f01c18…` em `<clone>/.git/sdd-mutation/stamps/`; o clone, já no commit dela, **pula** sobre essa chave (`root: …/wt`); depois do `worktree remove`, as duas chaves seguem lá e o clone segue pulando. É a M3 em miniatura, sem passo manual |
| S15 | o shim de git < 2.31 (o do `tests/check-preflight.sh:243–256`) no PATH, no clone e numa worktree nova | `old:2 new:1` (shim armado); pula nos dois, pelo braço de reserva do `git_common_dir_abs` |
| S18 | `bash tests/check-mutation.sh --touched c114e36 --list` na worktree (com o `run-all.sh` real devolvido só a ela) | só a semente `.sdd/cache` (775 linhas) → rc 0, `302 mutant(s) of the map`; nenhum mapa → rc 2, `--touched has no killer map to read (<clone>/.git/sdd-mutation/killers.tsv)`; só o compartilhado no common dir do clone (50 linhas) → rc 0, `15 mutant(s)`. Depois do `worktree remove`, `killers.tsv` e `stamps/` continuam no `.git` do clone |

**J-certify-mission-close: o passo do `gate_PR`** (`./bin/sdd why 20261026-health-pula-catalogo PR` no clone, com
um `gh` falso que confirma o PR e um `50-pr.md` não rastreado):

- S16a, chave gravada → `PR: PR open: https://github.com/example/kit/pull/1`;
- S16b, sem chave → `PR: no green mutation catalogue for this content — run 'sdd health' (since 4c86712 TEST_CMD does
  not run the catalogue, so no gate before this one measures it)`: a frase não mudou e nomeia o remédio;
- S16c, só o `.sdd/logs/mutation-stamp` velho com a chave **certa** → a mesma recusa. O `./bin/sdd health` também não
  pula sobre ele (argv `--with-mutation`);
- S16d–e, health na worktree (`wt2`), que carimba a chave → `PR open` no clone **e** na worktree.

**J-target-repo-ships** (o canário: um repo-alvo `git init` com o `./bin/sdd install` do clone, `claude` e `gh`
falhando como no `check-preflight.sh`):

- S17c: `sdd why <missão> PR` no repo-alvo, com o `gh` falso → `PR: PR open: …`, nenhuma palavra sobre carimbo,
  catálogo ou `sdd health`; nenhum `sdd-mutation/` no `.git` dele. O bloco do carimbo segue atrás do
  `has_mutation_catalogue`;
- S17a: `sdd preflight` com git 2.43 → `ok git speaks --path-format (2.31+)`, e mais nada sobre o kit;
- **S17b: `sdd preflight` com o shim < 2.31 → o `warn` diz `The mutation stamps ('mutation_stamp_dir', through the same
  'git_common_dir_abs') and the killer map (tests/check-mutation.sh, 'killers_paths') take that same fallback …` num
  repo que não tem `tests/check-mutation.sh`.** É o achado QA-1.

**J-suite-runs-something: não percorrida, de propósito.** O diff não toca o `tests/run-all.sh`, a verificação 2b
(`test_cmd_lists_only`), o `--list` nem o `TEST_CMD` que os gates rodam. O único contato é que o pulo chama
`tests/run-all.sh` sem flag, que é a própria suíte rápida que o `TEST_CMD` nomeia; e a verificação 2b continua
rodando no pulo (`ok TEST_CMD runs the suite (tests/run-all.sh)` em S2, S3, S7, S13, S14).

**A frase nova do `/sdd-plan`** (`commands/sdd-plan.md:49–53`), lida e conferida contra o medido: "Copy no killer map
into the worktree, and ask for nothing to come back after the merge: the map and the stamp live in
`<git-common-dir>/sdd-mutation/`, which the worktree shares with this checkout, so both outlive `git worktree remove`".
O lugar é esse (S1, S13, S18), os dois sobrevivem ao `worktree remove` (S14, S18), e a worktree sem cópia nenhuma lê o
mapa do principal (S18). A metade "escrever o mapa" só um catálogo real mede; aqui ela tem só o `killers_selftest`.
O Minor do I4 ("ask for nothing" diz mais que a justificativa, porque os logs `.sdd/logs/<missão>` seguem por
worktree) continua de pé, como o EXEC o deixou.

## Achados

### QA-1 → F1: o `preflight` com git < 2.31 fala da maquinaria do kit num repo-alvo

- **Onde:** `bin/sdd:6482–6488` (`cmd_preflight`, o `warn` do `git rev-parse --path-format`). A frase das linhas
  `:6485–6488` entrou na onda `291d9af` (a carona 4, `git log -S`). Na base `c114e36` o aviso só falava do
  `ledger_repo_root`, cujo ledger vale para todo repo.
- **O que a jornada promete:** a `J-target-repo-ships` diz, no nó final, "her PR opens without the kit own maintenance
  machinery ever being mentioned to her, in a message or in a gate", e o `true_end_state` diz "none names
  tests/check-mutation.sh, sdd health's catalogue, or a stamp". O aviso não tem condição de escopo e roda em todo repo.
  A Priya, num Ubuntu 20.04 ou Debian 11, lê que "the mutation stamps" e "the killer map (tests/check-mutation.sh)"
  tomam o caminho de reserva, e procura um arquivo que o repo dela não tem.
- **Medido:** S17b, e o sensor não o vê: o `check-preflight.sh` roda o shim num fixture que **é** um repo-alvo
  (`:243–268`) e lê só o prefixo do aviso.
- **Severidade:** baixa (só git < 2.31, é um `warn`, nenhum gate muda). Sanável, e nada nele espera decisão de produto.
- **Direção, a escolher pelo EXEC:** a frase do carimbo e do mapa só onde `has_mutation_catalogue "$REPO_ROOT"` (a
  mesma pergunta de artefato do `gate_PR`), ou fora do aviso, indo para o comentário. Se ficar condicionada, a regra
  nova ganha um mutante e um controle positivo, pela regra do kit.
- **Check (`F1`):** a asserção `an old git in a repo without the catalogue is not told about the mutation stamps or the
  killer map` no `check-preflight.sh` (0 no HEAD, medido: `check-preflight.sh` rc 0, 92 s, 160 `ok`), e o S17b
  percorrido de novo.

### QA-2 → F2: o pulo não tem sensor sobre a suíte que não imprime `score:`

- **Onde:** os dois stubs que rodam o caminho principal do `sdd health`: o `write_stub_suite`
  (`tests/check-health.sh:258–281`), que imprime o `score:` sempre, e o `i4_write_suite`
  (`tests/check-gates.sh:3283–3295`), que imprime a linha 2 do `stub-verdict` sempre. O `tests/run-all.sh` real só
  imprime o `score:` com `--with-mutation` (`:76`, `:403–404`), então o pulo real nunca vê um `score:`. Nenhum sensor mede essa forma.
- **Medido:** no clone, o mutante `if [ "$skip" = 1 ] && [ -n "$score_line" ]; then` no `cmd_health` (`bin/sdd:7452`),
  que um refactor da cadeia do `if` do score escreveria sem querer:
  - `check-health.sh` → as cinco `skip:` **ok** (o rc 90 do controle e do mutante vem das sondas de superfície do
    `run-all.sh`, que recusam o stub do clone e rodam depois delas);
  - `check-gates.sh` → rc 0, 481 `ok`, 0 `FAIL`, a mesma contagem do EXEC;
  - nenhum outro sensor roda o caminho principal (`grep` em `tests/*.sh`: só citações e `--release`);
  - e o health real-shaped sobre a chave do mutante: rc 1, `the suite did not print the 'score:' line — health went
    blind to the mutation`, em **todo** pulo. Seria a M1 e a M3 perdidas com a suíte verde.
- **Hoje o código está certo** (o ramo do pulo vem primeiro na cadeia, S2). O defeito é do sensor: uma `skip:` que passa
  com esse bug no lugar é decoração, e a regra "o pulo não precisa de `score:`" não tem mutante que morra.
- **Direção:** os dois stubs imprimem o `score:` só quando `$1 = --with-mutation`, como o real (os mundos que medem o
  catálogo seguem com ele, os do pulo ficam sem ele); o `mut_HEALTH_skip_needs_score` entra no `CATALOG`, endereçado a
  `/^cmd_health() {/,/^}/`, e o `--only` contra o `check-health.sh` o pega.
- **Check (`F2`):** `--only HEALTH_skip_needs_score tests/check-health.sh` → exit 0 (no HEAD → rc 2, `'HEALTH_skip_needs_score'
  is not a mutant of CATALOG`), e o S1–S2 percorrido de novo, com o stub realista.

### Hipóteses levantadas e descartadas

- **O `--touched` recusa o clone** (`SELFTEST FAIL touched: a diff of check-hat.sh selected ''`). É o fixture: o
  `touched_selftest` lê os passos do `tests/run-all.sh` real (`census_join "$ROOT/tests/run-all.sh"`), e o clone tinha o
  stub. Com o `run-all.sh` real devolvido à worktree, o selftest passa. Não é defeito.
- **O `HOME` sem `~/.gitconfig` quebraria os fixtures dos selftests.** Medido com uma identidade no `HOME` falso: não era
  a causa (era o stub, acima).
- **A ordem `--release --full` passaria.** Recusada nas três ordens (S5). O Minor do EXEC ("não tem teste") segue: o
  comportamento está certo, e um sensor durável fica para a REVIEW triar.
- **Um Ctrl-C deixaria a trava ou um temporário.** Nenhum dos dois (S12).

## Artefatos

| Arquivo | O que contém |
|---|---|
| `docs/handoffs/20261026-health-pula-catalogo/30-handoff-qa.md` | este handoff: o percurso, os dois achados, a receita do fixture |
| `docs/handoffs/20261026-health-pula-catalogo/checkpoint.md` | as linhas `F1` e `F2`, `pending` |
| `docs/handoffs/20261026-health-pula-catalogo/checkpoint-notas.md` | uma nota (append): de que achado nasce cada `F<n>` e o vermelho de cada uma no HEAD |
| `/home/pc_admin/.wt/plan-health-pula-catalogo/sdd/qa-report.md` | o relatório da QA ao relay (fora do repo) |

Nenhuma spec e2e (não há `E2E_DIR`), e nenhum `docs/qa/` foi criado nem tocado: o diretório existe, é de humanos e de
missões anteriores, e esta fase só o leu (as jornadas).

## Boot da próxima fase

**A próxima não é a REVIEW.** O `checkpoint.md` tem `F1` e `F2` `pending`, então o `current_phase()` devolve a bola ao
EXEC antes de ler o `gate_QA`. A ordem: EXEC (F1, F2) → QA de novo (re-walk e reescrita deste handoff; o `gate_QA`
recusa um handoff mais velho que o último `F<n>` `done`) → REVIEW. A missão segue **interativa, na worktree**, com todo
comando como `cd /home/pc_admin/repos/sdd_agents-health-pula-catalogo && …`. Valem as regras do boot do
`20-handoff-exec.md`: nunca o `sdd` do PATH, e nenhum `./bin/sdd health`, `run` ou `status` na worktree.

**Para o EXEC (F1, F2):**

- F1 e F2 são independentes; F2 mexe só em `tests/` e no `CATALOG`, e F1 em `bin/sdd` e no `check-preflight.sh`.
- F2: ao tornar o stub do `check-health.sh` realista, confira que os mundos que medem o catálogo continuam passando
  `--with-mutation` (todos os `health_run` sem chave passam), e que o `surface: cmd_health asks the suite for the
  mutation catalogue` segue lendo o argv. No `check-gates.sh`, o `i4_write_suite` lê o score da linha 2 do
  `stub-verdict`; a condição vai no stub, não no `i4_verdict`.
- F1: o fixture do `check-preflight.sh` é um repo-alvo, então o `assert_lacks` sobre o `$out_oldgit` já existente
  (`:261`) mede a metade "repo-alvo". Se a frase ficar condicionada ao catálogo, a metade "kit" precisa de um fixture
  que tenha `tests/check-mutation.sh`.
- Ambos: o `--only` de cada mutante novo, a suíte inteira no fim (rodada pelo relay), a catraca em 61 e
  `--anchors TODO.md` → `0 off target` (F1 mexe em `bin/sdd` acima de `:7311`, então confira as âncoras do `TODO.md`).

**Para a QA que volta:** o re-walk é a receita de *O fixture* acima, mais S17b (repo-alvo, `./bin/sdd install` do
clone, `claude` e `gh` falhando, o shim < 2.31 de `tests/check-preflight.sh:243–256`), e o `grep -cE
'check-mutation|mutation stamp|killer map'` sobre a saída → `0`. Para F2, o S1–S2 com o stub realista dá o pulo verde.

**Para a REVIEW, o que a QA viu:**

- O comportamento novo bate com as oito decisões do grill em todo cenário percorrido. Nenhuma divergência de código
  além de F1 e F2.
- A fidelidade dos stubs é o ponto fraco dos sensores desta missão (QA-2): eles imprimem o que a suíte real não
  imprime. Vale perguntar o mesmo de toda asserção `skip:` e de todo mundo do i4.
- A tensão entre o §4 do `agents/sdd-qa.md` e o `check-checkpoint.sh --red` (abaixo, fora de escopo) faz o `--red`
  recusar F1 e F2. O vermelho delas foi medido à mão e está na nota.
- Os Minor adiados do EXEC seguem para a triagem da REVIEW como estão; a QA confirmou dois pelo comportamento (a
  ordem `--release --full` recusada, e a recusa do `--touched` que nomeia só o compartilhado quando faltam os dois, S18).

## Pendências / Decisions for a Human

> Só julgamento humano genuíno (política de UX, decisão de produto, pagamento real, acesso
> externo). **Não bloqueiam o pipeline** — viram seção do PR. Bug sanável não entra aqui: vira
> incremento de fix no `checkpoint.md`.

- **Nada novo da QA.** As duas perguntas do EXEC seguem com o dono, sem mudança: a ressurreição pela semente
  (`20-handoff-exec.md`, *Pendências*, I3 `3e728d6`) e a cópia do kit sem `.git` dentro de outro repositório. Esta QA
  não as percorreu, porque nenhuma muda com o que se mediu aqui.
- **A pendência do operador, a M3 e o chore pós-merge** seguem como o `20-handoff-exec.md` os descreve. O S14 é a M3
  em miniatura (o carimbo de uma worktree chega ao principal pelo merge e o principal pula), mas o número real (≤ 20 min
  no checkout principal depois do merge) só o humano mede.

## Riscos e não-feitos

- **Nenhum catálogo real rodou**, nem nesta fase. O stub responde o `score:`, então a QA mediu o caminho do `cmd_health`
  e o lugar do carimbo e do mapa, nunca os 789 mutantes. A gravação do mapa (`write_killer_map`) só tem o
  `killers_selftest`.
- **O fixture não é o kit:** o `run-all.sh` do clone é um stub, e por isso as sondas de superfície do `check-health.sh`
  saíram `SENSOR-BROKEN` (rc 90) no clone. As medidas do QA-2 leem só as `skip:` e o `check-gates.sh`, que rodam antes
  delas ou sem elas.
- **A J-suite-runs-something não foi percorrida** (razão acima).
- **O `HOME` redirecionado** deixa vermelhas as linhas 1–5 do `--release` e pula a proveniência
  (`0 fixture(s) checked, 3 skipped`). Nenhuma das duas é da missão; a linha 6 é a única lida.
- **A doc das jornadas segue velha até a DOCS** (lista abaixo). A QA andou pelo comportamento novo.

## Achados fora de escopo

Todos do **kit**. Pela M4 a catraca fica em 61 nesta branch, então nenhum entra no `TODO.md` aqui. Vão para o **chore
pós-merge do `TODO.md`**, junto dos que o `20-handoff-exec.md` já listou:

- **O §4 do `agents/sdd-qa.md` e o `check-checkpoint.sh --red` se contradizem.** O contrato manda o Check de um `F<n>`
  levar "regression test passa **e** re-walk da jornada" (o modelo `` `<cmd>` → green AND re-walk of <journey> green ``),
  e o `--red` (`tests/check-checkpoint.sh:72–82`) recusa como "outside the strict form" toda célula com prosa depois da
  seta. Medido: `--red` → rc 1 nas duas linhas desta fase, como recusaria as `F<n>` de missões anteriores
  (`20260826-o-laco-da-qa`, `20260901-o-revisor-so-acha`). O `--red` não é gate, mas nenhum `F<n>` escrito pelo
  contrato pode ser provado vermelho pela ferramenta. Direção: uma forma estrita para o re-walk (o comando dele, com o
  esperado junto), ou o `--red` lendo só o primeiro par. → chore pós-merge.
- **Observado, sem defeito:** com uma saída de suíte curta, a linha `FAIL` sai duas vezes no `sdd health` (o
  `grep '^  FAIL  '` e depois a cauda de 15 linhas, `bin/sdd:7387–7388`). É pré-existente e é o desenho ("every FAIL
  line first, then the tail"). Fica registrado para o chore decidir se vale um item.

## Para a fase DOCS

O que o percurso mostrou velho, além da lista do `20-handoff-exec.md` § *Para a fase DOCS* (que segue valendo):

- `docs/qa/journeys/J-health-verdict.md`:
  - `:11`, "Check 2: run the mutation catalogue — 20 to 50 min": o catálogo agora é condicional (o pulo), e o tempo
    real é de horas (10 h 58 no #327);
  - `:24`, a janela "any existing stamp is REMOVED", e `:80`, "removes the stamp": hoje nada é gravado nem apagado (S11);
  - `:25`, `.sdd/logs/mutation-stamp`;
  - `:63`, `stamp-removed-on-failure`, e `:66–68`, "on any red, no stamp may remain on disk": a decisão 3 inverteu isso,
    porque uma suíte vermelha, um score ausente e a janela mantêm a chave, e só o veredito do catálogo a apaga
    (S7, S8, S10, S11). O `true_end_state` precisa ser reescrito, não só o caminho;
  - faltam o ramo do pulo, o `--full` e a recusa `--full --release` no fluxo e nos `actions`.
- `docs/qa/journeys/J-certify-mission-close.md`: `:16` "stamp file == key?", `:18` "20 to 50 min" (agora: o pulo, ou o
  catálogo de horas), `:21` e `:64` `.sdd/logs/mutation-stamp`; o `true_end_state` (`:63–64`) pode citar a receita e o
  `stamps/<chave>`, e ganhar a worktree que carimba para o principal (S14, S16).
- `docs/qa/journeys/J-target-repo-ships.md`: nada a mudar se o F1 tirar a frase do repo-alvo. Se o EXEC só a
  condicionar, a nota da jornada pode registrar que o aviso do git < 2.31 é do kit.
- `docs/failure-modes.md:1086`, "compare with .sdd/logs/mutation-stamp": a receita continua certa (S1 a usou), e o que
  muda é o lugar com que se compara (`<git-common-dir>/sdd-mutation/stamps/<chave>`).
