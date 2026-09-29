# ADR 0013 — A QA report belongs to the mission that added it, and a path the harness refuses is proposed, not written

- **Status**: accepted (—, 2026-09-28)
- **Spec**: docs/handoffs/20260928-os-achados-da-janela/00-missao.md

## Context

The judge's window over `4fd0f31` (LH-4 in `lighthouse_project`, SQ-145 and SQ-146 in `sales_quote`)
left eight `kit:` findings. Two of the five this mission fixes change a contract between phases.
Both were decided with the human in the room on 2026-09-28. This record keeps them, along with the
alternatives that were refused.

### A QA report with no owner

`qa_substep` (`bin/sdd`, at `038a314`) and Anchor 1 of `gate_QA` both choose the report with
`latest_matching "$REPO_ROOT/$QA_DOCS_PATH/reports/*.md"`. That is the newest dated file in the tree,
whichever mission wrote it. The anchor promises "this mission's QA closed". What it measures is
"some QA on disk is closed". It has been an open `TODO.md` item since 2026-08-27, and it recurred in
two of the three missions of the window:

- SQ-146 (`20260928-ver-vira-olho-na-lista`): the newest report was
  `2026-09-25-sq143-alcada-diretoria.md`. The sub-step answered `close`, and the `qa-report` and
  `qa-execution` skills never ran.
- LH-4 (the `lighthouse_project` mission of 2026-09-27): the handoff's own `gate:` field says the newest report
  was `2026-09-22-i14-release-0-1-0.md` and the skills did not run in the mission.

Three facts constrained the fix. They were measured on 2026-09-28:

- `derive_phase` is a plain walk over the gates, so any criterion also holds **after** the merge.
  Answered from the default branch, a criterion that refuses a merged mission sends `sdd status`
  back to QA. A `sdd run` on that mission would then buy a QA session.
- The QA fixture of `tests/check-gates.sh` stands on the fixture's own default branch.
- The skills treat reports and charters differently. A report is per-run
  (`reports/<YYYY-MM-DD>-<scope>.md`, "one per run; dated; never overwritten"). A charter is durable
  ("missions persist; re-run across cycles", `~/.claude/skills/qa-report/references/qa-docs-layout.md`).
  `qa-execution` scopes a branch run to the journeys its diff touches, and drafts any charter that is
  missing.

### A path the harness refuses, and a hat that was told it may write there

`agents/sdd-docs.md` lists `.claude/rules/**` in `writes:`. Headless `claude -p` refuses `Edit` and
`Write` under `.claude/` because the path is sensitive: files there enter the context of every
future session. The two authorities disagreed, with two outcomes:

- In SQ-145 and SQ-146 the DOCS session wrote `.claude/rules/techspec.md` with `python3` through
  Bash (streams `DOCS-20260927-190735-f56b8aca` and `DOCS-20260928-091239-822e7bf8`).
  `hat_guard_check` accepted it, because the path is inside `writes:`. No sensor saw the bypass.
- In LH-4 the session did not bypass. It left a `⛔` row with the proposed text. `gate_DOCS` refuses
  every Status that is not `✅` or `n/a`, and it has no `blocked` exit like QA and TICKET do. The
  honest answer was a gate with no owner inside the pipeline, so the phase would have spun until
  `no-progress`. The human applied the text by hand (`eacbc45` in the target).

## Decision

1. **A report belongs to the mission if the mission added it.** The report must have been added
   (`--diff-filter=A`, never merely modified) in `git merge-base "$DEFAULT_BRANCH" HEAD..HEAD`, or be
   new in the working tree (untracked, or staged as added). ONE function answers it, and
   `qa_substep` and Anchor 1 both call it.
2. **An empty range keeps today's answer.** That covers standing on the default branch, and a
   mission that is already merged. The criterion only applies where it can be decided. Seen from
   the default branch or from its own branch, a merged mission never goes back to QA.
3. **The charter keeps today's meaning**: "the tree exists". It is durable by the skill's own
   contract. Requiring a charter added by the mission would make `QA:plan` unsatisfiable in any cycle
   that reuses charters.
4. **`.claude/rules/**` leaves the `writes:` of `sdd-docs`.** Any write there, by `Edit` or through
   Bash, now stops the line as `hat-crossed`. The guard reads the kit's own `agents/` file, so the
   sensor is in force the moment this merges. `.claude/agents/**` stays, because `sdd install --force`
   is the sanctioned route for the mirrors.
