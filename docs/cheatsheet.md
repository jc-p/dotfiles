# 命令速查

通用命令的统一查看入口。按“查看差异、找文件、切换版本”等场景查找，不要求记住所有缩写。本页覆盖主要场景；其余通用定义见 `dot_config/zsh/aliases.zsh`、`dot_config/zsh/functions.zsh` 和 `dot_gitconfig`。本机私有命令不汇入公开手册。

## 怎么查

终端统一入口是 `dev-tools help`，底层使用 cheat。工具名直接显示整页，中文场景直接搜索；不带参数时用 fzf 选择页名。只显示示例，不执行示例：

```bash
dev-tools help              # 选择速查页，回车查看，Esc 退出
dev-tools help gx           # 直接查看 Git 工具速查
dev-tools help rx           # 直接查看传输速查
dev-tools help 差异          # 搜索相关用法
dev-tools help 传文件        # 搜索上传、下载用法
dev-tools help 打补丁 --plain # 关闭分页，输出文本
dev-tools help --list       # 列出速查页
```

六张精选页为 `gx`、`sx`、`rx`、`omc-build`、`shell`、`go`。完整参数仍查工具自身的 `--help`。分页时按 `q` 退出；Tab 补全工具名和常用关键词。原生入口 `cheat gx`、`cheat -s 差异`、`cheat -l` 也可用。

速查页正本在 `dot_config/cheat/cheatsheets/common/`，由 chezmoi 部署到 `~/.config/cheat/cheatsheets/common/`。配置将这些页设为只读；修改时用 `chezmoi edit ~/.config/cheat/cheatsheets/common/gx`，预览后应用。中文说明应与其下一条命令一起维护。`CHEAT_CONFIG_PATH` 默认指向 `~/.config/cheat/conf.yml`，允许本机覆盖。

本页保留配置与背景说明，六个工具的常用示例以速查页为准，不再从 Markdown 生成速查目录。MCP 参数及审批边界仍以 MCP 项目的 `USER_GUIDE.md` 和注册表为准；查询入口不扫描 profile、历史命令或凭据，不将 CLI 的全部命令视为 MCP 已支持。

用已有的 `less` 打开本页，输入 `/差异` 或 `/搜索` 查找，`n` 跳到下一处，`q` 退出：

```bash
less "$(chezmoi source-path)/docs/cheatsheet.md"
```

也可以直接按关键词查，或查看一个已知别名的展开内容：

```bash
rg -n -C 2 '差异' "$(chezmoi source-path)/docs/cheatsheet.md"
alias gd
```

`alias gd` 查看当前 Shell 的定义，可能受插件和本机配置覆盖。查看工具自身的完整参数用 `git diff --help`、`rg --help` 等原生帮助。

## chezmoi

| 场景 | 命令 |
|---|---|
| 编辑配置 | `chezmoi edit ~/.zshrc` |
| 编辑并应用 | `chezmoi edit --apply ~/.zshrc` |
| 预览相关变更 | `chezmoi diff ~/.zshrc ~/.config/zsh` |
| 模拟应用 | `chezmoi --dry-run apply` |
| 应用变更 | `chezmoi apply` |
| 改家目录后同步回源 | `chezmoi re-add ~/.zshrc` |
| 添加通用文件 | `chezmoi add ~/.newconfig`，先移除本机数据 |
| 添加模板 | `chezmoi add --template ~/.gitconfig` |
| 本机配置 | 直接编辑 `*.local.*`，不添加到公开仓库 |
| 移除管理 | `chezmoi forget ~/.oldconfig` |
| 提交准备 | `chezmoi cd`，仅暂存目标文件并审阅差异 |
| 拉取源码 | `git -C "$(chezmoi source-path)" pull --ff-only`，检查后再应用 |
| 进入源目录 | `chezmoi cd` |
| 查看源路径 | `chezmoi source-path ~/.zshrc` |
| 新机器初始化 | `chezmoi init jc-p`，先备份、预览，再应用 |

## 搜索 / 查找

