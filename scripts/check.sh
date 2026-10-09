#!/usr/bin/env bash
# 仅检查仓库中本次维护的配置和函数，不安装依赖、不应用家目录配置。
set -euo pipefail
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$source_dir"

# 优先选用源码声明的 Python；检查过程离线且不安装缺失运行时。
python_bin="$(command -v python3 || true)"
if command -v mise >/dev/null 2>&1; then
  if selected_python=$(MISE_CONFIG_DIR="$source_dir/dot_config/mise" MISE_AUTO_INSTALL=0 MISE_OFFLINE=1 mise which python3 2>/dev/null); then
    python_bin="$selected_python"
  fi
fi
if [[ -z "$python_bin" ]] || ! "$python_bin" -c 'import sys; raise SystemExit(sys.version_info < (3, 11))'; then
  printf '检查需要 Python 3.11+；先运行 scripts/bootstrap.sh 准备核心运行时。\n' >&2
  exit 1
fi

for file in dot_zshrc dot_config/zsh/*.zsh scripts/*.zsh; do
  zsh -f -n "$file"
done
for file in scripts/bootstrap.sh scripts/check.sh; do
  bash -n "$file"
done
for file in dot_local/bin/executable_gx dot_local/bin/executable_omc-build dot_local/bin/executable_rx; do
  bash -n "$file"
done
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/bootstrap.sh scripts/check.sh
fi
ruby -c Brewfile
ruby -c Brewfile.optional
export PYTHONDONTWRITEBYTECODE=1
"$python_bin" - <<'PY'
import ast
from pathlib import Path
import subprocess
import tomllib

paths = [Path('dot_config/mise/config.toml'),
         Path('dot_config/mise/conf.d/00-common.toml'), *Path('examples').glob('*.toml.example')]
for path in paths:
    with path.open('rb') as stream:
        tomllib.load(stream)
# 原生渲染后检查模板，避免把模板源码误当成 TOML。
rendered = subprocess.run(
    ['chezmoi', '--source', str(Path.cwd()), 'execute-template', '--file',
     'dot_config/starship.toml.tmpl'], capture_output=True, text=True, check=True,
)
tomllib.loads(rendered.stdout)
for path in [Path('dot_config/zsh/replace.py'), Path('dot_local/bin/executable_sx'),
             Path('dot_local/bin/executable_dev-tools'), *Path('scripts').glob('test_*.py')]:
    ast.parse(path.read_text(), filename=str(path))
print('TOML 与 Python 语法检查通过')
PY
zsh -f scripts/test-functions.zsh
"$python_bin" scripts/test_replace.py
"$python_bin" scripts/test_config.py
"$python_bin" scripts/test_migration.py
"$python_bin" scripts/test_tools.py
"$python_bin" scripts/test_help.py
printf '配置与函数检查通过\n'
