#!/usr/bin/env bash
# Sensor for the GNU userland probe of `sdd preflight`.
#
# The runner calls three tools by their GNU names and flags: `md5sum` (state_fingerprint),
# `date -Iseconds` (the journal) and `sort -V` (the plugin version). macOS ships none of the
# three — it has `md5`, and its BSD `date`/`sort` reject those options — and the bash-4 check at
# the top of bin/sdd can only speak for bash. So the rest of the assumption is measured in
# preflight, and this file is what proves the measurement still measures.
#
# Presence would not be enough, which is why the probe is behavioural: brew installs GNU
# coreutils as gmd5sum/gdate unless the gnubin dir comes first in PATH, so `command -v date`
# passes on a machine where `date -Iseconds` fails. The shims below answer the way the BSD tools
# answer, so the test exercises the same distinction.
#
# No token and no network: `claude` and `gh` are stubbed to fail, and preflight is EXPECTED to
# fail overall in both runs. The only thing asserted is the GNU line — quiet when the userland is
# GNU, and naming all three when it is not.
#
# SECOND responsibility, and it lives here because the fixture already runs `sdd install`: the
# guard that stops the installer from leaving a 0-byte `.sdd/config.sh` behind when the kit copy
# has no `config/starter.conf`. Same family as the GNU probe above — the runner asserting a world
# it did not measure.
#
# THIRD, same family again and the sharpest of the three: preflight used to ask `[ -f <copy> ]` and
# then print "N kit agent(s) checked" — a label over a comparison that never happened. The harness
# loads the COPY in .claude/agents/, so the source can be fixed and the agent keeps running the old
# text; it happened (2132cf5 edited agents/sdd-kaizen.md, the copy stayed behind, green in
# everything). Asserted differentially, for a reason spelled out at the section itself.
#
# Usage: tests/check-preflight.sh   (exit 0 = the probe still fires, and still stays quiet)

set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDD="$ROOT/bin/sdd"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-XXXXXX")"
fails=0
trap 'rm -rf "$FIX"' EXIT

pass() { printf '  ok    %s\n' "$1"; }
# Inside a mutant the first red assertion is the verdict: fail() ends the sensor there, AFTER
# printing, so the mutant's log still names it. The census in check-health.sh holds all nine.
fail() { printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }

# assert_has <description> <needle> <haystack>
assert_has() {
  if grep -qF -- "$2" <<< "$3"; then pass "$1"
  else fail "$1" "output containing: $2" "$(printf '%s' "$3" | tr '\n' '|' | head -c 200)"; fi
}

# assert_lacks <description> <needle> <haystack>
assert_lacks() {
  if grep -qF -- "$2" <<< "$3"; then fail "$1" "output WITHOUT: $2" "it was printed"
  else pass "$1"; fi
}

# assert_eq <description> <expected> <got>. The two above answer one yes/no about one needle; the
# blocks that have to say "this arm fired AND the other one did not, AND the command really ran"
# compose their answer into a string and compare it whole, so a red names which term went wrong
# instead of only that something did.
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1" "$2" "$3"; fi
}

OK_LINE="GNU userland (md5sum, date -Iseconds, sort -V)"
BAD_LINE="the kit assumes the GNU userland, and these do not answer: md5sum 'date -Iseconds' 'sort -V'"

# ---------------------------------------------------------------------------
echo "== fixture at $FIX =="
# `|| exit`: `set -e` is off, and a failing `cd` would run `git init` in the repo of whoever ran
# the test. Same guard, same reason, as check-dry-run.sh.
cd "$FIX" || exit 1

# Absolute paths captured BEFORE the shims go on PATH: a shim that exec'd a bare `date` would
# find itself and recurse until the process table complains.
REAL_DATE="$(command -v date)"
REAL_SORT="$(command -v sort)"

# claude and gh answer failure, instantly and offline. preflight fires a real headless session
# and a real `gh auth status` otherwise — a test that spends tokens or touches the network is not
# a test the suite can run.
mkdir -p "$FIX/.stub"
printf '#!/bin/sh\nexit 1\n' > "$FIX/.stub/claude"
printf '#!/bin/sh\nexit 1\n' > "$FIX/.stub/gh"
chmod +x "$FIX/.stub/claude" "$FIX/.stub/gh"
PATH="$FIX/.stub:$PATH"

# The BSD userland, imitated at the level that matters: the option is rejected, everything else
# still works. `md5sum` is not shimmed to fail — on macOS the name does not exist at all, and 127
# is what the shell returns for that.
mkdir -p "$FIX/.bsd"
printf '#!/bin/sh\nexit 127\n' > "$FIX/.bsd/md5sum"
printf '#!/bin/sh\ncase "$1" in -I*) echo "date: illegal option -- I" >&2; exit 1;; esac\nexec %s "$@"\n' \
  "$REAL_DATE" > "$FIX/.bsd/date"
printf '#!/bin/sh\nfor a in "$@"; do case "$a" in -V) echo "sort: illegal option -- V" >&2; exit 2;; esac; done\nexec %s "$@"\n' \
  "$REAL_SORT" > "$FIX/.bsd/sort"
chmod +x "$FIX/.bsd/md5sum" "$FIX/.bsd/date" "$FIX/.bsd/sort"

git init -q -b main
git config user.email "fixture@example.com"
git config user.name "Fixture"
echo "content" > file.txt
git add -A && git commit -qm "init"

# This install is fixture setup for preflight AND the POSITIVE control of the starter.conf guard
# asserted at the bottom of this file. Without it a guard that died unconditionally would satisfy
# every assertion down there, and the installer would be broken in the opposite direction.
echo "== sdd install with the real kit (positive control) =="
install_out="$( "$SDD" install 2>&1 )"
assert_has "install reports the config created" ".sdd/config.sh created" "$install_out"
# Asserted BEFORE the heredoc below overwrites it: what the defect produced was a file that
# existed and was empty, so existence alone is exactly the check that could not see it.
if [ -s ".sdd/config.sh" ]; then pass "the created config is not empty"
else fail "the created config is not empty" "a non-zero .sdd/config.sh" \
       "$(wc -c < .sdd/config.sh 2>/dev/null || echo 'no file') byte(s)"; fi

cat > .sdd/config.sh <<'EOF'
PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="npm test"
E2E_CMD=""
HANDOFF_DIR="docs/handoffs"
QA_DOCS_PATH="docs/qa"
JIRA_ENABLED=false
EOF

# --- the userland is GNU: the probe stays quiet -----------------------------
echo "== GNU userland =="
out="$( "$SDD" preflight 2>&1 )"

# Sanity first. Without it, a preflight that died before reaching the probe (a broken fixture, a
# renamed config key) would satisfy every "lacks" assertion below and the test would pass green
# while measuring nothing.
assert_has "preflight got as far as the tool checks" "git present" "$out"
assert_has "GNU userland reported ok" "$OK_LINE" "$out"
assert_lacks "no GNU complaint on a GNU machine" "the kit assumes the GNU userland" "$out"

# --- HAT_WRITES_EXTRA for a hat that already writes anywhere ----------------
# An entry naming sdd-executor is accepted and IGNORED: that hat's writes: is empty, which means
# "writes anywhere", and summing the entry would turn the widest hat in the pipeline into the
# narrowest. Accepted-and-silent would be a trap of its own, though — the operator would go on
# believing a declaration is in force while nothing reads it. So preflight says so.
echo "== HAT_WRITES_EXTRA naming a hat that already writes anywhere =="
printf 'HAT_WRITES_EXTRA="sdd-executor: x.md"\n' >> .sdd/config.sh
hwx_out="$( "$SDD" preflight 2>&1 )"
sed -i '/^HAT_WRITES_EXTRA=/d' .sdd/config.sh
# DIFFERENTIAL: the same preflight WITHOUT the key must not say it. Asserting only the presence
# would also pass on a line printed unconditionally, which is a warning that means nothing.
hwx_quiet="$( "$SDD" preflight 2>&1 )"
assert_eq "preflight says an entry for a hat that writes anywhere is ignored, and says it only then" \
  "named:1 quiet:0" \
  "named:$( grep -c 'sdd-executor' <<< "$hwx_out" ) quiet:$( grep -c 'sdd-executor' <<< "$hwx_quiet" )"

# --- the context bill: a SENSOR, and never a refusal ------------------------
# The target's CLAUDE.md plus its .claude/rules/ is ~73% of the fixed prefix every turn of every
# phase carries (measured 2026-09-03, two repos). The kit does not cut anybody's rulebook, so this
# line only has to make the number visible — and the second assertion is the one that matters,
# because a preflight that started REFUSING a repo for having many rules would be the kit deciding
# how a target documents itself.
#
# The fixture repo has no CLAUDE.md and no .claude/rules/, so `0 file(s), 0 bytes` is the honest
# answer AND the world where the guard is load-bearing: `find`/glob on an absent directory exits
# non-zero, and under `set -o pipefail` an unguarded capture would take the whole preflight down on
# exactly the repo shape most targets have.
assert_has "the context bill is reported" "context bill: 0 file(s), 0 bytes" "$out"
assert_has "and it is an ok line, never a refusal" "ok   context bill" "$out"
{ printf '# rules\n'; head -c 1234 /dev/zero | tr '\0' 'r'; } > "$FIX/CLAUDE.md"
mkdir -p "$FIX/.claude/rules" && printf '# r\n' > "$FIX/.claude/rules/one.md"
out_cb="$( "$SDD" preflight 2>&1 )"
# Differential: the count and the bytes both have to move, and the rules file has to be found under
# a directory the first world did not have. Counting only files would pass on a bill that reports
# a constant; counting only bytes would pass on one that never looks inside .claude/rules/.
# The expected byte count is COMPUTED from the two files just written, never typed: a literal here
# is a number that goes stale the first time the fixture changes by a byte, and a stale expectation
# in a passing test is worse than no test.
cb_want=$(( $(wc -c < "$FIX/CLAUDE.md") + $(wc -c < "$FIX/.claude/rules/one.md") ))
assert_has "the bill counts CLAUDE.md and the rules directory, in files and in bytes" \
  "context bill: 2 file(s), $cb_want bytes" "$out_cb"
rm -rf "$FIX/CLAUDE.md" "$FIX/.claude/rules"

# --- adr traceability: a SENSOR too, and for the same reason ----------------
# `ok   ` with THREE spaces, not the four a suite sensor prints: this reads the RUNNER's own
# `ok()`, which is a different function from the `pass()` at the top of this file. Written with
# four the assertion could never match, and it would have gone on reporting a line that was there.
#
# The default is `off` and the fixture never sets the key, so this is the state every repo is in
# on the day it installs the kit — the one state a preflight must not be red in.
assert_has "adr traceability is reported under the default off" \
  "ok   adr check: ADR_CHECK=off, the PLAN and EXEC gates ask nothing" "$out"

# Differential: one config line apart, the SAME repo has to stop saying "asks nothing" and start
# counting. Asserting only the off line would pass on a preflight that never reads the key; only
# the warn line, on one that always scans.
printf 'ADR_CHECK="warn"\n' >> "$FIX/.sdd/config.sh"
mkdir -p "$FIX/docs/adr" && printf 'loose\n' > "$FIX/docs/adr/not-an-adr.md"
out_adr="$( "$SDD" preflight 2>&1 )"
assert_has "under warn it counts the findings instead of refusing the repo" \
  "adr check: ADR_CHECK=warn, 0 ADR(s) in docs/adr, 1 finding(s)" "$out_adr"
assert_lacks "and a finding is never a preflight failure — migration debt is not a broken environment" \
  "fail  adr check" "$out_adr"
rm -rf "$FIX/docs/adr"
sed -i '/^ADR_CHECK="warn"$/d' "$FIX/.sdd/config.sh"

# ...and the third state, which is neither: a configuration the GATES refuse. Measured 2026-09-17
# (Codex review of PR #45): every value other than `off` fell through to the scan, so ADR_CHECK=bogus
# printed `ok   adr check: ADR_CHECK=bogus, ... no finding` and the command still ended `preflight
# ok`, while gate_PLAN refused that same value with rc 2. A preflight that certifies a config the
# pipeline then refuses is not a weaker sensor, it is a wrong one.
#
# `fail` and not `warn`, unlike the finding above, and BOTH terms say so: migration debt is a number
# to count, an unusable config is a door that will not open. Asserting only the `fail` line would
# pass on a preflight that went red for some unrelated reason.
printf 'ADR_CHECK="bogus"\n' >> "$FIX/.sdd/config.sh"
out_bogus="$( "$SDD" preflight 2>&1 )"
assert_has "an ADR_CHECK the gates refuse fails the preflight instead of being scanned" \
  "fail  adr check: ADR_CHECK=bogus is not one of off|warn|block" "$out_bogus"
assert_lacks "...and it never reports a clean scan over a config it cannot use" \
  "ADR_CHECK=bogus, 0 ADR(s)" "$out_bogus"
sed -i '/^ADR_CHECK="bogus"$/d' "$FIX/.sdd/config.sh"

# --- the userland is BSD: the probe names all three -------------------------
echo "== BSD userland (shimmed) =="
out="$( PATH="$FIX/.bsd:$PATH" "$SDD" preflight 2>&1 )"

assert_has "preflight got as far as the tool checks" "git present" "$out"
assert_has "the three GNU tools are named, in one line" "$BAD_LINE" "$out"
assert_lacks "the ok line is not printed at the same time" "$OK_LINE" "$out"
# The consequence is part of the message on purpose: "md5sum missing" reads like a cosmetic
# nuisance, and what actually happens is that state_fingerprint goes empty and the runner stops
# being able to tell a session that moved the disk from one that did not.
assert_has "the failure says what breaks, not only what is missing" \
  "the state fingerprint is empty" "$out"

# --- the git is older than 2.31: the probe says so, and only then -----------
# The line that tells the operator the ledger takes the slow path had no assertion at all: its
# `warn`, its `ok`, and the `= 1` that picks between them could each be sabotaged with this file
# green (issue #75, measured on 8033a79). The shim is check-autonomy.sh's GITSHIM: rev-parse echoes
# back the flag it does not know and exits 0, which is what git before 2.31 does. The floor proves
# the shim is armed before anything is concluded, and the two runs are read against each other.
echo "== git older than 2.31 (shimmed) =="
mkdir -p "$FIX/.oldgit"
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
} > "$FIX/.oldgit/git"
chmod +x "$FIX/.oldgit/git"
assert_eq "the pre-2.31 git shim is armed: rev-parse --path-format answers two lines, a modern git one" \
  "old:2 new:1" \
  "old:$(PATH="$FIX/.oldgit:$PATH" git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | grep -c . || true) new:$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | grep -c . || true)"
out_oldgit="$( PATH="$FIX/.oldgit:$PATH" "$SDD" preflight 2>&1 )"
out_newgit="$( "$SDD" preflight 2>&1 )"
assert_has "an old git is told the ledger takes the slow path" \
  "this git does not know 'rev-parse --path-format'" "$out_oldgit"
assert_lacks "...and is not told it speaks the flag" "git speaks --path-format" "$out_oldgit"
assert_has "a modern git is told it speaks --path-format" "git speaks --path-format (2.31+)" "$out_newgit"
assert_lacks "...and is not warned about an old git" \
  "this git does not know 'rev-parse --path-format'" "$out_newgit"

# --- the executor hat sees Bash ---------------------------------------------
# The auth probe used to run without --agent and called itself "the same flags as run_phase"; on
# 2026-09-06 it was green while every hat booted without a shell (Claude Code 2.1.263 reads the
# hat's `disallowedTools:` and strips Bash for a rule written there — bin/sdd: hat_disallowed).
# Now it fires the executor hat and reads `Bash` off the init line, and this pair is what proves
# it reads it: the same fixture, two stubs, ONE difference — whether the session answers with
# Bash in its tool list when asked as the hat — and the two outputs compared against each other.
# Stub B is flag-sensitive on purpose: it drops Bash ONLY when `--agent` is on the command line,
# which is what makes a probe that stopped passing --agent (the pre-fix shape) read green here and
# take the assertion red.
#
# PROVENANCE: the init line and the result line are one REAL session, captured on 2026-09-06 with
#     claude -p '<prompt>' --model haiku --max-turns 3 --permission-mode acceptEdits \
#       --output-format stream-json --verbose --setting-sources user,project,local \
#       --allowedTools Bash --disallowedTools "<hat_disallowed EXEC of bin/sdd>" \
#       --agent sdd-executor --strict-mcp-config
# in the kit repo on Claude Code 2.1.263, AFTER the rules moved to permissionsDeny: — 12 tools,
# Bash among them, no Task, no Monitor, no MCP. Pasted VERBATIM. The no-Bash init is DERIVED from
# it with jq, never typed; the result line has `.result` set to the marker the probe looks for,
# also with jq, because the real session answered its hat's refusal to push, not the marker.
echo "== the executor hat sees Bash =="
assert_has "with a dead claude the probe reports the login, not the hat" "claude -p did not answer" "$out"

