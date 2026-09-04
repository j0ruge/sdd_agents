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

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
# ONE grep per element, each contributing at most 1 — so the count really is "how many of the five
# format elements are present". ⚠️ It was a single `grep -c` with five `-e`, and that counts
# matching LINES, not distinct elements: measured, a copy that lost the `# 0003 — ` title and
# gained a second `## Context` still scored 5 and the assertion passed green. A shape assertion a
# duplicated heading can satisfy asserts nothing about the element that went missing — the
# fail-open shape this repo treats as the worst thing a sensor can do, because it reports having
# measured what it did not measure.
ADR3_SHAPE_PATS=(
  '^# 0003 — .'                       # title in the `# NNNN — <title>` form 0001/0002 ship
  '^Date: .* · Status: accepted$'     # the dated status line
  '^## Context$' '^## Decision$' '^## Consequences$'
)
adr3_shape=0
if [ -f "$ADR3" ]; then
  for pat in "${ADR3_SHAPE_PATS[@]}"; do
    grep -qE "$pat" "$ADR3" && adr3_shape=$((adr3_shape + 1))
  done
fi
assert_eq "adr 0003 exists in the shape of 0001/0002 (title, dated status, three sections)" \
  "5" "$adr3_shape"

# ⚠️ It grepped the WHOLE file, and `ADR 0003` appears there five times — FOUR of them in comments.
# So the assertion whose own words are "a decision record no code cites is a label" was itself
# measuring prose: under a degrade that strips the citation from the sentence the runner PRINTS, the
# four comments kept it green. Comment lines are dropped first, which is the difference between
# "the file mentions the decision" and "the implementation names it".
#
# The RUNTIME half — that the citation reaches the human on stdout — is asserted by the
# `degenerate axis` pair further down, whose helper demands `ADR 0003` inside the printed
# explanation. This one holds the source end; that one holds the terminal end.
#
# Read through a variable and a herestring, never `grep file | grep -q`: the second grep exits on
# the first match, the first takes SIGPIPE, and under `pipefail` the pipeline returns 141 — the
# house trap that inverts on large input and behaves on small.
adr3_code="$(grep -v '^[[:space:]]*#' "$SDD" || true)"
assert_eq "adr 0003 is named by bin/sdd — a decision record no code cites is a label" "yes" \
  "$(grep -q 'ADR 0003' <<< "$adr3_code" && echo yes || echo no)"

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
# m6/EXEC churn (fail/true then pass/true, one run, no retry, no escalation — ok under the old
# rubric, leve since 20260828-instrumento-honesto)
# m7/EXEC the DESIGNED loop (three sessions of one run, each closing one increment: the gate
# refuses twice by construction and the phase never churned once — `leve` until 20260829, `ok`
# since). It stands beside m6 on the same version on purpose: both are "a phase whose gate failed
# and then passed", and the ONLY thing that tells them apart is whether the pending count fell.
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
{"v":1,"ts":"2026-08-15T10:12:00-03:00","event":"session","run_id":"r9","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s9","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:13:00-03:00","event":"session","run_id":"r9","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s10","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:14:00-03:00","event":"session","run_id":"r10","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s11","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":3,"pending_after":2,"increments_total":3,"gate":"fail","gate_why":"2 of 3 increment(s) still to execute"}
{"v":1,"ts":"2026-08-15T10:15:00-03:00","event":"session","run_id":"r10","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s12","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":2,"pending_after":1,"increments_total":3,"gate":"fail","gate_why":"1 of 3 increment(s) still to execute"}
{"v":1,"ts":"2026-08-15T10:16:00-03:00","event":"session","run_id":"r10","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":3,"auto_retry":false,"session":"s13","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":1,"pending_after":0,"increments_total":3,"gate":"pass","gate_why":"suite green"}
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
# Five phase groups on the previous version: m1/QA leve, m1/REVIEW refez, m2/EXEC refez,
# m6/EXEC leve, m7/EXEC ok. The `ok` is the designed loop and it was 0 until 20260829 — the tally
# is what stops the new clause from being asserted only where it is convenient.
assert_eq "the label tally sums the detail" \
  '{"ok":1,"leve":2,"refez":2}' "$(jq -c '.previous.labels' <<< "$SERIES_OUT")"
assert_eq "escalations are counted by kind" '{"budget-exhausted":1,"increment-blocked":1}' \
  "$(jq -c '.previous.escalations' <<< "$SERIES_OUT")"
# 9 of the 10 sessions of the previous version wrote to the disk (s1 is the one that did not).
assert_eq "moved_rate is computed over the group's sessions" "0.9" \
  "$(field '.previous.moved_rate')"
# What the sessions DID — the headline since 20260828-instrumento-honesto. Over the previous
# version: s1 wrote nothing and failed (idle); s2 and the first m6 session wrote and failed with
# the pending count untouched (churned); four passed their gate and the two middle sessions of m7
# closed an increment each (advanced, 4 + 3). All three counts differ, so no two swapped fields
# agree by coincidence.
assert_eq "outcomes over the previous version: advanced · churned · idle" \
  '{"advanced":7,"churned":2,"idle":1}' "$(jq -c '.previous.outcomes' <<< "$SERIES_OUT")"
assert_eq "and over the latest, a single clean pass" \
  '{"advanced":1,"churned":0,"idle":0}' "$(jq -c '.latest.outcomes' <<< "$SERIES_OUT")"
assert_eq "each phase of the detail carries its own outcomes" \
  '{"advanced":1,"churned":1,"idle":0}' \
  "$(jq -c '.previous.detail[] | select(.mission == "m1" and .phase == "REVIEW") | .outcomes' <<< "$SERIES_OUT")"
# advance_rate reads what the session DID, moved_rate reads the disk: 7 of 10 advanced, 9 of 10
# wrote. Asserted on ONE line, on a fixture where the two numbers DIFFER, so a series that derived
# one from the other cannot pass. ⚠️ The name used to say "reads the gate", and it was true until
# 20260829-o-incremento-que-andou: only 5 of these 10 sessions passed a gate (0.5), and the two m7
# sessions the old spelling threw away are the designed loop this mission exists to stop
# discarding. Three numbers, three different values — 0.5 gate, 0.7 outcome, 0.9 disk — so no
# yardstick swap here is satisfiable by coincidence.
assert_eq "advance_rate reads what the sessions did and moved_rate reads the disk, and here they differ" \
  "0.7 0.9" "$(jq -r '"\(.previous.advance_rate) \(.previous.moved_rate)"' <<< "$SERIES_OUT")"
# The churn clause of the rubric. A phase whose gate failed and then passed inside ONE run, with
# no auto retry, no human retry and no escalation, used to read `ok` — frete-cif-fob EXEC, seven
# sessions and five refusals, read `ok` to the judge. Any session of the phase with gate == fail is
# at least `leve` now; `refez` does not change. Control beside it, on the same series: a phase that
# passed on its first session still reads `ok`, so the clause is not "everything is leve".
assert_eq "a phase that wrote, failed its gate and then passed reads leve, never ok" \
  "leve" "$(field '.previous.detail[] | select(.mission == "m6" and .phase == "EXEC") | .label')"
assert_eq "control: a single clean pass still reads ok" \
  "ok" "$(field '.latest.detail[] | select(.mission == "m3") | .label')"

# --- the designed loop is not churn (20260829-o-incremento-que-andou) --------
# The clause above ("any session with gate == fail is at least leve") was measured a day later
# against the ledger it was written for and read `leve` over EVERY EXEC phase of 2+ increments:
# the runner refuses the gate once per increment BY DESIGN, so `leve` had stopped separating the
# pipeline's own loop from a phase that spun. m7 is that loop — three sessions, each closing one
# increment, no auto retry, no human retry, no escalation — and it now reads `ok` because every
# one of its sessions advanced. The rate is asserted on the SAME line as the label, because they
# are one decision read twice: under the old rubric this reads `leve 0.5`.
assert_eq "a designed loop reads ok, and advance_rate counts the increments that advanced" \
  "ok 0.7" \
  "$(jq -r '[(.previous.detail[] | select(.mission == "m7" and .phase == "EXEC") | .label), (.previous.advance_rate | tostring)] | join(" ")' <<< "$SERIES_OUT")"
# The other half, and the reason the clause is not "EXEC is always ok": m6 is the same SHAPE as
# m7 — one run, gate fail then gate pass, no retry, no escalation — and it stays `leve` because
# its failing session moved no increment. Its own outcomes are read on the same line, so a rubric
# that reached `leve` for some other reason (a gate token, a session count) cannot satisfy this.
assert_eq "real churn still reads leve" \
  'leve {"advanced":1,"churned":1,"idle":0}' \
  "$(jq -r '[(.previous.detail[] | select(.mission == "m6" and .phase == "EXEC") | .label), (.previous.detail[] | select(.mission == "m6" and .phase == "EXEC") | .outcomes | tojson)] | join(" ")' <<< "$SERIES_OUT")"
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

