#!/usr/bin/env bash
# Sensor for the campaign worker — `bin/sdd-worker` answers from artifacts (ADR 0022).
#
# What it measures. The worker is a session that orchestrates a campaign under a delegation the
# owner signed, and the questions that decide its acts (does the delegation hold? does this act fit
# the level? what comes next? did a ceiling blow? is this pull request ready on this sha?) are
# answered by the verbs of bin/sdd-worker, never by the session's reading. Each verb is measured
# here over fixtures, and each rule carries a mutant `mut_WORKER_*` in tests/check-mutation.sh: a
# sabotaged verb has to turn this file red, or the assertion is decoration.
#
# Rules, each with a probe below:
#   R1  no verb, and a verb the program does not know, print the usage on stderr and leave rc 2 —
#       never a silent rc 0 that a caller would read as an answer
#   R2  `delegate` signs on a yes, and only on one: it writes `signed: <instant> <digest>`, where the
#       digest is the first 12 hex of the sha256 of the six other keys and of the ceiling of each lot
#       of the campaign.md beside it (computed HERE, independently of the program), and it touches no
#       other line of the file
#   R3  `delegate` with no character on stdin is rc 66 and writes nothing — nobody was asked, which
#       is not the same as a no (the contract of `sdd approve`)
#   R4  `delegate` signs nothing on a no, nor — with a yes on stdin — on a delegation that already
#       expired, one whose level is off the ladder, one with a ceiling missing, one with an empty
#       key (`lots:`), an instant that is not one, or a ceiling that is not a number; those are
#       refused before the question (rc 1), the no is an answer (rc 0)
#   R5  `level` answers, for a delegation the program itself signed, the level it was signed at —
#       each of the five, with `signed until <expires>` as the reason
#   R6  `level` answers assisted, naming its branch, for no delegation, an illegible one (the
#       template itself), an unsigned one and an expired one; expiry holds on both sides of the
#       SDD_WORKER_NOW seam, which moves time forward and never brings a delegation back; a
#       directory that is not there is a usage error, not an answer
#   R7  `level` answers assisted when any of the six keys, or the digest, changed after signing; a
#       line of prose in the body changes nothing, since only the frontmatter is read
#   R8  a near miss of a level name (a capital, a prefix, a word past the top, two levels, a glob)
#       is not a level: in `level:` the delegation is illegible, in a lot's Ceiling the lot is
#       capped at assisted
#   R9  above assisted, a campaign whose repo sets no ON_ESCALATION_CMD (empty, or no config, even
#       under a caller that exports one: the runner does not run without the file) is assisted —
#       the same signed file answers merge where the pager is set; the config read is the
#       campaign's repo (its checkout and the worktrees that hold a mission of it, R44), never the
#       cwd
#   R10 with --lot, a ceiling below the signed level lowers it and one above never raises it; a lot
#       outside `lots:`, or with no row in the table, is assisted; a --lot with no lot is rc 2
#   R11 `allows`, over a delegation signed at each of the five levels, answers the table of acts of
#       the mission plan (kept HERE, never read from the program) in every one of the 35 cells, on
#       a lot with no ceiling (every act is asked with --lot, R39):
#       `allowed <act> at <level>` with rc 0, or `ask <act> needs <floor>, effective <level> — …`
#       with rc 1
#   R12 a word the table does not name — a near miss of an act, a level's name, an entry of the
#       table as written, nothing — is rc 2 with nothing on stdout, under a full delegation where
#       every act is allowed; so is a call of the wrong shape
#   R13 a delegation that does not hold (absent, illegible, unsigned, expired, edited after signing,
#       no pager) asks the owner for every act, naming the reason of its branch; the signed ones are
#       first witnessed allowing approve, so the ask is the break's and nothing else's
#   R14 with --lot, the lot's ceiling is the act's: under full, approve is asked on a lot capped at
#       merge and allowed on the lots that are not, and a lot with no row asks for it
#   R15 `budget` sums the cost_usd of the ledger lines whose mission is one of the campaign's — the
#       folders under the repo's HANDOFF_DIR whose 00-missao.md declares exactly that campaign:, in
#       the checkout of the campaign AND in every linked worktree of its repo, each mission once —
#       and no other line: not another campaign's, not a longer id's, not a mission of no campaign;
#       a malformed line costs only itself; the ledger is found by SDD_STATE_DIR, else under $HOME
#   R16 at the campaign ceiling or above it `budget` leaves rc 1, and below it rc 0, the comparison
#       being numeric (10 is above 8.5); so do the answers it cannot have — no delegation or an
#       illegible one (no ceiling), a directory outside a git checkout, a ledger that does not read
#       (and a worktree list that does not run, R50)
#   R17 a missing or empty ledger is zero spent (rc 0), and the line prints the mission cap of the
#       delegation as signed, the one the worker passes to `sdd run` as BUDGET_MISSION_USD
#   R18 `next` plans a lot no mission of the campaign declares (another campaign's mission on the
#       lot, or this campaign's on another lot, is not it), and approves a mission whose aprovacao:
#       the runner's gate does not admit — empty, the template's placeholder, or empty in one copy
#   R19 an approved mission with no pull request is run, found also when it lives only in a linked
#       worktree (in flight); an open pull request is reviewed, a closed one beside it changing
#       nothing; `auto` is approved as `humano-…` is
#   R20 a lot with a merged pull request is skipped, and a queue whose every lot is merged is done;
#       the queue is the table under `## Lotes` and nothing after it; the stub answers like the real
#       gh, so a call without --state all reads no merged pull request
#   R21 the line `ahead plan <lot>` follows a run or a review when the lot after the deciding one has
#       no mission, and never otherwise
#   R22 a gh that fails, or answers anything but an array of {number, state} with a known state, is
#       rc 3 with no act on stdout — never "no pull request"; a pull request closed without merge,
#       two missions on one lot, an approved mission with no branch, no campaign.md and an empty
#       queue stop (rc 1); a call of the wrong shape is rc 2. gh runs at the repo root, or the stub
#       refuses it
#   R23 `pr-ready` answers `ready <the full head sha>` when the five items hold on one sha: the
#       newest round (by number: r10 after an r9 graded B) grades A in every row, the bold Overall
#       one included, and names a reviewed head after which only the mission folder changed — a file
#       whose name git quotes by default among them, and the commit right under the round's when it
#       names that; each world's rounds committed, as R46 requires; the newest receipt of the Codex
#       bot is for that sha, completed, with no unresolved
#       finding, and it is on the second page, so the comments are read with --paginate; every review
#       thread is resolved; the pull request is open and mergeable; the local HEAD is the head
#   R24 the review item fails for a grade other than A (B in a strict row, in an indented one, A- in
#       the bold Overall one), a newest round that names no head, or names HEAD, or a sha that is no
#       commit, a change outside the mission folder after the reviewed head — a move into the folder
#       included, so renames are not followed —, a pull request head this checkout does not have (the
#       ancestry is what does not run), no
#       round, a round with no grade table, the root of the checkout given as the mission folder, and
#       a folder outside any git checkout; an older round graded A beside the newest changes nothing
#   R25 the codex item fails for a receipt for another sha, one not completed, one with an unresolved
#       finding or a null for it, no receipt at all, a newest receipt whose state does not parse (an
#       older good one is never read in its place, R48), and a receipt for the head posted by somebody
#       other than the bot — anybody can comment on a public repo; the receipt is the real one of PR
#       409
#   R26 the threads item fails for one unresolved thread, and for more threads than the hundred read
#   R27 the mergeable item fails for a conflicting pull request, a closed one GitHub calls
#       mergeable, and a merged one (the answer of PR 409, copied)
#   R28 the head item fails for a local HEAD ahead of the pull request head, and for one behind it
#   R29 a gh that fails — before answering, or after printing a full answer — or answers off its
#       contract, on the pull request, the repo, the comments or the threads, is rc 3 with nothing on
#       stdout and the call named on stderr: never ready, and never a not-ready a caller would set out
#       to fix; a call of the wrong shape is rc 2
#   R30 commands/sdd-worker.md writes a call of every verb bin/sdd-worker dispatches — the verbs are
#       read from the program's main(), so a verb it gains is a verb the command owes
#   R31 each of the seven acts of the table kept HERE has one heading in the command, and the first
#       line under it is the literal `sdd-worker allows <campaign-dir> <act> --lot <L>`
#   R32 the command writes the five stops (one numbered line each, with the pager and the journal),
#       the never list and the context rules, each phrase on a line of its own section
#   R33 docs/pipeline.md writes, under `## The worker`, a call of every verb main() dispatches and the
#       ladder in order; README.md has a usage line of sdd-worker and a link to that section; the
#       ON_ESCALATION_CMD row of config/schema.md names the worker and `assisted`, and its
#       BUDGET_MISSION_USD row the worker; CONTEXT.md has a glossary row for each of the five terms,
#       the level's writing the ladder and the worker's naming the coordination helper it is not
#   R34 the seal covers the lot ceilings (probed after R14): a ceiling lifted, or a lot added under
#       `lots: all`, after signing answers assisted — edited after signing, for the delegation and for
#       that lot, so approve and merge are asked there; a lot's title and count rewritten and an item
#       struck change nothing; the delegate shows each ceiling it signs, `ceiling <lot>: <ceiling>`
#   R35 the campaign's id is its directory's name, in both files: a campaign signed and then moved
#       to a directory of another name, a campaign.md or a delegation turned to another id after
#       signing, and a delegation left with no campaign.md are illegible — level and allows answer
#       assisted, budget
#       no ceiling, delegate signs nothing — and next stops on the first two and on the template's
#       placeholder id, naming both values; `.`, a trailing slash and a symlink are the directory
#   R36 an expires: the clock does not have — minute 99, the 31st of November, the 29th of February
#       of a common year — is illegible: level answers assisted for it and delegate refuses it
#       before the question; the 29th of February of a leap year signs
#   R37 `budget` reads the repo's .sdd/config.sh the way the runner loads it, over the signed mission
#       cap in the environment, and leaves rc 1 naming the file and the value when the cap the
#       runner would apply is above the signed one, zero, or empty — the config `sdd install` writes
#       among them; at or below it, in a form where the environment wins, silent on the key under a
#       caller that exports another value, or with no config, the signed cap holds
#   R38 the review item of `pr-ready` refuses a round graded A whose Rationale is a fill-in, by the
#       rule gate_REVIEW applies: the runner's placeholder() is read out of bin/sdd HERE and run on
#       the text each cell leaves once its `*` and backticks are stripped, and pr-ready agrees with
#       it on every cell (a differential: the rule lives in two programs); the gate: of the round
#       too — the template's own, an empty one, a quoted one —, and an absent one, since a round
#       with reviewed_head: is the worker's own; a fill-in in a table after the grade table changes
#       nothing
#   R39 `allows` with no --lot is rc 2, nothing on stdout and the lot named on stderr, for each of
#       the seven acts, under a full delegation that allows approve on a lot with no ceiling and caps
#       it on a lot at plan: an act asked with no lot would answer over every ceiling of the queue
#   R40 `delegate` signs what it showed: the delegation edited while the question is open (a FIFO
#       on stdin) is `not signed`, rc 1, the file as the edit left it; the same FIFO with no edit
#       signs, so the refusal is the edit's
#   R41 `budget` applies R37 to the .sdd/config.sh of the campaign's checkout and of each linked
#       worktree that holds a mission of the campaign, since `sdd run` runs in the mission's
#       worktree and loads that checkout's file: a worktree cut from a commit that still sets the
#       key above the signed cap stops budget naming the worktree's file, with the line deleted in
#       the campaign's checkout; one that holds no mission of the campaign is not read (R49), and
#       its 150 holds nothing; deleted everywhere, the signed cap holds
#   R42 the review item of `pr-ready` splits a row of the grade table as gate_REVIEW splits it: a
#       `\|` is a pipe of its cell, not a delimiter, and `\\|` is a backslash against a real one.
#       The runner's own split is read out of bin/sdd HERE, and pr-ready agrees with it on every
#       row: a fill-in rationale holding an escaped pipe fails, a sentence holding one is ready, and
#       a criterion holding one never moves a B into the grade column
#   R43 a signed `budget_mission_usd:` of zero, which `sdd run` reads as no ceiling, stops `budget`
#       naming the delegation and never a .sdd/config.sh — with no config, or one silent on the key;
#       a fraction above zero is the cap, and holds
#   R44 above assisted, the pager of the campaign's checkout and of each worktree that holds a
#       mission of the campaign is read, since `sdd run` runs in the mission's worktree and pages
#       from that checkout's file: an empty one in such a worktree or in the campaign's checkout
#       lowers the level to assisted naming that file, and `allows run` asks; an empty one in a
#       worktree with no mission of the campaign is not read (R49); the pager in every checkout is
#       the signed level; a campaign outside any git checkout names `(no repo)`, never the cwd's
#   R45 the review item knows the header and the separator of the grade table by the shape of the
#       line, never by the grade: the separator is the row whose every cell is `:?-+:?`, the header
#       the first row, its criterion `Criterion`; a criterion graded `---`, `:---:` or `Grade`, a row
#       of dashes with one cell that is not, a `Criterion` row past the first and a criterion in the
#       header's place are read and refused, a `| --- | A | --- |` row by its rationale; an aligned,
#       a spaced and an open separator, and a header in bold, are skipped (achado #8 of the r5)
#   R46 the review item refuses a mission folder holding anything git has not committed — a round
#       modified, staged, untracked under status.showUntrackedFiles=no, or ignored, and a file
#       whose name git quotes —, naming the first path and its status, over a head whose round
#       grades B; a change outside the folder is ready; a git status that does not run is not-ready
#       (achado #18 of the r5)
#   R47 the review item reads every commit after the reviewed head against each parent, and needs
#       the reviewed head to be an ancestor of the head: a change to code reverted later, a merge
#       whose resolution changes code, and a reviewed commit the head does not carry each fail; the
#       head itself passes the ancestry and is refused only by R46; an empty commit is ready; a git
#       diff-tree that does not run is not-ready (achados #9 and #10 of the r5)
#   R48 the receipt is the newest comment of the bot carrying the marker, chosen before it is
#       parsed: one cut short, or whose code_review is no object, fails codex with rc 1, a good
#       older one never read in its place; a comment of the bot without the marker is no receipt
#       (achado #11 of the r5)
#   R49 budget, level, allows and next read the .sdd/config.sh of the campaign's checkout and of
#       the worktrees that hold a mission of the campaign, and of no other: a worktree with another
#       campaign's mission or none, whose file sets the cap to 150, the pager to empty and
#       HANDOFF_DIR elsewhere and touches a mark, changes no answer and is never executed; the file
#       of the mission's worktree is (achado #3 of the r5, the narrow set the owner chose)
#   R50 a `git worktree list` that fails, before printing or after a full answer, stops budget
#       (`no spend — …`), level (`level assisted — unread: …`) and next (`stop - - — unread: …`)
#       with rc 1, naming the call and its rc, and allows asks; a git that passes gives R49's
#       answers (achado #24 of the r5)
#   R51 money is counted in cents: 0.10 + 0.70 reaches a ceiling of 0.80, and the cents are
#       rounded (0.803 is 0.80, 0.806 is 0.81, a cap of 0.806 is 0.81); the mission cap is printed
#       as signed (0.015, 10.004) and refused below one cent (0.004, 0.0099, 00.009), naming the
#       delegation; a BUDGET_MISSION_USD the runner's own pattern refuses (read out of bin/sdd
#       HERE) stops budget naming the file, the value and the refusal, and one it accepts at or
#       below the signed cap holds — a differential (achados #4, #5 and #21 of the r5)
#   R52 a .sdd/config.sh is sourced from its own checkout: a relative include in the mission's
#       worktree reads that worktree's file, asked from the repo's cwd or from another; and a
#       HANDOFF_DIR in a worktree of the set other than the campaign checkout's stops budget, level
#       and next with rc 1 naming both files, the default written out on one side being the same
#       (achados #37 and #38 of the r5)
#   R53 `lots:` is `all` or a list of words each of which is a lot of the table of the campaign.md
#       beside it: the template's own value (read out of templates/delegation.md HERE, whose words
#       L1 and L2 a reader of the asked lot alone found), a lot with no row and `all` among other
#       words are refused by delegate before the question, and are assisted — illegible to level,
#       an ask to allows and no ceiling to budget, naming the word, over a full delegation signed by
#       hand with the digest the program writes; a list of the table's lots signs and answers its
#       level (achado #1 of the r5)
#   R54 a pull request from a fork is not the lot's: next asks gh for isCrossRepository and counts
#       only the elements where it is false — a fork's merged, open or closed one leaves the lot to
#       run, the repo's open one beside a fork's merged one is reviewed —, and an element that does
#       not carry it as a boolean is off the contract, rc 3 (achado #6 of the r5)
#   R55 next reads the merge before the approval: a lot whose pull request merged is done though a
#       copy of its mission in a linked worktree is not approved; the copy check still comes before
#       review and run, names the first copy not approved, and is not carried to the next lot; a gh
#       that fails there is rc 3, and a mission with no branch asks no gh (achado #7 of the r5)
#   R56 delegate keeps an edit saved while the signature is written (an awk first on the PATH saves
#       one between the copy and the move): not signed, rc 1, the file as the edit left it; with no
#       edit it signs, the file keeping its mode and no temporary file left; a write that fails —
#       the awk, the move, a directory it cannot write in — is not signed, rc 1, naming the step,
#       the file unchanged (achado #23 of the r5)
#   R57 level and allows grant what they checked: an edit landing right after the digest (a
#       sha256sum first on the PATH) — a lot's ceiling lifted, the level raised — or around the
#       copy of the terms (a cat first on the PATH) — the id turned after it, a ceiling lifted for
#       it alone — is never granted, and asked again the files are edited after signing; the copy
#       goes when the verb exits, one it cannot make under TMPDIR is `unread`, rc 1, and a file it
#       cannot read answers what budget answers for it (achado #25 of the r5)
#
# The command and the four documents are prose, and no mutant of bin/ reaches them, so R30 to R33
# carry their own negative control: each checker runs on the files, where it has to miss nothing,
# and on copies with one thing taken out, where it has to name exactly that thing. A checker that
# never misses is decoration.
#
# Declared limit, no probe: the review item stops when `git rev-list <reviewed_head>..<head>` does
# not run, and no world here makes it fail — it walks the commits `git merge-base --is-ancestor` has
# just walked between the same two shas, and reads no tree. The stop decides which failure a broken
# history produces (without it, an empty list of commits reads as a range with nothing outside the
# folder), so it stays, with the missing world named here.
#
# Declared limits of the set (R49 to R52), no probe:
# - config_key enters the checkout with `CDPATH='' cd -- <root> || exit 0` and sources
#   `./.sdd/config.sh` there. Every caller passes a path git printed, which is absolute, so CDPATH
#   is never consulted and `./.sdd/config.sh` is the same file as `<root>/.sdd/config.sh`: the world
#   of a relative root was not built. The `|| exit 0` decides what a checkout it cannot enter
#   answers (nothing, never the caller's cwd), and no world reaches it: the `-f` test before it
#   already needs to traverse the same directory.
# - checkouts_of puts the root first and lists each checkout once, and campaign_set never appends
#   the root twice: git lists every worktree, the root among them, and every reader dedupes the
#   mission ids after it, so a root listed twice reads the same files and answers the same; the
#   root first only orders the copies of a mission, and in every world here the root is the main
#   checkout, which git lists first anyway — a campaign in a linked worktree was not built.
# - campaign_set answers no mission for an empty id, and no verb reaches it (bin/sdd-worker says
#   why): it decides what an empty id would answer, never all the missions of no campaign.
# - The HANDOFF_DIR of a worktree outside the set is not read: a worktree whose HANDOFF_DIR is not
#   the root's keeps its missions where the root's glob does not look, holds none the set sees, and
#   its missions are not counted (bin/sdd-worker, campaign_set).
#
# Declared limits of R56 and R57, no probe:
# - An edit saved between delegate's comparison and its move is lost (bin/sdd-worker says so on
#   delegation_write_signed): an mv first on the PATH would build that world, and it is not closed,
#   since closing it needs a lock the owner's editor honours.
# - Under root, chmod takes nothing away: the directory delegate cannot write in (R56) and the files
#   level cannot read (R57) are not built there, and those two worlds go unmeasured.
# - delegate removes the first temporary file when the second cannot be made, and no world reaches
#   it: the two are asked of the same directory one right after the other.
# - terms_copy returns 1 when mktemp -d fails and when the mkdir of the campaign's name in it
#   fails. Off root, the first guard degraded is caught by the second (the mkdir of `/<name>` is
#   refused), so the probe of an absent TMPDIR answers the same; the world that tells them apart is
#   a root user, for whom that mkdir succeeds. The second has no world of its own: one name made in
#   a directory mktemp -d has just made.
#
# The money is measured under a decimal comma: every budget call runs with LC_ALL set to pt_BR when
# this machine has the locale and it is armed (its printf refuses 8.5), so a verb that formats or
# sums outside LC_ALL=C answers wrong here. Declared limit: on a machine without the locale that
# rule goes unmeasured, and the sensor says nothing about it.
#
# Every green line is `  ok    <family>: <assertion>` on stdout, and each family (`usage: `, the
# verbs, `seal: `, `legible: `, `cap: `, `rationale: `, `lot: `, `shown: `, `worktree: `, `pipe: `,
# `zero: `, `pager: `, `sep: `, `committed: `, `range: `, `receipt: `, `narrow: `, `listed: `,
# `spend: `, `cwd: `, `lots: `, `fork: `, `stale: `, `kept: `, `once: `, `command: ` and
# `docs: `) prints exactly the assertions the mission plan or the fix increment that opened it
# names — the checkpoint counts them. Inside a mutant (SDD_MUTANT set) fail() ends the sensor at
# the first red, after printing it; the census in check-health.sh holds that clause.
#
# Usage: tests/check-worker.sh   (exit 0 = every verb answers what its rule says)
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER="$ROOT/bin/sdd-worker"
PROBES=0
fails=0
# The seam, the pager and the mission cap are the fixture's to set: a value exported by whoever runs
# the suite (an `sdd run` launched by the worker exports the cap) would move the clock of every
# probe, lend a pager to a repo that has none, or stand in for a config that is silent on the cap.
unset SDD_WORKER_NOW ON_ESCALATION_CMD BUDGET_MISSION_USD HANDOFF_DIR

# Anti-vacuity: a block that stops being dispatched prints what a clean program prints. One unit of
# PROBES is one assertion outcome, and only pass() and fail() write it.
PROBE_FLOOR=40

pass() { PROBES=$((PROBES + 1)); printf '  ok    %s\n' "$1"; }
fail() { PROBES=$((PROBES + 1))
         printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }

BOX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-worker-XXXXXX")"
trap 'rm -rf "$BOX"' EXIT
# The ledger is the fixture's for the whole sensor: no probe ever reads the real one. The one probe
# of the $HOME fallback unsets this in a subshell, with HOME in the box.
export SDD_STATE_DIR="$BOX/state"

# worker_from <stdin-file> <args...> — runs the program with <stdin-file> on stdin, from the cwd
# W_CWD names (the sensor's own when unset); PUBLISHES W_RC, W_OUT and W_ERR. Called, never
# substituted: under `$( )` the three globals would die with the subshell. `worker` is the same with
# no stdin at all, and `answer` writes what the next `worker_from "$BOX/in"` reads.
worker_from() {
  local in="$1"; shift
  W_RC=0
  ( CDPATH='' cd "${W_CWD:-.}" && exec "$WORKER" "$@" ) > "$BOX/out" 2> "$BOX/err" < "$in" || W_RC=$?
  W_OUT="$(cat "$BOX/out")"
  W_ERR="$(cat "$BOX/err")"
}
worker() { worker_from /dev/null "$@"; }
answer() { printf '%s' "$1" > "$BOX/in"; }

# --- the fixture repo ---------------------------------------------------------------------------
# One git repo, the shape every campaign verb reads: the root comes from `git rev-parse
# --show-toplevel`, and .sdd/config.sh carries the two keys the verbs read — the pager is set, so a
# level above assisted is not lowered by its absence. No remote: when a verb needs gh, it is a stub.
REPO="$BOX/repo"
mkdir -p "$REPO/.sdd" "$REPO/docs/campaigns"
git init -q -b main "$REPO"
printf 'HANDOFF_DIR="docs/handoffs"\nON_ESCALATION_CMD="true"\n' > "$REPO/.sdd/config.sh"
# Two more repos, the worlds with no pager: one whose config sets ON_ESCALATION_CMD to empty, one
# with no .sdd/config.sh at all.
NOPAGER="$BOX/nopager"; NOCONF="$BOX/noconf"
for r in "$NOPAGER" "$NOCONF"; do mkdir -p "$r/docs/campaigns"; git init -q -b main "$r"; done
mkdir -p "$NOPAGER/.sdd"
printf 'HANDOFF_DIR="docs/handoffs"\nON_ESCALATION_CMD=""\n' > "$NOPAGER/.sdd/config.sh"

# campaign <path> <level> <expires> <mission cap> <campaign cap> — a campaign directory,
# docs/campaigns/<path> of the fixture repo, made from the kit's own templates, every placeholder of
# the delegation's frontmatter replaced by a real value, `lots: all`, and `signed:` left as the
# template has it (empty); prints its path. The id written in both files is the last segment of
# <path>, the directory's name, as the contract says: two directories of one campaign are
# `<a>/<id>` and `<b>/<id>`. A cap given as `-` deletes that key's line: a missing ceiling. Only the
# frontmatter (line 2 to the closing ---) is edited, the way the verbs read it.
campaign() {
  local d="$REPO/docs/campaigns/$1" id="${1##*/}"
  mkdir -p "$d"
  sed "2,/^---\$/ s@^campaign: .*@campaign: $id@" "$ROOT/templates/campaign.md" > "$d/campaign.md"
  sed "2,/^---\$/ {
         s@^campaign: .*@campaign: $id@
         s@^level: .*@level: $2@
         s@^lots: .*@lots: all@
         s@^expires: .*@expires: $3@
         s@^budget_mission_usd: .*@budget_mission_usd: $4@
         s@^budget_campaign_usd: .*@budget_campaign_usd: $5@
       }" "$ROOT/templates/delegation.md" > "$d/delegation.md"
  [ "$5" != - ] || sed -i '2,/^---$/ { /^budget_campaign_usd:/d }' "$d/delegation.md"
  printf '%s\n' "$d"
}

# digest_of <campaign> <level> <lots> <expires> <mission cap> <campaign cap> ['<lot> <ceiling>']... —
# the digest the contract defines, computed by the sensor and never by the program: the first 12
# hex of the sha256 of the six lines `key: value`, in this order, then one line
# `ceiling <lot>: <ceiling>` per row of the campaign's lots table, in the order of the queue, each
# line ending in a newline.
digest_of() {
  { printf 'campaign: %s\nlevel: %s\nlots: %s\nexpires: %s\nbudget_mission_usd: %s\nbudget_campaign_usd: %s\n' \
      "${@:1:6}"
    shift 6
    for r in "$@"; do printf 'ceiling %s: %s\n' "${r%% *}" "${r#* }"; done
  } | sha256sum | cut -c1-12
}

# signed_line <delegation> — the frontmatter's signed: line, as written.
signed_line() { sed -n '2,/^---$/ { /^signed:/p }' "$1"; }

