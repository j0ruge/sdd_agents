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
# Env: SDD_TODO_FILE overrides which file the no-arg form checks; SDD_TODO_CAP overrides the
#      per-item line budget (a positive integer; anything else exits 95).
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
# The two rules added last (the code-span-aware tail cut, and the box that lands on the line after
# its marker) went through their own adversarial pass: 13 degradations, 12 dead. The one SURVIVOR
# of that round was a probe, not a rule — the unticked-box fixture used an empty marker and
# asserted the loose word "bare", so the MARKER rule answered for it and the box rule could be
# narrowed to `[xX]` with the selftest still green. It reads the exact message now, over the link
# reference carrier, which only the box rule can catch.
#
# What survives by construction, named rather than hidden and not reachable in one edit: lowering
# a floor while the thing it counts is still there. That is inert on its own — the paired sabotage
# (delete a probe, delete a rule_end call) dies on the floor, which is what makes the floor a rule
# and not a decoration.
#
# Not measured, on purpose: whether an anchor still points at real code, whether the prose is any
# good, and whether a finding is worth keeping. All three are human judgement on the diff.
#
# TWO measured weaknesses, stated rather than hidden. The first is the header: nothing here
# models a fence, so a stray or unbalanced fence in the header — which makes GitHub render the
# whole findings section as a code block — is NOT detected. Four mechanisms tried to catch it and
# all four were worse than the gap: two failed silent, and the last also failed RED on an inline
# code span, on a nested example, and on the header showing the very shape rule 1 enforces.
# Detecting it correctly needs a CommonMark parser, which this file must not be. The blast radius
# is bounded and visible: the ticked-box rule never depended on fences, so no closed finding can
# hide behind one, and a file rendering as code is obvious to the first human who opens it.
#
# ⚠️ That last sentence was FALSE for two missions, and not because of fences: the ticked rule is
# per-line and demanded the marker and the `[x]` together, while GFM ticks a box whose marker line
# vanished from the AST. Two carriers did it and both are refused by name now, with the bare-box
# rule beside the ticked one. The claim above is true again, and it is worth remembering that it
# read as true while it was not.
#
# The one that is left: rule 3 asks for a backticked token before the last separator, so an item
# whose TITLE carries inline code satisfies it without an anchor — 45 of the 46 findings would
# still pass with their `file:line` deleted. Tightening it needs a shape test the real data will
# not support (`git worktree` and `KAIZEN_LOG` are legitimate anchors). It is in TODO.md, and it
# cannot hide a closed finding, which is what rule 2 and the whitelist are for.
#
# The third used to live here — rule 4 splitting on the last ` — ` without knowing code spans, so
# an em-dash inside the attribution backticks misreported a well-formed item. Closed: last_sep()
# skips any separator sitting at an odd backtick depth. It was a false ALARM rather than a
# fail-open, and those cost the sensor the trust that makes it worth reading.
#
# Exit codes, one per cause, FIRST failure wins — a shared or last-write-wins code would leave
# the reader unable to tell which failure happened:
#    0  clean          1  the file has shape violations
#   89  no temp dir (the probes never ran)   90/91/92  a selftest probe failed
#   93  findings file missing or unreadable  94  fewer items than the floor
#   95  SDD_TODO_CAP is not a positive integer   96  unknown option

set -uo pipefail

