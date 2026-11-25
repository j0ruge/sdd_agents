#!/usr/bin/env python3
"""Exercise separate relay processes and a resumable Codex planner."""
import json
import os
from pathlib import Path
import subprocess
import runpy
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SESSION = "c0de1234-1234-4234-8234-123456789abc"


class PlannerTest(unittest.TestCase):
    def test_draft_rejects_shadowed_approval_and_branch(self):
        module = runpy.run_path(str(ROOT / "bin/sdd-plan-codex"))
        mission = "20261124-test"
        with tempfile.TemporaryDirectory() as scratch:
            root = Path(scratch)
            (root / ".sdd").mkdir()
            (root / ".sdd/config.sh").write_text("HANDOFF_DIR=docs/handoffs\n")
            for shadow in ("  aprovacao : auto\n", " branch : wrong\n", "missao : 20260101-other\n"):
                with self.subTest(shadow=shadow), patch.dict(module["materialize"].__globals__, {"git": lambda *_: "branch"}):
                    state = {"stage": "draft", "answers": [], "draft": {
                        "00-missao.md": f"---\n{shadow}missao: {mission}\nbranch: branch\naprovacao:\n---\n",
                    }}
                    with self.assertRaisesRegex(ValueError, "one blank approval"):
                        module["materialize"](root, mission, state)
                self.assertFalse((root / "docs").exists())

    def test_pending_question_survives_relay_and_resume_uses_exact_id(self):
        with tempfile.TemporaryDirectory() as scratch:
            temp = Path(scratch)
            kit = temp / "kit"
            repo = temp / "target"
            repo.mkdir()
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            (repo / ".sdd").mkdir()
            (repo / ".sdd/config.sh").write_text("HANDOFF_DIR=docs/handoffs\n")
            (kit / "bin").mkdir(parents=True)
            for name in ("templates", "agents", "tests"):
                (kit / name).symlink_to(ROOT / name)
            (kit / "bin/sdd-plan-codex").write_bytes((ROOT / "bin/sdd-plan-codex").read_bytes())
            (kit / "bin/sdd-plan-codex").chmod(0o755)
            (kit / "bin/sdd-coordination.py").symlink_to(ROOT / "bin/sdd-coordination.py")
            subprocess.run(["git", "symbolic-ref", "HEAD", "refs/heads/work"], cwd=repo, check=True)
            adapter = kit / "bin/sdd-codex"
            adapter.write_text(
                "#!/usr/bin/env python3\n"
                "import json, sys\n"
                "from pathlib import Path\n"
                "sid = " + repr(SESSION) + "\n"
                "with Path('calls').open('a') as out:\n"
                "    out.write(json.dumps([sys.argv[1:],sys.stdin.read()])+'\\n')\n"
                "print(json.dumps(dict(type='system',session_id=sid)),flush=True)\n"
                "question = 'Question two?' if '--resume' in sys.argv else 'Question one?'\n"
                "with Path('calls').open() as log: latest = json.loads(list(log)[-1])[1]\n"
                "if latest == 'Write the plan':\n"
                "    question = json.dumps({\n"
                "      '00-missao.md': '---\\nmissao: 20261124-test\\nbranch: work\\naprovacao:\\n---\\n# Mission\\n\\n## Decisoes do grill\\n   - answer: (recommended)\\n   - answer: (other: Write the plan)\\n',\n"
                "      '01-plano.md': '# Plan\\n',\n"
                "      'checkpoint.md': '| ID | Incremento | Check (comando → esperado) | Status | Commit |\\n|---|---|---|---|---|\\n| I1 | Change | `false` → 0 | pending | — |\\n',\n"
                "    })\n"
                "print(json.dumps(dict(type='result',is_error=False,result=question)))\n"
            )
            adapter.chmod(0o755)
            mission = "20261124-test"
            relay = kit / "bin/sdd-plan-codex"
            env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}

            def call(*args, good=True):
                result = subprocess.run([str(relay), *args], cwd=repo, env=env,
                                        capture_output=True, text=True)
                if good:
                    self.assertEqual(result.returncode, 0, result.stderr)
                else:
                    self.assertNotEqual(result.returncode, 0, result.stdout)
                return result.stdout

            started = call("start", mission, "A change")
            self.assertIn("Question one?", started)
            question = started.splitlines()[0].split()[-1]
            self.assertIn("Question one?", call("status", mission))
            call("start", mission, "Duplicate", good=False)
            call("answer", mission, question, "Use A")
            call("answer", mission, question, "Use A", good=False)
            self.assertIn("Question two?", call("status", mission))
            calls = [json.loads(line) for line in (repo / "calls").read_text().splitlines()]
            self.assertEqual(len(calls), 2)
            self.assertIn("gpt-6.2-astra", calls[0][0])
            self.assertIn("--read-only", calls[0][0])
            self.assertEqual(calls[1][0][-2:], ["--resume", SESSION])
            self.assertEqual(calls[1][1], "Use A")
            second = call("status", mission).splitlines()[0].split()[-1]
            self.assertIn("draft", call("answer", mission, second, "Write the plan"))
            call("finish", mission)
            dest = repo / "docs/handoffs" / mission
            self.assertEqual(sorted(file.name for file in dest.iterdir()),
                             ["00-missao.md", "01-plano.md", "checkpoint.md"])
            self.assertIn("aprovacao:\n", (dest / "00-missao.md").read_text())
            call("finish", mission, good=False)

            worker = kit / "bin/sdd-worker"
            worker.write_text(
                "#!/usr/bin/env python3\n"
                "import sys\n"
                "from pathlib import Path\n"
                "assert sys.argv[1] in ('allows', 'budget')\n"
                "assert len(sys.argv) == 3 or sys.argv[3:] == ['plan', '--lot', 'L1']\n"
                "sys.exit(1 if Path('revoked').exists() else 0)\n"
            )
            worker.chmod(0o755)
            campaign = repo / "docs/campaigns/20261124-pilot"
            campaign.mkdir(parents=True)
            delegated = "20261124-delegated"
            started = call("start", delegated, "Another change", "--campaign", str(campaign), "--lot", "L1")
            question = started.splitlines()[0].split()[-1]
            (repo / "revoked").touch()
            count = len((repo / "calls").read_text().splitlines())
            call("answer", delegated, question, "Use A", good=False)
            self.assertEqual(len((repo / "calls").read_text().splitlines()), count)
            self.assertIn("Question one?", call("status", delegated))


if __name__ == "__main__":
    unittest.main()