# --- R1: usage ----------------------------------------------------------------------------------
# Both worlds, and three terms each: the rc alone is shared with every refusal a verb will have, the
# usage text is what tells this branch apart, and an empty stdout keeps the usage off the channel a
# caller parses as the answer.
got=""
worker;            [ "$W_RC" = 2 ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" && [ -z "$W_OUT" ] \
  || got="no verb: rc $W_RC, stderr '${W_ERR%%$'\n'*}', stdout '${W_OUT%%$'\n'*}'"
worker frobnicate; [ "$W_RC" = 2 ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" && [ -z "$W_OUT" ] \
  || got="${got:+$got; }unknown verb: rc $W_RC, stderr '${W_ERR%%$'\n'*}', stdout '${W_OUT%%$'\n'*}'"
if [ -z "$got" ]; then
  pass 'usage: no verb and an unknown verb print the usage and leave rc 2'
else
  fail 'usage: no verb and an unknown verb print the usage and leave rc 2' \
    'rc 2, the usage on stderr, nothing on stdout' "$got"
fi

# --- R2: delegate signs on a yes ----------------------------------------------------------------
# Five terms: rc 0; the signed: line has the instant-and-digest shape; the digest is the one the
# sensor computes from the six values and the two ceilings of the template's lots table, L1 with
# none and L2 at plan (a program that hashed a constant, fewer keys or no ceiling differs);
# the instant lies between two readings of the clock taken around the call; and the file minus its
# signed: line is byte for byte what it was. The stdout echoes the grant and says how to commit it.
got=""
d="$(campaign c-yes pr '2099-12-31 23:59' 25 200.50)"
cp "$d/delegation.md" "$BOX/c-yes.before"
answer $'y\n'
t0="$(date '+%Y-%m-%d %H:%M')"
worker_from "$BOX/in" delegate "$d"
t1="$(date '+%Y-%m-%d %H:%M')"
line="$(signed_line "$d/delegation.md")"
want="$(digest_of c-yes pr all '2099-12-31 23:59' 25 200.50 'L1 -' 'L2 plan')"
stamp="${line#signed: }"; stamp="${stamp% *}"
[ "$W_RC" = 0 ] || got="rc $W_RC (stdout '${W_OUT##*$'\n'}')"
[[ "$line" =~ ^signed:\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}\ [0-9a-f]{12}$ ]] \
  || got="${got:+$got; }signed line '$line'"
[ "${line##* }" = "$want" ] \
  || got="${got:+$got; }digest '${line##* }', the six keys and the two ceilings give '$want'"
{ [ "${stamp//[!0-9]/}" -ge "${t0//[!0-9]/}" ] 2>/dev/null \
    && [ "${stamp//[!0-9]/}" -le "${t1//[!0-9]/}" ]; } \
  || got="${got:+$got; }instant '$stamp' is not between $t0 and $t1"
cmp -s <(sed '/^signed:/d' "$BOX/c-yes.before") <(sed '/^signed:/d' "$d/delegation.md") \
  || got="${got:+$got; }a line other than signed: changed"
grep -qx 'level: pr' <<< "$W_OUT" && grep -qx 'budget_campaign_usd: 200.50' <<< "$W_OUT" \
  || got="${got:+$got; }the grant was not echoed on stdout"
grep -q "^signed $d/delegation.md — commit it: git add $d/delegation.md && git commit " <<< "$W_OUT" \
  || got="${got:+$got; }no commit line on stdout"
grep -qF 'Sign this delegation? [y/N]' <<< "$W_ERR" || got="${got:+$got; }the question was not asked"
if [ -z "$got" ]; then
  pass 'delegate: an answer of y signs with a digest of the other fields'
else
  fail 'delegate: an answer of y signs with a digest of the other fields' \
    "rc 0 and 'signed: <instant> $want' as the only changed line" "$got"
fi

# --- R3: no character on stdin ------------------------------------------------------------------
# The rc is the term that tells this branch apart (0 is a no, 1 a refusal); the file byte for byte
# unchanged and no `signed ` line on stdout are what "writes nothing" means.
got=""
d="$(campaign c-silent merge '2099-12-31 23:59' 25 200)"
cp "$d/delegation.md" "$BOX/c-silent.before"
worker delegate "$d"
[ "$W_RC" = 66 ] || got="rc $W_RC"
cmp -s "$BOX/c-silent.before" "$d/delegation.md" || got="${got:+$got; }the file changed: '$(signed_line "$d/delegation.md")'"
grep -q '^signed ' <<< "$W_OUT" && got="${got:+$got; }stdout says signed"
grep -q '^not signed — ' <<< "$W_OUT" || got="${got:+$got; }stdout gives no reason"
if [ -z "$got" ]; then
  pass 'delegate: no answer on stdin leaves rc 66 and writes nothing'
else
  fail 'delegate: no answer on stdin leaves rc 66 and writes nothing' \
    'rc 66, the file unchanged, a not signed reason' "$got"
fi

# --- R4: what signs nothing ---------------------------------------------------------------------
# Seven worlds. The no gets an n; the refusals get a YES, so that only the refusal stands
# between them and a signature. Each: the file unchanged, the reason that names its own branch, and
# the rc of that branch — 0 for the answer, 1 for the refusals, which are also never asked.
got=""
# refused <id> <rc> <reason prefix> — appends to got what the last delegate did wrong.
refused() {
  [ "$W_RC" = "$2" ] || got="${got:+$got; }$1: rc $W_RC"
  cmp -s "$BOX/$1.before" "$REPO/docs/campaigns/$1/delegation.md" \
    || got="${got:+$got; }$1: the file changed"
  grep -q "^not signed — $3" <<< "$W_OUT" || got="${got:+$got; }$1: no '$3' reason (stdout '${W_OUT##*$'\n'}')"
}
# Three more worlds are folded in, one per legibility rule that no world above reaches alone: an
# empty `lots:` (only "present and not empty" refuses it — an empty ceiling, level or instant also
# fails its own pattern), an instant that is not one (without its pattern, `expired` errors on the
# arithmetic, reads "not expired" and signs), and a ceiling that is not a number.
for w in 'c-no|pr|2099-12-31 23:59|25|200|n' 'c-expired|pr|2020-01-01 00:00|25|200|y' \
         'c-badlevel|everything|2099-12-31 23:59|25|200|y' 'c-nocap|pr|2099-12-31 23:59|25|-|y' \
         'c-nolots|pr|2099-12-31 23:59|25|200|y' 'c-badinstant|pr|next week|25|200|y' \
         'c-badcap|pr|2099-12-31 23:59|ten|200|y'; do
  IFS='|' read -r id lv ex m c a <<< "$w"
  d="$(campaign "$id" "$lv" "$ex" "$m" "$c")"
  [ "$id" != c-nolots ] || sed -i '2,/^---$/ s@^lots: .*@lots:@' "$d/delegation.md"
  cp "$d/delegation.md" "$BOX/$id.before"
  answer "$a"$'\n'
  worker_from "$BOX/in" delegate "$d"
  case "$id" in
    c-no) refused "$id" 0 'the answer was not y' ;;
    c-expired) refused "$id" 1 'expired' ;;
    # The clock (R36) refuses `next week` too, so only the pattern's own reason tells it apart.
    c-badinstant) refused "$id" 1 "illegible: expires 'next week' is not YYYY-MM-DD HH:MM" ;;
    *) refused "$id" 1 'illegible' ;;
  esac
  [ "$id" = c-no ] || ! grep -qF 'Sign this delegation?' <<< "$W_ERR" \
    || got="${got:+$got; }$id: the question was asked"
done
if [ -z "$got" ]; then
  pass 'delegate: n, an expired instant, an undefined level and a missing ceiling sign nothing'
else
  fail 'delegate: n, an expired instant, an undefined level and a missing ceiling sign nothing' \
    'each file unchanged, with its own reason and rc' "$got"
fi

# --- level: the fixtures ------------------------------------------------------------------------
# sign <dir> — the delegation of <dir> signed through the program's own delegate, a y on stdin,
# never with a digest written here: a probe built on a file the program did not sign would measure
# the sensor's idea of a signature. When it did not sign, it says so in got, and the probe that
# called it goes red on that instead of measuring an unsigned file.
sign() {
  answer $'y\n'
  worker_from "$BOX/in" delegate "$1"
  [ "$W_RC" = 0 ] && [[ "$(signed_line "$1/delegation.md")" =~ ^signed:\ [0-9] ]] \
    || got="${got:+$got; }fixture ${1##*/} did not sign: rc $W_RC, '${W_OUT##*$'\n'}'"
}

