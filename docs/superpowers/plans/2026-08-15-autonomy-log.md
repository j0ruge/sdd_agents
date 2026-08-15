# I13.1 — `autonomy-log.jsonl` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** o runner passa a registrar, por sessão, os fatos que já observa num ledger global
append-only, e um comando mínimo lê esse ledger — para que o juiz do I13.3 tenha série histórica
em vez de opinião.

**Architecture:** uma função de append com todas as guardas dentro (`autonomy_append`), dois
construtores de linha em cima dela (`autonomy_session_row`, `autonomy_blocked_row`), cinco pontos
de chamada no `cmd_run` + um no `cmd_retry`, e um leitor `cmd_autonomy` que agrega por `kit_sha`.
Nenhum score em lugar nenhum: o runner grava fato, o juiz do I13.3 julga.

**Tech Stack:** bash 4+ (GNU userland), `jq` (dependência dura já checada pelo preflight),
`uuidgen`, `git`. Sem daemon, sem banco, sem dependência nova.

**Spec:** [`docs/superpowers/specs/2026-08-15-autonomy-log-design.md`](../specs/2026-08-15-autonomy-log-design.md)

## Global Constraints

- **Idioma:** todo código, comentário, mensagem e nome de teste em **inglês** (superfície do kit,
  medida por `tests/check-lang.sh`). Mensagem de commit e este plano em **pt-BR** (`OUTPUT_LANG`).
- **`set -euo pipefail`** no `bin/sdd`; `bash -n bin/sdd` é o smoke mínimo; `shellcheck -S warning`
  limpo em `bin/sdd`.
- **⚠️ `printf … | grep -q` devolve 141 sob `pipefail`** quando o grep acha e fecha o pipe. Use
  herestring (`<<<`) em toda busca.
- **Nenhum teste gasta token ou rede.** Stub de `claude` no PATH do fixture.
- **`sed -i` sem argumento, `md5sum`, `date -Iseconds`, `grep -P`** — o kit é GNU-only por decisão
  declarada (`docs/failure-modes.md`).
- **Contrato quebrado em três lugares é o modo de falha mais caro do kit:** mudou contrato,
  atualize código + `docs/` + teste no **mesmo commit**.
- **Ledger:** `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl`, JSONL, `"v":1` em toda linha,
  append-only, um `printf` por linha.
- **`SDD_STATE_DIR` é env var, nunca chave de `.sdd/config.sh`.** Documentar em **prosa**; uma
  linha `` | `CHAVE` | `` na tabela do `config/schema.md` faz a checagem 4 do `sdd health` acusar
  `doc-without-key`.
- **Desperdício = sessões que NÃO moveram o disco / sessões comparáveis.**

---

### Task 1: O escritor, as escaladas e o isolamento da suíte

Entrega: existe um ledger, as três escaladas escrevem nele, e nenhuma rodada da suíte encosta no
ledger real da máquina. É a menor fatia com ciclo de teste próprio: o caminho de escalação por
incremento `blocked` retorna 3 **antes** de qualquer `run_phase`, então é exercitável offline.

**Files:**
- Modify: `bin/sdd` — inserir após `pipeline_log_line()` (hoje termina em `:676`); alterar os três
  `pipeline_log_line "… BLOCKED …"` (`:1297`, `:1313`, `:1364`) e o topo do `cmd_run` (`:1225`)
- Modify: `tests/run-all.sh:7-9` — export de `SDD_STATE_DIR`
- Modify: `tests/check-lang.sh:114-122` — piso de superfície 25 → 26
- Modify: `config/schema.md` — prosa sobre `SDD_STATE_DIR` (NÃO linha de tabela)
- Create: `tests/check-autonomy.sh`

**Interfaces:**
- Consumes: `DRY_RUN`, `PROJECT_NAME`, `REPO_ROOT`, `MISSION`, `SDD_HOME`, `GATE_WHY`, `warn()`
- Produces (usado pelas Tasks 2-4):
  - `autonomy_log_path()` → imprime o caminho do ledger
  - `autonomy_append <linha-json>` → aplica TODAS as guardas e faz o append; rc sempre 0
  - `autonomy_blocked_row <kind> <phase> <gate_why>` → monta e escreve a linha `event:"blocked"`
  - `AUTONOMY_RUN_ID` (string), `AUTONOMY_INVOCATION` (`"run"`/`"retry"`) — globais

- [ ] **Step 1: Escrever o teste que falha**

Criar `tests/check-autonomy.sh`. Este arquivo cresce nas Tasks 2-4; comece com o bloco do
escritor.

