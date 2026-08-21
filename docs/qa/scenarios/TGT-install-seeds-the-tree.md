---
id: TGT-install-seeds-the-tree
area: TGT
title: Seed the handoff root and the findings file at install time
persona: Priya
journey: J-target-repo-ships
expected: After sdd install the handoff root exists and the findings file is present and non-empty
entry_points: sdd install
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps:
---

Both paths are NAMED in the config the installer just wrote, which is what makes them the
installer's job rather than the user's. Without the handoff root, `resolve_mission` dies on the
first command Priya types, with a message that describes the absence and nothing that says the
installer should have made it.

Two halves, and the second is the one that can destroy work: the file is seeded with the entry
FORMAT (an empty file teaches nothing), and a second `sdd install` over a file holding real findings
must leave it byte for byte. Walk the second install with a real entry already in the file.

Read the values by sourcing the config in a subshell, the way check 2b reads TEST_CMD — a grep of
the line answers about the text, not about what `load_config` will hand the runner.