# level_is <label> <want> <args...> — runs level <args...>; appends to got unless it left rc 0 and
# exactly one line on stdout that starts with <want> (a literal, never a pattern).
level_is() {
  local label="$1" want="$2"; shift 2
  worker level "$@"
  [ "$W_RC" = 0 ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$want"* ]] \
    || got="${got:+$got; }$label: rc $W_RC, '$W_OUT' (want '$want…')"
}

# set_lots <campaign.md> <lot:ceiling>... — the rows of the template's lots table replaced by one
# row per argument, under the template's own header and separator. Says so in got when the rows did
# not land, so a probe never measures the template's two placeholder rows by accident.
set_lots() {
  local f="$1" r rows=""; shift
  for r in "$@"; do rows="$rows| ${r%%:*} | lote ${r%%:*} | ${r#*:} | 1 |\\n"; done
  awk -v rows="$rows" '/^\| L[0-9]/ { next } { print } /^\|---\|---\|---\|---\|$/ { printf "%s", rows }' \
    "$f" > "$f.new" && mv "$f.new" "$f"
  [ "$(grep -c '^| L[0-9]' "$f")" = "$#" ] || got="${got:+$got; }fixture $f: the lots rows did not land"
}

FAR='2099-12-31 23:59'

# --- R5: each of the five answers its own level -------------------------------------------------
# Five worlds, one per level, each signed and asked with the real clock: a program that answered a
# constant, or the ladder's top, matches one world at most. Each is asked from the cwd of the repo
# with no pager, so a program that read the pager from the cwd instead of the campaign's repo would
# answer assisted for four of them.
got=""
for lv in assisted pr plan merge full; do
  d="$(campaign "l-$lv" "$lv" "$FAR" 25 200)"
  sign "$d"
  W_CWD="$NOPAGER" level_is "$lv" "level $lv — signed until $FAR" "$d"
done
if [ -z "$got" ]; then
  pass 'level: a signed delegation answers its own level, for each of the five'
else
  fail 'level: a signed delegation answers its own level, for each of the five' \
    "level <the signed one> — signed until $FAR, for each" "$got"
fi

# --- R6: absent, illegible, unsigned, expired ---------------------------------------------------
# Each world answers assisted with its own reason — the reason is what tells the four branches
# apart, since every one of them is assisted. Two of them are siblings measured with them: a
# directory that is not there is a usage error (rc 2, nothing on stdout), never an answer about a
# campaign, and the illegible world is the template itself, placeholders and all.
# Expiry is measured on both sides of the SDD_WORKER_NOW seam. Forward: a delegation signed until
# FAR is expired at a seam one minute later and at a seam equal to FAR (the instant itself is not
# after it). Backward: a delegation signed under a clock stubbed into 2020 (a `date` on PATH that
# answers that one format and hands every other call to the real one), expiring in 2020, is
# expired under the real clock — and stays expired under a seam that names an instant before its
# expiry: the seam moves time forward and never brings a delegation back.
got=""
mkdir -p "$REPO/docs/campaigns/l-absent"
level_is absent 'level assisted — no delegation' "$REPO/docs/campaigns/l-absent"
worker level "$REPO/docs/campaigns/l-nowhere"
{ [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR"; } \
  || got="${got:+$got; }no directory: rc $W_RC, stdout '$W_OUT'"
mkdir -p "$REPO/docs/campaigns/l-template"
cp "$ROOT/templates/delegation.md" "$REPO/docs/campaigns/l-template/delegation.md"
level_is template 'level assisted — illegible: ' "$REPO/docs/campaigns/l-template"
d="$(campaign l-unsigned merge "$FAR" 25 200)"
level_is unsigned 'level assisted — unsigned' "$d"
d="$(campaign l-expiring merge "$FAR" 25 200)"
sign "$d"
level_is 'before the seam' "level merge — signed until $FAR" "$d"
SDD_WORKER_NOW='2100-01-01 00:00' level_is 'seam after' 'level assisted — expired: ' "$d"
SDD_WORKER_NOW="$FAR" level_is 'seam at the instant' 'level assisted — expired: ' "$d"
mkdir -p "$BOX/past"
printf '#!/bin/sh\n[ "$1" = "+%%Y-%%m-%%d %%H:%%M" ] && [ "$#" = 1 ] && { echo "2020-01-01 00:00"; exit 0; }\nexec %s "$@"\n' \
  "$(command -v date)" > "$BOX/past/date"
chmod +x "$BOX/past/date"
d="$(campaign l-past merge '2020-06-01 00:00' 25 200)"
PATH="$BOX/past:$PATH" sign "$d"
level_is 'signed in 2020' 'level assisted — expired: ' "$d"
SDD_WORKER_NOW='2020-03-01 00:00' level_is 'seam before the expiry' 'level assisted — expired: ' "$d"
if [ -z "$got" ]; then
  pass 'level: absent, illegible, unsigned and expired each answer assisted and say why'
else
  fail 'level: absent, illegible, unsigned and expired each answer assisted and say why' \
    'assisted, with the reason of each branch' "$got"
fi

# --- R7: edited after signing -------------------------------------------------------------------
# One signed file per edit, each first witnessed at its signed level, so the assisted that follows
# is the edit's and nothing else's: the level raised, the lots widened, a ceiling raised, and the
# digest itself rewritten. The body is the counter-world: only the frontmatter is read, so a line
# of prose added below it leaves the level standing — a digest of the whole file would not.
got=""
for w in 'l-edit-level|s@^level: merge$@level: full@' 'l-edit-lots|s@^lots: all$@lots: L1@' \
         'l-edit-cap|s@^budget_campaign_usd: 200$@budget_campaign_usd: 2000@' \
         'l-edit-digest|s@^\(signed: .*\)[0-9a-f]$@\1x@'; do
  id="${w%%|*}"
  d="$(campaign "$id" merge "$FAR" 25 200)"
  sign "$d"
  level_is "$id before" "level merge — signed until $FAR" "$d"
  cp "$d/delegation.md" "$BOX/$id.signed"
  sed -i "2,/^---\$/ ${w#*|}" "$d/delegation.md"
  cmp -s "$BOX/$id.signed" "$d/delegation.md" && got="${got:+$got; }fixture $id: the edit changed nothing"
  level_is "$id after" 'level assisted — edited after signing' "$d"
done
d="$(campaign l-edit-body merge "$FAR" 25 200)"
sign "$d"
printf '\nA line of prose added below the frontmatter after the signature.\n' >> "$d/delegation.md"
level_is 'body edited' "level merge — signed until $FAR" "$d"
if [ -z "$got" ]; then
  pass 'level: a delegation edited after signing answers assisted'
else
  fail 'level: a delegation edited after signing answers assisted' \
    'assisted — edited after signing for each frontmatter edit, the level for a body edit' "$got"
fi

# --- R8: a name outside the ladder --------------------------------------------------------------
# Near misses of a level, each in the level: key of an otherwise legible delegation: a capital, a
# prefix, a word past the top, two levels in one value, and a glob. Each is illegible (the reason
# says so — unsigned would mean the ladder let it through, since none of them can be signed). A
# match by substring of the ladder, by prefix or by pattern passes at least one of them. The same
# rule holds for the lot's Ceiling cell: a ceiling that is not a level caps the lot at assisted,
# never reads as no ceiling.
got=""
for lv in Merge mer fullest 'pr plan' '*'; do
  d="$(campaign "l-name-${#lv}-${lv//[^a-zA-Z]/}" "$lv" "$FAR" 25 200)"
  level_is "level '$lv'" 'level assisted — illegible: level ' "$d"
done
d="$(campaign l-badceiling merge "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:Plan' 'L2:*'
sign "$d"
level_is 'ceiling Plan' 'level assisted — capped by the lot' "$d" --lot L1
level_is 'ceiling *' 'level assisted — capped by the lot' "$d" --lot L2
if [ -z "$got" ]; then
  pass 'level: a name outside the ladder is not a level'
else
  fail 'level: a name outside the ladder is not a level' \
    'assisted — illegible for each level, assisted for each ceiling' "$got"
fi

# --- R9: no pager -------------------------------------------------------------------------------
# One signed delegation, three repos: the fixture repo (pager set), NOPAGER and NOCONF. The same
# file — copied, signature and all — answers merge in the first and assisted with "no pager" in the
# other two: the difference is the config and nothing else. Each is asked from the cwd of a repo with the opposite
# answer, so a program that read the cwd's config instead of the campaign's answers the other
# side. A signed assisted, in the repo with no pager, answers its own level: the rule is about the
# levels that act alone, and assisted acts on nothing. The repo with no config is asked once more
# under a caller that exports a pager: `sdd run` does not run without the file, so the caller's
# value lends nothing, and the reader answers empty there instead of reading the environment.
got=""
d="$(campaign l-pager merge "$FAR" 25 200)"
sign "$d"
cp -a "$d" "$NOPAGER/docs/campaigns/"; cp -a "$d" "$NOCONF/docs/campaigns/"
W_CWD="$NOPAGER" level_is 'pager set' "level merge — signed until $FAR" "$d"
W_CWD="$REPO" level_is 'pager empty' 'level assisted — no pager' "$NOPAGER/docs/campaigns/l-pager"
W_CWD="$REPO" level_is 'no config' 'level assisted — no pager' "$NOCONF/docs/campaigns/l-pager"
( export ON_ESCALATION_CMD=true
  W_CWD="$REPO" level_is 'no config, a pager exported' 'level assisted — no pager' \
    "$NOCONF/docs/campaigns/l-pager"
  printf '%s' "$got" > "$BOX/got" )
got="$(cat "$BOX/got")"
d="$(campaign l-pager-assisted assisted "$FAR" 25 200)"
sign "$d"
cp -a "$d" "$NOPAGER/docs/campaigns/"
W_CWD="$REPO" level_is 'assisted, no pager' "level assisted — signed until $FAR" \
  "$NOPAGER/docs/campaigns/l-pager-assisted"
if [ -z "$got" ]; then
  pass 'level: above assisted with no pager answers assisted'
else
  fail 'level: above assisted with no pager answers assisted' \
    'merge where the pager is set, assisted — no pager where it is not' "$got"
fi

# --- R10: the lot ------------------------------------------------------------------------------
# A merge delegation over a table of five lots: no ceiling, plan, full, pr, and L11 with none.
# Signed for all lots: the plan and pr ceilings lower it, the full ceiling does not raise it, and a
# lot the table has no row for is not covered. Signed for `L11 L3` only: L1 (a prefix of L11) and L2
# are not covered, L11 and L3 are. A --lot with no lot, or an empty one, is a usage error and never
# the uncapped level.
got=""
for id in l-lots l-some; do
  d="$(campaign "$id" merge "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L2:plan' 'L3:full' 'L4:pr' 'L11:-'
  [ "$id" = l-lots ] || sed -i '2,/^---$/ s@^lots: .*@lots: L11 L3@' "$d/delegation.md"
  sign "$d"
done
d="$REPO/docs/campaigns/l-lots"
level_is 'all, L1' "level merge — signed until $FAR" "$d" --lot L1
level_is 'all, L2' 'level plan — capped by the lot' "$d" --lot L2
level_is 'all, L3' "level merge — signed until $FAR" "$d" --lot L3
level_is 'all, L4' 'level pr — capped by the lot' "$d" --lot L4
level_is 'all, L9' 'level assisted — lot not covered' "$d" --lot L9
d="$REPO/docs/campaigns/l-some"
level_is 'some, L1' 'level assisted — lot not covered' "$d" --lot L1
level_is 'some, L2' 'level assisted — lot not covered' "$d" --lot L2
level_is 'some, L11' "level merge — signed until $FAR" "$d" --lot L11
level_is 'some, L3' "level merge — signed until $FAR" "$d" --lot L3
for args in '--lot' '--lot|' '--lit|L2'; do
  IFS='|' read -ra a <<< "$args"
  [ "$args" != '--lot|' ] || a=(--lot '')
  worker level "$d" "${a[@]}"
  { [ "$W_RC" = 2 ] && [ -z "$W_OUT" ]; } || got="${got:+$got; }level ${a[*]}: rc $W_RC, stdout '$W_OUT'"
done
if [ -z "$got" ]; then
  pass 'level: the lot ceiling lowers the level and never raises it, and an uncovered lot is assisted'
else
  fail 'level: the lot ceiling lowers the level and never raises it, and an uncovered lot is assisted' \
    'the lower of the signed level and the ceiling, assisted where the lot is not covered' "$got"
fi

# --- allows: the fixtures -----------------------------------------------------------------------
# The table of acts as the mission plan writes it, kept HERE and never read from the program: one
# row per act, the lowest level that grants it, then one letter per level of the ladder in order
# (assisted pr plan merge full), y where the act is allowed. A program whose table moved one act,
# or that compared the ranks the wrong way round, differs in at least one cell.
LEVELS=(assisted pr plan merge full)
ACT_TABLE=('run pr nyyyy' 'pr pr nyyyy' 'review pr nyyyy' 'plan plan nnyyy'
           'merge merge nnnyy' 'postmerge merge nnnyy' 'approve full nnnny')

# allows_is <label> <rc> <want> <args...> — runs allows <args...>; appends to got unless it left
# <rc> and exactly one line on stdout — equal to <want> when <rc> is 0 (the allowed line is whole),
# starting with <want> otherwise (the ask line ends in the level's reason). <want> is a literal,
# never a pattern.
allows_is() {
  local label="$1" rc="$2" want="$3"; shift 3
  worker allows "$@"
  if [ "$W_RC" = "$rc" ] && [[ "$W_OUT" != *$'\n'* ]] \
     && { [[ "$rc" = 0 && "$W_OUT" == "$want" ]] || [[ "$rc" != 0 && "$W_OUT" == "$want"* ]]; }; then
    return 0
  fi
  got="${got:+$got; }$label: rc $W_RC, '$W_OUT' (want rc $rc, '$want')"
}

# --- R11: five levels by seven acts -------------------------------------------------------------
# Every cell asked of a delegation signed at its level, in a repo with a pager, on L1 (the
# template's lot with no ceiling), and counted: the count is the witness that the 35 cells were
# asked, since a loop that asked none leaves got empty.
got=""; cells=0
for i in "${!LEVELS[@]}"; do
  lv="${LEVELS[$i]}"
  d="$(campaign "a-$lv" "$lv" "$FAR" 25 200)"
  sign "$d"
  for row in "${ACT_TABLE[@]}"; do
    read -r act floor yes <<< "$row"
    before="$got"
    if [ "${yes:$i:1}" = y ]; then
      allows_is "$lv/$act" 0 "allowed $act at $lv" "$d" "$act" --lot L1
    else
      allows_is "$lv/$act" 1 "ask $act needs $floor, effective $lv — signed until $FAR" "$d" "$act" --lot L1
    fi
    [ "$got" != "$before" ] || cells=$((cells + 1))
  done
done
[ "$cells" = 35 ] || got="${got:+$got; }$cells of 35 cells answered the table"
if [ -z "$got" ]; then
  pass 'allows: the five levels by the seven acts answer the table, 35 of 35'
else
  fail 'allows: the five levels by the seven acts answer the table, 35 of 35' \
    'allowed where the table says y, ask with the floor where it says n' "$got"
fi

# --- R12: a word that is not an act -------------------------------------------------------------
# Asked of the full delegation on L1, where every act of the table is allowed: a word read as any
# act, or as any level, is allowed there, so rc 2 and an empty stdout are what tell the refusal apart, and
# the stderr names the word. The near misses: an unknown word, a capital, a prefix, two acts in one
# argument, a glob, a level's name, an entry of the table as the program may write it, and nothing.
# The calls of the wrong shape ride along: no act, a --lot with no lot, a misspelt flag, and a
# directory that is not there.
got=""
d="$REPO/docs/campaigns/a-full"
for act in frobnicate Merge merg 'run pr' '*' assisted 'run:pr' ''; do
  worker allows "$d" "$act" --lot L1
  { [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -qF "'$act' is not an act" <<< "$W_ERR" \
      && grep -q '^usage: sdd-worker ' <<< "$W_ERR"; } \
    || got="${got:+$got; }act '$act': rc $W_RC, stdout '$W_OUT', stderr '${W_ERR%%$'\n'*}'"
done
for args in "$d" "$d|run|--lot" "$d|run|--lit|L1" "$REPO/docs/campaigns/a-nowhere|run|--lot|L1"; do
  IFS='|' read -ra a <<< "$args"
  worker allows "${a[@]}"
  { [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR"; } \
    || got="${got:+$got; }allows ${a[*]}: rc $W_RC, stdout '$W_OUT'"
done
if [ -z "$got" ]; then
  pass 'allows: an act outside the table leaves rc 2 and is never allowed'
else
  fail 'allows: an act outside the table leaves rc 2 and is never allowed' \
    "rc 2, nothing on stdout, the word named on stderr" "$got"
fi

# --- R13: a delegation that does not hold -------------------------------------------------------
# Six worlds, each signed (where it is signed at all) at full, so that only the break stands
# between the act and an allow: absent, the template, unsigned, expired (a seam one minute past
# FAR), edited after signing (lots narrowed), and no pager (the same signed file copied to
# the repo whose config sets none). The three signed ones are first witnessed allowing approve. Each
# world asks for each of the seven acts, effective assisted, with its own reason — and the count is
# the witness that the 42 were asked.
got=""; asks=0
mkdir -p "$REPO/docs/campaigns/a-absent" "$REPO/docs/campaigns/a-template"
cp "$ROOT/templates/delegation.md" "$REPO/docs/campaigns/a-template/delegation.md"
campaign a-unsigned full "$FAR" 25 200 > /dev/null
for id in a-expiring a-edited a-pager; do
  d="$(campaign "$id" full "$FAR" 25 200)"
  sign "$d"
  allows_is "$id before" 0 'allowed approve at full' "$d" approve --lot L1
done
sed -i '2,/^---$/ s@^lots: all$@lots: L1@' "$REPO/docs/campaigns/a-edited/delegation.md"
cp -a "$REPO/docs/campaigns/a-pager" "$NOPAGER/docs/campaigns/"
for w in "a-absent||no delegation" "a-template||illegible: " "a-unsigned||unsigned" \
         "a-expiring|2100-01-01 00:00|expired: " "a-edited||edited after signing" \
         "$NOPAGER/docs/campaigns/a-pager||no pager"; do
  IFS='|' read -r id seam why <<< "$w"
  if [[ "$id" == /* ]]; then d="$id"; else d="$REPO/docs/campaigns/$id"; fi
  for row in "${ACT_TABLE[@]}"; do
    read -r act floor _ <<< "$row"
    before="$got"
    SDD_WORKER_NOW="$seam" allows_is "${id##*/}/$act" 1 \
      "ask $act needs $floor, effective assisted — $why" "$d" "$act" --lot L1
    [ "$got" != "$before" ] || asks=$((asks + 1))
  done
done
[ "$asks" = 42 ] || got="${got:+$got; }$asks of 42 acts asked the owner"
if [ -z "$got" ]; then
  pass 'allows: a broken delegation asks the owner for every act'
else
  fail 'allows: a broken delegation asks the owner for every act' \
    'ask <act> needs <floor>, effective assisted — <the reason of the break>, for each' "$got"
fi

# --- R14: the lot's ceiling is the act's --------------------------------------------------------
# A full delegation over three lots: no ceiling, merge, full. On L1 and L3 approve is allowed at
# full — the witness that the delegation grants it; on L2 it is asked, and merge is
# allowed there at merge, so the cap is the lot's ceiling and not a refusal of the lot. A lot the
# table has no row for asks too.
got=""
d="$(campaign a-lots full "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:merge' 'L3:full'
sign "$d"
allows_is 'L1, no ceiling' 0 'allowed approve at full' "$d" approve --lot L1
allows_is 'L3, ceiling full' 0 'allowed approve at full' "$d" approve --lot L3
allows_is 'L2, approve' 1 'ask approve needs full, effective merge — capped by the lot' "$d" approve --lot L2
allows_is 'L2, merge' 0 'allowed merge at merge' "$d" merge --lot L2
allows_is 'L9, no row' 1 'ask approve needs full, effective assisted — lot not covered' "$d" approve --lot L9
if [ -z "$got" ]; then
  pass 'allows: the lot ceiling stops approve on a capped lot under full'
else
  fail 'allows: the lot ceiling stops approve on a capped lot under full' \
    'approve asked on the lot capped at merge, allowed where the lot is not capped' "$got"
fi

# --- R34: the seal covers the lot ceilings ------------------------------------------------------
# A lot's ceiling is what keeps its approval from being delegated (the L6 of the kit's campaign is
# capped at plan), and it lives in campaign.md, beside the file the owner signs. Three full
# delegations over L1 (no ceiling) and L6 (plan), each signed by the program and first witnessed
# capping L6 at plan, so what follows is the edit's and nothing else's: L6's ceiling replaced by
# `-`, and a row L7 added under `lots: all` (a lot the owner never saw), each answer assisted,
# edited after signing, for the delegation and for that lot, and allows asks approve and merge on
# it. The counter-world rewrites L1's title and count and strikes an item, which the campaign does
# as it goes: the level stands, and L6 is still capped. The delegate shows each ceiling it signs on
# a line of its own, and the digest it writes is the one the sensor computes from the six values
# and the two ceilings — a world the template's two rows (R2) do not reach alone.
got=""
for w in 's-lift|s/^| L6 | lote L6 | plan | 1 |$/| L6 | lote L6 | - | 1 |/' \
         's-add|/^| L6 | lote L6 | plan | 1 |$/a | L7 | lote L7 | - | 1 |' \
         's-strike|s/^| L1 | lote L1 | - | 1 |$/| L1 | renamed | - | 3 |/; 0,/^- \[ \] /s//- [x] /'; do
  id="${w%%|*}"
  d="$(campaign "$id" full "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L6:plan'
  sign "$d"
  { grep -qx 'ceiling L1: -' <<< "$W_OUT" && grep -qx 'ceiling L6: plan' <<< "$W_OUT"; } \
    || got="${got:+$got; }$id: the delegate did not show the ceilings it signs"
  line="$(signed_line "$d/delegation.md")"
  want="$(digest_of "$id" full all "$FAR" 25 200 'L1 -' 'L6 plan')"
  [ "${line##* }" = "$want" ] \
    || got="${got:+$got; }$id: digest '${line##* }', the six keys and the two ceilings give '$want'"
  level_is "$id before" 'level plan — capped by the lot' "$d" --lot L6
  cp "$d/campaign.md" "$BOX/$id.campaign"
  sed -i "${w#*|}" "$d/campaign.md"
  cmp -s "$BOX/$id.campaign" "$d/campaign.md" && got="${got:+$got; }fixture $id: the edit changed nothing"
  if [ "$id" = s-strike ]; then
    { grep -q '^- \[x\] ' "$d/campaign.md" && grep -qx '| L1 | renamed | - | 3 |' "$d/campaign.md"; } \
      || got="${got:+$got; }fixture $id: the strike or the rename did not land"
    level_is "$id after" "level full — signed until $FAR" "$d"
    level_is "$id after, L6" 'level plan — capped by the lot' "$d" --lot L6
    continue
  fi
  sl=L6; [ "$id" = s-lift ] || sl=L7
  level_is "$id after" 'level assisted — edited after signing' "$d"
  level_is "$id after, $sl" 'level assisted — edited after signing' "$d" --lot "$sl"
  allows_is "$id, approve" 1 'ask approve needs full, effective assisted — edited after signing' \
    "$d" approve --lot "$sl"
  allows_is "$id, merge" 1 'ask merge needs merge, effective assisted — edited after signing' \
    "$d" merge --lot "$sl"
done
if [ -z "$got" ]; then
  pass 'seal: a lot ceiling lifted or a lot added after signing answers assisted, and the delegate shows each ceiling'
else
  fail 'seal: a lot ceiling lifted or a lot added after signing answers assisted, and the delegate shows each ceiling' \
    'assisted — edited after signing for the lifted ceiling and the added lot, the level standing for a struck item, each ceiling on the stdout of delegate' "$got"
fi

# --- budget: the fixtures -----------------------------------------------------------------------
# mission <checkout> <handoff dir> <id> <campaign> — a mission folder made from the kit's own
# template, its missao: and campaign: replaced; a <campaign> of `-` keeps the template's
# placeholder, a mission that belongs to no campaign. Only the frontmatter is edited, so a template
# whose campaign: key moved leaves the placeholder and the probe that counts the mission goes red.
mission() {
  mkdir -p "$1/$2/$3"
  if [ "$4" = - ]; then
    cp "$ROOT/templates/missao.md" "$1/$2/$3/00-missao.md"
  else
    sed "2,/^---\$/ { s@^missao: .*@missao: $3@; s@^campaign: .*@campaign: $4@; }" \
      "$ROOT/templates/missao.md" > "$1/$2/$3/00-missao.md"
  fi
}

# spent <mission> <event> <cost> — one line of the ledger in the shape the runner writes it (a
# session line of the real ledger, trimmed to the keys around the two a reader of the spend reads);
# <cost> is raw JSON: a number, or the null the runner writes for the events that carry none.
spent() {
  printf '{"v":1,"ts":"2099-01-01T00:00:00-03:00","event":"%s","invocation":"run","project":"fixture","repo":"%s","mission":"%s","phase":"EXEC","rc":0,"cost_usd":%s}\n' \
    "$2" "$REPO" "$1" "$3"
}

# The decimal comma (see the header): the locale only when it is armed, empty otherwise.
NUM_POISON=pt_BR.UTF-8
[ "$(LC_ALL="$NUM_POISON" bash -c 'printf "%.2f" 8.5' 2>/dev/null)" != 8.50 ] || NUM_POISON=""

# budget_is <label> <rc> <want> <args...> — runs budget <args...> under NUM_POISON; appends to got
# unless it left <rc> and exactly one line on stdout that starts with <want> (a literal, never a
# pattern).
budget_is() {
  local label="$1" rc="$2" want="$3"; shift 3
  LC_ALL="$NUM_POISON" worker budget "$@"
  [ "$W_RC" = "$rc" ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$want"* ]] \
    || got="${got:+$got; }$label: rc $W_RC, '$W_OUT' (want rc $rc, '$want…')"
}

H=docs/handoffs

# --- R15: the campaign's missions and no other --------------------------------------------------
# Campaign b-sum owns three missions: two in the fixture repo, one only in a linked worktree of it
# (the shape of a mission in flight, whose folder reaches the campaign's checkout only with the
# merge), and the worktree carries a second copy of one of the two, which is still one mission.
# Their lines sum 8.50 — two sessions, a close, and an escalation that carries null. Around them,
# lines a looser reader would add: another campaign's (40), a campaign whose id starts with b-sum
# (100), a mission of no campaign (30), and a truncated line of one of the three. The same file
# answers through SDD_STATE_DIR and through $HOME/.sdd. A second repo sets HANDOFF_DIR to another
# folder and keeps a decoy mission of its campaign under docs/handoffs: only the declared one counts.
got=""
d="$(campaign b-sum pr "$FAR" 25 100)"
mission "$REPO" "$H" 20990101-b-one b-sum
mission "$REPO" "$H" 20990102-b-two b-sum
mission "$REPO" "$H" 20990103-b-other b-other
mission "$REPO" "$H" 20990104-b-longer b-sum-2
mission "$REPO" "$H" 20990105-b-none -
git -C "$REPO" -c user.name=fixture -c user.email=fixture@example.com commit -q --allow-empty -m fixture
git -C "$REPO" worktree add -q -b fixture-side "$BOX/wt" > /dev/null 2>&1 \
  || got="fixture: the linked worktree was not created"
# A worktree carries the config its repo commits, and the fixture repo commits none: this one gets
# the campaign checkout's own, HANDOFF_DIR and pager and all, so b-sum, whose mission it holds and
# whose verbs therefore read its file (R44, R52), reads the same keys as in the campaign's checkout.
mkdir -p "$BOX/wt/.sdd"; cp "$REPO/.sdd/config.sh" "$BOX/wt/.sdd/config.sh"
mission "$BOX/wt" "$H" 20990106-b-wt b-sum
mission "$BOX/wt" "$H" 20990101-b-one b-sum
HD="$BOX/hd"
mkdir -p "$HD/.sdd" "$HD/docs/campaigns"
git init -q -b main "$HD"
printf 'HANDOFF_DIR="work/missions"\nON_ESCALATION_CMD="true"\n' > "$HD/.sdd/config.sh"
cp -a "$(campaign b-hd pr "$FAR" 25 100)" "$HD/docs/campaigns/"
mission "$HD" work/missions 20990107-b-hd-in b-hd
mission "$HD" "$H" 20990108-b-hd-decoy b-hd
mkdir -p "$BOX/state" "$BOX/home/.sdd"
{ spent 20990101-b-one session 1.25; spent 20990101-b-one session 2.5
  spent 20990102-b-two close 0.75; spent 20990102-b-two blocked null
  printf '{"v":1,"event":"session","mission":"20990101-b-one","cost_usd":\n'
  spent 20990103-b-other session 40; spent 20990104-b-longer session 100
  spent 20990105-b-none session 30; spent 20990106-b-wt session 4
  spent 20990107-b-hd-in session 2; spent 20990108-b-hd-decoy session 16
} > "$BOX/state/autonomy-log.jsonl"
cp "$BOX/state/autonomy-log.jsonl" "$BOX/home/.sdd/"
want='campaign US$ 8.50 of 100.00 — 3 mission(s); mission cap US$ 25'
budget_is 'SDD_STATE_DIR' 0 "$want" "$d"
( unset SDD_STATE_DIR; HOME="$BOX/home" budget_is 'HOME' 0 "$want" "$d"; printf '%s' "$got" > "$BOX/got" )
got="$(cat "$BOX/got")"
budget_is 'HANDOFF_DIR' 0 'campaign US$ 2.00 of 100.00 — 1 mission(s); mission cap US$ 25' \
  "$HD/docs/campaigns/b-hd"
if [ -z "$got" ]; then
  pass "budget: the sum counts the campaign's missions and no other"
else
  fail "budget: the sum counts the campaign's missions and no other" \
    "$want, and 2.00 over 1 mission where HANDOFF_DIR moves" "$got"
fi

# --- R16: at the ceiling or above it ------------------------------------------------------------
# Four delegations of one campaign, b-cap, whose two missions spent 8.50: a ceiling of 8.5 (at it)
# and of 8 (above it) leave rc 1, of 8.51 (the boundary) and of 10 (which a comparison of text puts
# below 8.5) leave rc 0. Each lives in a directory named b-cap, under a parent of its own, since
# the id is the directory's name (R35). The answers it cannot have ride along, each over a
# directory that answers rc 0 with the fixture's ledger, so the rc 1 is the break's: no delegation,
# a delegation with no campaign ceiling, the same campaign copied outside any git checkout, and a
# ledger that is a directory.
got=""
mission "$REPO" "$H" 20990111-b-cap-1 b-cap
mission "$REPO" "$H" 20990112-b-cap-2 b-cap
{ spent 20990111-b-cap-1 session 5.25; spent 20990112-b-cap-2 close 3.25; } >> "$BOX/state/autonomy-log.jsonl"
for w in 'b-at|8.5|1|8.50' 'b-above|8|1|8.00' 'b-edge|8.51|0|8.51' 'b-below|10|0|10.00'; do
  IFS='|' read -r id cap rc shown <<< "$w"
  d="$(campaign "$id/b-cap" pr "$FAR" 25 "$cap")"
  budget_is "$id" "$rc" "campaign US\$ 8.50 of $shown — 2 mission(s); mission cap US\$ 25" "$d"
done
mkdir -p "$REPO/docs/campaigns/b-absent"
budget_is 'no delegation' 1 'no ceiling — no delegation' "$REPO/docs/campaigns/b-absent"
d="$(campaign b-nocap/b-cap pr "$FAR" 25 -)"
budget_is 'no campaign ceiling' 1 'no ceiling — illegible: budget_campaign_usd' "$d"
mkdir -p "$BOX/loose"
cp -a "$REPO/docs/campaigns/b-below/b-cap" "$BOX/loose/"
git -C "$BOX/loose" rev-parse --show-toplevel > /dev/null 2>&1 \
  && got="${got:+$got; }fixture: $BOX/loose is inside a git checkout"
budget_is 'outside a checkout' 1 'no spend — ' "$BOX/loose/b-cap"
mkdir -p "$BOX/state-dir/autonomy-log.jsonl"
SDD_STATE_DIR="$BOX/state-dir" budget_is 'a ledger that does not read' 1 'no spend — ' \
  "$REPO/docs/campaigns/b-below/b-cap"
if [ -z "$got" ]; then
  pass 'budget: at the ceiling or above it the verb leaves rc 1'
else
  fail 'budget: at the ceiling or above it the verb leaves rc 1' \
    'rc 1 at 8.5 and 8, rc 0 at 8.51 and 10, rc 1 for each answer it cannot have' "$got"
fi

# --- R17: no ledger yet -------------------------------------------------------------------------
# One mission of the campaign and three ledgers that hold nothing: a state directory that does not
# exist, one with no ledger file, and an empty ledger. Each is zero spent and rc 0, and the line
# names the mission cap of this delegation, 37.5 as signed — R15 and R16 print 25, so a constant fails
# one of the two.
got=""
d="$(campaign b-fresh pr "$FAR" 37.5 200)"
mission "$REPO" "$H" 20990121-b-fresh b-fresh
mkdir -p "$BOX/state-empty" "$BOX/state-blank"
: > "$BOX/state-blank/autonomy-log.jsonl"
for s in state-none state-empty state-blank; do
  SDD_STATE_DIR="$BOX/$s" budget_is "$s" 0 \
    'campaign US$ 0.00 of 200.00 — 1 mission(s); mission cap US$ 37.5' "$d"
done
if [ -z "$got" ]; then
  pass 'budget: a missing ledger is zero spent, and the mission cap is printed'
else
  fail 'budget: a missing ledger is zero spent, and the mission cap is printed' \
    'campaign US$ 0.00 of 200.00 — 1 mission(s); mission cap US$ 37.5, rc 0, for each' "$got"
fi

# --- R37: the mission cap the runner applies ----------------------------------------------------
# The runner sources the repo's .sdd/config.sh over its environment (load_config in bin/sdd), so a
# file that assigns BUDGET_MISSION_USD beats the cap the session passes to `sdd run`, and the
# starter that `sdd install` writes assigns 150. Each world is one repo of its own holding campaign
# k-<world>, signed mission cap 40 and campaign cap 100, and no ledger line:
#   starter  the config `sdd install` writes from config/starter.conf, its own line active: rc 1
#   zero     BUDGET_MISSION_USD=0.00, no ceiling at all: rc 1
#   above    40.01, just over the signed cap — 150 against 40 as text would hold: rc 1
#   empty    BUDGET_MISSION_USD="", which the runner fills with its default: rc 1
#   equal    40, the signed cap itself: rc 0
#   below    12.5, the stricter ceiling, which holds: rc 0
#   default  BUDGET_MISSION_USD="${BUDGET_MISSION_USD:-150}", where the environment wins: rc 0
#   silent   no such line, under a caller that exports BUDGET_MISSION_USD=999: the session's own
#            value never reaches the reading, since `sdd run` gets the signed cap: rc 0
#   noconf   no .sdd/config.sh at all: rc 0
# A stop names the file, the key and the value it sets. The starter's value is read from the
# starter here, so a starter that changes its default moves the expectation, never the reach.
got=""
cap_world() {
  local k="$BOX/cap-$1"
  mkdir -p "$k/docs/campaigns"
  git init -q -b main "$k"
  if [ "$1" != noconf ]; then mkdir -p "$k/.sdd"; printf '%s\n' "$2" > "$k/.sdd/config.sh"; fi
  cp -a "$(campaign "k-$1" pr "$FAR" 40 100)" "$k/docs/campaigns/"
  printf '%s\n' "$k/docs/campaigns/k-$1"
}
sv="$(sed -n 's/^BUDGET_MISSION_USD=\([0-9.]*\).*/\1/p' "$ROOT/config/starter.conf")"
jq -en --arg s "$sv" '($s | tonumber) > 40' > /dev/null 2>&1 \
  || got="fixture: config/starter.conf sets no BUDGET_MISSION_USD above 40 ('$sv')"
d="$(cap_world starter '')"
sed -e 's|<PROJECT_NAME>|fixture|g' -e 's|<DEFAULT_BRANCH>|main|g' -e 's|<TEST_CMD>|true|g' \
  -e "s|<SDD_HOME>|$ROOT|g" "$ROOT/config/starter.conf" > "$BOX/cap-starter/.sdd/config.sh"
stop="no mission cap — $BOX/cap-starter/.sdd/config.sh sets BUDGET_MISSION_USD=$sv, "
budget_is starter 1 "$stop" "$d"
for w in 'zero|0.00' 'above|40.01' 'empty|'; do
  IFS='|' read -r id v <<< "$w"
  d="$(cap_world "$id" "BUDGET_MISSION_USD=\"$v\"")"
  want="no mission cap — $BOX/cap-$id/.sdd/config.sh sets BUDGET_MISSION_USD=$v, which sdd run applies over the signed budget_mission_usd: 40; delete the line, or set it above 0 and at most that"
  budget_is "$id" 1 "$want" "$d"
  [ "$W_OUT" = "$want" ] || got="${got:+$got; }$id: the line is '$W_OUT'"
done
held='campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 40'
for w in 'equal|BUDGET_MISSION_USD=40' 'below|BUDGET_MISSION_USD=12.5' \
         'default|BUDGET_MISSION_USD="${BUDGET_MISSION_USD:-150}"' 'noconf|'; do
  IFS='|' read -r id v <<< "$w"
  budget_is "$id" 0 "$held" "$(cap_world "$id" "$v")"
done
d="$(cap_world silent 'HANDOFF_DIR="docs/handoffs"')"
( export BUDGET_MISSION_USD=999
  [ "$(bash -c 'printf %s "${BUDGET_MISSION_USD-}"')" = 999 ] \
    || got="${got:+$got; }fixture: the exported 999 does not reach a child"
  budget_is silent 0 "$held" "$d"; printf '%s' "$got" > "$BOX/got" )
got="$(cat "$BOX/got")"
if [ -z "$got" ]; then
  pass 'cap: a repo config that sets BUDGET_MISSION_USD above the signed mission cap, or to 0, stops budget and names the key'
else
  fail 'cap: a repo config that sets BUDGET_MISSION_USD above the signed mission cap, or to 0, stops budget and names the key' \
    "rc 1 naming the file and BUDGET_MISSION_USD=<value> for the starter, 0.00, 40.01 and empty; rc 0 and the mission cap 40 for 40, 12.5, the default form, no line and no config" "$got"
fi

# --- next: the fixtures -------------------------------------------------------------------------
# lot_mission <checkout> <id> <campaign> <lot> <branch> <approval> — a mission folder of <campaign>
# and <lot> under the checkout's docs/handoffs, made from the kit's own template; an <approval> of
# `-` leaves aprovacao: empty and `=` keeps the template's placeholder. Only the frontmatter is
# edited, so a template whose lot: or branch: key moved leaves its placeholder and the probe that
# finds the mission goes red.
lot_mission() {
  local ap="$6"
  [ "$ap" != - ] || ap=""
  mkdir -p "$1/$H/$2"
  sed "2,/^---\$/ {
         s@^missao: .*@missao: $2@
         s@^campaign: .*@campaign: $3@
         s@^lot: .*@lot: $4@
         s@^branch: .*@branch: $5@
       }" "$ROOT/templates/missao.md" > "$1/$H/$2/00-missao.md"
  [ "$ap" = = ] || sed -i "2,/^---\$/ s@^aprovacao: .*@aprovacao: $ap@" "$1/$H/$2/00-missao.md"
}

# The gh stub answers the one question next asks, `gh pr list --head <branch> --state all --json
# <fields>`, from $BOX/prs/<branch>: a JSON array in the shape the real gh printed on 2026-11-18 for
# `gh pr list --head feat/o-revisor-so-acha --state all --json number,state,isCrossRepository` in
# this repo (`[{"isCrossRepository":false,"number":34,"state":"MERGED"}]`; a pull request from a
# fork, the same call on cli/cli: `{"isCrossRepository":true,"number":15089,"state":"CLOSED"}`), or
# `[]` when there is no file, which is what it prints for a head with no pull request. Like the
# real gh it prints only the fields --json asks for, so a caller that does not ask for
# isCrossRepository cannot tell a fork's pull request from one of the repo; a field it does not
# know is refused. Without --state all it keeps only the OPEN ones, as the real gh does by default.
# A <branch>.fail beside the file makes it fail, and a <branch>.raw is printed as it is. It answers
# only from the root of the fixture repo, which is where gh infers the repository from.
mkdir -p "$BOX/stub" "$BOX/prs"
REPO_REAL="$(CDPATH='' cd "$REPO" && pwd -P)"
{ printf '#!/usr/bin/env bash\nroot=%q\nbox=%q\n' "$REPO_REAL" "$BOX"
  cat <<'STUB'
[ "$(pwd -P)" = "$root" ] || { echo "gh stub: run from $(pwd -P), not the repo root" >&2; exit 9; }
[ "${1:-} ${2:-}" = "pr list" ] || { echo "gh stub: unexpected call: $*" >&2; exit 9; }
shift 2
head="" all="" fields=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --head) head="$2"; shift 2 ;;
    --state) [ "$2" != all ] || all=1; shift 2 ;;
    --json) fields="$2"; shift 2 ;;
    *) echo "gh stub: unexpected argument $1" >&2; exit 9 ;;
  esac
done
[ -n "$head" ] || { echo "gh stub: no --head" >&2; exit 9; }
[ -n "$fields" ] || { echo "gh stub: no --json" >&2; exit 9; }
for k in ${fields//,/ }; do
  case "$k" in number | state | isCrossRepository) : ;; *) echo "gh stub: --json field $k" >&2; exit 9 ;; esac
done
f="$box/prs/$head"
[ ! -e "$f.fail" ] || { echo "HTTP 502: Bad Gateway" >&2; exit 1; }
[ ! -e "$f.raw" ] || { cat "$f.raw"; exit 0; }
[ -e "$f" ] || { echo '[]'; exit 0; }
jq -c --arg f "$fields" --arg all "$all" \
  '[.[] | select($all != "" or .state == "OPEN") | with_entries(select(.key | IN($f | split(",")[])))]' "$f"
STUB
} > "$BOX/stub/gh"
chmod +x "$BOX/stub/gh"

# prs <branch> <json> — what the stub answers for <branch>: <json> with isCrossRepository written
# first in every element that does not carry it, as false — a pull request of the repo itself, the
# shape of the real answer above. A fork's pull request is written with `"isCrossRepository":true`.
prs() { jq -c 'map({isCrossRepository: (.isCrossRepository // false)} + .)' <<< "$2" > "$BOX/prs/$1"; }

# next_is <label> <rc> <want> <ahead> <dir> — runs next over <dir> with the gh stub first on the
# PATH; appends to got unless it left <rc> and a first line on stdout that starts with <want> (a
# literal, never a pattern), followed by no other line when <ahead> is empty, or else by exactly the
# line <ahead>.
next_is() {
  local label="$1" rc="$2" want="$3" ahead="$4" l1 rest=""
  PATH="$BOX/stub:$PATH" worker next "$5"
  l1="${W_OUT%%$'\n'*}"
  [[ "$W_OUT" != *$'\n'* ]] || rest="${W_OUT#*$'\n'}"
  [ "$W_RC" = "$rc" ] && [[ "$l1" == "$want"* ]] && [ "$rest" = "$ahead" ] \
    || got="${got:+$got; }$label: rc $W_RC, '${W_OUT//$'\n'/ / }' (want rc $rc, '$want…'${ahead:+, then '$ahead'})"
}

N=20990200

# --- R18: no mission is planned, an empty approval is approved ----------------------------------
# Campaign n-plan has no mission on L1, and around it the missions a looser reader would take for
# it: another campaign's on L1, and this campaign's on L2 — each approved with a pull request open,
# so taking one for L1 answers review. Three missions are not approved: an empty aprovacao:, the
# template's placeholder (a value, which the runner's gate does not admit), and a mission whose copy
# in the campaign's checkout is approved while its copy in the linked worktree is not. None of the
# three has a pull request: a program that skipped the approval would answer run.
got=""
d="$(campaign n-plan pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 1))-n-other" n-other L1 n-other-b humano-2099-01-01
lot_mission "$REPO" "$((N + 2))-n-plan-l2" n-plan L2 n-plan-l2-b humano-2099-01-01
prs n-other-b '[{"number":11,"state":"OPEN"}]'
prs n-plan-l2-b '[{"number":12,"state":"OPEN"}]'
next_is 'no mission' 0 'plan L1 - — ' '' "$d"
for w in 'n-empty|-' 'n-placeholder|=' 'n-copies|humano-2099-01-01'; do
  IFS='|' read -r id a <<< "$w"
  d="$(campaign "$id" pr "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-'
  lot_mission "$REPO" "$((N + 3))-$id" "$id" L1 "$id-b" "$a"
  [ "$id" != n-copies ] || lot_mission "$BOX/wt" "$((N + 3))-$id" "$id" L1 "$id-b" -
  next_is "$id" 0 "approve L1 $((N + 3))-$id — " '' "$d"
done
if [ -z "$got" ]; then
  pass 'next: a lot with no mission is planned, and one with an empty approval is approved'
else
  fail 'next: a lot with no mission is planned, and one with an empty approval is approved' \
    'plan L1 - for the lot with no mission, approve L1 <mission> for each one not approved' "$got"
fi

# --- R19: approved with no pull request is run, an open one is reviewed -------------------------
# The mission of n-run lives only in the linked worktree, the shape of a lot in flight: a reader of
# the campaign's checkout alone would plan it again. The one of n-review is approved `auto` — the
# other spelling the runner's gate admits — and its branch has a closed pull request beside the open
# one, so the open one decides.
got=""
d="$(campaign n-run pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$BOX/wt" "$((N + 4))-n-run" n-run L1 n-run-b humano-2099-01-01
next_is 'approved, no pull request' 0 "run L1 $((N + 4))-n-run — " '' "$d"
d="$(campaign n-review pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$REPO" "$((N + 5))-n-review" n-review L1 n-review-b auto
prs n-review-b '[{"number":5,"state":"CLOSED"},{"number":7,"state":"OPEN"}]'
next_is 'an open pull request' 0 "review L1 $((N + 5))-n-review — " '' "$d"
if [ -z "$got" ]; then
  pass 'next: an approved mission with no pull request is run, and an open one is reviewed'
else
  fail 'next: an approved mission with no pull request is run, and an open one is reviewed' \
    'run L1 <mission> with no pull request, review L1 <mission> with one open' "$got"
fi

# --- R20: a merged lot is skipped, every lot merged is done -------------------------------------
# n-skip has L1 merged (the real answer, copied) and no mission on L2: the walk goes past L1 and
# plans L2. n-done has both lots merged, one beside a closed pull request, and a stray table under
# the last lot's heading, after the queue: a reader that did not end the queue at its table would
# read its rows as lots.
got=""
d="$(campaign n-skip pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 6))-n-skip" n-skip L1 n-skip-b humano-2099-01-01
prs n-skip-b '[{"number":34,"state":"MERGED"}]'
next_is 'L1 merged' 0 'plan L2 - — ' '' "$d"
d="$(campaign n-done pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
printf '\n| Lot | Title | Ceiling | Items |\n|---|---|---|---|\n| L9 | stray | - | 1 |\n' >> "$d/campaign.md"
lot_mission "$REPO" "$((N + 7))-n-done-1" n-done L1 n-done-1-b humano-2099-01-01
lot_mission "$REPO" "$((N + 8))-n-done-2" n-done L2 n-done-2-b humano-2099-01-01
prs n-done-1-b '[{"number":3,"state":"CLOSED"},{"number":35,"state":"MERGED"}]'
prs n-done-2-b '[{"number":36,"state":"MERGED"}]'
next_is 'every lot merged' 0 'done - - — ' '' "$d"
if [ -z "$got" ]; then
  pass 'next: a merged lot is skipped, and a campaign with every lot merged is done'
else
  fail 'next: a merged lot is skipped, and a campaign with every lot merged is done' \
    'plan L2 past a merged L1, done - - when every lot is merged' "$got"
fi

# --- R21: planned ahead -------------------------------------------------------------------------
# Ahead is the lot after the one that decides, and only when it has no mission: a run on L1 with no
# mission on L2; a review on L2 past a merged L1, with L3 and L4 empty (ahead names L3, never L2
# nor L4); a review on L1 whose L2 already has a mission (no ahead); an approve on L1 with L2 empty
# (no ahead: the lot does not run yet); and a run on the last lot (nothing ahead of it).
got=""
d="$(campaign n-ahead-run pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 9))-n-ahead-run" n-ahead-run L1 n-ahead-run-b humano-2099-01-01
next_is 'run, L2 empty' 0 "run L1 $((N + 9))-n-ahead-run — " 'ahead plan L2' "$d"
d="$(campaign n-ahead-rev pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-' 'L3:-' 'L4:-'
lot_mission "$REPO" "$((N + 10))-n-ahead-rev-1" n-ahead-rev L1 n-ahead-rev-1-b humano-2099-01-01
lot_mission "$REPO" "$((N + 11))-n-ahead-rev-2" n-ahead-rev L2 n-ahead-rev-2-b humano-2099-01-01
prs n-ahead-rev-1-b '[{"number":40,"state":"MERGED"}]'
prs n-ahead-rev-2-b '[{"number":41,"state":"OPEN"}]'
next_is 'review on L2, L3 empty' 0 "review L2 $((N + 11))-n-ahead-rev-2 — " 'ahead plan L3' "$d"
d="$(campaign n-ahead-taken pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 12))-n-ahead-taken-1" n-ahead-taken L1 n-ahead-taken-1-b humano-2099-01-01
lot_mission "$REPO" "$((N + 13))-n-ahead-taken-2" n-ahead-taken L2 n-ahead-taken-2-b -
prs n-ahead-taken-1-b '[{"number":42,"state":"OPEN"}]'
next_is 'review, L2 has a mission' 0 "review L1 $((N + 12))-n-ahead-taken-1 — " '' "$d"
d="$(campaign n-ahead-appr pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 14))-n-ahead-appr" n-ahead-appr L1 n-ahead-appr-b -
next_is 'approve, L2 empty' 0 "approve L1 $((N + 14))-n-ahead-appr — " '' "$d"
next_is 'run on the last lot' 0 "run L1 $((N + 4))-n-run — " '' "$REPO/docs/campaigns/n-run"
if [ -z "$got" ]; then
  pass 'next: while a lot runs, the next lot with no mission is planned ahead'
else
  fail 'next: while a lot runs, the next lot with no mission is planned ahead' \
    'ahead plan <the lot after the deciding one>, only under run or review and only when it is empty' "$got"
fi

# --- R22: gh that does not answer, and what stops -----------------------------------------------
# Six answers gh may give that are not read, each on L2 past a merged L1, so the verb has already
# printed nothing when gh fails: a failure, an empty answer with rc 0, text, an object, an object
# whose values are well-formed pull requests (read as a list it is a merged lot), and a state off
# the three — the last two carrying isCrossRepository, so each fails for its own reason (R54). Each
# is rc 3 with nothing on stdout and gh named on stderr — read as "no pull request" they would
# answer run. Then what stops (rc 1): a pull request closed without merge, two missions
# declaring one lot, an approved mission with no branch (gh asked about an empty head lists every
# pull request of the repo), a directory with no campaign.md, a campaign.md whose campaign: is
# empty, a campaign copied outside any git checkout, an empty queue — each of the last four over a
# queue whose L1 a reader that went on would plan; and a call of the wrong shape is rc 2.
got=""
for w in 'fail|' 'empty|' 'text|not json' 'object|{"message":"Not Found"}' \
         'keyed|{"51":{"isCrossRepository":false,"number":51,"state":"MERGED"}}' \
         'state|[{"isCrossRepository":false,"number":4,"state":"DRAFT"}]'; do
  IFS='|' read -r k raw <<< "$w"
  id="n-gh-$k"
  d="$(campaign "$id" pr "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L2:-'
  lot_mission "$REPO" "$((N + 15))-$id-1" "$id" L1 "$id-1-b" humano-2099-01-01
  lot_mission "$REPO" "$((N + 16))-$id-2" "$id" L2 "$id-2-b" humano-2099-01-01
  prs "$id-1-b" '[{"number":50,"state":"MERGED"}]'
  if [ "$k" = fail ]; then : > "$BOX/prs/$id-2-b.fail"; else printf '%s' "$raw" > "$BOX/prs/$id-2-b.raw"; fi
  PATH="$BOX/stub:$PATH" worker next "$d"
  [ "$W_RC" = 3 ] && [ -z "$W_OUT" ] && grep -q "gh pr list --head $id-2-b" <<< "$W_ERR" \
    || got="${got:+$got; }$id: rc $W_RC, stdout '${W_OUT//$'\n'/ / }', stderr '${W_ERR%%$'\n'*}'"
done
d="$(campaign n-closed pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 17))-n-closed" n-closed L1 n-closed-b humano-2099-01-01
prs n-closed-b '[{"number":9,"state":"CLOSED"}]'
next_is 'closed without merge' 1 "stop L1 $((N + 17))-n-closed — pull request closed without merge" '' "$d"
d="$(campaign n-two pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$REPO" "$((N + 18))-n-two-a" n-two L1 n-two-a-b humano-2099-01-01
lot_mission "$REPO" "$((N + 19))-n-two-b" n-two L1 n-two-b-b humano-2099-01-01
next_is 'two missions on one lot' 1 'stop L1 - — ' '' "$d"
d="$(campaign n-nobranch pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$REPO" "$((N + 20))-n-nobranch" n-nobranch L1 '' humano-2099-01-01
next_is 'no branch' 1 "stop L1 $((N + 20))-n-nobranch — " '' "$d"
mkdir -p "$REPO/docs/campaigns/n-nofile"
next_is 'no campaign.md' 1 'stop - - — ' '' "$REPO/docs/campaigns/n-nofile"
d="$(campaign n-noid pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
sed -i '2,/^---$/ s@^campaign: .*@campaign:@' "$d/campaign.md"
next_is 'empty campaign:' 1 'stop - - — ' '' "$d"
cp -a "$REPO/docs/campaigns/n-plan" "$BOX/loose/"
next_is 'outside a checkout' 1 'stop - - — ' '' "$BOX/loose/n-plan"
d="$(campaign n-noqueue pr "$FAR" 25 200)"
set_lots "$d/campaign.md"
next_is 'empty queue' 1 'stop - - — ' '' "$d"
for a in '' "$REPO/docs/campaigns/n-absent" "$REPO/docs/campaigns/n-run extra"; do
  read -ra args <<< "$a"
  PATH="$BOX/stub:$PATH" worker next ${args[@]+"${args[@]}"}
  [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" \
    || got="${got:+$got; }next '$a': rc $W_RC, stdout '${W_OUT%%$'\n'*}'"
done
if [ -z "$got" ]; then
  pass 'next: a gh that does not answer leaves rc 3, and a pull request closed without merge stops'
else
  fail 'next: a gh that does not answer leaves rc 3, and a pull request closed without merge stops' \
    'rc 3 and no act for each unread answer; stop with rc 1 for each world that stops' "$got"
fi

# --- pr-ready: the fixtures ---------------------------------------------------------------------
# One repo for every world, its history the shape pr-ready reads: Z0 holds the code (src/app.txt,
# src/old.txt) and the mission's 00-missao.md; Z1 changes src/app.txt; A moves src/old.txt into the
# mission folder; B commits two rounds, both naming A as the reviewed head, and a file whose name
# git quotes by default (λ.txt). B is the pull request's head, so A..B touches the mission folder
# alone, Z1..B carries the move and Z0..B the code. The
# review worlds edit the rounds on disk, where the verb reads them, and ready_reset puts the repo
# back; every gh world serves its own copy of the answers.
PRN=412
RR="$BOX/ready"
MD="$RR/$H/20990300-ready"
CODEX='chatgpt-codex-connector[bot]'
got=""
gitc() { git -C "$RR" -c user.name=fixture -c user.email=fixture@example.com "$@"; }

# round <file> <reviewed head> — a review round copied from templates/review.md: every row of the
# `### Overall Grade` table graded A (the bold of the Overall row kept) with a rationale RUN_RAT that
# is a sentence, the frontmatter's gate: filled with RUN_GATE, and `reviewed_head:` added under it —
# none when the head is `-`. The template ships its rationales and its gate: as fill-ins, which the
# review item refuses (R38).
RUN_RAT='measured, nothing to say'
RUN_GATE='tests/run-all.sh rc 0, the tree clean'
round() {
  sed -e "2,/^---\$/ s@^gate: .*@gate: $RUN_GATE\nreviewed_head: $2@" \
      -e "s@| <A> | <[^|]*> |@| A | $RUN_RAT |@" \
      -e "s@| \*\*<A>\*\* | <[^|]*> |@| **A** | $RUN_RAT |@" "$ROOT/templates/review.md" > "$1"
  [ "$2" != - ] || sed -i '2,/^---$/ { /^reviewed_head:/d }' "$1"
}

mkdir -p "$RR/src"
git init -q -b main "$RR"
printf 'one\n' > "$RR/src/app.txt"; printf 'old\n' > "$RR/src/old.txt"
lot_mission "$RR" 20990300-ready r-camp L1 ready-b humano-2099-01-01
gitc add -A; gitc commit -q -m z0; Z0="$(git -C "$RR" rev-parse HEAD)"
printf 'two\n' > "$RR/src/app.txt"; gitc commit -q -am z1; Z1="$(git -C "$RR" rev-parse HEAD)"
gitc mv src/old.txt "$H/20990300-ready/old.txt"; gitc commit -q -m a; A="$(git -C "$RR" rev-parse HEAD)"
round "$MD/40-review-r1.md" "$A"; round "$MD/40-review-r2.md" "$A"; printf 'n\n' > "$MD/λ.txt"
gitc add -A; gitc commit -q -m b; B="$(git -C "$RR" rev-parse HEAD)"
RR_REAL="$(CDPATH='' cd "$RR" && pwd -P)"
# The fixture is the world it claims: four distinct commits, and a round whose grades are A.
[ "$(printf '%s\n' "$Z0" "$Z1" "$A" "$B" | sort -u | grep -c '^[0-9a-f]\{40\}$')" = 4 ] \
  || got="fixture: the four commits of the ready repo were not made"
[ "$(grep -c '^| [A-Za-z*][^|]* | \**A\** |' "$MD/40-review-r2.md")" = 8 ] \
  || got="${got:+$got; }fixture: the round copied from templates/review.md does not grade eight rows A"
[ "$(grep -c " | $RUN_RAT |\$" "$MD/40-review-r2.md")" = 8 ] && grep -qx "gate: $RUN_GATE" "$MD/40-review-r2.md" \
  || got="${got:+$got; }fixture: the round does not justify its eight rows and fill its gate:"

# ready_reset — the ready repo at B, its two rounds as committed and nothing else on disk, and B the
# head a world is served with (HEADNOW).
ready_reset() {
  rm -f "$MD"/40-review-r*.md "$RR"/40-review-r*.md "$MD/note.md"; gitc reset -q --hard "$B"
  HEADNOW="$B"
}
HEADNOW="$B"

# The receipt is the real one: the body of the comment the Codex bot left on PR 409 of this repo,
# saved on 2026-11-17 by
#   gh api repos/j0ruge/sdd_agents/issues/409/comments --jq '[.[] | select(.user.login ==
#     "chatgpt-codex-connector[bot]" and (.body | contains("codex-review-state:v1")))] | last | .body'
# into tests/fixtures/codex-review-state.txt; a world swaps its sha (and the short one in the table)
# for the one it names, and may edit it further with a sed script.
RECEIPT="$ROOT/tests/fixtures/codex-review-state.txt"
REAL_SHA=a0bf8e9d8f09a88c8997bbf8356fca7a1d5ed6cd
grep -q "\"code_review\":{\"commit_sha\":\"$REAL_SHA\"" "$RECEIPT" \
  || got="${got:+$got; }fixture: $RECEIPT carries no code_review receipt for $REAL_SHA"
# comment <login> <sha> <sed> — one issue comment as gh api prints it, trimmed to user.login and body,
# carrying the receipt for <sha> edited by <sed> (empty for none).
comment() {
  jq -cn --arg l "$1" --arg b "$(sed -e "s/$REAL_SHA/$2/g" -e "s/\`${REAL_SHA:0:7}\`/\`${2:0:7}\`/" \
    -e "$3" "$RECEIPT")" '{user: {login: $l}, body: $b}'
}

# serve <world> [<head>] — the gh answers of pull request #PRN for <world>, every item true: open and
# mergeable, with <head> (B when none is given) as the head; the comments in two pages, written one
# array after the other as `gh api --paginate` prints them, the first page carrying an older receipt
# of the bot (for Z1) and a person's comment, the second the receipt for the head; two threads, both
# resolved, in the shape `gh api graphql` printed for PR 315 of this repo on 2026-11-17. The answers
# live in $BOX/ghfx/<world>.
serve() {
  local fx="$BOX/ghfx/$1" h="${2:-$B}"
  rm -rf "$fx"; mkdir -p "$fx"
  printf '%s\n' "$RR_REAL" > "$fx/root"
  printf '%s\n' "$PRN" > "$fx/number"
  printf 'j0ruge/fixture\n' > "$fx/repo"
  printf '{"headRefOid":"%s","mergeable":"MERGEABLE","state":"OPEN"}\n' "$h" > "$fx/view"
  printf '[%s,%s]' "$(comment "$CODEX" "$Z1" '')" '{"user":{"login":"j0ruge"},"body":"thanks"}' \
    > "$fx/comments.1"
  printf '[%s]' "$(comment "$CODEX" "$h" '')" > "$fx/comments.2"
  printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":2,"nodes":[{"isResolved":true},{"isResolved":true}]}}}}}' \
    > "$fx/threads"
}

# land <world> — the mission folder committed as the disk now has it, on top of the checkout's HEAD,
# and <world> served with that commit as the head (HEADNOW): a round a world writes is the round the
# pull request head carries, since the review item refuses a mission folder with a change not
# committed (R46). The commit touches the mission folder alone, so the range after the reviewed head
# stays the folder's (R47).
land() {
  gitc add -A -- "$H/20990300-ready"
  gitc commit -q --allow-empty -m world
  HEADNOW="$(git -C "$RR" rev-parse HEAD)"
  serve "$1" "$HEADNOW"
}

# The gh stub of pr-ready answers the four questions the verb asks, from the world GHFX names, and
# only from the root of the ready repo: `pr view <n> --json headRefOid,mergeable,state`, `repo view
# --json nameWithOwner -q .nameWithOwner`, the comments (both pages under --paginate, the first page
# alone without it, as the real gh does) and the graphql query of the review threads, which has to
# name the owner, the repo and the pull request. A <answer>.fail in the world makes that answer fail,
# and a <answer>.partial makes it fail after printing the answer, as a gh that dies on a later page.
mkdir -p "$BOX/stub-ready"
cat > "$BOX/stub-ready/gh" <<'STUB'
#!/usr/bin/env bash
fx="${GHFX:?gh stub: GHFX names no world}"
[ "$(pwd -P)" = "$(cat "$fx/root")" ] || { echo "gh stub: run from $(pwd -P), not the repo root" >&2; exit 9; }
n="$(cat "$fx/number")"; repo="$(cat "$fx/repo")"
give() {
  local a="$1"; shift
  [ ! -e "$fx/$a.fail" ] || { echo "HTTP 502: Bad Gateway" >&2; exit 1; }
  cat "$@"
  [ ! -e "$fx/$a.partial" ] || { echo "HTTP 502: Bad Gateway" >&2; exit 1; }
  exit 0
}
case "$*" in
  "pr view $n --json headRefOid,mergeable,state") give view "$fx/view" ;;
  "repo view --json nameWithOwner -q .nameWithOwner") give repo "$fx/repo" ;;
  "api --paginate repos/$repo/issues/$n/comments") give comments "$fx/comments.1" "$fx/comments.2" ;;
  "api repos/$repo/issues/$n/comments") give comments "$fx/comments.1" ;;
  "api graphql -f query="*"owner:\"${repo%%/*}\",name:\"${repo#*/}\""*"pullRequest(number:$n)"*) give threads "$fx/threads" ;;
