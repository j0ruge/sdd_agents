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
# DECLARED LIMIT, since the r2 finding of `20260901-o-revisor-so-acha`: a run with
# SDD_TPL_SELFTEST_CHILD set still EXITS 0 when the rules pass. It has to — the end-to-end probe
# reads its child's rc, and a red child there means templates/ is genuinely broken. What that run no
# longer buys is the word `intact` and the silence; it announces the skip on stderr and says so on
# its last stdout line, and both halves carry their own probe. So the residue is a reader who sets
# the variable, ignores two loud lines, and reads rc alone — not a sensor that certifies itself.
#
# THAT RESIDUE HAD A NAME, and r3 finding #3 of the same mission is who said it: `run()` in
# tests/run-all.sh reads the rc and nothing else, and that file is TEST_CMD, so the abstract
# "a reader" was every gate of every mission. It is closed at the source — run-all.sh now REFUSES
# to run with the variable in its environment, the shape check-mutation.sh already uses for
# SDD_MUTANT — and the refusal carries its own probe in the selftest below. What is left is a
# reader OUTSIDE this kit doing the same thing, which no sensor here can reach.
#
# Usage: tests/check-templates.sh   (exit 0 = contract intact)

set -uo pipefail

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Overridable for ONE reader: the selftest, which re-runs this very file over a doctored copy of
# templates/ to prove the whole path goes red — not just that a primitive does. `CDPATH=''` because
# the operand is relative and the bash that finds it through $CDPATH prints the resolved directory
# straight into the substitution (the CRITICAL of 20260817-eixo-do-juiz, RULE 2 of check-pipefail).
SELF_PATH="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
T="${SDD_TEMPLATES_DIR:-$ROOT/templates}"
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
#
# `-i`, and check() deliberately WITHOUT it: the two primitives want opposite directions. A heading
# is a byte contract the runner greps, so check() must refuse a capital that gate_REVIEW would not
# accept; a refutation is fail-safe when it is broader, and the r1 of `20260901-o-revisor-so-acha`
# measured the cost of the narrow version — `## O que foi corrigido` beside the new section, rc 0,
# `template contract intact`.
#
# Declared limit, MEASURED on GNU grep 3.11 and not reasoned about: `-i` folds ASCII in every
# locale, so the two spellings that matter here fold under `LC_ALL=C` too (`O que foi corrigido`
# and `Virou correção` both answer 0 — the differing letters are `O` and `V`). A spelling that
# capitalises the ACCENTED letter does not: `VIROU CORREÇÃO` answers 1 under `LC_ALL=C` and 0 under
# `C.UTF-8`. No probe covers that world — no template writes a heading in caps — so it is named
# here rather than denied, which is the shape `d4deb35`/`7cbc8e2` cost this repo to learn.
refute() { # refute <file> <regex> <description> — passes when the regex does NOT match
  local rc=0
  grep -qiE "$2" "$T/$1" 2>/dev/null || rc=$?
  CHECKS_RUN=$((CHECKS_RUN + 1))
  case "$rc" in
    1) printf '  ok   %s: does not carry %s\n' "$1" "$3" ;;
    0) printf '  FAIL %s: still carries %s (regex: %s)\n' "$1" "$3" "$2" >&2
       fails=$((fails + 1)) ;;
    *) printf '  FAIL %s: could not be read to refute %s (grep rc=%s)\n' "$1" "$3" "$rc" >&2
       fails=$((fails + 1)) ;;
  esac
}

