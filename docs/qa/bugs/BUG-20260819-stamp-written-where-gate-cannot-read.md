# BUG-20260819-stamp-written-where-gate-cannot-read: the operator runs the command the gate told them to run, and the gate keeps refusing

- **Status:** fixed <!-- open | fixed | verified | wont-fix | invalid -->
- **Impact (user-side):** Blocks-Completion
- **Severity:** Critical · **Priority:** P0
- **Persona Affected:** Mara
- **Journey Step:** J-certify-mission-close, step 4-5 (run sdd health, re-run the mission)
- **Scenarios:** GATE-pr-stamp-read-from-gate-tree
- **Found:** 2026-08-19 · **Report:** docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md (QA-phase notes; this repo's QA phase produces no dated report — see the tree README)

## Summary

Mara finishes a mission from a git worktree, with `sdd` on her PATH. `gate_PR` refuses and tells her
to run `sdd health`. She runs it, watches 20 to 50 minutes of catalogue go green, re-runs the
mission — and gets the identical refusal. The remedy the product handed her stamps a different tree
from the one the gate inspects, so the loop never terminates, at 20 to 50 minutes per lap.

## Reproduction

- **Charter:** CH-stamp-round-trip-from-a-worktree · **Tour:** Multi-Tab Tour
- **Environment:** laptop, any shell; `sdd` resolved from PATH per `README.md:30`
  (`export PATH=".../bin:$PATH"`), cwd inside a git worktree or a second clone of the kit

1. Clone the kit to `~/kit` and put `~/kit/bin` on PATH.
2. `git worktree add ~/work-mission` (or make a second clone) and `cd ~/work-mission`.
3. Take a mission to the PR phase; `sdd why <mission> PR` refuses with
   `no green mutation catalogue for this content — run 'sdd health'`.
4. Run `sdd health` from `~/work-mission`. It goes green and reports `mutation stamp written`.
5. `sdd why <mission> PR` again.

**Expected:** the gate passes — the command it named has been run and reported success.
**Actual:** the identical refusal. Repeating step 4 never changes it.

## Evidence

- `bin/sdd:1916` — `cmd_health` sets `local kit="$SDD_HOME"` and writes `$kit/$MUTATION_STAMP_REL`.
  `SDD_HOME` is `_resolve_self()` (`bin/sdd:47-56`): the directory of the **script**, i.e. `~/kit`.
- `bin/sdd:712-715` — `gate_PR` scopes on `$REPO_ROOT/tests/check-mutation.sh`, keys on
  `mutation_stamp_key "$REPO_ROOT"` and reads `$REPO_ROOT/$MUTATION_STAMP_REL`. `REPO_ROOT` is the
  git toplevel of the cwd, i.e. `~/work-mission`.
- The two agree only when the runner is invoked as `./bin/sdd` from the repo root. All eight
  differential worlds in `tests/check-gates.sh` invoke `$FIX/bin/sdd` from inside `$FIX`, so
  `SDD_HOME == REPO_ROOT` by construction in every one of them and none can reach this.

### Second half, same file, separate observable

`mutation_stamp_key` (`bin/sdd:672-690`) pipes `find` into `xargs -0 md5sum` **without `-r`**. With
no matches, `xargs` still runs `md5sum` once with no operands, which reads stdin and returns the
md5 of empty — a stable, valid-looking constant. The `[ -n "$listing" ]` guard that the comment
above describes as the refusal of vacuity therefore only fires when the **root** does not exist, not
when the four measured directories are empty. Filed here rather than separately because it is the
same function and the same fix increment; if F2 lands without addressing it, re-file it on its own id.

## Fix

- **Root cause:** the writer is keyed to the installation (`$SDD_HOME`), the reader to the
  workspace (`$REPO_ROOT`). Symptom and cause differ: the symptom is an unsatisfiable gate, the
  cause is two different answers to "which tree is this?" inside one feature.
- **Fix commit:** `1dc713f` (increment F2), checkpoint row closed by `cc0e1bd`
- **Regression test:** `tests/check-gates.sh`, anchored on
  `^  ok    gate_PR: the stamp is read from the tree whose content the gate measures` — and it does
  exercise `SDD_HOME != REPO_ROOT`, which is what no prior world did. Catalogue mutant
  `mut_HEALTH_stamp_tree_blind` (111 -> 112), proved at a single site with a one-line diff that
  kills the new assertion and **not** the I4 one — one sabotage per site. `mut_PR_stamp_blind` was
  re-anchored on `has_mutation_catalogue` and re-failed in the fixture to prove it still bites.
  `CAPTURE_FLOOR` 21 -> 22 for the new `kit` capture.
- **Adversarial pass:** five degradations, four red — resolver condition forced false (= the
  mutant), forced true, body returning `$SDD_HOME`, and `cmd_health`'s `stamp_path` reverted to
  `$SDD_HOME` with the measurement otherwise correct, which is the defect in pure form. Each probe
  proves it changed the line it claimed to change before concluding.

### The second half: hardened, and the hardening is unreachable today

`xargs -0 -r` was added, so the comment and the code now agree. The fixing session declares rather
than sells it: both ends only ever ask about a root whose `tests/` holds the catalogue, so `find`
always prints at least that file and no world reaches the empty-listing branch. Same class as the
`[ -z "$key" ]` branch from I4 — a cheap guard carrying real weight that nothing exercises.
Recorded as declared debt, not as a measured fix.

## Verification

**Not yet verified, deliberately** — same reason as its sibling: F3 was still `pending` and touches
`bin/` and `tests/`, so a stamp taken now would die at the next commit. Whoever closes F3 runs
`./bin/sdd health` after the last code commit, and that run verifies this bug.

Measured in the fixing session instead: `./bin/sdd phase` at 34 ms, `sdd why ... PR` still answering
`missing 50-pr.md` (the stamp stays last in the queue), and `sdd run --dry-run` projecting
EXEC -> REVIEW -> DOCS -> PR unchanged.
