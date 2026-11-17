#!/usr/bin/env bash
# Sensor for the campaign worker — `bin/sdd-worker` answers from artifacts (ADR 0022).
#
# What it measures. The worker is a session that orchestrates a campaign under a delegation the
# owner signed, and the questions that decide its acts (does the delegation hold? does this act fit
# the level? what comes next? did a ceiling blow? is this pull request ready on this sha?) are
# answered by the verbs of bin/sdd-worker, never by the session's reading. Each verb is measured
# here over fixtures, and each rule carries a mutant `mut_WORKER_*` in tests/check-mutation.sh: a
# sabotaged verb has to turn this file red, or the assertion is decoration.
#
# Rules, each with a probe below:
#   R1  no verb, and a verb the program does not know, print the usage on stderr and leave rc 2 —
#       never a silent rc 0 that a caller would read as an answer
#   R2  `delegate` signs on a yes, and only on one: it writes `signed: <instant> <digest>`, where the
#       digest is the first 12 hex of the sha256 of the six other keys (computed HERE, independently
#       of the program), and it touches no other line of the file
#   R3  `delegate` with no character on stdin is rc 66 and writes nothing — nobody was asked, which
#       is not the same as a no (the contract of `sdd approve`)
#   R4  `delegate` signs nothing on a no, nor — with a yes on stdin — on a delegation that already
#       expired, one whose level is off the ladder, one with a ceiling missing, one with an empty
#       key (`lots:`), an instant that is not one, or a ceiling that is not a number; those are
#       refused before the question (rc 1), the no is an answer (rc 0)
#
# Every green line is `  ok    <family>: <assertion>` on stdout, and each family (`usage: `, and the
# verbs as they land) prints exactly the assertions the mission plan names — the checkpoint counts
# them. Inside a mutant (SDD_MUTANT set) fail() ends the sensor at the first red, after printing it;
# the census in check-health.sh holds that clause.
#
# Usage: tests/check-worker.sh   (exit 0 = every verb answers what its rule says)
set -uo pipefail
. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"

ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKER="$ROOT/bin/sdd-worker"
PROBES=0
fails=0

# Anti-vacuity: a block that stops being dispatched prints what a clean program prints. One unit of
# PROBES is one assertion outcome, and only pass() and fail() write it.
PROBE_FLOOR=4

pass() { PROBES=$((PROBES + 1)); printf '  ok    %s\n' "$1"; }
fail() { PROBES=$((PROBES + 1))
         printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }

BOX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-worker-XXXXXX")"
trap 'rm -rf "$BOX"' EXIT

# worker_from <stdin-file> <args...> — runs the program with <stdin-file> on stdin; PUBLISHES W_RC,
# W_OUT and W_ERR. Called, never substituted: under `$( )` the three globals would die with the
# subshell. `worker` is the same with no stdin at all, and `answer` writes what the next
# `worker_from "$BOX/in"` reads.
worker_from() {
  local in="$1"; shift
  W_RC=0
  "$WORKER" "$@" > "$BOX/out" 2> "$BOX/err" < "$in" || W_RC=$?
  W_OUT="$(cat "$BOX/out")"
  W_ERR="$(cat "$BOX/err")"
}
worker() { worker_from /dev/null "$@"; }
answer() { printf '%s' "$1" > "$BOX/in"; }

# --- the fixture repo ---------------------------------------------------------------------------
# One git repo, the shape every campaign verb reads: the root comes from `git rev-parse
# --show-toplevel`, and .sdd/config.sh carries the two keys the verbs read — the pager is set, so a
# level above assisted is not lowered by its absence. No remote: when a verb needs gh, it is a stub.
REPO="$BOX/repo"
mkdir -p "$REPO/.sdd" "$REPO/docs/campaigns"
git init -q -b main "$REPO"
printf 'HANDOFF_DIR="docs/handoffs"\nON_ESCALATION_CMD="true"\n' > "$REPO/.sdd/config.sh"

# campaign <id> <level> <expires> <mission cap> <campaign cap> — a campaign directory made from the
# kit's own templates, every placeholder of the delegation's frontmatter replaced by a real value,
# `lots: all`, and `signed:` left as the template has it (empty); prints its path. A cap given as `-`
# deletes that key's line: a missing ceiling. Only the frontmatter (line 2 to the closing ---) is
# edited, the way the verbs read it.
campaign() {
  local d="$REPO/docs/campaigns/$1"
  mkdir -p "$d"
  sed "2,/^---\$/ s@^campaign: .*@campaign: $1@" "$ROOT/templates/campaign.md" > "$d/campaign.md"
  sed "2,/^---\$/ {
         s@^campaign: .*@campaign: $1@
         s@^level: .*@level: $2@
         s@^lots: .*@lots: all@
         s@^expires: .*@expires: $3@
         s@^budget_mission_usd: .*@budget_mission_usd: $4@
         s@^budget_campaign_usd: .*@budget_campaign_usd: $5@
       }" "$ROOT/templates/delegation.md" > "$d/delegation.md"
  [ "$5" != - ] || sed -i '2,/^---$/ { /^budget_campaign_usd:/d }' "$d/delegation.md"
  printf '%s\n' "$d"
}

