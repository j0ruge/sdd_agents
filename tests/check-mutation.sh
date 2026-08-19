#!/usr/bin/env bash
# Sensor of the sensor: proves the suite MEASURES something.
#
# Sabotages the runner in a COPY and demands the suite go RED. An assertion that cannot fail is
# indistinguishable from one that passes — that is how three gate bugs of the SAME family crossed
# a green suite and only showed up in real use, at ~US$ 40 in re-run sessions (see KAIZEN_LOG).
# A fixture written from memory agrees with the wrong gate forever.
#
# WARNING: exporting SDD_MUTANT in your shell skips the linter AND the mutation for the whole
# suite — the variable is the anti-recursion mechanism, not a user option.
#
# Usage: tests/check-mutation.sh   (exit 0 = catalogue intact and every unlisted mutation caught)

set -uo pipefail

# Double guard against recursion: run-all.sh already does not call this script when SDD_MUTANT is
# set. If we got here with it set, the guard over there fell — dying loudly beats fork-bombing the
# machine of whoever ran the suite.
if [ -n "${SDD_MUTANT:-}" ]; then
  echo "check-mutation.sh is running INSIDE a mutant — the run-all.sh guard has fallen" >&2
  exit 1
fi

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# JOBS resolution
#
# The default derives from the machine instead of being the constant 4 it used to be: a 20-core
# box was pinned to 4 while a 2-core one was oversubscribed by the same constant. Capped at 8 —
# each mutant runs a whole copy of the suite, and past that point the copies fight for disk and
# memory instead of finishing sooner. An explicit SDD_MUTATION_JOBS always wins; garbage in it is
# refused by name, never silently degraded (0 used to reach `i % JOBS` as a division by zero).
# ---------------------------------------------------------------------------
detect_cores() { # behaviour, not presence — the bin/sdd preflight pattern for the GNU userland
  nproc 2>/dev/null && return
  getconf _NPROCESSORS_ONLN 2>/dev/null && return
  sysctl -n hw.ncpu 2>/dev/null && return
  echo 4
}

resolve_jobs() { # resolve_jobs <env-value> <cores> — pure; prints JOBS or refuses by name
  local env_value="$1" cores="$2"
  if [ -n "$env_value" ]; then
    # ONE validation arm, deliberately. A first draft paired this case with a `[ -ge 1 ]` check
    # and the adversarial pass proved them redundant — either alone refuses everything, with the
    # same message. `0*` covers both the literal 0 and leading zeros ("08" is octal to bash
    # arithmetic and used to CRASH the old `i % JOBS`, so refusing it by name is the upgrade).
    case "$env_value" in
      0*|*[!0-9]*) echo "SDD_MUTATION_JOBS must be an integer >= 1 (got: $env_value)" >&2; return 1 ;;
    esac
    echo "$env_value"; return
  fi
  case "$cores" in *[!0-9]*|'') cores=4 ;; esac
  [ "$cores" -ge 1 ] || cores=1
  [ "$cores" -gt 8 ] && cores=8
  echo "$cores"
}

# The catalogue cannot reach this function — it lives in the harness, not in bin/sdd — so it
# carries its own probes, the CLAUDE.md rule for sensors the mutation cannot kill. Pure-function
# pairs only; detect_cores is machine-dependent and stays unprobed (the chain is trivial to read).
jobs_selftest() {
  local got
  got="$(resolve_jobs "" 20)"      && [ "$got" = 8 ]  || { echo "  SELFTEST FAIL  cap: 20 cores resolved to '$got', expected 8" >&2; return 1; }
  got="$(resolve_jobs "" 2)"       && [ "$got" = 2 ]  || { echo "  SELFTEST FAIL  small box: 2 cores resolved to '$got', expected 2" >&2; return 1; }
  got="$(resolve_jobs "" 0)"       && [ "$got" = 1 ]  || { echo "  SELFTEST FAIL  floor: 0 cores resolved to '$got', expected 1" >&2; return 1; }
  got="$(resolve_jobs "" bogus)"   && [ "$got" = 4 ]  || { echo "  SELFTEST FAIL  garbage cores resolved to '$got', expected the 4 fallback" >&2; return 1; }
  got="$(resolve_jobs 1 20)"       && [ "$got" = 1 ]  || { echo "  SELFTEST FAIL  explicit env must win: got '$got', expected 1" >&2; return 1; }
  got="$(resolve_jobs 32 4)"       && [ "$got" = 32 ] || { echo "  SELFTEST FAIL  explicit env is not capped: got '$got', expected 32" >&2; return 1; }
  # Assert the MESSAGE, not just the rc: without the case arm, 'abc' is still refused — but by
  # `[ abc -ge 1 ]` erroring ("integer expression expected"), an accident sharing the same rc.
  got="$(resolve_jobs abc 20 2>&1)" && { echo "  SELFTEST FAIL  'abc' in the env was accepted" >&2; return 1; }
  case "$got" in *"must be an integer"*) : ;; *) echo "  SELFTEST FAIL  'abc' was refused by accident, not by name: $got" >&2; return 1 ;; esac
  resolve_jobs 0 20   >/dev/null 2>&1 && { echo "  SELFTEST FAIL  '0' in the env was accepted — it reaches i % JOBS as a division by zero" >&2; return 1; }
  resolve_jobs -1 20  >/dev/null 2>&1 && { echo "  SELFTEST FAIL  '-1' in the env was accepted" >&2; return 1; }
  return 0
}

if ! jobs_selftest; then
  echo "the JOBS resolution does not measure what it claims — refusing to schedule mutants with it" >&2
  exit 1
fi

JOBS="$(resolve_jobs "${SDD_MUTATION_JOBS:-}" "$(detect_cores)")" || exit 1
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-mut-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Catalogue
#
# Mutation idiom: find the line by a UNIQUE anchor and touch only that line. If the anchor
# disappears in a refactor, the `cmp` below reports "did not apply" instead of scoring a point — a
# mutation that does not sabotage is the decorative assertion this file exists to hunt, one level
# up. Anchor on CODE, never on prose: prose gets translated, code does not.
#
# Name: mut_<GATE>_<slug> for a gate — `sdd health` greps exactly that prefix to demand one
# mutation per gate, so changing it there blinds health. Everything else is named after the
# COMMAND or helper it sabotages (RUN_, PRE_, RETRY_, APPROVE_, AUTONOMY_, FRONTMATTER_): the
# prefix is where to look when a mutant survives, and "not a gate" is not a place.
# ---------------------------------------------------------------------------

mut_PLAN_empty_approval() {   # accepts an empty `aprovacao:` — an unapproved plan becomes runnable
  sed -i 's/^    auto)          : ;;/    auto)          : ;;\n    "")            : ;;/' "$1"
}

# Blinds the kit to where the plan came from: `aprovacao: auto` next to a 05-verdict.md passes
# again, so a plan the kit wrote about itself certifies its own homework and `sdd run` spends a
# whole pipeline on it. Anchored on the marker's filename inside the condition — the one token that
# cannot survive a rewrite of this branch, and the only thing gate_KAIZEN and gate_PLAN agree on.
#
# It sabotages the DEFINITION, which since the F1 fix is shared: the predicate answers "no" to both
# readers at once, so gate_PLAN stops refusing AND cmd_approve goes back to reading the born plan's
# `auto` as an approval. That is the point — the two readers agreeing wrongly is the state this
# function exists to make impossible, and a mutant that killed only the gate's call would leave the
# other reader's assertion green and credit this entry for half a measurement.
mut_PLAN_kaizen_born_blind() {
  sed -i 's|^    && \[ -f "\$MISSION_DIR/05-verdict.md" \]$|    \&\& false|' "$1"
}

# Strips the remedy from the ORDINARY refusal: a plan whose `aprovacao:` is empty — the state every
# human-approved plan starts in, so the common stall and not the exotic one — is handed the SHAPE to
# type into the frontmatter and never the command that types it. No gate opens that should not and
# nothing fails; the runner simply goes back to sending the human to an editor, which is the failure
# `sdd approve` was built to end and which the sibling branch three lines below already refuses to
# commit. The expensive shape again: not a command that breaks, a door whose handle is invisible.
#
# ADDRESSED to the line rather than anchored on the bare command name: `sdd approve $MISSION`
# appears twice in gate_PLAN — here and in the kaizen-born refusal — and an unaddressed
# substitution would gut both while wearing this entry's name, when mut_PLAN_kaizen_born_blind
# already owns the other one. What has to die is the `unapproved plan is told` pair and only it, so
# every kaizen-born assertion stays green and the score credits this entry for the common stall.
mut_PLAN_remedy_unnamed() {
  sed -i '/00-missao.md has/ s@: run .sdd approve \$MISSION.@@' "$1"
}

mut_TICKET_no_sprint() {      # stops requiring `sprint:` — a card in the backlog is invisible work
  sed -i "s|.*if ! grep -qiE '\^sprint:.*|  if false; then|" "$1"
}

mut_EXEC_done_without_commit() {  # accepts a 'done' increment with commit '—' — label becomes artifact
  sed -i 's|.*\[ "\$commit" = "—" \].*|        if false; then|' "$1"
}

mut_EXEC_orphan_commit() {    # back to `cat-file -e`: a loose object passes as a commit in history
  sed -i 's|.*git merge-base --is-ancestor.*|        if false; then|' "$1"
}

mut_EXEC_ignores_TEST_CMD() { # discards the suite's rc — the gate stops measuring TEST_CMD
  sed -i 's|.*run_check_cmd "\$TEST_CMD" "gate-exec-test".*|  if false; then|' "$1"
}

# Historical bug 1 (SQ-97 pilot, ~US$ 15 a round): the skill emits
# `- **Started:** <ts> · **Status:** in-progress`, and the gate required `**Status:**` to OPEN the
# line. It never matched; the runner re-ran qa-execution forever.
mut_QA_status_line_start() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '^\\\\*\\\\*Status:\\\\*\\\\*[[:space:]]*closed' \"\$report\"|" "$1"  # sdd-pipefail-waiver: sed s|…|…| delimiter, not a pipe
}

# Loose enum: the `closed` has to come right after `**Status:**`. With `.*closed` the template
# legend (`<!-- in-progress | closed -->`) matches, and a report still IN PROGRESS passes.
mut_QA_status_enum_loose() {
  sed -i "s|.*grep -qE '\^\[\[:space:\]\]\*-\.\*\\\\\*\\\\\*Status.*|  grep -qE '\\\\*\\\\*Status:\\\\*\\\\*.*closed' \"\$report\"|" "$1"  # sdd-pipefail-waiver: sed s|…|…| delimiter, not a pipe
}

# Same family, in the bug registry: with `.*open` the legend
# `<!-- open | fixed | verified | wont-fix | invalid -->` matches, and a `wont-fix` bug (a human
# decision, not a blocker) starts blocking the phase.
mut_QA_bug_enum_loose() {
  sed -i "s|\[\[:space:\]\]+open'|.*open'|" "$1"
}

mut_QA_matrix_pending() {     # ignores a 'Pending' matrix row — an unwalked journey passes
  sed -i 's|.*Pending\[\[:space:\]\]\*.*|    if false; then|' "$1"
}

mut_QA_bug_open() {           # ignores a bug with Status: open in the registry
  sed -i 's|.*\[ "\$openbugs" -gt 0 \].*|  if false; then|' "$1"
}

# Historical bug 3 (SQ-97 pilot, ~US$ 10): the parser exited only at `###`, kept swallowing the
# report's following tables and failed an all-Grade-A review for finding a `Commit` column.
mut_REVIEW_stops_at_h3() {
  sed -i 's|.*inside && /\^#{1,6}\[\[:space:\]\]/ { exit }.*|      inside \&\& /^###[[:space:]]/ { exit }|' "$1"
}

mut_REVIEW_accepts_B() {      # any grade passes — the gate stops requiring Grade A
  sed -i 's|if (grade != "A")|if (grade == "ZZZ")|' "$1"
}

# Historical bug 4 (reproduced 2026-08-19, in the planning session of the mission that fixed it —
# the slug is not spelled out here because tests/ is English surface): the extractor took
# `crit = f[2]; grade = f[3]` and never touched `f[4]`, so `A` on every row with the literal
# `PREENCHER` on every justification bought a green gate. The live instance is
# docs/handoffs/20260818-lote-facil/40-review-r1.md:8, which records it in its own `gate:` field —
# a round that did not close, certified by the one sensor of the mission's quality.
# Addressed to the body of gate_REVIEW: an unaddressed `s|if (placeholder|` would be the same
# family as the two mutations already logged in TODO.md for sabotaging a second site in silence.
mut_REVIEW_placeholder_rationale_blind() {
  sed -i '/^gate_REVIEW()/,/^}/ s|if (placeholder(rat))|if (0)|' "$1"
}

