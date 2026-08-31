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
**and** `sprint:` in the frontmatter — and, when it also carries `branch:`, `00-missao.md` declares
the **same** branch.

Requiring `sprint:` is deliberate: a card created in the backlog is invisible work for the team.
The `ticket` skill creates it straight into the active sprint and confirms it left the backlog.

The `branch:` check exists because the runner honours `branch:` from `00-missao.md` and from
nowhere else. The session writes the name back and commits both files; a `10-ticket.md` that
declares a branch nobody copied over means every later phase runs on whatever branch the human is
standing on. `branch:` absent from `10-ticket.md` passes — that is every mission planned before the
field existed.

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

⚠️ The fingerprint answers *did this session write anything*, which is enough to decide the retry
and **not** enough to grade the phase: a session that wrote and closed nothing looks exactly like
one that closed an increment. Since `20260829-o-incremento-que-andou` the ledger carries the
sharper fact — `pending_before`, photographed by `cmd_run`/`cmd_retry` before the session, and
`pending_after`, published by `gate_EXEC` after its validation — so a session that made the
increment move reads `advanced` even though its gate refused, which is what this paragraph says
the normal case is. Until then the judge read the pipeline's designed loop as waste: 46 of the 72
EXEC sessions in the real ledger. Field contract in [the autonomy ledger](#the-autonomy-ledger).

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
    `30-handoff-qa.md` itself is filled in. Here the `qa-report`/`qa-execution` skills did not run
    as part of the phase, so demanding their dated report would require an artifact nobody
    produces, and the gate would be unsatisfiable precisely in the case where QA did the work and
    **found** something.
    ⚠️ **That is about what the gate DEMANDS, never about what may exist on disk.** A human can run
    `/qa-report` by hand and commit a `docs/qa/` tree in a project with no interface too. One did,
    on 2026-08-19, and an `sdd-qa` session read the older wording as licence and deleted it
    (`9f84cbc`). A tree that is there is read and complemented, never removed: this path still asks
    for no report from it, and Anchor 3 below (`bugs/` with no agent-closable `Status: open`)
    already applies to both paths;
- no file in `<QA_DOCS_PATH>/bugs/` has a `**Status:** open` **that an agent could close** (true in
  both cases). Since `20260826-o-laco-da-qa` the anchor reads a second field of the same file,
  `- **Closable by:**`: `agent` blocks, `human` does not, and **absent blocks**. Absent is the
  fail-safe and not an oversight — every bug file written before the field existed lacks it, so a
  permissive default would switch this anchor off for a whole legacy registry in one step. The
  genre is read from the FIELD, not from wherever the words happen to appear in the body, and
  matched as a whole lowercase word: `humano`, `humans` and `Human` all read as absent, and block;
- `TEST_CMD` exits 0 and `E2E_CMD` exits 0 (when set).

`wont-fix` and `invalid` do **not** block: they are a recorded human decision, not a pending
defect. Neither does an `open` bug marked `Closable by: human`, and that is the only way an `open`
bug passes. The reason is one level up: no agent in this pipeline may write the `Status:` line —
the `docs/qa/` tree belongs to the `qa-report`/`qa-execution` skills — so a bug waiting on a
product decision had no path out of `open` at all while this anchor blocked the phase for it
anyway, and every honest finding bought another lap. Measured in `20260825-frete-cif-fob`: 7 of the
12 QA sessions in that loop, US$ 73,32 of the mission's US$ 144,88. Marking the genre is the
`sdd-qa` agent's duty and the one line of a bug file that is its (`agents/sdd-qa.md` § 5.1);
`Status:` stays the skills'.

`qa: skipped` is a legitimate and expected answer: a diff with no user-visible change (refactor,
types, build, docs) has no journey to walk. Inventing a journey just to "have QA" is waste.

### REVIEW — Grade A on every criterion

**Passes when:** the most recent `40-review-r<N>.md` carries the `### Overall Grade` section with
**A on every row**; `TEST_CMD` exits 0; and the working tree is clean.

A criterion graded `—` (not analysed) fails too: a partial review is not a review.

The gate reads the `Rationale` column as well, and a placeholder there fails the round: an empty
cell, the whole cell between angle brackets (the shape `templates/review.md` ships), a cell that is
nothing but punctuation (`-`, `?`, `...`, `…`), or one of the fill-in words `PREENCHER` / `TODO` /
`TBD` / `FIXME` / `XXX` / `WIP` / `FILL ME`. For two missions it read the `Grade` column and nothing
else, so `A` on every row with `PREENCHER` on every justification bought a green gate —
`docs/handoffs/20260818-lote-facil/40-review-r1.md:8` records exactly that in its own `gate:` field.

The fill-in words are matched as **words**, not as spellings: `TODO:`, `TBD.` and `FILL ME` are the
same claim as the bare ones, and comparing whole cells by equality let a single keystroke buy the
`A`. Punctuation is never the offence on its own — a real sentence that ends in a full stop is a
real sentence. The skill's terse rationales `clean`, `n/a` and `—` are not placeholders either.

The same rule covers the `gate:` frontmatter field — the other half of the seal — when the key is
**present**, whatever its value: written and left blank fails exactly like `<…>` does, and absent is
left alone (6 of the 14 rounds on disk here predate the field, and refusing them would rewrite
history instead of measuring this round). Present-and-blank was itself a hole for two commits,
because the reader that fetches the value cannot tell it from a key that was never written.

The round report starts from [`templates/review.md`](../templates/review.md). Until
`20260818-lote-facil` this was the one artifact in the kit with a gate and no template, and two
independent rounds derived the heading as `## Overall Grade` and collected `NO-TABLE` — the gate
reads the literal `^###[[:space:]]+Overall Grade`. `tests/check-templates.sh` derives its
assertions from that same regex rather than restating it.

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

**In a repo that owns a mutation catalogue there is a third requirement, and it is checked last:**
a stamp in `.sdd/logs/mutation-stamp` matching the current content of `bin/ tests/ templates/
config/`. `sdd health` writes it when the catalogue comes back green; nothing else writes it; a red
catalogue, or a tree that moved while it ran, **removes** it. The refusal names its own remedy —
`no green mutation catalogue for this content — run 'sdd health'` — because a gate that stops the
line without naming the command sends the operator to run the fast suite, watch it go green, and
conclude the runner is lying.

The requirement is scoped by **artifact** (`tests/check-mutation.sh` exists under this root?) and
never by the identity of the repository, so a target repo is untouched: same gate, same two
requirements it always had. It is checked last so the likeliest message stays the one it already
was. And the gate never *runs* the catalogue — holding the working tree for twenty minutes inside a
gate is what made the REVIEW phase unsatisfiable headless, which is why the catalogue is opt-in in
the first place. It asks for the receipt instead. Why a stamp rather than CI, and what was
discarded, is [ADR 0004](adr/0004-mutation-catalogue-owner-stamp-not-ci.md).

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

One thing it deliberately does not do: **it never runs in `--dry-run`** — a checkout is a mutation
of state, and that is the half the projection promises not to touch (below).

**How the branch created by TICKET gets here.** With `JIRA_ENABLED=true` the `ticket` skill creates
the branch, and the name used to land in `10-ticket.md` alone — nothing copied it into the field
this function reads, so `branch:` stayed at the placeholder and the guard was a no-op on the exact
path it was written for. The TICKET **session** now writes it back into `00-missao.md` and commits
both files; `gate_TICKET` takes the half a gate can take, refusing a `10-ticket.md` whose `branch:`
is filled in while `00-missao.md` still carries the placeholder or declares another name. The write
is the session's and never the gate's: a gate that wrote would corrupt `moved`/`moved2`, the
fingerprints that tell "the session moved the disk" from "the session did nothing".

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
| `acli` not on `PATH` (or `SDD_ACLI_BIN` pointing at nothing) | error, **before** any session: the command will not report a close it could not see |
| `acli` answering anything but a JSON array — expired auth, an unknown spelling | error, **before** any session, and it prints the query to run by hand |
| the issue is already `Done` | reports it and exits 0, spending **no** session |

The verdict is the **artifact and never the session's exit code**, in both directions. That rc is
shared between two branches — the session that closed the issue exits 0, and so does the session
that only *asked* whether to close it — so `sdd close` goes back to JIRA and looks, exactly as
`gate_PR` re-reads the live PR. A session that fell over after closing the issue closed it; a
session that exited 0 without closing anything did not. When the tool stops answering *between* the
two questions, the answer is `UNVERIFIED` and not "still open": both fall closed, but they send a
human to different logs.

`sdd close` is the only invocation of `claude` outside `run_phase()` besides the `sdd preflight`
probe — neither of them runs a phase. It carries the kit guard anyway, for the reason below.

## The kit guard

The kit is not the target repo, and a session running a mission for some other repo has no business
editing it. Measured on 2026-08-25: an EXEC session whose mission was another repo entirely
committed a kit finding straight into the kit's `main`, leaving its test suite red and outside any
review — and the autonomy rows of that very run then stamped the sha of the commit the run had just
made, recording a kit version that existed only because the run created it.

Around every session that can commit — the two in `sdd run`'s loop, `sdd retry`, and `sdd close` —
the runner samples the kit's `HEAD` plus its working-tree state before and after. A difference gets
one `warn` and one `KIT-TOUCHED` line in `.sdd/logs/<mission>/pipeline.log`, naming both stamps.

It **warns and records; it does not stop the line**, and the cost is named on both sides: a human
editing the kit in another terminal while a mission runs is a real false positive, and a guard that
halts a paid pipeline on one is a guard the next author switches off. Two things it deliberately
does not do: it stays quiet when the mission's own repo *is* the kit (a kit mission edits the kit
for a living, and a warning on every phase of it teaches its only reader to scroll past), and it
arms nothing during `--dry-run`, because a projection opens no session for a change to be
attributed to.

