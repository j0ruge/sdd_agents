#!/usr/bin/env bash
# Sensor for the runner's state machine.
#
# The whole kit rests on one bet: the current phase is DERIVED from the artifacts on disk, and no
# gate can be satisfied by model text. This test builds a fixture repo, makes the artifacts appear
# one at a time, and asserts which phase the runner derives at each step — including the cases
# where the gate MUST fail (done with no commit, grade B, Pending matrix row, open bug in the
# registry).
#
# Usage: tests/check-gates.sh   (exit 0 = state machine correct)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-gates-XXXXXX")"
MISSION="20260101-fixture"
MDIR=""
fails=0

# The Jidoka assertion below runs a REAL (non-dry) `sdd run`, which writes an autonomy ledger row
# on the blocked-increment path. run-all.sh already exports SDD_STATE_DIR for every test it runs,
# but a standalone `tests/check-gates.sh` does not inherit that. Belt and braces, same reason
# check-autonomy.sh does not depend on run-all.sh's export holding.
#
# A directory OF ITS OWN, not "$FIX/state": $FIX becomes the git working tree below (`cd "$FIX" &&
# git init`), and a state/ subdirectory living inside it would be untracked noise in a fixture
# whose whole point is to model a clean, gate-passing repo.
SDD_STATE_FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-gates-state-XXXXXX")"
export SDD_STATE_DIR="$SDD_STATE_FIX"
trap 'rm -rf "$FIX" "$SDD_STATE_FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# assert_phase <description> <expected phase>
assert_phase() {
  local desc="$1" want="$2" got
  got="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
  if [ "$got" = "$want" ]; then pass "$desc → $want"; else fail "$desc" "$want" "$got"; fi
}

# assert_why <description> <phase> <regex expected in the reason>
#
# The regexes below match GATE_WHY, which is runner surface and therefore English — except where
# they match a CONTRACT token (`aprovacao`, `versao`, an artifact file name, a status from a
# third-party skill). Never widen one of these to `.*` to make it pass: an assertion that cannot
# fail is indistinguishable from one that passes, which is what check-mutation.sh exists to catch.
assert_why() {
  local desc="$1" ph="$2" re="$3" got
  got="$( cd "$FIX" && "$SDD" why "$MISSION" "$ph" 2>&1 )"
  # Herestring, never `printf | grep -q` — see the note on assert_why_absent below, and
  # tests/check-pipefail.sh, which is what stops the pipe form from coming back.
  if grep -qE "$re" <<< "$got"; then pass "$desc"
  else fail "$desc" "reason matching /$re/" "$got"; fi
}

# assert_why_absent <description> <phase> <regex that must NOT appear in the reason>
#
# The other half of assert_why, and the reason it exists: when two branches of the runner produce
# DIFFERENT reasons for the same phase, asserting only the expected text leaves the assertion
# unable to say WHICH branch ran — it just fails silently on the other one. Demanding the absence
# of the wrong branch's marker is what makes the pair distinguish them (house rule: the text of
# the right branch AND the absence of the other's marker).
#
# Herestring, never `printf | grep -q`: under `pipefail` the pipe returns 141 when grep FINDS and
# exits before printf finishes writing, so a negative assertion over a long reason would read
# "absent" for the very input that contains it.
assert_why_absent() {
  local desc="$1" ph="$2" re="$3" got
  got="$( cd "$FIX" && "$SDD" why "$MISSION" "$ph" 2>&1 )"
  if grep -qE "$re" <<< "$got"; then fail "$desc" "reason WITHOUT /$re/" "$got"
  else pass "$desc"; fi
}

# ---------------------------------------------------------------------------
echo "== fixture at $FIX =="
# `|| exit`: without `set -e`, a failing `cd` would go on to run `git init`, `sed -i` and
# `git commit` in the REAL repo of whoever ran the test.
cd "$FIX" || exit 1

# No test may spend tokens or network. The real `sdd run` below is only safe because the `blocked`
# Jidoka escapes BEFORE any `run_phase`; if that order breaks, the runner would call claude for
# real. The stub makes that impossible by construction.
mkdir -p "$FIX/.stub"
cat > "$FIX/.stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude — the escalation path did not escape before the session" >&2
exit 97
STUB
chmod +x "$FIX/.stub/claude"
PATH="$FIX/.stub:$PATH"

git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "content" > file.txt
git add -A && git commit -qm "init"

"$SDD" install >/dev/null
cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF
MDIR="$FIX/docs/handoffs/$MISSION"
mkdir -p "$MDIR" "$FIX/docs/qa/reports" "$FIX/docs/qa/bugs"

# --- PLAN ------------------------------------------------------------------
# The artifact file names, the frontmatter keys and the checkpoint header below are CONTRACT and
# stay exactly as templates/ ships them — they are what the runner parses, and this repo's
# OUTPUT_LANG is pt-BR.
echo "== PLAN phase =="
assert_phase "mission with no artifact at all" "PLAN"

cat > "$MDIR/00-missao.md" <<'EOF'
---
missao: 20260101-fixture
aprovacao:
---
# Mission
EOF
: > "$MDIR/01-plano.md"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
EOF
assert_phase "artifacts exist but 'aprovacao' is empty" "PLAN"
assert_why   "PLAN explains the missing approval" "PLAN" "aprovacao"
# And it names the command that ends the wait. An empty `aprovacao:` is the state EVERY plan a
# human approves starts in — the common stall, not the exotic one — and until this assertion the
# reason handed the human the shape to type into the frontmatter BY HAND, which is the exact
# failure `sdd approve` was built to end. The sibling branch of the very same gate (the kaizen-born
# refusal, three lines below it in bin/sdd) already names the remedy, and its comment states the
# rule the two must share: "naming a remedy obliges the remedy to work". A rule applied to one of
# two neighbouring branches is a rule the runner does not have.
#
# The mission NAME is demanded, not the bare verb: `sdd approve` with no argument resolves the
# LATEST mission, which on a repo with several open missions is the wrong one. The one thing a
# stalled human must be able to do is copy the line.
assert_why   "the unapproved plan is told which command approves it" "PLAN" "sdd approve $MISSION"

sed -i 's/^aprovacao:.*/aprovacao: auto/' "$MDIR/00-missao.md"
assert_phase "plan approved (auto) with a pending increment" "EXEC"
# The other half, and the reason the pair is not decoration: a reason that carried the remedy
# unconditionally would satisfy the assertion above while telling an already-approved plan to
# approve itself again. Same fixture, one `sed` apart, so no regime of fixture satisfies both by
# accident — whichever side a regression breaks, the other is standing next to it.
assert_why_absent "and an approved plan is not told to approve itself again" "PLAN" "sdd approve"

# JIRA on with no version stalls at PLAN — a version label is a human decision.
sed -i 's/^JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
assert_phase "JIRA_ENABLED=true with no 'versao:' in 00-missao" "PLAN"
assert_why   "PLAN explains the missing version" "PLAN" "versao"
sed -i 's/^JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh

# --- TICKET ----------------------------------------------------------------
echo "== TICKET phase =="
sed -i 's/^JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
sed -i 's/^aprovacao: auto/aprovacao: auto\nversao: 0.1.0/' "$MDIR/00-missao.md"
printf 'PROJECT=FX\nBOARD=1\n' > .jira-project
assert_phase "JIRA on and no 10-ticket.md" "TICKET"
assert_why   "TICKET reports the missing file" "TICKET" "10-ticket.md"

printf -- '---\nfase: TICKET\nstatus: done\nissue: FX-1\n---\n' > "$MDIR/10-ticket.md"
assert_phase "an issue with no sprint does not pass (a card in the backlog is invisible work)" "TICKET"
assert_why   "TICKET reports the missing sprint" "TICKET" "ACTIVE SPRINT|sprint"

printf -- '---\nfase: TICKET\nstatus: done\nissue: FX-1\nsprint: Sprint 1\n---\n' > "$MDIR/10-ticket.md"
assert_phase "an issue in the active sprint passes" "EXEC"

# back to the no-JIRA state for the rest of the test
sed -i 's/^JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh
rm -f .jira-project "$MDIR/10-ticket.md"

# --- EXEC ------------------------------------------------------------------
echo "== EXEC phase =="
sed -i 's/| I1 | slice one | `true` → 0 | pending | — |/| I1 | slice one | `true` → 0 | done | — |/' \
  "$MDIR/checkpoint.md"
assert_phase "increment 'done' with NO commit does not pass" "EXEC"
assert_why   "EXEC reports a label with no artifact" "EXEC" "with no commit|not an artifact|label"

sed -i 's/| I1 | slice one | `true` → 0 | done | — |/| I1 | slice one | `true` → 0 | done | deadbeef |/' \
  "$MDIR/checkpoint.md"
assert_phase "increment 'done' with a nonexistent commit does not pass" "EXEC"
assert_why   "EXEC reports a phantom commit" "EXEC" "does not exist in the repository"

echo "change" >> file.txt
git add -A && git commit -qm "feat: slice one"

# ORPHAN commit: it exists in the object database but left the history after an amend. It is the
# case `git cat-file -e` lets through — it only asks whether the object exists. Without checking
# reachability, a checkpoint quoting the pre-amend hash satisfies the gate while pointing outside
# the history, and the commit can still vanish at gc with the gate green. Measured by sdd-qa in
# mission 20260814-dry-run-completo, with a real amend.
ORPHAN_HASH="$(git rev-parse --short HEAD)"
git commit -q --amend -m "feat: slice one (amended)"
REAL_HASH="$(git rev-parse --short HEAD)"
sed -i "s/deadbeef/$ORPHAN_HASH/" "$MDIR/checkpoint.md"
if git cat-file -e "${ORPHAN_HASH}^{commit}" 2>/dev/null; then
  pass "fixture: the orphan commit is STILL in the object database (that is what fools the naive gate)"
else
  fail "orphan commit fixture" "object still in the database" "object already collected"
fi
assert_phase "orphan commit (exists but outside the history) does not pass" "EXEC"
assert_why   "EXEC reports a commit outside the history" "EXEC" "NOT in the history|reachable"

sed -i "s/$ORPHAN_HASH/$REAL_HASH/" "$MDIR/checkpoint.md"
assert_phase "real commit but no 20-handoff-exec.md" "EXEC"
assert_why   "EXEC reports the missing handoff" "EXEC" "20-handoff-exec"

printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
git add -A && git commit -qm "chore: handoff"
assert_phase "handoff written, suite green" "QA"

# A RED suite fails the gate. It looks too obvious to test, and that is exactly why nobody tested
# it: the fixture runs `TEST_CMD="true"`, which cannot fail, so a gate that discarded the suite's
# rc would go unnoticed forever. Measured by the `EXEC_ignores_TEST_CMD` mutation, which survived
# green before this assertion existed.
sed -i 's|^TEST_CMD="true"|TEST_CMD="false"|' .sdd/config.sh
assert_phase "a red TEST_CMD fails the EXEC gate" "EXEC"
assert_why   "EXEC reports the red suite" "EXEC" "TEST_CMD failed"
sed -i 's|^TEST_CMD="false"|TEST_CMD="true"|' .sdd/config.sh
assert_phase "TEST_CMD green again hands the mission back to QA" "QA"

# Jidoka: a `blocked` increment escalates ON THE SPOT, without burning a session.
# `sdd run` decides that before invoking claude, so this test spends no tokens.
#
# assert_jidoka <description> — one real `sdd run`, demanding the escalation happen ON THE SPOT.
#
# `exit 3` + "BLOCKED in EXEC" is NOT enough, and believing it was is what let the bug below hide:
# budget exhaustion escalates with the very same rc and the very same message prefix. The two
# discriminators are what make this assertion measure the Jidoka and not its impostor:
#   - "The line stopped on purpose" comes only from the blocked-increment branch;
#   - the claude stub's marker must be ABSENT — that is what "no session spent" means, and the
#     stub planted at the top of this file was only reporting it, never asserted, until now.
assert_jidoka() {
  local desc="$1" out rc
  out="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; rc=$?
  if [ "$rc" -eq 3 ] \
     && grep -q "The line stopped on purpose" <<< "$out" \
     && ! grep -q "the test invoked the real claude" <<< "$out"; then
    pass "$desc"
  else
    fail "$desc" "exit 3, the Jidoka branch, and no session spent" \
         "exit $rc: $(tail -3 <<< "$out")"
  fi
}

cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.jidoka.bak"
sed -i "s/| done | $REAL_HASH |/| blocked | — |/" "$MDIR/checkpoint.md"
rm -f "$MDIR/20-handoff-exec.md"
assert_jidoka "a 'blocked' increment escalates on the spot (exit 3, no session spent)"