# The other half of the same seal, and a SECOND mutant on purpose: one sabotage per site. With
# only the Rationale mutant above, the `gate:` branch could be deleted whole and the catalogue
# would still read 100% — the exact vacuity this file exists to refuse.
mut_REVIEW_gate_field_blind() {
  sed -i '/^gate_REVIEW()/,/^}/ s|if (gate_field != "" \&\& placeholder(gate_field))|if (0)|' "$1"
}

mut_DOCS_pending_status() {   # accepts an area with Status '✗' in the drift checklist
  sed -i 's|.*\[ -n "\$pending_cell" \].*|  if false; then|' "$1"
}

mut_PR_no_artifact() {        # a missing 50-pr.md stops failing — a "complete" mission with no PR
  sed -i 's|GATE_WHY="missing 50-pr.md"; return 1|GATE_WHY="missing 50-pr.md"; return 0|' "$1"
}

# The gate stops looking at the stamp, so a mission closes over a mutation catalogue nobody ran.
# It is the state the kit was actually in between PR #12 and PR #13: the fast suite green, the
# catalogue carrying a live survivor, and every gate agreeing that the mission was finished.
# Addressed to the body of gate_PR — an unaddressed `s|if \[ -f "$REPO_ROOT/tests|` would be the
# same family as the two mutations already logged in TODO.md for sabotaging a second site in
# silence, since the runner tests other files by that shape elsewhere.
mut_PR_stamp_blind() {
  sed -i '/^gate_PR()/,/^}/ s|if has_mutation_catalogue "\$REPO_ROOT"; then|if false; then|' "$1"
}

# The WRITER goes back to answering about the tree its own file sits in, whatever tree the operator
# is standing in and whatever tree the gate is about to ask for. With `sdd` on the PATH — the
# install README.md documents — over a worktree or a second clone of the kit, the stamp lands in
# one tree while gate_PR keys, scopes and reads under the other: a gate unsatisfiable forever whose
# own remedy re-measures the wrong tree at twenty to fifty minutes a lap.
#
# Sabotaging the CONDITION and not deleting the branch: what has to be measured is that the working
# directory can win, not that an `if` is present. Addressed to the body of health_kit_root, the
# family two mutations already in TODO.md got wrong by leaving the address off.
mut_HEALTH_stamp_tree_blind() {
  sed -i '/^health_kit_root() {/,/^}/ s|if \[ -n "\$cwd_root" \] \&\& has_mutation_catalogue "\$cwd_root"; then|if false; then|' "$1"
}

# The WRITER's half of the same seal, and a second mutant for the same reason the `gate:` branch of
# gate_REVIEW got one: with only the reader sabotaged, this whole comparison could be deleted and
# the catalogue would go on reading 100%. One sabotage per site.
# The stamp stops asking whether the measured tree moved WHILE the catalogue ran — a window twenty
# to fifty minutes wide, opened by the very phase that also commits, at the end of which the key
# would describe whatever is on disk rather than what was measured.
mut_HEALTH_stamp_window_blind() {
  sed -i '/^cmd_health()/,/^}/ s|elif \[ "\$stamp_key" != "\$stamp_key_before" \]; then|elif false; then|' "$1"
}

# Not a gate, and the only decorative-assertion bug that really happened (TODO.md): the inverted
# guard makes the PROJECTION (`--dry-run`) write to the journal while the real path goes mute — a
# read command dirtying the working tree, and an audit trail lying in both directions.
mut_RUN_inverted_journal() {
  sed -i 's|\[ "\$DRY_RUN" = "1" \] && return 0|[ "$DRY_RUN" = "0" ] \&\& return 0|' "$1"
}

# Not a gate: the target repo declares OUTPUT_LANG and the runner swallows the request in silence.
# It is the typical failure mode of a config key — the key exists, the schema promises it, and
# nobody reads it (the LINT_CMD/BUILD_CMD/DEV_UP_CMD family, frozen in health-baseline).
mut_RUN_ignores_output_lang() {
  sed -i 's|.*if \[ -n "\$OUTPUT_LANG" \]; then.*|  if false; then|' "$1"
}

# Not a gate: the ledger the kaizen judge reads. The projection starts writing, and rows for
# sessions that never happened enter the arithmetic that decides whether the kit graduates.
mut_RUN_autonomy_ignores_dry_run() {
  sed -i 's|  if \[ "\$DRY_RUN" = "1" \]; then return 0; fi|  if false; then return 0; fi|' "$1"
}

# The reader treats a row with no `moved` field (an older schema) as "did not move" instead of
# excluding it. Old history gets its waste inflated, and every later change looks like progress —
# the failure mode is a judge that congratulates the kit for nothing.
mut_RUN_autonomy_null_moved_as_zero() {
  sed -i 's|and (has("moved"))|and true|' "$1"
}

# Task 2 review measured this one by hand (Minor 6): up to check-autonomy.sh's moved-sensor
# scenario, no test in the repo ever made a session actually change the disk — every `claude`
# stub was dead (rc 1) or dry, so `moved` was always "false" and this exact no-op scored a point
# for nothing. It matters now because waste is defined as sessions that did NOT move the disk: a
# regression here both escalates BLOCKED on phases that were genuinely progressing and records
# every session as waste, with the suite green throughout.
mut_RUN_moved_never_true() {
  sed -i 's|    \[ "\$before" != "\$after" \] && moved="true"|    true|' "$1"
}

# Not a gate: the one-shot guard on the "kit is not a git checkout" warning. It reads cosmetic and
# is not — the flag only holds because `autonomy_kit_stamp` publishes AUTONOMY_KIT_STAMP as a
# global instead of being read through `$( )`, which ran the whole body, and its assignment, in a
# SUBSHELL that reset the flag on every call. This mutation restores that exact behaviour by other
# means: the warning goes back to firing once per ledger row, and a guard nobody can see failing is
# the decorative assertion this file exists to hunt.
mut_RUN_autonomy_sha_warn_repeats() {
  sed -i 's|    AUTONOMY_SHA_WARNED=1|    AUTONOMY_SHA_WARNED=0|' "$1"
}

# The KAIZEN gate goes blind to WHICH kit sha a verdict judged: any verdict file satisfies it.
# check-kaizen.sh plants a stale verdict for an older sha with a complete born plan beside it —
# under this sabotage the pending-verdict scenario returns 0 ("already judged") instead of
# escalating, and an old judgement silently covers every future kit change.
mut_KAIZEN_gate_blind() {
  sed -i 's|if \[ "\$(frontmatter "\$f" kit_sha_judged)" = "\$expected" \]|if [ -f "$f" ]|' "$1"
}

# ADR 0003 becomes an orphan: the runner stops naming the record that decides its own guard floor.
# The document survives on disk, so the shape assertion stays green and only the citation half of
# check-kaizen.sh goes red — which is the point. A decision record no code names is a label, and a
# label is what every gate in this kit refuses to accept as evidence. `g` because the citation is
# expected to appear at more than one site (the floor comment, the explanation printed to the
# human): stripping only the first would leave the assertion green and measure nothing.
mut_KAIZEN_adr_0003_orphan() {
  sed -i 's|ADR 0003|ADR|g' "$1"
}

# The runner goes blind to a degenerate axis: the predicate answers false everywhere, so
# `guard.degenerate_axis` is false in every repo and the explanation never prints. The human in the
# kit repo reads `sufficient: false` and goes hunting for the missions that would satisfy it — which
# no number of missions in THIS repo ever will, because each one commits and lands on a fresh sha
# (ADR 0003). Sabotaging the PREDICATE and not the printer measures both halves at once: the field
# and the sentence come from one source, and a mutant that killed only the print would leave the
# derived number free to drift from what the human is told. `@` as the delimiter because the pattern
# carries the jq pipe.
mut_KAIZEN_degenerate_axis_blind() {
  sed -i 's@| ($window | length) > 1@| false@' "$1"
}

# The window goes back to the WHOLE history, which is what it was until r2 of mission
# 20260817-eixo-do-juiz. The ledger is append-only, so one ancient kit_sha that once bought two
# sessions turns the structural explanation off forever while every recent version sits at one
# session each — the field stops working and nothing says so.
mut_KAIZEN_degenerate_axis_all_history() {
  sed -i 's@| ($order\[(if $n > guard_floor then $n - guard_floor else 0 end):\]) as $window@| $order as $window@' "$1"
}

# The window loses its second clause and goes back to judging a QUIET STRETCH as a broken axis. The
# field says "the axis cannot work here", so a repo whose own history reached the floor — twice —
# and then went three versions quiet reads `degenerate_axis: true`, and the runner tells its human
# to stop waiting for missions that are in fact arriving. The field then errs at exactly the
# distinction it exists to make, and it feeds the judge prompt.
# ⚠️ The anchor is `$best_reach`, not the `all($order[]; …)` this clause was first written as: the
# reach test was regrouped into one `group_by` to stop being O(versions × rows), and the old anchor
# stopped matching. It failed the honest way — CATALOGUE-BROKEN, rc 90 — which is the harness guard
# doing its job, and the same trap the apostrophe in `mut_LEDGER_repo_root_common_parent` sprang.
mut_KAIZEN_degenerate_axis_reach_blind() {
  sed -i 's@        and $best_reach < guard_floor;@        ;@' "$1"
}

# `gate_KAIZEN` goes back to dropping the rc of the series read. errexit is OFF inside every gate
# (each caller invokes it as `gate_KAIZEN || gate_rc=$?`), so an unreadable ledger arrives as the
# empty string and the gate reports "no verdict for kit  yet" — corruption spelled exactly like
# pending work, which sends the runner on to spend an opus session judging a file nobody can parse.
# The reader beside it dies loudly over the same file; this half guessed, and guessed expensively.
# The window goes back to counting SESSIONS instead of MISSIONS, and stops agreeing with the floor
# it explains. A version whose two sessions belong to one mission — an in-loop auto retry — still
# contributes one mission, so `missions_with_session` stays 1 and the floor stays unsatisfiable; the
# session count of 2 nevertheless turns the field `false` and takes the sentence with it. The human
# reads a bare `sufficient: false` and waits for missions that cannot help.
mut_KAIZEN_degenerate_axis_session_unit() {
  sed -i 's@and all($window\[\]; . as $sha | ($rows | missions_on($sha)) == 1)@and all($window[]; . as $sha | ($rows | map(select(.kit_sha == $sha and .event == "session")) | length) == 1)@' "$1"
}

# The window sorts its versions and stops meaning "recent". `shas_in_file_order` is what makes the
# window recency rather than alphabetical, and a `sort` slipped inside this one consumer is
# invisible: the latest/previous pair keeps its own probe, so only the window goes blind. An ancient
# version whose sha happens to sort last is dragged into the window and silences the explanation
# forever — N8 all over again, and by construction with nothing saying so.
mut_KAIZEN_degenerate_axis_window_sorted() {
  sed -i 's@| ($rows | shas_in_file_order) as $order@| ($rows | shas_in_file_order | sort) as $order@' "$1"
}

mut_KAIZEN_series_rc_dropped() {
  sed -i 's@  series="$(kaizen_series)" || series_rc=$?@  series="$(kaizen_series 2>/dev/null)"; series_rc=0; series="${series:-{\\}}"@' "$1"
}

# The mission identity loses the repo and goes back to the bare slug. A no-op until --all-repos
# existed; with it, two projects that ran the same dated slug on the same kit_sha collapse into one
# group — missions_with_session drops, guard.sufficient can flip, and one project `refez` swallows
# another project clean `ok`. Both readers are sabotaged by the one anchor pair below on purpose:
# the two spellings are one mechanism, and check-autonomy.sh compares the readers to each other.
mut_KAIZEN_mission_key_slug_only() {
  sed -i 's@def mission_key: \[(.repo // ""), (.mission // "")\];@def mission_key: [(.mission // "")];@g' "$1"
}

# The repo identity goes back to the PARENT of the shared .git — the first spelling of the worktree
# fix, and the one that silently merged repositories: every submodule of one parent answers
# `/parent/.git/modules`, and every bare repo beside another answers the directory that holds them.
# Nothing is excluded and nothing is reported (`other_repo: 0`), which is the contamination the
# filter exists to name, arriving through a different door.
#
# ⚠️ This anchor has now moved TWICE with the same function, and both moves were the honest
# failure — CATALOGUE-BROKEN, rc 90 — rather than a mutant quietly measuring nothing. The first
# time the anchor held `CDPATH=''` and had to be double-quoted, because an apostrophe cannot
# survive inside a single-quoted shell string (`''` there closes the quote and reopens it, so sed
# received `CDPATH= cd`). The second time `ledger_repo_root` dropped the two `cd`s entirely for
# `--path-format=absolute`, and the whole anchored line ceased to exist. It is single-quoted again
# now that no apostrophe is in it. The lesson both times: a mutant anchored on a line a refactor
# can delete has to be re-derived WITH that refactor, in the same commit.
mut_LEDGER_repo_root_common_parent() {
  sed -i 's@^  gitdir="\$( git -C "\$start" rev-parse --path-format=absolute --git-common-dir 2>/dev/null )" || return 0$@  printf "%s" "$( dirname "$( git -C "$start" rev-parse --path-format=absolute --git-common-dir 2>/dev/null )" )"; return 0@' "$1"
}

