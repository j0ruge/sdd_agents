#!/usr/bin/env bash
# Sensor of the sensor: proves the suite MEASURES something.
#
# Sabotages the runner in a COPY and demands the suite go RED. An assertion that cannot fail is
# indistinguishable from one that passes — that is how three gate bugs of the SAME family crossed
# a green suite and only showed up in real use, at ~US$ 40 in re-run sessions (see KAIZEN_LOG).
# A fixture written from memory agrees with the wrong gate forever.
#
# WARNING: exporting SDD_MUTANT in your shell skips the linter AND the mutation for the whole
# suite — the variable is the anti-recursion mechanism, not a user option.
#
# Usage: tests/check-mutation.sh   (exit 0 = catalogue intact and every unlisted mutation caught)

set -uo pipefail

# Double guard against recursion: run-all.sh already does not call this script when SDD_MUTANT is
# set. If we got here with it set, the guard over there fell — dying loudly beats fork-bombing the
# machine of whoever ran the suite.
if [ -n "${SDD_MUTANT:-}" ]; then
  echo "check-mutation.sh is running INSIDE a mutant — the run-all.sh guard has fallen" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# JOBS resolution
#
# The default derives from the machine instead of being the constant 4 it used to be: a 20-core
# box was pinned to 4 while a 2-core one was oversubscribed by the same constant. Capped at 8 —
# each mutant runs a whole copy of the suite, and past that point the copies fight for disk and
# memory instead of finishing sooner. An explicit SDD_MUTATION_JOBS always wins; garbage in it is
# refused by name, never silently degraded (0 used to reach `i % JOBS` as a division by zero).
# ---------------------------------------------------------------------------
detect_cores() { # behaviour, not presence — the bin/sdd preflight pattern for the GNU userland
  nproc 2>/dev/null && return
  getconf _NPROCESSORS_ONLN 2>/dev/null && return
  sysctl -n hw.ncpu 2>/dev/null && return
  echo 4
}

resolve_jobs() { # resolve_jobs <env-value> <cores> — pure; prints JOBS or refuses by name
  local env_value="$1" cores="$2"
  if [ -n "$env_value" ]; then
    # ONE validation arm, deliberately. A first draft paired this case with a `[ -ge 1 ]` check
    # and the adversarial pass proved them redundant — either alone refuses everything, with the
    # same message. `0*` covers both the literal 0 and leading zeros ("08" is octal to bash
    # arithmetic and used to CRASH the old `i % JOBS`, so refusing it by name is the upgrade).
    case "$env_value" in
      0*|*[!0-9]*) echo "SDD_MUTATION_JOBS must be an integer >= 1 (got: $env_value)" >&2; return 1 ;;
    esac
    echo "$env_value"; return
  fi
  case "$cores" in *[!0-9]*|'') cores=4 ;; esac
  [ "$cores" -ge 1 ] || cores=1
  [ "$cores" -gt 8 ] && cores=8
  echo "$cores"
}

# The catalogue cannot reach this function — it lives in the harness, not in bin/sdd — so it
# carries its own probes, the CLAUDE.md rule for sensors the mutation cannot kill. Pure-function
# pairs only; detect_cores is machine-dependent and stays unprobed (the chain is trivial to read).
jobs_selftest() {
  local got
  got="$(resolve_jobs "" 20)"      && [ "$got" = 8 ]  || { echo "  SELFTEST FAIL  cap: 20 cores resolved to '$got', expected 8" >&2; return 1; }
  got="$(resolve_jobs "" 2)"       && [ "$got" = 2 ]  || { echo "  SELFTEST FAIL  small box: 2 cores resolved to '$got', expected 2" >&2; return 1; }
  got="$(resolve_jobs "" 0)"       && [ "$got" = 1 ]  || { echo "  SELFTEST FAIL  floor: 0 cores resolved to '$got', expected 1" >&2; return 1; }
  got="$(resolve_jobs "" bogus)"   && [ "$got" = 4 ]  || { echo "  SELFTEST FAIL  garbage cores resolved to '$got', expected the 4 fallback" >&2; return 1; }
  got="$(resolve_jobs 1 20)"       && [ "$got" = 1 ]  || { echo "  SELFTEST FAIL  explicit env must win: got '$got', expected 1" >&2; return 1; }
  got="$(resolve_jobs 32 4)"       && [ "$got" = 32 ] || { echo "  SELFTEST FAIL  explicit env is not capped: got '$got', expected 32" >&2; return 1; }
  # Assert the MESSAGE, not just the rc: without the case arm, 'abc' is still refused — but by
  # `[ abc -ge 1 ]` erroring ("integer expression expected"), an accident sharing the same rc.
  got="$(resolve_jobs abc 20 2>&1)" && { echo "  SELFTEST FAIL  'abc' in the env was accepted" >&2; return 1; }
  case "$got" in *"must be an integer"*) : ;; *) echo "  SELFTEST FAIL  'abc' was refused by accident, not by name: $got" >&2; return 1 ;; esac
  resolve_jobs 0 20   >/dev/null 2>&1 && { echo "  SELFTEST FAIL  '0' in the env was accepted — it reaches i % JOBS as a division by zero" >&2; return 1; }
  resolve_jobs -1 20  >/dev/null 2>&1 && { echo "  SELFTEST FAIL  '-1' in the env was accepted" >&2; return 1; }
  return 0
}

