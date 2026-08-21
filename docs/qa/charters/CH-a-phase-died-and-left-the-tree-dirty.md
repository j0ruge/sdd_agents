# CH-a-phase-died-and-left-the-tree-dirty: what does the runner do with work nobody committed?

```yaml
charter:
  id: CH-a-phase-died-and-left-the-tree-dirty
  mission: "Kill phases the way they really die — mid-edit, mid-round, mid-run — and confirm the next sdd run ENDS instead of opening another session against the same wall, because state_fingerprint cannot see a working tree and every attempt used to cost about US$ 25."
  mode: charter-with-tour
  persona:
    name: Rui
    device: laptop
    network: wifi-fast
    locale: pt-BR
  journey: J-trouble-stops-the-line
  scenarios: [RUN-dirty-tree-stops-the-line, RUN-red-suite-clean-tree-still-runs, RUN-dirty-tree-refusal-names-the-remedy, RUN-review-rounds-counted-in-total, RUN-forced-review-round-still-runs]
  tour: Interrupt Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "Walk the differential one `echo >> file` apart: the SAME red suite over a clean tree must still open a session. Observing only the escalation cannot tell a working Jidoka from a runner that refuses everything."
      - "Count sessions in .sdd/logs/<mission>/pipeline.log, never by listing <PHASE>-*.json files — those are named to the second, so two sessions inside one second collide on one path and the count stops rising."
      - "Re-run the refused command two or three times in a row. A refusal a human can safely ignore is one that costs zero every time; verify the third attempt spends as little as the first."
      - "Then leave four review rounds on disk with REVIEW_MAX_ITER=3 and run again — the derived path must refuse, `--phase REVIEW` must not. Do both in the same fixture."
      - "Number the rounds so a lexicographic reader and a version-ordered one disagree (r3 and r10 present, r4-r9 absent) and see which one the ceiling used."
    must_avoid:
      - "Deciding the outcome from the terminal alone: exit 3 and the 'BLOCKED in EXEC' prefix are shared with budget exhaustion, so neither discriminates. The journal and the dirty-tree sentence do."
      - "Committing or restoring the dirty file yourself before reading the message — the message is the deliverable of this session, not the recovery."
```

<!-- Interrupt Tour: the theme is abandon-and-resume, and its named failure ("resume-from-here features that resume from the wrong place") is exactly what a re-derived EXEC over a dirty tree is. -->
