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
#   1. the row opens with its `|` and hands the runner exactly five columns when split on a raw
#      `|`. GFM makes the leading pipe optional and the runner reads such a row since PR #222, but
#      a reader of `|`-led lines skipped it whole, so it is refused here by name. A RAW pipe inside a
#      cell shifts Status and Commit one place and gate_EXEC starts reading a fragment of the
#      command as a status token. It is also what keeps rule 2 from failing open: with the columns
#      shifted, the Check cell this file reads is a truncation and the anchor rule would stop
#      applying in silence.
#      This rule is deliberately STRICTER than the runner and does not mirror it. `checkpoint_rows`
#      in bin/sdd rejoins GFM's `\|` by backslash parity, so an escaped pipe no longer breaks a
#      mission — but it stays refused HERE, in the kit's own checkpoints, because a Check needing a
#      pipe has a herestring form that is plainly better, and because the rejoin is a safety net for
#      what target repos write, not a licence for what this repo writes. Stricter and loud is the
#      one direction that costs nothing: the row fails, it never passes unmeasured.
#   2. a Check cell that merges stderr into stdout (`2>&1`, or any other spelling: `&>f`, `>&f`,
#      `2<&1`…, read by r2_merges, issue #269) AND greps must carry the `^  ok    ` anchor on
#      every grep that reads the merged output. Both halves of the precondition matter: without
#      a merge there is no FAIL text in the stream to confuse, and without `grep` nothing is being
#      read. Which grep reads it is rule2()'s answer (issue #258): the one whose herestring is a
#      variable a clean `NAME=$(… 2>&1)` captured, so a grep of a file owes nothing. A cell the
#      reader cannot follow keeps the cell rule: every grep anchored. A test runner's pass mark at
#      the start of the pattern (`'^ *✓ '`, issue #249) anchors like the ok prefix, on both paths.
#      And a counting grep (`-c`) of a pair `command` → `expected` whose expected value is only
#      zeros owes no anchor, on both paths (issue #272): it is green only when no line matches, so
#      never over a FAIL line its pattern matches — as long as the pair prints only its counts,
#      one zero per counting grep, so a grep that fails leaves it a word short (PR #274, round 2).
#      r2_greps decides it, pair by pair.
#   3. the rule is written where the next mission will meet it — templates/checkpoint.md and
#      agents/sdd-planner.md — so a checkpoint born tomorrow does not have to rediscover it.
#      Contract in three places, the house rule from CLAUDE.md.
#   4. the anchor it enforces IS the prefix the suite's sensors print, derived from every line of
#      theirs that opens a quoted ok prefix (a `pass()`, an inline `printf`, an `echo`, a Python
#      `print(`), counted per sensor file, rather than restated. See calibrate() for why that is
#      not decoration.
#   5. a path the Check tests with `test -e|-f|-s` (or the `[`/`[[` forms) is one its repository keeps:
#      `git check-ignore`, asked of the repo the checkpoint lives in, never of the cwd. An ignored
#      path is green on the machine that wrote it and red on a fresh clone (issue 211, measured in
#      a target repo; the kit's own checkpoints test no path today).
#   6. no row is `done` below a `blocked` one. The runner stops the line at the first blocked row,
#      so a done below it was closed outside the runner, past the stop (issue 216; no case in any
#      checkpoint when the rule was born, so it entered green).
#
# What it deliberately does NOT measure: whether the expected value beside the arrow is the right
# one, whether the Check actually exercises the increment, or whether a Check with no grep at all
# is strong. All three are human judgement on the diff. Rule 2 stops the one regression that rots
# in silence, which is the half prose already lost twice.
#
# One narrower question about the expected value IS answered, but never by the scan and never by
# run-all.sh: `--red <checkpoint>` runs the Check of every `pending` row and refuses the one that
# is already green at HEAD (issue 92). It executes text a model wrote, so it is a tool the planner
# runs with the human present before closing PLAN-AUTO — never a gate, and the runner never calls
# it. gate_PLAN cannot run it either: derive_phase calls gate_PLAN on every derivation, so with
# I1 done its Check turns green and the mission would fall back to PLAN — an unsatisfiable gate.
# What --red proves is "not green", never "red for the right reason": `cmd; echo $?` printing 127
# for a command that does not exist yet is red to it. The planner writes that before into the plan,
# where a person reads it. A Check that prints NOTHING is refused, whatever its rc: the form
# `test -f x && echo yes` has no before to write down, and a command that was never found (rc 127)
# looks exactly like one that ran and said no. Only the strict form `command` → `expected` runs —
# one pair per cell; two pairs, or prose after the arrow, are refused as unmeasurable.
# DECLARED LIMITS of --red, both measured on I0 and I6 of 20260918-a-excecao-do-chapeu-e-o-genero-
# diferido at its plan commit (79dd4df). The expected is compared with the WHOLE stdout, blanks
# folded: a Check whose expected is only the tail of what it prints (`sdd adr check …; echo rc=$?`
# → `rc=0`, over an ok line) reads red here and green to a person — the planner writes the noise to
# /dev/null. And a Check that reads OUTSIDE its repository (`~/repos/<other>/…`) is measured against
# today's world, not HEAD's: I6 read green in 2026-10 and red on the day it was planned.
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
#        tests/check-checkpoint.sh --red <checkpoint>
#                                               (run the Check of every pending row from the root of
#                                                the checkpoint's repository; refuse one already green,
#                                                one outside the strict form, one that prints nothing.
#                                                Run by the planner, never by run-all.sh)
#
# ── Known limits, stated so nobody re-discovers them as surprises ──────────────────────────────
# NOT measured: a Check that reads a sensor WITHOUT merging stderr and greps for the assertion
# text on stdout alone. That one is already correct — FAIL never reaches the stream it reads —
# but it is correct by the redirection it omits rather than by the anchor, so a later edit adding
# `2>&1` for convenience turns it blind and this file catches it only from that moment on.
#
# NOT measured either: a grep spelled `rg` or `awk /.../`. `egrep` is read as `grep -E` and `fgrep`
# as `grep -F`, never anchored: the cell rule counted both by substring while the reader saw
# neither, and refused an anchored `egrep` the base accepted (Codex on PR #267, fourth round). A
# grep's words are read the way bash hands them over (r2_word, issue #270), which is as much of a
# shell parser as the rule needs: every generalisation tried on the neighbouring sensors by regex
# fired on legitimate lines first.
#
# DECLARED LIMITS of rule 2's reader (issue #258), both CLOSED: a merged variable assigned again in
# the same cell stays tainted, so a grep of the new value still owes the anchor; and a herestring
# that is not exactly one variable (`<<< "$o$p"`) sends the whole cell back to the cell rule. The
# capture pass honours quotes, nested parens and `\` escapes and nothing else of the shell grammar:
# every shape it does not follow reads as a leak of the stream, and the cell keeps the cell rule. A
# name it never sees written — `${!v}`, a nameref (`declare`, `typeset`, `local`), an `eval` — keeps
# the cell rule too: the three read the stream with no rule at all until the final review of lote 8.
# One grep is anchored by r2_grep_anchored, on both paths, over the WORDS r2_grep_at reads (issue
# #270, lote 9): each word's value with quotes and escapes removed and its glued parts joined, so a
# quoted option is the option it spells (`'-v'`, `"-F"`) and an anchor written with escapes
# (`^\ \ ok…`) anchors. A redirection and its target are no word, and none of grep's argv: a target
# named like an anchor was a pattern to the reader before (`2>'^  ok    x'`, found by its sabotage
# pass). An escaped `\$'` is a literal dollar before a plain quote, and anchors since lote 9: it was
# refused with the ANSI-C quote. Over the words, the argv is read as GNU grep 3.11's getopt_long
# reads it (r2_argv), by a table copied from the binary (R2_LONG and its neighbours): an option
# anywhere before `--`, a long one by any prefix that resolves (`--fixed`, `--inv`, `--reg=`; Codex
# on PR #267, fourth round), an option's argument glued or in the next word; the patterns are the
# arguments of `-e`/`--regexp` or, with none, the first operand, and every other operand is a FILE.
# Only a pattern owes the anchor, and every pattern does. Refused, as unreadable: a letter or a name
# the table lacks, an ambiguous prefix, an argument missing or given to an option that takes none,
# and a `-X` matcher that is not literally one grep knows (grep refuses all four), and an option
# whose name or letters hold an expansion (the reader cannot see it). Four identities disarm the
# caret, refused with it: `F` (`-F`, `--fixed-strings`, `--fixed-regexp`, `-X fgrep`, the fgrep
# command: a literal caret; Codex on PR #267), `v` (every other line counts), `z` (one record, so
# `^` opens only the input and `.` crosses lines) and `f` (patterns from a file). A pattern holding
# an ANSI-C quote `$'…'` never anchors, since its `\n` hands grep a second pattern (the same PR,
# third round), and an operand holding one is refused, pattern or FILE: it is never decoded, and
# `$'-v'` is an option to grep (measured).
# DECLARED, lote 9: a word that opens with an expansion, or holds an unquoted one, a glob, a brace
# expansion or a leading `~`, never anchors (bash may split or rename it); a double-quoted pattern
# anchors on its literal prefix before the first expansion (`"^  ok    $k finding(s)"`, the shape
# two of the kit's checkpoints write), although the expansion could carry a newline or a `\|`. A
# word that opens with an expansion is an operand, although its value could be an option, and that
# fails OPEN: the kit's own control reads a FILE that way (`grep -c '^  ok    x' "$l"`, F1 of
# 2026-08-16). The table is GNU grep 3.11 with no POSIXLY_CORRECT in the environment: with it set,
# the options end at the first operand, and another grep (BSD, busybox, ugrep) reads its argv by
# its own rules. A grep's words are skipped once read, so a FILE or a matcher named `grep` is no
# second grep; a grep that runs inside one of those words is read by nobody, and when it reads the
# merged stream the cell falls back to the cell rule, whose count takes `grep` by substring and
# still owes it the anchor. That count is the closed side: a FILE named `grep` in a cell the reader
# cannot follow is one more grep to anchor.
#
# DECLARED LIMITS of the merge (issue #269, lote 9). r2_merges reads the text raw, so a `&>` or a
# `>&` inside quotes counts as a merge, and so does `>/dev/null 2>&1`, which sends both streams to
# the null device: both CLOSED. A merge through a third descriptor (`3>&1 2>&3`, or `2>&10` after an
# `exec 10>&1`) is not followed, and fails OPEN: `2>&` onto any descriptor but 1 merges nothing
# here (the substring test before it read `2>&10` as a merge by accident). The null device is the
# exact word `/dev/null` before a blank, `;`, `&`, `)`, a backtick or the end of the text; quoted
# (`"/dev/null"`) or as the head of a longer path it is a file, and a merge.
# The stderr redirected onto a path of the stdout (Codex on PR #274) is read for `/dev/stdout`,
# `/dev/fd/1` and descriptor 1 of any entry of /proc (`/proc/<anything with no blank>/fd/1`: self,
# thread-self, `$$`, a pid, a task; round 3), quotes removed, before a blank, `;`, `&`, `)`, `|`, a
# backtick or the end of the text. A pid that is not the stdout's still reads as a merge: CLOSED.
# Not followed, and OPEN: a target known only at run time (`2>$f`, `2>"$log"`), which no reader of
# the text decides; and any other path or spelling that resolves to the stdout (a symlink,
# `/dev/./stdout`, a backslash, `$'…'`). The TODO.md item of round 3 lists them with the rest.
# A `2` after a digit (`12>/dev/stdout`) is another descriptor and merges nothing, while `12>&1`
# still reads as a merge (CLOSED). `2>|` and a `|` after the path reach no cell, because a `|`
# splits the row before rule 2 reads it, so their probes call r2_merges in process.
#
# DECLARED LIMITS of the zero pair (issue #272, lote 9). The exemption is admitted positively: the
# grep's count has to be what its pair prints, and every condition r2_greps and r2_counts_zero name
# has to hold, the options by a list of what enters (R2_ZERO_OPTS). And the pair prints nothing else
# (Codex on PR #274, round 2): every command at the top of its command is a counting grep or one
# assignment (a name, `=` and one word), each ending at a `;`, a `&&`, a `||` or the span's end, and
# the expected value holds exactly one zero per counting grep. A grep that fails (`grep -c '['`)
# prints no count, so the pair's output is then a word short of it, and red. Nothing the pair holds
# runs a command either (round 3, r2_quiet): the value of each assignment, and each word and each
# redirection target of each counting grep, is `lit`, or free of `$`, backticks, `<(` and `>(`, or
# one name read whole, or one `$(…)` alone with no `/proc/`, `<(` or `>(` inside — `x=>(echo 0)`, a
# FILE `>(echo 0)` and `x=$(echo 0 >/proc/$$/fd/1)` printed the zero. Refused, CLOSED: a pair whose
# expected value mixes a count and a zero (`echo "$a $b"` → `3 0`: following the `$(…)` up to the
# `echo` would grow the reader again; decision 3 of that mission); a count captured and printed
# again (`echo "$(grep -c a <<< "$o")"` → `0`), which is no grep at the top of the command; every
# other command at the top — `echo`, `printf`, `cd` (it prints the directory CDPATH resolves), a
# command whose stdout goes to a file (`bash t.sh > out 2>&1`: telling that path from a spelling of
# the stdout is the open reading the merge paragraph above declares), a redirection or an assignment
# before the grep (`>f grep`, `LC_ALL=C grep`), a compound command, `exec` —; a command a lone `&`
# sends to the background (an assignment there never reaches the grep after it); and every value
# r2_quiet does not name, harmless or not (`${y:-0}`, `$((1+2))`, `"$(…)"`, text around a `$(…)`). A
# `||` reaches no cell (rule 1), so its probes call rule2 in process; a cell holds no newline, so
# none is read as an end. Not followed, and OPEN, as for every grep this rule reads: a name that
# renames grep before it (a PATH, or a function whose body is a subshell, `grep () (echo 0)`), which
# no Check of the kit or of the two target repos writes. The code spans are read backtick to
# backtick, as the cells write them; a span opened by two backticks reads as two empty ones (one
# Check cell of the corpus writes one, in its prose, around a literal).
#
# DECLARED LIMITS of the pass mark (issue #249, lote 8). Only U+2713 counts, the mark the two
# measured runners print (see PASS_MARK); `✔` (U+2714) and every fail mark do not. A runner that
# printed `✓` at the start of a FAILURE line would fool the rule, and none measured does. The
# runner's summary lines (`Tests  N passed`, ` N passed`) are no anchor by decision 5 of that
# mission: a list of phrases per runner is a list nobody keeps. Between the caret and the mark only
# blanks are read, each with or without a star (` *`), so `'^[[:space:]]*✓ '` or `'^\s*✓ '` is
# refused although it anchors — closed, and the message names the shape that passes. A star with
# no blank before it (`'^*✓ '`) is refused too: in an ERE or a PCRE it may quantify the caret away.
#
# NOT measured either: whether the anchor's assertion text matches an assertion that exists. A
# Check anchored on `^  ok    ` for a sentence no sensor ever prints returns 0 instead of 1 and
# fails honestly — wrong answer, not a silent green — which is the direction that costs nothing.
#
# DECLARED LIMITS of rule 5 (decision 9 of 20261003-lote-3-a-catraca-desce, and the final review
# of that branch for the last two). A Check that asserts the ABSENCE of an ignored path
# (`test -f x; echo $?` -> `1`) is refused all the same: a false positive, with no case in any
# checkpoint today. `git check-ignore` also reads the user's global ignore file
# (~/.config/git/ignore exists on the machine this rule was written on), so the verdict depends on
# the machine — exactly as the verdict of `git add` does, which is the step this rule stands in
# for. A Check that GENERATES an ignored artifact and then tests it (`<cmd> && test -f
# .sdd/cache/x`) is refused too, although it is green on every machine: the rule reads the test,
# not what ran before it. And a path is resolved against the repo's top level, so
# `cd app && test -f x` asks about `x`, not `app/x`. The four fail CLOSED or not at all; none
# certifies an ignored artifact. (`[[ -f x ]]` was the fifth, and it failed OPEN — read since.)
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
# Rule 3 (the pipe ban) added eight more in a later round, all dead: each half of the literal pair
# dropped on its own, pipe_rule always returning 0, each of the two call sites deleted, the doc
# floor lowered to zero, and the `ok rule:` line removed. That round also found PROBE_FLOOR sitting
# one below the real probe count — deleting a probe landed exactly on the floor and survived — so
# the floor is tight now and a deleted probe is caught. All eight DELETED something; the four that
# SHORTEN a literal instead (PIPE_MECH "aw", "awk" or "a", PIPE_ESCAPE '\') survived until issue
# #71 gave each literal a hand-written near-miss doc, and now die too.
#
# Rule 2's reader added 19 more (lote 8, 2026-10-15), all dead. Two of them first survived and
# became probes: the single quotes of the capture pass, whose absence let a `$(` inside quotes
# swallow a real merge into a file, and the `NAME="$(…)"` form.
#
# The pass mark added 18 more the same day, all dead. One first survived and became a probe: the
# cell rule's count taking every `'^` without asking the predicate.
#
# The final review of lote 8 reproduced two fail-opens (a name the reader never sees written, and a
# second pattern riding on one grep's anchor) and the fix added 18 more sabotages, all dead. Four
# first survived and became probes: the unquoted `-e` glued to its pattern, the herestring's operand
# read as a pattern and as an option, and the words past the herestring left unread.
# Codex on PR #267 reproduced a third, `-F` (and `-v` with it, declared until then): four more
# sabotages, one per spelling, all dead.
#
# The merge spellings (issue #269, lote 9) added 34 more, all dead: each branch of r2_merges, each
# terminator of the null device, each of its three call sites back to the `2>&1` literal, the
# `ok rule:` line and one probe deleted. Two first survived and became probes: the blank after the
# null device, and an operator at the first character of the text, which bash's offset -1 would
# read as preceded by the text's last character.
#
# The words (issue #270, lote 9) added 130 more, all dead: each branch of r2_dollar, r2_word,
# r2_grep_at, r2_grep_anchored and r2_glued_anchored, the `ok rule:` line, one probe, one line of
# the word table, and wd_tok's comparison and negative control. Two die by the suite's deadline
# (rc 124), not by a probe: with `<` or `>` read as no operator the reader stops advancing. One
# first survived and became a probe: the ANSI-C quote that no longer refused, which only a quoted
# word that is no pattern shows (`$'-v'`). Listing them first found four holes, closed the same way
# (R2_END in no probe, wd_tok without a negative control, a glued `dq` or `raw` pattern, a second
# `--regexp` in its own word), and a probe found one defect of the reader before any sabotage ran:
# an expansion left open inside double quotes ended its word one character in.
#
# The argv (issue #270, lote 9) added 73 more over two rounds, each anchored on code with its count:
# each branch of r2_long, r2_opt, r2_argv and r2_grep_anchored, each of the four disarming
# identities, the skip in r2_greps, the `F` that fgrep and `-X fgrep` imply, twelve entries of the
# table, gt_argv's comparison and negative control, the `ok rule:` line and one probe. In the last
# round 71 of 72 died; the live one is the probe floor lowered on its own, which no floor sees,
# being a minimum (the probe deleted beside it dies, rc 92). Two first survived: an option the
# reader cannot read after an `-e` had already given a pattern, which became a probe, and the reset
# of the ambiguity when the exact name wins, which no order of the table reaches, and was removed:
# the failure it decided is the closed one. Three members of the family were found while planning,
# not by a sabotage: `--fixed-regexp`, a hidden synonym of `-F`; `-z`, under which `.*` crosses
# lines; and `-X fgrep`, refused before by accident, the reader taking its `fgrep` for a second
# grep.
#
# The zero pair (issue #272, lote 9) added 84 more, each anchored on code with its count: the pair
# read for the whole cell, "only zeros" read as "some zero", each condition of the exemption dropped
# (the top, the redirected stdout, `-c`, `lit`, the first word and each way into it, the compound
# words), the list turned into "any option but `v`", every entry of R2_ZERO_OPTS dropped and seven
# admitted, the exemption on one path only (each path), each keyword dropped, read inside a capture,
# mid-word, as a prefix or up to a blank, each branch of r2_pairs and r2_zero_pair, zr_opts's
# comparison and negative control, the message, the four fixtures back to `0`, the `ok rule:` line
# and one probe. 83 died; the live one is the probe floor lowered on its own, a minimum. One first
# survived and changed a fixture: the backtick that opens a span was tested only behind a `;` of
# the prose between two pairs, which opened the command all by itself.
#
# Codex on PR #274 (round 1) reproduced one more merge, the stderr onto a path of the stdout
# (`o=$(sensor 2>/dev/stdout)`), which the cheap filter of r2_merges turned away. The fix added 39
# sabotages: each path, operator and terminator, the quotes, the `2` and the digit before it, the
# filter, mg_merges and its negative control, one probe of each kind. 37 died (one by the
# selftest's rc 91 alone). The two alive cannot die: the floor lowered on its own, a minimum, and
# the negative control's test forced false, which decides something only once mg_merges is broken.
# One first survived and moved a control: `1>/dev/stdout` alone never passed the filter, so `1>`
# read beside `2>` went unseen.
#
# Codex on PR #274 (round 2) reproduced a pair that printed a zero no grep counted: in `grep -c '['
# <<< "$o"; echo 0` → `0` the grep fails and prints nothing, the echo prints the `0`, and --check
# called the row non-blind. The exemption now reads the pair whole (r2_assign_at, r2_ends_clean and
# the zg/zb count of r2_greps), and the reader of compound words (cx) left: every compound command
# opens a command at the top, which is no assignment, so with the new rule deleting it left every
# probe green, and the one world where it still decided, `x=if`, it refused for nothing. A lone `&`
# was thought to refuse already, and did not: the grep before it stayed exempt (measured on
# a25cba6). 60 sabotages, each anchored on code with its count: 56 died (zk and zp left unreset by
# an unbound variable, their initialised variants by a probe). Alive: the floor lowered on its own,
# a minimum; the negative control's test forced false and zr_rule2's strict guard, which decide
# something only once the helper is broken; and the inline grep test put back, the same three lines
# r2_grep_word holds. Seven first survived. Six became probes: the assignment ending at a lone `&`,
# the anchored `-m 0` grep, the anchored count counted twice, the q of a file grep, the stale zp,
# and the grep word read unbounded, which had no probe at a25cba6 either. The stale zk changed a
# fixture: the grep inside the capture now ends at a `;`, as the closing paren had hidden it. On the
# targets 105 → 106: the R1 of breadcrumb-numero-cotacao (sales_quote) reads two counting greps
# against one `0`.
#
# Codex on PR #274 (round 3) reproduced two more. A stderr sent to `/proc/thread-self/fd/1` merges
# like `/proc/self/fd/1`, and the regex knew only the second: now descriptor 1 of any /proc entry is
# a merge, the closed side. And `x=>(echo 0)` was a pure assignment by its form (round 2) while its
# process substitution printed the zero; so did `x=$(echo 0 >/proc/$$/fd/1)`, and a FILE `>(echo 0)`
# of the counting grep itself. r2_quiet now names, positively, the words that run nothing, and both
# the value of an assignment and every word and target of a counting grep have to be one. On the 36
# targets the --check output stayed byte for byte the same (106). 34 sabotages, each anchored on
# code with its count: 31 died. Alive: the floor lowered on its own; the negative control's test of
# zr_quiet forced false; and `+` read as `*` in the /proc path, which adds only `/proc//fd/1`, a
# path that names no file. One first survived and became a word of zr_quiet: the shape test of (c),
# which alone tells `a$(echo 0))` from a capture.
#
# Exit codes, one per cause, FIRST failure wins:
#    0  clean                        1  a checkpoint has violations
#   89  no temp dir (probes never ran)      90/91/92  a selftest probe failed
#   93  a floor was breached (the scan was vacuous; for --red, no pending row)
#   94  a checkpoint named on the command line is missing or unreadable
#   95  --red: the checkpoint is not inside a git work tree, so there is no root to run from
#   96  unknown option

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"