# The ENVIRONMENT gets to answer "which repo is this" again. This mutant puts back the exact
# spelling `ledger_repo_root` carried before the `--path-format=absolute` rewrite, minus the
# `CDPATH=''` guards: a RELATIVE common dir (`.git` at a checkout root) fed to a bare `cd`, which
# bash resolves through $CDPATH and whose find it echoes into the capture. A dotfiles checkout in
# the path collapses every repository on the machine into one identity — writer and readers
# agreeing, `other_repo: 0`, nothing said — and `CDPATH=.` alone puts a second LINE in the field.
#
# ⚠️ It is deliberately NOT a sabotage that fails with a clean environment. With $CDPATH unset this
# mutant behaves EXACTLY like the healthy function, in every repo shape, which is the point: the
# only thing that can catch it is the poisoned-CDPATH differential pair in check-autonomy.sh, and
# the pair carries its own floor proving the poison is armed. A mutant that any assertion could
# catch would prove nothing about the two that were written for this.
# ⚠️ BOTH spellings, in one mutant, and that is the whole repair of this entry.
#
# It sabotaged only the FAST path, and `75c9d2a` made that a no-op: the shape guard empties a
# poisoned value and the pre-2.31 FALLBACK — which carries its own `CDPATH=''` — then resolves it
# correctly. Sane and mutant answered BYTE FOR BYTE the same, rc 0 both, so the entry sat in the
# catalogue certifying a protection nothing was measuring. Reported as `is NOT caught`, which is
# the catalogue doing its job on itself.
#
# Splitting it in two was the other direction the finding offered, and it is the wrong one HERE:
# a fast-path-only mutant stays neutralised by the fallback no matter which entry it lives under.
# The property being defended is "no `cd` in this function reads CDPATH", and that property has
# two sites, so the sabotage has two sites.
mut_LEDGER_repo_root_cdpath_leak() {
  sed -i 's@^  gitdir="\$( git -C "\$start" rev-parse --path-format=absolute --git-common-dir 2>/dev/null )" || return 0$@  local rel; rel="$( git -C "$start" rev-parse --git-common-dir 2>/dev/null )"; gitdir="$( cd "$start" \&\& cd "$rel" \&\& pwd -P 2>/dev/null )" || return 0@' "$1"
  sed -i 's@CDPATH='"''"' cd "\$start" && CDPATH='"''"' cd "\$common"@cd "$start" \&\& cd "$common"@' "$1"
}

# The bare test goes back to asking about the ENTRY POINT instead of the repository, and one
# repository gets two identities. `rev-parse --is-bare-repository` answers for the path git was
# entered through: a bare repo living in a directory named `.git` says `true` read from itself and
# `false` read from a linked worktree of itself, so the cosmetic `/.git` strip fires on the second
# reading only — `/x/.git` and `/x` for one repo, which makes every row written from the worktree
# foreign to every row written from the repo. The sibling of the collapse above and the same class
# of silence: both readings are non-empty and plausible, so nothing warns.
mut_LEDGER_bare_by_entry_point() {
  sed -i 's@git -C "$start" config --bool --get core.bare 2>/dev/null@git -C "$start" rev-parse --is-bare-repository 2>/dev/null@' "$1"
}

# The Jidoka dies: `verdict: piorou` no longer stops the line. The outcome falls through to the
# born-plan branch and exits 0 — a kit change that made autonomy WORSE reads as a green light,
# which is the exact failure ADR 0002 exists to forbid.
mut_KAIZEN_jidoka_dead() {
  sed -i 's|if \[ "\$GATE_KAIZEN_VERDICT" = "piorou" \]; then|if false; then|' "$1"
}

# The approved-plan protection dies EVERYWHERE: this sed hits all three identical bailout guards
# in cmd_kaizen at once (a deliberate exception to the one-line idiom — the three sites are one
# mechanism, and sabotaging any subset is caught by the same scenarios). A filled `aprovacao:`
# then flows into fix-it sessions that can blank a human's approval, and a retry-written approval
# gets misreported as a no-progress escalation.
mut_KAIZEN_approved_bailout_dead() {
  sed -i 's|if \[ -n "\$GATE_KAIZEN_APPROVED" \]; then|if false; then|' "$1"
}

# The rubric's strongest signal is dropped: phases with an escalation, a human retry or a failing
# last gate label as "ok". The judge would congratulate the kit precisely on the missions where
# the human had to push the work again. RUN_ prefix and not KAIZEN_: kaizen_series is a helper the
# runner reads, not the gate — the naming rule in the header comment holds.
mut_RUN_refez_dropped() {
  sed -i 's|then "refez"|then "ok"|' "$1"
}

# The guard floor goes back to counting every mission on the axis, escalations included: three
# missions that stopped the line without spending a single session free the judge to rule
# `melhorou` on a kit version it observed nothing of. Same RUN_ prefix and same reason as the
# mutation above — the floor lives in kaizen_series, a helper; KAIZEN_guard_ignored is the one
# that sabotages the gate that READS it, and the pair covers producer and consumer.
mut_RUN_guard_counts_escalations() {
  sed -i 's@missions_with_session: (\$sess @missions_with_session: (\$rows @' "$1"
}

# The guard stops guarding: gate_KAIZEN accepts `melhorou`/`piorou` written over an insufficient
# series. The whole point of the runner-owned guard (boot prompt: "the guard belongs to the
# runner") dies silently — a verdict label alone starts satisfying the gate, which is the
# label-instead-of-artifact failure principle 1 exists to forbid.
mut_KAIZEN_guard_ignored() {
  sed -i 's|if \[ "\$sufficient" != "true" \] && \[ "\$verdict" != "indeterminado" \]; then|if false; then|' "$1"
}

# Not a gate, and the most expensive false negative the runner can produce: the Jidoka goes back
# to a PIPE. Under `pipefail` `grep -q` exits on the match, `printf` dies of SIGPIPE and the
# pipeline returns 141, so the `if` reads "no blocked" while a blocked increment EXISTS — and the
# runner burns the whole phase budget against the wall it already knew was there. Note this is the
# sabotage that a SMALL fixture cannot see: the race is decided by the size of the text, which is
# why check-gates.sh asserts it on a 20000-row checkpoint.
mut_RUN_jidoka_pipefail() {
  sed -i 's@grep -qx "blocked" <<< "$ckstatus"@printf "%s\\n" "$ckstatus" | grep -qx "blocked"@' "$1"  # sdd-pipefail-waiver: this payload IS the bug, deliberately
}

# Not a gate, and the exact bug I2 closed: `force_phase="PR"; continue` sat ABOVE both writers, so
# the runner lowering its own bar — the single most interesting autonomy event a mission can
# produce — reached neither the journal nor the ledger. The series showed failing REVIEW sessions
# followed by a PR phase and nothing saying why, and the judge reads the series.
#
# It is also the guard on the reachability of an expensive fixture: check-autonomy.sh has to
# satisfy PLAN/TICKET/EXEC/QA and keep the disk MOVING to reach the draft branch at all. If a
# future change makes that fixture stop arriving there, this mutation stops being caught and the
# score says so — instead of a whole block of assertions passing over a branch nobody ran.
mut_RUN_degraded_row_dropped() {
  sed -i 's|autonomy_degraded_row "review-to-draft"|: "review-to-draft"|' "$1"
}

# Not a gate, and the other half of the same writer: the one-shot guard dies and the branch writes
# a row on EVERY lap. `force_phase="PR"` does not end the run — PR's gate fails, `current_phase`
# hands REVIEW back with the budget still blown, and the branch is re-entered. One degradation,
# three rows in both readers, against the "exactly one" of the mission's metric. This is the
# CARDINALITY of the record, which RUN_degraded_row_dropped (the writer's existence) cannot see:
# that one stays caught with the guard sabotaged, and this one stays caught with the writer intact.
#
# It is also what keeps check-autonomy.sh's degradation fixture in the REPEATING regime. The
# assertion it kills was green for two commits over a stub that moved the disk once, asserting a
# property of the fixture and not of the code — the third such vacuity of this mission.
mut_RUN_degraded_repeats() {
  sed -i 's|if \[ "\$degraded_logged" = "0" \]; then|if true; then|' "$1"
}

# Not a gate (RUN_ per the naming rule above — `cmd_autonomy` is a reader, not a gate): the human's
# escalation table loses the kit_sha axis and goes back to counting `.kind` over the whole ledger.
# The series keeps slicing per version, so the two instruments over the SAME file start reporting
# different escalation counts for the same period with nothing explaining the divergence — and kit
# version is the axis the ledger exists to measure. The `on_axis` filter is left ALONE on purpose:
# a mutant that sabotages both halves would stop distinguishing which one the assertions measure.
mut_RUN_escalations_no_axis() {
  sed -i 's|group_by(.kit_sha, .kind)|group_by(.kind)|' "$1"
}

# Not a gate: `phase_label` goes back to knowing only `blocked`, so a mission where the runner
# lowered its own bar reads `ok` in the judge's label histogram as soon as a later `sdd run` gets
# REVIEW past its gate — the rubric groups by (mission, phase) over the whole kit_sha slice, not
# per run. It sabotages ONLY phase_label's use of the shared predicate; the `escalations` map and
# the admission filter keep theirs, so what dies is the label and nothing else, and this mutant
# cannot be confused with RUN_degraded_row_dropped (the row's existence) or RUN_refez_dropped
# (the `refez` value itself, which stays reachable through the other two clauses).
mut_RUN_degraded_label_blind() {
  sed -i 's@if (map(select(is_escalation)) | length) > 0@if (map(select(.event == "blocked")) | length) > 0@' "$1"
}

# Not a gate (RUN_ per the naming rule above — latest_matching is a helper): the file picker goes
# back to a lexicographic `sort`, and `r10` sorts between `r1` and `r2`. From the tenth review
# round on, gate_REVIEW stops reading the round that just ran and reads `r3` — a review that was
# already all-A when it was approved, so the gate PASSES and the mission walks past a report
# nobody read. It is the sabotage that fails OPEN, and the one a fixture of three rounds cannot
# see: with REVIEW_MAX_ITER at 3 the two orders agree, which is exactly why check-gates.sh has to
# spend a fourth fixture on `r10`. The `sort -V` of health_skills (bin/sdd:1339) is left ALONE —
# the sed anchors on `ls -1d $pattern` — so what dies is the picker and nothing else.
mut_RUN_sort_lexi() {
  sed -i 's@ls -1d $pattern 2>/dev/null | sort -V@ls -1d $pattern 2>/dev/null | sort@' "$1"
}

# Turns the existence guard into a tautology, so `sdd install` walks into the sed again with a
# half-copied kit: 0-byte .sdd/config.sh on disk, and the next install reporting it as preserved.
# It is a sabotage that fails OPEN in the half that matters — rc stays non-zero either way,
# because sed's own rc is what killed the install before the guard existed. Only the assertions
# that read the branch's own text and the ABSENCE of the file can see it, which is the whole point
# of spending a mutation here. Anchors on `-f ` + the path: the `sed` line below feeds the same
# path with no `-f`, and is deliberately left alone.
mut_RUN_install_no_guard() {
  sed -i 's@-f "$SDD_HOME/config/starter.conf"@-n "always-there"@' "$1"
}

# Not a gate: the ledger readers go back to asking "can this row be attributed to a kit version?"
# in two spellings — `.kit_dirty == false` for sessions, `.kit_dirty != true` for escalations and
# for the judge. This is the EXACT pre-fix text, and it is why the mutant needs two edits: reverting
# `on_axis` alone would drag `comparable` lax with it (a wrong single definition), which is a
# different defect from the fork. What dies here is the differential assertion in check-autonomy —
# the twin rows with kit_dirty:null and a sha filled, where the escalation table grants a version
# the session table denies. Every row the runner writes today satisfies both spellings, so no
# fixture in the ordinary regime can tell this mutant from the fix.
mut_RUN_on_axis_forked() {
  sed -i \
    -e 's@def on_axis: .kit_dirty == false and .kit_sha != null;@def on_axis: .kit_dirty != true and .kit_sha != null;@' \
    -e 's@def comparable: .event == "session" and on_axis and (has("moved"));@def comparable: .event == "session" and .kit_dirty == false and (.kit_sha != null) and (has("moved"));@' \
    "$1"
}

