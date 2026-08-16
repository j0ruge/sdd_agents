#!/usr/bin/env bash
# Sensor for the kaizen loop — the deterministic series, the KAIZEN gate and its Jidoka.
#
# ADR 0001 splits the judge in two: the runner derives labels and numbers (this file measures
# that half), the agent gives the verdict CITING them and never recalculates. A series that lies
# — a dropped escalation, a "latest" picked by sort order instead of file order, a meta row
# leaking into its own axis — poisons every verdict downstream, which is why the assertions here
# are mostly about classification: every row must land where the rubric says it lands.
#
# Hermetic: SDD_STATE_DIR points at a scratch directory of this test's own, and the series runs
# from a plain directory that is not a git repository — the ledger is global, so `sdd kaizen
# --series` must work from ANY cwd. Runs INSIDE mutants: the mutations that sabotage the rubric
# or the gate have to kill the sandbox suite through this file.
#
# Fixture ledger written by hand: this is OUR format (the provenance rule covers third-party
# skill output). Row shapes mirror the real constructors — autonomy_session_row and
# autonomy_blocked_row in bin/sdd — field for field.
#
# Usage: tests/check-kaizen.sh   (exit 0 = the series tells the truth and the gate holds)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
fails=0

# Instruments live OUTSIDE any repo under test, same decision (and same reason) as
# check-autonomy.sh: the instrument must not end up inside the thing it measures.
OUTSIDE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-kaizen-outside-XXXXXX")"
trap 'rm -rf "$OUTSIDE"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi }

export SDD_STATE_DIR="$OUTSIDE/state"
mkdir -p "$SDD_STATE_DIR"
LEDGER="$SDD_STATE_DIR/autonomy-log.jsonl"

# field <jq-filter> — reads the captured series output. -r for bare values.
SERIES_OUT=""
field() { jq -r "$1" <<< "$SERIES_OUT"; }

# =============================================================================
# series — the deterministic half of the judge
# =============================================================================
echo "== series =="

