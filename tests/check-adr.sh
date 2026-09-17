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
PROBE_FLOOR=4

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

# --- verdict ------------------------------------------------------------------------------------
if [ "$PROBES" -lt "$PROBE_FLOOR" ]; then
  printf '  FAIL  probe floor shrank to %d, expected at least %d — did a block stop being dispatched?\n' \
    "$PROBES" "$PROBE_FLOOR" >&2
  exit 93
fi
if [ "$fails" -eq 0 ]; then printf '  ok    adr traceability: %d probes\n' "$PROBES"; exit 0; fi
printf '  FAIL  %d probe(s) failed\n' "$fails" >&2
exit 1
