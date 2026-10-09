# 通用配置依赖；仅通过 scripts/bootstrap.sh 显式安装。
brew "chezmoi"
brew "bash"  # rx 使用 Bash 4+ 特性，不使用 macOS 自带的 Bash 3。
brew "argc"  # gx、omc-build、rx 的参数解析与补全。
brew "rsync" # rx 的传输依赖。
brew "git"
brew "git-delta"
brew "jq"
brew "ripgrep"
brew "fd"
brew "bat"
brew "eza"
brew "fzf"
brew "zoxide"
brew "starship"
brew "mise"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# ls/Vim 使用图标，只迁移一种字体。
if OS.mac?
  cask "font-hack-nerd-font"
end