Where the finding itself should go — the handoff, never a commit into the kit — is in
[`../CLAUDE.md`](../CLAUDE.md) and in the executor's own instructions.

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

### Context is not the bottleneck — measured, not assumed

One session per phase is also what keeps the context window off the critical path, and until the
SQ-97 pilot that was an article of faith rather than a number. Measured across its 6 sessions, on
`claude-opus-5`: peaks of **184k to 289k tokens**, and **zero compactions**.

The structure is what buys it. Because the phases are separate sessions, the heaviest one carries
289k instead of the ~1.4M a single session would have accumulated by the end. Nothing is trimming
anything — there is simply never enough context in one session to need trimming.

So `--autocompact` is a lever that exists and is **deliberately not used**: the runner never passes
it. If some future phase does start crowding its window, that is the knob to reach for, and the
numbers above are the baseline it has to be compared against. Reach for it on a measurement, never
on a hunch — the whole point of writing this down is that the next person does not have to guess.

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
- a row with **no `repo` key** belongs to no project, so it leaves through a bucket of its own —
  `excluded.no_repo` in the series, one `N row(s) excluded: no repo field` line in the human table,
  and a fourth "no data" silence when the whole ledger is like that. Never `other_repo`: "born
  nowhere" and "born elsewhere" are different accusations. ⚠️ It used to be counted as local in
  **every** repo, on the claim that the readers named it anyway — false for a well-formed session
  row, because `is_unrecognized` asks `.event` and never `.repo`, so three of them cleared the
  judge's floor of 3 in silence. A row that is not an object at all is still admitted here and
  still dies loudly naming the file: hiding corruption is the one thing a filter must not do;
