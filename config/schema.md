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
| `LINT_CMD` | no | empty | Runs in the REVIEW gate when set. |
| `BUILD_CMD` | no | empty | Runs in the REVIEW gate when set. |

## Running application (QA phase)

| Key | Required | Default | What it is |
|---|---|---|---|
| `APP_URL` | only with `E2E_CMD` | empty | URL `agent-browser` opens in the exploratory sessions. |
| `DEV_UP_CMD` | no | empty | Brings the environment up before QA (e.g. `docker compose up -d`). Empty ⇒ the runner assumes it is already up and warns if `APP_URL` does not answer. |
| `DEV_READY_CMD` | no | empty | Command returning 0 when the app is ready (e.g. `curl -sf $APP_URL`). The runner polls for up to `DEV_READY_TIMEOUT` seconds. |
| `DEV_READY_TIMEOUT` | no | `90` | Seconds to wait for `DEV_READY_CMD`. |

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

## Limits and policy

| Key | Default | What it is |
|---|---|---|
| `QA_MAX_ITER` | `3` | Rounds of the QA⇄EXEC loop before `BLOCKED`. Protects against an endless "the fix breaks another journey". Careful raising it: one round is **up to 3 sessions** (one per sub-step), so the phase session cap is `QA_MAX_ITER × 3` — 9 by default. |
| `REVIEW_MAX_ITER` | `3` | Review sessions in total before `BLOCKED`. |
| `EXEC_MAX_RETRY` | `1` | Retries per increment before `BLOCKED`. |
| `BUDGET_PER_PHASE_USD` | `15` | Goes into `--max-budget-usd` per session. A damage cap, not a budget. |
| `PUBLISH_ON_REVIEW_BLOCKED` | `off` | `draft` ⇒ a blown review opens a **draft** PR with the current grade and the open items, instead of stopping dead. |
| `PERMISSION_MODE` | `acceptEdits` | The ceiling. `bypassPermissions` is **never** the kit's default. |
| `ALLOWED_TOOLS` | `Bash` | Goes into `--allowedTools`, as a **single argument**. **Required in practice**: `acceptEdits` auto-approves file edits, but **not** `Bash` — without this key the phase session cannot run the suite nor commit, and the EXEC phase becomes unsatisfiable. Verified in the fixture mission `20260814-dry-run-completo`. The kit has only exercised the default; if you need more than one tool, check the format your `claude` accepts before trusting the gate. |

## JIRA

| Key | Default | What it is |
|---|---|---|
| `JIRA_ENABLED` | `false` | `true` ⇒ the TICKET phase runs (`/ticket open`) and `sdd close` closes the issue post-merge. Requires `.jira-project` in the target repo (read by the `ticket` skill). |

When `JIRA_ENABLED=true`, `00-missao.md` **must** have `versao:` filled in — the version label is a
human decision, never headless. The PLAN-AUTO gate (criterion `e`) checks this.

## Minimal example (project with no UI and no JIRA)

```bash
PROJECT_NAME="my-lib"
DEFAULT_BRANCH="main"
TEST_CMD="pytest -q"
JIRA_ENABLED=false
```

Everything else falls back to the default. The QA gate becomes `qa: skipped` automatically when
there is no `E2E_CMD` and the diff touches nothing user-visible.
