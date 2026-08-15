#!/usr/bin/env bash
# The kit's suite. It is bash + markdown, so the "tests" are the kit's own sensors: the runner
# syntax, the template contract, the gate state machine, and the language of the kit surface.
#
# Usage: tests/run-all.sh

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fails=0

run() { # run <name> <command...>
  printf '\n\033[1m▸ %s\033[0m\n' "$1"; shift
  if "$@"; then :; else printf '\033[31m  ✗ failed\033[0m\n' >&2; fails=$((fails + 1)); fi
}

run "runner syntax (bash -n)" bash -n "$ROOT/bin/sdd"

# Inside a mutant (SDD_MUTANT=1) only the BEHAVIOURAL sensors run. The linter stays out because a
# mutant caught by the linter proves nothing about the gates — the assertion the mutation wants is
# "the gate noticed", not "the linter complained".
if [ -z "${SDD_MUTANT:-}" ]; then
  if command -v shellcheck >/dev/null 2>&1; then
    run "runner lint" shellcheck -S warning "$ROOT/bin/sdd"
  else
    printf '\n  (linter absent — skipped)\n'
  fi
fi

# check-lang reads paths (docs/, README.md, agents/) that the mutation sandbox does not copy —
# inside a mutant it would fail for a missing file, not for language, and the mutant would score a
# point for the wrong reason. Same guard as the linter, for the same reason.
[ -n "${SDD_MUTANT:-}" ] || run "language: no Portuguese prose on the kit surface" \
  "$ROOT/tests/check-lang.sh"

run "template contract" "$ROOT/tests/check-templates.sh"
run "gate state machine" "$ROOT/tests/check-gates.sh"
run "dry-run projection" "$ROOT/tests/check-dry-run.sh"

# Sensor of the sensor. Outside the guard this would be infinite recursion: every mutant runs this
# same suite. check-mutation.sh has the twin guard and dies if it is born with SDD_MUTANT set.
[ -n "${SDD_MUTANT:-}" ] || run "mutation: the suite dies when the runner is sabotaged" \
  "$ROOT/tests/check-mutation.sh"

printf '\n'
if [ "$fails" -eq 0 ]; then printf '\033[32m\033[1msuite green\033[0m\n'; exit 0; fi
printf '\033[31m\033[1m%d suite(s) failed\033[0m\n' "$fails" >&2
exit 1