SELF="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
  awk -v cap="$2" -v mode="$3" -v from="${from:-0}" '
    # How many backticks occur in text. Byte-based like everything else here, and that is safe:
    # a backtick is ASCII, so no multibyte character can contain one as a byte.
    function backticks(text,   n, i, p) {
      n = 0; i = 1
      while ((p = index(substr(text, i), "`")) > 0) { n++; i = i + p }
      return n
    }
    # Byte offset of the last " — " separator that is NOT inside a code span, 0 when there is none.
    #
    # ⚠️ index()/substr(), never a regex with a negated em-dash class. The awk this repo runs is
    # mawk, BYTE-oriented whatever the locale: `[^—]` is the negated byte set {0xE2,0x80,0x94},
    # so any character from U+2000..U+2FFF in the tail — every curly quote, ellipsis, en-dash,
    # bullet and arrow — broke the match and the anchor rule failed OPEN on ordinary punctuation.
    #
    # ⚠️ The code-span test is a BACKTICK PARITY, not a code-span model — this file does not write
    # CommonMark parsers, and six adversarial rounds are why. An odd number of backticks before an
    # offset means the offset is inside a span; that is exactly the precondition, and it needs no
    # knowledge of fences, of multi-backtick delimiters or of nesting. Without it the cut landed
    # inside `a — b` and reported "the last field names no `<agent>`" on an item whose attribution
    # was perfectly well formed — a FALSE ALARM, which costs the reader the trust that makes the
    # sensor worth reading. An unclosed backtick makes every later separator read as "inside", so
    # the cut moves left and the item is reported malformed: the honest answer, since it is.
    function last_sep(text,   sep, i, p, last, at) {
      sep = " — "; last = 0; i = 1
      while ((p = index(substr(text, i), sep)) > 0) {
        at = i + p - 1
        if (backticks(substr(text, 1, at - 1)) % 2 == 0) last = at
        i = at + length(sep)
      }
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
        # The found-by opens with PROSE — "found by", "descoberto por" — never with the span
        # itself. Skipping separators inside spans (above) has a second edge nobody asked for:
        # when the last content of an item IS a span, the cut lands on the separator BEFORE it
        # and the whole decoy span becomes the tail. That span carries a backtick pair, so the
        # check right above is satisfied, and an item naming no agent AT ALL reads well formed.
        # Measured: the naive cut used to land INSIDE such a span and reject the item by
        # accident, so removing the false alarm opened a real hole. Position again, not
        # presence — the same answer the anchor/tail split already gives, asked now of the
        # first token of the tail. All 43 items open this field with prose, none with a span.
        #
        # ⚠️ DECLARED LIMIT, and the sentence above used to read as though the hole were shut.
        # It is not: this rule reaches the span that IS the whole tail, and nothing else. A decoy
        # span sitting LATER in the same tail — prose, then the span, then more prose, then the
        # date — still satisfies the presence check above and still names no agent. Measured
        # differentially in the r2 review: the merge-base sensor REJECTED that shape (the naive
        # cut fell inside the span, leaving one lone backtick), this one accepts it, so it is a
        # regression of this mission and not the pre-existing weakness it was first filed as.
        # It is left open on purpose. Every syntactic rule tried against it invents violations
        # on the real file — requiring the span to be the last content before the date rejects
        # five well-formed items, because real found-by fields legitimately carry prose after
        # the agent name. Closing it needs the semantic re-derivation that 00-missao.md put out
        # of scope by name. Filed in TODO.md with this differential; the mirror weakness on
        # head_of is declared in this sensor header, and now so is this one.
        # ⚠️ No apostrophe and no backtick in this comment: the whole program is single-quoted
        # in the shell, so either one ends the quote and bash parses awk source as commands.
        else if (tail_of(body) ~ /^[ \t]*`/)
          print "  line " start ": the found-by tail opens with a code span — it names no `<agent>`, the cut fell before a trailing span"
        if (last !~ /\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\)/)
          print "  line " start ": last line carries no (YYYY-MM-DD) — the found-by field is the tail"
        if (nlines > cap)
          print "  line " start ": " nlines " content lines, cap is " cap
      }
      initem = 0
    }
    { sub(/\r$/, "") }        # CRLF: a trailing \r used to defeat the end-of-line alternations
    # A BARE CR — one not followed by LF — is a line ending to CommonMark and to GitHub, and not
    # to awk or grep. Everything after it on the same physical line renders as its own line, so a
    # closed finding could ride behind one, invisible, with the run green. Refused by name rather
    # than parsed, like every other construct this file will not model.
    /\r/ {
      if (mode == "lint") print "  line " NR ": a bare CR — it is a line ending to the renderer, not to this parser"
      flush(); next
    }
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
    # ── The box that lands on the line AFTER its marker, and the two carriers that put it there ─
    # The rule above is per-line and demands the marker and the `[x]` together. GFM does not: it
    # ticks the box when the first rendered block of the item is a paragraph opening with `[x] `,
    # and the line of the marker can vanish from the AST entirely. Two carriers do it — an empty
    # marker (`-` alone) and a link-reference definition (`- [ref]: https://…`, which emits no
    # node) — so a closed finding renders TICKED on GitHub while the run exits 0 on a file that
    # looks perfectly healthy. Measured against the merged sensor in the 12th adversarial round,
    # with the CommonMark AST as witness: in both carriers the first child of the item is a
    # paragraph whose first text is `[`, `x`, `]`, ` ` — the same shape as the item below it.
    #
    # Both rules run over the WHOLE file for the same reason the ticked rule does: "the header" is
    # not a fixed preamble but everything above a heading an editor can move, and the header skip
    # is precisely what let the first carrier through.
    #
    # Refused by name, never parsed. Deciding what a split item MEANS is the road this file has
    # already refused four times; deciding whether it belongs is a question with a short answer.
    /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]*$/ {
      if (mode == "lint") print "  line " NR ": a bare list marker — a finding is one line-start"
      flush(); next
    }
    # The second carrier is caught by the box itself rather than by the line that carried it: a
    # link-reference definition is only one of the shapes that can disappear from the AST, and the
    # box is what every one of them ends up pointing at. `[ ]` counts as well as `[x]` — GitHub
    # renders it as an OPEN task item, which is a finding the counter never saw.
    /^[ \t>]*\[[ xX]\]([ \t]|$)/ {
      if (mode == "lint") print "  line " NR ": a bare [ ]/[x] box — the marker it belongs to is on another line"
      flush(); next
    }
    # ── Header: NOTHING here models a fence, and that is the fourth and final answer ───────────
    # Four mechanisms tried to know where the header example begins and ends — a global toggle, a
    # bounded toggle, a parity count, and the closer-matching in between. All four failed, and the
    # last two failed BOTH ways: the parity count went silent on mixed `~~~`/``` markers and went
    # red on an inline `` ```code``` `` span, on a nested example, and on the header showing the
    # very shape rule 1 enforces. Counting is not a fence model either; only a CommonMark parser
    # is, and this file proved at length that it must not be one.
    #
    # So the header is judged by CONTENT alone: an item-shaped line whose TITLE POSITION opens
    # with a `<placeholder>` is documentation, anything else item-shaped is a finding in the wrong
    # place. No fence knowledge is needed for that, and the ticked-box rule never needed any.
    #
    # ⚠️ The anchor on that test is the whole rule. Loosened to "carries a `<` anywhere", it hid
    # every header finding that merely QUOTES a placeholder — measured: 288 of 18720 header shapes
    # rendered as a task item and went invisible, all 288 carrying a `<`, none without one. The
    # widening was meant to accept a header example written as `- [ ] **<what>** — …`; anchoring
    # to the title position accepts that and nothing else.
    NR <= from && /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]+\[ \]/ {
      if ($0 !~ /^[ \t>]*([-*+]|[0-9]+[.)])[ \t]+\[ \][ \t]*(\*\*)?</ && mode == "lint")
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
# Set by selftest() at its end, read by check_file: see the coupling there. It is the state
# that makes `selftest ||` undeletable from the bare dispatch.
SELFTEST_RAN_IN_PROC=0
# 1 only on the explicit `--check <file>` path, which names its file and makes no claim about the
# parser, so it is exempt from that coupling.
EXPLICIT_MODE=0

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

