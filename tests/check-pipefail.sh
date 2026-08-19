#!/usr/bin/env bash
# Sensor against the shell traps that make a CAPTURED VALUE lie — three rules, one scanned surface.
#
# RULE 1 (`grep -q`), the house's signature bug: a writer piped into an early-exiting `grep -q`
# while `set -o pipefail` is in force.
#
# RULE 2 (`cdpath:`), its sibling: a `cd` into a command substitution with no `CDPATH=''` guard.
#
# RULE 3 (`rule:`), rule 1's other half: a writer piped into `grep -m<N>` with no quiet flag at
# all, which exits early for exactly the same reason. All three defects have the same shape — the
# value the author reads back is not the value the command produced — and all three are invisible
# to `bash -n`, to shellcheck, and to any test run on a machine whose environment happens to be
# clean. Rules 2 and 3 are documented at their own regexes below.
#
# `grep -q` exits on the FIRST match and closes the pipe. The writer upstream then dies of
# SIGPIPE, `pipefail` propagates its 141, and `if writer | grep -q X` reads "X is absent" for the
# very input that CONTAINS X. What makes this the most expensive bug shape in this repo is that it
# is SIZE-DEPENDENT: with a short string the writer finishes before grep exits and the pipeline is
# correct, so the fixture passes, the review passes, and the inversion only appears on real data.
# It is what kept the runner's Jidoka lying for two missions, and it is why check-gates.sh has to
# assert that one on a 20000-row checkpoint.
#
# The fix is always the same and always local: a herestring (`grep -q X <<< "$var"`), which has no
# second process to kill. CLAUDE.md states the rule as prose; this file is what makes it a sensor.
# Prose already lost this argument twice.
#
# What RULE 2 measures, per scanned line: a `cd` whose OPERAND is a command substitution and which
# is not prefixed by an emptied CDPATH. Only that operand shape, and the reason is that it is the
# only one a line scanner can classify honestly — see the CD_RE comment for the two shapes left
# unmeasured on purpose and why neither is a fail-open in this repo.
#
# What RULE 1 measures, per scanned line:
#   1. a pipe into `grep` carrying a `-q` flag in any spelling — `-q`, `-qE`, `-Eq`, `-E -q`,
#      `--quiet`, `--silent` — at ANY position on the command, including after a flag that takes a
#      separate argument (`-m 1 -q`) and after the pattern operand (`grep pat -q`, which getopt's
#      permutation makes identical to `grep -q pat`). The spelling list is grep's own: `grep
#      --help` prints the three names on one line, and a spelling this file does not know is a
#      spelling it certifies as clean
#   2. unless the line is a WHOLE-LINE comment: the rule is documented in a dozen comments across
#      the kit (including this header), and a comment executes nothing
#   3. unless the line carries the waiver marker, which is a RATCHET and not an escape hatch — a
#      marker on a line that does NOT match is a stale waiver and fails just as loudly, the same
#      bidirectional semantics as tests/lang-allowlist.txt and tests/health-baseline.txt
#
# Usage: tests/check-pipefail.sh              (selftest, then scan the surface — what run-all calls)
#        tests/check-pipefail.sh --selftest   (probes only)
#        tests/check-pipefail.sh --check <f>  (one file, no selftest — used BY the selftest to
#                                              exercise the real reporting path without recursing)
#        tests/check-pipefail.sh --scan <dir> (scan one tree, no selftest — likewise, so the
#                                              surface floor and the per-file wiring get probed)
#
# ── Known limits, stated so nobody re-discovers them as surprises ──────────────────────────────
# `grep -m<N>` with no quiet flag WAS the first entry here, declared rather than closed because
# widening the rule forces conversions. It is RULE 3 now, and the one live violation it found
# (tests/check-dry-run.sh) was converted in the same commit — a sensor that lands with unconverted
# violations lands red.
#
# NOT measured: a line carrying BOTH a quiet flag and `-m<N>`, reported by rule 1 alone. Same
# defect, same fix, one message. The declared cost is a line with two greps, where rule 1 answers
# for a `-m` that belongs to the other command — see maxc_violations().
#
# NOT measured either: a quiet flag separated from `grep` by a shell metacharacter, e.g. a pattern
# containing an unquoted-looking `|` (`| grep "a|b" -q`). The boundary set that kills the false
# positives above cannot tell a metacharacter inside a quoted operand from a real one without
# parsing the shell, and this file is a line scanner by design. It errs toward silence there
# rather than toward flagging every neighbouring command's `-q`.
#
# NOT measured either: a pipe into anything BUT a literal `grep` token — `| command grep -q`,
# `| LC_ALL=C grep -q`, `| xargs grep -q`. None exist in the kit today. The rule stays keyed on
# the shape people actually write, because every generalisation tried on the neighbouring sensors
# fired on legitimate lines first.
#
# The waiver is a real hole and worth naming: a genuine bug on a marked line is invisible. What
# bounds it is that the marker is grep-able, self-documenting, and shows up in the summary count,
# so growth is visible in the diff rather than in nobody's memory.
#
# This file EXCLUDES ITSELF from the scan, the same exclusion and the same reason as
# tests/check-lang.sh: the probes below have to contain the thing being detected. Its guard is
# selftest(), which exercises the real --check path and exits 90/91/92 the moment detection stops
# working. That guard is also mandatory rather than nice-to-have, because nothing outside can
# cover this file: tests/check-mutation.sh only sabotages bin/sdd, and run-all.sh skips this
# sensor under SDD_MUTANT (mut_RUN_jidoka_pipefail INJECTS the pattern into the mutant's runner —
# catching it here would steal the point from the behavioural fixture that is supposed to earn it).
#
# An adversarial pass degraded every rule above one at a time and demanded a red selftest for each
# — 26 sabotages on the first draft, 15 more on the PIPE_RE rewrite (each member of the boundary
# set dropped on its own, the middle put back to flags-only, the trailing anchor widened and
# narrowed), 11 more when rule 3 landed (the short form alone, the long form alone, the cluster
# widened to `m[[:alnum:]]*`, the trailing anchor narrowed to whitespace, the leading pipe dropped,
# the middle forced to one-or-more tokens, maxc_violations reading nothing, the rule-1-owns-it skip
# dropped, has_early_exit forgetting rule 3, check_file never reading it, and the `ok rule:` line
# deleted — all eleven died on the probe that names the exact rule), and 11 when rule 2 landed:
# the leading boundary dropped, the flag group dropped,
# the operand widened to any quoted token, strip_cd_guards neutered, the comment exemption
# dropped, cd_violations emptied, the block cut out of check_file, the `cdpath:` line cut out of
# scan_surface, and the poison floor left unarmed. Nine of those eleven died on the probe that
# names the exact rule. Two survived and BOTH are the harness testing itself, already named below.
#
# ⚠️ The first attempt at that pass concluded nothing at all and looked like it had concluded
# everything: the sabotaged copy was run from a bare temp dir, so ROOT resolved outside any tree,
# `$SELF_PATH` did not exist, and all eleven "died" at rc 127 on the FIRST probe — a uniform,
# convincing, meaningless result. A sabotage probe proves it sabotaged what it said before it
# concludes anything: anchor on CODE (a literal, asserted to appear exactly once), run a CONTROL
# on the healthy file first, and refuse to read a run whose anchor did not match.
#
# The three that SURVIVE are worth naming rather than hiding, because all three are the harness
# testing itself and none is reachable in one edit:
#   - neutering fail_rc AND the FAILS cross-check (two independent paths, both must die). vprobe()
#     shares this survivor with probe(), and that is measured rather than assumed: the same edit
#     shape applied to each in turn leaves the selftest green in both cases, so rule 2 added no
#     weakness here that rule 1 did not already have
#   - neutering probe()'s message check AND then changing a message
#   - neutering the probe bodies AND lowering the probe floor to match
# A fourth survivor was not a limit but a duplicate: the waiver predicate had a second copy in the
# counter that no sabotage could break, which is how the kit finds out a rule is redundant. It was
# collapsed into waiver_lines() rather than given a probe.
#
# Exit codes, one per cause:
#   0  clean          1  violations found
#   90/91/92  a selftest probe failed          93  surface floor: the file list shrank
#   94  the file named on --check is missing or unreadable      96  unknown option

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF_PATH="$ROOT/tests/check-pipefail.sh"
SELF_REL='tests/check-pipefail.sh'
WAIVER='sdd-pipefail-waiver'

