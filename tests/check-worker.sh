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
#   R15 `budget` sums the cost_usd of the ledger lines whose mission is one of the campaign's — the
#       folders under the repo's HANDOFF_DIR whose 00-missao.md declares exactly that campaign:, in
#       the checkout of the campaign AND in every linked worktree of its repo, each mission once —
#       and no other line: not another campaign's, not a longer id's, not a mission of no campaign;
#       a malformed line costs only itself; the ledger is found by SDD_STATE_DIR, else under $HOME
#   R16 at the campaign ceiling or above it `budget` leaves rc 1, and below it rc 0, the comparison
#       being numeric (10 is above 8.5); so do the answers it cannot have — no delegation or an
#       illegible one (no ceiling), a directory outside a git checkout, a ledger that does not read
#   R17 a missing or empty ledger is zero spent (rc 0), and the line prints the mission cap of the
#       delegation, the one the worker passes to `sdd run` as BUDGET_MISSION_USD
#   R18 `next` plans a lot no mission of the campaign declares (another campaign's mission on the
#       lot, or this campaign's on another lot, is not it), and approves a mission whose aprovacao:
#       the runner's gate does not admit — empty, the template's placeholder, or empty in one copy
#   R19 an approved mission with no pull request is run, found also when it lives only in a linked
#       worktree (in flight); an open pull request is reviewed, a closed one beside it changing
#       nothing; `auto` is approved as `humano-…` is
#   R20 a lot with a merged pull request is skipped, and a queue whose every lot is merged is done;
#       the queue is the table under `## Lotes` and nothing after it; the stub answers like the real
#       gh, so a call without --state all reads no merged pull request
#   R21 the line `ahead plan <lot>` follows a run or a review when the lot after the deciding one has
#       no mission, and never otherwise
#   R22 a gh that fails, or answers anything but an array of {number, state} with a known state, is
#       rc 3 with no act on stdout — never "no pull request"; a pull request closed without merge,
#       two missions on one lot, an approved mission with no branch, no campaign.md and an empty
#       queue stop (rc 1); a call of the wrong shape is rc 2. gh runs at the repo root, or the stub
#       refuses it
#   R23 `pr-ready` answers `ready <the full head sha>` when the five items hold on one sha: the
#       newest round (by number: r10 after an r9 graded B) grades A in every row, the bold Overall
#       one included, and names a reviewed head after which only the mission folder changed — a file
#       whose name git quotes by default among them, and nothing at all when it names the head
#       itself; the newest receipt of the Codex bot is for that sha, completed, with no unresolved
#       finding, and it is on the second page, so the comments are read with --paginate; every review
#       thread is resolved; the pull request is open and mergeable; the local HEAD is the head
#   R24 the review item fails for a grade other than A (B in a strict row, in an indented one, A- in
#       the bold Overall one), a newest round that names no head, or names HEAD, or a sha that is no
#       commit, a change outside the mission folder after the reviewed head — a move into the folder
#       included, so renames are not followed —, a pull request head this checkout does not have, no
#       round, a round with no grade table, the root of the checkout given as the mission folder, and
#       a folder outside any git checkout; an older round graded A beside the newest changes nothing
#   R25 the codex item fails for a receipt for another sha, one not completed, one with an unresolved
#       finding or a null for it, no receipt at all, a newest receipt whose state does not parse (an
#       older good one is never read in its place), and a receipt for the head posted by somebody
#       other than the bot — anybody can comment on a public repo; the receipt is the real one of PR
#       409
#   R26 the threads item fails for one unresolved thread, and for more threads than the hundred read
#   R27 the mergeable item fails for a conflicting pull request, a closed one GitHub calls
#       mergeable, and a merged one (the answer of PR 409, copied)
#   R28 the head item fails for a local HEAD ahead of the pull request head, and for one behind it
#   R29 a gh that fails — before answering, or after printing a full answer — or answers off its
#       contract, on the pull request, the repo, the comments or the threads, is rc 3 with nothing on
#       stdout and the call named on stderr: never ready, and never a not-ready a caller would set out
#       to fix; a call of the wrong shape is rc 2
#   R30 commands/sdd-worker.md writes a call of every verb bin/sdd-worker dispatches — the verbs are
#       read from the program's main(), so a verb it gains is a verb the command owes
#   R31 each of the seven acts of the table kept HERE has one heading in the command, and the first
#       line under it is the literal `sdd-worker allows <campaign-dir> <act> --lot <L>`
#   R32 the command writes the five stops (one numbered line each, with the pager and the journal),
#       the never list and the context rules, each phrase on a line of its own section
#
# The command is prose, and no mutant of bin/ reaches it, so R30 to R32 carry their own negative
# control: each checker runs on the file, where it has to miss nothing, and on copies with one thing
# taken out, where it has to name exactly that thing. A checker that never misses is decoration.
#
# The money is measured under a decimal comma: every budget call runs with LC_ALL set to pt_BR when
# this machine has the locale and it is armed (its printf refuses 8.5), so a verb that formats or
# sums outside LC_ALL=C answers wrong here. Declared limit: on a machine without the locale that
# rule goes unmeasured, and the sensor says nothing about it.
#
# Every green line is `  ok    <family>: <assertion>` on stdout, and each family (`usage: `, the
# verbs, and `command: `) prints exactly the assertions the mission plan names — the checkpoint
# counts them. Inside a mutant (SDD_MUTANT set) fail() ends the sensor at the first red, after printing it;
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
PROBE_FLOOR=32

pass() { PROBES=$((PROBES + 1)); printf '  ok    %s\n' "$1"; }
fail() { PROBES=$((PROBES + 1))
         printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$1" "$2" "$3" >&2
         fails=$((fails + 1)); [ -z "${SDD_MUTANT:-}" ] || exit 1; }

BOX="$(mktemp -d "${TMPDIR:-/tmp}/sdd-worker-XXXXXX")"
trap 'rm -rf "$BOX"' EXIT
# The ledger is the fixture's for the whole sensor: no probe ever reads the real one. The one probe
# of the $HOME fallback unsets this in a subshell, with HOME in the box.
export SDD_STATE_DIR="$BOX/state"

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

# --- budget: the fixtures -----------------------------------------------------------------------
# mission <checkout> <handoff dir> <id> <campaign> — a mission folder made from the kit's own
# template, its missao: and campaign: replaced; a <campaign> of `-` keeps the template's
# placeholder, a mission that belongs to no campaign. Only the frontmatter is edited, so a template
# whose campaign: key moved leaves the placeholder and the probe that counts the mission goes red.
mission() {
  mkdir -p "$1/$2/$3"
  if [ "$4" = - ]; then
    cp "$ROOT/templates/missao.md" "$1/$2/$3/00-missao.md"
  else
    sed "2,/^---\$/ { s@^missao: .*@missao: $3@; s@^campaign: .*@campaign: $4@; }" \
      "$ROOT/templates/missao.md" > "$1/$2/$3/00-missao.md"
  fi
}

# spent <mission> <event> <cost> — one line of the ledger in the shape the runner writes it (a
# session line of the real ledger, trimmed to the keys around the two a reader of the spend reads);
# <cost> is raw JSON: a number, or the null the runner writes for the events that carry none.
spent() {
  printf '{"v":1,"ts":"2099-01-01T00:00:00-03:00","event":"%s","invocation":"run","project":"fixture","repo":"%s","mission":"%s","phase":"EXEC","rc":0,"cost_usd":%s}\n' \
    "$2" "$REPO" "$1" "$3"
}

# The decimal comma (see the header): the locale only when it is armed, empty otherwise.
NUM_POISON=pt_BR.UTF-8
[ "$(LC_ALL="$NUM_POISON" bash -c 'printf "%.2f" 8.5' 2>/dev/null)" != 8.50 ] || NUM_POISON=""

