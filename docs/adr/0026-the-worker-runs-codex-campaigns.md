# ADR 0026 — The worker runs Codex campaigns

- **Status**: accepted (2026-11-24)
- **Spec**: docs/handoffs/20261124-worker-codex/00-missao.md
- **Amends**: 0022, decisions 6 to 8, for campaigns declaring the Codex harness.

## Context

The worker was designed around Claude Code. A Codex subscription can report token usage without
reporting billed USD. Granting network access to the phase that prepares a pull request would let
its shell use the same GitHub identity for publishing and merging.

## Decision

Select Codex explicitly per campaign. Use Astra for the planner, Sol at medium effort for EXEC,
and Sol at extra-high effort for QA and REVIEW. Keep planning resumable by native thread ID.
The phase runner retains the existing gates and passes control back to the signed worker
publication act when it reaches PR.

Prefer measured costs when provided. An API reference estimate remains separate from billed
USD. A signed unknown-cost exception permits delegated Codex work when billed USD is unavailable.
The worker still checks known spend and existing limits.

## Consequences

Claude campaigns keep their existing route. The Codex preflight verifies that the native sandbox
can run commands. The acceptance pilot must pass that preflight and run without remote
publication. Merge remains a separate act.
