# ADR 0019 — Every session the runner opens may read the kit's templates, and only read them

- **Status**: accepted (—, 2026-10-20)
- **Spec**: docs/handoffs/20261020-a-sessao-le-o-que-o-boot-manda/00-missao.md

## Context

The judge's window over batch 7 (`05-verdict.md` beside the spec, `melhorou` over `bad6168`)
entered two target repositories the kit had not run in before, and both met the same gap: a phase
cannot open what its boot prompt tells it to open.

- **The boot names a path the runner does not let the session read.** Item 6 of `boot_prompt`
  tells every phase to start each artifact from its template in `$SDD_HOME/templates/`, "NEVER
  from memory" (the list comes from `phase_templates`). `run_phase` launches `claude -p` with
  `--permission-mode acceptEdits --allowedTools "$ALLOWED_TOOLS"`, and the default is `Bash`.
  Under those flags a `Read` outside the target's directory is denied.
- **Three ways out, and none is right.** Read in the `permission_denials` of the session logs:
  the lighthouse TICKET read the same files with `cat`, the bypass the hat boundary punishes when
  the path is a write (ADR 0013); the lighthouse REVIEW r1 ran the `codereview` skill with 30 of
  its own references denied, and the jrc-libs REVIEW with 14; the jrc-libs TICKET (2026-10-16
  20:17) refused to bypass and wrote `status: blocked`. That was the window's `handoff-blocked`,
  one `refez` and one intervention. The operator unblocked it by adding `additionalDirectories` to
  `~/.claude/settings.json`.
- **Counted, never shown.** 13 of 47 lighthouse logs and 4 of 23 jrc-libs logs carry a denied
  `Read` outside the repository. `sales_quote` has 0 of 33 only because its
  `.claude/settings.local.json` carries `Read(*)`, set by hand. It is not the harness bump: the
  lighthouse had the same denials on 2.1.278 and 2.1.283. `hat_init_facts` publishes
  `LAST_PHASE_DENIALS` and the ledger's session row carries `denials`, but no journal line, no
  `status` and no `preflight` says what was denied, and `sdd preflight` answered ok in all three
  cases.
- **The skills' references live outside both the repository and the kit.** `sdd-ticket` depends
  on `ticket`, `sdd-reviewer` on `codereview` (a plugin cache path whose version directory went
  from 2.15.3 to 2.17.0 in two days), the QA sessions on `qa-*`. Where they are installed is the
  machine's business, and `.sdd/config.sh` is tracked in the kit and in all three targets.

Measured on Claude Code 2.1.304, 2026-10-20 16:24–16:25: thirteen haiku sessions (US$ 0.026) in
scratch repositories, with the environment cleared as `HARNESS_ENV_UNSET` clears it and
`--strict-mcp-config`. The table is in the plan, under the verified context.

- With `--allowedTools Bash` alone the template `Read` is `DENIED`. With `Read(/<dir>/**)` as a
  second argument (`<dir>` absolute, so the literal spelling has two slashes) it is read, and a `Write` into the same directory is `DENIED`. With
  `--add-dir <dir>` the `Write` **succeeds** under `acceptEdits`.
- With `--setting-sources user,project,local`, in a repository whose `settings.local.json` allows
  `Read(*)`, the template is read with **no rule at all**. With `--setting-sources ""` the empty
  string is accepted, no settings load, and the outcome depends on the flags alone: `DENIED`
  without the rule, read with it.
- A symlinked directory needs two rules. `~/.claude/skills/ticket` is a symlink. A rule on the
  link's path alone is `DENIED`, in the `//` spelling and in the `~/` one; a rule on the resolved
  target alone is `DENIED`; both together read. A rule on a real directory (`qa-report`) reads
  with one. A rule on the plugin's parent directory, without the version, reads a file under
  `2.17.0/`.

## Decision

### §1 — A read-only rule, built once, at every door that opens a session

`kit_read_rules` prints the rules every session the runner opens receives, one per line:
`Read(/$SDD_HOME/templates/**)`, which with an absolute `$SDD_HOME` is
`Read(//home/…/templates/**)`, then the project's (§2). The three doors that assemble a
`claude -p` call it: `run_phase`, the preflight probe and `cmd_close`. Each appends every line as
one more argument of `--allowedTools`, after `"$ALLOWED_TOOLS"`, and no door copies the rule. The
shape is the measured one: the rule as an argument of its own, two slashes in its literal
spelling. Three slashes were never measured.

### §2 — The project declares the skill directories in `READ_EXTRA`

`READ_EXTRA` is a config key, empty by default, validated in `load_config` and never at the point
of use, because a `die` there would land in a subshell (the `HAT_WRITES_EXTRA` lesson). Its
entries are absolute directories after expansion: written `$HOME/…` in the tracked
`.sdd/config.sh`, so the file names no user, or exported in the environment like every key. A
glob character, `..`, a newline or a relative path dies with the reason named. `kit_read_rules`
emits `Read(/<dir>/**)` per entry and, when `readlink -f <dir>` differs, the rule for the
resolved target as well. A directory that does not exist is a `warn` of `sdd preflight`, never a
`die`: a plugin missing on another machine must not stop the line. The kit grants nothing beyond
its own templates, and each target declares its skills.

