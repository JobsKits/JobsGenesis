#!/usr/bin/env python3
"""递归盘点脚本并只做语法检查；不执行被审计脚本，不安装任何依赖。

直接运行本文件即可，只有 Python 标准库依赖，不需要配套 Scripts 或 Tests。
默认扫描本文件所在目录及其子目录，结果只输出到终端；--json 才保存报告。
Shell、Node.js、PowerShell 使用本机已有检查器，缺少时明确记录为未验证。
"""

from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from fnmatch import fnmatchcase
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile


EXTENSIONS = {'.command', '.sh', '.bash', '.zsh', '.py', '.js', '.mjs', '.cjs',
              '.ps1', '.psm1', '.psd1', '.bat', '.cmd'}
EXCLUDED = {'.git', '.hg', '.svn', '.codegraph', '.build', 'node_modules', 'Pods',
            'PodsManual', 'DerivedData', '.venv', 'venv', '__pycache__', 'dist',
            'build', '.next', '.dart_tool', 'vendor', 'vendors', 'Vendor', 'Vendors',
            'ThirdParty', 'third_party', 'third-party'}
EXCLUDED_PATTERNS = ('ManualBy*Pods@Pods',)
POWERSHELL_PARSER = r'''
$ErrorActionPreference = 'Stop'
$tokens = $null; $parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    $env:JOBS_AUDIT_FILE, [ref]$tokens, [ref]$parseErrors) | Out-Null
if ($parseErrors.Count) {
    $parseErrors | ForEach-Object { [Console]::Error.WriteLine($_.ToString()) }
    exit 1
}
exit 0
'''


def discover(root: Path):
    """忽略生成目录和符号链接；读取失败不能变成一次虚假的通过。"""
    def scan_error(error):
        raise error

    for folder, directories, files in os.walk(root, onerror=scan_error, followlinks=False):
        directories[:] = sorted(name for name in directories
                                if name not in EXCLUDED
                                and not any(fnmatchcase(name, pattern) for pattern in EXCLUDED_PATTERNS)
                                and not (Path(folder) / name).is_symlink())
        for name in sorted(files):
            candidate = Path(folder) / name
            if (candidate.suffix.lower() in EXTENSIONS and not candidate.is_symlink()
                    and candidate.is_file()):
                yield candidate


def shell_kind(path: Path, header: str) -> str:
    if header.startswith('#!'):
        words = shlex.split(header[2:])
        # 只检查命令位置，不能把 Python / echo 的 bash 参数误认成解释器。
        if words and Path(words[0]).name == 'env':
            words = words[1:]
            while words:
                if (words[0] in {'-S', '--split-string', '-i', '--ignore-environment'}
                        or '=' in words[0] and not words[0].startswith('-')):
                    words = words[1:]
                elif words[0] in {'-u', '--unset'} and len(words) > 1:
                    words = words[2:]
                elif words[0] == '--':
                    words = words[1:]
                    break
                else:
                    break
        if words and Path(words[0]).name in {'zsh', 'bash', 'sh', 'dash', 'ksh'}:
            return Path(words[0]).name
        raise ValueError('不支持的 Shell shebang：' + header)
    if path.suffix.lower() == '.zsh':
        return 'zsh'
    if path.suffix.lower() == '.bash':
        return 'bash'
    raise ValueError('Shell 文件缺少可确定的解释器')


