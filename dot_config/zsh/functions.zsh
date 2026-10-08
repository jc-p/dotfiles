# 通用交互函数；本机覆盖放在 local.zsh。

# EDITOR 支持命令及参数，按 shell 单词拆分，但不执行字符串中的代码。
_dotfiles_edit() {
  local -a editor
  editor=("${(@Q)${(z)${EDITOR:-vim}}}")
  command "${editor[@]}" "$@"
}

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

fbr() {
  setopt localoptions pipefail
  local branch
  branch=$(git branch -a | sed 's/^[* ] //; s#remotes/origin/##' | grep -v HEAD | sort -u | fzf) || return
  [[ -n "$branch" ]] && git checkout "$branch"
}

fshow() {
  fgl "$@"
}

fstash() {
  setopt localoptions pipefail
  local stash
  stash=$(git stash list | fzf | cut -d: -f1) || return
  [[ -n "$stash" ]] && git stash pop "$stash"
}

# ff 返回路径；fe 打开编辑器，保留原有调用契约。
__pjc_fzf_file_source() {
  if [[ -n "${FZF_DEFAULT_COMMAND:-}" ]]; then
    eval "$FZF_DEFAULT_COMMAND"
  elif command -v rg >/dev/null 2>&1; then
    rg --files --hidden --follow -g '!.git' -g '!node_modules' -g '!dist' -g '!build' -g '!coverage' -g '!.qoder'
  else
    print -u2 'fzf file source requires fd or rg'
    return 1
  fi
}

__pjc_fzf_preview_cmd() {
  if command -v bat >/dev/null 2>&1; then
    print -r -- 'bat --style=numbers --color=always --line-range=:200 {}'
  else
    print -r -- "sed -n '1,200p' {}"
  fi
}

ff() {
  setopt localoptions pipefail
  local file
  file="$(__pjc_fzf_file_source | fzf --preview "$(__pjc_fzf_preview_cmd)" --preview-window='right:60%,border-left')" || return
  [[ -n "$file" ]] && print -r -- "$file"
}

fe() {
  local file
  file="$(ff)" || return
  [[ -n "$file" ]] && _dotfiles_edit "$file"
}

fcode() {
  local file
  file="$(ff)" || return
  [[ -n "$file" ]] && code "$file"
}


# 避免覆盖用于前台作业控制的内置 fg 命令。
fsearch() {
  setopt localoptions pipefail
  local result file line
  result=$(rg --line-number --no-heading --color=never --smart-case \
    --glob '!.git' --glob '!node_modules' "$@" \
    | fzf --height 90% --layout=reverse --border \
        --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} --line-range=:200 {1} 2>/dev/null || head -n 200 {1}' \
        --preview-window 'right:60%:+{2}') || return
  [[ -n "$result" ]] || return
  file="${result%%:*}"
  result="${result#*:}"
  line="${result%%:*}"
  _dotfiles_edit "+$line" "$file"
}

fh() {
  setopt localoptions pipefail
  local selected_command
  selected_command=$(fc -ln -1000 | fzf --tac --height 90% --layout=reverse --no-sort) || return
  [[ -n "$selected_command" ]] || return
  # 只填入下一次命令行，保留用户检查和修改的机会。
  print -z -- "$selected_command"
}

fgl() {
  setopt localoptions pipefail
  local commit
  commit=$(git log --oneline --color=always | fzf --ansi --height 90% --layout=reverse \
    --preview 'git show --color=always {1} | head -n 200' \
    --preview-window 'right:60%') || return
  [[ -n "$commit" ]] && git show "${commit%% *}"
}

fgd() {
  setopt localoptions pipefail
  local file
  file=$(git diff --name-only | fzf --height 90% --layout=reverse \
    --preview 'git diff --color=always {} | head -n 200' \
    --preview-window 'right:60%') || return
  [[ -n "$file" ]] && _dotfiles_edit "$file"
}

fdir() {
  setopt localoptions pipefail
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --height 90% --layout=reverse) || return
  [[ -n "$dir" ]] && cd -- "$dir"
}

rgv() {
  setopt localoptions pipefail
  local result file line
  result=$(rg --line-number --no-heading --color=never "$@" | fzf --height 90% --layout=reverse) || return
  [[ -n "$result" ]] || return
  file="${result%%:*}"
  result="${result#*:}"
  line="${result%%:*}"
  _dotfiles_edit "+$line" "$file"
}

replace() {
  # 标准库实现字面替换、差异预览和单文件原子写入，不依赖 BSD/GNU sed。
  command python3 "$HOME/.config/zsh/replace.py" "$@"
}

frg() {
  setopt localoptions pipefail
  if [[ $# -eq 0 ]]; then
    print -u2 'usage: frg <pattern>'
    return 2
  fi

  local selected file line preview
  if command -v bat >/dev/null 2>&1; then
    preview='bat --style=numbers --color=always --highlight-line {2} --line-range=:240 {1}'
  else
    preview="sed -n '1,240p' {1}"
  fi

  selected="$(rg --line-number --column --no-heading --color=never --smart-case "$@" | fzf --delimiter : --preview "$preview" --preview-window='right:60%,border-left')" || return
  file="$(print -r -- "$selected" | cut -d: -f1)"
  line="$(print -r -- "$selected" | cut -d: -f2)"
  [[ -n "$file" && -n "$line" ]] && _dotfiles_edit "+$line" "$file"
}

frcode() {
  setopt localoptions pipefail
  if [[ $# -eq 0 ]]; then
    print -u2 'usage: frcode <pattern>'
    return 2
  fi

  local selected file line preview
  if command -v bat >/dev/null 2>&1; then
    preview='bat --style=numbers --color=always --highlight-line {2} --line-range=:240 {1}'
  else
    preview="sed -n '1,240p' {1}"
  fi

  selected="$(rg --line-number --column --no-heading --color=never --smart-case "$@" | fzf --delimiter : --preview "$preview" --preview-window='right:60%,border-left')" || return
  file="$(print -r -- "$selected" | cut -d: -f1)"
  line="$(print -r -- "$selected" | cut -d: -f2)"
  [[ -n "$file" && -n "$line" ]] && code -g "$file:$line"
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
