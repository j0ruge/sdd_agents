# ADR 0012 — A session's git moves carry its label, and a commit without it is not the hat's

- **Status**: accepted (—, 2026-09-26)
- **Spec**: docs/handoffs/20260926-a-carona-antes-do-congelamento/00-missao.md

## Context

Since `20260903-a-fronteira-do-chapeu` the runner stops the line when a session writes outside its
hat's `writes:`. `hat_guard_check` (`bin/sdd`, at `3c44df8`) reads two halves: the paths of
`git diff --name-only <HEAD before the session> <HEAD after it>`, and the new entries of
`git status`. Every path either half returns is attributed to the session.

The diff half measures the WINDOW, not the SESSION. Issue #51, measured in `lighthouse_project`: a
human committed a one-line ADR fix from a separate session, in the same working tree, while the
TICKET phase ran. The phase had done its work (issue created, branch cut, `10-ticket.md` written),
and the line stopped with `hat-crossed` and two remedies that were both wrong: restore the path by
hand, or widen `HAT_WRITES_EXTRA`. The second one would weaken a real guard for good to silence a
transient race. The ledger row it left is read by the judge as friction of the kit version.

The checkout lock of PR #48 does not cover this. It admits entries of the kit (`coordination_enter`)
and says so: it coordinates the kit's own commands, not external edits.

Two facts decided the mechanism, both measured on 2026-09-26:

- **The session transcript cannot attribute a commit.** The executor commits with `git commit -q`.
  In the 8 most recent EXEC streams of `sales_quote` there are 12 `git commit` tool calls, all 12
  with `-q`, and 0 commit SHAs printed.
- **The reflog can.** With `GIT_REFLOG_ACTION` in the environment, git 2.43.0 writes that label into
  the reflog entry of `commit`, `commit --amend`, `checkout` and `reset`:
  `sdd-session abc123: session commit` for the labelled commit, `commit: human commit` for the one
  made without it. The reflog of `HEAD` is per worktree, so a concurrent writer in the same checkout
  lands in the same log, and a writer in another worktree does not.

## Decision

1. **Every session runs with a label.** `run_phase` and `cmd_close` start `claude` with
   `GIT_REFLOG_ACTION=sdd:<step>:<first 8 characters of the invocation id>`. One definition
   (`session_git_label`) spells it, and `run_phase` publishes it as `LAST_PHASE_GIT_LABEL`.
2. **The guard reads the window through the reflog.** `hat_guard_arm` records the newest reflog
   entry of `HEAD` before the session. `hat_guard_check` takes the entries written after it. An
   entry that carries the session's exact label is the session's: its paths (`git diff --name-only
   <old> <new>` of that entry) are checked against `writes:` as today. An entry without the label is
   **foreign**.
3. **A foreign commit that touched a path outside `writes:` still stops the line**, with its own
   ledger `kind`, `foreign-commit`. The reason names the commit (sha and subject), and the remedy is
   the right one: nothing commits into this checkout while a phase runs, then `sdd run` again. A
   foreign commit that stayed inside `writes:` is not a stop, exactly as today.
4. **When the reflog cannot account for the move, nothing changes.** No reflog, the recorded entry
   no longer found, or HEAD moved with no new entry (`core.logAllRefUpdates=false`): the guard falls
   back to today's range diff, and every path is the session's.
5. **The kit guard does not move to the label.** `kit_guard_check` stays as it is, and the finding
   about the `kit-touched` attribution stays open in `TODO.md`.

## Implementation

Confirmed by I3 (the label) and I4 (the reading) of the mission.

- **The label (I3).** `session_git_label <step> <sid>` prints `sdd:<step>:<sid8>` and is the one
  spelling; a QA step reads `sdd:QA:plan:<sid8>`. `run_phase` zeroes `LAST_PHASE_GIT_LABEL` on
  entry, next to `SESSION_DIED_WHY` and `SESSION_BUDGET_CUT`, and sets it right after minting
  `$sid`, so the 8 hex are the ones the session's log file is named after, on a retry too (the
  retry mints a fresh `$sid` and hands claude `--resume <old> --fork-session`). The label enters
  the command as `env -u … GIT_REFLOG_ACTION=<label> claude -p`, between the last `-u` and
  `claude`, because `env` takes assignments only after its options. `cmd_close` mints its own
  label with the same function and passes it the same way; it is the one `claude -p` of the
  pipeline that does not go through `run_phase`. The projection (`--dry-run`) prints the label in
  every block, and `tests/check-dry-run.sh` checks it against the block's session id.
