# 0007 — "Apt for another repo of the organisation" is six green lines, and a real mission in a second repo is one of them

Date: 2026-09-03 · Status: accepted

## Context

The kit has one target. Every shape assumption it carries — the `TODO.md` genre, the QA docs
tree, the ticket skill's `.jira-project`, the e2e directory — was learned on its first target and
never contradicted, because nothing else ever ran it. "Ready to be used by other projects" was a
sentence with no artifact behind it, which is the one thing principle 1 of `CLAUDE.md` refuses.

Measured on 2026-09-03 (spec `docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md`,
§ 6): no LICENSE; 7 surface files name the first target and 15 name its ticket prefix; every
third-party skill the pipeline boots lives in the author's `~/.claude`; every headless phase saw
9 MCP servers and 104 tools it never used; 48 of 729 commits mention the client.

## Decision

"Apt" is the command `sdd health --release` printing six green lines, each read from an artifact:

| # | Line | Artifact | Owner | Closed by |
|---|---|---|---|---|
| 1 | installed and run in a second repo | ≥ 2 distinct non-kit `repo` values with `session` rows in the global ledger | the human who picks the second repo | mission 3 |
| 2 | every third-party skill has an installable origin | `skill_origin()` answers a URL for each of the seven | the kit | mission 3 |
| 3 | the last target mission saw only what its hats declare | `mcp_seen == 0` and `tools_leaked == 0` on every session row of that mission | the runner | mission 1 (the hat's boundary) |
| 4 | an end-to-end mission in the second repo | a `PR` phase row in ≥ 2 non-kit repos | the human + the pipeline | mission 3 |
| 5 | a LICENSE, and no client identifier on the surface | `LICENSE` exists; `RELEASE_FORBIDDEN_WORDS` finds nothing under `bin agents docs/adr docs/pipeline.md docs/failure-modes.md README.md config templates tests` | the kit | mission 3 |
| 6 | suite, ratchet and mutation catalogue green for this content | the mutation stamp matches the tree | `sdd health` | already |

The command never runs the suite: line 6 reads the stamp, which is the suite's own artifact. It
is opt-in (`--release`), exits 1 while any line is red, and was born with four red lines on
purpose — a "ready" that cannot fail is a label.

**"Apt" is not "public".** Publishing the repository in the open is a separate decision with its
own number (48 of 729 commits mention the client, so it means rewriting history), and this ADR
does not take it.

## Alternatives discarded

- **A dry-run in a fixture repo as the proof of line 4.** It proves installation and projection,
  not a headless session in a repo of another shape — and every shape assumption above is
  exactly what a projection cannot exercise.
- **A public toy repo as the second target.** A demo for strangers, not evidence about the
  organisation's own repos, whose shapes are the ones the kit will meet next.
- **A checklist in the README.** Verifiable by nobody; the ratchet on the backlog exists because
  a list that only a human re-reads is the most silent drift there is.

## Consequences

- Each mission of the roadmap (1 boundary, 2 context diet, 3 aptitude) names the line it closes.
- Line 5 puts client names in the kit's **own** `.sdd/config.sh`, never on the surface — the list
  of what must not appear is itself something that must not appear.
- The second repo (lines 1 and 4) is the human's choice; the pipeline proves it by the ledger,
  which already stamps `repo` and `kit_sha` per session (ADR 0005).
