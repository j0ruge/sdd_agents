# ADR 0027 — Lookahead planning and evidence for delegated merges

- **Status**: accepted (—, 2026-11-26)
- **Spec**: docs/handoffs/20261126-l5b-o-worker-e-os-verbos-dele/00-missao.md
- **Related**: ADR 0022

## Context

`sdd-worker next` reports when the successor can be planned. The run procedure can
reach its wait for the predecessor's PID without starting the planner. Some campaigns
ask to plan ahead. Others need to wait for the merge. The next plan needs to survive a
session change and keep a single identity when two sessions resume concurrently.

`pr-ready` checks the review and its threads. Issue #419 also requires evidence of the
suite on the current PR head, a decision on active change requests, and a record of how
findings posted only in a review body were handled.

## Decision

The orchestrator starts the planner for the successor named by `ahead plan` after it
observes that the predecessor's runner owns its checkout. This applies when the owner
has made an identifiable written request for that campaign. Otherwise the signal stays
a suggestion.

The orchestrator rechecks the budget and the successor's planning permission and uses a
separate worktree. It reserves the campaign, lot, and mission identity before starting
the relay, then recovers the same session on resume. The signature is checked on every
Codex turn. Planning produces a draft. Approval and EXEC require the predecessor to
merge, the updated base to be integrated, the plan to be checked, and the applicable
permissions.

The `review` act publishes the suite result as `local/ci` on the SHA it tested. A new head
needs its own result. The same act records how it handled findings posted in the review
body and resolves threads only with evidence. An active change request blocks the merge
even when it contains no inline comments.

## Alternatives considered

- Start the planner by default for every campaign with planning permission. Campaigns that
  need to wait for merge would have to declare an exception to keep their current behavior.
- Add a signed lookahead field to the delegation. Per-lot planning permission already
  exists, and campaigns with a recorded request would have to sign again.
- Depend on a CI service check. The `review` act already runs the suite and can publish
  the result directly on the head it checked.

## Consequences

Planning runs in its own worktree and can overlap with the predecessor's EXEC. It does
not advance the successor's approval or run. A retry resumes the reserved identity and
avoids two relays for the same lot. Campaigns without a request keep the signal as a
suggestion. Publishing status requires GitHub permission and a publication for each
tested head. Missing evidence leaves the PR pending with the reason recorded.
