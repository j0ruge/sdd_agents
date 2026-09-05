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

# assert_eq <description> <expected> <got>. For the blocks that compose several terms into one
# string — "this arm fired AND the other did not AND the artifact was written" — so a red names the
# term that went wrong instead of only that something did.
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi }

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

# With JIRA on, the branch is BORN in the TICKET phase (the `ticket` skill creates it) and used to
# stay in 10-ticket.md alone. `ensure_mission_branch` reads only 00-missao.md, so every later phase
# ran on whatever branch the human happened to be standing on, guarding a name that was never
# there — the SQ-97 shape, where five phases committed into another PR's branch.
#
# The write-back is the TICKET SESSION's job, never the gate's: a gate that wrote would break
# `moved2`, the fingerprint that answers "did the session move the disk". So the gate takes the
# half it can verify — if 10-ticket.md declares a branch, 00-missao.md must declare the same one,
# and not the placeholder.
#
# Three worlds, and the middle one is what the assertion is named after.
printf -- '---\nfase: TICKET\nstatus: done\nissue: FX-1\nsprint: Sprint 1\nbranch: feature/FX-1\n---\n' \
  > "$MDIR/10-ticket.md"
sed -i 's|^versao: 0.1.0|versao: 0.1.0\nbranch: <nome da branch de trabalho>|' "$MDIR/00-missao.md"
assert_phase "TICKET refuses a branch that never reached 00-missao.md" "TICKET"
assert_why   "TICKET names the artifact the branch has to reach" "TICKET" "00-missao"

# A DIFFERENT branch is the same defect wearing a filled-in field: 00-missao.md declares a name,
# `ensure_mission_branch` honours it, and the mission runs somewhere the ticket never created.
sed -i 's|^branch: <nome da branch de trabalho>|branch: feature/OTHER|' "$MDIR/00-missao.md"
assert_phase "TICKET refuses a 00-missao.md declaring another branch" "TICKET"

# And the other side: written back, the phase passes. Without it the two assertions above are
# satisfied by a gate that refuses every TICKET whatever is on disk.
sed -i 's|^branch: feature/OTHER|branch: feature/FX-1|' "$MDIR/00-missao.md"
assert_phase "the branch written back to 00-missao.md passes" "EXEC"

# back to the no-JIRA state for the rest of the test. The `branch:` line goes too: left behind, the
# `sdd run` invocations further down would check a branch out inside the fixture.
sed -i 's/^JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh
sed -i '/^branch: feature\/FX-1$/d' "$MDIR/00-missao.md"
rm -f .jira-project "$MDIR/10-ticket.md"
if grep -q '^branch:' "$MDIR/00-missao.md"; then
  fail "the TICKET block leaves no branch behind" "no branch: line in 00-missao.md" \
       "$(grep -m1 '^branch:' "$MDIR/00-missao.md")"
else
  pass "the TICKET block leaves no branch behind in the fixture"
fi

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

# --- the TL;DR cap, port 1 of 3 -----------------------------------------------
# Since 20260904-a-dieta-de-contexto the boot inlines `## TL;DR` verbatim into every session of the
# NEXT phase, so a TL;DR that grows is a cost multiplied by every turn of that phase. The cap is
# enforced by the gate of the phase that WRITES the file — the agent that fails it is the agent
# allowed to fix it, which is what keeps this from spinning the line instead of stopping it.
#
# Both sides, and neither alone is the assertion: "21 fails" alone passes on a gate that refuses
# every TL;DR there is, and "20 passes" alone passes on a gate that counts nothing at all.
{ printf -- '---\nfase: EXEC\nstatus: done\n---\n## TL;DR\n'; awk 'BEGIN{for(i=1;i<=21;i++) print "l" i}'; } > "$MDIR/20-handoff-exec.md"
git add -A && git commit -qm "chore: a TL;DR over the cap"
assert_phase "a TL;DR over the cap fails the EXEC gate" "EXEC"
assert_why   "EXEC names the count and the cap" "EXEC" "TL;DR is 21 lines"
{ printf -- '---\nfase: EXEC\nstatus: done\n---\n## TL;DR\n'; awk 'BEGIN{for(i=1;i<=20;i++) print "l" i}'; } > "$MDIR/20-handoff-exec.md"
git add -A && git commit -qm "chore: a TL;DR exactly at the cap"
assert_phase "and exactly at the cap it passes" "QA"

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

# The OTHER Jidoka of the same phase, and the one that costs money when it is missing. A phase that
# dies mid-way leaves the tree uncommitted; the suite runs against changes nobody approved and comes
# back red; every increment still reads `done`, so EXEC is re-derived and another session opens
# against the same wall. `state_fingerprint` reads HEAD, the mission listing and the checkpoint's
# md5 — never the working tree — so `attempts` starts at zero on every `sdd run`. Measured at about
# US$ 25 a lap, with no end condition.
#
# DIFFERENTIAL, one `echo` apart: the same red suite on a clean tree is the ORDINARY case and must
# still open a session. Without that half, a runner that escalated on every red suite would satisfy
# the dirty half — and would end the line on the most common situation there is.
git add -A && git commit -qm "chore: handoff back"
sed -i 's|^TEST_CMD="true"|TEST_CMD="false"|' .sdd/config.sh
git add -A && git commit -qm "chore: red suite, clean tree"
if [ -z "$( cd "$FIX" && git status --porcelain )" ]; then
  pass "fixture: the tree really is clean before the differential"
else
  fail "dirty-tree fixture" "a clean tree" "$( cd "$FIX" && git status --porcelain )"
fi
# "A session was spent" is counted in the ARTEFACT the runner leaves behind: one line per
# `run_phase` in the mission journal. NOT by grepping the stub's marker out of `sdd run`'s output —
# run_phase redirects the session's stdout AND stderr into its log file, so the marker never
# reaches the terminal and an assertion reading for it there is green whether a session ran or not.
# (The neighbouring assert_jidoka has that shape; recorded in TODO.md.)
#
# And not by counting `EXEC-*.json` files either. That was once a correctness argument — the name
# was `<PHASE>-%Y%m%d-%H%M%S.json`, so two sessions inside one SECOND landed on one path and the
# second destroyed the first (BUG-20260821-session-log-overwritten-in-the-same-second, now fixed:
# the name carries the session id, and check-autonomy.sh holds that property under a frozen clock).
# It stays an argument about the INSTRUMENT: the journal is append-only and is what the kaizen
# judge reads, so counting it measures the record rather than a directory listing beside it.
phase_sessions_spent() { # phase_sessions_spent <PHASE>
  grep -c "  $1  agent=" "$FIX/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true
}
sessions_spent() { phase_sessions_spent EXEC; }
n_before="$(sessions_spent)"
out_clean="$( cd "$FIX" && "$SDD" run "$MISSION" --max-phases 1 2>&1 )"; rc_clean=$?
n_clean="$(sessions_spent)"
if [ "$n_clean" -gt "$n_before" ]; then
  pass "a red suite over a CLEAN tree still opens a session (the ordinary case)"
else
  fail "red suite, clean tree" "a new EXEC session log" \
       "exit $rc_clean, $n_before → $n_clean log(s): $(tail -3 <<< "$out_clean")"
fi

echo "work nobody committed" >> file.txt
out_dirty="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; rc_dirty=$?
n_dirty="$(sessions_spent)"
if [ "$rc_dirty" -eq 3 ] \
   && grep -q "DIRTY working tree" <<< "$out_dirty" \
   && [ "$n_dirty" -eq "$n_clean" ]; then
  pass "a dirty tree with every increment done escalates (exit 3, no session spent)"
else
  fail "a dirty tree with every increment done escalates (exit 3, no session spent)" \
       "exit 3, the dirty-tree branch, and no new session log" \
       "exit $rc_dirty, $n_clean → $n_dirty log(s): $(tail -3 <<< "$out_dirty")"
fi
# The escalation has to be the DIRTY one and not the budget one, which shares rc 3 and the
# "BLOCKED in EXEC" prefix — the discriminator the neighbouring assert_jidoka already insists on.
if grep -q "session(s) without satisfying the gate" <<< "$out_dirty"; then
  fail "the escalation is the dirty-tree branch, not budget exhaustion" \
       "no budget-exhaustion text" "$(grep -m1 'session(s) without' <<< "$out_dirty")"
else
  pass "the escalation is the dirty-tree branch, not budget exhaustion"
fi
git checkout -- file.txt
sed -i 's|^TEST_CMD="false"|TEST_CMD="true"|' .sdd/config.sh
git add -A && git commit -qm "chore: green again"

# An invalid checkpoint status fails loudly, not in silence.
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.bak"
sed -i "s/| done | $REAL_HASH |/| completed | $REAL_HASH |/" "$MDIR/checkpoint.md"
assert_phase "a status outside the enum fails" "EXEC"
assert_why   "EXEC reports the invalid status" "EXEC" "invalid status"
mv "$MDIR/checkpoint.bak" "$MDIR/checkpoint.md"

# A literal pipe inside a Check cell is spelled `\|` in GFM, and a raw split on "|" cuts the row
# there — every column after it shifts one to the left, so the Status column is read out of the
# CHECK cell. The increment is `done` and the gate answers "invalid status", naming a status the
# author never wrote. gate_REVIEW learned this the expensive way (its comment carries the measured
# row); the checkpoint parser had not.
#
# The answer is taken BEFORE the escape is introduced and compared to the answer after it: a
# differential, not a literal. No fixture regime satisfies both sides by accident, and whichever
# side a regression breaks, the other is standing right next to it.
plain_answer="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.pipe.bak"
# `@` as the delimiter, never `|`: with `s|…|…|` the `|` of the replacement CLOSES the expression
# and the escape never reaches the file. `\\` is what spells one literal backslash in a sed
# replacement, so the cell ends up carrying `\|` — the GFM escape, which is the point.
sed -i 's@`true` → 0@`printf a\\|b` → 0@' "$MDIR/checkpoint.md"
# The probe dies loud if it sabotaged nothing: an assertion about an escaped pipe on a fixture that
# has none would be green forever, pointing at the right thing by accident. `-F`, because in a BRE
# `\|` is alternation and `grep 'a\|b'` would match the untouched row too.
if grep -qF '`printf a\|b` → 0' "$MDIR/checkpoint.md"; then
  pass "fixture: the Check cell really carries an escaped pipe"
else
  fail "escaped-pipe fixture" 'a Check cell containing \|' "$(grep -m1 '^| I1' "$MDIR/checkpoint.md")"
fi
assert_phase "a Check cell with an escaped pipe keeps its status readable" "QA"
escaped_answer="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
if [ "$plain_answer" = "$escaped_answer" ]; then
  pass "the escaped pipe changes nothing about which phase is due"
else
  fail "the escaped pipe changes nothing about which phase is due" "$plain_answer" "$escaped_answer"
fi
mv "$MDIR/checkpoint.pipe.bak" "$MDIR/checkpoint.md"

# The same formatter, on the checkpoint. `|:---|:---:|` is what prettier and markdownlint write,
# and a separator cell that starts or ends with a colon is not matched by the `/^-+$/` skip: the
# separator becomes a ROW, its ID is `:---` and its Status is `:---:` — outside the enum. gate_EXEC
# then refuses the phase with "invalid status" on a checkpoint whose every increment is done.
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.colon.bak"
sed -i 's@^|---|---|---|---|---|$@|:---|:---|:---:|:---:|:---|@' "$MDIR/checkpoint.md"
if grep -qF '|:---|:---|:---:|:---:|:---|' "$MDIR/checkpoint.md"; then
  pass "fixture: the checkpoint separator really carries alignment colons"
else
  fail "alignment-colon fixture" "a separator row with colons" "$(sed -n '2p' "$MDIR/checkpoint.md")"
fi
assert_phase "an alignment-colon separator is not an increment" "QA"
mv "$MDIR/checkpoint.colon.bak" "$MDIR/checkpoint.md"

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

# --- the TL;DR cap, port 2 of 3 ------------------------------------------------
# One probe per port, the rule this file already follows for the escalations: a port added without
# one is a port whose removal no assertion notices. The pair is also a restore check — the second
# half proves the fixture went back to the world the block below it assumes.
{ printf -- '---\nfase: QA\nstatus: done\n---\n## TL;DR\n'; awk 'BEGIN{for(i=1;i<=21;i++) print "l" i}'; } > "$MDIR/30-handoff-qa.md"
assert_why   "QA refuses a TL;DR over the cap, ahead of everything else it checks" "QA" "TL;DR is 21 lines"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
assert_why   "and back under the cap QA goes back to reporting the missing report" "QA" "no report in"

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

# Anchor 3 reads the bug's GENRE, and the unknown genre blocks.
#
# Why the genre exists at all: no agent in the pipeline may write the `Status:` line — that tree
# belongs to the qa-report/qa-execution skills (agents/sdd-qa.md, "Rules that are not negotiable"), and
# sdd-executor does not know the registry exists. So for a bug whose fix is a PRODUCT decision
# there was no path from `open` to anything else, while Anchor 3 blocked the phase for it all the
# same. Measured in 20260825-frete-cif-fob: 7 of the 12 QA sessions were in that loop, US$ 73,32.
# `Closable by: agent` still blocks, because for THAT bug the F<n> cycle does close.
#
# One file rewritten three times, so nothing but the genre line differs between the regimes. The
# `<!-- agent | human -->` legend is in every regime ON PURPOSE: the word `human` then exists in
# EVERY bug file on the machine, so an anchor like `.*human` would fail open and switch Anchor 3
# off for the whole registry — the same trap bin/sdd:587-588 already records for `closed`. With
# the legend in the fixture, that loosening turns the differential red.
GENRE_BUG="$FIX/docs/qa/bugs/BUG-20260102-genre.md"
write_genre_bug() { # write_genre_bug <the `Closable by:` line, or '' for a bug older than the field>
  { printf '# BUG-20260102-genre: needs a call nobody in the pipeline can make\n'
    printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
    if [ -n "$1" ]; then printf -- '%s\n' "$1"; fi
  } > "$GENRE_BUG"
}

