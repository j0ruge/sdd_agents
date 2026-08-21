---
id: RUN-status-agrees-with-the-gate
area: RUN
title: Print the same table the gate judged
persona: Rui
journey: J-checkpoint-survives-a-formatter
expected: sdd status and the gate's refusal describe the same rows, before and after a formatter runs
entry_points: sdd status <mission>; sdd why <mission> EXEC
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps:
---

Rui's trust is fragile in one specific way: if the runner's picture of the mission disagrees once
with the disk, he stops using it to decide anything. This scenario is that trust, made checkable.

The pre-fix state is the exact shape of the distrust — `sdd status` printing `pending` in the Commit
column while the gate refuses for `invalid status`, both derived from the same file. Walk it by
reading the two outputs side by side on one formatted checkpoint, not by reading either alone.
