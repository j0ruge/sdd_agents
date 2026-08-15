# Pipeline — state machine and gates

How `sdd` decides what to run, and what each phase has to deliver to the next.

## The core idea: there is no state file

The current phase is **derived** from the artifacts on disk. `sdd run <mission>` walks the gates in
canonical order and executes **the first phase whose gate is not satisfied**.

Three consequences that justify the whole design:

1. **Resume for free.** Session died from the network, an OOM or a context overflow? `sdd run`
   again resumes at the exact point — there is no state to reconcile.
2. **The state cannot lie.** There is no file saying "QA phase complete" that could disagree with
   the disk. The disk is the phase.
3. **The QA⇄EXEC loop falls out for free.** When `sdd-qa` writes fix increments into
   `checkpoint.md`, the EXEC gate goes back to failing, and since EXEC comes before QA in the
   order, the next turn of the loop lands there. No loop code was written for this.

And the rule that holds it all up: **success is never the model's answer.** Every gate is
re-evaluated by the runner — running the tests, checking the hash in the `git log`, reading the
report, calling `gh`. The text the session returns satisfies no gate.

## Canonical order

```
PLAN → TICKET → EXEC ⇄ QA → REVIEW → DOCS → PR → (merge: human)
```

## Who measures the gates

The gates measure the mission. What measures **the gates** is `tests/check-mutation.sh`: it
sabotages `bin/sdd` in a copy — one sabotage per gate, plus the three that already cost paid
sessions — and demands the suite go **red** on each one. An assertion that cannot fail is
indistinguishable from one that passes, and that is how three gate bugs crossed a green suite.

Two practical consequences for anyone working here:

- **a new gate arrives with a mutation.** `sdd health` fails a gate with no entry in the catalogue
  — not out of courtesy, but because it is the only way to know the new gate is measured.
- **a fixture imitating a third-party skill is copied from the source**, with the path in a
  provenance comment. A fixture written from memory agrees with the wrong gate forever; the
  mutation alone would only prove the gate measures the imagined format rigorously.

`sdd health` runs all of that in one go and answers "does the kit still measure what it says it
measures?". It belongs to the **kit**; `sdd preflight` belongs to the **target repo's
environment** — do not confuse them.

## The gates

### PLAN — the only one the runner does not execute

Planning is interactive by design: it is where the human takes part. The runner only checks and
instructs.

**Passes when:** `00-missao.md`, `01-plano.md` and `checkpoint.md` exist; the mission frontmatter
carries `aprovacao: auto` or `aprovacao: humano-<date>`; with `JIRA_ENABLED=true`, `versao:` is
filled in; and `checkpoint.md` has at least one parseable row.

**PLAN-AUTO:** `aprovacao: auto` means `sdd-planner` closed the five criteria (grill with nothing
open, checklists, self-containment, a Check per increment, the version) **with evidence**. A
well-run grill is the approval — the human was present. Any criterion left open and the planner
leaves `aprovacao` empty, and the runner stops asking for explicit approval.

### TICKET — skipped when there is no JIRA

**Passes when:** `JIRA_ENABLED=false` (skip recorded), or `10-ticket.md` exists with `issue:`
**and** `sprint:` in the frontmatter.

Requiring `sprint:` is deliberate: a card created in the backlog is invisible work for the team.
The `ticket` skill creates it straight into the active sprint and confirms it left the backlog.

### EXEC — one session per increment

**Passes when:** every row of `checkpoint.md` is `done`; each `done` has a hash that really exists
in the `git log` and is reachable from HEAD; `TEST_CMD` exits 0; and `20-handoff-exec.md` exists.

**Jidoka:** any `blocked` increment escalates **on the spot** — no retry, no consuming the phase's
session budget. The executor marks `blocked` when the suite is red because of an earlier
increment. The reason is in the checkpoint's execution notes.

**Progress ≠ gate.** While increments remain, the gate failing is the **normal** case. The runner
tells the two apart by a state fingerprint (HEAD + artifacts + checkpoint hash): it changed ⇒ the
session moved forward, carry on; it did not change ⇒ the session did nothing, gets one retry with
the gate reason in the prompt and, if it still does not move, becomes `BLOCKED`.

### QA — three sub-steps, one phase

The phase is **three sessions**, and the current sub-step is **derived from the artifacts**
(`qa_substep`), never from a counter:

