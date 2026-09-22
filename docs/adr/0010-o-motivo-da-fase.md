# ADR 0010 — A moved disk is not progress when the phase comes back for the same reason

- **Status**: proposed (—, 2026-09-22)
- **Spec**: docs/handoffs/20260922-o-motivo-da-fase/00-missao.md

## Context

Until this decision the runner had exactly one definition of progress: `state_fingerprint()`
(`bin/sdd:3753`) hashes HEAD, the mission listing and the checkpoint's md5, and a session "moved
forward" whenever that hash changed. The `no-progress` escalation (`bin/sdd:6984-6990`) fires only
when two consecutive sessions leave the hash untouched.

One incident on 2026-09-22 showed what that definition misses. On `lighthouse_project` (kit at
`ea39868`) a single checkpoint cell carried its SHA in backticks (`` `19c2c89` ``).
`checkpoint_rows()` trims spaces but not backticks, so `gate_EXEC` asked `git cat-file` about the
literal string and answered "does not exist". `current_phase()` therefore kept deriving EXEC. The
reason for that choice died in the `$(current_phase)` subshell, so the executor never learned it.
It found no `pending` row and made a no-op commit. The commit moved HEAD, `moved=true`, and the
runner bought the next lap. The result was two paid sessions (US$ 1,94) that changed nothing that
mattered. The third was killed by hand; without that the loop stopped only at
`BUDGET_MISSION_USD`. Every one of those sessions is logged as `rc=0` in the journal.

This is the "unsatisfiable gate" class of principle 1 in `CLAUDE.md`. The runner reads "the disk
moved" as progress, and a session with no work to do can always move the disk.

## Decision

1. **The reason travels with the phase.** A function called directly (never `$( )`) derives the
   phase and publishes both the phase and its `GATE_WHY` in globals. `cmd_run` and `cmd_retry` use
   it. The reason is written to the journal (`PHASE <X> reason="…"`) and put in every phase's boot
   prompt.
2. **A moved disk no longer buys a lap by itself.** A new escalation kind, `no-work` (rc 3,
   `event: "blocked"`), stops the line in two narrow cases:
   - **(b)** before a session opens, when the gate's reason belongs to the *unreadable checkpoint
     cell* class (`done` without a commit, a commit that does not exist, a commit off HEAD's
     history, an invalid status, a cell that is not a SHA). No session can fix these by doing
     increment work. The class is marked positively by `gate_EXEC` at those sites and is never
     inferred from the text.
   - **(a)** when the same **step** (`phase_step`: QA's sub-step, the phase everywhere else) comes
     back derived with the **same** reason on consecutive laps, unless that reason cites a log. A
     red suite produces the same sentence even when a session fixed half of it, and stopping it
     would stop real work. Keyed on the step by a human decision taken during execution: keyed on
     the phase, every QA with an interface stopped after `QA:plan`, because `gate_QA` says
     `missing 30-handoff-qa.md` after the plan and the walk alike.
   It lives in three doors: `cmd_run`'s first pass (derived laps only, the last refusal before the
   session, below the Jidoka pre-checks and the ceilings, which keep their own kinds and the draft
   degradation), its inline retry, and `cmd_retry`. Only the first door reads (a). There is one
   probe and one mutant per door.
3. **The cell is read the way a human reads it.** `checkpoint_rows` strips backticks from the commit
   cell. That function is the single reader, so every consumer is fixed at once. A cell that is
   still not hex after that gets its own gate message.

## Alternatives discarded

- **Reuse `no-progress`.** That kind already means "two sessions moved nothing", and `docs/pipeline.md`
  classes it as pure friction that D12/D16 read as the pipeline spinning. Here the session did move
  the disk. Folding both into one kind would merge two different diagnoses, the same way
  `session-died` had to be split from it on 2026-09-18.
- **Refuse EXEC whenever there are zero `pending` rows.** Measured against `gate_EXEC`: zero pending
  is legitimate when the suite is red (`bin/sdd:1005`/`1008`) or `20-handoff-exec.md` is missing
  (`:1011`). A session is the right answer in both cases. The refusal has to be keyed on the
  reason's class, not on the count.
- **"Same reason twice ⇒ stop", unqualified.** A session that fixes part of a red suite leaves
  `TEST_CMD failed — see <log>` unchanged and would be stopped while working. Hence the log
  exclusion. (Measured during execution: today every cited log is a per-execution `mktemp`, so two
  log-citing reasons are never the same text and the exclusion has no probe. It stays for the day a
  log path becomes stable, and the missing probe is declared where the predicate is defined.)
- **Key (a) on the phase.** It was the plan's key. The first probe found that it stops every QA
  with an interface after its first sub-step, which is real progress behind a stable reason.
- **Door 1 above the Jidoka pre-checks and the ceilings.** Placed there, (a) pre-empted
  `review-to-draft` and `budget-exhausted`, which are designed stops with their own remedies.
- **Re-call `gate_"$phase"` directly after `$(current_phase)`, as `cmd_status` does.** Inside
  `cmd_run` this re-runs `TEST_CMD` on every lap, because the `run_check_cmd` cache dies in the
  subshell (`TODO.md:705`). Publishing from a directly called function fixes both. A counter sensor
  (`TODO.md:320`) now pins it.
- **Validate the cell on write.** The runner has no write point for the cell, because the agent
  writes it. That layer can only be agent text plus the gate's message, and it is said so rather
  than implied.

## Consequences

- A `no-work` row in the ledger is new, deliberate Jidoka. `is_escalation` is defined on `.event`
  (`bin/sdd:7492`, `:7982`), so the row is admitted without editing either definition. The kind
  table in `docs/pipeline.md` and the `ON_ESCALATION_CMD` list in `config/schema.md` change in the
  same commit as the code, and a differential assertion proves that both readers count the row
  alike.
- Declared limits: `sdd kaizen` keeps its own `no-progress` loop. Case (a) applies only on the
  derived branch; a `--phase X` lap has no previous derived reason to compare against. `cmd_status`,
  `cmd_phase` and `cmd_why` keep `$(current_phase)`.
