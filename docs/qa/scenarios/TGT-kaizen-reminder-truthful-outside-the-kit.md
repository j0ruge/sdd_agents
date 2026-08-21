---
id: TGT-kaizen-reminder-truthful-outside-the-kit
area: TGT
title: Tell a target repo the truth about a judge that reads other numbers
persona: Priya
journey: J-target-repo-ships
expected: Outside the kit the post-pipeline line says the judge reads only kit missions, and never points at sdd kaizen
entry_points: sdd run <mission>
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps:
---

The line counts THIS repo's missions and then used to send every reader, from every repo, to
`sdd kaizen` in the kit — where the judge filters the ledger by repo and reads an entirely different
set of numbers. Priya opens the kit, runs the command, and is told something about the kit's own
missions that has nothing to do with the run that just finished.

Three things settle it and the last two are absences: the honest sentence is present, the pointer to
`sdd kaizen` is gone, and nothing promises `--all-repos` — an option whose decision is deliberately
deferred. Promising it would be the same lie in the other direction.

Inside the kit the old message must survive byte for byte; walk both sides.
