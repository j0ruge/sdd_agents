#!/usr/bin/env python3
"""Per-checkout flock ownership and Linux descendant supervision; no mission state."""
import ctypes
import datetime
import fcntl
import json
import os
from pathlib import Path
import select
import signal
import stat
import sys
import time
import uuid

REQUIREMENTS = ('Linux >=5.3 procfs/pidfd with task children enumeration, Python 3.9+ and '
                'flock/subreaper support')


class Unavailable(Exception):
    """A named requirement of coordination this interpreter or kernel does not meet. `build` is
    True when the requirement belongs to the Python BUILD — the one case another interpreter fixes."""

    def __init__(self, requirement, build=False):
        super().__init__(requirement)
        self.build = build


def unavailable(requirement, build=False):
    """The CHECKOUT-UNAVAILABLE refusal: WHAT failed, IN WHICH interpreter, and the remedy when one
    is on disk. The terminal of the operator of 2026-09-28 resolved python3 to a uv-built CPython
    3.11 with no os.pidfd_open while /usr/bin/python3 3.12 served, and the refusal listed every
    requirement and pasted the raw error — a human diagnosed it by hand (finding 8). The runner never
    USES /usr/bin/python3: it only probes it to write the remedy, and ONLY for a requirement of the
    Python build (`build`): a kernel or seccomp refusal is the same under every interpreter, and a
    remedy there sends the operator to switch Pythons for nothing. Imports are local on purpose:
    this is the refusal path, and every coordinated call pays the helper's startup.

    The remedy is offered only when that interpreter passes THIS helper's own check (`capable`):
    version, the pidfd CALLS, task children, the subreaper and flock. Reading the two attributes
    passed a Python whose pidfd calls the kernel then refused, and the remedy failed for the very
    reason it claimed to fix (CodeRabbit and Codex, PR #176). SDD_SYSTEM_PYTHON replaces
    /usr/bin/python3 for the sensor, which cannot build an incapable /usr/bin/python3; bin/sdd reads
    the same name. One not named python3 gets no remedy: its directory first on PATH does not make
    `python3` resolve to it (CodeRabbit, PR #176). The probe never asks for a remedy of its own: an interpreter the probe finds
    lacking would, under a PATH python3 lacking the same, probe itself again and again."""
    import platform
    import shutil
    import subprocess
    resolved = shutil.which('python3') or 'no python3 on PATH'
    lines = ['CHECKOUT-UNAVAILABLE: %s' % requirement,
             '  interpreter: %s (sys.executable %s, Python %s)'
             % (resolved, sys.executable, platform.python_version())]
    system = os.environ.get('SDD_SYSTEM_PYTHON') or '/usr/bin/python3'
    if (build and os.access(system, os.X_OK) and resolved != 'no python3 on PATH'
            and os.path.basename(system) == 'python3'
            and sys.argv[1:2] != ['capable']
            and os.path.realpath(resolved) != os.path.realpath(system)):
        try:
            probe = subprocess.run(
                [system, '-I', '-S', os.path.abspath(__file__), 'capable'],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                timeout=5)
            if probe.returncode == 0:
                lines.append('  %s passes the same check: run PATH=%s:$PATH sdd <the same command>'
                             % (system, os.path.dirname(system)))
        except Exception:  # the refusal path must not trade a message for a traceback
            pass
    lines.append('  coordinated commands need %s' % REQUIREMENTS)
    return '\n'.join(lines)


if sys.version_info < (3, 9):
    sys.exit(unavailable('Python 3.9+ is required', build=True))

BUSY = 75


def process(pid):
    """PID plus kernel start time prevents stale metadata from authorizing a reused PID."""
    try:
        fields = Path('/proc/%d/stat' % int(pid)).read_text().rsplit(')', 1)[1].split()
        if fields[0] == 'Z':
            return None
        return {'pid': int(pid), 'start': fields[19], 'parent': int(fields[1])}
    except (OSError, ValueError, IndexError):
        return None


def same(saved):
    live = process(saved['pid'])
    return live is not None and live['start'] == saved['start']


