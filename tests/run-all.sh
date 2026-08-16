#!/usr/bin/env bash
# The kit's suite. It is bash + markdown, so the "tests" are the kit's own sensors: the runner
# syntax, the template contract, the gate state machine, and the language of the kit surface.
#
# Usage: tests/run-all.sh

set -uo pipefail

# Every test that runs bin/sdd could write to the autonomy ledger — check-dry-run already
# exercises the real escalation path. Without this, each suite run would inject fixture rows into
# the developer's ~/.sdd/autonomy-log.jsonl, and the judge would read fixtures as missions. The
# export lives here, at the top, so it holds for tests that do not exist yet.
SDD_TEST_STATE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-suite-state-XXXXXX")"
export SDD_STATE_DIR="$SDD_TEST_STATE"
trap 'rm -rf "$SDD_TEST_STATE"' EXIT

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fails=0

run() { # run <name> <command...>
  printf '\n\033[1m▸ %s\033[0m\n' "$1"; shift
  if "$@"; then :; else printf '\033[31m  ✗ failed\033[0m\n' >&2; fails=$((fails + 1)); fi
}

run "runner syntax (bash -n)" bash -n "$ROOT/bin/sdd"

# Beside the syntax check because it measures the same thing — bin/sdd as a FILE — and needs no
# fixture. Deliberately NOT guarded by SDD_MUTANT: it is the only thing that catches
# mut_RUN_entrypoint_unguarded, and it reads nothing the mutation sandbox does not copy.
run "entry point cannot fall through into itself" "$ROOT/tests/check-entrypoint.sh"

# The lint surface: the runner PLUS every suite script. For a long time it was bin/sdd alone,
# which left ~2400 lines of tests/ unlinted — and the linter was right about them: SC2318 in
# check-mutation.sh had `local slug="$1" box="$WORK/$slug"` reading the CALLER's global `slug`,
# correct only by the coincidence that the loop variable shares the name. Rename the loop variable
# and every mutant silently shares one sandbox. A sensor that never opens the file cannot see that.
#
# The floor is the anti-vacuity guard, same reason as the ones in check-lang.sh and
# check-pipefail.sh: a glob that stops matching, or a list someone narrows back to bin/sdd, leaves
# the linter reporting "clean" over files it never read — the failure mode where the sensor claims
# to have measured what it did not. 12 paths today; the floor moves only on purpose, in a commit
# that says why.
#
# Mind the wording of any comment here: a line whose first word after `#` is the linter's own name
# is parsed as a DIRECTIVE, and an unparseable one is an ERROR (SC1073/SC1072) — this very block
# tripped it while being written. Keep that token out of the leading position.
#
# An adversarial pass degraded each rule below on its own and demanded a red for each. Dying as
# they should: the list narrowed to the runner alone, a glob that matches nothing, `-S error`, and
# the SC2318 itself put back into check-mutation.sh. The two that SURVIVE are named rather than
# hidden, and neither is a one-edit hole — alone, neither changes a single file the linter opens:
#   - zeroing LINT_FLOOR (harmless until someone ALSO narrows the list)
#   - neutering the probe's verdict (harmless until someone ALSO weakens LINT_SEVERITY)
# Confirmed by running each pair: two edits, and only two, put this step back to sleep.
# ONE definition of the severity, read by the real scan AND by the probe below — the house rule
# about an enum read in more than one place. Written twice, raising it to `error` would silence
# SC2318 in the scan while the probe went on asserting `warning` and stayed green: a sensor
# certifying a threshold nobody runs at. The risk table of this mission forbade lowering `-S`;
# this is what makes the ban a sensor instead of a sentence.
#
# The floor moved 12 → 13 when tests/check-entrypoint.sh landed. It tracks the real count on
# purpose: left at 12 it would still pass, and would have gone on describing a surface one file
# smaller than the one it reads — the label-instead-of-artifact shape this whole mission is about.
LINT_SEVERITY=warning
LINT_FLOOR=13

