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

**And that explicit approval is a command, not a hand edit.** `sdd approve <mission>` prints what is
being approved — the title, the PLAN-AUTO evidence, the increments, the open questions — asks
`[y/N]`, and only on an explicit yes writes `aprovacao: humano-<date>` and commits **that one file**.
It never opens a session: approving is the one decision in the pipeline that has to come from
outside it. Whenever the gate stalls on the field it names the command in its own reason, because a
refusal that does not carry its remedy sends the human back to typing `humano-YYYY-MM-DD` into the
frontmatter by hand — which is the failure the command exists to end.

**And `auto` is refused outright on a kaizen-born plan.** When `05-verdict.md` sits beside the
mission's artifacts, the plan came out of [the kaizen loop](#the-kaizen-loop) — the kit planning
its own next change, with no human in the room. The premise `auto` rests on is false there, so the
gate stalls the mission with `run 'sdd approve <mission>'` however the field got filled. The human
closes it with `sdd approve <mission>`, which writes `humano-<date>` and commits. This is
`gate_KAIZEN`'s "the loop never approves its own plan" enforced a second time, at the gate
`sdd run` actually asks.

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
`BLOCKED`, or a draft PR when `PUBLISH_ON_REVIEW_BLOCKED=draft` — the one place the runner lowers
its **own** bar instead of stopping, and it records the fact once per run (`event:"degraded"`, in
the ledger's field reference below).

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

## The mission's branch

`branch:` in `00-missao.md` was decorative until `ensure_mission_branch()`. The runner now reads it
**before the first gate** of every `sdd run` and every `sdd retry`, and puts the pipeline on the
branch the plan declares:

| `branch:` | What the runner does |
|---|---|
| the `<…>` placeholder the template ships, or empty | nothing — the mission runs where you are |
| the branch you are already on | nothing |
| a branch that exists | `git checkout <name>` |
| a branch that does not exist | `git checkout -b <name>` **from the branch you are standing on** — the one the plan's own commit lives on |

A name starting with `-` is refused by the runner itself, before git sees it: `git checkout -f` is
a legal command that returns 0, switches to nothing and throws away every uncommitted change.
Everything else git refuses — a space, `..`, a dirty tree the checkout would overwrite — becomes a
`die` carrying git's own message. And the artifact is re-read **after** the switch: a branch that
does not carry this mission's `00-missao.md` also stops the line, because the alternative is
spending sessions against a plan nobody approved there. All of it before a single session is spent;
what to do about each is in
[`docs/failure-modes.md`](failure-modes.md#the-runner-refused-to-switch-to-the-declared-branch).

The failure this closes was measured: in the SQ-97 pilot five phases committed into another PR's
branch — 16 commits over somebody else's work, ~US$ 45 of `rebase --onto` to undo. Committing on
the wrong branch is loud now in **all five doors that can end up committing** — `sdd run`,
`sdd retry`, `sdd approve`, `sdd kaizen` and `sdd preflight` — each warning when you are standing
on the base branch. The warning has one definition, so sabotaging it silences all five at once and
the suite dies; the two call sites added last (`sdd retry` and `sdd approve`) carry a mutation of
their own, because for those two the defect was the missing call, not the missing warning.

Two things it deliberately does not do:

- **it never runs in `--dry-run`** — a checkout is a mutation of state, and that is the half the
  projection promises not to touch (below);
- **it never learns the branch the TICKET phase creates.** With `JIRA_ENABLED=true` that name
  lands in `10-ticket.md` and nothing copies it into the field the runner reads, so `branch:`
  stays at the placeholder and this guard is a no-op. The SQ-97 class dies on the path without
  JIRA, which is the only path this has been walked on.

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
- **it does not switch branches:** `ensure_mission_branch()` returns before touching git in a
  projection — see [the mission's branch](#the-missions-branch) for what it does outside one. A
  checkout is a mutation of the working tree, which is the half the dry-run does promise, and it is
  the loudest state change the runner makes: leaving it out of this list would make the list read
  as complete while the one thing a human fears from a projection went unmentioned;
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
id, exit code, duration, cost in USD) and two files alongside it, in the same
`.sdd/logs/<mission>/`:

- `<PHASE>-<ts>.stream.jsonl` — the session's whole event stream, one JSON object per line,
  written **as it happens**. This is what you `tail -f` to watch a headless phase that is still
  running, and what is left behind by one that was killed halfway. The runner asks the CLI for
  `--output-format stream-json --verbose`; the two flags are one flag, since the CLI refuses
  `stream-json` under `--print` without `--verbose`.
- `<PHASE>-<ts>.json` — the terminal `result` object of that stream, distilled at the end. It is
  byte for byte what the older `--output-format json` used to print, and it is what the runner
  reads the session's cost out of. A session killed mid-write leaves a half-finished last line in
  the stream; the distillation keeps every object that DID close, so the summary and the cost
  still land. The run is never taken down by its own log being ragged.

Plus `<PHASE>-<ts>.err` for the session's stderr. The journal is **ephemeral by contract**: `.sdd/logs/` is in the
`.gitignore` that `sdd install` writes, and the durable record of what happened is the committed
handoffs. If it moved back into the committed tree it would dirty `git status` — and a dirty tree
fails `gate_REVIEW` and `sdd preflight`. `--max-budget-usd` per session is a damage cap, not a
budget.

## The autonomy ledger

Two records, different jobs. `.sdd/logs/<mission>/pipeline.log` is the **journal of one mission**,
ephemeral and local. `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl` is the **series across all
missions and all projects**, and it exists for one reader: the kaizen judge (`sdd kaizen`, driven
by the `sdd-kaizen` agent — see "The kaizen loop" below), which answers "did the last change to
the kit improve autonomy or hurt it?".

It is global, not per-repo, for two reasons. Maturity across projects cannot be measured in a
file that lives inside one project. And a file the runner writes BETWEEN phases inside the target
repo would sit untracked and fail `gate_REVIEW` and `sdd preflight` — the `pipeline.log` defect,
which was fixed by making that journal ephemeral, a way out this ledger does not have.

**The file is global; the READING is per repo.** Every reader — `sdd autonomy`, `sdd kaizen
--series`, and the reminder printed after a pipeline completes — admits only the rows whose `repo`
field equals the repo it is standing in, through one predicate (`ledger_row_is_local` in
`bin/sdd`) spliced into all of them. Without it the ledger was a namespace shared by accident: a
`sdd run` inside a `/tmp` fixture repo wrote three rows into the real ledger and the judge read
`66% waste · 2 mission(s)` where the truth was `0% · 1` — its own source of truth, contaminable
by any test. Three consequences worth knowing:

- what leaves is **counted, never dropped in silence**: `excluded.other_repo` in the series, and
  one `N row(s) excluded: born in another repo` line in the human table;
- a row that cannot say where it came from — not an object, or an object with no `repo` key — is
  **never** excluded by the filter. It reaches the bucket that names it (`unrecognized`, or a loud
  death naming the file) in whichever repo you are standing in: hiding corruption is the one thing
  a filter must not do;
- read from **outside any git repository**, nothing in the ledger is yours: `sdd autonomy` refuses
  with rc 1 saying the rows exist under another repo, and `sdd kaizen --series` warns and returns
  the empty series. That is the safe direction — an empty series is `guard.sufficient: false` and
  supports only `indeterminado`, never somebody else's numbers read as a verdict about this kit.

It records **facts, never a score**: phase, attempt, whether the session moved the disk, rc, cost,
the gate result and its reason. `ok|leve|refez` is a label, and a runner that labels its own work
is the "label instead of artifact" every gate here exists to forbid. The judge derives the label,
and can change its yardstick later without rewriting the past.

Every row carries `kit_sha` and `kit_dirty`. That is the before/after axis: without it a change
in the numbers gets attributed to the calendar instead of to the kit change that caused it, and
the judge cannot count missions per kit version to answer "not enough data yet".

### Field reference

This is the whole interface the judge (`sdd kaizen --series`) is written against — every field a
row can carry, one row per field.

There are **two row shapes**, not three: a *session* row (`event:"session"`) and an *escalation*
row, which is any row that spent no session — `event:"blocked"` or `event:"degraded"`. Escalation
rows carry only the columns marked "on escalation rows" in "absent when"; everything else is
present on both shapes.

| Field | Type | Absent when | Meaning |
|---|---|---|---|
| `v` | integer | never | Schema version of the row, `1` today. Lets the reader tell "old shape" from "malformed" when a future field is added. |
| `ts` | string | never | `date -Iseconds` timestamp of when the row was written. |
| `event` | string enum: `session` \| `blocked` \| `degraded` | never | A spent session versus a no-session escalation. `blocked` means the line **stopped** (the runner returns 3 and a human has to act); `degraded` means the runner lowered its own bar and **carried on**. They are kept apart on purpose: reusing `blocked` for a degradation would have been cheaper — it inherits the `kit_sha` axis and the aggregation with no `jq` to touch — but it records "stopped" for a run that continued, and the ledger exists to record fact. |
| `kind` | string enum: `increment-blocked` \| `budget-exhausted` \| `no-progress` \| `review-to-draft` | on `event:"session"` rows | Which escalation path fired. `increment-blocked` is a deliberate Jidoka (can be a *good* sign); `budget-exhausted` and `no-progress` are pure friction. `review-to-draft` is the only `degraded` kind today: `PUBLISH_ON_REVIEW_BLOCKED=draft` and the review out of rounds, so the runner publishes a draft PR by itself instead of stopping. **At most one `review-to-draft` row per `run_id`**, and now at most one *jump*: the draft PR gets a single chance, and if its own gate fails the run ends on `blocked` / `budget-exhausted` in REVIEW rather than looping REVIEW→PR→REVIEW with the budget still blown. Before that, the branch was re-entered every lap and wrote a row every lap — both readers agreeing on a wrong number, which is worse than one of them being wrong. |
| `run_id` | string (uuid) | never | One per `cmd_run`/`cmd_retry` invocation. Groups every row a single command call produced — "this mission needed N runs" is a `run_id` count. |
| `invocation` | string enum: `run` \| `retry` | never | Which command opened the session: `sdd run` or `sdd retry`. Answers "who opened the session", not "was this an in-loop retry" — that is `auto_retry`. |
| `kit_sha` | string \| `null` | never absent, but `null` | `null` when `$SDD_HOME` is not a git checkout. Short SHA of the kit's own HEAD when the row was written — the before/after axis the whole ledger exists for. |
| `kit_dirty` | boolean \| `null` | never absent, but `null` | `null` exactly when `kit_sha` is `null` (paired). `true` means the kit's own working tree had uncommitted changes — the row is real but not comparable across versions. |
| `project` | string | never | `PROJECT_NAME` from the target repo's `.sdd/config.sh`. |
| `repo` | string | never | Absolute path of the target repo, as `git rev-parse --show-toplevel` returns it — can carry client-identifying paths, which is why the ledger stays in `$HOME` and is never committed. It is also the **only** field the readers filter on before anything else: see "The file is global; the READING is per repo" above. Compared verbatim, with no normalization on either side, so a repo reached through a symlink is a different repo. |
| `mission` | string | never | The mission slug. |
| `phase` | string | never | The pipeline phase (`EXEC`, `QA`, …). `PLAN` never appears — the interactive phase spends no session. |
| `step` | string | on escalation rows | The sub-step actually run (`QA:plan`, `QA:exec`, `QA:close`); equal to `phase` outside QA. |
| `agent` | string | on escalation rows | The kit agent that drove the session. Empty string (not absent) when a third-party skill drove it through the literal slash instead. |
| `model` | string | on escalation rows | The model configured for the phase. |
| `attempt` | integer \| `null` | on escalation rows | ⚠️ Not a session counter: `cmd_run`'s in-loop retry row carries the SAME `attempt` as the row right before it, so `(mission, phase, attempt)` is not a key. And `cmd_retry` always writes `1`, no matter how many times the human has already pushed the phase by hand. |
| `auto_retry` | boolean | on escalation rows | Whether this row is the runner's own automatic second attempt at the phase, inside one `sdd run` loop — never about which command opened the session (that is `invocation`). Renamed from `retry`: the old name next to `invocation:"retry"` read as its own negation, and both the obvious `jq` filters on the old name (`select(.retry==true)`, `select(.invocation=="retry")`) silently missed the other kind of retry. |
| `session` | string (uuid) | on escalation rows | ⚠️ On an in-loop retry row this is the PARENT session's id, not the fork's: `run_phase` builds the retry with `--resume … --fork-session` and without `--session-id`, so the runner never learns the fork's own id. Two consecutive rows can therefore share one `session` value. |
| `rc` | integer \| `null` | on escalation rows | The `claude` process's exit code. `null` when the session log carried none. |
| `dur_s` | integer \| `null` | on escalation rows | Wall-clock seconds the session took. |
| `cost_usd` | number \| `null` | on escalation rows | The session's cost in USD, `null` (never the string `"?"`) when the session's JSON log carried no cost field. |
| `moved` | boolean | on escalation rows | ⚠️ The whole waste metric: `state_fingerprint` before ≠ after, and `state_fingerprint` is git HEAD + the mission directory listing + the checkpoint file's md5. `moved:false` is exactly what `sdd autonomy` counts as a stalled session. |
| `gate` | string enum: `pass` \| `fail` | on escalation rows | The gate's verdict, evaluated right after the session ended — the row is born after the gate, never before it. |
| `gate_why` | string, truncated to 200 characters | never | The gate's stated reason (on an escalation row, the reason the phase was not satisfied when the runner gave up on it). |

A **new `event` value has to be taught to both readers in the same commit**, or it trades one
blind spot for another: `kaizen_series`'s `select` counts anything it does not admit in
`excluded.unrecognized`, and `cmd_autonomy`'s `is_escalation` does the same for the human. A row
the runner itself wrote and its own reader files as "unrecognized" is the defect, just moved.

Admitting the row is **not enough** — a new escalation `event` also has to reach `phase_label`,
the rubric behind the `labels` histogram the judge is told to cite. The rubric groups by
`(mission, phase)` over the whole `kit_sha` slice, **not per run**: "the failing session in that
run already reads `refez`" stops being true the moment a later `sdd run` gets the phase past its
gate. That is why `blocked` is a clause of the rubric rather than being left to the sessions
around it — an escalation outlives the session that provoked it — and `degraded` is an escalation.
Both readers now share one `is_escalation` definition per program for exactly this reason: the
pair written out by hand in three places is how they came to disagree in the first place.

`sdd autonomy` prints the human view. The judge reads the JSONL with `jq` — never that table.
Both readers group escalations on the **same axis**, `kit_sha`, and both drop a row with a dirty
kit or no sha into a counted-and-excluded bucket. Two instruments over one file that report
different counts for the same period corrode the trust the whole loop runs on, and kit version is
the axis the ledger exists to measure — so a change to one reader's grouping belongs in the same
commit as the other's.

## The kaizen loop

The ledger records; `sdd kaizen` closes. Run **in the kit repo** (it refuses anywhere else), it
judges the previous kit change and gives birth to the kit's next mission plan — detection without
closure is inventory, not improvement.

The judge is split in two (ADR 0001):

**The runner derives the numbers.** `sdd kaizen --series` prints a versioned JSON (`v: 1`) about
the repo it runs in — the file is global, the reading is not, see above: `latest` and `previous`
kit versions (by
**file order** of first appearance, never by sort — and a reappearing old sha rejoins its old
group), each with missions, `missions_with_session` (the subset that bought an observation — the
guard below counts these, not the raw mission tally), sessions, `moved_rate`, cost, escalations
by kind, a per mission×phase `detail`, and a label per group:

- `refez` — an escalation, a human `sdd retry`, or the phase's last session still failing its
  gate: the work was pushed again.
- `leve` — an in-loop auto retry, or a session that did not move the disk: friction, absorbed.
- `ok` — none of the above.

Plus a `guard` (`missions_after_change`, `missions_with_session`, `sessions`,
`sufficient: missions_with_session >= 3` — a mission that only escalated ran, and is counted as
one, but bought the judge no observation and so does not raise the floor;
`degenerate_axis`, true when every kit version in the slice bought exactly one session **and**
there is more than one of them) and an `excluded`
accounting with four reasons
(`non_comparable` dirty-kit rows, `unrecognized` rows, the `meta` rows the kaizen sessions
themselves write — the loop never lets its own sessions shift the axis it is judged on — and
`other_repo`, the rows born somewhere else). The empty-ledger branch prints the same key set with
zeros: a consumer must never read `null` on one branch where the other gives a number.

`degenerate_axis` exists because `sufficient: false` alone says two different things. In a target
repo it means "not enough missions yet", and waiting works. In the repo that **builds** the kit
every session commits, so the next one lands on a fresh `kit_sha`, every version holds exactly one
session and the floor is unsatisfiable by construction — waiting never works, and `indeterminado`
there is the correct answer rather than a broken runner. `sdd kaizen` says so out loud, citing
[ADR 0003](adr/0003-judge-axis-evidence-from-target-repos.md); the floor does **not** loosen in
answer to it. One version with one session is not degenerate: that axis has only just started.

**The agent gives the verdict.** The `sdd-kaizen` session runs the series as its source of truth
(citing, never recalculating), interprets the sha axis with `git log`, and writes
`docs/handoffs/<YYYYMMDD>-<slug>/05-verdict.md` with frontmatter `verdict:`
(`melhorou` | `piorou` | `indeterminado`), `kit_sha_judged:` and `date:`. When
`guard.sufficient` is false the verdict **is** `indeterminado` — the guard belongs to the runner.
Unless the verdict is `piorou`, the same session triages `TODO.md` and writes the born plan
beside the verdict: `00-missao.md` with `aprovacao:` **empty** (the loop never approves its own
plans), `01-plano.md`, `checkpoint.md`.

**The gate** (`gate_KAIZEN`, not part of the mission `PHASES`) re-evaluates from outside, like
every gate: it finds the verdict by `kit_sha_judged` content — never by newest file — and
requires the born plan with the empty `aprovacao:` beside it.

**The Jidoka:** `verdict: piorou` dispenses the plan and `sdd kaizen` exits 3 — the line stops
and the human decides (ADR 0002). Same convention as a `blocked` increment.

**The reminder:** when a target repo's pipeline completes, `sdd run` prints one dim line if the
current kit version has missions without a verdict yet — pull, not push: the human is the
kanban, and the line disappears once the verdict exists.
