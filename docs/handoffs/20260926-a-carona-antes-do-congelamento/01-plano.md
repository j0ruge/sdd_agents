---
missao: 20260926-a-carona-antes-do-congelamento
data: 2026-09-26
---

# Plano — a carona antes do congelamento

> **Teste de autocontenção:** uma sessão nova, sem nenhuma memória da conversa que gerou este
> plano, lendo apenas `00-missao.md` + `01-plano.md` + `checkpoint.md`, consegue executar?
> Se a resposta for "só se souber X", **X vai escrito aqui**.

## Contexto verificado (não re-descobrir)

Tudo abaixo foi medido em `3c44df8` (`main`, 2026-09-26), de onde a branch
`fix/a-carona-antes-do-congelamento` foi cortada. Os números de linha **andam** conforme os
incrementos editam os arquivos: confie no **nome da função** e use a linha só como ponto de partida.

### Como executar

- **Interativo, uma sessão por incremento, na ordem I1 → I7.** Nunca `sdd run` neste repo (ver
  `00-missao.md`). Ciclo de cada incremento:
  1. o probe novo primeiro, e ele tem de ficar **vermelho pelo motivo certo** (o `rc`, o texto do
     ramo certo e a ausência do marcador do outro ramo);
  2. o código;
  3. o mutante novo, provado pela **receita M** abaixo;
  4. suíte verde, com `--anchors` verde;
  5. âncoras do `TODO.md` em `0 off target`;
  6. commit(s);
  7. a linha do `checkpoint.md` em `done` com o hash curto **nu** (sem crase), e uma nota em
     `checkpoint-notas.md` com `>>`.
- **Suíte:** `tests/run-all.sh`, o `TEST_CMD`, com 16 sensores e ~3,5 min. Rode em **primeiro
  plano**, nunca como tarefa de fundo do Bash tool: o hook do repo apaga `/tmp/sdd-*` com mais de
  10 min a cada commit, e o watchdog de memória já matou suíte de fundo. Um sensor sozinho:
  `bash tests/check-<x>.sh`. Tempos medidos nesta sessão: `check-gates` 48 s, `check-autonomy` 50 s,
  `check-coordination` 30 s, `check-health` 30 s, `check-preflight` 27 s, `check-kaizen` 19 s,
  `check-adr` 10 s, `check-dry-run` 4 s.
- `bash -n bin/sdd` é o smoke mínimo. O lint do `run-all.sh` passa o shellcheck no `bin/sdd` e em
  `tests/*.sh`.
- **Formato dos sensores:** todo sensor imprime `  ok    <asserção>` (2 espaços, `ok`, 4 espaços) na
  stdout e `  FAIL  <asserção>` na stderr. O `assert_eq <desc> <esperado> <obtido>` do
  `check-autonomy.sh:40` e o `assert_adr <desc> <fixture> <rc> <regex> <args…>` do
  `check-adr.sh:293` imprimem o `<desc>` como asserção. **O texto da asserção de cada Check do
  `checkpoint.md` é contrato:** escreva a asserção com exatamente aquele texto.
- **Receita M: provar um mutante sem o catálogo.** Na raiz do repo:

  ```bash
  d=$(mktemp -d); cp -r bin tests templates config agents CLAUDE.md TODO.md "$d/"
  mkdir -p "$d/docs" && cp -r docs/adr "$d/docs/"
  eval "$(sed -n '/^mut_<SLUG>() {/,/^}/p' tests/check-mutation.sh)"
  mut_<SLUG> "$d/bin/sdd"; cmp -s bin/sdd "$d/bin/sdd" && echo "NAO APLICOU"
  SDD_MUTANT=1 bash "$d/tests/<sensor>.sh" >/dev/null 2>&1; echo "rc=$? (esperado: != 0)"
  ```

  "NAO APLICOU" é conclusão **inválida**: a âncora apodreceu e o probe não sabotou o que diz
  sabotar. Os mutantes do `sdd-coordination.py` recebem `"$d/bin/sdd"` e editam `"${1%/*}/…"`. O
  catálogo inteiro **nunca** roda por incremento (é o `sdd health`, no fim).
- **Catálogo de mutação** (`tests/check-mutation.sh`):
  - cada mutante é `mut_<SLUG>() { sed -i '<âncora em CÓDIGO>' "$1"; }`, mais o `<SLUG>` na lista
    `CATALOG=(` (`:4271`, hoje com 406 entradas);
  - o piso é `ANCHOR_FLOOR=404` (`:4800`): **suba-o pelo número de mutantes que o incremento
    acrescenta**;
  - `bash tests/check-mutation.sh --anchors` leva segundos e reprova mutante cuja âncora não se
    aplica mais. Roda dentro da suíte rápida.
  - Já existem mutantes ancorados em linhas que esta missão edita. **Atualize a âncora no mesmo
    commit**:
    - `mut_RUN_harness_env_inherited` (`:1794-1796`), ancorado em
      `local -a cmd=(env "${HARNESS_ENV_UNSET[@]}" claude -p "$prompt"` (I3);
    - `mut_RUN_review_scope_quotepath_default` (`:3917`), ancorado em
      `-c core.quotePath=false diff --name-only` dentro do `hat_guard_check` (I4);
    - `mut_RUN_hat_guard_blind` (`:1452`), ancorado em `[ -n "$globs" ] || return 0` (I4);
    - `mut_RUN_hat_guard_ignores_prior_dirt` (`:1771`), ancorado em
      `HAT_STATUS_BEFORE="$(hat_status_lines)"` (I4);
    - `mut_REVIEW_floor_ignored` (`:707`) lê `rank(grade) < rank(floor)`, que o I1 não deve tocar.
- **Âncoras do `TODO.md` (ADR 0011):** todo item cita um símbolo em crase que ocorre a até 10 linhas
  da linha ancorada. Editar o `bin/sdd` ou um `tests/*.sh` desloca linhas, e o
  `tests/check-todo.sh` (passo "findings file holds its shape" da suíte) fica vermelho. Depois de
  editar, rode:

  ```bash
  bash tests/check-todo.sh --anchors TODO.md bin/sdd   # hoje: 37 measured, 0 off target
  bash tests/check-todo.sh --anchors TODO.md tests/    # hoje: 31 measured, 0 off target
  ```

  Cada violação nomeia a ocorrência mais próxima: troque o número no `TODO.md` **no mesmo
  commit**.
- **Espelho dos chapéus:** mexeu em `agents/*.md`, rode `./bin/sdd install --force`, que reescreve
  `.claude/agents/` (**versionado**, conferido pelo `sdd preflight`). Commite os dois juntos. Nunca
  `cp`, nunca Edit no espelho.
- **Idioma:** `bin/`, `tests/`, `agents/`, `docs/` (inclusive `docs/adr/`), `README.md` e
  `config/schema.md` são **inglês**, e o `tests/check-lang.sh` cobra. São pt-BR: `templates/`,
  `CONTEXT.md`, `CLAUDE.md`, `KAIZEN_LOG.md`, `TODO.md`, a rule `.claude/rules/anatomia-do-agente.md`
  e `docs/handoffs/`.
- `sdd preflight` de dentro do Claude Code: `env -u CLAUDECODE ./bin/sdd preflight`.
- **A gaveta** (`docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`): frente que anda muda a
  célula "Estado" da sua linha **no mesmo commit** (regra do `CLAUDE.md`). A F5 anda no I1, no I2 e
  no I4; a F4 anda no I5, no I6 e no I7; a F2 e a F3 andam no I7.
- **Commits:** `<tipo>(<escopo>): <o quê>`, com o porquê no corpo e o rodapé de atribuição que a
  sessão usar. Nunca commite com um `sdd health` rodando.

### #50 — o `adr_link` (`bin/sdd`)

- `ADR_LINK_PRE='^(- )?(\*\*)?'` e `ADR_LINK_POST='(\*\*)?:[[:space:]]*'` (`:5742-5743`), e
  `adr_key_re()` (`:5744`) junta os dois. É **uma** definição, lida em três escopos: mission, repo e
  spec. O escritor `adr_declare` também a lê, no awk de `:6170`, via `ENVIRON`.
