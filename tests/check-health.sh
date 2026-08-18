#!/usr/bin/env bash
# Sensor for `sdd health` — the kit's own health command.
#
# Until this file existed, NO sensor of the suite ran cmd_health. The two hits of
# `grep -l 'sdd health' tests/*.sh` were both COMMENTS. The one command written to answer "does
# the kit still measure what it claims to?" was the only one of the runner nobody asked that
# about — and it has already bitten: two of its checks were born with the logic inverted by
# pipefail and were caught by hand, by a human reading the file, not by anything that runs.
#
# What this file measures is that cmd_health's checks DISCRIMINATE — not that they run, but that
# they say different things about different worlds:
#
#   1. the ratchet fails on a finding outside the baseline    (the debt may not grow in silence)
#   2. the ratchet fails on a stale baseline line             (the list may not become folklore)
#   3. the two failures accuse DIFFERENT things — differential, and the reason 1 and 2 are not
#      enough on their own: a ratchet that refused every world with one sentence would satisfy
#      both while distinguishing nothing. No fixture regime satisfies this one by accident,
#      because it compares two outputs against EACH OTHER.
#   4. provenance fails when the fixture diverges from an installed skill — also differential:
#      the same kit, the same fixture, one matching skill template and one diverged.
#   5. the green fixture reaches `kit healthy` — the FLOOR against vacuity. Without it, 1-4 are
#      all satisfied by a fixture that is red for some reason of its own, and this file would
#      claim to have measured what it never measured.
#   6. a baseline off by one on the TODO.md finding count fails in BOTH directions at once — the
#      backlog ratchet, which is the whole point of the mission that added it. One edit, two
#      complaints: the emitted count is outside the baseline AND the baseline's count is stale.
#   7. the count check dies when the suite prints no finding count, and is the SOLE author of that
#      failure. Without it the contract could rot on the check-todo.sh side and cmd_health would
#      go blind in silence — the failure mode the `score:` check above was already written
#      against, and the one it still has (TODO.md: it dies of `set -e` before it can say so).
#   8. the ratchet policy is written where the next mission meets it — CLAUDE.md and TODO.md. The
#      one rule here that no mut_HEALTH_* can reach, since none of them can make a document say
#      less, so it carries probes of its own over all three of its layers.
#
# Usage: tests/check-health.sh   (exit 0 = cmd_health discriminates)
#
# ---------------------------------------------------------------------------
# Three things about the fixture, each of which cost something to learn:
#
# RECURSION. cmd_health runs `tests/run-all.sh` out of its own $SDD_HOME, and run-all.sh runs
# this file. A fixture pointed at the real kit would be run-all → check-health → sdd health →
# run-all, forever, on the machine of whoever typed `tests/run-all.sh`. That is why the fixture
# carries a STUB suite that prints the canonical lines and exits 0.
#
# THE RUNNER IS COPIED LIVE, never frozen into this file. It is that copy which carries the
# sabotage of `mut_HEALTH_*` into the fixture; a bin/sdd written out here would make every HEALTH
# mutation invisible while the catalogue went on crediting protection that does not exist. Which
# is the precise defect this whole sensor exists to make impossible one level up.
#
# THE BASELINE IS CALIBRATED, never written by hand. The findings cmd_health emits are read off
# the real bin/sdd and the real config/schema.md, so a hand-written baseline here would turn any
# legitimate drift of those two files into a RED SUITE — and the ratchet living inside TEST_CMD
# is the one thing decision 1 of this mission's plan forbids: it would fail the EXEC/QA/REVIEW
# gate of every mission in flight, including the one that just registered the drift. calibrate()
# reads the baseline off cmd_health's OWN first-run output instead, which keeps this file
# hermetic against everything except the properties it is asserting.
# ---------------------------------------------------------------------------

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# `|| exit 90` and not a bare assignment: with mktemp failed, WORK is EMPTY and FIX becomes the
# absolute path `/kit` — a non-empty string, so the `${FIX:?}` guard in reset_home() below is
# satisfied and `rm -rf /kit/home` runs for real on any machine where / is writable. The guard
# was written against exactly this and cannot see it, because it tests the symptom and not the
# cause. Raised in the r1 review; the SENSOR-BROKEN rc is used before broken() is defined.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-health-XXXXXX")" \
  || { printf '  SENSOR-BROKEN  mktemp -d failed — no fixture, so no verdict\n' >&2; exit 90; }
