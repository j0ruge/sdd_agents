#!/usr/bin/env bash
# Sensor for ADR traceability — `sdd adr new` allocates the id, `sdd adr check` reads the link.
#
# What it measures. The kit gained two verbs on 2026-09-17 because nothing anywhere allocated an
# ADR number: a note declared "ADR 0030" in prose on 2026-08-25 and the real `docs/adr/0030-…` of
# the pilot target was accepted for a different decision the next day. This file asserts that the
# allocator never hands the same number out twice and never overwrites a file, and that the check
# reads the link back in both directions instead of trusting the prose.
#
# Rules, each with a probe below:
#   R1  ADR_CHECK is admitted POSITIVELY — off|warn|block and nothing else, rc 2 on anything else
#   R2  ADR_DIR never degenerates to the root: it is substituted into the planner hat's `writes:`
#       glob, and a value of `/` expands `$ADR_DIR/**` to `/**` — a hat declaring it may write the
#       whole filesystem
#   R3  `sdd adr` with no verb prints the usage and exits 2 — never a silent no-op
#   R4  a legal mode names itself and counts what is on disk
#   R5  a mission with no `adr:` key, or an empty one, FAILS — absence is the defect in the scope
#       of the mission the kit is running right now, and information in every other scope
#   R6  `adr: none` passes: deciding nothing architectural is a decision, written down
#   R7  `adr: TBD` and the untouched template placeholder are the SAME state — information with no
#       `--phase`, a refusal with one. Read as two states, the mission that never touched the line
#       would pass the gate the written TBD fails
#   R8  a path is a path: the file name carries the id (NNNN-slug.md) and the file exists
#   R9  the ADR points BACK at the mission. One direction proves nothing — an `adr:` pointing at a
#       real file is satisfied by EVERY real file, which is exactly the vault note of 2026-08-25
#  R11  ADR_DIR holds one file per id, and every name reads as NNNN-slug.md
#  R12  the repo scope runs the FULL mission check on every mission that declares a path, and
#       COUNTS the ones that declare none — absence fails in the running mission and nowhere else,
#       or a check would be red on the day a repo installed the kit
#  R13  a SpecKit spec that declares an ADR gets the same two-way check, back-link included
#  R14  a bare `ADR NNNN` with no file is a FAILURE inside SPEC_DIR and a COUNT in a handoff
#  R15  SPEC_DIR empty scans NOTHING — it never falls back to the repo root
#  R16  an unfilled `sdd adr new` stub is counted
#  R17  an empty ADR_DIR allocates 0001, and a gap is NEVER reused — a reused number would point
#       an already-written citation at a different decision, the same defect inverted
#  R18  `--dry-run` prints the path and creates nothing
#  R19  a slug is lower-case letters, digits and hyphens
#  R20  `--spec` writes BOTH sides, in whichever of the two layouts the file is in, and ADDS the
#       `adr:` key when the mission has none — frontmatter_write() leaves an absent key absent by
#       design, so without this half every mission planned before the key existed would get one
#       side of the link and no complaint
#  R21  `--spec` REFUSES a spec that already declares a path: choosing between two ADRs is a human
#       decision, and silently overwriting the link would be the kit making it
#  R22  the reservation refuses an existing path and keeps its bytes (O_EXCL)
#  R23  under `block` an undecided `adr:` stalls at PLAN — and the reason NAMES `sdd adr new`
#  R24  `adr: none` derives EXEC: deciding nothing architectural is a decision, written down
#  R25  EXEC asks the one thing PLAN cannot — DRIFT. An ADR on disk when the human approved the
#       plan and gone now stops the line
#  R27  `warn` leaves exactly one `degraded` row of kind `adr-check` per run, written on the way
#       past the gate and BEFORE the session; `--dry-run` writes none, and `off` writes none
#  R26  off, warn and block are three states of ONE fixture, asserted differentially; and a bogus
#       ADR_CHECK refuses at the gate instead of quietly degrading to off
#  R10  both dialects are read by the same rule (`Spec:` here, `- **Spec**:` in the pilot target)
#
# Declared limits (D15 of CLAUDE.md — debt written is a limit, debt kept quiet is the fail-open):
#   - The pilot target keeps a LOCAL namespace at `specs/023/adr/001-…`, outside ADR_DIR. This
#     sensor does not see it and `sdd adr check` does not either. Unifying or declaring it is that
#     repo's decision, not the kit's.
#   - `docs/superpowers/{specs,plans}` of this repo are not laid out as `<SPEC_DIR>/*/spec.md`, so
#     the spec scan never reaches them. Recorded in KAIZEN_LOG.md.
#   - adr_mode also refuses an EMPTY ADR_DIR, and that arm has no probe. The world it guards could
#     not be built from the config: `load_config` defaults with `: "${ADR_DIR:=docs/adr}"`, and the
#     colon form fires on the empty value too, so a repo cannot reach the runner with ADR_DIR
#     unset. It stays because it decides WHICH failure a direct caller gets, and because the
#     spelling of that default is not this file's to change — `sdd health` extracts the key list
#     from exactly that regex. Which world went unbuilt is named here rather than claimed absent:
#     CLAUDE.md pays for the difference with a regression.
#   - There is NO `--check <file>` mode, and the absence is deliberate rather than owed. The
#     canonical selftest exists for sensors the mutation catalogue cannot reach: check-lang.sh and
#     check-pipefail.sh cannot scan themselves, and check-todo.sh, check-checkpoint.sh,
#     check-templates.sh and check-hat.sh measure MARKDOWN, so no sabotage of bin/sdd could make
#     them die. This one is the other case — it has no parser of its own; every assertion drives
#     `bin/sdd` as a subprocess, so the catalogue reaches it through the `mut_ADR_*` entries. What
#     a selftest would have bought is bought below by a PROBE FLOOR and a NEGATIVE CONTROL: the
#     assertion primitive is run against a world of known answer and required to say so, which is
#     what caught check-templates.sh certifying a zero-byte template with "23 assertion(s)".
#
# The adversarial sabotage pass (CLAUDE.md: a selftest green proves the rules that have probes).
# Every rule here was degraded to a looser version and the file required to go red:
#   R1 → accepting any non-empty ADR_CHECK: red (probe 1).
#   R1 → `case` written as `*) : ;;` with the refusal removed: red (probe 1).
#   R2 → dropping the ADR_DIR arm of adr_mode: red (probe 2).
#   R2 → widening the arm to `''|.` so it no longer names the root: red (probe 2).
#   R3 → `*) : ;;` on the verb: red (probe 3), and the rc is what catches it, not the text.
#   R4 → printing the mode without reading ADR_DIR: red (probe 4), which is also what keeps
#        `sdd health` check 7 (`var-never-read ADR_DIR`) honest in the same commit as the key.
#   R5 → the absent-key arm returning 0: red.
#   R7 → `TBD` falling into the `none` arm: red. → the `--phase` arm never firing: red.
#   R8 → the name pattern test replaced by `false`: red. → the `-f` test replaced by `false`: red.
#   R9 → the back-link comparison replaced by `false`: red. → the missing-`Spec:` arm never
#        firing: red. Both are also catalogue entries (mut_ADR_backlink_blind,
#        mut_ADR_number_mismatch_blind), which is what proves them from outside this file.
#  R10 → narrowing ADR_LINK_PRE to the bold dialect alone: red.
#  R11 → the duplicate-id arm replaced by `false`: red. → the name arm replaced by `false`: red.
#  R12 → the whole mission branch replaced by `:`: red — and it SURVIVED the first sweep, because
#        no probe drove a mission with a declared path through the repo scope. The probe that
#        closes it is the one naming 20260101-decl.
#  R13 → the spec's adr_check_link call replaced by `:`: red. → the no-ADR-line counter: red.
#  R14 → the handoff counter replaced by `:`: red. → `ADR [0-9]{4}` → `ADR NEVER` inside
#        adr_check_repo: red (also mut_ADR_bare_number_blind).
#  R15 → `[ -n "$SPEC_DIR" ]` replaced by `true`: red — and it SURVIVED the first sweep too, for a
#        reason worth writing down: the fixture kept its spec at `specs/001-thing/spec.md`, one
#        level below what the fallback `find "$root/" -mindepth 2 -maxdepth 2` reaches, so the
#        probe was asserting the shape of the fixture and not the presence of the guard. It plants
#        the spec at `thing/spec.md` now.
#  R16 → the stub counter replaced by `:`: red.
#  R17 → `max` taking every id instead of the largest: red. → the allocator always returning 1: red.
#  R18 → the `--dry-run` arm never firing: red.
#  R19 → the slug pattern widened to `.`: red.
#  R20 → `frontmatter_has` replaced by `true`, so the absent key is never inserted: red.
#        → adr_declare() returning early, so the SpecKit line is never written: red.
#  R21 → the already-declares arm never firing: red.
#  R22 → `( set -C; … )` replaced by a plain `>`: red (also mut_ADR_alloc_no_excl).
#  R23 → `adr_gate_verdict plan` replaced by `:`: red (also mut_PLAN_adr_check_ignored).
#        → `TBD|<*` moved off the arm so TBD lands in `none`: red (mut_PLAN_adr_tbd_accepted).
#        → GATE_WHY carrying no reason: red. → `$phase` not passed down: red.
#  R25 → `adr_gate_verdict exec` replaced by `:`: red (also mut_EXEC_adr_drift_blind).
#  R26 → warn behaving like block: red. → block behaving like warn: red. → a bogus mode degrading
#        to satisfied: red.
#  R27 → `autonomy_degraded_row "adr-check"` replaced by `:`: red (also mut_RUN_adr_warn_silent).
#        → `[ "$mode" != off ] || return 0` removed, so `off` arms the marker: red. That early
#        return had NO probe when it was written, and the gap was declared here until this
#        differential closed it — which is the discipline, not an accident.
#
# ⚠️ THREE rules in cmd_run survive every sabotage, and the honest thing is to name the world that
# could not be built rather than to claim it does not exist — CLAUDE.md paid for that difference
# with a regression (a DRY_RUN guard deleted as "unbreakable", restored in the review of the same
# PR). All three were MEASURED, not assumed, and all three decide WHICH failure a future defect
# produces, which is the D15 category that keeps a rule with its absence declared:
#
#   the one-shot `[ "$adr_degraded_logged" = 0 ]`. Removing it still writes exactly ONE row here,
#     because the EXEC pre-check is entered at most once per run in every world this fixture can
#     reach: under warn the row goes out, and the lap then either escalates on the spot or moves
#     on to QA. The world where it repeats is real — QA or REVIEW writes an F<n>/R<n> increment
#     and current_phase hands EXEC back — and it needs real sessions, which no probe here may
#     spend. That is the world I could not build. (Its sibling, degraded_logged for
#     review-to-draft, HAS a witness in check-autonomy.sh because REVIEW→PR→REVIEW re-enters.)
#   the `[ "$DRY_RUN" != "1" ]` guard. Measured: `sdd run --dry-run` over this same fixture never
#     reaches the site at all — 0 mentions of ADR_CHECK=warn in its output, 0 rows with the guard
#     and 0 without. It stays because the kit has already deleted one DRY_RUN guard on exactly
#     this reasoning and had to put it back.
#   `GATE_ADR_WARN_WHY=""` on entry. The marker is armed and read within ONE derivation of ONE
#     mission, so there is no second reader to inherit a stale value. It stays because a marker
#     that re-derives its contract instead of inheriting it is what CLAUDE.md demands of every new
#     one, and because the world where it matters is the same unreachable one as the one-shot: a
#     second EXEC lap whose mission became clean in between.
#   -- → the last line of adr_check_repo replaced by `return 0`: red — and it SURVIVED the first
#        sweep because cmd_adr read ADR_FAILS a second time. Two readers of one fact means either
#        one can be sabotaged while the other answers, and NEITHER is catchable; cmd_adr reads the
#        rc now, which is what makes that line load-bearing.
#   -- → adr_fail() no longer counting: red, and it has to be, or every rule above reports a
#        violation the command then exits 0 on.
#
# Usage: tests/check-adr.sh             (exit 0 = allocator and link check behave)
#        tests/check-adr.sh selftest    (the negative control alone; 90 = it did not go red)
set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
PROBES=0
fails=0

