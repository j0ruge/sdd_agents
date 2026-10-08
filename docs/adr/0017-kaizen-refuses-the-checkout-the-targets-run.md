# ADR 0017 — `sdd kaizen` refuses the checkout the targets run, and names the worktree

- **Status**: accepted (—, 2026-10-08)
- **Spec**: docs/handoffs/20261008-lote-6-as-quatro-que-faltam/00-missao.md
- **Amends**: 0016 (§2: the kit's own judge joins the kit mission in a linked worktree — the runner
  refuses the shared checkout, it does not create one)

## Context

ADR 0016 §2 decided that a mission whose repository is the kit `sdd` runs from is written and
executed in a linked worktree, never in the checkout every target's `sdd run` executes. It decided
that for the interactive kit mission (`commands/sdd-plan.md`, step 2) and said nothing about the
third writer of the kit: the `sdd kaizen` loop. Batch 5 registered the gap as a finding (decision
11b of `20261006-lote-5-o-que-o-lote-4-deixou`, issue #236) and left the choice to the human.

Measured on `fc32329` (2026-10-08):

- `cmd_kaizen` (`bin/sdd`) admits any checkout of the kit, compared by the git common dir (issue
  121): the main checkout and every linked worktree of it pass the same door. A linked worktree is
  **already** a working place for the judge — `tests/check-kaizen.sh` holds it ("kit-repo guard: a
  linked worktree of the kit answers like the main checkout").
- Nothing refuses the checkout the `sdd` on the PATH resolves into (`readlink -f "$(command -v
  sdd)"` → `/home/joruge/repos/sdd_agents/bin/sdd` on the operator's machine). There it only warns
  when on the base branch (`warn_if_on_base_branch`), and the KAIZEN session writes the verdict, the
  next mission's plan, and commits.
- The kit guard (`kit_guard_arm`/`kit_guard_check`) compares that checkout's `HEAD` and dirty tree
  around every phase of every target's run. ADR 0016 §2 reproduced the effect of one untracked file
  written there during a target's EXEC: rc 3, `KIT-TOUCHED`. A KAIZEN session writes four files and
  a commit. This was read in the code and not reproduced end to end.
- The judge runs at the end of a measurement window, which is exactly when target missions are
  running on the frozen kit (the measurement-window entry of `CONTEXT.md`; decision 6 of this mission freezes
  the kit again at its merge).

## Decision

**A real `sdd kaizen` dies before any session when `readlink -f "$(command -v sdd)"` lies under the
repository root it was called from** — the same test, with the same trailing slash, as step 2 of
`/sdd-plan`, so a sibling such as `<root>-kaizen` is never mistaken for it. The message says why
(every target's run executes this checkout; a committing session here stops them with
`KIT-TOUCHED`) and gives the command that fixes it: `git -C <root> fetch && git -C <root> worktree
add ../<repo>-kaizen -b kaizen/<YYYYMMDD> origin/<DEFAULT_BRANCH>`, then `sdd kaizen` from there — a
fetch, never a pull, because a pull moves the very `HEAD` the kit guard compares.

- `sdd kaizen --series` is not refused: it is a pure read and returns before the door.
- `sdd kaizen --dry-run` is not refused either: it **warns** with the same sentence and projects. A
  projection opens no session and writes nothing, and it is the read-only look the measurement
  window is told to use; refusing it would demand a worktree to look.
- When `sdd` is not on the PATH, or resolves outside this root, nothing changes: no target run on
  this machine executes this checkout.
- The reminder every finished `sdd run` prints (`kaizen_reminder`) pointed at "the kit repo
  (`$SDD_HOME`)", which from a target is exactly this checkout. It now says to run the judge from a
  linked worktree of the kit.
- The refusal is a `die` beside the identity refusal that already exists: no ledger row, no
  escalation hook, no `kind` — the same shape as a refused admission.

## Discarded

- **`sdd kaizen` creates the worktree and runs there.** It moves the command's `REPO_ROOT` in the
  middle of a run, takes the checkout lock of a second physical checkout (`coordination_enter` locks
  per checkout), and still leaves the push, the PR and the removal to the human. ADR 0016 §2 already
  says that a runner creating worktrees "needs its own design", and nothing here pays for that design.
- **Warn louder and keep going.** A sentence is a reminder, not a boundary
  (`.claude/rules/anatomia-do-agente.md` §1). It is the state today, and it is the gap.
- **Refuse only while a target run is in flight.** A point-in-time check, discarded for the same
  reason in ADR 0016 §2: a run that starts after the judge began still gets `KIT-TOUCHED`.
- **Refuse in the main worktree of the kit (`git-dir == common-dir`), whatever the PATH says.**
  Simpler, but it refuses a kit cloned twice where the PATH runs the other clone, and it is not the
  test `/sdd-plan` uses; two definitions of "the checkout the targets run" would drift.

## Consequences

- The judge costs one `git worktree add` per window. Its killer map and logs are not involved — the
  judge never runs the mutation catalogue.
- `README.md`, `docs/pipeline.md` § The kaizen loop, the `CONTEXT.md` entry on the measurement window
  and the anatomy rule §6 say where the judge runs. Probes in `tests/check-kaizen.sh` hold the door
  in six worlds (refused here, warned in the projection, admitted from the worktree, the sibling not
  mistaken, `--series` still read, nothing refused with no `sdd` on the PATH), and the mutation
  catalogue sabotages each rule.
- The declared limits: `command -v sdd` reads the PATH of the shell that runs `sdd kaizen`, so a
  target run launched with another PATH executes another kit and this door does not see it; and the
  `readlink -f` failure branch has no world (`readlink -f` of a path `command -v` found does not fail
  on this machine), so it is declared rather than probed.
