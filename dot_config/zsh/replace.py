"""交互式字面替换：先预览全部差异，确认后写入。"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import difflib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


@dataclass(frozen=True)
class Change:
    path: Path
    original: bytes
    updated: bytes
    mode: int


def collect_changes(old: str, new: str, paths: list[str]) -> list[Change]:
    """用 rg 筛选文本文件；NUL 分隔确保特殊文件名不被拆开。"""
    if not old or "\n" in old or "\r" in old:
        raise ValueError("旧字符串必须是非空单行文本")
    if shutil.which("rg") is None:
        raise ValueError("未找到 rg，请先显式安装通用工具")
    command = ["rg", "--no-config", "--files-with-matches", "--null", "--fixed-strings"]
    for directory in (".git", "node_modules", "dist", "build", "coverage", ".qoder"):
        command.extend(["--glob", f"!**/{directory}/**"])
    command.extend(["--", old, *(paths or ["."])])
    result = subprocess.run(command, capture_output=True, check=False)
    if result.returncode == 1:
        return []
    if result.returncode != 0:
        raise ValueError(result.stderr.decode(errors="replace").strip() or "rg 搜索失败")
    changes: list[Change] = []
    for filename in dict.fromkeys(result.stdout.rstrip(b"\0").split(b"\0")):
        path = Path(os.fsdecode(filename))
        if path.is_symlink():
            raise ValueError(f"不替换符号链接: {path}")
        original = path.read_bytes()
        original.decode("utf-8")
        updated = original.replace(old.encode("utf-8"), new.encode("utf-8"))
        if original != updated:
            changes.append(Change(path, original, updated, path.stat().st_mode & 0o7777))
    return changes


def apply_changes(changes: list[Change]) -> None:
    """确认后检查漂移；单文件原子替换，多文件不保证整体事务。"""
    for change in changes:
        if change.path.is_symlink() or change.path.read_bytes() != change.original:
            raise ValueError(f"预览后文件已变化，请重新执行: {change.path}")
    for change in changes:
        temporary: Path | None = None
        try:
            with tempfile.NamedTemporaryFile(dir=change.path.parent, delete=False) as stream:
                temporary = Path(stream.name)
                stream.write(change.updated)
                stream.flush()
                os.fchmod(stream.fileno(), change.mode)
            os.replace(temporary, change.path)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="字面替换，预览后确认；默认遵守 rg 忽略规则")
    parser.add_argument("old", help="非空单行旧字符串")
    parser.add_argument("new", help="新字符串，特殊字符按字面处理")
    parser.add_argument("paths", nargs="*", help="限定文件或目录，默认当前目录")
    args = parser.parse_args()
    try:
        changes = collect_changes(args.old, args.new, args.paths)
        if not changes:
            print("没有需要替换的内容")
            return 0
        for change in changes:
            sys.stdout.writelines(difflib.unified_diff(
                change.original.decode("utf-8").splitlines(keepends=True),
                change.updated.decode("utf-8").splitlines(keepends=True),
                fromfile=str(change.path), tofile=str(change.path),
            ))
        if input("\n执行以上替换? [y/N] ").strip().lower() != "y":
            print("取消")
            return 0
        apply_changes(changes)
        print(f"完成：{len(changes)} 个文件")
        return 0
    except (OSError, UnicodeError, ValueError) as error:
        print(f"替换失败：{error}；若已确认写入，请检查是否有文件已完成", file=sys.stderr)
        return 1
    except (EOFError, KeyboardInterrupt):
        print("\n取消")
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
