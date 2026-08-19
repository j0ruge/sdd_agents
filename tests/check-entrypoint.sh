#!/usr/bin/env bash
# Sensor for the runner's entry point: `bin/sdd` must not be able to return from its last command
# and go on reading itself.
#
# bash does not slurp a script. It parses command by command and keeps the file descriptor's
# offset in sync with what it has parsed, so that a command reading from stdin, or an `exec`,
# resumes at the right byte. When the LAST line of a script is a bare `main "$@"`, control returns
# to that read loop after main finishes, bash asks the file for more input — and gets whatever
# bytes now sit past the old end of file.
#
# That is not a hypothetical here. The EXEC phase edits `bin/sdd` DURING the `sdd run` that is
# executing it (10 times in one mission, +7647 bytes). What has kept it from biting is that the
# editor writes a new file and renames it, so the running bash keeps reading the old inode — an
# invariant of somebody else's tool, held by nothing this repo controls. An append (`>> "$0"`,
# `tee -a`, `cat >>`) preserves the inode and the fall-through fires.
#
# The fix is one line: `{ main "$@"; exit $?; }`. The braces close the syntactic unit and the
# `exit` means the read loop is never reached again, however much the file grew meanwhile.
#
# ── What this file measures ────────────────────────────────────────────────────────────────────
# Two assertions, and the first is DIFFERENTIAL on purpose. A single fixture could only show that
# the guarded form runs the entry point once, which is also what "bash never re-reads anything"
# looks like — a green that means nothing. So the probe builds TWO toy scripts, byte-identical
# except for that last line, has each one append to ITSELF in place and count its own entries, and
# compares the two counts against each other:
#
#   1. the unguarded toy enters its entry point MORE times than the guarded one, and the guarded
#      one exactly once. No regime of a one-sided fixture satisfies that by accident
#   2. the entry point of `bin/sdd` is the guarded form, and it is the LAST executable line
#
# Assertion 2 is what dies under `mut_RUN_entrypoint_unguarded`. Assertion 1 is what stops
# assertion 2 from being a style rule nobody can justify.
#
# Measured while this was written, on bash 5.2.21: the fall-through reproduces at EVERY size
# tried — 538 B, 4.5 KB, 20 KB, 129 KB, 196 KB — always 2 entries unguarded against 1 guarded.
# The filler stays at ~128 KB anyway, because the size at which a given bash stops holding the
# whole script in its buffer is an implementation detail and not a contract; a probe that only
# works on a small file would be trusting the very thing it is trying to measure.
#
# ── Known limits, stated so nobody re-discovers them as surprises ──────────────────────────────
# The runner rule is ONE exact spelling, not a family. `main "$@"; exit $?` without the braces is
# just as safe, and this file rejects it all the same. That is a contract rule rather than a
# safety rule: deciding, per spelling, whether a line ends the process needs a shell parser, and a
# line scanner that tried would fail open on the first shape nobody thought of. One spelling is
# also what lets the mutation kill this assertion — a rule matching a family survives a sabotage
# that just moves within the family.
#
# NOT measured either: an append that lands while bash sits INSIDE main. The offset only matters
# once main returns, so the guard covers it, but nothing here proves that.
#
# An adversarial pass degraded every parser rule on its own and demanded a red selftest for each:
# comment skip, blank skip, the missing final newline, FIRST instead of LAST, the empty-parse
# check, each half of the trim, and each direction of the equality loosened to a substring. Every
# one of those dies on the probe that names the exact rule.
#
# ⚠️ Three of those did NOT die when this file was first written, and the review round that found
# them measured all three rather than reasoning about them. They are recorded because the shape
# repeats: in all three the PARSER was probed and the path from "the parser said no" to "the suite
# goes red" was not.
#   - the equality loosened to `*"$GUARDED_FORM"*` passed all ten probes green, and accepted a file
#     whose last executable line is `note='{ main "$@"; exit $?; }'` — a line that contains the
#     guard, is not the guard, and falls straight back into the file. Probes 11 and 12 close it:
#     one carries the form as a strict PREFIX, the other as a strict SUFFIX, so no direction of the
#     loosening survives. The embedded-string case above is not written as a third probe because
#     probe 11 already kills every sabotage it would kill — a probe no sabotage needs is decoration
#   - deleting `FAILS=$((FAILS + 1)); fail_rc 91` from either branch of probe() changed nothing on
#     its own and went fail-OPEN beside any second defect: five SENSOR-BROKEN lines on stderr and
#     rc 0, printed under the ok line claiming the parser measures what it claims. harness_selfcheck
#     drives probe() with a deliberately wrong expectation and demands the failure was BOOKED
#   - deleting `differential` from the top-level composition left every assertion green and the
#     file exited 0 having never run the differential at all. probe_composition drives the whole
#     file with one stage forced to fail and demands rc 93 — once per stage
#
# The pass that closed those three ran 25 degradations, 20 of which die here. What SURVIVES is
# listed in full, because a survivor nobody wrote down is indistinguishable from one nobody looked
# for. In three groups, by what actually bounds each:
#
#   Not a rule — the rc is unchanged, so there is nothing to catch:
#   - dropping the `break` in the composition loop. First-failure-wins already fixed the verdict;
#     the break only decides how much runs after it was decided
#   - dropping the `FAILS -ne 0 → SELFTEST_RC=92` line. That is the deliberate redundancy described
#     at its own site: `fail_rc 91` still carries the failure out. Removing BOTH is what
#     harness_selfcheck catches
#
#   Floors and cross-checks, which hide nothing while the bodies they backstop are intact:
#   - lowering either probe floor, dropping the stage floor, disabling the witness cross-check
#
#   Genuinely fail-open here, and caught one layer out:
#   - neutering the composition's rc propagation, or stage()'s real branch. Either one means
#     check_runner's verdict never reaches the caller. Nothing inside this file can see that — the
#     last line of any sensor is the line it cannot assert on. `mut_RUN_entrypoint_unguarded`
#     closes it from outside: with bin/sdd sabotaged AND this composition neutered, the suite stays
#     green, which is exactly the rc the mutation driver reports as "NOT caught". Measured, both
#     ways round
#   - neutering the differential's own comparison, which no probe can reach. What bounds it is
#     that the two counts are PRINTED in the ok line ("2 vs 1"), so a neutered comparison reads
#     as "1 vs 1" in the suite output rather than as silence
#
# Neutering probe()'s body used to be a one-edit sabotage that made every assertion pass at once.
# It now needs to beat two independent things: the witness cross-check (no child was ever spawned)
# and harness_selfcheck (a failure that should have been booked was not).
#
# Usage: tests/check-entrypoint.sh              (probes, then the runner — what run-all calls)
#        tests/check-entrypoint.sh --selftest   (probes only)
#        tests/check-entrypoint.sh --check <f>  (one file's entry point, no probes — the real
#                                                reporting path, driven BY the probes without
#                                                recursing, so the parser gets exercised and not
#                                                just the function it lives in)
#
# Exit codes, one per cause:
#   0  the entry point is guarded              1  it is not
#   90 the differential probe stopped reproducing (read the message — it is not a green)
#   91 a form probe failed                     92 a floor, a harness probe, or no temp dir
#   93 a stage forced to fail by SDD_EP_FORCE_FAIL (internal — probe_composition only)
#   94 the file named on --check is missing or unreadable
#   96 unknown option

