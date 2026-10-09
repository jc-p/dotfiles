# 通用交互函数；本机覆盖放在 local.zsh。

# 重载时也清退旧入口；文件/内容搜索使用 sx，Git 交互使用 gx。
for retired_function in ff fe fcode fsearch rgv frg frcode fbr fgl fgd fstash fshow _dotfiles_edit __pjc_fzf_file_source; do
  if (( $+functions[$retired_function] )); then
    unfunction "$retired_function"
  fi
  if (( $+aliases[$retired_function] )); then
    unalias "$retired_function"
  fi
done
unset retired_function

mkcd() {
  [[ $# -eq 1 ]] || { print -u2 '用法: mkcd <目录>'; return 2; }
  mkdir -p -- "$1" && cd -- "$1"
}

fcd() {
  setopt localoptions pipefail
  local dir
  dir=$(zoxide query -l | fzf) || return
  [[ -n "$dir" ]] && cd -- "$dir"
}

fkill() {
  setopt localoptions pipefail
  local signal=TERM selected pid confirm
  case "${1:-}" in
    '') ;;
    -9|--force) signal=KILL ;;
    *) print -u2 '用法: fkill [--force|-9]'; return 2 ;;
  esac
  [[ $# -le 1 ]] || return 2
  selected=$(ps -eo pid=,comm= | fzf -m | awk '{print $1}') || return
  [[ -n "$selected" ]] || return
  # Zsh 不自动拆分字符串；逐行生成数组，保证多选传入多个 PID。
  local -a pids
  pids=("${(@f)selected}")
  for pid in "${pids[@]}"; do
    [[ "$pid" == <-> ]] || { print -u2 '进程选择结果不是 PID'; return 1; }
  done
  print -r -- "将发送 $signal: ${pids[*]}"
  read -r "confirm?确认终止? [y/N] " || return
  [[ "$confirm" == [yY] ]] || return 0
  kill -s "$signal" -- "${pids[@]}"
}

fh() {
  setopt localoptions pipefail
  local selected_command
  selected_command=$(fc -ln -1000 | fzf --tac --height 90% --layout=reverse --no-sort) || return
  [[ -n "$selected_command" ]] || return
  # 只填入下一次命令行，保留用户检查和修改的机会。
  print -z -- "$selected_command"
}

fdir() {
  setopt localoptions pipefail
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --height 90% --layout=reverse) || return
  [[ -n "$dir" ]] && cd -- "$dir"
}

replace() {
  # 标准库实现字面替换、差异预览和单文件原子写入，不依赖 BSD/GNU sed。
  command python3 "$HOME/.config/zsh/replace.py" "$@"
}

y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp"
}

pip() { python3 -m pip "$@"; }
pip3() { python3 -m pip "$@"; }