# Anti-vacuity. A file whose probes stop being dispatched prints exactly what a clean kit prints;
# the floor is what refuses that, and it is checked at the very bottom, after everything ran.
PROBE_FLOOR=53

pass() { PROBES=$((PROBES + 1)); printf '  ok    %s\n' "$1"; }
fail() { PROBES=$((PROBES + 1))
         printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }

# A fixture repo per probe, thrown away at exit. Its own SDD_STATE_DIR for the same reason
# check-gates.sh carries one: a standalone run does not inherit run-all.sh's export, and a fixture
# under $TMPDIR must never reach the real autonomy ledger.
BOX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-adr-XXXXXX")"
STATE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-adr-state-XXXXXX")"
export SDD_STATE_DIR="$STATE"
trap 'rm -rf "$BOX" "$STATE"' EXIT

# fixture <name> [config line]... — a git repo with the kit installed; prints its path.
#
# No test may spend tokens or reach the network. The stub on PATH makes that impossible by
# construction rather than by the assertion happening to escape before any session opens.
fixture() {
  local name="$1"; shift
  local d="$BOX/$name"
  mkdir -p "$d/.stub"
  cat > "$d/.stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
  chmod +x "$d/.stub/claude"
  ( cd "$d" \
      && git init -q -b main \
      && git config user.email "fixture@example.com" \
      && git config user.name "Fixture" \
      && echo content > file.txt \
      && git add -A && git commit -qm init \
      && "$SDD" install >/dev/null 2>&1 ) || return 1
  {
    printf 'PROJECT_NAME="fixture"\nDEFAULT_BRANCH="main"\nTEST_CMD="true"\nE2E_CMD=""\n'
    printf 'HANDOFF_DIR="docs/handoffs"\nQA_DOCS_PATH="docs/qa"\nJIRA_ENABLED=false\n'
    local line; for line in "$@"; do printf '%s\n' "$line"; done
  } > "$d/.sdd/config.sh"
  printf '%s\n' "$d"
}