set -uo pipefail

# `${BASH_SOURCE[0]}` and not a hardcoded name: the probes re-invoke THIS file, and a copy running
# under another name has to probe itself, not whatever still sits at the old path.
SELF_PATH="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
ROOT="$(CDPATH='' cd "$(dirname "$SELF_PATH")/.." && pwd)"

# Every normal path below removes its own temp dir; the trap is for the abnormal ones (a signal, or
# `set -u` tripping over something a future edit forgot to set).
BOXES=()
cleanup_boxes() {
  local b
  for b in ${BOXES+"${BOXES[@]}"}; do [ -n "$b" ] && rm -rf "$b"; done
  return 0
}
trap cleanup_boxes EXIT

# The one spelling. Written once and read by the check, the messages and the probes — the house
# rule about an enum read in more than one place. Two copies and the sabotage moves one of them.
GUARDED_FORM='{ main "$@"; exit $?; }'

# ~128 KB of comment: 32 lines of 4096 filler characters. See the header for why the size is
# deliberately far above what the repro actually needs.
FILLER_LINES=32
FILLER_WIDTH=4096

# --- the form check ------------------------------------------------------------------------------

# entry_line <file> — prints the LAST line that is neither blank nor a whole-line comment.
#
# The last one, not the first match of anything: a `grep` for the guarded form anywhere in the
# file would pass on a script that carries it and then goes on to run three more commands, which
# is exactly the fall-through this sensor exists to forbid. Probe 4 is that shape.
entry_line() {
  local line last='' t
  # `|| [ -n "$line" ]` so a file with no trailing newline still yields its last line.
  while IFS= read -r line || [ -n "$line" ]; do
    t="${line#"${line%%[![:space:]]*}"}"   # ltrim
    t="${t%"${t##*[![:space:]]}"}"         # rtrim
    [ -n "$t" ] || continue
    case "$t" in '#'*) continue ;; esac
    last="$t"
  done < "$1"
  printf '%s\n' "$last"
}

