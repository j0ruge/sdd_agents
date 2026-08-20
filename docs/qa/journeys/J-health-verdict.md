# J-health-verdict — Ask the kit whether it still measures what it claims

`sdd health` answers *"do the kit's own instruments still work?"*. Since `4c86712` it is also the
**only** place the mutation catalogue runs, and since this cycle's I4 the only writer of the stamp
`gate_PR` demands. Three responsibilities, one verdict line.

```mermaid
flowchart TD
    A[Entry: operator types ./bin/sdd health] --> B[key_before = md5 of bin/ tests/ templates/ config/]
    B --> C[Check 1: the fast suite]
    C --> D[Check 2: run the mutation catalogue — 20 to 50 min]
    D --> E{does the score line parse?}
    E -->|no| E1[Refuse: health went blind to the mutation] --> Y
    E -->|yes| F{gaps == 0?}
    F -->|no| F1[Refuse: mutation with an open gap] --> Y
    F -->|yes| G{caught == total?}
    G -->|no| G1[Refuse: N of M caught — K survivors, assertions the suite does not have] --> Y
    G -->|yes| H[ok: score N caught, 0 known gaps, of N]
    H --> I[Check 2b: does the kit TEST_CMD actually run anything?]
    I --> I1{TEST_CMD carries --list?}
    I1 -->|yes| I2[Refuse: that mode exits 0 having run NOTHING] --> Y
    I1 -->|no| J[Check 2c: the stamp]
    J --> K{key_after == key_before?}
    K -->|no| K1[Refuse: the measured tree moved WHILE the catalogue was running. Side effect: any existing stamp is REMOVED] --> Y
    K -->|yes| L[Side effect: stamp written to .sdd/logs/mutation-stamp]
    L --> M[Checks 3-12: TODO ratchet, doc drift, agent mirrors, fixtures]
    M --> N{any health_bad?}
    N -->|yes| Y[Verdict: kit NOT healthy, rc 1, every reason listed]
    N -->|no| O[Verdict: kit healthy, rc 0]
    O --> P[True end: gate_PR of a mission in this tree passes without re-running anything, and the operator can re-derive the key by hand]

    D -.->|Ctrl-C at minute 30| X1[Abandon-A: no verdict, no stamp; any PREVIOUS stamp survives untouched]
    D -.->|headless session turn ends| X2[Abandon-B: background run dies mid-pool; log stops inside 'mutants pool of 8', no score line]
    G1 -.->|operator ships anyway| X3[Abandon-C: survivor left in the catalogue; no stamp, so gate_PR keeps refusing — the loop closes]
```

```yaml
journey:
  id: J-health-verdict
  name: Ask the kit whether it still measures what it claims
  value_statement: "One command answers whether the kit's instruments are still honest, and the answer is re-derivable from disk rather than asserted."
  personas: [Mara, Ada]
  entry_points:
    - url: "./bin/sdd health"
      origin: direct
    - url: "tests/run-all.sh --with-mutation"
      origin: direct
  actions:
    - step: 1
      verb: Run the health command on a clean tree
      expected_observable: "Numbered checks stream by, each as `  ok    <assertion>` or `  FAIL  <assertion>`"
    - step: 2
      verb: Read the mutation score line
      expected_observable: "score: N caught, 0 known gap(s), of N — and the two numbers are compared, not just printed"
    - step: 3
      verb: Read the stamp line
      expected_observable: "mutation stamp written — gate_PR can see that THIS content ran green"
    - step: 4
      verb: Read the final verdict
      expected_observable: "kit healthy with rc 0, or every failing reason listed with rc 1"
  goal:
    observable: A verdict that is false whenever any instrument has stopped measuring
    side_effects: [stamp-written, stamp-removed-on-failure, todo-ratchet-read]
  true_end_state: >
    `kit healthy` is printed only when every check measured something real. Specifically: a
    catalogue with a survivor, a catalogue too small to have measured anything, an unparseable
    score line, and a TEST_CMD that runs nothing must each turn the verdict red — and on any red,
    no stamp may remain on disk.
  exit:
    natural: The operator either proceeds to the PR phase or has a named instrument to repair.
  abandonment:
    - at_step: 1
      how: Ctrl-C during the 20-50 minute catalogue.
      resume: "Nothing was written; a stamp from an earlier run is still there. Whether that surviving stamp is stale is the question — it is keyed on content, so it is valid only if the tree has not moved."
    - at_step: 2
      how: A headless session starts the run in the background and its turn ends; the run dies mid-pool.
      resume: "The log stops inside `mutants (pool of 8)` with no score line. Measured twice in this mission: /tmp/sdd-baseline-score.txt and /tmp/sdd-health-final.log."
    - at_step: 3
      how: A commit lands while the catalogue is running.
      resume: The window guard refuses, removes the stamp, and says the operator's own commit is why — a re-run is the only exit.
  crosses: [cmd_health, tests/check-mutation.sh, tests/run-all.sh, gate_PR, tests/health-baseline.txt, TODO.md]
```

## Notes

Every `  ok    ` / `  FAIL  ` pair prints the **same** assertion text on different streams. That is
the contract the checkpoint Checks anchor on (`^  ok    `, four spaces) and it is what makes Ada's
question answerable: the words carry the verdict, not a colour. Any new line added to this command
inherits that contract.

The 20-50 minute runtime is the journey's dominant constraint and the source of two of its three
abandonment paths. It is not a defect — it is the price of the catalogue — but every surface that
*depends* on this journey completing inherits the risk.
