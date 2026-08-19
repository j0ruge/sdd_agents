---
id: GATE-review-legit-short-rationale-passes
area: GATE
title: Let the codereview skill's own shorthand through
persona: Sessão
journey: J-review-round-seal
expected: clean, n/a and the em dash pass as rationales; the refusal targets the whole cell, not any short cell
entry_points: ./bin/sdd run <mission>
qa_status: untested
bug_ids: 
fix_status: 
retest_status: pending
fix_commits: 272cb91
evidence:
last_report: 
overlaps: 
---

The differential half, and it is what stops the rule from being decoration. `report-template.md:154-156`
names clean, n/a and — as the skill's shorthand for 'measured, nothing to say'. A gate that refused them
would contradict the skill it parses, which is exactly the gate_DOCS bug from the SQ-97 pilot.

The em dash is the sharp edge: mawk is byte-oriented and — is E2 80 94, so any future rule using a
punctuation class must be probed against it before shipping.

**Update 2026-08-19 (F3, `272cb91`):** this scenario's property is now a *measured* one. Removing
the `—` exception is one of the 13 adversarial degradations and turns the F3 assertion red, so
`clean`, `n/a` and `—` are held open by a probe rather than by intent.
