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
| `Reports/` | 留存的 JSON 结果；按文件中的路径、内容哈希与验证环境判断适用范围，不代表当前工作区自动通过 |

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

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
