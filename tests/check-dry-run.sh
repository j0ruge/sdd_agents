#!/usr/bin/env bash
# Sensor for the dry-run projection.
#
# `sdd run <mission> --dry-run` exists to answer "what will happen if I run this?" BEFORE spending
# tokens. Answering only for the first phase is answering half of it: the user never learns that
# QA, REVIEW, DOCS and PR would follow, nor which agent runs each one.
#
# This test builds a fixture repo stalled at EXEC and asserts that the dry-run projects the whole
# sequence of pending phases, in order, each with the right agent (or <none>, when the session is
# driven by a third-party skill through the literal slash) — and that nothing on disk changes.
#
# Usage: tests/check-dry-run.sh   (exit 0 = projection correct)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-dryrun-XXXXXX")"
MISSION="20260101-fixture"
fails=0

# This file exercises the REAL (non-dry) blocked-escalation path below, which writes an autonomy
# ledger row. run-all.sh already exports SDD_STATE_DIR for every test it runs, but a standalone
# `tests/check-dry-run.sh` does not inherit that — and standalone is exactly how this file gets
# run during manual verification. Without its own export here, that run injects fixture rows into
# the developer's real ~/.sdd/autonomy-log.jsonl. Belt and braces, same reason check-autonomy.sh
# does not depend on run-all.sh's export holding.
#
# A directory OF ITS OWN, not "$FIX/state": $FIX itself becomes the git working tree below (`cd
# "$FIX" && git init`), and this file asserts a CLEAN `git status --porcelain` at several points —
# a state/ subdirectory living inside that tree would show up as an untracked path and fail those
# assertions on its own.
SDD_STATE_FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-dryrun-state-XXXXXX")"
export SDD_STATE_DIR="$SDD_STATE_FIX"
trap 'rm -rf "$FIX" "$SDD_STATE_FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# assert_eq <description> <expected> <got>
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi
}

# The (phase, agent) sequence the dry-run printed, one per line, in print order.
# A single assertion covers four things: which phases appear, in what order, how many times each,
# and which agent was announced in each block.
projected() {
  awk '
    /^--- DRY RUN: phase .* ---$/ { ph = $5; next }
    ph != "" && /agent:/ {
      for (i = 1; i <= NF; i++) if ($i == "agent:") { printf "%s=%s\n", ph, $(i + 1); ph = "" }
    }
  '
}

# Fingerprint of everything in the fixture except .git. The dry-run must not touch any of it.
tree_snapshot() {
  ( cd "$FIX" && find . -path ./.git -prune -o -print | LC_ALL=C sort )
}

# ---------------------------------------------------------------------------
echo "== fixture at $FIX =="
# `|| exit`: `set -e` is off (we need `rc=$?` after the commands that fail on purpose), so a
# failing `cd` would go on to run `git init`, `sed -i` and `git commit` in the REAL repo of
# whoever ran the test. Failing here is cheap; corrupting the dev's repo is not.
cd "$FIX" || exit 1

# No test may spend tokens or network. The "real execution" path below depends on the `blocked`
# Jidoka escaping BEFORE any `run_phase` — if that order breaks, the runner would call claude for
# real. This stub makes that impossible by construction: instead of a paid session (or a hang in
# CI), the test fails loudly and cheaply.
mkdir -p "$FIX/.stub"
cat > "$FIX/.stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude — the escalation path did not escape before the session" >&2
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
# The runner's journal is ephemeral and lives outside the committed tree (`log_dir()` in bin/sdd).
PIPELINE_LOG="$FIX/.sdd/logs/$MISSION/pipeline.log"
mkdir -p "$MDIR"
# Artifact file names, frontmatter keys and the checkpoint header are CONTRACT: they stay exactly
# as templates/ ships them, because that is what the runner parses.
cat > "$MDIR/00-missao.md" <<'EOF'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
EOF
: > "$MDIR/01-plano.md"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
EOF
git add -A && git commit -qm "chore: fixture mission"

# Sanity: without this, a badly built fixture would make the test pass or fail for the wrong
# reason.
here="$( "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "fixture stalled at the EXEC phase" "EXEC" "$here"

# --- full projection -------------------------------------------------------
echo "== projection =="
before="$(tree_snapshot)"
out="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"; rc=$?
after="$(tree_snapshot)"

assert_eq "dry-run exits 0" "0" "$rc"

want="$(printf '%s\n' \
  "EXEC=sdd-executor" \
  "QA:close=sdd-qa" \
  "REVIEW=sdd-reviewer" \
  "DOCS=sdd-docs" \
  "PR=sdd-publisher")"
