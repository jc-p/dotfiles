# 新 Mac 迁移

目标是恢复核心命令与使用习惯，只迁移选定的工具。公开仓库负责通用配置，本机隐私内容通过私下恢复或重新授权处理。

## 1. 准备核心工具

先完成 macOS 开发命令行工具与 Homebrew 安装；本仓库不执行系统安装。安装 Homebrew 后：

```bash
brew install chezmoi
chezmoi init https://github.com/jc-p/dotfiles.git
dotfiles_source="$(chezmoi source-path)"
bash "$dotfiles_source/scripts/bootstrap.sh"
bash "$dotfiles_source/scripts/check.sh"
```

安装脚本只在显式执行时下载：先安装 Brewfile，再用 Homebrew mise 安装源码声明的 Node 24、Python 3.12、pnpm 10，并生成 shims。检查离线运行；不要求先把配置应用到家目录。

## 2. 备份并准备本机文件

按 README 备份现有目标，创建缺失的本机文件。已有文件保持原样：

- `env.local.zsh` / `local.zsh`：只带需要的本机环境和工作入口。
- `.gitconfig.local`：填写真实身份；凭据助手按新机安装态选择。
- `.ssh/config.local`：只保留仍使用的主机配置；密钥私下恢复或新建并授权。
- `99-machine.local.toml`：只选择实际需要的版本，不带旧机器 symlink。
- `.vimrc.local`：只保留本机字体和 GUI 设置。

本机文件权限使用 600，SSH 目录使用 700。`.npmrc`、登录态、私有服务、Token、密钥不进入公开仓库；保留需要的登录配置，重新授权工具。不要公开打包整个 home。

## 3. 恢复通用习惯

分模块预览，再应用；现有机器先完成备份，不使用无审阅的强制覆盖：

```bash
chezmoi diff ~/.zshrc ~/.config/zsh ~/.ripgreprc
chezmoi diff ~/.gitconfig ~/.ssh/config ~/.config/mise
chezmoi diff ~/.vimrc ~/.vim/plug-snapshot.vim ~/.config/starship.toml
chezmoi --dry-run apply
chezmoi apply
zsh -li "$dotfiles_source/scripts/verify.zsh"
```

Git 四个核心缩写、rg 搜索规则、fzf、zoxide、提示符和 Vim 配置均来自仓库。Oh My Zsh 可选；最后用原生 mise shims 激活，项目配置仍可选择其他运行时版本。shims 不自动加载项目环境变量，这类命令用 `mise exec -- 命令` 执行。Vim 插件须按 README 显式安装，不随启动下载。

## 4. 按需准备工作环境

Java/Maven 的本机选择示例是 `examples/99-work.local.toml.example`。核对目标 Mac 架构、项目要求和完整版本后，将需要的配置合入本机 `conf.d/*.local.toml`，再显式运行 `mise install`。当前示例选择 Java 8 / Maven 3.6.3；ARM 安装与项目构建尚未验证。不要沿用旧机器 JAVA_HOME/MAVEN_HOME 的绝对路径。

Codex、Claude、Pi、markitdown、cht.sh 等额外命令不属于默认核心安装。只安装选定入口；个人脚本、skills、MCP 配置要另行筛选，凭据重新授权。主用 IDE、终端、容器和文件管理器的配置尚未纳入同步，不能假定仅安装程序就能恢复其快捷键。

`Brewfile.optional` 只安装实际需要的条目；执行 `--optional` 会安装该文件全部内容，先删减再运行。`nv` 需要 Neovim，`y` 需要 yazi；不要为已经不用的入口安装依赖。

## 5. 不迁移的内容

- Homebrew 依赖全集、旧版本 keg、安装缓存。
- mise/pyenv/Cargo 的运行时、symlink、下载目录；按版本重新安装。
- node_modules、虚拟环境、构建产物、容器镜像、日志。
- 命令历史默认不带；其中可能含隐私值。
- 多套同用途终端、字体、跳转、资源监控与文件管理工具。
- 不再使用的代理、私有主机、服务和全局包。

macOS 自带 curl/grep/sed 保留，tree 使用 eza。确有 GNU 行为要求时再为对应项目安装，不放进默认核心。

## 6. 验收与回退

`check.sh` 验证配置、安装器失败中止、无 OMZ 的 Git 缩写和独立目标应用；`verify.zsh` 必须以 `zsh -li` 运行，验证实际核心命令、运行时版本、Git 身份存在性、SSH 解析和待同步状态，不安装软件、不连接 SSH。

人工验收：终端字体与显示、Ctrl-R/Ctrl-T、自动建议与语法高亮、ff 返回路径、z 跳目录、Vim 空格+c，以及一个代表性项目的开发命令。字体存在不等于终端已选中它，Git 身份存在不等于值填写正确，最后两项需人工确认。

恢复 README 的备份可回退已存在文件；首次应用新建的目标逐项核对。安装脚本与新 Mac 的完整网络安装尚未实机验证，替身测试不能替代平台安装验证。
