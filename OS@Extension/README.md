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

面向开发工作的桌面右键扩展分类目录；本目录没有独立 Git，各平台源码由各自仓库管理。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、平台与能力 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 平台 | 当前功能覆盖 |
| --- | --- |
| [macOS Finder](./MacOS@Extension/README.md) | IDE 打开、Git 拉取 / 远端地址、路径复制、运行授权、终端 / Pod / CodeGraph / 空白提交、Flutter 工具组，以及 iOS / Android / Harmony 模拟器。 |
| [Windows 文件资源管理器](./WindowsOS@Extension/README.md) | IDE 打开、Git / 路径 / 终端、Flutter 工具组、Android / Harmony 模拟器与检测修复；没有 iOS 模拟器和 Xcode 构建。 |

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录与运行入口 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `./MacOS@Extension/`：<u>[**Swift**](https://www.swift.org/)</u> 宿主 App、Finder Sync Extension 与原生 zsh 工具；[总安装与卸载入口](./MacOS@Extension/README.md)直接位于该仓根。
- `./WindowsOS@Extension/`：[**PowerShell**](https://learn.microsoft.com/powershell/) 业务、用户级注册表菜单与独立功能包；[组合面板与单包入口](./WindowsOS@Extension/README.md)。
- 各 `Jobs*` 功能目录自带 README，说明显示条件、菜单动作、依赖、确认、输出与风险；成对安装 / 卸载共用功能 README，不额外包装同名目录。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、使用边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

先按平台总览找到所需功能，再阅读包内说明。安装可能编译 / 注册扩展或修改当前用户菜单，业务动作按各功能独立确认；菜单安装不代表已自动执行 Git、构建或模拟器维护。本文仅对账目录与现有入口，未执行安装、卸载、桌面刷新或业务写入。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