# The pipe, optional whitespace, `grep`, ANY run of argument tokens, then a quiet flag.
#
# The quiet flag itself is a flag CLUSTER containing `q`, not the exact token `-q`, because grep's
# short flags combine: `-qE`, `-Eq` and even `-qualifier` all pass `-q` to grep, and a rule keyed
# on the token would let the next author reintroduce the bug by adding one letter. `--silent` sits
# beside `--quiet` because grep's own help prints all three names on ONE line — `-q, --quiet,
# --silent` — and the long forms do not combine, so the cluster half cannot reach them. Measured:
# `yes | head -200000 | grep --silent x` returns 141 under pipefail exactly as `-q` does.
#
# ── Why the middle is "any token" and not "any FLAG" ───────────────────────────────────────────
# The first two drafts wrote the middle as `([[:space:]]+-[[:alnum:]-]+)*`, requiring every token
# between `grep` and the quiet flag to start with `-`. That is not how a grep command line looks,
# and it made the sensor FAIL OPEN on two whole families — measured here, each with the real 141
# beside the sensor's `rc=0`:
#
#   * every flag whose argument is SEPARATE — `-m N`, `-A N`, `-B N`, `-C N`, `-e PAT`, `-f FILE`.
#     The bare argument (`N`, `PAT`, `FILE`) does not start with `-`, so the chain broke there and
#     the `-q` two tokens later was never reached. `| grep -m 1 -q x` read as CLEAN.
#   * the GNU PERMUTATION form `| grep pat -q`. getopt_long permutes, so options may follow
#     operands; `grep x -q` is `grep -q x` and returns 141 all the same.
#
# So the middle now accepts any token that is not a shell metacharacter, and the scan simply stops
# where the grep COMMAND stops. `[^[:space:]|;&()<>`#]` is that boundary set, and each member
# earns its place by killing a false positive the loose rule would otherwise invent:
# `| grep bar && baz -q` and `| grep bar; baz -q` (the `-q` belongs to another command),
# `| grep bar | xargs rm -q` (the next stage of the pipeline), and `| grep bar  # prefer -q`
# (a TRAILING comment — is_comment only exempts whole-line ones, so without `#` here every comment
# mentioning the flag would become a phantom violation). `<>()` and the backtick are in the set for
# the same reason: redirect, subshell and command substitution all end the grep command.
#
# The trailing anchor is `([^[:alnum:]-]|$)` rather than `([[:space:]]|$)` because `-q` is very
# often the LAST thing on the command — `if foo | grep -e pat -q; then` puts a `;` right after it,
# and the space-only anchor let that shape through too. The `$` half stays load-bearing: `| grep
# -q` is legal at the end of a `\`-continued line. Excluding alnum is what keeps `--quietish` from
# reading as `--quiet`.
PIPE_RE='\|[[:space:]]*grep([[:space:]]+[^[:space:]|;&()<>`#]+)*[[:space:]]+(-[[:alnum:]]*q[[:alnum:]]*|--quiet|--silent)([^[:alnum:]-]|$)'

