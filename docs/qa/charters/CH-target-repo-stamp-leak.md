# CH-target-repo-stamp-leak: does the kit's own maintenance stay out of somebody else's repo?

```yaml
charter:
  id: CH-target-repo-stamp-leak
  mission: "Walk a whole mission in a repo that is not the kit and confirm that no gate message ever names the mutation catalogue, a stamp, or sdd health — because one [ -f ] test is all that separates the kit's self-maintenance from every adopter's pipeline."
  mode: charter-with-tour
  persona:
    name: Priya
    device: laptop
    network: wifi-fast
    locale: en-US
  journey: J-target-repo-ships
  scenarios: [TGT-pr-gate-silent-in-target, TGT-review-rule-applies-everywhere]
  tour: Feature Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "Install into a fresh throwaway repo, then drive a trivial mission all the way to gate_PR and read back EVERY message the run produced, not only whether the PR opened."
      - "Confirm the differential: the stamp rule must NOT cross into her repo, and the placeholder-rationale rule MUST. Observing only one cannot distinguish correct scoping from refusing everything or nothing."
      - "Drop an unrelated file named tests/check-mutation.sh into her repo and watch what gate_PR then demands of her."
      - "Read the refusals as somebody with no knowledge of the kit's internals: does any of them name a file, a command, or a concept that lives only in the kit?"
    must_avoid:
      - "Running this in the kit's own repo or a worktree of it — the whole point is a repo without the catalogue artifact."
      - "Pointing the ledger at the fixture; a throwaway repo's rows once moved the kaizen judge's numbers."
```

<!-- Feature Tour: the promise being checked is the one the docs make to an adopter — the pipeline's discipline without the kit's self-maintenance. The tour's "mismatch between docs and behaviour" is precisely the failure shape. -->
