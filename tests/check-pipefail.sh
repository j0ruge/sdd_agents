#!/usr/bin/env bash
# Sensor against the house's signature bug: a writer piped into an early-exiting `grep -q` while
# `set -o pipefail` is in force.
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
# What it measures, per scanned line:
#   1. a pipe into `grep` carrying a `-q` flag in any spelling — `-q`, `-qE`, `-Eq`, `-E -q`,
#      `--quiet`, `--silent`. The list is grep's own: `grep --help` prints the three names on one
#      line, and a spelling this file does not know is a spelling it certifies as clean
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
# NOT measured: `grep -m<N>`, which exits early for exactly the same reason. Same family, real
# gap, and it is in TODO.md rather than here — widening the rule would force conversions this
# increment did not scope, and a sensor that lands with unconverted violations lands red.
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
# — 26 sabotages, and the three that SURVIVED are worth naming rather than hiding, because all
# three are the harness testing itself and none is reachable in one edit:
#   - neutering fail_rc AND the FAILS cross-check (two independent paths, both must die)
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

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF_PATH="$ROOT/tests/check-pipefail.sh"
SELF_REL='tests/check-pipefail.sh'
WAIVER='sdd-pipefail-waiver'

# The pipe, optional whitespace, `grep`, any number of other flags, then a flag CLUSTER containing
# `q`. A cluster and not the exact token `-q`, because grep's short flags combine: `-qE`, `-Eq`
# and even `-qualifier` all pass `-q` to grep, and a rule keyed on the token would let the next
# author reintroduce the bug by adding one letter. The trailing `([[:space:]]|$)` keeps the `$`
# half load-bearing: `| grep -q` is legal at the end of a `\`-continued line.
#
# `--silent` sits beside `--quiet` because grep's own help prints all three on ONE line —
# `-q, --quiet, --silent` — and the long forms do not combine, so the cluster half cannot reach
# them. Measured: `yes | head -200000 | grep --silent x` returns 141 under pipefail exactly as the
# `-q` spelling does. It was missing from the first draft of this rule, which is the fail-open a
# sensor must never have: the header promised "any spelling" and knew two of the three.
PIPE_RE='\|[[:space:]]*grep([[:space:]]+-[[:alnum:]-]+)*[[:space:]]+(-[[:alnum:]]*q[[:alnum:]]*|--quiet|--silent)([[:space:]]|$)'

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
    if grep -qE "$PIPE_RE" <<< "$text"; then printf 'good\t%s\t%s\n' "$no" "$text"
    else printf 'stale\t%s\t%s\n' "$no" "$text"; fi
  done < <(grep -nF -- "$WAIVER" "$1" 2>/dev/null)
}

# waiver_count <file> — how many lines legitimately carry the marker.
waiver_count() {
  grep -c '^good' <<< "$(waiver_lines "$1")"
}

# check_file <file> — the real check on one path. rc 0 clean, 1 dirty, 94 unreadable.
check_file() {
  local f="$1" label="$2" bad found stale rc=0
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf '  FAIL  file missing or unreadable: %s\n' "$f" >&2
    return 94
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

selftest() {
  local box t
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

  # 7: the line number is reported, not just the fact. A sensor that cannot say WHERE sends the
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

  # 14-16: the SCAN path, over fixture trees. Without these three the whole surface half of this
  # file is unmeasured: a floor lowered to zero, or a scan_surface that never calls check_file at
  # all, would both print "no pipe into grep -q" and exit 0 forever. That is precisely the
  # fail-open a sensor must not have — it would be asserting cleanliness about files it never
  # opened. `--scan` exists for these probes and is the same trick as `--check`.
  local tree i
  tree="$box/short"; mkdir -p "$tree/bin" "$tree/tests"; : > "$tree/bin/sdd"
  for i in 1 2 3; do : > "$tree/tests/check-$i.sh"; done
  probe 'a shrunken surface fails instead of reporting clean' 93 'surface shrank' "$tree" --scan

  tree="$box/full"; mkdir -p "$tree/bin" "$tree/tests"; : > "$tree/bin/sdd"
  for i in 1 2 3 4 5 6 7 8 9 10; do : > "$tree/tests/check-$i.sh"; done
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

  rm -rf "$box"

  # Floor on the probe COUNT: neutering every assertion body leaves a selftest that ran nothing,
  # and a selftest that ran nothing reads exactly like one that passed. Moves only on purpose.
  if [ "$PROBES" -lt 19 ]; then
    printf 'SENSOR-BROKEN: only %d probe(s) ran, expected at least 19\n' "$PROBES" >&2
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
  # loop with nothing to read and the sensor reports "0 violations" — clean by vacuity. 11 paths
  # today (bin/sdd + ten suite scripts, minus this file).
  if [ "$n_files" -lt 11 ]; then
    printf '  FAIL  surface shrank to %d path(s), expected at least 11 — did something move?\n' \
      "$n_files" >&2
    return 93
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    check_file "$root/$f" "$f" || fails=$((fails + 1))
    waived=$((waived + $(waiver_count "$root/$f")))
  done <<< "$files"
  if [ "$fails" -ne 0 ]; then
    printf '\n%d file(s) pipe a writer into `grep -q`\n' "$fails" >&2
    return 1
  fi
  printf '  ok    %d path(s) scanned, no pipe into `grep -q` (%d waived)\n' "$n_files" "$waived"
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
