# ADR 0016 — A base report needs a checkpoint the mission had; a kit mission is written and executed in a linked worktree

- **Status**: accepted (—, 2026-10-06)
- **Spec**: docs/handoffs/20261006-lote-5-o-que-o-lote-4-deixou/00-missao.md
- **Amends**: 0015 (§3: the declared fail-open closes — the checkpoint left by the base commit that
  added the report must be a blob the mission's branch already had)
- **Amended by**: 0017 (§2: the kit's own judge runs in a linked worktree; the runner refuses the
  shared checkout)

## Context

Batch 5 of the kit's backlog (mission `20261006-lote-5-o-que-o-lote-4-deixou`) closes twelve
findings: the eleven open after batch 4 (eight born in batch 4 itself, three from the `sales_quote`
mission `20261005-mascaras-ncm-e-painel`) and one found while planning this batch. Ten are fixes with a
sensor that implement a decision already written. Two are architectural trade-offs, and this record
holds them. Everything was measured on `89df2e5` (2026-10-06).

### 1. A report on the base's tip counts only with a checkpoint the mission had (amends 0015 §3)

ADR 0015 §3 made a QA report found on a tip of `mission_base_refs` count for the mission only when
the newest commit of that tip that added it touches the mission's `checkpoint.md` or
`checkpoint-notas.md` (`tip_add_carries_mission`, `bin/sdd`). The same section declared one world
where the rule **fails open**: a commit of another mission that brings its own report and also
edits this mission's checkpoint. It said "no such writer is known", and in the same breath
discarded "declaring the risk", because under the D15 rule a declared fail-open stays open.

The world was reproduced on `89df2e5` in a fixture of `tests/check-gates.sh` (world j):
- another mission's squash adds its own closed report and appends one line to this mission's
  `checkpoint.md`;
- the mission brings the report in with `git checkout <base> -- <report>`;
- `sdd phase` answers `REVIEW`, and the refusal is absent (`REVIEW|0`, where `QA|1` was expected).

The premise the fix rests on was measured on 2026-10-06:
- in `sales_quote` `origin/develop`, 21 first-parent commits add a QA report. 12 move no mission's
  progress file, 9 move exactly one mission's, and 0 move two or more;
- in all 9 of 9, every progress blob the commit leaves was also written by a commit outside
  `develop`, on the mission's own branch;
- `lighthouse_project` `develop` has 1 such commit and the kit has 2, none of them moving a progress
  file.

**Decision.** On top of the two conditions of 0015 §3, the report counts only when every progress
file the adding commit moved (`checkpoint.md`, `checkpoint-notas.md`) is left as a blob that a commit
of the mission itself wrote at the same path. The mission's commits are
`git rev-list HEAD --not <mission_base_refs>`.
- **The mission's own squash** leaves exactly a blob its branch wrote, so its report still counts,
  even after the branch moved its checkpoint again with a later note (world k).
- **Another mission's commit that edits this checkpoint** leaves a blob the mission never wrote, so
  its report stops counting. That holds even when the blob is the version from before the fork
  (world l).
- **How it is read:** by plumbing, never by clock or message. One `rev-list | diff-tree --raw` runs
  per call, and only when a report sits on a tip; then one `diff-tree --raw` runs per tip that holds
  it. Measured on a minimal fixture with one base ref: a mission in flight spends 10 → 10 `git`
  processes, and a squash-merged mission read from its branch 13 → 16, about +5 ms per call.

**Residue, declared.**
- It **fails open** when another mission writes this checkpoint byte for byte as a version the
  branch committed.
- It **fails closed** when the squash's progress blob came from a merge commit of the branch (a
  conflict resolution), or from a forge edit that was never fetched. That stop is visible, and it
  names the file.

**Discarded.**

- **Keep it declared.** 0015 §3 already refused this: a declared fail-open stays open.
- **`HEAD`'s blob only.** A note the mission writes after its squash takes the mission's own report
  away (world k).
- **`HEAD`'s whole history.** Another mission that writes this checkpoint back to the fork's version
  passes (world l), and the walk no longer stops at the base.
- **Refuse a commit that moves more than one mission's progress, or any two missions'
  directories.** It is a path heuristic: an intruder that edits only this checkpoint passes. It also
  refuses the backfill commit of 0015's own mission (fourteen `00-missao.md` in one commit), which is
  a legitimate writer.
- **Parse the checkpoint's content.** That reads model-written prose, where blob identity is exact
  and cheap.

### 2. A kit mission is written and executed in a linked worktree

The `sdd` on the operator's `PATH` is the kit's main checkout: `readlink -f ~/.hermes/bin/sdd` →
`/home/joruge/repos/sdd_agents/bin/sdd`, and `~/.claude/commands/sdd-plan.md` is a symlink into the
same checkout. Every `sdd run` of a target repo therefore executes whatever `bin/sdd` that checkout
holds at that moment, and its kit guard (`kit_guard_arm`/`kit_guard_check`) compares
`autonomy_kit_stamp` — `sha|dirty` of that checkout — before and after each phase.

- Reproduced in an isolated copy (kit via `git archive` + `git init`, a fixture target, a stub
  `claude`): a clean kit and one untracked `00-missao.md` written during the target's EXEC → rc 3,
  `KIT-TOUCHED  EXEC  kit_before=54ddde6|false  kit_after=54ddde6|true`; the control with no write →
  rc 0.
- It happened for real while this batch was being planned: a `sdd run` of `sales_quote` was in
  flight, and the plan could not be written to the checkout until it ended.
- Batch 4 kept the main checkout on its mission branch for about 26 h (plan `6c628be` at
  2026-10-04 21:44, merge `94123a4` at 2026-10-05 23:10), and every target run in that window
  executed half-edited, unreviewed runner code.
- A linked worktree does not move the stamp of the main checkout. Measured in a clone: `89df2e5|false`
  before `git worktree add`, after it, after dirtying the worktree (`bin/sdd` edited and an untracked
  `00-missao.md`) and after two commits in it.

**Decision.** A mission whose repository is the kit that `sdd` runs from (`readlink -f "$(command -v
sdd)"` resolves inside the repository being planned) is written **and** executed in a linked
worktree (`git worktree add`), never in the checkout the targets execute. `commands/sdd-plan.md` says
so before any artifact is written, and a `command:` probe in `tests/check-hat.sh` holds the
sentence. The main checkout stays on the default branch; it moves only by merge.

This is about the **interactive** kit mission. `sdd run` inside its own loop still creates no
worktree: closing that "needs its own design" (`.claude/rules/anatomia-do-agente.md` §6), and this
record does not decide it.

**Discarded.**

- **Check for live `sdd run` processes before writing.** A point-in-time check: a run that starts
  after the planner began writing still gets `kit-touched`.
- **Teach the kit guard to ignore the kit's `docs/handoffs/`.** A target session writing there is
  still a session editing outside its repo, and the guard exists to stop exactly that (`2d28d13`).
- **Keep working in the main checkout and coordinate by hand.** It is what batch 4 did, and it is
  how the target runs came to execute unreviewed code for a day.

## Consequences

- `gate_QA` refuses one more world, the one 0015 §3 declared open. The fail-closed worlds of 0015
  §3 are unchanged.
- The worktree costs one step per kit mission: `.sdd/cache/` is ignored, so the first `sdd health`
  there runs without the killer map (about 2× slower) unless `mutation-killers.tsv` is copied from
  the main checkout. `.sdd/logs/` is per worktree too, so the stamp the health writes lives there.
- The anatomy rule §6 says the kit mission runs in a worktree, and keeps saying the loop does not.
