---
id: GATE-pr-refuses-stale-stamp
area: GATE
title: Refuse again after a commit moves the measured content
persona: Rui
journey: J-certify-mission-close
expected: A commit touching tests/ invalidates the stamp; a commit touching only docs/ or CLAUDE.md does not
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

Differential, and both halves matter. The narrowing to four directories is deliberate (the DOCS phase
edits CLAUDE.md on the way to the PR, and keying on it would cost a second 20-50 minute round), so the
scenario has to confirm the boundary in both directions rather than only that staleness is detected.
