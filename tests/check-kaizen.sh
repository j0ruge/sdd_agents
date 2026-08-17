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
# from a sandbox git repository the fixture rows name. The ledger file is global — one per machine
# — but the READING is per repo, so a series read from nowhere is empty by construction and the
# fixtures have to stand somewhere real. Runs INSIDE mutants: the mutations that sabotage the
# rubric or the gate have to kill the sandbox suite through this file.
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

# The kit-shaped fixture repo the gate section builds out below is born HERE, as a bare `git
# init`, because the readers filter the ledger by the repo they are standing in: every fixture row
# has to name a repo that exists, and every series read has to happen from inside it. One repo for
# both halves and not two — the gate section reads a ledger written by the series section, so a
# second path would leave the gate looking at an empty series and blame the gate for it.
FIX="$OUTSIDE/fix"
mkdir -p "$FIX"
( cd "$FIX" && git init -q -b main )
# Ask git, never the string this file built the directory from: TMPDIR may be a symlink, and what
# the runner writes into a row is whatever `git rev-parse --show-toplevel` returns.
FIXROOT="$( cd "$FIX" && git rev-parse --show-toplevel )"
# Every fixture ledger below still spells the repo `/p1` (and `/kit` for the meta row), because a
# 400-character JSON line is hard enough to read without an absolute temp path in it. localize()
# is the one rewrite from that shorthand to the real path, applied as each ledger is written.
localize() { sed -e "s|\"repo\":\"/p1\"|\"repo\":\"$FIXROOT\"|g" \
                 -e "s|\"repo\":\"/kit\"|\"repo\":\"$FIXROOT\"|g"; }

# field <jq-filter> — reads the captured series output. -r for bare values.
SERIES_OUT=""
field() { jq -r "$1" <<< "$SERIES_OUT"; }

# =============================================================================
# adr 0003 — the axis the judge stands on
# =============================================================================
# ADR 0001 says WHERE the judgement lives (runner derives, agent interprets); 0003 says what the
# axis MEANS — that evidence for a verdict comes from real target repos, that `kit_sha` stays the
# axis, and that the `>= 3` floor does not loosen. The runner's floor and its structural
# `indeterminado` are that decision compiled into code, so both assertions here are about the pair
# staying together.
#
# The second one is the load-bearing half: a decision record no code names is a label, and a label
# is exactly what this kit refuses to accept as evidence. Sabotage it (mut_KAIZEN_adr_0003_orphan
# strips the citation from the runner) and the suite has to die — that is what separates an ADR the
# implementation stands on from a markdown file nobody reads.
echo "== adr 0003 =="

ADR3="$ROOT/docs/adr/0003-judge-axis-evidence-from-target-repos.md"
# One `grep -c` over five DISTINCT line patterns, so the count is the number of format elements
# present: title in `# NNNN — ` form, the dated status line, and the three sections 0001/0002 ship.
# A file that exists but drifted from the format scores below 5 and is not accepted.
adr3_shape="0"
[ -f "$ADR3" ] && adr3_shape="$(grep -c \
  -e '^# 0003 — ' \
  -e '^Date: .* · Status: accepted$' \
  -e '^## Context$' -e '^## Decision$' -e '^## Consequences$' "$ADR3")"
assert_eq "adr 0003 exists in the shape of 0001/0002 (title, dated status, three sections)" \
  "5" "$adr3_shape"

# Reading a FILE, not a pipe: `grep -q` here cannot hit the SIGPIPE-141 inversion the house rule
# warns about, which only bites when a writer is piped into it.
assert_eq "adr 0003 is named by bin/sdd — a decision record no code cites is a label" "yes" \
  "$(grep -q 'ADR 0003' "$SDD" && echo yes || echo no)"

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
localize > "$LEDGER" <<'EOF'
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
{"v":1,"ts":"2026-08-15T10:10:00-03:00","repo":"/p1"}
{"v":1,"ts":"2026-08-15T10:10:30-03:00"}
{"v":1,"ts":"2026-08-15T10:11:00-03:00","event":"session","run_id":"r8","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"sdd_agents","repo":"/kit","mission":"20260815-kaizen","phase":"KAIZEN","step":"KAIZEN","agent":"sdd-kaizen","model":"opus","attempt":1,"auto_retry":false,"session":"s8","rc":0,"dur_s":10,"cost_usd":0.5,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# From a plain directory that is NOT a git repository: the ledger is global and the series must
# be readable from anywhere — a `--series` that demands a target repo would chain the judge's
# input to the wrong cwd.
mkdir -p "$OUTSIDE/anywhere"
SERIES_OUT="$( cd "$FIX" && "$SDD" kaizen --series 2>/dev/null )"; rc=$?

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
# The two stray rows in the fixture are byte-identical but for the `repo` key, and they have to
# land in DIFFERENT buckets: one row nobody can attribute is not the same accusation as one whose
# event nobody recognizes. Lumped together (the old `else true end`) this reads `unrecognized:2,
# no_repo:0` — an object compared whole, so neither bucket can drift alone.
assert_eq "every excluded row is counted, by reason" \
  '{"non_comparable":2,"unrecognized":1,"meta":1,"other_repo":0,"no_repo":1}' \
  "$(jq -c '.excluded' <<< "$SERIES_OUT")"

# --- a degradation is an escalation the series has to SEE --------------------
# `PUBLISH_ON_REVIEW_BLOCKED=draft` makes the runner give up on reviewing and publish a draft PR
# by itself. It writes `event: "degraded"`, and the filter above only ever admitted `session` and
# `blocked`: a row it does not admit is counted in `excluded.unrecognized` and disappears from
# every number the judge reads — one blind spot traded for another. So the assertion that matters
# is not "the row exists" (check-autonomy.sh proves that) but "the series did not throw it away".
#
# Its own tiny ledger instead of extra rows in the fixture above: the degradation is a COHERENT
# two-row story (a REVIEW session whose gate failed, then the runner degrading), and splicing it
# into a fixture built for the label rubric would have meant either an escalation with no session
# before it or a second reading of the m1/REVIEW group that nobody can tell apart.
echo "== series: a degradation is seen, and counted as an escalation =="
mkdir -p "$OUTSIDE/degraded"
localize > "$OUTSIDE/degraded/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"bbb2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"fail","gate_why":"Security = B"}
{"v":1,"ts":"2026-08-16T10:01:00-03:00","event":"degraded","kind":"review-to-draft","run_id":"r1","invocation":"run","kit_sha":"bbb2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","gate_why":"Security = B"}
EOF
SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/degraded" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "the degradation is NOT thrown away as unrecognized" "0" \
  "$(field '.excluded.unrecognized')"