| Sub-step | Who drives | When | Delivers |
|---|---|---|---|
| `QA:plan` | `/qa-report` skill (no kit agent) | there is no charter in `<QA_DOCS_PATH>/charters/` | charters, personas, journeys |
| `QA:exec` | `/qa-execution` skill (no kit agent) | there is a charter, but no `closed` report | dated report + bug registry |
| `QA:close` | `sdd-qa` agent | report `closed` — or a project with no interface | e2e specs, fix increments, `30-handoff-qa.md` |

The two skills **own** `docs/qa/`; `sdd-qa` does not rewrite what they produced. A project **with
no interface** (no `E2E_CMD` and no `APP_URL`) goes straight to `QA:close`: bootstrapping browser
journeys in a project with no browser is the paperwork `skipped` exists to avoid.

**Passes when:** `30-handoff-qa.md` exists and (`status: skipped` **or** all of the conditions):

- **the evidence of the journey walked**, which takes two forms depending on the project:
  - **with an interface** (`E2E_CMD` or `APP_URL` set) — the most recent report in
    `<QA_DOCS_PATH>/reports/` is `**Status:** closed` and no row of the session matrix is still
    `Pending`;
  - **without an interface** (neither `E2E_CMD` nor `APP_URL`) — the `gate:` field of
    `30-handoff-qa.md` itself is filled in. Here the `qa-report`/`qa-execution` skills never ran,
    so the `docs/qa/` tree does not exist: demanding their dated report would require an artifact
    nobody produces, and the gate would be unsatisfiable precisely in the case where QA did the
    work and **found** something;
- no file in `<QA_DOCS_PATH>/bugs/` has `**Status:** open` (true in both cases);
- `TEST_CMD` exits 0 and `E2E_CMD` exits 0 (when set).

`wont-fix` and `invalid` do **not** block: they are a recorded human decision, not a pending
defect.

`qa: skipped` is a legitimate and expected answer: a diff with no user-visible change (refactor,
types, build, docs) has no journey to walk. Inventing a journey just to "have QA" is waste.

### REVIEW — Grade A on every criterion

**Passes when:** the most recent `40-review-r<N>.md` carries the `### Overall Grade` section with
**A on every row**; `TEST_CMD` exits 0; and the working tree is clean.

A criterion graded `—` (not analysed) fails too: a partial review is not a review.

The review→fix→re-review loop happens **inside** the session. If it ends without closing, the
runner opens a fresh session to continue, up to `REVIEW_MAX_ITER` in total. Blown →
`BLOCKED`, or a draft PR when `PUBLISH_ON_REVIEW_BLOCKED=draft`.

### DOCS — drift checklist

**Passes when:** `45-docs.md` exists with the drift checklist and **no pending item** in it. The
gate reads the `Status` COLUMN of the table, locating it by header position: every row must be
`✅` or `n/a`, and anything else fails, quoted verbatim in the reason. Every area touched by the
diff gets `✅` with a commit hash or `n/a` with a concrete justification.

Reading the column, and not the whole file, is deliberate: an earlier version grepped the file for
the word `TODO` and failed every `45-docs.md` that named `TODO.md` — which is exactly what
`sdd-docs` is required to do.

### PR — confirmed by `gh`, not by the file

**Passes when:** `50-pr.md` exists with `pr_url:` **and** `gh pr view <url>` confirms the PR
exists. A file claiming a PR that does not exist fails — and it is good that it does.

## Dry-run — the projection

`sdd run <mission> --dry-run` answers *"what happens if I run this?"* before spending tokens. It
walks the canonical order and prints **every** phase whose gate is unsatisfied, each with its
model, agent, session id, the full `claude` command and the boot prompt.

**It projects the present, it does not simulate the future.** The projection lists the gates
unsatisfied **today**. It does not try to guess that the EXEC phase would satisfy its own gate and
unblock QA. That is a deliberate choice: honest information is worth more than complete but
possibly wrong information — and a pipeline simulation that gets it wrong is worse than no
simulation.

That is why the projection **cannot** use `current_phase()`. Since the dry-run changes nothing on
disk, the unsatisfied gate stays unsatisfied and `current_phase()` would return the same phase
forever — an infinite loop. It advances through a cursor of its own over the `$PHASES` list
(`next_pending_phase()`).

Three cases where the projection stops early, and is meant to:

