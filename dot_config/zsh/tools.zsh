# ==============================================
# 工具初始化
# ==============================================
# starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# mise
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# fzf
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
fi