# budget_is <label> <rc> <want> <args...> — runs budget <args...> under NUM_POISON; appends to got
# unless it left <rc> and exactly one line on stdout that starts with <want> (a literal, never a
# pattern).
budget_is() {
  local label="$1" rc="$2" want="$3"; shift 3
  LC_ALL="$NUM_POISON" worker budget "$@"
  [ "$W_RC" = "$rc" ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$want"* ]] \
    || got="${got:+$got; }$label: rc $W_RC, '$W_OUT' (want rc $rc, '$want…')"
}

H=docs/handoffs

# --- R15: the campaign's missions and no other --------------------------------------------------
# Campaign b-sum owns three missions: two in the fixture repo, one only in a linked worktree of it
# (the shape of a mission in flight, whose folder reaches the campaign's checkout only with the
# merge), and the worktree carries a second copy of one of the two, which is still one mission.
# Their lines sum 8.50 — two sessions, a close, and an escalation that carries null. Around them,
# lines a looser reader would add: another campaign's (40), a campaign whose id starts with b-sum
# (100), a mission of no campaign (30), and a truncated line of one of the three. The same file
# answers through SDD_STATE_DIR and through $HOME/.sdd. A second repo sets HANDOFF_DIR to another
# folder and keeps a decoy mission of its campaign under docs/handoffs: only the declared one counts.
got=""
d="$(campaign b-sum pr "$FAR" 25 100)"
mission "$REPO" "$H" 20990101-b-one b-sum
mission "$REPO" "$H" 20990102-b-two b-sum
mission "$REPO" "$H" 20990103-b-other b-other
mission "$REPO" "$H" 20990104-b-longer b-sum-2
mission "$REPO" "$H" 20990105-b-none -
git -C "$REPO" -c user.name=fixture -c user.email=fixture@example.com commit -q --allow-empty -m fixture
git -C "$REPO" worktree add -q -b fixture-side "$BOX/wt" > /dev/null 2>&1 \
  || got="fixture: the linked worktree was not created"
mission "$BOX/wt" "$H" 20990106-b-wt b-sum
mission "$BOX/wt" "$H" 20990101-b-one b-sum
HD="$BOX/hd"
mkdir -p "$HD/.sdd" "$HD/docs/campaigns"
git init -q -b main "$HD"
printf 'HANDOFF_DIR="work/missions"\nON_ESCALATION_CMD="true"\n' > "$HD/.sdd/config.sh"
cp -a "$(campaign b-hd pr "$FAR" 25 100)" "$HD/docs/campaigns/"
mission "$HD" work/missions 20990107-b-hd-in b-hd
mission "$HD" "$H" 20990108-b-hd-decoy b-hd
mkdir -p "$BOX/state" "$BOX/home/.sdd"
{ spent 20990101-b-one session 1.25; spent 20990101-b-one session 2.5
  spent 20990102-b-two close 0.75; spent 20990102-b-two blocked null
  printf '{"v":1,"event":"session","mission":"20990101-b-one","cost_usd":\n'
  spent 20990103-b-other session 40; spent 20990104-b-longer session 100
  spent 20990105-b-none session 30; spent 20990106-b-wt session 4
  spent 20990107-b-hd-in session 2; spent 20990108-b-hd-decoy session 16
} > "$BOX/state/autonomy-log.jsonl"
cp "$BOX/state/autonomy-log.jsonl" "$BOX/home/.sdd/"
want='campaign US$ 8.50 of 100.00 — 3 mission(s); mission cap US$ 25.00'
budget_is 'SDD_STATE_DIR' 0 "$want" "$d"
( unset SDD_STATE_DIR; HOME="$BOX/home" budget_is 'HOME' 0 "$want" "$d"; printf '%s' "$got" > "$BOX/got" )
got="$(cat "$BOX/got")"
budget_is 'HANDOFF_DIR' 0 'campaign US$ 2.00 of 100.00 — 1 mission(s); mission cap US$ 25.00' \
  "$HD/docs/campaigns/b-hd"
if [ -z "$got" ]; then
  pass "budget: the sum counts the campaign's missions and no other"
else
  fail "budget: the sum counts the campaign's missions and no other" \
    "$want, and 2.00 over 1 mission where HANDOFF_DIR moves" "$got"
fi

# --- R16: at the ceiling or above it ------------------------------------------------------------
# Four delegations of one campaign, b-cap, whose two missions spent 8.50: a ceiling of 8.5 (at it)
# and of 8 (above it) leave rc 1, of 8.51 (the boundary) and of 10 (which a comparison of text puts
# below 8.5) leave rc 0. The answers it cannot have ride along, each over a directory that answers
# rc 0 with the fixture's ledger, so the rc 1 is the break's: no delegation, a delegation with no
# campaign ceiling, the same campaign copied outside any git checkout, and a ledger that is a
# directory.
got=""
mission "$REPO" "$H" 20990111-b-cap-1 b-cap
mission "$REPO" "$H" 20990112-b-cap-2 b-cap
{ spent 20990111-b-cap-1 session 5.25; spent 20990112-b-cap-2 close 3.25; } >> "$BOX/state/autonomy-log.jsonl"
for w in 'b-at|8.5|1|8.50' 'b-above|8|1|8.00' 'b-edge|8.51|0|8.51' 'b-below|10|0|10.00'; do
  IFS='|' read -r id cap rc shown <<< "$w"
  d="$(campaign "$id" pr "$FAR" 25 "$cap")"
  sed -i '2,/^---$/ s@^campaign: .*@campaign: b-cap@' "$d/delegation.md"
  budget_is "$id" "$rc" "campaign US\$ 8.50 of $shown — 2 mission(s); mission cap US\$ 25.00" "$d"
done
mkdir -p "$REPO/docs/campaigns/b-absent"
budget_is 'no delegation' 1 'no ceiling — no delegation' "$REPO/docs/campaigns/b-absent"
d="$(campaign b-nocap pr "$FAR" 25 -)"
sed -i '2,/^---$/ s@^campaign: .*@campaign: b-cap@' "$d/delegation.md"
budget_is 'no campaign ceiling' 1 'no ceiling — illegible: budget_campaign_usd' "$d"
mkdir -p "$BOX/loose"
cp -a "$REPO/docs/campaigns/b-below" "$BOX/loose/"
git -C "$BOX/loose" rev-parse --show-toplevel > /dev/null 2>&1 \
  && got="${got:+$got; }fixture: $BOX/loose is inside a git checkout"
budget_is 'outside a checkout' 1 'no spend — ' "$BOX/loose/b-below"
mkdir -p "$BOX/state-dir/autonomy-log.jsonl"
SDD_STATE_DIR="$BOX/state-dir" budget_is 'a ledger that does not read' 1 'no spend — ' \
  "$REPO/docs/campaigns/b-below"
if [ -z "$got" ]; then
  pass 'budget: at the ceiling or above it the verb leaves rc 1'
else
  fail 'budget: at the ceiling or above it the verb leaves rc 1' \
    'rc 1 at 8.5 and 8, rc 0 at 8.51 and 10, rc 1 for each answer it cannot have' "$got"
fi

# --- R17: no ledger yet -------------------------------------------------------------------------
# One mission of the campaign and three ledgers that hold nothing: a state directory that does not
# exist, one with no ledger file, and an empty ledger. Each is zero spent and rc 0, and the line
# names the mission cap of this delegation, 37.50 — R15 and R16 print 25.00, so a constant fails
# one of the two.
got=""
d="$(campaign b-fresh pr "$FAR" 37.5 200)"
mission "$REPO" "$H" 20990121-b-fresh b-fresh
mkdir -p "$BOX/state-empty" "$BOX/state-blank"
: > "$BOX/state-blank/autonomy-log.jsonl"
for s in state-none state-empty state-blank; do
  SDD_STATE_DIR="$BOX/$s" budget_is "$s" 0 \
    'campaign US$ 0.00 of 200.00 — 1 mission(s); mission cap US$ 37.50' "$d"
done
if [ -z "$got" ]; then
  pass 'budget: a missing ledger is zero spent, and the mission cap is printed'
else
  fail 'budget: a missing ledger is zero spent, and the mission cap is printed' \
    'campaign US$ 0.00 of 200.00 — 1 mission(s); mission cap US$ 37.50, rc 0, for each' "$got"
fi

# --- next: the fixtures -------------------------------------------------------------------------
# lot_mission <checkout> <id> <campaign> <lot> <branch> <approval> — a mission folder of <campaign>
# and <lot> under the checkout's docs/handoffs, made from the kit's own template; an <approval> of
# `-` leaves aprovacao: empty and `=` keeps the template's placeholder. Only the frontmatter is
# edited, so a template whose lot: or branch: key moved leaves its placeholder and the probe that
# finds the mission goes red.
lot_mission() {
  local ap="$6"
  [ "$ap" != - ] || ap=""
  mkdir -p "$1/$H/$2"
  sed "2,/^---\$/ {
         s@^missao: .*@missao: $2@
         s@^campaign: .*@campaign: $3@
         s@^lot: .*@lot: $4@
         s@^branch: .*@branch: $5@
       }" "$ROOT/templates/missao.md" > "$1/$H/$2/00-missao.md"
  [ "$ap" = = ] || sed -i "2,/^---\$/ s@^aprovacao: .*@aprovacao: $ap@" "$1/$H/$2/00-missao.md"
}

