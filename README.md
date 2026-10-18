# JobsGenesis 脚本升级优化版

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、升级标准](#jobs-toc-heading-2)
- [二、目录统计](#jobs-toc-heading-3)
- [三、使用方式](#jobs-toc-heading-4)
- [四、未执行声明](#jobs-toc-heading-5)
- [五、静态检查结果](#jobs-toc-heading-6)
- [六、Git 子模块脚本](#submodule-scripts)
  - [【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command](#jobs-toc-heading-8)
  - [【MacOS】🧭更新引用Git父仓=\>子仓.command](#jobs-toc-heading-9)
  - [【MacOS】🧾更新gitmodules.command](#jobs-toc-heading-10)
- [七、目录结构](#repository-layout)

</details>
<!-- jobs-toc:end -->

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

- 子仓代码更新、增量登记和关联修复见[Git 子模块脚本](#submodule-scripts)。
- 父子仓配置先看下面的[实际例子](#submodule-quick-look)，全目录检查结果与例外见 [Git 子模块多平台检查报告](./Git子模块多平台检查报告.md)。
- 本包由原始脚本压缩包整理升级而来。
- 共处理 `.command` 脚本：**135** 个。
- 涉及 Homebrew 的脚本：**56** 个。
- 原始整理阶段没有执行 zsh 检查；父子仓专项修改的 **21 份脚本已通过 `zsh -n`**，范围见检查报告。
- 输出结构保留原大类目录；独立脚本包内保留脚本和 `README.md`，根目录的三个子模块入口直接放置，由本页集中说明。

<strong id="sync-worktree-states">全量同步先看目录状态</strong>

| 本地状态 | 执行结果 | 需要怎样处理 |
| --- | --- | --- |
| 目录为空或缺失，且无既有 Git 缓存 | 首次克隆该子仓，再按所选深度同步。 | 核对清单后开始同步。 |
| 已有有效 Git 工作区，且没有未提交内容 | 复用原目录与缓存，`fetch` 后对齐远端目标分支最新提交。 | 核对本地独有提交；远端对齐仍可能覆盖这些提交。 |
| 当前仓或递归模式下所选子树的已有后代存在未提交、已暂存或未跟踪内容 | 红字加粗显示对应仓库绝对路径，暂停并循环复检。 | 精确输入 `YES` 只放弃该仓自己的内容，或在外部处理后回车复检；其它输入继续等待。 |

全量同步默认保留已有多层子树、旧仓名目录与 Git 缓存。空或缺失目录已有缓存时，先核验并按原索引恢复工作区；非 Git 非空目录、缓存归属不明或缺少索引时保护现场并停止。`YES` 使用 `reset --hard HEAD` 与 `clean -fd`，忽略文件和独立嵌套 Git 仓继续保留；无交互或输入结束时停止。

<strong id="git-source-log">运行时先看这里：子 Git 从哪里拉取</strong>

以父仓线路为 `https://gitee.com/JobsGo/JobsGenesis.git`、下载 `JobsCommand@iOS` 为例，终端会突出显示完整来源；提交号仅展示成功日志的格式：

```text
━━━━━━━━━━ Git 来源｜首次克隆 ━━━━━━━━━━
📦 仓库：JobsCommand@iOS
🌐 平台 / 主机：Gitee（gitee.com）
📥 拉取地址：https://gitee.com/JobsGo/JobsCommand-iOS.git
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️  克隆分支：main
... Git 原生下载进度 ...
✅ JobsCommand@iOS 已浅同步到 origin/main：17b467d（来源：https://gitee.com/JobsGo/JobsCommand-iOS.git）
```

父仓线路、首次克隆和拉取更新各有来源块；递归模式在取得每层 `.gitmodules` 后，先显示下层子仓来源，再逐项下载更新。每层都使用其直接父仓地址解析相对 URL。平台按地址中的主机识别，不按本地目录名判断。

若 `insteadOf` 改写了 URL，来源块同时列出“解析地址”和“拉取地址”；后者由 `git ls-remote --get-url` 在本地展开，未探测 HTTP 重定向或代理最终出口。首次克隆只读取系统、全局及本次进程的规则，不沿用父仓本地 `insteadOf`；已有子仓拉取读取自身配置，递归子仓也分别按未初始化 / 已初始化采用这两种作用域。新来源块在支持颜色的终端重点显示，写入日志时保留纯文本；URL 凭据与查询参数会脱敏。来源日志位于系统临时目录，文件名为 `【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.log`，Git 原生进度仍以终端输出为准。

<strong id="submodule-quick-look">先看例子：子仓地址跟随父仓的平台、账号和协议</strong>

固定平台的写法：

```ini
url = https://github.com/JobsKits/JobsCommand-Flutter.git
```

当前 [.gitmodules](./.gitmodules) 的写法：

```ini
[submodule "JobsCommand@Flutter"]
    path = JobsCommand@Flutter
    url = ../JobsCommand-Flutter.git
    branch = main
```

**从哪个平台克隆父仓，这条相对子仓地址就跟随哪个平台：**

| 父仓克隆地址 | 子仓实际解析地址 |
| --- | --- |
| `https://github.com/JobsKits/JobsGenesis.git` | `https://github.com/JobsKits/JobsCommand-Flutter.git` |
| `https://gitee.com/JobsGo/JobsGenesis.git` | `https://gitee.com/JobsGo/JobsCommand-Flutter.git` |
| `ssh://git@git.example.com:2222/team/JobsGenesis.git` | `ssh://git@git.example.com:2222/team/JobsCommand-Flutter.git` |

前两行对应已配置的 [**GitHub**](https://github.com) / [**Gitee**](https://gitee.com) 仓库地址；第三行为自建服务的结构示例，不代表已部署。[**GitLab**](https://gitlab.com) 等平台同样按父仓地址解析，不需要逐个平台写判断。

**`path` 是本地文件夹，`url` 使用真实远端仓名，两者可以不同：**

```ini
[submodule "SourceTree.command"]
    path = SourceTree.command
    url = ../SourceTree.sh.git
    branch = main
```

Windows 扩展同样保留本地目录与远端仓名的区别，实际登记为：

```ini
[submodule "Windows@Extension"]
    path = Windows@Extension
    url = ../WindowsOS_Extension.git
    branch = main
```

| 当前父仓地址 | Windows 子仓解析地址 |
| --- | --- |
| `ssh://git@github.com/JobsKits/JobsGenesis.git` | `ssh://git@github.com/JobsKits/WindowsOS_Extension.git` |
| `git@gitee.com:JobsGo/JobsGenesis.git` | `git@gitee.com:JobsGo/WindowsOS_Extension.git` |

Windows 子仓自身保留 GitHub `origin`，新增 Gitee HTTPS `gitee`，两端目标均为 `main`；标准下载入口对 Gitee 使用下述 HTTPS 传输规则。独立功能包与安装入口见其 [README](./Windows@Extension/README.md#repository-link)。

| 需要快速确认的事情 | 当前行为 |
| --- | --- |
| 更新清单、下载或修复引用 | 保留已有 URL、分支和扩展字段，不把相对地址覆盖成固定 GitHub 地址。 |
| 同一本地父仓选择下载线路 | 下载脚本通过 `REMOTE_NAME` 选择已配置的父仓 remote；只新增 remote 不会自动切换原生 Git 的默认线路。 |
| 目标平台仓库缺失或仓名不同 | 不创建镜像、不猜地址；保留明确地址或提示补充映射。 |

**前提：目标平台已有对应子仓和父仓所引用的提交。** CodeSnippets 两平台仓名不同，当前仍保留明确的 Gitee 地址；具体处理见[报告中的例外说明](./Git子模块多平台检查报告.md#exceptions)。上表说明地址解析，不能替代远端实际克隆验证。

**下载脚本的 Gitee 传输规则：** `【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command` 在本次运行中，将 `git@gitee.com:`、`ssh://git@gitee.com/`、`ssh://git@gitee.com:22/` 开头的标准地址统一通过 `https://gitee.com/` 访问，保留账号、真实仓名和分支；即使设置 `GIT_URL_STYLE=ssh`，这类 Gitee 地址仍使用 HTTPS。各层首次克隆和后续拉取都继承该规则，历史子模块中的 SSH 地址无需新电脑先配置 SSH 密钥。

规则通过追加进程级 `GIT_CONFIG_COUNT` / `url.https://gitee.com/.insteadOf` 配置传给子进程，不写入全局 Git 配置，也不依赖其它工程路径。GitHub、其它主机及非 `22` 的自定义 SSH 端口保持原规则。克隆或递归更新失败会返回非零状态，停止本轮同步并保留错误；不会再输出该项同步成功。各仓清单与浅克隆参数保留；全量同步默认逐仓复用已有工作区，空或缺失目录才首次克隆，不批量删除旧仓名目录、多层子树或缓存。未提交内容须逐仓处理，精确 `YES` 仅放弃当前仓自己的内容。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、升级标准 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 所有脚本统一为 `# shell: zsh`。
- 双击运行先显示脚本内置自述，并等待回车继续；`README.md` 供运行前阅读。
- 统一彩色日志函数；下载子模块入口的来源日志写入系统临时目录，文件名为 `【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.log`，其它入口以各自 `LOG_FILE` 为准。
- 统一 `SCRIPT_DIR` / `SCRIPT_PATH` 路径写法。
- 统一结构化入口：`main "$@"`。
- 普通安装 / 更新 / 升级步骤统一为：**回车跳过，输入任意字符后回车执行**。
- 危险操作必须明确确认，不做回车默认执行。
- Homebrew 按健康标准处理：架构识别、shellenv 注入、当前会话生效、可选健康更新。

## <span id="jobs-toc-heading-3" data-jobs-toc="v2">二、目录统计 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 原始大类 | 脚本数量 |
|---|---:|
| `JobsGenesis@JobsCommand.Flutter` | 57 |
| `JobsGenesis@JobsCommand.Gits` | 15 |
| `JobsGenesis@JobsCommand.SourceTree` | 20 |
| `JobsGenesis@JobsCommand.iOS` | 43 |


## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、使用方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

进入任意脚本同名文件夹后，双击 `.command` 文件即可。终端方式：

```shell
chmod +x './脚本名.command'
'./脚本名.command'
```

每个脚本文件夹内的 `README.md` 都已经按统一格式生成，可以先看用途、风险和流程图。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

生成过程中只做文件重组、代码结构升级和 `zsh -n` 静态检查；没有实际执行 `brew`、`pod`、`flutter`、`xcodebuild`、`osascript`、`sudo`、模拟器、Git 远程写入等 macOS 专属或有副作用的命令。

## <span id="jobs-toc-heading-6" data-jobs-toc="v2">五、静态检查结果 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

原始脚本整理阶段没有执行 `zsh -n`。父子仓多平台专项修改涉及的 21 份脚本已完成语法检查，地址解析与脚本隔离回归结果见 [Git 子模块多平台检查报告](./Git子模块多平台检查报告.md#validation)；其它脚本保留原验证范围。

详见：`升级报告.json`。

[**Homebrew**](https://brew.sh/) 安装路径由用户选择：已有可运行安装时复用；确实需要安装时先强提示，只有精确输入大写 `YES` 才选择系统标准目录，其它输入或直接回车选择当前用户的 `.local/homebrew`。`YES` 只表示选择路径，权限与密码由官方安装器实际处理；有管理员权限也可以选用户目录。选定路径失败立即停止，不自动切换；`Ctrl+C` / 输入结束取消整个任务。

Homebrew 的发现、健康检查、安装路径选择与复检均封装在每个相关脚本自己的函数中。

Python 入口在各自文件内封装完整的 Homebrew → Python → 虚拟环境自检流程；独立复制脚本不需要额外的环境支持文件或同步工具。

## 六、<span id="submodule-scripts">Git 子模块脚本</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">[【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command](./【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command)</span><!-- jobs-toc:heading-end -->

> **目的：** 将选中的子仓及可选的后代子模块更新到各自远端目标分支最新版本，并维护入口父仓关联。

* 确认自述后读取脚本清单、检查远端，尝试拉取父仓。
* 父仓有未提交改动：跳过父仓拉取，继续处理子仓。
* 在主菜单选择同步范围；“切换同步深度”可在默认“向下递归”和“仅直属子模块”之间切换，当前深度适用于各同步动作。
  * 全量同步：逐项同步清单内全部目标，按目录状态复用或首次克隆。
  * 只更新已有：更新清单内已存在的子仓；一个都没有时转全量同步。
  * 指定子模块：回车勾选或取消，空格确认开始。
  * 添加地址：输入新仓地址，自动用仓名作为目录，本轮登记并同步。
* 补齐关联配置，检查并处理目标子仓目录。
  * 目录为空或缺失：首次克隆；已有有效 Git 工作区：保留目录、缓存及后代，直接更新。
  * 已有 `modules/` 缓存时先核验并恢复空工作区；非 Git 非空目录保护并停止。
  * 子仓有未提交、已暂存或未跟踪内容：红字加粗显示该仓绝对路径并循环等待；精确输入 `YES` 只放弃当前仓自己的未提交内容，或在外部处理后回车复检。其它输入继续复检；无交互或输入结束则停止。
* 拉取并强制对齐远端目标分支最新提交：优先使用该层 `.gitmodules` 显式 `branch`，`.` 继承直接父仓分支；未设置时优先 `main`，不存在则使用远端默认分支。
  * 使用 `checkout -B` 和 `reset --hard`：目标本地分支未推送的独有提交可能被覆盖。
* 按当前深度同步：默认逐层读取所选子仓下的 `.gitmodules`，将已登记后代同步到各自远端目标分支最新提交；仅直属模式不下载或更新下层代码。
  * 只处理本层所选子树，不向上扫描，也不接管未登记的嵌套仓库。
  * 递归更新本层前先检查当前已有后代；各仓单独确认，子模块 HEAD 与父仓 gitlink 的普通差异不作为源码未提交反复提示。
  * `YES` 清理仅作用于当前仓：`reset --hard HEAD` 与 `clean -fd`；保留忽略文件和独立嵌套 Git 仓，残留冲突须外部处理后复检。
  * `PRUNE_STALE_GITMODULES` 默认 `0`，保留清单外旧登记；主动设为 `1` 时，每个旧登记另用红字加粗列明目录和后代删除范围，逐项精确输入 `YES` 才删除，其它输入、输入结束或非交互则停止；演练只展示，删除前仍逐仓检查已有后代。
  * 深层只下载更新，不自动暂存或提交其父仓的 gitlink；递归后这些父仓可能显示子模块指针改动，保留待审阅。
* 整理入口父仓 Git 元数据与来源日志。
* 默认自动提交入口父仓的关联变化，不自动推送。
  * 设置 `AUTO_PARENT_COMMIT=0`：跳过提交；`AUTO_PARENT_PUSH=1`：启用父仓推送。

### <span id="jobs-toc-heading-9" data-jobs-toc="v2">[【MacOS】🧭更新引用Git父仓=>子仓.command](./【MacOS】🧭更新引用Git父仓=%3E子仓.command)</span><!-- jobs-toc:heading-end -->

> **目的：** 修复目录改名、旧路径残留或元数据指向错误，让父仓关联符合当前磁盘布局。

* 扫描父仓第一层实际带 `.git` 的子目录，读取远端和已有登记。
  * 远端缺失、元数据归属不明或属于链接工作树：停止修复。
* 展示磁盘目录、父仓状态与清理计划，确认后备份关联状态。
  * 直接回车：跳过；输入任意字符后回车：执行；`--dry-run`：只预览。
* 按现存目录对齐 `.gitmodules`，保留仍存在条目的 URL、分支及扩展字段。
  * 目录缺失，包括尚未下载：移除旧登记和旧子模块指针，磁盘文件保留。
* 修复可证明失效的工作树指向，暂存各子仓当前提交号，用官方命令归集元数据并补齐父仓本地登记。
* 核对磁盘目录、清单和父仓子模块指针是否一致，输出状态；不拉取代码、不提交、不推送。

### <span id="jobs-toc-heading-10" data-jobs-toc="v2">[【MacOS】🧾更新gitmodules.command](./【MacOS】🧾更新gitmodules.command)</span><!-- jobs-toc:heading-end -->

> **目的：** 将新放入的直属子仓完整纳入父仓子模块管理，保留已有登记与指针。

* 读取已有登记，扫描直属子仓，预检远端、提交、索引和元数据冲突。
  * 有冲突或缺少必要信息：停止，展示问题。
* 生成增量计划，保留已有 URL、分支、扩展字段、子模块指针和暂缺目录登记。
  * `--dry-run` 或 `DRY_RUN=1`：只预览，不执行关联写入。
* 确认计划后备份关联配置和父仓索引。
  * 直接回车：跳过；输入任意字符后回车：执行。
* 补齐 `.gitmodules` 和缺失的子模块指针，初始化本地登记，将元数据归集到父仓。
* 核验父子关系和子仓提交号；仅暂存必要关联，不联网拉取、不提交、不推送。

## 七、<span id="repository-layout">目录结构</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

本仓根目录维护三个[子模块入口](#submodule-scripts)；各分类目录是独立 Git 子仓，脚本用途和执行流程在各自 README 中说明。

| 路径 | 职责 |
| --- | --- |
| [JobsCommand@Flutter/](./JobsCommand@Flutter/README.md) | Flutter 环境、工程、构建与常用工具脚本。 |
| [JobsCommand@Gits/](./JobsCommand@Gits/README.md) | Git 下载、关联、历史、迁移等操作脚本。 |
| [JobsCommand@Others/](./JobsCommand@Others/README.md) | 通用文件处理与终端工具脚本。 |
| [JobsCommand@iOS/](./JobsCommand@iOS/README.md) | iOS 开发环境、工程维护、安装与构建脚本。 |
| [JobsConfigOS/](./JobsConfigOS/README.md) | 系统、编辑器、代码片段及 Codex 等配置子仓。 |
| [JobsPythonTools.py/](./JobsPythonTools.py/README.md) | Python 工具子仓及跨平台运行、打包入口。 |
| [JobsSh.sh/](./JobsSh.sh/README.md) | Shell 工具与环境安装脚本。 |
| [MacOS@Extension/](./MacOS@Extension/README.md) | Finder 扩展工程及打包、安装入口。 |
| [SourceTree.command/](./SourceTree.command/README.md) | Sourcetree 自定义动作、维护脚本及菜单资源。 |
| [Windows@Extension/](./Windows@Extension/README.md) | Windows 资源管理器右键扩展；十个独立功能包及组合安装入口，远端仓名为 `WindowsOS_Extension`。 |
| [.gitmodules](./.gitmodules) | 子仓路径、克隆地址和跟踪分支登记。 |
| `【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command` 等三个根脚本 | 本仓直接管理的下载更新、关联修复和增量登记入口，完整说明见[第六章](#submodule-scripts)。 |
| [Git子模块多平台检查报告.md](./Git子模块多平台检查报告.md) | 多平台配置、例外与静态验证记录。 |

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
