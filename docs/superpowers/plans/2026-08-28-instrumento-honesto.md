# O instrumento honesto — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Both readers of the autonomy ledger (`sdd autonomy`, `sdd kaizen --series`) derive **what
a session did** — `advanced · churned · idle` — from fields every row already has (`gate` + `moved`),
and the D12 intervention count comes from an artifact (`run_id`) instead of prose. Zero migration,
`v` stays `1`.

**Architecture:** One bash function (`ledger_outcome_defs`) prints jq `def`s that BOTH readers splice
into their programs, the way `ledger_row_is_local` already does — one emission, parity proved by a
differential assertion, never by "same spelling in both". `sdd autonomy` swaps `stalled` for the
three outcomes and changes the yardstick of `waste`; `--by-mission` gains `launch(es)` (distinct
`run_id`) and `reopened` (a phase below one whose gate had already passed), both drawn over **every**
local session of the mission while `session(s)`/outcomes/`US$` stay on the comparable ones. The
judge's series gains `outcomes` and `advance_rate` per group and per `detail[]` entry, and the
rubric reads any `gate == fail` session as at least `leve`. Every behaviour change lands with a
mutant; `166 → 173`.

**Tech Stack:** bash 5 (`set -euo pipefail`), jq 1.7, git, markdown. `mawk` on this box (byte
oriented — no negated class with a multibyte char).

**Spec:** `docs/superpowers/specs/2026-08-28-instrumento-honesto-design.md`. Read it first; this
plan argues from it. Section numbers below (`§4.4`, `5.7`, …) are the spec's.

> The spec's D-c says "plano em `~/.claude/plans/`" — that is where plan-mode plans of earlier
> missions lived. This plan lives beside the two writing-plans plans already in
> `docs/superpowers/plans/`, so it travels with the repo like the spec does.

## Global Constraints

- **The kit surface is English** — `bin/sdd`, `agents/`, `docs/pipeline.md`, `docs/failure-modes.md`,
  `docs/adr/`, `README.md`, `tests/`: prose, comments, messages, test names. `TODO.md`,
  `KAIZEN_LOG.md`, `CONTEXT.md`, `templates/`, `docs/handoffs/`, `docs/superpowers/specs/` are
  `OUTPUT_LANG` = pt-BR. Sensor: `tests/check-lang.sh`. Commit messages are pt-BR, form
  `<tipo>(<escopo>): <o quê>`, with the why in the body.
- **`bin/sdd` runs under `set -euo pipefail`.** Guard every capture that can return non-zero
  (`|| true`, `|| rc=$?`); the last line `{ main "$@"; exit $?; }` is contract.
- **No apostrophe inside the jq programs of `cmd_autonomy` and `kaizen_series`** — prose in
  comments included. Each program is ONE single-quoted shell string; a stray `'` ends it mid-jq and
  `bash -n` reports the error dozens of lines away. Say "this repo rows", never "this repo's rows".
- **`printf … | grep -q` is forbidden** (rc 141 under pipefail when grep finds a match early); use
  herestrings. `grep -m<N>` without `-q` at the end of a pipe is the same family — the sensors below
  keep `grep -m1` as the writer (herestring input), never as a reader of a pipe.
- **Sensor first, red before green.** Every assertion is written and run red before the code that
  turns it green. A mutant proves first that it sabotaged what it says (`cmp` in `run_mutant`
  answers rc 90 when the anchor no longer matches). Anchors are CODE, `sed` with `@` as delimiter
  when the line carries `|`.
- **Contract in three places, same commit:** a change to what a reader prints or the series
  carries lands with `docs/pipeline.md`, the agent that reads it and the template it names, in the
  commit that changes the code — except that the doc files outside the stamp key are batched in
  Task 8 so `sdd health --with-mutation` (Task 7) runs after the last code commit and stays valid.
  The stamp key is the CONTENT of `bin/ tests/ templates/ config/`; `agents/`, `docs/`,
  `CONTEXT.md`, `KAIZEN_LOG.md`, `TODO.md` do not invalidate it; `tests/health-baseline.txt` does.
- **Nothing new in the row.** No new ledger field, no migration, `v: 1`. `moved_rate`, `labels`
  (three keys), `escalations`, `guard`, `composition`, `excluded` keep their shape.
- **Raw ledger captures never enter git** — they carry client repo paths. They live under
  `~/.sdd/measure/2026-08-28-instrumento-honesto/`.
- **The agent mirror is synced by `sdd install --force`**, never by `cp` or an edit to
  `.claude/agents/`.

---

## File map

| File | Responsibility in this mission |
|---|---|
| `bin/sdd` | `ledger_outcome_defs()` (new, beside `ledger_row_is_local`, :1712); `cmd_autonomy` (:4081) — tri-state lines, `waste`, `launches`, `reopened`, population, notes cell, help text (:5101); `kaizen_series` (:4428) — splice, `outcomes`, `advance_rate`, `phase_label` |
| `tests/check-autonomy.sh` | 5.1–5.8: new fixtures `tristate`, `launches`, `reopen_pass`/`reopen_fail`, `population`/`populationclean`; the `50% waste` assertion (:1391) changes number; by-mission assertions (:1722) learn the new cell |
| `tests/check-kaizen.sh` | 5.9–5.12: the main series fixture (:128) grows two `m6` rows; `outcomes`, `advance_rate`, the `leve` churn clause, the labels literal (:165) |
| `tests/check-mutation.sh` | seven mutants (`CATALOG=(` at :2052, functions appended before it) |
| `tests/health-baseline.txt` | `todo-findings 77 → 78` |
| `TODO.md` | the `sdd close` finding (§10) |
| `templates/checkpoint.md` | :44–47 — the `- intervention:` note is narrative, not the count |
| `docs/pipeline.md` | :594 (`moved` row), :619–632 (`--by-mission`), :648–661 (the series and the rubric) |
| `agents/sdd-kaizen.md` + `.claude/agents/sdd-kaizen.md` | :41 and :106 — headline is `outcomes`/`advance_rate`; the D16 reading |
| `README.md` | :61–62 |
| `docs/failure-modes.md` | :81 |
| `CONTEXT.md` | D16 amended (:50), **Churn** glossary entry, *Série* entry |
| `KAIZEN_LOG.md` | the entry, before/after |
| `docs/superpowers/specs/2026-08-28-instrumento-honesto-handoff.md` | the handoff |

Line numbers are from `feat/instrumento-honesto` at `d763098`. They shift as tasks land; anchor on
the quoted code, not the number.

---

### Task 0: Measure the BEFORE (nothing is committed)

**Files:** none in the repo. Writes `~/.sdd/measure/2026-08-28-instrumento-honesto/before-*.txt`.

The KAIZEN_LOG entry (Task 9) needs both sides, and the "before" can only be captured before any
edit. Spec §8 fixed the headline numbers on 2026-08-28; this step re-captures them so the entry
cites what THIS tree printed.

- [ ] **Step 1: Confirm the tree and the branch**

Run:
```bash
cd /home/joruge/repos/sdd_agents && git status --short && git log --oneline -1 && git branch --show-current
```
Expected: clean tree, `d763098 docs(spec): …`, `feat/instrumento-honesto`.

- [ ] **Step 2: Capture the three ledger readings**

```bash
MEASURE="$HOME/.sdd/measure/2026-08-28-instrumento-honesto"; mkdir -p "$MEASURE"
./bin/sdd autonomy --all-repos               > "$MEASURE/before-autonomy.txt" 2>&1
./bin/sdd autonomy --all-repos --by-mission  > "$MEASURE/before-by-mission.txt" 2>&1
./bin/sdd kaizen --series                    > "$MEASURE/before-series.json" 2>/dev/null
grep -c 'stalled' "$MEASURE/before-autonomy.txt"; grep 'condicoes-pagamento' "$MEASURE/before-by-mission.txt"
```
Expected: the by-mission line for `condicoes-pagamento` reads `6 session(s) · 0 stalled ·
? intervention(s) · US$ 68.87` (spec §8). Sum of `stalled` over the version table is 13.

- [ ] **Step 3: Capture the suite numbers**

```bash
./tests/run-all.sh 2>&1 | tee "$MEASURE/before-suite.txt" | tail -3
grep -cE '^  ok    ' "$MEASURE/before-suite.txt"
./tests/check-autonomy.sh 2>&1 | grep -cE '^  ok    '
./tests/check-kaizen.sh   2>&1 | grep -cE '^  ok    '
./tests/check-todo.sh     2>&1 | grep -E '^  ok    [0-9]+ finding'
grep -cE '^  [A-Za-z0-9_]+$' <(sed -n '/^CATALOG=(/,/^)/p' tests/check-mutation.sh)
```
Expected: suite green; `637` ok lines in the suite (measured while writing this plan); `77
finding(s)`; catalogue `166` slugs. Write the four numbers into `$MEASURE/before-counts.txt`.

---

### Task 1: The `sdd close` finding enters the backlog, and the ratchet moves with an author

**Files:**
- Modify: `TODO.md` (end of the `## Aberto` section — the file has that one section)
- Modify: `tests/health-baseline.txt:…` (`todo-findings 77`)

Spec §9 puts this FIRST because `tests/health-baseline.txt` is inside the mutation-stamp key: doing
it after Task 7 would invalidate the stamp and cost a second catalogue run.

- [ ] **Step 1: Write the finding, in the file's own format (≤ 8 lines, anchor, date)**

Append to the end of `TODO.md`:

```md
- [ ] **`sdd close` abre sessão e não escreve linha no ledger** — `bin/sdd:5278` — o
  `docs/pipeline.md` promete "uma linha JSON por sessão gasta ou escalada" e esta sessão não tem
  linha: `grep -n 'autonomy_.*_row' bin/sdd` não devolve nada dentro de `cmd_close`. Fail-open pela
  régua D15, com consumidor fora da suíte (o juiz e a D12). Direção: `cmd_close` passa por
  `run_phase` ou escreve a linha com `invocation: close`, e o enum de `invocation` no `pipeline.md`
  aprende o valor no mesmo commit — o mesmo contrato de cauda aberta que `kind` carrega.
  — descoberto por `humano` na missão `20260828-instrumento-honesto` (2026-08-28)
```

- [ ] **Step 2: Run the backlog sensor — it must count 78**

Run: `./tests/check-todo.sh 2>&1 | grep -E 'finding|FAIL'`
Expected: `  ok    78 finding(s), all within 8 lines and carrying anchor + date`. If it says 77 the
item was not parsed (check the leading `- [ ] **`, the backticked anchor and the `(2026-08-28)`).

- [ ] **Step 3: Move the ratchet**

In `tests/health-baseline.txt`, change the last line `todo-findings 77` to `todo-findings 78`.

- [ ] **Step 4: Prove the ratchet closes in both directions**

⚠️ `sdd health` takes no flag and ALWAYS runs the mutation catalogue (`cmd_health` calls
`tests/run-all.sh --with-mutation` unconditionally — measured during execution: the "quick check"
this step first asked for spawned 166 sandboxes and had to be killed). The ratchet is exercised
once, in Task 7. Here the property is proved by its two halves agreeing:

Run: `./tests/check-todo.sh 2>&1 | grep -oE '[0-9]+ finding'; grep '^todo-findings' tests/health-baseline.txt`
Expected: `78 finding` and `todo-findings 78` — the two numbers `health_ratchet` compares.

- [ ] **Step 5: Commit**

```bash
git add TODO.md tests/health-baseline.txt
git commit -m "docs(todo): sdd close abre sessão e não escreve linha no ledger" -m "A catraca sobe 77 → 78 com autor. O achado é fail-open pela régua D15: o pipeline.md promete uma linha por sessão e o cmd_close abre sessão sem passar por run_phase nem por autonomy_session_row. Registrado, não consertado — a missão é o instrumento, não o escritor."
```

---

### Task 2: One definition of "what the session did", spliced into BOTH readers, with parity measured

**Files:**
- Modify: `bin/sdd` — new `ledger_outcome_defs()` right after `ledger_row_is_local()` (:1733);
  `cmd_autonomy` (:4119 `local def`, :4230–4231 the jq invocation, :4324 and :4340 `$stalled`,
  :4331 and :4343 the two lines); `kaizen_series` (:4460 the jq invocation, :4581–4640
  `group_summary`)
- Test: `tests/check-autonomy.sh` (new block after :1403), `tests/check-kaizen.sh` (:128 fixture,
  :164–169)
- Modify: `tests/check-mutation.sh` (two mutants + `CATALOG`)

**Interfaces:**
- Produces `ledger_outcome_defs()` → prints three jq defs: `outcome` (`"advanced"|"churned"|"idle"`
  on a session row), `outcome_tally` (array of session rows → `{advanced, churned, idle}`),
  `phase_index` (phase string → integer index in `$phases`, `null` outside). Both readers pass
  `--arg phases "$PHASES"` and splice `"$(ledger_outcome_defs)"` immediately after
  `"$(ledger_row_is_local)"` / `"$def"` with NO space between the two strings.
- Produces in the series: `latest.outcomes`, `latest.advance_rate` (and `previous.*`), and
  `detail[].outcomes`.
- Produces in `sdd autonomy`: version line `<sha>  N session(s) · A advanced · C churned · I idle ·
  W% waste · M mission(s) · US$ X`; mission line `<label>  N session(s) · A advanced · C churned ·
  I idle · <iv> · US$ X` (`<iv>` unchanged in this task; Task 5 and 6 reshape it).

> Deviation from spec §4.1, stated: the emission carries a third def, `outcome_tally`. Its three
> keys ARE the enum, and an enum read in more than one place is one definition (CLAUDE.md, runner
> section). It changes nothing the spec measures — the mutant `KAIZEN_outcome_inlined_old` replaces
> the whole splice with local copies of `outcome` AND `outcome_tally`, so the tally binding follows
> the local `outcome` (jq binds lexically at definition time; a shadowing `def outcome` placed after
> a shared `outcome_tally` would NOT reach it — that is why the mutant replaces the splice rather
> than shadowing).

> Measured while planning, contrary to spec §4.1: on jq 1.7 `jq -n 'def f: $x; 1'` prints `1` — an
> unbound variable inside an uncalled def COMPILES. Both readers still pass `--arg phases`, but the
> comment says what was measured, not "dies with `$phases is not defined`".

- [ ] **Step 1: Write the failing assertions — `tests/check-autonomy.sh`**

Insert right after the line
`assert_bucket_sum "the four buckets sum to the header total (mixed ledger)" "$out"` (:1403),
before `# --- the reader gives a full accounting, never a silent gap`:

```bash
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
EOF
out_tri="$( SDD_STATE_DIR="$OUTSIDE/tristate" "$SDD" autonomy 2>&1 )"; rc=$?
assert_eq "a ledger of three outcomes is data (rc 0)" "0" "$rc"
# 6 comparable sessions: the gate passed on 3 (advanced), 2 wrote and still failed (churned), 1
# wrote nothing and failed (idle). The dirty row and the escalation are the other two buckets.
assert_eq "the version line says what the sessions did, in the order advanced · churned · idle" "1" \
  "$(grep -cE '^  ddddddd  6 session\(s\) · 3 advanced · 2 churned · 1 idle · ' <<< "$out_tri")"
assert_eq "and the word stalled is gone — idle is the same number under the name that says what it is" "0" \
  "$(grep -c 'stalled' <<< "$out_tri")"
assert_bucket_sum "the four buckets still sum to the header total (three outcomes)" "$out_tri"

# PARITY, measured and never asserted in prose. The judge series reads the SAME file through its
# own jq program, and both programs splice ONE printed definition. A program that stopped splicing
# it and grew a local copy on the old yardstick (mut_KAIZEN_outcome_inlined_old) stays internally
# consistent — only the comparison between the two catches it, which is why this is not a
# constant on the right-hand side.
series_tri="$( SDD_STATE_DIR="$OUTSIDE/tristate" "$SDD" kaizen --series 2>/dev/null )"
table_tri="$(sed -nE 's/^  ddddddd  [0-9]+ session\(s\) · ([0-9]+) advanced · ([0-9]+) churned · ([0-9]+) idle · .*/\1 \2 \3/p' <<< "$out_tri")"
assert_eq "the human window and the judge count the outcomes of the latest version alike" \
  "$(jq -r '.latest.outcomes | "\(.advanced) \(.churned) \(.idle)"' <<< "$series_tri")" "$table_tri"
# ...and not by both being empty: the floor is the known histogram of this fixture.
assert_eq "the parity is not vacuous — the table printed the three counts" "3 2 1" "$table_tri"
```

- [ ] **Step 2: Write the failing assertions — `tests/check-kaizen.sh`**

(a) Append two rows to the main fixture heredoc (:128–142), after the KAIZEN row (`"run_id":"r8"`)
and before `EOF`. They are one phase that wrote, failed, then passed inside one run — the churn
shape that Task 4 turns from `ok` into `leve`:

```
{"v":1,"ts":"2026-08-15T10:12:00-03:00","event":"session","run_id":"r9","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s9","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"fail","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:13:00-03:00","event":"session","run_id":"r9","invocation":"run","kit_sha":"fff9999","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m6","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":2,"auto_retry":false,"session":"s10","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
```

Update the fixture's comment (:125–127) to add: `m6/EXEC churn (fail/true then pass/true, one
run, no retry, no escalation — ok under the old rubric, leve since Task 4)`.

(b) The previous group now has 7 sessions (was 5). Change the two literals that count them:

```bash
assert_eq "the label tally sums the detail" \
  '{"ok":1,"leve":1,"refez":2}' "$(jq -c '.previous.labels' <<< "$SERIES_OUT")"
```
(`ok` is 1 here because m6 reads `ok` until Task 4; Task 4 changes it to `{"ok":0,"leve":2,"refez":2}`.)

```bash
# 6 of the 7 sessions of the previous version wrote to the disk (s1 is the one that did not).
assert_eq "moved_rate is computed over the group's sessions" "0.86" \
  "$(field '.previous.moved_rate')"
```

(c) Insert right after that `moved_rate` assertion:

```bash
# What the sessions DID — the headline since 20260828-instrumento-honesto. Over the previous
# version: s1 wrote nothing and failed (idle); s2 and the first m6 session wrote and failed
# (churned); the other four passed their gate (advanced). All three counts differ, so no two
# swapped fields agree by coincidence.
assert_eq "outcomes over the previous version: advanced · churned · idle" \
  '{"advanced":4,"churned":2,"idle":1}' "$(jq -c '.previous.outcomes' <<< "$SERIES_OUT")"
assert_eq "and over the latest, a single clean pass" \
  '{"advanced":1,"churned":0,"idle":0}' "$(jq -c '.latest.outcomes' <<< "$SERIES_OUT")"
assert_eq "each phase of the detail carries its own outcomes" \
  '{"advanced":1,"churned":1,"idle":0}' \
  "$(jq -c '.previous.detail[] | select(.mission == "m1" and .phase == "REVIEW") | .outcomes' <<< "$SERIES_OUT")"
# advance_rate reads the gate, moved_rate reads the disk: 4 of 7 passed, 6 of 7 wrote. Asserted on
# ONE line, on a fixture where the two numbers DIFFER, so a series that derived one from the other
# cannot pass.
assert_eq "advance_rate reads the gate and moved_rate reads the disk, and here they differ" \
  "0.57 0.86" "$(jq -r '"\(.previous.advance_rate) \(.previous.moved_rate)"' <<< "$SERIES_OUT")"
```

- [ ] **Step 3: Run both sensors — expect red on the new lines and on `moved_rate`**

Run: `./tests/check-autonomy.sh 2>&1 | grep -A2 'FAIL' | head -30; ./tests/check-kaizen.sh 2>&1 | grep -A2 'FAIL' | head -30`
Expected: check-autonomy fails "the version line says what the sessions did…" (got 0), "stalled
is gone" (got 1), the parity line (series prints `null null null`) and its floor; check-kaizen
fails the three `outcomes` lines (got `null`), the `advance_rate` line (`null 0.86`) — and
`moved_rate 0.86` PASSES already (the fixture grew, the code did not change). The labels literal
`{"ok":1,…}` passes too.

- [ ] **Step 4: `bin/sdd` — the emitted definition**

Insert after the closing `}` of `ledger_row_is_local()` (:1733), before the comment `# Publishes
AUTONOMY_KIT_STAMP`:

```bash
# ONE definition of "what did this session DO", spliced into both readers of the ledger the same
# way ledger_row_is_local is — printed jq, received through `"$(ledger_outcome_defs)"`, never
# spelled twice. `stalled` used to be `moved == false` ("the session wrote nothing"), which is not
# "the phase did not advance": 68 of the 145 sessions in the real ledger wrote something, failed
# their gate and bought the runner another session, and no reader could see them — the human
# window said `0 stalled`, the judge said `ok`, on a phase of seven sessions and five refusals
# (20260825-frete-cif-fob, EXEC). Measured 2026-08-28, before this function existed.
#
#   advanced — the gate passed. The gate is the artifact; `pass/false` does not occur in the
#              ledger and is classified here without a fourth arm.
#   churned  — the session wrote to the disk and the gate still failed: the runner reads "moved"
#              as progress and buys the next lap. The bucket that was invisible.
#   idle     — nothing on disk, gate failed: the old `stalled`, under the name that says what it is.
#
# Applied to the sessions each reader already admits — `comparable` in cmd_autonomy (which demands
# `has("moved")`), the on_axis sessions in kaizen_series — never to escalation rows, which carry
# neither field and would all read `idle`. Old-schema rows stay where they were.
# `outcome_tally` lives here and not in each program because its three keys ARE the enum, and an
# enum read in more than one place is one definition.
#
# `phase_index` reads the canonical phase order off $PHASES through `--arg phases`, so the order
# has ONE owner. Both readers pass `--arg phases "$PHASES"` even though only cmd_autonomy calls
# phase_index. Measured on jq 1.7: an unbound `$var` inside a def nobody calls COMPILES (`jq -n
# 'def f: $x; 1'` prints 1), so the arg is not strictly required there today — it is passed anyway
# because the emission is one and the day the series calls phase_index must not be the day it
# learns about the arg. (No apostrophe inside the printed jq: it is spliced into single-quoted
# shell strings.)
ledger_outcome_defs() {   # printed jq, spliced into cmd_autonomy AND kaizen_series
  printf '%s' 'def outcome: if .gate == "pass" then "advanced" elif .moved == true then "churned" else "idle" end;'
  printf '%s' 'def outcome_tally: map(outcome) | reduce .[] as $o ({advanced: 0, churned: 0, idle: 0}; .[$o] += 1);'
  printf '%s' 'def phase_index: . as $p | ($phases | split(" ")) | index($p);'
}
```

- [ ] **Step 5: `bin/sdd` — `cmd_autonomy` splices it and prints the three outcomes**

(a) After `local def; def="$(ledger_row_is_local)"` (:4119) add:
```bash
  local odefs; odefs="$(ledger_outcome_defs)"
