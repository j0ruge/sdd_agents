# Schema for `.sdd/config.sh`

The file is **pure bash** — the runner sources it. No logic: assignments only.
Created by `sdd install` from [`examples/sales_quote.conf`](examples/sales_quote.conf).

Rule: if a required key is empty, `sdd preflight` fails **before** spending a session. For two keys
it goes further than "not empty", because for those two an unusable value is only discovered by a
phase that has already been paid for:

- **`DEFAULT_BRANCH` is looked up in the repository.** On `origin` ⇒ ok; only local ⇒ a warning, since
  `gh pr create --base` opens the PR against the *remote* branch; nowhere ⇒ a failure. Without this
  the error surfaces in the PR phase, the last one, with EXEC, QA, REVIEW and DOCS already spent.
- **`TEST_CMD` is EXECUTED**, not just read. The spelling check that refuses `true`, `:` and
  `--list` cannot see a suite that dies on a dependency nobody installed — and `gate_EXEC` runs the
  same command for real, so a red suite makes the EXEC phase unsatisfiable at one session per lap.
  A value the spelling check already refused is *not* executed.

## Project identity

| Key | Required | Default | What it is |
|---|---|---|---|
| `PROJECT_NAME` | yes | — | Short name of the target repo. Appears in the logs and in the PR body. |
| `DEFAULT_BRANCH` | yes | — | **Base branch for PRs**. ⚠️ Not always `main`: in `sales_quote` the flow is `develop → staging → main`, so it is `develop`. Check `git symbolic-ref refs/remotes/origin/HEAD` instead of assuming. |
| `OUTPUT_LANG` | no | empty | Language of the mission **artifacts** — handoffs, checkpoint, commit messages, PR body — passed into the boot prompt of every phase. Empty ⇒ the runner says nothing about language and each session follows whatever the existing artifacts use. It does not affect the kit, which is English, nor the contract (config keys and status tokens are always English). E.g. `pt-BR`, `en`, `es`. |

## Verification commands (the runner's sensors)

They all run with cwd at the root of the target repo. The runner only looks at the **exit code**.

| Key | Required | Default | What it is |
|---|---|---|---|
| `TEST_CMD` | yes | — | Unit/integration suite. It is the EXEC gate and part of the REVIEW gate. It must be fast enough to run on every increment. |
| `E2E_CMD` | no | empty | End-to-end suite. Empty ⇒ the QA gate ignores e2e (a project with no UI). |
| `E2E_DIR` | no | `e2e` | Where `sdd-qa` commits new specs. Reaches the boot prompt of every phase, beside `E2E_CMD` and only when that key is set: a repo with no interface writes no specs. |

The runner has exactly these three. A separate lint or build command belongs **inside** `TEST_CMD`:
a key the runner never reads is a promise the user cannot collect on, and this schema carried five
such keys — for a lint, a build and bringing the environment up — until they were removed. Adding
one back means wiring the read in `bin/sdd` in the **same** commit.

## Running application (QA phase)

| Key | Required | Default | What it is |
|---|---|---|---|
| `APP_URL` | only with `E2E_CMD` | empty | URL `agent-browser` opens in the exploratory sessions — and the address the runner asks whether anything is listening on. |

The runner does not bring the environment up: it assumes the app is already running. Starting it
(`docker compose up -d` and friends) is a step for whoever runs `sdd`, or for `E2E_CMD` itself.

What the runner does do is **ask**. Two places open a TCP connect to this address, and neither one
ever starts anything:

- `sdd preflight` — a dead app is a **failure** when `E2E_CMD` is set (a gate is about to run that
  suite against an app that is not there) and a **warning** when it is not (nothing automatic runs
  against it, but the exploratory session will still need it up);
- `gate_QA`, but only **after** `E2E_CMD` has already come back non-zero. A red e2e over a refused
  address stops the line with `kind: app-down` and the address named, instead of buying another
  session for a machine no session can fix. The gate never probes ahead of the e2e, so a repo whose
  e2e brings its own server up — or whose app only answers while the suite runs — is never blocked
  for a state that did not matter.

Anything the probe cannot decide reads as *unknown* and changes nothing: an empty value, a URL that
is not `http://`/`https://` with a host, a bash without `/dev/tcp`, no `timeout(1)` on PATH, a
connect that times out instead of answering. Only a connection actively **refused** counts as down.

## Artifact paths

| Key | Required | Default | What it is |
|---|---|---|---|
| `HANDOFF_DIR` | no | `docs/handoffs` | Root of the durable state. Each mission becomes `<HANDOFF_DIR>/<YYYYMMDD>-<slug>/`. **Committed.** |
| `QA_DOCS_PATH` | no | `docs/qa` | Where the `qa-report`/`qa-execution` skills write. The runner does not write here — the skills own it. |
| `TODO_FILE` | no | `TODO.md` | Destination for out-of-scope findings. |