SELF_PATH="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The anchor, written ONCE and read by three things: the cell rule, the two doc assertions, and
# the probes. Written twice it would be the enum-in-three-places failure the house rule forbids —
# widen the cell rule to accept three spaces and the doc assertion would go on certifying four.
OK_ANCHOR='^  ok    '
# The pass mark of a test runner (issue #249): U+2713 and a blank, bytes e2 9c 93 20. It is the
# mark both runners measured in the target repos print before a case that passed — vitest 3.2.7
# (` ✓ ` passed, ` × ` failed, on stdout) and the Playwright list reporter (`  ✓   1 [chromium] › …`
# and `  ✘   8 …`, in lighthouse_project/.sdd/logs/). Read by r2_anchored alone, after `^` and
# blanks. The blank is part of it: a quantifier on the mark (`'^ ✓* x'`) matches every line that
# opens with a blank, `  FAIL  ` included.
PASS_MARK='✓ '

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

# ── rule 2's reader: which greps read the merged output (issue #258) ───────────────────────────
#
# A merge in the cell (any spelling, r2_merges) used to put EVERY grep of it under the anchor, the
# one that reads a file the sensor never wrote to included. The reader below asks the narrower
# question the rule is about: which grep reads the variable the merged output went into? A NAMED
# capture `NAME=$(…)` (or `NAME="$(…)"`) whose text merges and carries no `grep` taints NAME; a
# grep whose herestring is exactly `$NAME` or `${NAME}` (quoted or not) of a tainted name owes the
# anchor, and no other does.
#
# It is no shell parser, so it falls back to the cell rule — every grep anchored, which is closed —
# whenever it cannot follow the stream: a merge left outside the clean captures (a file, a `<(…)`,
# an anonymous `$(…)`, a capture that also greps), a tainted name read anywhere but a grep
# herestring, or a quote or a capture that never closes. Each fallback has a probe in the selftest.
# Results are published in R2_* and never through a command substitution (see the counters below).
# Byte-wise on purpose (`LC_ALL=C`): every character it acts on is ASCII, and indexing a UTF-8
# string costs a walk from its start.
R2_STRICT=0; R2_G=0; R2_A=0; R2_AA=0; R2_HSREFS=0; R2_END=-1; R2_HS=''; R2_RDOUT=0
R2_TAINTED=(); R2_WV=(); R2_WP=(); R2_WK=()
R2_W_V=''; R2_W_K=lit; R2_W_E=0; R2_X=0
# What stands for an expansion inside a word's value: U+0001, which no checkpoint cell writes.
R2_MARK=$'\001'
# Regexes live in variables: written inline, `[[ =~ ]]` would hand regcomp a backslash per quoted
# character, and inside a bracket expression that backslash is one more literal.
R2_VAR_RE='^[$]([A-Za-z_][A-Za-z0-9_]*)$'
R2_BRACED_RE='^[$][{]([A-Za-z_][A-Za-z0-9_]*)[}]$'
R2_NAME_RE='(^|[[:space:];&|(`!{])([A-Za-z_][A-Za-z0-9_]*)$'
R2_INDIRECT_RE='(^|[^A-Za-z0-9_])(eval|declare|typeset|local)([[:space:]]|$)'
R2_FD_ONE_RE='^0*1([^0-9]|$)'
R2_NULL_RE='^/dev/null([[:space:];&)`]|$)'
# The stderr onto a path of the stdout, read on the text with its quotes removed (PR #274).
R2_STDOUT_RE='[^0-9]2(>>|>[|]|<>|>)[[:blank:]]*(/dev/stdout|/dev/fd/1|/proc/[^[:space:]]+/fd/1)([[:space:];&)|`]|$)'
# A redirection operator with the descriptor before it, if any (`&>` takes none). POSIX matching is
# leftmost-longest, so `<<<` wins over `<`. A here-document's `<<` reads as two `<`, and `&>>` as `&>`
# and `>`: the same words, the same stdout.
R2_REDIR_RE='^([0-9]*)(<<<|<>|<&|<|>>|>&|>[|]|>)'

# r2_merges <text> — rc 0 when the text sends stderr where the stdout goes, in any spelling bash
# takes (issue #269: twelve besides `2>&1`, measured on bash 5.2.21). Called, never read through
# `$(…)`. The text is read raw, quotes not honoured, like the literal it replaced: a `&>` inside
# quotes counts, which is the closed side.
#   - `2>&` or `2<&` onto a descriptor merges when the descriptor is 1 (`1`, `01`, `1-`), and so
#     does a target that is no descriptor at all (`"1"`, `$one`): known only at run time;
#   - `&>` and `&>>` send both streams to their file, whatever its name (`&>1` writes a file `1`);
#     `>&` and `1>&` do the same when the target is no descriptor (`>&f`, never `>&2` or `>&-`);
#   - those four except into the null device, spelt exactly `/dev/null`: no grep reads it;
#   - `2>`, `2>>`, `2>|` or `2<>` onto a path of the stdout (`/dev/stdout`, `/dev/fd/1`, or
#     `/proc/<anything with no blank>/fd/1`), the `2` after no digit, quotes removed (R2_STDOUT_RE).
# The leading blank makes the character before the operator safe to read at index 0. The case below
# is the cheap filter: it names an operator of every form, or the form escapes it (PR #274).
r2_merges() {
  local LC_ALL=C
  local t=" $1" n i j op w
  n="${#t}"
  case "$t" in *'>&'* | *'<&'* | *'&>'* | *'2>'* | *'2<>'*) ;; *) return 1 ;; esac
  [[ "${t//[\"\']/}" =~ $R2_STDOUT_RE ]] && return 0
  for ((i = 1; i + 1 < n; i++)); do
    op="${t:i:2}"
    case "$op" in '>&' | '<&' | '&>') ;; *) continue ;; esac
    j=$((i + 2))
    [ "$op" = '&>' ] && [ "${t:j:1}" = '>' ] && j=$((j + 1))
    while [[ "${t:j:1}" == [[:blank:]] ]]; do j=$((j + 1)); done
    w="${t:j}"
    if [ "$op" = '&>' ]; then
      [[ "$w" =~ $R2_NULL_RE ]] || return 0
    elif [[ "${w:0:1}" == [0-9-] ]]; then
      [ "${t:i-1:1}" = 2 ] && [[ "$w" =~ $R2_FD_ONE_RE ]] && return 0
    elif [ "${t:i-1:1}" = 2 ]; then
      return 0
    elif [ "$op" = '>&' ]; then
      [[ "$w" =~ $R2_NULL_RE ]] || return 0
    fi
  done
  return 1
}

# r2_close <text> <i> — the index of the `)` closing the `$(` whose `(` sits at i-1, with quotes
# and nested parens honoured; -1 when it never closes. Published in R2_END.
r2_close() {
  local LC_ALL=C
  local t="$1" i="$2" n="${#1}" c sq=0 st=P
  R2_END=-1
  while [ "$i" -lt "$n" ]; do
    c="${t:i:1}"
    if [ "$sq" -eq 1 ]; then
      [ "$c" = "'" ] && sq=0
      i=$((i + 1)); continue
    fi
    if [ "${st: -1}" = D ]; then
      case "$c" in
        '\') i=$((i + 2)); continue ;;
        '"') st="${st%?}" ;;
        '$') if [ "${t:i+1:1}" = '(' ]; then st="${st}P"; i=$((i + 2)); continue; fi ;;
      esac
      i=$((i + 1)); continue
    fi
    case "$c" in
      '\') i=$((i + 2)); continue ;;
      "'") sq=1 ;;
      '"') st="${st}D" ;;
      '(') st="${st}P" ;;
      ')') st="${st%?}"; if [ -z "$st" ]; then R2_END="$i"; return 0; fi ;;
    esac
    i=$((i + 1))
  done
  return 0
}

# r2_dollar <text> <i> — the `$` at i outside single quotes: R2_X is the index past the expansion it
# opens (`$(…)`, `${…}`, `$name`, `$1`, `$?`…), i+1 when it opens none (a literal dollar), and -1
# when the expansion never closes. `$'…'` and `$"…"` are the caller's: only an unquoted one is a quote.
r2_dollar() {
  local LC_ALL=C
  local t="$1" i="$2" n="${#1}" j depth=1 r
  case "${t:i+1:1}" in
    '(') r2_close "$t" $((i + 2)); R2_X=-1; [ "$R2_END" -lt 0 ] || R2_X=$((R2_END + 1)) ;;
    '{') j=$((i + 2))
         while [ "$j" -lt "$n" ]; do
           case "${t:j:1}" in
             '{') depth=$((depth + 1)) ;;
             '}') depth=$((depth - 1)); [ "$depth" -eq 0 ] && break ;;
           esac
           j=$((j + 1))
         done
         R2_X=-1; [ "$j" -ge "$n" ] || R2_X=$((j + 1)) ;;
    [A-Za-z_]) r="${t:i+1}"; r="${r%%[!A-Za-z0-9_]*}"; R2_X=$((i + 1 + ${#r})) ;;
    [0-9@*#?\$!-]) R2_X=$((i + 2)) ;;
    *) R2_X=$((i + 1)) ;;
  esac
}

# r2_word <text> <i> — the shell word that starts at i, read as bash hands it to the command: its
# value (R2_W_V: quotes and escapes removed, R2_MARK for each expansion), its class (R2_W_K) and the
# index past it (R2_W_E). It ends at an unquoted blank, `;`, `&`, `|`, newline, backtick or `)`, or
# at the `<` or `>` of a redirection. The classes, strongest first:
#   ansi  an ANSI-C quote `$'…'`, whose `\n` hands grep a second pattern (Codex on PR #267);
#   raw   an unquoted expansion (`$x`, `${x}`, `$(…)`), a glob (`*`, `?`, `[`), a brace expansion
#         (a `{` with `,` or `..` before its `}`), a leading `~`, a process substitution `<(…)`,
#         a bare `(…)`, or a quote or expansion that never closes: bash may split or rename it;
#   dq    an expansion inside double quotes (`"$x"`, `"${x}"`, `"$(…)"`, a backtick): one word,
#         whose value is known up to it;
#   lit   only literal parts: unquoted text with `\x` read as `x`, `'…'` verbatim, and the text of
#         `"…"` with `\$`, `` \` ``, `\"` and `\\` read as the character they escape.
r2_word() {
  local LC_ALL=C
  local t="$1" i="$2" s="$2" n="${#1}" c d v='' k=lit
  while [ "$i" -lt "$n" ]; do
    c="${t:i:1}"
    case "$c" in
      ' '|$'\t'|';'|'&'|'|'|$'\n'|'`'|')') break ;;
      '<'|'>')
        [ "${t:i+1:1}" = '(' ] || break
        r2_close "$t" $((i + 2)); v+="$R2_MARK"; [ "$k" = ansi ] || k=raw
        if [ "$R2_END" -lt 0 ]; then i="$n"; break; fi
        i=$((R2_END + 1)) ;;
      '\')
        d="${t:i+1:1}"; v+="${d:-\\}"; i=$((i + 2)) ;;
      "'")
        d="${t:i+1}"
        case "$d" in
          *"'"*) d="${d%%"'"*}"; v+="$d"; i=$((i + ${#d} + 2)) ;;
          *) v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; i="$n"; break ;;
        esac ;;
      '"')
        i=$((i + 1))
        while :; do
          if [ "$i" -ge "$n" ]; then v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; break 2; fi
          c="${t:i:1}"
          case "$c" in
            '"') i=$((i + 1)); break ;;
            '\') d="${t:i+1:1}"
                 case "$d" in
                   '$'|'`'|'"'|'\') v+="$d"; i=$((i + 2)) ;;
                   *) v+='\'; i=$((i + 1)) ;;
                 esac ;;
            '`') d="${t:i+1}"
                 case "$d" in
                   *'`'*) d="${d%%'`'*}"; v+="$R2_MARK"; [ "$k" = lit ] && k=dq; i=$((i + ${#d} + 2)) ;;
                   *) v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; break 2 ;;
                 esac ;;
            '$') r2_dollar "$t" "$i"
                 if [ "$R2_X" -lt 0 ]; then v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; i="$n"; break 2; fi
                 if [ "$R2_X" -eq $((i + 1)) ]; then v+='$'; else v+="$R2_MARK"; [ "$k" = lit ] && k=dq; fi
                 i="$R2_X" ;;
            *) v+="$c"; i=$((i + 1)) ;;
          esac
        done ;;
      '$')
        case "${t:i+1:1}" in
          "'") v+="$R2_MARK"; k=ansi; i=$((i + 2))
               while [ "$i" -lt "$n" ]; do
                 case "${t:i:1}" in '\') i=$((i + 2)) ;; "'") break ;; *) i=$((i + 1)) ;; esac
               done
               i=$((i + 1)) ;;
          '"') i=$((i + 1)) ;;
          *) r2_dollar "$t" "$i"
             if [ "$R2_X" -lt 0 ]; then v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; i="$n"; break; fi
             if [ "$R2_X" -eq $((i + 1)) ]; then v+='$'; else v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; fi
             i="$R2_X" ;;
        esac ;;
      '*'|'?'|'[')
        v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; i=$((i + 1)) ;;
      '{')
        d="${t:i+1}"; d="${d%%[[:blank:];&|)\`<>]*}"
        case "$d" in
          *'}'*) d="${d%%'}'*}" ;;
          *) d='' ;;
        esac
        case "$d" in
          *,*|*..*) v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; i=$((i + ${#d} + 2)) ;;
          *) v+='{'; i=$((i + 1)) ;;
        esac ;;
      '~')
        if [ "$i" -eq "$s" ]; then v+="$R2_MARK"; [ "$k" = ansi ] || k=raw; else v+='~'; fi
        i=$((i + 1)) ;;
      '(')
        r2_close "$t" $((i + 1)); v+="$R2_MARK"; [ "$k" = ansi ] || k=raw
        if [ "$R2_END" -lt 0 ]; then i="$n"; break; fi
        i=$((R2_END + 1)) ;;
      *) v+="$c"; i=$((i + 1)) ;;
    esac
  done
  R2_W_V="$v"; R2_W_K="$k"; R2_W_E="$i"
}

# r2_quiet <word> <class> — the shell word, as written, runs no command when bash expands it (PR
# #274, round 3), so nothing it holds prints to the stdout the pair is read from. Written by what
# enters: its class is `lit` (r2_word: literal parts only, a `$` inside single quotes too), or its
# text (a) holds no `$`, backtick, `<(` or `>(`; (b) is one name read whole, `$name` or `"$name"`;
# or (c) is one `$(…)` and nothing around it, whose text holds no `/proc/` (`>/proc/$$/fd/1` in a
# capture writes to the shell outside it), `<(` or `>(`, and is no arithmetic `$((…))`. The rest is
# the closed side: `${…}`, a second substitution or text around one, `"$(…)"`, a process
# substitution anywhere. r2_close publishes R2_END on the way: a caller reads its own after.
R2_QUIET_NAME_RE='^([$][A-Za-z_][A-Za-z0-9_]*|"[$][A-Za-z_][A-Za-z0-9_]*")$'
r2_quiet() {
  local w="$1"
  [ "$2" != lit ] || return 0
  case "$w" in *'$'* | *'`'* | *'<('* | *'>('*) ;; *) return 0 ;; esac
  [[ "$w" =~ $R2_QUIET_NAME_RE ]] && return 0
  case "$w" in '$(('*) return 1 ;; '$('*')') ;; *) return 1 ;; esac
  case "$w" in *'/proc/'* | *'<('* | *'>('*) return 1 ;; esac
  r2_close "$w" 2
  [ "$R2_END" -eq $((${#w} - 1)) ]
}

# r2_grep_at <text> <i> — the grep command whose words start at i, read the way bash hands them
# over: where it ends (R2_END: the first `;`, `&`, `|`, newline or backtick outside a word, or the
# `)` closing the paren it sits in), its words in order — each one's value (R2_WV), the literal
# prefix of that value before its first expansion (R2_WP) and its class (R2_WK, see r2_word) —, its
# herestring (R2_HS: the variable name when the operand is exactly one variable, `?` when it is
# anything else, empty when there is none), and whether a redirection sends grep's STDOUT elsewhere
# (R2_RDOUT: `>`, `>>`, `>|`, `>&`, `&>`, or any operator on descriptor 1). A redirection —
# its descriptor, its operator and its target, glued or in the next word — is no word: grep never
# sees it. R2_QUIET is 1 when every word and every target runs nothing (r2_quiet). Called, never
# read through `$(…)`, like every reader here.
r2_grep_at() {
  local LC_ALL=C
  local t="$1" i="$2" n="${#1}" c fd op w end="${#1}"
  R2_WV=(); R2_WP=(); R2_WK=(); R2_HS=''; R2_RDOUT=0; R2_QUIET=1
  while [ "$i" -lt "$n" ]; do
    c="${t:i:1}"
    case "$c" in
      ' '|$'\t') i=$((i + 1)); continue ;;
      ';'|'|'|$'\n'|'`'|')') end="$i"; break ;;
      '&') if [ "${t:i+1:1}" != '>' ]; then end="$i"; break; fi ;;
    esac
    fd=''; op=''
    if [ "${t:i:2}" = '&>' ]; then
      op='&>'
    elif [[ "${t:i}" =~ $R2_REDIR_RE ]]; then
      fd="${BASH_REMATCH[1]}"; op="${BASH_REMATCH[2]}"
      case "$fd$op" in '<'|'>') [ "${t:i+1:1}" = '(' ] && op='' ;; esac
    fi
    if [ -z "$op" ]; then
      r2_word "$t" "$i"
      r2_quiet "${t:i:R2_W_E-i}" "$R2_W_K" || R2_QUIET=0
      R2_WV+=("$R2_W_V"); R2_WP+=("${R2_W_V%%"$R2_MARK"*}"); R2_WK+=("$R2_W_K")
      i="$R2_W_E"; continue
    fi
    i=$((i + ${#fd} + ${#op}))
    while [[ "${t:i:1}" == [[:blank:]] ]]; do i=$((i + 1)); done
    r2_word "$t" "$i"
    r2_quiet "${t:i:R2_W_E-i}" "$R2_W_K" || R2_QUIET=0
    if [ "$op" = '<<<' ]; then
      w="${t:i:R2_W_E-i}"
      case "$w" in \"*\") w="${w#\"}"; w="${w%\"}" ;; esac
      if [[ "$w" =~ $R2_VAR_RE ]] || [[ "$w" =~ $R2_BRACED_RE ]]; then
        R2_HS="${BASH_REMATCH[1]}"
      else
        R2_HS='?'
      fi
    fi
    if [ -n "$fd" ]; then
      [[ "$fd" =~ ^0*1$ ]] && R2_RDOUT=1
    else
      case "$op" in '>'|'>>'|'>|'|'>&'|'&>') R2_RDOUT=1 ;; esac
    fi
    i="$R2_W_E"
  done
  R2_END="$end"
  return 0
}

# r2_refs <name> <text> — how many times `$name` or `${name…` occurs, the next character not one
# that would lengthen the name.
r2_refs() {
  local LC_ALL=C
  local name="$1" rest needle k=0
  for needle in "\$$name" "\${$name"; do
    rest="$2"
    while [ "${rest#*"$needle"}" != "$rest" ]; do
      rest="${rest#*"$needle"}"
      case "${rest:0:1}" in [A-Za-z0-9_]) ;; *) k=$((k + 1)) ;; esac
    done
  done
  R2_REFS="$k"
}
R2_REFS=0

# r2_bounded <text> <i> [len] — the `grep` at i (len characters, 4 unless `egrep`/`fgrep`) is a
# command word: what precedes it starts a command (or nothing does), and a blank or the end follows it.
r2_bounded() {
  local LC_ALL=C
  local p=' ' f="${1:$2+${3:-4}:1}"
  [ "$2" -gt 0 ] && p="${1:$2-1:1}"
  case "$f" in ''|' '|$'\t') ;; *) return 1 ;; esac
  case "$p" in ' '|$'\t'|$'\n'|';'|'&'|'|'|'('|'`'|'!'|'{') return 0 ;; esac
  return 1
}

# r2_anchored <literal> — the pattern opens with the ok prefix, or with `^`, blanks and the pass
# mark (issue #249). A blank may carry a star (` *`, the shape the FAIL message names); a star with
# no blank before it is no blank. Prefix tests on bytes, so it answers the same under `LC_ALL=C`
# and a UTF-8 locale: the mark is the same four bytes in both.
r2_anchored() {
  local rest
  case "$1" in "$OK_ANCHOR"*) return 0 ;; '^'*) ;; *) return 1 ;; esac
  rest="${1#^}"
  while :; do
    case "$rest" in ' *'*) rest="${rest#' *'}" ;; ' '*) rest="${rest# }" ;; *) break ;; esac
  done
  case "$rest" in "$PASS_MARK"*) return 0 ;; esac
  return 1
}

# ── the argv of GNU grep 3.11, ONE definition (issue #270, lote 9) ─────────────────────────────
# Copied from `/usr/bin/grep --help` and from getopt_long's own messages, GNU grep 3.11, measured
# on 2026-10-16: each letter alone as the last word (`option requires an argument`, `invalid
# option`), each long name alone and with `=v` (`requires an argument`, `doesn't allow an
# argument`), the 50 names the ambiguity messages of `--a` … `--z` list, and every prefix of every
# name run through the binary and compared with r2_long. Read by r2_argv, r2_long and r2_opt only.
#   R2_SHORT_ARG   the letters that take an argument: the rest of the word, or the next word;
#   R2_SHORT_NONE  the letters that take none; a digit is a context length (`-5`, `--context=5`);
#   R2_LONG        name:argument:identity. The argument is r (required: after `=`, or the next word
#                  whatever it is), o (optional: after `=` only, so `--color never` makes `never` an
#                  operand) or n (none: `=` refused). The identity is what getopt_long compares when
#                  a prefix names several options: the short letter when there is one, the name
#                  otherwise. `fixed-regexp` is a hidden synonym of `-F`, so `--fixed` resolves, and
#                  so does `--col` (color, colour);
#   R2_MATCHERS    the names `-X` takes, exactly; `-X fgrep` is `-F`.
# A letter or a name absent from it is refused: the closed side.
R2_SHORT_ARG='ABCdDefmX'
R2_SHORT_NONE='abcEFGhHiIlLnoPqrRsTuUvVwxyzZ0123456789'
R2_LONG=(
  after-context:r:A before-context:r:B binary-files:r:binary-files context:r:C devices:r:D
  directories:r:d exclude:r:exclude exclude-dir:r:exclude-dir exclude-from:r:exclude-from file:r:f
  group-separator:r:group-separator include:r:include label:r:label max-count:r:m regexp:r:e
  color:o:color colour:o:color
  basic-regexp:n:G binary:n:U byte-offset:n:b count:n:c dereference-recursive:n:R
  extended-regexp:n:E files-with-matches:n:l files-without-match:n:L fixed-regexp:n:F
  fixed-strings:n:F help:n:help ignore-case:n:i initial-tab:n:T invert-match:n:v
  line-buffered:n:line-buffered line-number:n:n line-regexp:n:x no-filename:n:h
  no-group-separator:n:no-group-separator no-ignore-case:n:no-ignore-case no-messages:n:s
  null:n:Z null-data:n:z only-matching:n:o perl-regexp:n:P quiet:n:q recursive:n:r silent:n:q
  text:n:a unix-byte-offsets:n:u version:n:V with-filename:n:H word-regexp:n:w
)
R2_MATCHERS=(grep egrep fgrep awk gawk posixawk perl)
R2_OPTS=' '; R2_PV=(); R2_PK=(); R2_PLIT=0; R2_LT=''; R2_LI=''

