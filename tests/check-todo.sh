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
#   3. a non-empty backticked token BEFORE the last ` — ` separator — the `file:line` anchor.
#      Position matters: every well-formed item ends with "found by `<agent>`", so "a backtick
#      somewhere" is satisfied by the attribution alone and an anchorless wish would pass.
#   4. a `(YYYY-MM-DD)` on the item's LAST content line — the found-by field the DOCS phase
#      audits every mission. Anchoring on the last line rather than anywhere in the body is
#      deliberate: a date buried mid-item is a measurement, not attribution.
#   5. at most CAP content lines; the long analysis lives in the handoff the item cites
#
# What it deliberately does NOT measure: whether the prose is any good, or whether the anchor
# still points at real code. Both are human judgement on the diff. This one stops the regression,
# which is the half that rots on its own.
#
# And what it deliberately REFUSES in the findings section: fenced blocks, bare list markers,
# lazy column-0 continuations, and every task-item shape that is not `- [ ] **<title>**` at
# column 0. (Indented code blocks are NOT detected — an earlier version of this line claimed they
# were. Inside an item they are absorbed as content; the ~6-line cap is what bounds them.)
# That is stricter than CommonMark on purpose. Six adversarial rounds proved that a sensor which
# tries to decide what is code and what is a finding will get it wrong in a new way every time —
# every fail-open this file ever had lived in that decision. Forbidding the construct is one rule
# that cannot desync, and it costs nothing real: no finding carries a code block, and the ~6-line
# budget leaves no room for one. A sensor should refuse what it cannot safely parse, not guess.
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
# ── Known limits, stated so nobody re-discovers them as surprises ──────────────────────────────
# The selftest is this file's own harness, and a harness cannot fully test itself. Three one-line
# edits make every failure green: `return "$SELFTEST_RC"` -> `return 0`, dropping the `|| exit $?`
# from the default dispatch, and neutering an assertion body. That is not a hole this file can
# plug from the inside, and NOTHING OUTSIDE COVERS IT EITHER: `tests/check-mutation.sh` catalogues
# sabotages of `bin/sdd` only, and `tests/run-all.sh` skips this sensor under `SDD_MUTANT`. An
# earlier version of this comment claimed that catalogue as a safety net; it is not one, and
# saying so was the same label-instead-of-artifact failure the kit forbids everywhere else.
# What the selftest DOES defend is the rules that carry a probe — most of them, not all. Each
# probe asserts its own message; there is a floor on the probe count and a FAILS counter
# independent of `fail_rc`. Rules known to be unprobed are listed in TODO.md, not papered over.
#
# Not measured, on purpose: whether an anchor still points at real code, whether the prose is any
# good, and whether a finding is worth keeping. All three are human judgement on the diff.
#
# Two measured weaknesses, stated rather than hidden. Rule 3 asks for a backticked token before
# the last separator, so an item whose TITLE carries inline code satisfies it without an anchor —
# 45 of the 46 findings would still pass with their `file:line` deleted. Tightening it needs a
# shape test the real data will not support (`git worktree` and `KAIZEN_LOG` are legitimate
# anchors). And rule 4 splits on the last ` — `, so an em-dash inside the attribution backticks
# misreports. Both are in TODO.md; neither can hide a closed finding, which is what rules 2 and
# the whitelist are for.
#
# Exit codes, one per cause, FIRST failure wins — a shared or last-write-wins code would leave
# the reader unable to tell which failure happened:
#    0  clean          1  the file has shape violations
#   89  no temp dir (the probes never ran)   90/91/92  a selftest probe failed
#   93  findings file missing or unreadable  94  fewer items than the floor
#   95  SDD_TODO_CAP is not a positive integer   96  unknown option

set -uo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODO="${SDD_TODO_FILE:-$ROOT/TODO.md}"
CAP="${SDD_TODO_CAP:-8}"

# valid_cap <value> — a cap that is not a positive integer would be compared as a STRING by awk
# ("9" > "abc" is false), silently switching the line budget off. Zero is rejected too: it is a
# number, but it would fail every item and the error text promises "positive".
valid_cap() {
  case "${1:-}" in
    '' | *[!0-9]*) return 1 ;;
    *) [ "$1" -gt 0 ] 2>/dev/null || return 1 ;;
  esac
}

