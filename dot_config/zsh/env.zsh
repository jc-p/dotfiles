# ==============================================
# 环境变量 / PATH
# ==============================================
export LANG="${LANG:-en_US.UTF-8}"
export EDITOR="${EDITOR:-vim}"

# zsh PATH 数组自动去重
typeset -U path

# Homebrew
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 用户工具优先
path=(
  $HOME/.local/bin
  $path
)

# 通用工具偏好，允许本机 env.local.zsh 覆盖。
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.ripgreprc}"
export TLDR_LANGUAGE="zh"
