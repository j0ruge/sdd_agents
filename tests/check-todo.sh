#!/usr/bin/env bash
# Shape sensor for the kit's findings file (TODO.md).
#
# The file grew to 861 lines because two rules existed only as prose and nobody enforced them:
# a finding fits on a few lines, and a closed finding leaves. Prose alone lost that argument —
# the median item had reached 10 lines and 14 resolved items were still sitting in "Aberto".
#
# What it measures, per top-level item:
#   1. the item opens with `- [ ] **<title>**`
#   2. no ticked box: a closed finding is DELETED after its PR merges, never `- [x]`
#   3. at least one backticked token — the `file:line` anchor that makes a finding actionable
#   4. a `(YYYY-MM-DD)` on the item's LAST content line — the found-by field the DOCS phase
#      audits every mission. Anchoring on the last line rather than anywhere in the body is
#      deliberate: a date buried mid-item is a measurement, not attribution, and the earlier
#      version of this rule accepted exactly that while its message claimed to want the tail.
#   5. at most CAP content lines; the long analysis lives in the handoff the item cites
#
# What it deliberately does NOT measure: whether the prose is any good, or whether the anchor
# still points at real code. Both are human judgement on the diff. This one stops the regression,
# which is the half that rots on its own.
#
# Every rule above is STRUCTURAL — punctuation, backticks, a date — never a Portuguese word.
# That is on purpose and it is the reason this file needs no entry in tests/lang-allowlist.txt
# and no exclusion from check-lang's surface(): TODO.md is content in OUTPUT_LANG, so a sensor
# keyed on the Portuguese words of the found-by field would both break in an English target repo
# and widen the exact coverage hole that TODO.md already records against check-lang's surface().
#
# Usage: tests/check-todo.sh                (selftest, then check TODO.md — what run-all.sh calls)
#        tests/check-todo.sh --selftest     (probes only)
#        tests/check-todo.sh --check <file> (check one file, no selftest — used BY the selftest to
#                                            exercise the real reporting path without recursing)
#
# Exit codes, one per cause — a shared code would leave the reader unable to tell which failure
# happened, which is a defect this repo already tracks against cmd_autonomy:
#    0  clean          1  the file has shape violations
#   89  no temp dir (the probes never ran)   90/91/92  a selftest probe failed
#   93  findings file missing                94  fewer items than the floor
#   95  SDD_TODO_CAP is not an integer       96  unknown option

set -uo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODO="${SDD_TODO_FILE:-$ROOT/TODO.md}"
CAP="${SDD_TODO_CAP:-8}"

