# ==============================================
# 别名
# ==============================================

# --- 文件查看 ---
if command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza --icons -l'
  alias la='eza --icons -la'
  alias tree='eza --icons --tree'
  alias lt='eza --tree --level=2 --icons'
else
  if [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
  else
    alias ls='ls --color=auto'
  fi
  alias ll='ls -lah'
  alias la='ls -A'
fi

if command -v bat &>/dev/null; then
  alias cat='bat'
fi

# --- 基础 ---
# 本模块在 OMZ 之后加载，清退插件可能带回的重复入口；本机仍可最后覆盖。
for legacy_alias in c reload gpl; do
  if (( $+aliases[$legacy_alias] )); then
    unalias "$legacy_alias"
  fi
done
unset legacy_alias
alias cls='clear'
alias h='history'
alias szsh='source ~/.zshrc'
alias df='df -h'
alias ports='lsof -i -P -n | grep LISTEN'
alias ..='cd ..'
alias ...='cd ../..'
alias vzsh='chezmoi edit ~/.zshrc'
alias vza='chezmoi edit ~/.config/zsh/aliases.zsh'
alias vzf='chezmoi edit ~/.config/zsh/functions.zsh'

# --- Git：固定当前习惯，不依赖 OMZ；local.zsh 仍可最后覆盖 ---
(( $+aliases[g] )) || alias g='git'
(( $+aliases[gs] )) || alias gs='git status -sb'
(( $+aliases[ga] )) || alias ga='git add'
(( $+aliases[gaa] )) || alias gaa='git add --all'
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
(( $+aliases[gco] )) || alias gco='git checkout'
(( $+aliases[gcb] )) || alias gcb='git checkout -b'
(( $+aliases[gb] )) || alias gb='git branch'
(( $+aliases[gd] )) || alias gd='git diff'
alias gl='git pull'
(( $+aliases[gp] )) || alias gp='git push'
(( $+aliases[gf] )) || alias gf='git fetch --all --prune'
alias gst='git status'
(( $+aliases[gstp] )) || alias gstp='git stash pop'

# --- lazygit ---
if command -v lazygit &>/dev/null; then
  alias lg='lazygit'
fi

# --- Homebrew ---
if command -v brew &>/dev/null; then
  alias brewup='brew update && brew upgrade && brew cleanup'
  alias bi='brew install'
  (( $+aliases[bu] )) || alias bu='brew uninstall'
  alias bs='brew search'
  alias bl='brew list'
  (( $+aliases[bup] )) || alias bup='brew update && brew upgrade'
  alias bcu='brew cleanup'
fi

# 从现有配置迁入的通用快捷方式。
alias vprofile='vim ~/.zprofile'
alias vzshenv='vim ~/.zshenv'
alias vhosts='sudo vim /etc/hosts'

alias f='fzf'
command -v markitdown >/dev/null 2>&1 && alias md='markitdown'
command -v cht.sh >/dev/null 2>&1 && alias cs='cht.sh'
alias rgf='rg --files'
alias rgl='rg -l'
alias rgt='rg -t'
alias rge='rg -g'
alias rgc='rg -n -C 3'
alias rgtx='rg -t ts -t tsx'
alias rgj='rg -t js -t jsx -t ts -t tsx'
if command -v delta >/dev/null 2>&1; then
  alias gd='git diff'
  alias gdc='git diff --cached'
  alias gds='git diff --stat'
fi
alias d='dirs -v'
alias cpath='pwd | pbcopy'
alias pyrun='python3'
command -v nvim >/dev/null 2>&1 && alias nv='nvim'
command -v neovide >/dev/null 2>&1 && alias nvd='neovide --frame=none --maximized'

alias gbc='git branch --show-current | pbcopy'
# Verbose file ops
alias cp='cp -v'
alias mv='mv -v'
alias rm='rm -v'