# Not a gate: the LOOP half of the self-degradation, the other half of the pair whose RECORD half
# RUN_degraded_repeats owns. Puts the bare `force_phase="PR"; continue` back on the second entry,
# so the runner goes REVIEW→PR→REVIEW again with the REVIEW budget still blown — and, the part that
# actually misinforms, finally escalates as `budget-exhausted` in **PR**, a phase that was never
# over budget. The one-shot guard is left ALONE, so the ledger still shows exactly one `degraded`
# row and this mutant cannot be confused with RUN_degraded_repeats (which sabotages the guard and
# leaves the ending intact): what dies here is the number of laps, the number of PR sessions and
# the phase the run blames, and nothing else. Anchors on the second-entry warn — the first-entry
# one lives inside the guard and says something different, so the sed cannot hit both.
mut_RUN_degraded_spins() {
  sed -i 's@warn "  the draft PR did not satisfy its gate either — the run ends here"@force_phase="PR"; continue@' "$1"
}

# Not a gate: the streaming session. `--output-format stream-json` WITHOUT `--verbose` is refused
# by the CLI at argument validation ("When using --print, --output-format=stream-json requires
# --verbose") — rc 1, empty stdout, no model ever reached. It is the rarest kind of sabotage in
# this catalogue: no stub in the suite can see it, because a stub ignores its flags and answers
# anyway, so every behavioural fixture stays green while every REAL mission dies on its first
# phase. What kills it is the dry-run projection, the one place the suite reads the true argv.
mut_RUN_stream_no_verbose() {
  sed -i 's@--output-format stream-json --verbose@--output-format stream-json@' "$1"
}

# Not a gate either, and the other half of the pair: the stream is written but never distilled, so
# $logfile holds the WHOLE session instead of its terminal `result` object. jq then answers once
# per line, `tonumber?` refuses the multi-line string, and every session's cost lands in the ledger
# as null — the judge summing money it can no longer see, with the suite green. Anchors on the call
# site rather than on stream_summary's body: the body is one jq filter whose plausible degradations
# (`select(true)`, `head -1`) are indistinguishable from the fix on a one-result stream, so
# sabotaging it there would score a point no assertion could ever have earned.
mut_RUN_stream_summary_unfiltered() {
  sed -i 's@stream_summary "$streamfile" > "$logfile"@cp "$streamfile" "$logfile"@' "$1"
}

# Not a gate, and the third of the streaming trio: the `|| true` that keeps jq's exit status inside
# stream_summary comes off. jq answers 5 on the first unparseable line, a session killed mid-write
# ends in exactly one, and under `set -euo pipefail` that 5 walks out of the function and aborts the
# bare call in run_phase — the entire run gone with rc 5, no journal line, no ledger row, no gate,
# and nothing printed. Sabotaging the `|| true` and not the `2>/dev/null` beside it is the point:
# the stderr redirect only hides jq's complaint, while the status is what kills.
#
# Anchored on the whole jq line and NOT on the bare `| tail -1 || true`: latest_matching() ends in
# those same five tokens for its own reason (`ls` failing on no match), so the short anchor would
# sabotage two unrelated functions in one mutant and the point it scored would name neither.
mut_RUN_stream_summary_fatal() {
  sed -i "s@jq -c 'select(.type == \"result\")' \"\$1\" 2>/dev/null | tail -1 || true@jq -c 'select(.type == \"result\")' \"\$1\" 2>/dev/null | tail -1@" "$1"
}

# The journal stops naming an unknown cost, half one of two: an answer that carries no money makes
# jq print its own `null`, and the run files that word in the money column as if the CLI had said
# it. The ledger cannot notice — `($cost | tonumber? // null)` maps "?", "null" and "" to the same
# null — so this is a defect only the human reading pipeline.log ever meets, which is exactly the
# kind this catalogue keeps letting through. Caught by the `covered:` cost assertion of
# check-autonomy.sh and by nothing else in that file.
mut_RUN_cost_absent_unlabelled() {
  sed -i 's@ // "?"@@' "$1"
}

# Half two, and a separate entry because it is a separate guard for a separate shape: a session with
# no terminal `result` leaves an EMPTY summary, jq exits 0 having printed nothing, and the `|| echo
# "?"` above it never fires because nothing failed. The journal line came out `cost_usd=  log=…`,
# an unlabelled hole where every other row says `?`. Replaced by `true` rather than deleted, so the
# shape of the function is untouched and only the fallback dies.
mut_RUN_cost_empty_unlabelled() {
  sed -i 's@^  \[ -n "$cost" \] || cost="?"$@  true@' "$1"
}

# `--max-phases` stops stopping. The option still parses and still counts; the run simply keeps
# going and opens every session the pipeline has left — the human who asked for ONE session to look
# at the result gets the whole pipeline instead. The branch is left whole and only its condition
# dies, so the mutant is a runner that reads the flag and ignores it, which is what a regression
# here would actually look like.
mut_RUN_max_phases_ignored() {
  sed -i 's@^    if \[ "$max_phases" -gt 0 \] && \[ "$phases_run" -ge "$max_phases" \]; then$@    if false; then@' "$1"
}

# The watcher's exit status overwrites the session's. The tempting one-liner — `wait` without the
# `|| true`, or with its status kept — and the phase then reports how the WATCHER died instead of
# how the session did: journal and ledger record a green phase for a failed one.
#
# Deliberately NOT the `tee` shape the run_phase comment refuses: that one is already killed by
# the stream witness (a pipe under stdout is not the stream file), so a mutant built on it would
# score a point for an assertion that predates this fix and prove nothing about the rc rule.
mut_RUN_progress_eats_rc() {
  sed -i 's@wait "$watcher" 2>/dev/null || true; fi@wait "$watcher" 2>/dev/null; rc=$?; fi@' "$1"
}

# The observer never starts, so the terminal goes back to the banner and nothing else — the exact
# defect this fix exists to end, and one that hides well because every artifact downstream stays
# correct. Anchored on the call site and not on the `auto` arm of progress_wanted: that arm needs
# a tty, no test has one, and a mutant nothing can reach scores a permanent free point.
mut_RUN_progress_dead() {
  sed -i 's@  if progress_wanted; then stream_watch "$streamfile" & watcher=$!; fi@  watcher=""@' "$1"
}

# Not a gate: the entry point goes back to the bare `main "$@"` it shipped with for its whole life,
# so bash can return from the last command and ask this file for more input. It is the sabotage
# that changes NOTHING observable in any ordinary run — every command still works, every rc is
# still right — and only bites the day something appends to bin/sdd while it is executing, which
# is precisely what the EXEC phase does to it. No behavioural fixture can see it without editing a
# running runner, so what has to catch it is the form assertion in check-entrypoint.sh; if that
# assertion is ever loosened into "the guard appears somewhere", this mutant survives and says so.
# The delimiter is `|` and not the `@` every other mutation here uses: the anchor CONTAINS `"$@"`,
# so an `@` delimiter closes the expression in the middle of the entry point and sed dies with
# "unterminated `s' command". Cheap to write, and it would have read as anchor rot (rc 90).
mut_RUN_entrypoint_unguarded() {
  sed -i 's|^{ main "$@"; exit $?; }$|main "$@"|' "$1"
}

# Not a gate: the ledger goes back to being one namespace shared by accident — every reader sees
# every repo on the machine, which is how a `sdd run` in a /tmp fixture repo once moved the judge's
# own numbers to `66% waste · 2 mission(s)` where the truth was `0% · 1`.
#
# It sabotages the DEFINITION and not any one call site, and that is the whole point: the predicate
# is spliced into cmd_autonomy, kaizen_series and (through the series) the post-pipeline reminder.
# Sabotaging one call would measure one call; sabotaging the definition measures that all of them
# really go through it. What dies is the pair of differential assertions — the series read from two
# repos in check-kaizen.sh, the human table read from two repos in check-autonomy.sh — and neither
# can survive it, because both compare two readings of ONE file against each other.
mut_RUN_ledger_no_repo_filter() {
  sed -i 's@def ledger_row_is_local: if ledger_row_no_repo then false elif (type == "object" and has("repo")) then .repo == $repo else true end;@def ledger_row_is_local: true;@' "$1"
}

# Not a gate: a row with no `repo` key goes back to being local in EVERY repo, and the bucket that
# names it goes back to reading 0. The judge's floor is then movable by rows nobody can attribute
# to any project — three of them cleared `sufficient` in fixture — and nothing in the output says a
# row was even admitted. The expensive shape again: not a number missing, a number moved with no
# reason printed beside it.
#
# It sabotages `ledger_row_no_repo` and NOT `ledger_row_is_local`, which is what keeps it distinct
# from the two entries above: the repo filter itself stays honest (the two-repo differentials stay
# green), so what has to die is the pair that reads the same three sessions with and without the
# key. Emptying the definition kills the counter and the exclusion at once, because both go
# through it — the single-definition discipline, measured.
mut_LEDGER_no_repo_counted_as_local() {
  sed -i 's@def ledger_row_no_repo: type == "object" and ((\.repo // "") == "");@def ledger_row_no_repo: false;@' "$1"
}

# Not a gate: `--all-repos` is still accepted, still documented, and does nothing — the shape of
# dead flag that is worst to have, because the human asks the cross-project question, gets an
# answer, and the answer is about one repo. The complement of the mutation above: that one opens
# the filter that must stay shut by default, this one welds shut the door that must open on demand.
#
# `g` because the flag is parsed in TWO commands (cmd_autonomy and cmd_kaizen) and the differential
# pair reads one of them each: killing only the first would leave the judge's half green and
# measure half a flag. It sabotages the SETTERS and not `ledger_row_is_local`, which is the whole
# point of there being one predicate — a mutant that emptied the predicate would be indistinguishable
# from mut_RUN_ledger_no_repo_filter and would score the same point twice.
mut_AUTONOMY_all_repos_ignored() {
  sed -i 's@LEDGER_ALL_REPOS=1@LEDGER_ALL_REPOS=0@g' "$1"
}

# Not a gate: the ledger's repo identity goes back to `git rev-parse --show-toplevel`, which
# answers per WORKTREE. Nothing fails, nothing is malformed — a mission run from `git worktree add`
# simply stamps a path no other checkout of the same repo recognizes, and every reader files those
# rows under `other_repo`. The judge's series goes empty in the isolation workflow this kit itself
# recommends, and it goes empty QUIETLY, which is the shape of defect the repo filter exists to
# forbid: a number that moved with nothing saying why.
#
# It sabotages the ONE definition and not the call sites, like mut_RUN_ledger_no_repo_filter: the
# writer and the three readers all resolve identity here, so emptying the body is what proves they
# really share it. Reverting only the writer (or only the reader) would leave the two sides
# agreeing on the OLD identity — the differential pair reads 3-own/0-foreign either way, and the
# mutant would survive while measuring nothing.
#
# Re-anchored with the `--path-format=absolute` rewrite: it used to replace the `common=` line,
# which that rewrite deleted.
# The shape guard drops, and a git older than 2.31 gets to name the repository. `rev-parse` ECHOES
# an option it does not know and still exits 0, so the answer is two lines — the flag, then the
# relative common dir — and neither `|| return 0` (rc is 0) nor `-n` (not empty) refuses it. Caught
# by the pre-2.31 differential pair of check-autonomy.sh, which reads the identity back out of the
# runner under a shim and demands it be the repo or nothing, never the flag. The `case` and its
# `esac` go together: removing the opener alone leaves invalid bash, which is a harness failure and
# not a capture.
mut_LEDGER_repo_root_shape_blind() {
  perl -0pi -e 's@  case "\$gitdir" in\n    /\*\) \[ "\$gitdir" = "\$\{gitdir%%\$.\\n.\*\}" \] \|\| gitdir="" ;;\n    \*\)  gitdir="" ;;\n  esac\n@@' "$1"
}

mut_LEDGER_repo_root_toplevel() {
  sed -i 's@^  gitdir="\$( git -C "\$start" rev-parse --path-format=absolute --git-common-dir 2>/dev/null )" || return 0$@  printf "%s" "$( git -C "$start" rev-parse --show-toplevel 2>/dev/null )"; return 0@' "$1"
}

