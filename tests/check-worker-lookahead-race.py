#!/usr/bin/env python3
"""Exercise overlapping resumes while the first is still checking its budget."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time


def main(root, box):
    command = (root / "commands/sdd-worker.md").read_text()
    run = command.split("### `run`\n", 1)[1].split("\n### ", 1)[0]
    blocks = [block for block in re.findall(r"```bash\n(.*?)\n```", run, re.S)
              if "# Lookahead:" in block]
    assert len(blocks) == 2, "missing public dispatch and wait blocks"
    primary = box / "primary"
    primary.mkdir()
    kit = box / "kit" / "bin"
    kit.mkdir(parents=True)
    shutil.copy2(root / "bin/sdd-worker-ahead", kit)
    env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    env.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1",
               PATH=f"{kit}:{env['PATH']}")

    def git(*args):
        subprocess.run(["git", *args], cwd=primary, env=env, check=True, timeout=10)

    git("init", "-qb", "main")
    git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
        "commit", "-qm", "Fixture base", "--allow-empty")
    git("clone", "-q", "--bare", ".", str(box / "origin"))
    git("remote", "add", "origin", str(box / "origin"))
    predecessor = box / "predecessor"
    git("worktree", "add", "-qb", "fix/lot-a", str(predecessor))
    campaign = primary / "docs" / "campaigns" / "20990101-fixture"
    campaign.mkdir(parents=True)
    source = box / "request.md"
    source.write_text("Plan the next lot during the run.\n")
    handoff = box / "resume.md"
    handoff.write_text(f"ahead-request: {campaign.name} {source}\n")
    trace = box / "trace"
    env.update(kit=str(kit.parent), box=str(box), campaign_dir=str(campaign),
               resume_handoff=str(handoff), worktree=str(predecessor),
               engine="codex", base="main", mission="20990101-lot-a")

    stub = '''#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys, time

name = pathlib.Path(sys.argv[0]).name
env = os.environ
box = pathlib.Path(env["box"])
act, *args = sys.argv[1:]
if name == "sdd":
    assert act == "status"
    print(f"CHECKOUT-OWNER checkout={os.getcwd()} owner={env['pid']} "
          f"supervisor=1 command=run mission={env['mission']} started=now")
    sys.exit(0)
elif name == "sdd-worker":
    if act == "next":
        print("run L1 20990101-lot-a — fixture\\nahead plan L2")
    elif act == "budget" and env.get("delay") == "yes":
        (box / "entered").touch()
        until = time.monotonic() + 15
        while not (box / "release").exists():
            assert time.monotonic() < until, "budget was not released"
            time.sleep(.02)
    else:
        assert act in ("budget", "allows", "codex-plan"), act
elif name == "sdd-plan-codex":
    meta = pathlib.Path(subprocess.check_output(
        ["git", "rev-parse", "--absolute-git-dir"], text=True).strip())
    record = meta / "sdd-codex-planner" / (args[0] + ".json")
    if act == "start":
        assert pathlib.Path.cwd() not in (pathlib.Path(env["worktree"]), box / "primary")
        assert not record.exists()
        record.parent.mkdir()
        record.write_text(json.dumps({"campaign": args[-3], "lot": args[-1]}))
    else:
        assert act == "status" and record.is_file()
    print("question fixture-question")
else:
    assert name == "tail" and act == "--pid=" + env["pid"]
    act = "wait"
with (box / "trace").open("a") as stream:
    print(act, file=stream)
'''
    for name in ("sdd", "sdd-worker", "sdd-plan-codex", "tail"):
        file = kit / name
        file.write_text(stub)
        file.chmod(0o755)

    args = ["bash", "-c", "\n".join(blocks)]
    successor = f"{campaign.name}-ahead-l2"
    branch = f"plan/{successor}"
    target = box / f".sdd-ahead-{primary.name}-{successor}"

    def resume():
        return subprocess.run(args, cwd=primary, env=env, check=True,
                              text=True, capture_output=True, timeout=10)

    def relay_and_wait():
        return [event for event in trace.read_text().splitlines()
                if event in {"start", "status", "wait"}]

    with subprocess.Popen(["sleep", "45"]) as predecessor_runner:
        try:
            env["pid"] = str(predecessor_runner.pid)
            git("branch", branch)
            refusal = resume()
            assert "unreserved successor" in refusal.stderr and relay_and_wait() == ["wait"], refusal
            git("branch", "-qD", branch)
            trace.write_text("")

            with subprocess.Popen(args, cwd=primary, env={**env, "delay": "yes"},
                                  text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as delayed:
                try:
                    until = time.monotonic() + 10
                    while not (box / "entered").exists():
                        assert delayed.poll() is None and time.monotonic() < until, (
                            "the first resume did not reach its budget check")
                        time.sleep(.02)
                    winner = resume()
                    assert "question fixture-question" in winner.stdout, winner
                finally:
                    (box / "release").touch()
                out, err = delayed.communicate(timeout=15)
            assert predecessor_runner.poll() is None, "the predecessor exited before resume"
            events = relay_and_wait()
            if (delayed.returncode != 0 or "Lookahead stopped" in err
                    or "question fixture-question" not in out or events != ["start", "wait", "status", "wait"]):
                print(f"Resume did not reuse the only relay: events={events}\n{err}", file=sys.stderr)
                return 1

            git("worktree", "move", str(target), str(box / "wrong-checkout"))
            refusal = resume()
            assert "ambiguous or missing reserved checkout" in refusal.stderr, refusal
            assert relay_and_wait() == [*events, "wait"], refusal
        finally:
            predecessor_runner.terminate()
    print("1")
    return 0


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="worker-lookahead-race-") as directory:
        sys.exit(main(Path(sys.argv[1]).resolve(), Path(directory)))
