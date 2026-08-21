---
id: GATE-docs-alignment-colon-not-a-status
area: GATE
title: Skip the separator row when locating the Status column of the drift checklist
persona: Priya
journey: J-checkpoint-survives-a-formatter
expected: A formatter-aligned 45-docs.md with every area ✅ or n/a passes gate_DOCS
entry_points: sdd run <mission>; sdd why <mission> DOCS
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: GATE-exec-alignment-colon-not-an-increment
---

Same three-character blindness, third parser. Here the colons land in the Status **column** of the
separator row, so `:---:` reads as a pending status and the gate refuses a drift checklist with
nothing pending in it.

Worth walking next to the SQ-97 gate_DOCS bug this gate already carries scar tissue from: that one
grepped the whole file for the word TODO and failed every `45-docs.md` that named `TODO.md` — which
`sdd-docs` is required to do. Two different ways of reading a table as prose, one gate.
