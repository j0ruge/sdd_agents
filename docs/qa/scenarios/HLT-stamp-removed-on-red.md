---
id: HLT-stamp-removed-on-red
area: HLT
title: Remove the old stamp when the catalogue comes back red
persona: Rui
journey: J-health-verdict
expected: A red catalogue deletes any existing stamp rather than leaving it behind
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

Removal and not merely non-writing. A stamp that outlives the green it certifies goes on telling
gate_PR that a catalogue which just came back red, over this very content, was measured and clean.
