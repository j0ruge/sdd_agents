# ADR 0021 — The stamp is a set of measured keys in the git common directory, and `sdd health` skips a key already measured

- **Status**: proposed (—, 2026-10-26)
- **Spec**: docs/handoffs/20261026-health-pula-catalogo/00-missao.md
- **Amends**: 0004 (§4: the writer and the reader still address one repository, and the stamp now
  lives where every worktree of it reads; the consequence "the stamp is removed when the catalogue
  comes back red" is narrowed to the catalogue's own verdict), 0016 (Consequences: the killer map and
  the stamp are no longer per worktree)

## Context

`sdd health` ran the whole mutation catalogue on every call, even over content whose stamp key had
already been measured green. `cmd_health` reads the key before the suite and then calls
`tests/run-all.sh --with-mutation` unconditionally; only `gate_PR` and line 6 of `--release` compare
the key with a stamp. Measured on 2026-10-25: **10 h 58 min**, 775 of 775 caught, with no killer map,
for PR #327, whose diff touched only `TODO.md` and the backlog ratchet, both outside the key. The
fast suite, measured on the same machine the same night: 672 s.

Skipping on a matching stamp would not have been enough on its own, because the stamp
(`.sdd/logs/mutation-stamp`) and the killer map (`.sdd/cache/mutation-killers.tsv`) lived in ignored
directories **of each checkout** (ADR 0016, Consequences), and kit work runs in one linked worktree
per mission (ADR 0016 §2), which is born without either and loses both at `git worktree remove`:

- of the 10 checkouts of the kit on the measuring machine, only the main one held a stamp, and it was
  stale (key `b04da602` against `05dc39fc` on `main` since #321); only the main one held the map;
- the key PR #327 measured was the key of the tip of PR #315's branch, four days older (`git diff
  --quiet` over the five keyed paths: tip of #315 = merge of #315 = base of #327 = merge of #327). The
  worktree of #327 had no `.sdd/logs/`, so a skip reading the local stamp would not have fired there;
- 34 of the last 40 first-parent commits of `main` leave the key unchanged;
- bringing the map and the stamp back to the main checkout was a manual step, written in
  `docs/failure-modes.md` and repeated to the human by `/sdd-plan`.

Running "only the new mutants" is not an option: a mutant's fate depends on the whole of `bin/sdd` and
on the sensors (PRs #12 and #13, ADR 0004), and `--touched` is a hint, never a verdict. What can be
reused is the trust `gate_PR` already gives the stamp: an equal key means equal measured content.

## Decision

1. **The stamp and the map live in the git common directory.**
   `git rev-parse --path-format=absolute --git-common-dir` — shared by the main checkout and every
   linked worktree of one clone, and already the identity `ledger_repo_root` reads — holds
   `sdd-mutation/stamps/<key>` and `sdd-mutation/killers.tsv`. A root that is not a git checkout gets
   no stamp, as before, and its map stays in `.sdd/cache/`. `git status --porcelain` does not see
   inside `.git/`, so the kit guard (`autonomy_kit_stamp`) answers the same when a worktree writes
   there.
2. **The stamp is a set of keys measured green**, one file per key, written only when the catalogue
   ran green (the suite and the score, as before) over a key that did not move during the run. One
   definition answers "was this key measured green?", and `gate_PR`, line 6 of `--release` and
   `cmd_health` all ask it. The old `.sdd/logs/mutation-stamp` is neither read nor written.
3. **`sdd health` skips the catalogue when the key is in the set.** It runs the fast suite, the
   ratchet and every static check, and says that the catalogue was skipped and that `--full`
   measures it again. `--with-mutation` stays a synonym of the default; `--full` forces the
   catalogue, and is refused beside `--release`, which never runs the suite.
4. **Only the catalogue's own verdict over a key removes it:** a census that disagrees, a gap, a
   survivor or a TIMED-OUT mutant, from a run over a new key or under `--full`. A red fast suite — in
   a skip, or as the control of a catalogue run — fails `sdd health` (rc 1, with the FAIL lines) and
   leaves the key alone. The key describes the keyed content; with the key equal, the red comes from
   outside it (`TODO.md`, `docs/`) or from the machine, and `gate_REVIEW` already refuses a red
   `TEST_CMD` before `gate_PR` is read. A tree that moved during the run writes and removes nothing.
5. **The map is read as a union and written as a union.** The shared map first, then the old
   `.sdd/cache/` map of the checkout for the slugs the shared one does not know; it is written only to
   the shared file, the slugs of this run's catalogue taking this run's line (and leaving when they
   have no killer, as before) and every other slug keeping the line the map already had.

## Alternatives discarded

- **Keep both per checkout and pull from the sibling worktrees** (`git worktree list`) before deciding.
  A smaller diff, but whatever a worktree measured dies with `git worktree remove`, and "run health
  before removing" goes back to being a step the human has to remember.
- **Skip on the local stamp only, and keep the return manual.** It would have saved no measured case:
  every worktree is born without a stamp.
- **`--with-mutation` forces the catalogue.** It is what the name suggests, but the habit written in
  16 handoffs and in `CLAUDE.md` would keep paying the whole catalogue.
- **No new flag; delete the key file by hand to force a measurement.** No new surface, but the remedy
  is an `rm` inside `.git/`.
- **Any red removes the key** (the old rule extended to the set). A red that comes from outside the
  key, in one worktree, would make every checkout with the same content pay the catalogue again.
- **Read the old stamp and the old map forever, beside the shared ones.** Two sources of truth for the
  stamp, and the removal rule of point 4 would have to touch both.
- **A validity window by age or by environment.** `gate_PR` never had one; adding it to the skip alone
  would give the stamp two meanings. `--full` is the operator's way to distrust it.

## Consequences

- `sdd health` over content already measured green costs the fast suite instead of the catalogue.
- A kit worktree returns nothing by hand: `git worktree remove` keeps the stamp and the map, and
  `/sdd-plan` stops asking the human to bring them back.
- Declared, not closed: the key covers content only, so a change of machine or tool version (bash,
  shellcheck, python) is not seen by the skip, exactly as `gate_PR` never saw it; `--full` is the
  remedy. The set is never pruned (a file of a few dozen bytes per key). Two catalogues finishing at
  the same instant can lose a line of the map, which costs time and never a verdict. Another clone of
  the repository does not share the directory and measures again.
