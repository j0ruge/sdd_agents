# 0002 — `sdd kaizen` plans headless; a "piorou" verdict stops the line

Date: 2026-08-15 · Status: accepted

## Context

The kit's mission planning phase (`sdd-planner`) is deliberately the only phase with the human in
the room. `sdd kaizen` (I13.3) also produces a mission plan — for the kit's own next
self-improvement mission — and the fork was whether that planning is another interactive session
(human present, agent assisting) or a headless one (kit plans alone, human reviews the born plan).
Milestone 2 of the roadmap is explicitly "the kit PLANS and executes; the human approves and
merges". An interactive `sdd kaizen` would leave the human doing the planning, only with support —
Milestone 2 in name but not in fact.

## Decision

Headless, through `run_phase()` like every other phase-running `claude -p` invocation (logs,
budget cap, ledger row — per the CLAUDE.md rule that a third exception to `run_phase()` should be
a phase instead). The born plan follows the same contract `sdd-planner` ships: PLAN-AUTO table
filled with evidence, and `aprovacao:` left **empty** — always, until I13.4 exists. The human
gate moves from being in the room to reviewing the finished plan and merging.

Jidoka: when the deterministic series plus the agent's own judgment yield a **"piorou"** verdict
on the previous kit change, `sdd kaizen` stops the line — it writes the verdict and escalates to
the human instead of planning the next change on top of a bad one.

## Consequences

- Milestone 2 becomes real: plan quality now depends on the agent plus the TODO.md triage, not on
  a human interview. The human review of the born plan is the compensating control.
- `run_phase()` assumes an existing mission; the kaizen session *creates* one. The implementation
  must adapt (a mission dir born at session start, or a bootstrap step) without weakening the
  run_phase contract.
- Stop-the-line is a gate behavior, so it enters the mutation catalog like any gate: sabotage the
  Jidoka and the suite must go red.
- The interactive planning phase for regular missions is untouched.