assert_eq "it is counted as an escalation, by kind" '{"review-to-draft":1}' \
  "$(jq -c '.latest.escalations' <<< "$SERIES_OUT")"
# The escalation map lives inside the kit_sha slice, so the axis comes for free — but only if the
# row carries the stamp AND survives the filter. Reading it back proves both.
assert_eq "on the axis of the kit version that produced it" "bbb2222" "$(field '.latest.kit_sha')"
# A degradation spends no session. Counting it as one would deflate moved_rate — the headline
# number — by inventing a session that never ran.
assert_eq "it is not counted as a session" "1" "$(field '.latest.sessions')"
assert_eq "so moved_rate still speaks only of real sessions" "1" "$(field '.latest.moved_rate')"
# Inside the degraded run itself the failing REVIEW session alone already reads `refez`. Kept,
# because it is true — but it is NOT evidence that the rubric may stay blind to `degraded`, and
# it was written as if it were. It is green with or without the fix, so what it measures is this
# fixture's single run, not phase_label. The block below is the one that measures the rubric.
assert_eq "inside the degraded run the failing session alone already reads refez" "refez" \
  "$(field '.latest.detail[] | select(.phase == "REVIEW") | .label')"

# --- and the label still says so after a later run passes --------------------
# The rubric groups by (mission, phase) over the WHOLE kit_sha slice, never per run. So "the
# failing session already says refez" holds only INSIDE the degraded run: come back with
# `sdd run`, let REVIEW pass this time, and `last | .gate` is "pass", no `blocked` row was ever
# written to this group, and the one mission where the runner lowered its own bar reads `ok`.
# `blocked` sits in the rubric for exactly that reason — an escalation outlives the session that
# provoked it — and `degraded` is an escalation. Leaving it out had the two escalation events
# answering the same question differently, which is this mission's own defect one field over.
echo "== series: a degradation still colours the label after a later run passes =="
mkdir -p "$OUTSIDE/degthenok" "$OUTSIDE/degasblocked"
localize > "$OUTSIDE/degthenok/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ccc3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"fail","gate_why":"Security = B"}
{"v":1,"ts":"2026-08-16T10:01:00-03:00","event":"degraded","kind":"review-to-draft","run_id":"r1","invocation":"run","kit_sha":"ccc3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","gate_why":"Security = B"}
{"v":1,"ts":"2026-08-16T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ccc3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":0.5,"moved":true,"gate":"pass","gate_why":"draft PR open"}
{"v":1,"ts":"2026-08-16T11:00:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"ccc3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"pass","gate_why":"every criterion A"}
EOF
SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/degthenok" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "the REVIEW group of a mission that degraded never reads ok" "refez" \
  "$(field '.latest.detail[] | select(.phase == "REVIEW") | .label')"
# The histogram is what the judge is told to cite (agents/sdd-kaizen.md), so it is asserted apart
# from the per-group label: a rubric that reads refez into a histogram bucket nobody counts would
# be the same lie one layer out.
assert_eq "and the histogram carries it, so no verdict can cite ok for a run that degraded" "1" \
  "$(field '.latest.labels.refez')"

# THE assertion, stated as a differential and therefore impossible to satisfy by fixture: the same
# four rows with `blocked` in place of `degraded` have ALWAYS read refez. If the two escalation
# events ever answer the label question differently again, this fails — whichever of them moved.
sed 's|"event":"degraded","kind":"review-to-draft"|"event":"blocked","kind":"budget-exhausted"|' \
  "$OUTSIDE/degthenok/autonomy-log.jsonl" > "$OUTSIDE/degasblocked/autonomy-log.jsonl"
blocked_labels="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/degasblocked" \
  "$SDD" kaizen --series 2>/dev/null | jq -c '.latest.labels' )"
assert_eq "an escalation is an escalation: degraded labels exactly as blocked does" \
  "$blocked_labels" "$(jq -c '.latest.labels' <<< "$SERIES_OUT")"

# No ledger at all: the judge's first real run happens on an empty history, and the series must
# say so in the same shape — valid JSON, latest null, insufficient — instead of dying or zeroing.
SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/empty" "$SDD" kaizen --series 2>/dev/null )"; rc=$?
assert_eq "a missing ledger still exits 0" "0" "$rc"
assert_eq "and still prints valid JSON" "0" \
  "$(jq -e . >/dev/null 2>&1 <<< "$SERIES_OUT"; echo $?)"