```bash
#!/usr/bin/env bash
# Sensor for the autonomy ledger — the series the kaizen judge (I13.3) will read.
#
# The ledger records FACTS, never a score, and its value is entirely in being trustworthy: a row
# that should not exist (a projection, a fixture) poisons a metric that decides whether the kit
# graduates. So the assertions here are mostly about what must NOT be written.
#
# Hermetic: `claude` and `gh` are stubbed, SDD_STATE_DIR points inside the fixture. Runs INSIDE
# mutants (unlike check-preflight), because the mutations that sabotage the writer have to kill
# the sandbox suite — guarded, they would score a point for nothing.
#
# Usage: tests/check-autonomy.sh   (exit 0 = the ledger tells the truth)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-autonomy-XXXXXX")"
MISSION="20260101-fixture"
fails=0
trap 'rm -rf "$FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi }

# The ledger under test. Never the real one: the export in run-all.sh already redirects every
# test, and this makes THIS file independent of that export holding.
export SDD_STATE_DIR="$FIX/state"
LEDGER="$SDD_STATE_DIR/autonomy-log.jsonl"

# rows <jq-filter> — applies the filter to every row and prints one result per line.
rows() { jq -c "$1" "$LEDGER" 2>/dev/null; }
nrows() { [ -f "$LEDGER" ] && grep -c . "$LEDGER" || echo 0; }

echo "== fixture at $FIX =="
cd "$FIX" || exit 1

# No test spends tokens or network. In this task nothing should reach claude at all: the blocked
# escalation returns before any session. The stub makes that a loud failure instead of a bill.
mkdir -p "$FIX/.stub"
cat > "$FIX/.stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$FIX/.stub/claude"
PATH="$FIX/.stub:$PATH"

git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "content" > file.txt
git add -A && git commit -qm "init"

"$SDD" install >/dev/null
cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF

MDIR="$FIX/docs/handoffs/$MISSION"
mkdir -p "$MDIR"
cat > "$MDIR/00-missao.md" <<'EOF'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
EOF
: > "$MDIR/01-plano.md"
# A `blocked` increment: the Jidoka path escalates with rc 3 BEFORE opening any session, which is
# what makes the real (non-dry) writer reachable without spending a token.
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | blocked | — |
EOF
git add -A && git commit -qm "chore: fixture mission"

# --- the projection writes nothing ------------------------------------------
echo "== dry-run =="
"$SDD" run "$MISSION" --dry-run >/dev/null 2>&1
assert_eq "the projection writes no ledger at all" "0" "$(nrows)"

# --- the real escalation writes one honest row ------------------------------
echo "== blocked escalation =="
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the blocked increment escalates with rc 3" "3" "$rc"
assert_eq "exactly one row was written" "1" "$(nrows)"
assert_eq "every row is valid JSON" "1" "$(jq -e . "$LEDGER" >/dev/null 2>&1 && echo 1 || echo 0)"
assert_eq "schema version" "1" "$(rows '.v')"
assert_eq "event" "blocked" "$(rows '.event')"
assert_eq "kind distinguishes the three escalations by enum, not by prose" \
  "increment-blocked" "$(rows '.kind')"
assert_eq "project" "fixture" "$(rows '.project')"
assert_eq "mission" "$MISSION" "$(rows '.mission')"
assert_eq "phase" "EXEC" "$(rows '.phase')"
assert_eq "invocation" "run" "$(rows '.invocation')"
assert_eq "run_id is present" "true" "$(rows '(.run_id | length) > 0')"
# Session fields are ABSENT, never falsely zeroed: an escalation spent no session, and a 0 there
# would enter the judge's arithmetic as if it had.
assert_eq "no session fields on an escalation" "true" \
  "$(rows 'has("rc") == false and has("cost_usd") == false and has("moved") == false')"
# The gate reason carries quotes and an em-dash. Hand-rolled JSON would break here, and the only
# reader that would notice is the judge, months later, comparing garbage.
assert_eq "gate_why survived quoting" "true" "$(rows '(.gate_why | test("Jidoka"))')"

# --- the interactive PLAN spends no session, so it records none --------------
# PLAN returns 2 before opening anything: there is no friction to measure in a phase that is
# interactive BY DESIGN, and a row here would count human collaboration as waste.
: > "$LEDGER"
sed -i 's/^aprovacao: auto$/aprovacao:/' "$MDIR/00-missao.md"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the interactive PLAN exits 2" "2" "$rc"
assert_eq "and writes no row" "0" "$(nrows)"
sed -i 's/^aprovacao:$/aprovacao: auto/' "$MDIR/00-missao.md"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the ledger records facts and stays quiet on projections\n'; exit 0; fi
printf '%d autonomy check(s) failed\n' "$fails" >&2
exit 1
```

- [ ] **Step 2: Rodar o teste e ver falhar**

```bash
chmod +x tests/check-autonomy.sh && tests/check-autonomy.sh
```

Esperado: FALHA. `nrows` devolve `0` onde se esperava `1` a partir de "exactly one row was
written", porque `autonomy_blocked_row` ainda não existe. A asserção do dry-run passa por
vacuidade — é justamente por isso que o piso "exactly one row" vem logo depois.

- [ ] **Step 3: Isolar a suíte do ledger real — antes de qualquer escrita existir**

Em `tests/run-all.sh`, logo após `set -uo pipefail` (`:7`) e antes de `ROOT=`:

```bash
# Every test that runs bin/sdd could write to the autonomy ledger — check-dry-run already
# exercises the real escalation path. Without this, each suite run would inject fixture rows into
# the developer's ~/.sdd/autonomy-log.jsonl, and the judge would read fixtures as missions. The
# export lives here, at the top, so it holds for tests that do not exist yet.
SDD_TEST_STATE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-suite-state-XXXXXX")"
export SDD_STATE_DIR="$SDD_TEST_STATE"
trap 'rm -rf "$SDD_TEST_STATE"' EXIT
```

- [ ] **Step 4: Implementar o escritor**

Em `bin/sdd`, imediatamente após o fecho de `pipeline_log_line()` (`:676`):

