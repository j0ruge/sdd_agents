# 0009 — The genre gains a third value, and the hat's frontier gains a project variable

Date: 2026-09-18 · Status: accepted

Spec: docs/handoffs/20260918-a-excecao-do-chapeu-e-o-genero-diferido/00-missao.md

Amends: 0006

## Context

Two things the kit got wrong in the same direction: it had the right datum on disk and no way to
read it, so it either stopped correct work or made a decision invisible.

### The hat stops work the target's own rules demand

`writes:` in `agents/<hat>.md` is a constant of the **kit**: it says what a hat owns wherever the
kit is installed. The obligation that crosses it belongs to the **target**. Measured on the pilot
repo on 2026-09-17, three occurrences and two hats:

- a QA session of 759 s / **US$ 11,32** stopped in `BLOCKED` for touching
  `.github/workflows/e2e-staging.yml` — that repo's own rules require the case floor there to be
  revised whenever a spec is added;
- a DOCS session of 916 s / **US$ 6,24** stopped for 18 correct lines in `.claude/napkin.md`, where
  that repo's `CLAUDE.md` says a gotcha belongs;
- a third stopped for 30 correct lines in `PRODUCT.md`, and that one was repaired **literally**:
  `796e334` put `PRODUCT.md` into the `writes:` of every project that installs the kit. `DESIGN.md`,
  sibling of the same rule, still blocks.

The repair is the diagnosis. With nowhere for a project to say *"my rules oblige this path"*, the
only two moves are to let the run die or to widen the hat for **everyone** — a list that grows one
name per project, in a file no project owns.

### A bug a human decided has nowhere to live

ADR 0006 created `Closable by:` with two values and modelled the question *"who **can** close
this?"*. On SQ-129 the question was a different one: *"who **pays**?"*. A human decided four bugs
(`383df146`, a `## Decisao` section in each body) that an agent **can** close and that the mission
in flight would not pay for. Neither value fitted:

- `agent` put all four back in front of `gate_QA` of a mission already running;
- `human` is the only value that never blocks, so it became the hiding place — and `human` means
  *nobody in this pipeline can act on this*, which was false.

