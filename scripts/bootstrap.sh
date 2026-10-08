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
brew bundle --file="$source_dir/Brewfile"
if [[ "$include_optional" == true ]]; then
  brew bundle --file="$source_dir/Brewfile.optional"
fi
