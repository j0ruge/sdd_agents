# J-target-repo-ships — Ship a mission from a repo that is not the kit

The canary. Every gate this cycle touched is evaluated in **every** repo the kit drives, and the
kit is only one of them. This journey is the adjacent walk that proves the kit's own maintenance
machinery did not leak into somebody else's repository.

```mermaid
flowchart TD
    A[Entry: Priya runs sdd install in her own repo] --> B[.sdd/config.sh and .claude/agents/ written]
    B --> C[./bin/sdd preflight]
    C --> D{tools, auth, config, agent mirrors OK?}
    D -->|no| D1[Named refusal per item] --> C
    D -->|yes| E[Plans and runs a mission through EXEC, QA, REVIEW, DOCS]
    E --> F[gate_REVIEW reads her Overall Grade table]
    F --> F1{her review round has a filled Rationale per A?}
    F1 -->|no| F2[Refused — same rule as the kit, and correctly so: the rule is about the artifact, not about which repo it lives in] --> E
    F1 -->|yes| G[gate_PR]
    G --> H{does tests/check-mutation.sh exist in HER repo?}
    H -->|no — the expected answer| I[No stamp is asked for. The block is skipped entirely.]
    H -->|yes — she happens to have a file by that name| I2[She is asked for a mutation stamp she has no way to produce]
    I --> J[Side effect: branch pushed, PR opened]
    J --> K[True end: her PR opens without the kit own maintenance machinery ever being mentioned to her, in a message or in a gate]

    I2 -.->|no sdd health for her repo| X1[Abandon-A: gate_PR unsatisfiable; the remedy in the message points at the KIT catalogue]
    C -.->|preflight red on agent mirrors| X2[Abandon-B: she runs cp instead of sdd install --force; the harness blocks .claude/ in headless sessions]
    E -.->|her TEST_CMD is slow or absent| X3[Abandon-C: gates run it repeatedly per status; she shortens it and no check notices]
```

```yaml
journey:
  id: J-target-repo-ships
  name: Ship a mission from a repo that is not the kit
  value_statement: "A team adopting the kit gets the pipeline's discipline without inheriting the kit's own self-maintenance."
  personas: [Priya]
  entry_points:
    - url: "sdd install"
      origin: direct
    - url: "sdd preflight"
      origin: direct
    - url: "sdd run <mission>"
      origin: in-app-nav
  actions:
    - step: 1
      verb: Install the kit into a repo that is not the kit
      expected_observable: Config and agent mirrors written; preflight green
    - step: 2
      verb: Drive a mission to the PR phase
      expected_observable: Every gate refusal names something in HER repo
    - step: 3
      verb: Reach gate_PR
      expected_observable: No mention of a mutation catalogue or a stamp — the scope block is skipped
  goal:
    observable: The PR opens with no kit-only requirement having been evaluated against her repo
    side_effects: [branch-pushed, pr-opened]
  true_end_state: >
    Her PR is open and, reading back every gate message the run produced, none names
    tests/check-mutation.sh, sdd health's catalogue, or a stamp. The scope condition is an artifact
    question, so a repo without the artifact never sees the question.
  exit:
    natural: She merges her own PR and plans a second mission.
  abandonment:
    - at_step: 3
      how: Her repo happens to contain a file called tests/check-mutation.sh that is not the kit's catalogue.
      resume: "She is asked for a stamp only sdd health writes, and sdd health measures the kit, not her repo. Low likelihood, unbounded cost — the scope is a filename."
    - at_step: 1
      how: Preflight reports stale agent mirrors and she reaches for cp.
      resume: "sdd install --force is the only sync path; the harness treats .claude/ as sensitive and denies Edit/cp in headless sessions. Two DOCS phases in the kit's own history burned a session here."
    - at_step: 2
      how: Her TEST_CMD is slow, so she trims it.
      resume: "Health's check 2b reads the KIT's TEST_CMD, never hers — nothing in the kit inspects a target repo's TEST_CMD at all."
  crosses: [gate_PR scope condition, gate_REVIEW, cmd_install, cmd_preflight, cmd_health check 2b]
```

## Notes

This journey is walked **against the diff**, not against the product's roadmap. It is the canary the
targeted cadence tier requires: the diff changed two gates every target repo runs, and the only
thing between that and a broken adopter is one `[ -f ... ]` test.
