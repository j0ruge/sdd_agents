# ADR 0011 — A findings anchor carries a symbol, and the sensor finds the line through it

- **Status**: proposed (—, 2026-09-25)
- **Spec**: docs/handoffs/20260925-o-sensor-le-o-que-a-ancora-diz/00-missao.md

## Context

Every open item of a findings file (`TODO.md`, format in `templates/todo.md`) carries an anchor,
`` `path:line` ``, right after its bold title. The anchor exists so that the next session opens the
right line instead of searching for it. The only rule `tests/check-todo.sh` applies to it
(`flush()`, `tests/check-todo.sh:271-272` at `5cb0101`) is "some non-empty backticked span sits
before the found-by tail". The sensor never opens the file the anchor names; its header says so on
purpose (`tests/check-todo.sh:29-31`, `:96-97`).

Measured at `5cb0101` over the 100 open items of this kit's `TODO.md`:

- 85 anchors name a line greater than 1. All 85 files exist and all 85 lines are inside their file,
  so a rule "the file exists and the line is in range" would fail **0** items today.
- By a manual verdict item by item, **63 of the 85** point at the wrong code, 11 are right, 6 are
  near and 5 are unclear. Several miss by hundreds of lines: `bin/sdd` went from 2287 lines when the
  oldest anchors were written to 9680 today.
- Four items are stale beyond the anchor: one names a function that no longer exists
  (`review_scope_check`), one cites a header sentence that is gone (`RESOLVIDO`), one quotes a floor
  that moved from 12 to 36, and one claims the sensor "checks that the file exists", which it never
  did.

This is the same failure the issues #86 and #136 recorded twice, at 15 and at 22 wrong anchors. A
batch re-anchoring alone would repeat it: nothing would stop the number from growing again, because
every mission that grows `bin/sdd` pushes the anchors below the edit.

## Decision

1. **The line number stays, and a symbol travels with it.** An open item must cite, in its head
   (the text before the found-by tail), at least one backticked span of four or more characters,
   other than the anchor itself, that `grep -F` finds in the anchored file.
2. **The sensor measures the distance.** With an anchor `path:N` and N greater than 1, at least one
   occurrence of one cited symbol must sit within **10 lines** of N. An anchor without a line, or
   with `:1`, is a whole-file anchor: it passes when a cited symbol occurs anywhere in the file.
   The violation message names the nearest occurrence, so re-anchoring is a copy and never a hunt.
3. **The anchor is resolved against the checked file's repository, never against the kit.** The
   base is `git -C <dir of the checked file> rev-parse --show-toplevel`, falling back to that
   directory. In a target repo, `check-todo.sh --check TODO.md` must read the target's files. The
   kit's `$ROOT` would silently measure the wrong tree.
4. **The anchor must name a regular file.** A glob (`templates/*.md`) or a bare word
   (`frontmatter`) is not an anchor.
5. **The rule enters with a selftest and an adversarial pass**, like every rule of this sensor. The
   mutation catalogue does not reach `check-todo.sh`, which measures markdown and not `bin/sdd`.
   The kit's `TODO.md` is re-anchored in the same mission before the rule is wired into the default
   run, so the suite never goes red because of the rule.

## Alternatives discarded

- **File exists and line in range.** This is free to write and measures nothing today: 0 of 85
  fail. It would certify an anchor 400 lines off.
- **A term of the title within ±K lines, with no declared symbol.** At ±10 it fails 52 of 85, and
  it also fails on anchors that are right (it picks words the line does not need to carry). A
  heuristic that fails on correct input trains people to ignore it.
- **Symbol only, no line number.** This is the most rot-proof form, because a number derived from a
  symbol cannot drift. It was discarded because it makes the reader grep on every visit, and a
  symbol that occurs 30 times in `bin/sdd` points at nothing. The line plus a symbol at distance 10
  keeps the jump cheap and makes the drift detectable.
- **Re-anchor in batch and keep the rule as it is.** This is what #136 proposed. It fixes the
  number once and leaves the mechanism that produced it. The next mission that grows `bin/sdd`
  starts the count again.

## Consequences

- A mission that moves code under an anchor now sees `check-todo.sh` go red in the same suite run
  that gates its phase. The message gives the nearest line, so the fix is one edit.
- The format line of `templates/todo.md` and `templates/todo.pt-BR.md` changes, and every target
  repo that runs `check-todo.sh --check` inherits the rule. A target whose anchors rotted gets a red
  lint the first time it runs the new kit. That is the rule working, not a regression. The number
  it reports is the debt that already existed.
- Declared limits (header of `tests/check-todo.sh`): only the first anchor of an item is measured;
  items with `(+ other/path:N)` keep their secondary anchors unmeasured. A whole-file anchor (`:1`)
  is weaker than a line anchor by design. A symbol that occurs everywhere (`local`, `printf`)
  satisfies the rule near almost any line, which is why the minimum length is four characters and
  the adversarial pass has to try to cheat with a common word.
