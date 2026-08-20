---
id: TGT-pr-gate-silent-in-target
area: TGT
title: Ship from a target repo without ever hearing about the kit's catalogue
persona: Priya
journey: J-target-repo-ships
expected: In a repo with no tests/check-mutation.sh, no gate message mentions a stamp, a catalogue, or sdd health
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

The cycle's canary, and the highest-blast-radius scenario in it: the diff changed a gate that every
target repo evaluates, and one `[ -f ... ]` test is all that keeps the kit's self-maintenance out of
somebody else's pipeline. Scoped by artifact and never by repository identity — the identity door the
kit already owns (cmd_kaizen) carries a live worktree bug, and inheriting it would buy a known defect.

Walk it by reading back every message the run produced, not only by observing that the PR opened.
