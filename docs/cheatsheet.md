# 命令速查

一页纸速查。忘了命令翻这个。

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
| 找文件（返回路径） | `ff` |
| 找文件并打开编辑器 | `fe` |
| 找文件并打开 VS Code | `fcode` |
| 搜内容（交互跳行） | `fsearch 关键词` |
| 搜内容（命令行） | `rg 关键词` |
| 找文件（命令行） | `fd 文件名` |
| 搜历史命令 | `Ctrl+R` |
| 搜历史（填入命令行） | `fh`，检查后回车执行 |
| 搜 git log | `fgl` |
| 搜未提交改动 | `fgd` |
| 跳目录（zoxide） | `z 目录名` |
| 跳目录（交互） | `fcd` |
| 字面替换（预览后确认） | `replace 旧 新 [文件或目录...]` |

## Shell

| 场景 | 命令 |
|---|---|
| 重载配置 | `reload` 或 `exec zsh` |
| 编辑通用配置 | `vzsh` / `vza` / `vzf`，编辑后再应用 |
| 编辑本机配置 | `vim ~/.config/zsh/local.zsh` |
| mkdir + cd | `mkcd 目录名` |
| 查看 PATH | `echo $PATH \| tr ':' '\n'` |
| 查重复路径 | `echo $PATH \| tr ':' '\n' \| sort \| uniq -d` |
| 终止进程（TERM） | `fkill`，多选后确认 |
| 强制终止（KILL） | `fkill --force`，多选后确认 |
| 看监听端口 | `ports` |

## Git

已有 Oh My Zsh 插件缩写优先保留；通用配置只补缺失项。`gc`、`gl`、`gst` 等含义以 `alias 命令名` 的实际定义为准，下列操作使用明确的 Git 命令避免混淆。

| 场景 | 命令 |
|---|---|
| 状态 | `gs` |
| add | `ga` / `gaa` |
| commit | `git commit -m "message"` |
| commit amend | `git commit --amend --no-edit` |
| checkout | `gco` |
| 新分支 | `gcb 分支名` |
| diff | `gd` |
| log 图形 | `git log --oneline --graph --decorate --all` |
| push | `gp` |
| pull | `gpl` |
| fetch prune | `gf` |
| stash | `git stash` / `git stash pop` |
| lazygit | `lg` |

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
