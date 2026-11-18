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
#   R5  `level` answers, for a delegation the program itself signed, the level it was signed at —
#       each of the five, with `signed until <expires>` as the reason
#   R6  `level` answers assisted, naming its branch, for no delegation, an illegible one (the
#       template itself), an unsigned one and an expired one; expiry holds on both sides of the
#       SDD_WORKER_NOW seam, which moves time forward and never brings a delegation back; a
#       directory that is not there is a usage error, not an answer
#   R7  `level` answers assisted when any of the six keys, or the digest, changed after signing; a
#       line of prose in the body changes nothing, since only the frontmatter is read
#   R8  a near miss of a level name (a capital, a prefix, a word past the top, two levels, a glob)
#       is not a level: in `level:` the delegation is illegible, in a lot's Ceiling the lot is
#       capped at assisted
#   R9  above assisted, a campaign whose repo sets no ON_ESCALATION_CMD (empty, or no config) is
#       assisted — the same signed file answers merge where the pager is set; the config read is
#       the campaign's repo, never the cwd
#   R10 with --lot, a ceiling below the signed level lowers it and one above never raises it; a lot
#       outside `lots:`, or with no row in the table, is assisted; a --lot with no lot is rc 2
#   R11 `allows`, over a delegation signed at each of the five levels, answers the table of acts of
#       the mission plan (kept HERE, never read from the program) in every one of the 35 cells:
#       `allowed <act> at <level>` with rc 0, or `ask <act> needs <floor>, effective <level> — …`
#       with rc 1
#   R12 a word the table does not name — a near miss of an act, a level's name, an entry of the
#       table as written, nothing — is rc 2 with nothing on stdout, under a full delegation where
#       every act is allowed; so is a call of the wrong shape
#   R13 a delegation that does not hold (absent, illegible, unsigned, expired, edited after signing,
#       no pager) asks the owner for every act, naming the reason of its branch; the signed ones are
#       first witnessed allowing approve, so the ask is the break's and nothing else's
#   R14 with --lot, the lot's ceiling is the act's: under full, approve is asked on a lot capped at
#       merge and allowed on the lots that are not, and a lot with no row asks for it
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
# The seam and the pager are the fixture's to set: a value exported by whoever runs the suite would
# move the clock of every probe, or lend a pager to a repo that has none.
unset SDD_WORKER_NOW ON_ESCALATION_CMD

# Anti-vacuity: a block that stops being dispatched prints what a clean program prints. One unit of
# PROBES is one assertion outcome, and only pass() and fail() write it.
PROBE_FLOOR=14

pass() { PROBES=$((PROBES + 1)); printf '  ok    %s\n' "$1"; }
fail() { PROBES=$((PROBES + 1))
         printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }

BOX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-worker-XXXXXX")"
trap 'rm -rf "$BOX"' EXIT