- read from **outside any git repository**, nothing in the ledger is yours: `sdd autonomy` refuses
  with rc 1 saying the rows exist under another repo, and `sdd kaizen --series` warns and returns
  the empty series. That is the safe direction — an empty series is `guard.sufficient: false` and
  supports only `indeterminado`, never somebody else's numbers read as a verdict about this kit.

**A worktree is not another repo.** Writer and readers resolve identity through the same
`ledger_repo_root`, and it derives from the **shared** `.git` (`git rev-parse --git-common-dir`,
normalized) — never `--show-toplevel`, which answers per worktree. Without that, a mission run
from `git worktree add` stamped a path no other checkout of the same repo had seen, and every
reader outside that worktree filed the rows under `other_repo`: the series went empty in the very
isolation workflow this kit recommends, and went empty quietly. ⚠️ Rows written **before** the
fix keep the old per-worktree path and keep landing in `other_repo`. That is history, not a bug —
the ledger is append-only and is never migrated.

**A checkout under the temp directory may not write the real ledger.**
[ADR 0005](adr/0005-judge-reads-every-repo-with-visible-composition.md), part 3. `autonomy_append`
refuses — `die`, rc 1 — when `SDD_STATE_DIR` is unset and the row's repo identity sits under
`$TMPDIR` or `/tmp`. Five of the seven repositories in the real ledger are fixtures and every one
of them sits under `/tmp`; all five came from **manual** exploratory runs that forgot the variable,
never from the suite, which has exported it from `tests/run-all.sh` since the beginning. The
mechanism existed and worked, so what leaked, leaked through discipline — and this repo closes that
kind of gap with an instrument rather than a reminder. Whoever hits the refusal is one environment
variable away from what they meant.

⚠️ Three limits, declared in the guard's own header rather than discovered later:

- it is a **path heuristic**. It knows `$TMPDIR` and `/tmp`. macOS hands out `/var/folders/…`,
  `/var/tmp` is a temp directory it does not know, and a fixture built anywhere else walks straight
  past it. It is a ratchet against the leak that actually happened, never a boundary — what covers
  the miss is the **composition** below, which makes a contaminating repo visible in the very
  series the judge reads. The two ship together and neither is sufficient alone;
- it refuses at the **first row**, which in a `sdd run` is written after the first session, so a
  mission that hits it has already paid for one (an escalation, which spends no session, is
  refused for free). Refusing earlier would mean a guard at every door that opens a session — the
  shape that guarantees the fifth door is born unguarded;
- a **worktree** under `/tmp` of a real repository keeps writing, on purpose: the identity is the
  shared `.git` of the repository and not the checkout the session runs in, so the isolation
  workflow this kit recommends is untouched.

**The judge reads every repo; the human's table still reads one.** Two commands, two questions,
one file. `sdd autonomy` asks *"what did THIS project cost"*, so per repo is its right default and
`--all-repos` is the door back to the cross-project question — this ledger is one file per machine
precisely so maturity can be compared BETWEEN projects. `sdd kaizen` asks the other question, and
[ADR 0005](adr/0005-judge-reads-every-repo-with-visible-composition.md) part 1 points it at the
whole ledger by default. `--all-repos` is still accepted there and is a **no-op**: scripts and
handoffs already carry it, and a flag that silently changed meaning would be worse than one that
stopped deciding in one of its two homes.

⚠️ [ADR 0003](adr/0003-judge-axis-evidence-from-target-repos.md) said verdict evidence comes from
real target repos — the kit's own axis degenerates by construction — and it stayed a **dead letter
for nine days** because it never said how the judge READS those rows: the per-repo default kept it
looking at exactly the one repo 0003 declared unusable, and excluded the evidence as `other_repo`.
Measured on `20260825-frete-cif-fob`, the first real target-repo mission on a frozen kit: 21
comparable rows, US$ 144.88, and the default reading saw **none of them**.

