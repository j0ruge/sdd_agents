#!/usr/bin/env bash
# Sensor for the autonomy ledger — the series the kaizen judge (I13.3) will read.
#
# The ledger records FACTS, never a score, and its value is entirely in being trustworthy: a row
# that should not exist (a projection, a fixture) poisons a metric that decides whether the kit
# graduates. So the assertions here are mostly about what must NOT be written.
#
# Hermetic: `claude` is stubbed and SDD_STATE_DIR points inside the fixture — `gh` is never called
# on the paths this test exercises. Runs INSIDE mutants (unlike check-preflight), because the
# mutations that sabotage the writer have to kill the sandbox suite — guarded, they would score a
# point for nothing.
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

# sum_escalations <reader output> -> total of every "  <kind>: N" line. That exact shape (two
# leading spaces, a bare word, ": ", digits, end of line) is unique to escalation lines — the
# per-kit_sha table lines use "·" separators and never end in a bare number.
sum_escalations() {
  awk '/^  [A-Za-z][A-Za-z0-9_-]*: [0-9]+$/ { split($0, a, ": "); s += a[2] } END { print s + 0 }' \
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
export SDD_STATE_DIR="$FIX/state"
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
cat > "$FIX/.stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$MOVE_MARKER" ]; then
  : > "$MOVE_MARKER"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: session made a real change"
fi
echo '{}'
exit 0
STUB
chmod +x "$FIX/.stub/claude"

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
mkdir -p "$FIX/onlyesc"
cat > "$FIX/onlyesc/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$FIX/onlyesc" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (escalations are still data)" "0" "$rc"
assert_eq "says there are no comparable sessions, in place of the table" "1" \
  "$(grep -c 'no comparable sessions' <<< "$out")"
assert_eq "and never prints a percentage when there is nothing to compute one over" "0" \
  "$(grep -c '%' <<< "$out")"
assert_eq "the escalations are still both named" "1" "$(grep -c 'no-progress: 1' <<< "$out")"
assert_eq "the second kind too" "1" "$(grep -c 'increment-blocked: 1' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (escalations only)" "$out"

# A row with no `event` at all, or an event nobody recognizes yet: the reviewer's exact repro. It
# must be counted, not merely fail to crash.
echo "== reader: unrecognized row =="
mkdir -p "$FIX/stray"
printf '{"v":1,"ts":"2026-08-15T10:00:00-03:00"}\n' > "$FIX/stray/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$FIX/stray" "$SDD" autonomy 2>&1 )"; rc=$?
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
mkdir -p "$FIX/shape"
printf '[1,2,3]\n' > "$FIX/shape/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$FIX/shape" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a shape error dies with rc 1, not jq's own exit code" "1" "$rc"
assert_eq "and the die message names the file" "1" \
  "$(grep -c "error:.*$FIX/shape/autonomy-log.jsonl" <<< "$out")"

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

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the ledger records facts and stays quiet on projections\n'; exit 0; fi
printf '%d autonomy check(s) failed\n' "$fails" >&2
exit 1
