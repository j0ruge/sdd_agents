# ADR 0020 — A finding that comes back gains one measured line, and the line stays out of the cap

- **Status**: proposed (—, 2026-10-23)
- **Spec**: docs/superpowers/specs/2026-10-23-reincidencia-no-todo-design.md

## Context

A finding that comes back, named again by another project or by another mission or session, is
the strongest sign that the pain is real. The findings format (`templates/todo.md`) had no place
for a return. A writer who met an open finding again could only append prose to its found-by, and
nothing in `tests/check-todo.sh` reads a return there: the found-by is checked only for a code span
in its tail, which must not open with one (rule 3), and for a `(YYYY-MM-DD)` on the item's last
line (rule 4), and the item it closes is held to the cap and the width (rule 5).

Measured at `1e49e30` over this kit's `TODO.md`:

- Three open items carry returns written by hand in the found-by: `TODO.md:153-159` (`sdd install`
  takes the current branch as the base), `:175-182` (`/sdd-plan` delegates to `sdd-planner` with no
  way out when the agent type is missing) and `:295-302` (the PR body promises CI). Each phrases
  the return differently ("e no `magic_tutor`", "e por `retrofit-watch`", an "e por" that ends a
  line), so `grep -c ' e por ' TODO.md` finds 1 of the 3. The "e por" is a count nobody measures,
  which principle 2 of `CLAUDE.md` (sensors, not perception) says will rot.
- The `/sdd-plan` item came back twice more and left no trace: in the 3.4a (2026-10-22) and in the
  3.4b (2026-10-23) of `dotp-remake`. In the retro of the 3.4b the relay found the item and wrote
  nothing, because the item sat at the 8-line cap (rule 5) and the format had no shape for a
  return.

So a return is lost exactly where it matters most: the more often a finding comes back, the longer
its found-by grows, and the sooner it reaches the cap that stops the next return from being
written. The owner asked for the return to be recorded on the item itself and to be visible where
he picks what to fix, in `TODO.md` and in the issues `todo-to-github-issues` mirrors, and he
allowed the cap to rise.

## Decision

1. **One line lists the returns, and its token is a contract.** An open finding that came back
   gains one line, the item's LAST physical content line, indented by any run of blanks or tabs:

   ```
     RECURRED <n>: <where> (YYYY-MM-DD)[; <where> (YYYY-MM-DD)]*
   ```

   - `<n>` is decimal with no leading zero, at least 1, and equal to the number of entries.
   - `<where>` matches `[A-Za-z0-9][A-Za-z0-9._/-]*`: ASCII, so no blank, no `#` (the mirror would
     read it as an issue reference) and no backtick (a code span there would read as an anchor).
     Examples: `dotp-remake/3.4b`, `magic_tutor/pr25`.
   - The dates go oldest first, a tie allowed, since two missions can meet the same finding on one
     day. Month 01-12 and day 01-31 are compared as strings, with no calendar.
   - No `<where>` appears twice: one entry per project and mission (or session).
   - Trailing blanks are tolerated, as at the end of every other line the sensor reads.
   - The token is `RECURRED`, English in every `OUTPUT_LANG`, like `RESOLVED by` and the two
     section markers. Any other spelling (`Recurred`, a translation) is ordinary prose and counts
     toward the cap.
