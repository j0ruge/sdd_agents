---
id: HLT-survivor-refused
area: HLT
title: Refuse a catalogue that left a mutant alive
persona: Mara
journey: J-health-verdict
expected: A score line whose caught differs from total turns the verdict red and writes no stamp
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

The mission's headline fix (I1). `score: 103 caught, 0 known gap(s), of 104` is the exact line main
carried between PR #12 and #13 while every gate answered green. The scenario is only settled when the
red ALSO leaves no stamp behind — a refusal that still certifies the content is the same bug wearing
the fix's clothes.