cat > "$FIX/.stub/init-with-bash.jsonl" <<'EOF'
{"type":"system","subtype":"init","cwd":"/home/joruge/repos/sdd_agents","session_id":"a74f8a14-6262-426e-89af-0dc22f5f6f15","tools":["Bash","Edit","Read","Skill","TaskCreate","TaskGet","TaskList","TaskOutput","TaskStop","TaskUpdate","ToolSearch","Write"],"mcp_servers":[],"model":"claude-haiku-4-5-20251001","permissionMode":"acceptEdits","slash_commands":["archify","archimate","bpmn","brandkit","canvas","cloud","data-analytics","data-recovery","design-taste-frontend","design-taste-frontend-v1","designer-loop","find-skills","full-output-enforcement","gpt-taste","graphviz","grill-with-docs","high-end-visual-design","image-to-code","imagegen-frontend-mobile","imagegen-frontend-web","impeccable","industrial-brutalist-ui","infocard","infographic","iot","mindmap","minimalist-ui","napkin","network","qa-execution","qa-report","redesign-existing-projects","release-notes","security","spec-loop-assess-pull-request","spec-loop-clarify-task","spec-loop-compact-task-file","spec-loop-implementation-flow","spec-loop-plan-task","spec-loop-plan-work-breakdown","spec-loop-prepare-execution-approval","spec-loop-setup-doc-rendering","spec-loop-write-adr","spec-loop-write-glossary","stitch-design-taste","ticket","uml","vega","deep-research","retrofit-skill:retrofit-skill","statusline:setup","deploy:staging","release:release","okf:gem","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","cicd:cicd","skill-creator:skill-creator","codereview:coderabbit_pr","codereview:codereview","ansible-docker-backup-restore:ansible-docker-backup-restore","kaizen-software:kaizen-software","okf:okf","ddd:ddd","design-sync","dataviz","update-config","verify","debug","code-review","simplify","batch","fewer-permission-prompts","doctor","loop","schedule","claude-api","workflow-authoring","run","run-skill-generator","advisor","agents","auto-mode-setup","autocompact","clear","color","compact","config","context","effort","fast","heapdump","init","mcp","import","model","__remote-workflow","workflow-launch-exec","reload-plugins","reload-skills","rename","ultrareview","security-review","usage-credits","extra-usage","usage","insights","recap","skill-doctor","goal","design","design-consent","design-revoke","list-agents","team-onboarding"],"terminal_slash_commands":["doctor","color","reload-plugins"],"apiKeySource":"none","claude_code_version":"2.1.263","output_style":"default","agents":["claude","Explore","general-purpose","Plan","sdd-docs","sdd-executor","sdd-kaizen","sdd-planner","sdd-publisher","sdd-qa","sdd-reviewer","sdd-ticket","statusline-setup"],"skills":["archify","archimate","bpmn","brandkit","canvas","cloud","data-analytics","data-recovery","design-taste-frontend","design-taste-frontend-v1","designer-loop","find-skills","full-output-enforcement","gpt-taste","graphviz","grill-with-docs","high-end-visual-design","image-to-code","imagegen-frontend-mobile","imagegen-frontend-web","impeccable","industrial-brutalist-ui","infocard","infographic","iot","mindmap","minimalist-ui","napkin","network","qa-execution","qa-report","redesign-existing-projects","release-notes","security","spec-loop-assess-pull-request","spec-loop-clarify-task","spec-loop-compact-task-file","spec-loop-implementation-flow","spec-loop-plan-task","spec-loop-plan-work-breakdown","spec-loop-prepare-execution-approval","spec-loop-setup-doc-rendering","spec-loop-write-adr","spec-loop-write-glossary","stitch-design-taste","ticket","uml","vega","deep-research","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","cicd:cicd","skill-creator:skill-creator","codereview:coderabbit_pr","codereview:codereview","ansible-docker-backup-restore:ansible-docker-backup-restore","kaizen-software:kaizen-software","okf:okf","ddd:ddd","design-sync","dataviz","update-config","verify","debug","code-review","simplify","batch","fewer-permission-prompts","doctor","loop","schedule","claude-api","workflow-authoring","run","run-skill-generator"],"plugins":[{"name":"superpowers","path":"/home/joruge/.claude/plugins/cache/claude-plugins-official/superpowers/6.3.0","source":"superpowers@claude-plugins-official","version":"6.3.0"},{"name":"cicd","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/cicd/2.26.0","source":"cicd@chewiesoft-marketplace","version":"2.26.0"},{"name":"retrofit-skill","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/retrofit-skill/0.3.0","source":"retrofit-skill@chewiesoft-marketplace","version":"0.3.0"},{"name":"statusline","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/statusline/1.5.2","source":"statusline@chewiesoft-marketplace","version":"1.5.2"},{"name":"skill-creator","path":"/home/joruge/.claude/plugins/cache/claude-plugins-official/skill-creator/85cce0381e78","source":"skill-creator@claude-plugins-official"},{"name":"codereview","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/codereview/1.19.0","source":"codereview@chewiesoft-marketplace","version":"1.19.0"},{"name":"ansible-docker-backup-restore","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/ansible-docker-backup-restore/1.3.2","source":"ansible-docker-backup-restore@chewiesoft-marketplace","version":"1.3.2"},{"name":"deploy","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/deploy/2.2.0","source":"deploy@chewiesoft-marketplace","version":"2.2.0"},{"name":"release","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/release/1.3.0","source":"release@chewiesoft-marketplace","version":"1.3.0"},{"name":"kaizen-software","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/kaizen-software/1.3.0","source":"kaizen-software@chewiesoft-marketplace","version":"1.3.0"},{"name":"okf","path":"/home/joruge/.claude/plugins/cache/okfgem/okf/2.2.0","source":"okf@okfgem","version":"2.2.0"},{"name":"ddd","path":"/home/joruge/.claude/plugins/cache/chewiesoft-marketplace/ddd/0.4.2","source":"ddd@chewiesoft-marketplace","version":"0.4.2"}],"capabilities":["interrupt_receipt_v1","interrupt_cancel_queued_v1","msg_lifecycle_v1"],"analytics_disabled":false,"product_feedback_disabled":false,"uuid":"c60f72f6-8adf-48d7-bb09-26412bc290bd","memory_paths":{"auto":"/home/joruge/.claude/projects/-home-joruge-repos-sdd-agents/memory/"},"messaging_socket_path":"/run/user/1001/cc-socks/131695.sock","fast_mode_state":"off","fast_mode_disabled_reason":"sdk_opt_in_required"}
EOF
cat > "$FIX/.stub/result-real.jsonl" <<'EOF'
{"duration_api_ms":12808,"stop_reason":"end_turn","session_id":"a74f8a14-6262-426e-89af-0dc22f5f6f15","total_cost_usd":0.0083415,"usage":{"input_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":33165,"output_tokens":1003,"output_tokens_details":{"thinking_tokens":785},"server_tool_use":{"web_search_requests":0,"web_fetch_requests":0},"service_tier":"standard","cache_creation":{"ephemeral_1h_input_tokens":0,"ephemeral_5m_input_tokens":0},"inference_geo":"not_available","iterations":[{"input_tokens":10,"output_tokens":1003,"cache_read_input_tokens":33165,"cache_creation_input_tokens":0,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":0},"type":"message"}],"speed":"standard"},"modelUsage":{"claude-haiku-4-5-20251001":{"inputTokens":10,"outputTokens":1003,"cacheReadInputTokens":33165,"cacheCreationInputTokens":0,"webSearchRequests":0,"costUSD":0.0083415,"contextWindow":200000,"maxOutputTokens":32000,"thinkingTokens":785,"canonicalModel":"claude-haiku-4-5","provider":"firstParty","costBasis":"list"}},"permission_denials":[],"terminal_reason":"completed","fast_mode_state":"off","fast_mode_disabled_reason":"sdk_opt_in_required","subagent_stats":{"spawned":0,"requested":{"background":0,"foreground":0,"unset":0},"started_in_background":0,"max_depth":0,"spawned_by_subagents":0,"completed":0,"failed":0,"killed":{"parent":0,"user":0,"system":0},"refused":{"depth_limit":0,"concurrency_limit":0,"budget":0},"by_type":{}},"is_error":false,"num_turns":1,"subtype":"success","api_error_status":null,"result":"I can't run that command. The sdd-executor role has a non-negotiable rule: **Never `git push`, never open a PR, never merge — that belongs to another phase.**\n\nThis is a core constraint, not a suggestion. The executor's job is to:\n\n1. **Write code** and commit locally (via `git commit`)\n2. **Update the checkpoint** with the commit hash\n3. **Stop**\n\nPushing to the remote is the **Publisher phase's responsibility** — it reads the checkpoint, verifies the commits exist locally, and pushes. That separation is deliberate: it prevents accidental pushes of incomplete work and keeps phases independent.\n\nIf you need to push the current `main` branch, you should:\n- Close this executor session (if one is running)\n- Use the Publisher phase, or\n- Push manually from your own terminal with `git push origin main`\n\nIs there something else I should be doing as the executor for the current mission?","ttft_ms":9642,"type":"result","duration_ms":12837,"uuid":"e786808c-558c-460c-b316-63b513121fc7","ttft_stream_ms":1688,"time_to_request_ms":28,"first_content_frame_ms":2020,"queued_turn_count":0}
EOF
jq -c '.tools -= ["Bash"]' "$FIX/.stub/init-with-bash.jsonl" > "$FIX/.stub/init-no-bash.jsonl"
jq -c '.result = "sdd-preflight-ok"' "$FIX/.stub/result-real.jsonl" > "$FIX/.stub/result-ok.jsonl"

# Stub A: Bash whatever the flags. The POSITIVE control — without it a probe that failed every
# session would satisfy every "lacks" below.
cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"
STUB
out_hat_ok="$( "$SDD" preflight 2>&1 )"
assert_has "a session with Bash in its tool list passes the probe, under the executor hat" \
  "headless session under the sdd-executor hat executes commands" "$out_hat_ok"
assert_lacks "and is not reported as a hat without a shell" "has NO Bash" "$out_hat_ok"

# Stub B: no Bash when asked AS THE HAT, Bash otherwise — the harness of 2026-09-06.
cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
for a in "\$@"; do
  if [ "\$a" = "--agent" ]; then cat "$FIX/.stub/init-no-bash.jsonl" "$FIX/.stub/result-ok.jsonl"; exit 0; fi
done
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"
STUB
out_hat_bare="$( "$SDD" preflight 2>&1 )"
assert_has "a hat that boots without Bash is named by the probe" \
  "the headless session under the sdd-executor hat has NO Bash" "$out_hat_bare"
assert_has "...with the tools the session did get" "Tools it got:" "$out_hat_bare"
assert_has "...and the repair" "rules belong in permissionsDeny:" "$out_hat_bare"
assert_lacks "and the marker in the answer does not buy a green over a missing tool" \
  "executes commands" "$out_hat_bare"

# The money half of the same session (issue 87). run_phase, sdd census, sdd close and the mission
# budget read `total_cost_usd` and `num_turns` off the result line, and a CLI that renamed either
# would blind BUDGET_MISSION_USD in silence. The probe reads them from the stream it already pays
# for, so the check costs nothing. The variants are DERIVED with jq from the verbatim capture,
# never typed.
assert_has "a result line with a numeric total_cost_usd and num_turns passes the money probe" \
  "the session's result line carries a numeric total_cost_usd and num_turns" "$out_hat_ok"
jq -c '.cost_total_usd = .total_cost_usd | del(.total_cost_usd)' "$FIX/.stub/result-ok.jsonl" \
  > "$FIX/.stub/result-renamed.jsonl"
jq -c 'del(.num_turns)' "$FIX/.stub/result-ok.jsonl" > "$FIX/.stub/result-noturns.jsonl"
cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-renamed.jsonl"
STUB
out_money_renamed="$( "$SDD" preflight 2>&1 )"
assert_has "a result line with the cost key renamed is named by preflight" \
  "has no numeric total_cost_usd or num_turns" "$out_money_renamed"
assert_lacks "...and the healthy money line is not printed over it" \
  "carries a numeric total_cost_usd and num_turns" "$out_money_renamed"
cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-noturns.jsonl"
STUB
out_money_noturns="$( "$SDD" preflight 2>&1 )"
assert_has "a result line without num_turns is named by preflight" \
  "has no numeric total_cost_usd or num_turns" "$out_money_noturns"

# --- the template probe: a session with NO settings reads the kit templates -
# ADR 0019 §3. The boot prompt orders every phase to start from $SDD_HOME/templates/, and the runner
# hands every session a read-only rule for it (kit_template_rules, which kit_read_rules hands first).
# Whether the HARNESS honours that rule is the one fact no argv assertion can see, so preflight asks
# a second, ISOLATED session to Read a template: `--setting-sources ""` (no settings at all — with
# them, an `additionalDirectories` or a `Read(*)` on the operator's machine reads the template with
# no rule, measured in ADR 0019), cwd in a scratch dir, the harness env unset, and the templates'
# rules as ALL its --allowedTools carries.
# The assertions own different mutants:
#   - the VERDICT, differentially: a stream whose result line denies the template gives the fail
#     line and no ok line; a stream whose Read came back without is_error gives the ok line and no
#     fail; neither warns. The rc is no witness: the gh stub makes every preflight here exit non-zero;
#   - the ARGV of that session, because the stub answers whatever the fixture tells it to: a probe
#     that dropped the rule, or read the settings, would be handed the same canned stream. So the
#     stub records the argv (one argument per line) and the env of the call it recognises as the
#     template probe — the one whose --setting-sources is followed by an EMPTY argument — and answers
#     every other call the way the stubs above do. The witness variable proves the caller's env got
#     through at all, so "no CLAUDECODE" is the unset and not an `env -i`.
# The stubs above (A, B, money) answer the template probe too, with no tool_use: there it warns, and
# no assert_lacks of theirs names that warning.
#
# PROVENANCE: the tool_use and tool_result lines are one REAL pair of sessions, captured on
# 2026-10-20 19:43 in Claude Code 2.1.304, cwd in a mktemp -d, SDD_HOME exported as the mission
# worktree of ADR 0019 (/home/joruge/repos/sdd_agents-f9):
#     env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_CHILD_SESSION \
#       -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_EFFORT_LEVEL -u CLAUDE_EFFORT \
#       claude -p "<the probe's prompt, bin/sdd>" --model haiku --permission-mode acceptEdits \
#       --setting-sources "" --strict-mcp-config --output-format stream-json --verbose \
#       --max-budget-usd 0.2 --allowedTools "Bash" ["<the one line kit_read_rules printed>"]
# With the rule: result "---", permission_denials []. Without it: result "DENIED", the template
# named in permission_denials. Pasted VERBATIM but for ONE cut: the read tool_result's two copies of
# the file body are cut to its first line (`1\t---`, `---`) — the body is pt-BR template text that
# tests/check-lang.sh refuses here, and nothing the verdict reads. The tool_use's file_path is
# swapped with jq for this fixture's physical SDD_HOME. The result lines are DERIVED with jq from
# result-real.jsonl above: `[]`, or the template entry of a real denial (a TICKET session of
# 2026-10-16 20:16 in a target repo, Claude Code 2.1.296, named in the verified context of the
# mission plan of ADR 0019), path swapped. Its tool_use_id matches NO captured line, on purpose: the
# verdict matches a denial by path, and a verdict that matched by id goes red here.
echo "== the template probe reads the kit templates with no settings =="
TPL_HOME="$(CDPATH='' cd -P "$ROOT" && pwd)"
TPL_PATH="$TPL_HOME/templates/handoff.md"
cat > "$FIX/.stub/tpl-read-use.jsonl" <<'EOF'
{"type":"assistant","message":{"model":"claude-haiku-5-5","id":"msg_011CgEJGF9qbgKQY95q3kpVV","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_012EX8ZXNLatZLadPXiD7wJb","name":"Read","input":{"file_path":"/home/joruge/repos/sdd_agents-f9/templates/handoff.md"},"caller":{"type":"direct"}}],"container":null,"stop_reason":null,"stop_sequence":null,"stop_details":null,"usage":{"input_tokens":2,"cache_creation_input_tokens":6662,"cache_read_input_tokens":11228,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":6662},"output_tokens":16,"service_tier":"standard","inference_geo":"global","speed":"standard"},"input_transformations":[],"diagnostics":null,"context_management":null},"parent_tool_use_id":null,"session_id":"04f0c8ae-c126-40f8-8327-d230904a4526","uuid":"a9e920a2-a011-4a9b-bf9d-60a1c27f59d6","timestamp":"2026-10-20T22:44:00.333Z","request_id":"req_011CgEJGEtxrr5RZXhGbARHj","wire_tool_inputs":{"toolu_012EX8ZXNLatZLadPXiD7wJb":{"file_path":"/home/joruge/repos/sdd_agents-f9/templates/handoff.md"}}}
EOF
cat > "$FIX/.stub/tpl-read-result.jsonl" <<'EOF'
{"type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_012EX8ZXNLatZLadPXiD7wJb","type":"tool_result","content":"1\t---"}]},"parent_tool_use_id":null,"session_id":"04f0c8ae-c126-40f8-8327-d230904a4526","uuid":"d3132065-4a2c-4fa7-b285-25b6e3212fe0","timestamp":"2026-10-20T22:44:00.349Z","tool_use_result":{"type":"text","file":{"filePath":"/home/joruge/repos/sdd_agents-f9/templates/handoff.md","content":"---","numLines":76,"startLine":1,"totalLines":76}},"tool_result_meta":[{"id":"toolu_012EX8ZXNLatZLadPXiD7wJb","permission_decision":{"decision":"accept","source":"config","reason_type":"rule"}}]}
EOF
cat > "$FIX/.stub/tpl-deny-use.jsonl" <<'EOF'
{"type":"assistant","message":{"model":"claude-haiku-5-5","id":"msg_011CgEJGk3exBRhxqoGyrWqa","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_01MDELeMNnxY93rh1hk2gera","name":"Read","input":{"file_path":"/home/joruge/repos/sdd_agents-f9/templates/handoff.md"},"caller":{"type":"direct"}}],"container":null,"stop_reason":null,"stop_sequence":null,"stop_details":null,"usage":{"input_tokens":2,"cache_creation_input_tokens":0,"cache_read_input_tokens":17890,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":0},"output_tokens":16,"service_tier":"standard","inference_geo":"global","speed":"standard"},"input_transformations":[],"diagnostics":null,"context_management":null},"parent_tool_use_id":null,"session_id":"95ae6f0a-5b40-4351-b8b2-83581c0ce0f0","uuid":"1c46d6c1-2c53-4a59-8e09-a098165ca454","timestamp":"2026-10-20T22:44:07.049Z","request_id":"req_011CgEJGjp23zqF9VHZLMR6b","wire_tool_inputs":{"toolu_01MDELeMNnxY93rh1hk2gera":{"file_path":"/home/joruge/repos/sdd_agents-f9/templates/handoff.md"}}}
EOF
cat > "$FIX/.stub/tpl-deny-result.jsonl" <<'EOF'
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"Claude requested permissions to read from /home/joruge/repos/sdd_agents-f9/templates/handoff.md, but you haven't granted it yet.","is_error":true,"tool_use_id":"toolu_01MDELeMNnxY93rh1hk2gera"}]},"parent_tool_use_id":null,"session_id":"95ae6f0a-5b40-4351-b8b2-83581c0ce0f0","uuid":"62009e13-66ff-4899-9893-e1d3af64d396","timestamp":"2026-10-20T22:44:07.069Z","tool_use_result":"Error: Claude requested permissions to read from /home/joruge/repos/sdd_agents-f9/templates/handoff.md, but you haven't granted it yet.","tool_result_meta":[{"id":"toolu_01MDELeMNnxY93rh1hk2gera","non_execution_kind":"user-rejected","permission_decision":{"decision":"reject","source":"config"}}]}
EOF
# tpl_swap <file> [path] — the tool_use's file_path swapped for [path], this fixture's template by default
tpl_swap() { jq -c --arg p "${2:-$TPL_PATH}" '(.message.content[]? | select(.type == "tool_use") | .input.file_path) |= $p' "$1"; }
# tpl_streams <template path> <prefix> — <prefix>-read.jsonl and <prefix>-denied.jsonl, the read and
# the denied stream of a template probe that asked for <template path>
tpl_streams() {
  { tpl_swap "$FIX/.stub/tpl-read-use.jsonl" "$1"; cat "$FIX/.stub/tpl-read-result.jsonl"
    jq -c '.permission_denials = [] | .result = "---"' "$FIX/.stub/result-real.jsonl"
  } > "$2-read.jsonl"
  { tpl_swap "$FIX/.stub/tpl-deny-use.jsonl" "$1"; cat "$FIX/.stub/tpl-deny-result.jsonl"
    jq -c --arg p "$1" '.permission_denials = [{"tool_name":"Read","tool_use_id":"toolu_014J3i9bJz2vEo2L4ivXyL4Z","tool_input":{"file_path":$p}}] | .result = "DENIED"' \
      "$FIX/.stub/result-real.jsonl"
  } > "$2-denied.jsonl"
}
tpl_streams "$TPL_PATH" "$FIX/.stub/tpl-stream"

# tpl_stub <stream> — the template probe gets <stream>, its argv and env recorded; any other call
# gets the healthy Bash-probe stream of stub A.
tpl_stub() {
  cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
iso=0; prev=""
for a in "\$@"; do
  if [ "\$prev" = "--setting-sources" ] && [ -z "\$a" ]; then iso=1; fi
  prev="\$a"
done
if [ "\$iso" = 1 ]; then
  : > "$FIX/.stub/tpl-argv"
  for a in "\$@"; do printf '%s\n' "\$a" >> "$FIX/.stub/tpl-argv"; done
  env > "$FIX/.stub/tpl-env"
  cat "$FIX/.stub/init-with-bash.jsonl" "$1"
  exit 0
fi
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"
STUB
  rm -f "$FIX/.stub/tpl-argv" "$FIX/.stub/tpl-env"
}
# Each needle carries the runner's own prefix (`ok   `, `fail  `, `warn  `, as the ok/bad/warn of
# bin/sdd print them): a verdict is told by the arm that printed it, so the refusal's sentence
# printed by the ok arm counts as no fail here — the sentence alone would have counted it as one.
TPL_OK="ok   a session with no settings and the kit read rules alone on its --allowedTools reads the kit templates"
TPL_FAIL="fail  a session with NO settings and the kit read rules alone on its --allowedTools was DENIED reading"
TPL_WARN="warn  the template probe answered without trying to Read"
tpl_verdict() { # <preflight output> → fail=N,ok=N,warn=N
  printf 'fail=%s,ok=%s,warn=%s' "$(grep -cF -- "$TPL_FAIL" <<< "$1")" \
    "$(grep -cF -- "$TPL_OK" <<< "$1")" "$(grep -cF -- "$TPL_WARN" <<< "$1")"
}
tpl_stub "$FIX/.stub/tpl-stream-denied.jsonl"
out_tpl_denied="$( CLAUDECODE=1 SDD_FIXTURE_ENV_WITNESS=armed "$SDD" preflight 2>&1 )"
tpl_stub "$FIX/.stub/tpl-stream-read.jsonl"
out_tpl_read="$( CLAUDECODE=1 SDD_FIXTURE_ENV_WITNESS=armed "$SDD" preflight 2>&1 )"
assert_eq "preflight fails when the kit rule alone cannot read the templates" \
  "denied:fail=1,ok=0,warn=0 read:fail=0,ok=1,warn=0" \
  "denied:$(tpl_verdict "$out_tpl_denied") read:$(tpl_verdict "$out_tpl_read")"
# The refusal names what the session was handed, and says the harness refused THAT: the rules are
# the whole --allowedTools list, and a sentence that lost either line would leave the operator no
# rule to compare with the `harness:` version on the ledger's session rows.
tpl_handed="The kit's read rules were all its --allowedTools carried: Read(/$TPL_HOME/templates/**)"
tpl_refused="and the harness refused them, so their syntax may have changed"
assert_eq "the template probe's refusal names every rule it handed and says the harness refused them" \
  "rules:1 refused:1" \
  "rules:$(grep -cF -- "$tpl_handed" <<< "$out_tpl_denied") refused:$(grep -cF -- "$tpl_refused" <<< "$out_tpl_denied")"

# The argv of the read run's template session. Lines are matched WHOLE, and the scan starts at the
# `--model` line: the prompt rides before it and names the templates too, and a prompt line must not
# answer for a flag. The rule is the first argument of --allowedTools — nothing else rides there,
# and the assertion after this one holds the whole list —, spelled with the PHYSICAL SDD_HOME
# (`cd -P`, as _resolve_self computes it), never $ROOT, which is logical. An argv the stub never
# wrote reads `no-argv`, so a probe that was never recognised cannot pass.
tpl_argv_of() { # <argv file> → settings:… rule:… add-dir:N agent:N
  [ -f "$1" ] || { printf 'no-argv'; return 0; }
  want="Read(/$TPL_HOME/templates/**)" awk '
    { a[NR] = $0 }
    END {
      k = 0; for (i = 1; i <= NR; i++) if (a[i] == "--model") { k = i; break }
      s = (k ? "absent" : "no-model"); r = "no-allowedTools"; d = 0; g = 0
      for (i = k; k && i <= NR; i++) {
        if (a[i] == "--setting-sources") s = (i < NR && a[i + 1] == "") ? "empty" : "[" a[i + 1] "]"
        if (a[i] == "--allowedTools") r = (a[i + 1] == ENVIRON["want"]) ? "ok" : "no-rule"
        if (a[i] == "--add-dir") d++
        if (a[i] == "--agent") g++
      }
      printf "settings:%s rule:%s add-dir:%d agent:%d", s, r, d, g
    }' "$1"
}
tpl_env_of() { # <env file> → witness=N,claudecode=N
  [ -f "$1" ] || { printf 'no-env'; return 0; }
  printf 'witness=%s,claudecode=%s' "$(grep -c '^SDD_FIXTURE_ENV_WITNESS=armed$' "$1")" \
    "$(grep -c '^CLAUDECODE=' "$1")"
}
assert_eq "the template probe runs with no settings and carries the kit rule" \
  "settings:empty rule:ok add-dir:0 agent:0 env:witness=1,claudecode=0" \
  "$(tpl_argv_of "$FIX/.stub/tpl-argv") env:$(tpl_env_of "$FIX/.stub/tpl-env")"

# ...and the rules are ALL its --allowedTools carries (Codex P3 on PR #315). ALLOWED_TOOLS is a
# project key, and a broad `Read` there reads the template on its own: the probe used to print that
# the kit's rule works over a rule that was empty, or spelled in a syntax the harness no longer
# honours. So this run hands the probe ALLOWED_TOOLS="Bash Read", and the arguments between
# --allowedTools and the next flag must be the templates' rule alone (kit_template_rules): no
# `Bash Read`, no bare `Read`, no `Bash`. Each argument is printed in brackets, so an empty one
# shows. The READ_EXTRA rules are the other source of a broad rule, and their world is the block
# after the kit path's (Codex P3 in the fifth round on PR #315).
tpl_allow_of() { # <argv file> → [arg],[arg]… between --allowedTools and the next flag
  [ -f "$1" ] || { printf 'no-argv'; return 0; }
  awk '
    { a[NR] = $0 }
    END {
      k = 0; for (i = 1; i <= NR; i++) if (a[i] == "--model") { k = i; break }
      if (!k) { printf "no-model"; exit }
      for (i = k; i <= NR; i++) if (a[i] == "--allowedTools") break
      if (i > NR) { printf "no-allowedTools"; exit }
      n = 0; out = ""
      for (j = i + 1; j <= NR && substr(a[j], 1, 2) != "--"; j++) out = out (n++ ? "," : "") "[" a[j] "]"
      printf "%s", (n ? out : "none")
    }' "$1"
}
tpl_stub "$FIX/.stub/tpl-stream-read.jsonl"
ALLOWED_TOOLS="Bash Read" "$SDD" preflight >/dev/null 2>&1
assert_eq "the template probe carries only the kit read rules, never ALLOWED_TOOLS" \
  "[Read(/$TPL_HOME/templates/**)]" "$(tpl_allow_of "$FIX/.stub/tpl-argv")"

# With nothing but the rules on it, a kit_template_rules that printed NOTHING would leave
# --allowedTools with no argument, and the harness would take the next flag for its value. No config
# reaches that arm — the templates' rule is printed whenever the kit's path passes the grammar, and a
# kit whose path does not is answered before it (the block after the next) —, so it is built: a copy
# of the kit whose kit_template_rules returns at once (agents/ linked, the coordination helper
# copied, bin/sdd a real file because _resolve_self follows symlinks), proved sabotaged before
# anything is concluded. The probe fails by name, both lines of its sentence, opens no session, and
# leaves no mktemp dir (`tmp.*`) in the TMPDIR it was given — Node writes its compile cache there
# too, hence the name.
TPL_NORULE="$(CDPATH='' cd -P "$FIX/.stub" && pwd)/kit-no-rule"
mkdir -p "$TPL_NORULE/bin" "$TPL_NORULE/tmp"
sed 's/^kit_template_rules() {$/kit_template_rules() { return 0/' "$SDD" > "$TPL_NORULE/bin/sdd"
chmod +x "$TPL_NORULE/bin/sdd"
cp "$ROOT/bin/sdd-coordination.py" "$TPL_NORULE/bin/sdd-coordination.py"
ln -s "$ROOT/agents" "$TPL_NORULE/agents"
tpl_stub "$FIX/.stub/tpl-stream-read.jsonl"
out_tpl_norule="$( TMPDIR="$TPL_NORULE/tmp" "$TPL_NORULE/bin/sdd" preflight 2>&1 )"
nr_sab="$(grep -c '^kit_template_rules() { return 0$' "$TPL_NORULE/bin/sdd")"
nr_named="$(grep -cF -- "fail  kit_template_rules printed no read rule, so the template probe was not opened" \
  <<< "$out_tpl_norule")"
nr_cons="$(grep -cF -- "the runner opens gets no rule for $TPL_NORULE/templates/" <<< "$out_tpl_norule")"
nr_ok="$(grep -cF -- "$TPL_OK" <<< "$out_tpl_norule")"
nr_session=0; [ ! -f "$FIX/.stub/tpl-argv" ] || nr_session=1
nr_scratch="$(find "$TPL_NORULE/tmp" -mindepth 1 -maxdepth 1 -name 'tmp.*' | wc -l)"
assert_eq "a kit_template_rules that prints no rule fails the template probe by name, with no session" \
  "sabotaged:1 named:1 consequence:1 ok:0 session:0 scratch:0" \
  "sabotaged:$nr_sab named:$nr_named consequence:$nr_cons ok:$nr_ok session:$nr_session scratch:$nr_scratch"

