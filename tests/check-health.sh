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
#   8-11. the four silent aborts, prefixed `abort:` — cmd_health may not DIE where it was written
#      to speak. Each demands the sentence of the right branch AND that a check after the site
#      still appears; see the block header down the file for why the rc alone proves nothing.
#   12. the ratchet policy is written where the next mission meets it — CLAUDE.md and TODO.md. The
#      one rule here that no mut_HEALTH_* can reach, since none of them can make a document say
#      less, so it carries probes of its own over all three of its layers.
#   13. the OTHER two provenance comparisons, prefixed `covered:` — the qa-execution report and the
#      codereview grade table. Assertion 4 reaches one of the three; these two sat permanently on
#      the `skipped` branch, so either could have been `if true` with this file fully green.
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

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# The verdict-relevant lines of an output, flattened onto one line for a FAIL report. It carries
# the suite/score/gates lines too, and not only the ratchet's: the `abort:` assertions are ABOUT
# what the run stopped saying, so a digest that dropped those would report the silence as silence.
digest() { grep -E 'suite (green|red)|blind|gates have a mutation|baseline|provenance|finding count|kit healthy|check\(s\) failed|diverged from the skill|grade table has a criterion' <<< "$1" | tr '\n' ' '; }

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

# The stub suite. Three switches, all defaulting to the healthy world: assertion 7 needs a suite
# that prints everything except the finding count, assertion 9 one that prints everything except
# the score, and assertion 8 one that is simply RED. Each has to be the ONLY thing that changes
# between the two worlds it compares — hence one writer with switches, not four heredocs drifting
# apart. The defaults are what keeps the existing two calls reading as they did.
write_stub_suite() { # write_stub_suite <with-count|no-count> [with-score|no-score] [exit code]
  local count_line="" score_line="" rc="${3:-0}"
  [ "$1" = "with-count" ] \
    && count_line="printf '  ok    %d finding(s), all within 8 lines and carrying anchor + date\\n' $STUB_TODO_COUNT"
  [ "${2:-with-score}" = "with-score" ] \
    && score_line="printf '%s\\n' '$STUB_SCORE'"

  cat > "$FIX/tests/run-all.sh" <<EOF
#!/usr/bin/env bash
# Stub suite. See the RECURSION note in tests/check-health.sh: the real one runs that file, which
# runs this command, which would run the real one.
#
# It records its own argv, and that file is the whole evidence of the "surface:" assertion below:
# what cmd_health ACTUALLY passed, read off the call itself. A grep over bin/sdd would certify the
# TEXT of an invocation rather than the invocation — green for a call that moved, or that a second
# code path bypasses. Written by the stub because the stub is the only witness standing where the
# argument arrives.
printf '%s\n' "\$*" > "$FIX/tests/stub-argv.txt"
$score_line
$count_line
exit $rc
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

# The qa-execution report template — health_provenance's FIRST comparison, and one of the two
# nothing ever installed. Same decision as install_bug_skill and for the same reason: the content
# is DERIVED from the check-gates.sh fixture, never typed here. A template written from memory is
# the exact defect provenance exists to catch, and this sensor would end up confirming the
# assumption instead of measuring it.
install_report_skill() { # install_report_skill <the '- **Started:**' line>
  local dir="$FIX/home/.claude/skills/qa-execution/assets"
  mkdir -p "$dir"
  printf '%s\n' '# QA execution report' '' "$1" > "$dir/report-template.md"
}

# The codereview grade table — the THIRD comparison, and the one no mut_HEALTH_* could reach: it
# is a loop of a different shape from the other two. The path spells out what health_provenance's
# `find -path '*/codereview/*/references/report-template.md'` matches, and mirrors the real cache
# layout (…/<marketplace>/codereview/<version>/skills/codereview/references/). The table itself is
# the check-gates.sh fixture's own, read off the file — see GRADE_TABLE below.
install_codereview_skill() { # install_codereview_skill <extra table row, or "">
  local dir="$FIX/home/.claude/plugins/cache/fixture-marketplace/codereview/1.13.0/skills/codereview/references"
  mkdir -p "$dir"
  {
    printf '%s\n' "$GRADE_TABLE"
    [ -n "$1" ] && printf '%s\n' "$1"
    printf '\n## Grading Scale\n'
  } > "$dir/report-template.md"
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
# 13 — the other two provenance comparisons, which nothing ever reached
#
# health_provenance compares THREE fixtures against three installed skills, and until this
# assertion exactly one of them — the qa-report bug template of assertion 4 — had a fixture that
# got that far. The other two stayed permanently on the `skipped` branch, because no test in the
# repo ever installed a qa-execution report template or a codereview grade table: both comparisons
# could have read `if true` for a whole mission with every assertion in this file green. The
# catalogue says so in as many words — mut_HEALTH_provenance_blind is range-addressed to the one
# half that could honestly carry a mutation, and names the other two as an open finding.
#
# ONE assertion over FOUR worlds, because it is ONE property: a fixture that drifted from the
# skill it copies is reported, and one that matches is not. Each half is differential in BOTH
# directions — its own sentence present, the sibling comparison's sentence absent — so a
# provenance that started shouting every sentence in every world fails here instead of passing on
# the strength of the one it got right.
#
# The two worlds install ONE skill each rather than both at once, and that is what makes the
# absence half mean something: with both installed, "the grade-table sentence is absent" would be
# satisfied by a grade table that simply happens to match, not by a comparison that stayed quiet.
# ---------------------------------------------------------------------------
# The `- **Started:**` line as bin/sdd normalises it. `<ISO timestamp>` is the SKILL's own
# placeholder (qa-execution/assets/report-template.md), which is why normalising the fixture's
# concrete timestamp lands on the installed skill's line byte for byte — that equality is the
# contract, and the case below refuses to install a template that could never satisfy it.
PROV_REPORT_LINE="$(grep -m1 -- '- \*\*Started:\*\*' "$ROOT/tests/check-gates.sh" \
                    | sed 's/2026-01-01T10:00:00Z/<ISO timestamp>/')"
case "$PROV_REPORT_LINE" in
  *'<ISO timestamp>'*) : ;;
  *) broken "the check-gates.sh '- **Started:**' line no longer carries the timestamp bin/sdd normalises ('$PROV_REPORT_LINE') — the match world would install a template that can never agree, and the assertion would be red for the fixture instead of for the runner" ;;
esac

# The fixture's OWN grade table, copied out whole: header, separator, every criterion row and the
# `**Overall**` row, which is the shape the real plugin ships (report-template.md:163-172,
# chewiesoft-marketplace/codereview). Copied rather than re-derived so this file does not carry a
# second implementation of the runner's criterion parser — what is under test is whether cmd_health
# compares the criteria at all, not how they are spelled.
GRADE_TABLE="$(awk '/^\| Criterion \| Grade/ { t = 1 }
                    t && substr($0, 1, 1) != "|" { exit }
                    t { print }' "$ROOT/tests/check-gates.sh")"
# Anti-vacuity: with an empty (or one-row) table the runner's loop runs over nothing, `missing`
# stays empty, and the matching world would be green for having measured nothing at all.
GRADE_ROWS="$(grep -c . <<< "$GRADE_TABLE")"
[ "$GRADE_ROWS" -ge 5 ] \
  || broken "check-gates.sh no longer carries a grade table of at least 5 rows (got $GRADE_ROWS) — the criteria loop would run over nothing and the codereview half would pass by vacuity"

