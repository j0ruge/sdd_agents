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
# Usage: tests/check-lang.sh                 (exit 0 = surface whole, clean, and allowlist honest)
#        tests/check-lang.sh --census <root>  (the surface patterns and the docs/ census alone, over
#                                              one tree, no selftest — what the selftest drives)
#
# Exit codes: 0 clean · 1 Portuguese outside the allowlist, or a stale entry · 90/91/92/95/98 a
# selftest probe failed · 93 a surface pattern matches nothing, or the census read nothing · 94 the
# allowlist is missing · 96 unknown option · 97 a tracked docs/ file is on no surface and under no
# declared subtree.

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF_PATH="$ROOT/tests/$(basename "${BASH_SOURCE[0]}")"
ALLOWLIST="$ROOT/tests/lang-allowlist.txt"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sdd-lang-XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# The English surface. templates/ and config/examples/ are absent on purpose: they are content
# in OUTPUT_LANG, not kit surface. So are TODO.md, KAIZEN_LOG.md, CLAUDE.md and the three docs/
# subtrees of LANG_DECLARED below — docs/handoffs/, docs/qa/ and docs/superpowers/.
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
# the script pure English logic. ⚠️ DECLARED LIMIT (D15), moved here from TODO.md in
# 20261003-lote-3-a-catraca-desce: neither file fails open — the exclusion is explicit, listed here
# and in CLAUDE.md § Idioma, and no consumer outside the kit reads the prose of either.
#
# The surface is ONE list of patterns, read by surface() and by the floor in census(). `docs/*.md` is
# a glob since ADR 0015 §4: the list used to ENUMERATE the docs, and docs/plan-only.md was born
# outside it, carrying a pt-BR block while this file printed `0 of 56`. `commands/*.md` joined in the
# same commit: commands/sdd-plan.md is the kit's /sdd-plan, and its "verbatim" message was pt-BR.
SURFACE_SPECS=(bin/sdd bin/sdd-link-agents bin/sdd-coordination.py 'agents/sdd-*.md'
  '.claude/agents/sdd-*.md' 'commands/*.md' 'docs/*.md' 'docs/adr/*.md' README.md config/schema.md
  config/starter.conf 'tests/*.sh' tests/health-baseline.txt tests/lang-allowlist.txt)
# The docs/ subtrees that are content in OUTPUT_LANG, not kit surface (CLAUDE.md § Idioma) — the
# same three `health --release` in bin/sdd leaves out of its line 5. The two lists answer different
# questions (language here, client identifiers there) and nothing asserts their parity: declared.
LANG_DECLARED=(docs/handoffs/ docs/qa/ docs/superpowers/)

surface() { # surface <root> — one path per line, relative to root
  local root="$1"
  ( CDPATH='' cd -- "$root" 2>/dev/null || exit 0
    local spec
    for spec in "${SURFACE_SPECS[@]}"; do compgen -G "$spec" || true; done ) \
    | grep -vxF -e 'tests/check-lang.sh' -e 'tests/check-templates.sh'
}

# census <root> — the surface is WHOLE, which a count cannot say. Two halves, both derived:
#   - the floor: every pattern of SURFACE_SPECS matches at least one file. A renamed directory or a
#     moved file empties its pattern, which is the vacuity the old hand-written floor guarded —
#     without a number to fall behind (it lagged in 57 of 124 commits, 9 of 11 steps a new ADR);
#   - the census: every docs/**/*.md that git TRACKS is on the surface or under LANG_DECLARED. A new
#     subtree, or a pattern narrowed back to a list of names, leaves a tracked doc belonging nowhere.
# DECLARED LIMIT: deleting a non-docs pattern from SURFACE_SPECS is a diff on the definition and
# nothing here refuses it; the old floor refused it only while it had no slack. An untracked doc is
# not counted either — it is not the kit until it is committed.
# It PUBLISHES the surface it checked in SURFACE_FILES (a global, so it is called and never read
# through $(…)), and the scan below reads that and nothing else: deleting the call leaves the scan
# reading an unset variable under `set -u`, which is a loud red, not a scan without a census.
census() { # 0 whole; 93 a pattern matches nothing, or the census read nothing; 97 a doc belongs nowhere
  local root="$1" spec files tracked f d n_on=0 n_decl=0 bad=0
  for spec in "${SURFACE_SPECS[@]}"; do
    if ! ( CDPATH='' cd -- "$root" 2>/dev/null && compgen -G "$spec" >/dev/null ); then
      printf '  FAIL  surface pattern %s matches nothing — did something move?\n' "$spec" >&2
      return 93
    fi
  done
  files="$(surface "$root")"
  # A git pathspec `*` crosses `/`, so this is every tracked .md under docs/, at any depth.
  tracked="$(git -C "$root" ls-files -- 'docs/*.md' 2>/dev/null)" || tracked=''
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    for d in "${LANG_DECLARED[@]}"; do
      case "$f" in "$d"*) n_decl=$((n_decl + 1)); continue 2 ;; esac
    done
    if grep -qxF -- "$f" <<< "$files"; then n_on=$((n_on + 1)); continue; fi
    printf '  FAIL  census: %s is tracked but on no surface and under no declared subtree (%s)\n' \
      "$f" "${LANG_DECLARED[*]}" >&2
    bad=$((bad + 1))
  done <<< "$tracked"
  if [ "$n_on" -eq 0 ]; then
    printf '  FAIL  census: no tracked docs/*.md on the surface — is %s a git checkout?\n' "$root" >&2
    return 93
  fi
  [ "$bad" -eq 0 ] || return 97
  SURFACE_FILES="$files"
  printf '  ok    census: every tracked docs/**/*.md is on the surface or under a declared subtree (%d on the surface, %d declared)\n' \
    "$n_on" "$n_decl"
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
  census_selftest
}

