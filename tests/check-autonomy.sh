#!/usr/bin/env bash
# Sensor for the autonomy ledger — the series the kaizen judge (I13.3) will read.
#
# The ledger records FACTS, never a score, and its value is entirely in being trustworthy: a row
# that should not exist (a projection, a fixture) poisons a metric that decides whether the kit
# graduates. So the assertions here are mostly about what must NOT be written.
#
# Hermetic: `claude` is stubbed and SDD_STATE_DIR points at a scratch directory of this test's own
# — `gh` is never called on the paths this test exercises. Runs INSIDE mutants (unlike
# check-preflight), because the mutations that sabotage the writer have to kill the sandbox suite —
# guarded, they would score a point for nothing.
#
# Usage: tests/check-autonomy.sh   (exit 0 = the ledger tells the truth)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-autonomy-XXXXXX")"
MISSION="20260101-fixture"
fails=0

# Everything this file writes that is NOT part of the target repo lives here, deliberately OUTSIDE
# $FIX — which becomes the fixture's git working tree below. The instrument must not end up inside
# the thing it measures: the moving stub further down runs `git add -A`, so a state directory under
# $FIX would get the ledger COMMITTED into the repo under test, `state_fingerprint` (git HEAD +
# mission dir + checkpoint md5) could then move because the LEDGER was written rather than because
# the session did anything, and the tree this file asserts about would end dirty. It is also the
# exact configuration the ledger's own design forbids (see the comment above autonomy_log_path in
# bin/sdd, and `SDD_STATE_DIR` in config/schema.md). Same choice, same reason, as check-gates.sh
# and check-dry-run.sh — which is why the two assertions at the end of this file pin it.
OUTSIDE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-autonomy-outside-XXXXXX")"
trap 'rm -rf "$FIX" "$OUTSIDE"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi }

# num_before <text> <literal-that-follows-the-number, as an ERE> -> the integer, or "" if absent.
# One `grep -m1 -oE`, nothing piped after it: the match is trimmed with bash's own `${m%% *}`
# instead of a second process. That sidesteps the pipefail/SIGPIPE trap this repo warns about
# (`printf | grep -q` returns 141 when grep finds a match and closes the pipe before the writer is
# done) — there is no writer here for a downstream reader to cut off.
num_before() {
  local m; m="$(grep -m1 -oE "[0-9]+ $2" <<< "$1")"
  printf '%s' "${m%% *}"
}

# sum_sessions <reader output> -> total of every "N session(s)" occurrence (one per kit_sha row).
# A single awk process reading the whole herestring, same reason as num_before: no pipe, no
# early-exiting reader on the other end of one.
sum_sessions() {
  awk '{ while (match($0, /[0-9]+ session\(s\)/)) {
           s += substr($0, RSTART, RLENGTH) + 0
           $0 = substr($0, RSTART + RLENGTH)
         } }
       END { print s + 0 }' <<< "$1"
}

# sum_escalations <reader output> -> total of every "  <kit_sha>  <kind>: N" line. The leading
# kit_sha is optional in this pattern ON PURPOSE: this helper's job is to COUNT rows for the
# bucket sum, and pinning the shape belongs to the axis assertions further down — a helper that
# did both would report "0 escalations" on a shape change and blame the wrong bucket. Either way
# the pattern stays unique to escalation lines: the per-kit_sha session lines use "·" separators
# and end in "US$ <n>", never in "<word>: <digits>".
sum_escalations() {
  awk '/^  ([^ ]+  )?[A-Za-z][A-Za-z0-9_-]*: [0-9]+$/ { split($0, a, ": "); s += a[2] } END { print s + 0 }' \
    <<< "$1"
}