# Not a gate: the preflight goes back to asking whether the agent copy EXISTS, which is what it did
# for its whole life while printing "N kit agent(s) checked" — a label over a comparison that never
# happened. The harness loads the copy, so with this in place the kit source can be corrected and
# every agent keeps running the old text, green in everything (2132cf5 did exactly that).
#
# It sabotages the `cmp -s` arm only, leaving the "not installed" arm intact: an absent copy still
# fails, so any assertion that merely counts preflight failures or reads its rc survives. What dies
# is the differential pair in check-preflight.sh — one fixture read twice, one byte apart — plus
# the stale message itself. `elif` → `elif false &&` keeps the branch syntactically alive so the
# mutant is valid bash and the sabotage is precisely the comparison, nothing else.
mut_PRE_agent_presence_only() {
  sed -i 's@elif ! cmp -s "$a" "$copy"; then@elif false \&\& ! cmp -s "$a" "$copy"; then@' "$1"
}

# Not a gate: the base branch warning goes back to being decoration. The body is emptied while the
# function keeps existing and keeps returning 0, so every call site stays syntactically valid and
# nothing else about the runs changes — which is exactly the shape of the defect this closes, a
# warning that only ever reached cmd_preflight while `sdd run` and `sdd kaizen` opened committing
# sessions in silence.
#
# It sabotages the DEFINITION, for the same reason mut_RUN_ledger_no_repo_filter does: killing the
# call in cmd_run leaves check-kaizen.sh green and killing the one in cmd_kaizen leaves
# check-gates.sh green, so a per-call-site sabotage would measure one door. Emptying the body kills
# the presence half of BOTH differential pairs at once, and only that proves all three doors really
# go through the one function.
mut_RUN_base_branch_warn_dead() {
  sed -i 's@^  \[ -n "\$branch" \] && \[ -n "\$DEFAULT_BRANCH" \] && \[ "\$branch" = "\$DEFAULT_BRANCH" \] || return 0$@  return 0@' "$1"
}

# Not a gate: `sdd approve` keeps working, keeps asking, keeps committing — and writes `auto`
# instead of `humano-<date>`. The gate opens either way, so nothing that reads an rc can see it,
# and every downstream reader (the handoffs, the kaizen judge, a human doing archaeology on the
# history) is now told the plan cleared PLAN-AUTO on its own when in fact a human typed y. The
# expensive shape: not a command that fails, a command that lies in a committed artifact.
#
# It sabotages the single definition of the value rather than the write call, and that is what
# makes it survivable enough to be interesting: the command's own read-back guard compares against
# the same variable, so the mutant passes its self-check and reaches `git commit`. Splitting the
# literal across the write and the verify would leave a mutant that merely dies, which measures
# nothing. What has to die is the assertion demanding `humano-` AND the absence of `auto`.
mut_RUN_approve_writes_auto() {
  sed -i 's@^  local approved_as; approved_as="humano-\$(date +%F)"$@  local approved_as; approved_as="auto"@' "$1"
}

# `sdd approve` goes back to reading a kaizen-born `auto` as an approval already given — the exact
# state the kit shipped in between increment I4 and this fix, and the one sdd-qa walked: gate_PLAN
# refuses the plan and names this command, the command answers "already approved — nothing to do",
# and the two loop forever with no exit but the hand-edited frontmatter the command exists to end.
# Nothing fails, nothing warns; the runner simply prints an instruction that cannot be obeyed.
#
# The SECOND deliberate exception to "sabotage the definition, never the call site", for the same
# reason mut_RETRY_base_branch_warn_dead is the first: the defect this increment closes IS a reader
# that does not consult the shared condition, and mut_PLAN_kaizen_born_blind already empties the
# definition for both readers at once. Sabotaging the body again would measure that entry's ground
# twice and leave the approve door borrowing its coverage from a neighbour. What has to die here is
# `approve resolves` and only it — the gate keeps refusing, so every kaizen-born assertion above it
# stays green and the score credits this entry for the remedy alone.
#
# Addressed to cmd_approve's body: `plan_approves_itself` is read in two functions, and an
# unaddressed substitution would be a sabotage of the gate wearing this entry's name. The range
# ends at the first column-zero `}`, which is cmd_approve's own — every line of the body is
# indented.
mut_RUN_approve_bails_on_kaizen_born() {
  sed -i '/^cmd_approve() {/,/^}/ s@^      if ! plan_approves_itself; then$@      if true; then@' "$1"
}

# `sdd approve` stops refusing a mission whose plan is not on disk: the guard still asks gate_PLAN
# and still tests the reason, it simply does nothing about it. The command then previews, writes
# `aprovacao: humano-<today>` and commits — an approval of a mission that is one file, with the
# next `sdd run` opening an EXEC session over no plan and no increments.
#
# `:` and not a deletion: the `then` needs a body, and a mutant that dies of bash scores a point
# for a door that was never opened. Range-addressed to cmd_approve because `die "$GATE_WHY"` is
# also how cmd_kaizen refuses an unreadable ledger, and an unaddressed sed would sabotage the two
# commands at once. Caught by the `covered:` assertion of check-gates.sh and by nothing else —
# measured, and unsurprising: every other approve fixture ships the three artifacts, so gate_PLAN
# never answers `missing ` for them.
mut_RUN_approve_no_plan_blind() {
  sed -i '/^cmd_approve() {/,/^}/ s@; then die "$GATE_WHY"; fi@; then :; fi@' "$1"
}

# The runner stops reading the `branch:` field — the state the kit lived in until this mission, and
# the one that let five phases of the SQ-97 pilot commit into another PR's branch. It is a no-op
# that costs nothing and breaks nothing on screen: the run goes on, the gates pass, and every
# commit lands wherever the human happened to be standing.
#
# It blanks the READ rather than the checkout, which keeps the mutant honest in two ways. The whole
# function still runs, so an assertion that merely reached the code would stay green; and the
# empty-value no-op is the one path left alive, so the placeholder assertion survives on purpose —
# what has to die is the pair that proves the declared branch is honoured, checked out when it
# exists and cut from the CURRENT branch when it does not.
#
# The dry-run guard would have been the obvious anchor and is the wrong one: pipeline_log_line
# carries a byte-identical line, so a `sed` on it sabotages two functions at once and the score
# would credit this entry for whatever the other one broke.
mut_RUN_branch_switch_dead() {
  sed -i 's@^  want="\$(frontmatter "\$MISSION_DIR/00-missao.md" branch)"$@  want=""@' "$1"
}

# Lets a declared branch name that git reads as an OPTION through to the checkout. The case arm
# stays in the file, it simply stops matching — so the function still looks guarded to a reader, and
# `branch: -f` becomes `git checkout -f`: a legal command that returns 0, switches to nothing and
# DISCARDS every uncommitted change in the tree. The run then goes on, on the branch the human was
# already standing on, with the `ok` line announcing a switch that never happened. It is the only
# path in this function that destroys work rather than merely landing in the wrong place.
#
# The pattern is what gets sabotaged rather than the `die`, because a mutant that turned the die
# into a `return 0` would make the whole field a no-op and kill three other assertions with it —
# this entry has to be credited for the option-shaped name and nothing else.
# Goes back to treating the checkout as the end of the decision: the plan is read on one branch and
# the tree is replaced by another, and nothing looks again. The `die` becomes a `:` with the same
# string, so the condition still runs and a reader still sees a guard — the run simply goes on with
# MISSION_DIR pointing at a directory the checkout removed, announcing the switch as a success and
# then telling the human the mission was never planned. The quiet variant is the expensive one: a
# branch carrying an OLDER copy spends real sessions on a plan nobody approved.
#
# This is the regime the whole branch family was blind to until r1 of the review: five assertions
# on a fixture whose artifacts were never `git add`ed, where `git checkout` cannot remove them.
mut_RUN_branch_orphan_blind() {
  sed -i 's@^    die "the branch@    : "the branch@' "$1"
}

mut_RUN_branch_option_name() {
  sed -i 's@^    -\*) die "the branch@    -x-that-never-matches*) die "the branch@' "$1"
}

# `sdd retry` goes back to being the silent door: the function still exists, still warns for the
# other three, and this one call site simply is not there — which is the exact state the kit lived
# in until this increment. Nothing on screen changes except the missing line, and the phase gets
# redone and committed into whatever branch the human was standing on.
#
# The ONE deliberate exception to "sabotage the definition, never the call site" in this catalogue.
# The defect this increment closes IS an absent call site, and mut_RUN_base_branch_warn_dead
# already empties the definition — so a second sabotage of the body would measure the same thing
# twice and this door would keep its own coverage from a neighbour's entry. What has to die is the
# `retry ` pair in check-gates.sh, and only the pair: the three other doors stay warning, so every
# assertion about them stays green and the score credits this entry for nothing but the fourth.
#
# The sed is ADDRESSED to cmd_retry's body rather than anchored on the bare call, because after
# this increment the line `  warn_if_on_base_branch` appears four times and an unaddressed
# substitution would gut all four at once. The range ends at the first column-zero `}`, which is
# cmd_retry's own closing brace — every line of the body is indented.
mut_RETRY_base_branch_warn_dead() {
  sed -i '/^cmd_retry() {/,/^}/ s@^  warn_if_on_base_branch$@@' "$1"
}

# `sdd approve` goes back to being the silent fifth door: it still prints the plan, still asks, and
# still commits — into whatever branch the human is standing on, saying nothing. The state the kit
# shipped in between increment I1, which created this door, and the fix that closed it; sdd-qa
# walked it and found a `chore(missao)` commit dropped into the base branch without a word.
#
# The THIRD deliberate exception to "sabotage the definition, never the call site", and the same one
# mut_RETRY_base_branch_warn_dead declares: the defect this increment closes IS an absent call site,
# and mut_RUN_base_branch_warn_dead already empties the body for every door at once. A second
# sabotage of the definition would measure that entry's ground a third time and leave this door
# borrowing its coverage from a neighbour. What has to die is the `approve warns` pair and only it —
# the other four keep warning, so every assertion about them stays green.
#
# ADDRESSED to cmd_approve's body: after this fix the line `  warn_if_on_base_branch` appears five
# times, and an unaddressed substitution would gut all five while wearing this entry's name. The
# range ends at the first column-zero `}`, which is cmd_approve's own — every line of the body is
# indented, including the awk program and the two `-m` arguments of the commit.
mut_APPROVE_base_branch_warn_dead() {
  sed -i '/^cmd_approve() {/,/^}/ s@^  warn_if_on_base_branch$@@' "$1"
}

# The ORDER of the two guards in cmd_run, not their presence. Both calls stay — the warning simply
# moves ahead of the checkout, which is the shape a future editor arrives at honestly, following the
# "ahead of anything that could scroll it away" rule the other four doors state. What it produces is
# a human told the pipeline will commit into the base branch by a runner that moves them off it one
# line later. `cmd_retry` has had this entry since it was written; cmd_run went without, and the gap
# was measured (the swap left the whole suite green) by the REVIEW round of 20260816-portas-do-humano.
#
# Range-addressed to cmd_run: `ensure_mission_branch` now appears twice in the file and
# `warn_if_on_base_branch` five times, so an unaddressed sed would credit this entry for breaking
# somebody else's call site.
mut_RUN_branch_order_swap() {
  sed -i '/^cmd_run() {/,/^}/ {
    /^  ensure_mission_branch$/d
    s/^  warn_if_on_base_branch$/  warn_if_on_base_branch\n  ensure_mission_branch/
  }' "$1"
}

# frontmatter_write stops being scoped to the frontmatter block and rewrites the first line shaped
# like the key ANYWHERE in the file. A mission body legitimately quotes its own frontmatter — this
# repo's own 00-missao.md does — so the mutant silently rewrites committed prose. Sabotaging the
# DEFINITION and not a call site: there is one caller today, and the property belongs to the writer.
mut_FRONTMATTER_write_unscoped() {
  sed -i 's/^    inside && !written {$/    !written {/' "$1"
}

# Not a gate: `--all-repos` keeps working EVERYWHERE except in the one line the agent is handed.
# The gate reads its series in-process under the flag, the prompt tells the agent to run the bare
# `--series`, and the two halves land on different `latest` shas — so no `kit_sha_judged:` the
# agent can write is the one the gate hunts for. Nothing is malformed and no number is wrong: the
# PHASE is unsatisfiable, the runner retries once, and `BLOCKED in KAIZEN — no-progress` buys a
# blocked row with two opus sessions (BUG-1, sdd-qa, mission 20260817-eixo-do-juiz).
#
# It sabotages the propagation and NOT the setters: `AUTONOMY_all_repos_ignored` already welds the
# setters shut, and a mutant that killed those again would score the same point twice while leaving
# this half unmeasured. Killing only `ledger_flags` keeps the gate's reading flagged and the
# prompt's bare — which is precisely the split, and precisely what the differential pair in
# check-kaizen.sh reads. The control half of that pair (no flag ⇒ both bare) stays green here, as
# it must: a "fix" that hardcoded the flag into the prompt is the mutant this one does not cover.
mut_KAIZEN_prompt_series_unflagged() {
  sed -i 's@ledger_flags=" --all-repos"@ledger_flags=""@' "$1"
}

