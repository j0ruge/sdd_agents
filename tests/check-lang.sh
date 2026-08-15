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

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLOWLIST="$ROOT/tests/lang-allowlist.txt"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-lang-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# The English surface. templates/ and config/examples/ are absent on purpose: they are content
# in OUTPUT_LANG, not kit surface. So are TODO.md, KAIZEN_LOG.md, CLAUDE.md and docs/handoffs/.
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
      docs/pipeline.md docs/failure-modes.md README.md \
      config/schema.md config/starter.conf \
      tests/*.sh tests/health-baseline.txt tests/lang-allowlist.txt 2>/dev/null ) \
    | grep -vxF -e 'tests/check-lang.sh' -e 'tests/check-templates.sh'
}

# Accent-free Portuguese function words. `todo`/`toda` are deliberately absent: they would match
# TODO.md and `# TODO`. Measured against a real English markdown file: zero false positives.
STOPWORDS='falta|sem|para|pelo|pela|quando|onde|nada|este|esta|isso|pois|cada|apenas|ainda|depois|antes|porque|assim|sobre|mesmo|outro|outra|nao|entao'

# has_portuguese <file> — prints the offending lines, returns 0 when it found any.
#
# Two proxies, because either alone is blind: the accent class misses "falta o handoff", the word
# list misses "sessão". The accent class is Latin-1 letters only — a blanket non-ASCII test would
# fire on ✅ ✗ → ⇒ ▸ · │ ⚠️ —, which the kit uses on nearly every page.
has_portuguese() {
  local f="$1" hits
  [ -f "$f" ] || return 1
  hits="$( { grep -nP '[\x{00C0}-\x{00FF}]' "$f" || true
             grep -nwiE "$STOPWORDS" "$f" || true; } | sort -t: -k1,1n -u )"
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
  printf 'The session is not an artifact - see the checklist.\n' > "$t"
  if has_portuguese "$t" >/dev/null; then
    echo "SENSOR-BROKEN: clean English flagged as Portuguese" >&2; exit 92
  fi
}

selftest
echo "  ok    self-test: the sensor detects Portuguese and clears English"

files="$(surface)"

# Explicit floor, same reason as the "exactly 7 gates" floor in cmd_health: a glob that stops
# matching (a renamed directory, a moved file) would leave the loop with nothing to read and the
# check would report "0 new" — clean by vacuity. 24 paths today; the floor moves only on purpose.
n_surface="$(grep -c . <<< "$files")"
if [ "$n_surface" -lt 24 ]; then
  printf '  FAIL  surface shrank to %d path(s), expected at least 24 — did something move?\n' \
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
  elif has_portuguese "$ROOT/$f" > "$WORK/hits"; then
    printf '  FAIL  Portuguese outside the allowlist: %s\n' "$f" >&2
    head -5 "$WORK/hits" | sed 's/^/          /' >&2
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