# worker_from <stdin-file> <args...> — runs the program with <stdin-file> on stdin, from the cwd
# W_CWD names (the sensor's own when unset); PUBLISHES W_RC, W_OUT and W_ERR. Called, never
# substituted: under `$( )` the three globals would die with the subshell. `worker` is the same with
# no stdin at all, and `answer` writes what the next `worker_from "$BOX/in"` reads.
worker_from() {
  local in="$1"; shift
  W_RC=0
  ( CDPATH='' cd "${W_CWD:-.}" && exec "$WORKER" "$@" ) > "$BOX/out" 2> "$BOX/err" < "$in" || W_RC=$?
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
# Two more repos, the worlds with no pager: one whose config sets ON_ESCALATION_CMD to empty, one
# with no .sdd/config.sh at all.
NOPAGER="$BOX/nopager"; NOCONF="$BOX/noconf"
for r in "$NOPAGER" "$NOCONF"; do mkdir -p "$r/docs/campaigns"; git init -q -b main "$r"; done
mkdir -p "$NOPAGER/.sdd"
printf 'HANDOFF_DIR="docs/handoffs"\nON_ESCALATION_CMD=""\n' > "$NOPAGER/.sdd/config.sh"

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

# --- level: the fixtures ------------------------------------------------------------------------
# sign <dir> — the delegation of <dir> signed through the program's own delegate, a y on stdin,
# never with a digest written here: a probe built on a file the program did not sign would measure
# the sensor's idea of a signature. When it did not sign, it says so in got, and the probe that
# called it goes red on that instead of measuring an unsigned file.
sign() {
  answer $'y\n'
  worker_from "$BOX/in" delegate "$1"
  [ "$W_RC" = 0 ] && [[ "$(signed_line "$1/delegation.md")" =~ ^signed:\ [0-9] ]] \
    || got="${got:+$got; }fixture ${1##*/} did not sign: rc $W_RC, '${W_OUT##*$'\n'}'"
}

# level_is <label> <want> <args...> — runs level <args...>; appends to got unless it left rc 0 and
# exactly one line on stdout that starts with <want> (a literal, never a pattern).
level_is() {
  local label="$1" want="$2"; shift 2
  worker level "$@"
  [ "$W_RC" = 0 ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$want"* ]] \
    || got="${got:+$got; }$label: rc $W_RC, '$W_OUT' (want '$want…')"
}

# set_lots <campaign.md> <lot:ceiling>... — the rows of the template's lots table replaced by one
# row per argument, under the template's own header and separator. Says so in got when the rows did
# not land, so a probe never measures the template's two placeholder rows by accident.
set_lots() {
  local f="$1" r rows=""; shift
  for r in "$@"; do rows="$rows| ${r%%:*} | lote ${r%%:*} | ${r#*:} | 1 |\\n"; done
  awk -v rows="$rows" '/^\| L[0-9]/ { next } { print } /^\|---\|---\|---\|---\|$/ { printf "%s", rows }' \
    "$f" > "$f.new" && mv "$f.new" "$f"
  [ "$(grep -c '^| L[0-9]' "$f")" = "$#" ] || got="${got:+$got; }fixture $f: the lots rows did not land"
}

FAR='2099-12-31 23:59'

# --- R5: each of the five answers its own level -------------------------------------------------
# Five worlds, one per level, each signed and asked with the real clock: a program that answered a
# constant, or the ladder's top, matches one world at most. Each is asked from the cwd of the repo
# with no pager, so a program that read the pager from the cwd instead of the campaign's repo would
# answer assisted for four of them.
got=""
for lv in assisted pr plan merge full; do
  d="$(campaign "l-$lv" "$lv" "$FAR" 25 200)"
  sign "$d"
  W_CWD="$NOPAGER" level_is "$lv" "level $lv — signed until $FAR" "$d"
done
if [ -z "$got" ]; then
  pass 'level: a signed delegation answers its own level, for each of the five'
else
  fail 'level: a signed delegation answers its own level, for each of the five' \
    "level <the signed one> — signed until $FAR, for each" "$got"
fi

# --- R6: absent, illegible, unsigned, expired ---------------------------------------------------
# Each world answers assisted with its own reason — the reason is what tells the four branches
# apart, since every one of them is assisted. Two of them are siblings measured with them: a
# directory that is not there is a usage error (rc 2, nothing on stdout), never an answer about a
# campaign, and the illegible world is the template itself, placeholders and all.
# Expiry is measured on both sides of the SDD_WORKER_NOW seam. Forward: a delegation signed until
# FAR is expired at a seam one minute later and at a seam equal to FAR (the instant itself is not
# after it). Backward: a delegation signed under a clock stubbed into 2020 (a `date` on PATH that
# answers that one format and hands every other call to the real one), expiring in 2020, is
# expired under the real clock — and stays expired under a seam that names an instant before its
# expiry: the seam moves time forward and never brings a delegation back.
got=""
mkdir -p "$REPO/docs/campaigns/l-absent"
level_is absent 'level assisted — no delegation' "$REPO/docs/campaigns/l-absent"
worker level "$REPO/docs/campaigns/l-nowhere"
{ [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR"; } \
  || got="${got:+$got; }no directory: rc $W_RC, stdout '$W_OUT'"
mkdir -p "$REPO/docs/campaigns/l-template"
cp "$ROOT/templates/delegation.md" "$REPO/docs/campaigns/l-template/delegation.md"
level_is template 'level assisted — illegible: ' "$REPO/docs/campaigns/l-template"
d="$(campaign l-unsigned merge "$FAR" 25 200)"
level_is unsigned 'level assisted — unsigned' "$d"
d="$(campaign l-expiring merge "$FAR" 25 200)"
sign "$d"
level_is 'before the seam' "level merge — signed until $FAR" "$d"
SDD_WORKER_NOW='2100-01-01 00:00' level_is 'seam after' 'level assisted — expired: ' "$d"
SDD_WORKER_NOW="$FAR" level_is 'seam at the instant' 'level assisted — expired: ' "$d"
mkdir -p "$BOX/past"
printf '#!/bin/sh\n[ "$1" = "+%%Y-%%m-%%d %%H:%%M" ] && [ "$#" = 1 ] && { echo "2020-01-01 00:00"; exit 0; }\nexec %s "$@"\n' \
  "$(command -v date)" > "$BOX/past/date"
chmod +x "$BOX/past/date"
d="$(campaign l-past merge '2020-06-01 00:00' 25 200)"
PATH="$BOX/past:$PATH" sign "$d"
level_is 'signed in 2020' 'level assisted — expired: ' "$d"
SDD_WORKER_NOW='2020-03-01 00:00' level_is 'seam before the expiry' 'level assisted — expired: ' "$d"
if [ -z "$got" ]; then
  pass 'level: absent, illegible, unsigned and expired each answer assisted and say why'
else
  fail 'level: absent, illegible, unsigned and expired each answer assisted and say why' \
    'assisted, with the reason of each branch' "$got"
fi

# --- R7: edited after signing -------------------------------------------------------------------
# One signed file per edit, each first witnessed at its signed level, so the assisted that follows
# is the edit's and nothing else's: the level raised, the lots widened, a ceiling raised, and the
# digest itself rewritten. The body is the counter-world: only the frontmatter is read, so a line
# of prose added below it leaves the level standing — a digest of the whole file would not.
got=""
for w in 'l-edit-level|s@^level: merge$@level: full@' 'l-edit-lots|s@^lots: all$@lots: L1@' \
         'l-edit-cap|s@^budget_campaign_usd: 200$@budget_campaign_usd: 2000@' \
         'l-edit-digest|s@^\(signed: .*\)[0-9a-f]$@\1x@'; do
  id="${w%%|*}"
  d="$(campaign "$id" merge "$FAR" 25 200)"
  sign "$d"
  level_is "$id before" "level merge — signed until $FAR" "$d"
  cp "$d/delegation.md" "$BOX/$id.signed"
  sed -i "2,/^---\$/ ${w#*|}" "$d/delegation.md"
  cmp -s "$BOX/$id.signed" "$d/delegation.md" && got="${got:+$got; }fixture $id: the edit changed nothing"
  level_is "$id after" 'level assisted — edited after signing' "$d"
done
d="$(campaign l-edit-body merge "$FAR" 25 200)"
sign "$d"
printf '\nA line of prose added below the frontmatter after the signature.\n' >> "$d/delegation.md"
level_is 'body edited' "level merge — signed until $FAR" "$d"
if [ -z "$got" ]; then
  pass 'level: a delegation edited after signing answers assisted'
else
  fail 'level: a delegation edited after signing answers assisted' \
    'assisted — edited after signing for each frontmatter edit, the level for a body edit' "$got"
fi

# --- R8: a name outside the ladder --------------------------------------------------------------
# Near misses of a level, each in the level: key of an otherwise legible delegation: a capital, a
# prefix, a word past the top, two levels in one value, and a glob. Each is illegible (the reason
# says so — unsigned would mean the ladder let it through, since none of them can be signed). A
# match by substring of the ladder, by prefix or by pattern passes at least one of them. The same
# rule holds for the lot's Ceiling cell: a ceiling that is not a level caps the lot at assisted,
# never reads as no ceiling.
got=""
for lv in Merge mer fullest 'pr plan' '*'; do
  d="$(campaign "l-name-${#lv}-${lv//[^a-zA-Z]/}" "$lv" "$FAR" 25 200)"
  level_is "level '$lv'" 'level assisted — illegible: level ' "$d"
done
d="$(campaign l-badceiling merge "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:Plan' 'L2:*'
sign "$d"
level_is 'ceiling Plan' 'level assisted — capped by the lot' "$d" --lot L1
level_is 'ceiling *' 'level assisted — capped by the lot' "$d" --lot L2
if [ -z "$got" ]; then
  pass 'level: a name outside the ladder is not a level'
else
  fail 'level: a name outside the ladder is not a level' \
    'assisted — illegible for each level, assisted for each ceiling' "$got"
fi

# --- R9: no pager -------------------------------------------------------------------------------
# One signed delegation, three repos: the fixture repo (pager set), NOPAGER and NOCONF. The same
# file — copied, signature and all — answers merge in the first and assisted with "no pager" in the
# other two: the difference is the config and nothing else. Each is asked from the cwd of a repo with the opposite
# answer, so a program that read the cwd's config instead of the campaign's answers the other
# side. A signed assisted, in the repo with no pager, answers its own level: the rule is about the
# levels that act alone, and assisted acts on nothing.
got=""
d="$(campaign l-pager merge "$FAR" 25 200)"
sign "$d"
cp -a "$d" "$NOPAGER/docs/campaigns/"; cp -a "$d" "$NOCONF/docs/campaigns/"
W_CWD="$NOPAGER" level_is 'pager set' "level merge — signed until $FAR" "$d"
W_CWD="$REPO" level_is 'pager empty' 'level assisted — no pager' "$NOPAGER/docs/campaigns/l-pager"
W_CWD="$REPO" level_is 'no config' 'level assisted — no pager' "$NOCONF/docs/campaigns/l-pager"
d="$(campaign l-pager-assisted assisted "$FAR" 25 200)"
sign "$d"
cp -a "$d" "$NOPAGER/docs/campaigns/"
W_CWD="$REPO" level_is 'assisted, no pager' "level assisted — signed until $FAR" \
  "$NOPAGER/docs/campaigns/l-pager-assisted"
if [ -z "$got" ]; then
  pass 'level: above assisted with no pager answers assisted'
else
  fail 'level: above assisted with no pager answers assisted' \
    'merge where the pager is set, assisted — no pager where it is not' "$got"
fi

# --- R10: the lot ------------------------------------------------------------------------------
# A merge delegation over a table of five lots: no ceiling, plan, full, pr, and L11 with none.
# Signed for all lots: the plan and pr ceilings lower it, the full ceiling does not raise it, and a
# lot the table has no row for is not covered. Signed for `L11 L3` only: L1 (a prefix of L11) and L2
# are not covered, L11 and L3 are. A --lot with no lot, or an empty one, is a usage error and never
# the uncapped level.
got=""
for id in l-lots l-some; do
  d="$(campaign "$id" merge "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L2:plan' 'L3:full' 'L4:pr' 'L11:-'
  [ "$id" = l-lots ] || sed -i '2,/^---$/ s@^lots: .*@lots: L11 L3@' "$d/delegation.md"
  sign "$d"
done
d="$REPO/docs/campaigns/l-lots"
level_is 'all, L1' "level merge — signed until $FAR" "$d" --lot L1
level_is 'all, L2' 'level plan — capped by the lot' "$d" --lot L2
level_is 'all, L3' "level merge — signed until $FAR" "$d" --lot L3
level_is 'all, L4' 'level pr — capped by the lot' "$d" --lot L4
level_is 'all, L9' 'level assisted — lot not covered' "$d" --lot L9
d="$REPO/docs/campaigns/l-some"
level_is 'some, L1' 'level assisted — lot not covered' "$d" --lot L1
level_is 'some, L2' 'level assisted — lot not covered' "$d" --lot L2
level_is 'some, L11' "level merge — signed until $FAR" "$d" --lot L11
level_is 'some, L3' "level merge — signed until $FAR" "$d" --lot L3
for args in '--lot' '--lot|' '--lit|L2'; do
  IFS='|' read -ra a <<< "$args"
  [ "$args" != '--lot|' ] || a=(--lot '')
  worker level "$d" "${a[@]}"
  { [ "$W_RC" = 2 ] && [ -z "$W_OUT" ]; } || got="${got:+$got; }level ${a[*]}: rc $W_RC, stdout '$W_OUT'"
done
if [ -z "$got" ]; then
  pass 'level: the lot ceiling lowers the level and never raises it, and an uncovered lot is assisted'
else
  fail 'level: the lot ceiling lowers the level and never raises it, and an uncovered lot is assisted' \
    'the lower of the signed level and the ceiling, assisted where the lot is not covered' "$got"
fi

# --- allows: the fixtures -----------------------------------------------------------------------
# The table of acts as the mission plan writes it, kept HERE and never read from the program: one
# row per act, the lowest level that grants it, then one letter per level of the ladder in order
# (assisted pr plan merge full), y where the act is allowed. A program whose table moved one act,
# or that compared the ranks the wrong way round, differs in at least one cell.
LEVELS=(assisted pr plan merge full)
ACT_TABLE=('run pr nyyyy' 'pr pr nyyyy' 'review pr nyyyy' 'plan plan nnyyy'
           'merge merge nnnyy' 'postmerge merge nnnyy' 'approve full nnnny')

# allows_is <label> <rc> <want> <args...> — runs allows <args...>; appends to got unless it left
# <rc> and exactly one line on stdout — equal to <want> when <rc> is 0 (the allowed line is whole),
# starting with <want> otherwise (the ask line ends in the level's reason). <want> is a literal,
# never a pattern.
allows_is() {
  local label="$1" rc="$2" want="$3"; shift 3
  worker allows "$@"
  if [ "$W_RC" = "$rc" ] && [[ "$W_OUT" != *$'\n'* ]] \
     && { [[ "$rc" = 0 && "$W_OUT" == "$want" ]] || [[ "$rc" != 0 && "$W_OUT" == "$want"* ]]; }; then
    return 0
  fi
  got="${got:+$got; }$label: rc $W_RC, '$W_OUT' (want rc $rc, '$want')"
}

# --- R11: five levels by seven acts -------------------------------------------------------------
# Every cell asked of a delegation signed at its level, in a repo with a pager, and counted: the
# count is the witness that the 35 cells were asked, since a loop that asked none leaves got empty.
got=""; cells=0
for i in "${!LEVELS[@]}"; do
  lv="${LEVELS[$i]}"
  d="$(campaign "a-$lv" "$lv" "$FAR" 25 200)"
  sign "$d"
  for row in "${ACT_TABLE[@]}"; do
    read -r act floor yes <<< "$row"
    before="$got"
    if [ "${yes:$i:1}" = y ]; then
      allows_is "$lv/$act" 0 "allowed $act at $lv" "$d" "$act"
    else
      allows_is "$lv/$act" 1 "ask $act needs $floor, effective $lv — signed until $FAR" "$d" "$act"
    fi
    [ "$got" != "$before" ] || cells=$((cells + 1))
  done
done
[ "$cells" = 35 ] || got="${got:+$got; }$cells of 35 cells answered the table"
if [ -z "$got" ]; then
  pass 'allows: the five levels by the seven acts answer the table, 35 of 35'
else
  fail 'allows: the five levels by the seven acts answer the table, 35 of 35' \
    'allowed where the table says y, ask with the floor where it says n' "$got"
fi

# --- R12: a word that is not an act -------------------------------------------------------------
# Asked of the full delegation, where every act of the table is allowed: a word read as any act, or
# as any level, is allowed there, so rc 2 and an empty stdout are what tell the refusal apart, and
# the stderr names the word. The near misses: an unknown word, a capital, a prefix, two acts in one
# argument, a glob, a level's name, an entry of the table as the program may write it, and nothing.
# The calls of the wrong shape ride along: no act, a --lot with no lot, a misspelt flag, and a
# directory that is not there.
got=""
d="$REPO/docs/campaigns/a-full"
for act in frobnicate Merge merg 'run pr' '*' assisted 'run:pr' ''; do
  worker allows "$d" "$act"
  { [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -qF "'$act' is not an act" <<< "$W_ERR" \
      && grep -q '^usage: sdd-worker ' <<< "$W_ERR"; } \
    || got="${got:+$got; }act '$act': rc $W_RC, stdout '$W_OUT', stderr '${W_ERR%%$'\n'*}'"
done
for args in "$d" "$d|run|--lot" "$d|run|--lit|L1" "$REPO/docs/campaigns/a-nowhere|run"; do
  IFS='|' read -ra a <<< "$args"
  worker allows "${a[@]}"
  { [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR"; } \
    || got="${got:+$got; }allows ${a[*]}: rc $W_RC, stdout '$W_OUT'"
done
if [ -z "$got" ]; then
  pass 'allows: an act outside the table leaves rc 2 and is never allowed'
else
  fail 'allows: an act outside the table leaves rc 2 and is never allowed' \
    "rc 2, nothing on stdout, the word named on stderr" "$got"
fi

# --- R13: a delegation that does not hold -------------------------------------------------------
# Six worlds, each signed (where it is signed at all) at full, so that only the break stands
# between the act and an allow: absent, the template, unsigned, expired (a seam one minute past
# FAR), edited after signing (lots narrowed), and no pager (the same signed file copied to
# the repo whose config sets none). The three signed ones are first witnessed allowing approve. Each
# world asks for each of the seven acts, effective assisted, with its own reason — and the count is
# the witness that the 42 were asked.
got=""; asks=0
mkdir -p "$REPO/docs/campaigns/a-absent" "$REPO/docs/campaigns/a-template"
cp "$ROOT/templates/delegation.md" "$REPO/docs/campaigns/a-template/delegation.md"
campaign a-unsigned full "$FAR" 25 200 > /dev/null
for id in a-expiring a-edited a-pager; do
  d="$(campaign "$id" full "$FAR" 25 200)"
  sign "$d"
  allows_is "$id before" 0 'allowed approve at full' "$d" approve
done
sed -i '2,/^---$/ s@^lots: all$@lots: L1@' "$REPO/docs/campaigns/a-edited/delegation.md"
cp -a "$REPO/docs/campaigns/a-pager" "$NOPAGER/docs/campaigns/"
for w in "a-absent||no delegation" "a-template||illegible: " "a-unsigned||unsigned" \
         "a-expiring|2100-01-01 00:00|expired: " "a-edited||edited after signing" \
         "$NOPAGER/docs/campaigns/a-pager||no pager"; do
  IFS='|' read -r id seam why <<< "$w"
  if [[ "$id" == /* ]]; then d="$id"; else d="$REPO/docs/campaigns/$id"; fi
  for row in "${ACT_TABLE[@]}"; do
    read -r act floor _ <<< "$row"
    before="$got"
    SDD_WORKER_NOW="$seam" allows_is "${id##*/}/$act" 1 \
      "ask $act needs $floor, effective assisted — $why" "$d" "$act"
    [ "$got" != "$before" ] || asks=$((asks + 1))
  done
done
[ "$asks" = 42 ] || got="${got:+$got; }$asks of 42 acts asked the owner"
if [ -z "$got" ]; then
  pass 'allows: a broken delegation asks the owner for every act'
else
  fail 'allows: a broken delegation asks the owner for every act' \
    'ask <act> needs <floor>, effective assisted — <the reason of the break>, for each' "$got"
fi

# --- R14: the lot's ceiling is the act's --------------------------------------------------------
# A full delegation over three lots: no ceiling, merge, full. With no lot, and on L1 and L3, approve
# is allowed at full — the witness that the delegation grants it; on L2 it is asked, and merge is
# allowed there at merge, so the cap is the lot's ceiling and not a refusal of the lot. A lot the
# table has no row for asks too.
got=""
d="$(campaign a-lots full "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:merge' 'L3:full'
sign "$d"
allows_is 'no lot' 0 'allowed approve at full' "$d" approve
allows_is 'L1, no ceiling' 0 'allowed approve at full' "$d" approve --lot L1
allows_is 'L3, ceiling full' 0 'allowed approve at full' "$d" approve --lot L3
allows_is 'L2, approve' 1 'ask approve needs full, effective merge — capped by the lot' "$d" approve --lot L2
allows_is 'L2, merge' 0 'allowed merge at merge' "$d" merge --lot L2
allows_is 'L9, no row' 1 'ask approve needs full, effective assisted — lot not covered' "$d" approve --lot L9
if [ -z "$got" ]; then
  pass 'allows: the lot ceiling stops approve on a capped lot under full'
else
  fail 'allows: the lot ceiling stops approve on a capped lot under full' \
    'approve asked on the lot capped at merge, allowed where the lot is not capped' "$got"
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