write_genre_bug '- **Closable by:** human <!-- agent | human -->'
genre_phase_human="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
genre_why_human="$(   cd "$FIX" && "$SDD" why "$MISSION" QA 2>&1 )"

write_genre_bug '- **Closable by:** agent <!-- agent | human -->'
genre_phase_agent="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
genre_why_agent="$(   cd "$FIX" && "$SDD" why "$MISSION" QA 2>&1 )"

# DIFFERENTIAL, and not two separate "the gate passed" / "the gate failed" assertions: "passed" is
# shared with every healthy regime, so on its own it distinguishes nothing (house rule, CLAUDE.md
# — an assertion whose reading a wrong branch also produces is not measuring the branch). The two
# regimes are compared against EACH OTHER, on one registry that differs by one word.
genre_reasons=same
[ "$genre_why_human" != "$genre_why_agent" ] && genre_reasons=differ
assert_eq "genre differential: human-closable passes, agent-closable blocks, reasons differ" \
  "REVIEW|QA|differ" "$genre_phase_human|$genre_phase_agent|$genre_reasons"

# The other half of the rule: the absence of the wrong branch's marker. Without it the pair above
# is satisfied by ANY two different reasons — two unrelated failures would read `differ` too.
# `grep -cF`: the marker carries `(s)`, and a BRE would read those parentheses as literal only by
# luck of the dialect.
assert_eq "only the agent-closable regime carries the blocking marker" "0|1" \
  "$( grep -cF 'with Status: open in the registry' <<< "$genre_why_human" )|$( grep -cF 'with Status: open in the registry' <<< "$genre_why_agent" )"

# Fail-safe, and the reason the default is not permissive: every bug file that already exists in
# every target repo predates this field. A missing genre reading as `human` would switch Anchor 3
# off for the entire legacy registry at once (decision 3 of the grill).
write_genre_bug ''
assert_phase "an open bug with no genre field still blocks (fail-safe for the legacy registry)" "QA"

# The genre is the WHOLE WORD, and the anchor above has no right-hand boundary — so every value that
# merely STARTS with `human` was read as the genre `human` and stopped blocking. `humano` is the
# pt-BR spelling, and this repo declares OUTPUT_LANG=pt-BR: the very translation the contract
# forbids was the one that slipped through. agents/sdd-qa.md's Language section states the opposite
# in so many words — "a translated genre is a genre the gate cannot read, and it reads as absent,
# which blocks" — so the gate was failing OPEN against its own written promise, in the PERMISSIVE
# direction that decision 3 of the grill exists to refuse. (`humans`, `humanoid` and `human-ish`
# went the same way; `Human` and `HUMAN` did not, the match being case-sensitive.)
#
# DIFFERENTIAL, on ONE LETTER: the exact genre must pass and the near-miss must block, compared
# against each other. "humano blocks" alone is satisfied by a gate that blocks everything — the
# over-broad fix — and "human passes" alone is the assertion three blocks up. The exact regime keeps
# the `<!-- agent | human -->` legend, so a fix that anchors the end of the line without allowing
# the legend after the value turns this half red instead of passing quietly.
write_genre_bug '- **Closable by:** human <!-- agent | human -->'
genre_exact="$(  cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
write_genre_bug '- **Closable by:** humano <!-- agent | human -->'
genre_prefix="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "the genre is the whole word: 'human' passes, the near-miss 'humano' still blocks" \
  "REVIEW|QA" "$genre_exact|$genre_prefix"

# ...and the genre is read from the FIELD, not from wherever the two words happen to appear. `grep
# -q` is true for ANY line of the file, so a bug whose own field says `agent` — the blocking
# default — stopped blocking as soon as its body QUOTED the human line, in a fenced block, a repro
# or a diff. Not a contrived body: `agents/sdd-qa.md` § 5.1 prints that exact line for the agent to
# copy, so a bug filed ABOUT the genre field is the likely first victim, and a registry bug is
# prose written by a skill that quotes freely.
#
# The asymmetry is what makes it a defect rather than a quirk. Its sibling anchor, `Status: open`,
# matches anywhere in the file too — but there anywhere-matching is CONSERVATIVE (it can only make
# a bug block). This is the first anchor in the gate where anywhere-matching is PERMISSIVE, and
# `bin/sdd:631-637` calls the anchor "strict about it" while being strict only against the
# enum-legend trap.
#
# DIFFERENTIAL against the genuine article: the field decides, so a real `human` FIELD passes and a
# `human` MENTION under an `agent` field does not. Asserting only that the quoting bug blocks would
# also be satisfied by a gate that blocks everything, which is the over-broad fix.
{ printf '# BUG-20260102-genre: filed about the genre field itself\n'
  printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
  printf -- '- **Closable by:** agent <!-- agent | human -->\n'
  printf '\nThe template line this bug is about reads:\n\n```md\n'
  printf -- '- **Closable by:** human <!-- agent | human -->\n'
  printf '```\n'
} > "$GENRE_BUG"
genre_quoted="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "the genre is the FIELD: a bug that merely quotes the human line still blocks" \
  "REVIEW|QA" "$genre_exact|$genre_quoted"

# ...and "the FIELD" means the file's OWN field, not the first thing SHAPED like one. The fix above
# landed as `grep -m1`, and "the first field-shaped line IS the field" holds only while nothing
# above the header is shaped like the field. The regime right above breaks that itself the moment
# its repro block moves: same `Closable by: agent` field, same fenced `human` line, only the ORDER
# changed, and the gate went back to answering `registry clean` with an agent-closable bug open.
# It shipped as a declared limit in bin/sdd and in the EXEC handoff; a declared limit is still a
# fail-open, and every looseness in THIS anchor is permissive. Reproduced and closed in the REVIEW
# round of 20260826-o-laco-da-qa.
#
# DIFFERENTIAL on ORDER ALONE, plus the passing control: the two quoting fixtures carry byte-equal
# metadata and a byte-equal fenced quote, and differ only in which comes first — so a gate that
# blocked everything would take `genre_exact` red with it, and a gate that read position instead of
# the field would take the block above red. Neither half alone measures the rule.
{ printf '# BUG-20260102-genre: filed about the genre field, repro pasted first\n'
  printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
  printf '\nSteps to reproduce — the registry line that triggers it:\n\n```md\n'
  printf -- '- **Closable by:** human <!-- agent | human -->\n'
  printf '```\n\n'
  printf -- '- **Closable by:** agent <!-- agent | human -->\n'
} > "$GENRE_BUG"
genre_quoted_above="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "the genre is the file's OWN field: a quote ABOVE it does not become the genre" \
  "REVIEW|QA" "$genre_exact|$genre_quoted_above"

# Four more rules of the same anchor, one regime each. All four were found by an adversarial
# sabotage pass in the REVIEW round of 20260826-o-laco-da-qa: each was degraded in turn and
# `./tests/run-all.sh` stayed GREEN, which by the house rule makes them rules without a probe. In
# THIS anchor that is never neutral — bin/sdd's own comment calls it "the first anchor in the gate
# where a loose match is PERMISSIVE, so every looseness here fails OPEN" — so each was a fail-open
# waiting for a bug body shaped that way. They are separate regimes and not one because they fail
# open INDEPENDENTLY: a single fixture would let three of them rot behind the fourth.
#
# Every one keeps `$genre_exact` as the passing control, for the same reason as the blocks above:
# a gate that blocked everything satisfies "it blocks" and would take the control red instead.

# (a) The genre is LOWERCASE. check-gates.sh asserted this in a COMMENT — "`Human` and `HUMAN` did
# not, the match being case-sensitive" — and nothing measured it: turning `grep -qE` into `grep
# -qiE` left the whole suite green while `Human` and `HUMAN` went from blocking to passing. A
# comment that states a measured property is not a measurement — the same rule this repo already
# applies to a comment claiming parity between two programs, where only a differential assertion
# counts as proof. This is the assertion that comment was standing in for.
write_genre_bug '- **Closable by:** Human <!-- agent | human -->'
genre_case="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "the genre is lowercase: the capitalised 'Human' reads as absent and still blocks" \
  "REVIEW|QA" "$genre_exact|$genre_case"

# (b) The FIRST field-shaped line outside a fence wins, and the extractor stops there. Without the
# `exit`, every unfenced field-shaped line is printed and the match runs over a MULTI-LINE
# `genre_line` — so `grep -q`, true for any line it is given, goes back to answering "human" for a
# file whose own field says `agent`. That is the very defect the F1 increment closed, re-entering
# through the extractor instead of through the matcher.
{ printf '# BUG-20260102-genre: two field-shaped lines, neither fenced\n'
  printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
  printf -- '- **Closable by:** agent <!-- agent | human -->\n'
  printf '\nA later paragraph repeats the line without fencing it:\n\n'
  printf -- '- **Closable by:** human <!-- agent | human -->\n'
} > "$GENRE_BUG"
genre_second="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "the FIRST unfenced field wins: a second field-shaped line later does not override it" \
  "REVIEW|QA" "$genre_exact|$genre_second"