if ! jobs_selftest; then
  echo "the JOBS resolution does not measure what it claims — refusing to schedule mutants with it" >&2
  exit 1
fi

JOBS="$(resolve_jobs "${SDD_MUTATION_JOBS:-}" "$(detect_cores)")" || exit 1
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-mut-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Catalogue
#
# Mutation idiom: find the line by a UNIQUE anchor and touch only that line. If the anchor
# disappears in a refactor, the `cmp` below reports "did not apply" instead of scoring a point — a
# mutation that does not sabotage is the decorative assertion this file exists to hunt, one level
# up. Anchor on CODE, never on prose: prose gets translated, code does not.
#
# Name: mut_<GATE>_<slug> for a gate, mut_RUN_<slug> for what is not a gate. `sdd health` uses
# that prefix to demand one mutation per gate — changing the convention blinds health.
# ---------------------------------------------------------------------------

mut_PLAN_empty_approval() {   # accepts an empty `aprovacao:` — an unapproved plan becomes runnable
  sed -i 's/^    auto)          : ;;/    auto)          : ;;\n    "")            : ;;/' "$1"
}

mut_TICKET_no_sprint() {      # stops requiring `sprint:` — a card in the backlog is invisible work
  sed -i "s|.*if ! grep -qiE '\^sprint:.*|  if false; then|" "$1"
}

mut_EXEC_done_without_commit() {  # accepts a 'done' increment with commit '—' — label becomes artifact
  sed -i 's|.*\[ "\$commit" = "—" \].*|        if false; then|' "$1"
}

mut_EXEC_orphan_commit() {    # back to `cat-file -e`: a loose object passes as a commit in history
  sed -i 's|.*git merge-base --is-ancestor.*|        if false; then|' "$1"
}

mut_EXEC_ignores_TEST_CMD() { # discards the suite's rc — the gate stops measuring TEST_CMD
  sed -i 's|.*run_check_cmd "\$TEST_CMD" "gate-exec-test".*|  if false; then|' "$1"
}

# Historical bug 1 (SQ-97 pilot, ~US$ 15 a round): the skill emits
# `- **Started:** <ts> · **Status:** in-progress`, and the gate required `**Status:**` to OPEN the
# line. It never matched; the runner re-ran qa-execution forever.
mut_QA_status_line_start() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '^\\\\*\\\\*Status:\\\\*\\\\*[[:space:]]*closed' \"\$report\"|" "$1"  # sdd-pipefail-waiver: sed s|…|…| delimiter, not a pipe
}

# Loose enum: the `closed` has to come right after `**Status:**`. With `.*closed` the template
# legend (`<!-- in-progress | closed -->`) matches, and a report still IN PROGRESS passes.
mut_QA_status_enum_loose() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '\\\\*\\\\*Status:\\\\*\\\\*.*closed' \"\$report\"|" "$1"  # sdd-pipefail-waiver: sed s|…|…| delimiter, not a pipe
}

# Same family, in the bug registry: with `.*open` the legend
# `<!-- open | fixed | verified | wont-fix | invalid -->` matches, and a `wont-fix` bug (a human
# decision, not a blocker) starts blocking the phase.
mut_QA_bug_enum_loose() {
  sed -i "s|\[\[:space:\]\]+open'|.*open'|" "$1"
}