def check_file(path: Path, root: Path, timeout: float = 20) -> dict:
    result = {'path': path.relative_to(root).as_posix(), 'status': 'failed'}
    try:
        if path.is_symlink():
            raise ValueError('不读取符号链接脚本')
        flags = (os.O_RDONLY | getattr(os, 'O_BINARY', 0) | getattr(os, 'O_NONBLOCK', 0)
                 | getattr(os, 'O_NOFOLLOW', 0))
        with os.fdopen(os.open(path, flags), 'rb') as source:
            if not stat.S_ISREG(os.fstat(source.fileno()).st_mode):
                raise ValueError('只读取普通脚本文件')
            data = source.read()
        result.update(bytes=len(data), sha256=hashlib.sha256(data).hexdigest())
        suffix = path.suffix.lower()
        if suffix == '.py':
            # compile 接受源编码声明，不导入模块，也不写 __pycache__。
            compile(data, str(path), 'exec')
            result.update(status='passed', checker='python-compile')
            return result
        # 屏蔽 shell / Node 注入入口，不加载用户启动配置。
        env = {key: value for key, value in os.environ.items()
               if key not in {'BASH_ENV', 'ENV', 'ZDOTDIR', 'NODE_OPTIONS', 'NODE_PATH', 'SHELLOPTS', 'BASHOPTS'}
               and not key.startswith('BASH_FUNC_')}
        if suffix in {'.bat', '.cmd'}:
            result.update(status='skipped', checker='none', detail='cmd.exe 没有可靠的仅解析模式；需 Windows 隔离测试')
            return result
        if suffix in {'.ps1', '.psm1', '.psd1'}:
            checker = 'pwsh'
            env['JOBS_AUDIT_FILE'] = str(path)
            env['POWERSHELL_TELEMETRY_OPTOUT'] = '1'
            env['DOTNET_CLI_TELEMETRY_OPTOUT'] = '1'
            arguments = ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', POWERSHELL_PARSER]
        elif suffix in {'.mjs', '.cjs', '.js'}:
            checker = 'node'
            arguments = ['--check', str(path)]
        else:
            header = data.split(b'\n', 1)[0].decode('utf-8')
            checker = shell_kind(path, header)
            arguments = (['--noprofile', '--norc', '-n'] if checker == 'bash'
                         else ['-f', '-n'] if checker == 'zsh' else ['-n']) + [str(path)]
        executable = shutil.which(checker)
        if not executable and checker == 'pwsh':
            checker = 'powershell'
            executable = shutil.which(checker)
        result['checker'] = checker
        if not executable:
            missing = 'pwsh / powershell' if checker == 'powershell' else checker
            result.update(status='skipped', detail='未安装语法检查器：' + missing)
            return result
        process = subprocess.run([executable, *arguments], stdin=subprocess.DEVNULL,
                                 capture_output=True, text=True, errors='replace',
                                 timeout=timeout, env=env, cwd=root)
        result['status'] = 'passed' if process.returncode == 0 else 'failed'
        if process.stdout or process.stderr:
            result['detail'] = (process.stdout + process.stderr)[:8000]
    except (OSError, ValueError, SyntaxError, subprocess.TimeoutExpired) as error:
        result['detail'] = str(error)
    return result


def write_report(destination: Path, report: dict):
    """同目录原子替换报告，避免中途失败留下半个 JSON。"""
    if destination.is_symlink() or destination.exists() and not destination.is_file():
        raise ValueError('报告目标必须是普通文件路径，不能是符号链接或特殊文件')
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix='.jobs-audit-', dir=destination.parent)
    try:
        with os.fdopen(descriptor, 'w', encoding='utf-8') as output:
            json.dump(report, output, ensure_ascii=False, indent=2)
            output.write('\n')
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            'macOS / Linux：python3 "🔎审计脚本.py"\n'
            'Windows：py -3 "🔎审计脚本.py"\n'
            '另存报告：python3 "🔎审计脚本.py" --json "审计结果.json"\n'
            '退出码：0=已检查项无失败；1=失败或严格模式有未验证项；2=参数或扫描错误。'
        ),
    )
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent,
                        help='扫描根目录，默认是本脚本所在目录')
    parser.add_argument('--json', type=Path, help='另存逐文件结果和内容哈希')
    parser.add_argument('--require-all', action='store_true', help='任何无法检查的文件也返回非零')
    parser.add_argument('--jobs', type=int, default=4, help='并发检查数，1–32，默认 4')
    args = parser.parse_args(argv)
    if not 1 <= args.jobs <= 32:
        parser.error('--jobs 必须介于 1 和 32')
    try:
        root = args.root.resolve(strict=True)
        if not root.is_dir():
            parser.error('--root 必须是目录')
        paths = list(discover(root))
        if not paths:
            parser.error('没有发现脚本，不能报告检查通过')
        destination = None
        if args.json:
            if args.json.is_symlink():
                parser.error('--json 不能指向符号链接')
            destination = args.json.resolve()
            if (destination.suffix.lower() in EXTENSIONS
                    or destination.exists() and any(destination.samefile(path) for path in paths)):
                parser.error('--json 不能覆盖脚本源文件')
            if destination.exists() and not destination.is_file():
                parser.error('--json 必须是普通文件路径')
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            results = list(pool.map(lambda path: check_file(path, root), paths))
        counts = Counter(row['status'] for row in results)
        report = {'schema_version': 1, 'root': str(root), 'scope': 'syntax-only',
                  'excluded_directory_names': sorted(EXCLUDED),
                  'excluded_directory_patterns': list(EXCLUDED_PATTERNS),
                  'counts': dict(counts), 'files': results}
        if destination is not None:
            write_report(destination, report)
    except (OSError, ValueError, RuntimeError) as error:
        print('审计失败：' + str(error), file=sys.stderr)
        return 2
    for row in results:
        if row['status'] == 'failed':
            print(json.dumps(row, ensure_ascii=False))
    print(f"共 {len(results)} 个文件：通过 {counts['passed']}，失败 {counts['failed']}，未验证 {counts['skipped']}。")
    print('仅表示语法结果；未执行安装、卸载、Git 写入或脚本业务。')
    if counts['skipped']:
        print('存在未验证文件；--require-all 可将缺失检查器 / 不支持的类型设为失败。')
    return int(bool(counts['failed'] or (args.require_all and counts['skipped'])))


if __name__ == '__main__':
    raise SystemExit(main())