FIX="$WORK/kit"

# run-all.sh already exports SDD_STATE_DIR for everything it runs, but a standalone
# `tests/check-health.sh` does not inherit that. Belt and braces, the same reason check-gates.sh
# gives: nothing here may drop a fixture row into the developer's real autonomy ledger.
export SDD_STATE_DIR="$WORK/state"
mkdir -p "$SDD_STATE_DIR"
trap 'rm -rf "$WORK"' EXIT

fails=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# SENSOR-BROKEN is not an assertion failure. It means the fixture stopped modelling the world, so
# every verdict below would be a verdict about nothing — counting it as one red assertion among
# five would let four green ones drown it out. It exits, the way the HARNESS-BROKEN control run
# of check-mutation.sh does, and for the same reason.
broken() { printf '  SENSOR-BROKEN  %s\n' "$1" >&2; exit 90; }

# The ratchet-relevant lines of an output, flattened onto one line for a FAIL report.
digest() { grep -E 'baseline|provenance|finding count|kit healthy|check\(s\) failed' <<< "$1" | tr '\n' ' '; }

# ---------------------------------------------------------------------------
# The fixture
# ---------------------------------------------------------------------------

# The stub suite's score line. The number is deliberately NOT the real catalogue's: only the
# SHAPE is the contract cmd_health reads (`^score: [0-9]+ caught, 0 known gap`), and a number
# that tracked the real one would invite a future editor to keep them in sync for no reason.
STUB_SCORE='score: 3 caught, 0 known gap(s), of 3'

# The stub suite's TODO.md finding count — the SECOND line cmd_health reads off the suite's own
# stdout, emitted for real by tests/check-todo.sh. Same reasoning as STUB_SCORE, and the same
# reason it is a contract and not a recount: bin/sdd reads this number, tests/check-todo.sh
# writes it, and nobody re-derives it. The value here is deliberately not the real TODO.md's.
STUB_TODO_COUNT=7

reset_home() {
  rm -rf "${FIX:?}/home"
  # The plugins cache directory is part of the fixture and NOT decoration: health_provenance
  # reads the codereview template through `find "$HOME/.claude/plugins/cache" … | sort -V | tail`,
  # and `find` on a missing directory returns 1, which under the runner's own `set -o pipefail`
  # + `set -e` aborts `sdd health` mid-run — three ok lines, rc 1, not one word said. So the
  # fixture models a machine that HAS the directory, which is every machine the kit runs on
  # today. The defect itself is real and is recorded in TODO.md; it is not this file's to fix,
  # and papering over it here would be a lie only if it went unwritten.
  mkdir -p "$FIX/home/.claude/plugins/cache"
}

build_fixture() {
  mkdir -p "$FIX/bin" "$FIX/tests" "$FIX/config"
  reset_home

  # LIVE copy — see the header. This is the file mut_HEALTH_* sabotages.
  cp "$ROOT/bin/sdd" "$FIX/bin/sdd"

  # What cmd_health reads out of its own $SDD_HOME, and nothing else:
  #   config/schema.md        checks 4 and 6 (documented key <-> load_config default)
  #   tests/check-mutation.sh check 3 (every gate has a mutation)
  #   tests/check-gates.sh    check 7 (fixture provenance)
  cp "$ROOT/config/schema.md" "$FIX/config/schema.md"
  cp "$ROOT/tests/check-mutation.sh" "$ROOT/tests/check-gates.sh" "$FIX/tests/"

  write_stub_suite with-count
}

