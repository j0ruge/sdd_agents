# CH-a-formatter-rewrote-the-mission: does the pipeline survive somebody else's tooling touching its tables?

```yaml
charter:
  id: CH-a-formatter-rewrote-the-mission
  mission: "Run a real markdown formatter over a mission's artifacts, write a Check that needs a pipe, and confirm the runner still reads the table the author wrote — because the failure here is not a crash, it is a plausible and wrong answer that sends the reader hunting a defect that does not exist."
  mode: charter-with-tour
  persona:
    name: Sessão
    device: desktop
    network: wifi-fast
    locale: pt-BR
  journey: J-checkpoint-survives-a-formatter
  scenarios: [GATE-exec-escaped-pipe-keeps-status, GATE-exec-alignment-colon-not-an-increment, GATE-docs-alignment-colon-not-a-status, RUN-status-agrees-with-the-gate]
  tour: Paste Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "Use a real prettier or markdownlint --fix over docs/handoffs/<mission>/, not a hand-typed imitation of what you think it writes. The bug survived fourteen missions because nothing in the kit produces these colons."
      - "Read sdd status and sdd why side by side on the same formatted checkpoint. The pre-fix symptom is the pair disagreeing while each looks reasonable alone."
      - "Probe the backslash parity, not just the escape: a cell ending in `\\\\` sits against a REAL delimiter, so an odd run escapes the pipe and an even one does not. Get this wrong in either direction and a legitimate row is refused."
      - "Compare formatted against unformatted answers to EACH OTHER. A literal expectation would pass on a runner that refused both."
      - "Then check the kit's own sensor still refuses both pipe forms in this repo's checkpoints — the rejoin is a safety net for adopters, not a licence here."
    must_avoid:
      - "Walking the gate_REVIEW face of the same bug — it belongs to CH-review-round-after-the-porteira, on its own journey and its own persona."
      - "Fixing the formatted file to make a gate pass. The artifact is the input; changing it is answering a different question."
```

<!-- Paste Tour: the theme is content arriving from another tool with formatting the author never saw, and its named failure — "validation-passing input that breaks downstream consumers" — is this bug exactly. -->