def metadata(path):
    try:
        value = json.loads(path.read_text())
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def describe(label, root, value):
    owner = value.get('owner') if isinstance(value.get('owner'), dict) else {}
    supervisor = value.get('supervisor') if isinstance(value.get('supervisor'), dict) else {}
    return ('%s checkout=%s owner=%s supervisor=%s command=%s mission=%s started=%s' %
            (label, root, owner.get('pid', 'unknown'), supervisor.get('pid', 'unknown'),
             value.get('command', 'initializing'), value.get('mission', 'unknown'),
             value.get('started_at', 'unknown')))


def holds_lock(value, lock):
    """The recorded supervisor is alive and its kernel FD holds a WRITE flock on this lock file.

    Read from /proc, never by taking the lock: `show` and `check` only ask, and a question that
    grabbed the exclusive flock, even for an instant, made a concurrent `enter` fail CHECKOUT-BUSY
    against metadata of an owner that had already finished (CodeRabbit on PR #48)."""
    try:
        if not same(value['supervisor']):
            return False
        supervisor = value['supervisor']['pid']
        fd_path = '/proc/%d/fd/%d' % (supervisor, value['lock_fd'])
        held, expected = os.stat(fd_path), os.fstat(lock)
        if (held.st_dev, held.st_ino) != (expected.st_dev, expected.st_ino):
            return False
        fdinfo = Path('/proc/%d/fdinfo/%d' % (supervisor, value['lock_fd'])).read_text()
        return any('FLOCK' in line and 'WRITE' in line for line in fdinfo.splitlines())
    except (KeyError, TypeError, ValueError, OSError):
        return False


def authorized(value, root, lock, caller, boot):
    """Environment selects a candidate; live ancestry and the holder's kernel FD prove it."""
    try:
        if value['execution_id'] != os.environ.get('SDD_COORDINATION_ID'):
            return False
        if value['checkout'] != root or value['boot_id'] != boot:
            return False
        if not all(same(value[key]) for key in ('owner', 'supervisor', 'worker')):
            return False
        if not holds_lock(value, lock):
            return False
        supervisor = value['supervisor']['pid']
        worker = value['worker']['pid']
        current = caller
        seen = set()
        while current and current not in seen:
            seen.add(current)
            identity = process(current)
            if identity is None:
                return False
            if current == worker:
                return identity['parent'] == supervisor and all(
                    same(value[key]) for key in ('owner', 'supervisor', 'worker'))
            current = identity['parent']
        return False
    except (KeyError, TypeError, ValueError, OSError):
        return False


def pidfd_capability():
    # Check syscall availability and policy before any project config or session can run. Each
    # failure is raised as the requirement it breaks, so the refusal can say which one fell.
    if not hasattr(os, 'pidfd_open'):
        raise Unavailable('os.pidfd_open is missing from this Python build', build=True)
    try:
        descriptor = os.pidfd_open(os.getpid())
    except OSError as error:
        raise Unavailable('os.pidfd_open failed (denied by policy, or absent from the kernel): %s'
                          % error)
    try:
        if not hasattr(signal, 'pidfd_send_signal'):
            raise Unavailable('signal.pidfd_send_signal is missing from this Python build',
                              build=True)
        try:
            signal.pidfd_send_signal(descriptor, 0)
        except OSError as error:
            raise Unavailable('pidfd_send_signal failed (denied by policy, or absent from the kernel):'
                              ' %s' % error)
    finally:
        os.close(descriptor)
    # signal_family discovers descendants ONLY through /proc/<pid>/task/<tid>/children, which a
    # kernel without CONFIG_PROC_CHILDREN does not have. There every task reads as childless, a
    # signal reaches nobody, and an interrupted run keeps the lock (Codex on PR #48) — so the
    # absence is refused here, before execution, like a missing pidfd.
    if not os.path.exists('/proc/%d/task/%d/children' % (os.getpid(), os.getpid())):
        raise Unavailable('procfs has no task children enumeration (CONFIG_PROC_CHILDREN)')


PR_SET_CHILD_SUBREAPER = 36
PR_GET_CHILD_SUBREAPER = 37


