#!/usr/bin/env python3
"""Exercise the worker's public post-launch, review-resume and approval blocks."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

root = Path(sys.argv[1])
command = (root / "commands/sdd-worker.md").read_text()
blocks = {}
for name in ("run", "review", "plan", "approve"):
    section = command.split(f"### `{name}`\n", 1)[1].split("\n### ", 1)[0]
    matches = [b for b in re.findall(r'```bash\n(.*?)\n```', section, re.S)
               if "# Lookahead:" in b]
    if len(matches) != (2 if name == "run" else 1):
        sys.exit(f"{name}: no unique executable lookahead path in the public act")
    blocks[name] = "\n".join(matches)

with tempfile.TemporaryDirectory(prefix="worker-ahead-") as temp:
    box = Path(temp)
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    env.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1", PATH=f"{box}/kit/bin:{env['PATH']}", kit=str(box / "kit"), base="main")
    primary = box / "primary"
    primary.mkdir()
    kit = box / "kit/bin"
    kit.mkdir(parents=True)
    shutil.copy2(root / "bin/sdd-worker-ahead", kit)
    checks = box / "kit/tests"
    checks.mkdir()

    def call(argv, cwd=primary, **kwargs):
        return subprocess.run(argv, cwd=cwd, env=env, check=True, text=True,
                              stdout=subprocess.PIPE, **kwargs).stdout.strip()

    def git(*args, cwd=primary):
        return call(["git", *args], cwd)

    git("init", "-qb", "main")
    git("config", "user.name", "Fixture")
    git("config", "user.email", "fixture@example.invalid")
    (primary / ".sdd").mkdir()
    (primary / ".sdd/config.sh").write_text('HANDOFF_DIR="docs/handoffs"\n')
    git("add", ".sdd/config.sh")
    git("commit", "-qm", "base")
    git("clone", "-q", "--bare", ".", str(box / "origin"))
    git("remote", "add", "origin", str(box / "origin"))
    git("fetch", "-q", "origin")
    a = box / "runner-a"
    git("worktree", "add", "-qb", "fix/lot-a", str(a))
    campaign = primary / "docs/campaigns/20990101-fixture"
    campaign.mkdir(parents=True)
    handoff = box / "resume.md"
    source = box / "record-I1.md"
    source.write_text("# Owner request\n\nPlan the next lot during the run.\n")
    request = f"ahead-request: 20990101-fixture {source}#owner-request\n"
    handoff.write_text(request)
    trace = box / "trace"
    trace.touch()
    env.update(campaign_dir=str(campaign), resume_handoff=str(handoff), TRACE=str(trace),
               WORLD="ok", engine="codex", worktree=str(a), mission="20990101-lot-a", lot="L1")
    env["ROUND"] = "1"

    stub = r"""#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys, time
name = pathlib.Path(sys.argv[0]).name
act, *args = sys.argv[1:]
e = os.environ
world, stage = e['WORLD'], e['ROUND']
def mark(*parts):
    with open(e['TRACE'], 'a') as out:
        print('|'.join(parts), file=out)
if name == "sdd":
    if act == "status":
        if world == "dies-before-owner":
            sys.exit(0)
        mission = 'wrong-mission' if world == 'wrong-owner' else args[0]
        owner = e.get('FOREIGN_OWNER', e['OWNER_PID'])
        print(f"CHECKOUT-OWNER checkout={os.getcwd()} owner={owner} supervisor=1 command=run mission={mission} started=now")
    elif act == "approve":
        assert sys.stdin.read() == "y\n"
        mark("approve", args[0])
    else:
        sys.exit(91)
elif name == "sdd-worker":
    if act == "next":
        case = {
          '1': ('run', 'L1', '20990101-lot-a', 'L2'),
          'review': ('review', 'L1', '20990101-lot-a', 'L2'),
          'approve': ('approve', 'L2', '20990101-fixture-ahead-l2', ''),
          'plan': ('plan', 'L2', '-', ''),
          '2': ('run', 'L2', '20990101-fixture-ahead-l2', 'L3'),
          '3': ('run', 'L3', '20990101-fixture-ahead-l3', ''),
          'done': ('done', '-', '-', ''),
        }[stage]
        print(*case[:3], '— fixture')
        if case[3] and world != "no-successor":
            print('ahead plan', case[3])
        if world == "changed-next":
            print('unexpected extra line')
    else:
        mark(act, *args[1:])
        if (act, world) in (("allows", "expired"), ("budget", "poor"), ("codex-plan", "no-cost-consent")):
            sys.exit("fixture refusal")
elif name == "sdd-plan-codex":
    mission = args[0]
    meta = pathlib.Path(subprocess.check_output(
        ['git', 'rev-parse', '--absolute-git-dir'], text=True).strip()) / 'sdd-codex-planner'
    record = meta / (mission + '.json')
    if act == "start":
        os.kill(int(e['pid']), 0)
        assert pathlib.Path.cwd() != pathlib.Path(e['worktree'])
        assert not record.exists()
        mark('start', mission, os.getcwd())
        meta.mkdir(exist_ok=True)
        record.write_text(json.dumps({'campaign': args[args.index('--campaign') + 1],
                                      'lot': args[args.index('--lot') + 1]}))
        if world == "slow-start":
            time.sleep(.4)
    else:
        assert act == "status" and record.is_file()
        mark('status', mission, os.getcwd())
    print('question fixture-question')
elif name == "check-checkpoint.sh":
    assert pathlib.Path(args[0]).is_file()
    mark("check", act)
    if act == "--red":
        print("  ok    checkpoint.md: 14 pending Check(s), every one red at HEAD")
        if world == "red-plan":
            sys.exit(1)
