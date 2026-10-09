# 故障排查

## 配置没有生效

1. 用 `chezmoi source-path ~/.zshrc` 确认当前操作的是哪份源码。
2. 只预览相关目标，例如 `chezmoi diff ~/.zshrc ~/.config/zsh`。
3. 检查本机覆盖文件；Zsh 的环境覆盖先加载，别名和函数覆盖后加载。
4. 执行仓库中的 `bash scripts/check.sh`，再开启新终端检查实际加载。

## 插件或工具缺失

- 配置同步不安装软件。先审阅 Brewfile，再显式运行 `bash scripts/bootstrap.sh`。
- Oh My Zsh 缺失时通用配置仍可用；Zsh 两个插件使用 Homebrew 安装路径。
- 用 `command -v 工具名` 检查命令来源；本机 PATH 放入 `env.local.zsh`。
- mise 不自动下载。用 `mise config ls`、`mise ls --current` 查看加载文件和版本，再按需运行 `mise install`。
- 本机工具版本放入 `conf.d/99-machine.local.toml`；不要把工具写回优先级更高的主 `config.toml`。
- 用 `zsh -li scripts/verify.zsh` 检查首条命令的实际版本是否与 mise 一致；不依赖尚未执行的提示符 hook。
- 不复制旧机器的 mise/pyenv/Cargo 安装目录。运行时 symlink 指向旧目录时，新机需重新安装。
- `gc/gl/gst/gca` 有固定通用含义；若验收失败，检查本机 `local.zsh` 是否主动覆盖了它们。
- Python 版本过旧时先运行安装脚本；检查脚本本身不会下载运行时。

## Git 身份或 SSH 配置

- Git 开启 `useConfigOnly`，提交前在 `~/.gitconfig.local` 填写真实身份，替换示例占位值。
- SSH 主机、密钥路径及 macOS Keychain 选项放入 `~/.ssh/config.local`，权限设为 600。
- `ssh -G -F ~/.ssh/config example.invalid >/dev/null` 可检查配置解析，不建立连接。
- chezmoi 的 `private_` 只控制权限；私有数据不能因此进入公开仓库。

## 搜索与替换

- 内容搜索改名为 `fsearch`；`fg` 保留 Shell 内置作业控制含义。
- `fsearch`、`rgv`、`frg`、`frcode` 统一转调 `sx`；JSON 解析支持含冒号和空格的路径。制表符或换行路径暂不支持，会明确报错。
- 找不到 `sx/gx/rx/omc-build` 时，先确认核心依赖已安装、工具源码已通过 chezmoi 应用，且 `~/.local/bin` 在 PATH；不自动下载安装。`rx` 需要 Homebrew Bash 4+，不能依赖 macOS 自带 Bash 3。
- `replace 旧 新 [文件或目录...]` 执行字面替换，默认遵守 rg 的忽略规则，不搜索隐藏文件。
- 替换前预览全部差异；取消或预览后文件变化都不会开始写入。旧字符串必须非空且为单行，文件必须为 UTF-8 文本，不接受符号链接。
- 确认后的写入按单个文件原子完成；多文件不是整体事务，出现 IO 错误需检查是否已有文件完成。

## Vim 与恢复

- Vim 启动不下载插件；缺少 vim-plug 时按照 README 显式安装。
- 快照赋值错误不再静默忽略；确认快照插件名与 `Plug` 声明一致。
- 保留的主题为 everforest、状态栏为 airline、注释为 NERDCommenter；`空格+c` 调用注释切换，失配的 Coc 映射已移除。
- 回退时恢复 README 中的本机备份；应用新建的文件需要另外核对。
