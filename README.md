# dotfiles

使用 [chezmoi](https://chezmoi.io) 管理通用配置，本机配置独立保留。应用配置不安装软件；启动 Shell/Vim 不下载依赖。

## 配置边界

- 通用：Zsh 模块、Starship、Git 默认行为、Vim、SSH 通用参数、mise 默认版本。
- 本机：工作目录、代理、私有服务、Git 身份和凭据助手、SSH 主机及密钥路径、机器工具版本。
- `.gitignore` 排除本机源码文件，`.chezmoiignore` 按目标路径排除本机配置和仓库文档、示例、脚本；SSH 只管理通用 `config`。
- `private_` 只设置文件权限，不加密；本仓库公开，不上传本机配置、凭据或密钥。

本机入口及加载顺序：

- `~/.config/zsh/env.local.zsh`：环境变量模块之后、工具初始化之前。
- `~/.config/zsh/local.zsh`：通用别名和函数之后；语法高亮插件最后加载。
- `~/.gitconfig.local`：通用 Git 配置末尾加载。
- `~/.ssh/config.local`：通用 SSH 配置开头加载，遵守 SSH 首个匹配值优先的规则。
- `~/.config/mise/conf.d/99-machine.local.toml`：覆盖 `00-common.toml`；主 `config.toml` 只保留设置。
- `~/.vimrc.local`：通用 Vim 配置末尾加载。

缺失本机文件时仍可加载通用配置；Git 提交前必须在本机配置实际身份。

## 首次准备

下面的安装命令会下载软件；`init` 只准备源码，不应用家目录配置。

```bash
brew install chezmoi
chezmoi init jc-p
dotfiles_source="$(chezmoi source-path)"
```

若已有源码检出，可对 chezmoi 命令统一添加 `--source="$HOME/dotfiles"`，并将 `dotfiles_source` 设为该检出目录；不要另建第二份配置副本。

首次应用前备份现有目标；备份目录权限为 700，可能含本机私有配置，保持在本地。

```bash
backup_dir="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"
for item in .zshrc .gitconfig .gitignore_global .vimrc .vim/plug-snapshot.vim \
  .hushlogin .ssh/config .config/zsh .config/starship.toml .config/mise; do
  if [ -e "$HOME/$item" ] || [ -L "$HOME/$item" ]; then
    mkdir -p "$backup_dir/$(dirname "$item")"
    cp -Rp "$HOME/$item" "$backup_dir/$item"
  fi
done
```

显式安装通用依赖；可选清单包含额外 CLI 和 macOS 字体，按需编辑后安装。

```bash
bash "$dotfiles_source/scripts/bootstrap.sh"
# 如确实需要可选软件：
# bash "$dotfiles_source/scripts/bootstrap.sh" --optional
```

Oh My Zsh 可选；通用默认插件为 Git，本机可在 `env.local.zsh` 指定已有插件列表。已有 Git 缩写优先保留，通用配置只补缺失项。Zsh 插件统一从 Homebrew 加载，已安装的 `zsh-you-should-use` 也会加载，zoxide 仅初始化一次。

## 准备本机配置

示例只用于填写结构，不自动采集本机数据。以下命令创建缺失的文件，保留已有文件；随后在本机编辑 Git 身份及需要的工具版本。

```bash
mkdir -p "$HOME/.config/zsh" "$HOME/.config/mise/conf.d" "$HOME/.ssh"
copy_local_example() {
  if [ -e "$2" ] || [ -L "$2" ]; then
    printf '已存在，保留: %s\n' "$2"
  else
    install -m 600 "$dotfiles_source/examples/$1" "$2"
  fi
}
copy_local_example env.local.zsh.example "$HOME/.config/zsh/env.local.zsh"
copy_local_example local.zsh.example "$HOME/.config/zsh/local.zsh"
copy_local_example gitconfig.local.example "$HOME/.gitconfig.local"
copy_local_example ssh-config.local.example "$HOME/.ssh/config.local"
copy_local_example 99-machine.local.toml.example "$HOME/.config/mise/conf.d/99-machine.local.toml"
copy_local_example vimrc.local.example "$HOME/.vimrc.local"
unset -f copy_local_example
```

迁移现有配置时，先将本机路径、代理、凭据助手等移入本机文件，再逐项审阅通用目标差异。不要整份添加 `.zshrc`、`.gitconfig` 或 `.ssh` 目录。

## 检查与应用

检查需要 Bash、Zsh、Ruby、Python 3.11+、rg、Git、SSH、Vim；ShellCheck 存在时会运行，mise 存在时会验证本机版本覆盖。脚本不安装软件、不应用配置；测试只在临时目录写文件或使用进程测试替身。

```bash
bash "$dotfiles_source/scripts/check.sh"
chezmoi diff ~/.zshrc ~/.gitconfig ~/.ssh/config ~/.config/mise
# 分模块继续审阅其他目标，例如 ~/.config/zsh、~/.vimrc、~/.config/starship.toml。
chezmoi --dry-run apply
# 全部目标确认后，再执行：
chezmoi apply
```

mise 的 `auto_install` 已关闭。通用默认工具为 Node 24、Python 3.12、Rust stable 和 pnpm 10，本机精确版本放在 `99-machine.local.toml`；项目需要精确版本时放入项目 `mise.toml`。运行 `mise install` 才显式安装已选择的运行时。`replace` 需要可用的 Python 3 和 rg。

通用配置合入了现有 Starship 外观、Vim 快捷键及插件声明。`ff` 保留返回路径的行为，`fe` 打开编辑器，`fcode` 打开 VS Code；原有 `frg`、`frcode`、`y`、`pip` 等入口保留。

Vim 缺少 vim-plug 时只加载基础配置。需要插件时显式安装 vim-plug，再进入 Vim 执行 `:PlugInstall`；注册插件后才加载快照。已有快照只固定其中 6 个插件的 commit，其余插件尚未生成快照；启动时不会安装缺失插件。

```bash
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

## 日常同步与恢复

- 用 `chezmoi edit` 编辑通用配置；`vza`、`vzf` 分别定位别名和函数。
- 本机差异直接编辑本机文件，不执行 `chezmoi add`。
- 拉取通用配置后，先检查和分模块预览，再应用；软件安装独立执行。
- 提交前只暂存目标文件，检查暂存差异，不使用 `git add -A` 收集本机数据。提交和推送会更新远端共享基线。
- 恢复备份可执行 `cp -Rp "$backup_dir/." "$HOME/"`；这只恢复已备份文件，首次应用新建的目标需根据应用预览逐项处理。

交互函数、安装和同步命令见 [命令速查](docs/cheatsheet.md)，异常处理见 [故障排查](docs/troubleshooting.md)。
