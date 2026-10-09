# 命令速查

通用命令的统一查看入口。按“查看差异、找文件、切换版本”等场景查找，不要求记住所有缩写。本页覆盖主要场景；其余通用定义见 `dot_config/zsh/aliases.zsh`、`dot_config/zsh/functions.zsh` 和 `dot_gitconfig`。本机私有命令不汇入公开手册。

## 怎么查

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

四个自用工具由 dotfiles 管理源码和部署，依赖显式安装。每个工具用 `--help` 查完整用法；已有 Zsh 补全系统时，输入工具名后按 Tab 查看子命令。工作工具的私有配置仍独立留本机。

- `gx`：Git 交互工作流。`gx show` 选提交并展示；`gx diff` 选工作区变更文件并显示差异，`--cached` 看暂存区、`--edit` 打开编辑器；`gx co --all-branches` 选分支，`gx stash` 选 stash 并恢复（会修改工作区）。原 `gx log` 保持不变，不另设 Shell 兼容入口。
- `sx`：文件和内容搜索，最常用的是 `sx files`、`sx files --edit`、`sx grep 关键词`。完整示例见下方。
- `rx`：已确认常用；用于传输、远端执行、日志和备份恢复。先查 `rx --help`；具体参数查 `rx 子命令 --help`。传输和远端执行可能修改远端，查看帮助不会执行这些操作。
- `omc-build`：OMC 编译、交付打包和依赖提取。先查 `omc-build --help`，提供 `build`、`patch`、`deps` 等子命令；构建命令会写入产物。
- `go`：本机当前为 Go 开发工具，查 `go help` 或 `go help build` 等专题帮助；不与 Shell 快捷方式合并。

```bash
sx files                   # 选择文件，返回路径
sx files --edit            # 选择后用 EDITOR 打开
sx files --code            # 选择后用 VS Code 打开
sx grep 关键词              # 查内容，选择后跳到编辑器匹配行
sx grep --code 关键词       # 查内容，选择后用 VS Code 跳行
sx grep --print 关键词      # 只返回 文件:行号，不打开编辑器
sx grep -- -g '*.ts' 关键词 . # 转发原生 rg 选项，明确搜索当前目录
```

取消选择或无匹配返回非零，不打开编辑器。`sx files` 默认使用 fd，管道输入可用 `sx files --stdin`；`FZF_DEFAULT_COMMAND` 仍用于 fzf 自身的快捷键，不决定 sx 的文件来源。特殊路径中的制表符和换行暂不支持，工具会报错；此类文件请直接使用原生工具处理。

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