# assert_bucket_sum <description> <reader output>
# Every row lands in exactly one of four buckets: comparable session, non-comparable session,
# escalation, unrecognized. If the filter drops a row (finding 3) or double-counts one, this sum
# drifts from the header total — an anti-vacuity check a broken filter cannot pass by accident,
# unlike any single count in isolation.
assert_bucket_sum() {
  local desc="$1" out="$2" total comparable noncomp escal stray sum
  total="$(num_before "$out" 'row\(s\)')"; total="${total:-0}"
  comparable="$(sum_sessions "$out")"
  noncomp="$(num_before "$out" 'non-comparable')"; noncomp="${noncomp:-0}"
  escal="$(sum_escalations "$out")"
  stray="$(num_before "$out" 'unrecognized')"; stray="${stray:-0}"
  sum=$((comparable + noncomp + escal + stray))
  assert_eq "$desc" "$total" "$sum"
}

# The ledger under test. Never the real one: the export in run-all.sh already redirects every
# test, and this makes THIS file independent of that export holding.
export SDD_STATE_DIR="$OUTSIDE/state"
LEDGER="$SDD_STATE_DIR/autonomy-log.jsonl"

# rows <jq-filter> — applies the filter to every row and prints one result per line.
# -r (not -c): a compact string result still comes back quoted, and every string assertion below
# compares against the bare value.
rows() { jq -cr "$1" "$LEDGER" 2>/dev/null; }
# `grep -c .` on an EXISTING but empty file prints "0" and still exits 1 (no match), which would
# also fire the `||` fallback and double the output to "0\n0" — an explicit branch avoids that.
nrows() { [ -f "$LEDGER" ] || { echo 0; return; }; grep -c . "$LEDGER" 2>/dev/null; }

echo "== fixture at $FIX =="
cd "$FIX" || exit 1

# No test spends tokens or network. In this task nothing should reach claude at all: the blocked
# escalation returns before any session. The stub makes that a loud failure instead of a bill.
mkdir -p "$OUTSIDE/stub"
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$OUTSIDE/stub/claude"
PATH="$OUTSIDE/stub:$PATH"

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
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
git add -A && git commit -qm "chore: pending increment"

"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "two dead sessions escalate with rc 3" "3" "$rc"
assert_eq "two session rows plus one escalation" "3" "$(nrows)"
assert_eq "every row is valid JSON" "1" "$(jq -se . "$LEDGER" >/dev/null 2>&1 && echo 1 || echo 0)"

assert_eq "the first row is a session" "session" "$(jq -r -s '.[0].event' "$LEDGER")"
assert_eq "the first session is not a retry" "false" "$(jq -r -s '.[0].auto_retry' "$LEDGER")"
assert_eq "the second row is the retry" "true" "$(jq -r -s '.[1].auto_retry' "$LEDGER")"
# On an in-loop retry, `run_phase` is called with `--resume … --fork-session` and WITHOUT
# `--session-id`: the runner never learns the fork's own id, so the retry row has to carry the
# PARENT session's id — the two rows share one `session` value. Reverting
# `LAST_PHASE_SID="${resume_sid:-$sid}"` to `"$sid"` (the ghost-UUID bug fixed in `032c09c`) makes
# the retry row invent an id nobody ever gave `claude`, and leaves the suite green without this.
assert_eq "the two session rows share one session id (the retry has no fork id of its own)" \
  "true" "$(jq -s '.[1].session == .[0].session' "$LEDGER")"
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

# --- sdd retry is a human-forced session, and that is a first-class signal ---
# It is literally the rubric's "refez": the human looked at the result and pushed the phase
# again. Leaving it out of the ledger would hide the strongest friction signal there is.
echo "== retry invocation =="
: > "$LEDGER"
"$SDD" retry "$MISSION" >/dev/null 2>&1
assert_eq "sdd retry writes one session row" "1" "$(nrows)"
assert_eq "and marks itself as a retry invocation" "retry" "$(rows '.invocation')"
assert_eq "with its own run_id" "true" "$(rows '(.run_id | length) > 0')"

