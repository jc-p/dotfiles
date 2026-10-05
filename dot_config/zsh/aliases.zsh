# ==============================================
# 别名
# ==============================================

# --- 文件查看 ---
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
  alias la='ls -A'
fi

if command -v bat &>/dev/null; then
  alias cat='bat --style=plain --pager=never'
fi

# --- 基础 ---
alias c='clear'
alias h='history'
alias reload='source ~/.zshrc'
alias df='df -h'
alias ports='lsof -i -P -n | grep LISTEN'
alias ..='cd ..'
alias ...='cd ../..'
alias vzsh='vim ~/.zshrc'          # 主入口
alias vza='vim ~/dotfiles/zsh/aliases.zsh'    # 别名
alias vzf='vim ~/dotfiles/zsh/functions.zsh'  # 函数

# --- ripgrep 默认参数 ---
if command -v rg &>/dev/null; then
  alias rg='rg --smart-case --hidden --glob "!.git"'
fi

# --- Git ---
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch --all --prune'
alias gst='git stash'
alias gstp='git stash pop'

# --- lazygit ---
if command -v lazygit &>/dev/null; then
  alias lg='lazygit'
fi

# --- Homebrew ---
if command -v brew &>/dev/null; then
  alias brewup='brew update && brew upgrade && brew cleanup'
  alias bi='brew install'
  alias bu='brew uninstall'
  alias bs='brew search'
  alias bl='brew list'
  alias bup='brew update && brew upgrade'
  alias bcu='brew cleanup'
fi