# The two forbidden-prose regexes, ONE definition each. The rules at the bottom of this file apply
# them to the real `templates/review.md`; the selftest probe below applies the SAME two variables to
# a world that carries the capitalised spelling. A probe with its own hand-written copy would agree
# with a rule it never read — a constant wearing the clothes of a measurement, which is the failure
# this repo already paid for once in `check-kaizen.sh`.
FORBIDDEN_TLDR='o que foi corrigido'
FORBIDDEN_POINTER='virou correção'

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

  # r1 of `20260901-o-revisor-so-acha`, finding #2: both forbidden-prose rules were case-sensitive,
  # so the old section `## O que foi corrigido` — capital O, the very heading the comment beside the
  # rules says it fears — could be reintroduced BESIDE the new one and this sensor still printed
  # `template contract intact` and exited 0. Reproduced before this probe was written: that section
  # appended to the real template left `bash tests/check-templates.sh` at rc 0.
  #
  # The probe reads the SAME two variables the rules read; a hand-written copy of the regex would
  # agree with a rule it never saw. The world carries the spelling in the shape the defect had — a
  # heading and a sentence, not a bare lowercase phrase.
  printf '## O que foi corrigido\n\nO achado #3 Virou correção nesta rodada, com hash.\n' \
    > "$box/capitalised.md"
  refute capitalised.md "$FORBIDDEN_TLDR"    'the capitalised TL;DR field' > "$box/cap1.out" 2>&1
  refute capitalised.md "$FORBIDDEN_POINTER" 'the capitalised pointer'     > "$box/cap2.out" 2>&1
  # Counting the failures is NOT enough, and this is the fail-open the first draft of this probe
  # carried: refute() bumps `fails` for rc 0 (prose is there) AND for rc 2 (file unreadable), so a
  # world whose printf never landed would satisfy a counter and prove nothing. The floor is the
  # WORDING of the branch — `still carries` is the rc-0 line and nothing else prints it.
  grep -q 'still carries' "$box/cap1.out" && grep -q 'still carries' "$box/cap2.out" \
    || broken "the forbidden-prose rules read past the capitalised spelling — '## O que foi corrigido' can be shipped beside the new section and this sensor still says the template contract is intact"
  printf '  ok    self-test: the forbidden-prose rules catch the capitalised spelling too\n'

  # And the counter the floor reads counts GREPS, not calls: eight probes above, eight counted.
  [ "$CHECKS_RUN" -eq "$((run_keep + 8))" ] \
    || broken "CHECKS_RUN moved by $((CHECKS_RUN - run_keep)) over 8 checks — the floor is counting something other than the greps it performed"

  # The probes above measure the PRIMITIVE. The finding was about the SENSOR: `rc 0` over a
  # templates/ that ships both sections. A rule rewritten to inline its own case-sensitive literal
  # would leave every probe above green, because none of them runs the rules. So this one re-runs
  # the whole file over a doctored copy — the `--check <file>` shape CLAUDE.md names, with an env
  # guard instead of a flag so the child does not selftest itself into a recursion.
  cp -r "$T_KEEP" "$box/tpl" || broken "could not copy templates/ — the end-to-end probe never ran"
  local ctl_rc=0 poison_rc=0 poison_out
  # Negative control FIRST, and it is not ceremony — the sabotage pass measured what it buys. With
  # the control deleted and the copy replaced by an empty directory, the poison run still finds its
  # own `>>`-appended heading, the case below reads `still carries`, and this whole sensor exits 0
  # over a probe that never touched templates/ at all. Control back in: rc 92. So the probe that
  # would otherwise certify itself is the one thing the control refuses.
  #
  # When the control IS red the honest answer is "I cannot tell which", and the two candidates are far apart
  # — templates/ is genuinely broken, or this probe is decoration — so the child's own complaint is
  # replayed instead of swallowed. Measured: without this, a real forbidden-prose regression exits
  # 92 quoting the control and never names the line the reader has to fix.
  SDD_TPL_SELFTEST_CHILD=1 SDD_TEMPLATES_DIR="$box/tpl" bash "$SELF_PATH" > "$box/ctl.out" 2>&1 || ctl_rc=$?
  if [ "$ctl_rc" -ne 0 ]; then
    printf '  --- what the end-to-end child said about the real templates/ ---\n' >&2
    cat "$box/ctl.out" >&2
    broken "the end-to-end child is red (rc=$ctl_rc) over an untouched copy of templates/ — either templates/ is genuinely broken (its complaint is above, and the rules further down say the same) or this probe would have 'caught' the poison by failing at everything"
  fi
  # r2 of `20260901-o-revisor-so-acha`, finding #1 (HIGH), and it is about the env guard at the
  # bottom of this file rather than about any rule below it. That branch used to answer the
  # recursion problem by setting `SELFTEST_RAN=1` — the exact value the vacuity guard at the end
  # reads — so `SDD_TPL_SELFTEST_CHILD=1 bash tests/check-templates.sh` printed
  # `template contract intact` at rc 0 having run ZERO probes over its own primitives. Reproduced
  # before these two probes were written: rc 0, one `template contract intact`, zero `self-test:`
  # lines. The comment that stood by the guard argued a flag would be worse because "a human could
  # pass it", while the Check of the R5 line in this repo's own checkpoint.md was teaching a human
  # to pass THIS one. An env var was never harder to type — only harder to see.
  #
  # `ctl.out` IS that world, and that is why it is read back instead of built again: the control run
  # above is a top-level run of this file with the variable set, over an untouched copy of
  # templates/. A second fixture would be a hand-written copy of a world the child never saw.
  #
  # Floor first, and it is not ceremony: `grep -q` over an empty file answers "absent", so the
  # second probe would pass for free over a child that never printed anything — the vacuity this
  # whole block exists to refuse. Measured: pointed at an empty file, the floor goes red instead.
  grep -q '^== templates/missao.md ==' "$box/ctl.out" \
    || broken "the skipped child printed none of the rules — the two probes below would be reading an empty world, and both would pass"
  grep -q 'template contract intact' "$box/ctl.out" \
    && broken "a run with SDD_TPL_SELFTEST_CHILD set certifies the template contract while skipping every probe above it — the environment buys the clean bill of health the selftest exists to earn"
  printf '  ok    self-test: the probes cannot be skipped from the environment\n'

  # Half two, and it needs its own probe because it has its own sabotage: the first probe only
  # demands that the word `intact` is gone. Silence would satisfy it, and silence is how a reader
  # fails to notice that this run proved nothing about itself. The two carriers are deliberately
  # different strings — this token prints on stderr and fires even when the rules FAIL, while the
  # terminal stdout line only replaces `intact` on the clean run — so neither probe can pass on the
  # other one's evidence.
  grep -q 'SELF-TEST SKIPPED' "$box/ctl.out" \
    || broken "the skipped child said nothing about having skipped — a reader cannot tell a run that proved its primitives from one that proved nothing"
  printf '  ok    self-test: skipping the probes is announced, never silent\n'

  # THE RESIDUE OF THE TWO PROBES ABOVE HAD A CONSUMER, and this closes it. r3 of
  # `20260901-o-revisor-so-acha`, finding #3: the limit this file's header declares — "a reader who
  # sets the variable, ignores two loud lines, and reads rc alone" — was not hypothetical. `run()`
  # in tests/run-all.sh reads the exit status and NOTHING else, and that file is TEST_CMD, so a
  # stale export in a shell bought `suite green` over a sensor that had proved nothing about
  # itself, at every gate of every mission. Measured before this probe was written:
  # `SDD_TPL_SELFTEST_CHILD=1 bash tests/check-templates.sh` ⇒ rc 0, zero `self-test:` lines, and
  # `run-all.sh --list` exiting 0 with all 14 steps. The fix is over there, in run-all.sh's own
  # shape for SDD_MUTANT; this is the probe that it exists.
  #
  # `--list` AND NOT A REAL RUN, for two reasons that both matter. Cost is the small one. The big
  # one is recursion: this file is a step of that suite, so a probe that ran the suite for real
  # would fork-bomb the machine of whoever deleted the refusal — the exact edit this probe exists
  # to catch. `--list` executes no step, so the sabotaged world is merely green and reported,
  # never a bomb.
  #
  # THE CLEAN `--list` IS THE FLOOR, and it is not ceremony: without it a run-all.sh broken for any
  # other reason would exit non-zero with the variable set too, and this probe would read someone
  # else's failure as the refusal. The floor demands the same command answer 0 when the environment
  # is clean, so what is measured is the DIFFERENCE the variable makes. The refusal is demanded BY
  # NAME as well as by rc, for the same reason: a suite that died of anything else also exits 1.
  local list_rc=0 refuse_rc=0 refuse_out
  bash "$ROOT/tests/run-all.sh" --list >/dev/null 2>&1 || list_rc=$?
  [ "$list_rc" -eq 0 ] \
    || broken "tests/run-all.sh --list is red (rc=$list_rc) with a clean environment — the probe below would read that failure as the refusal it is trying to measure"
  refuse_out="$(SDD_TPL_SELFTEST_CHILD=1 bash "$ROOT/tests/run-all.sh" --list 2>&1)" || refuse_rc=$?
  if [ "$refuse_rc" -eq 0 ]; then
    broken "tests/run-all.sh runs with SDD_TPL_SELFTEST_CHILD in its environment — this sensor would skip every probe above, exit 0 anyway, and run() reads nothing but that rc: the suite every gate calls would report green over a self-test that never happened"
  fi
  grep -q 'SDD_TPL_SELFTEST_CHILD' <<< "$refuse_out" \
    || broken "tests/run-all.sh exited non-zero with the variable set but never named it (rc=$refuse_rc) — a suite that died of something else is not a refusal, and the reader has nothing to unset"
  printf '  ok    self-test: the suite refuses to run with the selftest skip variable set\n'

  printf '\n## O que foi corrigido\n\n| Achado | Hash |\n|---|---|\n' >> "$box/tpl/review.md"
  poison_out="$(SDD_TPL_SELFTEST_CHILD=1 SDD_TEMPLATES_DIR="$box/tpl" bash "$SELF_PATH" 2>&1)" \
    || poison_rc=$?
  case "$poison_rc:$poison_out" in
    0:*) broken "a templates/review.md shipping '## O que foi corrigido' beside the new section exits 0 — the very rc the r1 of 20260901-o-revisor-so-acha reproduced" ;;
    *"still carries the TL;DR field"*) : ;;
    *) broken "the doctored templates/ turned this sensor red (rc=$poison_rc) but not through the forbidden-prose rule — a red for the wrong reason is not a measurement" ;;
  esac
  printf '  ok    self-test: templates/ shipping the old section beside the new one turns this sensor red\n'

  rm -rf "$box"
  T="$T_KEEP"; fails="$fails_keep"; CHECKS_RUN="$run_keep"
  SELFTEST_RAN=1
}
SELFTEST_RAN=0
SELFTEST_SKIPPED=0
# The child spawned by the end-to-end probe skips the selftest — it exists to answer one question
# ("does this file go red over that templates/?") and running the probes again would recurse.
#
# What it must NOT do is write SELFTEST_RAN, and that is finding #1 (HIGH) of the r2 of
# `20260901-o-revisor-so-acha`. This branch used to set exactly the value the vacuity guard at the
# end of this file reads, so the variable bought `template contract intact` at rc 0 over zero
# probes. The comment that stood here defended the env var over a flag because "a human could pass"
# a flag — and the R5 Check in this repo's own checkpoint.md had a human passing this variable as a
# shortcut. Skipping is therefore its own state now, and the two states are read separately below.
#
# It still exits 0 when the rules pass, and that is a DECLARED limit rather than an oversight: the
# control run reads the child's rc, and a red child there means "templates/ is genuinely broken".
# What the run loses is the word `intact` and the silence — never the exit code the parent needs.
# The one reader that limit could still fool inside this kit — run-all.sh, which is TEST_CMD and
# reads the rc alone — refuses to start with this variable set (r3 finding #3); see the header.
if [ -n "${SDD_TPL_SELFTEST_CHILD:-}" ]; then
  SELFTEST_SKIPPED=1
