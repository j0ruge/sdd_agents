---
id: SUI-list-prints-steps-only
area: SUI
title: Ask what the suite would run and get only step names
persona: Mara
journey: J-suite-runs-something
expected: Every line of --list output is a step, including on a machine with no shellcheck
entry_points: tests/run-all.sh --list
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

The degraded world is the one that matters: with the linter absent, the notice about skipping it must
not appear inside the list, or a non-step line reads as a step that ran. The mission built that world
by degrading the command lookup rather than by poisoning PATH — on this distribution shellcheck shares
/usr/bin with grep, sed and comm, so removing the directory would measure a suite that cannot run.
