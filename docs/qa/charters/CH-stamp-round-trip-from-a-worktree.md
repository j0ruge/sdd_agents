# CH-stamp-round-trip-from-a-worktree: does the stamp survive the trip from the writer to the reader?

```yaml
charter:
  id: CH-stamp-round-trip-from-a-worktree
  mission: "Prove that the tree sdd health stamps is the same tree gate_PR reads it from, from every way an operator actually invokes the runner — because when they diverge, gate_PR is unsatisfiable forever and the remedy in its own message makes it worse."
  mode: charter-with-tour
  persona:
    name: Mara
    device: laptop
    network: wifi-fast
    locale: pt-BR
  journey: J-certify-mission-close
  scenarios: [GATE-pr-stamp-read-from-gate-tree, GATE-pr-passes-on-fresh-stamp, GATE-pr-demands-stamp-when-missing]
  tour: Multi-Tab Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "Invoke ./bin/sdd from the repo root, then `sdd` resolved from PATH with the cwd inside a git worktree of the same repo — compare where the stamp lands against where the gate looks."
      - "Run the same two invocations from a second clone; the README advertises `export PATH=\".../bin:$PATH\"`, so this is the documented flow, not an exotic one."
      - "Re-derive the key by hand (md5 over bin/ tests/ templates/ config/) and compare it against the stamp file, rather than trusting that writer and reader agree."
      - "Empty the four measured directories in a scratch copy and confirm the key is REFUSED rather than becoming the md5 of nothing — xargs without -r runs md5sum once with no operands."
    must_avoid:
      - "Running the full ./bin/sdd health inside this box — 20 to 50 minutes does not fit. Write the stamp file by hand from a key you computed, or reuse a stamp from CH-catalogue-floor-under-garbage."
      - "Editing bin/sdd to make a probe pass; this box measures, it does not fix."
```

<!-- Multi-Tab Tour, adapted: the CLI analogue of two tabs is two working trees plus two ways of resolving the binary. The tour's theme — the same state reached from two contexts, and stale or leaked state between them — is exactly the defect this charter hunts. -->
