# 0008 — An ADR id is allocated by a command, and the link between spec and ADR is read by a sensor

Date: 2026-09-17 · Status: accepted

Spec: docs/handoffs/20260917-o-numero-do-adr-nao-e-prosa/00-missao.md

## Context

Nothing in this kit, and nothing in the target repo it was built against, allocated an ADR id.
`grep -c traceab bin/sdd` answered 0; the single mention of `docs/adr` in the runner was the
`RELEASE_FORBIDDEN_WORDS` sweep of `health_release`. The seven ADRs here and the forty there were
numbered by hand, by reading the directory and adding one.

That is a convention, and a convention is only as good as the last person who followed it.
Measured on 2026-09-17, not supposed:

- A note written on 2026-08-25 declared "ADR 0030" for one decision. On 2026-08-26 the real
  `docs/adr/0030-…` of the target was accepted for **another** one. The collision stayed latent
  only because the note never reached the repo, and it materialises the day somebody implements
  against it.
- The link, where it exists at all, runs ONE way. In the target, ADR → spec exists; spec → ADR is
  zero. In this kit, 2 of 13 specs cite an ADR, one by path and one by a bare number.
- This kit has already paid for the class once: `CONTEXT.md` records dangling references to
  "ADR 0004" repaired by hand during `20260820-missao-porteira`.
- The only sensor was a human reviewer, by accident: a review round of a target mission noticed,
  in prose, that an ADR described a hole that had already been closed.

One direction proves nothing. An `adr:` pointing at a real file is satisfied by **every** real
file — which is exactly what the note of 2026-08-25 did, correctly, at a number that belonged to
somebody else.

## Decision

Two verbs and one pair.

**`sdd adr new` allocates.** It reads the largest id on disk, adds one, and creates the file under
`set -C` — O_EXCL, one syscall. Two writers racing for the same number get one file and one error
instead of two files and a silent overwrite. A gap is never reused: a freed number may already be
cited by a merged branch, a handoff or somebody's notes, and handing it out again would point that
citation at a different decision — the same defect, inverted. `--spec` writes **both** sides of the
link in one command, and refuses a spec that already declares one, because choosing between two
ADRs is a human decision.

**`sdd adr check` reads it back**, in two scopes and one grammar. The grammar is a key, not a
section: `^(- )?(\*\*)?(ADR|Spec)(\*\*)?:` serves the two dialects already on disk without
rewriting either, and the id is read from the FILE NAME (`NNNN-slug.md`) because the two dialects
disagree about the title and agree about the name. The mission scope asks one mission; the repo
scope asks the whole tree.

**`ADR_CHECK=off|warn|block` governs what the gates ask**, and the refusal lands in **PLAN**. Under
`block`, `gate_PLAN` refuses a mission whose `adr:` is empty, `TBD` or still the template
placeholder; `gate_EXEC` re-reads it, so an ADR deleted after approval stops the line. PLAN is the
one phase with a human in the room, and no agent in this kit may decide an architectural
trade-off. Refusing `TBD` in EXEC and nowhere else would be the unsatisfiable gate principle 1
forbids — the class that cost US$ 73,32 in a single mission.

**Absence fails in the running mission and is counted everywhere else.** The mission the kit is
executing right now is the one place where "nobody decided" is itself the defect. Every other
mission on disk predates the mechanism, so a repo scope that failed on absence would be red on the
day a repo installed the kit, and a check that is red from the first run is a check people turn
off. Adoption is `off` → `warn` → fix → `block`, and it is the target's decision.

**A bare `ADR NNNN` with no file is read differently in the two trees**, and the asymmetry was
measured rather than argued. Inside a SpecKit tree a number is a CLAIM by construction — that tree
carries `**ADR**:` lines. In a handoff it is NARRATIVE: the plan of the mission that built this
cites a number that names a test probe and another that belongs to a different repo, and neither
has a file here, nor should. So it fails in the spec tree and is counted in a handoff. The
alternative was to reword an approved artifact until the detector went quiet, which is weakening
the content to please the instrument.

## Alternatives discarded

- **A reusable CI workflow shipped by the kit.** Impossible between different owners with a
  private repository, and this kit has no `.github/` by decision (ADR 0004). What ships instead is
  a recipe in `docs/pipeline.md`: a thin job in the target that installs the kit and runs
  `sdd adr check`.
- **A ninth phase and a ninth gate.** The check runs INSIDE `gate_PLAN` and `gate_EXEC`. A phase of
  its own would have bought a session, a boot prompt and a hat for a question answered by reading
  four files.
- **A `## Traceability` section as the contract.** A section is prose with a heading; the rule is
  one line, and a line is what a sensor can read in both dialects without a migration.
- **`--json` output.** No consumer today. Recorded in `TODO.md`, not built.
- **Racing two processes to prove the reservation.** A scheduling accident: green on a fast
  machine, red under load, and red meaning nothing either way. What O_EXCL promises is testable
  without a second process — an existing path is refused and its bytes are untouched — and that is
  what the sensor asserts.
- **Failing on a local ADR namespace beside a spec** (`specs/NNN-slug/adr/001-…` exists in the
  target). Out of scope and declared as a limit in the sensor header and in `config/schema.md`:
  unifying it or declaring it is that repo's decision, not the kit's.
