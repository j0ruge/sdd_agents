---
id: GATE-exec-escaped-pipe-keeps-status
area: GATE
title: Read the Status column of a Check cell carrying a GFM-escaped pipe
persona: Sessão
journey: J-checkpoint-survives-a-formatter
expected: A checkpoint whose Check cell contains \| derives the same phase as the identical checkpoint without it
entry_points: sdd phase <mission>; sdd run <mission>; sdd why <mission> EXEC
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: GATE-review-escaped-pipe-in-rationale
---

Differential by construction: the two answers compared to each other, one `sed` apart. A literal
expectation would pass on a runner that refused both.

The symptom is what makes it expensive rather than annoying. The columns shift one left, so Status
is read from inside the command and Commit reads `pending`; the gate then refuses with
`invalid status`, naming a status the author never typed, while `sdd status` prints something that
looks healthy next to it. The operator goes hunting for an increment defect that does not exist.

The parity rule matters and is easy to get wrong: `\\` is how GFM spells a literal backslash, so a
cell ending in one sits against a REAL delimiter. An odd run of trailing backslashes escapes the
pipe; an even one does not. `gate_REVIEW` learned this first (`53586c5`); the two implementations
are deliberately duplicated so the mutation catalogue can anchor each separately.
