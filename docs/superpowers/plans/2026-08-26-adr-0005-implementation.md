# ADR 0005 + the QA ceiling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the three parts of ADR 0005 (the judge reads every repo, the series publishes the
composition of the slice it read, the runner refuses the real ledger to a throwaway checkout) and
the ready-made fix from § 4 of the handoff (the phase ceiling counts sessions, not laps).

**Architecture:** All four changes are edits to `bin/sdd` plus the sensors that measure them. No
new sensor FILE is created — every assertion lands in an existing `tests/check-*.sh`, so the four
anti-vacuity floors (`run-all.sh` run line, `LINT_FLOOR`, `check-pipefail.sh` surface,
`check-lang.sh` surface) do not move. Every behaviour change gets a mutant in
`tests/check-mutation.sh`, because `sdd health` refuses a gate with no mutation and because a
green assertion nobody sabotaged is decoration.

**Tech Stack:** bash 5 (`set -euo pipefail`), jq, git, markdown. `mawk` on this box — byte-oriented
in every locale, so no negated character class with a multibyte character in it.

**Spec:** `docs/superpowers/specs/2026-08-26-adr-0005-implementacao-handoff.md` and
`docs/adr/0005-judge-reads-every-repo-with-visible-composition.md`. Read both. This plan argues
from them and does not replace them.

## Global Constraints

- **The kit surface is English.** `bin/sdd`, `agents/`, `docs/`, `README.md`, `tests/` — prose,
  comments, messages, test names. `TODO.md`, `KAIZEN_LOG.md`, `docs/handoffs/`, `templates/`,
  `config/examples/` stay pt-BR (`OUTPUT_LANG`). Sensor: `tests/check-lang.sh`.
- **`bin/sdd` runs under `set -euo pipefail`.** `x="$(cmd)"` kills the process at the assignment
  when `cmd` exits non-zero — and for `grep`/`find` "no match" IS non-zero. Use `|| true`,
  `|| rc=$?`, or `if x="$(…)"; then`.
- **Never `printf … | grep -q`.** Under `pipefail` it returns 141 when the grep FINDS. Use a
  herestring: `grep -q x <<< "$var"`. Same family: `grep -m<N>` without `-q`. Sensor:
  `tests/check-pipefail.sh` (RULE 1 and RULE 3).
- **`cd` with a relative operand inside `$( )` carries `CDPATH=''`.** Sensor:
  `tests/check-pipefail.sh` RULE 2 (`cdpath:`), which scans `bin/` and `tests/` line by line.
- **A function with a side effect on a global is CALLED, never `x="$(f)"`** — the substitution runs
  it in a subshell and the assignment dies with it.
