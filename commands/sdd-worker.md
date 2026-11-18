---
description: Orchestrate an sdd campaign under the owner's signed delegation (budget → next → allows → act → journal)
---

Run a campaign of sdd missions in the current repository, as far as the owner's delegation allows.

This command exists because the owner already delegated whole chains of missions to a session, by
word, three times (`docs/superpowers/specs/2026-11-16-o-worker-merge-delegado.md`), and the
judgments that decided a merge were the model's reading and went wrong on record: a Codex receipt
matched by the hour instead of the sha (M13), a watcher whose `pgrep -f` matched itself (M23), a
bot with no quota read as "reviewed" (M1), a checker that read 20 of 21 units (M24). Those
questions are now answered by `bin/sdd-worker`, from artifacts. This command gives the session the
loop, the stops, and the way to cross a night without spending its own context window (ADR 0022).

**You are the worker.** `sdd-worker` only answers, and signs; it never acts. Every act is yours,
through the commands that already exist: `/sdd-plan`, `sdd approve`, `sdd run`, `gh`. Its verbs:

- `sdd-worker delegate <campaign-dir>` is the owner's, never yours: it shows the delegation, asks,
  and signs it. You never answer its question.
- `sdd-worker level <campaign-dir> [--lot L<n>]`: the effective level of autonomy, with the reason.
- `sdd-worker allows <campaign-dir> <act> --lot L<n>`: rc 0, the act is yours alone; rc 1, it goes
  back to the owner, and the line names the level it needs. With no `--lot` it is rc 2: every act
  is of one lot, and the lot's ceiling is the act's.
- `sdd-worker budget <campaign-dir>`: the campaign's spend against its ceiling, and the mission cap.
- `sdd-worker next <campaign-dir>`: the next act of the campaign, derived from the disk and `gh`.
- `sdd-worker pr-ready <mission-dir> <pr>`: `ready <sha>` only when the five-item bar holds on the
  pull request's head.

`sdd-worker` lives beside the runner, in the kit's `bin/`:
`"$(dirname "$(readlink -f "$(command -v sdd)")")/sdd-worker"`. Below, `sdd-worker` is that path.

## Before anything else

1. **Take the campaign directory** as the argument: the directory holding `campaign.md` and
   `delegation.md` (`docs/campaigns/<YYYYMMDD>-<slug>/` in a target, `docs/superpowers/campaigns/…`
   in the kit). No argument, or a directory with no `campaign.md`: stop and ask the owner which
   campaign.
2. **Run `sdd-worker level <campaign-dir>`** and show its line. Under `assisted` nothing is yours
   alone: propose each act, with the exact command you would run, and wait for the owner's yes. The
   reason after ` — ` says why (no delegation, illegible, unsigned, edited after signing, expired,
   no pager): tell the owner, who fixes it and signs again with `sdd-worker delegate`, in a terminal
   of his own.
3. **Read `harness:`, `plan_model:` and `exec_model:`** in the frontmatter of `campaign.md`. A
   harness other than `claude` stops here: this command drives Claude Code only. `exec_model:` is
   what the campaign declares, and nothing passes it on: the runner runs EXEC on `MODEL_EXEC` (each
   other phase on its own `MODEL_<PHASE>`, `config/schema.md`), from the `.sdd/config.sh` of the
   mission's worktree over the environment, `opus` when neither sets it. Before a `run`, read that
   key there; when it is not `exec_model:`, tell the owner, and never edit his file to match.
4. **Never act while an `sdd run` of another mission is alive in the same checkout.** One checkout,
   one owner of execution: each mission runs in its own worktree, and
   `sdd status <mission> --no-gates` names who holds a checkout.

## The loop

Every turn of the loop, in this order, reading the disk again each time: the delegation can expire,
or be edited, between two acts, and the answer of the last turn is not the answer of this one.

1. `sdd-worker budget <campaign-dir>`: rc 1 is a stop, named by the line it printed (below): the
   campaign ceiling reached, less of it left than the mission cap a run may spend (`no room — …`),
   a mission cap the runner would not apply (`no mission cap — …`), or a ceiling or a spend it
   could not read (`no ceiling — …`, `no spend — …`). Its line prints the mission cap, the
   `BUDGET_MISSION_USD` the next `run` passes.
2. The act. When the last act of the lot has a move in **The transitions** (below), the act is that
   one; otherwise `sdd-worker next <campaign-dir>`, whose first line is
   `<act> <lot> <mission> — <reason>`. The line `done - -` ends the campaign; rc 1 is a `stop …`
   line; rc 3 is a `gh` that did not answer: wait and ask again, and never read it as "no pull
   request". A second line `ahead plan <lot>` lets the next lot be planned while this one runs or is
   reviewed, when its own `plan` act is allowed.