# (c) BOTH fence spellings. GFM fences with ``` or with ~~~, and the extractor has to know both:
# knowing only ``` leaves a ~~~-fenced quote counting as an ordinary line, which puts the defect
# straight back for any bug filed with the other spelling. Same body as the quote-ABOVE regime,
# one character of fence apart.
{ printf '# BUG-20260102-genre: the repro is fenced with tildes\n'
  printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
  printf '\nSteps to reproduce:\n\n~~~md\n'
  printf -- '- **Closable by:** human <!-- agent | human -->\n'
  printf '~~~\n\n'
  printf -- '- **Closable by:** agent <!-- agent | human -->\n'
} > "$GENRE_BUG"
genre_tilde="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "a ~~~ fence hides the quote just as a \`\`\` fence does" \
  "REVIEW|QA" "$genre_exact|$genre_tilde"

# (d) The field starts at COLUMN ZERO. An indented `- **Closable by:** human` is a nested list
# item or an indented code block — body, never the header — and admitting leading whitespace lets
# any of them become the genre. Strict here for the same reason ABSENT blocks: in this anchor the
# loose reading is the permissive one.
#
# ⚠️ DECLARED REDUNDANCY, and this assertion is a PROPERTY probe rather than a rule probe — said
# out loud because the difference is exactly what the sabotage pass is for. The column-zero rule is
# enforced TWICE: once by the awk extractor's `/^-/` and once by the matcher's own `^\-`. Degrading
# either ALONE leaves the bug blocking, so neither has a probe of its own here. Measured, all four
# corners, on this very fixture:
#
#     awk strict + grep strict -> BLOCKS      awk LOOSE + grep strict -> BLOCKS
#     awk strict + grep LOOSE  -> BLOCKS      awk LOOSE + grep LOOSE  -> PASSES
#
# So the assertion is not vacuous — it is red in the one world where the property is actually
# gone — but nobody should read it as pinning the awk anchor. By the D15 admission rule a
# redundancy that is WRITTEN DOWN stops being debt; an unwritten one is the fail-open the rule
# exists to separate from it. If a later change removes one of the two anchors, this assertion
# will still pass, and that is the cost being declared here.
{ printf '# BUG-20260102-genre: the quote is indented, not fenced\n'
  printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
  printf '\nQuoted inside a nested list:\n\n'
  printf -- '  - **Closable by:** human <!-- agent | human -->\n'
  printf '\n'
  printf -- '- **Closable by:** agent <!-- agent | human -->\n'
} > "$GENRE_BUG"
genre_indented="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
assert_eq "the field starts at column zero: an indented quote does not become the genre" \
  "REVIEW|QA" "$genre_exact|$genre_indented"

rm -f "$GENRE_BUG"

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

echo "== QA phase — the e2e is red, and WHOSE fault it is =="
# A red e2e says nothing about whose fault it is: a dead app, a stopped database, a missing
# browser binary and a genuine assertion failure all leave the same non-zero rc. Before this
# block the runner read every one of them as "QA still has work to do" and bought another opus
# session — measured at US$ 14.16 on the SQ-111 mission of 2026-08-27, plus US$ 7.61 for the
# lap that reopened a mission whose PR was already open.
#
# FLOOR FIRST, and deliberately NOT written with the runner's own app_probe: a floor that reuses
# the function under test measures the runner with the runner. This is a raw connect, and when it
# cannot find a refused port it dies BY NAME rather than certifying a block that proved nothing.
port_is_free() {  # rc 0 = nothing is listening on 127.0.0.1:$1
  local rc=0
  LC_ALL=C timeout 3 bash -c 'exec 3<>"/dev/tcp/127.0.0.1/$0"' "$1" 2>/dev/null || rc=$?
  [ "$rc" -ne 0 ]
}
# BELOW the ephemeral range, and that is what makes the floor hold for the whole block. The floor
# proves the port refuses ONCE; the assertions under it then run several `sdd` invocations over
# minutes against that one measurement. Drawn from 49152-59171 the port sat INSIDE the kernel's
# `ip_local_port_range` (32768-60999 by default), so it could be handed out mid-block and the
# assertions would flip for a reason that has nothing to do with the runner. 20000-29999 is under
# that floor. DECLARED LIMIT: a machine that lowered `ip_local_port_range` past 20000, or that
# starts a real listener there mid-block, is back in the old window — the search loop below only
# re-measures at the start, and re-measuring per assertion would buy a smaller window at the price
# of a floor nobody can read.
dead_port=$(( 20000 + $$ % 10000 ))
floor_ok=1
if ! command -v timeout >/dev/null 2>&1; then
  fail "dead-app floor" "timeout(1) on PATH" "timeout is missing — the app-down block was NOT measured"
  floor_ok=0
else
  tries=0
  while ! port_is_free "$dead_port"; do
    dead_port=$(( dead_port + 1 )); tries=$(( tries + 1 ))
    if [ "$tries" -ge 20 ]; then
      fail "dead-app floor" "a refused port on 127.0.0.1" \
           "20 consecutive ports were all listening — the block would certify nothing"
      floor_ok=0; break
    fi
  done
fi

if [ "$floor_ok" = "1" ]; then
  pass "dead-app floor: 127.0.0.1:$dead_port refuses connections"

  # ⭐ THE DIFFERENTIAL PAIR. Same closed APP_URL on both sides; only E2E_CMD moves. The red half
  # alone would pass under a runner that probes unconditionally; the green half alone would pass
  # under a runner that never probes. Neither half is the assertion — the pair is.
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port/\"|" .sdd/config.sh
  sed -i 's|^E2E_CMD=.*|E2E_CMD="false"|' .sdd/config.sh
  assert_phase "e2e red over a dead app does not advance" "QA"
  assert_why   "the reason names the address nothing is listening on" "QA" \
               "nothing is listening at 127\.0\.0\.1:$dead_port"
  assert_why_absent "an app that WAS probed is not reported as unprobed" "QA" "not probed"

  # The green half, and it is what protects the `example.invalid` fixture above — that one sits
  # beside a GREEN E2E_CMD, and a runner that probed before the gate would block it for a machine
  # state that never mattered. A false BLOCKED costs a person; the loop only costs money.
  sed -i 's|^E2E_CMD=.*|E2E_CMD="true"|' .sdd/config.sh
  assert_phase "a dead app does NOT block a green e2e" "REVIEW"

  # Parser regimes, each read through `sdd why` so the assertion exercises the PATH and not just
  # the function — the lesson check-todo.sh's --check mode paid for.
  sed -i 's|^E2E_CMD=.*|E2E_CMD="false"|' .sdd/config.sh
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port/path?q=1#frag\"|" .sdd/config.sh
  assert_why "path, query and fragment are stripped" "QA" "at 127\.0\.0\.1:$dead_port"
  # A placeholder pair on loopback — nothing listens there and nothing is a credential — with an
  # `@` INSIDE the password, because the LAST `@` is the separator: a fixture without one would
  # pass a parser that cut at the first.
  sed -i "s|^APP_URL=.*|APP_URL=\"http://user:CHANGE@ME@127.0.0.1:$dead_port/\"|" .sdd/config.sh
  assert_why "userinfo is stripped, and the last @ is the separator" "QA" "at 127\.0\.0\.1:$dead_port"
  sed -i "s|^APP_URL=.*|APP_URL=\"http://[::1]:$dead_port/\"|" .sdd/config.sh
  assert_why "an IPv6 literal reads as an address" "QA" "at \[::1\]:$dead_port"
  # Query and fragment WITHOUT a path, one fixture each: with a path in front of them the `/` strip
  # swallows both before their own strips ever run, so `/path?q=1#frag` above measures the path
  # alone — neutralising either of the other two strips survived it. Measured in the review round
  # of 20260828-o-gate-sabe-que-o-app-caiu, and each of the three now has its own mutant.
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port?q=1\"|" .sdd/config.sh
  assert_why "a query with no path is stripped" "QA" "at 127\.0\.0\.1:$dead_port"
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port#frag\"|" .sdd/config.sh
  assert_why "a fragment with no path is stripped" "QA" "at 127\.0\.0\.1:$dead_port"
  # Address only, NOT the verdict: port 80 may well be open on the machine running this, and both
  # the up and the down sentence carry the label. Machine-independent by construction.
  sed -i 's|^APP_URL=.*|APP_URL="http://127.0.0.1/"|' .sdd/config.sh
  assert_why "http with no port defaults to 80" "QA" "127\.0\.0\.1:80"

  # ⭐ THE CASE PAIR, and it is two assertions because the fix is two decisions. The scheme is
  # case-insensitive (RFC 3986 §3.1), so `HTTP://` has to reach an address — a parser that reads
  # it literally sends the majority-adjacent spelling to `unknown`, where NOTHING fails and
  # nothing warns and the escalation simply stops existing. That is the first half.
  sed -i "s|^APP_URL=.*|APP_URL=\"HTTP://127.0.0.1:$dead_port/\"|" .sdd/config.sh
  assert_why "an uppercase scheme reads as an address" "QA" "at 127\.0\.0\.1:$dead_port"
  # The second half, and it is what stops the cheap fix: folding the whole URL to lower case would
  # also pass the line above, and would then fold the HOST — which rides into the sentence the
  # operator reads and goes looking for. Asserted on a name that cannot resolve, so this measures
  # the LABEL and never the verdict: all three arms carry it, exactly like the port-80 case above.
  sed -i "s|^APP_URL=.*|APP_URL=\"HTTPS://EXAMPLE.INVALID:$dead_port/\"|" .sdd/config.sh
  assert_why "and the host keeps the case the operator wrote" "QA" "EXAMPLE\.INVALID:$dead_port"

  # The one-sided contract: what the probe cannot decide, it never escalates.
  sed -i 's|^APP_URL=.*|APP_URL=""|' .sdd/config.sh
  assert_why        "an empty APP_URL is not probed" "QA" "not probed"
  assert_why_absent "an empty APP_URL never claims a dead app" "QA" "nothing is listening"
  sed -i 's|^APP_URL=.*|APP_URL="not a url"|' .sdd/config.sh
  assert_why        "an unparseable APP_URL is not probed" "QA" "not probed"
  assert_why_absent "an unparseable APP_URL never claims a dead app" "QA" "nothing is listening"
fi

# Restore what the next block's sed expects to find.
sed -i 's|^E2E_CMD=.*|E2E_CMD="true"|; s|^APP_URL=.*|APP_URL="http://example.invalid"|' .sdd/config.sh
assert_phase "the fixture is back where the next block starts" "REVIEW"

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

# --- the TL;DR cap, port 3 of 3 ------------------------------------------------
# `## Fim` closes the section on purpose: without a following `## ` heading the count would run to
# the end of the file and this assertion would be about a number nobody chose. `### Overall Grade`
# does NOT close it — `^## ` wants a space in the third column — which is exactly the kind of thing
# a fixture written from memory gets wrong.
cp "$MDIR/40-review-r1.md" "$MDIR/40.bak"
{ printf '## TL;DR\n'; awk 'BEGIN{for(i=1;i<=21;i++) print "l" i}'; printf '## Fim\n'; cat "$MDIR/40.bak"; } > "$MDIR/40-review-r1.md"
assert_why   "REVIEW refuses a TL;DR over the cap" "REVIEW" "TL;DR is 21 lines"
mv "$MDIR/40.bak" "$MDIR/40-review-r1.md"
assert_why   "and back under the cap REVIEW goes back to reporting the grade" "REVIEW" "Security = B"

# L1 of the 2026-09-03 audit: Grade A is required on every criterion, except the rows named in
# REVIEW_PROSE_CRITERIA (Documentation, Overall — graded on the mission's own prose), which pass at
# REVIEW_PROSE_MIN_GRADE (B). Measured on
# 20260902-o-rascunho-legado-fala-cru: four rounds, ~US$ 133, zero functional findings, every round
# blocked on `Documentation = B`, each prose fix writing new prose for the next round to grade. The
# floor is a config key and the list is a config key, so both are probed both ways below.
review_with() { # review_with <Security grade> <Documentation grade> — r1 in the template's shape
  cat > "$MDIR/40-review-r1.md" <<EOF
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Type Safety | A | clean |
| Error Handling | A | clean |
| Security | $1 | measured |
| Performance | A | clean |
| Test Coverage | A | clean |
| Documentation | $2 | two docstrings still generalise |
| **Overall** | **B** | prose only |
EOF
}
review_with A B
git add -A && git commit -qm "chore: r1 with Documentation at B"
assert_phase "Documentation at B, A everywhere a sensor exists: the round is over" "DOCS"
review_with A C
git add -A && git commit -qm "chore: r1 with Documentation at C"
assert_phase "Documentation at C is below the floor and does not pass" "REVIEW"
assert_why   "REVIEW names the criterion, the grade and the floor" "REVIEW" "Documentation = C.*REVIEW_PROSE_MIN_GRADE=B"
review_with A B
printf 'REVIEW_PROSE_CRITERIA="Overall"\n' >> .sdd/config.sh
git add -A && git commit -qm "chore: Documentation no longer tolerated"
assert_phase "taking Documentation out of REVIEW_PROSE_CRITERIA makes its B fail again" "REVIEW"
assert_why   "and the reason names the strict rule" "REVIEW" "Documentation = B.*outside REVIEW_PROSE_CRITERIA"
sed -i '/^REVIEW_PROSE_CRITERIA=/d' .sdd/config.sh
# The tolerated set is named POSITIVELY: a row the config does not know is strict, so a renamed
# criterion or a typo cannot buy the floor. Found by the check-autonomy fixture whose only row is
# `Correctness | B`, which a first draft (naming the strict six instead) let through.
cat > "$MDIR/40-review-r1.md" <<'EOF'
### Overall Grade

| Criterion | Grade | Rationale |
|-----------|-------|-----------|
| Code Quality (Zen) | A | clean |
| Securlty | B | a typo in the name would have bought the floor |
| Documentation | A | clean |
EOF
git add -A && git commit -qm "chore: a criterion nobody knows, at B"
assert_phase "a criterion name the config does not know stays strict at B" "REVIEW"
assert_why   "and is named as such" "REVIEW" "Securlty = B.*outside REVIEW_PROSE_CRITERIA"
review_with A C
printf 'REVIEW_PROSE_MIN_GRADE="C"\n' >> .sdd/config.sh
git add -A && git commit -qm "chore: floor lowered to C"
assert_phase "REVIEW_PROSE_MIN_GRADE=C lowers the floor and the C passes" "DOCS"
sed -i '/^REVIEW_PROSE_MIN_GRADE=/d' .sdd/config.sh
review_with A —
git add -A && git commit -qm "chore: Documentation not analysed"
assert_phase "a '—' on a tolerated criterion still fails: not analysed is not a grade" "REVIEW"
review_with B A
git add -A && git commit -qm "chore: back to Security at B"

# The REVIEW⇄EXEC loop, in both directions. Since `20260901-o-revisor-so-acha` a round that found
# something does not fix it in place: it writes an `R<n>` row into the SAME checkpoint table and
# ends. Nothing in the runner had to learn about the prefix — `current_phase()` walks
# `PLAN TICKET EXEC QA REVIEW …` and returns the first red gate, so a pending row fails `gate_EXEC`
# two phases before `gate_REVIEW` is ever read. That is the route the QA's `F<n>` already takes; the
# assertions below pin it for the reviewer's rows too, because a checkpoint parser taught to
# recognise `I`/`F` would silently strand every round of every future mission.
#
# Both directions, and the second is why the first is not vacuous: a runner that simply never leaves
# EXEC satisfies the first assertion whatever it reads.
cp "$MDIR/checkpoint.md" "$MDIR/checkpoint.rn.bak"
printf '%s\n' '| R1 | finding #1 of r1 becomes an increment | `true` → 0 | pending | — |' >> "$MDIR/checkpoint.md"
assert_phase "a review graded B with a pending R1 hands the ball to EXEC" "EXEC"

git add -A && git commit -qm "chore: r1 with a pending R1"
R1_HASH="$(git rev-parse --short HEAD)"
sed -i "s@| R1 | finding #1 of r1 becomes an increment | \`true\` → 0 | pending | — |@| R1 | finding #1 of r1 becomes an increment | \`true\` → 0 | done | $R1_HASH |@" \
  "$MDIR/checkpoint.md"
# Dies loud if it sabotaged nothing: a `sed` whose pattern rotted would leave the row `pending` and
# the assertion below would then be measuring the line above it a second time.
if grep -qF "| R1 | finding #1 of r1 becomes an increment | \`true\` → 0 | done | $R1_HASH |" "$MDIR/checkpoint.md"; then
  pass "fixture: the R1 row really closed with a commit that is in the history"
else
  fail "R1-done fixture" "an R1 row marked done with a real hash" "$(grep '^| R1' "$MDIR/checkpoint.md")"
fi
assert_phase "and once R1 is done the ball comes back to REVIEW" "REVIEW"
mv "$MDIR/checkpoint.rn.bak" "$MDIR/checkpoint.md"

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
| **Overall** | **A** | nothing left open |

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
| **Overall** | **C** | one HIGH left open |
EOF
git add -A && git commit -qm "chore: review r10"
assert_phase "the tenth round counts, not the third: r10 > r3 by version" "REVIEW"
assert_why   "REVIEW quotes the grade of the version-ordered pick" "REVIEW" "40-review-r10\.md: Security = C"
assert_why_absent "the lexicographic pick (r3) is not the file the gate read" "REVIEW" "40-review-r3\.md"

# r10 turns green and the phase advances — proving the gate advances BECAUSE of r10, not despite
# it. Without this second half the assertion above would also pass on a runner that simply never
# leaves REVIEW.
sed -i 's/^| Security | C |.*/| Security | A | clean |/;s/^| \*\*Overall\*\* .*/| **Overall** | **A** | nothing left open |/' \
  "$MDIR/40-review-r10.md"
