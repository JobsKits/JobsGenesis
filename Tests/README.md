# JobsGenesis 隔离回归测试

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、功能与文件](#jobs-toc-heading-2)
- [二、运行方式](#jobs-toc-heading-3)
- [三、依赖与执行边界](#jobs-toc-heading-4)
- [四、其它隔离回归入口](#jobs-toc-heading-5)
- [五、Windows 虚拟机原生回归](#windows-native-regression)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

本目录验证根目录脚本的解析、清理边界与安装故障处理。用户日常运行[脚本审计器](../🔎审计脚本.py)或[缓存清理入口](../【MacOS】🧹清理缓存与构建产物.command)不需要此目录。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、功能与文件 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 文件 | 验证范围 |
| --- | --- |
| [test_script_audit.py](./test_script_audit.py) | 只解析不执行业务、语法错误、启动环境注入屏蔽、解释器识别、缺少检查器、Windows 内置 PowerShell 回退、严格模式、特殊文件与供应商目录排除、报告源码覆盖保护、从其它工作目录启动单文件入口 |
| [test_cache_cleanup.py](./test_cache_cleanup.py) | 扫描 / 预览 / 删除过程中的目标消失、快照变化、权限失败、符号链接替换、仅缓存模式，以及不支持安全删除的运行时拒绝执行 |
| [test_installer_safety.py](./test_installer_safety.py) | Homebrew 卸载入口的取消与下载失败、VS Code 配置的备份 / 发布失败恢复、下载辅助函数、fzf 初始化和日志符号链接保护 |
| [test_text_replacement.py](./test_text_replacement.py) | 文本字面量替换、失败退出、已有备份与失败时原文件保留、二进制 / 链接 / 构建目录排除，以及输入结束取消 |
| [WindowsRegression.ps1](./WindowsRegression.ps1) | Windows PowerShell 5.1 原生测试编排：源码 Parser / BOM、Git 健康检查、38 套隔离回归、逐套超时与 JSON / 分离日志 |
| [WindowsLaunchers.Tests.ps1](./WindowsLaunchers.Tests.ps1) | 六个 Windows 源码根的 CMD 转发入口检查，以及延迟展开开启时含中文、空格、`!`、`[]` 路径和参数的真实假命令回归 |
| [DoctorBuild.Tests.ps1](./DoctorBuild.Tests.ps1) | 假 Python 验证体检 EXE 构建的各步骤失败即停，以及缺失、空产物与有效产物六种分支 |
| [PythonBat.Tests.ps1](./PythonBat.Tests.ps1) | 独立补充回归：检查十个 Python BAT，并以实际片段和假命令验证 `!` 路径、虚拟环境失败停止、空行 / EOF 及精确 `YES` 门禁 |
| `Reports/` | 留存的 JSON 结果与原始日志归档；按文件中的路径、内容哈希与验证环境判断适用范围，不代表当前工作区自动通过 |

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

在当前 `Tests/` 目录运行单组测试：

```shell
python3 -B -m unittest discover \
  -s . \
  -p 'test_script_audit.py' \
  -v
```

将 `-p` 改为对应文件名即可选择清理或安装测试；运行全部组：

```shell
python3 -B -m unittest discover \
  -s . \
  -p 'test_*.py' \
  -v
```

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、依赖与执行边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

使用 Python 标准库 `unittest`；Shell 相关用例还依赖本机解释器。测试使用临时目录和替身命令进行故障注入，不以真实安装、卸载、系统清理、联网或远端写入作为验收动作。代码通过相对位置读取本仓及相邻功能脚本，缺少对应源码时应先核对检出范围。

终端输出各用例和整体结果，退出码非零表示失败；运行测试不会自动刷新 `Reports/`。这些测试覆盖的是列出的边界，不能代替 Windows 桌面、真实网络、安装结果或 GUI 的运行验证。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、其它隔离回归入口 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

这些入口属于各独立子仓；根 `unittest discover` 不会自动运行。先按就近说明检查依赖，再选择需要的组，不能用根测试成功代替其它组的结论。

| 领域 | 测试入口或说明 |
| --- | --- |
| Windows Flutter | [Portable.Tests.ps1](../JobsCommand@Flutter/WindowsOS/Tests/Portable.Tests.ps1) |
| Windows Git | [Regression.ps1](../JobsCommand@Gits/WindowsOS/Tests/Regression.ps1)、[GitProxyConfigurator.Tests.ps1](../JobsCommand@Gits/WindowsOS/Tests/GitProxyConfigurator.Tests.ps1) |
| Windows SourceTree | [SourceTree.Tests.ps1](../SourceTree.command/WindowsOS/Tests/SourceTree.Tests.ps1)、[Safety.Tests.ps1](../SourceTree.command/WindowsOS/Tests/Safety.Tests.ps1) |
| Windows 文本工具 | [Regression.ps1](../JobsCommand@Others/WindowsOS/Tests/Regression.ps1)、[执行说明](../JobsCommand@Others/WindowsOS/Tests/README.md) |
| Windows 环境与容器 | [Regression.ps1](../JobsSh.sh/WindowsOS/Tests/Regression.ps1)、[执行说明](../JobsSh.sh/WindowsOS/Tests/README.md) |
| Git 目录恢复 | [test_markdown_toc_checkout.py](../JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_markdown_toc_checkout.py)；临时仓库中验证首次检出、恢复、缺工具停止与未配置跳过 |

在当前 `Tests/` 目录运行，例如：

```shell
pwsh -NoLogo -NoProfile \
  -File '../SourceTree.command/WindowsOS/Tests/Safety.Tests.ps1'
```

PowerShell 的跨平台夹具通过不等于 Windows 实机通过；CMD 原生分支只在 Windows 执行，macOS 会明确跳过该分支。当前范围、修复与验证证据见[脚本审计与升级报告](../脚本审计与升级报告.md)。

## 五、<span id="windows-native-regression">Windows 虚拟机原生回归</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

[WindowsRegression.ps1](./WindowsRegression.ps1) 只接受系统 [**Windows PowerShell**](https://learn.microsoft.com/powershell/) 5.1，使用已安装的 [**Git for Windows**](https://gitforwindows.org/)，不会安装依赖。在虚拟机中保留完整源码和相关子仓，从当前 `Tests/` 目录执行：

```powershell
powershell.exe `
  -NoLogo `
  -NoProfile `
  -STA `
  -ExecutionPolicy Bypass `
  -File '.\WindowsRegression.ps1'
```

先检查六个 Windows 源码根和四个指定文件的 Parser / UTF-8 BOM，并运行 `git --version`；预检失败停止。随后分别启动独立 5.1 进程，执行五个脚本仓、右键扩展、CMD 转发及体检构建的 38 套夹具。Git 仅允许本地 file 传输，代理 / 安装 / 构建业务使用替身；注册表和 ACL 用例只操作测试专属临时对象。进程级执行策略不持久修改系统策略，企业组策略限制仍须遵守。

| 参数 | 默认值与作用 |
| --- | --- |
| `-OutputDirectory` | 省略时创建系统临时目录中的唯一 `JobsWindowsRegression-*`；指定时必须为空目录，避免覆盖报告 |
| `-TimeoutSeconds` | 每套 300 秒，支持 1–86400 秒 |
| `-SuiteTimeoutSeconds` | 在 PowerShell 内通过哈希表按套件 ID 覆写，如 `@{'Flutter.Portable'=600}`；ID 以脚本显式清单为准 |

每套保存独立 `*.stdout.log`、`*.stderr.log`，并更新 `results.json`，记录系统、架构、实际 PowerShell / Git 版本、检查文件数、真实退出码和耗时；5.1 的信息流转换为可读文本，保留 `SKIP` 证据。超时只终止本轮测试进程树并保留已有日志；`Ctrl+C` 可中止。退出码 `0` 表示全部套件通过，`1` 表示预检阻塞、失败或超时，`2` 表示无失败但有明确 `SKIP` 的部分验证，不能把跳过算成通过。符号链接权限不足时只跳过对应链接断言，其余检查继续；未选择的原生编译分支也明确跳过。结果仅适用于记录的系统与架构；Windows 11 ARM 不能替代 x64、旧系统或真实菜单安装、工具链构建验收。

Python BAT 补充测试独立运行，不计入上述 38 套：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\PythonBat.Tests.ps1`。它只执行受控片段和临时替身，不运行完整打包脚本、Python 安装器或真实构建。中文 BAT 保留 UTF-8 并使用 CRLF；对应应用目录的 Git 属性保证检出行尾。片段在真实隐藏控制台中运行，异常 stderr 或命令解析错误均使测试失败。

2026-10-26 在 Windows 11 ARM64 / 系统 PowerShell 5.1 中的完整回归、定向重测、跳过项与源码哈希见[本轮原生报告](./Reports/windows11-arm64-2026-10-26/summary.json)。报告保留各轮原始结果，汇总采用各套最近一次有效原生结果，不表示最终快照重新执行全部 38 套。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