# The gh stub answers the one question next asks, `gh pr list --head <branch> --state all --json
# number,state`, from $BOX/prs/<branch>: a JSON array in the shape the real gh printed on 2026-11-17
# for `gh pr list --head feat/o-revisor-so-acha --state all --json number,state` in this repo
# (`[{"number":34,"state":"MERGED"}]`), or `[]` when there is no file, which is what it prints for a
# head with no pull request. Without --state all it keeps only the OPEN ones, as the real gh does by
# default. A <branch>.fail beside the file makes it fail, and a <branch>.raw is printed as it is. It
# answers only from the root of the fixture repo, which is where gh infers the repository from.
mkdir -p "$BOX/stub" "$BOX/prs"
REPO_REAL="$(CDPATH='' cd "$REPO" && pwd -P)"
cat > "$BOX/stub/gh" <<STUB
#!/usr/bin/env bash
[ "\$(pwd -P)" = "$REPO_REAL" ] || { echo "gh stub: run from \$(pwd -P), not the repo root" >&2; exit 9; }
[ "\${1:-} \${2:-}" = "pr list" ] || { echo "gh stub: unexpected call: \$*" >&2; exit 9; }
shift 2
head="" all=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    --head) head="\$2"; shift 2 ;;
    --state) [ "\$2" != all ] || all=1; shift 2 ;;
    --json) [ "\$2" = number,state ] || { echo "gh stub: --json \$2" >&2; exit 9; }; shift 2 ;;
    *) echo "gh stub: unexpected argument \$1" >&2; exit 9 ;;
  esac
done
[ -n "\$head" ] || { echo "gh stub: no --head" >&2; exit 9; }
f="$BOX/prs/\$head"
[ ! -e "\$f.fail" ] || { echo "HTTP 502: Bad Gateway" >&2; exit 1; }
[ ! -e "\$f.raw" ] || { cat "\$f.raw"; exit 0; }
[ -e "\$f" ] || { echo '[]'; exit 0; }
if [ -n "\$all" ]; then cat "\$f"; else jq -c '[.[] | select(.state == "OPEN")]' "\$f"; fi
STUB
chmod +x "$BOX/stub/gh"

# prs <branch> <json> — what the stub answers for <branch>.
prs() { printf '%s\n' "$2" > "$BOX/prs/$1"; }

# next_is <label> <rc> <want> <ahead> <dir> — runs next over <dir> with the gh stub first on the
# PATH; appends to got unless it left <rc> and a first line on stdout that starts with <want> (a
# literal, never a pattern), followed by no other line when <ahead> is empty, or else by exactly the
# line <ahead>.
next_is() {
  local label="$1" rc="$2" want="$3" ahead="$4" l1 rest=""
  PATH="$BOX/stub:$PATH" worker next "$5"
  l1="${W_OUT%%$'\n'*}"
  [[ "$W_OUT" != *$'\n'* ]] || rest="${W_OUT#*$'\n'}"
  [ "$W_RC" = "$rc" ] && [[ "$l1" == "$want"* ]] && [ "$rest" = "$ahead" ] \
    || got="${got:+$got; }$label: rc $W_RC, '${W_OUT//$'\n'/ / }' (want rc $rc, '$want…'${ahead:+, then '$ahead'})"
}

N=20990200

# --- R18: no mission is planned, an empty approval is approved ----------------------------------
# Campaign n-plan has no mission on L1, and around it the missions a looser reader would take for
# it: another campaign's on L1, and this campaign's on L2 — each approved with a pull request open,
# so taking one for L1 answers review. Three missions are not approved: an empty aprovacao:, the
# template's placeholder (a value, which the runner's gate does not admit), and a mission whose copy
# in the campaign's checkout is approved while its copy in the linked worktree is not. None of the
# three has a pull request: a program that skipped the approval would answer run.
got=""
d="$(campaign n-plan pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 1))-n-other" n-other L1 n-other-b humano-2099-01-01
lot_mission "$REPO" "$((N + 2))-n-plan-l2" n-plan L2 n-plan-l2-b humano-2099-01-01
prs n-other-b '[{"number":11,"state":"OPEN"}]'
prs n-plan-l2-b '[{"number":12,"state":"OPEN"}]'
next_is 'no mission' 0 'plan L1 - — ' '' "$d"
for w in 'n-empty|-' 'n-placeholder|=' 'n-copies|humano-2099-01-01'; do
  IFS='|' read -r id a <<< "$w"
  d="$(campaign "$id" pr "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-'
  lot_mission "$REPO" "$((N + 3))-$id" "$id" L1 "$id-b" "$a"
  [ "$id" != n-copies ] || lot_mission "$BOX/wt" "$((N + 3))-$id" "$id" L1 "$id-b" -
  next_is "$id" 0 "approve L1 $((N + 3))-$id — " '' "$d"
done
if [ -z "$got" ]; then
  pass 'next: a lot with no mission is planned, and one with an empty approval is approved'
else
  fail 'next: a lot with no mission is planned, and one with an empty approval is approved' \
    'plan L1 - for the lot with no mission, approve L1 <mission> for each one not approved' "$got"
fi

# --- R19: approved with no pull request is run, an open one is reviewed -------------------------
# The mission of n-run lives only in the linked worktree, the shape of a lot in flight: a reader of
# the campaign's checkout alone would plan it again. The one of n-review is approved `auto` — the
# other spelling the runner's gate admits — and its branch has a closed pull request beside the open
# one, so the open one decides.
got=""
d="$(campaign n-run pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$BOX/wt" "$((N + 4))-n-run" n-run L1 n-run-b humano-2099-01-01
next_is 'approved, no pull request' 0 "run L1 $((N + 4))-n-run — " '' "$d"
d="$(campaign n-review pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$REPO" "$((N + 5))-n-review" n-review L1 n-review-b auto
prs n-review-b '[{"number":5,"state":"CLOSED"},{"number":7,"state":"OPEN"}]'
next_is 'an open pull request' 0 "review L1 $((N + 5))-n-review — " '' "$d"
if [ -z "$got" ]; then
  pass 'next: an approved mission with no pull request is run, and an open one is reviewed'
else
  fail 'next: an approved mission with no pull request is run, and an open one is reviewed' \
    'run L1 <mission> with no pull request, review L1 <mission> with one open' "$got"
fi

# --- R20: a merged lot is skipped, every lot merged is done -------------------------------------
# n-skip has L1 merged (the real answer, copied) and no mission on L2: the walk goes past L1 and
# plans L2. n-done has both lots merged, one beside a closed pull request, and a stray table under
# the last lot's heading, after the queue: a reader that did not end the queue at its table would
# read its rows as lots.
got=""
d="$(campaign n-skip pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 6))-n-skip" n-skip L1 n-skip-b humano-2099-01-01
prs n-skip-b '[{"number":34,"state":"MERGED"}]'
next_is 'L1 merged' 0 'plan L2 - — ' '' "$d"
d="$(campaign n-done pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
printf '\n| Lot | Title | Ceiling | Items |\n|---|---|---|---|\n| L9 | stray | - | 1 |\n' >> "$d/campaign.md"
lot_mission "$REPO" "$((N + 7))-n-done-1" n-done L1 n-done-1-b humano-2099-01-01
lot_mission "$REPO" "$((N + 8))-n-done-2" n-done L2 n-done-2-b humano-2099-01-01
prs n-done-1-b '[{"number":3,"state":"CLOSED"},{"number":35,"state":"MERGED"}]'
prs n-done-2-b '[{"number":36,"state":"MERGED"}]'
next_is 'every lot merged' 0 'done - - — ' '' "$d"
if [ -z "$got" ]; then
  pass 'next: a merged lot is skipped, and a campaign with every lot merged is done'