mut_QA_matrix_pending() {     # ignores a 'Pending' matrix row — an unwalked journey passes
  sed -i 's|.*Pending\[\[:space:\]\]\*.*|    if false; then|' "$1"
}

mut_QA_bug_open() {           # ignores a bug with Status: open in the registry
  sed -i 's|.*\[ "\$openbugs" -gt 0 \].*|  if false; then|' "$1"
}

# Historical bug 3 (SQ-97 pilot, ~US$ 10): the parser exited only at `###`, kept swallowing the
# report's following tables and failed an all-Grade-A review for finding a `Commit` column.
mut_REVIEW_stops_at_h3() {
  sed -i 's|.*inside && /\^#{1,6}\[\[:space:\]\]/ { exit }.*|      inside \&\& /^###[[:space:]]/ { exit }|' "$1"
}

mut_REVIEW_accepts_B() {      # any grade passes — the gate stops requiring Grade A
  sed -i 's|if (grade != "A")|if (grade == "ZZZ")|' "$1"
}

mut_DOCS_pending_status() {   # accepts an area with Status '✗' in the drift checklist
  sed -i 's|.*\[ -n "\$pending_cell" \].*|  if false; then|' "$1"
}

mut_PR_no_artifact() {        # a missing 50-pr.md stops failing — a "complete" mission with no PR
  sed -i 's|GATE_WHY="missing 50-pr.md"; return 1|GATE_WHY="missing 50-pr.md"; return 0|' "$1"
}

# Not a gate, and the only decorative-assertion bug that really happened (TODO.md): the inverted
# guard makes the PROJECTION (`--dry-run`) write to the journal while the real path goes mute — a
# read command dirtying the working tree, and an audit trail lying in both directions.
mut_RUN_inverted_journal() {
  sed -i 's|\[ "\$DRY_RUN" = "1" \] && return 0|[ "$DRY_RUN" = "0" ] \&\& return 0|' "$1"
}

# Not a gate: the target repo declares OUTPUT_LANG and the runner swallows the request in silence.
# It is the typical failure mode of a config key — the key exists, the schema promises it, and
# nobody reads it (the LINT_CMD/BUILD_CMD/DEV_UP_CMD family, frozen in health-baseline).
mut_RUN_ignores_output_lang() {
  sed -i 's|.*if \[ -n "\$OUTPUT_LANG" \]; then.*|  if false; then|' "$1"
}

# Not a gate: the ledger the kaizen judge reads. The projection starts writing, and rows for
# sessions that never happened enter the arithmetic that decides whether the kit graduates.
mut_RUN_autonomy_ignores_dry_run() {
  sed -i 's|  if \[ "\$DRY_RUN" = "1" \]; then return 0; fi|  if false; then return 0; fi|' "$1"
}

# The reader treats a row with no `moved` field (an older schema) as "did not move" instead of
# excluding it. Old history gets its waste inflated, and every later change looks like progress —
# the failure mode is a judge that congratulates the kit for nothing.
mut_RUN_autonomy_null_moved_as_zero() {
  sed -i 's|and (has("moved"))|and true|' "$1"
}

# Task 2 review measured this one by hand (Minor 6): up to check-autonomy.sh's moved-sensor
# scenario, no test in the repo ever made a session actually change the disk — every `claude`
# stub was dead (rc 1) or dry, so `moved` was always "false" and this exact no-op scored a point
# for nothing. It matters now because waste is defined as sessions that did NOT move the disk: a
# regression here both escalates BLOCKED on phases that were genuinely progressing and records
# every session as waste, with the suite green throughout.
mut_RUN_moved_never_true() {
  sed -i 's|    \[ "\$before" != "\$after" \] && moved="true"|    true|' "$1"
}

# Not a gate: the one-shot guard on the "kit is not a git checkout" warning. It reads cosmetic and
# is not — the flag only holds because `autonomy_kit_stamp` publishes AUTONOMY_KIT_STAMP as a
# global instead of being read through `$( )`, which ran the whole body, and its assignment, in a
# SUBSHELL that reset the flag on every call. This mutation restores that exact behaviour by other
# means: the warning goes back to firing once per ledger row, and a guard nobody can see failing is
# the decorative assertion this file exists to hunt.
mut_RUN_autonomy_sha_warn_repeats() {
  sed -i 's|    AUTONOMY_SHA_WARNED=1|    AUTONOMY_SHA_WARNED=0|' "$1"
}

