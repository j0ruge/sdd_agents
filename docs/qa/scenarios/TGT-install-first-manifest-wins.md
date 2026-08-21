---
id: TGT-install-first-manifest-wins
area: TGT
title: Pick one suite when a repo carries more than one manifest
persona: Priya
journey: J-target-repo-ships
expected: A repo with package.json and go.mod is installed with npm test, not with the last manifest checked
entry_points: sdd install
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps:
---

Four independent `if`s meant all four ran and the LAST match won, whatever the repo actually is. A
Node project carrying a `go.mod` for a sidecar tool was installed with `go test ./...` as the suite
every gate runs — the wrong suite, chosen in silence, in the one key the whole pipeline trusts.

Multi-manifest repos are ordinary, not exotic: a JS app with a Go helper, a Python service with a
front end. Walk at least two orderings, and confirm the choice is announced where Priya reads it —
a silently wrong TEST_CMD is worse than a `TODO` she has to fill in.
