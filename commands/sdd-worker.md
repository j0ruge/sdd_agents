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
loop, the stops, and the way to cross a night without spending its own context window
(ADR 0022 of the sdd kit).

**You are the worker.** You coordinate each act through `/sdd-plan`, `sdd approve`, `sdd run`,
`gh` and the commands below. `review-ci` publishes evidence for the review act you authorize.

- `sdd-worker delegate <campaign-dir>` is the owner's, never yours: it shows the delegation, asks,
  and signs it. You never answer its question.
- `sdd-worker level <campaign-dir> [--lot L<n>]`: the effective level of autonomy, with the reason.
- `sdd-worker allows <campaign-dir> <act> --mission <mission-dir>`: rc 0, the act is yours alone;
  rc 1, it goes back to the owner, and the line names the level it needs. Every act is of one lot,
  and the lot's ceiling is the act's: the lot of an act on a mission is the `lot:` of
  `<mission-dir>/00-missao.md`, never a word you pass. `<mission-dir>` is the mission's folder,
  `<HANDOFF_DIR>/<mission>` in the worktree it runs in: the folder `pr-ready` reads too. Only
  `plan`, which comes before its mission, is asked by lot:
  `sdd-worker allows <campaign-dir> plan --lot L<n>`. Any other call is rc 2.
- `sdd-worker budget <campaign-dir>`: the campaign's spend against its ceiling, and the mission cap.
- `sdd-worker next <campaign-dir>`: the next act of the campaign, derived from the disk and `gh`.
- `sdd-worker pr-ready <mission-dir> <pr>`: `ready <sha>` only when the merge bar holds on the
  pull request's head.
- `sdd-worker review-ci <mission-dir> <pr>`: run the configured suite and publish its status on
  the pushed head, as part of the authorized `review` act.

`sdd-worker` lives beside the runner, in the kit's `bin/`:
`"$(dirname "$(readlink -f "$(command -v sdd)")")/sdd-worker"`. Below, `sdd-worker` is that path.

## Before anything else

1. **Take the campaign directory** as the argument: the directory holding `campaign.md` and
   `delegation.md` (`docs/campaigns/<YYYYMMDD>-<slug>/` in a target, `docs/superpowers/campaigns/…`
   in the kit). No argument, or a directory with no `campaign.md`: stop and ask the owner which
   campaign.
   **For Codex, put the campaign in the repository's primary checkout** (the first `worktree`
   entry from `git worktree list --porcelain`). Use that checkout's campaign directory for
   preparation and signing. The Codex guard reads the campaign and delegation there, even when
   the mission runs from a linked mission worktree.
2. **Run `sdd-worker level <campaign-dir>`** and show its line. Under `assisted` nothing is yours
   alone: propose each act, with the exact command you would run, and wait for the owner's yes. The
   reason after ` — ` says why (no delegation, illegible, unsigned, edited after signing, expired,
   no pager): tell the owner what needs fixing. The owner signs with `sdd-worker delegate` in a
   terminal of his own.
   For a delegation above `assisted`, **check the pager before asking the owner to sign**. A level
   of `assisted` with reason `unsigned` is returned before the pager check. Read the effective
   `ON_ESCALATION_CMD` from `.sdd/config.sh` in the campaign checkout and each existing checkout
   that holds a mission of the campaign, from each checkout's root. Report any checkout where the
   value is empty, without printing or invoking the command.
3. **Read `harness:`, `plan_model:` and `exec_model:`** in the campaign frontmatter. Accept
   `claude` and `codex`. Inspect the mission worktree's effective configuration before opening a
   session. For Claude, EXEC reads `MODEL_EXEC` there. For Codex, pass `PHASE_ENGINE=codex` to the
   runner and compare `exec_model:` with `CODEX_PHASE_MODEL` (default `gpt-6.2-sol`). Report a
   mismatch to the owner before running the phase.
4. **Never act while an `sdd run` of another mission is alive in the same checkout.** One checkout,
   one owner of execution: each mission runs in its own worktree, and
   `sdd status <mission> --no-gates` names who holds a checkout.

## The loop

Every turn of the loop, in this order, reading the disk again each time: the delegation can expire,
or be edited, between two acts, and the answer of the last turn is not the answer of this one.