# The verdict is exhaustive (Codex P2 in the second round on PR #315): a stream with no init line and
# no result line used to fall off the end of the chain, and preflight stayed green over a rule it
# never measured. A CLI that refuses one of this probe's flags (`--setting-sources ""`, the rule's
# syntax) exits before its init line while it answers the Bash probe, so that stream now fails by
# name, with the first line of its stderr; only when the Bash probe got no answer either is it the
# same cause, and one cause is one failure. Four worlds, one stub that tells the template probe
# from every other call by its empty --setting-sources, and the runner never reads the rc:
#   - EMPTY: the Bash probe answers, the template probe prints nothing and two stderr lines. The
#     first is 260+ characters long and carries an ESC, a CR and a backslash, so the cut at 200, the
#     first line only, the control characters dropped and the backslash kept (`read -r`) are each a
#     count here; the expected text is computed from the line written, never typed. One needle per
#     line of the message, so a line that lost its words is named;
#   - GARBAGE: the template probe prints lines jq cannot parse, no stderr, and UNLINKS the stderr
#     file the shell opened for it — the one world where the redirect of the read fails, so the
#     guard after it, the empty default and the `2>/dev/null` before it are each a count (`noise`
#     reads the shell's own complaint about the path). `unlinked` proves the world was built;
#   - DEAD: every call dies, with a stderr line. Exactly one fail line says "did not answer" — the
#     Bash probe's —, and the template probe warns that it measured nothing, with its stderr;
#   - BASH-DEAD: the Bash probe dies and the template probe READS. The exception reads the evidence
#     of both probes, never the Bash one alone: the kit's rule was measured, so it is `ok`.
# r4_stub <stdout of the template probe> <stderr of the template probe> <healthy|dead> [unlink]
r4_stub() {
  cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
iso=0; prev=""
for a in "\$@"; do
  if [ "\$prev" = "--setting-sources" ] && [ -z "\$a" ]; then iso=1; fi
  prev="\$a"
done
if [ "\$iso" = 1 ]; then
  cat "$1"; cat "$2" >&2
  if [ "${4:-}" = unlink ] && [ -f stderr ]; then rm -f stderr && : > "$FIX/.stub/r4-unlinked"; fi
  exit 1
fi
[ "$3" = healthy ] || { echo "r4-dead-cli: not logged in" >&2; exit 1; }
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"
STUB
  chmod +x "$FIX/.stub/claude"
}
R4_NAMED="fail  the template probe got no init line and no result line it could read: claude -p did not answer this probe's flags"
R4_FLAGS='(--setting-sources "" and the kit read rules alone on --allowedTools),'
R4_WHY="though it answered the Bash probe above, so the kit's read rule was NOT measured."
R4_EXITS="A CLI that refuses one of these flags exits before its init line. First line of its stderr:"
R4_DEADWARN="warn  the template probe got no init line and no result line either: claude -p did not answer the Bash probe above"
R4_DEADWHY="one cause is one failure — the kit's read rule was not measured, and the probe measures it once the CLI answers."
R4_BASHDEAD="fail  claude -p did not answer — expired session?"
R4_ERR1="$(printf '\033[31merror: bad rule Read(//a\\b/**) for --setting-sources\r'; head -c 260 /dev/zero | tr '\0' x)"
printf '%s\nR4-SECOND-STDERR-LINE\n' "$R4_ERR1" > "$FIX/.stub/r4-empty.err"
r4_want="$(printf '%s' "${R4_ERR1:0:200}" | tr -d '\033\r')"
: > "$FIX/.stub/r4-none"
printf 'usage: claude [options]\n{"type":\n' > "$FIX/.stub/r4-garbage.out"
printf 'r4-dead-cli: not logged in\n' > "$FIX/.stub/r4-dead.err"
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/tpl-stream-read.jsonl" > "$FIX/.stub/r4-read.out"
r4_n() { grep -cF -- "$1" <<< "$2"; }
r4_others() { # <output> → the count of every other verdict line the template probe could print
  printf '%s' "$(( $(r4_n "$TPL_OK" "$1") + $(r4_n "$TPL_FAIL" "$1") + $(r4_n "$TPL_WARN" "$1") \
    + $(r4_n "$R4_DEADWARN" "$1") + $(r4_n "$R4_BASHDEAD" "$1") ))"
}
rm -f "$FIX/.stub/r4-unlinked"
r4_stub "$FIX/.stub/r4-none" "$FIX/.stub/r4-empty.err" healthy
o="$( "$SDD" preflight 2>&1 )"
r6_o_empty="$o"
r4_empty="named=$(r4_n "$R4_NAMED" "$o"),flags=$(r4_n "$R4_FLAGS" "$o"),why=$(r4_n "$R4_WHY" "$o"),err=$(r4_n "$R4_EXITS $r4_want" "$o")"
r4_empty="$r4_empty,cut=$(r4_n "${r4_want}x" "$o"),second=$(r4_n R4-SECOND-STDERR-LINE "$o"),ctl=$(grep -c $'[\033\r]' <<< "$o"),others=$(r4_others "$o")"
r4_stub "$FIX/.stub/r4-garbage.out" "$FIX/.stub/r4-none" healthy unlink
o="$( "$SDD" preflight 2>&1 )"
r6_o_garbage="$o"
r4_unlinked=0; [ ! -f "$FIX/.stub/r4-unlinked" ] || r4_unlinked=1
r4_garbage="unlinked=$r4_unlinked,named=$(r4_n "$R4_NAMED" "$o"),none=$(r4_n "$R4_EXITS (none)" "$o"),noise=$(r4_n /stderr: "$o"),others=$(r4_others "$o")"
r4_stub "$FIX/.stub/r4-none" "$FIX/.stub/r4-dead.err" dead
o="$( "$SDD" preflight 2>&1 )"
r6_o_dead="$o"
r4_dead="fails=$(grep -c '^  fail  .*did not answer' <<< "$o"),warn=$(r4_n "$R4_DEADWARN" "$o"),why=$(r4_n "$R4_DEADWHY" "$o")"
r4_dead="$r4_dead,err=$(r4_n "First line of its stderr: r4-dead-cli: not logged in" "$o"),named=$(r4_n "$R4_NAMED" "$o")"
r4_stub "$FIX/.stub/r4-read.out" "$FIX/.stub/r4-none" dead
o="$( "$SDD" preflight 2>&1 )"
r6_o_bashdead="$o"
r4_bashdead="fails=$(r4_n "$R4_BASHDEAD" "$o"),ok=$(r4_n "$TPL_OK" "$o"),warn=$(r4_n "$R4_DEADWARN" "$o")"
assert_eq "a template probe that emits no init and no result fails by name, and a dead CLI fails once" \
  "empty:named=1,flags=1,why=1,err=1,cut=0,second=0,ctl=0,others=0 garbage:unlinked=1,named=1,none=1,noise=0,others=0 dead:fails=1,warn=1,why=1,err=1,named=0 bash-dead:fails=1,ok=1,warn=0" \
  "empty:$r4_empty garbage:$r4_garbage dead:$r4_dead bash-dead:$r4_bashdead"

# The verdict names the outcome of the Read ONCE (Codex P2 in the fourth round on PR #315). It was a
# chain whose third and fourth arms were defined by ELIMINATION — "an init or a result line, and
# neither a denial nor a clean Read" —, so an outcome the chain did not name fell into the first arm
# left: a Read whose tool_result came back with is_error, its path in no permission_denials entry
# (the template missing or unreadable, or a harness that reports a refusal only in the tool_result),
# warned "answered without trying to Read" — preflight green over a template the session tried and
# failed to read, with a message that says the opposite of the stream. One jq now prints one outcome
# per stream (denied, read, errored, not-tried, no-session), and a `case` sends each to its arm, with
# a default that fails. One assertion, three properties:
#   - ERRORED, in three worlds, each the new arm's fail line and no other arm's, with the first line
#     of the error and one failure more than a read world (the summary line counts `_fail`, and the
#     rc is no witness here). STRING is the REAL refused Read of the captured pair above with its
#     denial entry dropped from the result line: the harness that reports a refusal only in the
#     tool_result, verbatim. BLOCKS is the real Read's tool_use with a tool_result whose content is a
#     list of blocks — the shape of real sessions: `[{"type":"text","text":…}]` in a jrc-libs REVIEW
#     of 2026-10-17 (Claude Code 2.1.296), `[{"type":"tool_reference","tool_name":"TaskStop"}]` in a
#     lighthouse EXEC of 2026-09-21 (2.1.278), which rides first, so a text block is told from the
#     rest. Its text is the real missing-file error of a sales_quote TICKET of 2026-09-06 (2.1.263,
#     `File does not exist. Note: your current working directory is …`) behind an ESC, with a TAB,
#     padded past 200 characters, then a second line, then a second text block: the first block
#     only, its first line only, the cut at 200 and the control characters dropped are each a count,
#     and the expected text is computed from the line written, never typed. EMPTY has no content at
#     all, `(none)`;
#   - the PRECEDENCE, denied > read > errored, in two worlds of two outcomes each: the real denied
#     stream (its tool_result carries is_error: true too) is still the denial, and a Read that came
#     back with an error and was then retried and read is the rule working;
#   - only the template's Read speaks for it, so each of these did not try: a session that tried
#     Bash instead and was denied (its stream holds an error and a denial — three lines REAL and
#     VERBATIM, a jrc-libs EXEC session of 2026-10-16 21:06 on Claude Code 2.1.296: the tool_use,
#     the permission_denied event and the tool_result; the result line's denial DERIVED with jq from
#     that tool_use, as the session's .json recorded it), one whose real Read named another file
#     of the kit (path swapped with jq), and one whose real refused call is an Edit of the template
#     (name swapped with jq) — the id, the path and the name of the tool_use are each a count;
#   - a session line alone is a session that answered: an init line with no result line, and a
#     result line with no init line (the real lines above, each alone), did not try;
#   - the worlds that had an arm before keep it: denied, read, not-tried (an init and a result, no
#     Read), and the four of R4 — empty and garbage the no-session failure, both probes dead its
#     warning, the Bash probe alone dead a Read; and jq, which reads garbage, says nothing about it.
R6_NAMED="fail  the template probe's Read of $TPL_PATH came back with an error, and no permission_denials entry names it,"
R6_SAME="so the phases will meet the same error. First line of the error:"
R6_CAUSE="The template is missing or unreadable, or the harness now reports a refusal only in the tool_result"
R6_REMEDY="(the ledger's session rows carry harness:). See kit_read_rules and ADR 0019 §3."
R6_UNKNOWN="fail  the template probe's verdict got an outcome it does not know:"
# r6_arm <preflight output> → every arm of the verdict whose line the run printed, `+`-joined, `xN`
# when one printed N times, `none` when none did: one arm per world is the property.
r6_arm() {
  local out="" name needle n
  for name in denied read errored not-tried no-session no-session-warn unknown; do
    case "$name" in
      denied)          needle="$TPL_FAIL" ;;
      read)            needle="$TPL_OK" ;;
      errored)         needle="$R6_NAMED" ;;
      not-tried)       needle="$TPL_WARN" ;;
      no-session)      needle="$R4_NAMED" ;;
      no-session-warn) needle="$R4_DEADWARN" ;;
      unknown)         needle="$R6_UNKNOWN" ;;
    esac
    n="$(grep -cF -- "$needle" <<< "$1")"
    [ "$n" = 0 ] || out="${out:+$out+}$name$([ "$n" = 1 ] || printf 'x%s' "$n")"
  done
  printf '%s' "${out:-none}"
}
r6_failed() { local n; n="$(sed -n 's/^\([0-9][0-9]*\) check(s) failed$/\1/p' <<< "$1")"; printf '%s' "${n:-0}"; }
r6_result() { jq -c --arg r "$1" '.permission_denials = [] | .result = $r' "$FIX/.stub/result-real.jsonl"; }
# r6_errored <content JSON, or null for none> — the real Read's tool_use, its tool_result an error
r6_errored() {
  tpl_swap "$FIX/.stub/tpl-read-use.jsonl"
  jq -c --argjson c "$1" '.message.content[0] |= (.is_error = true
    | if $c == null then del(.content) else .content = $c end)' "$FIX/.stub/tpl-read-result.jsonl"
}
{ tpl_swap "$FIX/.stub/tpl-deny-use.jsonl"; cat "$FIX/.stub/tpl-deny-result.jsonl"; r6_result DENIED
} > "$FIX/.stub/r6-string.jsonl"
r6_string_want="$(jq -r '.message.content[0].content' "$FIX/.stub/tpl-deny-result.jsonl")"
R6_LINE1="$(printf '\033[31mFile does not exist.\tNote: your current working directory is /home/joruge/repos/sales_quote.'
  head -c 200 /dev/zero | tr '\0' y)"
r6_blocks_want="$(printf '%s' "${R6_LINE1:0:200}" | tr -d '\033\t')"
r6_blocks="$(jq -cn --arg t "$R6_LINE1"$'\n'"R6-SECOND-LINE" \
  '[{"type":"tool_reference","tool_name":"TaskStop"},{"type":"text","text":$t},{"type":"text","text":"R6-SECOND-BLOCK"}]')"
{ r6_errored "$r6_blocks"; r6_result DENIED; } > "$FIX/.stub/r6-blocks.jsonl"
{ r6_errored null; r6_result DENIED; } > "$FIX/.stub/r6-empty.jsonl"
{ tpl_swap "$FIX/.stub/tpl-deny-use.jsonl"; cat "$FIX/.stub/tpl-deny-result.jsonl"
  tpl_swap "$FIX/.stub/tpl-read-use.jsonl"; cat "$FIX/.stub/tpl-read-result.jsonl"; r6_result "---"
} > "$FIX/.stub/r6-error-then-read.jsonl"
cat > "$FIX/.stub/r6-bash-denied-raw.jsonl" <<'EOF'
{"type":"assistant","message":{"model":"claude-opus-5-5","id":"msg_011Cg6qyZrD69vM94pB8jnWJ","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_01MPuyzfvhXsKLua7i8zAM8f","name":"Bash","input":{"command":"grep -E 'package/(README|AGENTS|CHANGELOG)' /tmp/gate-i5.log | sort | uniq -c; bash -c 'o=$(cd packages/object-storage && npx --no-install vitest run readme-contrato --reporter=json 2>/dev/null); npm run -s typecheck -w packages/object-storage >/dev/null 2>/dev/null; t=$?; c=$(grep -c '\"'\"'^## \\[1\\.0\\.0\\]'\"'\"' packages/object-storage/CHANGELOG.md 2>/dev/null); node -e '\"'\"'let r={};try{r=JSON.parse(process.argv[1])}catch(e){};console.log(r.numFailedTests===0 && (r.numPassedTests ?? 0)>=3, process.argv[2], Number(process.argv[3]))'\"'\"' \"$o\" \"$t\" \"$c\"'; d=$(mktemp -d); npm pack -w packages/object-storage --pack-destination \"$d\" 2>/dev/null | tail -1; ls -l \"$d\"/*.tgz | awk '{print $5}'; tar tzf \"$d\"/*.tgz | wc -l; rm -rf \"$d\"; git status --short","description":"Run the I5 Check and measure the tarball","timeout":300000},"caller":{"type":"direct"}}],"container":null,"stop_reason":null,"stop_sequence":null,"stop_details":null,"usage":{"input_tokens":2,"cache_creation_input_tokens":823,"cache_read_input_tokens":146268,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":823},"output_tokens":8,"service_tier":"standard","inference_geo":"global","speed":"standard"},"input_transformations":[],"diagnostics":null,"context_management":null},"parent_tool_use_id":null,"session_id":"191e4ed1-dd78-4a43-b5cf-f933fa1ecc99","uuid":"d8ad21f0-b9ef-4bd0-a85a-7639a3c31058","timestamp":"2026-10-17T00:15:12.407Z","request_id":"req_011Cg6qyZYrGMuqMu9DVTieu","wire_tool_inputs":{"toolu_01MPuyzfvhXsKLua7i8zAM8f":{"command":"cd /home/joruge/repos/jrc-libs && grep -E 'package/(README|AGENTS|CHANGELOG)' /tmp/gate-i5.log | sort | uniq -c; bash -c 'o=$(cd packages/object-storage && npx --no-install vitest run readme-contrato --reporter=json 2>/dev/null); npm run -s typecheck -w packages/object-storage >/dev/null 2>/dev/null; t=$?; c=$(grep -c '\"'\"'^## \\[1\\.0\\.0\\]'\"'\"' packages/object-storage/CHANGELOG.md 2>/dev/null); node -e '\"'\"'let r={};try{r=JSON.parse(process.argv[1])}catch(e){};console.log(r.numFailedTests===0 && (r.numPassedTests ?? 0)>=3, process.argv[2], Number(process.argv[3]))'\"'\"' \"$o\" \"$t\" \"$c\"'; d=$(mktemp -d); npm pack -w packages/object-storage --pack-destination \"$d\" 2>/dev/null | tail -1; ls -l \"$d\"/*.tgz | awk '{print $5}'; tar tzf \"$d\"/*.tgz | wc -l; rm -rf \"$d\"; git status --short","description":"Run the I5 Check and measure the tarball","timeout":300000}},"wire_ingest_context":{"toolu_01MPuyzfvhXsKLua7i8zAM8f":{"cwd":"/home/joruge/repos/jrc-libs"}}}
{"type":"system","subtype":"permission_denied","tool_name":"Bash","tool_use_id":"toolu_01MPuyzfvhXsKLua7i8zAM8f","decision_reason_type":"safetyCheck","decision_reason":"This shell -c script runs rm and could not be checked","message":"This command passes a shell -c script that runs rm, and Claude Code could not check the script for dangerous removals. Approve only if you have read the script.","uuid":"b25188b6-a5e4-49fd-92c8-0bce9972dacc","session_id":"191e4ed1-dd78-4a43-b5cf-f933fa1ecc99"}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"This command passes a shell -c script that runs rm, and Claude Code could not check the script for dangerous removals. Approve only if you have read the script.","is_error":true,"tool_use_id":"toolu_01MPuyzfvhXsKLua7i8zAM8f"}]},"parent_tool_use_id":null,"session_id":"191e4ed1-dd78-4a43-b5cf-f933fa1ecc99","uuid":"876a7610-a131-4093-93ca-f9811d6b833a","timestamp":"2026-10-17T00:15:12.424Z","tool_use_result":"Error: This command passes a shell -c script that runs rm, and Claude Code could not check the script for dangerous removals. Approve only if you have read the script.","tool_result_meta":[{"id":"toolu_01MPuyzfvhXsKLua7i8zAM8f","non_execution_kind":"user-rejected","permission_decision":{"decision":"reject","source":"config"}}]}
EOF
{ cat "$FIX/.stub/r6-bash-denied-raw.jsonl"
  jq -c --slurpfile u <(head -1 "$FIX/.stub/r6-bash-denied-raw.jsonl") '.permission_denials = [$u[0].message.content[0]
    | {"tool_name": .name, "tool_use_id": .id, "tool_input": .input}] | .result = "DENIED"' "$FIX/.stub/result-real.jsonl"
} > "$FIX/.stub/r6-bash-denied.jsonl"
{ jq -c --arg p "$TPL_HOME/templates/checkpoint.md" '(.message.content[]? | select(.type == "tool_use") | .input.file_path) |= $p' \
    "$FIX/.stub/tpl-read-use.jsonl"; cat "$FIX/.stub/tpl-read-result.jsonl"; r6_result "---"
} > "$FIX/.stub/r6-other-path.jsonl"
{ tpl_swap "$FIX/.stub/tpl-deny-use.jsonl" | jq -c '(.message.content[]? | select(.type == "tool_use") | .name) |= "Edit"'
  cat "$FIX/.stub/tpl-deny-result.jsonl"; r6_result DENIED
} > "$FIX/.stub/r6-other-tool.jsonl"
tpl_stub "$FIX/.stub/tpl-stream-read.jsonl"
r6_o_read="$( "$SDD" preflight 2>&1 )"
tpl_stub "$FIX/.stub/r6-string.jsonl"
o="$( "$SDD" preflight 2>&1 )"
r6_string="arm=$(r6_arm "$o"),same=$(r4_n "$R6_SAME $r6_string_want" "$o"),cause=$(r4_n "$R6_CAUSE" "$o"),remedy=$(r4_n "$R6_REMEDY" "$o")"
r6_string="$r6_string,more=$(( $(r6_failed "$o") - $(r6_failed "$r6_o_read") ))"
tpl_stub "$FIX/.stub/r6-blocks.jsonl"
o="$( "$SDD" preflight 2>&1 )"
r6_blocks="arm=$(r6_arm "$o"),err=$(r4_n "$R6_SAME $r6_blocks_want" "$o"),cut=$(r4_n "${r6_blocks_want}y" "$o")"
r6_blocks="$r6_blocks,line=$(r4_n R6-SECOND-LINE "$o"),block=$(r4_n R6-SECOND-BLOCK "$o"),ctl=$(grep -c $'[\033\t\r]' <<< "$o")"
r6_blocks="$r6_blocks,more=$(( $(r6_failed "$o") - $(r6_failed "$r6_o_read") ))"
tpl_stub "$FIX/.stub/r6-empty.jsonl"
o="$( "$SDD" preflight 2>&1 )"
r6_empty="arm=$(r6_arm "$o"),none=$(r4_n "$R6_SAME (none)" "$o"),more=$(( $(r6_failed "$o") - $(r6_failed "$r6_o_read") ))"
tpl_stub "$FIX/.stub/r6-error-then-read.jsonl"
r6_retried="$(r6_arm "$( "$SDD" preflight 2>&1 )")"
tpl_stub "$FIX/.stub/r6-bash-denied.jsonl"
r6_elsewhere="bash=$(r6_arm "$( "$SDD" preflight 2>&1 )")"
tpl_stub "$FIX/.stub/r6-other-path.jsonl"
r6_elsewhere="$r6_elsewhere,path=$(r6_arm "$( "$SDD" preflight 2>&1 )")"
tpl_stub "$FIX/.stub/r6-other-tool.jsonl"
r6_elsewhere="$r6_elsewhere,tool=$(r6_arm "$( "$SDD" preflight 2>&1 )")"
r4_stub "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/r4-none" healthy
r6_alone="init=$(r6_arm "$( "$SDD" preflight 2>&1 )")"
r4_stub "$FIX/.stub/result-ok.jsonl" "$FIX/.stub/r4-none" healthy
r6_alone="$r6_alone,result=$(r6_arm "$( "$SDD" preflight 2>&1 )")"
tpl_stub "$FIX/.stub/result-ok.jsonl"
r6_nottried="$(r6_arm "$( "$SDD" preflight 2>&1 )")"
r6_before="denied=$(r6_arm "$out_tpl_denied") read=$(r6_arm "$out_tpl_read") not-tried=$r6_nottried"
r6_before="$r6_before empty=$(r6_arm "$r6_o_empty") garbage=$(r6_arm "$r6_o_garbage") dead=$(r6_arm "$r6_o_dead")"
r6_before="$r6_before bash-dead=$(r6_arm "$r6_o_bashdead") jq=$(r4_n 'jq: ' "$r6_o_garbage")"
assert_eq "the template probe names the outcome of its Read once, and a Read that comes back with an error fails by name" \
  "string:arm=errored,same=1,cause=1,remedy=1,more=1 blocks:arm=errored,err=1,cut=0,line=0,block=0,ctl=0,more=1 empty:arm=errored,none=1,more=1 precedence:denied=denied,retried=read elsewhere:bash=not-tried,path=not-tried,tool=not-tried alone:init=not-tried,result=not-tried before:denied=denied read=read not-tried=not-tried empty=no-session garbage=no-session dead=no-session-warn bash-dead=read jq=0" \
  "string:$r6_string blocks:$r6_blocks empty:$r6_empty precedence:denied=$(r6_arm "$out_tpl_denied"),retried=$r6_retried elsewhere:$r6_elsewhere alone:$r6_alone before:$r6_before"

# ...and the default: an outcome the classifier prints and the `case` does not know is never green.
# No stream reaches it — every outcome jq can print has an arm —, so it is built: a copy of the kit
# whose classifier spells the not-tried outcome as a word the `case` does not know (built like the
# copy of the no-rule world above), proved sabotaged, under the not-tried stream. Exactly one arm
# prints, the default's fail line, naming the word it got, with one failure more than the real kit
# under the same stream.
TPL_UNKNOWN="$(CDPATH='' cd -P "$FIX/.stub" && pwd)/kit-r6-unknown"
mkdir -p "$TPL_UNKNOWN/bin"
sed 's/ then "not-tried"$/ then "r6-unknown-outcome"/' "$SDD" > "$TPL_UNKNOWN/bin/sdd"
chmod +x "$TPL_UNKNOWN/bin/sdd"
cp "$ROOT/bin/sdd-coordination.py" "$TPL_UNKNOWN/bin/sdd-coordination.py"
ln -s "$ROOT/agents" "$TPL_UNKNOWN/agents"
tpl_stub "$FIX/.stub/result-ok.jsonl"
o="$( "$SDD" preflight 2>&1 )"
o_unknown="$( "$TPL_UNKNOWN/bin/sdd" preflight 2>&1 )"
assert_eq "an outcome the template probe's verdict does not know fails by name, never green" \
  "sabotaged:1 arm:unknown named:1 more:1" \
  "sabotaged:$(grep -c ' then "r6-unknown-outcome"$' "$TPL_UNKNOWN/bin/sdd") arm:$(r6_arm "$o_unknown") named:$(r4_n "$R6_UNKNOWN r6-unknown-outcome" "$o_unknown") more:$(( $(r6_failed "$o_unknown") - $(r6_failed "$o") ))"

