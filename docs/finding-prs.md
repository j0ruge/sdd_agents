# The queue of finding PRs

How to merge a queue of PRs that only register findings in the kit's `TODO.md` (a `chore(todo)` or
`docs(todo)` branch, one per retro or batch of lessons), one after another, without the next one
breaking. The same recipe serves the post-merge chore of a mission that deletes its `RESOLVED by`
items and moves the ratchet down.

## Why every finding PR conflicts with the next one

Two lines move in every one of them:

- **The ratchet.** The `todo-findings <N>` line of `tests/health-baseline.txt` holds the count of
  open findings (`CLAUDE.md`, principle 5: growing is allowed, growing silently is not). Every PR
  that adds an item moves that one line, so two PRs cut from the same `main` always conflict on it.
- **The end of a section of `TODO.md`.** A new item goes to the end of its section, and two PRs
  that add to the same section append at the same place.

Neither conflict is a disagreement: both sides are right, and the merged count is the sum. Measured
on 2026-11-11: of PRs 381 and 386 to 389, four conflicted on the ratchet and two on `TODO.md`; on
2026-11-12 PRs 378, 380 and 383 did the same. The recipe below (first written down by the merge
commit `9593497`) passed every time.

## The recipe, one PR at a time

Take the PRs in the order they will merge. For each one, on its branch, from the repository root:

1. **Bring `main` in.** `git fetch origin` and then `git merge origin/main` — a merge commit, never
   a rebase: the branch is already pushed and a review may be in flight.
2. **Resolve `TODO.md` keeping both sides.** Where both added items at the same place, keep the
   PR's items and then `main`'s, with the blank line the neighbouring items use in that section.
   An anchor (`` `path:N` (`symbol`) ``) both sides touched follows `main`, which is where the code
   now is.
3. **Recount and write the ratchet.** `tests/check-todo.sh --count TODO.md` prints the merged count
   `Y`; write `todo-findings Y` in `tests/health-baseline.txt`, never the sum done by hand. The
   merge commit's subject says the arithmetic:
   `Merge origin/main into <branch> — catraca X + n → Y`, where `X` is the count on `main` and `n`
   the items this PR adds (`9593497`: `catraca 57 + 4 → 61`).
4. **Measure, in this order.**
   - `tests/check-todo.sh --check TODO.md` → rc 0;
   - `tests/check-todo.sh --anchors TODO.md` → `0 off target`;
   - `tests/check-todo.sh --check TODO.md --baseline origin/main` → `0 new shape violation(s)`.
     The options keep this order: `--baseline` before `--check` is rc 96 (`unknown option`).
5. **Commit the merge** with the two files, and push the branch (`git push`, no force).
6. **Wait for the checks** of the new head. The kit's repository has no CI workflow; the checks
   are the review bots and GitGuardian (`gh pr checks <PR>`). A finding a bot raises is answered on
   the branch, and the recipe restarts from step 1 if `main` moved meanwhile.
7. **Merge pinned to the head you measured:**
   `gh pr merge <PR> --merge --match-head-commit <sha>`, with `<sha>` the head you pushed in step 5.
   A merge commit, never a squash: the `RESOLVED by <hash>` of a mission only reaches `main` with
   its commits, and the post-merge chore proves each hash with `git merge-base --is-ancestor`.

Then the next PR of the queue starts again from step 1, against the `main` this merge produced.

## The post-merge chore of a mission

A mission that fixes findings writes `RESOLVED by <hash>` in each item and leaves the ratchet
where it was (the decided record "`RESOLVED by` does not let the ratchet go down in the mission
that fixes"). After its PR merges, on a new branch from `origin/main`:

1. For every hash, `git merge-base --is-ancestor <hash> origin/main` → rc 0. A hash that fails it
   did not reach `main` (a squash merge, say): prove the fix through the PR instead, or leave the
   item.
2. Delete each proven item from `TODO.md`.
3. `tests/check-todo.sh --count TODO.md` gives the new count; write it as `todo-findings <N>` in
   `tests/health-baseline.txt`, and run the three measures of step 4 above.
4. Commit both files, push, open the PR, and merge it through steps 6 and 7 above. When other
   finding PRs are queued, this one takes its place in the queue like any of them.