Capture each verdict when calling the verb that decides the next step. For `budget` and `next`,
set `act` to the verb and `campaign_dir` to the campaign path:

```bash
rc=0
verdict="$(sdd-worker "$act" "$campaign_dir" 2>&1)" || rc=$?
why="${verdict%%$'\n'*}"
```

Decide with this `rc` and the saved `verdict`, including any second line from `next`. Keep both
through the decision and record the original stop line as `why`. If the output is not readable,
record an indeterminate cause and keep the captured output for the owner. Do not run the verb
again to explain a stop.

1. `sdd-worker budget <campaign-dir>`: rc 1 is a stop, named by the line it printed (below): the
   campaign ceiling reached, less of it left than the mission cap a run may spend (`no room — …`),
   a mission cap the runner would not apply (`no mission cap — …`), or a ceiling or a spend it
   could not read (`no ceiling — …`, `no spend — …`). A Codex cost check may also stop with
   `no cost exception — …` or `unknown cost — …`. The budget line prints the mission cap, the
   `BUDGET_MISSION_USD` the next `run` passes.
2. The act. When the last act of the lot has a move in **The transitions** (below), the act is that
   one; otherwise `sdd-worker next <campaign-dir>`, whose first line is
   `<act> <lot> <mission> — <reason>`. The line `done - -` ends the campaign; rc 1 is a `stop …`
   line; rc 3 is a `gh` that did not answer: wait and ask again, and never read it as "no pull
   request". A second line `ahead plan <lot>` lets the next lot be planned while this one runs or is
   reviewed, when its own `plan` act is allowed.
3. `sdd-worker allows <campaign-dir> <act> --mission <mission-dir>`, on the folder of the mission
   `next` named, or `sdd-worker allows <campaign-dir> plan --lot <lot>` for a plan: rc 0, the act is
   yours; rc 1, propose it to the owner, with the exact command, and wait for his yes. The yes is
   for that act alone: with it, go back to 1, and when steps 1 and 2 bring the same act again, the
   yes stands for this step's rc 0; another act asks again.
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
| Codex `run`, rc 2 and `PR needs worker publish` | `pr` | publish under the signed `pr` act before continuing |
| `pr` | `review` | the body is written, and the round comes next |
| `review`, every criterion A and the Codex receipt on the head | `merge`: `allows … merge`, then `pr-ready` | `next` answers `review` again for an open pull request; an rc 1 of `pr-ready` names the act that fixes its item |
| every wait: the owner's yes, a bot, a deadline, a run | step 1, `budget` | the ceiling read before the wait, and the delegation, may have moved since |

A new session finds the last act of each lot in the journal's tail: a `run` with rc 0, or with
rc 2 for a mission of the kit with only the stamp missing, and no `pr` line after it is a `pr`
still to do, though the pull request is open and `next` says `review`. A Codex run journaled
with `PR needs worker publish` also resumes at `pr`, even if `next` still finds no pull request.

## The acts

Each act starts with its `allows` call, the first line under its heading. An rc 1 there turns the
act into a proposal to the owner, whatever `next` answered.

### `plan`

`sdd-worker allows <campaign-dir> plan --lot <L>`

Run `/sdd-plan` for the lot, with the planner on the campaign's `plan_model:`: the strongest model
plans. The mission's `00-missao.md` declares `campaign: <id>` and `lot: <L>` in its frontmatter,
which is how `next` finds it. Under delegation the relay answers the grill with the recommended
option, and every answer that touches a rule of the owner is listed in the pull request body, for
his acceptance. The plan, the grill and the report go to files.

For delegated Codex planning, run
`<kit>/bin/sdd-plan-codex start <mission> <topic> --campaign <absolute-campaign-dir> --lot <L>`
in the mission worktree. Use the same executable for the relay commands below if it is not on PATH.
Before every turn, the relay runs `sdd-worker codex-plan <campaign-dir> --lot <L>` to verify the
signed Codex terms, the lot's plan authority, and the campaign's known budget. The worker's
orchestration and the relay's planning turns are not part of the mission-spend ledger.
Plan with `gpt-6.2-astra`. Read the pending question with
`sdd-plan-codex status <mission>` after a relay restart. Give the selected answer verbatim once
with `sdd-plan-codex answer <mission> <question-id> <answer>`. If the native turn itself was
interrupted, use `sdd-plan-codex recover <mission>` to recover the question from the same thread.
Use `sdd-plan-codex finish <mission>` to materialize the draft. If the plan requires an ADR,
allocate it with `sdd adr new`, write the agreed decision, and link it from the mission before approval.

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