# A kit whose path the grammar of the read rules refuses (Codex r3 #2 on PR #315). The harness reads
# `Read(/<path>/**)` as a gitignore-style pattern, so a kit at `/opt/sdd*` would grant
# `/opt/sdd-secret/templates/**` too, and the template probe stays green over it: it proves the
# session reads, never that it reads only what it should. So the templates' path is held to the
# grammar READ_EXTRA is held to (read_extra_dir_ok): refused, no session gets a rule naming the kit —
# not the template probe, and not the phases, whose projection still carries every READ_EXTRA rule —,
# and preflight fails ONCE, by name, with the remedy. The template probe is not opened, since there
# is no rule to measure, so neither the sentence of a kit_template_rules that printed nothing nor the
# probe's denial ("the harness refused them") speaks for a cause that is the path. Two worlds,
# READ_EXTRA empty and with one entry, each against the real kit under the same stub and config:
# exactly one fail line more. The copy is built like the one above (bin/sdd and the coordination
# helper copied, agents/ linked), here unsabotaged, in a directory whose name carries a `*`; the stub
# records the argv of EVERY call, and the projection is a `sdd run --dry-run` from that copy over a
# mission of its own, its argv printed with `%q` and matched with the same escape.
KP_KIT="$(CDPATH='' cd -P "$FIX/.stub" && pwd)/sdd*kit"
KP_RX="$(CDPATH='' cd -P "$FIX/.stub" && pwd)/kp-rx"
mkdir -p "$KP_KIT/bin" "$KP_KIT/tmp" "$KP_RX"
cp "$SDD" "$ROOT/bin/sdd-coordination.py" "$KP_KIT/bin/"
ln -s "$ROOT/agents" "$KP_KIT/agents"
kp_stub() {
  cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
iso=0; prev=""
for a in "\$@"; do
  if [ "\$prev" = "--setting-sources" ] && [ -z "\$a" ]; then iso=1; fi
  prev="\$a"
done
for a in "\$@"; do printf '%s\n' "\$a" >> "$FIX/.stub/kp-argv"; done
if [ "\$iso" = 1 ]; then
  : > "$FIX/.stub/kp-iso"
  cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/tpl-stream-read.jsonl"
  exit 0
fi
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"
STUB
  chmod +x "$FIX/.stub/claude"
  rm -f "$FIX/.stub/kp-argv" "$FIX/.stub/kp-iso"
}
KP_NAMED="fail  the kit's templates are at $KP_KIT/templates, a path the grammar of the read rules refuses"
KP_REMEDY="grant every directory it matches. Move the kit to a literal path."
# The message's middle lines, one needle each, so a line that lost its words is named: `body=111`.
KP_BODY1="kit_read_rules gives no session a rule for"
KP_BODY2="so the phases will read the templates through Bash, work from memory, or stop"
KP_BODY3="template probe is not opened — there is no rule to measure"
KP_SKIP="template probe not opened: "
# kp_world <sdd> <READ_EXTRA> → named,remedy,body,r3,denied,r4,skip,session,rule,scratch,refusal,
# fails — this world's fail line, its remedy and middle lines, the three other sentences that could
# speak for the cause, the probe's skip line, whether the template probe was opened, the rules
# naming the kit in ANY call's argv, the mktemp dirs (`tmp.*`) left in the TMPDIR it was given, the
# refusal's clause whatever kit it names (the real kit's runs must print none), and the count of
# fail lines
kp_world() {
  local o session=0 rule=0
  kp_stub
  o="$( TMPDIR="$KP_KIT/tmp" READ_EXTRA="$2" "$1" preflight 2>&1 )"
  [ ! -f "$FIX/.stub/kp-iso" ] || session=1
  [ ! -f "$FIX/.stub/kp-argv" ] || rule="$(grep -cF -- "Read(/$KP_KIT" "$FIX/.stub/kp-argv")"
  printf 'named=%s,remedy=%s,body=%s%s%s,r3=%s,denied=%s,r4=%s,skip=%s,session=%s,rule=%s,scratch=%s,refusal=%s,fails=%s' \
    "$(grep -cF -- "$KP_NAMED" <<< "$o")" "$(grep -cF -- "$KP_REMEDY" <<< "$o")" \
    "$(grep -cF -- "$KP_BODY1" <<< "$o")" "$(grep -cF -- "$KP_BODY2" <<< "$o")" "$(grep -cF -- "$KP_BODY3" <<< "$o")" \
    "$(grep -cF -- "kit_template_rules printed no read rule" <<< "$o")" "$(grep -cF -- "$TPL_FAIL" <<< "$o")" \
    "$(grep -cF -- "$R4_NAMED" <<< "$o")" "$(grep -cF -- "$KP_SKIP" <<< "$o")" "$session" "$rule" \
    "$(find "$KP_KIT/tmp" -mindepth 1 -maxdepth 1 -name 'tmp.*' | wc -l)" \
    "$(grep -cF -- ", a path the grammar of the read rules refuses" <<< "$o")" "$(grep -c '^  fail  ' <<< "$o")"
}
kp_fails() { sed 's/.*,fails=//' <<< "$1"; }
kp_refusal() { sed 's/.*,refusal=\([0-9]*\),.*/\1/' <<< "$1"; }
kp_empty="$(kp_world "$KP_KIT/bin/sdd" "")"
kp_entry="$(kp_world "$KP_KIT/bin/sdd" "$KP_RX")"
kp_ctl_empty="$(kp_world "$SDD" "")"
kp_ctl_entry="$(kp_world "$SDD" "$KP_RX")"
# The projection: a repo of its own (the fixture's tree stays as the later sections expect it), one
# pending increment, and the dry-run's five blocks. The READ_EXTRA rule riding in every block is the
# witness that the argv was read at all.
KP_REPO="$FIX/.stub/kp-repo"
mkdir -p "$KP_REPO/.sdd" "$KP_REPO/docs/handoffs/20260101-kitpath"
( cd "$KP_REPO" && git init -q -b main && git config user.email "fixture@example.com" \
    && git config user.name "Fixture" ) >/dev/null 2>&1
printf 'PROJECT_NAME="fixture"\nDEFAULT_BRANCH="main"\nTEST_CMD="true"\nE2E_CMD=""\nHANDOFF_DIR="docs/handoffs"\nQA_DOCS_PATH="docs/qa"\nJIRA_ENABLED=false\n' \
  > "$KP_REPO/.sdd/config.sh"
printf -- '---\nmissao: 20260101-kitpath\nbranch: main\naprovacao: auto\n---\n# Mission\n' \
  > "$KP_REPO/docs/handoffs/20260101-kitpath/00-missao.md"
: > "$KP_REPO/docs/handoffs/20260101-kitpath/01-plano.md"
printf '| ID | Incremento | Check (comando → esperado) | Status | Commit |\n|---|---|---|---|---|\n| I1 | slice | `true` → 0 | pending | — |\n' \
  > "$KP_REPO/docs/handoffs/20260101-kitpath/checkpoint.md"
( cd "$KP_REPO" && git add -A && git commit -qm "chore: fixture mission" ) >/dev/null 2>&1
kp_proj="$( cd "$KP_REPO" && SDD_STATE_DIR="$FIX/.stub/kp-state" READ_EXTRA="$KP_RX" "$KP_KIT/bin/sdd" run 20260101-kitpath --dry-run 2>&1 )"
kp_blocks="$(grep -c '^--- DRY RUN: phase ' <<< "$kp_proj")"
kp_kitrule="$(grep -oF -- "$(printf '%q' "Read(/$KP_KIT")" <<< "$kp_proj" | wc -l)"
kp_rxrule="$(grep -oF -- "$(printf '%q' "Read(/$KP_RX/**)")" <<< "$kp_proj" | wc -l)"
assert_eq "a kit path the read-rule grammar refuses gets no template rule, and preflight names it" \
  "empty:named=1,remedy=1,body=111,r3=0,denied=0,r4=0,skip=1,session=0,rule=0,scratch=0,refusal=1 entry:named=1,remedy=1,body=111,r3=0,denied=0,r4=0,skip=1,session=0,rule=0,scratch=0,refusal=1 more:1/1 ctl:refusal=0/0 projection:blocks=5,kit=0,rx=5" \
  "empty:${kp_empty%,fails=*} entry:${kp_entry%,fails=*} more:$(( $(kp_fails "$kp_empty") - $(kp_fails "$kp_ctl_empty") ))/$(( $(kp_fails "$kp_entry") - $(kp_fails "$kp_ctl_entry") )) ctl:refusal=$(kp_refusal "$kp_ctl_empty")/$(kp_refusal "$kp_ctl_entry") projection:blocks=$kp_blocks,kit=$kp_kitrule,rx=$kp_rxrule"

# The template probe carries the templates' rules alone (Codex P3 in the fifth round on PR #315).
# R3 took ALLOWED_TOOLS off its --allowedTools, and the READ_EXTRA rules stayed: the probe carried
# every line of kit_read_rules, so an entry that covers the kit — `$HOME`, with SDD_HOME below it,
# which the grammar accepts (a limit declared in ADR 0019) — read the template by itself, and
# preflight certified a templates rule that was sabotaged or broken. The probe now reads
# kit_template_rules, the one definition kit_read_rules composes with the READ_EXTRA rules; the
# entries keep the warnings of their own above. Here the stub plays the harness: it answers the
# template probe with the read stream when an argument of its --allowedTools covers the template in
# the shape ADR 0019 measured — `Read(/<dir>/**)`, the template under <dir> — and with the denied
# stream otherwise, so the world where a broad rule answers for a broken one is built, not
# described. Two worlds, each under an entry that covers its kit (the kit's parent directory):
#   - COVERING, the real kit: the probe's --allowedTools is the templates' rule alone, the Bash probe
#     beside it keeps its own (`[Bash]`, no read rule), and the verdict is `ok` — the positive
#     control of the stub. The phases of a `sdd run --dry-run` carry kit_read_rules as they did
#     before: the templates' rule, then the entry's. The differential is the two lists against
#     each other: the probe's is the phases' less the entry's rule;
#   - SABOTAGED, a copy of the kit whose kit_template_rules prints the rule without its `/**`,
#     proved sabotaged: the probe carries that rule alone and is DENIED, never green, while the
#     copy's phases carry the broken rule and then the entry's — the one that, on the probe's list,
#     read the template in its place.
# r7_stub <template path> <stream prefix> — the template probe answered as above, its argv in
# r7-tpl-argv; every other `-p` call (the Bash probe) gets stub A's stream, its argv in r7-bash-argv.
r7_stub() {
  cat > "$FIX/.stub/claude" <<STUB
#!/bin/sh
iso=0; prev=""; p=0
for a in "\$@"; do
  if [ "\$prev" = "--setting-sources" ] && [ -z "\$a" ]; then iso=1; fi
  [ "\$a" != "-p" ] || p=1
  prev="\$a"
done
if [ "\$iso" = 1 ]; then
  : > "$FIX/.stub/r7-tpl-argv"
  for a in "\$@"; do printf '%s\n' "\$a" >> "$FIX/.stub/r7-tpl-argv"; done
  cov=0; on=0
  for a in "\$@"; do
    case "\$a" in --allowedTools) on=1; continue ;; --*) on=0 ;; esac
    [ "\$on" = 1 ] || continue
    case "\$a" in
      'Read(/'*'/**)') d="\${a#'Read(/'}"; d="\${d%'/**)'}"
        case "$1" in "\$d"/*) cov=1 ;; esac ;;
    esac
  done
  if [ "\$cov" = 1 ]; then cat "$FIX/.stub/init-with-bash.jsonl" "$2-read.jsonl"
  else cat "$FIX/.stub/init-with-bash.jsonl" "$2-denied.jsonl"; fi
  exit 0
fi
if [ "\$p" = 1 ]; then
  : > "$FIX/.stub/r7-bash-argv"
  for a in "\$@"; do printf '%s\n' "\$a" >> "$FIX/.stub/r7-bash-argv"; done
fi
cat "$FIX/.stub/init-with-bash.jsonl" "$FIX/.stub/result-ok.jsonl"
STUB
  chmod +x "$FIX/.stub/claude"
  rm -f "$FIX/.stub/r7-tpl-argv" "$FIX/.stub/r7-bash-argv"
}
# r7_want <rule>... — the rules as the projection prints them (`%q`), space-joined
r7_want() { local w="" r; for r in "$@"; do w="${w:+$w }$(printf '%q' "$r")"; done; printf '%s' "$w"; }
# r7_lists <projection> <want> → <blocks whose arguments after the --allowedTools value are <want>>/<blocks>.
# The scan starts at the LAST `--model` field, as in check-dry-run.sh: the prompt rides on the line.
r7_lists() {
  want="$2" awk '
    /^--- DRY RUN: phase .* ---$/ { n++; blk = 1; next }
    blk && / claude -p / {
      k = 0; for (i = 1; i <= NF; i++) if ($i == "--model") k = i
      v = ""
      for (i = k; k && i <= NF; i++) if ($i == "--allowedTools") {
        for (j = i + 2; j <= NF && substr($j, 1, 2) != "--"; j++) v = v (v == "" ? "" : " ") $j
        break
      }
      if (v == ENVIRON["want"]) m++
      blk = 0
    }
    END { printf "%d/%d", m, n }' <<< "$1"
}
# r7_proj <sdd> <READ_EXTRA> — that kit's `sdd run --dry-run` over the mission of the block above,
# its arguments one space apart (the projection pads them, and check-dry-run.sh squeezes them too)
r7_proj() {
  ( cd "$KP_REPO" && SDD_STATE_DIR="$FIX/.stub/r7-state" ALLOWED_TOOLS=Bash READ_EXTRA="$2" "$1" run 20260101-kitpath --dry-run 2>&1 ) \
    | tr -s ' '
}
R7_RX="$(dirname "$TPL_HOME")"
r7_stub "$TPL_PATH" "$FIX/.stub/tpl-stream"
r7_cov_out="$( ALLOWED_TOOLS=Bash READ_EXTRA="$R7_RX" "$SDD" preflight 2>&1 )"
r7_cov="probe=$(tpl_allow_of "$FIX/.stub/r7-tpl-argv"),bash=$(tpl_allow_of "$FIX/.stub/r7-bash-argv"),$(tpl_verdict "$r7_cov_out")"
r7_cov="$r7_cov,phases=$(r7_lists "$(r7_proj "$SDD" "$R7_RX")" \
  "$(r7_want "Read(/$TPL_HOME/templates/**)" "Read(/$R7_RX/**)")")"
R7_KIT="$(CDPATH='' cd -P "$FIX/.stub" && pwd)/r7-kit"
R7_KIT_RX="$(dirname "$R7_KIT")"
R7_BROKEN='  printf "Read(/%s)\n" "$SDD_HOME/templates"'
mkdir -p "$R7_KIT/bin"
sed 's|^  dir_read_rules "\$SDD_HOME/templates"$|  printf "Read(/%s)\\n" "$SDD_HOME/templates"|' "$SDD" > "$R7_KIT/bin/sdd"
chmod +x "$R7_KIT/bin/sdd"
cp "$ROOT/bin/sdd-coordination.py" "$R7_KIT/bin/sdd-coordination.py"
ln -s "$ROOT/agents" "$R7_KIT/agents"
tpl_streams "$R7_KIT/templates/handoff.md" "$FIX/.stub/r7-stream"
r7_stub "$R7_KIT/templates/handoff.md" "$FIX/.stub/r7-stream"
r7_sab_out="$( ALLOWED_TOOLS=Bash READ_EXTRA="$R7_KIT_RX" "$R7_KIT/bin/sdd" preflight 2>&1 )"
r7_sab="applied=$(grep -cxF -- "$R7_BROKEN" "$R7_KIT/bin/sdd"),probe=$(tpl_allow_of "$FIX/.stub/r7-tpl-argv"),$(tpl_verdict "$r7_sab_out")"
r7_sab="$r7_sab,phases=$(r7_lists "$(r7_proj "$R7_KIT/bin/sdd" "$R7_KIT_RX")" \
  "$(r7_want "Read(/$R7_KIT/templates)" "Read(/$R7_KIT_RX/**)")")"
assert_eq "the template probe carries the templates rule alone, never a READ_EXTRA rule that covers the kit" \
  "covering:probe=[Read(/$TPL_HOME/templates/**)],bash=[Bash],fail=0,ok=1,warn=0,phases=5/5 sabotaged:applied=1,probe=[Read(/$R7_KIT/templates)],fail=1,ok=0,warn=0,phases=5/5" \
  "covering:$r7_cov sabotaged:$r7_sab"

# Back to the dead stub every later section assumes ("claude and gh are stubbed to fail").
printf '#!/bin/sh\nexit 1\n' > "$FIX/.stub/claude"
chmod +x "$FIX/.stub/claude"

# --- an agent copy that drifted from the kit source -------------------------
# DIFFERENTIAL on purpose: the two runs compared against EACH OTHER — same fixture, one byte of
# difference, exactly one more failed check. No fixture regime satisfies that by accident.
# The `N kit agent(s) checked` line is asserted too, both ways. It used to print only under a
# preflight-wide `fails -eq 0`, which claude and gh stubbed to fail never reach, so "absent" was
# vacuous here; since issue #83 it counts the AGENT block's failures alone, and the intact run is
# the witness that it can print at all.
echo "== an agent copy drifted from the kit source =="

AGENT=".claude/agents/sdd-executor.md"

# failed_count <preflight output> — the N from the closing "N check(s) failed" (stderr, captured).
# Prints nothing when the line is absent, which is itself a red: `-ne` on an empty string errors.
failed_count() {
  local line; line="$(grep -oE '[0-9]+ check\(s\) failed' <<< "$1")"
  printf '%s' "${line%% *}"
}

# Adversarial pass, like the starter.conf block below: each assertion here was broken on its own by
# a distinct sabotage of the agent block, and each names the one it owns exclusively. The two
# sanity guards are the exception and are marked as such — same rubric as "preflight got as far as
# the tool checks" in the GNU section, which is also non-exclusive on purpose.
#
# SANITY, not exclusive: it names the cause when the kit copy has no agents/ to install from (the
# mutation sandbox forgot to copy it), instead of leaving five assertions red with no explanation.
if [ -f "$AGENT" ]; then pass "the fixture installed the kit agents"
else fail "the fixture installed the kit agents" "$AGENT on disk" "no such file"; fi

out="$( "$SDD" preflight 2>&1 )"
# SANITY, not exclusive: `current branch:` prints AFTER the agent block, so a preflight that died
# before reaching the agents cannot produce it. Without it the three "lacks" here would all be
# satisfied by a fixture that never got that far.
assert_has "preflight got past the agent block" "current branch:" "$out"
# Positive control. Owns the sabotage that says "stale" about copies that MATCH — an `else warn`
# arm, which changes no rc and no failure count, so nothing else in this file sees it.
assert_lacks "no stale complaint when every copy matches the source" "stale" "$out"
n_intact="$(failed_count "$out")"
# The operator's line, with the kit's own agent count. Owns three sabotages: the line dropped, the
# count off, and the guard back on the preflight-wide `fails` (gh is stubbed red above this block).
# The SANITY guard below it keeps the claim honest: with no other red the line would print under
# the old guard too, and the assertion would prove nothing about the counter.
n_kit_agents="$(find "$ROOT/agents" -maxdepth 1 -name 'sdd-*.md' | wc -l | tr -d ' ')"
assert_has "every copy matches: the agent line says how many were checked" \
  "$n_kit_agents kit agent(s) checked" "$out"
if [ -n "$n_intact" ] && [ "$n_intact" -ge 1 ]; then
  pass "SANITY: the intact run carries another red, so the agent line is counted per block"
else
  fail "SANITY: the intact run carries another red, so the agent line is counted per block" \
       ">= 1 failed check" "'$n_intact'"
fi

printf '\n<!-- drift: one byte the source does not have -->\n' >> "$AGENT"
out="$( "$SDD" preflight 2>&1 )"
n_drift="$(failed_count "$out")"

# The literal text the checkpoint's Check greps. Owns the original defect AND the sabotage that
# keeps failing but drops the word: `_fail "agent $name differs — ..."` is caught here and nowhere
# else in this file.
assert_has "a drifted agent copy fails the preflight" "agent sdd-executor.md stale" "$out"
# Two different repairs deserve two different words — "not installed" sends the operator to install
# a file that is right there on disk. Owns the sabotage that keeps the stale branch but reuses the
# missing branch's wording inside it; rc, count and the "stale" needle all survive that one.
assert_lacks "a drifted copy is not reported as missing" "sdd-executor.md not installed" "$out"
# Owns the guard dropped altogether: "checked" printed right under the failure it just booked.
assert_lacks "a drifted copy silences the 'checked' line" "kit agent(s) checked" "$out"
# THE differential half, and the only one that survives a `warn` that does not count: the text can
# be perfect while the check silently passes. Compares the two readings of one fixture.
if [ -n "$n_intact" ] && [ -n "$n_drift" ] && [ "$n_drift" -eq $((n_intact + 1)) ]; then
  pass "the drift adds exactly one failed check, no more and no less"
else
  fail "the drift adds exactly one failed check, no more and no less" \
       "$((${n_intact:-0} + 1)) failed check(s)" "intact '$n_intact' → drifted '$n_drift'"
fi

# --- an agent copy that is absent: a different failure, in different words ---
# The branch that already worked, kept as the negative control of the one above: without it, a
# `cmp -s` that swallowed the missing case (cmp on a nonexistent file is also a mismatch, so one
# careless merge of the two arms does exactly that) would report every absent agent as "stale" and
# no assertion above would notice.
rm -f "$AGENT"
out="$( "$SDD" preflight 2>&1 )"
n_gone="$(failed_count "$out")"

# Owns the sabotage that reworded this branch ("agent X absent"): the operator loses the string
# every doc and every past handoff uses.
assert_has "a missing agent copy still says 'not installed'" \
  "agent sdd-executor.md not installed" "$out"
# Owns the mirror of the drift "lacks": the missing message growing a "stale or removed" clause.
assert_lacks "absent and stale do not collapse into one message" "sdd-executor.md stale" "$out"
if [ -n "$n_intact" ] && [ -n "$n_gone" ] && [ "$n_gone" -eq $((n_intact + 1)) ]; then
  pass "the missing copy adds exactly one failed check"
else
  fail "the missing copy adds exactly one failed check" \
       "$((${n_intact:-0} + 1)) failed check(s)" "intact '$n_intact' → missing '$n_gone'"
fi

# --- the base branch warning, at the door it was born in --------------------
# The warning is one function now, shared with `sdd run` and `sdd kaizen`, and preflight is the
# call site it started in — so it is also the one nobody would think to re-test after the
# extraction. Measured while writing this: deleting the call HERE left check-gates.sh and
# check-kaizen.sh both green, because each of those files only exercises its own door.
#
# DIFFERENTIAL, like its two twins: the fixture was born on `main`, so from a single reading
# "warns on the base branch" and "always warns" are the same output.
echo "== base branch warning =="
out="$( "$SDD" preflight 2>&1 )"
assert_has "the base branch warning survives in the preflight it was extracted from" \
  "you are on the base branch (main)" "$out"

git checkout -q -b missao/base-branch-fixture
out="$( "$SDD" preflight 2>&1 )"
git checkout -q main
git branch -q -D missao/base-branch-fixture
assert_lacks "and it is silent off the base branch" "you are on the base branch" "$out"
# `current branch:` is the witness that the second reading really reached the git block: without
# it, a preflight that died earlier would satisfy the `lacks` above by never getting there —
# absence proved by absence, which is the vacuity this whole mission is about.
assert_has "and the second reading really reached the git block" \
  "current branch: missao/base-branch-fixture" "$out"

# --- `sdd install` against a kit copy with no config/starter.conf -----------
# The redirect creates $CONFIG_FILE BEFORE sed runs, so the missing starter used to leave a 0-byte
# `.sdd/config.sh` on disk and `set -e` took the install down only afterwards. rc was ALREADY
# non-zero (sed's), so rc measures nothing on its own here — the two branches share it. What the
# assertions below separate is the branch's own text and, above all, the artifact: the poisoned
# empty config is what made the NEXT `sdd install` print "already exists (preserved)" over it.
echo "== sdd install without config/starter.conf =="

KIT="$FIX/.kit-no-starter"
mkdir -p "$KIT/bin"
# A real copy, never a symlink: _resolve_self follows symlinks, so a symlinked bin/sdd would
# resolve SDD_HOME back to the real kit — which HAS the starter, and the fixture would measure
# nothing. Nothing else is copied on purpose: `config/` absent IS the fixture.
cp "$SDD" "$KIT/bin/sdd"
cp "$ROOT/bin/sdd-coordination.py" "$KIT/bin/sdd-coordination.py"

mkdir -p "$FIX/target"
( cd "$FIX/target" \
  && git init -q -b main \
  && git config user.email "fixture@example.com" \
  && git config user.name "Fixture" \
  && echo content > file.txt \
  && git add -A && git commit -qm "init" ) >/dev/null 2>&1

out="$( cd "$FIX/target" && "$KIT/bin/sdd" install 2>&1 )"; rc=$?

# Adversarial pass, so none of the five below gets deleted later as decorative — each was broken
# on its own by a distinct sabotage of the guard, and each names its owner here.
#
# This one reads an rc that BOTH branches share, so it is blind to the original defect (it passed
# green before the guard existed). It is not redundant: it is the only half that sees the guard
# degrading from `die` to a warning that carries on.
if [ "$rc" -ne 0 ]; then pass "install fails when the kit has no starter.conf"
else fail "install fails when the kit has no starter.conf" "rc != 0" "rc $rc"; fi

# The consequence, not only the absence — same rubric as the GNU line above. Owns the sabotage
# that keeps the guard but drops the "so what" from the message.
assert_has "the guard says what breaks, not only what is missing" \
  "would be created empty" "$out"
# Also blind to the original defect on its own — sed's stderr quotes the same path. Kept because
# it owns the sabotage that keeps the consequence but stops naming the file the operator must fix.
assert_has "the guard names the file the kit copy is missing" "config/starter.conf" "$out"
# THE discriminating half. Both branches exit non-zero and both mention the path, so an assertion
# that stopped here would pass on the defect. sed only speaks if it ran, and it only runs if the
# guard did not fire — its prefix is the marker of the WRONG branch, and it is locale-proof
# (GNU sed prefixes with the program name in every language, and the message body does not).
assert_lacks "the guard fires before sed does" "sed:" "$out"
# The artifact half: the label was never the damage, the 0-byte file was.
if [ ! -e "$FIX/target/.sdd/config.sh" ]; then pass "no empty config is left behind"
else fail "no empty config is left behind" "no .sdd/config.sh at all" \
       "$(wc -c < "$FIX/target/.sdd/config.sh") byte(s) on disk"; fi

# --- a TEST_CMD that runs nothing -------------------------------------------
# `TEST_CMD` is the EXEC gate and half the REVIEW gate, and the preflight only ever refused it
# EMPTY or literally `TODO`. A value that exits 0 having executed nothing is worse than empty: it
# passes every gate, in every mission, for ever, and each phase certifies itself against a run that
# never happened — a label reached through the one key the whole pipeline trusts. `sdd health`
# already refused one spelling of this (`--list`) but only for the KIT's own suite; every target
# repo was on its own.
#
# The forms below are the ones people actually write: the placeholder left behind after wiring the
# config up, and the "list the tests without running them" flag of three ecosystems.
echo "== a TEST_CMD that runs nothing =="
cd "$FIX" || exit 1
cp .sdd/config.sh .sdd/config.sh.bak

noop_case() { # noop_case <TEST_CMD> <description>
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$1\"|" .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  if grep -qF "runs nothing" <<< "$o"; then pass "$2"
  else fail "$2" "a preflight refusing TEST_CMD=$1" "$(grep -m1 'TEST_CMD' <<< "$o" || echo 'no TEST_CMD line at all')"; fi
}

noop_case 'true'                'preflight fails a no-op TEST_CMD'
noop_case ':'                   'preflight fails TEST_CMD=":"'
noop_case 'echo ok'             'preflight fails a TEST_CMD that only echoes'
noop_case 'npm test -- --list'  'preflight fails a TEST_CMD carrying --list'
noop_case 'pytest --collect-only' 'preflight fails a TEST_CMD that only collects'

# The other half, and the half that keeps the rule alive: a rule that fires on correct config is a
# rule the next author deletes. `--listen-port` is the near miss the whole-argument padding exists
# for, and `echo` inside a longer command is not a command that only echoes.
ok_case() { # ok_case <TEST_CMD> <description>
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$1\"|" .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  if grep -qF "runs nothing" <<< "$o"; then
    fail "$2" "no refusal for TEST_CMD=$1" "$(grep -m1 'runs nothing' <<< "$o")"
  else pass "$2"; fi
}

ok_case 'npm test'                       'a real TEST_CMD is not accused'
ok_case 'tests/run-all.sh'               'the kit own suite is not accused'
ok_case './run.sh --listen-port 8080'    'a flag that merely starts with --list is not accused'
ok_case 'make test && echo done'         'an echo that is not the command is not accused'

mv .sdd/config.sh.bak .sdd/config.sh

# --- and then it RUNS the thing --------------------------------------------
# The block above is a STRING heuristic: it knows `true`, `:`, `echo`, `printf`, `exit` and three
# spellings of "list the tests without running them", and certifies everything else. A target repo
# whose `npm test` dies on a dependency that was never installed passes it green — and then
# gate_EXEC (which runs the same command for real) refuses for ever, at one EXEC session per lap,
# because a session cannot install what the gate never told anybody about. The whole point of a
# preflight is to move that discovery to before the first token.
#
# Asserted by WITNESS and not by the message: a preflight that printed "ran green" without running
# anything is exactly the label-over-artifact this repo forbids, and no wording check can see it.
# The probes live outside the fixture repo so running them cannot dirty the tree being measured.
echo "== the preflight RUNS the TEST_CMD =="
PROBE="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-probe-XXXXXX")"
trap 'rm -rf "$FIX" "$PROBE"' EXIT
printf '#!/usr/bin/env bash\nprintf "ran\\n" >> "%s/witness"\nexit 0\n' "$PROBE" > "$PROBE/suite-green.sh"
printf '#!/usr/bin/env bash\nprintf "ran\\n" >> "%s/witness"\nexit 3\n' "$PROBE" > "$PROBE/suite-red.sh"
chmod +x "$PROBE/suite-green.sh" "$PROBE/suite-red.sh"

cp .sdd/config.sh .sdd/config.sh.bak
run_case() { # run_case <script> <expected-marker> <forbidden-marker> <description>
  : > "$PROBE/witness"
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$PROBE/$1\"|" .sdd/config.sh
  local o ran; o="$( "$SDD" preflight 2>&1 )"
  ran="$(grep -c . "$PROBE/witness" 2>/dev/null || true)"
  local got="ran=$ran"
  grep -qF "$2" <<< "$o" || got="$got, the expected line is absent"
  grep -qF "$3" <<< "$o" && got="$got, and the OTHER verdict was printed too"
  assert_eq "$4" "ran=1" "$got"
}
run_case suite-green.sh "TEST_CMD ran green" "TEST_CMD FAILED" \
  "a green TEST_CMD is EXECUTED, and only then called green"
run_case suite-red.sh   "TEST_CMD FAILED"    "TEST_CMD ran green" \
  "a TEST_CMD that exits non-zero is refused by its exit status, not by its spelling"

# Gap 3 of portability: the TEST_CMD used to inherit the runner's stdin. vitest 3 turns watch mode
# on when stdin is a terminal (`watch: !isCI && process.stdin.isTTY`), and a target whose `test` is
# a bare `vitest` would hang the gate for good, with no rc, from any `sdd run` typed at a terminal.
# The preflight runs TEST_CMD through the same run_check_cmd the gates do, so one probe here covers
# the one redirection. The caller FEEDS a line on purpose: under a harness stdin is already
# /dev/null, and a probe that only inherited it would pass with and without the fix.
printf '#!/usr/bin/env bash\nprintf "ran\\n" >> "%s/witness"\nif IFS= read -r line; then printf "stdin:%%s\\n" "$line" >> "%s/witness"; exit 4; fi\nexit 0\n' \
  "$PROBE" "$PROBE" > "$PROBE/suite-stdin.sh"
chmod +x "$PROBE/suite-stdin.sh"
printf 'a line the TEST_CMD must never see\n' > "$PROBE/a-line"
: > "$PROBE/witness"
sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$PROBE/suite-stdin.sh\"|" .sdd/config.sh
stdin_out="$( "$SDD" preflight < "$PROBE/a-line" 2>&1 )"
assert_eq "TEST_CMD runs with stdin closed, whatever stdin the caller holds" \
  "ran=1 stdin=0 green=1 failed=0" \
  "ran=$(grep -cx 'ran' "$PROBE/witness") stdin=$(grep -c '^stdin:' "$PROBE/witness") green=$(grep -cF 'TEST_CMD ran green' <<< "$stdin_out") failed=$(grep -cF 'TEST_CMD FAILED' <<< "$stdin_out")"

# The no-op arm: a command the heuristic already refused must NOT be executed. Running whatever
# someone typed into a key the preflight had already decided was wrong is a preflight doing damage
# on config it just rejected.
#
# The value is the probe script WITH `--list`, and both halves of it are load-bearing. `--list` is
# what trips `test_cmd_looks_noop`, so the refusal arm is the one that fires; the SCRIPT is what
# appends to the witness, so an execution that should not have happened leaves a mark. This block
# used to carry `TEST_CMD="true"`, and that value could not do the second half: `true` is a builtin
# that touches nothing, so `ran=0` held in the blinded world exactly as in the correct one. The
# term read like a witness and was a constant — the sensor claiming to measure what it did not.
#
# Each half now has a mutant of its own, which is the only reason either can be believed:
# `mut_PRE_testcmd_noop_blind` blinds the heuristic and is caught by the MESSAGE, while
# `mut_PRE_testcmd_noop_runs_anyway` keeps the message and executes anyway — caught by `ran` and
# by nothing else in this suite.
: > "$PROBE/witness"
sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$PROBE/suite-green.sh --list\"|" .sdd/config.sh
noop_out="$( "$SDD" preflight 2>&1 )"
noop_ran="$(grep -c . "$PROBE/witness" 2>/dev/null || true)"
assert_eq "a TEST_CMD the heuristic already refused is not executed at all" \
  "runs nothing, ran=0" \
  "$(grep -qF 'runs nothing' <<< "$noop_out" && printf 'runs nothing' || printf 'not refused'), ran=$noop_ran"

# The same refusal for the spellings the old space-only `case` let through (issue 118): a TAB
# before `--list`, and `"--list"` quoted. run_check_cmd EVALS the value, so both reach the suite
# as a bare `--list` — measured with a witness recording the argv. Same two-halves witness as the
# block above: refused in words AND never executed.
list_spelling() { # list_spelling <the TEST_CMD value, raw> → "<refused?>, ran=<n>"
  : > "$PROBE/witness"
  { grep -v '^TEST_CMD=' .sdd/config.sh; printf 'TEST_CMD=%s\n' "$1"; } > .sdd/config.sh.tmp
  mv .sdd/config.sh.tmp .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  printf '%s, ran=%s' "$(grep -qF 'runs nothing' <<< "$o" && printf 'runs nothing' || printf 'not refused')" \
    "$(grep -c . "$PROBE/witness" 2>/dev/null || true)"
}
assert_eq "a TAB or a quoted --list is refused like a spaced one" \
  "runs nothing, ran=0 / runs nothing, ran=0" \
  "$(list_spelling "\"$PROBE/suite-green.sh"$'\t'"--list\"") / $(list_spelling "'$PROBE/suite-green.sh \"--list\"'")"
assert_eq "a TAB before --listen-port is still not accused" \
  "not refused, ran=1" \
  "$(list_spelling "\"$PROBE/suite-green.sh"$'\t'"--listen-port\"")"
# A shell operator ends the word as surely as a space does: `--list; true` lists and exits 0 (PR
# #167 review). The negative control is the same operator after a flag that only STARTS with --list.
assert_eq "a --list ended by a shell operator is refused like a spaced one" \
  "runs nothing, ran=0 / runs nothing, ran=0" \
  "$(list_spelling "\"$PROBE/suite-green.sh --list; true\"") / $(list_spelling "\"$PROBE/suite-green.sh --list&&true\"")"
assert_eq "an operator after --listen-port is still not accused" \
  "not refused, ran=1" \
  "$(list_spelling "\"$PROBE/suite-green.sh --listen-port; true\"")"
mv .sdd/config.sh.bak .sdd/config.sh

# --- DEFAULT_BRANCH names a branch that EXISTS ------------------------------
# `load_config` demands only that the key be non-empty, and `warn_if_on_base_branch` only compares
# it with the current branch name — nothing ever asked the repository whether the branch is there.
# The failure surfaces in `gh pr create --base` in the PR phase: the LAST one, after EXEC, QA,
# REVIEW and DOCS have all been paid for. The pilot declares `DEFAULT_BRANCH="develop"` and the
# value has already been got wrong once.
#
# Three arms and three distinct markers, so no arm can be satisfied by another's text: on origin is
# what `gh pr create` actually opens against, local-only is a warning (the branch exists, the PR
# still cannot be opened there), absent is a refusal.
echo "== DEFAULT_BRANCH is verified against the repository =="
ORIGIN="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-origin-XXXXXX")"
trap 'stop_page_server 2>/dev/null; rm -rf "$FIX" "$PROBE" "$ORIGIN"' EXIT
git init -q --bare -b main "$ORIGIN"
git remote add origin "$ORIGIN"
git push -q origin main
git branch only-local

cp .sdd/config.sh .sdd/config.sh.bak
branch_case() { # branch_case <value> <expected-marker> <forbidden-marker> <description>
  sed -i "s|^DEFAULT_BRANCH=.*|DEFAULT_BRANCH=\"$1\"|" .sdd/config.sh
  local o; o="$( "$SDD" preflight 2>&1 )"
  local got="ok"
  grep -qF "$2" <<< "$o" || got="the expected line is absent"
  grep -qF "$3" <<< "$o" && got="$got + the OTHER verdict was printed too"
  assert_eq "$4" "ok" "$got"
}
branch_case main       "DEFAULT_BRANCH=main exists on origin" \
                       "is not a branch of this repository" \
                       "a DEFAULT_BRANCH that exists on origin is accepted"
branch_case only-local "exists locally but not on origin" \
                       "is not a branch of this repository" \
                       "a DEFAULT_BRANCH that exists only locally warns — the PR opens against the REMOTE"
branch_case develop    "is not a branch of this repository" \
                       "exists on origin" \
                       "a DEFAULT_BRANCH that names no branch at all is refused, and the key is named"
mv .sdd/config.sh.bak .sdd/config.sh

# --- the TODO.md lint the starter suggests, run as a TEST_CMD (issue 95) -----
# config/starter.conf suggests appending the kit's own check-todo.sh to a target's TEST_CMD, with
# --baseline so a repo carrying inherited debt is not red on day one. The suggestion is a COMMENT,
# so no gate reads it, and the only proof that it works is running it the way the runner would:
# through `sdd preflight`, which evaluates TEST_CMD with run_check_cmd like every gate does. The
# spelling is READ from the starter, never retyped here — a probe with its own copy would agree
# with a suggestion it never ran. Three worlds, one file apart: the seeded TODO.md with no finding
# (green — and only because of --allow-empty: without it the floor of an empty file is rc 94);
# one malformed finding the base does not have (red); the same finding once origin/main carries it
# (green again — inherited, which is the whole point of --baseline). `origin` is the bare repo the
# DEFAULT_BRANCH block above pushed main to, without TODO.md: an empty baseline.
echo "== the starter's TODO.md lint, run as a TEST_CMD =="
cp .sdd/config.sh .sdd/config.sh.bak
cp TODO.md "$PROBE/TODO.md.bak"
todo_lint="$(sed -n "s/^#   TEST_CMD='<your suite> && \(.*\)'\$/\1/p" "$ROOT/config/starter.conf")"
todo_lint_case() { # todo_lint_case → "green" | "red" | "neither"
  local o; o="$( "$SDD" preflight 2>&1 )"
  if grep -qF 'TEST_CMD ran green' <<< "$o"; then printf green
  elif grep -qF 'TEST_CMD FAILED' <<< "$o"; then printf red
  else printf neither; fi
}
if [ -z "$todo_lint" ]; then
  fail "the TODO.md lint the starter suggests runs as a TEST_CMD" \
    "a line '#   TEST_CMD='<your suite> && …' in config/starter.conf" "no such line"
else
  { grep -v '^TEST_CMD=' .sdd/config.sh; printf "TEST_CMD='\"%s\" && %s'\n" "$PROBE/suite-green.sh" "$todo_lint"; } \
    > .sdd/config.sh.tmp && mv .sdd/config.sh.tmp .sdd/config.sh
  w_clean="$(todo_lint_case)"
  # Into the OPEN section, under its marker: appended at the end of the seed it would land below
  # the decided marker and be measured as a malformed record instead of a finding.
  sed -i '/^<!-- sdd:open -->$/a - [ ] **a finding with no anchor and no date**' TODO.md
  w_new="$(todo_lint_case)"
  git add TODO.md && git commit -qm "the base gains the finding" && git push -q origin main
  w_inherited="$(todo_lint_case)"
  assert_eq "the TODO.md lint the starter suggests runs as a TEST_CMD: green when clean, red on a new finding, green once the base has it" \
    "green / red / green" "$w_clean / $w_new / $w_inherited"
  git reset -q --hard HEAD~1 && git push -q -f origin main
fi
cp "$PROBE/TODO.md.bak" TODO.md
mv .sdd/config.sh.bak .sdd/config.sh

# --- third-party skills the phases depend on --------------------------------
# Three phases are driven by skills the kit does not ship: TICKET boots `ticket`, the two QA
# sub-steps boot `qa-report` and `qa-execution`, and REVIEW loads `codereview`. A missing one is
# not a broken kit — it is a session that boots, finds no skill, improvises, and burns the phase
# budget answering something nobody can gate.
#
# WARN and never fail: the search roots are a CONVENTION (`~/.claude/skills/`, the plugin cache,
# the project's own `.claude/skills/`), not a contract the kit can enforce, and a rule that fails on
# a heuristic is the rule the next author deletes. Same call the ddd/kaizen plugin check already
# makes, one screen up in the same command.
#
# The root is injectable so this is testable at all: with SDD_SKILLS_ROOT pointing at an empty
# directory every skill is missing, and pointing at one that holds them, none is.
echo "== third-party skills =="
cd "$FIX" || exit 1
EMPTY_SKILLS="$FIX/.skills-empty"
FULL_SKILLS="$FIX/.skills-full"
# Each skill where the harness loads it from for the form a phase invokes it by: the three invoked
# plain in the skills directory, and codereview, which REVIEW invokes as `codereview:codereview`, in
# the codereview plugin's tree under the cache (no registry here, so the cache is where it is found).
FULL_CR="$FULL_SKILLS/plugins/cache/mk/codereview/1.0.0/skills/codereview"
mkdir -p "$EMPTY_SKILLS" "$FULL_SKILLS/skills/ticket" "$FULL_SKILLS/skills/qa-report" \
         "$FULL_SKILLS/skills/qa-execution" "$FULL_CR"
for s in ticket qa-report qa-execution; do
  printf -- '---\nname: %s\n---\n' "$s" > "$FULL_SKILLS/skills/$s/SKILL.md"
done
printf -- '---\nname: codereview\n---\n' > "$FULL_CR/SKILL.md"

# JIRA on and an interface declared, so all four skills are in play.
cp .sdd/config.sh .sdd/config.sh.bak
sed -i 's|^JIRA_ENABLED=false|JIRA_ENABLED=true|; s|^E2E_CMD=""|E2E_CMD="npm run e2e"|' .sdd/config.sh
printf 'PROJECT=FX\nBOARD=1\n' > .jira-project

out_noskills="$( SDD_SKILLS_ROOT="$EMPTY_SKILLS" "$SDD" preflight 2>&1 )"
assert_has "preflight warns about a ticket skill it cannot find" "ticket" "$out_noskills"
assert_has "the warning names where it looked" "$EMPTY_SKILLS" "$out_noskills"
assert_has "the warning says what the absence costs" "boots the skill" "$out_noskills"
# And where it looked for each FORM (Codex r7 on PR #315): a plain skill in the skills directories, a
# plugin:skill one in the installs the registry records — the two places skill_findable reads.
assert_eq "the not-found warning says where it looked for a plain skill and for a plugin:skill one" \
  "plain:1 plugin:1" \
  "plain:$(grep -cF "A skill a phase invokes plain was looked for in $EMPTY_SKILLS/skills/," <<< "$out_noskills") plugin:$(grep -cF "$EMPTY_SKILLS/plugins/installed_plugins.json records for the plugin" <<< "$out_noskills")"

# The differential, one root apart: the SAME config with the skills present says nothing. Without
# it, a preflight that printed the warning unconditionally would satisfy every assertion above.
out_skills="$( SDD_SKILLS_ROOT="$FULL_SKILLS" "$SDD" preflight 2>&1 )"
assert_lacks "with the skills installed the warning is silent" "boots the skill" "$out_skills"

# The FORM each skill is asked for is the form a phase invokes it by (Codex r7 on PR #315): the
# harness resolves `/codereview:codereview` through the install its registry records for the
# codereview plugin, and a plain `/ticket` through the skills directories, so a preflight that asked
# for `codereview` plain would look where the REVIEW never loads from. Two spellings of one decision —
# the list the preflight asks for, and the invocations the kit writes — compared with EACH OTHER,
# never with a literal, so either side that moves alone turns this red. The preflight's side is the
# list it printed with all four skills in play; the kit's side is every `/[<plugin>:]<skill>` a hat
# writes in backticks, and every one phase_slash prints, for a skill the preflight names. The count
# is the floor: with the ok line gone both sides are empty, and empty equals empty.
pf_forms="$(sed -n 's/^  ok   third-party skills present (\(.*\))$/\1/p' <<< "$out_skills" | tr ' ' '\n' | sed '/^$/d' | sort -u)"
pf_names="$(sed 's/.*://' <<< "$pf_forms")"
kit_forms="$( { grep -ohE '`/[a-z0-9-]+(:[a-z0-9-]+)?[` ]' "$ROOT"/agents/*.md | sed 's/^`\///; s/.$//'
                sed -n "/^phase_slash() {/,/^}/ s#.*printf '/\([a-z0-9:-]*\) .*#\1#p" "$SDD"; } \
              | while IFS= read -r f; do grep -qxF -- "${f##*:}" <<< "$pf_names" && printf '%s\n' "$f"; done \
              | sort -u)"
assert_eq "preflight asks for each third-party skill in the form a phase invokes it, read off the hats and phase_slash" \
  "forms:4 $(paste -sd' ' - <<< "$pf_forms")" \
  "forms:$(grep -c . <<< "$kit_forms") $(paste -sd' ' - <<< "$kit_forms")"

# And the trigger is the CONFIG, not the calendar: with JIRA off, `ticket` is not asked for.
sed -i 's|^JIRA_ENABLED=true|JIRA_ENABLED=false|; s|^E2E_CMD="npm run e2e"|E2E_CMD=""|' .sdd/config.sh
out_nojira="$( SDD_SKILLS_ROOT="$EMPTY_SKILLS" "$SDD" preflight 2>&1 )"
assert_lacks "with JIRA off the ticket skill is not asked for" "ticket" "$out_nojira"
assert_lacks "with no interface the qa skills are not asked for" "qa-report" "$out_nojira"
# codereview is asked for in every project: REVIEW runs in every mission.
assert_has "codereview is asked for whatever the config says" "codereview" "$out_nojira"

rm -f .jira-project
mv .sdd/config.sh.bak .sdd/config.sh

# --- what the phases will not be able to read (ADR 0019 §2) ----------------
# Two warnings, neither a failure and neither a session. READ_EXTRA is empty by default and accepts
# a directory this machine does not have, so without them a target learns that its phases cannot
# read a skill's references from the DENIED line of a run already paid for:
#   - an entry that does not exist: named, and only it — an entry that exists is never named;
#   - a skill preflight finds (skill_findable, which publishes SKILL_FOUND_DIR) whose directory, or
#     whose `readlink -f` target, no read rule of the sessions covers: named, with the entry to add —
#     unless the directory is covered and the grammar refuses the target's name, which no entry can
#     reach: named as such, with the remedy (move or rename the target) and no entry;
#   - a plugin skill is the copy the registry (`installed_plugins.json`) records, else the first one
#     the cache holds, and a warning about a directory under the cache names that registry.
#     The rules are kit_read_rules' own, the repo is the session's cwd, and a rule covers its
#     directory and what is under `<dir>/` — never a sibling that only starts with the same letters.
# HOME is set for every run here, so the `$HOME/…` spelling of the entry is asserted both ways
# whatever the machine's TMPDIR is, and so no run reads this machine's real skills. The rc is a
# weak witness — the gh stub fails every preflight here —, so the count of `fail` lines rides
# beside it: a warning turned into a failure moves that count and not the rc.
echo "== READ_EXTRA against what this machine holds =="
cd "$FIX" || exit 1
# Its own scratch, OUTSIDE the fixture repo: everything under $FIX is the repo, the session's cwd,
# which the sessions read anyway — a skill root there is covered by construction and warns about
# nothing, whatever the rules say.
RXF="$(mktemp -d "${TMPDIR:-/tmp}/sdd-preflight-rx-XXXXXX")"
trap 'stop_page_server 2>/dev/null; rm -rf "$FIX" "$PROBE" "$ORIGIN" "$RXF"' EXIT
# rx_run <home> <skills root> <READ_EXTRA> → the preflight's output, then `rc=N` on a line of its own
rx_run() {
  local o rc=0
  o="$( HOME="$1" SDD_SKILLS_ROOT="$2" READ_EXTRA="$3" "$SDD" preflight 2>&1 )" || rc=$?
  printf '%s\nrc=%s\n' "$o" "$rc"
}
# rx_same <output A> <output B> → `same`, or what differs: the rc line and the count of fail lines
rx_same() {
  local ra rb fa fb
  ra="$(grep -E '^rc=[0-9]+$' <<< "$1" | tail -1)"; rb="$(grep -E '^rc=[0-9]+$' <<< "$2" | tail -1)"
  fa="$(grep -c '^  fail  ' <<< "$1")"; fb="$(grep -c '^  fail  ' <<< "$2")"
  if [ -n "$ra" ] && [ "$ra" = "$rb" ] && [ "$fa" = "$fb" ]; then printf 'same'
  else printf '%s/%s,fails=%s/%s' "${ra:-no-rc}" "${rb:-no-rc}" "$fa" "$fb"; fi
}
# rx_skill <output> [<form>] → missing=N,warned=N,link=N,entry=<the entries to add, comma-joined>
# for the skill a phase invokes as <form>, `codereview:codereview` by default — the REVIEW's, the one
# skill every config asks for. `missing` is the witness that the skill was FOUND at all — a run that
# lost it reads no warning too —, counted on the not-found line that lists <form> itself, so a world
# that misses another skill does not feed it; `link` counts the warnings that say the directory found
# is a symlink. The entries are every one the output hands over, whichever skill it is for.
rx_skill() {
  local f="${2:-codereview:codereview}"
  printf 'missing=%s,warned=%s,link=%s,entry=%s' "$(grep -cE "^  warn  skills not found:.* $f( |\$)" <<< "$1")" \
    "$(grep -c "^  warn  skill $f is found in " <<< "$1")" \
    "$(grep -c "^  warn  skill $f is found in .* (a symlink to " <<< "$1")" \
    "$(sed -n 's/^ *READ_EXTRA entry to add: //p' <<< "$1" | paste -sd, -)"
}
# rx_run_jira <home> <skills root> <READ_EXTRA> → rx_run with JIRA on, so `ticket`, which TICKET
# invokes plain (`/ticket open …`), is asked for beside `codereview:codereview`. The config is put
# back, and the .jira-project taken away, before it returns: every other world here runs JIRA off.
rx_run_jira() {
  local o
  cp .sdd/config.sh "$RXF/config.sh.bak"
  sed -i 's|^JIRA_ENABLED=false|JIRA_ENABLED=true|' .sdd/config.sh
  printf 'PROJECT=FX\nBOARD=1\n' > .jira-project
  o="$(rx_run "$@")"
  mv "$RXF/config.sh.bak" .sdd/config.sh
  rm -f .jira-project
  printf '%s\n' "$o"
}

# The entry that does not exist, beside one that does. Names that are not prefixes of each other,
# so a count of the present one cannot be fed by the absent one's line.
RX_HOME="$RXF/home"
RX_PRESENT="$RXF/present"
RX_ABSENT="$RXF/absent"
mkdir -p "$RX_HOME" "$RX_PRESENT"
out_rx_none="$(rx_run "$RX_HOME" "$EMPTY_SKILLS" "")"
out_rx_both="$(rx_run "$RX_HOME" "$EMPTY_SKILLS" "$RX_PRESENT $RX_ABSENT")"
assert_eq "preflight warns about a READ_EXTRA directory that does not exist, and only about it" \
  "absent:1 present:0 same:same reached:1" \
  "absent:$(grep -cF "  warn  READ_EXTRA names $RX_ABSENT, which does not exist on this machine" <<< "$out_rx_both") present:$(grep -cF -- "$RX_PRESENT" <<< "$out_rx_both") same:$(rx_same "$out_rx_both" "$out_rx_none") reached:$(grep -c '^  ok   git present$' <<< "$out_rx_both")"

# The skill nobody declared. The codereview plugin sits in the cache with its version below it, and
# `find` meets the plugin's own directory first (it walks a parent before its children), so the
# directory found IS the parent without the version: declared, it is covered by equality.
RX_SK1_HOME="$RXF/sk1"
RX_SK1_ROOT="$RX_SK1_HOME/.claude"
mkdir -p "$RX_SK1_ROOT/plugins/cache/mk/codereview/1.0.0/skills/codereview"
out_sk1_bare="$(rx_run "$RX_SK1_HOME" "$RX_SK1_ROOT" "")"
out_sk1_decl="$(rx_run "$RX_SK1_HOME" "$RX_SK1_ROOT" "$RX_SK1_ROOT/plugins/cache/mk/codereview")"
assert_eq "preflight names a skill it finds that READ_EXTRA does not declare, with the entry to add" \
  'undeclared:missing=0,warned=1,link=0,entry=$HOME/.claude/plugins/cache/mk/codereview declared:missing=0,warned=0,link=0,entry= same:same' \
  "undeclared:$(rx_skill "$out_sk1_bare") declared:$(rx_skill "$out_sk1_decl") same:$(rx_same "$out_sk1_bare" "$out_sk1_decl")"

# Found BELOW the version: a plugin whose name is not the skill's. The entry is still the plugin's
# directory, the parent without the version (two components under the cache), and it covers the
# skill through `<entry>/`. A sibling whose name only starts with the same letters covers nothing —
# the slash of `<entry>/` is what tells `codereview-x` from `codereview`. HOME is elsewhere here, so
# the entry comes back absolute.
RX_SK2_ROOT="$RXF/sk2/.claude"
RX_SK2_PLUGIN="$RX_SK2_ROOT/plugins/cache/mk/codereview-x"
mkdir -p "$RX_SK2_PLUGIN/2.0.0/skills/codereview"
out_sk2_bare="$(rx_run "$RX_HOME" "$RX_SK2_ROOT" "")"
out_sk2_parent="$(rx_run "$RX_HOME" "$RX_SK2_ROOT" "$RX_SK2_PLUGIN")"
out_sk2_sibling="$(rx_run "$RX_HOME" "$RX_SK2_ROOT" "$RX_SK2_ROOT/plugins/cache/mk/codereview")"
assert_eq "a plugin skill is covered by the directory above its version, and never by a sibling that shares a prefix" \
  "bare:missing=0,warned=1,link=0,entry=$RX_SK2_PLUGIN parent:missing=0,warned=0,link=0,entry= sibling:missing=0,warned=1,link=0,entry=$RX_SK2_PLUGIN" \
  "bare:$(rx_skill "$out_sk2_bare") parent:$(rx_skill "$out_sk2_parent") sibling:$(rx_skill "$out_sk2_sibling")"

# Reached through a symlink, as `ticket` is on the machine this was written on — so this world is
# `ticket`'s, a skill a phase invokes plain and finds in a skills directory (a plain directory is never
# where `codereview:codereview` is loaded from). The harness checks the path asked for AND the
# resolved one (p7, p10, p12 of ADR 0019), so the skill is covered only when both are: by its own
# entry, whose target kit_read_rules grants too; never by the parent above the link, nor by the target
# alone. Found inside the repo, it is the session's cwd: nothing to add. codereview:codereview is
# missing from every world of this one, which is why `missing` is counted for `ticket` alone.
RX_SK3_HOME="$RXF/sk3"
RX_SK3_ROOT="$RX_SK3_HOME/.claude"
RX_SK3_TARGET="$RXF/target/ticket-real"
mkdir -p "$RX_SK3_ROOT/skills" "$RX_SK3_TARGET"
ln -s "$RX_SK3_TARGET" "$RX_SK3_ROOT/skills/ticket"
out_sk3_above="$(rx_run_jira "$RX_SK3_HOME" "$RX_SK3_ROOT" "$RX_SK3_ROOT/skills")"
out_sk3_target="$(rx_run_jira "$RX_SK3_HOME" "$RX_SK3_ROOT" "$RX_SK3_TARGET")"
out_sk3_link="$(rx_run_jira "$RX_SK3_HOME" "$RX_SK3_ROOT" "$RX_SK3_ROOT/skills/ticket")"
mkdir -p "$FIX/.claude/skills/ticket"
out_sk3_repo="$(rx_run_jira "$RX_HOME" "$EMPTY_SKILLS" "")"
rm -rf "$FIX/.claude/skills"
assert_eq "a skill reached through a symlink is covered only with its target, and a skill in the repo needs no entry" \
  'above:missing=0,warned=1,link=1,entry=$HOME/.claude/skills/ticket target:missing=0,warned=1,link=1,entry=$HOME/.claude/skills/ticket link:missing=0,warned=0,link=0,entry= repo:missing=0,warned=0,link=0,entry=' \
  "above:$(rx_skill "$out_sk3_above" ticket) target:$(rx_skill "$out_sk3_target" ticket) link:$(rx_skill "$out_sk3_link" ticket) repo:$(rx_skill "$out_sk3_repo" ticket)"

# The declared skill whose target no rule can name (r1 #1 of the final review). The entry is the link
# itself, so the directory found is covered by equality — but its target is `odd[1]`, which the
# grammar refuses (a bracket expression to the harness), so kit_read_rules grants the target nothing
# and the phase is still DENIED. Handing back the entry the human already has is a loop with no way
# out: the warning names the refused target and the remedy (move or rename it), and no entry to add.
# Undeclared, the same world keeps the warning of the skill nobody declared, entry and all. The rc and
# the `warn` prefix are shared by both branches, so each needle is one branch's own text, and the
# absence of `entry to add` is counted over the whole output, not only on the entry's line. A symlink
# in a skills directory is a plain skill's, so the world is `ticket`'s, as the one above.
RX_SK5_HOME="$RXF/sk5"
RX_SK5_ROOT="$RX_SK5_HOME/.claude"
RX_SK5_TARGET="$RX_SK5_ROOT/skills/odd[1]"
mkdir -p "$RX_SK5_TARGET"
ln -s 'odd[1]' "$RX_SK5_ROOT/skills/ticket"
out_sk5_bare="$(rx_run_jira "$RX_SK5_HOME" "$RX_SK5_ROOT" "")"
out_sk5_decl="$(rx_run_jira "$RX_SK5_HOME" "$RX_SK5_ROOT" "$RX_SK5_ROOT/skills/ticket")"
# rx_refused <output> → refused=N,remedy=N,undeclared=N,add=N — the new branch's first line, its
# remedy, the old branch's clause, and every `entry to add` anywhere in the output.
rx_refused() {
  printf 'refused=%s,remedy=%s,undeclared=%s,add=%s' \
    "$(grep -cF "  warn  skill ticket is found in $RX_SK5_ROOT/skills/ticket (a symlink to $RX_SK5_TARGET), whose target no read rule can cover:" <<< "$1")" \
    "$(grep -c 'move or rename the target to a name the grammar accepts' <<< "$1")" \
    "$(grep -c 'READ_EXTRA does not declare it' <<< "$1")" \
    "$(grep -c 'entry to add' <<< "$1")"
}
assert_eq "a declared skill whose symlink target the grammar refuses is named as such, never as undeclared" \
  'bare:refused=0,remedy=0,undeclared=1,add=1|missing=0,warned=1,link=1,entry=$HOME/.claude/skills/ticket decl:refused=1,remedy=1,undeclared=0,add=0|missing=0,warned=1,link=1,entry= same:same' \
  "bare:$(rx_refused "$out_sk5_bare")|$(rx_skill "$out_sk5_bare" ticket) decl:$(rx_refused "$out_sk5_decl")|$(rx_skill "$out_sk5_decl" ticket) same:$(rx_same "$out_sk5_bare" "$out_sk5_decl")"

# The edges of the entry's spelling. A skill directory met one level under the cache has no version
# above it, so the entry is the directory itself, never a second copy of its name. `$HOME` is written
# only under a real HOME: one with a trailing slash still counts, and an EMPTY one would make every
# absolute path look like it is under it.
RX_SK4_HOME="$RXF/sk4"
RX_SK4_DIR="$RX_SK4_HOME/.claude/plugins/cache/codereview"
mkdir -p "$RX_SK4_DIR"
out_sk4_slash="$(rx_run "$RX_SK4_HOME/" "$RX_SK4_HOME/.claude" "")"
out_sk4_nohome="$(rx_run "" "$RX_SK4_HOME/.claude" "")"
assert_eq "the entry is the directory found when no version sits above it, and \$HOME is written only under a real HOME" \
  "slash:missing=0,warned=1,link=0,entry=\$HOME/.claude/plugins/cache/codereview nohome:missing=0,warned=1,link=0,entry=$RX_SK4_DIR" \
  "slash:$(rx_skill "$out_sk4_slash") nohome:$(rx_skill "$out_sk4_nohome")"

# A skill found in the plugin cache (r1 #2 of the final review). The cache keeps every copy ever
# fetched, under every marketplace that shipped the plugin, and the copy the harness loads is the
# installPath its registry records — so a warning about a directory under `<root>/plugins/cache/`
# says the cache may hold more than one copy and names `<root>/plugins/installed_plugins.json`. One
# about a directory outside the cache says neither: `<root>/skills/` here, and a copy the registry
# records under a sibling that only starts with the same letters (`plugins/cachex`), which is what
# the slash of `cache/` tells apart. SK1 is the cache world, with no registry at all. The skills
# directory is a plain skill's, so SK6 is `ticket`'s; its run misses codereview:codereview, whose
# not-found warning names the registry too, which is why `file` reads the note's own clause.
RX_SK6_HOME="$RXF/sk6"
RX_SK6_ROOT="$RX_SK6_HOME/.claude"
mkdir -p "$RX_SK6_ROOT/skills/ticket"
out_sk6_skills="$(rx_run_jira "$RX_SK6_HOME" "$RX_SK6_ROOT" "")"
RX_SK7_ROOT="$RXF/sk7/.claude"
RX_SK7_COPY="$RX_SK7_ROOT/plugins/cachex/mk/codereview/1.0.0"
mkdir -p "$RX_SK7_COPY/skills/codereview"
printf '{"version":2,"plugins":{"codereview@mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK7_COPY" > "$RX_SK7_ROOT/plugins/installed_plugins.json"
out_sk7_cachex="$(rx_run "$RX_HOME" "$RX_SK7_ROOT" "")"
# rx_cache <output> <skills root> → copies=N,file=N,which=N — the phrase, that root's registry
# named by the note, and the line that says which copy the warning names
rx_cache() {
  printf 'copies=%s,file=%s,which=%s' "$(grep -c 'may hold more than one copy' <<< "$1")" \
    "$(grep -cF "the installPath recorded in $2/plugins/installed_plugins.json: the copy named" <<< "$1")" \
    "$(grep -c 'the first copy found when it does not' <<< "$1")"
}
assert_eq "a skill found in the plugin cache is warned with installed_plugins.json named, since the cache may hold more than one copy" \
  "cache:copies=1,file=1,which=1|missing=0,warned=1,link=0,entry=\$HOME/.claude/plugins/cache/mk/codereview skills:copies=0,file=0,which=0|missing=0,warned=1,link=0,entry=\$HOME/.claude/skills/ticket cachex:copies=0,file=0,which=0|missing=0,warned=1,link=0,entry=$RX_SK7_COPY/skills/codereview" \
  "cache:$(rx_cache "$out_sk1_bare" "$RX_SK1_ROOT")|$(rx_skill "$out_sk1_bare") skills:$(rx_cache "$out_sk6_skills" "$RX_SK6_ROOT")|$(rx_skill "$out_sk6_skills" ticket) cachex:$(rx_cache "$out_sk7_cachex" "$RX_SK7_ROOT")|$(rx_skill "$out_sk7_cachex")"

# WHICH copy: the one the registry records (the same finding). Two marketplaces ship the plugin, and
# the registry lists, in this order: a user-scope plugin that holds no `codereview` skill; the `zz-mk`
# copy under PROJECT scope — another repo's pin, which this preflight does not speak for, the call
# health makes for the grade table; and the `aa-mk` copy under user scope, the one held to the rules.
# `find` meets each plugin's own directory first, above its versions, so falling back to it names
# `…/<mk>/codereview` and never the copy's `…/2.0.0/skills/codereview`, whichever marketplace the
# directory order puts first: the needle tells the readers apart in every order. Declared, the right
# copy's parent covers it and nothing is said — the reviewer's world, where the warning fired with
# the right copy declared and asked for the other. HOME is elsewhere, so a registry read off $HOME
# instead of the skills root reads nothing. A registry jq cannot read is no registry: the copy `find`
# meets, the rc and fail count of a readable one, and none of jq's complaints in the output.
RX_SK8_ROOT="$RXF/sk8/.claude"
RX_SK8_CACHE="$RX_SK8_ROOT/plugins/cache"
mkdir -p "$RX_SK8_CACHE/zz-mk/codereview/1.0.0/skills/codereview" \
         "$RX_SK8_CACHE/aa-mk/codereview/2.0.0/skills/codereview" "$RX_SK8_CACHE/aa-mk/other/1.0.0/skills/other"
printf '{"version":2,"plugins":{"other@aa-mk":[{"scope":"user","installPath":"%s"}],"codereview@zz-mk":[{"scope":"project","projectPath":"/elsewhere","installPath":"%s"}],"codereview@aa-mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK8_CACHE/aa-mk/other/1.0.0" "$RX_SK8_CACHE/zz-mk/codereview/1.0.0" "$RX_SK8_CACHE/aa-mk/codereview/2.0.0" \
  > "$RX_SK8_ROOT/plugins/installed_plugins.json"
out_sk8_bare="$(rx_run "$RX_HOME" "$RX_SK8_ROOT" "")"
out_sk8_decl="$(rx_run "$RX_HOME" "$RX_SK8_ROOT" "$RX_SK8_CACHE/aa-mk/codereview")"
RX_SK9_ROOT="$RXF/sk9/.claude"
mkdir -p "$RX_SK9_ROOT/plugins/cache/mk/codereview/1.0.0/skills/codereview"
printf '{' > "$RX_SK9_ROOT/plugins/installed_plugins.json"
out_sk9_bad="$(rx_run "$RX_HOME" "$RX_SK9_ROOT" "")"
# The registry's line is read whole: a copy whose last component carries a backslash and ends in a
# space is still that copy, never a mangled path that falls back to the cache. The JSON is built
# by jq, so the backslash is escaped as the harness would escape it.
RX_SK10_ROOT="$RXF/sk10/.claude"
RX_SK10_COPY="$RX_SK10_ROOT/plugins/cache/mk/codereview/v\\1 "
mkdir -p "$RX_SK10_COPY/skills/codereview"
jq -n --arg p "$RX_SK10_COPY" '{version: 2, plugins: {"codereview@mk": [{scope: "user", installPath: $p}]}}' \
  > "$RX_SK10_ROOT/plugins/installed_plugins.json"
out_sk10_odd="$(rx_run "$RX_HOME" "$RX_SK10_ROOT" "")"
# rx_where <output> <dir> [<form>] → 1 when the warning about <form> (codereview:codereview by
# default) names <dir> as the directory found, else 0
rx_where() { grep -cF "  warn  skill ${3:-codereview:codereview} is found in $2, and no read rule" <<< "$1"; }
assert_eq "the copy installed_plugins.json records is the one held to the rules, and an unreadable registry falls back to the cache" \
  "bare:where=1|missing=0,warned=1,link=0,entry=$RX_SK8_CACHE/aa-mk/codereview decl:missing=0,warned=0,link=0,entry= bad:where=1|missing=0,warned=1,link=0,entry=$RX_SK9_ROOT/plugins/cache/mk/codereview same:same noise=0 odd:where=1" \
  "bare:where=$(rx_where "$out_sk8_bare" "$RX_SK8_CACHE/aa-mk/codereview/2.0.0/skills/codereview")|$(rx_skill "$out_sk8_bare") decl:$(rx_skill "$out_sk8_decl") bad:where=$(rx_where "$out_sk9_bad" "$RX_SK9_ROOT/plugins/cache/mk/codereview")|$(rx_skill "$out_sk9_bad") same:$(rx_same "$out_sk9_bad" "$out_sk8_bare") noise=$(grep -c 'jq: ' <<< "$out_sk9_bad") odd:where=$(rx_where "$out_sk10_odd" "$RX_SK10_COPY/skills/codereview")"

# WHOSE copy: the codereview plugin's (Codex r3 #1 on PR #315). The REVIEW phase loads
# `/codereview:codereview`, the skill of the plugin named codereview, so a registry entry counts only
# under that plugin's own key, `codereview@<marketplace>` — the call health_provenance makes for the
# grade table, through the same reader. Two worlds, each listing a user-scope plugin that ALSO holds
# a `skills/codereview` before `codereview@mk`: OTHER is another plugin (`other@mk`), PREFIX one whose
# name only starts with the same letters (`codereview-x@mk`), which a key prefix without its `@`
# would take. In both the directory found, the warning and its entry are codereview@mk's, and
# declared, that copy's parent covers it and nothing is said. `find` meets a plugin's own directory
# before its versions, so a reader that fell back to the cache names `…/mk/<plugin>`, never the
# copy's `…/2.0.0/skills/codereview`: the needle tells the registry from the fallback in any order.
RX_SK11_ROOT="$RXF/sk11/.claude"
RX_SK11_CACHE="$RX_SK11_ROOT/plugins/cache"
mkdir -p "$RX_SK11_CACHE/mk/other/1.0.0/skills/codereview" "$RX_SK11_CACHE/mk/codereview/2.0.0/skills/codereview"
printf '{"version":2,"plugins":{"other@mk":[{"scope":"user","installPath":"%s"}],"codereview@mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK11_CACHE/mk/other/1.0.0" "$RX_SK11_CACHE/mk/codereview/2.0.0" > "$RX_SK11_ROOT/plugins/installed_plugins.json"
out_sk11_bare="$(rx_run "$RX_HOME" "$RX_SK11_ROOT" "")"
out_sk11_decl="$(rx_run "$RX_HOME" "$RX_SK11_ROOT" "$RX_SK11_CACHE/mk/codereview")"
RX_SK12_ROOT="$RXF/sk12/.claude"
RX_SK12_CACHE="$RX_SK12_ROOT/plugins/cache"
mkdir -p "$RX_SK12_CACHE/mk/codereview-x/1.0.0/skills/codereview" "$RX_SK12_CACHE/mk/codereview/2.0.0/skills/codereview"
printf '{"version":2,"plugins":{"codereview-x@mk":[{"scope":"user","installPath":"%s"}],"codereview@mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK12_CACHE/mk/codereview-x/1.0.0" "$RX_SK12_CACHE/mk/codereview/2.0.0" > "$RX_SK12_ROOT/plugins/installed_plugins.json"
out_sk12_bare="$(rx_run "$RX_HOME" "$RX_SK12_ROOT" "")"
assert_eq "a plugin skill is looked up in the registry only under its own plugin key, never another plugin" \
  "other:where=1|missing=0,warned=1,link=0,entry=$RX_SK11_CACHE/mk/codereview decl:missing=0,warned=0,link=0,entry= prefix:where=1|missing=0,warned=1,link=0,entry=$RX_SK12_CACHE/mk/codereview" \
  "other:where=$(rx_where "$out_sk11_bare" "$RX_SK11_CACHE/mk/codereview/2.0.0/skills/codereview")|$(rx_skill "$out_sk11_bare") decl:$(rx_skill "$out_sk11_decl") prefix:where=$(rx_where "$out_sk12_bare" "$RX_SK12_CACHE/mk/codereview/2.0.0/skills/codereview")|$(rx_skill "$out_sk12_bare")"

# HOW the phase invokes it (Codex r7 #1 on PR #315). REVIEW invokes `/codereview:codereview`, which
# the harness resolves through the install the registry records for the codereview plugin — so a
# plain `<root>/skills/codereview` beside it is a directory no phase loads, and neither the copy held
# to the rules nor an entry that covers it. One world, JIRA on, holding both: the plain directory, and
# the plugin registered with its `skills/codereview`; and `ticket`, which TICKET invokes plain, in the
# plain skills directory too. Bare, the codereview warning names the plugin's copy and never the plain
# directory, while ticket's names its plain directory: the same root, two forms, two places. Declaring
# the two plain directories silences ticket and NOT codereview, whose entry is still the plugin's;
# declaring the plugin's parent silences codereview. The plain directory's path is not a prefix of the
# copy's, so its count is fed by nothing else.
RX_SK13_ROOT="$RXF/sk13/.claude"
RX_SK13_CACHE="$RX_SK13_ROOT/plugins/cache"
RX_SK13_COPY="$RX_SK13_CACHE/mk/codereview/2.0.0"
mkdir -p "$RX_SK13_ROOT/skills/codereview" "$RX_SK13_ROOT/skills/ticket" "$RX_SK13_COPY/skills/codereview"
printf '{"version":2,"plugins":{"codereview@mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK13_COPY" > "$RX_SK13_ROOT/plugins/installed_plugins.json"
out_sk13_bare="$(rx_run_jira "$RX_HOME" "$RX_SK13_ROOT" "")"
out_sk13_plain="$(rx_run_jira "$RX_HOME" "$RX_SK13_ROOT" "$RX_SK13_ROOT/skills/codereview $RX_SK13_ROOT/skills/ticket")"
out_sk13_plugin="$(rx_run_jira "$RX_HOME" "$RX_SK13_ROOT" "$RX_SK13_CACHE/mk/codereview $RX_SK13_ROOT/skills/ticket")"
# rx_form <output> → cr=<where the plugin copy>/<where the plain dir>,tk=<ticket where its plain dir>
rx_form() {
  printf 'cr=%s/%s,tk=%s' "$(rx_where "$1" "$RX_SK13_COPY/skills/codereview")" \
    "$(grep -cF "is found in $RX_SK13_ROOT/skills/codereview" <<< "$1")" \
    "$(rx_where "$1" "$RX_SK13_ROOT/skills/ticket" ticket)"
}
assert_eq "a skill the phase invokes as plugin:skill is looked up in the plugin registry before any plain skills directory" \
  "bare:cr=1/0,tk=1|missing=0,warned=1,link=0,entry=$RX_SK13_CACHE/mk/codereview,$RX_SK13_ROOT/skills/ticket plain:cr=1/0,tk=0|missing=0,warned=1,link=0,entry=$RX_SK13_CACHE/mk/codereview plugin:cr=0/0,tk=0|missing=0,warned=0,link=0,entry=" \
  "bare:$(rx_form "$out_sk13_bare")|$(rx_skill "$out_sk13_bare") plain:$(rx_form "$out_sk13_plain")|$(rx_skill "$out_sk13_plain") plugin:$(rx_form "$out_sk13_plugin")|$(rx_skill "$out_sk13_plugin")"

# A registry that records the plugin and no install of it that holds the skill (Codex r7 #2 on PR
# #315) — a partial clean of the cache took the recorded `mk/codereview/2.0.0` away and left an older
# copy under another marketplace. The harness keeps resolving the plugin by the recorded install, so
# the skill is not where it loads it from: a BROKEN install, warned by name — the registry and the
# installPath, and the remedy —, never the cache copy held to the rules in its place, and not reported
# present either. The differential, the same cache with no key of the plugin in the registry: the cache
# copy is found, as before. Two more worlds, JIRA on. RESET: the broken world with `ticket` absent,
# where ticket is not found and reads as such, not as the broken reason of the skill before it. PLAIN:
# `ticket`, invoked plain, whose own key records an install without the skill, still goes on to the
# cache, as it always did — the broken install is the plugin form's, and the plain path is not
# narrowed; codereview's own install is registered and whole there. Every stale copy sits under
# `old-mk`, a name nothing else in these worlds carries. The broken world records the plugin under two
# marketplaces, so the warning has to name both installs, in file order and apart.
RX_SK14_ROOT="$RXF/sk14/.claude"
RX_SK14_CACHE="$RX_SK14_ROOT/plugins/cache"
RX_SK14_REC="$RX_SK14_CACHE/mk/codereview/2.0.0"
RX_SK14_REC2="$RX_SK14_CACHE/mk2/codereview/3.0.0"
mkdir -p "$RX_SK14_CACHE/old-mk/codereview/1.0.0/skills/codereview"
printf '{"version":2,"plugins":{"codereview@mk":[{"scope":"user","installPath":"%s"}],"codereview@mk2":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK14_REC" "$RX_SK14_REC2" > "$RX_SK14_ROOT/plugins/installed_plugins.json"
out_sk14_broken="$(rx_run "$RX_HOME" "$RX_SK14_ROOT" "")"
out_sk14_reset="$(rx_run_jira "$RX_HOME" "$RX_SK14_ROOT" "")"
RX_SK15_ROOT="$RXF/sk15/.claude"
RX_SK15_CACHE="$RX_SK15_ROOT/plugins/cache"
mkdir -p "$RX_SK15_CACHE/old-mk/codereview/1.0.0/skills/codereview" "$RX_SK15_CACHE/mk/other/1.0.0"
printf '{"version":2,"plugins":{"other@mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK15_CACHE/mk/other/1.0.0" > "$RX_SK15_ROOT/plugins/installed_plugins.json"
out_sk15_nokey="$(rx_run "$RX_HOME" "$RX_SK15_ROOT" "")"
RX_SK16_ROOT="$RXF/sk16/.claude"
RX_SK16_CACHE="$RX_SK16_ROOT/plugins/cache"
mkdir -p "$RX_SK16_CACHE/mk/codereview/2.0.0/skills/codereview" "$RX_SK16_CACHE/old-mk/ticket/1.0.0/skills/ticket"
printf '{"version":2,"plugins":{"codereview@mk":[{"scope":"user","installPath":"%s"}],"ticket@mk":[{"scope":"user","installPath":"%s"}]}}\n' \
  "$RX_SK16_CACHE/mk/codereview/2.0.0" "$RX_SK16_CACHE/mk/ticket/2.0.0" > "$RX_SK16_ROOT/plugins/installed_plugins.json"
out_sk16_plain="$(rx_run_jira "$RX_HOME" "$RX_SK16_ROOT" "")"
# rx_broken <output> <skills root> <recorded installs> → broken=N,any=N,remedy=N,stale=N,present=N —
# the broken warning naming that registry and those installs, every broken warning, the remedy, every
# line that names a stale copy, and the line that reports every skill present
rx_broken() {
  printf 'broken=%s,any=%s,remedy=%s,stale=%s,present=%s' \
    "$(grep -cF "  warn  skill codereview:codereview is not where the harness loads it: $2/plugins/installed_plugins.json records the codereview plugin installed at $3, and no such install holds skills/codereview" <<< "$1")" \
    "$(grep -c 'is not where the harness loads it' <<< "$1")" \
    "$(grep -c 'Reinstall the codereview plugin' <<< "$1")" \
    "$(grep -c 'old-mk' <<< "$1")" \
    "$(grep -c '^  ok   third-party skills present' <<< "$1")"
}
assert_eq "a recorded plugin install that lacks the skill is warned as broken, never replaced by a cache copy" \
  "broken:broken=1,any=1,remedy=1,stale=0,present=0|missing=0,warned=0,link=0,entry= nokey:where=1|missing=0,warned=1,link=0,entry=$RX_SK15_CACHE/old-mk/codereview reset:broken=1,any=1|missing=1,warned=0,link=0,entry=|missing=0,warned=0,link=0,entry= plain:any=0,where=1|missing=0,warned=1,link=0,entry=$RX_SK16_CACHE/mk/codereview,$RX_SK16_CACHE/old-mk/ticket" \
  "broken:$(rx_broken "$out_sk14_broken" "$RX_SK14_ROOT" "$RX_SK14_REC, $RX_SK14_REC2")|$(rx_skill "$out_sk14_broken") nokey:where=$(rx_where "$out_sk15_nokey" "$RX_SK15_CACHE/old-mk/codereview")|$(rx_skill "$out_sk15_nokey") reset:$(rx_broken "$out_sk14_reset" "$RX_SK14_ROOT" "$RX_SK14_REC, $RX_SK14_REC2" | cut -d, -f1-2)|$(rx_skill "$out_sk14_reset" ticket)|$(rx_skill "$out_sk14_reset") plain:any=$(grep -c 'is not where the harness loads it' <<< "$out_sk16_plain"),where=$(rx_where "$out_sk16_plain" "$RX_SK16_CACHE/old-mk/ticket" ticket)|$(rx_skill "$out_sk16_plain" ticket)"

# --- is anything listening where APP_URL points? ----------------------------
# preflight ran fifteen checks and never once touched APP_URL, so the one thing that costs a whole
# opus session to discover — the app is not up — was the one thing it could not say. Measured on
# the SQ-111 mission of 2026-08-27: US$ 14,16 for a QA phase reproved by the environment.
#
# FLOOR FIRST, and NOT written with the runner's own app_probe: a floor that reuses the function
# under test measures the runner with the runner.
echo "== is anything listening where APP_URL points =="
cd "$FIX" || exit 1
port_is_free() {  # rc 0 = nothing is listening on 127.0.0.1:$1
  local rc=0
  LC_ALL=C timeout 3 bash -c 'exec 3<>"/dev/tcp/127.0.0.1/$0"' "$1" 2>/dev/null || rc=$?
  [ "$rc" -ne 0 ]
}

# start_page_server <dir> — serves <dir> over HTTP on a free loopback port and publishes PAGE_PORT
# and PAGE_PID. CALLED, never `$( )`: the two globals would die with the subshell. PAGE_PORT stays
# empty when no server came up, and the caller fails BY NAME rather than certifying nothing. The
# server has to be OUR process (`kill -0` once the port answers): a neighbour sensor binding the
# same port between the free check and our bind would otherwise be read as ours. 30000-31999 sits
# under the ephemeral range, like the dead port above; `timeout 900` bounds an orphan if this shell
# is killed before its EXIT trap runs, and the trap kills it on every ordinary exit.
PAGE_PID=""; PAGE_PORT=""
start_page_server() {
  local port=$(( 30000 + $$ % 2000 )) tries=0 waited
  PAGE_PID=""; PAGE_PORT=""
  while [ "$tries" -lt 10 ]; do
    tries=$(( tries + 1 )); port=$(( port + 1 ))
    port_is_free "$port" || continue
    timeout 900 python3 -m http.server "$port" --bind 127.0.0.1 --directory "$1" >/dev/null 2>&1 &
    PAGE_PID=$!
    waited=0
    while port_is_free "$port" && [ "$waited" -lt 50 ]; do sleep 0.1; waited=$(( waited + 1 )); done
    if ! port_is_free "$port" && kill -0 "$PAGE_PID" 2>/dev/null; then PAGE_PORT="$port"; return 0; fi
    kill "$PAGE_PID" 2>/dev/null; wait "$PAGE_PID" 2>/dev/null || true; PAGE_PID=""
  done
  return 0
}
stop_page_server() {
  if [ -n "$PAGE_PID" ]; then kill "$PAGE_PID" 2>/dev/null; wait "$PAGE_PID" 2>/dev/null || true; fi
  PAGE_PID=""; PAGE_PORT=""
}
# BELOW the ephemeral range, and that is what makes the floor hold for the whole block. The floor
# proves the port refuses ONCE; the assertions under it then run several `sdd` invocations over
# minutes against that one measurement. Drawn from 49152-59171 the port sat INSIDE the kernel's
# `ip_local_port_range` (32768-60999 by default), so it could be handed out mid-block and the
# assertions would flip for a reason that has nothing to do with the runner. 20000-29999 is under
# that floor. DECLARED LIMIT: a machine that lowered `ip_local_port_range` past 20000, or that
# starts a real listener there mid-block, is back in the old window — the search loop below only
# re-measures at the start, and re-measuring per assertion would buy a smaller window at the price
# of a floor nobody can read.
dead_port=$(( 20000 + $$ % 10000 ))
app_floor_ok=1
if ! command -v timeout >/dev/null 2>&1; then
  fail "dead-app floor" "timeout(1) on PATH" "timeout is missing — the APP_URL block was NOT measured"
  app_floor_ok=0
else
  tries=0
  while ! port_is_free "$dead_port"; do
    dead_port=$(( dead_port + 1 )); tries=$(( tries + 1 ))
    if [ "$tries" -ge 20 ]; then
      fail "dead-app floor" "a refused port on 127.0.0.1" \
           "20 consecutive ports were all listening — the block would certify nothing"
      app_floor_ok=0; break
    fi
  done
fi

if [ "$app_floor_ok" = "1" ]; then
  pass "dead-app floor: 127.0.0.1:$dead_port refuses connections"
  cp .sdd/config.sh .sdd/config.sh.bak
  DEAD="http://127.0.0.1:$dead_port/"

  # ⭐ THE PAIR, and APP_URL is held CONSTANT across it while E2E_CMD moves — the opposite of the
  # pair in check-autonomy.sh, and for a reason. Every other APP_URL-sensitive check in preflight
  # (the browser, the qa skills) keys on `E2E_CMD OR APP_URL`, so with APP_URL non-empty on both
  # sides they fire identically and the ONLY thing that can move the failed count is the new
  # check. Varying APP_URL instead would flip the browser check with it, and the +1 could not be
  # attributed.
  #
  # And the direction is the whole policy: a dead app is a FAILURE only when E2E_CMD is
  # configured, because that is the case where a gate is about to run a suite against an app that
  # is not there. Without E2E_CMD nothing automatic runs against it, so the same fact is a warning
  # for the human who is about to walk the journey — never a refusal to start the mission.
  sed -i "s|^E2E_CMD=.*|E2E_CMD=\"npm run e2e\"|" .sdd/config.sh
  printf 'APP_URL="%s"\n' "$DEAD" >> .sdd/config.sh
  out_dead_e2e="$( "$SDD" preflight 2>&1 )"

  sed -i 's|^E2E_CMD=.*|E2E_CMD=""|' .sdd/config.sh
  out_dead_alone="$( "$SDD" preflight 2>&1 )"

  n_e2e="$(failed_count "$out_dead_e2e")"
  n_alone="$(failed_count "$out_dead_alone")"
  assert_eq "a dead app with E2E_CMD set is one MORE failed check than the same dead app without it" \
    "one more" \
    "$( [ -n "$n_e2e" ] && [ -n "$n_alone" ] && [ "$n_e2e" -eq $(( n_alone + 1 )) ] \
        && echo "one more" || echo "$n_alone -> $n_e2e" )"

  assert_has "and it names the address, so the human knows what to start" \
    "127.0.0.1:$dead_port" "$out_dead_e2e"
  assert_has "the refusal says WHY a dead app is fatal here, not just that it is dead" \
    "E2E_CMD" "$out_dead_e2e"
  # The other half of the pair, and the one that keeps the fix from being wider than the defect:
  # with no E2E_CMD the same dead app is still REPORTED, and still not a refusal.
  assert_has "without E2E_CMD the dead app is still reported" \
    "127.0.0.1:$dead_port" "$out_dead_alone"

  # An APP_URL this cannot read is NOT a dead app, and saying so is the one-sided contract of the
  # probe carried through to the human: `unknown` never becomes a refusal, whatever E2E_CMD says.
  sed -i "s|^E2E_CMD=.*|E2E_CMD=\"npm run e2e\"|" .sdd/config.sh
  sed -i 's|^APP_URL=.*|APP_URL="not a url"|' .sdd/config.sh
  out_unknown="$( "$SDD" preflight 2>&1 )"
  n_unknown="$(failed_count "$out_unknown")"
  assert_eq "an APP_URL that cannot be read is a warning, never a refusal — even with E2E_CMD set" \
    "no extra failure" \
    "$( [ -n "$n_unknown" ] && [ -n "$n_alone" ] && [ "$n_unknown" -eq "$n_alone" ] \
        && echo "no extra failure" || echo "$n_alone -> $n_unknown" )"
  assert_has "and it says why it could not tell, instead of claiming the app is down" \
    "no verdict on" "$out_unknown"
  assert_lacks "an unreadable APP_URL never claims a dead app" \
    "nothing is listening" "$out_unknown"

  # Empty APP_URL: nothing to probe, and nothing said about listening either way. This is the
  # regime EVERY repo without an interface is in, so a line here that fired would fire everywhere.
  sed -i 's|^APP_URL=.*|APP_URL=""|' .sdd/config.sh
  out_noapp="$( "$SDD" preflight 2>&1 )"
  assert_lacks "an empty APP_URL claims nothing about listening" "nothing is listening" "$out_noapp"
  assert_lacks "an empty APP_URL is not reported as unprobed either" "no verdict on" "$out_noapp"

  # --- something answers, but it is NOT this product (APP_EXPECT) ----------------------------
  # Measured in LH-4 (2026-09-27): lighthouse and sales_quote both declare
  # APP_URL=http://localhost:5173, this printed "something is listening", and the QA session
  # opened against the other product's dev server and stopped `blocked`. APP_EXPECT is a literal
  # the page must carry. The server is REAL, because the probe reads the page: python3's
  # http.server over a page whose <title> is another product's.
  #
  # THE PAIR keeps E2E_CMD and the address constant and moves only APP_EXPECT, so the failed count
  # can move for one reason. A shadow PATH (every executable minus curl, the no-jq technique
  # below) is the one-sided half: no curl, no verdict, never a refusal.
  page_dir="$FIX/.page"; mkdir -p "$page_dir"
  printf '<!doctype html><title>Other Product</title><p>not the fixture</p>\n' > "$page_dir/index.html"
  nocurl="$FIX/.nocurl-bin"; mkdir -p "$nocurl"
  IFS=: read -r -a path_dirs <<< "$PATH"
  for d in "${path_dirs[@]}"; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      n="${f##*/}"
      [ "$n" = curl ] && continue
      [ -x "$f" ] && [ ! -e "$nocurl/$n" ] && ln -s "$f" "$nocurl/$n"
    done
  done
  start_page_server "$page_dir"
  if [ -z "$PAGE_PORT" ]; then
    fail "wrong-app floor" "an HTTP server on a loopback port" \
         "python3 -m http.server did not come up — the APP_EXPECT block was NOT measured"
  else
    page_port="$PAGE_PORT"
    sed -i "s|^E2E_CMD=.*|E2E_CMD=\"npm run e2e\"|" .sdd/config.sh
    sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$page_port/\"|" .sdd/config.sh
    printf 'APP_EXPECT=""\n' >> .sdd/config.sh
    out_page_tcp="$( "$SDD" preflight 2>&1 )"
    sed -i 's|^APP_EXPECT=.*|APP_EXPECT="Fixture Product"|' .sdd/config.sh
    rc_page_wrong=0; out_page_wrong="$( "$SDD" preflight 2>&1 )" || rc_page_wrong=$?
    out_page_nocurl="$( PATH="$nocurl" "$SDD" preflight 2>&1 )"
    sed -i 's|^APP_EXPECT=.*|APP_EXPECT="Other Product"|' .sdd/config.sh
    out_page_right="$( "$SDD" preflight 2>&1 )"
    # A redirect or an error page is not a page to judge: the RIGHT product may answer `/` with a
    # 302 to its login, or a 500 the mission's own code caused, and neither carries the <title>.
    # Read as `wrong`, that was a false BLOCKED — "not this product, no session can fix that" over
    # an app a session could fix. So only a 2xx without the literal is `wrong`; anything else
    # without it is doubt, and doubt never refuses. http.server answers `/sub` with a 301 to
    # `/sub/` (whose page DOES carry the literal: following it would read `up`, never `wrong`),
    # and `/missing` with its own 404 page.
    mkdir -p "$page_dir/sub"
    printf '<!doctype html><title>Fixture Product</title>\n' > "$page_dir/sub/index.html"
    sed -i 's|^APP_EXPECT=.*|APP_EXPECT="Fixture Product"|' .sdd/config.sh
    sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$page_port/sub\"|" .sdd/config.sh
    out_page_redirect="$( "$SDD" preflight 2>&1 )"
    sed -i "s|^APP_URL=.*|APP_URL=\"http://127.0.0.1:$page_port/missing\"|" .sdd/config.sh
    out_page_404="$( "$SDD" preflight 2>&1 )"
    stop_page_server

    n_tcp="$(failed_count "$out_page_tcp")"
    n_wrong="$(failed_count "$out_page_wrong")"
    n_right="$(failed_count "$out_page_right")"
    n_nocurl="$(failed_count "$out_page_nocurl")"
    assert_eq "a page without APP_EXPECT fails the preflight when E2E_CMD is set" \
      "one more · rc≠0 · named" \
      "$( [ -n "$n_wrong" ] && [ "${n_wrong:-0}" -eq $(( ${n_tcp:-0} + 1 )) ] && echo 'one more' || echo "$n_tcp -> $n_wrong" ) · $( [ "$rc_page_wrong" -ne 0 ] && echo 'rc≠0' || echo rc=0 ) · $( grep -qF "APP_EXPECT 'Fixture Product'" <<< "$out_page_wrong" && echo named || echo unnamed )"
    assert_eq "an empty APP_EXPECT keeps the TCP-only probe" "listening · silent" \
      "$( grep -qF "something is listening at 127.0.0.1:$page_port" <<< "$out_page_tcp" && echo listening || echo quiet ) · $( grep -qF 'APP_EXPECT' <<< "$out_page_tcp" && echo 'says APP_EXPECT' || echo silent )"
    # The control of the pair: the SAME page, an APP_EXPECT it carries — curl ran and matched, so a
    # runner whose `wrong` came from a failed read instead of a missing literal takes this red.
    assert_eq "a page that carries APP_EXPECT reads as listening, with no extra failure" \
      "listening · no extra failure" \
      "$( grep -qF "something is listening at 127.0.0.1:" <<< "$out_page_right" && echo listening || echo quiet ) · $( [ -n "$n_right" ] && [ "$n_right" = "$n_tcp" ] && echo 'no extra failure' || echo "$n_tcp -> $n_right" )"
    n_redirect="$(failed_count "$out_page_redirect")"
    n_404="$(failed_count "$out_page_404")"
    assert_eq "a redirecting APP_URL is never wrong: it reads unknown, with the HTTP code" \
      "no extra failure · HTTP 301" \
      "$( [ -n "$n_redirect" ] && [ "$n_redirect" = "$n_tcp" ] && echo 'no extra failure' || echo "$n_tcp -> $n_redirect" ) · $( grep -qF 'HTTP 301' <<< "$out_page_redirect" && echo 'HTTP 301' || echo silent )"
    assert_eq "an error page without APP_EXPECT reads unknown, never wrong" \
      "no extra failure · HTTP 404" \
      "$( [ -n "$n_404" ] && [ "$n_404" = "$n_tcp" ] && echo 'no extra failure' || echo "$n_tcp -> $n_404" ) · $( grep -qF 'HTTP 404' <<< "$out_page_404" && echo 'HTTP 404' || echo silent )"
    assert_eq "without curl, APP_EXPECT reads unknown and never refuses" \
      "no extra failure · not checked" \
      "$( [ -n "$n_nocurl" ] && [ "$n_nocurl" = "$n_tcp" ] && echo 'no extra failure' || echo "$n_tcp -> $n_nocurl" ) · $( grep -qF 'not checked' <<< "$out_page_nocurl" && echo 'not checked' || echo silent )"
  fi

  mv .sdd/config.sh.bak .sdd/config.sh
