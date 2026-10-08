#!/usr/bin/env bash
# 仅检查仓库中本次维护的配置和函数，不安装依赖、不应用家目录配置。
set -euo pipefail
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$source_dir"

for file in dot_zshrc dot_config/zsh/*.zsh scripts/test-functions.zsh; do
  zsh -f -n "$file"
done
for file in scripts/bootstrap.sh scripts/check.sh; do
  bash -n "$file"
done
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck scripts/bootstrap.sh scripts/check.sh
fi
ruby -c Brewfile
ruby -c Brewfile.optional
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import ast
from pathlib import Path
import subprocess
import tomllib

paths = [Path('dot_config/mise/config.toml'),
         Path('dot_config/mise/conf.d/00-common.toml'), Path('examples/99-machine.local.toml.example')]
for path in paths:
    with path.open('rb') as stream:
        tomllib.load(stream)
# 原生渲染后检查模板，避免把模板源码误当成 TOML。
rendered = subprocess.run(
    ['chezmoi', '--source', str(Path.cwd()), 'execute-template', '--file',
     'dot_config/starship.toml.tmpl'], capture_output=True, text=True, check=True,
)
tomllib.loads(rendered.stdout)
for path in [Path('dot_config/zsh/replace.py'), Path('scripts/test_replace.py'), Path('scripts/test_config.py')]:
    ast.parse(path.read_text(), filename=str(path))
print('TOML 与 Python 语法检查通过')
PY
zsh -f scripts/test-functions.zsh
python3 scripts/test_replace.py
python3 scripts/test_config.py
printf '配置与函数检查通过\n'