# r2_long <name> — the long option a name spells, as getopt_long resolves it: the exact name, or
# else a prefix whose candidates all share one identity (and one argument). R2_LT is its argument
# and R2_LI its identity; rc 1 when the name is unknown or the prefix ambiguous, which grep refuses.
r2_long() {
  local e nm hit='' amb=0
  for e in "${R2_LONG[@]}"; do
    nm="${e%%:*}"
    [ "${nm#"$1"}" != "$nm" ] || continue
    if [ "$nm" = "$1" ]; then hit="${e#*:}"; break; fi
    if [ -z "$hit" ]; then hit="${e#*:}"; elif [ "$hit" != "${e#*:}" ]; then amb=1; fi
  done
  [ -n "$hit" ] && [ "$amb" -eq 0 ] || return 1
  R2_LT="${hit%%:*}"; R2_LI="${hit#*:}"
}

# r2_opt <identity> <argument> <its class> — an option read with its argument: R2_OPTS gains the
# identity, an `e` adds its pattern, and an `X` takes only a name of R2_MATCHERS (rc 1 otherwise; a
# value that is not `lit` holds R2_MARK, and names none); `-X fgrep` adds `F` too.
r2_opt() {
  local m
  R2_OPTS+="$1 "
  case "$1" in
    e) R2_PV+=("$2"); R2_PK+=("$3") ;;
    X) for m in "${R2_MATCHERS[@]}"; do
         [ "$m" = "$2" ] || continue
         [ "$m" != fgrep ] || R2_OPTS+='F '
         return 0
       done
       return 1 ;;
  esac
  return 0
}

# r2_argv [identity] — grep's argv, read from the words r2_grep_at published the way getopt_long
# reads it: options anywhere before `--` (GNU grep permutes), a cluster letter by letter, a long
# option by its name or by any prefix r2_long resolves; `--` ends the options and a lone `-` is an
# operand. The identity given is the option the command name implies (`F` for fgrep). R2_OPTS gets
# the identity of every option read, each followed by a blank; R2_PV and R2_PK the value and class
# of every pattern: each argument of `-e`/`--regexp`, or, with none, the first operand (past an
# `-f` that one is a FILE to grep, and the `-f` disarms the grep whatever it is). Every other
# operand is a FILE. A word whose value opens with R2_MARK (an expansion) is an operand, a declared
# limit: its value could be an option. An ANSI-C word is never decoded, so an operand holding one
# is refused, pattern or FILE (`$'-v'` is an option to grep, measured); as an option's argument it
# is that argument. R2_PLIT is 1 when there is a pattern and every one is `lit`. rc 1 when the argv
# cannot be read.
r2_argv() {
  local LC_ALL=C
  local n="${#R2_WV[@]}" k=0 dd=0 j v w c
  local -a ov=() ow=()
  R2_OPTS=' '; R2_PV=(); R2_PK=(); R2_PLIT=0
  [ -z "${1-}" ] || R2_OPTS+="$1 "
  while [ "$k" -lt "$n" ]; do
    v="${R2_WV[k]}"; w="${R2_WK[k]}"; k=$((k + 1))
    if [ "$dd" -eq 0 ]; then
      case "$v" in
        --) dd=1; continue ;;
        --*)
          c="${v#--}"; c="${c%%=*}"
          r2_long "$c" || return 1
          if [ "${v#*=}" != "$v" ]; then
            [ "$R2_LT" != n ] || return 1
            r2_opt "$R2_LI" "${v#*=}" "$w" || return 1
          elif [ "$R2_LT" = r ]; then
            [ "$k" -lt "$n" ] || return 1
            r2_opt "$R2_LI" "${R2_WV[k]}" "${R2_WK[k]}" || return 1
            k=$((k + 1))
          else
            R2_OPTS+="$R2_LI "
          fi
          continue ;;
        -?*)
          for ((j = 1; j < ${#v}; j++)); do
            c="${v:j:1}"
            case "$R2_SHORT_ARG" in
              *"$c"*)
                if [ $((j + 1)) -lt "${#v}" ]; then
                  r2_opt "$c" "${v:j+1}" "$w" || return 1
                else
                  [ "$k" -lt "$n" ] || return 1
                  r2_opt "$c" "${R2_WV[k]}" "${R2_WK[k]}" || return 1
                  k=$((k + 1))
                fi
                continue 2 ;;
            esac
            case "$R2_SHORT_NONE" in *"$c"*) R2_OPTS+="$c " ;; *) return 1 ;; esac
          done
          continue ;;
      esac
    fi
    [ "$w" != ansi ] || return 1
    ov+=("$v"); ow+=("$w")
  done
  if [ "${#R2_PV[@]}" -eq 0 ] && [ "${#ov[@]}" -gt 0 ]; then
    R2_PV=("${ov[0]}"); R2_PK=("${ow[0]}")
  fi
  [ "${#R2_PV[@]}" -gt 0 ] || return 0
  for w in "${R2_PK[@]}"; do [ "$w" = lit ] || return 0; done
  R2_PLIT=1
}

# r2_grep_anchored [identity] — the grep r2_grep_at just read is anchored: its argv reads
# (r2_argv, given the option its command name implies; R2_OPTS ends in `?` when it does not), no
# option disarms the caret, and it has a pattern and every pattern anchors. Disarm, by identity:
# `F` (`-F`, `--fixed-strings`, the hidden `--fixed-regexp`, `-X fgrep`, fgrep: the caret is a
# literal; Codex on PR #267), `v` (every other line counts), `z` (the input is one record, so `^`
# opens only it and `.` crosses lines) and `f` (patterns from a file). A pattern anchors when it is
# `lit` or `dq` and its value anchors: in a `dq` value R2_MARK stands where the literal prefix ends,
# and every anchor is a literal prefix, so the value anchors exactly when the prefix before the
# first expansion does (a declared limit: the expansion could carry a newline or a `\|`). An `ansi`
# or `raw` pattern never anchors (`$'…\n…'` hands grep two patterns; Codex on PR #267, third
# round). One definition for both paths: the final review of lote 8 measured a second pattern
# riding on the first one's anchor in each.
r2_grep_anchored() {
  local LC_ALL=C
  local k
  r2_argv "${1-}" || { R2_OPTS+='? '; return 1; }
  case "$R2_OPTS" in *' F '* | *' v '* | *' z '* | *' f '*) return 1 ;; esac
  [ "${#R2_PV[@]}" -gt 0 ] || return 1
  for k in "${!R2_PV[@]}"; do
    case "${R2_PK[k]}" in
      lit | dq) r2_anchored "${R2_PV[k]}" || return 1 ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# The options that leave a counting grep's count alone (issue #272), ONE definition, written by
# what enters: a predicate of admission is written positively (CLAUDE.md), so an option the table
# gains tomorrow stays out until someone writes it here. In: the count itself; case and syntax
# (`-i`, `-y`, `--no-ignore-case`, `-E`, `-G`, `-P`, `-w`, `-x`); the pattern (`-e`); and what `-c`
# ignores or prints beside the count (`-s`, `-a`, `-h`, `-H`, `-n`, `-b`, `-o`, `-T`, `-U`, `-u`,
# `-Z`, `--label`, `--color`, `--line-buffered`). Out by omission, among the rest: `-v` (it counts
# every other line), `-q` (it prints nothing), `-m` (`-m 0` prints `0` whatever the input), the `-F`
# family, `-X`, `-f`, `-z`, `-l`, `-L`, `-r`, the context and the file filters.
R2_ZERO_OPTS=' c i y no-ignore-case E G P w x e s a h H n b o T U u Z label color line-buffered '

# r2_counts_zero — the grep r2_grep_at and r2_grep_anchored just read prints a count and nothing
# moves it: its stdout is not redirected (R2_RDOUT), it counts (`-c`), every option is on
# R2_ZERO_OPTS (an argv that does not read leaves a `?` in R2_OPTS, which the list never holds),
# every pattern is `lit` (R2_PLIT), and no word or target of it runs a command (R2_QUIET; a FILE
# `>(echo 0)` prints the zero a failed grep never did, PR #274, round 3). Whether that count is
# what the pair prints is r2_greps' half.
r2_counts_zero() {
  local o
  local -a os=()
  [ "$R2_RDOUT" -eq 0 ] && [ "$R2_PLIT" -eq 1 ] && [ "$R2_QUIET" -eq 1 ] || return 1
  case "$R2_OPTS" in *' c '*) ;; *) return 1 ;; esac
  read -ra os <<< "$R2_OPTS"
  for o in ${os[@]+"${os[@]}"}; do
    case "$R2_ZERO_OPTS" in *" $o "*) ;; *) return 1 ;; esac
  done
  return 0
}

# r2_pairs <text> — the cell's pairs `command` → `expected` (issue #272). Its code spans are read
# backtick to backtick (a span holds no backtick); a span followed by `→` and the next span, blanks
# allowed around the arrow, is the command of a pair whose expected value is that next span.
# R2_CS and R2_CE hold the first index inside each command and the index of its closing backtick,
# and R2_CZ is 1 when its expected value is only zeros: at least one word, every word exactly `0`.
# R2_CN holds how many words that expected value has.
R2_CS=(); R2_CE=(); R2_CZ=()
r2_pairs() {
  local LC_ALL=C
  local t="$1" n="${#1}" i k g z x
  local -a b=() w=()
  R2_CS=(); R2_CE=(); R2_CZ=(); R2_CN=()
  for ((i = 0; i < n; i++)); do [ "${t:i:1}" != '`' ] || b+=("$i"); done
  for ((k = 0; k + 3 < ${#b[@]}; k += 2)); do
    g="${t:b[k+1]+1:b[k+2]-b[k+1]-1}"
    g="${g#"${g%%[![:blank:]]*}"}"; g="${g%"${g##*[![:blank:]]}"}"
    [ "$g" = '→' ] || continue
    read -ra w <<< "${t:b[k+2]+1:b[k+3]-b[k+2]-1}"
    z=0; [ "${#w[@]}" -eq 0 ] || z=1
    for x in ${w[@]+"${w[@]}"}; do [ "$x" = 0 ] || z=0; done
    R2_CS+=("$((b[k] + 1))"); R2_CE+=("${b[k+1]}"); R2_CZ+=("$z"); R2_CN+=("${#w[@]}")
  done
}

# r2_zero_pair <i> — the index i sits inside the command of a pair that expects only zeros; R2_ZK
# is that pair's index.
r2_zero_pair() {
  local k
  for k in ${R2_CS[@]+"${!R2_CS[@]}"}; do
    if [ "${R2_CZ[k]}" -eq 1 ] && [ "$1" -ge "${R2_CS[k]}" ] && [ "$1" -lt "${R2_CE[k]}" ]; then
      R2_ZK="$k"; return 0
    fi
  done
  return 1
}

# r2_grep_word <text> <i> — a grep starts at i: `grep`, `egrep` or `fgrep`, a command word as
# r2_bounded reads it. R2_GK is the length of the name. Like the two below, it runs only under
# r2_greps and its LC_ALL=C, so its indexes are the walker's.
r2_grep_word() {
  R2_GK=0
  if [ "${1:$2:4}" = grep ]; then R2_GK=4
  elif [ "${1:$2:5}" = egrep ] || [ "${1:$2:5}" = fgrep ]; then R2_GK=5; fi
  [ "$R2_GK" -gt 0 ] && r2_bounded "$1" "$2" "$R2_GK"
}

# r2_ends_clean <text> — the command r2_grep_at just read ends where the next command of the pair
# opens, or where the pair's command does: at a `;`, a `&&`, a `||` or the span's closing backtick
# (PR #274, round 2). Written by what enters: a lone `&` runs the command in the background, so a
# grep there is no count the pair waits for and an assignment there never reaches the grep after
# it; every other end is the closed side.
r2_ends_clean() {
  case "${1:R2_END:2}" in ';'* | '&&' | '||' | '`'*) return 0 ;; esac
  return 1
}

# r2_assign_at <text> <i> — the command at i is one assignment and nothing else (PR #274, round 2):
# a name and `=` open it, its value runs nothing (r2_quiet: `x=>(echo 0)` printed the zero, round
# 3), r2_grep_at reads one word there (a second word is a command the assignment only prefixes,
# `x=1 echo 0`), and it ends where r2_ends_clean says. It prints nothing.
R2_ASSIGN_RE='^[A-Za-z_][A-Za-z0-9_]*='
r2_assign_at() {
  local v
  [[ "${1:$2}" =~ $R2_ASSIGN_RE ]] || return 1
  r2_word "$1" "$2"
  v="${1:$2:R2_W_E-$2}"
  r2_quiet "${v#*=}" "$R2_W_K" || return 1
  r2_grep_at "$1" "$2"
  [ "${#R2_WV[@]}" -eq 1 ] && r2_ends_clean "$1"
}

# rule2 <check cell> — R2_STRICT=1 asks for the cell rule, where R2_AA of the cell's greps are
# anchored; otherwise R2_G greps read a merged variable and R2_A of them are anchored.
rule2() {
  local LC_ALL=C
  local t="$1" name refs=0
  R2_STRICT=0; R2_G=0; R2_A=0; R2_AA=0; R2_HSREFS=0; R2_TAINTED=()
  # A name the reader never sees written — `${!v}`, a nameref, an `eval` — reads the stream past it
  # (the final review of lote 8 reproduced all three), so the cell keeps the cell rule.
  case "$t" in *'${!'*) R2_STRICT=1 ;; esac
  [[ "$t" =~ $R2_INDIRECT_RE ]] && R2_STRICT=1
  [ "$R2_STRICT" -eq 1 ] || r2_captures "$t"
  r2_greps "$t"
  [ "$R2_STRICT" -eq 0 ] || return 0
  # Every read of a tainted name has to be one of those herestrings, or the stream went somewhere
  # this reader does not follow.
  for name in ${R2_TAINTED[@]+"${R2_TAINTED[@]}"}; do
    r2_refs "$name" "$t"; refs=$((refs + R2_REFS))
  done
  [ "$refs" -eq "$R2_HSREFS" ] || R2_STRICT=1
  return 0
}

# r2_captures <text> — pass 1, the captures. Each `$(` outside single quotes is skipped whole; the
# named clean ones taint their name (R2_TAINTED) and leave the residue. R2_STRICT=1 when a capture
# or a quote never closes, or when a merge (any spelling) is left outside the clean captures.
r2_captures() {
  local LC_ALL=C
  local t="$1" n="${#1}" i=0 c sq=0 dq=0 from=0 res='' pre inner name k
  while [ "$i" -lt "$n" ]; do
    c="${t:i:1}"
    if [ "$sq" -eq 1 ]; then
      [ "$c" = "'" ] && sq=0
      i=$((i + 1)); continue
    fi
    case "$c" in
      '\') i=$((i + 2)); continue ;;
      "'") [ "$dq" -eq 0 ] && sq=1 ;;
      '"') dq=$((1 - dq)) ;;
      '$')
        if [ "${t:i+1:1}" = '(' ]; then
          r2_close "$t" $((i + 2))
          if [ "$R2_END" -lt 0 ]; then R2_STRICT=1; return 0; fi
          inner="${t:i+2:R2_END-i-2}"
          pre="${t:0:i}"; name=''
          if [ "$dq" -eq 1 ]; then
            [ "${pre%=\"}" != "$pre" ] && pre="${pre%=\"}" && name=y
          else
            [ "${pre%=}" != "$pre" ] && pre="${pre%=}" && name=y
          fi
          if [ -n "$name" ] && [[ "$pre" =~ $R2_NAME_RE ]]; then
            name="${BASH_REMATCH[2]}"
          else
            name=''
          fi
          if [ -n "$name" ] && r2_merges "$inner" && [ "${inner#*grep}" = "$inner" ]; then
            case " ${R2_TAINTED[*]-} " in *" $name "*) ;; *) R2_TAINTED+=("$name") ;; esac
            k=$(( ${#pre} - ${#name} ))
            res="${res}${t:from:k-from}"
            from=$((R2_END + 1))
          fi
          i=$((R2_END + 1)); continue
        fi ;;
    esac
    i=$((i + 1))
  done
  res="${res}${t:from}"
  if [ "$sq" -eq 1 ] || [ "$dq" -eq 1 ] || r2_merges "$res"; then
    R2_STRICT=1
  fi
  return 0
}

# r2_greps <text> — pass 2, every grep outside quotes — `egrep` and `fgrep` too, read as `grep -E`
# and `grep -F` —, read where it stands and then skipped up to R2_END, so a word of its argv named
# `grep` (a FILE, the matcher of `-X fgrep`) is no second grep: R2_AA counts the anchored
# ones, R2_G those whose herestring is a tainted name, R2_A the anchored among these, R2_HSREFS the
# tainted reads they account for. A grep that does not anchor counts as anchored all the same, on
# both paths, when it is a counting grep of a pair that expects only zeros (issue #272,
# r2_zero_pair) and that pair prints its counts and nothing else (Codex on PR #274, round 2). Every
# command at the top of the pair's command — inside no `$(…)` or `(…)` (st), opening the span or
# after a `;`, a `&&` or a `||` (cs) — is a grep whose count nothing moves (r2_counts_zero) or one
# assignment (r2_assign_at), each ending where r2_ends_clean says, or the pair exempts nothing (zb);
# and the expected value holds one word for each of those greps (zg against R2_CN). A grep that
# fails prints no count, so the pair's output is then a word short of it, and red. Anything else at
# the top — a redirection or an assignment before the grep, a compound command, `exec`, `cd`, `echo`
# — is the closed side. A backtick opens a command: each span is its own.
r2_greps() {
  local LC_ALL=C
  local t="$1" n="${#1}" i=0 c sq=0 st='' name ok k cs=0 at zk zp q
  local -a zg=() zb=() pz=() pq=()
  r2_pairs "$t"
  for k in ${R2_CS[@]+"${!R2_CS[@]}"}; do zg+=(0); zb+=(0); done
  while [ "$i" -lt "$n" ]; do
    c="${t:i:1}"
    if [ "$sq" -eq 1 ]; then
      [ "$c" = "'" ] && sq=0
      i=$((i + 1)); continue
    fi
    if [ "${st: -1}" = D ]; then
      case "$c" in
        '\') i=$((i + 2)); continue ;;
        '"') st="${st%?}" ;;
        '$') if [ "${t:i+1:1}" = '(' ]; then st="${st}P"; i=$((i + 2)); continue; fi ;;
      esac
      i=$((i + 1)); continue
    fi
    case "$c" in
      ' '|$'\t') i=$((i + 1)); continue ;;
      '`') cs=1; i=$((i + 1)); continue ;;
      ';') cs=1; i=$((i + 1)); continue ;;
      '&') if [ "${t:i+1:1}" = '&' ]; then cs=1; i=$((i + 2)); continue; fi ;;
      '|') if [ "${t:i+1:1}" = '|' ]; then cs=1; i=$((i + 2)); continue; fi ;;
    esac
    at="$cs"; cs=0
    # A command at the top of a zero pair's command: a grep is read below, and anything else has
    # to be one assignment, or the pair prints what is no count (zb).
    zk=-1
    if [ -z "$st" ] && [ "$at" -eq 1 ] && r2_zero_pair "$i"; then
      zk="$R2_ZK"
      r2_grep_word "$t" "$i" || r2_assign_at "$t" "$i" || zb[zk]=1
    fi
    case "$c" in
      '\') i=$((i + 2)); continue ;;
      "'") sq=1 ;;
      '"') st="${st}D" ;;
      '(') st="${st}P" ;;
      ')') st="${st%?}" ;;
      g|e|f)
        if r2_grep_word "$t" "$i"; then
          r2_grep_at "$t" $((i + R2_GK))
          case "$c" in f) c=F ;; *) c='' ;; esac
          ok=0; zp=-1; q=0
          if r2_grep_anchored "$c"; then ok=1; fi
          if [ "$zk" -ge 0 ]; then
            if r2_counts_zero && r2_ends_clean "$t"; then
              zg[zk]=$((zg[zk] + 1)); [ "$ok" -eq 1 ] || zp="$zk"
            else
              zb[zk]=1
            fi
          fi
          R2_AA=$((R2_AA + ok))
          for name in ${R2_TAINTED[@]+"${R2_TAINTED[@]}"}; do
            [ "$R2_HS" = "$name" ] || continue
            R2_G=$((R2_G + 1)); R2_HSREFS=$((R2_HSREFS + 1)); R2_A=$((R2_A + ok)); q=1
            break
          done
          [ "$zp" -lt 0 ] || { pz+=("$zp"); pq+=("$q"); }
          i="$R2_END"; continue
        fi ;;
    esac
    i=$((i + 1))
  done
  # The exemption, once each pair is read whole: every command at its top a counting grep or an
  # assignment (zb), and one zero for each of those greps (zg), so a grep that prints no count
  # leaves the pair a word short of its expected value.
  for k in ${pz[@]+"${!pz[@]}"}; do
    [ "${zb[pz[k]]}" -eq 0 ] && [ "${zg[pz[k]]}" -eq "${R2_CN[pz[k]]}" ] || continue
    R2_AA=$((R2_AA + 1)); R2_A=$((R2_A + pq[k]))
  done
  return 0
}