fi

# --- install seeds the tree the runner cannot work without ------------------
# `sdd install` made `.sdd/` and `.claude/agents/` and stopped. `resolve_mission` dies on the FIRST
# command a new user types — "docs/handoffs/ does not exist in the target repo" — and `TODO_FILE`,
# where principle 5 sends every out-of-scope finding, is not there either. Both are named in the
# config the installer just wrote, so the installer is where they belong.
#
# Read the way check 2b of `sdd health` reads TEST_CMD: the config is SOURCED in a subshell, so the
# value seeded is the one `load_config` will hand the runner after expansion, not a grep of the
# text.
echo "== install seeds HANDOFF_DIR and the findings file =="
SEED="$FIX/seed"
mkdir -p "$SEED"
( cd "$SEED" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && echo content > file.txt && git add -A && git commit -qm "init" ) >/dev/null 2>&1
seed_out="$( cd "$SEED" && "$SDD" install 2>&1 )"

assert_has "install seeds HANDOFF_DIR and the findings file" "docs/handoffs/" "$seed_out"
if [ -d "$SEED/docs/handoffs" ]; then pass "the handoff root exists on disk after install"
else fail "the handoff root exists on disk after install" "a docs/handoffs/ directory" "absent"; fi
if [ -s "$SEED/TODO.md" ]; then pass "the findings file is seeded, and not empty"
else fail "the findings file is seeded, and not empty" "a non-empty TODO.md" \
       "$(wc -c < "$SEED/TODO.md" 2>/dev/null || echo 'no file') byte(s)"; fi

