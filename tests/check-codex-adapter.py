#!/usr/bin/env python3
"""Exercise the adapter against deterministic native Codex event fixtures."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

ADAPTER = Path(__file__).resolve().parents[1] / "bin" / "sdd-codex"
THREAD = "019aebba-bc11-73b0-8080-7c8fbffcd884"
START = {"type": "thread.started", "thread_id": THREAD}
TURN = {"type": "turn.started"}
USAGE = {"input_tokens": 22474, "cached_input_tokens": 12672, "output_tokens": 5}
COMPLETE = {"type": "turn.completed", "usage": USAGE}
MESSAGE = {"type": "item.completed", "item": {"type": "agent_message", "id": "item_1", "text": "SDD_OK"}}

FAKE = """#!/usr/bin/env python3
import json, os, pathlib, sys
args = sys.argv[1:]
if args == ['--version']:
    print('codex-cli 0.test')
elif args in (['exec', '--help'], ['exec', 'resume', '--help']):
    print('--json --strict-config --ignore-user-config --ignore-rules')
elif args == ['login', 'status']:
    print('Logged in using ChatGPT')
elif 'sandbox' in args:
    sys.exit(int(os.environ.get('FAKE_SANDBOX_RC', '0')))
else:
    pathlib.Path(os.environ['FAKE_ARGS']).write_text(json.dumps([args, sys.stdin.read(), os.environ['GIT_REFLOG_ACTION']]))
    print(os.environ['FAKE_STREAM'], flush=True)
    sys.exit(int(os.environ['FAKE_RC']))