git add -A && git commit -qm "chore: review"
assert_phase "last review all Grade A, suite green, clean tree" "DOCS"

# The separator row prettier and markdownlint actually write. GFM spells column alignment with
# colons — `|:---|:---:|---:|` — and the `/^-+$/` skip does not match a cell that starts or ends
# with one, so the separator became a criterion: `: = ---` , a grade no reviewer wrote, on a
# criterion named `:`. REVIEW then loops to its ceiling with a GATE_WHY naming no criterion at all,
# and every round costs a session. Nothing in the kit writes these colons — a formatter run over
# the target repo does, which is why no fixture had them until now.
cat > "$MDIR/40-review-r11.md" <<'EOF'
# Review r11
### Overall Grade

| Criterion | Grade | Rationale |
|:----------|:-----:|:----------|
| Code Quality (Zen) | A | clean |
| Type Safety | A | clean |
| Error Handling | A | clean |
| Security | A | clean |
| Performance | A | clean |
| Test Coverage | A | clean |
| Documentation | A | clean |
| **Overall** | **A** | nothing left open |
EOF
git add -A && git commit -qm "chore: review r11, formatter-aligned"
assert_phase "an alignment-colon separator row is not a criterion" "DOCS"
assert_why_absent "and the reason does not name the separator as a criterion" "REVIEW" "^:|= ---|:---"

# --- the REVIEW ceiling counts rounds in total, not per invocation ----------
# `attempts` is a `local -A` of cmd_run, born with the PROCESS. REVIEW_MAX_ITER therefore only ever
# capped ONE `sdd run`: three rounds, escalate — and the next `sdd run` handed out three more, for
# ever, on the most expensive phase in the kit. The rounds are on disk as `40-review-r<N>.md`, which
# is where the whole kit derives its state from.
#
# The fixture already carries r1, r2, r3, r10 and r11, so the count on disk is 11 against a
# REVIEW_MAX_ITER of 3. r11 goes red so REVIEW is the DERIVED phase again.
sed -i 's/^| Security | A | clean |/| Security | C | injection left open |/;s/^| \*\*Overall\*\* .*/| **Overall** | **C** | one HIGH left open |/' \
  "$MDIR/40-review-r11.md"
git add -A && git commit -qm "chore: review r11 red again"
assert_phase "fixture: REVIEW is the derived phase again" "REVIEW"

review_sessions_spent() { phase_sessions_spent REVIEW; }
rv_before="$(review_sessions_spent)"
out_rv="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 )"; rc_rv=$?
rv_after="$(review_sessions_spent)"
if [ "$rc_rv" -eq 3 ] && [ "$rv_after" -eq "$rv_before" ] \
   && grep -q "rounds IN TOTAL" <<< "$out_rv"; then
  pass "a fresh sdd run refuses round N+1 past REVIEW_MAX_ITER (exit 3, no session spent)"
else
  fail "a fresh sdd run refuses round N+1 past REVIEW_MAX_ITER (exit 3, no session spent)" \
       "exit 3, the disk-derived ceiling, and no new REVIEW session log" \
       "exit $rc_rv, $rv_before → $rv_after log(s): $(tail -3 <<< "$out_rv")"
fi

# The headline and the sentence that makes it true travel on the SAME channel. With the ceiling
# derived from disk the count in the headline is `0` — this invocation opened no session, because
# the ceiling refused before it could — so read alone it looks like a runner bug. `bad` writes to
# stderr and `dim` to stdout: with the note on `dim`, `sdd run 2>/dev/null` kept the sentence and
# dropped the headline, and `sdd run >file` kept the headline and dropped the sentence.
#
# `2>&1 >/dev/null` and not `2>&1`: the order matters and it is the whole assertion. stderr is
# pointed at the capture FIRST, then stdout is thrown away, so what comes back is stderr ALONE.
# Every other assertion in this file merges the two and is green whichever channel each half took
# — this is the only one that can tell them apart, which is why the note above it says so.
err_rv="$( cd "$FIX" && "$SDD" run "$MISSION" 2>&1 >/dev/null )"
if grep -q "BLOCKED in REVIEW" <<< "$err_rv" && grep -q "rounds IN TOTAL" <<< "$err_rv"; then
  pass "the ceiling note rides the same channel as the headline it explains"
else
  fail "the ceiling note rides the same channel as the headline it explains" \
       "stderr alone carrying BOTH the headline and the 'rounds IN TOTAL' sentence" \
       "stderr alone: $(tail -3 <<< "$err_rv")"
fi
# And the other half, or the assertion above is satisfied by a runner that shouts everything on
# stderr and leaves stdout empty: the navigation hint is NOT an escalation line and stays on stdout.
out_only_rv="$( cd "$FIX" && "$SDD" run "$MISSION" 2>/dev/null )"
if grep -q "shows the full state" <<< "$out_only_rv"; then
  pass "and the navigation hint stays on stdout, where it was"
else
  fail "and the navigation hint stays on stdout, where it was" \
       "stdout alone carrying the 'sdd status' hint" "stdout alone: $(tail -3 <<< "$out_only_rv")"
fi

# The differential, one config key apart: with the ceiling above the rounds on disk, the SAME state
# spends a session. Without it, a runner that escalated on every derived REVIEW would pass the
# assertion above while making the phase unreachable.
printf 'REVIEW_MAX_ITER=99\n' >> .sdd/config.sh
git add -A && git commit -qm "chore: raise the review ceiling"
out_rv2="$( cd "$FIX" && "$SDD" run "$MISSION" --max-phases 1 2>&1 )"; rc_rv2=$?
if [ "$(review_sessions_spent)" -gt "$rv_after" ]; then
  pass "with REVIEW_MAX_ITER above the rounds on disk the same state opens a session"
else
  fail "the ceiling is what refuses, not the phase itself" "a new REVIEW session log" \
       "exit $rc_rv2: $(tail -3 <<< "$out_rv2")"
fi

# And `--phase REVIEW` is a human asking for one specific round with their eyes on it: the
# disk-derived ceiling does not apply to the forced path, or the round that unblocks the mission
# could never be run.
sed -i '/^REVIEW_MAX_ITER=99$/d' .sdd/config.sh
git add -A && git commit -qm "chore: back to the default ceiling"
rv3="$(review_sessions_spent)"
out_rv3="$( cd "$FIX" && "$SDD" run "$MISSION" --phase REVIEW 2>&1 )"; rc_rv3=$?
if [ "$(review_sessions_spent)" -gt "$rv3" ]; then
  pass "--phase REVIEW still runs the round a human asked for"
else
  fail "--phase REVIEW still runs the round a human asked for" "a new REVIEW session log" \
       "exit $rc_rv3: $(tail -3 <<< "$out_rv3")"
fi

# Back to green so the phases below carry on from DOCS.
sed -i 's/^| Security | C |.*/| Security | A | clean |/;s/^| \*\*Overall\*\* .*/| **Overall** | **A** | nothing left open |/' \
  "$MDIR/40-review-r11.md"
git add -A && git commit -qm "chore: review r11 green"
assert_phase "with the ceiling fixture gone the mission is back at DOCS" "DOCS"

# --- the Rationale column ---------------------------------------------------
#
# DIFFERENTIAL, and it has to be: the extractor read `crit = f[2]; grade = f[3]` and never touched
# `f[4]`, so a table with `A` on every row and the literal `PREENCHER` on every justification
# bought a green gate. Not a hypothesis — the live instance is
# docs/handoffs/20260818-lote-facil/40-review-r1.md, whose own `gate:` field records that the round
# left `PREENCHER` in all seven rationales. An `A` that no sentence supports is exactly the label
# this repo refuses to accept in place of an artifact.
#
# The nine worlds below differ ONLY in the Rationale column and in the `gate:` frontmatter — same
# file name, same criteria, same grades, same tree state. Asserting one of them alone would not say
# WHICH column the gate read: a runner that never leaves REVIEW satisfies the refusing worlds, and
# one that reads nothing at all satisfies the accepting ones. The pair is what distinguishes them.
#
# The two accepting worlds are not decoration either. World 5 is the near miss the refusal must
# NOT eat (a real sentence that happens to contain `<A>`): the rule targets the WHOLE cell being a
# placeholder, never the presence of the character. World 6 carries `clean`, `n/a` and `—`, which
# are the codereview skill's own terse rationales (report-template.md:154-156) — refusing them
# would make the gate contradict the skill it parses, which is the SQ-97 gate_DOCS bug again.
i3_bad=0
# Counted, never written in prose. The failure line used to say "the 6 worlds above" while nine ran
# below it, and it stayed 6 as the block grew — the same class CLAUDE.md names with `44 caught of
# 44`: a number in a rubric with no command beside it expires quietly. Every `_phase` helper in this
# file now increments its own tally, so the sentence can only be wrong if the tally is.
i3_worlds=0
i3_rows=("Code Quality (Zen)" "Type Safety" "Error Handling" "Security" "Performance" "Test Coverage" "Documentation")

write_r11() { # write_r11 <rationale on every row> [gate: frontmatter value] — latest round by version
  # The literal @empty@ writes the key with NO value at all. That is a third world, not a spelling
  # of the second: an omitted argument means the key is ABSENT (six rounds on disk in this repo are
  # like that, and the gate leaves them alone), while `gate:` written and left blank is a round
  # claiming a seal it never filled. frontmatter() cannot tell them apart on its own — it prints
  # the same empty string for both — so the fixture has to be able to build both.
  local rat="$1" gate="${2-}" c
  {
    if [ "$gate" = '@empty@' ]; then printf -- '---\nfase: REVIEW\nrodada: 11\ngate:\n---\n\n'
    elif [ -n "$gate" ]; then printf -- '---\nfase: REVIEW\nrodada: 11\ngate: %s\n---\n\n' "$gate"; fi
    printf '# Review r11\n\n### Overall Grade\n\n'
    printf '| Criterion | Grade | Rationale |\n|-----------|-------|-----------|\n'
    for c in "${i3_rows[@]}"; do printf '| %s | A | %s |\n' "$c" "$rat"; done
    printf '| **Overall** | **A** | %s |\n' "$rat"
  } > "$MDIR/40-review-r11.md"
}

commit_r11() { git add -A && git commit -qm "chore: review r11" >/dev/null; }

i3_phase() { # i3_phase <world> <expected phase>
  local world="$1" want="$2" got
  i3_worlds=$((i3_worlds + 1))
  got="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
  [ "$got" = "$want" ] && return 0
  printf '         world "%s": expected phase %s, got %s\n' "$world" "$want" "$got" >&2
  i3_bad=$((i3_bad + 1))
}

i3_why() { # i3_why <world> <regex the reason MUST match> <regex it must NOT match>
  local world="$1" want="$2" absent="$3" got
  got="$( cd "$FIX" && "$SDD" why "$MISSION" REVIEW 2>&1 )"
  if ! grep -qE "$want" <<< "$got"; then
    printf '         world "%s": reason did not match /%s/ — got: %s\n' "$world" "$want" "$got" >&2
    i3_bad=$((i3_bad + 1))
  fi
  # Herestring, never `printf | grep -q` — see the note on assert_why_absent above.
  if grep -qE "$absent" <<< "$got"; then
    printf '         world "%s": reason still carries /%s/, so the gate did not stop at the table — got: %s\n' \
      "$world" "$absent" "$got" >&2
    i3_bad=$((i3_bad + 1))
  fi
}

# 1. filled in — the control. Without it every refusal below would also pass on a gate that
#    refuses everything, and the assertion would be measuring nothing.
write_r11 "reproduced before the fix and green after it"; commit_r11
i3_phase "a real justification on every row" "DOCS"

# 2. the live instance: `A` everywhere, `PREENCHER` everywhere. `assert_why_absent` in spirit —
#    demanding the ABSENCE of the dirty-tree/suite markers is what proves the gate stopped at the
#    table instead of arriving at the same verdict by a different road.
write_r11 "PREENCHER"; commit_r11
i3_phase "the whole Rationale column left as PREENCHER" "REVIEW"
i3_why   "PREENCHER" "Code Quality \(Zen\).*placeholder Rationale" "tree dirty|working tree|TEST_CMD"

# 3. the template shipped unfilled. Copied from templates/review.md, whose Rationale cells are
#    `<…>` — the shape a round that started from the template and never filled it in still has.
write_r11 "<…>"; commit_r11
i3_phase "the template placeholder left between angle brackets" "REVIEW"

# 4. ONE empty cell among seven real ones — the cheapest way to inflate a grade, and the row the
#    reason has to name is the empty one, never the first.
write_r11 "measured, nothing open"
sed -i 's/^| Test Coverage | A | .* |$/| Test Coverage | A |  |/' "$MDIR/40-review-r11.md"; commit_r11
i3_phase "a single empty Rationale among filled ones" "REVIEW"
i3_why   "one empty cell" "Test Coverage.*placeholder Rationale \(<empty>\)" "Code Quality"

# 5. the near miss. A refusal keyed on the CHARACTER instead of the whole cell would eat this.
write_r11 "refuted: the reviewer read <A> as a grade and it is prose"; commit_r11
i3_phase "a real sentence that merely contains angle brackets" "DOCS"

# 6. the skill's own terse rationales, which mean measured-and-nothing-to-say.
write_r11 "clean"
sed -i 's/^| Security | A | clean |$/| Security | A | — |/;s/^| Performance | A | clean |$/| Performance | A | n\/a |/' \
  "$MDIR/40-review-r11.md"; commit_r11
i3_phase "clean, n/a and — are the skill's terse rationales, not placeholders" "DOCS"