# --- each arm of the `leve` clause, ALONE ------------------------------------
# Found by the sabotage pass of 20260829-o-incremento-que-andou, and it was a fail-open: with the
# whole rubric anchored on the fixture above, `(.auto_retry == true or ...)` could be DELETED and
# `outcome != "advanced"` narrowed to `outcome == "churned"` with the suite still green. The reason
# is that m1/QA carries both facts at once — an idle session AND an in-loop auto retry — so the
# assertion whose name promises the auto-retry arm cannot tell which of the two labelled it. A
# fixture that satisfies an assertion for two possible reasons measures neither.
#
# One phase per arm, each with exactly ONE reason to be `leve`, plus a control that has none:
#   m8  the auto retry ALONE — its single session passed its gate AND closed an increment, so
#       `outcome` reads `advanced` and the arm is the only thing left. Reachable and not academic:
#       in the repo that builds the kit every session commits, so the failing first pass and the
#       in-loop retry land on DIFFERENT kit_sha and are graded in different groups — the retry is
#       then alone in its group, and without this arm a phase that needed two tries reads `ok`.
#   m9  the idle session ALONE — s1 wrote nothing and failed, s2 passed, no retry of any kind.
#       Narrowed to `outcome == "churned"` this reads `ok`: a session that produced NOTHING would
#       stop marking the phase, which is the older and worse blindness of the two.
#   m10 the control — the designed loop again, in isolation: two sessions, each closing an
#       increment, no retry. If this reads `leve` the clause is not stricter, it is just wrong.
# Asserted on ONE line so no single arm can be traded for another.
echo "== series: each arm of the leve clause, alone =="
mkdir -p "$OUTSIDE/arms"
localize > "$OUTSIDE/arms/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-17T10:00:00-03:00","event":"session","run_id":"a1","invocation":"run","kit_sha":"eee5555","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m8","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":true,"session":"a1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":2,"pending_after":1,"increments_total":2,"gate":"pass","gate_why":"suite green"}
{"v":1,"ts":"2026-08-17T10:01:00-03:00","event":"session","run_id":"a2","invocation":"run","kit_sha":"eee5555","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"a2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"no handoff"}
{"v":1,"ts":"2026-08-17T10:02:00-03:00","event":"session","run_id":"a2","invocation":"run","kit_sha":"eee5555","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"a3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":2,"pending_after":0,"increments_total":2,"gate":"pass","gate_why":"suite green"}
{"v":1,"ts":"2026-08-17T10:03:00-03:00","event":"session","run_id":"a3","invocation":"run","kit_sha":"eee5555","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"a4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":2,"pending_after":1,"increments_total":2,"gate":"fail","gate_why":"1 of 2 increment(s) still to execute"}
{"v":1,"ts":"2026-08-17T10:04:00-03:00","event":"session","run_id":"a3","invocation":"run","kit_sha":"eee5555","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"a5s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":1,"pending_after":0,"increments_total":2,"gate":"pass","gate_why":"suite green"}
EOF
ARMS_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/arms" "$SDD" kaizen --series 2>/dev/null )"
arm_label() { jq -r --arg m "$1" '.latest.detail[] | select(.mission == $m and .phase == "EXEC") | .label' <<< "$ARMS_OUT"; }
assert_eq "each arm of the leve clause stands alone: auto retry, idle session, and neither" \
  "leve leve ok" "$(arm_label m8) $(arm_label m9) $(arm_label m10)"

# --- the REVIEW round that advanced is not churn (20260831-a-rodada-que-andou) ----
# The same defect as m7 above, one phase further on. REVIEW is a LOOP BY DESIGN —
# REVIEW_MAX_ITER rounds, each landing its own `40-review-r<N>.md` — and `outcome` knew a single
# arm of progress, `pending_after < pending_before`, which exists for EXEC alone. So an r1 that
# landed with real findings and did not reach Grade A read `churned`, and the runner charged the
# phase for the refusal its own design schedules. Measured on the real ledger of window 2: the
# REVIEW of 20260830-a-tela-que-mente-o-pagamento is the most expensive cell of the whole slice —
# US$ 47.81, labelled `leve` off `1 advanced · 1 churned` — in the phase that consumes 41% of the
# spend the judge is asked to explain.
#
# FIVE missions, one per rule of the arm, because a rule whose removal no fixture notices is a rule
# with no probe. Each pairs the interesting session with a passing one so the phase closes and the
# cell is graded on the outcome rather than on `refez`:
#   m20  0→1 fail · 1→2 pass     the designed loop: both sessions advanced          ok
#   m21  1→1 fail · 1→2 pass     real churn: a session that landed NO new round     leve
#   m22  null→2 fail · 2→3 pass  no photograph of the round before                  leve
#   m23  0→1 fail · 1→2 pass     the round moved but the session wrote NOTHING      leve
#        (moved:false)
#   m24  2→1 fail · 1→2 pass     the round count went DOWN                          leve
#
# Every degrade of the arm lands somewhere different, and the values below were READ OFF the
# sabotage pass rather than predicted:
#   new rule            6 advanced · 3 churned · 1 idle   labels {ok: 1, leve: 4}
#   whole arm gone      5 advanced · 4 churned · 1 idle   {ok: 0, leve: 5}  mut_LEDGER_outcome_rounds_blind
#   no null guard       7 advanced · 2 churned · 1 idle   {ok: 2, leve: 3}  mut_LEDGER_outcome_rounds_unguarded, m22 turns ok
#   `>` becomes `!=`    7 advanced · 2 churned · 1 idle   {ok: 2, leve: 3}  m24 turns ok
#   no `.moved` guard   7 advanced · 3 churned · 0 idle   {ok: 2, leve: 3}  m23 turns ok
# The middle three share a slice tally, which is precisely why each rule also has its own CELL
# assertion below: the tally alone could not tell them apart, and a rule distinguished only by a
# number two other rules also produce is not measured.
#
# ⚠️ EVERY failing session here has `gate: "fail"` on purpose. A fixture where the round advanced
# AND the gate passed is satisfied by the FIRST arm of `outcome` and measures nothing about this
# one — the "red for the right reason" rule this repo pays for in CLAUDE.md.
#
# m22 is not academic. `jq` orders `null` below every number, so `.rounds_after > .rounds_before`
# with a null RIGHT-hand side is TRUE, and a REVIEW row whose photograph was never taken would read
# as the loudest progress in the ledger — fail-open in the direction of flattery, the exact error
# the EXEC sibling paid for. It is also the row shape `mut_RUN_review_rounds_photo_missing`
# produces, so without the guard that mutant would stop moving the histogram at all.
echo "== series: the REVIEW round that advanced is not churn =="
mkdir -p "$OUTSIDE/rounds"
localize > "$OUTSIDE/rounds/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T10:00:00-03:00","event":"session","run_id":"b1","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m20","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"b1s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":0,"rounds_after":1,"rounds_max":3,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B"}
{"v":1,"ts":"2026-08-31T10:01:00-03:00","event":"session","run_id":"b1","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m20","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"b2s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":1,"rounds_after":2,"rounds_max":3,"gate":"pass","gate_why":"40-review-r2.md: every criterion A"}
{"v":1,"ts":"2026-08-31T10:02:00-03:00","event":"session","run_id":"b2","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m21","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"b3s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":1,"rounds_after":1,"rounds_max":3,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B"}
{"v":1,"ts":"2026-08-31T10:03:00-03:00","event":"session","run_id":"b2","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m21","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"b4s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":1,"rounds_after":2,"rounds_max":3,"gate":"pass","gate_why":"40-review-r2.md: every criterion A"}
{"v":1,"ts":"2026-08-31T10:04:00-03:00","event":"session","run_id":"b3","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m22","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"b5s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":null,"rounds_after":2,"rounds_max":3,"gate":"fail","gate_why":"40-review-r2.md: Correctness = B"}
{"v":1,"ts":"2026-08-31T10:05:00-03:00","event":"session","run_id":"b3","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m22","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"b6s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":2,"rounds_after":3,"rounds_max":3,"gate":"pass","gate_why":"40-review-r3.md: every criterion A"}
{"v":1,"ts":"2026-08-31T10:06:00-03:00","event":"session","run_id":"b4","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m23","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"b7s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":false,"rounds_before":0,"rounds_after":1,"rounds_max":3,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B"}
{"v":1,"ts":"2026-08-31T10:07:00-03:00","event":"session","run_id":"b4","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m23","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"b8s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":1,"rounds_after":2,"rounds_max":3,"gate":"pass","gate_why":"40-review-r2.md: every criterion A"}
{"v":1,"ts":"2026-08-31T10:08:00-03:00","event":"session","run_id":"b5","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m24","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"b9s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":2,"rounds_after":1,"rounds_max":3,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B"}
{"v":1,"ts":"2026-08-31T10:09:00-03:00","event":"session","run_id":"b5","invocation":"run","kit_sha":"bbb7777","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m24","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"b10s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":1,"rounds_after":2,"rounds_max":3,"gate":"pass","gate_why":"40-review-r2.md: every criterion A"}
EOF
ROUNDS_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/rounds" "$SDD" kaizen --series 2>/dev/null )"
round_cell() { jq -r --arg m "$1" '.latest.detail[] | select(.mission == $m and .phase == "REVIEW")
                                   | "\(.label) \(.outcomes | tojson)"' <<< "$ROUNDS_OUT"; }
# THE assertion of this increment. Label and histogram on ONE line, because they are one decision
# read twice: under the old rubric this reads `leve {"advanced":1,"churned":1,"idle":0}`, which is
# letter for letter the cell window 2 charged US$ 47.81 for.
assert_eq "a REVIEW round that advanced reads advanced, never churned" \
  'ok {"advanced":2,"churned":0,"idle":0}' "$(round_cell m20)"
# The control, and the reason the clause is not "REVIEW is always ok": m21 has the same SHAPE as
# m20 — one run, gate fail then gate pass, no retry, no escalation — and stays `leve` because its
# failing session landed no new round. It reads the same under all three spellings, which is what
# a control is for.
assert_eq "control: a REVIEW session that landed no new round is still churn" \
  'leve {"advanced":1,"churned":1,"idle":0}' "$(round_cell m21)"
# The null guard, measured and not asserted in prose: without it b5s reads `advanced`, m22 turns
# `ok`, and a REVIEW row whose photograph was never taken becomes the loudest progress in the
# ledger.
assert_eq "a REVIEW row with no round before it is not a round that advanced" \
  'leve {"advanced":1,"churned":1,"idle":0}' "$(round_cell m22)"
# The `.moved != false` half of the arm, which no fixture reached until the sabotage pass said so.
# A session that wrote NOTHING has not advanced a round, whatever the disk says — the round it
# would be credited with is one an earlier session landed. Same guard, same direction and same
# reason as the EXEC arm one line up in bin/sdd.
assert_eq "a REVIEW session that wrote nothing did not advance the round" \
  'leve {"advanced":1,"churned":0,"idle":1}' "$(round_cell m23)"
# The DIRECTION, which is the whole reason this is a third arm and not a generalisation of the
# second: EXEC counts what is still to do and goes DOWN, REVIEW counts what has landed and goes UP.
# Spelled `!=` — "the number changed" — a round file that DISAPPEARED reads as progress. It is also
# what a single shared arm would do to the checkpoint that GREW, which is QA writing fix increments.
assert_eq "a REVIEW round count that went DOWN is not a round that advanced" \
  'leve {"advanced":1,"churned":1,"idle":0}' "$(round_cell m24)"
# The whole slice, so a rubric that reached the cells above by some other route still fails.
# ⚠️ It does NOT stand alone: three of the five degrades land on `7 · 2 · 1` or share a label
# tally, which is why every rule above also has its own cell.
assert_eq "and the slice tallies to the histogram only the new arm produces" \
  '{"advanced":6,"churned":3,"idle":1} {"ok":1,"leve":4,"refez":0}' \
  "$(jq -r '"\(.latest.outcomes | tojson) \(.latest.labels | tojson)"' <<< "$ROUNDS_OUT")"

# PARITY, measured and never asserted in prose — the second probe of this increment and the one
# that matters. `outcome` is ONE printed definition (`ledger_outcome_defs` in bin/sdd) spliced into
# BOTH readers, and a program that stopped splicing it and grew a local copy on the old yardstick
# stays internally consistent: only the comparison of the two OUTPUTS catches it. The house does
# not accept "same spelling in both programs" as proof of parity — the `$order` of cmd_autonomy and
# the `on_axis` of kaizen_series diverged once under a comment swearing the opposite
# (20260817-catraca-do-backlog, r1).
rounds_win="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/rounds" "$SDD" autonomy 2>&1 )"
rounds_table="$(sed -nE 's/^  bbb7777  [0-9]+ session\(s\) · ([0-9]+) advanced · ([0-9]+) churned · ([0-9]+) idle · .*/\1 \2 \3/p' <<< "$rounds_win")"
assert_eq "the human window and the judge count the REVIEW round alike" \
  "$(jq -r '.latest.outcomes | "\(.advanced) \(.churned) \(.idle)"' <<< "$ROUNDS_OUT")" "$rounds_table"
# ...and not by both being empty: two empty strings are equal. The floor is the known histogram of
# this fixture, so the parity above is about the numbers this block describes.
assert_eq "that parity is not vacuous — the table printed the three counts" "6 3 1" "$rounds_table"

# --- the phase that closed WITHOUT buying a session --------------------------
# The third clause of `phase_label` asks "did the last SESSION pass its gate?" while meaning "did
# the PHASE close?", and the two are the same question only while every gate that ever passes
# costs a session. It does not: the QA⇄EXEC fix loop closes QA for free — QA files a bug and a
# fix increment, EXEC closes both, and the next derivation finds gate_QA green with no second QA
# session anywhere. Measured on window 2: the QA of 20260830-o-rascunho-fantasma-do-mount read
# `refez` — the LOUDEST friction signal in the rubric — over a phase that closed clean, with
# `escalations: {}`, one launch for the whole mission, and REVIEW/DOCS/PR all `ok` after it.
#
# So the runner writes the FACT (`event: "gate_pass"`) instead of leaving the judge to infer it
# from an absence, and the rubric reads the fact. ⚠️ The promise is that `refez` stops being
# ASSERTED, never that the cell turns green: the surviving session is churn on its own count, and
# the cascade lands on `leve`. Promising `ok` would trade one false label for another.
#
# ⚠️ The `gate_pass` rows below carry EXACTLY the eleven keys `autonomy_gate_pass_row` builds —
# no `kind` and no `gate_why`, because the gate that closed was evaluated inside `current_phase()`,
# which runs as `$( )`, so GATE_WHY died with the subshell. A fixture that hands the reader a field
# the writer never writes is the shape CLAUDE.md names: writer and fixture sharing an author and an
# assumption, so a green suite CONFIRMS the assumption instead of measuring it. Copied from the
# constructor, never from memory.
echo "== series: a phase that closed without a session does not read refez =="
mkdir -p "$OUTSIDE/gatepass" "$OUTSIDE/nogatepass"
localize > "$OUTSIDE/gatepass/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T12:00:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"ddd8888","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m30","phase":"QA","step":"QA","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"g1s","rc":0,"dur_s":10,"cost_usd":3.0,"moved":true,"gate":"fail","gate_why":"1 bug(s) with Status: open in the registry"}
{"v":1,"ts":"2026-08-31T12:01:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"ddd8888","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m30","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g2s","rc":0,"dur_s":10,"cost_usd":1.5,"moved":true,"pending_before":1,"pending_after":0,"increments_total":1,"gate":"pass","gate_why":"0 of 1 increment(s) still to execute"}
{"v":1,"ts":"2026-08-31T12:02:00-03:00","event":"gate_pass","run_id":"g1","invocation":"run","kit_sha":"ddd8888","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m30","phase":"QA"}
{"v":1,"ts":"2026-08-31T12:03:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"ddd8888","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m30","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"g3s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":0,"rounds_after":1,"rounds_max":3,"gate":"pass","gate_why":"40-review-r1.md: every criterion A"}
{"v":1,"ts":"2026-08-31T12:04:00-03:00","event":"session","run_id":"g2","invocation":"run","kit_sha":"ddd8888","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m31","phase":"QA","step":"QA","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"g4s","rc":0,"dur_s":10,"cost_usd":3.0,"moved":true,"gate":"fail","gate_why":"1 bug(s) with Status: open in the registry"}
EOF
# The control world is the SAME file with the one row cut out, so nothing else can explain a
# difference between the two readings.
grep -v '"event":"gate_pass"' "$OUTSIDE/gatepass/autonomy-log.jsonl" \
  > "$OUTSIDE/nogatepass/autonomy-log.jsonl"
GP_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/gatepass" "$SDD" kaizen --series 2>/dev/null )"
NOGP_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/nogatepass" "$SDD" kaizen --series 2>/dev/null )"
gp_label() { jq -r --arg m "$1" --arg p "$2" \
  '.latest.detail[] | select(.mission == $m and .phase == $p) | .label' <<< "$3"; }
# THE assertion of this increment, stated as the metric states it: `refez` stops being asserted.
assert_eq "a phase that closed without a session does not read refez" "true" \
  "$([ "$(gp_label m30 QA "$GP_OUT")" != "refez" ] && echo true || echo false)"
# ...and where it lands instead, so the assertion above cannot be satisfied by a rubric that
# stopped labelling anything at all. `leve`, not `ok`: the one session QA bought is churn by its
# own count, and that fact did not change.
assert_eq "and it lands on leve, because the surviving session is still churn" "leve" \
  "$(gp_label m30 QA "$GP_OUT")"
# THE REPRODUCTION, and it is the same file minus one row: without the recorded fact the very same
# QA phase reads `refez`. Any rubric that reaches the two lines above by some other route fails
# here, because this control has to keep answering `refez`.
assert_eq "the same phase without the recorded fact still reads refez" "refez" \
  "$(gp_label m30 QA "$NOGP_OUT")"
# The in-slice control: m31/QA has the SAME shape as m30/QA — one session, gate failed, moved —
# and no gate_pass row of its own. A phase whose gate never closed is still `refez`, in the world
# where the feature is ON. This is what keeps the clause from degenerating into "QA is never refez".
assert_eq "a phase whose gate never closed is still refez, in the same slice" "refez" \
  "$(gp_label m31 QA "$GP_OUT")"

# THE DIFFERENTIAL, and it is the heart of this increment: a new event in an enum documented as
# closed reaches 15 readers of `.event` in bin/sdd, and "13 of them select `session` explicitly and
# the other 2 are the is_escalation pair" is a measurement of SITES, never of behaviour. So the two
# series above are compared field by field with only `labels` allowed to differ. The five `excluded`
# buckets are in the comparison BY NAME and not by accident: `unrecognized > 0` is what the judge
# reads as a bug in the kit itself, so an event the series does not admit would make `sdd kaizen
# --series` accuse the runner that wrote it.
# ⚠️ `detail` is in the list, and it is the key that makes the assertion below deserve the word
# NOTHING. Without it the comparison was ten SLICE-level keys hand-picked by the same author as the
# writer — so it said "nothing else moved" while measuring a subset, and the new event reaches
# per-CELL fields that were outside it. Measured (r2 of 20260831-a-rodada-que-andou): teaching the
# cell to count a closure as a session (`sessions: map(select(.event == "session" or is_gate_pass))`
# in group_summary) left BOTH sensors green at rc 0 while `m30/QA` went from 1 session to 2 — a
# phase that bought one session reported as two, in the very cell the judge cites. An assertion
# that AFFIRMS more than it measures is the fail-open this file spends its floors refusing.
# `del(.label)` and not the whole cell: the label is the ONE thing the closure is supposed to move,
# and it is what the three assertions above already pin, name by name.
# ⚠️ `cost_usd` is compared IN CENTS, and that is a real jq subtlety rather than sloppiness. The sum
# is `map(.cost_usd // 0) | add`, so a closure in the group contributes a `0` — numerically inert,
# but `[3.0] | add` renders `3.0` while `[3.0, 0] | add` renders `3`. Same number, different text,
# and a comparison of JSON TEXT would have failed on the representation while the money was
# identical. Rounding to the cent states what this key means and compares the value.
gp_shape() { jq -Sc '{outcomes: .latest.outcomes, advance_rate: .latest.advance_rate,
                      moved_rate: .latest.moved_rate, cost_usd: .latest.cost_usd,
                      sessions: .latest.sessions, missions: .latest.missions,
                      composition: .latest.composition, escalations: .latest.escalations,
                      detail: (.latest.detail | map(del(.label) | .cost_usd |= (. * 100 | round))),
                      guard: .guard, excluded: .excluded}' <<< "$1"; }
assert_eq "the recorded fact moves the label and NOTHING else in the series" \
  "$(gp_shape "$NOGP_OUT")" "$(gp_shape "$GP_OUT")"
# ...and not by both being empty. The floor is this fixture's known numbers, so the equality above
# is about a series that actually said something.
assert_eq "that differential is not vacuous — the slice has its four sessions and its money" \
  '{"advanced":2,"churned":2,"idle":0} 9.5 4' \
  "$(jq -r '"\(.latest.outcomes | tojson) \(.latest.cost_usd) \(.latest.sessions)"' <<< "$GP_OUT")"
# Spelled out on its own, because it is the bucket with a CONSUMER: the judge is told to read
# `unrecognized > 0` as a kit bug. The differential above would also catch this, but only as one
# of ten fields, and this is the one whose failure has a name.
assert_eq "the recorded fact is not thrown away as unrecognized" "0" \
  "$(jq -r '.excluded.unrecognized' <<< "$GP_OUT")"
# `is_escalation` answers false, in the judge's program. A gate that PASSED is the opposite of an
# escalation, and a new event that fell into that pair would poison `escalations` — the map the
# judge cites first — with a row that says the line stopped when it did not.
assert_eq "is_escalation says no: a gate that passed is not an escalation" "{}" \
  "$(jq -c '.latest.escalations' <<< "$GP_OUT")"

# --- the closure is a POSITION, not a membership -----------------------------
# The ledger is append-only and the rubric groups over the WHOLE life of a (repo, mission, phase),
# not per run. Asked as `(map(select(is_gate_pass)) | length) == 0`, one recorded closure disabled
# the clause for ever: a closure written on lap 3 outvoted every failing session after it, and the
# runner cannot argue back — `gate_pass_logged` and `sessions` die with the process, so a phase that
# reopens and stays red writes no second row. Reproduced end to end on a real `sdd run`: QA closes
# for free, the REVIEW round reopens QA, and the sessions that follow fail with nobody spending a
# cent on the phase closing again.
#
# Every row here carries ONE kit_sha on purpose. That is the normal case in a target repo — the kit
# does not change during a run — so this was the common path, not an edge.
echo "== series: a closure does not outvote the sessions that came after it =="
mkdir -p "$OUTSIDE/gpafter"
localize > "$OUTSIDE/gpafter/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T12:00:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"aaa9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m50","phase":"QA","step":"QA","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"k1s","rc":0,"dur_s":10,"cost_usd":3.0,"moved":true,"gate":"fail","gate_why":"1 bug(s) with Status: open in the registry"}
{"v":1,"ts":"2026-08-31T12:01:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"aaa9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m50","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"k2s","rc":0,"dur_s":10,"cost_usd":1.5,"moved":true,"pending_before":1,"pending_after":0,"increments_total":1,"gate":"pass","gate_why":"0 of 1 increment(s) still to execute"}
{"v":1,"ts":"2026-08-31T12:02:00-03:00","event":"gate_pass","run_id":"g1","invocation":"run","kit_sha":"aaa9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m50","phase":"QA"}
{"v":1,"ts":"2026-08-31T12:03:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"aaa9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m50","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"k3s","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"rounds_before":0,"rounds_after":1,"rounds_max":3,"gate":"pass","gate_why":"40-review-r1.md: every criterion A"}
{"v":1,"ts":"2026-08-31T12:04:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"aaa9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m50","phase":"QA","step":"QA","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"k4s","rc":0,"dur_s":10,"cost_usd":7.0,"moved":true,"gate":"fail","gate_why":"1 bug(s) with Status: open in the registry"}
EOF
AFTER_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/gpafter" "$SDD" kaizen --series 2>/dev/null )"
# THE assertion: the phase reopened AFTER the closure and did not close again, so `refez` is the
# true reading. A rubric that asks "is there a closure anywhere in this group" answers `leve` here.
assert_eq "a closure does not outvote the sessions that came after it" "refez" \
  "$(jq -r '.latest.detail[] | select(.mission == "m50" and .phase == "QA") | .label' <<< "$AFTER_OUT")"
# The floor that stops the assertion above from being satisfied by a rubric that went back to
# calling everything `refez`: the REVIEW of the same slice closed and still reads `ok`.
assert_eq "floor: the phase that DID close in the same slice still reads ok" "ok" \
  "$(jq -r '.latest.detail[] | select(.mission == "m50" and .phase == "REVIEW") | .label' <<< "$AFTER_OUT")"
# ...and the other direction, in the same file: cut the trailing QA session and the very same
# closure DOES speak, because now it is the last word about the phase. The two readings differ by
# one row, so no rubric that reaches the assertion above by ignoring `gate_pass` survives here.
mkdir -p "$OUTSIDE/gpafter2"
grep -v '"session":"k4s"' "$OUTSIDE/gpafter/autonomy-log.jsonl" > "$OUTSIDE/gpafter2/autonomy-log.jsonl"
BEFORE_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/gpafter2" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "and with nothing after it the same closure still speaks" "leve" \
  "$(jq -r '.latest.detail[] | select(.mission == "m50" and .phase == "QA") | .label' <<< "$BEFORE_OUT")"

# --- the closure that landed in ANOTHER slice --------------------------------
# The fixture above is the TARGET-REPO shape: the kit does not change during the run, so the
# closure and the session it explains carry the same `kit_sha` and land in the same slice. In the
# repo that BUILDS the kit every session commits, so the sha advances between the phase that failed
# and the lap that closes it — the closure is stamped with a sha the failing session never had.
#
# The rubric grades one slice at a time, so in that world the closure arrives ALONE in its group:
# no escalation, no retry, and `map(select(.event == "session")) | last` is null. Every arm of
# phase_label is false and the `else` mints a phantom `ok` — a clean grade for a phase that spent
# nothing in this slice, in the histogram the judge is told to cite first. Measured before the
# filter in group_summary existed: `labels {ok: 2}` over a slice holding ONE session.
#
# Same shape, second world, no split sha needed: the failing session written with a dirty kit goes
# to `non_comparable` and the clean closure stays. That is why the assertion below is stated over
# the GROUP and not over the sha — it is the session-less group that is the defect, whatever put it
# there.
echo "== series: a closure alone in a slice mints no cell =="
mkdir -p "$OUTSIDE/gpsplit"
localize > "$OUTSIDE/gpsplit/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T12:00:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"eee1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m40","phase":"QA","step":"QA","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"h1s","rc":0,"dur_s":10,"cost_usd":3.0,"moved":true,"gate":"fail","gate_why":"1 bug(s) with Status: open in the registry"}
{"v":1,"ts":"2026-08-31T12:01:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"fff2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m40","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"h2s","rc":0,"dur_s":10,"cost_usd":1.5,"moved":true,"pending_before":1,"pending_after":0,"increments_total":1,"gate":"pass","gate_why":"0 of 1 increment(s) still to execute"}
{"v":1,"ts":"2026-08-31T12:02:00-03:00","event":"gate_pass","run_id":"g1","invocation":"run","kit_sha":"fff2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m40","phase":"QA"}
EOF
SPLIT_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/gpsplit" "$SDD" kaizen --series 2>/dev/null )"
# THE assertion: the QA group of the newer slice holds nothing but the closure, so it is not a cell.
# `empty` and not `"ok"` — a phase this slice never saw has no grade to give.
assert_eq "a closure alone in a slice mints no cell" "" \
  "$(jq -r '.latest.detail[] | select(.mission == "m40" and .phase == "QA") | .label' <<< "$SPLIT_OUT")"
# ...and the assertion above is not satisfied by a slice that lost every cell: the EXEC session
# that shares the sha with the closure is still graded, so the filter removed the phantom and only
# the phantom.
assert_eq "and the session that shares the slice is still graded" '{"ok":1,"leve":0,"refez":0} 1' \
  "$(jq -r '"\(.latest.labels | tojson) \(.latest.sessions)"' <<< "$SPLIT_OUT")"
# The floor that keeps the two assertions above from being about an empty reading: the older slice
# still carries the failing QA session. ⚠️ It reads `refez`, and that is the DECLARED limit rather
# than a promise broken — the closure is not in this slice and cannot speak for it. What this block
# forbids is the FALSE `ok`; moving this `refez` needs the closure to be readable across slices.
assert_eq "floor: the failing session is still in the older slice, still refez" "refez" \
  "$(jq -r '.previous.detail[] | select(.mission == "m40" and .phase == "QA") | .label' <<< "$SPLIT_OUT")"
# The arithmetic still closes over the row the filter dropped from the histogram: dropping a cell
# is not dropping a row, and a closure filed as `unrecognized` is the judge accusing the kit.
assert_eq "dropping the cell does not drop the row into unrecognized" "0" \
  "$(jq -r '.excluded.unrecognized' <<< "$SPLIT_OUT")"

# --- a closure never MINTS a version -----------------------------------------
# The other half of "a closure MODIFIES a cell, it never is the subject of one", and the half the
# `$detail` filter one block up cannot reach: that filter drops the phantom CELL, but the phantom
# `kit_sha` was still minting a VERSION, because `shas_in_file_order` ran over `$ok` and
# `comparable_row` admits a closure (`.event != "session"` short-circuits the `has("moved")` arm).
# So the axis the whole judge stands on grew an entry that observed nothing.
#
# THIS IS THE KIT REPO'S NORMAL CASE, not an edge, and that is what makes it expensive: every
# session here commits, so the sha ADVANCES between the phase that failed and the lap that closes
# it for free — the closure lands on a sha of its own by construction. Measured on the real reader
# before the fix, one added row: `latest.kit_sha` ccc3333 → ddd4444, `latest.sessions` 1 → 0,
# `latest.labels` {ok:1} → {ok:0,leve:0,refez:0}, `previous` bbb2222 → ccc3333, and
# `guard.degenerate_axis` true → false.
#
# WHAT THAT COSTS, downstream and reproduced: `gate_KAIZEN` computes its expected sha from
# `latest.kit_sha`, so a verdict already written stops satisfying the gate and `sdd kaizen` buys an
# opus session to judge a slice with ZERO sessions — a gate nobody can satisfy, which is the most
# expensive failure mode this repo has measured (CLAUDE.md, principle 1). And `kaizen_axis_note`
# goes silent in the one repository where its sentence is always true.
#
# THE ASSERTION IS DIFFERENTIAL — two ledgers, the outputs compared with each OTHER — because the
# claim is "the closure changes nothing about the axis". No fixture regime satisfies that by
# accident, and it fails whichever side moves. The three older `gate_pass` fixtures above all put
# the closure on the SAME sha as the sessions, which is exactly the control that shows nothing.
echo "== series: a closure does not mint a version of its own =="
mkdir -p "$OUTSIDE/mintwith" "$OUTSIDE/mintwithout"
localize > "$OUTSIDE/mintwith/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-03T09:00:00-03:00","event":"session","run_id":"r-m1","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":1,"pending_after":0,"increments_total":1,"gate":"pass","gate_why":"0 of 1 increment(s) still to execute"}
{"v":1,"ts":"2026-08-03T10:00:00-03:00","event":"session","run_id":"r-m2","invocation":"run","kit_sha":"bbb2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":1,"pending_after":0,"increments_total":1,"gate":"pass","gate_why":"0 of 1 increment(s) still to execute"}
{"v":1,"ts":"2026-08-03T10:30:00-03:00","event":"session","run_id":"r-m3","invocation":"run","kit_sha":"ccc3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"QA","step":"QA","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"journey walked"}
{"v":1,"ts":"2026-08-03T11:00:00-03:00","event":"gate_pass","run_id":"r-m3","invocation":"run","kit_sha":"ddd4444","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"QA"}
EOF
# The control is the SAME file minus the one row, so nothing but the closure can explain a
# difference between the two readings.
grep -v '"event":"gate_pass"' "$OUTSIDE/mintwith/autonomy-log.jsonl" \
  > "$OUTSIDE/mintwithout/autonomy-log.jsonl"
MINT_WITH="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/mintwith" "$SDD" kaizen --series 2>/dev/null )"
MINT_WITHOUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/mintwithout" "$SDD" kaizen --series 2>/dev/null )"
mint_axis() { jq -Sc '{latest: .latest.kit_sha, previous: .previous.kit_sha,
                       sessions: .latest.sessions, labels: .latest.labels,
                       degenerate: .guard.degenerate_axis}' <<< "$1"; }
# THE FLOOR, and it comes first: the control really did read a version with a session in it. Both
# sides going `null` would satisfy the differential by vacuity, which is the trap this file spends
# its floors refusing.
assert_eq "floor: without the closure the axis ends on the sha that bought the session" \
  '{"degenerate":true,"labels":{"leve":0,"ok":1,"refez":0},"latest":"ccc3333","previous":"bbb2222","sessions":1}' \
  "$(mint_axis "$MINT_WITHOUT")"
# THE assertion: the closure is invisible to the axis. Differential, so it fails whichever side moves.
assert_eq "a closure on a sha of its own changes nothing about the axis" \
  "$(mint_axis "$MINT_WITHOUT")" "$(mint_axis "$MINT_WITH")"
# The row is not thrown away to buy that — dropping a version is not dropping a row, and a closure
# filed as `unrecognized` would be the judge accusing the kit of writing something it cannot read.
assert_eq "and the row is still read, not filed as unrecognized" "0" \
  "$(jq -r '.excluded.unrecognized' <<< "$MINT_WITH")"

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
# Five sessions across two repositories, plus ONE row that names no project at all — the shape the
# judge's widening deliberately does NOT admit.
{ ledger_row "$RA" a1; ledger_row "$RB" b1; ledger_row "$RA" a2
  ledger_row "$RB" b2; ledger_row "$RB" b3; ledger_row "" x1; } \
  > "$OUTSIDE/tworepos/autonomy-log.jsonl"

# ⚠️ This section used to assert the OPPOSITE, and it was right until ADR 0005: `sdd kaizen
# --series` filtered per repo, and these lines demanded that each repo see only its own missions.
# Part 1 reverses that decision for the JUDGE and only for the judge — ADR 0003 says verdict
# evidence comes from real target repos, and the per-repo default kept the judge looking at exactly
# the one repo 0003 declared unusable. The assertions moved with the decision instead of the
# decision being left to rot behind a green assertion; the per-repo reading did not disappear, it
# stayed where its question lives, which is what the differential at the bottom pins.
SERIES_A="$( cd "$RA" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
SERIES_B="$( cd "$RB" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
missions_of() { jq -r '[.latest.detail[].mission] | sort | join(",")' <<< "$1"; }
# The strongest form the property has: BYTE FOR BYTE the same answer from either repo. The judge's
# question is about a kit version, not about where the human is standing, and a comparison of the
# two readings with each other admits no fixture regime that satisfies it by accident — under the
# per-repo filter the two differ in `detail`, in `guard` and in `excluded` at once.
assert_eq "the judge answers the same series from either repo" "same" \
  "$( [ "$SERIES_A" = "$SERIES_B" ] && echo same || echo differ )"
# ...and the answer is the WHOLE file, not the empty intersection: without this, a reader that
# returned nothing anywhere would satisfy the identity above.
assert_eq "and it is every mission in the file, not the empty set they share" "a1,a2,b1,b2,b3" \
  "$(missions_of "$SERIES_A")"
# Nothing is foreign to the judge any more. Counted from both sides, because a reader that emptied
# only one bucket would still be reporting a filter it no longer applies.
assert_eq "nothing leaves as another repo's, read from either side" "0/0" \
  "$(printf '%s/%s' "$(jq -r '.excluded.other_repo' <<< "$SERIES_A")" \
                    "$(jq -r '.excluded.other_repo' <<< "$SERIES_B")")"
# The half that did NOT move, and it is the one that keeps the widening honest: widening the
# question BETWEEN projects is not the same as admitting rows that belong to none. A row naming no
# repo is unattributable in every scope, so it still leaves — through its own bucket, counted.
assert_eq "a row that names no project is still excluded, in its own bucket" "1/5" \
  "$(printf '%s/%s' "$(jq -r '.excluded.no_repo' <<< "$SERIES_A")" \
                    "$(jq -r '.guard.sessions' <<< "$SERIES_A")")"
# Standing in no repository at all the cwd decides nothing, so the judge answers the same series it
# answers from inside either repo. Before ADR 0005 this was the empty series plus a warning, and
# that was the safe direction WHILE the reading was per repo: an empty series is
# `sufficient: false` and supports only `indeterminado`. With one reading there is nothing for the
# cwd to be safe about.
mkdir -p "$OUTSIDE/anywhere"
SERIES_NOWHERE="$( cd "$OUTSIDE/anywhere" \
  && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "read from outside any git repository the judge answers the same series" "same" \
  "$( [ "$SERIES_NOWHERE" = "$SERIES_A" ] && echo same || echo differ )"

# --- ...and the per-repo reading is still there, where its question lives ----
# THE DIFFERENTIAL, and it is what stops all of the above from reading as "the filter was deleted".
# ADR 0005 moves the JUDGE and leaves `sdd autonomy` alone, because that command's question really
# is "what did THIS repo cost". One file, two commands, two answers — asserted against each other
# rather than each against a literal, so neither can drift into the other's behaviour unnoticed.
AUTO_A="$( cd "$RA" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy 2>&1 )"
AUTO_B="$( cd "$RB" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy 2>&1 )"
# One grep, nothing piped after it, no `-m1`: the first is this repo's SIGPIPE trap (a writer whose
# reader exits early returns 141 under pipefail) and the second is the same family one letter
# apart. The first line and the leading number are taken with bash's own expansions instead.
foreign_rows() {
  local m; m="$(grep -oE '[0-9]+ row\(s\) excluded: born in another repo' <<< "$1" || true)"
  m="${m%%$'\n'*}"; m="${m%% *}"
  printf '%s' "${m:-0}"
}
assert_eq "sdd autonomy still reads per repo: each side excludes the other's rows" "3/2" \
  "$(printf '%s/%s' "$(foreign_rows "$AUTO_A")" "$(foreign_rows "$AUTO_B")")"

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
# agents/ too: since the hat's boundary run_phase refuses a kit whose hats are missing, before
# any session — and `sdd install` below mirrors them into .claude/agents/ as a real install does.
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$ROOT/agents" "$FIX/"
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

echo "== the judge's own session is measured against the disk =="
# cmd_kaizen carries a THIRD copy of `[ "$before" != "$after" ] && moved="true"` — cmd_run has one
# at four spaces, cmd_retry and cmd_kaizen one each at two, byte for byte the same line. The retry's
# was covered by check-autonomy.sh the day the moving stub was written for it; the judge's never
# was, because every kaizen fixture in this file runs the DEAD stub, which does not touch the repo.
# So `moved` was "false" in every row the judge has ever written, and replacing the line with a
# no-op changed nothing anybody measured. It is not cosmetic: `moved` IS the waste metric — a judge
# pinned to false files every kaizen session as waste and feeds the next verdict a loop that never
# progressed, while a judge pinned to true hides a session that did nothing at all.
#
# The stub writes into the kaizen mission directory, which is what the real judge does and what
# state_fingerprint reads, on its FIRST call only. The retry that follows finds nothing left to
# change, so ONE world yields both rows and the pair is differential: a hardcoded `true` fails on
# the second, a hardcoded `false` on the first, and no regime of this fixture satisfies both.
#
# A STATE DIRECTORY OF ITS OWN, seeded from the ledger the gate section wrote: the rows below would
# otherwise land in the ledger every later scenario reads, and the session that moves the disk
# leaves the kit tree dirty while it runs — `kit_dirty` rows are exactly what the comparability
# filter drops. Isolated, this block cannot move a single number the blocks after it assert.
KSTATE="$OUTSIDE/kaizenmoved"
mkdir -p "$KSTATE"
cp "$LEDGER" "$KSTATE/autonomy-log.jsonl"
KMARK="$OUTSIDE/kaizen-moved-once"
rm -f "$KMARK"
# The marker lives OUTSIDE the repo under test, the same decision check-autonomy.sh pins with an
# assertion of its own: a marker inside would be part of the fingerprint it is there to control.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$KMARK" ]; then
  : > "$KMARK"
  d="$FIX/docs/handoffs/\$(date +%Y%m%d)-kaizen"
  mkdir -p "\$d"
  printf 'the judge left a note\n' > "\$d/notes.md"
fi
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"
( cd "$FIX" && SDD_STATE_DIR="$KSTATE" "$KSDD" kaizen >/dev/null 2>&1 )
assert_eq "covered: the judge's session records moved:true, and its retry moved:false" "true false" \
  "$(jq -rs '[.[] | select(.phase == "KAIZEN" and .event == "session")] | .[-2:] | map(.moved | tostring) | join(" ")' "$KSTATE/autonomy-log.jsonl")"
# Back to the world every later block expects: the dead stub, and a clean tree — the note the
# judge left is untracked, and `git add -A` two blocks down would commit it into the fixture kit.
rm -rf "$FIX/docs/handoffs/"*-kaizen
dead_stub

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

echo "== reminder: outside the kit it tells the truth about the judge =="
# The reminder counts THIS repo's missions and then used to send every reader, from every repo, to
# `sdd kaizen` in the kit — a judge that reads a different set of numbers entirely. In a target
# repo the human opens the kit, runs the command, and is told something about the kit's own
# missions that has nothing to do with the run that just finished.
#
# A SECOND kit checkout is the whole fixture, so SDD_HOME resolves somewhere else while the repo
# under the runner — and therefore the ledger rows, the series and every number in it — stays
# byte for byte the one the assertions above just measured. One `cp` apart: a differential, not a
# second world, so whichever side regresses the other is standing next to it.
KIT2="$OUTSIDE/kit2"
mkdir -p "$KIT2/bin"
cp "$ROOT/bin/sdd" "$KIT2/bin/sdd"
( cd "$KIT2" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && git add -A && git commit -qm "init the second kit checkout" ) >/dev/null 2>&1

out="$( cd "$FIX" && "$KIT2/bin/sdd" run 20260102-donemission 2>&1 )"; rc=$?
assert_eq "outside the kit the pipeline still completes (rc 0)" "0" "$rc"
# ⚠️ This used to demand the words "reads only the kit's own missions", and that sentence was true
# when it was written and became FALSE with ADR 0005 part 1: the judge reads every repo now, and
# ADR 0003 says a target repo's rows are exactly the evidence a verdict should rest on. So the
# reminder points at the judge instead of warning the human away from it, and the assertion moved
# with the fact rather than the fact being left to rot behind a green assertion.
assert_eq "outside the kit the reminder tells the truth about the judge" "yes" \
  "$(grep -q 'The kaizen judge counts them' <<< "$out" && echo yes || echo no)"
# The other half, the house rule: the text of the right branch AND the absence of the wrong one.
# Without it the assertion above passes on a runner that prints both lines — which is exactly what
# mut_KAIZEN_reminder_wrong_repo makes it do. The tell can no longer be "does it name sdd kaizen"
# (both branches do now, correctly), so it is the kit branch's own tail: only the reading taken
# from INSIDE the kit can promise the next kit mission plan.
assert_eq "and it does not answer with the kit branch's sentence" "no" \
  "$(grep -q 'for the next kit mission plan' <<< "$out" && echo yes || echo no)"
# No flag in the sentence: on the judge `--all-repos` decides nothing since ADR 0005, so naming it
# would send the human to type an option that changes no number.
assert_eq "and it promises no --all-repos, which decides nothing on the judge" "no" \
  "$(grep -q -- '--all-repos' <<< "$out" && echo yes || echo no)"

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
assert_eq "and carries the turn rule the other six phases read from the same definition" "yes" \
  "$(grep -q 'Never end the turn with a command' <<< "$out" && echo yes || echo no)"
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

# --- ...and the predicate has more clauses than two fixtures can see ---------
# A sabotage pass over the clauses of `degenerate_axis` and over the guard of `kaizen_axis_note`
# found FOUR degrades that stayed green on the fixtures above — one of them printing "the kit_sha
# axis is degenerate here" about a healthy target repo, which is the exact misreading ADR 0003 was
# written to prevent, arriving from the runner's own mouth. Each degrade gets the fixture that
# separates it. All of these are deliberately OUTSIDE the `degenerate axis` prefix: the checkpoint
# Check counts exactly the two assertions above, with `-c`.
axis_row() {   # axis_row <kit_sha> <mission> <session|blocked> — one on-axis row for THIS repo
  jq -cn --arg sha "$1" --arg mission "$2" --arg ev "$3" --arg repo "$FIXROOT" \
    'if $ev == "session"
     then {v:1, ts:"2026-08-16T18:00:00-03:00", event:"session", run_id:"x", invocation:"run",
           kit_sha:$sha, kit_dirty:false, project:"p", repo:$repo, mission:$mission,
           phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
           auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
           gate:"pass", gate_why:"x"}
     else {v:1, ts:"2026-08-16T18:00:00-03:00", event:"blocked", run_id:"x", invocation:"run",
           kit_sha:$sha, kit_dirty:false, project:"p", repo:$repo, mission:$mission,
           phase:"EXEC", kind:"increment-blocked", gate_why:"x"}
     end'
}
# axis_case <name> < rows -> "<guard.degenerate_axis>/<note printed: yes|no>/<guard.sufficient>"
# All three read from ONE fixture, because the interesting degrades move one of them and not the
# others: a field with no sentence explains nothing, a sentence with no field is the runner having
# an opinion, and `sufficient` is the question the note guard was interchangeable with.
axis_case() {
  local d="$OUTSIDE/axis-$1"; mkdir -p "$d"; cat > "$d/autonomy-log.jsonl"
  local s o
  s="$( cd "$FIX" && SDD_STATE_DIR="$d" "$KSDD" kaizen --series  2>/dev/null )"
  o="$( cd "$FIX" && SDD_STATE_DIR="$d" "$KSDD" kaizen --dry-run 2>&1 )"
  # The FOURTH field is the anti-vacuity floor, and it is not decoration: an empty ledger reads
  # `false/no/false`, which is exactly the expected string of four of the assertions below — measured,
  # stubbing `axis_row` to write nothing left those four GREEN. The session count witnesses that the
  # runner actually read the fixture, so "no rows" can no longer impersonate "the rule holds".
  printf '%s/%s/%s/%s' \
    "$(jq -r '.guard.degenerate_axis' <<< "$s")" \
    "$( if grep -q 'kit_sha axis is degenerate' <<< "$o"; then echo yes; else echo no; fi )" \
    "$(jq -r '.guard.sufficient' <<< "$s")" \
    "$(jq -r '[.latest.sessions, .previous.sessions] | map(. // 0) | add' <<< "$s")"
}

# `all` -> `any`. One version that bought three sessions beside one that bought a single session is
# an axis WORKING and merely young. Under `any` it reads degenerate, and the runner tells the human
# to stop waiting for missions that are in fact arriving.
# `sufficient` reads $latest, which here is the QUIET version (file order), so it is false — the
# floor speaks about the newest kit version, never about the busiest one.
assert_eq "axis clause: one busy kit version beside a quiet one is not a degenerate axis" \
  "false/no/false/4" \
  "$( { axis_row s000a01 q1 session; axis_row s000a01 q2 session; axis_row s000a01 q3 session
        axis_row s000a02 q4 session; } | axis_case any )"

# `== 1` -> `<= 1`. A version whose rows are all escalations bought ZERO sessions, and zero is not
# one: nothing was OBSERVED on that version, which is a different silence with a different remedy.
assert_eq "axis clause: a kit version that bought no session at all is not one that bought a session" \
  "false/no/false/1" \
  "$( { axis_row s000b01 q1 session; axis_row s000b02 q2 blocked; } | axis_case zero )"

# `map(select(.event == "session")) | length` -> `length`. A version that bought one session AND
# escalated has still bought exactly one session; counting ROWS makes the slice read as two and the
# explanation disappears with nothing saying so — the silent direction, which is the expensive one.
assert_eq "axis clause: a session with an escalation beside it is still one session" \
  "true/yes/false/2" \
  "$( { axis_row s000c01 q1 session; axis_row s000c01 q1 blocked
        axis_row s000c02 q2 session; } | axis_case escal )"

# The window, and its control: two fixtures of FOUR versions and FIVE sessions that differ only in
# WHICH version got the second session. Over the whole history this was a one-way switch — the
# ledger is append-only, so one ancient version that happened to buy two sessions turned the
# explanation off forever and nothing about today could turn it back on. The pair is what makes it a
# window rather than a blanket: outside it the second session must not matter, inside it must.
assert_eq "axis window: an ancient version with two sessions does not silence what the recent ones say" \
  "true/yes/false/2" \
  "$( { axis_row s000d01 q1 session; axis_row s000d01 q2 session
        axis_row s000d02 q3 session; axis_row s000d03 q4 session
        axis_row s000d04 q5 session; } | axis_case window )"
assert_eq "axis window: but a RECENT version with two sessions does silence it — same rows, one moved" \
  "false/no/false/3" \
  "$( { axis_row s000d01 q1 session
        axis_row s000d02 q3 session; axis_row s000d03 q4 session
        axis_row s000d04 q5 session; axis_row s000d04 q2 session; } | axis_case windowctl )"