# The KAIZEN gate goes blind to WHICH kit sha a verdict judged: any verdict file satisfies it.
# check-kaizen.sh plants a stale verdict for an older sha with a complete born plan beside it —
# under this sabotage the pending-verdict scenario returns 0 ("already judged") instead of
# escalating, and an old judgement silently covers every future kit change.
mut_KAIZEN_gate_blind() {
  sed -i 's|if \[ "\$(frontmatter "\$f" kit_sha_judged)" = "\$expected" \]|if [ -f "$f" ]|' "$1"
}

# The Jidoka dies: `verdict: piorou` no longer stops the line. The outcome falls through to the
# born-plan branch and exits 0 — a kit change that made autonomy WORSE reads as a green light,
# which is the exact failure ADR 0002 exists to forbid.
mut_KAIZEN_jidoka_dead() {
  sed -i 's|if \[ "\$GATE_KAIZEN_VERDICT" = "piorou" \]; then|if false; then|' "$1"
}

# The approved-plan protection dies EVERYWHERE: this sed hits all three identical bailout guards
# in cmd_kaizen at once (a deliberate exception to the one-line idiom — the three sites are one
# mechanism, and sabotaging any subset is caught by the same scenarios). A filled `aprovacao:`
# then flows into fix-it sessions that can blank a human's approval, and a retry-written approval
# gets misreported as a no-progress escalation.
mut_KAIZEN_approved_bailout_dead() {
  sed -i 's|if \[ -n "\$GATE_KAIZEN_APPROVED" \]; then|if false; then|' "$1"
}

# The rubric's strongest signal is dropped: phases with an escalation, a human retry or a failing
# last gate label as "ok". The judge would congratulate the kit precisely on the missions where
# the human had to push the work again. RUN_ prefix: kaizen_series is a helper, not a gate —
# the two-prefix contract in the header comment holds.
mut_RUN_refez_dropped() {
  sed -i 's|then "refez"|then "ok"|' "$1"
}

# The guard floor goes back to counting every mission on the axis, escalations included: three
# missions that stopped the line without spending a single session free the judge to rule
# `melhorou` on a kit version it observed nothing of. Same RUN_ prefix and same reason as the
# mutation above — the floor lives in kaizen_series, a helper; KAIZEN_guard_ignored is the one
# that sabotages the gate that READS it, and the pair covers producer and consumer.
mut_RUN_guard_counts_escalations() {
  sed -i 's@missions_with_session: (\$sess @missions_with_session: (\$rows @' "$1"
}

# The guard stops guarding: gate_KAIZEN accepts `melhorou`/`piorou` written over an insufficient
# series. The whole point of the runner-owned guard (boot prompt: "the guard belongs to the
# runner") dies silently — a verdict label alone starts satisfying the gate, which is the
# label-instead-of-artifact failure principle 1 exists to forbid.
mut_KAIZEN_guard_ignored() {
  sed -i 's|if \[ "\$sufficient" != "true" \] && \[ "\$verdict" != "indeterminado" \]; then|if false; then|' "$1"
}

# Not a gate, and the most expensive false negative the runner can produce: the Jidoka goes back
# to a PIPE. Under `pipefail` `grep -q` exits on the match, `printf` dies of SIGPIPE and the
# pipeline returns 141, so the `if` reads "no blocked" while a blocked increment EXISTS — and the
# runner burns the whole phase budget against the wall it already knew was there. Note this is the
# sabotage that a SMALL fixture cannot see: the race is decided by the size of the text, which is
# why check-gates.sh asserts it on a 20000-row checkpoint.
mut_RUN_jidoka_pipefail() {
  sed -i 's@grep -qx "blocked" <<< "$ckstatus"@printf "%s\\n" "$ckstatus" | grep -qx "blocked"@' "$1"  # sdd-pipefail-waiver: this payload IS the bug, deliberately
}

