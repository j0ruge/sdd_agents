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

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
# Every row lands in exactly one of four buckets: comparable session, non-comparable session,
# escalation, unrecognized. If the filter drops a row (finding 3) or double-counts one, this sum
# drifts from the header total — an anti-vacuity check a broken filter cannot pass by accident,
# unlike any single count in isolation.
assert_bucket_sum() {
  local desc="$1" out="$2" total comparable noncomp escal stray sum
  total="$(num_before "$out" 'row\(s\)')"; total="${total:-0}"
  comparable="$(sum_sessions "$out")"
  noncomp="$(num_before "$out" 'non-comparable')"; noncomp="${noncomp:-0}"
  escal="$(sum_escalations "$out")"
  stray="$(num_before "$out" 'unrecognized')"; stray="${stray:-0}"
  sum=$((comparable + noncomp + escal + stray))
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

# --- the real escalation writes one honest row ------------------------------
echo "== blocked escalation =="
"$SDD" run "$MISSION" >/dev/null 2>&1; rc=$?
assert_eq "the blocked increment escalates with rc 3" "3" "$rc"
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
echo "== session rows =="
: > "$LEDGER"
cat > "$MDIR/checkpoint.md" <<'EOF'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
EOF
cat > "$OUTSIDE/stub/claude" <<'STUB'
#!/usr/bin/env bash
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

# --- sdd retry is a human-forced session, and that is a first-class signal ---
# It is literally the rubric's "refez": the human looked at the result and pushed the phase
# again. Leaving it out of the ledger would hide the strongest friction signal there is.
echo "== retry invocation =="
: > "$LEDGER"
"$SDD" retry "$MISSION" >/dev/null 2>&1
assert_eq "sdd retry writes one session row" "1" "$(nrows)"
assert_eq "and marks itself as a retry invocation" "retry" "$(rows '.invocation')"
assert_eq "with its own run_id" "true" "$(rows '(.run_id | length) > 0')"

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
wc -l < "$DRAFT_LAPS" > "$FIX/churn.txt"
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
# 2 comparable sessions (rows 1 and 2), 1 of them stalled => 50%.
assert_eq "waste is computed over comparable sessions only" "1" \
  "$(grep -c '50% waste' <<< "$out")"
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

# The judge reads the same file through its own jq program. Pinning only the human's table would
# leave the flag able to reach one reader and not the other — the divergence between two
# instruments over one file that this whole section exists to prevent.
ser_here="$( SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series 2>/dev/null )"
ser_all="$(  SDD_STATE_DIR="$OUTSIDE/tworepos" "$SDD" kaizen --series --all-repos 2>/dev/null )"
assert_eq "all-repos: the judge's series answers it too — other_repo falls to 0 and the missions rise" \
  "3 0 wider" \
  "$(jq -r '.excluded.other_repo' <<< "$ser_here") $(jq -r '.excluded.other_repo' <<< "$ser_all") $(wider "$(jq -r '.guard.missions_with_session' <<< "$ser_all")" "$(jq -r '.guard.missions_with_session' <<< "$ser_here")")"
# Anti-vacuity: a flag that widened the reading by losing rows on the way would still be "wider".
assert_bucket_sum "the four buckets sum to the header total (--all-repos over two repos)" "$out_all"

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

# sdd health check 5 fails on a subcommand missing from the help — assert it here too, so the
# reason is visible at the point of change instead of three files away.
assert_eq "the subcommand is in sdd help" "1" "$( "$SDD" help 2>&1 | grep -c 'sdd autonomy' )"

echo
if [ "$fails" -eq 0 ]; then printf '  ok    the ledger records facts and stays quiet on projections\n'; exit 0; fi
printf '%d autonomy check(s) failed\n' "$fails" >&2
exit 1
