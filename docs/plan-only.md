# PLAN-only — the planning half, without the headless pipeline

How to adopt `00-missao.md` / `01-plano.md` / `checkpoint.md` in a repository that is **not** going
to run `sdd run`, and how to set up a brand-new project for it.

## Why this mode exists

`PLAN` is a declared phase (`PHASES="PLAN TICKET EXEC QA REVIEW DOCS PR"`), and the runner refuses
to execute it:

> `# PLAN is interactive by design: the human takes part in the grill. The runner does not boot`
> `# the planner.`

So the planning half was already detached. What this document adds is the other half of the
observation, **measured on `sales_quote`, mission `20260908-cliente-fala-com-o-erp-e-o-pdf-diz-de-onde`**:
a plain interactive session read `checkpoint.md` and executed all seven increments by hand —
TDD, sabotage per sensor, checkpoint updated as the last act of each one — without `sdd run` ever
being called. The artifacts carry enough contract to drive a human-present session on their own.

That makes PLAN-only a real adoption tier, not a degraded one:

| | PLAN-only | Full pipeline |
|---|---|---|
| Artifacts | `00-missao.md`, `01-plano.md`, `checkpoint.md` | all of them, through `50-pr.md` |
| Who executes | an interactive session, reading the checkpoint | `sdd run`, one headless session per phase |
| Needs a trustworthy `TEST_CMD` | no — the human reads the failures | **yes**, it is the only sensor the gates run |
| Needs budgets, `QA_MAX_ITER`, `MODEL_*` | no | yes |
| Needs `sdd preflight` | **no** — see the warning below | yes |
| Cost of adopting | a config file and a symlink | that, plus a preflight that spends real money |

## Setting up a new project

```bash
cd ~/repos/<project>
sdd install                    # writes .sdd/config.sh and copies the agents
sdd-link-agents                # replaces those copies with symlinks into this kit, and gitignores them
$EDITOR .sdd/config.sh
mkdir -p docs/handoffs
```

In PLAN-only mode only these keys matter — leave the rest as `sdd install` shipped them, commented:

| Key | Why it matters here |
|---|---|
| `PROJECT_NAME` | names the mission in the artifacts |
| `DEFAULT_BRANCH` | **derive it, never assume**: `git symbolic-ref --short refs/remotes/origin/HEAD`. `sales_quote` is `develop`, not `main` |
| `OUTPUT_LANG` | the language of the artifacts; the kit itself stays English |
| `HANDOFF_DIR` | where missions live, normally `docs/handoffs` |
| `TODO_FILE` | where the planner parks out-of-scope findings |
| `JIRA_ENABLED` | `true` also makes `gate_PLAN` require a filled `versao:` |

Then add the pointer block to the target's `CLAUDE.md` (model at the end of this document), and the
repository is ready.

⚠️ **Do not run `sdd preflight` in this mode.** It fires a real headless session (capped at US$ 1)
to prove that *headless phases* can execute a command — which is exactly the half this mode does
not use. Its other job, comparing the installed agents against the kit byte for byte, is moot once
they are symlinks.

## Per mission

```bash
/sdd-plan                      # interactive: brainstorm → grill → 00-missao, 01-plano, checkpoint
sdd why <mission> PLAN         # evaluates gate_PLAN — free, spends no session
sdd approve <mission>          # writes 'aprovacao: humano-YYYY-MM-DD' and commits it
```

`sdd why` is the cheap validator this mode needs. Without a runner ever booting, nothing else looks
at the artifacts, and format drift enters in silence.

### The `aprovacao:` trap, measured

`gate_PLAN` accepts **only** `auto` or `humano-*`:

```bash
case "$approval" in
  auto)     : ;;
  humano-*) : ;;
  *) GATE_WHY="... it must be 'auto' ... or 'humano-YYYY-MM-DD': run 'sdd approve $MISSION'" ;;
esac
```

The `sales_quote` mission cited above shipped with

```yaml
aprovacao: humano aprovou o plano em 2026-09-08 (grill de 8 perguntas + DDD + Kaizen)
```

— prose that reads as approval and that the gate **rejects**, because `humano-*` needs the hyphen.
It cost nothing there only because the runner was never invoked. Write the value with
`sdd approve`, never by hand: that is the failure the command exists to end.

## Why the target repository holds no templates

`sdd install` deliberately ships the agents and the config to the target, and **never the
templates**. The runner injects their absolute path into each phase's boot prompt, and
`sdd-planner` says so itself:

> a bare `templates/` resolves to nothing in a target repo, since the kit installs the agents and
> the config there but never the templates

In PLAN-only mode there is no runner and therefore no boot prompt, so the `/sdd-plan` command takes
that job: it names `$SDD_HOME/templates/` before the planner starts. That is the whole reason the
command exists — without it, an interactive session either guesses the path or writes the
artifacts from memory, and their headings are the contract the gates parse.

## Why the agents are symlinks

`sdd install` copies, and refuses to overwrite a copy that differs — good for a target pinned to a
known-good version, wrong for a kit under active development, where every improvement would need a
`--force` per repository.

Symlinking costs nothing to the runner: `sdd install` and `sdd preflight` compare with `cmp -s`,
which reads **through** the link and compares content, so a symlink reports as identical to the
source. No change to `bin/sdd` was needed.

They are **gitignored** rather than committed: the link carries this machine's absolute path, and a
committed symlink is dangling in every other checkout — broken in silence, which is the worst
shape. Recreating them is one command, named in the target's `CLAUDE.md`.

## The `CLAUDE.md` block for a target repository

Pointer, not recipe — the recipe is this file:

```markdown
## Planejamento de missão (kit `sdd`)

Missões grandes são planejadas antes de codar, e o plano vira três artefatos em
`docs/handoffs/<AAAAMMDD-slug>/`: `00-missao.md` (a intenção), `01-plano.md` (o como,
autocontido) e `checkpoint.md` (a tabela de incrementos, **lida por máquina**).

- Começar uma missão: `/sdd-plan` — sessão interativa, com brainstorm e grill.
- Validar o plano sem gastar sessão: `sdd why <missao> PLAN`.
- Aprovar: `sdd approve <missao>` — **nunca** editar `aprovacao:` à mão.

O kit vive em `~/repos/sdd_agents` e a receita completa está em
[`docs/plan-only.md`](file:///home/joruge/repos/sdd_agents/docs/plan-only.md) de lá. Os agentes em
`.claude/agents/sdd-*.md` são symlinks para o kit e **não** são versionados: num clone novo,
rode `sdd install && sdd-link-agents`.
```
