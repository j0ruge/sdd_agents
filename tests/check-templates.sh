#!/usr/bin/env bash
# Sensor for the template contract.
#
# The templates are not decoration: the runner greps them (the handoff frontmatter, the checkpoint
# table, the mission's PLAN-AUTO gate). If a heading or a key disappears, the matching gate starts
# lying in silence. This test fails first, loudly and cheaply.
#
# NOTE on the regexes below: they are deliberately Portuguese. They assert the contract of
# templates/, which is mission CONTENT in this repo's OUTPUT_LANG (pt-BR), not kit surface. The
# prose of this file is English because the file itself IS kit surface. Both are correct, and the
# split is the whole point of OUTPUT_LANG: a target repo declaring another language gets its
# artifacts in that language, while the kit stays readable to everyone.
#
# The mutation catalogue cannot reach this file (it sabotages bin/sdd; this one reads templates/),
# so it carries a selftest — see the block above the first `echo`. It did NOT for two missions, and
# the paragraph that stood here claimed the REVIEW_FLOOR plus an adversarial pass stood in for one,
# "not reachable in one edit". The r2 review of 20260818-lote-facil measured that sentence to be
# false: ONE deleted line inside `review_check` printed `23 assertion(s)` and `template contract
# intact` over a zero-byte templates/review.md.
#
# What survives now, named rather than hidden, and stated as TWO edits because that is what was
# measured: deleting the `selftest` call AND the SELFTEST_RAN guard that follows it; or neutering
# check() AND the negative controls that would catch it. Each alone turns this file red.
#
# Usage: tests/check-templates.sh   (exit 0 = contract intact)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$ROOT/templates"
fails=0

# Every grep this file performs, counted HERE and nowhere else. The counter used to live in the
# caller (`review_check` bumped it and then called check()), and the r2 review of 20260818-lote-facil
# measured what that bought: deleting the one line `check review.md "$1" "$2"` from the wrapper left
# this sensor printing `23 assertion(s)` and `template contract intact`, rc 0, over a
# `templates/review.md` of ZERO BYTES — the only carrier of the seven criteria gate_REVIEW cannot
# check itself. A floor over call sites counts intentions; a floor over this counts greps.
CHECKS_RUN=0
check() { # check <file> <regex> <description>
  local rc=0
  grep -qE "$2" "$T/$1" || rc=1
  CHECKS_RUN=$((CHECKS_RUN + 1))
  if [ "$rc" -eq 0 ]; then
    printf '  ok   %s: %s\n' "$1" "$3"
  else
    printf '  FAIL %s: missing %s (regex: %s)\n' "$1" "$3" "$2" >&2
    fails=$((fails + 1))
  fi
}

# The mirror of check(), and the half of the contract check() cannot express: what a template must
# NOT carry. Prose left behind is invisible to every positive assertion in this file — the sections
# are all there, the gate parses, the sensor says `intact` — while the template goes on instructing
# the session to do the thing the mission deleted. Measured in `20260901-o-revisor-so-acha`: the
# round stopped fixing in I2, and templates/review.md kept telling the TL;DR to say "o que foi
# corrigido" and the finding that "virou correção" to reappear "com hash" in a section whose first
# sentence is "Esta rodada não conserta." — a template that argues with itself, aimed at the very
# first round to read it.
#
# grep rc is THREE-valued here and the case below reads all three: 1 (absent) is the only pass.
# `grep -q ... || rc=1` would have folded rc 2 into the pass and let a missing or unreadable file
# certify every refutation in this file — the fail-open check() pays a probe to avoid one line up.
refute() { # refute <file> <regex> <description> — passes when the regex does NOT match
  local rc=0
  grep -qE "$2" "$T/$1" 2>/dev/null || rc=$?
  CHECKS_RUN=$((CHECKS_RUN + 1))
  case "$rc" in
    1) printf '  ok   %s: does not carry %s\n' "$1" "$3" ;;
    0) printf '  FAIL %s: still carries %s (regex: %s)\n' "$1" "$3" "$2" >&2
       fails=$((fails + 1)) ;;
    *) printf '  FAIL %s: could not be read to refute %s (grep rc=%s)\n' "$1" "$3" "$rc" >&2
       fails=$((fails + 1)) ;;
  esac
}

# --- selftest ----------------------------------------------------------------------------------
# The debt CLAUDE.md names for this file, paid. Four of the five sensors the mutation catalogue
# cannot reach carry a selftest; this one carried REVIEW_FLOOR and a declared adversarial pass
# instead, and the r2 review of 20260818-lote-facil measured what that was worth — the floor
# counted CALL SITES, so one deleted line certified a zero-byte `templates/review.md` with
# `23 assertion(s)` and `template contract intact`.
#
# Moving the count inside check() fixes that and moves the turtle one shell out: a check() whose
# grep is gone counts just the same, and every assertion in this file then passes over any world.
# Nothing but a NEGATIVE CONTROL closes it — running the assertion primitive against a world whose
# answer is known and demanding that it says so.
broken() { printf '  SENSOR-BROKEN  %s\n' "$1" >&2; exit 92; }