# todo_awk <file> <cap> <lint|count> — ONE parser, two views.
#
# The count shares this parser instead of getting its own `grep -c`: TODO.md documents its own
# format inside a ```md block whose example line is itself an unchecked item, so a grep counts one
# more than the parser sees. Two mechanisms answering the same question is how they drift.
#
# ── Why there is no fence tracking here ────────────────────────────────────────────────────────
# Six adversarial rounds, and every single fail-open lived in the fence logic: a one-way latch, a
# four-backtick block closing on an inner marker, an inline code span opening a phantom block, a
# closer carrying an info string, a 4-space indent that CommonMark calls a code block. The cause
# was never any of those — it was that this file had drifted into writing a CommonMark parser in
# awk, and markdown is genuinely hard.
#
# So it stopped. The findings section of TODO.md contains NO fenced block — the only one is the
# format example in the header — so the parser skips the header wholesale and forbids fences
# after it. Nothing to desync, and every shape that used to hide behind a fence is now judged by
# a rule that never looks at fences at all.
todo_awk() {
  local from f="$1"
  # A bare path shaped like `name=value` is eaten by awk as a variable ASSIGNMENT, and awk then
  # reads stdin instead of the file — the sensor would happily lint whatever it was handed and
  # report "ok". mawk has no `--` for operands, so the fix is to make the path un-assignable.
  # `name=value` is a variable ASSIGNMENT to awk and `-` is stdin to both grep and awk; either way
  # the file is never opened and the sensor reports about something else entirely.
  case "$f" in [A-Za-z_]*=* | -) f="./$f" ;; esac
  # The heading is located here rather than in awk because awk cannot look ahead, and starting
  # from "the findings begin" is what lets the header keep its example fence without the parser
  # having to understand fences. Absent (a probe fixture), the whole file is the findings section.
  from="$(grep -n '^## Aberto' "$f" 2>/dev/null | head -1 | cut -d: -f1)"
  # Parity of the header fence lines, counted rather than tracked. Backticks and tildes are
  # counted apart so a mixed pair cannot cancel out.
  local hb ht hodd
  hb="$(head -n "${from:-0}" "$f" 2>/dev/null | grep -cE '^ {0,3}```' || true)"
  ht="$(head -n "${from:-0}" "$f" 2>/dev/null | grep -cE '^ {0,3}~~~' || true)"
  hodd=$(( (hb % 2) + (ht % 2) ))
  awk -v cap="$2" -v mode="$3" -v from="${from:-0}" -v hodd="$hodd" '
    # Byte offset of the last " — " separator, 0 when there is none.
    # ⚠️ index()/substr(), never a regex with a negated em-dash class. The awk this repo runs is
    # mawk, BYTE-oriented whatever the locale: `[^—]` is the negated byte set {0xE2,0x80,0x94},
    # so any character from U+2000..U+2FFF in the tail — every curly quote, ellipsis, en-dash,
    # bullet and arrow — broke the match and the anchor rule failed OPEN on ordinary punctuation.
    function last_sep(text,   sep, i, p, last) {
      sep = " — "; last = 0; i = 1
      while ((p = index(substr(text, i), sep)) > 0) { last = i + p - 1; i = last + length(sep) }
      return last
    }
    # The anchor lives BEFORE the last separator, the agent name AFTER it. Position, not presence:
    # every well-formed item ends with "found by `<agent>`", so "a backtick somewhere" is satisfied
    # by the attribution alone and an anchorless wish would sail through. Checking both ends also
    # catches the item whose last field is not the attribution at all.
    function head_of(text,   last) { last = last_sep(text); return last == 0 ? "" : substr(text, 1, last - 1) }
    function tail_of(text,   last) { last = last_sep(text); return last == 0 ? "" : substr(text, last + length(" — ")) }
    function flush() {
      if (!initem) return
      items++
      if (mode == "lint") {
        if (first !~ /^- \[ \] \*\*/)
          print "  line " start ": item does not open with `- [ ] **<title>**`"
        if (head_of(body) !~ /`[^`]+`/)
          print "  line " start ": no non-empty `file:line` anchor before the found-by tail"
        else if (tail_of(body) !~ /`[^`]+`/)
          print "  line " start ": the last field names no `<agent>` — the found-by must be the tail"
        if (last !~ /\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)/)
          print "  line " start ": last line carries no (YYYY-MM-DD) — the found-by field is the tail"
        if (nlines > cap)
          print "  line " start ": " nlines " content lines, cap is " cap
      }
      initem = 0
    }
    { sub(/\r$/, "") }        # CRLF: a trailing \r used to defeat the end-of-line alternations
    # ── The ticked-box rule runs over the WHOLE file, header included ──────────────────────────
    # It is the one rule that must not respect any skip. "The header" is not a fixed preamble — it
    # is everything above a heading an editor can move, so a section of archived findings parked
    # above `## Aberto` switched this rule off and the file passed green. A ticked box is never
    # legitimate anywhere here: the format example in the header uses `- [ ]`.
    /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]+\[[xX]\]([ \t]|$)/ {
      if (mode == "lint")
        print "  line " NR ": ticked box — a closed finding is deleted after its PR merges, never [x]"
      flush(); next
    }
    # ── Header: no fence toggle, because every fence toggle this file ever had desynced ────────
    # The last one lived here, bounded to the header, and it still failed silent: one stray ``` in
    # the header made the ENTIRE findings section render as a code block on GitHub while the run
    # reported "ok 48 finding(s)". Its intended guard was unreachable dead code, so the comment
    # promising "a loud complaint, never silence" was false in both halves.
    #
    # What replaced it cannot desync because it holds no state: `hodd` is a PARITY COUNT of the
    # header fence lines, computed once outside awk. Odd means the findings section is inside a
    # code block, which is the only thing about the header that can hurt the reader.
    # The format example is recognised by CONTENT — an item whose text opens with a `<`
    # placeholder is a template, and no real finding does — so it needs no fence to be skipped.
    NR == 1 && hodd           { if (mode == "lint") print "  line 1: the header fences are unbalanced — the findings section renders as code" }
    NR <= from && /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]+\[ \]/ {
      if ($0 !~ /^- \[ \] </ && mode == "lint")
        print "  line " NR ": a finding above the findings section"
      next
    }
    NR <= from                { next }
    # ── Findings section: a WHITELIST. Item, indented continuation, heading, block quote, blank ─
    # Everything else at column 0 is refused. Seven rounds of fail-open came from trying to decide
    # what an unfamiliar construct MEANT; this decides only whether it belongs, which is a question
    # with a short and stable answer. It also closes what the cap could not: a body written at
    # column 0 is not item content in markdown, so 90 lines of de-indented prose used to report
    # "all within 8 lines" — the very regression this sensor exists to stop, passing green.
    /^[ \t>]*(```|~~~)/ {
      if (mode == "lint") print "  line " NR ": a fenced block in the findings section"
      flush(); next
    }
    # A list marker alone on its line, with the box on the NEXT line, is one rendered task item —
    # GitHub ticks it — and no per-line rule can see the pair. Refused instead of parsed.
    /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]*$/ {
      if (mode == "lint") print "  line " NR ": a bare list marker — a finding is one line-start"
      flush(); next
    }
    /^- \[ \]/ {
      flush(); initem = 1; start = NR
      first = $0; body = $0; last = $0; nlines = 1; next
    }
    # Every OTHER shape GitHub renders as an unchecked task item. The ticked rule was wide and this
    # one was `^[-*+] \[ \]` — column 0, one space — so the same line was "a closed finding" when
    # ticked and nothing at all when open: 195 of 270 open shapes skipped every rule and the count.
    /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]+\[ \]/ {
      if (mode == "lint")
        print "  line " NR ": a finding must open with `- [ ] **<title>**` at column 0"
      flush(); next
    }
    initem && NF && /^[ \t]/  { body = body " " $0; last = $0; nlines++; next }
    # Refused like everything else off the whitelist, but named for what it is: calling an
    # indented line "prose at column 0" sends the reader to look for something that is not there.
    NF && /^[ \t]/ {
      if (mode == "lint") print "  line " NR ": an indented line that belongs to no finding"
      next
    }
    /^#/                      { flush(); next }
    /^>/                      { flush(); next }
    NF {
      if (mode == "lint") print "  line " NR ": prose at column 0 in the findings section"
      flush(); next
    }
    END { flush(); if (mode == "count") print items + 0 }
  ' "$f"
}

lint_todo()   { todo_awk "$1" "$2" lint; }
count_items() { todo_awk "$1" 1 count; }

# --- selftest ---------------------------------------------------------------------------------
# Probes are COUNTED, never hand-written into the summary: the previous version carried "14
# probe(s)" as prose, which had already drifted from the real number by the time it was read.
PROBES=0
PROBES_SKIPPED=0
FAILS=0
SELFTEST_RC=0

# FAILS is bumped by the assertions THEMSELVES, independently of fail_rc, and cross-checked at the
# end by direct assignment. fail_rc was a single point of failure: neutering it to `return 0` let
# the selftest print six failures and then "the sensor measures what it claims", exit 0, and take
# the whole suite green with it — run-all.sh reads the exit status, not the text.
fail_rc() { [ "$SELFTEST_RC" -eq 0 ] && SELFTEST_RC="$1"; return 0; }

assert_clean() { # <file> <cap> <label>
  PROBES=$((PROBES + 1))
  local out; out="$(lint_todo "$1" "$2")"
  [ -z "$out" ] && return 0
  printf '  SELFTEST FAIL  %s — expected no violation, got:\n%s\n' "$3" "$out" >&2
  FAILS=$((FAILS + 1)); fail_rc 90
}

# Asserts the SPECIFIC message, not merely "something was printed". Six probes used to assert
# only non-emptiness, so a rule could be silently answered by a neighbour's message — killing the
# ticked-box branch left the probe green while the operator was told the title was malformed.
assert_says() { # <file> <cap> <substring> <label>
  PROBES=$((PROBES + 1))
  local out; out="$(lint_todo "$1" "$2")"
  case "$out" in *"$3"*) return 0 ;; esac
  printf '  SELFTEST FAIL  %s — expected a violation saying "%s", got: %s\n' \
    "$4" "$3" "${out:-<nothing>}" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# assert_rc <expected> <label> <args...> — for the exit paths. Defined at file scope beside the
# other assertions: it lived inside selftest() and every call above its definition died with
# "command not found", which bash reports on stderr while the run carries on.
assert_rc() {
  PROBES=$((PROBES + 1))
  local want="$1" label="$2"; shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  [ "$got" -eq "$want" ] && return 0
  printf '  SELFTEST FAIL  %s — expected rc %s, got %s\n' "$label" "$want" "$got" >&2
  FAILS=$((FAILS + 1)); fail_rc 92
}

selftest() {
  local box
  # An unchecked mktemp leaves $box empty, and every probe below then writes to /<name>.md —
  # the run would fail as "probe rejected" when the real cause was "no tmpdir".
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-todo-selftest-XXXXXX")"
  if [ -z "$box" ] || [ ! -d "$box" ]; then
    printf '  SELFTEST FAIL  could not create a temp dir — the probes never ran\n' >&2
    return 89
  fi
  trap 'rm -rf "$box"' RETURN
  # --- shapes that must pass ---
  cat > "$box/good.md" <<'EOF'
## Aberto

- [ ] **A finding with every field in place** — `bin/sdd:42` — why it matters, in one clause.
  Direction: what to do about it. — found by `sdd-qa` in mission `20260816-probe` (2026-08-16)
EOF
  assert_clean "$box/good.md" 8 "a well-formed item"

  cat > "$box/fenced.md" <<'EOF'
Format:

```md
- [ ] <what> — `file:line` — <why> — found by `<agent>` in mission `<slug>` (YYYY-MM-DD)
```

## Aberto

- [ ] **Real item** — `bin/sdd:1` — matters. — found by `humano` (2026-08-16)
EOF
  assert_clean "$box/fenced.md" 8 "the format example inside a fenced block"

  # The footnote's INDENTED second line is what makes this probe discriminate: without the
  # column-0 terminator the item stays open across the blank line, absorbs that line, and the date
  # rule blames the finding above. A one-line footnote proves nothing — column-0 lines are never
  # absorbed anyway — and the earlier version of this probe was exactly that, so the rule it was
  # meant to guard could be deleted with the selftest still green.
  { cat "$box/good.md"
    printf '\nA closing note that belongs to the file, not to any item.\n'
    printf '  and its indented continuation, which is part of no finding.\n'; } \
    > "$box/footnote.md"
  assert_says "$box/footnote.md" 8 'prose at column 0' "a column-0 footnote after the last item"

  # --- the item code block: seven probes for the state the parser lacked until round 4 ---
  #
  # ── Fences in the findings section: ONE rule, and the probes that killed a dozen ─────────────
  # Six rounds of fail-open lived in fence tracking. There is none now: the header (everything up
  # to `## Aberto`) is skipped wholesale, and after it any fence at all is a violation. These
  # probes are the shapes that each used to be its own bypass — a four-backtick block quoting a
  # three-backtick one, a backtick fence "closed" by a tilde, an inline span mistaken for an
  # opener, a fence indented past CommonMark's limit, a closer carrying an info string, and a
  # fence that never closes. Every one of them is now the same single answer.
  local shape
  for shape in '```sh' '````md' '~~~md' '   ```' '```code``` inline' '```x'; do
    { printf '## Aberto\n\n'
      printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n\n'
      printf '%s\n' "$shape"
      printf -- '- [x] **a closed finding that used to hide below this**\n'; } > "$box/fence.md"
    assert_says "$box/fence.md" 8 'fenced block in the findings section' "a fence shaped $shape"
    assert_says "$box/fence.md" 8 'ticked box' "the ticked box below a fence shaped $shape"
  done

  # An item may not carry one either, and the box below it stays visible — the shape that exited 0
  # through four different generations of fence tracking.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **T** — `f:1` — why. — found by `x` (2026-08-16)\n'
    printf '  ```\n'
    printf -- '- [x] **A CLOSED FINDING that GitHub renders ticked**\n'
    printf '  ```\n'; } > "$box/boxinfence.md"
  assert_says "$box/boxinfence.md" 8 'ticked box' "a column-0 ticked box between an item fence pair"
  assert_rc 1 "a ticked box between an item fence pair must fail the file" \
    bash "$SELF" --check "$box/boxinfence.md"

  # Every shape GitHub renders as a checked box, and each one used to be its own bypass: the three
  # bullet characters, both ordered delimiters, a tab or a run of spaces as the gap, any indent,
  # inside a block quote, uppercase, a bare box, and one ending in CRLF. A per-line rule is what
  # finally covered them; per-item checking never could.
  { printf -- '+ [x] **closed, plus bullet**\n'
    printf -- '1. [x] **closed, ordered with a dot**\n'
    printf -- '1) [x] **closed, ordered with a paren**\n'
    printf -- '   - [x] **closed, indented three spaces**\n'
    printf -- '- [X] **closed, uppercase**\n'
    printf -- '-  [x] **closed, two spaces before the box**\n'
    printf -- '-\t[x] **closed, tab before the box**\n'
    printf -- '> - [x] **closed, inside a block quote**\n'
    printf -- '* [x]\n'
    printf -- '- [x]\r\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } \
    > "$box/allboxes.md"
  PROBES=$((PROBES + 1))
  if [ "$(lint_todo "$box/allboxes.md" 8 | grep -c 'ticked box')" != "10" ]; then
    printf '  SELFTEST FAIL  the ten ticked-box shapes are not all reported: %s\n' \
      "$(lint_todo "$box/allboxes.md" 8 | grep -c 'ticked box')" >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  fi

  # The leading `^` is what keeps an inline `- [x]` inside an item's prose from being read as a
  # closed finding, and the trailing `([ \t]|$)` is what keeps a `[x](link)` from matching. Both
  # were unprobed, and dropping either one is invisible without these two.
  printf -- '- [ ] **A** — `bin/sdd:1` — it keys on - [x] markers. — found by `x` (2026-08-16)\n' \
    > "$box/inlinebox.md"
  assert_clean "$box/inlinebox.md" 8 "an inline - [x] inside item prose"
  { printf -- '- [x](https://example.com/spec) see the linked spec\n\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } > "$box/link.md"
  assert_says "$box/link.md" 8 'prose at column 0' "a markdown link whose text is x"

  # A ticked box ABOVE `## Aberto`. The header skip exists to spare the format example, and it
  # made the file's most important rule depend on where an editor puts a heading: a section of
  # archived findings parked above it switched rule 2 off entirely, with the run green.
  { printf '## Resolvido\n'
    printf -- '- [x] **closed A** — `f:1` — w. — by `x` (2026-08-16)\n'
    printf -- '- [x] **closed B**\n\n## Aberto\n\n'
    printf -- '- [ ] **Open** — `bin/sdd:42` — w. — by `x` (2026-08-16)\n'; } > "$box/archived.md"
  assert_says "$box/archived.md" 8 'ticked box' "a ticked box in a section above ## Aberto"

  # And an ITEM above the heading. Round 7 moved only the ticked rule out of the header skip, so
  # seven other rules and the count still went blind to anything an editor parked above it: the
  # same anchorless, dateless, 41-line finding was four violations below the heading and silence
  # above it, with the reported count short by one.
  { printf '## Triagem\n'
    printf -- '- [ ] a wish with no title, no anchor and no date\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/aboveitem.md"
  assert_says "$box/aboveitem.md" 8 'above the findings section' "an item parked above ## Aberto"

  # ...and the format example, which IS an item-shaped line in the header, must NOT be. It is
  # recognised by content — a `<placeholder>` where a title belongs — because recognising it by
  # fence needed a toggle, and every fence toggle this file ever had desynced.
  { printf 'Format:\n\n```md\n'
    printf -- '- [ ] <what> — `file:line` — <why> — by `<agent>` (YYYY-MM-DD)\n'
    printf '```\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/template.md"
  assert_clean "$box/template.md" 8 "the format example in the header"

  # One stray fence in the header renders the ENTIRE findings section as a code block on GitHub.
  # The toggle that used to guard this reported "ok" on the real file; a parity count cannot.
  { printf 'Format:\n\n```md\n'
    printf -- '- [ ] <what> — `file:line` — <why> — by `<agent>` (YYYY-MM-DD)\n'
    printf '```\n```\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/unbalanced.md"
  assert_says "$box/unbalanced.md" 8 'unbalanced' "an odd number of header fences"
  # Tildes are counted apart from backticks: a mixed pair must not cancel out into "balanced".
  { printf 'Format:\n\n~~~md\n'
    printf -- '- [ ] <what> — `file:line` — <why> — by `<agent>` (YYYY-MM-DD)\n'
    printf '~~~\n~~~\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/unbalanced2.md"
  assert_says "$box/unbalanced2.md" 8 'unbalanced' "an odd number of header tilde fences"

  # An indented line with no finding open is refused like everything off the whitelist, but it is
  # named for what it is: calling it "prose at column 0" sends the reader to the wrong place.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n\n## Section\n  an orphan indented line\n'; } \
    > "$box/orphanindent.md"
  assert_says "$box/orphanindent.md" 8 'belongs to no finding' "an indented line outside any item"

  # Free prose at column 0 is refused, and that is what bounds a body written WITHOUT indentation.
  # Markdown says those paragraphs are not item content, so the cap never saw them: three findings
  # trailed by 30 de-indented lines each reported "all within 8 lines" — 101 lines passing green,
  # the exact regression this sensor exists to stop.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **I** — `f:1` — w. — by `x` (2026-08-16)\n\n'
    printf 'a de-indented paragraph that markdown does not fold into the item\n'; } \
    > "$box/deindented.md"
  assert_says "$box/deindented.md" 8 'prose at column 0' "a de-indented body paragraph"

  # CommonMark ends a paragraph at a heading, a thematic break, a block quote, an HTML block and a
  # list start. An earlier rule called all five "a lazy continuation" and named the wrong line, so
  # deleting one blank line before a `###` section heading turned the suite red on a good file.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'
    printf '## A heading right after it\n'; } > "$box/interrupt.md"
  assert_clean "$box/interrupt.md" 8 "a heading interrupting an item with no blank line"

  # The section header of the real file is a 14-line block quote, so `>` has to be on the
  # whitelist — without it the whole preamble reads as prose at column 0 and every run fails.
  { printf '## Aberto\n\n> The lifecycle rule, stated where the findings live.\n'
    printf '> Second line of it.\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/quoted.md"
  assert_clean "$box/quoted.md" 8 "a block quote in the findings section"

  # The bare-marker rule tolerates the trailing space editors actually leave behind.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n\n- \n  [x] **closed**\n'; } \
    > "$box/markerspace.md"
  assert_says "$box/markerspace.md" 8 'bare list marker' "a bare marker with a trailing space"

  # A list marker alone on its line with the box below it is one rendered, ticked item that no
  # per-line rule can see. Refused rather than parsed.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n\n-\n  [x] **closed, split marker**\n'; } \
    > "$box/splitmarker.md"
  assert_says "$box/splitmarker.md" 8 'bare list marker' "a list marker with its box on the next line"

  # The open shapes. The ticked rule was wide and the item-start rule was narrow, so the same line
  # was "a closed finding" when ticked and nothing at all when open.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'
    printf -- '1. [ ] a vague wish\n-  [ ] another, two spaces\n> - [ ] one in a quote\n'; } \
    > "$box/openshapes.md"
  PROBES=$((PROBES + 1))
  if [ "$(lint_todo "$box/openshapes.md" 8 | grep -c 'must open with')" != "3" ]; then
    printf '  SELFTEST FAIL  the three off-pattern open shapes are not all reported: %s\n' \
      "$(lint_todo "$box/openshapes.md" 8 | grep -c 'must open with')" >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  fi

  # A lazy continuation folds into the item in markdown and used to count as zero lines, so a
  # 41-line finding written that way reported "within 8 lines".
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'
    printf 'a lazy continuation at column 0\n'; } > "$box/lazy.md"
  assert_says "$box/lazy.md" 8 'prose at column 0' "a column-0 continuation with no blank line"

  # And the legitimate shape it must not be confused with: a footnote AFTER a blank line.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n\n'
    printf 'A closing note.\n  and its indented continuation.\n'; } > "$box/footnote2.md"
  assert_says "$box/footnote2.md" 8 'prose at column 0' "a column-0 footnote after a blank line"

  assert_rc 93 "--check with an empty argument must not fall back to TODO.md" \
    bash "$SELF" --check ''

  # `+8` passes bash's `[ -gt 0 ]` but explodes in `$((10#+8))`; `08` passes both and then dies in
  # `printf %d` as an invalid octal, announcing a cap it never enforced. The digit class and the
  # base-10 normalisation are each the only thing standing between those and a broken run.
  PROBES=$((PROBES + 1))
  if valid_cap '+8' || valid_cap '8 ' || valid_cap ' 8'; then
    printf '  SELFTEST FAIL  valid_cap accepts a signed or space-padded value\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi
  PROBES=$((PROBES + 1))
  if [ "$(SDD_TODO_CAP=08 bash "$SELF" --check "$box/good.md" 2>&1 | grep -oE 'within [0-9]+ lines')" \
       != "within 8 lines" ]; then
    printf '  SELFTEST FAIL  a leading-zero cap is not normalised to base 10\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # A file literally named `-` is stdin to both grep and awk: the file is never opened and the
  # sensor reports about whatever it was handed.
  PROBES=$((PROBES + 1))
  printf -- '- [x] **closed**\n' > "$box/-"
  printf -- '- [ ] **A** — `f:1` — w. — by `x` (2026-08-16)\n' > "$box/innocent.md"
  ( cd "$box" && bash "$SELF" --check - < innocent.md >/dev/null 2>&1 )
  if [ "$?" -ne 1 ]; then
    printf '  SELFTEST FAIL  a file named - was read from stdin instead of opened\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # Which message an off-pattern bullet gets is a decision, so it is asserted: `* [ ] **T**` is
  # not an item that opens badly, it is a line that is not a finding opener at all.
  printf -- '* [ ] **A title with the wrong bullet** — `f:1` — w. — by `x` (2026-08-16)\n' \
    > "$box/starbullet.md"
  assert_says "$box/starbullet.md" 8 'must open with' "an item opened with a * bullet"

  # A path shaped like `name=value` is a variable ASSIGNMENT to awk, which then reads stdin — the
  # sensor would lint whatever it was handed and report "ok" about a file it never opened.
  PROBES=$((PROBES + 1))
  printf -- '- [x] **closed**\n' > "$box/weird=path.md"
  printf -- '- [ ] **A** — `f:1` — w. — by `x` (2026-08-16)\n' > "$box/innocent.md"
  ( cd "$box" && bash "$SELF" --check 'weird=path.md' < innocent.md >/dev/null 2>&1 )
  if [ "$?" -ne 1 ]; then
    printf '  SELFTEST FAIL  an awk-assignment-shaped path was read from stdin, not from the file\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # The date rule is anchored to the LAST content line, and nothing proved it: a date in the title
  # with none in the tail used to be the difference between this rule and "a date anywhere".
  { printf -- '- [ ] **Dated title (2026-08-16)** — `bin/sdd:1` — why it matters.\n'
    printf '  A closing line with no attribution at all.\n'; } > "$box/titledate.md"
  assert_says "$box/titledate.md" 8 'no (YYYY-MM-DD)' "a date in the title but not in the tail"

  # The line number in every message comes from `start`; zeroing it left every probe green because
  # no assertion ever read one.
  { printf 'Filler prose.\n\n'
    printf -- '- [ ] **No date here** — `bin/sdd:1` — why it matters. — by `x`\n'; } > "$box/lineno.md"
  assert_says "$box/lineno.md" 8 'line 3:' "the reported line number points at the item"

  PROBES=$((PROBES + 1))
  if [ "$(count_items "$box/fenced.md")" != "1" ]; then
    printf '  SELFTEST FAIL  the count saw %s item(s) where the parser sees 1\n' \
      "$(count_items "$box/fenced.md")" >&2
    FAILS=$((FAILS + 1)); fail_rc 90
  fi

  # --- shapes that must fail, each by its OWN message ---
  printf -- '- [ ] plain title, no bold — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n' \
    > "$box/nobold.md"
  assert_says "$box/nobold.md" 8 'does not open with' "no bold title"

  # Bold LATER on the line is not a title. Without this probe the rule degrades to "has ** on the
  # first line" and both the selftest and the real file stay green.
  printf -- '- [ ] no title, just prose with some **bold** later — `bin/sdd:1` — why. — by `x` (2026-08-16)\n' \
    > "$box/latebold.md"
  assert_says "$box/latebold.md" 8 'does not open with' "bold not at the opening"

  printf -- '- [ ] **No anchor at all** — a vague wish. — found by `sdd-qa` in mission `m` (2026-08-16)\n' \
    > "$box/noanchor.md"
  assert_says "$box/noanchor.md" 8 'anchor before the found-by tail' "attribution backticks only"

  printf -- '- [ ] **Empty anchor** — `` — why. — found by `sdd-qa` in mission `m` (2026-08-16)\n' \
    > "$box/emptyanchor.md"
  assert_says "$box/emptyanchor.md" 8 'anchor before the found-by tail' "an empty backtick pair"

  # The tail carries a curly quote. Under mawk — the awk this repo actually runs — a regex with a
  # negated em-dash class is a negated BYTE class, so every character encoded with 0xE2 (’ “ ” …
  # – • → ★) broke the split and the rule degraded to "a backtick anywhere". Failing open on
  # ordinary punctuation, and invisible without this probe.
  # \u2019 written as an escape, not pasted: the character IS the trigger, so spelling it out
  # keeps the probe honest about what it exercises (and keeps shellcheck's SC1112 quiet).
  printf -- '- [ ] **No anchor, curly quote in tail** — a wish. — found by `sdd-qa` in the team\u2019s mission (2026-08-16)\n' \
    > "$box/utf8tail.md"
  assert_says "$box/utf8tail.md" 8 'anchor before the found-by tail' "a curly quote in the found-by tail"

  # No separator at all means no region an anchor could live in; the attribution alone must not
  # satisfy the rule.
  printf -- '- [ ] **A vague wish** with no separator whatsoever, found by `sdd-qa` (2026-08-16)\n' \
    > "$box/nosep.md"
  assert_says "$box/nosep.md" 8 'anchor before the found-by tail' 'an item with no em-dash separator'

  # The head rule alone could not see this: a stray field after the attribution pushes the agent
  # name INTO the head, whose backticks then satisfy the anchor rule. Head and tail must both
  # carry one — anchor before the last separator, agent after it.
  { printf -- '- [ ] **A vague wish with no anchor at all**\n'
    printf '  — found by `sdd-qa` in mission `20260816-probe`\n'
    printf '  — revisit after the merge (2026-08-16)\n'; } > "$box/tailless.md"
  assert_says "$box/tailless.md" 8 'last field names no' "an attribution that is not the tail"

  # A closed finding is deleted at ANY depth: written as a nested list item it used to be plain
  # body text, invisible to the ticked-box rule while GitHub still rendered it checked.
  { printf -- '- [ ] **Item with a nested closed finding** — `bin/sdd:1` — why.\n'
    printf '  - [x] **closed, hidden as a child**\n'
    printf '  — found by `x` (2026-08-16)\n'; } > "$box/nested.md"
  assert_says "$box/nested.md" 8 'ticked box' "a ticked box nested under an open item"

  printf -- '- [ ] **No date tail** — `bin/sdd:1` — why it matters. — found by `x`\n' \
    > "$box/nodate.md"
  assert_says "$box/nodate.md" 8 'no (YYYY-MM-DD)' "no date at all"

  # A parenthesis that is not a date. Without this the rule degrades to "the last line has a (
  # somewhere" and nothing notices.
  printf -- '- [ ] **Paren but no date** — `bin/sdd:1` — why. — found by `x` (see the handoff)\n' \
    > "$box/parennodate.md"
  assert_says "$box/parennodate.md" 8 'no (YYYY-MM-DD)' "a paren that is not a date"

  # GitHub renders `- [X]` and `* [x]` as checked too; keying the rule to the lowercase dash form
  # let a closed finding hide from the sensor entirely.
  printf -- '- [x] **Ticked box** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n' \
    > "$box/ticked.md"
  assert_says "$box/ticked.md" 8 'ticked box' "a ticked box"
  printf -- '- [X] **Ticked, uppercase** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n' \
    > "$box/tickedupper.md"
  assert_says "$box/tickedupper.md" 8 'ticked box' "an uppercase X box"
  printf -- '* [x] **Ticked, asterisk bullet** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n' \
    > "$box/tickedstar.md"
  assert_says "$box/tickedstar.md" 8 'ticked box' "an asterisk bullet"

  { printf -- '- [ ] **Nine content lines** — `bin/sdd:1` — why it matters here.\n'
    for i in 2 3 4 5 6 7 8; do printf '  filler line %s\n' "$i"; done
    printf '  — found by `x` in mission `m` (2026-08-16)\n'; } > "$box/toolong.md"
  assert_says "$box/toolong.md" 8 'content lines, cap is 8' "nine lines under a cap of eight"

  # A heading after an item must end it. No probe covered this, so deleting the heading rule
  # passed the selftest; the real file only caught it by accident, having headings mid-file.
  { cat "$box/good.md"; printf '\n## Another section\n'; } > "$box/heading.md"
  assert_clean "$box/heading.md" 8 "a heading after an item"

  # --- the knobs ---
  PROBES=$((PROBES + 1))
  # Herestring, not `lint_todo … | grep -q`: under `pipefail` a matching `grep -q` closes the pipe,
  # the upstream stage dies of SIGPIPE and the pipeline returns 141 — the repo's signature bug,
  # documented in CLAUDE.md. Shellcheck's SC2143 asks for the pipe; it is wrong for this file.
  local capout; capout="$(lint_todo "$box/toolong.md" 9)"
  if grep -q 'content lines' <<< "$capout"; then
    printf '  SELFTEST FAIL  the cap is not honoured — 9 lines still failed under cap 9\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  PROBES=$((PROBES + 1))
  if ! valid_cap 8 || valid_cap abc || valid_cap '' || valid_cap 1x || valid_cap 0 || valid_cap 00; then
    printf '  SELFTEST FAIL  valid_cap does not separate positive integers from typos and zero\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # End-to-end: the number the sensor REPORTS must be the number the parser SEES. Proving
  # count_items() alone is fence-aware is not enough — the defect this closes was the caller
  # reaching for a `grep -c` beside the parser, which no probe on the function could ever notice.
  # Invoked through `bash "$SELF"` so a checkout without the exec bit (tarball, zip,
  # core.fileMode=false) does not turn into a bogus "the count is wrong" diagnosis.
  { printf 'Format:\n\n```md\n- [ ] <what> — `f:1` — <why> — by `<a>` (YYYY-MM-DD)\n```\n\n## Aberto\n\n'
    for i in $(seq 1 21); do
      printf -- '- [ ] **Item %s** — `bin/sdd:%s` — why it matters. — found by `x` (2026-08-16)\n' "$i" "$i"
    done; } > "$box/counted.md"
  PROBES=$((PROBES + 1))
  local reported
  reported="$(SDD_TODO_CAP=8 bash "$SELF" --check "$box/counted.md" 2>&1 |
    grep -oE '[0-9]+ finding' | grep -oE '[0-9]+')"
  if [ "$reported" != "21" ]; then
    printf '  SELFTEST FAIL  the sensor reports %s finding(s) where the parser sees 21 — the count\n' \
      "${reported:-<none>}" >&2
    printf '                 is not coming from the parser\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # An unreadable file must not read as an empty one: awk prints nothing, and an empty count in a
  # numeric test is a `[` syntax error that falls THROUGH, so the run used to end in "ok, 0
  # finding(s)" with rc 0 — the sensor failing open on the file it exists to guard.
  # PROBES is incremented INSIDE the guard: as root, or on a filesystem that ignores mode bits,
  # the probe cannot run, and counting it anyway would let the summary claim a probe that did not.
  printf 'x\n' > "$box/unreadable.md"
  if chmod 000 "$box/unreadable.md" 2>/dev/null && [ ! -r "$box/unreadable.md" ]; then
    PROBES=$((PROBES + 1))
    # shellcheck disable=SC2034
    bash "$SELF" --check "$box/unreadable.md" >/dev/null 2>&1
    [ "$?" -eq 93 ] || {
      printf '  SELFTEST FAIL  an unreadable findings file did not exit 93\n' >&2
      FAILS=$((FAILS + 1)); fail_rc 92
    }
    chmod 644 "$box/unreadable.md" 2>/dev/null
  else
    # As root, or on a filesystem that ignores mode bits, this probe CANNOT run. Counting the skip
    # keeps the floor honest in both worlds: the earlier floor simply failed the whole suite in a
    # container, blaming "an assertion stopped firing" for an environment difference.
    PROBES_SKIPPED=$((PROBES_SKIPPED + 1))
  fi

  # Every exit path carries a probe, or the code that names it is decoration: mutating any of
  # these `exit`/`return` values used to survive the whole selftest.
  assert_rc 95 "a non-integer cap must exit 95" env SDD_TODO_CAP=abc bash "$SELF" --check "$box/good.md"
  assert_rc 95 "a zero cap must exit 95"        env SDD_TODO_CAP=0   bash "$SELF" --check "$box/good.md"
  assert_rc 96 "an unknown option must exit 96" bash "$SELF" --bogus
  assert_rc 93 "a missing file must exit 93"    bash "$SELF" --check "$box/does-not-exist.md"
  # A file with prose but no items at all trips the floor, not the linter.
  printf '# Heading\n\n## Another\n' > "$box/noitems.md"
  assert_rc 94 "a file with no items must exit 94" bash "$SELF" --check "$box/noitems.md"
  # And an unclosed fence above every item must still say WHY, instead of the floor's generic
  # "did the format change?" — the linter runs first for exactly this case.

  # Floor on the probe COUNT, for the same reason every other floor here exists: neutering all the
  # assert_* call sites made the summary print "0 probe(s)" and exit 0 — a selftest that ran
  # nothing reads exactly like a selftest that passed. The number moves only on purpose.
  if [ "$((PROBES + PROBES_SKIPPED))" -lt 67 ]; then
    printf '  SELFTEST FAIL  only %d probe(s) accounted for (%d ran, %d skipped), expected 67\n' \
      "$((PROBES + PROBES_SKIPPED))" "$PROBES" "$PROBES_SKIPPED" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # Direct assignment, deliberately NOT through fail_rc: two independent paths from "a probe
  # failed" to "the exit status is non-zero", so neutering either one alone still reddens the run.
  if [ "$FAILS" -ne 0 ] && [ "$SELFTEST_RC" -eq 0 ]; then SELFTEST_RC=92; fi

  [ "$SELFTEST_RC" -eq 0 ] && printf '  ok    selftest: %d probe(s), the sensor measures what it claims\n' "$PROBES"
  return "$SELFTEST_RC"
}

