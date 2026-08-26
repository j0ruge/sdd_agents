# 0006 — The QA anchor reads the bug's genre, and a blocked handoff stops the line at once

Date: 2026-08-26 · Status: accepted

## Context

A gate is verifiable by command or it is not a gate — that is principle 1 of `CLAUDE.md`, and it
was never wrong. It was **incomplete**. `gate_QA`'s Anchor 3 was verifiable by command, deterministic,
and cheap; it was also **unsatisfiable by anybody the pipeline can dispatch**, and the pipeline paid
real money to discover it.

**Measured on 2026-08-26**, mission `20260825-frete-cif-fob` in `sales_quote` — the kit's first real
target-repo mission:

| | sessions | cost |
|---|---|---|
| the QA phase alone | 12 | US$ 73,32 |
| EXEC + REVIEW + DOCS + PR + TICKET together | 11 | US$ 71,56 |
| **the whole mission** | **23** | **US$ 144,88** |

**Seven of those twelve QA sessions were in a loop none of them could win.** The loop had two
gears, and neither was a coding bug. Both were contracts that do not close.

### Gear 1: the anchor demanded a line no agent may write

Anchor 3 counted every file under `<QA_DOCS_PATH>/bugs/` carrying `- **Status:** open`, over the
whole registry, unrelated to the current mission, and refused the phase while the count was above
zero. Its stated reason promised the way out: *"they become fix increments (QA⇄EXEC loop)"*.

That promise is false for a whole class of bug, and the ownership table says why:

| who | may write `Status:`? | evidence |
|---|---|---|
| `sdd-executor` | does not know the registry exists | `grep -c 'qa/bugs\|Status:' agents/sdd-executor.md` → **1**, and that hit is line 30, about `checkpoint.md` |
| `sdd-qa` | forbidden by a non-negotiable rule | `agents/sdd-qa.md` — *"the `docs/qa/` tree belongs to the skills — you read and complement, you do not rewrite"* |
| the `qa-report` / `qa-execution` skills | yes, they own it | same file, the sub-step table |

For a **fixable** bug the cycle closes: QA finds it, an `F<n>` increment fixes it, the skill verifies
and writes `verified`. For a bug whose fix is a **product decision** there was no path at all — and
the anchor blocked the phase for it just the same. The `§ 5` of `agents/sdd-qa.md` stated that such
an item *"does not block the pipeline"*. It was false, and Anchor 3 was the proof.

The four bugs that unblocked that mission were closed `wont-fix` **by the human**, and two of them
were P1 (Data-Loss and Trust-Damage).

### Gear 2: "it moved the disk" was read as progress

`cmd_run`'s loop samples a state fingerprint before the gate; a session that fails the gate **and
commits** makes the runner carry on and open another lap. Only **two** consecutive sessions that
move nothing fire `BLOCKED … no-progress`, the one event that summons a human.

In a phase whose gate nobody can satisfy, every honest finding becomes a commit, and **every commit
buys the next lap**. The seven rounds recorded exactly that: the "do not commit" instruction of
iterations 3, 4 and 6 was disobeyed every time — **rightly**, because each of those sessions found
something real. The sessions were never the defect.

Meanwhile the token for stopping already existed with the right meaning: `blocked` in a handoff's
frontmatter means *"the line stopped; the runner returns 3 and a human has to act"*. The gate
already refused on it. What was missing was escalating on it instead of spinning around it — so a
phase nobody can satisfy was charged one extra session to prove its own unsatisfiability twice.

## Decision

**Two parts, decided together on 2026-08-26 with the human present, because either alone leaves the
loop turning.**

### 1. Anchor 3 distinguishes the bug's **genre**

A bug file declares who may close it, in a field of its own:

```
- **Closable by:** agent <!-- agent | human -->
```

`agent` blocks, exactly as before, because for that bug the `F<n>` cycle does close. `human` does
not block. **Absent blocks** — the fail-safe, and the reason is not caution for its own sake: every
bug file written before the field existed lacks it, so a permissive default would switch Anchor 3
off for a whole legacy registry in one step.

Marking the genre becomes the `sdd-qa` agent's **duty**, and `human` requires provenance cited as
`file:line` — the same ruler the previous mission used to move two bugs and refuse to move four.
**No agent gains permission to write `Status:`.** The genre field is the one line of a bug file that
is the agent's; the status enum stays the skills'. That rule is not an obstacle to this decision, it
is what makes it necessary.

### 2. A handoff declaring `status: blocked` escalates on the first session

