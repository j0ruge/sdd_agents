#!/usr/bin/env bash
# Sensor for the hat's boundary DECLARATIONS — the frontmatter of agents/sdd-*.md.
#
# Every hat carries three keys: `disallowedTools:` (what it denies beyond HAT_DENY_BASE — a
# harness key), `writes:` (globs of what the phase may have touched when it ends — a kit key) and
# `mcp:` (MCP servers it may see — a kit key; empty ⇒ --strict-mcp-config). The runner reads them
# with frontmatter() and applies them by flag (bin/sdd: hat_disallowed, hat_writes, hat_mcp);
# what this file measures is the DECLARATION, because a hat that declares nothing is a hat that
# gets everything, silently. Spec: docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md.
#
# Rules, each with a selftest probe below:
#   R1  every agents/sdd-*.md carries the three keys (present; empty is a legal value)
#   R2  every `$name` in `writes:` is one of the placeholders the runner expands — an unknown one
#       would never match a path and the whole hat would read as "writes nowhere"
#   R3  every `disallowedTools:` item is `Name` or `Name(pattern)` — a stray quote or a bare `(`
#       is a token the harness would neither deny nor refuse
# Floor: at least 8 hats on disk, or the glob stopped matching and this sensor reads nothing.
#
# This file measures markdown, so no sabotage of bin/sdd can make it die: it carries a selftest
# (`tests/check-hat.sh selftest`, rc 90 = a probe failed, 93 = the probe floor shrank), and the
# selftest exercises the REPORTING path through `--check <file>`, never the parser alone.
#
# Usage: tests/check-hat.sh              (exit 0 = every hat declares its boundary)
#        tests/check-hat.sh --check <f>  (one file, exit 1 on any violation — the selftest's path)
#        tests/check-hat.sh selftest
set -uo pipefail
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HAT_FLOOR=8
PLACEHOLDERS='HANDOFF_DIR|MISSION|TODO_FILE|QA_DOCS_PATH|E2E_DIR'
fails=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1" >&2; fails=$((fails + 1)); }

# fm_value <file> <key> — the frontmatter value, quotes stripped; prints the sentinel when absent
ABSENT='@absent@'
fm_value() {
  awk -v k="$2" -v absent="$ABSENT" '
    NR==1 && $0=="---" { inside=1; next }
    inside && $0=="---" { exit }
    inside {
      idx = index($0, ":"); if (idx == 0) next
      name = substr($0, 1, idx-1); gsub(/^[ \t]+|[ \t]+$/, "", name)
      if (name == k) { found = 1; val = substr($0, idx+1); gsub(/^[ \t]+|[ \t]+$/, "", val)
                       gsub(/^["'\'']|["'\'']$/, "", val); print val; exit }
    }
    END { if (!found) print absent }' "$1"
}

# check_file <agent file> — R1..R3 over one hat; prints one line per verdict, rc 1 on any FAIL
check_file() {
  local f="$1" name key v item bad=0
  name="$(basename "$f")"
  for key in disallowedTools writes mcp; do
    v="$(fm_value "$f" "$key")"
    if [ "$v" = "$ABSENT" ]; then fail "R1 $name: no '$key:' in the frontmatter"; bad=1; fi
  done
  v="$(fm_value "$f" writes)"
  if [ "$v" != "$ABSENT" ]; then
    while IFS= read -r item; do
      [ -n "$item" ] || continue
      if ! grep -qE "^($PLACEHOLDERS)\$" <<< "$item"; then
        fail "R2 $name: writes: names '\$$item', not a placeholder the runner expands ($PLACEHOLDERS)"; bad=1
      fi
    done <<< "$(grep -oE '\$[A-Za-z_][A-Za-z0-9_]*' <<< "$v" | sed 's/^\$//' || true)"
  fi
  v="$(fm_value "$f" disallowedTools)"
  if [ "$v" != "$ABSENT" ] && [ -n "$v" ]; then
    while IFS= read -r item; do
      item="${item#"${item%%[![:space:]]*}"}"; item="${item%"${item##*[![:space:]]}"}"
      [ -n "$item" ] || continue
      if ! grep -qE '^[A-Za-z][A-Za-z0-9_]*(\([^()"]+\))?$' <<< "$item"; then
        fail "R3 $name: disallowedTools item '$item' is not Name or Name(pattern)"; bad=1
      fi
    done <<< "$(tr ',' '\n' <<< "$v")"
  fi
  [ "$bad" -eq 0 ] && pass "$name declares disallowedTools, writes and mcp"
  return "$bad"
}

selftest() {
  local box PROBES=0 FAILS=0
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-hat-selftest-XXXXXX")"
  trap 'rm -rf "$box"' RETURN
  # probe <description> <expected rc> <file body> — through --check, the reporting path
  probe() {
    local desc="$1" want="$2" body="$3" got
    printf '%s\n' "$body" > "$box/sdd-probe.md"
    "$ROOT/tests/check-hat.sh" --check "$box/sdd-probe.md" >/dev/null 2>&1; got=$?
    PROBES=$((PROBES + 1))
    if [ "$got" = "$want" ]; then printf '  ok    %s\n' "$desc"
    else printf '  FAIL  %s (rc %s, wanted %s)\n' "$desc" "$got" "$want" >&2; FAILS=$((FAILS + 1)); fi
  }
  probe 'a hat with the three keys passes' 0 $'---\nname: x\ndisallowedTools: "Agent, Bash(git push:*)"\nwrites: "$HANDOFF_DIR/$MISSION/**, $TODO_FILE"\nmcp: ""\n---\nbody'
  probe 'empty values are legal' 0 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without writes: fails' 1 $'---\nname: x\ndisallowedTools: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without mcp: fails' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\n---\nbody'
  probe 'R1: a hat without disallowedTools: fails' 1 $'---\nname: x\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R2: a placeholder with a digit ($E2E_DIR) is read whole — a regex stopping at the digit read it as $E' 0 $'---\nname: x\ndisallowedTools: ""\nwrites: "$E2E_DIR/**"\nmcp: ""\n---\nbody'
  probe 'R2: an unknown placeholder fails' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: "$HANDOFFS/**"\nmcp: ""\n---\nbody'
  probe 'R3: a stray quote in a deny item fails' 1 $'---\nname: x\ndisallowedTools: "Agent, \\"Bash(git push:*)"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R3: a bare pattern without a tool name fails' 1 $'---\nname: x\ndisallowedTools: "(git push:*)"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'negative control: a key AFTER the closing --- is body, not frontmatter' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\n---\nmcp: ""'
  if [ "$PROBES" -lt 10 ]; then printf '  probe floor shrank: %d < 10\n' "$PROBES" >&2; return 93; fi
  [ "$FAILS" -eq 0 ] || return 90
  printf '  ok    check-hat selftest: %d probes\n' "$PROBES"
}

case "${1:-}" in
  selftest) selftest; exit $? ;;
  --check)  check_file "$2"; exit $? ;;
esac

n=0
for f in "$ROOT"/agents/sdd-*.md; do
  [ -e "$f" ] || continue
  n=$((n + 1))
  check_file "$f" || true
done
if [ "$n" -lt "$HAT_FLOOR" ]; then
  printf '  hat surface shrank: %d agents/sdd-*.md, expected at least %d — did something move?\n' "$n" "$HAT_FLOOR" >&2
  exit 93
fi
selftest || exit $?
if [ "$fails" -eq 0 ]; then printf '  ok    %d hat(s) declare their boundary\n' "$n"; exit 0; fi
printf '%d hat check(s) failed\n' "$fails" >&2
exit 1
