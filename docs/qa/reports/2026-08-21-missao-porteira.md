# QA Run Report — 2026-08-21 — branch `20260820-missao-porteira`

- **Scope:** the diff of `main...20260820-missao-porteira` — the missão-porteira, 14 increments closing the blockers on the critical path to using the kit in real work (PR #17)
- **Cadence tier:** targeted (branch/PR cycle) + 1 adjacent journey as canary
- **Build:** `4e3a47c` (last commit; `sdd health` green at `128 caught of 128` with the stamp written) · **Environment:** local shell; no service, no URL — `E2E_CMD=""`, no `APP_URL`
- **Started:** 2026-08-21 · **Status:** in-progress <!-- in-progress | closed -->

> **Planning output only.** Every matrix row below is `Pending`: this report was created by
> `qa-report` before any session ran, which is what the template asks for. No bug was filed by this
> pass — nothing was walked, so nothing was found. The registry's five entries are last cycle's,
> all `fixed`, and three of them are re-walked here because *fixed* was never followed by *verified*.

## Personas

| Persona | Base | Device / Network / Locale | Sessions |
|---|---|---|---|
| Rui | Recovering User | laptop / wifi-fast / pt-BR | CH-a-phase-died-and-left-the-tree-dirty |
| Priya | New User | laptop / wifi-fast / en-US | CH-first-two-commands-in-a-strangers-repo, CH-the-branch-the-card-created, CH-target-repo-stamp-leak *(re-run)* |
| Sessão | New User (amnesiac) | desktop / wifi-fast / pt-BR | CH-a-formatter-rewrote-the-mission |
| Mara | Power User | laptop / wifi-fast / pt-BR | CH-review-round-after-the-porteira, CH-catalogue-floor-under-garbage *(re-run)*, CH-stamp-round-trip-from-a-worktree *(re-run)* |
| Ada | Accessibility-Reliant | laptop / flaky / en-US | CH-the-line-stopped-without-colour |

All five personas are in scope, which is unusual for a targeted tier and is a property of the diff:
it touched the first two commands a new adopter types (Priya), two new escalations an operator meets
after a dead session (Rui), three parsers the headless session depends on (Sessão), the review round
(Mara), and four commands' worth of new terminal output (Ada).

## Flows in Scope

- `J-trouble-stops-the-line` — **new**; a mission that hits trouble stops instead of spending sessions in a loop (`../journeys/J-trouble-stops-the-line.md`)
- `J-target-repo-ships` — **updated**; five of the fourteen changes land on Priya's first two commands (`../journeys/J-target-repo-ships.md`)
- `J-checkpoint-survives-a-formatter` — **new**; somebody else's tooling rewrites the tables the kit parses (`../journeys/J-checkpoint-survives-a-formatter.md`)
- `J-ticket-opens-and-branch-lands` — **new**; the JIRA path, never walked before (`../journeys/J-ticket-opens-and-branch-lands.md`)
- `J-review-round-seal` — **updated**; the alignment-colon face of the parser bug, plus the exemplar that contradicted its own gate (`../journeys/J-review-round-seal.md`)
- `J-certify-mission-close` / `J-health-verdict` — **canary, unchanged**; the diff rewrote `bin/ tests/ templates/ config/` wholesale, which is exactly the key the mutation stamp is content-addressed on (`../journeys/J-certify-mission-close.md`)

## Session Matrix & Results

| # | Charter | Journey / Scenario | Persona | Tour | Status | Issue | Fix commit |
|---|---|---|---|---|---|---|---|
| 1 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-dirty-tree-stops-the-line | Rui | Interrupt | Pending | | 550dc98 |
| 2 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-red-suite-clean-tree-still-runs | Rui | Interrupt | Pending | | 550dc98 |
| 3 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-dirty-tree-refusal-names-the-remedy | Rui | Interrupt | Pending | | 550dc98 |
| 4 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-review-rounds-counted-in-total | Rui | Interrupt | Pending | | d3dea51 |
| 5 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-forced-review-round-still-runs | Rui | Interrupt | Pending | | d3dea51 |
| 6 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-install-seeds-the-tree | Priya | Garbage | Pending | | 04d0e00 |
| 7 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-install-first-manifest-wins | Priya | Garbage | Pending | | 04d0e00 |
| 8 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-preflight-refuses-noop-testcmd | Priya | Garbage | Pending | | 41f6c34 |
| 9 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-preflight-warns-missing-skills | Priya | Garbage | Pending | | 1e20d6c |
| 10 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-preflight-skill-warning-follows-the-config | Priya | Garbage | Pending | | 1e20d6c |
| 11 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-schema-promises-only-what-is-read | Priya | Garbage | Pending | | c8070dc |
| 12 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / GATE-exec-escaped-pipe-keeps-status | Sessão | Paste | Pending | | 5434a65 |
| 13 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / GATE-exec-alignment-colon-not-an-increment | Sessão | Paste | Pending | | db26cc1 |
| 14 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / GATE-docs-alignment-colon-not-a-status | Sessão | Paste | Pending | | db26cc1 |
| 15 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / RUN-status-agrees-with-the-gate | Sessão | Paste | Pending | | 5434a65 |
| 16 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / RUN-ticket-boots-one-driver | Priya | Feature | Pending | | 557e267 |
| 17 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / GATE-ticket-branch-must-reach-mission | Priya | Feature | Pending | | 779d87a |
| 18 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / GATE-ticket-branch-mismatch-refused | Priya | Feature | Pending | | 779d87a |
| 19 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / GATE-ticket-without-branch-still-passes | Priya | Feature | Pending | | 779d87a |
| 20 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / RUN-ticket-branch-carries-later-phases | Priya | Feature | Pending | | 779d87a |
| 21 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-alignment-colon-not-a-criterion | Mara | Feature | Pending | | db26cc1 |
| 22 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-exemplar-matches-the-gate | Mara | Feature | Pending | | 346b0a2 |
| 23 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-placeholder-rationale-refused | Mara | Feature | Pending | | |
| 24 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-punctuated-placeholder-refused | Mara | Feature | Pending | BUG-20260819-punctuated-rationale-buys-an-a | 272cb91 |
| 25 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-empty-gate-field-refused | Mara | Feature | Pending | BUG-20260819-empty-gate-field-passes | 272cb91 |
| 26 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-escaped-pipe-in-rationale | Mara | Feature | Pending | BUG-20260819-escaped-pipe-rationale-read-as-placeholder | 53586c5 |
| 27 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-legit-short-rationale-passes | Mara | Feature | Pending | | |
| 28 | CH-the-line-stopped-without-colour | J-trouble-stops-the-line / RUN-dirty-tree-refusal-names-the-remedy | Ada | Locale | Pending | | 550dc98 |
| 29 | CH-the-line-stopped-without-colour | J-trouble-stops-the-line / RUN-phase-budget-fits-the-phase | Ada | Locale | Pending | | 2be05fd |
| 30 | CH-catalogue-floor-under-garbage *(re-run)* | J-health-verdict / HLT-empty-catalogue-refused | Mara | Garbage | Pending | BUG-20260819-empty-catalogue-stamped-green | 688553f |
| 31 | CH-stamp-round-trip-from-a-worktree *(re-run)* | J-certify-mission-close / GATE-pr-stamp-read-from-gate-tree | Mara | Multi-Tab | Pending | BUG-20260819-stamp-written-where-gate-cannot-read | 1dc713f |
| 32 | CH-target-repo-stamp-leak *(re-run)* | J-target-repo-ships / TGT-pr-gate-silent-in-target | Priya | Feature | Pending | | |

Status legend: `Pending | Pass | Fixed | Skipped | Blocked (needs human verify) | Blocked (human decision)`

Rows 30-32 re-run charters written last cycle, unedited — three of the five registry bugs are
`fixed` with their scenarios still at `fail`, which means the fix was applied and nobody re-walked
it. A fix that cannot be re-walked is not a fix.

## Coverage taxonomy sweep

Per journey, where each of the five dimensions lands. A dimension neither covered nor consciously
skipped is a planning gap, so the skips carry their reasoning.

| Journey | 1. Journeys | 2. Functional | 3. Experiential | 4. Edge/error/empty | 5. Cross-cutting |
|---|---|---|---|---|---|
| J-trouble-stops-the-line | rows 1-5 | rows 1-2, 4-5 (the differential pairs) | rows 28-29 (Ada: is a stopped run legible as stopped?) | rows 1, 3, 4 — this journey **is** the error dimension: every node is a way a mission goes wrong | row 29 (one damage cap per phase, read off the projected argv) |
| J-target-repo-ships | rows 6-11, 32 | rows 6-8, 11 | **skipped** — Priya's first-impression experience now genuinely changed (two new preflight lines), but it is *her reading of a refusal*, which rows 8-10 settle functionally. A first-impression walk with no prior knowledge belongs to a full-tier cycle, not to a branch pass by someone who wrote the messages |
| | | | | rows 7-10 (two manifests, no-op suite, absent skills, four config shapes) | row 32 (the canary: does kit-only machinery stay out of her repo?) |
| J-checkpoint-survives-a-formatter | rows 12-15 | rows 12-14 | row 15 (`sdd status` and the gate disagreeing is experienced as distrust, not as a bug) | rows 12-14 — the whole journey is an edge the product did not know it had | row 15 (two readers of one file must agree) |
| J-ticket-opens-and-branch-lands | rows 16-20 | rows 17-19 | **skipped** — the phase has never been walked at all, so there is no experience to regress yet; the first walk is row 16-20 and the experiential pass belongs to the cycle after it | rows 18-19 (a different branch, no branch at all) | row 20 (the branch name crosses the ticket skill, two artifacts, a checkout and every later phase) |
| J-review-round-seal | rows 21-27 | rows 23-27 | **skipped** — unchanged from last cycle and for the same reason: the reader of a round is a human opening a PR, and the PR body template did not move in this diff | rows 21, 24-26 (formatter colons, one-keystroke boundary, empty field, escaped pipe) | row 22 (the agent file and the gate must not contradict each other) |
| J-certify-mission-close / J-health-verdict | rows 30-31 | rows 30-31 | covered by `CH-health-verdict-without-colour`, not re-run this cycle | rows 30-31 (empty catalogue, stamp written where the gate cannot read it) | rows 30-31 — the stamp is content-keyed on the four directories this diff rewrote wholesale |

Dimension 3 is skipped in three of six journeys, each with a reason, and two of the three skips name
the cycle that should pick it up. That is one fewer skip than last cycle: `J-trouble-stops-the-line`
and `J-checkpoint-survives-a-formatter` both have a real experiential surface, because both are
about an operator's *trust* in what the runner says rather than only about a verdict being correct.

## Session Debriefs

_(none — no session has run; `qa-execution` writes one block per charter here)_

## What Was Fixed

_(nothing this pass — planning output only. The fix commits in the matrix are the mission's own, and
they are what the sessions above have to confirm.)_

## Human Verifications Needed

- **The TICKET phase needs a real JIRA project** (rows 16-20). The kit's own config has
  `JIRA_ENABLED=false`, so every claim about that phase is currently theoretical. Either the walk
  gets a real `.jira-project` and an `acli` that can create a card, or the session records
  explicitly that it simulated the walk and what that leaves unproven. Do not create cards in a
  project anyone else reads.
- **A real markdown formatter has to be available** (rows 12-15). The point of that session is that
  the fixtures currently proving the fix are hand-typed imitations of what prettier writes.

## Decisions for a Human

### The retest debt is now two cycles old

Five bugs were filed on 2026-08-19, all five were fixed in that mission, and none was ever
re-walked: the scenarios still read `fail`. `gate_QA` counts only `open` bugs, so nothing is holding
a phase shut and the debt is invisible to the pipeline — which is exactly how it survived a whole
mission. Rows 24-26 and 30-31 pay it. If a session cannot re-walk one of them, the honest move is
to reopen the bug, not to mark the scenario `pass`.

### Last cycle's report is still `Status: in-progress`

`reports/2026-08-19-fecho-que-nao-mente.md` was never closed, because no `qa-execution` session
ever ran against it. It costs nothing today (`gate_QA` reads `reports/` only when `E2E_CMD` or
`APP_URL` is set, and neither is), but it means this tree has two open planning passes and zero
walked sessions. Two plans and no walks is the failure mode a living QA tree is supposed to prevent,
and it is worth deciding deliberately: run the sessions, or record that this tree is a design
artifact and stop planning into it.

## Learnings

- **An abandonment path went stale and nobody would have noticed.** `J-target-repo-ships` recorded
  "nothing in the kit inspects a target repo's `TEST_CMD` at all" as the reason a trimmed suite was
  safe. One increment (`41f6c34`) made it false. Abandonment paths are conclusions with a shelf
  life; they get re-read against the diff every cycle rather than trusted.
- **Three of the diff's fourteen changes are the same promise seen three times** — a phase that
  dies, a ceiling that resets, a budget that does not fit the phase are all *trouble costing money
  more than once*. Mapping them as one journey found the differential each of them needs; mapping
  them as three features would have produced three happy-path checks and no twin.

## Final Status

**Planning complete, nothing walked.** 3 journeys added, 3 updated, 6 charters written, 24 scenarios
minted, 1 scenario's declared scope corrected, 1 automation-backlog item recorded, 0 bugs filed.
32 sessions are queued across 9 charters (6 new, 3 re-run unedited).
