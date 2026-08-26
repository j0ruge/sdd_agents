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

## A handoff that declares `status: blocked`

**Symptom:** `sdd run` exits with code 3 and `BLOCKED in <PHASE> — <handoff> has status: blocked`,
after **one** session of that phase, with five lines telling you to read the handoff.

**Cause:** the phase's own session wrote `status: blocked` in its handoff's frontmatter. That token
has always meant "the line stopped and a human has to act"; since `20260826-o-laco-da-qa` the runner
escalates on the declaration itself instead of routing it through the fingerprint heuristic. Before
that, a phase nobody could satisfy was charged a **second** session to prove the same thing twice —
and a session that failed the gate but committed something honest read as progress and bought
another lap. That is a deliberate Jidoka, filed in the ledger as `kind: handoff-blocked` alongside
`increment-blocked`, not as friction.

**What you do:** read the handoff the message names. What it needs from a human is written in its
"Decisions for a Human" section. Take the decisions, set the handoff's `status:` back, and run
`sdd run` again.

**In QA specifically, check the bug's genre first.** If the phase is blocked by an `open` bug that
waits on a product decision, the answer is usually not for you to unblock the handoff by hand: it is
that the bug should carry `- **Closable by:** human` (see the section below and
[ADR 0006](adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md)).

**Do not:** re-run the phase hoping a fresh session decides differently. Another session re-reads
the same handoff and refuses the same way — the runner says so in its own refusal, and that is the
whole reason it stopped instead of spinning.

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
what `ledger_repo_root` derives — the shared `.git` **itself**, `cd "$(git rev-parse
--git-common-dir)" && pwd -P`, with a trailing `/.git` stripped off when the repo is not bare —
with `jq -r .repo ~/.sdd/autonomy-log.jsonl | sort -u`. ⚠️ Not the PARENT of that path, which was
the first spelling and merged repositories silently: in a submodule the common dir is
`/parent/.git/modules/<name>`, so the parent is the same string for every submodule of one parent,
and in a bare repo it is `.`, so the parent is whatever directory happens to hold the repo. If the
question really is cross-project
maturity, that is what `--all-repos` is for: `sdd autonomy --all-repos`, `sdd kaizen --series
--all-repos`. ⚠️ At read time the comparison is verbatim on both sides by design: a `realpath`
invented there would silently merge two checkouts the ledger deliberately keeps apart. Full
contract in [`pipeline.md`](pipeline.md) § "The autonomy ledger".

**Do not:** read this as data loss. What the filter removed is **counted**, and by reason —
`excluded.other_repo` for rows born elsewhere and `excluded.no_repo` for rows that name no project
at all (field absent, `null`, or empty — one answer, not three), one `N row(s) excluded` line each
in the human table, plus its own "no data" voice per silence: an empty file, a wholly unattributable
ledger, a cwd in no repo, a ledger of somebody else's rows, and a **mixed** one, which says how the
rows split because `--all-repos` reaches the foreign ones and can reach none of the unattributable
ones. An empty series is `guard.sufficient: false`, which supports
only `indeterminado`. A throwaway fixture repo's numbers read as a verdict about this kit is
exactly what the default filter exists to prevent.

⚠️ **`sufficient: false` in the kit repo is not this failure mode.** If `guard.degenerate_axis` is
`true`, the last three kit versions in the slice each hold exactly one **mission** — the unit the
floor counts, never sessions — and no number of
missions *here* will clear the floor — the axis is being read in the repo that builds the kit. It
reads a window and not the whole file on purpose: over all of history one ancient sha with two
sessions would switch the explanation off forever, and an append-only ledger could never switch it
back on. `sdd kaizen` says so
and names [ADR 0003](adr/0003-judge-axis-evidence-from-target-repos.md); the floor is not the
defect and does not loosen. ⚠️ Careful with the ancient-sha sentence above: the unit there is
missions too. One old version that carried two *missions* is what latches the window off — and the
second clause, "no version anywhere ever reached the floor", is what keeps the whole thing off a
healthy repo that is merely quiet.

---

## `sdd kaizen` refuses: "the ledger could not be read"

**Symptom:** `sdd kaizen` (or `--dry-run`) prints `malformed row in <path> — the ledger is not
readable` and then `error: the ledger could not be read (the series reader exited 1) — this is NOT
'not judged yet'`, rc 1, with **no session opened**. `sdd kaizen --series` alone warns the same and
exits 1 with no JSON on stdout.

**Cause:** one row of `~/.sdd/autonomy-log.jsonl` is not valid JSON — a truncated write, a hand
edit, a file appended to by two processes at once. Before this was checked, the reader's empty
output was assigned into `series=$(kaizen_series)` with the return code dropped, and `errexit` is
**off** inside every gate (each caller runs `gate_KAIZEN || rc=$?`), so an unreadable ledger read
back as "no verdict for the kit yet" — a doubled space in that message was the only tell — and the
runner went on to spend an opus session judging a series nobody could read.

