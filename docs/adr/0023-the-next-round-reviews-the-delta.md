# ADR 0023 — The review round records the head it read, and the next round reviews only the delta

- **Status**: accepted (—, 2026-11-19)
- **Spec**: docs/handoffs/20261119-l1b-a-rodada-delta/00-missao.md
- **Amends**: 0022 §5. The `reviewed_head:` that `sdd-worker pr-ready` reads is no longer the
  worker's key alone: the runner's REVIEW phase writes it, reads it and checks it too. The rule of
  §5 does not change. `pr-ready` still wants the newest round to name the head, with only the
  mission's handoff directory changed after it.

## Context

Every REVIEW round re-reads the whole branch, and nothing records the head a round read.

- The reviewer hat says ``Invoke `/codereview:codereview` over the mission diff``
  (`agents/sdd-reviewer.md:46`). With no `base=`, the skill (2.30.1, the copy the harness registry
  records) reviews `git merge-base main HEAD..HEAD`. The same skill already takes `base=<sha>`, and
  its own rule for a re-review is "re-review the fix, not the branch".
- `phase_extra REVIEW` (`bin/sdd`) is a fixed heredoc. It tells the session no base and no head.
- `templates/review.md` has no `reviewed_head:`. The key exists only for the worker
  (`bin/sdd-worker`, `fm_value "$round" reviewed_head`, §5 of 0022), and `docs/pipeline.md` says so:
  "`reviewed_head:` is the worker's key, on purpose". So after a run the worker writes a round of
  its own, one above the runner's.

What that costs, measured:

- In the ledger, the REVIEW sessions of `20261117-o-worker-orquestrador` cost US$ 5.12 in 1 013 s
  (r1), US$ 6.31 in 1 287 s (r2), US$ 7.50 in 929 s (r3) and US$ 5.36 in 946 s (r4). A later round
  costs 1.0 to 1.5 times the first, though it only has the fixes to read.
- On pull request #414 the worker's rounds took about 1 h 30 each. The three delta rounds made by
  hand (r9, r10, r11) took 36 min, 37 min and 9 min, at 181 to 269 k tokens.
- A sentence did not hold. In r7 of #414 the briefing asked for the delta, the round got no
  `base=`, and it reviewed the whole branch. The delta holds when it is the skill's argument.

## Decision

1. **The round records the head it read.** The reviewer hat runs `git rev-parse HEAD` before it
   reads anything, and writes that sha as `reviewed_head:` in the round's frontmatter.
   `templates/review.md` names the key, the same one `pr-ready` reads. One fact, one key, two
   readers.
2. **The runner derives the base, in one definition.** `review_base_line` in `bin/sdd` reads the
   newest `40-review-r<N>.md` and prints one line. The first field is the contract:
   `base=<full sha>` (40 hex, or 64 in a SHA-256 repository) or `full`. The rest names the round or
   the reason, for the human. In order:
   - no round: `full`;
   - `git status` cannot say whether the round is committed (it fails): `full`. A status that
     fails proves nothing committed either;
   - the round is not committed (modified, staged, untracked or ignored): `full`. A session that
     wrote its round and died would otherwise hand the retry a base no finished round read;
   - no key: `full`;
   - the value is not a commit: `full`;
   - the commit is not an ancestor of `HEAD`: `full`;
   - a merge is in `<reviewed_head>..HEAD`: `full`;
   - otherwise: `base=` that commit.

   `phase_extra REVIEW` turns the line into the order the session follows:
   `/codereview:codereview base=<sha>`, naming the previous round as the list of open findings, or
   a full round with the reason. `sdd review-base <mission>` prints the same line. It runs no gate
   and no suite, and it is admitted without the checkout lock, so it writes nothing: the
   `git status` the second and third cases read runs with `GIT_OPTIONAL_LOCKS=0`, or it would take
   `index.lock` and rewrite the index under a session committing in the same checkout (r3 of the
   mission).
3. **A merge in the range makes the round full.** The skill reviews `base..HEAD`. A merge of the
   base branch would pour everything that came with it into the delta. Under `sdd run` nobody
   merges between rounds.
4. **`gate_REVIEW` checks a key that is present, and accepts one that is absent.** It refuses four
   cases, each naming the round:
   - a value that is not a commit;
   - a commit `HEAD` does not carry;
   - a path outside `hat_writes REVIEW` (the mission directory, the `TODO_FILE` and the ratchet)
     changed between that commit and the round's own commit;
   - a range `git diff` cannot list. The gate fails closed: a round it cannot read does not pass.

   The check is cheap and runs before the suite. A round without the key passes as it does today,
   and the next round is full.
5. **In a delta round, a finding in code the delta did not touch goes to the `TODO_FILE`, never to
   an `R<n>`.** The one read outside the delta is a grep for the old spelling of an interface the
   delta changed. Without the rule, a delta round would still open an increment for a LOW outside
   it, and would cost what a whole round costs.
6. **The worker's `review` act uses the same delta, through the runner.** It runs
   `sdd review-base <mission>` after it merges the base, and passes the line to its subagent.
   `bin/sdd-worker` gains no copy of the judgment.

## Alternatives discarded

- **A sentence in the briefing or in the hat ("review only the delta").** Nothing to build, and it
  already failed once: r7 of #414.
- **Keep the key the worker's, and the runner's rounds full.** No contract changes. Every later
  round of every mission keeps costing 1.0 to 1.5 times the first.
- **A second key for the runner** (`base:` or `head:`). It avoids touching what §5 of 0022 reads,
  but gives one fact two names, with two parsers that can disagree.
- **Refuse a round with no key.** Stricter, but every mission in flight (the L1 lot, the target
  repositories) would go back to REVIEW for a key its runner never asked for. That gate is
  unsatisfiable for the rounds already written.
- **Trust the key as written.** One check fewer. But the key is then a label the model writes: a
  sha the branch does not carry, or one older than the code the round read, would make the next
  round skip code nobody reviewed.
- **Review across a merge with a first-parent delta.** `base=` is one sha, and the skill reviews
  `base..HEAD`. No argument it takes says "skip what the merge brought".
- **Give `bin/sdd-worker` its own copy of the judgment.** It avoids a call into the runner. But it
  makes two definitions of one rule, which the kit refuses for every enum read in two places.

## Consequences

- From the second round on, a REVIEW round reads `base..HEAD` and the findings the previous round
  left open. The first round stays whole, and a round after a merge or after a round without the key
  is whole again, with the reason in the prompt.
- The artifact has an owner, as principle 1 asks. The `sdd-reviewer` hat writes the round and the
  key, so the new refusal of `gate_REVIEW` is satisfiable by the phase it judges.
- `pr-ready` does not change. A runner round now carries the key, but the DOCS phase commits
  outside the mission directory after it. So after a run the worker still writes its own round,
  and that round is now a delta round too.
- **Declared limits.**
  - The key proves that the round named a head the branch carries and that no outside code
    changed after it. It does not prove that the session read that head: a round that writes the
    right sha over a review of something else passes.
  - The rule on findings outside the delta is hat prose, not a gate. Nothing counts the `R<n>` a
    delta round opens for code it did not touch.
  - The worker merges the base before every round. With a merge in the range, that round is full
    whenever the base moved. Changing the order of the act is out of this decision.
  - The number this decision is for (later rounds at half the first, or less) is not measured
    here. This mission's own REVIEW runs on the runner from before it (0022 §7), so the "after" is
    read from the ledger in the next lot of the campaign.
