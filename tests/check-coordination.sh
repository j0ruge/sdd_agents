#!/usr/bin/env bash
# Checkout ownership is measured through real CLI entrypoints and isolated repositories.
# Removing admission, accepting environment-only reentry, or waiting only for the worker must
# fail here. Readiness and release FIFOs establish order; deadlines bound every subprocess.
# The supervisor is not a security boundary against killing it or external daemon writers.
set -euo pipefail
ROOT="$(CDPATH='' cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" "$@" <<'PY'
import contextlib
import fcntl
import io
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time

if sys.argv[2:] not in ([], ["--check-isolation"]):
    raise SystemExit("unknown coordination sensor option")
root = Path(sys.argv[1])
work = Path(tempfile.mkdtemp(prefix="sdd-coordination-"))
sdd = root / "bin/sdd"
passed = 0
failed = 0
owned = []
env = {key: value for key, value in os.environ.items()
       if key not in ("BASH_ENV", "ENV") and not key.startswith("BASH_FUNC_")}
env.update(SDD_STATE_DIR=str(work / "state"), NO_COLOR="1", ON_ESCALATION_CMD="")
# An enclosing health run may own another checkout. Its environment is not authority here.
env.pop("SDD_COORDINATION_ID", None)
stubs = work / "stubs"
stubs.mkdir()
external_commands = ("claude", "gh", "acli", "jira", "curl", "wget", "agent-browser")
for command in external_commands:
    stub = stubs / command
    stub.write_text("#!/usr/bin/env bash\nprintf 'isolated external CLI stub\\n' >&2\nexit 97\n")
    stub.chmod(0o755)
env["PATH"] = str(stubs) + ":/usr/bin:/bin"
env["SDD_ACLI_BIN"] = str(stubs / "acli")


def isolated():
    return all(shutil.which(command, path=env["PATH"]) == str(stubs / command)
               for command in external_commands)


# This guard runs before ANY sdd invocation, including the fixture's initial install.
# Its negative control removes a stub without executing the resulting real command.
if not isolated():
    raise RuntimeError("SENSOR-BROKEN: external CLI resolution escaped the fixture")
for command in external_commands:
    stub = stubs / command
    hidden = stubs / (command + ".hidden")
    stub.rename(hidden)
    if isolated():
        raise RuntimeError("SENSOR-BROKEN: missing external stub was accepted")
    hidden.rename(stub)
    result = subprocess.run([command], env=env, text=True, capture_output=True, timeout=2)
    if result.returncode != 97 or result.stderr != "isolated external CLI stub\n":
        raise RuntimeError("SENSOR-BROKEN: external stub behavior changed")
print("  ok    external CLI isolation and missing-stub controls", flush=True)
if sys.argv[2:] == ["--check-isolation"]:
    shutil.rmtree(work)
    sys.exit(0)


