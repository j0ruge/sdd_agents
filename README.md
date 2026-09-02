# sdd_agents

A kit of **autonomous development agents**: from an approved plan to an **open PR**, with no human intervention in between.

The human takes part in two things: **planning** and **merging**. Everything else (TDD execution, QA, review, documentation, PR) runs in headless sessions chained by the `bin/sdd` runner.

## How it works (30 seconds)

```
[you] ──approve plan──▶ sdd-planner ──▶ bin/sdd run <mission>
                                             │
     TICKET → EXEC → QA ⇄ EXEC → REVIEW ⇄ EXEC → DOCS → PR
                                             │
                                        [you] ──▶ merge
```

Every phase is at least one **fresh session** of `claude -p` (context-overflow protection) — QA is
up to three, one per sub-step (in a project with no interface, just one). The state lives on disk,
in `docs/handoffs/<mission>/` of the target repo. There is no state file: the runner **derives**
the current phase from the artifacts and runs the first one whose gate is not satisfied — if it
died halfway, `sdd run` again resumes at the exact point.

**Success is never the model's answer.** Every gate is re-evaluated by the runner (it runs the
tests, greps the checkpoint, reads the `git log`). A label is not an artifact.

## Installing into a target repo

```bash
# git clone https://github.com/j0ruge/sdd_agents.git   # PRIVATE repository
export PATH="$HOME/repos/sdd_agents/bin:$PATH"     # or ln -s .../bin/sdd ~/.local/bin/sdd

cd ~/repos/my-project
sdd install            # creates .sdd/config.sh and copies .claude/agents/sdd-*.md
$EDITOR .sdd/config.sh # set TEST_CMD, E2E_CMD, APP_URL, OUTPUT_LANG, JIRA_ENABLED...
sdd preflight          # environment sensor: claude, gh, GNU userland, git 2.31+, agent-browser, clean tree
```

`sdd install` is idempotent: running it again shows the agent diff instead of overwriting.
`sdd preflight` compares the installed copies with the kit source **byte for byte** and fails on a
stale one: the harness loads `.claude/agents/`, so a corrected source proves nothing on its own.

⚠️ `sdd preflight` fires a **real headless session** (capped at US$ 1) to prove the phase sessions
can actually execute a command — that is what makes it valuable, and what makes it cost money.
Do not run it in a loop.

The kit is English. The **artifacts** of a mission — handoffs, checkpoint, commit messages, PR
body — are written in whatever the target repo declares in `OUTPUT_LANG`; leave it empty and the
runner says nothing about language, and each session follows whatever the existing artifacts use.

## Usage

```bash
sdd approve <mission>        # show the plan and, on an explicit y, write the human approval and commit it
sdd run <mission>            # run from the first unsatisfied gate through to the PR
sdd status <mission>         # where it stands, what is missing, why it stalled
sdd why <mission> [PHASE]    # why that phase's gate did not pass — start any diagnosis here
sdd phase <mission>          # print only the current phase (or DONE) — for scripts
sdd retry <mission>          # retry the current phase with a fresh session
sdd close <mission>          # post-merge: close the JIRA issue
sdd health                   # KIT sensor (≠ preflight, which is about the target's environment)
sdd autonomy                 # what the sessions did per kit version (advanced · churned · idle, waste), for THIS repo,
                             #   from the global ledger (~/.sdd/autonomy-log.jsonl)
sdd autonomy --all-repos     # ...for EVERY repo on this machine (the cross-project question; never the default)
sdd autonomy --by-mission    # ...per mission: the same outcomes, launch(es) (distinct run_id — the intervention
                             #   count), reopened phases, the checkpoint's intervention notes, and the mission cost
sdd kaizen                   # judge the previous kit change and plan the next kit mission (kit repo only);
                             #   it reads EVERY repo (ADR 0005) — --all-repos is accepted and is a no-op here
sdd kaizen --series          # the deterministic series (JSON) the judge cites, on its own, with the
                             #   composition of the slice it read: how many missions came from which repo

sdd run <mission> --dry-run         # project the whole pipeline without spending tokens
sdd run <mission> --phase EXEC      # force one specific phase
sdd run <mission> --max-phases 2    # stop after N phases
```

