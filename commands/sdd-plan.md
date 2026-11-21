---
description: Plan an sdd mission interactively (brainstorm → grill → 00-missao/01-plano/checkpoint)
---

Start the PLAN phase of an sdd mission in the current repository.

This command exists because `PLAN` is the one phase the runner refuses to boot — *"PLAN is
interactive by design: the human takes part in the grill"* — and because the kit installs the
agents into a target repo but **never the templates**. In a headless phase the runner injects their
absolute path; here, that is this command's job. Without it a session either guesses the path or
writes the artifacts from memory, and their headings are the contract the gates parse.

## Before anything else

1. Resolve the repository root (`git rev-parse --show-toplevel`) and read `.sdd/config.sh` there.
   **If it does not exist, stop** and tell the user, verbatim:

   > This repository has no `.sdd/config.sh` — the `sdd` kit is not installed here.
   > Run `sdd install && sdd-link-agents` and edit the config before planning.
   > Recipe: `~/repos/sdd_agents/docs/plan-only.md`

   Do not invent a `HANDOFF_DIR`, and do not create the config yourself: `sdd install` derives
   `DEFAULT_BRANCH` and `TEST_CMD` from the repo, and a hand-written stub would carry neither.

   **Then read the checkout, before anything is written or delegated.** Read `HANDOFF_DIR` and
   `DEFAULT_BRANCH` from that config here (step 3 still reports them, later), and run, at the root,
   `git status --porcelain`, `git branch --show-current` and `ls <HANDOFF_DIR>`. When that directory
   holds a mission folder, also run `sdd status --no-gates <mission>` with the name of any one of them:
   it takes no lock and refuses to run without a mission name, and a `CHECKOUT-OWNER` line in its
   answer means another command holds this checkout. With no mission folder at all, run
   `pgrep -af '[b]in/sdd run'` instead. Show the human one line with what you read, then take the
   first of these exits that applies:
   - **A folder in `HANDOFF_DIR` already covers the topic:** stop, and show the human that folder
     and what `sdd status --no-gates` says of it. In `dotp-remake` 3.6d the tree held twelve paths
     of a plan another session was executing by hand, and the folder of 3.6d already existed,
     merged: only the relay's own `git status` and `git log` held the planner. This exit comes
     first even when a run holds the checkout: the folder of a mission in flight lives here, and
     the worktree of step 2, cut from `origin/<DEFAULT_BRANCH>`, does not have it until it merges.
   - **Another command holds the checkout** (a `CHECKOUT-OWNER` line, or a live `sdd run` of this
     repository): step 2 applies, even outside the kit. The planner writing here would put a foreign
     `00-missao.md` inside that run's phase, which its hat guard reads as the phase's own writing
     (`HAT-CROSSED`), and every commit of the run would move the `HEAD` the relay watches.
   - **A dirty tree with no command holding the checkout, or a branch other than `DEFAULT_BRANCH`:**
     stop, and ask the human which base the mission is cut from — go on here, switch branch, or a
     worktree. Never clean, stash or switch branch yourself: the dirty paths may be another
     session's work, and a mission cut from another branch inherits its commits. In `ui24_agent` the
     checkout was on the branch of an open PR, and the planner would have read a checkout that is
     not the base.

