---
id: GATE-review-empty-gate-field-refused
area: GATE
title: Refuse a gate field that is present and unfilled
persona: Sessão
journey: J-review-round-seal
expected: A gate frontmatter field with an empty value is refused; an absent field is left alone
entry_points: ./bin/sdd why <mission> REVIEW
qa_status: fail
bug_ids: BUG-20260819-empty-gate-field-passes
fix_status: fixed
retest_status: pending
fix_commits: 272cb91
evidence:
last_report: docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md
overlaps: 
---

Walked and failed by the mission's QA phase on 2026-08-19, and the defect contradicts the comment three
lines above it. The guard reads `gate_field != "" && placeholder(gate_field)`, while the comment claims
'Present-but-unfilled is the case that lies, and it is the one refused' — but an empty value IS
present-and-unfilled, and the first conjunct excludes precisely it.

Leaving ABSENT alone is correct and measured: 6 of the 14 rounds on disk predate the field, and refusing
them would rewrite history. That measured decision is not what this scenario disputes.

**Update 2026-08-19 (F3, `272cb91`):** fixed — presence moved into `frontmatter_has`/`gate_present`,
so absent and present-but-blank are now distinct. The refusal names the blank case as `(<empty>)`.
Retest pending on the REVIEW round now being written.
