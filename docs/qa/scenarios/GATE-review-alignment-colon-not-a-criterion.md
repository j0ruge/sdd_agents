---
id: GATE-review-alignment-colon-not-a-criterion
area: GATE
title: Skip an alignment-colon separator instead of grading it
persona: Mara
journey: J-review-round-seal
expected: An all-A round whose separator reads |:---|:---:| passes, and no reason names ':' as a criterion
entry_points: sdd run <mission>; sdd why <mission> REVIEW
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: GATE-exec-alignment-colon-not-an-increment
---

The costliest of the three faces of this bug, because REVIEW is the most expensive phase and this
one does not stop the line — it loops it. The separator becomes a criterion named `:` graded `---`,
the round is refused, and the phase spends up to `REVIEW_MAX_ITER` sessions on a `GATE_WHY` that
names no criterion anybody wrote.

Settle both halves: the round passes, AND the reason (when there is one) never quotes the separator.
Absence is the discriminator here — a gate that refused for a different reason would still be wrong
in the same way.