# check_file <file> <label> — rc 0 guarded, 1 not, 94 unreadable.
check_file() {
  local f="$1" label="$2" got
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf '  FAIL  file missing or unreadable: %s\n' "$f" >&2
    return 94
  fi
  got="$(entry_line "$f")"
  # Anti-vacuity: a file the parser found nothing executable in must not read as "guarded". That
  # is how a sensor reports on a surface it never opened.
  if [ -z "$got" ]; then
    printf '  FAIL  %s: no executable line found — nothing was measured\n' "$label" >&2
    return 1
  fi
  if [ "$got" != "$GUARDED_FORM" ]; then
    printf '  FAIL  %s: the entry point is `%s`\n' "$label" "$got" >&2
    printf '        it has to be `%s` — bash resumes reading the file from the saved offset\n' \
      "$GUARDED_FORM" >&2
    printf '        after the last command returns, so a script that grows in place while it runs\n' >&2
    printf '        re-executes whatever landed past the old end of file.\n' >&2
    return 1
  fi
  return 0
}

# --- the differential probe -----------------------------------------------------------------------

# write_toy <path> <last-line> — a script that counts its own entries and grows itself once.
#
# The append is `>>`, which keeps the inode, because that is the case the editor's rename hides.
# The `$SDD_EP_GROWN` marker bounds the growth at one append, so a bash that re-reads more
# aggressively than expected still terminates instead of eating the disk.
write_toy() {
  local p="$1" last="$2" pad=x i
  while [ "${#pad}" -lt "$FILLER_WIDTH" ]; do pad="$pad$pad"; done
  cat > "$p" <<'TOY'
#!/usr/bin/env bash
main() {
  printf 'entered\n' >> "$SDD_EP_COUNTER"
  if [ ! -e "$SDD_EP_GROWN" ]; then
    : > "$SDD_EP_GROWN"
    printf '%s\n' 'main "$@"' >> "$0"
  fi
}
TOY
  for ((i = 0; i < FILLER_LINES; i++)); do printf '# %s\n' "$pad" >> "$p"; done
  printf '%s\n' "$last" >> "$p"
}

# run_toy <box> <name> — prints how many times the toy's entry point ran.
run_toy() {
  local box="$1" name="$2" c="$1/$2.count" g="$1/$2.grown"
  : > "$c"; rm -f "$g"
  SDD_EP_COUNTER="$c" SDD_EP_GROWN="$g" bash "$box/$name.sh" >/dev/null 2>&1
  grep -c . < "$c"
}