# SAME Jidoka, on a checkpoint big enough to reach the failure regime — the assertion above cannot
# see the bug that matters. The runner reads the statuses into a variable and then tests it; while
# that test is a PIPE (`printf … | grep -qx`), `grep -q` exits on the match, `printf` dies of
# SIGPIPE and, under `pipefail`, the pipeline returns 141 — so the `if` reads "no blocked" WHILE
# blocked exists, and the line does NOT stop. `ckstatus` gets one status line per table row, and
# the knob is the rows that come AFTER the `blocked` one — what arms the race is how many bytes are
# left for `printf` to write once `grep` has already matched and exited, never how big the
# checkpoint is. Measured, and this is the whole point: with the `blocked` line at the END of a
# 1.1 MB checkpoint the pre-fix runner stopped CORRECTLY — `printf` has already written everything
# by the time `grep` matches, so its exit kills nothing and there is no SIGPIPE. Put the same line
# near the BEGINNING of the same file and the bug burned 2 sessions.
# Here the `blocked` row sits near the top and every filler row follows it, so on this fixture
# row count and rows-after-blocked coincide: measured, the miss starts between 4000 and 5000 rows,
# and 20000 keeps the assertion deep in the failure regime with margin for a different pipe buffer.
# The rows are generated here on purpose — versioning ~1 MB of fixture would be paying in the repo
# for what a loop produces in milliseconds.
awk 'BEGIN { for (i = 1; i <= 20000; i++) printf "| P%d | filler row | `true` → 0 | pending | — |\n", i }' \
  >> "$MDIR/checkpoint.md"
assert_jidoka "a 'blocked' increment escalates in a checkpoint bigger than the pipe buffer"

mv "$MDIR/checkpoint.jidoka.bak" "$MDIR/checkpoint.md"
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"

# An invalid checkpoint status fails loudly, not in silence.
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.bak"
sed -i "s/| done | $REAL_HASH |/| completed | $REAL_HASH |/" "$MDIR/checkpoint.md"
assert_phase "a status outside the enum fails" "EXEC"
assert_why   "EXEC reports the invalid status" "EXEC" "invalid status"
mv "$MDIR/checkpoint.bak" "$MDIR/checkpoint.md"

# --- QA --------------------------------------------------------------------
# The QA gate has TWO contracts, because there are two kinds of project.
#
# Project WITH an interface: the qa-report/qa-execution skills run and the proof is their dated
# report. Project WITHOUT one: those skills are never even called (`qa_substep` goes straight to
# sdd-qa), so demanding their report would make the gate unsatisfiable precisely when QA did the
# work and found something — there the proof is the `gate:` field of the handoff itself.
echo "== QA phase — project WITH an interface =="
sed -i 's|^E2E_CMD=""|E2E_CMD="true"\nAPP_URL="http://example.invalid"|' .sdd/config.sh
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "QA handoff with no report in docs/qa/reports/" "QA"
assert_why   "QA reports the missing report" "QA" "no report in"

# PROVENANCE: ~/.claude/skills/qa-execution/assets/report-template.md:6, verbatim (only the
# `<ISO timestamp>` was made concrete). The `**Status:**` does NOT open the line and the enum
# legend comes in the comment — the two things the gate measures, and the two a fixture written
# from memory loses. That is how bug 1 was born (~US$ 15 a round in the SQ-97 pilot).
cat > "$FIX/docs/qa/reports/2026-01-01-fixture.md" <<'EOF'
# QA Run Report — 2026-01-01 — fixture
- **Started:** 2026-01-01T10:00:00Z · **Status:** in-progress <!-- in-progress | closed -->
| # | Charter | Status |
|---|---|---|
| 1 | CH-one | Pending |
EOF
assert_phase "report still open (in-progress)" "QA"
assert_why   "QA reports the unclosed report" "QA" "closed"

sed -i 's/\*\*Status:\*\* in-progress/**Status:** closed/' "$FIX/docs/qa/reports/2026-01-01-fixture.md"
assert_phase "report closed but with a Pending row in the matrix" "QA"
assert_why   "QA reports the Pending matrix" "QA" "Pending"

sed -i 's/| 1 | CH-one | Pending |/| 1 | CH-one | Pass |/' "$FIX/docs/qa/reports/2026-01-01-fixture.md"
# PROVENANCE: ~/.claude/skills/qa-report/assets/bug-template.md:1-3, verbatim. The legend
# `<!-- open | fixed | ... -->` is the detail that matters: it contains the word `open` even when
# the Status is `wont-fix`, so a gate grepping `Status.*open` would block a human decision not to
# fix. Without the legend in the fixture, that loosening passes green.
cat > "$FIX/docs/qa/bugs/BUG-20260101-test.md" <<'EOF'
# BUG-20260101-test: something broke
- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->
EOF
assert_phase "bug with Status: open in the registry" "QA"
assert_why   "QA reports the open bug" "QA" "Status: open|bug\(s\) with Status"

sed -i 's/\*\*Status:\*\* open/**Status:** wont-fix/' "$FIX/docs/qa/bugs/BUG-20260101-test.md"
assert_phase "wont-fix is a human decision and does not block" "REVIEW"

# The QA site of latest_matching(), which the r10 fixture below does NOT cover: that one pins the
# REVIEW glob (`40-review-r*.md`), and for three rounds the runner comment claimed on top of it
# that "version order keeps the dated names in the order plain sort gave them, so the qa call sites
# are unaffected". That is a "X answers the same as Y" claim, which this repo requires to be a
# DIFFERENTIAL assertion — and the claim was simply false. Measured on two same-day reports:
#
#   plain sort | tail -1  ->  2026-01-01-fixture.md
#   sort -V    | tail -1  ->  2026-01-01-fixture-final.md
#
# because filevercmp special-cases the `.md` suffix and compares the stems, where plain sort
# compares `-` (0x2D) against `.` (0x2E) and puts `-final` FIRST. Drop the suffix and the two
# orders agree again, which is exactly why reading the code convinced three sessions in a row.
# The QA reports are named `<YYYY-MM-DD>-<scope>.md` by the qa-execution skill, so a same-day pair
# is the ordinary multi-round shape, not a corner case.
#
# The fixture is the smallest one that separates the two orders at THIS call site: the older name
# is the closed/Pass report, the version-ordered pick is a second one still in-progress. A
# lexicographic runner reads the green report and advances to REVIEW; the version-ordering runner
# stays in QA naming the report that actually is not done.
cat > "$FIX/docs/qa/reports/2026-01-01-fixture-final.md" <<'EOF'
# QA Run Report — 2026-01-01 — fixture final round
- **Started:** 2026-01-01T18:00:00Z · **Status:** in-progress <!-- in-progress | closed -->
| # | Charter | Status |
|---|---|---|
| 1 | CH-one | Pending |
EOF
assert_phase "two reports the same day: the pick is by version, not by alphabet" "QA"
assert_why   "QA quotes the version-ordered report" "QA" "2026-01-01-fixture-final\.md"
# `2026-01-01-fixture\.md` and not a looser stem: the version-ordered name is
# `2026-01-01-fixture-final.md`, which does NOT contain `2026-01-01-fixture.md`, so this pattern
# fires on the lexicographic pick and only on it. The first draft anchored on `…fixture\.md is`
# and stayed green under the broken runner — an absence assertion that distinguishes nothing.
assert_why_absent "the lexicographic pick is not the file the gate read" "QA" "2026-01-01-fixture\.md"
rm -f "$FIX/docs/qa/reports/2026-01-01-fixture-final.md"
assert_phase "with the later report gone the gate advances again" "REVIEW"

echo "== QA phase — project WITHOUT an interface =="
# With no E2E_CMD and no APP_URL the docs/qa/ tree is never created by anyone. Here the gate
# measures the handoff: `status: done` only passes together with the evidence of the journey.
sed -i 's|^E2E_CMD="true"|E2E_CMD=""|; s|^APP_URL=.*||' .sdd/config.sh
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "no interface, 'done' with no evidence does not pass" "QA"
assert_why   "QA asks for the journey evidence" "QA" "evidence of the journey|no interface"

printf -- '---\nfase: QA\nstatus: done\ngate: "1 journey walked in the CLI; 1 finding became F1"\n---\n' \
  > "$MDIR/30-handoff-qa.md"
assert_phase "no interface, 'done' WITH evidence passes" "REVIEW"

# skipped short-circuits everything
cp "$MDIR/30-handoff-qa.md" "$MDIR/30.bak"
printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "$MDIR/30-handoff-qa.md"
assert_phase "qa: skipped skips the whole phase" "REVIEW"
mv "$MDIR/30.bak" "$MDIR/30-handoff-qa.md"

# --- REVIEW ----------------------------------------------------------------
echo "== REVIEW phase =="
# PROVENANCE of the three tables below: skills/codereview/references/report-template.md:152-172
# (chewiesoft-marketplace plugin, contract v1.13.0+). They are the 7 real criteria plus the
# `**Overall**` row, in the skill's order — not an invented sample. A 3-row fixture does not
# exercise the parser the way the real report does. Criterion names and grades belong to the
# skill and are never translated.
cat > "$MDIR/40-review-r1.md" <<'EOF'
# Review r1
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Type Safety | A | clean |
| Error Handling | A | clean |
| Security | B | one HIGH |
| Performance | A | clean |
| Test Coverage | A | clean |
| Documentation | A | clean |
| **Overall** | **B** | |
EOF
assert_phase "a review graded B does not pass" "REVIEW"
assert_why   "REVIEW reports the exact grade" "REVIEW" "Security = B"

# The `—` with "Not analyzed" is what the skill emits on a focused review
# (report-template.md:156): a partial review is not a review, and the gate fails it. Copied from
# there, wording included.
cat > "$MDIR/40-review-r2.md" <<'EOF'
# Review r2
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Type Safety | A | clean |
| Error Handling | A | clean |
| Security | — | Not analyzed (focused review on runner) |
| Performance | A | clean |
| Test Coverage | A | clean |
| Documentation | A | clean |
| **Overall** | **A** | |
EOF
assert_phase "a '—' criterion (not analysed) fails too" "REVIEW"

# A real report has sections AFTER the grade table, at a HIGHER level (`##`). The parser used to
# stop only at `###`, kept reading the following tables and failed an all-A report on finding a
# `Commit` column. The fixture reproduces that shape on purpose — what matters here is the
# heading LEVEL, not the words in the headings.
cat > "$MDIR/40-review-r3.md" <<'EOF'
# Review r3
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Type Safety | A | clean |
| Error Handling | A | clean |
| Security | A | clean |
| Performance | A | clean |
| Test Coverage | A | clean |
| Documentation | A | clean |
| **Overall** | **A** | |

## Grading Scale

- **A**: No CRITICAL/HIGH findings; at most minor MEDIUM/LOW items.

---

## Fixes this round

| Commit | What |
|---|---|
| abc1234 | fixes the test |

## Findings recorded in the findings file

| ID | Severity | Destination |
|---|---|---|
| R1-03 | MEDIUM | TODO.md |
EOF
assert_phase "an earlier r<N> without the Overall Grade section does not matter: the last one counts" "REVIEW"
assert_why   "REVIEW reports a dirty tree before approving" "REVIEW" "tree dirty|working tree"

# The round the gate reads is the LATEST BY VERSION, not the last name in the alphabet. With a
# lexicographic order `r10` sorts between `r1` and `r2`, so from the tenth round on the gate would
# read `r3` — an old review, already approved — and let the mission through while the round that
# actually ran sits on disk unread. REVIEW_MAX_ITER is 3 today, which is exactly why this has to
# be a sensor and not a comment: the day someone raises the ceiling the bug arrives silently.
#
# The fixture is the smallest one that separates the two orders: r10 is the ONLY failing report
# among r1/r2/r3/r10, so a lexicographic runner picks r3, finds it all-A and advances to DOCS,
# while a version-ordering runner stays in REVIEW naming r10. Grade C, not the B of r1: the reason
# has to name a grade no other fixture in this file can produce.
cat > "$MDIR/40-review-r10.md" <<'EOF'
# Review r10
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Type Safety | A | clean |
| Error Handling | A | clean |
| Security | C | injection left open |
| Performance | A | clean |
| Test Coverage | A | clean |
| Documentation | A | clean |
| **Overall** | **C** | |
EOF
git add -A && git commit -qm "chore: review r10"
assert_phase "the tenth round counts, not the third: r10 > r3 by version" "REVIEW"
assert_why   "REVIEW quotes the grade of the version-ordered pick" "REVIEW" "40-review-r10\.md: Security = C"
assert_why_absent "the lexicographic pick (r3) is not the file the gate read" "REVIEW" "40-review-r3\.md"

# r10 turns green and the phase advances — proving the gate advances BECAUSE of r10, not despite
# it. Without this second half the assertion above would also pass on a runner that simply never
# leaves REVIEW.
sed -i 's/^| Security | C |.*/| Security | A | clean |/;s/^| \*\*Overall\*\* | \*\*C\*\* |/| **Overall** | **A** |/' \
  "$MDIR/40-review-r10.md"
