---
id: HLT-empty-catalogue-refused
area: HLT
title: Refuse a catalogue too small to have measured anything
persona: Mara
journey: J-health-verdict
expected: A catalogue of zero or a handful of mutants is refused; it never reaches a green stamp
entry_points: ./bin/sdd health
qa_status: pass
bug_ids: BUG-20260819-empty-catalogue-stamped-green
fix_status: fixed
retest_status: pass
fix_commits: 688553f
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: 
---

Walked and failed by the mission's QA phase on 2026-08-19, and it is the mission's own thesis turned
against the mission's own artifact. `score: 0 caught, 0 known gap(s), of 0` satisfies gaps == 0 and
caught == total, so the verdict is ok, catalogue_green is 1, and the stamp is written over a catalogue
that ran zero mutants. `CATALOG=()` executes the loop zero times and exits 0.

It is the only count in `cmd_health` with no anti-vacuity floor, among LINT_FLOOR, SURFACE_FLOOR,
CAPTURE_FLOOR and REVIEW_FLOOR.

**Update 2026-08-19 (F1, `688553f`):** fixed in `cmd_health`, the consumer of the score line. The
producer `tests/check-mutation.sh` still has no floor, and the runner points operators at
`tests/run-all.sh --with-mutation` in two places, where the unfloored green is still reachable.
Retest is pending on a real `./bin/sdd health` after F3.
