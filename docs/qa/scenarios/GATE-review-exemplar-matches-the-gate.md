---
id: GATE-review-exemplar-matches-the-gate
area: GATE
title: Show a review table the gate would accept
persona: Sessão
journey: J-review-round-seal
expected: The table in agents/sdd-reviewer.md carries at least one real Rationale sentence, and says the <…> cells are the shape
entry_points: .claude/agents/sdd-reviewer.md; sdd run <mission> --dry-run --phase REVIEW
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: GATE-review-placeholder-rationale-refused
---

An agent file is not documentation — it is the system prompt of the session that writes the
artifact. All eight Rationale cells of its exemplar were `<…>`, introduced as "in the format", with
the warning three paragraphs below. The session produced what it was shown and the gate refused it:
the kit teaching a sentence and then refusing it.

Walk it as Sessão, from the file the harness actually loads — `.claude/agents/`, never the kit
source. The two are synced only by `sdd install --force`, and a stale copy is precisely how an agent
goes on running text that was fixed weeks ago.