# mission <fixture dir> <mission> <adr: value or @none@ for no key at all> — writes 00-missao.md.
#
# The frontmatter keys below are CONTRACT, exactly as templates/missao.md ships them: they are
# what the runner parses, and this repo's OUTPUT_LANG is pt-BR.
mission() {
  local d="$1" m="$2" v="$3"
  mkdir -p "$d/docs/handoffs/$m"
  {
    printf -- '---\n'
    printf 'missao: %s\n' "$m"
    printf 'aprovacao: humano-2026-01-01\n'
    [ "$v" = '@none@' ] || printf 'adr: %s\n' "$v"
    printf -- '---\n\n# %s\n' "$m"
  } > "$d/docs/handoffs/$m/00-missao.md"
}

# adr_file <fixture dir> <NNNN-slug.md> <Spec: value, or @none@ for no back-link>
adr_file() {
  local d="$1" name="$2" spec="$3"
  mkdir -p "$d/docs/adr"
  {
    printf '# %s — fixture\n\n' "${name%%-*}"
    [ "$spec" = '@none@' ] || printf 'Spec: %s\n' "$spec"
    printf '\nDate: 2026-01-01 · Status: accepted\n'
  } > "$d/docs/adr/$name"
}

# run_adr <fixture dir> <args...> — PUBLISHES ADR_OUT and ADR_RC.
#
# CALLED, never `$(run_adr …)`: read through a command substitution the body runs in a subshell
# and both globals die with it — the autonomy_kit_stamp scar named in CLAUDE.md. One caller wants
# the rc and the text together, so the function publishes rather than returns.
ADR_OUT=""; ADR_RC=0
run_adr() {
  local d="$1"; shift
  ADR_OUT="$( cd "$d" && PATH="$d/.stub:$PATH" "$SDD" adr "$@" 2>&1 )"; ADR_RC=$?
}

# assert_adr <description> <fixture dir> <expected rc> <regex the output must match> <args...>
#
# BOTH terms, never the rc alone: rc 2 is shared by "bad configuration" and "no verb", so an
# assertion reading only the number cannot say which arm ran — the house rule that an rc shared
# between branches distinguishes nothing. The regex is never `.*`.
assert_adr() {
  local desc="$1" d="$2" want_rc="$3" re="$4"; shift 4
  run_adr "$d" "$@"
  if [ "$ADR_RC" = "$want_rc" ] && grep -qE "$re" <<< "$ADR_OUT"; then pass "$desc"
  else fail "$desc" "rc $want_rc and output matching /$re/" "rc $ADR_RC — $ADR_OUT"; fi
}

# --- the negative control ----------------------------------------------------------------------
# The assertion primitive run against a world whose answer is known, required to say so. Without
# it every "ok" below is a claim the file cannot support: check-templates.sh certified a zero-byte
# template with "23 assertion(s)" for two missions because its own counter could not go red.
selftest() {
  local d saved_fails="$fails" saved_probes="$PROBES"
  d="$(fixture selftest ADR_CHECK=\"off\")" || { printf '  SENSOR-BROKEN: the fixture did not build\n' >&2; return 90; }
  # A world whose answer is known: `sdd adr check` on a legal config exits 0. A primitive that
  # answered the refusal rc here would make every assertion below decoration.
  run_adr "$d" check
  if [ "$ADR_RC" != 0 ]; then
    printf '  SENSOR-BROKEN: a legal ADR_CHECK=off returned rc %s — the probes below measure nothing\n' "$ADR_RC" >&2
    return 90
  fi
  # ...and the other direction, so the control is not satisfied by a primitive that never agrees.
  run_adr "$d" ''
  if [ "$ADR_RC" != 2 ]; then
    printf '  SENSOR-BROKEN: an unknown verb did not return rc 2 — the rc this file reads is not the rc the runner writes\n' >&2
    return 90
  fi
  fails="$saved_fails"; PROBES="$saved_probes"
  printf '  ok    negative control: the rc this file reads distinguishes the two arms\n'
}