esac
echo "gh stub: unexpected call: $*" >&2
exit 9
STUB
chmod +x "$BOX/stub-ready/gh"

# ready_is <label> <rc> <want> <world> [<mission dir>] — runs pr-ready over the mission folder (the
# ready repo's when none is given) and pull request #PRN, with the stub first on the PATH serving
# <world>; appends to got unless it left <rc> and exactly one line on stdout that starts with <want>
# (a literal, never a pattern).
ready_is() {
  export GHFX="$BOX/ghfx/$4"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "${5:-$MD}" "$PRN"
  [ "$W_RC" = "$2" ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$3"* ]] \
    || got="${got:+$got; }$1: rc $W_RC, '${W_OUT//$'\n'/ / }' (want rc $2, '$3…'; stderr '${W_ERR%%$'\n'*}')"
}

# --- R23: all five true at one sha --------------------------------------------------------------
# The good world; the same world with its rounds renamed r9 and r10 and the r9 graded B (the newest
# is r10 by number, and a glob, which sorts r10 first, would read the B); and a round naming the
# commit under it, committed on top of B — the worker's own flow: the round names the HEAD it read,
# and the commit that carries it is the head. Each world's rounds are committed (land): the review
# item reads the round the head carries.
serve good
ready_is 'all five true' 0 "ready $B" good
[ "$W_OUT" = "ready $B" ] || got="${got:+$got; }the line is '$W_OUT', not 'ready $B'"
mv "$MD/40-review-r2.md" "$MD/40-review-r10.md"; mv "$MD/40-review-r1.md" "$MD/40-review-r9.md"
sed -i 's@^| Security | A |@| Security | B |@' "$MD/40-review-r9.md"
grep -q '^| Security | B |' "$MD/40-review-r9.md" || got="${got:+$got; }fixture: r9 was not graded B"
land good-r10
ready_is 'r10 after an r9 graded B' 0 "ready $HEADNOW" good-r10
ready_reset
round "$MD/40-review-r2.md" "$B"
land good-under
ready_is 'a round naming the commit under it' 0 "ready $HEADNOW" good-under
[ "$(git -C "$RR" rev-parse "$HEADNOW^")" = "$B" ] || got="${got:+$got; }fixture: the round's commit is not on B"
ready_reset
if [ -z "$got" ]; then
  pass 'pr-ready: all five true at one sha answers ready with the full sha'
else
  fail 'pr-ready: all five true at one sha answers ready with the full sha' "ready $B, rc 0" "$got"
fi

# --- R24: the review item -----------------------------------------------------------------------
# Each world breaks the newest round (r2) and leaves r1 — graded A, naming A — as it is, so a reader
# of any round but the newest answers ready. Every other item is true in the good world.
got=""
sed -i 's@^| Security | A |@| Security | B |@' "$MD/40-review-r2.md"
grep -q '^| Security | B |' "$MD/40-review-r2.md" || got="fixture: r2 was not graded B"
ready_is 'Security B' 1 'not-ready review: ' good; ready_reset
sed -i 's@^| \*\*Overall\*\* | \*\*A\*\* |@| **Overall** | **A-** |@' "$MD/40-review-r2.md"
grep -qF '| **Overall** | **A-** |' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: r2 Overall was not A-"
ready_is 'Overall A-' 1 'not-ready review: ' good; ready_reset
sed -i 's@^| Security | A |@   | Security | B |@' "$MD/40-review-r2.md"
grep -q '^   | Security | B |' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: r2 has no indented B"
ready_is 'an indented row graded B' 1 'not-ready review: ' good; ready_reset
round "$MD/40-review-r2.md" -
ready_is 'no reviewed head' 1 'not-ready review: the newest round names no head' good; ready_reset
round "$MD/40-review-r2.md" HEAD
ready_is 'HEAD as the reviewed head' 1 'not-ready review: ' good; ready_reset
round "$MD/40-review-r2.md" deadbeefdead
ready_is 'a sha that is no commit' 1 "not-ready review: the reviewed head 'deadbeefdead'" good; ready_reset
round "$MD/40-review-r2.md" "$Z0"
ready_is 'code after the reviewed head' 1 'not-ready review: src/app.txt ' good; ready_reset
round "$MD/40-review-r2.md" "$Z1"
ready_is 'a move into the mission folder' 1 'not-ready review: src/old.txt ' good; ready_reset
rm -f "$MD"/40-review-r*.md
ready_is 'no round' 1 'not-ready review: ' good; ready_reset
sed -i 's@^### Overall Grade@### Grades@' "$MD/40-review-r2.md"
grep -q '^### Grades' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: r2 kept its grade heading"
ready_is 'no grade table' 1 'not-ready review: ' good; ready_reset
# The head the pull request names is not in this checkout, receipt and all: only the review item
# can say so, since the ancestry it reads does not run.
UNFETCHED=0000000000000000000000000000000000000007
serve r-unfetched
printf '{"headRefOid":"%s","mergeable":"MERGEABLE","state":"OPEN"}\n' "$UNFETCHED" > "$BOX/ghfx/r-unfetched/view"
printf '[%s]' "$(comment "$CODEX" "$UNFETCHED" '')" > "$BOX/ghfx/r-unfetched/comments.2"
ready_is 'a head not fetched' 1 'not-ready review: git merge-base --is-ancestor ' r-unfetched
# The mission folder given as the root of the checkout: every path is under it.
round "$RR/40-review-r2.md" "$A"
ready_is 'the root as the mission folder' 1 'not-ready review: the mission folder ' good "$RR"; ready_reset
mkdir -p "$BOX/loose-ready"; cp -a "$MD" "$BOX/loose-ready/"
ready_is 'outside a checkout' 1 'not-ready review: ' good "$BOX/loose-ready/20990300-ready"
if [ -z "$got" ]; then
  pass 'pr-ready: a grade below A, a round that names no head, and code after the reviewed head each fail review'
else
  fail 'pr-ready: a grade below A, a round that names no head, and code after the reviewed head each fail review' \
    'rc 1 and not-ready review: … for each world' "$got"
fi

# --- R25: the codex item ------------------------------------------------------------------------
# Each world edits the second page of the good one; the witness is that the page changed. With no
# receipt at all, both pages carry only a person's comment. The spoof is a receipt for the head that
# a person posted after the bot's newest, which is for Z1. A null for the unresolved findings is not
# a false, and a newest receipt whose state does not parse says nothing, so the good receipt before
# it is never the one read.
got=""
for w in "c-sha|$CODEX|$A|" "c-unfinished|$CODEX|$B|s/\"status\":\"completed\"/\"status\":null/" \
         "c-finding|$CODEX|$B|s/\"has_unresolved_findings\":false/\"has_unresolved_findings\":true/" \
         "c-finding-null|$CODEX|$B|s/\"has_unresolved_findings\":false/\"has_unresolved_findings\":null/" \
         "c-spoof|j0ruge|$B|" "c-unreadable|$CODEX|$B|s/\"has_any_findings\":false,/\"has_any_findings\":,/"; do
  IFS='|' read -r fx who sha ed <<< "$w"
  serve "$fx"
  printf '[%s]' "$(comment "$who" "$sha" "$ed")" > "$BOX/ghfx/$fx/comments.2"
  cmp -s "$BOX/ghfx/good/comments.2" "$BOX/ghfx/$fx/comments.2" && got="${got:+$got; }fixture: $fx is the good page"
  # Unreadable: the page before carries a good receipt for the head, which only a skip would read.
  [ "$fx" != c-unreadable ] || printf '[%s]' "$(comment "$CODEX" "$B" '')" > "$BOX/ghfx/$fx/comments.1"
  ready_is "$fx" 1 'not-ready codex: ' "$fx"
done
serve c-none
printf '[%s]' '{"user":{"login":"j0ruge"},"body":"thanks"}' > "$BOX/ghfx/c-none/comments.1"
printf '[]' > "$BOX/ghfx/c-none/comments.2"
ready_is 'no receipt' 1 'not-ready codex: ' c-none
if [ -z "$got" ]; then
  pass 'pr-ready: a receipt for another sha, an unfinished one and an unresolved finding each fail codex'
else
  fail 'pr-ready: a receipt for another sha, an unfinished one and an unresolved finding each fail codex' \
    'rc 1 and not-ready codex: … for each world' "$got"
fi

# --- R26: the threads item ----------------------------------------------------------------------
got=""
serve t-open
printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":2,"nodes":[{"isResolved":true},{"isResolved":false}]}}}}}' \
  > "$BOX/ghfx/t-open/threads"
ready_is 'one open thread' 1 'not-ready threads: ' t-open
serve t-unseen
jq -cn '{data: {repository: {pullRequest: {reviewThreads: {totalCount: 101, nodes: [range(100) | {isResolved: true}]}}}}}' \
  > "$BOX/ghfx/t-unseen/threads"
ready_is 'a thread past the hundred read' 1 'not-ready threads: ' t-unseen
if [ -z "$got" ]; then
  pass 'pr-ready: one open thread fails threads'
else
  fail 'pr-ready: one open thread fails threads' 'rc 1 and not-ready threads: … for each world' "$got"
fi

# --- R27: the mergeable item --------------------------------------------------------------------
got=""
for w in 'm-conflict|CONFLICTING|OPEN' 'm-closed|MERGEABLE|CLOSED' 'm-merged|UNKNOWN|MERGED'; do
  IFS='|' read -r fx mg st <<< "$w"
  serve "$fx"
  printf '{"headRefOid":"%s","mergeable":"%s","state":"%s"}\n' "$B" "$mg" "$st" > "$BOX/ghfx/$fx/view"
  ready_is "$fx" 1 'not-ready mergeable: ' "$fx"
done
if [ -z "$got" ]; then
  pass 'pr-ready: a conflicting or closed pull request fails mergeable'
else
  fail 'pr-ready: a conflicting or closed pull request fails mergeable' \
    'rc 1 and not-ready mergeable: … for each world' "$got"
fi

# --- R28: the head item -------------------------------------------------------------------------
# Ahead: a local commit on top of B. Behind: the pull request head a commit on top of B that adds a
# note to the mission folder, and the checkout back at B, whose rounds are committed, so the review
# item still reads them and its folder is clean.
got=""
serve h-local
printf 'note\n' > "$MD/note.md"; gitc add -A; gitc commit -q -m c
ready_is 'local HEAD ahead' 1 'not-ready head: ' h-local; ready_reset
printf 'note\n' > "$MD/note.md"; land h-behind; gitc reset -q --hard "$B"
[ ! -e "$MD/note.md" ] || got="${got:+$got; }fixture: the checkout did not go back to B"
ready_is 'local HEAD behind' 1 'not-ready head: ' h-behind; ready_reset
[ "$(git -C "$RR" rev-parse HEAD)" = "$B" ] || got="${got:+$got; }fixture: the ready repo did not go back to B"
if [ -z "$got" ]; then
  pass 'pr-ready: a local HEAD that is not the pull request head fails head'
else
  fail 'pr-ready: a local HEAD that is not the pull request head fails head' \
    'rc 1 and not-ready head: … for each world' "$got"
fi

# --- R29: a gh that does not answer, and the wrong shape ----------------------------------------
# Each world breaks one answer of the good one, so only that answer stands between it and ready:
# a failure, a failure after a full answer was printed (a gh that dies on a later page), or an answer
# off the contract — text, a short sha, a name with no owner, an object for the pages (one keyed by
# comments whose receipt is good, read as a list it is ready), nothing at all, a graphql error, and
# threads with no count, keyed instead of listed, or of unknown resolution. Each is rc 3, nothing on
# stdout, the call named on stderr. Then the calls of the wrong shape, rc 2 with the usage.
for w in 'g-view-fail|view|FAIL|gh pr view' 'g-view-rc|view|RC|gh pr view' 'g-view-text|view|not json|gh pr view' \
         'g-view-short|view|{"headRefOid":"a0bf8e9","mergeable":"MERGEABLE","state":"OPEN"}|gh pr view' \
         'g-repo-fail|repo|FAIL|gh repo view' 'g-repo-rc|repo|RC|gh repo view' \
         'g-repo-name|repo|fixture|gh repo view' \
         'g-comments-fail|comments|FAIL|gh api --paginate' 'g-comments-rc|comments|RC|gh api --paginate' \
         'g-comments-keyed|comments.1|KEYED|gh api --paginate' \
         'g-comments-object|comments.1|{"message":"Not Found"}|gh api --paginate' \
         'g-comments-empty|comments.1||gh api --paginate' \
         'g-threads-fail|threads|FAIL|gh api graphql' 'g-threads-rc|threads|RC|gh api graphql' \
         'g-threads-error|threads|{"data":null,"errors":[{"message":"Could not resolve"}]}|gh api graphql' \
         'g-threads-nocount|threads|{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true}]}}}}}|gh api graphql' \
         'g-threads-keyed|threads|{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":1,"nodes":{"x":{"isResolved":true}}}}}}}|gh api graphql' \
         'g-threads-unknown|threads|{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":1,"nodes":[{"isResolved":null}]}}}}}|gh api graphql'; do
  IFS='|' read -r fx file body what <<< "$w"
  serve "$fx"
  if [ "$body" = FAIL ]; then
    : > "$BOX/ghfx/$fx/$file.fail"
  elif [ "$body" = RC ]; then
    : > "$BOX/ghfx/$fx/$file.partial"
  elif [ "$body" = KEYED ]; then
    printf '{"1":%s}' "$(comment "$CODEX" "$B" '')" > "$BOX/ghfx/$fx/comments.1"
    : > "$BOX/ghfx/$fx/comments.2"
  else
    printf '%s' "$body" > "$BOX/ghfx/$fx/$file"
    [ "$file" != comments.1 ] || : > "$BOX/ghfx/$fx/comments.2"
  fi
  export GHFX="$BOX/ghfx/$fx"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  [ "$W_RC" = 3 ] && [ -z "$W_OUT" ] && grep -qF "sdd-worker: $what" <<< "$W_ERR" \
    || got="${got:+$got; }$fx: rc $W_RC, stdout '${W_OUT//$'\n'/ / }', stderr '${W_ERR%%$'\n'*}'"
done
export GHFX="$BOX/ghfx/good"
for a in '' "$MD" "$MD|12a" "$MD|#412" "$MD|0" "$RR/nowhere|$PRN" "$MD|$PRN|extra"; do
  IFS='|' read -ra args <<< "$a"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready ${args[@]+"${args[@]}"}
  [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" \
    || got="${got:+$got; }pr-ready '$a': rc $W_RC, stdout '${W_OUT%%$'\n'*}'"
done
if [ -z "$got" ]; then
  pass 'pr-ready: a gh that does not answer leaves rc 3 and never ready'
else
  fail 'pr-ready: a gh that does not answer leaves rc 3 and never ready' \
    'rc 3, nothing on stdout and the call on stderr for each unread answer; rc 2 for each wrong shape' "$got"
fi

# --- command: the session's command -------------------------------------------------------------
# commands/sdd-worker.md is prose an interactive session follows, so these probes read the file, one
# phrase per markdown line. Each checker prints what the file misses, one item per line; each
# assertion runs it on the file (nothing missed) and on copies with one thing taken out, built here
# from the file and anchored on its text, where it has to name that thing.
COMMAND="$ROOT/commands/sdd-worker.md"

# command_verbs — the verbs bin/sdd-worker dispatches, one per line, read from the case of its
# main(): the program is the source, so a verb it gains is a verb the command has to name.
command_verbs() { sed -n '/^main() {$/,/^}$/ s/^    \([a-z][a-z-]*\)) shift; cmd_.*/\1/p' "$WORKER"; }

# section <file> <heading> — the lines under `## <heading>`, up to the next `## `.
section() { awk -v h="## $2" '$0 == h { on = 1; next } on && /^## / { exit } on' "$1"; }

# verbs_missing <file> — each verb the file never writes as a call: `sdd-worker <verb>` followed by
# a space, a backtick or the end of the line, so `sdd-worker budgets` is no call of budget.
verbs_missing() {
  local v
  while IFS= read -r v; do
    grep -qE "sdd-worker $v( |\`|\$)" "$1" 2>/dev/null || printf '%s\n' "$v"
  done < <(command_verbs)
}

# acts_unpreceded <file> — each act of ACT_TABLE whose heading `### \`<act>\`` is not in the file
# exactly once, or whose first non-blank line under it is not its allows call, written whole.
acts_unpreceded() {
  local row act n first
  for row in "${ACT_TABLE[@]}"; do
    act="${row%% *}"
    n="$(grep -cxF "### \`$act\`" "$1" 2>/dev/null)"
    first="$(awk -v h="### \`$act\`" '$0 == h { on = 1; next } on && NF { print; exit }' "$1" 2>/dev/null)"
    [ "$n" = 1 ] && [ "$first" = "\`sdd-worker allows <campaign-dir> $act --lot <L>\`" ] \
      || printf '%s\n' "$act"
  done
}

# prose_missing <file> — what three sections do not write. The five stops: exactly five numbered
# lines, each phrase on one of them, the pager and the journal in the section. The never list and
# the context rules: each phrase on a bullet of its own section, the last rule naming both verbs a
# new session resumes from. A phrase found only in another section is missing.
prose_missing() {
  local s items p
  s="$(section "$1" 'The five stops' 2>/dev/null)"
  items="$(grep -E '^[0-9]+\. ' <<< "$s")"
  [ "$(grep -c . <<< "$items")" = 5 ] || printf 'stops: not five numbered lines\n'
  for p in '60 minutes' 'three rounds' 'merge conflict' 'BUDGET_MISSION_USD' 'sdd-worker budget'; do
    grep -qF "$p" <<< "$items" || printf 'stops: %s\n' "$p"
  done
  for p in ON_ESCALATION_CMD journal.md; do grep -qF "$p" <<< "$s" || printf 'stops: %s\n' "$p"; done
  items="$(section "$1" 'Never' 2>/dev/null | grep '^- ')"
  for p in 'Delete a branch or a worktree' 'Push to the base branch' 'visual acceptance' "kit's main checkout"; do
    grep -qF "$p" <<< "$items" || printf 'never: %s\n' "$p"
  done
  items="$(section "$1" 'Context' 2>/dev/null | grep '^- ')"
  for p in 'One line per event' 'returns only its verdict' 'a handoff to a file'; do
    grep -qF "$p" <<< "$items" || printf 'context: %s\n' "$p"
  done
  items="$(grep -F 'sdd-worker level' <<< "$items")"
  grep -qF 'sdd-worker next' <<< "$items" || printf 'context: resumes from level and next\n'
}

# control <label> <checker> <want> <sed script> — runs <checker> on a copy of the command edited by
# <sed script>; appends to got unless the checker printed exactly <want>, one item per line, never
# empty. A sed that stops matching leaves the copy equal to the file, where the checker prints
# nothing: that is not <want>, so the control goes red instead of passing on a copy it never edited.
control() {
  local label="$1" checker="$2" want="$3" out
  sed "$4" "$COMMAND" > "$BOX/command-copy" 2>/dev/null
  out="$("$checker" "$BOX/command-copy")"
  [ "$out" = "$want" ] || got="${got:+$got; }$label: printed '${out//$'\n'/, }' (want '${want//$'\n'/, }')"
}

# --- R30: every verb is named -------------------------------------------------------------------
# The floor of six is the probe of the parse: a main() whose case changes shape (an arm split over
# two lines) hides that verb from command_verbs, and a verb the parse misses is one nobody checks —
# measured, level split that way left the controls green and only this floor red.
got=""
verbs="$(command_verbs)"
[ "$(grep -c . <<< "$verbs")" -ge 6 ] || got="the program dispatches '${verbs//$'\n'/ }', not the six verbs"
m="$(verbs_missing "$COMMAND")"
[ -z "$m" ] || got="${got:+$got; }not named: ${m//$'\n'/ }"
control 'no budget call' verbs_missing budget 's/sdd-worker budget/sdd-worker budgets/g'
control 'no pr-ready call' verbs_missing pr-ready 's/sdd-worker pr-ready/sdd-worker pr_ready/g'
# The primitive under every control, against an answer known wrong: told to want level from a copy
# whose checker prints budget, control() has to append, or each control above passes on anything.
saved="$got"
control 'the primitive' verbs_missing level 's/sdd-worker budget/sdd-worker budgets/g'
[ "$got" != "$saved" ] || saved="${saved:+$saved; }control() let a copy printing budget pass as level"
got="$saved"
if [ -z "$got" ]; then
  pass 'command: it names every verb of bin/sdd-worker'
else
  fail 'command: it names every verb of bin/sdd-worker' \
    'a call of each verb of main(), and each copy with one call taken out naming that verb' "$got"
fi

# --- R31: each act starts with its allows call --------------------------------------------------
# The seven are ACT_TABLE's, whose size R11 already witnesses by counting its 35 cells.
got=""
m="$(acts_unpreceded "$COMMAND")"
[ -z "$m" ] || got="not preceded: ${m//$'\n'/ }"
control 'review call deleted' acts_unpreceded review '/^`sdd-worker allows <campaign-dir> review --lot <L>`$/d'
control 'run call names plan' acts_unpreceded run 's/^`sdd-worker allows <campaign-dir> run --lot/`sdd-worker allows <campaign-dir> plan --lot/'
control 'plan call after prose' acts_unpreceded plan 's/^\(`sdd-worker allows <campaign-dir> plan --lot <L>`\)$/Plan first.\n\n\1/'
control 'approve call partial' acts_unpreceded approve 's/^`sdd-worker allows <campaign-dir> approve --lot <L>`$/`sdd-worker allows <campaign-dir> approve`/'
control 'merge heading twice' acts_unpreceded merge '$a\
\
### `merge`\
\
Merge by hand.'
if [ -z "$got" ]; then
  pass 'command: each of the seven acts is preceded by its allows call'
else
  fail 'command: each of the seven acts is preceded by its allows call' \
    'one heading per act whose first line is its allows call, and each sabotaged copy naming its act' "$got"
fi

# --- R32: the stops, the never list, the context rules ------------------------------------------
got=""
m="$(prose_missing "$COMMAND")"
[ -z "$m" ] || got="missing: ${m//$'\n'/, }"
control 'stop 1 deleted' prose_missing $'stops: not five numbered lines\nstops: 60 minutes' '/60 minutes/d'
control 'a sixth stop' prose_missing 'stops: not five numbered lines' '/^5\. /a\
6. **Another.** One more stop.'
control 'stop 4 not numbered' prose_missing $'stops: not five numbered lines\nstops: BUDGET_MISSION_USD' 's/^4\. \(.*BUDGET_MISSION_USD\)/\1/'
control 'no pager' prose_missing $'stops: ON_ESCALATION_CMD\nstops: journal.md' '/ON_ESCALATION_CMD/d'
control 'never: main checkout' prose_missing "never: kit's main checkout" "/^- Move the kit's main checkout/d"
control 'never: not a bullet' prose_missing 'never: visual acceptance' 's/^- \(Give the visual acceptance\)/\1/'
control 'context: handoff' prose_missing 'context: a handoff to a file' '/^- .*a handoff to a file/d'
control 'context: not a bullet' prose_missing 'context: One line per event' 's/^- \(One line per event\)/\1/'
control 'context: no next' prose_missing 'context: resumes from level and next' 's/^\(- A new session resumes from `sdd-worker level`\) and `sdd-worker next`/\1/'
control 'context: no level' prose_missing 'context: resumes from level and next' 's/^\(- A new session resumes from\) `sdd-worker level` and/\1/'
if [ -z "$got" ]; then
  pass 'command: the five stops, the never list and the context rules are written'
else
  fail 'command: the five stops, the never list and the context rules are written' \
    'every phrase on a line of its section, and each sabotaged copy naming what it lost' "$got"
fi

# --- docs: the documentation and the vocabulary -------------------------------------------------
# Four documents name the worker, and each is prose no mutant of bin/ reaches, so the checker carries
# its own negative control, like the command's. What each owes is read from the sensor's ladder and
# from the program's main(), never from a second list written here:
#   docs/pipeline.md  under `## The worker`, a call of every verb, and the ladder written in order
#   README.md         a line of the usage block starting `sdd-worker `, and a link to that section
#   config/schema.md  the ON_ESCALATION_CMD row names the worker and `assisted`; the
#                     BUDGET_MISSION_USD row names the worker
#   CONTEXT.md        a glossary row per term, found by the identifier its first cell carries in
#                     parentheses (the terms are pt-BR, the identifiers are not); the row of the level
#                     writes the ladder, and the worker's names the coordination helper, whose Bash
#                     worker is the other thing called a worker
DOC_FILES=(docs/pipeline.md README.md config/schema.md CONTEXT.md)
DOC_TERMS=(campaign.md lot: delegation.md level: bin/sdd-worker)

# ladder_line — the five levels as the documents write them: `assisted` < `pr` < ... < `full`.
ladder_line() { local l s=""; for l in "${LEVELS[@]}"; do s="${s:+$s < }\`$l\`"; done; printf '%s' "$s"; }

# glossary_row <file> <identifier> — the table rows whose first cell is a bold term followed by
# `(<identifier>)` as a code span, the shape of `| **Churn** (`churned`) |` in CONTEXT.md.
glossary_row() { grep -F "** (\`$2\`) |" "$1" 2>/dev/null | grep -E '^\| \*\*[^*|]+\*\* \(`'; }

# docs_missing <root> — what the four documents under <root> do not write, one item per line. A
# section that is not there is one item, not one per verb: the copy names its own break.
docs_missing() {
  local s v row t
  s="$(section "$1/docs/pipeline.md" 'The worker' 2>/dev/null)"
  if [ -z "$s" ]; then
    printf 'pipeline: no section\n'
  else
    printf '%s\n' "$s" > "$BOX/docs-section"
    while IFS= read -r v; do printf 'pipeline: verb %s\n' "$v"; done < <(verbs_missing "$BOX/docs-section")
    grep -qF "$(ladder_line)" <<< "$s" || printf 'pipeline: ladder\n'
  fi
  grep -qE '^sdd-worker ' "$1/README.md" 2>/dev/null || printf 'readme: command\n'
  grep -qF '(docs/pipeline.md#the-worker)' "$1/README.md" 2>/dev/null || printf 'readme: link\n'
  row="$(grep -E '^\| `ON_ESCALATION_CMD` \|' "$1/config/schema.md" 2>/dev/null)"
  { grep -qF 'sdd-worker' <<< "$row" && grep -qF '`assisted`' <<< "$row"; } || printf 'schema: ON_ESCALATION_CMD\n'
  row="$(grep -E '^\| `BUDGET_MISSION_USD` \|' "$1/config/schema.md" 2>/dev/null)"
  grep -qF 'sdd-worker' <<< "$row" || printf 'schema: BUDGET_MISSION_USD\n'
  for t in "${DOC_TERMS[@]}"; do
    [ -n "$(glossary_row "$1/CONTEXT.md" "$t")" ] || printf 'context: %s\n' "$t"
  done
  grep -qF "$(ladder_line)" <<< "$(glossary_row "$1/CONTEXT.md" level:)" || printf 'context: ladder\n'
  grep -qF 'sdd-coordination.py' <<< "$(glossary_row "$1/CONTEXT.md" bin/sdd-worker)" \
    || printf 'context: coordination\n'
}

# docs_control <label> <want> <file> <sed script> — runs docs_missing on a copy of the four documents
# in which <file> alone was edited by <sed script>; appends to got unless it printed exactly <want>.
# A sed that stops matching leaves a copy that misses nothing, which is not <want>: red.
docs_control() {
  local f out copy="$BOX/docs-copy"
  rm -rf "$copy"
  for f in "${DOC_FILES[@]}"; do
    mkdir -p "$(dirname "$copy/$f")" && cp "$ROOT/$f" "$copy/$f" 2>/dev/null
  done
  sed -i "$4" "$copy/$3" 2>/dev/null
  out="$(docs_missing "$copy")"
  [ "$out" = "$2" ] || got="${got:+$got; }$1: printed '${out//$'\n'/, }' (want '${2//$'\n'/, }')"
}

# --- R33: the documents name the worker, its verbs and its levels -------------------------------
got=""
m="$(docs_missing "$ROOT")"
[ -z "$m" ] || got="missing: ${m//$'\n'/, }"
docs_control 'no section' 'pipeline: no section' docs/pipeline.md 's/^## The worker$/## The workers/'
docs_control 'next only before the section' 'pipeline: verb next' docs/pipeline.md 's/sdd-worker next/sdd-worker nexts/g
/^## The kaizen loop$/a\
`sdd-worker next`'
# The ladder, the `assisted` of the pager row and the helper of the worker's row are each written
# once in their file, so a copy that only takes one out would be missed alike by a checker that reads
# the whole file instead of its section or row: those controls also put it back somewhere else.
lad="$(ladder_line)"
docs_control 'ladder only before the section' 'pipeline: ladder' docs/pipeline.md 's/`plan` < `merge`/`merge` < `plan`/g
/^## The kaizen loop$/a\
'"$lad"
docs_control 'no command line' 'readme: command' README.md '/^sdd-worker /d'
docs_control 'no link' 'readme: link' README.md 's@(docs/pipeline.md#the-worker)@(docs/pipeline.md)@g'
docs_control 'assisted only in another row' 'schema: ON_ESCALATION_CMD' config/schema.md '/^| `ON_ESCALATION_CMD` |/ s/`assisted`/assisted/g
/^| `BUDGET_MISSION_USD` |/ s/ |$/ `assisted` |/'
docs_control 'pager row, no worker' 'schema: ON_ESCALATION_CMD' config/schema.md '/^| `ON_ESCALATION_CMD` |/ s/sdd-worker/the worker/g'
docs_control 'mission cap, no worker' 'schema: BUDGET_MISSION_USD' config/schema.md '/^| `BUDGET_MISSION_USD` |/ s/sdd-worker/the worker/g'
# The five identifiers are written out in this want, never read from DOC_TERMS: a term dropped from
# the array would vanish from a want built of it too.
docs_control 'no glossary rows' $'context: campaign.md\ncontext: lot:\ncontext: delegation.md\ncontext: level:\ncontext: bin/sdd-worker\ncontext: ladder\ncontext: coordination' \
  CONTEXT.md '/^| \*\*[^*]*\*\* (`[^`]*`) |/d'
docs_control 'lot term not first' 'context: lot:' CONTEXT.md 's/^| \(\*\*[^*]*\*\* (`lot:`) |\)/| x | \1/'
docs_control 'ladder only in another row' 'context: ladder' CONTEXT.md '/(`level:`) |/ s/ < `full`//
/(`campaign.md`) |/ s/ |$/ '"$lad"' |/'
docs_control 'helper only in another row' 'context: coordination' CONTEXT.md '/(`bin\/sdd-worker`) |/ s/sdd-coordination\.py/the helper/g
/(`campaign.md`) |/ s/ |$/ sdd-coordination.py |/'
# The primitive under every control above, against an answer known wrong: told to want the command
# line from a copy that only lost the link, docs_control() has to append, or each control passes on
# anything — the same control R30 runs on control().
saved="$got"
docs_control 'the primitive' 'readme: command' README.md 's@(docs/pipeline.md#the-worker)@(docs/pipeline.md)@g'
[ "$got" != "$saved" ] || saved="${saved:+$saved; }docs_control() let a copy printing the link pass as the command"
got="$saved"
if [ -z "$got" ]; then
  pass 'docs: pipeline.md, README.md, schema.md and CONTEXT.md name the worker, its verbs and its five levels'
else
  fail 'docs: pipeline.md, README.md, schema.md and CONTEXT.md name the worker, its verbs and its five levels' \
    'each document naming what it owes, and each sabotaged copy naming what it lost' "$got"
fi

# --- R35: the campaign's id is its directory's name ---------------------------------------------
# The id is written three times (the directory, campaign.md, delegation.md), and neither the digest
# nor any other rule reads the directory's name or the campaign: of campaign.md, so each world is
# first a full delegation the program signed and that answers full: the assisted, the no ceiling,
# the refusal and the stop that follow are this rule's and nothing else's. g-moved is signed and
# its directory renamed g-renamed, both files still writing g-moved; the campaign.md of g-crossed
# turns to another id after signing (the J6 of the mission's QA: budget summed the missions of one
# id while next walked the queue of another); the delegation of g-deleg turns to another id, its
# campaign.md still right — the digest breaks there, but budget reads the ceiling of an unsigned
# delegation too, and summed the other id's missions; g-lone loses its campaign.md, which a reader
# of the delegation alone never misses. Each answers level and allows with assisted — illegible
# (never the digest's edited after signing) and budget with no ceiling, naming both values (g-lone:
# the file it lacks), and delegate refuses the renamed one before the question. next stops on the first two and on the template's campaign.md copied as it
# is, whose placeholder a reader of the frontmatter alone takes for an id, and plans L1 for.
# The controls, over g-named: `.` from inside it, a trailing slash and a symlink of another name are
# the directory, and answer full (level) and plan L1 (next) — a rule that read the argument as
# written goes red there.
got=""
C="$REPO/docs/campaigns"
for id in g-moved g-crossed g-deleg g-lone g-named; do
  d="$(campaign "$id" full "$FAR" 25 200)"
  sign "$d"
  level_is "$id before" "level full — signed until $FAR" "$d"
done
mv "$C/g-moved" "$C/g-renamed"
sed -i '2,/^---$/ s@^campaign: .*@campaign: g-other@' "$C/g-crossed/campaign.md" "$C/g-deleg/delegation.md"
rm "$C/g-lone/campaign.md"
ln -s g-named "$C/g-alias"
mkdir -p "$C/g-template"
cp "$ROOT/templates/campaign.md" "$C/g-template/"
for w in "g-renamed|campaign: 'g-moved' in $C/g-renamed/delegation.md is not the directory's name 'g-renamed'" \
         "g-crossed|campaign: 'g-other' in $C/g-crossed/campaign.md is not the directory's name 'g-crossed'" \
         "g-deleg|campaign: 'g-other' in $C/g-deleg/delegation.md is not the directory's name 'g-deleg'" \
         "g-lone|$C/g-lone/campaign.md does not exist"; do
  IFS='|' read -r id why <<< "$w"
  level_is "$id" "level assisted — illegible: $why" "$C/$id"
  allows_is "$id" 1 "ask approve needs full, effective assisted — illegible: $why" "$C/$id" approve --lot L1
  budget_is "$id" 1 "no ceiling — illegible: $why" "$C/$id"
done
cp "$C/g-renamed/delegation.md" "$BOX/g-renamed.before"
answer $'y\n'
worker_from "$BOX/in" delegate "$C/g-renamed"
refused g-renamed 1 "illegible: campaign: 'g-moved' in "
! grep -qF 'Sign this delegation?' <<< "$W_ERR" || got="${got:+$got; }g-renamed: the question was asked"
next_is g-renamed 1 \
  "stop - - — illegible: campaign: 'g-moved' in $C/g-renamed/campaign.md is not the directory's name 'g-renamed'" \
  '' "$C/g-renamed"
next_is g-crossed 1 \
  "stop - - — illegible: campaign: 'g-other' in $C/g-crossed/campaign.md is not the directory's name 'g-crossed'" \
  '' "$C/g-crossed"
next_is 'the template' 1 "stop - - — illegible: campaign: '<YYYYMMDD>-" '' "$C/g-template"
W_CWD="$C/g-named" level_is dot "level full — signed until $FAR" .
level_is 'trailing slash' "level full — signed until $FAR" "$C/g-named/"
level_is symlink "level full — signed until $FAR" "$C/g-alias"
W_CWD="$C/g-named" next_is dot 0 'plan L1 - — ' '' .
if [ -z "$got" ]; then
  pass "legible: a campaign: that is not its directory's name, in either file, is illegible to every verb and stops next"
else
  fail "legible: a campaign: that is not its directory's name, in either file, is illegible to every verb and stops next" \
    'assisted, no ceiling, a refusal and a stop naming both values for each break; full and plan L1 for each control' "$got"
fi

# --- R36: an instant the clock has --------------------------------------------------------------
# Three instants of the right shape that the clock does not have: minute 99, the 31st of November
# and the 29th of February of 2099, a common year. Each is far ahead, so without this rule nothing
# else refuses it — the comparison by digits reads it as not expired, level answers unsigned and
# delegate asks and signs. Each answers level with assisted — illegible, and delegate refuses it
# before the question, the file unchanged. The control is the 29th of February of 2096, a leap year:
# it signs, and level answers full until it — a rule that refused every 29th of February goes red
# there.
got=""
for w in 'i-minute|2099-11-18 99:99' 'i-november|2099-11-31 10:00' 'i-common|2099-02-29 12:00'; do
  IFS='|' read -r id ex <<< "$w"
  d="$(campaign "$id" full "$ex" 25 200)"
  level_is "$id" "level assisted — illegible: expires '$ex' is no instant on the clock" "$d"
  cp "$d/delegation.md" "$BOX/$id.before"
  answer $'y\n'
  worker_from "$BOX/in" delegate "$d"
  refused "$id" 1 "illegible: expires '$ex' is no instant on the clock"
  ! grep -qF 'Sign this delegation?' <<< "$W_ERR" || got="${got:+$got; }$id: the question was asked"
done
d="$(campaign i-leap full '2096-02-29 12:00' 25 200)"
sign "$d"
level_is i-leap 'level full — signed until 2096-02-29 12:00' "$d"
if [ -z "$got" ]; then
  pass 'legible: an expires: the clock does not have is illegible to level and refused by delegate, and a leap day signs'
else
  fail 'legible: an expires: the clock does not have is illegible to level and refused by delegate, and a leap day signs' \
    'assisted — illegible and a refusal for each instant the clock lacks; full until the leap day' "$got"
fi

# --- R38: a fill-in for a rationale, or for the gate: -------------------------------------------
# gate_REVIEW refuses a round whose A no sentence supports (PLACEHOLDER_AWK in bin/sdd), and the
# worker's bar is never below the pipeline's: bin/sdd-worker carries a copy of that rule, and this
# probe holds the two equal over the same cells. The runner's placeholder() is read out of bin/sdd
# HERE and run on the text each cell leaves once its `*` and backticks are stripped and its blanks
# trimmed (what gate_REVIEW judges); pr-ready has to agree with it on every cell: rc 1 and `…
# grades A with a placeholder rationale` where the runner refuses, `ready <B>` where it does not.
# Each cell is the Rationale of the Security row of the newest round (r2), its A kept, every other
# item true. The cells: the fill-ins of each kind (angle brackets, empty, an ellipsis in both
# spellings, a dash, the fill-in words with their punctuation), one in a code span, and the terse
# rationales the codereview skill writes (`clean`, `n/a`, `—`, the dash in bold), and sentences.
# Then the gate: of r2, judged by the same rule: the template's own, an empty one and the
# template's quoted (the runner strips the quotes) fail; the filled one is ready; and an absent one
# fails too — the runner leaves it alone for the rounds that predate the key, and a round with
# reviewed_head: is the worker's own, made from the template. The template's table as shipped, its
# eight rows graded A and left `<…>` (the round of the finding), is one line naming the first row.
# The counter-world: a fill-in left in the findings table, after the grade table, changes nothing.
got=""
RUNNER_PH="$(sed -n "/^PLACEHOLDER_AWK='\$/,/^'\$/p" "$ROOT/bin/sdd" | sed '1d;$d')"
grep -q '^function placeholder(s, ' <<< "$RUNNER_PH" \
  || got="fixture: no PLACEHOLDER_AWK with a placeholder() read out of $ROOT/bin/sdd"
# runner_refuses <text> — rc 0 when the runner's own rule calls <text> a fill-in.
runner_refuses() {
  SDD_PLACEHOLDER_TEXT="$1" awk "$RUNNER_PH"' BEGIN { exit placeholder(ENVIRON["SDD_PLACEHOLDER_TEXT"]) ? 0 : 1 }'
}
# set_row <round> <cell> — the Security row of <round> rewritten as `| Security | A | <cell> |`.
set_row() {
  CELL="$2" awk '/^\| Security \|/ { print "| Security | A | " ENVIRON["CELL"] " |"; next } { print }' \
    "$1" > "$1.new" && mv "$1.new" "$1"
  grep -qxF "| Security | A | $2 |" "$1" || got="${got:+$got; }fixture: the cell '$2' did not land"
}
# set_gate <round> <line> — the frontmatter's gate: line replaced by <line>, deleted when it is `-`.
set_gate() {
  LINE="$2" awk 'NR == 1 { fm = 1; print; next }
    fm && $0 == "---" { fm = 0 }
    fm && index($0, "gate:") == 1 { if (ENVIRON["LINE"] != "-") print ENVIRON["LINE"]; next }
    { print }' "$1" > "$1.new" && mv "$1.new" "$1"
}
# judged <label> <runner says refused: 0/1> — reads the last pr-ready against the runner's verdict.
judged() {
  if [ "$2" = 0 ]; then
    { [ "$W_RC" = 1 ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$3"* ]]; } && refused_n=$((refused_n + 1)) && return 0
  else
    { [ "$W_RC" = 0 ] && [ "$W_OUT" = "ready $HEADNOW" ]; } && kept_n=$((kept_n + 1)) && return 0
  fi
  got="${got:+$got; }$1: the runner says $([ "$2" = 0 ] && echo refused || echo justified), pr-ready rc $W_RC '$W_OUT'"
}
serve rationale
export GHFX="$BOX/ghfx/rationale"
refused_n=0; kept_n=0
# The first rationale of the template's table, the fill-in a model leaves, read from the template.
TPL_RAT="$(sed -n 's/^| Code Quality (Zen) | <A> | \(<[^|]*>\) |$/\1/p' "$ROOT/templates/review.md")"
[[ "$TPL_RAT" == '<'?*'>' ]] || got="${got:+$got; }fixture: no fill-in read from the first row of templates/review.md"
CELLS=('<…>' '' '...' '…' '-' 'TODO:' 'TBD.' 'PREENCHER' 'wip' 'FIXME' 'XXX' 'FILLME'
       "\`$TPL_RAT\`"
       'clean' 'n/a' '—' '**—**' 'Confirmed no leaks.' 'a real sentence with <A> in it')
for cell in "${CELLS[@]}"; do
  ready_reset
  set_row "$MD/40-review-r2.md" "$cell"
  t="${cell//[*\`]/}"
  rr=1; runner_refuses "$t" && rr=0
  land rationale
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  judged "rationale '$cell'" "$rr" "not-ready review: $MD/40-review-r2.md: Security grades A with a placeholder rationale (${t:-<empty>})"
done
TG="$(sed -n '2,/^---$/ s/^gate: //p' "$ROOT/templates/review.md")"
for w in "gate: $TG|$TG" 'gate:|' "gate: \"$TG\"|$TG" "gate: $RUN_GATE|$RUN_GATE"; do
  ready_reset
  set_gate "$MD/40-review-r2.md" "${w%%|*}"
  grep -qxF "${w%%|*}" "$MD/40-review-r2.md" || got="${got:+$got; }fixture: '${w%%|*}' did not land"
  rr=1; runner_refuses "${w#*|}" && rr=0
  land rationale
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  judged "'${w%%|*}'" "$rr" "not-ready review: the gate: of $MD/40-review-r2.md is a placeholder"
done
ready_reset
set_gate "$MD/40-review-r2.md" -
grep -q '^gate:' "$MD/40-review-r2.md" && got="${got:+$got; }fixture: the gate: line was not deleted"
land rationale
PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
judged 'no gate:' 0 "not-ready review: the gate: of $MD/40-review-r2.md is a placeholder"
ready_reset
sed -i "s@ | $RUN_RAT |\$@ | <…> |@" "$MD/40-review-r2.md"
[ "$(grep -c ' | <…> |$' "$MD/40-review-r2.md")" = 8 ] || got="${got:+$got; }fixture: the eight fill-ins did not land"
land rationale
PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
judged 'the eight fill-ins of the template' 0 \
  "not-ready review: $MD/40-review-r2.md: Code Quality (Zen) grades A with a placeholder rationale (<…>)"
ready_reset
sed -i 's@^| 1 | <CRITICAL .*@| 1 | LOW | <…> | x |@' "$MD/40-review-r2.md"
grep -qxF '| 1 | LOW | <…> | x |' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: the findings row did not land"
land rationale
PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
judged 'a fill-in in the findings table' 1 ''
ready_reset
{ [ "$refused_n" -ge 12 ] && [ "$kept_n" -ge 7 ]; } \
  || got="${got:+$got; }$refused_n refused and $kept_n justified of the 26 worlds (want at least 12 and 7)"
if [ -z "$got" ]; then
  pass 'rationale: a round graded A with a placeholder rationale or gate: fails review, by the rule of gate_REVIEW'
else
  fail 'rationale: a round graded A with a placeholder rationale or gate: fails review, by the rule of gate_REVIEW' \
    "pr-ready refusing exactly the cells and the gate: values the runner's placeholder() refuses" "$got"
fi

# --- R39: an act asked with no lot ----------------------------------------------------------------
# Every act of a campaign is an act of one of its lots, and a lot's ceiling is the act's (R14): an
# act asked with no --lot would answer the signed level over every ceiling of the queue. A full
# delegation over L1 (no ceiling) and L6 (plan), signed and first witnessed allowing approve on L1
# and capping it on L6, so the refusal that follows is the missing lot's: each of the seven acts
# asked with no --lot is rc 2, nothing on stdout, and the stderr names the lot it needs, in its own
# line and in the usage — the usage alone is what every call of the wrong shape prints. The count
# witnesses the seven.
got=""; nolot=0
d="$(campaign o-nolot full "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L6:plan'
sign "$d"
allows_is 'L1, approve' 0 'allowed approve at full' "$d" approve --lot L1
allows_is 'L6, approve' 1 'ask approve needs full, effective plan — capped by the lot' "$d" approve --lot L6
for row in "${ACT_TABLE[@]}"; do
  read -r act _ <<< "$row"
  worker allows "$d" "$act"
  if [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -qF 'sdd-worker: allows needs --lot L<n>' <<< "$W_ERR" \
     && grep -qF 'allows   <campaign-dir> <act> --lot L<n> ' <<< "$W_ERR"; then
    nolot=$((nolot + 1))
  else
    got="${got:+$got; }$act with no lot: rc $W_RC, stdout '$W_OUT', stderr '${W_ERR%%$'\n'*}'"
  fi
done
[ "$nolot" = 7 ] || got="${got:+$got; }$nolot of 7 acts refused with no lot"
if [ -z "$got" ]; then
  pass 'lot: an act asked with no --lot is rc 2 and never allowed, under a full delegation with a lot capped at plan'
else
  fail 'lot: an act asked with no --lot is rc 2 and never allowed, under a full delegation with a lot capped at plan' \
    'rc 2, nothing on stdout, the --lot named on stderr, for each of the seven acts' "$got"
fi

# --- R40: the delegate signs what it showed ------------------------------------------------------
# The delegate shows the terms, asks, and reads one line: an editor of the owner's, or a `git pull`
# in the checkout, can change the file while the question is open. Two worlds over a FIFO on stdin,
# signed at pr with a mission cap of 40: in h-edit the level becomes full and the cap 999 once the
# question is on stderr (so the terms were read and shown), then the y arrives — rc 1, `not signed`
# with its own reason, the file as the edit left it, the stdout showing what was asked (pr, 40), and
# level answering unsigned; in h-kept the same y arrives with no edit, and it signs at pr, so the
# refusal is the edit's and never the FIFO's.
got=""
for id in h-kept h-edit; do
  d="$(campaign "$id" pr "$FAR" 40 200)"
  mkfifo "$BOX/$id.fifo"
  ( exec "$WORKER" delegate "$d" < "$BOX/$id.fifo" > "$BOX/$id.out" 2> "$BOX/$id.err" ) &
  hp=$!
  exec 3> "$BOX/$id.fifo"
  for _ in $(seq 200); do grep -qF 'Sign this delegation?' "$BOX/$id.err" && break; sleep 0.05; done
  grep -qF 'Sign this delegation?' "$BOX/$id.err" || got="${got:+$got; }$id: the question never came"
  { grep -qx 'level: pr' "$BOX/$id.out" && grep -qx 'budget_mission_usd: 40' "$BOX/$id.out"; } \
    || got="${got:+$got; }$id: the terms asked were not shown"
  if [ "$id" = h-edit ]; then
    sed -i '2,/^---$/ { s@^level: pr$@level: full@; s@^budget_mission_usd: 40$@budget_mission_usd: 999@ }' "$d/delegation.md"
    grep -qx 'level: full' "$d/delegation.md" || got="${got:+$got; }fixture: the edit did not land"
  fi
  cp "$d/delegation.md" "$BOX/$id.asked"
  ( printf 'y\n' >&3 ) 2> /dev/null || true
  exec 3>&-
  hr=0; wait "$hp" || hr=$?
  if [ "$id" = h-kept ]; then
    { [ "$hr" = 0 ] && grep -q '^signed ' "$BOX/$id.out"; } || got="${got:+$got; }$id: rc $hr, '$(tail -1 "$BOX/$id.out")'"
    level_is "$id after" "level pr — signed until $FAR" "$d"
    continue
  fi
  [ "$hr" = 1 ] || got="${got:+$got; }$id: rc $hr"
  cmp -s "$BOX/$id.asked" "$d/delegation.md" \
    || got="${got:+$got; }$id: the file was written: '$(signed_line "$d/delegation.md")'"
  grep -q '^not signed — the delegation changed after it was shown' "$BOX/$id.out" \
    || got="${got:+$got; }$id: no reason of its own ('$(tail -1 "$BOX/$id.out")')"
  ! grep -q '^signed ' "$BOX/$id.out" || got="${got:+$got; }$id: stdout says signed"
  level_is "$id after" 'level assisted — unsigned' "$d"
done
if [ -z "$got" ]; then
  pass 'shown: a delegation edited while the question is open is not signed, and the same y with no edit signs'
else
  fail 'shown: a delegation edited while the question is open is not signed, and the same y with no edit signs' \
    'rc 1, not signed — the delegation changed…, the file as edited; rc 0 and signed at pr with no edit' "$got"
fi

# --- R41: the config of the checkouts in the set ------------------------------------------------
# The runner loads the .sdd/config.sh of the checkout it runs in (CONFIG_FILE under its REPO_ROOT,
# in bin/sdd), and the session launches it in the mission's worktree: the line deleted in the
# campaign's checkout, the remedy templates/delegation.md gives, is still there in a worktree cut
# from a commit that has it. One repo whose committed config sets BUDGET_MISSION_USD=150, two linked
# worktrees cut from that commit — m holds the campaign's mission, x holds none —, the line then
# deleted in the campaign's checkout; campaign w-cap, mission cap 40, campaign cap 100:
#   m      m keeps the 150 of the commit, x has the line deleted: rc 1, naming m's file and 150
#   x      m has the line deleted, x keeps 150: rc 0, the signed cap — x holds no mission of the
#          campaign, so no `sdd run` of it runs there, and its file is never read (the narrow set
#          the owner chose, R49)
#   clean  the line deleted in every checkout: rc 0, the signed cap and the one mission, so each
#          stop is the worktree's file and nothing else
# The folder of m ends in a backslash, a letter and a space, which `git worktree list` prints raw: a
# reader of its lines that drops a backslash or trims a space globs a checkout that is not there,
# finds no mission in it, and leaves m out of the set with its 150 unread — the fail-open side.
got=""
W="$BOX/wcap"
WM="$BOX/wcap-m\\b "
WX="$BOX/wcap-x"
mkdir -p "$W/.sdd" "$W/docs/campaigns"
git init -q -b main "$W"
noline='HANDOFF_DIR="docs/handoffs"'
printf '%s\nBUDGET_MISSION_USD=150\n' "$noline" > "$W/.sdd/config.sh"
git -C "$W" add .sdd/config.sh
git -C "$W" -c user.name=fixture -c user.email=fixture@example.com commit -q -m fixture
git -C "$W" worktree add -q -b feat/w-m "$WM" > /dev/null 2>&1 \
  || got="${got:+$got; }fixture: the worktree m was not created"
git -C "$W" worktree add -q -b feat/w-x "$WX" > /dev/null 2>&1 \
  || got="${got:+$got; }fixture: the worktree x was not created"
mission "$WM" "$H" 20990301-w-m w-cap
cp -a "$(campaign w-cap pr "$FAR" 40 100)" "$W/docs/campaigns/"
printf '%s\n' "$noline" > "$W/.sdd/config.sh"
printf '%s\n' "$noline" > "$WX/.sdd/config.sh"
grep -qx 'BUDGET_MISSION_USD=150' "$WM/.sdd/config.sh" 2>/dev/null \
  || got="${got:+$got; }fixture: the worktree m does not carry the 150 of the commit"
wstop=" sets BUDGET_MISSION_USD=150, which sdd run applies over the signed budget_mission_usd: 40; "
budget_is m 1 "no mission cap — $WM/.sdd/config.sh$wstop" "$W/docs/campaigns/w-cap"
printf '%s\n' "$noline" > "$WM/.sdd/config.sh"
printf '%s\nBUDGET_MISSION_USD=150\n' "$noline" > "$WX/.sdd/config.sh"
held='campaign US$ 0.00 of 100.00 — 1 mission(s); mission cap US$ 40'
budget_is x 0 "$held" "$W/docs/campaigns/w-cap"
[ "$W_OUT" = "$held" ] || got="${got:+$got; }x: the line is not the whole answer: '$W_OUT'"
printf '%s\n' "$noline" > "$WX/.sdd/config.sh"
budget_is clean 0 "$held" "$W/docs/campaigns/w-cap"
if [ -z "$got" ]; then
  pass 'worktree: a mission worktree whose config sets BUDGET_MISSION_USD above the signed cap stops budget and names that file, and a worktree with no mission of the campaign is not read'
else
  fail 'worktree: a mission worktree whose config sets BUDGET_MISSION_USD above the signed cap stops budget and names that file, and a worktree with no mission of the campaign is not read' \
    "rc 1 naming the file of m and 150; rc 0 and the mission cap 40 over 1 mission with x keeping 150, and with the line deleted in every checkout" "$got"
fi

# --- R42: a pipe escaped inside a cell of the grade table ----------------------------------------
# GFM writes a literal pipe inside a cell as `\|`, and gate_REVIEW rejoins it before it reads a
# column (its escaped_pipe, by the PARITY of the run of backslashes: `\\` is a literal backslash
# against a real delimiter). Cut at every `|`, the worker judged the rationale
# `<why \| in one sentence>` by its first piece, `<why \`, which has a letter and no closing
# `>`: a fill-in the runner refuses read as a sentence, on the bar of a merge with no human. The
# runner's split is read out of gate_REVIEW in bin/sdd HERE — its escaped_pipe() and the loop that
# rejoins — and run on each row the probe writes in place of the Security row of the newest round.
# The oracle is what that split leaves, `*` and backticks stripped: a Grade that is not A is
# refused by its grade, a Rationale the runner's placeholder() calls a fill-in is refused by the
# rationale, and the rest is ready; pr-ready has to agree on every row. The rows: fill-ins holding
# an escaped pipe (angle brackets around one, a fill-in word before one), sentences holding one
# (the shell pipeline of the runner's own world 10 in check-gates.sh, a plain one), a row with no
# closing pipe, whose last cell is the Rationale, a criterion holding one, which leaves a B where a
# cut at every `|` reads the A, and the even run `\\|`, a backslash against a real delimiter, whose
# A a rejoin by "ends in a backslash" would glue away.
got=""
RUNNER_EP="$(sed -n '/^gate_REVIEW() {/,/^}/ { /^ *function escaped_pipe(s, /p }' "$ROOT/bin/sdd")"
RUNNER_SPLIT="$(sed -n '/^gate_REVIEW() {/,/^}/ { /^ *delete f$/,/^ *}$/p }' "$ROOT/bin/sdd")"
{ grep -q 'escaped_pipe' <<< "$RUNNER_EP" && grep -qF 'escaped_pipe(f[n])' <<< "$RUNNER_SPLIT"; } \
  || got="fixture: no escaped_pipe() and rejoin read out of gate_REVIEW in $ROOT/bin/sdd"
# runner_reads <row> — `<grade><TAB><rationale>` of <row> as the split of gate_REVIEW leaves them,
# each with its `*` and backticks stripped and its blanks trimmed.
runner_reads() {
  awk "$RUNNER_EP"' { '"$RUNNER_SPLIT"'
    g = f[3]; r = f[4]; gsub(/[*`]/, "", g); gsub(/[*`]/, "", r)
    gsub(/^[ \t]+|[ \t]+$/, "", g); gsub(/^[ \t]+|[ \t]+$/, "", r); print g "\t" r }' <<< "$1"
}
# set_line <round> <row> — the Security row of <round> replaced by <row>, as written.
set_line() {
  ROW="$2" awk '/^\| Security \|/ { print ENVIRON["ROW"]; next } { print }' "$1" > "$1.new" && mv "$1.new" "$1"
  grep -qxF "$2" "$1" || got="${got:+$got; }fixture: the row '$2' did not land"
}
serve pipe
export GHFX="$BOX/ghfx/pipe"
refused_n=0; kept_n=0
ROWS=('| Security | A | <why \| in one sentence> |'
      '| Security | A | <a\|b> |'
      '| Security | A | TODO\| |'
      '| Security | A | `TODO\|` list references removed; assertions now target the function. Green. |'
      '| Security | A | read with grep \| sort, measured |'
      '| Security | A | Confirmed no leaks.'
      '| Security (a\| A | B | Confirmed no leaks. |'
      '| Escaping (\\| A | Confirmed no leaks. |')
for row in "${ROWS[@]}"; do
  ready_reset
  set_line "$MD/40-review-r2.md" "$row"
  IFS=$'\t' read -r rg rt <<< "$(runner_reads "$row")"
  if [ "$rg" != A ]; then
    rr=0; want="not-ready review: $MD/40-review-r2.md grades $rg, and every row must read A"
  elif runner_refuses "$rt"; then
    rr=0; want="not-ready review: $MD/40-review-r2.md: Security grades A with a placeholder rationale (${rt:-<empty>})"
  else
    rr=1; want=""
  fi
  land pipe
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  judged "row '$row'" "$rr" "$want"
done
ready_reset
{ [ "$refused_n" = 4 ] && [ "$kept_n" = 4 ]; } \
  || got="${got:+$got; }$refused_n refused and $kept_n ready of the 8 rows (want 4 and 4)"
# A row with no Rationale cell, and no closing pipe, after rows that have one: gate_REVIEW skips a
# row of fewer than four cells, and pr-ready, the stricter of the two, refuses it as an A no
# sentence supports — never by the rationale the row above it left behind.
set_line "$MD/40-review-r2.md" '| Security | A'
land pipe
PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
{ [ "$W_RC" = 1 ] && [ "$W_OUT" = "not-ready review: $MD/40-review-r2.md: Security grades A with a placeholder rationale (<empty>) — a grade no sentence supports is a label" ]; } \
  || got="${got:+$got; }a row with no Rationale cell: rc $W_RC '$W_OUT'"
ready_reset
if [ -z "$got" ]; then
  pass 'pipe: a grade row holding an escaped pipe is read as gate_REVIEW splits it, so a fill-in rationale with one fails review'
else
  fail 'pipe: a grade row holding an escaped pipe is read as gate_REVIEW splits it, so a fill-in rationale with one fails review' \
    "pr-ready agreeing with the split and the placeholder() of gate_REVIEW on the 8 rows, and refusing a row with no Rationale cell" "$got"
fi

# --- R43: a signed mission cap of zero -----------------------------------------------------------
# For the runner a BUDGET_MISSION_USD of zero is no ceiling (config/schema.md), and the grammar of
# the delegation reads `0` as a number, so a signed `budget_mission_usd: 0` is legible. budget
# stopped on it, but inside the loop over the configs of the checkouts, so the stop accused a
# .sdd/config.sh of setting the key to 0 where there was no such file, or no such line, and told
# the owner to delete it. Four campaigns, each the only one of its repo, signed at pr with a
# campaign cap of 100:
#   zero    mission cap 0, no .sdd/config.sh: rc 1, the stop naming the delegation and its 0
#   zeros   0.00, a spelling of the runner's numeric zero: rc 1, the same stop
#   silent  0, a config silent on the key: rc 1, the same stop, and no config.sh named
#   frac    0.5, a fraction above zero, no config: rc 0 and the mission cap 0.5 — a fraction of a
#           cent or more is a cap for the runner, so the stop is the zero's and never "below one
#           dollar" (below one cent is the stop of R51)
got=""
zero_world() {
  local k="$BOX/zero-$1"
  mkdir -p "$k/docs/campaigns"
  git init -q -b main "$k"
  if [ "$3" != - ]; then mkdir -p "$k/.sdd"; printf '%s\n' "$3" > "$k/.sdd/config.sh"; fi
  cp -a "$(campaign "z-$1" pr "$FAR" "$2" 100)" "$k/docs/campaigns/"
  printf '%s\n' "$k/docs/campaigns/z-$1"
}
for w in 'zero|0|-' 'zeros|0.00|-' 'silent|0|HANDOFF_DIR="docs/handoffs"'; do
  IFS='|' read -r id v c <<< "$w"
  d="$(zero_world "$id" "$v" "$c")"
  budget_is "$id" 1 "no mission cap — $d/delegation.md signs budget_mission_usd: $v, which sdd run reads as no ceiling; sign a cap above 0" "$d"
  [ "$W_OUT" = "no mission cap — $d/delegation.md signs budget_mission_usd: $v, which sdd run reads as no ceiling; sign a cap above 0" ] \
    || got="${got:+$got; }$id: the stop says more than its line: '$W_OUT'"
  [[ "$W_OUT" != *config.sh* ]] || got="${got:+$got; }$id: the stop names a config: '$W_OUT'"
done
budget_is frac 0 'campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 0.5' "$(zero_world frac 0.5 -)"
if [ -z "$got" ]; then
  pass 'zero: a signed mission cap of zero stops budget naming the delegation, never a config that does not set it'
else
  fail 'zero: a signed mission cap of zero stops budget naming the delegation, never a config that does not set it' \
    "rc 1 naming the delegation and its 0 for 0, 0.00 and a config silent on the key; rc 0 and the mission cap 0.5 for 0.5" "$got"
fi

# --- R44: the pager of the checkouts in the set -------------------------------------------------
# The pager is the mission cap's twin (R41): the runner loads the .sdd/config.sh of the checkout it
# runs in, and the session launches it in the mission's worktree, so a pager written only in the
# campaign's checkout — left out of the commit, since its command often carries a secret topic —
# pages nobody when the runner in the worktree stops the line with rc 3, and the command tells the
# session that the runner already paged that stop. One repo whose committed config leaves
# ON_ESCALATION_CMD empty, two linked worktrees cut from that commit — m holds the campaign's
# mission, x holds none —; campaign p-pager signed at pr, its lot L1 with no ceiling:
#   m        the pager in the campaign's checkout and in x, m's left empty: assisted naming m's
#            file, and `allows run --lot L1` asks
#   x        the pager in the campaign's checkout and in m, x's left empty: the signed pr — x holds
#            no mission of the campaign, no `sdd run` of it pages from there, and its file is never
#            read (the narrow set, R49)
#   inverse  the pager in both worktrees, the campaign's checkout left empty: assisted naming its file
#   control  the pager in every checkout: the signed pr, and `allows run --lot L1` allowed, so each
#            stop is a file's empty pager and nothing else
#   nogit    the same file copied outside any git checkout, asked from the cwd of P with the pager
#            everywhere: assisted naming `(no repo)`, never a checkout of the cwd's repo; the signed
#            assisted of R9 copied there answers its own level, since assisted asks for no pager
# The folder of m ends in a backslash, a letter and a space, as in R41: a reader of its lines that
# drops either globs a checkout that is not there, finds no mission, and leaves m's empty pager
# unread, so the world m goes red on it. Every answer is the whole line: a stop naming the wrong
# file starts the same.
got=""
P="$BOX/wpager"; PM="$BOX/wpager-m\\b "; PX="$BOX/wpager-x"
nopager='ON_ESCALATION_CMD=""'; pager='ON_ESCALATION_CMD="true"'
mkdir -p "$P/.sdd" "$P/docs/campaigns"
git init -q -b main "$P"
printf 'HANDOFF_DIR="docs/handoffs"\n%s\n' "$nopager" > "$P/.sdd/config.sh"
git -C "$P" add .sdd/config.sh
git -C "$P" -c user.name=fixture -c user.email=fixture@example.com commit -q -m fixture
git -C "$P" worktree add -q -b feat/p-m "$PM" > /dev/null 2>&1 \
  || got="${got:+$got; }fixture: the worktree m was not created"
git -C "$P" worktree add -q -b feat/p-x "$PX" > /dev/null 2>&1 \
  || got="${got:+$got; }fixture: the worktree x was not created"
grep -qxF "$nopager" "$PM/.sdd/config.sh" 2>/dev/null \
  || got="${got:+$got; }fixture: the worktree m does not carry the empty pager of the commit"
mission "$PM" "$H" 20990401-p-m p-pager
d="$(campaign p-pager pr "$FAR" 25 100)"
sign "$d"
cp -a "$d" "$P/docs/campaigns/"
d="$P/docs/campaigns/p-pager"
# pager_is <label> <campaign's> <m's> <x's> <want> — each checkout's config written with its
# ON_ESCALATION_CMD line, then level asked; appends to got unless the one line is <want>, whole.
pager_is() {
  printf 'HANDOFF_DIR="docs/handoffs"\n%s\n' "$2" > "$P/.sdd/config.sh"
  printf 'HANDOFF_DIR="docs/handoffs"\n%s\n' "$3" > "$PM/.sdd/config.sh"
  printf 'HANDOFF_DIR="docs/handoffs"\n%s\n' "$4" > "$PX/.sdd/config.sh"
  level_is "$1" "$5" "$d"
  [ "$W_OUT" = "$5" ] || got="${got:+$got; }$1: the line is not the whole answer: '$W_OUT'"
}
nopage='level assisted — no pager: ON_ESCALATION_CMD is empty in'
pager_is m "$pager" "$nopager" "$pager" "$nopage $PM/.sdd/config.sh"
allows_is m-run 1 "ask run needs pr, effective assisted — no pager: ON_ESCALATION_CMD is empty in $PM/.sdd/config.sh" \
  "$d" run --lot L1
[ "$W_OUT" = "ask run needs pr, effective assisted — no pager: ON_ESCALATION_CMD is empty in $PM/.sdd/config.sh" ] \
  || got="${got:+$got; }m-run: the line is not the whole answer: '$W_OUT'"
pager_is x "$pager" "$pager" "$nopager" "level pr — signed until $FAR"
pager_is inverse "$nopager" "$pager" "$pager" "$nopage $P/.sdd/config.sh"
pager_is control "$pager" "$pager" "$pager" "level pr — signed until $FAR"
allows_is control-run 0 'allowed run at pr' "$d" run --lot L1
mkdir -p "$BOX/nogit"
cp -a "$d" "$REPO/docs/campaigns/l-pager-assisted" "$BOX/nogit/"
W_CWD="$P" level_is nogit "$nopage (no repo)/.sdd/config.sh" "$BOX/nogit/p-pager"
[ "$W_OUT" = "$nopage (no repo)/.sdd/config.sh" ] || got="${got:+$got; }nogit: the line is not the whole answer: '$W_OUT'"
W_CWD="$P" level_is nogit-assisted "level assisted — signed until $FAR" "$BOX/nogit/l-pager-assisted"
if [ -z "$got" ]; then
  pass 'pager: a mission worktree whose config leaves ON_ESCALATION_CMD empty lowers the level to assisted and names that file, and a worktree with no mission of the campaign is not read'
else
  fail 'pager: a mission worktree whose config leaves ON_ESCALATION_CMD empty lowers the level to assisted and names that file, and a worktree with no mission of the campaign is not read' \
    "assisted naming the file of m (and run asked) and of the campaign's checkout; pr with x's empty; pr and run allowed with the pager in every checkout" "$got"
fi

# --- R45: the header and the separator, by the shape of the line ---------------------------------
# A row of the grade table is skipped for its shape and never for its grade: the separator is the
# row whose every cell is `:?-+:?` (aligned or not, closed by a pipe or not), and the header is the
# first row of the table, its criterion reading `Criterion`. Every other row is a criterion, read
# and held to A. Decided by the grade, as the verb did (achado #8 of the review r5), a criterion
# graded `---` or `Grade` was skipped, and the round was ready with no grade for it. Each world
# writes one line of the newest round (r2) in place of another, commits it (land) and reads the
# whole answer, so a refusal by another row or another item never passes for this one:
#   dash      `| Security | --- | Not evaluated |`       not-ready, grades ---
#   colon     `| Security | :---: | Not evaluated |`     not-ready, grades :---:
#   dashes    `| Security | --- | --- |`                 not-ready, grades ---: the criterion is a cell too
#   lastcell  `| --- | --- | Not evaluated |`            not-ready, grades ---: and so is the last one
#   word      `| Security | Grade | Not evaluated |`     not-ready, grades Grade
#   critdash  `| --- | B | Not evaluated |`              not-ready, grades B: a separator is every cell
#   ratdash   `| --- | A | --- |`                        not-ready, the rationale `---` a fill-in
#   midhead   `| Criterion | B | Not evaluated |`       not-ready, grades B: the header is the first row
#   nohead    the header itself `| Security | B | Not evaluated |`   not-ready, grades B
#   boldhead  the header in bold, `| **Criterion** | **Grade** | **Rationale** |`   ready
#   aligned   the separator `|:---|:---:|---:|`          ready
#   spaced    the separator `| --- | --- | --- |`        ready
#   open      the separator `|---|---|---`, no closing pipe     ready
# gate_REVIEW decides by the criterion cell, so it reads the first three and the two header worlds
# as pr-ready does; critdash and ratdash it skips, and pr-ready is there the stricter of the two.
got=""
R2F="$MD/40-review-r2.md"
SROW="| Security | A | $RUN_RAT |"; SEPL='|-----------|-------|-----------|'; HEADL='| Criterion | Grade | Rationale |'
{ grep -qxF -- "$SROW" "$R2F" && grep -qxF -- "$SEPL" "$R2F" && grep -qxF -- "$HEADL" "$R2F"; } \
  || got="fixture: r2 lacks its Security row, its separator or its header as the template writes them"
# swap_line <round> <old> <new> — the first line of <round> that is exactly <old> replaced by <new>.
swap_line() {
  OLD="$2" NEW="$3" awk '!done && $0 == ENVIRON["OLD"] { print ENVIRON["NEW"]; done = 1; next } { print }' \
    "$1" > "$1.new" && mv "$1.new" "$1"
  grep -qxF -- "$3" "$1" || got="${got:+$got; }fixture: the line '$3' did not land"
}
# sep_is <label> <old> <new> <rc> <want> — r2 with <old> swapped for <new>, committed, then pr-ready;
# appends to got unless it left <rc> and the one line <want>, whole (`ready` is the landed head).
sep_is() {
  local want="$5"
  ready_reset
  swap_line "$R2F" "$2" "$3"
  land sep
  [ "$want" != ready ] || want="ready $HEADNOW"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  { [ "$W_RC" = "$4" ] && [ "$W_OUT" = "$want" ]; } || got="${got:+$got; }$1: rc $W_RC '$W_OUT' (want rc $4 '$want')"
}
export GHFX="$BOX/ghfx/sep"
gr="not-ready review: $R2F grades"; ge=', and every row must read A'
sep_is dash "$SROW" '| Security | --- | Not evaluated |' 1 "$gr ---$ge"
sep_is colon "$SROW" '| Security | :---: | Not evaluated |' 1 "$gr :---:$ge"
sep_is dashes "$SROW" '| Security | --- | --- |' 1 "$gr ---$ge"
sep_is lastcell "$SROW" '| --- | --- | Not evaluated |' 1 "$gr ---$ge"
sep_is word "$SROW" '| Security | Grade | Not evaluated |' 1 "$gr Grade$ge"
sep_is critdash "$SROW" '| --- | B | Not evaluated |' 1 "$gr B$ge"
sep_is ratdash "$SROW" '| --- | A | --- |' 1 \
  "not-ready review: $R2F: --- grades A with a placeholder rationale (---) — a grade no sentence supports is a label"
sep_is midhead "$SROW" '| Criterion | B | Not evaluated |' 1 "$gr B$ge"
sep_is nohead "$HEADL" '| Security | B | Not evaluated |' 1 "$gr B$ge"
sep_is boldhead "$HEADL" '| **Criterion** | **Grade** | **Rationale** |' 0 ready
sep_is aligned "$SEPL" '|:---|:---:|---:|' 0 ready
sep_is spaced "$SEPL" '| --- | --- | --- |' 0 ready
sep_is open "$SEPL" '|---|---|---' 0 ready
ready_reset
if [ -z "$got" ]; then
  pass 'sep: the header and the separator are known by the shape of the line, so a criterion graded --- is read and is not A'
else
  fail 'sep: the header and the separator are known by the shape of the line, so a criterion graded --- is read and is not A' \
    'not-ready for each criterion row graded --- or Grade, for --- rows that are not separators and a misplaced header; ready for each separator' "$got"
fi

# --- R46: the round the head carries -------------------------------------------------------------
# The merge takes the head, never the disk (achado #18 of the review r5): a round on disk that the
# head does not carry would authorize the merge of a round nobody committed, and the head item
# proves the checkout is at the head, not that the mission folder is clean. So the review item
# refuses a mission folder with any change not committed, naming the first path and the status git
# gives it. Each world commits r2 graded B at the head (land) — the round the merge would take —
# and leaves the disk saying otherwise:
#   modified   r2 rewritten on disk graded A                 not-ready, status ` M`
#   staged     the same rewrite staged, not committed         not-ready, status `M `
#   untracked  a round r3 graded A and a note, never added, under status.showUntrackedFiles=no:
#              not-ready, `??`, the first of the two named alone
#   ignored    the same r3, ignored by .git/info/exclude      not-ready, status `!!`
#   named      the good world, λ.txt (a name git quotes by default) modified: not-ready, the name as
#              written
#   config     a copy of the good world whose config sets status.branch to no boolean, which git
#              status refuses and no other git call of the verb reads: not-ready naming the status,
#              never a clean folder read from an empty answer
#   outside    the good world, with src/app.txt modified on disk: ready — the refusal is the folder's
got=""
R3F="$MD/40-review-r3.md"
# committed_is <label> <status> <path> — pr-ready over the world the caller left on disk; appends to
# got unless it left rc 1 and the one line naming <path> (from the root) with its <status>.
committed_is() {
  local want="not-ready review: $3 in the mission folder is not committed (status '$2') — the merge takes the head, never the disk"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  { [ "$W_RC" = 1 ] && [ "$W_OUT" = "$want" ]; } || got="${got:+$got; }$1: rc $W_RC '$W_OUT' (want rc 1 '$want')"
}
# graded_b_landed <world> — r2 graded B in Security, committed at the head <world> serves.
graded_b_landed() {
  ready_reset
  sed -i 's@^| Security | A |@| Security | B |@' "$R2F"
  land "$1"
  export GHFX="$BOX/ghfx/$1"
  grep -q '^| Security | B |' <<< "$(git -C "$RR" show "HEAD:$H/20990300-ready/40-review-r2.md")" \
    || got="${got:+$got; }fixture: $1: the head does not carry r2 graded B"
}
graded_b_landed k-modified; round "$R2F" "$A"
committed_is modified ' M' "$H/20990300-ready/40-review-r2.md"
graded_b_landed k-staged; round "$R2F" "$A"; gitc add -- "$R2F"
committed_is staged 'M ' "$H/20990300-ready/40-review-r2.md"
graded_b_landed k-untracked; round "$R3F" "$A"; printf 'n\n' > "$MD/note.md"; gitc config status.showUntrackedFiles no
[ -z "$(git -C "$MD" status --porcelain -- .)" ] || got="${got:+$got; }fixture: untracked: git status still lists r3"
committed_is untracked '??' "$H/20990300-ready/40-review-r3.md"
gitc config --unset status.showUntrackedFiles
graded_b_landed k-ignored; round "$R3F" "$A"; printf '40-review-r3.md\n' >> "$RR/.git/info/exclude"
[ -z "$(git -C "$MD" status --porcelain -- .)" ] || got="${got:+$got; }fixture: ignored: r3 is not ignored"
committed_is ignored '!!' "$H/20990300-ready/40-review-r3.md"
sed -i '/^40-review-r3\.md$/d' "$RR/.git/info/exclude"
ready_reset; export GHFX="$BOX/ghfx/good"; printf 'm\n' > "$MD/λ.txt"
committed_is named ' M' "$H/20990300-ready/λ.txt"
ready_reset
# copy_world <name> — a copy of the ready repo as it now stands, its path printed: the worlds that
# break the repository itself never touch the one every other world reads.
copy_world() { local c="$BOX/rc-$1"; rm -rf "$c"; cp -a "$RR" "$c"; printf '%s\n' "$c"; }
CI="$(copy_world config)"
serve k-config; (CDPATH='' cd "$CI" && pwd -P) > "$BOX/ghfx/k-config/root"; export GHFX="$BOX/ghfx/k-config"
git -C "$CI" config status.branch maybe
! git -C "$CI" status --porcelain > /dev/null 2>&1 || got="${got:+$got; }fixture: config: git status still runs"
PATH="$BOX/stub-ready:$PATH" worker pr-ready "$CI/$H/20990300-ready" "$PRN"
{ [ "$W_RC" = 1 ] && [ "$W_OUT" = "not-ready review: git status does not run in $CI/$H/20990300-ready" ]; } \
  || got="${got:+$got; }config: rc $W_RC '$W_OUT'"
printf 'dirty\n' > "$RR/src/app.txt"
ready_is outside 0 "ready $B" good
[ "$W_OUT" = "ready $B" ] || got="${got:+$got; }outside: the line is '$W_OUT', not 'ready $B'"
ready_reset
if [ -z "$got" ]; then
  pass 'committed: a mission folder with a change not committed, staged, untracked or ignored fails review'
else
  fail 'committed: a mission folder with a change not committed, staged, untracked or ignored fails review' \
    "rc 1 naming the path and its status for each world; ready with a change outside the folder" "$got"
fi

# --- R47: every commit after the reviewed head, and the reviewed head an ancestor ----------------
# Commits after the reviewed head may touch only the mission folder, and that is read commit by
# commit: the diff between the two ends does not see a change made and then undone (achado #10 of
# the review r5), nor the resolution of a merge whose parents touch the folder alone. And the head
# has to carry the reviewed commit (achado #9): a round that read a commit the pull request dropped
# is a review of another history. The round of each world names its reviewed head; the head is
# what the world served:
#   revert   after B, C changes src/app.txt and D reverts it, the round naming A: not-ready, src/app.txt
#            named with C — the diff between A and D touches the folder alone
#   evil     after B, a merge of a side branch that only adds a note, its resolution changing
#            src/app.txt: not-ready, src/app.txt named with the merge
#   sibling  the round names E, a commit on A that only adds a note to the folder, which the head does
#            not carry: not-ready, not an ancestor — every commit of E..head and the diff between the
#            two touch the folder alone, so only the ancestry says no
#   itself   the round on disk names B, the head: the ancestry accepts the head itself and the range
#            is empty, so only the committed item (R46) refuses it
#   empty    after B, an empty commit (a push to wake a bot): ready — a commit that changes nothing
#            changes nothing outside the folder
#   tree     a copy whose head C adds a note after B, and B's tree deleted from its objects: git
#            diff-tree does not run on B, and the answer is not-ready naming B, never a range read as
#            clean from an empty answer
got=""
pre="$H/20990300-ready/"
range_is() {
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  { [ "$W_RC" = 1 ] && [ "$W_OUT" = "$2" ]; } || got="${got:+$got; }$1: rc $W_RC '$W_OUT' (want rc 1 '$2')"
}
# outside_of <a> <b> — the paths outside the mission folder that the diff between <a> and <b> lists.
outside_of() { git -C "$RR" -c core.quotePath=false diff --no-renames --name-only "$1" "$2" | grep -v "^$pre" || true; }
ready_reset
printf 'three\n' > "$RR/src/app.txt"; gitc commit -q -am c; RC1="$(git -C "$RR" rev-parse HEAD)"
gitc revert --no-edit HEAD > /dev/null; HEADNOW="$(git -C "$RR" rev-parse HEAD)"
serve n-revert "$HEADNOW"; export GHFX="$BOX/ghfx/n-revert"
[ -z "$(outside_of "$A" "$HEADNOW")" ] || got="${got:+$got; }fixture: revert: the diff between A and the head leaves the folder"
range_is revert "not-ready review: src/app.txt changed in $RC1 after the reviewed head $A, outside $pre"
ready_reset
gitc checkout -q -b r-side "$B"; printf 'side\n' > "$MD/note.md"; gitc add -A; gitc commit -q -m side
gitc checkout -q main; gitc merge -q --no-ff --no-commit r-side > /dev/null 2>&1
printf 'evil\n' > "$RR/src/app.txt"; gitc add src/app.txt; gitc commit -q -m evil
HEADNOW="$(git -C "$RR" rev-parse HEAD)"; serve n-evil "$HEADNOW"; export GHFX="$BOX/ghfx/n-evil"
{ [ "$(git -C "$RR" rev-list --count --merges "$B..$HEADNOW")" = 1 ] \
  && [ -z "$(git -C "$RR" diff-tree -r --no-commit-id --name-only "$HEADNOW")" ]; } \
  || got="${got:+$got; }fixture: evil: the head is not a merge whose own diff git log shows empty"
range_is evil "not-ready review: src/app.txt changed in $HEADNOW after the reviewed head $A, outside $pre"
ready_reset; gitc branch -q -D r-side
gitc checkout -q --detach "$A"; printf 'e\n' > "$MD/note.md"; gitc add -A; gitc commit -q -m e
E="$(git -C "$RR" rev-parse HEAD)"; gitc checkout -q main
round "$R2F" "$E"; land n-sibling; export GHFX="$BOX/ghfx/n-sibling"
{ [ -z "$(outside_of "$E" "$HEADNOW")" ] \
  && [ -z "$(git -C "$RR" -c core.quotePath=false log --format= --name-only --no-renames "$E..$HEADNOW" | grep -v "^$pre" | grep -v '^$' || true)" ]; } \
  || got="${got:+$got; }fixture: sibling: E..head leaves the folder"
range_is sibling "not-ready review: the reviewed head $E of $R2F is not an ancestor of the head $HEADNOW — the pull request does not carry the commit the round read"
ready_reset
round "$R2F" "$B"; export GHFX="$BOX/ghfx/good"
range_is itself "not-ready review: $H/20990300-ready/40-review-r2.md in the mission folder is not committed (status ' M') — the merge takes the head, never the disk"
ready_reset
land n-empty
[ -z "$(git -C "$RR" diff-tree -r --no-commit-id --name-only "$HEADNOW")" ] || got="${got:+$got; }fixture: empty: the commit changes a path"
ready_is empty 0 "ready $HEADNOW" n-empty
[ "$W_OUT" = "ready $HEADNOW" ] || got="${got:+$got; }empty: the line is '$W_OUT'"
ready_reset
CT="$(copy_world tree)"
printf 'n\n' > "$CT/$H/20990300-ready/note.md"
git -C "$CT" add -A; git -C "$CT" -c user.name=fixture -c user.email=fixture@example.com commit -q -m c
CTH="$(git -C "$CT" rev-parse HEAD)"; BT="$(git -C "$CT" rev-parse "$B^{tree}")"
rm -f "$CT/.git/objects/${BT:0:2}/${BT:2}"
! git -C "$CT" cat-file -e "$BT" 2> /dev/null || got="${got:+$got; }fixture: tree: the tree of B is still there"
serve n-tree "$CTH"; (CDPATH='' cd "$CT" && pwd -P) > "$BOX/ghfx/n-tree/root"; export GHFX="$BOX/ghfx/n-tree"
PATH="$BOX/stub-ready:$PATH" worker pr-ready "$CT/$H/20990300-ready" "$PRN"
{ [ "$W_RC" = 1 ] && [ "$W_OUT" = "not-ready review: git diff-tree $B does not run here" ]; } \
  || got="${got:+$got; }tree: rc $W_RC '$W_OUT'"
if [ -z "$got" ]; then
  pass 'range: a commit after the reviewed head that touches code, a merge resolution and a reviewed head the pull request does not carry each fail review'
else
  fail 'range: a commit after the reviewed head that touches code, a merge resolution and a reviewed head the pull request does not carry each fail review' \
    'rc 1 naming the path and the commit, or the reviewed head that is no ancestor; the head itself refused only as not committed' "$got"
fi

# --- R48: the newest receipt, read or refused ----------------------------------------------------
# The receipt is the newest comment of the bot that carries the marker, chosen BEFORE its payload is
# parsed: a newest one that does not parse says nothing, and an older good one is never read in its
# place (achado #11 of the review r5). The worlds, on the good world's pages:
#   truncated  the newest receipt cut before the `} -->` that closes its payload, a good receipt for
#              the head on the page before it: not-ready codex, does not parse
#   shapeless  the newest receipt's code_review a string, not an object: not-ready codex, rc 1 — a
#              receipt that says nothing, never a gh off its contract
#   chatter    after the bot's receipt for the head, a comment of the bot with no marker: ready —
#              only a comment carrying the marker is a receipt
got=""
unparsed="not-ready codex: the newest receipt of $CODEX does not parse"
serve k-truncated
printf '[%s,%s]' "$(comment "$CODEX" "$B" '')" '{"user":{"login":"j0ruge"},"body":"thanks"}' > "$BOX/ghfx/k-truncated/comments.1"
printf '[%s]' "$(comment "$CODEX" "$B" 's/,"security_review".*$//')" > "$BOX/ghfx/k-truncated/comments.2"
tb="$(jq -r '.[0].body' "$BOX/ghfx/k-truncated/comments.2")"
{ grep -qF 'codex-review-state:v1 {' <<< "$tb" && ! grep -q 'codex-review-state:v1 {.*} -->' <<< "$tb"; } \
  || got="fixture: truncated: the newest receipt is not cut before its close"
ready_is truncated 1 "$unparsed" k-truncated
[ "$W_OUT" = "$unparsed" ] || got="${got:+$got; }truncated: the line is '$W_OUT'"
serve k-shapeless
printf '[%s]' "$(comment "$CODEX" "$B" 's/"code_review":{[^}]*}/"code_review":"done"/')" > "$BOX/ghfx/k-shapeless/comments.2"
grep -qF '"code_review":"done"' <<< "$(jq -r '.[0].body' "$BOX/ghfx/k-shapeless/comments.2")" \
  || got="${got:+$got; }fixture: shapeless: code_review kept its object"
ready_is shapeless 1 "$unparsed" k-shapeless
[ "$W_OUT" = "$unparsed" ] || got="${got:+$got; }shapeless: the line is '$W_OUT'"
serve k-chatter
printf '[%s,%s]' "$(comment "$CODEX" "$B" '')" \
  "$(jq -cn --arg l "$CODEX" '{user: {login: $l}, body: "Codex is reviewing this pull request."}')" > "$BOX/ghfx/k-chatter/comments.2"
ready_is chatter 0 "ready $B" k-chatter
[ "$W_OUT" = "ready $B" ] || got="${got:+$got; }chatter: the line is '$W_OUT'"
if [ -z "$got" ]; then
  pass 'receipt: the newest comment of the bot with the marker is the receipt, and one that does not parse fails codex'
else
  fail 'receipt: the newest comment of the bot with the marker is the receipt, and one that does not parse fails codex' \
    'not-ready codex for a truncated and a shapeless newest receipt; ready with a comment of the bot without the marker after it' "$got"
fi

# --- R49: the narrow set ------------------------------------------------------------------------
# A .sdd/config.sh is read by sourcing it, which runs the file as shell, and `sdd run` reads the
# file of the checkout it runs in: the campaign's, or the worktree of a mission of the campaign. A
# worktree that holds none runs no `sdd run` of this campaign, so its file is never read — not for
# the cap, the pager or HANDOFF_DIR (achado #3 of the r5; the owner chose the narrow set). One repo,
# its config committed with a pager; three linked worktrees cut from that commit — m holds the
# campaign's mission (L1, not approved and with no branch, so next answers approve and asks no gh),
# o a mission of another campaign, x none —; campaign n-narrow signed at pr, mission cap 40,
# campaign cap 100.
# budget, level, `allows run --lot L1` and next are each asked from the cwd of the repo, the marks
# cleared before each:
#   control  every config clean, m's touching a mark of its own: each verb gives its answer, whole,
#            and leaves m's mark — the set is read
#   poison   o's and x's config set the cap to 150, the pager to empty and HANDOFF_DIR elsewhere, and
#            touch a mark of their own: each verb answers exactly what it answered in control, m's
#            mark comes back, and o's and x's are never made
got=""
NR="$BOX/narrow"
clean=$'HANDOFF_DIR="docs/handoffs"\nON_ESCALATION_CMD="true"'
mkdir -p "$NR/.sdd" "$NR/docs/campaigns"
git init -q -b main "$NR"
printf '%s\n' "$clean" > "$NR/.sdd/config.sh"
git -C "$NR" add .sdd/config.sh
git -C "$NR" -c user.name=fixture -c user.email=fixture@example.com commit -q -m fixture
for w in m o x; do
  git -C "$NR" worktree add -q -b "feat/n-$w" "$NR-$w" > /dev/null 2>&1 \
    || got="${got:+$got; }fixture: the worktree $w was not created"
done
# No branch: next answers approve with no gh asked, since a branch would have it read the merge first
# (R55), and this repo has no remote.
lot_mission "$NR-m" 20990501-n-m n-narrow L1 '' -
lot_mission "$NR-o" 20990502-n-o n-other L1 feat/n-o -
d="$(campaign n-narrow pr "$FAR" 40 100)"
sign "$d"
cp -a "$d" "$NR/docs/campaigns/"
d="$NR/docs/campaigns/n-narrow"
# four_ask <dir> — budget, level, `allows run --lot L1` and next asked of <dir> from the cwd of NR,
# the marks cleared before each; PUBLISHES FOUR, one `<verb>: rc <rc> '<stdout>' marks <names>` line
# per verb. Called, never substituted: under `$( )` the global would die with the subshell.
four_ask() {
  local v f mk
  FOUR=""
  for v in budget level allows next; do
    rm -f "$BOX"/narrow-mark-*
    case "$v" in
      budget) LC_ALL="$NUM_POISON" W_CWD="$NR" worker budget "$1" ;;
      allows) W_CWD="$NR" worker allows "$1" run --lot L1 ;;
      *) W_CWD="$NR" worker "$v" "$1" ;;
    esac
    mk=""
    for f in "$BOX"/narrow-mark-*; do [ ! -e "$f" ] || mk="$mk ${f##*/narrow-mark-}"; done
    FOUR+="$v: rc $W_RC '$W_OUT' marks$mk"$'\n'
  done
}
printf '%s\ntouch %q\n' "$clean" "$BOX/narrow-mark-m" > "$NR-m/.sdd/config.sh"
for w in o x; do printf '%s\n' "$clean" > "$NR-$w/.sdd/config.sh"; done
four_ask "$d"
control="$FOUR"
want="budget: rc 0 'campaign US\$ 0.00 of 100.00 — 1 mission(s); mission cap US\$ 40' marks m
level: rc 0 'level pr — signed until $FAR' marks m
allows: rc 0 'allowed run at pr' marks m
next: rc 0 'approve L1 20990501-n-m — not approved: $NR-m/$H/20990501-n-m/00-missao.md has aprovacao: ''' marks m
"
[ "$control" = "$want" ] || got="${got:+$got; }control: '${control//$'\n'/ / }' (want '${want//$'\n'/ / }')"
for w in o x; do
  printf 'HANDOFF_DIR="work/elsewhere"\nON_ESCALATION_CMD=""\nBUDGET_MISSION_USD=150\ntouch %q\n' \
    "$BOX/narrow-mark-$w" > "$NR-$w/.sdd/config.sh"
done
four_ask "$d"
[ "$FOUR" = "$control" ] || got="${got:+$got; }poison: '${FOUR//$'\n'/ / }' (want the control's)"
for w in o x; do printf '%s\n' "$clean" > "$NR-$w/.sdd/config.sh"; done
if [ -z "$got" ]; then
  pass "narrow: budget, level, allows and next read the config of the campaign's checkout and of the worktrees that hold a mission of it, and of no other"
else
  fail "narrow: budget, level, allows and next read the config of the campaign's checkout and of the worktrees that hold a mission of it, and of no other" \
    "the control's four answers, each leaving m's mark, and the same four with o's and x's config poisoned, their marks never made" "$got"
fi

# --- R50: a worktree list that does not run ------------------------------------------------------
# The set is read from `git worktree list`, and a listing that failed used to leave the campaign's
# checkout alone in it: budget summed fewer missions and read fewer caps, level fewer pagers, and
# next planned a lot in flight again — less, in silence (achado #24 of the r5). A git first on the
# PATH runs the real one for every call but `worktree list`; over the world of R49, clean:
#   fail   it refuses before printing (rc 128): budget `no spend — <the call> failed (rc 128)`,
#          level `level assisted — unread: …`, next `stop - - — unread: …`, each rc 1, and
#          `allows run` asks; no config is read, so no mark is made
#   late   it prints the real list and then fails (rc 1): the same four, naming rc 1 — the listing
#          is judged by its rc, never by what it printed
#   pass   it runs the real one: the answers of R49's control, so each stop is the failure's
got=""
REAL_GIT="$(command -v git)"
mkdir -p "$BOX/gitshim"
{ printf '#!/usr/bin/env bash\nreal=%q\n' "$REAL_GIT"
  cat <<'SHIM'
case " $* " in
  *" worktree list "*)
    case "${SDD_GIT_SHIM:-}" in
      fail) echo 'fatal: the shim refuses worktree list' >&2; exit 128 ;;
      late) "$real" "$@"; exit 1 ;;
    esac ;;