got="$(printf '%s\n' "$out" | projected)"
assert_eq "projects EXEC→QA→REVIEW→DOCS→PR, in order, each with its agent" "$want" "$got"

# TICKET has its gate satisfied (JIRA_ENABLED=false): a satisfied phase is not in the projection.
if grep -q '^--- DRY RUN: phase TICKET ---$' <<< "$out"; then
  fail "a phase with a satisfied gate does not appear in the projection" "no TICKET block" "TICKET block printed"
else
  pass "a phase with a satisfied gate (TICKET) does not appear in the projection"
fi

# --- nothing is executed, nothing changes on disk --------------------------
echo "== the dry-run does not touch the disk =="
assert_eq "file tree identical before and after" "$before" "$after"
assert_eq "working tree still clean" "" "$(git status --porcelain)"

# --- the phase session is projected as a STREAM ----------------------------
# `--output-format stream-json` and `--verbose` are ONE flag, not two. Without the second, the
# streaming format is not a degraded session, it is NO session: the CLI refuses at argument
# validation with
#     Error: When using --print, --output-format=stream-json requires --verbose
# (measured against Claude Code 2.1.233 on 2026-08-16), rc 1 and an empty stdout. Every phase of
# every mission would die before the model was ever reached, and the ledger would fill with rc-1
# rows that read as a model which keeps failing.
#
# No stub in this suite can see that: a stub ignores the flags it is handed and answers anyway.
# The dry-run projection is the ONLY place the whole suite reads the real argv, which is why the
# assertion lives in this file instead of next to the streaming assertions in check-autonomy.sh.
#
# `tr -s ' '` first, and it is not cosmetic: the projection prints the argv with `printf '  %q'`,
# so every element arrives prefixed by TWO spaces. A pattern written with the single spaces a
# human types matches NOTHING — before the fix and after it alike, which is an assertion frozen
# red, the mirror image of one frozen green. This very block was written that way and caught by
# demanding the red name the right cause.
echo "== the phase session is projected as a stream =="
argv="$(tr -s ' ' <<< "$out")"
blocks="$(grep -c -- '^--- DRY RUN: phase ' <<< "$argv")"
# Anti-vacuity. The next assertion compares two counts, and 0 == 0 would pass on a projection that
# printed nothing at all — the failure mode where the sensor certifies what it never read.
assert_eq "the projection has the five phase blocks the assertions below count over" "5" "$blocks"
assert_eq "every projected phase asks for stream-json WITH --verbose" "$blocks" \
  "$(grep -c -- '--output-format stream-json --verbose' <<< "$argv")"
# The other half, the house rule: the text of the right branch AND the absence of the wrong one.
# A runner that ADDED the streaming flags without removing the old one satisfies the assertion
# above while handing the CLI two conflicting --output-format values.
assert_eq "and no phase is left on the single-blob format" "0" \
  "$(grep -c -- '--output-format json' <<< "$argv")"

# --- OUTPUT_LANG reaches the boot prompt -----------------------------------
# Anchored on the VALUE of the key, never on the prose of the prompt: the runner text is English
# and the artifacts may be in any language, and an assertion tied to the prose would die at the
# first translation. An assertion that only survives its own commit is not a sensor — it is
# decoration with an expiry date.
echo "== OUTPUT_LANG =="
# Reuses the projection above: it is the SAME invocation, with the key absent from the fixture
# config.
if grep -q 'pt-BR' <<< "$out"; then
  fail "with no OUTPUT_LANG the prompt says nothing about language" "no mention of a language" "pt-BR mentioned"
else
  pass "with no OUTPUT_LANG the prompt says nothing about language (the state of every installed repo)"
fi

echo 'OUTPUT_LANG="pt-BR"' >> .sdd/config.sh
out_lang="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"
if grep -q 'pt-BR' <<< "$out_lang"; then
  pass "with OUTPUT_LANG the boot prompt carries the requested language"
else
  fail "with OUTPUT_LANG the boot prompt carries the requested language" \
       "prompt quoting pt-BR" "prompt with no language mention"
fi
# Restores the fixture byte for byte: the clean-working-tree assertions below depend on it.
sed -i '/^OUTPUT_LANG=/d' .sdd/config.sh
assert_eq "the fixture comes back clean after the language test" "" "$(git status --porcelain)"

# --- --phase still prints only the phase asked for -------------------------
echo "== --phase <PHASE> =="
out1="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
# QA is three sessions derived from the artifacts (plan → walk → close). This fixture has no
# interface to walk (E2E_CMD and APP_URL empty), so the sub-step is `close`: sdd-qa judges whether
# the diff is user-visible and, when it is not, writes `qa: skipped`.
assert_eq "--phase QA prints only the current sub-step" "QA:close=sdd-qa" "$(printf '%s\n' "$out1" | projected)"