# The ratchet of `sdd health` stops being a ratchet and becomes a one-way gate: a NEW finding
# still fails, a baseline line that stopped being a finding no longer does. The debt list turns
# into folklore — it can only grow, and every line anyone ever pays off stays in the file
# describing a world that no longer exists. Nothing breaks, nothing is malformed, and the command
# still prints a green "ratchet: N known debt(s)"; the number is simply about nothing.
#
# Caught by tests/check-health.sh, which until this mission had no ancestor: cmd_health was the
# only command of the runner no sensor ran. It kills assertion 2 (the stale line) and assertion 3
# (the differential) and leaves assertion 1 alive — and that PAIR is the point. A one-way ratchet
# that still refused the other direction with the same sentence would satisfy assertions 1 and 2
# while distinguishing nothing; the survivor is what proves the differential measures.
#
# Anchored on the herestring of the second loop, which is the only thing that tells the two loops
# apart: they are the same three lines otherwise, and the first reads `<<< "$known"`.
#
# The `@` delimiter is not a taste: with sed's usual `|`, the substitution opens with the literal
# text `s|grep -q`, and tests/check-pipefail.sh reads that as a writer piped into `grep -q` — the
# SIGPIPE bug it exists to forbid. It was right to: a human reading `|grep -q` sees a pipe too.
# The two guards the r2 review of 20260818-lote-facil added to the family the mission thought it
# had closed. `sdd health` runs under `set -euo pipefail`, so a capture whose command reports
# non-zero — and for grep, "no match" IS non-zero — kills the runner AT THE ASSIGNMENT, leaving
# every health_bad below it as dead code. The mission fixed five sites one at a time; eleven more
# were still live, three of them reproduced end to end. Both mutants below are caught by the
# `guard:` rule of check-health.sh, which censuses the whole region instead of probing one site.
#
# ⚠️ Both carry a RANGE ADDRESS and neither may lose it: `| sort -u || true)"` occurs three times
# in cmd_health alone, so an unaddressed `sed` would sabotage two extra sites in silence — the
# defect this same review round found twice in the pre-existing catalogue.
mut_HEALTH_gates_capture_aborts() {
  sed -i '/# --- 4. every gate has a mutation/,/# --- 5. drift load_config/ s@| sort -u || true)"@| sort -u)"@' "$1"
}

# The provenance line read, which is the site where the silence cost the most: `-f "$tpl"` proves
# the file is there and nothing about the LINE, so a skill that renamed the field it pins killed
# the run in exactly the case health_provenance exists to report.
mut_HEALTH_provenance_line_aborts() {
  sed -i '/# qa-execution report: the Status line/,/# registry bug: the Status line/ s@"\$tpl" || true)"@"$tpl")"@' "$1"
}

mut_HEALTH_ratchet_one_way() {
  sed -i 's@grep -qxF "\$line" <<< "\$HEALTH_FINDINGS"@true@' "$1"
}

# The blind exemption removed: a check that declared itself unable to measure has its baseline line
# judged anyway, and the ratchet tells the operator to DELETE the backlog ratchet's only anchor.
# Destructive advice out of a measurement that did not happen — worse than saying nothing, which is
# why it is a mutant and not a comment. Caught by "a baseline line whose producer went blind is not
# called stale" in check-health.sh.
mut_HEALTH_stale_judges_the_blind() {
  sed -i 's@if grep -qxF "${line%% \*}" <<< "$HEALTH_BLIND"; then@if false; then@' "$1"
}

# The grade-table criteria loop passes by never iterating: with the skill's heading renamed the
# `while` runs zero times, `missing` stays empty, `checked` goes up, and the summary announces
# `all 3 fixtures match` about a table it never read. The exact drift health_provenance exists to
# catch, certified as absent by health_provenance itself.
mut_HEALTH_provenance_empty_table() {
  sed -i 's@if \[ "$n_crit" -eq 0 \]; then@if false; then@' "$1"
}

# Fixture provenance always agrees. `sdd health` goes on reporting "provenance: N fixture(s) match
# the installed skills" while comparing nothing — which is the exact shape of the most expensive
# bug in the kit's history, now inside the instrument built to catch it. A fixture written from
# memory agrees with the wrong gate forever, and this check is the only thing that ever notices.
#
# It sabotages the COMPARISON and not the skill lookup: a mutant that hid the template would be
# SKIPPED by design (missing skill ⇒ skipped, like the absent linter), so it would fail nothing
# and score a point for a door that was never open.
# ⚠️ ADDRESSED BY RANGE, and the range is the whole point. `if [ "$line" = "$fix" ]; then checked`
# is byte for byte the same line in the qa-execution branch and in the qa-report one, so a bare
# `sed` sabotages BOTH and this single entry silently becomes two — the "one mutation, one line"
# discipline of this file broken, and, worse, a dedicated entry for the qa-execution comparison
# made impossible to ever score, because this one would already be killing it. Caught in the r1
# review of 20260817-catraca-do-backlog. The two entries below are the other two comparisons,
# which used to be an open TODO.md finding for exactly this reason: no fixture installed the skills
# they read, so neither could honestly carry a mutation. Now that both have one, the range here
# earns its keep three times over.
mut_HEALTH_provenance_blind() {
  sed -i '/# registry bug: the Status line/,/# codereview grade table/ s|    if \[ -n "\$line" \] && \[ "\$line" = "\$fix" \]; then checked|    if true; then checked|' "$1"
}

# The FIRST of the three comparisons goes blind: the qa-execution report fixture agrees with any
# template the skill ships. Range-addressed for the same reason as the entry above and against the
# same byte-identical line — this one takes the half BEFORE the qa-report branch.
#
# Caught by the `covered:` assertion of check-health.sh and by nothing else, measured one mutant at
# a time: assertion 4 reads the qa-report comparison, which this leaves untouched, and every other
# assertion in that file runs with no skill installed at all.
mut_HEALTH_report_provenance_blind() {
  sed -i '/# qa-execution report: the Status line/,/# registry bug: the Status line/ s|    if \[ -n "\$line" \] && \[ "\$line" = "\$fix" \]; then checked|    if true; then checked|' "$1"
}

# The THIRD comparison goes blind: the codereview grade table may grow a criterion the gate fixture
# never covers and `sdd health` says nothing. It is not a `$line = $fix` twin — it is a loop that
# collects the uncovered criteria and then judges — so it needs its own sabotage, and the verdict
# is where it goes: the loop keeps running and the finding is simply never spoken. Left as an `if`
# with both branches whole, so the `else` that counts the fixture as checked still runs and the
# mutant reports "provenance: 1 fixture(s) checked" exactly like a healthy kit.
mut_HEALTH_grade_table_blind() {
  sed -i 's@    elif \[ -n "$missing" \]; then@    elif false; then@' "$1"
}

# The backlog ratchet goes blind: `sdd health` still runs the whole TODO.md check, still refuses a
# suite that prints no count — and then records nothing. The debt is free to grow in silence
# again, which is the entire defect the mission that added this check exists to close.
#
# ⚠️ It is caught by the STALE-BASELINE half of the ratchet, not by the new-finding half, and that
# is correct: with nothing emitted there is no finding to be outside the baseline — it is the
# baseline's own line that loses its pair. Written down because the shape invites a future session
# to "fix" the mutation, believing it aims at the wrong branch. Concretely: assertion 6 of
# check-health.sh builds a baseline carrying a wrong count on purpose and demands BOTH sentences
# out of that one world, so the mutant satisfies half a conjunction and fails it.
#
# The line is replaced, never deleted: it is the whole body of an `else`, and an `else` with no
# body is a syntax error — the mutant would die of bash, scoring a point for a door never opened.
mut_HEALTH_todo_count_blind() {
  sed -i 's@^    health_finding "todo-findings .*@    true@' "$1"
}

# ─── the five silent aborts of cmd_health ─────────────────────────────────────────────────────
# One family, five entries, and the split is deliberate: each restores ONE site to the bare form
# that used to be there, so the score stops crediting one guard for the other four. They are the
# cheapest mutants in the catalogue to write and the ones that would hurt most to lose — every
# single one of them was a REAL defect measured against the real runner, not an invented one, and
# the shape they restore is the shape a future session writes by default.
#
# All five are range-addressed or anchored on the guard's own text, never on a line number: the
# bare form `x="$(cmd)"` is the most common line in this file, and an unaddressed sed would
# sabotage half the runner and score five points for one door.

# `sdd health` goes back to dying on the suite capture. A RED SUITE — the one case the command
# exists to report — prints the header, rc 1, and nothing else: `set -e` kills the assignment
# before health_bad can say a word, and checks 2 through 8 never run at all.
#
# ⚠️ Caught by the `abort: a red suite` assertion of check-health.sh and by NOTHING ELSE, because
# rc 1 is what a reporting health_bad returns too. Every other assertion in that file reads a
# green stub suite, so this mutant leaves them all alive — which is the point of the split.
mut_HEALTH_suite_capture_aborts() {
  sed -i '/^cmd_health() {/,/^}/ s@" || rc=$?@"; rc=$?@' "$1"
}

# The `score:` read goes back to killing the run when it matches nothing. The branch below it
# still carries the sentence "health went blind to the mutation" — it simply becomes unreachable,
# so the kit's mutation score can silently stop being printed and `sdd health` reports it as a
# crash instead of as the contract breach it is.
mut_HEALTH_score_read_aborts() {
  sed -i "s@grep -m1 '^score: ' <<< \"\$out\" || true@grep -m1 '^score: ' <<< \"\$out\"@" "$1"
}

# `sdd health` goes back to certifying a catalogue with a mutant ALIVE. The comparison loses its
# second operand, so `score: 103 caught, 0 known gap(s), of 104` — one assertion the suite does not
# have — walks straight into `ok`, exactly as the pre-mission form did, and the operator reads
# `kit healthy` over a hole.
#
# Not an invented defect: that line sat on main between PR #12 and #13, for days, because f6ecf73
# rotted the anchor of mut_HEALTH_grade_table_blind and every gate ran only the fast suite. Since
# 4c86712 the catalogue is opt-in and this command is its ONLY caller, so `ok` here is the entire
# verdict on the catalogue.
#
# Range-addressed to the body of cmd_health, per the header of the five above: `[ "$caught" -ne
# "$total" ]` is a shape this file would rather not chase across the whole runner.
# Caught by `mutation: a score whose caught differs from total is refused` in check-health.sh and
# by nothing else — every other world in that file reads a stub score whose two numbers agree.
mut_HEALTH_mutation_survivor_blind() {
  sed -i '/^cmd_health() {/,/^}/ s@elif \[ "$caught" -ne "$total" \]; then@elif [ "$caught" -ne "$caught" ]; then@' "$1"
}

# `sdd health` goes back to certifying a catalogue that ran NOTHING. With the size comparison gone,
# `score: 0 caught, 0 known gap(s), of 0` satisfies everything left — no gap, and `caught == of` —
# so an empty `CATALOG=()` reaches `ok`, sets catalogue_green, WRITES THE STAMP, and opens gate_PR
# over a loop that ran zero times. A catalogue merely narrowed does the same, one entry at a time.
#
# The sabotage is a condition that is false for every score a catalogue can print, and NOT the
# deletion of the branch: what has to be measured is the comparison, not the presence of an `if`.
# Range-addressed to the body of cmd_health for the reason the mutant above gives.
# Caught by `mutation: a catalogue too small to have measured anything is refused` in
# check-health.sh, and by nothing else — every other world there reads a score whose size the
# fixture's own tests/check-mutation.sh backs.
mut_HEALTH_catalogue_floor_blind() {
  sed -i '/^cmd_health() {/,/^}/ s@if \[ "$total" -ne "$defined" \] || \[ "$defined" -lt "$MUTATION_CATALOGUE_FLOOR" \]; then@if [ "$total" -lt 0 ]; then@' "$1"
}

# `sdd health` stops asking the suite for the catalogue — and since the catalogue left TEST_CMD,
# health is the ONLY caller that asks. Nobody else runs it; there is no CI in this repo.
#
# The expensive part is how quietly it fails. health still prints `suite green`, still finds no
# `score:` line, and still says `health went blind to the mutation` — a sentence that reads as an
# accusation against check-mutation.sh for a defect living in this very line. An operator would go
# looking in the wrong file while the whole catalogue sat unrun.
#
# Caught by `surface: cmd_health asks the suite for the mutation catalogue` in check-health.sh,
# which reads the argv the stub suite RECORDED rather than the text of this call.
# ⚠️ `2>\&1` and not `2>&1`: an unescaped `&` in a sed REPLACEMENT means "the whole match", so the
# naive form expands to `2>tests/run-all.sh --with-mutation 2>&11` — still valid bash, so `bash -n`
# passes it and the harness accepts the mutant. It killed the assertion, but as garbage killing ten
# of them, not as this defect killing one. Red for the wrong reason is the one verdict this
# catalogue may never take: it certifies an assertion that was never the thing measuring.
mut_HEALTH_suite_without_mutation() {
  sed -i 's@tests/run-all.sh --with-mutation 2>\&1@tests/run-all.sh 2>\&1@' "$1"
}