# Not a gate, and the exact bug I2 closed: `force_phase="PR"; continue` sat ABOVE both writers, so
# the runner lowering its own bar — the single most interesting autonomy event a mission can
# produce — reached neither the journal nor the ledger. The series showed failing REVIEW sessions
# followed by a PR phase and nothing saying why, and the judge reads the series.
#
# It is also the guard on the reachability of an expensive fixture: check-autonomy.sh has to
# satisfy PLAN/TICKET/EXEC/QA and keep the disk MOVING to reach the draft branch at all. If a
# future change makes that fixture stop arriving there, this mutation stops being caught and the
# score says so — instead of a whole block of assertions passing over a branch nobody ran.
mut_RUN_degraded_row_dropped() {
  sed -i 's|autonomy_degraded_row "review-to-draft"|: "review-to-draft"|' "$1"
}

# Not a gate, and the other half of the same writer: the one-shot guard dies and the branch writes
# a row on EVERY lap. `force_phase="PR"` does not end the run — PR's gate fails, `current_phase`
# hands REVIEW back with the budget still blown, and the branch is re-entered. One degradation,
# three rows in both readers, against the "exactly one" of the mission's metric. This is the
# CARDINALITY of the record, which RUN_degraded_row_dropped (the writer's existence) cannot see:
# that one stays caught with the guard sabotaged, and this one stays caught with the writer intact.
#
# It is also what keeps check-autonomy.sh's degradation fixture in the REPEATING regime. The
# assertion it kills was green for two commits over a stub that moved the disk once, asserting a
# property of the fixture and not of the code — the third such vacuity of this mission.
mut_RUN_degraded_repeats() {
  sed -i 's|if \[ "\$degraded_logged" = "0" \]; then|if true; then|' "$1"
}

# Not a gate (RUN_ per the naming rule above — `cmd_autonomy` is a reader, not a gate): the human's
# escalation table loses the kit_sha axis and goes back to counting `.kind` over the whole ledger.
# The series keeps slicing per version, so the two instruments over the SAME file start reporting
# different escalation counts for the same period with nothing explaining the divergence — and kit
# version is the axis the ledger exists to measure. The `on_axis` filter is left ALONE on purpose:
# a mutant that sabotages both halves would stop distinguishing which one the assertions measure.
mut_RUN_escalations_no_axis() {
  sed -i 's|group_by(.kit_sha, .kind)|group_by(.kind)|' "$1"
}

# Not a gate: `phase_label` goes back to knowing only `blocked`, so a mission where the runner
# lowered its own bar reads `ok` in the judge's label histogram as soon as a later `sdd run` gets
# REVIEW past its gate — the rubric groups by (mission, phase) over the whole kit_sha slice, not
# per run. It sabotages ONLY phase_label's use of the shared predicate; the `escalations` map and
# the admission filter keep theirs, so what dies is the label and nothing else, and this mutant
# cannot be confused with RUN_degraded_row_dropped (the row's existence) or RUN_refez_dropped
# (the `refez` value itself, which stays reachable through the other two clauses).
mut_RUN_degraded_label_blind() {
  sed -i 's@if (map(select(is_escalation)) | length) > 0@if (map(select(.event == "blocked")) | length) > 0@' "$1"
}

# Not a gate (RUN_ per the naming rule above — latest_matching is a helper): the file picker goes
# back to a lexicographic `sort`, and `r10` sorts between `r1` and `r2`. From the tenth review
# round on, gate_REVIEW stops reading the round that just ran and reads `r3` — a review that was
# already all-A when it was approved, so the gate PASSES and the mission walks past a report
# nobody read. It is the sabotage that fails OPEN, and the one a fixture of three rounds cannot
# see: with REVIEW_MAX_ITER at 3 the two orders agree, which is exactly why check-gates.sh has to
# spend a fourth fixture on `r10`. The `sort -V` of health_skills (bin/sdd:1339) is left ALONE —
# the sed anchors on `ls -1d $pattern` — so what dies is the picker and nothing else.
mut_RUN_sort_lexi() {
  sed -i 's@ls -1d $pattern 2>/dev/null | sort -V@ls -1d $pattern 2>/dev/null | sort@' "$1"
}