assert_eq "with latest null, not an invented group" "null" "$(field '.latest')"
assert_eq "and an insufficient guard, never a vacuous pass" "false" \
  "$(field '.guard.sufficient')"
# The empty ledger is a SECOND producer of the same object (a literal printed before jq ever
# runs), so it can drift from the real one key by key and nobody would notice until a consumer
# read `null` where it expected a number. Compared as key sets, not values: the values differ on
# purpose, the shape must not.
empty_guard_keys="$(jq -c '.guard | keys' <<< "$SERIES_OUT")"
# `excluded` is the other half of that same drift, and it was NOT compared until the repo filter
# added a fourth reason to it: a filter that empties the ledger has to land on the literal branch
# with the whole key set, never on a half-filled object the consumer reads as "zero of a reason
# that no longer exists".
empty_excluded_keys="$(jq -c '.excluded | keys' <<< "$SERIES_OUT")"

# --- the guard floor counts missions the judge could OBSERVE -----------------
# `missions` is `map(.mission) | unique` over every admitted row, escalations included — so three
# missions that escalated without ever spending a session cleared the floor of 3 and freed the
# judge to rule on a kit version it observed ZERO sessions of. The three ledgers below differ only
# in how the sessions are distributed, which is what makes the trio a differential: no fixture
# regime satisfies all three by accident.
echo "== series: the guard floor counts missions with a comparable session =="
mkdir -p "$OUTSIDE/escalonly" "$OUTSIDE/withsessions" "$OUTSIDE/twoofthree"

# A — three missions, three escalations, not one session.
localize > "$OUTSIDE/escalonly/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T12:00:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r1","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r2","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:02:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r3","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m12","phase":"EXEC","gate_why":"x"}
EOF
# B — the SAME three escalations plus one session per mission: the control that proves the fix
# did not simply tighten the floor into never passing.
cat "$OUTSIDE/escalonly/autonomy-log.jsonl" > "$OUTSIDE/withsessions/autonomy-log.jsonl"
localize >> "$OUTSIDE/withsessions/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T12:03:00-03:00","event":"session","run_id":"r4","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:04:00-03:00","event":"session","run_id":"r5","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:05:00-03:00","event":"session","run_id":"r6","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m12","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
# C — three missions, FOUR sessions, but only two missions spent them. This is the one that tells
# "count missions with a session" apart from the two cheaper readings that also pass A and B:
# "missions >= 3 and sessions > 0" and "sessions >= 3". Both would call this sufficient.
cat "$OUTSIDE/escalonly/autonomy-log.jsonl" > "$OUTSIDE/twoofthree/autonomy-log.jsonl"
localize >> "$OUTSIDE/twoofthree/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T12:03:00-03:00","event":"session","run_id":"r4","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:04:00-03:00","event":"session","run_id":"r5","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:05:00-03:00","event":"session","run_id":"r6","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T12:06:00-03:00","event":"session","run_id":"r7","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF

SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/escalonly" "$SDD" kaizen --series 2>/dev/null )"
# The display keeps telling the truth: three missions DID run on this kit version. What changes is
# which number the floor reads — hiding the escalations would trade one lie for another.
assert_eq "three escalation-only missions are still three missions on the axis" "3" \
  "$(field '.guard.missions_after_change')"
assert_eq "but none of them spent a session the judge could read" "0" \
  "$(field '.guard.sessions')"
assert_eq "so the floor counts zero missions, not three" "0" \
  "$(field '.guard.missions_with_session')"
assert_eq "and a series with no observed session is NOT sufficient" "false" \
  "$(field '.guard.sufficient')"
assert_eq "the empty-ledger series carries the same guard keys, never a subset" \
  "$empty_guard_keys" "$(jq -c '.guard | keys' <<< "$SERIES_OUT")"
assert_eq "and the same excluded keys, so no reason exists on one branch only" \
  "$empty_excluded_keys" "$(jq -c '.excluded | keys' <<< "$SERIES_OUT")"

SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/withsessions" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "the same three missions, one session each, clear the floor" "true" \
  "$(field '.guard.sufficient')"
assert_eq "and the guard says how many sessions bought it" "3" "$(field '.guard.sessions')"

SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/twoofthree" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "four sessions concentrated in two missions do not clear a floor of three" "false" \
  "$(field '.guard.sufficient')"
assert_eq "the refusal is not 'no sessions at all': there are four" "4" \
  "$(field '.guard.sessions')"
assert_eq "it is that only two missions were observed" "2" \
  "$(field '.guard.missions_with_session')"

# --- the ledger is global, the READERS are not -------------------------------
# One ledger file per machine, on purpose: cross-repo questions stay answerable. What was missing
# is the reader asking "mine?" — until this, a `sdd run` inside a /tmp fixture repo wrote rows the
# judge in the kit repo counted as its own (measured once: `66% waste · 2 mission(s)` where the
# truth was `0% · 1`). The judge's own source of truth was contaminable by any test.
#
# Read ONCE, no fixture can tell "filters by repo" from "always returns everything", so the
# assertion is DIFFERENTIAL: ONE file, TWO repos, read from each, and the two readings compared to
# each other. Two missions in repo A, three in repo B, all on a single kit_sha and interleaved in
# file order, so neither a missing filter (five missions from either side) nor a filter that
# happens to split on file order can pass by accident.
echo "== series: the ledger is global, the readers are not =="
mkdir -p "$OUTSIDE/repoA" "$OUTSIDE/repoB" "$OUTSIDE/tworepos"
( cd "$OUTSIDE/repoA" && git init -q -b main )
( cd "$OUTSIDE/repoB" && git init -q -b main )
# The path the runner writes is whatever `git rev-parse --show-toplevel` returns, not the string
# this file built the directory from — TMPDIR may be a symlink. Ask git, exactly as the reader
# does, instead of normalizing by hand on either side.
RA="$( cd "$OUTSIDE/repoA" && git rev-parse --show-toplevel )"
RB="$( cd "$OUTSIDE/repoB" && git rev-parse --show-toplevel )"
ledger_row() {   # ledger_row <repo> <mission> — one clean session, kit eee5555
  jq -cn --arg repo "$1" --arg mission "$2" \
    '{v:1, ts:"2026-08-16T13:00:00-03:00", event:"session", run_id:"r1", invocation:"run",
      kit_sha:"eee5555", kit_dirty:false, project:"p", repo:$repo, mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
      gate:"pass", gate_why:"x"}'
}
{ ledger_row "$RA" a1; ledger_row "$RB" b1; ledger_row "$RA" a2
  ledger_row "$RB" b2; ledger_row "$RB" b3; } > "$OUTSIDE/tworepos/autonomy-log.jsonl"

