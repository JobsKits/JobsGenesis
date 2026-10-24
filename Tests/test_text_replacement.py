"""仅加载替换函数，在临时目录和命令夹具中验证失败边界。"""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = (Path(__file__).resolve().parents[1] / 'JobsCommand@Others' / 'MacOS'
          / '【MacOS】全文件搜索文字替换.command' / '【MacOS】全文件搜索文字替换.command')


@unittest.skipUnless(shutil.which('zsh') and shutil.which('perl'), '需要本机 Zsh 和 Perl')
class TextReplacementTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.target = self.root / '目标 含空格'
        self.target.mkdir()
        self.fake_bin = self.root / 'fake-bin'
        self.fake_bin.mkdir()
        source = SOURCE.read_text(encoding='utf-8')
        self.assertTrue(source.rstrip().endswith('main "$@"'))
        self.library = self.root / 'functions.zsh'
        self.library.write_text(source.rsplit('\nmain "$@"', 1)[0] + '\n', encoding='utf-8')

    def file(self, relative, content):
        path = self.target / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')
        return path

    def fake(self, command, body):
        path = self.fake_bin / command
        path.write_text('#!/bin/zsh\n' + body + '\n', encoding='utf-8')
        path.chmod(0o700)

    def run_functions(self, body, *, target=None, search='needle', replacement='replacement', input_text=''):
        env = dict(os.environ, JOBS_LIBRARY=str(self.library), TARGET_FILE=str(target or self.target),
                   SEARCH_TEXT=search, REPLACE_TEXT=replacement, TMPDIR=str(self.root),
                   PATH=str(self.fake_bin) + os.pathsep + os.environ.get('PATH', ''))
        env.pop('ZDOTDIR', None)
        program = ('source "$JOBS_LIBRARY"\n'
                   'log() { print -r -- "$1"; }\n'
                   'pause_to_exit() { return 0; }\n' + body)
        return subprocess.run(['zsh', '-f', '-c', program], cwd=self.root, env=env,
                              input=input_text, capture_output=True, text=True, timeout=20)

    def replace(self, **kwargs):
        return self.run_functions('replace_in_target "$TARGET_FILE" "$SEARCH_TEXT" "$REPLACE_TEXT"', **kwargs)

    def test_literal_special_characters_and_empty_replacement(self):
        needle = r'a.*[b]/c\d$1'
        replacement = r'$&\1/$ENV{x}'
        source = self.file('换行\n文件.txt', needle + '\n' + needle)
        process = self.replace(search=needle, replacement=replacement)
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertEqual(source.read_text(encoding='utf-8'), replacement + '\n' + replacement)
        process = self.replace(search=replacement, replacement='')
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertEqual(source.read_text(encoding='utf-8'), '\n')

    def test_backup_preserves_original_and_file_mode(self):
        source = self.file('source.txt', 'needle\n')
        source.chmod(0o640)
        process = self.run_functions(
            'BACKUP_ENABLED=true; replace_in_target "$TARGET_FILE" "$SEARCH_TEXT" "$REPLACE_TEXT"')
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertEqual(source.read_text(), 'replacement\n')
        self.assertEqual(Path(str(source) + '.bak').read_text(), 'needle\n')
        self.assertEqual(source.stat().st_mode & 0o777, 0o640)

    def test_existing_backup_is_preserved_and_source_is_not_changed(self):
        source = self.file('source.txt', 'needle')
        backup = self.file('source.txt.bak', 'older backup')
        process = self.run_functions(
            'BACKUP_ENABLED=true; replace_in_target "$TARGET_FILE" "$SEARCH_TEXT" "$REPLACE_TEXT"')
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertEqual(backup.read_text(), 'older backup')
        self.assertIn('失败数：1', process.stdout)

    def test_backup_failure_does_not_change_source_or_report_success(self):
        source = self.file('source.txt', 'needle')
        self.fake('cp', 'exit 17')
        process = self.run_functions(
            'BACKUP_ENABLED=true; replace_in_target "$TARGET_FILE" "$SEARCH_TEXT" "$REPLACE_TEXT"')
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertNotIn('已替换：', process.stdout)

    def test_perl_failure_does_not_report_success_or_leave_temp_files(self):
        source = self.file('source.txt', 'needle')
        self.fake('perl', 'print -u2 -- "write failed"; exit 19')
        process = self.replace()
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertNotIn('已替换：', process.stdout)
        self.assertEqual(list(self.target.iterdir()), [source])

    def test_readonly_source_is_preserved(self):
        if hasattr(os, 'geteuid') and os.geteuid() == 0:
            self.skipTest('管理员身份不能可靠模拟普通用户写入失败')
        source = self.file('source.txt', 'needle')
        source.chmod(0o444)
        self.addCleanup(source.chmod, 0o600)
        process = self.replace()
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertNotIn('已替换：', process.stdout)

    def test_atomic_rename_failure_keeps_original(self):
        source = self.file('source.txt', 'needle')
        self.fake('mv', 'exit 23')
        process = self.replace()
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertNotIn('已替换：', process.stdout)
        self.assertEqual(list(self.target.iterdir()), [source])

    def test_binary_links_backups_and_build_directories_are_skipped(self):
        source = self.file('source.txt', 'needle')
        binary = self.target / 'binary.bin'
        binary.write_bytes(b'needle\x00binary')
        link = self.target / 'link.txt'
        link.symlink_to(source)
        excluded = ['.git', 'node_modules', 'Pods', '.dart_tool', 'build', 'DerivedData',
                    'PodsManual', 'ManualByFooPods@Pods', 'dist', 'vendor']
        for directory in excluded:
            self.file(directory + '/excluded.txt', 'needle')
        backup = self.file('old.txt.bak', 'needle')
        process = self.replace()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertIn('成功替换文件数：1', process.stdout)
        self.assertEqual(source.read_text(), 'replacement')
        self.assertTrue(link.is_symlink())
        self.assertEqual(binary.read_bytes(), b'needle\x00binary')
        self.assertEqual(backup.read_text(), 'needle')
        for directory in excluded:
            self.assertEqual((self.target / directory / 'excluded.txt').read_text(), 'needle')

    def test_failed_find_does_not_apply_partial_inventory(self):
        source = self.file('source.txt', 'needle')
        self.fake('find', 'printf "%s\\0" "$TARGET_FILE/source.txt"; exit 29')
        process = self.replace()
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertNotIn('已替换：', process.stdout)

    def test_text_classification_read_error_counts_as_failure(self):
        source = self.file('source.txt', 'needle')
        self.fake('grep', 'exit 2')
        process = self.replace()
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertIn('失败数：1', process.stdout)

    def test_search_read_error_counts_as_failure(self):
        source = self.file('source.txt', 'needle')
        self.fake('grep', '[[ "$1" == -Iq ]] && exit 0; exit 2')
        process = self.replace()
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(source.read_text(), 'needle')
        self.assertIn('失败数：1', process.stdout)

    def test_no_match_is_a_successful_skip(self):
        source = self.file('source.txt', 'other')
        process = self.replace()
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertEqual(source.read_text(), 'other')
        self.assertIn('成功替换文件数：0；失败数：0', process.stdout)

    def test_eof_at_every_input_stage_stops_before_replacement(self):
        source = self.file('source.txt', 'needle')
        for text in ('', 'needle\n', 'needle\nreplacement\n',
                     'needle\nreplacement\n' + str(source) + '\n'):
            with self.subTest(stage=text.count('\n')):
                process = self.run_functions('run_main_business_flow', input_text=text)
                self.assertNotEqual(process.returncode, 0)
                self.assertEqual(source.read_text(), 'needle')
                self.assertNotIn('已替换：', process.stdout)


if __name__ == '__main__':
    unittest.main()