# The stub suite. `$1` is `with-count` or `no-count`: assertion 7 needs a suite that prints
# everything except the finding count, and it has to be the ONLY thing that changes between the
# two worlds it compares — hence one writer with a switch, not two heredocs drifting apart.
write_stub_suite() { # write_stub_suite <with-count|no-count>
  local count_line=""
  [ "$1" = "with-count" ] \
    && count_line="printf '  ok    %d finding(s), all within 8 lines and carrying anchor + date\\n' $STUB_TODO_COUNT"

  cat > "$FIX/tests/run-all.sh" <<EOF
#!/usr/bin/env bash
# Stub suite. See the RECURSION note in tests/check-health.sh: the real one runs that file, which
# runs this command, which would run the real one.
printf '%s\n' '$STUB_SCORE'
$count_line
exit 0
EOF
  chmod +x "$FIX/tests/run-all.sh"
}

set_baseline() { printf '%s\n' "$1" > "$FIX/tests/health-baseline.txt"; }

# The qa-report skill template cmd_health compares its check-gates.sh fixture against.
install_bug_skill() { # install_bug_skill <status line>
  local dir="$FIX/home/.claude/skills/qa-report/assets"
  mkdir -p "$dir"
  printf '%s\n' '# BUG-<n> — <title>' '' "$1" > "$dir/bug-template.md"
}
clear_skills() { reset_home; }

HEALTH_OUT=""
HEALTH_RC=0
# Runs the fixture's `sdd health` and PUBLISHES the result in HEALTH_OUT / HEALTH_RC.
#
# Published in globals and CALLED, never read as `x="$(health_run)"`: a function read through a
# command substitution runs in a subshell, and every global it assigns dies with the
# substitution — `bash -n` does not say so and the linter does not either. The house rule, and
# the runner's own run_phase / LAST_PHASE_* shape.
health_run() {
  HEALTH_OUT="$( HOME="$FIX/home" NO_COLOR=1 "$FIX/bin/sdd" health 2>&1 )"
  HEALTH_RC=$?
}

# A target that cannot be a real finding whatever the runner grows: every check-id is emitted with
# a key that exists in load_config, and this one never will. Used twice — as the seed calibrate()
# needs and as the stale line of assertion 2.
STALE='var-never-read SDD_NOT_A_REAL_KEY'

# Writes the fixture's baseline from cmd_health's own first-run output — see the header.
CALIBRATED=""
calibrate() {
  # SEEDED with the impossible line, never emptied. `known` is read through
  # `grep -vE '^[[:space:]]*(#|$)' "$bl"`, and grep over a file with no live line returns 1 —
  # which under the runner's `set -e` + `set -o pipefail` aborts `sdd health` at the very first
  # line of health_ratchet, silently. Same family as the `find` in health_provenance, same TODO
  # entry. The seed comes back out as a stale-baseline complaint, which calibration ignores: it
  # reads only the finding side.
  set_baseline "$STALE"
  health_run
  CALIBRATED="$(sed -n 's/.*finding outside the baseline: //p' <<< "$HEALTH_OUT")"

  # Anti-vacuity floor. With no findings at all, assertion 1 would have no line to drop and
  # assertion 5 would be green over a baseline of nothing — five assertions about an empty world.
  # Two, not one: assertion 1 drops a line and still needs the rest of the baseline to hold.
  local n; n="$(grep -c . <<< "$CALIBRATED")"
  [ "$n" -ge 2 ] || broken "the fixture emitted $n finding(s) against an empty baseline, expected at least 2 — did cmd_health stop calling health_finding, or did the fixture stop carrying config/schema.md? Output: $(digest "$HEALTH_OUT")"

  set_baseline "$CALIBRATED"
}

build_fixture
calibrate

# ---------------------------------------------------------------------------
# 1 + 2 — the ratchet, in both directions
# ---------------------------------------------------------------------------
DROPPED="$(head -1 <<< "$CALIBRATED")"
set_baseline "$(grep -vxF "$DROPPED" <<< "$CALIBRATED")"
health_run
OUT_NEW="$HEALTH_OUT"; RC_NEW="$HEALTH_RC"

if [ "$RC_NEW" -ne 0 ] && grep -qF "finding outside the baseline: $DROPPED" <<< "$OUT_NEW"; then
  pass "the ratchet fails on a finding outside the baseline"