# Turns the existence guard into a tautology, so `sdd install` walks into the sed again with a
# half-copied kit: 0-byte .sdd/config.sh on disk, and the next install reporting it as preserved.
# It is a sabotage that fails OPEN in the half that matters — rc stays non-zero either way,
# because sed's own rc is what killed the install before the guard existed. Only the assertions
# that read the branch's own text and the ABSENCE of the file can see it, which is the whole point
# of spending a mutation here. Anchors on `-f ` + the path: the `sed` line below feeds the same
# path with no `-f`, and is deliberately left alone.
mut_RUN_install_no_guard() {
  sed -i 's@-f "$SDD_HOME/config/starter.conf"@-n "always-there"@' "$1"
}

# Not a gate: the ledger readers go back to asking "can this row be attributed to a kit version?"
# in two spellings — `.kit_dirty == false` for sessions, `.kit_dirty != true` for escalations and
# for the judge. This is the EXACT pre-fix text, and it is why the mutant needs two edits: reverting
# `on_axis` alone would drag `comparable` lax with it (a wrong single definition), which is a
# different defect from the fork. What dies here is the differential assertion in check-autonomy —
# the twin rows with kit_dirty:null and a sha filled, where the escalation table grants a version
# the session table denies. Every row the runner writes today satisfies both spellings, so no
# fixture in the ordinary regime can tell this mutant from the fix.
mut_RUN_on_axis_forked() {
  sed -i \
    -e 's@def on_axis: .kit_dirty == false and .kit_sha != null;@def on_axis: .kit_dirty != true and .kit_sha != null;@' \
    -e 's@def comparable: .event == "session" and on_axis and (has("moved"));@def comparable: .event == "session" and .kit_dirty == false and (.kit_sha != null) and (has("moved"));@' \
    "$1"
}

CATALOG=(
  PLAN_empty_approval
  TICKET_no_sprint
  EXEC_done_without_commit
  EXEC_orphan_commit
  EXEC_ignores_TEST_CMD
  QA_status_line_start
  QA_status_enum_loose
  QA_bug_enum_loose
  QA_matrix_pending
  QA_bug_open
  REVIEW_stops_at_h3
  REVIEW_accepts_B
  DOCS_pending_status
  PR_no_artifact
  RUN_inverted_journal
  RUN_ignores_output_lang
  RUN_autonomy_ignores_dry_run
  RUN_autonomy_null_moved_as_zero
  RUN_moved_never_true
  RUN_autonomy_sha_warn_repeats
  RUN_jidoka_pipefail
  RUN_degraded_row_dropped
  RUN_degraded_repeats
  RUN_escalations_no_axis
  RUN_degraded_label_blind
  RUN_sort_lexi
  RUN_install_no_guard
  RUN_on_axis_forked
  KAIZEN_gate_blind
  KAIZEN_jidoka_dead
  KAIZEN_guard_ignored
  KAIZEN_approved_bailout_dead
  RUN_refez_dropped
  RUN_guard_counts_escalations
)

# Mutations that are NOT caught today, each with the increment that closes it. Ratchet in both
# directions: an uncaught one outside the list fails, and a listed gap that STARTED being caught
# fails too (the list has to shrink, never become a permanent excuse).
KNOWN_GAPS=()

# ---------------------------------------------------------------------------
pass()  { printf '  ok    %s\n' "$1"; }
fail()  { printf '  FAIL  %s\n         %s\n' "$1" "$2" >&2; }

in_gap_list() { # in_gap_list <slug>
  local x
  for x in ${KNOWN_GAPS[@]+"${KNOWN_GAPS[@]}"}; do
    [ "$x" = "$1" ] && return 0
  done
  return 1
}

sandbox() { # sandbox <target-dir> — the whole kit the suite needs, and nothing more
  mkdir -p "$1"
  cp -r "$ROOT/bin" "$ROOT/tests" "$ROOT/templates" "$ROOT/config" "$1/"
}