What makes the widening safe is not a filter. It is the **composition** published beside the
numbers (above), which turns contamination into something you SEE, plus the writer guard that stops
a checkout under `$TMPDIR` from entering the file at all. The two shipped together and neither is
sufficient alone.

⚠️ The **post-pipeline reminder** still reads per repo, and that is the right unit for it: it is
called from `sdd run` alone, `sdd run` has no `--all-repos` (it dies on any unknown `-*` option),
and the question it answers is what the run that just finished contributed. What changed with
ADR 0005 is its **sentence**: it used to tell the human that the judge would not count these rows,
which was true then and is false now, and it now points at `sdd kaizen` in the kit repo instead.

The **KAIZEN boot prompt** no longer carries a ledger option, and the reason is worth keeping.
`gate_KAIZEN` reads its half of the series by calling `kaizen_series` in-process, so every option
the invocation carried landed on it; the prompt hands the agent a *written* command line, so an
option landed there only if the runner wrote it. With one half flagged and the other not, the two
landed on different `latest` shas — and because the gate hunts for exactly the `kit_sha_judged:`
the prompt ordered the agent to write, the phase stopped being *wrong* and became **unsatisfiable**:
gate fails, runner retries once, second session writes the same sha, run ends in `BLOCKED in
KAIZEN — no-progress`. Two opus sessions for a blocked row. ADR 0001 splits the judge; what keeps
the split honest is both halves reading ONE series — and since ADR 0005 there is only one to read,
so the invariant holds by construction instead of by upkeep.

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
| `kind` | string enum: `increment-blocked` \| `dirty-tree` \| `handoff-blocked` \| `app-down` \| `budget-exhausted` \| `no-progress` \| `review-to-draft` | on `event:"session"` rows | Which escalation path fired. `increment-blocked`, `dirty-tree` and `handoff-blocked` are deliberate Jidoka (they can be a *good* sign); `budget-exhausted` and `no-progress` are pure friction. `dirty-tree` is the oldest of the three and was **missing from this row** until `20260828-o-gate-sabe-que-o-app-caiu` went looking — the row that warns a kind can be added to the code and not to the table is the row that had one, which is exactly the open tail it describes. It fires from `cmd_run`'s EXEC pre-check and always names EXEC: a phase that died mid-way leaves the tree uncommitted, the suite then runs against changes nobody approved and comes back red, every increment still reads `done`, so EXEC is re-derived and another session opens against the same wall — about US$ 25 a lap, with no end condition, and no session may commit or discard on a human's behalf. `handoff-blocked` arrived with `20260826-o-laco-da-qa`: the phase's own handoff declares `status: blocked`, which already meant "the line stopped and a human has to act", so the runner escalates on that declaration instead of charging the phase a second session to prove the same thing. It is written from both doors of `cmd_run`'s loop — the first pass and the inline retry — and names the phase whose handoff declared it. `app-down` is its environment-facing sibling: the e2e came back red **and** a TCP connect to `APP_URL` was refused, so the line stops with the address named instead of charging QA a second opus session against a machine no session in this pipeline is allowed to start (bringing the environment up is the operator's job — see `config/schema.md`). Same two doors, same deliberate-Jidoka reading. What it never does is fire on doubt: an empty `APP_URL`, a URL the runner cannot parse, a bash built without `/dev/tcp`, an absent `timeout(1)` and an error string it does not recognise all read as *unknown*, and *unknown* escalates nothing — the probe may turn a red into a **named** red, never a green into a red. ⚠️ This column is a **documented enum with an open tail**: the runtime readers do not validate it (`is_escalation` is defined over `.event` alone and both aggregations `group_by(.kind)` dynamically), so a new kind is admitted, counted and printed rather than filed as `unrecognized` — which means a kind added to the code and not to this row goes unnoticed by every sensor. Adding one is a contract change: code and this table in the same commit. `review-to-draft` is the only `degraded` kind today: `PUBLISH_ON_REVIEW_BLOCKED=draft` and the review out of rounds, so the runner publishes a draft PR by itself instead of stopping. **At most one `review-to-draft` row per `run_id`**, and now at most one *jump*: the draft PR gets a single chance, and if its own gate fails the run ends on `blocked` / `budget-exhausted` in REVIEW rather than looping REVIEW→PR→REVIEW with the budget still blown. Before that, the branch was re-entered every lap and wrote a row every lap — both readers agreeing on a wrong number, which is worse than one of them being wrong. |
| `run_id` | string (uuid) | never | One per `cmd_run`/`cmd_retry` invocation. Groups every row a single command call produced — "this mission needed N runs" is a `run_id` count. |
| `invocation` | string enum: `run` \| `retry` | never | Which command opened the session: `sdd run` or `sdd retry`. Answers "who opened the session", not "was this an in-loop retry" — that is `auto_retry`. |
| `kit_sha` | string \| `null` | never absent, but `null` | `null` when `$SDD_HOME` is not a git checkout. Short SHA of the kit's own HEAD when the row was written — the before/after axis the whole ledger exists for. |
| `kit_dirty` | boolean \| `null` | never absent, but `null` | `null` exactly when `kit_sha` is `null` (paired). `true` means the kit's own working tree had uncommitted changes — the row is real but not comparable across versions. |
| `project` | string | never | `PROJECT_NAME` from the target repo's `.sdd/config.sh`. |
| `repo` | string | never | Absolute path of the target repo — the directory holding the **shared** `.git`, as `ledger_repo_root` in `bin/sdd` resolves it (`git rev-parse --git-common-dir`, normalized). Can carry client-identifying paths, which is why the ledger stays in `$HOME` and is never committed. It is also the **only** field the readers filter on before anything else: see "The file is global; the READING is per repo" above. Compared verbatim, with no normalization at read time on either side, so a repo reached through a symlink is a different repo. |
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
| `moved` | boolean | on escalation rows | ⚠️ The whole waste metric: `state_fingerprint` before ≠ after, and `state_fingerprint` is git HEAD + the mission directory listing + the checkpoint file's md5. `moved` alone no longer names a bucket: since `20260828-instrumento-honesto` both readers classify a comparable session as `advanced` (the gate passed — the gate is the artifact), `churned` (`moved:true` and the gate failed: the session wrote and the runner bought another lap) or `idle` (`moved:false` and the gate failed — the old `stalled`, under the name that says what it is). ⚠️ Since `20260829-o-incremento-que-andou` a session also reads `advanced` when `pending_after < pending_before` — **the increment moved**, which is the whole point of an EXEC session and something the gate cannot say, because `gate_EXEC` refuses by construction until the last increment. Both operands must be non-`null` for that arm to fire: `jq` sorts `null` below every number, so `null < 2` is true, and without the guard the session whose gate REFUSED the checkpoint (which publishes no `pending_after`) would have read as the highest progress in the ledger — a fail-open in the flattering direction. Declared limit, same place: the session that closes the last increment over a red suite reads `advanced` by the count while the lap it buys reads `churned` — the gate is the artifact of the NEXT lap. ⚠️ Since `20260831-a-rodada-que-andou` a **third** arm says the same about `REVIEW`, which is a loop by design too: a session reads `advanced` when `rounds_after > rounds_before` — **the round landed** — so an r1 that arrived with real findings and did not reach Grade A stops reading as churn. A separate arm and not a generalisation of the second, because the two counts move in **opposite directions**: `EXEC` counts what is still to do and goes down, `REVIEW` counts what has landed and goes up, and a single "the number changed" arm would call a checkpoint that *grew* (the fix increments QA writes) progress. It carries **one** non-`null` guard against EXEC's two, and the asymmetry is the operand order rather than an oversight: the possibly-`null` field sits on the LEFT of `>`, where `null > 2` is false, so `rounds_before != null` alone closes the hole — a redundant guard is removed here rather than probed. `waste = churned + idle`. ONE definition, `ledger_outcome_defs` in `bin/sdd`, spliced into `cmd_autonomy` and `kaizen_series`; `tests/check-autonomy.sh` and `tests/check-kaizen.sh` compare the two histograms over one file. |
| `pending_before` | integer \| `null` | on escalation rows; never absent on a session row, but `null` outside `EXEC` | How many increments the checkpoint still listed as `pending` or `doing` when the session opened — a PHOTOGRAPH, taken by `cmd_run`/`cmd_retry` before `run_phase`, because once the session has edited the checkpoint the question is unanswerable. `null` outside EXEC: no other phase has an increment to advance, and a `0` would enter the judge's arithmetic as a session that stood still. ⚠️ It is also `null` on every EXEC row written before `20260829-o-incremento-que-andou` added the three fields, and those rows are **not** left reading as churn: `historic_progress` in `ledger_outcome_defs` recovers the same fact from the prose `gate_why` already carried (`^N of M increment`), annotating `pending_after = N`, `increments_total = M`, `pending_before` = the previous EXEC row's `N` for the same `(repo, mission)` in FILE order, and `progress_source: "gate_why"`. Three rules earn their own mutants because each fails in a different direction: the first row of a mission (and any row where `M` changed, which is QA writing a fix increment, not churn) compares against `M`; a preceding `gate: pass` clears the memory; and the guard is `.pending_before == null` and never `has("pending_before")` — `autonomy_session_row` builds the object with `tonumber? // null`, so the KEY is present on every row and `has()` would annotate nothing. A dated read path, never a migration: the ledger is append-only, no line is ever rewritten. `sdd autonomy` prints how many rows it read that way (`(N EXEC row(s) older than the pending fields read their progress from gate_why)`) and the path is deletable the day that number reaches zero. |
| `pending_after` | integer \| `null` | on escalation rows; never absent on a session row, but `null` outside `EXEC` | The same count as the gate saw it, from `GATE_EXEC_PENDING` — a VERDICT, not a photograph. `gate_EXEC` publishes it only *after* its validation loop **and after the Jidoka refusal**, so a gate that is about to refuse leaves the pair `null` and the reader falls back to `moved`. Two refusals, not one, and each cost its own bug: (a) a checkpoint refused for a label with no artifact (`done` with no commit, a commit outside the history of HEAD); (b) a checkpoint carrying a `blocked` increment. ⚠️ (b) was published until 2026-08-30 and was a fail-open in the flattering direction — `checkpoint_tally` counts `pending|doing` and files `blocked` in a bucket of its own, so **giving up** on an increment lowers `pending` exactly as **finishing** it does, and the one session in the pipeline that *stopped the line* read `advanced` at `0% waste`. A real EXEC row of `20260825-cif-forma-pagamento` is that session; it reads honestly today only because it predates these fields. Blocking is not closing. Both orderings are assertions in `tests/check-autonomy.sh` (`a done without commit publishes no pending_after`, `a blocked increment publishes no pending_after`) with a mutant each. |
| `increments_total` | integer \| `null` | on escalation rows; never absent on a session row, but `null` outside `EXEC` | Every row of the checkpoint table, `GATE_EXEC_TOTAL`. It grows when QA writes a fix increment, which is why the pair above is read as a difference within one row and never as a running total across rows. |
| `rounds_before` | integer \| `null` | on escalation rows; never absent on a session row, but `null` outside `REVIEW` | How many `40-review-r<N>.md` files were on disk when the session opened, from `review_rounds_on_disk()` — a PHOTOGRAPH, taken by `cmd_run`/`cmd_retry` before `run_phase`, for the same reason as `pending_before`: once the reviewer has written the round, the question is unanswerable. ⚠️ Taken **outside** the `[ -z "$force_phase" ]` guard the round ceiling sits behind. `sdd run --phase REVIEW` is how a human asks for the one round that unblocks a mission, and a photograph taken inside that guard would write `null` on exactly those. ⚠️ It is also `null` on every REVIEW row written before `20260831-a-rodada-que-andou` added the three fields — 25 of 25 rows of the real ledger on the day it landed — and those are **not** left reading as churn: `historic_rounds` in `ledger_outcome_defs` recovers the same fact from the `gate_why` the row already carries, because `gate_REVIEW` has always written the round file's own name into it. Two spellings, both anchored: `^40-review-r<N>.md` gives `N`, and the fixed string `no 40-review-r<N>.md` gives **0** — the session landed no round file, which is a measurement and the reason the ledger's most expensive churned cell stays churned. `rounds_before` is the previous REVIEW row's recovered count for the same `(repo, mission)` in FILE order, seeded at 0, and the annotation carries `rounds_source: "gate_why"` so the reading is never mistaken for a measurement. ⚠️ It inherits **neither** of `historic_progress`'s two memory rules, and the second refusal is the load-bearing one: a passing gate does **not** clear the count, because `review_rounds_on_disk()` counts FILES and files are never deleted, so the count carries across a pass — copying EXEC's reset would read `1 > 0` as progress over a reopened phase whose session landed nothing. The guard is `.rounds_before == null` **and** `.rounds_after == null`: a row carrying only the second is not pre-schema, it is a row this runner wrote whose photograph went missing, and repairing it from prose would launder the very defect the non-`null` guard in `outcome` exists to catch. Declared limits: `rounds_max` is not recovered (it is config, absent from the prose), and the two refusals that name no file (`TEST_CMD failed`, `working tree dirty after the review`) are left where they were rather than guessed at — 1 row of 25. `sdd autonomy` prints how many rows it read that way (`(N REVIEW row(s) older than the round fields read their round from gate_why)`), counted over the **comparable** rows the table above it is made of, and the path is deletable the day that number reaches zero. |
| `rounds_after` | integer \| `null` | on escalation rows; never absent on a session row, but `null` outside `REVIEW` | The rounds on disk once the phase has run, from `GATE_REVIEW_ROUNDS`. ⚠️ Published by `gate_REVIEW` as soon as the round file is **resolved**, not after the gate approves — deliberately asymmetric with `pending_after`, which waits for validation. EXEC's count is a verdict because the checkpoint is a label the executor writes about itself (`done` with no commit); the `N` of `40-review-r<N>.md` is **structural** — it is the file name, read by the same `latest_matching` the gate itself uses, and nobody self-declares it. Publishing at the resolve is exactly what lets an r1 that landed with real findings and did **not** reach Grade A count as a round that advanced, which is why these fields exist. No round file at all publishes `0`, not `null`: zero rounds on disk is a measurement. |
| `rounds_max` | integer \| `null` | on escalation rows; never absent on a session row, but `null` outside `REVIEW` | `REVIEW_MAX_ITER`, the ceiling the rounds run against. A third field and not decoration: without it, "3 of 3, the phase is out of budget" cannot be told from "3 of 10" — the reading `increments_total` exists to close for EXEC. |
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

**`sdd autonomy --by-mission` regroups the same rows by mission** — the unit of "US$ per merged PR",
which is what a pilot has to report and what the kit_sha axis cannot answer. Same population, same
money: the two views sum to the same total, and a fixture in `tests/check-autonomy.sh` compares
them to each other so neither can be changed alone.

Its extra cells are **`launch(es)`** and **`reopened`**, and they are the half cost alone cannot
show: a cheap mission and a mission that ran cheap because a human relaunched it three times print
the same number of dollars. `launch(es)` is the count of distinct `run_id` in the mission — every
`sdd run` or `sdd retry` a human typed. It is the number the D12 metric reads (D16, amended
2026-08-28): the fact, never `launches − 1` — "interventions = launches − 1" is the reading, and a
subtraction inside the instrument would print `0` on a mission abandoned after its first launch. It
**undercounts** by design: bringing the app up by hand between two launches is one new `run_id`,
not two. `reopened` counts sessions in a phase **below** one whose gate had already **passed**, in
the canonical phase order — the pipeline going backwards after it had gone forward. Not "the phase
index went down": that would count the designed loop (QA fails, opens a fix increment, EXEC runs
it), which `20260825-frete-cif-fob` did three times with QA refused, all of it the pipeline working
(reads 0); SQ-111 ran QA after PR had passed and reads 1. A phase outside the order (`KAIZEN`)
counts on neither side.

