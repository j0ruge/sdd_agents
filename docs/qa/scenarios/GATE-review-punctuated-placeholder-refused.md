---
id: GATE-review-punctuated-placeholder-refused
area: GATE
title: Refuse a fill-in that differs from a placeholder by one keystroke
persona: Sessão
journey: J-review-round-seal
expected: TODO with a colon, TBD with a full stop, a bare hyphen, WIP and FILL ME are refused like their bare forms
entry_points: ./bin/sdd why <mission> REVIEW
qa_status: fail
bug_ids: BUG-20260819-punctuated-rationale-buys-an-a
fix_status: fixed
retest_status: pending
fix_commits: 272cb91
evidence:
last_report: docs/handoffs/20260819-fecho-que-nao-mente/checkpoint.md
overlaps: GATE-review-placeholder-rationale-refused
---

Walked and failed by the mission's QA phase on 2026-08-19. `placeholder()` compares the whole cell by
string equality against a closed set — empty, angle-bracketed, ellipsis, PREENCHER, TODO, TBD, FIXME,
XXX — so everything one keystroke away passes. `TODO:` is the spelling a model writes more often than
the bare word, and a bare hyphen sits one key from the em dash that is legitimate on purpose.

Overlaps its canonical owner above: same behaviour, refined boundary. Any fix must keep
GATE-review-legit-short-rationale-passes green.

**Update 2026-08-19 (F3, `272cb91`):** fixed — the cell is no longer matched by equality; a
punctuation-only cell is refused and a fill-in word is normalised before lookup. Eleven differential
worlds; three new mutants that leave the I3 assertion green. `FIXME` and `XXX` remain refused with
no world proving it, filed separately. Retest pending on the REVIEW round now being written.
