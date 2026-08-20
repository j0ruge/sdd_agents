# BUG-20260819-empty-gate-field-passes: the guard's own comment describes the case it lets through

- **Status:** fixed
- **Impact (user-side):** Trust-Damage
- **Severity:** High · **Priority:** P1
- **Persona Affected:** Sessão
- **Journey Step:** J-review-round-seal, step 3 (fill the gate frontmatter field)
- **Scenarios:** GATE-review-empty-gate-field-refused
- **Found:** 2026-08-19 · **Report:** docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md (QA-phase notes)

## Summary

The `gate:` frontmatter field of a review round is meant to carry the evidence that the round
closed. A round that ships it **present and empty** — `gate:` with nothing after it — is accepted,
while the comment three lines above the guard states that present-but-unfilled is the case that
lies and is the one refused. The reader of the round is told a field was filled that was not.

## Reproduction

- **Charter:** CH-review-seal-one-keystroke · **Tour:** Paste Tour
- **Environment:** desktop, hand-written round file

1. Write `40-review-r1.md` with a fully valid Overall Grade table (real rationales, all `A`).
2. In the frontmatter, write `gate:` with an empty value.
3. `./bin/sdd why <mission> REVIEW`.

**Expected:** refused, per the guard's own stated intent.
**Actual:** passes.

## Evidence

- `bin/sdd:571` — `if (gate_field != "" && placeholder(gate_field))`. `placeholder("")` returns 1,
  so the first conjunct exists **solely** to exclude the empty case — the same case the comment
  above it names as the one being refused.
- The comment, verbatim: *"Present-but-unfilled is the case that lies, and it is the one refused."*

**Not this bug:** `gate:` being **absent** is left alone deliberately, and the scope was measured,
not assumed — 6 of the 14 rounds on disk predate the field, so refusing absence would rewrite
history rather than measure the current round. That gap is already recorded in `TODO.md` by
`dc6a6c9` and is a different item. This bug is only about present-and-empty.

## Fix

- **Root cause:** one predicate is doing two jobs — "is this a placeholder?" and "does this field
  exist?" — and the second silently overrides the first. Symptom: an empty field passes. Cause: the
  absent/empty distinction is not available at the point the decision is made.
- **Fix commit:** `272cb91` (increment F3)
- **Regression test:** shares the F3 assertion with the sibling bug. The presence question moved out
  of the value test into `frontmatter_has`/`gate_present`, so absent and present-but-blank are now
  different answers instead of the same one. Catalogue mutant `blank_gate_field_blind` is the defect
  in pure form — it reverts to testing the value instead of the presence — and
  `mut_REVIEW_gate_field_blind` was re-anchored because the line it read had moved.
- **The documentation was right and the code was wrong**, which is the rare direction. `docs/pipeline.md`,
  `templates/review.md` and `agents/sdd-reviewer.md` all three promised that present-and-unfilled
  fails; that promise was false until this commit, and the same commit synced all three.

## Verification

Not yet `verified` — same re-walk as the sibling bug, and the REVIEW phase now running is its first
real exercise. The refusal message gained the `(<empty>)` label for this case, so the verification
observable is that a round shipping `gate:` with a blank value is named, not merely refused.
