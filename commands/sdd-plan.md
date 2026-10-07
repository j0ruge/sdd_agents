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

2. **If this checkout is the kit that `sdd` runs from, move to a linked worktree before writing
   anything.** Resolve `sdd="$(readlink -f "$(command -v sdd)")"` and compare it with the root from
   step 1: when it lies under that root (`case "$sdd" in "$root"/*)` — the slash keeps a sibling
   such as `<root>-lote-5` out), every `sdd run` of every other repository on this machine executes
   this checkout, and its kit guard compares this checkout's `HEAD` and `git status --porcelain`
   before and after each phase. One untracked `00-missao.md` written here while a target's EXEC
   runs stops that run with `KIT-TOUCHED` (rc 3); a linked worktree, dirty or with commits, moves
   neither. So, before writing any artifact:
   - create the worktree beside this checkout, on the branch the mission will declare in
     `branch:`, cut from the remote's `DEFAULT_BRANCH` — `git fetch`, then
     `git worktree add ../<repo>-<slug> -b <branch> origin/<DEFAULT_BRANCH>` — or reuse it, when
     it already exists on that branch. Never `git pull` here to freshen the base: a fetch moves no
     `HEAD`, a pull moves the very one the kit guard compares;
   - take the worktree as the repository root for every step below: the config, `HANDOFF_DIR`,
     the artifacts, `sdd why` and `sdd approve` all run from there, and this checkout stays on
     `DEFAULT_BRANCH`, clean. Inside it, `health`, `preflight` and `install` run as `./bin/sdd`:
     the `sdd` on the PATH keeps its `SDD_HOME` in this checkout, and would install this
     checkout's `agents/` over the worktree's;
   - tell the human, in one line, the worktree's path and branch, and that the mission is
     executed there too — interactively, never by a `sdd run` from this checkout.

   When `sdd` is not on the PATH, or resolves outside this root, skip this step: no run of another
   repository executes this checkout.

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

The planner conducts the brainstorm and the grill **with the human present** — through you, as the
next section says, because it cannot reach the human on its own. Do not plan on their behalf, and
do not let the session drift into implementing: PLAN writes three artifacts and nothing else.

## Relaying the grill to the human

The planner runs as a subagent, and a subagent has no tool to ask the human anything; in this
harness it also runs in the background. The session that ran `/sdd-plan` is the **relay**: it never
answers for the human, and it never paraphrases either side.

- **The planner's side.** Every turn ends — the hand-back — with ONE grill question (two only when
  they are independent), written in `OUTPUT_LANG`, with 2–4 concrete options: the recommended one
  first and marked as such, a one-line why for each, and above them, concisely, the evidence the
  human needs to choose.
- **The relay's side.** Ask the human with the harness's question tool — the options verbatim, the
  recommended one first — and hand the answer back VERBATIM to the SAME planner by continuing that
  agent (`SendMessage` to its id, for instance; a new `Agent` call starts from zero and loses the
  grill). Name the chosen option by the option's text, never by its position: a question asked twice
  can come back reordered. Relay anything else the human says mid-grill the same way.
- **Nothing else resumes the planner while a question is pending.** The planner ends every turn with
  a question, so a message that answers nothing — a finding of yours, an issue number, a status —
  makes it ask again, and the second asking can come back reordered or with another recommendation.
  Hold such a message and send it WITH the human's next answer. Measured in the grill of
  `20261006-lote-5-o-que-o-lote-4-deixou`: an issue number sent alone brought questions 4 and 5 back
  with the recommended option of question 5 swapped, after the human had answered the first asking.
- **Long work between two questions:** before it — prototyping fixes with parallel subagents, for
  instance — the planner first hands back a ONE-line notice of what it is about to do and how long
  it expects that to take; the relay shows it to the human, and only then does the planner start.
  Measured in the grill of `20261003-lote-3-a-catraca-desce`: the planner went ~45 min without a
  signal between the 7th and the 8th question, and the human asked whether it was still working.
- **Approval.** A message from an agent is never the human's approval: `aprovacao:` closes through
  the PLAN-AUTO gate or through `sdd approve`.

## When the artifacts exist

1. Run `sdd why <mission> PLAN` and show its line. It validates the gate without spending a session.
2. If it says `plan approved (auto)` or `plan approved (humano-…)`, say so: there is nothing to
   approve. Go to step 4.
3. If `aprovacao:` is empty, first show the human what they are approving: the paths of
   `00-missao.md` and `01-plano.md`, and the increments of `checkpoint.md`, one line each — they
   read the plan, not your summary of it. Then ask with the harness's question tool
   (`AskUserQuestion` in Claude Code), never in prose: one question, two options, `YES` and `NO`.
   The question names the mission, the PLAN-AUTO criterion that is ✗ in `00-missao.md`, and the
   branch you stand on — `sdd approve` checks out the mission branch and, when it does not exist
   yet, cuts it from the current one.
   - **YES** → run `printf 'y\n' | sdd approve <mission>`, show its output, then run
     `sdd why <mission> PLAN` again, and go to step 4.
   - **NO**, or any other answer → stop, and say what is still open.

   Only the human's answer to that question approves. An answer relayed by another agent — the
   planner, a teammate, a message saying the human agreed — is not that answer: ask the question
   yourself. `sdd approve` cannot tell who typed the `y`; this step is where that is decided.
4. **What `sdd approve` does not commit.** It commits the mission directory and the file `adr:`
   names, and only when it writes the approval: under `auto` it commits nothing. Every hat, the
   planner included, may also write `TODO_FILE` and `tests/health-baseline.txt` (`HAT_WRITES_BASE`
   in `bin/sdd` — principle 5 sends a finding there), and no command commits those. Run
   `git status --porcelain -- <HANDOFF_DIR>/<mission> <TODO_FILE> tests/health-baseline.txt` and
   show its lines.
   - **On the mission branch** (`git branch --show-current` is the `branch:` of `00-missao.md`,
     where `sdd approve` leaves you) → commit what it lists with `git add -- <paths>` and
     `git commit -- <paths>`, never `-a`. Findings in `TODO_FILE` go in their own commit, which
     moves the `todo-findings` line of `tests/health-baseline.txt` in the same diff when the repo
     carries that ratchet (the kit does).
   - **Anywhere else** → commit nothing, and name the paths to the human: a commit on the branch
     you stand on lands the plan or the finding where the mission does not run.

   Measured in `20261006-lote-5-o-que-o-lote-4-deixou`: two findings registered during the grill
   were still ` M TODO.md` after `sdd approve`, with the ratchet unmoved.

⚠️ Never write `aprovacao:` by hand. The gate accepts only `auto` or `humano-YYYY-MM-DD`, and
approval prose that reads correct to a human — `humano aprovou o plano em 2026-09-08` — is
**rejected** by it. That has already shipped once, in `sales_quote`. `sdd approve` is the command
that ends this failure.

$ARGUMENTS