```bash
# ---------------------------------------------------------------------------
# Autonomy ledger — the series the kaizen judge (I13.3) reads.
#
# It records FACTS only: attempts, whether the session moved the disk, rc, cost, the gate reason.
# No score. `ok|leve|refez` is a LABEL, and a runner that labels its own sessions is exactly the
# "label instead of artifact" every gate here exists to forbid — the judge derives the label from
# these facts, and can change its yardstick later without rewriting the past.
#
# Global on purpose (~/.sdd, not the target repo): "maturity across projects" cannot be measured
# in a per-repo file, and a file the runner writes BETWEEN phases inside the target repo would sit
# untracked and knock down gate_REVIEW and sdd preflight — the pipeline.log defect, fixed in
# 53cf63a by making that one ephemeral, a way out this ledger does not have because its whole
# point is to last.
AUTONOMY_RUN_ID=""
AUTONOMY_INVOCATION=""
AUTONOMY_WARNED=0

autonomy_log_path() { printf '%s/autonomy-log.jsonl' "${SDD_STATE_DIR:-$HOME/.sdd}"; }

# "<sha>|<true|false>", or "|" when SDD_HOME is not a git checkout. This is the judge's
# before/after axis: without it, a change in the numbers gets attributed to the calendar instead
# of to the kit change that caused it.
autonomy_kit_stamp() {
  local sha
  sha="$( git -C "$SDD_HOME" rev-parse --short HEAD 2>/dev/null || true )"
  [ -n "$sha" ] || { printf '|'; return 0; }
  if [ -n "$( git -C "$SDD_HOME" status --porcelain 2>/dev/null )" ]
  then printf '%s|true' "$sha"
  else printf '%s|false' "$sha"; fi
}

# EVERY row goes through here, so every guard holds for every caller. The guards do NOT live in
# the callers: the journal already paid that lesson — there are three escalation paths, and a
# fourth added tomorrow would be born with the defect.
autonomy_append() {   # autonomy_append <one json object, already built>
  # The projection must not write. Worse here than in the journal: a projected row does not just
  # lie in an audit trail, it enters the judge's arithmetic and shifts the metric forever.
  # NOTE: written as an `if` on purpose. `[ "$DRY_RUN" = "1" ] && return 0` is the unique anchor
  # of mut_RUN_inverted_journal in the mutation catalogue; sharing the text would make that
  # mutation sabotage two guards at once and stop measuring what it claims to.
  if [ "$DRY_RUN" = "1" ]; then return 0; fi
  [ -n "${1:-}" ] || return 0
  local file; file="$(autonomy_log_path)"
  mkdir -p "$(dirname "$file")" 2>/dev/null || true
  # A ledger the mission dies for is worse than a gap in the ledger: ~/.sdd unwritable or a full
  # disk warns and lets the phase carry on. Under `set -e` a failing `>>` would abort the runner.
  # One printf = one write(2) on an O_APPEND fd, which is what keeps two repos running at once
  # from interleaving. jq never writes to the file directly: its stdio may split the output.
  printf '%s\n' "$1" >> "$file" 2>/dev/null || {
    warn "could not write the autonomy ledger at $file — the mission goes on, the row is lost"
    return 0
  }
}

# Never a malformed row: broken JSONL is the one way the judge reads garbage believing it is data.
# jq is a hard dependency (preflight fails without it), so absence here is an anomaly, not a mode.
autonomy_have_jq() {
  command -v jq >/dev/null 2>&1 && return 0
  [ "$AUTONOMY_WARNED" = "1" ] || warn "jq not found — the autonomy ledger is not being written"
  AUTONOMY_WARNED=1
  return 1
}

# An escalation spends no session, so the session fields are ABSENT rather than zeroed. `kind` is
# an enum and not prose because the judge must not parse sentences: they get rewritten, and the
# three escalations mean different things — a deliberate Jidoka is not the same as burnt budget.
autonomy_blocked_row() {   # autonomy_blocked_row <kind> <phase> <gate_why>
  autonomy_have_jq || return 0
  local stamp; stamp="$(autonomy_kit_stamp)"
  autonomy_append "$( jq -cn \
    --arg ts "$(date -Iseconds)" --arg kind "$1" --arg phase "$2" \
    --arg why "$(printf '%s' "$3" | head -c 200)" \
    --arg run_id "$AUTONOMY_RUN_ID" --arg invocation "$AUTONOMY_INVOCATION" \
    --arg sha "${stamp%%|*}" --arg dirty "${stamp#*|}" \
    --arg project "$PROJECT_NAME" --arg repo "$REPO_ROOT" --arg mission "$MISSION" \
    '{v: 1, ts: $ts, event: "blocked", kind: $kind,
      run_id: $run_id, invocation: $invocation,
      kit_sha: (if $sha == "" then null else $sha end),
      kit_dirty: (if $dirty == "" then null else ($dirty == "true") end),
      project: $project, repo: $repo, mission: $mission, phase: $phase,
      gate_why: $why}' )"
}
```

- [ ] **Step 5: Ligar os três pontos de escalada e o `run_id`**

No topo de `cmd_run()` (`:1225`), logo após `resolve_mission`/`PIPELINE_LOG=`:

```bash
  # One id per `sdd run` invocation. Without it a resumed mission produces two indistinguishable
  # `attempt:1` rows for the same phase; with it, "this mission needed N runs" becomes countable —
  # a better friction signal than the session count.
  AUTONOMY_RUN_ID="$(uuidgen)"
  AUTONOMY_INVOCATION="run"
```

Depois, uma linha após cada `pipeline_log_line "… BLOCKED …"`:

```bash
      pipeline_log_line "$(date -Iseconds)  BLOCKED  EXEC  increment marked blocked by the executor"
      autonomy_blocked_row "increment-blocked" "EXEC" "$GATE_WHY"
```

```bash
      pipeline_log_line "$(date -Iseconds)  BLOCKED  $phase  $GATE_WHY"
      autonomy_blocked_row "budget-exhausted" "$phase" "$GATE_WHY"
```

```bash
      pipeline_log_line "$(date -Iseconds)  BLOCKED  $phase  $GATE_WHY"
      autonomy_blocked_row "no-progress" "$phase" "$GATE_WHY"
```

- [ ] **Step 6: Rodar o teste e ver passar**

```bash
bash -n bin/sdd && shellcheck -S warning bin/sdd && tests/check-autonomy.sh
```

Esperado: **rc 0 e nenhuma linha `FAIL`**. (Não conte `ok` exatos: contagem exata vira dívida a cada asserção nova e não mede nada que o rc já não meça.)

- [ ] **Step 7: Entrar na suíte e mover o piso de idioma**

Em `tests/run-all.sh`, após a linha do `check-dry-run` e **sem** guarda de `SDD_MUTANT` (ao
contrário do `check-preflight`), porque as mutações da Task 5 sabotam o escritor e quem tem de
morrer é a suíte do sandbox:

```bash
run "autonomy ledger" "$ROOT/tests/check-autonomy.sh"
```

Em `tests/check-lang.sh`, o piso passa de 25 para 26 (o glob `tests/*.sh` acaba de ganhar um
arquivo), com o comentário dizendo qual arquivo o moveu.

- [ ] **Step 8: Documentar `SDD_STATE_DIR` em prosa**

Em `config/schema.md`, fora da tabela de chaves:

```markdown
### Not a config key: `SDD_STATE_DIR`

The autonomy ledger is **global**, not per-repo: `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl`.
It is an environment variable and deliberately not a `.sdd/config.sh` key — a per-repo key would
suggest a per-repo file, and "maturity across projects" cannot be measured in one. The suite
exports it to a temporary directory so no test can touch the real ledger.
```

⚠️ Não acrescente linha `` | `SDD_STATE_DIR` | `` à tabela: a checagem 4 do `sdd health` compara a
tabela com as chaves do `load_config()` e acusaria `doc-without-key`.

- [ ] **Step 9: Verificar a suíte inteira e commitar**

