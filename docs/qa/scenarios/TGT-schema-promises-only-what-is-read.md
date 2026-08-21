---
id: TGT-schema-promises-only-what-is-read
area: TGT
title: Document no config key the runner never reads
persona: Priya
journey: J-target-repo-ships
expected: Every key in config/schema.md is read somewhere in bin/sdd, and the starter config offers no key that is ignored
entry_points: config/schema.md; config/starter.conf; sdd install
qa_status: blocked-decision
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
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

---

**Walked 2026-08-21 (CH-first-two-commands-in-a-strangers-repo, Garbage Tour).** The five phantom
keys are gone: the config `sdd install` writes offers 27 keys and every one of them is read by the
runner — except `E2E_DIR`, which is the declared, frozen debt.

That exception was walked from Priya's side rather than reasoned about. She keeps her specs in
`tests/browser/`, sets `E2E_DIR="tests/browser"` because the schema offers the key, and runs
`sdd run --dry-run --phase QA`: the boot prompt mentions `docs/qa` (a key that IS passed) three
times and `tests/browser` **zero** times. She changed a documented setting and nothing anywhere
told her it would not take effect.

`blocked-decision`, not `fail`: the disposition is a product decision with three real options
(wire the key into the QA prompt, remove it from the schema, or document it as agent-only), and no
bug was minted because an `open` bug in this repo holds `gate_QA` shut for every future mission —
disproportionate for a declared debt. Escalated in the report's Decisions for a Human.
