# 0003 — The judge axis: verdict evidence comes from target repos, never from the kit itself

Date: 2026-08-17 · Status: accepted

## Context

`sdd kaizen` judges the previous kit change by grouping the autonomy ledger on `kit_sha` — the
**axis** — and comparing the latest slice against the previous one. ADR 0001 put that derivation
in the runner precisely so it would be auditable; the guard floor (`missions_with_session >= 3`)
exists so a verdict is never pronounced on one mission of evidence.

Measured on the real ledger on 2026-08-16, in the kit repo, the judgement was dead on arrival:

```
latest    kit_sha 818b800 · 1 session · phase PR   · US$ 1.48
previous  kit_sha 4126b50 · 1 session · phase DOCS · US$ 7.31
guard     missions_after_change 1 · sessions 1 · sufficient false
```

`latest` and `previous` are **the same mission**, two consecutive phases. Comparing them measures
no kit change at all: it measures that publishing is cheaper than documenting. The whole ledger
held **24 distinct shas, every one of them with exactly 1 session, none with 2** — so the floor was
not merely unmet, it was unsatisfiable by construction.

The cause is structural, not a bug in the stamping. `autonomy_kit_stamp` records `kit_sha` = the
kit `HEAD` at the instant of each row, and in **this** repo the EXEC phase commits to `bin/sdd`
between sessions. Every session of every kit mission therefore lands on a fresh sha. The axis is
sound wherever the kit is a dependency and stands still for the length of a mission; it degenerates
wherever the kit is the thing under construction.

## Decision

**Evidence for a kaizen verdict comes from real target repos.** Three parts, and the third is what
this record exists to prevent from being re-litigated:

1. The axis stays `kit_sha`. `autonomy_kit_stamp` is not touched.
2. The guard floor stays at 3 missions with a session. It is not loosened, not made conditional on
   the repo, and not replaced by a smaller number when the sample is thin.
3. In the kit repo, `indeterminado` is the **correct** answer, not a malfunction — and the runner
   must say *why*, naming this record, instead of printing a bare `sufficient: false` that reads
   identically to "not enough missions yet".

**Discarded: stamping `kit_sha` once per mission instead of once per row.** It is the obvious fix
and it does not work. Each kit mission commits to `bin/sdd` and so produces its own sha; the series
would go from 1 session per sha to 1 mission per sha, and a floor of 3 would still be unsatisfiable.
The problem was never *when* the stamp is taken.

**Discarded: making the axis a published `SDD_VERSION`.** It would work, but it presupposes a
release policy the kit does not have (versioning, CHANGELOG, when a version is cut). That remains
in `TODO.md` as its own decision, not as a dependency of the judge.

## Consequences

- The kit is not a source of verdicts about itself. Running `sdd kaizen` here is still useful — it
  triages `TODO.md` and gives birth to the next plan — but the `melhorou | piorou | indeterminado`
  half of it will read `indeterminado` until the evidence arrives from elsewhere.
- The runner owes the human an explanation, not just a number: a degenerate axis (each of the last
  three shas holding exactly one session, across more than one sha, and no sha in the history ever
  having reached the floor) is a distinguishable state and is reported as such, citing this record.
  The last clause is what keeps the explanation off a healthy repo that is merely quiet: reaching
  the floor once proves the axis works there, and that proof does not expire.
- I13.4 (autonomy graduation) depends on missions run in target repos, where several missions share
  one kit sha and the floor of 3 behaves as designed. It is unblocked by evidence, never by a
  smaller yardstick.
- Anyone tempted to lower the floor because "the series never fills up" is looking at this axis in
  this repo. That is the symptom this record explains; the floor is not the defect.