# --- moved: true on a real change, false once nothing changes --------------
# Task 2 review measured this by hand: mutating `[ "$before" != "$after" ] && moved="true"` into a
# no-op left the whole suite GREEN, because every `claude` stub above is dead (rc 1) or dry — none
# of them ever touches the fixture repo, so `moved` was always "false" and nothing distinguished
# it from the mutant. `moved` is the headline number of the metric now (waste = sessions that did
# NOT move the disk), so this hole matters: a regression here both escalates BLOCKED on phases
# that are genuinely progressing and records every session as waste, with the suite still green.
#
# The stub is a SEPARATE PROCESS on every invocation of `claude`, so a shell variable set inside it
# would not survive to the next call — a marker FILE in the fixture counts invocations instead. On
# the first call it makes a real change (a new file) and commits it, which moves `git rev-parse
# HEAD` and therefore `state_fingerprint()`; on every later call it does nothing. No token, no
# network: the stub never shells out to the real `claude`.
echo "== moved: true on a real change, false once nothing changes =="
: > "$LEDGER"
MOVE_MARKER="$FIX/.moved-once"
rm -f "$MOVE_MARKER"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$MOVE_MARKER" ]; then
  : > "$MOVE_MARKER"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: session made a real change"
fi
echo '{}'
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the checkpoint never reaches done, so it still escalates no-progress" "3" "$rc"
assert_eq "three session rows plus one escalation" "4" "$(nrows)"
assert_eq "the first session actually moved the disk" "true" "$(jq -r -s '.[0].moved' "$LEDGER")"
assert_eq "the second session, with nothing left to change, records moved:false" "false" \
  "$(jq -r -s '.[1].moved' "$LEDGER")"
assert_eq "the inline retry (same iteration) also records moved:false" "false" \
  "$(jq -r -s '.[2].moved' "$LEDGER")"
assert_eq "escalates no-progress once the disk stops moving" "no-progress" \
  "$(jq -r -s '.[3].kind' "$LEDGER")"

# --- sdd retry, when it DOES move the disk, records moved:true -------------
# The "== retry invocation ==" block above ran against the DEAD stub (rc 1, never touches the
# fixture repo), so it never exercised `moved` for `cmd_retry` at all. Reusing the moving stub and
# marker file from the scenario above and resetting the marker makes the stub commit again on
# this next invocation — the mutation this catches: replacing `cmd_retry`'s own
# `[ "$before" != "$after" ] && moved="true"` with a no-op leaves the suite green today.
#
# The reset has to be COMMITTED, not just deleted from disk: the marker is already a tracked file
# from the section above, and an uncommitted `rm` followed by the stub recreating it with the same
# (empty) content is a no-op diff from HEAD — `git commit` finds nothing to commit, HEAD does not
# move, and the assertion would fail for a reason that has nothing to do with `cmd_retry`.
echo "== sdd retry that moves the disk records moved:true =="
: > "$LEDGER"
rm -f "$MOVE_MARKER"
git -C "$FIX" add -A
git -C "$FIX" commit -qm "chore: reset move marker for the sdd-retry scenario"
"$SDD" retry "$MISSION" >/dev/null 2>&1
assert_eq "sdd retry that changed the disk records moved:true" "true" "$(rows '.moved')"

