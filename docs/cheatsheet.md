# Cheatsheet

一页纸速查。忘了命令翻这个。

## chezmoi

| 场景 | 命令 |
|---|---|
| 编辑配置 | `chezmoi edit ~/.zshrc` |
| 编辑并应用 | `chezmoi edit --apply ~/.zshrc` |
| 预览变更 | `chezmoi diff` |
| 应用变更 | `chezmoi apply` |
| 改家目录后同步回源 | `chezmoi re-add ~/.zshrc` |
| 添加文件 | `chezmoi add ~/.newconfig` |
| 添加模板 | `chezmoi add --template ~/.gitconfig` |
| 添加加密 | `chezmoi add --encrypt ~/.ssh/key` |
| 移除管理 | `chezmoi forget ~/.oldconfig` |
| 提交推送 | `chezmoi cd && git add -A && git commit -m "..." && git push && exit` |
| 拉取应用 | `chezmoi update` |
| 进入源目录 | `chezmoi cd` |
| 查看源路径 | `chezmoi source-path ~/.zshrc` |
| 新机器初始化 | `chezmoi init --apply jc-p` |

## 搜索 / 查找

| 场景 | 命令 |
|---|---|
| 找文件（交互） | `ff` |
| 搜内容（交互跳行） | `fg 关键词` |
| 搜内容（命令行） | `rg 关键词` |
| 找文件（命令行） | `fd 文件名` |
| 搜历史命令 | `Ctrl+R` |
| 搜历史（函数） | `fh` |
| 搜 git log | `fgl` |
| 搜未提交改动 | `fgd` |
| 跳目录（zoxide） | `z 目录名` |
| 跳目录（交互） | `fcd` |
| 批量替换 | `replace 旧 新` |

## Shell

| 场景 | 命令 |
|---|---|
| 重载配置 | `reload` 或 `exec zsh` |
| 编辑 zshrc | `vzsh` |
| mkdir + cd | `mkcd 目录名` |
| 查看 PATH | `echo $PATH \| tr ':' '\n'` |
| 查重复路径 | `echo $PATH \| tr ':' '\n' \| sort \| uniq -d` |
| 杀进程 | `fkill` |
| 看监听端口 | `ports` |

## Git

| 场景 | 命令 |
|---|---|
| 状态 | `gs` |
| add | `ga` / `gaa` |
| commit | `gc "message"` |
| commit amend | `gca` |
| checkout | `gco` |
| 新分支 | `gcb 分支名` |
| diff | `gd` |
| log 图形 | `gl` |
| push | `gp` |
| pull | `gpl` |
| fetch prune | `gf` |
| stash | `gst` / `gstp` |
| lazygit | `lg` |

## Homebrew

| 场景 | 命令 |
|---|---|
| 更新所有 | `brewup` |
| 安装 | `bi 包名` |
| 卸载 | `bu 包名` |
| 搜索 | `bs 关键词` |
| 已装列表 | `bl` |
| 同步 Brewfile | `brew bundle --file=~/dotfiles/Brewfile` |

## mise

| 场景 | 命令 |
|---|---|
| 看管了哪些 | `mise list` |
| 看配置 | `mise config` |
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