# ── RULE 2: `cd` into a command substitution, with no emptied CDPATH ───────────────────────────
#
# bash searches $CDPATH for any `cd` operand that does not begin with `/`, `.` or `..` — and when
# it finds one there it PRINTS the resolved directory on stdout, straight into the enclosing
# command substitution. Two distinct failures from one cause, both silent, both already paid for
# in this repo (the CRITICAL of 20260817-eixo-do-juiz):
#   * the wrong directory. `git rev-parse --git-common-dir` answers `.git` at a checkout root, and
#     with `CDPATH=$HOME` where $HOME is itself a checkout, EVERY repo on the machine collapsed
#     into one ledger identity — writer and readers agreeing on it, nothing excluded, nothing said.
#   * a second LINE in the answer. `CDPATH=.` alone put a newline inside the ledger's `repo` field.
#
# The operand shape measured is a COMMAND SUBSTITUTION (`"$(…)"`, `$(…)`, a backtick), because
# that is the one a line scanner can classify without guessing: its result is not knowable here, it
# is `dirname` of a relative path everywhere in this kit, and `dirname` of a relative path is
# relative. Two shapes are deliberately NOT measured, and neither is a fail-open here:
#   * a literal operand — `cd sub`, `cd tests`. It IS the bug, but no line in the kit writes one,
#     and a rule with no live instance is a rule no sabotage can exercise.
#   * a VARIABLE operand — `cd "$FIX"`. Statically unknowable: `$FIX` is absolute at runtime in
#     every one of the ~150 sites in tests/, so requiring a guard there would be noise with no
#     defect behind it. The one site where a variable really did hold a relative path was
#     `ledger_repo_root`, and this mission removed the `cd` from it rather than guarding it.
#
# The guard is recognised in EXACTLY ONE spelling and nothing else — fail-CLOSED on purpose, so
# the ratchet pushes toward the single spelling the kit writes instead of blessing a new one each
# time somebody invents it. A first draft also accepted `CDPATH="" cd` and `CDPATH= cd`; the
# adversarial pass could not break either without breaking the canonical one too, which is how the
# kit finds out a rule is redundant — removed rather than given a probe. `CDPATH= cd` is also the
# spelling shellcheck flags as SC1007, so refusing it is the direction the linter already points.
# ── RULE 3: a pipe into `grep -m<N>` with no quiet flag at all ─────────────────────────────────
#
# The same race as rule 1, one keystroke away: `-m<N>` makes grep exit after the Nth match, the
# writer upstream dies of SIGPIPE, and `pipefail` propagates its 141. `| grep -m 1 -q x` was
# already measured by rule 1 (a quiet flag is present, just late on the line); `| grep -m 1 x` was
# the gap this file SHIPPED WITH — declared in the header and parked in TODO.md rather than closed,
# because widening rule 1 would have forced conversions that increment had not scoped.
#
# It is a rule of its own rather than a third alternative inside PIPE_RE for two reasons, and both
# are about the report rather than the detection: rule 1's message names `grep -q` and would be
# wrong here, and the existing probes assert that message. Same fix in both cases — a herestring.
#
# The middle and the trailing anchor are PIPE_RE's, verbatim in shape and for the same reasons
# (see the long comment above it — the boundary set, GNU permutation, the separated argument).
# What differs is the flag itself:
#
#   * the short form is a flag CLUSTER ENDING in `m`, optionally followed by the attached count:
#     `-m1`, `-m 1`, `-om1`, `-im 1`. Written the way rule 1 writes its quiet cluster
#     (`-[[:alnum:]]*m[[:alnum:]]*`) it would fire on every dashed word carrying an m — `-mtime`,
#     `-march`, `-mode` — and a sensor that invents violations gets its rule deleted, not fixed.
#     grep's argument to `-m` is a number, so digits are what may follow it.
#   * the long form is exact, and `--max-count` is the ONLY long spelling grep gives this flag —
#     unlike `-q`, which has three names. `--max-count=1` and `--max-count 1` both work because
#     the trailing anchor excludes alnum and `-`, which leaves `=` and whitespace.
MAXC_RE='\|[[:space:]]*grep([[:space:]]+[^[:space:]|;&()<>`#]+)*[[:space:]]+(-[[:alnum:]]*m[0-9]*|--max-count)([^[:alnum:]-]|$)'

CD_RE='(^|[^[:alnum:]_./$-])cd([[:space:]]+-[[:alpha:]]+)*[[:space:]]+"?(\$\(|`)'
CD_GUARD="CDPATH='' cd"
# A token with no `cd` in it: what is left after the guarded ones are blanked is what CD_RE reads.
CD_GUARD_TOKEN='CDPATHWASEMPTIED'

# is_comment <text> — true when the line is nothing but a comment.
is_comment() {
  local t="${1#"${1%%[![:space:]]*}"}"
  case "$t" in '#'*) return 0 ;; *) return 1 ;; esac
}

# violations <file> — prints "<lineno>\t<text>" per real violation. Never fails.
violations() {
  local hit no text
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    no="${hit%%:*}"; text="${hit#*:}"
    case "$text" in *"$WAIVER"*) continue ;; esac
    is_comment "$text" && continue
    printf '%s\t%s\n' "$no" "$text"
  done < <(grep -nE "$PIPE_RE" -- "$1" 2>/dev/null)
}

# maxc_violations <file> — prints "<lineno>\t<text>" per pipe into an early-exiting `grep -m<N>`
# that carries no quiet flag. Never fails.
#
# Lines rule 1 already reports are skipped, and that is the ONE place the two rules are coupled:
# they describe the same defect with the same fix, so a line carrying both flags is named once.
# The declared cost is a line with TWO greps — `| grep -q a | grep -m1 b` — where rule 1 answers
# first and rule 3 stays quiet. A line scanner cannot tell the two commands apart, and this errs
# toward one honest message instead of two, one of which would point at the wrong command.
maxc_violations() {
  local hit no text
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    no="${hit%%:*}"; text="${hit#*:}"
    case "$text" in *"$WAIVER"*) continue ;; esac
    is_comment "$text" && continue
    # Herestring, never a pipe — rule 1 applies to rule 3's implementation too.
    grep -qE "$PIPE_RE" <<< "$text" && continue
    printf '%s\t%s\n' "$no" "$text"
  done < <(grep -nE "$MAXC_RE" -- "$1" 2>/dev/null)
  return 0
}

# has_early_exit <text> — true when the line pipes into a grep that stops reading before its
# writer is done, by EITHER rule. ONE definition, so the waiver classifier cannot learn about a
# rule the scanner already knows (or the other way round): a real rule-3 violation carrying the
# marker would otherwise be reported as a STALE waiver — "nothing to waive" on a line that has
# something to waive, which reads as the opposite of the truth and invites deleting the marker.
has_early_exit() {
  grep -qE "$PIPE_RE" <<< "$1" && return 0
  grep -qE "$MAXC_RE" <<< "$1"
}

# strip_cd_guards <text> — blanks every GUARDED `cd` so only the unguarded ones survive for CD_RE.
# Literal replacement (the pattern is quoted), never a regex: the spellings contain `$`-free but
# quote-heavy text and a regex here would be one more thing to get wrong.
strip_cd_guards() {
  printf '%s' "${1//"$CD_GUARD"/$CD_GUARD_TOKEN}"
}

