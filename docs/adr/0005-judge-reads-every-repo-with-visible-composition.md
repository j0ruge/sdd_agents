# 0005 — The judge reads every repo, and publishes the composition it read

Date: 2026-08-26 · Status: accepted

## Context

[ADR 0003](0003-judge-axis-evidence-from-target-repos.md) decided that verdict evidence comes from
real target repos, because in the repo that *builds* the kit every session lands on a fresh
`kit_sha` and the axis degenerates by construction. It left one thing unstated, and that omission
made it a dead letter for nine days: **it never said how the judge READS those rows.**

`kaizen_series` filters per repo by default. `sdd kaizen` runs in the kit repo (`cmd_kaizen` dies
anywhere else), so the default filter keeps the judge looking at exactly the one repo ADR 0003
declared unusable. The rows ADR 0003 asked for are excluded as `other_repo`.

`--all-repos` was the only way to read them, and the usage text deliberately refused to point the
judge at it:

> ⚠️ Whether a REAL target repo's rows may carry a verdict is a different question, and an open
> one … nothing here yet distinguishes a target from a fixture, so the default stays shut and the
> judge is not pointed at it. That decision belongs to a future ADR.

This is that record.

**Measured on 2026-08-26**, mission `20260825-frete-cif-fob` in `sales_quote`, the first real
target-repo mission run against a deliberately frozen kit (`5a82f12`, the merge of PR #23):

```
per repo (the default, from the kit):  latest 671d432 · other_repo: 35 excluded
--all-repos:                           latest 5a82f12 · sessions: 20 · other_repo: 0
```

23 sessions, US$ 144.88, 21 comparable rows — every one `kit_dirty: false` — and the judge's
default reading sees **none of them**. The runner said so itself, in the last line of the run:

```
autonomy series: 1 mission(s) of this repo on kit 5a82f12 are in the ledger.
Today's kaizen judge reads only the kit's own missions, so it will not count them.
```

Three missions were planned on that frozen sha to fill the floor for the first time in the ledger's
life. Under the default reading, all three would have produced `indeterminado`: roughly US$ 400 of
evidence the judge is not pointed at.

**The premise that kept the default shut is out of date.** `SDD_STATE_DIR` (`bin/sdd:1263`)
relocates the whole ledger, and the automated suite already uses it — which is why the suite has
never contaminated anything. Measured over the real ledger — 134 rows, of which 128 are
`event: session` — every row resolves to one of seven repos:

| repo | missions | what it is |
|---|---|---|
| `/home/joruge/repos/sdd_agents` | 11 | the kit — degenerate axis, ADR 0003 |
| `/tmp/qa-portas/clone` | 3 | fixture |
| `/home/joruge/repos/sales_quote` | 2 | a real target repo |
| `/tmp/sddrev.q49jXD/r7b` | 1 | fixture |
| `/tmp/manual-XB2BJO` | 1 | fixture (escalation rows only) |
| `/tmp/manual-sWv4nl` | 1 | fixture (escalation rows only) |
| `/tmp/manual-kIca1U` | 1 | fixture (escalation rows only) |

**Five of the seven are fixtures, and every one of them sits under `/tmp`.** All five came from
**manual** exploratory runs that forgot `SDD_STATE_DIR`, never from the suite. The isolation
mechanism exists and works; what leaked, leaked through discipline — which is precisely the kind of
gap this repo closes with an instrument rather than a reminder.

⚠️ Three of the five contribute **no** `event: session` row at all, only escalations. They are
invisible to any count taken over sessions — the first draft of this record counted sessions, said
"four repos", and was wrong. The composition of part 2 must therefore be derived over the same rows
the guard admits, or it will under-report exactly the repos it exists to expose.

## Decision

**The judge reads the whole ledger, and publishes the composition of the slice it read.** Three
parts.

1. **`sdd kaizen` reads every repo.** The per-repo default remains for `sdd autonomy`, whose
   question genuinely is "what did THIS repo cost". The judge's question is the other one, and ADR
   0003 already answered where its evidence lives.

2. **The series publishes the composition of the axis slice** — how many missions each repo
   contributed to `latest` and to `previous`. This is the half that makes part 1 safe, and it is
   not decoration: a verdict resting on rows from a throwaway clone is a verdict about nothing, and
   under a silent filter nobody could tell. Contamination becomes a thing you SEE rather than a
   thing the runner guesses at. It is the same rule this repo applies everywhere else — a number
   without the composition beside it is a label, and the first principle refuses labels.

3. **The runner refuses the real ledger for a target repo under `TMPDIR`.** Writing a row from a
   throwaway checkout now requires `SDD_STATE_DIR` to be set explicitly. This closes the leak by
   instrument instead of by memory, which is what principle 2 demands.
   ⚠️ **Declared limit, in the guard's own header:** this is a PATH heuristic and it is fragile.
   It knows `TMPDIR` and `/tmp`; macOS hands out `/var/folders/…`, and a fixture built anywhere
   else walks straight past. It is a ratchet against the leak that actually happened, never a
   boundary. The composition of part 2 is what covers what the heuristic misses — which is the
   reason the two ship together and neither is sufficient alone.

**What is NOT decided here**, so nobody re-litigates it as though it were: the guard floor stays at
3 missions with a session (ADR 0003, part 2), and the axis stays `kit_sha` (ADR 0003, part 1).
Reading more repos makes the floor *satisfiable*; it does not lower it.

## Consequences

- ADR 0003 stops being a dead letter. Its evidence has a path to the judge for the first time since
  it was written.
- `sdd kaizen` and `sdd kaizen --series` change what they answer on an unchanged ledger. That is
  the point, and it is why this is a record and not a patch: anyone comparing a verdict from before
  this date with one from after is comparing two different questions.
- `--all-repos` becomes a no-op on `sdd kaizen` and keeps its meaning on `sdd autonomy`. It is kept
  rather than removed: scripts and handoffs already carry it, and a flag that silently changed
  meaning would be worse than one that stopped mattering in one of its two homes.
- A fixture run under `/tmp` that genuinely wants to write the real ledger now fails loudly instead
  of contaminating quietly. Whoever hits that is one env var away from what they meant.
- The four legacy fixture missions stay in the ledger. It is append-only and never migrated —
  history, not a bug, exactly as the `ledger_repo_root` comment already says of the pre-worktree
  rows. Part 2 is what makes them visible where they land.
- The composition field is a new contract on the series JSON. Anything that parses it — the boot
  prompt of the KAIZEN phase, `kaizen_axis_note`, `tests/check-kaizen.sh` — learns it in the same
  commit, under the rule this repo already carries: an enum read in more than one place gets ONE
  definition per program.

## Alternatives discarded

**An allowlist of repos that may carry a verdict.** Rejected because a hand-maintained list drifts
and this repo has already paid for that: the `TODO.md` carries entries about floors and lists that
fell behind while still reporting themselves complete, and `tests/health-baseline.txt` exists
because a list describing a world that no longer exists is worse than no list at all. An allowlist
would need its own ratchet to stay honest, and the composition of part 2 delivers the same safety
without a second thing to maintain.

**A `fixture: true` marker stamped into the row.** Rejected as strictly weaker than what already
exists: `SDD_STATE_DIR` keeps the fixture out of the file entirely, while a marker admits it and
asks every reader to remember to filter. It also cannot help the rows already written.

**Leaving the default shut and asking the human to type `--all-repos`.** Rejected because it is
what was already in place, and it is what produced the measurement at the top of this record: the
Fase 3 command of a written, approved plan would have answered `indeterminado` forever, and nobody
would have known why without reading the source.
