#!/usr/bin/env python3
"""Exercise the worker's public post-launch, review-resume and approval blocks."""
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace

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

owner_request_check = sys.argv[2:] == ["--owner-request"]
markup_case = sys.argv[3] if sys.argv[2:3] == ["--preceding-markup"] else None
if owner_request_check or markup_case:
    verdict, = re.findall(r'```bash\n(rc=unknown\n.*?)\n```', command, re.S)
    blocks["run"] += '\n' + verdict + '\nprintf "verdict|%s|%s|%s\\n" "$rc" "$reason" "$why"'

def compact_scan_work(marker):
    scan = runpy.run_path(str(root / "bin/sdd-worker-ahead"))["local_anchors"]

    def measure(n):
        work = 0

        def counted(fullmatch, line, pos=0):
            nonlocal work
            work += len(line) - pos
            return fullmatch(line, pos)

        def compiled(pattern):
            regex = re.compile(pattern)
            return SimpleNamespace(match=regex.match, fullmatch=lambda *args: counted(regex.fullmatch, *args))

        scan.__globals__["re"] = SimpleNamespace(
            match=re.match, search=re.search, sub=re.sub, compile=compiled,
            fullmatch=lambda pattern, line: counted(re.compile(pattern).fullmatch, line),
        )
        assert scan(marker * n + "<script>\n\n# Owner request\n") == ["owner-request"]
        return work

    small, large = measure(2000), measure(4000)
    assert 0 < small and large <= 3 * small, (marker, small, large)