# run_mutant <slug> — writes $WORK/<slug>.rc and $WORK/<slug>.log
run_mutant() {
  # Two `local`s on purpose (SC2318): collapsed into one, the `$slug` on the right expands BEFORE
  # this line's own assignment lands, so it reads the caller's global — correct today only by the
  # coincidence that the loop variable happens to share the name. Rename the loop variable and
  # every mutant silently shares `$WORK/`, one box for all of them.
  local slug="$1"
  local box="$WORK/$slug"
  sandbox "$box"
  "mut_$slug" "$box/bin/sdd"
  if cmp -s "$ROOT/bin/sdd" "$box/bin/sdd"; then
    echo "the mutation did not apply — did the anchor change in bin/sdd?" > "$box.log"
    echo 90 > "$box.rc"; return
  fi
  if ! bash -n "$box/bin/sdd" 2>"$box.log"; then
    echo "the mutant is not valid bash" >> "$box.log"
    echo 91 > "$box.rc"; return
  fi
  SDD_MUTANT=1 "$box/tests/run-all.sh" > "$box.log" 2>&1
  echo $? > "$box.rc"
}

# ---------------------------------------------------------------------------
# CONTROL run — the copy has to be green with NO sabotage at all.
#
# Without it, a broken copy (a future test reading agents/ or docs/, for instance) would leave
# EVERY mutant red and the score would read 100% while measuring exactly nothing — the same
# vacuity the mutation exists to catch, now inside the measuring device itself.
# ---------------------------------------------------------------------------
echo "== control =="
sandbox "$WORK/control"
if SDD_MUTANT=1 "$WORK/control/tests/run-all.sh" > "$WORK/control.log" 2>&1; then
  pass "the kit copy is green with no sabotage"
else
  fail "HARNESS-BROKEN: the copy is not green even without sabotage" \
       "the score would read 100% by vacuity — see $WORK/control.log"
  tail -20 "$WORK/control.log" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# A pool, not batches: the old `[ i % JOBS -eq 0 ] && wait` was a barrier every JOBS mutants, so
# each batch cost its slowest member while the finished slots sat idle. `wait -n` frees a slot as
# soon as ANY mutant exits. Safe because run_mutant shares nothing — each writes its own
# $WORK/<slug>.rc/.log and the scoring loop below reads the catalogue in order afterwards.
# `wait -n` is bash 4.3+; without it, fall back to the barrier and SAY so — a declared
# degradation, never a silent one.
if (: & wait -n) 2>/dev/null; then
  echo "== mutants (pool of $JOBS) =="
  running=0
  for slug in "${CATALOG[@]}"; do
    run_mutant "$slug" &
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
  done
else
  echo "== mutants (batches of $JOBS — this bash has no 'wait -n', falling back to barriers) =="
  i=0
  for slug in "${CATALOG[@]}"; do
    run_mutant "$slug" &
    i=$((i + 1))
    [ $((i % JOBS)) -eq 0 ] && wait
  done
fi
wait

caught=0; gaps=0; errors=0
for slug in "${CATALOG[@]}"; do
  rc="$(cat "$WORK/$slug.rc" 2>/dev/null || echo 99)"
  case "$rc" in
    90|91)
      fail "CATALOGUE-BROKEN: $slug" "$(cat "$WORK/$slug.log")"; errors=$((errors + 1)) ;;
    0)
      # The suite stayed GREEN with the runner sabotaged: nobody measures this sabotage.
      if in_gap_list "$slug"; then
        printf '  warn  %s — known gap, the suite does not catch it (yet)\n' "$slug"
        gaps=$((gaps + 1))
      else
        fail "$slug is NOT caught" "the suite stayed green with the runner sabotaged — an assertion is missing"
        errors=$((errors + 1))
      fi ;;
    99)
      fail "$slug produced no result" "the mutant died before writing its rc"
      errors=$((errors + 1)) ;;
    *)
      if in_gap_list "$slug"; then
        fail "$slug is in KNOWN_GAPS but is ALREADY caught" \
             "gap closed — drop it from the list, or it becomes a permanent excuse"
        errors=$((errors + 1))
      else
        pass "$slug — the suite dies (rc $rc)"
        caught=$((caught + 1))
      fi ;;
  esac
done

echo
# `cmd_health` in bin/sdd greps this exact line. The two sides are one contract across two files:
# change the wording here and the health check goes blind, which is why it fails on a missing
# line instead of passing in silence.
printf 'score: %d caught, %d known gap(s), of %d\n' "$caught" "$gaps" "${#CATALOG[@]}"
if [ "$errors" -eq 0 ]; then exit 0; fi
printf '%d problem(s) in the catalogue\n' "$errors" >&2
exit 1