# rule_begin / rule_end — one `ok    rule: ` line per rule, printed only when that rule's OWN
# probes ran AND passed.
#
# It is an assertion, not a caption. The floor is the half that bites: deleting a rule's probes
# leaves the parser change with nothing measuring it, and without a per-rule floor the global
# PROBES floor absorbs the loss the moment any other rule grows a probe. The FAILS comparison is
# the other half — a rule whose probes went red does not get to print a green line about itself,
# and the selftest has already said so on stderr.
RULE_MARK_PROBES=0
RULE_MARK_FAILS=0
# Counted, so that deleting a rule_end CALL SITE cannot buy silence. Without this the per-rule
# floor guards the probes and nothing guards the report: the sensor would stay green while saying
# one rule fewer than it ran, which is the shape of every quiet regression in this suite.
RULES_REPORTED=0
RULES_FLOOR=2
rule_begin() { RULE_MARK_PROBES="$PROBES"; RULE_MARK_FAILS="$FAILS"; }
rule_end() { # rule_end <floor> <text>
  local n=$((PROBES - RULE_MARK_PROBES))
  if [ "$n" -lt "$1" ]; then
    printf '  SELFTEST FAIL  the rule "%s" ran %d probe(s), expected at least %d — probes deleted\n' \
      "$2" "$n" "$1" >&2
    FAILS=$((FAILS + 1)); fail_rc 92; return 0
  fi
  [ "$FAILS" -eq "$RULE_MARK_FAILS" ] || return 0
  printf '  ok    rule: %s (%d probe(s))\n' "$2" "$n"
  RULES_REPORTED=$((RULES_REPORTED + 1))
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

# --- negative controls over the assertion helpers themselves ------------------------------------
# The three helpers above are the ONLY thing standing between a broken parser and a green run, and
# the r2 review of 20260818-lote-facil measured that nothing stood behind them: replacing the body
# of `assert_clean`, `assert_says` and `assert_rc` with `return 0` — while still bumping PROBES —
# left this file printing `88 probe(s), the sensor measures what it claims`, rc 0. The floors count
# CALL SITES, and every call site was still there; nothing probed the VERDICT inside the helper.
#
# So each helper is run against a world whose answer is known, and the ground truth for that world
# is taken from `lint_todo` itself rather than assumed — a control over a fixture that turned out
# to be clean would be vacuous in exactly the direction being tested. The counters are saved and
# restored, so the controls cost the report nothing.
helper_selfcheck() {
  local box bad good msg cfail=0
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-todo-helperprobe-XXXXXX")"
  if [ -z "$box" ] || [ ! -d "$box" ]; then
    printf '  SELFTEST FAIL  could not create a temp dir for the helper controls\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 89; return 0
  fi
  cat > "$box/bad.md" <<'EOF'
## Aberto

- [ ] a finding with no bold title, no anchor and no date
EOF
  cat > "$box/good.md" <<'EOF'
## Aberto

- [ ] **A finding with every field in place** — `bin/sdd:42` — why it matters, in one clause.
  Direction: what to do about it. — found by `sdd-qa` in mission `20260816-probe` (2026-08-16)
EOF
  # Ground truth from the parser itself, never assumed: a control over a fixture that turned out
  # clean would be vacuous in exactly the direction being tested.
  bad="$(lint_todo "$box/bad.md" 8)"; good="$(lint_todo "$box/good.md" 8)"
  if [ -z "$bad" ] || [ -n "$good" ]; then
    printf '  SELFTEST FAIL  the helper controls are vacuous: the bad world lints clean or the good one does not\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 89; rm -rf "$box"; return 0
  fi

  # Each control reads the helper's own MESSAGE from a subshell. That is the whole design: a first
  # draft let the helpers bump FAILS for real and restored the counters afterwards — and the
  # restore threw away the verdict it had just recorded, so all three neutered helpers passed. In
  # a subshell the counters cannot be perturbed, so there is nothing to restore and no way to lose
  # the answer. `say()` is not used: the controls must not print unless something is wrong.
  msg="$(assert_clean "$box/bad.md" 8 '<negative control>' 2>&1)"
  case "$msg" in *'expected no violation'*) ;; *) cfail=$((cfail + 1))
    printf '  SELFTEST FAIL  assert_clean accepted a file that lints dirty — the helper is a no-op and every probe using it proves nothing\n' >&2 ;; esac

  msg="$(assert_says "$box/bad.md" 8 'a substring no message contains' '<negative control>' 2>&1)"
  case "$msg" in *'expected a violation saying'*) ;; *) cfail=$((cfail + 1))
    printf '  SELFTEST FAIL  assert_says accepted a message that does not contain what it asked for — the helper is a no-op\n' >&2 ;; esac

  msg="$(assert_rc 77 '<negative control>' true 2>&1)"
  case "$msg" in *'expected rc 77, got 0'*) ;; *) cfail=$((cfail + 1))
    printf '  SELFTEST FAIL  assert_rc accepted rc 0 where it demanded 77 — the helper is a no-op\n' >&2 ;; esac

  # And the other direction, or a helper that fails on EVERY world would pass the three above.
  msg="$(assert_clean "$box/good.md" 8 '<positive control>' 2>&1)$(assert_says "$box/bad.md" 8 'does not open with' '<positive control>' 2>&1)$(assert_rc 0 '<positive control>' true 2>&1)"
  [ -z "$msg" ] || { cfail=$((cfail + 1))
    printf '  SELFTEST FAIL  a helper accused a world it should accept — a rule that refuses everything distinguishes nothing: %s\n' "$msg" >&2; }

  [ "$cfail" -eq 0 ] || { FAILS=$((FAILS + cfail)); fail_rc 90; }
  rm -rf "$box"
  HELPER_CONTROLS_RAN=1
}

