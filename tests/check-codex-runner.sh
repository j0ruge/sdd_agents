#!/usr/bin/env bash
# Sensor for the runner's harness dispatch. Stubs only the provider process and worker receipt;
# the coordination, gate, hat, journal and ledger are the same code run against a real checkout.
set -euo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-codex-runner-XXXXXX")"
trap 'rm -rf "$FIX"' EXIT
KIT="$FIX/kit" REPO="$FIX/repo" MISSION="20260101-codex-fixture"
export SDD_STATE_DIR="$FIX/state" SDD_PHASE_PROGRESS=off
export FIX
unset PHASE_ENGINE CODEX_PHASE_MODEL
mkdir -p "$KIT/bin" "$REPO" "$FIX/path"
cp "$ROOT/bin/sdd" "$ROOT/bin/sdd-coordination.py" "$KIT/bin/"
ln -s "$ROOT/agents" "$KIT/agents"
ln -s "$ROOT/templates" "$KIT/templates"
ln -s "$ROOT/config" "$KIT/config"
export PATH="$FIX/path:$PATH"

cat > "$FIX/path/claude" <<'STUB'
#!/usr/bin/env bash
touch "$FIX/claude.called"
if [ -f "$FIX/claude-cap-change" ]; then
  if [ -n "${SDD_DELEGATED_MISSION_CAP_USD:-}" ]; then touch "$FIX/delegated-cap-leaked"; fi
  printf '%s\n' "$BUDGET_MISSION_USD" >> "$FIX/claude-caps"
  replacement="$(cat "$FIX/claude-cap-change")"
  if [ -n "$replacement" ]; then
    : > "$FIX/claude-cap-change"
    commit="$(git rev-parse --short HEAD)"
    if [[ "$replacement" != *' inline' ]]; then
      sed -i "s/^| I1 .*$/| I1 | slice one | true → 0 | done | $commit |/" \
        docs/handoffs/20260101-codex-fixture/checkpoint.md
    fi
    sed -i "s/^BUDGET_MISSION_USD=.*/BUDGET_MISSION_USD=${replacement%% *}/" .sdd/config.sh
  fi
  printf '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0,"num_turns":1}\n'
  exit 0
fi
exit 97
STUB
cat > "$FIX/path/gh" <<'STUB'
#!/usr/bin/env bash
[ "$*" = "auth status" ]
STUB
cat > "$KIT/bin/sdd-worker" <<'STUB'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$PWD|$*" >> "$FIX/guard"
[ -f "$FIX/signed" ] || { echo "missing signed unknown-cost allowance" >&2; exit 1; }
STUB
cat > "$KIT/bin/sdd-codex" <<'STUB'
#!/usr/bin/env bash
set -eu
if [ "${1:-}" = --preflight ]; then
  touch "$FIX/adapter.preflight"
  case "$*" in *github.com*) exit 96 ;; esac
  [ ! -f "$FIX/login.missing" ]
  exit $?
fi
if [ "${1:-}" = --sandbox-check ]; then
  case "$#" in
    2) ;;
    4) [ "$3" = --qa-host ] && [ -n "$4" ] || exit 2 ;;
    *) exit 2 ;;
  esac
  printf '%s\n' "$2" >> "$FIX/sandbox-checks"
  printf '%s|%s\n' "$2" "${4:-offline}" >> "$FIX/sandbox-hosts"
  exec bash -c "$2"
fi
printf '%s\n' "$PWD|$*|${GIT_REFLOG_ACTION:-}" >> "$FIX/provider"
cat >> "$FIX/prompt"
if [ -f "$FIX/change-cap" ]; then
  printf '%s\n' "$BUDGET_MISSION_USD" >> "$FIX/provider-caps"
  replacement="$(cat "$FIX/change-cap")"
  if [ -n "$replacement" ]; then
    : > "$FIX/change-cap"
    if [[ "$replacement" == *' added'* ]]; then
      printf 'BUDGET_MISSION_USD="%s"\n' "${replacement%% *}" >> .sdd/config.sh
    else
      sed -i "s/^BUDGET_MISSION_USD=\"[0-9.]*\"/BUDGET_MISSION_USD=\"${replacement%% *}\"/" .sdd/config.sh
    fi
    if [[ "$replacement" == *' mixed' ]]; then printf '\n# Unrelated edit\n' >> .sdd/config.sh; fi
    if [[ "$replacement" == *' progress' ]]; then
      commit="$(git rev-parse --short HEAD)"
      sed -i "s/^| I1 .*$/| I1 | slice one | true → 0 | done | $commit |/" \
        docs/handoffs/20260101-codex-fixture/checkpoint.md
    fi
  fi
