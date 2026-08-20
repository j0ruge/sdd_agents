# CH-review-seal-one-keystroke: how few keystrokes buy an A?

```yaml
charter:
  id: CH-review-seal-one-keystroke
  mission: "As the session that has to get past gate_REVIEW, type the shortest thing that works and record everything the gate accepts — the placeholder set is compared by string equality, so the boundary is exactly one keystroke wide in several directions."
  mode: charter-with-tour
  persona:
    name: Sessão
    device: desktop
    network: wifi-fast
    locale: pt-BR
  journey: J-review-round-seal
  scenarios: [GATE-review-punctuated-placeholder-refused, GATE-review-empty-gate-field-refused, GATE-review-placeholder-rationale-refused, GATE-review-legit-short-rationale-passes]
  tour: Paste Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "TODO: TBD. FIXME! XXX? WIP, FILL ME, a bare hyphen, a full stop, a single space — each as a Rationale behind an A."
      - "The em dash, an en dash, a hyphen and a minus sign as four separate cells: mawk is byte-oriented and — is E2 80 94, so what looks like one character class is three different byte sequences."
      - "Smart quotes and an ellipsis character pasted from a word processor, against the ASCII three-dot spelling."
      - "The gate: frontmatter field present with an empty value, present with a space, present with a placeholder, and absent — four worlds, and the comment above the guard claims a behaviour the code does not have for the first."
    must_avoid:
      - "Refusing clean, n/a or the em dash — they are the codereview skill's own shorthand and a gate that rejects them contradicts the skill it parses."
      - "Proposing a [[:punct:]] rule without probing it against the em dash first."
```

<!-- Paste Tour: its theme — characters that arrived from somewhere else carrying formatting nobody saw — is literally this surface. The em dash, the ellipsis and the smart quote are the defect's actual material. -->
