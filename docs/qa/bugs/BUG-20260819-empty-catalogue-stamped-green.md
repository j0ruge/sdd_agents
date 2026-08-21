# BUG-20260819-empty-catalogue-stamped-green: the kit certifies itself healthy over a catalogue that ran nothing

- **Status:** verified <!-- open | fixed | verified | wont-fix | invalid -->
- **Impact (user-side):** Trust-Damage
- **Severity:** High · **Priority:** P1
- **Persona Affected:** Mara
- **Journey Step:** J-health-verdict, step 2 (read the mutation score line)
- **Scenarios:** HLT-empty-catalogue-refused
- **Found:** 2026-08-19 · **Report:** docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md (QA-phase notes)

## Summary

Mara asks the kit whether its instruments still work. It answers `kit healthy`, writes the stamp
that opens `gate_PR`, and the catalogue behind that answer ran zero mutants. Every downstream
green — the stamp, the gate, the PR — is then about a measurement that did not happen. This is the
exact failure the mission containing this bug was written to end, reproduced inside that mission's
own artifact.

## Reproduction

- **Charter:** CH-catalogue-floor-under-garbage · **Tour:** Garbage Tour
- **Environment:** laptop, kit repo, any shell

1. Reduce `CATALOG=()` in `tests/check-mutation.sh` to empty (or to a handful of entries).
2. `tests/run-all.sh --with-mutation` prints `score: 0 caught, 0 known gap(s), of 0` and exits 0 —
   the loop runs zero times, `errors=0`.
3. `./bin/sdd health`.

**Expected:** a catalogue too small to have measured anything is refused, and no stamp is written.
**Actual:** `gaps == 0` holds and `caught == total` holds, so check 2 prints `ok`,
`catalogue_green=1`, and the stamp is written. `gate_PR` then opens over a catalogue of nothing.

A **narrowed** catalogue does the same: `of 3` satisfies both comparisons just as well as `of 110`.

## Evidence

- `tests/check-mutation.sh:1615` prints `of ${#CATALOG[@]}` with no floor of any kind.
- `bin/sdd` check 2 compares `gaps` then `caught` against `total`, and never asks whether `total`
  is large enough to mean anything.
- It is the only count in `cmd_health` without an anti-vacuity floor, next to `LINT_FLOOR`,
  `SURFACE_FLOOR`, `CAPTURE_FLOOR` and `REVIEW_FLOOR` — all of which exist for this reason.
- Today 110 mutants are defined and 110 are listed, and nothing asserts the two numbers agree.

## Fix

- **Root cause:** the verdict validates the *relationship* between the score's numbers and never
  their *magnitude*. Symptom: a green over nothing. Cause: a missing floor, in the one place a
  floor was not copied.
- **Fix commit:** `688553f` (increment F1), checkpoint row closed by `09c43c2`
- **Regression test:** `tests/check-health.sh`, anchored on
  `^  ok    mutation: a catalogue too small to have measured anything is refused`; four new
  `sdd health` worlds in the fixture, plus catalogue mutant `mut_HEALTH_catalogue_floor_blind`
  (110 -> 111, proved by a one-line diff at a single site that killed the suite) and
  `CAPTURE_FLOOR` 20 -> 21 for the new size capture.

### Fixed in the consumer only — the residual is real and recorded

The floor lives in `cmd_health`, which is the reader of the score line. `tests/check-mutation.sh`
still prints `of ${#CATALOG[@]}` with no floor of its own, and **two sentences in the runner send
the operator to `tests/run-all.sh --with-mutation` by hand** — where the green goes back to lying,
because nothing between the catalogue and that operator's eyes applies the floor.

Filed by the fixing session as a new backlog item (`todo-findings` 83 -> 84, commit `202af04`).
This bug is `fixed`, not closed-out: the journey it names (`sdd health` -> `kit healthy`) is
guarded; the adjacent manual path is not.

## Verification

**Not yet verified, deliberately.** The re-walk is `./bin/sdd health` (20-50 min), and the fixing
session did not run it because F2 and F3 were still `pending` — each touches `bin/` and `tests/`,
so a stamp taken then would die at the next increment. Both background attempts earlier in this
mission died without printing a `score:` line.

What *is* measured today: the two numbers the new rule compares in the real kit are **111 and
111**, above the floor of 8, so a genuine run is not refused by the new guard. Whoever closes F3
runs `./bin/sdd health` and only then moves to the PR phase — that run is this bug's verification.

## Verification

- **Retested:** 2026-08-21, Mara / J-health-verdict · **Report:** ../reports/2026-08-21-missao-porteira.md
- **Result:** observable confirmed fixed. A kit copy whose `CATALOG=()` was emptied (the emptying
  proven before the run, not assumed) produced `score: 0 caught, 0 known gap(s), of 0`, and the
  sensor refused it: *"the catalogue ran 0 of the 128 mutant(s) tests/check-mutation.sh defines
  (floor 8) — an emptied or narrowed catalogue goes on printing caught == of, and that green is
  about a loop that ran 0 time(s)"*. No stamp was written.
