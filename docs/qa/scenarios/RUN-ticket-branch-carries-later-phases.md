---
id: RUN-ticket-branch-carries-later-phases
area: RUN
title: Commit the mission's later phases on the branch the card created
persona: Priya
journey: J-ticket-opens-and-branch-lands
expected: After TICKET, git log on the declared branch carries the EXEC commits and the PR opens from it
entry_points: sdd run <mission>
qa_status: blocked-verify
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps:
---

The true end state of the journey, and the only one checked from the repository rather than from an
artifact: `git log <branch>`, not "the handoff says so".

Walk the resume case too — `ensure_mission_branch` re-reads `00-missao.md` AFTER the checkout,
because a branch cut before the mission existed replaces the tree under the runner and the artifacts
that justified every choice are simply gone. Landing on a branch that does not carry this mission
must stop the line, not proceed.

**Walked 2026-08-21, half of it** (CH-the-branch-the-card-created, Feature Tour). The runner side is
proven end to end: with both artifacts agreeing on `feature/SQ-412-quote-pdf`, `sdd run` created the
branch from the current one, checked it out, announced
`ok branch: main → feature/SQ-412-quote-pdf (declared in 00-missao.md)`, journalled
`BRANCH  main -> feature/SQ-412-quote-pdf`, and ran EXEC on it.

`blocked-verify` for the other half: the `ticket` skill creating the real card **and** the branch,
and the PR opening from it, needs a live JIRA project and `gh` against a real remote. A person has
to do that leg.

**Instructions for the human:** in a repo with a real `.jira-project` pointing at a throwaway
project, set `JIRA_ENABLED=true`, leave `branch:` in `00-missao.md` at its `<...>` placeholder, and
run `sdd run <mission>`. Confirm three things: the card is created **in the active sprint** (not the
backlog); the session writes the created branch name into BOTH `10-ticket.md` and `00-missao.md` and
commits them; and `git log` on that branch afterwards carries the mission's commits. Do not use a
project anyone else reads.