# 7-9. the other half of the seal: the `gate:` frontmatter, which templates/review.md ships as an
#      unfilled `<…>`. Same rule, one implementation — the field is fed INTO the same awk. The
#      ABSENT world is the one that keeps this from rewriting history: 6 of the 14 rounds on disk
#      in this repo carry no `gate:` at all, and every world above already exercises it.
write_r11 "measured, nothing open" "<the evidence this round closed>"; commit_r11
i3_phase "the gate: frontmatter left as the template shipped it" "REVIEW"
i3_why   "gate: placeholder" "gate:. frontmatter is still a placeholder" "tree dirty|working tree|TEST_CMD"

write_r11 "measured, nothing open" "PREENCHER"; commit_r11
i3_phase "the gate: frontmatter left as PREENCHER" "REVIEW"

write_r11 "measured, nothing open" "tests/run-all.sh: suite green, 559 assertions, tree clean"; commit_r11
i3_phase "a gate: frontmatter carrying real evidence closes the round" "DOCS"

# 10. the false RED, which is the same defect as a false green wearing the other coat. GFM writes a
#     literal pipe inside a cell as `\|`, and the extractor splits the row on every `|` byte: the
#     cell below was cut at the escape, the stump `TODO\` normalised into a refused fill-in word,
#     and a fully justified round was blocked with a reason that is not true. A gate that refuses
#     everything passes every world above this one; only this world tells the two apart.
#     ⚠️ The cell has to OPEN with the escaped pipe. Written first as "the `TODO\|` list …", the
#     stump left behind was `the TODO\`, which normalises to THETODO and is not a fill-in word — the
#     world went green against the unfixed runner and measured nothing. Caught by the sabotage pass,
#     which is the whole reason this repo runs one.
write_r11 '`TODO\|` list references removed; assertions now target the function. Green.'
commit_r11
i3_phase "a Rationale quoting a shell pipeline is a real justification" "DOCS"

# 11. and the evidence the refusal QUOTES has to be the bytes on disk. `awk -v x=…` runs the value
#     through awk's escape processing before the program sees it, so a `gate:` carrying a regex
#     arrived mangled and the refusal echoed text the file does not contain. Measured side by side
#     on mawk 1.3.4: `-v` turns this value into `<a<TAB>b>`, ENVIRON hands it over byte for byte.
write_r11 "measured, nothing open" '<a\tb>'; commit_r11
i3_phase "a gate: placeholder is refused whatever escapes it carries" "REVIEW"
i3_why   "gate: escapes survive verbatim" 'placeholder \(<a\\tb>\)' "tree dirty|working tree|TEST_CMD"

# 12. the PARITY of that escape, and this world exists because the FIRST rejoin got it wrong. `\\`
#     is how GFM spells a literal backslash, so a cell ending in one sits against a REAL delimiter;
#     asking merely "does this field end in a backslash" glued two columns into one. Measured
#     against the runner one commit earlier, which passes the same row: it was reported as
#     `Escaping (\| A = Confirmed …`, a Grade-A round blocked by a criterion nobody wrote. World 10
#     alone could never see it — it only carries an ODD run — so the fix of this round had made the
#     defect this round's second pass found, which is the loop CLAUDE.md says to break by asking
#     what state is missing. The missing state was the COUNT of the backslashes.
write_r11 "measured, nothing open"
sed -i 's/^| Code Quality (Zen) | A | measured, nothing open |$/| Escaping (\\\\| A | measured, nothing open |/' \
  "$MDIR/40-review-r11.md"
commit_r11
i3_phase "a cell ending in an escaped backslash sits against a REAL delimiter" "DOCS"

if [ "$i3_bad" -eq 0 ]; then
  pass "gate_REVIEW: a placeholder Rationale does not buy an A"
else
  fail "gate_REVIEW: a placeholder Rationale does not buy an A" \
       "the $i3_worlds worlds above agreeing" "$i3_bad disagreement(s), listed above"
fi

# --- the seal that one keystroke used to win ---------------------------------
#
# The rule above shipped with two holes, both found by walking the journey it created:
#
#   (a) `gate_field != "" && placeholder(gate_field)` cannot tell a key that is ABSENT from a key
#       written and left BLANK — frontmatter() prints the same empty string for both. So the
#       comment three lines above it in bin/sdd claimed "present-but-unfilled is the case that
#       lies, and it is the one refused" while `gate:` with nothing after it walked straight
#       through. A gate whose comment is ahead of its code is the failure mode this repo pays for.
#
#   (b) placeholder() compared the WHOLE cell by equality, so a single character of punctuation
#       bought the A: `TODO:` — which is what a model actually writes, more often than the bare
#       `TODO` the list knew — plus `TBD.`, `-`, `?`, `WIP` and `FILL ME`.
#
# The refusing worlds and the accepting ones are BOTH load-bearing, and the accepting ones more so
# here than anywhere else in this file: the fix for (b) is a rule about punctuation, and mawk is
# byte-oriented. The skill's own terse rationale `—` is E2 80 94, three bytes that no character
# class sees as one — a rule spelled with [[:punct:]] or a negated class strips it away and turns
# the blessed cell into an empty one. World `—` below is that probe, and it is the reason this
# block exists as a pair instead of a list of refusals.
f3_bad=0
# Counted and not written in prose — see the note on i3_worlds above. This block's hand-written 11
# happened to be right the day it was written, which is the only state a hand-written count is ever
# in; the two beside it had already drifted to 6 while nine and eight worlds ran under them.
f3_worlds=0

# Twins of i3_phase/i3_why, counting into their own variable ON PURPOSE. Sharing the counter would
# make one broken world redden BOTH assertions, and the report would name a rule that never broke.
f3_phase() { # f3_phase <world> <expected phase>
  local world="$1" want="$2" got
  f3_worlds=$((f3_worlds + 1))
  got="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
  [ "$got" = "$want" ] && return 0
  printf '         world "%s": expected phase %s, got %s\n' "$world" "$want" "$got" >&2
  f3_bad=$((f3_bad + 1))
}

f3_why() { # f3_why <world> <regex the reason MUST match> <regex it must NOT match>
  local world="$1" want="$2" absent="$3" got
  got="$( cd "$FIX" && "$SDD" why "$MISSION" REVIEW 2>&1 )"
  if ! grep -qE "$want" <<< "$got"; then
    printf '         world "%s": reason did not match /%s/ — got: %s\n' "$world" "$want" "$got" >&2
    f3_bad=$((f3_bad + 1))
  fi
  if grep -qE "$absent" <<< "$got"; then
    printf '         world "%s": reason still carries /%s/, so the gate did not stop at the seal — got: %s\n' \
      "$world" "$absent" "$got" >&2
    f3_bad=$((f3_bad + 1))
  fi
}

# (a) the unfilled seal. The Rationale column is real prose in this world, so the ONLY thing that
#     can stop the round is the blank `gate:` — and the reason has to say so, naming <empty>.
write_r11 "measured, nothing open" '@empty@'; commit_r11
f3_phase "gate: written and left blank" "REVIEW"
f3_why   "gate: written and left blank" "gate:. frontmatter is still a placeholder \(<empty>\)" \
         "tree dirty|working tree|TEST_CMD"

# The control for (a), and the one that keeps this from rewriting history: ABSENT is not blank.
write_r11 "measured, nothing open"; commit_r11
f3_phase "no gate: field at all, as six rounds on disk in this repo" "DOCS"

# (b) the punctuated fill-ins. `TODO:` first: it is the spelling the equality test missed.
write_r11 "TODO:"; commit_r11
f3_phase "TODO with a colon" "REVIEW"
f3_why   "TODO with a colon" "Code Quality \(Zen\).*placeholder Rationale \(TODO:\)" \
         "tree dirty|working tree|TEST_CMD"

write_r11 "TBD."; commit_r11
f3_phase "TBD with a full stop" "REVIEW"

write_r11 "WIP"; commit_r11
f3_phase "WIP is an admission the criterion is unfinished" "REVIEW"

write_r11 "FILL ME"; commit_r11
f3_phase "FILL ME, the fill-in written as two words" "REVIEW"

# A cell that is only punctuation says nothing at all. `-` is ONE keystroke from the `—` two
# worlds below, which is why the pair has to be measured and not reasoned about. There is no
# second world for `?` or `.`: they die to the very same sabotage as this one, and a probe that
# no distinct degradation can turn red on its own is decoration.
write_r11 "-"; commit_r11
f3_phase "a bare ASCII hyphen" "REVIEW"

# The same rule reaching the other half of the seal — one definition, fed into the same awk. If
# the two halves ever grow separate spellings, this world is what notices.
write_r11 "measured, nothing open" "TBD."; commit_r11
f3_phase "the gate: frontmatter carrying a punctuated fill-in" "REVIEW"

# --- the near misses the refusal must NOT eat --------------------------------
#
# THE probe of this block: mawk is byte-oriented, `—` is E2 80 94, and every rule that strips
# punctuation would strip it byte by byte into the empty cell the gate refuses. The codereview
# skill ships it as a terse rationale (report-template.md:154-156); eating it would make the gate
# contradict the skill it parses, which is the SQ-97 gate_DOCS bug for the third time.
write_r11 "—"; commit_r11
f3_phase "the em dash survives a rule written about punctuation" "DOCS"

# The second of the skill's three terse rationales, and the one with a character in it that a
# stripping rule is most likely to eat. `clean` is not repeated here: it survives by the very
# mechanism this world measures, and world 6 of the block above already holds it.
write_r11 "n/a"; commit_r11
f3_phase "n/a survives it too, slash and all" "DOCS"

# Punctuation is not the offence — being nothing BUT a fill-in is. A real sentence that happens to
# end in a full stop is what separates the two, and without it the rule could refuse every
# well-punctuated review in the repo and this block would still be green.
write_r11 "reproduced before the fix, green after it."; commit_r11
f3_phase "a real sentence that ends in punctuation" "DOCS"

if [ "$f3_bad" -eq 0 ]; then
  pass "gate_REVIEW: an unfilled gate field and a punctuated fill-in do not buy an A"
else
  fail "gate_REVIEW: an unfilled gate field and a punctuated fill-in do not buy an A" \
       "the $f3_worlds worlds above agreeing" "$f3_bad disagreement(s), listed above"
fi

# Back to the state the DOCS section inherits: r10 is the latest round again, all Grade A.
rm -f "$MDIR/40-review-r11.md"
git add -A && git commit -qm "chore: drop the r11 fixture" >/dev/null
assert_phase "with the Rationale fixture gone the mission is back at DOCS" "DOCS"

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

# Same formatter, other gate. Here the alignment colons land in the Status COLUMN of the separator
# row, so the skip lets `:---:` through as a Status value and gate_DOCS fails a drift checklist
# with nothing pending in it — the phase refused for a row the author never wrote.
printf '# Docs\n\ndrift checklist\n\n| Area | Doc | Status | Evidence |\n|:------|:----|:------:|:---------|\n| runner | README | ✅ | commit abc1234 |\n| libs | — | n/a | internal refactor |\n\nFindings recorded in TODO.md for this mission.\n' \
  > "$MDIR/45-docs.md"
git add -A && git commit -qm "chore: docs, formatter-aligned"
assert_phase "a formatter-aligned drift checklist is still complete" "PR"
assert_why_absent "gate_DOCS does not read the separator row as a Status" "DOCS" ":---"

# --- the mutation catalogue's stamp -----------------------------------------
#
# Since 4c86712 the catalogue is OPT-IN: TEST_CMD does not run it, and this repo has no CI. That
# left it with no owner, and the bill arrived between PR #12 and PR #13 — a fix rotted the anchor
# of one mutation, every gate ran the fast suite and answered green, and `main` carried a score
# with a live survivor for days, until a human happened to type `sdd health`.
#
# gate_PR does NOT run the catalogue. Holding the working tree for twenty minutes inside a gate is
# precisely what 4c86712 undid, after it made the REVIEW phase unsatisfiable headless. It demands
# the EVIDENCE that the catalogue ran green over THIS content: a stamp `sdd health` writes and
# that nothing else in the kit writes.
#
# EIGHT worlds, in three pairs plus one, and none of them is decoration:
#   SCOPE   (1, 2) the requirement exists only where tests/check-mutation.sh does. World 1 is what
#           keeps every target repo — none of which has that file — behaving exactly as before, and
#           without it worlds 2-6 are all satisfied by a gate that refuses everything.
#   CONTENT (3, 4) the stamp keys on the CONTENT of the measured directories, never on the clock
#           and never on HEAD: the PR phase commits handoff markdown, which would move HEAD and
#           throw away a stamp that is still perfectly valid.
#   MEANING (5, 6, 7) the stamp means the catalogue was GREEN, not that the command ran — and
#           BOTH inputs feed that: a red suite and a green suite whose score carries a survivor
#           each have to take the stamp away. Without them, a `sdd health` that stamped
#           unconditionally satisfies worlds 1-4.
#   WINDOW  (8) the green has to be about the content that is still here. The real catalogue runs
#           for twenty to fifty minutes and the phase that starts it is a phase that commits, so a
#           key read only after the run would stamp whatever the tree happens to be at the end.
#
# The key is NEVER computed here. A second spelling of that algorithm would agree with the first by
# construction and measure nothing, so world 3 drives the real WRITER instead: a LIVE copy of the
# runner inside the fixture, with a stub suite standing in for the twenty-minute catalogue. Live
# for the same reason check-health.sh copies it live — the copy is what carries the sabotage of
# mut_PR_stamp_blind into the fixture, and a runner frozen into this file would make the mutation
# invisible while the catalogue went on crediting protection that does not exist.
#
# ⚠️ The stub's VERDICT lives outside the measured directories, in a control file under .sdd/logs/,
# and that is the whole reason worlds 5-7 measure anything. The first version of this block flipped
# the suite to red by REWRITING tests/run-all.sh — which moved the content key at the same time, so
# the refusal that followed could not tell "the stamp was taken away" from "the content changed".
# Measured, not feared: an adversarial pass that deleted the `catalogue_green` condition entirely
# left this assertion GREEN. The control file changes the answer while every hashed byte stands
# still, which is the only arrangement in which the removal is the sole suspect.
i4_bad=0
# Counted and not written in prose — see the note on i3_worlds above.
i4_worlds=0
i4_home="$SDD_STATE_FIX/health-home"; mkdir -p "$i4_home"
# The size the stand-in catalogue below has to have, READ OFF THE RUNNER and never typed here.
# cmd_health no longer takes the score line's word for the catalogue's size: it weighs the `of N`
# against the mut_*() definitions on disk and refuses anything under its own floor, because
# `score: 0 caught, 0 known gap(s), of 0` used to be stamped as green. So a stand-in that merely
# EXISTS is no longer a kit whose catalogue can be certified — worlds 3, 5 and 7 would be asking
# for a stamp the writer is right to withhold, and this assertion would report a stamp property it
# never got to measure. Derived, so a floor that moves in bin/sdd moves this fixture with it.
I4_FLOOR="$(sed -nE 's/^readonly MUTATION_CATALOGUE_FLOOR=([0-9]+)$/\1/p' "$ROOT/bin/sdd")"
[ -n "$I4_FLOOR" ] \
  || fail "SENSOR-BROKEN: the stamp fixture reads the runner's catalogue floor" \
          "a 'readonly MUTATION_CATALOGUE_FLOOR=<n>' line in bin/sdd" "nothing — the stand-in catalogue below would be sized by an empty string"
