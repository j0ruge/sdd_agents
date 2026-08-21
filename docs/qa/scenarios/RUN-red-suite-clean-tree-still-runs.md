---
id: RUN-red-suite-clean-tree-still-runs
area: RUN
title: Open a session for a red suite when the tree is clean
persona: Rui
journey: J-trouble-stops-the-line
expected: The same red suite over a committed tree opens an EXEC session, exactly as before the change
entry_points: sdd run <mission>
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: RUN-dirty-tree-stops-the-line
---

The half that keeps the other half honest, and it is not optional: a runner that escalated on every
red suite would settle `RUN-dirty-tree-stops-the-line` while ending the line on the most common
situation in the product — a suite that is red because there is work to do.

Walk the two one `echo >> file` apart, on the same fixture, in the same session. Comparing the two
outcomes to each other is the assertion; comparing either to a literal is not.
