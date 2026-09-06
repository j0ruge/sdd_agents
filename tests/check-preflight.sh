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

# assert_eq <description> <expected> <got>. The two above answer one yes/no about one needle; the
# blocks that have to say "this arm fired AND the other one did not, AND the command really ran"
# compose their answer into a string and compare it whole, so a red names which term went wrong
# instead of only that something did.
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi
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

# --- the context bill: a SENSOR, and never a refusal ------------------------
# The target's CLAUDE.md plus its .claude/rules/ is ~73% of the fixed prefix every turn of every
# phase carries (measured 2026-09-03, two repos). The kit does not cut anybody's rulebook, so this
# line only has to make the number visible — and the second assertion is the one that matters,
# because a preflight that started REFUSING a repo for having many rules would be the kit deciding
# how a target documents itself.
#
# The fixture repo has no CLAUDE.md and no .claude/rules/, so `0 file(s), 0 bytes` is the honest
# answer AND the world where the guard is load-bearing: `find`/glob on an absent directory exits
# non-zero, and under `set -o pipefail` an unguarded capture would take the whole preflight down on
# exactly the repo shape most targets have.
assert_has "the context bill is reported" "context bill: 0 file(s), 0 bytes" "$out"
assert_has "and it is an ok line, never a refusal" "ok   context bill" "$out"
{ printf '# rules\n'; head -c 1234 /dev/zero | tr '\0' 'r'; } > "$FIX/CLAUDE.md"
mkdir -p "$FIX/.claude/rules" && printf '# r\n' > "$FIX/.claude/rules/one.md"
out_cb="$( "$SDD" preflight 2>&1 )"
# Differential: the count and the bytes both have to move, and the rules file has to be found under
# a directory the first world did not have. Counting only files would pass on a bill that reports
# a constant; counting only bytes would pass on one that never looks inside .claude/rules/.
# The expected byte count is COMPUTED from the two files just written, never typed: a literal here
# is a number that goes stale the first time the fixture changes by a byte, and a stale expectation
# in a passing test is worse than no test.
cb_want=$(( $(wc -c < "$FIX/CLAUDE.md") + $(wc -c < "$FIX/.claude/rules/one.md") ))
assert_has "the bill counts CLAUDE.md and the rules directory, in files and in bytes" \
  "context bill: 2 file(s), $cb_want bytes" "$out_cb"
rm -rf "$FIX/CLAUDE.md" "$FIX/.claude/rules"

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

# --- and then it RUNS the thing --------------------------------------------
# The block above is a STRING heuristic: it knows `true`, `:`, `echo`, `printf`, `exit` and three
# spellings of "list the tests without running them", and certifies everything else. A target repo
# whose `npm test` dies on a dependency that was never installed passes it green — and then
# gate_EXEC (which runs the same command for real) refuses for ever, at one EXEC session per lap,
# because a session cannot install what the gate never told anybody about. The whole point of a
# preflight is to move that discovery to before the first token.
#
# Asserted by WITNESS and not by the message: a preflight that printed "ran green" without running
# anything is exactly the label-over-artifact this repo forbids, and no wording check can see it.
# The probes live outside the fixture repo so running them cannot dirty the tree being measured.
echo "== the preflight RUNS the TEST_CMD =="
PROBE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-probe-XXXXXX")"
trap 'rm -rf "$FIX" "$PROBE"' EXIT
printf '#!/usr/bin/env bash\nprintf "ran\\n" >> "%s/witness"\nexit 0\n' "$PROBE" > "$PROBE/suite-green.sh"
printf '#!/usr/bin/env bash\nprintf "ran\\n" >> "%s/witness"\nexit 3\n' "$PROBE" > "$PROBE/suite-red.sh"
chmod +x "$PROBE/suite-green.sh" "$PROBE/suite-red.sh"

cp .sdd/config.sh .sdd/config.sh.bak
run_case() { # run_case <script> <expected-marker> <forbidden-marker> <description>
  : > "$PROBE/witness"
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$PROBE/$1\"|" .sdd/config.sh
  local o ran; o="$( "$SDD" preflight 2>&1 )"
  ran="$(grep -c . "$PROBE/witness" 2>/dev/null || true)"
  local got="ran=$ran"
  grep -qF "$2" <<< "$o" || got="$got, the expected line is absent"
  grep -qF "$3" <<< "$o" && got="$got, and the OTHER verdict was printed too"
  assert_eq "$4" "ran=1" "$got"
}
run_case suite-green.sh "TEST_CMD ran green" "TEST_CMD FAILED" \
  "a green TEST_CMD is EXECUTED, and only then called green"
