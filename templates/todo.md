# TODO

Findings that **do not fit the current mission** — recorded, never lost, never a scope detour.
Format and lifecycle: `templates/todo.md` of the sdd kit (one variant per `OUTPUT_LANG`); the shape
is measured by the kit's `tests/check-todo.sh --check TODO.md --allow-empty`.

> **Skeleton.** Two `##`, in this order, each followed on the next line by its marker:
> `<!-- sdd:open -->` for the findings, `<!-- sdd:decided -->` for what must not be reopened. The
> heading text is free and follows `OUTPUT_LANG`; the marker never changes. No other `##`. Inside
> the open section, `###` categories are free (theme, who unblocks, "Blocking", "Needs a
> decision"). Long analysis and roadmaps live in `docs/`; the item points there with `Source:`.
>
> **Open finding** — about 6 lines (cap 8), the box always empty, the attribution on the last line:
>
> ```md
> - [ ] **<title>** — `<file:line>` — <why it matters>. Direction: <what to do>. Source: `<docs/…>`
>   — found by `<agent>` in mission `<slug>` (YYYY-MM-DD)
> ```
>
> **Decided record** — one physical line, no box, pointing at the evidence:
>
> ```md
> - **<title>** — <what was decided and why> — `<ADR | handoff | test>` (YYYY-MM-DD)
> ```
>
> **Lifecycle.** Fixed by a commit: the body gets `RESOLVED by <hash>` (a kit token, the same in
> every language) and the item stays until `git merge-base --is-ancestor <hash> <DEFAULT_BRANCH>`
> holds; then it is **deleted**, never ticked. Refuted, decided, won't-fix or accepted risk: there
> is nothing to commit, so it leaves the open section and becomes a decided record in the same
> commit. A duplicate is deleted, naming the survivor. Before filing, read the decided records:
> what is there does not come back.

## Open
<!-- sdd:open -->

## Decided — do not reopen
<!-- sdd:decided -->
