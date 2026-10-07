# shellcheck shell=bash
# tests/isolate-git.sh — SOURCED, never run: clears the git repository a caller hands the suite.
#
# Every sensor builds its fixtures in a temporary repo and trusts `cd` or `git -C` to aim git at
# it — and an inherited GIT_DIR beats both. Inside a LINKED worktree, `git bisect run`,
# `git rebase --exec`, the pre-commit and pre-push hooks and a `!` alias all export an absolute
# GIT_DIR (measured, git 2.43; the main worktree gets only GIT_PREFIX). Under one, the fixtures
# wrote into the kit's own repository: `core.bare = true` and a `[user]` section in its config,
# fixture branches and tags in its refs (issue #226, 2026-10-05, repaired by hand). Measured on
# 89df2e5, each sensor run ALONE with GIT_DIR aimed at a bait repo: 12 of 16 moved it, and
# check-autonomy.sh, whose fixture runs `git init --separate-git-dir`, replaced the bait's whole
# `.git` with a file pointing into a temp dir its trap then deleted.
#
# ONE definition, sourced by tests/run-all.sh and by EVERY tests/check-*.sh as the line right after
# its `set … pipefail`, spelled `. "$(dirname "${BASH_SOURCE[0]}")/isolate-git.sh"` — the one form
# that resolves before a sensor computes its ROOT, whatever cwd it was started from. Every sensor
# and not "every sensor that runs `git init`": that predicate was measured wrong both ways
# (check-coordination.sh moved the bait with no `git init` of its own — bin/sdd ran git for it —
# and check-checkpoint.sh, with three, left it intact). The census is in check-health.sh
# (`surface: every sensor sources tests/isolate-git.sh before its first git`).
#
# The list is git's own, `git rev-parse --local-env-vars` ("the GIT_* environment variables that
# are local to the repository", its manual says; 15 names on git 2.43, GIT_CONFIG_PARAMETERS
# among them, which a `!` alias exports), so a variable git adds tomorrow is cleared without
# editing this file. What is NOT in it stays on purpose: GIT_REFLOG_ACTION (check-autonomy.sh
# exports it to label a session), GIT_CEILING_DIRECTORIES (check-lang.sh and check-checkpoint.sh
# set it for a child of their own, and it only narrows discovery), GIT_AUTHOR_*/GIT_COMMITTER_*
# and GIT_CONFIG_GLOBAL say how to write, never where.
#
# An empty list is REFUSED, never read as "nothing to clear": a git that cannot name GIT_DIR is a
# sensor that would run unprotected while this header said otherwise. `exit`, not `return`: the
# file is sourced, so the refusal ends the sensor that sourced it.
#
# Sourced into every sensor's own shell, so it leaves nothing behind: the work is a function with
# locals, and the function is unset once it ran.
_sdd_isolate_git() {
  local -a _sdd_git_local=()
  mapfile -t _sdd_git_local < <(git rev-parse --local-env-vars 2>/dev/null)
  case " ${_sdd_git_local[*]-} " in
    *" GIT_DIR "*) unset "${_sdd_git_local[@]}" ;;
    *) printf "%s: 'git rev-parse --local-env-vars' named no GIT_DIR — cannot clear the repository a git-driven caller hands it\n" \
         "${0##*/}" >&2
       exit 1 ;;
  esac
}
_sdd_isolate_git
unset -f _sdd_isolate_git