fi
jq -se 'last | .event == "codex_launch" and (.launch_id | type == "string")' \
  "$SDD_STATE_DIR/autonomy-log.jsonl" > /dev/null || touch "$FIX/missing-launch"
native=3a80f12a-8f18-4077-8358-558cd54c75ff
if [ -f "$FIX/hat-cross" ]; then printf 'forbidden\n' > foreign.txt; fi
if [ -f "$FIX/closed-exec-then-error" ]; then
  mission=docs/handoffs/20260101-codex-fixture
  commit="$(git rev-parse --short HEAD)"
  sed -i "s/| pending | — |/| done | $commit |/" "$mission/checkpoint.md"
  printf '# EXEC\n\n## TL;DR\n\nThe fixture completed the increment and the suite is green.\n' > "$mission/20-handoff-exec.md"
  printf '{"type":"result","provider":"codex","subtype":"error_during_execution","is_error":true,"result":"fixture provider failed after writing artifacts","total_cost_usd":null}\n'
  exit 91
fi
printf '{"type":"system","subtype":"init","provider":"codex","session_id":"%s","tool_inventory":"configured","tools":["Bash"],"mcp_servers":[]}\n' "$native"
printf '{"type":"result","provider":"codex","session_id":"%s","subtype":"success","is_error":false,"total_cost_usd":null,"estimated_cost_usd":0.01,"estimate_basis":{"source":"fixture"},"num_turns":1,"usage":{"input_tokens":70,"cache_read_input_tokens":20,"output_tokens":5}}\n' "$native"
STUB
chmod +x "$KIT/bin/sdd-codex" "$KIT/bin/sdd-worker" "$FIX/path/"*
SDD="$KIT/bin/sdd"
cd "$REPO"
git init -q -b develop
git config user.email fixture@example.com
git config user.name Fixture
mkdir -p .sdd ".agents/skills/codereview" "docs/handoffs/$MISSION"
printf '.sdd/logs/\n' > .gitignore
cat > .sdd/config.sh <<'CONF'
PROJECT_NAME=codex-fixture
DEFAULT_BRANCH=develop
TEST_CMD="test -f .sdd/config.sh"
JIRA_ENABLED=false
CONF
printf '%s\n' '# Fixture review instructions' > .agents/skills/codereview/SKILL.md
MDIR="$REPO/docs/handoffs/$MISSION"
cat > "$MDIR/00-missao.md" <<'MISSION'
---
missao: 20260101-codex-fixture
campaign: fixture-campaign
branch: develop
aprovacao: auto
---
# Mission
MISSION
: > "$MDIR/01-plano.md"
cat > "$MDIR/checkpoint.md" <<'CHECKPOINT'
| ID | Incremento | Check (comando → esperado) | Status | Commit |
|---|---|---|---|---|
| I1 | slice one | `true` → 0 | pending | — |
CHECKPOINT
git add . && git commit -qm 'Create pending mission fixture'

assert() {
  local label="$1"; shift
  if "$@"; then printf '  ok    %s\n' "$label"
  else printf '  FAIL  %s\n' "$label" >&2; [ ! -f "$FIX/out" ] || cat "$FIX/out" >&2; exit 1; fi
}

run() { PHASE_ENGINE=codex "$SDD" run "$MISSION" "$@" > "$FIX/out" 2>&1; }
no_launch() { [ ! -e "$FIX/provider" ] && [ ! -e "$FIX/claude.called" ]; }

