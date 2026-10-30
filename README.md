# JobsGenesis 脚本与开发工具

![Jobs出品，必属精品](https://picsum.photos/1500/400)

<!-- jobs-toc:start -->
<!-- jobs-toc:source {"v":2,"token":"[toc]"} -->
<details>
<summary>📚 目录（点击展开 / 收起）</summary>

- [🔥 前言](#jobs-toc-heading-1)
- [一、运行与交互约定](#jobs-toc-heading-2)
- [二、功能分类与入口导航](#feature-navigation)
- [三、使用方式](#jobs-toc-heading-4)
- [四、执行范围与结果](#jobs-toc-heading-5)
- [五、环境准备与排查](#jobs-toc-heading-6)
- [六、Git 子模块脚本](#submodule-scripts)
  - [【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command](#jobs-toc-heading-8)
  - [【MacOS】🧭更新引用Git父仓=\>子仓.command](#jobs-toc-heading-9)
  - [【MacOS】🧾更新gitmodules.command](#jobs-toc-heading-10)
- [七、目录结构](#repository-layout)
- [八、拷贝前清理缓存与构建产物](#cache-cleanup)
- [九、跨平台脚本审计](#script-audit)

</details>
<!-- jobs-toc:end -->

## <span id="jobs-toc-heading-1" data-jobs-toc="v2">🔥 <font id=前言>前言</font></span><!-- jobs-toc:heading-end -->

**最低支持系统：** [**Windows**](https://www.microsoft.com/windows) **10 64 位（x64）**。这是当前最低支持目标；具体最低 build 尚未锁定，完整实机兼容性仍待验证。

JobsGenesis 是 Jobs 自维护的开发与系统工具集合，覆盖 Git 子模块管理、Flutter / iOS 工程、系统配置、文件与媒体处理、Python 桌面工具和桌面右键扩展。先按下表选择功能，再阅读对应目录的 README 和脚本运行时自述。

**平台与版本边界：** `WindowsOS/`、[**Windows**](https://www.microsoft.com/windows) 打包入口和 `.exe` 仅表示平台，不代表 XP 至 Windows 11 全版本兼容。[右键扩展](./OS@Extension/WindowsOS@Extension/README.md#windows-compatibility)以 Windows 10 / 11 为目标，要求 [**Windows PowerShell**](https://learn.microsoft.com/powershell/) 5.1 Desktop；[Python 桌面工具](./JobsPythonTools.py/README.md#windows-compatibility)多数采用 [**Qt 6**](https://doc.qt.io/qt-6/)，以 Windows 10 / 11 x64 为目标。旧系统、32 位和 ARM64 的限制分别见对应说明；目标系统及依赖要求不等于已经通过实机验收。

| 根目录功能 | 具体可以做什么 | 输入与结果 |
| --- | --- | --- |
| [下载与同步子模块](#submodule-scripts) | 默认向下递归拉取分支最新提交；维护模式可全量、仅已有、多选或新增仓库，并选择递归深度 | 读取父仓远端、`.gitmodules` 或维护清单；更新工作区与本地跟踪分支，维护模式可记录父仓指针 |
| [对齐父子仓引用](#submodule-scripts) | 以磁盘现有直属子仓为准，对齐目录、登记、gitlink 和 Git 元数据指向 | 先预览再确认；暂存关联变化，保留备份，不拉取、不提交、不推送 |
| [增量登记子仓](#submodule-scripts) | 将新放入的直属 Git 仓补登记为子模块，保留已有 URL、branch、扩展字段与指针 | 读取直属子仓真实远端和提交；补齐 `.gitmodules`、gitlink 与本地登记 |
| [缓存与构建产物清理](#cache-cleanup) | 递归识别缓存 / 构建特征，显示逐项占用；支持仅预览、仅缓存及无人值守 | 从脚本目录向下扫描；确认后删除匹配项，保护 Git 元数据、符号链接和挂载点 |
| [跨平台脚本审计](#script-audit) | 对 Shell、Python、JavaScript、PowerShell 做语法检查，标明无法验证的文件 | 默认只输出终端结果；可指定扫描目录、并发数、严格模式及 JSON 报告 |

各工具分类的功能范围与入口见[功能导航](#feature-navigation)，真实目录关系见[目录结构](#repository-layout)。本仓直接维护的脚本由本页说明，子仓独立功能在其就近 README 展开参数、交互、产物和限制。

<strong id="markdown-toc-sync">同步后文档目录：本地 `[toc]`，提交后发布折叠目录</strong>

本地编辑保留独占行 `[toc]`；整文件暂存时由 [**Git**](https://git-scm.com/) 过滤器生成按标题层级缩进、默认收起的可折叠目录，正常提交推送后供远端展示。下载入口先完成拉代码和向下递归，成功后才独立询问是否初始化全局 `filter.jobs-markdown-toc`；各仓继续维护自己的文档清单与精确属性。

全局配置功能位于 `JobsConfigOS/🌍JobsMacEnvVarConfigs`，可单独运行[配置入口](./JobsConfigOS/🌍JobsMacEnvVarConfigs/scripts/【MacOS】⚙️配置全局Markdown目录过滤器.command/【MacOS】⚙️配置全局Markdown目录过滤器.command)。使用[下载入口](./【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command)时，附加提示要求**回车才安装，输入任意字符后回车就跳过**；跳过或附加配置失败都不改变代码拉取结果。仅选择安装时需要 Node.js 20+，安装成功后子模块共用全局驱动。完整命令、状态及卸载见[独立功能说明](./JobsConfigOS/🌍JobsMacEnvVarConfigs/scripts/【MacOS】⚙️配置全局Markdown目录过滤器.command/README.md)。

| 本仓配置与工具 | 同步入口处理 | 结果与依赖 |
| --- | --- | --- |
| 已有有效目录过滤器 | 执行本仓 `.jobs-markdown-toc/MarkdownToc.mjs restore`，再执行 `verify`；已有工作树即使没有新提交，也显式恢复当前正文 | 需要可用的 [**Node.js**](https://nodejs.org) 和完整目录工具；保留正文及原暂存语义 |
| 新电脑未配置目录过滤器 | 先正常拉取与递归；成功后单独询问，回车才安装，任意字符后回车跳过 | Node.js 20+ 只用于可选配置；安装失败不改变拉取成功结果 |
| 仓库未携带目录工具 | 跳过已有文件恢复，不新增清单或属性 | 全局驱动只转换已由属性登记的文件 |
| 已有有效过滤器，但缺少 Node.js / 工具，或还原、验证失败 | 报出具体仓库并停止本轮同步 | 处理该仓配置或工具后重试，不能将本轮视为全部成功 |

默认只拉取的首次克隆先以 `--no-checkout` 复制已预检对象，记录真实远端地址后才首次安全检出；不会为此再次联网获取未经预检的提交。已有生成目录的恢复以当前磁盘正文为来源，不从旧 `HEAD` 或暂存区覆盖正文，也不自动暂存、提交或推送。普通 `git clone` / `git pull` 不会执行安装脚本或给新电脑写配置；新电脑至少通过独立入口或下载后的可选提示完成一次安装，后续克隆 / 检出才会自动得到 `[toc]`。无更新的拉取不会重写旧文件；需要恢复时向独立入口显式传入目标仓库。

<strong id="readonly-submodule-mode">先选用途：只拉取电脑默认跟随分支最新，子仓保持本地分支</strong>

用途、维护菜单、子仓多选和同步深度统一使用 [**fzf**](https://formulae.brew.sh/formula/fzf)。两种模式启动前都需已有可用 fzf，缺失或损坏时安全停止并提示修复，不自动退回数字菜单。维护菜单按 `←` 返回用途页，子仓与深度页按 `←` 返回维护菜单；返回后保留当前深度并恢复菜单位置。子仓多选用回车勾选 / 取消、空格确认、`Ctrl+A` 全选、`Ctrl+D` 清空；空选不启动同步，`Esc` / `Ctrl+C` 取消本轮。返回只改变后续选择，已经完成的父仓更新不会撤销。

| 启动选择 | 版本依据 | 是否写入父仓提交 |
| --- | --- | --- |
| 只拉取，默认 | 更新当前父仓明确的远程上游，再逐层跟随子仓目标分支最新提交，保持本地跟踪分支 | 不暂存、不提交、不推送 |
| 维护子模块，显式选择 | 按本仓清单及原有菜单，把所选子树更新到各自远端目标分支最新 | 沿用 `AUTO_PARENT_COMMIT` / `AUTO_PARENT_PUSH` 原有开关 |

可选目录配置工具随环境配置子仓下载，缺失时只跳过附加配置；另一台电脑上的未提交或未推送修改不会自动更新到新电脑。任一仓库拉取、分支切换或递归校验失败时，本轮不能视为全部完成；处理日志中的具体路径后重新运行。

只拉取模式从脚本所在仓库向下递归处理全部已登记子模块；不向上处理，不使用清单新增关联，也不把子仓最新提交自动提交回父仓。各层优先使用直接父仓 `.gitmodules` 的显式 `branch`，`.` 继承该层计划更新后的直接父仓分支；未配置时读取该子仓远端默认分支。首次下载和已有游离 HEAD 都会恢复或创建对应本地跟踪分支，获取最新提交并快进；成功结束时子仓显示实际分支名。每层相对 URL 随当前父仓的下载线路解析。只拉取模式使用系统 Git、zsh、Perl 等现有工具，不把全局过滤器安装或 Node.js 作为新电脑拉代码的前置条件。已安装并启用的过滤器仍按 Git 配置执行；外层用途选择仍需 fzf；只拉取不需要 Homebrew。

子仓源码、未跟踪内容、已暂存 gitlink、未完成操作或本地独有提交会报出具体路径并停止；不会强制覆盖或丢弃独有的游离提交，父仓 `YES` 不扩散到子仓。当前父仓自己的源码改动或本地独有提交，仍须红字列明并精确输入 `YES` 才舍弃。目标分支不存在、远端默认分支无法确定或最新提交获取失败时，停止并报告对应仓库与来源；不会把旧 gitlink SHA 当作最新分支结果。

只拉取模式在入口仓已有本地分支时仍要求明确上游。入口仓自身处于游离 HEAD 时，先使用直接父仓 `.gitmodules` 的显式 `branch`，`.` 继承直接父仓当前分支；无配置时读取 `origin` 或唯一远端的默认分支。已有目标本地分支须明确跟踪所选远端的同名分支；先获取最新提交，预检整棵子树与提交历史，并复查确认期间的状态，再恢复或创建本地跟踪分支。入口源码未提交、需继承分支时直接父仓同样游离、目标不明、目标分支无法快进或存在未受引用保护的独有游离提交时停止；普通父仓的 `YES` 不授权舍弃这些提交。

`REMOTE_NAME` 等原有清单参数只用于维护模式。设置 `DRY_RUN=1` 时，默认只拉取会停止并提示选择维护演练，不能忽略演练标志后执行真实更新。未初始化但存在旧 Git 缓存的空工作树须先恢复，脚本不会覆盖缓存内索引或独有提交。

下文关于清单新增、多选、可切换同步深度、目录清理及自动提交的既有流程，均指显式选择的**维护模式**。只拉取模式默认向下递归到分支最新，不使用这些写入父仓的开关；子仓最新提交与父仓 gitlink 可能不同，父仓会显示待审阅的子模块指针改动。两种模式都保留各仓独立清单和来源显示；两种模式均使用本次私有随机日志，终端会输出实际路径。

<strong id="download-resume-cache">网络不稳定时：保留下载缓存，安全发布工作树</strong>

只拉取与维护模式都会复用已有工作树。首次下载先把目标分支获取到持久裸对象库，再在实际 Git 元数据目录内的本次临时目录以 `--no-checkout` 复制对象、设置真实远端、检出并核验固定提交；全部成功后才移入经过复检的空目标目录。获取或检出失败时只清理本次临时目录，保留持久缓存供重跑使用，不把半成品工作树留在目标位置，不覆盖已有非空目录。已有条件过滤器仍在真实远端配置完成后的首次检出参与转换，不额外联网获取未经预检的提交。

缓存位于实际 Git 目录内的 `jobs-download-cache/v1/<路径与来源哈希>.git`：只拉取统一使用入口仓的 Git 目录，维护模式逐层使用当前父仓的 Git 目录。路径、配置来源与实际展开来源共同区分缓存；成功、失败和正常中断后均保留，不自动清空，所占磁盘空间会持续保留。中断只留下本工具的空缓存目录时可以重新初始化；不明或非空冲突目录保留并停止，不借恢复删除用户内容。

需要同步时正常获取最新分支，已完整下载的对象参与增量协商；后续某仓失败不会清除前面已下载成功的准备对象。**这不是半截 pack 按字节续传**：当前尚未完整接收的 pack 仍可能重新传输。只拉取的首次下载使用 `--depth=1`；维护模式沿用 `SUBMODULE_SHALLOW_CLONE`、`SUBMODULE_DEPTH` 和 `SUBMODULE_FETCH_TAGS`。已有完整仓不改成浅仓，已有工作树更新不重新设置浅克隆深度；浅克隆主要减少历史，当前工作文件中的大包仍须下载。

<strong id="download-complete-marker">每仓完成标记：先查询远端，版本匹配才跳过</strong>

每次运行先用 `ls-remote` 查询目标分支的远端最新提交，再核对该仓实际 Git 目录中的 `jobs-download-complete`。标记记录来源签名（包含配置来源与实际展开 URL 的哈希）、目标分支和已完成提交；本地 `HEAD`、当前分支、远端提交和标记全部匹配，并通过源码风险检查，默认才跳过**当前仓库**的下载与检出。来源哈希避免把带凭据的原始地址写进完成标记。

| 检查结果 | 当前仓库的处理 |
| --- | --- |
| 标记匹配远端最新提交，本地分支 / `HEAD` 和源码状态也符合，且使用默认不取 tags 策略 | 跳过当前仓下载与检出，仍核对或补齐子模块登记、`active` 和 `absorbgitdirs` 元数据归集，再独立检查所选范围内的后代。 |
| 标记不存在、来源 / 分支 / 提交改变，或本地状态与标记不一致 | 进入正常同步及既有风险检查，成功核验后才写入或更新标记。 |
| 已经是最新代码，但此前没有完成标记 | 正常同步一次，核验成功后建立标记，后续运行才可按标记跳过。 |
| 查询远端、下载、检出或核验失败 | 不写本轮成功标记；保留失败状态和下载缓存，处理具体原因后重跑。 |

父仓标记只表示该仓完成，**不表示整棵子树完成**；每个后代仍独立查询与核对。标记不会放宽源码、暂存内容、分叉或独有提交的保护，也不会跳过必要的本地登记修复；发现风险仍按原有门禁停止或确认。维护模式中 `SUBMODULE_FETCH_TAGS=0` 为默认省流量策略；显式设为 `1` 时，每次仍同步 tags，目标分支 `HEAD` 没变也不能被完成标记跳过。完成标记和下载缓存都在 Git 元数据目录内，不生成源码文件或自动提交。

需要强制重新同步某个仓库时，先停止该下载任务，在该仓执行下面的只读命令定位标记，然后只移除这个 `jobs-download-complete` 文件；保留 `modules/`、索引、对象缓存和其它 Git 元数据。移除某个仓的标记只影响该仓，后代仍按各自标记检查：

```shell
git rev-parse --git-path jobs-download-complete
```

| 环境变量 | 默认值 | 允许范围 | 作用 |
| --- | --- | --- | --- |
| `JOBS_DOWNLOAD_TIMEOUT` | `900` | `1–86400` | 单次 Git 网络命令总时限，单位秒；超时终止该命令及其子进程。 |
| `JOBS_DOWNLOAD_ATTEMPTS` | `3` | `1–10` | `clone` / `fetch` / 远端查询遇网络错误时的最多尝试次数，包含首次。 |
| `JOBS_DOWNLOAD_RETRY_DELAY` | `2` | `0–60` | 重试等待基数，默认两次分别等待 2、4 秒；`0` 表示不等待。 |
| `JOBS_DOWNLOAD_LOW_SPEED_LIMIT` | `1024` | `1–1000000000` | HTTP / HTTPS 低速阈值，单位字节 / 秒。 |
| `JOBS_DOWNLOAD_LOW_SPEED_TIME` | `60` | `1–3600` | 持续低于阈值达到此秒数后终止该次传输。 |

参数须为对应范围内的十进制整数，空值、表达式和越界值会停止执行。认证、权限、分支不存在和本地仓库错误保留失败状态，按日志处理后重跑；`pull` 不自动重复合并 / rebase，`push` 不使用下载重试包装。参数只影响本次脚本及其 Git 子进程，不修改全局 HTTP 或代理配置。同一入口通过共用锁阻止并行运行；异常强制结束留下锁时，须先确认旧进程已经退出再处理日志指明的锁目录。

维护模式在父仓工作区可拉取时，只精确 `fetch` 当前目标分支一次，固定本次远端跟踪目标，再在本地 `rebase` 到该目标；不会为了同一次父仓更新再发起 `pull` 的第二次网络获取。远端获取失败或 rebase 冲突会停止本轮，不继续处理子仓。父仓存在未提交内容时继续按原有策略跳过父仓拉取，具体风险与后续所选子仓分别检查。

脚本是可单独复制的完整入口：共享函数在本文件内只维护一份，只拉取流程按明确白名单导出所需函数到独立 zsh 子进程，不依赖外置支持库。两种模式的外层用途选择均要求已有健康的 fzf；只拉取不需要 Homebrew，维护模式仅在 fzf 修复确需且确认后使用 Homebrew，不为拉代码批量升级全部已安装软件。

两种模式的日志都在系统临时目录中使用本次唯一的随机文件名，权限为 `600`；以终端打印的“本次日志”或“日志”完整路径为准，不根据固定名称猜测。来源和诊断按既有规则脱敏。缓存、临时检出目录与完成标记放在 Git 元数据目录内，不进入源码或提交。

在本 README 所在目录运行，下面把单次时限放宽到 30 分钟，其余参数使用默认值；普通使用仍可直接双击脚本。网络慢但持续有数据时可适当提高总时限，避免完整大包尚未传完就达到时限：

```shell
JOBS_DOWNLOAD_TIMEOUT=1800 \
  /bin/zsh './【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command'
```

终端来源块后会显示 `下载缓存（重跑复用已完成对象）` 及其实际路径。这里的下载对象缓存与 `modules/` 中已有子模块的索引、配置和历史不同；后者仍按原有归属及索引保护规则处理，不能为重试删除它们。

<strong id="download-audit-result">蓝本审计与回归验收（2026.10.27-audited）</strong>

当前蓝本已部署到本机 `Github` 目录范围内全部 **7 份**同名自维护下载入口。根入口由 `4158` 行收口为 `3850` 行；7 份各自的 `SUBMODULE_REPO_URLS` 配置逐字保留，`JobsCommand@Gits/MacOS` 包的实际 Git 根定位例外与仅根入口提供的可选全局目录配置均保留。此处记录当前审计结论与验收边界，具体使用方式见上方下载说明。

| 确认问题 | 当前处理 | 测试证据 |
| --- | --- | --- |
| 维护真实入口在成功或失败后遗留锁 | 锁由正确的 owner / 子 Shell 层级持有，通过 `EXIT` / `ZERR` 完成退出清理，竞争任务不释放别人的锁。 | [入口锁回归](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_transport_audit.py>) |
| `ls-remote` 失败后的残缺标准输出拼入重试结果 | 按每次 attempt 隔离查询输出，只发布成功尝试的完整结果，并拒绝歧义分支或无效提交号。 | [查询与重试回归](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_transport_audit.py>) |
| 完成标记命中后漏掉登记与元数据归集 | 仅跳过下载 / 检出，仍收尾来源 URL、`active` 和 `absorbgitdirs`；后代独立检查。 | [中断与状态保护](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_audit.py>) |
| 首次 checkout 中断后无法安全重跑 | 在 Git 元数据内的 stage 完成检出与核验，再原子发布到空目标；失败清本次 stage，保留持久 cache。 | [中断与状态保护](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_audit.py>) |
| 空 cache 目录不能复用 | 仅安全初始化本工具的空目录；非空异常缓存保留，停止并交由人工检查。 | [中断与状态保护](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_audit.py>) |
| `tags=1` 且分支 HEAD 未变时漏取标签 | 显式取 tags 时每次执行标签获取，HEAD 完成标记不跳过标签同步；默认 `tags=0` 继续省流量。 | [中断与状态保护](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_audit.py>) |
| 精确 `YES` 可能误毁 ignored 文件、嵌套源码或 bare 仓库 | 先检查忽略路径碰撞、嵌套工作树和裸仓边界；有效非裸嵌套仓继续保留原生 `clean` 保护。 | [中断与状态保护](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_audit.py>)、[逐仓确认保护](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_dirty_confirmation.py>) |
| 父仓 fetch 吞错、重复联网或冲突后继续子仓 | 一次精确获取目标分支，固定目标引用后本地 rebase；网络失败与冲突均停止后续业务。 | [蓝本边界回归](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_downloader_blueprint.py>) |
| 共享实现重复、拉代码触发无关 Brew 升级 | 单文件内只维护一份共享函数，白名单导出独立只拉取引擎；仅准备当前需要修复的依赖，健康 Brew 原地复用。 | [蓝本边界回归](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_downloader_blueprint.py>) |

测试目录现有 **104 个测试方法**，由 AST 静态统计：原有 81 个，状态审计 9 个、传输审计 8 个、蓝本回归 6 个。静态方法总数不等于本轮执行次数。本轮通过的范围包括：根入口的代表回归与新增功能；[来源日志](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_source_logging.py>) 和 [Gitee 协议](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_gitee_https_transport.py>) 共 18 个方法对 7 份入口的验证；7 份公共结构、缓存 / 完成标记 helper 和渲染引擎 zsh 语法检查；[认证与 Ctrl+C](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/test_download_transport_tty.py>) 两项真实隔离 PTY 验证。未运行 `104 × 7` 完整矩阵，未将隔离回归当作真实大型远端完整传输验收；可复制测试命令与依赖见 [tests 说明](<./JobsCommand@Gits/MacOS/【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command/tests/README.md>)。

维护模式补齐或新增登记时，不自动写入 `branch = main`；已有 `branch` 与缺省状态均保留。显式 `branch` 严格指定目标分支，`.` 继承直接父仓分支；未配置时跟随子仓远端默认分支。目标不存在、直接父仓分支无法确定或远端默认分支无法确定时停止。

<strong id="sync-worktree-states">维护模式全量同步先看目录状态</strong>

| 本地状态 | 执行结果 | 需要怎样处理 |
| --- | --- | --- |
| 目录为空或缺失，且无既有 Git 缓存 | 首次克隆该子仓，再按所选深度同步。 | 核对清单后开始同步。 |
| 已有有效 Git 工作区，且没有未提交内容 | 复用原目录与缓存；默认不取 tags 时，远端最新提交、完成标记与本地状态匹配可跳过当前仓，否则 `fetch` 后快进目标本地分支。 | 本地领先远端或分叉时停止并保留提交，外部整合后重试。 |
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
ℹ️  下载缓存（重跑复用已完成对象）：<父仓实际 Git 目录>/jobs-download-cache/v1/<路径与来源哈希>.git
... Git 原生下载进度 ...
✅ JobsCommand@iOS 已浅同步到 origin/main：17b467d（来源：https://gitee.com/JobsGo/JobsCommand-iOS.git）
```

父仓线路、首次克隆和拉取更新各有来源块；递归模式在取得每层 `.gitmodules` 后，先显示下层子仓来源，再逐项下载更新。每层都使用其直接父仓地址解析相对 URL。平台按地址中的主机识别，不按本地目录名判断。

若 `insteadOf` 改写了 URL，来源块同时列出“解析地址”和“拉取地址”；后者由 `git ls-remote --get-url` 在本地展开，未探测 HTTP 重定向或代理最终出口。首次克隆只读取系统、全局及本次进程的规则，不沿用父仓本地 `insteadOf`；已有子仓拉取读取自身配置，递归子仓也分别按未初始化 / 已初始化采用这两种作用域。新来源块在支持颜色的终端重点显示，写入日志时保留纯文本；URL 凭据与查询参数会脱敏。来源日志位于系统临时目录，文件名带随机后缀，权限为 600；以终端显示的“本次日志”路径为准，Git 原生进度仍以终端输出为准。

<strong id="submodule-quick-look">先看例子：子仓地址跟随父仓的平台、账号和协议</strong>

固定平台地址的解析示例：

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
[submodule "WindowsOS@Extension"]
    path = OS@Extension/WindowsOS@Extension
    url = ../WindowsOS_Extension.git
    branch = main
```

| 当前父仓地址 | Windows 子仓解析地址 |
| --- | --- |
| `ssh://git@github.com/JobsKits/JobsGenesis.git` | `ssh://git@github.com/JobsKits/WindowsOS_Extension.git` |
| `git@gitee.com:JobsGo/JobsGenesis.git` | `git@gitee.com:JobsGo/WindowsOS_Extension.git` |

Windows 子仓自身保留 GitHub `origin`，新增 Gitee HTTPS `gitee`，两端目标均为 `main`；标准下载入口对 Gitee 使用下述 HTTPS 传输规则。独立功能包与安装入口见其 [README](./OS@Extension/WindowsOS@Extension/README.md#repository-link)。

| 需要快速确认的事情 | 当前行为 |
| --- | --- |
| 更新清单、下载或修复引用 | 保留已有 URL、分支和扩展字段，不把相对地址覆盖成固定 GitHub 地址。 |
| 同一本地父仓选择下载线路 | 下载脚本通过 `REMOTE_NAME` 选择已配置的父仓 remote；只新增 remote 不会自动切换原生 Git 的默认线路。 |
| 目标平台仓库缺失或仓名不同 | 不创建镜像、不猜地址；保留明确地址或提示补充映射。 |

**前提：目标平台已有对应子仓和父仓所引用的提交。** CodeSnippets 两平台仓名不同，当前仍保留明确的 Gitee 地址；具体处理见[报告中的例外说明](./Git子模块多平台检查报告.md#exceptions)。上表说明地址解析，不能替代远端实际克隆验证。

**下载脚本的 Gitee 传输规则：** `【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command` 在本次运行中，将 `git@gitee.com:`、`ssh://git@gitee.com/`、`ssh://git@gitee.com:22/` 开头的标准地址统一通过 `https://gitee.com/` 访问，保留账号、真实仓名和分支；即使设置 `GIT_URL_STYLE=ssh`，这类 Gitee 地址仍使用 HTTPS。各层首次克隆和后续拉取都继承该规则，历史子模块中的 SSH 地址无需新电脑先配置 SSH 密钥。

规则通过追加进程级 `GIT_CONFIG_COUNT` / `url.https://gitee.com/.insteadOf` 配置传给子进程，不写入全局 Git 配置，也不依赖其它工程路径。GitHub、其它主机及非 `22` 的自定义 SSH 端口保持原规则。克隆或递归更新失败会返回非零状态，停止本轮同步并保留错误；不会再输出该项同步成功。各仓清单与浅克隆参数保留；全量同步默认逐仓复用已有工作区，空或缺失目录才首次克隆，不批量删除旧仓名目录、多层子树或缓存。未提交内容须逐仓处理，精确 `YES` 仅放弃当前仓自己的内容。

## <span id="jobs-toc-heading-2" data-jobs-toc="v2">一、运行与交互约定 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

- 根目录 `.command` 入口使用 macOS 的 zsh；跨平台审计入口使用已有 Python。
- 双击运行先显示脚本内置自述，并等待回车继续；`README.md` 供运行前阅读。
- 子模块入口在终端显示来源和日志位置，日志位于系统临时目录，下载模式日志可带运行时间与进程号。清理与审计默认只输出终端，审计另存报告需显式使用 `--json`。
- 普通安装 / 更新 / 升级步骤统一为：**回车跳过，输入任意字符后回车执行**。
- 危险操作默认必须明确确认；[缓存清理脚本](#cache-cleanup)按其约定，展示清单后直接回车执行，输入任意字符取消。
- Homebrew 按健康标准处理：架构识别、shellenv 注入、当前会话生效、可选健康更新。

## 二、<span id="feature-navigation">功能分类与入口导航</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 功能目录 | 功能覆盖 | 运行入口 |
| --- | --- | --- |
| [Flutter](./JobsCommand@Flutter/README.md) | SDK / FVM 环境、项目创建与依赖、Android / iOS / 鸿蒙构建、资源与工程辅助 | 按 macOS / Windows 和功能分类选择脚本 |
| [Git 工具](./JobsCommand@Gits/README.md) | 仓库下载、子模块登记与关联、历史与分支操作、远端地址及附件处理 | 对应功能目录内的脚本 |
| [通用工具](./JobsCommand@Others/README.md) | 文件统计、搜索替换、权限与应用运行、时间戳、截图、键盘记录、计划任务 | `MacOS/` 内各独立功能包 |
| [iOS](./JobsCommand@iOS/README.md) | CocoaPods 安装 / 源 / 发布、工程分析、模拟器、图标、打包及重签名 | CocoaPods、配置、其它和打包分类目录 |
| [系统与开发配置](./JobsConfigOS/README.md) | 新系统初始化、终端命令、编辑器、代码片段、快捷键与 AI 工具配置 | 新系统入口或各配置子仓独立入口 |
| [Python 桌面工具](./JobsPythonTools.py/README.md) | 用量 / 流量 / 系统监控、账号工具、Mock、远程主机、局域网文件服务与 IPA 工具 | 各工具运行或平台打包入口 |
| [Shell 工具](./JobsSh.sh/README.md) | Shell 环境、开发工具安装及数据库等本机维护操作 | 平台目录内对应功能入口 |
| [macOS Finder 扩展](./OS@Extension/MacOS@Extension/README.md) | 文件与路径操作、编辑器 / 终端启动、Git 与 Flutter 工作流、模拟器与代码地图 | 总安装器或独立功能目录的安装 / 卸载入口 |
| [Windows 右键扩展](./OS@Extension/WindowsOS@Extension/README.md) | 资源管理器右键、项目运行与构建、SDK 管理、编辑器 / 终端和 Git 工具 | 总菜单或独立包的安装 / 卸载入口 |
| [Sourcetree 动作](./SourceTree.command/README.md) | 自定义动作菜单、Git 操作、编辑器启动及 Flutter 工程运行 / 构建 | 安装菜单后使用动作，或直接运行对应脚本 |

## <span id="jobs-toc-heading-4" data-jobs-toc="v2">三、使用方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

macOS 功能包通常在同名文件夹内放置 `.command` 与 README；根目录子模块和清理入口直接放在本仓根部。双击入口，或从本仓根目录用 zsh 运行。先查看不写入的预览：

```shell
zsh './【MacOS】🧾更新gitmodules.command' --dry-run
zsh './【MacOS】🧭更新引用Git父仓=>子仓.command' --dry-run
zsh './【MacOS】🧹清理缓存与构建产物.command' --dry-run
```

预览后需要执行时，按对应脚本说明去掉 `--dry-run` 并完成交互确认。下载入口默认会真实联网并更新仓库，使用前先读[两种同步模式](#readonly-submodule-mode)。Windows 工具在 Windows 上运行对应 `.cmd` / `.bat` / PowerShell 入口；Python 工具的环境和启动方式见各自 README。

## <span id="jobs-toc-heading-5" data-jobs-toc="v2">四、执行范围与结果 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

| 入口 | 联网与写入边界 | 结果如何确认 |
| --- | --- | --- |
| 默认只拉取 | 更新入口仓及已登记子树；不新增关联、不暂存、不提交、不推送 | 查看来源、分支、提交及递归校验；任一步失败须处理后重试 |
| 维护模式 | 按选择下载或更新，可能写 `.gitmodules`、整理元数据并提交入口父仓；推送需启用开关 | 查看所选范围、父仓指针和日志；默认不推送 |
| 对齐引用 / 增量登记 | 修改本地父子关联和索引，不联网、不提交、不推送 | 查看计划、关联备份及最终 Git 状态；`--dry-run` 不应用计划 |
| 清理 | 只在脚本目录向下删除匹配项；不移动到废纸篓 | 查看逐项路径、原因、空间与最终删除 / 跳过 / 失败结果 |
| 审计 | 不执行脚本业务；只有 `--json` 会写指定报告 | 查看通过 / 失败 / 未验证、退出码及可选逐文件报告 |

## <span id="jobs-toc-heading-6" data-jobs-toc="v2">五、环境准备与排查 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a></span><!-- jobs-toc:heading-end -->

Git 入口依赖健康的 Git 与 macOS 系统工具。默认只拉取不安装 Homebrew / fzf；维护菜单需要的依赖按其提示处理。清理入口仅使用 zsh 与 Python 标准库，实际删除要求 Python 3.11+ 的安全目录删除能力；审计器使用本机已有解释器，缺失的检查器记为未验证。

运行失败时先查看终端指出的仓库或文件路径与日志，再处理依赖、权限、分支或未提交状态。语法检查可以使用[跨平台审计器](#script-audit)，开发回归入口及隔离范围见 [Tests/README.md](./Tests/README.md)。语法通过不等于实际安装、构建、网络或 GUI 功能已经验收。

[**Homebrew**](https://brew.sh/) 安装路径由用户选择：已有可运行安装时复用；确实需要安装时先强提示，只有精确输入大写 `YES` 才选择系统标准目录，其它输入或直接回车选择当前用户的 `.local/homebrew`。`YES` 只表示选择路径，权限与密码由官方安装器实际处理；有管理员权限也可以选用户目录。选定路径失败立即停止，不自动切换；`Ctrl+C` / 输入结束取消整个任务。

Homebrew 的发现、健康检查、安装路径选择与复检均封装在每个相关脚本自己的函数中。

负责安装 / 构建的 Python 启动入口在各自文件内封装完整的 Homebrew → Python → 虚拟环境自检流程；独立复制脚本不需要额外的环境支持文件或同步工具。[只读审计入口](#script-audit)直接使用已有 Python，不安装或升级环境。

**隔空投送与跨机分享：** 独立 App 的启动脚本、图标和辅助资源应包含在 App 内；系统可能通过 [App 路径隔离](https://developer.apple.com/forums/thread/724969)从临时位置运行收到的 App，单纯改为相对路径仍不能保证找到 App 旁的外置文件。确需外置工程的 [Finder 管理入口](./OS@Extension/MacOS@Extension/Scripts/README.md#logs-and-troubleshooting)使用运行时包目录，直接打开 App 无法定位时选择同时含同名 App 与 `Scripts` 的原始目录；取消不执行安装或卸载。

分享源码功能包时保留入口、源码、配套脚本和资源的相对结构；构建输入按脚本或配置文件位置解析，用户配置与缓存按目标机器的当前用户目录解析。已有打包产物不会因源码或模板改动自动更新，分享前应由对应打包入口重新生成，并在目标机器检查系统版本、架构及业务依赖。迁移目录、特殊字符和模拟隔离测试只能证明对应路径分支，不能代替真实隔空投送、目标机启动及完整业务验收。

## 六、<span id="submodule-scripts">Git 子模块脚本</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### <span id="jobs-toc-heading-8" data-jobs-toc="v2">[【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command](./【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command)</span><!-- jobs-toc:heading-end -->

> **目的：** 默认递归拉取已登记子模块目标分支的最新提交，保持本地跟踪分支；显式维护模式保留清单与登记能力。

- 启动时回车默认进入[只拉取模式](#readonly-submodule-mode)，先预检本地状态，再查询当前父仓及子仓目标分支最新提交，按完成标记判断跳过或同步；恢复已有游离 HEAD，不提交、不推送。
- 显式选择维护模式后，按以下原有清单和菜单流程处理。

* 确认自述后读取脚本清单、检查远端，尝试拉取父仓。
* 父仓有未提交改动：跳过父仓拉取，再检查所选子仓；远端获取失败或 rebase 冲突则停止本轮。
* 在主菜单选择同步范围；“切换同步深度”可在默认“向下递归”和“仅直属子模块”之间切换，当前深度适用于各同步动作。
  * 全量同步：逐项同步清单内全部目标，按目录状态复用或首次克隆。
  * 只更新已有：更新清单内已存在的子仓；一个都没有时转全量同步。
  * 指定子模块：回车勾选或取消，空格确认开始。
  * 添加地址：输入新仓地址，自动用仓名作为目录，本轮登记并同步。
* 补齐关联配置，检查并处理目标子仓目录。
  * 目录为空或缺失：首次克隆；已有有效 Git 工作区：保留目录、缓存及后代；默认不取 tags 时，远端最新提交、完成标记与本地状态匹配可跳过当前仓，否则获取并快进更新。
  * 已有 `modules/` 缓存时先核验并恢复空工作区；非 Git 非空目录保护并停止。
  * 子仓有未提交、已暂存或未跟踪内容：红字加粗显示该仓绝对路径并循环等待；精确输入 `YES` 只放弃当前仓自己的未提交内容，或在外部处理后回车复检。其它输入继续复检；无交互或输入结束则停止。
* 拉取并快进到远端目标分支最新提交：优先使用该层 `.gitmodules` 显式 `branch`，`.` 继承直接父仓分支；未设置时读取该子仓远端默认分支；显式目标分支不存在时立即停止，不回退其它分支。
  * 已有目标本地分支只允许快进，领先远端或发生分叉时停止并保留本地提交；缺少目标分支时创建本地跟踪分支。
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

本仓根目录维护三个[子模块入口](#submodule-scripts)；各工具子仓的脚本用途和执行流程在各自 README 中说明。`OS@Extension/` 是普通分类目录，没有独立 Git；其中两个扩展仓仍由本仓直接登记和管理。

`JobsCommand@Flutter`、`JobsCommand@Gits`、`JobsCommand@Others`、`JobsSh.sh`、`SourceTree.command` 均按 `MacOS/` 与 `WindowsOS/` 分开：原 Shell 脚本与资源在 `MacOS/`，Windows 使用原生 PowerShell 与可双击 `.cmd`。iOS 模拟器、Xcode 与 Apple 专属工具链入口只保留在 macOS；各子仓 README 列出逐项功能对照、平台排除及验证边界。

| 路径 | 职责 |
| --- | --- |
| [JobsCommand@Flutter/](./JobsCommand@Flutter/README.md) | Flutter 环境、工程、构建与常用工具脚本。 |
| [JobsCommand@Gits/](./JobsCommand@Gits/README.md) | Git 下载、关联、历史、迁移等操作脚本。 |
| [JobsCommand@Others/](./JobsCommand@Others/README.md) | 通用文件处理与终端工具脚本。 |
| [JobsCommand@iOS/](./JobsCommand@iOS/README.md) | iOS 开发环境、工程维护、安装与构建脚本。 |
| [JobsConfigOS/](./JobsConfigOS/README.md) | 系统、编辑器、代码片段及 Codex 等配置子仓。 |
| [JobsPythonTools.py/](./JobsPythonTools.py/README.md) | Python 工具子仓及跨平台运行、打包入口。 |
| [JobsSh.sh/](./JobsSh.sh/README.md) | Shell 工具与环境安装脚本。 |
| [OS@Extension/MacOS@Extension/](./OS@Extension/MacOS@Extension/README.md) | Finder 扩展工程及打包、安装入口。 |
| [SourceTree.command/](./SourceTree.command/README.md) | Sourcetree 自定义动作、维护脚本及菜单资源。 |
| [OS@Extension/WindowsOS@Extension/](./OS@Extension/WindowsOS@Extension/README.md) | Windows 资源管理器右键扩展及组合安装入口，远端仓名为 `WindowsOS_Extension`。 |
| [.gitmodules](./.gitmodules) | 子仓路径、克隆地址和跟踪分支登记。 |
| `【MacOS】⏬下载配置当前Git子模块（可向下同步递归）.command` 等三个根脚本 | 本仓直接管理的下载更新、关联修复和增量登记入口，完整说明见[第六章](#submodule-scripts)。 |
| [【MacOS】🧹清理缓存与构建产物.command](./【MacOS】🧹清理缓存与构建产物.command) | 按缓存名称、后缀及构建标记递归清理，拷贝目录前使用；说明见[第八章](#cache-cleanup)。 |
| [🔎审计脚本.py](./🔎审计脚本.py) | 独立跨平台审计入口，默认只输出终端结果；参数见[第九章](#script-audit)。 |
| [Tests/](./Tests/README.md) | 隔离回归测试源码及留存报告；审计脚本运行时不依赖此目录，也不自动生成它。 |
| [Git子模块多平台检查报告.md](./Git子模块多平台检查报告.md) | 多平台配置、例外与静态验证记录。 |

## 八、<span id="cache-cleanup">拷贝前清理缓存与构建产物</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

入口：[【MacOS】🧹清理缓存与构建产物.command](./【MacOS】🧹清理缓存与构建产物.command)。从**脚本所在目录**向下递归，包括多层子仓；不依赖当前终端目录、仓库名、子模块清单或已知工程路径。整个目录复制或改名后仍可使用，也可把脚本放到其它待清理目录的根部。依赖 `zsh` 和 `python3` 标准库，不自动安装软件；实际删除要求 Python 3.11+ 且支持安全的 `rmtree(dir_fd=...)`，旧环境仍可预览。

双击脚本，阅读自述后回车扫描；脚本逐项列出路径、识别原因、磁盘占用和预计释放空间。**直接回车清除，输入任意字符（包括空格）后回车取消。** 默认适合拷贝前精简，会删除识别到的缓存和构建产物；运行前先停止构建与调试，避免文件在扫描后继续变化。

在脚本所在目录运行：

```shell
# 先查看将清理哪些内容；不会删除文件
./【MacOS】🧹清理缓存与构建产物.command --dry-run

# 拷贝前清理：展示清单后交互确认
./【MacOS】🧹清理缓存与构建产物.command

# 继续使用本机已构建的工具：仅清缓存，保留最终产物
./【MacOS】🧹清理缓存与构建产物.command --cache-only

# 自动化执行：明确跳过交互确认
./【MacOS】🧹清理缓存与构建产物.command --yes
```

`--dry-run` 可与 `--cache-only` 组合；`DRY_RUN=1` 也表示只预览，并优先于 `--yes`。非交互运行必须显式选择预览或 `--yes`。清理前会复核预览时的文件快照；内容变化或删除失败返回非零状态，已完成的删除会如实列出。

扫描过程中若文件或目录已被其它进程移走 / 删除，会提示并跳过该项，继续扫描；候选目录统计到一半有内容消失时，整项不加入清理清单。权限错误仍会报错。预览完成后整个目标已消失时计为跳过；内部内容变化或仅部分内容消失时仍停止。删除阶段逐层以 `O_NOFOLLOW` 打开父目录，并相对目录描述符删除，避免父目录被换成符号链接后越界；删除前再次比对目标身份与时间戳。隔离回归：`python3 -m unittest discover -s Tests -p 'test_cache_cleanup.py' -v`，仅操作临时夹具。

| 识别类别 | 特征与范围 |
| --- | --- |
| Xcode 缓存 | `ModuleCache.noindex`、`Index.noindex`、`SDKStatCaches.noindex`、`CompilationCache.noindex`、`SDKExplicitPrecompiledModules`、`Intermediates.noindex`。 |
| Python / 前端 / Gradle 缓存 | `__pycache__`、`.pytest_cache`、`.mypy_cache`、`.ruff_cache`、`.pytype`、`.cache`、`.parcel-cache`、`.turbo`、`.vite`、`.sass-cache`、`.gradle` 和 `.angular/cache`。 |
| 明确的构建输出 | `*DerivedData`、`DerivedData-*`、`.build`、`.dart_tool`、`.next`、`.nuxt`、`.output`、`.svelte-kit`、`*.dSYM`；仅默认模式整目录删除，`--cache-only` 继续检查内部缓存。 |
| 通用输出目录 | `build` / `Build` 同时有 CMake、Ninja、Xcode 或 Flutter 构建标记才匹配；`dist` 需有 `.vite/manifest.json`；`target` 需有 Rust 的 `.rustc_info.json`，或同级 `pom.xml` 与内部 `maven-status`。仅凭目录名不删除。 |
| 带标准标记的缓存 | `CACHEDIR.TAG` 包含标准签名的目录。 |
| 缓存文件 | `*.pyc`、`*.pyo`、`*.tsbuildinfo`、`.DS_Store`、`.eslintcache`、`.stylelintcache`。不会泛化删除所有 `.log`、`.tmp`、`.a`、`.pch` 或名称含 cache 的文件。 |

目录规则命中时删除整个目录，保留范围之外的源码、文档和资源；不要在这些缓存目录内保存手写文件。脚本不跟随符号链接，跳过挂载点、不同设备上的目录，以及 `.git`、`.hg`、`.svn`、`.codegraph`。候选目录内部存在这些受保护内容时，会保留外层目录并继续检查其它内容。`node_modules`、`Pods`、虚拟环境不会被整目录清除，但它们内部匹配的缓存仍会清理。

**Finder 扩展仍在本机使用时，请选 `--cache-only`。** 当前扩展安装器直接注册 DerivedData 中的 App / appex；默认清理会连同这些产物删除，可能导致右键扩展失效，需要重新安装。仅缓存模式保留最终产物，清掉 SDK、模块、索引和编译中间文件；下一次构建会按需重新生成缓存。

**Git 跟踪不等于缓存保护。** 本脚本按文件特征识别，包括已提交的缓存。当前计划任务子仓的 `.build` 就存在已跟踪文件，默认清理后会在该子仓显示删除；脚本不改索引、不提交、不推送，也不重写历史。`.git` 中的对象、软件安装包和拆分测试用二进制仍会保留，因此清理后目录大小不会只剩文本源码大小。

## 九、<span id="script-audit">跨平台脚本审计</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

[🔎审计脚本.py](./🔎审计脚本.py)是独立单文件工具，只依赖 [**Python**](https://www.python.org) 标准库。可以单独复制到待检查目录；默认以脚本位置为根递归扫描，与启动时的终端目录无关。不需要配套 `Scripts/` 或 `Tests/`，不安装或升级环境，不执行被审计文件的业务代码。

在本目录运行，macOS / Linux 使用：

```shell
python3 './🔎审计脚本.py'
```

Windows 使用 Python Launcher；没有 `py` 时可改用已经配置好的 `python`：

```powershell
py -3 './🔎审计脚本.py'
```

默认只显示终端汇总和失败明细，不创建产物目录或报告；需要持久化结果时显式指定 `--json`，会创建必要的父目录，并原子替换指定的普通报告文件。报告目标不得为脚本源码、源码的硬链接、符号链接或特殊文件：

```shell
python3 './🔎审计脚本.py' \
  --json './审计结果.json'

python3 './🔎审计脚本.py' \
  --root './待检查目录' \
  --require-all \
  --jobs 4
```

`--root` 指定扫描目录；`--jobs` 为 1–32，默认 4。命令行显式传入的相对路径以当前终端目录解析。`--help` 可查看内置说明。

| 类型 | 检查方式 | 是否执行被检查脚本 |
| --- | --- | --- |
| zsh / Bash / sh | 相应解释器的 `-n`，按 shebang 选择 | 否 |
| Python | `compile`，不导入模块，不生成字节码文件 | 否 |
| JavaScript / Node.js | `node --check` | 否 |
| PowerShell | 优先 `pwsh`，否则尝试 Windows 内置 `powershell`；使用 `-NoProfile` 和 Parser API | 否 |
| Windows `.cmd` / `.bat` | 标为未验证，需 Windows 隔离测试 | 否 |

审计递归覆盖已经下载的子模块、隐藏工具目录和测试；排除 `.git`、`.codegraph`、`node_modules`、`Pods`、`PodsManual`、`ManualBy*Pods@Pods`、`DerivedData`、供应商目录、虚拟环境和构建目录，只读取普通文件，不跟随符号链接，也不自动下载缺失子模块。完整排除目录名和模式见脚本中的 `EXCLUDED`、`EXCLUDED_PATTERNS` 或 JSON 报告。不会加载用户的 Bash / Node 启动注入，缺少检查器时明确记为“未验证”。JSON 逐项记录相对路径、SHA-256、检查器、通过 / 失败 / 未验证及失败原因。

退出码：`0` 表示已执行的语法检查无失败，`1` 表示发现失败，`2` 表示参数、目录扫描或报告写入错误；`--require-all` 还会把任何未验证项计为非零结果。权限错误、空目录、检查超时不能产生虚假的全绿结果。语法通过仅说明解析成功；安装 / 卸载、真实网络、Windows 注册表、GUI、发布和推送等副作用不由审计器运行。

`Tests/` 保存开发时使用的回归测试，审计器运行不依赖此目录。审计器回归仅操作临时夹具：

```shell
python3 -B -m unittest discover \
  -s Tests \
  -p 'test_script_audit.py' \
  -v
```

其它清理 / 安装回归及目录配置测试的范围见 [Tests/README.md](./Tests/README.md)；已执行范围、修复和未验证项见[脚本审计与升级报告](./脚本审计与升级报告.md)。

Windows 虚拟机可使用 [WindowsRegression.ps1](./Tests/WindowsRegression.ps1) 在系统 PowerShell 5.1 中编排 38 套隔离回归，先做源码 Parser / BOM 与 Git 健康检查，再逐套保存日志、真实退出码和 JSON；环境要求、超时参数与跳过状态见[执行说明](./Tests/README.md#windows-native-regression)。该入口不安装依赖，也不把某一系统或架构的通过结果推广到其它平台。2026-10-26 的实际验证范围、定向重测与跳过项见[Windows 11 ARM 原生报告](./Tests/Reports/windows11-arm64-2026-10-26/summary.json)。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