| 场景 | 命令 |
|---|---|
| 找文件（返回路径） | `sx files` |
| 找文件并打开编辑器 | `sx files --edit` |
| 找文件并打开 VS Code | `sx files --code` |
| 搜内容（交互跳行） | `sx grep 关键词` |
| 搜内容（命令行） | `rg 关键词` |
| 找文件（命令行） | `fd 文件名` |
| 搜历史命令 | `Ctrl+R` |
| 搜历史（填入命令行） | `fh`，检查后回车执行 |
| 选择并查看 Git 提交 | `gx show` |
| 选择工作区变更文件并打开编辑器 | `gx diff --edit` |
| 跳目录（zoxide） | `z 目录名` |
| 跳目录（交互） | `fcd` |
| 字面替换（预览后确认） | `replace 旧 新 [文件或目录...]` |

搜索统一由 `sx` 实现，旧兼容名称已移除。内容搜索的 rg 参数会转发，默认排除依赖和构建目录，不再用冒号拆分文件路径。`rg`、`fd` 原生命令始终可用；目录导航、历史查找保持独立功能。

## Shell

| 场景 | 命令 |
|---|---|
| 清屏 | `cls` |
| 重载配置 | `szsh`；删除旧别名或函数后，请打开新终端或用 `exec zsh` 启动新 Shell |
| 编辑通用配置 | `vzsh` / `vza` / `vzf`，编辑后再应用 |
| 编辑本机配置 | `vim ~/.config/zsh/local.zsh` |
| mkdir + cd | `mkcd 目录名` |
| 查看 PATH | `echo $PATH \| tr ':' '\n'` |
| 查重复路径 | `echo $PATH \| tr ':' '\n' \| sort \| uniq -d` |
| 终止进程（TERM） | `fkill`，多选后确认 |
| 强制终止（KILL） | `fkill --force`，多选后确认 |
| 看监听端口 | `ports` |

## Git

原生命令始终可用；下面的缩写只用于减少输入。`gc`、`gca`、`gl`、`gst` 已固定为现有习惯，不依赖 Oh My Zsh；本机可在 `local.zsh` 覆盖。

- 状态：`git status`（`gst`）；简略状态：`git status -sb`（`gs`）。
- 暂存：`git add 文件`（`ga 文件`）；暂存所有改动：`git add --all`（`gaa`）。
- 提交并显示差异：`git commit --verbose`（`gc`）；同时暂存已跟踪文件的改动并提交：`git commit --verbose --all`（`gca`，不自动添加新文件）。
- 指定提交说明：`git commit -m "说明"`；修改上次提交：`git commit --amend --no-edit`（会改写上次提交）。
- 切换分支：`git checkout 分支名`（`gco 分支名`）；新建分支：`git checkout -b 分支名`（`gcb 分支名`）。
- 拉取：`git pull`（`gl`）；推送：`git push`（`gp`，更新远端）。
- 获取并清理失效远端引用：`git fetch --all --prune`（`gf`）。
- 日志图：`git log --oneline --graph --decorate --all`。
- 暂存工作现场：`git stash`；恢复：`git stash pop`（会修改工作区）。
- Git 界面：`lazygit`（安装后可用 `lg`）。注意 `lg` 与 `git lg` 不同，后者是 Git 配置中的日志图别名。

### 查看差异（delta）

delta 自动增强 Git 的差异显示，默认上下对比、新旧行号和 `+/-` 标记；删除行红色背景，新增行绿色背景，行内变化加粗并使用更深的背景。

- 工作区差异：`git diff`（`gd`）。
- 暂存区差异：`git diff --cached`（`gdc`）。
- 文件变更统计：`git diff --stat`（`gds`）。
- 查看一个提交：`git show 提交号`。
- 只看指定文件：上述 diff 命令后追加 `-- 文件路径`。
- 宽窗口临时分栏：`git -c delta.side-by-side=true diff -- 文件路径`；暂存区再加 `--cached`，不另设别名。
- 长输出进入分页器后，`n`/`N` 跳到下一个/上一个文件，`/` 搜索，`q` 退出。
- 分块暂存：`git add -p` 会修改暂存区，delta 只负责着色；输入 `q` 退出。

当前配色适合深色终端。浅色终端可在 `~/.gitconfig.local` 的 `[delta]` 中设置 `dark = false`、`light = true`。若 `GIT_PAGER` 覆盖显示，可临时使用 `env -u GIT_PAGER -u PAGER git diff -- 文件路径`，不强制改写通用环境变量。