SERIES_A="$( cd "$RA" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
SERIES_B="$( cd "$RB" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
missions_of() { jq -r '[.latest.detail[].mission] | sort | join(",")' <<< "$1"; }
a_missions="$(missions_of "$SERIES_A")"
b_missions="$(missions_of "$SERIES_B")"
# The two positive readings first: without them the emptiness check below would be satisfied by a
# filter that refuses EVERYTHING, which is the vacuous way to have no shared mission.
assert_eq "the reading from one repo sees exactly its own two missions" "a1,a2" "$a_missions"
assert_eq "and the reading from the other sees exactly its own three" "b1,b2,b3" "$b_missions"
shared="$( jq -rn --arg a "$a_missions" --arg b "$b_missions" \
  '($a | split(",")) as $A | ($b | split(",")) as $B | ($A - ($A - $B)) | join(",")' )"
assert_eq "a row from another repo never enters the series" "" "$shared"
# What left has to be COUNTED. A filter that drops rows in silence is the same class of instrument
# this mission exists to kill: the number would be right and nobody could tell why it moved.
assert_eq "and what left is counted, never dropped in silence" "3" \
  "$(jq -r '.excluded.other_repo' <<< "$SERIES_A")"
assert_eq "symmetrically, read from the other side" "2" \
  "$(jq -r '.excluded.other_repo' <<< "$SERIES_B")"
assert_eq "the two readings together account for every session in the file" "5" \
  "$(( $(jq -r '.guard.sessions' <<< "$SERIES_A") + $(jq -r '.guard.sessions' <<< "$SERIES_B") ))"
# Standing in no repository at all, nothing in the ledger is yours. The safe direction: an empty
# series is `sufficient:false`, so it can only support `indeterminado` — never someone else's
# numbers read as a verdict about this kit.
SERIES_NOWHERE="$( cd "$OUTSIDE/anywhere" \
  && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "read from outside any git repository the series is empty, not everyone's" "null" \
  "$(jq -r '.latest' <<< "$SERIES_NOWHERE")"
assert_eq "and it says so, counting every row as some other repo's" "5" \
  "$(jq -r '.excluded.other_repo' <<< "$SERIES_NOWHERE")"

# =============================================================================
# gate + jidoka — the flow around the verdict artifact
# =============================================================================
# The fixture is a KIT-SHAPED repo: bin/, templates/ and config/ copied in and committed, so that
# SDD_HOME (parent of bin/) IS the repo root — the configuration `sdd kaizen` requires, since the
# kaizen phase plans the KIT's next mission, never a target project's. The gate-section ledger is
# the series fixture above, so the expected sha is aaa1111; every row cmd_kaizen appends carries
# phase KAIZEN and lands in excluded.meta, never shifting the axis it is judged on.
echo "== gate fixture (a kit-shaped repo: SDD_HOME == REPO_ROOT) =="
# $FIX was git-init'd at the top of this file, where the series fixtures needed its path; from
# here it is built out into the kit shape. From this point on it is also the cwd.
cd "$FIX" || exit 1
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
# gh answers `gh pr view <url> --json url --jq .url` — the only call gate_PR makes.
gh_stub_confirms_pr() {
  printf '#!/usr/bin/env bash\nif [ "$1" = "pr" ] && [ "$2" = "view" ]; then printf "%%s\\n" "$3"; exit 0; fi\nexit 1\n' \
    > "$OUTSIDE/stub/gh"
  chmod +x "$OUTSIDE/stub/gh"
}
PATH="$OUTSIDE/stub:$PATH"

# KAIZEN rows in the ledger — sessions and escalations the kaizen flow itself wrote.
krows() { jq -s '[.[] | select(.phase == "KAIZEN")] | length' "$LEDGER"; }

