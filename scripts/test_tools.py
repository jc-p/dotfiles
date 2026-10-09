"""工具入口的离线验证；仅操作临时项目，不构建、不传输、不连接远端。"""

from pathlib import Path
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]
TOOLS = REPOSITORY / "dot_local/bin"


class ToolTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory(prefix="dotfiles-tools-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.binaries = self.root / "bin"
        self.project = self.root / "project"
        self.binaries.mkdir()
        self.project.mkdir()
        for name in ["gx", "sx", "rx", "omc-build"]:
            (self.binaries / name).symlink_to(TOOLS / ("executable_" + name))
        self.environment = dict(
            os.environ, PATH=str(self.binaries) + os.pathsep + "/opt/homebrew/bin" + os.pathsep + os.environ["PATH"],
            GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1", GIT_PAGER="cat", PAGER="cat",
            RIPGREP_CONFIG_PATH=os.devnull, FZF_DEFAULT_OPTS="--filter=fixture", MISE_OFFLINE="1", MISE_AUTO_INSTALL="0",
        )
        self.editor_log = self.root / "editor.json"
        editor = self.binaries / "fixture-editor.py"
        editor.write_text("import json, os, sys\nfrom pathlib import Path\n"
                          "Path(os.environ['DOTFILES_EDITOR_LOG']).write_text(json.dumps(sys.argv[1:]))\n")
        self.environment["EDITOR"] = f"{shlex.quote(sys.executable)} {shlex.quote(str(editor))} 'label space'"
        self.environment["DOTFILES_EDITOR_LOG"] = str(self.editor_log)

    def run_tool(self, *arguments: str, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(arguments, cwd=self.project, env=self.environment, input=input_text,
                              capture_output=True, text=True, timeout=15, check=False)

    def git(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        result = self.run_tool("git", *arguments)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def git_fixture(self) -> Path:
        self.git("init", "--quiet")
        path = self.project / "fixture space.txt"
        path.write_text("before\n")
        self.git("add", "--", path.name)
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                 "commit", "--quiet", "-m", "test: 初始化临时仓库")
        return path

    def test_help_without_project_or_remote_access(self) -> None:
        for name in ["gx", "sx", "rx", "omc-build"]:
            with self.subTest(tool=name):
                result = self.run_tool(name, "--help")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(result.stdout or result.stderr)
        for command in ["show", "diff", "stash", "co"]:
            result = self.run_tool("gx", command, "--help")
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_files_keep_spaces_and_colons(self) -> None:
        name = "fixture space:part.txt"
        (self.project / name).write_text("sample\n")
        result = self.run_tool("sx", "files")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), name)

    def test_files_stdin_keeps_existing_ff_contract(self) -> None:
        result = self.run_tool("sx", "files", "--stdin", input_text="fixture space.txt\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "fixture space.txt\n")

    def test_content_preserves_path_and_editor_arguments_without_shell_execution(self) -> None:
        name = "fixture space:quote'$(touch owned).txt"
        (self.project / name).write_text("before\nneedle-fixture\n")
        result = self.run_tool("sx", "grep", "needle-fixture", name)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.editor_log.read_text()), ["label space", "+2", name])
        self.assertFalse((self.project / "owned").exists())

    def test_content_forwards_rg_options_and_prints_location(self) -> None:
        (self.project / "fixture.ts").write_text("needle-fixture\n")
        (self.project / "other.txt").write_text("needle-fixture\n")
        result = self.run_tool("sx", "grep", "--print", "--", "-g", "*.ts", "needle-fixture", ".")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "./fixture.ts:1\n")
        self.assertFalse(self.editor_log.exists())

    def test_cancel_and_no_match_do_not_open_editor(self) -> None:
        (self.project / "fixture.txt").write_text("needle-fixture\n")
        self.environment["FZF_DEFAULT_OPTS"] = "--filter=no-selected-item"
        result = self.run_tool("sx", "grep", "needle-fixture")
        self.assertEqual(result.returncode, 1, result.stderr)
        result = self.run_tool("sx", "grep", "no-matched-content")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertFalse(self.editor_log.exists())

    def test_invalid_pattern_reports_failure(self) -> None:
        result = self.run_tool("sx", "grep", "[")
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertFalse(self.editor_log.exists())

    def test_broken_pipe_cancellation_ends_only_own_search(self) -> None:
        selector = self.binaries / "fzf"
        selector.write_text("#!/bin/sh\nexit 130\n")
        selector.chmod(0o755)
        (self.project / "fixture.txt").write_text("needle-fixture\n" * 2000)
        result = self.run_tool("sx", "grep", "needle-fixture")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertFalse(self.editor_log.exists())

    def test_git_show_and_original_log_contract(self) -> None:
        self.git_fixture()
        result = self.run_tool("gx", "show", "HEAD")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("before", result.stdout)
        result = self.run_tool("gx", "log")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r"^[0-9a-f]+\tFixture\t")

    def test_git_diff_workspace_staged_and_editor(self) -> None:
        path = self.git_fixture()
        path.write_text("after\n")
        index_before = self.git("ls-files", "--stage").stdout
        result = self.run_tool("gx", "diff")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("+after", result.stdout)
        self.assertEqual(self.git("ls-files", "--stage").stdout, index_before)
        result = self.run_tool("gx", "diff", "--edit")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.editor_log.read_text()), ["label space", path.name])
        self.git("add", "--", path.name)
        result = self.run_tool("gx", "diff", "--cached")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("+after", result.stdout)

    def test_stash_dispatch_uses_selected_reference_without_real_pop(self) -> None:
        log = self.root / "git-calls.json"
        git = self.binaries / "git"
        git.write_text(f"#!{sys.executable}\nimport json, os, sys\nfrom pathlib import Path\n"
                       "args = sys.argv[1:]\n"
                       "if args == ['rev-parse', '--git-dir']: print('.git')\n"
                       "elif args == ['stash', 'list']: print('stash@{2}: fixture')\n"
                       "elif args[:2] == ['stash', 'pop']: Path(os.environ['DOTFILES_GIT_LOG']).write_text(json.dumps(args))\n"
                       "else: sys.exit(9)\n")
        git.chmod(0o755)
        self.environment["DOTFILES_GIT_LOG"] = str(log)
        result = self.run_tool("gx", "stash")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(log.read_text()), ["stash", "pop", "stash@{2}"])

    def test_completion_scripts_parse(self) -> None:
        for command in [["argc", "--argc-completions", "zsh", "gx", "rx", "omc-build"],
                        ["sx", "--completions", "zsh"]]:
            result = self.run_tool(*command)
            self.assertEqual(result.returncode, 0, result.stderr)
            syntax = self.run_tool("zsh", "-n", input_text=result.stdout)
            self.assertEqual(syntax.returncode, 0, syntax.stderr)

    def test_legacy_names_forward_to_one_implementation(self) -> None:
        # 用函数替身观察 argv，不切分支、不恢复 stash、不启动编辑器。
        script = '''
source "$1"
gx() { print -r -- "gx:${(j:|:)@}"; }
sx() { print -r -- "sx:${(j:|:)@}"; }
fbr
fgl
fgd
fstash
fsearch 'space pattern' 'file:name.txt'
frg -g '*.ts' needle .
rgv needle
frcode needle
'''
        result = self.run_tool("zsh", "-f", "-c", script, "fixture", str(REPOSITORY / "dot_config/zsh/functions.zsh"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), [
            "gx:co|--all-branches", "gx:show", "gx:diff|--edit", "gx:stash",
            "sx:grep|--|space pattern|file:name.txt", "sx:grep|--|-g|*.ts|needle|.",
            "sx:grep|--no-preview|--|needle", "sx:grep|--code|--|needle",
        ])

    @unittest.skipUnless(shutil.which("chezmoi"), "chezmoi 未安装")
    def test_chezmoi_deploys_executable_tools_only(self) -> None:
        config = self.root / "chezmoi.toml"
        config.write_text("")
        destination = self.root / "destination"
        destination.mkdir()
        (destination / ".local/bin").mkdir(parents=True)
        targets = [str(destination / ".local/bin" / name) for name in ["gx", "sx", "rx", "omc-build"]]
        result = self.run_tool("chezmoi", "--config", str(config), "--source", str(REPOSITORY),
                               "--destination", str(destination), "apply", *targets)
        self.assertEqual(result.returncode, 0, result.stderr)
        for name, target in zip(["gx", "sx", "rx", "omc-build"], targets):
            self.assertEqual(Path(target).read_bytes(), (TOOLS / ("executable_" + name)).read_bytes())
            self.assertTrue(os.access(target, os.X_OK))
        self.assertFalse((destination / "docs").exists())


if __name__ == "__main__":
    unittest.main()
