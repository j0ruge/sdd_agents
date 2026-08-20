---
id: HLT-open-gap-refused
area: HLT
title: Keep refusing a catalogue with a known open gap
persona: Mara
journey: J-health-verdict
expected: gaps greater than zero is refused with the older, more specific 'open gap' sentence
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

Regression canary for the pre-existing message. The gap comparison runs BEFORE the caught/total one on
purpose: with a gap open, caught is always below total, so the reverse order would make this sentence
unreachable and silently delete a message the product already had.
