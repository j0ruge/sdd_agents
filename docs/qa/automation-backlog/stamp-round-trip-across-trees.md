# Stamp round trip when the runner's home is not the workspace
- Source: BUG-20260819-stamp-written-where-gate-cannot-read; GATE-pr-stamp-read-from-gate-tree; J-certify-mission-close
- Why automate: regression-prone — the defect exists *because* every one of the eight differential worlds in `tests/check-gates.sh` invokes `$FIX/bin/sdd` from inside `$FIX`, making `SDD_HOME == REPO_ROOT` by construction. The fixture shape, not the assertion, is what hides it, and a new world written the same way would hide it again.
- Suggested layer: API/integration (shell fixture in `tests/check-gates.sh`), plus one mutant in `tests/check-mutation.sh`
- Spec sketch: build a fixture where the runner lives at `$KIT` and the mission tree at `$WORK`, invoke `$KIT/bin/sdd` with cwd `$WORK`; assert the stamp `cmd_health` writes is the file `gate_PR` reads; assert the reverse world (`SDD_HOME == REPO_ROOT`) still passes, so the pair is differential rather than a one-sided refusal.
- Status: proposed