2. **If this checkout is the kit that `sdd` runs from, move to a linked worktree before writing
   anything.** Resolve `sdd="$(readlink -f "$(command -v sdd)")"` and compare it with the root from
   step 1: when it lies under that root (`case "$sdd" in "$root"/*)` — the slash keeps a sibling
   such as `<root>-lote-5` out), every `sdd run` of every other repository on this machine executes
   this checkout, and its kit guard compares this checkout's `HEAD` and `git status --porcelain`
   before and after each phase. One untracked `00-missao.md` written here while a target's EXEC
   runs stops that run with `KIT-TOUCHED` (rc 3); a linked worktree, dirty or with commits, moves
   neither. So, before writing any artifact:
   - create the worktree beside this checkout, on a provisional branch cut from the remote's
     `DEFAULT_BRANCH` — `git fetch`, then
     `git worktree add ../<repo>-<slug> --no-track -b <provisional> origin/<DEFAULT_BRANCH>` — or
     reuse it, when it already exists for this mission. Provisional, because the mission's id, and
     with it the name `branch:` declares, comes out of the grill, and the worktree has to exist
     before the grill writes anything: the planner renames the branch when the grill decides the
     id (see *Then*), and the directory keeps its provisional name. Never `git pull` here to
     freshen the base: a fetch moves no `HEAD`, a pull moves the very one the kit guard compares.
     `--no-track` keeps the mission branch off `origin/<DEFAULT_BRANCH>`: without it, a `git pull`
     in the worktree brings the base in silently and `git status` counts ahead/behind against it
     (measured with git 2.43.0, 2026-10-15);
   - take the worktree as the repository root for every step below: the config, `HANDOFF_DIR`,
     the artifacts, `sdd why` and `sdd approve` all run from there, and this checkout stays on
     `DEFAULT_BRANCH`, clean. Inside it, `health`, `preflight` and `install` run as `./bin/sdd`:
     the `sdd` on the PATH keeps its `SDD_HOME` in this checkout, and would install this
     checkout's `agents/` over the worktree's;
   - tell the human, in one line, the worktree's path and branch, and that the mission is
     executed there too — interactively, or, under the campaign worker, by a `sdd run` launched
     in that worktree through the `sdd` on the PATH (ADR 0022 §7); never by a `sdd run` from this
     checkout. Copy no killer
     map into the worktree, and ask for nothing to come back after the merge: the map and the
     stamp live in `<git-common-dir>/sdd-mutation/`, which the worktree shares with this checkout,
     so both outlive `git worktree remove` (ADR 0021).

   When `sdd` is not on the PATH, or resolves outside this root, skip this step: no run of another
   repository executes this checkout. The one exception is the second exit of step 1: when another
   command holds this checkout, this step applies to any repository.

   **In a target with a run in flight** (step 1 found another command holding the checkout), the same
   `git fetch` and the same `git worktree add ../<repo>-<slug> --no-track -b <provisional> origin/<DEFAULT_BRANCH>`
   apply, the worktree is the repository root for every step below, and one line tells the human its
   path and branch. What belongs to the kit alone — `health`, `preflight` and `install` as
   `./bin/sdd`, the killer map and the stamp — does not apply. In `lighthouse_project` the relay
   planned piece C this way while M2 ran `sdd run` in the main checkout, and M2's `pipeline.log`
   closed with no `HAT-CROSSED` nor `FOREIGN-COMMIT`.

3. From that config, read `HANDOFF_DIR`, `OUTPUT_LANG`, `DEFAULT_BRANCH`, `TODO_FILE` and
   `JIRA_ENABLED`. Report them back in one line, so the user sees what the session is about to
   honour.

4. List the four templates you will write from, by absolute path, and confirm each one exists:

   - `~/repos/sdd_agents/templates/missao.md` → `00-missao.md`
   - `~/repos/sdd_agents/templates/plano.md` → `01-plano.md`
   - `~/repos/sdd_agents/templates/checkpoint.md` → `checkpoint.md`
   - `~/repos/sdd_agents/templates/checkpoint-notas.md` → `checkpoint-notas.md` (optional)

   A missing template is a stop, not a warning — writing the artifact from memory is the exact
   failure this step prevents.

## Then

Delegate to the `sdd-planner` subagent, handing it: the mission topic the user gave (ask, if the
command came with no argument), the repository root it writes under (the worktree, when step 2 moved
you), the config values from step 3, and the absolute template paths from step 4 — stated as *the*
templates to start from, never as examples.