# differential — rc 0 reproduced, 90 it did not, 92 no temp dir.
differential() {
  local box unguarded guarded rc=0
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-entrypoint-XXXXXX")" || {
    printf 'SENSOR-BROKEN: no temp dir — the differential never ran\n' >&2; return 92; }
  BOXES+=("$box")

  write_toy "$box/unguarded.sh" 'main "$@"'
  write_toy "$box/guarded.sh" "$GUARDED_FORM"
  unguarded="$(run_toy "$box" unguarded)"
  guarded="$(run_toy "$box" guarded)"
  rm -rf "$box"

  if [ "$guarded" -ne 1 ]; then
    printf 'SENSOR-BROKEN: the GUARDED toy entered its entry point %s time(s), expected exactly 1\n' \
      "$guarded" >&2
    printf '  the guard itself stopped working, or the probe stopped running the toy at all\n' >&2
    rc=90
  elif [ "$unguarded" -le "$guarded" ]; then
    printf 'SENSOR-BROKEN: the UNGUARDED toy entered %s time(s) and the guarded one %s — the two\n' \
      "$unguarded" "$guarded" >&2
    printf '  are no longer distinguishable, so this bash does not re-read a script that grew in\n' >&2
    printf '  place. What died is the PROBE, not the reason for the guard: other builds do re-read.\n' >&2
    printf '  Do not delete the guard on this message — decide in writing whether the property is\n' >&2
    printf '  still worth measuring here, and say so in the file.\n' >&2
    rc=90
  else
    printf '  ok    an unguarded entry point re-runs (%s vs %s): the guard has something to guard\n' \
      "$unguarded" "$guarded"
  fi
  return "$rc"
}

# --- selftest -------------------------------------------------------------------------------------
#
# The mutation catalogue DOES reach the runner assertion, so these probes are not the anti-vacuity
# guard the neighbouring sensors need. They measure the PARSER instead: `entry_line` is the part
# no sabotage of bin/sdd can be wrong about, and its interesting failures (matching the form
# anywhere, accepting an empty parse, tripping over a trailing comment) all fail OPEN.
PROBES=0
FAILS=0
SELFTEST_RC=0
WITNESS=''
fail_rc() { [ "$SELFTEST_RC" -eq 0 ] && SELFTEST_RC="$1"; return 0; }

# probe <desc> <want_rc> <want_text|-> <file>
probe() {
  local desc="$1" want_rc="$2" want_txt="$3" f="$4" out rc
  PROBES=$((PROBES + 1))
  out="$( SDD_EP_WITNESS="$WITNESS" "$SELF_PATH" --check "$f" 2>&1 )"; rc=$?
  if [ "$rc" -ne "$want_rc" ]; then
    printf 'SENSOR-BROKEN: %s — wanted rc %s, got %s\n%s\n' "$desc" "$want_rc" "$rc" "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 91; return 0
  fi
  if [ "$want_txt" != '-' ] && ! grep -qF -- "$want_txt" <<< "$out"; then
    printf 'SENSOR-BROKEN: %s — rc was right but the message never said "%s"\n%s\n' \
      "$desc" "$want_txt" "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 91; return 0
  fi
}

COMPOSITION_PROBES=0

