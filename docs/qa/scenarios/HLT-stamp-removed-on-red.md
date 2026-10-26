---
id: HLT-stamp-removed-on-red
area: HLT
title: Remove the key when the catalogue judges this content against it
persona: Rui
journey: J-health-verdict
expected: A catalogue verdict against the content (a census that disagrees, a gap, a survivor, a TIMED-OUT mutant) deletes that content's key rather than leaving it behind, and a red fast suite over a clean score leaves the key
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

Since `20261026-health-pula-catalogo` (ADR 0021 §4) only the catalogue's own verdict removes a key.
A red fast suite, in a skip or as the control of a catalogue run, comes from outside the key
(`TODO.md`, `docs/`) or from the machine when the key is equal, and it fails the health without
taking the key away; a tree that moved during the run writes and removes nothing.