# Provenance goes back to dying on a machine that has no plugins cache. `find` on a missing
# directory returns 1, pipefail carries it, and the assignment takes the runner down three ok
# lines in — no provenance, no ratchet, no verdict. Not a hypothetical machine: any box where the
# codereview plugin was never installed.
# `sdd health` goes blind to a TEST_CMD that only LISTS the suite. `tests/run-all.sh --list` exits
# 0 having executed nothing — correct for the mode, fatal as TEST_CMD: gate_EXEC, gate_QA and
# gate_REVIEW would each pass instantly, in every mission, against a run that never happened, and
# the log left behind is a dozen plausible step names. Health is where that gets said, because
# nothing else in the kit reads TEST_CMD as anything but a command to obey.
#
# The pattern is degraded rather than deleted, and the `case` is left with the same arms: a mutant
# that removed the branch outright would also remove the `ok` line, and half the assertions in
# check-health.sh would go red for a missing sentence instead of for the blindness.
#
# Range-addressed to the body of cmd_health, per the header of the entries above. Caught by
# `surface: --list prints steps only, and a TEST_CMD carrying it is refused` in check-health.sh —
# by its (b) half, whose two worlds differ in exactly this flag.
mut_HEALTH_testcmd_list_blind() {
  sed -i '/^cmd_health() {/,/^}/ s@\*" --list "\*)@*" --a-flag-no-config-carries "*)@' "$1"
}

mut_HEALTH_provenance_find_aborts() {
  sed -i 's@ | sort -V | tail -1 || true)"@ | sort -V | tail -1)"@' "$1"
}

# The ratchet goes back to dying on a baseline with no live line. An empty baseline is not an
# error — it means nothing is known debt, so everything is new — but the bare form made it a
# silent crash after the provenance line, saying neither `kit healthy` nor how many checks failed.
mut_HEALTH_baseline_read_aborts() {
  sed -i '/^health_ratchet() {/,/^}/ s@ || true)"@)"@' "$1"
}

# The SAME silence one call frame up, and the reason this is a fifth entry and not part of the one
# above: the site is not a capture at all. As an `&&` chain the last statement returns the status
# of its first failing test, so a ratchet that FOUND something returns 1 — and `set -e` kills
# cmd_health on the call, one line before its own `N check(s) failed`. It eats the verdict on the
# path that WORKS, and every assertion that reads only `rc != 0` stays green through it, since
# cmd_health's own `return 1` would have produced the same rc.
#
# TWO substitutions and not one, because the `fi` has to go with the `if`: left behind it is a
# syntax error, the mutant dies of bash (rc 91) and the harness scores a point for a door that was
# never opened. Deleted rather than replaced with a `true` — a `true` at the end of the function
# would pin the return status to 0 and quietly UNDO the very defect this entry exists to restore.
mut_HEALTH_ratchet_eats_verdict() {
  sed -i '/^health_ratchet() {/,/^}/ {
      s@^  if \[ "$new_findings" -eq 0 \] && \[ "$stale" -eq 0 \]; then@  [ "$new_findings" -eq 0 ] \&\& [ "$stale" -eq 0 ] \&\&@
      /^  fi$/d
    }' "$1"
}

# `sdd retry` loses the checkout and goes back to committing wherever the human happens to stand.
# ONE definition, two call sites: `mut_RUN_branch_switch_dead` above sabotages the FIELD READ inside
# ensure_mission_branch, so it kills the function for both doors at once and can never say which of
# the two still calls it. This one leaves the function whole and removes the CALL — the shape a
# refactor arrives at honestly — so the score stops crediting cmd_run's coverage to cmd_retry.
#
# Range-addressed to cmd_retry: the line is byte-identical in cmd_run, and an unaddressed `d` would
# delete both, sabotaging the door this entry is not about.
mut_RETRY_branch_switch_dead() {
  sed -i '/^cmd_retry() {/,/^}/ { /^  ensure_mission_branch$/d }' "$1"
}

# The ghost UUID comes back (the bug fixed in `032c09c`): an in-loop retry runs with `--resume …
# --fork-session` and WITHOUT `--session-id`, so the `$sid` generated at the top of the call was
# never handed to claude — recording it leaves the retry row pointing at a session that identifies
# nothing, and neither reader can tie the retry back to the session it forked from.
#
# The DRY-RUN copy of the same assignment is left ALONE — it carries four leading spaces and this
# one two — so a mutant cannot break the projection and the ledger at once, and this entry is
# credited for the recorded id and nothing else.
mut_RUN_ghost_session_id() {
  sed -i 's|^  LAST_PHASE_SID="${resume_sid:-$sid}"$|  LAST_PHASE_SID="$sid"|' "$1"
}

# `sdd retry` stops measuring whether its session changed the disk. `mut_RUN_moved_never_true` above
# anchors on the FOUR-space copy inside cmd_run's loop; cmd_retry and cmd_kaizen carry their own at
# two spaces, and the retry's was uncovered — measured, not assumed: the RUN_ sabotage leaves
# "sdd retry that changed the disk records moved:true" green. Waste is defined as sessions that did
# NOT move the disk, so a retry stuck on `moved:false` files every redone phase as waste and feeds
# the judge a mission that never progressed.
#
# Range-addressed to cmd_retry: the two-space form is byte-identical in cmd_kaizen.
mut_RETRY_moved_never_true() {
  sed -i '/^cmd_retry() {/,/^}/ { s|^  \[ "$before" != "$after" \] && moved="true"$|  true| }' "$1"
}

# The THIRD copy of the same line, and the last one that had no mutation: `sdd kaizen` stops
# measuring whether the judge's session changed the disk. Same argument as the retry entry above,
# with one extra edge — the kaizen row is the ONLY session row a kit repo writes about itself, so a
# judge stuck on moved:false teaches the next verdict that its own loop never progresses.
#
# Range-addressed to cmd_kaizen: the two-space form is byte-identical in cmd_retry, and an
# unaddressed sed would sabotage both doors and credit this entry for the other's coverage.
mut_KAIZEN_moved_never_true() {
  sed -i '/^cmd_kaizen() {/,/^}/ { s|^  \[ "$before" != "$after" \] && moved="true"$|  true| }' "$1"
}

# The post-pipeline nudge goes silent: missions pile up on a kit sha nobody judged and `sdd run`
# stops saying so, which is how the kaizen loop stalls without anybody noticing it stalled. Every
# OTHER assertion about the reminder asserts its ABSENCE (empty ledger, verdict already on disk), so
# the whole family stays green with the reminder deleted — a set of assertions that can only pass.
# The `dim` becomes a `:` carrying the same string, so the computation above it still runs and a
# reader still sees a line here.
mut_KAIZEN_reminder_dead() {
  sed -i 's|^  dim "  autonomy series: |  : "  autonomy series: |' "$1"
}

# `sdd kaizen` stops being idempotent: with the verdict already on disk the gate passes, the outcome
# is repeated — and then the command falls THROUGH and opens a session anyway. Re-running it to
# re-read a verdict is the ordinary human move, and it would quietly cost an opus session every
# time, on a judge with nothing new to judge.
#
# Range-addressed from the gate call: `return "$out_rc"` appears six times inside cmd_kaizen, so an
# unaddressed sed would collapse every bailout of the command into this one mutant and the entry
# would be credited for whichever of them the suite noticed first. The `return` is REPLACED by a `:`
# carrying the same expansion, never deleted: the branch stays syntactically whole and what dies is
# the early exit alone.
mut_KAIZEN_already_judged_spends() {
  sed -i '/^  gate_KAIZEN || gate_rc=\$?$/,+4 { s|^    return "$out_rc"$|    : "$out_rc"| }' "$1"
}

# The other half of the pair `mut_RUN_degraded_row_dropped` opens: the runner lowering its own bar
# still reaches the judge's ledger and disappears from the HUMAN's trail. `pipeline.log` is where a
# human reconstructs what a headless run did, and a REVIEW that ended in a draft PR would read there
# as a phase that simply stopped. The `continue` bug the pair closes skipped BOTH writers, so each
# needs its own sabotage or one of them is credited for the other's coverage.
mut_RUN_degraded_journal_dropped() {
  sed -i 's|^          pipeline_log_line "$(date -Iseconds)  DEGRADED  |          : "$(date -Iseconds)  DEGRADED  |' "$1"
}

# `cmd_autonomy`'s own `is_escalation` forgets `degraded`, so the human reader files a row the runner
# itself wrote under "unrecognized" while the judge goes on counting it — two instruments over ONE
# file reporting different escalation counts for the same period, with nothing on screen explaining
# the divergence. That is the exact failure the single-definition rule was written for, reappearing
# inside one of the definitions it created.
#
# Range-addressed to cmd_autonomy: kaizen_series holds a byte-identical definition, and three
# neighbours have to stay distinguishable from this one — `mut_RUN_escalations_no_axis` (the axis of
# the same table), `mut_RUN_degraded_label_blind` (kaizen_series' phase_label) and
# `mut_KAIZEN_series_escalations_dropped` below (kaizen_series' admission filter).
mut_AUTONOMY_is_escalation_blind() {
  sed -i '/^cmd_autonomy() {/,/^}/ { s|^    def is_escalation: .event == "blocked" or .event == "degraded";$|    def is_escalation: .event == "blocked";| }' "$1"
}

# The series stops ADMITTING escalations: `blocked` and `degraded` rows fall out of `$all`, so every
# event saying a mission stopped or the runner lowered its bar leaves the judge's numbers — and lands
# in the unrecognized bucket instead, a count that reads "the ledger is corrupt" about rows the
# runner wrote correctly.
#
# It sabotages the ADMISSION and not the definition, which is what keeps it apart from
# `mut_AUTONOMY_is_escalation_blind` above (the reader's predicate) and `mut_RUN_degraded_label_blind`
# (phase_label's use of this same program's predicate): each of the three stays caught with the other
# two intact, and each names a different consumer of the escalation pair.
mut_KAIZEN_series_escalations_dropped() {
  sed -i 's|^                         and (.event == "session" or is_escalation)))) as $all$|                         and (.event == "session")))) as $all|' "$1"
}

# The blocked line goes back to counting LAPS OF THE LOOP and calling them sessions. `attempts`
# rises on the lap that escalates — which opens no session at all — and on every later lap the
# REVIEW->PR->REVIEW degradation takes, so the last line a human reads when a run ends said
# `3 sessions` over a ledger holding one REVIEW session.
#
# It restores the historical defect exactly, rather than emptying the counter: a mutant that merely
# stopped feeding `sessions` would print `0` and be caught by arithmetic, where this one prints a
# plausible number that is simply about something else — the shape the assertion has to survive.
mut_RUN_blocked_counts_laps() {
  sed -i 's@${sessions\[$phase\]:-0} session(s) without satisfying@${attempts[$phase]} session(s) without satisfying@' "$1"
}

# The exclusion accounting goes back to one blank line between every two of its lines: a paragraph
# about where the rows went, printed as four unrelated asides. Anchored on the `join` of the array
# that collects them — the token that only exists because the four strings are ONE output now.
#
# The leading newline is left ALONE and only the separator doubles, so the blank that divides the
# block from the table survives: the mutant reproduces the defect and nothing else, and an
# assertion that passed on "there is a blank line somewhere" would not notice it.
mut_AUTONOMY_exclusions_split() {
  sed -i 's@\] | select(length > 0) | "\\n" + join("\\n"))@] | select(length > 0) | "\\n" + join("\\n\\n"))@' "$1"
}

# The one voice of the guard floor a human reads out loud writes its own copy of the number again,
# under the comment that swears it does not. Nothing breaks and no count moves — the sentence goes
# on being true until the floor changes, and then it is the only reader still saying the old value.
#
# The `$floor` in the anchor is what keeps it honest: it is the interpolation itself, so the mutant
# cannot apply to a runner that never derived the number, and `cmp` reports "did not apply" instead
# of scoring a point for sabotaging prose.
mut_KAIZEN_axis_note_own_floor() {
  sed -i 's@The floor of $floor missions per kit version@The floor of 3 missions per kit version@' "$1"
}