```

(b) The jq invocation (:4230–4231) becomes — note `"$def""$odefs"'` with no space, the three are
ONE argument:
```bash
  out="$(jq -rs --arg repo "$repo" --argjson interventions "$interventions" \
                --argjson by_mission "$by_mission" --arg allrepos "$LEDGER_ALL_REPOS" \
                --arg phases "$PHASES" "$def""$odefs"'
```

(c) In the by-mission branch replace
`| (map(select(.moved == false)) | length) as $stalled` with
`| (outcome_tally) as $t`
and the line
```
              | "  \($label)  \($n) session(s) · \($stalled) stalled · \($iv) · US$ \($cost | usd)"
```
with
```
              | "  \($label)  \($n) session(s) · \($t.advanced) advanced · \($t.churned) churned · \($t.idle) idle · \($iv) · US$ \($cost | usd)"
```

(d) In the version branch replace
`| (map(select(.moved == false)) | length) as $stalled` with
`| (outcome_tally) as $t`
and the line
```
            | "  \($sha)  \($n) session(s) · \($stalled) stalled · \(($stalled * 100 / $n) | floor)% waste · \($missions) mission(s) · US$ \($cost | usd)"
```
with (waste still on the OLD yardstick here — Task 3 moves it, red first):
```
            | "  \($sha)  \($n) session(s) · \($t.advanced) advanced · \($t.churned) churned · \($t.idle) idle · \(($t.idle * 100 / $n) | floor)% waste · \($missions) mission(s) · US$ \($cost | usd)"
```

(e) Add, above `def on_axis:` inside the jq program (:4249), the comment (no apostrophes):
```
    # outcome / outcome_tally / phase_index arrive spliced from ledger_outcome_defs: what a session
    # DID is one definition for this program and for kaizen_series, and check-autonomy.sh compares
    # the two histograms over one file so neither can be improved alone.
```

- [ ] **Step 6: `bin/sdd` — `kaizen_series` splices it and publishes `outcomes` + `advance_rate`**

(a) The jq invocation (:4460) becomes (again, no space between the two `"$( )"`):
```bash
  jq -n --arg repo "$repo" --argjson floor "$KAIZEN_GUARD_FLOOR" --arg phases "$PHASES" "$(ledger_row_is_local)""$(ledger_outcome_defs)"'
```

(b) In `group_summary`, the `$detail` map gains `outcomes` — filtered to sessions FIRST, because
`outcome` on a `blocked` row (no `gate`, no `moved`) would answer `idle`:
```
               | map({repo: .[0].repo, mission: .[0].mission, phase: .[0].phase, label: phase_label,
                      sessions: (map(select(.event == "session")) | length),
                      outcomes: (map(select(.event == "session")) | outcome_tally),
                      cost_usd: (map(.cost_usd // 0) | add)})) as $detail
```

(c) In the group object, insert between `sessions: ($sess | length),` and `moved_rate:`:
```
         # What the sessions DID, and how often the gate passed — the headline since
         # 20260828-instrumento-honesto (the judge prompt cites these two before moved_rate).
         # moved_rate stays: its name says what it measures, and it has a consumer. Same yardstick
         # as the human window BY CONSTRUCTION: both programs splice ledger_outcome_defs, and
         # check-autonomy.sh compares the two histograms over one file, so a program that grew a
         # local copy of the definition is caught by the comparison and not by a sentence here.
         outcomes: ($sess | outcome_tally),
         advance_rate: (if ($sess | length) == 0 then null
                        else (($sess | map(select(.gate == "pass")) | length) / ($sess | length) * 100 | round / 100) end),
```

- [ ] **Step 7: Syntax, then both sensors green**

Run: `bash -n bin/sdd && ./tests/check-autonomy.sh 2>&1 | tail -3 && ./tests/check-kaizen.sh 2>&1 | tail -3`
Expected: both end in their `ok` summary line with rc 0. If jq dies with `phases is not defined`
or `outcome_tally/0 is not defined`, the splice has a space in it or is on the wrong side of `'`.

- [ ] **Step 8: The two mutants**

In `tests/check-mutation.sh`, insert immediately BEFORE the line `CATALOG=(` (:2052):

