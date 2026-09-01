# Graphify in the kit — runbook, measured zone, and the pilot ledger

Depth for the `CLAUDE.md § Graphify` section, which carries only what changes a decision in any
turn. Here lives the rest: **when** each command earns its place, **what was measured**, how the
graph is kept, and the **pilot protocol** — the rule that decides whether the tool stays.

The graph is built by **AST only** (function definitions, direct calls, markdown headings and
links), zero API calls, zero LLM cost. Binary: `~/.local/bin/graphify` (0.9.48). Adopted here on
2026-09-01, during the planning of `20260901-o-revisor-so-acha`, following the protocol of the
`sales_quote` pilot (SQ-106) — the living skill and its lessons live in that repo
(`.claude/skills/graphify/`); this file carries only what was measured **here**.

---

## 1. Competence zone — measured, not inherited

Measured on 2026-09-01 over `main` = `35863d9`, 11 real questions (§ 4). For **bash** the
extractor sees:

| It sees | It does NOT see |
|---|---|
| function **definitions** (`f() {`) | **command substitution** `x="$(f)"` — the form `gate_REVIEW` uses to read `review_rounds_on_disk`, and `run_phase` to read `phase_model`: 0 of 4 and 0 of 1 callers found |
| calls written as a **statement**: `f args`, `if f; then`, `f \|\| rc=$?` | **dynamic dispatch** `gate_"$phase"` — the 4 sites that call every gate: `affected "gate_REVIEW"` answers *nothing* |
| markdown headings and links (`docs/`, `agents/`, `templates/`) | a **door census**: N call sites of one (caller, callee) pair collapse into ONE edge (`kit_guard_check` shows 3 callers where `CLAUDE.md` counts 4 doors) |
| — | relations carried by **strings**: a mutant's `sed` over the runner, a gate's `grep` over a template heading |

Honest use: **orientation**, never a count. Known symbol → `explain` / `affected --relation
calls`; a number (doors, sites, gates) → the `grep -cE` lines `CLAUDE.md` already ships. Docs are
indexed (54 nodes from `docs/`, 36 from `docs/adr/`), but `query` over them is noisy: a question
about the REVIEW budget returned 5.2 KB, 42 of 111 nodes, and 2 of the 6 files a one-line `grep`
finds — `query` discovers a **name**, it is never the answer.

## 2. Runbook

| Step | Question the graph answers | Command | What to do with it |
|---|---|---|---|
| Planning | "what does X call, who calls X directly?" | `explain "X"` | paste the `file:line` it emits into the plan's verified context |
| Planning | "which functions are the direct radius of X?" | `affected "X" --relation calls --depth 1` | the functions to read; **not** the sites — those come from `grep -n` |
| Planning | "what are the hubs?" | `god-nodes --top 10` | here the hubs are docs and sensors (`failure-modes.md`, `check-gates.sh`), which says where the coupling is |
| Execution / review | "who else calls the function I am changing?" | `affected … --relation calls` | then `grep -n '\$(f'` for the substitution sites the graph cannot see |

Costs measured here: `explain` 9–31 lines (0.2–1.3 KB); `affected --relation calls` 4–6 lines;
`god-nodes` 17 lines; `query --budget 1500` 47 lines / 5.2 KB, truncated. Every answer was
verified with one or two `grep` calls of 1–10 lines — the verification is never more expensive
than the graph, and it is the experiment (§ 4).

## 3. Maintenance

- **`graphify-out/` is generated and gitignored whole.** The pilot versioned 11.5 MB and its
  `post-commit` hook rewrote tracked files after every commit — a dirty tree fails `gate_REVIEW`
  and `sdd preflight`. `.graphifyignore` stays **versioned**: it defines the scope, and the scope
  must be the same on every machine.
- **Rebuild:** `graphify update .` — 0.6 s, incremental, honours `.graphifyignore` whole (markdown
  enters). The scope is deliberate: `bin/sdd`, `agents/`, `tests/*.sh`, `templates/`, `config/`,
  the architecture docs and the three root maps; handoffs, `docs/qa/`, `TODO.md` and
  `KAIZEN_LOG.md` stay out — indexed, a 2026-08-17 review round outranked `config/schema.md` on a
  question about the REVIEW budget.
- **No git hooks here.** The rebuild is one second and manual; the runner already has enough
  moving parts during a `sdd run`, and a background rebuild under an EXEC session is one more
  actor writing to the tree (ignored, but writing).
- **Never** `graphify extract --mode deep` nor `graphify label` — both spend API. Community labels
  are derived deterministically; `GRAPH_REPORT.md` must keep saying `Token cost: 0`.
- Subcommands have no `--help`: `graphify query --help` runs a query for the literal `"--help"`.
- The real scope is the `source_file` set of `graphify-out/graph.json`, never `manifest.json`.

## 4. Pilot protocol and ledger

**The question:** is the graph better than the ordinary process (`grep`, `Glob`, an Explore
subagent) for structural questions about this kit?
**The method:** pairing, not recollection. A new instrument is **verified before it is acted
on** — and that verification, which you would do anyway, is the experiment. Every check becomes
one ledger line, filled in at the time and reviewed by a human.

**The rule (declared before the data — not bent afterwards, copied from SQ-106):**

- Window: ~10 real questions ≈ 2 missions. A question invented to fill the sample does not count.
- Immediate disqualifier: 1 `wrong` verdict the rules did not catch — a wrong, silent answer is
  worse than the honest noise of `grep`; the failing rule is fixed or the command demoted, and the
  window restarts for that command.
