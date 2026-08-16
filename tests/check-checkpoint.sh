#!/usr/bin/env bash
# Sensor for the Check cells of every mission checkpoint.
#
# The checkpoint's Check is the increment's own sensor: the runner never reads it, a human does,
# and the mission's metric quotes it verbatim as the proof that the increment works. So a Check
# that cannot fail is the same defect this kit hunts everywhere else — a label wearing an
# artifact's clothes.
#
# One shape produces it, and this mission shipped three of them before QA measured it. Every
# behavioural sensor in tests/ prints its assertions through the same pair:
#
#     pass() { printf '  ok    %s\n' "$1"; }                       -> stdout
#     fail() { printf '  FAIL  %s\n ...' "$1" ... >&2; }           -> stderr, SAME text
#
# A Check that merges the two streams and greps the bare assertion text therefore answers
# "the assertion exists", never "the assertion passed":
#
#     o=$(bash tests/check-kaizen.sh 2>&1); grep -c 'a row from another repo ...' <<< "$o"
#     -> 1 with the assertion green, and 1 with it red. Measured, not reasoned about.
#
# The fix is the anchor: `grep -c '^  ok    a row from another repo ...'`, which only the stdout
# side can satisfy. That is the rule this file enforces.
#
# What it measures, per row of every checkpoint table under docs/handoffs/ plus the template:
#   1. the row hands the runner exactly five columns. `checkpoint_rows` in bin/sdd is a raw
#      `awk -F'|'` and does not know GFM's `\|`, so a pipe inside a cell shifts Status and Commit
#      one place and gate_EXEC starts reading a fragment of the command as a status token. It is
#      also what keeps rule 2 from failing open: with the columns shifted, the Check cell this
#      file reads is a truncation and the anchor rule would stop applying in silence.
#   2. a Check cell that merges stderr (`2>&1`) AND greps must carry the `^  ok    ` anchor on
#      every one of its greps. Both halves of the precondition matter: without `2>&1` there is no
#      FAIL text in the stream to confuse, and without `grep` nothing is being read.
#   3. the rule is written where the next mission will meet it — templates/checkpoint.md and
#      agents/sdd-planner.md — so a checkpoint born tomorrow does not have to rediscover it.
#      Contract in three places, the house rule from CLAUDE.md.
#   4. the anchor it enforces IS the prefix the suite's sensors print, derived from their `pass()`
#      lines rather than restated. See calibrate() for why that is not decoration.
#
# What it deliberately does NOT measure: whether the expected value beside the arrow is the right
# one, whether the Check actually exercises the increment, or whether a Check with no grep at all
# is strong. All three are human judgement on the diff. Rule 2 stops the one regression that rots
# in silence, which is the half prose already lost twice.
#
# Every rule is STRUCTURAL — a pipe count, a shell token, an anchor literal — never a Portuguese
# word, for the same reason as check-todo.sh: the files it reads are mission content in the target
# repo's OUTPUT_LANG, so a rule keyed on prose would break in an English repo and would measure
# the writer's vocabulary instead of the Check's power.
#
# Usage: tests/check-checkpoint.sh              (selftest, then scan the kit — what run-all calls)
#        tests/check-checkpoint.sh --selftest   (probes only)
#        tests/check-checkpoint.sh --check <f>  (one checkpoint, no selftest, no floors — used BY
#                                                the selftest to exercise the real reporting path
#                                                without recursing)
#        tests/check-checkpoint.sh --scan <dir> (scan one tree, no selftest — likewise, so the
#                                                floors and the doc assertions get probed too)
#        tests/check-checkpoint.sh --calibrate <dir>
#                                               (derive the ok prefix from a tree of sensors and
#                                                compare it to the anchor — likewise)
#
# ── Known limits, stated so nobody re-discovers them as surprises ──────────────────────────────
# NOT measured: a Check that reads a sensor WITHOUT merging stderr and greps for the assertion
# text on stdout alone. That one is already correct — FAIL never reaches the stream it reads —
# but it is correct by the redirection it omits rather than by the anchor, so a later edit adding
# `2>&1` for convenience turns it blind and this file catches it only from that moment on.
#
# NOT measured either: a grep whose pattern is built from a variable, or one spelled `egrep` /
# `rg` / `awk /.../`. The rule is keyed on the shape people actually write in a checkpoint cell,
# which is a literal single-quoted pattern handed to `grep`. Widening it needs a shell parser, and
# every generalisation tried on the neighbouring sensors fired on legitimate lines first.
#
# NOT measured either: whether the anchor's assertion text matches an assertion that exists. A
# Check anchored on `^  ok    ` for a sentence no sensor ever prints returns 0 instead of 1 and
# fails honestly — wrong answer, not a silent green — which is the direction that costs nothing.
#
# This file MEASURES MARKDOWN, so tests/check-mutation.sh cannot reach it: that catalogue sabotages
# bin/sdd, and no sabotage of the runner would make this sensor die. Its guard is selftest(),
# which drives the real --check and --scan paths and exits 90/91/92 the moment detection stops
# working, plus four floors against vacuity. An adversarial pass degraded every rule on its own
# and demanded a red for each: 44 sabotages over four rounds, and the four survivors of the first
# three rounds all became probes (the widened anchor, the calibration comparison, and the two
# paths from scan_file's counters to scan()'s verdict — the last two meant every cell-rule probe
# was running through --check only). The one survivor left is named at the bottom of the selftest.
#
# Exit codes, one per cause, FIRST failure wins:
#    0  clean                        1  a checkpoint has violations
#   89  no temp dir (probes never ran)      90/91/92  a selftest probe failed
#   93  a floor was breached (the scan was vacuous)
#   94  a checkpoint named on the command line is missing or unreadable
#   96  unknown option