# A criterion check-gates.sh cannot contain: the divergence has to be a criterion the fixture does
# NOT cover, and any real one would be covered by construction.
UNKNOWN_CRITERION='Fixture Criterion Nobody Ever Graded'

clear_skills
set_baseline "$CALIBRATED"
install_report_skill "$PROV_REPORT_LINE"
health_run
OUT_REP_OK="$HEALTH_OUT"; RC_REP_OK="$HEALTH_RC"

clear_skills
install_report_skill "$PROV_REPORT_LINE  <!-- and one column the fixture never had -->"
health_run
OUT_REP_BAD="$HEALTH_OUT"; RC_REP_BAD="$HEALTH_RC"

clear_skills
install_codereview_skill ""
health_run
OUT_CR_OK="$HEALTH_OUT"; RC_CR_OK="$HEALTH_RC"

clear_skills
install_codereview_skill "| $UNKNOWN_CRITERION | A | fixture |"
health_run
OUT_CR_BAD="$HEALTH_OUT"; RC_CR_BAD="$HEALTH_RC"

if [ "$RC_REP_OK" -eq 0 ] && ! grep -q 'diverged from the skill' <<< "$OUT_REP_OK" \
   && [ "$RC_REP_BAD" -ne 0 ] \
   && grep -q 'report fixture diverged from the skill' <<< "$OUT_REP_BAD" \
   && ! grep -q 'grade table has a criterion' <<< "$OUT_REP_BAD" \
   && [ "$RC_CR_OK" -eq 0 ] && ! grep -q 'grade table has a criterion' <<< "$OUT_CR_OK" \
   && [ "$RC_CR_BAD" -ne 0 ] \
   && grep -qF "grade table has a criterion the fixture does not cover: '$UNKNOWN_CRITERION'" <<< "$OUT_CR_BAD" \
   && ! grep -q 'diverged from the skill' <<< "$OUT_CR_BAD"; then
  pass "covered: the report and the grade table are compared too, not only the bug fixture"
else
  fail "covered: the report and the grade table are compared too, not only the bug fixture" \
       "the matching worlds rc 0 and silent, the drifted report says only 'report fixture diverged from the skill', the drifted table says only 'grade table has a criterion the fixture does not cover: $UNKNOWN_CRITERION'" \
       "report match: rc $RC_REP_OK · $(digest "$OUT_REP_OK") // report drift: rc $RC_REP_BAD · $(digest "$OUT_REP_BAD") // table match: rc $RC_CR_OK · $(digest "$OUT_CR_OK") // table drift: rc $RC_CR_BAD · $(digest "$OUT_CR_BAD")"
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
# 8-11 — the four silent aborts: `set -e` may not eat the rest of the run
#
# cmd_health captures what it reads with `out="$(cmd)"` under the runner's own `set -euo pipefail`.
# When cmd returns non-zero the script dies ON THE ASSIGNMENT, so the health_bad written on the
# next line is dead code and every check after it never runs: the operator gets the header, rc 1,
# and not one word about what went wrong. The command that exists to answer "does the kit still
# measure what it claims to?" was mute in four worlds — and A RED SUITE, the very case it was
# written to report, was one of them.
#
# EVERY ASSERTION HERE DEMANDS TWO HALVES, and the second is what makes it an assertion at all:
# the sentence of the right branch is said, AND something after the site still appears. `rc != 0`
# alone discriminates nothing, because health_bad also ends in rc 1 — an assertion reading only
# the rc stays green with the abort fully in place. Measured, not feared: that is exactly what the
# four probes of the planning session saw (rc 1 in all four, one line of output).
#
# The differential control is OUT_GREEN, the world of assertion 5: it must say none of it.
# ---------------------------------------------------------------------------

# Back to the world OUT_GREEN was read from, so each sabotage below is the ONLY thing standing
# between the fixture and `kit healthy`.
green_world() { write_stub_suite with-count; clear_skills; set_baseline "$CALIBRATED"; }

# The last line cmd_health prints when it walked the whole way, and the strongest `after` there
# is: reaching it means no check was skipped. Named once because three assertions read it — a
# wording drift would otherwise make three assertions vacuous one at a time and unnoticed.
VERDICT='check(s) failed'
# A check that lives after the suite capture AND after the score read — the "and it carried on"
# half of the two assertions whose site is at the top of cmd_health.
LATER='all 8 gates have a mutation'

green_world
write_stub_suite with-count with-score 1
health_run
OUT_SUITE_RED="$HEALTH_OUT"; RC_SUITE_RED="$HEALTH_RC"

if [ "$RC_SUITE_RED" -ne 0 ] \
   && grep -qF 'suite red' <<< "$OUT_SUITE_RED" \
   && grep -qF "$LATER" <<< "$OUT_SUITE_RED" \
   && grep -qF "$VERDICT" <<< "$OUT_SUITE_RED" \
   && ! grep -qF 'suite red' <<< "$OUT_GREEN"; then
  pass "abort: a red suite is said out loud and the run carries on"
else
  fail "abort: a red suite is said out loud and the run carries on" \
       "rc != 0 and 'suite red' and '$LATER' and '$VERDICT', with the green world saying none of it" \
       "rc $RC_SUITE_RED · $(digest "$OUT_SUITE_RED")"
fi

green_world
write_stub_suite with-count no-score
health_run
OUT_NO_SCORE="$HEALTH_OUT"; RC_NO_SCORE="$HEALTH_RC"

if [ "$RC_NO_SCORE" -ne 0 ] \
   && grep -qF 'health went blind to the mutation' <<< "$OUT_NO_SCORE" \
   && grep -qF "$LATER" <<< "$OUT_NO_SCORE" \
   && grep -qF "$VERDICT" <<< "$OUT_NO_SCORE" \
   && ! grep -qF 'went blind to the mutation' <<< "$OUT_GREEN"; then
  pass "abort: a suite with no score line is said out loud and the run carries on"
else
  fail "abort: a suite with no score line is said out loud and the run carries on" \
       "rc != 0 and 'health went blind to the mutation' and '$LATER' and '$VERDICT'" \
       "rc $RC_NO_SCORE · $(digest "$OUT_NO_SCORE")"
fi

# The third site says nothing on its own — a machine with no plugins cache is not a defect, it is
# a machine, and health_provenance SKIPS what is not installed. So this one is written as a pure
# DIFFERENTIAL: the two worlds have to reach the SAME verdict, and the floor underneath (both
# reach `kit healthy`, and the line compared is not empty) is what stops two identical silences
# from satisfying it. Today they are not the same at all — the cacheless one dies inside `find`,
# three ok lines and out, because `find` on a missing directory returns 1 under pipefail.
green_world
health_run
OUT_CACHE="$HEALTH_OUT"; RC_CACHE="$HEALTH_RC"
rm -rf "$FIX/home/.claude/plugins"
health_run
OUT_NO_CACHE="$HEALTH_OUT"; RC_NO_CACHE="$HEALTH_RC"
PROV_WITH="$(grep 'provenance:' <<< "$OUT_CACHE")"
PROV_WITHOUT="$(grep 'provenance:' <<< "$OUT_NO_CACHE")"

