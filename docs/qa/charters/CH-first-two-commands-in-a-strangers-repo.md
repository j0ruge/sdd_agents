# CH-first-two-commands-in-a-strangers-repo: what happens to somebody who types `sdd install` and then `sdd preflight`?

```yaml
charter:
  id: CH-first-two-commands-in-a-strangers-repo
  mission: "Be the first adopter and mistreat the install: a repo with two manifests, a TEST_CMD that runs nothing, no skills on the machine — and find where the kit lets a wrong answer through quietly, because everything downstream trusts what these two commands wrote."
  mode: charter-with-tour
  persona:
    name: Priya
    device: laptop
    network: wifi-fast
    locale: en-US
  journey: J-target-repo-ships
  scenarios: [TGT-install-seeds-the-tree, TGT-install-first-manifest-wins, TGT-preflight-refuses-noop-testcmd, TGT-preflight-warns-missing-skills, TGT-preflight-skill-warning-follows-the-config, TGT-schema-promises-only-what-is-read]
  tour: Garbage Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "Install into a repo carrying package.json AND go.mod, in both creation orders, and read which suite the config ended up naming. A silently wrong TEST_CMD is worse than a TODO she has to fill in."
      - "Feed the preflight every no-op spelling — true, :, echo ok, npm test -- --list, pytest --collect-only — and then the four that must NOT be accused: npm test, tests/run-all.sh, ./run.sh --listen-port 8080, make test && echo done. A rule that fires on correct config is the rule the next author deletes."
      - "Point SDD_SKILLS_ROOT at an empty directory and read the warning as somebody who has never heard of these skills: does it say where it looked and what the absence will cost her?"
      - "Walk all four config shapes for the skill warning (JIRA on/off × interface/none). The failure mode is a list that is right on the maintainer's machine and wrong on everyone else's."
      - "Run sdd install a second time over a findings file holding a real entry, and diff it. Seeding must never overwrite."
    must_avoid:
      - "Running any of this in the kit's own repo or a worktree of it — the whole point is a repo the kit does not own."
      - "Judging the seeded values by grepping the config text; source it in a subshell the way check 2b does, because what matters is the value load_config will hand the runner."
```

<!-- Garbage Tour: every failure in this diff's install/preflight surface is input-shaped — a manifest that shouldn't win, a command that runs nothing, a root that holds no skills. -->
