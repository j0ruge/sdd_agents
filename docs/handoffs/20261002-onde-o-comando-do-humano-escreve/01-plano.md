---
missao: 20261002-onde-o-comando-do-humano-escreve
data: 2026-10-02
---

# Plano — Onde o comando do humano escreve

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Medido em 2026-10-02 sobre `5e75fdc` (= `origin/main`), branch `feat/onde-o-comando-do-humano-escreve`
em `/home/joruge/repos/sdd_agents`. **Números de linha envelhecem a cada incremento:** ancore pelo
nome da função e use a linha só como ponto de partida.

**Ambiente**
- `git 2.43.0`, `Python 3.12.3`, GNU coreutils 9.4 (`timeout --kill-after`, `timeout --foreground`
  e `env --default-signal` existem), `awk` = `mawk`. Máquina com 20 núcleos.
- Suíte verde: `tests/run-all.sh` → `suite green`, rc 0, **271,4 s** com load 1,5;
  `anchors: all 532 mutants still apply and leave valid code`. Os passos rodam **em sequência**
  (`run()` é síncrono). Tempo ocioso por passo, medido com carimbo por linha:

  | Passo (nome exato do `run`) | Ocioso | Prazo decidido (I8) |
  |---|---|---|
  | `runner syntax (bash -n)` | 0,01 s | 60 s |
  | `coordination helper syntax` | 0,03 s | 60 s |
  | `entry point cannot fall through into itself` | 0,42 s | 60 s |
  | `lint: the runner and the whole suite` | 16,40 s | 180 s |
  | `language: no Portuguese prose on the kit surface` | 0,61 s | 60 s |
  | `no writer piped into grep -q (pipefail)` | 2,15 s | 60 s |
  | `findings file holds its shape` | 2,85 s | 60 s |
  | `checkpoint Checks cannot read a red assertion as green` | 1,06 s | 60 s |
  | `template contract` | 0,47 s | 60 s |
  | `gate state machine` | 64,47 s | 600 s |
  | `dry-run projection` | 3,46 s | 60 s |
  | `autonomy ledger` | 83,44 s | 720 s |
  | `kaizen series and gate` | 12,69 s | 120 s |
  | `sdd health discriminates` | 19,68 s | 180 s |
  | `preflight and the install guard` | 22,36 s | 240 s |
  | `every hat declares its boundary` | 2,06 s | 60 s |
  | `adr allocator and link check` | 7,76 s | 90 s |
  | `one checkout has one execution owner` | 28,18 s | 240 s |
  | `catalogue anchors: every mutant still applies` | 3,31 s | 60 s |
  | `mutation: the suite dies when the runner is sabotaged` (só `--with-mutation`) | ~18 min | **sem prazo próprio** |

  A regra (decisão 8 do grill) é 8 vezes o ocioso, com piso de 60 s. A margem vem de 2026-10-01:
  o mesmo `sdd health` levou 31 min com carga ~4 e 2h03 com carga ~28, cerca de 4 vezes mais.
- Rodar sensor: `bash tests/check-<x>.sh` da raiz do repo. As três suítes de hoje rodaram de dentro
  do Claude Code sem `env -u CLAUDECODE`. Tempos: check-autonomy ~83 s, check-gates ~64 s,
  check-coordination ~28 s, check-preflight ~22 s, check-health ~20 s, check-todo ~3 s.
- Em `sdd run`, toda sessão EXEC roda com `GIT_REFLOG_ACTION=sdd:EXEC:<sid8>` (`session_git_label`
  no `run_phase`). A asserção da #186 conta só `sdd:REVIEW:[0-9a-f]{8}` (`tests/check-autonomy.sh:~6476`),
  então o rótulo de EXEC não a derruba. Isso é inferido da regex; o medido foi com rótulo de REVIEW.
- O kit **é** o repo da missão (`REPO_ROOT == SDD_HOME`): a guarda de kit se exclui sozinha.

**Regras da casa que a suíte cobra (violar = vermelho)**
- `tests/check-lang.sh`: `bin/`, `tests/`, `agents/` e `docs/pipeline.md` são superfície **em
  inglês** (comentários, mensagens, nomes de asserção). Os artefatos da missão (`docs/handoffs/…`,
  `TODO.md`) são pt-BR.
- `tests/check-pipefail.sh`:
  - RULE 1: nada de `printf … | grep -q`; use herestring.
  - RULE 2: `cd` relativo dentro de `$( )` leva `CDPATH=''`; prefira `git -C`.
  - RULE 3: `grep -m` sem `-q` é proibido.
- O lint é `shellcheck -S warning` sobre `bin/sdd`, `bin/sdd-link-agents` e `tests/*.sh`.
- **Não crie arquivo novo em `tests/`.** Sensor novo entra em quatro lugares e arrasta um quinto
  (`CLAUDE.md`, "Entra lá são quatro lugares"); esta missão só acrescenta asserções a sensores que
  já existem.