# The seed is the kit's template in the repo's OUTPUT_LANG, and it passes the shape sensor the
# repo will be measured by. The starter config declares no language, so this fixture gets English.
if cmp -s "$SEED/TODO.md" "$ROOT/templates/todo.md"; then
  pass "with OUTPUT_LANG empty the seed is templates/todo.md, byte for byte"
else fail "with OUTPUT_LANG empty the seed is templates/todo.md, byte for byte" \
       "a copy of templates/todo.md" "$(head -c 120 "$SEED/TODO.md" 2>/dev/null)"; fi
seed_check="$(bash "$ROOT/tests/check-todo.sh" --check "$SEED/TODO.md" --allow-empty 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && grep -q '^  ok    0 finding(s)' <<< "$seed_check"; then
  pass "the seed passes the shape sensor with zero findings"
else fail "the seed passes the shape sensor with zero findings" "rc 0 and 'ok    0 finding(s)'" \
       "rc $rc: $seed_check"; fi

# Which variant: templates/todo.<OUTPUT_LANG>.md when the kit has one, the English one otherwise.
# Each case removes the file first, because an existing TODO.md is never overwritten.
seed_lang() { # seed_lang <lang> — reinstall with OUTPUT_LANG=<lang> over no TODO.md
  sed -i "s/^OUTPUT_LANG=.*/OUTPUT_LANG=\"$1\"/" "$SEED/.sdd/config.sh"
  rm -f "$SEED/TODO.md"
  ( cd "$SEED" && "$SDD" install >/dev/null 2>&1 )
}
seed_lang pt-BR
if cmp -s "$SEED/TODO.md" "$ROOT/templates/todo.pt-BR.md"; then
  pass "with OUTPUT_LANG=pt-BR the seed is templates/todo.pt-BR.md"