git add -A && git commit -qm "chore: review"
assert_phase "last review all Grade A, suite green, clean tree" "DOCS"

# --- DOCS ------------------------------------------------------------------
echo "== DOCS phase =="
# The gate reads the Status COLUMN of the table, not the loose word: a 45-docs.md that names
# TODO.md — which sdd-docs is REQUIRED to do — must not fail because of that.
printf '# Docs\n\ndrift checklist\n\n| Area | Doc | Status | Evidence |\n|---|---|---|---|\n| runner | README | ✗ | pending |\n\nFindings recorded in TODO.md for this mission.\n' \
  > "$MDIR/45-docs.md"
git add -A && git commit -qm "chore: partial docs"
assert_phase "drift checklist with a ✗ item" "DOCS"
assert_why   "DOCS reports the area with a pending Status, quoting the value" "DOCS" "Status '✗'"

printf '# Docs\n\ndrift checklist\n\n| Area | Doc | Status | Evidence |\n|---|---|---|---|\n| runner | README | ✅ | commit abc1234 |\n| libs | — | n/a | internal refactor |\n\nFindings recorded in TODO.md for this mission.\n' \
  > "$MDIR/45-docs.md"
git add -A && git commit -qm "chore: docs"
assert_phase "drift checklist complete" "PR"
assert_why   "PR reports the missing 50-pr.md" "PR" "50-pr.md"

# --- the base branch warning -----------------------------------------------
echo "== base branch warning =="
# The warning lived in ONE place, cmd_preflight — and preflight is OPTIONAL, while `sdd run` is
# one of the two doors that open a session which COMMITS. Start the pipeline from `main` and every
# phase commits straight into the base branch, with nothing on screen saying so.
#
# DIFFERENTIAL on purpose. A single fixture standing on `main` cannot tell "warns on the base
# branch" from "always warns" — both produce the same line, and the second is a warning that means
# nothing. So the SAME fixture is read twice, one checkout apart, and the two runs are compared to
# each other: the line present on `main`, absent off it, and everything else byte-identical.
#
# The rc is asserted too, and EQUAL on both sides rather than just 0: the expensive regression here
# is not the warning disappearing, it is the warning becoming a `die` — that would lock the kaizen
# loop out of its own repo the first time a human forgot to branch.
#
# `no_uuid` is what makes the byte comparison possible at all: run_phase prints one fresh
# `session: <uuid>` per projected phase, so two runs of the same fixture never match literally. The
# substitution is anchored on the UUID SHAPE and nothing else — widening it to `session:.*` would
# also erase a phase changing its agent or its model, which is half of what this comparison is for.
no_uuid() { sed -E 's/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/<uuid>/g'; }

# The two streams are captured APART and only then joined, in a fixed order. Not tidiness: it is
# what lets the assertion below read stderr alone. A `2>&1` capture cannot tell `warn` (stderr,
# yellow, prefixed) from `dim` (stdout, quiet) — measured, all three sensors of this mission stayed
# green on that degradation — and a warning nobody sees on the error stream is back to being
# decoration, which is the exact defect this increment closes.
BASE_ERR="$SDD_STATE_FIX/base-branch-main.err"
FEAT_ERR="$SDD_STATE_FIX/base-branch-feature.err"
BASE_RAW="$( cd "$FIX" && "$SDD" run --dry-run "$MISSION" 2>"$BASE_ERR" )"; BASE_RC=$?
git checkout -q -b missao/base-branch-fixture
FEAT_RAW="$( cd "$FIX" && "$SDD" run --dry-run "$MISSION" 2>"$FEAT_ERR" )"; FEAT_RC=$?
git checkout -q main
git branch -q -D missao/base-branch-fixture
# The rc is read from the bare command above, never from a pipeline: `$?` after `cmd | sed` is the
# pipeline's, and this assertion is about the runner's own exit code.
BASE_OUT="$(no_uuid <<< "$BASE_RAW"$'\n'"$(cat "$BASE_ERR")")"
FEAT_OUT="$(no_uuid <<< "$FEAT_RAW"$'\n'"$(cat "$FEAT_ERR")")"

# Herestrings everywhere below, never `printf … | grep -q`: under `pipefail` that form returns 141
# when grep FINDS the match, which inverts the logic for large inputs only. See check-pipefail.sh.
FEAT_WARN="$(grep -c 'you are on the base branch' <<< "$FEAT_OUT")"

# Reads the ERROR stream, and that is deliberate: presence and severity in one assertion, so the
# only way to satisfy it is the `warn` the runner is supposed to print.
if grep -q 'you are on the base branch' "$BASE_ERR"; then
  pass "the base branch warning reaches sdd run"
else
  fail "the base branch warning reaches sdd run" \
       "the warning on the STDERR of a dry run standing on main" \
       "stderr: $(tr '\n' '|' < "$BASE_ERR" | head -c 200)"
fi

if [ "$FEAT_WARN" -eq 0 ]; then
  pass "and it is silent off the base branch (not a warning that always fires)"
else
  fail "and it is silent off the base branch (not a warning that always fires)" \
       "no warning on branch missao/base-branch-fixture" "$(tail -5 <<< "$FEAT_OUT")"
fi

# THE half that separates "the warning was added" from "the warning changed the run": strip the
# warned line from the base-branch output and the two runs have to be the same text. A `sdd run`
# that started behaving differently — an extra gate, a phase skipped, an early return — would pass
# the two assertions above and die here.
if [ "$(grep -v 'you are on the base branch' <<< "$BASE_OUT")" = "$FEAT_OUT" ]; then
  pass "and the warning is the ONLY difference between the two runs"
else
  fail "and the warning is the ONLY difference between the two runs" \
       "identical output once the warned line is removed" \
       "$(diff <(grep -v 'you are on the base branch' <<< "$BASE_OUT") <(printf '%s\n' "$FEAT_OUT") | head -5)"
fi

if [ "$BASE_RC" = "$FEAT_RC" ] && [ "$BASE_RC" -eq 0 ]; then
  pass "and it is a warn and never a die: same rc on both branches ($BASE_RC)"
else
  fail "the warning does not change the rc of sdd run" \
       "the same rc on both branches, and 0" "main=$BASE_RC feature=$FEAT_RC"
fi

# --- sdd approve -----------------------------------------------------------
echo "== sdd approve =="
# Closing the PLAN gate used to mean typing `aprovacao: humano-YYYY-MM-DD` into the frontmatter by
# hand, in the exact shape gate_PLAN greps. Two failure modes, both cheap to hit: the human gets
# the format wrong and the gate stays shut with no explanation, or the human delegates the edit to
# the session — and the session is precisely who may not decide.
#
# A SECOND mission, not the fixture walked above: that one is approved (`auto`) and already at PR,
# and an approve test needs the one state it no longer has — an empty `aprovacao:`. The frontmatter
# below carries a `/` (in `branch:`) and an `&` (in `titulo:`) on purpose: the write has to be a
# surgical rewrite of ONE key, and a naive `sed 's/^aprovacao:.*/…/'` over the whole file is one
# careless replacement away from eating either character.
#
# Frontmatter KEYS are contract and stay exactly as templates/missao.md ships them. The section
# HEADINGS are not: `sdd approve` prints the whole body instead of parsing headings, so the fixture
# spells them in English — templates/check-templates.sh owns the pt-BR heading contract, and
# tests/check-lang.sh (which scans this file) owns the rule that kit surface carries no Portuguese.
# `titulo:` deliberately differs from the body's own heading: grepping it in the output is then
# proof the frontmatter key was READ, not that the body happened to contain the words.
AM="20260102-approve"
AMDIR="$FIX/docs/handoffs/$AM"
mkdir -p "$AMDIR"
cat > "$AMDIR/00-missao.md" <<'EOF'
---
missao: 20260102-approve
titulo: portas & barras — a/b
data: 2026-01-02
versao:
branch: missao/20260102-approve
aprovacao:
ddd: n/a
---

# Mission fixture

## Gate PLAN-AUTO

| # | Criterion | Status | Evidence |
|---|---|---|---|
| a | grill clean | ✅ | criterio-a-evidencia |

## Open questions for the human

pendencia-fixture-unica

aprovacao: humano-YYYY-MM-DD is the shape gate_PLAN greps, quoted here in the body on purpose
EOF
printf '# Plano\n' > "$AMDIR/01-plano.md"
cat > "$AMDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | fatia-de-fixture | `true` → 0 | pending | — |
EOF
# The three artifacts are left UNTRACKED on purpose, and it buys two things for free. First, the
# real first-approval state: nothing says the planner committed, and `git commit -- <path>` refuses
# a path git has never heard of — the command has to stage it. Second, the two siblings become the
# control for the commit's blast radius below: they sit right next to 00-missao.md, uncommitted,
# and a `git add -A` would swallow both.

# --- 1. the preview, and `n` as a real no-op.
#
# The refusal runs FIRST and on the SAME fixture the acceptance will run on: that is what makes the
# pair differential. A command that wrote the approval unconditionally — ignoring the answer — would
# satisfy every assertion about the written value below and die here, and a command that never
# wrote anything would die there. Neither half alone can tell the two apart.
#
# The preview is asserted in the same breath because refusing is only a decision if the human was
# shown what they were refusing: the title, the PLAN-AUTO evidence, the increments and the open
# questions. Approving blind is the manual edit with extra steps.
#
# Herestring, never `printf 'n' | sdd approve`: under `pipefail` that pipe returns 141 the moment
# the command stops reading, which would read as a failing runner. See check-pipefail.sh.
APPROVE_HEAD_0="$(git rev-parse HEAD)"
APPROVE_N_OUT="$( cd "$FIX" && "$SDD" approve "$AM" 2>&1 <<< "n" )"; APPROVE_N_RC=$?
# A bare Enter is the OTHER no, and the one the prompt's shape promises: `[y/N]` says out loud that
# the default is no. Feeding only "n" and "y" leaves that promise untested — an adversarial pass
# added `""` to the accept list and every clause here stayed green while a stray newline approved a
# plan in the human's name. It is the kit's only gate of human consent; the empty answer is the arm
# a careless `read` reaches first.
APPROVE_EMPTY_OUT="$( cd "$FIX" && "$SDD" approve "$AM" 2>&1 <<< "" )"; APPROVE_EMPTY_RC=$?
APPROVE_N_PHASE="$( cd "$FIX" && "$SDD" phase "$AM" 2>&1 )"
if [ "$APPROVE_N_RC" -eq 0 ] \
   && [ "$APPROVE_EMPTY_RC" -eq 0 ] \
   && ! grep -q 'approved: aprovacao' <<< "$APPROVE_EMPTY_OUT" \
   && grep -q 'portas & barras' <<< "$APPROVE_N_OUT" \
   && grep -q 'criterio-a-evidencia' <<< "$APPROVE_N_OUT" \
   && grep -q 'fatia-de-fixture' <<< "$APPROVE_N_OUT" \
   && grep -q 'pendencia-fixture-unica' <<< "$APPROVE_N_OUT" \
   && grep -qx 'aprovacao:' "$AMDIR/00-missao.md" \
   && [ "$(git rev-parse HEAD)" = "$APPROVE_HEAD_0" ] \
   && [ "$APPROVE_N_PHASE" = "PLAN" ]; then
  pass "sdd approve shows title, PLAN-AUTO, increments and open questions — and 'n' changes nothing"
else
  fail "sdd approve shows title, PLAN-AUTO, increments and open questions — and 'n' changes nothing" \
       "the four sections on screen, rc 0, frontmatter untouched, no commit, still PLAN" \
       "rc $APPROVE_N_RC, phase $APPROVE_N_PHASE, approval line '$(grep -m1 '^aprovacao:' "$AMDIR/00-missao.md")': $(tail -3 <<< "$APPROVE_N_OUT")"
fi