# The gate section gets its own ledger, SUFFICIENT on purpose (3 distinct missions on the latest
# sha): the gate now refuses `melhorou`/`piorou` over an insufficient series, so the scenarios
# that exercise those branches need a guard that admits them. The insufficient case keeps its own
# ledger in state2 below — same fixture kit, two guards, and the SAME verdict file flips between
# accepted and refused purely by which series the runner derives.
localize > "$LEDGER" <<'EOF'
{"v":1,"ts":"2026-08-15T11:00:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T11:01:00-03:00","event":"session","run_id":"g2","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T11:02:00-03:00","event":"session","run_id":"g3","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T11:03:00-03:00","event":"session","run_id":"g4","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# The insufficient guard: one mission on the same latest sha. Used per-invocation through
# SDD_STATE_DIR to prove the gate refuses a non-indeterminado verdict the moment the guard drops.
mkdir -p "$OUTSIDE/state2"
localize > "$OUTSIDE/state2/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T11:00:00-03:00","event":"session","run_id":"h1","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"h1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
state2_rows() { jq -s 'length' "$OUTSIDE/state2/autonomy-log.jsonl"; }

echo "== gate: verdict pending =="
# A stale verdict for an OLDER kit sha, with a complete born plan beside it: a gate blind to
# kit_sha_judged would accept this one and pass — the exact sabotage the KAIZEN_gate_blind
# mutation applies. The honest gate must keep asking for the CURRENT sha.
#
# PROVENANCE: the verdict frontmatter here and in the piorou scenario below is copied from the
# first REAL verdict the sdd-kaizen agent wrote — the 05-verdict.md born in commit c2dd298,
# session a0e24b4e (2026-08-15; the mission slug lives in that commit, not here — its middle
# word trips the language sensor) — never authored from memory: gate and fixture sharing one author's
# assumption is how three gate bugs crossed a green suite (see CLAUDE.md). Copied verbatim,
# including the blank line after the closing ---; only the values differ per scenario
# (real: `verdict: indeterminado`, `kit_sha_judged: none`). The body is omitted: it is
# OUTPUT_LANG mission content the gate never reads, and check-lang scans this file.
OLD="$FIX/docs/handoffs/20250101-old"
mkdir -p "$OLD"
cat > "$OLD/05-verdict.md" <<'EOF'
---
verdict: melhorou
kit_sha_judged: 0000000
date: 2025-01-01
---

# (body omitted — OUTPUT_LANG content the gate never reads)
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
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "with no verdict for the CURRENT sha the command blocks (rc 3)" "3" "$rc"
assert_eq "and the reason names the sha it is waiting for" "yes" \
  "$(grep -q 'no verdict for kit aaa1111' <<< "$out" && echo yes || echo no)"
assert_eq "the two dead sessions and the escalation reached the ledger as KAIZEN rows" \
  "$((before_rows + 3))" "$(krows)"

echo "== reminder: pipeline complete points at the judge =="
# A COMPLETE mission in the fixture kit: every gate satisfied, so cmd_run reaches the
# "pipeline complete" branch without opening a session. The artifact snippets are the passing
# forms proven by tests/check-gates.sh against the real gates; gh is stubbed to confirm the PR.
gh_stub_confirms_pr
DONE_SHA="$(git -C "$FIX" rev-parse --short HEAD)"
DMDIR="$FIX/docs/handoffs/20260102-donemission"
mkdir -p "$DMDIR"
cat > "$DMDIR/00-missao.md" <<'EOF'
---
missao: 20260102-donemission
aprovacao: auto
---
# Mission
EOF
: > "$DMDIR/01-plano.md"
cat > "$DMDIR/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | \`true\` → 0 | done | $DONE_SHA |
EOF
: > "$DMDIR/20-handoff-exec.md"
printf -- '---\nstatus: skipped\n---\n# QA\n' > "$DMDIR/30-handoff-qa.md"
printf '# Review\n\n### Overall Grade\n\n| Criterion | Grade | Rationale |\n|---|---|---|\n| Correctness | A | ok |\n' \
  > "$DMDIR/40-review-r1.md"
printf '# Docs\n\ndrift checklist\n\n| Area | Doc | Status | Evidence |\n|---|---|---|---|\n| runner | README | ✅ | commit abc1234 |\n' \
  > "$DMDIR/45-docs.md"
printf -- '---\npr_url: https://example.com/pr/1\n---\n# PR\n' > "$DMDIR/50-pr.md"
git add -A && git commit -qm "chore: a complete mission for the reminder scenario"

# The gate-section ledger: latest kit aaa1111 with 3 missions and NO verdict for it yet — the
# reminder must appear, with the numbers.
out="$( cd "$FIX" && "$KSDD" run 20260102-donemission 2>&1 )"; rc=$?
assert_eq "the complete mission reaches the human gate (rc 0)" "0" "$rc"
assert_eq "and reminds: missions accumulated on the current kit without a verdict" "yes" \
  "$(grep -q "autonomy series: 3 mission(s) on kit aaa1111 without a verdict" <<< "$out" && echo yes || echo no)"
assert_eq "pointing at sdd kaizen" "yes" \
  "$(grep -q "run 'sdd kaizen' in the kit repo" <<< "$out" && echo yes || echo no)"

# An empty ledger has nothing to judge: the reminder must stay silent — a nudge computed over
# no data is the vacuity the whole kit exists to kill.
out="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/empty" "$KSDD" run 20260102-donemission 2>&1 )"; rc=$?
assert_eq "with an empty ledger the pipeline still completes (rc 0)" "0" "$rc"
assert_eq "and the reminder stays silent" "no" \
  "$(grep -q 'autonomy series:' <<< "$out" && echo yes || echo no)"

echo "== jidoka: verdict piorou stops the line =="
loud_stub
VDIR="$FIX/docs/handoffs/20260815-kaizen-verdict"
mkdir -p "$VDIR"
# Frontmatter shape copied from the real verdict — see the PROVENANCE note above.
cat > "$VDIR/05-verdict.md" <<'EOF'
---
verdict: piorou
kit_sha_judged: aaa1111
date: 2026-08-15
---

# (body omitted — OUTPUT_LANG content the gate never reads)
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
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "a verdict without the born plan beside it blocks (rc 3)" "3" "$rc"
assert_eq "naming the missing artifact" "yes" \
  "$(grep -q '00-missao\.md is missing' <<< "$out" && echo yes || echo no)"
