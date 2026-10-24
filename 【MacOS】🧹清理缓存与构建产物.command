#!/bin/zsh
# shell: zsh
# 脚本自述：递归识别缓存特征，清理脚本所在目录内的缓存与构建产物。
# 默认先预览，再直接回车清除；输入任意字符取消，--dry-run 只预览，--yes 用于无人值守。
# 不依赖仓库名、子模块清单或固定工程路径；仅使用 zsh 与 Python 3 标准库。

SCRIPT_SOURCE="${(%):-%x}"
SCRIPT_PATH="${SCRIPT_SOURCE:A}"
SCRIPT_DIR="${SCRIPT_PATH:h}"

main() {
  if ! command -v python3 >/dev/null 2>&1; then
    print -u2 -- '需要 Python 3（python3）；本脚本不会自动安装依赖。'
    return 1
  fi
  local cleaner_code
  cleaner_code="$(cat <<'PYTHON'
import argparse
from contextlib import contextmanager
import inspect
import json
import os
from pathlib import Path
import shutil
import stat
import sys

# 只维护通用特征，不列举任何仓库或工程的绝对/相对路径。
PROTECTED_NAMES = {'.git', '.hg', '.svn', '.codegraph'}
CACHE_DIRS = {
    '__pycache__', '.pytest_cache', '.mypy_cache', '.ruff_cache', '.pytype',
    '.cache', '.parcel-cache', '.turbo', '.vite', '.sass-cache', '.gradle',
    'ModuleCache.noindex', 'Index.noindex', 'SDKStatCaches.noindex',
    'CompilationCache.noindex', 'SDKExplicitPrecompiledModules',
    'Intermediates.noindex',
}
BUILD_DIRS = {'.build', '.dart_tool', '.next', '.nuxt', '.output', '.svelte-kit'}
CACHE_FILES = {'.DS_Store', '.eslintcache', '.stylelintcache'}
CACHE_SUFFIXES = ('.pyc', '.pyo', '.tsbuildinfo')
CACHEDIR_SIGNATURE = b'Signature: 8a477f597d28d172789f06886806bc55'


def display_path(path):
    # 转义换行、制表符与控制字符，文件名不能伪造终端输出。
    return json.dumps(str(path.relative_to(ROOT)), ensure_ascii=False)


def say(message, color=None):
    if color and sys.stdout.isatty() and 'NO_COLOR' not in os.environ:
        print('\033[' + color + 'm' + message + '\033[0m', flush=True)
    else:
        print(message, flush=True)


def generated_directory(path):
    name = path.name
    if name in CACHE_DIRS or (name == 'cache' and path.parent.name == '.angular'):
        return '缓存目录'
    build_container = (
        name in BUILD_DIRS or name in {'build', 'Build', 'dist', 'target', 'out'}
        or name.endswith(('DerivedData', '.dSYM')) or name.startswith('DerivedData-')
    )
    # Rust target 等输出根目录也可能携带 CACHEDIR.TAG；仅缓存模式不能整棵删除。
    if ARGS.cache_only and build_container:
        return None
    tag = path / 'CACHEDIR.TAG'
    if tag.is_file() and not tag.is_symlink():
        with tag.open('rb') as handle:
            if handle.read(len(CACHEDIR_SIGNATURE)) == CACHEDIR_SIGNATURE:
                return 'CACHEDIR.TAG 标记的缓存'
    if ARGS.cache_only:
        return None
    if name in BUILD_DIRS or name.endswith(('DerivedData', '.dSYM')) or name.startswith('DerivedData-'):
        return '构建产物目录'
    # build / dist / target 可能是源码目录，必须同时存在生成器特征。
    if name in {'build', 'Build'} and any((path / marker).exists() for marker in (
        'CMakeCache.txt', 'CMakeFiles', 'build.ninja', 'Intermediates.noindex',
        'XCBuildData', '.last_build_id',
    )):
        return '带构建标记的输出目录'
    if name == 'dist' and (path / '.vite' / 'manifest.json').is_file():
        return 'Vite 构建输出'
    if name == 'target' and (
        (path / '.rustc_info.json').is_file()
        or ((path.parent / 'pom.xml').is_file() and (path / 'maven-status').is_dir())
    ):
        return 'Rust / Maven 构建输出'
    return None


def file_signature(st):
    return (st.st_dev, st.st_ino, st.st_mode, st.st_size, st.st_mtime_ns, st.st_ctime_ns)


def inspect_target(path):
    """一次遍历统计占用与快照；含版本元数据/挂载点的目录不能整棵删除。"""
    snapshot = {}
    allocated = 0
    protected = False
    pending = [path]
    while pending:
        item = pending.pop()
        st = item.lstat()
        if item.name in PROTECTED_NAMES or st.st_dev != ROOT_DEVICE or os.path.ismount(item):
            protected = True
            continue
        snapshot[str(item.relative_to(path))] = file_signature(st)
        allocated += getattr(st, 'st_blocks', 0) * 512
        if stat.S_ISDIR(st.st_mode):
            with os.scandir(item) as entries:
                pending.extend(Path(entry.path) for entry in entries)
        # lstat + S_ISDIR 不跟随目录内的符号链接。
    return snapshot, allocated, protected


def plan_cleanup():
    targets = []
    pending = [ROOT]
    while pending:
        directory = pending.pop()
        try:
            with os.scandir(directory) as entries:
                children = sorted(entries, key=lambda entry: entry.name)
        except FileNotFoundError:
            # 扫描队列不是文件系统快照；构建进程可能已移走待访问目录。
            if directory == ROOT:
                raise
            say('扫描时路径已消失，跳过：' + display_path(directory), '33')
            continue
        for entry in children:
            path = Path(entry.path)
            try:
                if entry.name in PROTECTED_NAMES or entry.is_symlink():
                    continue
                st = entry.stat(follow_symlinks=False)
                if st.st_dev != ROOT_DEVICE or os.path.ismount(path):
                    continue
                is_dir = stat.S_ISDIR(st.st_mode)
                if is_dir:
                    if ARGS.cache_only and (
                        entry.name.endswith(('.app', '.appex', '.dSYM'))
                        or (entry.name == 'Products' and path.parent.name == 'Build')
                    ):
                        continue
                    reason = generated_directory(path)
                elif stat.S_ISREG(st.st_mode):
                    reason = '缓存文件' if entry.name in CACHE_FILES or entry.name.endswith(CACHE_SUFFIXES) else None
                else:
                    continue
                if reason:
                    snapshot, allocated, protected = inspect_target(path)
                    if not protected:
                        targets.append((path, reason, snapshot, allocated))
                        continue  # 已选整个目录，不重复列举或统计内部文件。
                    say('保留含版本元数据或挂载点的目录，继续检查其余内容：' + display_path(path), '33')
                if is_dir:
                    pending.append(path)
            except FileNotFoundError:
                # 扫描统计中有任何条目消失时舍弃整个候选，
                # 不把不完整快照交给删除阶段。权限错误仍严格报错。
                say('扫描时路径或其内容已消失，跳过本项：' + display_path(path), '33')
    return sorted(targets, key=lambda target: str(target[0]))


def target_missing(path):
    # 根目录消失仍是错误；lstat 避免把悬空符号链接误判为已消失。
    ROOT.lstat()
    try:
        path.lstat()
    except FileNotFoundError:
        return True
    return False


def validate_target(target):
    """复核快照；整个目标已消失时返回 False，其它变化仍报错。"""
    path, _, snapshot, _ = target
    if path == ROOT or ROOT not in path.parents or path.is_symlink():
        raise RuntimeError('路径越界、符号链接或路径已变化：' + display_path(path))
    try:
        if path.resolve(strict=True) != path:
            raise RuntimeError('路径越界、符号链接或路径已变化：' + display_path(path))
        current, _, protected = inspect_target(path)
    except FileNotFoundError:
        if target_missing(path):
            return False
        # 目标仍在，仅内部内容消失时保留严格的快照检查。
        raise
    if protected or current != snapshot:
        raise RuntimeError('预览后内容发生变化，停止清理，请结束构建后重新运行：' + display_path(path))
    return True


@contextmanager
def open_parent_directory(path):
    """逐层固定真实目录，避免复核后父目录被换成链接导致越界删除。"""
    flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    descriptor = os.open(ROOT, flags)
    try:
        root_stat = os.fstat(descriptor)
        if (root_stat.st_dev, root_stat.st_ino) != ROOT_IDENTITY:
            raise RuntimeError('扫描根目录已被替换，停止清理。')
        for part in path.relative_to(ROOT).parts[:-1]:
            next_descriptor = os.open(part, flags, dir_fd=descriptor)
            os.close(descriptor)
            descriptor = next_descriptor
        yield descriptor
    finally:
        os.close(descriptor)


def remove_target(target):
    path, _, snapshot, _ = target

    def on_remove_error(_operation, failed_path, exc_info):
        error = exc_info[1]
        # rmtree 遍历期间内部条目可能被其它进程删除；只忽略这种错误。
        # 顶层目标消失交给外层统计，权限等其它错误必须继续上报。
        if not isinstance(error, FileNotFoundError) or Path(failed_path) == Path(path.name):
            raise error

    try:
        with open_parent_directory(path) as parent_fd:
            current = os.stat(path.name, dir_fd=parent_fd, follow_symlinks=False)
            if file_signature(current) != snapshot['.']:
                raise RuntimeError('删除前目标已变化，停止清理：' + display_path(path))
            if stat.S_ISDIR(current.st_mode):
                shutil.rmtree(path.name, dir_fd=parent_fd, onerror=on_remove_error)
            else:
                os.unlink(path.name, dir_fd=parent_fd)
    except FileNotFoundError:
        if target_missing(path):
            return False
        raise
    return True


def main():
    global ROOT_IDENTITY
    root_stat = ROOT.stat()
    ROOT_IDENTITY = (root_stat.st_dev, root_stat.st_ino)
    if not ARGS.dry_run and (
        not shutil.rmtree.avoids_symlink_attacks
        or 'dir_fd' not in inspect.signature(shutil.rmtree).parameters
    ):
        raise RuntimeError('安全删除需要支持 dir_fd 的 Python 3.11+；当前环境可使用 --dry-run。')
    say('🧹 递归清理缓存与构建产物', '1;31')
    say('扫描根目录：' + str(ROOT))
    say('模式：' + ('仅缓存，保留 DerivedData / .build 内的最终产物' if ARGS.cache_only else '拷贝前清理，包含 DerivedData / .build 等构建产物'))
    say('按通用特征识别；不跟随符号链接，不清理 Git 元数据、安装包或依赖目录本身。')
    say('请先停止正在进行的构建；匹配的整个缓存目录会删除，不应在其中保存手写源码。')
    if not ARGS.cache_only:
        say('Finder 扩展若注册在构建目录内，清理后可能失效；继续在本机使用时请加 --cache-only。', '33')
    say('已被 Git 跟踪的缓存也会清理，并显示为工作区删除；不会修改索引、提交或推送。', '33')
    if not ARGS.dry_run and not ARGS.yes:
        if not sys.stdin.isatty():
            raise RuntimeError('非交互运行请显式使用 --dry-run 或 --yes。')
        input('按回车扫描并查看清单；Ctrl+C 取消：')
    say('正在递归扫描……')
    targets = plan_cleanup()
    total = sum(target[3] for target in targets)
    for path, reason, _, allocated in targets:
        say(f'{allocated / 1024**2:9.2f} MiB  [{reason}] {display_path(path)}')
    say(f'共 {len(targets)} 项，预计释放 {total / 1e9:.3f} GB（{total / 1024**3:.3f} GiB）。', '1;34')
    if not targets:
        say('未发现匹配的缓存或构建产物。')
        return 0
    if ARGS.dry_run:
        say('预览结束，未删除任何文件。')
        return 0
    if not ARGS.yes and input('直接回车清除以上内容；输入任意字符（包括空格）后回车取消：') != '':
        say('已取消，未删除任何文件。')
        return 0
    deleted = 0
    skipped = 0
    deleted_size = 0
    deleting = False
    try:
        # 先复核所有目标再开始删除，避免确认期间新生成的内容被一并带走。
        # 已消失的目标从本次计划移除，即使同名路径重建也不再清理。
        remaining = []
        for target in targets:
            if validate_target(target):
                remaining.append(target)
            else:
                skipped += 1
                say('目标已消失，跳过：' + display_path(target[0]), '33')
        for target in remaining:
            path = target[0]
            deleting = False
            if validate_target(target):
                deleting = True
                removed = remove_target(target)
            else:
                removed = False
            if removed:
                deleted += 1
                deleted_size += target[3]
                say('已删除：' + display_path(path))
            else:
                skipped += 1
                say('目标已消失，跳过：' + display_path(path), '33')
    except (OSError, RuntimeError):
        detail = '当前失败项可能只删除了一部分。' if deleting else '在复核目标时停止。'
        say(f'清理中断，已完整删除 {deleted}/{len(targets)} 项，跳过 {skipped} 项；' + detail, '31')
        raise
    say(f'完成：已删除 {deleted} 项，跳过 {skipped} 项（目标已消失），已删除项的预览占用 {deleted_size / 1e9:.3f} GB。', '32')
    say('后续构建可能重新生成缓存；实际可用空间变化取决于文件系统。')
    return 0


ROOT = Path(sys.argv[1]).resolve(strict=True)
ROOT_DEVICE = ROOT.stat().st_dev
parser = argparse.ArgumentParser(
    prog=Path(sys.argv[2]).name,
    description='从脚本所在目录递归识别缓存；默认包括构建产物，先列清单再确认删除。',
)
parser.add_argument('--dry-run', action='store_true', help='只预览清单和占用，不删除')
parser.add_argument('--cache-only', action='store_true', help='仅清理缓存，保留最终构建产物')
parser.add_argument('--yes', action='store_true', help='输出清单后直接执行，无需交互确认')
ARGS = parser.parse_args(sys.argv[3:])
dry_run = os.environ.get('DRY_RUN', '0')
if dry_run not in {'0', '1'}:
    parser.error('DRY_RUN 只能为 0 或 1')
ARGS.dry_run = ARGS.dry_run or dry_run == '1'
try:
    sys.exit(main())
except (KeyboardInterrupt, EOFError):
    say('已取消；如已开始删除，请核对上方已删除清单。', '33')
    sys.exit(130)
except (OSError, RuntimeError) as error:
    say('错误：' + str(error), '31')
    sys.exit(1)
PYTHON
)"
  command python3 -c "$cleaner_code" "$SCRIPT_DIR" "$SCRIPT_PATH" "$@"
}

main "$@"