cp .sdd/config.sh "$FIX/config-before-ticket"
cp "$MDIR/00-missao.md" "$FIX/mission-before-ticket"
sed -i 's/JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
sed -i 's/^branch:.*/branch:\nversao: 1.0.0/' "$MDIR/00-missao.md"
PHASE_ENGINE=codex "$SDD" why "$MISSION" PLAN >"$FIX/out" 2>&1
assert 'Codex requires an explicit branch before delegated Jira ticket work' grep -Fq 'requires a real mission branch' "$FIX/out"
cp "$FIX/config-before-ticket" .sdd/config.sh
cp "$FIX/mission-before-ticket" "$MDIR/00-missao.md"

assert 'dry-run selects Codex without invoking either harness' run --phase EXEC --dry-run
assert 'Codex EXEC projects Sol medium and its role' grep -Eq 'model: gpt-6\.2-sol .*effort: medium .*agent: sdd-executor' "$FIX/out"
assert 'dry-run never opens a session' no_launch
assert 'dry-run never checks or charges the signed receipt' test ! -e "$FIX/guard"

assert 'dry-run projects REVIEW' run --phase REVIEW --dry-run
assert 'Codex REVIEW projects Sol xhigh and the review role' grep -Eq 'model: gpt-6\.2-sol .*effort: xhigh .*agent: sdd-reviewer' "$FIX/out"
assert 'review prompt resolves the Codex skill from the target worktree' grep -Fq "$REPO/.agents/skills/codereview/SKILL.md" "$FIX/out"
assert 'QA accepts a configured application URL' env PHASE_ENGINE=codex APP_URL='http://qa.example.test:8080/a@b?c=d' \
  "$SDD" run "$MISSION" --phase QA --dry-run > "$FIX/qa-out" 2>&1
assert 'QA gives the adapter only the configured app hostname' grep -Eq -- '--qa-host +qa\.example\.test' "$FIX/qa-out"
PHASE_ENGINE=codex "$SDD" boot "$MISSION" REVIEW > "$FIX/out" 2>&1
assert 'manual Codex boot uses the same review skill' grep -Fq "$REPO/.agents/skills/codereview/SKILL.md" "$FIX/out"
assert 'manual Codex boot includes the role instructions' grep -Fq 'Role instructions from the kit (sdd-reviewer)' "$FIX/out"

assert 'REVIEW accepts an EXEC model override without using it' env PHASE_ENGINE=codex CODEX_PHASE_MODEL=gpt-6.2-astra \
  "$SDD" run "$MISSION" --phase REVIEW --dry-run > "$FIX/model-out" 2>&1
assert 'REVIEW stays on Sol xhigh under an EXEC override' grep -Eq 'model: gpt-6\.2-sol .*effort: xhigh ' "$FIX/model-out"
assert 'EXEC uses its configured model override' env PHASE_ENGINE=codex CODEX_PHASE_MODEL=gpt-6.2-astra \
  "$SDD" run "$MISSION" --phase EXEC --dry-run > "$FIX/model-out" 2>&1
assert 'EXEC effort remains medium under its model override' grep -Eq 'model: gpt-6\.2-astra .*effort: medium ' "$FIX/model-out"

assert 'Codex PR projection reaches a local handoff' run --phase PR --dry-run
assert 'Codex PR projection says publication is a worker handoff' grep -Fq 'PR needs worker publish' "$FIX/out"
assert 'Codex PR dry-run spends no session or delegation' no_launch
touch "$FIX/signed"
rc=0; run --phase PR || rc=$?
assert 'even signed Codex PR delegation does not launch a publishing session' test "$rc" -eq 2
assert 'Codex PR handoff is actionable' grep -Fq 'PR needs worker publish' "$FIX/out"
assert 'Codex PR handoff cannot fall back to Claude or invoke Codex' no_launch
assert 'Codex PR handoff bought no session' test ! -e "$FIX/guard"
rm "$FIX/signed"

