"""审计器必须只解析代码、明确报告缺失检查器，并跳过外部链接。"""

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

SOURCE = Path(__file__).resolve().parents[1] / '🔎审计脚本.py'
SPEC = importlib.util.spec_from_file_location('audit_scripts', SOURCE)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class AuditTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()

    def file(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding='utf-8')
        return path

    def symlink(self, link, target, *, directory=False):
        try:
            link.symlink_to(target, target_is_directory=directory)
        except (OSError, NotImplementedError) as error:
            self.skipTest('当前环境不能创建符号链接：' + str(error))

    def test_python_is_compiled_without_executing(self):
        source = self.file('危险 script.py', "raise RuntimeError('must not execute')\n")
        self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'passed')
        self.assertFalse((self.root / '__pycache__').exists())

    def test_bad_syntax_is_failure(self):
        source = self.file('bad.py', 'def broken(:\n')
        self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'failed')

    def test_python_encoding_cookie_is_respected(self):
        source = self.root / 'legacy.py'
        source.write_bytes(b'# coding: latin-1\nvalue = "caf\xe9"\n')
        self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'passed')

    @unittest.skipUnless(shutil.which('bash'), '未安装 Bash')
    def test_shell_is_parsed_without_executing(self):
        source = self.file('test.sh', '#!/bin/bash\nexit 99\n')
        self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'passed')

    @unittest.skipUnless(shutil.which('bash'), '未安装 Bash')
    def test_shell_startup_injection_is_removed(self):
        marker = self.root / 'executed'
        startup = self.file('startup', f'touch "{marker}"\n')
        source = self.file('test.sh', '#!/bin/bash\nexit 99\n')
        with mock.patch.dict(os.environ, {'BASH_ENV': str(startup)}):
            self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'passed')
        self.assertFalse(marker.exists())

    def test_unknown_shebang_is_not_executed(self):
        source = self.file('test.sh', '#!/bin/echo unsafe\n')
        self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'failed')

    def test_shell_word_in_another_interpreters_arguments_is_not_a_shebang(self):
        for header in ('#!/usr/bin/python3 bash', '#!/usr/bin/env python3 bash',
                       '#!/bin/echo /bin/bash'):
            with self.subTest(header=header):
                with self.assertRaises(ValueError):
                    AUDIT.shell_kind(self.root / 'test.sh', header)

    def test_env_shebang_and_uppercase_shell_extension_are_supported(self):
        self.assertEqual(AUDIT.shell_kind(self.root / 'test.sh', '#!/usr/bin/env -S bash -eu'), 'bash')
        self.assertEqual(AUDIT.shell_kind(self.root / 'test.ZSH', '# comment'), 'zsh')

    def test_missing_checker_and_batch_are_explicitly_skipped(self):
        for name in ('test.ps1', 'test.cmd'):
            source = self.file(name, 'exit 99')
            with mock.patch.object(AUDIT.shutil, 'which', return_value=None):
                self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'skipped')

    def test_windows_powershell_is_used_when_pwsh_is_unavailable(self):
        source = self.file('test.ps1', 'exit 99')
        native = 'C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
        with mock.patch.object(AUDIT.shutil, 'which', side_effect=lambda name: native if name == 'powershell' else None):
            with mock.patch.object(AUDIT.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '', '')) as run:
                result = AUDIT.check_file(source, self.root)
        self.assertEqual(result['status'], 'passed')
        self.assertEqual(result['checker'], 'powershell')
        self.assertEqual(run.call_args.args[0][0], native)

    def test_available_native_checkers_only_parse_source(self):
        marker = self.root / 'executed'
        powershell_path = str(marker).replace("'", "''")
        fixtures = (
            ('node', 'test.js', f'require("node:fs").writeFileSync({json.dumps(str(marker))}, "unsafe");\n', 'const = ;'),
            ('pwsh' if shutil.which('pwsh') else 'powershell', 'test.ps1',
             f"[System.IO.File]::WriteAllText('{powershell_path}', 'unsafe')\n", 'function broken {'),
            ('zsh', 'test.zsh', f'print unsafe > "{marker}"\n', 'if then\n'),
        )
        for checker, name, valid, invalid in fixtures:
            with self.subTest(checker=checker):
                if not shutil.which(checker):
                    continue
                source = self.file(name, valid)
                self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'passed')
                self.assertFalse(marker.exists())
                source.write_text(invalid, encoding='utf-8')
                self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'failed')

    @unittest.skipUnless(shutil.which('node'), '未安装 Node.js')
    def test_node_startup_injection_is_removed(self):
        marker = self.root / 'executed'
        startup = self.file('startup.js', f'require("node:fs").writeFileSync({json.dumps(str(marker))}, "unsafe");\n')
        source = self.file('script.js', 'throw new Error("must not execute");\n')
        with mock.patch.dict(os.environ, {'NODE_OPTIONS': '--require ' + str(startup)}):
            self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'passed')
        self.assertFalse(marker.exists())

    def test_skipped_files_make_require_all_fail(self):
        self.file('test.cmd', 'exit 99')
        self.assertEqual(AUDIT.main(['--root', str(self.root), '--require-all']), 1)

    def test_symlinks_and_generated_directories_are_not_followed(self):
        source = self.file('source.py', 'pass')
        self.file('node_modules/vendor.py', 'broken syntax')
        self.file('.git/hook.py', 'broken syntax')
        self.symlink(self.root / 'link.py', source)
        self.symlink(self.root / 'linked', self.root, directory=True)
        self.assertEqual(list(AUDIT.discover(self.root)), [source])

    def test_build_and_supplier_directories_are_excluded(self):
        source = self.file('source.py', 'pass')
        for directory in ('DerivedData', 'PodsManual', 'ManualByFooPods@Pods',
                          'vendor', 'Vendor', 'ThirdParty', 'third_party'):
            self.file(directory + '/vendor.py', 'broken syntax')
        self.assertEqual(list(AUDIT.discover(self.root)), [source])

    @unittest.skipUnless(hasattr(os, 'mkfifo'), '平台没有命名管道')
    def test_named_pipes_are_not_discovered_as_scripts(self):
        source = self.file('source.py', 'pass')
        os.mkfifo(self.root / 'stream.py')
        self.assertEqual(list(AUDIT.discover(self.root)), [source])

    @unittest.skipUnless(hasattr(os, 'mkfifo'), '平台没有命名管道')
    def test_direct_check_rejects_named_pipe_without_blocking(self):
        source = self.root / 'stream.py'
        os.mkfifo(source)
        self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'failed')

    def test_direct_check_rejects_symlink(self):
        source = self.file('source.py', 'pass')
        link = self.root / 'link.py'
        self.symlink(link, source)
        self.assertEqual(AUDIT.check_file(link, self.root)['status'], 'failed')

    def test_report_cannot_overwrite_source(self):
        source = self.file('source.py', 'pass\n')
        with self.assertRaises(SystemExit) as raised:
            AUDIT.main(['--root', str(self.root), '--json', str(source)])
        self.assertEqual(raised.exception.code, 2)
        self.assertEqual(source.read_text(), 'pass\n')

    def test_report_cannot_follow_symlink_to_source(self):
        source = self.file('source.py', 'pass\n')
        destination = self.root / 'report.json'
        self.symlink(destination, source)
        with self.assertRaises(SystemExit) as raised:
            AUDIT.main(['--root', str(self.root), '--json', str(destination)])
        self.assertEqual(raised.exception.code, 2)
        self.assertEqual(source.read_text(), 'pass\n')
        self.assertTrue(destination.is_symlink())

    def test_report_cannot_overwrite_a_hardlink_to_source(self):
        source = self.file('source.py', 'pass\n')
        destination = self.root / 'report.json'
        os.link(source, destination)
        with self.assertRaises(SystemExit) as raised:
            AUDIT.main(['--root', str(self.root), '--json', str(destination)])
        self.assertEqual(raised.exception.code, 2)
        self.assertEqual(source.read_text(), 'pass\n')
        self.assertTrue(source.samefile(destination))

    def test_atomic_report_failure_preserves_previous_report(self):
        destination = self.file('report.json', '{"previous": true}\n')
        with mock.patch.object(AUDIT.os, 'replace', side_effect=PermissionError('denied')):
            with self.assertRaises(OSError):
                AUDIT.write_report(destination, {'new': True})
        self.assertEqual(destination.read_text(), '{"previous": true}\n')
        self.assertEqual(list(self.root.iterdir()), [destination])

    def test_timeout_and_checker_failure_are_reported(self):
        source = self.file('script.sh', '#!/bin/bash\nexit 99\n')
        with mock.patch.object(AUDIT.shutil, 'which', return_value='/bin/bash'):
            with mock.patch.object(AUDIT.subprocess, 'run', side_effect=subprocess.TimeoutExpired('bash', 1)):
                self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'failed')
            with mock.patch.object(AUDIT.subprocess, 'run', side_effect=PermissionError('denied')):
                self.assertEqual(AUDIT.check_file(source, self.root)['status'], 'failed')

    def test_scan_error_is_not_reported_as_success(self):
        with mock.patch.object(AUDIT.os, 'walk', side_effect=PermissionError('denied')):
            self.assertEqual(AUDIT.main(['--root', str(self.root)]), 2)

    def test_standalone_entry_uses_its_directory_from_another_working_directory(self):
        script = self.root / '独立工具 含空格' / SOURCE.name
        script.parent.mkdir()
        shutil.copy2(SOURCE, script)
        marker = script.parent / 'executed'
        (script.parent / '危险脚本.py').write_text(
            f'from pathlib import Path\nPath({str(marker)!r}).touch()\n', encoding='utf-8')
        # 当前工作目录里的错误源码不属于默认扫描范围。
        self.file('unrelated.py', 'def broken(:\n')
        report_path = self.root / '审计结果.json'
        command = [sys.executable, '-B', str(script)]

        process = subprocess.run(command, cwd=self.root, capture_output=True,
                                 text=True, errors='replace', timeout=30)
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertEqual(sorted(path.name for path in script.parent.iterdir()),
                         sorted([SOURCE.name, '危险脚本.py']))

        process = subprocess.run([*command, '--json', str(report_path)], cwd=self.root,
                                 capture_output=True, text=True, errors='replace', timeout=30)
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        report = json.loads(report_path.read_text(encoding='utf-8'))
        self.assertEqual(report['root'], str(script.parent))
        self.assertEqual({row['path'] for row in report['files']}, {SOURCE.name, '危险脚本.py'})
        self.assertEqual(report['counts'], {'passed': 2})
        self.assertFalse(marker.exists())
        self.assertFalse((script.parent / '__pycache__').exists())


if __name__ == '__main__':
    unittest.main()
