# ADR 0025 — The allocator reads every ref and worktree, and a merged pull request is the second proof of a resolution

- **Status**: accepted (—, 2026-11-21)
- **Spec**: docs/handoffs/20261121-l5-saida-humana-e-contrato-do-runner/00-missao.md
- **Amends**: 0008, the allocator. The id is still MAX+1, a gap is still never reused, and the
  reservation is still `O_EXCL`. What changes is where the maximum is read from. Nothing else of
  0008 changes.

## Context

Two contracts of the kit rest on one checkout seeing everything, and it does not.

- **`sdd adr new` reads one directory.** `adr_next_id` takes MAX+1 over the `ADR_DIR` on the disk
  of the checkout it runs in. A mission planned on a branch cut from the base does not see the ADR
  another unmerged branch already wrote. Measured in `dotp-remake`: missions 6a (ADR 0026) and 7a
  (ADR 0027) were on unmerged branches, and `sdd adr new` for 7b, cut from `main`, would have handed
  out 0026 again. The planner created two empty files to skip the numbers, deleted them, and got
  0028. It happened again in two later missions of the same repository. Without that hand work the
  collision shows up only at the merge. Reading the ADR directory of every ref is cheap: 0.44 s
  over the 158 refs of the kit's own clone.
- **A `RESOLVED by <hash>` leaves the backlog on one proof.** The lifecycle in `templates/todo.md`
  deletes a resolved finding once `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>` holds. In
  a repository that squashes, the branch's hash never becomes an ancestor of the base, and the item
  stays forever: four items were stuck in `sales_quote` after two squashed pull requests. No proof
  made of git alone exists there, because the squash commit does not keep the commits it joined.
  And nothing lists the items that can go: after `warehouse_explorer_web#8` five resolved items
  left only because a handoff remembered them.

`CLAUDE.md` of the kit says the deletion is "proved by `git merge-base --is-ancestor`, never by the
label of the PR". The rule behind that sentence is principle 1, artifact and never label, and the
same principle already counts `gh pr view` as reading an artifact: `sdd close` decides "post-merge"
by it, and `gate_PR` reads the head of the pull request from it.

## Decision

1. **The allocator reads three places.** `adr_next_id` takes the maximum over the `ADR_DIR` on the
   disk of the checkout, the `ADR_DIR` of every ref under `refs/heads` and `refs/remotes`
   (`git ls-tree`), and the `ADR_DIR` on the disk of every other worktree of the repository. Only
   regular files directly in that directory count. Every name passes the same `ADR_FILE_RE`.
   When the maximum comes from outside the checkout,
   `sdd adr new` says which ref or worktree carries it, on stderr, in the real run and in
   `--dry-run`. Outside a git repository, and for a ref git cannot read, that source contributes
   nothing and the allocation goes on. If Git rejects NUL output for the worktree list, the
   allocator falls back to line-delimited porcelain. On Git 2.31–2.35 that format cannot reliably
   represent a worktree path containing a newline.
2. **Two proofs let a resolved finding go, and both are commands.** The first is the one of today:
   `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>`. The second is
   `git merge-base --is-ancestor <hash> <head of the pull request>` together with the state
   `MERGED` of that pull request, read from `gh` at that moment. A text that says "merged" proves
   nothing. The token `RESOLVED by <hash>` and the grammar of the `TODO_FILE` do not change. The
   two templates state both proofs and the command that finds the pull request of a hash
   (`gh pr list --search <hash> --state merged`).
3. **`sdd close` lists what the merge resolved, and deletes nothing.** After it comes home to the
   base, it lists the open items whose every `RESOLVED by` hash passes one of the two proofs. The
   second proof is read against the head of the mission's own pull request, the one this close just
   saw `MERGED`. The items are read by `tests/check-todo.sh --resolved`, the parser that already
   knows where the open section ends, so the runner gains no second parser of the file. It omits
   examples in inline or fenced code and any item with a malformed resolution value outside code.
   The runner resolves each remaining hash to a unique
   local commit object before checking either proof, without interpreting the hash as a ref name.

## Alternatives discarded

- **`sdd adr new --after <n>`.** The smallest change. It works only when the planner already knows
  another branch took the number, which is what failed three times.
- **Both the automatic reading and `--after`.** It covers a branch that was never pushed from
  another machine, at the price of one more flag to keep and to prove. The limit is declared
  instead.
- **Declare that the lifecycle needs a merge commit.** The cheapest, and it matches how the owner
  merges his own repositories. A repository that squashes keeps every resolved item forever.
- **Change the token to carry the pull request** (`RESOLVED by <hash> (PR #N)`). The proof would
  be written in the item itself. It changes the grammar of the `TODO_FILE` in every target and in
  the sensor, with missions in flight, and what it writes is a label.
- **Let `sdd close` delete the items and commit.** It closes the loop alone. It is the runner
  committing straight into the base, and a wrong proof deletes a finding with no review.

## Consequences

- A number used only on a branch that was never pushed from another machine is still invisible,
  and that collision still shows up at the merge. The comment of `adr_next_id` says so.
- An abandoned branch that carries an ADR burns its number for good. That is the rule 0008 already
  has for a gap.
- Under a squash, `sdd close` lists the hashes of its own mission only. A hash another mission
  wrote is found by hand, with the command the templates give.
- The head of a pull request that is not in the local repository proves nothing: the item is not
  listed. The check fails closed.
- The sentence of `CLAUDE.md` that names one proof is the owner's text. The DOCS phase of the
  mission proposes the new sentence, and it changes only by his hand.
- The `todo-to-github-issues` skill lives in another repository and still deletes on the first
  proof alone. Until it is retrofitted it is stricter than the templates: it never deletes too
  much, it only stops deleting under a squash.
