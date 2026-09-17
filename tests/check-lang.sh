#!/usr/bin/env bash
# Language sensor for the kit's own surface.
#
# The kit is English; mission ARTIFACTS are written in whatever OUTPUT_LANG the target repo
# declares. This check guards the first half only: no Portuguese prose creeps back into the
# runner, the agents, the docs or the tests.
#
# What it does NOT do: prove a translation is complete. That is human judgement on the diff of
# each increment. This one prevents the regression, which is what rots on its own.
#
# Ratchet, same semantics as tests/health-baseline.txt: a file OUTSIDE the allowlist containing
# Portuguese fails; a file INSIDE the allowlist that is already clean ALSO fails — a list that
# only grows is folklore, not a ratchet.
#
# Usage: tests/check-lang.sh   (exit 0 = surface clean and allowlist honest)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLOWLIST="$ROOT/tests/lang-allowlist.txt"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-lang-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# The English surface. templates/ and config/examples/ are absent on purpose: they are content
# in OUTPUT_LANG, not kit surface. So are TODO.md, KAIZEN_LOG.md, CLAUDE.md and docs/handoffs/.
#
# tests/fixtures/ is absent for a third reason, and the glob below says so by scanning `tests/*.sh`
# and nothing deeper: it holds stdout CAPTURED VERBATIM from third-party tools, and a Jira status
# name arrives localized ("Concluído"). Scanning it would leave two exits, and both are worse than
# the hole — edit the capture until the scan is quiet (a fixture written from memory, which passes
# green forever) or exempt the whole .sh that carries it (a real English file going unscanned).
# The rule that keeps this from becoming a loophole is a category, not a list: tests/fixtures/ holds
# DATA, never logic. A .sh file there would be outside this surface while being exactly the thing
# the surface exists to read.
#
# Two files are excluded, and neither is a loophole. They are the only places where Portuguese is
# DATA rather than prose, so scanning them would force the data to be weakened just to keep the
# scan quiet:
#
#   - check-lang.sh (this file): the stopword list and the self-test probes have to contain the
#     thing being detected. Its guard is selftest() below, which exits 90/91/92 the moment
#     detection stops working — a stricter check than grepping for accents, because it measures
#     behaviour instead of spelling.
#   - check-templates.sh: its regexes assert the headings of templates/, which are mission content
#     in this repo's OUTPUT_LANG (pt-BR). Translating them would break the contract they measure.
#
# The cost is real and worth naming: Portuguese PROSE could creep into those two files unseen. The
# fix that would restore coverage is to move the template contract out into a data file, leaving
# the script pure English logic — recorded in TODO.md, not done here.
surface() {
  ( cd "$ROOT" && ls -1 bin/sdd agents/sdd-*.md .claude/agents/sdd-*.md \
      docs/pipeline.md docs/failure-modes.md docs/graphify.md docs/adr/*.md README.md \
      config/schema.md config/starter.conf \
      tests/*.sh tests/health-baseline.txt tests/lang-allowlist.txt 2>/dev/null ) \
    | grep -vxF -e 'tests/check-lang.sh' -e 'tests/check-templates.sh'
}

# Accent-free Portuguese function words. `todo`/`toda` are deliberately absent: they would match
# TODO.md and `# TODO`. Measured against a real English markdown file: zero false positives.
STOPWORDS='falta|sem|para|pelo|pela|quando|onde|nada|este|esta|isso|pois|cada|apenas|ainda|depois|antes|porque|assim|sobre|mesmo|outro|outra|nao|entao'

# The THIRD thing punched out of the scan, and the same argument as the × and the ÷ above: a
# traceability line is DATA, not prose. `Spec: docs/handoffs/<mission>/00-missao.md` in an ADR is
# the exact string `sdd adr check` reads back, and `docs/handoffs/` is out of this sensor's scope
# by the declaration at the top of the allowlist — so the mission slug in it is written in the
# repo's OUTPUT_LANG on purpose. Measured on 2026-09-17: ADR 0008 of this kit, English throughout,
# was reported as Portuguese for the word "nao" inside its own Spec: path.
#
# The line is BLANKED and not dropped, so grep -n goes on reporting the real line numbers; and the
# pattern is anchored on the key, so only the contract line loses its content — every other line of
# the ADR is scanned exactly as before. The tempting wider rule — "ignore anything that looks like a
# path" — is the fail-open this sensor exists to refuse.
#
# TWO halves, and the second is the one that keeps the first honest. Anchoring on the key alone
# blanked the WHOLE remainder of the line, so `Spec: <any Portuguese sentence>` disappeared before
# has_portuguese() ever saw it — a strip of every scanned file, one key wide, that the sensor
# claimed to be reading. It is the fail-open this file exists to refuse, written by the very
# comment above it. So the exemption fires only when the remainder is ONE path token running to
# end of line: a slash is required (a bare `TBD` is not a path) and a space is not in the class, so
# prose never satisfies it. Probed in both directions in selftest() — the path exempted, and a
# sentence behind the same key still caught.
ADR_LINK_KEY='^(- )?(\*\*)?(ADR|Spec)(\*\*)?:[[:space:]]*'
ADR_LINK_PATH='[A-Za-z0-9._-]*(/[A-Za-z0-9._-]+)+[[:space:]]*$'
ADR_LINK_LINE="${ADR_LINK_KEY}${ADR_LINK_PATH}"

# has_portuguese <file> — prints the offending lines, returns 0 when it found any.
#
# Two proxies, because either alone is blind: the accent class misses "falta o handoff", the word
# list misses "sessão". The accent class is Latin-1 LETTERS only — a blanket non-ASCII test would
# fire on ✅ ✗ → ⇒ ▸ · │ ⚠️ —, which the kit uses on nearly every page.
#
# The two holes punched in the range are × (00D7) and ÷ (00F7): they sit inside the Latin-1 letter
# block without being letters, and the first version of this check flagged `QA_MAX_ITER × 3` in
# config/schema.md as Portuguese. Worth naming because of how the mistake would have been fixed:
# the tempting move is to reword the doc until the detector goes quiet, which is weakening the
# content to please a broken instrument.
has_portuguese() {
  local f="$1" hits body
  [ -f "$f" ] || return 1
  body="$(sed -E "s@${ADR_LINK_LINE}@@" "$f")"
  hits="$( { grep -nP '[\x{00C0}-\x{00D6}\x{00D8}-\x{00F6}\x{00F8}-\x{00FF}]' <<< "$body" || true
             grep -nwiE "$STOPWORDS" <<< "$body" || true; } | sort -t: -k1,1n -u )"
  [ -n "$hits" ] || return 1
  printf '%s\n' "$hits"
}

# Anti-vacuity: a broken regex would report "all clean" forever, which is exactly the failure
# class the mutation catalogue exists to kill. Probes, not repo state — this has to behave the
# same on a fully translated kit, when no real file can play the part of the dirty one.
selftest() {
  local t="$WORK/probe.md"
  printf 'A sessão não é artefato.\n' > "$t"
  has_portuguese "$t" >/dev/null || {
    echo "SENSOR-BROKEN: accented Portuguese not detected" >&2; exit 90; }
  printf 'falta o handoff, sem commit\n' > "$t"
  has_portuguese "$t" >/dev/null || {
    echo "SENSOR-BROKEN: accent-free Portuguese not detected" >&2; exit 91; }
  # English with the symbols the kit really uses, including the two Latin-1 non-letters that a
  # naive range would catch. This probe is the regression guard for that exact mistake.
  printf 'The session is not an artifact — see ✅ ✗ → ⇒ ▸ · │ ⚠️ and QA_MAX_ITER × 3 ÷ 1.\n' > "$t"
  if has_portuguese "$t" >/dev/null; then
    echo "SENSOR-BROKEN: clean English flagged as Portuguese" >&2; exit 92
  fi
  # The traceability line is data. DIFFERENTIAL, and neither half is the assertion alone: "the
  # Spec: line is ignored" passes on a sensor that ignores everything, and "prose is still caught"
  # passes on one that ignores nothing. The two spellings differ by the key in front of the path.
  printf 'Spec: docs/handoffs/20260917-o-numero-do-adr-nao-e-prosa/00-missao.md\n' > "$t"
  if has_portuguese "$t" >/dev/null; then
    echo "SENSOR-BROKEN: a Spec: path read as prose — the mission slug in it is OUTPUT_LANG by design" >&2
    exit 95
  fi
  printf 'See docs/handoffs/20260917-o-numero-do-adr-nao-e-prosa/00-missao.md for the rest.\n' > "$t"
  if ! has_portuguese "$t" >/dev/null; then
    echo "SENSOR-BROKEN: the same path in PROSE was not caught — the hole is wider than the key" >&2
    exit 95
  fi
  # The THIRD spelling, and the one that measures the exemption's width rather than its existence.
  # With the rule anchored on the key alone this sentence was blanked whole and the sensor reported
  # a clean file: the two probes above both stayed green through it, because neither asks what
  # happens to a remainder that is NOT a path. Prose behind the key is still prose.
  printf 'Spec: aqui nao tem caminho nenhum, e apenas uma frase escondida atras da chave\n' > "$t"
  if ! has_portuguese "$t" >/dev/null; then
    echo "SENSOR-BROKEN: Portuguese prose behind a Spec: key was blanked — the exemption is not scoped to a path" >&2
    exit 95
  fi
  # And the neighbour that proves the scoping did not simply switch the exemption off: a bare
  # value with no slash is not a path, so the line is scanned — and a clean one stays clean.
  printf 'Spec: TBD\n' > "$t"
  if has_portuguese "$t" >/dev/null; then
    echo "SENSOR-BROKEN: 'Spec: TBD' read as Portuguese" >&2; exit 92
  fi
}

selftest
echo "  ok    self-test: the sensor detects Portuguese, clears English, and reads a traceability line as data"

# Checked before the surface floor below, and not after: the allowlist is itself a surface path,
# so a missing file trips the floor first and reports "did something move?" — loud, but the wrong
# diagnosis. The specific cause beats the generic one when both are true.
#
# An unreadable allowlist must not degrade into "empty allowlist" either: `grep ... || true` on a
# missing file yields an empty `known`, and with the surface clean that reads as "no debt".
#
# Precisely how bad that is, measured rather than assumed: the floor below would also catch it at
# rc 93, because the allowlist is itself one of the surface paths and losing it drops the count
# under the floor. So it would fail loudly — but by coincidence of the boundary, and only while
# nobody forgets to move the floor when the surface grows. This check makes the failure
# independent of that coincidence.
if [ ! -f "$ALLOWLIST" ]; then
  printf '  FAIL  allowlist missing: %s — cannot tell "no debt" from "no list"\n' "$ALLOWLIST" >&2
  exit 94
fi

files="$(surface)"

# Explicit floor, same reason as the "exactly 8 gates" floor in cmd_health: a glob that stops
# matching (a renamed directory, a moved file) would leave the loop with nothing to read and the
# check would report "0 new" — clean by vacuity. 41 paths today; the floor moves only on purpose,
# and it moved seven times already: tests/check-preflight.sh took it from 24 to 25,
# tests/check-autonomy.sh from 25 to 26, I13.3 from 26 to 31 (check-kaizen.sh, the two
# sdd-kaizen.md copies, and the docs/adr/*.md glob with its ADRs), check-todo.sh to 32,
# check-pipefail.sh to 33, then check-entrypoint.sh and check-checkpoint.sh to 35, ADR 0003
# to 36, tests/check-health.sh to 37, and docs/graphify.md to 41.
# ⚠️ Three of those arrived without moving the floor, so it sat at 33 against a real 36 and
# carried three paths of slack — a vacuity guard with slack is a vacuity guard that does not
# guard. Re-counted against the real surface in the r1 review of 20260817-eixo-do-juiz.
# ⚠️ And it happened AGAIN, which is why the last hop is 37 → 41 and not 37 → 38: ADRs 0004, 0005
# and 0006 each joined the docs/adr/*.md glob without touching this number, so the floor described
# 37 paths while the surface was already 40. A floor that lags keeps PASSING while measuring a
# smaller surface than the one it reads — the same failure this comment already names once.
# Re-counted against the real surface in I4 of 20260901-o-revisor-so-acha (40 + docs/graphify.md).
# Re-counted on 2026-09-03 (20260903-a-fronteira-do-chapeu): 41 + tests/check-hat.sh +
# agents/sdd-ticket.md + its .claude/agents copy = 44; docs/adr/0007 makes it 45 in the same mission.
# Re-counted on 2026-09-17 (20260917-o-numero-do-adr-nao-e-prosa): tests/check-adr.sh makes it 46,
# and docs/adr/0008 makes it 47 in the same mission — two hops, two commits, on purpose.
n_surface="$(grep -c . <<< "$files")"
if [ "$n_surface" -lt 47 ]; then
  printf '  FAIL  surface shrank to %d path(s), expected at least 47 — did something move?\n' \
    "$n_surface" >&2
  exit 93
fi

known="$(grep -vE '^[[:space:]]*(#|$)' "$ALLOWLIST" || true)"
new=0 stale=0 listed=0

while IFS= read -r f; do
  [ -n "$f" ] || continue
  if grep -qxF "$f" <<< "$known"; then
    listed=$((listed + 1))
    if ! has_portuguese "$ROOT/$f" >/dev/null; then
      printf '  FAIL  stale allowlist entry: %s is already clean — drop the line\n' "$f" >&2
      stale=$((stale + 1))
    fi
  elif hits="$(has_portuguese "$ROOT/$f")"; then
    printf '  FAIL  Portuguese outside the allowlist: %s\n' "$f" >&2
    head -5 <<< "$hits" | sed 's/^/          /' >&2
    new=$((new + 1))
  fi
done <<< "$files"

fails=$((new + stale))
echo
if [ "$fails" -eq 0 ]; then
  printf '  ok    %d of %d surface path(s) still in the allowlist, 0 new\n' "$listed" "$n_surface"
  exit 0
fi
printf '%d language check(s) failed\n' "$fails" >&2
exit 1
