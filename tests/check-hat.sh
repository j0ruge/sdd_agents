#!/usr/bin/env bash
# Sensor for the hat's boundary DECLARATIONS — the frontmatter of agents/sdd-*.md.
#
# Every hat carries four keys: `disallowedTools:` (tool NAMES it denies beyond HAT_DENY_BASE — a
# harness key, and the harness reads it), `permissionsDeny:` (permission RULES such as
# `Bash(git push:*)` — a kit key the runner passes on the CLI), `writes:` (globs of what the phase
# may have touched when it ends — a kit key) and `mcp:` (MCP servers it may see — a kit key; empty
# ⇒ --strict-mcp-config). The runner reads them with frontmatter() and applies them by flag
# (bin/sdd: hat_disallowed, hat_writes, hat_mcp); what this file measures is the DECLARATION,
# because a hat that declares nothing is a hat that gets everything, silently.
# Spec: docs/superpowers/specs/2026-09-03-a-fronteira-do-chapeu-design.md.
#
# Why two keys for one deny list, measured 2026-09-06 (Claude Code 2.1.263, five headless probes):
# `--agent` now honours the file's `disallowedTools:`, and the harness reads that key as tool
# names — `Bash(git push:*)` there removes `Bash` WHOLE from the session's tool list (the docs
# define the key as names plus `mcp__<server>` patterns; the rule syntax is the CLI's and the
# settings'). The first mission of the fourth window spent three TICKET sessions, US$ 3,39, in
# sessions that had no Bash at all. The same rule on the CLI flag keeps Bash and denies the push,
# so a rule lives in `permissionsDeny:` and never in `disallowedTools:`; R3 and R4 are that line.
#
# Rules, each with a selftest probe below:
#   R1  every agents/sdd-*.md carries the four keys (present; empty is a legal value)
#   R2  every `$name` in `writes:` is one of the placeholders the runner expands — an unknown one
#       would never match a path and the whole hat would read as "writes nowhere"
#   R3  every `disallowedTools:` item is a bare `Name` or an `mcp__server` / `mcp__server__*`
#       pattern — a `Name(pattern)` there strips `Name` from the session (see above), and a stray
#       quote or a bare `(` is a token the harness would neither deny nor refuse
#   R4  every `permissionsDeny:` item is `Name(pattern)` — a bare name there is a tool, not a
#       rule, and it belongs in `disallowedTools:` where the harness also enforces it
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
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HAT_FLOOR=8
PLACEHOLDERS='HANDOFF_DIR|MISSION|TODO_FILE|QA_DOCS_PATH|E2E_DIR|ADR_DIR'
fails=0
pass() { printf '  ok    %s\n' "$1"; }
# Inside a mutant the first red assertion is the verdict: fail() ends the sensor there, AFTER
# printing, so the mutant's log still names it. The census in check-health.sh holds all nine.
fail() { printf '  FAIL  %s\n' "$1" >&2; fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }
# That exit can land inside a probe function, before the `rm -rf "$box"` at its tail: measured on
# the health of 2026-09-25, each of the 14 mutants this sensor kills left its box in /tmp. Every box
# is registered here as well, and the EXIT trap removes whatever a stopped probe left behind.
PROBE_BOXES=()
trap 'rm -rf ${PROBE_BOXES[@]+"${PROBE_BOXES[@]}"}' EXIT

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
  for key in disallowedTools permissionsDeny writes mcp; do
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
      if grep -qE '^[A-Za-z][A-Za-z0-9_]*\([^()"]+\)$' <<< "$item"; then
        fail "R3 $name: disallowedTools item '$item' is a permission rule — the harness reads this key as tool names and would strip '${item%%(*}' whole; move it to permissionsDeny:"; bad=1
      elif ! grep -qE '^[A-Za-z][A-Za-z0-9_]*(__\*)?$' <<< "$item"; then
        fail "R3 $name: disallowedTools item '$item' is not a tool name or an mcp__server pattern"; bad=1
      fi
    done <<< "$(tr ',' '\n' <<< "$v")"
  fi
  v="$(fm_value "$f" permissionsDeny)"
  if [ "$v" != "$ABSENT" ] && [ -n "$v" ]; then
    while IFS= read -r item; do
      item="${item#"${item%%[![:space:]]*}"}"; item="${item%"${item##*[![:space:]]}"}"
      [ -n "$item" ] || continue
      if ! grep -qE '^[A-Za-z][A-Za-z0-9_]*\([^()"]+\)$' <<< "$item"; then
        fail "R4 $name: permissionsDeny item '$item' is not Name(pattern) — a bare name is a tool and belongs in disallowedTools:"; bad=1
      fi
    done <<< "$(tr ',' '\n' <<< "$v")"
  fi
  [ "$bad" -eq 0 ] && pass "$name declares disallowedTools, permissionsDeny, writes and mcp"
  return "$bad"
}

