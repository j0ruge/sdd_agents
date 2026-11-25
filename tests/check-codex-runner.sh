#!/usr/bin/env bash
# Sensor for the runner's harness dispatch. Stubs only the provider process and worker receipt;
# the coordination, gate, hat, journal and ledger are the same code run against a real checkout.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-codex-runner-XXXXXX")"
trap 'rm -rf "$FIX"' EXIT
KIT="$FIX/kit" REPO="$FIX/repo" MISSION="20260101-codex-fixture"
export SDD_STATE_DIR="$FIX/state" SDD_PHASE_PROGRESS=off
export FIX
unset PHASE_ENGINE CODEX_PHASE_MODEL
mkdir -p "$KIT/bin" "$REPO" "$FIX/path"
cp "$ROOT/bin/sdd" "$ROOT/bin/sdd-coordination.py" "$KIT/bin/"
ln -s "$ROOT/agents" "$KIT/agents"
ln -s "$ROOT/templates" "$KIT/templates"
ln -s "$ROOT/config" "$KIT/config"
export PATH="$FIX/path:$PATH"

cat > "$FIX/path/claude" <<'STUB'
#!/usr/bin/env bash
touch "$FIX/claude.called"
exit 97
STUB
cat > "$FIX/path/gh" <<'STUB'
#!/usr/bin/env bash
[ "$*" = "auth status" ]
STUB
cat > "$KIT/bin/sdd-worker" <<'STUB'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$PWD|$*" >> "$FIX/guard"
[ -f "$FIX/signed" ] || { echo "missing signed unknown-cost allowance" >&2; exit 1; }
STUB
cat > "$KIT/bin/sdd-codex" <<'STUB'
#!/usr/bin/env bash
set -eu
if [ "$*" = --preflight ]; then
  touch "$FIX/adapter.preflight"
  [ ! -f "$FIX/login.missing" ]
  exit $?
fi
printf '%s\n' "$PWD|$*|${GIT_REFLOG_ACTION:-}" >> "$FIX/provider"
cat >> "$FIX/prompt"
native=3a80f12a-8f18-4077-8358-558cd54c75ff
if [ -f "$FIX/hat-cross" ]; then printf 'forbidden\n' > foreign.txt; fi
printf '{"type":"system","subtype":"init","provider":"codex","session_id":"%s","tool_inventory":"configured","tools":["Bash"],"mcp_servers":[]}\n' "$native"
printf '{"type":"result","provider":"codex","session_id":"%s","subtype":"success","is_error":false,"total_cost_usd":null,"estimated_cost_usd":0.01,"estimate_basis":{"source":"fixture"},"num_turns":1,"usage":{"input_tokens":70,"cache_read_input_tokens":20,"output_tokens":5}}\n' "$native"
STUB
chmod +x "$KIT/bin/sdd-codex" "$KIT/bin/sdd-worker" "$FIX/path/"*
SDD="$KIT/bin/sdd"
cd "$REPO"
git init -q -b develop
git config user.email fixture@example.com
git config user.name Fixture
mkdir -p .sdd ".agents/skills/codereview" "docs/handoffs/$MISSION"
printf '.sdd/logs/\n' > .gitignore
cat > .sdd/config.sh <<'CONF'
PROJECT_NAME=codex-fixture
DEFAULT_BRANCH=develop
TEST_CMD="test -f .sdd/config.sh"
JIRA_ENABLED=false
CONF
printf '%s\n' '# Fixture review instructions' > .agents/skills/codereview/SKILL.md
MDIR="$REPO/docs/handoffs/$MISSION"
cat > "$MDIR/00-missao.md" <<'MISSION'
---
missao: 20260101-codex-fixture
branch: develop
aprovacao: auto
---
# Mission
MISSION
: > "$MDIR/01-plano.md"
cat > "$MDIR/checkpoint.md" <<'CHECKPOINT'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
CHECKPOINT
git add . && git commit -qm 'Create pending mission fixture'