```bash
# ---------------------------------------------------------------------------
# 20260828-instrumento-honesto — what a session DID, one definition in two readers.
# ---------------------------------------------------------------------------
# The shared definition falls back to the OLD yardstick under the new names: `moved` alone decides,
# and a session that wrote and failed its gate reads `advanced`. Both readers inherit it, so the
# parity assertion stays green — which is exactly why check-autonomy.sh also pins the histogram of
# a known fixture: `churned` has to come out 2 there, and this reads 0.
mut_AUTONOMY_outcome_reads_moved_only() {
  sed -i 's@def outcome: if .gate == "pass" then "advanced" elif .moved == true then "churned" else "idle" end;@def outcome: if .moved == true then "advanced" else "idle" end;@' "$1"
}

# The series stops splicing the shared definition and grows a LOCAL copy on the old yardstick —
# the "same spelling in both programs" that CLAUDE.md measures as not-parity. Each reader is then
# internally consistent and only the comparison between the two goes red (5.7), plus the exact
# histogram of the series fixture (5.9). The copy carries outcome_tally too, because the splice it
# replaces carried it: a mutant that dropped the tally would kill the suite with a jq compile error
# instead of with the divergence it exists to reproduce. Held in a variable so the single quotes
# it needs can sit inside a double-quoted sed script; the result is `"$(ledger_row_is_local)"'def
# outcome: …;''` followed by the program — two adjacent single-quoted strings, one argument.
mut_KAIZEN_outcome_inlined_old() {
  local copy="'def outcome: if .moved == true then \"advanced\" else \"idle\" end; def outcome_tally: map(outcome) | reduce .[] as \$o ({advanced: 0, churned: 0, idle: 0}; .[\$o] += 1);'"
  sed -i "/^kaizen_series() {/,/^}/ { s@\"\\\$(ledger_outcome_defs)\"@${copy}@ }" "$1"
}
```

Append to the end of the `CATALOG=(` list (after `RUN_kit_guard_arms_projection`):
```
  AUTONOMY_outcome_reads_moved_only
  KAIZEN_outcome_inlined_old
```

- [ ] **Step 9: Prove each mutant applies AND is caught, without running the whole catalogue**

The catalogue takes minutes; one mutant is verified by hand with this helper (paste into the shell,
it is not committed):

```bash
mut_verify() { # mut_verify <slug> <sensor-file>  — applies the mutant to a copy, runs ONE sensor
  local box; box="$(mktemp -d)"
  cp -r bin tests templates config agents CLAUDE.md TODO.md "$box/"; mkdir -p "$box/docs"; cp -r docs/adr "$box/docs/"
  ( source <(sed -n "/^mut_$1() {/,/^}/p" tests/check-mutation.sh); "mut_$1" "$box/bin/sdd" )
  cmp -s bin/sdd "$box/bin/sdd" && { echo "$1: DID NOT APPLY (rc 90 in the catalogue)"; return 90; }
  bash -n "$box/bin/sdd" || { echo "$1: not valid bash (rc 91)"; return 91; }
  if SDD_MUTANT=1 "$box/tests/$2" >/dev/null 2>&1; then echo "$1: SURVIVED — not caught"; return 1; fi
  echo "$1: caught by $2"
}
mut_verify AUTONOMY_outcome_reads_moved_only check-autonomy.sh
mut_verify KAIZEN_outcome_inlined_old        check-autonomy.sh
mut_verify KAIZEN_outcome_inlined_old        check-kaizen.sh
```
Expected: three `caught` lines. `AUTONOMY_outcome_reads_moved_only` is caught by the histogram
line (`5 advanced · 0 churned`), NOT by the parity line — confirm by reading the FAIL:
`SDD_MUTANT=1 <box>/tests/check-autonomy.sh 2>&1 | grep -A2 FAIL`. Red for the right reason.

- [ ] **Step 10: The whole suite, then commit**

Run: `./tests/run-all.sh 2>&1 | tail -3`
Expected: green.

```bash
git add bin/sdd tests/check-autonomy.sh tests/check-kaizen.sh tests/check-mutation.sh
git commit -m "feat(ledger): o resultado da sessão vira tri-estado, uma definição costurada nos dois leitores" -m "advanced · churned · idle a partir de gate + moved, campos que as 145 linhas já têm. stalled era moved == false — 'não escreveu nada', não 'a fase não avançou' —, e 68 sessões que escreveram, reprovaram e compraram outra sessão eram invisíveis nos dois leitores. ledger_outcome_defs imprime a definição uma vez; cmd_autonomy e kaizen_series a costuram, e a paridade é asserção diferencial (check-autonomy.sh), nunca a mesma grafia em dois lugares. A série ganha outcomes e advance_rate por grupo e por fase. waste ainda lê só idle aqui; muda de régua no próximo commit, vermelho antes. Mutantes: AUTONOMY_outcome_reads_moved_only, KAIZEN_outcome_inlined_old."
```

---

### Task 3: `waste` changes yardstick — churned + idle

**Files:**
- Modify: `bin/sdd` (the version line written in Task 2, Step 5d)
- Test: `tests/check-autonomy.sh` (:1390–1392 and the `tristate` block)
- Modify: `tests/check-mutation.sh` (one mutant + `CATALOG`)

`waste` always meant "a session that did not make the phase advance"; what existed was the
approximation `moved == false`. Spec §4.2.

- [ ] **Step 1: The differential assertion (5.2) and the moved number (spec §5, last paragraph)**

In the `tristate` block, right after `assert_bucket_sum "… (three outcomes)" "$out_tri"`, insert:

```bash
# waste changed yardstick on 2026-08-28: churned + idle over the comparable sessions, floored. The
# old yardstick (idle alone, then called stalled) is 1/6 = 16% on this fixture; the new one is
# 3/6 = 50%. The line has to carry the second AND NOT the first — a differential on one fixture,
# so no regime satisfies it by accident. The two sides of the change are in KAIZEN_LOG.md.
assert_eq "waste counts churned and idle, not idle alone" "1 0" \
  "$(grep -c ' 50% waste ' <<< "$out_tri") $(grep -c ' 16% waste ' <<< "$out_tri")"
```

In the `== reader ==` block replace (:1390–1392):
```bash
# 2 comparable sessions (rows 1 and 2), 1 of them stalled => 50%.
assert_eq "waste is computed over comparable sessions only" "1" \
  "$(grep -c '50% waste' <<< "$out")"
```
with:
```bash
# 2 comparable sessions (rows 1 and 2): row 1 wrote and failed its gate (churned), row 2 wrote
# nothing (idle) — neither made the phase advance, so waste is 100%. This read 50% while waste was
# the approximation `moved == false`; the yardstick moved on 2026-08-28 (KAIZEN_LOG.md).
assert_eq "waste is computed over comparable sessions only" "1" \
  "$(grep -c '100% waste' <<< "$out")"
```

- [ ] **Step 2: Run red**

Run: `./tests/check-autonomy.sh 2>&1 | grep -A2 FAIL`
Expected: exactly the two assertions above fail (`1 0` got `0 1`; `100% waste` got 0).

- [ ] **Step 3: Move the yardstick**

In the version line of `cmd_autonomy`, replace `\(($t.idle * 100 / $n) | floor)% waste` with
`\((($t.churned + $t.idle) * 100 / $n) | floor)% waste`.

Above the `$groups | map(` of the version branch add (no apostrophes):
```
        # waste = churned + idle: every session that did not make the phase advance. It was idle
        # alone (then called stalled) until 2026-08-28 — the approximation the name never meant.
```

- [ ] **Step 4: Run green**

Run: `./tests/check-autonomy.sh 2>&1 | tail -2`
Expected: rc 0.

- [ ] **Step 5: The mutant**

Before `CATALOG=(`, after `mut_KAIZEN_outcome_inlined_old`:
```bash
# waste goes back to counting idle alone — the old approximation under the new name, and the
# window prints 16% on a fixture whose churn is a third of its sessions.
mut_AUTONOMY_waste_idle_only() {
  sed -i 's@((\$t\.churned + \$t\.idle) \* 100 / \$n)@($t.idle * 100 / $n)@' "$1"
}
```
Add `  AUTONOMY_waste_idle_only` to the end of `CATALOG=(`.

Run: `mut_verify AUTONOMY_waste_idle_only check-autonomy.sh` → `caught`.

- [ ] **Step 6: Commit**

```bash
git add bin/sdd tests/check-autonomy.sh tests/check-mutation.sh
git commit -m "feat(autonomy): waste passa a contar churned + idle" -m "waste sempre quis dizer 'sessão que não fez a fase avançar'; o que existia era a aproximação moved == false. O fixture do leitor sobe de 50% para 100% pelo motivo certo: a sessão que escreveu e reprovou também não avançou. Asserção diferencial na mesma tabela (50% presente, 16% ausente). Mutante: AUTONOMY_waste_idle_only."
```

---

### Task 4: The rubric reads churn — any `gate == fail` session is at least `leve`

**Files:**
- Modify: `bin/sdd` — `phase_label` (:4571–4579) and the rubric comment (:4416–4419)
- Test: `tests/check-kaizen.sh` (:164–165 labels literal; new assertions)
- Modify: `tests/check-mutation.sh` (one mutant + `CATALOG`)

Spec §4.3. `frete-cif-fob` EXEC: 7 sessions, 5 refusals, each committing something, no auto retry,
the phase "ended up passing" — the judge read `ok`.

- [ ] **Step 1: The failing assertions (5.11, 5.12)**

In `tests/check-kaizen.sh`, right after the `advance_rate` assertion added in Task 2, insert:

```bash
# The churn clause of the rubric. A phase whose gate failed and then passed inside ONE run, with
# no auto retry, no human retry and no escalation, used to read `ok` — frete-cif-fob EXEC, seven
# sessions and five refusals, read `ok` to the judge. Any session of the phase with gate == fail is
# at least `leve` now; `refez` does not change. Control beside it, on the same series: a phase that
# passed on its first session still reads `ok`, so the clause is not "everything is leve".
assert_eq "a phase that wrote, failed its gate and then passed reads leve, never ok" \
  "leve" "$(field '.previous.detail[] | select(.mission == "m6" and .phase == "EXEC") | .label')"
assert_eq "control: a single clean pass still reads ok" \
  "ok" "$(field '.latest.detail[] | select(.mission == "m3") | .label')"
```

Change the labels literal (:164–165) from `'{"ok":1,"leve":1,"refez":2}'` to
`'{"ok":0,"leve":2,"refez":2}'` — the key set is unchanged, only the numbers move (5.12).

- [ ] **Step 2: Run red**

Run: `./tests/check-kaizen.sh 2>&1 | grep -A2 FAIL`
Expected: "a phase that wrote, failed…" (got `ok`) and "the label tally sums the detail" (got
`{"ok":1,…}`). The three `refez` assertions and the control pass.

- [ ] **Step 3: The clause**

In `kaizen_series`, `phase_label`: replace
```
      elif (map(select(.event == "session" and (.auto_retry == true or .moved == false))) | length) > 0
```
with
```
      elif (map(select(.event == "session" and (.auto_retry == true or .moved == false or .gate == "fail"))) | length) > 0
```

And the rubric comment above `kaizen_series` (:4416–4419) becomes:
```
#   refez — any escalation, any human retry invocation, or the phase's last session still failing
#           its gate: the work was pushed again, the strongest friction signal there is.
#   leve  — an in-loop auto retry, a session that did not move the disk, or ANY session of the
#           phase that failed its gate (churn: it wrote, the gate refused, the runner bought the
#           next lap — frete-cif-fob EXEC was seven sessions, five refusals, and read `ok` until
#           2026-08-28): friction, absorbed.
#   ok    — none of the above.
```

- [ ] **Step 4: Run green**

Run: `bash -n bin/sdd && ./tests/check-kaizen.sh 2>&1 | tail -2`
Expected: rc 0.

- [ ] **Step 5: The mutant**

Before `CATALOG=(`:
```bash
# The rubric loses the churn clause: a phase of seven sessions and five refusals that ended up
# passing reads `ok` to the judge again. Caught by the m6 group of the series fixture and by the
# labels literal beside it.
mut_KAIZEN_churn_reads_ok() {
  sed -i 's@(.auto_retry == true or .moved == false or .gate == "fail")@(.auto_retry == true or .moved == false)@' "$1"
}
```
Add `  KAIZEN_churn_reads_ok` to the end of `CATALOG=(`.

Run: `mut_verify KAIZEN_churn_reads_ok check-kaizen.sh` → `caught`.

- [ ] **Step 6: Commit**

```bash
git add bin/sdd tests/check-kaizen.sh tests/check-mutation.sh
git commit -m "feat(kaizen): qualquer sessão da fase com gate reprovado lê ao menos leve" -m "Uma cláusula na rubrica: churn (escreveu, reprovou, o runner comprou a volta) deixa de ler ok. O EXEC de frete-cif-fob — 7 sessões, 5 reprovações — sai de ok para leve; refez não muda; três rótulos, não quatro (a magnitude mora em outcomes). Não é emenda da ADR 0001: é o caso que ela desenhou — régua mecânica mudou, datada no histórico. Mutante: KAIZEN_churn_reads_ok."
```

---

### Task 5: `launch(es)` and `reopened` on the mission line, drawn over every session of the mission

**Files:**
- Modify: `bin/sdd` — `cmd_autonomy` jq program (defs after `def mission_key`, the `$mgroups`
  binding, the mission line, the accounting `$inside`)
- Test: `tests/check-autonomy.sh` — three new blocks after the by-mission block (after the line
  `rm -rf "$FIX/docs/handoffs/h1" "$FIX/docs/handoffs/h2" "$FIX/docs/handoffs/h3"`, :1758)
- Modify: `tests/check-mutation.sh` (three mutants + `CATALOG`)

**Interfaces:**
- Produces jq defs inside `cmd_autonomy`: `launches` (session rows → integer), `reopened` (session
  rows in file order → integer), `history_of` (a `mission_key` → every local session row of that
  mission, file order).
- Produces the mission line `<label>  N session(s) · A advanced · C churned · I idle · L launch(es)
  · R reopened · <iv> · US$ X` and the accounting sentence `(launches and reopened are counted over
  every session of the mission, N of them non-comparable)`.
- Consumes `phase_index` from Task 2 and the helper `mission_line()` defined at :1710 of the
  sensor.

Spec §4.4–4.5. The population decision is the one that "quase passou": SQ-111's post-PR QA row has
`kit_dirty: true`, so `reopened` over the comparable rows would read **0** exactly on the mission
that motivated the field.

- [ ] **Step 1: The failing assertions (5.3, 5.4, 5.5)**

Insert after `rm -rf "$FIX/docs/handoffs/h1" …` (:1758):

```bash
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
# comparable rows alone reopened read 0 exactly where it mattered. When the two populations differ
# the accounting paragraph says so, once. Differential: the same mission with the dirty row removed
# reads one launch, and the sentence is gone.
echo "== reader: --by-mission draws launches over every session of the mission =="
mkdir -p "$OUTSIDE/population" "$OUTSIDE/populationclean"
localize > "$OUTSIDE/population/autonomy-log.jsonl" <<'EOF'
{"v":1,"ts":"2026-08-15T10:00:00-03:00","event":"session","run_id":"r1","invocation":"run","kit_sha":"eeeeeee","kit_dirty":false,"project":"p1","repo":"/p1","mission":"m1","phase":"EXEC","step":"EXEC","agent":"sdd-executor","model":"opus","attempt":1,"auto_retry":false,"session":"s1","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
{"v":1,"ts":"2026-08-15T10:01:00-03:00","event":"session","run_id":"r2","invocation":"run","kit_sha":"eeeeeee","kit_dirty":true,"project":"p1","repo":"/p1","mission":"m1","phase":"QA","step":"QA:close","agent":"sdd-qa","model":"opus","attempt":1,"auto_retry":false,"session":"s2","rc":0,"dur_s":10,"cost_usd":1.0,"moved":true,"gate":"pass","gate_why":"x"}
EOF
grep -v '"kit_dirty":true' "$OUTSIDE/population/autonomy-log.jsonl" > "$OUTSIDE/populationclean/autonomy-log.jsonl"
out_pop="$(  SDD_STATE_DIR="$OUTSIDE/population"      "$SDD" autonomy --by-mission 2>&1 )"
out_popc="$( SDD_STATE_DIR="$OUTSIDE/populationclean" "$SDD" autonomy --by-mission 2>&1 )"
assert_eq "one comparable session, two launches: the launch on a dirty kit was a launch" "1 2" \
  "$(cell_of m1 "$out_pop" 'session') $(cell_of m1 "$out_pop" 'launch')"
assert_eq "and the accounting paragraph names the population difference, once" "1" \
  "$(grep -c '(launches and reopened are counted over every session of the mission, 1 of them non-comparable)' <<< "$out_pop")"
assert_eq "without the dirty row: one launch, and the sentence is gone" "1 0" \
  "$(cell_of m1 "$out_popc" 'launch') $(grep -c 'counted over every session' <<< "$out_popc")"
assert_bucket_sum "the four buckets still sum to the header total (--by-mission, a dirty launch)" "$out_pop"
```

- [ ] **Step 2: Run red**

Run: `./tests/check-autonomy.sh 2>&1 | grep -A2 FAIL | head -40`
Expected: every `launch`/`reopened`/sentence assertion fails with empty or `0` on the right; "the
twin differs…" and the bucket sum pass.

- [ ] **Step 3: `bin/sdd` — the two defs, the population, the line, the sentence**

(a) After `def mission_key: [(.repo // ""), (.mission // "")];` in `cmd_autonomy` (:4262), add
(no apostrophes — this is inside the jq string):
```
    # The number the D12 metric reads, since D16 was amended on 2026-08-28: distinct run_id — how
    # many times a human typed `sdd run` or `sdd retry` for this mission. The FACT, never
    # `launches - 1`: "interventions = launches - 1" is the reading, written in CONTEXT.md and in
    # the judge prompt, and a `- 1` here would be the first arithmetic of opinion inside an
    # instrument that prints facts — and would read 0 on a mission abandoned after its first
    # launch, which is an intervention. It UNDERCOUNTS by design: bringing the app up by hand
    # between two launches is one new run_id, not two. An honest floor, where the prose
    # (`- intervention:` notes) was a ceiling nobody filled — the mission with three launches
    # (SQ-111) had zero notes.
    def launches: map(.run_id) | unique | length;
    # A session in a phase BELOW one whose gate had already PASSED, in $PHASES order — the pipeline
    # going backwards after it had gone forward. NOT "the phase index went down": that counts the
    # designed loop (QA fails, opens a fix increment, EXEC runs it), which frete-cif-fob did three
    # times with QA REFUSED, all of it the pipeline working. With the gate in the clause that
    # mission reads 0 and SQ-111, which ran QA after PR had passed, reads 1. A phase outside the
    # order (KAIZEN) has a null index and counts on neither side — the `!= null` guards are
    # load-bearing, because jq orders null below every number. Input in file order, which is
    # write order: the ledger is append-only, and group_by keeps it (jq sorts stably).
    def reopened: reduce .[] as $r ({maxpass: -1, n: 0};
                    ($r.phase | phase_index) as $i
                    | (if $i != null and $i < .maxpass then .n += 1 else . end)
                    | (if $i != null and $r.gate == "pass" then .maxpass = ([.maxpass, $i] | max) else . end)) | .n;
```

(b) Right after the `$mgroups` binding (the `| (map(select(is_session and comparable)) |
group_by(mission_key) | sort_by(.[0].ts)) as $mgroups` line, :4313–4314), add:
```
    # EVERY local session of each mission, comparable or not — the population launches and
    # reopened are drawn over. They are facts about the human history of the mission and not about
    # a kit version: a launch that landed on a dirty kit was a launch. Measured on SQ-111, the
    # mission that motivated the two fields: its post-PR QA row carries kit_dirty:true, and over
    # the comparable rows alone `reopened` read 0 exactly there. session(s), the outcomes and US$
    # stay on the comparable rows, because that is the sum check-autonomy.sh closes against the
    # version table. When the two populations differ for a printed mission the accounting
    # paragraph says so, once, with the difference summed over the missions printed.
    | (map(select(is_session)) | group_by(mission_key)) as $every_session
    | def history_of: . as $k | $every_session | map(select((.[0] | mission_key) == $k)) | .[0] // [];
      (if $by_mission == 1
       then ($mgroups | map((.[0] | mission_key | history_of | length) - length) | add // 0)
       else 0 end) as $history_extra
```

(c) In the by-mission `map(`, after `| (outcome_tally) as $t` add:
```
              | (.[0] | mission_key | history_of) as $every
              | ($every | launches) as $launches
              | ($every | reopened) as $reopened
```
and the mission line becomes:
```
              | "  \($label)  \($n) session(s) · \($t.advanced) advanced · \($t.churned) churned · \($t.idle) idle · \($launches) launch(es) · \($reopened) reopened · \($iv) · US$ \($cost | usd)"
```

(d) In the accounting paragraph, the `$inside` array gains a third line after the `unrecognized`
one (it is `$inside`, not `$outside`: these rows WERE in the header total):
```
       , (if $history_extra > 0 then "  (launches and reopened are counted over every session of the mission, \($history_extra) of them non-comparable)" else empty end)
```
The sentence says "of them non-comparable" and never "N non-comparable": `assert_bucket_sum` reads
the first `[0-9]+ non-comparable` in the output, and that must keep being the exclusion line.

- [ ] **Step 4: Run green, then the by-mission block that already existed**

Run: `bash -n bin/sdd && ./tests/check-autonomy.sh 2>&1 | grep -E 'FAIL|autonomy check'`
Expected: no FAIL; the older `--by-mission prints one line per mission…` assertion still passes
(its regex `[0-9]+ intervention` still matches the untouched `<iv>` cell).

- [ ] **Step 5: The three mutants**

Before `CATALOG=(`:
```bash
# `unique` leaves `launches`: three rows of one run read as three launches, and the intervention
# count the D12 metric reads becomes a session count with a new name.
mut_AUTONOMY_launches_counts_rows() {
  sed -i 's@def launches: map(.run_id) | unique | length;@def launches: map(.run_id) | length;@' "$1"
}

# `reopened` advances its high-water mark on ANY session, passed or not — "the phase index went
# down", the definition the spec refused: frete-cif-fob (EXEC after a REFUSED QA, three times)
# would read 3 where the truth is 0. Caught by the fail twin of the reopen pair.
mut_AUTONOMY_reopened_ignores_gate() {
  sed -i 's@(if \$i != null and \$r.gate == "pass" then .maxpass@(if $i != null then .maxpass@' "$1"
}

# launches and reopened drawn over the COMPARABLE sessions of the mission instead of every local
# one: SQ-111, whose post-PR QA row is on a dirty kit, reads `2 launch(es) · 0 reopened` as
# `1 launch(es) · 0 reopened` — the population mistake that almost shipped. Caught by the
# population pair, whose comparable population is exactly one row.
mut_AUTONOMY_reopened_comparable_only() {
  sed -i 's@| (\.\[0\] | mission_key | history_of) as \$every$@| . as $every@' "$1"
}
```
Append to `CATALOG=(`:
```
  AUTONOMY_launches_counts_rows
  AUTONOMY_reopened_ignores_gate
  AUTONOMY_reopened_comparable_only
```

Run:
```bash
mut_verify AUTONOMY_launches_counts_rows     check-autonomy.sh
mut_verify AUTONOMY_reopened_ignores_gate    check-autonomy.sh
mut_verify AUTONOMY_reopened_comparable_only check-autonomy.sh
```
Expected: three `caught`. For the second, read the FAIL: it must be the `pass:1 fail:0` line
reading `fail:1`, not something else.

- [ ] **Step 6: Suite, commit**

Run: `./tests/run-all.sh 2>&1 | tail -3` → green.

```bash
git add bin/sdd tests/check-autonomy.sh tests/check-mutation.sh
git commit -m "feat(autonomy): --by-mission conta lançamentos e reaberturas sobre toda sessão da missão" -m "launches = run_id distintos (o fato; 'intervenções = lançamentos − 1' é a leitura, na D16). reopened = sessão numa fase abaixo de outra cujo gate já PASSOU, na ordem de PHASES — não 'o índice andou para trás', que contaria o laço desenhado (frete-cif-fob: 3× EXEC depois de QA reprovada, lê 0; SQ-111: QA depois de PR, lê 1). Os dois saem sobre TODAS as sessões locais da missão, porque a QA pós-PR da SQ-111 tem kit_dirty:true e sobre as comparáveis reopened leria 0 justo ali; session(s)/outcomes/US$ continuam sobre as comparáveis, e o parágrafo de contabilidade diz quando as populações diferem. Mutantes: AUTONOMY_launches_counts_rows, AUTONOMY_reopened_ignores_gate, AUTONOMY_reopened_comparable_only."
```

---

### Task 6: The notes become narrative — `intervention note(s)` only with a checkpoint on disk, and `?` is gone

**Files:**
- Modify: `bin/sdd` — `cmd_autonomy` comment block (:4162–4176), the interventions loop
  (:4178–4204), the `$iv` binding in the mission line, the help text (:5101–5104)
- Modify: `templates/checkpoint.md:44–47`
- Test: `tests/check-autonomy.sh` (new block after the Task 5 blocks; the :1722 regex)

Spec §4.5 and 5.6. The help text and the template are inside the stamp key, which is why they land
here and not in Task 8.

- [ ] **Step 1: The failing assertions**

Insert after the `population` block of Task 5:

```bash
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
```

Change the older assertion's regex (:1724, both `h1` and `h2` occurrences) from
`grep -oE '[0-9]+ intervention'` to `grep -oE '[0-9]+ intervention note'` so the name is pinned
there too. Same at :1755 (`h3`).

- [ ] **Step 2: Run red**

Run: `./tests/check-autonomy.sh 2>&1 | grep -A2 FAIL | head -40`
Expected: `? intervention` counted (`0 3`), `2 intervention note(s)` absent, the m1 line still
carrying `0 intervention(s)` (both the "cell does not exist" and the "cell by cell" lines fail),
the `otherrepo/h1` line borrowing the note (`2 1 1`), and the three renamed regexes returning
empty.

- [ ] **Step 3: `bin/sdd` — the loop only records a checkpoint that exists**

Replace the comment block at :4162–4176 (from `# The human interventions D12 prescribes:` through
`# answer `?` rather than a zero that would read as "nobody intervened".`) with:

```bash
  # The `- intervention:` notes of the mission checkpoint — what the human DID, in prose. Until
  # 2026-08-28 this was the intervention COUNT the D12 metric read (D16), and it was measured to
  # be a label the executor had to remember to write: the pilot missions carried 0, 1 and 0 notes,
  # and the one with three launches had none. The count is `launch(es)` now, distinct run_id per
  # mission, on every line of every repo; the notes are printed beside it as `intervention
  # note(s)`, and ONLY when there is a checkpoint on disk to read them from. No `?`: it stood in
  # for "nobody looked" so that no false zero reached the official number, and the official number
  # no longer comes from this file. A mission with no checkpoint simply has no notes to show.
  #
  # The TOKEN is English and the prose after it is not, exactly like the status words the boot
  # prompt already tells every session to leave alone: pending, done, blocked, auto, skipped. D12
  # wrote the marker in pt-BR; spelling it that way here would have put a new Portuguese contract
  # token on the kit surface — the very lock CLAUDE.md lists as debt for `aprovacao`, `versao` and
  # `titulo`, and that tests/check-lang.sh refuses. The checkpoint is an OUTPUT_LANG artifact, so
  # what follows the colon is written in whatever language the repo declared.
  #
  # Only for missions of THIS repo: the file lives under `$repo/$HANDOFF_DIR/`, and HANDOFF_DIR is a
  # key of the config of the repo the reader is standing in. Under --all-repos the missions of
  # other projects print no cell — and the jq below also refuses to lend this repo notes to a
  # foreign mission that merely shares the slug.
```

In the loop, replace:
```bash
      ck="$repo/$hdir/$m/checkpoint.md"
      n=0
      # `|| true` on BOTH: grep exits 1 when it counts zero, and `set -e` would take the whole
      # command down on the first mission that had no interventions — the common case.
      [ -f "$ck" ] && n="$(grep -cE '^[[:space:]]*-[[:space:]]*intervention:' "$ck" || true)"
      interventions="$(jq -c --arg m "$m" --argjson n "${n:-0}" '. + {($m): $n}' <<< "$interventions")"
```
with:
```bash
      ck="$repo/$hdir/$m/checkpoint.md"
      # A checkpoint that is not on disk contributes NO entry, so the cell does not print: absent
      # is not zero. `|| true`: grep exits 1 when it counts zero, and `set -e` would take the whole
      # command down on the first mission whose checkpoint has no note — the common case.
      [ -f "$ck" ] || continue
      n="$(grep -cE '^[[:space:]]*-[[:space:]]*intervention:' "$ck" || true)"
      interventions="$(jq -c --arg m "$m" --argjson n "${n:-0}" '. + {($m): $n}' <<< "$interventions")"
```

- [ ] **Step 4: `bin/sdd` — the cell in the jq program**

Replace, in the by-mission `map(`:
```
              # `?` and not 0 for a mission of another repo: its checkpoint lives under a
              # HANDOFF_DIR this process never loaded, and a zero there would read as
              # "nobody intervened" when the truth is "nobody looked".
              | (if ($interventions | has($m)) then "\($interventions[$m]) intervention(s)"
                 else "? intervention(s)" end) as $iv
```
with:
```
              # The narrative, under the name that says what it is, and only when the checkpoint
              # was readable: a mission of THIS repo with the file on disk. `$r == $repo` keeps a
              # foreign mission that shares the slug (--all-repos) from borrowing this repo notes —
              # the map is keyed by slug alone. Absent, the cell does not print: no `?`, no zero.
              | (if $r == $repo and ($interventions | has($m)) then " · \($interventions[$m]) intervention note(s)" else "" end) as $iv
```
and the mission line's ` · \($iv) · US$` becomes `\($iv) · US$` (the separator now lives inside
`$iv`):
```
              | "  \($label)  \($n) session(s) · \($t.advanced) advanced · \($t.churned) churned · \($t.idle) idle · \($launches) launch(es) · \($reopened) reopened\($iv) · US$ \($cost | usd)"
```

- [ ] **Step 5: `bin/sdd` — the help text**

Replace :5101–5104:
```
  sdd autonomy [--all-repos] waste per kit version, for this repo unless --all-repos, from the ledger
             [--by-mission]  group by mission instead of by kit version: sessions, stalled,
                             human interventions (the `- intervention:` notes of the checkpoint)
                             and the mission cost. Same rows, same money, other unit.
```
with:
```
  sdd autonomy [--all-repos] what the sessions did per kit version — advanced · churned · idle, and
                             waste = churned + idle — for this repo unless --all-repos, from the ledger
             [--by-mission]  group by mission instead of by kit version: the same three outcomes,
                             launch(es) (distinct run_id — the intervention count D12 reads),
                             reopened phases, the `- intervention:` notes of the checkpoint when
                             it is on disk, and the mission cost. Same rows, same money, other unit.
```

- [ ] **Step 6: `templates/checkpoint.md` — the note is narrative**

Replace :44–47:
```
> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É o que o
> `sdd autonomy --by-mission` conta, e é a metade que o custo sozinho não mostra: US$ baixo não
> distingue "rodou barato" de "rodou barato porque um humano fez metade".
```
with:
```
> **Toda vez que um humano precisou entrar na linha** — um `sdd retry`, um conserto à mão, um
> `BLOCKED` assumido — sai uma linha com o marcador `intervention:`. É a **narrativa** do que o
> humano fez. O **número** de intervenções o `sdd autonomy --by-mission` lê do ledger, em
> `launch(es)` (`run_id` distintos — cada `sdd run`/`sdd retry`), e imprime estas notas ao lado
> como `intervention note(s)`. Medido em 2026-08-28: a missão de três lançamentos tinha zero
> notas — o contador não pode depender de alguém lembrar de escrever; a narrativa, sim, e é a
> única fonte que diz o que o humano *fez*.
```

- [ ] **Step 7: Run green, whole suite, help assertion**

Run: `bash -n bin/sdd && ./tests/run-all.sh 2>&1 | tail -3 && ./bin/sdd help | grep -c 'launch(es)'`
Expected: suite green; `1`.

- [ ] **Step 8: Commit**

```bash
git add bin/sdd templates/checkpoint.md tests/check-autonomy.sh
git commit -m "feat(autonomy): as notas de intervenção viram narrativa, e o ? desaparece" -m "O número oficial da D12 é launch(es), em toda linha; as linhas '- intervention:' seguem como narrativa, impressas como 'intervention note(s)' só quando o checkpoint está em disco (missão sem arquivo: célula ausente, nunca zero, nunca ?). Missão estrangeira com o mesmo slug não empresta as notas deste repo. Ajuda do runner e template do checkpoint no mesmo commit — os dois estão na chave do carimbo."
```

---

### Task 7: The mutation stamp — `173 caught of 173`, after the last code commit

**Files:** none committed. Writes `.sdd/logs/mutation-stamp` (gitignored).

This is the last touch to `bin/ tests/ templates/ config/`; every later task edits files outside
the key. Running it earlier costs a second catalogue run (20–50 min, `docs/failure-modes.md`).

- [ ] **Step 1: Confirm the tree is committed and the count is right**

Run: `git status --short; grep -cE '^  [A-Za-z0-9_]+$' <(sed -n '/^CATALOG=(/,/^)/p' tests/check-mutation.sh)`
Expected: clean; `173`.

- [ ] **Step 2: Run the catalogue through `sdd health`**

`sdd health` always runs the catalogue — there is no flag (`cmd_health` ignores its arguments and
calls `tests/run-all.sh --with-mutation` itself). It takes 10–20 minutes on this box: run it with a
Bash timeout of 600000 ms, or in the background with the output redirected, and do not start a
second one while it runs.

Run: `./bin/sdd health 2>&1 | tee "$HOME/.sdd/measure/2026-08-28-instrumento-honesto/health.txt" | tail -20`
Expected: `score: 173 caught, 0 known gap(s), of 173`, no `CATALOGUE-BROKEN`, no `is NOT caught`,
`todo-findings 78` accepted by the ratchet, and the line saying the mutation stamp was written.

- [ ] **Step 3: Read the stamp**

Run: `cat .sdd/logs/mutation-stamp; git status --short`
Expected: a key printed; tree still clean (the stamp is ignored).

If a mutant is `NOT caught` or `CATALOGUE-BROKEN`: fix the anchor or the assertion in the task that
owns it, commit, and run this task again — the stamp keys on content, so it has to be re-earned.

---

### Task 8: Documentation — the contract in its other places

**Files:**
- Modify: `docs/pipeline.md:594`, `:619–632`, `:648–661`
- Modify: `agents/sdd-kaizen.md:40–46`, after `:81` ("Every number in your verdict comes from this
  output."), `:106`; mirror `.claude/agents/sdd-kaizen.md` via `sdd install --force`
- Modify: `README.md:61–62`
- Modify: `docs/failure-modes.md:81`

- [ ] **Step 1: `docs/pipeline.md` — the `moved` row (:594)**

Replace the sentence `\`moved:false\` is exactly what \`sdd autonomy\` counts as a stalled session.`
in that table cell with:
```
`moved` alone no longer names a bucket: since `20260828-instrumento-honesto` both readers classify a comparable session as `advanced` (the gate passed — the gate is the artifact), `churned` (`moved:true` and the gate failed: the session wrote and the runner bought another lap) or `idle` (`moved:false` and the gate failed — the old `stalled`, under the name that says what it is). ONE definition, `ledger_outcome_defs` in `bin/sdd`, spliced into `cmd_autonomy` and `kaizen_series`; `tests/check-autonomy.sh` compares the two histograms over one file. `waste = churned + idle`.
```

- [ ] **Step 2: `docs/pipeline.md` — `--by-mission` (:619–632)**

Replace the paragraph beginning `Its extra column is **human interventions**` (through `"nobody
intervened" when the truth is "nobody looked".`) with:

```
Its extra cells are **`launch(es)`** and **`reopened`**, and they are the half cost alone cannot
show: a cheap mission and a mission that ran cheap because a human relaunched it three times print
the same number of dollars. `launch(es)` is the count of distinct `run_id` in the mission — every
`sdd run` or `sdd retry` a human typed. It is the number the D12 metric reads (D16, amended
2026-08-28): the fact, never `launches − 1` — "interventions = launches − 1" is the reading, and a
subtraction inside the instrument would print `0` on a mission abandoned after its first launch. It
**undercounts** by design: bringing the app up by hand between two launches is one new `run_id`,
not two. `reopened` counts sessions in a phase **below** one whose gate had already **passed**, in
the canonical phase order — the pipeline going backwards after it had gone forward. Not "the phase
index went down": that would count the designed loop (QA fails, opens a fix increment, EXEC runs
it), which `20260825-frete-cif-fob` did three times with QA refused, all of it the pipeline working
(reads 0); SQ-111 ran QA after PR had passed and reads 1. A phase outside the order (`KAIZEN`)
counts on neither side.

Both are drawn over **every** local session of the mission, comparable or not — a launch that
landed on a dirty kit was a launch — while `session(s)`, the outcomes and `US$` stay on the
comparable sessions, because that is the sum the sensor closes against the version table. When the
two populations differ for a printed mission, the accounting paragraph says so once:
*(launches and reopened are counted over every session of the mission, N of them non-comparable)*.
A mission whose sessions are all non-comparable does not appear — as before.

The `- intervention:` notes of `checkpoint.md` are **narrative**, not the count. They print as
`N intervention note(s)` between `reopened` and `US$` when the mission belongs to this repo and its
checkpoint is on disk, and not at all otherwise — no `?`, no zero: `?` existed so that no false
zero reached the official number, and the official number no longer comes from the file. Measured
before the change: the pilot missions carried 0, 1 and 0 notes; the one with three launches had
none. The marker stays **English and contract**, like `pending`/`done`/`blocked`; the text after
the colon follows `OUTPUT_LANG`, and the word in the middle of a sentence is prose and is not
counted.
```

- [ ] **Step 3: `docs/pipeline.md` — the series and the rubric (:648–661)**

In the sentence `… sessions, \`moved_rate\`, cost, escalations by kind, a per repo×mission×phase
\`detail\` (each entry naming its \`repo\`), and a label per group:` replace `sessions,
\`moved_rate\`, cost,` with:
```
sessions, `outcomes` (`{advanced, churned, idle}` — what the sessions did, the headline since
2026-08-28; the same three buckets appear in every `detail[]` entry), `advance_rate` (the share
whose gate passed), `moved_rate` (the share that wrote to the disk — kept, its name says what it
measures), cost,
```
And the `leve` bullet becomes:
```
- `leve` — an in-loop auto retry, a session that did not move the disk, **or any session of the
  phase that failed its gate** (churn: it wrote, the gate refused, the runner bought the next lap;
  `frete-cif-fob` EXEC was seven sessions and five refusals and read `ok` until 2026-08-28):
  friction, absorbed. Three labels, not four — the magnitude lives in `outcomes`.
```

- [ ] **Step 4: `agents/sdd-kaizen.md`**

(a) :41 — replace `missions, sessions, \`moved_rate\`, the label tally` with
`missions, sessions, \`outcomes\` (\`{advanced, churned, idle}\` — what the sessions did; cite it
before anything else), \`advance_rate\` (the share whose gate passed), \`moved_rate\` (the share
that wrote to the disk), the label tally`.

(b) :106 — replace `labels, \`moved_rate\`, escalations, cost, the guard` with
`labels, \`outcomes\`, \`advance_rate\`, \`moved_rate\`, escalations, cost, the guard`.

(c) After the line `Every number in your verdict comes from this output. Cite them as they are.`
(:81) insert:
```

**The intervention count (D12) is NOT in the series**, and you do not invent it. The series groups
by `kit_sha`, and a mission that spans two kit versions would count its launches twice. Read it from
`"$SDD_HOME/bin/sdd" autonomy --all-repos --by-mission` — the `launch(es)` cell is distinct `run_id`
per mission, and the reading is *interventions = launches − 1* (D16, amended 2026-08-28). Cite the
command you read it from, beside the number. The `intervention note(s)` cell, when present, is the
narrative of what the human did; it is not the count.
```

- [ ] **Step 5: Sync the mirror**

Run: `./bin/sdd install --force 2>&1 | tail -5; diff agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md && echo mirror-in-sync`
Expected: `agent sdd-kaizen updated (--force)`; `mirror-in-sync`. Never `cp`.

- [ ] **Step 6: `README.md:61–62`**

Replace:
```
sdd autonomy                 # waste per kit version, for THIS repo, from the global ledger (~/.sdd/autonomy-log.jsonl)
sdd autonomy --all-repos     # ...for EVERY repo on this machine (the cross-project question; never the default)
```
with:
```
sdd autonomy                 # what the sessions did per kit version (advanced · churned · idle, waste), for THIS repo,
                             #   from the global ledger (~/.sdd/autonomy-log.jsonl)
sdd autonomy --all-repos     # ...for EVERY repo on this machine (the cross-project question; never the default)
sdd autonomy --by-mission    # ...per mission: the same outcomes, launch(es) (distinct run_id — the intervention
                             #   count), reopened phases, the checkpoint's intervention notes, and the mission cost
```

- [ ] **Step 7: `docs/failure-modes.md:81`**

Replace `(labels, \`moved_rate\`, escalations, cost)` with `(labels, \`outcomes\`, \`advance_rate\`,
escalations, cost)`.

- [ ] **Step 8: Language sensor, suite, commit**

Run: `./tests/check-lang.sh 2>&1 | tail -2 && ./tests/run-all.sh 2>&1 | tail -3`
Expected: both green. The stamp is NOT invalidated because none of these paths is in the key —
confirm by construction, never by re-running `sdd health` (that re-runs the whole catalogue):
`git diff --stat <Task 6 commit>..HEAD -- bin tests templates config` must print nothing.

```bash
git add docs/pipeline.md agents/sdd-kaizen.md .claude/agents/sdd-kaizen.md README.md docs/failure-modes.md
git commit -m "docs(pipeline): a tri-estado, launches e reopened, e a manchete do juiz" -m "Contrato em três lugares: a linha moved do ledger deixa de nomear stalled; a seção --by-mission descreve launch(es), reopened, a população e a célula de notas; a série ganha outcomes e advance_rate e o leve ganha a cláusula de churn. O prompt do juiz cita outcomes antes de moved_rate e aprende de onde lê a contagem da D12. Espelho sincronizado por sdd install --force."
```

---

### Task 9: `CONTEXT.md` and the KAIZEN_LOG entry — the AFTER, recaptured

**Files:**
- Modify: `CONTEXT.md` — D16 row (:50), the *Série* glossary entry (:13), new **Churn** entry
- Modify: `KAIZEN_LOG.md` — new entry at the top, after the intro `---`

- [ ] **Step 1: Recapture the AFTER with the same three commands**

```bash
MEASURE="$HOME/.sdd/measure/2026-08-28-instrumento-honesto"
./bin/sdd autonomy --all-repos               > "$MEASURE/after-autonomy.txt" 2>&1
./bin/sdd autonomy --all-repos --by-mission  > "$MEASURE/after-by-mission.txt" 2>&1
./bin/sdd kaizen --series                    > "$MEASURE/after-series.json" 2>/dev/null
grep 'condicoes-pagamento' "$MEASURE/after-by-mission.txt"
grep -c '?' "$MEASURE/after-by-mission.txt"
grep 'lote-facil' "$MEASURE/after-by-mission.txt"
awk '{ for (i = 1; i <= NF; i++) { if ($(i+1) == "advanced") a += $i; if ($(i+1) == "churned") c += $i; if ($(i+1) == "idle") d += $i } } END { print a, c, d }' "$MEASURE/after-autonomy.txt"
jq -c '.latest | {kit_sha, outcomes, advance_rate, moved_rate, labels}' "$MEASURE/after-series.json"
jq -r '.latest.detail[] | select(.mission | test("frete-cif-fob")) | select(.phase == "EXEC") | .label' "$MEASURE/after-series.json"
./tests/run-all.sh 2>&1 | grep -cE '^  ok    '
./tests/check-autonomy.sh 2>&1 | grep -cE '^  ok    '; ./tests/check-kaizen.sh 2>&1 | grep -cE '^  ok    '
```
Expected (spec §8 — verify, do not assume): `condicoes-pagamento … 6 session(s) · 5 advanced ·
1 churned · 0 idle · 3 launch(es) · 1 reopened · US$ 68.87`; zero `?`; `lote-facil … 4 launch(es)
· 2 reopened`; the version table sums to `64 68 13`; the latest series group shows
`outcomes {advanced:5, churned:1, idle:0}, advance_rate 0.83`, labels unchanged from
`before-series.json`; `frete-cif-fob` EXEC is on an older sha — find it with
`jq '.previous.detail[]…'` or note that it is outside `latest`/`previous` and cite the §2 table
instead. Record every number in `$MEASURE/after-counts.txt`.

- [ ] **Step 2: `CONTEXT.md` — D16 amended**

In the D16 row (:50), replace the **Decisão** cell (`**\`sdd autonomy --by-mission\`**, agrupando
por … entra no mesmo diff.`) with:

```
**`sdd autonomy --by-mission`**, agrupando por `(repo, missão)` — a chave que o `kaizen_series` já usa — com sessões, **o que cada uma fez** (`advanced · churned · idle`), custo total e **a contagem de intervenções lida do ledger: `launch(es)` = `run_id` distintos** (emenda de 2026-08-28, missão `20260828-instrumento-honesto`). As notas `- intervention:` do `checkpoint.md` ficam como **narrativa** — o que o humano *fez* —, impressas ao lado como `intervention note(s)` só quando o arquivo está em disco; missão sem arquivo não imprime célula (nem `?`, nem zero). A leitura é *intervenções = lançamentos − 1*; o instrumento imprime o fato, nunca a subtração. ⚠️ A forma original desta decisão — o número lido da prosa — foi **medida e derrubada**: `condicoes-pagamento` (três lançamentos, `~8 resgates` no handoff) tinha **zero** linhas `- intervention:`, e fora do repo do kit o contador respondia `?`. O `run_id` está em toda linha, de todo repo. `launches` **subconta** de propósito (subir o app à mão entre dois lançamentos é um `run_id` novo, não dois) — piso honesto no lugar de um teto que ninguém preenchia.
```

- [ ] **Step 3: `CONTEXT.md` — the *Série* entry and the **Churn** entry**

In the *Série* row (:13), replace `desperdício (\`moved:false\`/total)` with
`desperdício (\`churned + idle\` sobre o total — até \`20260828-instrumento-honesto\`,
\`moved:false\`/total; verbete *Churn*), \`outcomes\` e \`advance_rate\` por grupo e por entrada de
\`detail\``.

Insert a new row right after the **Escalada** row (:14):
```
| **Churn** (`churned`) | Sessão que **escreveu no disco e mesmo assim reprovou no gate** (`gate: fail` + `moved: true`): o runner lê "moveu" como progresso e compra a volta seguinte. Invisível até `20260828-instrumento-honesto`, porque `stalled` era `moved == false` — e **68 das 145 sessões** do ledger real estavam neste balde sem nome (o EXEC de `frete-cif-fob`: 7 sessões, 5 reprovações, rótulo `ok`). Hoje é um dos três resultados de sessão — `advanced` (gate passou; o gate é o artefato), `churned`, `idle` (nada em disco, gate reprovou — o antigo `stalled`) —, **UMA definição** (`ledger_outcome_defs`, jq impresso) costurada nos dois leitores, com paridade provada por asserção diferencial e nunca por "mesma grafia". `waste = churned + idle`. Na rubrica do juiz, qualquer `churned` na fase ⇒ pelo menos `leve`; a magnitude mora em `outcomes`, não num quarto rótulo. `pass/false` não ocorre no ledger e é classificado `advanced` sem fixture próprio — limite declarado. |
```

- [ ] **Step 4: `KAIZEN_LOG.md` — the entry**

Insert after the intro `---` (:5), before `## 2026-08-26 — A ADR 0005 sai do papel…`. Fill every
`<…>` from `$MEASURE/before-counts.txt` and `after-counts.txt` — a cell left unfilled fails the
mission's own rule ("sem número, não é kaizen"):

```md
## 2026-08-28 — O ledger passa a dizer o que a sessão fez, não só se ela escreveu (missão `20260828-instrumento-honesto`)

**Problema (Gemba):** a pergunta do dono do kit é *"está maduro para projeto real?"*, e o
instrumento que deveria respondê-la respondia errado — **na direção que lisonjeia o kit**. `stalled`
estava definido como `moved == false`: "a sessão não escreveu nada", que não é "a fase não avançou".
Censo das 145 sessões do ledger real, antes de qualquer edição: 64 `pass/true`, **68 `fail/true`**
(escreveu algo, o gate reprovou, o runner comprou outra sessão — **invisíveis**), 13 `fail/false`
(`stalled`). Sobre `20260827-condicoes-pagamento-mesmo-cliente`, que o handoff descreve como
*"~8 resgates humanos"*: `6 session(s) · 0 stalled · ? intervention(s)` — três `run_id` distintos
na mesma missão, e `?` porque a contagem da D16 lia linhas `- intervention:` de um checkpoint que
ninguém escreveu (0, 1 e 0 notas nas três missões do piloto). O juiz lia `ok` para o EXEC de
`frete-cif-fob`: 7 sessões, 5 reprovações, cada uma commitando algo.

**Contramedida:** uma definição de "o que a sessão fez" (`ledger_outcome_defs`, jq impresso),
costurada nos dois leitores como `ledger_row_is_local` já era, com paridade provada por asserção
diferencial; `launch(es)` (= `run_id` distintos) como o número da D12, sobre **todas** as sessões
locais da missão; `reopened` pela definição "fase abaixo de outra cujo gate já passou"; a cláusula
de churn na rubrica (`leve`). Nenhum campo novo na linha, `v` continua 1, zero migração — as 145
linhas se releem com a régua nova. D16 emendada no `CONTEXT.md`; achado do `sdd close` no
`TODO.md`. Spec em `docs/superpowers/specs/2026-08-28-instrumento-honesto-design.md`.

| | Antes (régua `moved`) | Depois (régua `gate` + `moved`) |
|---|---|---|
| 145 sessões, todos os repos | `13 stalled` | `64 advanced · 68 churned · 13 idle` |
| `condicoes-pagamento` (SQ-111), por missão | `6 session(s) · 0 stalled · ? intervention(s) · US$ 68.87` | `6 session(s) · 5 advanced · 1 churned · 0 idle · 3 launch(es) · 1 reopened · US$ 68.87` |
| `frete-cif-fob` · EXEC, no juiz | `ok` | `leve` |
| `25d4e1c` (latest), série | `moved_rate: 1, labels: {ok:5, leve:0, refez:1}` | `outcomes: {advanced:5, churned:1, idle:0}, advance_rate: 0.83`; `labels` **não** muda — o único grupo com reprovação nesta fatia já lia `refez` pela última sessão |
| `lote-facil` | `9 session(s)` | `4 launch(es) · 2 reopened` — bate com a contagem à mão de `20260828-o-gate-sabe-que-o-app-caiu-handoff.md` §9 |
| `?` na tabela por missão (`--all-repos`) | <antes: contar `? intervention`> | **0** |
| `waste` da versão mais recente do kit | <antes> | <depois> — a régua mudou: `churned + idle`, não só `idle` |
| asserções de `tests/run-all.sh` | <antes> | <depois> |
| `tests/check-autonomy.sh` / `check-kaizen.sh` | <antes> / <antes> | <depois> / <depois> |
| catálogo de mutação | 166 de 166 | **173** de 173 |
| achados abertos no `TODO.md` | 77 | 78 (o `sdd close`) |

**Sete mutantes entram, cada um com o assassino nomeado:** `AUTONOMY_outcome_reads_moved_only` (o
histograma exato de `check-autonomy.sh` — a paridade sozinha NÃO o pega, porque os dois leitores
erram juntos), `KAIZEN_outcome_inlined_old` (a paridade — é o que prova que ela é medida e não
afirmada), `KAIZEN_churn_reads_ok`, `AUTONOMY_waste_idle_only`, `AUTONOMY_launches_counts_rows`,
`AUTONOMY_reopened_ignores_gate`, `AUTONOMY_reopened_comparable_only`.

⚠️ **O que ISTO NÃO PROVA.** `launches` subconta por construção (piso, não teto). `pass/false` é
classificado `advanced` sem fixture. A mudança da rubrica não é emenda da ADR 0001: é o caso que
ela desenhou — régua mecânica é código, datada no histórico. E o `sdd close` continua fora do
ledger — achado, não conserto.
```

- [ ] **Step 5: Sensors that read these files, then commit**

Run: `./tests/check-todo.sh 2>&1 | tail -1 && ./tests/check-lang.sh 2>&1 | tail -1 && ./tests/run-all.sh 2>&1 | tail -2`
Expected: green. (`CONTEXT.md` and `KAIZEN_LOG.md` are pt-BR content, not kit surface.)

```bash
git add CONTEXT.md KAIZEN_LOG.md
git commit -m "docs(context): a D16 emendada, o verbete Churn, e a entrada do KAIZEN_LOG" -m "A D16 passa a nomear o run_id como contador e a prosa como narrativa, com a medição que derrubou a forma anterior (zero notas na missão de três lançamentos). O verbete Churn nomeia o balde que 68 das 145 sessões ocupavam sem nome. A entrada do KAIZEN_LOG carrega os dois lados, capturados com os mesmos três comandos antes da primeira edição e depois do último commit de código."
```

---

### Task 10: The handoff, and the acceptance run

**Files:**
- Create: `docs/superpowers/specs/2026-08-28-instrumento-honesto-handoff.md`

The handoff is the artifact the next session reads instead of this conversation (CLAUDE.md
principle 3). Same skeleton as `2026-08-28-o-gate-sabe-que-o-app-caiu-handoff.md`, pt-BR.

- [ ] **Step 1: Run the acceptance of spec §13, and keep the output**

```bash
MEASURE="$HOME/.sdd/measure/2026-08-28-instrumento-honesto"
{ ./tests/run-all.sh 2>&1 | tail -3
  ./bin/sdd health 2>&1 | grep -iE 'stamp|score|todo-findings'
  ./bin/sdd autonomy --all-repos --by-mission | grep condicoes-pagamento
  ./bin/sdd autonomy --all-repos --by-mission | grep -c '?'
  ./bin/sdd kaizen --series | jq -c '.latest.outcomes, .latest.advance_rate'
  git diff main -- KAIZEN_LOG.md | grep -c 'churned'
} 2>&1 | tee "$MEASURE/acceptance.txt"
```
Expected: suite green; stamp valid with `173`; the SQ-111 line reads `… 5 advanced · 1 churned ·
0 idle · 3 launch(es) · 1 reopened …`; `0`; the two series values; `≥ 1`.

- [ ] **Step 2: Write the handoff**

Create `docs/superpowers/specs/2026-08-28-instrumento-honesto-handoff.md` with these sections, each
filled from what actually happened (commit hashes from `git log --oneline main..HEAD`, numbers from
`$MEASURE/*-counts.txt` and `acceptance.txt`):

```md
# O instrumento honesto — handoff

**Data:** 2026-08-28 · **Estado:** <I1 a I10 commitados | o que ficou aberto>. Carimbo `<chave>`,
`173 caught of 173`, catraca `todo-findings 78`.

## 1. Comece por aqui
- branch `feat/instrumento-honesto`, empilhada sobre `feat/o-gate-sabe-que-o-app-caiu` (`cfb5fa7`);
  PR de baixo <aberto? mergeado?>; quando mergear, `git rebase main` é trivial (a base já está lá)
- spec: `docs/superpowers/specs/2026-08-28-instrumento-honesto-design.md`
- plano: `docs/superpowers/plans/2026-08-28-instrumento-honesto.md`
- comandos que provam o estado (os de §13 do spec, com a saída de `$MEASURE/acceptance.txt`)

## 2. Por que esta missão existe
(3 parágrafos, do §2 do spec: o leitor humano, o juiz, a contagem de intervenções — com os números)

## 3. O que foi feito
(um item por commit, `hash — o quê`, na ordem do `git log`)

## 4. O desenho, em três frases
(ledger_outcome_defs costurada nos dois; launches/reopened sobre toda sessão da missão; leve ganha churn)

## 5. Verificação ponta a ponta
(a tabela antes/depois do KAIZEN_LOG, e os sete mutantes com o assassino)

## 6. As decisões que se afastaram do plano, e por quê
(pelo menos: `outcome_tally` na emissão compartilhada; `$phases` compila sem o --arg no jq 1.7 —
o comentário diz o que foi medido; a guarda `$r == $repo` na célula de notas; qualquer outra)

## 7. Armadilhas medidas
(o que custou tempo na execução: âncoras de mutante, a ordem do carimbo, qualquer FAIL pelo motivo errado)

## 8. O que falta
(o `sdd close` no ledger — `TODO.md`; a faxina D15 e o custo do REVIEW — handoff anterior §9)

## 9. A próxima missão, já desenhada
(as duas do handoff anterior §9, intocadas — e o que esta missão muda na leitura delas: a janela
de medição agora lê `launch(es)` e `reopened`, então o piso de 3 missões tem um instrumento)
```

- [ ] **Step 3: Sensors, commit**

Run: `./tests/check-lang.sh 2>&1 | tail -1; ./tests/run-all.sh 2>&1 | tail -2; git status --short`
Expected: green; only the handoff untracked.

```bash
git add docs/superpowers/specs/2026-08-28-instrumento-honesto-handoff.md
git commit -m "docs(handoff): o instrumento honesto — o que fechou e o que a próxima missão herda" -m "Estado em disco, não em contexto: a sessão seguinte lê isto e o spec, nunca a conversa."
```

- [ ] **Step 4: Final state**

Run: `git log --oneline main..HEAD | head -25; git status --short; ./bin/sdd health 2>&1 | grep -iE 'stamp|todo-findings'`
Expected: the twelve commits of the branch below plus the nine of this plan (Tasks 1–6, 8–10);
clean tree; stamp valid. The PR is opened by the human (`sdd close`/`PR` are outside this plan:
the branch below has no PR yet, and this one stacks on it).

---

## Self-review against the spec

| Spec | Task |
|---|---|
| §3 D-a both readers, same commit, differential assertion | Task 2 (5.7 parity + `KAIZEN_outcome_inlined_old`) |
| §3 D-b `launches` is the D12 number, D16 amended | Task 5 (code), Task 6 (notes), Task 9 (CONTEXT D16), Task 8 (agent, pipeline) |
| §4.1 one definition, `--arg phases` in both | Task 2 Steps 4–6 (with the jq 1.7 measurement noted) |
| §4.2 version line, `waste` new yardstick, `stalled` gone | Task 2 (line), Task 3 (yardstick) |
| §4.3 `outcomes`, `advance_rate`, `phase_label`, `moved_rate` stays, three labels, empty series untouched | Task 2 (fields), Task 4 (clause) |
| §4.4 `launches`, `reopened` (gate-aware), population, accounting sentence | Task 5 |
| §4.5 mission line, `intervention note(s)`, no `?`, `launches` not `− 1` | Task 5, Task 6 |
| §4.6 nothing else changes | every task edits only what it names; `assert_bucket_sum` and the key-set assertions stay |
| §5 sensors 1–12 | 5.1/5.2/5.7/5.8 Task 2–3 (`tristate`); 5.3/5.4/5.5 Task 5; 5.6 Task 6; 5.9/5.10 Task 2; 5.11/5.12 Task 4; `50% → 100%` Task 3 |
| §6 seven mutants, anchored in code | Tasks 2 (2), 3 (1), 4 (1), 5 (3) — every anchor dry-run against the planned lines while writing this plan |
| §7 docs table | Task 6 (template, help), Task 8 (pipeline ×3, agent ×2 + mirror, README, failure-modes), Task 9 (CONTEXT, KAIZEN_LOG) |
| §8 measurement before/after | Task 0, Task 9 Step 1 |
| §9 order — TODO first, code, stamp, docs, handoff | Tasks 1 → 2–6 → 7 → 8–9 → 10 |
| §10 the `sdd close` finding | Task 1 |
| §11 declared limits | in the `launches`/`reopened` comments (Task 5) and the **Churn** entry (Task 9) |
| §13 acceptance | Task 10 Step 1 |