3. `sdd-worker allows <campaign-dir> <act> --lot <lot>`: rc 0, the act is yours; rc 1, propose it to
   the owner, with the exact command, and wait for his yes. The yes is for that act alone: with it,
   go back to 1, and when steps 1 and 2 bring the same act again, the yes stands for this step's
   rc 0; another act asks again.
4. The act, as the section below writes it.
5. One line in `<campaign-dir>/journal.md`, append-only: `- <instant> · <lot> · <act> · <outcome>`,
   the instant from `date '+%Y-%m-%d %H:%M'` run in the same batch of commands, never from memory.
   Never in the checkout the `sdd` on the PATH resolves to while an `sdd run` is alive, and no other
   file of the campaign directory either: the runner arms its kit guard on that checkout in every
   run (`kit_guard_arm`), and a line appended there stops the run with `KIT-TOUCHED`, rc 3. The
   kit's own campaign is in that checkout when its directory is passed there: while a run you
   launched is alive, keep its lines outside that checkout and append them once the run has ended.
6. Back to 1, and after every wait too: a ceiling or a delegation read before a wait does not hold
   after it.

## The transitions

`next` derives `plan`, `approve`, `run` and `review` from the disk and `gh`, and it reads every open
pull request as `review`, whatever happened to it. These moves it never derives are yours, and each
act still passes its own `allows` call (step 3):

| After | The act | Why |
|---|---|---|
| `run`, rc 0 | `pr` | the run opened the pull request, and its body still owes the owner the grill answers and the bots that did not review |
| `run` of a mission of the kit, rc 2, the pull request open and only the stamp missing | `pr` | the kit's `gate_PR` waits for the mutation stamp, which a mission's pull request of the kit merges without: the run left what an rc 0 leaves |
| `pr` | `review` | the body is written, and the round comes next |
| `review`, every criterion A and the Codex receipt on the head | `merge`: `allows … merge`, then `pr-ready` | `next` answers `review` again for an open pull request; an rc 1 of `pr-ready` names the act that fixes its item |
| every wait: the owner's yes, a bot, a deadline, a run | step 1, `budget` | the ceiling read before the wait, and the delegation, may have moved since |

A new session finds the last act of each lot in the journal's tail: a `run` with rc 0, or with
rc 2 for a mission of the kit with only the stamp missing, and no `pr` line after it is a `pr`
still to do, though the pull request is open and `next` says `review`.

## The acts

Each act starts with its `allows` call, the first line under its heading. An rc 1 there turns the
act into a proposal to the owner, whatever `next` answered.

### `plan`

`sdd-worker allows <campaign-dir> plan --lot <L>`

Run `/sdd-plan` for the lot, with the planner on the campaign's `plan_model:`: the strongest model
plans. The mission's `00-missao.md` declares `campaign: <id>` and `lot: <L>` in its frontmatter,
which is how `next` finds it. Under delegation the relay answers the grill with the recommended
option, and every answer that touches a rule of the owner is listed in the pull request body, for
his acceptance. The plan, the grill and the report go to files; the planner returns only its verdict.

The mission runs in a worktree of its own, cut before anything of it is written. In the kit,
`/sdd-plan` cuts it (its step 2), and the planner renames its branch. In a target, the session cuts
it before `/sdd-plan`, beside the campaign's checkout and from the base, with `git fetch` and then
`git worktree add <mission-worktree> --no-track -b <provisional> origin/<DEFAULT_BRANCH>`, and runs
`/sdd-plan` from it (`cd <mission-worktree>`), so the plan, `sdd approve` and `sdd run` all happen
there and `next` finds the mission in that worktree. Once the plan names the mission's branch
(`branch:` in its `00-missao.md`), the session renames the worktree's branch to it, while the
branch has no upstream:
`git -C <mission-worktree> branch -m <provisional> <branch>`.

### `approve`

`sdd-worker allows <campaign-dir> approve --lot <L>`

Measure again before approving: `tests/check-checkpoint.sh --check <checkpoint>` and
`--red <checkpoint>` by the kit's path, the `--red` in the background and waited for its last line.
A `FAIL`, or a run without the line `<n> pending Check(s), every one red at HEAD`, goes back to
`plan`. Write the extract of the plan the owner would have read to a file in the mission's
directory, then run `printf 'y\n' | sdd approve <mission>` in the mission's worktree. It writes
`humano-YYYY-MM-DD` even under delegation: the journal line is the trail of who approved.