# cd_violations <file> — prints "<lineno>\t<text>" per unguarded `cd` into a command substitution.
# Never fails. Whole-line comments are exempt for the same reason as in violations(): this header
# documents the shape, and a comment executes nothing.
cd_violations() {
  local hit no text
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    no="${hit%%:*}"; text="${hit#*:}"
    is_comment "$text" && continue
    # Herestring, never a pipe — rule 1 applies to rule 2's implementation too.
    if grep -qE "$CD_RE" <<< "$(strip_cd_guards "$text")"; then
      printf '%s\t%s\n' "$no" "$text"
    fi
  done < <(grep -nE "$CD_RE" -- "$1" 2>/dev/null)
  return 0
}

# waiver_lines <file> — classifies every line carrying the marker and prints
# "<good|stale>\t<lineno>\t<text>". ONE definition of "this line is a waiver", read by both the
# stale-waiver failure and the summary count: two near-copies of the same predicate is the exact
# defect this mission is fixing in the runner's ledger reader, and the first draft of this file
# planted a third — the copy in the counter turned out to be unbreakable by sabotage, which is
# how a duplicate announces itself.
#
# Whole-line comments are not waivers in EITHER reader: prose may name the marker (this header
# does) without claiming one.
waiver_lines() {
  local hit no text
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    no="${hit%%:*}"; text="${hit#*:}"
    is_comment "$text" && continue
    # Herestring, never a pipe — a sensor for this bug must not carry it.
    if has_early_exit "$text"; then printf 'good\t%s\t%s\n' "$no" "$text"
    else printf 'stale\t%s\t%s\n' "$no" "$text"; fi
  done < <(grep -nF -- "$WAIVER" "$1" 2>/dev/null)
}

# waiver_count <file> — how many lines legitimately carry the marker.
waiver_count() {
  grep -c '^good' <<< "$(waiver_lines "$1")"
}

# check_file <file> — the real check on one path. rc 0 clean, 1 dirty, 94 unreadable.
check_file() {
  local f="$1" label="$2" bad found stale cdbad maxbad rc=0
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf '  FAIL  file missing or unreadable: %s\n' "$f" >&2
    return 94
  fi
  cdbad="$(cd_violations "$f")"
  if [ -n "$cdbad" ]; then
    while IFS= read -r bad; do
      printf '  FAIL  %s:%s: `cd` into a command substitution with no CDPATH guard — bash searches\n' \
        "$label" "${bad%%$'\t'*}" >&2
      printf '        $CDPATH and prints what it finds into the capture. Write: CDPATH=%s cd …\n' \
        "''" >&2
      printf '        %s\n' "${bad#*$'\t'}" >&2
    done <<< "$cdbad"
    rc=1
  fi
  found="$(violations "$f")"
  if [ -n "$found" ]; then
    while IFS= read -r bad; do
      printf '  FAIL  %s:%s: pipe into `grep -q` under pipefail — use a herestring\n' \
        "$label" "${bad%%$'\t'*}" >&2
      printf '        %s\n' "${bad#*$'\t'}" >&2
    done <<< "$found"
    rc=1
  fi
  maxbad="$(maxc_violations "$f")"
  if [ -n "$maxbad" ]; then
    while IFS= read -r bad; do
      printf '  FAIL  %s:%s: pipe into an early-exiting `grep -m<N>` under pipefail — same race\n' \
        "$label" "${bad%%$'\t'*}" >&2
      printf '        as `grep -q`, same fix: a herestring\n' >&2
      printf '        %s\n' "${bad#*$'\t'}" >&2
    done <<< "$maxbad"
    rc=1
  fi
  stale="$(grep '^stale' <<< "$(waiver_lines "$f")")"
  if [ -n "$stale" ]; then
    while IFS= read -r bad; do
      bad="${bad#*$'\t'}"
      printf '  FAIL  %s:%s: stale waiver — the marker sits on a line with nothing to waive\n' \
        "$label" "${bad%%$'\t'*}" >&2
      printf '        %s\n' "${bad#*$'\t'}" >&2
    done <<< "$stale"
    rc=1
  fi
  return "$rc"
}