def subreaper():
    pidfd_capability()
    libc = ctypes.CDLL(None, use_errno=True)
    # Linux prctl is variadic: pass explicit machine-width arguments.
    if libc.prctl(PR_SET_CHILD_SUBREAPER, ctypes.c_ulong(1), ctypes.c_ulong(0),
                  ctypes.c_ulong(0), ctypes.c_ulong(0)) != 0:
        raise OSError(ctypes.get_errno(), 'PR_SET_CHILD_SUBREAPER failed')
    enabled = ctypes.c_int()
    if libc.prctl(PR_GET_CHILD_SUBREAPER, ctypes.byref(enabled), 0, 0, 0) != 0 \
            or enabled.value != 1:
        raise OSError('PR_GET_CHILD_SUBREAPER did not confirm supervision')


# A second reader of bin/sdd's argument grammar, for the metadata's `mission=` only (display, never
# a decision). It knows the value-taking flags of run/retry/close today — `--phase` and
# `--max-phases`; `--dry-run` and `--budget-override` take none. A flag that gains a value in
# bin/sdd must be added here in the same commit, or `show` names the value as the mission.
def requested_mission(args):
    if '--mission' in args:
        index = args.index('--mission') + 1
        return args[index] if index < len(args) else 'auto'
    if args[0] not in ('run', 'retry', 'close', 'approve', 'status', 'phase', 'why'):
        return 'none'
    skip = False
    for arg in args[1:]:
        if skip:
            skip = False
        elif arg in ('--phase', '--max-phases'):
            skip = True
        elif not arg.startswith('-'):
            return arg
    return 'auto'


def signal_state():
    state = {'number': 0, 'time': None, 'timed_out': False}

    def on_signal(number, _frame):
        state['number'] = number
        if state['time'] is None:
            state['time'] = time.monotonic()

    for number in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(number, on_signal)
    return state


def signal_family(number, delivered=None, relay=None):
    """Pin descendants before signaling; snapshots select recipients, never release the lock.

    `delivered` remembers (pid, start, signal) across the caller's rescans. The rescan must go on —
    an adoptee appears only on a later pass — but each process gets each signal ONCE: sent every
    10 ms, a second Ctrl-C interrupted the cleanup handler it was meant to let run (a Python
    `finally`, a bash trap, a CLI that reads the second INT as "force exit"; CodeRabbit on PR #48).

    `relay` is a descendant that FORWARDS what it receives — the hook's timeout(1), which passes a
    TERM on to its whole group. It gets no cooperative signal (its command already gets one
    directly, and would get a second through it; Codex on PR #48); SIGKILL cannot be forwarded and
    still reaches it."""
    pending = [(process(os.getpid()), None)]
    pinned = []
    try:
        while pending:
            parent, parent_fd = pending.pop()
            try:
                if parent_fd is not None:
                    signal.pidfd_send_signal(parent_fd, 0)
                children = []
                for task in Path('/proc/%d/task' % parent['pid']).iterdir():
                    try:
                        children.extend((task / 'children').read_text().split())
                    except FileNotFoundError:
                        pass  # A thread can finish while its process remains alive.
                for pid in children:
                    identity = process(pid)
                    if identity is None or identity['parent'] != parent['pid']:
                        continue
                    descriptor = None
                    try:
                        descriptor = os.pidfd_open(identity['pid'])
                        # Opening a pidfd and reading procfs are separate operations. Recheck
                        # both identities and the parent edge before authorizing this handle.
                        if process(identity['pid']) != identity or not same(parent):
                            continue
                        if parent_fd is not None:
                            signal.pidfd_send_signal(parent_fd, 0)
                        pinned.append((identity, descriptor))
                        pending.append((identity, descriptor))
                        descriptor = None
                    except OSError:
                        # Concurrent exit/reparenting is normal; a later pass sees adoptees.
                        continue
                    finally:
                        if descriptor is not None:
                            os.close(descriptor)
            except OSError:
                continue
        # Children receive the cooperative signal before a waiting shell is interrupted.
        for identity, descriptor in reversed(pinned):
            if identity['pid'] == relay and number != signal.SIGKILL:
                continue
            key = (identity['pid'], identity['start'], number)
            if delivered is not None and key in delivered:
                continue
            try:
                signal.pidfd_send_signal(descriptor, number)
                if delivered is not None:
                    delivered.add(key)
            except OSError:
                pass
    finally:
        for _identity, descriptor in pinned:
            os.close(descriptor)


