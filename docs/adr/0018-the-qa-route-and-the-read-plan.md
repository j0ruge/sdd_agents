# ADR 0018 — The QA route is the runner's, and under `/sdd-plan` the human reads the plan before approving

- **Status**: proposed (—, 2026-10-12)
- **Spec**: docs/handoffs/20261012-a-rota-da-qa/00-missao.md

## Context

The judge's window over batches 5 and 6 (`05-verdict.md` beside the spec, `melhorou` over
`0270727`) measured five `sales_quote` missions, and two gaps sat at the same point of the runner,
`qa_substep` (`bin/sdd`). The grill of this mission then opened a third question, about the
`/sdd-plan` approval.

- **A `skipped` the grill decided had no headless route.** With `E2E_CMD` or `APP_URL` set,
  `qa_substep` answers `plan` with no charter and `exec` with no closed report of the mission, and
  only then `close`, the one sub-step whose hat (`sdd-qa`) writes `status: skipped`.
  `agents/sdd-qa.md` § 2 promises that `skipped` is a legitimate answer for a diff that does not
  reach the user. On the interface path no session reached that promise without first paying for a
  browser walk. Three of the five missions decided `skipped` in the grill and went through the same
  ritual by hand: `sdd run` up to TICKET, `30-handoff-qa.md` written by the operator,
  `sdd note-manual … QA`, and a second `sdd run`. That second launch was the intervention of each
  of them, so 3 of the window's 5 interventions came from this gap (`sdd autonomy --all-repos
  --by-mission`). The route had existed by accident. Before `121a696` (ADR 0013, 2026-09-28) the
  sub-step accepted another mission's closed report, and two `sales_quote` missions of 2026-09-24
  reached `sdd-qa`, which wrote `skipped` in 45 s and 86 s for US$ 1.54 and US$ 1.64. ADR 0013
  closed the hole correctly and took that accidental route with it.
- **After an `F<n>` nothing walked the journey again.** With the mission's report `closed`, the
  sub-step went straight to `close`, and no session that owns a bug's `Status:` ran again, so
  Anchor 3 of `gate_QA` kept counting the fixed bug. What the target used instead was the `sdd-qa`
  session invoking the `qa-execution` skill through the `Skill` tool, which no contract describes:
  r2, r3 and r4 of `20261005-mascaras-ncm-e-painel` (the r3 retest found F5) and again in
  `20261009-o-que-some-calado` (US$ 7.19, 1144 s). It only works because both installed skills
  declare `disable-model-invocation: false`, while the runner's comments said the opposite. If the
  skill flips back, every mission with an `F` spins `QA:close` up to `QA_MAX_ITER`.
- **The handoff lied after a fix.** No rule tied `30-handoff-qa.md` to the fixes made after it.
  Once a retest moves `Status:`, `gate_QA` passes and `close` never runs again, so DOCS and the PR
  body read a handoff that still lists the fix as pending. The path without an interface already
  behaves that way today.
- **The approval.** `agents/sdd-planner.md` § 6 says "All ✅ → `aprovacao: auto`. A well-run grill
  **is** the approval." In all five missions of the `sales_quote` campaign (L0–L4), the human wanted
  to read the plan before approving. The relay achieved that by telling the planner to leave the
  field empty. Relaying the sentence "Never write `aprovacao:` by hand", which forbids approval
  *prose*, suppressed the `auto` (L2). The acceptance step of `commands/sdd-plan.md` showed only
  paths and one line per increment, and its question named "the criterion that is ✗", which no
  criterion was. In the two grills of 2026-10-12 (L4's, and this mission's up to D8) the human picked
  the recommended option 16 times out of 16; that was the sample when §3 was decided (this mission
  went on to 22 of 22 by D21). That count is consistent both with good recommendations and with
  anchoring, and no artifact records which decision was the recommended one. In L4 the acceptance step itself, where
  the relay re-ran `check-checkpoint.sh --red` before showing the plan, caught a stale
  red-measurement section that the plan carried.

## Decision

### §1 — The plan declares `qa: skipped`; `sdd-qa` confirms it against the diff

`00-missao.md` gains an optional frontmatter key, `qa:`. The planner writes `qa: skipped`, with the
justification among the grill decisions, only when the grill decides that the mission's diff does
not reach the user. On the interface path, `qa_substep` answers `close` when the key holds exactly
`skipped`. The check sits after the no-interface branch (whose answer is already `close`) and
before the charter check (a project may have no charter at all). Any other spelling (empty, the
template's placeholder, `Skipped`, `skipped # …`) is today's route: a looser match would skip real
QA, which fails open.

The `sdd-qa` session confirms the declaration against the real diff before writing anything. If
nothing in the diff reaches the user, it writes `status: skipped`, citing the plan and the files. If
something does, it writes `status: blocked`, naming the files and the whole remedy. `handoff-blocked`
then stops the line (rc 3), and the human removes the key **and deletes that handoff** (`git rm`), then
runs again. Removing the key alone does not recover: `gate_QA` re-reads a `blocked` handoff left in
place and arms the marker, and the escalation is read only after a session, so each run would pay
for `QA:plan`, then `QA:exec`, and stop again before the `close` that can rewrite it (Codex on PR
#247). With the handoff gone the gate says `missing 30-handoff-qa.md`, which does not escalate, and
one run goes `plan` → `exec` → `close`. No gate changes for this: `gate_QA` already
accepts `skipped` with an interface. Its passing reason now says what it read (`30-handoff-qa.md
declares status: skipped`) instead of asserting a property of the diff that the runner never
measured.

### §2 — The retest is the runner's route, and the QA handoff is written after the last fix

One definition, `qa_fix_ahead_of <path>`, answers with the first `F<n>` row marked `done` after
which `<path>` was not rewritten. Rewritten means two things at once: the bytes of `<path>` at
`HEAD` are new, no version the path had up to the fix; **and** the first commit after the fix (topological
order, ancestry path) that carries those bytes is not a merge. That is the provenance of the content
`HEAD` holds, which the two halves of round 10 (a non-merge commit touched the path; the blob changed)
only approximated. Codex on PR #247 measured each gap: a rewrite reverted right after (round 10), and a
merge that changes the file followed by an edit and its revert, whose surviving change is the merge's
(round 12). Over 12 worlds the round-10 rule failed open in two (that one, and a pre-fix version
restored after the fix), and this one answered all 12. Two readers use it:

- **`qa_substep`**, after the closed-report check, answers `exec` when an `F<n>` is ahead of the
  **mission's** report: the file `mission_qa_report` picks, the same one Anchor 1 reads. Never the
  whole `reports/` directory: a plain commit after the fix that edits or copies another mission's
  report would touch it and answer `close` with no retest (CodeRabbit on PR #247). Without an
  interface the sub-step answers `close` before it reads any report, on purpose: there `sdd-qa` is
  the walker, its `close` is the retest, and the freshness rule below is what brings it back. `qa-execution` enters through its slash, as in every walk, retests,
  and moves the bug's `Status:`. The task text of `QA:exec` covers the retest.
- **`gate_QA`**, on both paths and after the status enum, refuses while an `F<n>` is ahead of
  `30-handoff-qa.md` and names that row. The owner of the artifact is `sdd-qa`, which the default
  `close` reaches: on the interface path, once the retest's report commit lands after the fix; on
  the other path, at once.

An `F` cycle is now `close` → EXEC → `exec` → `close` (two QA sessions per round, within the
"three sub-steps per round" of `phase_budget`). The `sdd-qa` session never invokes a skill. The two
runner comments that claimed `disable-model-invocation` say what the kit knows instead: the slash
is the runner's route, whatever the skill's flag.

### §3 — Under `/sdd-plan` the human always reads and approves, and the choice is measured

Under `/sdd-plan`, the planner leaves `aprovacao:` empty even with every PLAN-AUTO criterion ✅,
and writes `auto` only when the human asks for it in the grill. The acceptance step:

1. re-runs `check-checkpoint.sh --check` and `--red`;
2. renders the plan on screen in the structure of a `superpowers:writing-plans` plan: Goal,
   Architecture and Tech Stack, the global constraints, and each increment with its **Files:**,
   its `- [ ]` steps and its Check as command and expected result;
3. asks YES/NO, naming the ✗ criteria or saying that all are ✅.

The closing warning forbids approval prose in the field, never `auto`. Every grill decision in
`00-missao.md` is marked `(recommended)` or `(other: …)`, and the acceptance step shows the count:
that is the datum the worker roadmap needs before anyone decides how much of the grill a planner
may take alone. `gate_PLAN` does not change. Both values stay valid, and a plan born of
`sdd kaizen` still never carries `auto`.

## Discarded

- **§1: `gate_QA` passes on the plan's declaration with no session.** Zero cost, but nobody checks
  the diff after EXEC. The only look at it would come from the hat that wrote the code, and DOCS and
  PR would lose the handoff they read.
- **§1: `sdd-qa` triages first in every mission with an interface, with no key.** It needs no grill
  decision, but it charges one more session to every mission with real QA and needs a new state
  ("this needs a walk") that no artifact carries.
- **§1: keep the ritual and document it.** Zero code, and one human intervention per mission
  without QA: exactly what the window measured.
- **§2: the `exec` route without the freshness rule.** One session cheaper per round, and the PR
  body reads a handoff that lies about the fix.
- **§2: authorise the `Skill` call in `sdd-qa` § 4, with a preflight probe of the flag.** It saves
  one session and has been measured working five times. It also depends on a third-party flag, and
  it puts two system prompts in one session, which the `phase_slash` comment refuses.
- **§3: keep `auto` as the default with all ✅.** It is the smallest change, and the human who
  wants to read before approving goes on asking the relay every time. That instruction is what
  produced the L2 failure.
- **§3: a `PLAN_APPROVAL=human|auto` config key enforced by `gate_PLAN`.** It would turn the rule
  into a gate rule, at the cost of a new key (schema, starter, `health_default_keys`) and a mutant,
  for a preference that has one user today.
- **§3: shrink the grill so the planner takes the technical decisions alone, vetoable at
  acceptance.** It goes straight at the PLAN-time bottleneck the worker notebook measures (138–372
  min per mission), but it would change the grill's contract on a single data point. This ADR
  measures first.

## Consequences

- A mission with `qa: skipped` runs from TICKET to PR in one launch, with one `sdd-qa` session of
  about US$ 1.6. Its proof is the next judge's window: no `manual` QA row in the ledger.
- A mission with an `F` pays one more `sdd-qa` session per round (US$ 1.2–6 measured), stops
  depending on a skill's invocation flag, and hands DOCS and PR a handoff written after the fix.
  Missions in flight with a fix done and an older handoff run one `close` more after the upgrade.
- Mutants hold each rule: the `skipped` branch, the retest branch, the descendant order, the
  merge exclusion, the mission's report over the directory, the freshness anchor. The assertions live in `tests/check-dry-run.sh` and `tests/check-gates.sh`.
- Declared limits: the retest reads the mission's own report, so another mission's report, merged
  in or edited on the branch, never counts as this mission's retest; `--no-merges` keeps a merge
  that touched the file out too. A retest written to a new file whose name sorts before the current
  one leaves the sub-step on `exec`, and `no_work_check` stops the second identical lap: fail closed
  and loud. A report or handoff rewritten but not committed does not count, and that fails closed (one more
  lap, then `no_work_check`). An `F` row whose commit does not resolve is skipped, which
  `gate_EXEC` makes unreachable in a derived run. The `(recommended)` mark is the planner's own
  account of the grill: a label, read as a count and never as a gate.