**What you do:** run `sdd autonomy`, which names the file and dies on the same row, then find it
with `jq -c . ~/.sdd/autonomy-log.jsonl` — the last line it prints before failing is the one before
the break. The ledger is append-only *facts*, so the repair is to fix or delete that one row; a row
that was never valid JSON never carried a fact.

**Do not:** re-run hoping a fresh session fixes it, and do not point a session at it. The file
lives in `$HOME`, **outside** the repo the session is given — no session can reach it, so the only
thing another attempt buys is a second opus bill and the same sentence. This is why the gate
publishes a reason of its own (`GATE_KAIZEN_UNREADABLE`, whose `GATE_WHY` names the remedy) instead
of letting the phase look merely unsatisfied — "unreadable" and "not judged yet" ask for opposite
things from you.

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

## `sdd preflight` warns: this git does not know `--path-format`

**Symptom:** a yellow `warn` line about `rev-parse --path-format` (2.31+). Nothing fails, no phase
stops.

**Cause:** the autonomy ledger stamps a repository **identity** on every row, and that identity is
the shared `.git` resolved absolute. `ledger_repo_root` asks for it in one shot with
`git rev-parse --path-format=absolute --git-common-dir`, born in git 2.31. An older git does not
reject the flag — `git rev-parse` **echoes back** an option it does not recognise and still exits
0, so it answers two lines, the flag and a still-relative path. Ubuntu 20.04 ships 2.25 and
Debian 11 ships 2.30.

**How the kit reacts:** the function refuses that shape and then **resolves** the identity the old
way (`cd` + `pwd -P`, both `cd`s with an emptied `CDPATH`), which answers the same string. The
ledger stays correct; the cost is one extra `rev-parse` per ledger write. The probe is by
**behaviour** and not by `git --version`, for the same reason as the GNU userland above: what the
runner needs is an answer, not a number.

**What you do:** nothing, unless you want the fast path back — then upgrade git. Do **not** "fix"
this by making the refusal return empty: empty is the contract for *"not a repository"*, so every
row would be filed under `excluded.no_repo`, a bucket `--all-repos` deliberately does not admit,
and `sdd autonomy` would answer "no data" while `sdd kaizen` could only ever say `indeterminado` —
silently, permanently, because the ledger is append-only. That regression shipped and was caught
in the r2 review of `20260818-lote-facil`; the differential assertion in `tests/check-autonomy.sh`
now demands the two gits **agree**, not that the old one stays quiet.

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

**Symptom:** `BLOCKED in QA` after `QA_MAX_ITER` rounds, or `N bug(s) with Status: open in the
registry that an agent could close` on every lap.

**First, check the genre of the bugs that are holding it.** Since `20260826-o-laco-da-qa` the gate
does not ask for an empty registry — it asks that no `open` bug be one **an agent could close**. A
bug whose fix is a product decision belongs to nobody in this pipeline (no agent may write the
`Status:` line), so it must carry `- **Closable by:** human` or it holds the phase for ever. The
count in the refusal includes every **unmarked** bug, which is exactly the bug whose genre nobody
has decided yet. Left unmarked, this is not a convergence problem at all: it is the loop that cost
7 of the 12 QA sessions of `20260825-frete-cif-fob`, US$ 73,32 of that mission's US$ 144,88, before
the field existed. The runner names the escape hatch in its own refusal;
[ADR 0006](adr/0006-qa-anchor-reads-genre-blocked-handoff-stops-the-line.md) has the reasoning.

Three cheap things get read as "unmarked", because the match is deliberately strict and its
looseness would fail **open**: a value written after the `<!-- agent | human -->` legend instead of
before it, a translated value (`humano`), and a capitalised one (`Human`). All three block; none of
them says so out loud. `agents/sdd-qa.md` § 5.1 spells the exact shape.

**Typical cause once the genres are right:** each fix breaks another journey — a sign the defect is
deeper than the recorded symptoms.

**What you do:** read the `30-handoff-qa.md` of each round. If the bugs move around every round,
the problem is one of design and belongs back in planning, not with the executor.

---

## The review does not close at Grade A

**Symptom:** `BLOCKED in REVIEW` with `N review round(s) already on disk, REVIEW_MAX_ITER=M`.

**The ceiling counts rounds IN TOTAL**, derived from the `40-review-r<N>.md` files — not sessions
per invocation. Re-running `sdd run` does **not** hand out a fresh set of rounds, which is exactly
what it used to do: 4 REVIEW sessions over 3 invocations, ~US$ 107, and no `BLOCKED` anywhere. So
the headline can name **0 sessions**: this invocation opened none, because the ceiling refused
before it could. The line under it names the count that actually refused.

**What you do:** read the last `40-review-r<N>.md` — the real grade is there. If the findings are
legitimate and large, the mission was badly sliced. If you want the PR anyway, set
`PUBLISH_ON_REVIEW_BLOCKED="draft"`: out comes a **draft** PR with the current grade and the open
items visible, instead of hiding the problem.

