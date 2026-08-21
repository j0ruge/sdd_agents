---
id: GATE-review-placeholder-rationale-refused
area: GATE
title: Refuse an A whose rationale is a placeholder
persona: Sessão
journey: J-review-round-seal
expected: A table of A grades with PREENCHER in every rationale is refused, naming the offending criterion
entry_points: ./bin/sdd why <mission> REVIEW
qa_status: pass
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: GATE-review-punctuated-placeholder-refused; GATE-review-exemplar-matches-the-gate
---

The mission's I3. The live instance is in this repo: `docs/handoffs/20260818-lote-facil/40-review-r1.md`
records in its own `gate:` field that round 1 left PREENCHER in all seven rationales, and the gate of the
day passed it. Canonical owner of the placeholder behaviour; the punctuated sibling refines it.