"""


class AdapterTests(unittest.TestCase):
    def invoke(self, *args, events=None, rc=0, sandbox_rc=0, linked=False, remote=None):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            repo = base / "repo"
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            if linked:
                subprocess.run(["git", "-C", str(repo), "-c", "user.name=Fixture",
                                "-c", "user.email=fixture@example.invalid",
                                "commit", "-qm", "seed", "--allow-empty"], check=True)
                branch = base / "linked"
                subprocess.run(["git", "-C", str(repo), "worktree", "add", "-qb", "mission", str(branch)], check=True)
                repo = branch
            if remote:
                subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", remote], check=True)
            fake = base / "codex"
            captured = base / "args.json"
            fake.write_text(FAKE)
            fake.chmod(0o755)
            env = {
                **os.environ,
                "PATH": f"{temporary}:{os.environ['PATH']}",
                "FAKE_ARGS": str(captured),
                "FAKE_STREAM": "\n".join(event if isinstance(event, str) else json.dumps(event)
                                         for event in (events if events is not None else (START, TURN, MESSAGE, COMPLETE))),
                "FAKE_RC": str(rc),
                "FAKE_SANDBOX_RC": str(sandbox_rc),
                "GIT_REFLOG_ACTION": "sdd:fixture",
            }
            result = subprocess.run(
                [str(ADAPTER), *args], text=True, input="fixture prompt\n", env=env,
                cwd=repo, capture_output=True, timeout=15,
            )
            arguments = json.loads(captured.read_text()) if captured.exists() else None
            return result, arguments

    def run_hat(self, *args, model="gpt-6.2-sol", hat="sdd-executor", **kwargs):
        result, native = self.invoke("--model", model, "--effort", "low", "--hat", hat, *args, **kwargs)
        return result.returncode, [json.loads(line) for line in result.stdout.splitlines()], native, result.stderr

    def test_estimate_uses_uncached_input_and_preserves_native_usage(self):
        rc, events, _, err = self.run_hat()
        self.assertEqual(rc, 0, err)
        self.assertEqual(events[0]["session_id"], THREAD)
        self.assertEqual(events[0]["native_event"], START)
        terminal = events[-1]
        self.assertEqual(terminal["type"], "result")
        self.assertEqual(terminal["result"], "SDD_OK")
        self.assertEqual(terminal["num_turns"], 1)
        self.assertEqual(terminal["turn_usage"], [USAGE])
        self.assertEqual(terminal["usage"], {**USAGE, "cache_read_input_tokens": 12672})
        self.assertIsNone(terminal["total_cost_usd"])
        self.assertEqual(terminal["estimated_cost_usd"], 0.0209212)
        self.assertIn("standard", terminal["estimate_basis"]["price_table"])
        self.assertEqual(terminal["estimate_basis"]["source"], "https://developers.openai.com/api/docs/models/gpt-6.2-sol")

    def test_astra_and_multiple_turns_sum_independently(self):
        rc, events, _, err = self.run_hat(model="gpt-6.2-astra", events=[START, TURN, COMPLETE, TURN, MESSAGE, COMPLETE])
        self.assertEqual(rc, 0, err)
        self.assertEqual(events[-1]["num_turns"], 2)
        self.assertEqual(events[-1]["usage"]["input_tokens"], 44948)
        self.assertEqual(events[-1]["estimated_cost_usd"], 0.1673696)

    def test_uncertain_price_inputs_cannot_become_zero_or_fake_precision(self):
        cases = [
            ("unknown-model", USAGE),
            ("gpt-6.2-sol", {**USAGE, "cached_input_tokens": 22475}),
            ("gpt-6.2-sol", {**USAGE, "cached_input_tokens": -1}),
            ("gpt-6.2-sol", {**USAGE, "output_tokens": True}),
            ("gpt-6.2-sol", {**USAGE, "input_tokens": 272001}),
            ("gpt-6.2-sol", {**USAGE, "cache_write_input_tokens": 10}),
            ("gpt-6.2-sol", {**USAGE, "service_tier": "priority"}),
            ("gpt-6.2-sol", {"input_tokens": 10, "output_tokens": 1}),
        ]
        for model, usage in cases:
            with self.subTest(model=model, usage=usage):
                rc, events, _, err = self.run_hat(model=model, events=[START, TURN, {**COMPLETE, "usage": usage}])
                self.assertEqual(rc, 0, err)
                self.assertIsNone(events[-1]["total_cost_usd"])
                self.assertIsNone(events[-1]["estimated_cost_usd"])
                self.assertTrue(events[-1]["estimate_basis"]["unknown_reason"])

    def test_turn_failure_or_truncation_cannot_masquerade_as_success(self):
        cases = [
            ([START, TURN, {"type": "turn.failed", "error": {"message": "auth expired"}}], 0, "auth expired"),
            ([START, TURN, "{broken"], 0, "malformed"),
            ([START, TURN], 0, "completed"),
            ([START, TURN, COMPLETE], 8, "8"),
            ([TURN, COMPLETE], 0, "thread"),
            ([START, TURN, COMPLETE, TURN], 0, "completed"),
        ]
        for events, child_rc, reason in cases:
            with self.subTest(reason=reason):
                rc, output, _, _ = self.run_hat(events=events, rc=child_rc)
                self.assertNotEqual(rc, 0)
                self.assertIs(output[-1]["is_error"], True)
                self.assertIn(reason, output[-1]["result"])
                self.assertIsNone(output[-1]["estimated_cost_usd"])

    def test_retry_keeps_the_native_id_and_policy(self):
        rc, events, native, err = self.run_hat("--resume", THREAD)
        self.assertEqual(rc, 0, err)
        args, prompt, label = native
        self.assertEqual(args[-2:], [THREAD, "-"])
        self.assertEqual(args[:2], ["exec", "resume"])
        self.assertEqual(prompt, "fixture prompt\n")
        self.assertEqual(label, "sdd:fixture")
        self.assertEqual(events[-1]["session_id"], THREAD)
        other = {**START, "thread_id": "019aebba-bc11-73b0-8080-7c8fbffcd881"}
        rc, events, _, _ = self.run_hat("--resume", THREAD, events=[other, TURN, COMPLETE])
        self.assertNotEqual(rc, 0)
        self.assertIn("thread", events[-1]["result"])

    def test_policy_disables_outside_tools_and_escalation(self):
        for hat, read_only, sandbox, network in [
            ("sdd-executor", False, "sdd-workspace", "false"),
            ("sdd-publisher", False, "sdd-workspace", "false"),
            ("sdd-planner", True, ":read-only", "false"),
        ]:
            with self.subTest(hat=hat):
                flags = ("--read-only",) if read_only else ()
                rc, events, native, err = self.run_hat(*flags, hat=hat)
                self.assertEqual(rc, 0, err)
                self.assertEqual(events[0]["mcp_servers"], [])
                args, _, _ = native
                self.assertIn("--ignore-user-config", args)
                self.assertIn("--ignore-rules", args)
                for setting in [
                    'approval_policy="never"', f'default_permissions="{sandbox}"', 'mcp_servers={}',
                    'features.apps=false', 'features.hooks=false', 'features.plugins=false',
                    'features.multi_agent=false', 'web_search="disabled"',
                ]:
                    self.assertIn(setting, args)
                self.assertFalse(any(flag.startswith("--dangerously") for flag in args))
                if not read_only:
                    profile = next(arg for arg in args if arg.startswith("permissions="))
                    self.assertIn(f"enabled = {network}", profile)
                    self.assertIn('/repo/.git/config" = "read"', profile)
                    self.assertIn('/repo/.git/hooks" = "read"', profile)

    def test_linked_worktree_profile_does_not_unlock_the_shared_git_directory(self):
        rc, _, (args, _, _), err = self.run_hat(linked=True)
        self.assertEqual(rc, 0, err)
        profile = next(arg for arg in args if arg.startswith("permissions="))
        self.assertIn('/repo/.git/worktrees/linked" = "write"', profile)
        self.assertIn('/repo/.git/objects" = "write"', profile)
        self.assertIn('/repo/.git/refs/heads" = "write"', profile)
        self.assertIn('/repo/.git/objects/info" = "read"', profile)
        self.assertIn('/repo/.git/worktrees/linked/commondir" = "read"', profile)
        self.assertIn('/repo/.git" = "read"', profile)
        self.assertNotIn('/repo/.git" = "write"', profile)
        self.assertNotIn('/repo/.git/config" = "write"', profile)
        self.assertNotIn('/repo/.git/hooks" = "write"', profile)

    def test_publisher_draft_has_the_executor_offline_boundary(self):
        profiles = []
        for hat in ("sdd-executor", "sdd-publisher"):
            rc, _, (args, _, _), err = self.run_hat(hat=hat, linked=True)
            self.assertEqual(rc, 0, err)
            self.assertIn("features.network_proxy=false", args)
            self.assertFalse(any(arg.startswith("features.network_proxy.domains=") for arg in args))
            profile = tomllib.loads(next(arg for arg in args if arg.startswith("permissions=")))
            workspace = profile["permissions"]["sdd-workspace"]
            self.assertEqual(workspace["network"], {"enabled": False})
            filesystem = {path.split("/repo/.git", 1)[1]: access
                          for path, access in workspace["filesystem"].items()}
            self.assertNotIn("/refs/remotes", filesystem)
            profiles.append(filesystem)
        self.assertEqual(*profiles)

    def test_ticket_network_is_limited_to_jira_cloud(self):
        rc, _, (args, _, _), err = self.run_hat(hat="sdd-ticket")
        self.assertEqual(rc, 0, err)
        profile = next(arg for arg in args if arg.startswith("permissions="))
        self.assertIn("enabled = true", profile)
        self.assertIn('features.network_proxy.enabled=true', args)
        domains = next(arg for arg in args if arg.startswith('features.network_proxy.domains='))
        self.assertIn('"*.atlassian.net" = "allow"', domains)
        self.assertNotIn('"*" = "allow"', domains)
        self.assertNotIn('github', domains)

    def test_qa_allowlists_one_exact_app_host(self):
        for host in ["localhost", "127.0.0.1", "::1", "staging.example.invalid"]:
            with self.subTest(host=host):
                rc, _, native, err = self.run_hat("--qa-host", host, hat="sdd-qa")
                self.assertEqual(rc, 0, err)
                args, _, _ = native
                self.assertIn(f'features.network_proxy.domains={{"{host}" = "allow"}}', args)
                self.assertIn('features.network_proxy.allow_upstream_proxy=false', args)

    def test_qa_host_refuses_globs_urls_ports_and_git_publication_hosts(self):
        for host in ["*", "*.example.invalid", "http://localhost", "localhost:9911",
                     "api.github.com", "gitlab.com", "github.com."]:
            with self.subTest(host=host):
                proc, native = self.invoke("--model", "gpt-6.2-sol", "--hat", "sdd-qa", "--qa-host", host)
                self.assertNotEqual(proc.returncode, 0)
                self.assertIsNone(native)
        proc, native = self.invoke("--model", "gpt-6.2-sol", "--hat", "sdd-executor", "--qa-host", "localhost")
        self.assertNotEqual(proc.returncode, 0)
        self.assertIsNone(native)

    def test_qa_rejects_the_self_hosted_checkout_git_remote(self):
        for url in ["git@ci.example.invalid:team/repo.git", "https://ci.example.invalid/team/repo.git"]:
            with self.subTest(url=url):
                proc, native = self.invoke("--model", "gpt-6.2-sol", "--hat", "sdd-qa",
                                           "--qa-host", "ci.example.invalid", remote=url)
                self.assertNotEqual(proc.returncode, 0)
                self.assertIsNone(native)
                self.assertIn("Git remote", proc.stdout)
                self.assertNotIn(url, proc.stdout + proc.stderr)

    def test_tools_are_emitted_as_runner_evidence(self):
        item = {"type": "command_execution", "id": "item_0", "command": "printf SDD_OK",
                "aggregated_output": "", "exit_code": None, "status": "in_progress"}
        start = {"type": "item.started", "item": item}
        finish = {"type": "item.completed", "item": {**item, "aggregated_output": "SDD_OK",
                                                   "exit_code": 0, "status": "completed"}}
        rc, events, _, err = self.run_hat(events=[START, TURN, start, finish, MESSAGE, COMPLETE])
        self.assertEqual(rc, 0, err)
        self.assertEqual(events[2]["message"]["content"][0]["name"], "Bash")
        self.assertEqual(events[2]["message"]["content"][0]["input"]["command"], item["command"])
        self.assertEqual(events[3]["message"]["content"][0]["content"], "SDD_OK")
        self.assertEqual(events[3]["native_event"], finish)

    def test_mcp_tool_observed_in_native_stream_cannot_pass_boundary(self):
        mcp = {"type": "item.completed", "item": {"type": "mcp_tool_call", "id": "item_0",
                                                "server": "inherited", "tool": "read"}}
        rc, events, _, _ = self.run_hat(events=[START, TURN, mcp, COMPLETE])
        self.assertNotEqual(rc, 0)
        self.assertIn("MCP", events[-1]["result"])

    def test_preflight_never_starts_a_model_and_refuses_unusable_sandbox(self):
        result, native = self.invoke("--preflight")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsNone(native)
        result, native = self.invoke("--preflight", sandbox_rc=33)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("sandbox", result.stderr)
        self.assertIsNone(native)


if __name__ == "__main__":
    unittest.main()