# check_file <file> <cap> — the real check. Kept out of the top-level flow so the selftest can
# invoke it through `--check` without recursing into itself.
check_file() {
  local file="$1" cap="$2" n_items violations

  # `-r`, not `-f`: an existing but unreadable file made awk print nothing, and "nothing" then
  # sailed through the floor as a `[` syntax error. Readability is checked where it can still be
  # reported honestly.
  #
  # This guard and the numeric check below OVERLAP on the unreadable case and each alone is enough
  # for it — so sabotaging either one alone survives the selftest, while sabotaging BOTH is caught.
  # That is redundancy, not decoration, and the distinction is worth naming because this file
  # deleted a rule for being decoration: the two cover different CAUSES that happen to meet here.
  # `-r` names the permission problem before awk runs; the numeric check catches any other way the
  # counter can come back non-numeric (awk killed, out of memory, a future parser bug). The probe
  # asserts the OUTCOME — unreadable file exits 93 — precisely so it does not care which one fires.
  if [ ! -f "$file" ] || [ ! -r "$file" ]; then
    printf '  FAIL  findings file missing or unreadable: %s\n' "$file" >&2
    return 93
  fi

  n_items="$(count_items "$file")"
  case "$n_items" in
    '' | *[!0-9]*)
      printf '  FAIL  could not parse %s — the counter returned "%s"\n' "$file" "$n_items" >&2
      return 93 ;;
  esac

  # Lint BEFORE the floor, and the order is load-bearing: a stray unclosed fence above the first
  # item swallows every item, so the floor would fire first and answer "did the format change?"
  # when the parser knows the precise cause and has it ready to print.
  violations="$(lint_todo "$file" "$cap")"
  if [ -n "$violations" ]; then
    printf '  FAIL  %s does not hold its shape:\n' "$(basename -- "$file")" >&2
    printf '%s\n' "$violations" >&2
    printf '\n%d shape violation(s)\n' "$(grep -c . <<< "$violations")" >&2
    return 1
  fi

  # Floor against a file that lost its items entirely. It is deliberately 1, not a headcount:
  # this sensor exists to make the file SHRINK, so a floor near today's size would fail the run
  # the day the cleanup finally works. The real defence against a parser that stopped matching is
  # the selftest, whose probes go red on every rule.
  if [ "$n_items" -lt 1 ]; then
    printf '  FAIL  no items parsed from %s — did the format change?\n' "$file" >&2
    return 94
  fi

  printf '  ok    %d finding(s), all within %d lines and carrying anchor + date\n' "$n_items" "$cap"
  return 0
}

if ! valid_cap "$CAP"; then
  printf '  FAIL  SDD_TODO_CAP must be a positive integer, got: %s\n' "$CAP" >&2
  exit 95
fi
# Normalised to base 10 right after validation: `08` is a valid positive integer to valid_cap and
# to awk, but bash `printf %d` reads a leading zero as octal and dies on the 8 — the sensor then
# announced a cap it had not enforced and leaked a shell error next to an "ok".
CAP=$((10#$CAP))

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  # `${2-$TODO}` and not `${2:-$TODO}`: an EMPTY argument is a caller passing an unset variable,
  # and defaulting it to TODO.md answered "ok" about a file the caller never named.
  --check)    check_file "${2-$TODO}" "$CAP"; exit $? ;;
  '')         selftest || exit $?; check_file "$TODO" "$CAP"; exit $? ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
