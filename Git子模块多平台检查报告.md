# Git 子模块多平台检查报告

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <span id="前言">前言</span>

检查日期：2026-10-17。范围为本目录的上级 `../` 中全部本地仓库，递归识别真实 Git 根目录、`.gitmodules`、索引中的 gitlink、已配置远端与会写入子模块地址的自有脚本。排除第三方源码、依赖缓存、供应商目录及构建产物的修改。

共扫描 **60 个有效 Git 根目录**，发现 **9 个有效父仓、38 条子模块关联**，另有 **1 份未生效的嵌套 `.gitmodules`、2 条历史声明**。自有同组织同名子仓统一使用相对地址；地址解析不绑定 [**GitHub**](https://github.com)、[**Gitee**](https://gitee.com) 或 [**GitLab**](https://gitlab.com)，也适用于结构相同的自建服务。

导航：[配置原理](#url-rule) · [仓库清单](#inventory) · [例外与限制](#exceptions) · [使用方法](#usage) · [脚本检查](#scripts) · [验证](#validation)。

## 一、<span id="url-rule">配置原理</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

[**Git**](https://git-scm.com/) 的 `.gitmodules` 每个子模块只有一个实际克隆 URL，不提供多个 URL 的自动探活或故障切换。`path` 是本地目录；`url` 指向远端仓库，两者名称可以不同。

同一组织下的兄弟仓库使用 `../仓库名.git`。相对地址以父仓默认远端的**仓库 URL**为基准，不以磁盘目录为基准；多层嵌套的每一级都按各自父仓计算。例如：

```ini
[submodule "SourceTree.command"]
    path = SourceTree.command
    url = ../SourceTree.sh.git
    branch = main
```

| 父仓默认远端 | 子仓解析结果 |
| --- | --- |
| `https://github.com/JobsKits/JobsGenesis.git` | `https://github.com/JobsKits/SourceTree.sh.git` |
| `git@gitee.com:JobsGo/JobsGenesis.git` | `git@gitee.com:JobsGo/SourceTree.sh.git` |
| `https://git.example.com/team/subgroup/JobsGenesis.git` | `https://git.example.com/team/subgroup/SourceTree.sh.git` |
| `ssh://git@git.example.com:2222/team/JobsGenesis.git` | `ssh://git@git.example.com:2222/team/SourceTree.sh.git` |

默认远端通常是当前分支的 upstream 所属 remote；没有对应配置或处于游离 HEAD 时通常回退到 `origin`，仅配置一条 remote 时 Git 也可能直接选用它。实际检查中 Flutter 的唯一 `gitee` remote 可被正常解析。同一本地父仓只新增另一个 remote，不会自动切换子模块线路。解析规则见 [Git 官方子模块说明](https://git-scm.com/docs/git-submodule)。

## 二、<span id="inventory">仓库清单</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

下表路径相对于本报告所在目录。

| 配置 | 条数 | 检查与处理 |
| --- | ---: | --- |
| [JobsGenesis](./.gitmodules) | 9 | 原有相对地址正确；保留 `SourceTree.sh.git` 的真实仓名并补充说明。 |
| [JobsConfigOS](./JobsConfigOS/.gitmodules) | 8 | 7 条相对地址；CodeSnippets 两平台异名，保留明确 Gitee 地址。 |
| [JobsCodexConfigs](./JobsConfigOS/💻JobsCodexConfigs/.gitmodules) | 1 | `../JobsSkills.git` 正确，保留。 |
| [VScodeConfigs](./JobsConfigOS/⚙️VScodeConfigs/.gitmodules) | 1 | 兄弟仓库相对地址正确，保留。 |
| [JobsPythonTools](./JobsPythonTools.py/.gitmodules) | 7 | 将账户工具从固定 GitHub URL 改为 `../JobsCodexAccountSwitcher.git`；其余保留。 |
| [MacOS Extension](./MacOS@Extension/.gitmodules) | 4 | 兄弟仓库相对地址正确，保留。 |
| [JobsBaseConfig](../JobsBaseConfig/.gitmodules) | 4 | 相对地址正确；另有 Swift gitlink 的远端可达性待核实，见下节。 |
| [Flutter](../Flutter/.gitmodules) | 1 | 当前 Gitee 线路的 `../player_m3u8.git` 正确；第三方子仓源码保留。 |
| [语言学习](../语言学习/.gitmodules) | 3 | 固定 GitHub URL 改为兄弟仓库相对地址；继续保留现有仅 GitHub 远端的项目约束。 |
| [JobsDocs 博客历史记录](../JobsDocs/blog/.gitmodules) | 2 | 文件不在 Git 根目录且没有对应 gitlink，不是实际子模块关联；保留外部来源记录。 |

## 三、<span id="exceptions">例外与限制</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- **CodeSnippets 两平台仓库异名**：GitHub 为 `JobsKits/JobsCodeSnippets.git`，Gitee 为 `JobsGo/jobs-code-snippetsJobsCodeSnippets.git`。不存在能同时代表这两个仓名的同一条兄弟仓相对 URL。当前共享配置保留已确认的 Gitee SSH 地址；其它部署线路需要按真实镜像地址明确配置，不能只替换域名。

  仓名尚未统一时，可先不递归克隆父仓，在 `JobsConfigOS` 中为这一条子模块设置本地明确地址，再初始化。下面使用已确认的 GitHub 地址；其它平台改为其真实镜像 URL：

  ```shell
  git config 'submodule.🍎JobsCodeSnippets.url' \
    'https://github.com/JobsKits/JobsCodeSnippets.git'

  git submodule update \
    --init \
    -- '🍎JobsCodeSnippets'
  ```

  后续 `submodule sync` 或下载脚本会重新按共享配置同步，应保留该机器的明确部署步骤；若要求所有平台均原生自动递归，须先统一镜像仓名或提供对应平台的部署配置。没有更名、创建或删除任何远端仓库。
- **Flutter 的第三方来源**：父仓当前只有 Gitee 远端，子仓 Gitee 镜像位于 `JobsGo/player_m3u8`，GitHub 上游位于 `yanmingLiu/player_m3u8`。当前相对地址适用于已有 Gitee 线路；不能推断 GitHub 上存在 `JobsKits/player_m3u8`。
- **语言学习仍为单平台部署**：改成相对地址只解除配置对域名的绑定，不会创建其它平台仓库；保留已确认的仅 GitHub 远端，不自动补建镜像。
- **Swift 子仓提交可达性**：JobsBaseConfig 固定的 Swift gitlink 为 `fa9049029bfc0d82b071c2fbf946ae627fe10366`，未能从现有本地 Gitee 跟踪引用找到可达分支。检查没有 fetch，不等同于实时服务端缺失。切换机器前需核实目标平台包含该提交；仅改 URL 不能修复缺失历史。
- **博客记录未生效**：JobsDocs 的真正 Git 根目录没有子模块 gitlink。`blog/themes/hugo-book` 以普通文件入库，`PaperMod` 目录已缺失；没有将第三方主题擅自改成自有镜像或重建父子关系。
- **提交与分支是两件事**：`git submodule update --init --recursive` 检出父仓记录的 gitlink；`branch = main` 主要影响 `update --remote`。不同平台的主分支可以异名，但所有使用该父仓提交的平台都必须拥有 gitlink 指向的子仓提交。独立快照历史不能仅凭文件树相同替代提交号。

## 四、<span id="usage">使用方法</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

1、在目标平台已具备父仓、全部所需子仓和固定提交的前提下，从该平台克隆父仓。例如：

```shell
git clone 'https://gitee.com/JobsGo/JobsGenesis.git' \
  --recurse-submodules \
  'JobsGenesis'
```

其它平台使用其真实父仓地址。同组织同名的相对子模块自动继承平台、namespace、协议和端口。跨组织、仓库异名或必须指定来源的子模块，继续使用明确地址。

2、已有本地副本切换线路时，先核对当前分支 upstream 和默认远端；只有确定了目标平台，再同步已初始化子模块的地址：

```shell
git submodule sync \
  --recursive

git submodule update \
  --init \
  --recursive
```

`sync` 会更新本地子模块 URL 和已初始化子仓相应远端，执行前先检查各仓自定义远端；它不会自动创建镜像或补齐缺失提交。当前任务没有对真实业务仓运行这些写配置、下载或检出命令。使用下载脚本时，`REMOTE_NAME` 选择父仓已配置的目标 remote，默认 `origin`。

3、修改文件须由内向外提交并将相应子仓提交同步到目标平台，再更新父仓 gitlink。未提交的子仓 `.gitmodules` 和脚本修改不会随父仓递归克隆到其它电脑；当前改动留在本地供审查，没有自动提交或推送。

## 五、<span id="scripts">脚本检查</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

检查所有引用 `.gitmodules` 的自有 Shell 入口，重点处理以下会生成或改写 URL 的路径：

| 入口 | 范围 | 处理目标 |
| --- | --- | --- |
| `⏬下载配置当前Git子模块` | JobsGenesis 内 7 份、JobsBaseConfig 1 份 | 保留共享 URL；相对地址按选定父远端解析，支持通用托管域名及嵌套 namespace；缺映射时报错，不默默跳回 GitHub。 |
| `🧾更新gitmodules` | JobsGenesis 内 5 份、JobsBaseConfig 1 份 | 保留既有 section、URL、branch 和扩展字段；新增只在已有远端能证明映射时使用相对地址。 |
| `🧭更新引用Git父仓=>子仓` | JobsGenesis 内 4 份、JobsBaseConfig 1 份 | 避免把子仓 `origin` 的绝对地址写回覆盖共享相对 URL，保留既有字段；元数据修复与共享 URL 分开处理。 |
| `⬆️Git添加子模块` | JobsCommand Gits 中的旧重建入口 | 内置同名仓清单改成相对地址；添加分支允许通过 `SUBMODULE_BRANCH` 指定。 |
| `⬆️Git添加WindowsOS子模块` | WindowsOS | 内置地址改为相对地址；不因 URL 表示不同删除已有子模块；允许指定添加分支。 |

其余读取配置、按用户明确输入添加子模块、清理运行态及提交推送入口保持原职责。本报告不把地址适配扩展为远端创建、自动镜像、改分支或重写历史授权。

JobsBaseConfig 的旧“更新 gitmodules”入口继续只生成清单，不自动暂存或归集元数据；JobsGenesis 内 5 份入口继续完成增量关联。引用修复入口仍按其原有职责对齐实际目录并清理已经消失的登记，运行前需核对计划。

## 六、<span id="validation">验证</span> <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 真实 Git 解析：38 条配置 × 9 种远端，共 **342 项通过**；在临时仓库中运行 `git submodule init`，覆盖 GitHub、Gitee、GitLab、自建域名、HTTPS / scp SSH / `ssh://`、自定义端口和嵌套 namespace；不访问网络。另按 9 个实际父仓的默认远端配置隔离复验，37 条相对 URL 全部匹配现有子仓远端。
- 下载脚本回归：8 份脚本共 **681 项通过**；隔离提取 URL 处理函数，检查相对地址保留、不同 remote 选择、原有 branch / 扩展字段、错误停止、重复运行，以及跨 namespace 的两层递归同步。另补 **112 项预览与输入处理检查通过**，核对实际下载地址展示及 SSH 用户 / 端口保留；最终源码哈希已归档，已测核心函数保持一致。
- 关联脚本回归：**44 项集成测试与 94 个写入场景通过**，使用临时 Git 仓库验证增量关联、配置保留、URL 映射和元数据修复；另外 3 项隔离检查覆盖旧添加入口的相对地址、分支参数和已有配置保留。
- 静态检查：**21 份改动脚本的 `zsh -n` 全部通过**，本轮修改文件的 `git diff --check` 通过。全目录检查另发现第三方 `3rd/edgetunnel/wrangler.toml` 的已有改动含两处行尾空白，本轮未修改该仓。
- 远端证据：仅检查已有本地远端跟踪引用。JobsGenesis 的 30 条 gitlink 均能从现有本地 Gitee 引用到达，不能据此宣称全部托管平台的实时克隆已通过。

没有运行真实业务入口或安装依赖；没有在真实业务仓创建提交、推送、改远端、切分支、更新索引或重写子仓历史。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