Both are drawn over **every** local session of the mission, comparable or not — a launch that
landed on a dirty kit was a launch — while `session(s)`, the outcomes and `US$` stay on the
comparable sessions, because that is the sum the sensor closes against the version table. When the
two populations differ for a printed mission, the accounting paragraph says so once:
*(launches and reopened are counted over every session of the mission, N of them non-comparable)*.
A mission whose sessions are all non-comparable does not appear — as before.

The `- intervention:` notes of `checkpoint.md` are **narrative**, not the count. They print as
`N intervention note(s)` between `reopened` and `US$` when the mission belongs to this repo and its
checkpoint is on disk, and not at all otherwise — no `?`, no zero: `?` existed so that no false
zero reached the official number, and the official number no longer comes from the file. Measured
before the change: the pilot missions carried 0, 1 and 0 notes; the one with three launches had
none. The marker stays **English and contract**, like `pending`/`done`/`blocked`; the text after
the colon follows `OUTPUT_LANG`, and the word in the middle of a sentence is prose and is not
counted.

**The accounting paragraph under the table is two paragraphs.** The first lists rows that were in
the header total and then left a bucket — add them to the table and you get the header. The second
is introduced by *"never part of the N counted above"* and lists rows the repo filter removed before
anything was counted (born in another repo; carrying no `repo` field). Printed together they invited
a subtraction that could not close: header 96, table 89 sessions, 7 non-comparable — correct — and
then "11 row(s) excluded: born in another repo" underneath.

