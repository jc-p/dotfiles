# ==============================================
# 环境变量 / PATH
# ==============================================
export LANG=en_US.UTF-8
export EDITOR=vim

# zsh PATH 数组自动去重
typeset -U path

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# 用户工具优先
path=(
  $HOME/.local/bin
  /opt/homebrew/opt/grep/libexec/gnubin
  $path
)
