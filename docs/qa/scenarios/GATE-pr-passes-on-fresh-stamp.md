---
id: GATE-pr-passes-on-fresh-stamp
area: GATE
title: Open the PR when the stamp matches the content being shipped
persona: Mara
journey: J-certify-mission-close
expected: gate_PR passes, and the md5 of bin/ tests/ templates/ config/ recomputed by hand equals the stamp file
entry_points: ./bin/sdd run <mission>
qa_status: untested
bug_ids: 
fix_status: 
retest_status:
fix_commits:
evidence:
last_report: 
overlaps: 
---

The happy path to the true end state. The check is deliberately re-derivation and not 'the gate said
yes': `sdd health` writing a stamp and `gate_PR` reading it share an author and an assumption, so a
verdict that only compares them to each other confirms the assumption instead of measuring it.
