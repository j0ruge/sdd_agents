# BUG-20260821-session-log-overwritten-in-the-same-second: the runner points two sessions at one log file and destroys the first one's transcript

- **Status:** verified <!-- open | fixed | verified | wont-fix | invalid -->
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

## Fix

- **Root cause:** the file name carried second-resolution time and nothing else, so it identified a
  SECOND rather than an invocation. The session id that would identify the invocation was already
  minted three lines above and was not used.
- **Fix commit:** `6d69a99` (increment I1 of M1)
- **The family had three sites, not one.** `run_phase` was the P0; `run_check_cmd` had the same
  defect one function over and *worse* — it carried the clock time with no date at all, so two runs
  on different days at the same second collided too, and it is the log `GATE_WHY` sends the operator
  to read. `cmd_close` had the same spelling. The two derived names (`.stream.jsonl`, `.err`) come
  from `${logfile%.json}` and were fixed by the first one.
- **`$sid` and not `${resume_sid:-$sid}`,** which is what keeps the journal honest in both fields:
  `session=` goes on naming the conversation, `log=` starts naming the invocation, and the pointer
  follows the file by construction because the journal line prints the same variable. Two retries of
  one *resumed* session share `resume_sid` and would have collided again on the other spelling.
- **`mktemp` and not a counter, in `run_check_cmd`.** Every caller reads the phase as
  `"$(current_phase)"`, and a command substitution is a subshell: an incremented counter dies with
  the fork and the parent reuses the number the subshell just wrote under. Measured while fixing it —
  four executions of the check command in one `sdd run`, three files. `mktemp` creates the file
  atomically and assumes no shared state at all, which is the only property that survives being
  called from inside a substitution.
- **Regression test:** `tests/check-autonomy.sh`, block *"a second session in the same second does
  not overwrite the first"*. It FREEZES the clock for exactly the two formats a log name is built
  from — everything else goes to the real `date` — so the collision is the regime the assertion runs
  in every time instead of a race it usually loses. Both assertions are self-relative (one transcript
  per session, one log per execution) and each carries its own anti-vacuity floor; the freeze itself
  carries a floor proving the poison is armed.
- **Catalogue mutants:** `mut_RUN_phase_log_time_only` and `mut_RUN_check_log_time_only` put the old
  form back. Verified one at a time: each kills exactly one assertion, with no overlap.
- **The two consumers named above were checked and neither moved.** `tests/check-autonomy.sh` and
  `tests/check-gates.sh` glob (`*.json`, `*.stream.jsonl`) or count the journal, never a literal
  name; `tests/check-health.sh` matches no log name at all. `bin/sdd`'s only other reference is the
  comment above `pipeline_log_line`, whose `gate-*-test-*.log` pattern still matches. The stale
  sentence in `check-gates.sh` — which cited this very collision as the reason not to count files —
  was rewritten in the fix commit rather than left to read as a live defect.

## Verification

- **Retested:** 2026-08-24, increment I1 of M1 · reproduction re-walked from this file, step 3
  ("simply let one `sdd run` retry the phase, which it does automatically when the session moved
  nothing"), with the clock frozen so both sessions land in one second by construction.
- **Result:** confirmed fixed. Two sessions of one phase, two distinct journal lines, two distinct
  `log=` paths, two transcripts on disk — `EXEC-20260101-120000-4fe4bfb0.*` and
  `EXEC-20260101-120000-adcccde0.*`. Red before the fix, in the same fixture and the same second:
  two sessions, one pointer, one transcript.
- **Scope of the retest, stated plainly:** a suite fixture with a stubbed `claude`, not a live
  mission. That is the environment this bug's own Reproduction section prescribes, and for the same
  reason it gives — a session that ends immediately is exactly what a failing phase does — but it is
  a fixture, and the first live exercise will be the next real `sdd run`.