selftest || exit $?
[ "${1:-}" != "selftest" ] || exit 0

# --- R1/R2: the config is admitted positively ---------------------------------------------------
BOGUS="$(fixture bogus ADR_CHECK=\"bogus\")" || { echo "fixture failed" >&2; exit 1; }
assert_adr 'ADR_CHECK=bogus is refused with rc 2' "$BOGUS" 2 'not one of off\|warn\|block' check

# `/` and not the empty string: the empty value cannot be reached through a config, because
# load_config defaults it with the colon form. `/` is reachable, and it is the same defect —
# hat_expand strips the trailing slash, so `$ADR_DIR/**` becomes `/**`.
ROOTDIR="$(fixture rootdir ADR_CHECK=\"warn\" ADR_DIR=\"/\")" || { echo "fixture failed" >&2; exit 1; }
assert_adr 'ADR_DIR=/ is refused with rc 2 — it would expand the hat glob to /**' \
  "$ROOTDIR" 2 'ADR_DIR=/ is not a directory path' check

# --- R3: no verb is never a silent no-op --------------------------------------------------------
OFF="$(fixture off ADR_CHECK=\"off\")" || { echo "fixture failed" >&2; exit 1; }
assert_adr 'sdd adr with no verb prints usage and exits 2' "$OFF" 2 '^usage: sdd adr new' ''

# --- R4: a legal mode names itself and reads ADR_DIR --------------------------------------------
mkdir -p "$OFF/docs/adr"
printf '# 0001 — one\n' > "$OFF/docs/adr/0001-one.md"
printf '# 0002 — two\n' > "$OFF/docs/adr/0002-two.md"
assert_adr 'off names the mode and counts what is on disk' \
  "$OFF" 0 '^  ok    ADR_CHECK=off, 2 ADR\(s\) in docs/adr$' check

# --- R5..R10: the mission scope --------------------------------------------------------------
M="$(fixture mission ADR_CHECK=\"warn\")" || { echo "fixture failed" >&2; exit 1; }

mission "$M" 20260101-nokey '@none@'
assert_adr 'mission without adr: fails and names 00-missao.md' "$M" 1 \
  'FAIL +docs/handoffs/20260101-nokey/00-missao\.md:[0-9]+ — no .adr:. key' \
  check --mission 20260101-nokey

mission "$M" 20260101-none none
assert_adr 'adr: none passes' "$M" 0 '^  ok    20260101-none: adr: none' check --mission 20260101-none

# The SAME fixture, asked twice, differing only in --phase: a differential assertion, so no
# regime of the fixture can satisfy it by accident and either side that moves turns it red.
mission "$M" 20260101-tbd TBD
assert_adr 'adr: TBD is info by default' "$M" 0 '^  info  20260101-tbd: adr: TBD' check --mission 20260101-tbd
assert_adr '...and the same mission FAILs with --phase plan' "$M" 1 \
  'FAIL .*00-missao\.md:[0-9]+ — .adr: TBD. is not a decision' check --mission 20260101-tbd --phase plan
# The untouched template placeholder has decided exactly as much as a written TBD. Read as two
# states, the mission that never touched the line would pass the gate the written TBD fails.
mission "$M" 20260101-ph '<none | TBD | docs/adr/NNNN-slug.md>'
assert_adr '...and so does the untouched template placeholder' "$M" 1 \
  'FAIL .*00-missao\.md:[0-9]+ — .adr: <none .* is not a decision' check --mission 20260101-ph --phase plan

mission "$M" 20260101-gone docs/adr/0009-gone.md
assert_adr 'adr: path to a missing file fails' "$M" 1 \
  'FAIL .*00-missao\.md:[0-9]+ — .adr: docs/adr/0009-gone\.md. points at a file that does not exist' \
  check --mission 20260101-gone

mission "$M" 20260101-title docs/adr/nine.md
assert_adr 'an adr: whose file name carries no number fails — the id is read from the NAME' "$M" 1 \
  'the id is read from the FILE NAME' check --mission 20260101-title

# The case of the vault note, which is what this whole mission is about: the ADR exists, the
# number is real, and it belongs to ANOTHER decision. One direction proves nothing — an `adr:`
# pointing at a real file is satisfied by every real file.
mission "$M" 20260101-else docs/adr/0010-else.md
adr_file "$M" 0010-else.md docs/handoffs/20260101-other/00-missao.md
assert_adr 'ADR whose Spec: points elsewhere fails' "$M" 1 \
  'FAIL +docs/adr/0010-else\.md:[0-9]+ — .Spec: docs/handoffs/20260101-other/00-missao\.md. points somewhere else' \
  check --mission 20260101-else

adr_file "$M" 0011-nolink.md '@none@'
mission "$M" 20260101-nolink docs/adr/0011-nolink.md
assert_adr 'ADR with no Spec: line at all fails' "$M" 1 \
  'FAIL +docs/adr/0011-nolink\.md:[0-9]+ — has no .Spec:. line' check --mission 20260101-nolink

mission "$M" 20260101-good docs/adr/0012-good.md
adr_file "$M" 0012-good.md docs/handoffs/20260101-good/00-missao.md
assert_adr 'ADR with the back-link passes rc 0' "$M" 0 \
  '^  ok    docs/handoffs/20260101-good/00-missao\.md: adr: docs/adr/0012-good\.md — and that ADR points back' \
  check --mission 20260101-good