Pass the model too, as the model of the subagent call: the campaign's `plan_model:` when `/sdd-worker` runs this command, else the `model:` of the hat (`fable`).
Measured by the relay in the kit's lots L1b and L2 (2026-11-19 and 2026-11-20), while the hat
carried no `model:` in its frontmatter and only its prose said Fable: without the model in the call
the subagent inherited the model of this session, and both planners opened on `claude-opus-5-5`
until the second was stopped and relaunched with the model in the call. With the `model: fable`
the hat declares now, what the harness does without the model in the call is not measured yet
(pending item 4 of `20261120-l2-o-sdd-plan-e-o-planner`), so the call keeps carrying it.

**When the agent type is not registered** (`Agent type 'sdd-planner' not found`, or the type is
missing from the list of agents this session offers): the harness reads that list when the session
opens, so an agent installed after it opened, or linked in a child of the directory it opened in,
is not there — the link in `.claude/agents/` does not help this session. Tell the human so, and
ask them to run `sdd install && sdd-link-agents` in the target (when it is not done yet) and to
reopen the session at the repository root; that is the way out, because only the registered hat
carries its `permissionsDeny`. Only if the human chooses to go on in this session, delegate to a
general agent instead: hand it the same briefing, tell it to read the absolute path of
`agents/sdd-planner.md` as its contract, and write in the briefing the three vetoes that hat's
`permissionsDeny` holds — never run `git push`, `gh pr create` and `gh pr merge` — because a
general agent does not load them. Then tell the human in one line that the grill runs
without the registered hat, with those three vetoes in prose only.

When step 2 moved you, hand the planner two more orders, and hold it to them:

- **The branch.** When the grill decides the mission's id, the planner renames the branch inside
  the worktree with `git branch -m <provisional> <branch>`, while the branch has no upstream, and
  writes that name in `branch:`. From then on the worktree is on the branch `sdd approve` reads,
  and no provisional branch is left behind (batches 9 and 10 renamed `fix/lote-N` this way).
- **The working directory.** The planner inherits this session's cwd, which is the main checkout.
  It runs every command as `cd <worktree> && …`, and writes scratch files only to an absolute path
  outside the main checkout. Before you delegate, record
  `git -C <main checkout> status --porcelain` and `git -C <main checkout> rev-parse HEAD`; run
  both again at every hand-back, before you relay the question. If either changed, stop: show the
  human the paths and the `HEAD` that changed, and never delete or reset anything there yourself —
  a path in that checkout may belong to another writer. In batch 9 a relative `2>e` of the
  planner left `?? e` in the main checkout, and a target's `sdd run` in flight would have stopped
  with `KIT-TOUCHED` (rc 3). When the worktree exists because a run holds the main checkout (the
  exit of step 1 for a checkout another command holds), compare at each hand-back only the paths outside the directory of the mission in flight,
  and do not stop on a `HEAD` that run moves: its commits and its mission's files are its own, and
  stopping on them stops the grill for nothing. That run also edits the product there, uncommitted,
  and nothing tells its edit from another writer's: the kit attributes a commit by its reflog label,
  never an uncommitted path (`.claude/rules/anatomia-do-agente.md` §6). So do not stop on a tracked
  file that changed either: name it to the human in the line of the hand-back, and go on. Stop only
  on a new untracked path (`??`) outside that directory, which is the shape the planner leaves (the
  `?? e` of batch 9), and let the human say whether the run made it.

When step 2 did not move you, record the same two — `git status --porcelain` and
`git rev-parse HEAD`, at the repository root — before you delegate, and again at every hand-back. A
path that changed outside the mission's directory, or a `HEAD` you did not move, you show the human
as above. A commit you make yourself during the grill (the human asked for a line in a roadmap,
say) changes the base the planner measured: send the new `HEAD` to the planner with the next answer,
never in a message of its own (*Nothing else resumes the planner*, in the next section). In
`dotp-remake` 3.2c the relay committed `b674421` after the planner had measured the suite at
`d6d6cf8`, and the plan recorded the right base only because the new `HEAD` went with the next
answer.