if [ "$RC_CACHE" -eq 0 ] && [ "$RC_NO_CACHE" -eq 0 ] \
   && grep -qF 'kit healthy' <<< "$OUT_NO_CACHE" \
   && [ -n "$PROV_WITH" ] && [ "$PROV_WITH" = "$PROV_WITHOUT" ]; then
  pass "abort: a machine with no plugins cache reads the same as one with an empty cache"
else
  fail "abort: a machine with no plugins cache reads the same as one with an empty cache" \
       "both worlds rc 0 and 'kit healthy', and one same non-empty provenance line" \
       "with cache: rc $RC_CACHE '$PROV_WITH' // without: rc $RC_NO_CACHE '$PROV_WITHOUT' · $(digest "$OUT_NO_CACHE")"
fi

# The fourth site is the ratchet's own first line, and the one with no later CHECK to point at —
# the ratchet IS the last one. So the `after` half is the verdict itself, which is also why
# health_ratchet may not return non-zero: a function that fails under `set -e` eats the verdict
# just as thoroughly as an assignment does, and the operator loses the count of what failed.
green_world
set_baseline '# every line commented out, and not one live finding'
health_run
OUT_DEAD_BL="$HEALTH_OUT"; RC_DEAD_BL="$HEALTH_RC"

if [ "$RC_DEAD_BL" -ne 0 ] \
   && grep -qF 'finding outside the baseline' <<< "$OUT_DEAD_BL" \
   && grep -qF "$VERDICT" <<< "$OUT_DEAD_BL" \
   && ! grep -qF 'finding outside the baseline' <<< "$OUT_GREEN"; then
  pass "abort: a baseline with no live line is said out loud and the run carries on"
else
  fail "abort: a baseline with no live line is said out loud and the run carries on" \
       "rc != 0 and 'finding outside the baseline' and '$VERDICT', with the green world saying neither" \
       "rc $RC_DEAD_BL · $(digest "$OUT_DEAD_BL")"
fi

# ---------------------------------------------------------------------------
# 12 — the policy is written where the next mission walks into it
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

# The live call is not here: both rule verdicts are issued from the counted list at the foot of
# this file. See the block there for why the two calls stopped being two statements.

# ---------------------------------------------------------------------------
# surface: the mutation catalogue is opt-in, and `sdd health` is the one caller that opts in
#
# The catalogue used to ride inside TEST_CMD. Measured, on this machine, with nothing else on it:
# one gate's suite held the working tree for over ten minutes. That is not a comfort problem — it
# made a PHASE unsatisfiable. Three REVIEW sessions of 20260818-lote-facil in a row ended their
# turn with the words "waiting for the suite", and in a headless `claude -p` session ending the
# turn IS ending the session; nobody wakes it up. US$ 104 of review bought no review.
#
# So the catalogue moved to `sdd health`. NOTHING WAS LOOSENED — every assertion is still demanded,
# once, by the command whose whole job is asking whether the kit still measures what it claims to.
# What these three assertions hold shut is the pair of ways that sentence could quietly stop being
# true, and they are opposite ways:
#
#   1. the fast suite grows the catalogue back        → gates go back to ten minutes
#   3. `sdd health` stops asking for it               → NOBODY runs it, and the kit goes blind
#
# 3 is the expensive one and it is silent: `sdd health` would still print `suite green`, still find
# no `score:` line, and say `health went blind to the mutation` — accusing check-mutation.sh of a
# defect that lives in its own caller. 2 is what keeps 1 and 3 from being satisfiable by a
# degenerate `--list`: the two lists compared against EACH OTHER, differing by exactly one line.
#
# `^mutation: ` is a contract across two files, like the `score:` line already is: tests/run-all.sh
# names the step, this file reads the name. Reword either alone and the suite goes red.
#
# Rules 1 and 2 are OUT OF THE CATALOGUE'S REACH and that is structural, not an oversight:
# check-mutation.sh sabotages `$box/bin/sdd` and only that (line ~1393), so no mutant can degrade
# tests/run-all.sh. A mutant that turned the step on unconditionally would also be caught for the
# WRONG reason — inside the sandbox it would recurse into check-mutation.sh, whose twin guard kills
# the suite, proving the recursion guard rather than these rules. So they carry probes of their
# own, below, in this file's `broken()` idiom. Rule 3 IS reachable, and is the one that gets a
# catalogue entry (mut_HEALTH_suite_without_mutation).
# ---------------------------------------------------------------------------
SURFACE_MUTATION_STEP='^mutation: '

# Anti-vacuity only, and deliberately NOT the real step count. A `--list` that prints nothing would
# satisfy "the plain suite does not carry the mutation step" while measuring exactly nothing; this
# floor is what refuses that.
#
# It is not a shrink detector, and the comment that used to stand here said the shrink question was
# "already owned" by LINT_FLOOR and the surface floors of check-pipefail.sh and check-lang.sh. That
# was measured and is FALSE: all three count paths or files, none counts dispatched steps, and
# commenting out one `run` line took the suite from 14 steps to 13 with every one of them green.
# What owns it now is rule 5 below — every sensor file invoked exactly once — which needs no fourth
# hand-written number because both of its sides are derived.
SURFACE_FLOOR=10

surface_lists() { # surface_lists <run-all.sh> — PUBLISHES SURFACE_PLAIN / SURFACE_FULL
  # Published in globals and called, never read through `x="$(...)"`: the house rule, and the same
  # subshell trap health_run above carries the comment for.
  #
  # ⚠️ `env -u SDD_MUTANT`, and it is not defensive noise — without it this rule fails inside every
  # mutant AND inside the control, which is how it was found. This file is NOT guarded out of the
  # mutants, so it runs with SDD_MUTANT=1 exported; run-all.sh then lists only the nine behavioural
  # steps (below the floor) and skips the catalogue step in BOTH lists (so nothing is ever added).
  # check-mutation.sh's control run went red and died before printing `score:`, and `sdd health`
  # reported `went blind to the mutation` — accusing the catalogue of a defect that was here.
  # The property is about the composition of a NORMAL run, so the probe has to ask a normal one.
  SURFACE_FILE="$1"
  SURFACE_PLAIN="$( env -u SDD_MUTANT "$1" --list 2>/dev/null )"
  SURFACE_FULL="$(  env -u SDD_MUTANT "$1" --list --with-mutation 2>/dev/null )"
}