## The kaizen loop

The ledger records; `sdd kaizen` closes. Run **in the kit repo** (it refuses anywhere else), it
judges the previous kit change and gives birth to the kit's next mission plan — detection without
closure is inventory, not improvement.

The judge is split in two (ADR 0001):

**The runner derives the numbers.** `sdd kaizen --series` prints a versioned JSON (`v: 1`) about
the repo it runs in — the file is global, the reading is not, see above: `latest` and `previous`
kit versions (by
**file order** of first appearance, never by sort — and a reappearing old sha rejoins its old
group; `sdd autonomy` orders its version table off the **same population**, the rows both the
table and the escalations block admit — comparable sessions and on-axis escalations — the
population the series reads through `comparable_row`, because two readers disagreeing about which
version is newest over one file is a defect and not a view), each with missions, `missions_with_session` (the subset that bought an observation — the
guard below counts these, not the raw mission tally), sessions, `outcomes` (`{advanced, churned, idle}` — what the sessions did, the headline since
2026-08-28; the same three buckets appear in every `detail[]` entry), `advance_rate` (the
`advanced` share of those same sessions — one yardstick read twice, so it can never contradict the
tally beside it; it read "the share whose gate passed" until `20260829-o-incremento-que-andou`,
which is why a nine-session EXEC that advanced nine increments used to print `0.10`),
`moved_rate` (the share that wrote to the disk — kept, its name says what it
measures), cost, escalations
by kind, a per repo×mission×phase `detail` (each entry naming its `repo`), and a label per group:

- `refez` — an escalation, a human `sdd retry`, or the phase's last session still failing its
  gate: the work was pushed again.
- `leve` — an in-loop auto retry, **or any session of the phase whose `outcome` is not
  `advanced`** (`churned`: it wrote, the gate refused, and the increment did not move, so the
  runner bought a lap that produced nothing; `idle`: it did not even write): friction, absorbed.
  Three labels, not four — the magnitude lives in `outcomes`.
  ⚠️ The clause read **`.gate == "fail"`** until `20260829-o-incremento-que-andou`, and that is
  a different claim: `gate_EXEC` refuses by design until the LAST increment, so every EXEC of two
  or more increments was stamped `leve` for doing exactly what the pipeline asks. `frete-cif-fob`
  EXEC — seven sessions, five refusals — is the worked example: it read `ok` until 2026-08-28,
  `leve` from the churn clause, and reads `ok` again today, now because all seven sessions
  advanced an increment. The two `ok`s are not the same answer; only the second one was measured.
  ⚠️ `20260831-a-rodada-que-andou` carried the same reading one phase on, to `REVIEW`. The worked
  example is the most expensive cell of measurement window 2 (`kit_sha bf001fe`): the REVIEW of
  `20260830-a-tela-que-mente-o-pagamento`, US$ 47.81, `1 advanced · 1 churned`, stamped `leve` for
  running the two rounds `REVIEW_MAX_ITER` exists to allow — in the phase that consumes 41% of the
  slice's spend. It reads `ok` today because both of its rounds landed.
  ⚠️ The `.auto_retry == true` arm looks subsumed by the outcome arm and is **not**: in the repo
  that builds the kit every session commits, so a failed first pass and its inline retry land on
  different `kit_sha` and are graded in different groups — a surviving retry alone in its group
  reads `advanced`, and without the arm its phase would read `ok`.
