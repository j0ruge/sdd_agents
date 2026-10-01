# ADR 0014 — The kit's identity is what it executes: the judge groups by the last behaviour commit, and the stamp keys on tracked content minus the ratchet

- **Status**: accepted (—, 2026-10-01)
- **Spec**: docs/handoffs/20261001-a-janela-nao-se-parte/00-missao.md

## Context

Two questions in the kit answer "which kit is this?", and both answered too widely.

**The judge's axis.** `autonomy_kit_stamp` (`bin/sdd`, at `c19e987`) stamps every ledger row with
`git -C "$SDD_HOME" rev-parse --short HEAD`, and `kit_dirty` with any line of
`git status --porcelain` over the whole tree. Part 1 of ADR 0003 kept it that way on purpose ("the
axis stays `kit_sha`; `autonomy_kit_stamp` is not touched"), and D4 of `CONTEXT.md` gave the nuance
to the agent: "two shas = one logical change" was the judge's call, read off `git log`.

That valve failed in practice, and the failure is measured:

- `6323c6f` (PR #184) changed `TODO.md` (+18) and one line of `tests/health-baseline.txt` (the
  backlog ratchet, 87 → 89). It changed no line of `bin/`, `agents/`, `templates/` or `config/`.
  It minted a new `kit_sha` anyway, and window 2 — 3 missions and US$ 110.18 on `5b98087` — went to
  `previous` with `window_missions_stranded: 3`.
- The verdict (`docs/handoffs/20260930-a-sub-etapa-que-andou/05-verdict.md`) refused to add the two
  slices up by hand, because that would be recomputing the series, which ADR 0001 forbids. It was
  right to refuse. A valve that asks the judge to break its own contract is not a valve.
- It was not a one-off. Mapping every target-repo `kit_sha` in the real ledger (593 rows, 202
  distinct shas, all resolvable, 0.4 s) to `git log -1 --first-parent <sha> -- bin agents
  templates config`: **10 of 17** target versions were a chore or docs commit, and two pairs of
  slices were the same behaviour (`5b98087`/`6323c6f`, `5aa21af`/`2d28d13`).

The cause is a collision of three rules, not anybody's slip: principle 5 says a finding becomes a
`TODO.md` item, the ratchet says the baseline moves in the same commit, and the axis says every
commit is a new kit.

**The mutation stamp.** `mutation_stamp_key` hashes `find bin tests templates config -type f`, and
the ratchet file lives in `tests/`. So every finding that is registered also throws the stamp away
and costs another `sdd health` (~18 min) before `gate_PR` (#117). Two more defects come from the
same `find`: it reads files git ignores (#119), and its emptiness guard only catches the absence of
all four directories, not a partial listing (#107). The ratchet's content decides no mutant's fate:
inside the suite only `check-lang.sh` reads it, independently of any mutant, and `health_ratchet`
runs in `cmd_health`, outside the suite.

## Decision

1. **Every ledger row carries `kit_rev` and `kit_rev_dirty` next to `kit_sha` and `kit_dirty`.**
   `kit_rev` is the short sha of the last first-parent commit that changed
   `KIT_BEHAVIOR_PATHS=(bin agents templates config)`. It is spelled with `rev-parse --short`, the
   same spelling as `kit_sha`. `kit_rev_dirty` is `git status --porcelain` restricted to the same
   paths. `kit_sha` and `kit_dirty` stay what they were: the fact of where `HEAD` stood.
   This replaces part 1 of ADR 0003. Parts 2 and 3 (the floor of 3, and `indeterminado` being the
   correct answer in the kit repo) stand untouched.
2. **Both readers group by the behaviour version, through ONE definition.** A printed jq
   definition, spliced into `kaizen_series` and `cmd_autonomy` at the same point (right after
   `historic_steps`), rewrites a row that carries `kit_rev` so that `kit_sha` is the version,
   `kit_dirty` is `kit_rev_dirty`, and the raw sha survives as `kit_sha_raw`. Rows without
   `kit_rev` (every row written before this ADR) pass through unchanged. The series keeps the
   output key `kit_sha`, so `gate_KAIZEN` and `kit_sha_judged` do not change contract, and each
   slice lists the raw shas it covers.
3. **The kit guard keeps reading the raw pair.** `kit_guard_check` answers a different question —
   "did anybody touch the kit during this session?" — and the incident that founded it (`2d28d13`)
   was a commit to `TODO.md`. Narrowing the guard to the behaviour paths would have made it blind to
   its own founding case.
4. **The stamp keys on TRACKED content of the four directories, minus the ratchet.** The listing is
   `git ls-files` over `bin tests templates config`, excluding `tests/health-baseline.txt`, hashed
   from the working tree. Each of the four paths must exist, and a root that is not a git checkout
   gets no key, so it is never stamped. A file that is new and not yet tracked is outside the key;
   once tracked — staged with `git add` is enough, since `git ls-files -c` reads the index — it
   enters the key, and the gate refuses until `sdd health` runs again. That is the safe direction.

**Who owns these artifacts** (CLAUDE.md, principle 1). The runner writes `kit_rev` on every row it
already writes, and `cmd_health` writes the stamp. No agent and no human writes either one, so no
gate gains an artifact nobody in the pipeline can produce.

## Alternatives discarded

**A map in the reader only, with the ledger untouched.** A bash pre-pass would map each raw sha to
its behaviour version through git and hand the map to both programs. It is retroactive, and that is
its whole advantage. It was discarded on measurement: retroactivity would heal two historical pairs
and neither of them reaches `latest` or `previous`, because today those two are rows of the kit's
own last mission. It would also make the reader depend on the git history of whichever clone reads
it, and the mutation catalogue's sandbox is a plain copy with no `.git`. A sensor whose answer
depends on whether the kit is a checkout is a sensor with two answers. And it cannot repair
`kit_dirty`, which only the writer can scope.

**Redefining `kit_sha` itself in the writer.** It is simpler on the reader side. It was discarded
because the ledger exists to record fact. It would mix two meanings in one field across the file,
and the kit guard reads the same stamp.

**A process rule: a finding waits in the handoff until the verdict.** Window 3 had exactly that
rule ("no commit to `main`, not even `TODO.md`"), and the human abandoned the window on 2026-10-01.
A rule somebody has to remember is the lowest rung of standardisation. Where a mechanism fits, it
goes first.

**Moving the ratchet file out of `tests/`.** It would close #117 without an exclusion. It touches
`HAT_WRITES_BASE`, `check-dry-run.sh`, `check-lang.sh`, `check-autonomy.sh`, the hats' `writes:`,
`CLAUDE.md` and `docs/failure-modes.md` for the same effect as one pathspec.

**Keying the stamp on non-ignored files (`ls-files --others --exclude-standard`).** It closes the
ignored-junk case but not the editor swap file, which is untracked and not ignored here. Tracked-only
closes both.

## Consequences

- A PR made of `TODO.md` plus the ratchet no longer moves the judge's axis and no longer costs a
  stamp. The only window break left is a real change of the kit, which is a legitimate break. No
  merge warning was added: that remainder is decided in `TODO.md`, not open.
- The series shows behaviour versions. The judge's prompt (`agents/sdd-kaizen.md` §2) stops saying
  "the axis is the raw `kit_sha`".
- Not retroactive: rows before this ADR group by raw sha as before, and the `indeterminado` of
  window 2 stands. Window 3 was abandoned without a verdict by human decision on 2026-10-01. Window 4
  opens on the first target stamp after this mission merges.
- Including one path too many can only split a window, never merge two behaviours. A change to
  `config/schema.md`, which is prose, moves the version. That is accepted as the conservative
  direction.
- `#67` stands: the stamp still covers 4 of the 8 paths the sandbox copies (ADR 0004).
