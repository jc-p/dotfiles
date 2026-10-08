"""以原生命令检查配置边界；不连接服务器、不修改家目录。"""

from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]


class ConfigTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory(prefix="dotfiles-config-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    @unittest.skipUnless(shutil.which("chezmoi"), "chezmoi 未安装，跳过原生管理边界验证")
    def test_chezmoi_managed_boundaries(self) -> None:
        source = self.root / "source"
        destination = self.root / "destination"
        ssh = source / "private_dot_ssh"
        zsh = source / "dot_config/zsh"
        ssh.mkdir(parents=True)
        zsh.mkdir(parents=True)
        destination.mkdir()
        config = self.root / "chezmoi.toml"
        config.write_text("")
        shutil.copyfile(REPOSITORY / ".chezmoiignore", source / ".chezmoiignore")
        for directory, filename in [(ssh, "private_config"), (ssh, "private_id_ed25519"),
                                    (ssh, "config.local"), (zsh, "env.zsh"),
                                    (zsh, "local.zsh"), (zsh, "env.local.zsh")]:
            (directory / filename).write_text("fixture\n")
        result = subprocess.run(
            ["chezmoi", "--config", str(config), "--source", str(source),
             "--destination", str(destination), "managed"],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        managed = set(result.stdout.splitlines())
        self.assertIn(".ssh/config", managed)
        self.assertIn(".config/zsh/env.zsh", managed)
        for path in [".ssh/id_ed25519", ".ssh/config.local", ".config/zsh/local.zsh", ".config/zsh/env.local.zsh"]:
            self.assertNotIn(path, managed)

    def test_local_files_ignored_and_examples_kept(self) -> None:
        ignored = ["dot_config/zsh/env.local.zsh", "dot_config/zsh/local.zsh",
                   "dot_gitconfig.local", "dot_config/mise/conf.d/99-machine.local.toml",
                   "private_dot_ssh/private_id_ed25519", "private_dot_ssh/known_hosts", ".env"]
        result = subprocess.run(
            ["git", "check-ignore", "--no-index", "--stdin"], cwd=REPOSITORY,
            input="\n".join(ignored) + "\n", capture_output=True, text=True, check=False,
        )
        self.assertEqual(set(result.stdout.splitlines()), set(ignored))
        examples = REPOSITORY.joinpath("examples").glob("*.example")
        for path in ["private_dot_ssh/private_config", *(str(p.relative_to(REPOSITORY)) for p in examples)]:
            result = subprocess.run(
                ["git", "check-ignore", "--no-index", path], cwd=REPOSITORY,
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(result.returncode, 1, path)

    def test_git_local_override(self) -> None:
        local = self.root / "gitconfig.local"
        local.write_text("[user]\nname = Fixture\nemail = fixture@example.invalid\n[pull]\nrebase = true\n")
        config = self.root / "gitconfig"
        config.write_text((REPOSITORY / "dot_gitconfig").read_text().replace("~/.gitconfig.local", str(local)))
        for key, value in [("user.name", "Fixture"), ("user.useConfigOnly", "true"),
                           ("pull.rebase", "true"), ("core.excludesfile", "~/.gitignore_global")]:
            result = subprocess.run(
                ["git", "config", "--file", str(config), "--includes", "--get", key],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(result.returncode, 0, key)
            self.assertEqual(result.stdout.strip(), value)

    def test_ssh_local_override_without_connection(self) -> None:
        local = self.root / "ssh.local"
        local.write_text("Host example.invalid\n  ServerAliveInterval 42\n")
        config = self.root / "ssh.config"
        config.write_text((REPOSITORY / "private_dot_ssh/private_config").read_text().replace(
            "Include config.local", "Include " + str(local)))
        result = subprocess.run(
            ["ssh", "-G", "-F", str(config), "example.invalid"],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        values = dict(line.split(" ", 1) for line in result.stdout.splitlines() if " " in line)
        self.assertEqual(values["serveraliveinterval"], "42")
        self.assertEqual(values["serveralivecountmax"], "3")

    def test_vim_snapshot_assignments_and_order(self) -> None:
        vimrc = (REPOSITORY / "dot_vimrc").read_text()
        plugins = re.findall(r"^\s*Plug '([^']+)'", vimrc, re.M)
        # 只构造注册表验证 commit 赋值，不加载实际插件。
        script = "let g:plugs = {}\n"
        for plugin in plugins:
            script += f"let g:plugs['{plugin.split('/')[-1]}'] = {{}}\n"
        script += "source " + str(REPOSITORY / "dot_vim/plug-snapshot.vim") + "\n"
        script += f"call assert_equal({len(plugins)}, len(g:plugs))\n"
        script += "let pinned = 0\nfor plug in values(g:plugs)\nif has_key(plug, 'commit')\ncall assert_match('^[0-9a-f]\\{40}$', plug.commit)\nlet pinned += 1\nendif\nendfor\n"
        script += f"call assert_equal({len(plugins)}, pinned)\n"
        script += "if !empty(v:errors)\ncquit\nendif\nqa!\n"
        fixture = self.root / "snapshot-test.vim"
        fixture.write_text(script)
        result = subprocess.run(
            ["vim", "-Nu", "NONE", "-i", "NONE", "-n", "-es", "-S", str(fixture)],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0)
        self.assertLess(vimrc.index("Plug 'jiangmiao/auto-pairs'"), vimrc.index("source ~/.vim/plug-snapshot.vim"))
        self.assertLess(vimrc.index("source ~/.vim/plug-snapshot.vim"), vimrc.index("call plug#end()"))
        self.assertNotIn("silent !curl", vimrc)

    @unittest.skipUnless(shutil.which("mise"), "mise 未安装，跳过本机加载顺序验证")
    def test_mise_local_override_offline(self) -> None:
        config = self.root / "config"
        conf_d = config / "conf.d"
        conf_d.mkdir(parents=True)
        shutil.copyfile(REPOSITORY / "dot_config/mise/config.toml", config / "config.toml")
        shutil.copyfile(REPOSITORY / "dot_config/mise/conf.d/00-common.toml", conf_d / "00-common.toml")
        shutil.copyfile(REPOSITORY / "examples/99-machine.local.toml.example", conf_d / "99-machine.local.toml")
        work = self.root / "work"
        work.mkdir()
        environment = dict(os.environ, MISE_CONFIG_DIR=str(config), MISE_DATA_DIR=str(self.root / "data"),
                           MISE_CACHE_DIR=str(self.root / "cache"), MISE_OFFLINE="1", MISE_AUTO_INSTALL="0",
                           MISE_HIDE_UPDATE_WARNING="1")
        result = subprocess.run(
            ["mise", "ls", "--current", "--json"], cwd=work, env=environment,
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        tools = json.loads(result.stdout)
        for tool, version in [("node", "24"), ("python", "3.12"), ("pnpm", "10")]:
            self.assertEqual(tools[tool][0]["requested_version"], version)
        self.assertNotIn("rust", tools)

    def test_readme_shell_examples_parse(self) -> None:
        for path in [REPOSITORY / "README.md", *REPOSITORY.joinpath("docs").glob("*.md")]:
            for block in re.findall(r"```(?:bash|sh)\n(.*?)```", path.read_text(), re.S):
                result = subprocess.run(["bash", "-n"], input=block, capture_output=True, text=True, check=False)
                self.assertEqual(result.returncode, 0, f"{path.name}: {result.stderr}")


if __name__ == "__main__":
    unittest.main()
