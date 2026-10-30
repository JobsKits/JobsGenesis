# Windows 原生回归验收记录

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、当前结果](#results)
- [二、修正范围](#changes)
- [三、未验范围与跳过项](#limits)
- [四、证据与复跑](#evidence)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

本轮在运行中的 [**VMware Fusion**](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) Windows 11 ARM64 虚拟机完成原生测试。系统 build 26300，系统 [**Windows PowerShell**](https://learn.microsoft.com/powershell/) 5.1.26100.9711 / STA，[**Git**](https://git-scm.com/) 2.56.0.windows.3。测试从 2026-10-29 持续至 2026-10-30；完整结构化结论见 [summary.json](./summary.json)。

## 一、<span id="results">当前结果</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 范围 | 原生结果 |
| --- | --- |
| 五个脚本仓与 Windows 右键扩展 | 65 套中 55 Passed、10 Partial、0 Failed、0 TimedOut |
| 语法与编码 | 576 份 PowerShell 文件 Parser / UTF-8 BOM 预检通过 |
| 启动入口 | 173 个 CMD：137 个 PowerShell、36 个 WScript；真实 CMD 特殊字符、参数与退出码夹具通过 |
| Python BAT | 10 个入口的静态与受控原生片段通过；不执行完整打包 |
| 公共面板 | 管理事务、真实 WinForms 事件、Timer、日志控件通过；23 个独立包基础设施逐字节一致 |
| 三款应用构建保护 | AccountSwitcher 24 通过 / 6 跳过；TokenMonitor 25 / 6；SystemMonitor 18 / 6；无失败 |
| 流量监控 | ETW 专项 20 项、终端清理 3 项通过；管理员本地 TCP / UDP 回环和会话撤回通过 |

65 套结果以完整执行后的定向修复复测合并，**最终源码快照没有再次完整重跑 65 套**。每套最新有效证据的位置记录在 `summary.json` 的 `EffectiveSuites` 中；跳过始终记作 Partial。

## 二、<span id="changes">修正范围</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 位置 | 当前行为 |
| --- | --- |
| JobsCommand@Flutter | 安装返回有效 SDK 路径；PowerShell 5.1 正确筛选顶层 JSON 数组中的鸿蒙设备 |
| JobsCommand@Others / JobsSh.sh | 文件名内部的 `%TEMP%` 保持字面值，只展开显式环境根；文本替换拒绝输入路径及祖先链接 |
| SourceTree.command | IPv6 仓库地址正确转换为网页地址，运行与备灾副本同步 |
| Windows Flutter 工具 | 恢复环境时正确识别 `Path` 大小写；机器事件、设备和 Temurin 资产数组兼容 5.1；依赖导入保留路径末尾 NBSP |
| Windows 管理面板 | Timer 捕获原模块进度函数，避免动态闭包找不到私有函数而卡住；各公共副本包含日志拖动、选择与复制能力 |
| Python 构建入口 | 10 个 BAT 限定本次进程树 UTF-8；三款构建器统一标准流、子 Python 和日志编码 |
| JobsAppTrafficMonitor | 实现 Windows ETW 按进程流量；进程生命周期防 PID 复用错归属，空闲不重置累计，失败保留可重试的清理所有权 |
| 回归夹具 | 更新启动器清单，修正 5.1 反射、信息流、ZIP 程序集及字面路径清理；关闭子进程 stdin，避免继承桌面控制台 |

ETW 实测使用本地回环；当前 Python EXE 身份匹配，上下行各计 2,141,952 字节，其中 UDP 各增加 44,800 字节。测试结束后系统查询确认自有会话已不存在，见 [管理员日志](./applications/Traffic.Elevated.log)。本次管理员授权只用于该回环测试。

## 三、<span id="limits">未验范围与跳过项</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 10 套 Partial 包含普通用户创建符号链接的权限限制，以及未启用的原生编译 / 工具链分支。三款应用另有 18 个符号链接用例跳过。
- 未实际构建、安装所有 EXE 或 MSVC 菜单 DLL，未真实注册 / 卸载菜单、升级 SDK；构建保护用例使用隔离替身。
- PySide6 成品 GUI 的视觉、真实打包与跨机启动未验。ETW 内核链路通过不代表整个 GUI 成品已验收。
- ARM64 结果不能替代 Windows x64 或旧系统；Android / 鸿蒙的 AMD64 本地模拟器运行未验。

## 四、<span id="evidence">证据与复跑</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- [汇总与逐套证据映射](./summary.json)、[最终源码哈希清单](./final-manifest.json)、[临时运行时来源](./runtimes.json)。
- `full-65/` 保留完整 65 套原始结果；`followup-four/`、`followup-seven/`、`applications/` 与 `final-native/` 保留定向复测及应用日志。
- [原生编排器](../../WindowsRegression.ps1)支持完整运行或 `-SuiteIds` 定向复测；参数与依赖见 [Tests 说明](../../README.md#windows-native-regression)。
- 临时 Python 使用官方嵌入包，并从同版本 CPython 源码补充测试需要的 `venv` 标准库；不会替代完整构建环境。Dart 使用文档列出的镜像并核对官方 SHA-256。未提交、未推送。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