# The other dialect, read by the same rule: the pilot target writes the link as a bold list item.
# Written twice, this file would go on passing the day one spelling stopped being understood.
mission "$M" 20260101-dialect docs/adr/0013-dialect.md
mkdir -p "$M/docs/adr"
printf '# ADR 0013 — fixture\n\n- **Status**: aceito\n- **Spec**: docs/handoffs/20260101-dialect/00-missao.md\n' \
  > "$M/docs/adr/0013-dialect.md"
assert_adr 'the `- **Spec**:` dialect is read by the same rule' "$M" 0 \
  '^  ok    docs/handoffs/20260101-dialect/00-missao\.md: adr: docs/adr/0013-dialect\.md' check --mission 20260101-dialect

# --- R11..R16: the repo scope -----------------------------------------------------------------
# A fixture of its own, because the repo scope reads EVERYTHING on disk and the mission fixture
# above is deliberately full of broken links.
R="$(fixture repo ADR_CHECK=\"warn\" SPEC_DIR=\"specs\")" || { echo "fixture failed" >&2; exit 1; }
adr_file "$R" 0001-one.md '@none@'
assert_adr 'a clean repo with no mission and no spec passes' "$R" 0 \
  '^  ok    ADR_CHECK=warn, 1 ADR\(s\) in docs/adr$' check

# Two files, one number. BOTH named in the verdict: the reader has to decide which of the two keeps
# it, and a message naming only the newcomer hides half the decision.
adr_file "$R" 0001-two.md '@none@'
assert_adr 'duplicate ADR number fails both files' "$R" 1 \
  'FAIL +docs/adr/0001-two\.md:[0-9]+ — id 0001 is already taken by 0001-one\.md' check
rm -f "$R/docs/adr/0001-two.md"

printf 'notes\n' > "$R/docs/adr/loose.md"
assert_adr 'a file in ADR_DIR whose name carries no id fails' "$R" 1 \
  'FAIL +docs/adr/loose\.md:[0-9]+ — the name does not read as NNNN-slug\.md' check
rm -f "$R/docs/adr/loose.md"

# d, the failing half: inside a spec tree a number is a CLAIM.
mkdir -p "$R/specs/001-thing"
printf '# Thing\n\nSee ADR 0042 for the rationale.\n' > "$R/specs/001-thing/spec.md"
assert_adr 'a bare ADR 0042 in a spec with no file fails' "$R" 1 \
  "FAIL +specs/001-thing/spec\\.md:3 — cites 'ADR 0042', and no file in docs/adr carries that id" check

# ...and the differential that gives the asymmetry teeth: the SAME sentence in a handoff is
# narrative and is COUNTED. Written as two separate assertions over two fixtures, either side could
# drift to match the other and both would stay green; compared here, whichever side moves goes red.
mission "$R" 20260101-prose none
printf '# Plan\n\nSee ADR 0042 for the rationale.\n' > "$R/docs/handoffs/20260101-prose/01-plano.md"
rm -f "$R/specs/001-thing/spec.md"
assert_adr 'a bare ADR 0042 in 01-plano.md is counted as info, not a failure' "$R" 0 \
  "^  info  1 bare 'ADR NNNN' citation\\(s\\) in handoff prose with no file in docs/adr$" check

# A spec that declares an ADR gets the two-way check a mission gets — including the vault case.
printf '# Thing\n\n**ADR**: docs/adr/0002-elsewhere.md\n' > "$R/specs/001-thing/spec.md"
adr_file "$R" 0002-elsewhere.md specs/999-other/spec.md
assert_adr 'a spec whose ADR points back at another spec fails' "$R" 1 \
  "FAIL +docs/adr/0002-elsewhere\\.md:[0-9]+ — 'Spec: specs/999-other/spec\\.md' points somewhere else, not at specs/001-thing/spec\\.md" check

adr_file "$R" 0002-elsewhere.md specs/001-thing/spec.md
assert_adr '...and passes once the ADR points back at it' "$R" 0 \
  '^  ok    specs/001-thing/spec\.md: ADR: docs/adr/0002-elsewhere\.md — and that ADR points back' check

mkdir -p "$R/specs/002-plain"
printf '# Other\n\nno decision here\n' > "$R/specs/002-plain/spec.md"
assert_adr 'spec.md without an ADR line is counted as info, rc 0' "$R" 0 \
  '^  info  1 spec\(s\) in specs carry no ADR line$' check

# The repo scope hands every mission that DECLARES a path to the full mission scope, back-link and
# all. Without this the whole (b) branch could be replaced by `:` and nothing would notice — which
# is exactly what the sabotage pass found, and the reason this probe exists.
mission "$R" 20260101-decl docs/adr/0004-decl.md
adr_file "$R" 0004-decl.md docs/handoffs/20260101-other/00-missao.md
assert_adr 'the repo scope runs the full mission check on every mission that declares a path' "$R" 1 \
  "FAIL +docs/adr/0004-decl\\.md:[0-9]+ — 'Spec: docs/handoffs/20260101-other/00-missao\\.md' points somewhere else" check
adr_file "$R" 0004-decl.md docs/handoffs/20260101-decl/00-missao.md

# SPEC_DIR empty scans NOTHING — never the repo root. The differential is the assertion: the same
# tree, one config line apart, has to stop naming the spec tree entirely.
RE="$(fixture repo_nospec ADR_CHECK=\"warn\")" || { echo "fixture failed" >&2; exit 1; }
# Planted at the depth the FALLBACK would reach — `find "$root/" -mindepth 2 -maxdepth 2` — and not
# at `specs/001-thing/spec.md`, which that fallback misses by one level. Measured: with the spec a
# level deeper the probe passed against a runner whose guard had been removed, so it was asserting
# the shape of the fixture rather than the presence of the guard.
mkdir -p "$RE/thing"
printf '# Thing\n\nSee ADR 0042 for the rationale.\n' > "$RE/thing/spec.md"
assert_adr 'SPEC_DIR empty scans no specs — an empty value must not fall back to the repo root' \
  "$RE" 0 '^  ok    ADR_CHECK=warn, 0 ADR\(s\) in docs/adr$' check