The planner conducts the brainstorm and the grill **with the human present** — through you, as the
next section says, because it cannot reach the human on its own. Do not plan on their behalf, and
do not let the session drift into implementing: PLAN writes three artifacts and nothing else.

The mission's id names its directory and must match `^[0-9]{8}-[a-z0-9-]+$` (eight digits, a
hyphen, then lower-case ASCII letters, digits and hyphens): the runner refuses any other mission
name in every command, so a slug with a dot, an accented letter or a prefix stops at `sdd status`.

## Relaying the grill to the human

The planner runs as a subagent, and a subagent has no tool to ask the human anything; in this
harness it also runs in the background. The session that ran `/sdd-plan` is the **relay**: it never
answers for the human, save under the one exception of **Grill answers delegated in writing** below,
and it never paraphrases either side.

- **The planner's side.** Every turn ends — the hand-back — with ONE grill question (two only when
  they are independent), written in `OUTPUT_LANG`, with 2–4 concrete options: the recommended one
  first and marked as such, a one-line why for each, and above them, concisely, the evidence the
  human needs to choose.
- **The relay's side.** Ask the human with the harness's question tool — the options verbatim, the
  recommended one first — and hand the answer back VERBATIM to the SAME planner by continuing that
  agent (`SendMessage` to its id, for instance; a new `Agent` call starts from zero and loses the
  grill). Name the chosen option by the option's text, never by its position: a question asked twice
  can come back reordered. Relay anything else the human says mid-grill the same way.
- **The session of the relay died mid-grill.** When you delegate, tell the human in one line the id
  of the planner agent, so that a later session can reach it. A session that opens after the relay's
  session died never starts a new planner: it must resume the same planner by its id (`SendMessage`), which keeps the grill.
  A call that came back saying the session ended before its result was recorded, so its outcome is unknown, counts as **not answered**:
  ask the human the pending question again before you send the planner any answer. Measured in
  `dotp-remake` 3.2c: the session died with a question pending, and in the new session a
  `SendMessage` to the old planner's id came back `Resuming agent`, with the ten decisions intact.
- **Nothing else resumes the planner while a question is pending.** The planner ends every turn with
  a question, so a message that answers nothing — a finding of yours, an issue number, a status —
  makes it ask again, and the second asking can come back reordered or with another recommendation.
  Hold such a message and send it WITH the human's next answer. Measured in the grill of
  `20261006-lote-5-o-que-o-lote-4-deixou`: an issue number sent alone brought questions 4 and 5 back
  with the recommended option of question 5 swapped, after the human had answered the first asking.
- **A question asked twice is one question.** A job the planner left running can end after its
  hand-back and open a new turn that asks the pending question again. A hand-back that repeats a question you already relayed
  does not go to the human again: answer it once, by the option's text, with the answer the human
  already gave, and tell the planner that it answers the first asking. A repeat that changed — other
  options, another recommendation — is a new question, and goes to the human. Measured in the grill
  of `ui24_agent`: a background suite of the planner ended after the hand-back, and the planner
  asked question 1 again with the human's answer already with the relay.
- **Count the answer marks at every hand-back.** From the moment `00-missao.md` exists, run the
  reader of D22 (the `awk` of step 3.2 of "When the artifacts exist") at every hand-back, and stop when its `M` exceeds the answers you handed back:
  the planner marked an answer the human never gave. Show the human that decision and send the
  planner nothing until they answer it. Under `aprovacao: auto` too, because step 2 of the
  acceptance skips the reader. Measured in `magic_tutor`: decision 7 came out
  `- answer: (recommended)` with `aprovacao: auto` before Q7 reached the human, and `sdd status`
  read `plan approved (auto)`; the relay caught it by reading the file.