selftest() {
  local box PROBES=0 FAILS=0
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-hat-selftest-XXXXXX")"
  trap 'rm -rf "$box"' RETURN
  # probe <description> <expected rc> <file body> [<needle>] — through --check, the reporting
  # path. The optional needle has to appear in what --check printed: a verdict alone cannot tell
  # the branch that NAMES the repair from the one that only refuses, and the R3 rule branch is
  # exactly that — drop it and `Bash(git push:*)` still fails, as "not a tool name", which sends
  # the reader to fix the spelling of the one item whose spelling is right (sabotage measured).
  probe() {
    local desc="$1" want="$2" body="$3" needle="${4-}" got out
    printf '%s\n' "$body" > "$box/sdd-probe.md"
    # Outside a mutant on purpose: this child measures the report a human reads, every rule named.
    out="$(env -u SDD_MUTANT "$ROOT/tests/check-hat.sh" --check "$box/sdd-probe.md" 2>&1)"; got=$?
    PROBES=$((PROBES + 1))
    local named=1
    if [ -n "$needle" ] && ! grep -qF -- "$needle" <<< "$out"; then named=0; fi
    if [ "$got" = "$want" ] && [ "$named" -eq 1 ]; then
      printf '  ok    %s\n' "$desc"
    else printf '  FAIL  %s (rc %s, wanted %s%s)\n' "$desc" "$got" "$want" \
           "${needle:+, and the output had to name: $needle}" >&2; FAILS=$((FAILS + 1)); fi
  }
  probe 'a hat with the four keys passes' 0 $'---\nname: x\ndisallowedTools: "Agent, Monitor"\npermissionsDeny: "Bash(git push:*), Bash(gh pr merge:*)"\nwrites: "$HANDOFF_DIR/$MISSION/**, $TODO_FILE"\nmcp: ""\n---\nbody'
  probe 'empty values are legal' 0 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without writes: fails' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without mcp: fails' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nwrites: ""\n---\nbody'
  probe 'R1: a hat without disallowedTools: fails' 1 $'---\nname: x\npermissionsDeny: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R1: a hat without permissionsDeny: fails — the key the rules moved to has to exist to be read' 1 $'---\nname: x\ndisallowedTools: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R2: a placeholder with a digit ($E2E_DIR) is read whole — a regex stopping at the digit read it as $E' 0 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nwrites: "$E2E_DIR/**"\nmcp: ""\n---\nbody'
  probe 'R2: an unknown placeholder fails' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nwrites: "$HANDOFFS/**"\nmcp: ""\n---\nbody'
  probe 'R2: $ADR_DIR is a placeholder the runner expands' 0 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nwrites: "$ADR_DIR/**"\nmcp: ""\n---\nbody'
  probe 'R3: a permission rule in disallowedTools fails — it would strip the tool whole (measured, 2.1.263)' 1 $'---\nname: x\ndisallowedTools: "Agent, Bash(git push:*)"\npermissionsDeny: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R3: ...and the verdict names the repair, not a misspelling' 1 $'---\nname: x\ndisallowedTools: "Agent, Bash(git push:*)"\npermissionsDeny: ""\nwrites: ""\nmcp: ""\n---\nbody' "would strip 'Bash' whole; move it to permissionsDeny:"
  probe 'R3: an mcp__server__* pattern is a legal name' 0 $'---\nname: x\ndisallowedTools: "mcp__github, mcp__atlassian__*"\npermissionsDeny: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R3: a stray quote in a deny item fails' 1 $'---\nname: x\ndisallowedTools: "Agent, \\"Monitor"\npermissionsDeny: ""\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R4: a bare name in permissionsDeny fails — a tool is not a rule' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: "Bash(git push:*), Agent"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R4: a bare pattern without a tool name fails' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: "(git push:*)"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'R4: a stray quote in a rule fails' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: "\\"Bash(git push:*)"\nwrites: ""\nmcp: ""\n---\nbody'
  probe 'negative control: a key AFTER the closing --- is body, not frontmatter' 1 $'---\nname: x\ndisallowedTools: ""\npermissionsDeny: ""\nwrites: ""\n---\nmcp: ""'
  if [ "$PROBES" -lt 17 ]; then printf '  probe floor shrank: %d < 17\n' "$PROBES" >&2; return 93; fi
  [ "$FAILS" -eq 0 ] || return 90
  printf '  ok    check-hat selftest: %d probes\n' "$PROBES"
}

# --- sdd boot: the boot prompt is an artifact, so it is asserted like one -----------------------
# Until 20260904-a-dieta-de-contexto `boot_prompt()` had ONE caller (`run_phase`), so the only way
# to see what a phase is told was to spend a session, and the only way to assert on it was to
# rebuild the prompt by hand — the fixture-from-memory that CLAUDE.md forbids and that has already
# cost this kit three gate bugs. `sdd boot` made the real thing readable, and these probes read it.
boot_probes() {
  local box out out2 mdir
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-boot-XXXXXX")"
  PROBE_BOXES+=("$box")
  mdir="$box/docs/handoffs/20260101-n"
  mkdir -p "$mdir" "$box/.sdd"
  ( cd "$box" && git init -q -b main . ) >/dev/null 2>&1
  printf 'PROJECT_NAME="n"\nDEFAULT_BRANCH="main"\nTEST_CMD="true"\nHANDOFF_DIR="docs/handoffs"\n' > "$box/.sdd/config.sh"
  : > "$mdir/00-missao.md"; : > "$mdir/01-plano.md"
  printf '| ID | Incremento | Check | Status | Commit |\n' > "$mdir/checkpoint.md"
  awk 'BEGIN{for(i=1;i<=30;i++) printf "- 2026-01-01 · I%d · NOTA_NUMERO_%02d\n", i, i}' > "$mdir/checkpoint-notas.md"
  out="$( cd "$box" && SDD_HOME="$ROOT" "$ROOT/bin/sdd" boot 20260101-n EXEC 2>&1 )" || true

  # BOTH terms, and neither alone is the assertion. "Ten notes" alone passes on a boot that inlines
  # the FIRST ten — the wrong end, and the one a tail written as `head` would give. "Not the first"
  # alone passes on a boot that inlines nothing at all.
  if [ "$(grep -c 'NOTA_NUMERO_' <<< "$out")" = 10 ] && grep -q 'NOTA_NUMERO_30' <<< "$out" \
       && ! grep -q 'NOTA_NUMERO_01' <<< "$out"; then pass "boot: exactly the last 10 notes are inlined, and not the first"
  else fail "boot: wanted 10 notes ending at 30 — got $(grep -c 'NOTA_NUMERO_' <<< "$out"), first present: $(grep -q 'NOTA_NUMERO_01' <<< "$out" && echo yes || echo no)"; fi
  if grep -q 'Do NOT read' <<< "$out"; then pass "boot: and the session is told not to open the notes file"
  else fail "boot: the do-not-read instruction is missing — inlining without it just adds a second copy"; fi

  # The differential, and the bug it was written against: the qualifier on item 3 was
  # unconditional for one commit, which made the prompt tell EVERY mission in flight that its notes
  # had moved while they sat in the very file item 3 sends it to read. A mission from before the
  # split has to come out of here indistinguishable from what it got yesterday.
  rm -f "$mdir/checkpoint-notas.md"
  out2="$( cd "$box" && SDD_HOME="$ROOT" "$ROOT/bin/sdd" boot 20260101-n EXEC 2>&1 )" || true
  if grep -qE '^  3\..*NOT in it' <<< "$out" && ! grep -qE '^  3\.' <<< "$(grep 'NOT in it' <<< "$out2")"; then
    pass "boot: item 3 claims the notes moved only when they did — a pre-split mission is not lied to"
  else fail "boot: item 3 qualifier is not conditional on the notes file"; fi
  # One grep and one alternation, not two greps joined by `||`: RULE 1 of check-pipefail.sh reads
  # the second `|` of a logical or as a pipe into `grep -q` and refuses the line. Declared limit,
  # written in that sensor's header — the shape below is the one the rule was built for anyway.
  if grep -qE 'NOTA_NUMERO_|Do NOT read' <<< "$out2"; then
    fail "boot: a pre-split mission got a notes block it has no file for"
  else pass "boot: and a pre-split mission gets no notes block at all"; fi
  # --- item 4: the runner resolves the handoff and inlines two sections of it ---
  # Three terms, and none of them is the assertion alone. "Names the file" alone passes on a boot
  # that names it and then inlines the whole thing; "inlines the TL;DR" alone passes on a boot that
  # inlines everything; "does not carry the ignored section" alone passes on a boot that inlines
  # nothing at all. The mutants BOOT_handoff_not_named and BOOT_handoff_whole_file both survived a
  # suite that had only the first two ideas in it.
  local out4
  { printf '## TL;DR\n\nINLINED_MARKER\n\n## Evidence\n\nNOT_INLINED_MARKER\n'; } \
    > "$mdir/20-handoff-exec.md"
  out4="$( cd "$box" && SDD_HOME="$ROOT" "$ROOT/bin/sdd" boot 20260101-n EXEC 2>&1 )" || true
  if grep -q '20-handoff-exec.md' <<< "$out4"; then pass "boot: item 4 names the handoff instead of leaving the session to find it"
  else fail "boot: the handoff is not named in the prompt"; fi
  if grep -q 'INLINED_MARKER' <<< "$out4"; then pass "boot: and inlines its TL;DR"
  else fail "boot: the TL;DR is not inlined"; fi
  if grep -q 'NOT_INLINED_MARKER' <<< "$out4"; then fail "boot: the whole handoff was inlined — the rest of the file is evidence, not boot"
  else pass "boot: and carries none of the sections it only points at"; fi

  # --- item 6: the templates of THIS phase, not the directory ---
  # Differential across two phases of the same mission, which is the only shape that separates
  # "names the phase's templates" from "names a fixed subset" or "names them all": the file each
  # one must have is the file the other must not.
  local out5
  out5="$( cd "$box" && SDD_HOME="$ROOT" "$ROOT/bin/sdd" boot 20260101-n REVIEW 2>&1 )" || true
  # The first term is not decoration: the fallback arm names the DIRECTORY and lists nothing, so
  # "review.md is absent" is true there too — the mutant BOOT_templates_whole_dir escaped a probe
  # that had only the absence in it. What separates the two worlds is that item 6 NAMES files.
  if grep -q 'templates this phase writes from' <<< "$out4" && grep -q 'checkpoint\.md' <<< "$out4" \
       && ! grep -q 'review\.md' <<< "$out4"; then pass "boot: item 6 names the EXEC templates and not the reviewer's"
  else fail "boot: EXEC item 6 is wrong — named: $(grep -c 'this phase writes from' <<< "$out4"), review.md: $(grep -c 'review\.md' <<< "$out4")"; fi
  if grep -q 'templates this phase writes from' <<< "$out5" && grep -q 'review\.md' <<< "$out5" \
       && ! grep -q 'pr-body\.md' <<< "$out5"; then pass "boot: and the REVIEW templates and not the publisher's"
  else fail "boot: REVIEW item 6 is wrong — named: $(grep -c 'this phase writes from' <<< "$out5"), pr-body.md: $(grep -c 'pr-body\.md' <<< "$out5")"; fi
  rm -rf "$box"
}