- Nenhum `#` dentro de bloco continuado por `\`: quebra o comando em silêncio, e `bash -n` não acusa.
- Função com efeito em global é **chamada**, nunca `x="$(f)"`.

**Catálogo de mutação (`tests/check-mutation.sh`)**
- Cada mutante são **três linhas**, como os vizinhos: `mut_<NOME>() {` / `  sed -i '<endereço por
  função> s@…@…@' "$1"` / `}`. A receita abaixo depende desse formato. O `<NOME>` (sem `mut_`)
  entra no array `CATALOG=(` (`:4918`), perto dos irmãos (por exemplo, `RUN_intervention_*` em
  `:5190`). O `--anchors` recusa mutante definido e não listado (`catalogue_orphans`, `:~5635`) e
  mutante que não muda nada. **Mudar uma linha que um mutante existente ancora deixa o `--anchors`
  vermelho**: reaponte o mutante no mesmo commit e prove-o de novo pela receita.
- A família `mut_RUN_intervention_*` mora em `:2026` e `:2148-2154`, `mut_CLOSE_*` em `:4842-4856`,
  e `mut_APPROVE_base_branch_warn_dead` em `:2765`. Este último continua tendo de ser pego depois
  do I7.
- `sandbox()` (`:5470`) copia `bin tests templates config agents CLAUDE.md TODO.md docs/adr`, **sem
  `.git`**. Não há `--only`.
- **Receita para provar UM mutante** (segundos a minutos, sem o catálogo), da raiz do repo:
  ```bash
  d=$(mktemp -d) && cp -r bin tests templates config agents CLAUDE.md TODO.md "$d/" \
    && mkdir -p "$d/docs" && cp -r docs/adr "$d/docs/" \
    && eval "$(sed -n '/^mut_NOME() {/,/^}/p' tests/check-mutation.sh)" && mut_NOME "$d/bin/sdd" \
    && ! cmp -s bin/sdd "$d/bin/sdd" && echo applied
  bash "$d/tests/check-<sensor>.sh" >/dev/null 2>&1; echo "rc=$?"   # esperado: rc ≠ 0
  ```
  O sensor resolve `ROOT` pelo próprio caminho, então roda contra o `bin/sdd` sabotado. Prove o
  mutante **antes** de commitar: aplicou (`applied`) **e** o sensor morreu.
- Veredito do catálogo (`:5720-5747`): rc `90|91` = CATALOGUE-BROKEN; `0` = sobrevivente (ou
  known gap); `99` = sem resultado; **qualquer outro rc = pego**. `run_mutant` (`:5527`) grava o rc
  e, se ≠ 0, o `killer_of` do log. É por isso que o I9 existe.

**`TODO.md` e catraca (ler antes de mexer)**
- `tests/check-todo.sh` confere que toda âncora `arquivo:NNNN` de item aberto fica a ≤ 10 linhas de
  um símbolo que o item cita, e que o item cabe em 8 linhas. **Editar `bin/sdd` desloca linhas.** Se
  o `check-todo.sh` reclamar de âncora fora do alvo, atualize o número no `TODO.md` no **mesmo
  commit**; isso não move a catraca, porque a contagem de abertos não muda. Hoje:
  `86 finding(s), all within 8 lines, carrying anchor + date, every anchor on target`.
- **PR #195** (o 86º item, "O Red do `R<n>` prova o achado…", e a catraca 85 → 86 em
  `tests/health-baseline.txt`) foi **mergeado** em `a3d002f` (2026-10-02), e esta branch já foi
  rebaseada sobre ele. A catraca na `main` está em `todo-findings 86`; o I10 a leva a **87** pelo
  achado novo. O Check do I10 compara a catraca com a contagem real, e não com um número escrito.

**Gemba de cada issue (reproduzido; detalhe no § Problema do `00-missao.md`)**
- `checkpoint_note_intervention` (`bin/sdd:442`): `tmp="$(mktemp "${TMPDIR:-/tmp}/sdd-ck-XXXXXX")"`
  em `:455`, **antes** do `if [ "$target" = "$nf" ]`. O ramo de append (`printf … >> "$nf"`) não usa
  nem apaga o tmp. O ramo do awk faz `… > "$tmp" && mv "$tmp" "$ck"`, e se o awk falhar o tmp também
  vaza. Chamadores: `:4915` (`--budget-override`), `:7718` (`--phase`), `:8387` (`sdd retry`).
  Probes existentes: o bloco "the sibling notes file takes the note" de `tests/check-autonomy.sh`
  (`:~505-523`, helpers `nnotes`, `notes`, `$MDIR`, `$FIX`, `"$SDD" retry "$MISSION"`).
- `cmd_close` (`bin/sdd:10594`): `[ "$JIRA_ENABLED" = "true" ] || { info "JIRA_ENABLED=false — nothing to close"; return 0; }`
  em `:10599`. O ramo JIRA confere `pr_url` (`frontmatter "$MISSION_DIR/50-pr.md" pr_url`, depois
  `gh pr view … --json state`) e morre com `"PR $prurl is '$merged', not MERGED — 'sdd close' is post-merge"`.
  `close_return_home` está em `:10539`. Probes: o bloco "sdd close" de `tests/check-gates.sh`
  (`:4377-4815`; helpers `has`, `spent`, `acli_calls` em `:4492`, `close_run` em `:4503`,
  `CLOSE_HOME` lido do config do fixture em `:4656`). O item 9 (`:4800-4808`) é o controle com JIRA
  desligado. O stub `gh` desse bloco responde MERGED a tudo e é removido em `:4813`.
- `frontmatter_write` (`bin/sdd:376`): `mktemp "${file}.XXXXXX"`, `awk -v k="$key" -v v="$value"`,
  `chmod --reference="$file" "$tmp" 2>/dev/null || true` (`:399`), `mv -f "$tmp" "$file"`.
  Chamadores: `cmd_approve` (`:7444`) e `adr_declare` (`:6949`). O `adr_declare` recebe
  `$root/$spec_rel`, já resolvido por `readlink -f` em `adr_spec_relative` (`:~6985`), **logo o
  mutante do symlink só é alcançável pelo approve**.
- O install de agentes (`bin/sdd:~5072-5090`), laço `for a in "$SDD_HOME"/agents/sdd-*.md`, tem três
  ramos:
  - `[ ! -f "$target" ]` → `cp`. Um link quebrado cai aqui e o `cp` cria o arquivo no destino do
    link.
  - `cmp -s` → identical.
  - `--force` → `cp`, que escreve **através** do link (`:5082`).

  Os testes de install vivem em `tests/check-preflight.sh`, onde o `mut_RUN_install_no_guard` é
  pego. O bloco "an agent copy drifted from the kit source" (`:~298`) usa
  `AGENT=".claude/agents/sdd-executor.md"`.
- `cmd_approve` (`bin/sdd:7339`), na ordem:
  1. `gate_PLAN` com `missing *` → `die`.
  2. Bail de idempotência (`auto|humano-*`).
  3. Imprime título, corpo e incrementos.
  4. `local approved_as` (`:7397`).
  5. Duas linhas `dim` (`:7399-7400`): "…It writes aprovacao: … into 00-missao.md and commits that
     one file." Esse texto fica falso depois do I7.
  6. Comentário "The fifth door…" e "A warning and NEVER a `die`…" (`:7402-7417`).
  7. `warn_if_on_base_branch` (`:7418`, exatamente dois espaços de recuo; é a âncora de
     `mut_APPROVE_base_branch_warn_dead`).
  8. Prompt `[y/N]`, `read`, rc 66 se nada chegou.
  9. `case y`.
  10. `frontmatter_write "$m" aprovacao "$approved_as"` (`:7444`) e leitura de volta.
  11. `git add -- "$rel" && git commit … -- "$rel"` (`:7456-7461`), com a frase "Only 00-missao.md
      enters this commit." em `:7460`.
  12. Re-pergunta ao `gate_PLAN` (`:7476`).