I4_SCORE_GREEN="score: $I4_FLOOR caught, 0 known gap(s), of $I4_FLOOR"
I4_SCORE_SURVIVOR="score: $(( I4_FLOOR - 1 )) caught, 0 known gap(s), of $I4_FLOOR"

i4_phase() { # i4_phase <world> <expected phase>
  local world="$1" want="$2" got
  i4_worlds=$((i4_worlds + 1))
  got="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
  [ "$got" = "$want" ] && return 0
  printf '         world "%s": expected phase %s, got %s\n' "$world" "$want" "$got" >&2
  i4_bad=$((i4_bad + 1))
}

i4_why() { # i4_why <world> <regex the reason MUST match> <regex it must NOT match>
  local world="$1" want="$2" absent="$3" got
  got="$( cd "$FIX" && "$SDD" why "$MISSION" PR 2>&1 )"
  if ! grep -qE "$want" <<< "$got"; then
    printf '         world "%s": reason did not match /%s/ — got: %s\n' "$world" "$want" "$got" >&2
    i4_bad=$((i4_bad + 1))
  fi
  # Herestring, never `printf | grep -q` — see the note on assert_why_absent above.
  if grep -qE "$absent" <<< "$got"; then
    printf '         world "%s": reason still carries /%s/, so the gate stopped before the stamp — got: %s\n' \
      "$world" "$absent" "$got" >&2
    i4_bad=$((i4_bad + 1))
  fi
}

# The WRITER, run for real out of the fixture's own copy. HOME is redirected because
# health_provenance reads the skills of whoever is running the suite, and a sensor whose verdict
# depends on the developer's machine is not a sensor. rc is ignored on purpose: the fixture kit has
# no config/schema.md and no baseline, so `sdd health` legitimately fails several other checks —
# what is under test is the stamp, which the command writes right after the catalogue's verdict.
i4_health() { ( cd "$FIX" && HOME="$i4_home" NO_COLOR=1 "$FIX/bin/sdd" health >/dev/null 2>&1 ) || true; }

# What the stub suite will answer next. It is written into .sdd/logs/, which is gitignored AND
# outside the four measured directories — so changing the catalogue's verdict changes not one byte
# of the content key. See the ⚠️ above: that separation is what the assertion rests on.
i4_verdict() { # i4_verdict <exit code> <the score line> [move-the-tree]
  printf '%s\n%s\n%s\n' "$1" "$2" "${3-}" > "$FIX/.sdd/logs/stub-verdict"
}

# The stub suite. Written ONCE, and its bytes never change again: it reads its own verdict from the
# control file above, so tests/ stays fixed across every world below.
#
# The scratch file it can append to lives INSIDE tests/ — so `find` sees it and the content key
# moves — and is gitignored, so the working tree stays clean and the mission does not fall back to
# the REVIEW gate instead of reaching PR. That combination is the whole of world 8.
i4_write_suite() {
  cat > "$FIX/tests/run-all.sh" <<EOF
#!/usr/bin/env bash
# Stub for the twenty-minute catalogue. cmd_health reads the score line off this stdout and the
# suite's verdict off this exit code; both come from a control file OUTSIDE the hashed paths.
sed -n 2p "$FIX/.sdd/logs/stub-verdict"
if [ "\$(sed -n 3p "$FIX/.sdd/logs/stub-verdict")" = move-the-tree ]; then
  printf 'written while the catalogue was running\n' >> "$FIX/tests/scratch.ignored"
fi
exit "\$(sed -n 1p "$FIX/.sdd/logs/stub-verdict")"
EOF
  chmod +x "$FIX/tests/run-all.sh"
}

# gate_PR asks `gh` whether the PR is real, and no test may touch the network.
cat > "$FIX/.stub/gh" <<'STUB'
#!/usr/bin/env bash
# Answers the one question gate_PR asks: `gh pr view <url> --json url --jq .url`.
[ "${1:-}" = "pr" ] && [ "${2:-}" = "view" ] || { echo "unexpected gh call: $*" >&2; exit 9; }
printf '%s\n' "${3:-}"
STUB
chmod +x "$FIX/.stub/gh"
printf -- '---\nfase: PR\npr_url: https://github.com/fixture/repo/pull/1\n---\n# PR\n' > "$MDIR/50-pr.md"
git add -A && git commit -qm "chore: the PR artifact and the gh stub" >/dev/null

# 1. SCOPE — a repo with no catalogue. The gate is exactly the gate it always was, which is the
#    world every target repo lives in.
i4_phase "a repo with no tests/check-mutation.sh closes as it always did" "DONE"

# 2. SCOPE — the catalogue is here and nothing on disk says it ever ran green. Demanding the
#    ABSENCE of the earlier requirements' markers is what proves the gate reached the stamp
#    instead of arriving at the same refusal by the 50-pr.md road.
mkdir -p "$FIX/tests"
{
  cat <<'CAT'
#!/usr/bin/env bash
# Stand-in for the kit's mutation catalogue. Its EXISTENCE is what gate_PR scopes on — the artifact,
# chosen over the identity of the repository because the identity door the kit already has
# (cmd_kaizen) carries a live worktree bug recorded in TODO.md.
#
# The mut_*() lines below are the second thing read of this file, and by the OTHER end of the
# mechanism: cmd_health counts them to decide whether the score line it was handed describes a
# catalogue that could have measured anything. They are generated, one per unit of the runner's own
# floor, so this file stays a coherent kit rather than a catalogue claiming a size nothing backs.
CAT
  i4_n=0
  while [ "$i4_n" -lt "${I4_FLOOR:-0}" ]; do
    printf 'mut_FIXTURE_%d() { :; }\n' "$i4_n"
    i4_n=$(( i4_n + 1 ))
  done
  printf 'exit 0\n'
} > "$FIX/tests/check-mutation.sh"
chmod +x "$FIX/tests/check-mutation.sh"
git add -A && git commit -qm "chore: the repo grows a mutation catalogue" >/dev/null
i4_phase "the catalogue is here and nothing says it ran green" "PR"
i4_why   "no stamp at all" "sdd health" "50-pr\.md|does not confirm"

# 3. CONTENT — the writer runs. From here on the fixture is also a small kit: bin/sdd live, plus a
#    stub suite, which is all cmd_health needs to reach its verdict on the catalogue.
mkdir -p "$FIX/bin" "$FIX/.sdd/logs"
cp "$ROOT/bin/sdd" "$FIX/bin/sdd"
i4_write_suite
printf 'tests/scratch.ignored\n' >> "$FIX/.gitignore"
git add -A && git commit -qm "chore: a kit inside the fixture, so the writer can run" >/dev/null
i4_verdict 0 "$I4_SCORE_GREEN"; i4_health
i4_phase "sdd health over a green catalogue stamps this content" "DONE"

# 3b. CONTENT, the other direction — HEAD moves and the measured content does not. This is the half
#     the block's header CLAIMED and no world measured: keying on `git rev-parse HEAD` would throw
#     the stamp away on the very commit the PR phase makes on its way to this gate, costing a second
#     twenty-to-fifty-minute run per mission for markdown no mutant reads. Measured while this world
#     was missing: with mutation_stamp_key rewritten to hash HEAD, worlds 1-7 all stayed GREEN and
#     only world 8 went red — and world 8's own sentence blames "a tree that moved DURING the run",
#     so the one world that noticed misnamed the cause. Claimed-and-unmeasured is the whole subject
#     of this mission; a sensor is allowed to say only what it tests.
printf '\n<!-- handoff prose: the PR phase commits markdown on its way to this gate -->\n' >> "$MDIR/50-pr.md"
git add -A && git commit -qm "chore: HEAD moves, and not one measured byte with it" >/dev/null
i4_phase "a commit outside the measured directories leaves the stamp standing" "DONE"

# 4. CONTENT — one line into a measured directory and the stamp no longer describes what is here.
#    A stamp keyed on the clock, on HEAD or on nothing at all would still be accepted.
printf '\n# one more line, so the measured content is not the content that was stamped\n' \
  >> "$FIX/tests/check-mutation.sh"
git add -A && git commit -qm "chore: the catalogue changes after the stamp" >/dev/null
i4_phase "a stamped repo whose tests/ moved is unstamped again" "PR"
i4_why   "stale stamp" "sdd health" "50-pr\.md|does not confirm"

# 5. MEANING — stamp the new content, so worlds 6 and 7 have something to take away.
i4_verdict 0 "$I4_SCORE_GREEN"; i4_health
i4_phase "health over the new content stamps it in turn" "DONE"

# 6. MEANING — the SUITE comes back red, over content that did not move by a single byte. The
#    stamp has to go: one that survived would mean "sdd health was executed", which is a label,
#    and the difference between a label and an artifact is the whole mission.
i4_verdict 1 "$I4_SCORE_GREEN"; i4_health
i4_phase "a red suite takes the stamp away, so it never means 'the command ran'" "PR"

# 7. MEANING — and the OTHER input, because the stamp answers to both checks. Here the suite is
#    green and the score carries a live survivor: `103 caught … of 104` is not a hypothesis, it is
#    what this repo's base branch carried for days. The green run in between is not scaffolding
#    either — it proves the removal is a verdict that can be revised and not a one-way latch.
i4_verdict 0 "$I4_SCORE_GREEN"; i4_health
i4_phase "green again, and the stamp comes back" "DONE"
i4_verdict 0 "$I4_SCORE_SURVIVOR"; i4_health
i4_phase "a score with a live survivor takes the stamp away too" "PR"

# 8. WINDOW — the catalogue is green AND the measured tree moves while it runs. The real run takes
#    twenty to fifty minutes, and the phase that types `sdd health` is the phase that also commits,
#    so this is the widest window in the kit for a tree to shift under a measurement. A key read
#    only AFTER the run would describe exactly what is on disk when the command ends, so the stamp
#    would fit, the gate would open, and the green would belong to content that was never measured.
#    The world distinguishes on its own, whatever the stamp state before it: unfixed, the stamp is
#    written and the phase is DONE.
i4_verdict 0 "$I4_SCORE_GREEN" move-the-tree; i4_health
i4_phase "a tree that moved DURING the run is not stamped by the green it did not take part in" "PR"

if [ "$i4_bad" -eq 0 ]; then
  pass "gate_PR: the mutation stamp is demanded only where the catalogue lives"
else
  fail "gate_PR: the mutation stamp is demanded only where the catalogue lives" \
       "the $i4_worlds worlds above agreeing" "$i4_bad disagreement(s), listed above"
fi

# --- the two ends of the stamp, and the tree they have to agree on ----------
#
# The block above proves WHAT the stamp means. This one proves WHERE it lives, which is a separate
# property and the one the writer got wrong. cmd_health stamped $SDD_HOME — the tree the running
# bin/sdd sits in — while gate_PR scopes, keys and reads under $REPO_ROOT, the git toplevel of the
# working directory. Those are the same tree only when the kit is invoked out of the very checkout
# being worked on. Put `sdd` on the PATH, which README.md documents as the install, then stand in a
# worktree or a second clone of the kit: the writer answers about one tree and the reader asks
# about the other, so nothing ever stamps the tree the gate is asking about. gate_PR is then
# unsatisfiable FOREVER, and the remedy its own sentence names re-measures the wrong tree at twenty
# to fifty minutes a lap — a refusal with no reachable remedy, which is worse than the label it
# replaced.
#
# Every world of the block above invokes "$FIX/bin/sdd" from inside $FIX, so SDD_HOME == REPO_ROOT
# holds by construction in all eight and none of them can see this. The three below are the worlds
# where the two DIVERGE: a second kit, living outside the fixture and never the working directory,
# is the one whose bin/sdd runs.
#
# THREE worlds, and the last two are not decoration — they are the half that says the answer is
# "the tree the gate measures", not "always the working directory". A cmd_health that simply
# followed the cwd would leave every target repo, and every operator standing outside a git
# checkout, with no stamped kit at all.
tree_bad=0
tree_worlds=0
tree_note() { # tree_note <world> <what disagreed>
  printf '         world "%s": %s\n' "$1" "$2" >&2
  tree_bad=$((tree_bad + 1))
}
TREE_STAMP=".sdd/logs/mutation-stamp"
tree_stamped() { [ -f "$1/$TREE_STAMP" ]; }

