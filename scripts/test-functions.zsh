#!/usr/bin/env zsh
# ps/fzf/kill 使用测试替身；不查看真实进程、不发送信号、不执行历史命令。
set -eu
test_source_dir="${0:A:h:h}"
source "${0:A:h:h}/dot_config/zsh/functions.zsh"

[[ "$(whence -w fg)" == 'fg: builtin' ]]

typeset -a captured_kill
ps() { print -r -- '111 sample'; print -r -- '222 sample'; }
fzf() { command cat; }
kill() { captured_kill=("$@"); }
fkill <<< y >/dev/null
[[ "${captured_kill[*]}" == '-s TERM -- 111 222' ]]
[[ ${#captured_kill} -eq 5 ]]
fkill --force <<< y >/dev/null
[[ "${captured_kill[*]}" == '-s KILL -- 111 222' ]]
captured_kill=()
fkill <<< n >/dev/null
[[ ${#captured_kill} -eq 0 ]]
fzf() { return 130; }
if fkill <<< y >/dev/null; then
  print -u2 '取消选择应返回非零'; exit 1
fi
[[ ${#captured_kill} -eq 0 ]]

typeset history_executed=false
fc() { print -r -- 'history_executed=true'; }
fzf() { command cat; }
fh
[[ "$history_executed" == false ]]
read -r -z queued_command
[[ "$queued_command" == 'history_executed=true' ]]

EDITOR="/usr/bin/printf '%s\\n'"
[[ "$(_dotfiles_edit 'space name.txt')" == 'space name.txt' ]]
FZF_DEFAULT_COMMAND="printf 'space name.txt\\n'"
sx() { command python3 "$test_source_dir/dot_local/bin/executable_sx" "$@"; }
export FZF_DEFAULT_OPTS='--filter="space name.txt"'
[[ "$(ff)" == 'space name.txt' ]]
alias gc='git commit --verbose'
alias gst='git status'
source "${0:A:h:h}/dot_config/zsh/aliases.zsh"
[[ "${aliases[gc]}" == 'git commit --verbose' ]]
[[ "${aliases[gst]}" == 'git status' ]]
[[ "${aliases[gl]}" == 'git pull' ]]
[[ "${aliases[gca]}" == 'git commit --verbose --all' ]]
print 'Zsh 行为检查通过：fg、多选 PID、取消、历史填入、EDITOR、ff、固定 Git 缩写'