- `adr_new` (`bin/sdd:~7037`) já tem o `case` que separa valor de `adr:` que não é caminho:
  `''|TBD|none|\<*) : ;;`. O I7 usa a mesma separação, mais o `$FRONTMATTER_ABSENT`.
- `ensure_mission_branch` (`bin/sdd:5211`), chamado hoje por `cmd_run` (`:7710`) e `cmd_retry`
  (`:8366`):
  - no-op em `DRY_RUN`, em `branch:` vazio, em `<…>` e em branch igual à atual;
  - `die` em nome começando com `-`;
  - com a branch existente, compara os hashes `--no-filters` de `00-missao.md` e `01-plano.md` com
    os do destino e morre com `"… differ or are missing on the destination branch; the working tree was not changed"`;
  - sem a branch, `git checkout -b` a partir da atual (os arquivos não rastreados vão junto);
  - depois do checkout, re-hash e `die` se mudou;
  - `ok "branch: a → b"` e `pipeline_log_line`. Este último é seguro no approve:
    `[ -n "$PIPELINE_LOG" ] || return 0` (`:2927`), e o approve não define `PIPELINE_LOG`.
- `warn_if_on_base_branch` (`bin/sdd:5175`) é uma definição só, usada por cinco portas (`CONTEXT.md:34`).
- Probes do approve em `tests/check-gates.sh:2927-~3240`:
  - fixture `AM="20260102-approve"`, `AMDIR="$FIX/docs/handoffs/$AM"`, com
    `branch: missao/20260102-approve` e JIRA desligado. Os três artefatos ficam **não rastreados de
    propósito**;
  - sub-blocos 1 (preview e `n`), 1b (rc 66), 2 (`y`), 3 (o commit: `APPROVE_FILES -eq 1`,
    `APPROVE_DIR_N -eq 3`, `^ M file.txt` continua sujo, segundo approve sem segundo commit; a
    asserção está em `:3136`), 3a (`SHUT="20260103-approve-shut"`, `:3157-3205`, com JIRA ligado,
    `versao:` placeholder e `branch: missao/20260103-approve-shut` **real**, resposta `y`, e
    `rm -rf "$SHUTDIR"` em `:3205`), 4 (`NK`, sem a chave `aprovacao:`) e 5 (`NP`). `NK` e `NP` não
    têm `branch:`.
  - O fixture `AM` **não tem a chave `adr:`** (`:2949-2958`).
  - O `$FIX` está em `main` no começo do bloco (`:2880`).
  - ⚠️ **O sub-bloco 3 codifica o defeito da #156** e é reescrito no I7.
  - ⚠️ **Depois do I7, dois fixtures trocam a branch do `$FIX`:** o `AM` (sub-blocos 2-3) e o
    `SHUT` (3a). Detalhe e conserto no I7.
- O assassino de `mut_APPROVE_base_branch_warn_dead` é **outro** bloco: `== approve on the base
  branch ==` (`tests/check-gates.sh:4294-4375`, fixture `QW="20260108-door-that-commits"`, com
  `branch:` **vazio** e respostas `n`). Ele continua válido depois do I7 porque `branch:` vazio
  mantém o caminho do aviso. **Não dê `branch:` real ao `QW`.**
- O mutante `mut_RUN_branch_switch_dead` (`tests/check-mutation.sh:2686-2688`) ancora na linha exata
  `  want="$(frontmatter "$MISSION_DIR/00-missao.md" branch)"` do `ensure_mission_branch`. O I7 a
  extrai para uma função, então o mutante tem de ser reapontado no mesmo commit. O assassino dele é
  o bloco `== the declared mission branch ==` do `check-gates.sh` (`:~3317`).
- `tests/run-all.sh`:
  - `run()` em `:101`. Imprime `\n\033[1m▸ <nome>\033[0m` e roda `"$@"`. Sob `SDD_MUTANT`, `exit 1`
    no primeiro vermelho.
  - `steps()` em `:125`, chamado duas vezes sob `SDD_MUTANT_FIRST`.
  - ⚠️ **`lint_surface` é FUNÇÃO** (`run "lint: …" lint_surface`), e o `timeout(1)` só executa
    programa. Ele lê os globais `ROOT`, `LINT_SEVERITY` e `LINT_FLOOR`.
- Probes do `run-all.sh` em `tests/check-health.sh`: o mundo FAILFAST (`:1320-1360`) copia o
  `run-all.sh` **real** para `$FAILFAST/tests/` e troca cada `tests/check-*.sh` por um stub que
  anota o próprio nome em `$FAILFAST_LOG` e falha se for `$FAILFAST_RED`. `failfast_run
  <mutant|plain> <red> [first]` publica `FAILFAST_RC`, `FAILFAST_STEPS` e `FAILFAST_OUT`. O probe do
  `killer_of` (`:1361-1385`) **sourcea** uma função curta do `check-mutation.sh` (recusa se não for
  `… { … }` de ≤ 8 linhas). É o molde para o I9. `broken()` (`:127`) sai 90.
- `tests/check-autonomy.sh`, #186:
  - `foreign_elsewhere()` em `:6465` faz `git checkout -qb elsewhere`, commit e
    `git checkout -q main`, sem limpar o ambiente;
  - mundo `RSR` em `:6470-6476`, com `reviewscope_world` (`:5995`), `foreign_stub "$RSR" roundtrip`
    (`:6385`) e `foreign_run` (`:6417`);
  - asserção `a round trip through another branch inside the window is not a crossing`, com esperado
    `trips:2 kind: hat:0 foreign:0`;
  - medido com `GIT_REFLOG_ACTION=sdd:REVIEW:deadbeef`: `got trips:4`. Foi a única falha da suíte
    inteira (443 ok, 1 FAIL no sensor).
- `tests/check-coordination.sh`, #157:
  - um heredoc Python (`python3 - "$ROOT" "$@" <<'PY'`, `:8`), com `def check(name, condition, detail="")`
    em `:73` e `def start(repo, …)` em `:202` (`subprocess.Popen` sem tratamento de sinal);
  - o laço `for number in (signal.SIGTERM, signal.SIGINT)` em `:~789` faz `send_signal`,
    `wait(timeout=8)` e as asserções `signal status: <n>` e `signal recovers: <n>`;
  - ⚠️ `subprocess.Popen(restore_signals=True)` (o default) só restaura SIGPIPE, SIGXFZ e SIGXFSZ,
    **não** o SIGINT, e um SIG_IGN herdado atravessa o `exec`;
  - medido com `bash -c 'tests/check-coordination.sh & wait $!'`: o filho nasce com `SigIgn 0x6`, e o
    SIGINT dá `subprocess.TimeoutExpired … after 8 seconds`, rc 1, sem linha FAIL.