# --- a kit without .git warns ONCE, not once per row ------------------------
# `autonomy_kit_stamp` used to be read as `stamp="$(autonomy_kit_stamp)"`, so the whole body ran in
# a subshell: its `AUTONOMY_SHA_WARNED=1` died with the command substitution, the flag was back to 0
# on the next call, and the warning its own comment calls "one-shot per process" fired once per
# ledger row. Nothing in the repo measured it, which is exactly why it survived review — the fix is
# publishing AUTONOMY_KIT_STAMP as a global instead of printing it.
#
# A kit copy WITHOUT .git is the only way to reach that branch at all: the real kit is a checkout.
# The copy takes the same set as check-mutation.sh's sandbox() — everything `sdd run` reads from
# $SDD_HOME and nothing more — and it lives in $OUTSIDE, since a kit copy under $FIX would be one
# more instrument inside the repo under test.
echo "== a kit that is not a git checkout warns once, not once per row =="
: > "$LEDGER"
KIT="$OUTSIDE/kit"
mkdir -p "$KIT"
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$KIT/"
# Back to the dead stub: two sessions that change nothing, so the run writes three rows (two
# sessions plus the no-progress escalation) and the warning gets three chances to repeat.
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
# stderr only: `2>&1 >/dev/null` dups stderr onto the capture pipe FIRST, then sends stdout away.
err="$( "$KIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
assert_eq "three rows were written, so the warning had three chances" "3" "$(nrows)"
assert_eq "a kit with no .git yields kit_sha:null on every row" "true" \
  "$(jq -s 'all(.kit_sha == null)' "$LEDGER")"
assert_eq "and the warning appeared exactly once" "1" \
  "$(grep -c 'is not a git checkout' <<< "$err")"

# --- the self-degradation review→draft leaves a trace -----------------------
# PUBLISH_ON_REVIEW_BLOCKED=draft is the runner deciding, ALONE, to stop reviewing and publish a
# draft PR anyway — the most interesting autonomy event a mission can produce. Until this
# assertion existed the branch's `force_phase="PR"; continue` jumped over BOTH writers (the
# journal and the ledger), so the whole history of the event was a run of failing REVIEW sessions
# followed by a PR phase, with nothing anywhere saying why. The judge reads the series; this
# event was invisible to it.
#
# Reaching the branch is the expensive part of the fixture: the mission has to actually BE in
# REVIEW, so PLAN, TICKET, EXEC and QA must all pass first. And the REVIEW session has to MOVE the
# disk — with a dead stub the no-progress escalation fires on the inline retry and the budget
# branch is never reached at all.
echo "== the self-degradation review→draft writes exactly one row =="
: > "$LEDGER"
cat >> .sdd/config.sh <<'EOF'
REVIEW_MAX_ITER=1
PUBLISH_ON_REVIEW_BLOCKED="draft"
EOF
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: exec handoff and a skipped QA"
# The hash goes into the checkpoint only AFTER its own commit exists, and a second commit follows:
# gate_EXEC demands the commit be an ANCESTOR of HEAD, not merely an object in the database.
DONE_HASH="$(git rev-parse --short HEAD)"
cat > "$MDIR/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | \`true\` → 0 | done | $DONE_HASH |
EOF
git add -A && git commit -qm "chore: the increment is done"

# Moves the disk on EVERY call — the REPETITION regime, and the whole reason the F1 increment
# exists. This stub used to move on the first call only, which held the runner to a single lap of
# the draft branch; "the degradation wrote exactly one row" below was then a property of the
# FIXTURE, not of the code. Under a stub that always moves, the run goes REVIEW→PR→REVIEW with the
# REVIEW budget still blown, re-enters the branch on every lap, and the pre-F1 runner wrote one row
# per lap: 3 rows for 1 degradation, against the "exactly one" of the mission's metric 3. It is the
# THIRD vacuity of this mission — after I1's shared rc 3 and I2's never-reached draft branch — and
# the reason a fixture regime is never allowed to stand in for the property being asserted.
DRAFT_LAPS="$OUTSIDE/draft-laps"
: > "$DRAFT_LAPS"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
echo x >> "$DRAFT_LAPS"
wc -l < "$DRAFT_LAPS" > "$FIX/churn.txt"
git -C "$FIX" add -A
git -C "$FIX" commit -qm "chore: the session changed something"
echo '{}'
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

