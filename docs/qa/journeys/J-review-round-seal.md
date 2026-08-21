# J-review-round-seal — Seal a review round with grades a sentence supports

The REVIEW phase closes when `40-review-r<N>.md` carries an Overall Grade table of `A`s. This
cycle's I3 made the gate read the column next to the grade, so an `A` has to be *earned by a
sentence* rather than typed.

```mermaid
flowchart TD
    A[Entry: sdd-reviewer session finishes a review round] --> A1{how many rounds are already on disk?}
    A1 -->|at or above REVIEW_MAX_ITER, derived path| A2[No session opens at all: BLOCKED, exit 3 — walked in J-trouble-stops-the-line]
    A1 -->|below| B[Writes docs/handoffs/mission/40-review-rN.md]
    B --> C[./bin/sdd run mission reaches gate_REVIEW]
    C --> C1{is the separator row a separator?}
    C1 -->|formatter wrote :---: and the skip does not match it| C2[The separator becomes a criterion called ':' graded '---'] --> Z
    C1 -->|yes| D{Overall Grade section present?}
    D -->|no| D1[Refuse: the gate has nothing to measure] --> Z[Reviewer rewrites the round]
    D -->|yes| E{any row whose Grade is not A?}
    E -->|yes| E1[Refuse: criterion = B] --> Z
    E -->|no| F{any A whose Rationale is a placeholder?}
    F -->|yes: empty, angle-brackets, ellipsis, PREENCHER, TODO, TBD, FIXME, XXX| F1[Refuse: criterion has Grade A with a placeholder Rationale — a grade no sentence supports is a label] --> Z
    F -->|no| G{gate frontmatter present AND a placeholder?}
    G -->|yes| G1[Refuse: that field carries the evidence the round closed, not the shape of it] --> Z
    G -->|absent — 6 of 14 rounds on disk| H[Left alone on purpose: refusing would rewrite history]
    G -->|filled| H
    H --> I[gate_REVIEW passes]
    I --> J[Side effect: the round becomes the mission review evidence, quoted into 50-pr.md by the PR phase]
    J --> K[True end: a human opening the PR reads a rationale per criterion and can check each claim against the diff]

    F1 -.->|reviewer retypes a dash or TODO-colon instead of a sentence| X1[Abandon-A: the placeholder set is compared by string equality, so one keystroke buys the A]
    E1 -.->|reviewer raises the grade instead of fixing the code| X2[Abandon-B: round N+1 is all A with real sentences about work never done]
    B -.->|session dies before writing the file| X3[Abandon-C: no round file; the phase re-derives and a fresh round starts from zero]
    A -.->|the session copies the exemplar out of agents/sdd-reviewer.md| X4[Abandon-D: the exemplar showed eight angle-bracket Rationales — the exact form the gate refuses]
```

```yaml
journey:
  id: J-review-round-seal
  name: Seal a review round with grades a sentence supports
  value_statement: "The A on a review round means a reviewer wrote down why, and a human can check the why against the diff."
  personas: [Sessão, Mara]
  entry_points:
    - url: "./bin/sdd run <mission>"
      origin: in-app-nav
    - url: "./bin/sdd why <mission> REVIEW"
      origin: direct
  actions:
    - step: 1
      verb: Write the round file with an Overall Grade table
      expected_observable: One row per criterion, Grade and Rationale both filled
    - step: 2
      verb: Let the gate read it
      expected_observable: Either a pass, or one sentence naming the offending criterion and what is wrong with it
    - step: 3
      verb: Fill the frontmatter gate field with the round's closing evidence
      expected_observable: A filled field passes; a placeholder one is named and refused
  goal:
    observable: gate_REVIEW passes only when every A has a rationale a human can disagree with
    side_effects: [round-quoted-into-pr-body]
  true_end_state: >
    The PR body carries the round's grades AND the sentences behind them, so a reader who never saw
    the review session can check each claim against the diff without asking anyone.
  exit:
    natural: The mission proceeds to DOCS with a reviewable record of what was examined.
  abandonment:
    - at_step: 2
      how: "The reviewer meets the refusal and types the shortest thing that gets past it — a dash, TODO-with-colon, a full stop, WIP."
      resume: "None: the gate accepts it. placeholder() compares the whole cell by string equality against a closed set, so anything outside that set passes. Filed as BUG-20260819-punctuated-rationale-buys-an-a."
    - at_step: 2
      how: The reviewer raises grades rather than fixing what round N found.
      resume: The gate cannot see this; only a human reading the rationales can. It is why the rationale column has to be readable.
    - at_step: 1
      how: The session dies before writing the file.
      resume: The phase re-derives from disk, finds no round, and a fresh session starts — losing the round's findings entirely.
    - at_step: 1
      how: "The session copies the table straight out of agents/sdd-reviewer.md, which is what an exemplar is for."
      resume: "Until `346b0a2` the exemplar's eight Rationale cells were all `<…>` — the exact form the gate refuses. The session produced the artifact the agent showed it and the gate refused it, so the phase looped on a sentence the kit itself taught it to write."
    - at_step: 1
      how: A formatter (prettier, markdownlint) rewrote the round's separator row with alignment colons.
      resume: "Until `db26cc1` the separator became a criterion named `:` graded `---`, and REVIEW looped to REVIEW_MAX_ITER with a GATE_WHY naming no criterion anybody wrote. Nothing in the kit writes those colons; an adopter's formatter does."
  crosses: [gate_REVIEW, review_rounds_on_disk, agents/sdd-reviewer.md, templates/review.md, the codereview skill report template, 50-pr.md]
```

## Notes

The legitimate short rationales are `clean`, `n/a` and `—` (em dash) — the `codereview` skill's own
shorthand for *"measured, nothing to say"*. Refusing them would make the gate contradict the skill
it parses. Any new placeholder rule must be probed against `—` **before** shipping: `mawk` is
byte-oriented and the em dash is `E2 80 94`, so a `[[:punct:]]` class over it matches by bytes.

⚠️ **The same table is parsed by `awk -F'|'`, and GFM escapes a literal pipe inside a cell as `\|`.**
The parser does not know that escape. It was harmless while only Grade was read, and became a
refusal the moment the Rationale column turned into a verdict — a real justification reported as a
placeholder and a round blocked for a reason that is not true (`53586c5`). Anything that starts
reading a new column of this table inherits the problem: reassemble the columns first.

The checkpoint table in every mission has the identical trap, documented in its own header. Two
parsers, one repo, same byte.

⚠️ **Update (branch `20260820-missao-porteira`).** Three things in this journey moved and the flow
above carries them:

1. **The escape is now understood on both sides.** `checkpoint_rows` grew the same
   `escaped_pipe()` + rejoin this gate already had (`5434a65`), deliberately duplicated with a
   cross-reference comment — a shared helper would collapse two mutation anchors into one, which is
   the class the stamp caught between PRs #12 and #13.
2. **Alignment colons stopped being data** (`db26cc1`): `/^:?-+:?$/` in all three parsers. The
   REVIEW half is the one walked here; the EXEC and DOCS halves are in
   [`J-checkpoint-survives-a-formatter`](J-checkpoint-survives-a-formatter.md).
3. **The round may never start.** `REVIEW_MAX_ITER` now counts rounds *in total* off the
   `40-review-r<N>.md` files on disk (`d3dea51`), so a mission that spent its rounds is refused
   before a session opens. That branch is walked in
   [`J-trouble-stops-the-line`](J-trouble-stops-the-line.md); it appears in this flowchart only as
   the entry condition, because it changes whether this journey is reachable at all.