esac
exec "$real" "$@"
SHIM
} > "$BOX/gitshim/git"
chmod +x "$BOX/gitshim/git"
NRT="$(git -C "$NR" rev-parse --show-toplevel)"
for w in 'fail|128' 'late|1'; do
  IFS='|' read -r mode rc <<< "$w"
  why="git -C $NRT worktree list --porcelain failed (rc $rc)"
  want="budget: rc 1 'no spend — $why' marks
level: rc 1 'level assisted — unread: $why' marks
allows: rc 1 'ask run needs pr, effective assisted — unread: $why' marks
next: rc 1 'stop - - — unread: $why' marks
"
  PATH="$BOX/gitshim:$PATH" SDD_GIT_SHIM="$mode" four_ask "$d"
  [ "$FOUR" = "$want" ] || got="${got:+$got; }$mode: '${FOUR//$'\n'/ / }' (want '${want//$'\n'/ / }')"
done
PATH="$BOX/gitshim:$PATH" SDD_GIT_SHIM=pass four_ask "$d"
[ "$FOUR" = "$control" ] || got="${got:+$got; }pass: '${FOUR//$'\n'/ / }' (want R49's control)"
if [ -z "$got" ]; then
  pass 'listed: a git worktree list that fails, before or after printing, stops budget, level and next with rc 1 naming the call, and allows asks'
