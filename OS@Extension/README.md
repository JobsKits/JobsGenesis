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
| [Windows 文件资源管理器](./WindowsOS@Extension/README.md) | IDE 打开、Git 提交回退 / 其它 Git 操作、路径 / 终端、运行授权 / 解除运行授权、隐藏文件显示切换、Flutter 工具组，Android / Harmony 模拟器创建及检测与修复；没有 iOS 模拟器和 Xcode 构建。 |

**Windows 版本限制：** 资源管理器扩展当前以 Windows 10 / 11 图形桌面及系统 PowerShell 5.1 Desktop 为目标，完整实机验收尚未完成；XP / Vista / Windows 8 不支持当前入口。Windows 7 SP1 / 8.1 补装 WMF 5.1 后仅可探索基础静态菜单，不能视为支持承诺。Windows 11 在“显示更多选项”内使用；x86 / ARM64、原生菜单编译及 SDK / 模拟器业务另有限制，无统一最低 build 保证。测试前阅读 [Windows 版本矩阵与虚拟机边界](./WindowsOS@Extension/README.md#windows-compatibility)。

两端右键菜单统一在名称前加入与功能含义相近的 emoji；不同功能使用不同标识，同一功能的两端与兼容入口保持一致。例如“📋 复制绝对路径”“📦 Flutter打包”“⏪ Git 提交回退”。

IDE 项目入口先排除空目录；仅有 `.DS_Store`、`Thumbs.db`、`desktop.ini` 也视为空。Android Studio 仅对 Android 原生、Flutter 官方或 Flutter 鸿蒙项目根目录显示；VSCode 对非 iOS 的非空普通目录显示；Xcode 仅在 macOS 对明确的 iOS 工程目录或有效工程包显示。Flutter 根目录包含 `ios/` 子工程时仍优先按 Flutter 处理；纯 macOS 工程和单独的 `Package.swift` 不自动判为 iOS。菜单生成和点击打开前均复核，具体识别依据见 [macOS IDE 说明](./MacOS@Extension/JobsProjectTools/README.md)及 [Windows Android Studio 说明](./WindowsOS@Extension/JobsAndroidStudioOpener/README.md)、[Windows VSCode 说明](./WindowsOS@Extension/JobsVSCodeOpener/README.md)。

两端隐藏文件菜单都表达下一步动作：当前隐藏时为“👁️ 显示文件”，当前显示时为“🙈 隐藏文件”；读取失败时禁用，不猜测状态。macOS 对桌面和文件夹空白处提供入口，Windows 对系统桌面空白处提供入口；均只改变当前用户的显示偏好，不修改文件属性。macOS 的桌面六项由统一菜单按“新建 iOS → 新建 Android → 新建 Harmony → Android 检测修复 → Harmony 检测修复 → 隐藏文件动作”固定排序，未启用的功能直接省略。

两端安装面板均展开可执行的 Flutter 子菜单，支持逐项勾选及组内全选 / 全不选；同包只安装一次，重装时按本次 Flutter 选择更新菜单。macOS 提供十九项叶子功能；Windows 按其已实现的功能列出，平台差异见各自说明。

两端的“Git操作 → Git 提交回退”仅对有效 Git 工作树内的普通文件夹显示，支持独立仓库、嵌套子 Git、子模块和 linked worktree。点击后在终端选择 upstream soft / hard、历史提交 soft / hard、tag hard 或 reflog hard，共六种模式；hard 必须精确输入 `YES`。功能自包含，不要求安装 SourceTree 脚本仓库。安装与运行细节见 [macOS 回退说明](./MacOS@Extension/JobsGitRollback/README.md)和 [Windows 回退说明](./WindowsOS@Extension/JobsGitRollback/README.md)。

两端提供“Git操作 → 🌳 用 Sourcetree 打开”，仅在本机安装了可用的 [**Sourcetree**](https://www.sourcetreeapp.com/) 且目标属于有效 Git 工作树时展示；未安装时隐藏该项。从仓库子目录进入会打开最近的仓库根目录，子模块和 linked worktree 保留各自工作树。点击前再次复核应用和目录状态，不安装 Sourcetree，也不执行 Git 写操作。功能须通过各平台安装入口启用，详见 [macOS 项目工具](./MacOS@Extension/JobsProjectTools/README.md)和 [Windows Sourcetree 入口](./WindowsOS@Extension/JobsSourcetreeOpener/README.md)。

两端桌面空白菜单均提供“Harmony 模拟器检测与修复”，仅操作精确选中的本机实例；单个可执行格式文件同时显示“🔓 运行授权”和“🔒 解除运行授权”，根据当前执行权限互斥置灰；README、文本等普通文档不显示这两项。macOS 清除 POSIX 执行位，Windows 按当前用户的文件执行权限处理，详细确认、回滚与限制见各包说明。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录与运行入口 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `./MacOS@Extension/`：<u>[**Swift**](https://www.swift.org/)</u> 宿主 App、Finder Sync Extension 与原生 zsh 工具；[总安装与卸载入口](./MacOS@Extension/README.md)直接位于该仓根。
- `./WindowsOS@Extension/`：[**PowerShell**](https://learn.microsoft.com/powershell/) 业务、用户级注册表菜单与独立功能包；[组合面板与单包入口](./WindowsOS@Extension/README.md)。
- 各 `Jobs*` 功能目录自带 README，说明显示条件、菜单动作、依赖、确认、输出与风险；成对安装 / 卸载共用功能 README，不额外包装同名目录。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、使用边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

先按平台总览找到所需功能，再阅读包内说明。安装可能编译 / 注册扩展或修改当前用户菜单，业务动作按各功能独立确认；菜单安装不代表已自动执行 Git、项目构建或模拟器维护。各平台的构建、菜单登记、画面与业务验证范围分别记录在对应功能说明中。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
