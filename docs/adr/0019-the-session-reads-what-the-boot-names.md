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

`kit_read_rules` prints the rules every session the runner opens receives, one per line: the
templates' rules first, `Read(/$SDD_HOME/templates/**)`, which with an absolute `$SDD_HOME` is
`Read(//home/…/templates/**)`, then the project's (§2). One definition builds the rules of a
directory, `dir_read_rules`: the grammar, the rule, and the resolved target's rule when that target
passes the grammar too. `kit_template_rules` is that definition applied to the templates, and
`kit_read_rules` is `kit_template_rules` followed by one `dir_read_rules` per `READ_EXTRA` entry.
The three doors that assemble a `claude -p` read them: `run_phase` and `cmd_close` append every
line of `kit_read_rules` as one more argument of `--allowedTools`, after `"$ALLOWED_TOOLS"`; the
preflight probe hands the lines of `kit_template_rules` alone, with nothing before them (§3); and no
door copies a rule. The shape is the measured one: the rule as an argument of its own, two slashes
in its literal spelling. Three slashes were never measured.

The templates' own path is held to the grammar of §2 (`read_extra_dir_ok`; the Codex r3 #2 on PR
#315, decided by the human). The harness reads the rule as a pattern, so a kit at `/opt/sdd*` would
grant `/opt/sdd-secret/templates/**` as well, and the isolated probe of §3 stays green over it: it
proves that the session reads, never that it reads only what it should. A path the grammar refuses
gets no rule, and neither does its resolved target, since the harness wants both and the target's
alone reads nothing. The project's rules still follow: the read fails closed and is never widened.
`sdd preflight` fails once, naming the path and the grammar, saying that the phases will not read
the templates, and telling the operator to move the kit to a literal path. It does not open the
probe of §3, because there is no rule to measure: a probe over no rule (it never carries the
project's, §3) would fail a second time for the same cause and give the wrong reason.
`load_config` does not refuse that path. Refusing would kill every kit command, and the missing
read costs the phases only the templates.

### §2 — The project declares the skill directories in `READ_EXTRA`

`READ_EXTRA` is a config key, empty by default, validated in `load_config` and never at the point
of use, because a `die` there would land in a subshell (the `HAT_WRITES_EXTRA` lesson). Its
entries are absolute directories after expansion: written `$HOME/…` in the tracked
`.sdd/config.sh`, so the file names no user, or exported in the environment like every key. The
grammar is literal and admitted positively (`read_extra_dir_ok`, after `hat_extra_path_ok`): an
absolute path whose every component is a plain name of letters, digits, `.`, `_` and `-`. Every
other entry dies with its name in the reason: a relative path (a `~` inside quotes is not
expanded), a trailing `/`, an empty, `.` or `..` component, and any other character in a name —
the glob characters and brackets, `\`, `{`, a parenthesis that would close the rule, `@`, an
accented letter alike. A value that holds a newline dies too. `kit_read_rules` emits
`Read(/<dir>/**)` per entry and, when `readlink -f <dir>` differs, the rule for the resolved target
as well, but only when that target passes the same grammar: the machine chose its name, not the
config. A target that fails it gets no rule, and a read there is denied and named in the journal.
A directory that does not exist is a `warn` of `sdd preflight`, never a `die`: a plugin missing on
another machine must not stop the line. The kit grants nothing beyond its own templates, and each
target declares its skills. `sdd preflight` names, with no session and never as a failure, each
skill it finds that no rule covers, with the entry to add (for a plugin, the parent without the
version), and a declared skill whose symlink target the grammar refuses, with no entry to add, since
no entry reaches that target. It looks each skill up by the form its phase invokes it by, never by
the name alone (the Codex r7 on PR #315, decided by the human). `ticket`, `qa-report` and
`qa-execution` are invoked plain, and are looked up in the skills directories, then in the registry
under the key of the plugin named after the skill, then in the cache by name. The REVIEW phase
invokes `/codereview:codereview`, which the harness resolves through the install its registry
records for the codereview plugin, so that form is looked up there and in no plain directory: a
plain `~/.claude/skills/codereview` is a directory no phase loads. The copy held to the rules is the
`installPath` that `installed_plugins.json` records under the plugin's own key,
`<plugin>@<marketplace>`; another plugin listed first that also ships a `skills/codereview`, or one
whose name only starts with the same letters, is a copy no session of it loads (the Codex r3 #1 on
PR #315, decided by the human). For the `<plugin>:<skill>` form, a registry that records the plugin
and no install of it that holds the skill is a **broken install**. It is warned by name, with the
registry, the `installPath` and the remedy (reinstall the plugin), and never replaced by a copy from
the cache, since the harness keeps loading the recorded install. For that form the cache is walked
only when the registry records no install of the plugin (no file, unreadable, no `jq`, no `user`
install under its key), and only under the plugin's own tree,
`<cache>/<marketplace>/<plugin>/<version>/skills/<skill>`, any marketplace and any version (the
Codex r8 on PR #315, decided by the human). A plugin's skill is namespaced by its plugin, so another
plugin's `skills/codereview` never stands for it, and neither does the plugin's directory with no
such skill below it. The copy found is named at the plugin's own directory, above its versions,
which is also the entry to add. `plugin_install_paths` is the one reader of the registry, shared
with `sdd health`, which compares the grade table against the same copy.

### §3 — The preflight proves the kit's rule in a session of its own, with no settings

The existing probe (the executor hat and `Bash`, under `user,project,local`) stays as it is: its
parity with the phase is what it proves — the phase's flags minus the read rules, which the second
session proves. A second haiku session runs with `--setting-sources ""`, its working directory in a
`mktemp -d`, `--permission-mode "$PERMISSION_MODE"`,
an `--allowedTools` that carries the lines of `kit_template_rules` and nothing else, and
`--strict-mcp-config`, and asks for a `Read` of `$SDD_HOME/templates/handoff.md`. It runs under
`--output-format stream-json --verbose`, because the `tool_use` and `tool_result` lines the
verdict reads exist only there, and with the environment cleared as `run_phase` clears it. The verdict reads the session's
artifact, never the model's answer, and it names the outcome of the `Read` once: one jq over the
whole stream prints exactly one of five outcomes, and a `case` sends each to its arm, with a
default that fails. In precedence order:

- `denied`: a denial naming the template in a result line's `permission_denials` → `_fail`, with
  the remedy;
- `read`: a `Read` `tool_use` of that path with a `tool_result` that is not an error → `ok`;
- `errored`: a `tool_result` with `is_error` for that `Read`, none without it, and no denial naming
  the path → `_fail`, naming the path and the first line of the error (the content's string or its
  first text block, read like the stderr below), and saying that the phases will meet the same
  error: the template is missing or unreadable, or the harness reports a refusal only in the
  `tool_result` (the Codex P2 in the fourth round on PR #315, decided by the human);
- `not-tried`: an init line or a result line, and no `tool_result` for a `Read` of that path →
  `warn`, because unmeasured is not zero. Another tool, another path or another call's result never
  stands for that `Read`;
- `no-session`: no init line and no result line that jq can read → `_fail`, saying that the CLI did not answer
  this probe's flags and that the kit's rule was not measured, with the first line of the
  session's stderr (200 characters at most, control characters dropped, `(none)` when it is empty).
  A CLI that refuses `--setting-sources ""` or the rule's syntax exits before its init line while
  it answers the `Bash` probe, so this stream does not mean the CLI is dead (the Codex P2 in the
  second round on PR #315, decided by the human). One exception: when the `Bash` probe got no
  answer either, the cause is the same, and one cause is one failure. That probe has already
  failed, and this one only warns that it measured nothing;
- any other outcome → `_fail`: the classifier and the `case` drifted apart, and an outcome no arm
  knows is never green.

The verdict used to be a chain whose last two arms were defined by elimination, so an outcome it
did not name fell into the first arm left: a `Read` that came back with an error, its path in no
denial, warned that the session never tried, and the preflight stayed green over a template the
session had failed to read. The precedence keeps every decision the chain made: a denial wins, and
a `Read` retried after an error and then read is the rule working. The outcome is the first line jq
prints and the error the second, so a text with a newline is never read as an outcome.

The denial is matched by the template's path, never by `tool_use_id`. The session is opened even
when the `Bash` probe got no answer: the exception reads what both probes returned, so a CLI that
refuses only the `Bash` probe's flags still has the kit's rule measured. jq reads the stream as a
whole (`-s`), so one line it cannot parse sends the stream to `no-session` whatever else it
holds. That makes the preflight red, never green.

`"$ALLOWED_TOOLS"` stays off that flag (the Codex P3 on PR #315, decided by the human). It is a
project key, and a broad `Read` in it reads the template on its own, so the probe would be green
over a rule that is empty or that the harness no longer honours; the question is whether the kit's
rule reads, not whether this target's phases do.

The project's rules stay off it too (the Codex P3 in the fifth round on PR #315, decided by the
human: probe only the kit's rule). It is the same class with a second source of a broad rule: the
grammar accepts an entry that covers the kit (`$HOME`, with `$SDD_HOME` below it, a limit declared
under Consequences), and that entry reads the template by itself, so the probe certified a templates
rule that was sabotaged or broken. The probe measures exactly the rule it names. The `READ_EXTRA`
entries are covered by the preflight's warnings (an entry that does not exist, a skill no read rule
covers), which read `kit_read_rules` whole.

With nothing else on the flag the rules cannot be absent, since an `--allowedTools` with no argument
takes the next flag for its value: a `kit_template_rules` that printed nothing fails by name,
before any session. No configuration reaches that arm. A kit whose path the grammar refuses is
answered before it: named once, with no session (§1).

`tests/check-preflight.sh` holds the verdict with a stub pair that differs in one thing, and holds
the argv separately: the session carries an empty `--setting-sources` and, as its whole
`--allowedTools` list, the templates' rule, under an `ALLOWED_TOOLS` that carries `Read`. Without the
argv assertions a mutant that hands the probe something other than that rule — the user's settings,
`"$ALLOWED_TOOLS"` in front of it — would survive, because the stub answers what the fixture
says. Under a `READ_EXTRA` entry that covers the kit, the stub answers as the harness would (a
`Read(/<dir>/**)` argument reads what is under `<dir>`): the real kit's probe carries the templates'
rule alone and reads, a copy of the kit whose templates rule is broken is denied, and in both the
phases' projection carries the templates' rule and then the entry's, as before. `no-session` is
held in four worlds: the template probe prints nothing (with a long stderr line), it prints lines
jq cannot parse, both probes are dead, and only the `Bash` probe is dead. `errored` is held in three (the content a string, a list of blocks, and none), `not-tried`
against a denied `Bash` call, a `Read` of another path, another tool and a session line alone, the
precedence in two worlds of two outcomes, and the default on a sabotaged copy of the kit.

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
  (`skill_findable`; and in the registry, for a skill invoked as `<plugin>:<skill>`), and only warns
  when it misses them, because those roots are a convention.
  Granting a permission from that convention, plus the plugin cache's internal layout (the
  marketplace, a plugin name that is not the skill's, the versions), was the most fragile of the
  options.
- **§1: let a non-literal `$SDD_HOME` into the rule and leave it to the probe**, as first written.
  No kit is denied its templates, but a glob in the path widens the rule to every directory it
  matches, and the probe is green over the widening.
- **§1: escape the metacharacters of `$SDD_HOME` in the rule.** The kit would keep its templates
  wherever it lives, but the escape syntax of the harness's pattern was never measured, and a wrong
  escape fails open.
- **§1: refuse the path in `load_config`.** The refusal would be loud, and it would also kill every
  kit command, `sdd status` and `sdd preflight` included, over a read that costs only the templates.
- **§2: read the registry by skill, under any plugin's key**, as the preflight first did. One jq
  filter fewer, but a plugin listed before codereview that ships its own `skills/codereview` is
  the copy held to the rules while the REVIEW phase loads the other one, and `sdd health` already
  read only the `codereview@` keys, so the two disagreed about which copy is installed.
- **§2: look a skill up by its name, whatever form its phase invokes it by**, as the preflight did
  until the Codex r7 on PR #315. One list of names, shared with `KIT_THIRD_PARTY_SKILLS`, but it left
  two doors open: a plain `~/.claude/skills/codereview` was held to the rules while the REVIEW phase
  invokes `/codereview:codereview`, which the harness never loads from a plain directory, and a
  registry whose install had lost the skill fell through to whatever older copy the cache held. It
  was the third failure in a row in this lookup, and the state it was missing was the form of the
  call.
- **§2: walk the cache by name for the `<plugin>:<skill>` form too**, as the preflight did until the
  Codex r8 on PR #315. One `find` for both forms, but the first directory of the skill's name it met
  could be another plugin's `skills/codereview`, or the codereview plugin's own directory with no
  such skill below it: the preflight handed over that tree's entry and kept quiet about the missing
  skill. It was the fourth failure in a row in this lookup, and the state it was missing was which
  plugin a cache path belongs to.
- **§2: leave the skills to the human's settings and only measure.** No key and no validation, but
  the symlink trap stays with whoever writes the setting by hand, and a new machine meets the
  blocked TICKET again.
- **§3: isolate the existing probe.** One session instead of two, but the `Bash` proof loses the
  phase's flags, and `--agent` under empty settings was not measured.
- **§3: the probe under `"$ALLOWED_TOOLS"` plus the rules**, the phase's own allowlist, as first
  written. Parity with the phase, but a broad `Read` in a target's `ALLOWED_TOOLS` reads the
  template with no rule, and the probe printed that the kit's rule works over one that was empty or
  broken (the Codex P3 on PR #315).
- **§3: the probe under every line of `kit_read_rules`**, as written until the fifth round. One
  list for every door, but a `READ_EXTRA` entry that covers the kit reads the template in place of
  the templates' rule, and the probe certified a rule that was sabotaged or broken (the Codex P3 in
  the fifth round on PR #315). The human decided on probing only the kit's rule.
- **§3: no verdict for a stream with no init line and no result line**, as first written. The
  `Bash` probe's "did not answer" was meant to cover it, which holds only when the whole CLI is
  dead. A CLI that refused one of this probe's flags left the preflight green over a rule it never
  measured (the Codex P2 in the second round on PR #315).
- **§3: skip the template probe when the `Bash` probe got no answer.** One session less on a dead
  CLI, but it repeats the assumption that P2 refuted, in the other direction: that the two probes
  always die together.
- **§3: a second failure for a dead CLI.** Each probe would say what it saw, but the operator
  would read two failures for one cause. The human decided on one cause, one failure.
- **§3: one more `elif` for the `Read` that came back with an error.** The smallest diff, but it
  keeps the shape behind the third finding in a row in this probe (the Codex P3, then the P2 of the
  second and of the fourth round on PR #315): arms defined by elimination, where the next
  outcome a harness invents falls into the first arm left. The human decided on naming the outcome
  once, with a default that fails.
- **§3: only an argv assertion in the suite.** Zero cost per preflight, but the preflight of a
  machine whose settings already grant the read stays green whatever the kit passes. This
  operator's `additionalDirectories` lists the templates directory, so the day the harness changes
  the rule's syntax would show only as denials in a real phase.

## Consequences

- Every phase, `sdd close` and the preflight probe read the templates the boot names with no help
  from the settings. A write there is still denied, and the kit guard still stops the line if one
  happens.
- `sdd preflight` pays one more haiku session — US$ 0.002 (US$ 0.00197 measured on 2026-10-20 at
  22:59, Claude Code 2.1.304, with the rule reading the template) and about 6 s (the grill's p5 and
  p6, 16:24) —, and it turns red the day the harness stops honouring the rule's syntax: the class
  of the 2.1.263 bump that stripped `Bash` from every hat. It turns red too, naming the first line
  of the CLI's stderr, the day the CLI stops accepting one of this probe's flags.
- Every `Read`, `Edit` or `Write` the harness denied becomes a `DENIED` line in the mission's
  journal, which is what a human on `tail -F` reads. What stays denied (a skill no project
  declared, a scratch file) is named instead of counted. The ledger's `denials` count is unchanged.
- The targets declare `READ_EXTRA` (yokoten in lighthouse and jrc-libs). The hand-made
  `additionalDirectories` of 2026-10-16 and the `Read(*)` of `sales_quote` stay until the human
  decides to replace them.
- Declared limits: a `deny` rule in a target's settings blocks the real phase and not the isolated
  probe, and only the journal's `DENIED` line names it, during the run. The converse holds for a
  broad `Read` in a target's `ALLOWED_TOOLS`, or a `READ_EXTRA` entry that covers the kit: its
  phases read the templates even when the kit's rule does not, and its probe is red anyway, because
  the probe measures the kit's rule. The single-argument form (`--allowedTools "Bash Read(…)"`)
  was not measured. A symlink below a declared directory, as opposed to the directory itself, is
  not resolved. An `$SDD_HOME` that is not a literal path (a
  glob character, a space, a `+`) gets no rule (§1), and its phases are denied the templates, which
  `sdd preflight` says by name. This line used to say that such a path entered the rule as it was
  and that the isolated probe of §3 would tell whether the harness read it. The probe cannot tell:
  it proves that the session reads, and a glob that widens the rule reads too (the Codex r3 #2 on PR
  #315). The suite runs from the checkout it lives in, so a checkout under such a path turns the
  assertions that expect the templates' rule red there.
- Declared limits of the reach and of the probe. The grammar holds the name, not the reach: an
  entry equal to `$HOME`, or a symlink whose target is the home, passes it and becomes
  `Read(//home/<user>/**)` (`/home` itself becomes `Read(//home/**)`), so every phase may read the
  whole home. That is read only, and a phase already has `Bash`, which reads whatever the user can,
  so it is hygiene, not a boundary. Such an entry no longer answers for the kit's rule in the probe
  of §3, which carries the templates' rules alone.
  `readlink -f` runs when the argv is assembled, once per session: a symlink retargeted during the
  session fails closed, its new target denied and named by a `DENIED` line in the journal. The two
  paid probes of `sdd preflight` carry a cost cap (`--max-budget-usd 1` each) and no time cap:
  nothing in the runner ends a probe session that does not answer.