5. **A `⛔` row passes `gate_DOCS` loudly, and only with its proposed text.** The row is accepted
   when `45-docs.md` carries the proposed-text section under the `<!-- sdd:proposed -->` marker (a
   line of its own, outside a code fence; quoted in a table cell it is not the section) and
   that section names the document of **every** `⛔` row. The marker alone, or an empty section, does
   not pass: the promise is measured row by row. The passing reason names every `⛔` row, as the
   `deferred` genre does in `gate_QA` (ADR 0009). The gate proves that each `⛔` has a proposal for
   its document, not that the text is right; the human judges the text in the PR. A `⛔` on a
   document the hat writes itself is refused, `.claude/` excepted, because the harness refuses it
   even inside `writes:` (added after the codereview of 2026-09-28).
   `sdd-publisher` carries the text into the PR's decisions for a human, and the human applies it at
   the merge gate, which is already theirs. `gate_PR` reads the PR body back and refuses one that
   does not name every `⛔` document (added after the codereview of 2026-09-28: until then only the
   publisher's prompt carried it, and a body without it merged green).

## Implementation

This is the shape the mission shipped: I2 (`121a696`) for decisions 1 to 3, I4 (`1ffee16`) for 4
and 5. It was checked against the code when the ADR was accepted.

- The function sits next to `latest_matching` and returns an absolute path, or empty. It reads
  `git -c core.quotePath=false log --diff-filter=A --name-only --format= <base>..HEAD -- <reports>`
  and `git status --porcelain -uall -- <reports>`. `-uall` is load-bearing, because without it an
  untracked directory is listed as the directory and not as its files. Among the mission's files it
  picks the newest by the same `sort -V` as `latest_matching`. It computes the base with `|| true`
  guards, because a missing `DEFAULT_BRANCH` must read as an empty range and never as a dead process.
  A candidate counts only when it is `-ef` the file `<reports>/<name>`: a direct child of `reports/`,
  as the glob of `latest_matching` reads, whatever spelling `QA_DOCS_PATH` has, and still on disk.
- When the tree has reports but none of them belong to the mission, `gate_QA` refuses with a reason
  that names the newest one and says it predates the mission branch, and `qa_substep` answers `exec`.
- The `<!-- sdd:proposed -->` marker is structural and in English, like `<!-- sdd:open -->` in
  `TODO.md`. The heading above it follows `OUTPUT_LANG`. The proposed text is the lines after EVERY
  marker up to the next `## ` heading outside a code fence (proposed text for a rules file is
  markdown and carries headings), or the end of the file. The document of a `⛔` row is the table's
  second column with its markup stripped, looked up there with `grep -F`, and it has to be a name
  (an alphanumeric in it: `—` matched any em-dash). A `⛔` followed by VS16 (U+FE0F) is the same
  value.
- `app_probe` reads the status: only a 2xx page without `APP_EXPECT` is `wrong`. A redirect or an
  error page without it is `unknown` (the right product may answer either), and with it is `up`.
- The rows of the table are admitted positively: only a `⛔` row is exempt, and every other value is
  pending, tagged or not. A `✗` beside a proposed `⛔` keeps today's reason, counted without the `⛔`.

## Alternatives discarded

- **Merge-base without the fallback.** It is stricter, but every merged mission, seen from the
  default branch, would derive QA again. A `sdd run` over one would open a paid session. That is the
  kind of run the 2026-09-03 incident opened by hand.
- **The date prefix of the file name ≥ the mission's `data:`.** It needs no git and is stable after
  the merge. It fails open when two missions overlap or fall on the same day, which is the pace of
  `sales_quote`. It also rests on a third-party naming convention.
- **Added by a descendant of the commit that added `00-missao.md`.** It is stable after the merge.
  It fails open in a common flow: the plan is committed on the default branch while the previous
  mission is still in review, and that mission's report lands after the plan.
- **Stop the line on `⛔`** (reuse `GATE_HANDOFF_BLOCKED` in `gate_DOCS`). The DOCS of `sales_quote`
  touched `.claude/rules/` in two of two missions, so every mission there would stop at DOCS for a
  human.
- **Grant the harness permission on `.claude/rules/**` for the DOCS phase.** It is not verified that
  `claude -p` lets an allow rule override the sensitive-path protection. It also hands a headless
  agent the power to rewrite the rules that steer every later session, which is what the
  protection exists to prevent.
- **A sentence in the hat, with no change to `writes:` or the gate.** A sentence is a reminder, not a
  rule. The bypass would stay invisible, and the honest `⛔` would still have no exit.

## Consequences

- The fail-open recorded on 2026-08-27 closes for every mission that runs on its own branch.
  **Declared residue:** a mission whose `branch:` is the default branch itself always has an empty
  range, so it keeps today's answer. So does a repository whose `DEFAULT_BRANCH` does not exist
  locally. The range is HEAD's, not the mission's, which leaves two more: a merged mission asked
  about from ANOTHER mission's branch reads QA again (its report is on the base, outside that
  branch's range), and a branch stacked on an unmerged mission counts that mission's reports as its
  own. Scoping the range by the mission's `branch:` ref would close the first; neither was measured.
- A cycle that runs `qa-execution` on a branch whose reports are all from earlier missions now
  walks. That is the intended cost: a QA phase that skipped the skills was a phase that did not run.
- `.claude/rules/` drift reaches the human as text in the PR, not as a commit. If the human merges
  without applying it, the rule stays stale, but it is named in the PR body. A project may put
  `.claude/rules/**` back through `HAT_WRITES_EXTRA`. That reopens the bypass, and it is that
  project's decision.
- The prompt half of the change (the rule in `sdd-docs.md` and `sdd-publisher.md`) reaches a target
  only after `sdd install --force` there. The guard half does not wait, because `hat_field` reads
  `$SDD_HOME/agents/`.
