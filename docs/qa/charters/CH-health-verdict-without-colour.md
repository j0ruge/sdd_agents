# CH-health-verdict-without-colour: does the verdict survive a terminal that renders none of its symbols?

```yaml
charter:
  id: CH-health-verdict-without-colour
  mission: "Read a full health verdict with no colour, 80 columns, and no glyph for the box-drawing and warning characters, and find every place where pass-or-fail was carried by something other than the words."
  mode: charter-with-tour
  persona:
    name: Ada
    device: laptop
    network: flaky
    locale: en-US
  journey: J-health-verdict
  scenarios: [HLT-verdict-readable-without-colour]
  tour: Locale Tour
  time_box_minutes: 60
  guidance:
    must_try:
      - "NO_COLOR=1 and a pipe to cat: does every line still say ok or FAIL in words?"
      - "An 80-column pane: which lines wrap, and does a wrapped refusal still read as one refusal?"
      - "A terminal font with no glyph for the checkmark, the cross, the arrows, the middle dot, the box-drawing bar and the warning sign — all of which appear on nearly every page of this kit's output."
      - "Pipe the output through a screen reader or `espeak`: does the ok/FAIL distinction survive being spoken, or does it become punctuation?"
      - "Confirm the stdout/stderr split holds: the same assertion text on both streams is what the checkpoint Checks anchor on with ^  ok    ."
    must_avoid:
      - "Rewriting the kit's glyph vocabulary during the box; the finding is where the glyph is the ONLY carrier, not that glyphs exist."
```

<!-- Locale Tour is the closest catalogue fit — "any surface that renders text", layout breaks, character widths — but it is an adaptation, not a match. If this box finds anything, propose a Terminal Tour as a catalogue candidate in the debrief. -->