# The scanned surface: every mission checkpoint plus the template they are all born from.
# Takes the root as an argument rather than reading the global, so the selftest can drive the real
# scan() path over a fixture tree — a floor without a probe is a wish.
surface() {
  ( cd "$1" && ls -1 docs/handoffs/*/checkpoint.md templates/checkpoint.md 2>/dev/null )
}

# rows_of <path> — one line per table row: "NF<TAB>ID<TAB>Status<TAB>Check cell".
#
# The row recognition is the raw `awk -F'|'` split, with NO rejoin of GFM's `\|` — deliberately
# stricter than checkpoint_rows() in bin/sdd, which does rejoin it. See rule 1 in the header for
# why: any pipe in a Check cell is refused in this repo's checkpoints, escaped or not. NF is
# emitted rather than checked here so the caller can tell "pipe inside a cell" from "not a table
# row at all".
#
# A row with no leading pipe, inside the table, is emitted with NF 0 so the callers refuse it by
# name: GFM makes that pipe optional, the runner reads the row since PR #222, and a reader of
# `|`-led lines alone skipped it whole — --check never saw it, --red answered 0 over a pending Check
# it never ran (CodeRabbit review). Below a blank line the same line is a paragraph and stays out.
#
# A row with FEWER than five cells is emitted too, with its NF under 6, so the callers refuse it by
# name (issue #224): GFM renders the missing cells empty, and dropped here it vanished from --check
# and --red alike. Only inside a table whose HEADER — the first line of the block — splits into six
# fields or more: GFM counts a table's columns by its header, and a narrow table elsewhere is no
# checkpoint table. Six fields is five cells, or four closed by the trailing pipe — DECLARED: that
# four-cell header reads as wide. A four-cell row closed the same way is refused all the same, by
# rule 1's column count (4 instead of 5) and not by the fewer-than-five message.
# A short line with no leading pipe is emitted too, with NF 0 (7th Codex review of PR #237): GFM
# renders it as a row, and the runner reads it since then — skipped on the guess that it was prose
# glued to the table, it carried a pending increment past both readers. Prose glued to the table
# that quotes a pipe is refused with it, as GFM renders it a row; a blank line cures it, and
# build_tree's template carries that blank line, as the real one does.
rows_of() {
  awk -F'|' '
    /^[ \t]*$/ { tbl = 0 }
    { bare = (tbl && /\|/ && !/^[ \t]*\|/) }
    bare { $0 = "|" $0 }
    /^[ \t]*\|/ {
      if (!tbl) wide = (NF >= 6)
      tbl = 1
      if (NF < 6 && !wide) next
      id = $2; gsub(/^[ \t]+|[ \t]+$/, "", id)
      if (id == "ID" || id ~ /^-+$/ || id == "") next
      status = $5; gsub(/^[ \t]+|[ \t]+$/, "", status)
      if (status == "Status") next
      chk = $4; gsub(/^[ \t]+|[ \t]+$/, "", chk)
      # An empty Status prints as "-": a tab is IFS whitespace to the reader, so an empty field
      # would collapse and hand the Check cell over as the status.
      printf "%d\t%s\t%s\t%s\n", (bare ? 0 : NF), id, (status == "" ? "-" : status), chk
    }' "$1"
}

# Counters published as globals and never through a command substitution: a function read as
# `x="$(f)"` runs in a subshell and every assignment it makes dies with it (CLAUDE.md).
N_FILES=0; N_ROWS=0; N_RULED=0; V_ANCHOR=0; V_COLS=0; N_PATHS=0; V_IGNORED=0; V_ORDER=0

reset_counters() {
  N_FILES=0; N_ROWS=0; N_RULED=0; V_ANCHOR=0; V_COLS=0; N_PATHS=0; V_IGNORED=0; V_ORDER=0
}

# scan_file <path> <label> — accumulates into the globals, prints one FAIL per violation.
scan_file() {
  local path="$1" label="$2" rows nf id st chk g a top p src bid=''
  rows="$(rows_of "$path")"
  N_FILES=$((N_FILES + 1))
  # The repo the checkpoint belongs to, resolved from ITS directory and never from the cwd: a
  # target repo ignores what the kit does not. `git -C`, never `cd` (CDPATH). Empty outside a repo,
  # and then rule 5 has nothing to ask.
  top="$(git -C "$(dirname -- "$path")" rev-parse --show-toplevel 2>/dev/null)" || top=''
  while IFS=$'\t' read -r nf id st chk; do
    [ -n "$nf" ] || continue
    N_ROWS=$((N_ROWS + 1))

    # Rule 1 — the row opens with its pipe, and hands the runner five columns, or the cell below is
    # a truncation and rule 2 fails open. NF 0 is rows_of's mark for the missing leading pipe.
    if [ "$nf" -eq 0 ]; then
      fail "$label: row $id has no leading '|' — GFM renders it as a row and the runner counts it, but this repo's checkpoints open every row with the pipe"
      V_COLS=$((V_COLS + 1))
      continue
    fi
    if [ "$nf" -lt 6 ]; then
      fail "$label: row $id has fewer than five cells — GFM renders the missing ones empty, so the runner reads no Status in it; write all five"
      V_COLS=$((V_COLS + 1))
      continue
    fi
    if [ "$nf" -ne 7 ]; then
      fail "$label: row $id hands the runner $((nf - 2)) column(s) instead of 5 — a '|' inside a cell splits it. A raw pipe breaks gate_EXEC; the escape '\\|' the runner rejoins, but this repo's checkpoints use the herestring form instead"
      V_COLS=$((V_COLS + 1))
      continue
    fi

    # Rule 6 — no row closes below a blocked one; after rule 1, since a shifted row has no Status to
    # read. The runner stops the line at the first blocked row (increment-blocked, rc 3), so a done
    # below it was closed past the stop, outside the runner, and its Check may certify what the
    # blocked row never proved (issue 216).
    if [ "$st" = blocked ] && [ -z "$bid" ]; then
      bid="$id"
    elif [ "$st" = 'done' ] && [ -n "$bid" ]; then
      fail "$label: $id is done below $bid, which is blocked — the runner stops the line at a blocked row, so $id was closed past the stop and its Check may certify what $bid never proved"
      V_ORDER=$((V_ORDER + 1))
    fi

    # Rule 5 — a path the Check tests with `test -e|-f|-s` must be one git keeps. An ignored one is
    # green on the machine that wrote it and red on a fresh clone, and the increment closes `done`
    # over an artifact that never reaches the repo (issue 211).
    if [ -n "$top" ]; then
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        N_PATHS=$((N_PATHS + 1))
        if src="$(git -C "$top" check-ignore -v -- "$p" 2>/dev/null)"; then
          fail "$label: the Check of $id tests '$p', which the repository ignores (${src%%$'\t'*}) — green over a file git never receives, red on a fresh clone"
          V_IGNORED=$((V_IGNORED + 1))
        fi
      done <<< "$(tested_paths "$chk")"
    fi

    # Rule 2 — precondition: the cell merges stderr into stdout, in any spelling (r2_merges), AND
    # greps. Either half missing and there is no FAIL text in the stream being read.
    r2_merges "$chk" || continue
    g="$(count_occ 'grep' "$chk")"
    [ "$g" -gt 0 ] || continue
    # Then the reader (issue #258): only a grep whose herestring reads the variable the merged
    # output went into owes the anchor. A cell it cannot follow keeps the cell rule below.
    rule2 "$chk"
    if [ "$R2_STRICT" -eq 0 ]; then
      g="$R2_G"; a="$R2_A"
      [ "$g" -gt 0 ] || continue
    else
      a="$R2_AA"
    fi
    N_RULED=$((N_RULED + 1))
    if [ "$a" -lt "$g" ]; then
      fail "$label: the Check of $id greps a sensor's merged output with $a of $g pattern(s) anchored on the ok prefix or on a pass mark ('^ *${PASS_MARK}') — FAIL prints the same text as ok, so this cell answers 'the assertion exists', never 'the assertion passed'; a counting grep (-c) whose pair expects only zeros owes none, when that pair runs only counting greps and assignments and expects one zero per grep"
      V_ANCHOR=$((V_ANCHOR + 1))
    fi
  done <<< "$rows"
}

# tested_paths <check cell> — the repo paths a `test -e|-f|-s <p>`, `[ … ]` or `[[ … ]]` names,
# one per line. Only a literal relative path is read: an absolute one or one under `~` is outside
# the repo, and anything carrying `$ * ? [ { < >` or a backtick is decided at run time, not here.
tested_paths() {
  local -a w
  local i t
  read -ra w <<< "$1"
  for ((i = 0; i + 2 < ${#w[@]}; i++)); do
    t="${w[i]}"; t="${t#\`}"; t="${t#(}"
    case "$t" in test|'['|'[[') ;; *) continue ;; esac
    case "${w[i+1]}" in -e|-f|-s) ;; *) continue ;; esac
    t="${w[i+2]}"
    while :; do
      case "$t" in *'`'|*';'|*')'|*'"'|*"'") t="${t%?}" ;; *) break ;; esac
    done
    t="${t#[\"\']}"
    case "$t" in ''|']'|/*|'~'*) continue ;; esac
    case "$t" in *[\$\*\?\[\{\<\>\`]*) continue ;; esac
    printf '%s\n' "$t"
  done
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

# pipe_rule <path> <label> — the twin of doc_rule for the OTHER rule a checkpoint has to be born
# knowing: no `|` inside a Check cell, not even escaped.
#
# It existed only as prose and as rule 1 of the scan, with nothing joining the two. Deleting the
# banner from templates/checkpoint.md AND from agents/sdd-planner.md left this file green, so the
# rule that cost a whole mission would be rediscovered by the next planner the expensive way —
# and rule 1 catches the violation only AFTER a checkpoint has been written with it, at which
# point gate_EXEC has already read a fragment of a command as a status token.
#
# Both literals are demanded and both are STRUCTURAL, for the same reason as doc_rule: the
# mechanism that cannot read the escape, and the escape itself. Either alone is half a rule — the
# mechanism without the escape lets the next planner write `\|` and believe GFM saves it, and the
# escape without the mechanism is a prohibition with no reason, which is the kind a later editor
# deletes as noise. Neither is a Portuguese word, so this survives a target repo writing its
# checkpoint prose in any language.
PIPE_MECH="awk -F'|'"
PIPE_ESCAPE='\|'
# One document per place the next planner meets the rule. A floor, not a headcount: it is what
# turns "both calls returned 0" into "both calls RAN", so deleting a call site cannot buy silence.
PIPE_DOC_FLOOR=2
# The third thing the next planner has to be born knowing (issue 92): the scan never runs a Check,
# so the only hand that measures the red is the planner's, and only if its hat names the run.
RED_DOC='check-checkpoint.sh --red'

pipe_rule() {
  local path="$1" label="$2"
  if [ ! -r "$path" ]; then
    fail "$label is missing or unreadable — the pipe ban has nowhere to live"
    return 1
  fi
  if grep -qF -- "$PIPE_MECH" "$path" && grep -qF -- "$PIPE_ESCAPE" "$path"; then
    return 0
  fi
  fail "$label never states the pipe ban (wanted the literals \"$PIPE_MECH\" and '$PIPE_ESCAPE') — the next Check cell splits into six columns and the runner reads a fragment of the command as a status token"
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
  if [ "$V_IGNORED" -eq 0 ]; then
    pass "no checkpoint Check tests a path its repository ignores ($N_PATHS tested path(s))"
  else
    rc=1
  fi
  if [ "$V_ORDER" -eq 0 ]; then
    pass "no checkpoint row is done below a blocked one ($N_ROWS row(s))"
  else
    rc=1
  fi

  doc_rule "$root/templates/checkpoint.md" "templates/checkpoint.md" \
    "the checkpoint template teaches the ok-anchor rule" || rc=1
  doc_rule "$root/agents/sdd-planner.md" "agents/sdd-planner.md" \
    "the planner agent teaches the ok-anchor rule" || rc=1

  # ONE ok line for the pair, and it prints only when BOTH documents carry the rule: the mission
  # Check counts `^  ok    rule: ` and a line per document would answer 2 for a rule half taught.
  local taught=0
  pipe_rule "$root/templates/checkpoint.md" "templates/checkpoint.md" && taught=$((taught + 1))
  pipe_rule "$root/agents/sdd-planner.md" "agents/sdd-planner.md" && taught=$((taught + 1))
  if [ "$taught" -ge "$PIPE_DOC_FLOOR" ]; then
    pass "rule: the ban on '|' inside a Check cell is taught where the next planner meets it ($taught doc(s))"
  else
    rc=1
  fi

  if grep -qF -- "$RED_DOC" "$root/agents/sdd-planner.md" 2>/dev/null; then
    pass "the planner agent teaches the --red run before PLAN-AUTO"
  else
    fail "agents/sdd-planner.md never states the --red run (wanted the literal '$RED_DOC') — the next plan closes PLAN-AUTO over Checks nobody ran at HEAD"
    rc=1
  fi

  [ "$rc" -eq 0 ] || fail "$((V_ANCHOR + V_COLS + V_IGNORED + V_ORDER)) checkpoint violation(s)"
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
#
# It reads EVERY line that opens a quoted ok prefix — a `pass()`, an inline `printf`, an `echo`, a
# Python `print(` — and counts FILES, not lines. Reading only `pass()` lines saw 9 of the 16
# sensors (issue 113): the other seven print from those other shapes, and a sensor printing three
# spaces from one of them went unseen. The needles are built from variables: a literal quote-ok
# pattern in the `case` below would match its own line and report this very file.
#
# DECLARED LIMIT (ADR 0015 §4): this floor is anti-vacuity, not a tracker of the surface. It is 16
# because 16 sensors print the ok prefix today, and a seventeenth that lands without moving it
# leaves one of slack; nothing measures that, so it is one of the places CLAUDE.md says every new
# sensor moves. No lag in 105 commits.
CALIBRATE_FLOOR=16
calibrate() {
  local root="$1" f line rest sp p seen='' seenf='' n=0 hit
  local sq="'" dq='"' ok='  ok'
  for f in "$root"/tests/*.sh; do
    [ -f "$f" ] || continue
    hit=0
    while IFS= read -r line; do
      case "$line" in *"$sq$ok "*|*"$dq$ok "*) ;; *) continue ;; esac
      rest="${line#*["$sq$dq"]"$ok"}"
      sp="${rest%%[! ]*}"
      p="$ok$sp"
      hit=1
      if [ -z "$seen" ]; then
        seen="$p"; seenf="$(basename -- "$f")"
      elif [ "$seen" != "$p" ]; then
        fail "the suite's sensors disagree about the ok prefix ('$seen' in $seenf, '$p' in $(basename -- "$f")) — no single anchor can be right for both"
        return 1
      fi
    done < "$f"
    n=$((n + hit))
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
  if [ $((V_ANCHOR + V_COLS + V_IGNORED + V_ORDER)) -eq 0 ]; then
    pass "$(basename -- "$path"): $N_ROWS row(s), $N_RULED under the anchor rule, none blind"
    return 0
  fi
  return 1
}

# --- --red: is each pending Check red at HEAD? (issue 92) --------------------------------------
#
# The scan above never runs a Check, on purpose (see the header). This mode does, and only when a
# person asks: the planner, before closing PLAN-AUTO, with the human in the room. A Check that is
# already green before its increment exists cannot tell done from not done — measured once in the
# kit, I7 of 20260918-a-excecao-do-chapeu-e-o-genero-diferido, whose `105 finding(s)` was already
# printed at the plan commit because a RESOLVED item stays in TODO.md until the merge.
#
# It EXECUTES the cell, which a model wrote. That is why it is a tool and never a gate: nothing in
# the runner calls it, and run-all.sh does not either. Each cell runs in a FRESH `bash -c`, from
# the root of the repository the checkpoint lives in, with stdin closed — never `eval`: even inside
# $(…) an eval'd cell inherits this file's `set -uo pipefail` and functions, and `printf … | grep -q`
# answers differently under pipefail than in the shell the executor runs the Check in.

# red_norm <text> — every run of blanks, newlines included, folds into one space; ends trimmed.
# Applied to both sides, so `echo 1; echo 2` compares equal to `1 2`, the way a person reads it.
# `${w[@]+…}` and not a bare `"${w[*]}"`: a Check that printed nothing leaves `w` EMPTY, and bash
# 4.0-4.3 call an empty array unbound under `set -u` (issue #223, the idiom of check-todo.sh).
red_norm() {
  local s="${1//$'\n'/ }" w
  s="${s//$'\t'/ }"
  read -ra w <<< "$s"
  printf '%s' ${w[@]+"${w[*]}"}
}

# red_cell <cell> — splits the strict form `command` → `expected` into RED_CMD and RED_EXP. Globals,
# never a $(…) read: a function run in a substitution loses its assignments (CLAUDE.md). rc 1 for any
# other shape, one guard per way out, each with its probe: a cell that is not backtick, arrow,
# backtick (prose with no code span); a backtick left inside either half (two pairs in one cell, or
# prose after the arrow); an empty expected value. An empty COMMAND needs no guard of its own — it
# prints nothing, and the silent rule in red_one refuses it.
red_cell() {
  local c="$1" bt='`' sep='` → `'
  RED_CMD=''; RED_EXP=''
  case "$c" in "$bt"*"$sep"*"$bt") ;; *) return 1 ;; esac
  RED_CMD="${c#"$bt"}"; RED_CMD="${RED_CMD%%"$sep"*}"
  RED_EXP="${c#*"$sep"}"; RED_EXP="${RED_EXP%"$bt"}"
  case "$RED_CMD$RED_EXP" in *"$bt"*) return 1 ;; esac
  [ -n "$RED_EXP" ]
}

red_one() { # red_one <checkpoint> — 0 every pending Check is red at HEAD; 1 one is not; 93/94/95
  local path="${1-}" label top rows nf id st chk out rc got want n=0 bad=0
  if [ -z "$path" ] || [ ! -r "$path" ]; then
    fail "checkpoint not readable: ${path:-<none>}"
    return 94
  fi
  label="$(basename -- "$path")"
  # The root is the checkpoint's repository, never the cwd — the same resolution as rule 5.
  top="$(git -C "$(dirname -- "$path")" rev-parse --show-toplevel 2>/dev/null)" || top=''
  if [ -z "$top" ]; then
    fail "$label is not inside a git work tree — --red runs each Check from the root of the checkpoint's repository, and there is none"
    return 95
  fi
  rows="$(rows_of "$path")"
  while IFS=$'\t' read -r nf id st chk; do
    [ -n "$nf" ] || continue
    if [ "$nf" -eq 0 ]; then
      fail "$label: row $id has no leading '|' — --red refuses the row a reader of '|'-led lines would skip; run --check first"
      bad=$((bad + 1)); continue
    fi
    if [ "$nf" -lt 6 ]; then
      fail "$label: row $id has fewer than five cells — --red refuses the row a reader of six fields would skip; run --check first"
      bad=$((bad + 1)); continue
    fi
    if [ "$nf" -ne 7 ]; then
      fail "$label: row $id splits into $((nf - 2)) column(s) — --red cannot tell its Status from its Check; run --check first"
      bad=$((bad + 1)); continue
    fi
    [ "$st" = pending ] || continue
    n=$((n + 1))
    if ! red_cell "$chk"; then
      fail "$label: $id has a Check outside the strict form \`command\` → \`expected\` — --red cannot run it, so nothing says it is red"
      bad=$((bad + 1)); continue
    fi
    out="$(CDPATH='' cd -- "$top" && bash -c "$RED_CMD" 2>/dev/null < /dev/null)"; rc=$?
    got="$(red_norm "$out")"; want="$(red_norm "$RED_EXP")"
    if [ -z "$got" ]; then
      fail "$label: $id printed nothing (rc $rc) — a Check has to print a value before the work exists, or its red cannot be written down as the before"
      bad=$((bad + 1))
    elif [ "$got" = "$want" ]; then
      fail "$label: $id is already green at HEAD — its Check prints '$got' before the increment exists, so it cannot tell done from not done"
      bad=$((bad + 1))
    else
      pass "$label: $id is red at HEAD (prints '$got', wants '$want')"
    fi
  done <<< "$rows"
  if [ "$n" -eq 0 ]; then
    fail "$label has no pending row — --red measured nothing"
    return 93
  fi
  [ "$bad" -eq 0 ] || return 1
  pass "$label: $n pending Check(s), every one red at HEAD"
  return 0
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
# Tight, not a minimum with slack: at 27 against 28 real probes, deleting one probe left the count
# on the floor and the sabotage that named exactly that survived the adversarial pass. A floor one
# below the truth measures nothing it claims to.
PROBE_FLOOR=384

# FAILS is bumped by the assertions themselves, independently of fail_rc, and cross-checked at the
# end. A single rc setter is a single point of failure: neuter it and every failure prints and
# then exits 0.
fail_rc() { [ "$SELFTEST_RC" -eq 0 ] && SELFTEST_RC="$1"; return 0; }

# rule_ok <text> — the `ok    rule: ` line a probe group prints when none of its probes failed, and
# a count of them: a mission Check reads that line, and before the count deleting it left the
# selftest green (the sabotage pass of lote 8, 2026-10-15). Tight, like PROBE_FLOOR, and the same
# shape as rule_end in check-todo.sh.
RULE_LINES=0
RULE_FLOOR=8
rule_ok() { pass "rule: $1"; RULE_LINES=$((RULE_LINES + 1)); }

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

cp_row() { # cp_row <file> <id> <check cell> [status, default done]
  printf '| %s | slice | %s | %s | abc1234 |\n' "$2" "$3" "${4-done}" >> "$1"
}

# mg_merges <want rc> <text> — r2_merges's answer on one text. IN-PROCESS on purpose, like wd_tok:
# a `|` splits the row before rule 2 reads the cell (rule 1), so `2>|` and a `|` after the stdout's
# path reach r2_merges from no checkpoint today, and only a direct call shows whether they are read.
mg_merges() {
  local rc=0
  PROBES=$((PROBES + 1))
  r2_merges "$2" || rc=1
  [ "$rc" = "$1" ] && return 0
  printf 'SENSOR-BROKEN: r2_merges on "%s" — wanted rc %s, got %s\n' "$2" "$1" "$rc" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# wd_tok <text after the grep> <want> — the words r2_grep_at publishes, each as class[value|prefix]
# with R2_MARK shown as <M>, then the stdout mark, the herestring's name and the text from where the
# grep ends (R2_END, which the argv reader will skip to). IN-PROCESS on purpose,
# like the red_norm assertion below: the words are a contract the argv reader and the zero pair
# read (issue #270, #272), and until they do, a value no rule reads yet (an unescaped `\$` inside
# double quotes, the redirected stdout) reaches no verdict a child process could print.
wd_tok() {
  local got='' k t="grep$1"
  PROBES=$((PROBES + 1))
  r2_grep_at "$t" 4
  for k in ${R2_WV[@]+"${!R2_WV[@]}"}; do
    got+="${R2_WK[k]}[${R2_WV[k]//"$R2_MARK"/<M>}|${R2_WP[k]}]"
  done
  got+=" out=${R2_RDOUT-} hs=$R2_HS rest=${t:R2_END}"
  [ "$got" = "$2" ] && return 0
  printf 'SENSOR-BROKEN: the words of "grep%s" — wanted %s, got %s\n' "$1" "$2" "$got" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# gt_argv <text after the grep> <want> — what the argv reader publishes (R2_OPTS, each pattern as
# class[value] with R2_MARK shown as <M>, R2_PLIT) and r2_grep_anchored's rc. IN-PROCESS on purpose,
# like wd_tok: the identities and R2_PLIT are what the zero pair of issue #272 reads, and no verdict
# shows them yet.
gt_argv() {
  local got k rc=0 t="grep$1"
  PROBES=$((PROBES + 1))
  r2_grep_at "$t" 4
  r2_grep_anchored || rc=1
  got="opts=[${R2_OPTS-}] pats="
  for k in ${R2_PV[@]+"${!R2_PV[@]}"}; do
    got+="${R2_PK[k]}[${R2_PV[k]//"$R2_MARK"/<M>}]"
  done
  got+=" plit=${R2_PLIT-} rc=$rc"
  [ "$got" = "$2" ] && return 0
  printf 'SENSOR-BROKEN: the argv of "grep%s" — wanted %s, got %s\n' "$1" "$2" "$got" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# zr_opts <want> — the identities r2_counts_zero admits, each read beside `-c`, with a `lit`
# pattern, quiet words and the stdout left alone: every letter of the table, then every identity no
# letter spells, then the `?` of an argv that does not read. IN-PROCESS, like gt_argv: the list is
# one definition, and a child process shows only the identities its fixtures happen to write.
zr_opts() {
  local got='' id e k
  local -a all=()
  PROBES=$((PROBES + 1))
  for ((k = 0; k < ${#R2_SHORT_NONE}; k++)); do all+=("${R2_SHORT_NONE:k:1}"); done
  for ((k = 0; k < ${#R2_SHORT_ARG}; k++)); do all+=("${R2_SHORT_ARG:k:1}"); done
  for e in "${R2_LONG[@]}"; do
    id="${e##*:}"
    [ "${#id}" -gt 1 ] || continue
    case " ${all[*]} " in *" $id "*) ;; *) all+=("$id") ;; esac
  done
  all+=('?')
  for id in "${all[@]}"; do
    R2_OPTS=" c $id "; R2_PLIT=1; R2_RDOUT=0; R2_QUIET=1
    if r2_counts_zero; then got+="${got:+ }$id"; fi
  done
  [ "$got" = "$1" ] && return 0
  printf 'SENSOR-BROKEN: the options a zero pair admits — wanted %s, got %s\n' "$1" "$got" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# zr_quiet <want> — the words r2_quiet admits out of ZR_QUIET_WORDS, each with the class r2_word
# gives it, shown as [word]. IN-PROCESS, like zr_opts: a backtick never reaches a word from a cell
# (it ends the code span), so only a direct call shows that a double-quoted one is refused, and the
# list reads every clause of the rule in one place (PR #274, round 3). The last word is a syntax
# error bash refuses to run; it is there because only the shape test of (c), and not r2_close, tells
# it from a capture.
ZR_QUIET_WORDS=(
  '3' 'if' '{a,b}' "'caso\$'" '$o' '"$o"' '$(bash t.sh 2>&1)'
  '"`echo 0`"' '>(echo 0)' '<(echo 0)' '$(echo 0 >/proc/$$/fd/1)' '${y:-0}' 'a$(echo 0)'
  '$(a)$(b)' '$((1+2))' '"$(echo 0)"' '$(cat <(echo 0))' '$(tee >(cat))' '$o$(echo 0)'
  '$(echo 0)$o' '"$o' 'a$(echo 0))'
)
zr_quiet() {
  local got='' w
  PROBES=$((PROBES + 1))
  for w in "${ZR_QUIET_WORDS[@]}"; do
    r2_word "$w" 0
    if r2_quiet "$w" "$R2_W_K"; then got+="[$w]"; fi
  done
  [ "$got" = "$1" ] && return 0
  printf 'SENSOR-BROKEN: the words r2_quiet admits — wanted %s, got %s\n' "$1" "$got" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# zr_rule2 <want> <cell> — rule 2's verdict on one cell that follows its capture, `<anchored> of
# <greps>` as the FAIL message writes it. IN-PROCESS on purpose, like mg_merges: a `|` splits the
# row before rule 2 reads the cell (rule 1), so a `||` reaches the zero pair from no checkpoint
# today, and only a direct call shows whether it is read as the end of a command (PR #274, round 2).
zr_rule2() {
  local got
  PROBES=$((PROBES + 1))
  rule2 "$2"
  got="$R2_A of $R2_G"
  [ "$R2_STRICT" -eq 0 ] || got='the cell rule'
  [ "$got" = "$1" ] && return 0
  printf 'SENSOR-BROKEN: rule 2 on "%s" — wanted %s, got %s\n' "$2" "$1" "$got" >&2
  FAILS=$((FAILS + 1)); fail_rc 91
}

# pipe_banner — the `|` ban in the shape both real documents write it: the mechanism that cannot
# read the GFM escape, and the escape itself. A function rather than a literal in each fixture, so
# the probes that isolate ONE half can be written by leaving one call out instead of by hand.
pipe_banner() {
  printf 'Never a `|` in the Check cell, not even escaped as `\\|` — the runner parses the table\n'
  printf "with a raw awk -F'|' that does not know the GFM escape.\n"
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
  # The blank line the real template has: prose glued to the table is a row of it in GFM.
  printf '\n' >> "$f"
  printf 'A Check reading a sensor: `o=$(cmd 2>&1); grep -c '"'"'%s<assertion>'"'"' <<< "$o"`\n' \
    "$OK_ANCHOR" >> "$f"
  pipe_banner >> "$f"

  printf 'A Check reading a sensor merges `2>&1` and anchors on `%s`.\n' \
    "$OK_ANCHOR" > "$root/agents/sdd-planner.md"
  pipe_banner >> "$root/agents/sdd-planner.md"
  printf 'Before PLAN-AUTO, run the kit'"'"'s tests/check-checkpoint.sh --red <checkpoint>.\n' \
    >> "$root/agents/sdd-planner.md"
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

  # ── rule 2 reads the variable the merged output went into, not the whole cell (issue #258) ──
  # A grep that reads a file never sees FAIL text, so only the greps whose herestring reads a
  # variable captured with `2>&1` owe the anchor. Every shape the reader cannot follow falls back to
  # the cell rule, which is closed: each rc-1 probe below would pass on the reading path, so its rc
  # proves the fallback ran.
  local r2_p0="$PROBES" r2_f0="$FAILS" r2
  r2="$box/r2-file.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); a=\$(grep -c '${OK_ANCHOR}x' <<< \"\$o\"); b=\$(grep -c foo f); echo \"\$a \$b\"\` → \`1 0\`"
  probe 'a grep that reads a file owes no anchor beside one that reads the merged output' \
    0 '1 under the anchor rule' "$r2"
  r2="$box/r2-blind.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'beta' <<< \"\$o\"; grep -c '${OK_ANCHOR}x' f\` → \`1 1\`"
  probe 'the unanchored grep of the merged output is caught, whatever anchor another grep carries' \
    1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-loose.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`bash t.sh > out.log 2>&1; grep -c 'alpha' out.log\` → \`1\`"
  probe 'a merge outside a capture falls back to the cell rule' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-leak.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); echo \"\$o\" > f; grep -c x f\` → \`1\`"
  probe 'a merged variable read anywhere but a grep herestring falls back' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-inner.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`n=\$(grep -c x <<< \"\$(bash t.sh 2>&1)\"); echo \"\$n\"\` → \`1\`"
  probe 'a capture that merges and greps falls back' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-quoted.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 'a)b' 2>&1); grep -c '${OK_ANCHOR}a (b); c' <<< \"\$o\"; grep -c 'x;y' f\` → \`1 0\`"
  probe 'a paren or a semicolon inside quotes splits nothing' 0 '1 under the anchor rule' "$r2"
  r2="$box/r2-clean.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh \$(echo a) 2>&1); p=\$(cat f); grep -c '${OK_ANCHOR}a' <<< \"\$o\"; grep -c x <<< \"\$p\"\` → \`1 0\`"
  probe 'a variable captured without the merge owes no anchor, nested parens included' \
    0 '1 under the anchor rule' "$r2"
  r2="$box/r2-open.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1; grep -c x <<< \"\$o\"\` → \`1\`"
  probe 'a capture that never closes falls back' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-concat.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); p=a; grep -c '${OK_ANCHOR}x' <<< \"\$o\$p\"; grep -c y f\` → \`1 0\`"
  probe 'a herestring that concatenates the merged variable falls back' 1 '1 of 2 pattern(s) anchored' "$r2"
  r2="$box/r2-dq.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\"\$(bash t.sh 2>&1)\"; grep -c '${OK_ANCHOR}a' <<< \"\${o}\"; grep -c x f\` → \`1 0\`"
  probe 'a capture inside double quotes taints its name, and a braced read is a read' 0 '1 under the anchor rule' "$r2"
  # Without the single quotes the first `$(` opens a capture that swallows the real merge into a
  # file, and the unanchored grep of that file passes — the fail-open the sabotage pass found.
  r2="$box/r2-sq.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`echo ' o=\$('; bash t.sh > out 2>&1; echo ')'; grep -c x out\` → \`1\`"
  probe 'a $( inside single quotes opens no capture' 1 '0 of 1 pattern(s) anchored' "$r2"
  # The final review of lote 8 (2026-10-15) reproduced two fail-opens. A name the reader never sees
  # written — `${!v}`, a nameref, an `eval` — read the merged stream with no rule at all:
  r2="$box/r2-indirect.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); v=o; grep -c x <<< \"\${!v}\"\` → \`1\`"
  probe 'an indirect expansion falls back to the cell rule' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-nameref.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); declare -n r=o; grep -c x <<< \"\$r\"\` → \`1\`"
  probe 'a nameref falls back to the cell rule' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-eval.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); n=o; eval \"grep -c x <<< \\\${\$n}\"\` → \`1\`"
  probe 'an eval falls back to the cell rule' 1 '0 of 1 pattern(s) anchored' "$r2"
  # And one anchored pattern carried a second, blind one through the same grep, on both paths.
  r2="$box/r2-two-e.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c -e '^ ✓ a' -e 'caso' <<< \"\$o\"\` → \`1\`"
  probe 'a second quoted -e rides on no anchor' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-bare-e.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c -e '^ ✓ a' -e caso <<< \"\$o\"\` → \`1\`"
  probe 'a second unquoted -e rides on no anchor' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-regexp.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c --regexp='^ ✓ a' --regexp=caso <<< \"\$o\"\` → \`1\`"
  probe 'a second --regexp rides on no anchor' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-file-f.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' -f pats.txt <<< \"\$o\"\` → \`1\`"
  probe 'patterns from -f ride on no anchor' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-glued-e.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c -e '^ ✓ a' -ecaso <<< \"\$o\"\` → \`1\`"
  probe 'a pattern glued to -e with no quote rides on no anchor' 1 '0 of 1 pattern(s) anchored' "$r2"
  # grep takes its options anywhere, the herestring's operand included: only that one word is skipped.
  r2="$box/r2-after-hs-e.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c -e 'caso' <<< \"\$o\" -e '^ ✓ a'\` → \`1\`"
  probe 'an -e after the herestring is read too' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-after-hs-f.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' <<< \"\$o\" -f pats.txt\` → \`1\`"
  probe 'an -f after the herestring is read too' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-hs-anchor.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"${OK_ANCHOR}\$o\"\` → \`1\`"
  probe 'the herestring operand is no pattern, whatever it opens with' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-hs-anchor-sq.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< '${OK_ANCHOR}'\"\$o\"\` → \`1\`"
  probe 'a single-quoted part of the herestring operand is no pattern either' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-hs-option.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' <<< -e\$o\` → \`1\`"
  probe 'the herestring operand is no option either' 0 '1 under the anchor rule' "$r2"
  r2="$box/r2-after-hs-pat.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -c <<< \"\$o\" '${OK_ANCHOR}x'\` → \`1\`"
  probe 'an anchored pattern after the herestring anchors' 0 '1 under the anchor rule' "$r2"
  # Two options change what an anchored pattern means (Codex on PR #267): `-F` reads the caret as a
  # literal, so the count is 0 whether the case passed or failed; `-v` counts every other line.
  r2="$box/r2-fixed.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -cF '^ ✓ caso' <<< \"\$o\"\` → \`0\`"
  probe 'a -F pattern anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-fixed-long.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep --fixed-strings -c '^ ✓ caso' <<< \"\$o\"\` → \`0\`"
  probe 'a --fixed-strings pattern anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-invert.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep -vc '${OK_ANCHOR}x' <<< \"\$o\"\` → \`3\`"
  probe 'an inverted match anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-invert-long.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`bash t.sh > out 2>&1; grep --invert-match -c '${OK_ANCHOR}x' out\` → \`3\`"
  probe 'the cell rule refuses --invert-match too' 1 '0 of 1 pattern(s) anchored' "$r2"
  # GNU grep takes an unambiguous PREFIX of a long option as the option (Codex on PR #267, fourth
  # round, measured on grep 3.11): `--fixed` is `--fixed-strings`, `--inv` is `--invert-match`.
  r2="$box/r2-fixed-abbr.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep --fixed -c '^ ✓ caso' <<< \"\$o\"\` → \`0\`"
  probe 'an abbreviated --fixed-strings anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-invert-abbr.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep --inv -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`3\`"
  probe 'an abbreviated --invert-match anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-file-abbr.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(bash t.sh 2>&1); grep --file=pats.txt -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a --file= pattern rides on no anchor' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-regexp-abbr.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c --reg='caso' -e '^ ✓ a' <<< \"\$o\"\` → \`1\`"
  probe 'an abbreviated --regexp counts as a pattern' 1 '0 of 1 pattern(s) anchored' "$r2"
  # The controls: a long option that is no prefix of those four, and the `--` that ends the options
  # (7 real Check cells write it), still let an anchored pattern anchor.
  r2="$box/r2-long-count.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep --count '^ ✓ pass' <<< \"\$o\"\` → \`1\`"
  probe 'a harmless long option leaves the anchor alone' 0 '1 under the anchor rule' "$r2"
  r2="$box/r2-dashdash.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c -- '^ ✓ pass' <<< \"\$o\"\` → \`1\`"
  probe 'the -- that ends the options leaves the anchor alone' 0 '1 under the anchor rule' "$r2"
  # egrep is grep -E and fgrep is grep -F: read like the grep they spell, not left to the substring
  # count of the cell rule, which counted them while the reader did not (Codex, same round).
  r2="$box/r2-egrep.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); egrep -c '^ ✓ pass' <<< \"\$o\"\` → \`1\`"
  probe 'an anchored egrep anchors' 0 '1 under the anchor rule' "$r2"
  r2="$box/r2-egrep-blind.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); egrep -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe 'a blind egrep is refused' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-fgrep.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); fgrep -c '^ ✓ pass' <<< \"\$o\"\` → \`0\`"
  probe 'an fgrep anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-egrep-cell.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`npm test > out.log 2>&1; egrep -c '^ ✓ a' out.log\` → \`1\`"
  probe 'the cell rule reads an anchored egrep as anchored' 0 '1 under the anchor rule' "$r2"
  # An ANSI-C quote can hold a newline, and grep reads one pattern per line of its pattern (Codex on
  # PR #267, third round): the anchor of the first line rode for the second.
  r2="$box/r2-ansi.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c \$'^ ✓ pass\\ncaso' <<< \"\$o\"\` → \`0\`"
  probe 'an ANSI-C quoted pattern anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-ansi-glued.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c '^ ✓ pass'\$'\\n''caso' <<< \"\$o\"\` → \`0\`"
  probe 'an ANSI-C piece glued to an anchored pattern anchors nothing' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-ansi-cell.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`npm test > out.log 2>&1; grep -c \$'^ ✓ a\\ncaso' out.log\` → \`1\`"
  probe 'the cell rule refuses an ANSI-C quoted pattern too' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-ansi-hs.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c '^ ✓ pass' <<< \$'\\n'\"\$o\"\` → \`1\`"
  probe 'an ANSI-C quote in the herestring operand is no pattern' 0 '1 under the anchor rule' "$r2"
  # The flag is per grep: a refused ANSI-C row must not refuse the anchored row after it. Absence,
  # with I1's refusal as the witness that the needle is spelt right.
  r2="$box/r2-ansi-reset.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c \$'^ ✓ a\\ncaso' <<< \"\$o\"\` → \`0\`"
  cp_row "$r2" I2 "\`o=\$(npm test 2>&1); grep -c '^ ✓ b' <<< \"\$o\"\` → \`1\`"
  PROBES=$((PROBES + 1)); local out; out="$("$SELF_PATH" --check "$r2" 2>&1)"
  case "$out" in
    *'the Check of I2 '*|'') printf 'SENSOR-BROKEN: an ANSI-C row leaks its refusal into the next row\n%s\n' "$out" >&2
                            FAILS=$((FAILS + 1)); fail_rc 91 ;;
    *'the Check of I1 '*) ;;
    *) printf 'SENSOR-BROKEN: an ANSI-C row next to an anchored one is not refused\n%s\n' "$out" >&2
       FAILS=$((FAILS + 1)); fail_rc 91 ;;
  esac
  r2="$box/r2-two-anchored.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`o=\$(npm test 2>&1); grep -c -e '^ ✓ a' -e '^ ✓ b' <<< \"\$o\"\` → \`2\`"
  probe 'every -e anchored passes' 0 '1 under the anchor rule' "$r2"
  r2="$box/r2-loose-two-e.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`npm test > out.log 2>&1; grep -c -e '^ ✓ a' -e 'caso' out.log\` → \`1\`"
  probe 'the cell rule reads every pattern of a grep too' 1 '0 of 1 pattern(s) anchored' "$r2"
  r2="$box/r2-loose-echo.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`bash t.sh > out 2>&1; echo '${OK_ANCHOR}x'; grep -c 'y' out\` → \`1\`"
  probe 'the cell rule counts an anchor only inside a grep' 1 '0 of 1 pattern(s) anchored' "$r2"
  # The control the kit's own checkpoints hold (F1 of the 2026-08-16 mission): a quoted FILE beside
  # the anchored pattern is no pattern, and owes no anchor.
  r2="$box/r2-loose-file.md"; cp_head "$r2"
  cp_row "$r2" I1 "\`l=\$(mktemp); bash t.sh >\"\$l\" 2>&1; a=\$(grep -c '${OK_ANCHOR}x' \"\$l\"); echo \"\$a\"\` → \`1\`"
  probe 'a quoted file beside the anchored pattern owes nothing' 0 '1 under the anchor rule' "$r2"
  [ "$FAILS" -eq "$r2_f0" ] && \
    rule_ok "the anchor rule reads the variable the merged output went into, not the whole cell ($((PROBES - r2_p0)) probe(s))"

  # ── the pass mark of a test runner anchors like the ok prefix (issue #249) ──
  # `^`, blanks, then U+2713 and a blank: the mark vitest and Playwright print before a case that
  # passed, and that no failure line opens with. Each rc-1 probe is one step off that shape.
  local r3_p0="$PROBES" r3_f0="$FAILS" r3
  r3="$box/r3-vitest.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^ ✓ src/a.test.ts > caso' <<< \"\$o\"\` → \`1\`"
  probe 'the vitest pass mark, one blank after the caret, anchors' 0 '1 under the anchor rule' "$r3"
  r3="$box/r3-playwright.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npx playwright test 2>&1); grep -c '^  ✓ ' <<< \"\$o\"\` → \`1\`"
  probe 'the Playwright pass mark, two blanks after the caret, anchors' 0 '1 under the anchor rule' "$r3"
  r3="$box/r3-tight.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'the pass mark right after the caret anchors' 0 '1 under the anchor rule' "$r3"
  # The shape the FAIL message names, written literally: ` *` is still blanks before the mark.
  r3="$box/r3-blankstar.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^ *✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'the blank-star the message names anchors' 0 '1 under the anchor rule' "$r3"
  # A star with no blank before it may quantify the caret away in an ERE or a PCRE.
  r3="$box/r3-caretstar.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^*✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'a star right after the caret is caught' 1 '0 of 1 pattern(s) anchored' "$r3"
  r3="$box/r3-nocaret.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c ' ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'a pass mark without the caret is caught, and the message names both anchors' \
    1 '0 of 1 pattern(s) anchored on the ok prefix or on a pass mark' "$r3"
  r3="$box/r3-inside.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^ x ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'a pass mark past the start of the pattern is caught' 1 '0 of 1 pattern(s) anchored' "$r3"
  r3="$box/r3-failmarks.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^ × caso' <<< \"\$o\"; grep -c '^  ✘ caso' <<< \"\$o\"\` → \`1 1\`"
  probe 'the fail marks of vitest and Playwright anchor nothing' 1 '0 of 2 pattern(s) anchored' "$r3"
  r3="$box/r3-heavy.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^ ✔ caso' <<< \"\$o\"\` → \`1\`"
  probe 'the heavy check mark (U+2714), which no measured runner prints, is caught' \
    1 '0 of 1 pattern(s) anchored' "$r3"
  r3="$box/r3-blind.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe 'the bare case name of a runner is still caught' 1 '0 of 1 pattern(s) anchored' "$r3"
  # A quantifier on the mark matches every line that opens with a blank, `  FAIL  ` included: the
  # blank after the mark is what keeps one out.
  r3="$box/r3-star.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`o=\$(npm test 2>&1); grep -c '^ ✓* caso' <<< \"\$o\"\` → \`1\`"
  probe 'a quantifier on the pass mark is caught' 1 '0 of 1 pattern(s) anchored' "$r3"
  # Copied from the source, with the mission slug and the test file renamed: row I1 of the LH-4
  # checkpoint under lighthouse_project/docs/handoffs/ (the mission of 2026-09-27), one of the 10
  # cells it refused before lote 8. It passes only with the reader (a grep of a file beside the
  # capture) and the mark together.
  r3="$box/r3-lh4.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`grep -c '^issue: LH-4\$' docs/handoffs/m/10-ticket.md\` → \`1\`; \`o=\$(npm run test -w packages/frontend 2>&1); grep -c '^ ✓ src/test/a.test.tsx > ' <<< \"\$o\"\` → \`7\`"
  probe 'a target Check that reads a file and the vitest mark passes' 0 '1 under the anchor rule' "$r3"
  # The cell rule counts the same anchors: a merge outside a capture keeps it, with either quote.
  r3="$box/r3-loose.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`npm test > out.log 2>&1; grep -c '^ ✓ a' out.log; grep -c \"^ ✓ b\" out.log\` → \`1 1\`"
  probe 'the cell rule counts the pass mark, in either quote' 0 '1 under the anchor rule' "$r3"
  r3="$box/r3-loose-blind.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`npm test > out.log 2>&1; grep -c ' ✓ a' out.log\` → \`1\`"
  probe 'the cell rule still catches a pass mark without the caret' 1 '0 of 1 pattern(s) anchored' "$r3"
  # A caret alone is no anchor on this path either: the sabotage pass found the count taking every
  # `'^` while the reader's predicate went unasked.
  r3="$box/r3-loose-caret.md"; cp_head "$r3"
  cp_row "$r3" I1 "\`bash t.sh > out.log 2>&1; grep -c '^  ok   a' out.log; grep -c '^ x ✓ b' out.log\` → \`1 1\`"
  probe 'the cell rule asks the same predicate of every caret' 1 '0 of 2 pattern(s) anchored' "$r3"
  [ "$FAILS" -eq "$r3_f0" ] && \
    rule_ok "a pass mark of a test runner at the start of a line anchors like the ok prefix ($((PROBES - r3_p0)) probe(s))"

  # ── every spelling that merges stderr into stdout puts the cell under the rule (issue #269) ──
  # Measured on bash 5.2.21: twelve spellings besides `2>&1` send the FAIL text where the stdout
  # goes, and the precondition read only that literal. A merge inside a capture taints its name;
  # one into a file (`&>f`, `>&f`) reaches the cell rule. The controls reach no grep: the null
  # device, a duplication onto another descriptor, a closed stderr. No expected value here is a
  # zero, so no fixture rides on the exemption of a pair that expects only zeros.
  local mg_p0="$PROBES" mg_f0="$FAILS" mg mg_g mg_k=0
  # A word after `2>&` or `2<&` is a descriptor known only at run time (`2<&$one` merges, measured).
  for mg_g in '2>& 1' '2>&1-' '2<&1' '2>&01' '2>&"1"' '2>&$one' '2<&$one'; do
    mg_k=$((mg_k + 1)); mg="$box/mg-capture$mg_k.md"; cp_head "$mg"
    cp_row "$mg" I1 "\`o=\$(bash t.sh $mg_g); grep -c 'alpha' <<< \"\$o\"\` → \`1\`"
    probe "a capture merged with '$mg_g' owes the anchor" 1 '0 of 1 pattern(s) anchored' "$mg"
  done
  # `&>1` and `&>-` name files (measured: both streams land in them); only `>&` reads a digit or a
  # `-` as a descriptor. And the null device is the exact word, never a path that opens with it.
  for mg_g in '&>f' '&> f' '&>>f' '>&f' '>& f' '1>&f' '&>1' '&>/dev/null.log'; do
    mg_k=$((mg_k + 1)); mg="$box/mg-file$mg_k.md"; cp_head "$mg"
    cp_row "$mg" I1 "\`bash t.sh $mg_g; grep -c 'alpha' f\` → \`1\`"
    probe "a merge into a file with '$mg_g' reaches the cell rule" 1 '0 of 1 pattern(s) anchored' "$mg"
  done
  # A new spelling taints the name the way `2>&1` does, so the grep of a file beside it owes nothing:
  # read only as a merge left outside the captures, the cell would fall back and refuse `b`.
  mg="$box/mg-taint.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`o=\$(bash t.sh 2<&1); a=\$(grep -c '${OK_ANCHOR}alpha' <<< \"\$o\"); b=\$(grep -c 'beta' f); echo \"\$a \$b\"\` → \`1 0\`"
  probe "a capture merged with '2<&1' taints its name like '2>&1'" 0 '1 under the anchor rule' "$mg"
  # The same with the operator as the first character of the capture's text (`&>f cmd` is valid).
  mg="$box/mg-taint-head.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`o=\$(&>f bash t.sh; cat f); a=\$(grep -c '${OK_ANCHOR}alpha' <<< \"\$o\"); b=\$(grep -c 'beta' g); echo \"\$a \$b\"\` → \`1 0\`"
  probe 'a merge at the first character of a capture taints its name' 0 '1 under the anchor rule' "$mg"
  # There is no character before it, so the last one of the text (`2`) is never read in its place:
  # `>&1` sends stdout onto itself, and `o` stays clean.
  mg="$box/mg-head-nothing.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`o=\$(>&1 bash t.sh 2); p=\$(bash u.sh 2>&1); a=\$(grep -c '${OK_ANCHOR}x' <<< \"\$p\"); b=\$(grep -c 'y' <<< \"\$o\"); echo \"\$a \$b\"\` → \`1 1\`"
  probe 'an operator at the first character reads no descriptor before it' 0 '1 under the anchor rule' "$mg"
  # `2>&3` and `2>&10` duplicate onto a third descriptor, which this reader does not follow (a
  # declared limit); `&> /dev/null` checks the blanks before the target are skipped.
  for mg_g in '&>/dev/null' '&> /dev/null' '>&2' '1>&2' '2>&-' '2>&3' '2>&10' '3>&1'; do
    mg_k=$((mg_k + 1)); mg="$box/mg-none$mg_k.md"; cp_head "$mg"
    cp_row "$mg" I1 "\`bash t.sh $mg_g; grep -c 'alpha' f\` → \`1\`"
    probe "'$mg_g' merges nothing a grep reads" 0 '0 under the anchor rule' "$mg"
  done
  # The word after the null device ends at a `;` (above), a `&`, a backtick, a blank or a `)`, and
  # at the end of a capture's own text.
  mg="$box/mg-null-amp.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`bash t.sh &>>/dev/null&& grep -c 'alpha' f\` → \`1\`"
  probe "'&>>/dev/null' before a '&' merges nothing" 0 '0 under the anchor rule' "$mg"
  mg="$box/mg-null-tick.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`grep -c 'alpha' f\`; \`bash t.sh >&/dev/null\` → \`1\`"
  probe "'>&/dev/null' before a backtick merges nothing" 0 '0 under the anchor rule' "$mg"
  mg="$box/mg-null-blank.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`bash t.sh &>/dev/null && grep -c 'alpha' f\` → \`1\`"
  probe "'&>/dev/null' before a blank merges nothing" 0 '0 under the anchor rule' "$mg"
  # Modelled on the gates lighthouse_project silences inside a capture in its AMEP missions. The
  # capture is read by no grep, so it pins the null device only through the precondition.
  mg="$box/mg-null-lh.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`q=\$(npm run lint &>/dev/null && echo OK); o=\$(npm test 2>/dev/null); grep -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe 'a capture of gates silenced into the null device merges nothing' 0 '0 under the anchor rule' "$mg"
  mg="$box/mg-null-capture.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`o=\$(bash t.sh 2>&1); q=\$(bash u.sh &>/dev/null); grep -c '${OK_ANCHOR}x' <<< \"\$o\"; grep -c 'caso' <<< \"\$q\"\` → \`1 1\`"
  probe 'a capture silenced into the null device taints nothing' 0 '1 under the anchor rule' "$mg"
  # The stderr redirected onto a path of the stdout merges too (Codex on PR #274, round 1; measured
  # on bash 5.2.21): `/dev/stdout`, `/dev/fd/1` or `/proc/self/fd/1` behind `2>`, `2>>`, `2>|` or
  # `2<>`, blanks before the path, quotes around it. And descriptor 1 of any entry of /proc (round
  # 3): another thread's, the shell's own by `$$`, a pid, a task.
  for mg_g in '2>/dev/stdout' '2>>/dev/stdout' '2<>/dev/stdout' '2> /dev/stdout' '2>/dev/fd/1' \
    '2>/proc/self/fd/1' '2>"/dev/stdout"' "2>'/dev/fd/1'" '2>/proc/thread-self/fd/1' \
    '2>/proc/$$/fd/1' '2>/proc/1234/fd/1' '2>/proc/self/task/77/fd/1'; do
    mg_k=$((mg_k + 1)); mg="$box/mg-capture$mg_k.md"; cp_head "$mg"
    cp_row "$mg" I1 "\`o=\$(bash t.sh $mg_g); grep -c 'alpha' <<< \"\$o\"\` → \`1\`"
    probe "a capture merged with '$mg_g' owes the anchor" 1 '0 of 1 pattern(s) anchored' "$mg"
  done
  # The path ends at a `)` (above), at the end of a capture's own text (the taint below), and at a
  # `;`, a blank, a `&` or a backtick.
  for mg_g in '2>/dev/stdout;' '2>/dev/stdout &&' '2>/dev/stdout&&'; do
    mg_k=$((mg_k + 1)); mg="$box/mg-file$mg_k.md"; cp_head "$mg"
    cp_row "$mg" I1 "\`bash t.sh $mg_g grep -c 'alpha' f\` → \`1\`"
    probe "a merge onto the stdout with '$mg_g' reaches the cell rule" 1 '0 of 1 pattern(s) anchored' "$mg"
  done
  mg="$box/mg-stdout-tick.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`grep -c 'alpha' f\`; \`bash t.sh 2>/dev/stdout\` → \`1\`"
  probe "'2>/dev/stdout' before a backtick merges" 1 '0 of 1 pattern(s) anchored' "$mg"
  mg="$box/mg-stdout-taint.md"; cp_head "$mg"
  cp_row "$mg" I1 "\`o=\$(bash t.sh 2>/dev/stdout); a=\$(grep -c '${OK_ANCHOR}alpha' <<< \"\$o\"); b=\$(grep -c 'beta' f); echo \"\$a \$b\"\` → \`1 0\`"
  probe "a capture merged with '2>/dev/stdout' taints its name, and the anchor holds" \
    0 '1 under the anchor rule' "$mg"
  # Any other path is a file or another stream: the stderr's own, a terminal, a descriptor spelt
  # with a zero (`/dev/fd/01` does not open, measured), a longer path. So is the stdout sent onto
  # itself, beside a `2>` that takes the text past the cheap filter, and a descriptor that only
  # ends in `2` (`12>`).
  for mg_g in '2>/dev/stderr' '2>/dev/fd/2' '2>/dev/tty' '2>/dev/fd/01' '2>/dev/stdout.log' \
    '1>/dev/stdout 2>/dev/null' '>/dev/stdout 2>/dev/null' '12>/dev/stdout' '2>/proc/self/fd/2' \
    '2>/proc/self/fd/10'; do
    mg_k=$((mg_k + 1)); mg="$box/mg-none$mg_k.md"; cp_head "$mg"
    cp_row "$mg" I1 "\`o=\$(bash t.sh $mg_g); grep -c 'alpha' <<< \"\$o\"\` → \`1\`"
    probe "'$mg_g' merges nothing a grep reads" 0 '0 under the anchor rule' "$mg"
  done
  # A `|` splits the row (rule 1), so `2>|` and the `|` after the path are read in process.
  mg_merges 0 'o=$(bash t.sh 2>|/dev/stdout)'
  mg_merges 0 'bash t.sh 2>/dev/stdout| grep -c alpha'
  mg_merges 1 'o=$(bash t.sh 2>|/dev/stdout.log)'
  # The negative control, as wd_tok's: mg_merges has to SAY a mismatch.
  local mg_fs="$FAILS" mg_rc="$SELFTEST_RC"
  mg_merges 1 'bash t.sh 2>&1' 2>/dev/null
  if [ "$FAILS" -eq "$mg_fs" ]; then
    printf 'SENSOR-BROKEN: mg_merges passed an answer it was not given — its probes measure nothing\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  else
    FAILS="$mg_fs"; SELFTEST_RC="$mg_rc"
  fi
  [ "$FAILS" -eq "$mg_f0" ] && \
    rule_ok "every spelling that merges stderr into stdout puts the cell under the anchor rule ($((PROBES - mg_p0)) probe(s))"

  # ── each word of a grep is read by its value, quotes and escapes removed (issue #270, half 1) ──
  # grep receives what bash hands it: quotes and escapes gone, glued parts joined, redirections
  # taken out. The reader kept the quoted literals and the unquoted skeleton of the words apart, so
  # a quoted option (`'-v'`, `"-F"`) was no option, an option's quoted argument (`--label=…`) and a
  # redirection's target were patterns, and an anchor written with escapes was none. No expected
  # value here is a zero, so no fixture rides on the exemption of a pair that expects only zeros.
  local wd_p0="$PROBES" wd_f0="$FAILS" wd wd_t wd_w
  wd="$box/wd-sq-v.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep '-v' -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`3\`"
  probe 'a quoted -v is the option it spells' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-dq-f.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(npm test 2>&1); grep \"-F\" -c '^ ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'a double-quoted -F is the option it spells' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-sq-inv.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep '--inv' -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`3\`"
  probe 'a quoted --inv is the option it abbreviates' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-label.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep --label='${OK_ANCHOR}x' -H -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe "an option's glued argument is no pattern" 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-escaped.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c ^\\ \\ ok\\ \\ \\ \\ x <<< \"\$o\"\` → \`1\`"
  probe 'an anchor written with escapes anchors' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-glued.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c '^  ok'\"    x\" <<< \"\$o\"\` → \`1\`"
  probe 'an anchor written in glued parts anchors' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-redir.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' 2>/dev/null <<< \"\$o\"\` → \`1\`"
  probe 'a redirection beside an anchored pattern leaves it anchored' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-redir-blank.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' 2> /dev/null <<< \"\$o\"\` → \`1\`"
  probe 'a redirection whose target is the next word leaves it anchored' 0 '1 under the anchor rule' "$wd"
  # The kit's own shape (I20 of 20261003-lote-3-a-catraca-desce): the anchor is literal, the rest
  # expands. Decision 8 (a) of lote 9: a pattern that OPENS with an expansion is refused.
  wd="$box/wd-dq-tail.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c \"${OK_ANCHOR}\$k x\" <<< \"\$o\"\` → \`1\`"
  probe 'a literal anchor before an expansion inside double quotes anchors' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-dq-head.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c \"\$p\" <<< \"\$o\"\` → \`1\`"
  probe 'a quoted pattern that opens with an expansion anchors nothing' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-raw-head.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c \$p <<< \"\$o\"\` → \`1\`"
  probe 'an unquoted expansion anchors nothing' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-glob.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}'* <<< \"\$o\"\` → \`1\`"
  probe 'an unquoted glob glued to an anchor anchors nothing' 1 '0 of 1 pattern(s) anchored' "$wd"
  # A redirection's target is no word of grep's argv, whatever it is named.
  wd="$box/wd-redir-target.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' 2>'${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe "a redirection's target is no pattern" 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-redir-target-next.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' 2> '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe "a redirection's target in the next word is no pattern either" 1 '0 of 1 pattern(s) anchored' "$wd"
  # Read by value, the pattern glued to -e or to --regexp= is the pattern it is, quoted or not; the
  # base read the quoted ones, and refused `-ec` (whose pattern is `c`) by the shape of the word.
  # `five` holds an `f`, a `v` and an `e`: the letters of the pattern are no options of the cluster.
  wd="$box/wd-e-glued.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c -e'${OK_ANCHOR}five' <<< \"\$o\"\` → \`1\`"
  probe 'an anchored pattern glued to -e anchors' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-regexp-glued.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c --regexp='${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'an anchored pattern glued to --regexp= anchors' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-e-glued-dq.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c -e\"${OK_ANCHOR}\$k\" <<< \"\$o\"\` → \`1\`"
  probe 'a double-quoted pattern glued to -e anchors on its literal prefix' 0 '1 under the anchor rule' "$wd"
  wd="$box/wd-e-glued-raw.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c -e'${OK_ANCHOR}x'* <<< \"\$o\"\` → \`1\`"
  probe 'a glob glued to the pattern of -e anchors nothing' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-regexp-next-blind.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c --regexp '${OK_ANCHOR}x' --regexp caso <<< \"\$o\"\` → \`1\`"
  probe 'a second --regexp whose pattern is the next word rides on no anchor' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-regexp-glued-blind.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c --regexp=caso '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a blind pattern glued to --regexp= is refused beside an anchored word' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-regexp-next.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c --regexp '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a --regexp whose pattern is the next word anchors' 0 '1 under the anchor rule' "$wd"
  # An option the reader cannot see whole is refused: an expansion could spell `-F` or `--file`.
  wd="$box/wd-opt-name.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep --\"\$x\" -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a long option whose name is an expansion is refused' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-opt-letters.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c\$f '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a short cluster holding an expansion is refused' 1 '0 of 1 pattern(s) anchored' "$wd"
  wd="$box/wd-e-cluster.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -ec '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a pattern glued to -e inside a cluster is read, and owes the anchor' 1 '0 of 1 pattern(s) anchored' "$wd"
  # The value of an ANSI-C quote is not decoded, so an operand holding one is refused: grep receives
  # `-v` here, and the anchored word beside it would count every other line.
  wd="$box/wd-ansi-option.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep \$'-v' -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`3\`"
  probe 'an ANSI-C quoted operand is refused, whatever it spells' 1 '0 of 1 pattern(s) anchored' "$wd"
  # An escaped `\$` is a literal dollar, and the `'…'` after it a plain quote: no ANSI-C quote.
  wd="$box/wd-escaped-ansi.md"; cp_head "$wd"
  cp_row "$wd" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x'\\\$'y' <<< \"\$o\"\` → \`1\`"
  probe "an escaped dollar before a quote is no ANSI-C quote" 0 '1 under the anchor rule' "$wd"
  # The words themselves, read in-process (see wd_tok): text after `grep`, TAB, the words wanted.
  while IFS=$'\t' read -r wd_t wd_w; do
    wd_tok "$wd_t" "$wd_w"
  done <<'WORDS'
 -c 'a b'"c\$d"e\ f	lit[-c|-c]lit[a bc$de f|a bc$de f] out=0 hs= rest=
 "a\"b\\c\$d\e\`" "a$ b"	lit[a"b\c$d\e`|a"b\c$d\e`]lit[a$ b|a$ b] out=0 hs= rest=
 -c "a`b	lit[-c|-c]raw[a<M>|a] out=0 hs= rest=`b
 -c "${a	lit[-c|-c]raw[<M>|] out=0 hs= rest=
 -c "$(a	lit[-c|-c]raw[<M>|] out=0 hs= rest=
 "^x$k y" "${k}" "$(c d)" "`c`" "$1"	dq[^x<M> y|^x]dq[<M>|]dq[<M>|]dq[<M>|]dq[<M>|] out=0 hs= rest=
 $p ${p} $(c d) $1 '^'* ?x [x] ~/f a~ {a,b} {a..c} {a}	raw[<M>|]raw[<M>|]raw[<M>|]raw[<M>|]raw[^<M>|^]raw[<M>x|]raw[<M>x]|]raw[<M>/f|]lit[a~|a~]raw[<M>|]raw[<M>|]lit[{a}|{a}] out=0 hs= rest=
 $'z' "a"$'\n' \$'z' $'a\'b' c $"x" $ a$	ansi[<M>|]ansi[a<M>|a]lit[$z|$z]ansi[<M>|]lit[c|c]lit[x|x]lit[$|$]lit[a$|a$] out=0 hs= rest=
 {a b,c} {a,b	lit[{a|{a]lit[b,c}|b,c}]lit[{a,b|{a,b] out=0 hs= rest=
 ${a:-${b}}x $ab.c (x) y	raw[<M>x|]raw[<M>.c|]raw[<M>|]lit[y|y] out=0 hs= rest=
 -c (x	lit[-c|-c]raw[<M>|] out=0 hs= rest=
 -c <(x	lit[-c|-c]raw[<M>|] out=0 hs= rest=
 -c ${a	lit[-c|-c]raw[<M>|] out=0 hs= rest=
 a\	lit[a\|a\] out=0 hs= rest=
 -c x 2>/dev/null 2> e <f <<< "$o" -v	lit[-c|-c]lit[x|x]lit[-v|-v] out=0 hs=o rest=
 -c x <<<${o} >o	lit[-c|-c]lit[x|x] out=1 hs=o rest=
 -c x <<< "$o$p" 1>f	lit[-c|-c]lit[x|x] out=1 hs=? rest=
 -c x &>/dev/null -v	lit[-c|-c]lit[x|x]lit[-v|-v] out=1 hs= rest=
 -c x &>>f	lit[-c|-c]lit[x|x] out=1 hs= rest=
 -c x >&2 -v	lit[-c|-c]lit[x|x]lit[-v|-v] out=1 hs= rest=
 -c x >>f	lit[-c|-c]lit[x|x] out=1 hs= rest=
 -c x >|f -v	lit[-c|-c]lit[x|x]lit[-v|-v] out=1 hs= rest=
 -c x 01>f	lit[-c|-c]lit[x|x] out=1 hs= rest=
 -c x 2>&1 3>f 10>f 21>f 2>>e <&0 <>f <<w -v	lit[-c|-c]lit[x|x]lit[-v|-v] out=0 hs= rest=
 -c x>f a2>g '2'>h 2>i	lit[-c|-c]lit[x|x]lit[a2|a2]lit[2|2] out=1 hs= rest=
 -c x <(bash t.sh 2>&1) >(cat)	lit[-c|-c]lit[x|x]raw[<M>|]raw[<M>|] out=0 hs= rest=
 -c 'a;b' "c|d" e; grep y	lit[-c|-c]lit[a;b|a;b]lit[c|d|c|d]lit[e|e] out=0 hs= rest=; grep y
 -c x && y	lit[-c|-c]lit[x|x] out=0 hs= rest=&& y
 -c x) y	lit[-c|-c]lit[x|x] out=0 hs= rest=) y
 -c x | y	lit[-c|-c]lit[x|x] out=0 hs= rest=| y
 -c x&& y	lit[-c|-c]lit[x|x] out=0 hs= rest=&& y
 -c x&>f -v	lit[-c|-c]lit[x|x]lit[-v|-v] out=1 hs= rest=
 -c x|y	lit[-c|-c]lit[x|x] out=0 hs= rest=|y
 -c x` y	lit[-c|-c]lit[x|x] out=0 hs= rest=` y
 -c ab'x	lit[-c|-c]raw[ab<M>|ab] out=0 hs= rest=
 -c "ab	lit[-c|-c]raw[ab<M>|ab] out=0 hs= rest=
WORDS
  # The two blanks a table line cannot hold: a TAB inside the text, and a newline that ends it.
  wd_tok $' -c\tx' 'lit[-c|-c]lit[x|x] out=0 hs= rest='
  wd_tok $' -c x\ny' $'lit[-c|-c]lit[x|x] out=0 hs= rest=\ny'
  # The negative control: wd_tok has to SAY a mismatch, or every line above passes unread. Its
  # failure is the expected one, so the counters it moved are put back; a silent wd_tok is the red.
  local wd_fs="$FAILS" wd_rc="$SELFTEST_RC"
  wd_tok ' -c x' 'lit[-c|-c] out=0 hs= rest=' 2>/dev/null
  if [ "$FAILS" -eq "$wd_fs" ]; then
    printf 'SENSOR-BROKEN: wd_tok passed words it was not given — its probes measure nothing\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  else
    FAILS="$wd_fs"; SELFTEST_RC="$wd_rc"
  fi
  [ "$FAILS" -eq "$wd_f0" ] && \
    rule_ok "each word of a grep is read by its value, quotes and escapes removed ($((PROBES - wd_p0)) probe(s))"

  # ── grep's argv is read as getopt_long reads it, and only a pattern owes the anchor (issue #270,
  # half 2) ──
  # The words know their value; the role of each one comes from GNU grep 3.11's own table (R2_LONG
  # and its neighbours): an option, an option's argument, a pattern or a FILE. A word in its own
  # place that was no pattern counted as one, so a FILE beside a blind `-e`, or an option's argument
  # in the next word, named like an anchor passed; three spellings that disarm the caret were never
  # read (`--fixed-regexp`, `-z`, `-X fgrep`), and a FILE or an argument named `grep` was one more
  # grep. Three rows of the plan's table are probes of the groups above and are not repeated:
  # `-ec` (wd-e-cluster), `--regexp '…'` (wd-regexp-next) and `--fixed` (r2-fixed-abbr). No
  # expected value is a zero.
  local gt_p0="$PROBES" gt_f0="$FAILS" gt gt_t gt_w
  gt="$box/gt-label-next.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep --label '${OK_ANCHOR}x' -H -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe "an option's argument in the next word is no pattern" 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-e-file.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -e 'caso' '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'with an -e, every operand is a FILE, whatever it is named' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-fixed-regexp.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep --fixed-regexp -c '^ ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'the hidden --fixed-regexp is -F' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-fixed-r.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep --fixed-r -c '^ ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'a prefix of --fixed-regexp is -F' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-z.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -cz '${OK_ANCHOR}a.*b' <<< \"\$o\"\` → \`1\`"
  probe 'a -z pattern anchors only the start of the whole input' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-null-data.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep --null-data -c '${OK_ANCHOR}a.*b' <<< \"\$o\"\` → \`1\`"
  probe 'a --null-data pattern anchors nothing either' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-x-fgrep.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep -X fgrep -c '^ ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'the fgrep matcher of -X is -F, and no second grep' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-x-fgrep-glued.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep -Xfgrep -c '^ ✓ caso' <<< \"\$o\"\` → \`1\`"
  probe 'the fgrep matcher glued to -X is -F' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-x-egrep.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep -X egrep -c '^ ✓ a' <<< \"\$o\"\` → \`1\`"
  probe 'the egrep matcher of -X leaves the anchor alone' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-x-bad.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep -X nope -c '^ ✓ a' <<< \"\$o\"\` → \`1\`"
  probe 'a matcher grep does not know is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-x-dq.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(npm test 2>&1); grep -X \"\$m\" -c '^ ✓ a' <<< \"\$o\"\` → \`1\`"
  probe 'a matcher the reader cannot see is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-file-grep.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -- '${OK_ANCHOR}x' grep <<< \"\$o\"\` → \`1\`"
  probe 'a FILE named grep is no second grep' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-ambiguous.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep --e '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'an ambiguous prefix is refused, as grep refuses it' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-unknown.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -K -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a letter grep does not know is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-colo.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c --colo=never '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a prefix of two spellings of one option resolves' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-color-next.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c --color never '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'an optional argument takes no next word: that word is the pattern' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-ce.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -ce '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'the -e at the end of a cluster takes the next word' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-reg.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c --reg '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a prefix of --regexp takes the next word as the pattern' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-context.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -5 '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a digit is a context length' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-m-next.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -m 1 '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe "an option's argument in the next word is no FILE either" 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-dd-e.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -- -e <<< \"\$o\"\` → \`1\`"
  probe 'after --, a -e is the pattern' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-dd-v.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -- '${OK_ANCHOR}x' -v <<< \"\$o\"\` → \`1\`"
  probe 'after --, a -v is a FILE' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-dash.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c - '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a lone - is an operand, here the pattern' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-dq-first.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c \"\$p\" '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a pattern that opens with an expansion is not saved by an anchored FILE' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-count-twice.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c --count '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'a long option and its letter read twice are one option' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-none-eq.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep --count=1 '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'an argument to an option that takes none is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-null-exact.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c --null '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe 'an exact name wins over the longer names it is a prefix of' 0 '1 under the anchor rule' "$gt"
  gt="$box/gt-m-last.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' <<< \"\$o\" -m\` → \`1\`"
  probe 'a letter whose argument is missing is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-max-count-last.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' <<< \"\$o\" --max-count\` → \`1\`"
  probe 'a long option whose argument is missing is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-e-then-unknown.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -e '${OK_ANCHOR}x' -K <<< \"\$o\"\` → \`1\`"
  probe 'an unreadable option after an anchored -e is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-f-beside-e.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c -e '${OK_ANCHOR}x' -f pats.txt <<< \"\$o\"\` → \`1\`"
  probe 'patterns from -f ride on no anchored -e' 1 '0 of 1 pattern(s) anchored' "$gt"
  # An ANSI-C quote is never decoded: an operand holding one may be an option to grep (`$'-v'`,
  # measured), so it is refused, pattern or FILE; as an option's argument it is that argument.
  gt="$box/gt-ansi-file.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' \$'-v' <<< \"\$o\"\` → \`1\`"
  probe 'an ANSI-C quoted FILE is refused' 1 '0 of 1 pattern(s) anchored' "$gt"
  gt="$box/gt-ansi-arg.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep --label=\$'x' -c '${OK_ANCHOR}x' <<< \"\$o\"\` → \`1\`"
  probe "an ANSI-C quoted argument of an option is no pattern" 0 '1 under the anchor rule' "$gt"
  # The words of a grep are skipped once read, and the grep a word of its argv runs is read by
  # nobody: the cell rule's count still owes it the anchor, the closed side.
  gt="$box/gt-nested.md"; cp_head "$gt"
  cp_row "$gt" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}x' <<< \"\$o\" \"\$(grep -l y <<< \"\$o\")\"\` → \`1\`"
  probe 'a grep inside a word of another grep still owes the anchor' 1 '1 of 2 pattern(s) anchored' "$gt"
  # What the argv reader publishes, read in-process (see gt_argv): text after `grep`, TAB, wanted.
  # The two long lines run every name and every letter of the table by its exact spelling.
  while IFS=$'\t' read -r gt_t gt_w; do
    gt_argv "$gt_t" "$gt_w"
  done <<'ARGV'
 -ci a -e '^  ok    x' --label=y -H	opts=[ c i e label H ] pats=lit[^  ok    x] plit=1 rc=0
 -X fgrep -c x	opts=[ X F c ] pats=lit[x] plit=1 rc=1
 -Xegrep -c '^  ok    x'	opts=[ X c ] pats=lit[^  ok    x] plit=1 rc=0
 -c "$p" x	opts=[ c ] pats=dq[<M>] plit=0 rc=1
 -m1 -e x -e"^  ok    $k" y	opts=[ m e e ] pats=lit[x]dq[^  ok    <M>] plit=0 rc=1
 -c -- -v x	opts=[ c ] pats=lit[-v] plit=1 rc=1
 -e a -e '^  ok    b' c	opts=[ e e ] pats=lit[a]lit[^  ok    b] plit=1 rc=1
 -c '^  ok    x' $f	opts=[ c ] pats=lit[^  ok    x] plit=1 rc=0
 --label $'x' -c '^  ok    x'	opts=[ label c ] pats=lit[^  ok    x] plit=1 rc=0
 -c --color=never --colour '^  ok    x'	opts=[ c color color ] pats=lit[^  ok    x] plit=1 rc=0
 -c $'^  ok    x'	opts=[ c ? ] pats= plit=0 rc=1
 --fi x	opts=[ ? ] pats= plit=0 rc=1
 -ce	opts=[ c ? ] pats= plit=0 rc=1
 -c	opts=[ c ] pats= plit=0 rc=1
 --after-context=1 --before-context=1 --binary-files=text --context=1 --devices=read --directories=read --exclude=a --exclude-dir=a --exclude-from=a --file=a --group-separator=a --include=a --label=a --max-count=1 --regexp=a --color --colour --basic-regexp --binary --byte-offset --count --dereference-recursive --extended-regexp --files-with-matches --files-without-match --fixed-regexp --fixed-strings --help --ignore-case --initial-tab --invert-match --line-buffered --line-number --line-regexp --no-filename --no-group-separator --no-ignore-case --no-messages --null --null-data --only-matching --perl-regexp --quiet --recursive --silent --text --unix-byte-offsets --version --with-filename --word-regexp	opts=[ A B binary-files C D d exclude exclude-dir exclude-from f group-separator include label m e color color G U b c R E l L F F help i T v line-buffered n x h no-group-separator no-ignore-case s Z z o P q r q a u V H w ] pats=lit[a] plit=1 rc=1
 -abcEFGhHiIlLnoPqrRsTuUvVwxyzZ0123456789 -A1 -B1 -C1 -d1 -D1 -e1 -f1 -m1 -Xgrep	opts=[ a b c E F G h H i I l L n o P q r R s T u U v V w x y z Z 0 1 2 3 4 5 6 7 8 9 A B C d D e f m X ] pats=lit[1] plit=1 rc=1
ARGV
  # The negative control, as wd_tok's: gt_argv has to SAY a mismatch.
  local gt_fs="$FAILS" gt_rc="$SELFTEST_RC"
  gt_argv ' -c x' 'opts=[ ] pats=lit[x] plit=1 rc=1' 2>/dev/null
  if [ "$FAILS" -eq "$gt_fs" ]; then
    printf 'SENSOR-BROKEN: gt_argv passed an argv it was not given — its probes measure nothing\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  else
    FAILS="$gt_fs"; SELFTEST_RC="$gt_rc"
  fi
  [ "$FAILS" -eq "$gt_f0" ] && \
    rule_ok "grep's argv is read as getopt_long reads it, and only a pattern owes the anchor ($((PROBES - gt_p0)) probe(s))"

  # ── a counting grep whose pair expects only zeros owes no anchor (issue #272) ──
  # A `grep -c` whose pair expects `0` turns green only when no line matches, so it is never green
  # over a FAIL line its pattern matches: the anchor buys it nothing. The cell is read as pairs
  # `command` → `expected`, and a grep of a command whose expected value is only zeros is exempt
  # when its count is what the pair prints: it opens a command at the top of the pair's command
  # (inside no `$(…)` or `(…)`), its stdout goes nowhere else, it counts (`-c`), every option it has
  # is on R2_ZERO_OPTS and every pattern is `lit` — and the pair prints nothing else: every other
  # command at its top is one assignment, and the expected value holds one zero per counting grep
  # (PR #274, round 2). Each rc-1 probe breaks one of those; the `-F`, fgrep and ANSI-C fixtures of
  # the groups above, which expect `0` too, stay refused by the list and by the `lit`.
  local zr_p0="$PROBES" zr_f0="$FAILS" zr zr_w zr_k=0
  # Copied from the source, row I8 of the LH-4 checkpoint under lighthouse_project/docs/handoffs/
  # (the mission of 2026-09-27): five pairs, and the build's count of a warning expects zero.
  zr="$box/zr-lh4.md"; cp_head "$zr"
  cp_row "$zr" I8 "\`o=\$(npm run test -w packages/frontend 2>&1); grep -c '^ ✓ src/test/em-ingles-admin.test.tsx > ' <<< \"\$o\"\` → \`3\`; \`grep -c '^ ✓ src/test/texto-cru-fora-do-dicionario.test.ts > ' <<< \"\$o\"\` → \`5\`; \`grep -c 'const PENDENTES: readonly string\\[\\] = \\[\\];' packages/frontend/src/test/texto-cru-fora-do-dicionario.test.ts\` → \`1\`; \`b=\$(npm run build -w packages/frontend 2>&1); grep -ci 'chunks larger than' <<< \"\$b\"\` → \`0\`; \`npm run lint -w packages/frontend && npm run typecheck && npm run knip -w packages/frontend && echo FG-OK\` → \`FG-OK\`"
  probe 'a count of a merged build warning whose pair expects zero owes no anchor' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-two-pairs.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(npm test 2>&1); grep -c '^ ✓ a' <<< \"\$o\"\` → \`3\`; \`b=\$(npm run build 2>&1); grep -ci 'chunks' <<< \"\$b\"\` → \`0\`"
  probe 'the zero pair beside an anchored pair owes no anchor' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-zeros.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\"; grep -c 'b' <<< \"\$o\"\` → \`0 0\`"
  probe 'two counting greps of a pair that expects two zeros owe no anchor' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-mixed.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\"; grep -c 'b' <<< \"\$o\"\` → \`3 0\`"
  probe 'a pair that expects a zero beside a count owes the anchor' 1 '0 of 2 pattern(s) anchored' "$zr"
  probe 'the message names what owes no anchor' 1 'a counting grep (-c) whose pair expects only zeros owes none, when that pair runs only counting greps and assignments and expects one zero per grep' "$zr"
  zr="$box/zr-ten.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`10\`"
  probe 'a count that ends in zero is no zero' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-blank.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \` \`"
  probe 'an expected value with no word is no zero' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-invert.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -vc 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'an inverted count counts every other line' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-quiet.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -qc 'caso' <<< \"\$o\"; echo 0\` → \`0\`"
  probe 'a quiet grep prints no count' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-max.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c -m 0 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a grep that stops at zero matches counts nothing' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-captured.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); n=\$(grep -c 'caso' <<< \"\$o\"); [ \"\$n\" -gt 0 ]; echo \$?\` → \`0\`"
  probe 'a count captured into a variable is not what the pair prints' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-redirected.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\" > /dev/null; echo 0\` → \`0\`"
  probe 'a count sent to the null device is not what the pair prints' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-no-count.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a grep without -c prints lines, no count' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-after-zero.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`true\` → \`0\`; \`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe 'a zero pair before the grep exempts nothing either' 1 '0 of 1 pattern(s) anchored' "$zr"
  # The pairs are the cell's own: a zero pair of one row exempts nothing in the next.
  zr="$box/zr-reset.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  cp_row "$zr" I2 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`1\`"
  probe "a zero pair of one row exempts nothing in the next" 1 'the Check of I2 greps' "$zr"
  zr="$box/zr-other-pair.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`1\`; \`true; echo \$?\` → \`0\`"
  probe 'the zero of another pair exempts nothing' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-unquoted.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → 0 matches"
  probe 'an expected value outside a code span makes no pair' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-prose.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` prints \`0\`"
  probe 'two code spans with no arrow between them make no pair' 1 '0 of 1 pattern(s) anchored' "$zr"
  # `$o` read outside a herestring sends the cell to the cell rule.
  zr="$box/zr-cell.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); p=\$o; grep -c 'caso' <<< \"\$p\"\` → \`0\`"
  probe 'the cell rule exempts the counting grep of a zero pair too' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-dq.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c \"\$p\" <<< \"\$o\"\` → \`0\`"
  probe 'a pattern the reader cannot see whole is no count it can vouch for' 1 '0 of 1 pattern(s) anchored' "$zr"
  # The top of the pair's command, each way into it: a grep that opens a span (prose before it, no
  # `;`), or follows `&&`.
  zr="$box/zr-span-head.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`bash t.sh > out 2>&1\` → \`0\`, and \`grep -c 'caso' out\` → \`0\`"
  probe 'a counting grep that opens the span of a zero pair owes no anchor' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-and.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1) && grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a counting grep after && owes no anchor' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-prefix.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); >/dev/null grep -c 'caso' <<< \"\$o\"; echo 0\` → \`0\`"
  probe 'a redirection before the grep sends its count elsewhere' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-group.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); { true; grep -c 'caso' <<< \"\$o\"; } > /dev/null; echo 0\` → \`0\`"
  probe 'a grep inside a group whose stdout goes elsewhere owes the anchor' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-subshell.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); (true; grep -c 'caso' <<< \"\$o\") > /dev/null; echo 0\` → \`0\`"
  probe 'a grep inside a subshell whose stdout goes elsewhere owes the anchor' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-for-paren.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); for((k=0;k<1;k++)); do true; grep -c 'caso' <<< \"\$o\"; done > /dev/null; echo 0\` → \`0\`"
  probe 'a loop glued to its parens is no assignment' 1 '0 of 1 pattern(s) anchored' "$zr"
  for zr_w in if while until for case select function coproc exec; do
    zr="$box/zr-kw-$zr_w.md"; cp_head "$zr"
    cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); $zr_w x; grep -c 'caso' <<< \"\$o\"\` → \`0\`"
    probe "a grep past '$zr_w' owes the anchor" 1 '0 of 1 pattern(s) anchored' "$zr"
  done
  # The controls: a keyword and a brace expansion in the value of an assignment run nothing. The
  # reader that refused a keyword anywhere at the top (`x=if` too) decided nothing once every
  # command there had to be an assignment or a counting grep, and left (PR #274, round 2).
  zr="$box/zr-iffor.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); x=if; grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a keyword in the value of an assignment opens no compound command' 0 '1 under the anchor rule' "$zr"
  # A compound command inside a capture, or in another pair's command, leaves the top of this one.
  zr="$box/zr-kw-capture.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(for f in a; do bash t.sh; done 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a loop inside the capture leaves the top alone' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-kw-span.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`for f in a; do true; done\` → \`0\`; \`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe "a loop in another pair's command leaves this one alone" 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-brace.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); x={a,b}; grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a brace expansion in an assignment is no group' 0 '1 under the anchor rule' "$zr"
  # The pair prints its counts and nothing else (Codex on PR #274, round 2): a grep that fails
  # (`[` is no regex) prints no count, so a command after it that prints the zero turns the pair
  # green over a FAIL line its pattern matches. Every command at the top of the pair's command is a
  # counting grep or one assignment, each ending at `;`, `&&`, `||` or the span's end, and the
  # expected value holds one zero per counting grep — so a grep that prints nothing leaves the
  # output a word short, and the pair red.
  zr="$box/zr-echo.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\"; echo 0\` → \`0\`"
  probe 'an echo after the grep prints the zero a failed grep never did' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-printf.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"; printf 0\` → \`0\`"
  probe 'a printf after the grep prints the zero too' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-cd.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); cd x && grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a cd before the grep is no assignment' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-pwd.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); pwd; grep -c 'caso' <<< \"\$o\"\` → \`0\`"
  probe 'a command of one word is no assignment' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-path-eq.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\"; ./x=0\` → \`0\`"
  probe 'a program whose path holds a name and = is no assignment' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-assign-cmd.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\"; x=1 echo 0\` → \`0\`"
  probe 'an assignment before a command runs the command' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-bg.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\" & echo 0\` → \`0\`"
  probe 'a grep sent to the background ends no command the pair can count' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-two-one.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\"; grep -c 'b' <<< \"\$o\"\` → \`0\`"
  probe 'one zero for two counting greps' 1 '0 of 2 pattern(s) anchored' "$zr"
  zr="$box/zr-one-two.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\"\` → \`0 0\`"
  probe 'two zeros for one counting grep' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-inner.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); n=\$(true; grep -c 'a' <<< \"\$o\"; true); grep -c 'b' <<< \"\$o\"\` → \`0 0\`"
  probe 'a grep inside a capture is no count the pair prints' 1 '0 of 2 pattern(s) anchored' "$zr"
  zr="$box/zr-file.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`bash t.sh > out 2>&1; grep -c 'caso' out\` → \`0\`"
  probe 'a command whose stdout goes to a file is no assignment either' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-bg-assign.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\"; x=1 & echo 0\` → \`0\`"
  probe 'an assignment sent to the background hides the command after it' 1 '0 of 1 pattern(s) anchored' "$zr"
  # A grep at the top that is no counting grep prints what it likes: `-m 0` prints `0` whatever
  # the input, so its own anchor buys the other grep nothing.
  zr="$box/zr-own-zero.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\"; grep -c -m 0 '${OK_ANCHOR}a' <<< \"\$o\"\` → \`0\`"
  probe 'an anchored grep that prints a zero of its own leaves the other one its anchor' 1 '1 of 2 pattern(s) anchored' "$zr"
  # The exemption is counted once per grep, and only for the greps of the capture.
  zr="$box/zr-once.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '${OK_ANCHOR}a' <<< \"\$o\"\` → \`0\`; \`grep -c 'b' <<< \"\$o\"\` → \`1\`"
  probe 'an anchored count of a zero pair counts once' 1 '1 of 2 pattern(s) anchored' "$zr"
  zr="$box/zr-file-grep.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\"\` → \`1\`; \`grep -c 'b' f\` → \`0\`"
  probe 'an exempt count of a file adds nothing to the greps of the capture' 1 '0 of 1 pattern(s) anchored' "$zr"
  zr="$box/zr-next.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\"\` → \`0\`; \`grep -c 'b' <<< \"\$o\"\` → \`1\`"
  probe 'the exemption of one grep passes to no grep after it' 1 '1 of 2 pattern(s) anchored' "$zr"
  # r2_grep_word reads a grep only as a command word, so the anchored pattern of a pgrep vouches
  # for nothing and its read of `$o` sends the cell to the cell rule. At a25cba6 the same test,
  # inline, had no probe, and dropping it left the selftest green.
  zr="$box/zr-pgrep.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); pgrep -c '${OK_ANCHOR}a' <<< \"\$o\"\` → \`1\`"
  probe 'a word that ends in grep is no grep' 1 '0 of 1 pattern(s) anchored' "$zr"
  # A word that runs a command prints to the stdout the pair is read from (PR #274, round 3): the
  # value of an assignment runs nothing (r2_quiet), and neither does any word or target of the
  # counting grep. Each fixture's grep fails, so the zero would be the command's.
  for zr_w in 'x=>(echo 0)' 'x=<(echo 0)' 'x=$(echo 0 >/proc/$$/fd/1)' 'x=${y:-0}' 'x=a$(echo 0)' \
    'x=$(a)$(b)' 'x=$((1+2))'; do
    zr_k=$((zr_k + 1)); zr="$box/zr-value$zr_k.md"; cp_head "$zr"
    cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); $zr_w; grep -c '[' <<< \"\$o\"\` → \`0\`"
    probe "the value of '$zr_w' is no quiet assignment" 1 '0 of 1 pattern(s) anchored' "$zr"
  done
  # A backtick inside a span opened by two reads as spans of its own, so the grep is in no pair.
  zr="$box/zr-value-tick.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`\` o=\$(bash t.sh 2>&1); x=\`echo 0\`; grep -c '[' <<< \"\$o\" \`\` → \`0\`"
  probe 'a command substitution in backticks exempts nothing' 1 '0 of 1 pattern(s) anchored' "$zr"
  for zr_w in '>(echo 0)' '<(echo 0 >/proc/$$/fd/1)'; do
    zr_k=$((zr_k + 1)); zr="$box/zr-file$zr_k.md"; cp_head "$zr"
    cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' <<< \"\$o\" $zr_w\` → \`0\`"
    probe "a FILE '$zr_w' of the counting grep runs a command" 1 '0 of 1 pattern(s) anchored' "$zr"
  done
  zr="$box/zr-label.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c --label=\"\$(echo 0 >/proc/\$\$/fd/1)\" '[' <<< \"\$o\"\` → \`0\`"
  probe "an option's argument of the counting grep runs a command" 1 '0 of 1 pattern(s) anchored' "$zr"
  # The values that run nothing: a literal, one name read whole (`p=$o` is above), and a `$` inside
  # single quotes, which is a literal.
  for zr_w in 'n=3' 'p="$o"'; do
    zr_k=$((zr_k + 1)); zr="$box/zr-quiet$zr_k.md"; cp_head "$zr"
    cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); $zr_w; grep -c 'caso' <<< \"\$o\"\` → \`0\`"
    probe "the value of '$zr_w' runs nothing" 0 '1 under the anchor rule' "$zr"
  done
  zr="$box/zr-dollar-lit.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c 'caso\$' <<< \"\$o\"\` → \`0\`"
  probe 'a dollar inside single quotes runs nothing' 0 '1 under the anchor rule' "$zr"
  zr="$box/zr-target.md"; cp_head "$zr"
  cp_row "$zr" I1 "\`o=\$(bash t.sh 2>&1); grep -c '[' < <(echo 0 >/proc/\$\$/fd/1) <<< \"\$o\"\` → \`0\`"
  probe 'a redirection target of the counting grep runs a command' 1 '0 of 1 pattern(s) anchored' "$zr"
  # Every clause of r2_quiet, in process, and its negative control.
  zr_quiet "[3][if][{a,b}]['caso\$'][\$o][\"\$o\"][\$(bash t.sh 2>&1)]"
  local zr_uf="$FAILS" zr_urc="$SELFTEST_RC"
  zr_quiet '[3]' 2>/dev/null
  if [ "$FAILS" -eq "$zr_uf" ]; then
    printf 'SENSOR-BROKEN: zr_quiet passed a list it was not given — its probe measures nothing\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  else
    FAILS="$zr_uf"; SELFTEST_RC="$zr_urc"
  fi
  # `||` reaches no cell (rule 1), so its two probes are in-process: the command after it is one
  # of the pair's, and a grep may end at it.
  zr_rule2 '0 of 1' "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\" || echo 0\` → \`0\`"
  zr_rule2 '2 of 2' "\`o=\$(bash t.sh 2>&1); grep -c 'a' <<< \"\$o\" || grep -c 'b' <<< \"\$o\"\` → \`0 0\`"
  # The negative control, as zr_opts's: zr_rule2 has to SAY a mismatch.
  local zr_qf="$FAILS" zr_qrc="$SELFTEST_RC"
  zr_rule2 '1 of 1' "\`o=\$(bash t.sh 2>&1); grep -c 'caso' <<< \"\$o\"\` → \`1\`" 2>/dev/null
  if [ "$FAILS" -eq "$zr_qf" ]; then
    printf 'SENSOR-BROKEN: zr_rule2 passed a verdict it was not given — its probe measures nothing\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  else
    FAILS="$zr_qf"; SELFTEST_RC="$zr_qrc"
  fi
  # The list of options that leave the count alone, read in-process: every identity of the table,
  # each beside `-c`, and the ones the exemption admits, in the table's order.
  zr_opts 'a b c E G h H i n o P s T u U w x y Z e label color line-buffered no-ignore-case'
  # The negative control, as gt_argv's: zr_opts has to SAY a mismatch.
  local zr_fs="$FAILS" zr_rc="$SELFTEST_RC"
  zr_opts 'c' 2>/dev/null
  if [ "$FAILS" -eq "$zr_fs" ]; then
    printf 'SENSOR-BROKEN: zr_opts passed a list it was not given — its probe measures nothing\n' >&2
    FAILS=$((FAILS + 1)); fail_rc 91
  else
    FAILS="$zr_fs"; SELFTEST_RC="$zr_rc"
  fi
  [ "$FAILS" -eq "$zr_f0" ] && \
    rule_ok "a counting grep whose pair expects only zeros owes no anchor ($((PROBES - zr_p0)) probe(s))"
  # GFM makes the leading pipe optional, so a row written without it renders like the rest of the
  # table — and a reader of `|`-led lines skipped it whole (CodeRabbit review of PR #222). The
  # control is the same line below a blank line: a paragraph, which is no row and stays out.
  local bare="$box/bare.md" barepara="$box/barepara.md"
  cp_head "$bare"; cp_row "$bare" I1 '`bash tests/run-all.sh` → verde'
  printf 'I2 | slice | `bash tests/run-all.sh` → verde | pending | — |\n' >> "$bare"
  cp_head "$barepara"; cp_row "$barepara" I1 '`bash tests/run-all.sh` → verde'
  printf '\nI2 | slice | `bash tests/run-all.sh` → verde | pending | — |\n' >> "$barepara"
  probe 'a row with no leading pipe is caught, not skipped' 1 "row I2 has no leading '|'" "$bare"
  probe 'the same line below a blank line is a paragraph, not a row' 0 'barepara.md: 1 row(s)' "$barepara"
  # A `|`-led row with FEWER than five cells is a row too — GFM renders the missing cells empty —
  # and rows_of dropped every line under six fields, so --check never saw it (issue #224). The
  # control is a NARROW table below the checkpoint's, past a blank line: GFM counts a table's
  # columns by its header, and target checkpoints carry such tables, whose rows are no increments.
  local short="$box/short.md" narrow="$box/narrow.md" short_f0="$FAILS"
  cp_head "$short"; cp_row "$short" I1 '`bash tests/run-all.sh` → verde'
  printf '| I2 | slice | pending |\n' >> "$short"
  cp_head "$narrow"; cp_row "$narrow" I1 '`bash tests/run-all.sh` → verde'
  printf '\n| File | sha256 |\n|---|---|\n| db.sql.gz | abc123 |\n' >> "$narrow"
  probe 'a row with fewer than five cells is caught, not skipped' 1 'row I2 has fewer than five cells' "$short"
  # The same short row with no leading pipe (7th Codex review of PR #237): read as GFM renders it,
  # and refused — it used to be skipped on the guess that such a line is prose glued to the table.
  local shortbare="$box/shortbare.md"
  cp_head "$shortbare"; cp_row "$shortbare" I1 '`bash tests/run-all.sh` → verde'
  printf 'I2 | slice | pending |\n' >> "$shortbare"
  probe 'a bare row with fewer than five cells is caught, not skipped' 1 "row I2 has no leading '|'" "$shortbare"
  probe 'a narrow table below the checkpoint is no row of it' 0 'narrow.md: 1 row(s)' "$narrow"
  [ "$FAILS" -eq "$short_f0" ] && \
    rule_ok 'a row with fewer than five cells is refused by name, a narrow table is not'

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
  # Only the ANCHOR half is removed — the template keeps its `2>&1`, and it keeps the pipe banner
  # too — so the probe isolates the half that matters instead of passing because the whole line
  # went away, or because a NEIGHBOURING doc rule fired. The asserted message names the rule:
  # both doc assertions open with "<label> never states", so a probe reading that prefix alone
  # could not tell the ok-anchor rule from the pipe ban.
  build_tree "$notmpl"
  cp_head "$notmpl/templates/checkpoint.md"
  cp_row "$notmpl/templates/checkpoint.md" I1 '`<comando>` → `<esperado>`'
  printf '\n' >> "$notmpl/templates/checkpoint.md"
  printf 'A Check reading a sensor: `o=$(cmd 2>&1); grep -c <assertion> <<< "$o"`\n' \
    >> "$notmpl/templates/checkpoint.md"
  pipe_banner >> "$notmpl/templates/checkpoint.md"
  probe 'a template that forgot the anchor rule is caught' 1 \
    'templates/checkpoint.md never states the ok-anchor rule' "$notmpl" --scan

  build_tree "$noagent"
  printf 'nothing here\n' > "$noagent/agents/sdd-planner.md"
  pipe_banner >> "$noagent/agents/sdd-planner.md"
  probe 'a planner that forgot the anchor rule is caught' 1 \
    'agents/sdd-planner.md never states the ok-anchor rule' "$noagent" --scan

  # The OTHER half of doc_rule, probed on its own: a doc that shows the anchor but never the
  # `2>&1` that makes it necessary states half a rule, and half a rule is how the next planner
  # writes `grep -c '^  ok  ...'` on a stream that never carried FAIL and calls it a Check.
  local halfdoc="$box/halfdoc"
  build_tree "$halfdoc"
  printf 'Anchor on `%s`.\n' "$OK_ANCHOR" > "$halfdoc/agents/sdd-planner.md"
  pipe_banner >> "$halfdoc/agents/sdd-planner.md"
  probe 'a doc stating the anchor without the merge is caught' 1 \
    'agents/sdd-planner.md never states the ok-anchor rule' "$halfdoc" --scan

  # ── the pipe ban, the rule that cost a whole mission and that no doc assertion cobrava ───────
  # It was taught in prose and measured in the scan, and NOTHING joined the two: deleting the
  # banner from templates/checkpoint.md and from the planner left this sensor green, so the next
  # checkpoint would be born not knowing a rule whose violation shifts the runner's columns and
  # still looks healthy. Same shape as doc_rule, one document at a time.
#
  # The sabotage strips the LITERALS the rule reads, never a phrase of the surrounding prose. It
  # used to delete lines matching `escaped as`, and rewording the banner (the day the runner
  # learned to rejoin `\|`) left that sed matching nothing: four probes went on "passing" while
  # sabotaging a file they had not touched. A probe that concludes about an unmodified world is the
  # false-green this whole file exists to refuse — anchor on what is measured, and the mismatch
  # shows up as the probe's own rc instead of as silence.
  strip_lit() { # strip_lit <file> <literal…> — remove every line carrying any of the literals
    local f="$1"; shift
    local lit
    for lit in "$@"; do
      grep -vF -- "$lit" "$f" > "$f.stripped" || true
      mv "$f.stripped" "$f"
    done
  }

  local notmplpipe="$box/notmplpipe" noagentpipe="$box/noagentpipe"
  build_tree "$notmplpipe"
  strip_lit "$notmplpipe/templates/checkpoint.md" "$PIPE_MECH" "$PIPE_ESCAPE"
  probe 'a template that forgot the pipe ban is caught' 1 \
    'templates/checkpoint.md never states the pipe ban' "$notmplpipe" --scan

  build_tree "$noagentpipe"
  strip_lit "$noagentpipe/agents/sdd-planner.md" "$PIPE_MECH" "$PIPE_ESCAPE"
  probe 'a planner that forgot the pipe ban is caught' 1 \
    'agents/sdd-planner.md never states the pipe ban' "$noagentpipe" --scan

  # Each half on its own. A doc naming the MECHANISM without the escape lets the next planner
  # write `\|` and believe GFM saves it — which is the exact mistake the banner exists to stop —
  # and a doc naming the escape without the mechanism gives a prohibition with no reason, which
  # is the kind a later editor deletes as noise.
  local mechonly="$box/mechonly" escapeonly="$box/escapeonly"
  build_tree "$mechonly"
  strip_lit "$mechonly/agents/sdd-planner.md" "$PIPE_ESCAPE"
  probe 'the mechanism without the escape is half a rule' 1 \
    'agents/sdd-planner.md never states the pipe ban' "$mechonly" --scan

  build_tree "$escapeonly"
  strip_lit "$escapeonly/agents/sdd-planner.md" "$PIPE_MECH"
  probe 'the escape without the mechanism is half a rule too' 1 \
    'agents/sdd-planner.md never states the pipe ban' "$escapeonly" --scan

  # Near misses: a doc one character short of each literal must still be refused. The round that
  # killed eight sabotages only DELETED things; SHORTENING a literal — PIPE_MECH="aw", "awk" or even
  # "a", PIPE_ESCAPE='\' — left this selftest green (issue #71, measured on 8033a79), because
  # strip_lit removes lines BY the variable and so follows any shorter literal. These two docs are
  # edited by hand, never derived from the variables: awk with no -F'|', a backslash with no pipe.
  local mechnear="$box/mechnear" escnear="$box/escnear"
  build_tree "$mechnear"
  sed -i "s/with a raw awk -F'|' that/with a raw awk that/" "$mechnear/agents/sdd-planner.md"
  probe "awk without its -F'|' is a near miss, not the mechanism" 1 \
    'agents/sdd-planner.md never states the pipe ban' "$mechnear" --scan
  build_tree "$escnear"
  sed -i 's/not even escaped as `\\|`/not even escaped with a backslash `\\`/' "$escnear/agents/sdd-planner.md"
  probe 'a backslash without the pipe is a near miss, not the escape' 1 \
    'agents/sdd-planner.md never states the pipe ban' "$escnear" --scan

  # And the ok line itself, which is what the mission Check counts: a pipe_rule that returned 0
  # without printing would leave the scan green and one assertion short, in silence.
  local pipeok="$box/pipeok"
  build_tree "$pipeok"
  probe 'a clean tree SAYS the pipe ban was found in both docs' 0 \
    'ok    rule:' "$pipeok" --scan

  # The --red run, taught where the next planner meets it (issue 92). The near miss is written by
  # hand, never derived from RED_DOC: a planner naming only the --check run must still be refused,
  # or a RED_DOC shortened to the script's name would pass on the --check sentence alone (#71).
  local nored="$box/nored" rednear="$box/rednear"
  build_tree "$nored"
  strip_lit "$nored/agents/sdd-planner.md" "$RED_DOC"
  probe 'a planner that forgot the --red run is caught' 1 \
    'agents/sdd-planner.md never states the --red run' "$nored" --scan
  build_tree "$rednear"
  sed -i 's/check-checkpoint[.]sh --red /check-checkpoint.sh --check /' "$rednear/agents/sdd-planner.md"
  probe 'a planner naming only the --check run is a near miss' 1 \
    'agents/sdd-planner.md never states the --red run' "$rednear" --scan
  build_tree "$rednear"
  sed -i 's/tests[/]check-checkpoint[.]sh --red /the --red mode on /' "$rednear/agents/sdd-planner.md"
  probe 'a planner naming --red without the script is a near miss' 1 \
    'agents/sdd-planner.md never states the --red run' "$rednear" --scan

  # ── the calibration, over trees of fake sensors ──
  # These probes do NOT derive their `pass()` lines from OK_ANCHOR: that independence is the whole
  # point, and building them from the variable would reproduce the survivor this rule was born to
  # kill.
  local cal="$box/cal" caldis="$box/caldis" calthin="$box/calthin" i
  mkdir -p "$cal/tests" "$caldis/tests" "$calthin/tests"
  # As many fake sensors as the floor asks for: a tree thinner than the floor answers "almost
  # nothing" before it can answer the question each probe asks.
  for i in $(seq 1 "$CALIBRATE_FLOOR"); do
    printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'" > "$cal/tests/check-$i.sh"
    printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'" > "$caldis/tests/check-$i.sh"
  done
  printf 'pass() { printf %s  ok  %%s\\n%s "$1"; }\n' "'" "'" > "$caldis/tests/check-4.sh"
  # Two FILES, each carrying as many ok lines as the floor asks for: a count of lines would reach
  # the floor here, and only a count of sensors refuses it.
  for i in 1 2; do
    for _ in $(seq 1 "$CALIBRATE_FLOOR"); do
      printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'"
    done > "$calthin/tests/check-$i.sh"
  done
  probe 'the anchor matches what the sensors print' 0 \
    'the prefix the suite' "$cal" --calibrate
  probe 'sensors disagreeing about the prefix is caught' 1 \
    'disagree about the ok prefix' "$caldis" --calibrate
  probe 'calibrating against almost nothing is caught' 1 \
    'calibrated against almost nothing' "$calthin" --calibrate

  # The two shapes calibrate() was blind to while it read only `pass()` lines (issue 113): an ok
  # line printed by an `echo`, and one printed by an inline `printf` with no `pass()` at all. The
  # quote is passed as an argument, as above, so this file's own source carries no needle.
  local calecho="$box/calecho" calinline="$box/calinline"
  mkdir -p "$calecho/tests" "$calinline/tests"
  for i in $(seq 1 "$CALIBRATE_FLOOR"); do
    printf 'pass() { printf %s  ok    %%s\\n%s "$1"; }\n' "'" "'" > "$calecho/tests/check-$i.sh"
    printf 'printf %s  ok    inline\\n%s\n' "'" "'" > "$calinline/tests/check-$i.sh"
  done
  printf 'echo %s  ok   inline%s\n' '"' '"' > "$calecho/tests/check-echo.sh"
  probe 'an echo printing three spaces is caught as a disagreement' 1 \
    'disagree about the ok prefix' "$calecho" --calibrate
  probe 'sensors that print inline, with no pass(), are calibrated' 0 \
    'the prefix the suite' "$calinline" --calibrate

  # The comparison itself. Without this the other three calibration probes pass with the
  # anchor-versus-house test deleted: they only exercise disagreement and the floor, and the
  # agreeing tree agrees ON the anchor. A tree that agrees on something ELSE is the only fixture
  # that can tell "compared" from "did not compare".
  local calelse="$box/calelse"
  mkdir -p "$calelse/tests"
  for i in $(seq 1 "$CALIBRATE_FLOOR"); do
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

  # ── a Check that tests a path the repository ignores (issue 211) ──
  # The checkpoint lives in its own git repo, which ignores `*-review.md` — a pattern the kit does
  # not ignore, so a sensor that resolved the repo from its cwd instead of from the checkpoint's
  # directory would answer differently here than it does for a target repo.
  local ign="$box/ign" f
  mkdir -p "$ign/docs/handoffs/m"
  git -C "$ign" init -q
  printf '*-review.md\n' > "$ign/.gitignore"
  f="$ign/docs/handoffs/m/checkpoint.md"
  cp_head "$f"; cp_row "$f" I1 '`test -f docs/qa/reports/s8-review.md && echo yes` → `yes`'
  probe 'a Check that tests an ignored path is caught' 1 'which the repository ignores' "$f"
  cp_head "$f"; cp_row "$f" I1 '`test -f docs/qa/r1-report.md && echo yes` → `yes`'
  probe 'a Check that tests a path the repository keeps passes' 0 'none blind' "$f"
  cp_head "$f"; cp_row "$f" I1 '`[ -f docs/b-review.md ] && echo yes` → `yes`'
  probe 'the bracket form of test is read too' 1 'which the repository ignores' "$f"
  cp_head "$f"; cp_row "$f" I1 '`[[ -f docs/c-review.md ]] && echo yes` → `yes`'
  probe 'the double-bracket form of test is read too' 1 'which the repository ignores' "$f"

  # And the wiring to scan()'s verdict, over a full tree that is a repo of its own.
  local scanign="$box/scanign"
  build_tree "$scanign"
  git -C "$scanign" init -q
  printf '*-review.md\n' > "$scanign/.gitignore"
  cp_row "$scanign/docs/handoffs/m4/checkpoint.md" I6 '`test -f docs/x-review.md && echo yes` → `yes`'
  probe 'an ignored path makes the whole scan red' 1 \
    'which the repository ignores' "$scanign" --scan

  # ── a done row below a blocked one (issue 216) ──
  # The runner stops the line at the first blocked row, so a done below it was closed past the
  # stop, by hand. The Check is a plain one on purpose: the order is the only thing wrong here.
  local order="$box/order.md" orderok="$box/orderok.md" scanorder="$box/scanorder"
  cp_head "$order"
  cp_row "$order" I1 '`bash tests/run-all.sh` → verde' blocked
  cp_row "$order" I2 '`bash tests/run-all.sh` → verde'
  probe 'a done below a blocked row is caught' 1 'is done below I1, which is blocked' "$order"
  cp_head "$orderok"
  cp_row "$orderok" I1 '`bash tests/run-all.sh` → verde'
  cp_row "$orderok" I2 '`bash tests/run-all.sh` → verde' blocked
  probe 'a done above a blocked row passes' 0 'none blind' "$orderok"
  build_tree "$scanorder"
  cp_row "$scanorder/docs/handoffs/m4/checkpoint.md" I6 '`bash tests/run-all.sh` → verde' blocked
  cp_row "$scanorder/docs/handoffs/m4/checkpoint.md" I7 '`bash tests/run-all.sh` → verde'
  probe 'a done below a blocked row makes the whole scan red' 1 \
    'which is blocked' "$scanorder" --scan

  # ── --red: the Check run at HEAD, refused when it is already green (issue 92) ──
  # One fixture repository, one row per probe. Every refusal shares rc 1, so each probe asserts the
  # message of ITS cause; the two that pass read rc 0, which a sabotage running the wrong rows or
  # inverting the comparison cannot fake. The repo carries `rootmark` and the caller's cwd does not,
  # so the probe reading it proves where the Check ran.
  local red="$box/red" rf nogit="$box/nogit" red_p0="$PROBES" red_f0="$FAILS"
  mkdir -p "$red/docs/handoffs/m" "$nogit/docs/handoffs/m"
  git -C "$red" init -q
  printf 'here\n' > "$red/rootmark"
  rf="$red/docs/handoffs/m/checkpoint.md"
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1` → `1`' pending
  probe 'a Check already green at HEAD is refused' 1 'I1 is already green at HEAD' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 0` → `1`' pending
  probe 'a Check red at HEAD passes and says what it printed' 0 \
    "I1 is red at HEAD (prints '0', wants '1')" "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`bash tests/run-all.sh` → verde' pending
  probe 'prose after the arrow is outside the strict form' 1 'outside the strict form' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 'echo 1 → 1' pending
  probe 'a cell with no code span is outside the strict form' 1 'outside the strict form' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1` → `0`; `echo 2` → `0`' pending
  probe 'two pairs in one cell are outside the strict form' 1 'outside the strict form' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1` → ``' pending
  probe 'an empty expected value is outside the strict form' 1 'outside the strict form' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1` → `1`' 'done'; cp_row "$rf" I2 '`echo 0` → `1`' pending
  probe 'a done row is never run' 0 '1 pending Check(s), every one red at HEAD' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`false` → `0`' pending
  probe 'a Check that prints nothing is refused, whatever its rc' 1 'I1 printed nothing (rc 1)' "$rf" --red
  # A fresh shell, not a subshell of this one: under this file's `set -o pipefail` a Check's own
  # `printf … | grep -q` would answer differently from the shell the executor runs it in.
  cp_head "$rf"; cp_row "$rf" I1 '`shopt -qo pipefail; echo $?` → `0`' pending
  probe "a Check runs in a fresh shell, not under this sensor's options" 0 \
    "I1 is red at HEAD (prints '1', wants '0')" "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`cat rootmark` → `there`' pending
  probe "a Check runs from the root of the checkpoint's repository" 0 "prints 'here'" "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1; echo 2` → `1 2`' pending
  probe 'a multi-line output folds into one line before the comparison' 1 \
    'I1 is already green at HEAD' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1; echo noise >&2` → `1`' pending
  probe 'stderr is not part of what a Check prints' 1 'I1 is already green at HEAD' "$rf" --red
  cp_head "$rf"; cp_row "$rf" I1 '`echo 1` → `1`' 'done'
  probe 'a checkpoint with no pending row measured nothing' 93 'has no pending row' "$rf" --red
  # A pending row with no leading pipe, whose Check is already green, below a red one: skipped, it
  # left --red answering 0 over a Check it never ran (CodeRabbit review of PR #222).
  cp_head "$rf"; cp_row "$rf" I1 '`echo 0` → `1`' pending
  printf 'I2 | slice | `echo 1` → `1` | pending | abc1234 |\n' >> "$rf"
  probe 'a pending row with no leading pipe is refused by --red, never skipped' 1 \
    "row I2 has no leading '|'" "$rf" --red
  # The same for a row with fewer than five cells (issue #224): skipped, --red answered 0.
  cp_head "$rf"; cp_row "$rf" I1 '`echo 0` → `1`' pending
  printf '| I2 | slice | `echo 1` → `1` | pending\n' >> "$rf"
  probe 'a pending row with fewer than five cells is refused by --red, never skipped' 1 \
    'row I2 has fewer than five cells' "$rf" --red
  cp_head "$nogit/docs/handoffs/m/checkpoint.md"
  cp_row "$nogit/docs/handoffs/m/checkpoint.md" I1 '`echo 0` → `1`' pending
  GIT_CEILING_DIRECTORIES="$box" probe 'a checkpoint outside any repository has no root to run from' \
    95 'not inside a git work tree' "$nogit/docs/handoffs/m/checkpoint.md" --red
  # The `[ "$FAILS" -eq "$red_f0" ] &&` guard is the one survivor of the sabotage pass, declared: on
  # its own it changes nothing observable — with any probe of the group broken the selftest rc is
  # already 90, and every reader of this sensor reads the rc. It stays so the rule line never
  # claims a group that just failed.
  [ "$FAILS" -eq "$red_f0" ] && \
    rule_ok "a Check already green at HEAD is refused by --red ($((PROBES - red_p0)) probe(s))"
  # bash 4.0-4.3 call an EMPTY array unbound under `set -u`, and the kit promises bash 4+ (issue
  # #223): `"${w[*]}"` over a Check that printed nothing killed red_norm with `w[*]: unbound
  # variable` on stderr — measured in docker bash:4.3, the verdict right only because the dead
  # substitution left the same empty string. The bash 5 this suite runs on cannot reproduce it
  # (BASH_COMPAT=4.3 does not either), so the assertion reads the function: the guarded expansion
  # check-todo.sh already uses, or red.
  PROBES=$((PROBES + 1))
  case "$(declare -f red_norm)" in
    *'${w[@]+"${w[*]}"}'*)
      pass 'red_norm guards its empty array, which bash 4.0-4.3 call unbound under set -u' ;;
    *) printf 'SENSOR-BROKEN: red_norm expands its array unguarded — bash 4.0-4.3 call an empty one unbound under set -u\n' >&2
       FAILS=$((FAILS + 1)); fail_rc 90 ;;
  esac

  rm -rf "$box"

  if [ "$PROBES" -lt "$PROBE_FLOOR" ]; then
    printf 'SENSOR-BROKEN: only %d probe(s) ran, expected at least %d — probes were deleted\n' \
      "$PROBES" "$PROBE_FLOOR" >&2
    fail_rc 92
  fi
  if [ "$RULE_LINES" -lt "$RULE_FLOOR" ]; then
    printf 'SENSOR-BROKEN: %d rule line(s) printed, expected %d — a group failed or its line was deleted\n' \
      "$RULE_LINES" "$RULE_FLOOR" >&2
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
  --red)      red_one "${2-}"; exit $? ;;
  '')         selftest || exit $?
              rc=0
              calibrate "$ROOT" || rc=1
              scan "$ROOT" || rc=$?
              exit "$rc" ;;
  *)          fail "unknown option: $1 (see the usage header)"; exit 96 ;;
esac
