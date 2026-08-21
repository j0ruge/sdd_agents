---
id: RUN-review-rounds-counted-in-total
area: RUN
title: Refuse review round N+1 across a fresh sdd run, not just within one
persona: Rui
journey: J-trouble-stops-the-line
expected: With REVIEW_MAX_ITER rounds already on disk a fresh sdd run exits 3 without opening a REVIEW session
entry_points: sdd run <mission>
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: RUN-forced-review-round-still-runs
---

The count comes from the `40-review-r<N>.md` files, read through the same `latest_matching` the
REVIEW gate uses — `-V` ordering, so `r10` comes after `r3`. Two readers, one ordering: if they ever
disagree about which round is latest, the ceiling and the gate are judging different rounds.

Walk it with a gap in the numbering and with a double-digit round present. A lexicographic reader
answers `r3` where a version-ordered one answers `r11`, and the ceiling is off by seven rounds —
about US$ 280 at the REVIEW ceiling.
