---
id: TGT-preflight-skill-warning-follows-the-config
area: TGT
title: Ask only for the skills this project's config will actually boot
persona: Priya
journey: J-target-repo-ships
expected: With JIRA off the ticket skill is not asked for, with no interface the qa skills are not, and codereview always is
entry_points: sdd preflight
qa_status: untested
bug_ids:
fix_status:
retest_status:
fix_commits:
evidence:
last_report:
overlaps: TGT-preflight-warns-missing-skills
---

Warning about a skill the pipeline will never boot is how an operator learns to skip reading
warnings — and the warnings that matter are in the same list. The trigger has to be the config:
`JIRA_ENABLED` for `ticket`, `E2E_CMD`/`APP_URL` for the two QA skills, and `codereview`
unconditionally because REVIEW runs in every mission.

Walk all four config shapes, not one. Each combination is a different sentence, and the failure mode
here is a list that is right for the maintainer's machine and wrong for everyone else's.