What actually happened: a convention was invented in the footer of each file (*"stays `human` until
the mission that pays for it is opened; on opening, change to `agent`"*), and the change back became
increment `I6` of the next mission — a manual step somebody has to remember, with nothing on disk
that would notice if they forgot.

### And in a fresh repo the field does not exist at all

`grep -rn Closable ~/.claude/skills/qa-*` answers **0**, and the pilot target's own
`docs/qa/templates/bug.md` has no such line either. The field reaches disk only when `sdd-qa` marks
a file by hand. Anchor 3 treats an absent genre as blocking — deliberately, so that a legacy
registry is not switched off in one step — so in a new target **every** bug the skills write is born
blocking, and a QA lap is paid before anyone works out why.

## Decision

**1. A third genre, `deferred`, in the same field.** Same extractor, one more alternative, and one
new rule: the passing reason **names every deferred bug, on every evaluation**. `human` passes
silently because nobody in this pipeline can act on it; `deferred` passes **loudly** because
somebody will, in a mission that has not opened yet. The line between them is *who can* versus *who
pays*. `agents/sdd-qa.md` § 5.1 requires the decision to be written in the bug's own body — a
`## Decision` / `## Decisao` section with the date and who decided — before an agent may write the
value; *"we are not doing this now"* without a recorded decision is `agent`.

**2. One config key, `HAT_WRITES_EXTRA`, by hat and by path.** Grammar
`hat: path[, path]; hat: path`, summed into `hat_writes` for the hat it names and no other. Guarded
on the model of `adr_dir_ok` and written positively: relative, no `..`, literal components, and no
metacharacter except a trailing `/**` on a directory that is named. A hat the kit does not ship is
refused by name. Validated in `load_config`, before a session is spent.

**3. `sdd install` seeds the field and `sdd preflight` asks for it.** Diff-first like the agent
mirrors: bare `install` shows the missing line, `--force` inserts it below the first
`- **Status:**`, idempotently, and refuses to touch a template that is not the shape the skill
writes.

**This ADR amends 0006; it does not overturn it.** The scope of Anchor 3 is unchanged — it still
counts every open bug in the registry, not only this mission's. 0006's alternative (A), *"count only
the current mission's provenance"*, stays refused with the argument it was refused on: it *"trades a
loop for silent debt"*. The gemba of this mission is that the real SQ-129 case was never *"a bug from
another mission"* — it was *"an agent-closable bug this mission decided not to pay for"*, which is a
gap in the **enum**, not in the anchor's scope.

## Alternatives discarded

- **`agent@<mission-slug>` instead of a third value.** Complete poka-yoke — the payer is named — but
  a closed enum becomes an open pattern, and a slug that does not match any mission **fails open**:
  the gate skips it and nobody learns. The mitigation (validate the slug against the missions on
  disk) forces the paying mission to be planned *before* a bug may be deferred, and on SQ-129 that
  mission did not exist yet. That is the case the value is for.
- **A separate field, `Decided:` / `Owner:`.** A second extractor over the same file, every
  looseness of which fails open, doubling the surface that ADR 0006 needed three mutants to close.
  The genre is one question and belongs in one field.
- **One config key per hat** (`HAT_WRITES_SDD_QA`, …). Eight keys in `config/schema.md` and eight
  defaults in `load_config`, and the list that grows one name per project simply moves house.
- **A file, `.sdd/hats/<hat>.writes`.** A second place where configuration lives, which `preflight`,
  `sdd census` and `config/schema.md` would all have to learn. `.sdd/config.sh` is the one place a
  target speaks to the kit.
- **By directory rather than by path** for the exception. The three measured occurrences refuse it:
  `.claude/rules/**` and `.claude/napkin.md` are different decisions, and a project may want one
  without the other.
- **`sdd preflight` alone, without the seed.** Poka-yoke on the obvious step only: a new repo still
  pays a QA lap before anybody reads the preflight line.
- **`sdd-qa` seeds the field itself.** A sentence in a prompt, paid for in a session, and it depends
  on a QA phase running before the first bug is filed — which is the case that has not happened yet
  in a fresh repo.

## Consequences

- `deferred` is the **second** permissive value in an anchor where every looseness fails open. It
  inherits the three blindages (read from the field, whole word, outside a fence) by construction —
  the extractor did not change — and that inheritance is asserted with the new value rather than
  assumed, plus two mutants of its own.
- The field's shape is now spelt **twice** in `gate_QA`, three lines apart, because only a branch of
  its own can name the bug and because moving the `human` line would rot the anchors of four
  existing mutants. It is the regex that duplicates, never the decision.
- `HAT_WRITES_EXTRA` **widens a permission**, and its value is matched as a shell **glob** by
  `hat_path_allowed`. That is why it is literal-only, why it is refused in `load_config` rather than
  at the point of use (a command substitution, where a `die` would exit the subshell and hand the
  guard an empty list — the spelling of *"this hat writes anywhere"*), and why a sabotage pass is
  part of the contract for changing it.
- A hat whose own `writes:` is empty already writes anywhere; an entry naming it is accepted and
  **ignored**, with `sdd preflight` saying so. Narrowing would turn the widest hat in the pipeline
  into the narrowest; refusing would make the key a trap.
- The return from `deferred` to `agent` remains **manual** — no mission is scheduled by this ADR —
  but it stops being **silent**: every evaluation of `gate_QA` prints the names.
- The installer seeds the **field**, never the enum **legend**. A repo installed before this ADR
  keeps `<!-- agent | human -->`, which the gate does not read. The three values live in
  `agents/sdd-qa.md` § 5.1.
