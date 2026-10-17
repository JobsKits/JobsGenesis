# JobsGenesis 脚本升级优化版

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

## 🔥 <font id=前言>前言</font>

- 父子仓配置先看下面的[实际例子](#submodule-quick-look)，全目录检查结果与例外见 [Git 子模块多平台检查报告](./Git子模块多平台检查报告.md)。
- 本包由原始脚本压缩包整理升级而来。
- 共处理 `.command` 脚本：**135** 个。
- 涉及 Homebrew 的脚本：**56** 个。
- 原始整理阶段没有执行 zsh 检查；父子仓专项修改的 **21 份脚本已通过 `zsh -n`**，范围见检查报告。
- 输出结构保留原大类目录；每个脚本都被同名文件夹包裹，文件夹内包含脚本和 `README.md`。

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

| 需要快速确认的事情 | 当前行为 |
| --- | --- |
| 更新清单、下载或修复引用 | 保留已有 URL、分支和扩展字段，不把相对地址覆盖成固定 GitHub 地址。 |
| 同一本地父仓选择下载线路 | 下载脚本通过 `REMOTE_NAME` 选择已配置的父仓 remote；只新增 remote 不会自动切换原生 Git 的默认线路。 |
| 目标平台仓库缺失或仓名不同 | 不创建镜像、不猜地址；保留明确地址或提示补充映射。 |

**前提：目标平台已有对应子仓和父仓所引用的提交。** CodeSnippets 两平台仓名不同，当前仍保留明确的 Gitee 地址；具体处理见[报告中的例外说明](./Git子模块多平台检查报告.md#exceptions)。上表说明地址解析，不能替代远端实际克隆验证。

## 一、升级标准 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 所有脚本统一为 `# shell: zsh`。
- 双击运行先显示 `README.md`，并等待回车继续。
- 统一彩色日志函数，日志落盘到 `$TMPDIR/脚本名.log`。
- 统一 `SCRIPT_DIR` / `SCRIPT_PATH` 路径写法。
- 统一结构化入口：`main "$@"`。
- 普通安装 / 更新 / 升级步骤统一为：**回车跳过，输入任意字符后回车执行**。
- 危险操作必须明确确认，不做回车默认执行。
- Homebrew 按健康标准处理：架构识别、shellenv 注入、当前会话生效、可选健康更新。

## 二、目录统计 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 原始大类 | 脚本数量 |
|---|---:|
| `JobsGenesis@JobsCommand.Flutter` | 57 |
| `JobsGenesis@JobsCommand.Gits` | 15 |
| `JobsGenesis@JobsCommand.SourceTree` | 20 |
| `JobsGenesis@JobsCommand.iOS` | 43 |


## 三、使用方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

进入任意脚本同名文件夹后，双击 `.command` 文件即可。终端方式：

```shell
chmod +x './脚本名.command'
'./脚本名.command'
```

每个脚本文件夹内的 `README.md` 都已经按统一格式生成，可以先看用途、风险和流程图。

## 四、未执行声明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

生成过程中只做文件重组、代码结构升级和 `zsh -n` 静态检查；没有实际执行 `brew`、`pod`、`flutter`、`xcodebuild`、`osascript`、`sudo`、模拟器、Git 远程写入等 macOS 专属或有副作用的命令。

## 五、静态检查结果 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

原始脚本整理阶段没有执行 `zsh -n`。父子仓多平台专项修改涉及的 21 份脚本已完成语法检查，地址解析与脚本隔离回归结果见 [Git 子模块多平台检查报告](./Git子模块多平台检查报告.md#validation)；其它脚本保留原验证范围。

详见：`升级报告.json`。

[**Homebrew**](https://brew.sh/) 安装路径由用户选择：已有可运行安装时复用；确实需要安装时先强提示，只有精确输入大写 `YES` 才选择系统标准目录，其它输入或直接回车选择当前用户的 `.local/homebrew`。`YES` 只表示选择路径，权限与密码由官方安装器实际处理；有管理员权限也可以选用户目录。选定路径失败立即停止，不自动切换；`Ctrl+C` / 输入结束取消整个任务。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

Homebrew 的发现、健康检查、安装路径选择与复检均封装在每个相关脚本自己的函数中。

Python 入口在各自文件内封装完整的 Homebrew → Python → 虚拟环境自检流程；独立复制脚本不需要额外的环境支持文件或同步工具。