selftest() {
  local box T_KEEP="$T" fails_keep="$fails" run_keep="$CHECKS_RUN"
  box="$(mktemp -d "${TMPDIR:-/tmp}/sdd-tpl-selftest-XXXXXX")" || broken "no tmpdir — the probes never ran"
  [ -n "$box" ] && [ -d "$box" ] || broken "no tmpdir — the probes never ran"
  T="$box"
  printf 'hello\n' > "$box/probe.md"

  check probe.md '^hello' 'a regex that matches' >/dev/null 2>&1
  [ "$fails" -eq "$fails_keep" ] \
    || broken "check() counted a failure over a regex that DOES match — a rule that refuses every world distinguishes nothing"

  check probe.md '^nope' 'a regex that does not match' >/dev/null 2>&1
  [ "$fails" -eq "$((fails_keep + 1))" ] \
    || broken "check() stayed silent over a regex that does NOT match — the assertion primitive is a no-op and every ok line in this file is decoration"

  # A missing file is the zero-byte template's neighbour, and it must accuse rather than crash.
  check absent.md '^anything' 'a file that is not there' >/dev/null 2>&1
  [ "$fails" -eq "$((fails_keep + 2))" ] \
    || broken "check() stayed silent over a file that does not exist"

  # refute() gets the same treatment, and it needs it more: a primitive whose pass is the SILENCE
  # of a grep degrades into a no-op without changing a single line of output. Neutered, every
  # `does not carry` line below becomes a claim about a grep nobody ran.
  refute probe.md '^nope' 'a regex that does not match' >/dev/null 2>&1
  [ "$fails" -eq "$((fails_keep + 2))" ] \
    || broken "refute() counted a failure over a regex that does NOT match — a refutation that refuses every world refutes nothing"

  refute probe.md '^hello' 'a regex that DOES match' >/dev/null 2>&1
  [ "$fails" -eq "$((fails_keep + 3))" ] \
    || broken "refute() stayed silent over prose that IS there — the forbidden-prose rules are decoration"

  # rc 2, the fail-open that the case in refute() exists to close: no file, no verdict.
  refute absent.md '^anything' 'a file that is not there' >/dev/null 2>&1
  [ "$fails" -eq "$((fails_keep + 4))" ] \
    || broken "refute() passed over a file it could not read — an unreadable template refutes everything for free"

  # And the counter the floor reads counts GREPS, not calls: six probes above, six counted.
  [ "$CHECKS_RUN" -eq "$((run_keep + 6))" ] \
    || broken "CHECKS_RUN moved by $((CHECKS_RUN - run_keep)) over 6 checks — the floor is counting something other than the greps it performed"

  rm -rf "$box"
  T="$T_KEEP"; fails="$fails_keep"; CHECKS_RUN="$run_keep"
  SELFTEST_RAN=1
}
SELFTEST_RAN=0
selftest

echo "== templates/missao.md =="
for k in missao titulo data versao branch aprovacao ddd; do
  check missao.md "^${k}:" "frontmatter key '${k}'"
done
check missao.md '^## Problema \(Gemba\)'      "section 'Problema (Gemba)'"
check missao.md '^## Métrica'                 "section 'Métrica'"
check missao.md '^## Resultado esperado'      "section 'Resultado esperado'"
check missao.md '^## Fora de escopo'          "section 'Fora de escopo'"
check missao.md '^## Gate PLAN-AUTO'          "section 'Gate PLAN-AUTO'"
check missao.md '^## Checklist kaizen'        "kaizen checklist"
check missao.md '^## Checklist DDD'           "DDD checklist"
check missao.md '^## Decisões do grill'       "grill decisions"
check missao.md '^## Pendências para o humano' "open questions for the human"
for c in a b c d e; do
  check missao.md "^\| ${c} \|" "PLAN-AUTO criterion '${c}'"
done

echo "== templates/plano.md =="
check plano.md '^## Contexto verificado'      "section 'Contexto verificado'"
check plano.md '^## Arquitetura da mudança'   "section 'Arquitetura da mudança'"
check plano.md '^## Incrementos'              "section 'Incrementos'"
check plano.md '\*\*Check:\*\*'               "per-increment 'Check' field"
check plano.md '\*\*Sensor durável:\*\*'      "per-increment 'Sensor durável' field"
check plano.md '^## Riscos e não-feitos'      "section 'Riscos e não-feitos'"
check plano.md '^## Verificação end-to-end'   "section 'Verificação end-to-end'"