# stderr only (`2>&1 >/dev/null`), the same idiom the kit-stamp block above uses: the warn line is
# the runner announcing out loud that it entered the branch, and counting it is what proves the
# regime. It is deliberately OUTSIDE the one-shot guard in bin/sdd — the runner really is jumping
# to PR on this lap, and an assertion over the writers must not be its own witness.
err="$( "$SDD" run "$MISSION" 2>&1 >/dev/null )"; rc=$?
assert_eq "the run still ends in an escalation, whichever path took it there" "3" "$rc"
# ANTI-VACUITY OF THE REGIME: without this, a future change that quiets the loop back down to one
# lap would make the cardinality assertion below pass for the old reason — the fixture — and the
# F1 sensor would silently stop measuring anything, exactly like the assertion it replaces.
laps="$(grep -c 'moving on to PR in draft mode' <<< "$err")"
assert_eq "the fixture is in the repeating regime: the draft branch was entered more than once" \
  "true" "$( [ "${laps:-0}" -ge 2 ] && echo true || echo false )"
# ANTI-VACUITY, and the lesson I1 paid for: rc 3 is shared by all three escalation paths, so `rc 3`
# alone would keep this whole block green on a fixture that never reached the draft branch at all.
# A PR session with the REVIEW gate still failing can only exist BECAUSE the runner degraded —
# `current_phase` would hand back REVIEW forever otherwise. This assertion is what says the
# assertions below are pointed at the right branch, and it holds with or without the writer.
assert_eq "the fixture really did reach the draft branch: a PR session with REVIEW still failing" \
  "true" "$(jq -s '[.[] | select(.event == "session" and .phase == "PR")] | length > 0' "$LEDGER")"
assert_eq "and no REVIEW gate ever passed, so nothing but the degradation could have moved it" \
  "0" "$(jq -s '[.[] | select(.phase == "REVIEW" and .gate == "pass")] | length' "$LEDGER")"
# THE METRIC OF F1, and now a property of the code rather than of the stub: the runner lowered its
# own bar ONCE in this run and the ledger says so once, however many laps the REVIEW→PR→REVIEW loop
# takes afterwards with the budget still blown. The laps are a defect of their own — the loop half
# — and it stays in TODO.md; what this asserts is the RECORD half.
assert_eq "the degradation wrote exactly one row, however many laps the loop took" "1" \
  "$(jq -s '[.[] | select(.event == "degraded")] | length' "$LEDGER")"
# `degraded` and not `blocked`: `blocked` means the line STOPPED and the runner returns 3. Here
# the run went ON, to PR. Reusing `blocked` would have been cheaper — it inherits the kit_sha axis
# and the series aggregation for free — but it would record "stopped" for a run that continued,
# and the ledger exists to record fact.
assert_eq "the event says the run degraded, not that it stopped" "degraded" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].event' "$LEDGER")"
assert_eq "kind names the degradation by enum, not by prose" "review-to-draft" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].kind' "$LEDGER")"
assert_eq "the phase that degraded" "REVIEW" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].phase' "$LEDGER")"
assert_eq "and the mission it happened in" "$MISSION" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].mission' "$LEDGER")"
# The kit stamp is what puts the row on the version axis the whole ledger exists to measure. A
# writer that forgot it would still look fine in `sdd autonomy` and vanish from the series.
assert_eq "the row carries the kit stamp, so it lands on the version axis" "true" \
  "$(jq -s '[.[] | select(.event == "degraded")][0] | has("kit_sha") and has("kit_dirty")' "$LEDGER")"
assert_eq "it shares the run_id of the run that produced it" "true" \
  "$(jq -s '([.[] | select(.event == "degraded")][0].run_id) == (.[0].run_id)' "$LEDGER")"
# Same refusal as autonomy_blocked_row: a degradation spends no session of its own, so a 0 in the
# session fields would enter the judge's arithmetic as if it had.
assert_eq "no session fields on a degradation" "true" \
  "$(jq -s '[.[] | select(.event == "degraded")][0]
            | has("rc") == false and has("cost_usd") == false and has("moved") == false' "$LEDGER")"