else
  fail "the ratchet fails on a finding outside the baseline" \
       "rc != 0 and 'finding outside the baseline: $DROPPED'" \
       "rc $RC_NEW · $(digest "$OUT_NEW")"
fi

set_baseline "$CALIBRATED
$STALE"
health_run
OUT_STALE="$HEALTH_OUT"; RC_STALE="$HEALTH_RC"

if [ "$RC_STALE" -ne 0 ] && grep -qF "stale baseline: '$STALE' is no longer a finding" <<< "$OUT_STALE"; then
  pass "the ratchet fails on a stale baseline line"
else
  fail "the ratchet fails on a stale baseline line" \
       "rc != 0 and \"stale baseline: '$STALE' is no longer a finding\"" \
       "rc $RC_STALE · $(digest "$OUT_STALE")"
fi

# ---------------------------------------------------------------------------
# 3 — differential: the two refusals are not the same refusal
#
# Both halves are asserted in BOTH directions — the phrase that must be there and the sibling's
# phrase that must NOT. Reading only "the right words appeared" would stay green the day both
# branches start shouting both sentences, which is exactly a ratchet that has stopped telling the
# two worlds apart while still failing them.
# ---------------------------------------------------------------------------
NEW_SAYS_NEW=0;   grep -q 'finding outside the baseline' <<< "$OUT_NEW"   && NEW_SAYS_NEW=1
NEW_SAYS_STALE=0; grep -q 'stale baseline'               <<< "$OUT_NEW"   && NEW_SAYS_STALE=1
STALE_SAYS_STALE=0; grep -q 'stale baseline'             <<< "$OUT_STALE" && STALE_SAYS_STALE=1
STALE_SAYS_NEW=0; grep -q 'finding outside the baseline' <<< "$OUT_STALE" && STALE_SAYS_NEW=1

if [ "$NEW_SAYS_NEW" -eq 1 ] && [ "$NEW_SAYS_STALE" -eq 0 ] \
   && [ "$STALE_SAYS_STALE" -eq 1 ] && [ "$STALE_SAYS_NEW" -eq 0 ]; then
  pass "the two ratchet failures accuse different things"
else
  fail "the two ratchet failures accuse different things" \
       "the extra-finding world says only 'finding outside the baseline' and the stale world says only 'stale baseline'" \
       "extra-finding world: new=$NEW_SAYS_NEW stale=$NEW_SAYS_STALE · stale world: new=$STALE_SAYS_NEW stale=$STALE_SAYS_STALE"
fi

# ---------------------------------------------------------------------------
# 4 — provenance, differential on the same kit
#
# The assertion the plan named "provenance fails when an installed skill is missing" is written
# here against DIVERGENCE, because a missing skill does not fail: health_provenance SKIPS it, by
# design, the way the linter step is skipped when the linter is absent. Divergence is the path
# that fails, and it is the one that cost the kit its most expensive bug — a fixture written from
# memory agrees with the wrong gate forever.
# ---------------------------------------------------------------------------
set_baseline "$CALIBRATED"
PROV_FIXTURE_LINE="$(grep -m1 -- '- \*\*Status:\*\* open' "$ROOT/tests/check-gates.sh")"
[ -n "$PROV_FIXTURE_LINE" ] \
  || broken "check-gates.sh no longer carries a '- **Status:** open' line — the provenance assertion would compare two empty strings and pass by vacuity"

install_bug_skill "$PROV_FIXTURE_LINE"
health_run
OUT_PROV_OK="$HEALTH_OUT"; RC_PROV_OK="$HEALTH_RC"

install_bug_skill "$PROV_FIXTURE_LINE  <!-- and one enum value the fixture never heard of -->"
health_run
OUT_PROV_BAD="$HEALTH_OUT"; RC_PROV_BAD="$HEALTH_RC"

if [ "$RC_PROV_BAD" -ne 0 ] && grep -q 'bug fixture diverged from the skill' <<< "$OUT_PROV_BAD" \
   && [ "$RC_PROV_OK" -eq 0 ] && ! grep -q 'diverged from the skill' <<< "$OUT_PROV_OK"; then
  pass "provenance fails when the fixture diverges from an installed skill"