# The stub the allocator writes is information until somebody fills it in.
adr_file "$R" 0003-stub.md specs/001-thing/spec.md
printf '<!-- sdd adr new: body in OUTPUT_LANG=en -->\n' >> "$R/docs/adr/0003-stub.md"
assert_adr 'an unfilled sdd adr new stub is counted as info' "$R" 0 \
  "^  info  1 ADR\\(s\\) still carry the unfilled 'sdd adr new' stub$" check

# --- R17..R22: the allocator --------------------------------------------------------------------
N="$(fixture new ADR_CHECK=\"warn\")" || { echo "fixture failed" >&2; exit 1; }
assert_adr 'an empty ADR_DIR allocates 0001' "$N" 0 '^docs/adr/0001-first\.md$' new --slug first --dry-run
# ...and the dry run touched NOTHING. Both terms, and neither alone is the assertion: "prints the
# path" passes on a projection that also creates the file, and "creates nothing" passes on one
# that prints nothing at all.
if [ -e "$N/docs/adr" ]; then fail '--dry-run prints the path and creates nothing' 'no docs/adr' 'the directory exists'
else pass '--dry-run prints the path and creates nothing'; fi

mkdir -p "$N/docs/adr"; : > "$N/docs/adr/0001-a.md"; : > "$N/docs/adr/0003-c.md"
assert_adr 'a gap is never reused (0001, 0003 allocate 0004)' "$N" 0 '^docs/adr/0004-d\.md$' new --slug d --dry-run

assert_adr 'a slug that is not lower-case-and-hyphens is refused' "$N" 1 \
  "is not lower-case letters, digits and hyphens" new --slug 'Not A Slug'

# --spec, the two layouts, told apart by what is on disk rather than by a flag.
mission "$N" 20260101-tbd TBD
assert_adr '--spec replaces adr: TBD with the path it just reserved' "$N" 0 \
  '^  ok +docs/adr/0004-decided\.md reserved, and docs/handoffs/20260101-tbd/00-missao\.md now declares it$' \
  new --slug decided --spec docs/handoffs/20260101-tbd/00-missao.md
assert_adr '...and the pair it wrote satisfies the check it will be asked for' "$N" 0 \
  '^  ok    docs/handoffs/20260101-tbd/00-missao\.md: adr: docs/adr/0004-decided\.md — and that ADR points back' \
  check --mission 20260101-tbd

# frontmatter_write() rewrites an existing key and leaves an absent one absent — by design. So the
# absent case has a probe of its own, or `sdd adr new --spec` would silently write only one half of
# the link on every mission planned before the key existed.
mission "$N" 20260101-nokey '@none@'
assert_adr '--spec adds adr: to a mission that lacks the key entirely' "$N" 0 \
  'docs/handoffs/20260101-nokey/00-missao\.md now declares it' \
  new --slug nokey --spec docs/handoffs/20260101-nokey/00-missao.md
assert_adr '...and that mission passes the check too' "$N" 0 \
  '^  ok    docs/handoffs/20260101-nokey/00-missao\.md: adr: docs/adr/0005-nokey\.md — and that ADR points back' \
  check --mission 20260101-nokey

assert_adr '--spec refuses a spec that already declares a path — choosing between two ADRs is a human decision' \
  "$N" 1 "already declares 'docs/adr/0004-decided\.md'" \
  new --slug again --spec docs/handoffs/20260101-tbd/00-missao.md

# The SpecKit layout: no frontmatter, so the link is a `**ADR**:` line.
mkdir -p "$N/specs/001-x"; printf '# X\n\n**Status**: Draft\n' > "$N/specs/001-x/spec.md"
assert_adr '--spec writes a **ADR**: line into a spec with no frontmatter' "$N" 0 \
  'specs/001-x/spec\.md now declares it' new --slug speckit --spec specs/001-x/spec.md

# --- the reservation primitive -----------------------------------------------------------------
# DETERMINISTIC, and not a race. Two processes fighting for the same number would assert a
# scheduling accident: green on a fast machine, red under load, and red means nothing either way.
# What O_EXCL promises is testable without a second process — an existing path is refused and its
# bytes are untouched — and that is what is asserted here.
#
# `sed '$d'` drops the last line, which is `{ main "$@"; exit $?; }`: sourced whole, bin/sdd would
# run main and take this file with it. The `declare -F` control is what keeps the probe from
# passing because the source silently did nothing.
PROBES=$((PROBES + 1))
cat > "$BOX/reserve-probe.sh" <<'RESERVE'
set -uo pipefail
sdd="$1"; victim="$2"
# shellcheck disable=SC1090
source <(sed '$d' "$sdd") >/dev/null 2>&1
set +e
declare -F adr_reserve >/dev/null || { echo NOFUNC; exit 3; }
adr_reserve "$victim" && { echo RESERVED_AN_EXISTING_PATH; exit 4; }
exit 0
RESERVE
printf 'original bytes\n' > "$BOX/victim.md"
if bash "$BOX/reserve-probe.sh" "$SDD" "$BOX/victim.md" >/dev/null 2>&1 \
     && [ "$(cat "$BOX/victim.md")" = 'original bytes' ]; then
  pass 'the reservation primitive refuses an existing path and keeps its bytes'
else
  fail 'the reservation primitive refuses an existing path and keeps its bytes' \
    'rc 0 from the probe and the file unchanged' \
    "probe rc $(bash "$BOX/reserve-probe.sh" "$SDD" "$BOX/victim.md" >/dev/null 2>&1; echo $?), content: $(cat "$BOX/victim.md")"
