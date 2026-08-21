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
# SECOND responsibility, and it lives here because the fixture already runs `sdd install`: the
# guard that stops the installer from leaving a 0-byte `.sdd/config.sh` behind when the kit copy
# has no `config/starter.conf`. Same family as the GNU probe above — the runner asserting a world
# it did not measure.
#
# THIRD, same family again and the sharpest of the three: preflight used to ask `[ -f <copy> ]` and
# then print "N kit agent(s) checked" — a label over a comparison that never happened. The harness
# loads the COPY in .claude/agents/, so the source can be fixed and the agent keeps running the old
# text; it happened (2132cf5 edited agents/sdd-kaizen.md, the copy stayed behind, green in
# everything). Asserted differentially, for a reason spelled out at the section itself.
#
# Usage: tests/check-preflight.sh   (exit 0 = the probe still fires, and still stays quiet)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# This install is fixture setup for preflight AND the POSITIVE control of the starter.conf guard
# asserted at the bottom of this file. Without it a guard that died unconditionally would satisfy
# every assertion down there, and the installer would be broken in the opposite direction.
echo "== sdd install with the real kit (positive control) =="
install_out="$( "$SDD" install 2>&1 )"
assert_has "install reports the config created" ".sdd/config.sh created" "$install_out"
# Asserted BEFORE the heredoc below overwrites it: what the defect produced was a file that
# existed and was empty, so existence alone is exactly the check that could not see it.
if [ -s ".sdd/config.sh" ]; then pass "the created config is not empty"
else fail "the created config is not empty" "a non-zero .sdd/config.sh" \
       "$(wc -c < .sdd/config.sh 2>/dev/null || echo 'no file') byte(s)"; fi

cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="npm test"
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

# --- an agent copy that drifted from the kit source -------------------------
# DIFFERENTIAL on purpose, and it has to be. The obvious assertion — "the `N kit agent(s) checked`
# line is absent" — is VACUOUS in this fixture: that line only prints under `fails -eq 0`, and here
# claude and gh are stubbed to fail, so it never prints in ANY run, defect fully in place included.
# What discriminates is the two runs compared against EACH OTHER: same fixture, one byte of
# difference, exactly one more failed check. No fixture regime satisfies that by accident.
echo "== an agent copy drifted from the kit source =="

AGENT=".claude/agents/sdd-executor.md"

# failed_count <preflight output> — the N from the closing "N check(s) failed" (stderr, captured).
# Prints nothing when the line is absent, which is itself a red: `-ne` on an empty string errors.
failed_count() {
  local line; line="$(grep -oE '[0-9]+ check\(s\) failed' <<< "$1")"
  printf '%s' "${line%% *}"
}

# Adversarial pass, like the starter.conf block below: each assertion here was broken on its own by
# a distinct sabotage of the agent block, and each names the one it owns exclusively. The two
# sanity guards are the exception and are marked as such — same rubric as "preflight got as far as
# the tool checks" in the GNU section, which is also non-exclusive on purpose.
#
# SANITY, not exclusive: it names the cause when the kit copy has no agents/ to install from (the
# mutation sandbox forgot to copy it), instead of leaving five assertions red with no explanation.
if [ -f "$AGENT" ]; then pass "the fixture installed the kit agents"
else fail "the fixture installed the kit agents" "$AGENT on disk" "no such file"; fi

out="$( "$SDD" preflight 2>&1 )"
# SANITY, not exclusive: `current branch:` prints AFTER the agent block, so a preflight that died
# before reaching the agents cannot produce it. Without it the three "lacks" here would all be
# satisfied by a fixture that never got that far.
assert_has "preflight got past the agent block" "current branch:" "$out"
# Positive control. Owns the sabotage that says "stale" about copies that MATCH — an `else warn`
# arm, which changes no rc and no failure count, so nothing else in this file sees it.
assert_lacks "no stale complaint when every copy matches the source" "stale" "$out"
n_intact="$(failed_count "$out")"

printf '\n<!-- drift: one byte the source does not have -->\n' >> "$AGENT"
out="$( "$SDD" preflight 2>&1 )"
n_drift="$(failed_count "$out")"