else fail "with OUTPUT_LANG=pt-BR the seed is templates/todo.pt-BR.md" "the pt-BR variant" \
       "$(sed -n 3p "$SEED/TODO.md" 2>/dev/null)"; fi
seed_lang xx
if cmp -s "$SEED/TODO.md" "$ROOT/templates/todo.md"; then
  pass "a language the kit has no variant for falls back to templates/todo.md"
else fail "a language the kit has no variant for falls back to templates/todo.md" "the English seed" \
       "$(sed -n 3p "$SEED/TODO.md" 2>/dev/null)"; fi

# The legacy seed — written by this command before the two-section skeleton — held no finding, so
# an install over an untouched copy replaces it; one byte of difference makes it somebody's work,
# preserved, with a warning that names the migration.
cp "$ROOT/tests/fixtures/todo-seed-legacy-en.md" "$SEED/TODO.md"
legacy_out="$( cd "$SEED" && "$SDD" install 2>&1 )"
if cmp -s "$SEED/TODO.md" "$ROOT/templates/todo.md"; then
  pass "an untouched legacy seed is replaced by the current one"
else fail "an untouched legacy seed is replaced by the current one" "templates/todo.md" \
       "$(sed -n 1p "$SEED/TODO.md" 2>/dev/null)"; fi
assert_has "the replacement of the legacy seed is announced" "untouched legacy seed" "$legacy_out"
{ cat "$ROOT/tests/fixtures/todo-seed-legacy-en.md"; printf -- '- [ ] one real finding\n'; } > "$SEED/TODO.md"
before_legacy="$(md5sum < "$SEED/TODO.md")"
legacy_out="$( cd "$SEED" && "$SDD" install 2>&1 )"
if [ "$before_legacy" = "$(md5sum < "$SEED/TODO.md")" ]; then
  pass "a legacy seed holding a finding is preserved"
else fail "a legacy seed holding a finding is preserved" "the same TODO.md" "rewritten"; fi
assert_has "a pre-skeleton TODO.md is named for migration" "predates the two-section skeleton" "$legacy_out"
sed -i 's/^OUTPUT_LANG=.*/OUTPUT_LANG=""/' "$SEED/.sdd/config.sh"
cp "$ROOT/templates/todo.md" "$SEED/TODO.md"

# A second install must not overwrite what the repo already has — the installer is idempotent
# everywhere else, and a TODO.md flattened on the second run would take real findings with it.
printf -- '- [ ] a real finding — `x:1` — it matters — found by `x` in mission `m` (2026-01-01)\n' \
  >> "$SEED/TODO.md"
before_todo="$(md5sum < "$SEED/TODO.md")"
( cd "$SEED" && "$SDD" install >/dev/null 2>&1 )
if [ "$before_todo" = "$(md5sum < "$SEED/TODO.md")" ]; then
  pass "a second install leaves an existing findings file untouched"
else
  fail "a second install leaves an existing findings file untouched" "the same TODO.md" "rewritten"
fi

# --- the autodetect cascade: first match wins -------------------------------
# Four `if`s with no `elif`: every one of them ran, so the LAST match won whatever the repo is. A
# Node repo carrying a `go.mod` for a sidecar tool was installed with `go test ./...` as the suite
# the gates run — the wrong suite, chosen in silence, in the one key the whole pipeline trusts.
echo "== the autodetect cascade =="
MULTI="$FIX/multi"
mkdir -p "$MULTI"
( cd "$MULTI" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && printf '{}\n' > package.json && printf 'module x\n' > go.mod \
  && git add -A && git commit -qm "init" ) >/dev/null 2>&1
( cd "$MULTI" && "$SDD" install >/dev/null 2>&1 )
multi_test_cmd="$( . "$MULTI/.sdd/config.sh" >/dev/null 2>&1; printf '%s' "${TEST_CMD:-}" )" || true
if [ "$multi_test_cmd" = "npm test" ]; then
  pass "with two manifests the first match wins (package.json → npm test)"
else
  fail "with two manifests the first match wins (package.json → npm test)" \
       "npm test" "$multi_test_cmd"
fi

# --- install never writes through a linked agent ----------------------------
# `.claude/agents/<hat>.md` can be a symlink — `sdd-link-agents` makes exactly that, by the human's
# explicit choice. `install --force` then ran `cp` over the LINK, which follows it: the link stayed
# a link and the file at the other end was overwritten with this kit's bytes (measured, #173). A
# DANGLING link fell into the `[ ! -f ]` arm instead, and `cp` created the file where it pointed.
# Both worlds are built in a repo of their own, so nothing later in this file reads them.
echo "== install never writes through a linked agent =="
LINKED="$FIX/linked"
mkdir -p "$LINKED"
( cd "$LINKED" && git init -q -b main \
  && git config user.email "fixture@example.com" && git config user.name "Fixture" \
  && echo content > file.txt && git add -A && git commit -qm "init" ) >/dev/null 2>&1
( cd "$LINKED" && "$SDD" install >/dev/null 2>&1 )
ELSEWHERE="$FIX/elsewhere-sdd-qa.md"
printf 'bytes that belong to somebody else\n' > "$ELSEWHERE"
rm -f "$LINKED/.claude/agents/sdd-qa.md"
ln -s "$ELSEWHERE" "$LINKED/.claude/agents/sdd-qa.md"
before_link="$(md5sum < "$ELSEWHERE")"
link_out="$( cd "$LINKED" && "$SDD" install --force 2>&1 )"
if [ -L "$LINKED/.claude/agents/sdd-qa.md" ] && [ "$before_link" = "$(md5sum < "$ELSEWHERE")" ] \
   && grep -q 'sdd-qa.md.*link' <<< "$link_out"; then
  pass "install --force never writes through a linked agent"
