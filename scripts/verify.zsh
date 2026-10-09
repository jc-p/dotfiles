#!/bin/zsh -li
# 应用后的本机验收；用 zsh -li scripts/verify.zsh 启动完整登录 Shell。
# 只验证核心工具，不安装软件、不打印环境变量、不连接 SSH 服务器。
# 登录 Shell 已加载第三方 hooks；不用全局 errexit/nounset，逐项显式检查失败。
source_dir="${0:A:h:h}"
cd "$source_dir" || exit 1
export MISE_OFFLINE=1 MISE_AUTO_INSTALL=0

for tool in chezmoi git delta jq rg fd bat eza fzf zoxide starship mise node python3 pnpm bash argc rsync gx sx omc-build rx; do
  command -v "$tool" >/dev/null 2>&1 || { print -u2 "缺少核心工具: $tool"; exit 1; }
done
command bash -c '(( BASH_VERSINFO[0] >= 4 ))' || { print -u2 'rx 需要 Bash 4+，请检查 PATH'; exit 1; }
for tool in gx sx omc-build rx; do
  command "$tool" --help >/dev/null 2>&1 || { print -u2 "$tool 帮助入口失败"; exit 1; }
done
for retired in ff fe fcode fsearch rgv frg frcode fbr fgl fgd fstash fshow; do
  if (( $+functions[$retired] || $+aliases[$retired] )); then
    print -u2 "旧入口仍存在: $retired，请检查本机覆盖或重新加载配置"; exit 1
  fi
done

for tool in node python3 pnpm; do
  actual=$(command "$tool" --version) || exit 1
  selected=$(command mise exec -- "$tool" --version) || exit 1
  [[ "$actual" == "$selected" ]] || {
    print -u2 "$tool 实际版本 $actual 与 mise 选择的 $selected 不一致"; exit 1
  }
  print -r -- "$tool: $actual"
done
[[ "${aliases[gc]:-}" == 'git commit --verbose' &&
   "${aliases[gl]:-}" == 'git pull' && "${aliases[gst]:-}" == 'git status' &&
   "${aliases[gca]:-}" == 'git commit --verbose --all' ]] || {
  print -u2 '核心 Git 别名不符合迁移基线，请检查 local.zsh 覆盖'; exit 1
}
[[ "$(whence -w fg)" == 'fg: builtin' ]] || { print -u2 'fg 已被覆盖'; exit 1; }
git config --get user.name >/dev/null || { print -u2 '请填写 ~/.gitconfig.local 的 user.name'; exit 1; }
git config --get user.email >/dev/null || { print -u2 '请填写 ~/.gitconfig.local 的 user.email'; exit 1; }
ssh -G -F "$HOME/.ssh/config" example.invalid >/dev/null 2>&1 || { print -u2 'SSH 配置解析失败'; exit 1; }

pending=$(chezmoi --source "$source_dir" status "$HOME/.zshrc" "$HOME/.config/zsh" \
  "$HOME/.config/mise" "$HOME/.config/starship.toml" "$HOME/.ripgreprc" \
  "$HOME/.gitconfig" "$HOME/.ssh/config" "$HOME/.vimrc" "$HOME/.vim/plug-snapshot.vim" \
  "$HOME/.local/bin/gx" "$HOME/.local/bin/sx" "$HOME/.local/bin/omc-build" "$HOME/.local/bin/rx") || exit 1
[[ -z "$pending" ]] || { print -u2 '通用配置仍有待同步项，请分模块预览并应用'; exit 1; }
print '本机核心迁移验收通过；终端字体、交互快捷键和项目命令仍需人工验收。'
