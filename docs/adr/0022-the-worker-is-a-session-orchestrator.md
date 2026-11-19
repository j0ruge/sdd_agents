# ADR 0022 — The worker is a session that orchestrates a campaign, under a signed delegation with five levels of autonomy

- **Status**: accepted (—, 2026-11-17)
- **Spec**: docs/handoffs/20261117-o-worker-orquestrador/00-missao.md
- **Amends**: the worker roadmap of 2026-09-22
  (`docs/superpowers/specs/2026-09-22-o-worker-roadmap-design.md`), which is a spec and not an ADR:
  its decisions D1 (the worker never plans), D2 (never the kit's own repository) and D5 (the merge
  stays human) are revised below, and its chosen form A (a `tick --once` fired by a systemd timer)
  is set aside, not refused. 0016 §2 (the kit mission in a linked worktree) gains a second way to
  execute it.

## Context

The roadmap of 2026-09-22 designed the worker as `bin/sdd-worker tick --once`, fired by a systemd
timer, that takes a mission **already approved on disk** to a pull request and stops there. Of its
seven steps only W1 (one checkout, one owner; PR 48) is in the code: on 2026-11-17, at `5221477`,
`bin/` holds `sdd`, `sdd-coordination.py` and `sdd-link-agents`, and `commands/` holds `sdd-plan.md`
alone. The front was parked by the owner until "the current flows run clean".

What ran instead was a session. Three times between 2026-11-15 and 2026-11-17 the owner delegated a
whole chain of missions of another repository to one Claude Code session
(`docs/superpowers/specs/2026-11-16-o-worker-merge-delegado.md`):

- the session planned with the planner on the strongest model and answered the grill with the
  recommended option (8 of 8, 6 of 6, 10 of 10);
- it ran `sdd run` in the mission's worktree (US$ 81.03, US$ 71.82 and US$ 101.88 for three
  missions, 17 to 18 sessions each, no rc 3), opened the pull request, reviewed it until every
  criterion read A, asked the review bot for the head, and merged with `--match-head-commit`;
- from the second night on it also ran `sdd approve`, and it planned the next mission while one ran;
- eight merges were decided by one checklist, read from artifacts, and none had to be undone.

The same record names what that costs when nothing but prose holds it:

- the delegation was a sentence. It is valid "in this session", so a chain that outlived its context
  window needed a new yes from the owner (M26), and the first one was marked "used and spent" by
  hand in an agent memory;
- the judgments that decide a merge were read by the model and went wrong four times: a review
  receipt matched by the clock and not by the sha (M13), a watcher whose `pgrep -f` matched itself
  (M23), a bot out of quota read as "reviewed" (M1), a verifier that read 20 of 21 units (M24);
- a grill with no owner in the room recommended over a wrong number once (M8);
- the orchestrating session spent its context on what a file should hold (M29).

The roadmap forbids three of the things that ran: planning (D1), the kit as a target (D2) and the
merge (D5, "only with an ADR"). And the kit's own backlog, the first campaign the owner wants the
worker for, stands at 83 open findings.

D2 refused the kit for two reasons: a nested `claude -p` dies, and the EXEC phase would edit the
`bin/sdd` that runs it. Both have an answer since then that nobody had put together. `run_phase`
clears the inherited harness environment (`HARNESS_ENV_UNSET`), and since ADR 0016 §2 a kit mission
lives in a linked worktree while the `sdd` on the PATH resolves to the main checkout: the runner is
a `bin/sdd` the mission does not edit. Only `sdd kaizen` refuses that checkout
(`kit_checkout_targets_run`); `sdd run` in a kit worktree has no guard and has never been measured.

## Decision

1. **The worker is a session, and its judgment is a program.** `commands/sdd-worker.md` tells an
   interactive session the loop. `bin/sdd-worker`, a program of its own outside `bin/sdd`, answers
   from artifacts the questions that used to be the model's reading: is the delegation valid, does
   this act fit the level, what is the next step of the campaign, is a ceiling spent, is this pull
   request ready at this sha. The program answers and signs; it never launches a run, opens a pull
   request or merges. Those acts stay with the commands that already exist (`sdd run`, `gh`).