else
  fail "provenance fails when the fixture diverges from an installed skill" \
       "the diverged template fails with 'bug fixture diverged from the skill' and the matching one does not" \
       "matching: rc $RC_PROV_OK · $(digest "$OUT_PROV_OK") // diverged: rc $RC_PROV_BAD · $(digest "$OUT_PROV_BAD")"
fi

# ---------------------------------------------------------------------------
# 5 — the floor: a kit with nothing wrong reaches `kit healthy`
# ---------------------------------------------------------------------------
clear_skills
set_baseline "$CALIBRATED"
health_run
OUT_GREEN="$HEALTH_OUT"; RC_GREEN="$HEALTH_RC"

if [ "$RC_GREEN" -eq 0 ] && grep -q 'kit healthy' <<< "$OUT_GREEN"; then
  pass "the green fixture reaches kit healthy"
else
  fail "the green fixture reaches kit healthy" \
       "rc 0 and 'kit healthy' — without this floor the four assertions above are satisfied by a fixture that is red for a reason of its own" \
       "rc $RC_GREEN · $(digest "$OUT_GREEN")"
fi

# ---------------------------------------------------------------------------
# 6 — the backlog ratchet: a count off by one fails in BOTH directions, one edit
#
# This is the property the mission exists for, and it is asserted as a CONJUNCTION on purpose:
# demanding both sentences out of a single world is what makes the assertion survive a ratchet
# that learned to complain about only one side. The baseline is BUILT (the todo line stripped and
# a wrong one appended), never sed-ed out of the calibrated one — with a substitution, a runner
# that stopped emitting the count would leave a baseline with nothing to be stale about and the
# whole world would go green. Built this way the stale line is there whatever the runner does, so
# the missing half is the emitted finding, and the conjunction is what notices.
# ---------------------------------------------------------------------------
OFF_BY_ONE="$(grep -vE '^todo-findings ' <<< "$CALIBRATED")
todo-findings $(( STUB_TODO_COUNT - 1 ))"
set_baseline "$OFF_BY_ONE"
health_run

if [ "$HEALTH_RC" -ne 0 ] \
   && grep -qF "finding outside the baseline: todo-findings $STUB_TODO_COUNT" <<< "$HEALTH_OUT" \
   && grep -qF "stale baseline: 'todo-findings $(( STUB_TODO_COUNT - 1 ))' is no longer a finding" <<< "$HEALTH_OUT"; then
  pass "a baseline off by one fails both ways"
else
  fail "a baseline off by one fails both ways" \
       "rc != 0 and BOTH 'finding outside the baseline: todo-findings $STUB_TODO_COUNT' and \"stale baseline: 'todo-findings $(( STUB_TODO_COUNT - 1 ))'\"" \
       "rc $HEALTH_RC · $(digest "$HEALTH_OUT")"
fi

# ---------------------------------------------------------------------------
# 7 — the count is a contract between two files, and a broken contract has to say so
#
# THE BASELINE DROPS THE COUNT LINE FOR THIS WORLD ON PURPOSE, and that line of setup is the
# whole assertion. Keep it and the un-emitted finding leaves the baseline's own entry with no
# pair, so the STALE branch fails the run by itself and the `rc != 0` below is authored by
# somebody else entirely — the assertion would read a shared rc and conclude the count check
# works. Measured, not feared: with the count line in the baseline, downgrading this very
# `health_bad` to a `warn` survived every assertion in this file. Stripped, the count check is the
# only thing left that can fail this world, so the rc means what it says.
#
# The OUT_GREEN half is load-bearing for a different defect and was kept because sabotage broke
# it: a diagnostic that shouts the sentence in EVERY world, healthy ones included, fails only
# here — assertion 5 stays green, because a `warn` is not a failure.
# ---------------------------------------------------------------------------
write_stub_suite no-count
set_baseline "$(grep -vE '^todo-findings ' <<< "$CALIBRATED")"
health_run

if [ "$HEALTH_RC" -ne 0 ] \
   && grep -q 'did not print the TODO.md finding count' <<< "$HEALTH_OUT" \
   && ! grep -q 'did not print the TODO.md finding count' <<< "$OUT_GREEN"; then
  pass "the count check dies when the suite prints no finding count"
