# BUG-20260821-session-log-overwritten-in-the-same-second: the runner points two sessions at one log file and destroys the first one's transcript

- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->
- **Impact (user-side):** Data-Loss
- **Severity:** Critical · **Priority:** P0
- **Persona Affected:** Rui
- **Journey Step:** J-trouble-stops-the-line, step 4 (a phase runs, fails, and the operator goes to read why)
- **Scenarios:** RUN-session-log-survives-a-second-session
- **Found:** 2026-08-21 · **Report:** ../reports/2026-08-21-missao-porteira.md

## Summary

Rui's REVIEW phase ran twice and failed twice. He opens the log the runner told him to read and
finds **one** file where there should be two — the first session's transcript is gone, overwritten
by the second, and nothing anywhere says it ever existed. The mission journal makes it worse rather
than better: it recorded both sessions faithfully, with two different session ids, and pointed both
of them at the *same path*.

The phase that costs the most is the phase whose evidence is most likely to disappear, because
retrying is what makes two sessions land close together in the first place.

## Reproduction

- **Charter:** CH-a-phase-died-and-left-the-tree-dirty · **Tour:** Interrupt Tour
- **Environment:** laptop / wifi-fast / pt-BR; local shell, no service. `claude` replaced by a stub
  that exits non-zero, so both sessions end immediately — which is what makes the collision easy to
  hit and is also exactly what a failing phase does in production.

1. Drive any mission to a phase whose gate does not pass, so the phase will run again.
2. Run the phase: `sdd run <mission> --phase REVIEW --max-phases 1`.
3. Run it again within the same second — or simply let one `sdd run` retry the phase, which it does
   automatically when the session moved nothing.
4. Read the two session lines in `.sdd/logs/<mission>/pipeline.log`, then list
   `.sdd/logs/<mission>/REVIEW-*.json`.

**Expected:** two sessions produced two readable transcripts, one per session id.
**Actual:** two journal lines naming two distinct session ids, both citing
`REVIEW-20260821-023554.json`; one file on disk; the earlier session's content destroyed.

## Evidence

- Journal, verbatim — two sessions, one path:
  ```
  session 85dae4b2-1ddf-4185-9381-fca44d46a50f  ->  REVIEW-20260821-023554.json
  session 8131f2db-e33b-43c0-9668-eb7fbea6833a  ->  REVIEW-20260821-023554.json
  ```
- `ls .sdd/logs/20260821-rate-limits/REVIEW-*` → `REVIEW-20260821-023554.json` and
  `REVIEW-20260821-023554.stream.jsonl`. One of each, for two sessions.
- Independent read path: the journal is written by a different code path than the log file, and it
  is the one that survived intact — which is how the loss is provable rather than merely suspected.

## Notes on the impact tier

Filed **Data-Loss** rather than Trust-Damage, and the call is arguable — a reviewer may downgrade
it, but should do so deliberately:

- *For Data-Loss:* the product creates an artifact, tells the operator to read it, and then destroys
  it silently, without consent and without the operator noticing. That is the tier's definition
  almost word for word, and its release-impact note — "silent loss is worse than visible failure,
  users can't recover from what they don't notice" — is the whole story here.
- *For Trust-Damage:* the destroyed data is product-generated diagnostics, not something a user
  entered, uploaded or configured, which is how that tier's definition is worded. The closest
  listed example is on the Trust-Damage side: *"confirmation email cites a different order id than
  the UI"* — a record pointing at the wrong thing.

The rubric says to take the higher tier when in doubt, so: Data-Loss.

## Direction (not a fix — the governor sends this to a human)

The collision is in the filename, which carries second-resolution time and nothing else. The
session id is already generated before the log path is built and is already unique per session.
Any fix has to keep `pipeline.log`'s `log=` field agreeing with whatever lands on disk — the two
are read together, and a fix that changed only one would replace lost data with a wrong pointer.

⚠️ Two consumers depend on the current shape and must be checked before changing it:
`tests/check-health.sh` and `tests/check-gates.sh` count or match these files by name, and this
repo's own `TODO.md` already carries a related note about counting sessions by log file.
