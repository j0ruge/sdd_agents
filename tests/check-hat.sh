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
# declared here rather than left silent.
executor_agent_probes() {
  local ex="$ROOT/agents/sdd-executor.md" rv="$ROOT/agents/sdd-reviewer.md"
  if grep -qE '^disallowedTools:.*(^|[ ,"])Agent([,"]|$)' "$ex"; then pass "hat: the executor denies Agent — the census measured 0 uses in 27 EXEC sessions"
  else fail "hat: sdd-executor no longer denies Agent"; fi
  if grep -qE '^disallowedTools:.*(^|[ ,"])Agent([,"]|$)' "$rv"; then fail "hat: sdd-reviewer denies Agent — its codereview skill dispatches subagents and would break"
  else pass "hat: and the reviewer still may use it, which is why Agent is not in HAT_DENY_BASE"; fi
  if grep -qi 'subagent' "$ex"; then fail "hat: the executor prompt still asks for subagents while the tool is denied"
  else pass "hat: and the executor prompt no longer asks for what it cannot do"; fi
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
  if grep -qE '^  boot bill .*templates [1-9][0-9]*B  total [1-9][0-9]*B$' <<< "$out"; then pass "census: the boot bill adds up what the boot points at"
  else fail "census: boot bill line missing or zero — got: $(grep '^  boot bill' <<< "$out" | cut -c1-140)"; fi
  # Differential, and the reason it exists: `latest=` is a four-stage pipeline under
  # `set -o pipefail`, and on a mission with no handoff yet EVERY stage exits non-zero for having
  # found nothing. Without the `|| true` inside the substitution the assignment kills sdd census
  # outright — so this pair asserts both that the empty world is survived AND that the non-empty
  # one is answered, which no single fixture can do.
  local out2
  head -c 500 /dev/zero | tr '\0' 'h' > "$box/docs/handoffs/20260101-fixture/20-handoff-exec.md"
  out2="$( cd "$box" && "$ROOT/bin/sdd" census 20260101-fixture 2>&1 )" || true
  if grep -qE '^  boot bill .*\(no handoff yet\) 0B' <<< "$out"; then pass "census: the boot bill survives a mission with no handoff yet"
  else fail "census: boot bill did not report an absent handoff"; fi
  if grep -qE '^  boot bill .*20-handoff-exec\.md [1-9][0-9]*B' <<< "$out2"; then pass "census: and names the most recent handoff once there is one"
  else fail "census: boot bill did not name 20-handoff-exec.md — got: $(grep '^  boot bill' <<< "$out2" | cut -c1-140)"; fi
  # The reason the resolution is `sort -V` and not the glob's own order, written as an assertion
  # instead of a comment: on text, r2 sorts ABOVE r10, and a mission that reached a two-digit
  # review round would have its boot measured against a handoff two rounds stale.
  local out3
  printf 'x\n' > "$box/docs/handoffs/20260101-fixture/40-review-r2.md"
  printf 'xx\n' > "$box/docs/handoffs/20260101-fixture/40-review-r10.md"
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
  if grep -qE '^  boot bill  worst point  20-handoff-exec\.md 500B  total [1-9][0-9]*B$' <<< "$out3"; then pass "census: the worst point names the heaviest handoff, not the newest"
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
release_probes
selftest || exit $?
if [ "$fails" -eq 0 ]; then printf '  ok    %d hat(s) declare their boundary\n' "$n"; exit 0; fi
printf '%d hat check(s) failed\n' "$fails" >&2
exit 1