`sdd-worker allows <campaign-dir> approve --mission <mission-dir>`

Measure again before approving: `tests/check-checkpoint.sh --check <checkpoint>` and
`--red <checkpoint>` by the kit's path, the `--red` in the background and waited for its last line.
A `FAIL`, or a run without the line `<n> pending Check(s), every one red at HEAD`, goes back to
`plan`. Write the extract of the plan the owner would have read to a file in the mission's
directory, then run `printf 'y\n' | sdd approve <mission>` in the mission's worktree. It writes
`humano-YYYY-MM-DD` even under delegation: the journal line is the trail of who approved.

### `run`

`sdd-worker allows <campaign-dir> run --mission <mission-dir>`

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
cd <mission-worktree> && BUDGET_MISSION_USD=<cap> SDD_DELEGATED_MISSION_CAP_USD=<cap> \
  setsid -w nohup env -u CLAUDECODE \
  bash -c 'rc=0; sdd run "$1" || rc=$?; printf "sdd run rc=%s\n" "$rc"' _ <mission> > <log> 2>&1 < /dev/null &
echo "$!"
```

The `-w` keeps that PID alive until the runner exits. In a shell with job control the background
job leads its own process group, and `setsid` then forks; without `-w` its parent, the `$!`, exits
at once, and a wait on it ends before the run does.

Wait on that PID (`tail --pid=<pid> -f /dev/null`, or a monitor whose condition is
`! kill -0 <pid>`), never on `pgrep -f`, which matches its own command line (M23). Then read the
final `sdd run rc=` line of the log retained for this invocation.
An rc 0 is the pull request open; an rc 2 is a human step the runner
names, except the rc 2 of a mission of the kit with the pull request open and only the stamp
missing, which goes on as an rc 0 does (**A mission of the kit**). On `PR needs worker publish`,
continue at the signed `pr` act. An rc 3 is an escalation the runner already paged, with the
worktree's pager, which `level` requires as it requires the campaign checkout's.

Read the verdict from that log (with its path in `log`), never from a later invocation or the
latest row of a shared ledger. The ledger still calls both ceilings `budget-exhausted`. If the
log has a single readable ceiling diagnostic, use it verbatim in the journal. A missing exit
record or an unreadable or ambiguous diagnostic does not establish either ceiling. Keep the log
for the owner and report an indeterminate cause when stopping without clear evidence.

```bash
rc=unknown
run_result="$(tail -n 1 -- "$log" 2>/dev/null)" || run_result=
if [[ "$run_result" =~ ^sdd\ run\ rc=([0-9]+)$ ]]; then
  rc="${BASH_REMATCH[1]}"
fi
if [ "$rc" = unknown ]; then
  reason=indeterminate
  why="runner exit status indeterminate ($log)"
elif [ "$rc" = 3 ]; then
  why="$(awk '
    /^sdd run stop: / {
      n++
      if ($0 ~ /^sdd run stop: (mission-ceiling|phase-ceiling) — .*[^[:space:]]/) line = $0
    }
    END { if (n == 1) print line }
  ' "$log" 2>/dev/null)" || why=
  case "$why" in
    'sdd run stop: mission-ceiling — '*) reason=mission-ceiling ;;
    'sdd run stop: phase-ceiling — '*) reason=phase-ceiling ;;
    *) reason=indeterminate; why="runner stop cause indeterminate ($log)" ;;
  esac