```bash
tests/run-all.sh && bin/sdd health
# Prova de que a suíte não encosta no ledger real:
ls -l ~/.sdd/autonomy-log.jsonl 2>/dev/null || echo "sem ledger real — esperado numa máquina limpa"
git add bin/sdd tests/check-autonomy.sh tests/run-all.sh tests/check-lang.sh config/schema.md
git commit -m "feat(autonomy): ledger global de fatos, escrito nas três escaladas

O juiz do I13.3 precisa de série histórica; o runner passa a gravar o que já
observa. Só fatos: score é rótulo, e rótulo é o que os gates existem para
proibir.

Global em ~/.sdd porque maturidade entre projetos não cabe em arquivo por repo
— e porque arquivo escrito entre fases dentro do alvo derrubaria gate_REVIEW e
preflight (o defeito do pipeline.log, 53cf63a).

As guardas moram na função de append, não nos chamadores: as escaladas são
três e a quarta nasceria com o defeito. A guarda de dry-run usa forma
sintática distinta da do diário de propósito — texto igual faria a mutação
RUN_inverted_journal sabotar as duas.

run-all.sh exporta SDD_STATE_DIR no topo: sem isso cada rodada da suíte
injetaria linha de fixture no ledger real da máquina."
```

---

### Task 2: Linhas de sessão — gate avaliado uma vez, retry medido

Entrega: cada sessão vira uma linha com o resultado do gate, e o retry — que hoje roda sem
medição nenhuma — passa a ter seu próprio `moved`.

**Files:**
- Modify: `bin/sdd` — `run_phase()` (`:682-745`) publica os fatos da sessão; `cmd_run()` avalia o
  gate uma vez e escreve nos dois pontos (`:1341` e `:1356`); novo `autonomy_session_row()`
- Modify: `tests/check-autonomy.sh` — bloco novo

**Interfaces:**
- Consumes: `autonomy_append`, `autonomy_kit_stamp`, `autonomy_have_jq`, `AUTONOMY_RUN_ID`
- Produces:
  - `LAST_PHASE_RC`, `LAST_PHASE_COST`, `LAST_PHASE_DUR`, `LAST_PHASE_STEP`, `LAST_PHASE_AGENT`,
    `LAST_PHASE_MODEL` (globais, escritas por `run_phase`)
  - `autonomy_session_row <phase> <attempt> <retry:true|false> <moved:true|false> <gate:pass|fail> <gate_why>`

- [ ] **Step 1: Escrever o teste que falha**

Acrescentar a `tests/check-autonomy.sh`, antes do bloco final de contagem:

```bash
# --- real sessions, still offline -------------------------------------------
# The stub `claude` exits non-zero, so the session does nothing: the gate fails, the disk did not
# move, the runner retries once and escalates with `no-progress`. Three real rows, no token.
echo "== session rows =="
: > "$LEDGER"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
EOF
cat > "$FIX/.stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
git add -A && git commit -qm "chore: pending increment"

"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "two dead sessions escalate with rc 3" "3" "$rc"
assert_eq "two session rows plus one escalation" "3" "$(nrows)"
assert_eq "every row is valid JSON" "1" "$(jq -se . "$LEDGER" >/dev/null 2>&1 && echo 1 || echo 0)"

assert_eq "the first row is a session" "session" "$(jq -r -s '.[0].event' "$LEDGER")"
assert_eq "the first session is not a retry" "false" "$(jq -r -s '.[0].retry' "$LEDGER")"
assert_eq "the second row is the retry" "true" "$(jq -r -s '.[1].retry' "$LEDGER")"
# The whole point of the metric: a session that changed nothing on disk is waste, and until now
# the retry ran with no measurement at all.
assert_eq "the retry carries its own moved" "false" "$(jq -r -s '.[1].moved' "$LEDGER")"
assert_eq "the gate result rides with the session" "fail" "$(jq -r -s '.[0].gate' "$LEDGER")"
assert_eq "claude's rc is recorded" "1" "$(jq -r -s '.[0].rc' "$LEDGER")"
# The session log has no cost field when claude died: "?" must become null, never a string, or
# the judge sums text.
assert_eq "unknown cost is null, not a string" "true" "$(jq -s '.[0].cost_usd == null' "$LEDGER")"
assert_eq "all three rows share one run_id" "1" \
  "$(jq -s '[.[].run_id] | unique | length' "$LEDGER")"
assert_eq "the escalation is no-progress" "no-progress" "$(jq -r -s '.[2].kind' "$LEDGER")"
```

- [ ] **Step 2: Rodar o teste e ver falhar**

```bash
tests/check-autonomy.sh
```

Esperado: FALHA em "two session rows plus one escalation" — vem `1` (só a escalada), porque
nenhuma linha de sessão é escrita ainda.

- [ ] **Step 3: `run_phase` publica os fatos da sessão**

Em `bin/sdd`, dentro de `run_phase()`, logo após a linha do `pipeline_log_line` (`:735`):

```bash
  # Published for the autonomy ledger, which is written by cmd_run — only there is the gate
  # result known, and the row carries it.
  LAST_PHASE_RC="$rc"
  LAST_PHASE_COST="$cost"
  LAST_PHASE_DUR="$dur"
  LAST_PHASE_STEP="$pstep"
  LAST_PHASE_AGENT="$agent"
  LAST_PHASE_MODEL="$model"
```

E ao lado de `LAST_PHASE_SID=""` (`:746`), inicializar todas sob `set -u`:

```bash
LAST_PHASE_SID=""
LAST_PHASE_RC=""
LAST_PHASE_COST=""
LAST_PHASE_DUR=""
LAST_PHASE_STEP=""
LAST_PHASE_AGENT=""
LAST_PHASE_MODEL=""
```

- [ ] **Step 4: Construtor da linha de sessão**

Em `bin/sdd`, após `autonomy_blocked_row()`:

```bash
# One row per session, written after the gate has been evaluated — the row carries the gate
# result, so it cannot be born before it.
autonomy_session_row() {  # <phase> <attempt> <retry> <moved> <gate> <gate_why>
  autonomy_have_jq || return 0
  local stamp; stamp="$(autonomy_kit_stamp)"
  autonomy_append "$( jq -cn \
    --arg ts "$(date -Iseconds)" --arg phase "$1" --arg attempt "$2" \
    --arg retry "$3" --arg moved "$4" --arg gate "$5" \
    --arg why "$(printf '%s' "$6" | head -c 200)" \
    --arg run_id "$AUTONOMY_RUN_ID" --arg invocation "$AUTONOMY_INVOCATION" \
    --arg sha "${stamp%%|*}" --arg dirty "${stamp#*|}" \
    --arg project "$PROJECT_NAME" --arg repo "$REPO_ROOT" --arg mission "$MISSION" \
    --arg step "$LAST_PHASE_STEP" --arg agent "$LAST_PHASE_AGENT" \
    --arg model "$LAST_PHASE_MODEL" --arg session "$LAST_PHASE_SID" \
    --arg rc "$LAST_PHASE_RC" --arg dur "$LAST_PHASE_DUR" --arg cost "$LAST_PHASE_COST" \
    '{v: 1, ts: $ts, event: "session",
      run_id: $run_id, invocation: $invocation,
      kit_sha: (if $sha == "" then null else $sha end),
      kit_dirty: (if $dirty == "" then null else ($dirty == "true") end),
      project: $project, repo: $repo, mission: $mission,
      phase: $phase, step: $step, agent: $agent, model: $model,
      attempt: ($attempt | tonumber? // null), retry: ($retry == "true"),
      session: $session,
      rc: ($rc | tonumber? // null),
      dur_s: ($dur | tonumber? // null),
      cost_usd: ($cost | tonumber? // null),
      moved: ($moved == "true"),
      gate: $gate, gate_why: $why}' )"
}
```

⚠️ `cost_usd` usa `tonumber? // null`: o `run_phase` cai para a string `"?"` quando o jq não acha
o campo no log da sessão (`bin/sdd:733`), e `"?" | tonumber?` devolve vazio, virando `null`.

- [ ] **Step 5: Avaliar o gate uma vez e escrever nos dois pontos**

Em `cmd_run()`, o trecho de `before="$(state_fingerprint)"` até o `return 3` do `no-progress`
passa a ser:

```bash
    before="$(state_fingerprint)"
    run_phase "$phase"
    after="$(state_fingerprint)"

    # The projection branch stays FIRST, exactly where it is today. Moving the gate evaluation
    # above it would make `--dry-run` run TEST_CMD once more per projected phase — a behaviour
    # change this increment has no mandate for, and one that check-dry-run.sh measures.
    if [ "$DRY_RUN" = "1" ]; then
      [ -n "$force_phase" ] && return 0
      dry_next="$(next_pending_phase "$phase")"
      [ -n "$dry_next" ] && continue
      dim "  (dry-run: end of the projection — no session was opened)"
      return 0
    fi

    # Evaluated ONCE into a variable, then branched on. Writing the ledger row inside each of the
    # four branches would multiply the same defect four times — and gate_ functions run TEST_CMD,
    # so calling them twice is not free either.
    local gate_rc=0 moved="false"
    gate_"$phase" || gate_rc=$?
    [ "$before" != "$after" ] && moved="true"
    autonomy_session_row "$phase" "${attempts[$phase]}" "false" "$moved" \
      "$( [ "$gate_rc" -eq 0 ] && echo pass || echo fail )" "$GATE_WHY"

    phases_run=$((phases_run + 1))
    if [ "$max_phases" -gt 0 ] && [ "$phases_run" -ge "$max_phases" ]; then
      info ""; dim "  --max-phases=$max_phases reached"; return 0
    fi

    if [ "$gate_rc" -eq 0 ]; then
      ok "gate $phase: $GATE_WHY"
      force_phase=""
      continue
    fi

    if [ "$moved" = "true" ]; then
      dim "  gate $phase not yet: $GATE_WHY (but the session moved forward — carrying on)"
      force_phase=""
      continue
    fi

    warn "gate $phase failed and the session changed nothing: $GATE_WHY"
    warn "  retrying once with the gate reason in the prompt"
    run_phase "$phase" "$LAST_PHASE_SID"
    # The retry gets its own pair of fingerprints. Until now it ran with no measurement at all,
    # and `moved/total` is precisely the metric that needs it.
    local after2 moved2="false" gate_rc2=0
    after2="$(state_fingerprint)"
    [ "$after" != "$after2" ] && moved2="true"
    gate_"$phase" || gate_rc2=$?
    autonomy_session_row "$phase" "${attempts[$phase]}" "true" "$moved2" \
      "$( [ "$gate_rc2" -eq 0 ] && echo pass || echo fail )" "$GATE_WHY"

    if [ "$gate_rc2" -eq 0 ]; then
      ok "gate $phase (on the retry): $GATE_WHY"
      force_phase=""
      continue
    fi
    if [ "$moved2" = "false" ]; then
      info ""
      bad "BLOCKED in $phase — two sessions without moving the disk: $GATE_WHY"
      pipeline_log_line "$(date -Iseconds)  BLOCKED  $phase  $GATE_WHY"
      autonomy_blocked_row "no-progress" "$phase" "$GATE_WHY"
      return 3
    fi
    force_phase=""
```

⚠️ O dry-run continua saindo **antes** de qualquer escrita, e a guarda dentro do
`autonomy_append` é a segunda linha de defesa — as duas de propósito.

- [ ] **Step 6: Rodar o teste e ver passar**

```bash
bash -n bin/sdd && shellcheck -S warning bin/sdd && tests/check-autonomy.sh && tests/check-dry-run.sh
```

Esperado: **rc 0 e nenhuma linha `FAIL`** nos dois. O `check-dry-run` intacto é a prova de que o
refactor não mexeu na projeção — o ramo de `--dry-run` continua sendo o primeiro depois do
`run_phase`.

- [ ] **Step 7: Commitar**

```bash
git add bin/sdd tests/check-autonomy.sh
git commit -m "feat(autonomy): uma linha por sessão, e o retry finalmente é medido

O gate passa a ser avaliado uma vez para variável e a linha nasce depois dele
— escrever dentro dos quatro ramos multiplicaria o mesmo defeito por quatro, e
gate_ roda TEST_CMD, então avaliar duas vezes também não é grátis.

Mudança de comportamento junto: o retry ganha seu próprio par de
state_fingerprint. Ele rodava sem medição nenhuma, e moved/total é exatamente
a métrica que precisa disso.

cost_usd desconhecido vira null e não a string '?', senão o juiz soma texto."
```

---