- `ok` — none of the above.

Each of `latest` and `previous` also carries a **`composition`**
([ADR 0005](adr/0005-judge-reads-every-repo-with-visible-composition.md), part 2): an array of
`{repo, missions, missions_with_session}`, one entry per repository that contributed to that
slice, sorted by `missions` descending and then by `repo`. It is what makes reading every repo
safe — a verdict resting on rows from a throwaway clone is a verdict about nothing, and under a
silent filter nobody could tell, so the mixture is published beside the numbers instead of guessed
at. `sdd kaizen` prints it to the human too, because a field nobody opens is available and not
seen.

⚠️ It is derived over the rows the guard **admits** — sessions *and* escalations — and never over
`event: session`. Three of the seven repositories in the real ledger contribute escalations only,
so a session-counted composition under-reports exactly the repos it exists to expose: the first
draft of ADR 0005 counted sessions, answered "four repos" over seven, and says so about itself.
Both numbers are published because the guard reads two, and each sum closes against its own field
— `sum(missions) == guard.missions_after_change`, `sum(missions_with_session) ==
guard.missions_with_session` — which is what makes the composition an explanation of the guard
rather than a second set of numbers standing beside it.

Plus a `guard` (`missions_after_change`, `missions_with_session`, `sessions`,
`floor` — the number of missions with a session a version needs, published because the runner also
says it out loud to the human and a second copy of it would drift the day it moves;
`sufficient: missions_with_session >= floor` — a mission that only escalated ran, and is counted as
one, but bought the judge no observation and so does not raise the floor;
`degenerate_axis`, true when the **last `floor`** kit versions in the slice — the same number, read
from the same owner, never a second copy of it — each bought exactly one
*mission* — the same unit the floor counts, never sessions — there is more than one of them, **and
no version anywhere in the history ever reached the floor** — that third clause is what separates
"this axis cannot work here" from a merely quiet stretch in a healthy repo) and an `excluded`
accounting with five reasons
(`non_comparable` dirty-kit rows, `unrecognized` rows, the `meta` rows the kaizen sessions
themselves write — the loop never lets its own sessions shift the axis it is judged on —
`other_repo`, the rows born somewhere else, and `no_repo`, the rows that name no project at all —
the field absent, `null`, or empty are one and the same answer).

**A mission is a mission of a repo, not a slug.** Every count above keys off `(repo, mission)`.
Under one repo that is a no-op; under `--all-repos` it is what keeps two projects that ran the same
dated slug on the same `kit_sha` from collapsing into one group — mission slugs are dated and
`sdd kaizen` itself mints `<today>-kaizen`, identical in every repo on the same day.
The empty-ledger branch prints the same key set with
zeros: a consumer must never read `null` on one branch where the other gives a number.

`degenerate_axis` exists because `sufficient: false` alone says two different things. In a target
repo it means "not enough missions yet", and waiting works. In the repo that **builds** the kit
every session commits, so the next one lands on a fresh `kit_sha`, each version holds exactly one
mission and the floor is unsatisfiable by construction — waiting never works, and `indeterminado`
there is the correct answer rather than a broken runner. `sdd kaizen` says so out loud, citing
[ADR 0003](adr/0003-judge-axis-evidence-from-target-repos.md); the floor does **not** loosen in
answer to it. One version with one mission is not degenerate: that axis has only just started.

⚠️ **The unit is missions, and it has to be**, because `sufficient` counts
`missions_with_session` and this field exists to explain *that* floor. Counting sessions made the
two disagree on the one row shape that separates them — a version whose two sessions belong to the
**same** mission, which is what an in-loop retry or a second `sdd run` over a phase that neither
commits nor dirties the kit tree produces. Measured: three versions, the newest holding two
sessions of one mission ⇒ `missions_with_session: 1`, `sufficient: false`, and yet
`degenerate_axis: false` with the sentence printed zero times. The human then reads a bare
`sufficient: false` and waits for missions that cannot help — the exact misreading this field was
built to end, and a single retry was enough to silence it. Zero is still not one: a version whose
rows are all escalations observed **nothing**, a different silence with a different remedy.

It reads the **last three** versions and not the whole history, for the same reason: the ledger is
append-only, so a single ancient `kit_sha` that once carried two missions would switch the
explanation off forever while every recent version sat at one mission each — and nothing about
today could ever switch it back on. Three is the guard floor, held as one definition in the `jq`
program so the window and the number it explains cannot drift apart.

The window alone was not enough, and the second clause is why. The field claims the axis **cannot
work here**, and a quiet stretch is not a broken axis: a repo whose history reached the floor twice
and then went three versions quiet read `true`, telling its human to stop waiting for missions that
were in fact arriving. So the whole history is consulted for one question only — did any version
ever reach the floor? Having reached it once is a permanent fact about a repository, which is why
latching the explanation off on *that* is right where latching it off on "some sha once carried two
missions" was wrong. In the repo that builds the kit no version ever reaches it, so the explanation
stays on.

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
