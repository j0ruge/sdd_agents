---
id: RUN-ticket-boots-one-driver
area: RUN
title: Boot the TICKET phase with one driver, not an agent and a slash
persona: Sessão
journey: J-ticket-opens-and-branch-lands
expected: The projection shows agent sdd-publisher and a boot prompt that does not open with /ticket open
entry_points: sdd run <mission> --dry-run --phase TICKET
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps:
---

The invariant is written in the runner above `phase_agent`: an agent and a prepended slash are two
system prompts fighting over one session. Every other phase obeys it — the QA sub-steps driven by a
skill answer `<none>` precisely so the slash can be the first line.

Both halves settle this, and neither alone does: the agent alone passes on a runner that kept the
slash too, and the missing slash alone passes on a runner that boots the phase with no driver at
all. The `ticket` skill has no `disable-model-invocation`, so it does not need to be the first line
to load, and `agents/sdd-publisher.md` already tells the session to invoke it.