- **The window (I4).** `hat_guard_arm` records `HAT_REFLOG_TOP`, the newest line of
  `git reflog show --date=unix --format='%gd%x09%H%x09%gs' HEAD` (`hat_reflog_lines`), and
  `HAT_REFLOG_COUNT`. Two entries of the same second share the selector, so an entry is the whole
  line. `hat_reflog_window` takes the `count now − HAT_REFLOG_COUNT` newest entries and accounts for
  the move only when there is at least one, the line right below them is `HAT_REFLOG_TOP` and the
  newest one's sha is `HEAD`; otherwise, or with no label or no recorded top, it returns 1 and
  `hat_guard_check` falls back to the range diff. It is read only when `HEAD` moved, as the diff
  half always was.
- **The attribution (I4, corrected by review r1).** Each new entry is diffed against the one below
  it (the recorded top for the oldest) through `hat_diff_names`, the one definition of
  `-c core.quotePath=false diff --name-only` that the window and the fallback share. An entry whose
  subject is the session's exact label — alone, followed by `:`, or followed by ` (` as rebase
  writes it — is the session's; any other entry is foreign. Then everything is cut down to the net
  diff `<before>..<now>`: a net path is the session's when a session entry touched it or no foreign
  entry did, and it joins the status half against `writes:` as before; a foreign entry is listed as
  `<sha7> <subject>` when it touched a net path outside `writes:` that is not the session's. The
  first draft summed the entries without the net cut, and a round trip through another branch read
  as a crossing the range diff never saw — review r1 reproduced it.
- **The marker (I4).** `FOREIGN_COMMIT_WHY` is armed by `hat_guard_check` only when the session's
  own paths armed nothing, with a `FOREIGN-COMMIT` and a `FOREIGN-REMEDY` line in the journal. It
  is reset at the entry of its only setter, beside `HAT_CROSSED_WHY`. `hat_crossed_escalation`
  reads it third, after `HAT_CROSSED_WHY` and `KIT_TOUCHED_WHY` — the session's own crossings are
  the ones to name when both arm — with `kind: foreign-commit` and its own remedy in place of the
  hat's. The four doors did not change.

## Alternatives discarded

- **Keep the range diff and only improve the message.** It names the commits in the window and adds
  the concurrent-writer remedy, and it still records the human's commit as `hat-crossed`. The judge
  would keep reading it as friction of the version.
- **Attribute by the SHAs the session printed.** 0 of the 12 commits in those 8 streams printed
  one, because `git commit -q` prints nothing. Anything the session does not print escapes the attribution.
- **Ask the session to commit with `--trailer`.** That is a sentence in a prompt, and the kit already
  learned that a prompt sentence is a reminder, not a rule. A session that forgets the trailer would
  be blamed or cleared by accident, and the human's commits carry no trailer either way.
- **Warn and do not stop on a foreign commit.** A session that strips its own label would then cross
  its hat without stopping the line. Stopping keeps that path fail-safe: an evasion changes the
  `kind`, never the stop.

## Consequences

- A commit made from another session during a phase stops the line as `foreign-commit`, with the
  commit named and the remedy that fits. The human's commit no longer reaches the judge as the hat's
  crossing.
- `foreign-commit` joins the open tail of the ledger `kind` column. The readers group by `kind`
  dynamically, so the new value is counted without a code change on their side;
  `docs/pipeline.md` and `config/schema.md` list it.
- Declared limits, written in the header of `hat_guard_check`:
  - a git that wrote a reflog message of its own instead of the label would make the session's move
    read as foreign. The line still stops; only the `kind` is wrong. Measured on git 2.43, no command
    does: commit, `--amend`, checkout, switch, reset, merge, pull, cherry-pick, revert and stash write
    `<label>` or `<label>: …`, and rebase writes `<label> (start|pick|finish): …` — all read as the
    session's (the first draft of this list named `rebase` and `pull` as overwriters, and review r1
    measured otherwise);
  - a target-repo hook that reads `GIT_REFLOG_ACTION` to tell whether it runs inside a rebase would
    see one in every git call a session makes;
  - three of the fallback checks (`k ≥ 1`, the recorded top right below the new entries, the newest
    entry at `HEAD`) have no probe: attribution never widens the net diff and charges an
    unexplained net path to the session, so skipping one changes the kind at worst;
  - uncommitted edits of a concurrent writer still land in the `git status` half and are still
    attributed to the session;
  - when the session crosses its hat AND a foreign move leaves it in the same phase, only the
    session's paths are named (`hat-crossed`); the foreign move is not written up, and it rides into
    the next lap's base. The line stops either way;
  - `cmd_kaizen` exports the label through `run_phase` and is still not guarded, as before.
