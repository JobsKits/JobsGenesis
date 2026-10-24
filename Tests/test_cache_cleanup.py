"""递归清理脚本的竞态回归；只使用临时目录，不清理真实仓库。"""

import argparse
from contextlib import redirect_stdout
import io
from pathlib import Path
import shutil
import subprocess
import tempfile
import types
import unittest
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / '【MacOS】🧹清理缓存与构建产物.command'
PYTHON = SCRIPT.read_text().split("<<'PYTHON'\n", 1)[1].split('\nPYTHON\n', 1)[0]


class CacheCleanupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='jobs-clean-scan-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.cleaner = types.ModuleType('cleaner')
        # 使用真正嵌入脚本的全部函数，入口参数在夹具内注入。
        definitions = PYTHON.split('\nROOT = Path(sys.argv[1])', 1)[0]
        exec(compile(definitions, str(SCRIPT), 'exec'), self.cleaner.__dict__)
        self.cleaner.ROOT = self.root
        self.cleaner.ROOT_DEVICE = self.root.stat().st_dev
        self.cleaner.ARGS = argparse.Namespace(cache_only=False, dry_run=True, yes=False)
        self.output = io.StringIO()
        self.redirect = redirect_stdout(self.output)
        self.redirect.__enter__()
        self.addCleanup(self.redirect.__exit__, None, None, None)
        self.survivor = self.make_file('.cache/keep-scanning')

    def make_file(self, relative, content='fixture'):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def assert_only_survivor_planned(self, targets):
        self.assertEqual([target[0] for target in targets], [self.survivor.parent])
        self.assertTrue(self.survivor.exists(), '扫描不能删除任何其它文件')
        self.assertIn('扫描时路径', self.output.getvalue())

    def run_cleanup(self, targets):
        self.cleaner.ARGS.dry_run = False
        self.cleaner.ARGS.yes = True
        with mock.patch.object(self.cleaner, 'plan_cleanup', return_value=targets):
            return self.cleaner.main()

    def test_listed_entry_disappears_before_stat(self):
        vanished = self.make_file('disappearing.pyc')
        original = self.cleaner.os.scandir
        root = self.root

        class ScandirThenRemove:
            def __enter__(self):
                self.entries = original(root)
                return self.entries.__enter__()

            def __exit__(self, *args):
                result = self.entries.__exit__(*args)
                vanished.unlink()
                return result

        def scan(path):
            return ScandirThenRemove() if Path(path) == root else original(path)

        with mock.patch.object(self.cleaner.os, 'scandir', side_effect=scan):
            targets = self.cleaner.plan_cleanup()
        self.assert_only_survivor_planned(targets)

    def test_queued_directory_disappears_before_scandir(self):
        vanished = self.make_file('ordinary/nested/source').parents[1]
        original = self.cleaner.generated_directory

        def classify(path):
            result = original(path)
            if path == vanished:
                shutil.rmtree(path)
            return result

        with mock.patch.object(self.cleaner, 'generated_directory', side_effect=classify):
            targets = self.cleaner.plan_cleanup()
        self.assert_only_survivor_planned(targets)

    def test_reported_derived_data_disappears_before_inspection(self):
        vanished = self.make_file('work/JobsFlutterToolsDerivedData/Build/output').parents[1]
        original = self.cleaner.inspect_target

        def inspect(path):
            if path == vanished:
                shutil.rmtree(path)
            return original(path)

        with mock.patch.object(self.cleaner, 'inspect_target', side_effect=inspect):
            targets = self.cleaner.plan_cleanup()
        self.assert_only_survivor_planned(targets)
        self.assertIn('JobsFlutterToolsDerivedData', self.output.getvalue())

    def test_disappearing_child_discards_entire_candidate_snapshot(self):
        vanished = self.make_file('ProjectDerivedData/Build/output')
        original = Path.lstat

        def lstat(path, *args, **kwargs):
            if path == vanished and path.exists():
                path.unlink()
            return original(path, *args, **kwargs)

        with mock.patch.object(Path, 'lstat', lstat):
            targets = self.cleaner.plan_cleanup()
        self.assert_only_survivor_planned(targets)
        self.assertTrue((self.root / 'ProjectDerivedData').is_dir())

    def test_cache_tag_disappears_between_check_and_open(self):
        tag = self.make_file('tagged/CACHEDIR.TAG')
        tag.write_bytes(self.cleaner.CACHEDIR_SIGNATURE)
        original = Path.open

        def open_file(path, *args, **kwargs):
            if path == tag:
                path.unlink()
            return original(path, *args, **kwargs)

        with mock.patch.object(Path, 'open', open_file):
            targets = self.cleaner.plan_cleanup()
        self.assert_only_survivor_planned(targets)

    def test_permission_failure_is_not_silently_ignored(self):
        denied = self.make_file('ordinary/source').parent
        original = self.cleaner.os.scandir

        def scan(path):
            if Path(path) == denied:
                raise PermissionError('fixture access denied')
            return original(path)

        with mock.patch.object(self.cleaner.os, 'scandir', side_effect=scan):
            with self.assertRaises(PermissionError):
                self.cleaner.plan_cleanup()
        self.assertTrue(self.survivor.exists())

    def test_missing_root_remains_an_error(self):
        self.cleaner.ROOT = self.root / 'missing-root'
        with self.assertRaises(FileNotFoundError):
            self.cleaner.plan_cleanup()

    def test_disappearance_after_preview_skips_targets_and_cleans_remaining(self):
        vanished = self.make_file('ProjectDerivedData/Build/output').parents[1]
        cache_file = self.make_file('.DS_Store')
        cache_file.write_bytes(b'x' * 2 * 1024**2)
        source = self.make_file('source.txt')
        targets = self.cleaner.plan_cleanup()
        expected_size = next(target[3] for target in targets if target[0] == self.survivor.parent)
        shutil.rmtree(vanished)
        cache_file.unlink()
        self.assertEqual(self.run_cleanup(targets), 0)
        self.assertFalse(self.survivor.exists())
        self.assertTrue(source.exists())
        self.assertIn('目标已消失，跳过："ProjectDerivedData"', self.output.getvalue())
        self.assertIn('已删除 1 项，跳过 2 项', self.output.getvalue())
        self.assertIn(f'已删除项的预览占用 {expected_size / 1e9:.3f} GB', self.output.getvalue())

    def test_all_targets_disappear_after_preview(self):
        targets = self.cleaner.plan_cleanup()
        shutil.rmtree(self.survivor.parent)
        self.assertEqual(self.run_cleanup(targets), 0)
        self.assertIn('已删除 0 项，跳过 1 项', self.output.getvalue())

    def test_target_disappears_during_validation_inspection(self):
        target = self.cleaner.plan_cleanup()[0]
        original = self.cleaner.inspect_target

        def inspect(path):
            shutil.rmtree(path)
            return original(path)

        with mock.patch.object(self.cleaner, 'inspect_target', side_effect=inspect):
            self.assertFalse(self.cleaner.validate_target(target))

    def test_target_disappears_between_preflight_and_deletion_validation(self):
        vanished = self.make_file('ProjectDerivedData/Build/output').parents[1]
        targets = self.cleaner.plan_cleanup()
        original = self.cleaner.validate_target
        validations = 0

        def validate(target):
            nonlocal validations
            if target[0] == vanished:
                validations += 1
                if validations == 2:
                    shutil.rmtree(vanished)
            return original(target)

        with mock.patch.object(self.cleaner, 'validate_target', side_effect=validate):
            self.assertEqual(self.run_cleanup(targets), 0)
        self.assertFalse(self.survivor.exists())
        self.assertIn('已删除 1 项，跳过 1 项', self.output.getvalue())

    def test_targets_disappear_between_validation_and_removal(self):
        vanished = self.make_file('ProjectDerivedData/Build/output').parents[1]
        cache_file = self.make_file('.DS_Store')
        targets = self.cleaner.plan_cleanup()
        original = self.cleaner.remove_target

        def remove(target):
            if target[0] == vanished:
                shutil.rmtree(vanished)
            elif target[0] == cache_file:
                cache_file.unlink()
            return original(target)

        with mock.patch.object(self.cleaner, 'remove_target', side_effect=remove):
            self.assertEqual(self.run_cleanup(targets), 0)
        self.assertFalse(self.survivor.exists())
        self.assertIn('已删除 1 项，跳过 2 项', self.output.getvalue())

    def test_skipped_target_is_not_deleted_if_recreated(self):
        vanished = self.make_file('ProjectDerivedData/Build/output').parents[1]
        targets = self.cleaner.plan_cleanup()
        shutil.rmtree(vanished)
        original = self.cleaner.validate_target
        validations = 0

        def validate(target):
            nonlocal validations
            if target[0] == self.survivor.parent:
                validations += 1
                if validations == 2:
                    self.make_file('ProjectDerivedData/new-build')
            return original(target)

        with mock.patch.object(self.cleaner, 'validate_target', side_effect=validate):
            self.assertEqual(self.run_cleanup(targets), 0)
        self.assertTrue((vanished / 'new-build').exists())
        self.assertFalse(self.survivor.exists())

    def test_missing_child_during_rmtree_does_not_interrupt_other_targets(self):
        vanished = self.make_file('ProjectDerivedData/Build/output')
        targets = self.cleaner.plan_cleanup()
        original = self.cleaner.os.unlink
        raced = False

        def unlink(path, *args, **kwargs):
            nonlocal raced
            if Path(path).name == vanished.name and not raced:
                raced = True
                original(path, *args, **kwargs)
            return original(path, *args, **kwargs)

        with mock.patch.object(self.cleaner.os, 'unlink', side_effect=unlink):
            self.assertEqual(self.run_cleanup(targets), 0)
        self.assertTrue(raced)
        self.assertFalse(vanished.parents[1].exists())
        self.assertFalse(self.survivor.exists())
        self.assertIn('已删除 2 项，跳过 0 项', self.output.getvalue())

    def test_missing_child_during_validation_is_not_a_missing_target(self):
        target = self.cleaner.plan_cleanup()[0]
        original = Path.lstat

        def lstat(path, *args, **kwargs):
            if path == self.survivor and path.exists():
                path.unlink()
            return original(path, *args, **kwargs)

        with mock.patch.object(Path, 'lstat', lstat):
            with self.assertRaises(FileNotFoundError):
                self.run_cleanup([target])
        self.assertTrue(self.survivor.parent.is_dir())
        self.assertIn('在复核目标时停止', self.output.getvalue())

    def test_changed_snapshot_stops_preflight_before_any_deletion(self):
        changed = self.make_file('ProjectDerivedData/Build/output')
        targets = self.cleaner.plan_cleanup()
        changed.write_text('new build content')
        with self.assertRaisesRegex(RuntimeError, '内容发生变化'):
            self.run_cleanup(targets)
        self.assertTrue(self.survivor.exists())
        self.assertTrue(changed.exists())
        self.assertIn('已完整删除 0/2 项', self.output.getvalue())

    def test_permission_error_during_removal_is_not_ignored(self):
        targets = self.cleaner.plan_cleanup()
        with mock.patch.object(self.cleaner.os, 'unlink', side_effect=PermissionError('fixture access denied')):
            with self.assertRaises(PermissionError):
                self.run_cleanup(targets)
        self.assertTrue(self.survivor.exists())
        self.assertIn('当前失败项可能只删除了一部分', self.output.getvalue())

    def test_missing_root_after_preview_remains_an_error(self):
        targets = self.cleaner.plan_cleanup()
        shutil.rmtree(self.root)
        with self.assertRaises(FileNotFoundError):
            self.run_cleanup(targets)

    def test_modified_snapshot_and_replaced_symlink_still_rejected(self):
        target = self.cleaner.plan_cleanup()[0]
        self.survivor.write_text('new build content')
        with self.assertRaisesRegex(RuntimeError, '内容发生变化'):
            self.cleaner.validate_target(target)
        original_directory = self.survivor.parent
        moved = self.root / 'moved'
        original_directory.rename(moved)
        original_directory.symlink_to(moved, target_is_directory=True)
        with self.assertRaisesRegex(RuntimeError, '符号链接'):
            self.cleaner.validate_target(target)
        shutil.rmtree(moved)
        with self.assertRaisesRegex(RuntimeError, '符号链接'):
            self.cleaner.validate_target(target)

    def test_whole_script_dry_run_and_cache_only_keep_outputs(self):
        copied = self.root / SCRIPT.name
        shutil.copy2(SCRIPT, copied)
        product = self.make_file('ToolDerivedData/Build/Products/Tool.app/executable')
        module = self.make_file('ToolDerivedData/ModuleCache.noindex/cache')
        source = self.make_file('build/handwritten.txt')
        metadata = self.make_file('.git/objects/object.pyc')
        (self.root / 'LinkedDerivedData').symlink_to(product.parents[3], target_is_directory=True)
        preview = subprocess.run(['/bin/zsh', str(copied), '--dry-run'], text=True, capture_output=True)
        self.assertEqual(preview.returncode, 0, preview.stdout + preview.stderr)
        self.assertIn('预览结束，未删除任何文件', preview.stdout)
        self.assertTrue(module.exists())
        cleaned = subprocess.run(['/bin/zsh', str(copied), '--cache-only', '--yes'], text=True, capture_output=True)
        self.assertEqual(cleaned.returncode, 0, cleaned.stdout + cleaned.stderr)
        self.assertFalse(module.exists())
        self.assertTrue(product.exists())
        self.assertTrue(source.exists())
        self.assertTrue(metadata.exists())
        self.assertTrue((self.root / 'LinkedDerivedData').is_symlink())

    def test_parent_swapped_to_symlink_after_last_validation_is_rejected(self):
        nested = self.make_file('project/.cache/output')
        targets = [target for target in self.cleaner.plan_cleanup() if target[0] == nested.parent]
        outside = self.root / 'outside'
        (outside / '.cache').mkdir(parents=True)
        protected = outside / '.cache/output'
        protected.write_text('must survive')
        original = self.cleaner.remove_target

        def remove(target):
            (self.root / 'project').rename(self.root / 'project-old')
            (self.root / 'project').symlink_to(outside, target_is_directory=True)
            return original(target)

        with mock.patch.object(self.cleaner, 'remove_target', side_effect=remove):
            with self.assertRaises(OSError):
                self.run_cleanup(targets)
        self.assertEqual(protected.read_text(), 'must survive')
        self.assertTrue((self.root / 'project-old/.cache/output').exists())

    def test_replacement_at_final_remove_is_rejected(self):
        targets = self.cleaner.plan_cleanup()
        original = self.cleaner.remove_target

        def remove(target):
            target[0].rename(self.root / 'old-cache')
            self.make_file('.cache/new-content', 'new data')
            return original(target)

        with mock.patch.object(self.cleaner, 'remove_target', side_effect=remove):
            with self.assertRaisesRegex(RuntimeError, '删除前目标已变化'):
                self.run_cleanup(targets)
        self.assertTrue((self.root / '.cache/new-content').exists())

    def test_runtime_without_safe_rmtree_refuses_deletion(self):
        self.cleaner.ARGS.dry_run = False
        self.cleaner.ARGS.yes = True
        with mock.patch.object(self.cleaner.shutil.rmtree, 'avoids_symlink_attacks', False):
            with self.assertRaisesRegex(RuntimeError, 'Python 3.11'):
                self.cleaner.main()
        self.assertTrue(self.survivor.exists())


if __name__ == '__main__':
    unittest.main()
