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
JOBS="${SDD_MUTATION_JOBS:-4}"
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
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '^\\\\*\\\\*Status:\\\\*\\\\*[[:space:]]*closed' \"\$report\"|" "$1"
}

# Loose enum: the `closed` has to come right after `**Status:**`. With `.*closed` the template
# legend (`<!-- in-progress | closed -->`) matches, and a report still IN PROGRESS passes.
mut_QA_status_enum_loose() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '\\\\*\\\\*Status:\\\\*\\\\*.*closed' \"\$report\"|" "$1"
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
  local slug="$1" box="$WORK/$slug"
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
echo "== mutants (batches of $JOBS) =="
i=0
for slug in "${CATALOG[@]}"; do
  run_mutant "$slug" &
  i=$((i + 1))
  [ $((i % JOBS)) -eq 0 ] && wait
done
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