# The literal text the checkpoint's Check greps. Owns the original defect AND the sabotage that
# keeps failing but drops the word: `_fail "agent $name differs — ..."` is caught here and nowhere
# else in this file.
assert_has "a drifted agent copy fails the preflight" "agent sdd-executor.md stale" "$out"
# Two different repairs deserve two different words — "not installed" sends the operator to install
# a file that is right there on disk. Owns the sabotage that keeps the stale branch but reuses the
# missing branch's wording inside it; rc, count and the "stale" needle all survive that one.
assert_lacks "a drifted copy is not reported as missing" "sdd-executor.md not installed" "$out"
# THE differential half, and the only one that survives a `warn` that does not count: the text can
# be perfect while the check silently passes. Compares the two readings of one fixture.
if [ -n "$n_intact" ] && [ -n "$n_drift" ] && [ "$n_drift" -eq $((n_intact + 1)) ]; then
  pass "the drift adds exactly one failed check, no more and no less"
else
  fail "the drift adds exactly one failed check, no more and no less" \
       "$((${n_intact:-0} + 1)) failed check(s)" "intact '$n_intact' → drifted '$n_drift'"
fi

# --- an agent copy that is absent: a different failure, in different words ---
# The branch that already worked, kept as the negative control of the one above: without it, a
# `cmp -s` that swallowed the missing case (cmp on a nonexistent file is also a mismatch, so one
# careless merge of the two arms does exactly that) would report every absent agent as "stale" and
# no assertion above would notice.
rm -f "$AGENT"
out="$( "$SDD" preflight 2>&1 )"
n_gone="$(failed_count "$out")"

# Owns the sabotage that reworded this branch ("agent X absent"): the operator loses the string
# every doc and every past handoff uses.
assert_has "a missing agent copy still says 'not installed'" \
  "agent sdd-executor.md not installed" "$out"
# Owns the mirror of the drift "lacks": the missing message growing a "stale or removed" clause.
assert_lacks "absent and stale do not collapse into one message" "sdd-executor.md stale" "$out"
if [ -n "$n_intact" ] && [ -n "$n_gone" ] && [ "$n_gone" -eq $((n_intact + 1)) ]; then
  pass "the missing copy adds exactly one failed check"
else
  fail "the missing copy adds exactly one failed check" \
       "$((${n_intact:-0} + 1)) failed check(s)" "intact '$n_intact' → missing '$n_gone'"
fi

# --- the base branch warning, at the door it was born in --------------------
# The warning is one function now, shared with `sdd run` and `sdd kaizen`, and preflight is the
# call site it started in — so it is also the one nobody would think to re-test after the
# extraction. Measured while writing this: deleting the call HERE left check-gates.sh and
# check-kaizen.sh both green, because each of those files only exercises its own door.
#
# DIFFERENTIAL, like its two twins: the fixture was born on `main`, so from a single reading
# "warns on the base branch" and "always warns" are the same output.
echo "== base branch warning =="
out="$( "$SDD" preflight 2>&1 )"
assert_has "the base branch warning survives in the preflight it was extracted from" \
  "you are on the base branch (main)" "$out"

git checkout -q -b missao/base-branch-fixture
out="$( "$SDD" preflight 2>&1 )"
git checkout -q main
git branch -q -D missao/base-branch-fixture
assert_lacks "and it is silent off the base branch" "you are on the base branch" "$out"
# `current branch:` is the witness that the second reading really reached the git block: without
# it, a preflight that died earlier would satisfy the `lacks` above by never getting there —
# absence proved by absence, which is the vacuity this whole mission is about.
assert_has "and the second reading really reached the git block" \
  "current branch: missao/base-branch-fixture" "$out"

# --- `sdd install` against a kit copy with no config/starter.conf -----------
# The redirect creates $CONFIG_FILE BEFORE sed runs, so the missing starter used to leave a 0-byte
# `.sdd/config.sh` on disk and `set -e` took the install down only afterwards. rc was ALREADY
# non-zero (sed's), so rc measures nothing on its own here — the two branches share it. What the
# assertions below separate is the branch's own text and, above all, the artifact: the poisoned
# empty config is what made the NEXT `sdd install` print "already exists (preserved)" over it.
echo "== sdd install without config/starter.conf =="