echo "== templates/checkpoint.md =="
check checkpoint.md '^\| ID \| Incremento \| Check \(comando → esperado\) \| Status \| Commit \|' \
  "exact table header (the runner parses by column position)"
check checkpoint.md 'pending'                 "status token 'pending'"
check checkpoint.md '`done`'                  "status token 'done'"
check checkpoint.md '`blocked`'               "status token 'blocked'"
check checkpoint.md '^## Notas de execução'   "section 'Notas de execução'"
check checkpoint.md '^## Incrementos de fix'  "section 'Incrementos de fix (QA e REVIEW)'"

echo "== templates/handoff.md =="
for k in missao fase status sessao data gate; do
  check handoff.md "^${k}:" "frontmatter key '${k}'"
done
check handoff.md '^## TL;DR'                  "section 'TL;DR'"
check handoff.md '^## Estado do repo'         "section 'Estado do repo'"
check handoff.md '^## O que foi feito'        "section 'O que foi feito'"
check handoff.md '^## Artefatos'              "section 'Artefatos'"
check handoff.md '^## Boot da próxima fase'   "section 'Boot da próxima fase'"
check handoff.md '^## Pendências / Decisions for a Human' "open-questions section"
check handoff.md '^## Riscos e não-feitos'    "section 'Riscos e não-feitos'"
check handoff.md '^## Achados fora de escopo' "section 'Achados fora de escopo'"
# The handoff is the ONLY carrier a kit finding has when the mission's repo is not the kit — the
# session is forbidden to write into the kit's own TODO.md, so a template that lost this line would
# leave the instruction pointing at a slot that does not exist.
#
# Anchored INSIDE the blockquote (`^> - kit: `) and never on a bare `^- kit: `, and the difference
# is a bug this repo already paid for one commit earlier: `cd49351` moved the `- intervention:`
# example of checkpoint.md into its quote because a bullet that opens the line gets counted verbatim
# by whatever comes to tally it, so every instantiated artifact was born owing a phantom. Nothing
# greps handoffs for `kit:` today; the triage is the stated plan, and an anchor on the bare form
# would pin the countable shape in place for it to find. The quote marker is what separates the
# EXAMPLE from a real finding written below it.
check handoff.md '^> - kit: ' "kit-finding slot in 'Achados fora de escopo'"

echo "== templates/pr-body.md =="
check pr-body.md '^## O que mudou'            "section 'O que mudou'"
check pr-body.md '^## Como verificar'         "section 'Como verificar'"
check pr-body.md '^## Evidências'             "section 'Evidências'"
check pr-body.md '^## Plano'                  "section 'Plano'"
check pr-body.md '^## Pendências \(Decisions for a Human\)' "open-questions section"
check pr-body.md '^## Achados fora de escopo' "section 'Achados fora de escopo'"
check pr-body.md '^## Riscos e não-feitos'    "section 'Riscos e não-feitos'"

# == templates/review.md ==
#
# The review round report was the ONE artifact with a gate and no template. gate_REVIEW reads it
# with a literal `^###[[:space:]]+Overall Grade` (bin/sdd) and answers NO-TABLE when the heading
# is written at any other level — which two independent review sessions did, both writing `##`,
# because there was nothing to copy from. A template is what stops a third from deriving it again.
#
# These assertions are DERIVED from the gate rather than restated beside it: the heading regex and
# the column names are what the awk in gate_REVIEW actually reads. Note the `###` in the check
# below is the whole point — a `##` here would ship the exact defect the template exists to stop.
# REVIEW_ASSERTIONS counts GREPS PERFORMED, never passes, and `fails` alone decides the verdict —
# one mechanism per question. A first draft counted only the assertions that held, which duplicated
# the `fails` accounting: an adversarial pass neutered the duplicate and the sensor went on
# printing an `ok rule:` line about a template that had just failed fourteen checks. The second
# draft counted CALL SITES, in the wrapper, and failed open on a zero-byte template (see check()).
# It is a delta over CHECKS_RUN so that the number belongs to this block and not to the file.
REVIEW_MARK="$CHECKS_RUN"
REVIEW_ASSERTIONS=0
REVIEW_FAILS_BEFORE="$fails"
review_check() { # review_check <regex> <description> — check(), counted for the floor below
  check review.md "$1" "$2"
}

echo "== templates/review.md =="
for k in missao fase rodada status sessao data gate; do
  review_check "^${k}:" "frontmatter key '${k}'"
