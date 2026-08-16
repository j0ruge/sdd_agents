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
#   4. a `(YYYY-MM-DD)` tail — the found-by field the DOCS phase audits every mission
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
# Usage: tests/check-todo.sh            (exit 0 = the findings file holds its shape)
#        tests/check-todo.sh --selftest (probes: 90/91/92 when the sensor stops measuring)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODO="${SDD_TODO_FILE:-$ROOT/TODO.md}"
CAP="${SDD_TODO_CAP:-8}"

# lint_todo <file> <cap> — prints one line per violation, nothing when the file is clean.
#
# Fenced blocks are skipped, and that is not cosmetic: TODO.md documents its own format inside a
# ```md block whose example line is itself an unchecked item. A naive grep counts that example as
# a malformed item, and the sensor fails on the documentation of the rule it enforces.
lint_todo() {
  awk -v cap="$2" '
    function flush(   n) {
      if (!initem) return
      if (first ~ /^- \[x\]/) {
        print "  line " start ": ticked box — a closed finding is deleted after its PR merges, never [x]"
      } else if (first !~ /^- \[ \] \*\*/) {
        print "  line " start ": item does not open with `- [ ] **<title>**`"
      }
      if (body !~ /`/)
        print "  line " start ": no backticked `file:line` anchor"
      if (body !~ /\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)/)
        print "  line " start ": no (YYYY-MM-DD) found-by tail"
      if (nlines > cap)
        print "  line " start ": " nlines " content lines, cap is " cap
      initem = 0
    }
    /^```/            { flush(); fence = !fence; next }
    fence             { next }
    /^- \[[ x]\] /    { flush(); initem = 1; start = NR; first = $0; body = $0; nlines = 1; next }
    /^#/              { flush(); next }
    initem && NF      { body = body "\n" $0; nlines++ ; next }
    END               { flush() }
  ' "$1"
}

selftest() {
  local box; box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-todo-selftest-XXXXXX")"
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
  # Counting it would make the sensor fail on the documentation of its own rule.
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
  { printf -- '- [ ] **Nine content lines** — `bin/sdd:1` — why it matters here.\n'
    for i in 2 3 4 5 6 7 8; do printf '  filler line %s\n' "$i"; done
    printf '  — found by `x` in mission `m` (2026-08-16)\n'; } > "$box/toolong.md"

  local probe
  for probe in nobold noanchor nodate ticked toolong; do
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

  [ "$rc" -eq 0 ] && printf '  ok    selftest: 7 probe(s), the sensor measures what it claims\n'
  return "$rc"
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit $?; fi

selftest || exit $?

if [ ! -f "$TODO" ]; then
  printf '  FAIL  findings file missing: %s\n' "$TODO" >&2
  exit 93
fi

# Floor, same reason as the surface floor in check-lang.sh and the "exactly 8 gates" floor in
# cmd_health: a parser that stops matching would report "0 violations" — clean by vacuity, which
# is indistinguishable from clean. 46 items today; the floor moves only on purpose.
n_items="$(grep -cE '^- \[[ x]\] ' "$TODO")"
if [ "$n_items" -lt 20 ]; then
  printf '  FAIL  only %d item(s) parsed from %s — did the format change?\n' "$n_items" "$TODO" >&2
  exit 94
fi

violations="$(lint_todo "$TODO" "$CAP")"
if [ -n "$violations" ]; then
  printf '  FAIL  %s does not hold its shape:\n' "$(basename "$TODO")" >&2
  printf '%s\n' "$violations" >&2
  printf '\n%d shape violation(s)\n' "$(grep -c . <<< "$violations")" >&2
  exit 1
fi

printf '  ok    %d finding(s), all within %d lines and carrying anchor + date\n' "$n_items" "$CAP"
exit 0
