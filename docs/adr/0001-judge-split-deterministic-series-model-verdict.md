# 0001 — The kaizen judge splits: deterministic series in the runner, verdict in the agent

Date: 2026-08-15 · Status: accepted

## Context

The autonomy ledger (`~/.sdd/autonomy-log.jsonl`, I13.1) records facts only — `gate`, `moved`,
`auto_retry`, escalation `kind`, cost — precisely so that a judge can derive `ok|leve|refez`
labels later and change its yardstick without rewriting the past. I13.3 builds that judge
(`sdd kaizen` + `agents/sdd-kaizen.md`), and the fork was where the derivation lives:

- **Pure sensor**: the runner derives labels, aggregates per `kit_sha`, applies the
  three-missions guard and prints the verdict. Testable, mutation-covered, but the yardstick is
  rigid early, when the historical series is still short and nuances ("`increment-blocked` can be
  a *good* sign") would have to be encoded as rules before we know them.
- **Pure model**: the agent reads the JSONL and judges on its own. Nuance for free, but the
  recorded verdict becomes untestable perception — the exact class the kit's principles forbid
  ("gates measure artifacts, never labels").

## Decision

Hybrid. The **runner** owns everything mechanical: per-session label derivation, the compared
series per `kit_sha` group, and the three-missions `indeterminado` guard — all deterministic
`jq`, covered by fixtures and by the mutation catalog. The **agent** (`sdd-kaizen`) reads those
numbers and owns the final verdict artifact: it interprets, may disagree with the raw rates when
context warrants it, and its interpretive yardstick is expected to be adjusted as we use it —
prose edits to `agents/sdd-kaizen.md`, visible in git history.

## Consequences

- The numbers are auditable and regression-guarded; the interpretation is cheap to evolve.
- The boundary must stay surgical: the agent never recomputes or overrides the series — it
  consumes the runner's output and writes a verdict **on top of** it, citing it. If the agent
  starts producing its own numbers, this ADR has been violated and the design has degenerated
  into the pure-model option.
- Changing the mechanical yardstick means changing runner code — dated in history, so a future
  reading of old verdicts can tell which yardstick judged what.