set -uo pipefail

SELF_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The anchor, written ONCE and read by three things: the cell rule, the two doc assertions, and
# the probes. Written twice it would be the enum-in-three-places failure the house rule forbids —
# widen the cell rule to accept three spaces and the doc assertion would go on certifying four.
OK_ANCHOR='^  ok    '
ANCHOR_SQ="'${OK_ANCHOR}"
ANCHOR_DQ="\"${OK_ANCHOR}"

# Floors against vacuity. The first two catch a glob that stops matching or a parser that stops
# recognising rows; the third is the one that matters most, because rule 2 only APPLIES to a cell
# that merges stderr and greps. Break its precondition and the file reports "clean" over a rule it
# never ran once. They are minimums, not the real counts: missions add checkpoints, and a floor
# that had to be bumped every mission would be bumped without being read.
FILE_FLOOR=5
ROW_FLOOR=20
RULED_FLOOR=4

pass() { printf '  ok    %s\n' "$1"; }
# The FAIL text is deliberately NOT the pass text: this whole file exists because a sensor whose
# two verdicts share a sentence cannot be read by a grep.
fail() { printf '  FAIL  %s\n' "$1" >&2; }

# count_occ <needle> <haystack> — how many times needle occurs. Pure parameter expansion: no
# subprocess per cell, and no pipeline that could invert under pipefail.
count_occ() {
  local needle="$1" hay="$2" n=0
  [ -n "$needle" ] || { printf '0\n'; return 0; }
  while [ "${hay#*"$needle"}" != "$hay" ]; do
    n=$((n + 1)); hay="${hay#*"$needle"}"
  done
  printf '%d\n' "$n"
}

