# CH-review-round-after-the-porteira: do last cycle's three fixes hold, and do the two new refusals behave?

```yaml
charter:
  id: CH-review-round-after-the-porteira
  mission: "Re-walk the three review-seal bugs the last cycle filed and marked fixed but never re-verified, and walk the two the porteira added, so the round's verdict stops resting on a fix nobody watched land."
  mode: charter-with-tour
  persona:
    name: Mara
    device: laptop
    network: wifi-fast
    locale: pt-BR
  journey: J-review-round-seal
  scenarios: [GATE-review-alignment-colon-not-a-criterion, GATE-review-exemplar-matches-the-gate, GATE-review-placeholder-rationale-refused, GATE-review-punctuated-placeholder-refused, GATE-review-empty-gate-field-refused, GATE-review-escaped-pipe-in-rationale, GATE-review-legit-short-rationale-passes]
  tour: Feature Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "Three bugs in this journey read fixed with their scenarios still at fail — the fix was applied and nobody re-walked it. Settle retest_status for each, and treat a fix that cannot be re-walked as unfixed."
      - "Read the exemplar from .claude/agents/sdd-reviewer.md — the copy the harness loads — not from agents/. A stale mirror is exactly how a session goes on running text that was corrected weeks ago."
      - "For the alignment colons, settle BOTH halves: the round passes, and no refusal anywhere quotes the separator as a criterion. Absence is the discriminator; a refusal for some other reason is still wrong in the same way."
      - "Re-probe the em dash. mawk is byte-oriented and `—` is three bytes, so any punctuation rule written over it matches by bytes — the legitimate short rationales `clean`, `n/a` and `—` must still pass."
    must_avoid:
      - "Re-deriving the placeholder boundary keystroke by keystroke — CH-review-seal-one-keystroke owns that mission and is re-runnable as it stands."
      - "Reading the round through the kit's suite. The suite's assertions and the gate share an author; the point of the walk is a second pair of eyes on the artifact."
```

<!-- Feature Tour: "sanity-checking a recent change" is its stated use, and this session is exactly that plus the retest the previous cycle left open. -->