def wait_family(child, signals, deadline=None, grace=2, relay=None):
    worker_status = 1
    # Whether the worker had already exited, on its own, before any signal was recorded. Then a
    # signal that arrives while only stragglers are being reaped does not rewrite its status: a
    # late Ctrl-C used to turn a successful `sdd run` into 128+n. A timeout is not a signal the
    # worker survived — the hook family must finish inside its deadline — so 124 still wins.
    worker_done_first = False
    delivered = set()
    # Woken by the worker's exit, not by the next 10 ms tick: most coordinated calls are short and
    # the tick was latency added to every one of them. Signals still land in the handlers, which
    # interrupt the wait exactly as they interrupted the sleep. Once the worker is reaped its pidfd
    # stays readable, so it is closed there and the stragglers go back to the plain tick.
    # A pidfd that cannot be opened falls back to the tick too: raising here would end the
    # supervisor with the worker still alive, releasing the lock under it. No probe reaches this
    # branch, and it is declared rather than claimed: pidfd_capability() has already refused a
    # machine without pidfds before any worker exists, so the world where it runs is not built.
    # poll(), never select(): a caller holding descriptors past 1023 hands the supervisor a pidfd
    # select() refuses with ValueError, and the supervisor died under a live worker (CodeRabbit on
    # PR #59; probe "a caller holding descriptors past 1023" in check-coordination.sh).
    worker_poll = select.poll()
    try:
        worker_fd = os.pidfd_open(child)
        worker_poll.register(worker_fd, select.POLLIN)
    except OSError:
        worker_fd = None
    try:
        while True:
            try:
                waited, status = os.waitpid(-1, os.WNOHANG)
            except ChildProcessError:
                break
            except InterruptedError:
                continue
            if waited:
                if waited == child:
                    worker_done_first = not signals['number']
                    worker_status = os.waitstatus_to_exitcode(status)
                    if worker_status < 0:
                        worker_status = 128 - worker_status
                    if worker_fd is not None:
                        worker_poll.unregister(worker_fd)
                        os.close(worker_fd)
                    worker_fd = None
                continue
            if deadline is not None and time.monotonic() >= deadline and signals['time'] is None:
                signals.update(number=signal.SIGTERM, time=deadline, timed_out=True)
            if signals['number']:
                sent = signal.SIGKILL if time.monotonic() - signals['time'] >= grace else signals['number']
                signal_family(sent, delivered, relay)
            if worker_fd is not None:
                worker_poll.poll(10)
            else:
                time.sleep(.01)
    finally:
        if worker_fd is not None:
            os.close(worker_fd)
    if signals['timed_out']:
        return 124
    if worker_done_first:
        return worker_status
    return 128 + signals['number'] if signals['number'] else worker_status


def bounded_hook(duration, grace, command):
    """One deadline covers timeout and every hook descendant, including escaped sessions."""
    duration, grace = float(duration), float(grace)
    os.setsid()
    subreaper()
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    signals = signal_state()
    deadline = time.monotonic() + duration
    child = os.fork()
    if child == 0:
        try:
            os.setsid()
            # timeout(1) is the BACKSTOP for a supervisor that died, so its deadline comes after
            # ours: on the normal path wait_family alone delivers TERM, then KILL, once each.
            os.execvp('timeout', ['timeout', '--kill-after=%ss' % grace,
                                  '%ss' % (duration + grace + 1), 'bash', '-c', command])
        except BaseException:
            os._exit(1)
    return wait_family(child, signals, deadline, grace, relay=child)