# --- the executor and the Agent tool ------------------------------------------------------------
# `Agent` is deliberately NOT in HAT_DENY_BASE, and the reason is a single hat: the reviewer's
# codereview skill dispatches subagents. The executor's prompt used to ask for them too, and
# `sdd census` measured `Agent=0` across 27 EXEC sessions of two missions — the phrase came out in
# 20260904-a-dieta-de-contexto and the executor now denies the tool by name.
#
# Differential on purpose. "The executor denies Agent" alone would stay green if someone closed the
# hole by putting Agent into HAT_DENY_BASE, which is the one fix that silently breaks the reviewer;
# "the reviewer allows Agent" alone would stay green if the executor's line rotted away. Only the
# pair says what the design actually is. The catalogue cannot reach either half — it sabotages
# bin/sdd and this lives in agents/*.md — so this probe is the whole sensor, and that limit is
# declared here rather than left silent. It covers every probe of this function, the two text
# probes of the executor added in 20261004-lote-4-a-catraca-zera included: each was proved by a
# sabotage pass over agents/sdd-executor.md, recorded in that mission's plan, not by the catalogue.
executor_agent_probes() {
  local ex="$ROOT/agents/sdd-executor.md" rv="$ROOT/agents/sdd-reviewer.md"
  if grep -qE '^disallowedTools:.*(^|[ ,"])Agent([,"]|$)' "$ex"; then pass "hat: the executor denies Agent — the census measured 0 uses in 27 EXEC sessions"
  else fail "hat: sdd-executor no longer denies Agent"; fi
  if grep -qE '^disallowedTools:.*(^|[ ,"])Agent([,"]|$)' "$rv"; then fail "hat: sdd-reviewer denies Agent — its codereview skill dispatches subagents and would break"
  else pass "hat: and the reviewer still may use it, which is why Agent is not in HAT_DENY_BASE"; fi
  if grep -qi 'subagent' "$ex"; then fail "hat: the executor prompt still asks for subagents while the tool is denied"
  else pass "hat: and the executor prompt no longer asks for what it cannot do"; fi
  # Issue 180: gate_EXEC reads 7–64 hex digits in the Commit cell, so an act outside git (an e-mail,
  # a KB page) needs a RECORD commit to point at; issue 218: a step after the merge or inside an
  # external window is not a row the executor can close. Both halves, because the planner is told
  # the same and the executor is who meets the legacy row the planner wrote before the rule.
  if grep -qF 'record-<ID>.md' "$ex" && grep -qF 'open questions for the human' "$ex"; then
    pass "hat: the executor commits a record for an act outside git, and hands a step it cannot close to the human"
  else fail "hat: sdd-executor no longer says how an act outside git reaches the Commit cell, or where a step it cannot close goes"; fi
  # Issue 194: the Red of an R<n> proves the finding, not the fix, and at least eight findings of
  # four missions were opened by the fix of the round before (3 code in this kit, 5 prose in
  # sales_quote). The step is read as a BLOCK, from its numbered heading to the next one, and each
  # of its three parts has to be inside it: the R<n> scope ON THE HEADING (the block names R<n>
  # again in its prose sentence, so a block-wide grep answered for a step that lost its scope —
  # sabotage measured), the sabotage note in checkpoint-notas.md (a name the file also uses in its
  # section 5, so a whole-file grep would answer for a step that lost it), and the re-read of the
  # whole paragraph for an R<n> of prose.
  local sab
  sab="$(awk '/^[0-9]+\. \*\*Sabotage/ { on = 1; print; next } on && /^[0-9]+\. \*\*/ { on = 0 } on' "$ex")"
  if grep -qF 'only in an `R<n>`' <<< "${sab%%$'\n'*}" && grep -qF 'checkpoint-notas.md' <<< "$sab" \
     && grep -qF 'whole paragraph' <<< "$sab"; then
    pass "hat: the executor sabotages the new line of an R<n>, notes it, and re-reads the paragraph of a prose fix"
  else fail "hat: sdd-executor lost the sabotage step of an R<n> (its scope, its note in checkpoint-notas.md, or the prose re-read)"; fi
  # Codex on sales_quote#416 (2026-10-07): the sabotage step came BEFORE the refactor, so a refactor
  # that rewrote the fix's lines committed code no sabotage had degraded. The order is read from the
  # numbered headings of the TDD section — Refactor, then Sabotage, then Commit — and the scope is read
  # from the IMPERATIVE, not from a slogan beside it (Codex on #243: "each line the fix added" left out
  # the lines the refactor changed and the ones the diff deletes, under a sentence that promised the
  # whole commit): every line the final diff adds or changes, and every line it deletes, put back.
  local nref nsab ncom
  nref="$(awk '/^[0-9]+\. \*\*Refactor/ { print NR; exit }' "$ex")"
  nsab="$(awk '/^[0-9]+\. \*\*Sabotage/ { print NR; exit }' "$ex")"
  ncom="$(awk '/^[0-9]+\. \*\*Commit/ { print NR; exit }' "$ex")"
  if [ -n "$nref" ] && [ -n "$nsab" ] && [ -n "$ncom" ] && [ "$nref" -lt "$nsab" ] && [ "$nsab" -lt "$ncom" ] \
     && grep -qF 'each line the final diff adds or changes' <<< "$sab" && grep -qF 'each line it deletes' <<< "$sab"; then
    pass "hat: the executor sabotages an R<n> after the refactor, every line the final diff adds, changes or deletes"
  else fail "hat: sdd-executor sabotages an R<n> before its refactor, or no longer every line the final diff adds, changes or deletes (Codex on sales_quote#416 and #243)"; fi
}