## Models per phase

Opus by default in the judgement phases; Sonnet where Opus would be waste — an **explicit
exception, never a silent one** (kaizen K3). Values: any alias `claude --model` accepts.

| Key | Default | Why |
|---|---|---|
| `MODEL_EXEC` | `opus` | TDD and implementation decisions. |
| `MODEL_QA` | `opus` | Exploratory judgement is the expensive part of QA. |
| `MODEL_REVIEW` | `opus` | The `codereview` skill routes internally by severity. |
| `MODEL_DOCS` | `opus` | Writing documentation that does not lie takes a model. |
| `MODEL_PUBLISH` | `sonnet` | Assembling a PR body from finished handoffs is mechanical. |
| `MODEL_TICKET` | `sonnet` | Calling `acli` with fields already decided is mechanical. |
| `MODEL_KAIZEN` | `opus` | Used only by the kit's own kaizen loop (`sdd kaizen`, kit repo): judging the previous kit change and planning the next takes judgement. |

## Limits and policy

| Key | Default | What it is |
|---|---|---|
| `QA_MAX_ITER` | `3` | Rounds of the QA⇄EXEC loop before `BLOCKED`. Protects against an endless "the fix breaks another journey". Careful raising it: one round is **up to 3 sessions** (one per sub-step), so the phase session cap is `QA_MAX_ITER × 3` — 9 by default. ⚠️ That sentence promised sessions and the runner counted **laps of its loop** until `20260826`: the retry inside a lap opened a second session without raising the counter, so 9 was really 18. Measured on `20260825-frete-cif-fob` — 9 laps, 3 of them buying a retry, 12 sessions, US$ 11.27. The ceiling reads sessions now; the bound is `QA_MAX_ITER × 3 + 1`, because it is tested once per lap and a lap already admitted may still buy its retry. |
| `REVIEW_MAX_ITER` | `3` | Review **rounds in total**, derived from the `40-review-r<N>.md` files on disk — re-running `sdd run` does not reset it. A second guard counts sessions inside one invocation, for the session that writes no round at all. `--phase REVIEW` is exempt: that is a human asking for one specific round with their eyes on it. ⚠️ Since `20260901-o-revisor-so-acha` a round only **finds**: r1 comes out at **B by design** whenever there is something to fix, the fix lands as an `R<n>` increment executed by EXEC, and r2 re-grades it independently. So the normal path spends **two** rounds, not one, and `3` leaves exactly one spare. Raise it only with the `turns` field of the ledger in hand — more rounds of finding is a different purchase from more rounds of fixing. |
| `EXEC_MAX_RETRY` | `1` | Retries per increment before `BLOCKED`. |
| `BUDGET_PER_PHASE_USD` | `15` | Goes into `--max-budget-usd` per session. A damage cap, not a budget. Applies to the phases with no key of their own: DOCS, PR, TICKET, KAIZEN. |
| `BUDGET_EXEC_USD` | `25` | Cap for an EXEC session — one increment in TDD, which reads, writes, runs the suite and commits. |
| `BUDGET_QA_USD` | `25` | Cap for a QA session. One QA **round** is up to three of them, so the round costs up to `3 ×` this. |
| `BUDGET_REVIEW_USD` | `40` | Cap for a REVIEW round. Still the most expensive phase — the `codereview` skill routes by severity — but since `20260901-o-revisor-so-acha` the session **no longer fixes inside itself**: it finds, grades honestly and writes `R<n>` increments the EXEC phase closes in a session of its own. The number stays `40` on purpose, and lowering it is not the obvious win it looks like: a cap that bites **mid-session** throws the money away with nothing on disk, because the round is only worth something once `40-review-r<N>.md` is committed. The distribution of a find-only session is what decides the next number, and it is now measurable — `turns` and `cost_usd` per REVIEW row, `review loop US$ X (N%)` per mission in `sdd autonomy --by-mission`. |
| `PUBLISH_ON_REVIEW_BLOCKED` | `off` | `draft` ⇒ a blown review opens a **draft** PR with the current grade and the open items, instead of stopping dead. The runner records that it lowered its own bar, **once per run**: a `DEGRADED` line in the mission's `pipeline.log` and one `event:"degraded"` / `kind:"review-to-draft"` row in the autonomy ledger. The draft PR gets **one** chance: if its own gate fails too, the run ends on `blocked` / `budget-exhausted` in **REVIEW** — the phase whose ceiling was actually blown — instead of handing REVIEW back and going round again. |
| `ON_ESCALATION_CMD` | *(empty)* | The pager. A shell command the runner executes — `bash -c`, stdin closed, output to stderr — on **every escalation that ends the run with rc 3**: `increment-blocked`, `dirty-tree`, `handoff-blocked`, `app-down`, `budget-exhausted`, `no-progress`. Its environment carries `SDD_REASON` (the ledger `kind`), `SDD_PHASE`, `SDD_MISSION`, `SDD_PROJECT` and `SDD_GATE_WHY` (the gate's sentence). Empty ⇒ the line stops in silence, as it did before L6 of the 2026-09-03 audit — which measured zero notification sites in the runner and a human learning the line had stopped by watching `tail -F`. The projection (`--dry-run`) never runs it; a hook that exits non-zero is a warning, never a second failure, because the escalation is already in the journal and the ledger. `review-to-draft` is a `degraded` row, not an rc 3, and gets no pager. Example: `ON_ESCALATION_CMD='notify-send "sdd $SDD_MISSION" "$SDD_PHASE stopped: $SDD_REASON"'`. |
| `PERMISSION_MODE` | `acceptEdits` | The ceiling. `bypassPermissions` is **never** the kit's default. |
| `ALLOWED_TOOLS` | `Bash` | Goes into `--allowedTools`, as a **single argument**. **Required in practice**: `acceptEdits` auto-approves file edits, but **not** `Bash` — without this key the phase session cannot run the suite nor commit, and the EXEC phase becomes unsatisfiable. Verified in the fixture mission `20260814-dry-run-completo`. The kit has only exercised the default; if you need more than one tool, check the format your `claude` accepts before trusting the gate. |

⚠️ Trade-off, declared: raising `BUDGET_PER_PHASE_USD` does **not** raise EXEC, QA or REVIEW —
they read their own key. One number for every phase was either too low for REVIEW, where the
session dies mid-round and the money is spent with nothing on disk, or too high for PR, where it
stopped capping anything. Four keys instead of one is the price of the cap meaning something in
both places. ⚠️ The paragraph sits **below** the table and not between two of its rows: a
paragraph inside a GFM table ends it, and the rows after it stop being rows at all — three keys
rendered as one run-on sentence until this was caught in review.

## JIRA

| Key | Default | What it is |
|---|---|---|
| `JIRA_ENABLED` | `false` | `true` ⇒ the TICKET phase runs (`/ticket open`) and `sdd close` closes the issue post-merge. Requires `.jira-project` in the target repo (read by the `ticket` skill). |

When `JIRA_ENABLED=true`, `00-missao.md` **must** have `versao:` filled in — the version label is a
human decision, never headless. The PLAN-AUTO gate (criterion `e`) checks this.

### Not a config key: context compaction

There is no key for `--autocompact`, because the runner never passes it. One session per phase
already keeps the heaviest window at **289k tokens with zero compactions** (measured across the 6
sessions of the SQ-97 pilot on `claude-opus-5`; see
[`../docs/pipeline.md`](../docs/pipeline.md)), so the lever has never been needed. It is written
down here so that whoever first hits a crowded window adds the key on a **measurement** against
that baseline, instead of adding one on faith.

### Not a config key: `SDD_ACLI_BIN`

`sdd close` verifies the close against JIRA itself instead of trusting the session's exit code, and
it asks with `${SDD_ACLI_BIN:-acli}`. The override exists so a sensor can model "no acli on this
machine" without uninstalling one; on a real machine you never set it, unless the CLI lives
somewhere off `PATH`. Environment variable and not a `.sdd/config.sh` key, for the same reason as
`SDD_STATE_DIR` below: it describes the machine, not the project.

The question it asks is `key = <issue> AND statusCategory = Done` — the **category** and never the
status name, because the name is localized per project and per language while the category is not.
It is asked twice, before the session and after it: an answer that is not a JSON array means the
tool could not be reached (expired auth is the ordinary way), and `sdd close` refuses **before**
spending a paid session rather than after. An issue already `Done` is reported as such and costs no
session at all.

### Not a config key: `SDD_STATE_DIR`

The autonomy ledger is **global**, not per-repo: `${SDD_STATE_DIR:-$HOME/.sdd}/autonomy-log.jsonl`.
It is an environment variable and deliberately not a `.sdd/config.sh` key — a per-repo key would
suggest a per-repo file, and "maturity across projects" cannot be measured in one. The suite
exports it to a temporary directory so no test can touch the real ledger.

## Minimal example (project with no UI and no JIRA)

```bash
PROJECT_NAME="my-lib"
DEFAULT_BRANCH="main"
TEST_CMD="pytest -q"
JIRA_ENABLED=false
```

Everything else falls back to the default. The QA gate becomes `qa: skipped` automatically when
there is no `E2E_CMD` and the diff touches nothing user-visible.