## 独立工具

文件与内容搜索使用 `sx`，Git 交互使用 `gx`，传输和远端操作使用 `rx`，OMC 编译与交付使用 `omc-build`。工具用法直接查 `dev-tools help 工具名`。

精选速查页：

- [gx：差异、提交和分支](../dot_config/cheat/cheatsheets/common/gx)
- [sx：文件和内容搜索](../dot_config/cheat/cheatsheets/common/sx)
- [rx：传文件、远端操作和恢复](../dot_config/cheat/cheatsheets/common/rx)
- [omc-build：编译、打补丁和依赖](../dot_config/cheat/cheatsheets/common/omc-build)
- [shell：清屏、重载和导航](../dot_config/cheat/cheatsheets/common/shell)
- [go：Go 专题帮助](../dot_config/cheat/cheatsheets/common/go)

工作工具的私有配置仍独立留本机。`rx` 的 CLI 传输需要显式加 `--dry-run`；MCP 的默认值另查 MCP 手册。构建、传输、恢复、清理与切换分支可能产生写入，查帮助不会执行这些操作。

## Homebrew

| 场景 | 命令 |
|---|---|
| 更新所有 | `brewup` |
| 安装 | `bi 包名` |
| 卸载 | `bu 包名` |
| 搜索 | `bs 关键词` |
| 已装列表 | `bl` |
| 安装通用依赖 | `bash "$(chezmoi source-path)/scripts/bootstrap.sh"` |
| 安装可选依赖 | `bash "$(chezmoi source-path)/scripts/bootstrap.sh" --optional` |

## mise

| 场景 | 命令 |
|---|---|
| 看管了哪些 | `mise list` |
| 看配置来源 | `mise config ls` |
| 本机版本 | 编辑 `~/.config/mise/conf.d/99-machine.local.toml` |
| 装缺失 | `mise install` |
| 更新 | `mise upgrade` |
| 某工具版本 | `mise current node` |
| 健康检查 | `mise doctor` |

## Vim

| 场景 | 命令 |
|---|---|
| 保存 | `:w` |
| 退出 | `:q` |
| 保存退出 | `:wq` 或 `ZZ` |
| 放弃退出 | `:q!` 或 `ZQ` |
| 插件状态 | `:PlugStatus` |
| 插件更新 | `:PlugUpdate` |
| 清行尾空格 | `:%s/\s\+$//e` |
| 全文缩进 | `gg=G` |
| 关闭搜索高亮 | `:nohlsearch` 或 `空格+h` |
| 保存文件 | `空格+w` |
| 退出 | `空格+q` |

## 文件查看

| 场景 | 命令 |
|---|---|
| 目录列表 | `ls` / `ll` / `la` |
| 目录树 | `lt` |
| 看文件（bat） | `cat 文件` |
| 看文件（原始） | `\cat 文件`（转义别名） |

## macOS 杂项

| 场景 | 命令 |
|---|---|
| 看磁盘 | `df -h` |
| 复制路径 | `pwd \| pbcopy` |
| 查找大文件 | `fd -t f -S +100M` |

## 入口精简状态

只删除已确认重复的通用封装。配置文件不能证明使用频率；未确认的入口继续保留，本机配置可最后覆盖。

- 已确认保留：`cls`、`szsh`、`gl`、`rx` 和搜索功能；此前确认的 `gc`、`gca`、`gst` 及差异入口 `gd`、`gdc`、`gds` 保留。
- 已删除重复入口：`c` → `cls`、`reload` → `szsh`、`gpl` → `gl`；`..`、`...` 各只声明一次。通用模块会清退 OMZ 带回的 `c`、`reload`、`gpl` 别名。
- 已删除兼容入口：`ff/fe/fcode/fsearch/rgv/frg/frcode`，以及 `fbr/fgl/fgd/fstash/fshow`；统一使用 `sx` 和 `gx`，重载也会清退旧函数或别名。
- 未删除：`bi/bs/bl/bcu`、各 `rg` 缩写、`pyrun`、`fkill`；没有足够使用习惯证据继续精简。
- 查询说明统一放在本页，不另建手册，不从历史命令或私有配置自动生成公开文档。