# ...and the window needed a second clause, because ON ITS OWN it traded one wrong answer for
# another. The field claims "the axis cannot work HERE", and a quiet stretch is not a broken axis:
# with the window alone, a repo whose history reached the floor TWICE and then went three versions
# quiet answered `true`, and the runner told its human to stop waiting for missions that were
# arriving. Measured before the fix, on the first fixture below.
#
# DIFFERENTIAL, and the two fixtures differ in ONE fact: whether the busy versions reached the floor
# (3 missions apiece) or stopped one short of it (2). Same version count, same session count, same
# quiet tail, same `sufficient`. Drop the clause and BOTH read `true`, so the first goes red; make it
# too strong and the second stops explaining a genuinely degenerate axis, so the second goes red.
# Neither fixture can satisfy its own assertion by the other's regime — which is the only way this
# pair could pass without measuring the rule.
assert_eq "axis reach: a repo whose own history reached the floor has a WORKING axis, quiet stretch or not" \
  "false/no/false/2" \
  "$( { axis_row s000e01 q1 session; axis_row s000e01 q2 session; axis_row s000e01 q3 session
        axis_row s000e02 q4 session; axis_row s000e02 q5 session; axis_row s000e02 q6 session
        axis_row s000e03 q7 session; axis_row s000e04 q8 session
        axis_row s000e05 q9 session; } | axis_case reach )"