# harness_selfcheck <scratch-file> <scratch-err> — measures the PROBE, not the parser.
#
# Both arms drive probe() with an expectation that is deliberately wrong, then demand the failure
# was BOOKED and not merely printed. probe() has two accounting sites (the rc branch and the text
# branch) and each arm reaches exactly one, so a sabotage of either is caught by itself.
#
# Deleting `FAILS=$((FAILS + 1)); fail_rc 91` used to be invisible: latent on its own, because with
# a healthy parser no probe ever diverges, and fail-OPEN next to any second defect. Measured before
# this existed — five SENSOR-BROKEN lines on stderr and rc 0, printed under the ok line that says
# the parser measures what it claims. run-all.sh reads only the rc, so that is green in the suite.
harness_selfcheck() {
  local t="$1" err="$2" saved_fails="$FAILS" saved_rc="$SELFTEST_RC" broke=0
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' 'main "$@"' > "$t"

  # Arm 1 — the rc branch. `--check` answers 1 on this file; ask for 0.
  FAILS=0; SELFTEST_RC=0
  probe 'harness arm 1 — this divergence is EXPECTED' 0 '-' "$t" 2>"$err"
  if [ "$FAILS" -ne 1 ] || [ "$SELFTEST_RC" -ne 91 ]; then
    printf 'SENSOR-BROKEN: probe() met a wrong rc and booked FAILS=%s SELFTEST_RC=%s, wanted 1 and\n' \
      "$FAILS" "$SELFTEST_RC" >&2
    printf '  91 — a diverging probe would be printed and then forgotten\n' >&2
    broke=1
  fi
  if ! grep -q 'SENSOR-BROKEN' "$err"; then
    printf 'SENSOR-BROKEN: probe() booked the rc divergence without saying anything about it\n' >&2
    broke=1
  fi

  # Arm 2 — the text branch, booked at its own site. The rc is right, the message is not.
  FAILS=0; SELFTEST_RC=0
  probe 'harness arm 2 — this divergence is EXPECTED' 1 'a phrase this sensor never prints' "$t" 2>"$err"
  if [ "$FAILS" -ne 1 ] || [ "$SELFTEST_RC" -ne 91 ]; then
    printf 'SENSOR-BROKEN: probe() met the wrong MESSAGE and booked FAILS=%s SELFTEST_RC=%s,\n' \
      "$FAILS" "$SELFTEST_RC" >&2
    printf '  wanted 1 and 91 — a probe could then assert any text at all\n' >&2
    broke=1
  fi

  FAILS="$saved_fails"; SELFTEST_RC="$saved_rc"
  if [ "$broke" -ne 0 ]; then FAILS=$((FAILS + 1)); fail_rc 92; fi
}

# probe_composition <stage> — measures the top-level dispatch, the only path no probe reached.
#
# It runs the WHOLE file with one stage forced to fail and demands rc 93 come back out. Deleting
# `differential` from the composition left all ten probes green and the file exited 0 having never
# run it — measured. SDD_EP_FORCE_FAIL stubs every OTHER stage to a no-op, so the child does no real
# work and cannot recurse into this function.
probe_composition() {
  local st="$1" out rc
  COMPOSITION_PROBES=$((COMPOSITION_PROBES + 1))
  out="$( SDD_EP_FORCE_FAIL="$st" "$SELF_PATH" 2>&1 )"; rc=$?
  if [ "$rc" -ne 93 ]; then
    printf 'SENSOR-BROKEN: stage `%s` was forced to fail and the file exited %s, not 93 — the\n' \
      "$st" "$rc" >&2
    printf '  composition either never runs that stage or swallows its rc\n%s\n' "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi
}