selftest() {
  local box
  # The bare-dispatch probe below re-enters this file with no arguments, which is the path that
  # runs `selftest || exit $?; check_file`. Answering here — before any probe — is what keeps that
  # from recursing, and makes the poisoned run report a rc no clean world produces.
  case "${SDD_TODO_SELFTEST_POISON:-}" in
    '') ;;
    *)
      printf '  SELFTEST FAIL  poisoned on purpose, so a probe can prove the bare dispatch runs the selftest\n' >&2
      return 97 ;;
  esac
  HELPER_CONTROLS_RAN=0
  helper_selfcheck
  [ "$HELPER_CONTROLS_RAN" -eq 1 ] || {
    printf '  SELFTEST FAIL  the helper controls did not run — the assertions below are unmeasured\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 89; }
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

  # A bare CR is a line ending to GitHub and not to awk: a closed finding could ride behind one on
  # the same physical line, invisible, with the run green. Refused by name.
  printf -- '## Aberto\n\n- [ ] **Item** — `f:1` — w. — by `x` (2026-08-16)\r- [x] **hidden**\n' \
    > "$box/barecr.md"
  assert_says "$box/barecr.md" 8 'a bare CR' "a closed finding hidden behind a bare CR"

  # The header example may be written in the shape rule 1 enforces, or nested in an indented
  # fence; keying the test to a `<` at byte 7 failed both. A third spelling — a worked example
  # with concrete values and NO placeholder — is still reported, and that is the convention rather
  # than a gap: telling documentation from a misplaced finding without modelling fences is exactly
  # what the placeholder is for. Stated here because the earlier version of this comment claimed
  # three cases and the code covered two.
  { printf 'Format:\n\n```md\n'
    printf -- '- [ ] **<what>** — `file:line` — <why> — by `<agent>` (YYYY-MM-DD)\n'
    printf '```\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/template2.md"
  assert_clean "$box/template2.md" 8 "a header example written in the enforced shape"

  # A finding parked in the header that merely QUOTES a placeholder is still a finding. Loosening
  # the template test to "carries a `<` anywhere" hid 288 of the 18720 header shapes that render
  # as a task item — every one of them carrying a `<`, none without.
  { printf -- '- [ ] **`gate_DOCS` fails when the text quotes `<preencher>`** — `bin/sdd:394` —\n'
    printf '  the sentinel matches an innocent mention. — by `humano` (2026-08-16)\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/quotesplaceholder.md"
  assert_says "$box/quotesplaceholder.md" 8 'above the findings section' \
    "a header finding that quotes a placeholder"

  # The `flush()` on the block-quote branch is load-bearing and was unprobed: the only quote probe
  # put the quote BEFORE any item, where flushing is a no-op. With an item open, a quote ends it —
  # CommonMark puts the paragraph after it outside the list — and without the flush the item
  # swallows that paragraph and its defects go unreported, rc 0.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **A finding with no anchor and no date**\n\n'
    printf '> a note in the section\n\n  — by `x` (2026-08-16)\n'; } > "$box/quoteflush.md"
  # Asserting the DATE message, not the anchor one: without the flush the indented line below the
  # quote is absorbed as continuation and carries the date, so the anchor message fires either way
  # and the probe would prove nothing. Only the date message discriminates.
  assert_says "$box/quoteflush.md" 8 'no (YYYY-MM-DD)' "a block quote must end the item before it"

  # The tail rule's "non-empty" half had no probe — the head's did. An empty pair must not count
  # as naming an agent.
  printf -- '## Aberto\n\n- [ ] **T** — `f:1` — why. — found by `` (2026-08-16)\n' \
    > "$box/emptytail.md"
  assert_says "$box/emptytail.md" 8 'last field names no' "an empty backtick pair in the tail"

  # A blank line must NOT close an item: findings are written in multiple paragraphs, and closing
  # on blank would turn every one of them red.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **A multi-paragraph finding** — `f:1` — first paragraph.\n\n'
    printf '  Second paragraph. — found by `x` (2026-08-16)\n'; } > "$box/multipara.md"
  assert_clean "$box/multipara.md" 8 "a finding written in two paragraphs"

  # And the `NF` guard on the continuation rule: a whitespace-only line must not become the item's
  # last line, or the date rule blames a finding that carries its date correctly.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **A finding** — `f:1` — why. — found by `x` (2026-08-16)\n'
    printf '   \n'; } > "$box/wsline.md"
  assert_clean "$box/wsline.md" 8 "a whitespace-only line after the last item"

  # The violation COUNT in the failure report is asserted, not just the messages: setting it to a
  # constant used to survive the whole selftest.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'
    printf -- '1. [ ] one\n-  [ ] two\n> - [ ] three\n'; } > "$box/countable.md"
  # Herestring, never `| grep -q`: under `pipefail` a matching `grep -q` closes the pipe, the
  # upstream stage dies of SIGPIPE and the pipeline returns 141 — so the probe would report a
  # failure exactly when the assertion HOLDS. The trap this repo documents, walked into while
  # writing the probe that asserts the count.
  PROBES=$((PROBES + 1))
  local countout; countout="$(bash "$SELF" --check "$box/countable.md" 2>&1)"
  if ! grep -q '^3 shape violation(s)' <<< "$countout"; then
    printf '  SELFTEST FAIL  the reported violation count is not 3\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # `from` is the FIRST `^## Aberto`, anchored at column 0. Taking the last one would put a whole
  # section of findings back inside the header; matching the word unanchored would let a mention
  # of the heading in prose move the boundary earlier.
  # A ticked box would not discriminate here — that rule reads the whole file. A malformed ITEM
  # does: judged in the section it gets the anchor and date rules, judged as header it gets one
  # "above the findings section" and its real defects go unreported.
  { printf '## Aberto\n\n'
    printf -- '- [ ] **A finding with no anchor and no date**\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/twoheadings.md"
  assert_says "$box/twoheadings.md" 8 'no non-empty' "a malformed item between two ## Aberto headings"
  { printf 'Header prose mentioning the Aberto section before it exists.\n\n'
    printf -- '- [ ] not a finding, just header prose\n\n## Aberto\n\n'
    printf -- '- [ ] **Good** — `f:1` — w. — by `x` (2026-08-16)\n'; } > "$box/looseheading.md"
  assert_says "$box/looseheading.md" 8 'above the findings section' "a heading word mentioned in header prose"


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

  # The DISPATCH, and not just the functions it dispatches to. `''` is the branch the suite uses —
  # `selftest || exit $?; check_file "$TODO"` — and r2 measured that deleting the `selftest ||`
  # half of it went unnoticed: `check_file` alone answers 0 over a healthy TODO.md and the run
  # looks identical. The poison makes the selftest report 97, a code no clean world produces, and
  # the two probes are a pair: the first pays the floor — proving the poison is armed at all —
  # before the second concludes anything about the path from it.
  #
  # These two do NOT close the deletion itself, and pretending otherwise is the failure this round
  # exists to stop: delete `selftest ||` and the probes below never run, because they live inside
  # the function that was just unhooked. What closes it is the coupling in check_file (see there) —
  # missing state, not one more assertion that the same edit could take with it.
  # Guarded on the poison being ABSENT, and that guard is not decoration: it is what makes the
  # recursion impossible by construction rather than by the branch these probes are testing. An
  # adversarial pass deleted that branch and the suite HUNG — the child ran the full selftest,
  # which spawned another child in the same world, forever. A sensor that hangs is worse than one
  # that lies, and this repo has just spent three REVIEW sessions on suites that never returned.
  if [ -z "${SDD_TODO_SELFTEST_POISON:-}" ]; then
    assert_rc 97 "the poison is armed: --selftest reports it" \
      env SDD_TODO_SELFTEST_POISON=1 bash "$SELF" --selftest
    assert_rc 97 "the bare dispatch runs the selftest and propagates its rc" \
      env SDD_TODO_SELFTEST_POISON=1 bash "$SELF"
  else
    PROBES_SKIPPED=$((PROBES_SKIPPED + 2))
  fi

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

  # ── the tail cut, and the code spans it used to cut inside ───────────────────────────────────
  # `last_sep` takes the LAST " — " in the item and calls everything after it the found-by field.
  # A code span in the attribution carrying an em-dash — a mission slug, a flag, a quoted message
  # — moves that cut INSIDE the span, and a perfectly well-formed item is reported as malformed.
  # It is a fail-open's mirror image: a false alarm, which costs the reader the trust that makes
  # the sensor worth reading at all.
  rule_begin
  cat > "$box/tailspan.md" <<'EOF'
## Aberto

- [ ] **A finding whose attribution carries an em-dash in backticks** — `bin/sdd:42` — why it
  matters, in one clause. — found by `sdd-qa` in mission `a — b` (2026-08-16)
EOF
  assert_clean "$box/tailspan.md" 8 "an em-dash inside the attribution's code span"

  # TWO spans carrying a separator, and the scan has to walk past both. A loop that stopped at the
  # first one it had to skip would answer with a cut further left and call the item malformed for
  # a different reason — the same false alarm wearing another message.
  #
  # Note what this probe does NOT claim. The false alarm has exactly one direction: an em-dash
  # span BEFORE the last legitimate separator changes nothing, because the head keeps an earlier
  # complete span either way. A first draft here asserted the head side too and was red against
  # the FIXED parser — the fixture it used was genuinely malformed (its anchor sat in the tail),
  # so it was measuring the anchor rule and calling it the tail rule.
  cat > "$box/twospans.md" <<'EOF'
## Aberto

- [ ] **A finding with two em-dash spans in its tail** — `bin/sdd:42` — why it matters, in one
  clause. — found by `a — b` in mission `c — d` (2026-08-16)
EOF
  assert_clean "$box/twospans.md" 8 "two code spans carrying separators in the tail"

  # The rule must still BITE, or "ignore code spans" is just "stop checking". A tail with no code
  # span at all is still an item that never names its agent.
  cat > "$box/tailspan-bad.md" <<'EOF'
## Aberto

- [ ] **A finding with an em-dash in a span and no agent** — `bin/sdd:42` — because `a — b`
  matters — found by nobody at all (2026-08-16)
EOF
  assert_says "$box/tailspan-bad.md" 8 'last field names no' \
    "a code span earlier in the line does not excuse an agentless tail"

  # And the degenerate case: EVERY separator inside a span leaves no cut at all, which is the
  # same answer as an item with no separator — malformed, said out loud.
  cat > "$box/allspan.md" <<'EOF'
## Aberto

- [ ] **A finding whose only separators hide in one span** — `a — b — c` (2026-08-16)
EOF
  assert_says "$box/allspan.md" 8 'no non-empty' \
    "an item whose every separator sits inside a code span"

  # The hole the span-skip opened, and the reason this rule has six probes and not four. The item
  # below names NO agent anywhere; its last content is a quoted phrase that happens to carry an
  # em-dash. The cut lands on the separator before that span, the span becomes the whole tail, and
  # its backtick pair satisfies "the tail names an agent". Before the span-skip existed the cut
  # fell INSIDE the span and the item was rejected — by accident, but rejected. Verified against
  # the merge-base copy of this sensor, which says `last field names no`; without this probe the
  # regression is invisible and an unattributed finding hides behind any trailing quoted phrase.
  cat > "$box/decoyspan.md" <<'EOF'
## Aberto

- [ ] **A finding with a decoy span and no attribution** — `bin/sdd:42` — `emdash — inside decoy span` (2026-08-16)
EOF
  assert_says "$box/decoyspan.md" 8 'opens with a code span' \
    "a trailing decoy span is not an attribution"

  # The same shape spread over a continuation line: the span opens on one physical line and closes
  # on the next, so a rule reading single lines instead of the joined body would miss it.
  cat > "$box/decoyspan-multi.md" <<'EOF'
## Aberto

- [ ] **A finding with a decoy span across two lines** — `bin/sdd:42` — why it matters, in one
  clause. — `emdash — inside decoy span` (2026-08-16)
EOF
  assert_says "$box/decoyspan-multi.md" 8 'opens with a code span' \
    "a trailing decoy span split across lines is not an attribution either"

  # The `[ \t]*` in the rule, which had no probe of its own. The separator ends a physical line
  # and the decoy span opens the next, so the joined tail starts with the continuation indent
  # rather than with the backtick. Dropping the tolerance — a one-character edit to `/^`/` —
  # left the whole selftest green in the r2 adversarial pass while this shape, which is ordinary
  # authoring and not a contrivance, walked through unattributed.
  cat > "$box/decoyspan-indent.md" <<'EOF'
## Aberto

- [ ] **A finding whose decoy span opens the continuation line** — `bin/sdd:42` — why it matters —
  `emdash — inside decoy span` (2026-08-16)
EOF
  assert_says "$box/decoyspan-indent.md" 8 'opens with a code span' \
    "a decoy span opening an indented continuation line is not an attribution"
  rule_end 7 'the found-by tail is cut outside the code spans, not inside them'

  # ── the box that lands on the line after its marker ──────────────────────────────────────────
  # Rule 2 (ticked box) is a per-line regex demanding the marker and the `[x]` on the SAME source
  # line. GFM does not ask for that: it ticks the box when the item's first rendered block is a
  # paragraph opening with `[x] `, and the marker's own line can vanish from the AST entirely —
  # an empty marker, or a link-reference definition, which emits no node. The result is a closed
  # finding rendering with a ticked box on GitHub while this sensor exits 0, on a file that looks
  # perfectly healthy. Measured against the merged sensor in the 12th adversarial round
  # (docs/handoffs/20260816-todo-enxuto/r12-caixa-partida.md), with the CommonMark AST as witness.
  #
  # Refused by name, like every other construct this file will not model — it is not a parser.
  rule_begin
  cat > "$box/splitmarker.md" <<'EOF'
# TODO

-
  [x] **a closed finding hiding behind an empty marker**

## Aberto

- [ ] **A well-formed item** — `bin/sdd:42` — why — found by `x` in mission `y` (2026-08-16)
EOF
  assert_says "$box/splitmarker.md" 8 'bare list marker' \
    "an empty list marker above the findings section"

  cat > "$box/linkrefbox.md" <<'EOF'
# TODO

- [ref]: https://example.com
  [x] **a closed finding hiding behind a link reference**

## Aberto

- [ ] **A well-formed item** — `bin/sdd:42` — why — found by `x` in mission `y` (2026-08-16)
EOF
  assert_says "$box/linkrefbox.md" 8 'bare [ ]/[x] box' \
    "a link-reference definition carrying the box on the next line"

  # The unticked twin. GitHub renders it as an OPEN task item, so it is a finding the count never
  # saw — the same hole the ticked rule had, one character away.
  #
  # ⚠️ The carrier here is the LINK REFERENCE, not the empty marker, and the asserted message is
  # the box rule's own. Written the other way — an empty marker, asserting the loose word "bare" —
  # the probe was answered by the MARKER rule and passed with the box rule narrowed to `[xX]`.
  # It survived the adversarial pass that way: a probe reading a message its neighbour also prints
  # measures the neighbour. Same defect this suite fixed in assert_says six probes at a time.
  cat > "$box/splitopen.md" <<'EOF'
# TODO

- [ref]: https://example.com
  [ ] **an open finding the counter never saw**

## Aberto

- [ ] **A well-formed item** — `bin/sdd:42` — why — found by `x` in mission `y` (2026-08-16)
EOF
  assert_says "$box/splitopen.md" 8 'bare [ ]/[x] box' \
    "an unticked box that lands on the line after its marker"

  # The SAME carrier with an uppercase tick, and the reason it is a probe of its own: the box
  # rule's class is `[ xX]`, the ticked-box rule two screens up already probes its own `X` with
  # tickedupper.md, and this branch — the one that catches a CLOSED finding hidden on a split
  # line — had none. Narrowing the class to `[ x]` left the whole selftest green in the r2
  # adversarial pass while a `[X]` carrier walked straight through, which is the fail-open this
  # sensor exists to make impossible. GitHub renders `[X]` ticked; so must this.
  cat > "$box/splitopenupper.md" <<'EOF'
# TODO

- [ref]: https://example.com
  [X] **a closed finding hiding behind an uppercase tick on the split line**

## Aberto

- [ ] **A well-formed item** — `bin/sdd:42` — why — found by `x` in mission `y` (2026-08-16)
EOF
  assert_says "$box/splitopenupper.md" 8 'bare [ ]/[x] box' \
    "an uppercase-ticked box that lands on the line after its marker"

  # The bare marker rule stopped being header-only. It was already refused INSIDE the findings
  # section; making it whole-file is what closes the carrier, and this probe is what keeps the
  # findings-section half from being deleted as a duplicate of the new one.
  cat > "$box/splitinside.md" <<'EOF'
## Aberto

-
  [x] **a closed finding inside the findings section**

- [ ] **A well-formed item** — `bin/sdd:42` — why — found by `x` in mission `y` (2026-08-16)
EOF
  assert_says "$box/splitinside.md" 8 'bare list marker' \
    "an empty list marker inside the findings section"

  # And the shapes that must NOT be swept up. A `[` opening ordinary prose is not a box, and the
  # well-formed item — whose own line carries `- [ ] ` — is not a bare box either.
  cat > "$box/notabox.md" <<'EOF'
## Aberto

- [ ] **A well-formed item** — `bin/sdd:42` — why it matters. See
  [the handoff](docs/handoffs/x.md) for the analysis. — found by `x` in mission `y` (2026-08-16)
EOF
  assert_clean "$box/notabox.md" 8 "a markdown link opening a continuation line is not a box"
  rule_end 5 'a box landing on the line after its marker is refused, not rendered'

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
  if [ "$((PROBES + PROBES_SKIPPED))" -lt 88 ]; then
    printf '  SELFTEST FAIL  only %d probe(s) accounted for (%d ran, %d skipped), expected 88\n' \
      "$((PROBES + PROBES_SKIPPED))" "$PROBES" "$PROBES_SKIPPED" >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  if [ "$RULES_REPORTED" -lt "$RULES_FLOOR" ]; then
    printf '  SELFTEST FAIL  %d rule line(s) reported, expected %d — either a rule_end call site\n' \
      "$RULES_REPORTED" "$RULES_FLOOR" >&2
    printf '                 was deleted or one of the rules above went red\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 92
  fi

  # Direct assignment, deliberately NOT through fail_rc: two independent paths from "a probe
  # failed" to "the exit status is non-zero", so neutering either one alone still reddens the run.
  if [ "$FAILS" -ne 0 ] && [ "$SELFTEST_RC" -eq 0 ]; then SELFTEST_RC=92; fi

  SELFTEST_RAN_IN_PROC=1
  [ "$SELFTEST_RC" -eq 0 ] && printf '  ok    selftest: %d probe(s), the sensor measures what it claims\n' "$PROBES"
  return "$SELFTEST_RC"
}