else
  fail 'next: a merged lot is skipped, and a campaign with every lot merged is done' \
    'plan L2 past a merged L1, done - - when every lot is merged' "$got"
fi

# --- R21: planned ahead -------------------------------------------------------------------------
# Ahead is the lot after the one that decides, and only when it has no mission: a run on L1 with no
# mission on L2; a review on L2 past a merged L1, with L3 and L4 empty (ahead names L3, never L2
# nor L4); a review on L1 whose L2 already has a mission (no ahead); an approve on L1 with L2 empty
# (no ahead: the lot does not run yet); and a run on the last lot (nothing ahead of it).
got=""
d="$(campaign n-ahead-run pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 9))-n-ahead-run" n-ahead-run L1 n-ahead-run-b humano-2099-01-01
next_is 'run, L2 empty' 0 "run L1 $((N + 9))-n-ahead-run — " 'ahead plan L2' "$d"
d="$(campaign n-ahead-rev pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-' 'L3:-' 'L4:-'
lot_mission "$REPO" "$((N + 10))-n-ahead-rev-1" n-ahead-rev L1 n-ahead-rev-1-b humano-2099-01-01
lot_mission "$REPO" "$((N + 11))-n-ahead-rev-2" n-ahead-rev L2 n-ahead-rev-2-b humano-2099-01-01
prs n-ahead-rev-1-b '[{"number":40,"state":"MERGED"}]'
prs n-ahead-rev-2-b '[{"number":41,"state":"OPEN"}]'
next_is 'review on L2, L3 empty' 0 "review L2 $((N + 11))-n-ahead-rev-2 — " 'ahead plan L3' "$d"
d="$(campaign n-ahead-taken pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 12))-n-ahead-taken-1" n-ahead-taken L1 n-ahead-taken-1-b humano-2099-01-01
lot_mission "$REPO" "$((N + 13))-n-ahead-taken-2" n-ahead-taken L2 n-ahead-taken-2-b -
prs n-ahead-taken-1-b '[{"number":42,"state":"OPEN"}]'
next_is 'review, L2 has a mission' 0 "review L1 $((N + 12))-n-ahead-taken-1 — " '' "$d"
d="$(campaign n-ahead-appr pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 14))-n-ahead-appr" n-ahead-appr L1 n-ahead-appr-b -
next_is 'approve, L2 empty' 0 "approve L1 $((N + 14))-n-ahead-appr — " '' "$d"
next_is 'run on the last lot' 0 "run L1 $((N + 4))-n-run — " '' "$REPO/docs/campaigns/n-run"
if [ -z "$got" ]; then
  pass 'next: while a lot runs, the next lot with no mission is planned ahead'
else
  fail 'next: while a lot runs, the next lot with no mission is planned ahead' \
    'ahead plan <the lot after the deciding one>, only under run or review and only when it is empty' "$got"
fi

# --- R22: gh that does not answer, and what stops -----------------------------------------------
# Six answers gh may give that are not read, each on L2 past a merged L1, so the verb has already
# printed nothing when gh fails: a failure, an empty answer with rc 0, text, an object, an object
# whose values are well-formed pull requests (read as a list it is a merged lot), and a state off
# the three. Each is rc 3 with nothing on stdout and gh named on stderr — read as "no pull request"
# they would answer run. Then what stops (rc 1): a pull request closed without merge, two missions
# declaring one lot, an approved mission with no branch (gh asked about an empty head lists every
# pull request of the repo), a directory with no campaign.md, a campaign.md whose campaign: is
# empty, a campaign copied outside any git checkout, an empty queue — each of the last four over a
# queue whose L1 a reader that went on would plan; and a call of the wrong shape is rc 2.
got=""
for w in 'fail|' 'empty|' 'text|not json' 'object|{"message":"Not Found"}' \
         'keyed|{"51":{"number":51,"state":"MERGED"}}' 'state|[{"number":4,"state":"DRAFT"}]'; do
  IFS='|' read -r k raw <<< "$w"
  id="n-gh-$k"
  d="$(campaign "$id" pr "$FAR" 25 200)"
  set_lots "$d/campaign.md" 'L1:-' 'L2:-'
  lot_mission "$REPO" "$((N + 15))-$id-1" "$id" L1 "$id-1-b" humano-2099-01-01
  lot_mission "$REPO" "$((N + 16))-$id-2" "$id" L2 "$id-2-b" humano-2099-01-01
  prs "$id-1-b" '[{"number":50,"state":"MERGED"}]'
  if [ "$k" = fail ]; then : > "$BOX/prs/$id-2-b.fail"; else printf '%s' "$raw" > "$BOX/prs/$id-2-b.raw"; fi
  PATH="$BOX/stub:$PATH" worker next "$d"
  [ "$W_RC" = 3 ] && [ -z "$W_OUT" ] && grep -q "gh pr list --head $id-2-b" <<< "$W_ERR" \
    || got="${got:+$got; }$id: rc $W_RC, stdout '${W_OUT//$'\n'/ / }', stderr '${W_ERR%%$'\n'*}'"
