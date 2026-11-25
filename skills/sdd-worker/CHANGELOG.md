# Changelog

## 2026-11-25

- Record the required Codex preflight evidence for missions of the kit. The host
  suite passed while the real preflight failed on sockets, writable paths, and
  Git identity. The corrected fixtures passed the integrated preflight.
- Verify affected mutation controls in the same sandbox. With
  `tests/check-mutation.sh --only LEDGER_tmp_repo_allowed check-autonomy.sh`,
  the control now stays outside `/tmp` and the mutant is caught.
