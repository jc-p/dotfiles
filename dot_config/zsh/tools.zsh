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

# fzf
# fzf: fast file/history search. Prefer fd when available.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude dist --exclude build --exclude coverage --exclude .qoder'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude dist --exclude build --exclude coverage --exclude .qoder'
elif command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g "!.git" -g "!node_modules" -g "!dist" -g "!build" -g "!coverage" -g "!.qoder"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
export FZF_DEFAULT_OPTS='--height 45% --layout=reverse --border --info=inline --cycle'
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS='--preview "bat --style=numbers --color=always --line-range=:200 {}" --preview-window=right:60%,border-left'
else
  export FZF_CTRL_T_OPTS='--preview "sed -n '\''1,200p'\'' {}" --preview-window=right:60%,border-left'
fi
if [[ -o interactive && -t 0 ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# 已有 Zsh 补全系统时注册工具补全，不安装依赖、不另外运行 compinit。
if (( $+functions[compdef] )); then
  if command -v argc >/dev/null 2>&1; then
    source <(argc --argc-completions zsh gx omc-build rx)
  fi
  if command -v sx >/dev/null 2>&1; then
    source <(sx --completions zsh)
  fi
  if command -v dev-tools >/dev/null 2>&1; then
    source <(dev-tools --completions zsh)
  fi
fi
