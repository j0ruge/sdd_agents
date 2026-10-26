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
> **Open finding** — about 6 lines (cap 8), the box always empty, the attribution on the last line,
> or on the one above the `RECURRED`:
>
> ```md
> - [ ] **<title>** — `<file:line>` (`<symbol>`) — <why it matters>. Direction: <what to do>.
>   Source: `<docs/…>` — found by `<agent>` in mission `<slug>` (YYYY-MM-DD)
> ```
>
> **The anchor is measured.** The first path after the title names a file of this repository, and
> the `<symbol>` in parentheses right after it is **mandatory**: a code span of 4+ characters that
> occurs in that file within 10 lines of the line — anywhere in it for `:1` or no line. It is the
> only span measured, and the one an off-target report names. No physical line of the open section
> passes 120 characters, except a well-formed `RECURRED` (below).
> ([ADR 0011 of the sdd kit](https://github.com/j0ruge/sdd_agents/blob/main/docs/adr/0011-ancora-do-todo-carrega-simbolo.md))
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
> commit. A duplicate is deleted, naming the survivor; one that came from another project or
> mission is first folded into the survivor's `RECURRED` line, as a new entry (below). Before
> filing, read the decided records and the open findings: a decided one does not come back, and an
> open one gains an entry on its `RECURRED` line.
>
> **Where `RESOLVED by` goes.** At the end of the body's last line, or inside the `Source:` line
> before `— found by`; never on a line of its own, which on an item at the cap becomes its 9th line
> (`9 content lines, cap is 8`), nor after the found-by, which has to be the last field, nor on the
> `RECURRED` line. With no room in the 120 characters, shorten the body.
>
> **Recurrence.** A finding that comes back (another project, mission or session) gains an entry,
> never a new item. The entries sit on one line, `RECURRED <n>: <where> (YYYY-MM-DD); …` (a kit
> token, the same in every language), indented two spaces like the rest of the item. On the first
> return it is appended as the item's new last line, under the found-by, which keeps its text and
> so moves to the line above it; on the next ones the return is one more entry on that line, and
> `<n>` goes up by one. The first sighting stays in the found-by, and `<n>` counts the returns.
> Oldest first, one entry per project and mission: a return from a project and mission already
> listed, or from those of the found-by itself, adds nothing. `<where>` holds ASCII letters, digits
> and `._/-`, opens with a letter or digit, has no blank, backtick or `#`, and names the return as
> `<project>/<mission>` (`dotp-remake/3.4b`), `<project>/pr<N>` (`magic_tutor/pr25`) or, with
> neither mission nor PR, `<project>/<YYYYMMDD>` of the session's day, with `-2`, `-3`… for the next
> sessions of that day (`magic_tutor/20261020-2`); a bare `<project>` only for that project's first
> return with neither. Well formed, the line counts toward neither the cap nor the width. A finding
> that is among the decided records gains no line: tell the human, who decides whether to reopen it.

## Open
<!-- sdd:open -->

## Decided — do not reopen
<!-- sdd:decided -->