- `adr_link <arquivo> <chave>` (`:5793-5813`):
  - publica `ADR_LINK_NO` e `ADR_LINK_VALUE`, e é chamado, nunca `$( )`;
  - `ADR_LINK_NO` é gravado **antes** de o valor ser extraído, então continua preenchido quando a
    linha existe e o valor sai vazio;
  - o valor é a primeira palavra depois da chave (`${ADR_LINK_VALUE%%[[:space:]]*}`), sem `(` na
    frente e sem `)` e `.` atrás (`:5809-5811`);
  - termina em `[ -n "$ADR_LINK_VALUE" ]`.
- Reproduzido com a regex do runner:
  - `**Spec:** docs/handoffs/x/00-missao.md` → `[**]`;
  - `` **Spec**: `docs/handoffs/x/00-missao.md` `` → o caminho com as crases;
  - `- **Spec**: …` e `Spec: …` → o caminho, certo.
- `adr_check_link()` (`:5906`) chama `adr_link "$root/$v" Spec` (`:5939`):
  - falha em "has no 'Spec:' line";
  - valor diferente de `$rel` → `adr_fail … "'Spec: $ADR_LINK_VALUE' points somewhere else, not at
    $rel" "one ADR, one spec: fix whichever side is wrong, …"` (`:5945-5946`).
- `adr_fail <arquivo> <linha> <motivo> <remédio>` (`:5765`) imprime `  FAIL  <arq>:<linha> —
  <motivo> — <remédio>` na stderr.
- `tests/check-adr.sh`:
  - o fixture `M` (`:418`) é o escopo mission, "deliberadamente cheio de links quebrados", e usa as
    ADRs 0009 a 0013;
  - o probe do outro dialeto é ``the `- **Spec**:` dialect is read by the same rule`` (`:469-476`),
    que escreve o ADR com `printf` direto;
  - `PROBE_FLOOR=69` (`:204`): suba pelo número de asserções novas;
  - o cabeçalho lista as regras R1–R32 (`:10-70`) e a passada de sabotagem (`:88-125`). Regra nova
    entra nas duas listas;
  - os mutantes `mut_ADR_*` ficam em `tests/check-mutation.sh:4012-4140`.

### Yokoten da crase — `gate_REVIEW` e `gate_DOCS` (`bin/sdd`)

- `gate_REVIEW()` (`:1331`), no awk da tabela `### Overall Grade`:
  - `crit = f[2]; grade = f[3]; rat = f[4]` (`:1464`);
  - `gsub(/\*/, "", grade)` (`:1466`) tira só o `*`, enquanto a justificativa já tira `*` e crase:
    ``gsub(/[*`]/, "", rat)`` (`:1467`);
  - `rank(g) = index("FDCBA", substr(g, 1, 1))` (`:1400`);
  - resultado: `` `A` `` vira `grade != "A"` e o motivo sai `` STRICT … Correctness = `A` ``.
- `gate_DOCS()` (`:1541`): acha a coluna `Status` pelo cabeçalho, apara espaço e compara literal com
  `✅`, `n/a` ou `N/A` (`:1570`). Então `` `✅` ``, `` `n/a` `` e `**✅**` contam como pendentes.
- ⚠️ **O `awk` é o `mawk` 1.3.4, orientado a byte.** A crase e o `*` são ASCII, e ``gsub(/[*`]/, …)``
  é seguro. **Nunca** escreva classe negada com `✅` ou `✗` (multibyte), que o `CLAUDE.md` proíbe.
- `tests/check-gates.sh`:
  - REVIEW em `:1061`, com o helper `review_with <nota Security> <nota Documentation>` (`:1102`),
    que escreve a r1 no formato do template;
  - DOCS em `:1678`, com as tabelas escritas por `printf`;
  - os helpers `assert_phase <desc> <fase>` (`:45`), `assert_why <desc> <fase> <regex>` (`:57`) e
    `assert_why_absent` (`:77`);
  - o fixture principal está em `$FIX`, com a missão `$MISSION`.

### #52 — `cmd_approve` (`bin/sdd:6534`)

- A pergunta e a leitura:
  - `printf '  approve this plan? [y/N] '` (`:6614`);
  - `local ans=""; read -r ans || ans=""` (`:6617-6618`);
  - `info ""`;
  - `case "$ans" in y|Y|yes|Yes|YES) : ;; *) info "  not approved — nothing was written"; return 0 ;; esac`
    (`:6622-6625`).
- Semântica de hoje, que **fica** fora do caso novo:
  - `<<< "n"` e `<<< ""` (Enter) → rc 0, "not approved";
  - `<<< "y"` → aprova;
  - uma linha parcial sem `\n` (`read` sai ≠ 0 com `ans` preenchido) → descartada, "not approved",
    rc 0.
- **O caso novo:** `read` sai ≠ 0 **e** `ans` vazio, ou seja, não chegou nenhum caractere. Medido:
  no Bash do harness o stdin é `/dev/null`, `read` sai 1 e `[ -t 0 ]` é falso.
- O rc atravessa a coordenação: o supervisor devolve `waitstatus_to_exitcode` do worker
  (`bin/sdd-coordination.py`), e o único rc que ele reserva é 75 (`BUSY`). `main()` (`:9558`)
  retorna o rc de `cmd_approve`.
- `tests/check-gates.sh`:
  - seção `== sdd approve ==` em `:2143`, com a missão `AM` (`20260102-approve`, `:2159-2175`, **já
    tem `branch:`**);
  - `n` e Enter em `:2215-2233`;
  - `y` em `:2265-2283`;
  - use herestring ou `</dev/null`, **nunca** `printf … | sdd approve`: sob `pipefail` o pipe
    devolve 141.
- Mutantes vizinhos: `mut_RUN_approve_writes_auto` (`:2280`), `mut_RUN_approve_bails_on_kaizen_born`
  (`:2302`) e `mut_RUN_approve_no_plan_blind` (`:2317`).
- A prosa que descreve o comando está em `README.md:103-111` e `docs/pipeline.md:162-168`.

### #51 — a fronteira do chapéu (`bin/sdd`)

- **Globais:** `HAT_CROSSED_WHY` (`:3101`), `KIT_TOUCHED_WHY` (`:3102`) e `HAT_STATUS_BEFORE`
  (`:3103`). O cabeçalho da família, com os "DECLARED LIMITS", está em `:3047-3100`.
- **`hat_guard_arm()`** (`:3110`) só fotografa o `git status` (`HAT_STATUS_BEFORE`). Em `DRY_RUN`
  sai vazio.
- **`hat_guard_check <fase> <HEAD antes>`** (`:3144`), na ordem:
  - zera `HAT_CROSSED_WHY`;
  - retorna em `DRY_RUN`;
  - `step="$LAST_PHASE_STEP"` e `hat="$(phase_hat "$step")"`;
  - a metade MCP/ferramentas, que arma e retorna;
  - `globs="$(hat_writes "$step")"` e `[ -n "$globs" ] || return 0`: o **executor não tem
    `writes:`** e sai aqui;
  - a metade diff: `git -C "$REPO_ROOT" -c core.quotePath=false diff --name-only "$before"
    "$head_now"` (`:3164`), **o intervalo inteiro**;
  - a metade status: `hat_status_lines` menos `HAT_STATUS_BEFORE`;
  - `hat_path_allowed` filtra;
  - arma `HAT_CROSSED_WHY="the $step session ($hat) touched $n path(s) outside its writes: $outside"`,
    mais `warn`, `HAT-CROSSED` e `HAT-REMEDY` no journal.
- **`hat_crossed_escalation <fase>`** (`:3191`):
  - `HAT_CROSSED_WHY` → `kind="hat-crossed"`, depois `KIT_TOUCHED_WHY` → `kind="kit-touched"`;
  - `bad "BLOCKED in $phase — $why"`, as linhas `dim` do remédio (as de `HAT_WRITES_EXTRA` só para
    `hat-crossed`), `BLOCKED` no journal (`:3211`) e `autonomy_blocked_row "$kind" "$phase" "$why"`;
  - devolve 0 para parar.
- **As quatro portas** (arm → sessão → check → escalada):
  - 1ª passada do `cmd_run` (`:7196-7205`, escalada em `:7283`);
  - retry inline (`:7319-7342`, `:7390`);
  - `cmd_retry` (`:7563-7586`);
  - `cmd_close` (`:9734-9825`), com o `claude` **próprio** em `:9779`, que não passa pelo
    `run_phase`.

  O `cmd_kaizen` chama `run_phase KAIZEN` (`:9282`, `:9309`) sem guarda, e isso é limite
  declarado.