**To run one more round anyway**, two ways, and they mean different things. `sdd run <mission>
--phase REVIEW` is exempt from the disk-derived ceiling — a human asking for one specific round
with their eyes on it — and is the right one when you know what that round has to fix. Raising
`REVIEW_MAX_ITER` in `.sdd/config.sh` lifts the ceiling for every future round of every mission in
the repo, which is a decision about the project and not about this mission.

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

## The `PR` gate refuses: "no green mutation catalogue for this content"

**Symptom:** every other gate is green, the branch is ready, and `sdd why <mission> PR` answers
`no green mutation catalogue for this content — run 'sdd health' (since 4c86712 TEST_CMD does not
run the catalogue, so no gate before this one measures it)`. Running `tests/run-all.sh` by hand
answers `suite green`, which makes the refusal look like a lie. It is not.

**Cause:** the catalogue is opt-in — `TEST_CMD` does not run it — so no gate before this one has
measured whether the suite's assertions still bite. The `PR` gate therefore demands the **artifact**
`sdd health` leaves behind: a stamp keyed on the content of `bin/ tests/ templates/ config/`. Three
states produce this message and only the first is common:

- **nothing was ever stamped** on this tree, or the last stamp was for other content — the ordinary
  case, and usually it means a commit landed after the last `sdd health`;
- **the catalogue came back red**, so the stamp was removed rather than left behind;
- **the tree moved while the catalogue was running** — a commit, or an editor swap file, landing
  during the twenty-to-fifty-minute round. `sdd health` says so out loud
  (`the measured tree moved WHILE the catalogue was running`) and stamps nothing, because the green
  it just reported is about content that is no longer there.

**How the kit reacts:** it stops, and it stops **last** — after `50-pr.md` and `gh pr view`, so the
likelier failures still speak first. Nothing is pushed, nothing is merged. In a repo without
`tests/check-mutation.sh` this requirement does not exist at all.

**What you do:** run `./bin/sdd health` from the checkout the mission is in, and run it **after the
last commit that touches `bin/ tests/ templates/ config/`**. Twenty to fifty minutes on a laptop; a
green round ends with `mutation stamp written` and the gate opens. Two things worth knowing before
you start it:

- editing `CLAUDE.md`, `CONTEXT.md`, `docs/` or `TODO.md` does **not** invalidate the stamp, so the
  DOCS phase can work freely — but `tests/health-baseline.txt` **does**, and that is where the
  backlog ratchet lives. Recording an out-of-scope finding therefore costs the stamp. The collision
  is a known item in `TODO.md`, with its direction;
- do not start it on a tree you are still committing to. The window guard will refuse the round and
  you will have spent the wall-clock for nothing.

Design, and why this is a stamp rather than CI, is
[ADR 0004](adr/0004-mutation-catalogue-owner-stamp-not-ci.md).

---

## `sdd health` fails: the backlog count moved

**Symptom:** `sdd health` exits 1 with **two** lines about the same number — `fail  finding
outside the baseline: todo-findings <N>` and `fail  stale baseline: 'todo-findings <M>' is no
longer a finding — delete the line` — while every other check stays green.

**Cause:** nothing is broken. `TODO.md` gained (or lost) findings and `tests/health-baseline.txt`
still freezes the old count. Both messages fire from a single edit because the emitted finding is
new **and** the frozen line lost its pair — the ratchet bites both ways on purpose: debt may not
grow in silence, and a list describing a world that no longer exists is worse than no list at all.

**How the kit reacts:** `sdd health` only. The ratchet is deliberately **outside** `TEST_CMD`: a
cap inside the suite would fail `gate_EXEC`/`QA`/`REVIEW` of every mission in flight, including the
one that just recorded the finding.

**What you do:** write the new number into `tests/health-baseline.txt` **in the same commit** as
the finding that moved it. That is the whole point — growing stays allowed, growing undeclared does
not, and the count moves in a diff with an author. Take `<N>` from the failure message or from
`tests/check-todo.sh` (`  ok    N finding(s) …`), never from a `grep -c` of your own: that answers
one too many, counting the format example inside the header's fenced block. Findings closed with
`RESOLVIDO por <hash>` keep counting until they are deleted, which happens after the PR merges
(`git merge-base --is-ancestor <hash> main`) — so the count usually drops on the post-merge sweep,
not inside the mission that fixed them.

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
The damage cap is a **per-session** ceiling, not a mission budget, and it is **four keys and not
one**. `BUDGET_PER_PHASE_USD` (default 15) applies only to the phases with no key of their own —
DOCS, PR, TICKET, KAIZEN. The three expensive phases read their own: `BUDGET_EXEC_USD` (25),
`BUDGET_QA_USD` (25), `BUDGET_REVIEW_USD` (40). ⚠️ **Raising the global does not raise those
three** — the commonest way to spend an afternoon wondering why a REVIEW keeps dying on the same
ceiling. Full table in [`config/schema.md`](../config/schema.md).

If a phase is expensive over and over, the problem is usually a badly sliced plan — big sessions
re-exploring what the "verified context" should have handed over ready. Raising the cap for that
phase buys a longer session against the same wall.
