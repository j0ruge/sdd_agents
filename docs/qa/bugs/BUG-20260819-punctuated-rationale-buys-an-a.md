# BUG-20260819-punctuated-rationale-buys-an-a: one keystroke turns a refused placeholder into an accepted review

- **Status:** verified <!-- open | fixed | verified | wont-fix | invalid -->
- **Impact (user-side):** Trust-Damage
- **Severity:** High · **Priority:** P1
- **Persona Affected:** Sessão
- **Journey Step:** J-review-round-seal, step 2 (let the gate read the round)
- **Scenarios:** GATE-review-punctuated-placeholder-refused
- **Found:** 2026-08-19 · **Report:** docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md (QA-phase notes)

## Summary

A review round is sealed with `A` on every criterion and `TODO:` as every rationale, and the gate
accepts it. The human who later opens the PR reads grades that no sentence supports — which is the
precise thing the rule shipped this cycle was written to make impossible. The rule works; its
boundary is one keystroke wide, and it is wide in the direction a model is most likely to walk.

## Reproduction

- **Charter:** CH-review-seal-one-keystroke · **Tour:** Paste Tour
- **Environment:** desktop, headless `claude -p` session or a hand-written round file

1. Write `docs/handoffs/<mission>/40-review-r1.md` with an `### Overall Grade` table.
2. Give every criterion Grade `A` and the Rationale `TODO:` — with the colon.
3. `./bin/sdd why <mission> REVIEW`.

**Expected:** refused, as the bare `TODO` is.
**Actual:** the gate passes. Same for `TBD.`, `-`, `.`, `?`, `WIP`, `FILL ME`.

## Evidence

- `bin/sdd` `placeholder()` compares the **whole cell by string equality** against a closed set:
  empty, `^<.*>$`, `...`, `…`, and (upper-cased) `PREENCHER`, `TODO`, `TBD`, `FIXME`, `XXX`.
  Anything one character away is outside the set and passes.
- `TODO:` is the spelling a model writes more readily than the bare word.
- A bare hyphen sits one key from the em dash `—`, which is legitimate **on purpose** (the
  `codereview` skill's shorthand for "measured, nothing to say", `report-template.md:154-156`).

⚠️ **Any fix must be probed against the em dash before shipping.** `mawk` is byte-oriented; `—` is
`E2 80 94`, so a `[[:punct:]]` class or a negated class over it matches by bytes, not characters.
The same trap already cost this repo the `head_of()` of `tests/check-todo.sh`.

## Fix

- **Root cause:** an allow/deny decision made by exact-match against an enumeration, on a field
  whose input space is open. Symptom: a placeholder buys an A. Cause: the set can never be complete.
- **Fix commit:** `272cb91` (increment F3)
- **Regression test:** `tests/check-gates.sh`, anchored on
  `^  ok    gate_REVIEW: an unfilled gate field and a punctuated fill-in do not buy an A` — eleven
  differential worlds. The rule stopped comparing the whole cell by equality: a punctuation-only
  cell is refused, and a fill-in word is normalised before lookup, so `TODO:`, `TBD.`, `-`, `?`,
  `WIP` and `FILL ME` no longer buy the A. Catalogue 112 -> 115: `punctuation_only_blind`,
  `punctuated_fillin_blind`, `blank_gate_field_blind`, plus `mut_REVIEW_gate_field_blind`
  re-anchored. All three new mutants leave the I3 assertion **green** — one sabotage per site.
- **The em-dash warning above was honoured and is now measured.** Removing the `—` exception is one
  of the 13 adversarial degradations, and it turns the assertion red. `clean`, `n/a` and `—` still
  pass, so the rule refuses placeholders without contradicting the `codereview` skill it parses.

### Left open by the fix, recorded rather than closed

`FIXME` and `XXX` are refused with no world proving it — filed by the fixing session as a new
backlog item (`todo-findings` 85 -> 86, commit `3f958f3`). Two of the three green control
degradations in the adversarial pass are exactly those two words.

⚠️ **One adversarial probe in that pass concluded invalidly and is worth carrying forward.** A
`sed` expression had its quoting broken by the shell, became something else, created a file named
`== "FILLME"||` in the working directory, and still printed `RED ✓`. Only `git status` caught it.
Re-run with `#` as delimiter the conclusion held — but the original was worth zero. Same rule as
the repo's standing one about probes proving they sabotaged what they claimed, now via shell
quoting rather than a stale anchor.

## Verification

Not yet `verified`: the re-walk under the original persona is `sdd why <mission> REVIEW` against a
round file carrying each refused spelling, and the REVIEW phase now running is the first real
exercise of it — the round it writes is judged by the rule this bug produced. Move to `verified`
once that round is on disk and the gate's verdict on it has been read.

## Verification

- **Retested:** 2026-08-21, Mara / J-review-round-seal · **Report:** ../reports/2026-08-21-missao-porteira.md
- **Result:** observable confirmed fixed. Walked on a live target repo (not a suite fixture), on a
  round whose table was colon-aligned and prettier-formatted, so the retest also covers the
  alignment change that landed since the fix.
