---
id: GATE-ticket-branch-mismatch-refused
area: GATE
title: Refuse a mission artifact declaring a different branch than the ticket created
persona: Priya
journey: J-ticket-opens-and-branch-lands
expected: 00-missao.md naming another branch is refused, with both names quoted in the reason
entry_points: sdd run <mission>; sdd why <mission> TICKET
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: GATE-ticket-branch-must-reach-mission
---

The same defect wearing a filled-in field, and the more dangerous of the two: a placeholder at least
looks unfinished, while a filled-in wrong name looks done. The runner honours `00-missao.md`, so the
mission would run — correctly, quietly — on a branch the ticket never created.