- **No `#` comment inside a `\`-continued block.** It breaks the command silently and `bash -n`
  says nothing.
- **The last line of `bin/sdd` is `{ main "$@"; exit $?; }`** — the braces and the `exit` are
  contract. Sensor: `tests/check-entrypoint.sh`.
- **`acceptEdits` is the permission ceiling**, never `bypassPermissions`.
- **Every `agents/*.md` edit is mirrored with `./bin/sdd install --force`**, never `cp`, never a
  direct edit of `.claude/agents/`.
- **Commits:** `<tipo>(<escopo>): <o quê>` with the why in the body. Small, one per task.
- **`./bin/sdd health` reads the content of `bin/ tests/ templates/ config/`.** It runs AFTER the
  last commit that touches those four. `tests/health-baseline.txt` invalidates the stamp;
  `CLAUDE.md`, `docs/`, `KAIZEN_LOG.md` and `TODO.md` do not.
- **Baseline measured before any edit:** `tests/run-all.sh` green in ~49 s;
  `sdd kaizen --series` → `latest 06e49bc`, `excluded.other_repo: 38`;
  `sdd kaizen --series --all-repos` → same latest, `other_repo: 0`, `non_comparable: 14`.

---

## File Structure

| File | Responsibility in this plan |
|---|---|
| `bin/sdd` | `ledger_repo_is_temp()` (new), the guard inside `autonomy_append()`, `composition` inside the `group_summary` of `kaizen_series()`, `kaizen_composition_note()` (new), the all-repos default in `cmd_kaizen()`, the `ledger_flags` removal in `boot_prompt()`, the reminder's sentence, the ceiling in `cmd_run()`, `cmd_help()` |
| `tests/check-autonomy.sh` | the writer's refusal (4 regimes) and the ceiling's unit (session count + witness) |
| `tests/check-kaizen.sh` | the composition field, the printed composition block, the judge's default reading, the reworked "one series" section |
| `tests/check-mutation.sh` | 5 mutants in, 1 out, `CATALOG` kept in step |
| `docs/pipeline.md` | series schema, the `--all-repos` section, the writer guard |
| `docs/failure-modes.md` | the `other_repo` mode, the new refusal mode |
| `agents/sdd-kaizen.md` | the composition the judge must cite; the reading is no longer per repo |
| `README.md`, `docs/adr/0005-*.md`, `KAIZEN_LOG.md` | surface text, the `NOT YET` line, the measured before/after |

---

### Task 1: Part 3 — the runner refuses the real ledger to a repo under the temp directory

**Files:**
- Modify: `bin/sdd` (new function above `autonomy_append`, guard inside it)
- Modify: `tests/check-autonomy.sh` (new section near the end, before `== reader: the human-facing output ==`)
- Modify: `tests/check-mutation.sh` (one mutant + one `CATALOG` line)
- Modify: `docs/pipeline.md`, `docs/failure-modes.md`

**Interfaces:**
- Consumes: `ledger_repo_root()` (already the ONE definition of a row's repo identity),
  `autonomy_log_path()`'s `${SDD_STATE_DIR:-$HOME/.sdd}` rule, `die()`.
- Produces: `ledger_repo_is_temp <path>` → rc 0 when the path sits under `$TMPDIR` or `/tmp`.
  Task 2 and Task 3 do not use it; nothing else consumes it.

- [ ] **Step 1: Write the failing probe in `tests/check-autonomy.sh`**

Insert a new section immediately BEFORE the line `echo "== reader: the human-facing output =="`.
It builds a self-contained blocked-increment fixture at an arbitrary path — the same shape the
file's own fixture uses at the top — and drives `sdd run`, which escalates with rc 3 BEFORE
opening any session, so the writer is reachable without a token.

```bash
# =============================================================================
# writer: the real ledger is refused to a throwaway checkout (ADR 0005, part 3)
# =============================================================================
# Five of the seven repos in the real ledger were fixtures, and all five sat under /tmp. Every one
# came from a MANUAL run that forgot SDD_STATE_DIR — the isolation mechanism exists and works, and
# what leaked leaked through discipline. This section measures the instrument that replaced the
# reminder.
#
# FOUR regimes, and they are two differential PAIRS rather than one refusal plus decoration:
#   A/B  the same repo under /tmp, one env var apart — SDD_STATE_DIR unset refuses, set writes.
#        Without B, "refuses everything" satisfies A.
#   C/D  the same repo under /var/tmp, one env var apart — TMPDIR unset writes, TMPDIR=/var/tmp
#        refuses. Without D the $TMPDIR arm of the heuristic has no probe at all (every path this
#        suite can mktemp lands under /tmp, so the two arms are otherwise indistinguishable);
#        without C nothing shows that a repo OUTSIDE the temp roots is still written.
#
# /var/tmp is the control root on purpose: it is a temp directory the heuristic deliberately does
# NOT know, which is the declared limit of ADR 0005 part 3 turned into a fixture.
#
# HOME is redirected for the refusing regimes: with SDD_STATE_DIR unset the writer targets
# $HOME/.sdd, and a probe that wrote into the developer's real ledger would be the contamination
# it exists to forbid. The fake HOME is asserted EMPTY afterwards, which is the half that proves
# the refusal happened before the write and not after it.
echo "== writer: the real ledger is refused to a temp checkout =="

TMPGUARD="$OUTSIDE/tmpguard"
mkdir -p "$TMPGUARD/home"

# tmpguard_fixture <dir> — a repo with a blocked increment, which escalates with rc 3 and writes
# exactly one row without opening a session. Same shape as the fixture at the top of this file;
# built as a function because the two roots (/tmp and /var/tmp) need one each and a second
# hand-written copy is how two fixtures come to disagree.
tmpguard_fixture() {
  local d="$1"
  mkdir -p "$d"
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
# `rows` counts what landed in the FAKE home, which is where an unguarded writer would put it.
tmpguard_run() {
  local d="$1" state="$2" tmp="$3" out rc home
  home="$TMPGUARD/home"
  rm -rf "$home"; mkdir -p "$home"
  if [ -n "$state" ]; then rm -rf "$state"; mkdir -p "$state"; fi
  out="$( cd "$d" && env HOME="$home" \
            ${state:+SDD_STATE_DIR="$state"} ${tmp:+TMPDIR="$tmp"} \
            ${state:+} ${tmp:+} \
            "$SDD" run "$MISSION" 2>&1 )"; rc=$?
  printf '%s %s %s' "$rc" \
    "$(grep -q 'SDD_STATE_DIR' <<< "$out" && echo refused || echo silent)" \
    "$( [ -f "$home/.sdd/autonomy-log.jsonl" ] \
          && grep -c . "$home/.sdd/autonomy-log.jsonl" || echo 0 )"
}
```

⚠️ `env` with `${state:+VAR=value}` leaves NOTHING on the command line when the variable is empty,
which is how "unset" is expressed here — `SDD_STATE_DIR=""` would not be unset, it would be a
ledger under `/autonomy-log.jsonl`. Drop the two stray `${state:+} ${tmp:+}` lines when you write
this for real; they are noise from the skeleton above. The final form of the `env` line is:

```bash
  out="$( cd "$d" && env -u SDD_STATE_DIR -u TMPDIR HOME="$home" \
            ${state:+SDD_STATE_DIR="$state"} ${tmp:+TMPDIR="$tmp"} \
            "$SDD" run "$MISSION" 2>&1 )"; rc=$?
```

`env -u` first, then the conditional re-set: the suite EXPORTS `SDD_STATE_DIR` from
`run-all.sh`, so without the `-u` every regime here would silently be regime B.

Now the four assertions:

```bash
tmpguard_fixture "$TMPGUARD/under-tmp" || { fail "PROBE-BROKEN: /tmp fixture" "built" "failed"; }
VARTMP="$(mktemp -d /var/tmp/sdd-tmpguard-XXXXXX)"
trap 'rm -rf "$OUTSIDE" "$VARTMP"' EXIT
tmpguard_fixture "$VARTMP/repo" || { fail "PROBE-BROKEN: /var/tmp fixture" "built" "failed"; }

# A — under /tmp with no SDD_STATE_DIR: refused, loudly, and NOTHING reached the real ledger path.
assert_eq "a repo under the temp dir may not write the real ledger" \
  "1 refused 0" "$(tmpguard_run "$TMPGUARD/under-tmp" "" "")"
# B — the control: the same repo, one env var apart. Without it, a runner that refused every
# ledger everywhere would satisfy A.
assert_eq "...and with SDD_STATE_DIR set the same repo writes its row" \
  "3 silent 0" "$(tmpguard_run "$TMPGUARD/under-tmp" "$TMPGUARD/state" "")"
# C — outside the temp roots the real ledger is written: the guard refuses temp checkouts, not
# repositories. /var/tmp is a temp directory the heuristic deliberately does not know — the
# declared limit of ADR 0005 part 3, standing here as the control it makes possible.
assert_eq "a repo outside the temp roots still writes the real ledger" \
  "3 silent 1" "$(tmpguard_run "$VARTMP/repo" "" "")"
# D — the same repo, refused the moment $TMPDIR names its root. This is the only probe of the
# $TMPDIR arm: every path mktemp hands this suite is under /tmp, so without it the arm is
# indistinguishable from the /tmp literal beside it.
assert_eq "...and refused as soon as TMPDIR names that root" \
  "1 refused 0" "$(tmpguard_run "$VARTMP/repo" "" "/var/tmp")"
```

⚠️ Regime B's rc is `3` and not `0`: the fixture escalates on a blocked increment. B and C assert
the PRE-GUARD rc, which is what makes "the guard did not fire" observable as a value rather than
as an absence.

- [ ] **Step 2: Run the probe and watch it fail for the right reason**

```bash
cd ~/repos/sdd_agents && ./tests/check-autonomy.sh 2>&1 | grep -E 'writer:|FAIL'
```

Expected: regimes A and D FAIL with `got: 3 silent 1` (the runner wrote the row instead of
refusing), B and C already pass. If A fails with `1 refused 0` before you have written any runner
code, the probe is measuring something else — stop and find out what.

- [ ] **Step 3: Write the guard in `bin/sdd`**

Immediately above `autonomy_append()` (find it with `grep -n '^autonomy_append()' bin/sdd`):

```bash
# ONE definition of "this path is a throwaway checkout" — ADR 0005, part 3.
#
# ⚠️ DECLARED LIMITS, and they are why this is a ratchet against the leak that actually happened
# and never a boundary:
#  · it is a PATH heuristic. It knows $TMPDIR and /tmp. macOS hands out /var/folders/…, /var/tmp
#    is a temp directory it does not know, and a fixture built anywhere else walks straight past
#    it. What covers the miss is part 2: the composition makes a contaminating repo VISIBLE in the
#    series the judge reads. The two ship together and neither is sufficient alone.
#  · it says nothing about a WORKTREE under /tmp of a real repository, on purpose: the caller
#    hands it `ledger_repo_root`, which is the shared `.git` of the repository and not the
#    checkout the session runs in. A `git worktree add /tmp/x` of a real repo keeps writing.
# No glob metacharacter can escape from $TMPDIR into the pattern: it is quoted, so `case` takes it
# as a literal.
ledger_repo_is_temp() {   # ledger_repo_is_temp <path> — 0 when it sits under a known temp root
  local repo="${1:-}" tmp="${TMPDIR:-}"
  [ -n "$repo" ] || return 1
  case "$repo" in /tmp/?*) return 0 ;; esac
  while [ "$tmp" != "${tmp%/}" ]; do tmp="${tmp%/}"; done
  case "$tmp" in ''|/) return 1 ;; esac
  case "$repo" in "$tmp"/?*) return 0 ;; esac
  return 1
}
```

Then, INSIDE `autonomy_append`, immediately after the emptiness guard
(`[ -n "${1:-}" ] || { warn "autonomy ledger row came out empty…`) and before
`local file; file="$(autonomy_log_path)"`:

```bash
  # ADR 0005, part 3. Here and not in the callers, for the reason the header of this function
  # already gives: every row goes through here, so a writer added tomorrow is born guarded.
  #
  # `die` and not the `warn`-and-carry-on the two guards below use, because this is a REFUSAL and
  # not an I/O failure: a full disk costs a gap in the ledger, a throwaway checkout costs the
  # judge's evidence, permanently, in a file that is append-only and never migrated.
  # ⚠️ Declared cost: the first row of a `sdd run` is written after the first session, so a
  # mission that hits this has already paid for one. Refusing earlier would mean a guard at every
  # door that opens a session — the shape this repo pays for in four places already, and the
  # shape that guarantees the fifth door is born unguarded.
  # The identity is resolved through the SAME function the row carries in `.repo`, so the guard
  # and the row can never disagree about which repository this is.
  if [ -z "${SDD_STATE_DIR:-}" ]; then
    local guard_repo; guard_repo="$(ledger_repo_root)"
    if ledger_repo_is_temp "$guard_repo"; then
      die "refusing to write the real autonomy ledger: $guard_repo lives under the temp directory, and rows from a throwaway checkout are what the judge reads as missions (ADR 0005). Set SDD_STATE_DIR to a directory of this run's own, or move the repo out of the temp root."
    fi
  fi
```

- [ ] **Step 4: Run the probe and the whole suite**

```bash
cd ~/repos/sdd_agents && bash -n bin/sdd && ./tests/check-autonomy.sh 2>&1 | tail -20 && ./tests/run-all.sh 2>&1 | tail -5
```

Expected: the four `writer:` assertions `ok`, and `suite green`. If another sensor goes red, it is
almost certainly a fixture that runs `sdd run` from `/tmp` without `SDD_STATE_DIR` — the guard is
right and the fixture needs the variable, exactly as `run-all.sh` already sets it globally.

- [ ] **Step 5: Add the mutant**

In `tests/check-mutation.sh`, beside the other `LEDGER_` mutants (after
`mut_LEDGER_bare_by_entry_point`):

```bash
# The writer takes the real ledger back from a throwaway checkout. Nothing fails, nothing is
# malformed: a `sdd run` in a /tmp fixture simply lands its rows in ~/.sdd again, and the judge
# reads them as missions — the leak ADR 0005 part 3 closed, restored exactly as it was.
#
# The `if` and not the function: emptied, `ledger_repo_is_temp` would still be defined and the
# call site would still be there, and this way the mutant proves the CALL is what refuses.
mut_LEDGER_tmp_repo_allowed() {
  sed -i 's@    if ledger_repo_is_temp "$guard_repo"; then@    if false; then@' "$1"
}
```

And add `LEDGER_tmp_repo_allowed` to `CATALOG` beside the other `LEDGER_` entries.

- [ ] **Step 6: Verify the mutant is caught, without paying for the whole catalogue**

The catalogue has no way to run one mutant, and running all of them is 20–50 minutes. Reproduce
what `run_mutant` does by hand:

```bash
cd ~/repos/sdd_agents
BOX="$(mktemp -d /tmp/sdd-onemut-XXXXXX)"
cp -r bin tests templates config agents "$BOX/" && cp CLAUDE.md TODO.md "$BOX/" \
  && mkdir -p "$BOX/docs" && cp -r docs/adr "$BOX/docs/"
sed -i 's@    if ledger_repo_is_temp "$guard_repo"; then@    if false; then@' "$BOX/bin/sdd"
grep -c 'if false; then' "$BOX/bin/sdd"          # expected: at least 1 — the anchor really applied
bash -n "$BOX/bin/sdd" && SDD_MUTANT=1 "$BOX/tests/run-all.sh" >/dev/null 2>&1; echo "rc=$?"
rm -rf "$BOX"
```

Expected: the `grep -c` prints a non-zero count (a sed that did not apply proves nothing), and
`rc` is NOT 0 — the suite dies with the guard sabotaged.

- [ ] **Step 7: Documentation, in the same commit**

- `docs/pipeline.md`: in the ledger section, one paragraph — the writer refuses the real ledger to
  a repo under `$TMPDIR`/`/tmp` unless `SDD_STATE_DIR` is set, with the declared limit.
- `docs/failure-modes.md`: a new mode — symptom (`error: refusing to write the real autonomy
  ledger…`), cause (a fixture or exploratory run from a temp checkout), fix (`SDD_STATE_DIR`), and
  the pointer to ADR 0005.

- [ ] **Step 8: Commit**

```bash
cd ~/repos/sdd_agents && git add -A && git commit -m "feat(ledger): refuse the real ledger to a checkout under the temp dir

ADR 0005, part 3. Five of the seven repos in the real ledger are fixtures and
every one of them sits under /tmp; all five came from manual runs that forgot
SDD_STATE_DIR. The mechanism existed and worked — what leaked, leaked through
discipline, so it is closed with an instrument.

Path heuristic and declared as one in the guard's header: it knows TMPDIR and
/tmp, and /var/tmp (which it does not know) is what the sensor uses as its
control. What covers the miss is part 2.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012biKv9wZBAWhGHMEAKjmn8"
```

---

### Task 2: Part 2 — the series publishes the composition of the axis slice

**Files:**
- Modify: `bin/sdd` — `group_summary` inside `kaizen_series()`; new `kaizen_composition_note()`
  above `cmd_kaizen()`; one call inside `cmd_kaizen`
- Modify: `tests/check-kaizen.sh`
- Modify: `tests/check-mutation.sh` (two mutants + two `CATALOG` lines)
- Modify: `docs/pipeline.md`, `agents/sdd-kaizen.md`

**Interfaces:**
- Consumes: `mission_key` (`[repo, mission]`, already defined above `group_summary` in the jq
  program), `$rows` and `$sess` as `group_summary` already binds them.
- Produces: `.latest.composition` and `.previous.composition`, an ARRAY of
  `{repo: string, missions: number, missions_with_session: number}`, sorted by `missions`
  descending then `repo` ascending. Task 3's reworked assertions read `.latest.composition`.

- [ ] **Step 1: Write the failing assertions in `tests/check-kaizen.sh`**

Add a section right after the `== series: the guard floor counts missions with a comparable
session ==` block (the one with the `escalonly` / `withsessions` / `twoofthree` fixtures), reusing
`localize` and `field`.

```bash
# =============================================================================
# series: the composition of the axis slice (ADR 0005, part 2)
# =============================================================================
# Part 1 points the judge at every repo in the ledger. What makes that SAFE is not a filter, it is
# that the mixture becomes visible: a verdict resting on rows from a throwaway clone is a verdict
# about nothing, and under a silent filter nobody could tell.
#
# Derived over the rows the GUARD ADMITS and never over `event: session`, which is the mistake the
# first draft of the ADR made and left written inside itself: three of the seven repos in the real
# ledger contribute escalations only, so a composition counted over sessions under-reports exactly
# the repos it exists to expose. Both numbers are published for the same reason — `missions` is
# what `guard.missions_after_change` reads, `missions_with_session` is what the FLOOR reads, and a
# composition that explained only one of the two would leave the other a bare number again.
echo "== series: the composition of the axis slice =="

mkdir -p "$OUTSIDE/comp"
COMPOTHER="$OUTSIDE/comp/other"
mkdir -p "$COMPOTHER" && ( cd "$COMPOTHER" && git init -q -b main )
COMPOTHERROOT="$( cd "$COMPOTHER" && git rev-parse --show-toplevel )"
# Three repos on ONE kit version: the fixture repo with two missions (one of them session-less),
# a second repo with one session mission, and a third that contributes an ESCALATION ONLY — the
# shape a session-counted composition cannot see.
sed -e "s|\"repo\":\"/p1\"|\"repo\":\"$FIXROOT\"|g" \
    -e "s|\"repo\":\"/p2\"|\"repo\":\"$COMPOTHERROOT\"|g" \
    -e "s|\"repo\":\"/p3\"|\"repo\":\"/tmp/throwaway\"|g" \
  > "$OUTSIDE/comp/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-20T10:00:00-03:00","event":"session","run_id":"c1","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"c-m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:01:00-03:00","event":"blocked","kind":"increment-blocked","run_id":"c2","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"p1","repo":"/p1","mission":"c-m2","phase":"EXEC","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:02:00-03:00","event":"session","run_id":"c3","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"p2","repo":"/p2","mission":"c-m3","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":2.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-20T10:03:00-03:00","event":"blocked","kind":"budget-exhausted","run_id":"c4","invocation":"run","kit_sha":"ccc0001","kit_dirty":false,"project":"p3","repo":"/p3","mission":"c-m4","phase":"REVIEW","gate_why":"x"}
EOF

COMP_OUT="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/comp" "$KSDD" kaizen --series --all-repos 2>/dev/null )"
comp() { jq -r "$1" <<< "$COMP_OUT"; }

# The three repos are all there, each with its own pair of numbers. Asserted as ONE string, so a
# composition that dropped a repo, merged two, or counted the wrong unit moves the assertion.
assert_eq "composition: every repo of the slice, with missions and missions-with-a-session" \
  "$FIXROOT 2 1|$COMPOTHERROOT 1 1|/tmp/throwaway 1 0" \
  "$(comp '[.latest.composition[] | "\(.repo) \(.missions) \(.missions_with_session)"] | join("|")')"
# The escalation-only repo is the load-bearing one: counted over `event: session` it disappears,
# and the composition would report a clean two-repo slice over a ledger holding three.
assert_eq "composition: a repo that only ESCALATED is still in it" "1" \
  "$(comp '[.latest.composition[] | select(.repo == "/tmp/throwaway")] | length')"
# The arithmetic closes on BOTH numbers, which is what makes the composition an explanation of the
# guard rather than a second set of numbers beside it.
assert_eq "composition: the two sums are the guard's two numbers" "3/2 3/2" \
  "$(comp '"\([.latest.composition[].missions] | add)/\([.latest.composition[].missions_with_session] | add) \(.guard.missions_after_change)/\(.guard.missions_with_session)"')"
# `previous` carries it too — the judge compares two slices, and a composition on only one of them
# explains only half of the comparison.
assert_eq "composition: previous carries one too" "true" \
  "$(comp '(.previous == null) or (.previous | has("composition"))')"
```

⚠️ The heredoc above is `<<'EOF'` fed INTO `sed`, and the redirection sits on the `sed` — copy
that shape exactly. Writing `> file <<'EOF'` on its own line and piping afterwards silently drops
the localisation.

⚠️ `KSDD` is the variable `check-kaizen.sh` already uses for the runner in the gate section. If
the section you insert sits above its definition, use `"$SDD"`; check with
`grep -n 'KSDD=' tests/check-kaizen.sh` and place the block after it, or use `$SDD`.

- [ ] **Step 2: Run it and watch it fail**

```bash
cd ~/repos/sdd_agents && ./tests/check-kaizen.sh 2>&1 | grep -E 'composition|FAIL' | head -20
```

Expected: all four FAIL, three of them with `got:` empty or `null` — there is no `composition`
key yet.

- [ ] **Step 3: Add the field to `group_summary`**

In `kaizen_series()`, inside `def group_summary:`, add `composition` to the emitted object —
between `missions_with_session` and `sessions` keeps the three mission-shaped numbers together:

```jq
         # ADR 0005, part 2. Derived from $rows and NEVER from $sess: the rows the guard admits
         # are sessions AND escalations, and three of the seven repos in the real ledger
         # contribute escalations only. Counted over sessions this field would report a clean
         # slice over a contaminated one — the exact error the first draft of the ADR made, and
         # the reason the record says so about itself.
         # BOTH numbers, because the two above read different rows: `missions` is what
         # missions_after_change reports and `missions_with_session` is what the FLOOR gates on.
         # Each sum closes against its own field, which is what makes this an explanation of the
         # guard instead of a second opinion beside it.
         # An ARRAY of objects and not an object keyed by path, for the reason mission_key is an
         # array: a repo path is arbitrary text, and a key set built from it admits a delimiter
         # nobody chose. sort_by is what makes the order a fact of the data rather than of jq.
         composition: ($rows | group_by(.repo // "")
                             | map({repo: (.[0].repo // ""),
                                    missions: (map(mission_key) | unique | length),
                                    missions_with_session:
                                      (map(select(.event == "session")) | map(mission_key) | unique | length)})
                             | sort_by(-.missions, .repo)),
```

- [ ] **Step 4: Run the assertions again**

```bash
cd ~/repos/sdd_agents && ./tests/check-kaizen.sh 2>&1 | grep -E 'composition|FAIL' | head -20
```

Expected: four `ok`. If the order is wrong, the expectation string in Step 1 is the thing to
re-derive from the printed value — but only after checking that `sort_by(-.missions, .repo)` is
what produced it, never by pasting whatever came out.

- [ ] **Step 5: Say it out loud to the human**

The series carries the composition as data; the human who types `sdd kaizen` has to SEE it, or
part 1's safety argument rests on a field nobody opens. Add above `cmd_kaizen()`:

```bash
# The composition of the axis slice, said out loud — ADR 0005, part 2. The series is the contract
# and the judge reads it there; this is the same fact on the terminal, because the argument that
# makes part 1 safe is that a contaminated slice is SEEN, and a JSON field nobody opens is not
# seen. It explains and never decides: no verdict, no threshold, no opinion (ADR 0001).
#
# Silent when there is no latest slice at all — an empty series has no composition to publish, and
# a header over nothing is the kind of zero this file refuses to print.
kaizen_composition_note() {
  autonomy_have_jq || return 0
  local series
  # stderr dropped for the same reason kaizen_axis_note drops it: the gate one screen down reports
  # an unreadable ledger, and the same complaint from two voices reads as two problems.
  series="$(kaizen_series 2>/dev/null)" || return 0
  local sha; sha="$(jq -r '.latest.kit_sha // empty' <<< "$series")"
  [ -n "$sha" ] || return 0
  local lines
  lines="$(jq -r '.latest.composition[]?
                  | "    \(.missions) mission(s), \(.missions_with_session) with a session  —  " +
                    (if .repo == "" then "<no repo>" else .repo end)' <<< "$series")"
  [ -n "$lines" ] || return 0
  dim "  the slice the judge reads for kit $sha, by repo:"
  local l; while IFS= read -r l; do dim "$l"; done <<< "$lines"
}
```

And call it in `cmd_kaizen`, on the line immediately after `kaizen_axis_note`:

```bash
  kaizen_axis_note
  # Beside the axis note and on the same terms: before the gate, so it reaches the human on BOTH
  # outcomes. CALLED, never `$( )` — it prints.
  kaizen_composition_note
```

- [ ] **Step 6: Assert the printed block**

In `tests/check-kaizen.sh`, right after the composition assertions:

```bash
# The terminal end of the same fact. The series holds the contract; this is the half a human
# actually reads, and it is the half that makes "contamination is visible" true rather than
# available. Asserted as the repos NAMED in the block, not as its wording: prose gets rewritten.
COMP_TTY="$( cd "$FIX" && SDD_STATE_DIR="$OUTSIDE/comp" "$KSDD" kaizen --dry-run 2>&1 )"
assert_eq "composition: the human is shown which repos the slice came from" "3" \
  "$(grep -c 'mission(s), .* with a session' <<< "$COMP_TTY")"
assert_eq "composition: including the throwaway one, by name" "yes" \
  "$(grep -q '/tmp/throwaway' <<< "$COMP_TTY" && echo yes || echo no)"
```

⚠️ `sdd kaizen --dry-run` opens no session but DOES reach `load_config` and the kit-repo checks —
`$FIX` is the kit-shaped fixture the gate section builds, so it satisfies them. If the block does
not print, check that `$FIX` really is `$SDD_HOME`'s toplevel for that invocation; the gate
section's own helpers (`gate_verdict_rc`) show the environment that makes it work.

- [ ] **Step 7: Two mutants**

In `tests/check-mutation.sh`, beside the other `KAIZEN_` series mutants:

```bash
# The composition goes back to counting SESSIONS — the error the first draft of ADR 0005 made and
# left written inside itself. A repo that only ESCALATED on this kit version disappears from the
# published mixture, and the field under-reports exactly the repos it exists to expose: three of
# the seven in the real ledger. The numbers that remain are all plausible, which is the shape the
# assertion has to survive.
mut_KAIZEN_composition_session_unit() {
  sed -i 's@composition: ($rows | group_by(.repo // "")@composition: ($rows | map(select(.event == "session")) | group_by(.repo // "")@' "$1"
}

# The human stops being shown the mixture. The series keeps the field, so every JSON assertion
# stays green and only the terminal goes quiet — which is the whole difference between a fact that
# is available and a fact that is seen, and the difference part 1 rests on.
mut_KAIZEN_composition_unprinted() {
  sed -i '/^  kaizen_composition_note$/d' "$1"
}
```

Add `KAIZEN_composition_session_unit` and `KAIZEN_composition_unprinted` to `CATALOG`.

- [ ] **Step 8: Verify both mutants are caught**

Run the by-hand harness from Task 1 Step 6 twice, once per `sed`. Both must print a non-zero
`grep -c` for their anchor and end with a non-zero `rc`.

- [ ] **Step 9: Documentation and the agent, in the same commit**

- `docs/pipeline.md`, in the series-schema section (search for `missions_with_session`): document
  `composition` — the array, both numbers, that it is derived over admitted rows and not over
  sessions, and that the sums close against the guard's two numbers.
- `agents/sdd-kaizen.md`: the series now carries `composition`; the judge CITES it beside the
  guard, and a verdict over a slice whose composition is dominated by a repo that is not a real
  target repo says so in the verdict.
- Mirror the agent: `./bin/sdd install --force` (never `cp`, never an edit under `.claude/`).

- [ ] **Step 10: Full suite, then commit**

```bash
cd ~/repos/sdd_agents && ./tests/run-all.sh 2>&1 | tail -3
git add -A && git commit -m "feat(kaizen): the series publishes the composition of the axis slice

ADR 0005, part 2. Derived over the rows the guard admits and not over
event: session — three of the seven repos in the real ledger contribute
escalations only, and a session-counted composition under-reports exactly
the repos it exists to expose. The first draft of the ADR counted sessions,
answered 'four repos' against seven, and says so about itself.

Both numbers are published because the guard reads two: missions_after_change
counts every admitted mission, the floor counts the ones that bought a
session. Each sum closes against its own field.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012biKv9wZBAWhGHMEAKjmn8"
```

---

### Task 3: Part 1 — the judge reads every repo (and the ADR's `NOT YET` line comes out)

**Files:**
- Modify: `bin/sdd` — `cmd_kaizen()` default, `boot_prompt()` `ledger_flags` removal,
  `kaizen_reminder()`'s closing sentence, `cmd_help()`
- Modify: `tests/check-kaizen.sh` — rework `== one series behind the verdict ==`, add the
  default-reading assertions
- Modify: `tests/check-mutation.sh` — remove `mut_KAIZEN_prompt_series_unflagged`, add
  `mut_KAIZEN_series_default_per_repo`, keep `CATALOG` in step
- Modify: `docs/pipeline.md`, `docs/failure-modes.md`, `README.md`, `agents/sdd-kaizen.md`
- Modify: `docs/adr/0005-judge-reads-every-repo-with-visible-composition.md`

**Interfaces:**
- Consumes: `.latest.composition` from Task 2 (the reworked "one series" section asserts the slice
  really does mix two repos).
- Produces: no new symbol. `LEDGER_ALL_REPOS` is 1 for the whole of `cmd_kaizen`, so `gate_KAIZEN`,
  `kaizen_axis_note`, `kaizen_composition_note` and `kaizen_series --series` all read one slice.

- [ ] **Step 1: Rework the `== one series behind the verdict ==` section — it is about to go
      vacuous, and a vacuous section is worse than a deleted one**

That section's witness demands that the per-repo and the `--all-repos` readings DISAGREE. After
this task `--all-repos` is a no-op on `sdd kaizen`, so `JS_LOCAL == JS_ALL` and the witness fails —
correctly, because the regime it needed no longer exists. Replace the witness and the pair; keep
the real-gate half, which gets STRONGER.

Read the whole section first (`grep -n 'one series behind the verdict' tests/check-kaizen.sh`),
then:

1. Keep the fixture (`judgesplit`, three missions for `$FIXROOT` on `qqq1111` and three for
   `$JOTHER` on `zzz9999`, the other repo's rows LAST in file order) exactly as it is.
2. Replace the witness with one that reads the FIXTURE rather than the runner — the regime is a
   property of the ledger, and a witness computed by the thing under test agrees with its own bug:

```bash
# Witness for the REGIME, computed from the FIXTURE and never from the runner: this section is
# about what the runner answers, so a witness the runner derived would agree with whatever it
# does. The property is that the newest kit version in the file belongs to the OTHER repo — so a
# judge that still filtered per repo would land on a different sha and every assertion below moves.
JS_KITONLY="$(jq -rs --arg r "$FIXROOT" '[.[] | select(.repo == $r)] | last | .kit_sha' \
                "$OUTSIDE/judgesplit/autonomy-log.jsonl")"
JS_WHOLE="$(jq -rs 'last | .kit_sha' "$OUTSIDE/judgesplit/autonomy-log.jsonl")"
assert_eq "witness: the newest version in the file is NOT the kit repo's own (else the pair proves nothing)" \
  "differ" \
  "$( if [ "$JS_KITONLY" != "$JS_WHOLE" ] && [ -n "$JS_KITONLY" ] && [ -n "$JS_WHOLE" ]
      then echo differ; else echo "same:$JS_KITONLY/$JS_WHOLE"; fi )"
```

3. Replace `JS_LOCAL`/`JS_ALL` and the two `one series:` assertions with three that pin the new
   contract — the judge reads the whole file, with the flag and without it, and the prompt hands
   the agent the same reading:

```bash
# ADR 0005, part 1: the judge's question is "what did this kit version cost", and ADR 0003 says
# that evidence lives in real target repos. So the default reading is the WHOLE ledger — and
# `--all-repos` is kept, and kept a no-op here, because scripts and handoffs already carry it and
# a flag that silently changed meaning is worse than one that stopped mattering in one of its two
# homes. `sdd autonomy` is where it still decides something.
assert_eq "the judge reads every repo by default (ADR 0005, part 1)" "$JS_WHOLE" "$(gate_sha)"
assert_eq "...and --all-repos is a no-op on the judge, never a second reading" "$JS_WHOLE" "$(gate_sha --all-repos)"
assert_eq "one series: the prompt hands the agent the reading the gate takes" \
  "$(gate_sha)" "$(judge_prompt_sha)"
```

4. Keep `gate_verdict_rc` and its pair, retargeted: accepted with `$JS_WHOLE`, refused with
   `$JS_KITONLY` (the sha a per-repo judge would have demanded). Drop the `--all-repos` arguments —
   they decide nothing now:

```bash
loud_stub
assert_eq "real gate: it accepts the very sha the prompt hands the agent" \
  "0 verdict-found" "$(gate_verdict_rc "$(judge_prompt_sha)")"
dead_stub
assert_eq "real gate: and refuses the sha a per-repo reading would have demanded" \
  "3 no-verdict" "$(gate_verdict_rc "$JS_KITONLY")"
```

- [ ] **Step 2: Run it and watch it fail**

```bash
cd ~/repos/sdd_agents && ./tests/check-kaizen.sh 2>&1 | grep -E 'witness|the judge reads|one series|real gate|FAIL' | head -20
```

Expected: the witness passes (it reads the fixture), `the judge reads every repo by default` FAILS
with `got:` = the kit-only sha, and the real-gate pair FAILS.

- [ ] **Step 3: Make `cmd_kaizen` read every repo**

In `cmd_kaizen()`, as the FIRST statement of the body, above `local series_only=0`:

```bash
  # ADR 0005, part 1 — the judge reads the WHOLE ledger. ADR 0003 already said where verdict
  # evidence lives (real target repos: in the repo that BUILDS the kit every session lands on a
  # fresh sha and the axis degenerates by construction), and it stayed a dead letter for nine days
  # because nothing said how the judge READS those rows — the per-repo default kept it looking at
  # exactly the one repo 0003 declared unusable, and excluded the evidence as `other_repo`.
  # Set HERE, before the option loop, so it reaches every half of this command in one process:
  # `--series`, `gate_KAIZEN`, `kaizen_axis_note` and `kaizen_composition_note` all read one slice.
  # What makes it safe is part 2 — the composition of that slice is published, so contamination is
  # a thing you SEE instead of a thing the runner guesses at.
  # `sdd autonomy` keeps the per-repo default: its question really is "what did THIS repo cost".
  LEDGER_ALL_REPOS=1
  local series_only=0
```

And in the same function's option loop, the `--all-repos)` arm keeps the assignment (harmless) but
its comment is now a lie — replace it:

```bash
      # Kept, and a NO-OP here since ADR 0005: the judge reads every repo by default. Scripts,
      # handoffs and the boot prompts of finished missions already carry the flag, and a flag that
      # silently changed meaning would be worse than one that stopped deciding in one of its two
      # homes — on `sdd autonomy` it still decides everything.
      --all-repos) LEDGER_ALL_REPOS=1 ;;
```

- [ ] **Step 4: Delete `ledger_flags` from the boot prompt**

In `boot_prompt()`, the `KAIZEN` branch: remove the two lines

```bash
    local ledger_flags=""
    [ "$LEDGER_ALL_REPOS" = "1" ] && ledger_flags=" --all-repos"
```

and change the prompt line `sdd kaizen --series$ledger_flags` to `sdd kaizen --series`. Replace
the long comment above them with the reason the machinery is gone:

```bash
    # ADR 0001 splits the judge in two halves that must read ONE series: the runner derives the
    # numbers, the agent gives the verdict citing them. That invariant used to be MAINTAINED here
    # — the gate read the series in-process and inherited every ledger option, while this prompt
    # hands the agent a WRITTEN command line, so `--all-repos` reached one half and not the other:
    # the prompt ordered `kit_sha_judged:` to be its latest, the gate hunted for its own, no
    # verdict satisfied both, and the phase ended `BLOCKED in KAIZEN — no-progress`. Two opus
    # sessions for a blocked row (BUG-1, 20260817-eixo-do-juiz).
    # Since ADR 0005 the invariant holds BY CONSTRUCTION instead of by upkeep: there is one
    # reading, `cmd_kaizen` sets it for the whole process, and the line below carries no option
    # that could disagree with the gate. The mutant that watched the propagation is retired with
    # the machinery; `mut_KAIZEN_series_default_per_repo` watches the default that replaced it.
```

- [ ] **Step 5: The post-pipeline reminder stops saying something false**

`kaizen_reminder()`'s last line says *"Today's kaizen judge reads only the kit's own missions, so
it will not count them."* — after this task that is a lie, and it is printed in every target repo.
The reminder keeps its PER-REPO count (its question is what THIS repo just contributed; it is
called from `cmd_run`, which has no `--all-repos`), and only the sentence changes:

```bash
  # Outside the kit there is nothing to run here, and the pointer is to the kit. Until ADR 0005
  # this line said the judge would not count these rows, which was true and is now false: the
  # judge reads every repo, and ADR 0003 says these are exactly the rows a verdict should rest on.
  # The COUNT stays per repo — this sentence is about what the run that just finished contributed,
  # and `sdd run` carries no ledger option to widen it with.
  dim "  autonomy series: $n mission(s) of this repo on kit $sha are in the ledger. The kaizen judge counts them (ADR 0005) — run 'sdd kaizen' in the kit repo ($SDD_HOME)."
```

Also fix the stale claim in the comment ABOVE `kaizen_reminder()` ("A repo whose rows all came from
somewhere else gets missions_after_change 0 here and stays silent … there is nothing of THIS repo
for the judge to look at") — the silence is still right, but the reason is now "this repo
contributed nothing new", not "the judge cannot see it".

- [ ] **Step 6: `cmd_help`**

Rewrite the `LEDGER OPTIONS` block. The old text ends in a ⚠️ paragraph deferring the decision to
"a future ADR" — that ADR is 0005 and it is now implemented, so the paragraph is a description of
a world that no longer exists:

```
LEDGER OPTIONS
  --all-repos                on `sdd autonomy`: read the WHOLE ledger, not just the rows born in
                             this repo. The default there is per repo because that command's
                             question is "what did THIS project cost", and because a `sdd run` in
                             a THROWAWAY FIXTURE repo once moved the numbers.
                             On `sdd kaizen` it is a NO-OP, kept because scripts and handoffs
                             carry it: since ADR 0005 the judge always reads every repo. Its
                             question is the other one — ADR 0003 says verdict evidence comes
                             from real target repos, because the kit's own axis degenerates by
                             construction — and the composition of the slice it read is published
                             beside the numbers, so a contaminated verdict is visible instead of
                             silent. A repo under $TMPDIR can no longer write the real ledger at
                             all without SDD_STATE_DIR.
```

Update the two `sdd kaizen` usage lines above it so the `[--all-repos]` continuation lines no
longer suggest the flag changes the reading.

- [ ] **Step 7: Run the sensors**

```bash
cd ~/repos/sdd_agents && bash -n bin/sdd && ./tests/check-kaizen.sh 2>&1 | tail -25 && ./tests/run-all.sh 2>&1 | tail -3
```

Expected: `the series tells the truth and the gate holds`, and `suite green`.

Then measure the change on the REAL ledger and keep the two numbers for Task 5:

```bash
cd ~/repos/sdd_agents && ./bin/sdd kaizen --series | jq -c '{latest:.latest.kit_sha,guard:.guard,excluded:.excluded,composition:.latest.composition}'
```

Expected: `excluded.other_repo` is now `0` where the pre-change default reported `38`.

- [ ] **Step 8: Retire one mutant, add its replacement**

In `tests/check-mutation.sh`:

1. Delete `mut_KAIZEN_prompt_series_unflagged` and its `CATALOG` line. It anchors on
   `ledger_flags=" --all-repos"`, which no longer exists — left in place it reports
   CATALOGUE-BROKEN (rc 90), and re-anchored on the new code it would SURVIVE, because with one
   reading the prompt and the gate cannot disagree. A mutant whose defect is structurally
   unreachable is not a mutant.
2. Add, beside the other `KAIZEN_` mutants:

```bash
# The judge goes back to reading only the repo it stands in — the dead letter ADR 0003 was for
# nine days. Nothing fails and nothing is malformed: `sdd kaizen` in the kit repo simply looks at
# the one repo 0003 declared unusable, files every real target repo's rows under `other_repo`, and
# can only ever answer `indeterminado`. Roughly US$ 400 of measured evidence, excluded in silence.
#
# Range-addressed to the head of cmd_kaizen: `LEDGER_ALL_REPOS=1` also spells the `--all-repos`
# arm of two option loops, and an unaddressed sed would sabotage three sites while claiming one.
mut_KAIZEN_series_default_per_repo() {
  sed -i '/^cmd_kaizen() {/,/^  local series_only=0$/ s@^  LEDGER_ALL_REPOS=1$@  LEDGER_ALL_REPOS=0@' "$1"
}
```

Add `KAIZEN_series_default_per_repo` to `CATALOG`.

⚠️ The range end `^  local series_only=0$` must be the line you actually wrote in Step 3. Verify
with `sed -n '/^cmd_kaizen() {/,/^  local series_only=0$/p' bin/sdd` before trusting the mutant.

- [ ] **Step 9: Verify the new mutant is caught, and that the retired one really is gone**

```bash
cd ~/repos/sdd_agents
grep -c 'ledger_flags' bin/sdd tests/check-mutation.sh    # expected: 0 and 0
BOX="$(mktemp -d /tmp/sdd-onemut-XXXXXX)"
cp -r bin tests templates config agents "$BOX/" && cp CLAUDE.md TODO.md "$BOX/" \
  && mkdir -p "$BOX/docs" && cp -r docs/adr "$BOX/docs/"
sed -i '/^cmd_kaizen() {/,/^  local series_only=0$/ s@^  LEDGER_ALL_REPOS=1$@  LEDGER_ALL_REPOS=0@' "$BOX/bin/sdd"
diff <(grep -n 'LEDGER_ALL_REPOS=0' bin/sdd) <(grep -n 'LEDGER_ALL_REPOS=0' "$BOX/bin/sdd") \
  && echo "MUTANT-DID-NOT-APPLY" || echo "mutant applied"
bash -n "$BOX/bin/sdd" && SDD_MUTANT=1 "$BOX/tests/run-all.sh" >/dev/null 2>&1; echo "rc=$?"
rm -rf "$BOX"
```

Expected: `mutant applied` and a non-zero `rc`.

- [ ] **Step 10: Documentation, the agent, and the ADR's own line**

- `docs/pipeline.md`: the `--all-repos` section (search `the door back to the cross-project
  question`) — the judge's default is now the whole ledger, the flag still decides on
  `sdd autonomy`, and the composition is what makes it safe. Also the sentence about the reminder.
- `docs/failure-modes.md`: the `other_repo` mode (line ~92 onwards) — for the JUDGE that symptom
  is gone; `sdd autonomy` is where it still applies.
- `README.md` lines 62–65: the three `--all-repos` lines.
- `agents/sdd-kaizen.md`: the boot prompt hands a bare `--series`; the reading is every repo;
  cite `composition`. Then `./bin/sdd install --force`.
- `docs/adr/0005-judge-reads-every-repo-with-visible-composition.md`: **delete the
  `· **Implementation: NOT YET IN THE RUNNER**` from the status line and the whole `> ⚠️` blockquote
  under it.** This is the commit that lands the last of the three parts, which is exactly when the
  record itself says the line comes out.

- [ ] **Step 11: Full suite, then commit**

```bash
cd ~/repos/sdd_agents && ./tests/run-all.sh 2>&1 | tail -3
git add -A && git commit -m "feat(kaizen): the judge reads every repo, and ADR 0005 is implemented

Part 1, the last of the three. ADR 0003 said verdict evidence comes from real
target repos and never said how the judge READS them, so the per-repo default
kept it looking at exactly the one repo 0003 declared unusable: measured on
20260825-frete-cif-fob, 21 comparable rows and 35 excluded as other_repo, with
three planned missions on a frozen sha that would all have answered
indeterminado.

--all-repos is kept and is a no-op here; on sdd autonomy it still decides.
The boot prompt drops the flag machinery: with one reading, the gate and the
prompt cannot disagree, so the invariant holds by construction instead of by
upkeep. mut_KAIZEN_prompt_series_unflagged retires with it and
mut_KAIZEN_series_default_per_repo takes its place.

The 'Implementation: NOT YET IN THE RUNNER' line comes out here, which is what
the record says should happen in the commit that lands the last part.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012biKv9wZBAWhGHMEAKjmn8"
```

---

### Task 4: § 4 — the phase ceiling counts sessions, not laps

**Files:**
- Modify: `bin/sdd` — the ceiling in `cmd_run()`
- Modify: `tests/check-autonomy.sh` — a probe with its own regime witness
- Modify: `tests/check-mutation.sh` — one mutant + one `CATALOG` line
- Modify: `docs/pipeline.md` if it states the ceiling in laps

**Interfaces:**
- Consumes: `sessions["$phase"]`, which `cmd_run` already increments at BOTH session sites
  (after the first `run_phase` and after the retry) and already reads for the blocked headline.
- Produces: nothing new. `attempts["$phase"]` keeps its only remaining job — the ledger's
  `attempt` field, which stays the LAP number, so no row shape changes.

- [ ] **Step 1: Find the two anchors, in code and not by line number**

```bash
cd ~/repos/sdd_agents
grep -n 'QA_MAX_ITER \* 3' bin/sdd          # phase_budget: the QA budget
grep -n 'attempts\[' bin/sdd                # the increment, the ceiling test, two ledger rows
grep -n 'sessions\[' bin/sdd                # the headline and the two increments
```

Expected: `attempts[` on four lines — the increment, the `-gt "$budget"` test, and two
`autonomy_session_row` calls. Only the SECOND one changes.

- [ ] **Step 2: Write the failing probe in `tests/check-autonomy.sh`**

Add after the `== session rows ==` section. The regime it needs is a lap that costs TWO sessions:
the first session must move nothing (so the runner retries) and the retry must move the disk (so
the lap ends `carrying on` instead of escalating `no-progress`). An alternating stub does exactly
that, and the mission is EXEC with one pending increment, whose budget is
`rows + EXEC_MAX_RETRY + 2` = 4.

```bash
# =============================================================================
# the phase ceiling counts SESSIONS, not laps
# =============================================================================
# `attempts` rose once per lap of the loop, before the first run_phase, and the retry inside the
# lap opened a second session without touching it. So a budget of N bought up to 2N sessions:
# QA's `QA_MAX_ITER * 3` = 9 was a ceiling of 18. Measured on 20260825-frete-cif-fob — the ceiling
# WORKED (9 laps, exactly the limit) and 3 of those laps bought a retry, turning 9 into 12 sessions
# and US$ 11.27. The budgets were always written in sessions ("3 sub-steps per round"), so this
# makes the unit match the arithmetic rather than lowering anything.
#
# `sessions` is the counter that was already there and already right: cmd_run increments it at
# BOTH session sites and the blocked headline already reads it.
#
# ⚠️ The bound is budget + 1, not budget, and it is stated rather than hidden: the ceiling is
# tested once per lap, and a lap that has already been admitted may still buy its retry.
#
# THE WITNESS COMES FIRST. On a fixture where every lap costs one session, laps and sessions are
# the same number and the assertion below passes under the OLD code too — measured, and the reason
# the alternating stub exists at all.
echo "== the phase ceiling counts sessions, not laps =="
```

Build the stub as a script with a counter file: odd invocations exit non-zero having written
nothing; even invocations commit an empty change into the mission directory, which moves
`state_fingerprint` (it reads HEAD, the mission listing and the checkpoint's md5).

```bash
CEIL="$OUTSIDE/ceiling"
mkdir -p "$CEIL/stub"
cat > "$CEIL/stub/claude" <<STUB
#!/usr/bin/env bash
n=\$(( \$(cat "$CEIL/n" 2>/dev/null || echo 0) + 1 ))
echo "\$n" > "$CEIL/n"
if [ \$(( n % 2 )) -eq 1 ]; then exit 9; fi
: > "$CEIL/repo/docs/handoffs/$MISSION/note-\$n.md"
git -C "$CEIL/repo" add -A >/dev/null 2>&1
git -C "$CEIL/repo" commit -qm "stub: session \$n moved the disk" >/dev/null 2>&1
exit 0
STUB
chmod +x "$CEIL/stub/claude"
```

Then a fixture at `$CEIL/repo` (reuse `tmpguard_fixture` from Task 1, with the checkpoint's status
`pending` instead of `blocked` so EXEC is reached rather than escalated), run it with the stub
first on `PATH` and `SDD_STATE_DIR` pointing at a ledger of its own, and assert:

```bash
CEILSTATE="$OUTSIDE/ceilstate"; mkdir -p "$CEILSTATE"
CEILLEDGER="$CEILSTATE/autonomy-log.jsonl"
( cd "$CEIL/repo" && PATH="$CEIL/stub:$PATH" SDD_STATE_DIR="$CEILSTATE" "$SDD" run "$MISSION" >/dev/null 2>&1 )
ceil_sessions="$(jq -rs '[.[] | select(.event == "session")] | length' "$CEILLEDGER")"
ceil_retries="$(jq -rs '[.[] | select(.event == "session" and .auto_retry == true)] | length' "$CEILLEDGER")"
ceil_laps="$(jq -rs '[.[] | select(.event == "session") | .attempt] | max' "$CEILLEDGER")"

# WITNESS: without a lap that really bought a retry, sessions and laps are the same number and the
# assertion below is satisfied by the defect it exists to forbid.
assert_eq "witness: the fixture really does buy a retry inside a lap" "yes" \
  "$( [ "${ceil_retries:-0}" -ge 1 ] && echo yes || echo "no:$ceil_retries" )"
# EXEC's budget is rows + EXEC_MAX_RETRY + 2 = 1 + 1 + 2 = 4 sessions, +1 for the lap already
# admitted when the ceiling was last tested. Counting laps, the same fixture buys 8.
assert_eq "the ceiling stops the phase by SESSIONS spent, not laps of the loop" "within" \
  "$( if [ "${ceil_sessions:-0}" -le 5 ]; then echo within; else echo "over:$ceil_sessions"; fi )"
# The differential that makes the number mean something: laps really are fewer than sessions here,
# so "within" was not reached by the two being equal.
assert_eq "...and it is a real distinction on this fixture: fewer laps than sessions" "fewer" \
  "$( if [ "${ceil_laps:-0}" -lt "${ceil_sessions:-0}" ]; then echo fewer
      else echo "same:$ceil_laps/$ceil_sessions"; fi )"
```

- [ ] **Step 3: Run it and watch the middle assertion fail**

```bash
cd ~/repos/sdd_agents && ./tests/check-autonomy.sh 2>&1 | grep -E 'ceiling|witness|FAIL' | head
```

Expected: the witness passes, `the ceiling stops the phase by SESSIONS spent` FAILS with
`got: over:8`. If it reports `over:` with a number that is not double the budget, read the ledger
at `$CEILLEDGER` before touching the runner — the fixture may not be in the regime you think.

- [ ] **Step 4: Change the ceiling**

In `cmd_run()`, the block that reads

```bash
    budget="$(phase_budget "$phase")"
    attempts["$phase"]="$(( ${attempts[$phase]:-0} + 1 ))"
    local over_ceiling=0 ceiling_note=""
    [ "${attempts[$phase]}" -gt "$budget" ] && over_ceiling=1
```

becomes

```bash
    budget="$(phase_budget "$phase")"
    # `attempts` is the LAP number and it stays that: it is what the ledger's `attempt` field
    # carries, and the retry inside a lap is told apart by `auto_retry` rather than by a number.
    attempts["$phase"]="$(( ${attempts[$phase]:-0} + 1 ))"
    local over_ceiling=0 ceiling_note=""
    # SESSIONS, and never laps. `attempts` rises once per lap, before the first run_phase, and the
    # retry inside the lap opens a second session without touching it — so a budget of N bought up
    # to 2N sessions and QA's `QA_MAX_ITER * 3` = 9 was a ceiling of 18. Every budget in
    # phase_budget is written in sessions already ("3 sub-steps per round"), so this makes the unit
    # match the arithmetic instead of lowering a limit. Measured on 20260825-frete-cif-fob: the
    # ceiling held at exactly 9 laps and 3 of them bought a retry — 12 sessions, US$ 11.27.
    # `sessions` is the counter cmd_run already keeps at BOTH session sites and the blocked
    # headline already reads, so the number in the escalation and the number that caused it are
    # one.
    # `-ge` and read BEFORE the lap, so the bound is budget + 1 and not budget: the test happens
    # once per lap and a lap already admitted may still buy its retry. Stated rather than hidden —
    # exact accounting would need a second ceiling inside the lap, which is a second door.
    [ "${sessions[$phase]:-0}" -ge "$budget" ] && over_ceiling=1
```

- [ ] **Step 5: Run the probe, then the whole suite**

```bash
cd ~/repos/sdd_agents && bash -n bin/sdd && ./tests/check-autonomy.sh 2>&1 | grep -E 'ceiling|witness|FAIL' | head
./tests/run-all.sh 2>&1 | tail -5
```

Expected: three `ok`, `suite green`. Sensors that drive a phase to its ceiling now stop one
session earlier — if `check-gates.sh` goes red, read the failing assertion's expectation: a
hard-coded session count that was double the budget is the assertion agreeing with the defect, and
it moves with an explanation in its comment.

- [ ] **Step 6: The mutant**

```bash
# The ceiling counts LAPS again. Every budget in phase_budget is written in sessions, and the
# retry inside a lap opens a second one without touching `attempts` — so the QA ceiling of 9 is a
# ceiling of 18 and nothing anywhere says so. It is not the same line as
# mut_RUN_blocked_counts_laps, which restores the same confusion in the HEADLINE: that one
# misreports a number, this one buys sessions.
mut_RUN_qa_ceiling_counts_laps() {
  sed -i 's@\[ "${sessions\[$phase\]:-0}" -ge "$budget" \] && over_ceiling=1@[ "${attempts[$phase]}" -gt "$budget" ] \&\& over_ceiling=1@' "$1"
}
```

Add `RUN_qa_ceiling_counts_laps` to `CATALOG`, and verify it with the by-hand harness from Task 1
Step 6.

- [ ] **Step 7: Commit**

```bash
cd ~/repos/sdd_agents && git add -A && git commit -m "fix(runner): the phase ceiling counts sessions, not laps of the loop

attempts[] rises once per lap, before the first run_phase; the retry inside
the lap opens a second session without touching it. A budget of N bought up
to 2N sessions, so QA's QA_MAX_ITER * 3 = 9 was a ceiling of 18.

Measured on 20260825-frete-cif-fob: the ceiling WORKED — 9 laps, exactly the
limit — and 3 of those laps bought a retry, turning 9 sessions into 12 at
US\$ 11.27. Every budget in phase_budget is already written in sessions
('3 sub-steps per round'), so this makes the unit match the arithmetic
rather than lowering a limit.

sessions[] is the counter cmd_run already keeps at both session sites and
the blocked headline already reads. attempts[] keeps the ledger's attempt
field, so no row shape changes. Bound is budget + 1 and the comment says so.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012biKv9wZBAWhGHMEAKjmn8"
```

---

### Task 5: the catalogue, the stamp, and the measured before/after

**Files:**
- Modify: `KAIZEN_LOG.md`
- Possibly: `tests/health-baseline.txt` (only if `todo-findings` legitimately moved)

- [ ] **Step 1: Run the whole catalogue — this is the expensive one (20–50 min)**

⚠️ Order matters and costs 20–50 minutes when it is wrong: the stamp's key is the CONTENT of
`bin/ tests/ templates/ config/`, so this runs AFTER the last commit that touches any of them.
`KAIZEN_LOG.md` and `docs/` do not invalidate it — `tests/health-baseline.txt` does.

```bash
cd ~/repos/sdd_agents && git status --porcelain    # expected: clean
./bin/sdd health --with-mutation 2>&1 | tail -40
```

Expected: `score: N caught, 0 known gap(s), of N` with the two Ns equal, and a green stamp. Five
mutants were added and one retired, so N is the previous total + 4.

- [ ] **Step 2: If any mutant SURVIVED, the assertion is missing — not the mutant**

A surviving mutant means the sabotage went unnoticed by the suite. Do not add it to `KNOWN_GAPS`:
that list is a ratchet for debt that is already declared, not a place to put this task's own
misses. Find which assertion should have died, and make it die.

- [ ] **Step 3: Write the KAIZEN_LOG entry (pt-BR — this repo's `OUTPUT_LANG`)**

Numbers only, measured, no adjectives. The four to carry:

1. `sdd kaizen --series` on the real ledger, before: `latest 06e49bc`, `excluded.other_repo: 38`.
   After: `other_repo: 0` and the composition beside it (paste the real output of
   `./bin/sdd kaizen --series | jq -c '.latest.composition'`).
2. The QA ceiling: `QA_MAX_ITER * 3` = 9 laps was 18 sessions; it is now 9 (+1). The measured
   incident: `20260825-frete-cif-fob`, 3 laps bought a retry, 12 sessions, US$ 11.27.
3. The catalogue: N before → N after, both `caught == of`.
4. The suite's wall clock before and after (`time ./tests/run-all.sh`), because the ceiling probe
   and the four ledger regimes are new work every mutant pays for.

- [ ] **Step 4: Commit and verify the stamp survived**

```bash
cd ~/repos/sdd_agents && git add -A && git commit -m "docs(kaizen): a ADR 0005 implementada e o teto da QA, com os numeros medidos

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012biKv9wZBAWhGHMEAKjmn8"
./bin/sdd health 2>&1 | tail -20
```

Expected: still green, and the mutation stamp still valid — `KAIZEN_LOG.md` is not one of the four
paths the stamp key reads. If the stamp went stale, something in `bin/ tests/ templates/ config/`
moved after Step 1 and the catalogue has to run again.

- [ ] **Step 5: Report, do not merge**

Print for the human: the four numbers above, the list of files touched, and the two things this
work does NOT prove — the QA-ceiling fix has never run against a real mission (the proof is the
next target-repo mission), and the REVIEW phase became the most expensive phase in the pipeline
(US$ 32.94 in one session on the last mission, more than the six EXEC sessions together) with
nobody having looked at it yet.

---

## Self-Review

**Spec coverage.**

| Spec item | Task |
|---|---|
| ADR 0005 part 1 — `sdd kaizen` reads every repo | Task 3, Steps 3–4 |
| ADR 0005 part 2 — the series publishes the composition | Task 2, Steps 3, 5 |
| ADR 0005 part 2 ⚠️ — derived over admitted rows, not over `event: session` | Task 2, Step 3 (the jq) and Step 1 (the escalation-only repo in the fixture, and the mutant in Step 7) |
| ADR 0005 part 3 — refuse the real ledger under `TMPDIR` | Task 1, Step 3 |
| ADR 0005 part 3 ⚠️ — the declared limit lives in the guard's header | Task 1, Step 3 (the header) |
| "the floor of 3 and the `kit_sha` axis are NOT re-litigated" | nothing in this plan touches `KAIZEN_GUARD_FLOOR` or `on_axis` |
| ⚠️ remove `Implementation: NOT YET IN THE RUNNER` in the commit that lands the LAST part | Task 3, Step 10 (part 1 is last by construction of the task order) |
| Consequence — "the boot prompt, `kaizen_axis_note`, `check-kaizen.sh` learn it in the same commit" | Task 2 (schema + agent + docs) and Task 3 (prompt + help + docs) |
| Handoff § 4 — the QA ceiling counts sessions | Task 4 |
| Handoff § 4 — "Sensor obrigatório: mutante novo" | Task 4, Step 6 |
| Handoff § 4 — anchors in CODE, not line numbers | Task 4, Step 1 |
| Handoff § 8 — `sdd status`/`sdd phase` run the gates and are not cheap | not used anywhere in this plan |
| Handoff § 8 — `pgrep -f` in a waiting loop matches itself | no waiting loop in this plan; the long command (Task 5 Step 1) is run in the foreground |

**Placeholders.** None: every step carries the code or the exact command and its expected output.
Task 5's KAIZEN_LOG entry names the four numbers and where each is read from, rather than saying
"write a log entry".

**Type consistency.** `composition` is `[{repo, missions, missions_with_session}]` in the jq
(Task 2 Step 3), in the assertions (Task 2 Step 1), in the printed block (Task 2 Step 5), in the
mutants (Task 2 Step 7) and in the reworked section (Task 3 Step 1). `ledger_repo_is_temp` takes
one path and returns an rc in both its definition and its only call site. `sessions[$phase]` and
`attempts[$phase]` keep the meanings Task 4 assigns them at every one of their six sites.

**One known risk, flagged rather than solved in advance.** Task 3 Step 1 rewrites a section of
`check-kaizen.sh` whose fixture was built for a regime this change deletes. If the reworked
witness cannot be made to hold on that fixture, do NOT delete the section: a section removed is a
property nobody measures. Ask instead, with the fixture's actual numbers in hand.