done
d="$(campaign n-closed pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-' 'L2:-'
lot_mission "$REPO" "$((N + 17))-n-closed" n-closed L1 n-closed-b humano-2099-01-01
prs n-closed-b '[{"number":9,"state":"CLOSED"}]'
next_is 'closed without merge' 1 "stop L1 $((N + 17))-n-closed — pull request closed without merge" '' "$d"
d="$(campaign n-two pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$REPO" "$((N + 18))-n-two-a" n-two L1 n-two-a-b humano-2099-01-01
lot_mission "$REPO" "$((N + 19))-n-two-b" n-two L1 n-two-b-b humano-2099-01-01
next_is 'two missions on one lot' 1 'stop L1 - — ' '' "$d"
d="$(campaign n-nobranch pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
lot_mission "$REPO" "$((N + 20))-n-nobranch" n-nobranch L1 '' humano-2099-01-01
next_is 'no branch' 1 "stop L1 $((N + 20))-n-nobranch — " '' "$d"
mkdir -p "$REPO/docs/campaigns/n-nofile"
next_is 'no campaign.md' 1 'stop - - — ' '' "$REPO/docs/campaigns/n-nofile"
d="$(campaign n-noid pr "$FAR" 25 200)"
set_lots "$d/campaign.md" 'L1:-'
sed -i '2,/^---$/ s@^campaign: .*@campaign:@' "$d/campaign.md"
next_is 'empty campaign:' 1 'stop - - — ' '' "$d"
cp -a "$REPO/docs/campaigns/n-plan" "$BOX/loose/"
next_is 'outside a checkout' 1 'stop - - — ' '' "$BOX/loose/n-plan"
d="$(campaign n-noqueue pr "$FAR" 25 200)"
set_lots "$d/campaign.md"
next_is 'empty queue' 1 'stop - - — ' '' "$d"
for a in '' "$REPO/docs/campaigns/n-absent" "$REPO/docs/campaigns/n-run extra"; do
  read -ra args <<< "$a"
  PATH="$BOX/stub:$PATH" worker next ${args[@]+"${args[@]}"}
  [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" \
    || got="${got:+$got; }next '$a': rc $W_RC, stdout '${W_OUT%%$'\n'*}'"
done
if [ -z "$got" ]; then
  pass 'next: a gh that does not answer leaves rc 3, and a pull request closed without merge stops'
else
  fail 'next: a gh that does not answer leaves rc 3, and a pull request closed without merge stops' \
    'rc 3 and no act for each unread answer; stop with rc 1 for each world that stops' "$got"
fi

# --- pr-ready: the fixtures ---------------------------------------------------------------------
# One repo for every world, its history the shape pr-ready reads: Z0 holds the code (src/app.txt,
# src/old.txt) and the mission's 00-missao.md; Z1 changes src/app.txt; A moves src/old.txt into the
# mission folder; B commits two rounds, both naming A as the reviewed head, and a file whose name
# git quotes by default (λ.txt). B is the pull request's head, so A..B touches the mission folder
# alone, Z1..B carries the move and Z0..B the code. The
# review worlds edit the rounds on disk, where the verb reads them, and ready_reset puts the repo
# back; every gh world serves its own copy of the answers.
PRN=412
RR="$BOX/ready"
MD="$RR/$H/20990300-ready"
CODEX='chatgpt-codex-connector[bot]'
got=""
gitc() { git -C "$RR" -c user.name=fixture -c user.email=fixture@example.com "$@"; }

# round <file> <reviewed head> — a review round copied from templates/review.md: every grade of the
# `### Overall Grade` table filled with A (the bold of the Overall row kept), and `reviewed_head:`
# added under the frontmatter's gate: line — none when the head is `-`.
round() {
  sed -e "2,/^---\$/ s@^gate: .*@&\nreviewed_head: $2@" -e 's@| <A> |@| A |@' \
      -e 's@| \*\*<A>\*\* |@| **A** |@' "$ROOT/templates/review.md" > "$1"
  [ "$2" != - ] || sed -i '2,/^---$/ { /^reviewed_head:/d }' "$1"
}

mkdir -p "$RR/src"
git init -q -b main "$RR"
printf 'one\n' > "$RR/src/app.txt"; printf 'old\n' > "$RR/src/old.txt"
lot_mission "$RR" 20990300-ready r-camp L1 ready-b humano-2099-01-01
gitc add -A; gitc commit -q -m z0; Z0="$(git -C "$RR" rev-parse HEAD)"
printf 'two\n' > "$RR/src/app.txt"; gitc commit -q -am z1; Z1="$(git -C "$RR" rev-parse HEAD)"
gitc mv src/old.txt "$H/20990300-ready/old.txt"; gitc commit -q -m a; A="$(git -C "$RR" rev-parse HEAD)"
round "$MD/40-review-r1.md" "$A"; round "$MD/40-review-r2.md" "$A"; printf 'n\n' > "$MD/λ.txt"
gitc add -A; gitc commit -q -m b; B="$(git -C "$RR" rev-parse HEAD)"
RR_REAL="$(CDPATH='' cd "$RR" && pwd -P)"
# The fixture is the world it claims: four distinct commits, and a round whose grades are A.
[ "$(printf '%s\n' "$Z0" "$Z1" "$A" "$B" | sort -u | grep -c '^[0-9a-f]\{40\}$')" = 4 ] \
  || got="fixture: the four commits of the ready repo were not made"
[ "$(grep -c '^| [A-Za-z*][^|]* | \**A\** |' "$MD/40-review-r2.md")" = 8 ] \
  || got="${got:+$got; }fixture: the round copied from templates/review.md does not grade eight rows A"

# ready_reset — the ready repo at B, its two rounds as committed and nothing else on disk.
ready_reset() { rm -f "$MD"/40-review-r*.md "$RR"/40-review-r*.md "$MD/note.md"; gitc reset -q --hard "$B"; }

# The receipt is the real one: the body of the comment the Codex bot left on PR 409 of this repo,
# saved on 2026-11-17 by
#   gh api repos/j0ruge/sdd_agents/issues/409/comments --jq '[.[] | select(.user.login ==
#     "chatgpt-codex-connector[bot]" and (.body | contains("codex-review-state:v1")))] | last | .body'
# into tests/fixtures/codex-review-state.txt; a world swaps its sha (and the short one in the table)
# for the one it names, and may edit it further with a sed script.
RECEIPT="$ROOT/tests/fixtures/codex-review-state.txt"
REAL_SHA=a0bf8e9d8f09a88c8997bbf8356fca7a1d5ed6cd
grep -q "\"code_review\":{\"commit_sha\":\"$REAL_SHA\"" "$RECEIPT" \
  || got="${got:+$got; }fixture: $RECEIPT carries no code_review receipt for $REAL_SHA"
# comment <login> <sha> <sed> — one issue comment as gh api prints it, trimmed to user.login and body,
# carrying the receipt for <sha> edited by <sed> (empty for none).
comment() {
  jq -cn --arg l "$1" --arg b "$(sed -e "s/$REAL_SHA/$2/g" -e "s/\`${REAL_SHA:0:7}\`/\`${2:0:7}\`/" \
    -e "$3" "$RECEIPT")" '{user: {login: $l}, body: $b}'
}

# serve <world> — the gh answers of pull request #PRN for <world>, every item true: open and
# mergeable, with B as the head; the comments in two pages, written one array after the other as
# `gh api --paginate` prints them, the first page carrying an older receipt of the bot (for Z1) and a
# person's comment, the second the receipt for B; two threads, both resolved, in the shape
# `gh api graphql` printed for PR 315 of this repo on 2026-11-17. The answers live in $BOX/ghfx/<world>.
serve() {
  local fx="$BOX/ghfx/$1"
  rm -rf "$fx"; mkdir -p "$fx"
  printf '%s\n' "$RR_REAL" > "$fx/root"
  printf '%s\n' "$PRN" > "$fx/number"
  printf 'j0ruge/fixture\n' > "$fx/repo"
  printf '{"headRefOid":"%s","mergeable":"MERGEABLE","state":"OPEN"}\n' "$B" > "$fx/view"
  printf '[%s,%s]' "$(comment "$CODEX" "$Z1" '')" '{"user":{"login":"j0ruge"},"body":"thanks"}' \
    > "$fx/comments.1"
  printf '[%s]' "$(comment "$CODEX" "$B" '')" > "$fx/comments.2"
  printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":2,"nodes":[{"isResolved":true},{"isResolved":true}]}}}}}' \
    > "$fx/threads"
}

# The gh stub of pr-ready answers the four questions the verb asks, from the world GHFX names, and
# only from the root of the ready repo: `pr view <n> --json headRefOid,mergeable,state`, `repo view
# --json nameWithOwner -q .nameWithOwner`, the comments (both pages under --paginate, the first page
# alone without it, as the real gh does) and the graphql query of the review threads, which has to
# name the owner, the repo and the pull request. A <answer>.fail in the world makes that answer fail,
# and a <answer>.partial makes it fail after printing the answer, as a gh that dies on a later page.
mkdir -p "$BOX/stub-ready"
cat > "$BOX/stub-ready/gh" <<'STUB'
#!/usr/bin/env bash
fx="${GHFX:?gh stub: GHFX names no world}"
[ "$(pwd -P)" = "$(cat "$fx/root")" ] || { echo "gh stub: run from $(pwd -P), not the repo root" >&2; exit 9; }
n="$(cat "$fx/number")"; repo="$(cat "$fx/repo")"
give() {
  local a="$1"; shift
  [ ! -e "$fx/$a.fail" ] || { echo "HTTP 502: Bad Gateway" >&2; exit 1; }
  cat "$@"
  [ ! -e "$fx/$a.partial" ] || { echo "HTTP 502: Bad Gateway" >&2; exit 1; }
  exit 0
}
case "$*" in
  "pr view $n --json headRefOid,mergeable,state") give view "$fx/view" ;;
  "repo view --json nameWithOwner -q .nameWithOwner") give repo "$fx/repo" ;;
  "api --paginate repos/$repo/issues/$n/comments") give comments "$fx/comments.1" "$fx/comments.2" ;;
  "api repos/$repo/issues/$n/comments") give comments "$fx/comments.1" ;;
  "api graphql -f query="*"owner:\"${repo%%/*}\",name:\"${repo#*/}\""*"pullRequest(number:$n)"*) give threads "$fx/threads" ;;
