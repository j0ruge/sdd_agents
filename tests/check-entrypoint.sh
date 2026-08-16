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
# An adversarial pass degraded every parser rule on its own and demanded a red selftest for each —
# ten sabotages, eight died on the probe that names the exact rule (comment skip, blank skip, the
# missing final newline, FIRST instead of LAST, the empty-parse check, the equality loosened to a
# substring, and each half of the trim). The two that SURVIVED are named rather than hidden:
#   - lowering the probe floor on its own, which hides nothing while the probe bodies are intact
#   - neutering the differential's own comparison, which no probe can reach. What bounds it is
#     that the two counts are PRINTED in the ok line ("2 vs 1"), so a neutered comparison reads
#     as "1 vs 1" in the suite output rather than as silence
# Neutering probe()'s body used to be a third, and a one-edit one: it made all ten assertions pass
# at once. The cross-check at the end of selftest() is what turned it into two edits.
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
#   91 a form probe failed                     92 probe floor, or no temp dir
#   94 the file named on --check is missing or unreadable
#   96 unknown option

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF_PATH="$ROOT/tests/check-entrypoint.sh"

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

selftest() {
  local box t
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-entrypoint-selftest-XXXXXX")" || {
    printf 'SENSOR-BROKEN: no temp dir — the probes never ran\n' >&2; return 92; }
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

  # Floor on the probe COUNT: neutering every assertion body leaves a selftest that ran nothing,
  # and a selftest that ran nothing reads exactly like one that passed.
  if [ "$PROBES" -lt 10 ]; then
    printf 'SENSOR-BROKEN: only %d probe(s) ran, expected at least 10\n' "$PROBES" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi
  # Direct assignment, deliberately NOT through fail_rc: two independent paths from "a probe
  # failed" to "the selftest fails".
  if [ "$FAILS" -ne 0 ] && [ "$SELFTEST_RC" -eq 0 ]; then SELFTEST_RC=92; fi
  [ "$SELFTEST_RC" -eq 0 ] && \
    printf '  ok    selftest: %d probe(s), the entry-point parser measures what it claims\n' "$PROBES"
  return "$SELFTEST_RC"
}

# --- the real check ---------------------------------------------------------------------------

check_runner() {
  check_file "$ROOT/bin/sdd" 'bin/sdd' || return $?
  printf '  ok    bin/sdd ends in `%s` — it cannot fall through into itself\n' "$GUARDED_FORM"
  return 0
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
  '')         selftest || exit $?
              differential || exit $?
              check_runner; exit $? ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