assert_eq "the gate reason that triggered it rides along" "true" \
  "$(jq -s '([.[] | select(.event == "degraded")][0].gate_why | length) > 0' "$LEDGER")"
# The journal is the human's trail and the ledger is the judge's; the `continue` skipped BOTH, so
# both are asserted here.
assert_eq "the pipeline journal records it too" "1" \
  "$(grep -c 'DEGRADED' "$FIX/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || echo 0)"
# The human reader must not file a row the runner itself wrote under "unrecognized": that would
# just move the blind spot from the judge to the human.
#
# The kit stamp is NORMALISED first, and only for the reader assertions below. Since I3 the
# escalation table lives on the kit_sha axis and drops non-comparable rows, and the stamp these
# rows carry is whatever the kit checkout happened to be at test time: a dirty working tree (any
# EXEC session) or the no-.git copy check-mutation.sh sandboxes into make every row here
# non-comparable, and the block would pass in CI and fail on the developer's machine, or the other
# way round. The rows stay exactly as the RUNNER wrote them in every other respect — that they
# carry a stamp at all is asserted above, against the untouched ledger.
jq -c '.kit_sha = "deadbee" | .kit_dirty = false' "$LEDGER" > "$LEDGER.norm" && mv "$LEDGER.norm" "$LEDGER"
out="$( "$SDD" autonomy 2>&1 )"
assert_eq "the human reader does not call it unrecognized" "0" "$(grep -c 'unrecognized' <<< "$out")"
assert_eq "it is counted as an escalation, by its kind" "1" \
  "$(grep -c 'review-to-draft: 1' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (a ledger with a degradation)" "$out"
# The other half of metric 3: the judge has to read the same single degradation the human does.
# One instrument counting 1 while the other counts 3 is the divergence I3 closed for the axis —
# cardinality is the same failure one field over, so both readers are asserted, not just one.
series="$( "$SDD" kaizen --series 2>/dev/null )"
assert_eq "and the judge counts the same one, not one per lap" "1" \
  "$(jq -r '.latest.escalations["review-to-draft"] // 0' <<< "$series")"
assert_eq "with nothing pushed into the unrecognized bucket to get there" "0" \
  "$(jq -r '.excluded.unrecognized' <<< "$series")"

# --- the reader ------------------------------------------------------------
# Fixture ledger written by hand: this is OUR format, so there is no third-party source to copy
# from (the provenance rule covers skill output). Every row here exists to prove one refusal.
echo "== reader =="
mkdir -p "$OUTSIDE/read"
cat > "$OUTSIDE/read/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":3,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":4,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"gate":"fail","gate_why":"old schema, no moved"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/read" "$SDD" autonomy 2>&1 )"; rc=$?

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
# The four buckets (2 comparable, 2 non-comparable, 1 escalation, 0 unrecognized) must sum to the
# 5 rows the header says it read.
assert_bucket_sum "the four buckets sum to the header total (mixed ledger)" "$out"

# --- the reader gives a full accounting, never a silent gap --------------------------------------
# Two findings from review, one root cause: a bucket the reader does not name is a bucket that can
# vanish with no trace (finding 3 — the reviewer's ledger with no `event` key printed nothing and
# exited 0). The fix makes every row land in one of four buckets and names each non-empty one.

# Only escalations, zero comparable sessions: the table must not go blank. Blank reads as "checked,
# found nothing" — the same vacuity as the empty-ledger case below, just one layer deeper.
echo "== reader: only escalations, no comparable sessions =="
mkdir -p "$OUTSIDE/onlyesc"
cat > "$OUTSIDE/onlyesc/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/onlyesc" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (escalations are still data)" "0" "$rc"
assert_eq "says there are no comparable sessions, in place of the table" "1" \
  "$(grep -c 'no comparable sessions' <<< "$out")"
