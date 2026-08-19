# BUG-20260819-escaped-pipe-rationale-read-as-placeholder: a real justification is refused as a placeholder, and the refusal quotes back words nobody wrote

- **Status:** fixed
- **Impact (user-side):** Blocks-Completion
- **Severity:** Critical · **Priority:** P0
- **Persona Affected:** Sessão
- **Journey Step:** J-review-round-seal, step 2 (let the gate read the round)
- **Scenarios:** GATE-review-escaped-pipe-in-rationale
- **Found:** 2026-08-19 · **Report:** docs/handoffs/20260819-fecho-que-nao-mente/40-review-r1.md (REVIEW round of the same mission)

## Summary

Sessão writes a genuine, complete rationale for an `A` — and the gate refuses the round, naming a
"placeholder Rationale" and quoting text that does not appear anywhere in the file. It cannot ask
anyone, it has no memory of the round it just wrote, and the reason it is given is not true. This is
the same family as the rest of the cycle — an instrument asserting what it did not measure — pointed
the **false-red** way, which costs exactly what a false green costs.

It was introduced by this cycle's own F3 (`272cb91`) and found by the mission's REVIEW round.

## Reproduction

- **Charter:** none — found by the `sdd-reviewer` session of mission `20260819` (see the tree README
  on why this repo's QA phase produces no charter-driven report)
- **Environment:** desktop, headless session

1. Write a review round whose rationale legitimately contains a pipe. GFM escapes it as `\|`:

   `| Code Quality (Zen) | A | `TODO\|` list references removed. |`

2. `./bin/sdd why <mission> REVIEW`.

**Expected:** the round passes — that is a real sentence about real work.
**Actual:** refused as a placeholder. The extractor split the row on the escaped pipe's byte,
leaving the stub `TODO\`, which normalises straight to the fill-in word.

## Evidence

Three separate defects, all in `gate_REVIEW`, all measured by the review session:

1. **The escaped pipe.** `awk -F'|'` does not know GFM's escape. While only `f[2]` and `f[3]` were
   read this was harmless; the moment F3 made `f[4]` a verdict, it became a refusal. Columns are now
   reassembled before reading. This is the same `awk -F'|'` trap the checkpoint's own header warns
   about for Check cells — the second time this repo has paid for it, in a different parser.
2. **`awk -v` escape processing.** The `gate:` value travelled via `-v`, which runs it through awk's
   escape handling before the program sees it. Measured on this machine's mawk 1.3.4:
   `-v x='grep -E \bcaught\b'` arrives as `grep -E caught`. So the refusal quoted back a string the
   file does not contain. It now travels through the environment instead.
3. **A comment asserting a falsehood.** The `.sdd/config.sh` source comment claimed `set -e` brings
   down the command substitution. It does not, without `inherit_errexit` — measured: the `printf` is
   always reached and the substitution exits 0.

## Fix

- **Root cause:** a parser whose looseness was harmless until a new consumer made it load-bearing.
  F3 did not introduce the split-on-escaped-pipe behaviour; it promoted a field that had never been
  read into a verdict, and the latent defect became reachable.
- **Fix commit:** `53586c5`, with `e2e5252` adding three new worlds and a mutant
- **Regression test:** `tests/check-gates.sh` — three new differential worlds plus one catalogue
  mutant, and the counts in that file stopped being prose.

## Verification

Not yet `verified`: the re-walk is the REVIEW round of this mission passing the gate with a rationale
that contains an escaped pipe. That round is being written now and is the natural verification.

<!-- Deliberately a new id, not a `## Regressed` section on BUG-20260819-punctuated-rationale-buys-an-a.
     That bug's symptom is a placeholder buying an A; this one's is a real sentence being refused.
     Opposite directions, different personas' experience, different fix — one id each. The two are
     linked through the scenarios' `overlaps` instead. -->
