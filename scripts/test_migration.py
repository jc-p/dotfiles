"""新机迁移检查：安装器用替身，配置只应用到临时目录。"""

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import tomllib
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]


class MigrationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory(prefix="dotfiles-migration-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def bootstrap_fixture(self, fail_brew: bool = False) -> tuple[dict[str, str], Path]:
        """替身只记录调用，禁止测试安装真实软件。"""
        binaries = self.root / "bin"
        prefix = self.root / "mise-prefix"
        binaries.mkdir()
        (prefix / "bin").mkdir(parents=True)
        log = self.root / "calls"
        brew = binaries / "brew"
        brew.write_text('''#!/bin/bash
if [[ "$1" == --prefix ]]; then
  printf '%s\\n' "$DOTFILES_TEST_PREFIX"
  exit 0
fi
printf 'brew %s\\n' "$*" >> "$DOTFILES_TEST_LOG"
[[ "${HOMEBREW_NO_AUTO_UPDATE:-}" == 1 && "${HOMEBREW_NO_INSTALL_CLEANUP:-}" == 1 ]] || exit 8
[[ "$DOTFILES_TEST_FAIL_BREW" == 0 ]] || exit 7
''')
        mise = prefix / "bin/mise"
        mise.write_text('''#!/bin/bash
printf 'mise %s config=%s\\n' "$*" "${MISE_CONFIG_DIR:-}" >> "$DOTFILES_TEST_LOG"
''')
        brew.chmod(0o755)
        mise.chmod(0o755)
        environment = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ["PATH"],
                           DOTFILES_TEST_PREFIX=str(prefix), DOTFILES_TEST_LOG=str(log),
                           DOTFILES_TEST_FAIL_BREW="1" if fail_brew else "0")
        return environment, log

    def test_bootstrap_prepares_runtimes_before_optional_tools(self) -> None:
        environment, log = self.bootstrap_fixture()
        result = subprocess.run(
            ["bash", str(REPOSITORY / "scripts/bootstrap.sh"), "--optional"],
            env=environment, capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(log.read_text().splitlines(), [
            f"brew bundle --file={REPOSITORY / 'Brewfile'}",
            f"mise install config={REPOSITORY / 'dot_config/mise'}",
            "mise reshim config=" + environment.get("MISE_CONFIG_DIR", ""),
            f"brew bundle --file={REPOSITORY / 'Brewfile.optional'}",
        ])

    def test_bootstrap_stops_when_core_install_fails(self) -> None:
        environment, log = self.bootstrap_fixture(fail_brew=True)
        result = subprocess.run(
            ["bash", str(REPOSITORY / "scripts/bootstrap.sh"), "--optional"],
            env=environment, capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 7)
        self.assertEqual(len(log.read_text().splitlines()), 1)

    def test_git_habits_with_and_without_existing_plugin_aliases(self) -> None:
        source = str(REPOSITORY / "dot_config/zsh/aliases.zsh")
        for existing in ["", "alias gl='git log'; alias gst='git stash'; alias gc='git commit -m'"]:
            script = existing + "\nsource \"$1\"\n"
            script += "alias gc gl gst gca\n"
            result = subprocess.run(
                ["zsh", "-f", "-c", script, "fixture", source],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), [
                "gc='git commit --verbose'", "gl='git pull'", "gst='git status'",
                "gca='git commit --verbose --all'",
            ])

    def test_runtime_entry_wins_after_local_path_changes(self) -> None:
        """模拟本机接线再次改 PATH，验证首条命令仍走核心运行时入口。"""
        home = self.root / "fixture-home"
        modules = home / ".config/zsh"
        modules.parent.mkdir(parents=True)
        shutil.copytree(REPOSITORY / "dot_config/zsh", modules)
        binaries = self.root / "bin"
        legacy = self.root / "legacy"
        shims = self.root / "shims"
        for path in [binaries, legacy, shims]:
            path.mkdir()
        (binaries / "brew").write_text('#!/bin/bash\nprintf "export HOMEBREW_PREFIX=%q\\n" "$DOTFILES_TEST_ROOT"\n')
        (binaries / "mise").write_text('''#!/bin/bash
[[ "$*" == 'activate zsh --shims' ]] || exit 2
printf 'path=("%s" $path)\\n' "$DOTFILES_TEST_SHIMS"
''')
        (legacy / "node").write_text('#!/bin/bash\nprintf "v99-legacy\\n"\n')
        (shims / "node").write_text('#!/bin/bash\nprintf "v24-fixture\\n"\n')
        for path in [binaries / "brew", binaries / "mise", legacy / "node", shims / "node"]:
            path.chmod(0o755)
        (modules / "env.local.zsh").write_text('path=("$DOTFILES_TEST_BIN" $path)\n')
        (modules / "local.zsh").write_text('path=("$DOTFILES_TEST_LEGACY" $path)\n')
        # 只重定向该入口的文件引用；不重设真实 HOME。
        startup = (REPOSITORY / "dot_zshrc").read_text().replace("$HOME", str(home))
        script = self.root / "startup.zsh"
        script.write_text(startup + '\ncommand node --version\n')
        environment = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ["PATH"],
                           ZSH=str(home / ".oh-my-zsh"), DOTFILES_TEST_ROOT=str(self.root),
                           DOTFILES_TEST_BIN=str(binaries), DOTFILES_TEST_LEGACY=str(legacy),
                           DOTFILES_TEST_SHIMS=str(shims))
        result = subprocess.run(["zsh", "-f", str(script)], env=environment,
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "v24-fixture")

    @unittest.skipUnless(shutil.which("chezmoi"), "chezmoi 未安装")
    def test_clean_destination_apply_without_private_files(self) -> None:
        destination = self.root / "destination"
        destination.mkdir()
        config = self.root / "chezmoi.toml"
        config.write_text("umask = 0o022\n")
        command = ["chezmoi", "--config", str(config), "--source", str(REPOSITORY),
                   "--destination", str(destination), "--persistent-state", str(self.root / "state"),
                   "--cache", str(self.root / "cache"), "--refresh-externals=never"]
        subprocess.run(command + ["apply", "--include", "files,dirs"],
                       check=True, capture_output=True, text=True)
        result = subprocess.run(command + ["status"], check=True, capture_output=True, text=True)
        self.assertEqual(result.stdout, "")
        for name in [".zshrc", ".ripgreprc", ".gitconfig", ".ssh/config", ".config/mise/conf.d/00-common.toml"]:
            self.assertTrue((destination / name).is_file(), name)
        for name in [".gitconfig.local", ".ssh/config.local", ".config/zsh/local.zsh", "scripts", "Brewfile"]:
            self.assertFalse((destination / name).exists(), name)
        config = tomllib.loads((destination / ".config/mise/conf.d/00-common.toml").read_text())
        self.assertEqual(set(config["tools"]), {"node", "python", "pnpm"})


if __name__ == "__main__":
    unittest.main()
