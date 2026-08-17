# Failure modes

What breaks, how the kit reacts, and what **you** do. Ordered by expected frequency.

General rule before any diagnosis: run `sdd status <mission>` and `sdd why <mission>`.
The runner can tell you which gate it stopped at and why — do not guess.

---

## The session cannot execute commands

**Symptom:** the EXEC phase commits nothing; the session log says *"This command requires
approval"* or *"command blocked"*. The gate fails with "1 of N increments still to execute"
forever.

**Cause:** `--permission-mode acceptEdits` auto-approves **file edits**, not `Bash`. Without
`--allowedTools`, the session reads but does not run the suite and does not `git add`.

**How the kit reacts:** `sdd preflight` catches this before any mission — it fires a real headless
session with the same flags and demands it execute a command.

**What you do:** check `ALLOWED_TOOLS` in `.sdd/config.sh` (default `Bash`). This was the first
structural defect the kit found in itself, in the fixture mission `20260814-dry-run-completo`.

---

## A `blocked` increment

**Symptom:** `sdd run` exits with code 3 and "BLOCKED in EXEC" straight away, without opening a
session.

**Cause:** the executor found the suite red because of an **earlier** increment and stopped. That
is Jidoka working: a red sensor stops the line.

**What you do:** read the execution notes in `checkpoint.md` — the reason is written there. Clear
the impediment, set the increment back to `pending`, run `sdd run` again.

**Do not:** mark it `done` to get unstuck. The gate checks the hash in the `git log` and the real
suite; you would only lose the next session.

---

## `sdd kaizen` exited 3 (piorou)

**Symptom:** `sdd kaizen` prints "the previous kit change made autonomy WORSE — the line is
stopped" and exits with code 3, with no plan born.

**Cause:** the judge compared the autonomy series before and after the latest kit change and
concluded the change hurt. That is the loop's own Jidoka (ADR 0002): planning the next mission on
top of a regression would compound it, so the verdict is written and the line stops.

**What you do:** read the `05-verdict.md` the message points at — it cites the series' numbers
(labels, `moved_rate`, escalations, cost) and the hypotheses. Decide: revert the kit change, fix
it, or overrule the judge with your own reasons. Then run `sdd kaizen` again — a new verdict for
the new kit sha reopens the loop.

**Do not:** delete or edit the verdict to unblock the loop. The verdict is the series' memory;
a judged regression that disappears from the record will be re-attempted.

---

## The series is empty, or the rows "were born in another repo"

**Symptom:** `sdd kaizen --series` returns `latest: null` with `excluded.other_repo: N`, or
`sdd autonomy` refuses with rc 1 naming the same count. The ledger file is right there and it is
not empty.

**Cause:** the file is global, the **reading is per repo by default** — one predicate admits only
the rows whose `repo` equals the repo you are standing in. Three ordinary ways to land here:
reading from a directory that is no git repository at all; reading in the kit repo while every
session was spent on a target (or the reverse); or reaching the repo through a path the rows do not
carry — a symlink, or a **worktree row written before** `c514e36`, when identity still came from
`git rev-parse --show-toplevel` and every worktree therefore looked like a repo of its own.

**What you do:** run the reader **inside** the repo whose missions you want to judge, and compare
what `ledger_repo_root` derives — `cd "$(git rev-parse --git-common-dir)/.." && pwd -P`, the shared
`.git` and never the per-worktree toplevel — with
`jq -r .repo ~/.sdd/autonomy-log.jsonl | sort -u`. If the question really is cross-project
maturity, that is what `--all-repos` is for: `sdd autonomy --all-repos`, `sdd kaizen --series
--all-repos`. ⚠️ At read time the comparison is verbatim on both sides by design: a `realpath`
invented there would silently merge two checkouts the ledger deliberately keeps apart. Full
contract in [`pipeline.md`](pipeline.md) § "The autonomy ledger".