esac
echo "gh stub: unexpected call: $*" >&2
exit 9
STUB
chmod +x "$BOX/stub-ready/gh"

# ready_is <label> <rc> <want> <world> [<mission dir>] — runs pr-ready over the mission folder (the
# ready repo's when none is given) and pull request #PRN, with the stub first on the PATH serving
# <world>; appends to got unless it left <rc> and exactly one line on stdout that starts with <want>
# (a literal, never a pattern).
ready_is() {
  export GHFX="$BOX/ghfx/$4"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "${5:-$MD}" "$PRN"
  [ "$W_RC" = "$2" ] && [[ "$W_OUT" != *$'\n'* ]] && [[ "$W_OUT" == "$3"* ]] \
    || got="${got:+$got; }$1: rc $W_RC, '${W_OUT//$'\n'/ / }' (want rc $2, '$3…'; stderr '${W_ERR%%$'\n'*}')"
}

# --- R23: all five true at one sha --------------------------------------------------------------
# The good world; the same world with its rounds renamed r9 and r10 and the r9 graded B (the newest
# is r10 by number, and a glob, which sorts r10 first, would read the B); and a round naming the head
# itself, on disk, where nothing changed after the reviewed head.
serve good
ready_is 'all five true' 0 "ready $B" good
[ "$W_OUT" = "ready $B" ] || got="${got:+$got; }the line is '$W_OUT', not 'ready $B'"
mv "$MD/40-review-r2.md" "$MD/40-review-r10.md"; mv "$MD/40-review-r1.md" "$MD/40-review-r9.md"
sed -i 's@^| Security | A |@| Security | B |@' "$MD/40-review-r9.md"
grep -q '^| Security | B |' "$MD/40-review-r9.md" || got="${got:+$got; }fixture: r9 was not graded B"
ready_is 'r10 after an r9 graded B' 0 "ready $B" good
ready_reset
round "$MD/40-review-r2.md" "$B"
ready_is 'a round naming the head itself' 0 "ready $B" good
ready_reset
if [ -z "$got" ]; then
  pass 'pr-ready: all five true at one sha answers ready with the full sha'
else
  fail 'pr-ready: all five true at one sha answers ready with the full sha' "ready $B, rc 0" "$got"
fi

# --- R24: the review item -----------------------------------------------------------------------
# Each world breaks the newest round (r2) and leaves r1 — graded A, naming A — as it is, so a reader
# of any round but the newest answers ready. Every other item is true in the good world.
got=""
sed -i 's@^| Security | A |@| Security | B |@' "$MD/40-review-r2.md"
grep -q '^| Security | B |' "$MD/40-review-r2.md" || got="fixture: r2 was not graded B"
ready_is 'Security B' 1 'not-ready review: ' good; ready_reset
sed -i 's@^| \*\*Overall\*\* | \*\*A\*\* |@| **Overall** | **A-** |@' "$MD/40-review-r2.md"
grep -qF '| **Overall** | **A-** |' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: r2 Overall was not A-"
ready_is 'Overall A-' 1 'not-ready review: ' good; ready_reset
sed -i 's@^| Security | A |@   | Security | B |@' "$MD/40-review-r2.md"
grep -q '^   | Security | B |' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: r2 has no indented B"
ready_is 'an indented row graded B' 1 'not-ready review: ' good; ready_reset
round "$MD/40-review-r2.md" -
ready_is 'no reviewed head' 1 'not-ready review: the newest round names no head' good; ready_reset
round "$MD/40-review-r2.md" HEAD
ready_is 'HEAD as the reviewed head' 1 'not-ready review: ' good; ready_reset
round "$MD/40-review-r2.md" deadbeefdead
ready_is 'a sha that is no commit' 1 "not-ready review: the reviewed head 'deadbeefdead'" good; ready_reset
round "$MD/40-review-r2.md" "$Z0"
ready_is 'code after the reviewed head' 1 'not-ready review: src/app.txt ' good; ready_reset
round "$MD/40-review-r2.md" "$Z1"
ready_is 'a move into the mission folder' 1 'not-ready review: src/old.txt ' good; ready_reset
rm -f "$MD"/40-review-r*.md
ready_is 'no round' 1 'not-ready review: ' good; ready_reset
sed -i 's@^### Overall Grade@### Grades@' "$MD/40-review-r2.md"
grep -q '^### Grades' "$MD/40-review-r2.md" || got="${got:+$got; }fixture: r2 kept its grade heading"
ready_is 'no grade table' 1 'not-ready review: ' good; ready_reset
# The head the pull request names is not in this checkout, receipt and all: only the review item
# can say so, since the diff it reads does not run.
UNFETCHED=0000000000000000000000000000000000000007
serve r-unfetched
printf '{"headRefOid":"%s","mergeable":"MERGEABLE","state":"OPEN"}\n' "$UNFETCHED" > "$BOX/ghfx/r-unfetched/view"
printf '[%s]' "$(comment "$CODEX" "$UNFETCHED" '')" > "$BOX/ghfx/r-unfetched/comments.2"
ready_is 'a head not fetched' 1 'not-ready review: git diff ' r-unfetched
# The mission folder given as the root of the checkout: every path is under it.
round "$RR/40-review-r2.md" "$A"
ready_is 'the root as the mission folder' 1 'not-ready review: the mission folder ' good "$RR"; ready_reset
mkdir -p "$BOX/loose-ready"; cp -a "$MD" "$BOX/loose-ready/"
ready_is 'outside a checkout' 1 'not-ready review: ' good "$BOX/loose-ready/20990300-ready"
if [ -z "$got" ]; then
  pass 'pr-ready: a grade below A, a round that names no head, and code after the reviewed head each fail review'
else
  fail 'pr-ready: a grade below A, a round that names no head, and code after the reviewed head each fail review' \
    'rc 1 and not-ready review: … for each world' "$got"
fi

# --- R25: the codex item ------------------------------------------------------------------------
# Each world edits the second page of the good one; the witness is that the page changed. With no
# receipt at all, both pages carry only a person's comment. The spoof is a receipt for the head that
# a person posted after the bot's newest, which is for Z1. A null for the unresolved findings is not
# a false, and a newest receipt whose state does not parse says nothing, so the good receipt before
# it is never the one read.
got=""
for w in "c-sha|$CODEX|$A|" "c-unfinished|$CODEX|$B|s/\"status\":\"completed\"/\"status\":null/" \
         "c-finding|$CODEX|$B|s/\"has_unresolved_findings\":false/\"has_unresolved_findings\":true/" \
         "c-finding-null|$CODEX|$B|s/\"has_unresolved_findings\":false/\"has_unresolved_findings\":null/" \
         "c-spoof|j0ruge|$B|" "c-unreadable|$CODEX|$B|s/\"has_any_findings\":false,/\"has_any_findings\":,/"; do
  IFS='|' read -r fx who sha ed <<< "$w"
  serve "$fx"
  printf '[%s]' "$(comment "$who" "$sha" "$ed")" > "$BOX/ghfx/$fx/comments.2"
  cmp -s "$BOX/ghfx/good/comments.2" "$BOX/ghfx/$fx/comments.2" && got="${got:+$got; }fixture: $fx is the good page"
  # Unreadable: the page before carries a good receipt for the head, which only a skip would read.
  [ "$fx" != c-unreadable ] || printf '[%s]' "$(comment "$CODEX" "$B" '')" > "$BOX/ghfx/$fx/comments.1"
  ready_is "$fx" 1 'not-ready codex: ' "$fx"
done
serve c-none
printf '[%s]' '{"user":{"login":"j0ruge"},"body":"thanks"}' > "$BOX/ghfx/c-none/comments.1"
printf '[]' > "$BOX/ghfx/c-none/comments.2"
ready_is 'no receipt' 1 'not-ready codex: ' c-none
if [ -z "$got" ]; then
  pass 'pr-ready: a receipt for another sha, an unfinished one and an unresolved finding each fail codex'
else
  fail 'pr-ready: a receipt for another sha, an unfinished one and an unresolved finding each fail codex' \
    'rc 1 and not-ready codex: … for each world' "$got"