rc=0; run --phase EXEC || rc=$?
assert 'unsigned Codex run is refused' test "$rc" -ne 0
assert 'refusal names the signed exception' grep -q 'missing signed unknown-cost allowance' "$FIX/out"
assert 'refusal spends no session' no_launch
assert 'worker checks the actual mission directory in the working checkout' grep -Fxq "$REPO|codex-run --mission $MDIR --phase EXEC --model gpt-6.2-sol" "$FIX/guard"

touch "$FIX/signed"
rc=0; run --phase EXEC --budget-override || rc=$?
assert 'Codex refuses the standalone budget override' grep -q -- '--budget-override does not apply' "$FIX/out"
assert 'budget override spends no session' no_launch
rc=0; run --phase EXEC || rc=$?
assert 'a successful harness response without artifacts fails the actual gate' test "$rc" -eq 3
assert 'first invocation uses the target checkout, model, effort and reflog label' grep -Eq "^$REPO\\|--model gpt-6\\.2-sol --effort medium --hat sdd-executor\\|sdd:EXEC:" "$FIX/provider"
assert 'inline retry resumes the actual native thread' grep -Fq -- '--resume 3a80f12a-8f18-4077-8358-558cd54c75ff' "$FIX/provider"
assert 'runner hands the executor role to the provider' grep -Fq 'You execute **one increment**' "$FIX/prompt"
assert 'runner hands the failing gate to the retry' grep -Fq 'Fix exactly that.' "$FIX/prompt"
assert 'retry revalidates signed budget' test "$(wc -l < "$FIX/guard")" -eq 3
assert 'ledger retains native thread ID, engine, usage and unknown USD' jq -es '
  map(select(.event == "session"))
  | length == 2 and all(.[]; .engine == "codex" and .effort == "medium" and
      .session == "3a80f12a-8f18-4077-8358-558cd54c75ff" and .gate == "fail" and
      .cost_usd == null and .usage.input_tokens == 70 and .usage.output_tokens == 5 and
      .estimated_cost_usd == 0.01 and .estimate_basis.source == "fixture" and
      .mcp_seen == null and .tools_leaked == null)
' "$SDD_STATE_DIR/autonomy-log.jsonl"
assert 'the Codex launch is recorded before the provider starts' test ! -e "$FIX/missing-launch"
assert 'each finished session refers to one earlier launch' jq -es '
  (map(select(.event == "session")) | map(.launch_id) | sort) ==
  (map(select(.event == "codex_launch")) | map(.launch_id) | sort)
' "$SDD_STATE_DIR/autonomy-log.jsonl"

assert 'campaign attribution is recorded on each paid session and its launch' jq -es '
  map(select(.event == "session" or .event == "codex_launch"))
  | length == 4 and all(.[]; .campaign == "fixture-campaign")
' "$SDD_STATE_DIR/autonomy-log.jsonl"

touch "$FIX/hat-cross"
rc=0; run --phase REVIEW || rc=$?
assert 'Codex still triggers the review hat write guard' grep -Eq 'touched .*outside its writes:.*foreign.txt' "$FIX/out"
assert 'Codex hat crossing exits 3' test "$rc" -eq 3
rm "$REPO/foreign.txt"

cat > "$FIX/path/acli" <<'STUB'
#!/usr/bin/env bash
printf '[]\n'
STUB
chmod +x "$FIX/path/acli"
cat > "$MDIR/10-ticket.md" <<'TICKET'
---
issue: SDD-1
---
TICKET
rm "$FIX/hat-cross"
close() { PHASE_ENGINE=codex "$SDD" close "$MISSION" > "$FIX/out" 2>&1; }
rm "$FIX/signed"
rc=0; close || rc=$?
assert 'close with JIRA disabled spends nothing' test "$rc" -eq 0
sed -i 's/JIRA_ENABLED=false/JIRA_ENABLED=true/' .sdd/config.sh
rc=0; close || rc=$?
assert 'Codex close reports its unsupported paid phase' grep -q 'CLOSE is not a delegated Codex campaign phase' "$FIX/out"
assert 'Codex close does not fall back to Claude' test ! -e "$FIX/claude.called"
sed -i 's/JIRA_ENABLED=true/JIRA_ENABLED=false/' .sdd/config.sh
rm "$MDIR/10-ticket.md"

rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
assert 'Codex preflight exits green without Claude mirrors' test "$rc" -eq 0
assert 'Codex preflight uses the selected adapter capability probe' test -f "$FIX/adapter.preflight"
touch "$FIX/login.missing"
rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
assert 'Codex preflight cannot report readiness when the adapter refuses' test "$rc" -ne 0
rm "$FIX/login.missing"
rc=0; APP_URL=https://github.com PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
assert 'Codex preflight asks the adapter to validate its QA host' grep -q 'Codex capability or login check failed' "$FIX/out"
assert 'Codex preflight fails when the sandbox cannot open QA for this host' test "$rc" -ne 0
mv "$KIT/bin/sdd-worker" "$KIT/bin/worker.off"
rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
mv "$KIT/bin/worker.off" "$KIT/bin/sdd-worker"
assert 'Codex preflight finds a missing mandatory worker' grep -q 'Codex requires the worker' "$FIX/out"
assert 'Codex preflight fails with no worker' test "$rc" -ne 0
touch "$FIX/signed" "$FIX/closed-exec-then-error"
rc=0; PHASE_ENGINE=codex "$SDD" retry "$MISSION" > "$FIX/out" 2>&1 || rc=$?
assert 'Codex retry stops on provider failure after valid artifacts' test "$rc" -eq 3
assert 'Codex retry reports that the provider session died' grep -q 'session died.*fixture provider failed' "$FIX/out"
assert 'Codex session death takes precedence over the passing retry gate' jq -se '
  (map(select(.event == "session" and .invocation == "retry" and .gate == "pass")) | last | .run_id) as $run
  | $run != null and any(.[]; .run_id == $run and .event == "blocked" and .kind == "session-died")
' "$SDD_STATE_DIR/autonomy-log.jsonl"
rm "$FIX/closed-exec-then-error"
cat > "$MDIR/30-handoff-qa.md" <<'QA'
---
status: done
gate: The CLI journey passed with the expected output. There is no browser interface.
---
# QA

## TL;DR

The command-line journey and the configured suite passed.
QA
printf '%s\n' '# An incomplete review round' > "$MDIR/40-review-r1.md"
git add "$MDIR" && git commit -qm 'Record QA and the incomplete review round'
cp "$FIX/provider" "$FIX/provider-before-draft"
rc=0; REVIEW_MAX_ITER=1 PUBLISH_ON_REVIEW_BLOCKED=draft run || rc=$?
assert 'Codex keeps the draft publication handoff separate' test "$rc" -eq 2
assert 'Codex reports draft-only publication after review reached its ceiling' grep -Fq 'PR needs worker publish (draft only)' "$FIX/out"
assert 'Codex draft handoff opens no provider session' cmp -s "$FIX/provider" "$FIX/provider-before-draft"
assert 'Codex sends repository check commands through the no-model sandbox' grep -Fxq 'test -f .sdd/config.sh' "$FIX/sandbox-checks"
git switch -qc qa-network-fixture
mkdir -p docs/qa/reports
printf '%s\n' '# Fixture report' '- **Started:** 2026-01-01 · **Status:** closed' > docs/qa/reports/20260101-fixture.md
git add docs/qa/reports && git commit -qm 'Record the closed interface QA report'
: > "$FIX/sandbox-hosts"
APP_URL=https://qa.example.test E2E_CMD='test -f .sdd/config.sh' PHASE_ENGINE=codex \
  "$SDD" why "$MISSION" QA > "$FIX/out" 2>&1
assert 'Codex separates identical unit and E2E commands by sandbox host' \
  cmp -s "$FIX/sandbox-hosts" <(printf '%s\n' 'test -f .sdd/config.sh|offline' 'test -f .sdd/config.sh|qa.example.test')
