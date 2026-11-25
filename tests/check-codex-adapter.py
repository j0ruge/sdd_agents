#!/usr/bin/env python3
"""Exercise the adapter against deterministic native Codex event fixtures."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import tomllib
import unittest
from contextlib import ExitStack
from unittest.mock import patch

ADAPTER = Path(__file__).resolve().parents[1] / "bin" / "sdd-codex"
THREAD = "019aebba-bc11-73b0-8080-7c8fbffcd884"
START = {"type": "thread.started", "thread_id": THREAD}
TURN = {"type": "turn.started"}
USAGE = {"input_tokens": 22474, "cached_input_tokens": 12672, "output_tokens": 5}
COMPLETE = {"type": "turn.completed", "usage": USAGE}
MESSAGE = {"type": "item.completed", "item": {"type": "agent_message", "id": "item_1", "text": "SDD_OK"}}

FAKE = """#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys, tomllib
args = sys.argv[1:]
if args == ['--version']:
    print('codex-cli 0.test')
elif args in (['exec', '--help'], ['exec', 'resume', '--help']):
    print('--json --strict-config --ignore-user-config --ignore-rules')
elif args == ['login', 'status']:
    print('Logged in using ChatGPT')
elif 'sandbox' in args:
    if any(value.startswith('GIT_DIR=') for value in args):
        if os.environ.get('SDD_TEST_NATIVE_CODEX'):
            real = os.environ['SDD_TEST_NATIVE_CODEX']
            os.execv(real, [real, *args])
        command = args[args.index('--') + 1:]
        os.execv(command[0], command)
    if os.environ.get('FAKE_EXEC_SANDBOX') == '1':
        pathlib.Path(os.environ['FAKE_ARGS']).write_text(json.dumps(args))
        if os.environ.get('SDD_TEST_NATIVE_CODEX'):
            real = os.environ['SDD_TEST_NATIVE_CODEX']
            os.execv(real, [real, *args])
        command = args[args.index('--') + 1:]
        os.execv(command[0], command)
    sys.exit(int(os.environ.get('FAKE_SANDBOX_RC', '0')))
else:
    pathlib.Path(os.environ['FAKE_ARGS']).write_text(json.dumps([args, sys.stdin.read(), os.environ['GIT_REFLOG_ACTION']]))
    if 'FAKE_MODEL_COMMIT' in os.environ:
        setting = next((v for v in args if v.startswith('shell_environment_policy.set=')), None)
        env = os.environ.copy()
        if setting:
            env.update(tomllib.loads(setting)['shell_environment_policy']['set'])
        pathlib.Path('proof.txt').write_text('proof')
        amend = ['--amend'] if os.environ['FAKE_MODEL_COMMIT'] == 'amend' else []
        command = ['bash', '-ec', 'git add --all && git commit -qm proof "$@"', 'bash', *amend]
        if os.environ.get('SDD_TEST_NATIVE_CODEX'):
            real = os.environ['SDD_TEST_NATIVE_CODEX']
            config = [value for i, value in enumerate(args) if args[i - 1] == '-c']
            command = [real, *(value for setting in config for value in ('-c', setting)), 'sandbox', '--', *command]
            env = os.environ.copy()
        subprocess.run(command, env=env, check=True)
        if os.environ['FAKE_MODEL_COMMIT'] == 'concurrent':
            # The fixture's separate checkout owner advances the real branch.
            subprocess.run(['git', 'commit', '--allow-empty', '-qm', 'external'], check=True)
        if os.environ['FAKE_MODEL_COMMIT'] == 'flags':
            subprocess.run(['git', 'update-index', '--assume-unchanged', 'baseline.txt'], check=True)
    print(os.environ['FAKE_STREAM'], flush=True)
    sys.exit(int(os.environ['FAKE_RC']))
