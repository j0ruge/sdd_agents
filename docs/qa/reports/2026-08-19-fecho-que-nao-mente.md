# QA Run Report — 2026-08-19 — branch `fix/fecho-que-nao-mente`

- **Scope:** the diff of `main...fix/fecho-que-nao-mente` — four instruments that certify a mission's close stop asserting what they did not measure (`sdd health`'s score verdict, `tests/run-all.sh --list`, `gate_REVIEW`'s rationale column, `gate_PR`'s mutation stamp)
- **Cadence tier:** targeted (branch/PR cycle) + 1 adjacent journey as canary
- **Build:** `272cb91` (last code commit; planning began at `9f84cbc`) · **Environment:** local shell; no service, no URL — `E2E_CMD=""`, no `APP_URL`
- **Started:** 2026-08-19 · **Status:** in-progress <!-- in-progress | closed -->

> **Planning output only.** Every matrix row below is `Pending`: this report was created by
> `qa-report` before any session ran, which is what the template asks for. The four bugs already in
> the registry were **not** found by these charters — they were reproduced by the mission's own QA
> phase (`sdd-qa`, session `9237fec0`, 2026-08-19) and are carried in here so the sessions that do
> run start from what is already known rather than re-finding it.

## Personas

| Persona | Base | Device / Network / Locale | Sessions |
|---|---|---|---|
| Mara | Power User | laptop / wifi-fast / pt-BR | CH-stamp-round-trip-from-a-worktree, CH-catalogue-floor-under-garbage, CH-suite-list-is-not-a-run |
| Priya | New User | laptop / wifi-fast / en-US | CH-target-repo-stamp-leak |
| Sessão | New User (amnesiac) | desktop / wifi-fast / pt-BR | CH-review-seal-one-keystroke |
| Rui | Recovering User | laptop / wifi-fast / pt-BR | CH-health-interrupted-mid-catalogue |
| Ada | Accessibility-Reliant | laptop / flaky / en-US | CH-health-verdict-without-colour |

## Flows in Scope

- `J-certify-mission-close` — the PR that ships a kit change carries proof the kit's assertions ran green over exactly this content (`../journeys/J-certify-mission-close.md`)
- `J-health-verdict` — one command answers whether the kit's instruments are still honest (`../journeys/J-health-verdict.md`)
- `J-review-round-seal` — an A on a review round means a reviewer wrote down why (`../journeys/J-review-round-seal.md`)
- `J-suite-runs-something` — rc 0 from TEST_CMD means work was done (`../journeys/J-suite-runs-something.md`)
- `J-target-repo-ships` — **canary**; an adopter gets the pipeline without the kit's self-maintenance (`../journeys/J-target-repo-ships.md`)

## Session Matrix & Results

| # | Charter | Journey / Scenario | Persona | Tour | Status | Issue | Fix commit |
|---|---|---|---|---|---|---|---|
| 1 | CH-stamp-round-trip-from-a-worktree | J-certify-mission-close / GATE-pr-stamp-read-from-gate-tree | Mara | Multi-Tab | Pending | BUG-20260819-stamp-written-where-gate-cannot-read | 1dc713f |
| 2 | CH-stamp-round-trip-from-a-worktree | J-certify-mission-close / GATE-pr-passes-on-fresh-stamp | Mara | Multi-Tab | Pending | | |
| 3 | CH-stamp-round-trip-from-a-worktree | J-certify-mission-close / GATE-pr-demands-stamp-when-missing | Mara | Multi-Tab | Pending | | |
| 4 | CH-target-repo-stamp-leak | J-target-repo-ships / TGT-pr-gate-silent-in-target | Priya | Feature | Pending | | |
| 5 | CH-target-repo-stamp-leak | J-target-repo-ships / TGT-review-rule-applies-everywhere | Priya | Feature | Pending | | |
| 6 | CH-catalogue-floor-under-garbage | J-health-verdict / HLT-empty-catalogue-refused | Mara | Garbage | Pending | BUG-20260819-empty-catalogue-stamped-green | 688553f |
| 7 | CH-catalogue-floor-under-garbage | J-health-verdict / HLT-survivor-refused | Mara | Garbage | Pending | | |
| 8 | CH-catalogue-floor-under-garbage | J-health-verdict / HLT-open-gap-refused | Mara | Garbage | Pending | | |
| 9 | CH-catalogue-floor-under-garbage | J-health-verdict / HLT-unparseable-score-refused | Mara | Garbage | Pending | | |
| 10 | CH-review-seal-one-keystroke | J-review-round-seal / GATE-review-punctuated-placeholder-refused | Sessão | Paste | Pending | BUG-20260819-punctuated-rationale-buys-an-a | 272cb91 |
| 11 | CH-review-seal-one-keystroke | J-review-round-seal / GATE-review-empty-gate-field-refused | Sessão | Paste | Pending | BUG-20260819-empty-gate-field-passes | 272cb91 |
| 12 | CH-review-seal-one-keystroke | J-review-round-seal / GATE-review-placeholder-rationale-refused | Sessão | Paste | Pending | | |
| 13 | CH-review-seal-one-keystroke | J-review-round-seal / GATE-review-legit-short-rationale-passes | Sessão | Paste | Pending | | |
| 14 | CH-health-interrupted-mid-catalogue | J-health-verdict / HLT-stamp-window-refused | Rui | Interrupt | Pending | | |
| 15 | CH-health-interrupted-mid-catalogue | J-health-verdict / HLT-stamp-removed-on-red | Rui | Interrupt | Pending | | |
| 16 | CH-health-interrupted-mid-catalogue | J-certify-mission-close / GATE-pr-refuses-stale-stamp | Rui | Interrupt | Pending | | |
| 17 | CH-suite-list-is-not-a-run | J-suite-runs-something / SUI-list-prints-steps-only | Mara | Feature | Pending | | |
| 18 | CH-suite-list-is-not-a-run | J-suite-runs-something / SUI-testcmd-with-list-refused | Mara | Feature | Pending | | |
| 19 | CH-health-verdict-without-colour | J-health-verdict / HLT-verdict-readable-without-colour | Ada | Locale | Pending | | |
| 20 | CH-review-seal-one-keystroke | J-review-round-seal / GATE-review-escaped-pipe-in-rationale | Sessão | Paste | Pending | BUG-20260819-escaped-pipe-rationale-read-as-placeholder | 53586c5 |

