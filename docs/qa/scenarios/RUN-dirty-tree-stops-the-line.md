---
id: RUN-dirty-tree-stops-the-line
area: RUN
title: Escalate a red suite over an uncommitted tree instead of opening a session
persona: Rui
journey: J-trouble-stops-the-line
expected: sdd run exits 3 naming the dirty tree, and the mission journal gains no new EXEC session line
entry_points: sdd run <mission>
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: RUN-red-suite-clean-tree-still-runs
---

The settled state is checked in `.sdd/logs/<mission>/pipeline.log`, not in the terminal: one
`BLOCKED  EXEC` line and **no** new `EXEC  agent=` line. Counting session log files instead is
wrong — they are named `<PHASE>-%Y%m%d-%H%M%S.json`, so two sessions inside one second land on the
same path and the count silently stops rising.

Exit 3 and the `BLOCKED in EXEC` prefix are shared with budget exhaustion. Neither alone settles
this scenario; the discriminator is the dirty-tree sentence plus the absence of the
budget-exhaustion one.
