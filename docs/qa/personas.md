# Personas — `sdd_agents`

Derived 2026-08-19 from the product's real audience. Durable: update when the audience changes,
not per cycle. Adapted from the seed catalog in the `qa-report` skill — none is a verbatim copy.

The kit is a CLI with no interface, so the seed catalog's device axis mostly collapses. What
replaces it is **context**: how much the reader already knows, and whether they can ask anyone.

---

## Mara — Kit Maintainer

```yaml
persona:
  name: Mara
  base: Power User
  goal: Land a kit mission — plan to merged PR — without any instrument telling her something it did not measure
  device: laptop
  network: wifi-fast
  modality: mouse-keyboard
  locale: pt-BR
  patience_seconds: 20
```

Runs `sdd kaizen`, `sdd run`, `sdd health` daily. Knows every verb and reads `bin/sdd` when a
message is ambiguous. Tolerates a slow suite; has **zero** tolerance for a green that is a label.
Her reflex when a gate refuses is to suspect the gate — which is why every refusal must name the
command that fixes it.

**Reveals:** verdicts that pass over unmeasured content, refusals with no remedy, ratchets that
drifted, output whose two halves disagree.

---

## Priya — First Adopter

```yaml
persona:
  name: Priya
  base: New User
  goal: Install the kit into her own repo and get one mission through the pipeline
  device: laptop
  network: wifi-fast
  modality: mouse-keyboard
  locale: en-US
  patience_seconds: 60
```

Has never seen the kit. Runs `sdd install`, `sdd preflight`, then a first mission on a repo that is
**not** the kit — no `tests/check-mutation.sh`, no mutation catalogue, no `KAIZEN_LOG.md`. Reads
English only. Abandons if a gate refuses for a reason that belongs to somebody else's repository.

**Reveals:** kit-only behaviour leaking into target repos, English-surface regressions, install and
preflight gaps, assumptions about the kit's own directory layout.

---

## Sessão — Headless Phase Session

```yaml
persona:
  name: Sessão
  base: New User
  goal: Satisfy the gate of exactly one phase and hand off, using only what is on disk
  device: desktop
  network: wifi-fast
  modality: keyboard-only
  locale: pt-BR
  patience_seconds: 0
```

Not a human, and on this list anyway — it is the reader that consumes gate messages most often and
the one whose confusion costs measurable money. A `claude -p` run booted by `run_phase()` with no
memory of any previous conversation (the kit's principle 3: *state on disk, not in context*). It
can act only on the boot prompt, the handoff files, and the exact text of `sdd why`. It cannot ask.
It ends its turn — and therefore its session — if it waits for a command that never returns.

**Reveals:** messages that describe a state without naming the command that leaves it, refusals
unsatisfiable by construction, commands that outlive a session's turn (`sdd health` at 20-50
minutes is the standing example), instructions in `agents/*.md` that contradict a gate.

> Justification for a non-human persona, against the seed catalog's warning about
> personas-of-convenience: two DOCS phases in this repo burned a session each because a rule said
> *what* to do and not *which command*, and three REVIEW sessions ended their turn with the words
> "waiting for the suite". Those are persona findings, and no human persona would have found them.

---

## Rui — Operator After a Dead Session

```yaml
persona:
  name: Rui
  base: Recovering User
  goal: Pick a mission back up after a session died mid-phase, and trust where the runner says it is
  device: laptop
  network: wifi-fast
  modality: mouse-keyboard
  locale: pt-BR
  patience_seconds: 30
```

Comes back to a repo where something stopped: a phase died, a background run was killed, the tree
is dirty, a stamp is stale. Runs `sdd status` first and believes it. His trust is fragile in one
specific way — if the runner's picture of the mission disagrees once with the disk, he stops using
it to decide anything.

**Reveals:** stale artifacts certifying a state that has moved, resume paths that re-do expensive
work, `sdd status` and `sdd why` disagreeing, phases re-derived in a loop.

---

## Ada — Terminal-Constrained Operator

```yaml
persona:
  name: Ada
  base: Accessibility-Reliant
  goal: Read a verdict and act on it without colour, without wide columns, and with a screen reader
  device: laptop
  network: flaky
  modality: screen-reader
  locale: en-US
  patience_seconds: 45
```

Works over SSH in an 80-column tmux pane, sometimes with a screen reader, sometimes with
`NO_COLOR` set, sometimes on a terminal whose font has no glyph for `✅ ✗ → ⇒ ▸ · │ ⚠️` — all of
which the kit's output uses on nearly every page. Her question of any line is: *does this still say
pass or fail if the symbol does not render and the colour is gone?*

**Reveals:** status carried by glyph or colour alone, lines that wrap into unreadability, output a
screen reader announces as punctuation, unicode assumed present in the terminal font.

> No Mobile persona: the product has no mobile surface. The nearest real constraint — a narrow
> terminal over a phone SSH client — rides on Ada's device row rather than inventing a sixth
> persona for it.

---

## Coverage rule

A full cycle covers at least three of these. A targeted (branch) cycle covers the personas the diff
can hurt, named in the cycle's report.