assert_eq "axis reach: but a history that never once reached it is degenerate, and the runner says so" \
  "true/yes/false/2" \
  "$( { axis_row s000f01 q1 session; axis_row s000f01 q2 session
        axis_row s000f02 q4 session; axis_row s000f02 q5 session
        axis_row s000f03 q7 session; axis_row s000f04 q8 session
        axis_row s000f05 q9 session; } | axis_case reachctl )"

# The unit of the window is MISSIONS, not sessions, because the floor it explains is
# `missions_with_session >= 3`. The two disagree on exactly one row shape, and it is a shape the
# runner writes by itself: two sessions belonging to the SAME mission on one kit version — an in-loop
# auto retry, or a second `sdd run` over a phase that neither commits nor dirties the kit tree. The
# floor is as unsatisfiable as before (one mission), and counting sessions read `2`, turned the field
# `false` and took the sentence away with it. Measured before the fix: `missions_with_session: 1`,
# `sufficient: false`, `degenerate_axis: false`, sentence printed zero times — a human told nothing,
# waiting for missions that cannot help.
#
# Its control is the `windowctl` case above: two sessions of TWO missions on the newest version is
# genuinely `false`. Same session count, same version count — only the mission count differs, so
# neither case can pass in the other's regime, and the session-unit spelling fails THIS one.
assert_eq "axis unit: two sessions of ONE mission on a version is still one mission, and still degenerate" \
  "true/yes/false/3" \
  "$( { axis_row s000g01 q1 session; axis_row s000g02 q2 session
        axis_row s000g03 q3 session; axis_row s000g03 q3 session; } | axis_case unit )"