else
  selftest
fi

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
# The qualifier is IN the regex, and it is the whole assertion. `20260901-o-revisor-so-acha` widened
# this section from `(QA)` to `(QA e REVIEW)` — the R<n> increments the review round now writes live
# beside the QA's F<n> — and a regex that stopped at `de fix` served the heading it replaced exactly
# as well as the one it names, while the description beside it swore to pin the new one. Measured in the
# QA phase of that same mission: reverting the template's heading to `(QA)` left this sensor at rc 0,
# printing `template contract intact` over a template that had lost the contract. Same reasoning and
# same shape as `## O que virou incremento` below — a heading that REPLACED another is asserted by
# its new name in full, or the sensor certifies the old one.
check checkpoint.md '^## Incrementos de fix \(QA e REVIEW\)' \
  "section 'Incrementos de fix (QA e REVIEW)'"

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
# The qualifier is IN the regex, for the reason its sibling in checkpoint.md spells out at length:
# a regex that stops at `de conserto` serves a heading the description does not name, while the
# description swears to pin `(R<n>)`. Measured in the r1 of this same mission (finding #5): with the
# qualifier removed from the template this file printed `ok   review.md: section 'Incrementos de
# conserto (R<n>)'` and exited 0 — the sensor asserting it measured what it did not. The qualifier
# is not decoration in the heading either: it is where the reviewer reads the row ID from.
review_check '^## Incrementos de conserto \(R<n>\)' "section 'Incrementos de conserto (R<n>)'"
# And the section it replaced, asserted by its NEW name. `## O que foi corrigido` is what a round
# that fixed in place wrote; keeping the old heading beside the new one would let a template ship
# both and a session pick either, which is how a contract stops being one. That heading is refuted
# below, by the TL;DR rule and not by an anchored rule of its own: `-i` makes `o que foi corrigido`
# match inside `## O que foi corrigido`, so a `^## [Oo] que foi corrigido` rule could not be broken
# by any world the TL;DR rule does not already refuse. Measured, then not written — this repo asks
# for the probe before the deletion, and here the probe says the second rule would be decoration.
review_check '^## O que virou incremento' "section 'O que virou incremento'"
# The other half of the same contract, and the half the sections above cannot see. Both headings
# can be present and correct while the PROSE between them still sends the round back to fixing:
# the TL;DR asking what it corrected, and the findings table promising the fixed one reappears
# "com hash" in a section that opens with "Esta rodada não conserta." and has no hash column. That
# is what shipped in I2 and what the QA phase caught reading the template as a reviewer would.
# Anchored on the words the prose used, not on a whole sentence: a rewrite that keeps the
# instruction keeps the words, and a rewrite that drops the instruction has no reason to keep them.
refute review.md "$FORBIDDEN_TLDR" \
  "the TL;DR field 'o que foi corrigido' — a round that does not fix has no correction to summarise"
refute review.md "$FORBIDDEN_POINTER" \
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
#
# THREE states, not two, since the r2 finding: ran, skipped-and-said-so, and neither. Folding the
# middle one back into the first is what the environment used to buy for free.
if [ "$SELFTEST_SKIPPED" -eq 1 ]; then
  printf '  SELF-TEST SKIPPED  SDD_TPL_SELFTEST_CHILD is set, so the probes over this file own\n' >&2
  printf '                     assertion primitives did NOT run. This run says nothing about\n' >&2
  printf '                     whether the rules above are able to fail at all.\n' >&2
elif [ "$SELFTEST_RAN" -ne 1 ]; then
  broken "the selftest never ran — every ok line above is a claim about an assertion primitive nothing checked"
fi
if [ "$fails" -eq 0 ]; then
  # The word `intact` is earned by the probes, so the run that skipped them does not get to print
  # it. Same rc, because the end-to-end control above reads the rc and nothing else.
  if [ "$SELFTEST_SKIPPED" -eq 1 ]; then
    echo "template rules checked, self-test NOT run — this run proved nothing about itself"
    exit 0
  fi
  echo "template contract intact"
  exit 0
fi
echo "$fails check(s) failed" >&2
exit 1
