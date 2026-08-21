---
id: GATE-ticket-branch-must-reach-mission
area: GATE
title: Refuse a ticket whose branch never reached the artifact the runner reads
persona: Priya
journey: J-ticket-opens-and-branch-lands
expected: With branch filled in 10-ticket.md and a placeholder in 00-missao.md, gate_TICKET refuses and names 00-missao.md
entry_points: sdd run <mission>; sdd why <mission> TICKET
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: GATE-ticket-branch-mismatch-refused; GATE-ticket-without-branch-still-passes
---

`ensure_mission_branch` reads `branch:` from `00-missao.md` and from nowhere else. A name recorded
only in `10-ticket.md` leaves every later phase committing wherever the operator happened to be
standing — class SQ-97, measured once at 16 commits on another PR's branch.

The gate takes only the half a gate can take. The **write** is the session's: a gate that wrote
would corrupt `moved`/`moved2`, the fingerprints that tell "the session moved the disk" from "the
session did nothing", and the runner would start retrying phases that were making progress.