### `run`

`sdd-worker allows <campaign-dir> run --lot <L>`

Launch `sdd run` in the mission's worktree, detached from this session, with the mission cap that
`budget` printed, and keep the PID it echoes. The runner sources the `.sdd/config.sh` of the
checkout it runs in, the mission's worktree and not the campaign's checkout, over its environment,
so the cap passed here holds only where that file leaves `BUDGET_MISSION_USD` alone or assigns it a
cap at or below this one; the starter assigns `150`, and a worktree cut from a commit that still has
the line keeps it after the owner deletes it in the campaign's checkout. That is why `budget` reads
first the file of the campaign's checkout and of each worktree that holds a mission of the campaign
(no other: a worktree with none runs no `sdd run` of the campaign, and its file is never executed),
each from its own checkout, and answers `no mission cap — …`, rc 1, naming the file and the value,
when a line sets the key above the signed cap, to zero, or to anything the runner does not take as
a number: a stop, never a run. A signed cap of zero, or below one cent, stops it first, naming the
delegation. The cap the line prints is the signed one, as written, and that is the value to pass.
The pager is read the same way: `allows run` reads the `ON_ESCALATION_CMD` of the same checkouts,
and an empty one in the mission's worktree answers `ask … — no pager`, naming that file.

```bash
cd <mission-worktree> && BUDGET_MISSION_USD=<cap> setsid -w nohup env -u CLAUDECODE \
  bash -c 'sdd run "$1"; echo "sdd run rc=$?"' _ <mission> > <log> 2>&1 < /dev/null &
echo "$!"
```

The `-w` keeps that PID alive until the runner exits. In a shell with job control the background
job leads its own process group, and `setsid` then forks; without `-w` its parent, the `$!`, exits
at once, and a wait on it ends before the run does.

Wait on that PID (`tail --pid=<pid> -f /dev/null`, or a monitor whose condition is
`! kill -0 <pid>`), never on `pgrep -f`, which matches its own command line (M23). Then read the
`sdd run rc=` line of the log. An rc 0 is the pull request open; an rc 2 is a human step the runner
names, except the rc 2 of a mission of the kit with the pull request open and only the stamp
missing, which goes on as an rc 0 does (**A mission of the kit**); an rc 3 is an escalation the
runner already paged, with the worktree's pager, which `level` requires as it requires the campaign
checkout's: write it in the journal and wait for the owner, and `budget-exhausted` among them is a
stop (the mission ceiling).

### `pr`

`sdd-worker allows <campaign-dir> pr --lot <L>`

The run's PR phase opens the pull request; this act is what its body owes the owner. It lists the
grill answers that touch his rules, and declares every bot but Codex that did not review (no quota,
no plan, a rate limit) as "did not review": such a bot neither blocks nor counts as a review. Codex
is never one of them: its receipt on the head is an item of `pr-ready`, so a Codex that does not
answer is the `no-receipt` stop. When the run left no pull request, open it from the mission's
branch with `gh pr create`, never by a push to the base.

### `review`

`sdd-worker allows <campaign-dir> review --lot <L>`

In the mission's worktree, bring the base in (`git fetch`, then `git merge origin/<base>`), run the
suite (`TEST_CMD`), and make the review round through a subagent that writes the report to a file
and returns only the grade table, each grade with its one-sentence rationale. Write the round as
`<HANDOFF_DIR>/<mission>/40-review-r<N>.md`, one above the newest, with `reviewed_head: <sha>` in
its frontmatter, the `git rev-parse HEAD` the round read, and the suite's result in `gate:`.
`pr-ready` refuses a round whose rationale or `gate:` is still a fill-in of `templates/review.md`,
and one whose grade table leaves out the row of any of its eight criteria.
The rounds the runner's REVIEW phase writes carry no `reviewed_head:`, so `pr-ready` waits for this
one. Fix what the round finds and review again, until every criterion is A. Commit and push the
round, then ask `@codex review` on the pull request, always, and wait for its receipt on the new
head.

### `merge`

`sdd-worker allows <campaign-dir> merge --lot <L>`

Run `sdd-worker pr-ready <mission-dir> <pr>`. Only `ready <sha>` (rc 0) merges, and the merge is
`gh pr merge <pr> --merge --match-head-commit <sha>` with that very sha: always a merge commit, never
a squash or a rebase, which would orphan every `RESOLVED by <hash>` the branch wrote. An rc 1 names
the item that failed: go back to the act that fixes it, never around it. An rc 3 is a `gh` that did
not answer: wait and ask again.

### `postmerge`