# 0 = rules 1 and 2 both hold over the published lists. ONE definition, read by the verdict on the
# real file AND by every probe below — a second copy for the probes would let the two drift, and
# the probes would then certify a rule nobody runs.
surface_rules_hold() {
  local n added removed
  n="$(grep -c . <<< "$SURFACE_PLAIN" || true)"
  [ "$n" -ge "$SURFACE_FLOOR" ] || return 1
  # Rule 1: the fast suite does not carry the step.
  ! grep -qE "$SURFACE_MUTATION_STEP" <<< "$SURFACE_PLAIN" || return 1
  # Rule 2: --with-mutation adds it, and adds ONLY it. `removed` is not decoration — without it a
  # degradation that SWAPS one step for the mutation step would satisfy "exactly one added".
  added="$(comm -13 <(sort <<< "$SURFACE_PLAIN") <(sort <<< "$SURFACE_FULL"))"
  removed="$(comm -23 <(sort <<< "$SURFACE_PLAIN") <(sort <<< "$SURFACE_FULL"))"
  [ -z "$removed" ] || return 1
  [ "$(grep -c . <<< "$added" || true)" -eq 1 ] || return 1
  grep -qE "$SURFACE_MUTATION_STEP" <<< "$added" || return 1
  # Rule 4: every sensor file is invoked EXACTLY ONCE by the suite, counted over the invocation
  # form `$ROOT/tests/<file>` and not the bare name — this file's prose names check-mutation.sh
  # seven times, and a rule that counts mentions counts comments. It answers two questions at once,
  # which is why the separate rule that used to sit here was deleted as subsumed rather than probed:
  #
  #   too FEW — a sensor quietly unhooked. Rules 1-3 read only `--list`, and nothing else in this
  #     repo counts dispatched steps: commenting out one `run` line left check-lang.sh,
  #     check-pipefail.sh and this file green over a suite of 13. Measured.
  #   too MANY — the catalogue invoked a SECOND time, beside run(). `--list` prints only what goes
  #     through run(), so that world reinstates the ten-minute regression with every assertion here
  #     printing `ok`. Reproduced end to end: the plain suite really executed the catalogue.
  #
  # Both sides are derived — the files on disk, the invocations in the file under test — so there
  # is no fourth hand-written number to fall behind.
  local f n_inv
  for f in "$ROOT"/tests/check-*.sh; do
    n_inv="$(grep -c "\$ROOT/tests/$(basename -- "$f")" "$SURFACE_FILE" || true)"
    [ "$n_inv" -eq 1 ] || return 1
  done
  return 0
}

# --- the probes, and each one proves it sabotaged what it says it sabotaged -----------------
# A probe whose edit did not land concludes "the rule survives" over a file it never changed. Two
# rounds of this house have made exactly that mistake, so the anchor is CODE and a miss is loud.
SURF="$WORK/surface"
mkdir -p "$SURF/tests"

surface_degrade() { # surface_degrade <sed-expression> <what it should have changed>
  cp "$ROOT/tests/run-all.sh" "$SURF/tests/run-all.sh"
  sed -i "$1" "$SURF/tests/run-all.sh"
  cmp -s "$ROOT/tests/run-all.sh" "$SURF/tests/run-all.sh" \
    && broken "surface probe '$2' changed nothing — the anchor rotted, and a probe over an unedited file proves nothing"
  bash -n "$SURF/tests/run-all.sh" 2>/dev/null \
    || broken "surface probe '$2' left run-all.sh invalid — a rule cannot be measured against a file that will not parse"
  surface_lists "$SURF/tests/run-all.sh"
}

# The control FIRST: a degraded world means nothing if the pristine copy does not pass.
cp "$ROOT/tests/run-all.sh" "$SURF/tests/run-all.sh"
surface_lists "$SURF/tests/run-all.sh"
surface_rules_hold \
  || broken "the pristine copy of run-all.sh fails its own surface rules — the probes below would all be vacuous"

surface_degrade 's/^\[ -n "${SDD_MUTANT:-}" \] || \[ "$WITH_MUTATION" = 0 \] \\$/[ -n "${SDD_MUTANT:-}" ] \\/' 'mutation step unconditional'
surface_rules_hold \
  && broken "the surface rules passed a suite that runs the catalogue WITHOUT being asked — rule 1 is decoration"

surface_degrade 's/^    --with-mutation) WITH_MUTATION=1 ;;$/    --with-mutation) WITH_MUTATION=0 ;;/' '--with-mutation does nothing'
surface_rules_hold \
  && broken "the surface rules passed a suite where --with-mutation adds nothing — rule 2 is decoration"

surface_degrade 's/^  if \[ "$LIST_ONLY" = 1 \]; then printf .%s.n. "$1"; return 0; fi$/  if [ "$LIST_ONLY" = 1 ]; then return 0; fi/' 'a --list that prints nothing'
surface_rules_hold \
  && broken "the surface rules passed an empty --list — the anti-vacuity floor is decoration"

# --- probes that isolate ONE rule each ------------------------------------------------------
# The three above prove the COMPOSITION and nothing finer: an adversarial pass deleted the floor,
# rule 1 and the `removed` check one at a time and all three probes stayed green, because every
# world they build also violates rule 2's `added` grep. A probe that several rules answer proves
# only that at least one of them is awake. Each world below is answered by exactly one rule, so
# deleting that rule turns exactly one of them red.
#
# The floor: six steps removed, so the list shrinks below it while --with-mutation still adds
# exactly the catalogue step. Rule 2 is satisfied throughout; only the floor refuses this.
surface_degrade '0,/^run "sdd health discriminates"/s/^run "/# run "/; 0,/^run "preflight and the install/s/^run "/# run "/' 'a suite that lost steps'
surface_rules_hold \
  && broken "the surface rules passed a suite that quietly lost steps — the anti-vacuity floor answers no world of its own"

# Rule 1: a SECOND, unguarded catalogue step, listed by --list. Plain then carries `mutation: `
# while --with-mutation still adds exactly one matching step, so rule 2, the floor and `removed`
# are all satisfied. This is the world rule 1 exists for, and the first draft had none.
surface_degrade 's@^\[ -n "${SDD_MUTANT:-}" \] || \[ "$WITH_MUTATION" = 0 \] \\@run "mutation: an unguarded second caller" true\n&@' 'a second, unguarded mutation step'
surface_rules_hold \
  && broken "the surface rules passed a plain suite carrying a mutation step — rule 1 answers no world of its own"

# `removed`: a SWAP. With --with-mutation the gate sensor is not listed and the catalogue is, so
# exactly one step is added and it matches — a sensor silently leaves the suite and only the
# `removed` term notices.
surface_degrade 's@^run "gate state machine" "\$ROOT/tests/check-gates.sh"$@[ "$WITH_MUTATION" = 0 ] \&\& &@' 'a step that --with-mutation drops'
surface_rules_hold \
  && broken "the surface rules passed a suite that SWAPPED a step for the catalogue — the 'removed' term answers no world of its own"

# The `added` COUNT: --with-mutation brings a second step along with the catalogue. The added set
# still contains a `mutation: ` line, so the content grep is satisfied and only the count refuses.
surface_degrade 's@^\[ -n "${SDD_MUTANT:-}" \] || \[ "$WITH_MUTATION" = 0 \] \\@[ "$WITH_MUTATION" = 1 ] \&\& run "an extra step riding along" true\n&@' 'a second step added by --with-mutation'
surface_rules_hold \
  && broken "the surface rules passed a --with-mutation that adds two steps — the added count answers no world of its own"

# The `added` CONTENT: --with-mutation adds exactly one step, but not the catalogue. This is the
# cross-file half of `^mutation: ` — reword the step in run-all.sh and the name this file reads no
# longer finds it. Count, floor, `removed` and rule 4 are all satisfied here.
surface_degrade 's@^  || run "mutation: @  || run "catalogue: @' 'the mutation step renamed'
surface_rules_hold \
  && broken "the surface rules passed a --with-mutation that adds a step which is NOT the catalogue — the added-content grep answers no world of its own"