fi

# --- R26: the threads item ----------------------------------------------------------------------
got=""
serve t-open
printf '%s\n' '{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":2,"nodes":[{"isResolved":true},{"isResolved":false}]}}}}}' \
  > "$BOX/ghfx/t-open/threads"
ready_is 'one open thread' 1 'not-ready threads: ' t-open
serve t-unseen
jq -cn '{data: {repository: {pullRequest: {reviewThreads: {totalCount: 101, nodes: [range(100) | {isResolved: true}]}}}}}' \
  > "$BOX/ghfx/t-unseen/threads"
ready_is 'a thread past the hundred read' 1 'not-ready threads: ' t-unseen
if [ -z "$got" ]; then
  pass 'pr-ready: one open thread fails threads'
else
  fail 'pr-ready: one open thread fails threads' 'rc 1 and not-ready threads: … for each world' "$got"
fi

# --- R27: the mergeable item --------------------------------------------------------------------
got=""
for w in 'm-conflict|CONFLICTING|OPEN' 'm-closed|MERGEABLE|CLOSED' 'm-merged|UNKNOWN|MERGED'; do
  IFS='|' read -r fx mg st <<< "$w"
  serve "$fx"
  printf '{"headRefOid":"%s","mergeable":"%s","state":"%s"}\n' "$B" "$mg" "$st" > "$BOX/ghfx/$fx/view"
  ready_is "$fx" 1 'not-ready mergeable: ' "$fx"
done
if [ -z "$got" ]; then
  pass 'pr-ready: a conflicting or closed pull request fails mergeable'
else
  fail 'pr-ready: a conflicting or closed pull request fails mergeable' \
    'rc 1 and not-ready mergeable: … for each world' "$got"
fi

# --- R28: the head item -------------------------------------------------------------------------
# Ahead: a local commit on top of B. Behind: the checkout at A with the two rounds on disk, so the
# review item still reads them.
got=""
serve h-local
printf 'note\n' > "$MD/note.md"; gitc add -A; gitc commit -q -m c
ready_is 'local HEAD ahead' 1 'not-ready head: ' h-local; ready_reset
gitc reset -q --hard "$A"; round "$MD/40-review-r1.md" "$A"; round "$MD/40-review-r2.md" "$A"
ready_is 'local HEAD behind' 1 'not-ready head: ' h-local; ready_reset
[ "$(git -C "$RR" rev-parse HEAD)" = "$B" ] || got="${got:+$got; }fixture: the ready repo did not go back to B"
if [ -z "$got" ]; then
  pass 'pr-ready: a local HEAD that is not the pull request head fails head'
else
  fail 'pr-ready: a local HEAD that is not the pull request head fails head' \
    'rc 1 and not-ready head: … for each world' "$got"
fi

# --- R29: a gh that does not answer, and the wrong shape ----------------------------------------
# Each world breaks one answer of the good one, so only that answer stands between it and ready:
# a failure, a failure after a full answer was printed (a gh that dies on a later page), or an answer
# off the contract — text, a short sha, a name with no owner, an object for the pages (one keyed by
# comments whose receipt is good, read as a list it is ready), nothing at all, a graphql error, and
# threads with no count, keyed instead of listed, or of unknown resolution. Each is rc 3, nothing on
# stdout, the call named on stderr. Then the calls of the wrong shape, rc 2 with the usage.
for w in 'g-view-fail|view|FAIL|gh pr view' 'g-view-rc|view|RC|gh pr view' 'g-view-text|view|not json|gh pr view' \
         'g-view-short|view|{"headRefOid":"a0bf8e9","mergeable":"MERGEABLE","state":"OPEN"}|gh pr view' \
         'g-repo-fail|repo|FAIL|gh repo view' 'g-repo-rc|repo|RC|gh repo view' \
         'g-repo-name|repo|fixture|gh repo view' \
         'g-comments-fail|comments|FAIL|gh api --paginate' 'g-comments-rc|comments|RC|gh api --paginate' \
         'g-comments-keyed|comments.1|KEYED|gh api --paginate' \
         'g-comments-object|comments.1|{"message":"Not Found"}|gh api --paginate' \
         'g-comments-empty|comments.1||gh api --paginate' \
         'g-threads-fail|threads|FAIL|gh api graphql' 'g-threads-rc|threads|RC|gh api graphql' \
         'g-threads-error|threads|{"data":null,"errors":[{"message":"Could not resolve"}]}|gh api graphql' \
         'g-threads-nocount|threads|{"data":{"repository":{"pullRequest":{"reviewThreads":{"nodes":[{"isResolved":true}]}}}}}|gh api graphql' \
         'g-threads-keyed|threads|{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":1,"nodes":{"x":{"isResolved":true}}}}}}}|gh api graphql' \
         'g-threads-unknown|threads|{"data":{"repository":{"pullRequest":{"reviewThreads":{"totalCount":1,"nodes":[{"isResolved":null}]}}}}}|gh api graphql'; do
  IFS='|' read -r fx file body what <<< "$w"
  serve "$fx"
  if [ "$body" = FAIL ]; then
    : > "$BOX/ghfx/$fx/$file.fail"
  elif [ "$body" = RC ]; then
    : > "$BOX/ghfx/$fx/$file.partial"
  elif [ "$body" = KEYED ]; then
    printf '{"1":%s}' "$(comment "$CODEX" "$B" '')" > "$BOX/ghfx/$fx/comments.1"
    : > "$BOX/ghfx/$fx/comments.2"
  else
    printf '%s' "$body" > "$BOX/ghfx/$fx/$file"
    [ "$file" != comments.1 ] || : > "$BOX/ghfx/$fx/comments.2"
  fi
  export GHFX="$BOX/ghfx/$fx"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready "$MD" "$PRN"
  [ "$W_RC" = 3 ] && [ -z "$W_OUT" ] && grep -qF "sdd-worker: $what" <<< "$W_ERR" \
    || got="${got:+$got; }$fx: rc $W_RC, stdout '${W_OUT//$'\n'/ / }', stderr '${W_ERR%%$'\n'*}'"
done
export GHFX="$BOX/ghfx/good"
for a in '' "$MD" "$MD|12a" "$MD|#412" "$MD|0" "$RR/nowhere|$PRN" "$MD|$PRN|extra"; do
  IFS='|' read -ra args <<< "$a"
  PATH="$BOX/stub-ready:$PATH" worker pr-ready ${args[@]+"${args[@]}"}
  [ "$W_RC" = 2 ] && [ -z "$W_OUT" ] && grep -q '^usage: sdd-worker ' <<< "$W_ERR" \
    || got="${got:+$got; }pr-ready '$a': rc $W_RC, stdout '${W_OUT%%$'\n'*}'"
done
if [ -z "$got" ]; then
  pass 'pr-ready: a gh that does not answer leaves rc 3 and never ready'
else
  fail 'pr-ready: a gh that does not answer leaves rc 3 and never ready' \
    'rc 3, nothing on stdout and the call on stderr for each unread answer; rc 2 for each wrong shape' "$got"
fi

# --- command: the session's command -------------------------------------------------------------
# commands/sdd-worker.md is prose an interactive session follows, so these probes read the file, one
# phrase per markdown line. Each checker prints what the file misses, one item per line; each
# assertion runs it on the file (nothing missed) and on copies with one thing taken out, built here
# from the file and anchored on its text, where it has to name that thing.
COMMAND="$ROOT/commands/sdd-worker.md"

# command_verbs — the verbs bin/sdd-worker dispatches, one per line, read from the case of its
# main(): the program is the source, so a verb it gains is a verb the command has to name.
command_verbs() { sed -n '/^main() {$/,/^}$/ s/^    \([a-z][a-z-]*\)) shift; cmd_.*/\1/p' "$WORKER"; }

# section <file> <heading> — the lines under `## <heading>`, up to the next `## `.
section() { awk -v h="## $2" '$0 == h { on = 1; next } on && /^## / { exit } on' "$1"; }

