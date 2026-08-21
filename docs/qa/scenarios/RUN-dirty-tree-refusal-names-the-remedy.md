---
id: RUN-dirty-tree-refusal-names-the-remedy
area: RUN
title: Name the commands that leave the blocked state, not only the state
persona: Sessão
journey: J-trouble-stops-the-line
expected: The refusal names both directions — commit what belongs to the mission, restore what does not
entry_points: sdd run <mission>; sdd why <mission> EXEC
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps:
---

Sessão's standing failure mode: a message that describes a state without naming the command that
leaves it. Two DOCS phases in this repo burned a session each on exactly that shape.

The runner must not choose for the operator here — it cannot tell whose uncommitted work it is, and
`git restore` on somebody else's changes is unrecoverable. Naming **both** directions is therefore
the correct behaviour, and a message naming only one would be a worse bug than naming neither.