**Do not:** read this as data loss. What the filter removed is **counted**, and by reason —
`excluded.other_repo` for rows born elsewhere and `excluded.no_repo` for rows that name no project
at all, one `N row(s) excluded` line each in the human table, plus a fourth "no data" silence when
the whole ledger is unattributable. An empty series is `guard.sufficient: false`, which supports
only `indeterminado`. A throwaway fixture repo's numbers read as a verdict about this kit is
exactly what the default filter exists to prevent.

⚠️ **`sufficient: false` in the kit repo is not this failure mode.** If `guard.degenerate_axis` is
`true`, every kit version in the slice bought exactly one session and no number of missions *here*
will clear the floor — the axis is being read in the repo that builds the kit. `sdd kaizen` says so
and names [ADR 0003](adr/0003-judge-axis-evidence-from-target-repos.md); the floor is not the
defect and does not loosen.

---

## A context window overflow in the middle of an increment

**Symptom:** the session dies or returns a truncated answer; the checkpoint did not advance.

**How the kit reacts:** the state lives on disk. `sdd run` again boots a **fresh** session from the
checkpoint — there is nothing to recover.

**If it repeats on the same increment:** the slice is too big. Go back to `sdd-planner` and
re-slice. Retrying forever against a badly sized slice is waste, not persistence.

---

## A flaky test

**Symptom:** the gate fails, you run the command by hand and it passes.

**How the kit reacts:** the gates memoize per process, so one runner execution measures once.

**What you do:** confirm the intermittency (run it 3×). A confirmed flaky becomes a line in the
target repo's `TODO.md` **and** a note in the mission handoff. Do not "fix" the flaky inside the
mission: it is another scope, and the kit has a place for it.

---

## A BSD userland (macOS without GNU tools)

**Symptom:** the runner starts and behaves strangely instead of stopping. Phases get escalated
for "no progress" even though the session committed; the mission journal has empty timestamps.

**Cause:** the kit calls `md5sum`, `date -Iseconds` and `sort -V`, and its own suite calls
`sed -i` with no argument and `grep -P`. The BSD tools macOS ships reject all of them. The
failure is quiet where it hurts most: `state_fingerprint()` pipes through `md5sum` with stderr
discarded, so a missing `md5sum` yields an EMPTY fingerprint — every session then looks identical
to the previous one, and the runner escalates work that was in fact advancing.

**How the kit reacts:** the bash-4 check at the top of `bin/sdd` speaks only for bash, and used to
imply that `brew install bash` was enough — it is not. `sdd preflight` now probes the three tools
by behaviour (not by presence: brew installs them as `gmd5sum`/`gdate` unless `gnubin` comes first
in `PATH`, so the name existing proves nothing).

**What you do:** `brew install bash coreutils gnu-sed grep`, then put the `gnubin` directories
first in `PATH`. The kit is developed and measured on Linux; macOS is supported only in that
configuration, and `tests/check-preflight.sh` is what keeps the probe honest.

---

## `agent-browser` missing or hung

**Symptom:** `agent-browser: command not found`, or the QA phase hangs.

**Known cause:** a shim in `~/.nvm/versions/node/*/bin/agent-browser` pointing at
`~/.hermes/hermes-agent/node_modules/...`, which does not exist.

**How the kit reacts:** `sdd preflight` checks `agent-browser --version` whenever `E2E_CMD` or
`APP_URL` is set.

**What you do:**
```bash
ln -sf ../lib/node_modules/agent-browser/bin/agent-browser.js \
  ~/.nvm/versions/node/<version>/bin/agent-browser
```

---

## The QA⇄EXEC loop does not converge

**Symptom:** `BLOCKED in QA` after `QA_MAX_ITER` rounds; the bug registry does not empty.

**Typical cause:** each fix breaks another journey — a sign the defect is deeper than the recorded
symptoms.

**What you do:** read the `30-handoff-qa.md` of each round. If the bugs move around every round,
the problem is one of design and belongs back in planning, not with the executor.

---

## The review does not close at Grade A

**Symptom:** `BLOCKED in REVIEW` after `REVIEW_MAX_ITER` sessions.

