---
id: GATE-ticket-without-branch-still-passes
area: GATE
title: Pass a ticket artifact that predates the branch field
persona: Priya
journey: J-ticket-opens-and-branch-lands
expected: A 10-ticket.md with issue and sprint but no branch passes the gate unchanged
entry_points: sdd run <mission>
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: GATE-ticket-branch-must-reach-mission
---

Backwards compatibility as a walked scenario, not an assumption. Every mission planned before the
field existed carries no `branch:` in `10-ticket.md`; refusing them would rewrite history instead of
measuring the phase that just ran, and would make each of them unrunnable at once.

It is also the anti-vacuity half of the two refusals above: without it, a gate that refused every
TICKET would settle both of them.
