"""App 构建模板搬迁回归；PyInstaller、桌面业务和用户配置均不实际运行。"""
from pathlib import Path
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import types
import unittest
import xml.etree.ElementTree as ET
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
PYTHON_TOOLS = ROOT / "JobsPythonTools.py"
LAN = PYTHON_TOOLS / "LANFileServer.py"
MOCK = PYTHON_TOOLS / "JobsMockTool.py"
TIMERS = [
    ROOT / "JobsCommand@Others/MacOS/【MacOS】Xcode编译耗时菜单栏.command/【MacOS】Xcode编译耗时菜单栏.command",
    ROOT / "JobsCommand@iOS/其他/【MacOS】⌚️Xcode编译耗时菜单栏.command/【MacOS】⌚️Xcode编译耗时菜单栏.command",
]


def shell_function(path, name):
    """只抽取真实函数定义，不运行入口或初始化。"""
    match = re.search(r"^" + re.escape(name) + r"\(\) \{\n.*?^\}", path.read_text(), re.M | re.S)
    if not match:
        raise AssertionError(f"缺少函数 {name}: {path}")
    return match.group()


class PortableAppTemplateTests(unittest.TestCase):
    def test_tracked_specs_resolve_relocated_sources_and_icons_without_pyinstaller(self):
        for source, entry, nested in [
            (LAN / "LANFileServer/LANFileServer.spec", "LANFileServer.py", True),
            (MOCK / "JobsMockTool.spec", "app.py", False),
        ]:
            with self.subTest(spec=source.name), tempfile.TemporaryDirectory() as temporary:
                original = Path(temporary) / "original"
                project = original / "source" if nested else original
                project.mkdir(parents=True)
                shutil.copy2(source, project / source.name)
                (project / entry).write_text("# fixture\n")
                icon = original / "icon.png"
                icon.write_bytes(b"fixture-icon")
                moved = Path(temporary) / "改名 中文 ' & $()"
                original.rename(moved)
                project = moved / "source" if nested else moved
                spec = project / source.name
                calls = []

                def analysis(*args, **kwargs):
                    calls.append((args, kwargs))
                    return types.SimpleNamespace(pure=[], scripts=[], binaries=[], datas=[])

                hooks = types.ModuleType("PyInstaller.utils.hooks")
                hooks.collect_all = lambda name: ([], [], [])
                namespace = {"SPECPATH": str(project), "Analysis": analysis,
                             "PYZ": lambda *a, **k: None, "EXE": lambda *a, **k: None,
                             "COLLECT": lambda *a, **k: None, "BUNDLE": lambda *a, **k: None}
                with patch.dict(sys.modules, {"PyInstaller": types.ModuleType("PyInstaller"),
                                             "PyInstaller.utils": types.ModuleType("PyInstaller.utils"),
                                             "PyInstaller.utils.hooks": hooks}):
                    exec(compile(spec.read_text(), str(spec), "exec"), namespace)
                args, options = calls[0]
                self.assertEqual([str((project / entry).resolve())], args[0])
                self.assertEqual([str(project.resolve())], options["pathex"])
                self.assertIn((str((moved / "icon.png").resolve()), "."), options["datas"])
                self.assertNotIn("/Users/", spec.read_text())

    def test_lan_launcher_uses_its_package_and_reports_missing_without_desktop_fallback(self):
        source = LAN / "【MacOS】📦生成dmg.command"
        function = shell_function(source, "resolve_project_launcher")
        with tempfile.TemporaryDirectory() as temporary:
            package = Path(temporary) / "搬迁 中文 ' $()"
            worker = package / "LANFileServer/启动LANFileServer.command"
            worker.parent.mkdir(parents=True)
            worker.write_text("# fixture")
            for start in (package, package / "wrapper"):
                start.mkdir(exist_ok=True)
                code = function + '\nSCRIPT_DIR="$1"\nresolve_project_launcher || exit $?\nprint -r -- "$PROJECT_LAUNCHER"\n'
                result = subprocess.run(["/bin/zsh", "-c", code, "fixture", str(start)],
                                        cwd="/", text=True, capture_output=True)
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual(worker.resolve(), Path(result.stdout.strip()).resolve())
            worker.unlink()
            result = subprocess.run(["/bin/zsh", "-c", code, "fixture", str(package)], cwd="/", capture_output=True)
            self.assertEqual(1, result.returncode)
        self.assertNotIn("/Users/", source.read_text())
        self.assertIn("已查找：", shell_function(source, "check_environment"))

    def test_macos_builders_put_generated_specs_in_cache_without_building(self):
        cases = [(MOCK / "build_macos.command/build_macos.command", "build_macos_app"),
                 (LAN / "LANFileServer/启动LANFileServer.command", "build_macos_app_with_arch")]
        for source, name in cases:
            with self.subTest(source=source), tempfile.TemporaryDirectory() as temporary:
                package = Path(temporary) / "源码 中文 ' $()"
                package.mkdir()
                arguments = package / "arguments"
                fake_python = package / "fake-python"
                fake_python.write_text('#!/bin/zsh\nprintf "%s\\0" "$@" > "$ARGS_FILE"\n')
                fake_python.chmod(0o755)
                (package / ".venv/bin").mkdir(parents=True)
                (package / ".venv/bin/python").symlink_to(fake_python)
                (package / "dist/App.app").mkdir(parents=True)
                code = shell_function(source, name) + '''
                  PROJECT_ROOT="$1"; PROJECT_DIR="$1"; BUILD_DIR="$1/build"
                  DIST_DIR="$1/dist"; APP_BUNDLE="$1/dist/App.app"; VENV_DIR="$1/.venv"
                  ENTRY_FILE="$1/LANFileServer.py"; APP_NAME=LANFileServer
                  PYTHON_BIN="$1/fake-python"; LOG_FILE=/dev/null
                  info_echo() { :; }; note_echo() { :; }; success_echo() { :; }
                  error_echo() { print -u2 -r -- "$@"; }
                  run_logged() { "$@"; }
                ''' + f'\n{name} arm64\n'
                result = subprocess.run(["/bin/zsh", "-c", code, "fixture", str(package)],
                                        cwd="/", env={**os.environ, "ARGS_FILE": str(arguments)}, capture_output=True)
                self.assertEqual(0, result.returncode, result.stderr.decode())
                args = arguments.read_bytes().decode().strip("\0").split("\0")
                self.assertEqual(str(package / "build/pyinstaller-spec"), args[args.index("--specpath") + 1])
                self.assertTrue((package / "build/pyinstaller-spec").is_dir())

    def test_windows_builders_keep_crlf_and_generated_spec_cache_argument(self):
        for source in (MOCK / "build_windows.bat", LAN / "LANFileServer/启动LANFileServer.bat"):
            with self.subTest(source=source):
                raw = source.read_bytes()
                self.assertEqual(0, raw.replace(b"\r\n", b"").count(b"\n"))
                text = raw.decode("utf-8-sig")
                build = next(line for line in text.splitlines() if "--specpath" in line)
                self.assertIn("build\\pyinstaller-spec", build)
                self.assertLess(text.index("mkdir "), text.index(build))

    def test_timer_templates_bundle_the_actual_hook(self):
        self.assertEqual(TIMERS[0].read_bytes(), TIMERS[1].read_bytes())
        for source in TIMERS:
            with self.subTest(source=source), tempfile.TemporaryDirectory() as temporary:
                directory = Path(temporary)
                hook = directory / "hook.sh"
                hook.write_text("# Jobs Xcode Build Timer Hook v1\n")
                contents = directory / "App 中文.app/Contents"
                code = shell_function(source, "write_info_plist") + '''
                  APP_CONTENTS="$1"; APP_MACOS="$1/MacOS"; APP_INFO_PLIST="$1/Info.plist"
                  APP_NAME=XcodeBuildTimer; HOOK_SCRIPT="$2"
                  success_echo() { :; }
                  write_info_plist
                '''
                result = subprocess.run(["/bin/zsh", "-c", code, "fixture", str(contents), str(hook)], capture_output=True)
                self.assertEqual(0, result.returncode, result.stderr.decode())
                self.assertEqual(hook.read_bytes(), (contents / "Resources/xbt-build-hook.sh").read_bytes())
                with (contents / "Info.plist").open("rb") as stream:
                    self.assertEqual("XcodeBuildTimer", plistlib.load(stream)["CFBundleExecutable"])

    @unittest.skipUnless(shutil.which("xcrun"), "需要本机 Swift 编译工具")
    def test_timer_generated_scheme_resolves_home_for_the_actual_build_user(self):
        self.assertEqual(TIMERS[0].read_bytes(), TIMERS[1].read_bytes())
        source = TIMERS[0].read_text()
        methods = []
        for name in ("executionActionXML", "xmlEscape"):
            match = re.search(r"^    private func " + name + r"\(.*?^    \}", source, re.M | re.S)
            self.assertIsNotNone(match, name)
            methods.append(match.group().replace("private func", "func", 1))
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            fixture = directory / "SchemeFixture.swift"
            fixture.write_text("import Foundation\nclass SchemeFixture {\n"
                               'private let hookScript = "/Users/configuring-user/private-build/xbt-build-hook.sh"\n'
                               + "\n".join(methods) + "\n}\n" + r'''
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fixture = SchemeFixture()
for action in ["start", "end"] {
    let xml = fixture.executionActionXML(scriptArgument: action, buildableReference: nil)
    try xml.write(to: root.appendingPathComponent(action + ".xml"), atomically: true, encoding: .utf8)
}
''')
            result = subprocess.run(["/usr/bin/xcrun", "swift", str(fixture), str(directory)],
                                    cwd="/", text=True, capture_output=True, timeout=60)
            self.assertEqual(0, result.returncode, result.stdout + result.stderr)
            build_home = directory / "实际构建用户 中文 ' $()"
            hook = build_home / ".xcode-build-timer/xbt-build-hook.sh"
            hook.parent.mkdir(parents=True)
            hook.write_text('#!/bin/zsh\nprintf "current-user-hook:%s" "$1"\n')
            hook.chmod(0o755)
            for action in ("start", "end"):
                xml = (directory / (action + ".xml")).read_text()
                command = ET.fromstring(xml).find("ActionContent").attrib["scriptText"]
                self.assertEqual('"${HOME}/.xcode-build-timer/xbt-build-hook.sh" ' + action, command)
                self.assertNotIn("/Users/configuring-user", xml)
                result = subprocess.run(["/bin/zsh", "-c", command], cwd="/", text=True,
                                        capture_output=True, env={**os.environ, "HOME": str(build_home)})
                self.assertEqual(0, result.returncode, result.stderr)
                self.assertEqual("current-user-hook:" + action, result.stdout)

    @unittest.skipUnless(shutil.which("xcrun"), "需要本机 Swift 编译工具")
    def test_timer_hook_deployment_preserves_known_files_and_blocks_conflicts(self):
        source = TIMERS[0].read_text()
        start = source.index("enum BuildTimerHookResources {")
        end = source.index("\nfinal class SchemeHookConfigurator", start)
        actual_helper = source[start:end]
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            script = directory / "Fixture.swift"
            script.write_text("import Foundation\n" + actual_helper + r'''
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fm = FileManager.default
let resource = root.appendingPathComponent("resource.sh")
try "# Jobs Xcode Build Timer Hook v1\n".write(to: resource, atomically: true, encoding: .utf8)
let target = root.appendingPathComponent("new-user/Hook.sh")
try BuildTimerHookResources.ensureInstalled(at: target, resourceURL: resource)
guard fm.isExecutableFile(atPath: target.path) else { fatalError("Hook is not executable") }
try "# Jobs Xcode Build Timer Hook v1\n# user changes\n".write(to: target, atomically: true, encoding: .utf8)
let existing = try Data(contentsOf: target)
try BuildTimerHookResources.ensureInstalled(at: target, resourceURL: nil)
guard try Data(contentsOf: target) == existing else { fatalError("Existing Hook overwritten") }
let unknown = root.appendingPathComponent("unknown.sh")
try "foreign-content".write(to: unknown, atomically: true, encoding: .utf8)
try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: unknown.path)
let folder = root.appendingPathComponent("directory.sh")
try fm.createDirectory(at: folder, withIntermediateDirectories: true)
let link = root.appendingPathComponent("symlink.sh")
try fm.createSymbolicLink(at: link, withDestinationURL: target)
for conflict in [unknown, folder, link] {
    do {
        try BuildTimerHookResources.ensureInstalled(at: conflict, resourceURL: resource)
        fatalError("Conflict was accepted")
    } catch {
        guard error.localizedDescription.contains(conflict.path) else { fatalError("Missing conflict path") }
    }
}
guard try String(contentsOf: unknown) == "foreign-content" else { fatalError("Foreign Hook overwritten") }
do {
    try BuildTimerHookResources.ensureInstalled(at: root.appendingPathComponent("missing-user/Hook.sh"), resourceURL: nil)
    fatalError("Missing bundled Hook accepted")
} catch {
    guard error.localizedDescription.contains("Contents/Resources/xbt-build-hook.sh") else { fatalError("Missing resource diagnostic") }
}
print("PORTABLE_HOOK_OK")
''')
            result = subprocess.run(["/usr/bin/xcrun", "swift", str(script), str(directory)],
                                    cwd="/", text=True, capture_output=True, timeout=60)
            self.assertEqual(0, result.returncode, result.stdout + result.stderr)
            self.assertIn("PORTABLE_HOOK_OK", result.stdout)


if __name__ == "__main__":
    unittest.main()
