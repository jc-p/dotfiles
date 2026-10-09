"""cheat 薄封装的公开入口检查；只运行临时替身，不执行示例。"""

import io
import json
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

REPOSITORY = Path(__file__).resolve().parents[1]
SCRIPT = REPOSITORY / "dot_local/bin/executable_dev-tools"


class Terminal(io.StringIO):
    def isatty(self) -> bool:
        return True


class HelpTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="cheat-help-test-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.binaries = self.root / "bin"
        self.binaries.mkdir()
        self.log = self.root / "argv.jsonl"
        self.marker = self.root / "must-not-execute"
        cheat = self.binaries / "cheat"
        cheat.write_text(f"#!{sys.executable}\n" +
            "import json,os,sys\nfrom pathlib import Path\n"
            "with Path(os.environ['TEST_LOG']).open('a') as f:\n"
            " f.write(json.dumps({'argv':sys.argv[1:],'pager':os.environ.get('CHEAT_PAGER'),"
            "'config':os.environ.get('CHEAT_CONFIG_PATH')})+'\\n')\n"
            "args=sys.argv[1:]\n"
            "if args==['-b']: print('title: tags:\\ngx common\\nrx common')\n"
            "elif args and args[0]=='-s': print('rx: 搜索结果 '+args[1])\n"
            "elif args and args[0]=='-l': print('gx common\\nrx common')\n"
            "else: print('rx put --dry-run ./文件 host:/目录/')\n"
            "sys.exit(int(os.environ.get('TEST_EXIT','0')))\n")
        cheat.chmod(0o700)
        self.environment = dict(os.environ, PATH=str(self.binaries), TEST_LOG=str(self.log),
                                CHEAT_CONFIG_PATH=str(self.root / "conf.yml"),
                                PYTHONDONTWRITEBYTECODE="1")

    def call(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([sys.executable, str(SCRIPT), "help", *arguments],
                              capture_output=True, text=True, env=self.environment, timeout=10, check=False)

    def records(self) -> list[dict[str, object]]:
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_known_tool_displays_sheet_without_executing_example(self) -> None:
        result = self.call("rx")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("rx put --dry-run", result.stdout)
        self.assertEqual(self.records()[-1]["argv"], ["rx"])
        self.assertFalse(self.marker.exists())

    def test_keyword_is_literal_argument(self) -> None:
        query = f"差异 $(touch {self.marker})"
        result = self.call(query)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.records()[-1]["argv"], ["-s", query])
        self.assertFalse(self.marker.exists())

    def test_plain_mode_and_explicit_config(self) -> None:
        result = self.call("rx", "--plain")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.records()[-1]["pager"], "")
        self.assertEqual(self.records()[-1]["config"], self.environment["CHEAT_CONFIG_PATH"])

    def test_listing_and_no_terminal_fallback(self) -> None:
        for args in [("--list",), ()]:
            self.assertEqual(self.call(*args).returncode, 0)
            self.assertEqual(self.records()[-1]["argv"], ["-b"])

    def test_missing_dependency_and_cheat_failure(self) -> None:
        self.environment["TEST_EXIT"] = "2"
        result = self.call("rx")
        self.assertEqual(result.returncode, 2)
        self.assertIn("无法读取 cheat", result.stderr)
        self.environment["PATH"] = str(self.root / "missing")
        result = self.call("rx")
        self.assertEqual(result.returncode, 2)
        self.assertIn("找不到 cheat", result.stderr)

    def test_interactive_selection_cancel_and_untrusted_selection(self) -> None:
        fzf = self.binaries / "fzf"
        fzf.write_text(f"#!{sys.executable}\n" +
            "import os,sys\n"
            "assert 'FZF_DEFAULT_OPTS' not in os.environ\n"
            "sys.stdin.read()\n"
            "if os.environ['TEST_SELECT']=='cancel': sys.exit(130)\n"
            "print(os.environ['TEST_SELECT'])\n")
        fzf.chmod(0o700)
        main = runpy.run_path(str(SCRIPT))["main"]
        for selected in ("rx", "cancel", "invalid"):
            env = dict(self.environment, TEST_SELECT=selected,
                       FZF_DEFAULT_OPTS="--bind=enter:execute(touch unsafe)")
            with patch.dict(os.environ, env, clear=True), patch.object(sys, "stdin", Terminal()), \
                    patch.object(sys, "stdout", Terminal()), patch.object(sys, "argv", ["dev-tools", "help"]):
                if selected == "invalid":
                    with self.assertRaisesRegex(ValueError, "无效页名"):
                        main()
                else:
                    self.assertEqual(main(), 0)
            self.assertFalse(self.marker.exists())
        self.assertEqual(self.records()[-1]["argv"], ["-b"])

    def test_completion_output_parses(self) -> None:
        result = subprocess.run([sys.executable, str(SCRIPT), "--completions", "zsh"],
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0)
        syntax = subprocess.run(["zsh", "-n"], input=result.stdout,
                                capture_output=True, text=True, check=False)
        self.assertEqual(syntax.returncode, 0, syntax.stderr)

    @unittest.skipUnless(shutil.which("cheat"), "cheat 未安装")
    def test_real_cheat_with_isolated_deployment(self) -> None:
        destination = self.root / "destination"
        (destination / ".config/cheat").mkdir(parents=True)
        (destination / ".local/bin").mkdir(parents=True)
        config = self.root / "chezmoi.toml"
        config.write_text("")
        applied = subprocess.run(
            ["chezmoi", "--config", str(config), "--source", str(REPOSITORY),
             "--destination", str(destination), "apply", str(destination / ".config/cheat"),
             str(destination / ".local/bin/dev-tools")], capture_output=True, text=True, check=False,
        )
        self.assertEqual(applied.returncode, 0, applied.stderr)
        self.assertIn(str(destination / ".config/cheat/cheatsheets/common"),
                      (destination / ".config/cheat/conf.yml").read_text())
        env = dict(os.environ, CHEAT_CONFIG_PATH=str(destination / ".config/cheat/conf.yml"), CHEAT_PAGER="")
        for query, expected in [("gx", "gx diff"), ("传文件", "rx put --dry-run"),
                                ("打补丁", "omc-build patch --help")]:
            result = subprocess.run([str(destination / ".local/bin/dev-tools"), "help", query, "--plain"],
                                    capture_output=True, text=True, env=env, timeout=10, check=False)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(expected, result.stdout)
        names = sorted(p.name for p in (destination / ".config/cheat/cheatsheets/common").iterdir())
        self.assertEqual(names, ["go", "gx", "omc-build", "rx", "shell", "sx"])


if __name__ == "__main__":
    unittest.main()
