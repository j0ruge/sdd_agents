# QA Run Report — 2026-08-21 — branch `20260820-missao-porteira`

- **Scope:** the diff of `main...20260820-missao-porteira` — the missão-porteira, 14 increments closing the blockers on the critical path to using the kit in real work (PR #17)
- **Cadence tier:** targeted (branch/PR cycle) + 1 adjacent journey as canary
- **Build:** `4e3a47c` (last commit; `sdd health` green at `128 caught of 128` with the stamp written) · **Environment:** local shell; no service, no URL — `E2E_CMD=""`, no `APP_URL`
- **Started:** 2026-08-21 · **Status:** closed <!-- in-progress | closed -->

> **Walked 2026-08-21.** Planned by `qa-report` with every row `Pending`, then executed by
> `qa-execution` in the same day. 32 rows, zero `Pending` at close. Every session ran against real
> throwaway repositories built for it — `sdd install` for real, real commits, a real prettier 3.9.6
> — never against a suite fixture.
>
> ⚠️ **Fidelity deviation, disclosed because it cannot be removed: the walker wrote the code under
> test.** Persona fidelity forbids reading source mid-session to decide what *should* happen, and
> that knowledge cannot be unlearned. It was mitigated, not eliminated: every verdict was taken
> from a public read path (`sdd status`, `sdd why`, `sdd phase`, `--dry-run`, the journal, `git`),
> the oracle for each row was the `expected` line its scenario file already carried, and three
> probes were caught being wrong *before* the product was. It still qualifies every `Pass` below —
> an independent walker would be worth more than a re-run by this one.
>
> **Parity deviations:** `claude` and `gh` were replaced by stubs (a session costs real money, and
> the point of five of these rows is that no session opens at all). That invalidates only the
> preflight's own auth line, which no row here settles. No JIRA project was touched.

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
| 1 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-dirty-tree-stops-the-line | Rui | Interrupt | Pass | | 550dc98 |
| 2 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-red-suite-clean-tree-still-runs | Rui | Interrupt | Pass | | 550dc98 |
| 3 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-dirty-tree-refusal-names-the-remedy | Rui | Interrupt | Pass | | 550dc98 |
| 4 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-review-rounds-counted-in-total | Rui | Interrupt | Pass | | d3dea51 |
| 5 | CH-a-phase-died-and-left-the-tree-dirty | J-trouble-stops-the-line / RUN-forced-review-round-still-runs | Rui | Interrupt | Pass | | d3dea51 |
| 6 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-install-seeds-the-tree | Priya | Garbage | Pass | | 04d0e00 |
| 7 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-install-first-manifest-wins | Priya | Garbage | Pass | | 04d0e00 |
| 8 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-preflight-refuses-noop-testcmd | Priya | Garbage | Pass | | 41f6c34 |
| 9 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-preflight-warns-missing-skills | Priya | Garbage | Pass | | 1e20d6c |
| 10 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-preflight-skill-warning-follows-the-config | Priya | Garbage | Pass | | 1e20d6c |
| 11 | CH-first-two-commands-in-a-strangers-repo | J-target-repo-ships / TGT-schema-promises-only-what-is-read | Priya | Garbage | Blocked (human decision) | | c8070dc |
| 12 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / GATE-exec-escaped-pipe-keeps-status | Sessão | Paste | Pass | | 5434a65 |
| 13 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / GATE-exec-alignment-colon-not-an-increment | Sessão | Paste | Pass | | db26cc1 |
| 14 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / GATE-docs-alignment-colon-not-a-status | Sessão | Paste | Pass | | db26cc1 |
| 15 | CH-a-formatter-rewrote-the-mission | J-checkpoint-survives-a-formatter / RUN-status-agrees-with-the-gate | Sessão | Paste | Pass | | 5434a65 |
| 16 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / RUN-ticket-boots-one-driver | Priya | Feature | Pass | | 557e267 |
| 17 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / GATE-ticket-branch-must-reach-mission | Priya | Feature | Pass | | 779d87a |
| 18 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / GATE-ticket-branch-mismatch-refused | Priya | Feature | Pass | | 779d87a |
| 19 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / GATE-ticket-without-branch-still-passes | Priya | Feature | Pass | | 779d87a |
| 20 | CH-the-branch-the-card-created | J-ticket-opens-and-branch-lands / RUN-ticket-branch-carries-later-phases | Priya | Feature | Blocked (needs human verify) | | 779d87a |
| 21 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-alignment-colon-not-a-criterion | Mara | Feature | Pass | | db26cc1 |
| 22 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-exemplar-matches-the-gate | Mara | Feature | Pass | | 346b0a2 |
| 23 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-placeholder-rationale-refused | Mara | Feature | Pass | | |
| 24 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-punctuated-placeholder-refused | Mara | Feature | Fixed | BUG-20260819-punctuated-rationale-buys-an-a | 272cb91 |
| 25 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-empty-gate-field-refused | Mara | Feature | Fixed | BUG-20260819-empty-gate-field-passes | 272cb91 |
| 26 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-escaped-pipe-in-rationale | Mara | Feature | Fixed | BUG-20260819-escaped-pipe-rationale-read-as-placeholder | 53586c5 |
| 27 | CH-review-round-after-the-porteira | J-review-round-seal / GATE-review-legit-short-rationale-passes | Mara | Feature | Pass | | |
| 28 | CH-the-line-stopped-without-colour | J-trouble-stops-the-line / RUN-dirty-tree-refusal-names-the-remedy | Ada | Locale | Pass | | 550dc98 |
| 29 | CH-the-line-stopped-without-colour | J-trouble-stops-the-line / RUN-phase-budget-fits-the-phase | Ada | Locale | Pass | | 2be05fd |
| 30 | CH-catalogue-floor-under-garbage *(re-run)* | J-health-verdict / HLT-empty-catalogue-refused | Mara | Garbage | Fixed | BUG-20260819-empty-catalogue-stamped-green | 688553f |
| 31 | CH-stamp-round-trip-from-a-worktree *(re-run)* | J-certify-mission-close / GATE-pr-stamp-read-from-gate-tree | Mara | Multi-Tab | Skipped | BUG-20260819-stamp-written-where-gate-cannot-read | 1dc713f |
| 32 | CH-target-repo-stamp-leak *(re-run)* | J-target-repo-ships / TGT-pr-gate-silent-in-target | Priya | Feature | Pass | | |

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

### CH-a-phase-died-and-left-the-tree-dirty — Rui (Interrupt Tour, 60 min)

Built `acme-api`: a real repo, a real two-file suite, a mission with its increment `done` and
committed. Then killed a phase the way phases die — an edit to `src/auth.sh` left uncommitted,
which makes the suite red *because of work nobody approved*.

The line stopped. `rc 3`, one `BLOCKED  EXEC  red suite over a dirty working tree` in the journal,
**zero** `EXEC agent=` lines, and the stub `claude` never spoke. Re-running twice more cost exactly
the same: three attempts, three ledger rows, zero sessions. That is the whole point — a refusal a
human can safely ignore is one that costs nothing to repeat.

The differential is what makes it a verdict rather than an anecdote: `git commit` the same broken
edit, so the suite stays red and the tree goes clean, and the identical command **opens a session**.
One `echo` apart, opposite outcomes.

Then the ceiling, with the numbering that separates a lexicographic reader from a version-ordered
one: rounds `r1 r2 r3 r10` on disk, `REVIEW_MAX_ITER=5`. A lexicographic reader sees `r3` and allows;
the runner said *"10 review round(s) already on disk"* and refused, with no session spent. Raising
the ceiling to 99 let the same state run; `--phase REVIEW` ran it too. Three states, three different
outcomes, one fixture.

**Found underneath:** two REVIEW sessions landed on one log file (`BUG-20260821-…`). Neither row was
looking for it; the tour was.

### CH-first-two-commands-in-a-strangers-repo — Priya (Garbage Tour, 60 min)

Two fresh repos carrying `package.json` **and** `go.mod`, created in both orders. Both installed
with `npm test`: first match wins, no longer last. The install seeded `docs/handoffs/` and a
`TODO.md` that teaches the entry format, and a second install over a file holding a real finding
left it byte for byte.

The Garbage Tour on `TEST_CMD`: eight no-op spellings (`true`, `:`, `echo ok`, `printf hi`,
`exit 0`, `npm test -- --list`, `jest --listTests`, `pytest --collect-only`) — all eight refused,
each naming the consequence. Six real commands (`npm test`, `tests/run-all.sh`,
`./run.sh --listen-port 8080`, `make test && echo done`, `go test ./...`, `npm run test:ci`) — none
accused. The near miss the padding exists for, `--listen-port`, behaved.

The skill warning was asked for by config across all four shapes: JIRA off + no interface asks for
`codereview` alone; JIRA on adds `ticket`; an interface adds `qa-report qa-execution`; both adds all
four. With the skills present the line goes quiet and says so positively.

**Found:** the installer announces the base branch it detected *and asks her to confirm it*, and
says nothing at all about the `TEST_CMD` it detected — the one value every gate trusts. Paper cut
below. **Escalated:** `E2E_DIR`.

### CH-a-formatter-rewrote-the-mission — Sessão (Paste Tour, 60 min)

Ran a real `prettier@3.9.6` over `docs/handoffs/**/*.md` — eight files rewritten, 22 insertions.
The mission did not move: phase `REVIEW` before, `REVIEW` after, the increment still read, `sdd
status` and `sdd why` still agreeing.

**The walk corrected the plan.** Prettier's *default* is not alignment colons — left alone it writes
`| --- | ------ |`, padded, which the old regex already survived after trimming. Colons appear when
the **author** aligned the table and prettier preserves it, reformatting `|:---:|` into `| :----: |`.
Both spellings were then walked deliberately, plus a Check cell carrying `\|`, and the mission
advanced REVIEW → DOCS → PR through artifacts the formatter had rewritten. The bug was real; its
trigger is narrower and just as reachable as the journey claimed.

### CH-the-branch-the-card-created — Priya (Feature Tour, 90 min)

The phase nobody had walked. `--dry-run --phase TICKET` shows `agent: sdd-publisher` and a boot
prompt that opens with the phase statement — one driver, no prepended slash.

Four branch worlds, one fixture: branch in `10-ticket.md` with `00-missao.md` still on the
placeholder → refused, naming the artifact it has to reach; a *different* name → refused, quoting
both; written back → `EXEC`; and a `10-ticket.md` with no branch at all (every mission planned
before the field) → `EXEC`. Without that fourth world the first two would be satisfied by a gate
that refused everything.

Then the runner honoured it for real: from `main`, with the branch not yet existing, `sdd run`
printed `ok branch: main → feature/SQ-412-quote-pdf (declared in 00-missao.md)`, journalled the
switch, and ran EXEC on it.

**Not walked:** the `ticket` skill creating the real card and branch. That needs a live JIRA
project — row 20, blocked, with instructions.

### CH-review-round-after-the-porteira — Mara (Feature Tour, 60 min)

Eight rationales through the seal, on a colon-aligned, prettier-formatted round: a real sentence,
`clean`, `n/a` and `—` all passed; `<one measured sentence>`, `TODO:`, `-` and `…` were all refused
by name. The `gate:` frontmatter refused empty and refused `<evidence>`, and passed a filled one. A
rationale carrying `` `TODO\|` `` passed — the symptom of the 2026-08-19 bug, gone.

Three fixes that had sat `fixed` and unverified for a cycle are now `verified`, and they were
verified on a live target repo rather than a suite fixture — so the retest also covers the alignment
change that landed on top of the fix since.

The exemplar in `.claude/agents/sdd-reviewer.md` — the copy the harness loads, confirmed identical
to the kit source — carries one real sentence and the line saying the `<…>` cells are the shape.

### CH-the-line-stopped-without-colour — Ada (Locale Tour, 30 min)

`NO_COLOR=1`, 80 columns, every kit glyph replaced by `?`. The new escalation output survives:
`fail` and `warn` are **words**, and the remedy line — *"Commit what belongs to the mission, or
'git restore' what does not"* — is still there and still readable when the colour and the symbols
are gone.

The per-phase cap was read off the projected argv: `REVIEW 40`, `DOCS 15`, `PR 15`; raising
`BUDGET_PER_PHASE_USD` to 60 moved DOCS and PR to 60 and left REVIEW at 40 — the trade-off
`config/schema.md` declares, observed rather than believed.

**Found:** `sdd status` carries phase pass/fail on a **glyph alone** (`✓` vs `·`). Paper cut below.

### CH-catalogue-floor-under-garbage / CH-stamp-round-trip-from-a-worktree / CH-target-repo-stamp-leak — re-runs

The canary held: in a repo with no `tests/check-mutation.sh`, all seven gate messages together
mention the kit's self-maintenance **zero** times. The emptied-catalogue retest is described under
What Was Fixed. The stamp round-trip is row 31, skipped with its reason.

## What Was Fixed

Nothing was fixed **in this run** — the fix loop's governor authorised no edit, because the one new
finding is a Data-Loss bug whose repair touches a filename two sensors and a journal field depend
on. That is out of bounds by the governor's own rule and is escalated instead.

What the run did settle is four fixes that were applied *before* it and had never been re-walked:

### BUG-20260819-punctuated-rationale-buys-an-a → verified
`272cb91`. `TODO:`, `-` and `…` are refused by name; `clean`, `n/a` and `—` still pass. Walked on a
live target repo.

### BUG-20260819-empty-gate-field-passes → verified
`272cb91`. A `gate:` field present-but-empty is refused as `<empty>`; `<evidence>` is refused;
a filled one passes.

### BUG-20260819-escaped-pipe-rationale-read-as-placeholder → verified
`53586c5`. A rationale carrying `` `TODO\|` `` passes. The symptom is gone.

### BUG-20260819-empty-catalogue-stamped-green → verified
`688553f`. A kit copy with `CATALOG=()` emptied produced `score: 0 caught, 0 known gap(s), of 0`,
and the sensor refused it: *"the catalogue ran 0 of the 128 mutant(s) … (floor 8) — an emptied or
narrowed catalogue goes on printing caught == of, and that green is about a loop that ran 0
time(s)"*. No stamp was written.

⚠️ The emptying was **proven before the run**, not assumed — the first attempt at this retest used a
regex that matched nothing, ran the full catalogue, and would have reported a green about an
untouched world. That attempt was discarded.

## Paper Cuts

Friction found in persona, filed here rather than in the registry **on purpose**: an `open` bug in
this repo holds `gate_QA` shut for every future mission (see the tree README), which is
disproportionate for friction. Each is a candidate scenario for the next cycle.

- **The installer asks Priya to confirm the branch it guessed, and never mentions the suite it
  guessed.** `sdd install` prints *"base branch detected: main — confirm it"* and says nothing about
  the `TEST_CMD` it just chose — the value `gate_EXEC`, `gate_QA` and `gate_REVIEW` all trust. The
  asymmetry is the finding: the same reasoning that earned the branch a "confirm it" applies harder
  to the suite. *(Friction, on a first-impression journey → treat as High priority per the rubric.)*
- **`sdd status` carries phase pass/fail on a glyph alone.** `✓` vs `·`, no word. With no glyph in
  the font both render `?` and only the prose beside them distinguishes "plan approved" from
  "working tree dirty". Ada can read it; a screen reader announces punctuation. Pre-existing, not
  from this diff. *(Trust-Damage at the low end.)*
- **The dirty-tree refusal spends three of its eight lines on an absolute log path** at 80 columns,
  pushing the remedy — the most useful sentence in it — below the fold. *(Friction.)*
- **`BLOCKED in REVIEW — 0 session(s) without satisfying the gate`** reads as a runner bug on first
  encounter. It is literally true (this invocation opened none, because the ceiling refused before
  it could), and the line below explains it, but the headline number is the first thing read.
  *(Cosmetic → Friction, because it lands on an escalation a human is meant to act on.)*

## Human Verifications Needed

- **Row 20 — the `ticket` skill creating the real card and branch.** Everything downstream of it is
  proven: the gate refuses both mismatch worlds, passes the agreeing one, and the runner creates and
  checks out the declared branch and runs EXEC on it. What no session can do is create a real JIRA
  card. In a repo with a `.jira-project` pointing at a **throwaway** project, set
  `JIRA_ENABLED=true`, leave `branch:` in `00-missao.md` at its `<...>` placeholder, and run
  `sdd run <mission>`. Confirm three things: the card lands **in the active sprint**, not the
  backlog; the session writes the branch into BOTH `10-ticket.md` and `00-missao.md` and commits
  them; and `git log` on that branch afterwards carries the mission's commits.
- ~~A real markdown formatter~~ — **done**: `prettier@3.9.6` was fetched and run for real (rows
  12-15), and it changed what that session concluded. See its debrief.

## Decisions for a Human

### The new finding: two sessions, one log file (BUG-20260821-…)

`run_phase` names session logs `<PHASE>-%Y%m%d-%H%M%S`, so two sessions of one phase inside the same
second land on the same path and the earlier transcript is destroyed. The journal recorded both
sessions faithfully, with two ids, and pointed both at the same file. Walked live: two REVIEW
sessions, two ids, one `REVIEW-20260821-023554.json` on disk.

Filed **Data-Loss** — the product creates an artifact, tells the operator to read it, then destroys
it silently. A reviewer may argue Trust-Damage (the lost data is product diagnostics, not something
a user entered); the rubric says take the higher tier when in doubt, and the bug file records both
readings so the downgrade can be deliberate.

**Not auto-fixed, on purpose.** The repair is in a filename that `tests/check-health.sh`,
`tests/check-gates.sh` and the journal's own `log=` field all depend on; a fix that changed the file
without changing the pointer would replace lost data with a wrong pointer. That is outside the fix
governor's bounds.

**Options.** (a) Append the session id (or a counter) to the log filename and update the journal
field in the same commit — correct, and touches two sensors. (b) Refuse to overwrite: if the path
exists, suffix it — smaller, keeps the pointer honest, still needs the journal to record which. (c)
`wont-fix` with the reasoning recorded, on the grounds that colliding sessions are rare — *note that
this branch made them less rare, since escalation and retry are now designed to run a phase twice in
quick succession*. **Recommendation: (b)**, then (a) if the ids turn out to be worth having.

⚠️ **This bug is `open`, and in this repo an open bug holds `gate_QA` shut for every future
mission.** That is the tree's documented coupling working as designed, and it is why the three
Friction findings above went to Paper Cuts instead. It needs a disposition before the next mission's
QA phase, not after.

### The E2E_DIR key that Priya can set and nothing reads (row 11)

Walked from her side, not reasoned about: she keeps specs in `tests/browser/`, sets
`E2E_DIR="tests/browser"` because `config/schema.md` offers the key, and the QA boot prompt mentions
`docs/qa` (a key that IS passed) three times and `tests/browser` **zero** times. She changed a
documented setting and nothing told her it would not take effect.

It is declared debt — frozen in `tests/health-baseline.txt`, carried in `TODO.md` — but *declared in
the maintainer's backlog* is not *disclosed to the adopter*. The five phantom keys this branch
removed were the same class; this is the one that survived.

**Options.** (a) Pass `E2E_DIR` into the QA phase's boot prompt, the way `QA_DOCS_PATH` already is —
makes the key mean what the schema says. (b) Remove it from the schema and the starter config, as
the five phantom keys were removed, and let `sdd-qa`'s own convention own the path. (c) Keep it and
document it as *agent-only, not read by the runner*, in the schema row itself. **Recommendation:
(a)** — the key already exists in every installed config, and (b) would break repos that set it
expecting it to work.

### The retest debt is now two cycles old

**Paid.** Four of the five are now `verified` (rows 24, 25, 26, 30), each re-walked under its
original persona and journey on a live repo. The fifth — the stamp round-trip, row 31 — is
`Skipped` with its reason: this branch's mission was run interactively rather than through
`sdd run`, so there is no mission directory for `gate_PR` to be asked about, and inventing one
would be editing a fixture to reach a code path. The next mission driven by `sdd run` settles it
for free.

### Last cycle's report is still `Status: in-progress`

`reports/2026-08-19-fecho-que-nao-mente.md` was never closed, because no `qa-execution` session
ever ran against it. It costs nothing today (`gate_QA` reads `reports/` only when `E2E_CMD` or
`APP_URL` is set, and neither is), but it means this tree has two open planning passes and zero
walked sessions. Two plans and no walks is the failure mode a living QA tree is supposed to prevent,
and it is worth deciding deliberately: run the sessions, or record that this tree is a design
artifact and stop planning into it.

## Learnings

- **Three of my own probes were wrong before the product was.** A key census with `[A-Z_]+` that
  silently skipped every `E2E_*` key; a `grep … | head` whose `|| echo` branch could never fire
  because the pipeline's status was `head`'s; a single-line `grep` for a sentence that wraps. Each
  would have produced a confident wrong verdict. The kit's own rule — *the probe proves it sabotaged
  what it claimed before it concludes* — earned its place again in the emptied-catalogue retest,
  where the first attempt matched nothing and would have certified a green about an untouched world.
- **The real tool disagreed with the plan, and the plan was the thing that was wrong.**
  `CH-a-formatter-rewrote-the-mission` insisted on a real prettier rather than a hand-typed
  imitation. Prettier's default turned out not to produce alignment colons at all; it produces them
  only by preserving an author's. The bug was real, the trigger was narrower than written, and no
  amount of imagined fixtures would have said so.
- **An abandonment path went stale and nobody would have noticed.** `J-target-repo-ships` recorded
  "nothing in the kit inspects a target repo's `TEST_CMD` at all" as the reason a trimmed suite was
  safe. One increment (`41f6c34`) made it false. Abandonment paths are conclusions with a shelf
  life; they get re-read against the diff every cycle rather than trusted.
- **Three of the diff's fourteen changes are the same promise seen three times** — a phase that
  dies, a ceiling that resets, a budget that does not fit the phase are all *trouble costing money
  more than once*. Mapping them as one journey found the differential each of them needs; mapping
  them as three features would have produced three happy-path checks and no twin.

## Final Status

**Ready to merge, with two items waiting on a person.** The fourteen increments of PR #17 were
walked by five personas across nine charters and thirty-two rows: **25 Pass, 4 Fixed, 1 Skipped,
2 Blocked**, zero Pending. Every behaviour the branch claims to have changed was observed doing what
it claims, on real throwaway repositories, through public read paths — including both halves of
every differential, which is what separates "the escalation fired" from "the runner refuses
everything".

**Exit gate**, run on the current build, recorded verbatim:

```
suite green
```

(`bash tests/run-all.sh`, 2026-08-21, at `bb0556f`. The mutation catalogue was run separately by the
mission itself: `score: 128 caught, 0 known gap(s), of 128`, stamp written.)

**Totals by user-impact tier**

| Tier | New this run | Open at close |
|---|---|---|
| Blocks-Completion | 0 | 0 |
| Data-Loss | 1 | 1 — `BUG-20260821-session-log-overwritten-in-the-same-second` |
| Trust-Damage | 0 | 0 |
| Friction | 3 (paper cuts, unfiled by design) | 3 |
| Cosmetic | 0 | 0 |

**What blocks nothing:** none of the fourteen increments regressed anything, and four bugs left over
from the previous cycle moved from *fixed-but-unwatched* to `verified`.

**What waits on a person, before the next mission rather than after:**

1. **The open Data-Loss bug holds `gate_QA` shut** for every future mission in this repo — the
   tree's documented coupling, working as designed. It needs a disposition (fix, or `wont-fix` with
   reasoning); the recommendation is in Decisions for a Human.
2. **`E2E_DIR`** — a documented key an adopter can set and nothing reads. Three options and a
   recommendation are recorded; row 11 stays `blocked-decision` until one is chosen.

**One coverage gap, disclosed rather than papered over:** the `ticket` skill creating a real JIRA
card (row 20) was not walked, because no session can create one. Everything downstream of it was.

**And the deviation that qualifies all of the above:** the person who walked these sessions is the
person who wrote the code. It was mitigated — public read paths only, scenario `expected` lines as
the oracle, differentials on both sides, three of my own probes caught being wrong before the
product was — but not removed. The highest-value thing the next cycle could do is have somebody else
re-walk `J-trouble-stops-the-line` and `J-target-repo-ships` from these same charters.