KIT="$FIX/.kit-no-starter"
mkdir -p "$KIT/bin"
# A real copy, never a symlink: _resolve_self follows symlinks, so a symlinked bin/sdd would
# resolve SDD_HOME back to the real kit — which HAS the starter, and the fixture would measure
# nothing. Nothing else is copied on purpose: `config/` absent IS the fixture.
cp "$SDD" "$KIT/bin/sdd"

mkdir -p "$FIX/target"
( cd "$FIX/target" \
  && git init -q -b main \
  && git config user.email "fixture@example.com" \
  && git config user.name "Fixture" \
  && echo content > file.txt \
  && git add -A && git commit -qm "init" ) >/dev/null 2>&1

out="$( cd "$FIX/target" && "$KIT/bin/sdd" install 2>&1 )"; rc=$?

# Adversarial pass, so none of the five below gets deleted later as decorative — each was broken
# on its own by a distinct sabotage of the guard, and each names its owner here.
#
# This one reads an rc that BOTH branches share, so it is blind to the original defect (it passed
# green before the guard existed). It is not redundant: it is the only half that sees the guard
# degrading from `die` to a warning that carries on.
if [ "$rc" -ne 0 ]; then pass "install fails when the kit has no starter.conf"
else fail "install fails when the kit has no starter.conf" "rc != 0" "rc $rc"; fi

# The consequence, not only the absence — same rubric as the GNU line above. Owns the sabotage
# that keeps the guard but drops the "so what" from the message.
assert_has "the guard says what breaks, not only what is missing" \
  "would be created empty" "$out"
# Also blind to the original defect on its own — sed's stderr quotes the same path. Kept because
# it owns the sabotage that keeps the consequence but stops naming the file the operator must fix.
assert_has "the guard names the file the kit copy is missing" "config/starter.conf" "$out"
# THE discriminating half. Both branches exit non-zero and both mention the path, so an assertion
# that stopped here would pass on the defect. sed only speaks if it ran, and it only runs if the
# guard did not fire — its prefix is the marker of the WRONG branch, and it is locale-proof
# (GNU sed prefixes with the program name in every language, and the message body does not).
assert_lacks "the guard fires before sed does" "sed:" "$out"
# The artifact half: the label was never the damage, the 0-byte file was.
if [ ! -e "$FIX/target/.sdd/config.sh" ]; then pass "no empty config is left behind"
else fail "no empty config is left behind" "no .sdd/config.sh at all" \
       "$(wc -c < "$FIX/target/.sdd/config.sh") byte(s) on disk"; fi

# --- a TEST_CMD that runs nothing -------------------------------------------
# `TEST_CMD` is the EXEC gate and half the REVIEW gate, and the preflight only ever refused it
# EMPTY or literally `TODO`. A value that exits 0 having executed nothing is worse than empty: it
# passes every gate, in every mission, for ever, and each phase certifies itself against a run that
# never happened — a label reached through the one key the whole pipeline trusts. `sdd health`
# already refused one spelling of this (`--list`) but only for the KIT's own suite; every target
# repo was on its own.
#
# The forms below are the ones people actually write: the placeholder left behind after wiring the
# config up, and the "list the tests without running them" flag of three ecosystems.
echo "== a TEST_CMD that runs nothing =="
cd "$FIX" || exit 1
cp .sdd/config.sh .sdd/config.sh.bak

noop_case() { # noop_case <TEST_CMD> <description>
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$1\"|" .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  if grep -qF "runs nothing" <<< "$o"; then pass "$2"
  else fail "$2" "a preflight refusing TEST_CMD=$1" "$(grep -m1 'TEST_CMD' <<< "$o" || echo 'no TEST_CMD line at all')"; fi
}

noop_case 'true'                'preflight fails a no-op TEST_CMD'
noop_case ':'                   'preflight fails TEST_CMD=":"'
noop_case 'echo ok'             'preflight fails a TEST_CMD that only echoes'
noop_case 'npm test -- --list'  'preflight fails a TEST_CMD carrying --list'
noop_case 'pytest --collect-only' 'preflight fails a TEST_CMD that only collects'

