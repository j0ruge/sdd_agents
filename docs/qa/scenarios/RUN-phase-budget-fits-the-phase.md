---
id: RUN-phase-budget-fits-the-phase
area: RUN
title: Hand each phase the damage cap its own work needs
persona: Mara
journey: J-trouble-stops-the-line
expected: The projected command line carries --max-budget-usd 40 for REVIEW, 25 for EXEC and QA, and 15 for PR and DOCS
entry_points: sdd run <mission> --dry-run
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps:
---

Readable in exactly one place: the argv `sdd run --dry-run` prints. No stub in any suite sees the
flags it was handed, so a session cannot report this and only the projection can.

Settle it on the whole case arm at once, never on one phase — a resolver that echoes the same number
for everything is indistinguishable from a working one when you read a single phase. The trade-off
to confirm while walking: raising `BUDGET_PER_PHASE_USD` must NOT raise the three phases with keys
of their own, and `config/schema.md` has to say so where the operator will look.
