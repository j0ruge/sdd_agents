---
name: sdd-worker
description: Orchestrate a signed SDD campaign, resume its planner, or report its next action and budget.
---

Resolve the installed `sdd` or `sdd-worker` with `command -v` and `readlink -f`. The parent of
its `bin/` directory is the SDD kit. Read the kit's `commands/sdd-worker.md` in full and follow it.
Read the target repository's instructions before running a campaign.

Use the campaign directory the user supplied, or identify it from the repository. The campaign
declares the harness. A Codex campaign uses the Codex planner relay in the mission worktree and
launches the selected backend with `PHASE_ENGINE=codex`. Follow the signed terms, including
permission to proceed when the actual USD charge is unavailable. Answer the human's questions
and stop at the command's escalation points.

Use the `run` act's shared launch block for either harness and for a permitted restart. It runs
preflight in the mission worktree before starting a runner.
Follow its post-launch lookahead block before waiting on that PID. Pass the recoverable
owner request only when verified for this campaign. Resume the reserved relay from the
same worktree and use the command's post-merge revalidation before approving its draft.

## Codex preflight for the kit itself

Require `PHASE_ENGINE=codex sdd preflight` to exit successfully and report
`TEST_CMD ran green` in the mission worktree. A green host suite can miss sandbox
restrictions on loopback, writable paths, and inherited Git identity.

When a suite fix touches a mutation fixture, run the affected `tests/check-mutation.sh --only`
case through `bin/sdd-codex --sandbox-check`. Require a green unsabotaged control and a
caught mutant. For the ledger guard, the control repository must stay outside `/tmp`
even when the catalogue runs the sensor from a copy under `/tmp`.