assert() {
  local label="$1"; shift
  if "$@"; then printf '  ok    %s\n' "$label"
  else printf '  FAIL  %s\n' "$label" >&2; [ ! -f "$FIX/out" ] || cat "$FIX/out" >&2; exit 1; fi
}

run() { PHASE_ENGINE=codex "$SDD" run "$MISSION" "$@" > "$FIX/out" 2>&1; }
no_launch() { [ ! -e "$FIX/provider" ] && [ ! -e "$FIX/claude.called" ]; }

assert 'dry-run selects Codex without invoking either harness' run --phase EXEC --dry-run
assert 'Codex EXEC projects Sol medium and its role' grep -Eq 'model: gpt-6\.2-sol .*effort: medium .*agent: sdd-executor' "$FIX/out"
assert 'dry-run never opens a session' no_launch
assert 'dry-run never checks or charges the signed receipt' test ! -e "$FIX/guard"

assert 'dry-run projects REVIEW' run --phase REVIEW --dry-run
assert 'Codex REVIEW projects Sol xhigh and the review role' grep -Eq 'model: gpt-6\.2-sol .*effort: xhigh .*agent: sdd-reviewer' "$FIX/out"
assert 'review prompt resolves the Codex skill from the target worktree' grep -Fq "$REPO/.agents/skills/codereview/SKILL.md" "$FIX/out"
assert 'QA accepts a configured application URL' env PHASE_ENGINE=codex APP_URL='http://qa.example.test:8080/a@b?c=d' \
  "$SDD" run "$MISSION" --phase QA --dry-run > "$FIX/qa-out" 2>&1
assert 'QA gives the adapter only the configured app hostname' grep -Eq -- '--qa-host +qa\.example\.test' "$FIX/qa-out"
PHASE_ENGINE=codex "$SDD" boot "$MISSION" REVIEW > "$FIX/out" 2>&1
assert 'manual Codex boot uses the same review skill' grep -Fq "$REPO/.agents/skills/codereview/SKILL.md" "$FIX/out"
assert 'manual Codex boot includes the role instructions' grep -Fq 'Role instructions from the kit (sdd-reviewer)' "$FIX/out"

assert 'REVIEW accepts an EXEC model override without using it' env PHASE_ENGINE=codex CODEX_PHASE_MODEL=gpt-6.2-astra \
  "$SDD" run "$MISSION" --phase REVIEW --dry-run > "$FIX/model-out" 2>&1
assert 'REVIEW stays on Sol xhigh under an EXEC override' grep -Eq 'model: gpt-6\.2-sol .*effort: xhigh ' "$FIX/model-out"
assert 'EXEC uses its configured model override' env PHASE_ENGINE=codex CODEX_PHASE_MODEL=gpt-6.2-astra \
  "$SDD" run "$MISSION" --phase EXEC --dry-run > "$FIX/model-out" 2>&1
assert 'EXEC effort remains medium under its model override' grep -Eq 'model: gpt-6\.2-astra .*effort: medium ' "$FIX/model-out"

assert 'Codex PR projection reaches a local handoff' run --phase PR --dry-run
assert 'Codex PR projection says publication is a worker handoff' grep -Fq 'PR needs worker publish' "$FIX/out"
assert 'Codex PR dry-run spends no session or delegation' no_launch
touch "$FIX/signed"
rc=0; run --phase PR || rc=$?
assert 'even signed Codex PR delegation does not launch a publishing session' test "$rc" -eq 2
assert 'Codex PR handoff is actionable' grep -Fq 'PR needs worker publish' "$FIX/out"
assert 'Codex PR handoff cannot fall back to Claude or invoke Codex' no_launch
assert 'Codex PR handoff bought no session' test ! -e "$FIX/guard"
rm "$FIX/signed"