`sdd-worker allows <campaign-dir> postmerge --lot <L>`

What the merge leaves for the base (the roadmap, `TODO.md`, `KAIZEN_LOG.md`) goes in a pull request
of its own, from a branch cut from the updated base, never a push to it; it gets its own review
round and its Codex receipt, as `review` writes them. Open it before the loop calls `next` again:
`next` does not derive this act, so the journal line of the merge names it, and a new session
resumes from there.

## The five stops

Each stop runs `ON_ESCALATION_CMD`, writes one line to `journal.md`, and ends the loop.
Then the session waits for the owner, whatever the level. Page the way the runner does, from the
repository root, with the stop's name in `SDD_REASON`, the line it rests on in `SDD_GATE_WHY`, and
five seconds for the pager:

```bash
why="$(sdd-worker budget <campaign-dir>)"
( . .sdd/config.sh && SDD_REASON=<stop> SDD_MISSION=<mission> SDD_GATE_WHY="$why" \
  timeout -k 1 5 bash -c "$ON_ESCALATION_CMD" < /dev/null )
```

`why` is set in the same batch of commands, by running again the verb whose line stopped the loop,
as above, or by reading the file the session wrote the line to: never by pasting the line between
quotes, which an apostrophe in an id or a path ends.

A line of a verb that measured no stop is paged the same way, named by what the verb printed: a
`stop …` line of `next` with `SDD_REASON=next-stop`; a `no ceiling — …` line of `budget` (no
delegation, or an illegible one) with `no-ceiling`; a `no spend — …` line (no checkout, a
`git worktree list` that failed, an upstream of the campaign's checkout that does not read, a ledger
that does not read) with `no-spend`. None of them is
`campaign-ceiling`: nobody measured a spend.

A `no room — …` line of `budget` measured a spend below the ceiling, with less of it left than the
signed mission cap: the next `run` may spend up to its cap and pass the ceiling, so the loop stops
before any act, a merge among them, and the line is paged with `no-room`. It is not a stop of the
spend that reached the ceiling, so it is not `campaign-ceiling`: the owner signs a higher ceiling,
or a mission cap of at most what is left, and the campaign goes on.

The runner pages its own rc 3 already, `budget-exhausted` among them, from the `.sdd/config.sh` of
the worktree it runs in, whose pager `level` reads as it reads this one: that stop is not paged
twice.

1. **`no-receipt`**: no Codex receipt for the head 60 minutes after the explicit `@codex review`.
2. **`below-a`**: a criterion still graded below A after three rounds of review on one pull request.
3. **`conflict`**: a merge conflict with the base outside the findings file and its ratchet.
4. **`mission-ceiling`**: `sdd run` stopped on `budget-exhausted`, the mission spent its `BUDGET_MISSION_USD`; or `sdd-worker budget` answered `no mission cap — …`, the config of the campaign's checkout or of a mission's worktree sets that key over the signed cap, or the delegation signs a mission cap of zero, which the runner reads as no ceiling, or one below one cent.
5. **`campaign-ceiling`**: `sdd-worker budget` leaves rc 1 on its `campaign US$ <spent> of <ceiling>` line, the spend it measured reached the ceiling; only on that line.

## Never

No level grants these, and no delegation can:

- Delete a branch or a worktree (`--delete-branch`, `git branch -D`, `git worktree remove`).
- Push to the base branch: every change reaches it through a pull request.
- Give the visual acceptance of a journey: what the owner has to see is his, at every level.
- Move the kit's main checkout while a run is alive (`git pull`, `git checkout`, a commit there, a file of a campaign directory written there).

## Context

The night is longer than one context window, so what matters lives on disk, never in this
conversation:

- One line per event, in `journal.md` and in what you write here: the act, the lot, the outcome.
- A report, a plan or a review round goes to a file, and the subagent that wrote it returns only its verdict.
- At every lot closed, merged or stopped, a handoff to a file in the campaign directory (`handoff-<lot>.md`).
- A new session resumes from `sdd-worker level` and `sdd-worker next`, and the journal's tail, with no memory of this one.

## A mission of the kit

The kit's own mission runs in the mission's linked worktree, by `sdd run` from that worktree: the
`sdd` on the PATH is the kit's main checkout, which the mission does not edit. The kit's `gate_PR`
asks for the mutation stamp, so `sdd run` leaves with rc 2 when the pull request is open and only
the stamp is missing. That rc 2 goes to `pr` as an rc 0 does (**The transitions**), by the owner's
standing rule that a mission's pull request of the kit merges without the stamp: the pull request
is open, and its body still owes the owner what `pr` writes.
