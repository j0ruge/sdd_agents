# Changelog

## 2026-11-26

- Locate new Codex campaigns and owner signatures in the primary checkout,
  where the paid-session guard reads both files.
- Check the effective pager in the campaign and mission checkouts before
  asking for a signature, because an unsigned delegation hides missing pagers.

## 2026-11-25

- Record the required Codex preflight evidence for missions of the kit. The host
  suite passed while the real preflight failed on sockets, writable paths, and
  Git identity. The corrected fixtures passed the integrated preflight.
- Verify affected mutation controls in the same sandbox. With
  `tests/check-mutation.sh --only LEDGER_tmp_repo_allowed check-autonomy.sh`,
  the control now stays outside `/tmp` and the mutant is caught.