fi
```

Record the rc and reason in the journal and wait for the owner after an escalation. For a
readable non-ceiling escalation, retain its name and original diagnostic from the same log.
For other stops, use the original diagnostic for the decision (for example the Codex config
change below). A missing exit record is not permission to continue.

For a Codex campaign, run `PHASE_ENGINE=codex sdd preflight` in that worktree before launching
`sdd run`. Set `PHASE_ENGINE=codex` alongside `BUDGET_MISSION_USD` in the launch command. Before
each Codex model session, the runner verifies the signed delegation with
`sdd-worker codex-run --mission <mission-dir> --phase <phase> [--model <model>]`. The owner must explicitly grant
`allow_unknown_cost: true` when signing the Codex delegation. If the signature, cost exception,
or ordinary run authority fails verification, stop and return the diagnostic to the owner.
Budget output reports the known subtotal and any reference API estimate separately.

When a Codex run exits on a config change, only the runner's
`Codex mission cap reduced … (config <hash>, phase <phase>)` diagnostic is a restart candidate.
Wait for that run to exit and retain its PID and log. Check that the diagnostic belongs to this
mission and worktree and that `git hash-object --no-filters -- .sdd/config.sh` there still matches
the reported hash. Recheck `sdd-worker allows … run --mission …`, `sdd-worker budget` and the
phase's `sdd-worker codex-run` (with the configured model for EXEC) for mission headroom. Repeat
the Codex preflight in that worktree and confirm the hash still matches. Only then launch a fresh
`sdd run`, with the signed cap from the new budget verdict and no forced phase. Keep that PID and
log as usual. If any check fails, there is another edit, the cause is uncertain, or the new run
stops again before the mission advances, stop and report the diagnostic. A generic config-change
error is not permission to relaunch.

For a delegated Claude run, pass both cap variables shown above. The runner checks the reloaded
cap before each phase and inline retry. Zero and values above the signed cap stop the run. A
valid reduction applies at the next dispatch, with the spend checked against the lower ceiling.

### `pr`

`sdd-worker allows <campaign-dir> pr --mission <mission-dir>`

For Codex, `sdd run` returns rc 2 with `PR needs worker publish` when work at the PR gate remains.
Resume at this act under the signed `pr` authority. In the mission worktree, follow the publisher
procedure in `agents/sdd-publisher.md` as the worker. Check the suite and branch before pushing.
If the handoff says `draft only`, or that run's journal records `PUBLISH_ON_REVIEW_BLOCKED=draft`,
check the existing PR state before pushing. If the PR is already ready, report that conflict and
stop without pushing or editing the PR. For a new draft-only PR use `gh pr create --draft`. Push only
the mission branch, create or update its pull request and record verified `50-pr.md`. For a `draft only` handoff, verify that `gh pr view --json isDraft --jq .isDraft` prints `true`
in addition to checking the artifact gate. Then use
`PHASE_ENGINE=codex sdd why <mission> PR` to read the verdict. Check for `PR: PR open:` rather
than relying on the command's exit code. If only the kit mutation stamp is missing and the PR is
already open, apply the kit-specific exception above. On any other refusal, stop before advancing
to review and resolve or report the reason. Merge remains a separate act
requiring `allows … merge` and `pr-ready`.

After the PR opens, this act completes the information its body owes the owner. It lists the
grill answers that touch his rules, and declares every bot but Codex that did not review (no quota,
no plan, a rate limit) as "did not review": such a bot neither blocks nor counts as a review. Codex
is never one of them: its receipt on the head is an item of `pr-ready`, so a Codex that does not
answer is the `no-receipt` stop. When the run left no pull request, open it from the mission's
branch with `gh pr create`, never by a push to the base.

### `review`

`sdd-worker allows <campaign-dir> review --mission <mission-dir>`

In the mission's worktree, bring the base in (`git fetch`, then `git merge origin/<base>`), run the
suite (`TEST_CMD`), then run `sdd review-base <mission>` and hand its one line to the subagent that
makes the review round: on `base=<sha> — <round> …` it invokes `/codereview:codereview base=<sha>`
and reads that round for the findings it left open; on `full — <reason>` the round is whole (a merge
of the base after the last round makes it whole, by the same rule). Use `gpt-6.2-sol` at `xhigh` for the Codex review subagent, and load the installed Codex
`codereview` skill for that round. The subagent writes the report
to a file and returns only the grade table, each grade with its one-sentence rationale. Write the round as
`<HANDOFF_DIR>/<mission>/40-review-r<N>.md`, one above the newest, with `reviewed_head: <sha>` in
its frontmatter, the `git rev-parse HEAD` the round read, and the suite's result in `gate:`.
`pr-ready` refuses a round whose rationale or `gate:` is still a fill-in of `templates/review.md`,
and one whose grade table leaves out the row of any of its eight criteria.
The runner's REVIEW rounds write `reviewed_head:` too, but a commit after it outside the mission
folder (the DOCS phase's) leaves `pr-ready` waiting for this one. Fix what the round finds and review
again, until every criterion is A. Commit and push the round, then run
`sdd-worker review-ci <mission-dir> <pr>` in its worktree. The earlier suite run does not count as
evidence on the pushed head. Use the same authenticated GitHub account for this step and for
`pr-ready`, with permission to write commit statuses for this step. If the suite fails, the head
moves, or the status cannot be published, record the diagnostic and stop the act. Do not proceed
on a previously read verdict. After a successful publication, ask `@codex review` on the pull
request, always, and wait for its receipt on the new head.

### `merge`

`sdd-worker allows <campaign-dir> merge --mission <mission-dir>`

Run `sdd-worker pr-ready <mission-dir> <pr>`, on the folder its `allows` call read. Only
`ready <sha>` (rc 0) merges, and the merge is
`gh pr merge <pr> --merge --match-head-commit <sha>` with that very sha: always a merge commit, never
a squash or a rebase, which would orphan every `RESOLVED by <hash>` the branch wrote. An rc 1 names
the item that failed: go back to the act that fixes it, never around it. An rc 3 is a `gh` that did
not answer: wait and ask again.

### `postmerge`

`sdd-worker allows <campaign-dir> postmerge --mission <mission-dir>`

What the merge leaves for the base (the roadmap, `TODO.md`, `KAIZEN_LOG.md`) goes in a pull request
of its own, from a branch cut from the updated base, never a push to it; it gets its own review
round and its Codex receipt, as `review` writes them. Open it before the loop calls `next` again:
`next` does not derive this act, so the journal line of the merge names it, and a new session
resumes from there.

## The five stops

Each stop writes one line to `journal.md`, pages via `ON_ESCALATION_CMD` unless the runner
already paged, and ends the loop. Then the session waits for the owner, whatever the level.
From the repository root, use the saved `rc` and `why` with `campaign_dir`, `lot`, `mission`,
`act` and the stop's `reason`. Use the same line in the journal and in `SDD_GATE_WHY`, never text
pasted between quotes or a new measurement. The pager gets five seconds, as the runner gives it:

```bash
printf -- '- %s · %s · %s · %s (rc %s) — %s\n' \
  "$(date '+%Y-%m-%d %H:%M')" "$lot" "$act" "$reason" "$rc" "$why" >> "$campaign_dir/journal.md"
