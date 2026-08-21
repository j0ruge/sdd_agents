# CH-the-line-stopped-without-colour: can you tell a blocked run from a finished one with no colour and no glyphs?

```yaml
charter:
  id: CH-the-line-stopped-without-colour
  mission: "Read the branch's new escalation output — the dirty-tree refusal, the ceiling note, the skills warning — with NO_COLOR set, 80 columns and a font with no glyph for the kit's symbols, and find every line whose pass-or-fail was carried by something other than the words."
  mode: charter-with-tour
  persona:
    name: Ada
    device: laptop
    network: flaky
    locale: en-US
  journey: J-trouble-stops-the-line
  scenarios: [RUN-dirty-tree-refusal-names-the-remedy, RUN-phase-budget-fits-the-phase]
  tour: Locale Tour
  time_box_minutes: 30
  guidance:
    must_try:
      - "The diff added output lines to four commands. Read each one through `sed 's/\\x1b\\[[0-9;]*m//g'` and ask of every line: does this still say pass or fail without the colour?"
      - "The escalation messages are multi-line and indented. Check they survive an 80-column pane without wrapping into unreadability, and that the remedy is not the half that wraps away."
      - "The new preflight warning names three filesystem paths in one message. Paths are the worst case for a screen reader — check whether the sentence still works when the paths are announced as punctuation."
      - "Compare the dim-styled ceiling note against the bad-styled refusal above it: dim and red are the same in a monochrome pane, so the words have to carry the difference."
    must_avoid:
      - "Re-walking the health verdict — CH-health-verdict-without-colour owns that surface and is re-runnable unchanged."
      - "Judging severity here. This session finds unreadable lines; whether one is a bug is the registry's rubric, not the pane's."
```

<!-- Locale Tour: the catalog's rendering-and-layout lens is the closest fit for a terminal whose font, width and colour support are all unknowns. -->
