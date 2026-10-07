# ADR 0015 — The stamp is not headless; and three amendments that close sensors claiming more than they measure

- **Status**: accepted (—, 2026-10-05)
- **Spec**: docs/handoffs/20261004-lote-4-a-catraca-zera/00-missao.md
- **Amends**: 0004 (who runs the stamp, and when; `agents/` joins the key), 0014 (the key is five
  directories, not four), 0011 (decisions 1 and 2: the anchor measures the symbol the item
  designates),
  0013 (a QA report on the tip of the base belongs to the mission only if it arrived with the
  mission's directory)
- **Amended by**: 0016 (§3: the checkpoint left by the base commit that added the report must be a
  blob the mission's branch already had)

## Context

Batch 4 of the kit's backlog (mission `20261004-lote-4-a-catraca-zera`) closes the 23 findings left
after batch 3. Four of them are architectural trade-offs that amend earlier ADRs, and one changes
where the language rule reads `docs/`. Each part below states the measured context, the decision,
and the alternatives discarded. Everything was measured on `fe9441d` (2026-10-04).

### 1. The mutation stamp ran inside a headless session, before the bots

ADR 0004 made the stamp the `gate_PR` demand wherever the catalogue lives (`has_mutation_catalogue`,
`bin/sdd`), and `CLAUDE.md` fixed the order: open the PR, wait for every reviewer, fix in one round,
stamp **once**, merge. The PR hat did the opposite. `agents/sdd-publisher.md` told the publisher to
run `./bin/sdd health` (20–50 min) inside its own headless session, right after opening the PR.

- On PR #196 the health started at 18:13, and CodeRabbit posted at 18:27 with a finding in a keyed
  file (`tests/run-all.sh`).
- The PR session polled the health in a `sleep 20` loop until it was killed from outside
  (`error_during_execution`, 2571 s, US$ 0.54). It left no ledger row.
- The ledger holds 19 PR sessions of the kit: US$ 39.13 and 4.6 h in all, three of them over
  15 min. One ended in `budget-exhausted`.

The stamp exists only in the kit: no target repo carries `tests/check-mutation.sh`, and nothing but
the dispatcher calls `cmd_health`.

The key had a related hole. `MUTATION_STAMP_PATHS` was `bin tests templates config` (ADR 0014,
item 4). `sandbox()` in `tests/check-mutation.sh` also copies `agents/`, `CLAUDE.md`, `TODO.md` and
`docs/adr`, and the runner reads the hats' frontmatter (`hat_field`). Three sensors also copy the real
`agents/` into their fixtures (`check-hat.sh`, `check-autonomy.sh`, `check-kaizen.sh`). An edit
confined to `agents/` therefore kept a stamp valid over content the catalogue measures: key
`17ff0579…` before and after editing `agents/sdd-reviewer.md`. Measured cost of keying `agents/`
over the last 30 first-parent merges: **zero** extra `sdd health` runs, because every PR that
touched `agents/` touched a keyed path after it.

**Decision.**

- `gate_PR` is unchanged: it still demands a valid stamp where the catalogue lives.
- When the stamp is the **only** refusal, `sdd run` stops with rc 2 without opening a session, like
  a plan that is not approved. The message names `./bin/sdd health` and the order: bots, one fix
  round, `sdd health`, `sdd run` again.
- The publisher only opens the PR, and the PR body states that order. Who stamps is the operator,
  after the bots, once.
- `agents/` joins the key: `MUTATION_STAMP_PATHS=(bin tests templates config agents)`, still minus
  the ratchet `tests/health-baseline.txt`.
- `docs/adr`, `CLAUDE.md`, `TODO.md` and `docs/pipeline.md` stay out, declared in the comment beside
  the array. `docs/pipeline.md` is copied by the sandbox from this batch on, for the series-key
  sensor. The rules that read these files answer the same for every mutant, so they cannot change a
  mutant's verdict:
  - the ADR 0003 shape in `check-kaizen.sh`;
  - the policy rule in `check-health.sh`;
  - the series-key block, which a mutant can only fail against, never pass.

  Keying them would cost an extra `sdd health` in 15 of the last 30 merges, the ones that touched
  only `CLAUDE.md` or `TODO.md`.

**Discarded.**

- **The runner stamps before opening the PR session.** That stamps before the bots, the exact defect
  of #198. It would also run the in-memory runner over new content (#129).
- **The stamp leaves `gate_PR` and becomes a pre-merge artifact.** That lowers the gate's promise
  instead of raising the code to it (principle 1, ADR 0006). It orphans or rewrites about 16 stamp
  mutants and reverses ADR 0004.
- **Accept the re-stamp.** It keeps an LLM session watching a 40-minute catalogue.
- **Key the eight paths by reading the list from `sandbox()`.** The runner would depend on a test
  file, and the stamp would move in about half of the merges.

### 2. The findings anchor measures the symbol the item designates (amends 0011, decisions 1 and 2)

ADR 0011 made the anchor carry a symbol. `tests/check-todo.sh` (`ANCHOR_REACH`) accepted **any**
span of four or more letters cited in the item, found within 10 lines of the anchor. An identifier
repeated across a file therefore rescued any anchor near it. Two rotten anchors were green on
`fe9441d`:

- `README.md:158` passed through `templates/`, cited by the item, eight lines below.
- `bin/sdd:1198` passed through `gate_EXEC`, in a comment at `:1191`. The item's real symbol,
  `GATE_EXEC_CELL`, is at `:1251`.

The rot spread through the sensor's own repair hint. The "nearest X is at line N" hint names the
nearest span, and `52de46e` moved the second anchor from 1179 to 1198 by following it.

Stricter generic rules were measured as extra failures across kit / `sales_quote` / `lighthouse_project`:

| Rule | Kit | `sales_quote` | `lighthouse_project` | Catches |
|---|---|---|---|---|
| Reach 2 | +8 | +17 | +4 | both, but the hint still points at `:1191` |
| Same line | +11 | +29 | +10 | both; +21% re-anchoring churn |
| Symbols with ≤ 5 occurrences | +5 | +15 | +1 | misses `README.md:158` |

**Decision.**

- The slot `` (`<symbol>`) `` that `templates/todo.md` already defines becomes **the** symbol: the
  code span opened by `(` right after the anchor. It is the one the anchor rule measures and the one
  the hint names.
- The slot is mandatory for an open item.
- The four-character minimum and the 10-line reach stay as they are.
- Target repos adopt it through `--baseline <ref>`. A missing slot on an item the ref already had is
  an inherited violation (measured: `0 new` on the nine targets that carry a findings file), and new
  items must carry it.

This amends decisions 1 and 2 of ADR 0011: the anchor still carries a symbol, but the symbol is the
designated one, not any span the item cites.

Measured on the open items of the kit after the decided exits of this batch: 9 of 16 lacked the
slot. Forcing the slot exposed two more anchors that the old rule let through:

- `bin/sdd:4315` passed through `TEST_CMD`, which occurs 73 times in the file;
- `tests/check-lang.sh:180` pointed at a comment, while the floor is at `:203`.

On a churn model of 28 merges, an anchor that has drifted passes 26.1% of the time under the old
rule, 12.7% with the designated symbol, and 4.3% with reach 2 on top. Reach 2 costs 22 more
re-anchorings (+7%) and changes what the slot means: from "the finding's function" to "a code span
of the line itself". It is not adopted.

**Discarded.**

- **Reach 2 or same line alone.** Each moves the threshold and leaves the hint wrong.
- **An occurrence cap.** Misses one of the two live cases.
- **A declared limit.** It was already written (`tests/check-todo.sh` header, ADR 0011), and the D15
  rule does not let a fail-open leave by declaration.

### 3. A QA report on the base's tip belongs to the mission only if it came with the mission (amends 0013)

ADR 0013 made the report the one the mission's branch **added**: a path absent from the merge-base
tree (`mission_qa_report`, `path_in_commits`). A report that another mission merged into the base
after the cut still counts if it is brought in later by `git checkout origin/<base> -- f`,
`merge --squash` or `cherry-pick`: it too is new to the merge-base. This was reproduced in a
fixture. The direction the finding proposed does not separate the cases:

- **Comparing the blob at the tip.** The blob is identical in both cases.
- **Ordering by date.** It ties within the same second, and the code already refuses clock order
  (`--topo-order`).

No real case was found in the kit, `sales_quote` or `lighthouse_project`.

The premise the rule rests on was measured on `sales_quote` (`develop`). Of the reports added by a
commit that touches a mission directory, 9 of 9 touch their own mission's directory and 0 touch
another's. Since 2026-08-01 that repo merged 85 PRs by squash, 25 by merge commit and 0 by rebase.

**Decision.** A report new to every merge-base still counts, **unless** two things hold together:

- a tip of `mission_base_refs` also has the path;
- the newest commit of that tip that added it touches neither `<HANDOFF_DIR>/<mission>/checkpoint.md`
  nor `<HANDOFF_DIR>/<mission>/checkpoint-notas.md`.

The question is asked by plumbing (`cat-file -e` per base ref, and `rev-list` plus `diff-tree` only
when the path is on a tip), never by clock. The mission's own squash merge does move its checkpoint,
so its report counts; another mission's report does not.

The two progress files, and not the whole directory: the first version of this rule asked for any
path under `<HANDOFF_DIR>/<mission>/`, and the Codex review of PR #222 showed it open. Another
mission's commit can edit this mission's approved intent — this ADR's own mission backfilled `adr:`
into fourteen `00-missao.md` files in one commit — and a report carried by that commit counted. The
progress files move with every increment of the mission itself and nobody else writes them. It
**fails open** in one declared world: a commit of another mission that also edits this mission's
checkpoint. No such writer is known.

It **fails closed** in three declared worlds:

- the mission's own report taken to the base by a cherry-pick without the mission directory;
- a rebase-merge read from the branch after a fetch, where each commit is replayed alone;
- a report whose **name** another mission merged earlier.

In each one QA reads "not one this branch added", and `GATE_WHY` names the file: a visible,
recoverable stop, never a silent pass.

**Discarded.**

- **Declaring the risk.** The fail-open was reproducible, and a declared fail-open stays open under
  the D15 rule.
- **Blob identity at the tip.** Refuted: the blobs are identical in both cases.
- **Date order.** It ties within the same second, and the code already refuses clock order
  (`--topo-order`).
- **Refusing every report found on a tip without asking who added it.** That takes from a squash
  merge its own report, which is the case ADR 0013 was written for.

### 4. The language rule reads `docs/` by census

`CLAUDE.md` § Idioma promises that `docs/` is English surface. `tests/check-lang.sh` `surface()`
**enumerated** files, so a new doc was born outside the rule. `docs/plan-only.md` carried a 10-line
pt-BR block and a mission slug in prose, while the sensor printed `0 of 56`. Its floor (`-lt 56`)
lagged the real surface in 57 of 124 first-parent commits, 9 of 11 steps of them caused by a new ADR.
A second definition of the same surface already lives in `health --release` (`bin/sdd`), by glob, with
`docs/handoffs/`, `docs/qa/` and `docs/superpowers/` declared as `OUTPUT_LANG` content.

**Decision.**

- `surface()` matches `docs/*.md` by glob.
- A census proves that every tracked `docs/**/*.md` is either on the surface or under one of the three
  declared subtrees. These are the same subtrees as `health --release`.
- A tracked doc that is on no surface and under no declared subtree fails, with its own rc (97).
- The floor of `check-lang.sh` is derived, not written by hand:
  - every pattern of the single surface list must match a file;
  - the census must find a tracked doc on the surface.

  Deleting a non-docs pattern from the list is a diff on the definition, and nothing refuses it.
  That is declared.
- The pt-BR block of `docs/plan-only.md` is **translated**, because the kit is public.
  `config/examples/` holds one named repo's config, and moving the block there would send an English
  reader into Portuguese. The line that cited a mission slug in prose is rewritten without it.
- `CLAUDE.md` § Idioma names `docs/qa/` and `docs/superpowers/` as content in `OUTPUT_LANG`.
- The other floors (`LINT_FLOOR`, the `check-pipefail.sh` floor, `CALIBRATE_FLOOR`) never lagged in
  105 commits. They stay numbers, with a declared limit: a floor guards against vacuity, it does not
  track the surface.

**Discarded.**

- **Glob plus a fenced-block exemption.** It would blind 179 of 6 293 markdown lines (2.8%), leave the
  prose slug red, and widen the hole the sensor's header refuses.
- **A permanent allowlist entry.** The allowlist exists to empty.

## Consequences

- `sdd run` on the kit stops at the stamp instead of spending a session. Target repos are untouched,
  since they have no catalogue.
- Every PR that edits a hat now needs a stamp. Measured over the last 30 merges, that added zero
  runs.
- The `TODO.md` format gains a mandatory slot. Targets that run `check-todo.sh --check` **without**
  `--baseline` see each old item without the slot as a violation, until they adopt `--baseline` or
  migrate.
- Not decided here: the sixth ledger event `manual` (`sdd note-manual`) enters without an ADR, by the
  precedent of `gate_pass` and `close`, because it is admitted by both readers and never scores.