assert_eq "and its two dead sessions plus the escalation are on the ledger" \
  "$((before_rows + 3))" "$(krows)"

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

echo "== gate: the verdict enum is closed =="
# A label outside melhorou|piorou|indeterminado is never trusted — a typo'd verdict that fell
# into the born-plan path would satisfy the gate on a value nobody defined.
dead_stub
sed -i 's/^verdict: melhorou$/verdict: bogus/' "$VDIR/05-verdict.md"
git add -A && git commit -qm "chore: verdict outside the enum"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "a verdict outside the enum blocks (rc 3)" "3" "$rc"
assert_eq "naming the closed enum" "yes" \
  "$(grep -q 'is not one of melhorou|piorou|indeterminado' <<< "$out" && echo yes || echo no)"
sed -i 's/^verdict: bogus$/verdict: melhorou/' "$VDIR/05-verdict.md"
git add -A && git commit -qm "chore: verdict back to melhorou"

echo "== gate: an insufficient guard only supports indeterminado =="
# The SAME verdict file that passes under the sufficient ledger must be refused the moment the
# series drops below the guard floor: the guard belongs to the runner (boot prompt), and this is
# where that sentence is enforced rather than requested. state2 carries 1 mission on aaa1111.
dead_stub
before2="$(state2_rows)"
out="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/state2" "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "melhorou over an insufficient series blocks (rc 3)" "3" "$rc"
assert_eq "naming the runner's guard" "yes" \
  "$(grep -q "only supports 'indeterminado'" <<< "$out" && echo yes || echo no)"
assert_eq "and its sessions landed in the insufficient ledger, not the main one" \
  "$((before2 + 3))" "$(state2_rows)"

echo "== reminder: silenced once the verdict exists =="
# The verdict for aaa1111 is on disk now (the scenarios above wrote it). Same complete mission,
# same populated ledger — but the judge already spoke, so nagging would teach people to ignore
# the reminder. The search is the gate's: by kit_sha_judged content, never by newest file.
out="$( cd "$FIX" && "$KSDD" run 20260102-donemission 2>&1 )"; rc=$?
assert_eq "the complete mission still completes (rc 0)" "0" "$rc"
assert_eq "and the reminder is suppressed by the existing verdict" "no" \
  "$(grep -q 'autonomy series:' <<< "$out" && echo yes || echo no)"

echo "== dry-run projection =="
# Projected against the insufficient ledger (the gate is pending there on the guard, so
# run_phase is reached) — the projection must print the prompt while touching nothing: no
# claude, no mission directory, no row in either ledger. The loud stub turns any real session
# into a visible ledger row; the row counts are the witness, and the handoff listing replaces
# the old date-recomputed path check (two `date` calls could straddle midnight).
loud_stub
before_rows="$(krows)"
before2="$(state2_rows)"
dirs_before="$(ls -1 "$FIX/docs/handoffs" | sort)"
out="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/state2" "$KSDD" kaizen --dry-run 2>&1 )"; rc=$?
assert_eq "kaizen --dry-run exits 0" "0" "$rc"
assert_eq "and prints the KAIZEN boot prompt" "yes" \
  "$(grep -q 'DRY RUN: phase KAIZEN' <<< "$out" && echo yes || echo no)"
assert_eq "which cites the series command as the source of truth" "yes" \
  "$(grep -q 'kaizen --series' <<< "$out" && echo yes || echo no)"
assert_eq "driven by the sdd-kaizen agent" "yes" \
  "$(grep -q 'sdd-kaizen' <<< "$out" && echo yes || echo no)"
assert_eq "the projection creates no mission directory" \
  "$dirs_before" "$(ls -1 "$FIX/docs/handoffs" | sort)"
assert_eq "and writes no row to the main ledger" "$before_rows" "$(krows)"
assert_eq "nor to the insufficient one" "$before2" "$(state2_rows)"

echo "== the axis degenerates in the kit repo and holds in a target =="
# ADR 0003 compiled into something the human can read. `guard.sufficient: false` alone is ambiguous
# by construction: in a target repo it means "not enough missions yet", and in the repo that BUILDS
# the kit it means the axis itself cannot work — every session commits, so the next one lands on a
# fresh kit_sha and no number of missions here will ever clear the floor. Read as the first, the
# human goes hunting for missions that would never help.
#
# Both halves are asserted TOGETHER per fixture (`<field>/<note>`), because either alone is a
# different, weaker claim: a field nobody prints explains nothing to the human, and a sentence with
# no derived field behind it is the runner having an opinion — which is what ADR 0001 forbids.
#
# DIFFERENTIAL, and built so that no cheaper reading passes both sides: the healthy fixture carries
# MORE THAN ONE sha (so "count the shas" fails it) and the degenerate one carries more than one
# mission and more than one phase (so "one mission" or "one phase" fails it too).
mkdir -p "$OUTSIDE/degenaxis" "$OUTSIDE/healthyaxis" "$OUTSIDE/firstsha"