| Situation | What comes out | Exit |
|---|---|---|
| `PLAN` pending | the interactive instruction for the human; no phase projected | 2 |
| a `blocked` increment in the checkpoint | the Jidoka, with the reason; no phase projected | 3 |
| `--phase <PHASE>` | only the phase asked for — `--phase` forces, it does not project | 0 |

A confusing detail of vocabulary: the projection prints the **sub-step** (`QA:close`), while
`--phase` takes the name of the **phase** (`QA`). Copying `QA:close` into `--phase` does not work —
the sub-step is derived from the artifacts, never chosen on the command line.

### What the dry-run touches, and what it does not

The easy sentence — "the dry-run touches nothing" — is false, and `--help` does not use it. The
real guarantee is narrower, and it is this:

- **it spends no session:** no `claude` is invoked;
- **it does not touch the mission artifacts:** nothing is written to `docs/handoffs/<mission>/`;
- **it does not write to the journal:** the guard lives inside `pipeline_log_line()`, not in the
  callers. Three paths log before any session (checkpoint `blocked`, budget blown, two sessions
  with no progress) and a fourth added tomorrow would be born with the defect again; a single
  guard makes "the projection does not write to the journal" true by construction;
- **but the gates do run for real:** working out which phases are pending requires evaluating the
  gates, and `gate_EXEC`/`gate_QA`/`gate_REVIEW` run `TEST_CMD`. That writes
  `.sdd/logs/<mission>/gate-*-test-<ts>.log` — gitignored, memoized per process in
  `run_check_cmd`, but real. Anyone expecting zero cost in a repo with a slow suite needs to know
  this.

## After the PR

The **merge is human**, and it is the pipeline's only unconditional human gate. The "Decisions for
a Human" accumulated by the phases arrive as a section of the PR: they inform the merge decision,
without ever having blocked the automation.

Post-merge, `sdd close <mission>` closes the JIRA issue with an automatic summary (the
`/ticket close` skill, model `MODEL_TICKET`). It refuses to run outside the right place, and each
refusal is deliberate:

| Condition | What happens |
|---|---|
| `JIRA_ENABLED=false` | not an error — reports "nothing to close" and exits 0 |
| no `issue:` in `10-ticket.md` | error: the TICKET phase did not run, there is nothing to close |
| `50-pr.md` with a `pr_url:` whose PR is not `MERGED` | error: `sdd close` is **post-merge**, and closing the issue before the merge lies to the board |

`sdd close` is the only invocation of `claude` outside `run_phase()` besides the `sdd preflight`
probe — neither of them runs a phase.

## Models per phase

Opus where there is judgement (EXEC, QA, REVIEW, DOCS), Sonnet where the task is mechanical (PR,
TICKET), Fable in interactive planning. The cost exception is **explicit in the config**, never
silent — `MODEL_PUBLISH="sonnet"` is there to be read and challenged.

## Language

The kit is English. The **artifacts** of a mission follow `OUTPUT_LANG` from the target repo's
`.sdd/config.sh`, which the runner passes into the boot prompt of every phase; empty, and the
runner says nothing about language and each session follows what the existing artifacts use.

The contract never moves: file names, frontmatter keys, status tokens
(`pending|doing|done|blocked|auto|skipped`), the enums owned by the `qa-report`/`qa-execution`
skills, and the `### Overall Grade` criteria of `codereview` are English in every repo, because
the runner greps them. The kit's own surface is guarded by `tests/check-lang.sh`.

## Permissions

The runner passes `--permission-mode acceptEdits` **and** `--allowedTools "$ALLOWED_TOOLS"`
(default `Bash`). Both are necessary: `acceptEdits` auto-approves file edits, but **not** `Bash` —
without the allowlist the session cannot run the suite nor commit, and the EXEC phase becomes
unsatisfiable by construction. `bypassPermissions` is never the kit's default.

`sdd preflight` proves this by firing a real headless session with the same flags and demanding it
**execute** a command. "claude answers" does not cover this failure mode.

## Costs and logs

Every session becomes a line in `.sdd/logs/<mission>/pipeline.log` (phase, agent, model, session
id, exit code, duration, cost in USD) and a full JSON alongside it, in the same
`.sdd/logs/<mission>/`. The journal is **ephemeral by contract**: `.sdd/logs/` is in the
`.gitignore` that `sdd install` writes, and the durable record of what happened is the committed
handoffs. If it moved back into the committed tree it would dirty `git status` — and a dirty tree
fails `gate_REVIEW` and `sdd preflight`. `--max-budget-usd` per session is a damage cap, not a
budget.