def check(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print("  ok    " + name, flush=True)
    else:
        failed += 1
        print("  FAIL  " + name + ": " + detail, flush=True)


def run(repo, *args, extra=None, binary=sdd):
    call_env = dict(env, **(extra or {}))
    return subprocess.run([str(binary), *args], cwd=repo, env=call_env,
                          text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          timeout=8)


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()


def fixture(name):
    repo = work / name
    repo.mkdir()
    git(repo, "init", "-q", "-b", "main")
    git(repo, "config", "user.name", "Fixture")
    git(repo, "config", "user.email", "fixture@example.com")
    (repo / "file").write_text("initial\n")
    git(repo, "add", ".")
    git(repo, "commit", "-qm", "initial")
    installed = run(repo, "install")
    if installed.returncode:
        raise RuntimeError("fixture install: " + installed.stdout)
    (repo / ".sdd/config.sh").write_text('''PROJECT_NAME="fixture"
DEFAULT_BRANCH="main"
TEST_CMD="true"
JIRA_ENABLED=false
ADR_CHECK=off
ON_ESCALATION_CMD="${COORD_HOOK:-}"
if [ -n "${COORD_PROBE:-}" ]; then printf touched >> "$COORD_PROBE"; fi
if [ -n "${COORD_FDCOUNT:-}" ]; then ls /proc/$$/fd | wc -l > "$COORD_FDCOUNT"; fi
if [ -n "${COORD_HOLD:-}" ]; then
  if [ "${COORD_CHILD:-}" = cooperative ]; then
    exec 3<> "$COORD_RELEASE"
    trap 'trap "" INT; printf handled > "$COORD_READY.handled"; read -r -n 1 -u 3; printf cleaned > "$COORD_FINISHED"; exit 42' INT
    env COORD_WORKER="$$" python3 "$COORD_BARRIER"
    read -r -n 1 -u 3
    exit 43
  fi
  COORD_WORKER="$$" python3 "$COORD_BARRIER"
  exit "${COORD_EXIT:-0}"
fi
''')
    for mission in ("20260101-one", "20260101-two"):
        path = repo / "docs/handoffs" / mission
        path.mkdir(parents=True)
        (path / "00-missao.md").write_text("---\naprovacao: fixture\nadr: none\n---\n")
    return repo


barrier = work / "barrier.py"
barrier.write_text('''import json, os, signal, subprocess, sys, threading
from pathlib import Path
mode = os.environ.get("COORD_CHILD", "ordinary")
if mode == "foreground-threaded":
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    def threaded_child():
        child_env = dict(os.environ, COORD_CHILD="foreground-escaped")
        os._exit(subprocess.call([sys.executable, __file__], env=child_env))
    thread = threading.Thread(target=threaded_child)
    thread.start()
    thread.join()
if mode == "foreground-escaped":
    os.setsid()
if mode == "escaped":
    if os.fork(): os._exit(0)
    os.setsid()
    if os.fork(): os._exit(0)
os.closerange(3, 1048576)
if mode == "reentry":
    child_env = dict(os.environ)
    child_env.pop("COORD_HOLD", None)
    commands = [["install", "--force"], ["adr", "new", "--slug", "nested"],
                ["run", "20260101-one"], ["retry", "20260101-one"], ["close", "20260101-one"], ["kaizen"]]
    results = []
    gitdir = subprocess.check_output(["git", "rev-parse", "--absolute-git-dir"], text=True).strip()
    meta_path = Path(gitdir) / "sdd-coordination.json"
    before = meta_path.read_bytes()
    for args in commands:
        result = subprocess.run([os.environ["COORD_SDD"], *args], env=child_env,
                                text=True, capture_output=True, timeout=8)
        results.append([args, result.returncode, result.stdout + result.stderr])
    results.append([["metadata"], 0 if meta_path.read_bytes() == before else 1, ""])
    for field in ("owner", "worker", "supervisor"):
        forged = json.loads(before)
        forged[field]["start"] = "0"
        meta_path.write_text(json.dumps(forged))
        result = subprocess.run([os.environ["COORD_SDD"], "install"], env=child_env,
                                text=True, capture_output=True, timeout=8)
        results.append([["stale-" + field], result.returncode, result.stdout + result.stderr])
        meta_path.write_bytes(before)
    Path(os.environ["COORD_RESULTS"]).write_text(json.dumps(results))
if mode in ("foreground", "foreground-escaped"):
    def stop(number, frame):
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        Path(os.environ["COORD_READY"] + ".handled").write_text("handled")
        with open(os.environ["COORD_RELEASE"], "rb", buffering=0) as stream: stream.read(1)
        Path(os.environ["COORD_FINISHED"]).write_text("cleaned")
        raise SystemExit(42)
    signal.signal(signal.SIGINT, stop)
ready = Path(os.environ["COORD_READY"])
pid = int(os.environ["COORD_WORKER"]) if mode == "cooperative" else os.getpid()
stamp = Path('/proc/%d/stat' % pid).read_text().rsplit(')', 1)[1].split()[19]
ready.with_suffix('.tmp').write_text(json.dumps({"pid": pid, "start": stamp, "ppid": os.getppid(), "worker": int(os.environ["COORD_WORKER"])}))
ready.with_suffix('.tmp').replace(ready)
if mode == "cooperative": os._exit(0)
with open(os.environ["COORD_RELEASE"], "rb", buffering=0) as stream:
    stream.read(1)
Path(os.environ["COORD_FINISHED"]).write_text("child wrote after release")
''')


def start(repo, mode="ordinary", code=0, args=("run", "20260101-one"), binary=sdd):
    serial = len(owned)
    ready = work / ("ready-" + str(serial))
    release = work / ("release-" + str(serial))
    os.mkfifo(release)
    log = open(work / ("owner-" + str(serial) + ".log"), "w+")
    proc = subprocess.Popen([str(binary), *args], cwd=repo,
                            env=dict(env, COORD_HOLD="1", COORD_BARRIER=str(barrier),
                                     COORD_READY=str(ready), COORD_RELEASE=str(release),
                                     COORD_CHILD=mode, COORD_EXIT=str(code), COORD_SDD=str(binary),
                                     COORD_RESULTS=str(work / "nested-results"),
                                     COORD_FINISHED=str(ready) + ".finished"),
                            stdout=log, stderr=subprocess.STDOUT)
    item = (proc, ready, release, log)
    owned.append(item)
    deadline = time.monotonic() + 8
    while not ready.exists() and time.monotonic() < deadline:
        if proc.poll() is not None and mode != "escaped":
            log.seek(0)
            raise RuntimeError("owner stopped before readiness: " + log.read())
        time.sleep(.01)
    if not ready.exists():
        raise RuntimeError("owner readiness deadline")
    return item


def release(item):
    proc, ready, fifo, log = item
    try:
        fd = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
        os.write(fd, b"x")
        os.close(fd)
    except OSError:
        pass
    try:
        return proc.wait(timeout=8)
    except subprocess.TimeoutExpired:
        raise RuntimeError("owner did not finish after release")


def snapshot(repo):
    # Operational lock metadata lives in Git's private directory and is intentionally excluded.
    files = [(str(p.relative_to(repo)), p.read_bytes()) for p in repo.rglob("*")
             if p.is_file() and ".git" not in p.relative_to(repo).parts]
    return (git(repo, "symbolic-ref", "HEAD"), git(repo, "ls-files", "--stage"), sorted(files))


def busy(repo, *args, binary=sdd, extra=None, name=None):
    probe = work / "refused-config-effect"
    probe.unlink(missing_ok=True)
    hook = work / "refused-hook-effect"
    hook.unlink(missing_ok=True)
    before = snapshot(repo)
    state_before = sorted((str(p), p.read_bytes()) for p in (work / "state").rglob("*") if p.is_file())
    result = run(repo, *args, binary=binary,
                 extra=dict(extra or {}, COORD_PROBE=str(probe),
                            COORD_HOOK="printf touched >> " + str(hook)))
    check(name or ("busy: " + " ".join(args)),
          result.returncode == 75 and "CHECKOUT-BUSY" in result.stdout,
          "rc=" + str(result.returncode) + " " + result.stdout[:400])
    check("refusal has no effects: " + " ".join(args),
          not probe.exists() and not hook.exists() and snapshot(repo) == before
          and state_before == sorted((str(p), p.read_bytes()) for p in (work / "state").rglob("*") if p.is_file()),
          result.stdout[:200])
    return result


try:
    # A negative control proves the verdict accumulator itself can report a failure.
    with contextlib.redirect_stdout(io.StringIO()):
        check("negative control", False, "intentional")
    if failed != 1:
        raise RuntimeError("SENSOR-BROKEN: assertion accounting")
    failed = 0
    repo = fixture("repo")
    # Missing Python cannot reach config or an external CLI; help remains available.
    limited = work / "limited-path"
    limited.mkdir()
    for command in ("bash", "dirname", "git", "cat"):
        (limited / command).symlink_to(shutil.which(command))
    limited_env = {"PATH": str(stubs) + ":" + str(limited)}
    missing = run(repo, "preflight", extra=limited_env)
    check("missing dependency refuses before execution", missing.returncode != 0
          and "CHECKOUT-UNAVAILABLE" in missing.stdout, missing.stdout)
    check("help needs no supervisor dependency", run(repo, "help", extra=limited_env).returncode == 0)
    # pidfd support must be usable under this kernel/seccomp policy before project config runs.
    python_stub = stubs / "python3"
    capability_effect = work / "pidfd-config-effect"
    # `children`: a procfs without task children enumeration (no CONFIG_PROC_CHILDREN) makes every
    # task read as childless, so an interrupt would reach nobody and keep the lock (Codex, PR #48).
    for denied in ("missing", "open", "send", "children"):
        python_stub.write_text("#!/usr/bin/python3\nimport os, signal, runpy, sys\n"
            "def denied(*args, **kwargs): raise PermissionError('fixture pidfd denied')\n"
            + {"missing": "del os.pidfd_open\n", "open": "os.pidfd_open = denied\n",
               "send": "signal.pidfd_send_signal = denied\n",
               "children": "_exists = os.path.exists\n"
                           "os.path.exists = lambda p: False if str(p).endswith('/children')"
                           " else _exists(p)\n"}[denied]
            # The runner starts the helper with interpreter flags (COORDINATION_PYTHON); the stub
            # imitates the CLI, so it consumes them before the script path.
            + "while sys.argv[1].startswith('-'): sys.argv.pop(1)\n"
            + "target = sys.argv.pop(1)\nrunpy.run_path(target, run_name='__main__')\n")
        python_stub.chmod(0o755)
        capability_effect.unlink(missing_ok=True)
        result = run(repo, "phase", "20260101-one", extra={"COORD_PROBE": str(capability_effect)})
        check("unavailable pidfd refuses before config: " + denied,
              result.returncode != 0 and "CHECKOUT-UNAVAILABLE" in result.stdout
              and not capability_effect.exists(), result.stdout[:300])
        check("help survives unavailable pidfd: " + denied, run(repo, "help").returncode == 0)
    python_stub.unlink()
    # A signal that lands after the worker already exited, while only a straggler is being reaped,
    # must not rewrite the worker's status: a late Ctrl-C turned a successful run into 130.
    # DIFFERENTIAL: the same family and the same signal, once after the worker exit and once before.
    late_probe = work / "late-signal.py"
    late_probe.write_text(
        "import importlib.util, os, signal, sys, threading, time\n"
        "spec = importlib.util.spec_from_file_location('coord', sys.argv[1])\n"
        "m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)\n"
        "signals = m.signal_state()\n"
        "worker = os.fork()\n"
        "if worker == 0:\n"
        "    time.sleep(0 if sys.argv[2] == 'after' else 3); os._exit(0)\n"
        "straggler = os.fork()\n"
        "if straggler == 0:\n"
        "    time.sleep(5); os._exit(0)\n"
        "def late():\n"
        "    time.sleep(.5); os.kill(os.getpid(), signal.SIGINT)\n"
        "threading.Thread(target=late, daemon=True).start()\n"
        "print(m.wait_family(worker, signals))\n")
    late = {}
    for when in ("after", "before"):
        # -B: importing the helper must not leave bin/__pycache__/ in the kit's tree.
        probe = subprocess.run([sys.executable, "-B", str(late_probe),
                                str(root / "bin/sdd-coordination.py"), when],
                               capture_output=True, text=True, timeout=8)
        late[when] = probe.stdout.strip()
    check("a signal after the worker's own exit keeps its status", late["after"] == "0", late)
    check("...and the same signal before it still reports the interrupt", late["before"] == "130", late)
    # Each process gets each signal ONCE. The rescan runs every 10 ms and used to re-send INT on
    # every pass, so a cleanup handler was interrupted by the next INT (CodeRabbit, PR #48). The
    # child counts deliveries and does not reset its handler — the defensive fixtures above do.
    count_file = work / "int-count"
    once_probe = work / "signal-once.py"
    once_probe.write_text(
        "import importlib.util, os, signal, sys, threading, time\n"
        "spec = importlib.util.spec_from_file_location('coord', sys.argv[1])\n"
        "m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)\n"
        "signals = m.signal_state()\n"
        "worker = os.fork()\n"
        "if worker == 0:\n"
        "    signal.signal(signal.SIGINT, lambda n, f: open(sys.argv[2], 'a').write('x'))\n"
        "    time.sleep(6); os._exit(0)\n"
        "def late():\n"
        "    time.sleep(.5); os.kill(os.getpid(), signal.SIGINT)\n"
        "threading.Thread(target=late, daemon=True).start()\n"
        "print(m.wait_family(worker, signals))\n")
    count_file.unlink(missing_ok=True)
    once = subprocess.run([sys.executable, "-B", str(once_probe), str(root / "bin/sdd-coordination.py"),
                           str(count_file)], capture_output=True, text=True, timeout=8)
    deliveries = len(count_file.read_text()) if count_file.exists() else 0
    check("a cooperative signal reaches each process once", deliveries == 1,
          "deliveries=%d rc=%s" % (deliveries, once.stdout.strip()))
    # A timed-out hook gets ONE TERM and then its grace. The nested timeout(1) used to receive the
    # supervisor's TERM too, and GNU timeout turns any signal after its own TERM into an immediate
    # KILL — the hook's trap was cut at ~1.1 s instead of 2 s (traced; Codex on PR #48).
    term_file = work / "hook-terms"
    term_file.unlink(missing_ok=True)
    started = time.monotonic()
    hook = subprocess.run([sys.executable, "-B", str(root / "bin/sdd-coordination.py"), "hook", "1", "1",
                           'trap "printf x >> \\"$TERM_FILE\\"" TERM; while :; do sleep 5 & wait; done'],
                          env=dict(env, TERM_FILE=str(term_file)), capture_output=True, text=True,
                          timeout=8)
    elapsed = time.monotonic() - started
    terms = len(term_file.read_text()) if term_file.exists() else 0
    check("a timed-out hook gets one TERM and then its grace",
          hook.returncode == 124 and terms == 1 and elapsed >= 1.7,
          "rc=%s terms=%d elapsed=%.2f" % (hook.returncode, terms, elapsed))
    # `show` and `check` only ask: they answer from /proc and never take the flock, or a question
    # asked at the wrong instant made a concurrent `enter` fail CHECKOUT-BUSY (CodeRabbit, PR #48).
    flock_log = work / "flock-calls"
    for mode in ("show", "check"):
        flock_log.unlink(missing_ok=True)
        subprocess.run([sys.executable, "-B", "-c",
                        "import fcntl, os, runpy, sys\n"
                        "real = fcntl.flock\n"
                        "def spy(*a):\n"
                        "    open(os.environ['FLOCK_LOG'], 'a').write('x'); return real(*a)\n"
                        "fcntl.flock = spy\n"
                        "sys.argv = sys.argv[1:]\n"
                        "runpy.run_path(sys.argv[0], run_name='__main__')\n",
                        str(root / "bin/sdd-coordination.py"), mode, str(repo), str(repo / ".git"),
                        "query"], env=dict(env, FLOCK_LOG=str(flock_log)),
                       capture_output=True, text=True, timeout=8)
        check("%s answers without taking the checkout flock" % mode, not flock_log.exists(),
              flock_log.read_text() if flock_log.exists() else "")
    # ADR's explicit target controls both ownership and config, regardless of the caller cwd.
    adr_target = fixture("adr-target")
    adr_alias = work / "adr-alias"
    adr_alias.symlink_to(adr_target, target_is_directory=True)
    target_config = adr_target / ".sdd/config.sh"
    target_config.write_text(target_config.read_text() + '\nADR_DIR="docs/target-adr"\n')
    target_before = snapshot(adr_target)
    with open(adr_target / ".git/sdd-coordination.lock", "a+") as target_lock:
        fcntl.flock(target_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        for target in (str(adr_target), "../adr-alias"):
            busy(repo, "adr", "new", "--slug", "cross", "--repo", target,
                 name="ADR target owns admission: " + target)
            check("busy ADR target has no file effects", snapshot(adr_target) == target_before)
    caller_before = snapshot(repo)
    result = run(repo, "adr", "new", "--slug", "cross", "--repo", str(adr_alias))
    check("free ADR target uses its config and physical root", result.returncode == 0
          and (adr_target / "docs/target-adr/0001-cross.md").exists()
          and snapshot(repo) == caller_before, result.stdout)
    result = run(repo, "adr", "new", "--repo", str(adr_target), "--ticket", "--repo",
                 "--slug", "consumed-option", "--dry-run")
    check("ADR admission and dispatch share option consumption", result.returncode == 0
          and result.stdout.strip() == "docs/target-adr/0002-consumed-option.md", result.stdout)
    # A spec must stay inside the admitted checkout even when the other checkout is occupied.
    spec_external = fixture("adr-external")
    external_spec = spec_external / "docs/spec.md"
    external_spec.write_text("# Spec\n\n**ADR**: none\n")
    (adr_target / "docs/outside").symlink_to(spec_external / "docs", target_is_directory=True)
    config_effect = work / "external-spec-config-effect"
    with open(spec_external / ".git/sdd-coordination.lock", "a+") as external_lock:
        fcntl.flock(external_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        for spelling in ("../adr-external/docs/spec.md", "docs/outside/spec.md"):
            external_spec.write_text("# Spec\n\n**ADR**: none\n")
            config_effect.unlink(missing_ok=True)
            before = [snapshot(path) for path in (repo, adr_target, spec_external)]
            result = run(repo, "adr", "new", "--repo", str(adr_alias), "--slug", "outside",
                         "--spec", spelling, extra={"COORD_PROBE": str(config_effect)})
            check("external ADR spec is refused: " + spelling, result.returncode == 1
                  and "outside the admitted checkout" in result.stdout, result.stdout)
            check("external ADR spec refusal has no effects: " + spelling,
                  before == [snapshot(path) for path in (repo, adr_target, spec_external)]
                  and not config_effect.exists())
    (adr_target / "internal").symlink_to(adr_target / "docs", target_is_directory=True)
    for name, spelling in (("absolute", str(adr_alias / "docs/spec-absolute.md")),
                           ("relative", "internal/spec-relative.md")):
        spec_file = adr_target / ("docs/spec-" + name + ".md")
        spec_file.write_text("# Spec\n\n**ADR**: none\n")
        result = run(repo, "adr", "new", "--repo", str(adr_alias), "--slug", name, "--spec", spelling)
        records = list((adr_target / "docs/target-adr").glob("*-" + name + ".md"))
        check("internal ADR spec alias preserves both link ends: " + name, result.returncode == 0
              and len(records) == 1 and "**Spec**: docs/spec-" + name + ".md" in records[0].read_text()
              and "**ADR**: " + str(records[0].relative_to(adr_target)) in spec_file.read_text(), result.stdout)
    # Kernel ownership is authoritative even before metadata has been published.
    lock_file = open(repo / ".git/sdd-coordination.lock", "a+")
    fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    busy(repo, "install", name="metadata-free kernel lock refuses admission")
    lock_file.close()
    owner = start(repo)
    for args in [("run", "20260101-one"), ("run", "20260101-two"),
                 ("run", "20260101-one", "--dry-run"), ("retry", "20260101-one"),
                 ("close", "20260101-one"), ("kaizen",), ("approve", "20260101-one"),
                 ("install", "--force"), ("adr", "new", "--slug", "new"),
                 ("preflight",), ("status", "20260101-one"),
                 ("phase", "20260101-one"), ("why", "20260101-one", "EXEC"),
                 ("boot", "20260101-one", "EXEC")]:
        busy(repo, *args)
    busy(repo, binary=root / "bin/sdd-link-agents", name="alternate linker shares admission")
    alias = work / "alias"
    alias.symlink_to(repo, target_is_directory=True)
    busy(alias, "install", name="symlink checkout shares ownership")
    runner_alias = work / "sdd-alias"
    runner_alias.symlink_to(sdd)
    busy(repo, "install", binary=runner_alias, name="symlink runner shares ownership")
    busy(repo, "install", extra={"SDD_STATE_DIR": str(work / "different-state")},
         name="state directory cannot split checkout ownership")
    for args in [("status", "20260101-one", "--no-gates"),
                 ("census", "20260101-one"), ("autonomy",), ("kaizen", "--series"),
                 ("adr", "check"), ("help",), ("version",)]:
        result = run(repo, *args)
        check("query stays available: " + " ".join(args),
              result.returncode != 75 and "CHECKOUT-BUSY" not in result.stdout, result.stdout[:200])
        if args[0] == "status":
            check("query reports active owner", "CHECKOUT-OWNER" in result.stdout
                  and str(owner[0].pid) in result.stdout, result.stdout[:500])
    independent = work / "worktree"
    git(repo, "worktree", "add", "-qb", "independent", str(independent))
    result = run(independent, "install")
    check("independent worktree can execute", result.returncode == 0, result.stdout)
    lock_inode = (repo / ".git/sdd-coordination.lock").stat().st_ino
    check("normal completion preserves result", release(owner) == 0)
    check("release keeps the same lock inode", (repo / ".git/sdd-coordination.lock").stat().st_ino == lock_inode)
    check("normal completion recovers", run(repo, "install").returncode == 0)
    # The lock helper runs isolated from the caller's Python environment (`python3 -I`). Without
    # it a PYTHONPATH entry shadows the helper's stdlib imports — json here — and code nobody
    # reviewed runs inside the process that decides checkout ownership, on every coordinated call.
    # The shadow hands the real module back, so the failure is "it ran", never a crash.
    shadow = work / "shadow"
    shadow.mkdir()
    shadowed = work / "shadowed"
    (shadow / "json.py").write_text(
        "import importlib, os, sys\n"
        "open(os.environ['COORD_SHADOWED'], 'a').write('json\\n')\n"
        "here = os.path.dirname(os.path.abspath(__file__))\n"
        "sys.path[:] = [p for p in sys.path if os.path.abspath(p or '.') != here]\n"
        "del sys.modules['json']\n"
        "sys.modules['json'] = importlib.import_module('json')\n")
    result = run(repo, "install", extra={"PYTHONPATH": str(shadow), "COORD_SHADOWED": str(shadowed)})
    check("the lock helper ignores the caller's PYTHONPATH",
          result.returncode == 0 and not shadowed.exists(),
          "rc %d, shadow module ran: %s" % (result.returncode, shadowed.exists()))
    # A caller holding descriptors 3..~1110 pushes every descriptor the supervisor opens past 1023,
    # where select() raises ValueError: the supervisor died mid-run and its flock went with it,
    # under a live worker (CodeRabbit on PR #59). Reachable in practice: Node raises the soft
    # RLIMIT_NOFILE to the hard one, and every child of a harness session inherits it. The worker
    # counts its own descriptors, which proves the world was built — a caller that closed them
    # would make this probe pass over a supervisor that never saw a high descriptor.
    # A supervisor that dies leaves its worker orphaned and holding the output pipe, so the broken
    # world ends in a timeout, not in an rc: caught here and read as the failure it is.
    fdcount = work / "fdcount"
    try:
        # The soft limit is DERIVED from the hard one (Codex on PR #59): a fixed `ulimit -n 4096`
        # skipped every host whose hard limit sits between ~1040 and 4095, where a descriptor CAN
        # pass 1023 — and there mut_COORD_select_pidfd survived. Eight descriptors are left free
        # for bash and the helper's own opens, so the supervisor's pidfd lands at soft-8 or above.
        crowded = subprocess.run(["bash", "-c",
            'hard=$(ulimit -Hn); [ "$hard" = unlimited ] && hard=1100\n'
            '[ "$hard" -ge 1040 ] || exit 3\n'
            'soft=$(( hard < 1100 ? hard : 1100 )); ulimit -n "$soft" || exit 3\n'
            'for n in 3 4 5 6 7 8 9; do eval "exec $n</dev/null"; done\n'
            'while exec {fd}</dev/null && [ "$fd" -lt $((soft - 8)) ]; do :; done\n'
            'exec "$0" phase 20260101-one', str(sdd)],
            cwd=repo, env=dict(env, COORD_FDCOUNT=str(fdcount)), text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=8)
    except subprocess.TimeoutExpired as error:
        crowded = subprocess.CompletedProcess(error.cmd, 124, (error.output or b"").decode(errors="replace"))
    if crowded.returncode == 3:
        # The world NOT built here: a hard limit below 1040. At 1024 or less no descriptor can pass
        # 1023, so the defect cannot happen; between 1025 and 1039 it can, but only for a caller
        # holding all but a handful of its descriptors, and this probe does not build that world.
        print("  skip  a crowded caller: the hard RLIMIT_NOFILE is below 1040 on this machine", flush=True)
    else:
        seen = int(fdcount.read_text()) if fdcount.exists() else 0
        check("a caller holding descriptors past 1023 keeps the supervisor alive",
              crowded.returncode == 0 and "CHECKOUT-UNAVAILABLE" not in crowded.stdout and seen >= 1024,
              "rc %d, worker saw %d descriptors: %s" % (crowded.returncode, seen, crowded.stdout[-300:]))
    nested = start(repo, mode="reentry")
    results = json.loads((work / "nested-results").read_text())
    for args, code, output in results:
        expected = 0 if args[0] in ("install", "adr", "metadata") else 75
        check("nested admission: " + " ".join(args), code == expected, str(code) + " " + output)
    busy(repo, "install", name="nested helpers preserve outside ownership")
    value = json.loads((repo / ".git/sdd-coordination.json").read_text())
    metadata_file = repo / ".git/sdd-coordination.json"
    original_metadata = metadata_file.read_bytes()
    metadata_file.write_text('{"owner": "corrupted"}')
    busy(repo, "install", name="malformed diagnostics never override kernel refusal")
    metadata_file.write_bytes(original_metadata)
    busy(repo, "install", extra={"SDD_COORDINATION_ID": value["execution_id"]},
         name="copied owner environment is not authorization")
    busy(repo, "install", extra={"SDD_COORDINATION_ID": "forged"},
         name="forged environment is not authorization")
    release(nested)
    stale = repo / ".git/sdd-coordination.json"
    stale.write_text(json.dumps(value))
    check("stale metadata does not retain ownership", run(repo, "install").returncode == 0)
    special = start(repo, code=76)
    check("worker status cannot masquerade as admission", release(special) == 76)

    kit = fixture("kit")
    shutil.copytree(root / "bin", kit / "bin")
    (kit / "tests").mkdir()
    (kit / "tests/check-mutation.sh").write_text("# fixture catalogue\n")
    health_owner = start(kit)
    busy(repo, "health", binary=kit / "bin/sdd", name="health locks the kit it measures")
    # A kit cwd takes precedence over the installed executable's kit.
    busy(kit, "health", name="health honors measured cwd over executable home")
    release(health_owner)
    (kit / "tests/run-all.sh").write_text("#!/usr/bin/env bash\necho fixture-suite-failed\nexit 1\n")
    (kit / "tests/run-all.sh").chmod(0o755)
    # An authenticated health auxiliary may enter the currently owned kit.
    config = kit / ".sdd/config.sh"
    config.write_text(config.read_text().replace('  COORD_WORKER="$$" python3 "$COORD_BARRIER"',
        '  if [ -n "${COORD_HEALTH_NESTED:-}" ]; then env -u COORD_HOLD "$COORD_SDD" health > "$COORD_HEALTH_NESTED" 2>&1 || true; fi\n  COORD_WORKER="$$" python3 "$COORD_BARRIER"'))
    env["COORD_HEALTH_NESTED"] = str(work / "nested-health")
    nested_health = start(kit, binary=kit / "bin/sdd")
    health_output = (work / "nested-health").read_text()
    check("nested health enters owned measured tree", "kit sensor at " + str(kit) in health_output
          and "CHECKOUT-BUSY" not in health_output and "fixture-suite-failed" in health_output,
          health_output[:500])
    release(nested_health)
    env.pop("COORD_HEALTH_NESTED", None)
    # Signal delivery must not release a still-running descendant, or leak ownership forever.
    for number in (signal.SIGTERM, signal.SIGINT):
        interrupted = start(repo)
        interrupted[0].send_signal(number)
        code = interrupted[0].wait(timeout=8)
        check("signal status: " + str(number), code in (-number, 128 + number), str(code))
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            result = run(repo, "install")
            if result.returncode != 75:
                break
            time.sleep(.01)
        check("signal recovers: " + str(number), result.returncode == 0, result.stdout)
    # The direct-child control proves its explicit handler before forwarding through the owner.
    for mode, receiver in (("cooperative", "owner"), ("foreground", "child"), ("foreground", "owner"),
                           ("foreground-escaped", "owner"), ("foreground-threaded", "owner")):
        label = mode + "/" + receiver
        cooperative = start(repo, mode=mode, code=42, args=("phase", "20260101-one"))
        handled = Path(str(cooperative[1]) + ".handled")
        finished = Path(str(cooperative[1]) + ".finished")
        recipient = cooperative[0].pid if receiver == "owner" else json.loads(cooperative[1].read_text())["pid"]
        os.kill(recipient, signal.SIGINT)
        deadline = time.monotonic() + 8
        while not handled.exists() and cooperative[0].poll() is None and time.monotonic() < deadline:
            time.sleep(.01)
        check("SIGINT executes handler: " + label, handled.exists() and handled.read_text() == "handled")
        busy(repo, "install", name="SIGINT cleanup retains ownership: " + label)
        check("SIGINT preserves public status: " + label, release(cooperative) == (130 if receiver == "owner" else 42))
        check("SIGINT cleanup finishes before releasing ownership: " + label,
              finished.exists() and finished.read_text() == "cleaned")
        check("SIGINT cooperative cleanup recovers: " + label, run(repo, "install").returncode == 0)
    config = repo / ".sdd/config.sh"
    original_config = config.read_text()
    config.write_text(original_config + '\nif [ -n "${COORD_STDIN:-}" ]; then read -r answer; printf "%s\\n" "$answer"; exit 0; fi\n')
    stdin_result = subprocess.run([str(sdd), "phase", "20260101-one"], cwd=repo,
                                  env=dict(env, COORD_STDIN="1"), input="stdin-witness\n",
                                  text=True, capture_output=True, timeout=8)
    check("stdin survives supervision", stdin_result.returncode == 0
          and stdin_result.stdout == "stdin-witness\n", stdin_result.stdout + stdin_result.stderr)
    config.write_text(original_config)
    # A hook must remain bounded even when a child leaves timeout's process group.
    hook_repo = fixture("hook-escape")
    mission = hook_repo / "docs/handoffs/20260101-one"
    (mission / "00-missao.md").write_text("---\naprovacao: auto\nadr: none\n---\n")
    (mission / "01-plano.md").write_text("")
    (mission / "checkpoint.md").write_text("| ID | Increment | Check | Status | Commit |\n|---|---|---|---|---|\n| I1 | slice | `true` | blocked | - |\n")
    git(hook_repo, "add", "-A")
    git(hook_repo, "commit", "-qm", "hook fixture")
    hook_fifo = work / "hook-release"
    os.mkfifo(hook_fifo)
    hook_ready = work / "hook-ready"
    hook_child = work / "hook-child.py"
    hook_child.write_text('import os, signal\nfrom pathlib import Path\nsignal.signal(signal.SIGTERM, signal.SIG_IGN)\nPath(os.environ["HOOK_READY"]).write_text(str(os.getpid()))\nwith open(os.environ["HOOK_RELEASE"], "rb", buffering=0) as stream: stream.read(1)\n')
    hook = work / "hook.sh"
    hook.write_text('#!/usr/bin/env bash\nsetsid python3 "$HOOK_CHILD" &\nwait\n')
    hook.chmod(0o755)
    with open(work / "hook-owner.log", "w+") as hook_log:
        hook_owner = subprocess.Popen([str(sdd), "run", "20260101-one"], cwd=hook_repo,
            env=dict(env, COORD_HOOK=str(hook), HOOK_CHILD=str(hook_child),
                     HOOK_READY=str(hook_ready), HOOK_RELEASE=str(hook_fifo)),
            stdout=hook_log, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 8
        while not hook_ready.exists() and time.monotonic() < deadline:
            time.sleep(.01)
        check("escaped hook child was exercised", hook_ready.exists())
        hook_pid = int(hook_ready.read_text())
        hook_identity = Path("/proc/%d/stat" % hook_pid).read_text().rsplit(")", 1)[1].split()
        check("escaped hook child is alive in its own session", hook_identity[0] != "Z"
              and os.getsid(hook_pid) == hook_pid)
        bounded = True
        try:
            hook_status = hook_owner.wait(timeout=9)
        except subprocess.TimeoutExpired:
            bounded = False
            # Release our own barrier to bound a failing mutant without killing its supervisor.
            descriptor = os.open(hook_fifo, os.O_WRONLY | os.O_NONBLOCK)
            os.write(descriptor, b"x")
            os.close(descriptor)
            hook_status = hook_owner.wait(timeout=8)
        hook_log.seek(0)
        hook_output = hook_log.read()
    check("escaped hook cannot delay the escalation stop", bounded and hook_status == 3
          and "ON_ESCALATION_CMD" in hook_output, str(hook_status) + " " + hook_output[-300:])
    ledger_rows = [json.loads(line) for line in (work / "state/autonomy-log.jsonl").read_text().splitlines()]
    check("escaped hook preserves the escalation row", ledger_rows[-1]["event"] == "blocked"
          and ledger_rows[-1]["kind"] == "increment-blocked")
    hook_pid = int(hook_ready.read_text())
    try:
        hook_fields = Path("/proc/%d/stat" % hook_pid).read_text().rsplit(")", 1)[1].split()
        hook_alive = hook_fields[0] != "Z" and hook_fields[19] == hook_identity[19]
    except FileNotFoundError:
        hook_alive = False
    check("escaped hook leaves no live writer", not hook_alive)
    if hook_alive:
        descriptor = os.open(hook_fifo, os.O_WRONLY | os.O_NONBLOCK)
        os.write(descriptor, b"x")
        os.close(descriptor)
    check("escaped hook recovery releases ownership", run(hook_repo, "install").returncode == 0)
    failing = start(repo, code=7)
    check("error preserves worker status", release(failing) == 7)
    check("error recovers", run(repo, "install").returncode == 0)
    for victim, mode in [("owner", "ordinary"), ("worker", "ordinary"), ("owner", "escaped")]:
        orphan = start(repo, mode=mode)
        identity = json.loads(orphan[1].read_text())
        victim_pid = orphan[0].pid if victim == "owner" else identity["worker"]
        if orphan[0].poll() is None or victim == "worker":
            os.kill(victim_pid, signal.SIGKILL)
        if victim == "owner":
            orphan[0].wait(timeout=8)
        os.kill(identity["pid"], 0)
        check("orphan witness is alive: " + victim + "/" + mode,
              Path("/proc/%d/stat" % identity["pid"]).read_text().rsplit(")", 1)[1].split()[0] != "Z")
        busy(repo, "install", name="orphan retains ownership: " + victim + "/" + mode)
        release(orphan)
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            result = run(repo, "install")
            if result.returncode != 75:
                break
            time.sleep(.01)
        check("orphan completion recovers: " + victim + "/" + mode,
              result.returncode == 0, result.stdout)
        check("surviving child finished its write: " + victim + "/" + mode,
              Path(str(orphan[1]) + ".finished").read_text() == "child wrote after release")

finally:
    for item in owned:
        try:
            release(item)
        except (RuntimeError, ProcessLookupError):
            item[0].kill()
        # Failure cleanup targets only a process whose PID/start time came from this fixture.
        if item[1].exists():
            identity = json.loads(item[1].read_text())
            try:
                fields = Path("/proc/%d/stat" % identity["pid"]).read_text().rsplit(")", 1)[1].split()
                if fields[19] == identity["start"] and fields[0] != "Z":
                    os.kill(identity["pid"], signal.SIGKILL)
            except (FileNotFoundError, ProcessLookupError):
                pass
        item[3].close()
    shutil.rmtree(work)

if passed + failed < 154:
    raise SystemExit("SENSOR-BROKEN: coordination probe surface shrank")
print("coordination: %d passed, %d failed" % (passed, failed))
sys.exit(1 if failed else 0)
PY