# --- 2. `y` writes humano-<today>, never `auto`, and the gate opens.
#
# `auto` is asserted ABSENT and not merely "humano- present": the two values share the gate's happy
# path, so a command that wrote `auto` would close the gate just the same and every rc-reading
# assertion would stay green — while the artifact now claims the PLAN-AUTO table was all ✅ when a
# human in fact typed y. House rule: the text of the right branch AND the absence of the other's
# marker.
#
# The unrelated dirty file is planted here and read by assertion 3 — the commit has to carry
# 00-missao.md and nothing else, and a fixture with a clean tree cannot tell `git commit -- <path>`
# from `git commit -a`.
echo "unrelated change" >> file.txt
# Everything except the FIRST `aprovacao:` line — the one in the frontmatter, the only line the
# write is allowed to touch. `grep -v '^aprovacao:'` would have been the obvious filter and is the
# wrong one: it also hides the copy the fixture body carries at column 0, which is precisely what a
# whole-file `sed 's/^aprovacao:.*/…/'` would rewrite. The filter that hides the defect from the
# assertion is the filter that makes the assertion decorative.
approval_stripped() { awk '!seen && /^aprovacao:/ { seen=1; next } { print }' "$1"; }
APPROVE_FILE_BEFORE="$(approval_stripped "$AMDIR/00-missao.md")"
# The mode rides along because the byte comparison below reads CONTENT and never metadata, and the
# write goes through a `mktemp` (0600) plus a `chmod --reference`. Drop that chmod and the approved
# artifact comes out readable only by whoever approved it — git tracks the exec bit alone, so the
# one property version control cannot show is the one nothing was measuring.
APPROVE_MODE_BEFORE="$(stat -c %a "$AMDIR/00-missao.md")"
APPROVE_DAY_0="$(date +%F)"
APPROVE_Y_OUT="$( cd "$FIX" && "$SDD" approve "$AM" 2>&1 <<< "y" )"; APPROVE_Y_RC=$?
APPROVE_DAY_1="$(date +%F)"
APPROVE_MODE_AFTER="$(stat -c %a "$AMDIR/00-missao.md")"
APPROVE_LINE="$(grep -m1 '^aprovacao:' "$AMDIR/00-missao.md")"
APPROVE_PHASE="$( cd "$FIX" && "$SDD" phase "$AM" 2>&1 )"
if [ "$APPROVE_Y_RC" -eq 0 ] \
   && { [ "$APPROVE_LINE" = "aprovacao: humano-$APPROVE_DAY_0" ] \
        || [ "$APPROVE_LINE" = "aprovacao: humano-$APPROVE_DAY_1" ]; } \
   && ! grep -q 'aprovacao:.*auto' "$AMDIR/00-missao.md" \
   && [ "$(approval_stripped "$AMDIR/00-missao.md")" = "$APPROVE_FILE_BEFORE" ] \
   && [ "$APPROVE_MODE_AFTER" = "$APPROVE_MODE_BEFORE" ] \
   && [ "$APPROVE_PHASE" != "PLAN" ]; then
  pass "sdd approve answered 'y' writes humano-<today>, never 'auto', and opens the PLAN gate"
else
  fail "sdd approve answered 'y' writes humano-<today>, never 'auto', and opens the PLAN gate" \
       "aprovacao: humano-$APPROVE_DAY_0, the rest of the file byte-identical, phase off PLAN" \
       "rc $APPROVE_Y_RC, phase $APPROVE_PHASE, line '$APPROVE_LINE', diff: $(diff <(printf '%s\n' "$APPROVE_FILE_BEFORE") <(approval_stripped "$AMDIR/00-missao.md") | head -4), out: $(tail -2 <<< "$APPROVE_Y_OUT")"
fi