def supervise(root, lock, meta_path, args, caller, boot):
    """The public Bash launcher may die; this separate session holds the lock until ECHILD."""
    os.setsid()
    subreaper()
    signal.signal(signal.SIGCHLD, signal.SIG_DFL)
    # Bash starts this supervisor asynchronously with SIGINT ignored. Install handlers
    # before fork so exec restores catchable signals in the worker.
    signals = signal_state()
    value = {'checkout': root,
             'owner': process(caller), 'supervisor': process(os.getpid()), 'boot_id': boot,
             'lock_fd': lock, 'execution_id': str(uuid.uuid4()),
             'started_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
             'command': args[1],
             'mission': requested_mission(args[1:])}
    if value['owner'] is None:
        return 1
    reader, writer = os.pipe()
    child = os.fork()
    if child == 0:
        try:
            os.close(writer)
            os.close(lock)
            go = os.read(reader, 1)
            os.close(reader)
            if go != b'1':
                os._exit(1)
            os.setsid()
            os.environ['SDD_COORDINATION_ID'] = value['execution_id']
            os.execv(args[0], args)
        except BaseException:
            os._exit(1)
    os.close(reader)
    try:
        value['worker'] = process(child)
        temporary = meta_path.with_name(meta_path.name + '.' + value['execution_id'])
        temporary.write_text(json.dumps(value) + '\n')
        os.replace(temporary, meta_path)
        os.write(writer, b'1')
    except BaseException:
        # Startup failure never releases a live child or lets it enter the command.
        signals['number'] = signal.SIGTERM
        signals['time'] = time.monotonic()
        try:
            temporary.unlink(missing_ok=True)   # a write that landed but was never renamed
        except (NameError, OSError):
            pass
    finally:
        os.close(writer)
    result = wait_family(child, signals)
    # The kernel, not a process-tree snapshot or timer, established the absence of descendants.
    if metadata(meta_path).get('execution_id') == value['execution_id']:
        meta_path.unlink(missing_ok=True)
    return result


def main():
    """The CLI bin/sdd calls — its only caller:

      hook  <seconds> <grace> <command>          run ON_ESCALATION_CMD, the whole family bounded
      enter <root> <dir> <kind> <sdd> <args...>  take the checkout lock and supervise <sdd>
      check <root> <dir> <kind>                  0 when the caller descends from the lock holder;
                                                 kind `pipeline` further requires the worker itself
      show  <root> <dir> <kind>                  print the current owner, if any; never locks
      capable                                    0 when THIS interpreter meets every requirement;
                                                 the probe behind the refusal's remedy
    """
    if sys.argv[1:2] == ['capable']:
        subreaper()
        # flock is the requirement neither pidfd_capability() nor the subreaper reaches: a policy
        # that denies the syscall would pass the probe and earn a remedy no Python can deliver
        # (CodeRabbit, PR #176). A temporary file proves the syscall, not the checkout's own
        # filesystem: `enter` meets that at the lock, before any pidfd call, as a non-build refusal.
        import tempfile
        with tempfile.TemporaryFile() as probe:
            fcntl.flock(probe, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return 0
    if sys.argv[1:2] == ['hook']:
        return bounded_hook(*sys.argv[2:])
    if len(sys.argv) < 5:
        print('usage: sdd-coordination.py capable|hook|enter|check|show <root> <dir> <kind> [args...]',
              file=sys.stderr)
        return 2
    mode, root, directory, kind, *args = sys.argv[1:]
    root = os.path.realpath(root)
    directory = Path(directory)
    # Two questions that must not write: nothing to show, and nothing a caller could descend from.
    if mode in ('show', 'check') and not directory.exists():
        return 0 if mode == 'show' else 1
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    lock_path = directory / 'sdd-coordination.lock'
    meta_path = directory / 'sdd-coordination.json'
    if mode in ('show', 'check') and not lock_path.exists():
        return 0 if mode == 'show' else 1
    lock = os.open(lock_path, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    if not stat.S_ISREG(os.fstat(lock).st_mode):
        raise OSError('checkout lock is not a regular file')
    # The two questions answer from /proc (holds_lock) and never take the flock themselves.
    if mode == 'show':
        value = metadata(meta_path)
        if holds_lock(value, lock):
            print(describe('CHECKOUT-OWNER', root, value))
        return 0
    if mode == 'check':
        value = metadata(meta_path)
        boot = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
        caller = os.getppid()
        if authorized(value, root, lock, caller, boot):
            if kind != 'pipeline' or caller == value['worker']['pid']:
                return 0
        return 1
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        print(describe('CHECKOUT-BUSY', root, metadata(meta_path)), file=sys.stderr)
        return BUSY
    boot = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
    return supervise(root, lock, meta_path, args, os.getppid(), boot)


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Unavailable as error:
        print(unavailable(str(error), error.build), file=sys.stderr)
        sys.exit(1)
    except (OSError, ValueError, AttributeError) as error:
        print(unavailable('coordination failed: %s' % error), file=sys.stderr)
        sys.exit(1)
