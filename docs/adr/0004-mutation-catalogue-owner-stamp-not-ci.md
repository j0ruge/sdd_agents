# 0004 — The mutation catalogue gets an owner: a content-keyed stamp, not CI

Date: 2026-08-19 · Status: accepted

## Context

`4c86712` made the mutation catalogue **opt-in**: `TEST_CMD` stopped running it, and `sdd health`
became its single caller. That change was right and is not re-litigated here — verifying every
mutant re-runs the whole suite in a sandbox, which held the working tree for more than ten minutes
per gate and made the REVIEW phase unsatisfiable headless. Three consecutive REVIEW sessions ended
their turn with the words *"waiting for the suite"*, and in `claude -p` ending the turn ends the
session: US$ 104 of review that bought no review.

What it left behind is the subject of this record. The one instrument that measures whether the
suite's assertions still bite had **no automatic owner**, and this repo has no CI. The bill arrived
between PR #12 and PR #13, and it is fact rather than fear:

```
f6ecf73 rotted the anchor of mut_HEALTH_grade_table_blind
  → the REVIEW and PR gates ran the fast suite, answered green
  → the base branch carried `score: 103 caught, 0 known gap(s), of 104` for days
  → only `sdd health` saw it, because a human happened to type the command
```

The gate said green about a catalogue nobody had run. That is this repo's most expensive failure
mechanism — a label accepted in place of an artifact — inside the instruments that exist to refuse
labels.

## Decision

**The `PR` gate demands the catalogue's green as an artifact on disk.** Four parts, and each one
exists to keep a specific alternative from being tried again:

1. **The gate does not RUN the catalogue — it demands the stamp.** `sdd health` writes
   `.sdd/logs/mutation-stamp` when, and only when, the full suite and the `score:` line both came
   back green; `gate_PR` refuses while no stamp matches the current content. Running the catalogue
   inside a gate is precisely what `4c86712` undid, and re-buying it here would re-buy the
   unsatisfiable phase along with it.

2. **The key is the CONTENT of `bin/ tests/ templates/ config/`, never `HEAD`.** Those four are
   what decides a mutant's fate: the runner the mutants edit, the assertions that judge them, and
   the templates and config those assertions read. Keying on `HEAD` would throw a perfectly valid
   stamp away at the DOCS and PR commits, which move the `HEAD` without moving a byte the catalogue
   measures.

3. **The requirement is scoped by ARTIFACT, never by the identity of the repository.**
   `has_mutation_catalogue` asks one question — does `tests/check-mutation.sh` exist under this
   root? — and both ends ask it. A target repo has no catalogue, so nothing changes there. The
   identity door the kit already owns (`cmd_kaizen`) carries a live worktree bug in `TODO.md`;
   inheriting it would have been buying a known defect.

4. **Writer and reader address the same tree, resolved once.** This is not a refinement, it is a
   defect the mission had to pay for: the writer stamped `$SDD_HOME` while the gate asked about
   `$REPO_ROOT`, and those diverge exactly in the install `README.md` documents (`sdd` on the
   `PATH`, standing in a worktree or a second clone). `gate_PR` was unsatisfiable **forever**, and
   the command its own refusal names as the remedy re-measured the wrong tree, twenty to fifty
   minutes a lap. Fixed in `1dc713f` by `health_kit_root`, which resolves the tree once.

The refusal names the command that resolves it: `no green mutation catalogue for this content —
run 'sdd health'`. A gate that stops the line without naming the remedy is Jidoka half-done.

**Discarded: CI running `tests/run-all.sh --with-mutation`.** It is the other exit the backlog item
names and it would work. It is not taken here because it costs a human budget decision (a private
repo, and a full round measured at 20 to 50 minutes on this machine), because the kit refuses
infrastructure by YAGNI, and above all because it is **not exclusive**: the stamp closes the hole
from inside the kit today, and CI can be added later without touching any of it. The decision stays
with the human, in `TODO.md`.

**Discarded: keying the stamp on every path `sandbox()` copies.** The sandbox also copies
`agents/`, `CLAUDE.md`, `TODO.md` and `docs/adr`. Including them would invalidate the stamp between
the last code commit and the gate that reads it, because the DOCS phase edits exactly those files
on its way to the PR — a second twenty-minute run per mission, bought for documents no mutant
edits. The narrowing is 4 of 8 paths, and the residual gap is recorded in `TODO.md` rather than
hidden in a comment.

**Discarded: trusting the score line as it was.** Two thirds of this decision would have been
theatre without `7a6653b`: the health check accepted `0 known gap(s)` and never compared `caught`
against `of`, so a catalogue with a live survivor printed `ok`. Stamping before fixing that would
have written the certification of a red catalogue to disk. The ordering was a real dependency, not
a preference.

## Consequences

- **`sdd health` runs after the last code commit, and running it earlier wastes a round.** Editing
  `CLAUDE.md`, `CONTEXT.md`, `docs/` or `TODO.md` does not invalidate the stamp;
  `tests/health-baseline.txt` does — and that is where the backlog ratchet lives, so honouring
  principle 5 (an out-of-scope finding becomes an item) costs the stamp. The collision is in
  `TODO.md` with its direction; the symptom and the way out are in `docs/failure-modes.md`.
- **`gate_PR` became unsatisfiable for anyone who does not run the catalogue, and that is the
  point.** The line stops, Jidoka, with the command in the message. What must never happen is
  stopping without naming it.
- **The stamp is removed, never merely left behind, when the catalogue comes back red** or when the
  tree moved while it ran. A stamp that outlives the green it certifies is the exact label this
  record exists to replace.
- **Nothing changes in a target repo.** No `tests/check-mutation.sh`, no requirement, no new
  message — verified by the differential world that exercises that branch in `tests/check-gates.sh`.
- The catalogue itself remains opt-in and outside `TEST_CMD`. Every gate still asks the fast
  question; only the last gate of a mission asks for the slow one's receipt.