fi

# --- R23..R26: the gates ------------------------------------------------------------------------
# Through `sdd phase` and `sdd why`, which is the only way to assert on a gate: the runner derives
# the phase from the artifacts, so a probe that called gate_PLAN directly would be asserting on a
# function rather than on what the pipeline does.
#
# ONE fixture for all of them, config lines apart, so the off/warn/block triple is DIFFERENTIAL.
# Three fixtures would let any one of them drift to match the others and all three stay green;
# here, whichever mode moves turns red next to the two that did not.
G="$(fixture gates ADR_CHECK=\"block\")" || { echo "fixture failed" >&2; exit 1; }
GM=20260101-gate
mkdir -p "$G/docs/handoffs/$GM"
{ printf -- '---\nmissao: %s\naprovacao: auto\n---\n\n# Mission\n' "$GM"; } > "$G/docs/handoffs/$GM/00-missao.md"
: > "$G/docs/handoffs/$GM/01-plano.md"
{ printf '| ID | Incremento | Check (comando → esperado) | Status | Commit |\n'
  printf -- '|---|---|---|---|---|\n'
  printf '| I1 | slice one | `true` → 0 | pending | — |\n'; } > "$G/docs/handoffs/$GM/checkpoint.md"

# adr_phase <fixture> <mission> — PUBLISHES ADR_OUT/ADR_RC from `sdd phase`. CALLED, never `$( )`
# at the call site for the same reason run_adr is.
sdd_at() {
  local d="$1"; shift
  ADR_OUT="$( cd "$d" && PATH="$d/.stub:$PATH" "$SDD" "$@" 2>&1 )"; ADR_RC=$?
}
assert_at() {   # assert_at <desc> <fixture> <regex> <args...>
  local desc="$1" d="$2" re="$3"; shift 3
  sdd_at "$d" "$@"
  if grep -qE "$re" <<< "$ADR_OUT"; then pass "$desc"
  else fail "$desc" "output matching /$re/" "$ADR_OUT"; fi
}
assert_at_absent() {   # the other half: rc and text are shared between branches, absence is not
  local desc="$1" d="$2" re="$3"; shift 3
  sdd_at "$d" "$@"
  if grep -qE "$re" <<< "$ADR_OUT"; then fail "$desc" "output WITHOUT /$re/" "$ADR_OUT"
  else pass "$desc"; fi
}

assert_at 'block: a mission with no adr: key stalls at PLAN' "$G" '^PLAN$' phase "$GM"
# ...and the reason NAMES the command that ends the stall. A refusal that does not is an
# instruction to hand-edit frontmatter, which is the failure the allocator exists to end — the
# same rule gate_PLAN's approval branch already carries.
assert_at 'block: ...and the reason names sdd adr new' "$G" "sdd adr new --slug" why "$GM" PLAN

sed -i 's@^aprovacao: auto@aprovacao: auto\nadr: TBD@' "$G/docs/handoffs/$GM/00-missao.md"
assert_at 'block: adr: TBD stalls at PLAN' "$G" '^PLAN$' phase "$GM"
sed -i 's@^adr: TBD@adr: <none | TBD | docs/adr/NNNN-slug.md>@' "$G/docs/handoffs/$GM/00-missao.md"
assert_at 'block: the untouched template placeholder stalls at PLAN too' "$G" '^PLAN$' phase "$GM"

sed -i 's@^adr: .*@adr: none@' "$G/docs/handoffs/$GM/00-missao.md"
assert_at 'block: adr: none derives EXEC — deciding nothing is a decision, written down' "$G" '^EXEC$' phase "$GM"

# Drift, which is the one thing EXEC asks that PLAN cannot: the ADR was on disk when the human
# approved the plan and is not on disk now.
adr_file "$G" 0001-gate.md "docs/handoffs/$GM/00-missao.md"
sed -i 's@^adr: none@adr: docs/adr/0001-gate.md@' "$G/docs/handoffs/$GM/00-missao.md"
assert_at 'block: a mission whose ADR is on disk derives EXEC' "$G" '^EXEC$' phase "$GM"
rm -f "$G/docs/adr/0001-gate.md"
assert_at 'block: ADR file removed after approval makes EXEC refuse' "$G" 'points at a file that does not exist' why "$GM" EXEC
adr_file "$G" 0001-gate.md "docs/handoffs/$GM/00-missao.md"

# The differential. Same mission, same disk, one config line apart.
sed -i 's@^adr: .*@adr: TBD@' "$G/docs/handoffs/$GM/00-missao.md"
assert_at 'block: TBD refuses, and the refusal is the ADR one' "$G" '^PLAN: adr: ' why "$GM" PLAN
sed -i 's@^ADR_CHECK="block"@ADR_CHECK="warn"@' "$G/.sdd/config.sh"
assert_at 'warn: the SAME mission derives EXEC' "$G" '^EXEC$' phase "$GM"
assert_at_absent 'warn: ...and PLAN says nothing about the adr:' "$G" '^PLAN: adr: ' why "$GM" PLAN
sed -i 's@^ADR_CHECK="warn"@ADR_CHECK="off"@' "$G/.sdd/config.sh"
sed -i '/^adr: /d' "$G/docs/handoffs/$GM/00-missao.md"
assert_at 'off: a mission with no adr: key at all derives EXEC' "$G" '^EXEC$' phase "$GM"

# A config the runner cannot read must stop the gate, not be silently treated as off.
sed -i 's@^ADR_CHECK="off"@ADR_CHECK="bogus"@' "$G/.sdd/config.sh"
assert_at 'a bogus ADR_CHECK refuses at the gate instead of degrading to off' "$G" \
  '^PLAN: ADR_CHECK=bogus is not one of off\|warn\|block' why "$GM" PLAN

