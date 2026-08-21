# CH-the-branch-the-card-created: does the branch born in TICKET reach the field every later phase obeys?

```yaml
charter:
  id: CH-the-branch-the-card-created
  mission: "Follow one piece of data — the branch name — from the ticket skill that creates it to the commits that land on it, through two artifacts and one checkout, because the runner reads it from exactly one of those files and reading the wrong one once cost 16 commits on somebody else's PR."
  mode: charter-with-tour
  persona:
    name: Priya
    device: laptop
    network: wifi-fast
    locale: en-US
  journey: J-ticket-opens-and-branch-lands
  scenarios: [RUN-ticket-boots-one-driver, GATE-ticket-branch-must-reach-mission, GATE-ticket-branch-mismatch-refused, GATE-ticket-without-branch-still-passes, RUN-ticket-branch-carries-later-phases]
  tour: Feature Tour
  time_box_minutes: 90
  guidance:
    must_try:
      - "This phase has never been walked: the kit's own config has JIRA_ENABLED=false, so every claim about it is currently theoretical. Walk it against a real .jira-project, or record explicitly that the walk was simulated and what that leaves unproven."
      - "Read the boot argv in sdd run --dry-run --phase TICKET. Both halves settle it: the agent is sdd-publisher AND the prompt does not open with /ticket open. Either alone passes on a broken runner — one that kept both drivers, or one that boots the phase with no driver at all."
      - "Walk all three branch worlds in one fixture: placeholder in 00-missao.md (refuse), a different name (refuse), the same name (pass). Without the third, a gate that refused every TICKET would satisfy the first two."
      - "Confirm the final state from the repository — git log on the declared branch — and never from the session's own account of what it did."
      - "Try a 10-ticket.md with no branch field at all: it must pass. Every mission planned before the field existed is that shape."
    must_avoid:
      - "Letting the gate write the branch back. The write is the session's; a gate that wrote would corrupt moved/moved2 and the runner would start retrying phases that were making progress."
      - "Creating real JIRA cards in a project anyone else reads."
```

<!-- Feature Tour: first pass on an area nobody has walked, and its named failure — "mismatch between docs and behaviour" — is the shape of both defects here (an agent file that says one thing, an invariant that says another). -->
