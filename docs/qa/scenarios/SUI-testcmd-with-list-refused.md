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
overlaps: TGT-preflight-refuses-noop-testcmd
---

Three refusals, three distinct causes, and the scenario is only settled when each prints its own — a
shared message would make the check unable to say which of the three ways the suite is empty.

⚠️ **The declared scope changed on branch `20260820-missao-porteira` and this file's old note is
kept below as the record of it.** The gap is closed: `sdd preflight` now refuses a no-op `TEST_CMD`
in **any** repo (`test_cmd_looks_noop`, `41f6c34`), covering `true`, `:`, `echo`, `printf`, `exit`
and the enumerate-don't-run flags. That behaviour is walked in `TGT-preflight-refuses-noop-testcmd`,
under Priya, in a target repo — this scenario stays about check 2b of `sdd health`, whose subject is
the KIT's own suite mode and whose message says so.

Check 2b deliberately kept its own narrower `--list` case rather than calling the shared predicate:
its sentence names the kit's suite, and `mut_HEALTH_testcmd_list_blind` anchors on that case
pattern. The duplication is declared in the code, not hidden — a new spelling belongs in both, and
that is what this scenario and its overlap exist to keep honest.

> Superseded note, kept as history: *"Declared scope: check 2b reads the KIT's config and never a
> target repo's. A target repo's TEST_CMD that exits 0 without running anything stays invisible;
> that is filed in TODO.md, not hidden here."*
