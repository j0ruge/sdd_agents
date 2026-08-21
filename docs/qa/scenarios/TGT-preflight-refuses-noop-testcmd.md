---
id: TGT-preflight-refuses-noop-testcmd
area: TGT
title: Refuse a target repo TEST_CMD that exits zero having run nothing
persona: Priya
journey: J-target-repo-ships
expected: preflight fails a TEST_CMD of true, :, echo, --list, --listTests or --collect-only, naming the consequence
entry_points: sdd preflight
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: SUI-testcmd-with-list-refused
---

Worse than an empty key, because it passes: `gate_EXEC`, `gate_QA` and `gate_REVIEW` all trust this
one value, so a no-op certifies every phase of every mission for ever against a run that never
happened. `sdd health` refused one spelling of it (`--list`) and only for the KIT's own config; a
target repo was on its own.

The half that keeps the rule alive is the contra-examples: `npm test`, `tests/run-all.sh`,
`./run.sh --listen-port 8080` and `make test && echo done` must NOT be accused. A rule that fires on
correct config is the rule the next author deletes, and then the real one is gone too.