assert 'Codex paths never invoke Claude' test ! -e "$FIX/claude.called"
assert 'Codex census labels unmeasured billing' bash -c '"$1" census "$2" | grep -F "0+unknown" >/dev/null' bash "$SDD" "$MISSION"
"$SDD" autonomy >"$FIX/autonomy"
assert 'Codex launch receipts are recognized apart from graded sessions' grep -Fq 'Codex telemetry receipt(s)' "$FIX/autonomy"
"$SDD" kaizen --series >"$FIX/series"
assert 'The judge extracts Codex receipts from the unknown event bucket' jq -e \
  '.excluded.codex_telemetry > 0 and .excluded.unrecognized == 0' "$FIX/series"

# A retry entered from another branch must use the selected mission configuration.
(
  seed="$(git rev-list --max-parents=0 HEAD)"
  git switch -qc retry-engine-source "$seed"
  sed -i 's/^branch:.*/branch: retry-engine-destination/' "$MDIR/00-missao.md"
  git add "$MDIR/00-missao.md" && git commit -qm 'Declare the retry destination'
  git switch -qc retry-engine-destination
  printf '%s\n' PHASE_ENGINE=codex CODEX_PHASE_MODEL=gpt-6.2-astra >> .sdd/config.sh
  git add .sdd/config.sh && git commit -qm 'Select Codex on the destination'
  git switch -q retry-engine-source
  rm -f "$FIX/signed" "$FIX/guard" "$FIX/provider"
  rc=0; "$SDD" retry "$MISSION" > "$FIX/out" 2>&1 || rc=$?
  assert 'retry reaches the branch declared by the mission' test "$(git branch --show-current)" = retry-engine-destination
  assert 'retry on a Codex destination requires signed consent before either provider' grep -Fq 'missing signed unknown-cost allowance' "$FIX/out"
  assert 'retry checks the destination model' grep -Fq -- '--phase EXEC --model gpt-6.2-astra' "$FIX/guard"
  assert 'retry with no consent never invokes either harness' no_launch
)

# Reports carry the measured subtotal and say which sessions had unknown billed USD.
(
  export SDD_STATE_DIR="$FIX/cost-state"
  mkdir "$SDD_STATE_DIR"
  jq -cn --arg repo "$REPO" '
    {v:1,ts:"2026-01-01T12:00:00Z",event:"session",repo:$repo,mission:"cost-mixed",
     kit_sha:"cost-fixture",kit_dirty:false,phase:"EXEC",step:"EXEC",gate:"pass",moved:true,
     invocation:"run",run_id:"r1",engine:"claude",cost_usd:2.5} as $known
    | $known, ($known + {engine:"codex",cost_usd:null,estimated_cost_usd:7}),
      ($known + {mission:"cost-all-unknown",engine:"codex",cost_usd:null})
  ' > "$SDD_STATE_DIR/autonomy-log.jsonl"
  "$SDD" autonomy --by-mission > "$FIX/out"
  assert 'mission report discloses unknown USD without adding the estimate' grep -Eq 'cost-mixed .*US[$] 2[.]50 [+] 1 session.s. at unknown cost' "$FIX/out"
  assert 'mission report does not present an entirely unpriced mission as measured zero' grep -Eq 'cost-all-unknown .*US[$] 0[.]00 [+] 1 session.s. at unknown cost' "$FIX/out"
  "$SDD" autonomy > "$FIX/out"
  assert 'version report records the same known subtotal and both unknown sessions' grep -Eq 'cost-fixture .*US[$] 2[.]50 [+] 2 session.s. at unknown cost' "$FIX/out"
  "$SDD" kaizen --series > "$FIX/out"
  assert 'series reports known USD and unknown counts at version and cell levels' jq -e '
    .latest.cost_usd == 2.5 and .latest.unknown_cost_sessions == 2
    and any(.latest.detail[]; .mission == "cost-mixed" and .cost_usd == 2.5 and .unknown_cost_sessions == 1)
    and any(.latest.detail[]; .mission == "cost-all-unknown" and .cost_usd == 0 and .unknown_cost_sessions == 1)
  ' "$FIX/out"
)