"""


class AdapterTests(unittest.TestCase):
    def invoke(self, *args, events=None, rc=0, sandbox_rc=0, linked=False, remote=None,
               execute_sandbox=False, model_commit=False, git_override=False, mission_branch="mission",
               local_ignore=False, staged_gitlink=False):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            git_env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
            repo = base / "repo"
            subprocess.run(["git", "init", "-q", "--initial-branch=trunk", str(repo)], env=git_env, check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "Fixture"], env=git_env, check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "fixture@example.invalid"],
                           env=git_env, check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "seed", "--allow-empty"], env=git_env, check=True)
            if local_ignore:
                (repo / ".git/info/exclude").write_text("local-note.txt\n")
                excludes = base / "extra-ignore"
                excludes.write_text("other-local-note.txt\n")
                subprocess.run(["git", "-C", str(repo), "config", "core.excludesfile", str(excludes)],
                               env=git_env, check=True)
            if linked:
                branch = base / "linked"
                subprocess.run(["git", "-C", str(repo), "worktree", "add", "-qb", mission_branch, str(branch)],
                               env=git_env, check=True)
                repo = branch
            (repo / ".sdd").mkdir()
            if model_commit == "flags":
                (repo / "baseline.txt").write_text("baseline")
                subprocess.run(["git", "add", "baseline.txt"], cwd=repo, env=git_env, check=True)
                subprocess.run(["git", "commit", "-qm", "baseline"], cwd=repo, env=git_env, check=True)
            if staged_gitlink:
                subprocess.run(["git", "config", "diff.ignoreSubmodules", "all"], cwd=repo, env=git_env, check=True)
                head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, env=git_env, text=True).strip()
                subprocess.run(["git", "update-index", "--add", "--cacheinfo", f"160000,{head},module"],
                               cwd=repo, env=git_env, check=True)
            if local_ignore:
                (repo / "local-note.txt").write_text("local")
                (repo / "other-local-note.txt").write_text("other local")
            if remote:
                subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", remote], env=git_env, check=True)
            fake = base / "codex"
            captured = base / "args.json"
            fake.write_text(FAKE)
            fake.chmod(0o755)
            env = {
                **git_env,
                "PATH": f"{temporary}:{os.environ['PATH']}",
                "FAKE_ARGS": str(captured),
                "FAKE_STREAM": "\n".join(event if isinstance(event, str) else json.dumps(event)
                                         for event in (events if events is not None else (START, TURN, MESSAGE, COMPLETE))),
                "FAKE_RC": str(rc),
                "FAKE_SANDBOX_RC": str(sandbox_rc),
                "FAKE_EXEC_SANDBOX": str(int(execute_sandbox)),
                "GIT_REFLOG_ACTION": "sdd:fixture",
            }
            if model_commit:
                env["FAKE_MODEL_COMMIT"] = str(model_commit)
            if git_override:
                (repo / "already-staged.txt").write_text("already staged")
                subprocess.run(["git", "add", "already-staged.txt"], cwd=repo, check=True, env=git_env)
                env["GIT_INDEX_FILE"] = str(base / "other-index")
                subprocess.run(["git", "read-tree", "HEAD"], cwd=repo, check=True, env=env)
            result = subprocess.run(
                [str(ADAPTER), *args], text=True, input="fixture prompt\n", env=env,
                cwd=repo, capture_output=True, timeout=15,
            )
            arguments = json.loads(captured.read_text()) if captured.exists() else None
            if model_commit:
                def git(*args):
                    return subprocess.check_output(["git", *args], cwd=repo, env=git_env, text=True).strip()

                self.final_git = [git("log", "-1", "--format=%s"), git("status", "--short"),
                                  git("log", "-1", "--format=%s", "trunk"),
                                  git("reflog", "-1", "--format=%gs")]
                self.final_tracked = git("ls-files").splitlines()
                self.final_flags = git("ls-files", "-v").splitlines()
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
        fresh_rc, _, (fresh_args, _, _), fresh_error = self.run_hat()
        self.assertEqual(fresh_rc, 0, fresh_error)

        def settings(arguments):
            projects = next(value for value in arguments if value.startswith("projects="))
            root = next(iter(tomllib.loads(projects)["projects"]))
            private = next(value for value in arguments if value.startswith("shell_environment_policy.set="))
            shadow = tomllib.loads(private)["shell_environment_policy"]["set"]["GIT_DIR"]
            return [value.replace(root, "/fixture").replace(shadow, "/shadow") for value in arguments]

        self.assertEqual(settings(args[2:-2]), settings(fresh_args[1:-1]))
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
                    self.assertIn('/repo/.git" = "read"', profile)

    def test_linked_worktree_profile_does_not_unlock_the_shared_git_directory(self):
        rc, _, (args, _, _), err = self.run_hat(linked=True)
        self.assertEqual(rc, 0, err)
        profile = next(arg for arg in args if arg.startswith("permissions="))
        self.assertIn('/repo/.git/worktrees/linked" = "read"', profile)
        self.assertIn('/linked/.sdd" = "read"', profile)
        self.assertIn('/repo" = "read"', profile)
        self.assertNotIn('/repo/.git/refs/heads/mission" = "read"', profile)
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
            project = next(arg for arg in args if arg.startswith("projects="))
            checkout = Path(next(iter(tomllib.loads(project)["projects"])))
            filesystem = {str(Path(path).relative_to(checkout.parent)): access
                          for path, access in workspace["filesystem"].items() if Path(path).is_relative_to(checkout.parent)}
            self.assertNotIn("repo/.git/refs/remotes", filesystem)
            profiles.append(filesystem)
        self.assertEqual(*profiles)

    def test_ticket_network_is_limited_to_jira_cloud(self):
        rc, _, (args, _, _), err = self.run_hat(hat="sdd-ticket")
        self.assertEqual(rc, 0, err)
        profile = next(arg for arg in args if arg.startswith("permissions="))
        self.assertIn("enabled = true", profile)
        self.assertIn('features.network_proxy.enabled=true', args)
        domains = next(arg for arg in args if arg.startswith('features.network_proxy.domains='))
        self.assertEqual(tomllib.loads(domains)["features"]["network_proxy"]["domains"],
                         dict.fromkeys(("*.atlassian.net", "api.atlassian.com",
                                        "auth.atlassian.com", "id.atlassian.com"), "allow"))
        self.assertIn("features.network_proxy.allow_upstream_proxy=false", args)
        self.assertIn('features.network_proxy.mode="full"', args)

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

    def test_qa_rejects_the_same_ipv6_remote_in_both_spellings(self):
        result, native = self.invoke("--model", "gpt-6.2-sol", "--hat", "sdd-qa",
                                     "--qa-host", "::1", remote="https://[0:0:0:0:0:0:0:1]/repo.git")
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(native)
        self.assertIn("Git remote", result.stdout)

    def test_qa_reports_malformed_remote_without_reprinting_it(self):
        result, native = self.invoke("--model", "gpt-6.2-sol", "--hat", "sdd-qa",
                                     "--qa-host", "localhost", remote="https://git-example／invalid/repo.git")
        self.assertNotEqual(result.returncode, 0)
        self.assertIsNone(native)
        self.assertIn("malformed Git remote", result.stdout)
        self.assertNotIn("git-example", result.stdout + result.stderr)

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

    def test_gate_checks_keep_pipefail_and_do_not_get_git_write_access(self):
        positive, _ = self.invoke("--sandbox-check", "true | true", linked=True, execute_sandbox=True)
        self.assertEqual(positive.returncode, 0, positive.stderr)
        negative, args = self.invoke("--sandbox-check", "false | true", linked=True, execute_sandbox=True)
        self.assertEqual(negative.returncode, 1, negative.stderr)
        profile = tomllib.loads(next(arg for arg in args if arg.startswith("permissions=")))
        filesystem = profile["permissions"]["sdd-workspace"]["filesystem"]
        self.assertTrue(all(access == "read" for access in filesystem.values()))

    def test_git_turn_promotes_only_the_mission_tip_and_labels_it(self):
        rc, events, (args, _, _), err = self.run_hat(linked=True, model_commit=True)
        self.assertEqual(rc, 0, (events, err))
        profile = tomllib.loads(next(arg for arg in args if arg.startswith("permissions=")))
        paths = profile["permissions"]["sdd-workspace"]["filesystem"]
        self.assertTrue(all(access == "read" for path, access in paths.items() if "/repo" in path))
        self.assertEqual(self.final_git, ["proof", "", "seed", "sdd:fixture"])

    def test_git_turn_never_promotes_a_failed_provider_turn(self):
        rc, _, _, _ = self.run_hat(linked=True, model_commit=True, rc=91)
        self.assertEqual(rc, 91)
        self.assertEqual(self.final_git[:3], ["seed", "?? proof.txt", "seed"])

    def test_git_turn_refuses_to_rewrite_the_original_tip(self):
        rc, events, _, _ = self.run_hat(linked=True, model_commit="amend")
        self.assertNotEqual(rc, 0)
        self.assertIn("merge-base", events[-1]["result"])
        self.assertEqual(self.final_git[:3], ["seed", "?? proof.txt", "seed"])

    def test_git_turn_preserves_an_external_advance(self):
        rc, events, _, _ = self.run_hat(linked=True, model_commit="concurrent")
        self.assertNotEqual(rc, 0)
        self.assertIn("update-ref", events[-1]["result"])
        self.assertEqual(self.final_git[:3], ["external", "?? proof.txt", "seed"])

    def test_git_turn_ignores_an_inherited_index_override(self):
        rc, events, captured, _ = self.run_hat(linked=True, model_commit=True, git_override=True)
        self.assertNotEqual(rc, 0)
        self.assertIn("staged", events[-1]["result"])
        self.assertIsNone(captured)
        self.assertEqual(self.final_git[:3], ["seed", "A  already-staged.txt", "seed"])

    def test_git_turn_accepts_a_unicode_branch_name(self):
        rc, events, _, _ = self.run_hat(linked=True, model_commit=True, mission_branch="missão")
        self.assertEqual(rc, 0, events)
        self.assertEqual(self.final_git[:3], ["proof", "", "seed"])

    def test_git_turn_respects_local_ignore_rules_when_staging(self):
        rc, events, _, _ = self.run_hat(linked=True, model_commit=True, local_ignore=True)
        self.assertEqual(rc, 0, events)
        self.assertEqual(self.final_tracked, ["proof.txt"])

    def test_git_turn_preserves_index_flags_changed_while_the_model_runs(self):
        rc, events, _, _ = self.run_hat(linked=True, model_commit="flags")
        self.assertNotEqual(rc, 0)
        self.assertIn("assume-unchanged", events[-1]["result"])
        self.assertEqual(self.final_git[0], "baseline")
        self.assertIn("h baseline.txt", self.final_flags)

    def test_git_turn_refuses_staged_gitlinks_even_when_the_diff_ignores_submodules(self):
        rc, events, captured, _ = self.run_hat(linked=True, model_commit=True, staged_gitlink=True)
        self.assertNotEqual(rc, 0)
        self.assertIsNone(captured)
        self.assertIn("staged", events[-1]["result"])
        self.assertIn("module", self.final_tracked)

    @unittest.skipUnless(os.environ.get("SDD_TEST_NATIVE_CODEX"), "requires the opt-in native Codex CLI")
    def test_gate_native_sandbox_denies_git_metadata_writes(self):
        command = ('touch permitted-worktree-file && '
                   'git_dir=$(git rev-parse --absolute-git-dir) && '
                   'test -f "$git_dir/HEAD" && '
                   '! touch "$git_dir/sandbox-permission-check" && '
                   'test ! -e "$git_dir/sandbox-permission-check"')
        result, _ = self.invoke("--sandbox-check", command, linked=True, execute_sandbox=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_git_handoff_recovers_a_failed_installation_after_the_branch_advances(self):
        handoff_type = runpy.run_path(str(ADAPTER))["GitIndexHandoff"]
        with tempfile.TemporaryDirectory() as directory:
            checkout = Path(directory)
            env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}

            def git(*args):
                return subprocess.check_output(["git", *args], cwd=checkout, env=env, text=True).strip()

            git("init", "-q", "-b", "mission")
            git("config", "user.name", "Fixture")
            git("config", "user.email", "fixture@example.invalid")
            git("commit", "-qm", "seed", "--allow-empty")
            old = git("rev-parse", "HEAD")
            (checkout / "proof.txt").write_text("proof")
            git("add", "proof.txt")
            git("commit", "-qm", "proof")
            new = git("rev-parse", "HEAD")
            git("reset", "--mixed", old)
            replace = Path.replace

            def fail_index_lock_rename(source, destination):
                if source.name == "index.lock":
                    raise OSError("simulated interrupted index installation")
                return replace(source, destination)

            with ExitStack() as stack:
                handoff = handoff_type(stack, checkout)
                with patch.object(Path, "replace", fail_index_lock_rename):
                    with self.assertRaisesRegex(OSError, "simulated interrupted"):
                        handoff.advance("refs/heads/mission", old, new, lambda: None)
            self.assertEqual(git("rev-parse", "HEAD"), new)
            self.assertTrue(handoff.intent.is_file())
            self.assertTrue(handoff.lock.is_file())
            with ExitStack() as stack:
                handoff_type(stack, checkout)
            self.assertEqual(git("status", "--short"), "")
            self.assertFalse(handoff.intent.exists())
            self.assertFalse(handoff.lock.exists())

    def test_git_handoff_reconciles_a_failed_result_after_update_ref_applied(self):
        handoff_type = runpy.run_path(str(ADAPTER))["GitIndexHandoff"]
        with tempfile.TemporaryDirectory() as directory, ExitStack() as stack:
            checkout = Path(directory)
            env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}

            def git(*args):
                return subprocess.check_output(["git", *args], cwd=checkout, env=env, text=True).strip()

            git("init", "-q", "-b", "mission")
            git("config", "user.name", "Fixture")
            git("config", "user.email", "fixture@example.invalid")
            git("commit", "-qm", "seed", "--allow-empty")
            old = git("rev-parse", "HEAD")
            (checkout / "proof.txt").write_text("proof")
            git("add", "proof.txt")
            git("commit", "-qm", "proof")
            new = git("rev-parse", "HEAD")
            git("reset", "--mixed", old)
            handoff = handoff_type(stack, checkout)
            real_git = handoff.git

            def lost_status(*args, **kwargs):
                value = real_git(*args, **kwargs)
                if args[0] == "update-ref":
                    raise ValueError("simulated lost update-ref status")
                return value

            with patch.object(handoff, "git", lost_status):
                handoff.advance("refs/heads/mission", old, new, lambda: None)
            self.assertEqual(git("rev-parse", "HEAD"), new)
            self.assertEqual(git("status", "--short"), "")
            self.assertFalse(handoff.intent.exists())
            self.assertFalse(handoff.lock.exists())


            # Another owner may already have installed the candidate ref and then staged work.
            (checkout / "staged.txt").write_text("operator work")
            git("add", "staged.txt")

            def reject_index():
                raise ValueError("operator has staged work")

            with self.assertRaisesRegex(ValueError, "operator has staged work"):
                handoff.advance("refs/heads/mission", old, new, reject_index)
            self.assertEqual(git("status", "--short"), "A  staged.txt")
            self.assertFalse(handoff.intent.exists())
            self.assertFalse(handoff.lock.exists())


if __name__ == "__main__":
    unittest.main()