run_case suite-red.sh   "TEST_CMD FAILED"    "TEST_CMD ran green" \
  "a TEST_CMD that exits non-zero is refused by its exit status, not by its spelling"

# The no-op arm: a command the heuristic already refused must NOT be executed. Running whatever
# someone typed into a key the preflight had already decided was wrong is a preflight doing damage
# on config it just rejected.
#
# The value is the probe script WITH `--list`, and both halves of it are load-bearing. `--list` is
# what trips `test_cmd_looks_noop`, so the refusal arm is the one that fires; the SCRIPT is what
# appends to the witness, so an execution that should not have happened leaves a mark. This block
# used to carry `TEST_CMD="true"`, and that value could not do the second half: `true` is a builtin
# that touches nothing, so `ran=0` held in the blinded world exactly as in the correct one. The
# term read like a witness and was a constant — the sensor claiming to measure what it did not.
#
# Each half now has a mutant of its own, which is the only reason either can be believed:
# `mut_PRE_testcmd_noop_blind` blinds the heuristic and is caught by the MESSAGE, while
# `mut_PRE_testcmd_noop_runs_anyway` keeps the message and executes anyway — caught by `ran` and
# by nothing else in this suite.
: > "$PROBE/witness"
sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$PROBE/suite-green.sh --list\"|" .sdd/config.sh
noop_out="$( "$SDD" preflight 2>&1 )"
noop_ran="$(grep -c . "$PROBE/witness" 2>/dev/null || true)"
assert_eq "a TEST_CMD the heuristic already refused is not executed at all" \
  "runs nothing, ran=0" \
  "$(grep -qF 'runs nothing' <<< "$noop_out" && printf 'runs nothing' || printf 'not refused'), ran=$noop_ran"
mv .sdd/config.sh.bak .sdd/config.sh

# --- DEFAULT_BRANCH names a branch that EXISTS ------------------------------
# `load_config` demands only that the key be non-empty, and `warn_if_on_base_branch` only compares
# it with the current branch name — nothing ever asked the repository whether the branch is there.
# The failure surfaces in `gh pr create --base` in the PR phase: the LAST one, after EXEC, QA,
# REVIEW and DOCS have all been paid for. The pilot declares `DEFAULT_BRANCH="develop"` and the
# value has already been got wrong once.
#
# Three arms and three distinct markers, so no arm can be satisfied by another's text: on origin is
# what `gh pr create` actually opens against, local-only is a warning (the branch exists, the PR
# still cannot be opened there), absent is a refusal.
echo "== DEFAULT_BRANCH is verified against the repository =="
ORIGIN="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-origin-XXXXXX")"
trap 'rm -rf "$FIX" "$PROBE" "$ORIGIN"' EXIT
git init -q --bare -b main "$ORIGIN"
git remote add origin "$ORIGIN"
git push -q origin main
git branch only-local

cp .sdd/config.sh .sdd/config.sh.bak
branch_case() { # branch_case <value> <expected-marker> <forbidden-marker> <description>
  sed -i "s|^DEFAULT_BRANCH=.*|DEFAULT_BRANCH=\"$1\"|" .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  local got="ok"
  grep -qF "$2" <<< "$o" || got="the expected line is absent"
  grep -qF "$3" <<< "$o" && got="$got + the OTHER verdict was printed too"
  assert_eq "$4" "ok" "$got"
}
branch_case main       "DEFAULT_BRANCH=main exists on origin" \
                       "is not a branch of this repository" \
                       "a DEFAULT_BRANCH that exists on origin is accepted"
branch_case only-local "exists locally but not on origin" \
                       "is not a branch of this repository" \
                       "a DEFAULT_BRANCH that exists only locally warns — the PR opens against the REMOTE"
branch_case develop    "is not a branch of this repository" \
                       "exists on origin" \
                       "a DEFAULT_BRANCH that names no branch at all is refused, and the key is named"
mv .sdd/config.sh.bak .sdd/config.sh

# --- third-party skills the phases depend on --------------------------------
# Three phases are driven by skills the kit does not ship: TICKET boots `ticket`, the two QA
# sub-steps boot `qa-report` and `qa-execution`, and REVIEW loads `codereview`. A missing one is
# not a broken kit — it is a session that boots, finds no skill, improvises, and burns the phase
# budget answering something nobody can gate.
#
# WARN and never fail: the search roots are a CONVENTION (`~/.claude/skills/`, the plugin cache,
# the project's own `.claude/skills/`), not a contract the kit can enforce, and a rule that fails on
# a heuristic is the rule the next author deletes. Same call the ddd/kaizen plugin check already
# makes, one screen up in the same command.
#
# The root is injectable so this is testable at all: with SDD_SKILLS_ROOT pointing at an empty
# directory every skill is missing, and pointing at one that holds them, none is.
echo "== third-party skills =="
cd "$FIX" || exit 1
EMPTY_SKILLS="$FIX/.skills-empty"
FULL_SKILLS="$FIX/.skills-full"
mkdir -p "$EMPTY_SKILLS" "$FULL_SKILLS/skills/ticket" "$FULL_SKILLS/skills/qa-report" \
         "$FULL_SKILLS/skills/qa-execution" "$FULL_SKILLS/skills/codereview"