# --- 3. the commit: one file, the conventional message, and no second one.
#
# `sdd approve` is the first thing in the runner that commits, so its blast radius is the assertion:
# the unrelated edit planted above must still be uncommitted afterwards. And the second call has to
# be a no-op — a human who runs it twice, or a script that retries, must not stack a second
# `chore(missao)` commit onto a plan that was already approved.
#
# The subject is ENGLISH with the pt-BR `missao` scope kept, and that is a deliberate departure from
# the pt-BR wording the grill wrote down in 00-missao.md (decision 2). Two reasons, both structural:
# the runner is kit surface installed into repos declaring any OUTPUT_LANG, and here it is the only
# writer — there is no session to write the message in the target language. tests/check-lang.sh
# measures that rule over bin/sdd, and the grill's phrasing carries one of its stopwords, so the
# original subject cannot be spelled in the runner at all. Recorded in the checkpoint notes.
APPROVE_SUBJECT="$(git log -1 --format=%s)"
# Captured into variables and read with herestrings below, never `git … | grep -q`: that pipe
# returns 141 when grep FINDS the line, and both assertions here are positive ones.
APPROVE_TOUCHED="$(git show --name-only --format= HEAD)"
APPROVE_STATUS="$(git status --porcelain)"
APPROVE_FILES="$(grep -c . <<< "$APPROVE_TOUCHED")"
# The mission directory's blast radius, next to the commit's. `frontmatter_write` mktemps INSIDE it,
# so a `cp` where the `mv` belongs leaves `00-missao.md.aBc123` sitting beside the artifacts —
# swept into the next `git add -A`, and read by every glob that walks that directory. The porcelain
# check above says what IS dirty and cannot say what else appeared.
#
# A glob and not `ls | grep -c .`: shellcheck refuses that pipe (SC2010) and the lint step is part
# of the suite, so the original spelling was red on arrival. The two count the same thing here —
# measured, 3 for the clean directory and 4 with a `00-missao.md.aBc123` beside it — and with no
# `nullglob` an empty directory leaves the pattern unexpanded at 1, which is not 3 either: the
# degradation this guards against keeps failing, and it fails closed.
APPROVE_DIR_ENTRIES=( "$AMDIR"/* )
APPROVE_DIR_N="${#APPROVE_DIR_ENTRIES[@]}"
APPROVE_HEAD_1="$(git rev-parse HEAD)"
APPROVE_AGAIN_OUT="$( cd "$FIX" && "$SDD" approve "$AM" 2>&1 <<< "y" )"; APPROVE_AGAIN_RC=$?
if [ "$APPROVE_SUBJECT" = "chore(missao): plan $AM approved by the human" ] \
   && [ "$APPROVE_FILES" -eq 1 ] \
   && [ "$APPROVE_DIR_N" -eq 3 ] \
   && grep -qx "docs/handoffs/$AM/00-missao.md" <<< "$APPROVE_TOUCHED" \
   && grep -q '^ M file.txt' <<< "$APPROVE_STATUS" \
   && [ "$APPROVE_AGAIN_RC" -eq 0 ] \
   && [ "$(git rev-parse HEAD)" = "$APPROVE_HEAD_1" ]; then
  pass "sdd approve commits only 00-missao.md, and approving twice makes no second commit"
else
  fail "sdd approve commits only 00-missao.md, and approving twice makes no second commit" \
       "one file in the commit, the unrelated edit left dirty, HEAD unmoved on the second call" \
       "subject '$APPROVE_SUBJECT', $APPROVE_FILES file(s), rc2 $APPROVE_AGAIN_RC, status: ${APPROVE_STATUS//$'\n'/ · }, second call: $(tail -2 <<< "$APPROVE_AGAIN_OUT")"
fi
git checkout -q -- file.txt

# --- 4. the mission whose frontmatter has no `aprovacao:` key at all.
#
# Deliberately NOT prefixed `sdd approve `: that string is I1's Check in checkpoint.md, and an
# assertion that inflates it turns a contract into a coincidence.
#
# TWO guards of `cmd_approve` are written for this state and NEITHER had a fixture that reached it,
# because all five approve fixtures above ship the key inside the frontmatter:
#
#   - the `inside &&` scope of frontmatter_write, which is what keeps the write inside the first
#     `---` block. The fixture above carries a body copy of `aprovacao:` on purpose, but the
#     frontmatter copy always comes FIRST and `!written` stops there, so the scope guard is never
#     the thing that decides. Measured: deleting `inside && ` left check-gates.sh at 82 `ok`, rc 0,
#     and the whole suite green — while the command silently rewrote mission prose.
#   - the read-back before the commit, which exists precisely because an absent key makes
#     frontmatter_write a no-op by design, and committing that would be an approval approving
#     nothing.
#
# The probe is the FILE BYTES, not the rc: with the key absent both the scoped and the unscoped
# write end at the same `die` (frontmatter() cannot see a body line either way), so rc 1 and "no
# commit" are shared by the defect and the fix. What separates them is whether the body survived.
# The rc and HEAD ride along anyway, as the read-back guard's own half: drop that `die` and this
# assertion fails on the commit that should not exist.
NK="20260102-nokey"
NKDIR="$FIX/docs/handoffs/$NK"
mkdir -p "$NKDIR"
cat > "$NKDIR/00-missao.md" <<'EOF'
---
missao: 20260102-nokey
titulo: a mission whose frontmatter never declared the key
---

# Mission fixture

aprovacao: quoted in the body and nowhere else — the write must not reach this line
EOF
printf '# Plano\n' > "$NKDIR/01-plano.md"
cat > "$NKDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | fatia-de-fixture | `true` → 0 | pending | — |
EOF
NK_BEFORE="$(cat "$NKDIR/00-missao.md")"
NK_HEAD_0="$(git rev-parse HEAD)"
NK_OUT="$( cd "$FIX" && "$SDD" approve "$NK" 2>&1 <<< "y" )"; NK_RC=$?
NK_AFTER="$(cat "$NKDIR/00-missao.md")"
NK_DIR_ENTRIES=( "$NKDIR"/* )
if [ "$NK_RC" -eq 1 ] \
   && [ "$NK_AFTER" = "$NK_BEFORE" ] \
   && [ "${#NK_DIR_ENTRIES[@]}" -eq 3 ] \
   && [ "$(git rev-parse HEAD)" = "$NK_HEAD_0" ] \
   && grep -q "aprovacao" <<< "$NK_OUT"; then
  pass "approve refuses a mission whose frontmatter has no aprovacao: key, and never touches the body"
else
  fail "approve refuses a mission whose frontmatter has no aprovacao: key, and never touches the body" \
       "rc 1, the file byte-identical, three files in the directory, HEAD unmoved" \
       "rc $NK_RC, changed: $(diff <(printf '%s\n' "$NK_BEFORE") <(printf '%s\n' "$NK_AFTER") | head -4), ${#NK_DIR_ENTRIES[@]} file(s): $(tail -2 <<< "$NK_OUT")"
fi

# --- 5. the mission whose plan is not on disk at all ------------------------
#
# `cmd_approve` opens by asking gate_PLAN and dying when the reason starts with `missing `. Until
# this fixture NO world reached that guard: all five approve missions above ship the three
# artifacts, so replacing the `die` with a no-op left this file green — and the command went on to
# print a preview, write `aprovacao: humano-<today>` and commit it, over a mission that is one
# file. The next `sdd run` then opens an EXEC session with no plan and no increments to execute.
#
# THE rc IS NOT THE ASSERTION. `die` ends in rc 1 and so does half this file; what separates the
# guard from its absence is that the artifact and HEAD are untouched, and that the refusal NAMES
# the file that is missing. The name is load-bearing rather than cosmetic: the guard exists to
# hand the human gate_PLAN's OWN diagnosis, and a die that reworded it — or that fired on some
# other reason — would leave the human hunting for which of the three artifacts to write. The
# whole `sdd approve` block is built on GATE_WHY being read and never restated.
#
# Deliberately a SIXTH mission and not a `rm` on one of the five: they are walked in order, and
# assertion 3 reads the directory of $AM as its own blast radius.
NP="20260102-noplan"
NPDIR="$FIX/docs/handoffs/$NP"
mkdir -p "$NPDIR"
cat > "$NPDIR/00-missao.md" <<'EOF'
---
missao: 20260102-noplan
titulo: a mission whose plan was never written
aprovacao:
---

# Mission fixture
EOF
NP_BEFORE="$(cat "$NPDIR/00-missao.md")"
NP_HEAD_0="$(git rev-parse HEAD)"
# `y` on purpose, and it is what makes the world adversarial: the human is answering YES, so the
# only thing between this mission and an approval is the guard under test.
NP_OUT="$( cd "$FIX" && "$SDD" approve "$NP" 2>&1 <<< "y" )"; NP_RC=$?
NP_AFTER="$(cat "$NPDIR/00-missao.md")"
NP_DIR_ENTRIES=( "$NPDIR"/* )
if [ "$NP_RC" -eq 1 ] \
   && [ "$NP_AFTER" = "$NP_BEFORE" ] \
   && [ "${#NP_DIR_ENTRIES[@]}" -eq 1 ] \
   && [ "$(git rev-parse HEAD)" = "$NP_HEAD_0" ] \
   && grep -q '01-plano.md' <<< "$NP_OUT" \
   && ! grep -q 'aprovacao: humano-' "$NPDIR/00-missao.md"; then
  pass "covered: approve refuses a mission whose plan is not on disk, naming the missing artifact"
else
  fail "covered: approve refuses a mission whose plan is not on disk, naming the missing artifact" \
       "rc 1 naming 01-plano.md, the file byte-identical, one file in the directory, HEAD unmoved" \
       "rc $NP_RC, ${#NP_DIR_ENTRIES[@]} file(s), changed: $(diff <(printf '%s\n' "$NP_BEFORE") <(printf '%s\n' "$NP_AFTER") | head -4), out: $(tail -2 <<< "$NP_OUT")"
fi

# --- the declared mission branch -------------------------------------------
echo "== the declared mission branch =="
# `branch:` shipped in templates/missao.md from the start and NOTHING in the runner ever read it.
# The plan declared where the mission's commits belong and the human was the only one honouring it,
# by hand, before every run. In the SQ-97 pilot that hand-off failed once and five phases committed
# into someone else's branch — 16 commits and a `rebase --onto` to undo.
#
# These three assertions run a REAL (non-dry) `sdd run`, for the same reason assert_jidoka does and
# with the same safety: the mission below carries a `blocked` increment, so the runner escalates
# before reaching any `run_phase`, and the claude stub at the top of this file turns a broken
# ordering into a loud failure instead of a spent token. Checking a branch out is a mutation of the
# working tree, which is exactly what `--dry-run` promises not to do — so the first assertion is a
# PAIR, projection against real run, and the guard cannot be deleted without one half dying.
BM="20260103-branch"
BMDIR="$FIX/docs/handoffs/$BM"
mkdir -p "$BMDIR"
: > "$BMDIR/01-plano.md"
# `blocked`, so `sdd run` escalates on the spot: the branch decision happens before the gates, and
# this fixture only ever needs the runner to get that far.
cat > "$BMDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | one slice | `true` → 0 | blocked | — |
EOF
# branch_mission <value of the `branch:` key> — the ONE thing that varies between the cases below.
#
# printf and not a heredoc, because one of the callers passes a value read out of
# templates/missao.md: an unquoted heredoc expands `$` and backticks, so the day someone writes a
# backtick into that placeholder this fixture would EXECUTE it. Quoting the delimiter would kill
# the expansion and the parameter with it.
branch_mission() {
  printf -- '---\nmissao: %s\naprovacao: auto\nbranch: %s\n---\n# Mission fixture\n' \
    "$BM" "$1" > "$BMDIR/00-missao.md"
}

# The line the runner prints when it really does switch. It is asserted PRESENT here and ABSENT in
# case 3, and the pair is the point: a lone absence assertion is satisfied by a runner that never
# announces anything at all, which is how a "silent no-op" check goes vacuous without a word. Both
# halves read the same variable so neither can drift into measuring a different line.
BRANCH_LINE='branch: .* → '

# --- 1. the declared branch exists: check it out — and never in a dry run.
git branch missao/20260103-existing
branch_mission "missao/20260103-existing"
git checkout -q main
BR_DRY_OUT="$( cd "$FIX" && "$SDD" run --dry-run "$BM" 2>&1 )"; BR_DRY_RC=$?
BR_DRY_AT="$(git branch --show-current)"
BR_RUN_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_RUN_RC=$?
BR_RUN_AT="$(git branch --show-current)"
# The switch has to reach the TRAIL as well as the working tree. pipeline.log is where a human (and
# the kaizen judge) reconstructs what a run did, and a checkout is the single event most likely to
# be asked about afterwards — "which branch did phase three commit into?". Asserted here rather
# than in its own case because it is the same event: a switch nobody recorded is half a switch.
BR_LOG="$FIX/.sdd/logs/$BM/pipeline.log"
BR_LOG_LINES="$(grep -c 'BRANCH  main -> missao/20260103-existing' "$BR_LOG" 2>/dev/null || true)"
if [ "$BR_DRY_AT" = "main" ] \
   && [ "$BR_RUN_AT" = "missao/20260103-existing" ] \
   && [ "$BR_DRY_RC" = "$BR_RUN_RC" ] \
   && [ "$BR_LOG_LINES" = "1" ] \
   && grep -qF "branch: main → missao/20260103-existing" <<< "$BR_RUN_OUT" \
   && ! grep -qE "$BRANCH_LINE" <<< "$BR_DRY_OUT" \
   && ! grep -q "the test invoked the real claude" <<< "$BR_RUN_OUT"; then
  pass "branch declared and already there: sdd run checks it out, logs it, and a dry run does neither"
else
  fail "branch declared and already there: sdd run checks it out, logs it, and a dry run does neither" \
       "still on main after the projection, on missao/20260103-existing after the run, same rc, one BRANCH line" \
       "dry: $BR_DRY_AT (rc $BR_DRY_RC) · run: $BR_RUN_AT (rc $BR_RUN_RC) · BRANCH lines: $BR_LOG_LINES: $(tail -2 <<< "$BR_RUN_OUT")"
fi

# --- 2. the declared branch does not exist: created from the CURRENT branch, not from the base.
#
# The distinction is the whole assertion, and a fixture standing on `main` could not make it: both
# behaviours would produce the same tip. So the run starts from a branch carrying a commit that
# exists NOWHERE else, and the new branch has to carry it too. `main` is asserted NOT to contain it
# in the same breath — that is what keeps the check from passing on a fixture where every branch
# happens to share a tip. The direction matters because the plan's own commit lives on the branch
# the human is standing on when they run: cutting from the base would leave it behind.
git checkout -q -b missao/20260103-source
echo "a commit that lives only off the base branch" > branch-source-marker.txt
git add branch-source-marker.txt
git commit -qm "branch fixture: a commit that exists only off main"
BR_SOURCE_TIP="$(git rev-parse HEAD)"
branch_mission "missao/20260103-created"
BR_NEW_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_NEW_RC=$?
BR_NEW_AT="$(git branch --show-current)"
BR_NEW_TIP="$(git rev-parse HEAD)"
BR_MAIN_HAS_SOURCE=0
git merge-base --is-ancestor "$BR_SOURCE_TIP" main 2>/dev/null && BR_MAIN_HAS_SOURCE=1
if [ "$BR_NEW_AT" = "missao/20260103-created" ] \
   && [ "$BR_NEW_TIP" = "$BR_SOURCE_TIP" ] \
   && [ "$BR_MAIN_HAS_SOURCE" -eq 0 ] \
   && [ "$BR_NEW_RC" = "$BR_RUN_RC" ]; then
  pass "branch declared and absent: created from the CURRENT branch, never from the base"
else
  fail "branch declared and absent: created from the CURRENT branch, never from the base" \
       "on missao/20260103-created, tip $BR_SOURCE_TIP (a commit main does not have)" \
       "at $BR_NEW_AT, tip $BR_NEW_TIP, main-has-source $BR_MAIN_HAS_SOURCE, rc $BR_NEW_RC: $(tail -2 <<< "$BR_NEW_OUT")"
fi

# --- 3. the two silent no-ops: the placeholder, and a run already on the declared branch.
#
# templates/missao.md ships a `<...>` placeholder in `branch:` while the name is still unknown, and
# it is not a branch name: git rejects both the `<` and the spaces. A runner that tried would `die`
# and take the whole pipeline with it — so the branch COUNT is asserted alongside the name, because
# "no switch happened" and "no branch was created" are two different failures and only one of them
# shows up in `--show-current`.
#
# The value is READ from the template instead of spelled here, and that bought two things the day
# it was written. The plan for this increment quoted a placeholder the kit does not ship — reading
# the file is what caught it — and a literal would have frozen today's wording into a sensor that
# keeps passing after the template moves on. It also keeps this file free of the Portuguese that
# tests/check-lang.sh forbids on kit surface: the template is artifact prose in OUTPUT_LANG, a
# sensor is not.
#
# The second half is what keeps the same-branch short-circuit honest. Dropping it breaks nothing
# visible: `git checkout` onto the branch you are already on succeeds. What it produces is a run
# that ANNOUNCES a switch that never happened and appends a BRANCH line to pipeline.log every lap
# — a false entry in the audit trail, which is the one thing this repo's gates exist to refuse. So
# both no-ops are asserted SILENT, not merely harmless, and the announcement line is the probe.
# awk with index()/substr() and never a negated class: the awk of this house is mawk, which negates
# BYTES, and a placeholder carrying a curved quote or a dash would silently fall out of the match.
BR_PLACEHOLDER="$(awk '/^branch: / { print substr($0, index($0, ":") + 2); exit }' "$ROOT/templates/missao.md")"
# Without this the whole case degrades in silence: an empty value is a DIFFERENT no-op (the empty
# guard, not the placeholder guard), so a template that stopped shipping a `<...>` here would leave
# the assertion passing while measuring nothing at all.
case "$BR_PLACEHOLDER" in
  '<'*) ;;
  *) fail "SENSOR-BROKEN: the placeholder case reads templates/missao.md" \
          "a <...> placeholder in the template's branch: key" "'$BR_PLACEHOLDER'" ;;
esac
branch_mission "$BR_PLACEHOLDER"
BR_PH_BEFORE="$(git branch --show-current)"
BR_PH_LIST_BEFORE="$(git branch --list)"
BR_PH_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_PH_RC=$?
BR_PH_AFTER="$(git branch --show-current)"
BR_PH_LIST_AFTER="$(git branch --list)"
# Herestrings, never `git branch --list | grep -c`: this file runs under `pipefail` and the house
# rule is one form for all of them, so nobody has to work out which pipes are safe.
BR_PH_N_BEFORE="$(grep -c . <<< "$BR_PH_LIST_BEFORE")"
BR_PH_N_AFTER="$(grep -c . <<< "$BR_PH_LIST_AFTER")"
branch_mission "$BR_PH_AFTER"
BR_SAME_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_SAME_RC=$?
BR_SAME_AT="$(git branch --show-current)"
if [ "$BR_PH_AFTER" = "$BR_PH_BEFORE" ] \
   && [ "$BR_PH_N_AFTER" = "$BR_PH_N_BEFORE" ] \
   && [ "$BR_PH_RC" = "$BR_RUN_RC" ] \
   && ! grep -qE "$BRANCH_LINE" <<< "$BR_PH_OUT" \
   && [ "$BR_SAME_AT" = "$BR_PH_AFTER" ] \
   && [ "$BR_SAME_RC" = "$BR_RUN_RC" ] \
   && ! grep -qE "$BRANCH_LINE" <<< "$BR_SAME_OUT"; then
  pass "branch already there or still a placeholder: both no-ops, and both silent about switching"
else
  fail "branch already there or still a placeholder: both no-ops, and both silent about switching" \
       "on $BR_PH_BEFORE both times, $BR_PH_N_BEFORE branches, rc $BR_RUN_RC, no switch announced" \
       "placeholder: $BR_PH_AFTER, $BR_PH_N_AFTER branches, rc $BR_PH_RC · same-branch: $BR_SAME_AT, rc $BR_SAME_RC · announced: $(grep -cE "$BRANCH_LINE" <<< "$BR_PH_OUT$BR_SAME_OUT")"
fi
git checkout -q main

# --- 4. git refusing the checkout stops the line — a die, never a warn.
#
# Deliberately NOT prefixed `branch `: the checkpoint's Check for this increment counts the three
# cases the plan named, and this is a fourth the adversarial pass demanded. Degrading the `die`
# into a `warn` survived every other assertion here — and it is the worst survivor of the set,
# because a warned run GOES ON: the whole pipeline then commits into whatever branch git left the
# tree on, which is the exact SQ-97 failure this increment exists to close.
#
# The refusal is manufactured the way it actually happens: a tracked file changed on the target
# branch and dirty in the working tree. git will not clobber it, and the runner must not guess on
# top of a tree git already refused.
#
# Two discriminators, because the rc alone cannot tell a die from a warn — a warned run escalates
# on the blocked increment with rc 3, and rc 1 is also what a dozen other `die`s return:
#   - "BLOCKED in EXEC" must be ABSENT. That marker is proof the run went on, which is the whole
#     defect. Its absence is what says the line stopped HERE.
#   - git's own words must be present. `file.txt` is the probe rather than the English sentence
#     around it: git localises that sentence and the kit's preflight measures the GNU userland,
#     never the locale — but the file it refuses to clobber is named in every language, and no
#     paraphrase written in this runner would contain it.
git checkout -q -b missao/20260103-refused
echo "content that lives only on the refused branch" > file.txt
git commit -qam "branch fixture: a conflicting change to a tracked file"
git checkout -q main
echo "an uncommitted local change to that very same file" > file.txt
branch_mission "missao/20260103-refused"
BR_DIE_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_DIE_RC=$?
BR_DIE_AT="$(git branch --show-current)"
if [ "$BR_DIE_RC" -eq 1 ] \
   && [ "$BR_DIE_AT" = "main" ] \
   && grep -q "missao/20260103-refused" <<< "$BR_DIE_OUT" \
   && grep -q "git said:" <<< "$BR_DIE_OUT" \
   && grep -q "file\.txt" <<< "$BR_DIE_OUT" \
   && ! grep -q "BLOCKED in EXEC" <<< "$BR_DIE_OUT"; then
  pass "refused checkout stops the line: rc 1 carrying git's own words, and the run never goes on"
else
  fail "refused checkout stops the line: rc 1 carrying git's own words, and the run never goes on" \
       "rc 1, still on main, git's message quoted, and no phase escalation after it" \
       "rc $BR_DIE_RC at $BR_DIE_AT: $(tail -3 <<< "$BR_DIE_OUT")"
fi
git checkout -q -- file.txt
git branch -q -D missao/20260103-refused

# --- 4b. a declared name git would read as an OPTION is refused before git sees it.
#
# Deliberately NOT prefixed `branch `, for the reason case 4 gives: the checkpoint's Check counts
# the three cases the plan named. This is the second one the adversarial pass demanded, and it is
# the only path in this function that can DESTROY work.
#
# `git checkout -f` is a legal command: it returns 0, switches to nothing, and throws away every
# uncommitted change in the tree. So a `branch: -f` reaching the checkout unfiltered discards the
# human's work, succeeds, and has the runner announce a switch that never happened — the SQ-97
# class with data loss on top, produced by the very function written to close it.
#
# It takes a REF to get there, and that is why this fixture builds one instead of just writing `-f`
# into the frontmatter: a name git refuses to CREATE (`git checkout -b -- '-f'` → "not a valid
# branch name") already dies on the other path, so a fixture without the ref measures nothing.
# `git update-ref` accepts `refs/heads/-f` and `git check-ref-format` calls it valid — measured —
# so the ref-exists path is reachable, and it is the dangerous one.
#
# The probe is the DIRTY FILE, not the rc: a die and a survived `checkout -f` both leave the tree on
# main, and only one of them still has the human's uncommitted line in it. `BLOCKED in EXEC` rides
# along as the "the run went on" marker, exactly as in case 4.
git update-ref "refs/heads/-f" HEAD
printf 'an uncommitted line the human has not saved anywhere else\n' > file.txt
branch_mission "-f"
BR_OPT_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_OPT_RC=$?
BR_OPT_AT="$(git branch --show-current)"
BR_OPT_FILE="$(cat file.txt)"
if [ "$BR_OPT_RC" -eq 1 ] \
   && [ "$BR_OPT_AT" = "main" ] \
   && [ "$BR_OPT_FILE" = "an uncommitted line the human has not saved anywhere else" ] \
   && ! grep -qE "$BRANCH_LINE" <<< "$BR_OPT_OUT" \
   && ! grep -q "BLOCKED in EXEC" <<< "$BR_OPT_OUT"; then
  pass "a declared name git would read as an option is refused, and the dirty tree survives it"
else
  fail "a declared name git would read as an option is refused, and the dirty tree survives it" \
       "rc 1, still on main, the uncommitted line intact, no switch announced and no phase after it" \
       "rc $BR_OPT_RC at $BR_OPT_AT, file.txt now '$BR_OPT_FILE': $(tail -3 <<< "$BR_OPT_OUT")"
fi
git update-ref -d "refs/heads/-f"
git checkout -q -- file.txt

# --- 4c. the ORDER of the two guards in `sdd run`, which is a decision and not an accident.
#
# Deliberately NOT prefixed `branch `, for the reason cases 4 and 4b give: the checkpoint's Check
# counts the three cases the plan named.
#
# `cmd_retry` got this witness when it was written (case 5 of the `retry ` family below); `cmd_run`
# — the door nearly every invocation goes through — did not, and the gap was measured: swapping the
# two calls left check-gates.sh at 82 `ok`, rc 0, and the whole suite green. It survived because the
# base-branch pair for `sdd run` uses a fixture that declares NO branch, and a mission with no
# declared branch cannot tell the two orders apart.
#
# What the wrong order produces is a FALSE warning: the human is told the pipeline is about to
# commit into the base branch by a runner that is, in the very next line, moving them off it. A
# warning that cries wolf is how people learn to skip reading the true ones.
#
# Self-contained differential, both halves on the SAME command, the SAME fixture and the SAME
# warning text, so no fixture regime can satisfy it by accident: an empty `branch:` leaves the run
# standing on the base and the warning MUST appear exactly once; a declared branch moves it off and
# the warning MUST NOT appear at all. Asserting only the absence would be satisfied by a runner that
# never warns; asserting only the presence, by one that always does. The branch the run ENDS on is
# what proves the checkout really happened first, rather than not at all.
git checkout -q main
BASE_WARN='you are on the base branch'
branch_mission ""
BR_ORD_BASE_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_ORD_BASE_RC=$?
BR_ORD_BASE_AT="$(git branch --show-current)"
BR_ORD_BASE_N="$(grep -c "$BASE_WARN" <<< "$BR_ORD_BASE_OUT" || true)"
branch_mission "missao/20260103-order"
BR_ORD_OFF_OUT="$( cd "$FIX" && "$SDD" run "$BM" 2>&1 )"; BR_ORD_OFF_RC=$?
BR_ORD_OFF_AT="$(git branch --show-current)"
BR_ORD_OFF_N="$(grep -c "$BASE_WARN" <<< "$BR_ORD_OFF_OUT" || true)"
if [ "$BR_ORD_BASE_AT" = "main" ] \
   && [ "$BR_ORD_BASE_N" = "1" ] \
   && [ "$BR_ORD_OFF_AT" = "missao/20260103-order" ] \
   && [ "$BR_ORD_OFF_N" = "0" ] \
   && [ "$BR_ORD_BASE_RC" = "$BR_ORD_OFF_RC" ]; then
  pass "run order: the base-branch warning follows the checkout, and never precedes it"
else
  fail "run order: the base-branch warning follows the checkout, and never precedes it" \
       "warned once while it stays on main, silent once the declared branch takes it off, same rc" \
       "on main: $BR_ORD_BASE_AT warned $BR_ORD_BASE_N× (rc $BR_ORD_BASE_RC) · declared: $BR_ORD_OFF_AT warned $BR_ORD_OFF_N× (rc $BR_ORD_OFF_RC)"
fi
git checkout -q main
git branch -q -D missao/20260103-order

# --- 5. the SECOND call site: `sdd retry` honours the declared branch too.
#
# One definition, two doors that open a session which commits. Deleting the call in cmd_retry left
# all four assertions above green — the function still existed, still worked, and was simply never
# reached by the other door, which is precisely how a single definition drifts back into two
# behaviours. So the second site gets its own witness.
#
# Prefixed neither `branch ` nor `retry `: those two strings are the Checks of this increment and
# of the next one in checkpoint.md, and an assertion that quietly inflates a sibling's count turns
# a contract into a coincidence.
#
# The mission below stands at PLAN, and that is what makes a REAL `sdd retry` free: the runner
# refuses a headless PLAN and dies before `run_phase`, so the branch decision — which happens
# earlier still — is observable with no session spent. "PLAN is interactive" is asserted as the
# stopping point, so a future reordering that moved the checkout after the session would fail here
# instead of quietly spending tokens.
RM="20260104-retry-branch"
RMDIR="$FIX/docs/handoffs/$RM"
mkdir -p "$RMDIR"
cat > "$RMDIR/00-missao.md" <<'EOF'
---
missao: 20260104-retry-branch
aprovacao:
branch: missao/20260104-retry
---
# Mission fixture
EOF
BR_RETRY_OUT="$( cd "$FIX" && "$SDD" retry "$RM" 2>&1 )"; BR_RETRY_RC=$?
BR_RETRY_AT="$(git branch --show-current)"
if [ "$BR_RETRY_AT" = "missao/20260104-retry" ] \
   && [ "$BR_RETRY_RC" -eq 1 ] \
   && grep -q "PLAN is interactive" <<< "$BR_RETRY_OUT" \
   && ! grep -q "the test invoked the real claude" <<< "$BR_RETRY_OUT"; then
  pass "sdd retry is the other call site: it honours the declared branch before it stops at PLAN"
else
  fail "sdd retry is the other call site: it honours the declared branch before it stops at PLAN" \
       "on missao/20260104-retry, rc 1 at the interactive-PLAN refusal, no session spent" \
       "at $BR_RETRY_AT, rc $BR_RETRY_RC: $(tail -2 <<< "$BR_RETRY_OUT")"
fi
git checkout -q main
git branch -q -D missao/20260104-retry

# --- 6. the branch that does not carry the mission: the checkout is not the end of the decision.
#
# Every assertion above runs on a fixture whose mission files are UNTRACKED, and in that regime
# `git checkout` physically cannot remove them — so five assertions agreed about a property none of
# them could see. This one commits the artifacts first, which is what `sdd approve` now does to
# 00-missao.md, and then declares a branch cut BEFORE they existed. The house calls this the fixture
# regime instead of the property (CLAUDE.md): the family was green in the only regime where the
# question could not be asked.
#
# What the runner did with that: read the plan on branch A, switch to branch B, and go on with
# MISSION_DIR pointing at a path that is no longer there — announcing the switch as a success and
# then telling the human the mission was never planned. The expensive variant is worse and needs no
# new fixture to imagine: B carrying an OLDER copy of the plan spends real sessions executing a
# plan nobody approved.
#
# The probe is the DIE plus git's `--show-current`, and the marker of the run going on
# (`sdd-planner`, the PLAN advice) must be ABSENT: rc 1 alone cannot tell a stopped line from a
# line that stopped later for its own reasons.
OM="20260109-orphan"
OMDIR="$FIX/docs/handoffs/$OM"
git branch missao/20260109-orphan          # cut BEFORE the mission exists — the ticket-skill flow
mkdir -p "$OMDIR"
printf -- '---\nmissao: %s\naprovacao: humano-2026-01-09\nbranch: missao/20260109-orphan\n---\n# Mission fixture\n' \
  "$OM" > "$OMDIR/00-missao.md"
: > "$OMDIR/01-plano.md"
cp "$BMDIR/checkpoint.md" "$OMDIR/checkpoint.md"
( cd "$FIX" && git add -A && git commit -qm "fixture: a mission whose declared branch predates it" ) >/dev/null
BR_ORPH_OUT="$( cd "$FIX" && "$SDD" run "$OM" 2>&1 )"; BR_ORPH_RC=$?
BR_ORPH_AT="$(git branch --show-current)"
( cd "$FIX" && git checkout -q main )
if [ "$BR_ORPH_RC" -eq 1 ] \
   && grep -q "missao/20260109-orphan" <<< "$BR_ORPH_OUT" \
   && grep -q "does not carry" <<< "$BR_ORPH_OUT" \
   && ! grep -q "sdd-planner" <<< "$BR_ORPH_OUT" \
   && ! grep -q "BLOCKED in EXEC" <<< "$BR_ORPH_OUT"; then
  pass "a declared branch that does not carry the mission stops the line instead of running blind"
else
  fail "a declared branch that does not carry the mission stops the line instead of running blind" \
       "rc 1 naming the branch and saying it does not carry the mission, with no phase after it" \
       "rc $BR_ORPH_RC, ended at $BR_ORPH_AT: $(tail -3 <<< "$BR_ORPH_OUT")"
fi
git branch -q -D missao/20260109-orphan

# --- the fourth door: sdd retry warns about the base branch ----------------
echo "== sdd retry on the base branch =="
# `sdd retry` opens a session that COMMITS, exactly like the three doors that already warn
# (cmd_preflight, cmd_run, cmd_kaizen). It was the one that did not: a retry fired from `main`
# redid a phase and committed it straight into the base branch with nothing on screen saying so.
#
# DIFFERENTIAL, and for the same reason as the `sdd run` pair above: a single fixture standing on
# `main` cannot tell "warns on the base branch" from "always warns", and the second is a warning
# that means nothing. The SAME fixture is read twice, one checkout apart, and the two runs are
# compared to each other.
#
# The mission declares NO `branch:` key, which is what keeps this pair measuring the warning
# instead of the checkout: with a branch declared, ensure_mission_branch would move the retry off
# `main` before the warning could fire, and the two cases would stop being one checkout apart. The
# branch each run ENDS on is asserted on both sides, so a fixture that grew a `branch:` key would
# fail here rather than quietly turn both halves into the same case.
#
# It stands at PLAN, and that is what makes a REAL `sdd retry` free: the runner refuses a headless
# PLAN and dies before `run_phase`, so the warning — which happens earlier — is observable with no
# session spent. The claude stub turns a reordering that broke that into a loud failure.
RW="20260105-retry-warn"
RWDIR="$FIX/docs/handoffs/$RW"
mkdir -p "$RWDIR"
cat > "$RWDIR/00-missao.md" <<'EOF'
---
missao: 20260105-retry-warn
aprovacao:
---
# Mission fixture
EOF
# Captured APART and only then joined, like the `sdd run` pair: a `2>&1` capture cannot tell `warn`
# (stderr) from `dim` (stdout), and a warning nobody sees on the error stream is decoration again.
RW_BASE_ERR="$SDD_STATE_FIX/retry-warn-main.err"
RW_FEAT_ERR="$SDD_STATE_FIX/retry-warn-feature.err"
RW_BASE_RAW="$( cd "$FIX" && "$SDD" retry "$RW" 2>"$RW_BASE_ERR" )"; RW_BASE_RC=$?
RW_BASE_AT="$(git branch --show-current)"
git checkout -q -b missao/20260105-retry-warn
RW_FEAT_RAW="$( cd "$FIX" && "$SDD" retry "$RW" 2>"$RW_FEAT_ERR" )"; RW_FEAT_RC=$?
RW_FEAT_AT="$(git branch --show-current)"
git checkout -q main
git branch -q -D missao/20260105-retry-warn
RW_BASE_OUT="$(no_uuid <<< "$RW_BASE_RAW"$'\n'"$(cat "$RW_BASE_ERR")")"
RW_FEAT_OUT="$(no_uuid <<< "$RW_FEAT_RAW"$'\n'"$(cat "$RW_FEAT_ERR")")"

# Reads the ERROR stream: presence and severity in one assertion, so the only way to satisfy it is
# the `warn` the runner is supposed to print. The rc and the PLAN refusal ride along because the
# expensive regression here is not a missing line, it is the guard turning into a `die` — that
# would lock a human out of retrying the moment they forgot to branch.
#
# EXACTLY one, never "at least one". The adversarial pass duplicated the call inside cmd_retry and
# a presence check stayed green: the differential half below strips every copy of the line before
# comparing, so a runner shouting the same warning twice satisfied both halves. A warning that
# repeats is how people learn to skip reading them, which is the failure this door exists to avoid.
RW_BASE_WARN="$(grep -c 'you are on the base branch' <<< "$RW_BASE_OUT")"
if grep -q 'you are on the base branch' "$RW_BASE_ERR" \
   && [ "$RW_BASE_WARN" -eq 1 ] \
   && [ "$RW_BASE_RC" -eq 1 ] \
   && [ "$RW_BASE_AT" = "main" ] \
   && grep -q "PLAN is interactive" <<< "$RW_BASE_OUT" \
   && ! grep -q "the test invoked the real claude" <<< "$RW_BASE_OUT"; then
  pass "retry warns on the base branch too — on stderr, and still a warn and not a die"
else
  fail "retry warns on the base branch too — on stderr, and still a warn and not a die" \
       "the warning on STDERR, rc 1 at the interactive-PLAN refusal, still on main" \
       "rc $RW_BASE_RC at $RW_BASE_AT, warned $RW_BASE_WARN× · stderr: $(tr '\n' '|' < "$RW_BASE_ERR" | head -c 200)"
fi

# The other half. The byte comparison is what separates "the warning was added" from "the warning
# changed the retry": strip the warned line from the base-branch output and the two runs have to be
# the same text, at the same rc. A retry that started behaving differently on one of the two
# branches — an early return, a phase resolved elsewhere — passes the assertion above and dies here.
RW_FEAT_WARN="$(grep -c 'you are on the base branch' <<< "$RW_FEAT_OUT")"
if [ "$RW_FEAT_WARN" -eq 0 ] \
   && [ "$RW_FEAT_AT" = "missao/20260105-retry-warn" ] \
   && [ "$RW_BASE_RC" = "$RW_FEAT_RC" ] \
   && [ "$(grep -v 'you are on the base branch' <<< "$RW_BASE_OUT")" = "$RW_FEAT_OUT" ]; then
  pass "retry is silent off it, and the warning is the ONLY difference between the two retries"
else
  fail "retry is silent off it, and the warning is the ONLY difference between the two retries" \
       "no warning on missao/20260105-retry-warn, same rc, identical output once the line is removed" \
       "at $RW_FEAT_AT (rc $RW_FEAT_RC, base rc $RW_BASE_RC), warned $RW_FEAT_WARN×: $(diff <(grep -v 'you are on the base branch' <<< "$RW_BASE_OUT") <(printf '%s\n' "$RW_FEAT_OUT") | head -5)"
fi

# --- and the ORDER of the two guards, which is a decision and not an accident.
#
# Deliberately NOT prefixed `retry `: that string is this increment's Check in checkpoint.md, and
# an assertion that inflates it turns a contract into a coincidence. This is the third case, born
# of the adversarial pass — moving the call ABOVE ensure_mission_branch left the pair above green,
# because a mission that declares no branch cannot tell the two orders apart.
#
# What the wrong order produces is a FALSE warning: the human is told the pipeline is about to
# commit into the base branch by a runner that is, in the very next line, moving them off it. A
# warning that cries wolf is how people learn to skip reading them — the same reason the guard
# stays silent on a detached HEAD.
#
# The absence is only meaningful because the presence half exists above, on the same command and
# the same warning text: on its own, "no warning here" is satisfied by a runner that never warns at
# all. The branch the retry ENDS on is what says the checkout really happened first.
RWO="20260105-retry-order"
RWODIR="$FIX/docs/handoffs/$RWO"
mkdir -p "$RWODIR"
cat > "$RWODIR/00-missao.md" <<'EOF'
---
missao: 20260105-retry-order
aprovacao:
branch: missao/20260105-retry-order
---
# Mission fixture
EOF
RWO_OUT="$( cd "$FIX" && "$SDD" retry "$RWO" 2>&1 )"; RWO_RC=$?
RWO_AT="$(git branch --show-current)"
if [ "$RWO_AT" = "missao/20260105-retry-order" ] \
   && [ "$RWO_RC" -eq 1 ] \
   && grep -q "PLAN is interactive" <<< "$RWO_OUT" \
   && ! grep -q 'you are on the base branch' <<< "$RWO_OUT"; then
  pass "and the warning follows the checkout: a retry being moved off the base branch is not warned"
else
  fail "and the warning follows the checkout: a retry being moved off the base branch is not warned" \
       "on missao/20260105-retry-order, rc 1 at the PLAN refusal, and no base-branch warning" \
       "at $RWO_AT, rc $RWO_RC: $(tail -3 <<< "$RWO_OUT")"
fi
git checkout -q main
git branch -q -D missao/20260105-retry-order

# --- a kaizen-born plan never approves itself ------------------------------
echo "== kaizen-born plans =="
# `aprovacao: auto` means one thing and one thing only: the PLAN-AUTO table was all ✅ *with the
# human in the room*, which is the premise sdd-planner writes it under. A plan born of `sdd kaizen`
# had no human in the room — the kit planned its own next change — so `auto` there is a machine
# certifying its own homework. agents/sdd-kaizen.md already orders the born plan to ship with
# `aprovacao:` EMPTY, and gate_KAIZEN refuses to hand one over with the field filled; but nothing
# stopped the born plan from filling it in later, and gate_PLAN — the gate `sdd run` actually asks
# — read `auto` without ever looking at where the plan came from. Prose on one side, a gate blind
# to it on the other: the kit could approve itself and run.
#
# The marker is `05-verdict.md` sitting in the mission directory, and it is not a convention
# invented here: gate_KAIZEN finds the verdict and takes `dirname` as the born plan's home
# (bin/sdd:2441), so the two files are siblings by construction. Provenance of the frontmatter
# below: docs/handoffs/20260816-kit-como-alvo/05-verdict.md, the verdict the kit's own second
# kaizen lap wrote — read from there, not remembered. It is spelled out instead of `cp`ed because
# the gate reads the file's NAME and nothing inside it, and a copy would make this sensor depend on
# one mission directory surviving in the repo forever.
#
# THREE cases on ONE fixture, and the shape is what makes them differential. Only one thing changes
# between case 1 and case 2 (the verdict file appears) and only one between 2 and 3 (the approval
# becomes a human's), so no assertion can be satisfied by a fixture that happens to sit in the
# right regime: whichever half a regression breaks, the other half is standing right next to it.
#
# Neither slug below contains the words the assertions grep for, and that is not tidiness. The
# refusal names the mission (`run 'sdd approve <mission>'`), so a fixture called `…-kaizen-born`
# put the probe's own needle into the runner's output: degrading the message to drop "kaizen-born"
# left the assertion green, because the mission NAME was still carrying it. The probe must only be
# satisfiable by the gate's own words.
KM="20260106-selfapproved"
KMDIR="$FIX/docs/handoffs/$KM"
mkdir -p "$KMDIR"
cat > "$KMDIR/00-missao.md" <<'EOF'
---
missao: 20260106-selfapproved
aprovacao: auto
---
# Mission fixture
EOF
: > "$KMDIR/01-plano.md"
cat > "$KMDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | one slice | `true` → 0 | pending | — |
EOF
# A SIBLING mission, planner-written and approved `auto`, that never gets a verdict of its own. It
# is read in case 2 — after the verdict below exists — and it is what pins the marker to THE
# MISSION instead of to the repo. The adversarial pass built the version that asks
# `ls $HANDOFF_DIR/*/05-verdict.md`, which reads identically on the case-1 fixture and then refuses
# every `auto` plan in any repo that has ever run `sdd kaizen` — the kit's own, for one. It
# survived every other assertion here.
KS="20260106-planner-written"
KSDIR="$FIX/docs/handoffs/$KS"
mkdir -p "$KSDIR"
printf -- '---\nmissao: %s\naprovacao: auto\n---\n# Mission fixture\n' "$KS" > "$KSDIR/00-missao.md"
: > "$KSDIR/01-plano.md"
cp "$KMDIR/checkpoint.md" "$KSDIR/checkpoint.md"

# --- 1. the control: the very same `auto`, with no verdict beside it, runs.
#
# It goes FIRST and on the fixture the refusal will use, because it is the only thing that says the
# new branch discriminates instead of just refusing. A gate that turned every `auto` away would
# satisfy every assertion about the refusal below and die here — and it would brick the ordinary
# planner-written mission, which is most of them.
KB_OK_PHASE="$( cd "$FIX" && "$SDD" phase "$KM" 2>&1 )"
KB_OK_WHY="$( cd "$FIX" && "$SDD" why "$KM" PLAN 2>&1 )"
if [ "$KB_OK_PHASE" = "EXEC" ] \
   && grep -q 'plan approved' <<< "$KB_OK_WHY" \
   && ! grep -q 'kaizen-born' <<< "$KB_OK_WHY"; then
  pass "kaizen-born: 'auto' with no verdict beside it is an ordinary approved plan and still runs"
else
  fail "kaizen-born: 'auto' with no verdict beside it is an ordinary approved plan and still runs" \
       "phase EXEC and a PLAN reason that approves without mentioning kaizen-born" \
       "phase $KB_OK_PHASE, why: $KB_OK_WHY"
fi

# --- 2. the verdict appears: the same file, the same `auto`, and now the gate shuts.
#
# The reason is read, not just the rc: `auto` is on gate_PLAN's happy path, so a refusal that came
# out of some OTHER branch (a missing artifact, an unparseable checkpoint) would leave the phase at
# PLAN exactly the same way and this assertion could not tell which one ran. Hence the pair — the
# new branch's own words present AND the happy path's marker absent.
#
# `sdd approve <mission>` is demanded inside the reason on purpose. A gate that shuts without
# naming the way out sends the human back to hand-editing frontmatter, which is the failure the
# approve command was built to end: the refusal has to carry its own remedy or it is just a wall.
cat > "$KMDIR/05-verdict.md" <<'EOF'
---
verdict: indeterminado
kit_sha_judged: dd80cb9
date: 2026-01-06
---
# Verdict fixture
EOF
#
# The sibling is read in the same breath, and only now that a verdict exists somewhere in the tree:
# it is the witness that the marker is the mission's own file and not "this repo does kaizen".
KB_NO_PHASE="$( cd "$FIX" && "$SDD" phase "$KM" 2>&1 )"
KB_NO_WHY="$( cd "$FIX" && "$SDD" why "$KM" PLAN 2>&1 )"
KB_SIB_PHASE="$( cd "$FIX" && "$SDD" phase "$KS" 2>&1 )"
if [ "$KB_NO_PHASE" = "PLAN" ] \
   && grep -q 'kaizen-born' <<< "$KB_NO_WHY" \
   && grep -q "sdd approve $KM" <<< "$KB_NO_WHY" \
   && ! grep -q 'plan approved' <<< "$KB_NO_WHY" \
   && [ "$KB_SIB_PHASE" = "EXEC" ]; then
  pass "kaizen-born: the verdict beside it turns 'auto' into a refusal that names sdd approve"
else
  fail "kaizen-born: the verdict beside it turns 'auto' into a refusal that names sdd approve" \
       "phase PLAN and a reason citing kaizen-born and 'sdd approve $KM', never 'plan approved' — and the sibling mission still at EXEC" \
       "phase $KB_NO_PHASE, sibling $KB_SIB_PHASE, why: $KB_NO_WHY"
fi

# --- 3. and the way out really is a way out: the human's own approval passes, verdict and all.
#
# Without this the branch could be `[ -f 05-verdict.md ]` alone and everything above would still be
# green — a kaizen-born mission would then be unrunnable FOREVER, `sdd approve` included, and the
# kit's own improvement loop would have no terminating state at all. What is refused is a machine
# certifying itself, never the presence of a verdict.
#
# The value is written the way cmd_approve writes it (`humano-<date>`) and not some other legal
# string, so this case also pins the two halves of the mission together: the gate has to accept
# exactly what the command produces.
sed -i 's/^aprovacao: auto/aprovacao: humano-2026-01-06/' "$KMDIR/00-missao.md"
KB_HUMAN_PHASE="$( cd "$FIX" && "$SDD" phase "$KM" 2>&1 )"
KB_HUMAN_WHY="$( cd "$FIX" && "$SDD" why "$KM" PLAN 2>&1 )"
if [ "$KB_HUMAN_PHASE" = "EXEC" ] \
   && grep -q 'plan approved (humano-2026-01-06)' <<< "$KB_HUMAN_WHY" \
   && ! grep -q 'kaizen-born' <<< "$KB_HUMAN_WHY"; then
  pass "kaizen-born: the human's own approval opens the gate with the verdict still sitting there"
else
  fail "kaizen-born: the human's own approval opens the gate with the verdict still sitting there" \
       "phase EXEC and a PLAN reason approving 'humano-2026-01-06' without mentioning kaizen-born" \
       "phase $KB_HUMAN_PHASE, why: $KB_HUMAN_WHY"
fi

# --- the remedy the refusal names has to work ------------------------------
echo "== the remedy the kaizen-born refusal names =="
# gate_PLAN refuses a kaizen-born `auto` and names ONE way out: `run 'sdd approve <mission>'`.
# cmd_approve reads `auto` as "already approved — nothing to do" and returns 0 without writing.
# The two sets are not merely overlapping, they are nested: the gate refuses only when the value is
# `auto`, and `auto` is exactly what makes approve bail. Every plan the gate stops is a plan the
# named remedy declines to fix, so the instruction never works — not sometimes, never. What is left
# is hand-typing `humano-YYYY-MM-DD` into the frontmatter, which is the failure `sdd approve` was
# built to end and which the refusal's own comment says it exists to avoid.
#
# The assertion above this one already reaches the approved state — with `sed -i`. That is why the
# seam went unmeasured: simulating the remedy proves the GATE accepts what the command would write,
# never that the COMMAND gets there. This one invokes the remedy the runner prints.
#
# Found by sdd-qa walking the journey in mission 20260816-portas-do-humano: `sdd why`, `sdd status`
# and `sdd run` each print the instruction, and all three loop forever.
QM="20260107-named-remedy"
QMDIR="$FIX/docs/handoffs/$QM"
mkdir -p "$QMDIR"
# The slug carries neither "already" nor the words the probe looks for below: a fixture whose name
# satisfies the probe hands the runner the needle (the I4 notes paid for that lesson once).
cat > "$QMDIR/00-missao.md" <<'EOF'
---
missao: 20260107-named-remedy
titulo: fixture — a machine-approved plan with a verdict beside it
aprovacao: auto
---
# Mission
EOF
: > "$QMDIR/01-plano.md"
cat > "$QMDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | fatia de fixture | `true` → `0` | pending | — |
EOF
printf -- '---\nmissao: %s\n---\n# Verdict\n' "$QM" > "$QMDIR/05-verdict.md"
( cd "$FIX" && git add -A && git commit -qm "fixture: a kaizen-born plan carrying auto" ) >/dev/null

# The SIBLING that keeps the fix honest: `auto` with no verdict beside it is an ordinary
# planner-written plan, already approved, and `sdd approve` must go on declining it. Without this
# half the cheapest way to satisfy the assertion above is to drop `auto` from the bail case
# altogether — which would rewrite every legitimate `auto` into `humano-<today>` on contact,
# erasing the PLAN-AUTO provenance the value carries. What is being demanded is that approve act on
# the kaizen-born condition, not that it stop recognising approval.
QN="20260107-planner-auto"
QNDIR="$FIX/docs/handoffs/$QN"
mkdir -p "$QNDIR"
sed -e "s/$QM/$QN/" -e 's/^titulo:.*/titulo: fixture — an ordinary plan the planner approved/' \
    "$QMDIR/00-missao.md" > "$QNDIR/00-missao.md"
: > "$QNDIR/01-plano.md"
cp "$QMDIR/checkpoint.md" "$QNDIR/checkpoint.md"
( cd "$FIX" && git add -A && git commit -qm "fixture: a planner-written plan approved auto" ) >/dev/null

QM_WHY="$( cd "$FIX" && "$SDD" why "$QM" PLAN 2>&1 )"
QM_DAY_0="$(date +%F)"
QM_OUT="$( cd "$FIX" && "$SDD" approve "$QM" 2>&1 <<< "y" )"; QM_RC=$?
QM_DAY_1="$(date +%F)"
QM_LINE="$(grep -m1 '^aprovacao:' "$QMDIR/00-missao.md")"
QM_PHASE="$( cd "$FIX" && "$SDD" phase "$QM" 2>&1 )"
QN_HEAD_0="$( cd "$FIX" && git rev-parse HEAD )"
QN_OUT="$( cd "$FIX" && "$SDD" approve "$QN" 2>&1 <<< "y" )"
QN_LINE="$(grep -m1 '^aprovacao:' "$QNDIR/00-missao.md")"
QN_HEAD_1="$( cd "$FIX" && git rev-parse HEAD )"
# The refusal is asserted FIRST: without it a runner that simply stopped refusing kaizen-born plans
# would satisfy every clause below, and this assertion would quietly become a test of nothing.
# `already approved` is demanded ABSENT on one side and PRESENT on the other for the same reason the
# `auto` check exists above — the bail path and the write path both return 0, so rc alone cannot
# tell them apart.
# The announcement clause was added by sdd-executor closing F1, after a sabotage pass found it was
# the one degradation that survived: stripping the warning left `sdd approve` silently replacing a
# committed `aprovacao: auto` with `humano-<today>`, and every clause below stayed green. Overwriting
# a value the artifact carries is exactly what this command was built NOT to do quietly — the human
# is told which of the two `auto`s this is before being asked. Demanded present on the kaizen-born
# side and ABSENT on the verdict-less one, so a runner that simply warns at every approve fails too.
if grep -q 'kaizen-born' <<< "$QM_WHY" \
   && [ "$QM_RC" -eq 0 ] \
   && { [ "$QM_LINE" = "aprovacao: humano-$QM_DAY_0" ] \
        || [ "$QM_LINE" = "aprovacao: humano-$QM_DAY_1" ]; } \
   && ! grep -q 'already approved' <<< "$QM_OUT" \
   && grep -q 'born of sdd kaizen' <<< "$QM_OUT" \
   && [ "$QM_PHASE" != "PLAN" ] \
   && [ "$QN_LINE" = "aprovacao: auto" ] \
   && grep -q 'already approved' <<< "$QN_OUT" \
   && grep -q 'you are on the base branch' <<< "$QM_OUT" \
   && ! grep -q 'you are on the base branch' <<< "$QN_OUT" \
   && ! grep -q 'born of sdd kaizen' <<< "$QN_OUT" \
   && [ "$QN_HEAD_1" = "$QN_HEAD_0" ]; then
  pass "approve resolves the refusal that names it, and still declines an 'auto' with no verdict"
else
  fail "approve resolves the refusal that names it, and still declines an 'auto' with no verdict" \
       "PLAN refused for kaizen-born, then the born plan announced and 'aprovacao: humano-$QM_DAY_0' written and the phase off PLAN — while the verdict-less sibling stays 'aprovacao: auto', unannounced and uncommitted" \
       "why: $QM_WHY | rc $QM_RC, phase $QM_PHASE, line '$QM_LINE', out: $(tail -2 <<< "$QM_OUT") | sibling line '$QN_LINE', sibling out: $(tail -1 <<< "$QN_OUT")"
fi

# --- approve is a door that commits, so it says which branch it is on ------
echo "== approve on the base branch =="
# warn_if_on_base_branch has ONE definition and its comment enumerates "the four doors that can end
# up committing": preflight, run, retry, kaizen. `sdd approve` commits — it is the fifth, written in
# the same mission that closed the silence for the fourth, and it is the only one that does not
# warn. Approving while standing on `main` drops a `chore(missao)` commit straight into the base
# branch without a word, which is the class this mission exists to end.
#
# A warning and never a `die`: the plan legitimately lives on the base branch before the mission
# branch is cut (ensure_mission_branch cuts it FROM there), so refusing would break the ordinary
# flow. The pair is what keeps it honest — a guard that always fires teaches people to skip reading
# it, and is indistinguishable from a banner.
#
# `n` on both calls: the warning fires before the question, so the pair measures the warning alone
# and leaves the fixture's history untouched.
QW="20260108-door-that-commits"
QWDIR="$FIX/docs/handoffs/$QW"
mkdir -p "$QWDIR"
cat > "$QWDIR/00-missao.md" <<'EOF'
---
missao: 20260108-door-that-commits
titulo: fixture — approving from the base branch
aprovacao:
branch:
---
# Mission
EOF
: > "$QWDIR/01-plano.md"
cat > "$QWDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | fatia de fixture | `true` → `0` | pending | — |
EOF
( cd "$FIX" && git add -A && git commit -qm "fixture: a plan waiting for approval" ) >/dev/null

( cd "$FIX" && git checkout -q main )
QW_ON_BASE="$( cd "$FIX" && "$SDD" approve "$QW" 2>&1 <<< "n" )"
( cd "$FIX" && git checkout -q -b off-base-for-approve )
QW_OFF_BASE="$( cd "$FIX" && "$SDD" approve "$QW" 2>&1 <<< "n" )"
QW_BRANCH="$( cd "$FIX" && git branch --show-current )"
# A third invocation, back on the base branch, with the increment table made unparseable. The
# branch is the ONLY thing this guard may depend on, and the pair above cannot say so: a sabotage
# pass moved the call inside the `if [ -n "$rows" ]` arm and every clause stayed green, because the
# fixture happened to satisfy the unrelated condition. That is how a guard ends up firing for the
# missions that need it least — and a half-written checkpoint is exactly the mission most likely to
# be approved in a hurry, from wherever the human is standing.
( cd "$FIX" && git checkout -q main )
printf 'this file carries no parseable increment row\n' > "$QWDIR/checkpoint.md"
QW_NOROWS="$( cd "$FIX" && "$SDD" approve "$QW" 2>&1 <<< "n" )"
QW_NOROWS_N="$(grep -c 'you are on the base branch' <<< "$QW_NOROWS")"
( cd "$FIX" && git checkout -q -- "docs/handoffs/$QW/checkpoint.md" )
# WHERE in the output, not merely whether: the clause below was added by sdd-executor closing F2,
# after a sabotage pass found it was the one degradation the pair alone could not see. Moving the
# call to just after `read -r ans` keeps both greps green and tells the human which branch they
# were standing on AFTER they already answered — a guard that arrives late is not a guard, it is a
# receipt, and the SQ-97 class this mission exists to end is precisely being told after the fact.
# The prompt carries no trailing newline, so a warning printed after it lands ON the prompt line
# and the comparison is strict: equal line numbers are the late warning, not an early one.
#
# awk with `exit` rather than `grep -n | head -1`: one process, no pipe, so nothing here can return
# 141 under `pipefail` when the match is found before the writer finishes (a house lesson, in
# CLAUDE.md). Both numbers are demanded non-empty — a missing warning would otherwise arrive as an
# empty string and compare its way to a pass.
#
# Counted, not just present, for the reason the `retry ` pair states: with "at least one" a guard
# that fires early AND again after the answer passes, and the late copy is the crying wolf the
# definition's own comment says it must never become. Exactly one on the base branch, exactly none
# off it.
QW_WARN_N="$(grep -c 'you are on the base branch' <<< "$QW_ON_BASE")"
QW_WARN_OFF_N="$(grep -c 'you are on the base branch' <<< "$QW_OFF_BASE")"
QW_WARN_AT="$(awk '/you are on the base branch/ { print NR; exit }' <<< "$QW_ON_BASE")"
QW_ASK_AT="$(awk '/approve this plan/ { print NR; exit }' <<< "$QW_ON_BASE")"
if [ "$QW_WARN_N" -eq 1 ] \
   && [ "$QW_WARN_OFF_N" -eq 0 ] \
   && [ "$QW_NOROWS_N" -eq 1 ] \
   && [ -n "$QW_WARN_AT" ] && [ -n "$QW_ASK_AT" ] && [ "$QW_WARN_AT" -lt "$QW_ASK_AT" ]; then
  pass "approve warns about the base branch it is about to commit into, and is silent off it"
else
  fail "approve warns about the base branch it is about to commit into, and is silent off it" \
       "exactly one warning on main and BEFORE the [y/N] question, none on $QW_BRANCH, one again with an unparseable checkpoint" \
       "on main: $QW_WARN_N warning(s), at line ${QW_WARN_AT:-<none>}, question at line ${QW_ASK_AT:-<none>}, $(tail -2 <<< "$QW_ON_BASE") | off base: $QW_WARN_OFF_N warning(s), $(tail -2 <<< "$QW_OFF_BASE") | no rows: $QW_NOROWS_N warning(s), $(tail -1 <<< "$QW_NOROWS")"
fi

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "state machine correct"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
