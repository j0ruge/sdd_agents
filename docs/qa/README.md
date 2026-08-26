# QA living docs — `sdd_agents`

One committed tree, appended to by every QA cycle. It is the cross-cycle memory that the
per-mission `docs/handoffs/<mission>/30-handoff-qa.md` never had: handoffs record what one
mission's QA phase did, this tree records what the product promises its users and what state each
promise is in.

Planned 2026-08-19 on branch `fix/fecho-que-nao-mente`. No legacy QA artifacts were adopted —
nothing outside `docs/handoffs/` held QA state before this tree.

> ✅ **The question this file used to open with is answered.** It warned that committing the tree
> changed `gate_QA`'s behaviour and contradicted a written contract in `docs/pipeline.md`. The
> contract was changed to match, in `6dea0d5`: a `docs/qa/` tree that exists "is read and
> complemented, never removed", and the no-interface path still asks for no dated report from it.
> The tree is committed and the coupling below is live, not hypothetical.

## Cycles

| Cycle | Branch | Tier | What it planned |
|---|---|---|---|
| 2026-08-19 | `fix/fecho-que-nao-mente` | Targeted | Bootstrap: 5 journeys, 7 charters, 20 scenarios, 5 bugs |
| 2026-08-21 | `20260820-missao-porteira` | Targeted | 3 journeys added, 3 updated, 6 charters, 24 scenarios; no new bugs |

## The product, and who its users are

The kit has **no interface**: `E2E_CMD=""` in `.sdd/config.sh`, no `APP_URL`, no service, no port.
The product is a CLI (`bin/sdd`) plus markdown agents, and the entry points are shell verbs.

"User" therefore means one of three real people or one machine, all defined in
[`personas.md`](personas.md):

- the maintainer driving a mission on the kit itself;
- an engineer installing the kit into their own repo;
- the operator coming back after a session died;
- **the headless phase session** — an autonomous `claude -p` run that boots with no memory of any
  previous conversation and acts only on what `sdd why` and the handoff tell it. It is not a human,
  and it is on the persona list anyway, because it is the reader that consumes gate messages most
  often and the one that has burned real money when a message did not name the command to run.

## Language

This tree is **English**, like the rest of the kit's surface (`CLAUDE.md` § Idioma: `bin/sdd`,
`agents/`, `docs/`, `README.md`, `config/`, `tests/`). It is not a mission artifact, so it does not
follow `OUTPUT_LANG=pt-BR` the way `docs/handoffs/`, `checkpoint.md`, commit messages and PR bodies
do. Quotes lifted verbatim from a pt-BR artifact stay in pt-BR — that is data, not prose.

`tests/check-lang.sh` does **not** scan this path: its surface is an explicit file list
(`docs/pipeline.md`, `docs/failure-modes.md`, `docs/adr/*.md`), not `docs/**`. Nothing enforces the
choice above; it is a convention, recorded here so the next cycle does not re-decide it.

## Area codes

Scenario ids are `<AREA>-<slug>`. The closed set:

| Code  | Area |
|-------|------|
| `HLT` | `sdd health` — the kit's own sensor: suite, mutation catalogue, drift, the mutation stamp |
| `GATE`| Phase-gate verdicts and their explanations (`gate_REVIEW`, `gate_PR`, `sdd why`) |
| `SUI` | The test suite surface — `tests/run-all.sh`, its modes and its output contract |
| `RUN` | Mission drive and operator navigation (`sdd run`, `sdd status`, `sdd phase`, `sdd approve`) |
| `TGT` | Behaviour inside a target repo that is **not** the kit |

Adding an area updates this table first.

## Entry points

There is no dev server to start. Every journey begins at a shell prompt:

```bash
./bin/sdd help                     # verb list
./bin/sdd health                   # kit sensor — runs the mutation catalogue, ~20-50 min
./bin/sdd status <mission>         # where a mission stands, gate by gate
./bin/sdd phase <mission>          # the current phase only (for scripts)
./bin/sdd why <mission> [PHASE]    # why that phase's gate did not pass
./bin/sdd run <mission> --dry-run  # boot prompts only; the gates still run TEST_CMD for real
tests/run-all.sh                   # the TEST_CMD every gate runs (~1m50s)
tests/run-all.sh --list            # step names only — runs NOTHING (see the SUI scenarios)
tests/run-all.sh --with-mutation   # the opt-in mutation catalogue
```

