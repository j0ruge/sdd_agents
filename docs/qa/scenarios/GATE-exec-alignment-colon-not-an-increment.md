---
id: GATE-exec-alignment-colon-not-an-increment
area: GATE
title: Skip a separator row that carries alignment colons
persona: Priya
journey: J-checkpoint-survives-a-formatter
expected: A checkpoint whose separator reads |:---|:---:| derives the same phase as one with plain dashes
entry_points: sdd phase <mission>; sdd run <mission>
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: GATE-docs-alignment-colon-not-a-status; GATE-review-alignment-colon-not-a-criterion
---

Read as data, the separator becomes an increment whose id is `:---` and whose status is `:---:` —
outside the enum — so `gate_EXEC` refuses a checkpoint in which every increment is done.

Nothing in the kit writes these colons, which is why no fixture carried them for fourteen missions.
An adopter's formatter writes them the first time it runs, so the trigger is somebody else's tooling
and the finder is the first adopter, not the maintainer.