### Task 3: `sdd retry` também gasta sessão — e é o sinal mais forte

Entrega: o retry humano deixa de ser invisível para o juiz.

**Files:**
- Modify: `bin/sdd` — `cmd_retry()` (`:1371-1383`)
- Modify: `tests/check-autonomy.sh`

**Interfaces:**
- Consumes: `autonomy_session_row`, `AUTONOMY_RUN_ID`, `AUTONOMY_INVOCATION`
- Produces: nada novo — só passa a preencher `invocation:"retry"`

- [ ] **Step 1: Escrever o teste que falha**

```bash
# --- sdd retry is a human-forced session, and that is a first-class signal ---
# It is literally the rubric's "refez": the human looked at the result and pushed the phase
# again. Leaving it out of the ledger would hide the strongest friction signal there is.
echo "== retry invocation =="
: > "$LEDGER"
"$SDD" retry "$MISSION" >/dev/null 2>&1
assert_eq "sdd retry writes one session row" "1" "$(nrows)"
assert_eq "and marks itself as a retry invocation" "retry" "$(rows '.invocation')"
assert_eq "with its own run_id" "true" "$(rows '(.run_id | length) > 0')"
```

- [ ] **Step 2: Rodar o teste e ver falhar**

```bash
tests/check-autonomy.sh
```

Esperado: FALHA em "sdd retry writes one session row" — vem `0`.

- [ ] **Step 3: Implementar**

Em `cmd_retry()`, após `PIPELINE_LOG="$(log_dir)/pipeline.log"`:

```bash
  AUTONOMY_RUN_ID="$(uuidgen)"
  AUTONOMY_INVOCATION="retry"
```

E o fim da função:

```bash
  step "retrying $phase with a FRESH session"
  local before after moved="false" gate_rc=0
  before="$(state_fingerprint)"
  run_phase "$phase"
  after="$(state_fingerprint)"
  [ "$before" != "$after" ] && moved="true"
  gate_"$phase" || gate_rc=$?
  autonomy_session_row "$phase" "1" "false" "$moved" \
    "$( [ "$gate_rc" -eq 0 ] && echo pass || echo fail )" "$GATE_WHY"
  if [ "$gate_rc" -eq 0 ]; then ok "gate $phase: $GATE_WHY"; return 0; fi
  bad "gate $phase not yet: $GATE_WHY"
  return 3
```

⚠️ `attempt` é `1` porque cada `sdd retry` é uma invocação nova: o que distingue esta linha de uma
sessão de `sdd run` é o `invocation`, não a contagem.

- [ ] **Step 4: Rodar o teste e ver passar**

```bash
bash -n bin/sdd && shellcheck -S warning bin/sdd && tests/check-autonomy.sh
```

Esperado: **rc 0 e nenhuma linha `FAIL`**.

- [ ] **Step 5: Commitar**

```bash
git add bin/sdd tests/check-autonomy.sh
git commit -m "feat(autonomy): sdd retry entra no ledger com invocation=retry

O spec excluía o cmd_retry por descuido — ele gasta sessão real e é
humano-iniciado, ou seja, é literalmente o 'refez' da rubrica. Deixá-lo de
fora esconderia o sinal de atrito mais forte que existe."
```

---

### Task 4: `sdd autonomy` — o leitor que se recusa a inventar

Entrega: dá para ver a taxa de desperdício por versão do kit, e o comando se recusa a responder
o que o dado não sustenta.

**Files:**
- Modify: `bin/sdd` — `cmd_autonomy()` novo antes de `cmd_help()` (`:1387`), entrada no `main()`
  (`:1419`) e no texto do `cmd_help`
- Modify: `tests/check-autonomy.sh`
- Modify: `README.md` — o comando na lista de uso
- Modify: `docs/pipeline.md` — seção sobre o ledger

**Interfaces:**
- Consumes: `autonomy_log_path`
- Produces: `cmd_autonomy` (subcomando `sdd autonomy`)

- [ ] **Step 1: Escrever o teste que falha**

```bash
# --- the reader ------------------------------------------------------------
# Fixture ledger written by hand: this is OUR format, so there is no third-party source to copy
# from (the provenance rule covers skill output). Every row here exists to prove one refusal.
echo "== reader =="
mkdir -p "$FIX/read"
cat > "$FIX/read/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":3,"retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":4,"retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"gate":"fail","gate_why":"old schema, no moved"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$FIX/read" "$SDD" autonomy 2>&1 )"; rc=$?

assert_eq "the reader exits 0 with data" "0" "$rc"
# 2 comparable sessions (rows 1 and 2), 1 of them stalled => 50%.
assert_eq "waste is computed over comparable sessions only" "1" \
  "$(grep -c '50% waste' <<< "$out")"
assert_eq "it says how many rows it excluded, and why" "1" \
  "$(grep -c '2 non-comparable' <<< "$out")"
assert_eq "escalations are counted apart from sessions" "1" \
  "$(grep -c 'no-progress: 1' <<< "$out")"
# Anti-vacuity floor, same family as the surface floor in check-lang: a broken jq filter would
# report "0 sessions, all good" forever.
assert_eq "the header states how many rows it read" "1" "$(grep -c '5 row(s)' <<< "$out")"

# An empty ledger is NOT 0% waste. Zeros that look like excellence are the vacuity the whole kit
# exists to kill.
mkdir -p "$FIX/empty"
out="$( SDD_STATE_DIR="$FIX/empty" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "no ledger yet exits 1" "1" "$rc"
assert_eq "and says 'no data' instead of printing zeros" "1" "$(grep -c 'no data' <<< "$out")"
assert_eq "and never prints a percentage" "0" "$(grep -c '%' <<< "$out")"

# A malformed row dies loudly: skipping it in silence is how the judge ends up reading a subset
# and calling it the whole history.
mkdir -p "$FIX/bad"
printf '{"v":1,"event":"session"\n' > "$FIX/bad/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$FIX/bad" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a malformed row fails loudly" "1" "$rc"

# sdd health check 5 fails on a subcommand missing from the help — assert it here too, so the
# reason is visible at the point of change instead of three files away.
assert_eq "the subcommand is in sdd help" "1" "$( "$SDD" help 2>&1 | grep -c 'sdd autonomy' )"
```

- [ ] **Step 2: Rodar o teste e ver falhar**