# The INSTALLED kit: a second checkout, outside the fixture, whose bin/sdd is the one on the PATH.
# It carries a catalogue and a stub suite of its own, so that a `sdd health` which measures THIS
# tree can still reach a verdict without the twenty-minute run — otherwise worlds 2 and 3 would be
# measuring an absent suite instead of the fallback.
TREE_KIT="$SDD_STATE_FIX/kit-install"
mkdir -p "$TREE_KIT/bin" "$TREE_KIT/tests" "$TREE_KIT/.sdd/logs"
cp "$ROOT/bin/sdd" "$TREE_KIT/bin/sdd"
cat > "$TREE_KIT/tests/run-all.sh" <<EOF
#!/usr/bin/env bash
# Stub for the installed kit's own catalogue: always green, always this score.
printf '%s\n' "$I4_SCORE_GREEN"
EOF
chmod +x "$TREE_KIT/tests/run-all.sh"
{
  printf '#!/usr/bin/env bash\n'
  # Sized off the runner's floor, for the reason I4_FLOOR spells out above: a catalogue under it is
  # one cmd_health is right to refuse, and worlds 2 and 3 would then be asking for a stamp that no
  # correct writer would ever produce.
  tree_n=0
  while [ "$tree_n" -lt "${I4_FLOOR:-0}" ]; do
    printf 'mut_INSTALL_%d() { :; }\n' "$tree_n"
    tree_n=$(( tree_n + 1 ))
  done
  printf 'exit 0\n'
} > "$TREE_KIT/tests/check-mutation.sh"
chmod +x "$TREE_KIT/tests/check-mutation.sh"

# A plain git repo with no catalogue: the world every target repo of the kit lives in.
TREE_PLAIN="$SDD_STATE_FIX/plain-repo"
mkdir -p "$TREE_PLAIN"
( cd "$TREE_PLAIN" && git init -q -b main ) >/dev/null 2>&1

# Runs the INSTALLED kit's health from <cwd>, after taking every stamp away — so what is on disk
# afterwards was written by THIS run and never inherited from the block above.
tree_health() { # tree_health <cwd>
  # One call, one world — counted here for the reason the note on i3_worlds gives.
  tree_worlds=$((tree_worlds + 1))
  rm -f "$FIX/$TREE_STAMP" "$TREE_KIT/$TREE_STAMP" "$TREE_PLAIN/$TREE_STAMP"
  ( cd "$1" && HOME="$i4_home" NO_COLOR=1 "$TREE_KIT/bin/sdd" health >/dev/null 2>&1 ) || true
}

# The control file still says `move-the-tree` from world 8, and a run that moves the tree is right
# to stamp nothing at all — which would make every world below pass for the wrong reason.
i4_verdict 0 "$I4_SCORE_GREEN"

# 1. The kit runs from the PATH while the working directory is a kit worktree. The tree the gate
#    measures is $FIX; the tree the runner's own file sits in is $TREE_KIT. Only one of them can be
#    the one that gets stamped, and it has to be the one the gate reads.
tree_health "$FIX"
tree_stamped "$FIX" \
  || tree_note "sdd from the PATH, standing in a kit worktree" \
               "the tree gate_PR measures was not stamped — the gate has no reachable remedy"
tree_stamped "$TREE_KIT" \
  && tree_note "sdd from the PATH, standing in a kit worktree" \
               "the installed kit was stamped instead, and it is not the tree the gate asks about"
tree_got="$( cd "$FIX" && "$SDD" phase "$MISSION" 2>&1 )"
[ "$tree_got" = "DONE" ] \
  || tree_note "sdd from the PATH, standing in a kit worktree" \
               "expected phase DONE after health, got $tree_got"

# 2. The same install, standing in a repo with no catalogue — a target repo. The kit itself is what
#    gets measured and stamped, exactly as before, and the target repo is left alone: it has no
#    catalogue, so gate_PR asks it for nothing and a stamp there would certify a tree nobody ran.
tree_health "$TREE_PLAIN"
tree_stamped "$TREE_KIT" \
  || tree_note "sdd from the PATH, standing in a target repo" \
               "the installed kit was not stamped — the fallback every target repo depends on is gone"
tree_stamped "$TREE_PLAIN" \
  && tree_note "sdd from the PATH, standing in a target repo" \
               "the target repo was stamped, and nothing ever measured it"

# 3. And the other half of that fallback: no git repository at all under the working directory.
#    A resolution that read the cwd without asking whether it is a kit would stamp nothing here.
tree_health "$TREE_KIT"
tree_stamped "$TREE_KIT" \
  || tree_note "sdd invoked from outside any git repository" \
               "the installed kit was not stamped, so health has no tree to measure at all"

if [ "$tree_bad" -eq 0 ]; then
  pass "gate_PR: the stamp is read from the tree whose content the gate measures"
else
  fail "gate_PR: the stamp is read from the tree whose content the gate measures" \
       "the $tree_worlds worlds above agreeing" "$tree_bad disagreement(s), listed above"
fi

# Back to the state the sections below inherit: no catalogue, no kit copy, no PR artifact — the
# fixture is a plain target repo again, sitting at PR with 50-pr.md missing.
# `${FIX:?}` and not `$FIX`: with the fixture variable empty this line is `rm -rf /bin /tests` on
# the machine of whoever ran the suite. The same family check-health.sh records in its own header,
# where an unguarded `rm -rf` reached `/kit` for real.
rm -rf "${FIX:?}/bin" "${FIX:?}/tests" "${FIX:?}/.stub/gh" "${MDIR:?}/50-pr.md" "${FIX:?}/.sdd/logs/mutation-stamp"
git add -A && git commit -qm "chore: drop the stamp fixture" >/dev/null
assert_phase "with the stamp fixture gone the mission is back at PR" "PR"
assert_why   "and back to the reason it had before" "PR" "50-pr.md"

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

# --- 3a. and it stops sending the human to a gate that is still shut.
#
# `cmd_approve` asked gate_PLAN ONCE, at the top, and bailed only on `missing *`. Every other
# reason the gate can hold — and it can hold several that approving does not touch — was carried
# straight past the commit into `next: sdd run`. The reproduction is literally the pilot's config:
# JIRA_ENABLED=true with `versao:` still a placeholder. Approve writes the approval, commits, says
# "next: sdd run", and the very next `sdd why` refuses for `versao:`. Every new reason gate_PLAN
# learns inherits the defect for free, which is why the fix re-ASKS the gate instead of adding a
# second condition here.
#
# DIFFERENTIAL, and it has to be: an "improvement" that simply deleted the `next:` line would satisfy
# the shut half and break nothing else in this file. The two outputs are compared against each other
# — the same command, one gate open and one shut — so neither arm can be reached by accident.
SHUT="20260103-approve-shut"
SHUTDIR="$FIX/docs/handoffs/$SHUT"
mkdir -p "$SHUTDIR"
cat > "$SHUTDIR/00-missao.md" <<'EOF'
---
missao: 20260103-approve-shut
titulo: the gate holds for a reason approving does not touch
data: 2026-01-03
versao: <versao>
branch: missao/20260103-approve-shut
aprovacao:
ddd: n/a
---

# Mission fixture
EOF
printf '# Plano
' > "$SHUTDIR/01-plano.md"
cat > "$SHUTDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
EOF
sed -i 's/^JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
SHUT_OUT="$( cd "$FIX" && "$SDD" approve "$SHUT" 2>&1 <<< "y" )"; SHUT_RC=$?
SHUT_LINE="$(grep -m1 '^aprovacao:' "$SHUTDIR/00-missao.md")"
SHUT_WHY="$( cd "$FIX" && "$SDD" why "$SHUT" 2>&1 )"
sed -i 's/^JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh

# Composed into one string so the red names which term went wrong. Four terms, and each is a
# different way the fix could be wrong: the approval still has to be WRITTEN (a fix that refused to
# approve would be worse than the bug), the next step must be absent, the gate's own reason must be
# on screen, and the OPEN case must still print the next step.
shut_got="$(printf 'rc=%s written=%s next=%s reason=%s open_still_says_next=%s' \
  "$SHUT_RC" \
  "$([ -n "$SHUT_LINE" ] && [[ $SHUT_LINE == aprovacao:\ humano-* ]] && echo yes || echo NO)" \
  "$(grep -q "next: sdd run" <<< "$SHUT_OUT" && echo printed || echo absent)" \
  "$(grep -q "versao:" <<< "$SHUT_OUT" && echo named || echo MISSING)" \
  "$(grep -q "next: sdd run" <<< "$APPROVE_Y_OUT" && echo yes || echo NO)")"
assert_eq "approve with the gate still shut prints the gate's reason, not 'next: sdd run'" \
  "rc=0 written=yes next=absent reason=named open_still_says_next=yes" "$shut_got"
# The floor under the whole block: the reason really is one approving cannot fix, so the arm being
# measured is the arm the comment names. Read from `sdd why`, the reader that owns the question.
assert_eq "and the reason really is one approving does not touch" \
  "versao" "$(grep -qF 'versao' <<< "$SHUT_WHY" && printf 'versao')"
# Swept, and not left for a later `git add -A` to adopt. `cmd_approve` stages only the mission file
# it wrote, so the plan and the checkpoint below would ride into the next fixture commit as
# untracked strays — a fixture leaking into the state a later block measures.
rm -rf "$SHUTDIR"

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

# --- sdd close: the artifact decides, never the exit code ------------------
# `cmd_close` printed `ok <issue> closed` off `[ "$rc" -eq 0 ]` — the exit code of the session it
# had just asked to close the issue. That rc is SHARED between two branches: the session that
# closed the issue exits 0, and so does the session that only ASKED whether to close it. Measured
# on 2026-08-25 in the M2 pilot — `ok SQ-108 closed` printed over an issue sitting in "Em
# andamento". It is the shape principle 1 of CLAUDE.md refuses (gate = artifact, never label), and
# the pattern that is right is one screen up in gate_PR, which re-reads the live PR.
#
# The nine regimes below are DIFFERENTIAL pairs: each demands the text of the branch it is in AND
# the absence of the other branch's marker. A message that carried both would satisfy either half
# alone, which is how an assertion stops distinguishing anything.
#
# `session-spent` is a term of most of them and not decoration. The verification query is also the
# PRE-CHECK, so where it runs decides whether a verdict this command cannot reach costs a paid
# session: an assertion that only read the rc would be equally green with the whole check moved
# below the session, which is the shape the first round of this work shipped.
#
# They run LAST on purpose — the claude stub planted at the top of this file exists to turn any
# real session into a loud failure, and this block has to replace it with one that answers. The
# fixture is put BACK at the end of the block rather than left mutated, so "runs last" stops being
# a load-bearing assumption a future author can break silently by appending below.
echo "== sdd close: the artifact decides =="

CLOSE_CTL="$FIX/.sdd/logs/close-ctl"           # the acli stub's answers, one per invocation
CLOSE_MARK="$FIX/.sdd/logs/close-session-ran"  # the claude stub's marker: a session WAS spent
CLOSE_RCFILE="$FIX/.sdd/logs/close-session-rc" # what the claude stub exits with
CLOSE_ACLI_LOG="$FIX/.sdd/logs/close-acli-calls"
CLOSE_JOURNAL="$FIX/.sdd/logs/$MISSION/pipeline.log"
mkdir -p "$FIX/.sdd/logs/$MISSION"

# The close session, reproduced: it spends a session, leaves a marker so "was a session spent?" is
# ASSERTED and not assumed, exits with whatever the control file says — and never closes anything.
cat > "$FIX/.stub/claude" <<STUB
#!/usr/bin/env bash
: > "$CLOSE_MARK"
exit "\$(cat "$CLOSE_RCFILE" 2>/dev/null || echo 0)"
STUB
chmod +x "$FIX/.stub/claude"

# cmd_close asks `gh` exactly one thing before it spends anything: is the PR merged?
cat > "$FIX/.stub/gh" <<'STUB'
#!/usr/bin/env bash
[ "${1:-}" = "pr" ] && [ "${2:-}" = "view" ] || { echo "unexpected gh call: $*" >&2; exit 9; }
printf 'MERGED\n'
STUB
chmod +x "$FIX/.stub/gh"