selftest() {
  local box t
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-entrypoint-selftest-XXXXXX")" || {
    printf 'SENSOR-BROKEN: no temp dir — the probes never ran\n' >&2; return 92; }
  BOXES+=("$box")
  t="$box/probe.sh"
  WITNESS="$box/witness"; : > "$WITNESS"

  # 1: the defect. This is the shape bin/sdd shipped with for its whole life.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' 'main "$@"' > "$t"
  probe 'a bare `main "$@"` is refused' 1 'the entry point is `main "$@"`' "$t"

  # 2: the fix.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' "$GUARDED_FORM" > "$t"
  probe 'the guarded form is accepted' 0 '-' "$t"

  # 3: blank lines and a trailing comment after the guard are still guarded. Every real file ends
  # in some of these, and a parser that took the literal last LINE would reject the fix itself.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' "$GUARDED_FORM" '' '# trailing note' '' > "$t"
  probe 'blank lines and comments after the guard do not hide it' 0 '-' "$t"

  # 4: the one that separates "the form is the LAST executable line" from "the form appears
  # somewhere". A `grep` implementation passes this file, and this file is the fall-through.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' "$GUARDED_FORM" 'echo late' > "$t"
  probe 'the guard followed by another command is not a guard' 1 'the entry point is `echo late`' "$t"

  # 5: anti-vacuity. A file with nothing executable must not answer "guarded".
  printf '%s\n' '# only a comment' '' > "$t"
  probe 'a file with no executable line is not silently guarded' 1 'no executable line' "$t"

  # 6: the near-miss that matters. `{ main "$@"; }` closes the syntactic unit and changes nothing:
  # bash returns from the group and goes straight back to the read loop.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' '{ main "$@"; }' > "$t"
  probe 'braces without the exit are not the guard' 1 'the entry point is `{ main "$@"; }`' "$t"

  # 7: the contract limit, named in the header. This spelling is SAFE and refused anyway.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' 'main "$@"; exit $?' > "$t"
  probe 'a safe-but-different spelling is refused (one spelling, on purpose)' 1 'it has to be' "$t"

  # 8: indentation is not a difference. The trim is a rule like any other.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' "   $GUARDED_FORM  " > "$t"
  probe 'the guarded form survives being indented' 0 '-' "$t"

  # 9: a file with no trailing newline. `read` returns false on that last line, and a loop without
  # the `|| [ -n "$line" ]` would drop it — reading the guard as absent on a perfectly good file,
  # or worse, reading a fall-through as guarded.
  printf '%s\n%s\n%s' '#!/usr/bin/env bash' 'main() { :; }' "$GUARDED_FORM" > "$t"
  probe 'a file with no final newline still shows its last line' 0 '-' "$t"

  # 10: the missing path must not read as clean.
  probe 'a missing file is not silently guarded' 94 'missing or unreadable' "$box/does-not-exist.sh"

  # 11 and 12: the equality is an EQUALITY, in both directions. Loosening it to a substring test
  # passed probes 1-10 green — measured, not supposed — because every non-guarded fixture above is
  # SHORTER than the guard and none can contain it. These two are longer and contain it.
  #
  # 11 carries the form as a strict prefix, and is the dangerous one: `&` backgrounds the group, so
  # the parent returns to the read loop with the file possibly grown. It kills `"$FORM"*` and
  # `*"$FORM"*`.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' "$GUARDED_FORM &" > "$t"
  probe 'the guard backgrounded is not the guard' 1 'the entry point is' "$t"

  # 12 carries it as a strict suffix, which `*"$FORM"` would accept. This spelling is SAFE — it
  # does exit — and is refused anyway, for the same one-spelling reason as probe 7.
  printf '%s\n' '#!/usr/bin/env bash' 'main() { :; }' "true && $GUARDED_FORM" > "$t"
  probe 'the guard behind another command is not the guard' 1 'it has to be' "$t"

  # The harness and the composition: two paths that carry a failure from here to the suite, and
  # neither had a probe. See harness_selfcheck and probe_composition for what each one measured.
  harness_selfcheck "$t" "$box/harness.err"
  probe_composition selftest
  probe_composition differential
  probe_composition check_runner

  # Cross-check on the HARNESS itself. Replacing probe()'s body with `out="$want_txt";
  # rc="$want_rc"` makes all ten assertions above pass at once and none of them can notice — in
  # the adversarial pass it was the one sabotage that survived, and it cost a single edit.
  #
  # The witness closes it from the OTHER side: the real `--check` entry point appends a line every
  # time it is invoked, so a probe harness that never spawns the child leaves a count that does not
  # match. A first attempt at this block ran `--check` directly on a known-bad file, which was
  # redundant with probes 1-10 and, being redundant, could not be shown red by any sabotage — the
  # kit's own rule for telling a rule from a decoration.
  local seen
  seen="$(grep -c . < "$WITNESS" 2>/dev/null)"
  if [ "${seen:-0}" -ne "$PROBES" ]; then
    printf 'SENSOR-BROKEN: %d probe(s) counted, but the real --check path ran %s time(s) — the\n' \
      "$PROBES" "${seen:-0}" >&2
    printf '  harness is not invoking the thing it reports on\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  rm -rf "$box"

  # Floors on the probe COUNTS: neutering every assertion body leaves a selftest that ran nothing,
  # and a selftest that ran nothing reads exactly like one that passed. 12 form probes plus the two
  # harness arms; the composition probes are counted apart because they drive a different path.
  if [ "$PROBES" -lt 14 ]; then
    printf 'SENSOR-BROKEN: only %d probe(s) ran, expected at least 14\n' "$PROBES" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi
  if [ "$COMPOSITION_PROBES" -lt 3 ]; then
    printf 'SENSOR-BROKEN: only %d composition probe(s) ran, expected one per stage (3)\n' \
      "$COMPOSITION_PROBES" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi
  # Direct assignment, deliberately NOT through fail_rc. The two are independent against a sabotage
  # of EITHER accounting site: drop `fail_rc 91` and FAILS still lands here; drop the FAILS counter
  # and fail_rc still carries the 91 out. Dropping BOTH — which is one edit, and was the hole this
  # comment used to paper over — is what harness_selfcheck exists to catch.
  if [ "$FAILS" -ne 0 ] && [ "$SELFTEST_RC" -eq 0 ]; then SELFTEST_RC=92; fi
  [ "$SELFTEST_RC" -eq 0 ] && \
    printf '  ok    selftest: %d probe(s) + %d composition probe(s), the entry-point parser and the\n        two paths that report on it measure what they claim\n' \
      "$PROBES" "$COMPOSITION_PROBES"
  return "$SELFTEST_RC"
}