# census_says <want_rc> <want_text> <tree> <label> — the real --census path, in a CHILD, over a tree
# that is its own git checkout. GIT_CEILING_DIRECTORIES keeps git from climbing out of the work dir
# into whatever repository TMPDIR happens to sit in.
CENSUS_PROBES=0
census_says() {
  local out rc
  CENSUS_PROBES=$((CENSUS_PROBES + 1))
  out="$(GIT_CEILING_DIRECTORIES="$WORK" bash "$SELF_PATH" --census "$3" 2>&1)"; rc=$?
  if [ "$rc" -ne "$1" ] || ! grep -qF -- "$2" <<< "$out"; then
    printf 'SENSOR-BROKEN: census probe "%s" wanted rc %s and "%s", got rc %s:\n%s\n' \
      "$4" "$1" "$2" "$rc" "$out" >&2
    exit 98
  fi
}

# census_tree <root> — a checkout every SURFACE_SPECS pattern matches once, DERIVED from the list so a
# new pattern needs no fixture edit; plus docs/a.md, written BY HAND: the witness that a docs/ file
# is on the surface by the glob, which a fixture derived from the list would agree with in lockstep.
census_tree() {
  local root="$1" spec f
  for spec in "${SURFACE_SPECS[@]}"; do
    f="$root/${spec//\*/x}"; mkdir -p "$(dirname "$f")"; : > "$f"
  done
  : > "$root/docs/a.md"
  git -C "$root" init -q && git -C "$root" add -A
}

census_selftest() {
  local c="$WORK/census"
  census_tree "$c/whole"
  census_says 0 'census: every tracked docs/**/*.md is on the surface' "$c/whole" 'a whole tree passes'
  census_tree "$c/stray"; mkdir -p "$c/stray/docs/newtree"; : > "$c/stray/docs/newtree/y.md"
  git -C "$c/stray" add -A
  census_says 97 'docs/newtree/y.md is tracked but on no surface' "$c/stray" 'a doc in a new subtree is refused'
  census_tree "$c/decl"
  mkdir -p "$c/decl/docs/handoffs/m" "$c/decl/docs/qa" "$c/decl/docs/superpowers"
  : > "$c/decl/docs/handoffs/m/n.md"; : > "$c/decl/docs/qa/z.md"; : > "$c/decl/docs/superpowers/s.md"
  git -C "$c/decl" add -A
  census_says 0 '3 declared)' "$c/decl" 'each declared subtree is honoured'
  census_tree "$c/empty"; rm -rf "$c/empty/docs/adr"
  census_says 93 'surface pattern docs/adr/*.md matches nothing' "$c/empty" 'an emptied pattern bites'
  census_tree "$c/nogit"; rm -rf "$c/nogit/.git"
  census_says 93 'no tracked docs/*.md on the surface' "$c/nogit" 'a tree git does not track measured nothing'
  [ "$CENSUS_PROBES" -ge 5 ] || { echo "SENSOR-BROKEN: only $CENSUS_PROBES census probe(s) ran" >&2; exit 98; }
  # The negative control: the primitive itself, asked something false about a known world, has to
  # say so. Without it, census_says neutered to "always agree" leaves every probe above green.
  if ( census_says 0 'census: every tracked' "$c/stray" 'control' ) 2>/dev/null; then
    echo "SENSOR-BROKEN: census_says agreed with a wrong expectation — the census probes measure nothing" >&2
    exit 98
  fi
}

case "${1:-}" in
  # `${2-}` and a directory test: an empty root would `cd ""` into the cwd and certify whatever is there.
  --census) [ -n "${2-}" ] && [ -d "$2" ] || { printf '  FAIL  --census needs a directory\n' >&2; exit 96; }
            census "$2"; exit $? ;;
  '') ;;
  *) printf '  FAIL  unknown option: %s (see the usage header)\n' "$1" >&2; exit 96 ;;
esac

selftest
echo "  ok    self-test: the sensor detects Portuguese, clears English, and reads a traceability line as data"
echo "  ok    self-test: the census refuses a tracked doc outside the surface and every declared subtree ($CENSUS_PROBES probe(s))"

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

# The floor is DERIVED (ADR 0015 §4): census() above demands that every surface pattern match a
# file and that every tracked doc belong somewhere, so there is no number here to move — and none
# to fall behind, which the hand-written one did in 57 of 124 commits.
census "$ROOT" || exit $?
files="$SURFACE_FILES"
n_surface="$(grep -c . <<< "$files")"

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