if [ "$act" != run ] || [ "$rc" != 3 ]; then
  ( . .sdd/config.sh && SDD_REASON="$reason" SDD_PHASE="$act" SDD_PROJECT="${PROJECT_NAME:-}" \
    SDD_MISSION="$mission" SDD_GATE_WHY="$why" \
    timeout -k 1 5 bash -c "$ON_ESCALATION_CMD" < /dev/null )
fi
```

A line of a verb that measured no stop is paged the same way, named by what the verb printed: a
`stop …` line of `next` with `SDD_REASON=next-stop`; a `no ceiling — …` line of `budget` (no
delegation, or an illegible one) with `no-ceiling`; a `no spend — …` line (no checkout, a
`git worktree list` that failed, an upstream of the campaign's checkout that does not read, a ledger
that does not read) with `no-spend`. None of them is
`campaign-ceiling`: nobody measured a spend.

Report `no cost exception — …` with `SDD_REASON=no-cost-exception`, and `unknown cost — …`
with `SDD_REASON=unknown-cost`. Include the original diagnostic for the owner and stop.
Neither result means the measured campaign ceiling was reached.

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
4. **`mission-ceiling`**: the saved `sdd run` diagnostic names `mission-ceiling` (the mission spent its `BUDGET_MISSION_USD`); or `sdd-worker budget` answered `no mission cap — …`, the config of the campaign's checkout or of a mission's worktree sets that key over the signed cap, or the delegation signs a mission cap of zero, which the runner reads as no ceiling, or one below one cent.
5. **`campaign-ceiling`**: `sdd-worker budget` leaves rc 1 on its `campaign US$ <spent> of <ceiling>` or `campaign known US$ <spent> of <ceiling>` line when the measured spend reached the ceiling.

A runner diagnostic naming `phase-ceiling` means a phase ran out of sessions or review rounds,
not that the mission ran out of money. Record it separately without paging again.

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
