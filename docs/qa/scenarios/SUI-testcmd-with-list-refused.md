---
id: SUI-testcmd-with-list-refused
area: SUI
title: Refuse a TEST_CMD that exits zero having run nothing
persona: Mara
journey: J-suite-runs-something
expected: health refuses a TEST_CMD carrying --list, an empty one, and a missing config, each with its own sentence
entry_points: ./bin/sdd health
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

Three refusals, three distinct causes, and the scenario is only settled when each prints its own — a
shared message would make the check unable to say which of the three ways the suite is empty.

Declared scope: check 2b reads the KIT's config and never a target repo's. A target repo's TEST_CMD that
exits 0 without running anything stays invisible; that is filed in TODO.md, not hidden here.
