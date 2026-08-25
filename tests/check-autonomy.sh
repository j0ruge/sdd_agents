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
  "$(grep -cE '^  h[12]  ' <<< "$out_bm") h1:$(mission_line h1 "$out_bm" | grep -oE '[0-9]+ intervention' | grep -oE '^[0-9]+') h2:$(mission_line h2 "$out_bm" | grep -oE '[0-9]+ intervention' | grep -oE '^[0-9]+')"

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
  "$(grep -cE '^  h3  ' <<< "$out_bm3") h3:$(mission_line h3 "$out_bm3" | grep -oE '[0-9]+ intervention' | grep -oE '^[0-9]+')"

rm -rf "$FIX/docs/handoffs/h1" "$FIX/docs/handoffs/h2" "$FIX/docs/handoffs/h3"

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
# holds nothing but comparable sessions; the judge, though, reads first appearance off every
# on_axis row, escalations included. So a version whose first on_axis row is an escalation is
# already known to the series while the table has never heard of it — and a table that ordered by
# its OWN population put that version last while the judge called another one latest. Found in the
# r1 review by reproduction, not by reading: rows blocked(aaaaaaa), session(bbbbbbb),
# session(aaaaaaa) answered `aaaaaaa` here and `bbbbbbb` there over one file. Written DIFFERENTIAL
# for the same reason D4 is, and the escalation goes FIRST because that is the only placement in
# which the two populations disagree at all.
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

kitguard_reset()    { rm -f "$KIT_SESSION_COUNT" "$KIT_COMMIT_MARK"; }
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
KG1_ERR="$( cd "$KGT" && "$FAKEKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
KG1_LOG="$(cat "$KGT/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
KG1_BEFORE="$(grep -oE 'kit_before=[^ ]+' <<< "$KG1_LOG" | head -1)"
KG1_AFTER="$(grep -oE 'kit_after=[^ ]+' <<< "$KG1_LOG" | head -1)"
assert_eq "kit-guard: a session that edits the kit during another repo's mission is warned once and journalled once" \
  "sessions:2 moved:1 lines:1 warns:1 phase:EXEC differ:1" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG1_LOG") warns:$(grep -c 'changed during' <<< "$KG1_ERR") phase:$(grep -oE 'KIT-TOUCHED[[:space:]]+[A-Z]+' <<< "$KG1_LOG" | head -1 | awk '{print $2}') differ:$([ "${KG1_BEFORE#kit_before=}" != "${KG1_AFTER#kit_after=}" ] && echo 1 || echo 0)"

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
KG4_ERR="$( cd "$KGR" && "$FAKEKIT/bin/sdd" run "$MISSION" 2>&1 >/dev/null )"
KG4_LOG="$(cat "$KGR/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: the kit edited by the inline RETRY is caught by the retry's own check" \
  "sessions:2 moved:1 lines:1 warns:1" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG4_LOG") warns:$(grep -c 'changed during' <<< "$KG4_ERR")"

# 5. `sdd retry` is ANOTHER door that opens a session which commits, and it does not go through
#    cmd_run's loop at all: its arm/check pair is its own. Measured the same way — delete that pair
#    and every regime above stays green while this one reports nothing.
kitguard_reset
KGT2="$OUTSIDE/kitguard-retry-cmd"
kitguard_world "$KGT2"
kitguard_stub "$FAKEKIT" 1
KG5_ERR="$( cd "$KGT2" && "$FAKEKIT/bin/sdd" retry "$MISSION" 2>&1 >/dev/null )"
KG5_LOG="$(cat "$KGT2/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: sdd retry is another door that opens a session, and it is guarded too" \
  "sessions:1 moved:1 lines:1 warns:1" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG5_LOG") warns:$(grep -c 'changed during' <<< "$KG5_ERR")"

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
KG7_ERR="$( cd "$KGCL" && "$FAKEKIT/bin/sdd" close "$MISSION" 2>&1 >/dev/null )"
KG7_LOG="$(cat "$KGCL/.sdd/logs/$MISSION/pipeline.log" 2>/dev/null || true)"
assert_eq "kit-guard: sdd close opens a session too, and it is guarded like every other door" \
  "sessions:1 moved:1 lines:1 warns:1 phase:CLOSE" \
  "sessions:$(kitguard_sessions) moved:$(kitguard_touched) lines:$(grep -c 'KIT-TOUCHED' <<< "$KG7_LOG") warns:$(grep -c 'changed during' <<< "$KG7_ERR") phase:$(grep -oE 'KIT-TOUCHED[[:space:]]+[A-Z]+' <<< "$KG7_LOG" | head -1 | awk '{print $2}')"

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