# ...and the window is the last versions in FILE order, which is what makes it mean "recent" at all.
# That property was load-bearing and unprobed: `shas_in_file_order | sort` inside the window left
# BOTH sensors green (rc 0, zero FAILs, measured), because every fixture that reaches the window
# happened to use shas whose lexical order equals their file order. Under the degrade this very
# ledger reads `false` — the ancient version silencing what the recent ones say, which is N8 verbatim
# with the suite green.
#
# Descending on purpose, and that is the whole point: lexically `zzz0001` sorts LAST, so any sort or
# reverse inside the window drags it in and its two missions break the clause. Paired with the two
# ascending `axis window` cases above, the three pin recency to file order and to nothing else.
assert_eq "axis order: recency is FILE order — an ancient version that sorts last is still ancient" \
  "true/yes/false/2" \
  "$( { axis_row zzz0001 q1 session; axis_row zzz0001 q2 session
        axis_row aaa0002 q3 session; axis_row aaa0003 q4 session
        axis_row aaa0004 q5 session; } | axis_case order )"

# The guard of `kaizen_axis_note` asks `degenerate_axis == true`, and `sufficient == false` was
# INTERCHANGEABLE with it across every fixture above: the degenerate one is also insufficient, the
# healthy one is also sufficient. This is the third case that pulls them apart — a healthy target
# axis still below the floor (two versions, two missions each). Swapped, the runner announces "the
# kit_sha axis is degenerate here" about a repo where waiting is exactly the right advice, which is
# the wrong reading ADR 0003 exists to forbid, printed by the instrument that was built to prevent it.
assert_eq "axis note: a healthy axis below the floor is insufficient WITHOUT being degenerate, and the runner stays quiet" \
  "false/no/false/4" \
  "$( { axis_row s000f01 q1 session; axis_row s000f01 q2 session
        axis_row s000f02 q3 session; axis_row s000f02 q4 session; } | axis_case note )"