# --- R27: warn leaves a trail ------------------------------------------------------------------
# Through the DETERMINISTIC dirty-tree Jidoka, which escapes before any run_phase — so this drives a
# real `sdd run` and spends nothing. The stub `claude` on PATH makes that a property of the fixture
# and not of the assertion happening to escape in time.
#
# A ledger of its own per fixture: rows from a throwaway checkout are what the judge reads as
# missions (ADR 0005), and the runner refuses to write the real one from under $TMPDIR anyway.
W="$(fixture warnrun ADR_CHECK=\"warn\")" || { echo "fixture failed" >&2; exit 1; }
WM=20260101-warn
WLEDGER="$BOX/warn-state"
mkdir -p "$WLEDGER" "$W/docs/handoffs/$WM"
{ printf -- '---\nmissao: %s\naprovacao: auto\nadr: TBD\n---\n\n# Mission\n' "$WM"; } > "$W/docs/handoffs/$WM/00-missao.md"
: > "$W/docs/handoffs/$WM/01-plano.md"
( cd "$W" && git add -A && git commit -qm "mission" ) >/dev/null 2>&1
WSHA="$( cd "$W" && git rev-parse --short HEAD )"
{ printf '| ID | Incremento | Check (comando → esperado) | Status | Commit |\n'
  printf -- '|---|---|---|---|---|\n'
  # The Commit cell is read VERBATIM by gate_EXEC — no backticks around the sha. With them the
  # gate reports "points at commit '`abc1234`', which does not exist" and the run escalates for
  # the wrong reason, which is how this fixture first behaved: rc 3 with no dirty-tree row at all.
  printf '| I1 | slice one | `true` → 0 | done | %s |\n' "$WSHA"; } > "$W/docs/handoffs/$WM/checkpoint.md"
: > "$W/docs/handoffs/$WM/20-handoff-exec.md"
( cd "$W" && git add -A && git commit -qm "increment" ) >/dev/null 2>&1
# TEST_CMD red over a dirty tree is the dirty-tree Jidoka: rc 3, and no session.
sed -i 's@^TEST_CMD=.*@TEST_CMD="false"@' "$W/.sdd/config.sh"
printf 'uncommitted\n' > "$W/dirty.txt"

# run_ledger <fixture> <state dir> <extra sdd args...> — PUBLISHES ADR_RC and the ledger path.
LEDGER_FILE=""
run_ledger() {
  local d="$1" st="$2"; shift 2
  rm -f "$st/autonomy-log.jsonl"
  ( cd "$d" && PATH="$d/.stub:$PATH" SDD_STATE_DIR="$st" "$SDD" run "$@" ) >/dev/null 2>&1
  ADR_RC=$?
  LEDGER_FILE="$st/autonomy-log.jsonl"
}
# rows_of <kind> — how many degraded rows of that kind the last run wrote
# Captured and defaulted, never `grep -c … || true` and never `… || echo 0`. On a MISSING file
# grep -c prints nothing (the empty string compared against "0" fails with a blank in the "got"
# column); on a file with no match it prints 0 AND exits 1, so an `|| echo 0` appends a SECOND
# line and the comparison sees "0\n0". Both spellings were tried here, in that order.
rows_of() {
  local n; n="$(grep -c "\"kind\":\"$1\"" "$LEDGER_FILE" 2>/dev/null)" || n=0
  printf '%s\n' "${n:-0}"
}

run_ledger "$W" "$WLEDGER" "$WM"
# THREE terms, and none of them is the assertion alone. "rc 3" passes on a run that escalated for
# any reason; "one adr-check row" passes on a run that wrote it and then never reached the Jidoka;
# "before the dirty-tree row" is what says the warning was written on the way past the gate rather
# than as part of the escalation.
if [ "$ADR_RC" = 3 ] && [ "$(rows_of adr-check)" = 1 ] && [ "$(rows_of dirty-tree)" = 1 ] \
     && [ "$(grep -n '"kind":"adr-check"' "$LEDGER_FILE" | cut -d: -f1)" -lt \
          "$(grep -n '"kind":"dirty-tree"' "$LEDGER_FILE" | cut -d: -f1)" ]; then
  pass 'warn: one degraded adr-check row per run, before the session'
else
  fail 'warn: one degraded adr-check row per run, before the session' \
    'rc 3, exactly one adr-check row, and it precedes the dirty-tree row' \
    "rc $ADR_RC, adr-check $(rows_of adr-check), dirty-tree $(rows_of dirty-tree)"
fi

# The two differentials. Same fixture, same disk: one flag apart and one config line apart, so no
# regime of the fixture satisfies them by accident and whichever side moves turns red.
run_ledger "$W" "$WLEDGER" "$WM" --dry-run
if [ "$(rows_of adr-check)" = 0 ]; then pass 'warn: --dry-run writes no adr-check row — a projection opens no session to attribute one to'
else fail 'warn: --dry-run writes no adr-check row' '0 rows' "$(rows_of adr-check)"; fi

sed -i 's@^ADR_CHECK="warn"@ADR_CHECK="off"@' "$W/.sdd/config.sh"
run_ledger "$W" "$WLEDGER" "$WM"
if [ "$ADR_RC" = 3 ] && [ "$(rows_of adr-check)" = 0 ]; then
  pass 'off writes no degraded row — the same run, the same disk, one config line apart'
else fail 'off writes no degraded row' 'rc 3 and 0 adr-check rows' "rc $ADR_RC, $(rows_of adr-check) row(s)"; fi

# --- verdict ------------------------------------------------------------------------------------
if [ "$PROBES" -lt "$PROBE_FLOOR" ]; then
  printf '  FAIL  probe floor shrank to %d, expected at least %d — did a block stop being dispatched?\n' \
    "$PROBES" "$PROBE_FLOOR" >&2
  exit 93
fi
if [ "$fails" -eq 0 ]; then printf '  ok    adr traceability: %d probes\n' "$PROBES"; exit 0; fi
printf '  FAIL  %d probe(s) failed\n' "$fails" >&2
exit 1