- **`run_phase()`** (`:3674`):
  - `sid="$(uuidgen)"` (`:3701`), fresco a cada chamada, inclusive no retry;
  - o comando é `local -a cmd=(env "${HARNESS_ENV_UNSET[@]}" claude -p "$prompt"` (`:3734`), e
    `HARNESS_ENV_UNSET` está em `:3670`;
  - o log se chama `${phase}-<data>-${sid:0:8}.json` (`:3781`);
  - publica `LAST_PHASE_*`, com os globais em `:3912-3921`;
  - no retry o claude recebe `--resume "$resume_sid" --fork-session`, e o `$sid` fresco continua
    sendo o da invocação.
- **O `cmd_close`** tem `sid="$(uuidgen)"` próprio (`:9717`) e roda
  `env -u CLAUDE_CODE_EFFORT_LEVEL -u CLAUDE_EFFORT claude -p …` (`:9779`).
- **O rótulo, medido nesta sessão** (git 2.43.0, repo de scratch):
  - `GIT_REFLOG_ACTION="sdd-session abc123" git commit -qm "session commit"` grava
    `sdd-session abc123: session commit`, e o commit sem a variável grava `commit: human commit`;
  - com `GIT_REFLOG_ACTION="sdd:EXEC:ab12"`: `checkout -b` grava `sdd:EXEC:ab12`,
    `commit --amend` grava `sdd:EXEC:ab12: amended` e `reset --hard` grava
    `sdd:EXEC:ab12: updating HEAD`;
  - `git reflog show --date=unix --format='%gd%x09%H%x09%gs' HEAD` imprime
    `HEAD@{1790450214}<TAB><sha40><TAB><assunto>`. Três entradas feitas no mesmo segundo têm o
    **mesmo** `%gd`: a identidade de uma entrada é a linha inteira, não o carimbo.
- **O `env` só aceita atribuição depois das opções.** `env -u A -u B NOME=v cmd` funciona;
  `env NOME=v -u A cmd` executaria `-u` como comando. O rótulo entra entre o último `-u` e o
  `claude`.
- **A transcrição não serve** (medido): nos 8 streams EXEC mais recentes do `sales_quote` há 12
  chamadas de `git commit`, todas com `-q`, e 0 SHAs impressos.
- **`tests/check-dry-run.sh:238-239`** conta, por bloco de fase projetado, a string literal
  `env -u CLAUDECODE … -u CLAUDE_EFFORT claude -p`. Com o rótulo no meio ela deixa de casar: o I3
  muda essa asserção. A projeção imprime o comando com `printf '  %q'`, e `%q` não escapa `=` nem
  `:`.
- **`tests/check-autonomy.sh`**:
  - `assert_eq` (`:40`);
  - o bloco "hat boundary" (`:5000-5165`), com `hat_stub <caminho> <commit|leave> [dispara na n-ésima]`
    (`:5011`), `hat_rows` (lista os `kind` das linhas `blocked`) e `hat_reset`;
  - o mundo de review `reviewscope_world <dir>` (`:5674`), com `git init -q -b main` e a missão sem
    `branch:`, mais `reviewscope_stub <dir> <dispara na> <code|clean> [extra]` (`:5740`) e os regimes
    RS1–RS7 (`:5790-5960`): RS1 é a porta 1, RS3 a porta 2 e RS4 o `sdd retry`;
  - o fechamento que veste o chapéu do ticket é o KG8 (`:5421-5441`, `sdd close` com Jira ligado
    num `kitguard_world`);
  - **o stub do claude herda o ambiente do `run_phase`**, então o `git commit` que ele faz sai
    rotulado. Um commit **alheio** dentro do stub se simula com
    `env -u GIT_REFLOG_ACTION git commit …`.
- Mutantes da família: `mut_RUN_hat_guard_blind` (`:1452`), `mut_RUN_hat_door1_missing` …
  `mut_RUN_hat_close_door_missing` (`:1458-1469`), `mut_RUN_hat_close_unchecked` (`:1485`) e
  `mut_RUN_harness_env_inherited` (`:1794`).
- **A prosa que nomeia a família, e muda com o `kind` novo:**
  - `docs/pipeline.md:120` (lista das escaladas rc 3), `:665`, `:693` e a coluna `kind` em `:1075`,
    que diz: "Adding one is a contract change: code and this table in the same commit";
  - `config/schema.md:207` (lista do `ON_ESCALATION_CMD`);
  - `CONTEXT.md:17` (verbete "Fronteira do chapéu");
  - `CLAUDE.md:122` ("UMA definição, DOIS marcadores");
  - `.claude/rules/anatomia-do-agente.md:170-173` (§6).
- Os leitores do ledger agrupam por `kind` dinamicamente (`group_by(.kind)`, `bin/sdd:8829`), sem
  lista fechada: o valor novo é contado sem mudança neles.

### Lacuna 2 — `branch:` sem Jira (`bin/sdd`)

- **`gate_PLAN()`** (`:809-852`), na ordem:
  - arquivos;
  - `aprovacao:` (`auto` ou `humano-*`, senão o motivo com `run 'sdd approve $MISSION'`);
  - `plan_approves_itself`;
  - **`if [ "$JIRA_ENABLED" = "true" ]` → `versao:`** (`:838-844`);
  - `adr_gate_verdict plan` (`:847`);
  - `checkpoint_rows`.

  A regra nova é o **espelho do bloco do `versao:`**, logo depois dele.
- `ensure_mission_branch()` (`:4455`) trata vazio e `'<'*` como no-op (`[ -n "$want" ] || return 0`;
  `case "$want" in '<'*) return 0`) e não faz nada quando `branch:` é a branch corrente.
- `cmd_approve` chama `gate_PLAN` e só morre em motivo `missing *`, então um plano sem `branch:`
  **é aprovado** e para depois, no `gate_PLAN` do `sdd run`, com o motivo novo.
- As 18 missões em `docs/handoffs/` têm `branch:` real. `lighthouse_project` e `sales_quote` rodam
  com `JIRA_ENABLED=true`. **Nenhuma missão em disco regride.**
- **O raio, prototipado nesta sessão.** A regra foi aplicada numa cópia do kit, e cada sensor rodado
  sozinho:

  | Sensor | Asserções que caem |
  |---|---|
  | `check-autonomy` | 163 |
  | `check-gates` | 84 |
  | `check-dry-run` | 31 |
  | `check-adr` | 10 |
  | `check-kaizen` | 7 |
  | `check-coordination` | 1 (`escaped hook child was exercised`: sem escalada, o hook nunca roda) |
  | `check-hat`, `check-health`, `check-preflight` | 0 |

  O motivo é um só: fixtures escrevem missão aprovada sem `branch:`. **Conserte os fixtures, nunca
  as asserções.**
- **Os fixtures que escrevem `00-missao.md`**, a conferir um a um:
  - `check-gates.sh`: `:128` (o fixture principal), `:2164` (já tem), `:2348`, `:2420`, `:2473`,
    `:2534` (já tem), `:2830`, `:2876` (já tem), `:2910` (já tem), `:3137`, `:3215`, `:3270`,
    `:3292`, `:3394`, `:3421`, `:3485`;
  - `check-autonomy.sh`: `:273`, `:4036`, `:4540`, `:5233`, `:5701`, `:6052`;
  - `check-kaizen.sh`: `:980`, `:1053`, `:1166`;
  - `check-dry-run.sh`: `:115`;
  - `check-adr.sh`: `:263` (o helper `mission`), `:727`, `:801`;
  - `check-coordination.sh`: `:670` (o `write_text` do fixture do hook).

  Os que escrevem `aprovacao:` vazio para testar o próprio PLAN podem continuar sem `branch:`.
- **O valor do fixture é a branch em que ele está** quando o runner roda (quase todos fazem
  `git init -q -b main`, então `branch: main`). É o único valor em que o `ensure_mission_branch` não
  faz nada: qualquer outro nome faria `sdd run` trocar de branch e mudaria o que os probes medem.