else
  fail 'listed: a git worktree list that fails, before or after printing, stops budget, level and next with rc 1 naming the call, and allows asks' \
    "rc 1 and the call with its rc for each verb, no config read; R49's control through a git that passes" "$got"
fi

# --- R51: money in cents -------------------------------------------------------------------------
# The spend is counted in cents, and the cap the session passes on is the one signed (achados #4,
# #5 and #21 of the r5). In the fixture repo:
#   cents      two missions of s-cents spent 0.10 and 0.70, which a binary sum puts at
#              0.7999999999999999: a campaign cap of 0.80 is reached (rc 1, `0.80 of 0.80`), one of
#              0.81 is not (rc 0); the cents are rounded, never cut down nor up: two missions of
#              s-frac spent 0.50 and 0.303, 0.80 of a cap of 0.81 (rc 0), two of s-half 0.50 and
#              0.306, 0.81 of 0.81 (rc 1), and a cap of 0.806 is 0.81, which 0.80 is below (rc 0)
#   as-signed  a signed mission cap of 0.015 is printed as signed, the value `run` passes to
#              `sdd run`: `%.2f` would hand the runner 0.01 or 0.02; so are 10.004 and 0.01
#   cent       a signed mission cap below one cent — 0.004, which `%.2f` printed as 0.00, the
#              runner's no ceiling, 0.0099 and 00.009 — stops budget naming the delegation
#   grammar    each BUDGET_MISSION_USD of a list in a config: a value the runner's own pattern
#              refuses (read out of bin/sdd HERE: 1e2, 5e0, +5 and a blank, which jq reads as
#              numbers, among them) stops budget naming the file, the value and the refusal; one it
#              accepts, at or below the signed 150, holds — a differential, value by value
# Every answer is the whole line.
got=""
mission "$REPO" "$H" 20990601-s-a s-cents
mission "$REPO" "$H" 20990602-s-b s-cents
{ spent 20990601-s-a session 0.1; spent 20990602-s-b close 0.7; } >> "$BOX/state/autonomy-log.jsonl"
jq -en '0.1 + 0.7 < 0.8' > /dev/null || got="fixture: this jq sums 0.1 and 0.7 to 0.8 exactly"
mission "$REPO" "$H" 20990603-s-c s-frac
mission "$REPO" "$H" 20990604-s-d s-frac
mission "$REPO" "$H" 20990605-s-e s-half
mission "$REPO" "$H" 20990606-s-f s-half
{ spent 20990603-s-c session 0.5; spent 20990604-s-d session 0.303
  spent 20990605-s-e session 0.5; spent 20990606-s-f session 0.306; } >> "$BOX/state/autonomy-log.jsonl"