# --- the real check ---------------------------------------------------------------------------

check_runner() {
  check_file "$ROOT/bin/sdd" 'bin/sdd' || return $?
  printf '  ok    bin/sdd ends in `%s` — it cannot fall through into itself\n' "$GUARDED_FORM"
  return 0
}

# stage <name> — one member of the composition, or its stub while probe_composition drives.
#
# The stub exists only so the composition itself can be measured: without it, the loop below is
# three names nobody probes, and dropping one of them is a silent green. SDD_EP_FORCE_FAIL is never
# set by anything but probe_composition, so every real run takes the first branch.
#
# The counter is the half probe_composition cannot reach. probe_composition lives INSIDE selftest,
# so dropping `selftest` from the list also drops the probes that would have noticed — measured, it
# survived as a clean rc 0. The counter is read after the loop, outside every stage.
STAGES_RUN=0
stage() {
  STAGES_RUN=$((STAGES_RUN + 1))
  case "${SDD_EP_FORCE_FAIL:-}" in
    '')   "$1"; return $? ;;
    "$1") printf 'SENSOR-BROKEN: stage %s forced to fail (composition probe)\n' "$1" >&2; return 93 ;;
    *)    return 0 ;;
  esac
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  # `${2-}` and not `${2:-}`: an EMPTY argument is a caller passing an unset variable, and it must
  # not default into a path that answers "ok" about a file nobody named.
  # The witness line is how selftest() proves its probes really spawned this path instead of
  # inventing the answers. Only the probes ever set the variable; everywhere else it is unset and
  # this is a no-op.
  --check)    [ -z "${SDD_EP_WITNESS:-}" ] || printf 'check\n' >> "$SDD_EP_WITNESS"
              check_file "${2-}" "$(basename -- "${2-<none>}")"; exit $? ;;
  # The three stages, composed through `stage` so that probe_composition can drive this very loop.
  # Written as a list and not as three lines because a list is what a probe can count: dropping a
  # name here turns exactly one composition probe red, naming the stage that went missing.
  '')         SUITE_RC=0
              for _stage in selftest differential check_runner; do
                stage "$_stage"; _stage_rc=$?
                [ "$SUITE_RC" -ne 0 ] || SUITE_RC="$_stage_rc"   # first failure wins
                # Fail-fast is behaviour, not an assertion: with the line above intact, removing
                # this one changes only how much runs after the verdict is already decided.
                [ "$SUITE_RC" -eq 0 ] || break
              done
              # Composition floor, read outside every stage. See stage() for why probe_composition
              # cannot cover the case where `selftest` itself is the name that went missing.
              if [ "$SUITE_RC" -eq 0 ] && [ "$STAGES_RUN" -ne 3 ]; then
                printf 'SENSOR-BROKEN: %d of 3 stages ran and the file still answered ok\n' \
                  "$STAGES_RUN" >&2
                SUITE_RC=92
              fi
              exit "$SUITE_RC" ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