# The exclusion paragraph loses the blank line that divides it from the TABLE and is printed glued
# to the last version row — the opposite over-correction to `mut_AUTONOMY_exclusions_split` above,
# and the one a hand fixing that defect reaches for first (delete every newline and the blanks
# between the lines go away too).
#
# It exists because that half of the claim has no other catcher: the split mutant leaves the
# leading newline alone, and D5 next door counts CONSECUTIVE blanks, so an accounting welded onto
# the table satisfies it. Without this entry the "one blank above" term would be a rule with no
# probe — decoration, by this repo's own rubric.
mut_AUTONOMY_exclusions_glued() {
  sed -i 's@\] | select(length > 0) | "\\n" + join("\\n"))@] | select(length > 0) | join("\\n"))@' "$1"
}

# The series stops PUBLISHING the floor, so `.guard.floor` reads null and the sentence the human
# hears has nothing left to quote. It is the other half of `mut_KAIZEN_axis_note_own_floor`: that
# one puts a second copy of the number back, this one removes the first — either way the floor stops
# having exactly one owner with exactly one voice.
#
# Caught twice on purpose, and that is not a duplicate point: check-kaizen.sh compares the guard KEY
# SETS of the two producers (the jq program and the empty-ledger printf), so this mutation also
# proves the empty series never silently drifts out of step with the real one.
mut_KAIZEN_guard_floor_unpublished() {
  sed -i '/^               floor: guard_floor,$/d' "$1"
}

CATALOG=(
  PLAN_empty_approval
  PLAN_kaizen_born_blind
  PLAN_remedy_unnamed
  TICKET_no_sprint
  EXEC_done_without_commit
  EXEC_orphan_commit
  EXEC_ignores_TEST_CMD
  QA_status_line_start
  QA_status_enum_loose
  QA_bug_enum_loose
  QA_matrix_pending
  QA_bug_open
  REVIEW_stops_at_h3
  REVIEW_accepts_B
  REVIEW_placeholder_rationale_blind
  REVIEW_gate_field_blind
  DOCS_pending_status
  PR_no_artifact
  PR_stamp_blind
  HEALTH_stamp_window_blind
  HEALTH_stamp_tree_blind
  RUN_inverted_journal
  RUN_ignores_output_lang
  RUN_autonomy_ignores_dry_run
  RUN_autonomy_null_moved_as_zero
  RUN_moved_never_true
  RUN_autonomy_sha_warn_repeats
  RUN_jidoka_pipefail
  RUN_degraded_row_dropped
  RUN_degraded_repeats
  RUN_escalations_no_axis
  RUN_degraded_label_blind
  RUN_sort_lexi
  RUN_install_no_guard
  RUN_on_axis_forked
  KAIZEN_gate_blind
  KAIZEN_jidoka_dead
  KAIZEN_guard_ignored
  KAIZEN_approved_bailout_dead
  RUN_refez_dropped
  RUN_guard_counts_escalations
  RUN_degraded_spins
  RUN_stream_no_verbose
  RUN_stream_summary_unfiltered
  RUN_stream_summary_fatal
  RUN_cost_absent_unlabelled
  RUN_cost_empty_unlabelled
  RUN_max_phases_ignored
  RUN_progress_eats_rc
  RUN_progress_dead
  RUN_entrypoint_unguarded
  RUN_ledger_no_repo_filter
  PRE_agent_presence_only
  RUN_base_branch_warn_dead
  RUN_approve_writes_auto
  RUN_approve_bails_on_kaizen_born
  RUN_approve_no_plan_blind
  RUN_branch_switch_dead
  RUN_branch_option_name
  RUN_branch_orphan_blind
  RETRY_base_branch_warn_dead
  APPROVE_base_branch_warn_dead
  RUN_branch_order_swap
  FRONTMATTER_write_unscoped
  KAIZEN_adr_0003_orphan
  KAIZEN_degenerate_axis_blind
  AUTONOMY_all_repos_ignored
  LEDGER_repo_root_shape_blind
  LEDGER_repo_root_toplevel
  LEDGER_no_repo_counted_as_local
  KAIZEN_prompt_series_unflagged
  KAIZEN_degenerate_axis_all_history
  KAIZEN_mission_key_slug_only
  LEDGER_repo_root_common_parent
  LEDGER_repo_root_cdpath_leak
  LEDGER_bare_by_entry_point
  KAIZEN_degenerate_axis_reach_blind
  KAIZEN_degenerate_axis_session_unit
  KAIZEN_degenerate_axis_window_sorted
  KAIZEN_series_rc_dropped
  HEALTH_gates_capture_aborts
  HEALTH_provenance_line_aborts
  HEALTH_ratchet_one_way
  HEALTH_stale_judges_the_blind
  HEALTH_provenance_empty_table
  HEALTH_provenance_blind
  HEALTH_report_provenance_blind
  HEALTH_grade_table_blind
  HEALTH_todo_count_blind
  HEALTH_suite_capture_aborts
  HEALTH_score_read_aborts
  HEALTH_mutation_survivor_blind
  HEALTH_catalogue_floor_blind
  HEALTH_testcmd_list_blind
  HEALTH_suite_without_mutation
  HEALTH_provenance_find_aborts
  HEALTH_baseline_read_aborts
  HEALTH_ratchet_eats_verdict
  RETRY_branch_switch_dead
  RUN_ghost_session_id
  RETRY_moved_never_true
  KAIZEN_moved_never_true
  KAIZEN_reminder_dead
  KAIZEN_already_judged_spends
  RUN_degraded_journal_dropped
  AUTONOMY_is_escalation_blind
  KAIZEN_series_escalations_dropped
  RUN_blocked_counts_laps
  AUTONOMY_exclusions_split
  AUTONOMY_exclusions_glued
  KAIZEN_axis_note_own_floor
  KAIZEN_guard_floor_unpublished
)

# Mutations that are NOT caught today, each with the increment that closes it. Ratchet in both
# directions: an uncaught one outside the list fails, and a listed gap that STARTED being caught
# fails too (the list has to shrink, never become a permanent excuse).
KNOWN_GAPS=()

# ---------------------------------------------------------------------------
pass()  { printf '  ok    %s\n' "$1"; }
fail()  { printf '  FAIL  %s\n         %s\n' "$1" "$2" >&2; }

in_gap_list() { # in_gap_list <slug>
  local x
  for x in ${KNOWN_GAPS[@]+"${KNOWN_GAPS[@]}"}; do
    [ "$x" = "$1" ] && return 0
  done
  return 1
}

sandbox() { # sandbox <target-dir> — the whole kit the suite needs, and nothing more
  mkdir -p "$1"
  # `agents/` earned its place here the day check-preflight.sh started asserting that a drifted
  # .claude/agents/ copy fails: its fixture runs `sdd install`, and with no agents/ to install from
  # there is no copy to drift — the assertions would pass vacuously in every sandbox while the
  # control run stayed green. It is NOT copied for check-lang.sh, which reads it too but is guarded
  # out of the mutants; adding it here does not make that guard removable.
  cp -r "$ROOT/bin" "$ROOT/tests" "$ROOT/templates" "$ROOT/config" "$ROOT/agents" "$1/"
  # `CLAUDE.md` and `TODO.md` earned their place the day check-health.sh started demanding that the
  # backlog-ratchet policy be written in both: that rule resolves them from its OWN kit root, which
  # inside a sandbox is the sandbox. Absent, the rule has nowhere to live and REFUSES — correctly,
  # since "skip the document that is missing" is the fail-open this repo forbids — so the control
  # run went red and every mutant would have scored by vacuity. Measured, not feared: that is how
  # this line was born. Two files, and they keep the sandbox a faithful kit instead of making a
  # documentation rule optional.
  cp "$ROOT/CLAUDE.md" "$ROOT/TODO.md" "$1/"
  # `docs/adr` and NOT `docs`: check-kaizen.sh asserts the runner still names ADR 0003, and the
  # sabotage that strips the citation has to be able to kill it INSIDE a mutant. Three small files,
  # against a `docs/` tree whose handoffs are megabytes and which no sensor here reads — the
  # sensors that DO read the rest of docs/ (check-todo.sh, check-checkpoint.sh) are the ones
  # run-all.sh guards out under SDD_MUTANT, so this stays the whole kit the suite needs and nothing
  # more.
  mkdir -p "$1/docs"
  cp -r "$ROOT/docs/adr" "$1/docs/"
}

# run_mutant <slug> — writes $WORK/<slug>.rc and $WORK/<slug>.log
run_mutant() {
  # Two `local`s on purpose (SC2318): collapsed into one, the `$slug` on the right expands BEFORE
  # this line's own assignment lands, so it reads the caller's global — correct today only by the
  # coincidence that the loop variable happens to share the name. Rename the loop variable and
  # every mutant silently shares `$WORK/`, one box for all of them.
  local slug="$1"
  local box="$WORK/$slug"
  sandbox "$box"
  "mut_$slug" "$box/bin/sdd"
  if cmp -s "$ROOT/bin/sdd" "$box/bin/sdd"; then
    echo "the mutation did not apply — did the anchor change in bin/sdd?" > "$box.log"
    echo 90 > "$box.rc"; return
  fi
  if ! bash -n "$box/bin/sdd" 2>"$box.log"; then
    echo "the mutant is not valid bash" >> "$box.log"
    echo 91 > "$box.rc"; return
  fi
  SDD_MUTANT=1 "$box/tests/run-all.sh" > "$box.log" 2>&1
  echo $? > "$box.rc"
}

# ---------------------------------------------------------------------------
# CONTROL run — the copy has to be green with NO sabotage at all.
#
# Without it, a broken copy (a future test reading agents/ or docs/, for instance) would leave
# EVERY mutant red and the score would read 100% while measuring exactly nothing — the same
# vacuity the mutation exists to catch, now inside the measuring device itself.
# ---------------------------------------------------------------------------
echo "== control =="
sandbox "$WORK/control"
if SDD_MUTANT=1 "$WORK/control/tests/run-all.sh" > "$WORK/control.log" 2>&1; then
  pass "the kit copy is green with no sabotage"
else
  fail "HARNESS-BROKEN: the copy is not green even without sabotage" \
       "the score would read 100% by vacuity — see $WORK/control.log"
  tail -20 "$WORK/control.log" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# A pool, not batches: the old `[ i % JOBS -eq 0 ] && wait` was a barrier every JOBS mutants, so
# each batch cost its slowest member while the finished slots sat idle. `wait -n` frees a slot as
# soon as ANY mutant exits. Safe because run_mutant shares nothing — each writes its own
# $WORK/<slug>.rc/.log and the scoring loop below reads the catalogue in order afterwards.
# `wait -n` is bash 4.3+; without it, fall back to the barrier and SAY so — a declared
# degradation, never a silent one.
if (: & wait -n) 2>/dev/null; then
  echo "== mutants (pool of $JOBS) =="
  running=0
  for slug in "${CATALOG[@]}"; do
    run_mutant "$slug" &
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
  done
else
  echo "== mutants (batches of $JOBS — this bash has no 'wait -n', falling back to barriers) =="
  i=0
  for slug in "${CATALOG[@]}"; do
    run_mutant "$slug" &
    i=$((i + 1))
    [ $((i % JOBS)) -eq 0 ] && wait
  done
fi
wait

caught=0; gaps=0; errors=0
for slug in "${CATALOG[@]}"; do
  rc="$(cat "$WORK/$slug.rc" 2>/dev/null || echo 99)"
  case "$rc" in
    90|91)
      fail "CATALOGUE-BROKEN: $slug" "$(cat "$WORK/$slug.log")"; errors=$((errors + 1)) ;;
    0)
      # The suite stayed GREEN with the runner sabotaged: nobody measures this sabotage.
      if in_gap_list "$slug"; then
        printf '  warn  %s — known gap, the suite does not catch it (yet)\n' "$slug"
        gaps=$((gaps + 1))
      else
        fail "$slug is NOT caught" "the suite stayed green with the runner sabotaged — an assertion is missing"
        errors=$((errors + 1))
      fi ;;
    99)
      fail "$slug produced no result" "the mutant died before writing its rc"
      errors=$((errors + 1)) ;;
    *)
      if in_gap_list "$slug"; then
        fail "$slug is in KNOWN_GAPS but is ALREADY caught" \
             "gap closed — drop it from the list, or it becomes a permanent excuse"
        errors=$((errors + 1))
      else
        pass "$slug — the suite dies (rc $rc)"
        caught=$((caught + 1))
      fi ;;
  esac
done

echo
# `cmd_health` in bin/sdd greps this exact line. The two sides are one contract across two files:
# change the wording here and the health check goes blind, which is why it fails on a missing
# line instead of passing in silence.
printf 'score: %d caught, %d known gap(s), of %d\n' "$caught" "$gaps" "${#CATALOG[@]}"
if [ "$errors" -eq 0 ]; then exit 0; fi
printf '%d problem(s) in the catalogue\n' "$errors" >&2
exit 1
