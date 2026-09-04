#!/usr/bin/env bash
# Sensor for the autonomy ledger — the series the kaizen judge (I13.3) will read.
#
# The ledger records FACTS, never a score, and its value is entirely in being trustworthy: a row
# that should not exist (a projection, a fixture) poisons a metric that decides whether the kit
# graduates. So the assertions here are mostly about what must NOT be written.
#
# Hermetic: `claude` is stubbed and SDD_STATE_DIR points at a scratch directory of this test's own
# — `gh` is never called on the paths this test exercises. Runs INSIDE mutants (unlike
# check-preflight), because the mutations that sabotage the writer have to kill the sandbox suite —
# guarded, they would score a point for nothing.
#
# Usage: tests/check-autonomy.sh   (exit 0 = the ledger tells the truth)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-autonomy-XXXXXX")"
MISSION="20260101-fixture"
fails=0

# Everything this file writes that is NOT part of the target repo lives here, deliberately OUTSIDE
# $FIX — which becomes the fixture's git working tree below. The instrument must not end up inside
# the thing it measures: the moving stub further down runs `git add -A`, so a state directory under
# $FIX would get the ledger COMMITTED into the repo under test, `state_fingerprint` (git HEAD +
# mission dir + checkpoint md5) could then move because the LEDGER was written rather than because
# the session did anything, and the tree this file asserts about would end dirty. It is also the
# exact configuration the ledger's own design forbids (see the comment above autonomy_log_path in
# bin/sdd, and `SDD_STATE_DIR` in config/schema.md). Same choice, same reason, as check-gates.sh
# and check-dry-run.sh — which is why the two assertions at the end of this file pin it.
OUTSIDE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-autonomy-outside-XXXXXX")"
trap 'rm -rf "$FIX" "$OUTSIDE"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); }
assert_eq() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi }

# num_before <text> <literal-that-follows-the-number, as an ERE> -> the integer, or "" if absent.
# One `grep -m1 -oE`, nothing piped after it: the match is trimmed with bash's own `${m%% *}`
# instead of a second process. That sidesteps the pipefail/SIGPIPE trap this repo warns about
# (`printf | grep -q` returns 141 when grep finds a match and closes the pipe before the writer is
# done) — there is no writer here for a downstream reader to cut off.
num_before() {
  local m; m="$(grep -m1 -oE "[0-9]+ $2" <<< "$1")"
  printf '%s' "${m%% *}"
}

# sum_sessions <reader output> -> total of every "N session(s)" occurrence (one per kit_sha row).
# A single awk process reading the whole herestring, same reason as num_before: no pipe, no
# early-exiting reader on the other end of one.
sum_sessions() {
  awk '{ while (match($0, /[0-9]+ session\(s\)/)) {
           s += substr($0, RSTART, RLENGTH) + 0
           $0 = substr($0, RSTART + RLENGTH)
         } }
       END { print s + 0 }' <<< "$1"
}

# sum_escalations <reader output> -> total of every "  <kit_sha>  <kind>: N" line. The leading
# kit_sha is optional in this pattern ON PURPOSE: this helper's job is to COUNT rows for the
# bucket sum, and pinning the shape belongs to the axis assertions further down — a helper that
# did both would report "0 escalations" on a shape change and blame the wrong bucket. Either way
# the pattern stays unique to escalation lines: the per-kit_sha session lines use "·" separators
# and end in "US$ <n>", never in "<word>: <digits>".
sum_escalations() {
  awk '/^  ([^ ]+  )?[A-Za-z][A-Za-z0-9_-]*: [0-9]+$/ { split($0, a, ": "); s += a[2] } END { print s + 0 }' \
    <<< "$1"
}

# assert_bucket_sum <description> <reader output>
# Every row lands in exactly one of FIVE buckets: comparable session, non-comparable session,
# escalation, recorded gate closure, unrecognized. If the filter drops a row (finding 3) or
# double-counts one, this sum drifts from the header total — an anti-vacuity check a broken filter
# cannot pass by accident, unlike any single count in isolation.
#
# It was four until 2026-08-31, and the fifth is what an event added to the enum costs: a row the
# reader recognises has to be NAMED somewhere the arithmetic closes over, or "recognised" degrades
# into "silently dropped" — which is the same defect as `unrecognized`, only quieter.
assert_bucket_sum() {
  local desc="$1" out="$2" total comparable noncomp escal closed stray sum
  total="$(num_before "$out" 'row\(s\)')"; total="${total:-0}"
  comparable="$(sum_sessions "$out")"
  noncomp="$(num_before "$out" 'non-comparable')"; noncomp="${noncomp:-0}"
  escal="$(sum_escalations "$out")"
  closed="$(num_before "$out" 'gate\(s\) closed without a session')"; closed="${closed:-0}"
  stray="$(num_before "$out" 'unrecognized')"; stray="${stray:-0}"
  sum=$((comparable + noncomp + escal + closed + stray))
  assert_eq "$desc" "$total" "$sum"
}

# The ledger under test. Never the real one: the export in run-all.sh already redirects every
# test, and this makes THIS file independent of that export holding.
export SDD_STATE_DIR="$OUTSIDE/state"
LEDGER="$SDD_STATE_DIR/autonomy-log.jsonl"

# rows <jq-filter> — applies the filter to every row and prints one result per line.
# -r (not -c): a compact string result still comes back quoted, and every string assertion below
# compares against the bare value.
rows() { jq -cr "$1" "$LEDGER" 2>/dev/null; }
# `grep -c .` on an EXISTING but empty file prints "0" and still exits 1 (no match), which would
# also fire the `||` fallback and double the output to "0\n0" — an explicit branch avoids that.
nrows() { [ -f "$LEDGER" ] || { echo 0; return; }; grep -c . "$LEDGER" 2>/dev/null; }

echo "== fixture at $FIX =="
cd "$FIX" || exit 1

# No test spends tokens or network. In this task nothing should reach claude at all: the blocked
# escalation returns before any session. The stub makes that a loud failure instead of a bill.
mkdir -p "$OUTSIDE/stub"
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$OUTSIDE/stub/claude"
PATH="$OUTSIDE/stub:$PATH"

# One session's worth of `stream-json`, replayed by every stub in this file that answers at all.
# ONE copy, deliberately: three stubs pasting their own idea of the format is three chances for
# one of them to drift into a shape the CLI never emits, and the drifted one would still pass.
#
# PROVENANCE: captured from a REAL session on 2026-08-16 with
#     claude -p 'Reply with exactly: OK' --model haiku --output-format stream-json --verbose
# on Claude Code 2.1.233, and pasted VERBATIM — no field invented, none renamed. These are lines
# 1, 2 and 37 of that capture: two `system` events and the terminal `result` object. The 34
# omitted lines are the `init` blob, the hook events and the assistant turns, none of which the
# runner reads. Writing this shape from memory is the mistake the provenance rule exists to stop —
# stub and parser would share one author and one wrong assumption, and the suite would go on
# confirming it forever. Re-capture with the command above when the CLI major changes.
STREAM_SAMPLE="$OUTSIDE/stream-sample.jsonl"
cat > "$STREAM_SAMPLE" <<'EOF'
{"type":"system","subtype":"thinking_tokens","estimated_tokens":5,"estimated_tokens_delta":5,"uuid":"b53d314f-e6ef-41b2-9227-bf8375d962bd","session_id":"3b628c65-6068-442e-aedb-bc76c2e508b1"}
{"type":"system","subtype":"thinking_tokens","estimated_tokens":10,"estimated_tokens_delta":5,"uuid":"41cba195-10ef-4421-b806-4e3fde0069f2","session_id":"3b628c65-6068-442e-aedb-bc76c2e508b1"}
{"is_error":false,"duration_api_ms":14208,"num_turns":1,"stop_reason":"end_turn","session_id":"3b628c65-6068-442e-aedb-bc76c2e508b1","total_cost_usd":0.0362104,"usage":{"input_tokens":10,"cache_creation_input_tokens":15451,"cache_read_input_tokens":18134,"output_tokens":697,"output_tokens_details":{"thinking_tokens":690},"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":15451,"ephemeral_5m_input_tokens":0},"inference_geo":"not_available","iterations":[{"input_tokens":10,"output_tokens":697,"cache_read_input_tokens":18134,"cache_creation_input_tokens":15451,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":15451},"type":"message"}],"speed":"standard"},"modelUsage":{"claude-haiku-4-5-20251001":{"inputTokens":10,"outputTokens":697,"cacheReadInputTokens":18134,"cacheCreationInputTokens":15451,"webSearchRequests":0,"costUSD":0.0362104,"contextWindow":200000,"maxOutputTokens":32000,"canonicalModel":"claude-haiku-4-5","provider":"firstParty"}},"permission_denials":[],"terminal_reason":"completed","fast_mode_state":"off","fast_mode_disabled_reason":"sdk_opt_in_required","subtype":"success","api_error_status":null,"result":"OK","ttft_ms":14187,"ttft_stream_ms":1324,"time_to_request_ms":28,"type":"result","duration_ms":14238,"uuid":"09a7a31e-9833-426b-8fdd-293522a57a35"}
EOF

# The `init` line the hat sensor reads — tools and mcp_servers as the session saw them.
# PROVENANCE: captured on 2026-09-04 with
#     claude -p 'Reply with exactly: OK' --model haiku --max-turns 1 --output-format stream-json --verbose \
#       --permission-mode acceptEdits --allowedTools Bash --strict-mcp-config --setting-sources project,local \
#       --disallowedTools "<HAT_DENY_BASE of bin/sdd>, Bash(git push:*), Bash(gh pr create:*), Bash(gh pr merge:*), ScheduleWakeup, Monitor" \
#       --max-budget-usd 1
# — the exact flags run_phase passes the EXEC hat — in an empty scratch repo on Claude Code
# 2.1.260, first line pasted VERBATIM. Under --strict-mcp-config the list has no MCP server, every
# denied tool is absent from `tools` (a first capture denying only two of them listed the other
# fifteen, and the clean probe read tools_leaked:14 — the fixture has to be born under the real
# flags),
# and the subagent tool is spelt `Task` here where the deny flag spells `Agent` (a second capture
# with `Agent` denied lost exactly that entry — the alias in bin/sdd's hat_init_facts is this
# measurement). The leaking fixtures below are DERIVED from this line with jq, never typed.
INIT_SAMPLE="$OUTSIDE/init-sample.jsonl"
cat > "$INIT_SAMPLE" <<'EOF'
{"type":"system","subtype":"init","cwd":"/tmp/tmp.blYioysMoW","session_id":"5400b3e9-db58-47db-a360-5080d5c3571a","tools":["Task","Bash","Edit","ListAgents","Read","Skill","TaskCreate","TaskGet","TaskList","TaskOutput","TaskStop","TaskUpdate","ToolSearch","Write"],"mcp_servers":[],"model":"claude-haiku-4-5-20251001","permissionMode":"acceptEdits","slash_commands":["deep-research","design-sync","dataviz","update-config","verify","debug","code-review","simplify","batch","fewer-permission-prompts","doctor","loop","schedule","claude-api","workflow-authoring","run","run-skill-generator","advisor","agents","auto-mode-setup","autocompact","clear","color","compact","config","context","effort","fast","heapdump","init","mcp","import","model","__remote-workflow","workflow-launch-exec","reload-plugins","reload-skills","rename","ultrareview","security-review","usage-credits","extra-usage","usage","insights","recap","skill-doctor","goal","design","design-consent","design-revoke","list-agents","team-onboarding"],"terminal_slash_commands":["doctor","color","reload-plugins"],"apiKeySource":"none","claude_code_version":"2.1.260","output_style":"default","agents":["claude","Explore","general-purpose","Plan","statusline-setup"],"skills":["deep-research","design-sync","dataviz","update-config","verify","debug","code-review","simplify","batch","fewer-permission-prompts","doctor","loop","schedule","claude-api","workflow-authoring","run","run-skill-generator"],"plugins":[],"capabilities":["interrupt_receipt_v1","interrupt_cancel_queued_v1","msg_lifecycle_v1"],"analytics_disabled":false,"product_feedback_disabled":false,"uuid":"70c30b5e-604a-4d7d-ab06-daae31a31453","memory_paths":{"auto":"/home/joruge/.claude/projects/-tmp-tmp-blYioysMoW/memory/"},"messaging_socket_path":"/run/user/1001/cc-socks/1456978.sock","fast_mode_state":"off","fast_mode_disabled_reason":"sdk_opt_in_required"}
EOF
INIT_CLEAN="$OUTSIDE/stream-init-clean.jsonl"
{ cat "$INIT_SAMPLE"; cat "$STREAM_SAMPLE"; } > "$INIT_CLEAN"
INIT_LEAK="$OUTSIDE/stream-init-leak.jsonl"
{ jq -c '.mcp_servers = [{"name":"atlassian","status":"connected"}] | .tools += ["WebSearch"]' "$INIT_SAMPLE"; cat "$STREAM_SAMPLE"; } > "$INIT_LEAK"

git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "content" > file.txt
git add -A && git commit -qm "init"

# The reader filters the ledger by the repo it is standing in, so every hand-written fixture row
# has to name THIS repo. Ask git for the path rather than reusing $FIX: TMPDIR may be a symlink
# and the reader resolves it exactly this way. The fixtures keep spelling it `/p1` — a 400-char
# JSON line is unreadable enough without an absolute temp path in it — and localize() is the one
# rewrite from that shorthand, applied as each ledger is written.
FIXROOT="$(git rev-parse --show-toplevel)"
localize() { sed -e "s|\"repo\":\"/p1\"|\"repo\":\"$FIXROOT\"|g"; }

"$SDD" install >/dev/null
cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF
# L6 of the 2026-09-03 audit: ON_ESCALATION_CMD is the human's pager — every rc 3 runs it with
# SDD_REASON, SDD_PHASE, SDD_MISSION and SDD_GATE_WHY in its env. Measured before it: zero
# notification sites in bin/sdd, and a human watching `tail -F` to learn the line had stopped.
# The fixture's hook appends one line per escalation; the blocks below read it as an artefact.
HOOK_LOG="$OUTSIDE/hook.log"
cat >> .sdd/config.sh <<EOF
ON_ESCALATION_CMD='printf "%s|%s|%s|%s\n" "\$SDD_REASON" "\$SDD_PHASE" "\$SDD_MISSION" "\$SDD_GATE_WHY" >> $HOOK_LOG'
EOF

MDIR="$FIX/docs/handoffs/$MISSION"
mkdir -p "$MDIR"
cat > "$MDIR/00-missao.md" <<'EOF'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
EOF
: > "$MDIR/01-plano.md"
# A `blocked` increment: the Jidoka path escalates with rc 3 BEFORE opening any session, which is
# what makes the real (non-dry) writer reachable without spending a token.
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | blocked | — |
EOF
git add -A && git commit -qm "chore: fixture mission"

# --- the projection writes nothing ------------------------------------------
echo "== dry-run =="
"$SDD" run "$MISSION" --dry-run >/dev/null 2>&1
assert_eq "the projection writes no ledger at all" "0" "$(nrows)"
assert_eq "and runs no ON_ESCALATION_CMD — the pager is for escalations, not for projections" "absent" \
  "$( [ -e "$HOOK_LOG" ] && echo present || echo absent)"

# --- the real escalation writes one honest row ------------------------------
echo "== blocked escalation =="
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the blocked increment escalates with rc 3" "3" "$rc"
assert_eq "the escalation ran ON_ESCALATION_CMD once, with reason, phase, mission and gate_why in its env" \
  "1 increment-blocked|EXEC|$MISSION yes" \
  "$(grep -c . "$HOOK_LOG" 2>/dev/null || echo 0) $(cut -d'|' -f1-3 "$HOOK_LOG" 2>/dev/null) $(grep -q Jidoka "$HOOK_LOG" 2>/dev/null && echo yes || echo no)"
rm -f "$HOOK_LOG"
assert_eq "exactly one row was written" "1" "$(nrows)"
assert_eq "every row is valid JSON" "1" "$(jq -e . "$LEDGER" >/dev/null 2>&1 && echo 1 || echo 0)"
assert_eq "schema version" "1" "$(rows '.v')"
assert_eq "event" "blocked" "$(rows '.event')"
assert_eq "kind distinguishes the three escalations by enum, not by prose" \
  "increment-blocked" "$(rows '.kind')"
assert_eq "project" "fixture" "$(rows '.project')"
assert_eq "mission" "$MISSION" "$(rows '.mission')"
assert_eq "phase" "EXEC" "$(rows '.phase')"
assert_eq "invocation" "run" "$(rows '.invocation')"
assert_eq "run_id is present" "true" "$(rows '(.run_id | length) > 0')"
# Session fields are ABSENT, never falsely zeroed: an escalation spent no session, and a 0 there
# would enter the judge's arithmetic as if it had.
assert_eq "no session fields on an escalation" "true" \
  "$(rows 'has("rc") == false and has("cost_usd") == false and has("moved") == false')"
# The gate reason carries quotes and an em-dash. Hand-rolled JSON would break here, and the only
# reader that would notice is the judge, months later, comparing garbage.
assert_eq "gate_why survived quoting" "true" "$(rows '(.gate_why | test("Jidoka"))')"

# --- the interactive PLAN spends no session, so it records none --------------
# PLAN returns 2 before opening anything: there is no friction to measure in a phase that is
# interactive BY DESIGN, and a row here would count human collaboration as waste.
: > "$LEDGER"
sed -i 's/^aprovacao: auto$/aprovacao:/' "$MDIR/00-missao.md"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the interactive PLAN exits 2" "2" "$rc"
assert_eq "and writes no row" "0" "$(nrows)"
sed -i 's/^aprovacao:$/aprovacao: auto/' "$MDIR/00-missao.md"

# --- real sessions, still offline -------------------------------------------
# The stub `claude` exits non-zero, so the session does nothing: the gate fails, the disk did not
# move, the runner retries once and escalates with `no-progress`. Three real rows, no token.
#
# It DOES answer with a stream, and that is what makes `turns` reachable here: run_phase reads the
# turn count out of the same distilled summary it reads the cost from, so a stub that prints
# nothing measures neither. The sample is the capture MINUS its money and WITH a turn count of its
# own, derived with jq and never pasted — the provenance rule at the top of this file covers this
# line too. Costless on purpose, so `unknown cost is null, not a string` below still measures the
# world it names; 7 and not the capture's own 1, so a writer that hard-coded a 1 (or wrote the
# `attempt`, which is also 1 on the first row) could not pass by coincidence.
echo "== session rows =="
: > "$LEDGER"
TURNS_SAMPLE="$OUTSIDE/stream-turns.jsonl"
jq -c 'del(.total_cost_usd, .cost_usd) | if .type == "result" then .num_turns = 7 else . end' \
  "$STREAM_SAMPLE" > "$TURNS_SAMPLE"
# The floor of the world this block asserts over: one result object, seven turns in it, no money
# anywhere. Without it the sample could stop being the sample the assertions name and the two
# verdicts below would go on agreeing with whatever it became.
turns_floor="$(jq -rs '[.[] | select(.type == "result")]
                       | "\(length) \(.[0].num_turns) \([.[] | select(has("total_cost_usd") or has("cost_usd"))] | length)"' \
                       "$TURNS_SAMPLE")"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
EOF
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
cat "$TURNS_SAMPLE"
exit 1
STUB
git add -A && git commit -qm "chore: pending increment"

"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "two dead sessions escalate with rc 3" "3" "$rc"
assert_eq "two session rows plus one escalation" "3" "$(nrows)"
assert_eq "every row is valid JSON" "1" "$(jq -se . "$LEDGER" >/dev/null 2>&1 && echo 1 || echo 0)"

assert_eq "the first row is a session" "session" "$(jq -r -s '.[0].event' "$LEDGER")"
assert_eq "the first session is not a retry" "false" "$(jq -r -s '.[0].auto_retry' "$LEDGER")"
assert_eq "the second row is the retry" "true" "$(jq -r -s '.[1].auto_retry' "$LEDGER")"
# On an in-loop retry, `run_phase` is called with `--resume … --fork-session` and WITHOUT
# `--session-id`: the runner never learns the fork's own id, so the retry row has to carry the
# PARENT session's id — the two rows share one `session` value. Reverting
# `LAST_PHASE_SID="${resume_sid:-$sid}"` to `"$sid"` (the ghost-UUID bug fixed in `032c09c`) makes
# the retry row invent an id nobody ever gave `claude`, and leaves the suite green without this.
assert_eq "the two session rows share one session id (the retry has no fork id of its own)" \
  "true" "$(jq -s '.[1].session == .[0].session' "$LEDGER")"
# The whole point of the metric: a session that changed nothing on disk is waste, and until now
# the retry ran with no measurement at all.
assert_eq "the retry carries its own moved" "false" "$(jq -r -s '.[1].moved' "$LEDGER")"
assert_eq "the gate result rides with the session" "fail" "$(jq -r -s '.[0].gate' "$LEDGER")"
assert_eq "claude's rc is recorded" "1" "$(jq -r -s '.[0].rc' "$LEDGER")"
# The session log has no cost field when claude died: "?" must become null, never a string, or
# the judge sums text.
assert_eq "unknown cost is null, not a string" "true" "$(jq -s '.[0].cost_usd == null' "$LEDGER")"
assert_eq "all three rows share one run_id" "1" \
  "$(jq -s '[.[].run_id] | unique | length' "$LEDGER")"
assert_eq "the escalation is no-progress" "no-progress" "$(jq -r -s '.[2].kind' "$LEDGER")"
# How many turns a session spent is the OTHER half of what it cost — cache-read grows with turns²
# (corr 0.94 over 28 real rounds), so a phase that got cheaper by spending fewer turns and one
# that got cheaper by luck read the same on money alone. The floor rides beside the verdict for
# the reason the block header gives.
assert_eq "a session row carries the turns the session spent" \
  "1 7 0 7" "$turns_floor $(jq -r -s '.[0].turns' "$LEDGER")"
# ABSENT, never zeroed — the rule every other session field on an escalation already follows: an
# escalation spent no session, and a 0 here would enter the judge's arithmetic as a session that
# ran and said nothing. The event term is this assertion's own floor: `.[2]` has to BE the
# escalation, or "no turns" is a fact about the wrong row.
assert_eq "an escalation row carries no turns" "blocked false" \
  "$(jq -r -s '.[2].event' "$LEDGER") $(jq -r -s '.[2] | has("turns")' "$LEDGER")"

# --- sdd retry is a human-forced session, and that is a first-class signal ---
# It is literally the rubric's "refez": the human looked at the result and pushed the phase
# again. Leaving it out of the ledger would hide the strongest friction signal there is.
echo "== retry invocation =="
: > "$LEDGER"
"$SDD" retry "$MISSION" >/dev/null 2>&1
assert_eq "sdd retry writes one session row" "1" "$(nrows)"
assert_eq "and marks itself as a retry invocation" "retry" "$(rows '.invocation')"
assert_eq "with its own run_id" "true" "$(rows '(.run_id | length) > 0')"
# L4 of the 2026-09-03 audit: the human's hand is written by the RUNNER, not remembered by the
# human. Measured: three launches and zero `- intervention:` notes on 20260901-o-revisor-so-acha,
# three interventions and zero notes on 20260902-o-rascunho-legado-fala-cru. The reader did not
# change — `sdd autonomy --by-mission` still counts `^- intervention:` in the checkpoint — only who
# writes did. Committed ALONE and at once (the cmd_approve precedent), so the clean-tree gates of
# the phase that follows still hold. Read as a pair: "1 dirty" fails by name.
notes() { grep -cE '^[[:space:]]*-[[:space:]]*intervention:' "$MDIR/checkpoint.md" || true; }
ck_clean() { [ -z "$(git -C "$FIX" status --porcelain -- "docs/handoffs/$MISSION/checkpoint.md")" ] && echo clean || echo dirty; }
assert_eq "sdd retry writes the intervention note in the checkpoint and commits it alone" "1 clean" \
  "$(notes) $(ck_clean)"
assert_eq "the note names the command, the phase and the date, in the form the template shows" "1" \
  "$(grep -cE '^- intervention: sdd retry .* — EXEC — [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · written by the runner$' "$MDIR/checkpoint.md" || true)"

echo "== --phase is the human's hand too, and the projection writes none =="
: > "$LEDGER"
"$SDD" run "$MISSION" --phase EXEC --max-phases 1 >/dev/null 2>&1 || true
assert_eq "sdd run --phase writes a second note, committed alone" "2 clean" "$(notes) $(ck_clean)"
"$SDD" run "$MISSION" --phase EXEC --dry-run >/dev/null 2>&1 || true
assert_eq "sdd run --phase --dry-run writes none and leaves the tree clean" "2 clean" \
  "$(notes) $( [ -z "$(git -C "$FIX" status --porcelain)" ] && echo clean || echo dirty)"
: > "$LEDGER"

echo "== the mission ceiling stops the line before a phase opens =="
# L2 of the 2026-09-03 audit. Measured: 20260902-o-rascunho-legado-fala-cru cost US$ 174.11 against
# a ceiling of US$ 150 that lived in the plan's prose — the runner had a cap per SESSION
# (--max-budget-usd) and none per mission, so a loop of cheap rounds never met a number. The sum is
# read off the mission journal (`cost_usd=` per line; `?` counts as nothing), BEFORE a phase opens,
# so the money that stops the line is money already spent, never a session cut mid-way. The
# fixture seeds three journal lines (100.5 + ? + 49.5 = 150.00) against a ceiling of 150.
: > "$LEDGER"
PLOG="$FIX/.sdd/logs/$MISSION/pipeline.log"; mkdir -p "$(dirname "$PLOG")"
if [ -f "$PLOG" ]; then cp "$PLOG" "$OUTSIDE/plog.bak"; else : > "$OUTSIDE/plog.bak"; fi
printf '%s\n' \
  "2026-01-01T10:00:00-03:00  EXEC  agent=sdd-executor  model=opus  session=a  rc=0  dur=1s  cost_usd=100.5  log=/dev/null" \
  "2026-01-01T10:01:00-03:00  REVIEW  agent=sdd-reviewer  model=opus  session=b  rc=1  dur=1s  cost_usd=?  log=/dev/null" \
  "2026-01-01T10:02:00-03:00  EXEC  agent=sdd-executor  model=opus  session=c  rc=0  dur=1s  cost_usd=49.5  log=/dev/null" >> "$PLOG"
printf 'BUDGET_MISSION_USD=150\n' >> .sdd/config.sh
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "US\$ 150.00 spent against a ceiling of 150 stops with rc 3: one budget-exhausted row, no session" \
  "3 1 blocked budget-exhausted EXEC yes" \
  "$rc $(nrows) $(rows '.event') $(rows '.kind') $(rows '.phase') $(rows '(.gate_why | test("mission budget"))' | sed 's/true/yes/;s/false/no/')"
assert_eq "and the journal says why, naming the phase that did not open" "1" \
  "$(grep -c 'BLOCKED  EXEC  mission budget' "$PLOG")"
: > "$LEDGER"
"$SDD" retry "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "sdd retry is stopped by the same ceiling (second door)" "3 budget-exhausted" "$rc $(rows '.kind')"
: > "$LEDGER"
dry_budget="$( "$SDD" run "$MISSION" --dry-run 2>&1 )"; rc=$?
assert_eq "the projection says how much is spent and never stops there" "0 0 1" \
  "$rc $(nrows) $(grep -c 'mission budget: US\$ 150.00 of 150' <<< "$dry_budget")"
n_before="$(notes)"
"$SDD" run "$MISSION" --budget-override --max-phases 1 >/dev/null 2>&1 || true
assert_eq "--budget-override goes on, and the runner notes it as an intervention, once" "$((n_before + 1)) 1" \
  "$(notes) $(grep -c 'intervention: sdd run --budget-override' "$MDIR/checkpoint.md")"
sed -i 's/^BUDGET_MISSION_USD=150$/BUDGET_MISSION_USD=0/' .sdd/config.sh
: > "$LEDGER"
"$SDD" run "$MISSION" --max-phases 1 >/dev/null 2>&1 || true
assert_eq "BUDGET_MISSION_USD=0 means no ceiling: no budget-exhausted row, a session opens" "0 yes" \
  "$(grep -c . <<< "$(rows 'select(.kind == "budget-exhausted") | .kind')") $(grep -q . <<< "$(rows 'select(.event == "session") | .event')" && echo yes || echo no)"
sed -i '/^BUDGET_MISSION_USD=/d' .sdd/config.sh
cp "$OUTSIDE/plog.bak" "$PLOG"
: > "$LEDGER"

# --- the EXEC row carries how many increments were left --------------------
# `outcome` cannot tell the pipeline's DESIGNED loop (one session per increment, the gate red
# until the last one) from real churn while the only facts on the row are the gate's verdict and
# whether the disk moved. Measured on 2026-08-29 over the real ledger: 46 of 72 EXEC rows read
# `churned` and about 5 of them were. The count gate_EXEC already computes for its own "N of M"
# sentence is what closes the hole, and it has to reach the row as NUMBERS — prose in `gate_why`
# is not a field, and parsing it back is the reader guessing at what the writer knew.
#
# The stub closes ONE of two increments on its first call and does nothing afterwards: the
# designed loop in miniature. Session 1 advances (2 → 1) with the gate still red; session 2 and
# its inline retry stand still, which is what churn actually looks like.
echo "== the EXEC row carries how many increments were left =="
: > "$LEDGER"
CKPT_TALLY_SAVED="$OUTSIDE/checkpoint.tally-saved"
cp "$MDIR/checkpoint.md" "$CKPT_TALLY_SAVED"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
| I2 | slice two | `true` → 0 | pending | — |
EOF
git add -A && git commit -qm "chore: two pending increments"
# OUTSIDE the fixture repo, like every other instrument in this file: a marker under $FIX would be
# swept into the next block's `git add -A` and move `state_fingerprint` because the TEST wrote,
# not because the session did.
TALLY_MARKER="$OUTSIDE/tally-once"
rm -f "$TALLY_MARKER"
# The hash is read BEFORE the stub's own commit and a commit follows it, exactly like the
# `done`-with-a-real-commit stub further down: gate_EXEC demands an ANCESTOR of HEAD, not merely
# an object in the database, so a hash taken after the commit would be refused.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$TALLY_MARKER" ]; then
  : > "$TALLY_MARKER"
  h=\$(git -C "$FIX" rev-parse --short HEAD)
  sed -i "/^| I1 /s/| pending | — |/| done | \$h |/" "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the session closed one increment"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1
assert_eq "an EXEC row carries pending_before, pending_after and increments_total" "2 1 2" \
  "$(jq -r -s '.[0] | "\(.pending_before) \(.pending_after) \(.increments_total)"' "$LEDGER")"
# The retry takes no snapshot of its own: the gate ran BETWEEN the two passes, so the first pass's
# `pending_after` already is the retry's starting point. Reading the checkpoint again there would
# sample a file the gate had judged one line earlier, and the retry would be credited with the
# progress of the pass before it. The `!= null` term is the floor — without it two absent fields
# satisfy the equality and the assertion measures nothing.
assert_eq "the inline retry starts where the first pass ended" "true" \
  "$(jq -s '.[2].auto_retry == true and .[1].pending_after != null
            and .[2].pending_before == .[1].pending_after' "$LEDGER")"

# --- a checkpoint the gate REFUSED publishes no count ----------------------
# `pending_before` is a photograph, `pending_after` is a VERDICT: the gate publishes it only after
# the validation loop, so a checkpoint marked `done` with no commit — the "a label is not an
# artifact" refusal — cannot buy its session an `advanced`. The row keeps the honest before and
# leaves the after null, which is exactly what makes the reader fall back to `moved`.
echo "== a refused checkpoint publishes no count =="
: > "$LEDGER"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
| I2 | slice two | `true` → 0 | pending | — |
EOF
git add -A && git commit -qm "chore: two pending increments again"
rm -f "$TALLY_MARKER"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$TALLY_MARKER" ]; then
  : > "$TALLY_MARKER"
  sed -i "/^| I1 /s/| pending | — |/| done | — |/" "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: a label with no artifact"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1
assert_eq "a done without commit publishes no pending_after" "2 null null" \
  "$(jq -r -s '.[0] | "\(.pending_before) \(.pending_after) \(.increments_total)"' "$LEDGER")"

# --- blocking an increment is the line STOPPING, not an increment advancing ---
# The sibling of the block above, and the one the ordering inside gate_EXEC missed. `blocked` is a
# valid checkpoint status, so the validation loop lets it through; the counts are published, and
# only THEN does the Jidoka refusal fire. But checkpoint_tally counts `pending|doing` and files
# `blocked` in a bucket of its own, so a session that gave up on an increment lowers `pending` by
# one exactly like a session that finished it: pending_before 2, pending_after 1, and `outcome`
# reads `advanced` over the one session in the whole pipeline that stopped the line.
#
# Fail-open in the flattering direction, which is the failure this mission exists to prevent, and
# it is not hypothetical: of the 2 EXEC rows still reading `churned` in the real ledger on
# 2026-08-30, ONE is exactly this session (sales_quote/20260825-cif-forma-pagamento, gate_why
# "1 increment(s) 'blocked' — Jidoka: the line stops"). It reads honestly today only because it
# predates the fields; written by this runner it would read `advanced` at 0% waste, and the
# instrument would lose its last accusation about a stopped line. The usage text of `sdd autonomy`
# promises "the EXEC session that CLOSED an increment" — blocking one is not closing it.
#
# The refusal has to publish NOTHING, like the `done`-with-no-commit refusal above: `pending_after`
# is a verdict, and there is no verdict to give about a checkpoint the gate is about to refuse for
# Jidoka. `pending_before` stays — it is a photograph, taken before the session, and it is what
# keeps this assertion from passing over an empty ledger.
echo "== a blocked increment publishes no count =="
: > "$LEDGER"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
| I2 | slice two | `true` → 0 | pending | — |
EOF
git add -A && git commit -qm "chore: two pending increments, before the block"
rm -f "$TALLY_MARKER"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$TALLY_MARKER" ]; then
  : > "$TALLY_MARKER"
  sed -i "/^| I1 /s/| pending | — |/| blocked | — |/" "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the session gave up on the increment"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1
assert_eq "a blocked increment publishes no pending_after" "2 null null" \
  "$(jq -r -s '.[0] | "\(.pending_before) \(.pending_after) \(.increments_total)"' "$LEDGER")"
# The witness, and it is not decoration: without it the assertion above is satisfied by ANY refusal
# that publishes nothing — an invalid status token, a checkpoint the stub failed to write — and it
# would go on passing over a fixture that stopped reaching the Jidoka path at all.
assert_eq "and the refusal that produced it is the Jidoka one" "true" \
  "$(jq -r -s '.[0].gate_why | test("Jidoka: the line stops")' "$LEDGER")"

# --- the inline retry starts where the pass before it stopped ---------------
# The third member of the family above, and the one the two blocks before it do NOT reach: they
# both stop at the FIRST pass, whose `pending_before` is the photograph cmd_run takes before the
# session opens. The inline retry gets its `pending_before` from a different place — `exec_after`,
# the first pass's PUBLISHED count — and when that first gate refused before publishing (either of
# the two refusals above) `exec_after` is the empty string, so the retry row was born with
# `pending_before: null`.
#
# That null is not inert, and this is the measured harm: `historic_progress` fires on ANY EXEC row
# whose `pending_before` is null and whose `gate_why` carries the `N of M` prose, so a row written
# by TODAY's runner falls down the compatibility path built for rows written before the fields
# existed. It is then handed a `pending_before` of M — the TOTAL, because the memory is empty —
# and reads `advanced` over a retry that advanced nothing. Reproduced end to end on 2026-08-30 with
# a real `sdd run` over this very fixture: the pass photographs `pending_before 1`, the retry
# leaves `pending_after 1`, and the reader answered `advanced` off a fabricated `2`. Fail-open in
# the flattering direction — the same family as the null guard of I2 and the Jidoka block above,
# and the failure this whole mission exists to prevent.
#
# Two further consequences the fix closes: `sdd autonomy` counted that row in its
# "older than the pending fields" disclosure, which is false about a row minutes old; and that
# count is the DELETION SIGNAL for the compatibility path, so the path could never reach zero.
#
# The fix is sound because cmd_run reaches its inline retry ONLY when `moved == "false"` — the
# first pass changed nothing, and `state_fingerprint` includes the checkpoint's md5 — so the file
# the retry starts on is byte-identical to the one the photograph read.
echo "== the inline retry records the count it started from =="
: > "$LEDGER"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | done | — |
| I2 | slice two | `true` → 0 | pending | — |
EOF
git add -A && git commit -qm "chore: a label with no artifact, and one increment still pending"
rm -f "$TALLY_MARKER"
# The FIRST session changes nothing — that is the only way to reach the inline retry, which is
# guarded on `moved == false`. The SECOND gives I1 the commit it was missing, so the retry's gate
# gets past validation and PUBLISHES a count while the pass before it did not.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$TALLY_MARKER" ]; then
  : > "$TALLY_MARKER"
else
  h=\$(git -C "$FIX" rev-parse --short HEAD)
  sed -i "/^| I1 /s/| done | — |/| done | \$h |/" "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the retry gives the increment its artifact"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1
# The floor, and it is what keeps the assertion below from passing over a run that never retried:
# it names the FIRST pass, proves it is the non-retry one, and proves its gate published nothing.
assert_eq "the pass before the retry is the one that published nothing" "false 1 null null" \
  "$(jq -r -s '.[0] | "\(.auto_retry) \(.pending_before) \(.pending_after) \(.increments_total)"' "$LEDGER")"
assert_eq "the inline retry records the count it started from" "true 1 1 2" \
  "$(jq -r -s '.[1] | "\(.auto_retry) \(.pending_before) \(.pending_after) \(.increments_total)"' "$LEDGER")"
# The harm, asserted where it lands rather than only at the writer: with a measured
# `pending_before` no row of this run is eligible for the compatibility path, so the reader's
# disclosure — which is also the signal that says when that path can be deleted — stays silent.
autonomy_out="$("$SDD" autonomy --all-repos 2>/dev/null)"
assert_eq "and no row this runner wrote is read as one that predates the fields" "0" \
  "$(grep -c 'read their progress from gate_why' <<< "$autonomy_out" || true)"

# --- the EXEC counts do not follow the run into the next phase -------------
# GATE_EXEC_PENDING outlives the gate that set it BY DESIGN — cmd_run reads it one screen after
# the call — so the phase guard at the read site is the only thing keeping the next phase's row
# from inheriting it. This block builds the sequence where that is reachable, and it took a
# sabotage pass to find out which sequence that is: `current_phase` runs as `$(...)`, so the
# gate_EXEC it evaluates on every lap sets those globals in a SUBSHELL that dies immediately, and
# the run→REVIEW fixture further down cannot reach the leak at all. The one that can is an EXEC
# gate that PASSES in the parent shell — door 1's own `gate_"$phase"` call — followed by another
# lap that opens a session for the next phase.
#
# A QA row carrying `pending_after: 0` would tell the judge QA advanced an increment it never had,
# and `waste` would fall for free across every mission in the ledger.
echo "== the EXEC counts do not follow the run into the next phase =="
: > "$LEDGER"
cp "$CKPT_TALLY_SAVED" "$MDIR/checkpoint.md"
git add -A && git commit -qm "chore: back to the single pending increment"
rm -f "$TALLY_MARKER"
# One call closes the only increment AND writes the handoff, so gate_EXEC passes in the parent
# shell on this very lap; the next lap finds QA unsatisfied and opens a session for it.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$TALLY_MARKER" ]; then
  : > "$TALLY_MARKER"
  printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
  h=\$(git -C "$FIX" rev-parse --short HEAD)
  sed -i "/^| I1 /s/| pending | — |/| done | \$h |/" "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the last increment closed and the handoff written"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1
# The floor is the EXEC row itself: it proves the gate really did pass in the parent shell and
# really did publish, so the nulls one row later are a guard doing its job and not an empty ledger.
assert_eq "the EXEC row that closed the last increment says so" "EXEC pass 1 0 1" \
  "$(jq -r -s '.[0] | "\(.phase) \(.gate) \(.pending_before) \(.pending_after) \(.increments_total)"' "$LEDGER")"
assert_eq "a non-EXEC row carries the three as null" "QA true" \
  "$(jq -r -s '.[1] | "\(.phase) \(.pending_before == null and .pending_after == null
                                 and .increments_total == null)"' "$LEDGER")"
# Row [2] is the same lap's INLINE RETRY of that QA session, and it is a THIRD read site of the
# globals — a door of its own, guarded by its own `if [ "$phase" = "EXEC" ]`. It was unprobed: with
# that guard removed the suite stayed green while the row came out carrying `pending_after: 0` and
# `increments_total: 1`, EXEC's numbers on a QA row, which is the reading that would tell the judge
# QA advanced an increment it never had. The fixture already wrote this row — the door cost a line
# to probe, not a world to build. One probe per door, the shape CLAUDE.md already spells out for
# handoff_blocked_escalation and app_down_escalation.
assert_eq "and so does the inline retry of that same non-EXEC phase" "QA true true" \
  "$(jq -r -s '.[2] | "\(.phase) \(.auto_retry) \(.pending_before == null and .pending_after == null
                                 and .increments_total == null)"' "$LEDGER")"
# The REVIEW half of the same door is NOT asserted here, and the reason is measured rather than
# assumed: `current_phase` evaluates its gates in a `$(...)` subshell, so no gate_REVIEW ever runs
# in the parent shell of this fixture and GATE_REVIEW_ROUNDS is still the empty string it was born
# with. Removing the `[ "$phase" = "REVIEW" ]` guard at both read sites leaves this block GREEN —
# measured, 258 assertions, no failure. The world where the leak is reachable is a REVIEW gate that
# PASSES in the parent shell followed by a lap that opens a DOCS session, and it is built in
# `== a REVIEW round that passed does not follow the run into the next phase ==` below.

cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"
rm -f "$MDIR/20-handoff-exec.md"
cp "$CKPT_TALLY_SAVED" "$MDIR/checkpoint.md"
git add -A && git commit -qm "chore: restore the single pending increment"
rm -f "$TALLY_MARKER"

# --- moved: true on a real change, false once nothing changes --------------
# Task 2 review measured this by hand: mutating `[ "$before" != "$after" ] && moved="true"` into a
# no-op left the whole suite GREEN, because every `claude` stub above is dead (rc 1) or dry — none
# of them ever touches the fixture repo, so `moved` was always "false" and nothing distinguished
# it from the mutant. `moved` is the headline number of the metric now (waste = sessions that did
# NOT move the disk), so this hole matters: a regression here both escalates BLOCKED on phases
# that are genuinely progressing and records every session as waste, with the suite still green.
#
# The stub is a SEPARATE PROCESS on every invocation of `claude`, so a shell variable set inside it
# would not survive to the next call — a marker FILE in the fixture counts invocations instead. On
# the first call it makes a real change (a new file) and commits it, which moves `git rev-parse
# HEAD` and therefore `state_fingerprint()`; on every later call it does nothing. No token, no
# network: the stub never shells out to the real `claude`.
echo "== moved: true on a real change, false once nothing changes =="
: > "$LEDGER"
MOVE_MARKER="$FIX/.moved-once"
rm -f "$MOVE_MARKER"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$MOVE_MARKER" ]; then
  : > "$MOVE_MARKER"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: session made a real change"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the checkpoint never reaches done, so it still escalates no-progress" "3" "$rc"
assert_eq "three session rows plus one escalation" "4" "$(nrows)"
assert_eq "the first session actually moved the disk" "true" "$(jq -r -s '.[0].moved' "$LEDGER")"
assert_eq "the second session, with nothing left to change, records moved:false" "false" \
  "$(jq -r -s '.[1].moved' "$LEDGER")"
assert_eq "the inline retry (same iteration) also records moved:false" "false" \
  "$(jq -r -s '.[2].moved' "$LEDGER")"
assert_eq "escalates no-progress once the disk stops moving" "no-progress" \
  "$(jq -r -s '.[3].kind' "$LEDGER")"

# --- sdd retry, when it DOES move the disk, records moved:true -------------
# The "== retry invocation ==" block above ran against the DEAD stub (rc 1, never touches the
# fixture repo), so it never exercised `moved` for `cmd_retry` at all. Reusing the moving stub and
# marker file from the scenario above and resetting the marker makes the stub commit again on
# this next invocation — the mutation this catches: replacing `cmd_retry`'s own
# `[ "$before" != "$after" ] && moved="true"` with a no-op leaves the suite green today.
#
# The reset has to be COMMITTED, not just deleted from disk: the marker is already a tracked file
# from the section above, and an uncommitted `rm` followed by the stub recreating it with the same
# (empty) content is a no-op diff from HEAD — `git commit` finds nothing to commit, HEAD does not
# move, and the assertion would fail for a reason that has nothing to do with `cmd_retry`.
echo "== sdd retry that moves the disk records moved:true =="
: > "$LEDGER"
rm -f "$MOVE_MARKER"
git -C "$FIX" add -A
git -C "$FIX" commit -qm "chore: reset move marker for the sdd-retry scenario"
"$SDD" retry "$MISSION" >/dev/null 2>&1
assert_eq "sdd retry that changed the disk records moved:true" "true" "$(rows '.moved')"

# --- the phase session stops being a blind spot while it runs ---------------
# `--output-format json` prints ONE blob, and only once the session is already over: the log file
# sits at 0 bytes for the ten minutes the phase takes, so a human watching a headless run has
# nothing to watch and a crashed session leaves no trace of how far it got. The runner now asks
# for `stream-json` and keeps the event stream in `<PHASE>-<ts>.stream.jsonl`, beside the
# `<PHASE>-<ts>.json` summary every other reader already knows. The replayed capture and its
# provenance are at the top of this file.
#
# Sabotage matrix (10 degradations of bin/sdd, control green, judged by the NAME of the assertion
# that falls — the I7 correction). Sole catchers, one per row:
#   buffered  — the session collected into a variable and written at exit → THE witness below
#   nostream  — the stream deleted once distilled                        → the whole-session shape
#   cost_field— the summary read for a field it no longer carries        → the cost parity
#   (in check-dry-run.sh: no_verbose → the --verbose count; both_formats → the absence half)
# Overlap, kept for the diagnosis and not for the coverage: `the .json summary is still exactly
# the result object` dies alongside the cost in all three sabotages that reach it, and never
# alone — it is what says WHY the cost went null instead of only that it did.
# Two survivors, named rather than hidden, and neither is reachable by any honest fixture: `head -1`
# for `tail -1`, and `select(true)` for `select(.type == "result")`. A real stream carries exactly
# one `result` object, so both are the SAME program on every input the CLI can produce — which is
# why mut_RUN_stream_summary_unfiltered anchors on the call site instead of on that body.
echo "== the phase session streams to disk while it runs =="
: > "$LEDGER"
# Hermetic: earlier blocks left their own phase logs here, written by stubs that answer nothing.
# `pipeline.log` is deliberately spared — a later block counts DEGRADED lines in it.
LOGDIR="$FIX/.sdd/logs/$MISSION"
rm -f "$LOGDIR"/*.json "$LOGDIR"/*.jsonl "$LOGDIR"/*.err

# The witness of the whole increment, and the only way a test can tell "streamed" from
# "buffered": the stub replays the capture in TWO writes and, BETWEEN them, reads back the file
# its own stdout is pointing at. It records the file NAME and how many lines were already on disk
# mid-session. A bare line count would not separate the two worlds — the old runner also has a
# file under its stdout, so it would also answer 2. The NAME is what separates them: `.json`
# under the old format, `.stream.jsonl` under the new one.
STREAM_WITNESS="$OUTSIDE/stream-witness"
rm -f "$STREAM_WITNESS"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
head -2 "$STREAM_SAMPLE"
# /proc/\$\$/fd/1, never /proc/self/fd/1: command substitution runs in a forked subshell whose
# fd 1 is the capture PIPE, so \`self\` would resolve to \`pipe:[…]\` and the witness would report
# "no file under stdout" under BOTH runners — red, but for the mechanism instead of the defect.
# \$\$ keeps the stub's own pid inside the substitution, and that fd 1 is still the runner's file.
target="\$(readlink "/proc/\$\$/fd/1" 2>/dev/null)"
if [ -n "\$target" ] && [ -f "\$target" ]; then
  printf '%s %s\n' "\$(basename "\$target")" "\$(wc -l < "\$target")" > "$STREAM_WITNESS"
else
  printf 'no-file-under-stdout -1\n' > "$STREAM_WITNESS"
fi
tail -1 "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1

witness="$(cat "$STREAM_WITNESS" 2>/dev/null || echo 'no-witness -1')"
# `EXEC-20260816-120000.stream.jsonl 2` → suffix `stream.jsonl`, count `2`.
witness_suffix="${witness%% *}"; witness_suffix="${witness_suffix#*.}"
# ONE assertion for the pair, not two. The adversarial pass tried both halves separately and no
# sabotage separated them: the count alone caught nothing the suffix did not, because buffering the
# session puts a PIPE under stdout and both halves go at once. Two rules where the sabotage finds
# one is the duplication the I5 waiver collapse already paid for once in this mission.
assert_eq "mid-session the runner's stdout was ALREADY the stream file, with what it wrote on disk" \
  "stream.jsonl 2" "$witness_suffix ${witness##* }"

streams=(); for f in "$LOGDIR"/*.stream.jsonl; do [ -f "$f" ] && streams+=("$f"); done
# Whole session, not only its summary. Reported as "the first file that disagrees, named" instead
# of a boolean, so a red says WHICH phase lost its stream. The empty-set guard is not decoration:
# a `for` over zero files runs the body zero times and answers "ok", which is the vacuity this
# whole block exists to refuse — with no runner change at all it would have been born green.
stream_shape="ok"
[ "${#streams[@]}" -ge 1 ] || stream_shape="no stream file was written at all"
for f in "${streams[@]}"; do
  n="$(grep -c . "$f")"
  [ "$n" = 3 ] || { stream_shape="$(basename "$f") has $n line(s), expected 3"; break; }
done
assert_eq "each session left a stream holding the WHOLE session — the events AND the result" \
  "ok" "$stream_shape"

# Parity, the half that protects every existing reader. `--output-format json` printed exactly
# the terminal `result` object and nothing else, so the summary file has to keep holding exactly
# that: one line, `type == "result"`. Everything downstream (the cost below, the `.err` sibling,
# the journal's `log=`) was written against that shape and is untouched by the format change.
summary_shape="no summary file was written at all"   # same empty-set guard, same reason
for f in "$LOGDIR"/*.json; do
  [ -f "$f" ] || continue
  summary_shape="ok"
  n="$(grep -c . "$f")"
  t="$(jq -r '.type' "$f" 2>/dev/null)"
  [ "$n" = 1 ] && [ "$t" = "result" ] || { summary_shape="$(basename "$f"): $n line(s), type=$t"; break; }
done
assert_eq "the .json summary is still exactly the result object the old format printed" \
  "ok" "$summary_shape"
# The headline of the parity: the number the judge sums. Reading the stream as if it were one blob
# yields one jq answer PER LINE, `tonumber?` refuses the multi-line string, and the cost silently
# becomes null — the ledger going quiet about money with the suite still green.
assert_eq "the ledger reads the cost out of the streamed session, to the last digit" \
  "0.0362104" "$(jq -r -s '.[0].cost_usd' "$LEDGER")"

# --- two sessions inside one second are two transcripts, not one -----------
# BUG-20260821-session-log-overwritten-in-the-same-second, filed Data-Loss: the log file name
# carried second-resolution time and nothing else, so the second session of a phase landed on the
# first one's path and destroyed a transcript the runner had just told the operator to go read.
# The journal recorded both sessions faithfully, with two different ids, and pointed both at the
# SAME file — which is how the loss is provable rather than merely suspected.
#
# The phase that costs the most is the one most likely to lose its evidence, because retrying is
# what puts two sessions in the same second in the first place. This fixture does not wait for
# that coincidence: it FREEZES the clock for the ONE format a log name is built from — both naming
# sites, bin/sdd:330 and bin/sdd:1696, spell it `+%Y%m%d-%H%M%S` — so
# the collision is the regime the assertion runs in every time instead of a race it usually loses.
# Everything else the runner asks `date` for — the journal's -Iseconds stamp, the duration's %s —
# goes to the real binary untouched, and the floor below proves the freeze is armed before any
# verdict is read. An environment rule whose poison is not armed is decoration.
#
# One `sdd run` against a stub that answers and changes nothing spends TWO sessions of one phase
# (the session and the runner's own inline retry) and then escalates — the second reproduction the
# bug report names, and the one that needs no second invocation.
echo "== a second session in the same second does not overwrite the first =="
: > "$LEDGER"
rm -f "$LOGDIR"/*.json "$LOGDIR"/*.jsonl "$LOGDIR"/*.err "$LOGDIR"/gate-*.log

# Resolved through the DEFAULT path, never through $PATH: the stub directory is already in front
# of it, and a `date` that resolved to the stub being written would recurse forever.
REAL_DATE="$(command -p -v date)"
cat > "$OUTSIDE/stub/date" <<STUB
#!/usr/bin/env bash
case "\$*" in
  "+%Y%m%d-%H%M%S") printf '20260101-120000\n' ;;
  *)                exec "$REAL_DATE" "\$@" ;;
esac
STUB
chmod +x "$OUTSIDE/stub/date"

# The floor, read through the same PATH the runner will use. Two terms and not one: the frozen
# format has to be frozen AND the passthrough has to still answer, or a stub that froze everything
# would make the collision unreachable for a reason that has nothing to do with the runner.
freeze="frozen=$(date +%Y%m%d-%H%M%S) passthrough=$(date -Iseconds | grep -c .)"

# The check command counts its own executions. `printf` exits 0 exactly like the `true` it
# replaces, so no gate changes its mind — what changes is that the number of times run_check_cmd
# actually ran the command becomes readable, and that number is what its log files have to match.
# The memo makes the two equal by construction: a cache hit runs nothing and writes no file.
CHECK_WITNESS="$OUTSIDE/check-witness"
: > "$CHECK_WITNESS"
sed -i "s|^TEST_CMD=.*|TEST_CMD=\"printf 'x\\\\n' >> $CHECK_WITNESS\"|" "$FIX/.sdd/config.sh"

# The checkpoint is walked to `done` for this block ALONE, and the reason is that gate_EXEC returns
# on a pending increment BEFORE it ever reaches run_check_cmd — with the fixture's usual checkpoint
# the check command is unreachable and its log files could never exist to collide. Every increment
# done and the suite green, the gate now fails one line further on, at the missing
# 20-handoff-exec.md: the phase stays EXEC, the sessions still run, and TEST_CMD runs once per gate
# evaluation because invalidate_checks empties the memo after every phase. Restored below, so the
# blocks after this one read the fixture they were written against.
CKPT_SAVED="$OUTSIDE/checkpoint.saved"
cp "$MDIR/checkpoint.md" "$CKPT_SAVED"
cat > "$MDIR/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | \`true\` → 0 | done | $(git -C "$FIX" rev-parse --short HEAD) |
EOF
git -C "$FIX" add -A && git -C "$FIX" commit -qm "chore: increment done, handoff still missing"

cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

# The journal is append-only and shared with every block above — deliberately never truncated here
# (a later block counts DEGRADED lines in it), so this run is read as the lines it ADDED.
JOURNAL="$FIX/.sdd/logs/$MISSION/pipeline.log"
jbefore="$(wc -l < "$JOURNAL" 2>/dev/null || echo 0)"
"$SDD" run "$MISSION" >/dev/null 2>&1
jnew="$(tail -n +$((jbefore + 1)) "$JOURNAL" 2>/dev/null || true)"

rm -f "$OUTSIDE/stub/date"
sed -i 's|^TEST_CMD=.*|TEST_CMD="true"|' "$FIX/.sdd/config.sh"
cp "$CKPT_SAVED" "$MDIR/checkpoint.md"
git -C "$FIX" add -A && git -C "$FIX" commit -qm "chore: restore the pending checkpoint"

sessions="$(grep -c "  EXEC  agent=" <<< "$jnew")"
pointers="$(grep -o 'log=[^ ]*' <<< "$jnew" | sort -u | grep -c .)"
# `transcripts` and not `streams`: an array by that name is live above, and shellcheck reads the
# reuse as SC2178 — the linter is right, two meanings for one name in one file.
transcripts=0; for f in "$LOGDIR"/EXEC-*.stream.jsonl; do [ -f "$f" ] && transcripts=$((transcripts + 1)); done

# Self-relative on purpose: the property is "one transcript per session", not "exactly two". The
# `ok` term is the anti-vacuity floor — with fewer than two sessions the counts agree trivially and
# the collision this block exists to reproduce never happened.
floor="ok"
[ "$sessions" -ge 2 ] || floor="only $sessions session(s) ran — the collision needs two"
[ "$freeze" = "frozen=20260101-120000 passthrough=1" ] || floor="the clock freeze is not armed: $freeze"
assert_eq "each session of one phase in one second left a transcript of its own, and the journal names it" \
  "$sessions $sessions ok" "$pointers $transcripts $floor"

# The same defect, one function over: run_check_cmd names the TEST_CMD log by time alone — and with
# no date at all, so two runs on different days at the same clock time collided too. It is the log
# GATE_WHY sends the operator to read, and `invalidate_checks` makes the gate run it again after
# every phase, so the overwrite is reachable inside a single process without any retry.
checklogs=0; for f in "$LOGDIR"/gate-*.log; do [ -f "$f" ] && checklogs=$((checklogs + 1)); done
runs="$(grep -c . "$CHECK_WITNESS")"
check_floor="ok"
[ "$runs" -ge 2 ] || check_floor="the check command ran $runs time(s) — the overwrite needs two"
assert_eq "each execution of the check command left the log the gate reason points at" \
  "$runs ok" "$checklogs $check_floor"

# --- and the human at the TERMINAL stops being the blind half -------------------------------
# The stream above closed the blind spot for whoever runs `tail -f` on the file. It did nothing
# for the person watching the run: `> "$streamfile"` takes claude's stdout off the terminal, so a
# phase prints its banner and then nothing for the ten to thirty minutes it lasts. Measured on
# the mission that introduced the stream: run alive, file growing 420 KB in 40 s, terminal silent.
# `stream_watch` is a background observer on the runner's OWN stderr — never a `tee`, because a
# pipeline would put the watcher's status where claude's has to be, which is the very defect the
# mutation below fixes in place.
#
# `SDD_PHASE_PROGRESS=1` forces it on: the guard is `auto` (a tty on fd 2) and no test has one, so
# without the override this whole behaviour would be unreachable from the suite — unsensored code
# shipped behind a condition the sensor can never meet.
echo "== the run says what it is doing while it does it =="
: > "$LEDGER"
rm -f "$LOGDIR"/*.json "$LOGDIR"/*.jsonl "$LOGDIR"/*.err

# The stub answers the sample AND exits non-zero: one run feeds both assertions, and the rc is
# what the second one is about.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
cat "$STREAM_SAMPLE"
exit 7
STUB
chmod +x "$OUTSIDE/stub/claude"

PROGRESS_ERR="$OUTSIDE/progress.err"
SDD_PHASE_PROGRESS=1 "$SDD" run "$MISSION" >/dev/null 2>"$PROGRESS_ERR" || true

# RED before the fix: nothing writes progress, so the marker is absent. The marker is asserted by
# NAME and not merely "stderr is non-empty" — warnings and gate reasons already land there, and a
# test that accepts any stderr would pass on a runner that only ever complains.
progress_seen="absent"
grep -q '⋯ session' "$PROGRESS_ERR" 2>/dev/null && progress_seen="present"
assert_eq "the phase reports progress on the terminal while the session runs" \
  "present" "$progress_seen"

# The watcher runs BESIDE the session, never in front of its exit status. Green before the fix by
# construction — there is no watcher to eat anything yet — and that is exactly what
# mut_RUN_progress_eats_rc is for: it moves the watcher into claude's pipeline, `rc` becomes the
# watcher's 0, and this line is the one that dies. Asserted from the JOURNAL and not from the
# runner's own exit code: the journal is what the kaizen judge reads, and a phase whose failure
# reaches the operator but not the record is the ledger blind spot all over again.
assert_eq "the session's own exit status still reaches the journal, not the watcher's" \
  "rc=7" "$(grep -o 'rc=[0-9]*' "$FIX/.sdd/logs/$MISSION/pipeline.log" | tail -1)"

# The session's stderr keeps going to its own file: progress is the RUNNER talking, and mixing the
# two would put the watcher's chatter inside the artifact that records what the session said.
assert_eq "the progress line did not leak into the session's .err sibling" \
  "" "$(cat "$LOGDIR"/*.err 2>/dev/null)"

# --- a session cut off mid-write does not take the whole run down with it ---
# The distillation above reads the stream with jq, and jq exits 5 the instant it meets a line it
# cannot parse — having already printed every well-formed object before it. A session killed while
# writing leaves exactly that shape: the whole events, the terminal `result` among them, and then
# a last line that starts and never ends. Under the runner's `set -euo pipefail` that 5 used to
# escape `stream_summary` and abort the bare call in `run_phase`. Measured on the un-fixed runner:
# rc **5**, terminal silent after the phase banner, `pipeline.log` without the phase line, and the
# ledger with **zero** rows — while `<PHASE>-<ts>.json` sat on disk holding the correct summary.
# The runner simply never lived to read what it had just written, and the session most worth
# recording is the one that produces this stream.
#
# The two assertions are ONE rule and its consequence, and the split is deliberate: the compound
# below dies to any degradation that lets the status escape, while the cost has an owner of its
# own — a "fix" that answers `{}` or `null` instead of the object jq did recover keeps the run
# alive and still empties the judge's money column. What is NOT here, for honesty: asserting that
# `<PHASE>-<ts>.json` still holds the result object would be born green, since the un-fixed runner
# writes that file correctly and only then dies.
echo "== a stream truncated by a killed session does not abort the run =="
: > "$LEDGER"
rm -f "$LOGDIR"/*.json "$LOGDIR"/*.jsonl "$LOGDIR"/*.err
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
cat "$STREAM_SAMPLE"
# The kill, in one line: an object that starts and never closes, and no trailing newline after it.
printf '{"type":"assistant","message":{"content":[{"type":"tex'
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
# ONE assertion for the pair. The rc alone is a label and this repo does not grade labels; the row
# count alone would also read 0 in a world where jq is simply absent (`autonomy_have_jq` returns
# early and the run still ends 3). Together they are the artifact AND the verdict: the run reached
# its own no-progress escalation — two dead sessions plus the escalation — instead of dying on
# somebody else's exit status.
assert_eq "the run ends on its OWN verdict with the sessions in the ledger, not on jq's rc" \
  "3 3" "$rc $(nrows)"
assert_eq "and the cost is still distilled out of the truncated stream, to the last digit" \
  "0.0362104" "$(jq -r -s '.[0].cost_usd' "$LEDGER")"

# --- an unknown cost has a NAME, and the name is `?` ------------------------
# The journal's money column has two ways of coming out unknown and, until this block, no fixture
# reached either. Every stub above answers either the full capture (cost present, asserted to the
# last digit) or nothing at all with rc 1 — and the dead one leaves an EMPTY summary, which is the
# second shape below. The ledger could not tell the difference: `($cost | tonumber? // null)` maps
# "?", "null" and "" to the same null, so an assertion that only reads the ledger is green in every
# world. The JOURNAL is where it shows, and the journal is what a human reads to reconstruct a
# headless run: `cost_usd=` with nothing after it is an unlabelled hole where every other row says
# `?`, and `cost_usd=null` is jq's word for "the key was absent" being filed as if it were an answer.
#
# TWO worlds because the runner has two guards, one per shape, and neither had a fixture:
#   A. an answer that carries no money — the `// "?"` arm of the jq filter;
#   B. an answer with no terminal `result` at all, so the summary is empty and jq exits 0 having
#      printed nothing — the `[ -n "$cost" ]` arm, which the `|| echo "?"` does NOT cover.
# ONE assertion over both, with the floor of each world beside its verdict: the costless sample
# really is a result object with no money in it, and world B's summary really is empty. Without
# those two terms the world could stop being the world the assertion names and nothing would say so.
echo "== an unknown cost is journalled as '?' in both of its shapes =="
# The captured sample MINUS its money, derived with jq and never pasted: the provenance rule at the
# top of this file covers this line too. A result object typed out here would be this file's idea
# of the CLI's shape, and the runner would be measured against that idea forever.
COSTLESS_SAMPLE="$OUTSIDE/stream-costless.jsonl"
jq -c 'del(.total_cost_usd, .cost_usd)' "$STREAM_SAMPLE" > "$COSTLESS_SAMPLE"
costless_floor="$(jq -rs '[.[] | select(.type == "result")]
                          | "\(length) \([.[] | select(has("total_cost_usd") or has("cost_usd"))] | length)"' \
                          "$COSTLESS_SAMPLE")"

: > "$LEDGER"
rm -f "$LOGDIR"/*.json "$LOGDIR"/*.jsonl "$LOGDIR"/*.err
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
cat "$COSTLESS_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"
"$SDD" run "$MISSION" >/dev/null 2>&1
cost_a_journal="$(grep -o 'cost_usd=[^ ]*' "$FIX/.sdd/logs/$MISSION/pipeline.log" | tail -1)"
cost_a_ledger="$(jq -r -s '.[0].cost_usd' "$LEDGER")"

: > "$LEDGER"
rm -f "$LOGDIR"/*.json "$LOGDIR"/*.jsonl "$LOGDIR"/*.err
# The first two lines of the capture and no `result`: the shape a session killed before its verdict
# leaves behind. stream_summary finds nothing to distil, so the summary file is created and stays
# at zero bytes — which is the state the second guard exists for.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
head -2 "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"
"$SDD" run "$MISSION" >/dev/null 2>&1
summary_b_lines="$(cat "$LOGDIR"/*.json 2>/dev/null | grep -c .)"
cost_b_journal="$(grep -o 'cost_usd=[^ ]*' "$FIX/.sdd/logs/$MISSION/pipeline.log" | tail -1)"
cost_b_ledger="$(jq -r -s '.[0].cost_usd' "$LEDGER")"

assert_eq "covered: an unknown cost is journalled as '?', both when the answer carries none and when there is no answer" \
  "1 0 cost_usd=? null 0 cost_usd=? null" \
  "$costless_floor $cost_a_journal $cost_a_ledger $summary_b_lines $cost_b_journal $cost_b_ledger"

# --- --max-phases stops the run where the human asked -----------------------
# The option is parsed, counted and reported, and nothing ever ran it. It is the flag a human
# reaches for to spend ONE session and look at the result — the cheapest way to drive a headless
# runner by hand — so a regression here is silent and expensive in the same breath: the run simply
# keeps going and opens every session the pipeline has left.
#
# The row count is the half that says WHERE it stopped, and the ordering it pins is deliberate: the
# gate is evaluated and the ledger row written BEFORE the limit is tested, so the session that ran
# is recorded rather than dropped on the way out. One row and not zero; three (two sessions plus the
# no-progress escalation) is what the same fixture writes with no limit at all — measured two blocks
# up, where the dead stub runs to its own escalation.
#
# The message rides along because the count alone cannot tell a stop from a crash, and because the
# number in it is the parsed value: a parse that dropped the argument would leave `max_phases` at 0,
# the branch unreachable, and the run would escalate exactly as if the flag had never been typed.
echo "== --max-phases 1 stops after one phase, with the row already written =="
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"
maxout="$( "$SDD" run "$MISSION" --max-phases 1 2>&1 )"; maxrc=$?
assert_eq "covered: --max-phases 1 stops after one phase, having written that phase's row first" \
  "0 1 said" \
  "$maxrc $(nrows) $(grep -q -- '--max-phases=1 reached' <<< "$maxout" && echo said || echo silent)"

# --- a kit without .git warns ONCE, not once per row ------------------------
# `autonomy_kit_stamp` used to be read as `stamp="$(autonomy_kit_stamp)"`, so the whole body ran in
# a subshell: its `AUTONOMY_SHA_WARNED=1` died with the command substitution, the flag was back to 0
# on the next call, and the warning its own comment calls "one-shot per process" fired once per
# ledger row. Nothing in the repo measured it, which is exactly why it survived review — the fix is
# publishing AUTONOMY_KIT_STAMP as a global instead of printing it.
#
# A kit copy WITHOUT .git is the only way to reach that branch at all: the real kit is a checkout.
# The copy takes the same set as check-mutation.sh's sandbox() — everything `sdd run` reads from
# $SDD_HOME and nothing more — and it lives in $OUTSIDE, since a kit copy under $FIX would be one
# more instrument inside the repo under test.
echo "== a kit that is not a git checkout warns once, not once per row =="
: > "$LEDGER"
KIT="$OUTSIDE/kit"
mkdir -p "$KIT"
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$KIT/"
# Back to the dead stub: two sessions that change nothing, so the run writes three rows (two
# sessions plus the no-progress escalation) and the warning gets three chances to repeat.
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
# stderr only: `2>&1 >/dev/null` dups stderr onto the capture pipe FIRST, then sends stdout away.
err="$( "$KIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
assert_eq "three rows were written, so the warning had three chances" "3" "$(nrows)"
assert_eq "a kit with no .git yields kit_sha:null on every row" "true" \
  "$(jq -s 'all(.kit_sha == null)' "$LEDGER")"
assert_eq "and the warning appeared exactly once" "1" \
  "$(grep -c 'is not a git checkout' <<< "$err")"

# --- the REVIEW row carries the round it advanced ---------------------------
# The defect 20260829-o-incremento-que-andou closed for EXEC, one phase further on. REVIEW is a
# LOOP BY DESIGN — REVIEW_MAX_ITER rounds, each landing its own 40-review-r<N>.md — and `outcome`
# knew a single arm of progress, `pending_after < pending_before`, which exists for EXEC alone. An
# r1 that landed with real findings and did not reach Grade A therefore read `churned`. Measured on
# the real ledger of window 2: the REVIEW of 20260830-a-tela-que-mente-o-pagamento is the most
# expensive cell of the whole slice at US$ 47.81, labelled `leve` off `1 advanced · 1 churned`.
#
# `rounds_max` is a third field and not decoration: without it "3 of 3, the phase is out of budget"
# is indistinguishable from "3 of 10" — the reading the `increments_total` of EXEC exists to close.
#
# `--phase REVIEW`, and that is the point of this fixture rather than a shortcut to reach the
# phase. The ceiling check that already calls review_rounds_on_disk sits behind
# `[ "$phase" = "REVIEW" ] && [ -z "$force_phase" ]`, so a photograph taken THERE would write
# `rounds_before: null` on every round a human forces — and forcing a round is exactly how a human
# unblocks a mission, the case where the number matters most. Taken outside that guard, this run
# proves it.
#
# `--max-phases 1` keeps the run to the one session this block is about: the gate refuses (Grade B),
# the disk moved, and without the ceiling the loop would take another lap and another phase.
echo "== the REVIEW row carries the round it advanced =="
: > "$LEDGER"
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: exec handoff and a skipped QA, for the review round"
# Same ordering as every other done-increment fixture in this file: the hash is read BEFORE the
# commit that carries it, and a commit follows — gate_EXEC demands an ANCESTOR of HEAD.
REV_DONE_HASH="$(git rev-parse --short HEAD)"
cat > "$MDIR/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | \`true\` → 0 | done | $REV_DONE_HASH |
EOF
git add -A && git commit -qm "chore: the increment is done, the mission is in REVIEW"
# Grade B, on purpose. A round that lands and PASSES is already `advanced` by the first arm of
# `outcome` (`gate == "pass"`), so a fixture whose gate passes cannot tell the new arm from the old
# one — the "red for the right reason" rule this repo pays for in CLAUDE.md. Here the gate refuses
# and the round still advanced, which is the only regime where the three fields mean anything.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
cat > "$MDIR/40-review-r1.md" <<'MD'
---
fase: REVIEW
gate: r1 landed with one real finding
---
### Overall Grade

| Criterion | Grade | Rationale |
|---|---|---|
| Correctness | B | One real finding, fixed next round. |
MD
git -C "$FIX" add -A
git -C "$FIX" commit -qm "chore: round one landed"
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" --phase REVIEW --max-phases 1 >/dev/null 2>&1
# The floor rides in the same assertion as the property: `REVIEW fail` proves the row is a REVIEW
# session whose gate REFUSED, so the round below is the designed loop advancing and not a passing
# gate wearing new fields. Read as three bare numbers this would go green over a gate that passed,
# where `outcome` never needed the new arm at all.
assert_eq "the REVIEW row carries rounds_before, rounds_after and rounds_max" "REVIEW fail 0 1 3" \
  "$(jq -r -s '.[0] | "\(.phase) \(.gate) \(.rounds_before) \(.rounds_after) \(.rounds_max)"' "$LEDGER")"
# Anti-vacuity of the regime: one lap, one session. A run that took a second lap would put another
# row here and the reading above would be about a session this block never described.
assert_eq "and --max-phases held the run to the one session this block is about" "1" "$(nrows)"

# --- a REVIEW round that passed does not follow the run into the next phase ---
# GATE_REVIEW_ROUNDS outlives the gate that set it BY DESIGN — cmd_run reads it one screen after the
# call — so the phase guard at the read site is the only thing keeping the next phase's row from
# inheriting a round count. A DOCS row carrying `rounds_after 1` over `rounds_before null` would
# tell the judge DOCS advanced a review round it never had.
#
# WHICH sequence reaches the leak took a sabotage pass to find out, exactly as it did for the EXEC
# sibling above: `current_phase` runs as `$(...)`, so every gate_REVIEW it evaluates sets the global
# in a subshell that dies immediately, and the `--phase REVIEW` block above cannot reach the leak at
# all. The one that can is a REVIEW gate that PASSES in the parent shell — door 1's own
# `gate_"$phase"` call — followed by another lap that opens a session for DOCS.
echo "== a REVIEW round that passed does not follow the run into the next phase =="
: > "$LEDGER"
rm -f "$MDIR"/40-review-r*.md
git add -A && git commit -qm "chore: no round on disk, so REVIEW is derived again"
# Call 1 lands a round that satisfies the gate — all Grade A, a real Rationale, a filled `gate:`
# field — and commits, so the tree is clean when gate_REVIEW reads it. Every later call does
# nothing: DOCS then spends a session and its inline retry without moving the disk, which is the
# cheapest way to get two non-REVIEW rows out of the lap that follows a passing REVIEW.
REVIEW_PASS_MARKER="$OUTSIDE/review-pass-once"
rm -f "$REVIEW_PASS_MARKER"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$REVIEW_PASS_MARKER" ]; then
  : > "$REVIEW_PASS_MARKER"
  cat > "$MDIR/40-review-r1.md" <<'MD'
---
fase: REVIEW
gate: suite green, tree clean, every criterion A
---
### Overall Grade

| Criterion | Grade | Rationale |
|---|---|---|
| Correctness | A | Read the diff line by line; no finding survived verification. |
MD
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: round one landed clean"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" >/dev/null 2>&1
# The floor is the REVIEW row itself: it proves the gate really did pass in the parent shell and
# really did publish, so the nulls one row later are a guard doing its job and not an empty ledger.
assert_eq "the REVIEW row of the round that satisfied the gate says so" "REVIEW pass 0 1 3" \
  "$(jq -r -s '.[0] | "\(.phase) \(.gate) \(.rounds_before) \(.rounds_after) \(.rounds_max)"' "$LEDGER")"
assert_eq "a non-REVIEW row carries the three round fields as null" "DOCS true" \
  "$(jq -r -s '.[1] | "\(.phase) \(.rounds_before == null and .rounds_after == null
                                 and .rounds_max == null)"' "$LEDGER")"
# The inline retry is a read site of its own — a second door, with its own `if [ "$phase" = "REVIEW" ]`
# — and this fixture already writes the row, so probing it costs a line rather than a world. One
# probe per door, the shape CLAUDE.md spells out for handoff_blocked_escalation.
assert_eq "and so does the inline retry of that same non-REVIEW phase" "DOCS true true" \
  "$(jq -r -s '.[2] | "\(.phase) \(.auto_retry) \(.rounds_before == null and .rounds_after == null
                                 and .rounds_max == null)"' "$LEDGER")"

# The fixture is restored before the block below: a 40-review-r<N>.md left on disk is a round the
# NEXT block's REVIEW_MAX_ITER=1 ceiling would count, and its whole regime (the runner re-entering
# the draft branch lap after lap) depends on the ceiling not firing before the first session.
rm -f "$MDIR"/40-review-r*.md
git add -A && git commit -qm "chore: the round is off the disk again"

# --- the phase that closed WITHOUT buying a session -------------------------
# A gate that passes spending no session writes nothing anywhere, so the judge has to infer the
# closure from an ABSENCE — and it infers wrong: `phase_label`'s third clause asks "did the last
# SESSION pass?" and stamps `refez`, the loudest friction signal in the rubric, on a phase that
# closed clean. Measured on window 2, the QA of 20260830-o-rascunho-fantasma-do-mount. The runner
# records the FACT instead; check-kaizen.sh measures what the rubric then does with it.
#
# THE WORLD IS THE QA⇄EXEC FIX LOOP, and it is the one the pipeline is designed around rather than
# a contrivance: no state changes between a failing gate and the next derivation UNLESS a phase
# runs in between, so "the gate passed without a session" is reachable only by going BACKWARDS
# first. QA files a bug and the fix increment for it, gate_QA refuses; the next derivation lands on
# EXEC (an earlier phase, with an increment pending); EXEC closes both; the derivation after that
# finds gate_QA green with no second QA session anywhere.
#
# FOUR laps and not three, and the fourth is not padding: the row is written at the TOP of the lap
# that derives REVIEW, and `gate_failed[QA]` is never cleared, so a run that stops there proves
# nothing about the one-shot marker — the fixture's regime would be standing in for the property.
# Lap 4 derives DOCS with QA still carrying its failed verdict, which is the only world where a
# second row can be born. `--max-phases 4` then ends the run on the DOCS session, sparing the
# fixture the no-progress escalation a dead DOCS stub would otherwise reach.
echo "== the gate that closed without a session is recorded, not inferred =="
: > "$LEDGER"
rm -rf "$FIX/docs/qa"
rm -f "$MDIR/30-handoff-qa.md"
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
git add -A && git commit -qm "chore: exec handoff, no QA artifact yet"
# The hash goes in only after its own commit exists, and a second commit follows: gate_EXEC demands
# the commit be an ANCESTOR of HEAD, not merely an object in the database.
GP_HASH="$(git rev-parse --short HEAD)"
cat > "$MDIR/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | true → 0 | done | $GP_HASH |
EOF
git add -A && git commit -qm "chore: the increment is done, so QA is what is derived"

GP_CALLS="$OUTSIDE/gatepass-calls"
: > "$GP_CALLS"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
echo x >> "$GP_CALLS"
n=\$(wc -l < "$GP_CALLS")
if [ "\$n" = "1" ]; then
  # The QA session: the handoff, one open bug an agent could close (anchor 3 refuses on it), and
  # the fix increment that will send the run BACKWARDS to EXEC.
  mkdir -p "$FIX/docs/qa/bugs"
  cat > "$FIX/docs/qa/bugs/b1.md" <<'MD'
# b1 — the mount draws a ghost
- **Status:** open
- **Closable by:** agent
MD
  printf -- '---\nfase: QA\nstatus: done\ngate: journey walked, evidence in the handoff\n---\n' \
    > "$MDIR/30-handoff-qa.md"
  cat > "$MDIR/checkpoint.md" <<'MD'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | true → 0 | done | HASH1 |
| F1 | fix the ghost | true → 0 | pending | — |
MD
  sed -i "s/HASH1/$GP_HASH/" "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: qa filed one bug and one fix increment"
elif [ "\$n" = "2" ]; then
  # The EXEC session: it closes the bug, which is what makes gate_QA pass later without QA ever
  # opening a second session — the whole point of this fixture.
  sed -i 's/Status:\*\* open/Status:** closed/' "$FIX/docs/qa/bugs/b1.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the fix increment landed"
  h2=\$(git -C "$FIX" rev-parse --short HEAD)
  sed -i "s/| F1 | fix the ghost | true → 0 | pending | — |/| F1 | fix the ghost | true → 0 | done | \$h2 |/" \
    "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: F1 is done"
elif [ "\$n" = "3" ]; then
  # The REVIEW session lands a round that satisfies its gate, so the run takes a FOURTH lap and
  # gate_pass_rows is asked a second time with QA's failed verdict still on the books.
  cat > "$MDIR/40-review-r1.md" <<'MD'
---
fase: REVIEW
gate: suite green, tree clean, every criterion A
---
### Overall Grade

| Criterion | Grade | Rationale |
|---|---|---|
| Correctness | A | Read the diff line by line; no finding survived verification. |
MD
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: round one landed clean"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" --max-phases 4 >/dev/null 2>&1
# THE FLOOR, and it comes first: without the QA→EXEC→REVIEW→DOCS sequence on disk every assertion
# below would be measuring an empty ledger and would pass by vacuity. The fourth phase is what
# makes "exactly one row" a statement about the one-shot marker instead of about the ceiling.
assert_eq "the fixture walked QA, back to EXEC, then on through REVIEW to DOCS" "QA EXEC REVIEW DOCS" \
  "$(jq -r -s '[.[] | select(.event == "session") | .phase] | join(" ")' "$LEDGER")"
# THE assertion of this increment: the closure is a row, not an absence.
assert_eq "the gate that closed without a session leaves a row naming the phase" "gate_pass QA" \
  "$(jq -r -s '[.[] | select(.event == "gate_pass")] | "\(.[0].event) \(.[0].phase)"' "$LEDGER")"
# THE ONE-SHOT, and it needs lap 4 to mean anything: `gate_failed[QA]` is never cleared, so every
# later derivation re-satisfies every other condition of the writer. Without the marker this reads
# 2 — one row per lap, into a file that is append-only by contract.
assert_eq "exactly one row: the closure is recorded once, not once per lap" "1" \
  "$(jq -s '[.[] | select(.event == "gate_pass")] | length' "$LEDGER")"
# THE NARROW CONDITION, and it is the assertion that keeps this writer from firing on every
# derivation. EXEC also closed its gate in this run — but it BOUGHT the session that closed it, so
# there is nothing here the ledger did not already say. `current_phase()` re-evaluates every gate
# on every derivation, so a writer without this condition would emit a row for every already-closed
# phase of every resumed run: up to six rows a lap, into a file that is append-only by contract.
assert_eq "a phase that closed WITH its own session gets no row" "0" \
  "$(jq -s '[.[] | select(.event == "gate_pass" and .phase == "EXEC")] | length' "$LEDGER")"
# The row belongs to the run and to the version, or the judge cannot put it on any axis. Same
# identity fields the escalation row carries, from the same three helpers.
assert_eq "it carries the run, the mission and the kit stamp" "true" \
  "$(jq -r -s --arg m "$MISSION" '[.[] | select(.event == "gate_pass")][0]
               | (.run_id | length) > 0 and .mission == $m
                 and .project == "fixture" and .invocation == "run"
                 and has("kit_sha") and has("kit_dirty")' "$LEDGER")"
# Session fields ABSENT, never zeroed — the same rule an escalation row obeys, for the same reason:
# a 0 here would enter the judge's arithmetic as a session that ran and did nothing.
# `. != null` is load-bearing and not belt-and-braces: jq 1.7 answers `null | has("rc")` with
# FALSE rather than an error (measured), so every conjunct below is satisfied by the absence of the
# row — the assertion would go green over an empty ledger, which is the vacuity this file spends
# its floors refusing.
assert_eq "and no session fields, because it spent no session" "true" \
  "$(jq -r -s '[.[] | select(.event == "gate_pass")][0]
               | . != null
                 and has("rc") == false and has("cost_usd") == false and has("moved") == false
                 and has("session") == false and has("gate") == false' "$LEDGER")"

# The human reader must not file a row the runner itself wrote under "unrecognized" — the same
# rule the `degraded` event bought one screen down, and the same failure it is: a disclosure line
# telling the operator the runner emitted something it does not understand.
gp_out="$("$SDD" autonomy 2>&1)"
assert_eq "the human reader does not call the recorded closure unrecognized" "0" \
  "$(grep -c 'unrecognized' <<< "$gp_out")"
assert_eq "it names the closure instead, so nothing leaves the accounting in silence" "1" \
  "$(num_before "$gp_out" 'gate\(s\) closed without a session')"
assert_bucket_sum "the buckets still sum to the header total (a recorded closure)" "$gp_out"

# --- cmd_retry photographs only the phase it is retrying --------------------
# `sdd retry` is the THIRD writer of the six count fields, beside cmd_run's first pass and cmd_run's
# inline retry, and it was the one with no assertion at all: the sibling probes above ("a non-REVIEW
# row carries the three round fields as null" and its EXEC twin) live in cmd_run and say nothing
# about this function. Sabotaged — either photograph guard deleted — the whole suite stayed green,
# and neither guard is inert: `review_rounds_on_disk` prints `0` rather than nothing, and
# `checkpoint_tally` always tallies. The row then carries counts the phase never had into the
# judge's arithmetic, which is the same contract break the cmd_run twin exists to refuse.
#
# THE FIXTURE IS FREE AT EXACTLY THIS POINT OF THE FILE, and that is why the block sits here rather
# than building a world of its own. The gate_pass block above leaves a mission whose EXEC, QA and
# REVIEW gates all pass, with a ROUND FILE and a full checkpoint still on disk — the one state where
# the sabotage is LOUD (`rounds_before: 1` on a DOCS row) instead of a `0` a reader could mistake for
# a count that was honestly taken.
#
# DECLARED, NO PROBE, and measured rather than assumed: the OTHER two guards of this function — the
# `review_after`/`review_max` and `exec_after`/`exec_total` pairs, read AFTER the gate call — are
# unreachable today. `cmd_retry` calls `gate_"$phase"` only for the phase it is retrying, and
# `current_phase()` runs its gates inside `$( )`, whose assignments die with the subshell; so
# `GATE_REVIEW_ROUNDS` and `GATE_EXEC_PENDING` still hold the empty string their declarations gave
# them (bin/sdd:736, :1015) and deleting those two guards changes no byte of the row. They stay
# because they decide WHICH failure the next writer gets the day a second gate call in the parent
# shell is added here. That is a world this fixture cannot build, NOT a claim that none exists —
# the distinction this repo paid for in d4deb35/7cbc8e2.
echo "== sdd retry photographs only the phase it is retrying =="
: > "$LEDGER"
# THE FLOOR, and it is a BLOCK-ORDERING CANARY rather than a probe of the guard — the distinction
# matters, and the first version of this comment got it wrong. It claimed that without the round
# file "the guarded and unguarded readings agree", which is measurably false: `review_rounds_on_disk`
# prints `0` when the glob matches nothing (bin/sdd:2686), `autonomy_session_row` maps `"0"` to the
# number 0 while `""` becomes null, and `0 == null` is FALSE in jq — so the sibling assertion below
# would catch the sabotage with or without this file. What the file actually protects is the
# IDENTITY of the block: remove it with an intact runner and the derivation lands on REVIEW instead
# of DOCS, so the three assertions below quietly stop being about a non-REVIEW `cmd_retry` row at
# all. Measured: four assertions of this block and the next go red that way. A floor whose stated
# reason is not its real reason is the false rationale this repo paid for in d4deb35/7cbc8e2, so the
# reason is written here as what it is.
assert_eq "the world has a round on disk, so the derived phase below is DOCS and not REVIEW" "1" \
  "$(find "$MDIR" -maxdepth 1 -name '40-review-r*.md' | wc -l)"
"$SDD" retry "$MISSION" >/dev/null 2>&1 || true
# The second floor: the phase actually retried is DOCS. If the derivation ever lands somewhere else
# the assertion below would be measuring the guard of the phase it is supposed to exempt.
assert_eq "the retried phase is DOCS, which is neither EXEC nor REVIEW" "DOCS retry 1" \
  "$(jq -r -s '"\(.[0].phase) \(.[0].invocation) \(length)"' "$LEDGER")"
assert_eq "and its row carries all six count fields as null" "true" \
  "$(jq -r -s '.[0] | .rounds_before == null and .rounds_after == null and .rounds_max == null
                      and .pending_before == null and .pending_after == null
                      and .increments_total == null' "$LEDGER")"

# --- an inline retry that PASSES leaves no false closure --------------------
# `gate_failed[$phase]` is written at both session sites of cmd_run, and until now only the FIRST
# had a probe: deleting the retry's own write left the suite green under a comment that invokes "one
# probe per door". The consequence is not cosmetic. It is a FALSE `gate_pass` row — permanent, in a
# file that is append-only by contract — saying a phase closed WITHOUT a session about a phase that
# closed with the very retry sitting one row above it. It then feeds `phase_label` (where a closure
# outvotes the sessions before it) and the `$closed` count the human reader prints.
#
# THE WORLD IS THE ONE EVERY OTHER FIXTURE IN THIS FILE MISSES, and that is why it was still open:
# every inline-retry fixture here ends on a retry that FAILS, and a failing retry writes the same
# `1` the first pass already wrote, so the sabotage is invisible. The retry has to PASS — and then
# the run has to take ANOTHER lap, because gate_pass_rows speaks only from the derived branch.
echo "== an inline retry that passes leaves no false closure =="
: > "$LEDGER"
DOCS_CALLS="$OUTSIDE/docs-retry-calls"
: > "$DOCS_CALLS"
# Call 1 is the DOCS session and does NOTHING on purpose: cmd_run reaches its inline retry only
# through the `moved == "false"` guard. Call 2 IS that retry, and it lands the drift checklist that
# makes gate_DOCS pass, so the phase closes by BUYING a second session.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
echo x >> "$DOCS_CALLS"
n=\$(wc -l < "$DOCS_CALLS")
if [ "\$n" = "2" ]; then
  printf '# Docs\n\ndrift checklist\n\n| Area | Doc | Status | Evidence |\n|---|---|---|---|\n| runner | README | ✅ | commit abc1234 |\n' \
    > "$MDIR/45-docs.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the retry landed the docs the first pass did not"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

"$SDD" run "$MISSION" --max-phases 2 >/dev/null 2>&1 || true
# FLOOR 1: the world was actually built. DOCS bought two sessions; the first failed its gate without
# moving the disk (the only route to the inline retry) and the second is the retry, which PASSED.
# Without this the assertion below goes green over any run that never reached a retry at all.
assert_eq "DOCS failed without moving, retried inline, and the retry passed" "2 fail false true pass" \
  "$(jq -r -s '[.[] | select(.event == "session" and .phase == "DOCS")]
               | "\(length) \(.[0].gate) \(.[0].moved) \(.[1].auto_retry) \(.[1].gate)"' "$LEDGER")"
# FLOOR 2: the run took the lap that ASKS. gate_pass_rows is called from the derived branch only, so
# a run that stopped on the passing retry would prove nothing about the verdict it left behind.
assert_eq "and the run took the next lap, so the writer was asked about DOCS" "DOCS DOCS PR" \
  "$(jq -r -s '[.[] | select(.event == "session") | .phase] | join(" ")' "$LEDGER")"
# THE assertion: a phase that closed WITH its own retry session did not close for free.
assert_eq "the phase whose inline retry passed gets no closure row" "0" \
  "$(jq -s '[.[] | select(.event == "gate_pass")] | length' "$LEDGER")"

# The fixture is restored for the block below, which needs a mission sitting in REVIEW: the QA
# tree, the QA handoff and — the one that bites — the round file lap 3 landed. A 40-review-r<N>.md
# left here is a round the next block's REVIEW_MAX_ITER=1 ceiling counts BEFORE its first session,
# and its whole regime (the runner re-entering the draft branch lap after lap) depends on the
# ceiling not firing that early. Measured: 15 assertions of that block died on the leftover file.
rm -rf "$FIX/docs/qa"
# `45-docs.md` joins the sweep because the block just above landed one: left on disk it makes
# gate_DOCS pass, and the degradation block below derives its phase from the same gates.
rm -f "$MDIR/30-handoff-qa.md" "$MDIR/45-docs.md" "$MDIR"/40-review-r*.md
git add -A && git commit -qm "chore: the qa artifacts, the round and the docs are off the disk again"

# --- the self-degradation review→draft leaves a trace -----------------------
# PUBLISH_ON_REVIEW_BLOCKED=draft is the runner deciding, ALONE, to stop reviewing and publish a
# draft PR anyway — the most interesting autonomy event a mission can produce. Until this
# assertion existed the branch's `force_phase="PR"; continue` jumped over BOTH writers (the
# journal and the ledger), so the whole history of the event was a run of failing REVIEW sessions
# followed by a PR phase, with nothing anywhere saying why. The judge reads the series; this
# event was invisible to it.
#
# Reaching the branch is the expensive part of the fixture: the mission has to actually BE in
# REVIEW, so PLAN, TICKET, EXEC and QA must all pass first. And the REVIEW session has to MOVE the
# disk — with a dead stub the no-progress escalation fires on the inline retry and the budget
# branch is never reached at all.
echo "== the self-degradation review→draft writes exactly one row =="
: > "$LEDGER"
cat >> .sdd/config.sh <<'EOF'
REVIEW_MAX_ITER=1
PUBLISH_ON_REVIEW_BLOCKED="draft"
EOF
printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "$MDIR/20-handoff-exec.md"
printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: exec handoff and a skipped QA"
# The hash goes into the checkpoint only AFTER its own commit exists, and a second commit follows:
# gate_EXEC demands the commit be an ANCESTOR of HEAD, not merely an object in the database.
DONE_HASH="$(git rev-parse --short HEAD)"
cat > "$MDIR/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | \`true\` → 0 | done | $DONE_HASH |
EOF
git add -A && git commit -qm "chore: the increment is done"

# Moves the disk on EVERY call — the REPETITION regime, and the whole reason the F1 increment
# exists. This stub used to move on the first call only, which held the runner to a single lap of
# the draft branch; "the degradation wrote exactly one row" below was then a property of the
# FIXTURE, not of the code. Under a stub that always moves, the run goes REVIEW→PR→REVIEW with the
# REVIEW budget still blown, re-enters the branch on every lap, and the pre-F1 runner wrote one row
# per lap: 3 rows for 1 degradation, against the "exactly one" of the mission's metric 3. It is the
# THIRD vacuity of this mission — after I1's shared rc 3 and I2's never-reached draft branch — and
# the reason a fixture regime is never allowed to stand in for the property being asserted.
DRAFT_LAPS="$OUTSIDE/draft-laps"
: > "$DRAFT_LAPS"
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
echo x >> "$DRAFT_LAPS"
wc -l < "$DRAFT_LAPS" > "$MDIR/churn.txt"
git -C "$FIX" add -A
git -C "$FIX" commit -qm "chore: the session changed something"
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"

# stderr only (`2>&1 >/dev/null`), the same idiom the kit-stamp block above uses: the warn line is
# the runner announcing out loud that it entered the branch, and counting it is what proves the
# regime. It is deliberately OUTSIDE the one-shot guard in bin/sdd — the runner really is jumping
# to PR on this lap, and an assertion over the writers must not be its own witness.
err="$( "$SDD" run "$MISSION" 2>&1 >/dev/null )"; rc=$?
assert_eq "the run still ends in an escalation, whichever path took it there" "3" "$rc"
# I9 — THE LOOP HALF. `force_phase="PR"` never ended the run: PR ran, its own gate failed, and
# `current_phase` handed REVIEW straight back with the budget still blown, so the runner re-entered
# the branch lap after lap (measured before the fix: warn 3×, PR sessions 3). F1 closed the RECORD
# half — one row per run — and left the spin itself in TODO.md. This closes the spin: the draft PR
# gets ONE chance, and if its gate fails too the run ends on the `blocked`/`budget-exhausted` pair
# that already sat below the branch. No new event entered the ledger's enum.
#
# The five assertions below were put through a sabotage pass, and the matrix is worth writing down
# because it is NOT the obvious one. The announcement count no longer witnesses the loop at all:
# the warn moved inside the one-shot guard, so `degraded_logged` pins it and restoring the spin
# leaves it at 1. What it is the SOLE catcher of is the warn moving back OUTSIDE that guard, where
# the terminal announces "moving on to PR" on the very lap the run ends. The spin itself is caught
# by the session count and the phase; see each assertion for its own owner.
laps="$(grep -c 'moving on to PR in draft mode' <<< "$err")"
assert_eq "the draft jump is announced once, because it now happens once" "1" "${laps:-0}"
# Sole catcher of the spin's session cost, and the assertion that dies loudest if the branch stops
# being reached at all.
assert_eq "and the draft PR got exactly the one session it was promised" "1" \
  "$(jq -s '[.[] | select(.event == "session" and .phase == "PR")] | length' "$LEDGER")"
# ANTI-VACUITY OF THE REGIME, in its I9 form — and the assertion this increment could most easily
# have got wrong. The old witness was "the branch was entered >= 2 times", which is the very number
# the fix drives down to 1: kept as-is it would fail on the fix, and simply flipped to "== 1" it
# would go green on a fixture that never reached the branch a SECOND time at all — the fixture
# standing in for the property again, the vacuity this block already paid for once.
#
# So the witness moves to the only row a second entry can produce. The FIRST entry `continue`s past
# the blocked pair below; the only way to reach it in phase REVIEW is to come back with the budget
# still blown — which is exactly the lap the pre-I9 runner spent spinning. `budget-exhausted` in
# REVIEW therefore proves both halves at once: the fixture is still in the repeating regime, AND
# the runner stopped instead of taking another lap.
#
# It is also the assertion that measured the defect most sharply: against the pre-I9 runner this
# read **PR**, not REVIEW. The spin did not merely waste laps — it handed the escalation to the
# phase that was never over budget, so the ledger blamed PR for a ceiling REVIEW had blown three
# laps earlier, and every reader downstream inherited that.
assert_eq "the run came BACK to the blown REVIEW budget — the lap the old runner spun on" "REVIEW" \
  "$(jq -r -s '[.[] | select(.event == "blocked")][0].phase' "$LEDGER")"
# THESE TWO WERE BORN GREEN, and they stay — the I3 precedent in this mission. Against the pre-I9
# runner the ending already carried `budget-exhausted` and already happened once, just in the wrong
# phase, so neither measured the defect. The sabotage pass is what earned them their place: each is
# the SOLE catcher of one way the fix could be got wrong later — inventing a `draft-exhausted` kind
# instead of reusing the pair (which all three `is_escalation` readers would file as unrecognized),
# and writing the row on the fall-through as well as in the branch.
assert_eq "and it ends on the pair that already existed, with no new event in the enum" \
  "budget-exhausted" "$(jq -r -s '[.[] | select(.event == "blocked")][0].kind' "$LEDGER")"
# The DERIVED-BRANCH-ONLY rule of gate_pass_rows, and THIS is the fixture that reaches it — the
# only path in cmd_run where `force_phase` survives into a lap that already has a failed phase
# behind it. The degradation jumps to PR over a REVIEW whose gate is still failing; a writer
# running on that lap would read "every phase before PR has closed" off a derivation that never
# happened, and record that the phase the runner GAVE UP ON closed cleanly. That is the loudest
# possible lie in a ledger whose whole purpose is to hold what the runner measured, and it is one
# `else` away: measured by moving the call out of the derived branch, this reads 1.
assert_eq "the phase the runner gave up on records no gate closure" "0" \
  "$(jq -s '[.[] | select(.event == "gate_pass")] | length' "$LEDGER")"
assert_eq "exactly one blocked row: a run ends once" "1" \
  "$(jq -s '[.[] | select(.event == "blocked")] | length' "$LEDGER")"
# Kept from F1: a PR session with the REVIEW gate still failing can only exist BECAUSE the runner
# degraded — `current_phase` would hand back REVIEW forever otherwise. It is what says every
# assertion in this block is pointed at the right branch, and it holds with or without the writer.
assert_eq "and no REVIEW gate ever passed, so nothing but the degradation could have moved it" \
  "0" "$(jq -s '[.[] | select(.phase == "REVIEW" and .gate == "pass")] | length' "$LEDGER")"
# THE METRIC OF F1, and now a property of the code rather than of the stub: the runner lowered its
# own bar ONCE in this run and the ledger says so once, however many laps the REVIEW→PR→REVIEW loop
# takes afterwards with the budget still blown. The laps are a defect of their own — the loop half
# — and it stays in TODO.md; what this asserts is the RECORD half.
assert_eq "the degradation wrote exactly one row, however many laps the loop took" "1" \
  "$(jq -s '[.[] | select(.event == "degraded")] | length' "$LEDGER")"
# `degraded` and not `blocked`: `blocked` means the line STOPPED and the runner returns 3. Here
# the run went ON, to PR. Reusing `blocked` would have been cheaper — it inherits the kit_sha axis
# and the series aggregation for free — but it would record "stopped" for a run that continued,
# and the ledger exists to record fact.
assert_eq "the event says the run degraded, not that it stopped" "degraded" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].event' "$LEDGER")"
assert_eq "kind names the degradation by enum, not by prose" "review-to-draft" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].kind' "$LEDGER")"
assert_eq "the phase that degraded" "REVIEW" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].phase' "$LEDGER")"
assert_eq "and the mission it happened in" "$MISSION" \
  "$(jq -r -s '[.[] | select(.event == "degraded")][0].mission' "$LEDGER")"

# D6 — the blocked line counts SESSIONS, not laps of the loop. `attempts[$phase]` rises on every
# lap that reaches the top with this phase, including the lap that escalates (which opens no
# session at all) and every later lap the REVIEW→PR→REVIEW loop takes. The number is the last thing
# a human reads when a run ends, and here it said `3 sessions` over a ledger holding ONE REVIEW
# session. Prefixed `output:` with the reader assertions further down, but it lives HERE because
# this is the only fixture in the file that reaches the budget branch at all — the mission has to
# really be in REVIEW, and the stub has to move the disk on every call.
#
# DIFFERENTIAL against the ledger, and `agree/total` rather than a single number: the branch is
# entered twice in this run (once to degrade, once to end it), so an assertion reading only the
# first occurrence would go green on a fix that repaired one voice and left the other. `0/0` is the
# vacuity floor — a fixture that stopped reaching the branch fails instead of passing on nothing —
# and the REVIEW session count on the left pins the regime that makes laps and sessions differ.
#
# `session[^ ]*` and not the literal spelling: the defect is the NUMBER, and a pattern written
# against the post-fix wording would have gone red on the plural alone — measured, it read `0/0`
# against the old runner and would have called a pure rename a fix.
rev_sessions="$(jq -s '[.[] | select(.event == "session" and .phase == "REVIEW")] | length' "$LEDGER")"
blocked_says="$(awk -v n="$rev_sessions" '
  { s = $0
    while (match(s, /[0-9]+ session[^ ]* without satisfying the gate/)) {
      total++
      if (substr(s, RSTART, RLENGTH) + 0 == n) agree++
      s = substr(s, RSTART + RLENGTH)
    } }
  END { printf "%d/%d", agree + 0, total + 0 }' <<< "$err")"
assert_eq "output: the blocked line counts the sessions the phase spent, not the laps of the loop" \
  "1 2/2" "$rev_sessions $blocked_says"
# The kit stamp is what puts the row on the version axis the whole ledger exists to measure. A
# writer that forgot it would still look fine in `sdd autonomy` and vanish from the series.
assert_eq "the row carries the kit stamp, so it lands on the version axis" "true" \
  "$(jq -s '[.[] | select(.event == "degraded")][0] | has("kit_sha") and has("kit_dirty")' "$LEDGER")"
assert_eq "it shares the run_id of the run that produced it" "true" \
  "$(jq -s '([.[] | select(.event == "degraded")][0].run_id) == (.[0].run_id)' "$LEDGER")"
# Same refusal as autonomy_blocked_row: a degradation spends no session of its own, so a 0 in the
# session fields would enter the judge's arithmetic as if it had.
assert_eq "no session fields on a degradation" "true" \
  "$(jq -s '[.[] | select(.event == "degraded")][0]
            | has("rc") == false and has("cost_usd") == false and has("moved") == false' "$LEDGER")"
assert_eq "the gate reason that triggered it rides along" "true" \
  "$(jq -s '([.[] | select(.event == "degraded")][0].gate_why | length) > 0' "$LEDGER")"
# The journal is the human's trail and the ledger is the judge's; the `continue` skipped BOTH, so
# both are asserted here.
assert_eq "the pipeline journal records it too" "1" \
  "$(grep -c 'DEGRADED' "$FIX/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || echo 0)"
# The human reader must not file a row the runner itself wrote under "unrecognized": that would
# just move the blind spot from the judge to the human.
#
# The kit stamp is NORMALISED first, and only for the reader assertions below. Since I3 the
# escalation table lives on the kit_sha axis and drops non-comparable rows, and the stamp these
# rows carry is whatever the kit checkout happened to be at test time: a dirty working tree (any
# EXEC session) or the no-.git copy check-mutation.sh sandboxes into make every row here
# non-comparable, and the block would pass in CI and fail on the developer's machine, or the other
# way round. The rows stay exactly as the RUNNER wrote them in every other respect — that they
# carry a stamp at all is asserted above, against the untouched ledger.
jq -c '.kit_sha = "deadbee" | .kit_dirty = false' "$LEDGER" > "$LEDGER.norm" && mv "$LEDGER.norm" "$LEDGER"
out="$( "$SDD" autonomy 2>&1 )"
assert_eq "the human reader does not call it unrecognized" "0" "$(grep -c 'unrecognized' <<< "$out")"
assert_eq "it is counted as an escalation, by its kind" "1" \
  "$(grep -c 'review-to-draft: 1' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (a ledger with a degradation)" "$out"
# The other half of metric 3: the judge has to read the same single degradation the human does.
# One instrument counting 1 while the other counts 3 is the divergence I3 closed for the axis —
# cardinality is the same failure one field over, so both readers are asserted, not just one.
series="$( "$SDD" kaizen --series 2>/dev/null )"
assert_eq "and the judge counts the same one, not one per lap" "1" \
  "$(jq -r '.latest.escalations["review-to-draft"] // 0' <<< "$series")"
assert_eq "with nothing pushed into the unrecognized bucket to get there" "0" \
  "$(jq -r '.excluded.unrecognized' <<< "$series")"

# --- `status: blocked` in the handoff escalates on the FIRST session ---------
# `blocked` already MEANS "the line stopped; the runner returns 3 and a human has to act"
# (bin/sdd:1602), and gate_QA has always refused it (:564). What was missing is that the refusal
# went through the fingerprint heuristic like any other: session 1 fails the gate, the runner
# retries, session 2 fails it identically, and only THEN does `no-progress` escalate. A phase
# nobody can satisfy paid for proving its own unsatisfiability twice, at one session apiece —
# and when the session did commit something honest, `moved=true` bought yet another lap instead.
# Measured in 20260825-frete-cif-fob: 7 of the 12 QA sessions were in that loop, US$ 73,32.
#
# ONE assertion, and it is DIFFERENTIAL on purpose. "rc 3" is shared with every escalation in this
# file, and "one session" alone would be satisfied by a runner that escalated on the first session
# for ANY failing gate — which is the over-broad fix, not the fix. So the same fixture is run twice
# and the two outputs are compared against each other: the `blocked` handoff must escalate on
# session 1 by its own enum, and a handoff that fails the gate for an ordinary reason (no `gate:`
# evidence, the no-interface branch at :568) must still spend its two sessions and still land on
# `no-progress`. Either half alone passes under a mutant; together neither does.
echo "== status: blocked escalates on the first session, an ordinary gate failure does not =="
# The dead stub: no session moves the disk, so the control regime reaches `no-progress` — which is
# also what makes the two halves differ ONLY in the reason the gate refused.
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"

# blocked_shape <expected-phase> -> "<rc>|<session rows>|<event>|<kind>" for the run just made.
blocked_shape() {
  printf '%s|%s|%s|%s' "$1" \
    "$(jq -s '[.[] | select(.event == "session")] | length' "$LEDGER")" \
    "$(jq -r -s '[.[] | select(.event == "blocked")][0].event' "$LEDGER")" \
    "$(jq -r -s '[.[] | select(.event == "blocked")][0].kind' "$LEDGER")"
}

: > "$LEDGER"
printf -- '---\nfase: QA\nstatus: blocked\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: QA handoff declares blocked"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
qa_blocked="$(blocked_shape "$rc")"

: > "$LEDGER"
# Same phase, same stub, same everything — only the REASON the gate refuses changes. `done` with
# no `gate:` field is the ordinary failure of the no-interface branch (bin/sdd:568).
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: QA handoff without the gate evidence"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
qa_ordinary="$(blocked_shape "$rc")"

assert_eq "status: blocked escalates on the first session, where an ordinary gate failure still spends two" \
  "3|1|blocked|handoff-blocked · 3|2|blocked|no-progress" \
  "$qa_blocked · $qa_ordinary"

# --- ...and a `--max-phases` ceiling does not turn that into rc 0 -----------
# Door 1 used to sit BELOW the ceiling check, so `sdd run --max-phases 1` against this very
# handoff opened and paid for a QA session, armed the marker, and returned **0**: no ledger row,
# no pipeline.log line, and a SUCCESS exit code for a phase nobody in the pipeline can satisfy.
# The two sibling Jidokas — the `blocked` increment and the dirty tree — sit ABOVE the ceiling and
# escalate whatever it says, so the third one alone answered the flag first. An operator or a CI
# wrapper pacing the pipeline one phase at a time got the pre-fix loop for ever, wearing a green
# rc. Found in the REVIEW round of 20260826-o-laco-da-qa.
#
# DIFFERENTIAL, and it refuses BOTH over-broad readings in one pair: a runner that escalated
# whenever `--max-phases` is set takes the CONTROL half red (an ordinary gate failure under the
# same flag must still end `0`, with no escalation row at all), and a runner where the ceiling
# always wins takes the BLOCKED half red. Only the word in the handoff differs between the runs —
# same mission, same dead stub, same flag, same ceiling.
: > "$LEDGER"
printf -- '---\nfase: QA\nstatus: blocked\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: QA handoff declares blocked, under a ceiling"
"$SDD" run "$MISSION" --max-phases 1 >/dev/null 2>&1; rc=$?
qa_ceiling_blocked="$(blocked_shape "$rc")"

: > "$LEDGER"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: ordinary gate failure, under the same ceiling"
"$SDD" run "$MISSION" --max-phases 1 >/dev/null 2>&1; rc=$?
qa_ceiling_ordinary="$(blocked_shape "$rc")"

assert_eq "a --max-phases ceiling does not turn a blocked handoff into rc 0, where an ordinary failure still ends 0" \
  "3|1|blocked|handoff-blocked · 0|1|null|null" \
  "$qa_ceiling_blocked · $qa_ceiling_ordinary"

# --- ...and it escalates from the INLINE RETRY on the same terms -------------
# The branch above sits on the FIRST pass only. The inline retry (bin/sdd:3538) calls the same gate,
# which sets the same marker, but the code below it consults `moved2` and nothing else — so a retry
# session that declares `blocked` and COMMITS the declaration reads as "moved forward, carrying on"
# and buys exactly the lap this mission exists to delete. The runner's own words for the marker are
# "another session would re-read the same handoff and refuse the same way", and that is precisely
# what the extra session then does: it re-reads the same `blocked` handoff and refuses identically.
#
# Reachable without contrivance: session 1 dies or writes nothing (moved=false is what SUMMONS the
# retry), and the retry is the one that does the honest work of declaring the line stopped.
#
# DIFFERENTIAL against the first-pass regime above, and on the SAME enum: both must land on
# `handoff-blocked`, so what the pair isolates is WHEN — the declaration itself, or one lap later.
# Asserting the retry shape alone would be satisfied by a runner that escalates every retry, which
# is the over-broad fix and would take the `no-progress` half of the block above red with it.
: > "$LEDGER"
RETRY_MARKER="$OUTSIDE/.retry-declares-blocked"
rm -f "$RETRY_MARKER" "$RETRY_MARKER.2"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: QA handoff the retry session will replace"
# Separate process per invocation, so the invocation count lives in marker FILES — same idiom as the
# `moved` block above. Call 1 changes nothing (that is what makes the runner retry at all); call 2,
# the inline retry, declares blocked and commits it.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$RETRY_MARKER" ]; then
  : > "$RETRY_MARKER"
  exit 1
fi
if [ ! -e "$RETRY_MARKER.2" ]; then
  : > "$RETRY_MARKER.2"
  printf -- '---\nfase: QA\nstatus: blocked\n---\n' > "$MDIR/30-handoff-qa.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the retry session declares the line stopped"
  exit 0
fi
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
qa_retry_blocked="$(blocked_shape "$rc")"

assert_eq "a retry session that declares blocked escalates on that declaration, not a lap later" \
  "3|1|blocked|handoff-blocked · 3|2|blocked|handoff-blocked" \
  "$qa_blocked · $qa_retry_blocked"

# ...and the lap it survives into escalates the WRONG PHASE, with a reason that is not true of it.
# The marker is a global; `current_phase` is a SUBSHELL and cannot clear the parent's copy; and
# gate_EXEC — like every gate but gate_QA — never touches it. So when the retry above carries on,
# the next lap runs gate_EXEC with the marker still 1 and the reader at :3498 fires for EXEC: the
# runner prints "the phase's handoff declares 'status: blocked'" about 20-handoff-exec.md, which
# says `done`, swallows the retry EXEC was owed, and writes {phase: EXEC, kind: handoff-blocked}
# into the ledger the kaizen judge reads. It is the exact failure the CONTRACT above
# GATE_HANDOFF_BLOCKED (:508-511) warns a SECOND setter about — reached with only the first one,
# because the marker outlives the lap rather than a gate.
#
# Reached by the pipeline's own instructions, not by contrivance: `agents/sdd-qa.md` § 4 tells the
# QA session to answer a fixable bug with an `F<n>` row that is `pending`, and a pending row is
# precisely what sends the next lap to EXEC. QA doing its job is the trigger.
#
# DIFFERENTIAL, and the control is what keeps it from passing vacuously: both regimes append the
# same `F<n>` row, so both genuinely offer EXEC as the next phase — asserting "it escalates QA"
# alone would also pass on a fixture that never left QA at all. Only the word in the QA handoff
# differs, and it must not be able to relabel an escalation that belongs to another phase.
CKPT_BEFORE_WRONG_PHASE="$OUTSIDE/checkpoint-before-wrong-phase.md"
cp "$MDIR/checkpoint.md" "$CKPT_BEFORE_WRONG_PHASE"
QA_DECL="$FIX/.qa-status-the-retry-declares"
# One stub for both regimes, reading the word from a file: two hand-written stubs would be two
# places for the regimes to drift apart, and what the pair measures is that ONLY that word differs.
cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$RETRY_MARKER" ]; then : > "$RETRY_MARKER"; exit 1; fi
if [ ! -e "$RETRY_MARKER.2" ]; then
  : > "$RETRY_MARKER.2"
  printf -- '---\nfase: QA\nstatus: %s\n---\n' "\$(cat "$QA_DECL")" > "$MDIR/30-handoff-qa.md"
  printf -- '| F1 | the fix QA asked for | \`true\` → 0 | pending | — |\n' >> "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the retry session reports, and opens a fix increment"
  exit 0
fi
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"

# blocked_where -> "<phase>|<kind>" of the escalation row.
blocked_where() {
  printf '%s|%s' \
    "$(jq -r -s '[.[] | select(.event == "blocked")][0].phase' "$LEDGER")" \
    "$(jq -r -s '[.[] | select(.event == "blocked")][0].kind'  "$LEDGER")"
}

: > "$LEDGER"; rm -f "$RETRY_MARKER" "$RETRY_MARKER.2"
printf 'blocked\n' > "$QA_DECL"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: baseline before the retry declares blocked"
out_blocked="$("$SDD" run "$MISSION" 2>&1)"
where_blocked="$(blocked_where)"

: > "$LEDGER"; rm -f "$RETRY_MARKER" "$RETRY_MARKER.2"
cp "$CKPT_BEFORE_WRONG_PHASE" "$MDIR/checkpoint.md"
printf 'done\n' > "$QA_DECL"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: control, the retry reports done"
out_ordinary="$("$SDD" run "$MISSION" 2>&1)"
where_ordinary="$(blocked_where)"

assert_eq "the escalation names the phase whose handoff declared it, never the one that came next" \
  "QA|handoff-blocked · EXEC|no-progress" \
  "$where_blocked · $where_ordinary"

# ...and it names that phase TO THE HUMAN, not only in the ledger. The two are written from the
# same `$phase`, but only the ledger half was measured: an adversarial pass in the REVIEW round of
# 20260826-o-laco-da-qa hardcoded the wrong phase into the `bad`/pipeline.log prose while leaving
# the ledger row correct, and the whole suite stayed green at 585 ok. That is precisely the damage
# the F2 narrative describes — the runner telling a human to go fix `status: blocked` in a
# 20-handoff-exec.md that says `done` — so the half a human actually READS was the unmeasured one.
# A Jidoka exists to be acted on by a person; its terminal output is not decoration.
#
# DIFFERENTIAL on the same pair of runs, and it costs no extra session: one word in the QA handoff
# has to move the name in the human line from QA to EXEC and back. Both halves assert the ABSENCE
# of the other phase's line too — "names QA" alone is satisfied by output that names both.
assert_eq "and it names that phase to the HUMAN too, not only in the ledger row" \
  "QA=1 EXEC=0 · QA=0 EXEC=1" \
  "QA=$(grep -c 'BLOCKED in QA' <<< "$out_blocked") EXEC=$(grep -c 'BLOCKED in EXEC' <<< "$out_blocked") · QA=$(grep -c 'BLOCKED in QA' <<< "$out_ordinary") EXEC=$(grep -c 'BLOCKED in EXEC' <<< "$out_ordinary")"

cp "$CKPT_BEFORE_WRONG_PHASE" "$MDIR/checkpoint.md"
rm -f "$QA_DECL"
# The fixture is left as the blocks below expect to find it: the dead stub, and a committed handoff
# that is not `blocked`. A `blocked` handoff left behind would escalate every later `sdd run` here
# on the FIRST session and quietly rewrite what those blocks measure.
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
chmod +x "$OUTSIDE/stub/claude"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: restore the handoff the retry regime replaced"

# --- the app is down: the runner asks, and stops ---------------------------
echo "== a dead app escalates on the first session, where a red e2e alone still spends two =="
# A red e2e says nothing about WHOSE fault it is: a dead app, a stopped database, a missing
# browser binary and a genuinely broken assertion all leave the same non-zero rc, and the runner
# read every one of them as "QA still has work to do" — one gate failure, one more opus session,
# for ever. Measured on the SQ-111 mission of 2026-08-27: US$ 14,16 for a QA reproved by the
# environment, plus US$ 7,61 for the lap that reopened a mission whose PR was already open.
#
# FLOOR FIRST, and deliberately NOT written with the runner's own app_probe: a floor that reuses
# the function under test measures the runner with the runner. This is a raw connect, and when it
# cannot find a refused port it dies BY NAME rather than certifying a pair that proved nothing.
port_is_free() {  # rc 0 = nothing is listening on 127.0.0.1:$1
  local rc=0
  LC_ALL=C timeout 3 bash -c 'exec 3<>"/dev/tcp/127.0.0.1/$0"' "$1" 2>/dev/null || rc=$?
  [ "$rc" -ne 0 ]
}
# BELOW the ephemeral range, and that is what makes the floor hold for the whole block. The floor
# proves the port refuses ONCE; the assertions under it then run several `sdd` invocations over
# minutes against that one measurement. Drawn from 49152-59171 the port sat INSIDE the kernel's
# `ip_local_port_range` (32768-60999 by default), so it could be handed out mid-block and the
# assertions would flip for a reason that has nothing to do with the runner. 20000-29999, plus the
# 19 steps the search below may take past it, is under that floor. DECLARED LIMIT: a machine that
# lowered `ip_local_port_range` past 20000, or that starts a real listener there mid-block, is back
# in the old window — the search loop below only re-measures at the start, and re-measuring per
# assertion would buy a smaller window at the price of a floor nobody can read.
dead_port=$(( 20000 + $$ % 10000 ))
app_floor_ok=1
if ! command -v timeout >/dev/null 2>&1; then
  fail "dead-app floor" "timeout(1) on PATH" "timeout is missing — the app-down pair was NOT measured"
  app_floor_ok=0
else
  tries=0
  while ! port_is_free "$dead_port"; do
    dead_port=$(( dead_port + 1 )); tries=$(( tries + 1 ))
    if [ "$tries" -ge 20 ]; then
      fail "dead-app floor" "a refused port on 127.0.0.1" \
           "20 consecutive ports were all listening — the pair would certify nothing"
      app_floor_ok=0; break
    fi
  done
fi

if [ "$app_floor_ok" = "1" ]; then
  pass "dead-app floor: 127.0.0.1:$dead_port refuses connections"

  # With E2E_CMD set, gate_QA takes the interface branch, so the dated report has to be there and
  # closed — otherwise the gate refuses ABOVE the e2e and the probe is never reached, which is a
  # pair that measures the report anchor while claiming to measure the probe.
  # PROVENANCE: ~/.claude/skills/qa-execution/assets/report-template.md:6, same capture the
  # equivalent fixture in tests/check-gates.sh carries — the `**Status:**` does not open the line
  # and the enum legend rides in the comment.
  mkdir -p "$FIX/docs/qa/reports"
  cat > "$FIX/docs/qa/reports/2026-01-01-fixture.md" <<'RPT'
# QA Run Report — 2026-01-01 — fixture
- **Started:** 2026-01-01T10:00:00Z · **Status:** closed <!-- in-progress | closed -->
| # | Charter | Status |
|---|---|---|
| 1 | CH-one | Pass |
RPT
  printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"

  # ⭐ THE PAIR, and its control is the SAME fixture with APP_URL emptied — one line of config is
  # the only difference between the two runs. That is what makes it isolate the PROBE and not the
  # redness: E2E_CMD is `false` on both sides, so both gates refuse for a red e2e, and a runner
  # that escalated on a red e2e alone would take the control half red. The dead stub moves
  # nothing, so the control reaches `no-progress` — the two-session loop of today, which is
  # exactly what this pair exists to delete.
  sed -i 's|^E2E_CMD=.*|E2E_CMD="false"|' .sdd/config.sh
  if grep -q '^APP_URL=' .sdd/config.sh; then
    sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port/\"|" .sdd/config.sh
  else
    printf 'APP_URL="http://127.0.0.1:%s/"\n' "$dead_port" >> .sdd/config.sh
  fi
  git add -A && git commit -qm "chore: a red e2e over an app nobody is serving"
  : > "$LEDGER"
  "$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
  app_down="$(blocked_shape "$rc")"
  # `kind == "app-down"` and NOT merely `event == "blocked"`: with the second spelling this line
  # reads the `no-progress` row of today, whose gate_why already carries the address (the probe
  # writes GATE_WHY one increment earlier than the escalation reads it) — so it would pass before
  # the escalation existed AND after, which is an assertion that measures nothing.
  why_down="$(jq -r -s '[.[] | select(.kind == "app-down")][0].gate_why' "$LEDGER")"

  sed -i 's|^APP_URL=.*|APP_URL=""|' .sdd/config.sh
  git add -A && git commit -qm "chore: control — the same red e2e, with no address to ask about"
  : > "$LEDGER"
  "$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
  app_control="$(blocked_shape "$rc")"

  assert_eq "a dead app escalates on the first session, where the same red e2e with no APP_URL still spends two" \
    "3|1|blocked|app-down · 3|2|blocked|no-progress" \
    "$app_down · $app_control"

  # The row an operator acts on has to say WHERE nothing is listening. `app-down` in the `kind`
  # field names the class; the address is what turns the escalation into an instruction, and it is
  # the half a `kind` set by hand would leave empty. Read off the SAME run — no extra session.
  assert_eq "and the escalation row names the address nothing is listening on" \
    "names-it" \
    "$(grep -qE "nothing is listening at 127\.0\.0\.1:$dead_port" <<< "$why_down" && echo names-it || echo "$why_down")"

  # --- ...and a `--max-phases` ceiling does not turn that into rc 0 ----------
  # The sibling of the ceiling assertion in the handoff-blocked family above, and it is owed by
  # the same argument: door 1 sits ABOVE the ceiling check, so an operator or a CI wrapper pacing
  # the pipeline one phase at a time must not get a SUCCESS exit code for a phase no session can
  # satisfy. DIFFERENTIAL against the control, which under the same flag must still end 0 with no
  # escalation row at all — a runner that escalated whenever --max-phases is set takes it red.
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port/\"|" .sdd/config.sh
  git add -A && git commit -qm "chore: the dead app, under a ceiling"
  : > "$LEDGER"
  "$SDD" run "$MISSION" --max-phases 1 >/dev/null 2>&1; rc=$?
  app_ceiling_down="$(blocked_shape "$rc")"

  sed -i 's|^APP_URL=.*|APP_URL=""|' .sdd/config.sh
  git add -A && git commit -qm "chore: control, under the same ceiling"
  : > "$LEDGER"
  "$SDD" run "$MISSION" --max-phases 1 >/dev/null 2>&1; rc=$?
  app_ceiling_control="$(blocked_shape "$rc")"

  assert_eq "a --max-phases ceiling does not turn a dead app into rc 0, where the same red e2e still ends 0" \
    "3|1|blocked|app-down · 0|1|null|null" \
    "$app_ceiling_down · $app_ceiling_control"

  # NOT asserted here: "a projection over a dead app writes no ledger row". It was written, and
  # then removed because no single sabotage could make it red — the house rule for a rule the
  # sabotage cannot break, and the probes came BEFORE the removal rather than instead of it.
  # Three worlds were built and measured:
  #   · the escalation hoisted ABOVE cmd_run's projection early-exit  -> still green, because
  #   · autonomy_append carries its own DRY_RUN guard, and removing THAT is already owned by
  #     "the projection writes no ledger at all" at the top of this file (12 assertions go red);
  #   · pipeline_log_line's guard is owned by tests/check-dry-run.sh (3 assertions go red).
  # The escalation reaches the ledger only through autonomy_append, so a second assertion here
  # would have measured that function's guard for the third time and this path not at all.
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port/\"|" .sdd/config.sh
  git add -A && git commit -qm "chore: the dead app stays put for the retry regime"

  # --- ...and the INLINE RETRY escalates on the same terms ------------------
  # Everything above sits on the FIRST pass. The retry door is reached whenever the gate's FIRST
  # evaluation refuses ABOVE the e2e — the probe is never run, so the marker is not armed — and
  # the retry session then does the honest work that lets the gate get as far as the e2e and find
  # the app dead. Reachable without contrivance: session 1 dying or writing nothing is what
  # SUMMONS the retry, and the retry is the session that writes the report the gate was missing.
  #
  # Without door 2 the marker survives the LAP rather than the gate: the run carries on (the retry
  # DID move the disk), the next lap derives EXEC from the `F<n> pending` row the retry opened,
  # gate_EXEC never touches the marker, and door 1 fires for EXEC — an APP_URL diagnosis printed
  # over a phase that never ran an e2e, and {phase: EXEC, kind: app-down} written into the ledger
  # the kaizen judge reads. That is the F2 failure measured on the handoff-blocked sibling.
  #
  # DIFFERENTIAL, and the control is what stops it passing vacuously: BOTH regimes append the same
  # `F<n> pending` row, so both genuinely offer EXEC as the next phase — "it escalates QA" alone
  # would also pass on a fixture that never left QA. Only the APP_URL line of the config differs.
  APP_CKPT_BEFORE_RETRY="$OUTSIDE/checkpoint-before-app-retry.md"
  cp "$MDIR/checkpoint.md" "$APP_CKPT_BEFORE_RETRY"
  APP_RETRY_MARKER="$OUTSIDE/.app-down-retry"
  # ONE stub for both regimes: two hand-written stubs would be two places for the regimes to drift
  # apart, and what the pair measures is that only the config line differs.
  cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
if [ ! -e "$APP_RETRY_MARKER" ]; then : > "$APP_RETRY_MARKER"; exit 1; fi
if [ ! -e "$APP_RETRY_MARKER.2" ]; then
  : > "$APP_RETRY_MARKER.2"
  mkdir -p "$FIX/docs/qa/reports"
  cat > "$FIX/docs/qa/reports/2026-01-01-fixture.md" <<'RPT'
# QA Run Report — 2026-01-01 — fixture
- **Started:** 2026-01-01T10:00:00Z · **Status:** closed <!-- in-progress | closed -->
| # | Charter | Status |
|---|---|---|
| 1 | CH-one | Pass |
RPT
  printf -- '| F1 | the fix QA asked for | \`true\` → 0 | pending | — |\n' >> "$MDIR/checkpoint.md"
  git -C "$FIX" add -A
  git -C "$FIX" commit -qm "chore: the retry session files its report, and opens a fix increment"
  exit 0
fi
exit 1
STUB
  chmod +x "$OUTSIDE/stub/claude"

  # The report is REMOVED so the first evaluation refuses above the e2e: that is what leaves the
  # marker unarmed on the first pass and sends the run to the retry door at all.
  : > "$LEDGER"; rm -f "$APP_RETRY_MARKER" "$APP_RETRY_MARKER.2"; rm -rf "$FIX/docs/qa"
  sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$dead_port/\"|" .sdd/config.sh
  git add -A && git commit -qm "chore: the report the retry session will file"
  "$SDD" run "$MISSION" >/dev/null 2>&1
  app_retry_where="$(blocked_where)"

  : > "$LEDGER"; rm -f "$APP_RETRY_MARKER" "$APP_RETRY_MARKER.2"; rm -rf "$FIX/docs/qa"
  cp "$APP_CKPT_BEFORE_RETRY" "$MDIR/checkpoint.md"
  sed -i 's|^APP_URL=.*|APP_URL=""|' .sdd/config.sh
  git add -A && git commit -qm "chore: control — the same retry, with no address to ask about"
  "$SDD" run "$MISSION" >/dev/null 2>&1
  app_retry_control="$(blocked_where)"

  assert_eq "a retry that reaches a dead app escalates QA, never the phase the next lap would derive" \
    "QA|app-down · EXEC|no-progress" \
    "$app_retry_where · $app_retry_control"

  cp "$APP_CKPT_BEFORE_RETRY" "$MDIR/checkpoint.md"
  # Back to the dead stub the blocks below expect.
  cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
exit 1
STUB
  chmod +x "$OUTSIDE/stub/claude"
fi

# The fixture goes back to what the blocks below expect: no interface, and a QA handoff that is
# `done` without the `gate:` evidence — the ordinary refusal the reader blocks are built on. An
# E2E_CMD or an APP_URL left behind here would send every later gate_QA down the interface branch.
sed -i 's|^E2E_CMD=.*|E2E_CMD=""|; s|^APP_URL=.*||' .sdd/config.sh
rm -rf "$FIX/docs/qa"
printf -- '---\nfase: QA\nstatus: done\n---\n' > "$MDIR/30-handoff-qa.md"
git add -A && git commit -qm "chore: restore the fixture the app-down pair borrowed"

# --- the reader ------------------------------------------------------------
# Fixture ledger written by hand: this is OUR format, so there is no third-party source to copy
# from (the provenance rule covers skill output). Every row here exists to prove one refusal.
echo "== reader =="
mkdir -p "$OUTSIDE/read"
localize > "$OUTSIDE/read/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":3,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":4,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"gate":"fail","gate_why":"old schema, no moved"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/read" "$SDD" autonomy 2>&1 )"; rc=$?

assert_eq "the reader exits 0 with data" "0" "$rc"
# 2 comparable sessions (rows 1 and 2): row 1 wrote and failed its gate (churned), row 2 wrote
# nothing (idle) — neither made the phase advance, so waste is 100%. This read 50% while waste was
# the approximation `moved == false`; the yardstick moved on 2026-08-28 (KAIZEN_LOG.md).
assert_eq "waste is computed over comparable sessions only" "1" \
  "$(grep -c '100% waste' <<< "$out")"
assert_eq "it says how many rows it excluded, and why" "1" \
  "$(grep -c '2 non-comparable' <<< "$out")"
assert_eq "escalations are counted apart from sessions" "1" \
  "$(grep -c 'no-progress: 1' <<< "$out")"
# Anti-vacuity floor, same family as the surface floor in check-lang: a broken jq filter would
# report "0 sessions, all good" forever.
assert_eq "the header states how many rows it read" "1" "$(grep -c '5 row(s)' <<< "$out")"
# The four buckets (2 comparable, 2 non-comparable, 1 escalation, 0 unrecognized) must sum to the
# 5 rows the header says it read.
assert_bucket_sum "the four buckets sum to the header total (mixed ledger)" "$out"

# --- what the session DID, not only whether it wrote ------------------------------------------
# `stalled` was `moved == false`: "the session wrote nothing", which is not "the phase did not
# advance". On the real ledger 68 of 145 sessions wrote something, failed their gate and bought the
# runner another session, and the window said `0 stalled` about all of them. Three outcomes now,
# ONE definition (`ledger_outcome_defs` in bin/sdd) spliced into BOTH readers. The counts below are
# all different on purpose, so two swapped fields cannot pass by coincidence.
echo "== reader: advanced · churned · idle =="
mkdir -p "$OUTSIDE/tristate"
localize > "$OUTSIDE/tristate/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":2,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":3,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:05:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s6","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:06:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"ddddddd","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m2","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s7","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:07:00-03:00","event":"blocked","kind":"no-progress","run_id":"r3","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"QA","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:08:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":2,"auto_retry":false,"session":"s8","rc":0,"dur_s":10,"cost_usd":1.0,"gate":"fail","gate_why":"old schema, no moved"}
EOF
out_tri="$( SDD_STATE_DIR="$OUTSIDE/tristate" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a ledger of three outcomes is data (rc 0)" "0" "$rc"
# 6 comparable sessions: the gate passed on 3 (advanced), 2 wrote and still failed (churned), 1
# wrote nothing and failed (idle). The dirty row (s7), the escalation, and the old-schema session
# with no `moved` field (s8) are the other three rows — 9 total, 6 + 2 non-comparable + 1
# escalation + 0 unrecognized. s8 is the row review found: an on-axis SESSION missing `moved` used
# to be admitted by kaizen_series (on_axis alone) while cmd_autonomy already refused it
# (`comparable` demands has("moved")) — 2 non-comparable here proves both readers refuse it now.
assert_eq "the version line says what the sessions did, in the order advanced · churned · idle" "1" \
  "$(grep -cE '^  ddddddd  6 session\(s\) · 3 advanced · 2 churned · 1 idle · ' <<< "$out_tri")"
assert_eq "and the word stalled is gone — idle is the same number under the name that says what it is" "0" \
  "$(grep -c 'stalled' <<< "$out_tri")"
assert_bucket_sum "the four buckets still sum to the header total (three outcomes)" "$out_tri"

# waste changed yardstick on 2026-08-28: churned + idle over the comparable sessions, floored. The
# old yardstick (idle alone, then called stalled) is 1/6 = 16% on this fixture; the new one is
# 3/6 = 50%. The line has to carry the second AND NOT the first — a differential on one fixture,
# so no regime satisfies it by accident. The two sides of the change are in KAIZEN_LOG.md.
assert_eq "waste counts churned and idle, not idle alone" "1 0" \
  "$(grep -c ' 50% waste ' <<< "$out_tri") $(grep -c ' 16% waste ' <<< "$out_tri")"

# PARITY, measured and never asserted in prose. The judge series reads the SAME file through its
# own jq program, and both programs splice ONE printed definition. A program that stopped splicing
# it and grew a local copy on the old yardstick (mut_KAIZEN_outcome_inlined_old) stays internally
# consistent — only the comparison between the two catches it, which is why this is not a
# constant on the right-hand side.
series_tri="$( SDD_STATE_DIR="$OUTSIDE/tristate" "$SDD" kaizen --series 2>/dev/null )"
table_tri="$(sed -nE 's/^  ddddddd  [0-9]+ session\(s\) · ([0-9]+) advanced · ([0-9]+) churned · ([0-9]+) idle · .*/\1 \2 \3/p' <<< "$out_tri")"
assert_eq "the human window and the judge count the outcomes of the latest version alike" \
  "$(jq -r '.latest.outcomes | "\(.advanced) \(.churned) \(.idle)"' <<< "$series_tri")" "$table_tri"
# ...and not by both being empty: the floor is the known histogram of this fixture. This fixture
# now carries the row shape (an on-axis session with no `moved` field) that made the two readers
# disagree before this fix — s8 above — and the parity assertion above only holds because both
# readers now refuse it the same way.
assert_eq "the parity is not vacuous — the table printed the three counts" "3 2 1" "$table_tri"
# The divergence review measured directly: the human count of excluded non-comparable rows and the
# series' own excluded.non_comparable field, over the SAME fixture that carries the row shape that
# used to split them (s7, dirty kit; s8, session with no moved). Both must read 2.
human_noncomp_tri="$(num_before "$out_tri" 'non-comparable')"; human_noncomp_tri="${human_noncomp_tri:-0}"
assert_eq "the judge excludes exactly the rows the human's reader excludes (session with no moved included)" \
  "2 2" "$human_noncomp_tri $(jq -r '.excluded.non_comparable' <<< "$series_tri")"

# --- the increment that advanced is not churn ----------------------------------------------------
# The gate is the artifact of the PHASE, and a phase of four increments only passes it on the last
# session — so `gate == pass` alone read the pipeline's DESIGNED loop as waste. Measured on the real
# ledger on 2026-08-29: 46 of the 72 EXEC rows read `churned` where the churn is about 5, and 49 of
# the 107 kit versions printed `100% waste` — every one of them a version whose only session was a
# middle increment of some mission. The row now carries the count gate_EXEC already had
# (pending_before/pending_after/increments_total, written by I1), and `outcome` reads it.
#
# The fixture is one coherent EXEC history of four increments, and its six rows exist to make the
# three regimes of this definition come out at three DIFFERENT histograms, so none is reachable by
# accident:
#   s1  4→3  moved, gate fail   the increment advanced; the phase did not          advanced
#   s2  3→3  moved, gate fail   wrote, closed nothing — the churn that is real     churned
#   s3  3→3  no move, fail      wrote nothing at all                               idle
#   s4  3→2  moved, gate fail   advanced again                                     advanced
#   s5  2→?  moved, gate fail   the gate REFUSED the checkpoint, so it published   churned
#                               no pending_after: `null`, not "it went to zero"
#   s6  2→0  moved, gate pass   the last increment closes the phase                advanced
# new rule      3 advanced · 2 churned · 1 idle · 50% waste
# gate-only     1 advanced · 4 churned · 1 idle · 83% waste   (mut_AUTONOMY_progress_ignored)
# no null guard 4 advanced · 1 churned · 1 idle · 33% waste   (mut_AUTONOMY_progress_null_blind)
#
# s5 is not decoration: jq orders `null` BELOW every number, so `.pending_after < .pending_before`
# with a null left-hand side is TRUE — a gate that refused the checkpoint would read as the loudest
# possible progress. The guard against that is code, and this is the row that measures it.
echo "== reader: the increment that advanced is not churn =="
mkdir -p "$OUTSIDE/progress"
localize > "$OUTSIDE/progress/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-29T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":4,"pending_after":3,"increments_total":4,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":3,"pending_after":3,"increments_total":4,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:02:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"pending_before":3,"pending_after":3,"increments_total":4,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:03:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":3,"pending_after":2,"increments_total":4,"gate":"fail","gate_why":"2 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:04:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":2,"pending_after":null,"increments_total":null,"gate":"fail","gate_why":"increment I3 is done with no commit"}
{"v":1,"ts":"2026-08-29T10:05:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s6","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":2,"pending_after":0,"increments_total":4,"gate":"pass","gate_why":""}
EOF
out_prog="$( SDD_STATE_DIR="$OUTSIDE/progress" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a ledger of increment counts is data (rc 0)" "0" "$rc"

assert_eq "a session that advanced its increment reads advanced, not churned" "1" \
  "$(grep -cE '^  eeeeeee  6 session\(s\) · 3 advanced · 2 churned · 1 idle · ' <<< "$out_prog")"

# Differential on ONE fixture: the new number has to be there AND the gate-only number has to be
# gone. A count asserted alone is satisfied by any regime that happens to land on it.
assert_eq "waste counts only the increment that did not move" "1 0" \
  "$(grep -c ' 50% waste ' <<< "$out_prog") $(grep -c ' 83% waste ' <<< "$out_prog")"

# The null guard, measured and not asserted in prose: without it s5 reads `advanced` and the
# histogram goes 4 · 1 · 1 at 33% waste. Both halves, so deleting the row cannot satisfy it.
assert_eq "a gate that published no pending_after is not an increment that advanced" "0 0" \
  "$(grep -c ' 4 advanced · 1 churned ' <<< "$out_prog") $(grep -c ' 33% waste ' <<< "$out_prog")"

# Parity again, on the fixture where the definition CHANGED: the judge splices the same printed
# defs, so a copy that stayed on the gate-only yardstick shows up only in the comparison.
series_prog="$( SDD_STATE_DIR="$OUTSIDE/progress" "$SDD" kaizen --series 2>/dev/null )"
table_prog="$(sed -nE 's/^  eeeeeee  [0-9]+ session\(s\) · ([0-9]+) advanced · ([0-9]+) churned · ([0-9]+) idle · .*/\1 \2 \3/p' <<< "$out_prog")"
assert_eq "the human window and the judge agree on the increment that advanced" \
  "$(jq -r '.latest.outcomes | "\(.advanced) \(.churned) \(.idle)"' <<< "$series_prog")" "$table_prog"
assert_eq "that parity is not vacuous — the table printed the three counts" "3 2 1" "$table_prog"
assert_bucket_sum "the four buckets sum to the header total (increment counts)" "$out_prog"

# --- the historical path: a row older than the fields recovers its count from gate_why -----------
# 49 of the 72 EXEC rows in the real ledger were written before the three pending fields existed,
# and they carry the SAME fact in prose: gate_EXEC has always written `N of M increment(s) still to
# execute` into gate_why. Migrating them is not an option (the ledger is append-only by contract),
# and leaving them on the `moved` arm would have the human window reading `churned` over the whole
# history it exists to explain — for ever, since nothing will ever rewrite those lines.
#
# So the readers recover it, and the assertions below are about the recovery being a reading of ONE
# history rather than a second opinion about it. The fixture is the SAME six-session history the
# block above just measured through the fields, respelled the way the runner wrote it in July:
# no pending_* keys, the count in the prose, and the real gate_EXEC sentences — including the
# passing one, `4 increment(s) done, suite green, handoff written`, which opens with a number and
# must NOT be mistaken for a count (it has no `of`).
echo "== reader: the historical path reads the count from gate_why =="
mkdir -p "$OUTSIDE/historic"
localize > "$OUTSIDE/historic/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-29T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:02:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:03:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"2 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T10:04:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"increment I3 is done with no commit"}
{"v":1,"ts":"2026-08-29T10:05:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s6","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"4 increment(s) done, suite green, handoff written"}
EOF
out_hist="$( SDD_STATE_DIR="$OUTSIDE/historic" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a ledger written before the pending fields is data (rc 0)" "0" "$rc"

# THE differential, and it is the whole increment: two ledgers, one history, two spellings of it.
# The full version line is compared — sessions, the three outcomes, waste, missions and money — so
# a recovery that agreed on the histogram by landing on some other regime still fails. Asserted
# against the line the block above printed from the FIELDS, never against a literal: a literal
# would let both sides drift together, which is the failure this comparison exists to catch.
line_fields="$(grep -E '^  eeeeeee  ' <<< "$out_prog")"
line_prose="$(grep -E '^  eeeeeee  ' <<< "$out_hist")"
assert_eq "the historical path and the fields agree on one history" "$line_fields" "$line_prose"
# Not vacuous: two empty strings are equal. The line has to be the one this fixture is about.
assert_eq "that agreement is not vacuous — both lines carry the three counts" "1 1" \
  "$(grep -c ' 3 advanced · 2 churned · 1 idle · 50% waste ' <<< "$line_fields") $(grep -c ' 3 advanced · 2 churned · 1 idle · 50% waste ' <<< "$line_prose")"

# The path SAYS it ran, and how far it reached. A reader that silently reinterprets half its input
# is the silent instrument this whole command was rewritten to stop being — and the sentence is
# also the deletion signal: the day `sdd autonomy --all-repos` stops printing it, the code below
# it in bin/sdd has no rows left to serve and comes out.
assert_eq "the historical path says how many rows it read from prose" "1" \
  "$(grep -c '(4 EXEC row(s) older than the pending fields read their progress from gate_why)' <<< "$out_hist")"

# Parity again, over the ledger where the count is RECOVERED rather than read: the judge splices
# the same printed defs, so a series that skipped the recovery shows up only here.
series_hist="$( SDD_STATE_DIR="$OUTSIDE/historic" "$SDD" kaizen --series 2>/dev/null )"
table_hist="$(sed -nE 's/^  eeeeeee  [0-9]+ session\(s\) · ([0-9]+) advanced · ([0-9]+) churned · ([0-9]+) idle · .*/\1 \2 \3/p' <<< "$out_hist")"
assert_eq "the human window and the judge agree on the recovered history" \
  "$(jq -r '.latest.outcomes | "\(.advanced) \(.churned) \(.idle)"' <<< "$series_hist")" "$table_hist"
assert_eq "that parity is not vacuous — the recovered table printed the three counts" "3 2 1" "$table_hist"
assert_bucket_sum "the four buckets sum to the header total (historical path)" "$out_hist"

# --- the two memory rules of the historical path -------------------------------------------------
# `pending_before` of an old row is the `pending_after` of the PREVIOUS EXEC row of the same
# mission, and two rules say when that memory does not apply. Each gets a mission of its own, built
# so that dropping the rule flips its outcome — a rule whose removal no fixture notices is a rule
# with no probe.
#
#   m4  the total GREW between two FAILING sessions: the checkpoint went from 4 increments to 6
#       (a fix increment appended to a phase still in flight, or a human amendment) and the next
#       row says `3 of 6` after a memory of 2. Without the rule 3 is not below 2, and the session
#       that did the work reads churn. With it, a changed M is a new denominator: count from M.
#       No passing row anywhere in this mission, DELIBERATELY — the first shape of this fixture put
#       a `pass` before the growth, the reset rule below cleared the memory first, and
#       mut_AUTONOMY_historic_total_change_blind survived a probe that pointed at the right rule
#       for the wrong reason.
#   m5  a PASSING gate clears the memory. The phase closed at `4 increment(s) done`; a later session
#       reopened one and left `3 of 4`. Without the reset the memory still says 3 from before the
#       pass, M is unchanged so the M rule does not fire, and 3 → 3 reads churned.
echo "== reader: the memory rules of the historical path =="
mkdir -p "$OUTSIDE/histfix"
localize > "$OUTSIDE/histfix/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-29T11:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m4","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T11:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m4","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"g2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"2 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T11:02:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m4","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"g3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 6 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T11:10:00-03:00","event":"session","run_id":"r4","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m5","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"h1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T11:11:00-03:00","event":"session","run_id":"r4","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m5","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"h2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"4 increment(s) done, suite green, handoff written"}
{"v":1,"ts":"2026-08-29T11:12:00-03:00","event":"session","run_id":"r5","invocation":"run","kit_sha":"ddddddd","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m5","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"h3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
EOF
out_histfix="$( SDD_STATE_DIR="$OUTSIDE/histfix" "$SDD" autonomy --by-mission 2>&1 )"

assert_eq "a growing total is a fix increment, not churn" "1" \
  "$(grep -c '^  m4  3 session(s) · 3 advanced · 0 churned · 0 idle · ' <<< "$out_histfix")"
assert_eq "a passing gate clears the count the next session is measured against" "1" \
  "$(grep -c '^  m5  3 session(s) · 3 advanced · 0 churned · 0 idle · ' <<< "$out_histfix")"

# --- an inference never credits a session that provably wrote nothing -----------------------------
# The historical path RECOVERS `pending_before` from prose; it does not measure it. Where the memory
# is empty it recovers M, the largest value the field can take, so the `advanced` arm is satisfied by
# any prose that is not `M of M` — and the memory is empty on the first row of a mission (where M is
# right), but ALSO on the row after a passing gate, where it is not. A phase that closed at
# `4 increment(s) done` and then reopened an increment reads `1 of 5`, is handed a `pending_before`
# of 5, and reads `advanced` — over a session that never touched the disk. `0% waste` on a session
# that did nothing is the flattering direction, the same family as the null guard and the Jidoka
# block, and it is the one place an INFERENCE outranks a MEASUREMENT.
#
# The guard is `.moved != false`, and it is a tautology rather than a policy: `state_fingerprint`
# hashes the checkpoint, and closing an increment means editing the checkpoint, so a session whose
# fingerprint did not move CANNOT have lowered the count. It therefore costs the field path nothing
# (a measured pair with `moved: false` is unreachable) and it does not touch which rows the path
# annotates — the disclosure count and the two memory rules above are deliberately left alone, so
# this assertion cannot be satisfied by the path simply failing to reach the row. Measured over the
# real ledger on 2026-08-30: 53 recovered rows, 48 `advanced`, and the guard moves NONE of them.
# `!= false` and not `== true`: an escalation row carries no `moved` at all, and `null != false`
# leaves it exactly where the two readers already file it.
echo "== reader: a recovered count never credits a session that wrote nothing =="
mkdir -p "$OUTSIDE/histmoved"
localize > "$OUTSIDE/histmoved/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-29T13:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"j1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"4 increment(s) done, suite green, handoff written"}
{"v":1,"ts":"2026-08-29T13:01:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"j2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"1 of 5 increment(s) still to execute"}
EOF
out_histmoved="$( SDD_STATE_DIR="$OUTSIDE/histmoved" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "a recovered count never credits a session that wrote nothing" "1" \
  "$(grep -c '^  m11  2 session(s) · 1 advanced · 0 churned · 1 idle · ' <<< "$out_histmoved")"
# The witness, and without it the assertion above is satisfied by a path that never reached the row
# at all — which is the cheapest way to make it green for the wrong reason.
assert_eq "and the row it declined to credit is one the path did read" "1" \
  "$(grep -c '1 EXEC row(s) older than the pending fields read their progress from gate_why' <<< "$out_histmoved")"

# --- the historical path never touches a row that carries the fields -----------------------------
# The guard is `.pending_before == null` and NOT `has("pending_before")`: autonomy_session_row
# builds the object with `($pbefore | tonumber? // null)`, so the KEY is on every row the runner has
# written since I1 — `has` answers true for all 49 historical rows and the path would annotate none
# of them. Measured on this mission's own first ledger row.
#
# The mirror image is this fixture: the same six-session history with s1 and s2 respelled in the new
# schema, their prose left in place. A path that ignored the guard would annotate 4 rows instead of
# 2 — and would ALSO have to be fed by those two rows to keep the histogram, which is the second
# thing measured here: s3 reads its `pending_before` off s2, a row the path never annotated.
echo "== reader: the historical path leaves a row with fields alone =="
mkdir -p "$OUTSIDE/histmixed"
localize > "$OUTSIDE/histmixed/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-29T12:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":4,"pending_after":3,"increments_total":4,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T12:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"pending_before":3,"pending_after":3,"increments_total":4,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T12:02:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":false,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T12:03:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"2 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-29T12:04:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"increment I3 is done with no commit"}
{"v":1,"ts":"2026-08-29T12:05:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s6","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"4 increment(s) done, suite green, handoff written"}
EOF
out_mixed="$( SDD_STATE_DIR="$OUTSIDE/histmixed" "$SDD" autonomy 2>&1 )"
assert_eq "the historical path never touches a row that carries the fields" "1 1" \
  "$(grep -c '(2 EXEC row(s) older than the pending fields read their progress from gate_why)' <<< "$out_mixed") $(grep -c ' 3 advanced · 2 churned · 1 idle · 50% waste ' <<< "$out_mixed")"
# The other half of that guard: over a ledger where EVERY row carries the fields, the path reaches
# nothing and the sentence does not print at all.
assert_eq "a ledger written entirely in the new schema prints no historical sentence" "0" \
  "$(grep -c 'read their progress from gate_why' <<< "$out_prog")"

# --- the dated path for REVIEW: a row older than the round fields recovers it from gate_why -------
# The same change, one phase on, and the same reason: on 2026-08-31 the real ledger held 25 REVIEW
# rows and ZERO of them carried `rounds_before` — every one predates the fields. Migrating them is
# not an option (the ledger is append-only by contract) and leaving them on the `moved` arm keeps
# the human window and the judge reading `churned` over the whole REVIEW history they exist to
# explain. gate_REVIEW has always written the round file's own name into GATE_WHY, so the row
# carries `40-review-r<N>.md` verbatim and the count is recoverable from it: measured over that
# ledger, 24 of the 25 rows are reachable, the one that is not being a `TEST_CMD failed` refusal
# that names no file. Which is why the third assertion of this block is about that row STAYING out.
#
# `rounds_before` is the recovered `rounds_after` of the previous REVIEW row of the same
# (repo, mission) in FILE order, seeded at 0 — and 0 is a MEASUREMENT and not a default: a fresh
# mission dir holds no `40-review-r*.md`, so the first REVIEW session of a mission genuinely starts
# at zero rounds. The repo filter runs before this path and a mission belongs to one repo, so the
# filter cannot truncate a mission's history and leave the seed reading a middle row as a first one.
# DECLARED LIMIT: a ledger file truncated by hand mid-mission can, and the row after the cut then
# reads its round against 0. Same shape as the EXEC sibling's empty-memory case, same guard
# (`.moved != false`, in `outcome`), and the same remedy — do not truncate the ledger.
echo "== reader: the dated path reads the REVIEW round from gate_why =="
mkdir -p "$OUTSIDE/histrounds"
localize > "$OUTSIDE/histrounds/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T09:00:00-03:00","event":"session","run_id":"q1","invocation":"run","kit_sha":"fff0000","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"q1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"40-review-r1.md: Code Quality (Zen) = B — the gate requires Grade A on every criterion"}
{"v":1,"ts":"2026-08-31T09:01:00-03:00","event":"session","run_id":"q1","invocation":"run","kit_sha":"fff0000","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"q2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"40-review-r1.md: Test Coverage = B — the gate requires Grade A on every criterion"}
{"v":1,"ts":"2026-08-31T09:02:00-03:00","event":"session","run_id":"q2","invocation":"run","kit_sha":"fff0000","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m7","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"q3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"40-review-r2.md all Grade A, suite green, tree clean"}
{"v":1,"ts":"2026-08-31T09:03:00-03:00","event":"session","run_id":"q3","invocation":"run","kit_sha":"fff0000","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m8","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"q4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"no 40-review-r<N>.md"}
{"v":1,"ts":"2026-08-31T09:04:00-03:00","event":"session","run_id":"q4","invocation":"run","kit_sha":"fff0000","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m9","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"q5s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"TEST_CMD failed (tests/run-all.sh) — see /tmp/gate-review-test.log"}
EOF
out_rounds="$( SDD_STATE_DIR="$OUTSIDE/histrounds" "$SDD" autonomy 2>&1 )"; rc=$?
out_rounds_bym="$( SDD_STATE_DIR="$OUTSIDE/histrounds" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "a REVIEW ledger written before the round fields is data (rc 0)" "0" "$rc"

# THE assertion of this increment. The r1 that landed with real findings and did not reach Grade A
# advanced a round; the second session on the SAME r1 did not. One fixture, both readings, so a
# path that simply annotated everything cannot satisfy it: 2 advanced (q1s off the recovered round,
# q3s off its passing gate) · 3 churned (q2s, q4s, q5s) · 0 idle.
assert_eq "a pre-schema REVIEW row recovers its round from gate_why" "1" \
  "$(grep -c ' 5 session(s) · 2 advanced · 3 churned · 0 idle · 60% waste ' <<< "$out_rounds")"

# The row the real ledger's most expensive cell is actually made of, and it must NOT move. `no
# 40-review-r<N>.md` means the session landed no round file at all, so it recovers ZERO rounds and
# 0 > 0 is false. A recovery that read the sentence as "a round" would turn the one shape that
# genuinely spun into the loudest progress in the ledger — the flattering direction this whole
# family of guards exists to refuse.
assert_eq "a REVIEW session that landed no round file did not advance a round" "1" \
  "$(grep -c '^  m8  1 session(s) · 0 advanced · 1 churned · 0 idle · ' <<< "$out_rounds_bym")"
# The DECLARED limit, asserted rather than promised: two of gate_REVIEW's eight refusals name no
# file (`TEST_CMD failed`, `working tree dirty after the review`), and those rows stay where they
# were instead of being guessed at. Measured over the real ledger: 1 row of 25.
assert_eq "a REVIEW refusal that names no round file is not annotated" "1" \
  "$(grep -c '^  m9  1 session(s) · 0 advanced · 1 churned · 0 idle · ' <<< "$out_rounds_bym")"

# The path SAYS it ran, and how far it reached — the same deletion signal the EXEC sibling carries:
# the day this sentence stops printing, the def below it in bin/sdd has no rows left to serve.
# FOUR and not five: q3s (the passing gate) is annotated too, and q5s is the `TEST_CMD failed` row
# that is not.
assert_eq "the dated REVIEW path says how many rows it read from prose" "1" \
  "$(grep -c '(4 REVIEW row(s) older than the round fields read their round from gate_why)' <<< "$out_rounds")"

# Parity, over a ledger where the round is RECOVERED and not read: the judge splices the same
# printed defs, so a series that skipped the recovery shows up only here. Asserted against the
# window's own line, never against a literal — a literal lets both sides drift together.
series_rounds="$( SDD_STATE_DIR="$OUTSIDE/histrounds" "$SDD" kaizen --series 2>/dev/null )"
table_rounds="$(sed -nE 's/^  fff0000  [0-9]+ session\(s\) · ([0-9]+) advanced · ([0-9]+) churned · ([0-9]+) idle · .*/\1 \2 \3/p' <<< "$out_rounds")"
assert_eq "the human window and the judge agree on the recovered REVIEW history" \
  "$(jq -r '.latest.outcomes | "\(.advanced) \(.churned) \(.idle)"' <<< "$series_rounds")" "$table_rounds"
assert_eq "that parity is not vacuous — the recovered REVIEW table printed the three counts" "2 3 0" "$table_rounds"
assert_bucket_sum "the four buckets sum to the header total (dated REVIEW path)" "$out_rounds"

# --- the two memory rules the REVIEW path does NOT inherit ----------------------------------------
# The EXEC sibling clears its memory on a PASSING gate, because `pending` resets to M when a closed
# phase is reopened. REVIEW rounds do the opposite: `review_rounds_on_disk` counts FILES, the files
# are never deleted, and `sdd run` deliberately does not reset the ceiling against them
# (bin/sdd, the round-ceiling block of cmd_run). So the count carries ACROSS a passing gate, and
# copying the reset over would be a fail-open in the flattering direction — this fixture is the
# world that proves it, and it is here so that the next reader who notices the asymmetry and
# "restores" it gets a red suite instead of a plausible commit.
#
#   m10  r1 lands and the gate PASSES; the phase is reopened and a session spins on the same r1.
#        Memory carried: 1 → 1 is not progress, `churned`. Memory reset: 1 > 0 reads `advanced`
#        over a session that landed nothing.
#   m11  the memory is fed by rows that carry the FIELDS too, which is load-bearing on a mixed
#        ledger: the new-schema row publishes rounds_after 1, and the pre-schema row after it must
#        be measured against that 1 and not against an empty seed of 0.
echo "== reader: the memory rules of the dated REVIEW path =="
mkdir -p "$OUTSIDE/histroundfix"
localize > "$OUTSIDE/histroundfix/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T09:10:00-03:00","event":"session","run_id":"w1","invocation":"run","kit_sha":"fff1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"w1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"40-review-r1.md all Grade A, suite green, tree clean"}
{"v":1,"ts":"2026-08-31T09:11:00-03:00","event":"session","run_id":"w2","invocation":"run","kit_sha":"fff1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m10","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"w2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B — the gate requires Grade A on every criterion"}
{"v":1,"ts":"2026-08-31T09:12:00-03:00","event":"session","run_id":"w3","invocation":"run","kit_sha":"fff1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"w3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"rounds_before":0,"rounds_after":1,"rounds_max":3,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B — the gate requires Grade A on every criterion"}
{"v":1,"ts":"2026-08-31T09:13:00-03:00","event":"session","run_id":"w3","invocation":"run","kit_sha":"fff1111","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m11","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"w4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"40-review-r1.md: Test Coverage = B — the gate requires Grade A on every criterion"}
EOF
out_roundfix="$( SDD_STATE_DIR="$OUTSIDE/histroundfix" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "a passing REVIEW gate does NOT clear the round the next session is measured against" "1" \
  "$(grep -c '^  m10  2 session(s) · 1 advanced · 1 churned · 0 idle · ' <<< "$out_roundfix")"
assert_eq "the round memory is fed by the rows that carry the fields too" "1" \
  "$(grep -c '^  m11  2 session(s) · 1 advanced · 1 churned · 0 idle · ' <<< "$out_roundfix")"
# The witness: both assertions above are satisfiable by a path that never reached those rows at
# all, which is the cheapest way to be green for the wrong reason. THREE rows recovered of the four
# — w1s and w2s of m10, w4s of m11 — and w3s left alone because it was born with the fields.
assert_eq "and the rows they judge are rows the dated path did read" "1" \
  "$(grep -c '3 REVIEW row(s) older than the round fields read their round from gate_why' <<< "$out_roundfix")"

# --- the dated REVIEW path never touches a row born with the fields ------------------------------
# The guard is `.rounds_before == null AND .rounds_after == null`, and the second half is the one
# with a measurement behind it. A row carrying `rounds_after` with a null `rounds_before` is not a
# pre-schema row — it is a row this runner wrote whose PHOTOGRAPH went missing, which is exactly
# the shape `mut_RUN_review_rounds_photo_missing` produces and exactly what the non-null guard in
# `outcome` exists to catch. Recovering it from prose would repair the sabotage and leave that
# mutant scoring a point for nothing, which is the measured harm bin/sdd records for the EXEC
# sibling one screen up (a retry born with `pending_before: null` read `advanced` off a fabricated
# count). The dated path serves rows written before the fields existed, and those carry NEITHER.
echo "== reader: the dated REVIEW path leaves a row born with the fields alone =="
mkdir -p "$OUTSIDE/histroundmixed"
localize > "$OUTSIDE/histroundmixed/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T09:20:00-03:00","event":"session","run_id":"y1","invocation":"run","kit_sha":"fff2222","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m12","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"y1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"rounds_before":null,"rounds_after":2,"rounds_max":3,"gate":"fail","gate_why":"40-review-r2.md: Correctness = B — the gate requires Grade A on every criterion"}
EOF
out_roundmixed="$( SDD_STATE_DIR="$OUTSIDE/histroundmixed" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "a REVIEW row whose photograph went missing is not repaired from prose" "1" \
  "$(grep -c '^  m12  1 session(s) · 0 advanced · 1 churned · 0 idle · ' <<< "$out_roundmixed")"
assert_eq "and the dated path says it reached nothing, rather than saying nothing" "0" \
  "$(grep -c 'read their round from gate_why' <<< "$out_roundmixed")"

# --- the disclosure sentences count what the table shows -----------------------------------------
# Both sentences are DELETION SIGNALS: they say how much of the window was read through a dated
# compatibility path, and therefore when that path may come out. A count bound before the
# comparability filter counts rows that then leave as non-comparable, and the number cannot be
# reconciled with anything on screen — measured on the real ledger, the EXEC sentence said "2 rows"
# over a table of 1 session. Both counts are bound over `is_session and comparable`, which is the
# population the table above them is made of. The fixture carries one annotated row of each phase
# on a DIRTY kit_sha, so a count bound too early says 2 where the table says 1.
echo "== reader: the dated-path sentences count only rows the table shows =="
mkdir -p "$OUTSIDE/histdisclose"
localize > "$OUTSIDE/histdisclose/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-31T09:30:00-03:00","event":"session","run_id":"z1","invocation":"run","kit_sha":"fff3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m13","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"z1s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"3 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-31T09:31:00-03:00","event":"session","run_id":"z1","invocation":"run","kit_sha":"fff3333","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m13","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"z2s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"2 of 4 increment(s) still to execute"}
{"v":1,"ts":"2026-08-31T09:32:00-03:00","event":"session","run_id":"z2","invocation":"run","kit_sha":"fff3333","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m13","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"z3s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"40-review-r1.md: Correctness = B — the gate requires Grade A on every criterion"}
{"v":1,"ts":"2026-08-31T09:33:00-03:00","event":"session","run_id":"z2","invocation":"run","kit_sha":"fff3333","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m13","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":2,"auto_retry":false,"session":"z4s","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"40-review-r2.md: Correctness = B — the gate requires Grade A on every criterion"}
EOF
out_disclose="$( SDD_STATE_DIR="$OUTSIDE/histdisclose" "$SDD" autonomy 2>&1 )"
# Not vacuous: the fixture really does hold rows the table does not show, and says so.
assert_eq "the fixture really does hide two rows behind the comparability filter" "1" \
  "$(grep -c '2 non-comparable row(s) excluded' <<< "$out_disclose")"
assert_eq "the EXEC sentence counts only the rows the table is made of" "1" \
  "$(grep -c '(1 EXEC row(s) older than the pending fields read their progress from gate_why)' <<< "$out_disclose")"
assert_eq "the REVIEW sentence counts only the rows the table is made of" "1" \
  "$(grep -c '(1 REVIEW row(s) older than the round fields read their round from gate_why)' <<< "$out_disclose")"

# --- the reader gives a full accounting, never a silent gap --------------------------------------
# Two findings from review, one root cause: a bucket the reader does not name is a bucket that can
# vanish with no trace (finding 3 — the reviewer's ledger with no `event` key printed nothing and
# exited 0). The fix makes every row land in one of four buckets and names each non-empty one.

# Only escalations, zero comparable sessions: the table must not go blank. Blank reads as "checked,
# found nothing" — the same vacuity as the empty-ledger case below, just one layer deeper.
echo "== reader: only escalations, no comparable sessions =="
mkdir -p "$OUTSIDE/onlyesc"
localize > "$OUTSIDE/onlyesc/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/onlyesc" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (escalations are still data)" "0" "$rc"
assert_eq "says there are no comparable sessions, in place of the table" "1" \
  "$(grep -c 'no comparable sessions' <<< "$out")"
assert_eq "and never prints a percentage when there is nothing to compute one over" "0" \
  "$(grep -c '%' <<< "$out")"
assert_eq "the escalations are still both named" "1" "$(grep -c 'no-progress: 1' <<< "$out")"
assert_eq "the second kind too" "1" "$(grep -c 'increment-blocked: 1' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (escalations only)" "$out"

# --- the two readers of the ledger agree on the axis -------------------------
# `sdd autonomy` (the human's window) and `sdd kaizen --series` (the judge's source of truth) read
# the SAME file. The series has always sliced escalations INSIDE a kit_sha group; this reader
# grouped them by `.kind` over the whole file, with no version axis and no comparability filter.
# A human reading the table next to a verdict saw different escalation counts for the same period
# with nothing explaining the divergence — and the kit version is precisely the axis the ledger
# exists to measure, so the divergence corrodes trust in the instrument the whole loop depends on.
echo "== reader: escalations carry the kit_sha axis =="
mkdir -p "$OUTSIDE/escaxis"
localize > "$OUTSIDE/escaxis/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"blocked","kind":"no-progress","run_id":"r2","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"degraded","kind":"review-to-draft","run_id":"r2","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"REVIEW","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"blocked","kind":"no-progress","run_id":"r3","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:05:00-03:00","event":"blocked","kind":"no-progress","run_id":"r4","invocation":"run","kit_sha":null,"kit_dirty":null,"project":"p1","repo":"/p1","mission":"m4","phase":"EXEC","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/escaxis" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (a ledger of escalations across two kit versions is data)" "0" "$rc"

# The same kind under two kit versions is two facts, not one number: summing them is exactly the
# arithmetic that makes "did the change help?" unanswerable.
assert_eq "no-progress under the version it happened in" "1" \
  "$(grep -c '^  aaaaaaa  no-progress: 1$' <<< "$out")"
assert_eq "and the one under the other version, counted apart" "1" \
  "$(grep -c '^  bbbbbbb  no-progress: 1$' <<< "$out")"
assert_eq "a second kind stays with its own version too" "1" \
  "$(grep -c '^  aaaaaaa  increment-blocked: 1$' <<< "$out")"
assert_eq "a degradation is an escalation on the axis, like any other" "1" \
  "$(grep -c '^  bbbbbbb  review-to-draft: 1$' <<< "$out")"
# Anti-vacuity: an escalation line with no version in front of it IS the old axis-less shape, so
# asserting its absence is what makes the four assertions above impossible to satisfy by accident.
assert_eq "no escalation line is printed without a version" "0" \
  "$(grep -cE '^  [A-Za-z][A-Za-z0-9_-]*: [0-9]+$' <<< "$out")"
# Non-comparable escalations are excluded and COUNTED, the same refusal the session block already
# makes: a dirty kit and a null sha cannot be attributed to a version, and a row silently summed
# into one is worse than a row excluded out loud.
assert_eq "the dirty kit and the null sha are excluded, not summed into a version" "1" \
  "$(grep -c '2 non-comparable' <<< "$out")"
assert_bucket_sum "the buckets sum to the header total (escalations on two versions)" "$out"

# The increment's metric, stated as the two instruments agreeing — compared as DATA, kind by kind,
# not as prose. Whatever `sdd kaizen --series` reports for the latest kit version, the human table
# has to report the same. A divergence fails here even when each side looks plausible alone, which
# is the only way to catch the two readers drifting apart again.
series="$( SDD_STATE_DIR="$OUTSIDE/escaxis" "$SDD" kaizen --series 2>/dev/null )"
latest_sha="$(jq -r '.latest.kit_sha' <<< "$series")"
assert_eq "the series and the reader are talking about the same latest version" "bbbbbbb" "$latest_sha"
series_esc="$(jq -r '.latest.escalations | to_entries | sort_by(.key)
                     | map("\(.key): \(.value)") | join("\n")' <<< "$series")"
# $1 is the sha, $2 the "<kind>:" token and $3 the count; the session table lines have "session(s)"
# in $3, so the numeric guard keeps them out without a second pattern to maintain.
reader_esc="$(awk -v sha="$latest_sha" '$1 == sha && $3 ~ /^[0-9]+$/ { print $2, $3 }' <<< "$out" | sort)"
assert_eq "the human reader and the judge count the latest version's escalations alike" \
  "$series_esc" "$reader_esc"

# --- one test of comparability, not three that agree by luck -----------------
# "Can this row be attributed to a kit version?" was asked in three places with two different sets
# of words: `.kit_dirty == false` in the session table, `.kit_dirty != true` in the escalation
# table, and `.kit_dirty != true` again inside `kaizen_series`. On every row the runner writes the
# spellings agree — the stamp emits `kit_dirty:null` only together with `kit_sha:null`, and a null
# sha already fails all three — which is precisely why they could sit there disagreeing unseen.
# `kit_dirty:null` WITH a sha filled (a hand edit, a partial write, a future stamp that learns the
# sha before the dirtiness) is the one input that separates them, and on it the human's own table
# counted an escalation under a version while refusing the session standing right next to it.
#
# The assertions below are DIFFERENTIAL on purpose: the readers are compared TO EACH OTHER over
# twin rows, never to a constant, so no fixture regime satisfies them by accident and whichever
# side is "improved" alone is the side that fails. The known-clean control is what stops a reader
# that excludes everything from passing them all.
echo "== reader: the three comparability tests are one =="

# How many lines each reader printed for one version. The session line ends in "US$ <n>"; the
# escalation line is "<sha>  <kind>: <n>" — the numeric tail keeps the two patterns disjoint.
axis_sessions()    { grep -cE "^  $2  [0-9]+ session\(s\)" <<< "$1"; }
axis_escalations() { grep -cE "^  $2  [A-Za-z][A-Za-z0-9_-]*: [0-9]+$" <<< "$1"; }

mkdir -p "$OUTSIDE/axisnull" "$OUTSIDE/axisclean"
# Twin rows — one session, one escalation, same version, dirtiness UNKNOWN.
localize > "$OUTSIDE/axisnull/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ccccccc","kit_dirty":null,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"ccccccc","kit_dirty":null,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
# The same twins with the dirtiness KNOWN-clean: the control that keeps the agreement above from
# being satisfied by a reader which simply drops everything.
localize > "$OUTSIDE/axisclean/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"blocked","kind":"no-progress","run_id":"r1","invocation":"run","kit_sha":"ccccccc","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","gate_why":"x"}
EOF
out_null="$( SDD_STATE_DIR="$OUTSIDE/axisnull" "$SDD" autonomy 2>&1 )"
out_clean="$( SDD_STATE_DIR="$OUTSIDE/axisclean" "$SDD" autonomy 2>&1 )"

assert_eq "unknown dirtiness: the session table and the escalation table give the same verdict" \
  "$(axis_sessions "$out_null" ccccccc)" "$(axis_escalations "$out_null" ccccccc)"
assert_eq "known-clean: the two tables give the same verdict there too" \
  "$(axis_sessions "$out_clean" ccccccc)" "$(axis_escalations "$out_clean" ccccccc)"
# ...and they do not agree merely by both being empty: the control has to COUNT its twins.
assert_eq "the control is not vacuous — a known-clean pair is counted by both readers" \
  "1 1" "$(axis_sessions "$out_clean" ccccccc) $(axis_escalations "$out_clean" ccccccc)"
# Direction, not just agreement: unknown is never read as clean. A row nobody can attribute to a
# version is excluded OUT LOUD, the same refusal the dirty kit and the null sha already get.
assert_eq "unknown dirtiness is non-comparable, never assumed clean" "1" \
  "$(grep -c '2 non-comparable' <<< "$out_null")"
assert_bucket_sum "the four buckets sum to the header total (unknown dirtiness)" "$out_null"
assert_bucket_sum "the four buckets sum to the header total (known-clean twins)" "$out_clean"

# The judge reads the SAME file through its own jq program, where the predicate was spelled a third
# time. Fixing only `sdd autonomy` would not remove the divergence — it would move it from inside
# one command to between two commands, which is the harder one to notice.
series_null="$( SDD_STATE_DIR="$OUTSIDE/axisnull" "$SDD" kaizen --series 2>/dev/null )"
# The `:-0` matters: the reader PRINTS NO LINE when it excludes nothing, so num_before gives "" and
# jq gives "0". Left raw, this assertion would go red on a reader that excludes nothing — red for a
# formatting difference instead of for the divergence it exists to measure, and the direction
# assertion above would stop being the thing that catches that case.
human_noncomp="$(num_before "$out_null" 'non-comparable')"; human_noncomp="${human_noncomp:-0}"
assert_eq "the judge excludes exactly the rows the human's reader excludes" \
  "$human_noncomp" "$(jq -r '.excluded.non_comparable' <<< "$series_null")"
series_clean="$( SDD_STATE_DIR="$OUTSIDE/axisclean" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "and admits exactly the ones it admits — the control again, so neither side can just refuse everything" \
  "0 ccccccc" \
  "$(jq -r '.excluded.non_comparable' <<< "$series_clean") $(jq -r '.latest.kit_sha' <<< "$series_clean")"

# --- the ledger is global, the reader is not ---------------------------------
# One file per machine, on purpose: cross-repo questions stay answerable. What was missing is the
# reader asking "mine?" — until this, a `sdd run` in a /tmp fixture repo wrote rows the judge in
# the kit repo counted as its own. The twin of the series assertion in check-kaizen.sh, over the
# HUMAN's table: the two instruments read the same file and neither may see what is not its own.
#
# DIFFERENTIAL, because one reading cannot tell "filters by repo" from "returns everything": the
# same ledger read from two repos, two sessions here and three there. No filter prints 5 and 5;
# a filter that refuses everything prints 0 and 0; only the honest one prints 2 and 3.
echo "== reader: the ledger is global, the reader is not =="
mkdir -p "$OUTSIDE/otherrepo" "$OUTSIDE/tworepos" "$OUTSIDE/onlyhere"
( cd "$OUTSIDE/otherrepo" && git init -q -b main )
OTHER="$( cd "$OUTSIDE/otherrepo" && git rev-parse --show-toplevel )"
ledger_row() {   # ledger_row <repo> <mission> — one clean comparable session on kit ccccccc
  jq -cn --arg repo "$1" --arg mission "$2" \
    '{v:1, ts:"2026-08-16T14:00:00-03:00", event:"session", run_id:"r", invocation:"run",
      kit_sha:"ccccccc", kit_dirty:false, project:"p", repo:$repo, mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
      gate:"pass", gate_why:"x"}'
}
# Interleaved, so no split on file order can pass by accident.
{ ledger_row "$FIXROOT" h1; ledger_row "$OTHER" t1; ledger_row "$FIXROOT" h2
  ledger_row "$OTHER" t2;   ledger_row "$OTHER" t3; } > "$OUTSIDE/tworepos/autonomy-log.jsonl"
{ ledger_row "$FIXROOT" h1; ledger_row "$FIXROOT" h2; } > "$OUTSIDE/onlyhere/autonomy-log.jsonl"

out_here="$(  SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy 2>&1 )"
out_there="$( cd "$OTHER" && SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy 2>&1 )"
assert_eq "a row from another repo never enters the human table" "2 3" \
  "$(sum_sessions "$out_here") $(sum_sessions "$out_there")"
assert_eq "the header counts the rows of this repo, never the lines of the file" "1" \
  "$(grep -c '· 2 row(s) ·' <<< "$out_here")"
# What left has to be NAMED. A filter that drops rows in silence is the same instrument this
# mission exists to kill: the number would be right and nobody could tell why it moved.
assert_eq "and what left is counted, never dropped in silence" "1" \
  "$(grep -c '3 row(s) excluded: born in another repo' <<< "$out_here")"
assert_eq "symmetrically, read from the other repo" "1" \
  "$(grep -c '2 row(s) excluded: born in another repo' <<< "$out_there")"
assert_bucket_sum "the four buckets still sum to the header total, per repo" "$out_here"

# A ledger that holds rows, none of them yours: 'no data' and rc 1, saying WHERE they are. The
# three silences are named apart on purpose — an empty file sends you looking for a runner that
# never wrote, which is the wrong hunt when the rows are right there under another path.
out_none="$( cd "$OTHER" && SDD_STATE_DIR="$OUTSIDE/onlyhere" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a ledger with no row of yours refuses, same rc as any other refusal" "1" "$rc"
assert_eq "and says the rows exist, under another repo — not that nothing was recorded" "1" \
  "$(grep -c 'none of the 2 row(s)' <<< "$out_none")"
assert_eq "never a percentage computed out of somebody else's sessions" "0" \
  "$(grep -c '%' <<< "$out_none")"

# --- ...and --all-repos is the door back to the cross-repo question ----------
# The filter above is right as a DEFAULT and wrong as the only option. The ledger is ONE file per
# machine precisely so maturity stays comparable BETWEEN projects (docs/pipeline.md), and once the
# filter landed no reader could ask that question at all — the fixture contamination it removed
# took the cross-repo number with it. The flag is the explicit door back; leaving the default open
# is what let a /tmp fixture repo move the judge's own numbers in the first place.
#
# DIFFERENTIAL over ONE ledger, like every pair in this file: the two readings are compared to EACH
# OTHER and never to a constant. A flag that is a no-op prints the same numbers twice; a flag that
# opened the default prints the whole file twice (and the assertions above go red); only an honest
# one is STRICTLY wider with the flag than without, with the foreign bucket emptied because with it
# nothing is foreign any more. Both readers are pinned, because the flag has to reach the predicate
# and not one command's own copy of the question.
echo "== reader: --all-repos =="

# wider <a> <b> -> "wider" when a is strictly greater than b, "not wider" otherwise. A side that is
# not a number (an unknown-option death printing nothing, a jq miss) is NEVER evidence of widening:
# it answers "not wider" instead of letting `[ -gt ]` die and leaving the assertion to read the
# shell's own noise. Same reason num_before defaults to "" rather than guessing.
wider() {
  case "${1:-x}" in *[!0-9]*) printf 'not wider'; return 0 ;; esac
  case "${2:-x}" in *[!0-9]*) printf 'not wider'; return 0 ;; esac
  if [ "$1" -gt "$2" ]; then printf 'wider'; else printf 'not wider'; fi
}
foreign_of() { local m; m="$(num_before "$1" 'row\(s\) excluded: born in another repo')"; printf '%s' "${m:-0}"; }

out_all="$( SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy --all-repos 2>&1 )"
assert_eq "all-repos: the human table widens to the whole ledger, and nothing is foreign under it" \
  "wider 3 0" \
  "$(wider "$(sum_sessions "$out_all")" "$(sum_sessions "$out_here")") $(foreign_of "$out_here") $(foreign_of "$out_all")"

# The judge reads the same file through its own jq program, and the two instruments must not drift.
#
# ⚠️ This pair used to demand that the flag CHANGE the judge's series (other_repo 3 → 0, missions
# rising). ADR 0005 part 1 deletes that premise: the judge reads every repo by DEFAULT — ADR 0003
# says verdict evidence comes from real target repos, and the per-repo default kept it looking at
# exactly the one repo 0003 declared unusable. So the flag decides nothing here, and the old pair
# would now be one value compared with itself. What replaced it is the same concern stated for the
# world the ADR built: the flag is a no-op on the judge, and the two commands answer DIFFERENT
# questions over one file on purpose.
ser_here="$( SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
ser_all="$(  SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series --all-repos 2>/dev/null )"
assert_eq "all-repos: the judge already reads every repo, so the flag moves nothing in its series" \
  "0 0 same" \
  "$(jq -r '.excluded.other_repo' <<< "$ser_here") $(jq -r '.excluded.other_repo' <<< "$ser_all") $( [ "$ser_here" = "$ser_all" ] && echo same || echo differ )"
# The control, and it is what stops the line above from reading as "the repo filter was deleted":
# over the SAME file the human's default table still excludes the other repo's rows. Two commands,
# two answers, one ledger — asserted against each other rather than each against a literal.
assert_eq "all-repos: ...and the human's default table over that same file still filters per repo" \
  "0 3" "$(jq -r '.excluded.other_repo' <<< "$ser_here") $(foreign_of "$out_here")"
# Anti-vacuity: a flag that widened the reading by losing rows on the way would still be "wider".
assert_bucket_sum "the four buckets sum to the header total (--all-repos over two repos)" "$out_all"

# --- an exclusion that was NEVER in the header total says so -----------------
# The header counts the rows this reader admitted; the accounting paragraph under the table lists
# what left. Two of its four lines name populations that were bound BEFORE the repo filter — they
# never entered the total in the first place — so a reader adding the paragraph up against the
# header could not make it close. Measured on the real ledger: header 96, table 89 sessions, 7
# non-comparable (89 + 7 = 96, correct), and then "11 row(s) excluded: born in another repo"
# printed underneath, inviting 96 - 11.
#
# What is NOT done here, and the reason: deleting those two lines would close the arithmetic and
# break something older and better — "what left has to be NAMED", the invariant three assertions
# above this one exist to hold. The fix is a sentence that says the two populations were never in
# the total, so both hold at once. Hence the assertion is about ORDER and PRESENCE, not about a
# number: the disclaimer has to be there exactly when there is something to disclaim, and above it.
declared_scope() { # declared_scope <reader output> -> declared | silent | none | <what is wrong>
  local o="$1" dis oos
  dis="$(grep -n 'never part of the' <<< "$o" | head -1 | cut -d: -f1)"
  oos="$(grep -n 'born in another repo\|no repo field' <<< "$o" | head -1 | cut -d: -f1)"
  if [ -z "$oos" ]; then
    [ -z "$dis" ] && printf 'none' || printf 'a disclaimer with nothing to disclaim'
    return 0
  fi
  [ -n "$dis" ] || { printf 'silent'; return 0; }
  if [ "$dis" -lt "$oos" ]; then printf 'declared'; else printf 'the disclaimer sits below the lines it disclaims'; fi
}
# DIFFERENTIAL over one ledger: the same file read per repo (3 foreign rows) and with --all-repos
# (nothing is foreign). A fix that printed the sentence unconditionally would answer "declared" for
# both and be caught by the second term; one that never printed it answers "silent".
assert_eq "an exclusion that never entered the header total says so, and only when there is one" \
  "declared none" "$(declared_scope "$out_here") $(declared_scope "$out_all")"

# --- ...and the mission is a unit the reader can ask about ------------------
# The kit_sha table answers "did this VERSION get better". D12 asks a different question — US$ per
# merged PR, and how many times a human had to step in — and its unit is the MISSION. Without this
# view the pilot measures it by hand, which is the form of proof principle 1 refuses.
#
# The grouping key is (repo, mission), the one kaizen_series already holds: two projects run the
# same dated slug on the same day, and --all-repos puts their rows in one reading.
echo "== reader: --by-mission =="
# Two `- intervention:` notes for h1 and none for h2 — the count has to come from the ARTEFACT.
# The marker is a TOKEN and the text after it is prose, exactly like the status words the boot
# prompt tells every session to leave in English: the third bullet below carries the word in the
# middle of a sentence and must NOT be counted, or the reader is a word-frequency meter rather
# than a census of a marker.
mkdir -p "$FIX/docs/handoffs/h1" "$FIX/docs/handoffs/h2"
cat > "$FIX/docs/handoffs/h1/checkpoint.md" <<'EOF'
| ID | Incremento | Check | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` -> 0 | done | abc1234 |

## Execution notes

- intervention: the human redid the REVIEW phase by hand — REVIEW — US$ 12.40
- intervention: the human fixed the branch by hand — PR
- 2026-01-01 10:00 · `I1` · no intervention was needed here, and this line is prose
EOF
printf '# no notes here\n' > "$FIX/docs/handoffs/h2/checkpoint.md"

out_bm="$( SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy --by-mission 2>&1 )"
mission_line() { grep -m1 -E "^  $1  " <<< "$2"; }
# Summed in integer CENTS, never as a float: `printf "%.2f"` writes `0,00` under a pt-BR locale and
# `0.00` under C, so a float comparison here would pass or fail by the environment of whoever ran
# the suite. The money is already printed to exactly two places by the reader's own `usd`.
usd_cents() {
  grep -oE 'US\$ [0-9]+\.[0-9][0-9]' <<< "$1" \
    | sed 's/US\$ //; s/\.//' \
    | awk '{ s += $1 + 0 } END { print s + 0 }'
}

# ONE assertion for the shape: a line per mission of THIS repo, the interventions read off the
# artifact (2 for h1, 0 for h2), and nothing from the other repo's three missions.
assert_eq "--by-mission prints one line per mission of this repo, with the interventions the checkpoint records" \
  "2 h1:2 h2:0" \
  "$(grep -cE '^  h[12]  ' <<< "$out_bm") h1:$(mission_line h1 "$out_bm" | grep -oE '[0-9]+ intervention note' | grep -oE '^[0-9]+') h2:$(mission_line h2 "$out_bm" | grep -oE '[0-9]+ intervention note' | grep -oE '^[0-9]+')"

# The Check of the increment: two groupings of ONE population have to agree about the money. A
# view that summed a different set of rows would be a second instrument disagreeing with the first
# over one file — the divergence the kit_sha axis of this reader was rewritten to remove.
# Floor beside the verdict: a comparison of two zeros is green in every broken world, and the
# reader printing nothing at all is exactly one of them.
assert_eq "the money adds up the same however the rows are grouped" \
  "$(usd_cents "$out_here") over-zero" \
  "$(usd_cents "$out_bm") $([ "$(usd_cents "$out_here")" -gt 0 ] && echo over-zero || echo 'both sides are zero')"

# The fixture repo has to end clean — the two assertions at the bottom of this file say so, and
# these handoff directories are this block's own litter.
# A checkpoint straight out of the template owes ZERO interventions. The template ships one
# `- intervention:` line to show the FORM of the marker, and that stub used to be counted verbatim
# by the reader: every mission was born owing a phantom intervention to the very instrument that
# judges how much the human had to step in. Measured on 2026-08-25, on the M2 pilot — the executor
# deleted the line by hand and nothing checked that it had.
# The fixture is `cp` of the real template, never a hand-written imitation: an imitation would be
# written by whoever writes the fix, and would agree with the fix instead of measuring it.
# Its own ledger, never `tworepos`: the counts of that file sustain eight assertions above.
mkdir -p "$FIX/docs/handoffs/h3" "$OUTSIDE/bymission3"
cp "$ROOT/templates/checkpoint.md" "$FIX/docs/handoffs/h3/checkpoint.md"
{ ledger_row "$FIXROOT" h1; ledger_row "$FIXROOT" h2; ledger_row "$FIXROOT" h3; } \
  > "$OUTSIDE/bymission3/autonomy-log.jsonl"
out_bm3="$( SDD_STATE_DIR="$OUTSIDE/bymission3" "$SDD" autonomy --by-mission 2>&1 )"
# The presence term comes FIRST and as its own field: a reader that printed no h3 line at all would
# leave the count field empty, and "absent" is not "zero" — without the term, deleting the mission
# from the report would be one of the worlds this assertion calls green.
assert_eq "a checkpoint born verbatim from the template owes no intervention" \
  "1 h3:0" \
  "$(grep -cE '^  h3  ' <<< "$out_bm3") h3:$(mission_line h3 "$out_bm3" | grep -oE '[0-9]+ intervention note' | grep -oE '^[0-9]+')"

rm -rf "$FIX/docs/handoffs/h1" "$FIX/docs/handoffs/h2" "$FIX/docs/handoffs/h3"

# --- ...and the review loop is a cell of its own ----------------------------
# The metric of `20260901-o-revisor-so-acha`: what the REVIEW phase costs is not the REVIEW rows
# alone. Every EXEC session the review sends back — the `R<n>` increments a round writes — is part
# of the same loop, and summing only the REVIEW rows would report a cut that merely MOVED money
# into the phase next door. The EXEC sessions BEFORE the first round are the mission's own work
# and are not in it.
#
# DIFFERENTIAL, because one reading cannot tell "counts the loop" from "counts every EXEC": over
# the same four sessions, the honest cell reads 16.00 (REVIEW 10 + the EXEC after it 6), a reader
# that dropped the index filter reads 20.00 (the EXEC before it too), and one that summed
# everything after the round reads 18.00 (the DOCS row rides along). The twin without the round
# pins the other direction: no REVIEW row, no cell at all — a suffix printed unconditionally would
# be a "review loop" on a mission that never had one.
echo "== reader: --by-mission prints the review loop =="
mkdir -p "$OUTSIDE/reviewloop" "$OUTSIDE/reviewloop_norev"
localize > "$OUTSIDE/reviewloop/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-09-01T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fffffff","kit_dirty":false,"project":"p1","repo":"/p1","mission":"rl1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":4.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-09-01T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fffffff","kit_dirty":false,"project":"p1","repo":"/p1","mission":"rl1","phase":"REVIEW","step":"REVIEW","agent":"sdd-reviewer","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":10.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-09-01T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fffffff","kit_dirty":false,"project":"p1","repo":"/p1","mission":"rl1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":6.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-09-01T10:03:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"fffffff","kit_dirty":false,"project":"p1","repo":"/p1","mission":"rl1","phase":"DOCS","step":"DOCS","agent":"sdd-docs","model":"opus","attempt":1,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
# The twin is DERIVED from the first file, never a second hand-written ledger: two hand-written
# fixtures drift, and the one that drifted would still be green.
grep -v '"phase":"REVIEW"' "$OUTSIDE/reviewloop/autonomy-log.jsonl" \
  > "$OUTSIDE/reviewloop_norev/autonomy-log.jsonl"
out_rl="$(  SDD_STATE_DIR="$OUTSIDE/reviewloop"       "$SDD" autonomy --by-mission 2>&1 )"
out_rl0="$( SDD_STATE_DIR="$OUTSIDE/reviewloop_norev" "$SDD" autonomy --by-mission 2>&1 )"
# `|| echo none` covers the whole pipeline, which is the point: "the cell is not there" is an
# ANSWER here, and the fallback has to name it instead of letting an empty field pass for it.
rl_cell() { mission_line rl1 "$1" | grep -oE 'review loop US\$ [0-9]+\.[0-9][0-9] \([0-9]+%\)' || echo none; }
# The presence term comes first, and for the reason the h3 assertion above states: a reader that
# printed no rl1 line at all would leave the cell field empty, and "absent" is not "none".
assert_eq "the review loop counts REVIEW and the EXEC sessions after it, never the EXEC before" \
  "1 review loop US\$ 16.00 (73%) 1 none" \
  "$(grep -cE '^  rl1  ' <<< "$out_rl") $(rl_cell "$out_rl") $(grep -cE '^  rl1  ' <<< "$out_rl0") $(rl_cell "$out_rl0")"

# --- launches and reopenings: the intervention count comes from the ledger, not from prose --------
# D16 read the D12 count off `- intervention:` notes, and the notes were never written: the
# mission with three launches (SQ-111, 2026-08-27) had zero. `run_id` is on every row of every
# repo, so the count is distinct run_id per mission — the FACT, never `launches - 1` ("interventions
# = launches - 1" is the reading, written in CONTEXT.md; a `- 1` here would print 0 on a mission
# abandoned after its first launch, which is an intervention).
echo "== reader: --by-mission counts launches =="
mkdir -p "$OUTSIDE/launches"
localize > "$OUTSIDE/launches/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":3,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"session","run_id":"r3","invocation":"retry","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:05:00-03:00","event":"session","run_id":"r4","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s6","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
out_l="$( SDD_STATE_DIR="$OUTSIDE/launches" "$SDD" autonomy --by-mission 2>&1 )"
# cell_of <mission> <output> <cell-word>  -> the integer in front of that cell word, or "".
# The writer is mission_line (a grep over a herestring); the readers consume all of its output, so
# nothing on the reading end exits early — the SIGPIPE trap this repo warns about needs a reader
# that quits, and -o never does.
cell_of() { mission_line "$1" "$2" | grep -oE "[0-9]+ $3" | grep -oE '^[0-9]+'; }
assert_eq "launches count distinct run_id per mission: three rows of one run are one launch" \
  "m1:1 m2:2 m3:1" \
  "m1:$(cell_of m1 "$out_l" 'launch') m2:$(cell_of m2 "$out_l" 'launch') m3:$(cell_of m3 "$out_l" 'launch')"

# reopened: a session in a phase BELOW one whose gate had already PASSED, in $PHASES order. NOT
# "the phase index went down" — that counts the designed loop (QA fails, opens a fix increment,
# EXEC runs it), which frete-cif-fob did three times with QA REFUSED, all of it the pipeline
# working. The pair below is identical but for the gate of the QA row, so only the gate can
# separate 1 from 0. The KAIZEN row after PR sits outside $PHASES: null index, counted on neither
# side — jq orders null below every number, so with the null guard gone the pass twin reads 2.
echo "== reader: --by-mission counts reopenings by the gate, not by the direction =="
mkdir -p "$OUTSIDE/reopen_pass" "$OUTSIDE/reopen_fail"
localize > "$OUTSIDE/reopen_pass/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"the QA row"}
{"v":1,"ts":"2026-08-15T10:02:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:03:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s4","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:04:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"KAIZEN","step":"KAIZEN","agent":"sdd-kaizen","model":"opus","attempt":1,"auto_retry":false,"session":"s5","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
sed 's|"gate":"pass","gate_why":"the QA row"|"gate":"fail","gate_why":"the QA row"|' \
  "$OUTSIDE/reopen_pass/autonomy-log.jsonl" > "$OUTSIDE/reopen_fail/autonomy-log.jsonl"
# The twin has to differ, or the differential below compares a file with itself.
assert_eq "the twin differs from its pair on exactly one row" "1" \
  "$(diff "$OUTSIDE/reopen_pass/autonomy-log.jsonl" "$OUTSIDE/reopen_fail/autonomy-log.jsonl" | grep -c '^<')"
out_rp="$( SDD_STATE_DIR="$OUTSIDE/reopen_pass" "$SDD" autonomy --by-mission 2>&1 )"
out_rf="$( SDD_STATE_DIR="$OUTSIDE/reopen_fail" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "EXEC after a PASSED QA is a reopening; EXEC after a FAILED QA is the loop working" \
  "pass:1 fail:0" "pass:$(cell_of m1 "$out_rp" 'reopened') fail:$(cell_of m1 "$out_rf" 'reopened')"

# The population. session(s), the outcomes and US$ are drawn over the COMPARABLE sessions — that is
# the sum this file closes against the version table. launches and reopened are drawn over EVERY
# local session of the mission: a launch that landed on a dirty kit was a launch, and on SQ-111 the
# post-PR QA row — the reopening that motivated the field — carries kit_dirty:true, so over the
# comparable rows alone reopened read 0 exactly where it mattered. This fixture mirrors SQ-111
# exactly: EXEC passes, PR passes (both comparable, clean kit), then QA runs AGAIN on a DIRTY kit
# and also passes — a phase index below PR, which had already passed, which is exactly what
# `reopened` exists to count, and the row `reopened` needs is the one row `comparable` refuses.
# When the two populations differ the accounting paragraph says so, once. Differential: the same
# mission with the dirty row removed reads one launch and zero reopened, and the sentence is gone.
echo "== reader: --by-mission draws launches and reopened over every session of the mission =="
mkdir -p "$OUTSIDE/population" "$OUTSIDE/populationclean"
localize > "$OUTSIDE/population/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:00:30-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"PR","step":"PR","agent":"sdd-publisher","model":"sonnet","attempt":1,"auto_retry":false,"session":"s1b","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
grep -v '"kit_dirty":true' "$OUTSIDE/population/autonomy-log.jsonl" > "$OUTSIDE/populationclean/autonomy-log.jsonl"
out_pop="$(  SDD_STATE_DIR="$OUTSIDE/population"      "$SDD" autonomy --by-mission 2>&1 )"
out_popc="$( SDD_STATE_DIR="$OUTSIDE/populationclean" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "two comparable sessions, two launches, one reopened: the dirty QA below a passed PR reopens" \
  "2 2 1" \
  "$(cell_of m1 "$out_pop" 'session') $(cell_of m1 "$out_pop" 'launch') $(cell_of m1 "$out_pop" 'reopened')"
assert_eq "and the accounting paragraph names the population difference, once" "1" \
  "$(grep -c '(launches and reopened are counted over every session of the mission, 1 of them non-comparable)' <<< "$out_pop")"
assert_eq "without the dirty row: one launch, no reopening, and the sentence is gone" "1 0 0" \
  "$(cell_of m1 "$out_popc" 'launch') $(cell_of m1 "$out_popc" 'reopened') $(grep -c 'counted over every session' <<< "$out_popc")"
assert_bucket_sum "the four buckets still sum to the header total (--by-mission, a dirty launch)" "$out_pop"

# --- the narrative cell, and the `?` that is gone --------------------------------------------------
# The official count is `launch(es)`, on every line. The `- intervention:` notes stay as what the
# human DID, printed as `intervention note(s)` when the checkpoint is on disk and not printed at all
# when it is not: `?` existed so that no false zero reached the official number, and the official
# number no longer comes from the file. Measured on the real ledger: the three missions of the
# pilot carried 0, 1 and 0 notes — the mission with three launches had none.
echo "== reader: --by-mission prints the notes as narrative, and never a ? =="
out_all_bm="$( SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" autonomy --all-repos --by-mission 2>&1 )"
assert_eq "no mission line carries a ? any more, this repo or another" "0 0" \
  "$(grep -c '? intervention' <<< "$out_bm") $(grep -c '? intervention' <<< "$out_all_bm")"
assert_eq "the notes print under the name that says what they are" "1" \
  "$(mission_line h1 "$out_bm" | grep -c '2 intervention note(s)')"
# The `launches` fixture has no docs/handoffs/m1 in $FIX at all: the cell is absent and the line
# still exists — absent is not zero, and the line has to be there for absent to mean anything.
assert_eq "with no checkpoint on disk the cell does not exist, and the line still does" "1 0" \
  "$(grep -cE '^  m1  ' <<< "$out_l") $(mission_line m1 "$out_l" | grep -c 'intervention')"
# The whole line once, in its final shape, every cell in order — so no reordering passes.
assert_eq "the mission line, cell by cell" "1" \
  "$(grep -cE '^  m1  3 session\(s\) · 1 advanced · 2 churned · 0 idle · 1 launch\(es\) · 0 reopened · US\$ 3\.00$' <<< "$out_l")"
# A foreign mission that shares a SLUG with a mission of this repo must not borrow its notes: the
# map of counts is keyed by slug alone (it is built from this repo rows), so the guard on the cell
# is the row repo. Two missions named h1 — ours, with a checkpoint on disk, and theirs — read
# together under --all-repos: both lines print (2), ours carries the cell (1), theirs does not (0).
# Without the guard the third number is 1: the same slug, our notes, their line.
mkdir -p "$OUTSIDE/noteclash" "$FIX/docs/handoffs/h1"
printf -- '- intervention: ours\n' > "$FIX/docs/handoffs/h1/checkpoint.md"
{ ledger_row "$FIXROOT" h1; ledger_row "$OTHER" h1; } > "$OUTSIDE/noteclash/autonomy-log.jsonl"
out_clash="$( SDD_STATE_DIR="$OUTSIDE/noteclash" "$SDD" autonomy --all-repos --by-mission 2>&1 )"
assert_eq "a mission of another repo never borrows the notes of a same-slug mission of this one" "2 1 0" \
  "$(grep -cE '^  [^ ]+/h1  ' <<< "$out_clash") $(grep -E '^  [^ ]+/h1  ' <<< "$out_clash" | grep -vE '^  otherrepo/' | grep -c 'intervention note') $(grep -E '^  otherrepo/h1  ' <<< "$out_clash" | grep -c 'intervention note')"
rm -rf "$FIX/docs/handoffs/h1"

# The header has to name the SCOPE it actually read. Under the flag the rows below come from every
# project on the machine, and a header still ending in one repo path reads as a claim ABOUT that
# repo — the same misattribution the filter was added to remove, now printed by the reader itself.
# Both halves are asserted: the right text present AND the other repo path absent, because a header
# that carried both would satisfy either half alone.
# ⚠️ NOT prefixed `all-repos` — the checkpoint Check for I3 counts `^  ok    all-repos` and demands
# exactly two. A new clause that needs a probe takes a new name, never a counted prefix.
assert_eq "scope header: it names the scope it read, never the one repo path it did not confine itself to" \
  "1 0" \
  "$( printf '%s %s' "$(grep -c 'all repos (--all-repos)' <<< "$out_all")" \
                     "$(grep -c "row(s) · $FIXROOT\$" <<< "$out_all")" )"
# And the control: WITHOUT the flag the header does end in this repo path, so the assertion above
# is about the flag and not about a header that never names a repo at all.
assert_eq "and without it the header does name this repo — the scope line is not merely blank" "1" \
  "$(grep -c "row(s) · $FIXROOT\$" <<< "$out_here")"

# `sdd help` advertises the flag; the parsers accept one. Nothing tied the two together, so a typo
# in either was green in both sensors — measured, `--allrepos` in the help text passed everything.
# The flag token is READ OUT of the help output and handed to both parsers, so the two can only
# agree by really agreeing. A parser that does not know it dies naming it (`unknown … option`).
HELPFLAG="$( "$SDD" help 2>&1 | sed -n 's/^  \(--[a-z][a-z-]*\) *read the WHOLE ledger.*/\1/p' | head -1 )"
assert_eq "the ledger flag the help advertises is one the help itself states — and not empty" "yes" \
  "$( case "${HELPFLAG:-}" in --?*) echo yes ;; *) echo "no:${HELPFLAG:-<empty>}" ;; esac )"
# ⚠️ ACCEPTANCE is read as rc 0, never as the absence of the word "unknown", and the near-miss is
# half the assertion. Both were measured on the previous spelling of this pair, which read
# `grep -c 'unknown'` on each parser: (a) replacing both `*) die "unknown … option"` arms with
# `*) : ;;` left it GREEN — a parser that accepts everything says "unknown" about nothing, so the
# typo in the help text this pair exists to catch sailed through the very assertion aimed at it;
# (b) making the `--all-repos)` arm die with a different sentence also left it green, while the
# command rejected the flag the help advertises. The word was the death's WORDING, not the answer.
# rc 0 on the advertised token says accepted; rc non-zero on `<token>x` says the arm matches the
# token and not a prefix of it, which is what kills the accept-everything degrade.
parser_rc() {  # parser_rc <args…> -> the rc of the runner, run against the two-repo fixture
  ( SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" "$@" >/dev/null 2>&1 ); printf '%s' "$?"
}
assert_eq "BOTH parsers accept the very token the help prints, and BOTH reject a near-miss of it" \
  "0 0 reject reject" \
  "$( printf '%s %s %s %s' \
       "$(parser_rc autonomy "${HELPFLAG:-–none}")" \
       "$(parser_rc kaizen --series "${HELPFLAG:-–none}")" \
       "$( [ "$(parser_rc autonomy "${HELPFLAG:-–none}x")" != 0 ] && echo reject || echo accept )" \
       "$( [ "$(parser_rc kaizen --series "${HELPFLAG:-–none}x")" != 0 ] && echo reject || echo accept )" )"

# --- ...and one mission is one mission in BOTH readers -----------------------
# The comment on `def mission_key` in bin/sdd promises that this file compares the two readers to
# each other so neither can be "improved" alone. It did not: nothing here mentioned mission_key,
# and the catalogue's mutant rewrites both spellings at once (`/g` on purpose), so not even it
# would see them diverge. A comment promising a sensor that does not exist is the same debt this
# mission removed three times over, so the sensor is written rather than the comment deleted.
#
# TWO clauses, because either alone fails open. The pair compared to EACH OTHER catches a fork (one
# reader taught the repo, the other left on the slug); the absolute `2` catches both being wrong
# TOGETHER, which is exactly the shape of the catalogue mutant. The fixture is the collision that
# made this real: `cmd_kaizen` mints `$(date +%Y%m%d)-kaizen`, so two projects judged on the same
# day carry the identical slug, and under --all-repos their rows land in one reading.
mkdir -p "$OUTSIDE/slugclash"
{ ledger_row "$FIXROOT" 20260817-kaizen; ledger_row "$OTHER" 20260817-kaizen; } \
  > "$OUTSIDE/slugclash/autonomy-log.jsonl"
assert_eq "mission identity: two projects sharing one dated slug are two missions in both readers" \
  "2 2" \
  "$( h="$( SDD_STATE_DIR="$OUTSIDE/slugclash" "$SDD" autonomy --all-repos 2>&1 \
              | sed -n 's/^  ccccccc  .* · \([0-9][0-9]*\) mission(s) · .*/\1/p' )"
      j="$( SDD_STATE_DIR="$OUTSIDE/slugclash" "$SDD" kaizen --series --all-repos 2>/dev/null \
              | jq -r '.latest.missions' )"
      printf '%s %s' "${h:-<empty>}" "${j:-<empty>}" )"

# --- ...and a worktree of one repo is still that repo ------------------------
# `git rev-parse --show-toplevel` answers per WORKTREE, so a mission run from `git worktree add`
# stamped a `repo` path the main checkout had never heard of. The row was born in the same repo
# and the reader called it foreign: the series went empty in the very workflow this kit tells you
# to use for isolation (superpowers:using-git-worktrees, and the multi-mission item in TODO.md).
#
# The rows here are written by the REAL writer, not by hand: what is under test is that the writer
# and the readers resolve ONE identity, and a hand-written `repo` field would just be this test
# agreeing with itself about the formula. The `blocked` increment reaches the writer with rc 3
# before any session opens — no token, same door the fixture at the top of this file uses.
#
# DIFFERENTIAL, and ASYMMETRIC on purpose: ONE row born in the main checkout, TWO born in the
# worktree, into ONE ledger. Broken, the two readings are 1-own/2-foreign and 2-own/1-foreign —
# they DISAGREE, and no swap of the two sides makes them match. Fixed, both read 3-own/0-foreign.
# A reader that refused everything would read 0/3 on both sides and agree — which is why the
# absolute assertion sits next to the differential one and neither is enough alone.
echo "== reader: a worktree is not another repo =="
WTMAIN="$OUTSIDE/wtrepo"
WTLINK="$OUTSIDE/wtlinked"
WTSTATE="$OUTSIDE/wtledger"
mkdir -p "$WTMAIN" "$WTSTATE"
(
  cd "$WTMAIN" || exit 1
  git init -q -b main
  git config user.email "fixture@example.com"
  git config user.name "Fixture"
  mkdir -p .sdd "docs/handoffs/$MISSION"
  printf '.sdd/logs/\n' > .gitignore
  cat > .sdd/config.sh <<'CFG'
PROJECT_NAME="wtfixture"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
CFG
  cat > "docs/handoffs/$MISSION/00-missao.md" <<'MIS'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
MIS
  : > "docs/handoffs/$MISSION/01-plano.md"
  cat > "docs/handoffs/$MISSION/checkpoint.md" <<'CPT'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | blocked | — |
CPT
  git add -A && git commit -qm "init"
  git worktree add "$WTLINK" -b wtprobe
) >/dev/null 2>&1

( cd "$WTMAIN" && SDD_STATE_DIR="$WTSTATE" "$SDD" run "$MISSION" ) >/dev/null 2>&1
( cd "$WTLINK" && SDD_STATE_DIR="$WTSTATE" "$SDD" run "$MISSION" ) >/dev/null 2>&1
( cd "$WTLINK" && SDD_STATE_DIR="$WTSTATE" "$SDD" run "$MISSION" ) >/dev/null 2>&1

# Floor, and NOT named `worktree…`: the checkpoint's Check counts `^  ok    worktree` and expects
# exactly two. Without this line a fixture that silently wrote nothing would leave both assertions
# below reading "0 0" on each side — absolutely equal, and absolutely vacuous.
assert_eq "the worktree probe reached the real writer from both checkouts" "3" \
  "$( [ -f "$WTSTATE/autonomy-log.jsonl" ] && grep -c . "$WTSTATE/autonomy-log.jsonl" || echo 0 )"

# "<own rows> <foreign rows>", read by the human's table from the checkout given.
wt_summary() {
  local o m; o="$( cd "$1" && SDD_STATE_DIR="$WTSTATE" "$SDD" autonomy 2>&1 )"
  m="$(num_before "$o" 'row\(s\) ·')"
  printf '%s %s' "${m:-0}" "$(foreign_of "$o")"
}
assert_eq "worktree: a row born in a worktree is local in the main checkout, and none is foreign" \
  "3 0" "$(wt_summary "$WTMAIN")"
assert_eq "worktree: and the two checkouts read one ledger identically — same rows, same buckets" \
  "$(wt_summary "$WTMAIN")" "$(wt_summary "$WTLINK")"

# --- ...but two repositories are never ONE ------------------------------------
# The fix above resolves the identity from the shared `.git`, and its FIRST spelling took the
# PARENT of that path — which merged distinct repositories in two shapes, both SILENTLY. In a
# SUBMODULE the common dir is `/parent/.git/modules/<name>`, so the parent is `/parent/.git/modules`
# for every submodule of that parent. In a BARE repo it is `.`, so the parent is whatever directory
# happens to hold the repo, shared with every bare repo beside it. Writer and readers then agree on
# the merged string, so nothing is excluded and `other_repo` stays 0: exactly the contamination
# d99a7fc closed, arriving through another door, and with no line of output admitting it.
# `--show-toplevel` answered both of these correctly and only worktrees wrong, so a fix for
# worktrees that lost them was a regression the pair above could not see.
#
# The identity is read back FROM THE RUNNER and never composed here: the fourth "no data" voice
# names the repo it resolved, so every comparison below is between things the command itself said.
# A probe that rebuilt the path from its own idea of the formula would agree with itself in every
# shape, which is how a green suite confirms an assumption instead of measuring it.
#
# The submodule shape comes from `git init --separate-git-dir`, which writes the very same `.git`
# FILE a submodule carries (`gitdir: /parent/.git/modules/<name>`) with no `submodule add` and no
# file-protocol config a modern git would demand for it.
echo "== reader: two repositories are never one =="
IDROOT="$OUTSIDE/identity"
IDSTATE="$OUTSIDE/identityledger"
mkdir -p "$IDROOT/parent/.git/modules" "$IDSTATE"
(
  git init -q "$IDROOT/parent"
  git init -q --separate-git-dir="$IDROOT/parent/.git/modules/suba" "$IDROOT/suba"
  git init -q --separate-git-dir="$IDROOT/parent/.git/modules/subb" "$IDROOT/subb"
  git init -q --bare "$IDROOT/bare1.git"
  git init -q --bare "$IDROOT/bare2.git"
  git init -q "$IDROOT/plain"
  mkdir -p "$IDROOT/hidden"
  git init -q --bare "$IDROOT/hidden/.git"
  # ...and a linked worktree OF that same bare repo, which is the shape that split its identity in
  # two: `rev-parse --is-bare-repository` answers about the ENTRY POINT, so the bare repo read from
  # itself said `true` and read from this worktree said `false`, and the cosmetic `/.git` strip fired
  # on one reading only. `worktree add` needs a commit and a bare repo has no index to make one
  # with, so it is minted with plumbing straight into the bare repo — no second checkout, no push.
  # The identity is passed explicitly: a machine with no `user.email` would otherwise fail HERE, and
  # a fixture that failed to build is caught by the floor below rather than read as a passing rule.
  GIT_AUTHOR_NAME=sdd GIT_AUTHOR_EMAIL=sdd@invalid \
  GIT_COMMITTER_NAME=sdd GIT_COMMITTER_EMAIL=sdd@invalid \
    git -C "$IDROOT/hidden/.git" commit-tree \
      "$( git -C "$IDROOT/hidden/.git" hash-object -w -t tree /dev/null )" -m seed \
    > "$IDROOT/hidden-seed"
  git -C "$IDROOT/hidden/.git" branch -f main "$(cat "$IDROOT/hidden-seed")"
  git -C "$IDROOT/hidden/.git" worktree add -q "$IDROOT/hiddenwt" main
) >/dev/null 2>&1
ln -sfn "$IDROOT/plain" "$IDROOT/plain-link"

# One row from a repo that is none of these, so every reading below has rows to REJECT and reaches
# the voice that names the identity it resolved. Over an empty file the first voice fires instead
# and names nothing, and every comparison here would be "" against "" — equal, and vacuous.
ledger_row "/elsewhere/notmine" x1 > "$IDSTATE/autonomy-log.jsonl"
id_of() { ( cd "$1" && SDD_STATE_DIR="$IDSTATE" "$SDD" autonomy 2>&1 ) \
            | sed -n 's/.*no data for \([^:]*\):.*/\1/p'; }

# Floor against exactly that vacuity: a fixture that failed to build resolves nothing, and "" is
# equal to "" in every pair below. Deliberately NOT named `identity…`, so it cannot be mistaken for
# one of the properties — it only says the instrument is plugged in.
assert_eq "the identity probe resolved a repo from all five shapes through the runner own voice" "5" \
  "$( n=0; for p in suba subb bare1.git bare2.git plain; do
        if [ -n "$(id_of "$IDROOT/$p")" ]; then n=$((n + 1)); fi
      done; echo "$n" )"

assert_eq "identity: two sibling submodules are two repos, never the modules dir that holds both" \
  "differ" \
  "$( if [ "$(id_of "$IDROOT/suba")" != "$(id_of "$IDROOT/subb")" ]
      then echo differ; else echo "same:$(id_of "$IDROOT/suba")"; fi )"
assert_eq "identity: two sibling bare repos are two repos, never the directory that merely holds them" \
  "differ" \
  "$( if [ "$(id_of "$IDROOT/bare1.git")" != "$(id_of "$IDROOT/bare2.git")" ]
      then echo differ; else echo "same:$(id_of "$IDROOT/bare1.git")"; fi )"
# The `pwd -P` half of the fix, which the worktree pair above never exercises: TMPDIR may itself be
# a symlink (the comment at the top of this file already says so), and one repo reached by two
# paths read as two repos is the same "series went empty" the worktree case was about.
assert_eq "identity: a checkout reached through a symlink is the SAME repo, not a second one" \
  "$(id_of "$IDROOT/plain")" "$(id_of "$IDROOT/plain-link")"
# The `/repo/.git` -> `/repo` step is COSMETIC and must not fire on a repository that IS a
# directory called `.git` — a bare repo there is the repo itself, and stripping the last component
# would name the directory that merely contains it, which is not a repo at all. That was the second
# half of the bare-repo defect: an identity that is non-empty and wrong silences the honest
# "not inside a git repository" warning and returns an empty series with nothing explaining it.
# Asserted as the PROPERTY (the last component survived) and not against a composed path: TMPDIR
# may be a symlink, so a literal expectation would be comparing a logical path against a resolved
# one and could go red for the normalization instead of for the rule.
assert_eq "identity: a bare repo that lives in a dir named .git is itself, not the dir above it" \
  "yes" \
  "$( id="$(id_of "$IDROOT/hidden/.git")"
      case "$id" in */hidden/.git) echo yes ;; *) echo "no:${id:-<empty>}" ;; esac )"
# ...and the OTHER entry point into that same repository has to agree, which is the half the rule
# above cannot state about itself. `--is-bare-repository` is a property of the entry point, not of
# the repository: it said `true` from the bare repo and `false` from this worktree of it, the strip
# fired on the second reading only, and one repository answered `/x/.git` and `/x` — the very
# collapse-and-split this function exists to prevent, reached without any exotic environment.
# DIFFERENTIAL and not a literal path: the two readings are compared to EACH OTHER, so no spelling
# of the formula satisfies it by agreeing with the test's own idea of it. `/hidden/.git` on the
# right is the anti-vacuity half — two empty reads are also "equal", and a reader that stripped
# BOTH would agree at `/hidden`, which is a directory that is nobody's repository.
assert_eq "identity: and a worktree of that bare repo resolves to the SAME repo, not to its parent" \
  "same /hidden/.git" \
  "$( a="$(id_of "$IDROOT/hidden/.git")"; b="$(id_of "$IDROOT/hiddenwt")"
      if [ "$a" = "$b" ]; then s=same; else s="split:${a:-<empty>}|${b:-<empty>}"; fi
      case "$b" in */hidden/.git) t=/hidden/.git ;; *) t="${b:-<empty>}" ;; esac
      printf '%s %s' "$s" "$t" )"

# Differing strings are not yet the property that matters. THIS is: a row born in one submodule is
# not readable as its sibling own. Broken, both readings answer 1 — they AGREE, and the agreement
# is the contamination. The `1` on the left is the anti-vacuity half: a reader that refused
# everything would answer `0 0` and fail here.
own_of() {
  local o; o="$( cd "$1" && SDD_STATE_DIR="$IDSTATE" "$SDD" autonomy 2>&1 )"
  if grep -q 'no data' <<< "$o"; then printf '0'; else printf '%s' "$(num_before "$o" 'row\(s\) ·')"; fi
}
ledger_row "$(id_of "$IDROOT/suba")" s1 > "$IDSTATE/autonomy-log.jsonl"
assert_eq "identity: a row born in one submodule is that submodule row and never its sibling" \
  "1 0" "$(printf '%s %s' "$(own_of "$IDROOT/suba")" "$(own_of "$IDROOT/subb")")"
ledger_row "$(id_of "$IDROOT/bare1.git")" b1 > "$IDSTATE/autonomy-log.jsonl"
assert_eq "identity: and a row born in a bare repo is never the neighbouring bare repo row" \
  "1 0" "$(printf '%s %s' "$(own_of "$IDROOT/bare1.git")" "$(own_of "$IDROOT/bare2.git")")"

# --- ...not even when the environment answers `cd` for us -------------------
# `--git-common-dir` comes back RELATIVE at the root of a checkout (`.git`), and bash searches
# $CDPATH for any `cd` operand whose first component is neither `/`, `.` nor `..` — so `cd .git`
# at a repo root is an environment-controlled lookup. Two ways it lied, both measured:
#
#   * with CDPATH naming any directory that holds a `.git` (a dotfiles checkout in $HOME is the
#     everyday shape), EVERY repo on the machine resolved to that one identity. Writer and readers
#     agree on it, so `other_repo` stays 0 and not one line of output admits it — the same silent
#     contamination d99a7fc closed, this time reachable from an env var;
#   * bash PRINTS the directory it found through CDPATH, on stdout, straight into this command
#     substitution — so `CDPATH=.` appended a second LINE to the identity and put a newline inside
#     the ledger's `repo` field.
#
# Both are shut by emptying CDPATH for the duration of each `cd`. The rule is the environment's,
# not git's, so no fixture of repository SHAPES could reach it: this block is the only probe.
#
# ⚠️ The floor below is not decoration and is deliberately NOT named `cdpath…`: it proves the
# poison is ARMED in this shell before any conclusion is drawn from it. A CDPATH that is not being
# consulted (a bash built with it off, a fixture whose poison directory holds no `.git`) makes
# every assertion here pass while measuring nothing — a probe that cannot sabotage what it claims
# to sabotage concludes nothing, and this file has already been bitten by exactly that.
echo "== reader: the environment does not get to answer 'which repo is this' =="
CDROOT="$OUTSIDE/cdpath"
mkdir -p "$CDROOT"
( git init -q "$CDROOT/poison"; git init -q "$CDROOT/one"; git init -q "$CDROOT/two" ) >/dev/null 2>&1

assert_eq "the CDPATH poison is armed: an unguarded relative cd .git lands in the poison checkout" \
  "yes" \
  "$( p="$( CDPATH="$CDROOT/poison" bash -c 'cd "$1" && cd .git >/dev/null && pwd -P' _ "$CDROOT/one" )"
      case "$p" in */poison/.git) echo yes ;; *) echo "no:${p:-<empty>}" ;; esac )"

# Read back from the runner's own "no data for <repo>" voice, like id_of above, and never composed
# here — a probe that rebuilt the path from its own idea of the formula would agree with itself
# under any CDPATH. The env goes on the EXTERNAL command (never as a prefix to a shell function,
# where bash's export rules differ), so what the runner sees is what this line says.
id_cd() {  # id_cd <cdpath> <dir> — the identity the runner resolves with CDPATH set to <cdpath>
  ( cd "$2" && CDPATH="$1" SDD_STATE_DIR="$IDSTATE" "$SDD" autonomy 2>&1 ) \
    | sed -n 's/.*no data for \([^:]*\):.*/\1/p'
}

# Basenames, not "differ" alone: two repos collapsed onto the POISON is the defect, and a pair that
# only said "they differ" would also be satisfied by two identities that are both wrong. An empty
# read (the vacuous way to pass) prints nothing and fails here too.
assert_eq "cdpath: a poisoned CDPATH leaves two repos two, and leaves each of them itself" \
  "one two differ" \
  "$( a="$(id_cd "$CDROOT/poison" "$CDROOT/one")"; b="$(id_cd "$CDROOT/poison" "$CDROOT/two")"
      if [ "$a" != "$b" ]; then d=differ; else d="same:${a:-<empty>}"; fi
      printf '%s %s %s' "${a##*/}" "${b##*/}" "$d" )"

# The other half, and a different failure entirely: here the identity is not moved to another repo,
# it is DOUBLED — bash echoes what it found and the answer becomes two lines. One line is as much
# part of the contract as the right path, because the readers compare `repo` verbatim.
assert_eq "cdpath: CDPATH=. yields the repo on ONE line, not the path echoed by cd as well" \
  "one 1" \
  "$( id="$(id_cd . "$CDROOT/one")"; printf '%s %s' "${id##*/}" "$(grep -c . <<< "$id")" )"

# --- the same identity, asked of a git that predates --path-format ----------
# `ledger_repo_root` asks git for `--path-format=absolute`, born in git 2.31. An OLDER git does not
# refuse it: `rev-parse` echoes a token it does not recognize straight back to stdout and still
# exits 0, so it answers TWO lines — the flag, then the common dir, still relative. `|| return 0`
# cannot fire (rc is 0) and `-n` cannot fire (the string is not empty), so the whole two-line
# string used to become the repository IDENTITY, newline and all, in every row of an append-only
# ledger that is never migrated. Same shape as the CDPATH pair above and a strictly worse
# consequence, which is why it sits beside it: there the identity moved, here it is not a path.
GITSHIM="$CDROOT/oldgit"; mkdir -p "$GITSHIM"
{ printf '#!/usr/bin/env bash\n'
  printf 'is_rp=0; for a in "$@"; do [ "$a" = rev-parse ] && is_rp=1; done\n'
  printf 'if [ "$is_rp" = 1 ]; then\n'
  printf '  keep=(); echoed=()\n'
  printf '  for a in "$@"; do case "$a" in --path-format=*) echoed+=("$a");; *) keep+=("$a");; esac; done\n'
  printf '  if [ "${#echoed[@]}" -gt 0 ]; then\n'
  printf '    for e in "${echoed[@]}"; do printf "%%s\\n" "$e"; done\n'
  printf '    exec %s "${keep[@]}"\n' "$(command -v git)"
  printf '  fi\n'
  printf 'fi\n'
  printf 'exec %s "$@"\n' "$(command -v git)"
} > "$GITSHIM/git"
chmod +x "$GITSHIM/git"

# ⚠️ The floor, before any conclusion: a shim that failed to imitate the old git would make the
# assertion below pass over a modern git and say nothing. Two properties, because either one alone
# is satisfiable by a broken shim — it must ECHO the unknown flag (two lines, the first being the
# flag itself) and it must stay transparent for every other rev-parse.
assert_eq "the pre-2.31 git shim is armed: rev-parse echoes the flag it does not know, rc 0" \
  "2 --path-format=absolute ok" \
  "$( o="$( PATH="$GITSHIM:$PATH" git -C "$CDROOT/one" rev-parse --path-format=absolute --git-common-dir 2>&1 )"
      t="$( PATH="$GITSHIM:$PATH" git -C "$CDROOT/one" rev-parse --git-common-dir 2>/dev/null )"
      printf '%s %s %s' "$(grep -c . <<< "$o")" "$(head -1 <<< "$o")" \
        "$( [ "$t" = .git ] && echo ok || echo "opaque:$t" )" )"

# ⚠️ RAW, and never through the `no data for <repo>:` extractor `id_cd` uses. That extractor was
# the first spelling of this probe and it could not see the defect BY CONSTRUCTION: its `sed`
# needs `no data for X:` on ONE line, while the leak is two lines by definition — the echoed flag
# is always a whole line of its own, so the pattern never matched and the probe read the empty
# string in BOTH worlds, reporting `clean 0` whether the guard was there or not. Measured: with
# `mut_LEDGER_repo_root_shape_blind` applied — guard gone, `bash -n` clean — the whole of
# check-autonomy.sh stayed green. A sensor written to protect a CRITICAL, blind to that CRITICAL.
raw_oldgit() { ( cd "$1" && PATH="$GITSHIM:$PATH" SDD_STATE_DIR="$IDSTATE" "$SDD" autonomy 2>&1 ); }

# ⚠️ REFUSING the shape was only half the contract, and asserting the refusal alone is what let the
# second defect live: the r2 of 20260818-lote-facil made the old git yield NOTHING and this
# assertion called that a pass. Empty is the contract for "not a repo", so on git 2.25 and 2.30
# every ledger row would be written `repo: ""`, land in `no_repo` — a bucket `--all-repos` does not
# admit — and the whole judge would go dark, silently and permanently, on a spelling that used to
# work. The property is AGREEMENT, not silence: the answer is the real repo, the same string the
# modern git resolves, and never the echoed flag.
#
# Four fields, each answering an objection the other three cannot. `said` is the FLOOR — the old-git
# run must still produce the runner's per-repo voice, because "the flag does not appear" is free for
# a run that printed nothing or died. `leak` is the shape property, read RAW (see above: the `no
# data for X:` extractor cannot see a two-line answer BY CONSTRUCTION). `same` is the identity
# property, and it is DIFFERENTIAL — the two gits compared to each other, so no fixture regime
# satisfies it by accident and either side moving reproves it. Requiring `old` non-empty is what
# stops "resolved nothing" from buying the green a third time.
assert_eq "cdpath: a git older than --path-format resolves the SAME identity, never the echoed flag" \
  "one said clean same" \
  "$( new="$(id_cd '' "$CDROOT/one")"; raw="$(raw_oldgit "$CDROOT/one")"
      old="$(sed -n 's/.*no data for \([^:]*\):.*/\1/p' <<< "$raw")"
      case "$raw" in *"no data"*) s=said ;; *) s="mute:$(head -c 40 <<< "$raw")" ;; esac
      case "$raw" in *--path-format*) g=leaked ;; *) g=clean ;; esac
      if [ -n "$old" ] && [ "$old" = "$new" ]; then m=same
      else m="split:${old:-<empty>}|${new:-<empty>}"; fi
      printf '%s %s %s %s' "${new##*/}" "$s" "$g" "$m" )"

# --- ...and a row that cannot say where it came from is nobody's ------------
# `ledger_row_is_local` used to answer `true` for a row with no `repo` key — local in EVERY repo.
# The comment above it claimed the readers then classified those rows out loud, and for a bare
# array that is true (one dies naming the file). For a WELL-FORMED session row it was false:
# `is_unrecognized` looks at `.event`, never at `.repo`, so three sessions that named no project
# walked straight into the slice and cleared the judge's floor of 3 — a guard moved by rows nobody
# can attribute to anything, in silence. They now land in `excluded.no_repo`: counted, never summed
# into the slice, never dropped without a word.
#
# DIFFERENTIAL over TWO ledgers that differ in exactly one key: the same three clean sessions, on
# the same kit_sha, in the same three missions — with and without `repo`. Read once, nothing tells
# "excludes the unattributable" from "excludes everything": a blanket refusal answers `false` on
# both, the old behaviour answers `true` on both, and only the honest one splits them.
echo "== reader: a row that says no repo belongs to no repo =="
mkdir -p "$OUTSIDE/norepo" "$OUTSIDE/withrepo" "$OUTSIDE/norepomix"
norepo_row() {   # norepo_row <mission> — ledger_row's twin, minus the one key under test
  jq -cn --arg mission "$1" \
    '{v:1, ts:"2026-08-16T15:00:00-03:00", event:"session", run_id:"r", invocation:"run",
      kit_sha:"ccccccc", kit_dirty:false, project:"p", mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
      gate:"pass", gate_why:"x"}'
}
{ norepo_row n1;            norepo_row n2;            norepo_row n3; }            > "$OUTSIDE/norepo/autonomy-log.jsonl"
{ ledger_row "$FIXROOT" n1; ledger_row "$FIXROOT" n2; ledger_row "$FIXROOT" n3; } > "$OUTSIDE/withrepo/autonomy-log.jsonl"
# Interleaved with two local rows, so the human table has a slice to print beside the exclusion.
{ ledger_row "$FIXROOT" h1; norepo_row n1; ledger_row "$FIXROOT" h2
  norepo_row n2;            norepo_row n3; } > "$OUTSIDE/norepomix/autonomy-log.jsonl"

triple() { jq -r '[.excluded.no_repo, .excluded.other_repo, .guard.sufficient] | map(tostring) | join(" ")' <<< "$1"; }
ser_norepo="$(   SDD_STATE_DIR="$OUTSIDE/norepo"   "$SDD" kaizen --series 2>/dev/null )"
ser_withrepo="$( SDD_STATE_DIR="$OUTSIDE/withrepo" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "no-repo: three well-formed sessions that name no project are counted apart, and never reach the guard" \
  "3 0 false" "$(triple "$ser_norepo")"
# The control, and it is what makes the line above an assertion instead of a refusal: the same
# three rows WITH a repo do clear the floor. A bucket that swallowed everything fails here.
assert_eq "no-repo: and the same three rows WITH a repo still clear the floor — the bucket is not a blanket refusal" \
  "0 0 true" "$(triple "$ser_withrepo")"

# `--all-repos` has its OWN branch of the predicate, and the two-repo fixture further up holds no
# unattributable row — so without this line that branch could answer a plain `true` and nothing in
# the file would notice. The flag widens the question BETWEEN projects; a row that names none is
# out of every scope, so it stays counted and stays out. Sessions, not just the bucket: a flag that
# admitted the three would read 5 here, and the bucket alone cannot tell that apart.
ser_mix_all="$( SDD_STATE_DIR="$OUTSIDE/norepomix" "$SDD" kaizen --series --all-repos 2>/dev/null )"
assert_eq "the cross-project door widens the scope, it does not admit rows that belong to no scope" \
  "3 2" "$(jq -r '[.excluded.no_repo, .guard.sessions] | map(tostring) | join(" ")' <<< "$ser_mix_all")"

out_mix="$( SDD_STATE_DIR="$OUTSIDE/norepomix" "$SDD" autonomy 2>&1 )"
assert_eq "the human table names them out loud, never drops them in silence" "1" \
  "$(grep -c '3 row(s) excluded: no repo' <<< "$out_mix")"
assert_eq "and never files them under another repo — the two exclusions are different accusations" \
  "0" "$(foreign_of "$out_mix")"
assert_bucket_sum "the four buckets sum to the header total (unattributable rows beside local ones)" "$out_mix"

# The fourth silence. Without it the reader blames THIS repo ("none of the 3 row(s) were born
# here") for rows that were born in no repo at all — sending the human hunting for a path that
# does not exist, which is the same wrong hunt the other three silences are named apart to avoid.
out_only="$( SDD_STATE_DIR="$OUTSIDE/norepo" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a ledger of nothing but unattributable rows refuses, and says which silence it is" "1 1" \
  "$rc $(grep -c 'say which repo they came from' <<< "$out_only")"

# ...and the FIFTH state, which the four voices used to answer wrongly: a MIXED ledger with no local
# row at all — some rows born elsewhere, some naming no repo. The headline was true and the remedy
# was false for part of the file: `--all-repos` deliberately does not admit rows that belong to no
# project, so "run it over there / open the scope" is advice nobody can carry out for them.
#
# It is also the probe the third voice never had: its condition is `norepo -eq lines`, and relaxing
# it to `norepo -gt 0` was green in this whole file. Here it would print "none of the 3 row(s) say
# which repo they came from" over a file where one of them says exactly that — a falsehood about
# rows that HAVE a repo. So both halves are asserted: the right voice present and the wrong one
# ABSENT, which is what makes the pair distinguish the two branches instead of counting messages.
mkdir -p "$OUTSIDE/norepoforeign"
{ ledger_row "$OTHER" f1; norepo_row n1; norepo_row n2; } > "$OUTSIDE/norepoforeign/autonomy-log.jsonl"
out_mixnone="$( SDD_STATE_DIR="$OUTSIDE/norepoforeign" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a mixed ledger with nothing of yours refuses through the voice that fits it, not the one next door" \
  "1 1 0" \
  "$rc $(grep -c 'were born in this repo' <<< "$out_mixnone") $(grep -c 'say which repo they came from' <<< "$out_mixnone")"
# And the remedy is split, because it is two remedies: one reachable, one not. A single sentence
# here sent the human hunting for a cwd or a flag that can never surface two of the three rows.
assert_eq "and the advice separates what a cwd or a flag can reach from what nothing can" "1 1" \
  "$( printf '%s %s' "$(grep -c '1 row(s) came from other repos; 2 name no repo at all' <<< "$out_mixnone")" \
                     "$(grep -c 'neither reaches the 2 unattributable row(s)' <<< "$out_mixnone")" )"

# The three shapes of "this row names no project": key absent, key present and null, key present and
# empty. Only the first is one the writer can produce; the other two arrive by hand edit or partial
# write, which is the corruption the bucket exists to report. Under `has("repo") | not` they fell
# through to `.repo == $repo` and were accused of being `other_repo` — "born elsewhere", a wrong
# reason with the confidence of a right one. Asserted as ONE object so neither bucket can drift
# alone, exactly as the excluded assertion in check-kaizen.sh does.
mkdir -p "$OUTSIDE/norepshapes"
{ norepo_row n1
  jq -cn '{v:1, ts:"2026-08-16T15:00:00-03:00", event:"session", run_id:"r", invocation:"run",
           kit_sha:"ccccccc", kit_dirty:false, project:"p", repo:null, mission:"n2",
           phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
           auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
           gate:"pass", gate_why:"x"}'
  jq -cn '{v:1, ts:"2026-08-16T15:00:00-03:00", event:"session", run_id:"r", invocation:"run",
           kit_sha:"ccccccc", kit_dirty:false, project:"p", repo:"", mission:"n3",
           phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
           auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true,
           gate:"pass", gate_why:"x"}'
} > "$OUTSIDE/norepshapes/autonomy-log.jsonl"
ser_shapes="$( SDD_STATE_DIR="$OUTSIDE/norepshapes" "$SDD" kaizen --series 2>/dev/null )"
# ⚠️ NOT prefixed `no-repo` — the checkpoint Check for I5 counts `^  ok    no-repo` and demands
# exactly two, and these two clauses are new. Same rule as the scope-header assertion above.
assert_eq "unattributable shapes: absent, null and empty are one 'names no project', never three verdicts" \
  '{"non_comparable":0,"unrecognized":0,"meta":0,"other_repo":0,"no_repo":3}' \
  "$(jq -c '.excluded' <<< "$ser_shapes")"
# The one that mattered outside a git repo: there $repo is itself empty, so a `repo: ""` row
# compared EQUAL to it and was counted local in a repo that does not exist.
# ⚠️ PAIRED with the bucket, in ONE invocation, and that is the whole point: read alone, the `0` on
# the left is indistinguishable from a command that read nothing at all — a `kaizen --series` that
# died, printed no JSON and left jq with empty input answers `0` too, and the assertion would call
# that a passing rule. The `3` is the witness that the three rows were seen and placed; only then
# does the `0` mean "seen and refused" instead of "never looked".
assert_eq "unattributable shapes: and standing outside any repo, an empty repo field is still nobody's" "0 3" \
  "$( cd "$OUTSIDE" && SDD_STATE_DIR="$OUTSIDE/norepshapes" "$SDD" kaizen --series 2>/dev/null \
       | jq -r '"\(.guard.sessions) \(.excluded.no_repo)"' )"

# A row with no `event` at all, or an event nobody recognizes yet: the reviewer's exact repro. It
# must be counted, not merely fail to crash. It carries a `repo` ON PURPOSE, and that is the
# change: the repo filter runs FIRST, so a row that names no project is excluded as `no_repo`
# before anything looks at its event, and would never reach the bucket under test here.
echo "== reader: unrecognized row =="
mkdir -p "$OUTSIDE/stray"
printf '{"v":1,"ts":"2026-08-15T10:00:00-03:00","repo":"%s"}\n' "$FIXROOT" > "$OUTSIDE/stray/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/stray" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "exits 0 (an unrecognized row is not a malformed one)" "0" "$rc"
assert_eq "says there are no comparable sessions" "1" "$(grep -c 'no comparable sessions' <<< "$out")"
assert_eq "and says how many rows it could not classify" "1" \
  "$(grep -c '1 unrecognized' <<< "$out")"
assert_bucket_sum "the four buckets sum to the header total (one unrecognized row)" "$out"

# A row that is syntactically valid JSON but the wrong SHAPE (a bare array, not an object) cannot
# be classified either — indexing it is a jq runtime error, not a false comparison. Before the fix
# this leaked jq's own exit code (the reviewer saw rc 5); now it dies through the same rc-1
# convention as every other refusal in this command.
echo "== reader: valid JSON, wrong shape =="
mkdir -p "$OUTSIDE/shape"
printf '[1,2,3]\n' > "$OUTSIDE/shape/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/shape" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a shape error dies with rc 1, not jq's own exit code" "1" "$rc"
assert_eq "and the die message names the file" "1" \
  "$(grep -c "error:.*$OUTSIDE/shape/autonomy-log.jsonl" <<< "$out")"

# An empty ledger is NOT 0% waste. Zeros that look like excellence are the vacuity the whole kit
# exists to kill.
mkdir -p "$OUTSIDE/empty"
out="$( SDD_STATE_DIR="$OUTSIDE/empty" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "no ledger yet exits 1" "1" "$rc"
assert_eq "and says 'no data' instead of printing zeros" "1" "$(grep -c 'no data' <<< "$out")"
assert_eq "and never prints a percentage" "0" "$(grep -c '%' <<< "$out")"

# A malformed row dies loudly: skipping it in silence is how the judge ends up reading a subset
# and calling it the whole history.
mkdir -p "$OUTSIDE/bad"
printf '{"v":1,"event":"session"\n' > "$OUTSIDE/bad/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/bad" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a malformed row fails loudly" "1" "$rc"

# --- the human-facing output ------------------------------------------------
# Five defects that sat open through three missions, and they sat open for one reason: none of them
# moves a COUNT, so not one assertion above this line could go red on any of them. `sdd autonomy` is
# the human's window — a column that stops lining up, a refusal that names the wrong remedy and a
# table whose last row is not the latest version are defects of the same instrument as a wrong sum.
# Prefixed `output:` so the increment's Check can count them without reading them.
# =============================================================================
# writer: the real ledger is refused to a throwaway checkout (ADR 0005, part 3)
# =============================================================================
# Five of the seven repositories in the real ledger are fixtures, and every one of them sits under
# /tmp. All five came from MANUAL runs that forgot SDD_STATE_DIR, never from this suite — the
# isolation mechanism exists and works, and what leaked, leaked through discipline. This section
# measures the instrument that replaced the reminder.
#
# FOUR regimes, and they are two differential PAIRS rather than one refusal plus decoration:
#   A/B  the same repo under /tmp, one environment variable apart. Unset refuses, set writes.
#        Without B, "the runner refuses every ledger everywhere" satisfies A.
#   C/D  the same repo under /var/tmp, one environment variable apart. TMPDIR unset writes,
#        TMPDIR naming that root refuses. Without D the $TMPDIR arm of the heuristic has NO probe
#        at all — every path mktemp hands this suite lands under /tmp, so the two arms are
#        otherwise indistinguishable; without C nothing shows that a repo outside the temp roots
#        is still written, and "refuses temp checkouts" would be unseparable from "refuses".
#
# /var/tmp is the control root on purpose: it is a temp directory the heuristic deliberately does
# NOT know. The declared limit of ADR 0005 part 3, standing here as the control it makes possible.
#
# HOME is redirected in every regime: with SDD_STATE_DIR unset the writer targets $HOME/.sdd, and
# a probe that wrote into the developer's real ledger would BE the contamination it exists to
# forbid. The fake home is counted afterwards, and that count is the half proving the refusal
# happened before the write rather than after it.
echo "== writer: the real ledger is refused to a temp checkout =="

TMPGUARD="$OUTSIDE/tmpguard"
mkdir -p "$TMPGUARD/home"
# NOT under $OUTSIDE, which is where mktemp puts things and therefore under /tmp. This one has to
# live outside both temp roots the guard knows, or regimes C and D have nothing to stand on.
VARTMP="$(mktemp -d /var/tmp/sdd-tmpguard-XXXXXX)"
trap 'rm -rf "$FIX" "$OUTSIDE" "$VARTMP"' EXIT

# tmpguard_fixture <dir> — a repo whose only increment is `blocked`, so `sdd run` escalates with
# rc 3 BEFORE opening any session: the real writer is reachable without spending a token. Same
# shape as the fixture at the top of this file, built as a function because two roots need one
# each and a second hand-written copy is how two fixtures come to disagree.
tmpguard_fixture() {
  local d="$1"
  mkdir -p "$d" || return 1
  ( cd "$d" \
    && git init -q -b main \
    && git config user.email "fixture@example.com" \
    && git config user.name "Fixture" \
    && "$SDD" install >/dev/null ) || return 1
  cat > "$d/.sdd/config.sh" <<'CFG'
PROJECT_NAME="tmpguard"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
CFG
  mkdir -p "$d/docs/handoffs/$MISSION"
  cat > "$d/docs/handoffs/$MISSION/00-missao.md" <<'MSN'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
MSN
  : > "$d/docs/handoffs/$MISSION/01-plano.md"
  cat > "$d/docs/handoffs/$MISSION/checkpoint.md" <<'CKP'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | blocked | — |
CKP
  ( cd "$d" && git add -A && git commit -qm "chore: fixture mission" >/dev/null ) || return 1
}

# tmpguard_run <dir> <state-dir-or-empty> <tmpdir-or-empty> -> "<rc> <refused|silent> <rows>"
#
# `env -u` FIRST and then the conditional re-set, because run-all.sh exports SDD_STATE_DIR for
# everything it runs: without the -u every regime here would silently be regime B, and the four
# would agree with each other for a reason that has nothing to do with the guard.
# The array and not `${var:+VAR=value}`: the conditional expansion carries quotes that are not
# quotes, and a path with a space in it would split into two arguments.
tmpguard_run() {
  local d="$1" state="$2" tmp="$3" out rc home rows=0
  home="$TMPGUARD/home"
  rm -rf "$home"; mkdir -p "$home"
  local -a envv=( env -u SDD_STATE_DIR -u TMPDIR "HOME=$home" )
  if [ -n "$state" ]; then rm -rf "$state"; mkdir -p "$state"; envv+=( "SDD_STATE_DIR=$state" ); fi
  if [ -n "$tmp" ]; then envv+=( "TMPDIR=$tmp" ); fi
  out="$( cd "$d" && "${envv[@]}" "$SDD" run "$MISSION" 2>&1 )"; rc=$?
  # `grep -c` answers 1 when it counts zero, so the capture carries `|| true` — under this file's
  # pipefail an unguarded one would hand the caller an empty string instead of a number.
  [ -f "$home/.sdd/autonomy-log.jsonl" ] \
    && rows="$(grep -c . "$home/.sdd/autonomy-log.jsonl" || true)"
  printf '%s %s %s' "$rc" \
    "$(grep -q 'SDD_STATE_DIR' <<< "$out" && echo refused || echo silent)" \
    "${rows:-0}"
}

tmpguard_fixture "$TMPGUARD/under-tmp" \
  || fail "PROBE-BROKEN: the /tmp fixture did not build" "built" "failed"
tmpguard_fixture "$VARTMP/repo" \
  || fail "PROBE-BROKEN: the /var/tmp fixture did not build" "built" "failed"

# A — under /tmp with no SDD_STATE_DIR: refused, loudly, and nothing reached the real ledger path.
assert_eq "writer: a repo under the temp dir may not write the real ledger" \
  "1 refused 0" "$(tmpguard_run "$TMPGUARD/under-tmp" "" "")"
# B — the control, one environment variable apart. rc 3 is the fixture's own escalation: asserting
# the PRE-GUARD rc is what makes "the guard did not fire" a value instead of an absence.
assert_eq "writer: ...and with SDD_STATE_DIR set the same repo writes its row" \
  "3 silent 0" "$(tmpguard_run "$TMPGUARD/under-tmp" "$TMPGUARD/state" "")"
# C — outside both temp roots the real ledger is written: the guard refuses throwaway checkouts,
# not repositories. /var/tmp is a temp directory the heuristic deliberately does not know.
assert_eq "writer: a repo outside the temp roots still writes the real ledger" \
  "3 silent 1" "$(tmpguard_run "$VARTMP/repo" "" "")"
# D — the same repo, refused the moment $TMPDIR names its root. The only probe of that arm.
assert_eq "writer: ...and refused as soon as TMPDIR names that root" \
  "1 refused 0" "$(tmpguard_run "$VARTMP/repo" "" "/var/tmp")"

# =============================================================================
# the phase ceiling counts SESSIONS, not laps of the loop
# =============================================================================
# `attempts` rises once per lap, before the first run_phase of that lap, and the retry INSIDE the
# lap opens a second session without touching it. So a budget of N bought up to 2N sessions, and
# QA's `QA_MAX_ITER * 3` = 9 was a ceiling of 18. Measured on 20260825-frete-cif-fob: the ceiling
# WORKED — 9 laps, exactly the limit — and 3 of those laps bought a retry, turning 9 sessions into
# 12 at US$ 11.27. Every budget in phase_budget is already written in sessions ("3 sub-steps per
# round"), so counting them makes the unit match the arithmetic rather than lowering a limit.
#
# `sessions` is the counter cmd_run already kept at BOTH session sites and the blocked headline
# already read; `attempts` keeps the ledger's `attempt` field, so no row shape moves.
#
# THE WITNESS COMES FIRST, and it is not decoration: on a fixture where every lap costs one session
# laps and sessions are the SAME number, and the count below is satisfied by the defect it exists
# to forbid. The alternating stub is what puts the fixture in the regime that separates them —
# odd sessions change nothing (so the runner retries inside the lap), even sessions commit (so the
# lap ends "carrying on" instead of escalating no-progress).
echo "== the phase ceiling counts sessions, not laps =="

CEIL="$OUTSIDE/ceiling"
CEILSTATE="$OUTSIDE/ceilstate"
mkdir -p "$CEIL/stub" "$CEILSTATE"
CEILLEDGER="$CEILSTATE/autonomy-log.jsonl"
tmpguard_fixture "$CEIL/repo" \
  || fail "PROBE-BROKEN: the ceiling fixture did not build" "built" "failed"
# `pending`, not `blocked`: the Jidoka of a blocked increment escalates before any session and this
# section is about the sessions. EXEC_MAX_RETRY is pinned so the budget below is derivable by hand
# instead of by whatever the default happens to be: rows + EXEC_MAX_RETRY + 2 = 1 + 1 + 2 = 4.
sed -i 's/| blocked | — |/| pending | — |/' "$CEIL/repo/docs/handoffs/$MISSION/checkpoint.md"
printf 'EXEC_MAX_RETRY=1\n' >> "$CEIL/repo/.sdd/config.sh"
( cd "$CEIL/repo" && git add -A && git commit -qm "chore: a pending increment" ) >/dev/null 2>&1

rm -f "$CEIL/n"
cat > "$CEIL/stub/claude" <<STUB
#!/usr/bin/env bash
n=\$(( \$(cat "$CEIL/n" 2>/dev/null || echo 0) + 1 ))
echo "\$n" > "$CEIL/n"
if [ \$(( n % 2 )) -eq 1 ]; then exit 9; fi
: > "$CEIL/repo/docs/handoffs/$MISSION/note-\$n.md"
git -C "$CEIL/repo" add -A >/dev/null 2>&1
git -C "$CEIL/repo" commit -qm "chore: session \$n moved the disk" >/dev/null 2>&1
cat "$STREAM_SAMPLE"
exit 0
STUB
chmod +x "$CEIL/stub/claude"

( cd "$CEIL/repo" && PATH="$CEIL/stub:$PATH" SDD_STATE_DIR="$CEILSTATE" \
    "$SDD" run "$MISSION" >/dev/null 2>&1 )
ceil_sessions="$(jq -rs '[.[] | select(.event == "session")] | length' "$CEILLEDGER" 2>/dev/null)"
ceil_retries="$(jq -rs '[.[] | select(.event == "session" and .auto_retry == true)] | length' "$CEILLEDGER" 2>/dev/null)"
ceil_laps="$(jq -rs '[.[] | select(.event == "session") | .attempt] | max // 0' "$CEILLEDGER" 2>/dev/null)"

assert_eq "witness: the fixture really does buy a retry inside a lap" "yes" \
  "$( [ "${ceil_retries:-0}" -ge 1 ] && echo yes || echo "no:${ceil_retries:-<none>}" )"
# EXEC's budget here is 4 SESSIONS. Two laps of two sessions each spend them, and the third lap is
# refused before it opens anything: 4 rows, then `budget-exhausted`. Counting LAPS the same fixture
# runs five laps and buys EIGHT sessions before the same escalation — double the bill for the same
# refusal, which is exactly what happened in QA.
# The escalation KIND is part of the same string on purpose: 4 sessions followed by `no-progress`
# would be a different run altogether (the alternating stub having stopped alternating), and a
# count asserted alone would call it green.
assert_eq "the ceiling stops the phase by sessions spent, not by laps of the loop" \
  "4 budget-exhausted" \
  "$(printf '%s %s' "${ceil_sessions:-0}" \
       "$(jq -rs '[.[] | select(.event == "blocked")] | last | .kind // "none"' "$CEILLEDGER" 2>/dev/null)")"
# The differential that makes the number mean something: on THIS fixture laps really are fewer than
# sessions, so "4" was not reached by the two being the same quantity under another name.
assert_eq "...and on this fixture the two units really do disagree" "fewer" \
  "$( if [ "${ceil_laps:-0}" -lt "${ceil_sessions:-0}" ]; then echo fewer
      else echo "same:${ceil_laps:-0}/${ceil_sessions:-0}"; fi )"

echo "== reader: the human-facing output =="

# One clean comparable session, with the three fields these assertions vary. Same shape as
# `ledger_row` above; a second helper rather than a fourth parameter on that one, because that one
# is the fixture of the repo-filter section and its callers pin its arity.
out_row() {   # out_row <kit_sha> <mission> <cost_usd>
  jq -cn --arg repo "$FIXROOT" --arg sha "$1" --arg mission "$2" --argjson cost "$3" \
    '{v:1, ts:"2026-08-16T14:00:00-03:00", event:"session", run_id:"r", invocation:"run",
      kit_sha:$sha, kit_dirty:false, project:"p", repo:$repo, mission:$mission,
      phase:"EXEC", step:"EXEC", agent:"sdd-executor", model:"opus", attempt:1,
      auto_retry:false, session:"s", rc:0, dur_s:10, cost_usd:$cost, moved:true,
      gate:"pass", gate_why:"x"}'
}
# The ledger path is part of every refusal message on purpose, and the two fixtures below live in
# different directories — so a differential assertion that compared the messages raw would find them
# "different" for a reason that has nothing to do with what they accuse, and would go on passing
# after both were rewritten into one sentence. Normalised out, once, for both.
norm_ledger() { sed -e "s|$OUTSIDE/[A-Za-z0-9]*/autonomy-log\.jsonl|<LEDGER>|g" <<< "$1"; }

# D1 — money is a COLUMN. jq interpolates NUMBERS, not formatted strings, so a total of 2.0 printed
# `US$ 2` in a column next to `US$ 1.5`: the table stops lining up and a reader in a hurry reads "no
# cents were computed". Both shapes in one ledger (a whole number and a one-place number) and the
# TOTAL of money columns asserted alongside, so a formatter that fixes only the integer case fails,
# and so does an output that lost the column altogether.
mkdir -p "$OUTSIDE/money"
{ out_row zzzzzzz m1 2.0; out_row aaaaaaa m2 1.5; } > "$OUTSIDE/money/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/money" "$SDD" autonomy 2>&1 )"
assert_eq "output: every money column carries two decimals, and there are two of them" "2 2" \
  "$(grep -c 'US\$ ' <<< "$out") $(grep -cE 'US\$ [0-9]+\.[0-9][0-9]$' <<< "$out")"

# D2 — two defects, one sentence. `[1,2,3]` is valid JSON of the wrong SHAPE (a writer produced a
# non-object: somebody has to find the writer); a truncated line is not JSON at all (somebody has to
# fix the line). The remedies are different and the reader could not tell which had happened.
# DIFFERENTIAL, because an assertion that only looked for the text of one of them stays green after
# the other is rewritten to say the same thing again — which is how these two got here.
die_line() { grep -m1 'error:' <<< "$(norm_ledger "$1")"; }
bad_msg="$(die_line "$( SDD_STATE_DIR="$OUTSIDE/bad" "$SDD" autonomy 2>&1 )")"
shape_msg="$(die_line "$( SDD_STATE_DIR="$OUTSIDE/shape" "$SDD" autonomy 2>&1 )")"
assert_eq "output: the two malformed-ledger refusals accuse different things" \
  "spoke spoke different" \
  "$(printf '%s %s %s' "${bad_msg:+spoke}" "${shape_msg:+spoke}" \
       "$( [ "$bad_msg" = "$shape_msg" ] && echo same || echo different )")"

# D3 — the "no data" block was written twice, word for word: once for a file that is not there and
# once for a file that holds no row. Both guards are necessary and they test different things, but
# they are ONE refusal, and two copies is how one of them gets rewritten alone — leaving two voices
# for the very sentence that separates "empty ledger" from "corrupt ledger". Asserted at BOTH ends,
# in one assertion: the sentence exists once in the source (which is the debt), and the two guards
# still reach it (which is what makes one copy a refactor instead of a deletion). The `1` on the
# left is also the floor — a source that lost the sentence counts 0, and two silent guards would
# otherwise compare equal.
mkdir -p "$OUTSIDE/blanklines"
printf '\n\n\n' > "$OUTSIDE/blanklines/autonomy-log.jsonl"
out_nofile="$( SDD_STATE_DIR="$OUTSIDE/empty" "$SDD" autonomy 2>&1 )"
out_norows="$( SDD_STATE_DIR="$OUTSIDE/blanklines" "$SDD" autonomy 2>&1 )"
assert_eq "output: the two empty-ledger refusals are one sentence, written once" \
  "1 $(norm_ledger "$out_nofile")" \
  "$(grep -cF 'no data: the ledger at ' "$SDD") $(norm_ledger "$out_norows")"

# D4 — `group_by(.kit_sha)` sorts by KEY, so "the last line of the table" was the lexically-largest
# version and not the most recent one. `kaizen_series` has always ordered by first appearance in the
# file (`shas_in_file_order`), so the human's window and the judge's series disagreed about which
# version is latest — over the same file, with nothing on screen explaining it, in the table a human
# reads to decide whether the kit got better. DIFFERENTIAL against the judge, over a ledger whose
# file order is the REVERSE of its sort order: no single ordering satisfies both readings by chance.
mkdir -p "$OUTSIDE/vorder"
{ out_row zzzzzzz m1 1.0; out_row aaaaaaa m2 1.0; } > "$OUTSIDE/vorder/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/vorder" "$SDD" autonomy 2>&1 )"
vseries="$( SDD_STATE_DIR="$OUTSIDE/vorder" "$SDD" kaizen --series 2>/dev/null )"
# awk and not `grep | tail`: $3 is "session(s)" on the table lines and a count on the escalation
# lines, so one field test keeps them apart with no pipe to trip over pipefail. An output with no
# table at all leaves `sha` empty, which fails against the judge's answer instead of matching it.
assert_eq "output: the table's last version is the judge's latest, not the lexically largest" \
  "aaaaaaa aaaaaaa" \
  "$(jq -r '.latest.kit_sha' <<< "$vseries") $(awk '$3 == "session(s)" { sha = $1 } END { print sha }' <<< "$out")"

# D4b — the SAME question, over the one file order where reading it off the wrong POPULATION still
# splits the two answers. D4 above is satisfied by any first-appearance order, because its ledger
# holds nothing but comparable sessions; the judge, though, reads first appearance off the rows it
# admits through `comparable_row` — comparable sessions and on_axis escalations — never every
# on_axis row. So a version whose first admitted row is an escalation is already known to the
# series while the table has never heard of it — and a table that ordered by its OWN population put
# that version last while the judge called another one latest. Found in the r1 review by
# reproduction, not by reading: rows blocked(aaaaaaa), session(bbbbbbb), session(aaaaaaa) answered
# `aaaaaaa` here and `bbbbbbb` there over one file. Written DIFFERENTIAL for the same reason D4 is,
# and the escalation goes FIRST because that is the only placement in which the two populations
# disagree at all.
esc_row() {   # esc_row <kit_sha> <mission> — same shape autonomy_escalation_row writes
  jq -cn --arg repo "$FIXROOT" --arg sha "$1" --arg mission "$2" \
    '{v:1, ts:"2026-08-16T13:00:00-03:00", event:"blocked", kind:"increment-blocked",
      run_id:"r", invocation:"run", kit_sha:$sha, kit_dirty:false, project:"p", repo:$repo,
      mission:$mission, phase:"EXEC", gate_why:"x"}'
}
mkdir -p "$OUTSIDE/vorder2"
{ esc_row aaaaaaa m0; out_row bbbbbbb m1 1.0; out_row aaaaaaa m2 1.0
} > "$OUTSIDE/vorder2/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/vorder2" "$SDD" autonomy 2>&1 )"
vseries2="$( SDD_STATE_DIR="$OUTSIDE/vorder2" "$SDD" kaizen --series 2>/dev/null )"
# The FLOOR travels with the claim: two table rows, or a reader that lost half its table would
# agree with the judge by having nothing left to disagree with.
assert_eq "output: the table orders versions off the judge's population, escalations included" \
  "bbbbbbb bbbbbbb 2" \
  "$(jq -r '.latest.kit_sha' <<< "$vseries2") $(awk '$3 == "session(s)" { sha = $1 } END { print sha }' <<< "$out") $(grep -cE '^  [a-z]{7}  [0-9]+ session\(s\)' <<< "$out")"

# D4c — the placement D4b cannot reach: a SESSION missing `moved` (old schema), never an
# escalation. D4b's only non-session row is an escalation, and BOTH readers admit an escalation
# through the same `on_axis` test, so D4b cannot see a divergence there. The only placement where
# the two populations disagree is a session missing `moved` FIRST: `on_axis` alone admits it
# (kit_dirty:false, kit_sha set) while `comparable_row` in the judge does not, because a session
# additionally needs `has("moved")`. Reproduced on session(aaaaaaa, no moved) ·
# session(bbbbbbb) · session(aaaaaaa): the last row of the table read bbbbbbb while the judge's
# `.latest.kit_sha` read aaaaaaa, over the same file.
mkdir -p "$OUTSIDE/vorder3"
localize > "$OUTSIDE/vorder3/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-16T14:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"gate":"fail","gate_why":"old schema, no moved"}
{"v":1,"ts":"2026-08-16T14:01:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"bbbbbbb","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m2","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-16T14:02:00-03:00","event":"session","run_id":"r3","invocation":"run","kit_sha":"aaaaaaa","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s3","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
out="$( SDD_STATE_DIR="$OUTSIDE/vorder3" "$SDD" autonomy 2>&1 )"
vseries3="$( SDD_STATE_DIR="$OUTSIDE/vorder3" "$SDD" kaizen --series 2>/dev/null )"
assert_eq "output: a session missing moved cannot lead the table's order, only the judge's population does" \
  "aaaaaaa aaaaaaa" \
  "$(jq -r '.latest.kit_sha' <<< "$vseries3") $(awk '$3 == "session(s)" { sha = $1 } END { print sha }' <<< "$out")"

# D5 — with no escalations and one unrecognized row, two blank lines opened between the table and
# the exclusion line. Each exclusion string already begins with `\n` AND jq's `,` puts every output
# on its own line, so an exclusion that prints "" for a count of zero contributes a blank line of
# its own. Cosmetic and confirmed by reproduction: no count moves. The exclusion line is the floor —
# an output that dropped its accounting has no double blank either, and would pass on nothing.
mkdir -p "$OUTSIDE/gap"
{ out_row aaaaaaa m1 1.0
  jq -cn --arg repo "$FIXROOT" '{v:1, ts:"2026-08-16T14:00:00-03:00", repo:$repo}'
} > "$OUTSIDE/gap/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/gap" "$SDD" autonomy 2>&1 )"
gap_blanks="$(awk 'prev == "" && $0 == "" { n++ } { prev = $0 } END { print n + 0 }' <<< "$out")"
gap_excl="$(grep -c '1 unrecognized row(s) excluded' <<< "$out")"
assert_eq "output: never two blank lines in a row, and the accounting still prints" "0 1" \
  "$gap_blanks $gap_excl"

# D7 — the SAME family as D5, and the half it left behind. Each of the four exclusion strings opens
# with `\n` AND the jq comma puts every output on its own line, so with more than one bucket filled
# the accounting came out block+blank+block+blank+block: four unrelated remarks where there is one
# paragraph. D5 cannot see it — it counts CONSECUTIVE blanks, and this defect never makes two in a
# row. All four buckets are filled at once, so a fix that groups only some of them fails here.
#
# Three numbers, and none of them is redundant: the four lines are the anti-vacuity floor (an
# output that lost its accounting has no internal blank either, and would pass on nothing), the
# zero is the defect, and the blank ABOVE the first line is what still separates the block from the
# table — a fix that deleted every newline would satisfy the middle number and glue the accounting
# onto the last row of the table.
mkdir -p "$OUTSIDE/excl"
{ out_row aaaaaaa m1 1.0
  # non-comparable: on this repo, but the kit was dirty when the row was born
  jq -cn --arg repo "$FIXROOT" \
    '{v:1, ts:"2026-08-16T14:00:00-03:00", event:"session", kit_sha:"aaaaaaa", kit_dirty:true,
      repo:$repo, mission:"m2", phase:"EXEC", moved:true}'
  # unrecognized: no event field at all (counted after the repo filter, so it names this repo)
  jq -cn --arg repo "$FIXROOT" '{v:1, ts:"2026-08-16T14:00:00-03:00", repo:$repo}'
  # born in another repo, and says no repo at all — the two exclusions bound before the filter
  jq -cn '{v:1, ts:"2026-08-16T14:00:00-03:00", event:"session", kit_sha:"aaaaaaa",
      kit_dirty:false, repo:"/somewhere/else", mission:"m3", phase:"EXEC", moved:true}'
  jq -cn '{v:1, ts:"2026-08-16T14:00:00-03:00", event:"session", kit_sha:"aaaaaaa",
      kit_dirty:false, mission:"m4", phase:"EXEC", moved:true}'
} > "$OUTSIDE/excl/autonomy-log.jsonl"
out="$( SDD_STATE_DIR="$OUTSIDE/excl" "$SDD" autonomy 2>&1 )"
excl_inner="$(awk '/row\(s\) excluded/ { if (started) n += blank; started = 1; blank = 0; next }
                   started && $0 == "" { blank++ }
                   END { print n + 0 }' <<< "$out")"
excl_above="$(awk 'prev == "" && /row\(s\) excluded/ && !seen { seen = 1; n = 1 }
                   { prev = $0 } END { print n + 0 }' <<< "$out")"
assert_eq "output: the exclusion accounting is one paragraph, not one remark per bucket" "4 0 1" \
  "$(grep -c 'row(s) excluded' <<< "$out") $excl_inner $excl_above"

# D8 — the axis note kept a SECOND copy of the guard floor. Its own comment reads "no count in the
# sentence on purpose ... writing 3 here would be a third copy of a number the jq program already
# owns", and the `dim` two lines below it printed "The floor of 3 missions per kit version". Of the
# floor's several voices this is the ONLY one a human reads out loud, and it was the one that would
# drift in silence the day the floor moved.
#
# The note prints from `sdd kaizen` alone, which refuses to run anywhere but the KIT repo (SDD_HOME
# has to BE the repo root), so this is the one assertion in this file that needs a kit-SHAPED
# fixture — the $KIT copy above deliberately has no .git and is a target repo. `--dry-run` is
# enough: the note prints before the gate and before anything that could spend a session.
echo "== reader: the guard floor has one owner and one voice =="
KITREPO="$OUTSIDE/kitrepo"
mkdir -p "$KITREPO"
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$KITREPO/"
git -C "$KITREPO" init -q -b main
git -C "$KITREPO" config user.email "fixture@example.com"
git -C "$KITREPO" config user.name "Fixture"
( cd "$KITREPO" && "$KITREPO/bin/sdd" install >/dev/null 2>&1 )
mkdir -p "$KITREPO/.sdd"
cat > "$KITREPO/.sdd/config.sh" <<'EOF'
PROJECT_NAME="kitfix"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF
git -C "$KITREPO" add -A >/dev/null && git -C "$KITREPO" commit -qm "init kit fixture" >/dev/null
KITROOT="$(git -C "$KITREPO" rev-parse --show-toplevel)"
# Three consecutive phases of one mission, each landing on its own kit_sha because the phase before
# it committed: the gemba of the repo that BUILDS the kit, where no number of missions ever reaches
# the floor. Same shape as check-kaizen.sh's degenerate-axis fixture, pointed at this repo.
mkdir -p "$OUTSIDE/degenaxis"
axis_row() {   # axis_row <kit_sha> <phase>
  jq -cn --arg repo "$KITROOT" --arg sha "$1" --arg phase "$2" \
    '{v:1, ts:"2026-08-16T14:00:00-03:00", event:"session", run_id:"k", invocation:"run",
      kit_sha:$sha, kit_dirty:false, project:"kitfix", repo:$repo, mission:"m20",
      phase:$phase, step:$phase, agent:"a", model:"opus", attempt:1, auto_retry:false,
      session:"s", rc:0, dur_s:10, cost_usd:1.0, moved:true, gate:"pass", gate_why:"x"}'
}
{ axis_row a000001 EXEC; axis_row a000002 DOCS; axis_row a000003 PR
} > "$OUTSIDE/degenaxis/autonomy-log.jsonl"
axis_out="$(    cd "$KITREPO" && SDD_STATE_DIR="$OUTSIDE/degenaxis" "$KITREPO/bin/sdd" kaizen --dry-run 2>&1 )"
axis_series="$( cd "$KITREPO" && SDD_STATE_DIR="$OUTSIDE/degenaxis" "$KITREPO/bin/sdd" kaizen --series 2>/dev/null )"
# Four terms, three of them floors. `degenerate_axis: true` proves the note was reachable at all
# (it returns early on every other series, so a fixture that stopped degenerating would leave the
# number empty and read as a fix); the series field is the owner; the printed number is the voice;
# and the source count is what makes the two the SAME number — with a literal written back into the
# sentence the first three still agree, and only the fourth goes red.
#
# That fourth term reads the PRINTING lines of `kaizen_axis_note` and nothing else. A plain grep
# over the file counts the prose too: the comment above the sentence quotes the defect it is about,
# so the first spelling of this assertion failed on its own documentation while the code was
# already right — a source rule that cannot tell code from a comment about the code.
#
# It is written `<literals>/<lines read>` and not as a bare count, because a bare count FAILS OPEN:
# rename the function, move the sentence into a helper, and the awk range matches nothing, `n`
# stays 0 and the assertion goes on reporting "no literal" about a body it never opened. The
# denominator is the floor — 0 lines read fails instead of passing on nothing.
axis_literal="$(awk '/^kaizen_axis_note\(\) \{/ { inf = 1; next }
                     inf && /^\}/ { inf = 0 }
                     inf && /^ *(dim|warn) / { lines++; if ($0 ~ /[0-9]+ missions/) n++ }
                     END { printf "%d/%d", n + 0, lines + 0 }' "$SDD")"
assert_eq "output: the axis note quotes the guard floor instead of keeping a copy of its own" \
  "true 3 3 0/4" \
  "$(jq -r '.guard.degenerate_axis' <<< "$axis_series") $(jq -r '.guard.floor' <<< "$axis_series") $(num_before "$axis_out" 'missions per kit version') $axis_literal"

# --- a target-repo session that edits the KIT ------------------------------
# Measured on 2026-08-25: an EXEC session whose mission was another repo entirely committed a kit
# finding straight into this kit's `main` (2d28d13). The kit's own suite went red, and the ledger
# rows of that very run stamped the sha of the commit the run had just made — the instrument
# recording a kit version that only existed because the run created it.
#
# The world here is a FAKE KIT: a `cp -r` (never a symlink — `_resolve_self` resolves symlinks and
# would land back on the real kit) of the four directories `sdd` reads from. Invoking
# `$OUTSIDE/fakekit/bin/sdd` makes SDD_HOME the fake, which is what makes "the kit changed under
# the run" a thing a test may cause. It also keeps the mutation catalogue honest: inside a mutant
# the sandbox is what gets copied here, so the sabotage travels into the fake kit too.
#
# EVERY regime carries a floor proving its sessions ran, the two that expect SILENCE included. That
# is not symmetry for its own sake: a regime whose whole expectation is `lines:0 warns:0` is green
# in the world where `kitguard_world` quietly failed and no run happened at all — measured, by
# deleting the control world and its run and watching the assertion still say ok. `kitguard_world`
# silences its own subshell, so nothing else would have said a word.
# --- the hat's boundary: what the session SAW is read off the init line into the ledger ------
# Three fields on every session row — mcp_seen, tools_leaked, denials — read from the stream's
# `init` line and the result's `permission_denials`. A server the hat did not declare, or a denied
# tool still listed, is the same hat-crossed stop with its own reason. A stream with no init line
# (a session dead before it) records null: unmeasured is not zero.
echo "== hat boundary: what the session saw is read off the init line =="
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<STUB
cat "$INIT_CLEAN"
exit 0
STUB
chmod +x "$OUTSIDE/stub/claude"
"$SDD" run "$MISSION" >/dev/null 2>&1 || true
assert_eq "init: a clean session records 0 MCP seen, 0 tools leaked, 0 denials" "0 0 0" \
  "$(jq -r -s '.[0] | "\(.mcp_seen) \(.tools_leaked) \(.denials)"' "$LEDGER")"
assert_eq "init: nothing crossed" "0" "$(jq -r -s '[.[] | select(.kind == "hat-crossed")] | length' "$LEDGER")"
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<STUB
cat "$INIT_LEAK"
exit 0
STUB
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "init: an MCP server the hat did not declare, and a denied tool still visible, stop the line" \
  "3 1 1 hat-crossed" \
  "$rc $(jq -r -s '.[0] | "\(.mcp_seen) \(.tools_leaked)"' "$LEDGER") $(jq -r -s '[.[] | select(.event=="blocked") | .kind] | join(",")' "$LEDGER")"
assert_eq "init: the reason names what leaked" "1" "$(grep -c 'atlassian' <<< "$(jq -r -s '.[1].gate_why' "$LEDGER")")"
: > "$LEDGER"
cat > "$OUTSIDE/stub/claude" <<STUB
cat "$STREAM_SAMPLE"
exit 0
STUB
"$SDD" run "$MISSION" >/dev/null 2>&1 || true
assert_eq "init: a stream without an init line (a session dead before it) records null, not 0" "null null null" \
  "$(jq -r -s '.[0] | "\(.mcp_seen) \(.tools_leaked) \(.denials)"' "$LEDGER")"
cat > "$OUTSIDE/stub/claude" <<'STUB'
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$OUTSIDE/stub/claude"

# --- the hat's boundary: a session that writes outside its writes: stops the line ------------
# The reviewer of SQ-115 wrote a scratch test into the code tree three times and the runner only
# warned (REVIEW-EDITED-CODE). Since the 2026-09-03 spec the runner reads the hat's `writes:` and
# a path outside it — committed OR left dirty — arms HAT_CROSSED_WHY, which the one door
# (hat_crossed_escalation) turns into rc 3 and a `hat-crossed` ledger row AFTER the session row.
# `--phase REVIEW` forces the phase: the fixture is stalled at EXEC and the reviewer is the hat
# whose writes: is narrow (the executor writes anywhere).
echo "== hat boundary: the reviewer that edits code stops the line =="
: > "$LEDGER"
HAT_PLOG="$FIX/.sdd/logs/$MISSION/pipeline.log"
hat_stub() {   # hat_stub <path the session writes, relative to the repo> <commit|leave> [fire on]
  local fire="${3:-1}"
  cat > "$OUTSIDE/stub/claude" <<STUB
n=\$(( \$(cat "$OUTSIDE/hat-count" 2>/dev/null || echo 0) + 1 ))
printf '%s\n' "\$n" > "$OUTSIDE/hat-count"
if [ "\$n" -eq $fire ]; then
  mkdir -p "\$(dirname "$1")"
  printf 'probe\n' > "$1"
  if [ "$2" = commit ]; then git add -A; git commit -qm "chore: the session wrote $1"; fi
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
  chmod +x "$OUTSIDE/stub/claude"
}
hat_rows() { jq -r -s '[.[] | select(.event == "blocked") | .kind] | join(",")' "$LEDGER" 2>/dev/null; }
hat_reset() { rm -f "$OUTSIDE/hat-count"; : > "$LEDGER"; : > "$HAT_PLOG" 2>/dev/null || true; }
hat_reset
hat_stub "src/zz-scratch-probe.test.ts" commit
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: a REVIEW session that commits a code file stops the line with rc 3" "3" "$rc"
assert_eq "hat: the escalation row is hat-crossed and comes after the session row" "session,blocked hat-crossed" \
  "$(jq -r -s '[.[0].event, .[1].event] | join(",")' "$LEDGER") $(hat_rows)"
assert_eq "hat: the pipeline log names the file" "1" \
  "$(grep -c 'HAT-CROSSED  REVIEW .*src/zz-scratch-probe.test.ts' "$HAT_PLOG")"
assert_eq "hat: one session, not two — the door is read before the inline retry" "1" "$(cat "$OUTSIDE/hat-count" 2>/dev/null || echo 0)"
git -C "$FIX" reset -q --hard HEAD~1; git -C "$FIX" clean -qfd

hat_reset
hat_stub "src/zz-scratch-probe.test.ts" leave
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: a file LEFT in the tree outside writes: is a crossing too" "3 hat-crossed" "$rc $(hat_rows)"
git -C "$FIX" clean -qfd; git -C "$FIX" checkout -q -- .

hat_reset
hat_stub "docs/handoffs/$MISSION/40-review-r1.md" commit
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: a review that writes only its own artifact is not accused" "0" "$(grep -c 'hat-crossed' <<< "$(hat_rows)")"
assert_eq "hat: …and the pipeline log carries no HAT-CROSSED" "0" "$(grep -c HAT-CROSSED "$HAT_PLOG")"
git -C "$FIX" reset -q --hard HEAD~1 2>/dev/null || true; git -C "$FIX" clean -qfd

hat_reset
hat_stub "src/zz-scratch-probe.test.ts" commit 2
"$SDD" run "$MISSION" --phase REVIEW >/dev/null 2>&1; rc=$?
assert_eq "hat: door 2 — the inline retry's crossing is caught by the retry's own read" "3 2 session,session,blocked" \
  "$rc $(cat "$OUTSIDE/hat-count" 2>/dev/null || echo 0) $(jq -r -s '[.[].event] | join(",")' "$LEDGER")"
git -C "$FIX" reset -q --hard HEAD~1; git -C "$FIX" clean -qfd
hat_reset
cat > "$OUTSIDE/stub/claude" <<'STUB'
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$OUTSIDE/stub/claude"

echo "== reader: a target-repo session that edits the kit =="
FAKEKIT="$OUTSIDE/fakekit"
mkdir -p "$FAKEKIT"
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$ROOT/agents" "$FAKEKIT/"
( cd "$FAKEKIT" && git init -q -b main && git config user.email "fixture@example.com" \
    && git config user.name "Fixture" && git add -A && git commit -qm "chore: the kit" ) >/dev/null

# The same four directories with NO `git init`, which is the whole difference: a kit installed as a
# plain copy is the world `autonomy_kit_stamp` warns about, and regime 6 is the only one that needs
# it. Built next to the checkout rather than derived from it so neither can drift into the other.
PLAINKIT="$OUTSIDE/plainkit"
mkdir -p "$PLAINKIT"
cp -r "$ROOT/bin" "$ROOT/templates" "$ROOT/config" "$ROOT/agents" "$PLAINKIT/"

# kitguard_world <dir> [kit] — a target repo sitting at EXEC with a `pending` increment. CALLED,
# never substituted: it cds and writes, and there is nothing here worth losing to a subshell.
kitguard_world() {
  local kit="${2:-$FAKEKIT}"
  mkdir -p "$1"
  ( cd "$1" || exit 1
    git init -q -b main
    git config user.email "fixture@example.com"
    git config user.name "Fixture"
    echo content > file.txt
    "$kit/bin/sdd" install >/dev/null
    cat > .sdd/config.sh <<'CFG'
PROJECT_NAME="kitguard"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
CFG
    mkdir -p "docs/handoffs/$MISSION"
    cat > "docs/handoffs/$MISSION/00-missao.md" <<'MIS'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
MIS
    : > "docs/handoffs/$MISSION/01-plano.md"
    # `pending`, not `blocked`: the Jidoka path escapes BEFORE opening a session, and this block
    # needs sessions to actually run. The increment never reaches `done`, so the gate fails, the
    # session moved nothing in THIS repo, and the runner spends its inline retry too — which is
    # the second half of regime 1: one divergence must be reported once, not once per session.
    cat > "docs/handoffs/$MISSION/checkpoint.md" <<'CK'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
CK
    git add -A && git commit -qm "chore: fixture mission" ) >/dev/null 2>&1
}

# The session that commits into the kit, on one chosen invocation. TWO files and not one, because
# they answer different questions: the COUNTER says how many sessions ran (every regime's floor,
# and the silent ones need it most), the MARK says a commit into a kit actually happened (the floor
# of the regimes that expect a warning). One file could not tell a control run apart from a fixture
# that stopped working.
#
# Files and not shell variables: the stub is a separate process per `claude` call, so nothing in it
# survives to the next one. Which call it fires on is a parameter because the four call sites of the
# guard are reached by different sessions — a stub that always fired first would leave three of them
# unmeasured, which is exactly what the sabotage pass caught before these regimes existed.
#
# `git add` of the ONE file it wrote, never `-A`: a blanket add inside a kit checkout would sweep up
# whatever else the run happened to drop there, and the assertion would stop being about the file
# the session actually wrote.
KIT_SESSION_COUNT="$OUTSIDE/kit-session-count"
KIT_COMMIT_MARK="$OUTSIDE/kit-commit-mark"
kitguard_stub() {   # kitguard_stub <repo to commit into, or "" for benign> [invocation to fire on]
  local fire="${2:-1}"
  cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
n=\$(( \$(cat "$KIT_SESSION_COUNT" 2>/dev/null || echo 0) + 1 ))
printf '%s\n' "\$n" > "$KIT_SESSION_COUNT"
if [ -n "$1" ] && [ "\$n" -eq $fire ]; then
  printf 'a finding the session had no business committing here\n' >> "$1/TODO.md"
  git -C "$1" add TODO.md
  git -C "$1" commit -qm "chore: the session wrote into the kit"
  : > "$KIT_COMMIT_MARK"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
  chmod +x "$OUTSIDE/stub/claude"
}

kitguard_reset()    { rm -f "$KIT_SESSION_COUNT" "$KIT_COMMIT_MARK"; : > "$LEDGER"; }
kitguard_touched()  { if [ -e "$KIT_COMMIT_MARK" ]; then printf 1; else printf 0; fi }
kitguard_sessions() { cat "$KIT_SESSION_COUNT" 2>/dev/null || printf 0; }
# kitguard_has <text> <fixed string> -> 1|0. A boolean and not a count, wherever the number is not
# the property: regime 6's projection prints one banner per phase, and pinning that number here
# would make the regime fail the day the phase list grows — an assertion about the wrong thing.
kitguard_has()      { if grep -qF "$2" <<< "$1"; then printf 1; else printf 0; fi }

# 1. THE INCIDENT. Exactly one KIT-TOUCHED for one divergence — not one per session, and
#    `sessions:2` is what makes that sentence mean something: the retry guarantees there were two.
#    `kit_before` and `kit_after` are demanded DIFFERENT: a line that printed the same stamp twice
#    would satisfy "a line exists" while saying nothing.
kitguard_reset
KGT="$OUTSIDE/kitguard-target"
kitguard_world "$KGT"
kitguard_stub "$FAKEKIT"
KG1_ERR="$( cd "$KGT" && "$FAKEKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"; KG1_RC=$?
KG1_LOG="$(cat "$KGT/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
KG1_BEFORE="$(grep -oE 'kit_before=[^ ]+' <<< "$KG1_LOG" | head -1)"
KG1_AFTER="$(grep -oE 'kit_after=[^ ]+' <<< "$KG1_LOG" | head -1)"
assert_eq "kit-guard: a session that edits the kit during another repo's mission is warned once and journalled once" \
  "sessions:1 moved:1 lines:1 warns:1 phase:EXEC differ:1 rc:3 kind:kit-touched" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG1_LOG") warns:$(grep -c 'changed during' <<< "$KG1_ERR") phase:$(grep -oE 'KIT-TOUCHED[[:space:]]+[A-Z]+' <<< "$KG1_LOG" | head -1 | awk '{print $2}') differ:$([ "${KG1_BEFORE#kit_before=}" != "${KG1_AFTER#kit_after=}" ] && echo 1 || echo 0) rc:$KG1_RC kind:$(hat_rows)"

# 2. CONTROL. The same run, same sessions, same everything — with a session that leaves the kit
#    alone. Without this term the guard could be a line printed unconditionally; without the
#    `sessions:2` FLOOR the term itself is satisfied by a run that never happened, which is the
#    measured hole this regime carried when it shipped.
kitguard_reset
KGC="$OUTSIDE/kitguard-control"
kitguard_world "$KGC"
kitguard_stub ""
KG2_ERR="$( cd "$KGC" && "$FAKEKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
KG2_LOG="$(cat "$KGC/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: a session that leaves the kit alone is not accused of anything" \
  "sessions:2 moved:0 lines:0 warns:0" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG2_LOG") warns:$(grep -c 'changed during' <<< "$KG2_ERR")"

# 3. SELF-EXCLUSION. A mission whose target IS the kit edits the kit for a living. A guard that
#    fired on every phase of every kit mission would train its only reader to ignore it, and the
#    run it finally mattered on would scroll past unread. This regime is why the guard compares
#    the kit root against REPO_ROOT rather than merely asking "did the kit change".
kitguard_reset
kitguard_world "$FAKEKIT"
kitguard_stub "$FAKEKIT"
KG3_ERR="$( cd "$FAKEKIT" && "$FAKEKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
KG3_LOG="$(cat "$FAKEKIT/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: a mission whose own repo IS the kit is left alone — the guard must not cry wolf" \
  "moved:1 lines:0 warns:0" \
  "moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG3_LOG") warns:$(grep -c 'changed during' <<< "$KG3_ERR")"

# 4. THE INLINE RETRY has a guard of its own. When the first session leaves the kit alone and the
#    RETRY is the one that writes into it, only the check on the retry path can see it — measured:
#    with that call site deleted, regimes 1-3 stay green and this one goes to lines:0. The stub
#    fires on invocation 2 because a gate that fails over a session which moved nothing is exactly
#    what makes cmd_run spend its one inline retry.
kitguard_reset
KGR="$OUTSIDE/kitguard-inline-retry"
kitguard_world "$KGR"
kitguard_stub "$FAKEKIT" 2
KG4_ERR="$( cd "$KGR" && "$FAKEKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"; KG4_RC=$?
KG4_LOG="$(cat "$KGR/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: the kit edited by the inline RETRY is caught by the retry's own check" \
  "sessions:2 moved:1 lines:1 warns:1 rc:3 kind:kit-touched" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG4_LOG") warns:$(grep -c 'changed during' <<< "$KG4_ERR") rc:$KG4_RC kind:$(hat_rows)"

# 5. `sdd retry` is ANOTHER door that opens a session which commits, and it does not go through
#    cmd_run's loop at all: its arm/check pair is its own. Measured the same way — delete that pair
#    and every regime above stays green while this one reports nothing.
kitguard_reset
KGT2="$OUTSIDE/kitguard-retry-cmd"
kitguard_world "$KGT2"
kitguard_stub "$FAKEKIT" 1
KG5_ERR="$( cd "$KGT2" && "$FAKEKIT/bin/sdd" retry "$MISSION" 2>&1 >/dev/null )"; KG5_RC=$?
KG5_LOG="$(cat "$KGT2/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: sdd retry is another door that opens a session, and it is guarded too" \
  "sessions:1 moved:1 lines:1 warns:1 rc:3 kind:kit-touched" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG5_LOG") warns:$(grep -c 'changed during' <<< "$KG5_ERR") rc:$KG5_RC kind:$(hat_rows)"

# 6. THE PROJECTION IS DISARMED, and this regime exists because the first round of this work argued
#    the opposite and shipped it. It reasoned that a dry run opens no session, so no window exists
#    and no sabotage could turn a probe red — and the window was never the point. `autonomy_kit_stamp`
#    is reached from NOWHERE ELSE during a projection, so arming the pair made `sdd run --dry-run`
#    inherit that function's warning about ledger rows a projection never writes.
#
#    DIFFERENTIAL, and it has to be: `dry-warn:0` alone is satisfied by a runner with the warning
#    deleted outright, by a plain-copy kit that stopped being plain, and by a dry run that died
#    before reaching anything. So the same kit and the same repo answer in a REAL run too
#    (`real-warn:1`), the projection has to prove it projected (`projected:1`), and it has to prove
#    it spent nothing (`dry-sessions:0`) — which is also the term that keeps this a statement about
#    the guard rather than about the warning's spelling.
kitguard_reset
KGP="$OUTSIDE/kitguard-projection"
kitguard_world "$KGP" "$PLAINKIT"
kitguard_stub ""
KG6_DRY_OUT="$( cd "$KGP" && "$PLAINKIT/bin/sdd" run "$MISSION" --dry-run 2>/dev/null )"
KG6_DRY_ERR="$( cd "$KGP" && "$PLAINKIT/bin/sdd" run "$MISSION" --dry-run 2>&1 >/dev/null )"
KG6_DRY_SESSIONS="$(kitguard_sessions)"
KG6_REAL_ERR="$( cd "$KGP" && "$PLAINKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
assert_eq "kit-guard: the projection arms nothing — and the same plain-copy kit in a real run still warns" \
  "dry-warn:0 real-warn:1 projected:1 dry-sessions:0" \
  "dry-warn:$(kitguard_has "$KG6_DRY_ERR" 'not a git checkout') real-warn:$(kitguard_has "$KG6_REAL_ERR" 'not a git checkout') projected:$(kitguard_has "$KG6_DRY_OUT" 'DRY RUN: phase') dry-sessions:$KG6_DRY_SESSIONS"

# 7. `sdd close` is the LAST door that opens a session able to commit, and it is not a phase: it
#    never goes through run_phase or cmd_run's loop, so its arm/check pair is its own too. Without
#    this regime the guard's own sentence — "a target-repo session has no business editing the kit"
#    — would be wider than what it measures, which is the shape this repo calls fail-open.
#
#    The acli stub answers `[]`: a JSON array, so the pre-check finds the tool reachable and lets
#    the session run, and an issue that is not Done, so nothing about the close verdict is what this
#    regime is reading. `phase:CLOSE` is demanded so a pair copied from cmd_run with the wrong label
#    still fails.
kitguard_reset
KGCL="$OUTSIDE/kitguard-close"
kitguard_world "$KGCL"
sed -i 's/^JIRA_ENABLED=false$/JIRA_ENABLED=true/' "$KGCL/.sdd/config.sh"
printf -- '---\nfase: TICKET\nissue: SQ-1\n---\n# TICKET\n' > "$KGCL/docs/handoffs/$MISSION/10-ticket.md"
cat > "$OUTSIDE/stub/acli" <<'STUB'
#!/usr/bin/env bash
printf '[]\n'
STUB
chmod +x "$OUTSIDE/stub/acli"
kitguard_stub "$FAKEKIT" 1
KG7_ERR="$( cd "$KGCL" && "$FAKEKIT/bin/sdd" close "$MISSION" 2>&1 >/dev/null )"; KG7_RC=$?
KG7_LOG="$(cat "$KGCL/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: sdd close opens a session too, and it is guarded like every other door" \
  "sessions:1 moved:1 lines:1 warns:1 phase:CLOSE rc:3 kind:kit-touched" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG7_LOG") warns:$(grep -c 'changed during' <<< "$KG7_ERR") phase:$(grep -oE 'KIT-TOUCHED[[:space:]]+[A-Z]+' <<< "$KG7_LOG" | head -1 | awk '{print $2}') rc:$KG7_RC kind:$(hat_rows)"

# The stubs go back the way they were found. "This block runs last" is not a property a sensor can
# hold: a future author appending below would inherit a `claude` that returns success without doing
# anything and an `acli` that answers `[]` to every question, and would never see why their new
# assertion passed.
rm -f "$OUTSIDE/stub/acli"
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$OUTSIDE/stub/claude"

# =============================================================================
# THE REVIEW SCOPE GUARD — the reviewer finds, the executor fixes
# =============================================================================
# Since 20260901-o-revisor-so-acha the REVIEW session is READ-ONLY over the code: it reproduces,
# grades honestly, and turns every finding that must be fixed into an `R<n>` increment the EXEC
# phase closes in a session of its own. `review_scope_check` is the instrument that says whether
# the contract held — a WARN and a journal line, never a boundary, exactly like the kit guard one
# screen up. The prompt is what asks; this is what measures.
#
# THREE DOORS, one probe each, the shape CLAUDE.md spells out: cmd_run's first pass, cmd_run's
# inline retry, and cmd_retry. `cmd_close` is the fourth kit-guard door and deliberately NOT a
# fourth here — it runs with `phase=CLOSE`, and the function's first line answers only to REVIEW.
#
# The regimes below are built on a world of their own rather than on $FIX: this block has to derive
# REVIEW with no `--phase` flag (the retry door lives past `--max-phases`, which returns before
# cmd_run ever spends its retry), and a run that takes several laps would leave $FIX in a state the
# assertions after this block describe.

# reviewscope_world <dir> [HANDOFF_DIR, as the target repo spells it] — a target repo sitting at
# REVIEW with nothing left pending: the increment is `done` and its commit is an ancestor of HEAD,
# the EXEC handoff is on disk and QA is skipped, so `current_phase` derives REVIEW without being
# told. CALLED, never substituted: it cds and writes, and there is nothing here worth losing to a
# subshell.
#
# The second argument is the SPELLING of the key and never the directory: the mission always lands
# in `docs/handoffs/$MISSION` on disk, because a trailing slash resolves to the same directory and
# regime 5 is about the string the allowlist matches, not about where the files are.
reviewscope_world() {
  mkdir -p "$1"
  ( cd "$1" || exit 1
    git init -q -b main
    git config user.email "fixture@example.com"
    git config user.name "Fixture"
    # core.quotePath is git's OWN DEFAULT; it is pinned here so regime 6 measures the world it
    # names on a machine whose ~/.gitconfig turned it off — a probe whose venom depends on the
    # reader's global config is a probe that quietly stops being one. Regimes 1-5 are all-ASCII,
    # so for them this line is a no-op.
    git config core.quotePath true
    mkdir -p bin tests
    printf 'echo hello\n' > bin/tool.sh
    printf 'sensor 1\n' > tests/health-baseline.txt
    : > TODO.md
    "$SDD" install >/dev/null
    cat > .sdd/config.sh <<CFG
PROJECT_NAME="reviewscope"
DEFAULT_BRANCH="main"
TEST_CMD="true"
E2E_CMD=""
HANDOFF_DIR="${2:-docs/handoffs}"
QA_DOCS_PATH="docs/qa"
TODO_FILE="TODO.md"
JIRA_ENABLED=false
CFG
    mkdir -p "docs/handoffs/$MISSION"
    cat > "docs/handoffs/$MISSION/00-missao.md" <<'MIS'
---
missao: 20260101-fixture
aprovacao: auto
---
# Mission
MIS
    : > "docs/handoffs/$MISSION/01-plano.md"
    printf -- '---\nfase: EXEC\nstatus: done\n---\n' > "docs/handoffs/$MISSION/20-handoff-exec.md"
    printf -- '---\nfase: QA\nstatus: skipped\n---\n' > "docs/handoffs/$MISSION/30-handoff-qa.md"
    git add -A && git commit -qm "chore: fixture mission"
    # Same ordering as every other done-increment fixture in this file: the hash is read BEFORE the
    # commit that carries it, and a commit follows — gate_EXEC demands an ANCESTOR of HEAD.
    cat > "docs/handoffs/$MISSION/checkpoint.md" <<EOF
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | \`true\` → 0 | done | $(git rev-parse --short HEAD) |
EOF
    git add -A && git commit -qm "chore: the increment is done, the mission is in REVIEW" ) >/dev/null 2>&1
}

# reviewscope_stub <dir> <invocation to fire on> <code|clean> — the REVIEW session.
#
# On the chosen invocation it lands `40-review-r1.md` graded B and rewrites the checkpoint with an
# `R1` line, which is precisely what the new contract asks of the reviewer; in `code` mode it also
# edits a tracked source file, which is precisely what it must not do. Every other invocation does
# NOTHING, and that is what makes the retry regime reachable: cmd_run spends its inline retry only
# when the first pass moved no disk at all.
#
# TARGETED `git add`, never `-A`: a blanket add inside the world would sweep up whatever else the
# run happened to drop there, and the assertion would stop being about the files the session
# actually wrote. `clean` mode writes all THREE allowed paths — the mission directory, $TODO_FILE
# and tests/health-baseline.txt — so the control is a statement about the allowlist rather than
# about one entry of it.
#
# The optional FOURTH argument is one more file the round drops inside its own mission directory,
# named by the caller. Regime 6 uses it for a name that is not ASCII; it is empty everywhere else,
# and then the block below is written into the stub as a dead `if [ -n "" ]`.
REVIEWSCOPE_COUNT="$OUTSIDE/reviewscope-count"
reviewscope_stub() {   # <dir> <fire on> <code|clean> [extra file inside the mission directory]
  local extra="${4:-}"
  cat > "$OUTSIDE/stub/claude" <<STUB
#!/usr/bin/env bash
n=\$(( \$(cat "$REVIEWSCOPE_COUNT" 2>/dev/null || echo 0) + 1 ))
printf '%s\n' "\$n" > "$REVIEWSCOPE_COUNT"
if [ "\$n" -eq $2 ]; then
  cat > "$1/docs/handoffs/$MISSION/40-review-r1.md" <<'MD'
---
fase: REVIEW
gate: r1 landed with one real finding
---
### Overall Grade

| Criterion | Grade | Rationale |
|---|---|---|
| Correctness | B | One real finding, handed to EXEC as R1. |
MD
  cat > "$1/docs/handoffs/$MISSION/checkpoint.md" <<'CK'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| R1 | finding one | \`true\` → 0 | pending | — |
CK
  printf 'a finding for the executor\n' >> "$1/TODO.md"
  printf 'sensor 2\n' > "$1/tests/health-baseline.txt"
  git -C "$1" add "docs/handoffs/$MISSION/40-review-r1.md" "docs/handoffs/$MISSION/checkpoint.md" TODO.md tests/health-baseline.txt
  if [ -n "$extra" ]; then
    printf 'one more artifact of the round\n' > "$1/docs/handoffs/$MISSION/$extra"
    git -C "$1" add "docs/handoffs/$MISSION/$extra"
  fi
  if [ "$3" = "code" ]; then
    printf 'echo fixed by the reviewer\n' > "$1/bin/tool.sh"
    git -C "$1" add bin/tool.sh
  fi
  git -C "$1" commit -qm "chore: round one landed"
fi
cat "$STREAM_SAMPLE"
exit 0
STUB
  chmod +x "$OUTSIDE/stub/claude"
}

reviewscope_sessions() { cat "$REVIEWSCOPE_COUNT" 2>/dev/null || printf 0; }
# The names the journal line reports, or "" when there is no line. `-F': '` (colon SPACE) and not
# `-F:`: the ISO timestamp that opens every journal line is full of bare colons and none of them is
# followed by a space.
reviewscope_files() { awk -F': ' '/HAT-CROSSED/ { print $NF; exit }' <<< "$1"; }
# The warn and the BLOCKED line both carry the reason; `warns` counts the warn alone.
reviewscope_warns() { grep -v 'BLOCKED' <<< "$1" | grep -c 'outside its writes'; }

# 1. DOOR 1 — the first pass of cmd_run's loop. `--phase REVIEW --max-phases 1` holds the run to the
#    one session this regime is about; the ceiling returns before the inline retry, which is why
#    regime 2 below cannot use it. `phase:REVIEW` is demanded so a call copied from the kit guard
#    with the wrong label still fails, and `files:bin/tool.sh` so a line that fired over the
#    reviewer's OWN artifacts — the failure mode that would make the guard noise — still fails.
echo "== the hat crossed its boundary: the reviewer that edits code stops the line =="
rm -f "$REVIEWSCOPE_COUNT"
RS1="$OUTSIDE/reviewscope-door1"
reviewscope_world "$RS1"
reviewscope_stub "$RS1" 1 code
: > "$LEDGER"
RS1_ERR="$( cd "$RS1" && "$SDD" run "$MISSION" --phase REVIEW --max-phases 1 2>&1 >/dev/null )"; RS1_RC=$?
RS1_LOG="$(cat "$RS1/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "a REVIEW session that edited code outside its writes: is logged HAT-CROSSED, and the line stops" \
  "sessions:1 lines:1 warns:1 phase:REVIEW n:1 files:bin/tool.sh rc:3 kind:hat-crossed" \
  "sessions:$(reviewscope_sessions) lines:$(grep -c 'HAT-CROSSED' <<< "$RS1_LOG") warns:$(reviewscope_warns "$RS1_ERR") phase:$(grep -oE 'HAT-CROSSED[[:space:]]+[A-Z]+' <<< "$RS1_LOG" | head -1 | awk '{print $2}') n:$(num_before "$RS1_LOG" 'path\(s\) outside') files:$(reviewscope_files "$RS1_LOG") rc:$RS1_RC kind:$(hat_rows)"

# 2. CONTROL, and it carries the whole allowlist. The same world, the same session count, a session
#    that COMMITS — `committed:1` is the floor, without which `lines:0` is also the answer of a run
#    that never opened anything — writing the round, the checkpoint, $TODO_FILE and the health
#    baseline. Every one of those is a path the new contract expects the reviewer to touch, so a
#    guard that flagged them would fire on every healthy round and train its only reader to scroll.
rm -f "$REVIEWSCOPE_COUNT"
RS2="$OUTSIDE/reviewscope-control"
reviewscope_world "$RS2"
reviewscope_stub "$RS2" 1 clean
RS2_HEAD_BEFORE="$(git -C "$RS2" rev-parse HEAD)"
RS2_ERR="$( cd "$RS2" && "$SDD" run "$MISSION" --phase REVIEW --max-phases 1 2>&1 >/dev/null )"
RS2_LOG="$(cat "$RS2/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "a REVIEW session that only wrote the round and the checkpoint is not flagged" \
  "sessions:1 committed:1 lines:0 warns:0" \
  "sessions:$(reviewscope_sessions) committed:$([ "$RS2_HEAD_BEFORE" != "$(git -C "$RS2" rev-parse HEAD)" ] && echo 1 || echo 0) lines:$(grep -c 'HAT-CROSSED' <<< "$RS2_LOG") warns:$(reviewscope_warns "$RS2_ERR")"

# 3. DOOR 2 — cmd_run's INLINE RETRY has a check of its own, and only it can see this: the first
#    session moves nothing (which is exactly what makes the runner spend the retry), the RETRY is
#    the one that commits into bin/, and door 1 of that lap had already looked and found an
#    unchanged HEAD. Measured the same way as the kit guard's sibling regime — delete the retry
#    call site and regimes 1 and 2 stay green while this one reports nothing.
rm -f "$REVIEWSCOPE_COUNT"
RS3="$OUTSIDE/reviewscope-retry"
reviewscope_world "$RS3"
reviewscope_stub "$RS3" 2 code
: > "$LEDGER"
RS3_ERR="$( cd "$RS3" && "$SDD" run "$MISSION" 2>&1 >/dev/null )"; RS3_RC=$?
RS3_LOG="$(cat "$RS3/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "the inline retry door logs HAT-CROSSED too, and stops" \
  "retried:1 lines:1 warns:1 files:bin/tool.sh rc:3 kind:hat-crossed" \
  "retried:$([ "$(reviewscope_sessions)" -ge 2 ] && echo 1 || echo 0) lines:$(grep -c 'HAT-CROSSED' <<< "$RS3_LOG") warns:$(reviewscope_warns "$RS3_ERR") files:$(reviewscope_files "$RS3_LOG") rc:$RS3_RC kind:$(hat_rows)"

# 4. DOOR 3 — `sdd retry` is another door that opens a session which commits, and it does not go
#    through cmd_run's loop at all: its call is its own. THIS REGIME WAS MISSING when the guard
#    first went green, and the sabotage pass is what said so: deleting the cmd_retry call left
#    regimes 1-3 green and the suite at rc 0, which is the definition of a door whose removal no
#    assertion notices. Written the moment that was measured, never after.
rm -f "$REVIEWSCOPE_COUNT"
RS4="$OUTSIDE/reviewscope-retry-cmd"
reviewscope_world "$RS4"
reviewscope_stub "$RS4" 1 code
: > "$LEDGER"
RS4_ERR="$( cd "$RS4" && "$SDD" retry "$MISSION" 2>&1 >/dev/null )"; RS4_RC=$?
RS4_LOG="$(cat "$RS4/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "sdd retry is another door that opens a REVIEW session, and it is guarded too" \
  "sessions:1 lines:1 warns:1 files:bin/tool.sh rc:3 kind:hat-crossed" \
  "sessions:$(reviewscope_sessions) lines:$(grep -c 'HAT-CROSSED' <<< "$RS4_LOG") warns:$(reviewscope_warns "$RS4_ERR") files:$(reviewscope_files "$RS4_LOG") rc:$RS4_RC kind:$(hat_rows)"

# 5. THE ALLOWLIST IS A GLOB MATCHED AGAINST A STRING, and the two sides of that match come from
#    different worlds: `git diff --name-only` prints a path git has already normalised, while
#    `$HANDOFF_DIR` arrives VERBATIM from the target repo's .sdd/config.sh. `HANDOFF_DIR=
#    "docs/handoffs/"` — a spelling nothing in the kit forbids, documents against, or normalises —
#    makes the pattern `docs/handoffs//<mission>/*`, which matches no path git ever prints. The
#    round's OWN report is then counted as code, and the guard warns on EVERY healthy round: the
#    noise the allowlist exists to prevent, reachable through a config key rather than a bug.
#
#    `slash:1` is the floor that the venom is ARMED. Without it a world whose config quietly lost
#    the trailing slash would satisfy this regime by being regime 2 over again — a probe concluding
#    about a world it never built, which is the failure this file has already paid for twice.
#
#    The expectation string after that floor is regime 2's, character for character, ON PURPOSE:
#    the two regimes are the differential ("the slash reads the same as no slash"), and writing it
#    out literally on both sides is what stops them from drifting into agreement by moving together.
rm -f "$REVIEWSCOPE_COUNT"
RS5="$OUTSIDE/reviewscope-trailing-slash"
reviewscope_world "$RS5" "docs/handoffs/"
reviewscope_stub "$RS5" 1 clean
RS5_HEAD_BEFORE="$(git -C "$RS5" rev-parse HEAD)"
RS5_ERR="$( cd "$RS5" && "$SDD" run "$MISSION" --phase REVIEW --max-phases 1 2>&1 >/dev/null )"
RS5_LOG="$(cat "$RS5/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "a trailing slash in HANDOFF_DIR does not turn a healthy round into a warning" \
  "slash:1 sessions:1 committed:1 lines:0 warns:0" \
  "slash:$(grep -c 'HANDOFF_DIR="docs/handoffs/"$' "$RS5/.sdd/config.sh") sessions:$(reviewscope_sessions) committed:$([ "$RS5_HEAD_BEFORE" != "$(git -C "$RS5" rev-parse HEAD)" ] && echo 1 || echo 0) lines:$(grep -c 'HAT-CROSSED' <<< "$RS5_LOG") warns:$(reviewscope_warns "$RS5_ERR")"

# 6. THE OTHER SIDE OF THAT SAME MATCH — and this one is git's doing, not the config key's. With
#    `core.quotePath` (git's DEFAULT) a tracked path carrying one byte outside ASCII leaves
#    `git diff --name-only` C-quoted and octal-escaped: `"docs/handoffs/<mission>/round\302\267
#    one.md"`. It OPENS WITH A `"`, so it matches no arm of the allowlist, and a file the round
#    wrote INSIDE its own mission directory is counted as code — the guard shouting on a healthy
#    round, which is regime 2's failure reached by a filename instead of by a config key.
#
#    THE NAME BELOW CARRIES A MIDDLE DOT AND NOT AN ACCENT, and that is a constraint of this file
#    rather than of the property. git quotes PER BYTE: every byte >= 0x80 goes the same way, so the
#    real-world instance — a mission artifact named in pt-BR, in the repo whose OUTPUT_LANG is
#    pt-BR — travels this exact code path. It cannot be typed here: tests/ is the kit's ENGLISH
#    surface and check-lang.sh reads a Latin-1 LETTER class, so an accented filename would fail the
#    language sensor, and rewording a file to quiet a detector is what that sensor's own header
#    forbids. `·` is non-ASCII (C2 B7), is not a Latin-1 letter, and is punctuation the kit already
#    writes on nearly every page. Verified by hand that the two spellings quote identically.
#
#    `nonascii:1` is the floor that the venom is ARMED. It reads the RAW diff of the fixture, where
#    core.quotePath is pinned on, so the runner's command-line override cannot reach it, and it
#    demands the ESCAPED spelling — without that floor a world where git printed the literal path
#    would satisfy this regime by being regime 2 over again, which is the vacuous probe this file
#    has already paid for twice.
#
#    The expectation after the floor is regime 2's, character for character, for regime 5's reason:
#    the claim is "a non-ASCII name reads the same as an ASCII one", and that is a differential.
rm -f "$REVIEWSCOPE_COUNT"
RS6="$OUTSIDE/reviewscope-nonascii"
reviewscope_world "$RS6"
reviewscope_stub "$RS6" 1 clean "round·one.md"
RS6_HEAD_BEFORE="$(git -C "$RS6" rev-parse HEAD)"
RS6_ERR="$( cd "$RS6" && "$SDD" run "$MISSION" --phase REVIEW --max-phases 1 2>&1 >/dev/null )"
RS6_LOG="$(cat "$RS6/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
RS6_RAW="$(git -C "$RS6" diff --name-only "$RS6_HEAD_BEFORE" HEAD 2>/dev/null || true)"
assert_eq "a mission-directory file whose name is not ASCII is not flagged HAT-CROSSED" \
  "nonascii:1 sessions:1 committed:1 lines:0 warns:0" \
  "nonascii:$(grep -cF 'round\302\267one.md' <<< "$RS6_RAW") sessions:$(reviewscope_sessions) committed:$([ "$RS6_HEAD_BEFORE" != "$(git -C "$RS6" rev-parse HEAD)" ] && echo 1 || echo 0) lines:$(grep -c 'HAT-CROSSED' <<< "$RS6_LOG") warns:$(reviewscope_warns "$RS6_ERR")"

# 7. THE WARNING BRANCH CANNOT STOP THE LINE. Every regime above measures what the guard SAYS;
#    this one measures what saying it COSTS. The warn is followed by `pipeline_log_line`, whose
#    last act is a `printf` redirected into a file the runner does not own — and under `set -e` a
#    failed redirection kills the shell where it happens, so the sentence three places of this kit
#    repeat ("it warns and records; it does not stop the line") stopped being true the moment
#    `.sdd/logs/<mission>/pipeline.log` could not be written.
#
#    THE FIRST VICTIM IS NOT THE GUARD, which is why the fix is not a `|| true` at the guard's call
#    site. Measured in exactly this world before the fix: `sdd run` died inside `pipeline_log_line`
#    on run_phase's OWN session line — one caller earlier — with `rc=1`, no ledger row and the
#    guard never reached. Guarding only the guard would have left the runner dying one line up
#    while its header claimed the property. So the guard lives in the ONE definition, beside the
#    DRY_RUN and empty-path guards already there and for the reason that function's header gives:
#    a caller added tomorrow is born with it.
#
#    `armed:1` is the floor that the venom is ARMED — as root, or on a filesystem that ignores the
#    mode, this regime would quietly be regime 1 under another name. `warns:1` is the floor that
#    the GUARD FIRED: a run that never triggered it would reach the ledger trivially. `journal:1`
#    and not 2 pins the announcement as ONE-SHOT — two journal writes fail in this run (run_phase's
#    line and the guard's), and a warning repeated per line would train its only reader to scroll,
#    which is what the allowlist above exists to prevent. `rc:0 rows:1` is the property itself: the
#    run ended cleanly and reached the line AFTER the guard, which is the ledger row.
rm -f "$REVIEWSCOPE_COUNT"
RS7="$OUTSIDE/reviewscope-nojournal"
reviewscope_world "$RS7"
reviewscope_stub "$RS7" 1 code
mkdir -p "$RS7/.sdd/logs/$MISSION"
: > "$RS7/.sdd/logs/$MISSION/pipeline.log"
chmod 000 "$RS7/.sdd/logs/$MISSION/pipeline.log"
RS7_ARMED=0
( printf 'x' >> "$RS7/.sdd/logs/$MISSION/pipeline.log" ) 2>/dev/null || RS7_ARMED=1
: > "$LEDGER"
RS7_ROWS_BEFORE="$(nrows)"
RS7_RC=0
RS7_ERR="$( cd "$RS7" && "$SDD" run "$MISSION" --phase REVIEW --max-phases 1 2>&1 >/dev/null )" || RS7_RC=$?
assert_eq "the hat guard still stops the line when the pipeline log cannot be written — the ledger row is the artifact" \
  "armed:1 sessions:1 warns:1 journal:1 rc:3 rows:2 kind:hat-crossed" \
  "armed:$RS7_ARMED sessions:$(reviewscope_sessions) warns:$(reviewscope_warns "$RS7_ERR") journal:$(grep -c 'the pipeline journal at' <<< "$RS7_ERR") rc:$RS7_RC rows:$(( $(nrows) - RS7_ROWS_BEFORE )) kind:$(hat_rows)"

# 8. THE SAME FAILURE, IN THE CHANNEL THE HUMAN ACTUALLY READS. Regime 7 measured that the run
#    SURVIVES an unwritable journal, and stopped there — the evidence for this regime was already
#    sitting in `RS7_ERR` and no assertion looked at it. `2>/dev/null` was written to the RIGHT of
#    the `>>` in both writers, and bash applies redirections LEFT TO RIGHT: when the `open` of the
#    append fails, the shell's own complaint goes to an fd 2 that has not been redirected yet. So
#    the curated one-shot regime 7 pins with `journal:1` arrived escorted by one raw
#    `Permission denied` PER journal line, in the same stderr — the one-shot defeated where its
#    only reader stands. Reproduced before this regime was written, in a throwaway script: three
#    calls, `2>` on the right ⇒ 3 raw lines; `2>` on the left ⇒ 0, with the guard branch still
#    firing.
#
#    ONE ASSERTION, BOTH WRITERS, and that is not tidiness. `pipeline_log_line` and
#    `autonomy_append` carry the same spelling because the R8 of `20260901-o-revisor-so-acha`
#    aligned them on purpose ("one rule, one spelling, in both writers"); two assertions that can
#    be closed one at a time are how the two spellings drift apart a third time. Hence a world in
#    which BOTH files are unwritable, with a floor per venom.
#
#    THE RAW COUNT IS A SUBTRACTION AND NOT A MESSAGE MATCH, deliberately: the shell's complaint is
#    `<script>: line N: <path>: <strerror>`, and both halves after the path are LOCALE-dependent —
#    neither the word before the line number nor the `strerror` is English on a machine whose
#    locale is not (measured on this one, whose two words cannot be written on the kit's English
#    surface — the constraint regime 6 above spells out). What is stable is the PATH, which every raw
#    line names and which both curated warnings embed. So `named - curated` counts exactly the
#    lines that mention a journal path without being one of the kit's own sentences, in any locale.
#
#    `jarmed:1 larmed:1` are the floors that each venom is ARMED — as root, or on a filesystem that
#    ignores the mode, this regime would quietly become regime 1 with a longer name. `journal:1`
#    and `ledger:1` are the floor that each writer was actually REACHED and warned: `raw:0` over a
#    run where neither write failed is the answer of a world nobody built. `rc:0` keeps regime 7's
#    property from regressing here — the ledger row cannot be the witness in this world, because
#    the ledger is the second thing this regime breaks.
rm -f "$REVIEWSCOPE_COUNT"
RS8="$OUTSIDE/reviewscope-rawerror"
reviewscope_world "$RS8"
reviewscope_stub "$RS8" 1 code
mkdir -p "$RS8/.sdd/logs/$MISSION" "$OUTSIDE/rs8-state"
: > "$RS8/.sdd/logs/$MISSION/pipeline.log"
: > "$OUTSIDE/rs8-state/autonomy-log.jsonl"
chmod 000 "$RS8/.sdd/logs/$MISSION/pipeline.log" "$OUTSIDE/rs8-state/autonomy-log.jsonl"
RS8_JARMED=0
RS8_LARMED=0
( printf 'x' >> "$RS8/.sdd/logs/$MISSION/pipeline.log" ) 2>/dev/null || RS8_JARMED=1
( printf 'x' >> "$OUTSIDE/rs8-state/autonomy-log.jsonl" ) 2>/dev/null || RS8_LARMED=1
RS8_RC=0
RS8_ERR="$( cd "$RS8" && SDD_STATE_DIR="$OUTSIDE/rs8-state" "$SDD" run "$MISSION" --phase REVIEW --max-phases 1 2>&1 >/dev/null )" || RS8_RC=$?
RS8_NAMED="$(grep -cE 'pipeline\.log|autonomy-log\.jsonl' <<< "$RS8_ERR")"
RS8_CURATED="$(grep -cE 'the pipeline journal at|could not write the autonomy ledger at' <<< "$RS8_ERR")"
# ledger:2 since the hat guard stops the line: the session row AND the blocked row both try the
# unwritable file, and each is refused with the curated sentence — never the raw redirection.
assert_eq "neither journal writer leaks a raw redirection error when its file cannot be written" \
  "jarmed:1 larmed:1 sessions:1 journal:1 ledger:2 raw:0 rc:3" \
  "jarmed:$RS8_JARMED larmed:$RS8_LARMED sessions:$(reviewscope_sessions) journal:$(grep -c 'the pipeline journal at' <<< "$RS8_ERR") ledger:$(grep -c 'could not write the autonomy ledger at' <<< "$RS8_ERR") raw:$(( RS8_NAMED - RS8_CURATED )) rc:$RS8_RC"

# The stub goes back the way it was found, for the reason spelled out one screen up.
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
echo "ERROR: the test invoked the real claude" >&2
exit 97
STUB
chmod +x "$OUTSIDE/stub/claude"

# --- the instrument never lands inside the thing it measures ----------------
# Pins the $OUTSIDE decision at the top of this file. If the ledger, a reader fixture or the kit
# copy ever moves back under $FIX, the moving stub's `git add -A` commits it into the repo under
# test: `state_fingerprint` reads git HEAD, so the LEDGER being written could move the fingerprint
# by itself and the waste metric would start measuring its own instrument. The second assertion is
# the general form — any stray file this test leaves in the target repo fails it, including ones
# nobody has thought of yet.
assert_eq "the ledger is never tracked by the repo under test" "0" \
  "$(git -C "$FIX" ls-files | grep -c 'autonomy-log\.jsonl')"
assert_eq "the repo under test ends with a clean tree" "" \
  "$(git -C "$FIX" status --porcelain)"

# sdd health check 6 fails on a subcommand missing from the help — assert it here too, so the
# reason is visible at the point of change instead of three files away.
assert_eq "the subcommand is in sdd help" "1" "$( "$SDD" help 2>&1 | grep -c 'sdd autonomy' )"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the ledger records facts and stays quiet on projections\n'; exit 0; fi
printf '%d autonomy check(s) failed\n' "$fails" >&2
exit 1