Status legend: `Pending | Pass | Fixed | Skipped | Blocked (needs human verify) | Blocked (human decision)`

## Coverage taxonomy sweep

Per journey, where each of the five dimensions lands. A dimension neither covered nor consciously
skipped is a planning gap, so the skips carry their reasoning.

| Journey | 1. Journeys | 2. Functional | 3. Experiential | 4. Edge/error/empty | 5. Cross-cutting |
|---|---|---|---|---|---|
| J-certify-mission-close | rows 1-3, 16 | inside each row's expected observable | **skipped** — the experiential half of this journey is the 20-50 min wait, owned by row 14-16 rather than duplicated here | rows 1, 16 (missing stamp, stale stamp) | row 4 (does the rule cross into a target repo?) |
| J-health-verdict | rows 6-9, 14-15 | rows 7-9 | row 19 (Ada: is the verdict legible at all?) | rows 6, 9, 14, 15 (empty, unparseable, interrupted, red) | row 19 (terminal compatibility) |
| J-review-round-seal | rows 10-13 | rows 12-13 | **skipped** — the reader of a review round is a human opening a PR, and their experience is downstream of this cycle's diff; revisit when the PR body template changes | rows 10-11 (one-keystroke boundary, empty field) | row 13 (consistency with the codereview skill's own shorthand) |
| J-suite-runs-something | rows 17-18 | rows 17-18 | **skipped** — no experiential surface; the output is read by gates, and by a human only when it fails | row 17 (linter-absent world) | row 18 (TEST_CMD is shared by three gates) |
| J-target-repo-ships | rows 4-5 | rows 4-5 | **skipped** — Priya's first-impression experience is the install/preflight surface, which this diff does not touch; it belongs to a full-tier cycle | row 4 (a target repo that happens to own the scoping filename) | rows 4-5 — this journey **is** the cross-cutting dimension for the whole cycle |

Dimension 3 is skipped in four of five journeys, with a reason each time. That is the honest shape
of a CLI whose output is consumed by gates and by two humans; the one place it genuinely bites is
Ada's walk, and that has its own charter.

## Session Debriefs

<!-- Written by qa-execution, one block per charter run. Nothing here yet: no session has run. -->

## What Was Fixed

All four registry bugs are `fixed`, none is `verified`. They were fixed by the mission's own QA-EXEC
loop (increments F1-F3, three `sdd-executor` sessions) rather than by any charter in this cycle —
these charters have not been walked yet.

### BUG-20260819-empty-catalogue-stamped-green — F1, `688553f`
- **Symptom:** `kit healthy` and a green stamp over a catalogue that ran zero mutants.
- **Root cause:** the verdict validated the *relationship* between the score's numbers, never their
  magnitude — the one count in `cmd_health` without an anti-vacuity floor.
- **Fix:** check 2 now weighs `of N` against the `mut_*()` definitions on disk, with
  `MUTATION_CATALOGUE_FLOOR=8` for the case where both sides are emptied together.
- **Regression test:** `tests/check-health.sh`, four new worlds; `mut_HEALTH_catalogue_floor_blind`.
- **Residual, recorded not closed:** the floor lives only in the consumer. `tests/check-mutation.sh`
  still prints `of ${#CATALOG[@]}` unfloored, and the runner points operators at
  `tests/run-all.sh --with-mutation` in two places, where the green goes back to lying.
  Filed by the fixing session (`todo-findings` 83 -> 84, `202af04`).

### BUG-20260819-stamp-written-where-gate-cannot-read — F2, `1dc713f`
- **Symptom:** from a worktree with `sdd` on PATH, `gate_PR` refuses forever and its own remedy
  costs 20-50 minutes per futile lap.