```bash
tests/check-autonomy.sh
```

Esperado: FALHA em "the reader exits 0 with data" — o `main()` responde
`unknown command: autonomy`, rc 1.

- [ ] **Step 3: Implementar o leitor**

Em `bin/sdd`, antes de `cmd_version()`:

```bash
# ---------------------------------------------------------------------------
# Reader for the autonomy ledger. It prints NUMBERS and never a verdict: whether the kit improved
# is the judge's answer (sdd-kaizen, I13.3), and a reader that opines today becomes the yardstick
# that judge would have to contradict tomorrow.
#
# This command is the human's window; the JUDGE reads the JSONL with jq. Coupling I13.3 to this
# text would freeze a table nobody promised to keep.
cmd_autonomy() {
  local file; file="$(autonomy_log_path)"
  command -v jq >/dev/null 2>&1 || die "jq not found — it is required to read the ledger"

  # Absent or empty is NOT zero waste. Zeros that look like excellence are exactly the vacuity the
  # floors in check-lang and cmd_health exist to kill.
  if [ ! -s "$file" ]; then
    warn "no data: the ledger at $file does not exist yet (or has no rows)"
    dim "  It is written by 'sdd run' and 'sdd retry'. Nothing has been recorded on this machine."
    return 1
  fi
  # A malformed row dies loudly. Skipping it quietly is how a judge ends up reading a subset and
  # calling it the whole history.
  jq -se . "$file" >/dev/null 2>&1 || die "malformed row in $file — the ledger is not readable"

  local total; total="$(grep -c . "$file")"
  step "sdd autonomy — $file · $total row(s)"

  jq -rs '
    def comparable: .event == "session" and .kit_dirty == false
                    and (.kit_sha != null) and (has("moved"));
    (map(select(.event == "session" and (comparable | not))) | length) as $skipped
    | (map(select(comparable)) | group_by(.kit_sha)) as $groups
    | ($groups | map(
        (.[0].kit_sha) as $sha
        | (length) as $n
        | (map(select(.moved == false)) | length) as $stalled
        | (map(.mission) | unique | length) as $missions
        | (map(.cost_usd // 0) | add) as $cost
        | "  \($sha)  \($n) session(s) · \($stalled) stalled · \(($stalled * 100 / $n) | floor)% waste · \($missions) mission(s) · US$ \($cost | . * 100 | round / 100)"
      ) | join("\n"))
    , (map(select(.event == "blocked")) | group_by(.kind)
       | map("  \(.[0].kind): \(length)") | join("\n") | select(length > 0) | "\nescalations\n" + .)
    , (if $skipped > 0 then "\n  (\($skipped) non-comparable row(s) excluded: dirty kit, no kit_sha, or no moved field)" else "" end)
  ' "$file"
}
```

⚠️ **A saída é inglesa porque `bin/sdd` é superfície do kit** e o `tests/check-lang.sh` a mede —
"sessões"/"não-comparáveis" reprovariam a suíte na hora. O `OUTPUT_LANG` governa artefato de
missão, nunca mensagem do runner. Vale para o texto do `warn`/`dim` acima também.

⚠️ `comparable` exige `has("moved")`: linha de esquema velho é **excluída e contada**, nunca
somada como "não mexeu" — isso inflaria o desperdício do passado e faria qualquer mudança futura
parecer melhoria.

- [ ] **Step 4: Registrar o subcomando**

No `main()`, após a linha do `close`:

```bash
    autonomy)  cmd_autonomy "$@" ;;
```

No `cmd_help`, na seção `FOR SCRIPTS` — ou logo após `sdd close`:

```
  sdd autonomy               waste per kit version, read from the global autonomy ledger
```

- [ ] **Step 5: Rodar o teste e ver passar**

```bash
bash -n bin/sdd && shellcheck -S warning bin/sdd && tests/check-autonomy.sh && bin/sdd health
```

Esperado: `check-autonomy` verde; `sdd health` rc 0 (a checagem 5 confirma o subcomando no help).

- [ ] **Step 6: Documentar no mesmo commit**

`README.md`, na lista de comandos:

```
sdd autonomy           waste per kit version, from the global ledger (~/.sdd/autonomy-log.jsonl)
```

`docs/pipeline.md`, seção nova ao lado da que descreve o `pipeline.log`:

```markdown
## The autonomy ledger

Two records, different jobs. `.sdd/logs/<mission>/pipeline.log` is the **journal of one mission**,
ephemeral and local. `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl` is the **series across all
missions and all projects**, and it exists for one reader: the kaizen judge (`sdd-kaizen`, I13.3),
which answers "did the last change to the kit improve autonomy or hurt it?".

It is global, not per-repo, for two reasons. Maturity across projects cannot be measured in a
file that lives inside one project. And a file the runner writes BETWEEN phases inside the target
repo would sit untracked and fail `gate_REVIEW` and `sdd preflight` — the `pipeline.log` defect,
which was fixed by making that journal ephemeral, a way out this ledger does not have.

It records **facts, never a score**: phase, attempt, whether the session moved the disk, rc, cost,
the gate result and its reason. `ok|leve|refez` is a label, and a runner that labels its own work
is the "label instead of artifact" every gate here exists to forbid. The judge derives the label,
and can change its yardstick later without rewriting the past.

Every row carries `kit_sha` and `kit_dirty`. That is the before/after axis: without it a change
in the numbers gets attributed to the calendar instead of to the kit change that caused it, and
the judge cannot count missions per kit version to answer "not enough data yet".

`sdd autonomy` prints the human view. The judge reads the JSONL with `jq` — never that table.
```

- [ ] **Step 7: Commitar**

```bash
git add bin/sdd tests/check-autonomy.sh README.md docs/pipeline.md
git commit -m "feat(autonomy): sdd autonomy — desperdício por versão do kit

Imprime número e nunca veredito: se melhorou é resposta do juiz (I13.3), e
leitor que opina hoje vira a régua que o juiz teria de contradizer amanhã.

Três recusas explícitas: linha não-comparável (kit sujo, sha ausente, sem
campo moved) fica fora E é contada; ledger vazio dá rc 1 e 'sem dados' em vez
de 0%; linha malformada morre alto em vez de ser pulada em silêncio."
```

---