## Arquitetura da mudança

Nenhum contrato de artefato muda. Três famílias de mudança:

1. **Portas que escrevem** (`bin/sdd`, I3–I7), cada uma chamando a definição que já existe em vez de
   uma cópia:
   - o approve passa a chamar `ensure_mission_branch` e a commitar o diretório da missão;
   - os dois ramos do close terminam em `close_return_home`;
   - a nota de intervenção cria o temporário só onde o usa;
   - o `frontmatter_write` e o install recusam symlink.

   A regra "o `branch:` é real?" vira **uma** função lida por `ensure_mission_branch` e pelo approve
   (sugestão de nome: `mission_branch_declared`; ela imprime o nome, ou nada para vazio e `<…>`).
   Hoje ela mora inline no `ensure_mission_branch`, e uma segunda cópia no approve é a forma que o
   `CLAUDE.md` recusa ("enum lido em mais de um ponto vira UMA definição").
2. **Sensores que armam o próprio veneno** (`tests/`, I1–I2): o mundo de cada um passa a rodar no
   regime hostil, em toda execução, com um piso que prova que o veneno está armado. O conserto mora
   no fixture ou no probe.
3. **A suíte com prazo** (`tests/run-all.sh` e `tests/check-mutation.sh`, I8–I9):
   - uma tabela nome → segundos ao lado de `steps()`;
   - `run()` envolve cada passo em `timeout`;
   - passo sem prazo declarado é recusado em tempo de execução (é o censo);
   - estouro fora do mutante: vermelho nomeado; dentro do mutante: rc 124;
   - o catálogo ganha o veredito "inconclusivo".

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula. Todo incremento termina assim:
1. a suíte verde (`tests/run-all.sh`) e o `tests/check-mutation.sh --anchors` verde;
2. cada mutante novo provado pela receita;
3. o commit (`<tipo>(<escopo>): <o quê>` com o porquê no corpo, em pt-BR);
4. a linha do `checkpoint.md` como último ato, com o hash curto nu na célula Commit.

### I1 — #186: o mundo da ida e volta roda sob um rótulo de sessão armado

**O quê:** o bloco da ida e volta (`RSR`) passa a rodar sob `GIT_REFLOG_ACTION=sdd:REVIEW:<8 hex>`,
armado pelo próprio sensor (por exemplo `0badc0de`) e desarmado ao fim do bloco. Os comandos git do
fixture (`foreign_elsewhere`, e o que mais o Red apontar) rodam com `env -u GIT_REFLOG_ACTION`. Um
piso novo, `the round-trip world runs under an armed session label`, prova que o veneno está armado:
- o valor está no ambiente naquele ponto; **e**
- um `git checkout` sem limpeza, num repo descartável sob esse ambiente, grava o rótulo no reflog
  (`git reflog show --format=%gs`).

**Onde:** `tests/check-autonomy.sh` (`foreign_elsewhere` em `:6465`, mundo `RSR` em `:6469-6476`).
**Por que só os checkouts:** o contador casa a linha inteira (`grep -cxE 'sdd:REVIEW:[0-9a-f]{8}'`).
Só `checkout` grava o rótulo nu; commit grava `<rótulo>: <assunto>`. Logo, só os dois checkouts de
`foreign_elsewhere` somam trips.
**Detalhes:**
- A limpeza vai **dentro** de `foreign_elsewhere`, e isso protege também o bloco `RSB` (`:6484`),
  que reusa a função.
- Precedente no próprio arquivo: `env -u GIT_REFLOG_ACTION git …` no `foreign_stub` (`:~6401-6406`).
- Arme com `export GIT_REFLOG_ACTION=sdd:REVIEW:0badc0de` antes do `reviewscope_world "$RSR"` e
  desarme com `unset GIT_REFLOG_ACTION` depois do `assert_eq`.
- O repo descartável do piso fica sob `$OUTSIDE`. Os helpers são `pass`, `fail` e `assert_eq`
  (`:41-47`).

**Como (TDD):** Red primeiro: armar o veneno sem a limpeza dá `trips:4`, já medido com rótulo
externo. Depois a limpeza, e o verde.
**Check:** ver `checkpoint.md` → `2`. Hoje dá 0: a asserção reprova sob o rótulo externo e o piso
não existe.
**Sensor durável:** o veneno armado em toda execução. Tirar a limpeza deixa a suíte vermelha sempre,
e não só dentro de uma REVIEW. Sem mutante: o catálogo sabota `bin/`, e isto é fixture de `tests/`.
**Reversível por:** `git revert` do commit.

### I2 — #157: o probe de sinal nasce com SIGINT ignorado e o filho o recebe em SIG_DFL

**O quê:** o laço de sinais (`:~789`) arma SIG_IGN para SIGINT no processo Python **só durante o
laço**, e restaura o handler anterior depois, para o Ctrl-C do humano seguir parando o sensor. Um
piso novo, `the signal probes start with SIGINT ignored, as a detached launch leaves it`, prova que
o veneno está armado. O conserto: o filho lançado por `start()` (`:202`) nasce com SIGINT em SIG_DFL,
por exemplo com `preexec_fn` que reseta SIGINT (e SIGQUIT) só no filho. Lembre que `restore_signals`
não cobre SIGINT.
**Onde:** `tests/check-coordination.sh`.
**Como (TDD):** Red com o veneno armado e sem conserto: `TimeoutExpired` em 8 s, o mesmo modo medido
lançando com `&`. Depois o conserto em `start()`, e o verde.
**Check:** ver `checkpoint.md` → `3`. Hoje dá 0: medido rc 1 com traceback.
**Sensor durável:** o veneno armado em toda execução, mais o piso. Sem mutante (só `tests/`).
**Reversível por:** `git revert`.

### I3 — #193: a nota de intervenção cria o temporário só onde o usa