# The scanned surface. bin/sdd plus every suite script, minus this file (see the header).
# Takes the root as an argument rather than reading the global, so the selftest can drive the real
# scan_surface path over a fixture tree — the floor below is a rule like any other and a rule
# without a probe is a wish.
surface() {
  ( cd "$1" && ls -1 bin/sdd tests/*.sh 2>/dev/null ) | grep -vxF -e "$SELF_REL"
}

# --- selftest ----------------------------------------------------------------------------------
#
# Anti-vacuity. A broken regex here would report "surface clean" forever, which is the exact
# failure class this kit refuses to ship. The probes are FILES, never repo state: this has to
# behave identically on a kit where no real file can play the dirty part.
#
# Every probe drives the real `--check` path in a child process and asserts its own message.
# Asserting the rc alone was not enough on the neighbouring sensor: rc 1 is shared by both
# failure causes, so a probe reading only the rc cannot tell a detection from a stale waiver.
PROBES=0
FAILS=0
SELFTEST_RC=0
# FAILS is bumped by the assertions themselves, independently of fail_rc, and cross-checked at the
# end. A single rc setter is a single point of failure: neutering it prints every failure and then
# exits 0.
fail_rc() { [ "$SELFTEST_RC" -eq 0 ] && SELFTEST_RC="$1"; return 0; }

# probe <desc> <want_rc> <want_text|-> <target> [mode]   — mode defaults to --check
probe() {
  local desc="$1" want_rc="$2" want_txt="$3" f="$4" mode="${5---check}" out rc
  PROBES=$((PROBES + 1))
  out="$( "$SELF_PATH" "$mode" "$f" 2>&1 )"; rc=$?
  if [ "$rc" -ne "$want_rc" ]; then
    printf 'SENSOR-BROKEN: %s — wanted rc %s, got %s\n%s\n' "$desc" "$want_rc" "$rc" "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 90; return 0
  fi
  if [ "$want_txt" != '-' ] && ! grep -qF -- "$want_txt" <<< "$out"; then
    printf 'SENSOR-BROKEN: %s — rc was right but the message never said "%s"\n%s\n' \
      "$desc" "$want_txt" "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 91; return 0
  fi
}

# vprobe <desc> <want> <got> — a probe over a measured VALUE rather than over a run of this file.
# Same accounting as probe() (PROBES, FAILS, fail_rc) so the floor and the cross-check below cover
# both kinds. Rule 2's differential cannot go through probe(): what it measures is bash's own
# behaviour under a poisoned environment, not this scanner's verdict about a file.
vprobe() {
  local desc="$1" want="$2" got="$3"
  PROBES=$((PROBES + 1))
  if [ "$got" != "$want" ]; then
    printf 'SENSOR-BROKEN: %s — wanted "%s", got "%s"\n' "$desc" "$want" "$got" >&2
    FAILS=$((FAILS + 1)); fail_rc 90
  fi
}

# cd_poison_probes <box> — the differential rule 2 exists for, and the FLOOR that makes it mean
# something. The floor is not decoration and is deliberately measured FIRST: a CDPATH that is not
# being consulted (a bash built without it, a poison directory that does not hold the name being
# looked up) makes the guarded half pass while measuring nothing. A probe that cannot demonstrate
# the sabotage it claims concludes nothing — this repo has already been bitten by exactly that, and
# the sibling floor in tests/check-autonomy.sh exists for the same reason.
#
# Both `here/sub` and `poison/sub` exist, so the two halves differ only in the guard: bash searches
# $CDPATH BEFORE falling back to the current directory, which is what makes the poison win.
cd_poison_probes() {
  local box="$1" got
  mkdir -p "$box/poison/sub" "$box/here/sub"

  # FLOOR — the poison is armed: an unguarded `cd` into a capture lands in the poison checkout.
  got="$( cd "$box/here" \
          && CDPATH="$box/poison" bash -c 'cd "$(dirname "sub/x")" >/dev/null 2>&1 && pwd -P' )"
  vprobe 'the CDPATH poison is armed: an unguarded cd into a capture lands in the poison tree' \
    "$box/poison/sub" "$got"

  # FLOOR, other half — and it is the SECOND defect, not a restatement of the first: bash echoes
  # the directory it found, so the capture comes back with a line the author never wrote.
  got="$( cd "$box/here" \
          && CDPATH="$box/poison" bash -c 'cd "$(dirname "sub/x")" && pwd -P' | grep -c . )"
  vprobe 'the poison also DOUBLES the capture: cd prints what it found, so the value is 2 lines' \
    2 "$got"

  # The guard, against that armed poison: right directory, and one line.
  got="$( cd "$box/here" \
          && CDPATH="$box/poison" bash -c 'CDPATH='\'''\'' cd "$(dirname "sub/x")" && pwd -P' )"
  vprobe 'CDPATH= on the cd yields the local directory, on ONE line, under the same poison' \
    "$box/here/sub" "$got"
}

selftest() {
  local box t out_r2 out_r3
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-pipefail-selftest-XXXXXX")" || {
    echo 'SENSOR-BROKEN: no temp dir — the probes never ran' >&2; return 92; }
  t="$box/probe.sh"

  # 1-6: the shapes that ARE the bug. Six spellings, because a regex that only knows `-q ` lets
  # the next author reintroduce the bug with `-qE` and stay green. The set is not invented: the
  # short ones are the flag clusters grep accepts, and the two long ones are the other two names
  # grep's own `--help` gives the SAME flag. A probe per spelling is the only thing standing
  # between "the rule covers any spelling" and a claim nobody measured — the first draft of this
  # file made that claim while `--silent` walked straight through.
  cat > "$t" <<'EOF'
if printf '%s\n' "$out" | grep -q 'BLOCKED'; then :; fi
EOF
  probe 'plain -q detected' 1 'pipe into `grep -q`' "$t"

  cat > "$t" <<'EOF'
if printf '%s' "$got" | grep -qE "$re"; then :; fi
EOF
  probe '-qE detected' 1 'pipe into `grep -q`' "$t"

  cat > "$t" <<'EOF'
if cat "$f" | grep -Eq 'x'; then :; fi
EOF
  probe '-Eq detected' 1 'pipe into `grep -q`' "$t"

  cat > "$t" <<'EOF'
if echo "$v" | grep -E -q 'x'; then :; fi
EOF
  probe 'separated -E -q detected' 1 'pipe into `grep -q`' "$t"

  cat > "$t" <<'EOF'
if echo "$v" | grep --quiet 'x'; then :; fi
EOF
  probe '--quiet detected' 1 'pipe into `grep -q`' "$t"

  cat > "$t" <<'EOF'
if echo "$v" | grep --silent 'x'; then :; fi
EOF
  probe '--silent detected (grep spells this flag three ways)' 1 'pipe into `grep -q`' "$t"

  # 7-9: the quiet flag is not always the token right after `grep`, and the two drafts that assumed
  # it was both FAILED OPEN. One probe per family, each measured against the real 141 before being
  # written here — see the PIPE_RE comment for the numbers.
  #
  # 7: a flag whose argument is SEPARATE. `1` does not start with `-`, which is precisely where the
  # old "every token is a flag" middle broke.
  cat > "$t" <<'EOF'
if foo | grep -m 1 -q x; then :; fi
EOF
  probe 'a flag with a separated argument does not hide the -q' 1 'pipe into `grep -q`' "$t"

  # 8: GNU permutation — options may follow operands, so `grep pat -q` IS `grep -q pat`.
  cat > "$t" <<'EOF'
if foo | grep pat -q; then :; fi
EOF
  probe 'the -q after the pattern operand is still the -q' 1 'pipe into `grep -q`' "$t"

  # 9: the flag ends the command. `;` after `-q` is the single most common real shape, and the
  # space-only trailing anchor let it through.
  cat > "$t" <<'EOF'
if foo | grep -e pat -q; then :; fi
EOF
  probe 'a -q ending the command (terminator, not space) is detected' 1 'pipe into `grep -q`' "$t"

  # 10: the line number is reported, not just the fact. A sensor that cannot say WHERE sends the
  # reader to grep the file by hand, and the report becomes a rumour.
  cat > "$t" <<'EOF'
: line one
: line two
if echo "$v" | grep -q 'x'; then :; fi
EOF
  probe 'the violation carries its line number' 1 'probe.sh:3:' "$t"

  # 7-10: the shapes that are NOT the bug. Without these, "flag every line" scores full marks.
  cat > "$t" <<'EOF'
if grep -q 'x' <<< "$v"; then :; fi
EOF
  probe 'the herestring fix is accepted' 0 '-' "$t"

  cat > "$t" <<'EOF'
if grep -q 'x' "$file"; then :; fi
EOF
  probe 'grep -q on a FILE (no pipe) is accepted' 0 '-' "$t"

  cat > "$t" <<'EOF'
n="$(printf '%s\n' "$v" | grep -c 'x')"
m="$(printf '%s\n' "$v" | grep -v 'q' | head -1)"
EOF
  probe 'a pipe into grep WITHOUT -q is accepted' 0 '-' "$t"

  cat > "$t" <<'EOF'
   # never write printf '%s' "$x" | grep -q y here
EOF
  probe 'a whole-line comment documenting the bug is accepted' 0 '-' "$t"

  # The boundary set, one probe per reason it exists. Widening the middle to "any token" is what
  # closed the fail-open; these four are what stop it from flagging every `-q` in the neighbourhood
  # instead. Each was a live false positive of the loose rule before the boundary set was added.
  cat > "$t" <<'EOF'
foo | grep bar && baz -q
foo | grep bar; baz -q
EOF
  probe "a -q on the NEXT command (';' and '&&') is not this grep's" 0 '-' "$t"

  cat > "$t" <<'EOF'
foo | grep bar | xargs rm -q
EOF
  probe 'a -q on the next PIPELINE stage is not this grep either' 0 '-' "$t"

  # is_comment only exempts WHOLE-LINE comments, so without `#` in the boundary set every trailing
  # comment naming the flag would become a phantom violation on a line that is perfectly fine.
  cat > "$t" <<'EOF'
foo | grep bar   # prefer -q here one day
EOF
  probe 'a TRAILING comment naming -q does not invent a violation' 0 '-' "$t"

  # The long forms are exact tokens: `--quiet` does not combine, so `--quietish` is a different
  # flag and not this bug. This is the negative half of the trailing anchor.
  cat > "$t" <<'EOF'
echo x | grep --quietish y
EOF
  probe '--quietish is not --quiet' 0 '-' "$t"

  # 11-12: the waiver, both directions. The ratchet is the whole reason the waiver is tolerable.
  cat > "$t" <<'EOF'
sed -i 's@a@printf "%s" "$x" | grep -q y@' "$1"  # sdd-pipefail-waiver: sabotage payload
EOF
  probe 'a waived violation is accepted' 0 '-' "$t"

  cat > "$t" <<'EOF'
grep -q 'x' <<< "$v"  # sdd-pipefail-waiver: nothing left to waive
EOF
  probe 'a stale waiver fails' 1 'stale waiver' "$t"

  # Prose may NAME the marker without being one — this file's own header does, and so will any
  # doc explaining the rule. Without this probe, "skip whole-line comments" in stale_waivers is a
  # rule nothing exercises, and dropping it turns every mention of the marker into a failure.
  cat > "$t" <<'EOF'
# Lines that need it carry sdd-pipefail-waiver with a reason. This comment is not one.
grep -q 'x' <<< "$v"
EOF
  probe 'prose naming the marker is not a waiver' 0 '-' "$t"

  # 13: the unreadable file must not read as "clean". A missing path answering 0 is how a sensor
  # reports on a surface it never opened.
  probe 'a missing file is not silently clean' 94 'missing or unreadable' "$box/does-not-exist.sh"

  # ── RULE 2 ────────────────────────────────────────────────────────────────────────────────────
  # The shape that IS the bug, and the one every script in tests/ was written in.
  cat > "$t" <<'EOF'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EOF
  probe 'an unguarded cd into a capture is detected' 1 'no CDPATH guard' "$t"

  # The fix. Without this probe "flag every cd" scores full marks on the one above.
  cat > "$t" <<'EOF'
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EOF
  probe 'the CDPATH guard is accepted' 0 '-' "$t"

  # The guard has ONE spelling. `CDPATH= cd` empties CDPATH just as well, and is refused anyway:
  # the ratchet is toward one spelling, and without this probe that decision is unmeasured.
  cat > "$t" <<'EOF'
ROOT="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
EOF
  probe 'a non-canonical guard spelling is refused, not silently blessed' 1 'no CDPATH guard' "$t"

  # A flag between `cd` and the operand must not hide it — bin/sdd's own SDD_HOME resolution
  # writes `cd -P "$(dirname "$src")"`, and a rule keyed on `cd "` would have certified it clean.
  cat > "$t" <<'EOF'
dir="$(cd -P "$(dirname "$src")" && pwd)"
EOF
  probe 'a flag between cd and the operand does not hide it' 1 'no CDPATH guard' "$t"

  # The two operand shapes the header declares unmeasured. They are probes precisely BECAUSE they
  # are limits: if a later widening starts flagging them, that is a decision, not a surprise.
  cat > "$t" <<'EOF'
cd "$FIX" || exit 1
out="$( cd "$FIX/target" && "$KIT/bin/sdd" install 2>&1 )"
EOF
  probe 'a VARIABLE operand is out of scope (declared limit, not a silent pass)' 0 '-' "$t"

  cat > "$t" <<'EOF'
( cd "$ROOT" && ls -1 bin/sdd )
cd -P /tmp && pwd
EOF
  probe 'an absolute operand needs no guard' 0 '-' "$t"

  # `abcd`, `--cd`, `$cd`, `bin/cd`: the token has to BE the command. Without the leading boundary
  # the rule invents violations in every neighbouring word that happens to end in "cd".
  cat > "$t" <<'EOF'
abcd "$(f)"
foo --cd "$(f)"
"$cd" "$(f)"
/usr/bin/cd "$(f)"
EOF
  probe 'a word merely ending in cd is not the cd command' 0 '-' "$t"

  # Line number, same reason as rule 1: a report that cannot say WHERE is a rumour.
  cat > "$t" <<'EOF'
: line one
: line two
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EOF
  probe 'the cd violation carries its line number' 1 'probe.sh:3:' "$t"

  # Prose describing the trap is not the trap — this file's own header writes the bad shape.
  cat > "$t" <<'EOF'
  # never write ROOT="$(cd "$(dirname "$0")/.." && pwd)" without emptying CDPATH
EOF
  probe 'a whole-line comment showing the bad shape is accepted' 0 '-' "$t"

  # The two rules must be told APART. A file that breaks only rule 2 has to say so: with one
  # shared message, a reader (and the mission Check) could not tell which rule fired.
  cat > "$t" <<'EOF'
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EOF
  probe 'a rule-2 violation is not reported as a pipe into grep -q' 1 'no CDPATH guard' "$t"
  out_r2="$( "$SELF_PATH" --check "$t" 2>&1 )"
  PROBES=$((PROBES + 1))
  if grep -qF 'pipe into `grep -q`' <<< "$out_r2"; then
    printf 'SENSOR-BROKEN: rule 2 fired but the message blamed rule 1\n%s\n' "$out_r2" >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  fi

  # And bash's own behaviour, which is what the rule is FOR.
  cd_poison_probes "$box"

  # ── RULE 3 ────────────────────────────────────────────────────────────────────────────────────
  # `grep -m<N>` with NO quiet flag: the same early exit, one keystroke from a shape rule 1
  # already measures. Every spelling grep accepts for the flag gets a probe, for the same reason
  # rule 1 has six: a spelling this file does not know is a spelling it certifies as clean.
  cat > "$t" <<'EOF'
if printf '%s\n' "$out" | grep -m1 'BLOCKED'; then :; fi
EOF
  probe 'an attached -m1 with no quiet flag is detected' 1 'early-exiting `grep -m' "$t"

  cat > "$t" <<'EOF'
line="$(cat "$f" | grep -m 1 'x')"
EOF
  probe 'a separated -m 1 is detected' 1 'early-exiting `grep -m' "$t"

  cat > "$t" <<'EOF'
line="$(cat "$f" | grep -om1 'x')"
EOF
  probe 'a flag CLUSTER ending in m is detected' 1 'early-exiting `grep -m' "$t"

  cat > "$t" <<'EOF'
line="$(cat "$f" | grep --max-count=1 'x')"
EOF
  probe '--max-count= is detected (grep spells this flag two ways)' 1 'early-exiting `grep -m' "$t"

  cat > "$t" <<'EOF'
line="$(cat "$f" | grep --max-count 1 'x')"
EOF
  probe '--max-count with a separated argument is detected' 1 'early-exiting `grep -m' "$t"

  # The shapes that are NOT the bug. Without these, "flag every pipe into grep" scores full marks.
  cat > "$t" <<'EOF'
n="$(printf '%s\n' "$v" | grep -c 'x')"
EOF
  probe 'a pipe into a grep that reads to EOF is accepted' 0 '-' "$t"

  # The `m` has to be in a FLAG, not in an operand: `grep make` reads to EOF.
  cat > "$t" <<'EOF'
hits="$(ls | grep make)"
EOF
  probe 'an operand merely containing an m is not the -m flag' 0 '-' "$t"

  # And the flag is `-m` plus DIGITS, not any dashed token containing an m. Written as
  # `-[[:alnum:]]*m[[:alnum:]]*` the rule would fire on `-mtime`, `-march`, `-mode` — every dashed
  # word with an m in it — and a sensor that invents violations gets its rule deleted, not fixed.
  cat > "$t" <<'EOF'
hits="$(printf '%s\n' "$out" | grep -F -- -mtime)"
EOF
  probe 'a dashed word merely containing an m is not -m either' 0 '-' "$t"

  # No writer, no SIGPIPE: grep reading a FILE has nothing upstream to kill.
  cat > "$t" <<'EOF'
line="$(grep -m1 'x' "$f")"
EOF
  probe 'grep -m1 on a FILE (no pipe) is accepted' 0 '-' "$t"

  # ONE message per line. The line carrying BOTH flags is rule 1's — the fix is the same
  # herestring, and telling the reader the same defect twice under two names is how a report stops
  # being read. The second half is the half that matters: without it, "rule 1 owns it" is a claim
  # satisfied by rule 1 firing, whether or not rule 3 also did.
  cat > "$t" <<'EOF'
if foo | grep -m 1 -q x; then :; fi
EOF
  probe 'a line carrying both flags is reported by rule 1' 1 'pipe into `grep -q`' "$t"
  out_r3="$( "$SELF_PATH" --check "$t" 2>&1 )"
  PROBES=$((PROBES + 1))
  if grep -qF 'early-exiting `grep -m' <<< "$out_r3"; then
    printf 'SENSOR-BROKEN: a line carrying both flags was reported twice, once per rule\n%s\n' \
      "$out_r3" >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  fi

  # Line number, same reason as the other two rules: a report that cannot say WHERE is a rumour.
  cat > "$t" <<'EOF'
: line one
: line two
line="$(cat "$f" | grep -m1 'x')"
EOF
  probe 'the max-count violation carries its line number' 1 'probe.sh:3:' "$t"

  # Prose describing the trap is not the trap — this file's own header writes the bad shape.
  cat > "$t" <<'EOF'
   # never write cat "$f" | grep -m1 x here
EOF
  probe 'a whole-line comment naming the max-count shape is accepted' 0 '-' "$t"

  # The waiver has to know rule 3 exists. Without that, waiving a real max-count violation makes
  # the file fail as a STALE waiver — the marker on a line with "nothing to waive" — which reads
  # as the opposite of the truth and pushes the author to delete the marker.
  cat > "$t" <<'EOF'
line="$(cat "$f" | grep -m1 'x')"  # sdd-pipefail-waiver: sabotage payload
EOF
  probe 'a waived max-count violation is accepted, not called stale' 0 '-' "$t"

  # 14-16: the SCAN path, over fixture trees. Without these three the whole surface half of this
  # file is unmeasured: a floor lowered to zero, or a scan_surface that never calls check_file at
  # all, would both print "no pipe into grep -q" and exit 0 forever. That is precisely the
  # fail-open a sensor must not have — it would be asserting cleanliness about files it never
  # opened. `--scan` exists for these probes and is the same trick as `--check`.
  local tree i
  tree="$box/short"; mkdir -p "$tree/bin" "$tree/tests"; : > "$tree/bin/sdd"
  for i in 1 2 3; do : > "$tree/tests/check-$i.sh"; done
  probe 'a shrunken surface fails instead of reporting clean' 93 'surface shrank' "$tree" --scan

  # One test file per unit of the floor, minus the bin/sdd that comes free: the tree has to CLEAR
  # the floor, so this loop moves with it. Left one short, every probe below turns into "surface
  # shrank" and stops measuring the thing it names — which is how the floor bump of this mission
  # was caught, by three probes failing at once with the wrong message.
  tree="$box/full"; mkdir -p "$tree/bin" "$tree/tests"; : > "$tree/bin/sdd"
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13; do : > "$tree/tests/check-$i.sh"; done
  probe 'a full clean surface passes' 0 '(0 waived)' "$tree" --scan

  # The waived COUNT is the only thing that makes the waiver hole visible in a diff, so it is a
  # rule and not decoration: a counter stuck at zero would let waivers multiply in silence while
  # the summary kept printing the reassuring number.
  cat > "$tree/tests/check-4.sh" <<'EOF'
sed -i 's@a@printf "%s" "$x" | grep -q y@' "$1"  # sdd-pipefail-waiver: sabotage payload
EOF
  probe 'the summary counts the waivers it let through' 0 '(1 waived)' "$tree" --scan

  cat > "$tree/tests/check-7.sh" <<'EOF'
if printf '%s\n' "$out" | grep -q 'x'; then :; fi
EOF
  probe 'the scan actually opens each file on the surface' 1 'pipe into `grep -q`' "$tree" --scan

  # Rule 2 has to REPORT, not merely refrain from failing. A scan_surface that dropped the
  # `cdpath:` line would still exit 0 on a clean tree and still say "no pipe into grep -q" — green
  # here, and silently one assertion short everywhere that counts them.
  rm -f "$tree/tests/check-7.sh"; : > "$tree/tests/check-7.sh"
  probe 'a clean scan SAYS the cd rule was applied, it does not merely stay quiet' \
    0 'ok    cdpath:' "$tree" --scan

  # Same reason for rule 3, and it is the line the mission Check counts: dropping it would leave
  # a scan that still exits 0 on a clean tree and still names the other two rules, silently one
  # assertion short everywhere that counts them.
  probe 'a clean scan SAYS the max-count rule was applied too' \
    0 'ok    rule:' "$tree" --scan

  cat > "$tree/tests/check-7.sh" <<'EOF'
line="$(cat "$f" | grep -m1 'x')"
EOF
  probe 'the scan reports a max-count violation on the surface' \
    1 'early-exiting `grep -m' "$tree" --scan
  rm -f "$tree/tests/check-7.sh"; : > "$tree/tests/check-7.sh"

  rm -rf "$box"

  # Floor on the probe COUNT: neutering every assertion body leaves a selftest that ran nothing,
  # and a selftest that ran nothing reads exactly like one that passed. Moves only on purpose.
  if [ "$PROBES" -lt 57 ]; then
    printf 'SENSOR-BROKEN: only %d probe(s) ran, expected at least 57\n' "$PROBES" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi
  # Direct assignment, deliberately NOT through fail_rc: two independent paths from "a probe
  # failed" to "the selftest fails".
  if [ "$FAILS" -ne 0 ] && [ "$SELFTEST_RC" -eq 0 ]; then SELFTEST_RC=92; fi
  [ "$SELFTEST_RC" -eq 0 ] && \
    printf '  ok    selftest: %d probe(s), the sensor measures what it claims\n' "$PROBES"
  return "$SELFTEST_RC"
}

# --- surface scan ------------------------------------------------------------------------------
scan_surface() {
  local root="$1" files n_files fails=0 waived=0 f
  files="$(surface "$root")"
  n_files="$(grep -c . <<< "$files")"
  # Explicit floor, same reason as the one in check-lang.sh: a glob that stops matching leaves the
  # loop with nothing to read and the sensor reports "0 violations" — clean by vacuity. 14 paths
  # today (bin/sdd + thirteen suite scripts, minus this file); it was 11 until
  # tests/check-entrypoint.sh landed, 12 until tests/check-checkpoint.sh did and 13 until
  # tests/check-health.sh did, and it tracks the real count rather than staying at a number that
  # would still pass while describing a smaller surface than the one actually scanned.
  if [ "$n_files" -lt 14 ]; then
    printf '  FAIL  surface shrank to %d path(s), expected at least 14 — did something move?\n' \
      "$n_files" >&2
    return 93
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    check_file "$root/$f" "$f" || fails=$((fails + 1))
    waived=$((waived + $(waiver_count "$root/$f")))
  done <<< "$files"
  if [ "$fails" -ne 0 ]; then
    printf '\n%d file(s) break one of the three capture rules\n' "$fails" >&2
    return 1
  fi
  printf '  ok    %d path(s) scanned, no pipe into `grep -q` (%d waived)\n' "$n_files" "$waived"
  # Its own line, and prefixed: the two rules are reported separately so a reader (and the
  # mission Check that counts `^  ok    cdpath: `) can tell WHICH of them is being asserted.
  printf '  ok    cdpath: %d path(s) scanned, every `cd` into a capture empties CDPATH first\n' \
    "$n_files"
  # Rule 3, its own line for the same reason and carrying the prefix the mission Check counts:
  # a reader (and `grep -c '^  ok    rule: '`) has to be able to tell WHICH of the three rules is
  # being asserted, and a rule that only refrains from failing says nothing about having run.
  printf '  ok    rule: %d path(s) scanned, no pipe into an early-exiting `grep -m<N>` either\n' \
    "$n_files"
  return 0
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  # `${2-}` and not `${2:-}`: an EMPTY argument is a caller passing an unset variable, and it must
  # not default into a path that answers "ok" about a file nobody named.
  --check)    check_file "${2-}" "$(basename -- "${2-<none>}")"; exit $? ;;
  --scan)     scan_surface "${2-}"; exit $? ;;
  '')         selftest || exit $?; scan_surface "$ROOT"; exit $? ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
