---
id: GATE-pr-demands-stamp-when-missing
area: GATE
title: Refuse the PR gate when no stamp certifies this content
persona: Mara
journey: J-certify-mission-close
expected: gate_PR refuses in one sentence that names both the missing stamp and the command that writes it
entry_points: ./bin/sdd why <mission> PR
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

Branch point D->F of the flow, the 'no stamp' edge. What proves this scenario is not just the refusal
but the remedy inside it: the sentence must still carry `run 'sdd health'` and the clause explaining
that TEST_CMD has not run the catalogue since `4c86712`. Without that clause the operator runs the
fast suite, sees green, and concludes the gate is lying — Abandon-A of the journey.