# --- ...and a mission is a mission of a REPO, not a slug ---------------------
# Every count in the series keyed off the bare mission slug. A no-op while the reader was confined
# to one repo, and a defect the moment `--all-repos` opened it: slugs are dated (`YYYYMMDD-<name>`)
# and cmd_kaizen itself mints `$(date +%Y%m%d)-kaizen`, identical in every repo on the same day.
#
# DIFFERENTIAL over two ledgers that differ in exactly one character of one slug — three repos, one
# session each, one kit version. Colliding, the floor used to read 2 and `guard.sufficient` flipped
# to false, and one project's `refez` swallowed another project's clean `ok` into a single group: a
# verdict about the kit decided by a slug coincidence. Both halves matter — the label tally is what
# shows the two missions were really FUSED and not merely miscounted.
collide_row() {   # collide_row <repo> <mission> <gate>
  jq -cn --arg repo "$1" --arg mission "$2" --arg gate "$3" \
    '{v:1, ts:"2026-08-17T10:00:00-03:00", event:"session", run_id:"c", invocation:"run",
      kit_sha:"e000001", kit_dirty:false, project:"p", repo:$repo, mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
      gate:$gate, gate_why:"x"}'
}
collide_case() {   # collide_case <name> < rows -> "<missions_with_session> <sufficient> <labels>"
  local d="$OUTSIDE/collide-$1"; mkdir -p "$d"; cat > "$d/autonomy-log.jsonl"
  ( cd "$FIX" && SDD_STATE_DIR="$d" "$KSDD" kaizen --series --all-repos 2>/dev/null ) \
    | jq -r '[(.guard.missions_with_session | tostring), (.guard.sufficient | tostring),
              (.latest.labels | tojson)] | join(" ")'
}
assert_eq "mission key: two projects that ran the SAME slug are two missions, and neither label eats the other" \
  '3 true {"ok":2,"leve":0,"refez":1}' \
  "$( { collide_row /c1 20260817-kaizen pass; collide_row /c2 20260817-kaizen fail
        collide_row /c3 20260817-other pass; } | collide_case same )"
# The control: the same three rows with DISTINCT slugs must read identically. Without it, a key that
# simply stopped grouping (one group per row) would satisfy the line above and break every other
# count in the file quietly.
assert_eq "mission key: and with distinct slugs the reading is the same — the repo in the key changed nothing else" \
  '3 true {"ok":2,"leve":0,"refez":1}' \
  "$( { collide_row /c1 20260817-a pass; collide_row /c2 20260817-b fail
        collide_row /c3 20260817-other pass; } | collide_case distinct )"
