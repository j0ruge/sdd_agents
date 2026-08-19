# CH-suite-list-is-not-a-run: can the suite's list mode still be mistaken for a suite that passed?

```yaml
charter:
  id: CH-suite-list-is-not-a-run
  mission: "Confirm that asking the suite what it would run can never be confused with running it — in the output and in the config key — because TEST_CMD is the single key gate_EXEC, gate_QA and gate_REVIEW all trust."
  mode: charter-with-tour
  persona:
    name: Mara
    device: laptop
    network: wifi-fast
    locale: pt-BR
  journey: J-suite-runs-something
  scenarios: [SUI-list-prints-steps-only, SUI-testcmd-with-list-refused]
  tour: Feature Tour
  time_box_minutes: 30
  guidance:
    must_try:
      - "Run --list on a machine WITH shellcheck and on one without it; the linter-absent notice must not appear inside the list."
      - "Diff --list output against a real run's step names — every list line must correspond to a step, and no step may be missing."
      - "Set TEST_CMD to the --list form, to empty, and remove the config entirely: three refusals, three distinct sentences."
      - "Try one other way of exiting 0 without running anything (a `true`, a `--help`) and record whether check 2b notices — the guard is a denylist of one today."
    must_avoid:
      - "Poisoning PATH to remove shellcheck: on this distribution it shares /usr/bin with grep, sed and comm, so the probe would measure a suite that cannot run instead of a suite without a linter."
```

<!-- 30 minutes: narrow scope, two scenarios, both already implemented this cycle. This is the smoke re-walk of I2. -->