# --- the QA sub-step changes with the existence of an interface ------------
echo "== QA sub-step derived from the artifacts =="
# With E2E_CMD set and no charter in the tree, the cycle starts at planning — driven by the
# qa-report skill through the literal slash, hence with no kit agent.
sed -i 's|^E2E_CMD=""|E2E_CMD="true"|' .sdd/config.sh
out2="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
assert_eq "a project WITH an interface and no charters starts at QA:plan (qa-report skill)" \
  "QA:plan=<none>" "$(printf '%s\n' "$out2" | projected)"
# The dry-run prints the prompt with the "  │ " prefix, so the anchor includes the first line of
# the block — that is where the slash has to be to expand headless.
if grep -q '│ /qa-report docs/qa' <<< "$out2"; then
  pass "the boot prompt starts with the literal /qa-report slash"
else
  fail "QA:plan boot" "prompt starting with /qa-report" "$(printf '%s\n' "$out2" | grep -m1 '│' || echo empty)"
fi
# With a charter AND a closed report, the cycle moves on to closing (sdd-qa). This assertion
# exists because the "report closed" anchor used to live duplicated in the gate and in the
# sub-step: fixed in one place only, the gate accepted it while the sub-step kept ordering another
# execution — the runner re-ran qa-execution indefinitely, at US$ 15 a round. Measured in the
# SQ-97 pilot.
mkdir -p docs/qa/charters docs/qa/reports
printf '# CH-one\n' > docs/qa/charters/CH-one.md
printf -- '# QA Run Report\n- **Started:** 2026-01-01T10:00:00Z · **Status:** closed <!-- in-progress | closed -->\n' \
  > docs/qa/reports/2026-01-01-fixture.md
out3="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
assert_eq "with a charter and a closed report the sub-step is close (no re-execution)" \
  "QA:close=sdd-qa" "$(printf '%s\n' "$out3" | projected)"

# And a report that is still OPEN has to order execution again — otherwise the assertion above
# would pass by vacuity, approving anything.
sed -i 's/\*\*Status:\*\* closed/**Status:** in-progress/' docs/qa/reports/2026-01-01-fixture.md
out4="$( "$SDD" run "$MISSION" --dry-run --phase QA 2>&1 )"
assert_eq "an in-progress report goes back to the exec sub-step" \
  "QA:exec=<none>" "$(printf '%s\n' "$out4" | projected)"
rm -rf docs/qa/charters docs/qa/reports

sed -i 's|^E2E_CMD="true"|E2E_CMD=""|' .sdd/config.sh

# --- the projection must not write to the mission journal ------------------
# Found by the QA phase of mission 20260814-dry-run-completo: with a `blocked` increment, the
# dry-run escapes through the `cmd_run` Jidoka BEFORE reaching the DRY_RUN block, and that path
# calls `pipeline_log_line` with no guard. Result: a projection — a read command the user runs
# precisely so as NOT to change anything — records a BLOCKED event that never happened in the
# mission's `pipeline.log`, lying in the audit trail. Worse in a freshly installed target repo:
# `sdd install` only puts `.sdd/logs/` in `.gitignore`, so the `pipeline.log` lands as untracked
# and dirties the working tree — and a dirty tree fails `gate_REVIEW` and `sdd preflight`.
# A projection command must not be able to knock down another phase's gate.
echo "== the projection does not write to the mission journal (blocked increment) =="
sed -i 's/| pending |/| blocked |/' "$MDIR/checkpoint.md"
git add -A && git commit -qm "fixture: blocked increment"

before_b="$(tree_snapshot)"
out3="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"; rc3=$?
after_b="$(tree_snapshot)"

# Escalating is the right and honest behaviour: "run this and the line stops". A regression guard
# — this already passed before the finding.
assert_eq "dry-run of a blocked mission escalates with exit 3" "3" "$rc3"
# The exit code alone does not prove the user was TOLD the reason. Without this assertion,
# breaking the escalation message went unnoticed here (verified by mutation: changing the text of
# `bad "BLOCKED in EXEC — …"` left this whole file green) — and that message is exactly what
# answers "what happens if I run this?", the question the dry-run exists to answer.
if grep -q 'BLOCKED in EXEC' <<< "$out3"; then
  pass "the projection EXPLAINS the escalation (the 'BLOCKED in EXEC' message)"
else
  fail "dry-run escalation message" "output containing 'BLOCKED in EXEC'" \
    "$(printf '%s\n' "$out3" | tail -3 | tr '\n' ' ')"