assert_eq "and never prints a percentage when there is nothing to compute one over" "0" \
  "$(grep -c '%' <<< "$out")"
assert_eq "the escalations are still both named" "1" "$(grep -c 'no-progress: 1' <<< "$out")"
assert_eq "the second kind too" "1" "$(grep -c 'increment-blocked: 1' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (escalations only)" "$out"

# --- the two readers of the ledger agree on the axis -------------------------
# `sdd autonomy` (the human's window) and `sdd kaizen --series` (the judge's source of truth) read
# the SAME file. The series has always sliced escalations INSIDE a kit_sha group; this reader
# grouped them by `.kind` over the whole file, with no version axis and no comparability filter.
# A human reading the table next to a verdict saw different escalation counts for the same period
# with nothing explaining the divergence — and the kit version is precisely the axis the ledger
# exists to measure, so the divergence corrodes trust in the instrument the whole loop depends on.
echo "== reader: escalations carry the kit_sha axis =="
mkdir -p "$OUTSIDE/escaxis"
cat > "$OUTSIDE/escaxis/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"blocked","kind":"no-progress","run_id":"r2","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"degraded","kind":"review-to-draft","run_id":"r2","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"REVIEW","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"blocked","kind":"no-progress","run_id":"r3","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:05:00-03:00","event":"blocked","kind":"no-progress","run_id":"r4","invocation":"run","kit_sha":null,"kit_dirty":null,"project":"p1","repo":"/p1","mission":"m4","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/escaxis" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (a ledger of escalations across two kit versions is data)" "0" "$rc"

# The same kind under two kit versions is two facts, not one number: summing them is exactly the
# arithmetic that makes "did the change help?" unanswerable.
assert_eq "no-progress under the version it happened in" "1" \
  "$(grep -c '^  aaaaaaa  no-progress: 1$' <<< "$out")"
assert_eq "and the one under the other version, counted apart" "1" \
  "$(grep -c '^  bbbbbbb  no-progress: 1$' <<< "$out")"
assert_eq "a second kind stays with its own version too" "1" \
  "$(grep -c '^  aaaaaaa  increment-blocked: 1$' <<< "$out")"
assert_eq "a degradation is an escalation on the axis, like any other" "1" \
  "$(grep -c '^  bbbbbbb  review-to-draft: 1$' <<< "$out")"
# Anti-vacuity: an escalation line with no version in front of it IS the old axis-less shape, so
# asserting its absence is what makes the four assertions above impossible to satisfy by accident.
assert_eq "no escalation line is printed without a version" "0" \
  "$(grep -cE '^  [A-Za-z][A-Za-z0-9_-]*: [0-9]+$' <<< "$out")"
# Non-comparable escalations are excluded and COUNTED, the same refusal the session block already
# makes: a dirty kit and a null sha cannot be attributed to a version, and a row silently summed
# into one is worse than a row excluded out loud.
assert_eq "the dirty kit and the null sha are excluded, not summed into a version" "1" \
  "$(grep -c '2 non-comparable' <<< "$out")"
assert_bucket_sum "the buckets sum to the header total (escalations on two versions)" "$out"

# The increment's metric, stated as the two instruments agreeing — compared as DATA, kind by kind,
# not as prose. Whatever `sdd kaizen --series` reports for the latest kit version, the human table
# has to report the same. A divergence fails here even when each side looks plausible alone, which
# is the only way to catch the two readers drifting apart again.
series="$( SDD_STATE_DIR="$OUTSIDE/escaxis" "$SDD" kaizen --series 2>/dev/null )"
latest_sha="$(jq -r '.latest.kit_sha' <<< "$series")"
assert_eq "the series and the reader are talking about the same latest version" "bbbbbbb" "$latest_sha"
series_esc="$(jq -r '.latest.escalations | to_entries | sort_by(.key)
                     | map("\(.key): \(.value)") | join("\n")' <<< "$series")"
