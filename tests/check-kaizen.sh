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
cat > "$OUTSIDE/degraded/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"bbb2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"fail","gate_why":"Security = B"}
{"v":1,"ts":"2026-08-16T10:01:00-03:00","event":"degraded","kind":"review-to-draft","run_id":"r1","invocation":"run","kit_sha":"bbb2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","gate_why":"Security = B"}
EOF
SERIES_OUT="$( cd "$OUTSIDE/anywhere" && SDD_STATE_DIR="$OUTSIDE/degraded" "$SDD" kaizen --series 2>/dev/null )"
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
# phase_label is deliberately NOT taught about `degraded`: the REVIEW sessions of a degraded run
# already end with `gate: fail`, so the group already reads `refez`. Teaching it would count the
# same fact twice.
assert_eq "the label was already refez, so nothing had to be taught to phase_label" "refez" \
  "$(field '.latest.detail[] | select(.phase == "REVIEW") | .label')"

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
cat > "$LEDGER" <<'EOF'
{"v":1,"ts":"2026-08-15T11:00:00-03:00","event":"session","run_id":"g1","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T11:01:00-03:00","event":"session","run_id":"g2","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T11:02:00-03:00","event":"session","run_id":"g3","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T11:03:00-03:00","event":"session","run_id":"g4","invocation":"run","kit_sha":"aaa1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF

# The insufficient guard: one mission on the same latest sha. Used per-invocation through
# SDD_STATE_DIR to prove the gate refuses a non-indeterminado verdict the moment the guard drops.
mkdir -p "$OUTSIDE/state2"
cat > "$OUTSIDE/state2/autonomy-log.jsonl" <<'EOF'
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

echo "== hygiene =="
assert_eq "the fixture kit tree ends clean" "" "$(git -C "$FIX" status --porcelain)"
assert_eq "the ledger is never tracked by the fixture kit" "0" \
  "$(git -C "$FIX" ls-files | grep -c 'autonomy-log\.jsonl')"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the series tells the truth and the gate holds\n'; exit 0; fi
printf '%d kaizen check(s) failed\n' "$fails" >&2
exit 1