When a gate refuses **because the phase's own handoff declares `blocked`**, the runner returns 3
immediately, writes the ledger row and the `pipeline.log` line, and names for the human what has to
be decided. It no longer routes that refusal through the fingerprint heuristic, which was built to
answer a different question ("did this session do anything?") and cannot answer this one.

The ledger's `kind` enum gains a fifth value, `handoff-blocked`, filed as a deliberate Jidoka
alongside `increment-blocked` rather than as friction — the line stopping on a written declaration
is the system working.

## Consequences

- **The `§ 5` promise becomes true.** The documentation was right and the code was wrong; this fixes
  the code rather than downgrading the promise to fit it. Every document that stated the old
  condition was corrected in the same diff — `docs/pipeline.md`, `docs/qa/README.md`,
  `agents/sdd-qa.md`.
- **A bug marked `Closable by: human` stays `open`, stays in the registry, and stays in the PR.**
  `human` says *"no agent in this pipeline can close this"*, never *"this is closed"*. The decision
  still reaches a human — through the handoff's "Decisions for a Human" section and the PR — it just
  stops holding a phase shut on the way there.
- **Every looseness in the genre match fails OPEN**, which is new: Anchor 3's other conditions can
  only make a bug block. Three separate hardenings were needed, each with a mutant of its own,
  because they rot independently — the genre is read from the FIELD (a `grep -q` matched any line of
  the file, so a bug that merely QUOTED the human line stopped blocking), matched as a WHOLE
  lowercase word (`humano`, the pt-BR spelling in a repo declaring `OUTPUT_LANG=pt-BR`, read as
  `human`), and taken from the first field-shaped line **outside a fenced block**.
  ⚠️ One residue is declared rather than hidden: an **unfenced** quote parked above the real field
  still reads as the genre. It is in `TODO.md` with its direction, because a declared fail-open is
  still a fail-open.
- **The escalation has ONE definition and TWO doors** in `cmd_run`'s loop — the first pass and the
  inline retry — the shape `kit_guard_check` already has, for the same reason: the body must not
  drift between call sites, but where the doors sit is a property of the loop. The second door is
  not symmetry: without it the marker outlived the **lap** rather than the gate, and the escalation
  fired for EXEC over a handoff that said `done`. Whoever adds a third door owes it a probe.
- **The escalation sits ABOVE the `--max-phases` ceiling**, with its two sibling Jidokas. Below it,
  `sdd run <mission> --max-phases 1` on a blocked handoff paid for a session and returned **0**, with
  no ledger row and no journal line: the pre-fix loop wearing a green exit code, for ever, for any
  operator or CI wrapper pacing the pipeline one phase at a time.
- **`sdd retry` still returns 3 without writing an escalation row.** Older than this decision and
  true of every escalation, not just the new one. In `TODO.md`, with the reproduction.

## Alternatives discarded

**(A) Count only the bugs of the current mission.** Rejected because it changes the promise to fit
the code. The registry-wide scope is what makes a bug filed in mission N visible to mission N+1, and
narrowing it would let a real, agent-closable defect age out of sight — trading a loop for silent
debt. The defect was never the scope; it was that one class of bug had no exit at any scope.

**(B) Let `sdd-qa` apply `wont-fix` itself.** Rejected on evidence from the very mission that
motivated this record: the four `wont-fix` calls that unblocked it were the human's, and **two were
P1** — Data-Loss and Trust-Damage. An agent holding that power would have closed all four alone, in
a headless session, with nobody reading the decision. It would also break the ownership rule that
makes the `docs/qa/` tree trustworthy at all. The genre field gives the agent exactly the authority
it can be trusted with — *"I cannot close this"* — and none of the authority it cannot: *"this need
not be fixed"*.

**A permissive default for a missing genre.** Rejected as a one-step switch-off of Anchor 3 across
every bug file older than the field. The fail-safe direction costs a lap when somebody misspells the
value; the permissive direction costs the anchor.

**Moving where `cmd_run` samples the fingerprint.** Rejected without being attempted: the sampling
point is documented in the code as deliberate, and moving it breaks the waste metric in silence. The
escalation is a new branch **before** the fingerprint test, reading a marker — never a reordering.

**Grepping `GATE_WHY` for the word "blocked".** Rejected because `GATE_WHY` is prose: every gate
spells its refusal its own way, and `gate_EXEC`'s Jidoka line carries the same word. An early exit
anchored on a substring of prose would escalate runs nobody asked it to. The gate publishes a
marker instead.

**Teaching `sdd-executor` about the registry.** Rejected as unnecessary under this decision, not as
wrong: a human-genre bug stops blocking, and an agent-genre bug closes through the `F<n>` cycle that
already exists. Nothing is left for the executor to learn.
