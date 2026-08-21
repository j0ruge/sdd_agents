---
id: TGT-preflight-warns-missing-skills
area: TGT
title: Warn about the third-party skills the phases will boot
persona: Priya
journey: J-target-repo-ships
expected: preflight warns (never fails) about a skill it cannot find, naming the roots searched and the cost
entry_points: sdd preflight
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: TGT-preflight-skill-warning-follows-the-config
---

Three phases boot skills the kit does not ship. A missing one is not a session that fails — it is a
session that boots, finds nothing, improvises, and spends the phase budget producing something no
gate can read. That is the most expensive silent failure in the product.

Warn and never fail is the deliberate call: the search roots are a convention of the harness, not a
contract the kit can enforce, and failing on a heuristic is how the rule gets deleted. Walk the
differential — the same config with the skills present must be silent — or the warning is
indistinguishable from one that always fires.