# A — the kit repo, measured: three consecutive phases of ONE mission, each on its own kit_sha
# because the phase before it committed. This is the gemba of 2026-08-16, where `latest` and
# `previous` turned out to be two phases of the same mission (PR at US$ 1.48 vs DOCS at US$ 7.31).
localize > "$OUTSIDE/degenaxis/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T14:00:00-03:00","event":"session","run_id":"k1","invocation":"run","kit_sha":"a000001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m20","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"k1s","rc":0,"dur_s":10,"cost_usd":5.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T14:01:00-03:00","event":"session","run_id":"k2","invocation":"run","kit_sha":"a000002","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m20","phase":"DOCS","step":"DOCS","agent":"sdd-docs","model":"opus","attempt":1,"auto_retry":false,"session":"k2s","rc":0,"dur_s":10,"cost_usd":7.31,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T14:02:00-03:00","event":"session","run_id":"k3","invocation":"run","kit_sha":"a000003","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m21","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"k3s","rc":0,"dur_s":10,"cost_usd":1.48,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# B — a real target repo: the kit does not change during a mission, so many missions share one sha
# and a sha change is an upgrade of the kit, not a commit of it. Two shas, three sessions each.
localize > "$OUTSIDE/healthyaxis/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T15:00:00-03:00","event":"session","run_id":"t1","invocation":"run","kit_sha":"b000001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"n1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"t1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T15:01:00-03:00","event":"session","run_id":"t2","invocation":"run","kit_sha":"b000001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"n2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"t2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T15:02:00-03:00","event":"session","run_id":"t3","invocation":"run","kit_sha":"b000001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"n3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"t3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T16:00:00-03:00","event":"session","run_id":"t4","invocation":"run","kit_sha":"b000002","kit_dirty":false,"project":"p1","repo":"/p1","mission":"n4","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"t4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T16:01:00-03:00","event":"session","run_id":"t5","invocation":"run","kit_sha":"b000002","kit_dirty":false,"project":"p1","repo":"/p1","mission":"n5","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"t5s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T16:02:00-03:00","event":"session","run_id":"t6","invocation":"run","kit_sha":"b000002","kit_dirty":false,"project":"p1","repo":"/p1","mission":"n6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"t6s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# C — one kit version, one session: that axis has not degenerated, it has only just started. The
# probe for the "more than one sha" half of the predicate, which the two fixtures above cannot see.
localize > "$OUTSIDE/firstsha/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T17:00:00-03:00","event":"session","run_id":"u1","invocation":"run","kit_sha":"c000001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"o1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"u1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# Three answers, not two: a sentence printed WITHOUT the record that decides it is not the same
# event as no sentence at all, and folding them together would let a half-printed explanation
# satisfy the negative side by accident.
axis_note() {   # axis_note <captured output> -> yes | adr-missing | no
  grep -q 'kit_sha axis is degenerate' <<< "$1" || { printf 'no'; return 0; }
  grep -q 'ADR 0003' <<< "$1" && printf 'yes' || printf 'adr-missing'
}

# --dry-run: the projection reaches nothing that spends a session (the loud stub above is still
# armed), and the explanation belongs to the human-facing path — `--series` returns pure JSON.
deg_out="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/degenaxis" "$KSDD" kaizen --dry-run 2>&1 )"
SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/degenaxis" "$KSDD" kaizen --series 2>/dev/null )"
assert_eq "degenerate axis: one session per kit version, several versions — the series says so and the runner explains it citing ADR 0003" \
  "true/yes" "$(field '.guard.degenerate_axis')/$(axis_note "$deg_out")"

healthy_out="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/healthyaxis" "$KSDD" kaizen --dry-run 2>&1 )"
SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/healthyaxis" "$KSDD" kaizen --series 2>/dev/null )"
assert_eq "degenerate axis: missions sharing a kit version is the axis WORKING — false, and not a word about it" \
  "false/no" "$(field '.guard.degenerate_axis')/$(axis_note "$healthy_out")"

# Deliberately NOT prefixed `degenerate axis`: the checkpoint Check counts exactly the two
# assertions above, and this third one guards the clause they share a blind spot on.
SERIES_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/firstsha" "$KSDD" kaizen --series 2>/dev/null )"
assert_eq "a single kit version has not degenerated, it has only just started" "false" \
  "$(field '.guard.degenerate_axis')"

echo "== the approved plan never reaches a session =="
# Once `aprovacao:` is filled, the generic fix-it retry prompt ("complete what is missing")
# reads, to a live agent, as an instruction to blank the field — erasing a decision that may be
# a HUMAN's, with `sdd run` already acting on it. Both directions bail out before any session:
# the loop's own `auto` stops the line; a human's value is a done state, not a defect.
loud_stub
sed -i 's/^aprovacao:$/aprovacao: auto/' "$VDIR/00-missao.md"
git add -A && git commit -qm "chore: the born plan tries to approve itself"
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "a born plan that approves itself is refused (rc 3)" "3" "$rc"
assert_eq "naming the self-approval" "yes" \
  "$(grep -q "aprovacao: auto" <<< "$out" && echo yes || echo no)"
assert_eq "without opening any session that could blank the field" \
  "$before_rows" "$(krows)"

sed -i 's/^aprovacao: auto$/aprovacao: humano-2026-08-15/' "$VDIR/00-missao.md"
git add -A && git commit -qm "chore: the human approves the born plan"
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "a human-approved plan is a done state (rc 0)" "0" "$rc"
assert_eq "pointing at sdd run, not at another verdict" "yes" \
  "$(grep -q "sdd run" <<< "$out" && echo yes || echo no)"
assert_eq "again without any session" "$before_rows" "$(krows)"