# The live worker validates the signed cap. Only the model and host checks are fixtures.
(
  export SDD_STATE_DIR="$FIX/cap-state"
  mkdir "$SDD_STATE_DIR"
  git switch -qc cap-fixture "$(git rev-list --max-parents=0 HEAD)"
  sed -i 's/^branch:.*/branch: cap-fixture/; /^campaign:/a lot: L1' "$MDIR/00-missao.md"
  printf '%s\n' '| I2 | slice two | true | pending | — |' >> "$MDIR/checkpoint.md"
  printf '%s\n' 'ON_ESCALATION_CMD=true' 'BUDGET_MISSION_USD="60"  # Fixture mission cap' >> .sdd/config.sh
  cp .sdd/config.sh "$FIX/launch-config"
  d="$REPO/docs/campaigns/fixture-campaign"
  mkdir -p "$d"
  sed -e 's/^campaign:.*/campaign: fixture-campaign/' -e 's/^harness:.*/harness: codex/' \
    -e 's/^exec_model:.*/exec_model: gpt-6.2-sol/' "$ROOT/templates/campaign.md" > "$d/campaign.md"
  sed -e 's/^campaign:.*/campaign: fixture-campaign/' -e 's/^level:.*/level: pr/' \
    -e 's/^lots:.*/lots: all/' -e 's/^expires:.*/expires: 2099-01-01 00:00/' \
    -e 's/^budget_mission_usd:.*/budget_mission_usd: 60/' \
    -e 's/^budget_campaign_usd:.*/budget_campaign_usd: 500/' \
    -e 's/^allow_unknown_cost:.*/allow_unknown_cost: true/' "$ROOT/templates/delegation.md" > "$d/delegation.md"
  rm "$KIT/bin/sdd-worker"
  ln -s "$ROOT/bin/sdd-worker" "$KIT/bin/sdd-worker"
  "$KIT/bin/sdd-worker" delegate "$d" <<< y > "$FIX/out" 2>&1
  git add .sdd/config.sh "$d" "$MDIR" && git commit -qm 'Sign the campaign fixture'
  export BUDGET_MISSION_USD=60

  for replacement in '100 added' 0 '40 mixed' '40 added' 40; do
    cp "$FIX/launch-config" .sdd/config.sh
    git show HEAD:"docs/handoffs/$MISSION/checkpoint.md" > "$MDIR/checkpoint.md"
    if [[ "$replacement" == *' added' ]]; then sed -i '/^BUDGET_MISSION_USD=/d' .sdd/config.sh; fi
    case "$replacement" in
      '100 added') printf '%s progress\n' "$replacement" ;;
      *) printf '%s\n' "$replacement" ;;
    esac > "$FIX/change-cap"
    : > "$FIX/provider-caps"
    rc=0; run || rc=$?
    assert "changed config stops the original run ($replacement)" test "$rc" -ne 0
    assert "no second session under the old invocation ($replacement)" test "$(cat "$FIX/provider-caps")" = 60
    case "$replacement" in
      '100 added'|0)
        assert "refusal names the file and both caps ($replacement)" \
          grep -Fq "$REPO/.sdd/config.sh sets BUDGET_MISSION_USD=${replacement%% *}, which sdd run applies over the signed budget_mission_usd: 60" "$FIX/out"
        rc=0; PHASE_ENGINE=codex "$SDD" retry "$MISSION" > "$FIX/out" 2>&1 || rc=$?
        assert "fresh retry revalidates signed cap ($replacement)" test "$rc" -eq 3
        assert "fresh retry launches nothing ($replacement)" test "$(cat "$FIX/provider-caps")" = 60
        ;;
      '40 mixed')
        assert 'mixed edit still requires manual review' grep -Fq 'Codex launch configuration changed' "$FIX/out"
        assert 'mixed edit offers no automatic resume' bash -c '! grep -Fq "Codex mission cap reduced" "$1"' bash "$FIX/out"
        ;;
      '40 added'|40)
        assert 'pure reduction allows only a new invocation' \
          grep -Fq "Codex mission cap reduced from 60 to 40 in $REPO/.sdd/config.sh" "$FIX/out"
        assert 'restart diagnostic pins the reduced file and phase' \
          grep -Fq "(config $(git hash-object --no-filters -- .sdd/config.sh), phase EXEC)" "$FIX/out"
        ;;
    esac
  done
  rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
  assert 'dirty reduction cannot pass preflight' test "$rc" -ne 0
  assert 'failed preflight opens no provider session' test "$(cat "$FIX/provider-caps")" = 60
  git add .sdd/config.sh && git commit -qm 'Record the reduced config in the fixture'
  "$KIT/bin/sdd-worker" allows "$d" run --mission "$MDIR" > "$FIX/out" 2>&1
  "$KIT/bin/sdd-worker" budget "$d" >> "$FIX/out" 2>&1
  rc=0; PHASE_ENGINE=codex "$SDD" preflight > "$FIX/out" 2>&1 || rc=$?
  assert 'reduced cap relaunch passes Codex preflight' test "$rc" -eq 0
  cp "$SDD_STATE_DIR/autonomy-log.jsonl" "$FIX/ledger-before-known-spend"
  printf '{"event":"session","mission":"%s","cost_usd":40}\n' "$MISSION" >> "$SDD_STATE_DIR/autonomy-log.jsonl"
  rc=0; run || rc=$?
  assert 'relaunch checks spend against the reduced cap' grep -Fq 'reached its US$ 40 cap' "$FIX/out"
  assert 'relaunch at the new cap launches nothing' test "$(cat "$FIX/provider-caps")" = 60
  cp "$FIX/ledger-before-known-spend" "$SDD_STATE_DIR/autonomy-log.jsonl"
  rc=0; run --max-phases 1 || rc=$?
  assert 'new Codex invocation opens one session at the reduced cap' test "$(cat "$FIX/provider-caps")" = $'60\n40'

  mkdir -p .claude/agents
  cp "$ROOT/agents/sdd-executor.md" .claude/agents/

  for world in 100 0 '0 inline' 40 standalone; do
    cp "$FIX/launch-config" .sdd/config.sh
    git show HEAD:"docs/handoffs/$MISSION/checkpoint.md" > "$MDIR/checkpoint.md"
    : > "$FIX/claude-caps"
    signed_cap=60; replacement="$world"
    if [ "$world" = standalone ]; then signed_cap=""; replacement=100; fi
    printf '%s\n' "$replacement" > "$FIX/claude-cap-change"
    rc=0
    SDD_DELEGATED_MISSION_CAP_USD="$signed_cap" PHASE_ENGINE=claude \
      "$SDD" run "$MISSION" --max-phases 2 > "$FIX/out" 2>&1 || rc=$?
    case "$world" in
      100|0|'0 inline')
        assert "delegated Claude rejects the reloaded cap ($world)" \
          grep -Fq "$REPO/.sdd/config.sh sets BUDGET_MISSION_USD=${world%% *} outside the signed mission cap of 60" "$FIX/out"
        assert "invalid Claude reload opens no second session ($world)" test "$(cat "$FIX/claude-caps")" = 60
        ;;
      *)
        assert "Claude preserves valid config precedence ($world)" \
          test "$(cat "$FIX/claude-caps")" = "60"$'\n'"$replacement"
        ;;
    esac
  done
  assert 'the launch constraint does not turn child runs into delegated runs' test ! -e "$FIX/delegated-cap-leaked"
  sed -i '/^BUDGET_MISSION_USD=/d' .sdd/config.sh
  rc=0; BUDGET_MISSION_USD=100 run || rc=$?
  assert 'Codex refuses a launch whose cap differs from the worker check' \
    grep -Fq 'gives 60 to the worker, but the runner would use 100' "$FIX/out"
  assert 'mismatched cap opens no further Codex session' test "$(cat "$FIX/provider-caps")" = $'60\n40'
  printf '  ok    delegated sessions respect cap changes\n'
)

python3 "$ROOT/tests/check-codex-adapter.py"
python3 "$ROOT/tests/check-codex-planner.py"