rc=0; run --phase EXEC || rc=$?
assert 'unsigned Codex run is refused' test "$rc" -ne 0
assert 'refusal names the signed exception' grep -q 'missing signed unknown-cost allowance' "$FIX/out"
assert 'refusal spends no session' no_launch
assert 'worker checks the actual mission directory in the working checkout' grep -Fxq "$REPO|codex-run --mission $MDIR --phase EXEC --model gpt-6.2-sol" "$FIX/guard"

touch "$FIX/signed"
rc=0; run --phase EXEC --budget-override || rc=$?
assert 'Codex refuses the standalone budget override' grep -q -- '--budget-override does not apply' "$FIX/out"
assert 'budget override spends no session' no_launch
rc=0; run --phase EXEC || rc=$?
assert 'a successful harness response without artifacts fails the actual gate' test "$rc" -eq 3
assert 'first invocation uses the target checkout, model, effort and reflog label' grep -Eq "^$REPO\\|--model gpt-6\\.2-sol --effort medium --hat sdd-executor\\|sdd:EXEC:" "$FIX/provider"
assert 'inline retry resumes the actual native thread' grep -Fq -- '--resume 3a80f12a-8f18-4077-8358-558cd54c75ff' "$FIX/provider"
assert 'runner hands the executor role to the provider' grep -Fq 'You execute **one increment**' "$FIX/prompt"
assert 'runner hands the failing gate to the retry' grep -Fq 'Fix exactly that.' "$FIX/prompt"
assert 'retry revalidates signed budget' test "$(wc -l < "$FIX/guard")" -eq 3
assert 'ledger retains native thread ID, engine, usage and unknown USD' jq -es '
  map(select(.event == "session"))
  | length == 2 and all(.[]; .engine == "codex" and .effort == "medium" and
      .session == "3a80f12a-8f18-4077-8358-558cd54c75ff" and .gate == "fail" and
      .cost_usd == null and .usage.input_tokens == 70 and .usage.output_tokens == 5 and
      .estimated_cost_usd == 0.01 and .estimate_basis.source == "fixture" and
      .mcp_seen == null and .tools_leaked == null)
' "$SDD_STATE_DIR/autonomy-log.jsonl"

touch "$FIX/hat-cross"
rc=0; run --phase REVIEW || rc=$?
assert 'Codex still triggers the review hat write guard' grep -Eq 'touched .*outside its writes:.*foreign.txt' "$FIX/out"
assert 'Codex hat crossing exits 3' test "$rc" -eq 3
rm "$REPO/foreign.txt"

cat > "$FIX/path/acli" <<'STUB'
#!/usr/bin/env bash
printf '[]\n'
STUB
chmod +x "$FIX/path/acli"
cat > "$MDIR/10-ticket.md" <<'TICKET'
---
issue: SDD-1
---
TICKET
rm "$FIX/hat-cross"
close() { PHASE_ENGINE=codex "$SDD" close "$MISSION" > "$FIX/out" 2>&1; }
rm "$FIX/signed"
rc=0; close || rc=$?
assert 'close with JIRA disabled spends nothing' test "$rc" -eq 0
sed -i 's/JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
rc=0; close || rc=$?
assert 'Codex close reports its unsupported paid phase' grep -q 'CLOSE is not a delegated Codex campaign phase' "$FIX/out"
assert 'Codex close does not fall back to Claude' test ! -e "$FIX/claude.called"
sed -i 's/JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh
rm "$MDIR/10-ticket.md"

rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
assert 'Codex preflight exits green without Claude mirrors' test "$rc" -eq 0
assert 'Codex preflight uses the selected adapter capability probe' test -f "$FIX/adapter.preflight"
touch "$FIX/login.missing"
rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
assert 'Codex preflight cannot report readiness when the adapter refuses' test "$rc" -ne 0
assert 'Codex paths never invoke Claude' test ! -e "$FIX/claude.called"

python3 "$ROOT/tests/check-codex-adapter.py"
python3 "$ROOT/tests/check-codex-planner.py"