# The catalogue invoked a SECOND time, beside run(), where --list cannot see it. The fail-open an
# adversarial pass reproduced end to end: the plain suite really ran the catalogue.
surface_degrade 's@^printf ..n.$@if [ -z "${SDD_MUTANT:-}" ]; then "$ROOT/tests/check-mutation.sh" >/dev/null 2>\&1 || true; fi\n&@' 'a catalogue call outside run()'
surface_rules_hold \
  && broken "the surface rules passed a suite invoking the catalogue outside run() — --list cannot see it and rule 4 is decoration"

# Rule 5: one sensor quietly unhooked from the suite. Nothing else in this repo notices — measured
# on check-lang.sh, check-pipefail.sh and this file, all green over the 13-step suite.
# DELETED, not commented out: rule 5 counts invocations in the file text, so a `#` in front of the
# line leaves the invocation there and the probe would conclude over a world it did not build.
surface_degrade '/^run "gate state machine/d' 'a sensor unhooked from the suite'
surface_rules_hold \
  && broken "the surface rules passed a suite with a sensor unhooked — rule 5 is decoration and nothing owns the shrink question"

# --- the verdict, on the real file ----------------------------------------------------------
surface_lists "$ROOT/tests/run-all.sh"
if surface_rules_hold; then
  pass 'surface: the plain suite does not carry the mutation step, and --with-mutation adds only it'
else
  fail 'surface: the plain suite does not carry the mutation step, and --with-mutation adds only it' \
       "at least $SURFACE_FLOOR steps listed, none matching ${SURFACE_MUTATION_STEP}, and exactly one added by --with-mutation" \
       "plain: $(grep -c . <<< "$SURFACE_PLAIN" || true) step(s) · full: $(grep -c . <<< "$SURFACE_FULL" || true) step(s)"
fi

# Rule 3, read off the CALL and not off the text of bin/sdd. The stub records its own argv; this
# reads what cmd_health actually handed it.
green_world
health_run
SURFACE_ARGV="$(cat "$FIX/tests/stub-argv.txt" 2>/dev/null || true)"
# The two failing states are DIFFERENT and get different sentences. `printf '%s\n' "$*"` writes a
# bare newline for an empty argv and `$(...)` strips it, so "called with no arguments" and "never
# called" both arrive here as an empty string — and the default text accused the wrong one. That
# matters because `mut_HEALTH_suite_without_mutation`, the ONE defect this assertion exists for,
# lands in exactly the empty-argv branch: the operator was sent hunting for a deleted call when the
# real cause was a dropped flag. The file's existence is what tells them apart.
if grep -qF -- '--with-mutation' <<< "$SURFACE_ARGV"; then
  pass 'surface: cmd_health asks the suite for the mutation catalogue'
else
  if [ -e "$FIX/tests/stub-argv.txt" ]; then
    SURFACE_WHY="argv was '$SURFACE_ARGV' — the suite WAS called, without the flag; with no catalogue in TEST_CMD, nothing else runs it"
  else
    SURFACE_WHY="the stub suite was never called at all — cmd_health has no path to the suite"
  fi
  fail 'surface: cmd_health asks the suite for the mutation catalogue' \
       "the stub suite receives --with-mutation from cmd_health" \
       "$SURFACE_WHY"
fi

# ---------------------------------------------------------------------------
# guard: no capture in the `sdd health` region may abort the run
#
# The rule the four `abort:` assertions above cannot carry, and the reason it is written as a
# RULE and not as a fifth, sixth and seventh probe. `bin/sdd` runs under `set -euo pipefail`, so
# `x="$(cmd)"` kills the process AT THE ASSIGNMENT the moment `cmd` reports non-zero — and for
# `grep`, `find` and a `pipefail` pipeline, "non-zero" is simply "found nothing". Every
# `health_bad` written below such a line is dead code, and `sdd health` answers the one question
# it exists for by saying nothing at all.
#
# The mission 20260818-lote-facil closed FIVE of these one at a time and declared the family
# swept. The r2 review of that same mission then found ELEVEN more still live, in the same
# command, three of them reproduced end to end: renaming the gates made the run stop after check
# 2 without ever printing the `found 0 gates` its own comment promised; reformatting the key
# table of config/schema.md stopped it after check 4; and a skill that renamed the field
# `health_provenance` pins killed it in exactly the case that function exists to report.
#
# That is the lesson this block encodes: a per-site probe proves the sites that have a probe and
# says nothing about the twelfth. Enumerating the region instead makes the class unreinstatable —
# a future editor who writes a bare capture here fails the suite on the line they wrote, without
# anyone having to think of the world that would have exposed it. The mutation catalogue reaches
# it because it reads the runner that check-mutation.sh sabotages, not a copy frozen in here.
#
# FOUR properties, and the r2 review of this same mission measured that the first version had
# none of them. It knew ONE spelling — `x="$(cmd)"` — and every other way of writing a capture
# was invisible AND shrank the census in silence:
#
#   `x=$(cmd)`      no quotes. Aborts identically (measured: rc 1). Worse, it never contains the
#                   old `)"` terminator, so the open statement SWALLOWED the following lines until
#                   some later, guarded capture closed it — one guarded capture WASHING an
#                   unguarded one. Reproduced: rewriting the `gates` capture without quotes took
#                   the census from 16 to 15 and the rule went on printing `ok`.
#   `x=`cmd``       backticks. Same abort (measured: rc 1), no `$(` at all.
#   `x="$(`         the substitution opened at end of line: `[^(]` had nothing to match.
#   `x="$( (…) )"`  a real subshell, indistinguishable from arithmetic to the old exclusion.
#
# And the guard token was searched over the WHOLE accumulated statement, so a `|| true` inside a
# comment or a quoted string certified the capture beside it. The guard is now read in exactly the
# two places a guard can actually protect a capture, and both are ANCHORED — which is what leaves
# prose nowhere to sit:
#
#   inside, at the very end   `x="$(cmd || true)"` — the idiom this region uses everywhere. Only
#                             `|| true` and `|| :` count: under `set -o pipefail` the substitution
#                             reports its LAST stage, so a `|| true` in the middle of a pipeline
#                             guards nothing, and `|| anything_else` can itself report non-zero.
#   in the tail, at the start `x="$(cmd)" || rc=$?` — what the suite capture uses. Here ANY or-list
#                             counts, and that is not laxity: a command that is the left operand of
#                             `||` is exempt from errexit whatever the right operand does. Pinning
#                             the tail to the four spellings of the house style would accuse
#                             `x="$(cmd)" || health_bad "…"`, which cannot abort.
#
# Stripping a trailing comment before that test was written first and then DELETED: the anchors
# above already make it unreachable, an adversarial pass could not break it in any world, and this
# kit's rule for a rule the sabotage cannot break is to remove it, not to write a probe for it.
#
# The other direction matters as much: THREE shapes cannot abort at all, and a rule that fails on
# correct code is a rule the next author deletes. Measured on bash 5.2, `set -euo pipefail`:
# `if x="$(cmd)"; then` survives (the condition of `if` is exempt from errexit), and so does
# `local x="$(cmd)"` — the builtin's own status masks the substitution's. The split form the
# region actually uses, `local x; x="$(cmd)"`, aborts, and is censused.
#
# Joining by PAREN DEPTH was tried first and rejected: the region contains awk programs whose
# regexes carry unbalanced `)`, and a depth counter reads those as an unterminated statement. What
# replaces it is a per-spelling terminator plus a SPAN CAP, and the cap is what makes the parser
# fail closed: a statement this parser cannot see the end of is reported as `[unterminated]`
# instead of being allowed to eat its neighbours. Every shape below that this parser reads wrongly
# therefore lands on the loud side.
#
# Declared limits, none of them silent: a NESTED `$( … "$(…)" … )` closes on the inner `)"` and so
# reads as unguarded (loud, and there are none in the region); a here-doc BODY carrying an
# assignment would be censused as code (loud; the region has only `<<<` herestrings, checked); and
# two captures on one line are read as one.
# ---------------------------------------------------------------------------
CAPTURE_DESC='guard: every capture in the `sdd health` region is protected from set -e'