- **Root cause:** two different answers to "which tree is this?" inside one feature — the writer
  keyed to `$SDD_HOME`, the reader to `$REPO_ROOT`.
- **Fix:** a single question (`has_mutation_catalogue`) read by both ends.
- **Regression test:** `tests/check-gates.sh` — the first world in the suite to run with
  `SDD_HOME != REPO_ROOT`, which is the fixture shape that had hidden the defect;
  `mut_HEALTH_stamp_tree_blind`.
- **Residual:** `xargs -0 -r` was added so the comment and the code agree, but no world reaches the
  empty-listing branch. Declared, not sold as measured.

### BUG-20260819-punctuated-rationale-buys-an-a and BUG-20260819-empty-gate-field-passes — F3, `272cb91`
- **Symptom:** an A bought by `TODO:` or a bare hyphen; a `gate:` field written and left blank
  passing while the guard's own comment said that case was the one refused.
- **Root cause:** two separate collapses — an open input space decided by exact match against an
  enumeration, and one predicate answering both "is this a placeholder?" and "does this exist?".
- **Fix:** presence moved into `frontmatter_has`/`gate_present`; punctuation-only cells refused and
  fill-in words normalised before lookup.
- **Regression test:** eleven differential worlds; `punctuation_only_blind`,
  `punctuated_fillin_blind`, `blank_gate_field_blind`, plus `mut_REVIEW_gate_field_blind`
  re-anchored. Catalogue 104 -> 115 across the mission.
- **Residual:** `FIXME` and `XXX` are refused with no world proving it
  (`todo-findings` 85 -> 86, `3f958f3`).
- **Kept measured, not merely intended:** removing the `—` exception turns the assertion red, so
  the `codereview` skill's own shorthand is held open by a probe.

### BUG-20260819-escaped-pipe-rationale-read-as-placeholder — REVIEW round, `53586c5` + `e2e5252`
- **Symptom:** a genuine rationale refused as a placeholder, with the refusal quoting text that
  appears nowhere in the file.
- **Root cause:** F3 promoted a field that had never been read into a verdict, and a latent parser
  looseness became reachable. `awk -F'|'` split the row on GFM's escaped pipe (`\|`), leaving a stub
  that normalised to a fill-in word; separately, passing `gate:` through `awk -v` ran it through
  awk's escape processing, so the message cited a string nobody wrote.
- **Fix:** columns reassembled before reading; the `gate:` value travels through the environment.
- **Regression test:** three new differential worlds in `tests/check-gates.sh` plus one mutant.
- **Why it matters to this cycle's shape:** it is the same failure family as the other four, pointed
  the **false-red** way. The plan's placeholder scenarios all pushed on "does a placeholder get
  refused?"; none asked "does a real sentence survive?" until this bug forced the pair. That gap was
  a planning gap, and `GATE-review-escaped-pipe-in-rationale` exists to close it.

## Human Verifications Needed

- [ ] Run `./bin/sdd health` (20-50 min) after the last code commit and before the PR phase. It is
      the verification leg of BUG-20260819-empty-catalogue-stamped-green and
      BUG-20260819-stamp-written-where-gate-cannot-read, and no session in this mission has yet seen
      it green end to end — two background attempts died without printing a `score:` line. It is
      also what writes the stamp `gate_PR` demands.
- [ ] Read the REVIEW round this mission produces against its own new rule, and move the two F3 bugs
      to `verified` if the gate's verdict on it is correct. That round is the first real exercise of
      the rule it came from.

## Decisions for a Human

### Whether `docs/qa/` exists in this repo — DECIDED 2026-08-19: install, with the contract updated
- What's broken: nothing — this was a scope decision, not a defect.
- Why not auto-decided: `qa_substep()` routes a no-interface project away from these skills, and an autonomous `sdd-qa` session already removed an earlier copy of this tree and recorded why in `9f84cbc`. Installing it anyway is a change to the repo's documented pipeline contract, which is a human's call.
- Options: 1. Commit the tree and update `docs/pipeline.md` so the next `sdd-qa` does not remove it — durable QA memory, plus a new `gate_QA` coupling on `bugs/`. 2. Keep it out of the repo — no contract change, and the QA knowledge stays where it is today, spread across per-mission handoffs.
- Recommendation: option 1, but **after** the in-flight EXEC session finishes F1-F3, and with the four bug files moved to `fixed`/`verified` in the same commit — otherwise `gate_QA` flips this mission back to QA the moment the tree lands.
- **Outcome:** option 1 chosen. F1-F3 landed (`688553f`, `1dc713f`, `272cb91`), all four bug files
  are `fixed`, so Anchor 3 counts zero `Status: open` and the tree does not reopen the phase.
  `docs/pipeline.md` and `agents/sdd-qa.md` are amended in the same commit so the next `sdd-qa`
  session reads "do not bootstrap one" instead of "one does not exist" — the wording that licensed
  the deletion in `9f84cbc`.

## Final Status

<!-- Written LAST, after the exit gate. Not reached: no session has run. -->