- **O contrato** (a resposta 3, mais o chapéu do kaizen):
  - `agents/sdd-planner.md` §8 (`:171-190`), que hoje diz que o placeholder é a resposta certa
    "whenever the branch name is not yours to decide";
  - `agents/sdd-kaizen.md` (`:225-228` descreve o `00-missao.md` que ele escreve);
  - `templates/missao.md` (a linha `branch:` do frontmatter; o `check-templates.sh:323` exige a
    chave);
  - `config/schema.md:224-227` (seção JIRA, que já diz o equivalente do `versao:`);
  - `docs/pipeline.md:428-440` (tabela "The mission's branch").

### Lacuna 3 — o stdin do `TEST_CMD` (`bin/sdd`)

- `run_check_cmd()` (`:707-734`): `( cd "$REPO_ROOT" && eval "$cmd" ) >"$logfile" 2>&1 || rc=$?`
  (`:728`). O stdin é herdado e não há timeout. A função é memoizada por `$cmd`.
- **O preflight roda o `TEST_CMD` pela mesma função** (`run_check_cmd "$TEST_CMD" "preflight-test"`,
  `:4706`), e o `E2E_CMD` dos gates também. Um redirecionamento no `run_check_cmd` cobre os três.
- O vitest 3.2.4, em `erp_api/node_modules/vitest/dist/chunks/defaults.B7q_naMc.js:80`:
  `watch: !isCI && process.stdin.isTTY`. O `"test"` do `erp_api` é `"vitest"`. Não há hoje um alvo
  do kit com esse `TEST_CMD`.
- `tests/check-preflight.sh`:
  - o bloco `== the preflight RUNS the TEST_CMD ==` (`:509`), com `PROBE` fora do fixture (`:510`);
  - os scripts `suite-green.sh` e `suite-red.sh`, que escrevem uma linha na `$PROBE/witness`
    (`:512-514`);
  - `run_case <script> <marcador esperado> <marcador proibido> <desc>` (`:518-527`) roda
    `"$SDD" preflight`, e as linhas `TEST_CMD ran green` e `TEST_CMD FAILED` são as duas
    respostas.
- `config/schema.md:28` diz que os comandos rodam na raiz do alvo e que o runner só lê o rc. É ali
  que o stdin fechado vai por escrito.

### Faxina (F2 e F4)

- ADR 0010 (`docs/adr/0010-o-motivo-da-fase.md:3`) e ADR 0011 (`…/0011-ancora-do-todo-carrega-simbolo.md:3`)
  dizem `- **Status**: proposed (—, <data>)`. O runner não lê a linha de status: ninguém faz parse
  dela. Precedente de `accepted` dentro da própria missão: a ADR 0009, em `27a7717`.
- `TODO.md:244-250`, o item "**A economia de `current_phase()`/`next_pending_phase()` depende da
  memoização e ninguém conta**":
  - é pago pelo probe `deriving the phase runs TEST_CMD exactly as often as forcing it`
    (`tests/check-autonomy.sh:6100-6118`), que cita esse item no comentário;
  - `git merge-base --is-ancestor 3245bfd main` → verdadeiro;
  - pela regra do template (`templates/todo.pt-BR.md`, "Ciclo de vida"), com o conserto já na
    `main` o item **é apagado**, nunca marcado.
- A catraca: `tests/health-baseline.txt` diz `todo-findings 82`, e `bash tests/check-todo.sh --count
  TODO.md` responde `82`. Depois do I7: −1 (o `:244`) +2 (lacunas 4 e 5) = **83**.
- **Formato do item aberto** (`templates/todo.pt-BR.md`):
  - cerca de 6 linhas, teto 8, nenhuma linha física com mais de 120 caracteres, caixa vazia;
  - ``- [ ] **<título>** — `<arquivo:linha>` (`<símbolo>`) — <por que importa>. Direção: <…>.``;
  - a última linha é ``— descoberto por `<agente>` na missão `<slug>` (YYYY-MM-DD)``;
  - a crase de 4 ou mais caracteres da cabeça tem de ocorrer no arquivo ancorado a até 10 linhas da
    linha.
- **Lacuna 4:**
  - `cmd_install` (`bin/sdd:4185`) copia os chapéus com `cp "$a" "$target"; ok "agent $name updated
    (--force)"` (`:4327`);
  - o `sdd-link-agents` (`bin/sdd-link-agents`) troca as cópias por symlinks para o kit;
  - medido num scratch: um `cp` sobre um symlink escreve no **destino** do link.

  Então um `sdd install --force` rodado de **outro** kit, como uma worktree do kit ou uma versão
  instalada, reescreve os chapéus do kit ligado. Quando o kit é o mesmo, o `cmp -s` responde
  idêntico e nada é copiado.
- **Lacuna 5:** `agents/sdd-docs.md:78` traz `packages/x/serializer.ts`, do `sales_quote`. O
  `sdd-docs.md:25-26` e o `sdd-reviewer.md:31` mandam ler `KAIZEN_LOG.md`, `CHANGELOG.md` e
  `CONTEXT.md`, que nenhum gate exige.
- **O KAIZEN_LOG** fica em `KAIZEN_LOG.md`, em pt-BR, e a entrada mais recente é a do P2(b), no alto
  do arquivo. Cada entrada traz medição, antes/depois e contramedida.

## Arquitetura da mudança

Nada novo de infraestrutura: tudo é `bin/sdd`, sensores e markdown.

