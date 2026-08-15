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

## `sdd install` shows a diff in the agents

**Symptom:** warnings "agent X differs from the kit version" with a diff.

**Cause:** the target repo has a customised (or old) version of the agent. That is information,
not an error.

**What you do:** `sdd install --force` adopts the kit version. If the customisation was
deliberate, keep it — and record in the kit's `TODO.md` why it exists: a recurring customisation
is a sign the kit's agent needs to change.

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
duration. `BUDGET_PER_PHASE_USD` is a per-session cap (maximum damage), not a mission budget. If a
phase is expensive over and over, the problem is usually a badly sliced plan — big sessions
re-exploring what the "verified context" should have handed over ready.
