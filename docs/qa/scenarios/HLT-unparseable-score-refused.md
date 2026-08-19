---
id: HLT-unparseable-score-refused
area: HLT
title: Refuse a score line the parser no longer understands
persona: Mara
journey: J-health-verdict
expected: A score line that does not match the expected shape is refused, never skipped
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

The vacuity branch. Without it a sed that stopped matching would skip the whole comparison in silence,
which is the same failure class as having no score line at all — the instrument going blind while
reporting nothing wrong.