lint_surface() {
  local files=("$ROOT/bin/sdd") f
  for f in "$ROOT"/tests/*.sh; do [ -f "$f" ] && files+=("$f"); done

  # Anti-vacuity, half 1 — the LIST. Catches the glob that stops matching and the list narrowed
  # back to the runner alone.
  if [ "${#files[@]}" -lt "$LINT_FLOOR" ]; then
    printf '  lint surface shrank to %d path(s), expected at least %d — did something move?\n' \
      "${#files[@]}" "$LINT_FLOOR" >&2
    return 1
  fi

  # Anti-vacuity, half 2 — the SEVERITY. A full file list linted at a threshold that reports
  # nothing is the same green as linting nothing at all. The probe carries a real SC2318, the very
  # defect this extended surface was born to catch, and it is demanded BY CODE rather than by
  # exit status alone: a probe rejected for a missing shebang would also exit non-zero, and would
  # prove the linter runs while proving nothing about what it still sees.
  local box out rc
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-lint-probe-XXXXXX")"
  printf '%s\n' '#!/usr/bin/env bash' 'f() { local a="$1" b="$a"; echo "$b"; }' > "$box/probe.sh"
  out="$(shellcheck -S "$LINT_SEVERITY" "$box/probe.sh" 2>&1)"; rc=$?
  rm -rf "$box"
  if [ "$rc" -eq 0 ] || ! grep -q 'SC2318' <<< "$out"; then
    printf '  the linter no longer flags a known SC2318 at -S %s — severity weakened, or the\n  linter is a stub? (rc %d)\n' \
      "$LINT_SEVERITY" "$rc" >&2
    return 1
  fi

  shellcheck -S "$LINT_SEVERITY" "${files[@]}"
}

# Inside a mutant (SDD_MUTANT=1) only the BEHAVIOURAL sensors run. The linter stays out because a
# mutant caught by the linter proves nothing about the gates — the assertion the mutation wants is
# "the gate noticed", not "the linter complained".
if [ -z "${SDD_MUTANT:-}" ]; then
  if command -v shellcheck >/dev/null 2>&1; then
    run "lint: the runner and the whole suite" lint_surface
  else
    printf '\n  (linter absent — skipped)\n'
  fi
fi

# check-lang reads paths (docs/, README.md, agents/) that the mutation sandbox does not copy —
# inside a mutant it would fail for a missing file, not for language, and the mutant would score a
# point for the wrong reason. Same guard as the linter, for the same reason.
[ -n "${SDD_MUTANT:-}" ] || run "language: no Portuguese prose on the kit surface" \
  "$ROOT/tests/check-lang.sh"

# Guarded for a reason of its OWN, and the sharpest one in this file: mut_RUN_jidoka_pipefail
# INJECTS `printf … | grep -q` into the mutant's bin/sdd. Unguarded, this sensor would kill that
# mutant on sight and the catalogue would score a point for "the linter complained" — stealing it
# from the 20000-row fixture in check-gates.sh that is the only thing actually proving the runner
# still notices a blocked increment. A sensor that makes an expensive behavioural fixture
# redundant has not added coverage, it has hidden the loss of some.
[ -n "${SDD_MUTANT:-}" ] || run "no writer piped into grep -q (pipefail)" \
  "$ROOT/tests/check-pipefail.sh"

# Same guard and same reason as check-lang above: the mutation sandbox copies bin/ tests/
# templates/ config/, never TODO.md — inside a mutant this would fail for a missing file, not for
# shape, and the mutant would score a point for the wrong reason. It also tests no gate, so it
# could never score a legitimate one.
[ -n "${SDD_MUTANT:-}" ] || run "findings file holds its shape" "$ROOT/tests/check-todo.sh"

run "template contract" "$ROOT/tests/check-templates.sh"
run "gate state machine" "$ROOT/tests/check-gates.sh"
run "dry-run projection" "$ROOT/tests/check-dry-run.sh"
run "autonomy ledger" "$ROOT/tests/check-autonomy.sh"
run "kaizen series and gate" "$ROOT/tests/check-kaizen.sh"

# This one used to be guarded like the three above, on the reasoning "preflight is not a gate, so
# it can never score a point inside a mutant". That stopped being true the day the file also
# started asserting the `sdd install` starter.conf guard: it now measures RUNNER BEHAVIOUR, and
# mut_RUN_install_no_guard is caught here or nowhere. The guard was the sensor's own blind spot —
# it kept the mutant green while the sabotage worked, which is the failure the catalogue exists to
# find. The second half of the old reason was never true either: `sdd install` iterates agents/
# with `[ -e ] || continue`, so the sandbox not copying it costs nothing.
# Cost of letting it in, measured: 0.14 s per run, ~0.6 s of wall clock across the whole pool.
run "preflight and the install guard" "$ROOT/tests/check-preflight.sh"

# Sensor of the sensor. Outside the guard this would be infinite recursion: every mutant runs this
# same suite. check-mutation.sh has the twin guard and dies if it is born with SDD_MUTANT set.
[ -n "${SDD_MUTANT:-}" ] || run "mutation: the suite dies when the runner is sabotaged" \
  "$ROOT/tests/check-mutation.sh"

printf '\n'
if [ "$fails" -eq 0 ]; then printf '\033[32m\033[1msuite green\033[0m\n'; exit 0; fi
printf '\033[31m\033[1m%d suite(s) failed\033[0m\n' "$fails" >&2
exit 1
