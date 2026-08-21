---
id: GATE-exec-alignment-colon-not-an-increment
area: GATE
title: Skip a separator row that carries alignment colons
persona: Priya
journey: J-checkpoint-survives-a-formatter
expected: A checkpoint whose separator reads |:---|:---:| derives the same phase as one with plain dashes
entry_points: sdd phase <mission>; sdd run <mission>
qa_status: pass
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report: ../reports/2026-08-21-missao-porteira.md
overlaps: GATE-docs-alignment-colon-not-a-status; GATE-review-alignment-colon-not-a-criterion
---

Read as data, the separator becomes an increment whose id is `:---` and whose status is `:---:` —
outside the enum — so `gate_EXEC` refuses a checkpoint in which every increment is done.

Nothing in the kit writes these colons, which is why no fixture carried them for fourteen missions.
An adopter's formatter writes them the first time it runs, so the trigger is somebody else's tooling
and the finder is the first adopter, not the maintainer.

**Walked 2026-08-21 with prettier 3.9.6** (CH-a-formatter-rewrote-the-mission, Paste Tour), and the
walk corrected an assumption this file was written on: **prettier's default output is not alignment
colons.** Left alone it rewrites the separator as `| --- | ------ |`, padded — which the plain
`/^-+$/` skip already handled after trimming. Colons appear when the *author* aligned the table and
prettier **preserves** that alignment, reformatting `|:---:|` into `| :----: |`.

So the trigger is narrower than "an adopter runs a formatter" and just as reachable: an adopter who
aligns tables by hand, or a markdownlint config that enforces alignment, plus any formatter run
afterwards. Both spellings were walked — authored colons, and prettier's reformatting of them — and
the mission advanced REVIEW → DOCS → PR through artifacts the formatter had rewritten.