elif name == "tail":
    mark('wait', args[0])
else:
    sys.exit(92)
"""
    for executable in [kit / name for name in ("sdd", "sdd-worker", "sdd-plan-codex", "tail")] + [
            checks / "check-checkpoint.sh"]:
        executable.write_text(stub)
        executable.chmod(0o755)

    def action(name, rc=0):
        result = subprocess.run(["bash", "-c", blocks[name]], env=env, cwd=primary,
                                text=True, capture_output=True, timeout=20)
        assert result.returncode == rc, (name, env["WORLD"], result.returncode, result.stderr, result.stdout)
        return result.stdout

    def lines(event):
        return [line for line in trace.read_text().splitlines() if line.startswith(event + "|")]

    runner_job = """sleep 120 & child=$!; trap 'kill "$child"; wait "$child"' TERM; echo "$child"; wait"""
    with subprocess.Popen(["bash", "-c", runner_job], stdout=subprocess.PIPE, text=True) as runner:
        env.update(pid=str(runner.pid), OWNER_PID=runner.stdout.readline().strip())
        try:
            for world in ("absent", "ambiguous", "wrong-campaign", "no-successor",
                          "changed-next", "wrong-owner", "expired", "poor", "no-cost-consent",
                          "foreign-owner", "dead"):
                env["WORLD"] = world
                env["FOREIGN_OWNER"] = str(os.getpid()) if world == "foreign-owner" else env["OWNER_PID"]
                if world == "dead":
                    env["pid"] = "2147483647"
                handoff.unlink(missing_ok=True)
                if world != "absent":
                    handoff.write_text({"ambiguous": request * 2, "wrong-campaign":
                                        request.replace("fixture", "other")}.get(world, request))
                before = len(lines("wait"))
                action("run")
                assert not lines("start") and len(lines("wait")) == before + 1, world
            with subprocess.Popen(["sleep", ".6"]) as dying:
                env.update(WORLD="dies-before-owner", pid=str(dying.pid), FOREIGN_OWNER=str(dying.pid))
                action("run")
                assert dying.wait(timeout=2) == 0 and not lines("start")
            env.pop("FOREIGN_OWNER")
            env.update(WORLD="slow-start", pid=str(runner.pid), ROUND="review")
            action("review")
            assert not lines("start"), "review alone cannot start a planner"
            env.update(ROUND="1", engine="claude")
            action("run")
            assert not lines("start")
            env["engine"] = "codex"
            with subprocess.Popen(["bash", "-c", blocks["run"]], env=env, cwd=primary,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) as worker:
                for _ in range(200):
                    if lines("start") or worker.poll() is not None:
                        break
                    time.sleep(.02)
                assert len(lines("start")) == 1, worker.communicate(timeout=20)
                action("run")
                out, err = worker.communicate(timeout=20)
                assert worker.returncode == 0, (out, err)
            assert runner.poll() is None
            _, bmission, bpath = lines("start")[0].split("|")
            b = Path(bpath)
            assert b != a and b != primary and b.is_dir()
            assert len(lines("start")) == 1
            recent = trace.read_text().splitlines()
            assert recent.index(lines("start")[0]) < len(recent) - 1
            assert recent[-1].startswith("wait|")
            env.update(WORLD="ok", ROUND="review")
            assert "question fixture-question" in action("review")
            env.update(ROUND="plan", lot="L2")
            assert "question fixture-question" in action("plan")
            handoff.unlink()
            action("plan", 1)
            handoff.write_text(request)
            assert len(lines("start")) == 1 and len(lines("status")) >= 2

            mission_dir = b / "docs/handoffs" / bmission
            mission_dir.mkdir(parents=True)
            (mission_dir / "checkpoint.md").touch()
            (mission_dir / "00-missao.md").touch()
            git("commit", "-qm", "merge-before-approval", "--allow-empty")
            merged = git("rev-parse", "HEAD")
            git("--git-dir", str(box / "origin"), "fetch", "-q", str(primary), "main:main")
            env.update(worktree=bpath, mission=bmission, mission_dir=str(mission_dir), predecessor_merge=merged)
            action("approve", 1)
            env["ROUND"] = "approve"
            action("approve", 1)
            assert not lines("check") and not lines("approve")
            git("fetch", "-q", "origin", cwd=b)
            git("merge", "-q", "--ff-only", "origin/main", cwd=b)
            for world in ("red-plan", "poor", "expired"):
                env["WORLD"] = world
                action("approve", 1)
                assert not lines("approve"), world
            env["WORLD"] = "ok"
            unrelated = primary / "docs/handoffs" / bmission
            unrelated.mkdir(parents=True)
            (unrelated / "checkpoint.md").touch()
            env["mission_dir"] = str(unrelated)
            action("approve", 1)
            assert not lines("approve"), "approval cannot borrow a mission directory from another checkout"
            env["mission_dir"] = str(mission_dir)
            action("approve")
            assert lines("approve") == [f"approve|{bmission}"]
            tail = trace.read_text().splitlines()[-5:]
            assert [line.split("|")[0] for line in tail] == [
                "check", "check", "budget", "allows", "approve"], tail
            env.update(ROUND="2", lot="L2")
            action("run")
            assert len(lines("start")) == 2
            _, cmission, cpath = lines("start")[1].split("|")
            assert cpath not in (bpath, str(a), str(primary)) and cmission.endswith("-ahead-l3")
            env.update(ROUND="3", worktree=cpath, mission=cmission, lot="L3")
            action("run")
            env["ROUND"] = "done"
            assert call([str(kit / "sdd-worker"), "next", str(campaign)]).startswith("done - -")
            assert len(lines("start")) == 2 and len(lines("approve")) == 1
        finally:
            runner.terminate()