**What you do:** read the last `40-review-r<N>.md` — the real grade is there. If the findings are
legitimate and large, the mission was badly sliced. If you want the PR anyway, set
`PUBLISH_ON_REVIEW_BLOCKED="draft"`: out comes a **draft** PR with the current grade and the open
items visible, instead of hiding the problem.

**Never:** edit the report to put an A there. That switches off the mission's only quality sensor.

---

## The runner published a draft PR by itself

**Symptom:** the mission ends with a **draft** PR and a review that never reached Grade A.

**Cause:** `PUBLISH_ON_REVIEW_BLOCKED="draft"` plus a review out of `REVIEW_MAX_ITER` rounds. The
runner lowered its own bar and carried on — by design, and the one autonomy event where it decides
by itself to ship less.

**What you do:** the decision leaves a trail in three places. `warn "PUBLISH_ON_REVIEW_BLOCKED=draft
— moving on to PR in draft mode"` on the terminal, a `DEGRADED` line in
`.sdd/logs/<mission>/pipeline.log`, and one `event:"degraded"` / `kind:"review-to-draft"` row in the
autonomy ledger — visible in `sdd autonomy` and in the judge's `escalations`. Read the last
`40-review-r<N>.md` for the real grade, then choose: merge the draft with the open items visible, or
hand the mission back to REVIEW with more rounds.

**Reading the count:** all three trails are written **once per run**, so `review-to-draft: 3` in
either reader means three runs — never one run that degraded three times.

**If the draft PR does not close either:** the run ends there, with `BLOCKED in REVIEW` and a
`blocked` / `budget-exhausted` row naming **REVIEW**. The draft was the one chance, and the phase
named is the one whose ceiling was actually blown. The runner used to hand REVIEW back instead and
go round again — REVIEW→PR→REVIEW with the budget still blown — until PR ran out of its own budget
and the escalation came out blaming **PR**, a phase that was never over budget. If you are reading
an old ledger and a `budget-exhausted` in PR follows a `review-to-draft`, that is what you are
looking at.

**Do not:** silence it by setting `PUBLISH_ON_REVIEW_BLOCKED="off"` and re-running until the review
passes. Off is the default precisely because a stop is louder than a draft; switching it on and then
hiding the record is the worst of the two.

---

## `sdd preflight` fails: an agent is `stale`

**Symptom:** `agent sdd-<x>.md stale — .claude/agents/sdd-<x>.md no longer matches <kit>/agents/…`,
and the preflight refuses before any mission starts.

**Cause:** the harness loads the **copy** in `.claude/agents/`, never the kit source. The two
drifted — usually a kit that moved (`git pull`, a kit mission) with nobody re-installing. Until the
mission `20260816-kit-como-alvo` the preflight only checked that the copy **existed**, so "source
corrected" and "agent still running the old text" looked identical: green on both.

**What you do:** `sdd install` to read the diff first, then `sdd install --force` to adopt the kit
version. If the divergence is a deliberate customisation, keep it and record in the kit's `TODO.md`
why — but the preflight will keep failing, and that is the point: a target running an agent of its
own should have to say so out loud.

**Not the same as** the next entry: that one is information at install time, this one is a gate
refusing to spend a session on an agent that is not the one you think you are running.

---

## `sdd install` shows a diff in the agents

**Symptom:** warnings "agent X differs from the kit version" with a diff.

**Cause:** the target repo has a customised (or old) version of the agent. That is information,
not an error.

**What you do:** `sdd install --force` adopts the kit version. If the customisation was
deliberate, keep it — and record in the kit's `TODO.md` why it exists: a recurring customisation
is a sign the kit's agent needs to change.

---

## `sdd install` refuses to run: the kit has no `config/starter.conf`

**Symptom:** `error: the kit at <path> has no config/starter.conf …`, rc 1, and **no**
`.sdd/config.sh` in the target repo.

**Cause:** the kit checkout is incomplete — a partial copy, a clone that lost a file, a `$PATH`
pointing at a `bin/sdd` whose `config/` was left behind. `sdd install` builds `.sdd/config.sh`
out of that template.