### §3 — The preflight proves the kit's rule in a session of its own, with no settings

The existing probe (the executor hat and `Bash`, under `user,project,local`) stays as it is: its
parity with the phase is what it proves. A second haiku session runs with `--setting-sources ""`,
its working directory in a `mktemp -d`, `--permission-mode "$PERMISSION_MODE"`,
`--allowedTools "$ALLOWED_TOOLS"` plus the lines of `kit_read_rules`, and `--strict-mcp-config`,
and asks for a `Read` of `$SDD_HOME/templates/handoff.md`. It runs under
`--output-format stream-json --verbose`, because the `tool_use` and `tool_result` lines the
verdict reads exist only there, and with the environment cleared as `run_phase` clears it. The verdict reads the session's
artifact, never the model's answer:

- a denial naming the template in `permission_denials` → `_fail`, with the remedy;
- a `Read` `tool_use` of that path with a `tool_result` that is not an error → `ok`;
- no attempt → `warn`, because unmeasured is not zero;
- no init line and no result line → nothing new: the `Bash` probe has already said "did not
  answer", and one failure is never counted twice.

The denial is matched by the template's path, never by `tool_use_id`.

`tests/check-preflight.sh` holds the verdict with a stub pair that differs in one thing, and holds
the argv separately: the session carries an empty `--setting-sources` and the rule. Without the
second assertion a mutant that drops the rule from the probe would survive, because the stub
answers what the fixture says.

## Discarded

- **§1: `--add-dir "$SDD_HOME/templates"`.** It is the documented flag, and it reads. It also lets
  the session write into the kit under `acceptEdits` (measured), which leaves the kit guard as the
  only barrier, and the guard acts after the fact (`KIT-TOUCHED`).
- **§1: document the rule for the human's settings and only measure.** No permission code, and
  every new machine or target meets the blocked TICKET again, as jrc-libs did.
- **§2: a non-empty default, `$HOME/.claude/skills $HOME/.claude/plugins/cache`.** Every new target
  would work with no configuration, but the default fixes the harness's install layout inside the
  kit, has to open symlinks one level down (the `ticket` case), and lets every phase read every
  skill and plugin of the user.
- **§2: `reads: <skill>` in the hat's frontmatter, resolved by the runner.** No configuration, since
  the kit knows which hat calls which skill. `sdd preflight` already looks for these skills under
  `$HOME/.claude/skills/`, `$HOME/.claude/plugins/cache/` and the repo's `.claude/skills/`
  (`skill_findable`), and only warns when it misses them, because those roots are a convention.
  Granting a permission from that convention, plus the plugin cache's internal layout (the
  marketplace, a plugin name that is not the skill's, the versions), was the most fragile of the
  options.
- **§2: leave the skills to the human's settings and only measure.** No key and no validation, but
  the symlink trap stays with whoever writes the setting by hand, and a new machine meets the
  blocked TICKET again.
- **§3: isolate the existing probe.** One session instead of two, but the `Bash` proof loses the
  phase's flags, and `--agent` under empty settings was not measured.
- **§3: only an argv assertion in the suite.** Zero cost per preflight, but the preflight of a
  machine whose settings already grant the read stays green whatever the kit passes. This
  operator's `additionalDirectories` lists the templates directory, so the day the harness changes
  the rule's syntax would show only as denials in a real phase.

## Consequences

- Every phase, `sdd close` and the preflight probe read the templates the boot names with no help
  from the settings. A write there is still denied, and the kit guard still stops the line if one
  happens.
- `sdd preflight` pays one more haiku session (US$ 0.0018–0.0023 and about 6 s, measured), and it
  turns red the day the harness stops honouring the rule's syntax: the class of the 2.1.263 bump
  that stripped `Bash` from every hat.
- Every `Read`, `Edit` or `Write` the harness denied becomes a `DENIED` line in the mission's
  journal, which is what a human on `tail -F` reads. What stays denied (a skill no project
  declared, a scratch file) is named instead of counted. The ledger's `denials` count is unchanged.
- The targets declare `READ_EXTRA` (yokoten in lighthouse and jrc-libs). The hand-made
  `additionalDirectories` of 2026-10-16 and the `Read(*)` of `sales_quote` stay until the human
  decides to replace them.
- Declared limits: a `deny` rule in a target's settings blocks the real phase and not the isolated
  probe, and only the journal's `DENIED` line names it, during the run. The single-argument form
  (`--allowedTools "Bash Read(…)"`) was not measured. A symlink below a declared directory, as
  opposed to the directory itself, is not resolved. An `$SDD_HOME` that is not a literal path (a
  glob character, a space) goes into the rule as it is: that spelling was not measured, and the
  isolated probe of §3 is what says whether the harness reads it. `load_config` does not refuse it,
  because refusing would kill every kit command on a machine that works today without the read.
