---
id: TGT-schema-promises-only-what-is-read
area: TGT
title: Document no config key the runner never reads
persona: Priya
journey: J-target-repo-ships
expected: Every key in config/schema.md is read somewhere in bin/sdd, and the starter config offers no key that is ignored
entry_points: config/schema.md; config/starter.conf; sdd install
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps:
---

A key the runner never reads is a promise the user cannot collect on, and it is worse than a missing
feature: Priya fills in `LINT_CMD`, believes she has a lint gate, and gets a green pipeline that
never linted anything. The schema carried five of these — for a lint, a build and bringing the
environment up.

Walk it as a reader, not as a grep: does the schema now say where lint and build belong (inside
`TEST_CMD`), and does adding a key back oblige the reader to wire it in the same commit? The
surviving frozen case is `E2E_DIR`, read only by the agent — check it is still declared as debt
rather than quietly re-promised.