**O quê:** em `checkpoint_note_intervention`, o `mktemp` sai de antes do `if` e vai para dentro do
ramo do awk. Lá, o tmp é apagado se o awk falhar (`|| rm -f "$tmp"`). O ramo de append não toca em
`TMPDIR`.
**Onde:** `bin/sdd` (`:442-476`); probes em `tests/check-autonomy.sh`, no bloco "the sibling notes
file takes the note" (`:~505`).
**Como (TDD):** dois probes, ambos vermelhos hoje:
1. `the intervention note leaves no temporary file behind`: `sdd retry` com `TMPDIR` apontando para
   um diretório privado do sensor (por exemplo `"$OUTSIDE/ck-tmp"`). Conte os `sdd-ck-*` lá dentro
   depois da nota, com `find`/glob e sem `ls | grep` (SC2010). Esperado 0, nos **dois** caminhos:
   com `checkpoint-notas.md` e sem ele (o do awk). Medido hoje: 1 por execução no caminho do
   arquivo irmão.
2. `the notes-file path writes the note with an unwritable TMPDIR`: `TMPDIR` apontando para um
   caminho que **não existe** (não use `chmod 500`, que não bloqueia root). A nota aparece em
   `checkpoint-notas.md` e é commitada sozinha. Leia a nota e o `git status`, **nunca** o rc do
   retry: a sessão stub que vem depois pode falhar por outro motivo.

**Mutante:** `mut_RUN_intervention_tmp_before_branch`, que devolve o `mktemp` para antes do `if`. A
âncora tem de casar uma linha que só existe dentro de `checkpoint_note_intervention`.
**Check:** ver `checkpoint.md` → `2`.
**Sensor durável:** os dois probes mais o mutante.
**Reversível por:** `git revert`.

### I4 — #182: o close sem JIRA confere o PR e volta à base

**O quê:** no `cmd_close`, o ramo `JIRA_ENABLED != true` deixa de sair antes da hora. Se
`50-pr.md` tem `pr_url:` e o PR não está MERGED, `die` com a **mesma** frase do ramo JIRA. A forma
recomendada é extrair a conferência existente para um ponto antes da bifurcação, e não copiar o
bloco. Nos outros casos, `close_return_home`, sem acli e sem sessão. A linha `nothing to close` pode
mudar de texto, mas continua dizendo que não há issue para fechar.
**Onde:** `bin/sdd` (`cmd_close`, `:10594-10600`); probes no item 9 do bloco close de
`tests/check-gates.sh` (`:~4800`), antes da limpeza do stub `gh` em `:4813`.
**Como (TDD):**
1. `close: with JIRA off the tree goes back to the default branch`: o fixture vai para uma branch
   de missão (`git -C "$FIX" checkout -q -b …`) com `50-pr.md` carregando `pr_url:` e o stub `gh`
   respondendo MERGED. Depois do close, `rev-parse --abbrev-ref HEAD` = `$CLOSE_HOME`, e
   `acli-calls:0` e `session-spent:0` continuam.
2. `close: with JIRA off an unmerged PR is still refused`: o stub `gh` responde `OPEN`. rc ≠ 0, a
   mensagem diz `not MERGED`, e a branch não muda.

**Mutantes:** `mut_CLOSE_no_jira_stays_put` (o ramo sem JIRA não chama `close_return_home`) e
`mut_CLOSE_no_jira_skips_merge_check` (o ramo sem JIRA pula a conferência do PR).
**Check:** ver `checkpoint.md` → `2`.
**Sensor durável:** os dois probes mais os dois mutantes.
**Reversível por:** `git revert`.

### I5 — #81: `frontmatter_write` recusa symlink, avisa quando o chmod falha e lê o valor por ENVIRON

**O quê:** três mudanças no `frontmatter_write`.
1. `[ -L "$file" ] && die "…"` antes de qualquer escrita. A frase diz que o arquivo é um link
   simbólico, e que escrever através dele cairia fora do commit enquanto substituí-lo desfaria o
   link (decisão 6).