### Task 5: Mutações, medição e o registro kaizen

Entrega: as asserções novas provam que medem, o custo na suíte está medido, e a melhoria tem
número.

**Files:**
- Modify: `tests/check-mutation.sh` — duas mutações + `CATALOG`
- Modify: `KAIZEN_LOG.md`
- Modify: `TODO.md` — **não há item para fechar** (o I13.1 vem do design kaizen, não do TODO). O
  que entra aqui é achado novo, se houver: em particular, se o Step 4 mostrar a suíte estourando
  o alvo de 15s, isso vira entrada no formato do arquivo, com o número medido

**Interfaces:**
- Consumes: tudo das Tasks 1-4
- Produces: score de mutação 18

- [ ] **Step 1: Escrever as mutações**

Em `tests/check-mutation.sh`, após `mut_RUN_ignores_output_lang()`:

```bash
# Not a gate: the ledger the kaizen judge reads. The projection starts writing, and rows for
# sessions that never happened enter the arithmetic that decides whether the kit graduates.
mut_RUN_autonomy_ignores_dry_run() {
  sed -i 's|  if \[ "\$DRY_RUN" = "1" \]; then return 0; fi|  if false; then return 0; fi|' "$1"
}

# The reader treats a row with no `moved` field (an older schema) as "did not move" instead of
# excluding it. Old history gets its waste inflated, and every later change looks like progress —
# the failure mode is a judge that congratulates the kit for nothing.
mut_RUN_autonomy_null_moved_as_zero() {
  sed -i 's|and (has("moved"))|and true|' "$1"
}
```

E no `CATALOG`, após `RUN_ignores_output_lang`:

```bash
  RUN_autonomy_ignores_dry_run
  RUN_autonomy_null_moved_as_zero
```

- [ ] **Step 2: Verificar que as âncoras são únicas**

O catálogo exige âncora única: `sed` acerta **toda** linha que casa, e uma âncora compartilhada
faz uma mutação sabotar dois lugares e parar de medir o que promete.

```bash
grep -c 'if \[ "\$DRY_RUN" = "1" \]; then return 0; fi' bin/sdd   # esperado: 1
grep -c '\[ "\$DRY_RUN" = "1" \] && return 0' bin/sdd             # esperado: 1
grep -c 'and (has("moved"))' bin/sdd                              # esperado: 1
```

Qualquer número diferente de 1 ⇒ pare e torne a âncora única antes de seguir.

- [ ] **Step 3: Rodar a mutação e ver 18/18**

```bash
tests/check-mutation.sh
```

Esperado: `score: 18 caught, 0 known gap(s), of 18`. Se alguma das duas novas aparecer como
`is NOT caught`, a asserção correspondente é decorativa — conserte o **teste**, não a mutação.

- [ ] **Step 4: Medir o custo na suíte**

```bash
for i in 1 2 3; do /usr/bin/time -f "%e s" tests/run-all.sh >/dev/null; done
# A base tem de vir do commit, não da árvore: o trabalho está commitado e `git stash` só mexe
# no que está sujo — mediria o depois duas vezes.
BASE_DIR="$(mktemp -d)"; git archive "$(git merge-base main HEAD)" | tar -x -C "$BASE_DIR"
for i in 1 2 3; do /usr/bin/time -f "base %e s" "$BASE_DIR/tests/run-all.sh" >/dev/null; done
rm -rf "$BASE_DIR"
```

Anote os dois números. O alvo do plano é ≤15s e a suíte já está em ~15,9s nesta máquina — se
estourar de forma relevante, **pare e reporte**: a decisão (subir o alvo, paralisar mais mutantes
via `SDD_MUTATION_JOBS`) é humana.

- [ ] **Step 5: Registrar no `KAIZEN_LOG.md` com número**

Preencha os `<…>` com os números medidos no Step 4 — sem número não é kaizen, é opinião:

```markdown
## 2026-08-15 — O runner passou a observar a si mesmo (I13.1)

**Problema medido:** o kit tinha 6 fases por missão e **zero** observabilidade sobre a própria
autonomia. A pergunta "a última mudança melhorou ou piorou?" só tinha resposta por memória
humana, e o piloto SQ-97 já mostrara que memória humana perde o dado: as 6 sessões foram
reconstruídas à mão, depois, a partir de logs.

**Antes → depois**

| | antes | depois |
|---|---|---|
| linhas de série histórica | 0 | 1 por sessão + 1 por escalada |
| sessões de retry medidas | 0 (rodavam sem `state_fingerprint`) | todas |
| mutação | 16/16 | 18/18 |
| suíte | <base> s | <depois> s |
| pontos de escrita com guarda própria | 3 (diário) | 6, todos por uma função só |

**O que mudou de verdade:** o gate passou a ser avaliado **uma vez** por sessão em vez de até
quatro vezes nos ramos do `cmd_run` — menos `TEST_CMD` rodando por fase, e a linha do ledger
nasce depois do gate porque carrega o resultado dele.

**O que não mudou de propósito:** nenhum score. O runner grava fato; quem julga é o `sdd-kaizen`
do I13.3, que nasce com série histórica em vez de opinião.
```

- [ ] **Step 6: Commitar**

```bash
git add tests/check-mutation.sh KAIZEN_LOG.md TODO.md
git commit -m "test(autonomy): duas mutações provam que o ledger mede

RUN_autonomy_ignores_dry_run e RUN_autonomy_null_moved_as_zero — a segunda é o
modo de falha que mais importa: linha de esquema velho contada como 'não
mexeu' infla o desperdício do passado e faz toda mudança futura parecer
melhoria. Score 16 -> 18.

Âncoras conferidas por grep -c: a guarda do autonomy usa forma sintática
distinta da do diário justamente para não compartilhar âncora."
```

---

## Verificação final

```bash
tests/run-all.sh && bin/sdd health && bin/sdd autonomy
```

1. Suíte verde, mutação **18/18**, `sdd health` rc 0.
2. `sdd autonomy` imprime desperdício por `kit_sha` sobre o ledger real desta máquina.
3. **A suíte não altera o ledger real** — confira `stat -c '%Y %s' ~/.sdd/autonomy-log.jsonl`
   antes e depois de `tests/run-all.sh`: idênticos.
4. `git log --oneline` mostra 5 commits, um por task.