fi
# The Red of the finding: the projection must leave no trace on disk, not even on the escalation
# path. The journal lives in `.sdd/logs/<mission>/` (it moved in 53cf63a — it used to be `$MDIR`,
# inside the committed tree, where it dirtied `git status` and knocked down `gate_REVIEW`). This
# assertion has to point at where the runner WRITES today: pointed at the old path it becomes
# decoration — verified by mutation, with the F1 bug reintroduced it stayed green.
assert_eq "a blocked projection does not write the pipeline.log" "" \
  "$( [ -e "$PIPELINE_LOG" ] && echo "pipeline.log created" || true )"
assert_eq "tree identical before and after (blocked path)" "$before_b" "$after_b"
# CAREFUL reading this line: it is NOT the discriminator for F1. `.sdd/logs/` is in the
# `.gitignore` that `sdd install` writes, so `git status --porcelain` is blind to the
# `pipeline.log` — with the F1 bug reintroduced it stays green (verified by mutation). The two
# assertions above are what catch F1. This one guards something different and complementary: that
# the projection dirtied no TRACKED path, which is what would knock down `gate_REVIEW` and
# `sdd preflight`.
assert_eq "the projection dirtied no tracked file (blocked path)" "" "$(git status --porcelain)"

# --- the other side of the guard: the REAL path still writes ---------------
# Every assertion above states that the projection does NOT write. None stated that a real run
# DOES — so inverting the guard (`= "1"` becoming `!= "1"`) would kill the mission journal in
# silence, with the suite green. Writing for real would normally require a `run_phase`, which
# would call claude; the `blocked` escalation path is the exception: it logs and returns 3 BEFORE
# any session, so the real path can be exercised without spending tokens or network.
echo "== the real (non-dry) path still writes to the journal =="
# Deleting first is what makes the assertion causal instead of circumstantial: without it, a
# journal left behind by the projection (exactly what happens if the guard is inverted) would make
# the `[ -e ]` pass for the wrong reason. Verified by mutation — it is what happened in the first
# version of this section, which reported "ok" with the guard inverted.
rm -f "$PIPELINE_LOG"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc4=$?
assert_eq "a real run of a blocked mission escalates with exit 3" "3" "$rc4"
assert_eq "the real path WRITES the pipeline.log in .sdd/logs/<mission>/" "exists" \
  "$( [ -e "$PIPELINE_LOG" ] && echo exists || echo "absent" )"
assert_eq "the recorded event is the BLOCKED one" "1" \
  "$(grep -c 'BLOCKED' "$PIPELINE_LOG" 2>/dev/null || echo 0)"
# The journal is ephemeral by contract: `.sdd/logs/` is in the `.gitignore` that `sdd install`
# writes. If it comes back inside the committed tree, it dirties the working tree and knocks down
# `gate_REVIEW`.
assert_eq "the journal stays OUTSIDE the committed tree" "" "$(git status --porcelain)"
assert_eq "no pipeline.log in docs/handoffs/" "0" \
  "$(find docs/handoffs -name 'pipeline.log' 2>/dev/null | wc -l | tr -d ' ')"

# Now that the journal EXISTS, the F1 assertion gets stronger: the projection must neither create
# nor MODIFY the journal. `tree_snapshot` compares names, not content — only the md5 catches a
# write into a file that already existed, which is the case for any mission that has run for real
# once.
md5_before="$(md5sum "$PIPELINE_LOG" | cut -d' ' -f1)"
"$SDD" run "$MISSION" --dry-run >/dev/null 2>&1
md5_after="$(md5sum "$PIPELINE_LOG" | cut -d' ' -f1)"
assert_eq "the projection does not MODIFY a pre-existing pipeline.log" "$md5_before" "$md5_after"

sed -i 's/| blocked |/| pending |/' "$MDIR/checkpoint.md"

# --- scope hygiene: no function reads the caller's local --------------------
# `pstep` is `local` to `run_phase`. Bash dynamic scoping means EVERY function it calls can see
# that local — so another function referencing `$pstep` "works", but only by coincidence of who
# calls it. Under `set -u`, called from anywhere else, the expansion fails INSIDE a `$( )`: the
# variable comes out empty, the function returns 0 and the phase runs with no agent — no visible
# error, exactly the silent failure mode this kit exists to prevent.
# Neither `bash -n` nor the linter catches this (the name IS assigned in the file, in run_phase),
# which is why the sensor is here.
echo "== runner scope hygiene =="
offenders="$(awk '
  /^[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{/ { fn = substr($1, 1, index($1, "(") - 1) }
  /pstep/ && fn != "run_phase" { print fn "():" NR }
' "$ROOT/bin/sdd")"
assert_eq "only run_phase references \$pstep (the caller's local does not leak)" "" "$offenders"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "dry-run projection correct"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