# The other half, and the half that keeps the rule alive: a rule that fires on correct config is a
# rule the next author deletes. `--listen-port` is the near miss the whole-argument padding exists
# for, and `echo` inside a longer command is not a command that only echoes.
ok_case() { # ok_case <TEST_CMD> <description>
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$1\"|" .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  if grep -qF "runs nothing" <<< "$o"; then
    fail "$2" "no refusal for TEST_CMD=$1" "$(grep -m1 'runs nothing' <<< "$o")"
  else pass "$2"; fi
}

ok_case 'npm test'                       'a real TEST_CMD is not accused'
ok_case 'tests/run-all.sh'               'the kit own suite is not accused'
ok_case './run.sh --listen-port 8080'    'a flag that merely starts with --list is not accused'
ok_case 'make test && echo done'         'an echo that is not the command is not accused'

mv .sdd/config.sh.bak .sdd/config.sh

# --- install seeds the tree the runner cannot work without ------------------
# `sdd install` made `.sdd/` and `.claude/agents/` and stopped. `resolve_mission` dies on the FIRST
# command a new user types — "docs/handoffs/ does not exist in the target repo" — and `TODO_FILE`,
# where principle 5 sends every out-of-scope finding, is not there either. Both are named in the
# config the installer just wrote, so the installer is where they belong.
#
# Read the way check 2b of `sdd health` reads TEST_CMD: the config is SOURCED in a subshell, so the
# value seeded is the one `load_config` will hand the runner after expansion, not a grep of the
# text.
echo "== install seeds HANDOFF_DIR and the findings file =="
SEED="$FIX/seed"
mkdir -p "$SEED"
( cd "$SEED" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && echo content > file.txt && git add -A && git commit -qm "init" ) >/dev/null 2>&1
seed_out="$( cd "$SEED" && "$SDD" install 2>&1 )"

assert_has "install seeds HANDOFF_DIR and the findings file" "docs/handoffs/" "$seed_out"
if [ -d "$SEED/docs/handoffs" ]; then pass "the handoff root exists on disk after install"
else fail "the handoff root exists on disk after install" "a docs/handoffs/ directory" "absent"; fi
if [ -s "$SEED/TODO.md" ]; then pass "the findings file is seeded, and not empty"
else fail "the findings file is seeded, and not empty" "a non-empty TODO.md" \
       "$(wc -c < "$SEED/TODO.md" 2>/dev/null || echo 'no file') byte(s)"; fi

# A second install must not overwrite what the repo already has — the installer is idempotent
# everywhere else, and a TODO.md flattened on the second run would take real findings with it.
printf -- '- [ ] a real finding — `x:1` — it matters — found by `x` in mission `m` (2026-01-01)\n' \
  >> "$SEED/TODO.md"
before_todo="$(md5sum < "$SEED/TODO.md")"
( cd "$SEED" && "$SDD" install >/dev/null 2>&1 )
if [ "$before_todo" = "$(md5sum < "$SEED/TODO.md")" ]; then
  pass "a second install leaves an existing findings file untouched"
else
  fail "a second install leaves an existing findings file untouched" "the same TODO.md" "rewritten"
fi

# --- the autodetect cascade: first match wins -------------------------------
# Four `if`s with no `elif`: every one of them ran, so the LAST match won whatever the repo is. A
# Node repo carrying a `go.mod` for a sidecar tool was installed with `go test ./...` as the suite
# the gates run — the wrong suite, chosen in silence, in the one key the whole pipeline trusts.
echo "== the autodetect cascade =="
MULTI="$FIX/multi"
mkdir -p "$MULTI"
( cd "$MULTI" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && printf '{}\n' > package.json && printf 'module x\n' > go.mod \
  && git add -A && git commit -qm "init" ) >/dev/null 2>&1
( cd "$MULTI" && "$SDD" install >/dev/null 2>&1 )
multi_test_cmd="$( . "$MULTI/.sdd/config.sh" >/dev/null 2>&1; printf '%s' "${TEST_CMD:-}" )" || true
if [ "$multi_test_cmd" = "npm test" ]; then
  pass "with two manifests the first match wins (package.json → npm test)"
else
  fail "with two manifests the first match wins (package.json → npm test)" \
       "npm test" "$multi_test_cmd"
fi

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then printf '  ok    preflight measures the GNU userland instead of assuming it\n'; exit 0; fi
printf '%d preflight check(s) failed\n' "$fails" >&2
exit 1
