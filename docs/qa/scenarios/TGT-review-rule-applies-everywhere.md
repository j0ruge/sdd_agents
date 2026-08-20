---
id: TGT-review-rule-applies-everywhere
area: TGT
title: Have the review rule apply in a target repo too
persona: Priya
journey: J-target-repo-ships
expected: A target repo's review round with a placeholder rationale is refused, exactly as the kit's would be
entry_points: sdd run <mission> (in a repo that is not the kit)
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

The other side of the canary, and the reason it is a separate scenario. The stamp rule must NOT cross
into a target repo; the rationale rule MUST. Walking only one of them cannot tell 'correctly scoped'
from 'refuses everything' or 'refuses nothing' — the pair is the assertion.
