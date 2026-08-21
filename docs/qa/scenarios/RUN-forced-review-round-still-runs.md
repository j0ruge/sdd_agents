---
id: RUN-forced-review-round-still-runs
area: RUN
title: Run the round a human explicitly asked for, past the ceiling
persona: Mara
journey: J-trouble-stops-the-line
expected: sdd run --phase REVIEW opens a session even when the rounds on disk are at or above the ceiling
entry_points: sdd run <mission> --phase REVIEW
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: RUN-review-rounds-counted-in-total
---

The escape hatch, and the reason it has to exist: the round that unblocks a blown mission is a round
somebody asks for with their eyes on it. A ceiling that also refused the forced path would leave no
way to finish the mission except editing artifacts by hand.

Also the anti-vacuity half of the pair above — without it, a runner that refused every derived
REVIEW would settle `RUN-review-rounds-counted-in-total` while making the phase unreachable.
