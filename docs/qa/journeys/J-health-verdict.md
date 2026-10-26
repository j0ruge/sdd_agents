# J-health-verdict — Ask the kit whether it still measures what it claims

`sdd health` answers *"do the kit's own instruments still work?"*. Since `4c86712` it is also the
**only** place the mutation catalogue runs, and since this cycle's I4 the only writer of the stamp
`gate_PR` demands. Since `20261026-health-pula-catalogo` (ADR 0021) the stamp is a set of keys
measured green in `<git-common-dir>/sdd-mutation/stamps/`, and the command skips the catalogue over a
key already in it. Three responsibilities, one verdict line.

```mermaid
flowchart TD
    A[Entry: operator types ./bin/sdd health] --> B[key_before = md5 of the tracked bin/ tests/ templates/ config/ agents/, minus the ratchet]
    A2["Entry: ./bin/sdd health --full --release"] --> A3["Refuse by name: --full measures the catalogue, and --release never runs the suite — pick one"]
    B --> S{"key_before in the stamps, and no --full?"}
    S -->|yes| S1[Check 1: the fast suite only; red is refused and the key stays]
    S1 --> S2["ok: mutation: catalogue skipped — key measured green, with its provenance; ./bin/sdd health --full measures it again"]
    S2 --> I
    S -->|no| C[Check 1: the suite with the catalogue; a red control is refused and removes nothing]
    C --> D[Check 2: the mutation catalogue — hours: 10 h 58 for 775 mutants with no killer map, PR #327]
    D --> E{does the score line parse?}
    E -->|no| E1[Refuse: health went blind to the mutation] --> I
    E -->|yes| E2{"of == the mut_* definitions, and above the floor?"}
    E2 -->|no| E3[Refuse: the catalogue ran N of the M defined. The catalogue speaks against the key] --> I
    E2 -->|yes| F{gaps == 0?}
    F -->|no| F1[Refuse: mutation with an open gap. The catalogue speaks against the key] --> I
    F -->|yes| G{caught == total?}
    G -->|no| G1[Refuse: N of M caught — K survivors or TIMED-OUT, assertions the suite does not have. The catalogue speaks against the key] --> I
    G -->|yes| H[ok: score N caught, 0 known gaps, of N]
    H --> I[Check 2b: does the kit TEST_CMD actually run anything?]
    I --> I1{TEST_CMD carries --list?}
    I1 -->|yes| I2[Refuse: that mode exits 0 having run NOTHING] --> J
    I1 -->|no| J[Check 2c: the stamp]
    J --> K{key_after == key_before?}
    K -->|no| K1[Refuse: the measured tree moved WHILE the catalogue or the suite was running. Nothing written, no key taken away] --> M
    K -->|yes| K2{what did the catalogue say about this key?}
    K2 -->|against it: census, gap, survivor, TIMED-OUT| K3[Side effect: the key file is REMOVED] --> M
    K2 -->|skip, red suite over a clean score, no score| K4[Nothing written, nothing removed: the key stays as it was] --> M
    K2 -->|green, suite and score| L[Side effect: key written to git-common-dir/sdd-mutation/stamps/key — first line the key, then measured:, root:, score:]
    L --> M[Checks 3-12: TODO ratchet, doc drift, agent mirrors, fixtures]
    M --> N{any health_bad?}
    N -->|yes| Y[Verdict: kit NOT healthy, rc 1, every reason listed]
    N -->|no| O[Verdict: kit healthy, rc 0]
    O --> P[True end: gate_PR over this content passes in any checkout of the clone without re-running anything, the next health over it skips the catalogue, and the operator can re-derive the key by hand]

    D -.->|Ctrl-C in the middle| X1[Abandon-A: no verdict, nothing written or removed; a key already in the set survives untouched]
    D -.->|headless session turn ends| X2[Abandon-B: background run dies mid-pool; log stops inside 'mutants pool of 8', no score line]
    G1 -.->|operator ships anyway| X3[Abandon-C: survivor left in the catalogue; its key removed or never written, so gate_PR keeps refusing — the loop closes]
```