Two things to know before walking anything:

1. **`sdd health` takes 20 to 50 minutes** and it is the only place the mutation catalogue runs.
   A charter that includes it needs the 90-minute box, or it must start the run and walk something
   else while it goes.
2. **The mutation stamp is content-keyed** on `bin/ tests/ templates/ config/`. Any commit touching
   those four invalidates it and `gate_PR` starts refusing again. `CLAUDE.md`, `docs/` and `TODO.md`
   do not. Practical rule: run `sdd health` *after* the last code commit of a mission.

## Evidence policy

Default, per the skill: `evidence/` is gitignored and `state.csv` is a generated view, never
committed. Reports in `reports/` are the durable record and reference evidence by path. Command
transcripts belong inline in the report — they are small; only catalogue logs (tens of MB of
sandbox output) stay outside the tree and get indexed by path.

## Relationship to the `sdd` pipeline

Three facts, all measured against `bin/sdd` at `9f84cbc` rather than assumed.

**1. This project routes AROUND the two QA skills, by design.** `qa_substep()` (`bin/sdd:801`)
sends a project with no interface straight to `QA:close` — the `sdd-qa` agent — and never opens a
`/qa-report` or `/qa-execution` session. `docs/pipeline.md:113` states the reasoning: bootstrapping
browser journeys in a project with no browser is the paperwork `qa: skipped` exists to avoid. This
tree therefore exists because a human asked for it, not because the pipeline produced it, and the
phase's gate artifact remains `30-handoff-qa.md` with its `gate:` field filled.

**2. The runner DOES read one directory of this tree, and it is a gate.** `gate_QA` Anchor 3
(in `bin/sdd`, the `Anchor 3` block of `gate_QA` — anchored on the name, because the line numbers
here went stale once already and pointed at `gate_TICKET`) counts files under
`<QA_DOCS_PATH>/bugs/` matching `- **Status:** open` and refuses the phase while any of them are
**agent-closable** — in **both** the interface and the no-interface case. A bug filed here is not
documentation: it holds the mission's QA gate shut until it moves to `fixed`+verified, `wont-fix`
or `invalid`. That is the QA⇄EXEC fix loop working as documented (`docs/pipeline.md`, "Passes
when"), and it is the coupling to weigh before filing.

Since `20260826-o-laco-da-qa` a second field of the same file decides whether an `open` bug is one
of those: `- **Closable by:** agent <!-- agent | human -->`. `agent` blocks (for that bug the
`F<n>` cycle closes); `human` does not; **absent blocks**, which is the fail-safe every bug file
older than the field relies on. The genre is read from that FIELD — not from anywhere the words
appear in the body — and matched as a whole lowercase word, so `humano` and `Human` read as absent.
Marking it is the `sdd-qa` agent's duty (`agents/sdd-qa.md` § 5.1) and the **only** line of a bug
file an agent may write: `Status:` is still the skills', which is exactly why the genre had to
exist. Before it, a bug waiting on a product decision held the phase with no path out — 7 of the 12
QA sessions of `20260825-frete-cif-fob`, US$ 73,32.

`gate_QA`'s other two anchors (a `closed` report, no `Pending` matrix row) are reached **only** when
`E2E_CMD` or `APP_URL` is set. Neither is set here, so `reports/` is unread by the runner — the
dated reports in it are for humans and for the next cycle, not for a gate.

**3. An autonomous `sdd-qa` session already rejected this tree once**, on 2026-08-19 at 16:51,
and recorded why in commit `9f84cbc` — it appeared untracked mid-phase, and the agent read fact 1
and fact 2 the same way this file did. **That is settled**: `docs/pipeline.md` was rewritten in
`6dea0d5` to say the opposite in as many words — *"a tree that is there is read and complemented,
never removed"* — and it cites the deletion by hash so the next session meets the reasoning rather
than re-deriving it. The three facts above stay because they are still the operating conditions,
not because the question is still open.
