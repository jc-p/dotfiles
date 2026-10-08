"""只在临时目录验证替换行为，不修改用户配置。"""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPOSITORY / "dot_config/zsh"))
from replace import apply_changes, collect_changes


class ReplaceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory(prefix="dotfiles-replace-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)

    def test_literal_characters_and_special_filenames(self) -> None:
        paths = [self.root / name for name in ("space name.txt", "-leading.txt", "line\nbreak.txt")]
        for path in paths:
            path.write_text("a.*| + a.*|\n", encoding="utf-8")
            path.chmod(0o640)
        changes = collect_changes("a.*|", r"&\new|", [str(path) for path in paths])
        self.assertEqual(len(changes), 3)
        apply_changes(changes)
        for path in paths:
            self.assertEqual(path.read_text(), "&\\new| + &\\new|\n")
            self.assertEqual(path.stat().st_mode & 0o777, 0o640)
        self.assertEqual(set(self.root.iterdir()), set(paths))

    def test_cancellation_does_not_write(self) -> None:
        path = self.root / "sample.txt"
        path.write_text("old\n")
        result = subprocess.run(
            [sys.executable, str(REPOSITORY / "dot_config/zsh/replace.py"), "old", "new", str(path)],
            input="n\n", text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(path.read_text(), "old\n")
        self.assertIn("-old", result.stdout)
        self.assertIn("+new", result.stdout)

    def test_confirmation_writes(self) -> None:
        path = self.root / "sample.txt"
        path.write_text("old\n")
        result = subprocess.run(
            [sys.executable, str(REPOSITORY / "dot_config/zsh/replace.py"), "old", "new", str(path)],
            input="y\n", text=True, capture_output=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(path.read_text(), "new\n")

    def test_drift_aborts_before_any_write(self) -> None:
        first, second = self.root / "first.txt", self.root / "second.txt"
        first.write_text("old")
        second.write_text("old")
        changes = collect_changes("old", "new", [str(first), str(second)])
        second.write_text("edited")
        with self.assertRaises(ValueError):
            apply_changes(changes)
        self.assertEqual(first.read_text(), "old")
        self.assertEqual(second.read_text(), "edited")

    def test_invalid_input_and_search_error(self) -> None:
        with self.assertRaises(ValueError):
            collect_changes("", "new", [str(self.root)])
        with self.assertRaises(ValueError):
            collect_changes("old", "new", [str(self.root / "missing")])

    def test_no_match_or_no_change(self) -> None:
        path = self.root / "sample.txt"
        path.write_text("old")
        self.assertEqual(collect_changes("absent", "new", [str(path)]), [])
        self.assertEqual(collect_changes("old", "old", [str(path)]), [])

    def test_symlink_is_rejected(self) -> None:
        path, link = self.root / "sample.txt", self.root / "link.txt"
        path.write_text("old")
        link.symlink_to(path)
        with self.assertRaises(ValueError):
            collect_changes("old", "new", [str(link)])
        self.assertEqual(path.read_text(), "old")


if __name__ == "__main__":
    unittest.main()