for w in 's-at|s-cents|0.80|1|0.80 of 0.80' 's-edge|s-cents|0.81|0|0.80 of 0.81' \
         's-up|s-frac|0.81|0|0.80 of 0.81' 's-half|s-half|0.81|1|0.81 of 0.81' \
         's-capr|s-cents|0.806|0|0.80 of 0.81'; do
  IFS='|' read -r id c cap rc shown <<< "$w"
  d="$(campaign "$id/$c" pr "$FAR" 25 "$cap")"
  want="campaign US\$ $shown — 2 mission(s); mission cap US\$ 25"
  budget_is "$id" "$rc" "$want" "$d"
  [ "$W_OUT" = "$want" ] || got="${got:+$got; }$id: the line is '$W_OUT'"
done
for w in '0.015|0|campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 0.015' \
         '10.004|0|campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 10.004' \
         '0.01|0|campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 0.01' \
         '0.004|1|' '0.0099|1|' '00.009|1|'; do
  IFS='|' read -r v rc want <<< "$w"
  d="$(campaign "s-mc-$v/s-mc" pr "$FAR" "$v" 100)"
  [ -n "$want" ] || want="no mission cap — $d/delegation.md signs budget_mission_usd: $v, below one cent; sign a cap of at least 0.01"
  budget_is "cap $v" "$rc" "$want" "$d"
  [ "$W_OUT" = "$want" ] || got="${got:+$got; }cap $v: the line is '$W_OUT'"
