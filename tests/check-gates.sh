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

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
  if printf '%s' "$got" | grep -qE "$re"; then pass "$desc"
  else fail "$desc" "reason matching /$re/" "$got"; fi
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

sed -i 's/^aprovacao:.*/aprovacao: auto/' "$MDIR/00-missao.md"
assert_phase "plan approved (auto) with a pending increment" "EXEC"

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
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.jidoka.bak"
sed -i "s/| done | $REAL_HASH |/| blocked | — |/" "$MDIR/checkpoint.md"
rm -f "$MDIR/20-handoff-exec.md"
run_out="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; run_rc=$?
if [ "$run_rc" -eq 3 ] && printf '%s' "$run_out" | grep -q "BLOCKED in EXEC"; then
  pass "a 'blocked' increment escalates on the spot (exit 3, no session spent)"
else
  fail "a 'blocked' increment must escalate on the spot" "exit 3 + 'BLOCKED in EXEC'" "exit $run_rc: $(printf '%s' "$run_out" | tail -3)"
fi
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

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "state machine correct"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
