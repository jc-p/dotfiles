# ==============================================
# 函数
# ==============================================

# mkdir + cd
mkcd() { mkdir -p "$1" && cd "$1"; }

# fzf + zoxide 跳目录
fcd() {
  local dir
  dir=$(zoxide query -l | fzf) || return
  cd "$dir"
}

# fzf 杀进程
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [ -n "$pid" ] && kill -9 $pid
}

# fzf 切分支
fbr() {
  local b
  b=$(git branch -a | sed 's/^[* ] //; s#remotes/origin/##' | grep -v HEAD | sort -u | fzf) || return
  git checkout "$b"
}

# fzf 看 commit
fshow() {
  local c
  c=$(git log --oneline --color=always | fzf --ansi) || return
  git show "${c%% *}"
}

# fzf stash
fstash() {
  local s
  s=$(git stash list | fzf | cut -d: -f1) || return
  git stash pop "$s"
}

# --- ripgrep + fzf 封装 ---

# ff —— 找文件，回车用 $EDITOR 打开
ff() {
  local file
  file=$(rg --files --hidden --glob '!.git' --glob '!node_modules' \
    | fzf --height 90% --layout=reverse --border \
        --preview 'bat --style=numbers --color=always --line-range=:200 {} 2>/dev/null || cat {}' \
        --preview-window 'right:60%') || return
  [ -z "$file" ] && return
  ${EDITOR:-vim} "$file"
}

# fg —— 搜内容，回车跳到对应行
fg() {
  local result
  result=$(rg --line-number --no-heading --color=always --smart-case \
    --glob '!.git' --glob '!node_modules' "$@" \
    | fzf --ansi --height 90% --layout=reverse --border \
        --delimiter : \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
        --preview-window 'right:60%:+{2}') || return
  [ -z "$result" ] && return
  local file line
  file=$(echo "$result" | cut -d: -f1)
  line=$(echo "$result" | cut -d: -f2)
  ${EDITOR:-vim} "+$line" "$file"
}


# ==============================================
# 更多搜索封装
# ==============================================

# fh —— 搜历史命令，回车执行
fh() {
  local cmd
  cmd=$(history -1000 | fzf --tac --height 90% --layout=reverse --no-sort) || return
  [ -z "$cmd" ] && return
  # 去掉历史编号
  cmd=$(echo "$cmd" | sed 's/^ *[0-9]* *//')
  print -s "$cmd"           # 加入历史
  eval "$cmd"
}

# fgl —— 搜 git log，回车看详情
fgl() {
  local commit
  commit=$(git log --oneline --color=always | fzf --ansi --height 90% --layout=reverse \
    --preview 'git show --color=always {1}' \
    --preview-window 'right:60%') || return
  [ -z "$commit" ] && return
  git show "${commit%% *}"
}

# fgd —— 搜 git diff（未提交的改动）
fgd() {
  local file
  file=$(git diff --name-only | fzf --height 90% --layout=reverse \
    --preview 'git diff --color=always {}' \
    --preview-window 'right:60%') || return
  [ -z "$file" ] && return
  ${EDITOR:-vim} "$file"
}

# fdir —— 在目录间跳（不用 zoxide，纯 fd）
fdir() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --height 90% --layout=reverse) || return
  [ -z "$dir" ] && return
  cd "$dir"
}

# rgv —— 搜内容 + 预览 vim 打开（fg 的轻量版，不开 preview）
rgv() {
  local result
  result=$(rg --line-number --no-heading --color=never "$@" | fzf --height 90% --layout=reverse) || return
  [ -z "$result" ] && return
  local file line
  file=$(echo "$result" | cut -d: -f1)
  line=$(echo "$result" | cut -d: -f2)
  ${EDITOR:-vim} "+$line" "$file"
}

# replace —— 批量替换（先预览，确认后执行）
replace() {
  if [ $# -lt 2 ]; then
    echo "用法: replace <旧字符串> <新字符串>"
    return 1
  fi
  local old="$1" new="$2"
  echo "将在以下文件中替换:"
  rg -l "$old" || { echo "没有匹配"; return 0; }
  echo ""
  read "confirm?执行替换? [y/N] "
  [[ "$confirm" == "y" || "$confirm" == "Y" ]] || { echo "取消"; return 0; }
  rg -l "$old" | xargs sed -i '' "s|$old|$new|g"
  echo "✅ 完成"
}

# ==============================================
# 更多搜索封装
# ==============================================

# fh —— 搜历史命令，回车执行
fh() {
  local cmd
  cmd=$(history -1000 | fzf --tac --height 90% --layout=reverse --no-sort) || return
  [ -z "$cmd" ] && return
  cmd=$(echo "$cmd" | sed 's/^ *[0-9]* *//')
  print -s "$cmd"
  eval "$cmd"
}

# fgl —— 搜 git log，回车看详情
fgl() {
  local commit
  commit=$(git log --oneline --color=always | fzf --ansi --height 90% --layout=reverse \
    --preview 'git show --color=always {1}' \
    --preview-window 'right:60%') || return
  [ -z "$commit" ] && return
  git show "${commit%% *}"
}

# fgd —— 搜 git diff（未提交的改动），回车用编辑器打开
fgd() {
  local file
  file=$(git diff --name-only | fzf --height 90% --layout=reverse \
    --preview 'git diff --color=always {}' \
    --preview-window 'right:60%') || return
  [ -z "$file" ] && return
  ${EDITOR:-vim} "$file"
}

# fdir —— 纯 fd 版目录跳转
fdir() {
  local dir
  dir=$(fd --type d --hidden --exclude .git | fzf --height 90% --layout=reverse) || return
  [ -z "$dir" ] && return
  cd "$dir"
}

# rgv —— 搜内容 + 直接 vim 打开（无预览，快）
rgv() {
  local result
  result=$(rg --line-number --no-heading --color=never "$@" | fzf --height 90% --layout=reverse) || return
  [ -z "$result" ] && return
  local file line
  file=$(echo "$result" | cut -d: -f1)
  line=$(echo "$result" | cut -d: -f2)
  ${EDITOR:-vim} "+$line" "$file"
}

# replace —— 批量替换（先列出文件，确认后执行）
replace() {
  if [ $# -lt 2 ]; then
    echo "用法: replace <旧字符串> <新字符串>"
    return 1
  fi
  local old="$1" new="$2"
  local files
  files=$(rg -l "$old" 2>/dev/null) || { echo "没有匹配"; return 0; }

  echo "将在以下文件中替换:"
  echo "$files"
  echo ""
  read "confirm?执行替换? [y/N] "
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "取消"
    return 0
  fi

  echo "$files" | while read -r f; do
    sed -i '' "s|$old|$new|g" "$f"
  done
  echo "✅ 完成"
}
