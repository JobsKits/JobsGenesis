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
| [macOS Finder](./MacOS@Extension/README.md) | IDE 打开、Git 拉取 / 提交回退 / 远端地址、路径复制、新建空文件、运行授权 / 解除运行授权、终端 / Pod / CodeGraph / 空白提交、文件分卷合并与拆分、Flutter 工具组，iOS / Android / Harmony 模拟器创建及 Android / Harmony 模拟器检测与修复。 |
| [Windows 文件资源管理器](./WindowsOS@Extension/README.md) | IDE 打开、Git 提交回退 / 其它 Git 操作、路径 / 终端、文件分卷合并与拆分、运行授权 / 解除运行授权、隐藏文件显示切换、Flutter 工具组，Android / Harmony 模拟器创建及检测与修复；没有 iOS 模拟器和 Xcode 构建。 |

**Windows 版本限制：** 资源管理器扩展当前以 Windows 10 / 11 图形桌面及系统 PowerShell 5.1 Desktop 为目标，完整实机验收尚未完成；XP / Vista / Windows 8 不支持当前入口。Windows 7 SP1 / 8.1 补装 WMF 5.1 后仅可探索基础静态菜单，不能视为支持承诺。Windows 11 在“显示更多选项”内使用；x86 / ARM64、原生菜单编译及 SDK / 模拟器业务另有限制，无统一最低 build 保证。测试前阅读 [Windows 版本矩阵与虚拟机边界](./WindowsOS@Extension/README.md#windows-compatibility)。

两端右键菜单统一在名称前加入与功能含义相近的 emoji；不同功能使用不同标识，同一功能的两端与兼容入口保持一致。例如“📋 复制绝对路径”“📦 Flutter打包”“⏪ Git 提交回退”。

macOS 的“📃 新建文件…”由独立的 [JobsFileCreator](./MacOS@Extension/JobsFileCreator/README.md) 提供，可在总管理面板的“文件与通用工具”中单独安装 / 卸载，也可使用包内管理入口。仅在桌面和普通文件夹空白处显示；点击后输入文件名，默认 `未命名.txt`，可自行指定扩展名。确认后创建零字节文件并在 Finder 中选中；取消不创建，已有同名文件、目录或符号链接均拒绝覆盖。Windows 使用系统自带“新建”，不增加对应扩展。

Flutter 工具组以“拉取Flutter项目工程相关依赖”处理联网解析，以“提取Flutter项目工程依赖”读取本机已具备的内容，以“导入Flutter项目工程依赖”恢复快照。“📤 导入 Flutter Pub 依赖”位于导入组，提取组中有对应的 Pub 叶子。选中目标项目后在终端输入或拖入完整依赖快照；先验证清单、包源码、版本和目标声明，通过后输入 `YES` 才复制本地依赖并生成覆盖配置，原配置保留备份。普通目录、不完整快照和覆盖冲突会停止；不自动执行 `pub get`。用法与恢复见 [macOS 说明](./MacOS@Extension/JobsFlutterTools/README.md#dependency-import)及 [Windows 说明](./WindowsOS@Extension/JobsFlutterTools/README.md)。

私库迁移使用独立的“🔐 提取Flutter项目工程私库依赖”和“📥 导入Flutter项目工程私库依赖”入口，覆盖 Git、path、自建 hosted Pub 包及其间接依赖。导出保留必要源码与文件级 SHA-256；导入先核对快照类型、包名、版本和声明，精确输入 `YES` 才写入当前项目并保留原配置备份。私库与普通 Pub 快照不能混用入口；不迁移机器凭据、Git 历史或原生私服二进制，也不自动运行 `pub get`。两端的具体边界见上述 Flutter 工具说明。

IDE 项目入口先排除空目录；仅有 `.DS_Store`、`Thumbs.db`、`desktop.ini` 也视为空。Android Studio 仅对 Android 原生、Flutter 官方或 Flutter 鸿蒙项目根目录显示；VSCode 对非 iOS 的非空普通目录显示；Xcode 仅在 macOS 对明确的 iOS 工程目录或有效工程包显示。Flutter 根目录包含 `ios/` 子工程时仍优先按 Flutter 处理；纯 macOS 工程和单独的 `Package.swift` 不自动判为 iOS。菜单生成和点击打开前均复核，具体识别依据见 [macOS IDE 说明](./MacOS@Extension/JobsProjectTools/README.md)及 [Windows Android Studio 说明](./WindowsOS@Extension/JobsAndroidStudioOpener/README.md)、[Windows VSCode 说明](./WindowsOS@Extension/JobsVSCodeOpener/README.md)。

两端单文件右键提供“📄 用终端查看文件内容”：macOS 在 Terminal 查看，Windows 在独立 PowerShell 控制台流式查看（等效 CMD 的 `type` / PowerShell 的 `Get-Content`）。只接受一个普通文件；默认超过 1 MiB（1,048,576 字节）时先显示大小与阈值，精确输入 `YES` 才继续，回车或输入结束取消，`Ctrl+C` 中止。`JOBS_FILE_VIEWER_MAX_BYTES` 可配置阈值，非法值停止；二进制或未知文本另需确认。安装入口、编码与显示边界见 [macOS 功能说明](./MacOS@Extension/JobsTerminalOpener/README.md)及 [Windows 功能说明](./WindowsOS@Extension/JobsFileContentViewer/README.md)。

两端文件右键提供“🧩 合并分卷”和“✂️ 拆分文件”。合并只在选中同目录、同原文件名的一整组 `原文件名@卷号of总数` 普通分卷时显示；至少两卷，按数字卷号排序，缺卷、重复卷号、混合文件或目录均不显示。拆分只在选中一个普通文件时显示，分卷上限提供 50 / 100 / 1900 MiB 和自定义值。业务在独立终端中先说明并确认，只处理所选文件，始终保留源件；已有结果拒绝覆盖，失败保留临时结果。拆分目录为 `完整文件名.chunks`，合并结果位于分卷所在目录；兼容已有脚本的分卷文件格式。安装与运行说明见 [macOS 文件工具](./MacOS@Extension/JobsTerminalOpener/README.md)和 [Windows 文件工具](./WindowsOS@Extension/JobsFileVolumes/README.md)。

Flutter 鸿蒙工程提供“📦 打包鸿蒙（HAP + APP）”，使用工程已绑定的鸿蒙 FVM SDK，固定 release 依次构建两种包；只有两步及两类非空产物均通过才整体成功。普通 Flutter 工程不显示该快捷入口，已有签名由工程管理。菜单启用与工具链要求见 [macOS Flutter 工具](./MacOS@Extension/JobsFlutterTools/README.md)和 [Windows Flutter 工具](./WindowsOS@Extension/JobsFlutterTools/README.md)。安装 / 更新后生效，真实编译与设备安装另验。

两端 Flutter 工具组提供“📚 下载Gradled分发与构建插件”和“🚀 一键配置 Flutter 项目”。一键配置通过 [**fzf**](https://github.com/junegunn/fzf) 选择 [**FVM**](https://fvm.app/)（首选）或系统 [**Flutter**](https://flutter.dev/)，以及项目 [**jEnv**](https://www.jenv.be/)（首选）或系统 Java；Windows 使用独立的原生 [**JEnv-for-Windows**](https://github.com/FelixSelter/JEnv-for-Windows)。选择保存在项目 `.jobs/flutter-environment.json`，绝对路径换机后须重新选择。按项目 Wrapper 锁定版本下载 [**Gradle**](https://gradle.org/)，检查 Java 兼容性并校验 SHA-256，再解析 Pub 依赖、预热构建插件；提供有界超时、重试和备用下载来源，不自动升级项目 Gradle / AGP 或改系统代理。两项均可在管理面板独立勾选，依赖和执行边界见各平台 Flutter 工具说明。

“拉取Flutter项目工程相关依赖”只列 Pub、Android 原生、OpenHarmony、Web，macOS 另有 CocoaPods 与 Swift Package；“安装/切换Flutter运行环境”包含“安装/切换Flutter SDK”“安装/切换Flutter@OpenHarmony SDK”“安装/切换Java SDK”；“Flutter 资源与构建依赖”依次包含“下载Gradled分发与构建插件”“下载Flutter平台资源”“准备原生库与构建依赖（组合操作）”。“查看当前Flutter项目工程的SDK版本”位于“Flutter项目体检”。各项可独立勾选、安装与卸载，继续使用现有 Flutter 聚合包。一键配置在 Pub 后按目标复用同一内核，再以同一启动配置真实编译以触发 FFI / CMake / 插件延迟下载，最后进入已有实际运行验收。原生依赖准备会编译但不安装或启动 App；SDK / precache 不代替平台系统工具，版本、target、flavor、模式与架构限定成功范围，不承诺任意配置全部离线。Pub 源码继续使用原提取 / 导入格式；“提取Flutter项目工程依赖”和“导入Flutter项目工程依赖”分别提供对应的平台快照叶子，按宿主、工具版本、组件与工程锁指纹完整校验，冲突不覆盖。Gradle / OHPM / Hvigor 组件分开选择；native 是本机构建缓存，precache 只含 Flutter artifacts、不含 SDK 源码 / Dart；Web 原生扩展要求同宿主与 Node。导入不执行归档脚本，不保证任意跨宿主离线。

资源与组合操作的区别：`flutter precache` 缓存选定 Flutter SDK 的平台制品，组合操作则按一个目标执行 Pub 前置、平台包解析和实际构建；已有缓存会被复用，两者都不代表全部平台已经就绪。具体制品示例及执行链见 [macOS FAQ](./MacOS@Extension/JobsFlutterTools/README.md#dependency-faq)与 [Windows FAQ](./WindowsOS@Extension/JobsFlutterTools/README.md#dependency-faq)。

一键配置在 GUI 中展示水平里程碑，各阶段下面细分 SDK、平台组件、许可证、原生依赖、设备、启动配置及运行验收子节点，分别标记等待、进行中、成功、失败或需用户处理，不显示推测百分比。窗口显示工具版本与构建号，节点显示实际检测版本，连接符统一为 `>>>>>`。下半部使用真实交互终端：macOS 为 PTY + 随包离线终端，Windows 优先嵌入经典 conhost/CMD，系统拒绝嵌入时明确回退独立终端；fzf、许可证和参数仍可交互。上下两区之间的分隔条可拖动调整高度，终端/控制台同步适配尺寸，日志保持独立滚动。完整原始输出及状态事件独立保存在本次本机会话目录，不以界面滚动缓冲区代替日志，分享前须核对其中的敏感信息。

流程只为工程已有且当前系统可构建的目标准备工具链。Android 补齐 SDK、Command-line Tools、platform/build-tools 及工程要求的 NDK/CMake；macOS 的 Apple 平台准备 Xcode/CLT、CocoaPods/Bundler 或原工程的 Swift Package Manager 依赖，Windows 桌面检查或补齐 Visual Studio C++ 工作负载，Web 准备可用浏览器。后续选择真机/模拟器，空列表可重载或进入已有模拟器工具；选择已有启动配置或明确输入入口、flavor、dart-define。本人确认后实际构建、安装并运行，收到对应应用的 `app.started` 才标记运行验证通过。也可仅准备环境并保留未验收状态；Apple 许可、私库认证、真机签名及供应商架构限制不会被自动绕过。鸿蒙目标仍要求独立适配入口提供的 SDK 与已有 DevEco 工具，普通官方 Flutter 不能代替。

两端隐藏文件菜单都表达下一步动作：当前隐藏时为“👁️ 显示文件”，当前显示时为“🙈 隐藏文件”；读取失败时禁用，不猜测状态。macOS 对桌面和文件夹空白处提供入口，Windows 对系统桌面空白处提供入口；均只改变当前用户的显示偏好，不修改文件属性。macOS 的桌面六项由统一菜单按“新建 iOS → 新建 Android → 新建 Harmony → Android 检测修复 → Harmony 检测修复 → 隐藏文件动作”固定排序，未启用的功能直接省略。

两端统一管理面板均可切换“安装 / 更新”与“卸载”，展开可执行的 Flutter 子菜单，支持单项、多项及组内全选 / 全不选。默认空选，切换操作清空勾选；取消或空选不执行业务；点击安装 / 更新或卸载按钮后立即执行，不要求终端二次确认。同包只安装一次，安装所选项时保留其它功能，卸载只关闭所选动作，最后一项移除后才卸载该扩展包。2026-10-30 按各端动作清单核对，macOS 提供 45 项 Flutter 叶子功能，Windows 为 36 项；Apple 专属依赖仅 macOS 提供，平台差异见各自说明。

原 `.command` / `.cmd` 管理入口保留，终端 / CMD 只负责唤起 GUI，随后结束启动脚本；本次独立启动的终端页关闭，已有工作 Shell 不受影响。后续安装 / 卸载、逐项状态及实时可复制日志全部在普通、不置顶的 GUI 内完成。单项内部进度无法可靠获取时显示活动状态。总进度按已处理项 / 本次所选项显示计数和百分比；成功与失败计入已处理，等待中和执行中不计入，100% 表示全部处理完毕，结果以成功 / 失败汇总为准。安装 / 更新和卸载分别计时；点击时只清零并启动当前操作计时，后台全部结束或启动失败时只冻结当前耗时。每秒刷新 `HH:mm:ss`（小时可超过 24），执行时显示“安装用时 / 卸载用时”，结束显示“安装总用时 / 卸载总用时”。两份耗时只在当前面板会话内独立保留。安装成功显示绿色“✅ 安装成功”。运行结束保留结果与完整日志。也可直接打开同名 `.app` / `.vbs`。

两端的“Git操作 → Git 提交回退”仅对有效 Git 工作树内的普通文件夹显示，支持独立仓库、嵌套子 Git、子模块和 linked worktree。点击后在终端选择 upstream soft / hard、历史提交 soft / hard、tag hard 或 reflog hard，共六种模式；hard 必须精确输入 `YES`。功能自包含，不要求安装 SourceTree 脚本仓库。安装与运行细节见 [macOS 回退说明](./MacOS@Extension/JobsGitRollback/README.md)和 [Windows 回退说明](./WindowsOS@Extension/JobsGitRollback/README.md)。


两端桌面空白菜单均提供“Harmony 模拟器检测与修复”，仅操作精确选中的本机实例；单个可执行格式文件同时显示“🔒 运行授权”和“🔓 解除运行授权”，根据当前执行权限互斥置灰；README、文本等普通文档不显示这两项。macOS 清除 POSIX 执行位，Windows 按当前用户的文件执行权限处理，详细确认、回滚与限制见各包说明。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录与运行入口 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- `./MacOS@Extension/`：<u>[**Swift**](https://www.swift.org/)</u> 宿主 App、Finder Sync Extension 与原生 zsh 工具；[【MacOS】🧩管理Finder扩展.command](./MacOS@Extension/【MacOS】🧩管理Finder扩展.command)直接位于该仓根。
- `./WindowsOS@Extension/`：[**PowerShell**](https://learn.microsoft.com/powershell/) 业务、用户级注册表菜单与独立功能包；[【Windows】🧩管理资源管理器扩展.cmd](./WindowsOS@Extension/【Windows】🧩管理资源管理器扩展.cmd)提供组合面板。
- 各 `Jobs*` 功能目录自带一个管理入口与 README，说明安装 / 更新和卸载、显示条件、业务动作、依赖、确认、输出与风险；管理脚本与功能 README 平级，不额外包装同名目录。原本支持整体复制的独立功能包继续可单独使用。

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、使用边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

先按平台总览找到所需功能，再阅读包内说明。安装可能编译 / 注册扩展或修改当前用户菜单，业务动作按各功能独立确认；菜单安装不代表已自动执行 Git、项目构建或模拟器维护。各平台的构建、菜单登记、画面与业务验证范围分别记录在对应功能说明中。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
