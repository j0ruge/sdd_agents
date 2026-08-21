# Schema for `.sdd/config.sh`

The file is **pure bash** — the runner sources it. No logic: assignments only.
Created by `sdd install` from [`examples/sales_quote.conf`](examples/sales_quote.conf).

Rule: if a required key is empty, `sdd preflight` fails **before** spending a session.

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
| `E2E_DIR` | no | `e2e` | Where `sdd-qa` commits new specs. |

The runner has exactly these three. A separate lint or build command belongs **inside** `TEST_CMD`:
a key the runner never reads is a promise the user cannot collect on, and this schema carried five
such keys — for a lint, a build and bringing the environment up — until they were removed. Adding
one back means wiring the read in `bin/sdd` in the **same** commit.

## Running application (QA phase)

| Key | Required | Default | What it is |
|---|---|---|---|
| `APP_URL` | only with `E2E_CMD` | empty | URL `agent-browser` opens in the exploratory sessions. |

The runner does not bring the environment up: it assumes the app is already running. Starting it
(`docker compose up -d` and friends) is a step for whoever runs `sdd`, or for `E2E_CMD` itself.

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
| `QA_MAX_ITER` | `3` | Rounds of the QA⇄EXEC loop before `BLOCKED`. Protects against an endless "the fix breaks another journey". Careful raising it: one round is **up to 3 sessions** (one per sub-step), so the phase session cap is `QA_MAX_ITER × 3` — 9 by default. |
| `REVIEW_MAX_ITER` | `3` | Review **rounds in total**, derived from the `40-review-r<N>.md` files on disk — re-running `sdd run` does not reset it. A second guard counts sessions inside one invocation, for the session that writes no round at all. `--phase REVIEW` is exempt: that is a human asking for one specific round with their eyes on it. |
| `EXEC_MAX_RETRY` | `1` | Retries per increment before `BLOCKED`. |
| `BUDGET_PER_PHASE_USD` | `15` | Goes into `--max-budget-usd` per session. A damage cap, not a budget. Applies to the phases with no key of their own: DOCS, PR, TICKET, KAIZEN. |
| `BUDGET_EXEC_USD` | `25` | Cap for an EXEC session — one increment in TDD, which reads, writes, runs the suite and commits. |
| `BUDGET_QA_USD` | `25` | Cap for a QA session. One QA **round** is up to three of them, so the round costs up to `3 ×` this. |
| `BUDGET_REVIEW_USD` | `40` | Cap for a REVIEW round. The most expensive phase: the `codereview` skill routes by severity and the session fixes inside itself. |
| `PUBLISH_ON_REVIEW_BLOCKED` | `off` | `draft` ⇒ a blown review opens a **draft** PR with the current grade and the open items, instead of stopping dead. The runner records that it lowered its own bar, **once per run**: a `DEGRADED` line in the mission's `pipeline.log` and one `event:"degraded"` / `kind:"review-to-draft"` row in the autonomy ledger. The draft PR gets **one** chance: if its own gate fails too, the run ends on `blocked` / `budget-exhausted` in **REVIEW** — the phase whose ceiling was actually blown — instead of handing REVIEW back and going round again. |
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