done
rpat="$(sed -n 's/^ *\(.*\)) die "BUDGET_MISSION_USD must be a number.*/\1/p' "$ROOT/bin/sdd")"
runner_refuses() { eval "case \"\$1\" in $rpat) return 0 ;; esac"; return 1; }
{ [ "$(grep -c 'die "BUDGET_MISSION_USD must be a number' "$ROOT/bin/sdd")" = 1 ] && [ -n "$rpat" ] \
    && runner_refuses '' && runner_refuses 1e2 && ! runner_refuses 40; } \
  || got="${got:+$got; }fixture: the runner's pattern of BUDGET_MISSION_USD was not read out of bin/sdd ('$rpat')"
n=0; refused=0; accepted=0
for v in 1e2 5e0 1E2 +5 ' 5' '5 ' 0x10 1.2.3 . 100.00 .5 5. 007 00.05 150; do
  n=$((n + 1))
  k="$BOX/spend-$n"
  mkdir -p "$k/.sdd" "$k/docs/campaigns"
  git init -q -b main "$k"
  printf 'BUDGET_MISSION_USD="%s"\n' "$v" > "$k/.sdd/config.sh"
  cp -a "$(campaign "s-g$n" pr "$FAR" 150 100)" "$k/docs/campaigns/"
  if runner_refuses "$v"; then
    refused=$((refused + 1))
    want="no mission cap — $k/.sdd/config.sh sets BUDGET_MISSION_USD=$v, which sdd run refuses as no number; delete the line, or set it above 0 and at most 150"
    budget_is "grammar '$v'" 1 "$want" "$k/docs/campaigns/s-g$n"
    [ "$W_OUT" = "$want" ] || got="${got:+$got; }grammar '$v': the line is '$W_OUT'"
  else
    accepted=$((accepted + 1))
    want='campaign US$ 0.00 of 100.00 — 0 mission(s); mission cap US$ 150'
    budget_is "grammar '$v'" 0 "$want" "$k/docs/campaigns/s-g$n"
    [ "$W_OUT" = "$want" ] || got="${got:+$got; }grammar '$v': the line is '$W_OUT'"
  fi
done
[ "$refused" -ge 1 ] && [ "$accepted" -ge 1 ] \
  || got="${got:+$got; }fixture: the runner refuses $refused and accepts $accepted of the list"
if [ -z "$got" ]; then
  pass 'spend: the spend reaches its ceiling in cents, the mission cap is printed as signed and refused below one cent, and a config value the runner refuses stops budget'
else
  fail 'spend: the spend reaches its ceiling in cents, the mission cap is printed as signed and refused below one cent, and a config value the runner refuses stops budget' \
    'rc 1 at 0.80 and rc 0 at 0.81 and 0.806 for 0.10 + 0.70, 0.803 below 0.81 and 0.806 at it; 0.015, 10.004 and 0.01 printed as signed, 0.004, 0.0099 and 00.009 stopped; the runner and budget agreeing on every value' "$got"
fi

# --- R52: a config read from its own checkout ------------------------------------------------------
# The runner is launched in the mission's worktree (`cd <mission-worktree> && … sdd run`) and
# sources that checkout's config there, so a relative include in it resolves against the worktree;
# the worker sourced it from the cwd of its caller (achado #38 of the r5). One repo whose config
# includes `./.sdd/local.sh`, a linked worktree m cut from it holding the campaign's mission;
# campaign c-cwd signed at pr, mission cap 40, campaign cap 100. budget and level are asked from
# the repo's cwd and from the box's, which has no .sdd:
#   include  the repo's local.sh sets the cap to 10 and the pager, m's the cap to 150 and an empty
#            pager: budget stops naming m's file and 150, and level is assisted naming m's file
#   same     m's local.sh is the repo's: rc 0 and the signed cap, and the signed pr
# A HANDOFF_DIR in a checkout of the set other than the campaign checkout's would have the runner
# there look for its missions elsewhere (achado #37 of the r5): it stops budget (`no spend — …`),
# level (`level assisted — unread: …`) and next (`stop - - — unread: …`), each rc 1, naming both
# files; the default written out on one side and left out on the other is the same HANDOFF_DIR.
got=""
C="$BOX/cwd"; CM="$BOX/cwd-m"
inc='. ./.sdd/local.sh'
mkdir -p "$C/.sdd" "$C/docs/campaigns"
git init -q -b main "$C"
printf 'HANDOFF_DIR="docs/handoffs"\n%s\n' "$inc" > "$C/.sdd/config.sh"
git -C "$C" add .sdd/config.sh
git -C "$C" -c user.name=fixture -c user.email=fixture@example.com commit -q -m fixture
git -C "$C" worktree add -q -b feat/c-m "$CM" > /dev/null 2>&1 \
  || got="${got:+$got; }fixture: the worktree m was not created"
grep -qxF "$inc" "$CM/.sdd/config.sh" 2>/dev/null \
  || got="${got:+$got; }fixture: the worktree m does not carry the include of the commit"
[ ! -e "$BOX/.sdd" ] || got="${got:+$got; }fixture: the box has a .sdd of its own"
# No branch, as in R49: next answers approve with no gh asked.
lot_mission "$CM" 20990701-c-m c-cwd L1 '' -
d="$(campaign c-cwd pr "$FAR" 40 100)"
sign "$d"
cp -a "$d" "$C/docs/campaigns/"
d="$C/docs/campaigns/c-cwd"
here=$'BUDGET_MISSION_USD=10\nON_ESCALATION_CMD="true"'
printf '%s\n' "$here" > "$C/.sdd/local.sh"
printf 'BUDGET_MISSION_USD=150\nON_ESCALATION_CMD=""\n' > "$CM/.sdd/local.sh"
# cwd_is <label> <verb> <rc> <want> [<cwd>] — the verb asked of d from <cwd> (the repo's when
# absent); appends to got unless it left <rc> and the one line <want>, whole.
cwd_is() {
  if [ "$2" = budget ]; then LC_ALL="$NUM_POISON" W_CWD="${5:-$C}" worker budget "$d"
  else W_CWD="${5:-$C}" worker "$2" "$d"; fi
  [ "$W_RC" = "$3" ] && [ "$W_OUT" = "$4" ] \
    || got="${got:+$got; }$1 $2: rc $W_RC, '${W_OUT//$'\n'/ / }' (want rc $3, '$4')"
}
for cwd in "$C" "$BOX"; do
  cwd_is "include ${cwd##*/}" budget 1 "no mission cap — $CM/.sdd/config.sh sets BUDGET_MISSION_USD=150, which sdd run applies over the signed budget_mission_usd: 40; delete the line, or set it above 0 and at most that" "$cwd"
  cwd_is "include ${cwd##*/}" level 0 "level assisted — no pager: ON_ESCALATION_CMD is empty in $CM/.sdd/config.sh" "$cwd"
done
printf '%s\n' "$here" > "$CM/.sdd/local.sh"
held='campaign US$ 0.00 of 100.00 — 1 mission(s); mission cap US$ 40'
for cwd in "$C" "$BOX"; do
  cwd_is "same ${cwd##*/}" budget 0 "$held" "$cwd"
  cwd_is "same ${cwd##*/}" level 0 "level pr — signed until $FAR" "$cwd"
done
printf 'HANDOFF_DIR="work/missions"\n%s\n' "$inc" > "$CM/.sdd/config.sh"
why="HANDOFF_DIR 'work/missions' in $CM/.sdd/config.sh is not the campaign checkout's 'docs/handoffs' ($C/.sdd/config.sh)"
cwd_is divergent budget 1 "no spend — $why"
cwd_is divergent level 1 "level assisted — unread: $why"
cwd_is divergent next 1 "stop - - — unread: $why"
approve="approve L1 20990701-c-m — not approved: $CM/$H/20990701-c-m/00-missao.md has aprovacao: ''"
for w in "$inc|HANDOFF_DIR=\"docs/handoffs\"" "HANDOFF_DIR=\"docs/handoffs\"|"; do
  printf '%s\n%s\n' "${w%%|*}" "$inc" > "$C/.sdd/config.sh"
  printf '%s\n%s\n' "${w#*|}" "$inc" > "$CM/.sdd/config.sh"
  cwd_is "default ${w%%=*}" budget 0 "$held"
  cwd_is "default ${w%%=*}" level 0 "level pr — signed until $FAR"
  cwd_is "default ${w%%=*}" next 0 "$approve"
done
if [ -z "$got" ]; then
  pass "cwd: a config is sourced from its own checkout, and a HANDOFF_DIR in the set other than the campaign checkout's stops budget, level and next naming the file"
else
  fail "cwd: a config is sourced from its own checkout, and a HANDOFF_DIR in the set other than the campaign checkout's stops budget, level and next naming the file" \
    "m's include read from m from both cwds (150 and no pager, then 40 and pr); rc 1 naming m's HANDOFF_DIR for the three verbs, and the default the same on both sides" "$got"
fi

# --- R53: lots: is all or a list of the table's lots ----------------------------------------------
# The template's lots: is `<all, ou L1 L2 …>` and some words after, and a reader that split it into
# words found L1 and L2 among them: a full delegation left with it signed, and approve on the
# uncapped L1 was allowed (achado #1 of the r5). Each world is a full delegation over the template's
# own table (L1 with no ceiling, L2 at plan), its lots: one of:
#   template  the template's value, read out of templates/delegation.md HERE
#   ghost     `L1 L3`, a lot the table has no row for
#   all-plus  `all L1`, all among other words
# Each is refused by delegate before the question (rc 1, the file unchanged, the word named), and,
# signed here by hand with the digest the contract defines (digest_of, which the control below holds
# equal to the program's), level --lot L1 answers assisted — illegible, allows approve --lot L1 asks
# and budget has no ceiling, each naming the word. The controls: `L1 L2` signs through delegate and
# answers full on L1 and plan on L2, and `L2` signs and answers plan on L2 and not covered on L1.
got=""
tplval="$(sed -n '2,/^---$/ s/^lots: //p' "$ROOT/templates/delegation.md")"
read -ra tw <<< "$tplval"
[[ " ${tw[*]} " == *" L1 "* ]] \
  || got="fixture: the template's lots: '$tplval' has no word L1, which is the shape of the finding"
now_sig="$(date '+%Y-%m-%d %H:%M')"
for w in "lt-template|$tplval|<all," 'lt-ghost|L1 L3|L3' 'lt-allplus|all L1|all'; do
  IFS='|' read -r id val word <<< "$w"
  d="$(campaign "$id" full "$FAR" 25 200)"
  sed -i "2,/^---\$/ s@^lots: .*@lots: $val@" "$d/delegation.md"
  [ "$(sed -n '2,/^---$/ s/^lots: //p' "$d/delegation.md")" = "$val" ] \
    || got="${got:+$got; }fixture $id: the lots: line did not land"
  why="lots '$val' is neither all nor a list of the lots of $d/campaign.md: '$word' has no row"
  cp "$d/delegation.md" "$BOX/$id.before"
  answer $'y\n'
  worker_from "$BOX/in" delegate "$d"
  { [ "$W_RC" = 1 ] && [ "${W_OUT##*$'\n'}" = "not signed — illegible: $why" ] \
      && cmp -s "$BOX/$id.before" "$d/delegation.md"; } \
    || got="${got:+$got; }$id delegate: rc $W_RC, '${W_OUT##*$'\n'}' (want rc 1, 'not signed — illegible: $why')"
  [[ "$W_ERR" != *'Sign this delegation?'* ]] || got="${got:+$got; }$id: the question was asked"
  sed -i "2,/^---\$/ s@^signed:.*@signed: $now_sig $(digest_of "$id" full "$val" "$FAR" 25 200 'L1 -' 'L2 plan')@" \
    "$d/delegation.md"
  level_is "$id" "level assisted — illegible: $why" "$d" --lot L1
  allows_is "$id" 1 "ask approve needs full, effective assisted — illegible: $why" "$d" approve --lot L1
  budget_is "$id" 1 "no ceiling — illegible: $why" "$d"
done
d="$(campaign lt-list full "$FAR" 25 200)"
sed -i '2,/^---$/ s@^lots: .*@lots: L1 L2@' "$d/delegation.md"
sign "$d"
sl="$(signed_line "$d/delegation.md")"
[ "${sl##* }" = "$(digest_of lt-list full 'L1 L2' "$FAR" 25 200 'L1 -' 'L2 plan')" ] \
  || got="${got:+$got; }lt-list: the program signed '${sl##* }', which is not the digest digest_of gives"
level_is 'L1 L2, on L1' "level full — signed until $FAR" "$d" --lot L1
level_is 'L1 L2, on L2' 'level plan — capped by the lot' "$d" --lot L2
d="$(campaign lt-one full "$FAR" 25 200)"
sed -i '2,/^---$/ s@^lots: .*@lots: L2@' "$d/delegation.md"
sign "$d"
level_is 'L2, on L2' 'level plan — capped by the lot' "$d" --lot L2
level_is 'L2, on L1' 'level assisted — lot not covered: L1 is not in lots: L2' "$d" --lot L1
if [ -z "$got" ]; then
  pass "lots: a lots: that is not all or a list of the table's lots, the template's own among them, is illegible to every verb"
else
  fail "lots: a lots: that is not all or a list of the table's lots, the template's own among them, is illegible to every verb" \
    'a refusal before the question, assisted, an ask and no ceiling naming the word, for each; full, plan and not covered for the lists' "$got"
fi

# --- R54: a pull request from a fork is not the lot's ---------------------------------------------
# gh pr list --head matches the branch's name alone, and a fork can push a branch of that name: a
# merged pull request from a fork, read as the lot's, skipped the lot, and the next one was planned
# while this one never ran (achado #6 of the r5). Each campaign has L1 approved on its branch and L2
# with no mission, and gh answers for the branch of L1:
#   merged  a fork's alone, merged: run L1, ahead plan L2 — never plan L2
#   open    a fork's alone, open: run L1 — never review
#   closed  a fork's alone, closed: run L1 — never stop
#   mixed   the repo's open beside a fork's merged: review L1, naming the repo's alone
#   own     the same merged pull request with isCrossRepository false: plan L2, so the field is
#           what decides
# An answer whose element carries no isCrossRepository, or one that is no boolean (null, the string
# "false"), is off the contract: rc 3, no act, gh named — read as absent it would hide the repo's
# own merged pull request and send the lot to run again.
got=""
fork_world() {
  d="$(campaign "$1" pr "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L2:-'
  lot_mission "$REPO" "20990801-$1" "$1" L1 "$1-b" humano-2099-01-01
}
for w in 'fk-merged|[{"isCrossRepository":true,"number":60,"state":"MERGED"}]|run L1 20990801-fk-merged — approved, and no pull request of the repository has the head fk-merged-b|ahead plan L2' \
         'fk-open|[{"isCrossRepository":true,"number":61,"state":"OPEN"}]|run L1 20990801-fk-open — |ahead plan L2' \
         'fk-closed|[{"isCrossRepository":true,"number":62,"state":"CLOSED"}]|run L1 20990801-fk-closed — |ahead plan L2' \
         'fk-mixed|[{"number":63,"state":"OPEN"},{"isCrossRepository":true,"number":64,"state":"MERGED"}]|review L1 20990801-fk-mixed — pull request #63 is open on fk-mixed-b|ahead plan L2' \
         'fk-own|[{"isCrossRepository":false,"number":65,"state":"MERGED"}]|plan L2 - — |'; do
  IFS='|' read -r id json want ahead <<< "$w"
  fork_world "$id"
  prs "$id-b" "$json"
  next_is "$id" 0 "$want" "$ahead" "$d"
done
for w in 'fk-nofield|[{"number":66,"state":"MERGED"}]' \
         'fk-null|[{"isCrossRepository":null,"number":67,"state":"MERGED"}]' \
         'fk-string|[{"isCrossRepository":"false","number":68,"state":"MERGED"}]'; do
  IFS='|' read -r id json <<< "$w"
  fork_world "$id"
  printf '%s' "$json" > "$BOX/prs/$id-b.raw"
  PATH="$BOX/stub:$PATH" worker next "$d"
  { [ "$W_RC" = 3 ] && [ -z "$W_OUT" ] && [[ "$W_ERR" == *"gh pr list --head $id-b "* ]]; } \
    || got="${got:+$got; }$id: rc $W_RC, stdout '${W_OUT//$'\n'/ / }', stderr '${W_ERR%%$'\n'*}' (want rc 3, no act, gh named)"
done
if [ -z "$got" ]; then
  pass "fork: a pull request from a fork is not the lot's, and an answer that does not say whose it is is not read"
else
  fail "fork: a pull request from a fork is not the lot's, and an answer that does not say whose it is is not read" \
    "run past a fork's merged, open or closed one, review on the repo's own beside a fork's, plan L2 past the repo's merged one; rc 3 off the contract" "$got"
fi

# --- R55: a merged lot with a stale copy ----------------------------------------------------------
# A mission's copy in an old linked worktree keeps the aprovacao: it had before the plan was
# approved, and the walk asked approve of it before reading the pull request: a lot merged long ago
# stopped the campaign on approve (achado #7 of the r5). Each campaign has L1's mission approved in
# the campaign's checkout and not in the linked worktree, both on its branch, and L2 with no
# mission:
#   merged     the repo's pull request merged: plan L2 — the lot is done, whatever a copy says
#   open       it is open: approve L1 naming the worktree's copy — the copy check still comes before
#              review and run
#   fail       gh fails: rc 3, no act, gh named — the merge is read before approve, and an answer
#              that was not read is none
#   no branch  neither copy names a branch: approve L1, and gh is never asked (the stub refuses an
#              empty --head, which would be rc 3)
#   next       L1 merged with the stale copy, and L2 approved on its branch with no pull request:
#              run L2 — what L1's copies said is not carried to the lot after it
#   both       both copies of L1 not approved, its pull request open: approve L1 naming the first
#              copy, the campaign checkout's
got=""
for k in merged open fail nobranch next both; do
  id="st-$k"; br="$id-b"
  [ "$k" != nobranch ] || br=''
  d="$(campaign "$id" pr "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L2:-'
  if [ "$k" = both ]; then
    lot_mission "$REPO" "20990811-$id" "$id" L1 "$br" -
  else
    lot_mission "$REPO" "20990811-$id" "$id" L1 "$br" humano-2099-01-01
  fi
  lot_mission "$BOX/wt" "20990811-$id" "$id" L1 "$br" -
  approve="approve L1 20990811-$id — not approved: $BOX/wt/$H/20990811-$id/00-missao.md has aprovacao: ''"
  case "$k" in
    merged) prs "$br" '[{"number":70,"state":"MERGED"}]'; next_is "$id" 0 'plan L2 - — ' '' "$d" ;;
    open) prs "$br" '[{"number":71,"state":"OPEN"}]'; next_is "$id" 0 "$approve" '' "$d" ;;
    nobranch) next_is "$id" 0 "$approve" '' "$d" ;;
    next)
      prs "$br" '[{"number":72,"state":"MERGED"}]'
      lot_mission "$REPO" "20990812-$id" "$id" L2 "$id-2-b" humano-2099-01-01
      next_is "$id" 0 "run L2 20990812-$id — " '' "$d" ;;
    both)
      prs "$br" '[{"number":73,"state":"OPEN"}]'
      next_is "$id" 0 "approve L1 20990811-$id — not approved: $REPO/$H/20990811-$id/00-missao.md has aprovacao: ''" '' "$d" ;;
    fail)
      : > "$BOX/prs/$br.fail"
      PATH="$BOX/stub:$PATH" worker next "$d"
      { [ "$W_RC" = 3 ] && [ -z "$W_OUT" ] && [[ "$W_ERR" == *"gh pr list --head $br "* ]]; } \
        || got="${got:+$got; }$id: rc $W_RC, stdout '${W_OUT//$'\n'/ / }', stderr '${W_ERR%%$'\n'*}' (want rc 3, no act, gh named)" ;;
  esac
done
if [ -z "$got" ]; then
  pass 'stale: a lot whose pull request merged is done though a stale copy is not approved, and the merge is read before approve'
else
  fail 'stale: a lot whose pull request merged is done though a stale copy is not approved, and the merge is read before approve' \
    'plan L2 past the merged lot, approve on the open one and on the one with no branch, rc 3 when gh fails, run L2 past a merged L1, the first copy named' "$got"
fi

# --- R56: an edit while the signature is written is kept ------------------------------------------
# delegate writes the signed line into a copy and moves the copy over the file, and an edit saved
# between the two was lost under the move (achado #23 of the r5). An awk first on the PATH runs the
# real one for every call and, for the one that writes the signed line (its `-v line=signed: …`),
# appends a line of prose to the delegation after the real awk ends, the owner's editor saving in
# that gap, and leaves a mark:
#   edit     delegate with a y is `not signed — the delegation changed while …`, rc 1: the file is
#            the one before plus the edit, its signed: still empty, no temporary file beside it, and
#            the mark proves the edit landed in the gap
#   control  the same awk with no edit asked signs, so the refusal is the edit's; the file keeps its
#            mode (640, where the temporary file is born 600) and no temporary file is left
# A write that fails is `not signed — the signature was not written: …`, rc 1, the file unchanged
# and no temporary file left, never an rc with no line: the awk that writes the signed line fails
# (the same awk, asked to), the move fails (an mv first on the PATH refuses it), and a campaign
# directory delegate cannot write in (no temporary file can be made beside the delegation) — under
# root chmod takes nothing away, and that last world goes unmeasured.
got=""
REAL_AWK="$(command -v awk)"
mkdir -p "$BOX/awkshim"
{ printf '#!/usr/bin/env bash\nreal=%q\nmark=%q\n' "$REAL_AWK" "$BOX/kept-mark"
  cat <<'SHIM'
hit=""
for a in "$@"; do case "$a" in 'line=signed: '*) hit=1 ;; esac; done
[ -n "$hit" ] || exec "$real" "$@"
[ -z "${SDD_AWK_SHIM_FAIL:-}" ] || { echo 'awk: the shim refuses to write the signed line' >&2; exit 2; }
[ -n "${SDD_AWK_SHIM_EDIT:-}" ] || exec "$real" "$@"
rc=0
"$real" "$@" || rc=$?
printf '\nA line the owner saved while the signature was written.\n' >> "$SDD_AWK_SHIM_EDIT"
: > "$mark"
exit "$rc"
SHIM
} > "$BOX/awkshim/awk"
chmod +x "$BOX/awkshim/awk"
REAL_MV="$(command -v mv)"
mkdir -p "$BOX/mvshim"
{ printf '#!/usr/bin/env bash\nreal=%q\n' "$REAL_MV"
  cat <<'SHIM'
[ -z "${SDD_MV_SHIM_FAIL:-}" ] || { echo 'mv: the shim refuses the move' >&2; exit 1; }
exec "$real" "$@"
SHIM
} > "$BOX/mvshim/mv"
chmod +x "$BOX/mvshim/mv"
# write_refused <label> <dir> <tail> — appends to got unless the last delegate left rc 1, a last
# line `not signed — the signature was not written: …<tail>: run delegate again` (<tail> a literal:
# each step that fails names itself), the delegation byte for byte as $BOX/<label>.before and no
# temporary file beside it.
write_refused() {
  { [ "$W_RC" = 1 ] && [[ "${W_OUT##*$'\n'}" == 'not signed — the signature was not written: '*"$3: run delegate again" ]] \
      && cmp -s "$BOX/$1.before" "$2/delegation.md" && ! compgen -G "$2/.delegation.*" > /dev/null; } \
    || got="${got:+$got; }$1: rc $W_RC, '${W_OUT##*$'\n'}' (want rc 1, 'not signed — the signature was not written: …$3: run delegate again', the file unchanged, no temporary file)"
}
d="$(campaign kp-edit pr "$FAR" 25 200)"
cp "$d/delegation.md" "$BOX/kp-edit.before"
rm -f "$BOX/kept-mark"
answer $'y\n'
PATH="$BOX/awkshim:$PATH" SDD_AWK_SHIM_EDIT="$d/delegation.md" worker_from "$BOX/in" delegate "$d"
want='not signed — the delegation changed while the signature was written; the change is kept and nothing was signed: run delegate again'
{ [ "$W_RC" = 1 ] && [ "${W_OUT##*$'\n'}" = "$want" ]; } \
  || got="${got:+$got; }edit: rc $W_RC, '${W_OUT##*$'\n'}' (want rc 1, '$want')"
[ -e "$BOX/kept-mark" ] || got="${got:+$got; }fixture: the awk first on the PATH made no edit"
cmp -s <(cat "$BOX/kp-edit.before"; printf '\nA line the owner saved while the signature was written.\n') "$d/delegation.md" \
  || got="${got:+$got; }edit: the file is not the one before plus the edit (signed: '$(signed_line "$d/delegation.md")')"
! compgen -G "$d/.delegation.*" > /dev/null || got="${got:+$got; }edit: a temporary file is left in $d"
d="$(campaign kp-control pr "$FAR" 25 200)"
chmod 640 "$d/delegation.md"
rm -f "$BOX/kept-mark"
answer $'y\n'
PATH="$BOX/awkshim:$PATH" worker_from "$BOX/in" delegate "$d"
{ [ "$W_RC" = 0 ] && [[ "$(signed_line "$d/delegation.md")" =~ ^signed:\ [0-9] ]] && [ ! -e "$BOX/kept-mark" ] \
    && ! compgen -G "$d/.delegation.*" > /dev/null && [ "$(stat -c %a "$d/delegation.md")" = 640 ]; } \
  || got="${got:+$got; }control: rc $W_RC, '$(signed_line "$d/delegation.md")', mode $(stat -c %a "$d/delegation.md") (want rc 0 and a signature, no edit, no temporary file, mode 640)"
d="$(campaign kp-awkfail pr "$FAR" 25 200)"
cp "$d/delegation.md" "$BOX/kp-awkfail.before"
answer $'y\n'
PATH="$BOX/awkshim:$PATH" SDD_AWK_SHIM_FAIL=1 worker_from "$BOX/in" delegate "$d"
write_refused kp-awkfail "$d" "the signed copy of $d/delegation.md could not be made"
d="$(campaign kp-mvfail pr "$FAR" 25 200)"
cp "$d/delegation.md" "$BOX/kp-mvfail.before"
answer $'y\n'
PATH="$BOX/mvshim:$PATH" SDD_MV_SHIM_FAIL=1 worker_from "$BOX/in" delegate "$d"
write_refused kp-mvfail "$d" " could not be moved over $d/delegation.md"
if [ "$(id -u)" != 0 ]; then
  d="$(campaign kp-readonly pr "$FAR" 25 200)"
  cp "$d/delegation.md" "$BOX/kp-readonly.before"
  chmod a-w "$d"
  answer $'y\n'
  worker_from "$BOX/in" delegate "$d"
  chmod u+w "$d"
  write_refused kp-readonly "$d" "no temporary file could be made in $d"
fi
if [ -z "$got" ]; then
  pass 'kept: an edit saved while the signature is written is kept and nothing is signed, and a write that fails says so'
else
  fail 'kept: an edit saved while the signature is written is kept and nothing is signed, and a write that fails says so' \
    'rc 1 and the file as the edit left it; a signature with no edit; rc 1 naming the write that failed' "$got"
fi

# --- R57: the terms checked are the terms read ----------------------------------------------------
# effective_level checked the digest over one reading of delegation.md and campaign.md and read the
# level, the lots and the lot's ceiling again after it: an edit landing in between was authorized
# under the old signature (achado #25 of the r5). A sha256sum first on the PATH runs the real one
# and, when asked, then applies one edit to one file and leaves a mark, an edit landing right after
# the digest:
#   ceiling  a full delegation over L1 (no ceiling) and L2 at plan, L2's ceiling lifted to `-` after
#            the digest: level --lot L2 answers plan — capped by the lot, and allows approve --lot L2
#            asks; asked again with no edit, the lifted file is edited after signing
#   level    a merge delegation, its level: raised to full after the digest: level answers merge
# Each is first asked through the same sha256sum with no edit, and the mark proves the edit landed.
# A cat first on the PATH lands an edit around the copy of campaign.md, the last file copied:
#   renamed  a campaign signed full and renamed, both files still naming the old id; right after the
#            copy both are turned to the new name: level answers assisted — illegible naming the old
#            id and the campaign's files, never the copy (the copy is what is read); asked again,
#            the turned files are edited after signing
#   aba      L2's ceiling lifted right before the copy and put back right after it: level answers
#            assisted — edited after signing, the copy's digest; a digest of the files as they are
#            when it runs would match the signature and grant the copy's lifted ceiling
# The copy the verb reads is made under TMPDIR and goes when the verb exits, whatever its answer;
# one it cannot make there is `level assisted — unread: …`, rc 1. And a delegation.md or campaign.md
# the verb cannot read answers assisted — illegible with the reason budget gives for the same file
# (a differential), never an rc with no line; under root chmod takes nothing away, and that world
# goes unmeasured.
got=""
REAL_SUM="$(command -v sha256sum)"
mkdir -p "$BOX/sumshim"
{ printf '#!/usr/bin/env bash\nreal=%q\nmark=%q\n' "$REAL_SUM" "$BOX/once-mark"
  cat <<'SHIM'
rc=0
"$real" "$@" || rc=$?
if [ -n "${SDD_SUM_SHIM_FILE:-}" ]; then sed -i "$SDD_SUM_SHIM_SED" "$SDD_SUM_SHIM_FILE"; : > "$mark"; fi
exit "$rc"
SHIM
} > "$BOX/sumshim/sha256sum"
chmod +x "$BOX/sumshim/sha256sum"
d="$(campaign on-ceiling full "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:plan'
sign "$d"
cp "$d/campaign.md" "$BOX/on-ceiling.signed"
lift='s/^| L2 | lote L2 | plan | 1 |$/| L2 | lote L2 | - | 1 |/'
PATH="$BOX/sumshim:$PATH" level_is 'ceiling, no edit' 'level plan — capped by the lot' "$d" --lot L2
rm -f "$BOX/once-mark"
PATH="$BOX/sumshim:$PATH" SDD_SUM_SHIM_FILE="$d/campaign.md" SDD_SUM_SHIM_SED="$lift" \
  level_is 'ceiling lifted after the digest' 'level plan — capped by the lot' "$d" --lot L2
{ [ -e "$BOX/once-mark" ] && grep -qxF '| L2 | lote L2 | - | 1 |' "$d/campaign.md"; } \
  || got="${got:+$got; }fixture: the ceiling of L2 was not lifted after the digest"
level_is 'ceiling lifted, asked again' 'level assisted — edited after signing' "$d" --lot L2
cp "$BOX/on-ceiling.signed" "$d/campaign.md"
PATH="$BOX/sumshim:$PATH" SDD_SUM_SHIM_FILE="$d/campaign.md" SDD_SUM_SHIM_SED="$lift" \
  allows_is 'approve, the ceiling lifted after the digest' 1 \
  'ask approve needs full, effective plan — capped by the lot' "$d" approve --lot L2
d="$(campaign on-level merge "$FAR" 25 200)"
sign "$d"
PATH="$BOX/sumshim:$PATH" level_is 'level, no edit' "level merge — signed until $FAR" "$d"
rm -f "$BOX/once-mark"
PATH="$BOX/sumshim:$PATH" SDD_SUM_SHIM_FILE="$d/delegation.md" SDD_SUM_SHIM_SED='2,/^---$/ s/^level: merge$/level: full/' \
  level_is 'level raised after the digest' "level merge — signed until $FAR" "$d"
{ [ -e "$BOX/once-mark" ] && grep -qx 'level: full' "$d/delegation.md"; } \
  || got="${got:+$got; }fixture: the level was not raised after the digest"
level_is 'level raised, asked again' 'level assisted — edited after signing' "$d"
REAL_CAT="$(command -v cat)"
mkdir -p "$BOX/catshim"
{ printf '#!/usr/bin/env bash\nreal=%q\nmark=%q\n' "$REAL_CAT" "$BOX/once-mark"
  cat <<'SHIM'
case "${!#}" in */campaign.md) : ;; *) exec "$real" "$@" ;; esac
[ -n "${SDD_CAT_SHIM_DIR:-}" ] || exec "$real" "$@"
[ -z "${SDD_CAT_SHIM_BEFORE:-}" ] \
  || sed -i "$SDD_CAT_SHIM_BEFORE" "$SDD_CAT_SHIM_DIR/delegation.md" "$SDD_CAT_SHIM_DIR/campaign.md"
rc=0
"$real" "$@" || rc=$?
[ -z "${SDD_CAT_SHIM_AFTER:-}" ] \
  || sed -i "$SDD_CAT_SHIM_AFTER" "$SDD_CAT_SHIM_DIR/delegation.md" "$SDD_CAT_SHIM_DIR/campaign.md"
: > "$mark"
exit "$rc"
SHIM
} > "$BOX/catshim/cat"
chmod +x "$BOX/catshim/cat"
d="$(campaign on-ren full "$FAR" 25 200)"
sign "$d"
mv "$d" "$REPO/docs/campaigns/on-ren2"
d="$REPO/docs/campaigns/on-ren2"
rm -f "$BOX/once-mark"
PATH="$BOX/catshim:$PATH" SDD_CAT_SHIM_DIR="$d" SDD_CAT_SHIM_AFTER='2,/^---$/ s/^campaign: on-ren$/campaign: on-ren2/' \
  level_is 'renamed, the id turned after the copy' \
  "level assisted — illegible: campaign: 'on-ren' in $d/delegation.md is not the directory's name 'on-ren2'" "$d"
{ [ -e "$BOX/once-mark" ] && grep -qx 'campaign: on-ren2' "$d/delegation.md" && grep -qx 'campaign: on-ren2' "$d/campaign.md"; } \
  || got="${got:+$got; }fixture: the id was not turned after the copy"
level_is 'renamed, asked again' 'level assisted — edited after signing' "$d"
d="$(campaign on-aba full "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:plan'
sign "$d"
rm -f "$BOX/once-mark"
PATH="$BOX/catshim:$PATH" SDD_CAT_SHIM_DIR="$d" SDD_CAT_SHIM_BEFORE="$lift" \
  SDD_CAT_SHIM_AFTER='s/^| L2 | lote L2 | - | 1 |$/| L2 | lote L2 | plan | 1 |/' \
  level_is 'lifted for the copy alone' 'level assisted — edited after signing' "$d" --lot L2
{ [ -e "$BOX/once-mark" ] && grep -qxF '| L2 | lote L2 | plan | 1 |' "$d/campaign.md"; } \
  || got="${got:+$got; }fixture: the ceiling was not put back after the copy"
mkdir -p "$BOX/terms-tmp"
TMPDIR="$BOX/terms-tmp" worker level "$d" --lot L2
TMPDIR="$BOX/terms-tmp" worker allows "$d" approve --lot L2
TMPDIR="$BOX/terms-tmp" worker level "$REPO/docs/campaigns/on-ren2"
[ -z "$(ls -A "$BOX/terms-tmp")" ] || got="${got:+$got; }the copies were left under TMPDIR: $(ls -A "$BOX/terms-tmp")"
d="$(campaign on-notmp full "$FAR" 25 200)"
sign "$d"
TMPDIR="$BOX/no-such-tmp" worker level "$d"
{ [ "$W_RC" = 1 ] && [[ "$W_OUT" == 'level assisted — unread: '* ]] && [[ "$W_OUT" != *$'\n'* ]]; } \
  || got="${got:+$got; }no TMPDIR: rc $W_RC, '$W_OUT' (want rc 1, 'level assisted — unread: …')"
if [ "$(id -u)" != 0 ]; then
  for k in delegation campaign; do
    d="$(campaign "on-unread-$k" full "$FAR" 25 200)"
    sign "$d"
    chmod 000 "$d/$k.md"
    LC_ALL="$NUM_POISON" worker budget "$d"
    why="${W_OUT#no ceiling — }"
    [[ "$W_OUT" == 'no ceiling — illegible: '* ]] || got="${got:+$got; }fixture on-unread-$k: budget '$W_OUT'"
    level_is "unreadable $k.md" "level assisted — $why" "$d" --lot L1
    [ "$W_OUT" = "level assisted — $why" ] || got="${got:+$got; }unreadable $k.md: level '$W_OUT', budget '$why'"
    chmod 644 "$d/$k.md"
  done
fi
if [ -z "$got" ]; then
  pass 'once: the level, the lots and the ceilings a verb authorizes are the ones whose digest it checked'
else
  fail 'once: the level, the lots and the ceilings a verb authorizes are the ones whose digest it checked' \
    'plan and an ask with the ceiling lifted after the digest, merge with the level raised after it, edited after signing when asked again; unread with no TMPDIR; the reason budget gives for an unreadable file' "$got"
fi

# --- verdict ------------------------------------------------------------------------------------
if [ "$PROBES" -lt "$PROBE_FLOOR" ]; then
  printf '  FAIL  probe floor shrank to %d, expected at least %d — did a block stop being dispatched?\n' \
    "$PROBES" "$PROBE_FLOOR" >&2
  exit 93
fi
if [ "$fails" -eq 0 ]; then printf '  ok    worker verbs: %d probe(s)\n' "$PROBES"; exit 0; fi
printf '  FAIL  %d probe(s) failed\n' "$fails" >&2
exit 1