for s in ticket qa-report qa-execution codereview; do
  printf -- '---\nname: %s\n---\n' "$s" > "$FULL_SKILLS/skills/$s/SKILL.md"
done

# JIRA on and an interface declared, so all four skills are in play.
cp .sdd/config.sh .sdd/config.sh.bak
sed -i 's|^JIRA_ENABLED=false|JIRA_ENABLED=true|; s|^E2E_CMD=""|E2E_CMD="npm run e2e"|' .sdd/config.sh
printf 'PROJECT=FX\nBOARD=1\n' > .jira-project

out_noskills="$( SDD_SKILLS_ROOT="$EMPTY_SKILLS" "$SDD" preflight 2>&1 )"
assert_has "preflight warns about a ticket skill it cannot find" "ticket" "$out_noskills"
assert_has "the warning names where it looked" "$EMPTY_SKILLS" "$out_noskills"
assert_has "the warning says what the absence costs" "boots the skill" "$out_noskills"

# The differential, one root apart: the SAME config with the skills present says nothing. Without
# it, a preflight that printed the warning unconditionally would satisfy every assertion above.
out_skills="$( SDD_SKILLS_ROOT="$FULL_SKILLS" "$SDD" preflight 2>&1 )"
assert_lacks "with the skills installed the warning is silent" "boots the skill" "$out_skills"

# And the trigger is the CONFIG, not the calendar: with JIRA off, `ticket` is not asked for.
sed -i 's|^JIRA_ENABLED=true|JIRA_ENABLED=false|; s|^E2E_CMD="npm run e2e"|E2E_CMD=""|' .sdd/config.sh
out_nojira="$( SDD_SKILLS_ROOT="$EMPTY_SKILLS" "$SDD" preflight 2>&1 )"
assert_lacks "with JIRA off the ticket skill is not asked for" "ticket" "$out_nojira"
assert_lacks "with no interface the qa skills are not asked for" "qa-report" "$out_nojira"
# codereview is asked for in every project: REVIEW runs in every mission.
assert_has "codereview is asked for whatever the config says" "codereview" "$out_nojira"

rm -f .jira-project
mv .sdd/config.sh.bak .sdd/config.sh

# --- is anything listening where APP_URL points? ----------------------------
# preflight ran fifteen checks and never once touched APP_URL, so the one thing that costs a whole
# opus session to discover — the app is not up — was the one thing it could not say. Measured on
# the SQ-111 mission of 2026-08-27: US$ 14,16 for a QA phase reproved by the environment.
#
# FLOOR FIRST, and NOT written with the runner's own app_probe: a floor that reuses the function
# under test measures the runner with the runner.
echo "== is anything listening where APP_URL points =="
cd "$FIX" || exit 1
port_is_free() {  # rc 0 = nothing is listening on 127.0.0.1:$1
  local rc=0
  LC_ALL=C timeout 3 bash -c 'exec 3<>"/dev/tcp/127.0.0.1/$0"' "$1" 2>/dev/null || rc=$?
  [ "$rc" -ne 0 ]
}
# BELOW the ephemeral range, and that is what makes the floor hold for the whole block. The floor
# proves the port refuses ONCE; the assertions under it then run several `sdd` invocations over
# minutes against that one measurement. Drawn from 49152-59171 the port sat INSIDE the kernel's
# `ip_local_port_range` (32768-60999 by default), so it could be handed out mid-block and the
# assertions would flip for a reason that has nothing to do with the runner. 20000-29999 is under
# that floor. DECLARED LIMIT: a machine that lowered `ip_local_port_range` past 20000, or that
# starts a real listener there mid-block, is back in the old window — the search loop below only
# re-measures at the start, and re-measuring per assertion would buy a smaller window at the price
# of a floor nobody can read.
dead_port=$(( 20000 + $$ % 10000 ))
app_floor_ok=1
if ! command -v timeout >/dev/null 2>&1; then
  fail "dead-app floor" "timeout(1) on PATH" "timeout is missing — the APP_URL block was NOT measured"
  app_floor_ok=0