# PROVENANCE — every byte below is stdout captured live on 2026-08-25 from the real Jira this repo
# tickets against, never written from memory (CLAUDE.md: a fixture and the gate that reads it
# written by the same hand agree with each other instead of measuring anything):
#
#   acli jira workitem search --jql "key = SQ-108 AND statusCategory = Done" \
#        --fields "key,status" --json
#
# `done` is that command's stdout for a CLOSED issue — which is why the fixture mission carries the
# real key SQ-108: renaming it to something tidier would make this a fixture written from memory.
# `notdone` is the same command against an OPEN issue (SQ-98): `[]`, and **rc 0 in both cases** —
# the exit code discriminates nothing, and the SHAPE of the answer is the only witness there is.
#
# The captured bytes live in tests/fixtures/ rather than in a heredoc here, and that is not tidying:
# a Jira status name is LOCALIZED — this instance answers in pt-BR — so inlining it would put
# Portuguese into a file check-lang.sh scans as English kit surface — and the only ways out of that
# would be to edit the capture until the scan goes quiet, which is a fixture written from memory
# wearing a fixture's clothes. tests/fixtures/ is captured third-party DATA, never kit logic; the
# header of check-lang.sh names the category.
#
# DECLARED LIMIT, because this is the fourth third-party fixture in the kit and the first with no
# drift sensor: `health_provenance` pins the other three against the skill file each was captured
# from, and there is no installed file to diff a CLI's stdout against. If acli renames `key` or
# moves it under `fields`, `close_query`'s `.[]?.key` stops matching, `sdd close` answers "still
# open" over every real close, and every regime below stays green on the frozen bytes. What IS
# pinned here is the shape the runner depends on — the assertion right below — so a fixture edited
# until the tests pass fails instead. Re-capture with the command above when acli majors.
cp "$ROOT/tests/fixtures/acli-workitem-search-done.json" "$FIX/.stub/acli-done.json"
assert_eq "close: the captured acli fixture still has the shape close_query reads" \
  "array:true key:SQ-108 status:1" \
  "array:$(jq -r 'type == "array"' "$FIX/.stub/acli-done.json") key:$(jq -r '.[0].key' "$FIX/.stub/acli-done.json") status:$(jq -r '[.[0].fields.status.statusCategory.key == "done"] | length' "$FIX/.stub/acli-done.json")"

# Same provenance, same day: the failure text, captured by pointing HOME at an empty directory so
# the tool had no credentials. It came back on **rc 1** — the plan for this work had assumed rc 0,
# and the live probe said otherwise. Both are exercised below and the reason is structural: the
# runner captures with `|| true`, so a non-JSON answer arriving with a success rc is a world the
# code manufactures for itself no matter which code the tool actually picked.
printf '%s\n' "✗ Error: unauthorized: use 'acli [product] auth login' to authenticate" \
  > "$FIX/.stub/acli-unauth.txt"

# One verdict per INVOCATION, and the sequence is the whole point: `cmd_close` asks twice — once
# before the session and once after — and the two answers have to be settable independently or the
# regimes cannot tell "refused before spending anything" from "asked, spent, then refused". Runs
# past the end of the list repeat the last line, so a one-word sequence still means "always this".
cat > "$FIX/.stub/acli" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CLOSE_ACLI_LOG"
n=\$(wc -l < "$CLOSE_ACLI_LOG")
v="\$(sed -n "\${n}p" "$CLOSE_CTL" 2>/dev/null)"
[ -n "\$v" ] || v="\$(tail -1 "$CLOSE_CTL" 2>/dev/null)"
case "\$v" in
  done)    cat "$FIX/.stub/acli-done.json" ;;
  notdone) printf '[]\n' ;;
  error0)  cat "$FIX/.stub/acli-unauth.txt"; exit 0 ;;
  *)       cat "$FIX/.stub/acli-unauth.txt"; exit 1 ;;
esac
STUB
chmod +x "$FIX/.stub/acli"

CLOSE_ISSUE="SQ-108"
printf -- '---\nfase: TICKET\nissue: %s\n---\n# TICKET\n' "$CLOSE_ISSUE" > "$MDIR/10-ticket.md"
printf -- '---\nfase: PR\npr_url: https://github.com/fixture/repo/pull/1\n---\n# PR\n' > "$MDIR/50-pr.md"
sed -i 's/^JIRA_ENABLED=false$/JIRA_ENABLED=true/' "$FIX/.sdd/config.sh"

# has <text> <ERE> -> 1|0. A term of a composed assertion, so a red names WHICH half moved instead
# of only reporting that something did.
has() { if grep -qE "$2" <<< "$1"; then printf 1; else printf 0; fi }
spent() { if [ -e "$CLOSE_MARK" ]; then printf 1; else printf 0; fi }
acli_calls() { if [ -e "$CLOSE_ACLI_LOG" ]; then wc -l < "$CLOSE_ACLI_LOG" | tr -d ' '; else printf 0; fi }

# close_run <acli verdict sequence, space-separated> <session rc> — CALLED, never substituted: it
# publishes its results in globals, and a `$(close_run …)` would run it in a subshell where every
# one of those assignments dies with the substitution. That is a scar this repo already carries
# (CLAUDE.md, the one-shot guard of autonomy_kit_stamp), and it is why the two outputs come back as
# CLOSE_RC_OUT/CLOSE_OUT.
CLOSE_RC_OUT=0
CLOSE_OUT=""
close_run() {
  rm -f "$CLOSE_MARK" "$CLOSE_ACLI_LOG" "$CLOSE_JOURNAL"
  # Herestring into `tr`, never `printf … | tr`: this file runs under `pipefail`, where the pipe
  # form is the family check-pipefail.sh exists to keep out.
  tr ' ' '\n' <<< "$1" > "$CLOSE_CTL"
  printf '%s\n' "$2" > "$CLOSE_RCFILE"
  CLOSE_RC_OUT=0
  CLOSE_OUT="$( cd "$FIX" && "$SDD" close "$MISSION" 2>&1 )" || CLOSE_RC_OUT=$?
}

# 1. No acli on the machine. Fail-closed and BEFORE the session: a verdict this command cannot
#    reach is not a reason to spend a budget first and then admit it. `session-spent:0` is the
#    whole point of the regime — without it the guard could sit after the session and still pass.
rm -f "$CLOSE_MARK" "$CLOSE_ACLI_LOG"
printf 'done\n' > "$CLOSE_CTL"
printf '0\n' > "$CLOSE_RCFILE"
C1_RC=0
C1_OUT="$( cd "$FIX" && SDD_ACLI_BIN=/nonexistent/acli "$SDD" close "$MISSION" 2>&1 )" || C1_RC=$?
assert_eq "close: with no acli reachable it fails before spending a session, and says what to run by hand" \
  "rc:1 acli:1 jql:1 auth:1 session-spent:0" \
  "rc:$C1_RC acli:$(has "$C1_OUT" 'acli') jql:$(has "$C1_OUT" 'statusCategory = Done') auth:$(has "$C1_OUT" 'auth') session-spent:$(spent)"

# 2. The pre-check sits BELOW the JIRA gate, and only this regime says so. Regime 9 cannot: it
#    leaves acli reachable, so a pre-check lifted above `JIRA_ENABLED` would still find one and
#    stay quiet. Measured on 2026-08-25 by lifting it: every close regime stayed green while
#    `sdd close` began dying with rc 1 on every JIRA-less repo with no acli installed — a repo that
#    tickets nothing has no business needing a Jira CLI.
sed -i 's/^JIRA_ENABLED=true$/JIRA_ENABLED=false/' "$FIX/.sdd/config.sh"
rm -f "$CLOSE_MARK" "$CLOSE_ACLI_LOG"
C2_RC=0
C2_OUT="$( cd "$FIX" && SDD_ACLI_BIN=/nonexistent/acli "$SDD" close "$MISSION" 2>&1 )" || C2_RC=$?
assert_eq "close: with JIRA off an absent acli is nobody's business — the pre-check is below the gate" \
  "rc:0 nothing:1 acli-error:0 session-spent:0" \
  "rc:$C2_RC nothing:$(has "$C2_OUT" 'nothing to close') acli-error:$(has "$C2_OUT" 'cannot reach') session-spent:$(spent)"
sed -i 's/^JIRA_ENABLED=false$/JIRA_ENABLED=true/' "$FIX/.sdd/config.sh"

# 3. THE INCIDENT. The session exits 0 having only asked for confirmation; the issue is still open.
close_run "notdone notdone" 0
assert_eq "close: a session that exits 0 having only ASKED does not get to call the issue closed" \
  "rc:1 confirms:0 refuses:1 session-spent:1 journal:1" \
  "rc:$CLOSE_RC_OUT confirms:$(has "$CLOSE_OUT" 'JIRA confirms') refuses:$(has "$CLOSE_OUT" 'does not confirm') session-spent:$(spent) journal:$(has "$(cat "$CLOSE_JOURNAL" 2>/dev/null || true)" 'verified=false')"

# 4. Confirmed by the issue itself — open before the session, Done after it.
close_run "notdone done" 0
assert_eq "close: with the issue actually Done it says closed, and the journal records what confirmed it" \
  "rc:0 confirms:1 refuses:0 session-spent:1 journal:1" \
  "rc:$CLOSE_RC_OUT confirms:$(has "$CLOSE_OUT" 'JIRA confirms') refuses:$(has "$CLOSE_OUT" 'does not confirm') session-spent:$(spent) journal:$(has "$(cat "$CLOSE_JOURNAL" 2>/dev/null || true)" 'verified=true')"

# 5. The artifact outranks the exit code in BOTH directions — a session that fell over after
#    closing the issue closed the issue. Without this regime the fix could be "trust rc AND the
#    JQL", which is a second label added to the first rather than the artifact deciding.
close_run "notdone done" 1
assert_eq "close: a session that failed but left the issue Done is a close, and the rc is reported not obeyed" \
  "rc:0 confirms:1 refuses:0 rc-shown:1" \
  "rc:$CLOSE_RC_OUT confirms:$(has "$CLOSE_OUT" 'JIRA confirms') refuses:$(has "$CLOSE_OUT" 'does not confirm') rc-shown:$(has "$CLOSE_OUT" 'exited 1')"

# 6. Prose where JSON was expected, under BOTH exit codes — the expired-auth world the fixture in
#    .stub/acli-unauth.txt was captured from. It is refused at the PRE-CHECK, so `session-spent:0`
#    is the term that matters: `command -v` cannot see expired auth, so a pre-check that only asked
#    whether the binary exists spent the whole budget on the one unreachable case that happens.
close_run "error1" 0
C6_RC1="$CLOSE_RC_OUT"; C6_OUT1="$CLOSE_OUT"; C6_SPENT1="$(spent)"
close_run "error0" 0
assert_eq "close: an acli answering prose is refused BEFORE the session, whichever exit code it picks" \
  "rc1:1 json1:1 confirms1:0 spent1:0 rc0:1 json0:1 confirms0:0 spent0:0" \
  "rc1:$C6_RC1 json1:$(has "$C6_OUT1" 'did not answer JSON') confirms1:$(has "$C6_OUT1" 'JIRA confirms') spent1:$C6_SPENT1 rc0:$CLOSE_RC_OUT json0:$(has "$CLOSE_OUT" 'did not answer JSON') confirms0:$(has "$CLOSE_OUT" 'JIRA confirms') spent0:$(spent)"

# 7. Reachable before the session, gone after it — auth expiring mid-session is the ordinary way.
#    THREE outcomes, not two: "I asked and JIRA said no" and "I could not ask" both fall closed, but
#    a human told the session merely asked for confirmation goes and reads the wrong log. The
#    `still-open:0` term is the half that makes this regime distinguish anything.
close_run "notdone error1" 0
assert_eq "close: acli that dies after the session is UNVERIFIED, not 'the session only asked'" \
  "rc:1 unverified:1 still-open:0 confirms:0 session-spent:1 journal:1" \
  "rc:$CLOSE_RC_OUT unverified:$(has "$CLOSE_OUT" 'UNVERIFIED') still-open:$(has "$CLOSE_OUT" 'is still open') confirms:$(has "$CLOSE_OUT" 'JIRA confirms') session-spent:$(spent) journal:$(has "$(cat "$CLOSE_JOURNAL" 2>/dev/null || true)" 'reachable=false')"

# 8. Already Done before anything is spent. The pre-check is the verification query, so this costs
#    ONE acli call and no session — it used to cost a whole one to learn the issue was shut. The
#    `acli-calls:1` term is what pins that: a second call would mean the query ran after a session
#    that this regime says never happened.
close_run "done" 0
assert_eq "close: an issue already Done is confirmed without spending a session at all" \
  "rc:0 already:1 confirms:1 session-spent:0 acli-calls:1 journal:1" \
  "rc:$CLOSE_RC_OUT already:$(has "$CLOSE_OUT" 'already Done') confirms:$(has "$CLOSE_OUT" 'JIRA confirms') session-spent:$(spent) acli-calls:$(acli_calls) journal:$(has "$(cat "$CLOSE_JOURNAL" 2>/dev/null || true)" 'session=none')"

# 9. Control. With JIRA off the command asks nothing of anyone — and the two `:0` terms are the
#    half that matters: a guard that ran acli anyway would still print "nothing to close".
sed -i 's/^JIRA_ENABLED=true$/JIRA_ENABLED=false/' "$FIX/.sdd/config.sh"
rm -f "$CLOSE_MARK" "$CLOSE_ACLI_LOG"
C9_RC=0
C9_OUT="$( cd "$FIX" && "$SDD" close "$MISSION" 2>&1 )" || C9_RC=$?
assert_eq "close: with JIRA off nothing is asked of anyone — no session, no acli, no verdict" \
  "rc:0 nothing:1 session-spent:0 acli-calls:0" \
  "rc:$C9_RC nothing:$(has "$C9_OUT" 'nothing to close') session-spent:$(spent) acli-calls:$(acli_calls)"

# The fixture goes back the way it was found. "This block runs last" was the previous version's
# only defence, and it is not one a sensor can hold: a future author appending below would inherit
# a `gh` that answers MERGED to everything and a `claude` that returns success without doing
# anything, and would never see why their new assertion passed. Restoring costs four lines.
rm -f "$MDIR/10-ticket.md" "$MDIR/50-pr.md" "$FIX/.stub/gh" "$FIX/.stub/acli" "$CLOSE_JOURNAL"
cat > "$FIX/.stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude — the escalation path did not escape before the session" >&2
exit 97
STUB
chmod +x "$FIX/.stub/claude"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then
  echo "state machine correct"
  exit 0
fi
echo "$fails assertion(s) failed" >&2
exit 1