echo "== an approval written by the RETRY session still bails out =="
# The retry runs the same generic fix-it prompt the first session did — it can be the one that
# fills `aprovacao:`. The third gate evaluation must take the same bailout as the other two:
# without it, the flow falls through to the generic BLOCKED branch, misreporting an approval as
# a no-progress escalation and writing a spurious blocked row. The discriminating witnesses:
# the self-approval message, and a ledger delta of exactly 2 (two sessions, NO escalation row).
sed -i 's/^aprovacao: humano-2026-08-15$/aprovacao:/' "$VDIR/00-missao.md"
git rm -q "$VDIR/01-plano.md"
git add -A && git commit -qm "chore: plan artifact missing so the gate is pending again"
APPROVE_MARKER="$OUTSIDE/approve-once"
rm -f "$APPROVE_MARKER"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ -e "$APPROVE_MARKER" ]; then
  sed -i 's/^aprovacao:\$/aprovacao: auto/' "$VDIR/00-missao.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the retry session approves the plan"
else
  : > "$APPROVE_MARKER"
fi
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"
before_rows="$(krows)"
out="$( cd "$FIX" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "the retry-written self-approval stops the line (rc 3)" "3" "$rc"
assert_eq "through the self-approval message, not the generic BLOCKED" "yes" \
  "$(grep -q 'approved ITSELF' <<< "$out" && echo yes || echo no)"
assert_eq "with two session rows and NO spurious escalation row" \
  "$((before_rows + 2))" "$(krows)"
sed -i 's/^aprovacao: auto$/aprovacao:/' "$VDIR/00-missao.md"
: > "$VDIR/01-plano.md"
git add -A && git commit -qm "chore: restore the born plan after the retry-approval scenario"

echo "== a kit that is not a git checkout is refused by name =="
# A plain copy of the kit has no history to judge. The refusal must say THAT — the generic
# "run it in the kit repo" would send the user hunting for the wrong problem while standing in
# the right directory.
KIT2="$OUTSIDE/kitcopy"
mkdir -p "$KIT2"
cp -r "$FIX/bin" "$FIX/templates" "$FIX/config" "$KIT2/"
out="$( cd "$FIX" && "$KIT2/bin/sdd" kaizen 2>&1 )"; rc=$?
assert_eq "a kit without .git dies with rc 1" "1" "$rc"
assert_eq "naming the missing git history, not the cwd" "yes" \
  "$(grep -q 'is not a git checkout' <<< "$out" && echo yes || echo no)"

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
# The FIXTURE kit ($KSDD, a real git checkout) run from the target repo: deterministic in both
# contexts — the real repo's $SDD would fire the not-a-git-checkout refusal instead when this
# test runs inside the mutation sandbox, whose kit copy has no .git.
out="$( cd "$TGT" && "$KSDD" kaizen 2>&1 )"; rc=$?
assert_eq "sdd kaizen refuses to run outside the kit repo (rc 1)" "1" "$rc"
assert_eq "and points at the kit repo" "yes" \
  "$(grep -q 'run it in the kit repo' <<< "$out" && echo yes || echo no)"

echo "== the base branch warning reaches the kaizen door =="
# The kaizen door is the WORSE of the two that open a committing session: it validates the kit repo
# and warns about a dirty tree, and then writes a verdict plus three artifacts wherever you happen
# to be standing — `main` included. The warning used to live only in cmd_preflight, which nothing
# forces you to run.
#
# The twin of the assertion in check-gates.sh, and NOT redundant with it: sabotage proves each one
# is blind to the other's call site (dropping the call in cmd_run leaves this file green, dropping
# it in cmd_kaizen leaves check-gates.sh green). That is why the catalogue mutation sabotages the
# DEFINITION — only that measures that both doors really go through it.
#
# DIFFERENTIAL for the same reason as its twin: the fixture is born on `main`, so "warns on the
# base branch" and "always warns" would look identical from one reading. Two readings, one checkout
# apart. `--dry-run` because the projection returns before any session — the fixture gate is
# pending here, so a real invocation would spend the stub.
kz_base="$( cd "$FIX" && "$KSDD" kaizen --dry-run 2>&1 )"; kz_base_rc=$?
git -C "$FIX" checkout -q -b kaizen/base-branch-fixture
kz_feat="$( cd "$FIX" && "$KSDD" kaizen --dry-run 2>&1 )"; kz_feat_rc=$?
git -C "$FIX" checkout -q main
git -C "$FIX" branch -q -D kaizen/base-branch-fixture

assert_eq "the base branch warning reaches sdd kaizen too" "yes" \
  "$(grep -q 'you are on the base branch' <<< "$kz_base" && echo yes || echo no)"
assert_eq "and is silent off the base branch (not a warning that always fires)" "no" \
  "$(grep -q 'you are on the base branch' <<< "$kz_feat" && echo yes || echo no)"
# The rc of BOTH sides, compared to each other: turning the warn into a die is the regression that
# would lock the kaizen loop out of its own repo, and it is invisible to a presence assertion.
assert_eq "and it is a warn and never a die: the same rc on both branches" \
  "0/0" "$kz_base_rc/$kz_feat_rc"
# `--series` opens no session and commits nothing, so it must stay quiet even standing on `main` —
# a warning fired by a pure read is noise, and noise is what teaches people to ignore warnings.
assert_eq "but a bare --series read does not warn: it opens no session" "no" \
  "$(grep -q 'you are on the base branch' \
       <<< "$( cd "$FIX" && "$KSDD" kaizen --series 2>&1 )" && echo yes || echo no)"

echo "== hygiene =="
assert_eq "the fixture kit tree ends clean" "" "$(git -C "$FIX" status --porcelain)"
assert_eq "the ledger is never tracked by the fixture kit" "0" \
  "$(git -C "$FIX" ls-files | grep -c 'autonomy-log\.jsonl')"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the series tells the truth and the gate holds\n'; exit 0; fi
printf '%d kaizen check(s) failed\n' "$fails" >&2
exit 1