2. **A campaign is a directory in the target repository** holding the queue of lots
   (`campaign.md`), the delegation (`delegation.md`) and a one-line-per-event journal. The verbs take
   that directory as an argument; no configuration key names it. A lot finds its mission through the
   mission's own artifact: `00-missao.md` declares `campaign:` and `lot:`. There is no state file:
   the next step is derived from the queue, the missions and the pull requests. A mission is found
   on disk, in the campaign's checkout and in every linked worktree of its repository, and in the
   base, the tree of the upstream of the branch that checkout has checked out, read through git: a
   merged mission whose worktree was removed is still the campaign's.

3. **The delegation is an artifact with an end.** It carries the level, the lots it covers, the
   instant it expires, a ceiling per mission and a ceiling for the campaign, and it is signed by the
   owner (`sdd-worker delegate`, which shows what is being granted, asks, and leaves with rc 66 and
   writes nothing when it reads no answer, as `sdd approve` does). The signature carries a digest of
   the six other keys and of the ceiling of each lot in the table of the `campaign.md` beside it, so
   a delegation edited after signing, or whose campaign moved a lot's ceiling, is no delegation. The
   worker reads it again before every act.

4. **Five cumulative levels, one definition.** `assisted` < `pr` < `plan` < `merge` < `full`:

   | Level | The worker may, alone |
   |---|---|
   | `assisted` | nothing: it proposes each act and waits for the owner |
   | `pr` | run an approved mission, open the pull request, treat the bots |
   | `plan` | also plan the next mission and leave it measured for the owner |
   | `merge` | also merge by the checklist, and the post-merge pull request |
   | `full` | also `sdd approve` |

   A delegation that is absent, unsigned, expired, illegible, or of a level nobody defined is
   `assisted`, and so is any signed level above `assisted` when `ON_ESCALATION_CMD` is empty in the
   `.sdd/config.sh` of the campaign's checkout or of a linked worktree that holds a mission of the
   campaign, where `sdd run` pages from; the file of a worktree that holds none is never read. The effective level of a lot is the lower of the signed level and the lot's own ceiling. The
   predicate is written positively: an act is allowed because a level names it, never because
   nothing refused it.

5. **The merge is delegated at `merge` and above, by a checklist read at one sha** (amends D5).
   `sdd-worker pr-ready` answers 0 only when all five hold for the head: the newest review round of
   the mission grades every criterion A and names that head (commits after it may touch only the
   mission's handoff directory); the review bot's machine state says `completed` for that sha with
   no unresolved finding; no review thread is open; the pull request is mergeable; and the head the
   caller will pass to `--match-head-commit` is the one that was read. The Codex receipt is one of
   the five, so it is required: a Codex that does not answer is a stop, never a pass. Any other bot
   that did not review (quota, plan, rate limit) is "did not review", declared in the pull request,
   and does not block.
   Three stops: no receipt for the head 60 minutes after an explicit request, a grade below A after
   three rounds, a merge conflict outside the findings file and its ratchet.

6. **Planning and approval are delegated at `plan` and `full`** (amends D1). The planner still runs
   on the strongest model, and the campaign declares the harness and the two models. Under
   delegation the relay answers the grill with the recommended option; an answer that touches the
   owner's rules is listed in the pull request for his acceptance. A lot may carry a ceiling: the
   design lots of the kit's campaign (one item each, since a lot is done when one mission merges)
   are capped at `plan`, so their approval is never delegated.
   `sdd approve` itself does not change.

7. **The kit is a target, through `sdd run` in the mission's worktree** (amends D2, extends
   0016 §2). The `sdd` on the PATH is the main checkout, which the mission does not edit. This is
   reasoning and not yet a measured run: the mission that builds the worker is the first one, and
   the stop rule is written in its spec — a run that dies because of the arrangement goes back to
   the owner. The kit's `gate_PR` asks for the mutation stamp and leaves with rc 2 when only the
   stamp is missing (ADR 0015 §1); for a kit mission the worker reads that as "ready for review",
   by the owner's standing rule that a mission's pull request merges without the stamp.

