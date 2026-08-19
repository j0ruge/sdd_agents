---
id: HLT-verdict-readable-without-colour
area: HLT
title: Read the verdict with no colour and no glyphs
persona: Ada
journey: J-health-verdict
expected: Every check's pass/fail is carried by the words ok and FAIL, not by a symbol or a colour
entry_points: ./bin/sdd health (NO_COLOR set, 80 columns, screen reader)
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

The kit prints the same assertion text on stdout for ok and stderr for FAIL, which is what makes the
checkpoint Checks anchorable on `^  ok    `. Ada's walk confirms the human half of that contract:
that the two streams' words differ, that lines survive 80 columns, and that a missing glyph for the
box-drawing and warning characters never removes the verdict itself.
