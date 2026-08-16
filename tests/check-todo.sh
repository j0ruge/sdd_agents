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
# The count shares this parser instead of getting its own `grep -c` for a reason measured on this
# very file: TODO.md documents its own format inside a ```md block whose example line is itself an
# unchecked item, so a grep counts 46 where the parser sees 45. Two mechanisms answering the same
# question is how they drift — the defect this repo has now paid for three times (the two ledger
# readers, the two comparability predicates, and this counter).
#
# Three parsing rules earn their keep and each was written after a sabotage got past the earlier
# version: an UNCLOSED fence is reported (one stray ``` used to latch the parser off and blank
# every rule below it while the run stayed green); an indented fence inside an item is that item's
# code block rather than a document fence; and a column-0 line ENDS the item, so the item does not
# stay open across a blank line and swallow the INDENTED continuation of the paragraph that
# follows it. (Precision the earlier comment here lacked: a column-0 line was never absorbed —
# absorption requires a leading blank — so the rule earns its keep only in that indented case,
# which is exactly what its probe now exercises.)
#
# That last rule subsumes the `/^#/` heading rule this parser used to carry — a heading is a
# column-0 line — and the redundancy was found the honest way: sabotaging the heading rule left
# the selftest green, which reads identically to "no probe covers it". It was the second, not the
# first. Removed rather than probed, because a rule that cannot change an outcome is decoration.
todo_awk() {
  awk -v cap="$2" -v mode="$3" '
    # ── Why this parser is SMALL ───────────────────────────────────────────────────────────────
    # An earlier version tracked "we are inside the code block OF AN ITEM" so that items could
    # carry fenced examples. That state was the single most expensive decision in this file: five
    # adversarial rounds, and four of them found a fail-open living in it — the block markers
    # forged the anchor, a `- [x]` in a sample was reported, a column-0 line inside a block
    # latched the parser off, a column-0 `- [x]` between opener and closer vanished entirely.
    #
    # It was also YAGNI: not one of the 46 findings carries a code block, and the ~6-line budget
    # the format prescribes leaves no room for one. So items simply MAY NOT carry a fence, and
    # saying so is one line instead of a state machine. The complexity was never paying rent.
    #
    # Returns the fence marker (backticks or tildes, with its length) or "" — CommonMark indent
    # of 0-3 spaces, and a backtick fence whose info string contains a backtick is not a fence,
    # which is what stops an inline `` ```code``` `` span from opening a phantom block.
    # ⚠️ ` ? ? ?`, not `{0,3}`, and two match() calls instead of one alternation: mawk PANICS on
    # an interval combined with alternation ("REcompile() - panic: values still on machine stack")
    # — and the panic goes to stderr without aborting, so the pattern simply never matches. A
    # regex the engine cannot compile is one more way to fail open, and it looks like clean code.
    function fence_open(line,   m, rest) {
      if (match(line, /^ ? ? ?```+/) == 0 && match(line, /^ ? ? ?~~~+/) == 0) return ""
      m = substr(line, RSTART, RLENGTH); sub(/^ */, "", m)
      if (substr(m, 1, 1) == "`") {
        rest = substr(line, RSTART + RLENGTH)
        if (index(rest, "`") > 0) return ""
      }
      return m
    }
    # A closer uses the same character and is at least as long as its opener: a ```` block that
    # quotes a ``` one closed on the inner marker otherwise and desynced the rest of the file.
    function fence_closes(line, opener,   m) {
      m = fence_open(line)
      if (m == "") return 0
      if (substr(m, 1, 1) != substr(opener, 1, 1)) return 0
      return length(m) >= length(opener)
    }
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
    # every well-formed item ends with "found by `<agent>`", so "a backtick somewhere" is
    # satisfied by the attribution alone and an anchorless wish sails through. Checking both ends
    # also catches the item whose last field is not the attribution at all.
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
    fence && fence_closes($0, doc_marker) { fence = 0; next }
    fence                      { next }
    # A fence while an item is open is a violation, not a mode to enter. One line replaces the
    # state machine, and it fails CLOSED: the item is reported and the fence is tracked normally.
    fence_open($0) != "" {
      # Only an INDENTED fence belongs to the item — that is what an item continuation looks like.
      # A column-0 fence after a blank line is the next document block and merely closes the item.
      if (initem && mode == "lint" && $0 ~ /^[ \t]/)
        print "  line " start ": an item carries a code block — the long form belongs in the handoff it cites"
      flush(); fence = 1; fence_line = NR; doc_marker = fence_open($0); next
    }
    # Ticked boxes are checked PER LINE, not per item, and that is what finally covered them all:
    # `- [x]`, `* [x]`, `+ [x]`, `1. [x]`, indented, nested, with or without a trailing space —
    # GitHub renders every one of those as a checked task box, and each shape used to be its own
    # bypass. Anchored at line start so an inline `- [x]` inside prose is not a false positive.
    /^[ \t]*([-*+]|[0-9]+\.) \[[xX]\]([ \t]|$)/ {
      if (mode == "lint")
        print "  line " NR ": ticked box — a closed finding is deleted after its PR merges, never [x]"
      flush(); next
    }
    /^[-*+] \[ \]/ {
      flush(); initem = 1; start = NR
      first = $0; body = $0; last = $0; nlines = 1; next
    }
    initem && NF && /^[ \t]/   { body = body " " $0; last = $0; nlines++; next }
    # A column-0 line closes the item. Without this the item stays open across the blank line and
    # swallows the INDENTED continuation of whatever follows: the second line of a footnote then
    # becomes the last line of the item, and the date rule blames the finding above it.
    initem && NF               { flush(); next }
    END {
      flush()
      if (mode == "lint" && fence)
        print "  line " fence_line ": unclosed ``` — every rule below this line was skipped"
      if (mode == "count") print items + 0
    }
  ' "$1"
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
  assert_clean "$box/footnote.md" 8 "a column-0 footnote with an indented continuation"

  # An indented fence inside an item is that item's code block. Read as a document fence, it made
  # the parser skip to the close: a 43-line item measured 1 line and slipped under the cap.
  { printf -- '- [ ] **Item with a fenced block** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'
    printf '  ```sh\n'; for i in $(seq 1 40); do printf '  filler %s\n' "$i"; done
    printf '  ```\n'; } > "$box/itemfence.md"
  assert_says "$box/itemfence.md" 8 'carries a code block' "an item hiding 40 lines behind an indented fence"

  # THE fail-open. An indented fence pair in prose, opened by a rule below `fence` and closed by a
  # line `fence` eats first, latches the parser off: the ticked box below vanished and a later
  # column-0 fence rebalanced the toggle, so the run ended green with the item simply absent.
  # Both earlier versions of this file shipped that hole; only this probe distinguishes them.
  { printf 'Opening prose.\n\n  ```sh\n  echo hi\n  ```\n\n'
    printf -- '- [x] **A closed finding that must still be reported** — no anchor, no date\n\n'
    printf '```\n\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } \
    > "$box/latch.md"
  assert_says "$box/latch.md" 8 'ticked box' "a ticked box hidden behind an indented fence pair"

  # The mirror image: legal markdown must not be reported. An indented fence pair in prose with no
  # item open is a document fence and closes normally; and CommonMark lets the closer carry up to
  # three spaces even when the opener had none.
  { printf 'Prose.\n\n  ```sh\n  echo hi\n  ```\n\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } \
    > "$box/prosefence.md"
  assert_clean "$box/prosefence.md" 8 "a closed indented fence in prose"
  { printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n\n'
    printf '```md\nexample\n  ```\n'; } > "$box/asymfence.md"
  assert_clean "$box/asymfence.md" 8 "a fence opened at column 0 and closed indented"

  # --- the item code block: seven probes for the state the parser lacked until round 4 ---
  #
  # An item may not carry a fenced block at all — the rule that replaced a whole state machine.
  # Supporting item-level code blocks cost five adversarial rounds and four fail-opens, for a
  # feature no finding uses and the line budget forbids.
  { printf -- '- [ ] **Item documenting the format** — `TODO.md:1` — why.\n'
    printf '  ```md\n  - [x] a CLOSED example\n  ```\n'
    printf '  — found by `sdd-qa` (2026-08-16)\n'; } > "$box/sample.md"
  assert_says "$box/sample.md" 8 'carries a code block' "an item carrying a fenced example"

  # And the mirror: the block's own ``` markers used to FORGE the anchor. An opener plus a closer
  # is a matching backtick pair, so adding a code block flipped an anchorless item green.
  { printf -- '- [ ] **A wish with no anchor**\n'
    printf '  ```sh\n  echo hi\n  ```\n'
    printf '  — found by sdd-qa (2026-08-16)\n'; } > "$box/forged.md"
  assert_says "$box/forged.md" 8 'anchor before the found-by tail' "an anchor forged by the item fence markers"

  # A column-0 line inside the block used to close the item, which handed the block's closer to
  # the document rule as an OPENER — everything below vanished with the run green.
  { printf -- '- [ ] **A** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'
    printf '  ```sh\n  echo hi\ngrep -n foo bar\n  ```\n\n'
    printf -- '- [x] **HIDDEN closed finding, no anchor, no date**\n\n```\n\n'
    printf -- '- [ ] **B** — `bin/sdd:2` — why. — found by `x` (2026-08-16)\n'; } > "$box/col0block.md"
  assert_says "$box/col0block.md" 8 'ticked box' "a column-0 line inside an item code block"

  # Same hole reached by an asymmetric closer.
  { printf -- '- [ ] **A** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'
    printf '  ```sh\n  echo hi\n```\n\n'
    printf -- '- [x] **HIDDEN closed finding**\n\n```\n\n'
    printf -- '- [ ] **B** — `bin/sdd:2` — why. — found by `x` (2026-08-16)\n'; } > "$box/asymclose.md"
  assert_says "$box/asymclose.md" 8 'ticked box' "a column-0 closer under an indented opener"

  # Fences are compared by character AND length: a four-backtick block quoting a three-backtick
  # one closed on the inner marker and desynced every rule below it.
  { printf 'Prose.\n\n````md\n```\n````\n\n'
    printf -- '- [x] **HIDDEN closed finding**\n\n```\n\n'
    printf -- '- [ ] **B** — `bin/sdd:2` — why. — found by `x` (2026-08-16)\n'; } > "$box/quad.md"
  assert_says "$box/quad.md" 8 'ticked box' "a four-backtick fence quoting a three-backtick one"

  # A backtick fence is not closed by a tilde one. Without the character comparison the toggle
  # flips on the wrong marker and everything after it desyncs.
  { printf 'Prose.\n\n```md\n~~~\n```\n\n'
    printf -- '- [x] **HIDDEN closed finding**\n\n```\n\n'
    printf -- '- [ ] **B** — `bin/sdd:2` — why. — found by `x` (2026-08-16)\n'; } > "$box/mixfence.md"
  assert_says "$box/mixfence.md" 8 'ticked box' "a backtick fence closed by a tilde marker"

  # Tilde fences are fences too; unrecognised, their contents were linted as findings.
  { printf 'Prose.\n\n~~~md\n- [ ] an example inside a tilde fence\n~~~\n\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } > "$box/tilde.md"
  assert_clean "$box/tilde.md" 8 "a tilde-fenced example block"

  # The shapes GitHub renders as a checked box that each used to be its own bypass. Per-item
  # checking could never cover them; a per-LINE rule does, and this is the probe that says so.
  { printf -- '+ [x] **closed, plus bullet**\n'
    printf -- '1. [x] **closed, ordered list**\n'
    printf -- '   - [x] **closed, indented three spaces**\n'
    printf -- '- [X] **closed, uppercase**\n'
    printf -- '* [x]\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } \
    > "$box/allboxes.md"
  PROBES=$((PROBES + 1))
  if [ "$(lint_todo "$box/allboxes.md" 8 | grep -c 'ticked box')" != "5" ]; then
    printf '  SELFTEST FAIL  the five ticked-box shapes are not all reported: %s\n' \
      "$(lint_todo "$box/allboxes.md" 8 | grep -c 'ticked box')" >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  fi

  # A ticked box between an item fence opener and its closer, at column 0. CommonMark ends the
  # list item there and GitHub draws a live checkbox — and the version that tracked item code
  # blocks swallowed it whole, with the run green. The rule that replaced that state machine
  # cannot have this hole: fences never open a mode, and the box is judged line by line.
  { printf -- '- [ ] **T** — `f:1` — why. — found by `x` (2026-08-16)\n'
    printf '  ```\n'
    printf -- '- [x] **A CLOSED FINDING that GitHub renders ticked**\n'
    printf '  ```\n'; } > "$box/boxinfence.md"
  # Fails CLOSED, and that is the whole point: the earlier design swallowed this file whole and
  # exited 0. It now names the root cause the author must fix — the item may not carry a block —
  # and the box below it becomes visible the moment that is done. Reporting the deepest symptom
  # is worth less than refusing the file and naming the structural reason.
  assert_says "$box/boxinfence.md" 8 'carries a code block' "a column-0 ticked box between an item fence pair"
  assert_rc 1 "a ticked box between an item fence pair must fail the file" \
    bash "$SELF" --check "$box/boxinfence.md"

  # An inline code span that merely starts with three backticks is not a fence: CommonMark says a
  # backtick fence's info string may not contain a backtick. Accepting it opened a phantom block
  # that swallowed every rule until the next backtick line.
  { printf -- '- [ ] **A** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'
    printf '  ```code``` is the inline form.\n'
    printf -- '- [x] **HIDDEN closed finding**\n'
    printf '  ```\n'
    printf -- '- [ ] **B** — `bin/sdd:2` — why. — found by `x` (2026-08-16)\n'; } \
    > "$box/inlinespan.md"
  assert_says "$box/inlinespan.md" 8 'ticked box' "an inline code span mistaken for a fence"

  # A markdown link whose text is `x` is not a ticked box. Requiring a space or line end after the
  # box is what separates them; dropping that requirement made the sensor report a link.
  { printf -- '- [x](https://example.com/spec) see the linked spec\n\n'
    printf -- '- [ ] **Good** — `bin/sdd:1` — why. — found by `x` (2026-08-16)\n'; } > "$box/link.md"
  assert_clean "$box/link.md" 8 "a markdown link whose text is x"

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

  # One stray unclosed fence used to latch the parser off and blank every rule below it, with the
  # run still reporting green.
  { cat "$box/good.md"
    printf '\n```md\n\n- [x] **A closed item hiding below an unclosed fence** — no anchor, no date\n'
  } > "$box/unclosed.md"
  assert_says "$box/unclosed.md" 8 'unclosed ```' "an unclosed fence"

  # A heading after an item must end it. No probe covered this, so deleting the heading rule
  # passed the selftest; the real file only caught it by accident, having headings mid-file.
  { cat "$box/good.md"; printf '\n## Another section\n\nProse under the heading.\n'; } \
    > "$box/heading.md"
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
  { printf 'Format:\n\n```md\n- [ ] <what> — `f:1` — <why> — by `<a>` (YYYY-MM-DD)\n```\n\n'
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
  printf '# Heading\n\nProse, and not one finding.\n' > "$box/noitems.md"
  assert_rc 94 "a file with no items must exit 94" bash "$SELF" --check "$box/noitems.md"
  # And an unclosed fence above every item must still say WHY, instead of the floor's generic
  # "did the format change?" — the linter runs first for exactly this case.
  # Through --check, not lint_todo: what this probe guards is the ORDER inside check_file. Run the
  # floor first and it answers 94 "did the format change?" while the linter already knows the
  # precise cause. Asserting rc 1 is what distinguishes the two orderings.
  { printf '```md\n'
    printf -- '- [ ] **swallowed** — `f:1` — why. — found by `x` (2026-08-16)\n'; } > "$box/swallow.md"
  assert_says "$box/swallow.md" 8 'unclosed ```' "an unclosed fence above every item"
  assert_rc 1 "an unclosed fence must lint before the floor answers" \
    bash "$SELF" --check "$box/swallow.md"

  # Floor on the probe COUNT, for the same reason every other floor here exists: neutering all the
  # assert_* call sites made the summary print "0 probe(s)" and exit 0 — a selftest that ran
  # nothing reads exactly like a selftest that passed. The number moves only on purpose.
  if [ "$((PROBES + PROBES_SKIPPED))" -lt 49 ]; then
    printf '  SELFTEST FAIL  only %d probe(s) accounted for (%d ran, %d skipped), expected 49\n' \
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
    printf '  FAIL  %s does not hold its shape:\n' "$(basename "$file")" >&2
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
  --check)    check_file "${2:-$TODO}" "$CAP"; exit $? ;;
  '')         selftest || exit $?; check_file "$TODO" "$CAP"; exit $? ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
