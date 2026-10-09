#!/usr/bin/env bash
# 仅在显式执行时安装软件；配置 apply/update 不触发安装。
set -euo pipefail

include_optional=false
case "${1:-}" in
  '') ;;
  --optional) include_optional=true ;;
  -h|--help)
    printf '用法: bash scripts/bootstrap.sh [--optional]\n'
    exit 0
    ;;
  *) printf '未知参数: %s\n' "$1" >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
  printf '只支持一个可选参数 --optional\n' >&2
  exit 2
fi
if ! command -v brew >/dev/null 2>&1; then
  printf '未找到 Homebrew，请先按官方说明安装，再运行此脚本。\n' >&2
  exit 1
fi

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# 只准备声明的依赖，避免安装时顺带更新 taps 或清理其他旧版本。
# 这些设置只作用于本脚本及其子进程；brew update/cleanup 由用户另行执行。
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1
brew bundle --file="$source_dir/Brewfile"
# 固定使用刚安装的 Homebrew mise，避免旧 ~/.local/bin/mise 抢占。
mise_bin="$(brew --prefix mise)/bin/mise"
if [[ ! -x "$mise_bin" ]]; then
  printf 'Homebrew mise 不可执行: %s\n' "$mise_bin" >&2
  exit 1
fi
# 安装源目录声明的核心版本，初始化阶段不依赖已应用的家目录配置。
(
  cd "$source_dir"
  MISE_CONFIG_DIR="$source_dir/dot_config/mise" "$mise_bin" install
  "$mise_bin" reshim
)
if [[ "$include_optional" == true ]]; then
  brew bundle --file="$source_dir/Brewfile.optional"
fi
printf '核心工具已准备；运行 bash scripts/check.sh，再备份、预览并应用配置。\n'