else
  fail "install --force never writes through a linked agent" \
       "the link kept, its target's md5 unchanged and a warning naming the link" \
       "link: $([ -L "$LINKED/.claude/agents/sdd-qa.md" ] && echo kept || echo replaced); md5 $(md5sum < "$ELSEWHERE"); out: $(grep 'sdd-qa' <<< "$link_out" || true)"
fi

DANGLING="$FIX/nowhere/sdd-qa.md"
rm -f "$LINKED/.claude/agents/sdd-qa.md"
mkdir -p "$FIX/nowhere"
ln -s "$DANGLING" "$LINKED/.claude/agents/sdd-qa.md"
# GNU cp 9.4 refuses to write through a dangling link ("not writing through dangling symlink") and
# the install died there under `set -e`, rc 1, with every later step unrun; a cp under
# POSIXLY_CORRECT creates the file instead. Both are wrong, so the probe demands all three: no
# file at the other end, rc 0, and the same warning that names the link.
rc=0; dangling_out="$( cd "$LINKED" && "$SDD" install 2>&1 )" || rc=$?
if [ ! -e "$DANGLING" ] && [ -L "$LINKED/.claude/agents/sdd-qa.md" ] && [ "$rc" -eq 0 ] \
   && grep -q 'sdd-qa.md.*link' <<< "$dangling_out"; then
  pass "install never creates a file through a dangling link"
else
  fail "install never creates a file through a dangling link" \
       "no file at $DANGLING, the link kept, rc 0 and a warning naming the link" \
       "rc $rc; $(ls -l "$DANGLING" 2>&1 || true); out: $(grep 'sdd-qa' <<< "$dangling_out" || true)"
fi

# --- the bug template is seeded with `Closable by:` -------------------------
# Anchor 3 of gate_QA reads that field and an ABSENT genre BLOCKS — fail-safe, because every bug
# written before the field existed lacks it. But nothing on disk ever puts the field there:
# `grep -rn Closable ~/.claude/skills/qa-*` answers 0, and the pilot target's own
# docs/qa/templates/bug.md has no such line either. So in a fresh target every bug the skills write
# is born blocking, and somebody pays a QA lap before anyone works out why. The field has to exist
# BEFORE the first bug, which makes it the installer's job.
echo "== the qa bug template gains Closable by: =="
BT="$FIX/bugtpl"
mkdir -p "$BT/docs/qa/templates"
( cd "$BT" && git init -q -b main && git config user.email "fixture@example.com"   && git config user.name "Fixture" && printf '{}\n' > package.json ) >/dev/null 2>&1
# PROVENANCE: ~/.claude/skills/qa-report/assets/bug-template.md:1-4, verbatim. Copied and not
# written from memory — three gate bugs of this kit were born of an imagined fixture, where the
# gate and the fixture shared an author and a wrong assumption, so green CONFIRMED the assumption
# instead of measuring it.
bt_template() {
  cat > "$BT/docs/qa/templates/bug.md" <<'BTEOF'
# BUG-<YYYYMMDD>-<slug>: <one-line title, user-first>

- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->
- **Impact (user-side):** <Blocks-Completion | Data-Loss | Trust-Damage | Friction | Cosmetic>
BTEOF
}
bt_template
( cd "$BT" && git add -A && git commit -qm "init" ) >/dev/null 2>&1
( cd "$BT" && "$SDD" install >/dev/null 2>&1 )
bt_template   # the install above wrote .sdd/; the template is put back to the skill's own shape

# 1. WITHOUT the field: preflight refuses, and `install` alone only SHOWS it — diff-first, the way
#    the agent mirrors already behave. `md5:same` is the half that matters: an installer that
#    edited the file without being asked would satisfy "it warned" and still have edited.
bt_md5_before="$(md5sum < "$BT/docs/qa/templates/bug.md")"
bt_pf_missing="$( cd "$BT" && "$SDD" preflight 2>&1 )"
bt_inst_soft="$( cd "$BT" && "$SDD" install 2>&1 )"
assert_eq "a template without Closable by: fails preflight, and a bare install only shows it" \
  "pf-fail:1 pf-remedy:1 shown:1 md5:same" \
  "pf-fail:$( grep -cE '^ *fail +qa bug template' <<< "$bt_pf_missing" ) pf-remedy:$( grep -c "sdd install --force" <<< "$bt_pf_missing" ) shown:$( grep -cF -- '- **Closable by:** agent <!-- agent | human | deferred -->' <<< "$bt_inst_soft" ) md5:$( [ "$bt_md5_before" = "$(md5sum < "$BT/docs/qa/templates/bug.md")" ] && echo same || echo edited )"

# 2. WITH --force: the line lands immediately BELOW `Status:` — line 4, because the skill's own
#    file opens with the title, a blank line and Status. Position is not cosmetic: gate_QA reads
#    the FIRST field-shaped line outside a fence, so a seed dropped at the end of the file would
#    still work today and stop working the day the template grows a fenced example above it.
( cd "$BT" && "$SDD" install --force >/dev/null 2>&1 )
bt_line4="$(sed -n '4p' "$BT/docs/qa/templates/bug.md")"
bt_pf_seeded="$( cd "$BT" && "$SDD" preflight 2>&1 )"
assert_eq "install --force seeds Closable by: below Status:, and preflight goes quiet" \
  "line4:1 legend:1 pf-fail:0" \
  "line4:$( grep -c '^- \*\*Closable by:\*\* agent' <<< "$bt_line4" ) legend:$( grep -c 'agent | human | deferred' <<< "$bt_line4" ) pf-fail:$( grep -cE '^ *fail +qa bug template' <<< "$bt_pf_seeded" )"

# 3. IDEMPOTENT. A second --force must not stack a second line: `sdd install --force` is run after
#    every change to an agent file, so a seeder that appended each time would grow the template one
#    line per kit update and the SECOND field-shaped line would be nobody's genre.
bt_md5_seeded="$(md5sum < "$BT/docs/qa/templates/bug.md")"
( cd "$BT" && "$SDD" install --force >/dev/null 2>&1 )
assert_eq "a second install --force is a no-op on the template" \
  "md5:same count:1" \
  "md5:$( [ "$bt_md5_seeded" = "$(md5sum < "$BT/docs/qa/templates/bug.md")" ] && echo same || echo changed ) count:$( grep -c '^- \*\*Closable by:\*\*' "$BT/docs/qa/templates/bug.md" )"

# 4. NO ANCHOR, NO WRITE. A template that is not the skill's shape is somebody else's file, and
#    guessing where the field goes in it is how an installer corrupts a document it does not
#    understand. It says so and leaves the bytes alone — the `md5:same` here is the assertion.
printf 'a template of our own, with no Status line\n' > "$BT/docs/qa/templates/bug.md"
bt_md5_odd="$(md5sum < "$BT/docs/qa/templates/bug.md")"
bt_inst_odd="$( cd "$BT" && "$SDD" install --force 2>&1 )"
assert_eq "a template with no Status: anchor is named and left untouched" \
  "warned:1 md5:same" \
  "warned:$( grep -c 'Status:' <<< "$bt_inst_odd" ) md5:$( [ "$bt_md5_odd" = "$(md5sum < "$BT/docs/qa/templates/bug.md")" ] && echo same || echo edited )"

# 5. NO TREE, NO COMPLAINT. A repo with no docs/qa/ yet has nothing to seed and nothing to fail
#    on — the skills create that tree on their first run. Without this the kit's OWN preflight
#    would go red, which is the check reporting the absence of a feature as a defect.
rm -rf "$BT/docs/qa"
bt_pf_notree="$( cd "$BT" && "$SDD" preflight 2>&1 )"
assert_eq "a repo with no QA docs tree is neither failed nor seeded" \
  "fail:0 said:1" \
  "fail:$( grep -cE '^ *fail +qa bug template' <<< "$bt_pf_notree" ) said:$( grep -c 'qa bug template not found' <<< "$bt_pf_notree" )"

# 6. The repo that does NOT keep its QA tree at docs/qa. `cmd_install` never calls `load_config`,
#    so the `${QA_DOCS_PATH:-docs/qa}` it used to build the template path read an UNSET variable
#    and answered `docs/qa` whatever the repo had declared — while `cmd_preflight`, which does
#    call `load_config`, checked the configured path. The two commands talked about different
#    files, and because preflight NAMES `sdd install --force` as its remedy, the pair closed into
#    a loop: fail, run the remedy, remedy reports ok, nothing changes, fail again.
#
#    FOUR terms, and the last two are what make it a measurement rather than a restatement. That
#    the configured template gained the field is the fix; that `docs/qa` was NOT created is the
#    defect's own signature (the old code would have looked there and, finding nothing, said so);
#    and that preflight goes quiet afterwards is the loop actually closing — asserting only the
#    first term would be satisfied by an installer that seeded both paths.
rm -rf "$BT/docs" "$BT/quality"
mkdir -p "$BT/quality/qa/templates"
sed -i 's|^QA_DOCS_PATH=.*|QA_DOCS_PATH="quality/qa"|' "$BT/.sdd/config.sh"
grep -q '^QA_DOCS_PATH=' "$BT/.sdd/config.sh" || printf 'QA_DOCS_PATH="quality/qa"\n' >> "$BT/.sdd/config.sh"
{ printf '# BUG-<YYYYMMDD>-<slug>: <one-line title, user-first>\n\n'
  printf -- '- **Status:** open <!-- open | fixed | verified | wont-fix | invalid -->\n'
} > "$BT/quality/qa/templates/bug.md"
bt_pf_alt_before="$( cd "$BT" && "$SDD" preflight 2>&1 )"
bt_inst_alt="$(     cd "$BT" && "$SDD" install --force 2>&1 )"
bt_pf_alt_after="$( cd "$BT" && "$SDD" preflight 2>&1 )"
assert_eq "install --force seeds the CONFIGURED qa tree, not the default one, and the loop closes" \
  "before-fail:1 said:1 seeded:1 no-default-tree:1 after-fail:0" \
  "before-fail:$( grep -cE '^ *fail +qa bug template' <<< "$bt_pf_alt_before" ) said:$( grep -cE '^ *ok +qa bug template.*inserted' <<< "$bt_inst_alt" ) seeded:$( grep -c '^- \*\*Closable by:\*\* agent' "$BT/quality/qa/templates/bug.md" ) no-default-tree:$( [ -e "$BT/docs/qa" ] && echo 0 || echo 1 ) after-fail:$( grep -cE '^ *fail +qa bug template' <<< "$bt_pf_alt_after" )"
# ...and the remedy preflight NAMES is the one that was just run. The loop above is only a loop
# because the two sentences point at each other; without this term the pair could drift apart
# again and each half would still pass.
assert_eq "and the remedy preflight names is the command that closed it" "1" \
  "$( grep -c "sdd install --force" <<< "$bt_pf_alt_before" )"

# --- a Node TEST_CMD carries lint, typecheck and build ----------------------
# The starter says it in the line beside the key: lint and build go INSIDE TEST_CMD, because the
# runner reads no other sensor. `sdd install` then wrote `npm test` for every package.json, whatever
# scripts the repo declared — the installer breaking the rule it prints. Measured on 2026-09-24
# across the Node repos carrying the kit: four of six had `lint`, `build` or `typecheck` outside the
# gate, so a mission there passes EXEC and REVIEW with the lint or the build red (a Codex review of
# warehouse_explorer_api PR #7 is what surfaced it). Two halves: install composes the command from
# the scripts that exist, and preflight warns about a config written before that, or by hand.
echo "== a Node TEST_CMD carries lint, typecheck and build =="
node_target() { # node_target <dir> <scripts-json> — a fresh repo with that package.json
  mkdir -p "$1"
  ( cd "$1" && git init -q -b main && git config user.email "fixture@example.com" \
    && git config user.name "Fixture" && printf '{"name":"f","scripts":%s}\n' "$2" > package.json \
    && git add -A && git commit -qm init ) >/dev/null 2>&1
}
node_target "$FIX/node-full" '{"lint":"true","typecheck":"true","build":"true","test":"true"}'
( cd "$FIX/node-full" && "$SDD" install >/dev/null 2>&1 )
assert_eq "install chains every gate script into TEST_CMD, cheapest first" \
  'TEST_CMD="npm run lint && npm run typecheck && npm run build && npm test"' \
  "$(grep -oE '^TEST_CMD="[^"]*"' "$FIX/node-full/.sdd/config.sh" 2>/dev/null || echo 'no TEST_CMD line')"
# The positive control: a repo that declares only `test` keeps the old value. Without it an
# installer that chained scripts the repo does not have would pass the case above.
node_target "$FIX/node-bare" '{"test":"true"}'
( cd "$FIX/node-bare" && "$SDD" install >/dev/null 2>&1 )
assert_eq "install keeps a bare npm test when the repo declares no gate script" \
  'TEST_CMD="npm test"' \
  "$(grep -oE '^TEST_CMD="[^"]*"' "$FIX/node-bare/.sdd/config.sh" 2>/dev/null || echo 'no TEST_CMD line')"

nw_case() { # nw_case <TEST_CMD> <expected: warn|quiet> <description>
  # Escaped for sed: `&` in a replacement is the matched text, and every value here carries `&&`.
  local v; v="$(printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g')"
  sed -i "s|^TEST_CMD=.*|TEST_CMD=\"$v\"|" "$FIX/node-full/.sdd/config.sh"
  local o got; o="$( cd "$FIX/node-full" && "$SDD" preflight 2>&1 )"
  if grep -qF "leaves out package.json script" <<< "$o"; then got="warn: $(grep -oE 'script\(s\): [a-z ]+' <<< "$o" | head -1)"
  else got="quiet"; fi
  assert_eq "$3" "$2" "$got"
}
nw_case 'npm test' 'warn: script(s): lint typecheck build ' \
  "preflight names every gate script a hand-written TEST_CMD leaves out"
nw_case 'npm run lint && npm test' 'warn: script(s): typecheck build ' \
  "preflight names only the scripts that are missing"
nw_case 'npm run lint && npm run typecheck && npm run build && npm test' 'quiet' \
  "preflight stays quiet when every gate script is inside TEST_CMD"
nw_case 'npm run build:prod && npm run lint && npm run typecheck && npm test' 'warn: script(s): build ' \
  "a longer script name that merely starts with build does not count as build"

# --- a greenfield mission: the runner is there, its manifest is not yet (issue 53) ----------
# A mission whose I1 creates the package.json runs preflight BEFORE the manifest exists, and
# `npm test` dies with ENOENT (rc 254). The old verdict — "a red suite makes the EXEC phase
# unsatisfiable" — was false about that repo: the scaffold is exactly what EXEC is about to write.
# The warn is NARROW, and the three probes are its edges: no manifest -> warn; manifest present and
# suite red -> still the fail; a runner the table does not know -> still the fail (run_case above).
echo "== greenfield: TEST_CMD's runner without its manifest =="
# The excuse needs the runner to SAY the manifest is missing, so this probe needs npm's own words —
# and a real npm is not something the suite may assume: without one the shell answers "command not
# found", the evidence never matches, and the probe went red on a machine with no Node for a reason
# that has nothing to do with issue 53. The stub prints what npm prints. Provenance: `npm test` in an
# empty directory, npm 12.0.2, 2026-09-25 — copied, not written from memory (the CLAUDE.md rule).
mkdir -p "$FIX/.npmstub"
cat > "$FIX/.npmstub/npm" <<'STUB'
#!/usr/bin/env bash
cat >&2 <<EOF
npm error code ENOENT
npm error syscall open
npm error path $PWD/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '$PWD/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
EOF
exit 254
STUB
chmod +x "$FIX/.npmstub/npm"
node_target "$FIX/greenfield" '{}'
rm -f "$FIX/greenfield/package.json"
( cd "$FIX/greenfield" && "$SDD" install >/dev/null 2>&1 )
sed -i 's|^TEST_CMD=.*|TEST_CMD="npm test"|' "$FIX/greenfield/.sdd/config.sh"
out="$( cd "$FIX/greenfield" && PATH="$FIX/.npmstub:$PATH" "$SDD" preflight 2>&1 )"
assert_eq "a runner without its manifest at the root is a warn, not a fail" \
  "warn, no FAILED" \
  "$(grep -qF 'expected if I1 creates the scaffold' <<< "$out" && printf 'warn' || printf 'no warn'), $(grep -qF 'TEST_CMD FAILED' <<< "$out" && printf 'FAILED' || printf 'no FAILED')"
node_target "$FIX/node-red" '{"test":"exit 3"}'
( cd "$FIX/node-red" && "$SDD" install >/dev/null 2>&1 )
sed -i 's|^TEST_CMD=.*|TEST_CMD="npm test"|' "$FIX/node-red/.sdd/config.sh"
out="$( cd "$FIX/node-red" && "$SDD" preflight 2>&1 )"
assert_eq "a red suite with its manifest present still fails" \
  "FAILED, no warn" \
  "$(grep -qF 'TEST_CMD FAILED' <<< "$out" && printf 'FAILED' || printf 'no FAILED'), $(grep -qF 'expected if I1 creates the scaffold' <<< "$out" && printf 'warn' || printf 'no warn')"

# The excuse is only for the runner that SAYS its manifest is missing. Two worlds the table alone
# used to excuse: pytest needs no manifest at all, so a red suite in a setup.py repo read as
# "scaffold not there yet"; and `npm --prefix sub test` keeps its manifest in a subdirectory, so
# the root check was blind to it. Both must stay a fail.
mkdir -p "$FIX/.pyfail"
printf '#!/bin/sh\necho "FAILED tests/test_x.py::test_x - assert False"\nexit 1\n' > "$FIX/.pyfail/pytest"
chmod +x "$FIX/.pyfail/pytest"
node_target "$FIX/py-red" '{}'
rm -f "$FIX/py-red/package.json"
( cd "$FIX/py-red" && "$SDD" install >/dev/null 2>&1 )
sed -i 's|^TEST_CMD=.*|TEST_CMD="pytest"|' "$FIX/py-red/.sdd/config.sh"
out="$( cd "$FIX/py-red" && PATH="$FIX/.pyfail:$PATH" "$SDD" preflight 2>&1 )"
node_target "$FIX/prefix-red" '{}'
rm -f "$FIX/prefix-red/package.json"
mkdir -p "$FIX/prefix-red/sub" && printf '{"name":"s","scripts":{"test":"exit 3"}}\n' > "$FIX/prefix-red/sub/package.json"
( cd "$FIX/prefix-red" && "$SDD" install >/dev/null 2>&1 )
sed -i 's|^TEST_CMD=.*|TEST_CMD="npm --prefix sub test"|' "$FIX/prefix-red/.sdd/config.sh"
out2="$( cd "$FIX/prefix-red" && "$SDD" preflight 2>&1 )"
# And the root check earns its place with a manifest the runner names while it IS there: a malformed
# package.json makes npm cite it (EJSONPARSE), and without the root check that read as "missing".
node_target "$FIX/bad-json" '{}'
printf '{"name": \n' > "$FIX/bad-json/package.json"
inst3="$( cd "$FIX/bad-json" && "$SDD" install 2>&1 )"
sed -i 's|^TEST_CMD=.*|TEST_CMD="npm test"|' "$FIX/bad-json/.sdd/config.sh"
out3="$( cd "$FIX/bad-json" && "$SDD" preflight 2>&1 )"
assert_eq "a manifest the runner cites while it exists (malformed) is still a fail" "FAILED" \
  "$(grep -qF 'TEST_CMD FAILED' <<< "$out3" && printf 'FAILED' || printf 'excused')"
# The same malformed manifest, read by the kit: node_gate_scripts answers "no gate script" both for
# a repo that declares none and for one it could not read, and the second used to be silence —
# install wrote a bare `npm test`, preflight never warned. Both now SAY they could not read it, and
# the control (node-bare, a manifest that parses) says nothing of the kind.
unread_says="could not read package.json's scripts (package.json does not parse as JSON)"
out4="$( cd "$FIX/node-bare" && "$SDD" preflight 2>&1 )"
assert_eq "install and preflight say they could not read package.json's scripts" \
  "install: said / preflight: said / parsed manifest: quiet" \
  "install: $(grep -qF "$unread_says" <<< "$inst3" && printf said || printf silent) / preflight: $(grep -qF "$unread_says" <<< "$out3" && printf said || printf silent) / parsed manifest: $(grep -qF 'could not read package.json' <<< "$out4" && printf said || printf quiet)"

# The other half of node_manifest_unread: jq itself absent. A PATH prefix cannot HIDE a binary,
# so the probe builds a shadow PATH — a link to every executable the real one reaches, minus jq —
# and runs install there. A package.json that parses must still be reported as unread, and for
# the right reason: with the jq check gone, `jq empty` fails as "command not found" and the
# message would blame the JSON instead.
nojq="$FIX/.nojq-bin"; mkdir -p "$nojq"
IFS=: read -r -a path_dirs <<< "$PATH"
for d in "${path_dirs[@]}"; do
  [ -d "$d" ] || continue
  for f in "$d"/*; do
    n="${f##*/}"
    [ "$n" = jq ] && continue
    [ -x "$f" ] && [ ! -e "$nojq/$n" ] && ln -s "$f" "$nojq/$n"
  done
done
node_target "$FIX/no-jq" '{"lint":"true","test":"true"}'
inst5="$( cd "$FIX/no-jq" && PATH="$nojq" "$SDD" install 2>&1 )"
assert_eq "install without jq says so, and does not blame the JSON" \
  "jq: said / json: not blamed / TEST_CMD: bare" \
  "jq: $(grep -qF "could not read package.json's scripts (jq is not installed)" <<< "$inst5" && printf said || printf silent) / json: $(grep -qF 'does not parse as JSON' <<< "$inst5" && printf blamed || printf 'not blamed') / TEST_CMD: $([ "$(grep -oE '^TEST_CMD="[^"]*"' "$FIX/no-jq/.sdd/config.sh" 2>/dev/null)" = 'TEST_CMD="npm test"' ] && printf bare || printf other)"

# --- every value install substitutes is escaped for sed, not only TEST_CMD -------------------
# `&` in a sed replacement is "the matched text": a branch named `feat/a&b` came out of the starter
# as `feat/a<DEFAULT_BRANCH>b`. The same corruption the composed TEST_CMD had, through another key.
echo "== install escapes the branch name for sed =="
mkdir -p "$FIX/amp-branch"
( cd "$FIX/amp-branch" && git init -q -b 'feat/a&b' && git config user.email "fixture@example.com" \
  && git config user.name "Fixture" && git commit -q --allow-empty -m init ) >/dev/null 2>&1
( cd "$FIX/amp-branch" && "$SDD" install >/dev/null 2>&1 )
assert_eq "a branch name carrying & reaches DEFAULT_BRANCH verbatim" \
  'DEFAULT_BRANCH="feat/a&b"' \
  "$(grep -oE '^DEFAULT_BRANCH="[^"]*"' "$FIX/amp-branch/.sdd/config.sh" 2>/dev/null || echo 'no DEFAULT_BRANCH line')"
assert_eq "a red suite whose runner never said its manifest is missing still fails" \
  "pytest: FAILED / prefix: FAILED" \
  "pytest: $(grep -qF 'TEST_CMD FAILED' <<< "$out" && printf 'FAILED' || printf 'excused') / prefix: $(grep -qF 'TEST_CMD FAILED' <<< "$out2" && printf 'FAILED' || printf 'excused')"

# --- sdd install over a config that does not parse (issue 116) -------------
# install reads four keys of an existing .sdd/config.sh, and used to source it with
# `>/dev/null 2>&1` — so an unclosed quote quietly bought the defaults, and the handoff dir the
# repo declared was never created. The defaults are still the right fallback; the silence is not.
echo "== sdd install over a config that does not parse =="
mkdir -p "$FIX/unparse/.sdd"
( cd "$FIX/unparse" && git init -q -b main ) || exit 1
printf 'HANDOFF_DIR="notes/handoffs\n' > "$FIX/unparse/.sdd/config.sh"
out="$( cd "$FIX/unparse" && "$SDD" install 2>&1 )"
assert_has "install says the config does not parse instead of using defaults in silence" \
  "does not parse" "$out"

# The same silence one step later. `bash -n` accepts `"$UNSET/x"`, and load_config's `set -u` dies
# on it; config_read_key let the final printf eat the source's failure, the unset variable came
# back as rc 1 — "no such file" — and install bought the defaults saying nothing (PR #167 review).
echo "== sdd install over a config that parses but does not evaluate =="
mkdir -p "$FIX/uneval/.sdd"
( cd "$FIX/uneval" && git init -q -b main ) || exit 1
# shellcheck disable=SC2016  # the $ is for the config file, never for this shell
printf 'HANDOFF_DIR="$SDD_PROBE_NEVER_SET/handoffs"\n' > "$FIX/uneval/.sdd/config.sh"
out="$( cd "$FIX/uneval" && env -u SDD_PROBE_NEVER_SET "$SDD" install 2>&1 )"
assert_has "install says a config that does not evaluate does not load, instead of using defaults in silence" \
  "parses but does not evaluate" "$out"

# ---------------------------------------------------------------------------
echo
if [ "$fails" -eq 0 ]; then printf '  ok    preflight measures the GNU userland instead of assuming it\n'; exit 0; fi
printf '%d preflight check(s) failed\n' "$fails" >&2
exit 1