# One hat promised a measurement nobody makes, and another was silent where its boundary needed a
# sentence; the next session reads a hat's promise as a fact and its silence as permission. Asserted
# HERE because neither half lives in bin/sdd, so the catalogue cannot reach it — the same limit as
# executor_agent_probes, declared the same way; the sabotage pass that proves each probe is in the
# plan of 20261004-lote-4-a-catraca-zera.
#   - issue 178: sdd-ticket said the runner confirms the issue "through acli"; gate_TICKET reads
#     10-ticket.md and never asks Jira (its own comment says why). Refuted on the sentence that
#     makes the runner or the gate the subject of acli — the hat legitimately names `acli
#     --from-json`, the skill's tool, and the `gate:` evidence key of 10-ticket.md carries the
#     skill's own read-back — and asserted on what the gate does, so dropping both passes nothing.
#   - issue 135: a drifted code comment has an owner — R<n>, a proposed-text row, or the TODO file —
#     and it is never the DOCS phase's own edit, which hat_guard_check would stop as hat-crossed.
hat_promise_probes() {
  local tk="$ROOT/agents/sdd-ticket.md" dc="$ROOT/agents/sdd-docs.md"
  if grep -qiE '(the runner|the gate|gate_TICKET)[^.]*acli' "$tk" || ! grep -qF 'never asks Jira' "$tk"; then
    fail "hat: sdd-ticket promises a Jira check the gate does not make, or no longer says that gate_TICKET reads only 10-ticket.md"
  else pass "hat: the ticket hat promises no Jira check the gate does not make"; fi
  if grep -qF 'A comment in the code belongs to the code' "$dc" && grep -qE 'R<n>.*batch' "$dc"; then
    pass "hat: the docs hat leaves a code comment to the code's own phase (R<n>, a proposed-text row, or the TODO file)"
  else fail "hat: sdd-docs no longer says who owns a drifted code comment"; fi
}

# --- /sdd-plan: the approval is the human's answer to a YES/NO question -------------------------
# The human asked for it in the grill of 20261004-lote-4-a-catraca-zera: approving a plan used to
# mean reading "sdd approve <mission>" off the screen and typing it. `sdd approve` reads its `y`
# from stdin and cannot tell who typed it, so the guarantee lives in the command's prose, and this
# probe is the whole sensor for it: the catalogue sabotages bin/sdd, never commands/*.md. It reads
# the section, not the file, so a rule moved out of "When the artifacts exist" is a rule lost.
command_approval_probes() {
  local cmd="$ROOT/commands/sdd-plan.md" sec
  sec="$(awk '/^## When the artifacts exist/{s=1; next} s && /^## /{s=0} s' "$cmd")"
  # The plan is SHOWN before the question (CodeRabbit review of PR #222): a YES to a plan nobody put
  # in front of the human approves what the relay summarised, not what the gates will run.
  if grep -qF 'first show the human what they are approving' <<< "$sec" \
     && grep -q 'AskUserQuestion' <<< "$sec" \
     && grep -qE '^ *- \*\*YES\*\* .*sdd approve <mission>' <<< "$sec" \
     && grep -qE '^ *- \*\*NO\*\*' <<< "$sec" \
     && grep -qF "Only the human's answer to that question approves" <<< "$sec"; then
    pass "command: /sdd-plan asks the human YES or NO before it runs sdd approve"
  else
    fail "command: /sdd-plan no longer shows the plan and asks YES or NO before sdd approve, or lost the rule that only the human's answer approves"
  fi
}