done
review_check '^### Overall Grade' "the '### Overall Grade' heading gate_REVIEW greps, at level 3"
review_check '^\| Criterion \| Grade \| Rationale \|' "the exact table header the gate parses"
review_check '^\| \*\*Overall\*\* \|'  "the '**Overall**' row"
# The seven criteria, one assertion each, because the gate CANNOT check them. gate_REVIEW reads
# whatever rows it finds and demands Grade A on each; a table that lost six of its seven criteria
# still passes it, and passes it with a real seal. The template is the only carrier of the list,
# and it says so itself two lines above the table ("não traduza os critérios: eles são contrato do
# skill"). Measured: deleting all seven rows left this sensor green, still printing its `ok rule:`
# line — the rule was written and never probed. Sibling tables in this file already assert each
# row individually (missao.md's PLAN-AUTO criteria, `for c in a b c d e`); this follows them.
# English on purpose, in a pt-BR template: the names belong to the codereview skill, not to us.
for c in 'Code Quality (Zen)' 'Type Safety' 'Error Handling' 'Security' 'Performance' \
         'Test Coverage' 'Documentation'; do
  review_check "^\| ${c//(/\\(}" "the '${c}' criterion row"
done
review_check '^## TL;DR'               "section 'TL;DR'"
review_check '^## Pendências / Decisions for a Human' "section 'Pendências / Decisions for a Human'"
review_check '^## Achados da rodada'   "section 'Achados da rodada'"
review_check '^## O que foi refutado'  "section 'O que foi refutado'"
review_check '^## Achados fora de escopo' "section 'Achados fora de escopo'"
# Since `20260901-o-revisor-so-acha` the round does not fix: every finding that must be fixed is
# written into the checkpoint as an `R<n>` increment and the EXEC phase closes it. The section is
# what the reviewer copies the row shape from, and a round that lost it has nowhere to record the
# increments it wrote — the ball never goes back to EXEC and the finding dies in the prose.
review_check '^## Incrementos de conserto' "section 'Incrementos de conserto (R<n>)'"
# And the section it replaced, asserted by its NEW name. `## O que foi corrigido` is what a round
# that fixed in place wrote; keeping the old heading beside the new one would let a template ship
# both and a session pick either, which is how a contract stops being one.
review_check '^## O que virou incremento' "section 'O que virou incremento'"
# The other half of the same contract, and the half the sections above cannot see. Both headings
# can be present and correct while the PROSE between them still sends the round back to fixing:
# the TL;DR asking what it corrected, and the findings table promising the fixed one reappears
# "com hash" in a section that opens with "Esta rodada não conserta." and has no hash column. That
# is what shipped in I2 and what the QA phase caught reading the template as a reviewer would.
# Anchored on the words the prose used, not on a whole sentence: a rewrite that keeps the
# instruction keeps the words, and a rewrite that drops the instruction has no reason to keep them.
refute review.md 'o que foi corrigido' \
  "the TL;DR field 'o que foi corrigido' — a round that does not fix has no correction to summarise"
refute review.md 'virou correção' \
  "the pointer sending a finding that 'virou correção' to a next section with a hash column"

# The floor is what turns "no assertion failed" into "the assertions ran". Deleting the loops above
# would otherwise leave this file green while measuring nothing about the file it names — the
# vacuity every sensor in this suite carries a floor against.
REVIEW_ASSERTIONS=$((CHECKS_RUN - REVIEW_MARK))
# 23 → 24 in `20260901-o-revisor-so-acha`, with the `## Incrementos de conserto` section, then
# 24 → 26 in the F1 of the same mission, with the two `refute` rules above. A floor left behind
# still PASSES while describing a smaller surface than the one it reads, which is the same
# fail-open as a floor of zero — recounted in the commit that adds the rule, never later.
REVIEW_FLOOR=26
if [ "$REVIEW_ASSERTIONS" -lt "$REVIEW_FLOOR" ]; then
  printf '  FAIL review.md: only %d assertion(s) ran, expected at least %d — a clean report over\n' \
    "$REVIEW_ASSERTIONS" "$REVIEW_FLOOR" >&2
  printf '       a rule that never ran is what this floor exists to refuse\n' >&2
  fails=$((fails + 1))
elif [ "$fails" -ne "$REVIEW_FAILS_BEFORE" ]; then
  # An assertion above failed and check() has already said which. No ok line: a sensor whose two
  # verdicts share a stream cannot be read by a grep, and this one IS read by a grep.
  :
else
  printf '  ok    rule: the review template carries the heading and table gate_REVIEW parses, and none of the prose the round no longer honours (%d assertion(s))\n' \
    "$REVIEW_ASSERTIONS"
fi

echo
# The last composition this file can assert about itself: probes that never ran are probes that
# prove nothing, and deleting the `selftest` call is one line. Deleting THIS as well is a second
# edit — stated as two edits and not as "unreachable in one", because r2 measured that stronger
# sentence to be false where a sensor header claimed it.
[ "$SELFTEST_RAN" -eq 1 ] \
  || broken "the selftest never ran — every ok line above is a claim about an assertion primitive nothing checked"
if [ "$fails" -eq 0 ]; then
  echo "template contract intact"
  exit 0
fi
echo "$fails check(s) failed" >&2
exit 1