# Two kit versions in FILE order chosen so that lexical order disagrees: the previous sha
# (fff9999) sorts AFTER the latest (aaa1111). An implementation that picks "latest" by sorting
# (jq's group_by sorts by key) gets fff9999 and fails; so does one that lets a reappearing old
# sha open a new group. The four label scenarios are the probe's: m1/QA leve (moved:false +
# in-loop auto_retry), m1/REVIEW refez (budget-exhausted + human retry invocation), m2/EXEC
# refez (increment-blocked, a Jidoka with no session at all), m3/EXEC ok.
cat > "$LEDGER" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":true,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"blocked","kind":"budget-exhausted","run_id":"r1","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"REVIEW","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"session","run_id":"r2","invocation":"retry","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:05:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r3","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:06:00-03:00","event":"session","run_id":"r4","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":3.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:07:00-03:00","event":"session","run_id":"r5","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.5,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:08:00-03:00","event":"session","run_id":"r6","invocation":"run","kit_sha":"fff9999","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m4","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s6","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:09:00-03:00","event":"session","run_id":"r7","invocation":"run","kit_sha":null,"kit_dirty":null,"project":"p1","repo":"/p1","mission":"m5","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s7","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:10:00-03:00"}
{"v":1,"ts":"2026-08-15T10:11:00-03:00","event":"session","run_id":"r8","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"sdd_agents","repo":"/kit","mission":"20260815-kaizen","phase":"KAIZEN","step":"KAIZEN","agent":"sdd-kaizen","model":"opus","attempt":1,"auto_retry":false,"session":"s8","rc":0,"dur_s":10,"cost_usd":0.5,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# From a plain directory that is NOT a git repository: the ledger is global and the series must
# be readable from anywhere — a `--series` that demands a target repo would chain the judge's
# input to the wrong cwd.
mkdir -p "$OUTSIDE/anywhere"
SERIES_OUT="$( cd "$OUTSIDE/anywhere" && "$SDD" kaizen --series 2>/dev/null )"; rc=$?

assert_eq "the series exits 0" "0" "$rc"
assert_eq "and is valid JSON" "0" "$(jq -e . >/dev/null 2>&1 <<< "$SERIES_OUT"; echo $?)"
assert_eq "schema version" "1" "$(field '.v')"
assert_eq "latest comes from FILE order, and a reappearing old sha never opens a new group" \
  "aaa1111" "$(field '.latest.kit_sha')"
assert_eq "previous is the sha before it, in file order" "fff9999" "$(field '.previous.kit_sha')"
assert_eq "moved:false plus in-loop auto_retry labels the phase 'leve'" \
  "leve" "$(field '.previous.detail[] | select(.mission == "m1" and .phase == "QA") | .label')"
assert_eq "an escalation plus a human retry invocation labels the phase 'refez'" \
  "refez" "$(field '.previous.detail[] | select(.mission == "m1" and .phase == "REVIEW") | .label')"
assert_eq "increment-blocked labels the phase 'refez' even with zero dead sessions" \
  "refez" "$(field '.previous.detail[] | select(.mission == "m2" and .phase == "EXEC") | .label')"
assert_eq "a clean pass labels the phase 'ok'" \
  "ok" "$(field '.latest.detail[] | select(.mission == "m3") | .label')"
assert_eq "the label tally sums the detail" \
  '{"ok":0,"leve":1,"refez":2}' "$(jq -c '.previous.labels' <<< "$SERIES_OUT")"
assert_eq "escalations are counted by kind" '{"budget-exhausted":1,"increment-blocked":1}' \
  "$(jq -c '.previous.escalations' <<< "$SERIES_OUT")"
assert_eq "moved_rate is computed over the group's sessions" "0.8" \
  "$(field '.previous.moved_rate')"
assert_eq "one mission after the latest change" "1" "$(field '.guard.missions_after_change')"
assert_eq "one mission is below the guard floor of 3" "false" "$(field '.guard.sufficient')"
# The KAIZEN row shares the latest kit_sha on purpose: leaking into the group would inflate
# missions to 2 and sessions to 2, shifting the very guard that gates its own verdict.
assert_eq "the meta row does not inflate the latest group's sessions" "1" \
  "$(field '.latest.sessions')"
assert_eq "nor its missions" "1" "$(field '.latest.missions')"
assert_eq "every excluded row is counted, by reason" \
  '{"non_comparable":2,"unrecognized":1,"meta":1}' "$(jq -c '.excluded' <<< "$SERIES_OUT")"

# No ledger at all: the judge's first real run happens on an empty history, and the series must
# say so in the same shape — valid JSON, latest null, insufficient — instead of dying or zeroing.
SERIES_OUT="$( cd "$OUTSIDE/anywhere" && SDD_STATE_DIR="$OUTSIDE/empty" "$SDD" kaizen --series 2>/dev/null )"; rc=$?
assert_eq "a missing ledger still exits 0" "0" "$rc"
assert_eq "and still prints valid JSON" "0" \
  "$(jq -e . >/dev/null 2>&1 <<< "$SERIES_OUT"; echo $?)"
assert_eq "with latest null, not an invented group" "null" "$(field '.latest')"
assert_eq "and an insufficient guard, never a vacuous pass" "false" \
  "$(field '.guard.sufficient')"

# =============================================================================
# gate + jidoka — the flow around the verdict artifact
# =============================================================================
# The fixture is a KIT-SHAPED repo: bin/, templates/ and config/ copied in and committed, so that
# SDD_HOME (parent of bin/) IS the repo root — the configuration `sdd kaizen` requires, since the
# kaizen phase plans the KIT's next mission, never a target project's. The gate-section ledger is
# the series fixture above, so the expected sha is aaa1111; every row cmd_kaizen appends carries
# phase KAIZEN and lands in excluded.meta, never shifting the axis it is judged on.
echo "== gate fixture (a kit-shaped repo: SDD_HOME == REPO_ROOT) =="
FIX="$OUTSIDE/fix"
mkdir -p "$FIX"
cd "$FIX" || exit 1
git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture"
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$FIX/"
KSDD="$FIX/bin/sdd"
echo "kit" > kit.txt
git add -A && git commit -qm "init kit fixture"
"$KSDD" install >/dev/null
cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="kitfix"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF
printf -- '- [ ] a kit finding worth a mission\n' > TODO.md
git add -A && git commit -qm "chore: fixture kit config"

# No test spends tokens. The dead stub lets the pending-gate path burn its two attempts offline;
# the loud stub makes any session on a path that must NOT open one visible in the ledger row it
# would write (run_phase sends claude's own streams to log files, so the ledger is the witness).
mkdir -p "$OUTSIDE/stub"
dead_stub() {
  printf '#!/usr/bin/env bash\nexit 1\n' > "$OUTSIDE/stub/claude"
  chmod +x "$OUTSIDE/stub/claude"
}
loud_stub() {
  printf '#!/usr/bin/env bash\necho "ERROR: the test invoked the real claude" >&2\nexit 97\n' \
    > "$OUTSIDE/stub/claude"
  chmod +x "$OUTSIDE/stub/claude"
}
PATH="$OUTSIDE/stub:$PATH"

# KAIZEN rows in the ledger — sessions and escalations the kaizen flow itself wrote. Starts at 1:
# the series fixture above already carries one meta row.
krows() { jq -s '[.[] | select(.phase == "KAIZEN")] | length' "$LEDGER"; }

echo "== gate: verdict pending =="
# A stale verdict for an OLDER kit sha, with a complete born plan beside it: a gate blind to
# kit_sha_judged would accept this one and pass — the exact sabotage the KAIZEN_gate_blind
# mutation applies. The honest gate must keep asking for the CURRENT sha.
OLD="$FIX/docs/handoffs/20250101-old"
mkdir -p "$OLD"
cat > "$OLD/05-verdict.md" <<'EOF'
---
verdict: melhorou
kit_sha_judged: 0000000
date: 2025-01-01
---
# Verdict for an older kit change
EOF
cat > "$OLD/00-missao.md" <<'EOF'
---
missao: 20250101-old
aprovacao:
---
# Older mission
EOF
: > "$OLD/01-plano.md"
: > "$OLD/checkpoint.md"
git add -A && git commit -qm "chore: stale verdict for an older kit sha"

dead_stub
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "with no verdict for the CURRENT sha the command blocks (rc 3)" "3" "$rc"
assert_eq "and the reason names the sha it is waiting for" "yes" \
  "$(grep -q 'no verdict for kit aaa1111' <<< "$out" && echo yes || echo no)"
assert_eq "the two dead sessions and the escalation reached the ledger as KAIZEN rows" \
  "4" "$(krows)"

echo "== jidoka: verdict piorou stops the line =="
loud_stub
VDIR="$FIX/docs/handoffs/20260815-kaizen-verdict"
mkdir -p "$VDIR"
cat > "$VDIR/05-verdict.md" <<'EOF'
---
verdict: piorou
kit_sha_judged: aaa1111
date: 2026-08-15
---
# The previous change made autonomy worse
EOF
git add -A && git commit -qm "chore: piorou verdict for the current sha"
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "verdict piorou stops the line (rc 3)" "3" "$rc"
assert_eq "without opening any session" "$before_rows" "$(krows)"
assert_eq "and says the previous change made autonomy worse" "1" \
  "$(grep -c 'made autonomy WORSE' <<< "$out")"

echo "== gate: verdict without the born plan =="
sed -i 's/^verdict: piorou$/verdict: melhorou/' "$VDIR/05-verdict.md"
git add -A && git commit -qm "chore: verdict flips to melhorou"
dead_stub
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "a verdict without the born plan beside it blocks (rc 3)" "3" "$rc"
assert_eq "naming the missing artifact" "yes" \
  "$(grep -q '00-missao\.md is missing' <<< "$out" && echo yes || echo no)"

echo "== gate: born plan with empty aprovacao passes =="
loud_stub
cat > "$VDIR/00-missao.md" <<'EOF'
---
missao: 20260815-kaizen-verdict
aprovacao:
titulo: next kit batch
---
# Mission born from the kaizen loop
EOF
: > "$VDIR/01-plano.md"
: > "$VDIR/checkpoint.md"
git add -A && git commit -qm "chore: born plan beside the verdict"
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "verdict + born plan with empty aprovacao passes (rc 0)" "0" "$rc"
assert_eq "spending no session (already judged, idempotent)" "$before_rows" "$(krows)"
assert_eq "and hands the plan to the human" "1" "$(grep -c "fill 'aprovacao:'" <<< "$out")"

echo "== gate: the plan never approves itself =="
dead_stub
sed -i 's/^aprovacao:$/aprovacao: auto/' "$VDIR/00-missao.md"
git add -A && git commit -qm "chore: the born plan tries to approve itself"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "a born plan that approves itself is refused (rc 3)" "3" "$rc"
assert_eq "naming the self-approval" "yes" \
  "$(grep -q "aprovacao: auto" <<< "$out" && echo yes || echo no)"

echo "== dry-run projection =="
# The gate is failing at this point (the self-approved plan above), so a real run would open a
# session — the projection must not: no claude, no mission directory, no ledger row. The loud
# stub turns any session into a visible ledger row; the row count is the witness.
loud_stub
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen --dry-run 2>&1 )"; rc=$?
assert_eq "kaizen --dry-run exits 0" "0" "$rc"
assert_eq "and prints the KAIZEN boot prompt" "yes" \
  "$(grep -q 'DRY RUN: phase KAIZEN' <<< "$out" && echo yes || echo no)"