2. `chmod --reference … || warn "…"`, nomeando o arquivo.
3. O valor chega ao awk por `ENVIRON`, não por `-v`, pelo mesmo motivo escrito no `gate_REVIEW`
   (`bin/sdd:~1590`). Não há mundo que o probe construa, porque nenhum chamador produz `\`: escreva
   esse limite no comentário e diga **qual** mundo não foi construído.

**Onde:** `bin/sdd` (`frontmatter_write`, `:376-404`); probes num sub-bloco **novo** do approve em
`tests/check-gates.sh`. Ele tem a própria missão de fixture, com `branch: <placeholder>`, para que o
I7 não mude este mundo.
**Como (TDD):**
1. `sdd approve refuses a symlinked 00-missao.md and writes nothing`: o `00-missao.md` é um link
   para um arquivo fora do diretório da missão. `y` dá rc ≠ 0 e a saída nomeia o link; o link
   continua link, o alvo continua com `aprovacao:` vazio e o HEAD não andou. Hoje: o link vira
   arquivo comum e o commit leva a troca de tipo (medido).
2. `frontmatter_write warns when it cannot keep the mode`: um shim `chmod` que sai 1, primeiro no
   `PATH` só dessa chamada (o molde é o `$FIX/.bsd` do `check-preflight.sh`). A aprovação é escrita
   **e** a saída traz o aviso.

**Mutantes:** `mut_FRONTMATTER_writes_over_link` (a guarda `-L` vira no-op) e
`mut_FRONTMATTER_chmod_silent` (o `warn` volta a `|| true`).
**Check:** ver `checkpoint.md` → `2`.
**Sensor durável:** os dois probes mais os dois mutantes.
**Reversível por:** `git revert`.

### I6 — #173: o install nunca escreve através de um agente ligado

**O quê:** no laço de agentes do install, um alvo que é symlink (`[ -L "$target" ]`, testado
**antes** dos três ramos) nunca recebe `cp`.
- Se `readlink -f` do link = `readlink -f` da fonte do kit: `ok`, ligado a este kit.
- Senão, e também para link quebrado: `warn` dizendo que é um link para `<destino>` e que não foi
  tocado. Não conta como "differs": o remédio não é `--force`.

**Onde:** `bin/sdd` (`:~5072-5090`); probes em `tests/check-preflight.sh`, perto do bloco de agente
derivado (`:~298`).
**Como (TDD):**
1. `install --force never writes through a linked agent`: `.claude/agents/sdd-qa.md` vira link para
   um arquivo de fora com bytes próprios. `sdd install --force` deixa o link como link, o md5 do
   destino igual e um aviso que contém `link`. Hoje: o destino é sobrescrito (medido).
2. `install never creates a file through a dangling link`: um link para um caminho que não existe,
   e `sdd install`. O destino continua não existindo. Hoje: o `cp` o cria.

Devolva o fixture ao estado anterior ao fim do sub-bloco: os blocos seguintes leem
`.claude/agents/`.
**Mutante:** `mut_RUN_install_writes_through_link` (a guarda `-L` vira no-op).
**Check:** ver `checkpoint.md` → `2`.
**Sensor durável:** os dois probes mais o mutante.
**Reversível por:** `git revert`.

### I7 — #156: o approve entra na branch declarada e commita o diretório da missão

**O quê:** no `cmd_approve`, quatro mudanças.
1. **Uma definição de "branch declarada"**: extraia do `ensure_mission_branch` a leitura do
   `branch:` (vazio e `<…>` → nada) para uma função que os dois chamam, por exemplo
   `mission_branch_declared`.
   - No mesmo commit, reaponte `mut_RUN_branch_switch_dead` para a leitura dentro da função nova,
     endereçado por faixa (`/^mission_branch_declared() {/,/^}/`).
   - Prove-o pela receita contra `check-gates.sh` (bloco `== the declared mission branch ==`,
     `:3315`).
   - O comentário do mutante passa a dizer que ele agora também apaga a troca do approve.
2. **Antes do prompt:** "a branch declarada é real e diferente" quer dizer `mission_branch_declared`
   não vazio **e** diferente de `git branch --show-current`, exista a branch no git ou não.
   - Nesse caso, imprima uma linha `dim` anunciando que aprovar troca para ela e commita a missão lá.
   - Senão, `warn_if_on_base_branch` como hoje (decisão 12; com placeholder ou vazio o aviso
     continua).
   - A linha `  warn_if_on_base_branch` muda de forma, então atualize a âncora de
     `mut_APPROVE_base_branch_warn_dead` (`tests/check-mutation.sh:2765-2767`) no mesmo commit e
     prove-o contra o bloco `QW`.
   - Atualize também as duas linhas `dim` de `:7399-7400` ("…and commits that one file.").
3. **Depois do `y`, antes do `frontmatter_write`:** `ensure_mission_branch`. A ordem é contrato. O
   `ensure_mission_branch` compara o hash do `00-missao.md` com o do destino, e escrever a aprovação
   antes quebraria essa comparação. Também não se troca de branch numa resposta "não". Branch
   existente com outro plano: o `die` dele, antes de qualquer escrita (decisão 4).
4. **O commit:** `git add -- <dir da missão>` mais o arquivo do `adr:` quando o valor é um caminho
   que existe (`none`, `TBD` e `<…>` ficam de fora), e `git commit … -- <os mesmos>`. Nada de `-A`:
   o arquivo sujo alheio continua sujo. Atualize a frase do corpo da mensagem ("Only 00-missao.md
   enters this commit.") e o comentário de `:7402-7417`, para dizerem o que o código faz agora, e
   preserve a decisão "never a `die`" por estar na base.

**Onde:** `bin/sdd` (`cmd_approve` `:7339-7480`, `ensure_mission_branch` `:5211`); probes no bloco
approve de `tests/check-gates.sh` (`:2927-~3240`).
**Como (TDD):** quatro probes. Os probes 3 e 4 usam cada um **uma missão própria**, porque a branch
do `AM` já existe depois do probe 2.
1. `sdd approve commits the mission directory and nothing else`: o sub-bloco 3 reescrito.
   - Antes do sub-bloco 1, acrescente `adr: docs/adr/0001-approve-fixture.md` ao frontmatter do
     `AM` e crie esse arquivo **não rastreado**. Se ele estivesse commitado e intacto, deixá-lo de
     fora não mudaria o commit, e o `mut_APPROVE_adr_file_left_out` ficaria invisível.
   - O commit tem **exatamente 4 caminhos**: `00-missao.md`, `01-plano.md`, `checkpoint.md` e o ADR.
   - O `^ M file.txt` continua sujo e não há sobra `00-missao.md.XXXXXX`.
   - O valor do `adr:` é relativo à raiz (`[ -f "$REPO_ROOT/$v" ]`, como o `adr_check_link`,
     `bin/sdd:6700`, lê `$root/$v`).
   - No `$FIX` o `ADR_CHECK` é `off` (default de `config/starter.conf:47`, e o `check-gates.sh` não o
     muda), então um ADR de fixture sem `Spec:` não fecha o gate de PLAN.
   - Rode o segundo approve (o que não pode fazer segundo commit) **ainda na branch da missão**: em
     `main` o diretório do `AM` deixa de existir, porque agora só está rastreado na branch da missão.
     Depois, `git checkout -q -- file.txt && git checkout -q main`.
2. `sdd approve with JIRA off lands on the declared branch`.
   - Parte de `main`, e depois do approve o HEAD está em `missao/20260102-approve` e a ponta de
     `main` não andou.
   - Exija a linha de anúncio antes de `approve this plan` e **zero** `you are on the base branch`.
     Sem isso, um `warn_if_on_base_branch` incondicional passaria verde.
3. `sdd approve refuses a declared branch that carries another plan`. Missão própria, por exemplo
   `20260104-approve-taken`:
   - `git checkout -q -b missao/20260104-approve-taken`, commite o diretório com um `01-plano.md` A
     e faça `git checkout -q main` (o diretório some).
   - Reescreva o diretório **não rastreado** com um `01-plano.md` B e responda `y`.
   - Exija rc ≠ 0, a frase `differ or are missing on the destination branch`,
     `grep -qx 'aprovacao:'` no `00-missao.md`, a branch atual `main`, e as pontas de `main` e da
     branch declarada intactas.
   - Depois, `rm -rf` no diretório.
4. `sdd approve with a placeholder branch stays, warns and commits the whole directory`. Missão
   própria com `branch: <…>`, em `main`, resposta `y`. Exija que continue em `main`, exatamente 1
   `you are on the base branch` antes do prompt, e um commit em `main` com os três arquivos. Não
   reaproveite o fixture do I5.

**O fixture `SHUT` (3a) também troca de branch depois do I7** (JIRA ligado e `branch:` real; o
gatilho é o `branch:`, não o `JIRA_ENABLED`):
- devolva o `JIRA_ENABLED` como hoje;
- troque o `rm -rf "$SHUTDIR"` (`:3205`) por `git checkout -q main`: o diretório sai junto com a
  branch. Como está hoje, o `rm -rf` deixaria deleções rastreadas, e todo o resto do arquivo rodaria
  nessa branch com a árvore suja;
- atualize o comentário de `:3202-3204`.

Atualize também os comentários de `tests/check-gates.sh:3060-3062` e `:3096-3101`, que descrevem o
commit de um arquivo só.
**Mutantes novos:** `mut_APPROVE_commits_only_missao` (o pathspec volta a ser só o arquivo),
`mut_APPROVE_skips_mission_branch` (a chamada a `ensure_mission_branch` no approve vira no-op) e
`mut_APPROVE_adr_file_left_out` (o ADR sai do commit; quem o mata é o probe 1, com seus 4 caminhos).
**Mutantes reapontados:** `mut_RUN_branch_switch_dead` e `mut_APPROVE_base_branch_warn_dead`; os dois
têm de seguir pegos, provados pela receita.
**Check:** ver `checkpoint.md` → `4`.
**Sensor durável:** os quatro probes mais os três mutantes novos e o antigo.
**Reversível por:** `git revert`.

### I8 — #112, parte 1: cada passo da suíte tem prazo, e o estouro é vermelho nomeado

**O quê:** em `tests/run-all.sh`, cinco peças.
1. **A tabela:** uma função `step_timeout <nome>` com `case` (a tabela do § Contexto verificado),
   ao lado de `steps()`. `0` quer dizer "sem prazo" e só vale para o passo do catálogo.
2. **O censo:** `run()` recusa, em vermelho e com mensagem, um passo sem entrada na tabela. A suíte
   real verde passa a provar que todo passo tem prazo.
3. **O `timeout`:** `run()` roda o passo sob `timeout --foreground --kill-after=10 <N>`.
   - Por que `--foreground` (decisão do planner, decisão 12): sem ele, o `timeout` se move para um
     grupo de processos próprio. O Ctrl-C do terminal deixaria de chegar ao passo, e o bash, que
     espera o filho, segura o SIGINT até o passo acabar.
   - O preço, declarado no comentário: num estouro, só o processo de topo do passo morre, e
     descendentes podem sobreviver.
   - Nos gates, a saída vai para arquivo (`run_check_cmd`, `bin/sdd:765`), então um descendente vivo
     não trava a leitura.
4. **Passo que é função:** para `lint_surface`, use `export -f lint_surface`, exporte `ROOT`,
   `LINT_SEVERITY` e `LINT_FLOOR`, e rode `timeout … bash -c lint_surface`. **Não** a mova para um
   arquivo novo em `tests/` (os quatro lugares).
5. **O estouro:** rc 124 ou 137 **e** tempo decorrido ≥ N (`$SECONDS`; um sensor pode sair 124 por
   conta própria) → `printf` em stderr `  ✗ <nome> timed out after N s`, `fails++`, e a suíte segue.
   O ramo dentro do mutante é o I9.

**Onde:** `tests/run-all.sh`; probes no mundo FAILFAST de `tests/check-health.sh` (`:1320`). O stub
ganha um modo lento, por exemplo `[ "${0##*/}" != "${FAILFAST_SLOW:-}" ] || sleep 30`, e uma cópia
do `run-all.sh` tem o prazo de um passo rebaixado para 1 s por `sed`. O probe **morre alto**
(`broken`) se o `sed` não mudou o arquivo.
**Como (TDD):** três probes.
1. `surface: a step that outlives its timeout is red and named, and the suite goes on`: modo plain,
   rc 1, `timed out after 1 s` no stderr, e os passos depois do lento rodaram (`FAILFAST_STEPS`).
2. `surface: every step of the suite carries a timeout`: numa cópia sem a entrada de um passo, esse
   passo fica vermelho com a mensagem de prazo não declarado.
3. `surface: an interrupt still stops the suite while a step runs`: lance a cópia com o stub lento
   via `setsid env --default-signal=INT …/run-all.sh &`. Sem o `env`, o `&` de shell não interativo
   nasce com SIGINT ignorado, que é a #157. Mande `kill -INT -- -<pgid>`, como faz um terminal, e
   exija fim em poucos segundos, com rc ≠ 0.

**Check:** ver `checkpoint.md` → `3`.
**Sensor durável:** os três probes. Sem mutante: o catálogo sabota `bin/`, e a composição do
`run-all.sh` já é medida pelo FAILFAST.
**Reversível por:** `git revert`.

### I9 — #112, parte 2: dentro do mutante, estouro é inconclusivo e nunca pego

**O quê:**
1. **No `run()`:** sob `SDD_MUTANT`, um estouro imprime a mesma linha e sai **124**, não 1.
2. **No `check-mutation.sh`:** a classificação de rc do laço do veredito (`:5720-5747`) vira uma
   função curta (`rc_verdict <rc>` ou similar, ≤ 8 linhas, para o `check-health.sh` poder sourceá-la
   como faz com o `killer_of`).
   - Ela ganha o ramo `124` → `fail "TIMED-OUT: <slug> — a step outlived its timeout inside the mutant; inconclusive, never caught"`
     e `errors++`, nunca `caught++`.
   - O `run_mutant` (`:5527`) não grava assassino para rc 124.
3. **No `sdd health`:** um inconclusivo deixa o catálogo vermelho (`errors > 0`) e sem carimbo.

**Onde:** `tests/run-all.sh`, `tests/check-mutation.sh`; probes em `tests/check-health.sh`.
**Como (TDD):** dois probes.
1. `surface: inside a mutant a timeout is not a kill`: o mundo FAILFAST em modo mutante com o stub
   lento dá rc 124, e a suíte para no passo lento.
2. `surface: the catalogue reads a timed-out mutant as inconclusive, never caught`: sourceie a função
   do veredito com a mesma guarda do `killer_of`, e prove em diferencial: 124 → inconclusivo,
   1 → pego, 0 → sobrevivente.

**Check:** ver `checkpoint.md` → `2`.
**Sensor durável:** os dois probes. O `--anchors` segue verde (a função nova não é mutante).
**Reversível por:** `git revert`.

### I10 — TODO.md: `RESOLVED by` nos oito itens e o achado do `adr_declare`

**O quê:**
1. **`RESOLVED by <hash curto>`** no corpo de cada um dos oito itens, com o hash do commit de código
   do incremento (leia as células Commit do `checkpoint.md`):

   | Issue | Incremento | Título do item |
   |---|---|---|
   | #186 | I1 | "A ida e volta de branch do `check-autonomy.sh` herda o rótulo da sessão REVIEW" |
   | #157 | I2 | "`check-coordination.sh` reprova quando herda SIGINT ignorado" |
   | #193 | I3 | "`checkpoint_note_intervention` vaza um arquivo vazio em `/tmp` a cada nota" |
   | #182 | I4 | "`sdd close` sem JIRA não volta à base" |
   | #81 | I5 | "`frontmatter_write` confia em três coisas que não valem sempre" |
   | #173 | I6 | "Com os chapéus ligados por symlink, o `sdd install --force` de outro kit escreve no kit ligado" |
   | #156 | I7 | "`sdd approve` commita na branch corrente, mesmo a padrão, e só o `00-missao.md`" |
   | #112 | I8 e I9 (cite o I9) | "A suíte não tem `timeout` em lugar nenhum" |

   O item continua até o merge (ciclo de vida em `templates/todo.pt-BR.md`). **Não passe de 8
   linhas por item**: acrescente o token ao fim de uma linha existente quando couber.
2. **Um achado novo:** o `chmod --reference … 2>/dev/null || true` de `adr_declare`
   (`bin/sdd:~6962` e `~6981`) engole a falha como o `frontmatter_write` engolia. É o yokoten da #81,
   e o symlink não o alcança. Formato do `templates/todo.pt-BR.md`: título, âncora `bin/sdd:NNNN` a
   ≤ 10 linhas de um símbolo citado, data, e "— descoberto por `sdd-planner` na missão
   `20261002-onde-o-comando-do-humano-escreve` (2026-10-02)".
3. **A catraca:** `tests/health-baseline.txt`, linha `todo-findings`, sobe +1 no **mesmo** commit.

**Onde:** `TODO.md`, `tests/health-baseline.txt`.
**Como:** o `tests/check-todo.sh` mede a forma e o Check compara a catraca com a contagem real.
**Check:** ver `checkpoint.md` → `8` e `1`.
**Sensor durável:** `tests/check-todo.sh`, na suíte, e a catraca do `sdd health`.
**Reversível por:** `git revert`.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| O approve do fixture troca a branch do `$FIX` e os blocos seguintes do `check-gates.sh` rodam noutra branch (I7) | alta | Gravar a branch antes e devolvê-la depois de cada approve que trocar; a suíte inteira verde é o Check |
| Prazo apertado demais sob carga dá vermelho falso no catálogo (I8/I9) | baixa | 8 vezes o ocioso com piso de 60 s. Dentro do mutante o estouro é inconclusivo e nomeado, nunca um ponto falso. Ajuste da tabela é commit com autor |
| `--foreground` deixa descendentes vivos num estouro (I8) | média | Limite declarado no comentário. Nos gates a saída vai para arquivo, e nada espera o pipe |
| Um sensor sai 124 por conta própria e é lido como estouro (I8) | baixa | Discriminar pelo tempo decorrido (`$SECONDS` ≥ N) |
| O probe de "TMPDIR inacessível" esbarra noutro `mktemp` antes da nota (I3) | baixa | Medido: o único `mktemp` em `TMPDIR` no caminho do `sdd retry` é o `:455`; o resto usa `log_dir` ou o diretório do arquivo. A asserção lê a nota, não o rc |
| Âncoras do `TODO.md` saem do alcance depois de editar `bin/sdd` | média | Atualizar o número no mesmo commit (não move a catraca) |
| PR #195 mergeado antes: conflito em `tests/health-baseline.txt` | média | Rebase; o valor é o da `main` + 1 |
| `preexec_fn` com threads no processo do harness (I2) | baixa | O harness principal não cria threads (elas vivem nos filhos `barrier.py`). Se o Red mostrar o contrário, resetar o SIGINT no pai com um handler (não SIG_IGN) só em volta do `Popen` |

## Para a fase DOCS (drift conhecido)

O `sdd-docs` escreve `README.md`, `CLAUDE.md`, `CONTEXT.md`, `docs/**`, `templates/**`, `agents/**`,
`.claude/agents/**` e `KAIZEN_LOG.md`. Para `.claude/rules/**` só propõe texto `⛔`. Conferido em
`5e75fdc`:
- `README.md:74`, a linha do `sdd approve` ("write the human approval and commit it"): agora também
  entra na branch declarada e commita o diretório da missão.
- `README.md:57`, `sdd-link-agents`: o `install --force` deixou de escrever através dos links.
- `docs/pipeline.md:176`, `sdd approve … writes humano-<date> and commits`: idem.
- `docs/pipeline.md:584`, a linha `JIRA_ENABLED=false | not an error — reports "nothing to close" and exits 0`,
  e `:596-603` (a volta à base): agora vale também sem JIRA, com a conferência do PR.
- `CONTEXT.md:34` ("Portas que commitam"): o approve também troca de branch.
- `CLAUDE.md`, § "TDD aqui dentro": a suíte tem prazo por passo, e dentro do mutante o estouro é
  inconclusivo (rc 124).
- `docs/failure-modes.md`: um verbete para `timed out after N s` (sintoma e saída) e para o
  `TIMED-OUT` do catálogo.
- `agents/sdd-planner.md`, § 8 (Branch): o approve também entra na branch. Depois de editar
  `agents/*.md`, sincronize o espelho com `sdd install --force` (regra do `CLAUDE.md`).
- `templates/missao.md`: o texto do placeholder de `branch:` diz "sdd run/retry faz checkout dela";
  agora o approve também. ⚠️ `templates/` está na chave do carimbo: editar aqui exige o
  `sdd health` **depois** da DOCS.
- `KAIZEN_LOG.md`: a entrada com o antes e depois medido.
- `.claude/rules/anatomia-do-agente.md`, § 4 (o veredito inconclusivo do catálogo) e § 7 (a porta do
  approve): texto proposto, linha `⛔` no `45-docs.md`.
- **O comentário em `bin/sdd:~7402-7417` NÃO é da DOCS:** é do I7, porque a DOCS não escreve `bin/`.

## Verificação end-to-end

Com todos os incrementos `done`:
1. `tests/run-all.sh` → `suite green`, incluindo `anchors: all N mutants still apply` (N = 532 + os
   mutantes novos).
2. `GIT_REFLOG_ACTION=sdd:REVIEW:deadbeef tests/run-all.sh` → `suite green` (métrica 1).
3. `bash -c 'tests/run-all.sh > "$HOME/.cache/sdd-detached.log" 2>&1 & wait $!'; echo $?` → `0`
   (métrica 1, SIGINT ignorado).
4. Antes e depois de uma suíte, a contagem de `/tmp/sdd-ck-*` não muda (métrica 2).
5. Cada mutante novo provado pela receita (rc ≠ 0 no sensor indicado).
6. **Humano:** `./bin/sdd health` uma vez, depois da DOCS e da última rodada dos revisores →
   N de N e carimbo (métrica 7).