else
  fail "the count check dies when the suite prints no finding count" \
       "the count-less suite fails, saying so, and the world of assertion 5 never says the sentence" \
       "no-count: rc $HEALTH_RC · $(digest "$HEALTH_OUT") // green: rc $RC_GREEN · $(digest "$OUT_GREEN")"
fi

# ---------------------------------------------------------------------------
# 8 — the policy is written where the next mission walks into it
#
# The backlog ratchet is the one finding of cmd_health whose owner is not a TODO.md entry but the
# FILE, so the only thing that can tell the next session what the number means is prose. Prose
# nobody measures is how the count would drift back to being folklore with the mechanism still
# running — the failure this mission exists to end, one level up.
#
# STRUCTURAL, never a Portuguese word. TODO.md and CLAUDE.md are content in this repo's
# OUTPUT_LANG, and a rule keyed on their prose would break the day a target repo declares another
# one — the same reasoning that keeps tests/check-todo.sh out of tests/lang-allowlist.txt. What is
# demanded are the two literals the policy cannot be stated without: the check-id bin/sdd emits
# and the file that freezes it.
#
# BOTH halves, the way check-checkpoint.sh's own doc_rule demands both of its own. Measured, not
# assumed: TODO.md already carries `health-baseline.txt` in an unrelated finding, so the filename
# alone is satisfied today by a document that says nothing about the ratchet at all. The check-id
# alone is the mirror gap — it says what is emitted without saying that it is frozen.
#
# ⚠️ THIS IS THE ONE RULE IN THIS FILE THE MUTATION CATALOGUE CANNOT REACH. Every mut_HEALTH_*
# sabotages bin/sdd, and no sabotage of bin/sdd can make a document say less — the house rule for
# that is a probe of the sensor's own, so the rule carries four, and they run BEFORE the verdict.
# A doc_rule that had stopped discriminating would otherwise report a clean policy over documents
# it never read, which is the fail-open shape this repo pays the most for.
# ---------------------------------------------------------------------------
POLICY_ID='todo-findings'
POLICY_FILE='health-baseline.txt'
POLICY_DOCS='CLAUDE.md TODO.md'
POLICY_DESC='the ratchet policy is written where the next mission meets it'

doc_rule() { # doc_rule <path> — 0 when the document states the ratchet policy
  local path="$1"
  [ -r "$path" ] || return 1
  grep -qF -- "$POLICY_ID" "$path" && grep -qF -- "$POLICY_FILE" "$path"
}

# policy_silent <root> — the documents of POLICY_DOCS that do not state the policy, space-joined.
policy_silent() {
  local root="$1" d out=""
  for d in $POLICY_DOCS; do
    if ! doc_rule "$root/$d"; then
      if [ -z "$out" ]; then out="$d"; else out="$out $d"; fi
    fi
  done
  printf '%s' "$out"
}

# policy_report <root> — the VERDICT, over any root. Parameterised for one reason only: a probe
# has to be able to run this block, not just the function under it. The rule that probes measure
# the PATH and not only the parser was learned in check-todo.sh, where every probe proved the
# parser right while the caller counted with a grep that did not.
policy_report() {
  local silent; silent="$(policy_silent "$1")"
  if [ -z "$silent" ]; then
    pass "$POLICY_DESC"
    return 0
  fi
  fail "$POLICY_DESC" \
       "$POLICY_DOCS each carry the literals '$POLICY_ID' and '$POLICY_FILE'" \
       "silent in: $silent"
  return 1
}

# ── the probes ────────────────────────────────────────────────────────────────────────────────
# broken() and not fail(): a policy rule that stopped discriminating makes the verdict below a
# verdict about nothing, and one red assertion among eight would be outvoted by seven green ones.
# Same reasoning as every other SENSOR-BROKEN here.
#
# They drive the real verdict path over fabricated roots, one document at a time, because the
# THREE layers degrade separately: the two literals (doc_rule), which document is looked at
# (policy_silent), and whether a silent world is actually reported (policy_report). Dropping
# TODO.md from POLICY_DOCS leaves the real repo green today, since both documents state the
# policy — the probe with a silent TODO.md is the only thing that notices.
PROBE_ROOT="$WORK/policy"
mkdir -p "$PROBE_ROOT"
STATES="the ratchet freezes $POLICY_ID in tests/$POLICY_FILE"
QUIET='a document about something else entirely'

