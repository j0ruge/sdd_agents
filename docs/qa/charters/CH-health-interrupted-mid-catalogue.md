# CH-health-interrupted-mid-catalogue: what does a 20-to-50-minute command leave behind when it does not finish?

```yaml
charter:
  id: CH-health-interrupted-mid-catalogue
  mission: "Interrupt the health run every way it really gets interrupted — Ctrl-C, a dead background session, a commit landing mid-run — and check what is left on disk afterwards, because the stamp is the thing that outlives the command."
  mode: charter-with-tour
  persona:
    name: Rui
    device: laptop
    network: wifi-fast
    locale: pt-BR
  journey: J-health-verdict
  scenarios: [HLT-stamp-window-refused, HLT-stamp-removed-on-red, GATE-pr-refuses-stale-stamp]
  tour: Interrupt Tour
  time_box_minutes: 90
  guidance:
    must_try:
      - "Ctrl-C at minute 5, then check whether a PREVIOUS stamp survived and whether it is still honest about the tree as it stands now."
      - "Start the run, commit a one-line change to tests/ while it is going, and confirm the window guard refuses AND says the operator's own commit is why."
      - "Start it in the background from a session whose turn then ends — this repo has two logs that died mid-pool inside 'mutants (pool of 8)' with no score line."
      - "After a green stamp, commit to docs/ and to CLAUDE.md and confirm the stamp SURVIVES; then commit to tests/ and confirm it does not. The narrowing to four directories is deliberate and both directions are the assertion."
    must_avoid:
      - "Assuming an interrupted run left nothing behind — the point of the box is what remains."
      - "Treating the 20-to-50-minute runtime as the defect. It is the price of the catalogue; what this box measures is what depends on it finishing."
```

<!-- 90 minutes for the same reason as CH-catalogue-floor-under-garbage: the interrupts being studied only exist inside a real run. -->