- **I1 — leitura do valor como o autor escreveu.**
  - `ADR_LINK_POST` passa a aceitar o `**` depois dos dois-pontos: `(\*\*)?:(\*\*)?[[:space:]]*`.
  - `adr_link` tira a crase das duas pontas do valor, junto do `(`, `)` e `.`.
  - `adr_check_link` diz "not a path" quando o valor não tem `/` ou quando a linha existe e o valor
    sai vazio (`ADR_LINK_NO` > 0). Isso vem **antes** da comparação com `$rel`.
  - No awk do `gate_REVIEW`, ``gsub(/[*`]/, "", grade)``. No awk do `gate_DOCS`, a célula do Status
    perde `*` e crase antes de comparar.
- **I2 — um ramo novo no `cmd_approve`:** `read` falhou **e** `ans` vazio → `bad` com o motivo (e
  "stdin is not a terminal" quando `! [ -t 0 ]`), `dim` com o remédio, `return 66`. Nada é escrito e
  nada é commitado.
- **I3 — o rótulo:**
  - `session_git_label <passo> <sid>` imprime `sdd:<passo>:<sid:0:8>`, e é a **única** definição
    da grafia;
  - o `run_phase` monta `cmd=(env "${HARNESS_ENV_UNSET[@]}" "GIT_REFLOG_ACTION=$label" claude -p …`
    e publica `LAST_PHASE_GIT_LABEL`, zerado na entrada e novo global ao lado dos outros
    `LAST_PHASE_*`;
  - o `cmd_close` monta o mesmo par, com o seu `sid`, e publica o mesmo global.
- **I4 — a leitura:**
  - o `hat_guard_arm` grava `HAT_REFLOG_TOP` (a linha mais nova de `hat_reflog_lines`) e
    `HAT_REFLOG_COUNT`;
  - o `hat_guard_check` pega as `count_depois − count_antes` entradas mais novas e exige que a linha
    logo abaixo delas seja `HAT_REFLOG_TOP`;
  - se o HEAD andou sem entrada nova, se não havia topo, se o rótulo está vazio ou se a verificação
    falha, **fallback** para o diff do intervalo de hoje;
  - por entrada, o sha antigo é o da entrada de baixo e os caminhos saem de `git diff --name-only`;
    com o rótulo exato (`LAST_PHASE_GIT_LABEL` seguido de `:` ou no fim do assunto) a entrada é da
    sessão, sem ele é alheia;
  - os caminhos da sessão e o status seguem o caminho de hoje (`HAT_CROSSED_WHY`). Os caminhos
    alheios fora do `writes:` armam `FOREIGN_COMMIT_WHY` só se `HAT_CROSSED_WHY` ficou vazio,
    nomeando `sha curto + assunto` de cada commit alheio, com `warn` e a linha `FOREIGN-COMMIT` no
    journal;
  - o `hat_crossed_escalation` ganha o terceiro ramo (`kind="foreign-commit"`) com o remédio
    próprio, e as quatro portas não mudam.
- **I5 — a regra nova no `gate_PLAN`, logo depois do `versao:`:**

  ```bash
  if [ "$JIRA_ENABLED" != "true" ]; then
    local b; b="$(frontmatter "$m" branch)"
    if [ -z "$b" ] || [[ $b == \<* ]]; then GATE_WHY="…branch:…"; return 1; fi
  fi
  ```

  Mais os fixtures e o contrato em cinco arquivos.
- **I6:** `( cd "$REPO_ROOT" && eval "$cmd" ) </dev/null >"$logfile" 2>&1`.
- **I7:** markdown e a catraca.

## Incrementos

A tabela executável vive em `checkpoint.md` (é ela que o runner lê). Aqui fica o **porquê** de
cada fatia — o detalhe que não cabe numa célula.

### I1 — #50 e o yokoten da crase: o valor é lido como o autor o escreveu

**O quê:**
- (a) `**Spec:** <caminho>` passa pela mesma regra que `**Spec**: <caminho>`;
- (b) `` `<caminho>` `` entre crases é lido como o caminho;
- (c) um valor que não é caminho (sem `/`, ou vazio com a linha presente) reprova com a mensagem
  própria, sem dizer "points somewhere else";
- (d) a nota `` `A` `` passa o `gate_REVIEW`, e `` `B` `` continua reprovando como `Security = B`;
- (e) no `gate_DOCS`, `` `✅` `` e `**n/a**` contam como completos, e `` `✗` `` continua pendente.

**Onde:**
- `bin/sdd`: `ADR_LINK_POST`, `adr_link`, `adr_check_link`, o awk do `gate_REVIEW` e o do
  `gate_DOCS`;
- `tests/check-adr.sh`, `tests/check-gates.sh` e `tests/check-mutation.sh`;
- a gaveta (F5: #50).

**Como (TDD):**
1. **`check-adr.sh`, no fixture `M`, logo depois do probe do outro dialeto (`:476`).** Três
   asserções, com ADRs de ids livres no `M` (0014, 0015, 0016):
   - `the bold-colon Spec dialect is read by the same rule`: missão `20260101-boldcolon` com
     `adr: docs/adr/0014-boldcolon.md`, e o ADR com `- **Spec:** docs/handoffs/20260101-boldcolon/00-missao.md`
     → rc 0 e `^  ok    …: adr: docs/adr/0014-boldcolon\.md — and that ADR points back`;
   - `a backticked Spec path is read as the path it carries`: `` - **Spec**: `docs/handoffs/20260101-tick/00-missao.md` ``
     → rc 0 e o mesmo `ok`;
   - `a Spec line whose value is not a path says so, not that it points elsewhere`:
     `- **Spec**: see-below` → rc 1, a regex `not a path` **e** a ausência de `points somewhere else`.
     Use um `assert_adr` para a primeira metade e um `grep` negativo sobre o `ADR_OUT`, para que
     dois ramos que dividem o rc 1 não se confundam.

   Suba o `PROBE_FLOOR` em 3, acrescente R33–R35 ao cabeçalho e as linhas da sabotagem.
2. **`check-gates.sh`, no bloco REVIEW, depois do par `REVIEW_PROSE_CRITERIA` (`~:1131`).**
   - `a backticked grade is read as the grade it carries`: ``review_with '`A`' B`` com commit →
     `assert_phase … "DOCS"`;
   - `a backticked grade below A still fails`: ``review_with '`B`' B`` → REVIEW, e o motivo cita
     `Security = B`. Esta é a asserção diferencial: um normalizador que aceitasse tudo passaria na
     primeira.
3. **`check-gates.sh`, no bloco DOCS, depois do par do separador alinhado (`~:1708`).**
   - `a backticked or bold Status in the drift checklist is read as its value`: tabela com
     `` `✅` `` e `**n/a**` → `PR`;
   - `a backticked pending Status is still pending`: `` `✗` `` → DOCS, com `has 1 area`.

   Volte a tabela ao estado do bloco seguinte, para não mudar o que ele mede.
4. **Red antes do código:** (1) sai com o valor `**`, com crases e com "points somewhere else"; (2)
   sai `` Security = `A` ``; (3) sai ``Status '`✅`'``.
5. **O código**, como em "Arquitetura" (I1). Na mensagem nova, use
   `adr_fail "$v" "$ADR_LINK_NO" "the 'Spec:' line carries '<valor ou <empty>>', which is not a path" "write it as 'Spec: $rel' — the value is the first word after the colon"`.
6. **Cinco mutantes, cada um provado pela receita M:**
   - `mut_ADR_link_bold_colon_blind` (o `ADR_LINK_POST` de volta ao de hoje) → `check-adr`;
   - `mut_ADR_link_backtick_kept` (a linha que tira a crase vira `:`) → `check-adr`;
   - `mut_ADR_link_not_path_generic` (o ramo "not a path" vira `if false`) → `check-adr`;
   - `mut_REVIEW_backtick_grade_kept` (o `gsub` da nota de volta a `/\*/`) → `check-gates`;
   - `mut_DOCS_backtick_status_kept` (a normalização do Status removida) → `check-gates`.

   `ANCHOR_FLOOR` +5.

**Check:** `o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    the bold-colon Spec dialect is read by the same rule' <<< "$o"; g=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    a backticked grade is read as the grade it carries' <<< "$g"` → `1` e `1`

**Sensor durável:** as sete asserções novas e os cinco mutantes no catálogo.

**Reversível por:** `git revert` dos commits do I1. O dialeto de hoje continua aceito dos dois
lados, então nada que já passava deixa de passar.

### I2 — #52: `sdd approve` sem resposta nenhuma sai 66

**O quê:** quando não chega nenhum caractere, a saída é esta, com **rc 66**, sem escrever nem
commitar:
- `fail  no answer reached the prompt — stdin closed before a single character was read` (mais
  ` (stdin is not a terminal)` quando `! [ -t 0 ]`);
- `  nothing was written. Run 'sdd approve <missão>' from an interactive shell.`

`n`, Enter, linha parcial e `y` ficam como estão.

**Onde:**
- `bin/sdd` (`cmd_approve`);
- `tests/check-gates.sh` (seção `sdd approve`) e `tests/check-mutation.sh`;
- `README.md:105`, `docs/pipeline.md:162`;
- a gaveta (F5: #52).

**Como (TDD):**
1. A asserção `sdd approve with no answer at all exits 66 and writes nothing`, na seção
   `== sdd approve ==`, **depois** do par `n`/Enter (`:2215-2233`) e **antes** do `y` (`:2265`),
   porque o `y` aprova a `AM`:
   - roda `"$SDD" approve "$AM" </dev/null` em `$FIX`;
   - exige rc 66, `no answer reached the prompt` na saída e a **ausência** de `not approved`;
   - exige `aprovacao:` ainda vazio, o HEAD igual e a fase ainda PLAN.
2. **A diferencial**, na mesma asserção ou logo ao lado: `<<< ""` continua rc 0 com `not approved`.
   É isso que prova que o 66 é do caso "nenhuma linha" e não de "resposta vazia".
3. **Red:** hoje sai rc 0 com `not approved`.
4. **O código**, como em "Arquitetura" (I2). Escreva
   `local ans="" got=0; read -r ans || got=$?`, depois
   `if [ "$got" -ne 0 ] && [ -z "$ans" ]; then …; return 66; fi` e
   `[ "$got" -eq 0 ] || ans=""`: é esta linha que mantém a linha parcial descartada, como hoje.
5. **O mutante `mut_RUN_approve_eof_silent`** troca o `return 66` do ramo novo por
   `info "  not approved — nothing was written"; return 0` (ou o `if` por `if false`), e é provado
   com o `check-gates`. `ANCHOR_FLOOR` +1.
6. Em `README.md` e `docs/pipeline.md`, uma frase: sem resposta nenhuma (stdin fechado, pipe vazio,
   harness sem terminal) o comando sai 66 e não escreve nada; `N` é uma resposta e sai 0.

**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    sdd approve with no answer at all exits 66 and writes nothing' <<< "$o"` → `1`

**Sensor durável:** a asserção, com a diferencial, e o mutante.

**Reversível por:** `git revert`. Quem dependia do rc 0 no caso sem stdin volta a recebê-lo.

### I3 — #51, parte 1: toda sessão roda com o rótulo, e a de fechamento também

**O quê:**
- `session_git_label` é a definição única da grafia `sdd:<passo>:<sid8>`;
- o `run_phase` e o `cmd_close` exportam `GIT_REFLOG_ACTION=<rótulo>` para o `claude`;
- o `LAST_PHASE_GIT_LABEL` é publicado;
- a projeção mostra o rótulo;
- a ADR 0012 ganha a seção de implementação confirmada.

Ninguém lê o rótulo ainda: o comportamento da guarda não muda neste incremento.

**Onde:**
- `bin/sdd`: `run_phase`, `cmd_close` e os globais `LAST_PHASE_*`;
- `tests/check-autonomy.sh`, `tests/check-dry-run.sh` e `tests/check-mutation.sh`;
- `docs/adr/0012-o-commit-tem-dono.md`.

**Como (TDD):**
1. **`check-autonomy.sh`, no bloco da fronteira (ou num regime RS novo), a asserção
   `every session runs under its own git label, the close session too`:**
   - um stub que grava `printf '%s\n' "$GIT_REFLOG_ACTION"` num arquivo;
   - numa porta 1 (`sdd run --phase REVIEW --max-phases 1` num `reviewscope_world`) o valor tem de
     casar `^sdd:REVIEW:[0-9a-f]{8}$`, e os 8 hex têm de ser os mesmos do nome do log da sessão
     (`.sdd/logs/<missão>/REVIEW-*-<8hex>.json`). Essa é a prova cruzada de que o rótulo nomeia a
     invocação;
   - num `sdd close` (o mundo do KG8) o valor casa `^sdd:CLOSE:[0-9a-f]{8}$`;
   - uma asserção só, com as três partes no valor comparado.
2. **`check-dry-run.sh:238-239`:**
   - a asserção antiga passa a contar
     `-u CLAUDE_EFFORT GIT_REFLOG_ACTION=sdd:[A-Za-z:]*:[0-9a-f]\{8\} claude -p` (o `env -u …`
     completo continua na frente);
   - uma asserção nova, `every projected phase labels its git moves with the session`, conta um
     rótulo por bloco (`$blocks`).
3. **Red:** as duas asserções falham hoje, porque não existe `GIT_REFLOG_ACTION`.
4. **O código**, como em "Arquitetura" (I3). Zere `LAST_PHASE_GIT_LABEL` junto de
   `SESSION_DIED_WHY` na entrada do `run_phase`. **Atualize a âncora de
   `mut_RUN_harness_env_inherited`** para a linha nova do `cmd`.
5. **Dois mutantes:**
   - `mut_RUN_git_label_unexported` (o `run_phase` sem o par `GIT_REFLOG_ACTION=`) → `check-dry-run`
     e `check-autonomy`;
   - `mut_RUN_close_git_label_unexported` (o `cmd_close` sem ele) → `check-autonomy`.

   `ANCHOR_FLOOR` +2.
6. **ADR 0012, seção "Implementation":** confirme ou corrija a parte do rótulo com o que o código
   ficou (nome da função, onde o global é zerado).

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    every session runs under its own git label, the close session too' <<< "$o"; d=$(bash tests/check-dry-run.sh 2>&1); grep -c '^  ok    every projected phase labels its git moves with the session' <<< "$d"` → `1` e `1`

**Sensor durável:** as asserções e os dois mutantes.

**Reversível por:** `git revert`. Um `GIT_REFLOG_ACTION` a mais no ambiente da sessão não muda o
que o git grava além do texto do reflog.

### I4 — #51, parte 2: o commit alheio para a linha como `foreign-commit`

**O quê:**
- o `hat_guard_check` lê a janela pelo reflog e separa as entradas da sessão (rótulo exato) das
  alheias;
- os caminhos alheios fora do `writes:` armam `FOREIGN_COMMIT_WHY`, e a linha para com
  `kind: foreign-commit`, o commit nomeado e o remédio certo;
- sem reflog que explique o movimento, o comportamento é o de hoje;
- o contrato do `kind` novo muda no mesmo commit.

**Onde:**
- `bin/sdd`: `hat_guard_arm`, `hat_guard_check`, `hat_crossed_escalation`, os globais e o cabeçalho
  "DECLARED LIMITS" da família;
- `tests/check-autonomy.sh` e `tests/check-mutation.sh`;
- `docs/pipeline.md` (`:120`, `:665`, `:693`, `:1075`), `config/schema.md:207`, `CONTEXT.md:17`,
  `CLAUDE.md:122` e `.claude/rules/anatomia-do-agente.md` §6;
- a ADR 0012 (a seção "Implementation");
- a gaveta (F5: #51).

**Como (TDD):**
1. **Em `check-autonomy.sh`, num `reviewscope_world`**, um stub de REVIEW que commita o
   `40-review-r1.md` com o rótulo e depois commita `bin/tool.sh` de dois jeitos:
   - com `env -u GIT_REFLOG_ACTION git commit -qm "chore: a concurrent writer"` (alheio);
   - com `git commit -qm …` (da sessão, rotulado).

   A diferencial, `a commit without the session label stops the line as foreign-commit, the same commit with it as hat-crossed`,
   compara os dois mundos. Esperado:
   `rc=3 kind=foreign-commit journal=FOREIGN-COMMIT hat=0 · rc=3 kind=hat-crossed`. O primeiro mundo
   exige `FOREIGN-COMMIT` no journal com o sha curto e o assunto `a concurrent writer`, e **zero**
   linhas `HAT-CROSSED`.
2. `a foreign commit inside the hat writes is not a stop`: o commit alheio só dentro do diretório da
   missão → nenhuma linha `foreign-commit` nem `FOREIGN-COMMIT`.
3. `without a reflog the guard blames the session as before`: `git config core.logAllRefUpdates
   false` e `rm -rf .git/logs` no mundo, e o commit alheio de `bin/tool.sh` → `rc=3
   kind=hat-crossed`.
4. **Porta do `cmd_close`:** o KG8 existente (a sessão de fechamento commita código **rotulado**)
   continua `3 hat-crossed`, e é essa asserção que pega o rótulo esquecido no `cmd_close`.
5. **Red:** (1) sai `hat-crossed` nos dois mundos; (2) e (3) já passam hoje, e são guardas contra o
   código novo.
6. **O código**, como em "Arquitetura" (I4):
   - `FOREIGN_COMMIT_WHY=""` ao lado dos outros dois globais (`:3101-3103`), zerado na entrada do
     `hat_guard_check`, o seu único setter;
   - `hat_reflog_lines` capturada com `|| true`, e lida com herestring, nunca `| head`;
   - na mensagem, `the $step session ($hat) did not make $n commit(s) that changed path(s) outside its writes: <sha assunto>; …` (o texto final é seu);
   - o remédio do ramo novo no `hat_crossed_escalation`: `nothing may commit into this checkout while a phase runs — let the phase end, then 'sdd run' again; widening writes: or HAT_WRITES_EXTRA would not fix this`;
   - **atualize as âncoras** de `mut_RUN_review_scope_quotepath_default`, `mut_RUN_hat_guard_blind`
     e `mut_RUN_hat_guard_ignores_prior_dirt` se as linhas delas mudarem.
7. **Três mutantes:**
   - `mut_RUN_foreign_blamed_on_hat` (toda entrada tratada como da sessão) → a diferencial;
   - `mut_RUN_foreign_not_stopped` (o ramo `FOREIGN_COMMIT_WHY` do `hat_crossed_escalation` removido)
     → a diferencial;
   - `mut_RUN_reflog_fallback_blind` (sem topo gravado, lê "zero entradas novas" em vez de cair no
     diff) → o probe (3).

   `ANCHOR_FLOOR` +3.
8. **O contrato, no mesmo commit:**
   - `foreign-commit` na lista das rc 3 (`docs/pipeline.md:120`) e na coluna `kind` (`:1075`), com o
     que ele significa e o limite de evasão;
   - no `ON_ESCALATION_CMD` (`config/schema.md:207`);
   - no verbete "Fronteira do chapéu" (`CONTEXT.md:17`), com os termos rótulo da sessão, commit
     alheio e janela da sessão;
   - "TRÊS marcadores" no `CLAUDE.md:122`;
   - a atribuição por rótulo na §6 da rule da anatomia;
   - a seção "Implementation" da ADR 0012.

**Check:** `o=$(bash tests/check-autonomy.sh 2>&1); grep -c '^  ok    a commit without the session label stops the line as foreign-commit, the same commit with it as hat-crossed' <<< "$o"; grep -c '^  ok    without a reflog the guard blames the session as before' <<< "$o"` → `1` e `1`

**Sensor durável:** as três asserções novas, o KG8 como guarda da porta do `cmd_close` e os três
mutantes.

**Reversível por:** `git revert` do I4, e só dele: sem a leitura, o rótulo do I3 fica inofensivo.

### I5 — lacuna 2: sem Jira, o `gate_PLAN` exige `branch:`

**O quê:**
- com `JIRA_ENABLED` diferente de `true`, `branch:` vazio ou `<…>` deixa a missão em PLAN com o
  motivo
  `JIRA_ENABLED is not true and 00-missao.md has no mission branch ('branch: <valor ou <empty>>') — nothing will create one, so every phase would commit wherever you stand: write the branch name into 00-missao.md (the planner decides it with the human)`;
- com Jira ligado, nada muda;
- os fixtures da suíte passam a declarar a branch;
- o contrato muda em cinco arquivos.

**Onde:**
- `bin/sdd` (`gate_PLAN`);
- os fixtures listados em "Contexto verificado";
- `tests/check-gates.sh` (os probes) e `tests/check-mutation.sh`;
- `agents/sdd-planner.md` §8, `agents/sdd-kaizen.md`, `.claude/agents/` (via `install --force`),
  `templates/missao.md`, `config/schema.md` (seção JIRA) e `docs/pipeline.md` ("The mission's
  branch");
- a gaveta (F4: lacuna 2).

**Como (TDD):**
1. **Em `check-gates.sh`, no bloco PLAN (`:125-166`)**, depois do par `aprovacao`.
   - `JIRA off with no branch stalls PLAN and names the fix`: missão aprovada, sem `branch:` →
     `assert_phase … "PLAN"` e `assert_why … "PLAN" "branch:"`.
   - `the branch placeholder is refused like an empty branch`: com
     `branch: <nome da branch de trabalho>` → PLAN.
   - `JIRA on leaves an empty branch to the TICKET phase`: `JIRA_ENABLED=true`, `versao:`
     preenchida e sem `branch:` → `TICKET` (é o mesmo fixture, com a linha do config trocada e
     desfeita depois).
   - `an explicit branch opens the PLAN gate`: com `branch: main` → EXEC.

   O fixture principal (`:128`) nasce **com** `branch: main`. Os probes tiram e põem a linha com
   `sed`, como o bloco já faz com `aprovacao:`.
2. **Red:** as três primeiras falham hoje (EXEC onde se espera PLAN).
3. **A regra**, como em "Arquitetura" (I5).
4. **Os fixtures.** Rode os seis sensores da tabela do raio. Cada queda se conserta no **fixture**
   com `branch: <a branch em que ele está>`, nunca na asserção. A meta é a tabela zerada. O
   `check-coordination.sh:670` é um `write_text` em Python: acrescente `branch: main\n`.
5. **O mutante `mut_PLAN_branch_unasked`** (o bloco novo vira `if false`) → `check-gates`.
   `ANCHOR_FLOOR` +1.
6. **O contrato:**
   - no §8 do `sdd-planner.md`, com Jira desligado, o placeholder deixa de ser a resposta certa:
     um nome real, decidido com o humano, é **obrigatório** e o gate recusa o resto;
   - no `sdd-kaizen.md`, uma linha: o plano do kit leva `branch:` real, porque o kit roda com o Jira
     desligado;
   - `./bin/sdd install --force` sincroniza o espelho;
   - no `templates/missao.md`, o texto do placeholder de `branch:` diz que ele é obrigatório com
     `JIRA_ENABLED=false`;
   - no `config/schema.md`, uma frase ao lado da do `versao:`;
   - no `docs/pipeline.md`, uma linha na tabela `branch:`.

**Check:** `o=$(bash tests/check-gates.sh 2>&1); grep -c '^  ok    JIRA off with no branch stalls PLAN and names the fix' <<< "$o"; grep -c '^  ok    JIRA on leaves an empty branch to the TICKET phase' <<< "$o"` → `1` e `1`

**Sensor durável:** as quatro asserções e o mutante. A suíte inteira passa a ser sensor, porque um
fixture novo sem `branch:` cai nela.

**Reversível por:** `git revert` do I5. Os fixtures com `branch: main` continuam válidos sem a
regra.

⚠️ É o incremento mais pesado da missão, porque são uns vinte fixtures em seis sensores. Se a
sessão apertar, commite a regra, os probes e os fixtures num commit e o contrato em outro, **sem**
deixar a suíte vermelha entre eles.

### I6 — lacuna 3: o `TEST_CMD` roda com o stdin fechado

**O quê:**
- `run_check_cmd` redireciona `</dev/null`, o que cobre os gates, o preflight e o `E2E_CMD`;
- o `config/schema.md` diz isso por escrito.

**Onde:**
- `bin/sdd` (`run_check_cmd`);
- `tests/check-preflight.sh` e `tests/check-mutation.sh`;
- `config/schema.md:28`;
- a gaveta (F4: lacuna 3).

**Como (TDD):**
1. **Em `check-preflight.sh`, no bloco `== the preflight RUNS the TEST_CMD ==` (`:509`)**, a
   asserção `TEST_CMD runs with stdin closed, whatever stdin the caller holds`:
   - um script `$PROBE/suite-stdin.sh` que grava `ran` na witness, depois, se
     `IFS= read -r line`, grava `stdin:<linha>` e sai 4, e senão sai 0;
   - roda `"$SDD" preflight < "$PROBE/a-line"`, com um arquivo de uma linha;
   - exige `TEST_CMD ran green`, a ausência de `TEST_CMD FAILED`, `ran=1` e **nenhuma** linha
     `stdin:` na witness.
2. **Red:** hoje o script lê a linha do arquivo e sai 4. Se o Red **não** aparecer, algo acima do
   `run_check_cmd` comeu o stdin, e a conclusão do probe é inválida: troque o caminho, por exemplo
   `"$SDD" why` num mundo de gate de EXEC que roda o `TEST_CMD`, até o Red aparecer.
3. **O código:** uma linha em `bin/sdd:728`.
4. **O mutante `mut_RUN_check_cmd_stdin_inherited`** remove o `</dev/null` → `check-preflight`.
   `ANCHOR_FLOOR` +1.
5. **O `config/schema.md:28`:** o stdin é `/dev/null`, com o porquê (um runner em watch, como um
   `vitest` puro, penduraria o gate num terminal).

**Check:** `o=$(bash tests/check-preflight.sh 2>&1); grep -c '^  ok    TEST_CMD runs with stdin closed, whatever stdin the caller holds' <<< "$o"` → `1`

**Sensor durável:** a asserção e o mutante.

**Reversível por:** `git revert` do I6.

### I7 — faxina: ADRs aceitas, o item pago sai, as lacunas 4 e 5 entram, a catraca anda

**O quê:**
- as ADRs 0010, 0011 e 0012 passam a `- **Status**: accepted (—, <data do commit>)`;
- o item `TODO.md:244-250` é apagado;
- dois itens novos entram (lacunas 4 e 5);
- `tests/health-baseline.txt` vai para `todo-findings 83`;
- entra a entrada do `KAIZEN_LOG.md`;
- a gaveta recebe a passada final.

**Onde:** `docs/adr/0010-…`, `docs/adr/0011-…`, `docs/adr/0012-…`, `TODO.md`,
`tests/health-baseline.txt`, `KAIZEN_LOG.md` e `docs/superpowers/specs/2026-09-23-a-gaveta-do-kit.md`.

**Como:**
1. **Âncoras, antes de redigir.** Os números do `bin/sdd` andaram nos I1–I6: releia com
   `grep -n 'agent $name updated (--force)' bin/sdd` e `grep -n 'packages/x/serializer.ts'
   agents/sdd-docs.md`.
2. **A lacuna 4**, rascunho de cabeça, com o número re-medido:
   ``- [ ] **Com os chapéus ligados por symlink, o `sdd install --force` de outro kit escreve no kit ligado** — `bin/sdd:<N>` (`updated (--force)`) — …``.
   O corpo diz o mecanismo (`cp` sobre symlink escreve no destino, medido), que o install não é
   sessão e não passa pela guarda de kit, e a direção: `cp --remove-destination`, ou recusar quando
   o alvo é symlink. Fonte: a lacuna 4 da F4 da gaveta.
3. **A lacuna 5**, rascunho de cabeça:
   ``- [ ] **A prosa dos chapéus ainda cita o `sales_quote`** — `agents/sdd-docs.md:78` (`packages/x/serializer.ts`) — …``.
   O corpo diz que o `sdd-docs.md` e o `sdd-reviewer.md` mandam ler `KAIZEN_LOG.md`, `CHANGELOG.md` e
   `CONTEXT.md`, que nenhum gate exige: é ruído de prompt, não falha. Direção: neutralizar o
   exemplo e condicionar a leitura à existência do arquivo.
4. **Os dois itens:**
   - atribuição ``— descoberto por `sdd-planner` na missão `20260926-a-carona-antes-do-congelamento` (2026-09-26)``;
   - ≤ 8 linhas cada, nenhuma linha física acima de 120 caracteres;
   - sob um `###` que já exista e caiba (portabilidade ou chapéus).
5. **A catraca:** `bash tests/check-todo.sh --count TODO.md` tem de responder 83, e o
   `tests/health-baseline.txt` passa a `todo-findings 83`, no mesmo commit.
6. **O `KAIZEN_LOG.md`**, uma entrada no alto, no formato da mais recente, com o antes/depois de
   cada fato binário da Métrica do `00-missao.md` e os números do catálogo (406 → 419).
7. **A gaveta:**
   - F2 **fechada**;
   - F4 com as lacunas 2 e 3 consertadas, 4 e 5 no `TODO.md` e 6 declarada;
   - F5 com #50, #51 e #52 fechando com o PR;
   - F1 com o P3 esperando o próximo aumento de paralelismo;
   - F3 dizendo que o congelamento começa no merge deste PR;
   - na "Recomendação", o item 3 marcado como feito por esta missão.

**Check:** `c=$(bash tests/check-todo.sh --count TODO.md); b=$(cat tests/health-baseline.txt); grep -c "^todo-findings $c\$" <<< "$b"; grep -c '^todo-findings 83$' <<< "$b"; a=$(cat docs/adr/0010-o-motivo-da-fase.md docs/adr/0011-ancora-do-todo-carrega-simbolo.md docs/adr/0012-o-commit-tem-dono.md); grep -c '^- \*\*Status\*\*: accepted' <<< "$a"` → `1`, `1` e `3`

**Sensor durável:** a catraca do `sdd health` (`todo-findings`) e o `check-todo.sh` (forma e âncora
dos itens novos), os dois já na suíte e no health. Um status de ADR não tem sensor, e nenhum leitor
faz parse dele.

**Reversível por:** `git revert` do I7.

## Riscos e não-feitos

| Risco | Probabilidade | Mitigação |
|---|---|---|
| Cada edição no `bin/sdd` desloca as âncoras do `TODO.md` e as dos mutantes | certa | `--anchors` do `check-todo.sh` e do `check-mutation.sh` em todo incremento, com o conserto no mesmo commit (Contexto verificado). |
| O I5 vira sessão longa demais (uns 20 fixtures) | média | A lista dos fixtures e a tabela do raio estão escritas. Commit em dois, sem suíte vermelha no meio. |
| Um git que sobrescreve o `GIT_REFLOG_ACTION` (algum `rebase`/`pull` futuro) grava entrada sem rótulo da sessão | baixa | A linha para mesmo assim (`foreign-commit`); só o `kind` sai errado. Limite declarado na ADR 0012 e no cabeçalho do `hat_guard_check`. |
| Uma sessão tira o próprio rótulo para escapar | baixa | Fail-safe por desenho: o commit alheio fora do `writes:` também para a linha. |
| O stub do claude herda o `GIT_REFLOG_ACTION` de quem roda a suíte e os probes medem o rótulo de fora | baixa | O rótulo do `run_phase` sobrescreve o de fora dentro da sessão, e o `hat_guard_check` compara o rótulo **exato** da invocação, nunca o prefixo `sdd:`. |
| O `sdd approve` aprova um plano sem `branch:`, que para depois no `sdd run` | certa, por desenho | O motivo do gate nomeia o remédio. Avisar dentro do `approve` fica fora (não pedido no grill). |
| O probe do I6 fica verde por acidente, porque o stdin já é `/dev/null` no harness | alta, se ninguém olhar | O probe **alimenta** um arquivo com uma linha, e o I6 exige ver o Red antes do código. |
| O carimbo é invalidado a cada commit em `bin/`, `tests/`, `templates/` e `config/` | certa | `sdd health` **uma vez**, depois do último commit de código e de todos os revisores. |
| Um commit na `main` depois do merge encalha a janela do juiz | média | Nenhum `RESOLVED by` nasce nesta missão, e as ADRs saem `accepted` dentro do PR. O re-sync do espelho mexe só no GitHub. |

## Verificação end-to-end

Com todas as linhas `done`:

```bash
bash -n bin/sdd; echo rc=$?                                                   # rc=0
tests/run-all.sh; echo rc=$?                                                  # rc=0 (em primeiro plano)
bash tests/check-mutation.sh --anchors; echo rc=$?                            # rc=0
o=$(bash tests/check-todo.sh --anchors TODO.md 2>&1); grep -c '^  ok    anchors: [1-9][0-9]* measured, 0 off target' <<< "$o"   # 1
m=$(sed -n '/^CATALOG=(/,/^)/p' tests/check-mutation.sh); grep -c '^  [A-Z][A-Za-z_0-9]*$' <<< "$m"   # 419
o=$(bash tests/check-adr.sh 2>&1); grep -c '^  ok    a Spec line whose value is not a path says so, not that it points elsewhere' <<< "$o"   # 1
o=$(bash tests/check-gates.sh 2>&1)
grep -c '^  ok    a backticked grade below A still fails' <<< "$o"                                   # 1
grep -c '^  ok    a backticked or bold Status in the drift checklist is read as its value' <<< "$o"  # 1
grep -c '^  ok    sdd approve with no answer at all exits 66 and writes nothing' <<< "$o"           # 1
grep -c '^  ok    JIRA off with no branch stalls PLAN and names the fix' <<< "$o"                    # 1
o=$(bash tests/check-autonomy.sh 2>&1)
grep -c '^  ok    a commit without the session label stops the line as foreign-commit, the same commit with it as hat-crossed' <<< "$o"   # 1
grep -c '^  ok    a foreign commit inside the hat writes is not a stop' <<< "$o"                    # 1
env -u CLAUDECODE ./bin/sdd adr check --mission 20260926-a-carona-antes-do-congelamento; echo rc=$?   # rc=0
env -u CLAUDECODE ./bin/sdd preflight; echo rc=$?                             # rc=0
```

Depois, fora da execução e na ordem do `CLAUDE.md`:

1. a revisão pré-PR (`/codereview:codereview`) até Grade A, com os achados consertados em
   incrementos `R<n>`;
2. a passada de DOCS: `README.md`, `docs/failure-modes.md` (um verbete "the line stopped with
   foreign-commit") e os números do `CLAUDE.md`, que saem do comando e nunca de memória;
3. push e PR com `Closes #50`, `Closes #51` e `Closes #52`;
4. esperar **todos** os revisores (o Codex só vem com `@codex review`) e consertar numa leva;
5. `./bin/sdd health` **uma vez**, pelo lançador (`SIG_DFL`, sem `CLAUDE*`, sessão nova; texto no
   plano do P2(b), `docs/superpowers/plans/2026-09-25-o-sensor-para-no-primeiro-fail.md`, "Antes de
   começar", passo B). Ele carimba `419 caught of 419` e confere `todo-findings 83`;
6. merge com o ok do humano. A partir dele o kit **congela**;
7. re-sincronizar o espelho de issues com a skill `todo-to-github-issues`. Ela fecha a issue do
   `TODO.md:244` e cria as duas das lacunas 4 e 5, e só mexe no GitHub, sem commit na `main`.