# --- /sdd-plan: what the relay commits, and what it holds back -----------------------------------
# Two gaps measured in the grill of 20261006-lote-5-o-que-o-lote-4-deixou, both living only in the
# command's prose — so, like command_approval_probes above, this probe is their whole sensor:
#   - `sdd approve` commits the mission directory and the adr: file, never the two paths
#     HAT_WRITES_BASE opens to every hat ($TODO_FILE and tests/health-baseline.txt). Two findings
#     registered during that grill were still ` M TODO.md` after the approval, the ratchet unmoved.
#   - the planner ends EVERY turn with a question, so a relay message that answers nothing makes it
#     ask again — and the second asking came back with the recommended option of question 5
#     swapped, after the human had answered the first. The relay holds such a message for the next
#     answer, and hands an answer back by the option's text, which survives a reordering.
# Read by section, for the reason command_approval_probes gives: a rule moved out of its section is
# a rule lost.
command_relay_probes() {
  local cmd="$ROOT/commands/sdd-plan.md" art relay
  art="$(awk '/^## When the artifacts exist/{s=1; next} s && /^## /{s=0} s' "$cmd")"
  relay="$(awk '/^## Relaying the grill to the human/{s=1; next} s && /^## /{s=0} s' "$cmd")"
  # The two paths are demanded INSIDE the status command, not anywhere in the section: the section
  # names tests/health-baseline.txt three times, and the sabotage pass measured a presence check
  # surviving the removal of the one occurrence that is the instruction. `todo-findings` is the
  # ratchet line the commit must move; `commit nothing` is the branch the relay must not commit on.
  if grep -qF 'What `sdd approve` does not commit' <<< "$art" \
     && grep -qE 'git status --porcelain -- .*<TODO_FILE> tests/health-baseline\.txt' <<< "$art" \
     && grep -qF 'todo-findings' <<< "$art" \
     && grep -qE '^ *- \*\*Anywhere else\*\* .*commit nothing' <<< "$art"; then
    pass "command: /sdd-plan commits what sdd approve leaves behind"
  else
    fail "command: /sdd-plan no longer says who commits the TODO_FILE findings and the ratchet that sdd approve leaves uncommitted"
  fi
  if grep -qF "by the option's text, never by its position" <<< "$relay" \
     && grep -qF 'Nothing else resumes the planner while a question is pending' <<< "$relay"; then
    pass "command: /sdd-plan holds a relay message until the next answer"
  else
    fail "command: /sdd-plan lets a message that answers nothing resume the planner, or relays an answer by its position"
  fi
}

# --- /sdd-plan: a mission of the kit `sdd` runs from is written in a linked worktree (#235) -------
# The `sdd` on the PATH is the kit's main checkout, and kit_guard_check (bin/sdd) compares that
# checkout's HEAD and `git status --porcelain` around every phase of every target's run: an untracked
# 00-missao.md written there during a target's EXEC stopped the run with KIT-TOUCHED (rc 3),
# reproduced on a copy. A linked worktree, dirty or with commits, leaves the stamp as it was
# (measured: `89df2e5|false` before and after; the same file in the main checkout, `|true`). The
# rule lives in the command's prose and the catalogue never mutates commands/*.md, so this probe is
# its whole sensor — the shape of command_approval_probes above. It reads "Before anything else",
# not the file: a step moved below the delegation would create the worktree after the planner wrote.
# It also demands that `health`, `preflight` and `install` run as ./bin/sdd inside the worktree: the
# `sdd` on the PATH has its SDD_HOME in the main checkout and would install THAT checkout's agents/.
command_worktree_probes() {
  local cmd="$ROOT/commands/sdd-plan.md" sec
  sec="$(awk '/^## Before anything else/{s=1; next} s && /^## /{s=0} s' "$cmd")"
  if grep -qF 'readlink -f "$(command -v sdd)"' <<< "$sec" \
     && grep -qF 'case "$sdd" in "$root"/*)' <<< "$sec" \
     && grep -qF 'before writing any artifact' <<< "$sec" \
     && grep -qF 'git worktree add ../<repo>-<slug>' <<< "$sec" \
     && grep -qF 'take the worktree as the repository root for every step below' <<< "$sec" \
     && grep -qF 'run as `./bin/sdd`' <<< "$sec" \
     && grep -qF 'tell the human' <<< "$sec" \
     && grep -qF 'resolves outside this root, skip this step' <<< "$sec"; then
    pass "command: /sdd-plan moves a mission of the kit sdd runs from into a linked worktree before writing it"
  else
    fail "command: /sdd-plan no longer moves a mission of the kit sdd runs from into a linked worktree before writing it (the PATH check, the worktree, the root switch, ./bin/sdd inside it, or the line to the human)"
  fi
}

# The same step tells the human what comes back BEFORE the worktree goes (retro of batch 5; Codex on
# PR #242): `.sdd/cache/` and `.sdd/logs/` are ignored and per worktree, so `git worktree remove`
# deletes the killer map the mission's health taught and the stamp it wrote — 676 mutants against
# 619 in the main checkout, measured. The map always returns; the stamp only when line 6 of
# `./bin/sdd health --release` is red, or a valid stamp of the main checkout is overwritten. Its own
# probe, so a red names this sentence and not the creation step's.
command_worktree_return_probes() {
  local cmd="$ROOT/commands/sdd-plan.md" sec
  sec="$(awk '/^## Before anything else/{s=1; next} s && /^## /{s=0} s' "$cmd")"
  if grep -qF 'before `git worktree remove`, its killer map comes back to this checkout' <<< "$sec" \
     && grep -qF 'its stamp too when line 6 of `./bin/sdd health --release` here is red' <<< "$sec" \
     && grep -qF '`docs/failure-modes.md`' <<< "$sec"; then
    pass "command: /sdd-plan tells the human the killer map, and the stamp when line 6 is red, come back before the worktree is removed"
  else
    fail "command: /sdd-plan no longer tells the human what comes back before the worktree is removed (the killer map always, the stamp when line 6 of health --release is red, the failure-modes pointer)"
  fi
}


# --- the publisher and the mutation stamp (#142, #198; ADR 0015 §1) ------------------------------
# The stamp is not headless. `sdd health` runs for twenty to fifty minutes; the publisher was told to
# run it inside its session, started it in the background and ended its turn waiting (a headless
# session that ends its turn has ended: US$ 1,46 for nothing), and when it did wait it stamped
# before the review bots had spoken (#196: health at 18:13, CodeRabbit at 18:27 with a finding in
# bin/sdd, the next run cut at 123 of 542 mutants). Since ADR 0015 the runner stops with rc 2 once
# the PR is open and the stamp is all its gate misses, so the publisher only opens the PR. Three
# probes, because each failure is its own: the order to run it is back; a stamp item is back in the
# pre-push list, which makes the publisher stop BEFORE the PR exists and the runner's stop is never
# reached; the PR body no longer carries the order the human follows. The catalogue reaches none of
# them — it sabotages bin/sdd and this lives in agents/*.md — so these probes are the whole sensor.
publisher_stamp_probes() {
  local pub="$ROOT/agents/sdd-publisher.md" pre
  if grep -qE 'run `\./bin/sdd health`' "$pub"; then fail "hat: the publisher is told to run ./bin/sdd health — the stamp is not headless"
  else pass "hat: the publisher never runs the stamp — it is not headless"; fi
  pre="$(awk '/^### 2\. /{on=1; next} /^### /{on=0} on' "$pub")"
  if [ -z "$pre" ]; then fail "hat: the publisher's pre-push section (### 2.) was not found — the probe would read nothing"
  elif grep -qiE '^- .*(stamp|check-mutation)' <<< "$pre"; then fail "hat: a stamp item is back in the publisher's pre-push list — it would stop before the PR exists"
  else pass "hat: and the stamp is no reason for the publisher to stop before the PR is open"; fi
  if grep -qE 'review bot.*one batch.*\./bin/sdd health.*sdd run' "$pub"; then pass "hat: and the PR body carries the order: bots, one batch of fixes, the stamp, sdd run"
  else fail "hat: the publisher's PR body lost the order before the merge"; fi
}

