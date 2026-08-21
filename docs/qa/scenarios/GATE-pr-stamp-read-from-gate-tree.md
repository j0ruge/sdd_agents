---
id: GATE-pr-stamp-read-from-gate-tree
area: GATE
title: Find the stamp from a worktree or a second clone
persona: Mara
journey: J-certify-mission-close
expected: The tree sdd health stamps is the same tree gate_PR reads it from, including when sdd is invoked from PATH
entry_points: sdd why <mission> PR (sdd resolved from PATH, cwd in a worktree)
qa_status: skipped
bug_ids: BUG-20260819-stamp-written-where-gate-cannot-read
fix_status: fixed
retest_status: pending
fix_commits: 1dc713f
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: 
---

Walked and failed by the mission's QA phase on 2026-08-19. `cmd_health` writes to `$SDD_HOME`
(resolved from the script path); `gate_PR` scopes, keys and reads under `$REPO_ROOT` (git toplevel of
the cwd). They diverge exactly in the flow the README advertises — `export PATH=".../bin:$PATH"` over a
worktree or a second clone — and the gate becomes unsatisfiable forever there.

No verdict came from a dated report: this repo's QA phase does not produce one (see the tree README).
`last_report` points at the checkpoint whose notes carry the reproduction.

**Update 2026-08-19 (F2, `1dc713f`):** fixed — the stamp is now written to the tree whose content
the gate measures, and the new world in `tests/check-gates.sh` is the first to run with
`SDD_HOME != REPO_ROOT`. The `xargs -0 -r` vacuity guard was hardened in the same commit but no
world reaches it, which is declared. Retest pending on a real `./bin/sdd health` after F3.

**Skipped 2026-08-21, with the reason** (CH-stamp-round-trip-from-a-worktree re-run). The stamp is
on disk in the kit and `sdd health` wrote it at `128 caught of 128` after the last code commit — but
this branch's mission was executed **interactively**, not through `sdd run`, so there is no
`docs/handoffs/<mission>/` for `gate_PR` to be asked about. Walking it would mean inventing a
mission directory to make the path reachable, which is fixture-editing to reach a code path — the
thing persona fidelity forbids. The next mission driven by `sdd run` settles it for free.
