#!/usr/bin/env python3
"""Exercita duas retomadas quando a primeira ainda está verificando orçamento."""
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
    assert len(blocks) == 2, "faltam os blocos públicos de despacho e espera"
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
        "commit", "-qm", "Base da fixture", "--allow-empty")
    git("clone", "-q", "--bare", ".", str(box / "origin"))
    git("remote", "add", "origin", str(box / "origin"))
    predecessor = box / "predecessor"
    git("worktree", "add", "-qb", "fix/lot-a", str(predecessor))
    campaign = primary / "docs" / "campaigns" / "20990101-fixture"
    campaign.mkdir(parents=True)
    source = box / "pedido.md"
    source.write_text("Planeje o próximo lote durante a execução.\n")
    handoff = box / "retomada.md"
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
            assert time.monotonic() < until, "orçamento não liberado"
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
    with subprocess.Popen(["sleep", "45"]) as predecessor_runner:
        try:
            env["pid"] = str(predecessor_runner.pid)
            with subprocess.Popen(args, cwd=primary, env={**env, "delay": "yes"},
                                  text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as delayed:
                try:
                    until = time.monotonic() + 10
                    while not (box / "entered").exists():
                        assert delayed.poll() is None and time.monotonic() < until, (
                            "a primeira retomada não chegou ao orçamento")
                        time.sleep(.02)
                    winner = subprocess.run(args, cwd=primary, env=env, check=True,
                                            text=True, capture_output=True, timeout=10)
                    assert "question fixture-question" in winner.stdout, winner
                finally:
                    (box / "release").touch()
                out, err = delayed.communicate(timeout=15)
            assert predecessor_runner.poll() is None, "o predecessor terminou antes da retomada"
        finally:
            predecessor_runner.terminate()

    events = [event for event in trace.read_text().splitlines()
              if event in {"start", "status", "wait"}]
    if (delayed.returncode != 0 or "Lookahead stopped" in err
            or "question fixture-question" not in out or events != ["start", "wait", "status", "wait"]):
        print(f"Retomada não reutilizou o único relay: eventos={events}\n{err}", file=sys.stderr)
        return 1
    print("1")
    return 0


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="worker-lookahead-race-") as directory:
        sys.exit(main(Path(sys.argv[1]).resolve(), Path(directory)))
