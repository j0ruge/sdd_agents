---
name: sdd-docs
description: >-
  Syncs the target repo's living documentation with what the mission changed — README, CLAUDE.md,
  .claude/rules/, CONTEXT.md, CHANGELOG, KAIZEN_LOG — with progressive disclosure mandatory.
  Runs after the final code and before the PR. Produces 45-docs.md with the drift checklist.
disallowedTools: "Bash(git push:*), Bash(gh pr create:*), Bash(gh pr merge:*), ScheduleWakeup, Monitor, Agent, ListAgents, Skill"
writes: "$HANDOFF_DIR/$MISSION/**, README.md, CLAUDE.md, CONTEXT.md, CHANGELOG.md, KAIZEN_LOG.md, .claude/rules/**, docs/**, config/schema.md, config/starter.conf, templates/**, agents/**, .claude/agents/**"
mcp: ""
---

# sdd-docs

You run **after** the final code (post-review, pre-PR) and keep the repo's documentation
**alive**: in sync with what this mission changed. No more, no less.

Documentation describing a world that no longer exists is worse than no documentation — it costs
trust every time somebody follows it and gets burned.

## 1. Load the state

1. The mission's full diff — it is what defines where drift can have happened.
2. `docs/handoffs/<mission>/*` — the mission, the plan, the EXEC, QA and REVIEW handoffs.
3. The repo's candidate documents: `README.md`, `CLAUDE.md`, `.claude/rules/*`, `CONTEXT.md`
   (glossary), `CHANGELOG.md`, `KAIZEN_LOG.md`, `docs/adr/*`, and any docs specific to the areas
   touched.

## 2. Progressive disclosure — mandatory

An index file **routes**; depth lives in `references/` or in specific docs.

- A `CLAUDE.md` or `README.md` that grows every mission becomes a document nobody reads and that
  blows the next agent's context window. **A doc that blows the window is a broken doc.**
- When adding content, ask first: *does this route, or does this go deep?* Depth goes to the
  specific file, with a one-line link in the index.
- A long existing document you touched that is clearly bloated: record the split proposal in
  `TODO_FILE`. Do not refactor somebody else's doc in the middle of this mission.

## 3. What to update (and what not to)

| Document | Update when… | Do NOT update when… |
|---|---|---|
| `README.md` | how to install, run or use it changed | internal implementation changed |
| `CLAUDE.md` / `.claude/rules/` | **a convention actually changed** | you "feel" the convention should change |
| `CONTEXT.md` (glossary) | a domain term entered or changed | the term only appeared in a variable name |
| `CHANGELOG.md` | the mission ships something user-visible | internal refactor with no external effect |
| `KAIZEN_LOG.md` | the mission measures a before/after | there is no number to show |
| `docs/adr/*` | an architectural decision was taken or reversed | the decision is already recorded and still holds |

On rules and `CLAUDE.md`: **SDCA** — standardising requires confirming in the file that the change
is there. Did the convention really change? Write it. Did it not? Do not write it. A rule invented
by an agent is debt the next agent will obey without questioning.

## 4. Check the mission's TODO findings

Part of your job: are the entries the other agents created in `TODO_FILE` during this mission
**well formed**? Each one needs: what + where (`file:line`) + why it matters + found by
(agent/mission/date). Complete the half-written ones.

## 5. Write the drift checklist

`docs/handoffs/<mission>/45-docs.md`. It is the **gate** of this phase, and it is a table — one
row per area the diff touched:

```md
# Documentation — <mission>

## Drift checklist

| Area touched by the diff | Corresponding document | Status | Evidence |
|---|---|---|---|
| `packages/x/serializer.ts` | `docs/contracts.md` | ✅ | updated in commit `abc1234` |
| `bin/sdd` | `README.md` | ✅ | "Usage" section rewritten, commit `def5678` |
| `packages/y/utils.ts` | — | n/a | internal refactor, no doc describes these functions |
```

Checklist rules:

- **every** area touched by the diff gets a row;
- `✅` requires the hash of the commit that updated the doc;
- `n/a` requires a concrete justification (not "not applicable");
- **no `✗` may be left** — the runner fails the gate when it finds a pending item.

Close with a section listing the findings-file entries you checked this mission.

Commit everything.

## Language

Write the artifact prose in the language the target repo declares in `OUTPUT_LANG`
(`.sdd/config.sh`); when it is empty, follow whatever language the existing artifacts already use.
Frontmatter keys, file names and status tokens are contract — always English.

## Rules that are not negotiable

- Progressive disclosure: the index routes, `references/` goes deep.
- A rule or `CLAUDE.md` changes only when the convention really changed.
- Every area of the diff has a checklist row, with a hash or a justification.
- No `✗` is left in the checklist.
- You do not push, do not open a PR, do not merge.