# verbs_missing <file> — each verb the file never writes as a call: `sdd-worker <verb>` followed by
# a space, a backtick or the end of the line, so `sdd-worker budgets` is no call of budget.
verbs_missing() {
  local v
  while IFS= read -r v; do
    grep -qE "sdd-worker $v( |\`|\$)" "$1" 2>/dev/null || printf '%s\n' "$v"
  done < <(command_verbs)
}

# acts_unpreceded <file> — each act of ACT_TABLE whose heading `### \`<act>\`` is not in the file
# exactly once, or whose first non-blank line under it is not its allows call, written whole.
acts_unpreceded() {
  local row act n first
  for row in "${ACT_TABLE[@]}"; do
    act="${row%% *}"
    n="$(grep -cxF "### \`$act\`" "$1" 2>/dev/null)"
    first="$(awk -v h="### \`$act\`" '$0 == h { on = 1; next } on && NF { print; exit }' "$1" 2>/dev/null)"
    [ "$n" = 1 ] && [ "$first" = "\`sdd-worker allows <campaign-dir> $act --lot <L>\`" ] \
      || printf '%s\n' "$act"
  done
}

# prose_missing <file> — what three sections do not write. The five stops: exactly five numbered
# lines, each phrase on one of them, the pager and the journal in the section. The never list and
# the context rules: each phrase on a bullet of its own section, the last rule naming both verbs a
# new session resumes from. A phrase found only in another section is missing.
prose_missing() {
  local s items p
  s="$(section "$1" 'The five stops' 2>/dev/null)"
  items="$(grep -E '^[0-9]+\. ' <<< "$s")"
  [ "$(grep -c . <<< "$items")" = 5 ] || printf 'stops: not five numbered lines\n'
  for p in '60 minutes' 'three rounds' 'merge conflict' 'BUDGET_MISSION_USD' 'sdd-worker budget'; do
    grep -qF "$p" <<< "$items" || printf 'stops: %s\n' "$p"
  done
  for p in ON_ESCALATION_CMD journal.md; do grep -qF "$p" <<< "$s" || printf 'stops: %s\n' "$p"; done
  items="$(section "$1" 'Never' 2>/dev/null | grep '^- ')"
  for p in 'Delete a branch or a worktree' 'Push to the base branch' 'visual acceptance' "kit's main checkout"; do
    grep -qF "$p" <<< "$items" || printf 'never: %s\n' "$p"
  done
  items="$(section "$1" 'Context' 2>/dev/null | grep '^- ')"
  for p in 'One line per event' 'returns only its verdict' 'a handoff to a file'; do
    grep -qF "$p" <<< "$items" || printf 'context: %s\n' "$p"
  done
  items="$(grep -F 'sdd-worker level' <<< "$items")"
  grep -qF 'sdd-worker next' <<< "$items" || printf 'context: resumes from level and next\n'
}

# control <label> <checker> <want> <sed script> — runs <checker> on a copy of the command edited by
# <sed script>; appends to got unless the checker printed exactly <want>, one item per line, never
# empty. A sed that stops matching leaves the copy equal to the file, where the checker prints
# nothing: that is not <want>, so the control goes red instead of passing on a copy it never edited.
control() {
  local label="$1" checker="$2" want="$3" out
  sed "$4" "$COMMAND" > "$BOX/command-copy" 2>/dev/null
  out="$("$checker" "$BOX/command-copy")"
  [ "$out" = "$want" ] || got="${got:+$got; }$label: printed '${out//$'\n'/, }' (want '${want//$'\n'/, }')"
}

# --- R30: every verb is named -------------------------------------------------------------------
# The floor of six is the probe of the parse: a main() whose case changes shape (an arm split over
# two lines) hides that verb from command_verbs, and a verb the parse misses is one nobody checks —
# measured, level split that way left the controls green and only this floor red.
got=""
verbs="$(command_verbs)"
[ "$(grep -c . <<< "$verbs")" -ge 6 ] || got="the program dispatches '${verbs//$'\n'/ }', not the six verbs"
m="$(verbs_missing "$COMMAND")"
[ -z "$m" ] || got="${got:+$got; }not named: ${m//$'\n'/ }"
control 'no budget call' verbs_missing budget 's/sdd-worker budget/sdd-worker budgets/g'
control 'no pr-ready call' verbs_missing pr-ready 's/sdd-worker pr-ready/sdd-worker pr_ready/g'
# The primitive under every control, against an answer known wrong: told to want level from a copy
# whose checker prints budget, control() has to append, or each control above passes on anything.
saved="$got"
control 'the primitive' verbs_missing level 's/sdd-worker budget/sdd-worker budgets/g'
[ "$got" != "$saved" ] || saved="${saved:+$saved; }control() let a copy printing budget pass as level"
got="$saved"
if [ -z "$got" ]; then
  pass 'command: it names every verb of bin/sdd-worker'
else
  fail 'command: it names every verb of bin/sdd-worker' \
    'a call of each verb of main(), and each copy with one call taken out naming that verb' "$got"
fi

# --- R31: each act starts with its allows call --------------------------------------------------
# The seven are ACT_TABLE's, whose size R11 already witnesses by counting its 35 cells.
got=""
m="$(acts_unpreceded "$COMMAND")"
[ -z "$m" ] || got="not preceded: ${m//$'\n'/ }"
control 'review call deleted' acts_unpreceded review '/^`sdd-worker allows <campaign-dir> review --lot <L>`$/d'
control 'run call names plan' acts_unpreceded run 's/^`sdd-worker allows <campaign-dir> run --lot/`sdd-worker allows <campaign-dir> plan --lot/'
control 'plan call after prose' acts_unpreceded plan 's/^\(`sdd-worker allows <campaign-dir> plan --lot <L>`\)$/Plan first.\n\n\1/'
control 'approve call partial' acts_unpreceded approve 's/^`sdd-worker allows <campaign-dir> approve --lot <L>`$/`sdd-worker allows <campaign-dir> approve`/'
control 'merge heading twice' acts_unpreceded merge '$a\
\
### `merge`\
\
Merge by hand.'
if [ -z "$got" ]; then
  pass 'command: each of the seven acts is preceded by its allows call'
else
  fail 'command: each of the seven acts is preceded by its allows call' \
    'one heading per act whose first line is its allows call, and each sabotaged copy naming its act' "$got"
fi

# --- R32: the stops, the never list, the context rules ------------------------------------------
got=""
m="$(prose_missing "$COMMAND")"
[ -z "$m" ] || got="missing: ${m//$'\n'/, }"
control 'stop 1 deleted' prose_missing $'stops: not five numbered lines\nstops: 60 minutes' '/60 minutes/d'
control 'a sixth stop' prose_missing 'stops: not five numbered lines' '/^5\. /a\
6. **Another.** One more stop.'
control 'stop 4 not numbered' prose_missing $'stops: not five numbered lines\nstops: BUDGET_MISSION_USD' 's/^4\. \(.*BUDGET_MISSION_USD\)/\1/'
control 'no pager' prose_missing $'stops: ON_ESCALATION_CMD\nstops: journal.md' '/ON_ESCALATION_CMD/d'
control 'never: main checkout' prose_missing "never: kit's main checkout" "/^- Move the kit's main checkout/d"
control 'never: not a bullet' prose_missing 'never: visual acceptance' 's/^- \(Give the visual acceptance\)/\1/'
control 'context: handoff' prose_missing 'context: a handoff to a file' '/^- .*a handoff to a file/d'
control 'context: not a bullet' prose_missing 'context: One line per event' 's/^- \(One line per event\)/\1/'
control 'context: no next' prose_missing 'context: resumes from level and next' 's/^\(- A new session resumes from `sdd-worker level`\) and `sdd-worker next`/\1/'
control 'context: no level' prose_missing 'context: resumes from level and next' 's/^\(- A new session resumes from\) `sdd-worker level` and/\1/'
if [ -z "$got" ]; then
  pass 'command: the five stops, the never list and the context rules are written'
else
  fail 'command: the five stops, the never list and the context rules are written' \
    'every phrase on a line of its section, and each sabotaged copy naming what it lost' "$got"
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