# check_file <file> <cap> — the real check. Kept out of the top-level flow so the selftest can
# invoke it through `--check` without recursing into itself.
check_file() {
  local file="$1" cap="$2" n_items violations

  # The coupling that makes `selftest ||` undeletable from the bare dispatch, and it is STATE and
  # not an assertion on purpose. r2 measured the hole: drop the `selftest ||` half of the `''`
  # branch and check_file alone answers `ok 74 finding(s)`, rc 0, over a healthy TODO.md — the run
  # reads identical and every probe in this file has just been unhooked. An assertion could not
  # close that, because the assertions live inside the function the same edit removes; what closes
  # it is check_file refusing to speak on the bare path about a parser nothing measured.
  # `--check` is the explicit mode and is exempt: it names its file and makes no such claim.
  if [ "$EXPLICIT_MODE" -eq 0 ] && [ "$SELFTEST_RAN_IN_PROC" -eq 0 ]; then
    printf '  FAIL  the bare path reached check_file without running the selftest — the parser\n' >&2
    printf '        below is unmeasured, so its verdict on %s means nothing\n' "$(basename -- "$file")" >&2
    return 98
  fi

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
  --check)    EXPLICIT_MODE=1; check_file "${2-$TODO}" "$CAP"; exit $? ;;
  '')         selftest || exit $?; check_file "$TODO" "$CAP"; exit $? ;;
  *)          printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac
