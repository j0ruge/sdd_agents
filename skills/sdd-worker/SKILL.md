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