# Prints one line per unguarded capture, `<line>: <text>`. Region is anchored on comment and
# function text, never on line numbers, so it does not rot at the first refactor.
health_captures() {
  awk '
    function reset() { open = 0; acc = ""; kind = ""; safe = 0 }
    # `why` empty = the statement terminated and was read; otherwise it is reported as-is.
    function emit(pre_close, tail, why,   guarded) {
      total++
      if (why != "") { printf "%d: [%s] %s\n", start, why, substr(acc, 1, 110); reset(); return }
      if (safe) { safecnt++; reset(); return }
      guarded = 0
      if (pre_close ~ /\|\|[ \t]*(true|:)[ \t]*$/) guarded = 1
      if (tail ~ /^[ \t]*\|\|/) guarded = 1
      if (!guarded) printf "%d: %s\n", start, substr(acc, 1, 110)
      reset()
    }
    # Looks for the terminator of the open statement in `s` (an offset `off` into the raw line).
    # Returns 1 and calls emit() when it closes; 0 while the statement is still open.
    function close_try(line, from,   p, q, r) {
      if (kind == "dq") { p = index(substr(line, from), ")\""); if (p == 0) return 0
                          p = p + from - 1; emit(substr(line, 1, p - 1), substr(line, p + 2), ""); return 1 }
      if (kind == "bt") { p = index(substr(line, from), "`");   if (p == 0) return 0
                          p = p + from - 1; emit(substr(line, 1, p - 1), substr(line, p + 1), ""); return 1 }
      # bare `x=$(…)`: the last `)` on the line. There is no closing quote to anchor on, so the
      # guard can only be read from what precedes that paren and what follows it.
      q = 0; r = from
      while ((p = index(substr(line, r), ")")) > 0) { q = p + r - 1; r = q + 1 }
      if (q == 0) return 0
      emit(substr(line, 1, q - 1), substr(line, q + 1), ""); return 1
    }
    /^# Sensor of the KIT/ { inside = 1 }
    inside && /^cmd_status\(\) \{/ { if (open) emit("", "", "unterminated"); exit }
    !inside { next }
    {
      line = $0
      if (open) {
        acc = acc " " line; span++
        # A new capture while one is open means the open one never terminated. Saying so is what
        # keeps a guarded capture from laundering the unguarded one above it.
        if (line ~ /[A-Za-z_][A-Za-z0-9_]*\+?=("?\$\(|"?`)/) { emit("", "", "unterminated") }
        else if (close_try(line, 1)) { next }
        else if (span > 12) { emit("", "", "unterminated") }
        else { next }
      }
      rest = line; base = 0
      while (match(rest, /[A-Za-z_][A-Za-z0-9_]*\+?=("?\$\(|"?`)/)) {
        tok = substr(rest, RSTART, RLENGTH); abs = base + RSTART; after = abs + RLENGTH
        # Arithmetic `$((n + 1))` is not a capture. Without this the HEALTH_FAILS and
        # checked/skipped counters all read as unguarded and the rule fails closed on correct
        # code — which is how a rule gets deleted. `$( (` with a space IS a subshell and stays in.
        if (tok ~ /\$\($/ && substr(line, after, 1) == "(") {
          base = after - 1; rest = substr(line, after); continue
        }
        pre = substr(line, 1, abs - 1); sub(/^[ \t]+/, "", pre); sub(/[ \t]+$/, "", pre)
        safe = 0
        # The condition of if/elif/while/until is exempt from errexit; `; then`/`; do` means the
        # capture is already in the BODY and is not exempt.
        if (pre ~ /^(if|elif|while|until)([ \t]|$)/ && pre !~ /(then|do)$/) safe = 1
        # `local x="$(cmd)"` cannot abort: the builtin reports its own status. The split form the
        # region uses — `local x; x="$(cmd)"` — leaves `x;` as the last word here and is censused.
        if (pre ~ /(^|[ \t])(local|declare|typeset|export|readonly)$/) safe = 1
        kind = (tok ~ /`$/) ? "bt" : ((tok ~ /"\$\($/) ? "dq" : "bare")
        start = FNR; acc = line; open = 1; span = 1
        if (!close_try(line, after)) { }
        break
      }
    }
    END { if (open) emit("", "", "unterminated"); printf "TOTAL %d %d\n", total, safecnt }
  ' "$1"
}

# Floor against vacuity, and it is the only thing standing between this rule and a silent pass:
# if either anchor rots the region is empty, `health_captures` reports nothing, and "no unguarded
# capture" is exactly what a clean kit looks like.
#
# It is a BIDIRECTIONAL ratchet at today's census, and no longer the loose 12 it was born with.
# Two measurements changed the shape. The first: 12 against 16 real captures let four of them
# vanish without a word — the same silence the rule exists to refuse. The second: an adversarial
# pass put the constant back to 12 and NOTHING went red, so the number was decoration.
#
# The comment this replaces argued for a floor over an equality, "so that adding a guarded capture
# does not fail the suite of the mission that added it". That reasoning is overridden on purpose,
# by this repo's own dominant convention: CLAUDE.md says growth is allowed and SILENT growth is
# not, and both `todo-findings` and `tests/lang-allowlist.txt` bite in both directions for exactly
# that reason. A mission that adds a capture to the health region is already editing this family;
# moving one number in the same commit is the record, and the failure message says so.
CAPTURE_FLOOR=16

capture_report() {
  local out total safe offenders
  out="$(health_captures "$1/bin/sdd")"
  total="$(awk '/^TOTAL /{print $2}' <<< "$out")"
  safe="$(awk '/^TOTAL /{print $3}' <<< "$out")"
  offenders="$(grep -v '^TOTAL ' <<< "$out")"
  if [ -z "$total" ] || [ "$total" -lt "$CAPTURE_FLOOR" ]; then
    fail "$CAPTURE_DESC" \
         "at least $CAPTURE_FLOOR capture(s) censused in the health region" \
         "${total:-none} — either the region anchors rotted and this rule measured nothing, or a capture left: move CAPTURE_FLOOR in the same commit"
    return 1
  fi
  if [ "$total" -gt "$CAPTURE_FLOOR" ]; then
    fail "$CAPTURE_DESC" \
         "exactly $CAPTURE_FLOOR capture(s) — the ratchet bites in both directions" \
         "$total — a capture was added to the health region: move CAPTURE_FLOOR to $total in the same commit, so the growth is in a diff with an author"
    return 1
  fi
  if [ -n "$offenders" ]; then
    fail "$CAPTURE_DESC" \
         "every capture guarded by '|| true', '|| :', '|| return' or '|| rc=\$?'" \
         "$(tr '\n' ' ' <<< "$offenders")"
    return 1
  fi
  pass "$CAPTURE_DESC ($total censused, $safe of them unable to abort)"
  return 0
}

# Probes over the PARSER and over the CALLER, because this repo has already shipped a sensor
# whose probes proved the parser while the path from "a defect exists" to "the suite is red" had
# no probe at all. `capture_report` is invoked for real below on the live runner; here it is
# invoked on synthetic regions whose answer is known.
CAPPROBE="$WORK/capguard"; mkdir -p "$CAPPROBE/bin"
cap_world() { printf '# Sensor of the KIT\n%s\ncmd_status() {\n' "$1" > "$CAPPROBE/bin/sdd"; }
cap_offenders() { health_captures "$CAPPROBE/bin/sdd" | grep -cv '^TOTAL '; }
cap_total() { health_captures "$CAPPROBE/bin/sdd" | awk '/^TOTAL /{print $2}'; }
cap_safe()  { health_captures "$CAPPROBE/bin/sdd" | awk '/^TOTAL /{print $3}'; }
# Prints the offender lines themselves, so a probe can assert WHICH capture was accused and not
# merely that the count is right — a rule that reports the neighbour is a rule that measured
# nothing, and this file has already shipped one.
cap_lines() { health_captures "$CAPPROBE/bin/sdd" | grep -v '^TOTAL ' || true; }

cap_world '  x="$(grep foo bar)"'
[ "$(cap_offenders)" = 1 ] || broken "capture probe 'a bare capture' was not reported — the rule reads nothing"
cap_world '  x="$(grep foo bar || true)"'
[ "$(cap_offenders)" = 0 ] || broken "capture probe 'a guarded capture' was reported — the rule refuses correct code"
cap_world '  x="$( cd . && ls )" || rc=$?'
[ "$(cap_offenders)" = 0 ] || broken "capture probe '|| rc=\$?' was reported — the guard the suite capture uses is not recognised"
# The continuation case, and the reason the join exists at all: written without it, the real
# `find` of health_provenance reads as unguarded and the rule fails closed on the live runner.
cap_world '  x="$(find /tmp -name z \
         2>/dev/null | tail -1 || true)"'
[ "$(cap_offenders)" = 0 ] || broken "capture probe 'guard on the continuation line' was reported — the statement join does not span lines"
cap_world '  x="$(find /tmp -name z \
         2>/dev/null | tail -1)"'
[ "$(cap_offenders)" = 1 ] || broken "capture probe 'unguarded across two lines' was not reported — the join swallows the defect with the statement"
# Arithmetic is not a capture. Unprobed, `[^(]` looks like a typo to the next reader and gets
# removed, and the rule then reports every counter in the region.
cap_world '  n=$((n + 1))
  HEALTH_FAILS=$((HEALTH_FAILS + 1))'
[ "$(cap_offenders)" = 0 ] && [ "$(cap_total)" = 0 ] \
  || broken "capture probe 'arithmetic expansion' was counted as a capture — the rule fails closed on every counter"
# The region is bounded at BOTH ends: text before the header and after cmd_status is invisible.
cap_world '  x="$(grep foo bar || true)"'
printf '  y="$(grep after censo)"\n' >> "$CAPPROBE/bin/sdd"
[ "$(cap_offenders)" = 0 ] || broken "capture probe 'after cmd_status' was censused — the region has no end anchor"

# --- the five spellings r2 measured passing invisibly ------------------------------------------
# One probe per spelling, and each asserts the CENSUS too: the defect was never "no offender
# printed", it was "no offender printed AND the total silently shrank", which is what let a floor
# of 12 sit over sixteen real captures and notice nothing.
cap_world '  x=$(grep foo bar)'
[ "$(cap_offenders)" = 1 ] && [ "$(cap_total)" = 1 ] \
  || broken "capture probe 'unquoted \$( )' was not reported — measured: it aborts under set -e exactly like the quoted form (rc 1, bash 5.2)"
cap_world '  x=$(grep foo bar || true)'
[ "$(cap_offenders)" = 0 ] && [ "$(cap_total)" = 1 ] \
  || broken "capture probe 'unquoted and guarded' was reported — the rule refuses correct code in the spelling it just learned"
cap_world '  x=`grep foo bar`'
[ "$(cap_offenders)" = 1 ] && [ "$(cap_total)" = 1 ] \
  || broken "capture probe 'backtick' was not reported — measured: it aborts under set -e (rc 1)"
cap_world '  x=`grep foo bar || true`'
[ "$(cap_offenders)" = 0 ] \
  || broken "capture probe 'backtick, guarded' was reported — the rule refuses correct code"
cap_world '  x="$(
    grep foo bar)"'
[ "$(cap_offenders)" = 1 ] \
  || broken "capture probe 'substitution opened at end of line' was not reported — the opener regex demands a character that is not there"
cap_world '  x="$( (cd /tmp && ls) )"'
[ "$(cap_offenders)" = 1 ] \
  || broken "capture probe 'subshell \$( ( … ) )' was not reported — the arithmetic exclusion swallowed a real capture"

# The washing case, and the reason this rule stopped joining until `)"`. An unterminated capture
# used to keep the statement open and let the NEXT capture's guard certify it — one line of
# sabotage buying silence for two, and the second capture never counted at all. Both must be
# censused and the FIRST must be the one accused by name: a rule that reports the neighbour
# measured nothing. Written with an opener the parser genuinely cannot close on its own line,
# because that is the only shape that exercises the rule: a first draft used `x=$(a b)`, which
# closes on its own `)`, and the sabotage that deletes this rule survived it.
cap_world '  x="$(grep a b
  y="$(grep c d || true)"'
[ "$(cap_total)" = 2 ] && [ "$(cap_offenders)" = 1 ] && [[ "$(cap_lines)" == *'[unterminated]'* ]] \
  || broken "capture probe 'a guarded capture washing an unguarded one' — census $(cap_total), offenders $(cap_offenders): the open statement still eats its neighbour"
# Same shape one level down: the washing detector has to know every opener spelling too, or a
# backtick capture below an open statement buys the same silence.
cap_world '  x="$(grep a b
  y=`grep c d || true`'
[ "$(cap_total)" = 2 ] && [ "$(cap_offenders)" = 1 ] \
  || broken "capture probe 'a backtick capture washing an unguarded one' — census $(cap_total): the washing detector knows fewer spellings than the scanner"

# --- the guard token is read where a guard can actually protect ---------------------------------
# Searched over the whole statement, `|| true` written in PROSE certified the capture beside it.
cap_world '  x="$(grep foo bar)"  # or write || true here'
[ "$(cap_offenders)" = 1 ] \
  || broken "capture probe 'a comment mentioning || true' certified an unguarded capture — the token is still read outside code"
cap_world '  x="$(grep foo || true bar)"'
[ "$(cap_offenders)" = 1 ] \
  || broken "capture probe '|| true mid-pipeline' certified the capture — under pipefail the status is the LAST stage's, so a guard that is not at the end guards nothing"
# The tail accepts ANY or-list, and it is measured rather than assumed: a command that is the left
# operand of `||` is exempt from errexit whatever the right operand is. Pinning the tail to the
# house style would accuse this line, which cannot abort.
cap_world '  x="$(grep foo bar)" || health_bad "no score line"'
[ "$(cap_offenders)" = 0 ] \
  || broken "capture probe 'tail guarded by an or-list that is not || true' was accused — the rule refuses a shape that cannot abort"

# --- the three shapes that cannot abort ---------------------------------------------------------
# Measured on bash 5.2 under `set -euo pipefail`, each in its own script (probe3/probe4 of the r3
# round): `if x="$(false)"` and `local x="$(false)"` both survive; `local x; x="$(false)"` exits 1.
# They are counted in the census — they ARE captures in the region — and reported as unable to
# abort. A rule that fails on correct code is a rule the next author deletes.
cap_world '  if x="$(grep foo bar)"; then :; fi'
[ "$(cap_offenders)" = 0 ] && [ "$(cap_safe)" = 1 ] \
  || broken "capture probe 'if-condition' was accused — errexit exempts the condition of if, and the fix the message asks for would break the if"
cap_world '  local x="$(grep foo bar)"'
[ "$(cap_offenders)" = 0 ] && [ "$(cap_safe)" = 1 ] \
  || broken "capture probe 'local x=\$(…)' was accused — the builtin reports its own status and masks the substitution's"
cap_world '  local x; x="$(grep foo bar)"'
[ "$(cap_offenders)" = 1 ] && [ "$(cap_safe)" = 0 ] \
  || broken "capture probe 'local x; x=\$(…)' was excused — the SPLIT form is the one the region uses and it does abort"
cap_world '  if [ -z "$q" ]; then y="$(grep foo bar)"; fi'
[ "$(cap_offenders)" = 1 ] \
  || broken "capture probe 'capture in an if BODY' was excused as a condition — a '; then' ends the exemption"

# The span cap: a statement whose end this parser cannot see is reported, never dropped. The probe
# has to put a PLAUSIBLE terminator far below the opener — a first draft simply left the statement
# open to the end of the region, and the `END` fallback reported it with the cap deleted, so the
# sabotage that removes the cap survived. Here the far line closes the statement and carries a
# `|| true` right before it: without the cap the opener is read as guarded and vanishes.
cap_world '  x="$(grep foo bar
  # 1
  # 2
  # 3
  # 4
  # 5
  # 6
  # 7
  # 8
  # 9
  # 10
  # 11
  # 12
  # prose that happens to end like this || true)"'
[ "$(cap_offenders)" = 1 ] && [[ "$(cap_lines)" == *'[unterminated]'* ]] \
  || broken "capture probe 'a statement whose terminator is 14 lines away' was certified by it — the span cap does not fail closed"

# The floor, in the direction the r2 review measured as decoration: putting the constant back to
# the 12 it was born with must not be free. Asserted over the LIVE region, because that is the one
# whose census the number is supposed to track.
CAP_FLOOR_KEEP2="$CAPTURE_FLOOR"
CAPTURE_FLOOR=12
( capture_report "$ROOT" >/dev/null 2>&1 ) \
  && broken "the capture verdict passed with CAPTURE_FLOOR below the live census — the constant is decoration, which is what let 12 sit over sixteen captures"
CAPTURE_FLOOR="$CAP_FLOOR_KEEP2"

# And the caller: a world with an offender must make `fails` grow, and a world with none must
# not. Run in a subshell so the FAIL text and the increment die with it.
cap_world '  a="$(grep 1 f || true)"
  b="$(grep 2 f || true)"
  c="$(grep 3 f)"'
CAP_FLOOR_KEEP="$CAPTURE_FLOOR"
CAPTURE_FLOOR=3
( capture_report "$CAPPROBE" >/dev/null 2>&1 ) \
  && broken "the capture verdict passed a world holding an unguarded capture — the rule discriminates and the report does not say so"
cap_world '  a="$(grep 1 f || true)"
  b="$(grep 2 f || true)"
  c="$(grep 3 f || true)"'
( capture_report "$CAPPROBE" >/dev/null 2>&1 ) \
  || broken "the capture verdict refused a world where every capture is guarded — a rule that refuses every world distinguishes nothing"
# The floor itself, over the same clean world: a census below it is not a pass.
CAPTURE_FLOOR=99
( capture_report "$CAPPROBE" >/dev/null 2>&1 ) \
  && broken "the capture verdict passed a census below its own floor — the anti-vacuity floor is decoration"
CAPTURE_FLOOR="$CAP_FLOOR_KEEP"

# ---------------------------------------------------------------------------
# The rule verdicts over the LIVE kit, as a counted list and no longer as two statements dropped
# beside their own probes.
#
# Every rule above is probed; the CALL that puts each rule on the live runner was not, and an
# adversarial pass measured the cost: deleting the single line `capture_report "$ROOT"` left this
# file green — every probe still passing, `sdd health discriminates`, rc 0 — over a `bin/sdd` whose
# `gates` capture had had its `|| true` removed. That is the whole family this mission exists to
# make unreinstatable, certified as absent by the sensor written to find it.
#
# The catalogue does reach it (`mut_HEALTH_gates_capture_aborts` survives the deletion, measured),
# but since the catalogue left TEST_CMD it only runs when a human types `sdd health
# --with-mutation`. A composition this load-bearing may not wait for that, so it is made countable
# here — the shape CLAUDE.md records from check-entrypoint.sh: top-level calls a probe can count,
# a derived expectation that bites when one is deleted, and a tally that bites when the loop goes.
#
# What is NOT claimed, because the adversarial pass measured it: neutering the equality below, or
# pointing it at the list it is supposed to check, survives — and then deleting an entry is free
# again. Two edits, not one. The outer witness for that residue is the mutation catalogue, and it
# was measured rather than assumed: with the live call gone, `mut_HEALTH_gates_capture_aborts`
# survives (`bin/sdd` with its `gates` guard removed, this file green, rc 0), so the catalogue
# reports the gap. This comment says "two edits" and not "unreachable in one edit" on purpose —
# r2 measured the second sentence to be false where a sensor header claimed it.
RULE_REPORTS=(policy_report capture_report)
# The expected count is DERIVED and not written by hand. A hand-written floor was tried first and
# an adversarial pass set it to 0 for free — the same shape as the `CAPTURE_FLOOR=12` this round
# is here to fix, a constant guarding a list with nothing guarding the constant. Counting the
# `*_report()` definitions instead puts the two halves in independent places: a rule defined above
# and left out of the list below fails on the mismatch, in either direction. A helper that ends in
# `_report` and is not a rule verdict fails it too — loudly, which is the right side to fail on.
RULE_REPORTS_DECLARED="$(grep -c '^[a-z_]*_report() {' "${BASH_SOURCE[0]}" || true)"
[ "${#RULE_REPORTS[@]}" -eq "$RULE_REPORTS_DECLARED" ] \
  || broken "${#RULE_REPORTS[@]} rule verdict(s) listed but $RULE_REPORTS_DECLARED defined in this file — a rule was probed in here and never run against the live kit"
REPORTS_RUN=0
for _rule_report in "${RULE_REPORTS[@]}"; do
  "$_rule_report" "$ROOT" || true
  REPORTS_RUN=$((REPORTS_RUN + 1))
done
[ "$REPORTS_RUN" -eq "${#RULE_REPORTS[@]}" ] \
  || broken "$REPORTS_RUN of ${#RULE_REPORTS[@]} rule verdict(s) were issued — the loop that runs them is not running them"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "sdd health discriminates"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