`sdd approve <mission>` is the human gate with a command instead of a hand edit. It prints what you
are about to approve — the title, the PLAN-AUTO evidence, the increments, the open questions —
asks `[y/N]`, and only on an explicit yes writes `aprovacao: humano-<date>` and commits that one
file. It never opens a session: approving is the one decision in the pipeline that has to come from
outside it. On a plan born of `sdd kaizen` it is the **only** way through the gate — `auto` is
refused there, because nobody was in the room
([why](docs/pipeline.md#plan--the-only-one-the-runner-does-not-execute)).

`sdd run` and `sdd retry` put you on the branch the plan declares (`branch:` in `00-missao.md`)
before the first gate — checking it out, or cutting it from where you stand. A `<…>` placeholder or
an empty value means "stay here". What happens when git refuses, and why the field is not
decorative, is in [`docs/pipeline.md`](docs/pipeline.md#the-missions-branch).

`sdd health` answers *"does the kit still measure what it claims to?"* — it runs the suite,
requires a **100% mutation score** (both numbers of the `score:` line compared, not just the gap
count — a catalogue with one live survivor used to print `ok`), refuses a catalogue too small to
have measured anything, refuses a `TEST_CMD` carrying `--list` (a command that exits 0 having run
nothing would pass every gate instantly), demands one mutation per gate, and reports drift between
`load_config()` and `config/schema.md`, a command missing from `--help`, a variable with a default
that is never read, and a fixture that diverged from the skill it imitates. It also freezes **how
many open findings `TODO.md` carries**, as `todo-findings <N>`, so the backlog cannot grow in
silence: growing stays allowed, growing undeclared does not. Known debt lives frozen in
`tests/health-baseline.txt` — almost every line owned by the `TODO.md` entry that will pay it off,
and one, the count itself, owned by the file: a new finding fails, and so does a baseline line
that stopped being a finding. It spends no paid session and does not need `.sdd/config.sh`.

**In the kit repo it is also a gate, not only a report.** Since the catalogue became opt-in it had
no automatic owner, and the base branch once carried a live survivor for days because nobody typed
the command. So a green run now **stamps** `.sdd/logs/mutation-stamp` with the content of
`bin/ tests/ templates/ config/`, and the `PR` gate refuses while no stamp matches that content:
`no green mutation catalogue for this content — run 'sdd health'`. The gate never runs the
catalogue itself — asking a gate to hold the tree for twenty minutes is what made a phase
unsatisfiable once. The requirement exists only where `tests/check-mutation.sh` does, so a target
repo sees none of it. Run it **after the last code commit**: editing docs does not invalidate the
stamp, editing `bin/ tests/ templates/ config/` does. Design and discarded alternatives in
[ADR 0004](docs/adr/0004-mutation-catalogue-owner-stamp-not-ci.md); the way out of a refusal in
[`docs/failure-modes.md`](docs/failure-modes.md).

Every one of those checks **says its verdict out loud and the run carries on** — including the one
case the command exists for, a red suite. It did not always: a bare `out="$(cmd)"` under
`set -euo pipefail` killed the process at the assignment, so `sdd health` answered a red suite with
one line of header and rc 1, and the four checks after it never ran. What keeps the class from
coming back is the `guard:` rule of `tests/check-health.sh`, which enumerates the whole region
instead of probing site by site — the reasoning is in that file's header.

`--dry-run` answers *"what happens if I run this?"*: it prints **every** phase the mission would
go through from today's state — in order, each with its agent, model and boot prompt — without
opening a single session. It projects the **current** state, it does not simulate the future; the
details, and what it does (and does not) touch on disk, are in
[`docs/pipeline.md`](docs/pipeline.md#dry-run--the-projection).

A mission is born in planning (`sdd-planner`, interactive, with you present) and is identified by
the directory `docs/handoffs/<YYYYMMDD>-<slug>/`.

## Documentation

| Where | What is in it |
|---|---|
| [`docs/pipeline.md`](docs/pipeline.md) | state machine, gates per phase, what each agent reads and writes |
| [`docs/failure-modes.md`](docs/failure-modes.md) | what breaks, how the kit reacts, how to get unstuck |
| [`docs/adr/`](docs/adr/) | the architectural decisions taken, and the alternatives discarded with them |
| [`config/schema.md`](config/schema.md) | every `.sdd/config.sh` key, with its default and why |
| [`CONTEXT.md`](CONTEXT.md) | glossary of the kit's own vocabulary, and the decisions resolved in interview |
| [`agents/`](agents/) | the 6 agents (open markdown — portable to other harnesses) |
| [`templates/`](templates/) | mission, plan, handoff, checkpoint, review, PR body |
| [`CLAUDE.md`](CLAUDE.md) | conventions for whoever (human or agent) works on **this** kit |
| [`KAIZEN_LOG.md`](KAIZEN_LOG.md) | history of improvements with a measured before/after |
| [`TODO.md`](TODO.md) | findings about the kit itself, recorded by any agent |

## The 6 agents

| Agent | Phase | Model | Delivers |
|---|---|---|---|
| `sdd-planner` | plan | Fable (interactive) | `00-missao.md`, `01-plano.md`, `checkpoint.md` |
| `sdd-executor` | TDD execution, 1 session per increment | Opus | commits + updated `checkpoint.md` |
| `sdd-qa` | closes the QA cycle (sub-step `QA:close`) | Opus | e2e specs, fix increments, `30-handoff-qa.md` |
| `sdd-reviewer` | code review until Grade A, read-only over the code | Opus | `40-review-r<N>.md` + `R<n>` increments |
| `sdd-docs` | living documentation | Opus | target docs synced + `45-docs.md` |
| `sdd-publisher` | TICKET (opens the issue) and PR (push + opens the PR) | Sonnet | `10-ticket.md`, open PR + `50-pr.md` |

The `docs/qa/` tree is **not** delivered by `sdd-qa`: it is written by the `qa-report` and
`qa-execution` skills, in the `QA:plan` and `QA:exec` sub-steps — two sessions of their own, with
no kit agent.

## Requirements

authenticated `claude` CLI · authenticated `gh` · `bash` 4+ · `git` · `uuidgen` (util-linux) ·
`jq` · `agent-browser` (only for the QA phase of projects with a UI).

**Linux, or a macOS with the GNU userland in front.** The kit calls `md5sum`, `date -Iseconds`
and `sort -V`, and its own suite calls `sed -i` with no argument and `grep -P` — the BSD tools
macOS ships reject every one of them. On macOS: `brew install bash coreutils gnu-sed grep`, and
put the `gnubin` directories first in `PATH` (brew names them `gmd5sum`/`gdate`; the kit calls
`md5sum`/`date`). `sdd preflight` measures this instead of trusting it.