# --- sdd census: the instrument reads the logs, never memory ------------------------------------
# PROVENANCE: the three lines below were captured on 2026-09-04 on Claude Code 2.1.260 with
#     claude -p 'Read docs/handoffs/x/00-missao.md with the Read tool, then reply with exactly: OK' \
#       --model haiku --max-turns 3 --output-format stream-json --verbose --permission-mode acceptEdits \
#       --allowedTools Bash --strict-mcp-config --setting-sources project,local --max-budget-usd 1
# in a scratch repo holding a 14-byte docs/handoffs/x/00-missao.md — one tool_use (Read), its
# tool_result, and the result object, pasted VERBATIM (the absolute scratch path inside them is
# the session's own; the census matches on the `docs/handoffs/` segment).
census_fixture() {   # census_fixture <dir> — a .sdd/logs/<mission> with one EXEC and one REVIEW session
  mkdir -p "$1"
  cat > "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" <<'EOF'
{"type":"assistant","message":{"model":"claude-haiku-4-5-20251001","id":"msg_011CehgTuNGVKVHAB6Mdhbnz","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_01KBzzjoMzuzrhMEeAJVgdh5","name":"Read","input":{"file_path":"/tmp/tmp.LlQXlVC5uE/docs/handoffs/x/00-missao.md"},"caller":{"type":"direct"}}],"stop_reason":null,"stop_sequence":null,"stop_details":null,"usage":{"input_tokens":10,"cache_creation_input_tokens":7094,"cache_read_input_tokens":13615,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":7094},"output_tokens":3,"service_tier":"standard","inference_geo":"not_available"},"diagnostics":null,"context_management":null},"parent_tool_use_id":null,"session_id":"7b70d796-37ea-4eb3-bf36-943bf898a9ce","uuid":"923a49ca-96a7-4c1a-ad89-9f3f292eb365","timestamp":"2026-09-04T03:22:16.818Z","request_id":"req_011CehgTspkFiXA6jkYbf5E4"}
{"type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_01KBzzjoMzuzrhMEeAJVgdh5","type":"tool_result","content":"1\thello handoff\n2\t"}]},"parent_tool_use_id":null,"session_id":"7b70d796-37ea-4eb3-bf36-943bf898a9ce","uuid":"1315de5c-ea53-40ad-baf2-5f0b6f1e8482","timestamp":"2026-09-04T03:22:16.850Z","tool_use_result":{"type":"text","file":{"filePath":"/tmp/tmp.LlQXlVC5uE/docs/handoffs/x/00-missao.md","content":"hello handoff\n","numLines":2,"startLine":1,"totalLines":2}}}
{"duration_api_ms":4264,"stop_reason":"end_turn","session_id":"7b70d796-37ea-4eb3-bf36-943bf898a9ce","total_cost_usd":0.0189534,"usage":{"input_tokens":18,"cache_creation_input_tokens":7314,"cache_read_input_tokens":34324,"output_tokens":175,"output_tokens_details":{"thinking_tokens":86},"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":7314,"ephemeral_5m_input_tokens":0},"inference_geo":"not_available","iterations":[{"input_tokens":8,"output_tokens":44,"cache_read_input_tokens":20709,"cache_creation_input_tokens":220,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":220},"type":"message"}],"speed":"standard"},"modelUsage":{"claude-haiku-4-5-20251001":{"inputTokens":18,"outputTokens":175,"cacheReadInputTokens":34324,"cacheCreationInputTokens":7314,"webSearchRequests":0,"costUSD":0.0189534,"contextWindow":200000,"maxOutputTokens":32000,"thinkingTokens":86,"canonicalModel":"claude-haiku-4-5","provider":"firstParty","costBasis":"list"}},"permission_denials":[],"terminal_reason":"completed","fast_mode_state":"off","fast_mode_disabled_reason":"sdk_opt_in_required","subagent_stats":{"spawned":0,"requested":{"background":0,"foreground":0,"unset":0},"started_in_background":0,"max_depth":0,"spawned_by_subagents":0,"completed":0,"failed":0,"killed":{"parent":0,"user":0,"system":0},"refused":{"depth_limit":0,"concurrency_limit":0,"budget":0},"by_type":{}},"is_error":false,"num_turns":2,"subtype":"success","api_error_status":null,"result":"OK","ttft_ms":2131,"type":"result","duration_ms":4300,"uuid":"cec86581-6d23-4789-adb8-f7a0310790a8","ttft_stream_ms":1448,"time_to_request_ms":26,"first_content_frame_ms":1750,"queued_turn_count":0}
EOF
  cp "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" "$1/REVIEW-20260101-000100-bbbbbbbb.stream.jsonl"
  jq -c 'select(.type=="result")' "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" > "$1/EXEC-20260101-000000-aaaaaaaa.json"
  jq -c 'select(.type=="result") | .permission_denials = [{"tool_name":"Bash","tool_input":{"command":"git push"}}]' \
     "$1/EXEC-20260101-000000-aaaaaaaa.stream.jsonl" > "$1/REVIEW-20260101-000100-bbbbbbbb.json"
}
census_probes() {
  local box out
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-census-XXXXXX")"
  PROBE_BOXES+=("$box")
  ( cd "$box" && git init -q . && "$ROOT/bin/sdd" install >/dev/null 2>&1 \
      && printf 'PROJECT_NAME="census"\nDEFAULT_BRANCH="main"\nTEST_CMD="true"\nHANDOFF_DIR="docs/handoffs"\n' > .sdd/config.sh \
      && mkdir -p docs/handoffs/20260101-fixture && : > docs/handoffs/20260101-fixture/00-missao.md )
  census_fixture "$box/.sdd/logs/20260101-fixture"
  out="$( cd "$box" && "$ROOT/bin/sdd" census 20260101-fixture 2>&1 )" || true
  if grep -qE '^  EXEC +sessions 1 +turns [0-9]+' <<< "$out"; then pass "census: EXEC counts its one session and its turns"
  else fail "census: EXEC row missing — got: $(head -3 <<< "$out" | tr '\n' '|' | cut -c1-160)"; fi
  if grep -qE '^  REVIEW .*denials 1' <<< "$out"; then pass "census: denials are summed off the result"
  else fail "census: REVIEW denials not 1"; fi
  if grep -qE 'tools: .*Read=1' <<< "$out"; then pass "census: the tool census names Read once"
  else fail "census: tool census missing Read=1"; fi
  if grep -qE '^  EXEC .*handoff_read [1-9][0-9]*B' <<< "$out"; then pass "census: bytes read under docs/handoffs are counted"
  else fail "census: handoff_read is 0 or absent"; fi
  # The aggregate one line up cannot say WHICH file, and a diet aimed at "1.4 MB somewhere under
  # docs/handoffs" is aimed at nothing. The capture holds exactly one Read of 00-missao.md, so
  # both terms are pinned: a break-down that lost the count would print reads 0, one that lost the
  # correlation between tool_use and tool_result would print bytes 0.
  if grep -qE '^ +file +00-missao\.md reads 1 bytes [1-9][0-9]*$' <<< "$out"; then pass "census: the per-file break-down names the file, its reads and its bytes"
  else fail "census: per-file line for 00-missao.md missing — got: $(grep -c ' file ' <<< "$out") file line(s)"; fi
  # `handoff_read` needs a session to have already run; the boot bill is the same question asked
  # of the disk, so a cut can be read before and after for free. Templates alone make it non-zero
  # in this box, which is what the assertion pins.
  # The EXPECTED number, computed here from the same templates the bill reads — not a wildcard.
  # `[1-9][0-9]*B` accepted both the honest answer and the one that folds PLAN into the maximum
  # (12 132 against 9 830), and the mutant CENSUS_templates_count_plan walked straight through it.
  # PLAN is excluded from the bill because it is the first phase: it has no predecessor handoff, so
  # summing its four templates with the worst handoff describes a boot that cannot happen.
  local want_t=0 t
  for t in checkpoint.md checkpoint-notas.md handoff.md; do
    [ -f "$ROOT/templates/$t" ] && want_t=$((want_t + $(wc -c < "$ROOT/templates/$t")))
  done
  if grep -qE "^  boot bill .*templates\(worst booting phase\) ${want_t}B  total [1-9][0-9]*B\$" <<< "$out"; then pass "census: the boot bill charges the heaviest BOOTING phase's templates, and PLAN is not one"
  else fail "census: templates term should be ${want_t}B (EXEC's set) — got: $(grep -o 'templates(worst booting phase) [0-9]*B' <<< "$out")"; fi
  # Differential, and the reason it exists: `latest=` is a four-stage pipeline under
  # `set -o pipefail`, and on a mission with no handoff yet EVERY stage exits non-zero for having
  # found nothing. Without the `|| true` inside the substitution the assignment kills sdd census
  # outright — so this pair asserts both that the empty world is survived AND that the non-empty
  # one is answered, which no single fixture can do.
  local out2
  # The bill measures the two sections the boot inlines, not the file, so the fixture has to carry
  # them: a 500-byte blob with no headings costs the boot nothing and would make every term zero.
  # The ignored section is deliberately LARGER than the inlined one: with both small, "counts the
  # sections" and "counts the whole file" land in the same range and an assertion cannot tell them
  # apart — the mutant BOOT_handoff_whole_file escaped exactly that way before this line grew.
  { printf '## TL;DR\n\n'; head -c 400 /dev/zero | tr '\0' 'h'
    printf '\n\n## Evidence\n\n'; head -c 3000 /dev/zero | tr '\0' 'z'; printf '\n'; } \
    > "$box/docs/handoffs/20260101-fixture/20-handoff-exec.md"
  out2="$( cd "$box" && "$ROOT/bin/sdd" census 20260101-fixture 2>&1 )" || true
  if grep -qE '^  boot bill .*\(no handoff yet\) 0B' <<< "$out"; then pass "census: the boot bill survives a mission with no handoff yet"
  else fail "census: boot bill did not report an absent handoff"; fi
  if grep -qE '^  boot bill .*20-handoff-exec\.md [1-9][0-9]*B' <<< "$out2"; then pass "census: and names the most recent handoff once there is one"
  else fail "census: boot bill did not name 20-handoff-exec.md — got: $(grep '^  boot bill' <<< "$out2" | cut -c1-140)"; fi
  # The reason the resolution is `sort -V` and not the glob's own order, written as an assertion
  # instead of a comment: on text, r2 sorts ABOVE r10, and a mission that reached a two-digit
  # review round would have its boot measured against a handoff two rounds stale.
  local out3
  printf '## TL;DR\nx\n' > "$box/docs/handoffs/20260101-fixture/40-review-r2.md"
  printf '## TL;DR\nxx\n' > "$box/docs/handoffs/20260101-fixture/40-review-r10.md"
  out3="$( cd "$box" && "$ROOT/bin/sdd" census 20260101-fixture 2>&1 )" || true
  if grep -qE '^  boot bill .*40-review-r10\.md [1-9][0-9]*B' <<< "$out3"; then pass "census: and prefers r10 to r2 — version order, not text order"
  else fail "census: boot bill picked text order — got: $(grep '^  boot bill' <<< "$out3" | cut -c1-140)"; fi
  # "Most recent" and "heaviest" are different questions, and only the second one a target can be
  # held to: on a closed mission the most recent handoff is the smallest artifact there is. The
  # pair is differential on purpose — the line has to be ABSENT when the two points agree (out2,
  # where the only handoff is both) and PRESENT naming the heavier one when they disagree (out3,
  # where the newest is a 3-byte review round and the heaviest a 500-byte exec handoff). Neither
  # half alone separates "computes the worst point" from "always prints the last file again".
  if grep -qE '^  boot bill  worst point' <<< "$out2"; then fail "census: worst-point line printed when it repeats the first"
  else pass "census: no worst-point line when the heaviest handoff IS the most recent"; fi
  if grep -qE '^  boot bill  worst point  20-handoff-exec\.md 4[0-9][0-9]B  total [1-9][0-9]*B$' <<< "$out3"; then pass "census: the worst point costs the two inlined sections, not the whole handoff"
  else fail "census: worst point wrong — got: $(grep 'worst point' <<< "$out3" | cut -c1-140)"; fi
  rm -rf "$box"
}

# --- sdd health --release: the six lines of ADR 0007 read artifacts, never labels ---------------
# The probes read the verdict off the printed line: `ok` prefix = green, the same line without it
# = red. They never run the suite — line 6 reads the mutation stamp, the suite's own artifact.
rel_green() { grep -cE "ok[^ ]*[[:space:]]+line $2 ·" <<< "$1"; }   # rel_green <out> <n>
rel_red()   { grep -E "line $2 ·" <<< "$1" | grep -vcE "ok[^ ]*[[:space:]]+line $2 ·"; }
release_probes() {
  local box ledger out rc
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-release-XXXXXX")"
  PROBE_BOXES+=("$box")
  ledger="$box/state/autonomy-log.jsonl"; mkdir -p "$box/state"
  cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$ROOT/agents" "$ROOT/tests" "$box/"
  mkdir -p "$box/.sdd"
  # The forbidden word is BUILT here, never written whole: this file is on the surface line 5
  # greps, so a literal would be found in the sensor itself and the green probe could never pass.
  local forb; forb="$(printf 'acme%s' '_corp')"
  printf 'PROJECT_NAME="kit"\nDEFAULT_BRANCH="main"\nTEST_CMD="tests/run-all.sh"\nRELEASE_FORBIDDEN_WORDS="%s"\n' "$forb" > "$box/.sdd/config.sh"
  printf '# kit\n' > "$box/README.md"
  ( cd "$box" && git init -q -b main && git config user.email f@x && git config user.name f && git add -A && git commit -qm kit ) >/dev/null
  release() { ( cd "$box" && SDD_STATE_DIR="$box/state" "$box/bin/sdd" health --release 2>&1 ); }
  : > "$ledger"
  out="$(release)"; rc=$?
  if [ "$rc" = 1 ] && [ "$(grep -cE 'line [1-6] ·' <<< "$out")" -eq 6 ]; then pass "release: prints six lines and exits 1 while red"
  else fail "release: expected rc 1 and six verdict lines — got rc $rc: $(tr '\n' '|' <<< "$out" | cut -c1-240)"; fi
  if [ "$(rel_red "$out" 1)" = 1 ] && grep -qE 'line 1 ·.*0 of 2' <<< "$out"; then pass "release: line 1 red — 0 of 2 target repos in an empty ledger"; else fail "release: line 1 should be red with '0 of 2'"; fi
  if [ "$(rel_red "$out" 3)" = 1 ]; then pass "release: line 3 red with no target mission"; else fail "release: line 3 should be red on an empty ledger"; fi
  if [ "$(rel_red "$out" 5)" = 1 ] && grep -qE 'line 5 ·.*LICENSE' <<< "$out"; then pass "release: line 5 red and wants a LICENSE"; else fail "release: line 5 should name LICENSE"; fi
  # `sdd health --with-mutation` is a habit written in ten handoffs; the catalogue always runs, so
  # the flag is accepted as a synonym and never refused as an unknown option.
  out="$( cd "$box" && SDD_STATE_DIR="$box/state" "$box/bin/sdd" health --with-mutation --release 2>&1 )" || true
  if ! grep -q 'unknown option' <<< "$out" && grep -qE 'line 1 ·' <<< "$out"; then pass "health: --with-mutation is accepted as a synonym, not refused"
  else fail "health: --with-mutation should be accepted — got: $(head -2 <<< "$out" | tr '\n' '|' | cut -c1-160)"; fi
  # a ledger with two target repos, a PR in the second, and a last mission whose rows saw nothing
  cat > "$ledger" <<'EOF'
{"v":1,"ts":"2026-09-01T10:00:00-03:00","event":"session","run_id":"a","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"one","repo":"/repos/one","mission":"20260901-x","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":9,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
{"v":1,"ts":"2026-09-01T11:00:00-03:00","event":"session","run_id":"a","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"one","repo":"/repos/one","mission":"20260901-x","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s1b","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":9,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
{"v":1,"ts":"2026-09-02T10:00:00-03:00","event":"session","run_id":"b","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"two","repo":"/repos/two","mission":"20260902-y","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":0,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
{"v":1,"ts":"2026-09-02T11:00:00-03:00","event":"session","run_id":"b","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"two","repo":"/repos/two","mission":"20260902-y","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":0,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}
EOF
  printf '%s\n' '{"v":1,"ts":"2026-09-03T10:00:00-03:00","event":"session","run_id":"t","invocation":"run","kit_sha":"abc1234","kit_dirty":false,"project":"tmp","repo":"/tmp/sdd-fixture-clone","mission":"20260903-t","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s9","rc":0,"dur_s":1,"cost_usd":1,"turns":3,"moved":true,"mcp_seen":0,"tools_leaked":0,"denials":0,"gate":"pass","gate_why":""}' >> "$ledger"
  printf 'MIT\n' > "$box/LICENSE"
  out="$(release)"
  if [ "$(rel_green "$out" 1)" = 1 ] && grep -qE 'line 1 ·.*2 of 2' <<< "$out"; then pass "release: line 1 green with two target repos — and a /tmp clone is not a third"; else fail "release: line 1 should be green with exactly 2 — $(grep 'line 1' <<< "$out")"; fi
  if [ "$(rel_green "$out" 3)" = 1 ]; then pass "release: line 3 green when the last mission saw nothing it did not declare"; else fail "release: line 3 should be green — $(grep 'line 3' <<< "$out")"; fi
  if [ "$(rel_green "$out" 4)" = 1 ]; then pass "release: line 4 green with a PR phase in the second repo"; else fail "release: line 4 should be green — $(grep 'line 4' <<< "$out")"; fi
  if [ "$(rel_green "$out" 5)" = 1 ]; then pass "release: line 5 green with a LICENSE and a clean surface"; else fail "release: line 5 should be green — $(grep 'line 5' <<< "$out")"; fi
  printf 'the client %s\n' "$forb" >> "$box/README.md"
  out="$(release)"
  if [ "$(rel_red "$out" 5)" = 1 ] && grep -qF "$forb" <<< "$(grep 'line 5 ·' <<< "$out")"; then pass "release: line 5 names the forbidden word it found"; else fail "release: line 5 should name the word — $(grep 'line 5' <<< "$out")"; fi
  rm -rf "$box"
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
census_probes
executor_agent_probes
hat_promise_probes
command_approval_probes
command_relay_probes
command_worktree_probes
command_worktree_return_probes
publisher_stamp_probes
boot_probes
release_probes
selftest || exit $?
if [ "$fails" -eq 0 ]; then printf '  ok    %d hat(s) declare their boundary\n' "$n"; exit 0; fi
printf '%d hat check(s) failed\n' "$fails" >&2
exit 1
