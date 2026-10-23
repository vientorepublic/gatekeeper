"""Exercise rollout ordering and failure boundaries without a server or Docker."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("deploy-backend.sh").resolve()
SHA = "a" * 40
BACKEND_SHA = "b" * 40
MOCK = r'''
import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["MOCK_LOG"], "a") as log:
    log.write(json.dumps([name, *args]) + "\n")
if name == "git":
    child = False
    while args[:1] in (["-c"], ["-C"]):
        if args[0] == "-C":
            child = args[1].endswith("gatekeeper-backend")
        args = args[2:]
    if args[:1] == ["symbolic-ref"]:
        print(os.environ.get("MOCK_BRANCH", "main"))
    elif args[:1] == ["status"]:
        print(os.environ.get("MOCK_CHILD_DIRTY" if child else "MOCK_DIRTY", ""))
    elif args[:1] == ["rev-parse"]:
        ref = args[1]
        if child or ref == "HEAD:gatekeeper-backend":
            print("b" * 40)
        elif ref == "FETCH_HEAD":
            print(os.environ.get("MOCK_REMOTE_SHA", "a" * 40))
        else:
            print("a" * 40)
    elif args[:1] == ["merge"] and os.environ.get("MOCK_DIVERGED"):
        sys.exit(1)
elif name == "docker":
    if args[:1] == ["inspect"]:
        print(os.environ.get("MOCK_COMPOSE_PROJECT", "gatekeeper"))
    if "build" in args and os.environ.get("MOCK_BUILD_FAIL"):
        sys.exit(1)
    if "up" in args and os.environ.get("MOCK_UP_FAIL"):
        sys.exit(1)
elif name == "curl" and os.environ.get("MOCK_HEALTH_FAIL"):
    sys.exit(1)
'''


class DeploymentTests(unittest.TestCase):
    def run_deploy(self, sha=SHA, **overrides):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            project = root / overrides.pop("MOCK_PROJECT_PATH", "Gatekeeper")
            (project / "gatekeeper-backend/.git").mkdir(parents=True)
            (project / ".git").mkdir()
            (project / "docker-compose.yml").touch()
            if overrides.pop("MOCK_AMBIGUOUS", ""):
                other = root / "projects/gatekeeper"
                (other / ".git").mkdir(parents=True)
                (other / "docker-compose.yml").touch()
            binary_dir = root / "bin"
            binary_dir.mkdir()
            for name in ("git", "docker", "curl", "flock"):
                executable = binary_dir / name
                executable.write_text(f"#!{sys.executable}\n{MOCK}")
                executable.chmod(0o755)
            log = root / "commands.jsonl"
            env = {
                **os.environ,
                "HOME": str(root),
                "PATH": f"{binary_dir}{os.pathsep}{os.environ['PATH']}",
                "MOCK_LOG": str(log),
                **overrides,
            }
            result = subprocess.run(
                ["bash", str(SCRIPT), sha], env=env, capture_output=True, text=True
            )
            commands = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            return result, commands

    def test_success_builds_before_replacing_only_backend(self):
        result, commands = self.run_deploy()
        self.assertEqual(result.returncode, 0, result.stderr)
        checkout = next(command for command in commands if "checkout" in command)
        self.assertEqual(checkout[-2:], ["--detach", SHA])
        self.assertTrue(all("--recurse-submodules=no" in command for command in commands if "fetch" in command))
        update = next(command for command in commands if "submodule" in command)
        self.assertEqual(update[-6:], ["submodule", "update", "--init", "--recursive", "--", "gatekeeper-backend"])
        build = next(command for command in commands if command[0] == "docker" and "build" in command)
        up = next(command for command in commands if command[0] == "docker" and "up" in command)
        self.assertEqual(build[1:4], ["compose", "--project-name", "gatekeeper"])
        self.assertEqual(up[-7:], ["up", "--detach", "--no-deps", "--wait", "--wait-timeout", "120", "backend"])
        self.assertLess(commands.index(build), commands.index(up))
        self.assertEqual(commands[-1][0], "curl")
        self.assertIn(BACKEND_SHA, result.stdout)

    def test_invalid_sha_never_runs_commands(self):
        result, commands = self.run_deploy(sha="main; unexpected-command")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(commands, [])

    def test_ephemeral_fetch_credentials_do_not_enter_logs_or_persist(self):
        result, commands = self.run_deploy(
            GATEKEEPER_FETCH_TOKEN="synthetic-ci-token",
            GATEKEEPER_BACKEND_READ_KEY="synthetic-private-key",
            GATEKEEPER_GITHUB_HOST_KEYS="github.com ssh-ed25519 synthetic-public-key",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        output = result.stdout + result.stderr + json.dumps(commands)
        self.assertNotIn("synthetic-ci-token", output)
        self.assertNotIn("synthetic-private-key", output)
        ssh_option = next(arg for command in commands for arg in command if arg.startswith("core.sshCommand="))
        self.assertTrue(all("--recurse-submodules=no" in command for command in commands if "fetch" in command))
        key_path = ssh_option.split(" -i ")[1].split(" ")[0]
        self.assertFalse(Path(key_path).exists())

    def test_backend_key_requires_verified_host_keys(self):
        result, commands = self.run_deploy(GATEKEEPER_BACKEND_READ_KEY="synthetic-private-key")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(command[0] == "docker" for command in commands))

    def test_locates_unique_checkout_with_different_case_and_parent(self):
        result, _ = self.run_deploy(MOCK_PROJECT_PATH="projects/GateKeeper")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("projects/GateKeeper", result.stdout)

    def test_ambiguous_checkouts_never_fetch_or_deploy(self):
        result, commands = self.run_deploy(MOCK_PROJECT_PATH="work/GateKeeper", MOCK_AMBIGUOUS="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(command[0] in ("git", "docker") for command in commands))

    def test_missing_checkout_reports_matching_directories_without_fetch(self):
        result, commands = self.run_deploy(MOCK_PROJECT_PATH="gatekeeper-unrelated")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("gatekeeper-unrelated", result.stderr)
        self.assertFalse(any(command[0] in ("git", "docker") for command in commands))

    def test_superseded_push_does_not_change_checkout_or_service(self):
        result, commands = self.run_deploy(MOCK_REMOTE_SHA="c" * 40)
        self.assertEqual(result.returncode, 0)
        self.assertFalse(any(command[0] == "docker" or "merge" in command for command in commands))

    def test_foreign_branch_and_dirty_checkouts_stop_before_fetch(self):
        for overrides in (
            {"MOCK_BRANCH": "dev"},
            {"MOCK_DIRTY": " M docker-compose.yml"},
            {"MOCK_CHILD_DIRTY": "?? local-file"},
        ):
            with self.subTest(overrides=overrides):
                result, commands = self.run_deploy(**overrides)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(any(command[0] == "docker" or command[1:2] == ["fetch"] for command in commands))

    def test_operator_gitlinks_are_preserved_without_a_primary_merge(self):
        result, commands = self.run_deploy(MOCK_DIVERGED="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any("merge" in command or "reset" in command for command in commands))

    def test_reuses_existing_compose_project_and_refuses_unmanaged_container(self):
        result, commands = self.run_deploy(MOCK_COMPOSE_PROJECT="existing-gateway")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(all("existing-gateway" in command for command in commands if "compose" in command))
        result, commands = self.run_deploy(MOCK_COMPOSE_PROJECT="<no value>")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any("up" in command for command in commands))

    def test_real_local_clone_preserves_primary_staged_gitlinks(self):
        real_git = shutil.which("git")
        self.assertIsNotNone(real_git)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            primary = root / "primary"
            primary.mkdir()
            env = {
                **os.environ,
                "GIT_CONFIG_GLOBAL": os.devnull,
                "GIT_CONFIG_NOSYSTEM": "1",
                "GIT_AUTHOR_NAME": "Fixture",
                "GIT_AUTHOR_EMAIL": "fixture@example.invalid",
                "GIT_COMMITTER_NAME": "Fixture",
                "GIT_COMMITTER_EMAIL": "fixture@example.invalid",
            }

            def git(*args, input=None):
                return subprocess.run(
                    [real_git, *args], cwd=primary, env=env, input=input,
                    capture_output=True, text=True, check=True,
                ).stdout.strip()

            git("init", "--quiet", "--initial-branch=main")
            tree = git("mktree", input="")
            base = git("commit-tree", tree, "-m", "Base fixture")
            target = git("commit-tree", tree, "-p", base, "-m", "Release fixture")
            git("update-ref", "refs/heads/main", base)
            git("update-ref", "refs/remotes/origin/main", target)
            git("read-tree", base)
            git("update-index", "--add", "--cacheinfo", f"160000,{base},gatekeeper-backend")
            index = (primary / ".git/index").read_bytes()
            release = root / "release"
            git("clone", "--no-hardlinks", "--no-checkout", str(primary), str(release))
            git("-c", "submodule.recurse=false", "-C", str(release), "checkout", "--detach", target)
            self.assertEqual(git("-C", str(release), "rev-parse", "HEAD"), target)
            self.assertEqual(git("rev-parse", "HEAD"), base)
            self.assertEqual((primary / ".git/index").read_bytes(), index)

    def test_failed_build_leaves_running_service_untouched(self):
        result, commands = self.run_deploy(MOCK_BUILD_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any("up" in command for command in commands))

    def test_unhealthy_container_and_failed_http_probe_fail_deployment(self):
        for overrides in ({"MOCK_UP_FAIL": "1"}, {"MOCK_HEALTH_FAIL": "1"}):
            with self.subTest(overrides=overrides):
                result, _ = self.run_deploy(**overrides)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Deployed meta", result.stdout)


if __name__ == "__main__":
    unittest.main()