# valid_cap <value> — a cap that is not a positive integer would be compared as a STRING by awk
# ("9" > "abc" is false), silently switching the line budget off. A typo in the env var must fail
# loudly instead of quietly disabling the rule it was meant to tune.
valid_cap() { case "${1:-}" in '' | *[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# todo_awk <file> <cap> <lint|count> — ONE parser, two views.
#
# The count shares this parser instead of getting its own `grep -c` for a reason measured on this
# very file: TODO.md documents its own format inside a ```md block whose example line is itself an
# unchecked item, so a grep counts 46 where the parser sees 45. Two mechanisms answering the same
# question is how they drift — the defect this repo has now paid for three times (the two ledger
# readers, the two comparability predicates, and this counter).
todo_awk() {
  awk -v cap="$2" -v mode="$3" '
    function flush() {
      if (!initem) return
      items++
      if (mode == "lint") {
        if (first ~ /^- \[x\]/)
          print "  line " start ": ticked box — a closed finding is deleted after its PR merges, never [x]"
        else if (first !~ /^- \[ \] \*\*/)
          print "  line " start ": item does not open with `- [ ] **<title>**`"
        if (body !~ /`/)
          print "  line " start ": no backticked `file:line` anchor"
        if (last !~ /\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)/)
          print "  line " start ": last line carries no (YYYY-MM-DD) — the found-by field is the tail"
        if (nlines > cap)
          print "  line " start ": " nlines " content lines, cap is " cap
      }
      initem = 0
    }
    /^```/            { flush(); fence = !fence; next }
    fence             { next }
    /^- \[[ x]\] /    { flush(); initem = 1; start = NR; first = $0; body = $0; last = $0; nlines = 1; next }
    /^#/              { flush(); next }
    initem && NF      { body = body "\n" $0; last = $0; nlines++ ; next }
    END               { flush(); if (mode == "count") print items + 0 }
  ' "$1"
}

lint_todo()   { todo_awk "$1" "$2" lint; }
count_items() { todo_awk "$1" 0 count; }

selftest() {
  local box
  # An unchecked mktemp leaves $box empty, and every probe below then writes to /<name>.md —
  # the run would fail as "probe rejected" when the real cause was "no tmpdir".
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-todo-selftest-XXXXXX")" && [ -d "$box" ] || {
    printf '  SELFTEST FAIL  could not create a temp dir — the probes never ran\n' >&2
    return 89
  }
  trap 'rm -rf "$box"' RETURN
  local rc=0

  # A well-formed item must produce nothing. If this probe ever fails, every real run of the
  # sensor is failing for the same reason and the noise would train people to ignore it.
  cat > "$box/good.md" <<'EOF'
## Aberto

- [ ] **A finding with every field in place** — `bin/sdd:42` — why it matters, in one clause.
  Direction: what to do about it. — found by `sdd-qa` in mission `20260816-probe` (2026-08-16)
EOF
  if [ -n "$(lint_todo "$box/good.md" 8)" ]; then
    printf '  SELFTEST FAIL  a well-formed item was reported as a violation\n' >&2
    lint_todo "$box/good.md" 8 >&2
    rc=90
  fi

  # The `- [ ]` inside a fenced block is the format example TODO.md carries in its own header.
  # Counting it would make the sensor fail on the documentation of its own rule — and, before the
  # count moved into this parser, it also inflated the reported total by exactly one.
  cat > "$box/fenced.md" <<'EOF'
Format:

```md
- [ ] <what> — `file:line` — <why> — found by `<agent>` in mission `<slug>` (YYYY-MM-DD)
```

- [ ] **Real item** — `bin/sdd:1` — matters. — found by `humano` (2026-08-16)
EOF
  if [ -n "$(lint_todo "$box/fenced.md" 8)" ]; then
    printf '  SELFTEST FAIL  the format example inside a fenced block was counted as an item\n' >&2
    rc=90
  fi
  if [ "$(count_items "$box/fenced.md")" != "1" ]; then
    printf '  SELFTEST FAIL  the count saw %s item(s) where the parser sees 1 — fenced example counted\n' \
      "$(count_items "$box/fenced.md")" >&2
    rc=90
  fi

  # Each malformed probe has to be REPORTED. A sensor that cannot go red is decoration — the
  # exact failure this file exists to prevent, applied to itself.
  printf -- '- [ ] plain title, no bold — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n' \
    > "$box/nobold.md"
  printf -- '- [ ] **No anchor at all** — why it matters. — found by x (2026-08-16)\n' \
    > "$box/noanchor.md"
  printf -- '- [ ] **No date tail** — `bin/sdd:1` — why it matters. — found by `x`\n' \
    > "$box/nodate.md"
  printf -- '- [x] **Ticked box** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n' \
    > "$box/ticked.md"
  # A date the item MEASURES is not a date that ATTRIBUTES it. The rule anchors on the last
  # content line precisely so this probe fails; keyed on the whole body, it passed.
  { printf -- '- [ ] **Date in the middle** — `bin/sdd:1` — measured on (2026-08-15).\n'
    printf '  A closing line that attributes nothing.\n'; } > "$box/middate.md"
  { printf -- '- [ ] **Nine content lines** — `bin/sdd:1` — why it matters here.\n'
    for i in 2 3 4 5 6 7 8; do printf '  filler line %s\n' "$i"; done
    printf '  — found by `x` in mission `m` (2026-08-16)\n'; } > "$box/toolong.md"

  local probe
  for probe in nobold noanchor nodate ticked middate toolong; do
    if [ -z "$(lint_todo "$box/$probe.md" 8)" ]; then
      printf '  SELFTEST FAIL  probe %s was accepted — the sensor stopped measuring it\n' "$probe" >&2
      rc=91
    fi
  done

  # The cap must be the knob it claims to be: the same 9-line probe passes under a cap of 9.
  # Without this, a hardcoded cap that ignores $CAP would look identical to a working one.
  if [ -n "$(lint_todo "$box/toolong.md" 9 | grep 'content lines')" ]; then
    printf '  SELFTEST FAIL  the cap is not honoured — 9 lines still failed under cap 9\n' >&2
    rc=92
  fi

  # And the guard that keeps the knob a number, since a string cap disables the rule in silence.
  if ! valid_cap 8 || valid_cap abc || valid_cap '' || valid_cap 1x; then
    printf '  SELFTEST FAIL  valid_cap does not separate integers from typos\n' >&2
    rc=92
  fi

  # End-to-end: the number the sensor REPORTS must be the number the parser SEES. Proving
  # count_items() alone is fence-aware is not enough — the defect this closes was the caller
  # reaching for a `grep -c` beside the parser, which no probe on the function could ever notice.
  # Runs through `--check` so the nested invocation exercises the real reporting path without
  # re-entering the selftest.
  { printf 'Format:\n\n```md\n- [ ] <what> — `f:1` — <why> — by `<a>` (YYYY-MM-DD)\n```\n\n'
    for i in $(seq 1 21); do
      printf -- '- [ ] **Item %s** — `bin/sdd:%s` — why it matters. — found by `x` (2026-08-16)\n' "$i" "$i"
    done; } > "$box/counted.md"
  local reported
  reported="$("$SELF" --check "$box/counted.md" 2>&1 | grep -oE '[0-9]+ finding' | grep -oE '[0-9]+')"
  if [ "$reported" != "21" ]; then
    printf '  SELFTEST FAIL  the sensor reports %s finding(s) where the parser sees 21 — the count\n' \
      "${reported:-<none>}" >&2
    printf '                 is not coming from the parser (a fenced example is being counted)\n' >&2
    rc=92
  fi

  [ "$rc" -eq 0 ] && printf '  ok    selftest: 14 probe(s), the sensor measures what it claims\n'
  return "$rc"
}

# check_file <file> <cap> — the real check. Kept out of the top-level flow so the selftest can
# invoke it through `--check` without recursing into itself.
check_file() {
  local file="$1" cap="$2" n_items violations

  if [ ! -f "$file" ]; then
    printf '  FAIL  findings file missing: %s\n' "$file" >&2
    return 93
  fi

  # Floor on the PARSER's own count, not on a grep beside it — otherwise a parser that stopped
  # matching would report "0 violations" while the floor, counting by another mechanism, still
  # looked satisfied. The selftest is the primary defence against that (sabotage the item pattern
  # and the 91 probes fire); this floor is the second one, and it covers what the selftest cannot
  # see: the parser is fine but the FILE lost its items. 45 today; it moves only on purpose.
  n_items="$(count_items "$file")"
  if [ "$n_items" -lt 20 ]; then
    printf '  FAIL  only %d item(s) parsed from %s — did the format change?\n' "$n_items" "$file" >&2
    return 94
  fi

  violations="$(lint_todo "$file" "$cap")"
  if [ -n "$violations" ]; then
    printf '  FAIL  %s does not hold its shape:\n' "$(basename "$file")" >&2
    printf '%s\n' "$violations" >&2
    printf '\n%d shape violation(s)\n' "$(grep -c . <<< "$violations")" >&2
    return 1
  fi

  printf '  ok    %d finding(s), all within %d lines and carrying anchor + date\n' "$n_items" "$cap"
  return 0
}

if ! valid_cap "$CAP"; then
  printf '  FAIL  SDD_TODO_CAP must be a positive integer, got: %s\n' "$CAP" >&2
  exit 95
fi

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  --check)    check_file "${2:-$TODO}" "$CAP"; exit $? ;;
  '')         selftest || exit $?; check_file "$TODO" "$CAP"; exit $? ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
