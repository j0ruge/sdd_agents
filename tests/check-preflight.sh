#!/usr/bin/env bash
# Sensor for the GNU userland probe of `sdd preflight`.
#
# The runner calls three tools by their GNU names and flags: `md5sum` (state_fingerprint),
# `date -Iseconds` (the journal) and `sort -V` (the plugin version). macOS ships none of the
# three — it has `md5`, and its BSD `date`/`sort` reject those options — and the bash-4 check at
# the top of bin/sdd can only speak for bash. So the rest of the assumption is measured in
# preflight, and this file is what proves the measurement still measures.
#
# Presence would not be enough, which is why the probe is behavioural: brew installs GNU
# coreutils as gmd5sum/gdate unless the gnubin dir comes first in PATH, so `command -v date`
# passes on a machine where `date -Iseconds` fails. The shims below answer the way the BSD tools
# answer, so the test exercises the same distinction.
#
# No token and no network: `claude` and `gh` are stubbed to fail, and preflight is EXPECTED to
# fail overall in both runs. The only thing asserted is the GNU line — quiet when the userland is
# GNU, and naming all three when it is not.
#
# Usage: tests/check-preflight.sh   (exit 0 = the probe still fires, and still stays quiet)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-XXXXXX")"
fails=0
trap 'rm -rf "$FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# assert_has <description> <needle> <haystack>
assert_has() {
  if grep -qF -- "$2" <<< "$3"; then pass "$1"
  else fail "$1" "output containing: $2" "$(printf '%s' "$3" | tr '\n' '|' | head -c 200)"; fi
}

# assert_lacks <description> <needle> <haystack>
assert_lacks() {
  if grep -qF -- "$2" <<< "$3"; then fail "$1" "output WITHOUT: $2" "it was printed"
  else pass "$1"; fi
}

OK_LINE="GNU userland (md5sum, date -Iseconds, sort -V)"
BAD_LINE="the kit assumes the GNU userland, and these do not answer: md5sum 'date -Iseconds' 'sort -V'"

# ---------------------------------------------------------------------------
echo "== fixture at $FIX =="
# `|| exit`: `set -e` is off, and a failing `cd` would run `git init` in the repo of whoever ran
# the test. Same guard, same reason, as check-dry-run.sh.
cd "$FIX" || exit 1

# Absolute paths captured BEFORE the shims go on PATH: a shim that exec'd a bare `date` would
# find itself and recurse until the process table complains.
REAL_DATE="$(command -v date)"
REAL_SORT="$(command -v sort)"

# claude and gh answer failure, instantly and offline. preflight fires a real headless session
# and a real `gh auth status` otherwise — a test that spends tokens or touches the network is not
# a test the suite can run.
mkdir -p "$FIX/.stub"
printf '#!/bin/sh\nexit 1\n' > "$FIX/.stub/claude"
printf '#!/bin/sh\nexit 1\n' > "$FIX/.stub/gh"
chmod +x "$FIX/.stub/claude" "$FIX/.stub/gh"
PATH="$FIX/.stub:$PATH"

# The BSD userland, imitated at the level that matters: the option is rejected, everything else
# still works. `md5sum` is not shimmed to fail — on macOS the name does not exist at all, and 127
# is what the shell returns for that.
mkdir -p "$FIX/.bsd"
printf '#!/bin/sh\nexit 127\n' > "$FIX/.bsd/md5sum"
printf '#!/bin/sh\ncase "$1" in -I*) echo "date: illegal option -- I" >&2; exit 1;; esac\nexec %s "$@"\n' \
  "$REAL_DATE" > "$FIX/.bsd/date"
printf '#!/bin/sh\nfor a in "$@"; do case "$a" in -V) echo "sort: illegal option -- V" >&2; exit 2;; esac; done\nexec %s "$@"\n' \
  "$REAL_SORT" > "$FIX/.bsd/sort"
chmod +x "$FIX/.bsd/md5sum" "$FIX/.bsd/date" "$FIX/.bsd/sort"

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

# --- the userland is GNU: the probe stays quiet -----------------------------
echo "== GNU userland =="
out="$( "$SDD" preflight 2>&1 )"

# Sanity first. Without it, a preflight that died before reaching the probe (a broken fixture, a
# renamed config key) would satisfy every "lacks" assertion below and the test would pass green
# while measuring nothing.
assert_has "preflight got as far as the tool checks" "git present" "$out"
assert_has "GNU userland reported ok" "$OK_LINE" "$out"
assert_lacks "no GNU complaint on a GNU machine" "the kit assumes the GNU userland" "$out"

# --- the userland is BSD: the probe names all three -------------------------
echo "== BSD userland (shimmed) =="
out="$( PATH="$FIX/.bsd:$PATH" "$SDD" preflight 2>&1 )"

assert_has "preflight got as far as the tool checks" "git present" "$out"
assert_has "the three GNU tools are named, in one line" "$BAD_LINE" "$out"
assert_lacks "the ok line is not printed at the same time" "$OK_LINE" "$out"
# The consequence is part of the message on purpose: "md5sum missing" reads like a cosmetic
# nuisance, and what actually happens is that state_fingerprint goes empty and the runner stops
# being able to tell a session that moved the disk from one that did not.
assert_has "the failure says what breaks, not only what is missing" \
  "the state fingerprint is empty" "$out"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then printf '  ok    preflight measures the GNU userland instead of assuming it\n'; exit 0; fi
printf '%d preflight check(s) failed\n' "$fails" >&2
exit 1
