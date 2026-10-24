"""安装 / 卸载故障注入；所有工具和文件均限定在临时目录。"""

import errno
import io
import os
from pathlib import Path
import pty
import re
import select
import subprocess
import sys
import tempfile
import time
import types
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
UNINSTALLERS = [
    ROOT / 'JobsCommand@Flutter/MacOS/小工具/【MacOS】⚙️双击卸载Homebrew.command/【MacOS】⚙️双击卸载Homebrew.command',
    ROOT / 'JobsCommand@iOS/其他/【MacOS】⚙️双击卸载Homebrew.command/【MacOS】⚙️双击卸载Homebrew.command',
]
INJECTOR = ROOT / 'JobsConfigOS/⚙️VScodeConfigs/🐦VScodeConfigByFlutter/【MacOS】💉VSCode配置注入@当前项目.command'


class UninstallerTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='jobs-installer-test-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.prefix = self.root / 'brew 中文 space'
        self.bin = self.root / 'tools'
        (self.prefix / 'bin').mkdir(parents=True)
        self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.root), TMPDIR=str(self.root),
                        PATH=f'{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin', TERM='dumb',
                        FIXTURE_PREFIX=str(self.prefix), FIXTURE_EVENTS=str(self.root / 'events'))
        self.env.pop('DRY_RUN', None)
        self.tool(self.prefix / 'bin/brew', 'printf "%s\\n" "$FIXTURE_PREFIX"\n')
        self.tool(self.bin / 'uname', 'printf "Darwin\\n"\n')
        self.tool(self.bin / 'curl', '''
echo download >> "$FIXTURE_EVENTS"
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output ]; then destination="$2"; shift; fi
  shift
done
if [ "${DOWNLOAD_FAIL:-0}" = 1 ]; then exit 23; fi
if [ "${DOWNLOAD_EMPTY:-0}" = 1 ]; then : > "$destination"; exit 0; fi
cat > "$destination" <<'INSTALLER'
#!/bin/bash
printf 'installer:%s\\n' "$*" >> "$FIXTURE_EVENTS"
exit "${INSTALLER_EXIT:-0}"
INSTALLER
''')

    def tool(self, path, body):
        path.write_text('#!/bin/sh\n' + body)
        path.chmod(0o755)

    def run_entry(self, source, answer=None, extra=()):
        args = ['/bin/zsh', '-f', str(source), '--prefix', str(self.prefix), *extra]
        if answer is None:
            result = subprocess.run(args, env=self.env, stdin=subprocess.DEVNULL,
                                    capture_output=True, text=True, timeout=10)
            return result.returncode, result.stdout + result.stderr
        master, slave = pty.openpty()
        process = subprocess.Popen(args, env=self.env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = bytearray()
        sent = False
        try:
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.05)[0]:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
                    if not chunk:
                        break
                    output.extend(chunk)
                if not sent and '其它输入取消：'.encode() in output:
                    os.write(master, answer.encode() + b'\n')
                    sent = True
                if process.poll() is not None:
                    # Drain the PTY before collecting the exit status.
                    continue
            return process.wait(timeout=2), output.decode(errors='replace')
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()
            os.close(master)

    def test_copies_share_the_same_safe_implementation(self):
        self.assertEqual(UNINSTALLERS[0].read_bytes(), UNINSTALLERS[1].read_bytes())

    def test_preview_and_noninteractive_refusal_never_download(self):
        for source in UNINSTALLERS:
            code, output = self.run_entry(source, extra=('--dry-run',))
            self.assertEqual(code, 0, output)
            code, output = self.run_entry(source)
            self.assertNotEqual(code, 0, output)
        self.assertFalse((self.root / 'events').exists())

    def test_cancel_does_not_download(self):
        code, output = self.run_entry(UNINSTALLERS[0], answer='')
        self.assertEqual(code, 0, output)
        self.assertFalse((self.root / 'events').exists())

    def test_download_failure_never_invokes_installer(self):
        self.env['DOWNLOAD_FAIL'] = '1'
        code, output = self.run_entry(UNINSTALLERS[0], answer='YES')
        self.assertNotEqual(code, 0, output)
        self.assertEqual((self.root / 'events').read_text().strip(), 'download')

    def test_empty_download_is_rejected(self):
        self.env['DOWNLOAD_EMPTY'] = '1'
        code, output = self.run_entry(UNINSTALLERS[0], answer='YES')
        self.assertNotEqual(code, 0, output)
        self.assertEqual((self.root / 'events').read_text().strip(), 'download')

    def test_installer_failure_is_preserved(self):
        self.env['INSTALLER_EXIT'] = '17'
        code, output = self.run_entry(UNINSTALLERS[0], answer='YES')
        self.assertEqual(code, 17, output)
        self.assertNotIn('官方卸载流程完成', output)
        self.assertTrue((self.prefix / 'bin/brew').exists())

    def test_success_passes_only_the_confirmed_prefix(self):
        code, output = self.run_entry(UNINSTALLERS[0], answer='YES')
        self.assertEqual(code, 0, output)
        self.assertIn(f'installer:--path {self.prefix} --force', (self.root / 'events').read_text())
        self.assertTrue((self.prefix / 'bin/brew').exists())
        for logfile in self.root.glob('jobs-brew-uninstall-log.*'):
            self.assertEqual(logfile.stat().st_mode & 0o777, 0o600)
        self.assertFalse(list(self.root.glob('jobs-brew-uninstall.*')))


class VscodeInjectionTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='jobs-vscode-test-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.target = self.root / '.vscode'
        self.target.mkdir()
        (self.target / 'my-settings.json').write_text('original')
        source = INJECTOR.read_text().split("<<'PYTHON'\n", 1)[1].split('\nPYTHON\n', 1)[0]
        definitions = source.split('\nparser = ', 1)[0]
        self.module = types.ModuleType('injector')
        with mock.patch.object(sys, 'argv', ['injector', str(self.root)]):
            exec(compile(definitions, str(INJECTOR), 'exec'), self.module.__dict__)
        self.output = io.StringIO()
        for patcher in (mock.patch('builtins.input', return_value='YES'),
                        mock.patch.object(sys.stdin, 'isatty', return_value=True),
                        mock.patch.object(sys, 'stdout', self.output),
                        mock.patch.dict(os.environ, {name: '' for name in
                            ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR')})):
            patcher.start()
            self.addCleanup(patcher.stop)

    def download(self, arguments, **kwargs):
        repo = Path(arguments[-1])
        repo.mkdir()
        for name in self.module.CONFIG_FILES:
            (repo / name).write_text('// JSONC\n{"new": true,}\n')
        (repo / 'README.md').write_text('must not install')

    def test_network_failure_preserves_existing_configuration(self):
        with mock.patch.object(subprocess, 'run', side_effect=subprocess.CalledProcessError(128, 'git')):
            with self.assertRaises(subprocess.CalledProcessError):
                self.module.inject(False)
        self.assertEqual((self.target / 'my-settings.json').read_text(), 'original')
        self.assertFalse(list(self.root.glob('.vscode-backup-*')))

    def test_success_backs_up_and_copies_only_configuration(self):
        with mock.patch.object(subprocess, 'run', side_effect=self.download):
            self.module.inject(False)
        self.assertEqual({p.name for p in self.target.iterdir()}, set(self.module.CONFIG_FILES))
        backup = next(self.root.glob('.vscode-backup-*')) / '.vscode/my-settings.json'
        self.assertEqual(backup.read_text(), 'original')

    def test_invalid_download_preserves_existing_configuration(self):
        def bad_download(arguments, **kwargs):
            self.download(arguments, **kwargs)
            (Path(arguments[-1]) / 'settings.json').unlink()
        with mock.patch.object(subprocess, 'run', side_effect=bad_download):
            with self.assertRaises(FileNotFoundError):
                self.module.inject(False)
        self.assertEqual((self.target / 'my-settings.json').read_text(), 'original')

    def test_failed_publication_restores_backup(self):
        original = Path.rename
        def rename(path, destination):
            if path.name == 'ready':
                raise PermissionError('injected publication failure')
            return original(path, destination)
        with mock.patch.object(subprocess, 'run', side_effect=self.download), mock.patch.object(Path, 'rename', rename):
            with self.assertRaises(PermissionError):
                self.module.inject(False)
        self.assertEqual((self.target / 'my-settings.json').read_text(), 'original')

    def test_dry_run_does_not_download(self):
        with mock.patch.object(subprocess, 'run') as download:
            self.module.inject(True)
        download.assert_not_called()
        self.assertEqual((self.target / 'my-settings.json').read_text(), 'original')


class DownloadHelperTests(unittest.TestCase):
    def test_failed_download_never_executes_partial_payload(self):
        entries = [
            ('JobsCommand@Flutter/MacOS/配置相关/【MacOS】⚙️双击安装Cocoapods.command/【MacOS】⚙️双击安装Cocoapods.command', 'download_and_run_rvm'),
            ('JobsConfigOS/【MacOS】🆕新系统配置.command/【MacOS】🆕新系统配置.command', 'jobs_install_ohmyzsh'),
            ('JobsConfigOS/🌍JobsMacEnvVarConfigs/scripts/install.command/install.command', 'jobs_install_ohmyzsh'),
        ]
        for relative, function in entries:
            with self.subTest(script=relative), tempfile.TemporaryDirectory() as temporary:
                folder = Path(temporary)
                curl = folder / 'curl'
                curl.write_text('''#!/bin/sh
while [ "$#" -gt 0 ]; do
  if [ "$1" = --output ]; then destination="$2"; shift; fi
  shift
done
printf '#!/bin/sh\\nprintf executed > "$PAYLOAD_MARKER"\\n' > "$destination"
exit 23
''')
                curl.chmod(0o755)
                source = (ROOT / relative).read_text()
                definition = re.search(r'(?ms)^' + function + r'\(\) \(\n.*?^\)', source).group()
                env = dict(os.environ, PATH=f'{folder}:/usr/bin:/bin', TMPDIR=str(folder),
                           PAYLOAD_MARKER=str(folder / 'executed'))
                result = subprocess.run(['/bin/zsh', '-f', '-c', definition + '\n' + function],
                                        env=env, capture_output=True, timeout=10)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((folder / 'executed').exists())
                self.assertEqual([p.name for p in folder.iterdir()], ['curl'])

    def test_fzf_bootstrap_does_not_call_missing_fzf(self):
        source = (ROOT / 'JobsCommand@Flutter/MacOS/配置相关/【MacOS】⚙️双击安装Cocoapods.command/【MacOS】⚙️双击安装Cocoapods.command').read_text()
        definition = re.search(r'(?ms)^  install_fzf\(\) \{\n.*?^  }', source).group()
        with tempfile.TemporaryDirectory() as temporary:
            prefix = '''fzf_select() { print BROKEN_MISSING_FZF; return 99; }
error_echo() { print -r -- "$*"; }
success_echo() { print -r -- "$*"; }
'''
            result = subprocess.run(['/bin/zsh', '-f', '-c', prefix + definition + '\ninstall_fzf'],
                                    input='\n', env=dict(os.environ, PATH='/usr/bin:/bin', HOME=temporary),
                                    capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertNotIn('BROKEN_MISSING_FZF', result.stdout)

    def test_git_runtime_does_not_truncate_a_preexisting_log_symlink(self):
        for name, function in [('【MacOS】🧾更新gitmodules.command', 'initialize_runtime'),
                               ('【MacOS】🧭更新引用Git父仓=>子仓.command', 'initialize_script_runtime')]:
            source = (ROOT / name).read_text()
            definition = re.search(r'(?ms)^' + function + r'\(\) \{\n.*?^}', source).group()
            with self.subTest(script=name), tempfile.TemporaryDirectory() as temporary:
                folder = Path(temporary)
                protected = folder / 'protected'
                protected.write_text('keep')
                logfile = folder / 'predictable.log'
                logfile.symlink_to(protected)
                result = subprocess.run(['/bin/zsh', '-f', '-c', 'LOG_FILE="$1"\n' + definition + '\n' + function,
                                         'fixture', str(logfile)], capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(protected.read_text(), 'keep')
                logs = list(folder.glob('predictable.log.*'))
                self.assertEqual(len(logs), 1)
                self.assertEqual(logs[0].stat().st_mode & 0o777, 0o600)


if __name__ == '__main__':
    unittest.main()