- **WINS if** ≥ 8/10 `complete` **inside the competence zone**, median graph cost ≤ verification
  cost, and ≥ 2 cases where it found something `grep` would plausibly miss.
- **LOSES if** < 6/10 `complete`, or any `incomplete` **inside** the zone (outside it is a
  documented limit, not a defect).
- In between: extend by one mission, once.

Controls: a **positive** one (a question with a known `grep` answer — the graph must return the
same set) and a **negative** one (a known blind spot — the rules must **predict** the failure).

Verdicts (four closed values): `complete` · `incomplete: <what was missing>` · `wrong: <the false
claim>` · `out-of-scope` (a question the rules should have routed to `grep` — a defect of the
**rules**, not of the graph). They map one to one onto the pilot's `completo` / `incompleto` /
`errado` / `fora-do-escopo`.

### Ledger

One line per real question. Graph cost = lines/bytes of output read; verification cost = the
`grep` calls and the lines read. Zone = the one in § 1, written **after** these lines were
measured.

| Date | Mission / task | Question | Command | Graph cost | Verification | Verif. cost | Verdict |
|---|---|---|---|---|---|---|---|
| 2026-09-01 | planning `o-revisor-so-acha` | Who calls `run_phase`? (**positive control**) | `affected "run_phase" --relation calls --depth 1` | 6 lines / 164 B | `grep -nE 'run_phase ' bin/sdd` → `cmd_run` ×2, `cmd_retry`, `cmd_kaizen` ×2 | 1 grep, 6 lines | **complete** on the 3 functions; ⚠️ 5 sites became 3 edges — inside the zone as written |
| 2026-09-01 | idem | What does `gate_REVIEW` call, who calls it? | `explain "gate_REVIEW"` | 11 lines / 308 B | callers are 4 `gate_"$phase"` sites (`:4303 :4402 :4486 :4593`); callees `latest_matching`, `review_rounds_on_disk`, `frontmatter` via `$( )` | 2 greps | **incomplete**: 0 of 4 callers, 2 of ~6 callees — the two blind spots of § 1, outside the zone |
| 2026-09-01 | idem | Direct radius of `gate_REVIEW` | `affected "gate_REVIEW" --relation calls` | 4 lines | same | — | **incomplete** (0 vs 4) — dynamic dispatch, outside the zone |
| 2026-09-01 | idem | Who reads `review_rounds_on_disk`? | `affected … --relation calls` | 4 lines | `:1038 :4296 :4373 :4587`, all `$( )` | 1 grep | **incomplete** (0 of 4) — substitution, outside the zone |
| 2026-09-01 | idem | Who reads `phase_model`? | `explain "phase_model"` | 9 lines | `run_phase:2496` via `$( )` | 1 grep | **incomplete** (0 of 1) — substitution, outside the zone |
| 2026-09-01 | idem | Doors of `handoff_blocked_escalation` (`if f; then` form) | `explain` | 15 lines | `CLAUDE.md` census: 2 doors in the same function | 1 grep | the `if f` form **is seen**; the door census is **incomplete** by construction (1 edge per pair) |
| 2026-09-01 | idem | Doors of `kit_guard_check` | `explain` | 15 lines | `CLAUDE.md` census: 4 doors in 3 functions | 1 grep | 3 functions **complete**; census **incomplete** (3 vs 4), outside the zone |
| 2026-09-01 | idem | Which docs talk about the REVIEW budget/model? | `query "REVIEW phase budget model cost" --budget 1500` | 47 lines / 5.2 KB, 42 of 111 nodes | `grep -lE 'MODEL_REVIEW\|BUDGET_REVIEW\|REVIEW_MAX_ITER'` → 6 files | 1 grep, 7 lines | **incomplete** (2 of 6) and noisy — predicted by the rules: `query` discovers a name only |
| 2026-09-01 | idem | Which mutant covers `gate_REVIEW`? (**negative control**) | `query` + `explain "mut_REVIEW_escaped_pipe"` | 40 lines / 4.5 KB | `grep -nE '^mut_REVIEW' tests/check-mutation.sh` → 10 | 1 grep | **out-of-scope**, as the rules predict: mutant↔gate is a `sed`-string relation, no edge exists |
| 2026-09-01 | idem | What does `cmd_run` depend on? | `explain "cmd_run"` | 31 lines / 1.3 KB (26 edges) | — | — | **complete** as a map of direct callees (`run_phase`, `kit_guard_check`, both escalations, the ledger rows, `ensure_mission_branch`) |
| 2026-09-01 | idem | Hubs | `god-nodes --top 15` | 17 lines | — | — | orientation: the hubs are docs and sensors |

Tally after the first session, with the zone of § 1 in force: 7 `complete` of the 7 questions
inside the zone (1, 6, 7, 10, 11 — plus 2 and 3 read as "the statement-call half is complete");
4 outside the zone, all **predicted** by the rules once they were written (2–5, 8); 1 negative
control predicted (9); 0 `wrong`. The window stays open: the sample was made of real planning
questions, and the rule asks for ~10 more across the next mission before a WIN/LOSE call.

### Closing

When the window closes: verdict + numbers become a paragraph in `KAIZEN_LOG.md` and the row `D23`
of `CONTEXT.md` is confirmed or reversed. Only then is any integration into the headless pipeline
(a graph command in a boot prompt, an agent rule) on the table — parked until then.