Every refusal above says its verdict and the run carries on to the next check; the verdict line
(`N`) collects them. That is why a catalogue verdict reaches check 2c, where it removes the key.

```yaml
journey:
  id: J-health-verdict
  name: Ask the kit whether it still measures what it claims
  value_statement: "One command answers whether the kit's instruments are still honest, and the answer is re-derivable from disk rather than asserted."
  personas: [Mara, Ada]
  entry_points:
    - url: "./bin/sdd health"
      origin: direct
    - url: "./bin/sdd health --full"
      origin: direct
    - url: "tests/run-all.sh --with-mutation"
      origin: direct
  actions:
    - step: 1
      verb: Run the health command on a clean tree
      expected_observable: "Numbered checks stream by, each as `  ok    <assertion>` or `  FAIL  <assertion>`"
    - step: 2
      verb: Read the mutation line
      expected_observable: "Over a new key: score: N caught, 0 known gap(s), of N — and the two numbers are compared, not just printed. Over a key already in the stamps: mutation: catalogue skipped — this content (key K) was measured green (measured: …; root: …; score: …); ./bin/sdd health --full measures it again"
    - step: 3
      verb: Read the stamp line
      expected_observable: "After a catalogue run: mutation stamp written — gate_PR can see that THIS content ran green (<git-common-dir>/sdd-mutation/stamps/K). After a skip: no stamp line, because the skip writes nothing"
    - step: 4
      verb: Read the final verdict
      expected_observable: "kit healthy with rc 0, or every failing reason listed with rc 1"
    - step: 5
      verb: Distrust the skip and measure again
      expected_observable: "./bin/sdd health --full runs the catalogue over the same key; ./bin/sdd health --full --release is refused by name"
  goal:
    observable: A verdict that is false whenever any instrument has stopped measuring
    side_effects: [key-written, key-removed-on-catalogue-verdict, todo-ratchet-read]
  true_end_state: >
    `kit healthy` is printed only when every check measured something real. Specifically: a
    catalogue with a survivor, a catalogue too small to have measured anything, an unparseable
    score line, a red fast suite, and a TEST_CMD that runs nothing must each turn the verdict red.
    A key leaves the set only by the catalogue's own verdict over it: a census that disagrees, a
    gap, a survivor or a TIMED-OUT mutant. A red fast suite, a missing or unparseable score line and
    a tree that moved leave the key exactly as it was, written or absent, and a skip writes nothing.
  exit:
    natural: The operator either proceeds to the PR phase or has a named instrument to repair.
  abandonment:
    - at_step: 1
      how: Ctrl-C during the catalogue, which takes hours.
      resume: "Nothing was written or removed; a key already in the set is still there. It is keyed on content, so it is valid exactly for the content it names, and a health over that content skips the catalogue."
    - at_step: 2
      how: A headless session starts the run in the background and its turn ends; the run dies mid-pool.
      resume: "The log stops inside `mutants (pool of 8)` with no score line. Measured twice in this mission: /tmp/sdd-baseline-score.txt and /tmp/sdd-health-final.log."
    - at_step: 3
      how: A commit lands while the catalogue is running.
      resume: The window guard refuses, writes and removes nothing, and says the operator's own commit is why — a re-run once the tree stops moving is the only exit.
  crosses: [cmd_health, mutation_stamp_valid, git-common-dir/sdd-mutation/stamps, tests/check-mutation.sh, tests/run-all.sh, gate_PR, tests/health-baseline.txt, TODO.md]
```

## Notes

Every `  ok    ` / `  FAIL  ` pair prints the **same** assertion text on different streams. That is
the contract the checkpoint Checks anchor on (`^  ok    `, four spaces) and it is what makes Ada's
question answerable: the words carry the verdict, not a colour. Any new line added to this command
inherits that contract.

The catalogue's runtime is the journey's dominant constraint and the source of two of its three
abandonment paths: it was 20 to 50 minutes when this journey was written, and 10 h 58 min for 775
mutants with no killer map on PR #327 (2026-10-25). It is not a defect — it is the price of the
catalogue — but every surface that *depends* on this journey completing inherits the risk. Since
ADR 0021 the skip takes it off every run over content already measured green, and `--full` is the
way back to it.
