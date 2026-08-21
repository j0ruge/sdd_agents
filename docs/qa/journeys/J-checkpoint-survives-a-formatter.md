# J-checkpoint-survives-a-formatter — Run a markdown formatter over the repo and keep the mission moving

The kit parses its own artifacts as tables. Every adopting repo has a formatter — prettier,
markdownlint, an editor plugin, a pre-commit hook — and formatters rewrite tables: they add
alignment colons to separator rows, and authors escape pipes inside cells as `\|` because that is
what GFM requires. Neither is a mistake. Both used to make the runner refuse a mission for a reason
nobody wrote.

The failure shape is what makes this journey worth its own file: the runner does not crash and does
not go quiet. It reports a **plausible and wrong** state, and the operator's next move is to go
looking for a defect that is not there.

```mermaid
flowchart TD
    A[Entry: Priya runs prettier over her repo, or writes a Check that needs a pipe] --> B[checkpoint.md is rewritten: separator becomes :---:, a cell carries \\|]
    B --> C[sdd run derives the phase, gate_EXEC reads the table]
    C --> D{does the parser skip a separator that carries alignment colons?}
    D -->|no| D1[The separator becomes a ROW: id :---, status :---:] --> E1[Refused: invalid status — a status nobody wrote]
    D -->|yes| E{does the parser rejoin the GFM escape \\| ?}
    E -->|no| E2[The cell splits: every column after it shifts one left] --> E3[Status is read from INSIDE the command, Commit reads pending] --> E1
    E -->|yes| F[Columns land where the author put them]
    F --> G[gate_EXEC judges the statuses the author actually wrote]
    G --> H[sdd status prints the same table the gate judged]
    H --> I[True end: the phase the runner names is the phase the artifacts justify, and status and gate agree]

    E1 -.->|the operator believes the refusal| X1[Abandon-A: hunts a defect that is not there. sdd status looks healthy, which is what makes this expensive]
    B -.->|the same formatter runs over 45-docs.md| X2[Abandon-B: gate_DOCS reads :---: as a pending Status and refuses a clean drift checklist]
    B -.->|the same formatter runs over 40-review-r N .md| X3[Abandon-C: gate_REVIEW grades a criterion called ':' — covered in J-review-round-seal]
    F -.->|the Check really does need a pipe| X4[Abandon-D: the runner now understands it, and the kit's own sensor still refuses it — herestring is the form]
```

```yaml
journey:
  id: J-checkpoint-survives-a-formatter
  name: Keep a mission readable after a formatter rewrites its tables
  value_statement: "An adopter's ordinary tooling — a formatter, a GFM escape — does not stop the pipeline or make it lie about where the mission stands."
  personas: [Sessão, Priya]
  entry_points:
    - url: "sdd run <mission>"
      origin: direct
    - url: "sdd status <mission>"
      origin: direct
    - url: "sdd why <mission> EXEC"
      origin: in-app-nav
  actions:
    - step: 1
      verb: Let a formatter rewrite the mission's markdown tables
      expected_observable: Nothing about the mission's state changes
    - step: 2
      verb: Write a Check whose command contains a pipe, escaped as GFM requires
      expected_observable: The Status column still reads the status
    - step: 3
      verb: Ask the runner where the mission stands
      expected_observable: sdd status and gate_EXEC describe the same table
  goal:
    observable: The phase the runner derives is the one the artifacts justify, before and after formatting
    side_effects: []
  true_end_state: >
    The same mission, formatted and unformatted, answers the same `sdd phase`. Compared to EACH
    OTHER rather than to a literal: the two answers are the assertion, because a runner that refused
    both would satisfy any single-sided check.
  exit:
    natural: The mission advances to the phase it was going to advance to anyway.
  abandonment:
    - at_step: 1
      how: The operator believes "invalid status" and starts hunting the increment.
      resume: "There is nothing to find. `sdd status` prints something that looks healthy next to the refusal, which is what makes this cost a session rather than a minute."
    - at_step: 2
      how: The Check genuinely needs a pipe.
      resume: "The runner rejoins the escape, so the mission is not blocked — but the kit's own tests/check-checkpoint.sh still refuses BOTH forms in this repo's checkpoints, because a herestring is plainly better. The rejoin is a safety net for what target repos write, not a licence for what this repo writes."
    - at_step: 1
      how: The formatter touched 45-docs.md instead of checkpoint.md.
      resume: "Same three-character blindness, different gate: gate_DOCS read the separator's Status cell as a pending status and refused a checklist with nothing pending in it."
  crosses: [checkpoint_rows, gate_EXEC, gate_DOCS, sdd status, tests/check-checkpoint.sh, templates/checkpoint.md]
```

## Notes

**One regex, three parsers, three different lies.** `/^:?-+:?$/` replaced `/^-+$/` in
`checkpoint_rows`, `gate_REVIEW` and `gate_DOCS`. The REVIEW half is walked in
[`J-review-round-seal`](J-review-round-seal.md); the EXEC and DOCS halves are here. Splitting them
across journeys is deliberate — the persona and the moment differ (a review round is read by Mara
closing a mission; a checkpoint is read by the headless session deciding what to do next).

**Nothing in the kit writes these colons**, which is exactly why no fixture had them until this
branch and why the bug survived fourteen missions. The trigger is somebody else's tooling, and the
first adopter to run prettier finds it.

**Deliberate skip, recorded:** the `\|` half is not walked in a *target* repo this cycle. The parser
is the same code on both sides and the kit's own checkpoints are the harder case (the sensor refuses
the form outright there). If the pilot's `sales_quote` checkpoints acquire a pipe, that becomes its
own scenario.
