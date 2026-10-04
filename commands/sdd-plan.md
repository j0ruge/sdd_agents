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

   > Este repositório não tem `.sdd/config.sh` — o kit `sdd` não foi instalado aqui.
   > Rode `sdd install && sdd-link-agents` e edite o config antes de planejar.
   > Receita: `~/repos/sdd_agents/docs/plan-only.md`

   Do not invent a `HANDOFF_DIR`, and do not create the config yourself: `sdd install` derives
   `DEFAULT_BRANCH` and `TEST_CMD` from the repo, and a hand-written stub would carry neither.

2. From that config, read `HANDOFF_DIR`, `OUTPUT_LANG`, `DEFAULT_BRANCH`, `TODO_FILE` and
   `JIRA_ENABLED`. Report them back in one line, so the user sees what the session is about to
   honour.

3. List the four templates you will write from, by absolute path, and confirm each one exists:

   - `~/repos/sdd_agents/templates/missao.md` → `00-missao.md`
   - `~/repos/sdd_agents/templates/plano.md` → `01-plano.md`
   - `~/repos/sdd_agents/templates/checkpoint.md` → `checkpoint.md`
   - `~/repos/sdd_agents/templates/checkpoint-notas.md` → `checkpoint-notas.md` (optional)

   A missing template is a stop, not a warning — writing the artifact from memory is the exact
   failure this step prevents.

## Then

Delegate to the `sdd-planner` subagent, handing it: the mission topic the user gave (ask, if the
command came with no argument), the config values from step 2, and the absolute template paths from
step 3 — stated as *the* templates to start from, never as examples.

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
  grill). Relay anything else the human says mid-grill the same way.
- **Long work between two questions:** before it — prototyping fixes with parallel subagents, for
  instance — the planner first hands back a ONE-line notice of what it is about to do and how long
  it expects that to take; the relay shows it to the human, and only then does the planner start.
  Measured in the grill of `20261003-lote-3-a-catraca-desce`: the planner went ~45 min without a
  signal between the 7th and the 8th question, and the human asked whether it was still working.
- **Approval.** A message from an agent is never the human's approval: `aprovacao:` closes through
  the PLAN-AUTO gate or through `sdd approve`.

## When the artifacts exist

Say this, and stop:

- Validate the gate without spending a session: `sdd why <mission> PLAN`
- Approve: `sdd approve <mission>`

⚠️ Never write `aprovacao:` by hand. The gate accepts only `auto` or `humano-YYYY-MM-DD`, and
approval prose that reads correct to a human — `humano aprovou o plano em 2026-09-08` — is
**rejected** by it. That has already shipped once, in `sales_quote`. `sdd approve` is the command
that ends this failure.

$ARGUMENTS