# The scanned surface: every mission checkpoint plus the template they are all born from.
# Takes the root as an argument rather than reading the global, so the selftest can drive the real
# scan() path over a fixture tree — a floor without a probe is a wish.
surface() {
  ( cd "$1" && ls -1 docs/handoffs/*/checkpoint.md templates/checkpoint.md 2>/dev/null )
}

# rows_of <path> — one line per table row: "NF<TAB>ID<TAB>Check cell".
#
# The row recognition MIRRORS checkpoint_rows() in bin/sdd on purpose: this file has to read the
# cell the runner reads, not a better-parsed one. NF is emitted rather than checked here so the
# caller can tell "pipe inside a cell" from "not a table row at all".
rows_of() {
  awk -F'|' '
    /^[ \t]*\|/ {
      if (NF < 6) next
      id = $2; gsub(/^[ \t]+|[ \t]+$/, "", id)
      if (id == "ID" || id ~ /^-+$/ || id == "") next
      status = $5; gsub(/^[ \t]+|[ \t]+$/, "", status)
      if (status == "Status") next
      chk = $4; gsub(/^[ \t]+|[ \t]+$/, "", chk)
      printf "%d\t%s\t%s\n", NF, id, chk
    }' "$1"
}

# Counters published as globals and never through a command substitution: a function read as
# `x="$(f)"` runs in a subshell and every assignment it makes dies with it (CLAUDE.md).
N_FILES=0; N_ROWS=0; N_RULED=0; V_ANCHOR=0; V_COLS=0

reset_counters() { N_FILES=0; N_ROWS=0; N_RULED=0; V_ANCHOR=0; V_COLS=0; }

# scan_file <path> <label> — accumulates into the globals, prints one FAIL per violation.
scan_file() {
  local path="$1" label="$2" rows nf id chk g a
  rows="$(rows_of "$path")"
  N_FILES=$((N_FILES + 1))
  while IFS=$'\t' read -r nf id chk; do
    [ -n "$nf" ] || continue
    N_ROWS=$((N_ROWS + 1))

    # Rule 1 — five columns, or the cell below is a truncation and rule 2 fails open.
    if [ "$nf" -ne 7 ]; then
      fail "$label: row $id hands the runner $((nf - 2)) column(s) instead of 5 — a '|' inside a cell splits it, and awk -F'|' does not know GFM's backslash escape"
      V_COLS=$((V_COLS + 1))
      continue
    fi

    # Rule 2 — precondition: the cell merges stderr AND greps. Either half missing and there is
    # no FAIL text in the stream being read.
    case "$chk" in *'2>&1'*) ;; *) continue ;; esac
    g="$(count_occ 'grep' "$chk")"
    [ "$g" -gt 0 ] || continue
    N_RULED=$((N_RULED + 1))
    a=$(( $(count_occ "$ANCHOR_SQ" "$chk") + $(count_occ "$ANCHOR_DQ" "$chk") ))
    if [ "$a" -lt "$g" ]; then
      fail "$label: the Check of $id greps a sensor's merged output with $a of $g pattern(s) anchored on the ok prefix — FAIL prints the same text as ok, so this cell answers 'the assertion exists', never 'the assertion passed'"
      V_ANCHOR=$((V_ANCHOR + 1))
    fi
  done <<< "$rows"
}

# doc_rule <path> <label> <assertion> — the rule has to be written where the next planner meets
# it. Both halves are demanded: the anchor alone could be a stray copy of a Check, and `2>&1`
# alone says nothing. Structural, so it survives a target repo writing its prose in any language.
doc_rule() {
  local path="$1" label="$2" desc="$3"
  if [ ! -r "$path" ]; then
    fail "$label is missing or unreadable — the rule has nowhere to live"
    return 1
  fi
  if grep -qF -- "$OK_ANCHOR" "$path" && grep -qF -- '2>&1' "$path"; then
    pass "$desc"
    return 0
  fi
  fail "$label never states the ok-anchor rule (wanted the literals '$OK_ANCHOR' and '2>&1') — the next checkpoint will be born blind"
  return 1
}

scan() { # scan <root> — the full surface, floors and doc assertions included
  local root="$1" files f rc=0
  reset_counters
  files="$(surface "$root")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    scan_file "$root/$f" "$f"
  done <<< "$files"

  if [ "$N_FILES" -lt "$FILE_FLOOR" ]; then
    fail "the surface shrank to $N_FILES checkpoint(s), expected at least $FILE_FLOOR — did docs/handoffs/ move?"
    return 93
  fi
  if [ "$N_ROWS" -lt "$ROW_FLOOR" ]; then
    fail "only $N_ROWS checkpoint row(s) recognised, expected at least $ROW_FLOOR — did the table shape change?"
    return 93
  fi
  if [ "$N_RULED" -lt "$RULED_FLOOR" ]; then
    fail "the anchor rule applied to $N_RULED cell(s), expected at least $RULED_FLOOR — a clean report over a rule that never ran is the failure this file exists to catch"
    return 93
  fi

  if [ "$V_ANCHOR" -eq 0 ]; then
    pass "no checkpoint Check reads a red assertion as green ($N_RULED cell(s) under the rule, $N_ROWS row(s) in $N_FILES file(s))"
  else
    rc=1
  fi
  if [ "$V_COLS" -eq 0 ]; then
    pass "every checkpoint row hands the runner five columns ($N_ROWS row(s))"
  else
    rc=1
  fi

  doc_rule "$root/templates/checkpoint.md" "templates/checkpoint.md" \
    "the checkpoint template teaches the ok-anchor rule" || rc=1
  doc_rule "$root/agents/sdd-planner.md" "agents/sdd-planner.md" \
    "the planner agent teaches the ok-anchor rule" || rc=1

  [ "$rc" -eq 0 ] || fail "$((V_ANCHOR + V_COLS)) checkpoint violation(s)"
  return "$rc"
}

# calibrate <root> — the anchor this file enforces has to BE the prefix the suite's sensors really
# print, and that is DERIVED from their source rather than restated here.
#
# This assertion exists because an adversarial pass found the one survivor of every other rule:
# widening OK_ANCHOR to `ok` left the selftest green, since the probes BUILD their fixtures from
# OK_ANCHOR and a widened rule widens its own evidence in lockstep. Anything keyed on the value
# alone has that shape. What breaks the tie is a second, independent witness — the `pass()` line
# of every behavioural sensor — so a widened anchor no longer matches the thing it is an anchor
# FOR. It also catches the mirror failure, which is the one that will actually happen some day:
# the house changes the ok prefix and this file goes on enforcing the old one.
CALIBRATE_FLOOR=4
calibrate() {
  local root="$1" f line p seen='' n=0
  for f in "$root"/tests/*.sh; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
      case "$line" in "pass() { printf '"*) ;; *) continue ;; esac
      p="${line#*printf \'}"
      case "$p" in *'%s'*) ;; *) continue ;; esac
      p="${p%%"%s"*}"
      n=$((n + 1))
      if [ -z "$seen" ]; then
        seen="$p"
      elif [ "$seen" != "$p" ]; then
        fail "the suite's sensors disagree about the ok prefix ('$seen' in one file, '$p' in $(basename -- "$f")) — no single anchor can be right for both"
        return 1
      fi
    done < "$f"
  done
  if [ "$n" -lt "$CALIBRATE_FLOOR" ]; then
    fail "only $n sensor(s) declare an ok prefix, expected at least $CALIBRATE_FLOOR — the anchor was calibrated against almost nothing"
    return 1
  fi
  if [ "^$seen" != "$OK_ANCHOR" ]; then
    fail "this file enforces the anchor '$OK_ANCHOR' but the suite's sensors print '$seen' — one of the two moved, and the rule now certifies a prefix nobody writes"
    return 1
  fi
  pass "the ok anchor is the prefix the suite's sensors actually print ($n sensor(s))"
  return 0
}

check_one() { # check_one <path> — one checkpoint, no floors, no doc assertions
  local path="${1-}"
  if [ -z "$path" ] || [ ! -r "$path" ]; then
    fail "checkpoint not readable: ${path:-<none>}"
    return 94
  fi
  reset_counters
  scan_file "$path" "$(basename -- "$path")"
  if [ $((V_ANCHOR + V_COLS)) -eq 0 ]; then
    pass "$(basename -- "$path"): $N_ROWS row(s), $N_RULED under the anchor rule, none blind"
    return 0
  fi
  return 1
}

# --- selftest ----------------------------------------------------------------------------------
#
# Anti-vacuity for the sensor itself. Nothing outside covers this file: check-mutation.sh only
# sabotages bin/sdd, and run-all.sh skips this sensor under SDD_MUTANT (it reads docs/, which the
# mutation sandbox does not copy). Every probe drives the real --check or --scan path in a CHILD
# PROCESS and asserts its own message, because rc 1 is shared by both violation causes and a probe
# reading the rc alone could not tell a column shift from a blind anchor.
PROBES=0
FAILS=0
SELFTEST_RC=0
PROBE_FLOOR=22

# FAILS is bumped by the assertions themselves, independently of fail_rc, and cross-checked at the
# end. A single rc setter is a single point of failure: neuter it and every failure prints and
# then exits 0.
fail_rc() { [ "$SELFTEST_RC" -eq 0 ] && SELFTEST_RC="$1"; return 0; }

probe() { # probe <desc> <want_rc> <want_text|-> <target> [mode]
  local desc="$1" want_rc="$2" want_txt="$3" target="$4" mode="${5---check}" out rc
  PROBES=$((PROBES + 1))
  out="$( "$SELF_PATH" "$mode" "$target" 2>&1 )"; rc=$?
  if [ "$rc" -ne "$want_rc" ]; then
    printf 'SENSOR-BROKEN: %s — wanted rc %s, got %s\n%s\n' "$desc" "$want_rc" "$rc" "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 90; return 0
  fi
  if [ "$want_txt" != '-' ] && ! grep -qF -- "$want_txt" <<< "$out"; then
    printf 'SENSOR-BROKEN: %s — rc was right but the message never said "%s"\n%s\n' \
      "$desc" "$want_txt" "$out" >&2
    FAILS=$((FAILS + 1)); fail_rc 91; return 0
  fi
  return 0
}

# cp_head <file> <id> <check cell> — a one-row checkpoint fixture.
cp_head() {
  {
    printf '| ID | Incremento | Check (comando → esperado) | Status | Commit |\n'
    printf '|---|---|---|---|---|\n'
  } > "$1"
}

cp_row() { # cp_row <file> <id> <check cell>
  printf '| %s | slice | %s | done | abc1234 |\n' "$2" "$3" >> "$1"
}

# A tree that satisfies every floor, so the probes can degrade ONE thing at a time and read the
# difference. 5 checkpoints, 21 rows, 4 of them under the anchor rule.
build_tree() { # build_tree <root>
  local root="$1" m i f
  mkdir -p "$root/templates" "$root/agents"
  for m in m1 m2 m3 m4; do mkdir -p "$root/docs/handoffs/$m"; done

  f="$root/docs/handoffs/m1/checkpoint.md"; cp_head "$f"
  cp_row "$f" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c '${OK_ANCHOR}alpha holds' <<< \"\$o\"\` → \`1\`"
  cp_row "$f" I2 "\`o=\$(bash tests/check-b.sh 2>&1); grep -c '${OK_ANCHOR}beta holds' <<< \"\$o\"\` → \`1\`"
  cp_row "$f" I3 "\`bash tests/check-c.sh >/dev/null 2>&1; echo \$?\` → \`0\`"
  cp_row "$f" I4 "\`grep -c foo bin/sdd\` → \`0\`"
  cp_row "$f" I5 "\`bash tests/run-all.sh\` → verde"

  f="$root/docs/handoffs/m2/checkpoint.md"; cp_head "$f"
  cp_row "$f" I1 "\`o=\$(bash tests/check-d.sh 2>&1); grep -c '${OK_ANCHOR}gamma holds' <<< \"\$o\"\` → \`1\`"
  for i in 2 3 4 5 6; do cp_row "$f" "I$i" "\`bash tests/run-all.sh\` → verde"; done

  f="$root/docs/handoffs/m3/checkpoint.md"; cp_head "$f"
  cp_row "$f" I1 "\`o=\$(bash tests/check-e.sh 2>&1); grep -c \"${OK_ANCHOR}delta holds\" <<< \"\$o\"\` → \`1\`"
  for i in 2 3 4 5; do cp_row "$f" "I$i" "\`bash tests/run-all.sh\` → verde"; done

  f="$root/docs/handoffs/m4/checkpoint.md"; cp_head "$f"
  for i in 1 2 3 4 5; do cp_row "$f" "I$i" "\`bash tests/run-all.sh\` → verde"; done

  f="$root/templates/checkpoint.md"; cp_head "$f"
  cp_row "$f" I1 '`<comando>` → `<esperado>`'
  printf 'A Check reading a sensor: `o=$(cmd 2>&1); grep -c '"'"'%s<assertion>'"'"' <<< "$o"`\n' \
    "$OK_ANCHOR" >> "$f"

  printf 'A Check reading a sensor merges `2>&1` and anchors on `%s`.\n' \
    "$OK_ANCHOR" > "$root/agents/sdd-planner.md"
}

selftest() {
  local box
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-checkpoint-probe-XXXXXX")" || return 89
  [ -d "$box" ] || return 89

  local blind="$box/blind.md" anchored="$box/anchored.md" nocaret="$box/nocaret.md"
  local thin="$box/thin.md" nogrep="$box/nogrep.md" nomerge="$box/nomerge.md"
  local piped="$box/piped.md" two="$box/two.md" onlyone="$box/onlyone.md"

  cp_head "$anchored"
  cp_row "$anchored" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c '${OK_ANCHOR}alpha holds' <<< \"\$o\"\` → \`1\`"

  cp_head "$blind"
  cp_row "$blind" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c 'alpha holds' <<< \"\$o\"\` → \`1\`"

  cp_head "$nocaret"
  cp_row "$nocaret" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c '  ok    alpha holds' <<< \"\$o\"\` → \`1\`"

  cp_head "$thin"
  cp_row "$thin" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c '^  ok   alpha holds' <<< \"\$o\"\` → \`1\`"

  cp_head "$nogrep"
  cp_row "$nogrep" I1 "\`bash tests/check-a.sh >/dev/null 2>&1; echo \$?\` → \`0\`"

  # Greps, but reads a file the sensor wrote to stdout alone — no FAIL text in the stream. Note
  # the absence of a `|`: the runner's parser would split the cell on it, and the probe would then
  # be measuring rule 1 while claiming to measure rule 2's precondition.
  cp_head "$nomerge"
  cp_row "$nomerge" I1 "\`bash tests/check-a.sh > out.log; grep -c 'alpha holds' out.log\` → \`1\`"

  cp_head "$piped"
  printf '| I1 | slice | `o=$(bash tests/check-a.sh 2>&1); echo "$o" \\| grep -c x` | done | abc1234 |\n' \
    >> "$piped"

  cp_head "$two"
  cp_row "$two" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c '${OK_ANCHOR}alpha' <<< \"\$o\"; grep -c '${OK_ANCHOR}beta' <<< \"\$o\"\` → \`11\`"

  cp_head "$onlyone"
  cp_row "$onlyone" I1 "\`o=\$(bash tests/check-a.sh 2>&1); grep -c '${OK_ANCHOR}alpha' <<< \"\$o\"; grep -c 'beta' <<< \"\$o\"\` → \`11\`"

  # ── the cell rule, one degradation at a time ──
  probe 'an anchored Check passes'            0 '1 under the anchor rule' "$anchored"
  probe 'a bare-text Check is caught'         1 "answers 'the assertion exists'" "$blind"
  probe 'dropping the caret is caught'        1 "answers 'the assertion exists'" "$nocaret"
  probe 'three spaces instead of four is caught' 1 "answers 'the assertion exists'" "$thin"
  probe 'no grep means the rule stays out'    0 '0 under the anchor rule' "$nogrep"
  probe 'no 2>&1 means the rule stays out'    0 '0 under the anchor rule' "$nomerge"
  probe 'a pipe inside the cell is caught'    1 'instead of 5' "$piped"
  probe 'two anchored greps pass'             0 '1 under the anchor rule' "$two"
  probe 'one of two greps unanchored is caught' 1 '1 of 2 pattern(s) anchored' "$onlyone"
  probe 'a checkpoint that does not exist'   94 'not readable' "$box/nowhere.md"

  # ── the floors and the doc assertions, over real trees ──
  local full="$box/full" small="$box/small" fewrows="$box/fewrows" novoid="$box/novoid"
  build_tree "$full"
  probe 'a full clean tree passes' 0 \
    'no checkpoint Check reads a red assertion as green' "$full" --scan

  build_tree "$small"; rm -rf "$small/docs/handoffs/m4"
  probe 'the file floor bites' 93 'the surface shrank to' "$small" --scan

  build_tree "$fewrows"
  local f
  for f in "$fewrows"/docs/handoffs/m*/checkpoint.md; do
    head -n 3 "$f" > "$f.keep"; mv "$f.keep" "$f"
  done
  probe 'the row floor bites' 93 'checkpoint row(s) recognised' "$fewrows" --scan

  build_tree "$novoid"
  for f in "$novoid"/docs/handoffs/m*/checkpoint.md; do
    sed -i 's/2>&1//g' "$f"
  done
  probe 'the vacuity floor bites when no cell is under the rule' 93 \
    'the anchor rule applied to' "$novoid" --scan

  local notmpl="$box/notmpl" noagent="$box/noagent"
  # Only the ANCHOR half is removed — the template keeps its `2>&1` — so the probe isolates the
  # half that matters instead of passing because the whole line went away.
  build_tree "$notmpl"
  cp_head "$notmpl/templates/checkpoint.md"
  cp_row "$notmpl/templates/checkpoint.md" I1 '`<comando>` → `<esperado>`'
  printf 'A Check reading a sensor: `o=$(cmd 2>&1); grep -c <assertion> <<< "$o"`\n' \
    >> "$notmpl/templates/checkpoint.md"
  probe 'a template that forgot the rule is caught' 1 \
    'templates/checkpoint.md never states' "$notmpl" --scan

  build_tree "$noagent"; printf 'nothing here\n' > "$noagent/agents/sdd-planner.md"
  probe 'a planner that forgot the rule is caught' 1 \
    'agents/sdd-planner.md never states' "$noagent" --scan

  # The OTHER half of doc_rule, probed on its own: a doc that shows the anchor but never the
  # `2>&1` that makes it necessary states half a rule, and half a rule is how the next planner
  # writes `grep -c '^  ok  ...'` on a stream that never carried FAIL and calls it a Check.
  local halfdoc="$box/halfdoc"
  build_tree "$halfdoc"
  printf 'Anchor on `%s`.\n' "$OK_ANCHOR" > "$halfdoc/agents/sdd-planner.md"
  probe 'a doc stating the anchor without the merge is caught' 1 \
    'agents/sdd-planner.md never states' "$halfdoc" --scan

  # ── the calibration, over trees of fake sensors ──
  # These probes do NOT derive their `pass()` lines from OK_ANCHOR: that independence is the whole
  # point, and building them from the variable would reproduce the survivor this rule was born to
  # kill.
  local cal="$box/cal" caldis="$box/caldis" calthin="$box/calthin" i
  mkdir -p "$cal/tests" "$caldis/tests" "$calthin/tests"
  for i in 1 2 3 4; do
    printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'" > "$cal/tests/check-$i.sh"
    printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'" > "$caldis/tests/check-$i.sh"
  done
  printf 'pass() { printf %s  ok  %%s\\n%s "$1"; }\n' "'" "'" > "$caldis/tests/check-4.sh"
  for i in 1 2; do
    printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'" > "$calthin/tests/check-$i.sh"
  done
  probe 'the anchor matches what the sensors print' 0 \
    'the prefix the suite' "$cal" --calibrate
  probe 'sensors disagreeing about the prefix is caught' 1 \
    'disagree about the ok prefix' "$caldis" --calibrate
  probe 'calibrating against almost nothing is caught' 1 \
    'calibrated against almost nothing' "$calthin" --calibrate

  # The comparison itself. Without this the other three calibration probes pass with the
  # anchor-versus-house test deleted: they only exercise disagreement and the floor, and the
  # agreeing tree agrees ON the anchor. A tree that agrees on something ELSE is the only fixture
  # that can tell "compared" from "did not compare".
  local calelse="$box/calelse"
  mkdir -p "$calelse/tests"
  for i in 1 2 3 4; do
    printf 'pass() { printf %s  ok  %%s\\n%s "$1"; }\n' "'" "'" > "$calelse/tests/check-$i.sh"
  done
  probe 'a house prefix the anchor does not match is caught' 1 \
    'certifies a prefix nobody writes' "$calelse" --calibrate

  # ── the wiring from scan_file's counters to scan()'s verdict ──
  # Without these two, every cell-rule probe above runs through --check only, and scan() could
  # print its two ok lines unconditionally while the violations went on being counted into
  # nothing. That is exactly the shape this file exists to refuse, and the adversarial pass found
  # it: `if true; then pass ...` survived every other probe.
  local scanblind="$box/scanblind" scanpiped="$box/scanpiped"
  build_tree "$scanblind"
  cp_row "$scanblind/docs/handoffs/m4/checkpoint.md" I9 \
    "\`o=\$(bash tests/check-a.sh 2>&1); grep -c 'omega holds' <<< \"\$o\"\` → \`1\`"
  probe 'a blind cell makes the whole scan red' 1 \
    "answers 'the assertion exists'" "$scanblind" --scan

  build_tree "$scanpiped"
  printf '| I9 | slice | `o=$(bash tests/check-a.sh 2>&1); echo "$o" \\| grep -c x` | done | abc1234 |\n' \
    >> "$scanpiped/docs/handoffs/m4/checkpoint.md"
  probe 'a piped cell makes the whole scan red' 1 \
    'instead of 5' "$scanpiped" --scan

  rm -rf "$box"

  if [ "$PROBES" -lt "$PROBE_FLOOR" ]; then
    printf 'SENSOR-BROKEN: only %d probe(s) ran, expected at least %d — probes were deleted\n' \
      "$PROBES" "$PROBE_FLOOR" >&2
    fail_rc 92
  fi
  if [ "$FAILS" -ne 0 ] && [ "$SELFTEST_RC" -eq 0 ]; then
    printf 'SENSOR-BROKEN: %d probe(s) failed but the rc setter stayed silent\n' "$FAILS" >&2
    SELFTEST_RC=92
  fi
  return "$SELFTEST_RC"
}
# The ONE survivor of the adversarial pass, named rather than hidden, and not reachable in one
# edit: neutering the probe bodies AND lowering PROBE_FLOOR to match. Measured, not assumed —
# each of the three near misses was paired with a real sabotage and died:
#   - probe()'s rc check alone neutered -> the message half still bites (rc 91)
#   - probe()'s message check alone neutered -> the rc half still bites (rc 90)
#   - fail_rc alone neutered -> the FAILS cross-check still bites (rc 92)

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  # `${2-}` and not `${2:-}`: an EMPTY argument is a caller passing an unset variable, and it must
  # not default into a path that answers "ok" about a file nobody named.
  --check)    check_one "${2-}"; exit $? ;;
  --scan)     scan "${2-}"; exit $? ;;
  --calibrate) calibrate "${2-}"; exit $? ;;
  '')         selftest || exit $?
              rc=0
              calibrate "$ROOT" || rc=1
              scan "$ROOT" || rc=$?
              exit "$rc" ;;
  *)          fail "unknown option: $1 (see the usage header)"; exit 96 ;;
esac
