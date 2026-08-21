# Run a real markdown formatter over a fixture mission and assert the phase is unchanged

- Source: J-checkpoint-survives-a-formatter; GATE-exec-alignment-colon-not-an-increment; GATE-docs-alignment-colon-not-a-status; GATE-review-alignment-colon-not-a-criterion
- Why automate: regression-prone — three parsers share one three-character blindness, and every
  fixture that proves it fixed is a hand-typed imitation of what a formatter writes
- Suggested layer: API/integration (a sensor in `tests/`, not a browser spec — the product has no UI)
- Spec sketch:
  - build a fixture mission whose artifacts are all valid and all-green;
  - run the repo's real formatter (`prettier --write` / `markdownlint --fix`) over
    `docs/handoffs/<mission>/`, and **fail loudly if it changed nothing** — a probe that formatted
    nothing would certify the parsers against an untouched world;
  - assert `sdd phase` answers the same thing before and after, compared to each other;
  - true end state: the same phase, and no `GATE_WHY` anywhere quoting a separator row.
- Status: proposed

## Why this one and not the others

The alignment-colon bug survived fourteen missions because **nothing in the kit produces those
colons** — no fixture had them until a human typed them by hand in `db26cc1`. The fixtures that now
prove the fix are the same shape: strings an author believed a formatter writes. That is the
imagined-fixture trap `CLAUDE.md` names in as many words — gate and fixture share an author and the
same assumption, so a green suite *confirms* the assumption instead of measuring it.

A sensor that invokes the real tool closes it, and closes the whole family at once: the day
prettier changes how it aligns a table, or markdownlint starts normalising escapes, the sensor
notices and the hand-typed fixtures do not.

⚠️ The obvious objection is that this makes the suite depend on a tool that may not be installed.
The precedent in this repo is the linter: `tests/run-all.sh` skips it when `shellcheck` is absent
and **says so on stderr**, because a list that silently drops a step is the other half of the lie.
Same shape here — skip loudly, never silently.