with tempfile.TemporaryDirectory(prefix="worker-ahead-") as temp:
    box = Path(temp)
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    env.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1", PATH=f"{box}/kit/bin:{env['PATH']}", kit=str(box / "kit"), base="main")
    primary = box / "primary checkout"
    primary.mkdir()
    kit = box / "kit/bin"
    kit.mkdir(parents=True)
    shutil.copy2(root / "bin/sdd-worker-ahead", kit)
    shutil.copy2(root / "bin/sdd-plan-codex", kit)
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
    queue = campaign / "campaign.md"
    queue.write_text("## Lots\n\n### L2\nScope only available in the primary queue.\n\n### L3\nNext scope.\n")
    handoff = box / "resume.md"
    source = box / "record-I1.md"
    instruction = "# Owner request\n\nPlan the next lot during the run.\n"
    source.write_text(instruction)
    request = f"ahead-request: 20990101-fixture {source}#owner-request\n"
    handoff.write_text(request)
    trace = box / "trace"
    trace.touch()
    env.update(campaign_dir=str(campaign), resume_handoff=str(handoff), TRACE=str(trace),
               SDD_STATE_DIR=str(box / "state"),
               WORLD="ok", engine="codex", worktree=str(a), mission="20990101-lot-a", lot="L1")
    env["ROUND"] = "1"

    stub = r"""#!/usr/bin/env python3
import json, os, pathlib, sys, time
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
        if act == "budget" and world.startswith("changes-"):
            heading = "# Owner request" if world == "changes-text" else "# Retired request"
            pathlib.Path(e["SOURCE"]).write_text(heading + "\n\nDo not plan ahead.\n")
        if (act, world) in (("allows", "expired"), ("budget", "poor"), ("codex-plan", "no-cost-consent")):
            sys.exit("fixture refusal")
elif name == "sdd-codex":
    os.kill(int(e['pid']), 0)
    assert '--read-only' in args and '--resume' not in args
    checkout = pathlib.Path.cwd()
    assert checkout != pathlib.Path(e['worktree'])
    pathlib.Path(e['TRACE']).with_name(checkout.name + '.prompt').write_text(sys.stdin.read())
    mark('start', str(checkout))
    if world == "slow-start":
        time.sleep(.4)
    print(json.dumps(dict(type='system', session_id='c0de1234-1234-4234-8234-123456789abc')))
    print(json.dumps(dict(type='result', is_error=False, result='fixture-question')))
elif name == "check-checkpoint.sh":
    assert pathlib.Path(args[0]).is_file()
    mark("check", act)
    if act == "--red":
        print("  ok    checkpoint.md: 14 pending Check(s), every one red at HEAD")
        if world == "red-plan":
            sys.exit(1)
elif name == "tail":
    if act == "-n":
        assert args == ["1", "--", e["log"]]
        print(pathlib.Path(args[-1]).read_text().splitlines()[-1])
    else:
        assert act == "--pid=" + e["pid"]
        mark('wait', args[0])
else:
    sys.exit(92)
"""
    for executable in [kit / name for name in ("sdd", "sdd-worker", "sdd-codex", "tail")] + [
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
            if owner_request_check or markup_case:
                log = box / "runner.log"
                diagnostic = "sdd run stop: phase-ceiling — fixture"
                log.write_text(f"{diagnostic}\nsdd run rc=3\n")
                env.update(log=str(log), SOURCE=str(source))
            if markup_case:
                html = "<div>\n- ```html\n  </div>\n\n"
                duplicate = "  # Owner request\n\nDo not plan the next lot.\n"
                item_html = "- Sample item\n  <div>\n  Sample content\n"
                compact = "- - <script>\n    <div>\n  "
                expanded = "- Outer item\n  - <script>\n    <div>\n  "
                paragraph = "10. - <script>\n    Text\n<sample-box>\n"
                thematic = "10. - <script></script>\n\n    ***\n<sample-box>\n"
                content, starts = {
                    "plain": (instruction, True),
                    "ordinary": ("An ordinary paragraph.\n\n" + instruction, True),
                    "closed-comment": ("<!--\n```text\n-->\n\n" + instruction, True),
                    "same-line-comment": ("<!-- note -->\n" + instruction, True),
                    "comment-in-fence": ("```text\n<!--\n```\n" + instruction, True),
                    "indented-comment": ("    <!--\n\n" + instruction, True),
                    "commented-heading": ("  <!--\n" + instruction + "-->\n", False),
                    "unclosed-comment": ("<!--\n\n" + instruction, False),
                    "backtick-info": ("``` text with `inline`\n\n" + instruction, True),
                    "tilde-info": ("~~~ text with `inline`\n" + instruction + "~~~\n", False),
                    "list-fenced-comment-marker": ("- ```html\n  <!--\n\n" + instruction, True),
                    "duplicate-after-list-code": (instruction + "\n- ```html\n  <!--\n\n"
                                                  "# Owner request\n\nDo not plan the next lot.\n", False),
                    "list-content-after-blank": ("- ```html\n  example\n\n  # Owner request\n", False),
                    "list-closed-fence": ("- ```html\n  <!--\n    ```\n  " + instruction, True),
                    "list-longer-fence": ("- ````html\n  ```\n  # Owner request\n", False),
                    "ordered-list-fence": ("2) ~~~html\n   <!--\n   # Owner request\n\n" + instruction, True),
                    "ordered-cannot-interrupt": ("Intro\n2. ```html\n   <!--\n\n" + instruction, False),
                    "ordered-can-interrupt": ("Intro\n1. ```html\n   <!--\n\n" + instruction, True),
                    "ordered-after-heading": ("Intro\n# Another title\n2. ```html\n   <!--\n\n" + instruction, True),
                    "ordered-after-comment": ("Intro\n<!-- note -->\n2. ```html\n   <!--\n\n" + instruction, True),
                    "ordered-after-code": ("    example\n2. ```html\n   <!--\n\n" + instruction, True),
                    "ordered-after-blank": ("Intro\n\n2. ```html\n   <!--\n\n" + instruction, True),
                    "ordered-after-invalid-fence": ("```text with `inline`\n2. ```html\n   <!--\n\n" + instruction, False),
                    "tabbed-list-fence": ("- ```html\n\t<!--\n  # Owner request\n", False),
                    "list-invalid-backticks": ("- ```text with `inline`\n  " + instruction, True),
                    "root-list-not-closer": ("```html\n- ```\n" + instruction + "```\n", False),
                    "html-before-unique": (html + "  " + instruction, True),
                    "html-before-duplicate": (instruction + "\n" + html + duplicate, False),
                    "html-before-comment": (html + "  <!--\n\n" + instruction + "-->\n", False),
                    "html-heading-before-blank": ("Intro\n  <DIV class=sample>\n</DIV>\n" + instruction, False),
                    "html-indented-opener": ("Intro\n  <div class=sample>\n" + instruction, False),
                    "html-heading-after-space-blank": (html.rstrip("\n") + "\n \t\n" + instruction, True),
                    "html-inside-fence": ("```html\n<div>\n```\n" + instruction, True),
                    "html-inside-indented-code": ("    <div>\n" + instruction, True),
                    "html-before-ordered-fence": ("<!--\n-->\n2. ```html\n   <!--\n\n" + instruction, True),
                    "html-custom-tag": ("<aside-box data-x='a > b'>\n" + instruction, False),
                    "html-custom-end-tag": ("</aside-box>\n" + instruction, False),
                    "html-inline-custom-tag": ("Intro\n<aside-box>\n" + instruction, True),
                    "html-custom-prefix-is-not-block-tag": ("Intro\n<div-box>\n" + instruction, True),
                    "html-tag-followed-by-text": ("<aside-box> text\n" + instruction, True),
                    "html-script": ("<SCRIPT type='text/plain'>\n\n  # Another title\n</SCRIPT>\n" + instruction, True),
                    "html-script-before-close-hidden": ("<script>\n\n" + instruction + "</script>\n", False),
                    "html-processing": ("<?sample\n\n  # Owner request\n?>\n" + instruction, True),
                    "html-declaration": ("<!DOCTYPE\n\n  # Owner request\n>\n" + instruction, True),
                    "html-cdata": ("<![CDATA[\n\n  # Owner request\n]]>\n" + instruction, True),
                    "html-list-end-unique": (item_html + instruction, True),
                    "html-list-end-duplicate": (instruction + "\n" + item_html + instruction, False),
                    "html-list-end-script": (item_html.replace("<div>", "<script>") + instruction, True),
                    "html-list-still-inside": (item_html + "  " + instruction, False),
                    "html-list-ordered-dedent": ("1. Sample item\n   <div>\n  " + instruction, True),
                    "html-list-after-blank": ("- Sample item\n\n  <script>\n" + instruction, True),
                    "html-list-indented-script": ("1. Sample item\n    <script>\n   " + instruction, False),
                    "html-list-start-custom-tag": ("Intro\n- <sample-box>\n  " + instruction, False),
                    "html-list-ordered-cannot-interrupt": ("Intro\n2. <script>\n   " + instruction, True),
                    "html-list-ordered-can-interrupt": ("Intro\n1. <script>\n   " + instruction, False),
                    "html-root-after-list": ("- Outer item\n  - Inner item\n<script>\n" + instruction, False),
                    "html-root-after-thematic-break": ("- - -\n  <script>\n" + instruction, False),
                    "html-root-after-fenced-list": ("```\n- Sample item\n  ```\n  <script>\n" + instruction, False),
                    "html-root-contains-fake-list": ("<div>\n- Sample item\n" + instruction, False),
                    "html-nested-list-dedent": ("- Outer item\n  - Inner item\n    <script>\n  <div>\n" + instruction, True),
                    "compact-nested-unique": (compact + instruction, True),
                    "compact-nested-duplicate": (instruction + "\n" + compact + instruction, False),
                    "compact-nested-closed": (compact[:-2] + "    </script>\n  " + instruction, True),
                    "compact-nested-still-inside": (compact + "  " + instruction, False),
                    "expanded-nested-unique": (expanded + instruction, True),
                    "expanded-nested-duplicate": (instruction + "\n" + expanded + instruction, False),
                    "compact-paragraph-unique": (paragraph + instruction, True),
                    "compact-paragraph-duplicate": (instruction + "\n" + paragraph + instruction, False),
                    "compact-html-after-blank": (paragraph.replace("Text\n", "Text\n        \n") + instruction, False),
                    "compact-html-after-indented-code": ("10. - <script></script>\n\n          Code\n<sample-box>\n"
                                                         + instruction, False),
                    "compact-scale-hyphens": ("- " * 4000 + "<script>\n\n" + instruction, True),
                    "compact-scale-pluses": ("+ " * 4000 + "<script>\n\n" + instruction, True),
                    "compact-scale-thematic": ("* " * 4000 + "\n  <script>\n" + instruction, False),
                    "compact-scale-thematic-in-item": ("+ - - -\n    <script>\n  " + instruction, False),
                    "thematic-after-html-hidden": (thematic + instruction, False),
                    "thematic-after-html-visible": (thematic + "\n" + instruction, True),
                    "thematic-after-html-duplicate": (instruction + "\n" + thematic + instruction, True),
                    "thematic-after-html-root-duplicate": (instruction + "\n" + thematic + "\n" + instruction, False),
                    "thematic-after-html-hyphens": (thematic.replace("***", "- - -") + instruction, False),
                    "thematic-after-html-in-item": ("10. ***\n<sample-box>\n" + instruction, False),
                    "thematic-after-html-underscores": (thematic.replace("***", "_ _ _") + instruction, False),
                }[markup_case]
                source.write_text(content)
                result = subprocess.run(["bash", "-c", blocks["run"]], env=env, cwd=primary,
                                        check=True, text=True, capture_output=True, timeout=20)
                events = [line.split("|", 1)[0] for line in trace.read_text().splitlines()
                          if line.startswith(("start|", "wait|"))]
                expected = ["start", "wait"] if starts else ["wait"]
                assert events == expected, (markup_case, expected, events)
                assert not result.stderr, (markup_case, result.stderr)
                assert result.stdout.endswith(f"verdict|3|phase-ceiling|{diagnostic}\n"), result.stdout
                if markup_case in ("compact-scale-hyphens", "compact-scale-pluses"):
                    compact_scan_work(content[:2])
                sys.exit(0)
            if owner_request_check:
                retired = "# Retired request\n\nDo not plan ahead.\n"
                narrow_fence = "````text\n```\n# Owner request\n````\n"
                wrong_fence = "~~~text\n```\n# Owner request\n~~~\n"
                fence_with_info = "```text\n```still-code\n# Owner request\n```\n"
                negative = (
                    ("stale", request, retired),
                    ("missing-file", request, None),
                    ("absent", None, instruction),
                    ("indented-code", request, "    # Owner request\n" + retired),
                    ("fenced", request, narrow_fence + retired),
                    ("wrong-fence", request, wrong_fence + retired),
                    ("fence-with-info", request, fence_with_info + retired),
                    ("duplicate", request, instruction + instruction),
                    ("empty-fragment", request.replace("#owner-request", "#"), "# !\n" + retired),
                    ("empty-file", request.replace("#owner-request", ""), "\n"),
                    ("relative", request.replace(str(source), "../record-I1.md"), instruction),
                    ("changes-fragment", request, instruction),
                    ("changes-text", request, instruction),
                )
                for world, reference, contents in negative:
                    for file, data in ((handoff, reference), (source, contents)):
                        if data is None:
                            file.unlink(missing_ok=True)
                        else:
                            file.write_text(data)
                    env["WORLD"] = world
                    trace.write_text("")
                    result = subprocess.run(["bash", "-c", blocks["run"]], env=env, cwd=primary,
                                            check=True, text=True, capture_output=True, timeout=20)
                    assert not lines("start"), f"{world}: a planner turn started"
                    assert lines("wait") == ["wait|-f"], (world, lines("wait"))
                    assert result.stdout.splitlines()[-1] == f"verdict|3|phase-ceiling|{diagnostic}", result
                    if world.startswith("changes-"):
                        assert "budget" in trace.read_text().splitlines() and "owner request changed" in result.stderr, result
                    else:
                        assert "budget" not in trace.read_text().splitlines() and not result.stderr, result
                env["WORLD"] = "ok"
                source.write_text(wrong_fence + "  ## Owner request! ##\n\nPlan the next lot.\n")
                handoff.write_text(request)
                out = action("run")
                receipt = next(line for line in out.splitlines() if line.startswith("lookahead "))
                assert json.loads(receipt.removeprefix("lookahead "))["request"] == f"{source}#owner-request"
                assert len(lines("start")) == 1 and out.endswith(f"verdict|3|phase-ceiling|{diagnostic}\n"), out
                env.update(ROUND="2", worktree=lines("start")[0].split("|", 1)[1],
                           mission="20990101-fixture-ahead-l2", lot="L2")
                link = "https://example.invalid/campaign#owner-request"
                handoff.write_text(f"ahead-request: {campaign.name} {link}\n")
                out = action("run")
                assert len(lines("start")) == 2 and json.dumps(link) in out, out
                sys.exit(0)
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
            question = re.search(r"^question [0-9a-f]{32}\nfixture-question$", out, re.M)
            assert question, (out, err)
            bmission = "20990101-fixture-ahead-l2"
            _, bpath = lines("start")[0].split("|")
            b = Path(bpath)
            assert b != a and b != primary and b.is_dir()
            assert len(lines("start")) == 1
            recent = trace.read_text().splitlines()
            assert recent.index(lines("start")[0]) < len(recent) - 1
            assert recent[-1].startswith("wait|")
            env.update(WORLD="ok", ROUND="review")
            assert question[0] in action("review")
            env.update(ROUND="plan", lot="L2")
            assert question[0] in action("plan")
            handoff.unlink()
            action("plan", 1)
            handoff.write_text(request)
            assert len(lines("start")) == 1

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
            _, cpath = lines("start")[1].split("|")
            cmission = "20990101-fixture-ahead-l3"
            assert cpath not in (bpath, str(a), str(primary)) and Path(cpath).name.endswith(cmission)
            env.update(ROUND="3", worktree=cpath, mission=cmission, lot="L3")
            action("run")
            env["ROUND"] = "done"
            assert call([str(kit / "sdd-worker"), "next", str(campaign)]).startswith("done - -")
            assert len(lines("start")) == 2 and len(lines("approve")) == 1
        finally:
            runner.terminate()

    print("ahead journey verified", flush=True)
    for checkout, lot_id in ((b, "L2"), (Path(cpath), "L3")):
        assert not (checkout / queue.relative_to(primary)).exists(), checkout
        prompt = trace.with_name(checkout.name + ".prompt").read_text()
        expected = f"Read the canonical queue at `{queue}` before planning lot {lot_id}."
        assert expected in prompt, f"first turn for {lot_id} did not point to the canonical queue"