# digest_of <campaign> <level> <lots> <expires> <mission cap> <campaign cap> — the digest the
# contract defines, computed by the sensor and never by the program: the first 12 hex of the sha256
# of the six lines `key: value`, each ending in a newline, in this order.
digest_of() {
  printf 'campaign: %s\nlevel: %s\nlots: %s\nexpires: %s\nbudget_mission_usd: %s\nbudget_campaign_usd: %s\n' \
    "$@" | sha256sum | cut -c1-12
}

# signed_line <delegation> — the frontmatter's signed: line, as written.
signed_line() { sed -n '2,/^---$/ { /^signed:/p }' "$1"; }

# --- R1: usage ----------------------------------------------------------------------------------
# Both worlds, and three terms each: the rc alone is shared with every refusal a verb will have, the
# usage text is what tells this branch apart, and an empty stdout keeps the usage off the channel a
# caller parses as the answer.
got=""
worker;            [ "$W_RC" = 2 ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" && [ -z "$W_OUT" ] \
  || got="no verb: rc $W_RC, stderr '${W_ERR%%$'\n'*}', stdout '${W_OUT%%$'\n'*}'"
worker frobnicate; [ "$W_RC" = 2 ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" && [ -z "$W_OUT" ] \
  || got="${got:+$got; }unknown verb: rc $W_RC, stderr '${W_ERR%%$'\n'*}', stdout '${W_OUT%%$'\n'*}'"
if [ -z "$got" ]; then
  pass 'usage: no verb and an unknown verb print the usage and leave rc 2'
else
  fail 'usage: no verb and an unknown verb print the usage and leave rc 2' \
    'rc 2, the usage on stderr, nothing on stdout' "$got"
fi

# --- R2: delegate signs on a yes ----------------------------------------------------------------
# Five terms: rc 0; the signed: line has the instant-and-digest shape; the digest is the one the
# sensor computes from the six values (a program that hashed a constant, or fewer keys, differs);
# the instant lies between two readings of the clock taken around the call; and the file minus its
# signed: line is byte for byte what it was. The stdout echoes the grant and says how to commit it.
got=""
d="$(campaign c-yes pr '2099-12-31 23:59' 25 200.50)"
cp "$d/delegation.md" "$BOX/c-yes.before"
answer $'y\n'
t0="$(date '+%Y-%m-%d %H:%M')"
worker_from "$BOX/in" delegate "$d"
t1="$(date '+%Y-%m-%d %H:%M')"
line="$(signed_line "$d/delegation.md")"
want="$(digest_of c-yes pr all '2099-12-31 23:59' 25 200.50)"
stamp="${line#signed: }"; stamp="${stamp% *}"
[ "$W_RC" = 0 ] || got="rc $W_RC (stdout '${W_OUT##*$'\n'}')"
[[ "$line" =~ ^signed:\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}\ [0-9a-f]{12}$ ]] \
  || got="${got:+$got; }signed line '$line'"
[ "${line##* }" = "$want" ] || got="${got:+$got; }digest '${line##* }', the six keys give '$want'"
{ [ "${stamp//[!0-9]/}" -ge "${t0//[!0-9]/}" ] 2>/dev/null \
    && [ "${stamp//[!0-9]/}" -le "${t1//[!0-9]/}" ]; } \
  || got="${got:+$got; }instant '$stamp' is not between $t0 and $t1"
cmp -s <(sed '/^signed:/d' "$BOX/c-yes.before") <(sed '/^signed:/d' "$d/delegation.md") \
  || got="${got:+$got; }a line other than signed: changed"
grep -qx 'level: pr' <<< "$W_OUT" && grep -qx 'budget_campaign_usd: 200.50' <<< "$W_OUT" \
  || got="${got:+$got; }the grant was not echoed on stdout"
grep -q "^signed $d/delegation.md — commit it: git add $d/delegation.md && git commit " <<< "$W_OUT" \
  || got="${got:+$got; }no commit line on stdout"
grep -qF 'Sign this delegation? [y/N]' <<< "$W_ERR" || got="${got:+$got; }the question was not asked"
if [ -z "$got" ]; then
  pass 'delegate: an answer of y signs with a digest of the other fields'
else
  fail 'delegate: an answer of y signs with a digest of the other fields' \
    "rc 0 and 'signed: <instant> $want' as the only changed line" "$got"
fi

# --- R3: no character on stdin ------------------------------------------------------------------
# The rc is the term that tells this branch apart (0 is a no, 1 a refusal); the file byte for byte
# unchanged and no `signed ` line on stdout are what "writes nothing" means.
got=""
d="$(campaign c-silent merge '2099-12-31 23:59' 25 200)"
cp "$d/delegation.md" "$BOX/c-silent.before"
worker delegate "$d"
[ "$W_RC" = 66 ] || got="rc $W_RC"
cmp -s "$BOX/c-silent.before" "$d/delegation.md" || got="${got:+$got; }the file changed: '$(signed_line "$d/delegation.md")'"
grep -q '^signed ' <<< "$W_OUT" && got="${got:+$got; }stdout says signed"
grep -q '^not signed — ' <<< "$W_OUT" || got="${got:+$got; }stdout gives no reason"
if [ -z "$got" ]; then
  pass 'delegate: no answer on stdin leaves rc 66 and writes nothing'
else
  fail 'delegate: no answer on stdin leaves rc 66 and writes nothing' \
    'rc 66, the file unchanged, a not signed reason' "$got"
fi

# --- R4: what signs nothing ---------------------------------------------------------------------
# Seven worlds. The no gets an n; the refusals get a YES, so that only the refusal stands
# between them and a signature. Each: the file unchanged, the reason that names its own branch, and
# the rc of that branch — 0 for the answer, 1 for the refusals, which are also never asked.
got=""
# refused <id> <rc> <reason prefix> — appends to got what the last delegate did wrong.
refused() {
  [ "$W_RC" = "$2" ] || got="${got:+$got; }$1: rc $W_RC"
  cmp -s "$BOX/$1.before" "$REPO/docs/campaigns/$1/delegation.md" \
    || got="${got:+$got; }$1: the file changed"
  grep -q "^not signed — $3" <<< "$W_OUT" || got="${got:+$got; }$1: no '$3' reason (stdout '${W_OUT##*$'\n'}')"
}
# Three more worlds are folded in, one per legibility rule that no world above reaches alone: an
# empty `lots:` (only "present and not empty" refuses it — an empty ceiling, level or instant also
# fails its own pattern), an instant that is not one (without its pattern, `expired` errors on the
# arithmetic, reads "not expired" and signs), and a ceiling that is not a number.
for w in 'c-no|pr|2099-12-31 23:59|25|200|n' 'c-expired|pr|2020-01-01 00:00|25|200|y' \
         'c-badlevel|everything|2099-12-31 23:59|25|200|y' 'c-nocap|pr|2099-12-31 23:59|25|-|y' \
         'c-nolots|pr|2099-12-31 23:59|25|200|y' 'c-badinstant|pr|next week|25|200|y' \
         'c-badcap|pr|2099-12-31 23:59|ten|200|y'; do
  IFS='|' read -r id lv ex m c a <<< "$w"
  d="$(campaign "$id" "$lv" "$ex" "$m" "$c")"
  [ "$id" != c-nolots ] || sed -i '2,/^---$/ s@^lots: .*@lots:@' "$d/delegation.md"
  cp "$d/delegation.md" "$BOX/$id.before"
  answer "$a"$'\n'
  worker_from "$BOX/in" delegate "$d"
  case "$id" in
    c-no) refused "$id" 0 'the answer was not y' ;;
    c-expired) refused "$id" 1 'expired' ;;
    *) refused "$id" 1 'illegible' ;;
  esac
  [ "$id" = c-no ] || ! grep -qF 'Sign this delegation?' <<< "$W_ERR" \
    || got="${got:+$got; }$id: the question was asked"
done
if [ -z "$got" ]; then
  pass 'delegate: n, an expired instant, an undefined level and a missing ceiling sign nothing'
else
  fail 'delegate: n, an expired instant, an undefined level and a missing ceiling sign nothing' \
    'each file unchanged, with its own reason and rc' "$got"
fi

# --- verdict ------------------------------------------------------------------------------------
if [ "$PROBES" -lt "$PROBE_FLOOR" ]; then
  printf '  FAIL  probe floor shrank to %d, expected at least %d — did a block stop being dispatched?\n' \
    "$PROBES" "$PROBE_FLOOR" >&2
  exit 93
fi
if [ "$fails" -eq 0 ]; then printf '  ok    worker verbs: %d probe(s)\n' "$PROBES"; exit 0; fi
printf '  FAIL  %d probe(s) failed\n' "$fails" >&2
exit 1
