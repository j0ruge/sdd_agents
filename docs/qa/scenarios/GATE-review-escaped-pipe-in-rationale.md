---
id: GATE-review-escaped-pipe-in-rationale
area: GATE
title: Accept a rationale that legitimately contains a pipe
persona: Sessão
journey: J-review-round-seal
expected: A rationale containing a GFM-escaped pipe passes, and any refusal quotes back text that actually appears in the file
entry_points: ./bin/sdd why <mission> REVIEW
qa_status: fail
bug_ids: BUG-20260819-escaped-pipe-rationale-read-as-placeholder
fix_status: fixed
retest_status: pending
fix_commits: 53586c5; e2e5252
evidence:
last_report: docs/handoffs/20260819-fecho-que-nao-mente/40-review-r1.md
overlaps: GATE-review-punctuated-placeholder-refused
---

The false-red counterpart of the placeholder rule, and the reason that rule needs a scenario on each
side. Refusing every placeholder is easy; refusing every placeholder *and no real sentence* is the
actual property, and only a pair of scenarios can tell the two apart.

Two distinct observables, both required:

1. the round **passes** when a rationale contains an escaped pipe (`awk -F'|'` must not split the
   row on it — the columns are reassembled before reading);
2. when the gate does refuse, the text it quotes back is text the file contains. Passing the `gate:`
   value through `awk -v` ran it through awk's escape processing first, so the refusal cited a
   string nobody wrote — a message that cannot be acted on by a persona with no memory and no one
   to ask.

Overlaps `GATE-review-punctuated-placeholder-refused`, which owns the placeholder behaviour; this
file owns the boundary on the legitimate side.