assert_eq "which cites the series command as the source of truth" "yes" \
  "$(grep -q 'kaizen --series' <<< "$out" && echo yes || echo no)"
assert_eq "driven by the sdd-kaizen agent" "yes" \
  "$(grep -q 'sdd-kaizen' <<< "$out" && echo yes || echo no)"
assert_eq "the projection creates no mission directory" "no" \
  "$([ -d "$FIX/docs/handoffs/$(date +%Y%m%d)-kaizen" ] && echo yes || echo no)"
assert_eq "and writes no ledger row" "$before_rows" "$(krows)"

echo "== kit-repo guard =="
# KAIZEN plans the KIT's next mission. Run from a target project it would judge the kit but plan
# in the wrong repo — the guard refuses before load-bearing work, naming where to go.
TGT="$OUTSIDE/target"
mkdir -p "$TGT"
( cd "$TGT" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && echo "t" > t.txt && git add -A && git commit -qm "init" \
  && "$SDD" install >/dev/null 2>&1 )
cat > "$TGT/.sdd/config.sh" <<'EOF'
PROJECT_NAME="target"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF
out="$( cd "$TGT" && "$SDD" kaizen 2>&1 )"; rc=$?
assert_eq "sdd kaizen refuses to run outside the kit repo (rc 1)" "1" "$rc"
assert_eq "and points at the kit repo" "yes" \
  "$(grep -q 'run it in the kit repo' <<< "$out" && echo yes || echo no)"

echo "== hygiene =="
assert_eq "the fixture kit tree ends clean" "" "$(git -C "$FIX" status --porcelain)"
assert_eq "the ledger is never tracked by the fixture kit" "0" \
  "$(git -C "$FIX" ls-files | grep -c 'autonomy-log\.jsonl')"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the series tells the truth and the gate holds\n'; exit 0; fi
printf '%d kaizen check(s) failed\n' "$fails" >&2
exit 1