# The key is an ARRAY, and these are the two things a joined string got wrong. A separator inside a
# value collides: repo `a|b` + mission `c` and repo `a` + mission `b|c` joined to one key and read
# as ONE mission — measured on the first spelling of this very fix. And `+` on a value that is not
# a string makes jq DIE, so one hand-edited row with a numeric `repo` returned the judge nothing at
# all and took `sdd autonomy` down with `malformed row`. Neither is exotic: `|` is legal in a path,
# and reporting corruption is what the excluded buckets are for — dying is not reporting.
inject_row() {   # inject_row <repo as raw JSON> <mission as raw JSON>
  jq -cn --argjson repo "$1" --argjson mission "$2" \
    '{v:1, ts:"2026-08-17T11:00:00-03:00", event:"session", run_id:"i", invocation:"run",
      kit_sha:"f000001", kit_dirty:false, project:"p", repo:$repo, mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
      gate:"pass", gate_why:"x"}'
}
assert_eq "mission key: a separator inside a repo path does not fuse two missions into one" "2" \
  "$( { inject_row '"/a|b"' '"c"'; inject_row '"/a"' '"b|c"'; } \
      | { d="$OUTSIDE/collide-inject"; mkdir -p "$d"; cat > "$d/autonomy-log.jsonl"
          ( cd "$FIX" && SDD_STATE_DIR="$d" "$KSDD" kaizen --series --all-repos 2>/dev/null ) \
            | jq -r '.latest.missions'; } )"
# The claim here is SURVIVAL, not exclusion: a row whose `repo` is not a string still names
# something, so it is counted rather than dropped, and what must never happen is the reader dying
# over it. Under the joined-string key `5 + "|"` was a fatal jq error — the series came back with
# nothing in it and `sdd autonomy` died with `malformed row`, so ONE hand-edited row silenced both
# instruments. The pair is the witness of that: a readable series AND a reader that exits 0.
assert_eq "mission key: a row whose repo is not a string is counted, and never fatal to either reader" \
  "1 0" \
  "$( d="$OUTSIDE/collide-type"; mkdir -p "$d"
      inject_row '5' '"m"' > "$d/autonomy-log.jsonl"
      s="$( cd "$FIX" && SDD_STATE_DIR="$d" "$KSDD" kaizen --series --all-repos 2>/dev/null )"
      ( cd "$FIX" && SDD_STATE_DIR="$d" "$KSDD" autonomy --all-repos >/dev/null 2>&1 ); r=$?
      printf '%s %s' "$(jq -r '.guard.sessions' <<< "${s:-null}" 2>/dev/null || echo DIED)" "$r" )"

# =============================================================================
# series: the composition of the axis slice (ADR 0005, part 2)
# =============================================================================
# Pointing the judge at every repo in the ledger is safe only because the MIXTURE becomes visible.
# A verdict resting on rows from a throwaway clone is a verdict about nothing, and under a silent
# filter nobody could tell — so the series publishes how many missions each repo contributed to
# the slice it read. It is the rule this repo applies everywhere else: a number without the
# composition beside it is a label, and the first principle refuses labels.
#
# ⚠️ Derived over the rows the GUARD ADMITS and never over `event: session`. That is the mistake
# the first draft of ADR 0005 made and left written inside itself: counted over sessions it
# answered "four repos" over a ledger holding seven, because three of the seven contribute
# escalations only. A composition counted that way under-reports exactly the repos it exists to
# expose, which is worse than not having one.
#
# BOTH numbers are published, because the guard reads two: `missions_after_change` counts every
# admitted mission and `missions_with_session` is what the FLOOR gates on. Each sum closes against
# its own field, which is what makes this an explanation of the guard rather than a second set of
# numbers standing beside it.
echo "== series: the composition of the axis slice =="

mkdir -p "$OUTSIDE/comp"
# Repo paths as LITERALS and not as localized fixture roots: under the cross-repo reading a repo is
# a string the readers compare, nothing is resolved on disk, and a literal keeps the expectation
# below readable instead of an absolute temp path nobody can check by eye. Two kit versions in file
# order so `previous` is a real slice and the last assertion is not satisfied by a null.
#   bbb0000  /repo-alpha m0 session                          -> previous: alpha 1/1
#   ccc0001  /repo-alpha m1 session, /repo-alpha m2 blocked,
#            /repo-beta  m3 session, /tmp/throwaway-clone m4 blocked
#                                                            -> latest:   4 missions, 2 with a session
cat > "$OUTSIDE/comp/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-19T10:00:00-03:00","event":"session","run_id":"b1","invocation":"run","kit_sha":"bbb0000","kit_dirty":false,"project":"alpha","repo":"/repo-alpha","mission":"c-m0","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s0","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:00:00-03:00","event":"session","run_id":"c1","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"alpha","repo":"/repo-alpha","mission":"c-m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"c2","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"alpha","repo":"/repo-alpha","mission":"c-m2","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:02:00-03:00","event":"session","run_id":"c3","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"beta","repo":"/repo-beta","mission":"c-m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:03:00-03:00","event":"blocked","kind":"budget-exhausted","run_id":"c4","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"throwaway","repo":"/tmp/throwaway-clone","mission":"c-m4","phase":"REVIEW","gate_why":"x"}
EOF

COMP_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/comp" "$KSDD" kaizen --series --all-repos 2>/dev/null )"
comp() { jq -r "$1" <<< "$COMP_OUT"; }

# Every repo of the slice, each with its own pair of numbers, as ONE string: a composition that
# dropped a repo, merged two of them, or counted the wrong unit moves this assertion.
assert_eq "composition: every repo of the slice, with missions and missions-with-a-session" \
  "/repo-alpha 2 1|/repo-beta 1 1|/tmp/throwaway-clone 1 0" \
  "$(comp '[.latest.composition[] | "\(.repo) \(.missions) \(.missions_with_session)"] | join("|")')"
# The load-bearing one. Counted over `event: session` the throwaway repo DISAPPEARS, and the field
# would report a clean two-repo slice over a ledger holding three — the ADR's own first draft.
assert_eq "composition: a repo that only ESCALATED is still in it" "1" \
  "$(comp '[.latest.composition[] | select(.repo == "/tmp/throwaway-clone")] | length')"
# The arithmetic closes on BOTH numbers against the guard's own two. This is what makes the
# composition an explanation of the guard instead of a second opinion beside it.
assert_eq "composition: the two sums are the guard's two numbers" "4/2 4/2" \
  "$(comp '"\([.latest.composition[].missions] | add)/\([.latest.composition[].missions_with_session] | add) \(.guard.missions_after_change)/\(.guard.missions_with_session)"')"
# `previous` carries one too, and it is asserted by VALUE and not by `has`: the judge compares two
# slices, and a composition on only one of them explains half of the comparison. A `previous` that
# came back null would satisfy a presence test and prove nothing.
assert_eq "composition: previous carries its own, over its own rows" \
  "/repo-alpha 1 1" \
  "$(comp '[.previous.composition[] | "\(.repo) \(.missions) \(.missions_with_session)"] | join("|")')"

# --- ...and the human is shown it, not merely offered it --------------------
# The series holds the contract and the judge reads it there. This is the half a human actually
# reads, and it is the half that makes "contamination is visible" true rather than available.
# Asserted by the repos NAMED and by how many lines the block has — never by its wording, which
# gets rewritten.
COMP_TTY="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/comp" "$KSDD" kaizen --dry-run --all-repos 2>&1 )"
assert_eq "composition: the human is shown which repos the slice came from" "3" \
  "$(grep -c 'mission(s), .* with a session' <<< "$COMP_TTY")"
assert_eq "composition: including the throwaway one, by name" "yes" \
  "$(grep -q '/tmp/throwaway-clone' <<< "$COMP_TTY" && echo yes || echo no)"

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

# =============================================================================
# one series behind the verdict — the gate and the prompt may never read two
# =============================================================================
# ADR 0001 splits the judge: the runner derives the numbers, the agent gives the verdict CITING
# them. That split only holds while both halves read the SAME series. `gate_KAIZEN` reads it by
# calling kaizen_series in-process, so every ledger option the invocation carries reaches it; the
# KAIZEN boot prompt hands the agent a WRITTEN command line, so an option only reaches it if
# someone wrote it there. `--all-repos` reaches the first and not the second.
#
# The consequence is not cosmetic and not a wrong number — it is an UNSATISFIABLE phase. The
# prompt orders `kit_sha_judged:` to be "the series' latest kit_sha"; the gate then hunts for a
# verdict whose kit_sha_judged equals the latest of ITS series. Two series, two latests, no
# verdict the agent can write that the gate will accept: gate fails, the runner retries once, the
# second session writes the same sha, and cmd_kaizen ends in `BLOCKED in KAIZEN — no-progress`.
# Two opus sessions bought a blocked row. Found by sdd-qa walking `sdd kaizen --all-repos` in
# mission 20260817-eixo-do-juiz, the mission that introduced the flag.
#
# DIFFERENTIAL, and the two halves are not interchangeable: the flagged reading is the regression,
# the bare reading is the control that a fix cannot satisfy by refusing everything (hardcoding one
# series into both halves would pass the first and fail the second). The fixture puts the two
# series in the regime where they DISAGREE — a same-latest ledger would let the broken code pass
# by accident, which is the whole reason the witness below is asserted first.
echo "== one series behind the verdict =="
mkdir -p "$OUTSIDE/judgeother" "$OUTSIDE/judgesplit"
( cd "$OUTSIDE/judgeother" && git init -q -b main )
JOTHER="$( cd "$OUTSIDE/judgeother" && git rev-parse --show-toplevel )"
# Same shape as ledger_row above; kit_sha and ts are what this section varies. Three missions a
# side, so `guard.sufficient` is true in BOTH readings and no assertion here can be satisfied by
# an insufficient guard forcing `indeterminado` for the wrong reason.
split_row() {   # split_row <repo> <mission> <kit_sha> <ts>
  jq -cn --arg repo "$1" --arg mission "$2" --arg sha "$3" --arg ts "$4" \
    '{v:1, ts:$ts, event:"session", run_id:"r1", invocation:"run",
      kit_sha:$sha, kit_dirty:false, project:"p", repo:$repo, mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
      gate:"pass", gate_why:"x"}'
}
# The kit's own rows come FIRST in file order and the other repo's LAST, because `latest` is
# picked by file order: that is what makes the two readings land on different shas.
{ split_row "$FIXROOT" j1 qqq1111 2026-08-10T10:00:00-03:00
  split_row "$FIXROOT" j2 qqq1111 2026-08-10T11:00:00-03:00
  split_row "$FIXROOT" j3 qqq1111 2026-08-10T12:00:00-03:00
  split_row "$JOTHER"  o1 zzz9999 2026-08-16T10:00:00-03:00
  split_row "$JOTHER"  o2 zzz9999 2026-08-16T11:00:00-03:00
  split_row "$JOTHER"  o3 zzz9999 2026-08-16T12:00:00-03:00
} > "$OUTSIDE/judgesplit/autonomy-log.jsonl"