**What you do:** re-copy or re-clone the kit, then run `sdd install` again. The guard fires
**before** the file is written, so there is nothing to clean up on the target side.

⚠️ **Reading an older target.** Before this guard existed the redirect ran anyway and left a
**0-byte** `.sdd/config.sh` behind. The damage is not the first run — it is the *second*: the
next `sdd install` finds the file, prints `ok … already exists (preserved)` with rc 0, and the
repo carries on with no `TEST_CMD` at all. A target whose gates behave as if every key were
empty is worth one `wc -c .sdd/config.sh`; on `0`, delete it and install again.

---

## The runner refused to switch to the declared branch

**Symptom:** `sdd run` (or `sdd retry`) exits before opening any session, with one of three
messages naming the `branch:` field of `00-missao.md`.

**Cause and what you do**, one per message:

| The runner said | What happened | What you do |
|---|---|---|
| `could not switch to the branch '<name>' … — git said: <git's own message>` | git declined the checkout. Usually the working tree carries changes the switch would overwrite. | Deal with the tree the way you would for any checkout — `git stash`, commit, or discard. The kit will not choose for you: picking one of those three is deciding whose work survives. |
| `the branch '<name>' … starts with '-' — git would read it as an option` | the declared name would reach `git checkout` as a flag. `git checkout -f` is a legal command that returns 0 and throws the whole dirty tree away, so the shape is refused before git sees it. | Fix `branch:` in `00-missao.md`. |
| `the branch '<name>' … does not carry this mission — you are now on it, and the plan that asked for it is on '<other>'` | the checkout worked and the mission's artifacts are not on the branch it asked for — an old branch of the same name, or one cut before the mission existed. | Go back (`git checkout <other>`) and decide which branch the mission belongs on. **Do not** re-run from here: the pipeline would spend sessions against a plan nobody approved on this branch. |

**How the kit reacts:** it stops, every time — `die`, no session spent, nothing guessed. Carrying
on from wherever the checkout left the tree is the SQ-97 class the field exists to close
([the mission's branch](pipeline.md#the-missions-branch)).

A mission that should not move branches at all leaves `branch:` at the `<…>` placeholder the
template ships, which is a no-op — that is the right value whenever the name is not yours to
decide.

---

## A conflict with the base branch on push

**Symptom:** `50-pr.md` with `status: blocked` and the reason for the conflict.

**Why:** `sdd-publisher` **does not resolve conflicts**, by design. Resolving a conflict is
deciding which of two intents wins — human judgement. An automatic rebase here is the cheapest way
to lose somebody else's work.

**What you do:** resolve the conflict by hand, then `sdd run <mission>` for the PR phase to carry
on.

---

## Upstream skill drift

**Symptom:** a gate fails even though the artifact looks correct.

**Cause:** the kit anchors on **few** format points of third-party skills, and those can change:

| Gate | Anchor | Skill |
|---|---|---|
| QA | `**Status:** closed` in the report; `Pending` rows in the matrix; `**Status:** open` in the bugs | `qa-execution` / `qa-report` |
| REVIEW | the `### Overall Grade` section and the `Grade` column | `codereview` |

**What you do:** check the skill's current format and adjust the anchor in `bin/sdd` — and update
`tests/check-gates.sh` in the same commit, so the sensor catches the next drift. `sdd health`
compares the fixtures against the installed skills and reports the divergence on its own.

---

## Cost higher than expected

**What you do:** `.sdd/logs/<mission>/pipeline.log` has one line per session with cost and
duration; `<PHASE>-<ts>.stream.jsonl` beside it has that session's whole event stream, so an
expensive phase can be read turn by turn instead of guessed at — and `tail -f` on it answers
"what is it doing right now?" while the phase is still running.
`BUDGET_PER_PHASE_USD` is a per-session cap (maximum damage), not a mission budget. If a
phase is expensive over and over, the problem is usually a badly sliced plan — big sessions
re-exploring what the "verified context" should have handed over ready.