2. **The line counts the returns only.** The first sighting stays in the found-by, and `<n>` is the
   number of times the finding came back (the owner's decision). The item is recurrent when the
   line exists. A mission or session that re-reads its own finding is not a return.
3. **The first well-formed line is outside the cap and the width.** It is not one of the CAP (8)
   content lines, and it has no 120-character width cap. Rule 4 reads the last line that is not a
   token line, so the dates of the returns never stand in for the date of the found-by; the
   found-by moves to the line above. The precedent is the long anchor line of issue #257, exempt
   from the width because its grammar admits no blank: no sentence rides on either line.
4. **A malformed token line is refused by name and keeps no width exemption.** A line that opens
   with the token and a blank but breaks the grammar is held to 120 characters and fails with the
   message of its first violation. Like a well-formed line it stays out of the body (the anchor and
   the found-by cut never see it) and out of rule 4, and the first such line stays out of the cap
   too: the item already fails on the RECURRED message, and counting the line again would only
   stack messages on the same defect.
5. **From the second token line on, each one counts toward the cap.** An item carries one token
   line at most, and with two or more only the last is parsed. The message for a second line
   carries no count, so under `--baseline` an item that inherited it kept the same key while token
   lines piled up unseen: the task review of this mission reproduced it with 30 extra lines, rc 0
   (fixed in `5745b51`). Every token line after the first is a content line now, and the cap
   message, which carries the number, bounds the item.
6. **The messages, verbatim.** Each names the line the item OPENS on, as rules 1, 3, 4 and the cap
   do, so a `--baseline` key does not move when the line of returns changes:
   - `RECURRED opens with "RECURRED <n>: "`
   - `RECURRED says <n>, lists <m>`
   - `RECURRED entry <k> is not <where> (YYYY-MM-DD)`
   - `RECURRED dates go oldest first`
   - `RECURRED names <where> twice: one entry per project and mission`
   - `RECURRED is the last line of the item` (no apostrophe: the awk program is single-quoted)
   - `one RECURRED line per item`

   The width message of a malformed line keeps naming its own physical line, like every width
   message.
7. **A decided record gains no line.** A decided finding that comes back goes to the human, who
   decides whether to reopen it, and it is not counted (the owner's decision). A token line under a
   record is refused by the rule that already exists, `a decided record is one line`.
8. **Every writer reads the open findings too.** The rule that already stood, "before filing, read
   the decided records", gains its other half in the preamble of `templates/todo.md` and
   `templates/todo.pt-BR.md`: an open finding that comes back gains an entry on its `RECURRED`
   line, never a new item. The hats that write in the `TODO_FILE` (`sdd-executor`, `sdd-qa`,
   `sdd-reviewer`, `sdd-docs`, `sdd-kaizen` and `sdd-planner`), the two boot prompts of `bin/sdd`,
   principle 5 of `CLAUDE.md`, `docs/pipeline.md` and the relay of `commands/sdd-plan.md` point at
   the template instead of repeating the grammar. The template governs the one writer with no file
   of its own, the manual triage of the LOW findings of a PR. The retro that the `retrofit-watch`
   Stop hook asks for learns the same rule in its own repository (Part 2 of the plan).
9. **The sensor declares the token once.** `RECURRED_TOKEN="RECURRED"` sits at column 0 of
   `tests/check-todo.sh`, in double quotes and alone on its line. The awk program receives it as
   `rtok` and never spells the word.

## Alternatives discarded

- **Raise the cap for the whole body.** The owner allowed it. It was refused because the cap
  exists for a measured reason: `TODO.md` reached 861 lines, with a median item of 10, while "a
  finding fits on a few lines" was prose only (header of `tests/check-todo.sh`). A higher cap gives
  every item the room, and the returns would still have no shape to be counted in. Exempting one
  line of fixed grammar gives the room only to what it is for.
- **The count in the title**, such as `**<title>** (x3)`. The title is the mirror's key
  (`<!-- todo-key -->`): every return would change the key, and `todo-to-github-issues` would plan
  a `RENAME?` pair, an orphan issue and a new one, instead of an update.
- **The "e por" in prose, as today.** It is what lost the returns: three items, three phrasings, a
  grep that finds 1 of 3, a number nobody checks, and no room left once the item sits at the cap.
- **A separate ledger file**, one row per return, outside `TODO.md`. Its rows need a key into the
  item, and the only stable one is the title, so a renamed finding would orphan them. It is one
  more file every writer has to know and the mirror has to read, and the count would live away from
  the item, which is where the owner picks what to fix.

## Consequences

- **`RECURRED` is the first token the sensor parses.** Until now every rule of
  `tests/check-todo.sh` was structural (punctuation, backticks, a date), and the only words it read
  were the two section markers, compared whole. `RECURRED` is the first word whose line the sensor
  parses by a grammar. It stays English in every language for the reason the markers do: a sensor
  keyed on a word of `OUTPUT_LANG` would work in one language and go blind in the others.
- **Backward compatible.** A `TODO.md` with no token line gives the output it gave before, in
  `--check`, `--check --baseline`, `--count` and `--anchors`: measured byte for byte, old sensor
  (`9a4a71c`) against new, under gawk 5.2.1 and mawk 1.3.4, over 162 selftest fixtures and the
  real `TODO.md` files of the kit, `dotp-remake` and `magic_tutor` (`fc69e16`, redone in
  `5745b51`). The new sensor reaches every target's gate as soon as `~/repos/sdd_agents` advances
  (the `TEST_CMD` of `magic_tutor` runs `check-todo.sh --check ... --baseline`), and an inherited
  item above the cap that gains the line is no new violation (probe
  `recurred-baseline-inherited`).
- **The mirror requires the token.** `todo-to-github-issues` (Part 2 of the plan) reads the
  declaration with `^RECURRED_TOKEN="([A-Z]+)"[ \t]*$` and refuses, with rc 3, a kit that lacks it,
  like the other kit requirements of its `SKILL.md`, instead of carrying a copy of the token. The
  declaration is therefore a contract: moving it off column 0, dropping the quotes or spelling the
  word inside the awk program breaks the mirror, not the sensor. A change on that line alone is an
  `UPDATE (recurrence)` of the mirror's plan, never the `UPDATE (text)` that asks for a human read.
- **The mirror strips the indent the same way and accepts trailing blanks.** The sensor recognises
  the line after cutting `[ \t]+` at its start and tolerates `[ \t]+` at its end. The mirror must
  cut exactly that, no more and no less, and accept the trailing blanks, or the label `reincidente`
  and the sensor will disagree about the same item.
- **From the second token line on, each counts toward the cap**, so an item holds at most CAP
  content lines plus ONE token line; under `--baseline`, an item that inherited a cap message holds
  the number that message carries, and any added line moves it.
- **Declared limits** (the Declared debt block of the header of `tests/check-todo.sh`, D15). Rule 6
  measures the shape of the line, never its truth: nothing reads whether an entry is a real return
  rather than a mission re-reading its own finding, whether it repeats the project of the found-by,
  whether a date is a real day (2026-02-31 passes) or no older than the first sighting. Two
  `<where>` that differ only in case are two. The well-formed line has no width cap and no limit on
  its entries; its grammar admits no blank, so it carries names and dates, never a sentence. Under
  `--baseline`, an item that inherited a RECURRED message can have its token lines edited with no
  new violation while the messages stay the same. Each is judgement on the diff.
- **What this version does not do.** The kit reorders nothing by the count (the planner does not
  pull recurrent items first), there is no composite weight, and nothing detects a duplicate by
  text similarity. The priority is to see and to filter: the count on the item, and the label
  `reincidente` the mirror puts on the issue.
