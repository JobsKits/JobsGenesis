# `OS@Extension`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#%E5%89%8D%E8%A8%80)
- [一、平台与能力](#jobs-toc-heading-2)
- [二、目录与运行入口](#jobs-toc-heading-3)
- [三、使用边界](#jobs-toc-heading-4)

</details>
<!-- jobs-toc:end -->

---

## 🔥 <span id="前言">前言</span>

**最低支持系统：Windows 10 64 位（x64）。** 这是当前最低支持目标；具体最低 build 尚未锁定，完整实机兼容性仍待验证。最低基线不等于所有功能已经实测通过。

面向开发工作的桌面右键扩展分类目录；本目录没有独立 Git，各平台源码由各自仓库管理。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、平台与能力 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 平台 | 当前功能覆盖 |
| --- | --- |
| [macOS Finder](./MacOS@Extension/README.md) | IDE 打开、Git 拉取 / 提交回退 / 远端地址、路径复制、运行授权 / 解除运行授权、终端 / Pod / CodeGraph / 空白提交、Flutter 工具组，iOS / Android / Harmony 模拟器创建及 Android / Harmony 模拟器检测与修复。 |
| [Windows 文件资源管理器](./WindowsOS@Extension/README.md) | IDE 打开、Git 提交回退 / 其它 Git 操作、路径 / 终端、运行授权 / 解除运行授权、Flutter 工具组，Android / Harmony 模拟器创建及检测与修复；没有 iOS 模拟器和 Xcode 构建。 |

**Windows 版本限制：** 资源管理器扩展当前以 Windows 10 / 11 图形桌面及系统 PowerShell 5.1 Desktop 为目标，完整实机验收尚未完成；XP / Vista / Windows 8 不支持当前入口。Windows 7 SP1 / 8.1 补装 WMF 5.1 后仅可探索基础静态菜单，不能视为支持承诺。Windows 11 在“显示更多选项”内使用；x86 / ARM64、原生菜单编译及 SDK / 模拟器业务另有限制，无统一最低 build 保证。测试前阅读 [Windows 版本矩阵与虚拟机边界](./WindowsOS@Extension/README.md#windows-compatibility)。

两端安装面板均展开可执行的 Flutter 子菜单，支持逐项勾选及组内全选 / 全不选；同包只安装一次，重装时按本次 Flutter 选择更新菜单。macOS 提供十九项叶子功能；Windows 按其已实现的功能列出，平台差异见各自说明。

两端的“Git操作 → Git 提交回退”仅对有效 Git 工作树内的普通文件夹显示，支持独立仓库、嵌套子 Git、子模块和 linked worktree。点击后在终端选择 upstream soft / hard、历史提交 soft / hard、tag hard 或 reflog hard，共六种模式；hard 必须精确输入 `YES`。功能自包含，不要求安装 SourceTree 脚本仓库。安装与运行细节见 [macOS 回退说明](./MacOS@Extension/JobsGitRollback/README.md)和 [Windows 回退说明](./WindowsOS@Extension/JobsGitRollback/README.md)。

两端桌面空白菜单均提供“Harmony 模拟器检测与修复”，仅操作精确选中的本机实例；普通单文件菜单同时提供“运行授权”和“解除运行授权”。macOS 清除 POSIX 执行位，Windows 按当前用户的文件执行权限处理，详细确认、回滚与限制见各包说明。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录与运行入口 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `./MacOS@Extension/`：<u>[**Swift**](https://www.swift.org/)</u> 宿主 App、Finder Sync Extension 与原生 zsh 工具；[总安装与卸载入口](./MacOS@Extension/README.md)直接位于该仓根。
- `./WindowsOS@Extension/`：[**PowerShell**](https://learn.microsoft.com/powershell/) 业务、用户级注册表菜单与独立功能包；[组合面板与单包入口](./WindowsOS@Extension/README.md)。
- 各 `Jobs*` 功能目录自带 README，说明显示条件、菜单动作、依赖、确认、输出与风险；成对安装 / 卸载共用功能 README，不额外包装同名目录。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、使用边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

先按平台总览找到所需功能，再阅读包内说明。安装可能编译 / 注册扩展或修改当前用户菜单，业务动作按各功能独立确认；菜单安装不代表已自动执行 Git、项目构建或模拟器维护。各平台的构建、菜单登记、画面与业务验证范围分别记录在对应功能说明中。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