8. **Two ceilings and a pager.** The ceiling per mission reaches the runner as
   `BUDGET_MISSION_USD`; the ceiling of the campaign is the sum of the ledger over the campaign's
   missions. Either one spent stops the worker. The campaign's is a hard limit (decision 2 of the
   owner on the review r6 of the mission that built the worker): `sdd-worker budget` stops when
   what is left of it is below the signed mission cap, so a campaign may end with up to one mission
   cap unused, and passes its ceiling only by three spends: what the runner spends past its own cap
   in a phase, the spend of a mission `budget` does not find (one that never reached the base and
   whose worktree was removed), and the spend of the orchestrating session and of its subagents,
   which is outside both ceilings (Declared limits, below).

## Alternatives discarded

- **The roadmap as written (a tick fired by a timer, a dedicated clone).** It solves the context
  window by construction and needs no session. Set aside, not refused: none of it has run, W2 to W6
  do not exist, and it keeps the kit out. The session flow has three measured runs.
- **A program with no long session**: a bash loop opening one `claude -p` per step, grill included.
  The largest build, and a headless delegated grill has never run.
- **Prose alone** (the command and two templates). The smallest mission, and it leaves "ready" and
  "the delegation is valid" as the model's reading, which is where the four errors came from.
- **A ninth hat launched as a long-lived subagent.** A subagent cannot reach the owner and does not
  launch subagents reliably; a stop would cross a relay.
- **Delegation by word, as today.** No contract changes, and the worker stops every time the
  context window turns.
- **A permanent configuration key** ("this repository accepts delegated merges"). No scope and no
  end: the permanent permission the field notes warn against.
- **Independent switches per act** instead of a ladder. It describes any combination, including
  ones that mean nothing (approve without planning), and multiplies the probes.
- **A new value for `aprovacao:`** (`delegated-…`) so the plan says who approved. Honest, and it
  moves `gate_PLAN`, the templates and `docs/pipeline.md` in a mission that already builds a
  program. Left to the owner as an open question; the trail is the campaign journal.
- **Verbs that act** (`sdd-worker run`, `sdd-worker merge`). One more place that pushes and merges,
  and a second runner in all but name.

## Consequences

- The kit gains a second program with rules of its own. Its sensor is `tests/check-worker.sh`, and
  its mutants enter the catalogue against `bin/sdd-worker`, the way the coordination helper's do.
- The parser of the review grade table now exists in two programs. `pr-ready` is stricter than
  `gate_REVIEW` on purpose (every criterion A, no tolerance for prose), so the two are not meant to
  agree; a round `gate_REVIEW` passes may fail `pr-ready`, never the reverse on the grade alone.
- `pr-ready` reads a third party's machine comment (`codex-review-state:v1`). The fixture is copied
  from a real pull request, with provenance. The day the bot changes that shape the verb answers
  "no receipt", which stops the worker: fail closed.
- **Declared limits.** The signature proves an answer on stdin, not a person: an agent with a
  shell passes, the same limit `sdd approve` has. The ceilings read the ledger of this machine, and the spend of
  the orchestrating session and of its subagents is outside both. A mission of the campaign that
  never reached the base and whose worktree was removed is found nowhere, and its spend leaves the
  campaign's sum until the ledger carries the campaign (the direction is in `TODO.md`). A campaign's missions are matched
  by id, not by repository. `sdd approve` under `full` still writes `humano-YYYY-MM-DD`. Visual
  acceptance is never the worker's. Deleting a branch or a worktree and pushing to the default
  branch are in no level. The pager and the mission cap are read in the `.sdd/config.sh` of the
  campaign's checkout and of each worktree that holds a mission of the campaign, and of no other
  (the narrow set, the owner's choice): a worktree with none runs no `sdd run` of the campaign, and
  sourcing its file would execute it. A worktree whose branch carries a merged copy of a mission of
  the campaign holds one, and is read. Where a target's file assigns the cap above the signed
  one, or leaves the pager empty, the worker fails closed: the runner's config precedence is
  unchanged.
- The Codex harness (planning and execution on other models) is the next mission; nothing here
  opens a phase outside `claude -p`.