else
  tries=0
  while ! port_is_free "$dead_port"; do
    dead_port=$(( dead_port + 1 )); tries=$(( tries + 1 ))
    if [ "$tries" -ge 20 ]; then
      fail "dead-app floor" "a refused port on 127.0.0.1" \
           "20 consecutive ports were all listening — the block would certify nothing"
      app_floor_ok=0; break
    fi
  done
fi

if [ "$app_floor_ok" = "1" ]; then
  pass "dead-app floor: 127.0.0.1:$dead_port refuses connections"
  cp .sdd/config.sh .sdd/config.sh.bak
  DEAD="http://127.0.0.1:$dead_port/"

  # ⭐ THE PAIR, and APP_URL is held CONSTANT across it while E2E_CMD moves — the opposite of the
  # pair in check-autonomy.sh, and for a reason. Every other APP_URL-sensitive check in preflight
  # (the browser, the qa skills) keys on `E2E_CMD OR APP_URL`, so with APP_URL non-empty on both
  # sides they fire identically and the ONLY thing that can move the failed count is the new
  # check. Varying APP_URL instead would flip the browser check with it, and the +1 could not be
  # attributed.
  #
  # And the direction is the whole policy: a dead app is a FAILURE only when E2E_CMD is
  # configured, because that is the case where a gate is about to run a suite against an app that
  # is not there. Without E2E_CMD nothing automatic runs against it, so the same fact is a warning
  # for the human who is about to walk the journey — never a refusal to start the mission.
  sed -i "s|^E2E_CMD=.*|E2E_CMD=\"npm run e2e\"|" .sdd/config.sh
  printf 'APP_URL="%s"\n' "$DEAD" >> .sdd/config.sh
  out_dead_e2e="$( "$SDD" preflight 2>&1 )"

  sed -i 's|^E2E_CMD=.*|E2E_CMD=""|' .sdd/config.sh
  out_dead_alone="$( "$SDD" preflight 2>&1 )"

  n_e2e="$(failed_count "$out_dead_e2e")"
  n_alone="$(failed_count "$out_dead_alone")"
  assert_eq "a dead app with E2E_CMD set is one MORE failed check than the same dead app without it" \
    "one more" \
    "$( [ -n "$n_e2e" ] && [ -n "$n_alone" ] && [ "$n_e2e" -eq $(( n_alone + 1 )) ] \
        && echo "one more" || echo "$n_alone -> $n_e2e" )"

  assert_has "and it names the address, so the human knows what to start" \
    "127.0.0.1:$dead_port" "$out_dead_e2e"
  assert_has "the refusal says WHY a dead app is fatal here, not just that it is dead" \
    "E2E_CMD" "$out_dead_e2e"
  # The other half of the pair, and the one that keeps the fix from being wider than the defect:
  # with no E2E_CMD the same dead app is still REPORTED, and still not a refusal.
  assert_has "without E2E_CMD the dead app is still reported" \
    "127.0.0.1:$dead_port" "$out_dead_alone"

  # An APP_URL this cannot read is NOT a dead app, and saying so is the one-sided contract of the
  # probe carried through to the human: `unknown` never becomes a refusal, whatever E2E_CMD says.
  sed -i "s|^E2E_CMD=.*|E2E_CMD=\"npm run e2e\"|" .sdd/config.sh
  sed -i 's|^APP_URL=.*|APP_URL="not a url"|' .sdd/config.sh
  out_unknown="$( "$SDD" preflight 2>&1 )"
  n_unknown="$(failed_count "$out_unknown")"
  assert_eq "an APP_URL that cannot be read is a warning, never a refusal — even with E2E_CMD set" \
    "no extra failure" \
    "$( [ -n "$n_unknown" ] && [ -n "$n_alone" ] && [ "$n_unknown" -eq "$n_alone" ] \
        && echo "no extra failure" || echo "$n_alone -> $n_unknown" )"
  assert_has "and it says why it could not tell, instead of claiming the app is down" \
    "not probed" "$out_unknown"
  assert_lacks "an unreadable APP_URL never claims a dead app" \
    "nothing is listening" "$out_unknown"

  # Empty APP_URL: nothing to probe, and nothing said about listening either way. This is the
  # regime EVERY repo without an interface is in, so a line here that fired would fire everywhere.
  sed -i 's|^APP_URL=.*|APP_URL=""|' .sdd/config.sh
  out_noapp="$( "$SDD" preflight 2>&1 )"
  assert_lacks "an empty APP_URL claims nothing about listening" "nothing is listening" "$out_noapp"
  assert_lacks "an empty APP_URL is not reported as unprobed either" "not probed" "$out_noapp"

  mv .sdd/config.sh.bak .sdd/config.sh
fi

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