# $1 is the sha, $2 the "<kind>:" token and $3 the count; the session table lines have "session(s)"
# in $3, so the numeric guard keeps them out without a second pattern to maintain.
reader_esc="$(awk -v sha="$latest_sha" '$1 == sha && $3 ~ /^[0-9]+$/ { print $2, $3 }' <<< "$out" | sort)"
assert_eq "the human reader and the judge count the latest version's escalations alike" \
  "$series_esc" "$reader_esc"

# A row with no `event` at all, or an event nobody recognizes yet: the reviewer's exact repro. It
# must be counted, not merely fail to crash.
echo "== reader: unrecognized row =="
mkdir -p "$OUTSIDE/stray"
printf '{"v":1,"ts":"2026-08-15T10:00:00-03:00"}\n' > "$OUTSIDE/stray/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/stray" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (an unrecognized row is not a malformed one)" "0" "$rc"
assert_eq "says there are no comparable sessions" "1" "$(grep -c 'no comparable sessions' <<< "$out")"
assert_eq "and says how many rows it could not classify" "1" \
  "$(grep -c '1 unrecognized' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (one unrecognized row)" "$out"

# A row that is syntactically valid JSON but the wrong SHAPE (a bare array, not an object) cannot
# be classified either — indexing it is a jq runtime error, not a false comparison. Before the fix
# this leaked jq's own exit code (the reviewer saw rc 5); now it dies through the same rc-1
# convention as every other refusal in this command.
echo "== reader: valid JSON, wrong shape =="
mkdir -p "$OUTSIDE/shape"
printf '[1,2,3]\n' > "$OUTSIDE/shape/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/shape" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a shape error dies with rc 1, not jq's own exit code" "1" "$rc"
assert_eq "and the die message names the file" "1" \
  "$(grep -c "error:.*$OUTSIDE/shape/autonomy-log.jsonl" <<< "$out")"

# An empty ledger is NOT 0% waste. Zeros that look like excellence are the vacuity the whole kit
# exists to kill.
mkdir -p "$OUTSIDE/empty"
out="$( SDD_STATE_DIR="$OUTSIDE/empty" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "no ledger yet exits 1" "1" "$rc"
assert_eq "and says 'no data' instead of printing zeros" "1" "$(grep -c 'no data' <<< "$out")"
assert_eq "and never prints a percentage" "0" "$(grep -c '%' <<< "$out")"

# A malformed row dies loudly: skipping it in silence is how the judge ends up reading a subset
# and calling it the whole history.
mkdir -p "$OUTSIDE/bad"
printf '{"v":1,"event":"session"\n' > "$OUTSIDE/bad/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/bad" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a malformed row fails loudly" "1" "$rc"

# --- the instrument never lands inside the thing it measures ----------------
# Pins the $OUTSIDE decision at the top of this file. If the ledger, a reader fixture or the kit
# copy ever moves back under $FIX, the moving stub's `git add -A` commits it into the repo under
# test: `state_fingerprint` reads git HEAD, so the LEDGER being written could move the fingerprint
# by itself and the waste metric would start measuring its own instrument. The second assertion is
# the general form — any stray file this test leaves in the target repo fails it, including ones
# nobody has thought of yet.
assert_eq "the ledger is never tracked by the repo under test" "0" \
  "$(git -C "$FIX" ls-files | grep -c 'autonomy-log\.jsonl')"
assert_eq "the repo under test ends with a clean tree" "" \
  "$(git -C "$FIX" status --porcelain)"

# sdd health check 5 fails on a subcommand missing from the help — assert it here too, so the
# reason is visible at the point of change instead of three files away.
assert_eq "the subcommand is in sdd help" "1" "$( "$SDD" help 2>&1 | grep -c 'sdd autonomy' )"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the ledger records facts and stays quiet on projections\n'; exit 0; fi
printf '%d autonomy check(s) failed\n' "$fails" >&2
exit 1