- **A message can land after the hand-back.** Read what `SendMessage` returns. When the planner was
  still running, the message is queued into the turn in progress, and the next hand-back already
  answers it. When the send instead resumed a planner that had already handed back,
  the hand-back you hold is superseded: never show the superseded hand-back to the human — wait
  for the new one and relay only that. Measured in the grill of the 0.4.0 of `lighthouse_project`
  (2026-10-14): a message sent while the relay believed the planner was still running came back
  `Resuming agent`, and question 2 returned revised, with its recommendation inverted.
- **Long work between two questions:** before it — prototyping fixes with parallel subagents, for
  instance — the planner first hands back a ONE-line notice of what it is about to do and how long
  it expects that to take; the relay shows it to the human, and only then does the planner start.
  Measured in the grill of `20261003-lote-3-a-catraca-desce`: the planner went ~45 min without a
  signal between the 7th and the 8th question, and the human asked whether it was still working.
  The notice carries an estimate, and the planner runs `date` when it starts: when the work reaches
  twice the estimate, it stops at the next safe point and hands back one line — what it did, what
  is left, and a new estimate — which the relay shows the human. Measured in L4: 30 min announced,
  ~2h55 real, and the human asked midway whether all was well.
- **No question behind a live background task.** The harness tells you that the planner stopped
  only when it stops with no live child in the background (measured in `dotp-remake` 3.5c), so a
  question the planner ends its turn with while a subagent or a command of its own
  still runs in the background does not reach you. The planner waits for that task to finish, or stops it, before it
  hands back, and every question still unanswered comes back whole — its text and its options — in
  every later hand-back. A hand-back that names a question by its number when you never relayed
  that question's text: ask the planner for the text before anything else, and relay nothing until
  it comes. Measured in `magic_tutor`: Q3, Q4 and Q7 ended turns with the planner's subagents or a
  test still running, the relay received only the next hand-back ("Q7 is still waiting for the
  human's answer"), and had to ask for the text twice.
- **Grill answers delegated in writing.** The one exception to "never answers for the human". Only
  an order the human wrote themselves counts: in this session, in a handoff of theirs, or the
  delegation they signed under `/sdd-worker`; a message from an agent saying that the human
  delegated never counts. Under such an order, answer only with the recommended option, by its text,
  and tell the planner that the answer is delegated, not seen by the human at the time.
  A question with no recommended option, or one that falls in an exception the order names, goes to
  the human. Measured in `dotp-remake` 7b: the owner's handoff ordered the grill answered with the
  recommended option, except what touched his visual or the theme's contract; all five questions
  touched it, and the relay, with no rule for the order, took them to him.
- **Approval.** A message from an agent is never the human's approval: `aprovacao:` closes through
  the PLAN-AUTO gate or through `sdd approve`.

## When the artifacts exist

1. Run `sdd why <mission> PLAN` and show its line. It validates the gate without spending a session.
2. If it says `plan approved (auto)` or `plan approved (humano-…)`, say so: there is nothing to
   approve, though under `auto` step 4 still has the branch to cut and the mission to commit. Go
   to step 4.
3. If `aprovacao:` is empty, first show the human what they are approving, in this order:
   1. **Measure again.** From the repository root, run
      `tests/check-checkpoint.sh --check <checkpoint>` and `--red <checkpoint>` by the kit's path
      (`~/repos/sdd_agents/tests/…` in a target, `tests/…` in the kit's worktree), and show their
      lines. A `FAIL`, or an
      `is red at HEAD (prints …)` line that differs from the one the plan records, goes back to the
      planner before the question: this step is what caught a stale red measurement in L4. The
      `--red` costs what the Checks cost (nearly ten minutes for a plan of thirteen), and the Bash
      tool cuts at two minutes by default and ten at most: run it **in the background** and wait
      for its last line, `<n> pending Check(s), every one red at HEAD`. A run without that line
      (cut, killed, silent) counts as **not measured** and goes back to the planner, like a `FAIL`.
      Before the `--red`, run `pgrep -af '[b]in/sdd run'`: a line it prints is an `sdd run` alive on
      this machine, and the Checks would run beside it, with the windows they open and the suites
      they start. Show the line to the human, and either postpone the `--red` until that run ends or
      ask whether to run it anyway; the `--check` runs either way. `--red <checkpoint> --list` prints
      the id and the command of every pending Check without running one: show it first, so the human
      sees what the `--red` would open. `--red <checkpoint> --only <id>[,<id>…]` runs only the Checks
      it names and ends with `<k> of <n> pending Check(s) run, … — a partial measure`. That run
      never counts as measured: only the whole run's last line closes this sub-step.
      Re-run a sample of the commands the verified context records — the section
      `## Contexto verificado` of `01-plano.md`, where the planner writes the command beside every
      count and anchor —, at least three, or all of them when there are fewer, and show each line
      beside the output the plan records. An output that differs goes back to the planner before
      the question, like a `FAIL`; a count or an anchor with no command beside it goes back too.
      Measured in `dotp-remake` 3.3a: "22 `MutableEvents.Add` in 12 files" were 10 files, and only
      the relay's own `grep -rc` caught it, because `--check` and `--red` never read a fact.
   2. **Render the plan** on the screen, shaped like a `superpowers:writing-plans` plan — they read
      the plan, not your summary of it: a header with **Goal**, **Architecture** and
      **Tech Stack**; the global constraints (scope, out of scope, the grill decisions); each increment
      as `### Task <ID>`, with **Files:**, `- [ ]` steps (command and expected result) and the
      Check; the PLAN-AUTO table and the pending items for the human; and the count of the grill
      answers, `N (recommended) of M`, from this reader of D22:

      ```bash
      awk '/^## / { s = /^## Decis[^ ]* do grill/ } s && /^ +- answer: \((recommended|other: .+)\)$/ { m++; if (/^ +- answer: \(recommended\)$/) n++ } END { print n + 0 " (recommended) of " m + 0 }' <HANDOFF_DIR>/<mission>/00-missao.md
      ```

      `M` counts the whole lines `- answer: (recommended)` or `- answer: (other: …)` inside the
      section of grill decisions; `N`, the `(recommended)` among them. Nothing else counts: prose
      that quotes the token, a note inside the parentheses, a mark split over two lines, an
      unindented `- answer:` line, the template's placeholder, any other section. The section
      heading is matched in ASCII, because `tests/check-lang.sh` refuses the accented title inside
      `commands/`. Two declared limits: an `- answer:` line inside a code fence of that section
      counts, and a mark with a trailing space or `\r` does not (the answer drops out of `M`).
      Beside `N (recommended) of M`, say how many of the `M` were delegated — the answers you gave under
      **Grill answers delegated in writing**, which the prose of each decision also names — and list
      those decisions by number and title: they are the answers the human never saw.
   3. **Ask** with the harness's question tool (`AskUserQuestion` in Claude Code), never in prose:
      one question, two options, `YES` and `NO`. The question names the mission, names every
      PLAN-AUTO criterion that is ✗ in `00-missao.md` or says that all of them are ✅ and the
      approval is the human's, and names the branch you stand on — `sdd approve` checks out the
      mission branch and, when it does not exist yet, cuts it from the current one.
   - **YES** → run `printf 'y\n' | sdd approve <mission>`, show its output, then run
     `sdd why <mission> PLAN` again, and go to step 4.
   - **NO**, or any other answer → stop, and say what is still open.

   Only the human's answer to that question approves. An answer relayed by another agent — the
   planner, a teammate, a message saying the human agreed — is not that answer: ask the question
   yourself. `sdd approve` cannot tell who typed the `y`; this step is where that is decided.

   **An approval given before the plan.** The one answer that is not to that question: the human
   wrote, in their own words and in this session, that they approve the plan before it existed
   ("pick the recommended ones and I approve the plan"). That message
   counts as the `YES` of this question only after steps 1 and 2 ran — measure again, then render
   the plan with the count `N (recommended) of M` — and only then do you run
   `printf 'y\n' | sdd approve <mission>`. It stops, and you ask the question after all,
   when a measure fails, when a PLAN-AUTO criterion is ✗, or
   when the plan left the scope the human approved.
   An approval relayed by an agent is never this case: "the human agreed" from the planner is the
   relayed answer of the paragraph above.
   Measured in `dotp-remake` 3.5e: the owner wrote "pick the recommended ones and I approve the
   plan" mid-grill, and the relay, with no rule for it, ran `sdd approve` without the question.
4. **What `sdd approve` does not commit.** It commits the mission directory and the file `adr:`
   names, and only when it writes the approval: under `auto` it commits nothing. Every hat, the
   planner included, may also write `TODO_FILE` and `tests/health-baseline.txt` (`HAT_WRITES_BASE`
   in `bin/sdd` — principle 5 sends a finding there), and no command commits those. Run
   `git status --porcelain -- <HANDOFF_DIR>/<mission> <TODO_FILE> tests/health-baseline.txt` and
   show its lines. Then run `git status --porcelain` with no path, and show what it lists outside
   those three: a file the plan depends on (the plan cites it as existing, and the session that
   executes will look for it) is committed on the mission branch with the rest, by the bullet that
   applies below; anything else is named to the human, never committed and never deleted. Measured
   in `dotp-remake` 3.5e: the planner wrote a survey under `docs/knowledge/` that the plan cites,
   `sdd approve` did not commit it, and only the whole `git status` showed it.
   - **Under `auto`** (`sdd why` said `plan approved (auto)`) → nobody cut the branch or committed
     the mission: `sdd approve` was never run. A `branch:` of `00-missao.md` that is empty
     or still the `<...>` placeholder names no branch to cut (the hat admits it only under
     `JIRA_ENABLED=true`, where the TICKET phase creates the branch and writes it back):
     switch to nothing and follow **Anywhere else**. Otherwise move to that `branch:` with
     `git switch -c <branch>`, or `git switch <branch>` when it already exists, commit there the
     mission directory and the file `adr:` names, then follow **On the mission branch** for the
     rest, and tell the human that the next step is `sdd run <mission>`. Measured in `magic_tutor`:
     `plan approved (auto)` with the mission directory untracked on `main`, and the relay cut the
     branch and committed by hand, with no rule for it.
   - **On the mission branch** (`git branch --show-current` is the `branch:` of `00-missao.md`,
     where `sdd approve` leaves you) → commit what it lists with `git add -- <paths>` and
     `git commit -- <paths>`, never `-a`. Findings in `TODO_FILE` go in their own commit, which
     moves the `todo-findings` line of `tests/health-baseline.txt` in the same diff when the repo
     carries that ratchet (the kit does). A finding already open gains an entry on the item's
     `RECURRED` line (`~/repos/sdd_agents/templates/todo.md`), never a new item, and that entry
     moves no ratchet: the count of findings stays.
   - **Anywhere else** → commit nothing, and name the paths to the human: a commit on the branch
     you stand on lands the plan or the finding where the mission does not run.

   Measured in `20261006-lote-5-o-que-o-lote-4-deixou`: two findings registered during the grill
   were still ` M TODO.md` after `sdd approve`, with the ratchet unmoved.

⚠️ Never write approval prose in `aprovacao:`. The gate accepts only `auto` — which the planner
writes when the human asks for it in the grill — or `humano-YYYY-MM-DD`, which comes from
`sdd approve`; approval prose that reads correct to a human — `humano aprovou o plano em
2026-09-08` — is **rejected** by it. That has already shipped once, in `sales_quote`. This warning
forbids approval prose in `aprovacao:`, never `auto`: relayed to the planner as "never write
`aprovacao:`", it suppressed an `auto` in L2. `sdd approve` is the command that ends this failure.

$ARGUMENTS
