---
id: HLT-stamp-window-refused
area: HLT
title: Refuse to stamp a tree that moved while the catalogue ran
persona: Rui
journey: J-health-verdict
expected: A commit landing during the 20-50 minute run means nothing is stamped and the operator is told their own commit is why
entry_points: ./bin/sdd health
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

The widest window in the kit, opened by the same phase that commits. The scenario's non-obvious half is
the sentence: an operator who watched a green catalogue scroll past and then finds gate_PR still asking
needs to be told the cause, or they will re-run and hit it again.
