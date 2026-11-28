# ADR 0024 — The gates at the end of the line read the head they check

- **Status**: accepted (—, 2026-11-21)
- **Spec**: docs/handoffs/20261121-l3-gates-do-fim-da-linha/00-missao.md
- **Amends**: 0023, decision 4. `gate_REVIEW` still checks the range from `reviewed_head:` to the
  commit that added the round. It now also reads the range from that commit to `HEAD`. Nothing
  else of 0023 changes.

## Context

Three gates at the end of the line answer for a head they never read.

- **`gate_PR` proves the pull request exists.** Its one question to `gh` is
  `gh pr view "$url" --json url --jq .url`. A push that failed leaves the pull request on the old
  commit with the gate green. The publisher runs `TEST_CMD` before the push (step 2) and writes
  `50-pr.md` after it (step 5), and the hat does not say whether that file goes into the pull
  request. In the kit it is committed after the push (`cec8c9b` in lot L2, `ad32508` in lot L1b),
  so the head of the pull request is a commit no check saw. In `lighthouse_project` the publisher
  left it out, and a coordinating session committed it, ran the gate again and published the
  status again.
- **`gate_REVIEW` reads the grade of the newest round, and stops at the round's own commit.**
  `review_head_ok` (0023) checks `reviewed_head:` up to the commit that added the round. Code
  committed after an approved round is not read by anything. In `lighthouse_project` the
  increments F5 to F8 and R3 landed after r2 graded A, and the human forced r3 and r4 with
  `--phase REVIEW`: 2 of the 6 interventions of that mission.
- **The K8 check of `gate_DOCS` measures `HEAD`, and calls it "the mission branch".** It never
  reads the `branch:` of `00-missao.md`. Measured in `warehouse_explorer_web`: the same merged
  mission read `✓` on `master` and `·` on a later branch with a commit of its own.

The kit already has the rule that closes the first two. `sdd-worker pr-ready` (0022 §5) and
`review_head_ok` (0023) accept, after the sha that was checked, only commits that touch the
mission directory.

## Decision

1. **One definition of the head of the mission.** `mission_tip` in `bin/sdd` prints `HEAD` when
   the checkout is on the `branch:` of `00-missao.md` (or the key is empty or the template's
   placeholder), and otherwise the tip of that branch, the local ref first and `origin/<branch>`
   second. When neither resolves it prints nothing. Two readers: `gate_PR` and the K8 check.
2. **`gate_PR` compares the head of the pull request with the head of the mission.** One call
   reads `url`, `state` and `headRefOid`. A pull request that is `MERGED` is not read further,
   the rule the `⛔` check already follows. An answer the gate cannot parse is its own refusal,
   never "the head differs". An open pull request whose `headRefOid` is not `mission_tip` is
   refused, with both shas in the reason. With no `mission_tip` the comparison is skipped.
3. **`50-pr.md` goes into the pull request, and records the sha that was checked.** The publisher
   writes `verified_head:`, the `git rev-parse HEAD` on which step 2 ran, commits the file in a
   commit that touches the mission directory alone, and pushes it. `gate_PR` refuses a
   `verified_head:` that is no commit, one the head does not carry, and one with a path outside
   the mission directory changed between it and the head. A record without the key passes, as a
   round without `reviewed_head:` does.
4. **`gate_REVIEW` reopens the phase for code committed after the round.** After `review_head_ok`,
   it lists the commits of the mission that came after the commit which added the round, the base
   excluded (`--not` the base refs), and reads the paths each one changed. A path outside
   `hat_writes REVIEW` and outside `hat_writes DOCS` in any of them refuses the round, and the
   reason names the commit and the path. The next round is a delta round (0023). A round without
   `reviewed_head:`, an uncommitted round and a mission already in the base (an empty range) pass
   as they do today. A merge of the base needs no rule: read commit by commit, a merge commit
   prints no path, and what it brought is in the base.
5. **The K8 check measures `mission_tip`.** The range, the merge-bases and the diff are read from
   it instead of `HEAD`. A branch that is gone or already in the base gives an empty range, which
   passes as it does today on the base branch. The reason names the branch it read.

## Alternatives discarded

- **Run step 2 again on the final head.** It is the literal reading of the finding. It costs one
  more suite in every PR phase (about ten minutes in the kit), and the record of that second run
  would be one more commit no check saw.
- **Keep `50-pr.md` out of the pull request.** The head stays equal to the checked sha, but the PR
  phase can no longer be derived on another machine, and the tree carries a file git does not
  track.
- **Let `gate_REVIEW` pass and name the later commits in its reason.** No loop and no cost. It is
  a label nobody has to read, and the round stays a manual `--phase REVIEW`.
- **Reopen REVIEW for any path outside the mission directory** (the rule of `pr-ready`). The DOCS
  phase writes outside it by design, so every mission would pay one more round after DOCS, and
  the open choice about prose written after the review (lot L6b of the campaign) would be made
  here by a side effect.
- **Read what a merge of the base brought.** It would reopen REVIEW with a full round (0023, rule
  6) for code another pull request already reviewed.
- **Only an empty range for the K8 check when `HEAD` is off the branch.** Simpler, but a mission
  that is not merged, read from another branch, would show `✓` without its entry.
- **Only rename the sentence of the K8 check.** Honest and cheap, and a merged mission would still
  read `·` on every later branch.

## Consequences

- Each new refusal has an owner inside the pipeline, as principle 1 asks. The publisher pushes,
  and rewrites `verified_head:` after running step 2 again. The reviewer writes the next round.
- A fix pushed while the pull request is open now buys two sessions: a delta round of REVIEW, and
  a publisher session that runs step 2 on the new head. In the kit, the stop with rc 2 for the
  mutation stamp comes after both.
- With positive `REVIEW_MAX_ITER`, REVIEW counts rounds in total. A mission at the ceiling that
  gets later code stops as `BLOCKED` in REVIEW, and the human forces the round as before, now
  with the reason written.
- `pr-ready` does not change. It stays stricter than the runner: after `reviewed_head:` it accepts
  the mission directory alone.
- **Declared limits.**
  - What the DOCS hat writes (`README.md`, `docs/**`, `templates/**`, `agents/**` and the rest of
    its `writes:`) does not reopen REVIEW, whoever committed it. A fix to a hat or to a template
    made after the round is not seen by this gate. Lot L6b owns that question.
  - The resolution of a merge of the base is not read by `gate_REVIEW`. `pr-ready` reads it.
  - `verified_head:` proves the publisher named a sha the head carries with no code after it. It
    does not prove the suite ran on that sha.
  - `gate_PR` compares with the local head of the mission. A checkout that is behind the remote
    reads a pull request that is ahead of it as a different head, and says so.
  - These gates judge the missions that come after this one: the run of this lot is judged by the
    runner on the PATH, the one from before it (0022 §7).