probe_policy() { # probe_policy <name> <expected silent list> <CLAUDE.md line> <TODO.md line>
  local name="$1" want="$2" got
  printf '%s\n' "$3" > "$PROBE_ROOT/CLAUDE.md"
  printf '%s\n' "$4" > "$PROBE_ROOT/TODO.md"
  got="$(policy_silent "$PROBE_ROOT")"
  [ "$got" = "$want" ] \
    || broken "policy probe '$name' reported silent:'$got', expected silent:'$want' — the rule stopped discriminating, so its verdict on the real documents means nothing"
}

probe_policy 'both silent'              'CLAUDE.md TODO.md'  "$QUIET"  "$QUIET"
probe_policy 'the check-id alone'       'CLAUDE.md'          "the ratchet emits $POLICY_ID"         "$STATES"
probe_policy 'the file name alone'      'CLAUDE.md'          "the baseline is tests/$POLICY_FILE"   "$STATES"
# ⚠️ There is no `a silent CLAUDE.md` / `a silent TODO.md` pair here, and their absence is a
# RESULT, not an oversight. Both were written, and the 14-degradation coverage matrix showed each
# of them was subsumed: every sabotage they caught was caught by something else in this block, so
# neither was ever the sole reason a degraded sensor went red. `both silent` carries the
# per-document rule on its own — its expected value names both files, so a document dropped from
# POLICY_DOCS shows up there. Removed rather than documented, the way check-health's own
# `1 check(s) failed` set was: a rule no single sabotage needs is decoration.

# An unreadable document is a rule with nowhere to live, never a rule that is satisfied. It gets
# a world of its OWN rather than being folded into the verdict probes below, and the coverage
# matrix is why: sharing one world with them left no sabotage that this rule alone could catch,
# and a rule no sabotage can isolate is decoration by this repo's own standard.
printf '%s\n' "$STATES" > "$PROBE_ROOT/TODO.md"; rm -f "$PROBE_ROOT/CLAUDE.md"
PROBE_GONE="$(policy_silent "$PROBE_ROOT")"
[ "$PROBE_GONE" = 'CLAUDE.md' ] \
  || broken "policy probe 'a document that does not exist' reported silent:'$PROBE_GONE', expected silent:'CLAUDE.md' — an unreadable document is a rule with nowhere to live, not a satisfied one"

# The verdict block itself, over BOTH worlds, on a document that exists. Run in a SUBSHELL so the
# output and the `fails` increment die with it. Without the silent world, the two lines that turn
# a silent document into a red run are the one layer no probe touches. Without the green world,
# a verdict that refused EVERY world would satisfy the silent one while distinguishing nothing —
# the anti-vacuity floor, and the only thing that catches `if false; then`.
printf '%s\n' "$QUIET" > "$PROBE_ROOT/CLAUDE.md"
PROBE_OUT="$( policy_report "$PROBE_ROOT" 2>&1 )"; PROBE_RC=$?
[ "$PROBE_RC" -ne 0 ] && grep -q 'silent in: CLAUDE.md' <<< "$PROBE_OUT" \
  || broken "the policy verdict reported rc $PROBE_RC over a world with a silent document — the rule discriminates and the report does not say so"
printf '%s\n' "$STATES" > "$PROBE_ROOT/CLAUDE.md"
PROBE_OUT="$( policy_report "$PROBE_ROOT" 2>&1 )"; PROBE_RC=$?
[ "$PROBE_RC" -eq 0 ] && grep -qF "  ok    $POLICY_DESC" <<< "$PROBE_OUT" \
  || broken "the policy verdict reported rc $PROBE_RC over a world where both documents state the policy — a rule that refuses every world distinguishes nothing"

policy_report "$ROOT"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "sdd health discriminates"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
