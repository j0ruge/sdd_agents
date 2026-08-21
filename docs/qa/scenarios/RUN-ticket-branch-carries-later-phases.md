---
id: RUN-ticket-branch-carries-later-phases
area: RUN
title: Commit the mission's later phases on the branch the card created
persona: Priya
journey: J-ticket-opens-and-branch-lands
expected: After TICKET, git log on the declared branch carries the EXEC commits and the PR opens from it
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

The true end state of the journey, and the only one checked from the repository rather than from an
artifact: `git log <branch>`, not "the handoff says so".

Walk the resume case too — `ensure_mission_branch` re-reads `00-missao.md` AFTER the checkout,
because a branch cut before the mission existed replaces the tree under the runner and the artifacts
that justified every choice are simply gone. Landing on a branch that does not carry this mission
must stop the line, not proceed.
