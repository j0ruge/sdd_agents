---
id: RUN-session-log-survives-a-second-session
area: RUN
title: Keep each session's transcript readable when a phase runs twice
persona: Rui
journey: J-trouble-stops-the-line
expected: Two sessions of one phase leave two readable transcripts, and the journal's log= path resolves to the session it names
entry_points: sdd run <mission> --phase REVIEW; .sdd/logs/<mission>/pipeline.log
qa_status: fail
bug_ids: BUG-20260821-session-log-overwritten-in-the-same-second
fix_status: pending
retest_status:
fix_commits:
evidence: ../reports/2026-08-21-missao-porteira.md
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps:
---

Minted mid-walk, not planned: the Interrupt Tour of `CH-a-phase-died-and-left-the-tree-dirty` ran a
phase twice inside one second and the first transcript was gone. The scenarios that session was
walking all held — a session opened when it should, the ceiling refused when it should — and this
sat underneath them, which is what a tour is for.

Not a regression from this branch. `run_phase` has named log files `<PHASE>-%Y%m%d-%H%M%S` since
long before it; the branch only made it easy to hit, because a phase that escalates or retries is
now a phase that runs twice in quick succession on purpose.

The verdict is `fail` on its own observable, and it does **not** invalidate the rows walked beside
it: those were settled against `pipeline.log`, which is append-only and survived the collision
intact. That the journal survived while the transcripts did not is also what makes the loss
provable rather than merely suspected.