# judge_sha <flags...> — the sha the AGENT would write: run the very command the boot prompt hands
# it, whatever that command turns out to be. Executing the prompt's own line instead of a line
# this test composed is the point: a test that rebuilt the command from its own idea of the flags
# would agree with itself no matter what the runner wrote.
judge_prompt_sha() {
  local out line
  out="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/judgesplit" "$KSDD" kaizen --dry-run "$@" 2>&1 )"
  # The `│`-prefixed block is the human-readable projection of the same prompt; the escaped
  # `claude -p $'...'` form above it carries literal \n and is not runnable as-is.
  line="$( grep -m1 '^  │ *1\. run: ' <<< "$out" )"
  [ -n "$line" ] || { printf 'PROBE-BROKEN-no-prompt\n'; return 0; }
  line="${line#*run: }"
  # Run it where the AGENT would: same cwd and same SDD_STATE_DIR the runner itself held when it
  # wrote the prompt. This file exports SDD_STATE_DIR globally for the sections above, so an eval
  # in the bare environment silently reads the OTHER fixture ledger — it did, and both halves of
  # the pair came back `aaa1111`, agreeing with each other for a reason that had nothing to do
  # with the flag. A probe that answers from the wrong ledger concludes nothing.
  ( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/judgesplit" eval "$line" ) 2>/dev/null \
    | jq -r '.latest.kit_sha // "none"'
}
# gate_sha <flags...> — the sha the GATE demands. gate_KAIZEN is not callable from here (bin/sdd
# is an entrypoint, never sourced), so it is read through the same door the gate uses: it calls
# kaizen_series in-process, under whatever ledger flags the invocation carried.
gate_sha() {
  ( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/judgesplit" "$KSDD" kaizen --series "$@" 2>/dev/null ) \
    | jq -r '.latest.kit_sha // "none"'
}
# Witness for the REGIME, computed from the FIXTURE FILE and never from the runner — deliberately
# outside the `one series` prefix the checkpoint counts. This whole section is about what the
# runner answers, so a witness the runner derived would agree with whatever the runner does; the
# property below is a fact of the ledger on disk, which no edit to bin/sdd can move.
#
# The property: the newest kit version IN THE FILE belongs to the other repo, not to the kit's own
# rows. A judge that still filtered per repo lands on the kit's sha instead, and every assertion
# under this one moves — which is what makes them assertions about ADR 0005 part 1 rather than
# about a flag.
#
# ⚠️ Asserted as a PROPERTY ("differ") and never as the literal pair `qqq1111 zzz9999`. The first
# draft used the literals, and the sabotage probe that renamed the fixture shas renamed the
# expectation with them — the witness agreed with the sabotage and reported `ok` on a fixture that
# had stopped diverging. An expectation a fixture edit can move in lockstep witnesses nothing.
# Both shas are required real, too: two nulls are equal, but one null against a sha would read as
# "differ" out of emptiness rather than out of the split this section exists to hold.
JS_KITONLY="$(jq -rs --arg r "$FIXROOT" '[.[] | select(.repo == $r)] | last | .kit_sha' \
                "$OUTSIDE/judgesplit/autonomy-log.jsonl")"
JS_WHOLE="$(jq -rs 'last | .kit_sha' "$OUTSIDE/judgesplit/autonomy-log.jsonl")"
assert_eq "witness: the newest version in the file is not the kit repo's own (else the pair proves nothing)" \
  "differ" \
  "$( if [ "$JS_KITONLY" != "$JS_WHOLE" ] \
        && [ -n "$JS_KITONLY" ] && [ "$JS_KITONLY" != "null" ] \
        && [ -n "$JS_WHOLE" ]   && [ "$JS_WHOLE" != "null" ]
      then echo differ; else echo "same:$JS_KITONLY/$JS_WHOLE"; fi )"

# ADR 0005, part 1. The judge's question is "what did this kit version cost", and ADR 0003 already
# answered where that evidence lives: real target repos, because in the repo that BUILDS the kit
# every session lands on a fresh sha and the axis degenerates by construction. So the default
# reading is the WHOLE ledger — and for nine days it was not, which is what made 0003 a dead
# letter: the per-repo default kept the judge looking at exactly the one repo 0003 declared
# unusable.
#
# `--all-repos` is kept, and kept a NO-OP here, because scripts and handoffs already carry it and a
# flag that silently changed meaning would be worse than one that stopped deciding in one of its
# two homes. On `sdd autonomy` it still decides everything.
assert_eq "the judge reads every repo by default (ADR 0005, part 1)" "$JS_WHOLE" "$(gate_sha)"
assert_eq "...and --all-repos is a no-op on the judge, never a second reading" \
  "$JS_WHOLE" "$(gate_sha --all-repos)"

# The pair. Gate against prompt, one string each, with the flag and without it. It used to be the
# flag that could put the two halves on different series — the gate inherited it in-process, the
# prompt only if the runner wrote it into the command line it hands over. With ONE reading the
# invariant holds by construction, and the second run is what says the flag cannot reopen the
# split from either side.
assert_eq "one series: the prompt hands the agent the reading the gate takes" \
  "$(gate_sha)" "$(judge_prompt_sha)"
assert_eq "one series: and the flag splits them from neither side, now that it decides nothing" \
  "$(gate_sha --all-repos)" "$(judge_prompt_sha --all-repos)"

# ...and the GATE half of that pair, driven for real instead of by proxy.
#
# `gate_sha` above reads the series through the same door gate_KAIZEN uses, which measures the
# SERIES and takes the gate on faith. Measured: degrading gate_KAIZEN to force a per-repo read
# (`series="$( LEDGER_ALL_REPOS=0 kaizen_series )"`) left all three assertions above GREEN — the
# section written to forbid BUG-1 was blind to the same bug one function further on. So the gate is
# driven end to end here: the verdict on disk names the sha the PROMPT hands the agent, and the
# runner's own rc says whether the gate accepted it.
#
# The pair is what makes it an assertion. Accepted-with-the-right-sha alone is satisfied by a gate
# that accepts anything; refused-with-the-other-sha alone is satisfied by a gate that refuses
# everything. Together they pin the gate to ONE series — and under the degrade BOTH go red, because
# it is exactly the two shas that swap places.
#
# ⚠️ NOT prefixed `one series`: the checkpoint Check for F1 counts `^  ok    one series` with `-c`
# and demands exactly two. New clause, new name.
gate_verdict_rc() {   # gate_verdict_rc <sha to write into the verdict> <flags...> -> "<rc> <found?>"
  local sha="$1"; shift
  sed -i "s/^kit_sha_judged: .*/kit_sha_judged: $sha/" "$VDIR/05-verdict.md"
  git -C "$FIX" add -A >/dev/null 2>&1
  git -C "$FIX" commit -qm "chore: the verdict names $sha" >/dev/null 2>&1
  local o r
  o="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/judgesplit" "$KSDD" kaizen "$@" 2>&1 )"; r=$?
  if grep -q 'no verdict for kit' <<< "$o"; then printf '%s no-verdict' "$r"
  else printf '%s verdict-found' "$r"; fi
}
# The verdict is `melhorou`, which the gate only accepts over a sufficient series — and both
# readings of this fixture are sufficient (three missions a side), so nothing here can pass or fail
# for the guard's reason instead of the series' reason.
loud_stub   # no session may open on the accepting path; a real one would show up as a ledger row
assert_eq "real gate: it accepts the very sha the prompt hands the agent" \
  "0 verdict-found" "$(gate_verdict_rc "$(judge_prompt_sha)")"
dead_stub   # the refusing path burns its two offline attempts and escalates, exactly as rc 3 says
assert_eq "real gate: and refuses the sha a per-repo reading would have demanded" \
  "3 no-verdict" "$(gate_verdict_rc "$JS_KITONLY")"

# --- ...and corruption is never "not judged yet" -----------------------------
# `gate_KAIZEN` read `series="$(kaizen_series)"` and dropped the rc. It looked safe because errexit
# would catch it, and errexit is OFF inside there every time: every caller invokes the gate as
# `gate_KAIZEN || gate_rc=$?`, which disables it for the whole body. So an unreadable ledger arrived
# as the empty string, `expected` came out empty, and the gate answered "no verdict for kit  yet" —
# that double space was the only tell. It is the branch meaning "the judge has not run", so the
# runner went on to open an OPUS session to judge a file nobody could parse. `sdd autonomy` over the
# same file died loudly; the judge's own gate guessed, and guessed the expensive way.
#
# FOUR clauses in one reading, because the degrades that matter move one and not the others: the rc
# (rc 1, a refusal over corrupt input — not rc 3, which is what a burnt-out retry loop returns), the
# sentence naming the unreadable file, the ABSENCE of the pending sentence (that confusion IS the
# finding: a gate that complains and still says "no verdict yet" has not stopped conflating them),
# and the loud stub, which is the witness that no session was opened at all.
echo "== the judge refuses a ledger it cannot read =="
mkdir -p "$OUTSIDE/judgecorrupt"
{ cat "$OUTSIDE/judgesplit/autonomy-log.jsonl"; printf 'NOT JSON AT ALL {{{\n'; } \
  > "$OUTSIDE/judgecorrupt/autonomy-log.jsonl"
loud_stub
assert_eq "corrupt ledger: refused as UNREADABLE, never as 'not judged yet', and no session is spent" \
  "1 unreadable no-pending-claim no-session" \
  "$( o="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/judgecorrupt" "$KSDD" kaizen 2>&1 )"; r=$?
      printf '%s %s %s %s' "$r" \
        "$(grep -q 'could not be read' <<< "$o" && echo unreadable || echo silent)" \
        "$(grep -q 'no verdict for kit' <<< "$o" && echo pending-claim || echo no-pending-claim)" \
        "$(grep -q 'invoked the real claude' <<< "$o" && echo SESSION-SPENT || echo no-session)" )"
# The control, and it is not decoration: the clauses above are all satisfied by a runner that
# refuses EVERY ledger. The same fixture with the broken line removed has to reach the gate and give
# a verdict answer — so "refuses corruption" is distinguishable from "refuses".
assert_eq "corrupt ledger: and the same ledger without the broken line still reaches the gate" \
  "reaches-gate no-unreadable-claim" \
  "$( o="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/judgesplit" "$KSDD" kaizen --series 2>&1 )"; r=$?
      printf '%s %s' \
        "$( [ "$r" = 0 ] && echo reaches-gate || echo "refused:$r" )" \
        "$(grep -q 'could not be read' <<< "$o" && echo unreadable-claim || echo no-unreadable-claim)" )"

echo "== hygiene =="
assert_eq "the fixture kit tree ends clean" "" "$(git -C "$FIX" status --porcelain)"
assert_eq "the ledger is never tracked by the fixture kit" "0" \
  "$(git -C "$FIX" ls-files | grep -c 'autonomy-log\.jsonl')"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the series tells the truth and the gate holds\n'; exit 0; fi
printf '%d kaizen check(s) failed\n' "$fails" >&2
exit 1
