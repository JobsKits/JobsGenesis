# JobsGenesis 脚本升级优化版

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

## 🔥 <font id=前言>前言</font>

- 本包由原始脚本压缩包整理升级而来。
- 共处理 `.command` 脚本：**135** 个。
- 涉及 Homebrew 的脚本：**56** 个。
- zsh 静态检查：**当前生成环境没有 zsh，未执行；请在 macOS 上复核**。
- 输出结构保留原大类目录；每个脚本都被同名文件夹包裹，文件夹内包含脚本和 `README.md`。

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

当前生成环境没有 `zsh`，所以没有执行 `zsh -n`。脚本文件已经完成结构化重组与权限设置，建议你在 macOS 上先抽样运行 2～3 个高频脚本，再批量替换旧版本。

详见：`升级报告.json`。

[**Homebrew**](https://brew.sh/) 安装路径由用户选择：已有可运行安装时复用；确实需要安装时先强提示，只有精确输入大写 `YES` 才选择系统标准目录，其它输入或直接回车选择当前用户的 `.local/homebrew`。`YES` 只表示选择路径，权限与密码由官方安装器实际处理；有管理员权限也可以选用户目录。选定路径失败立即停止，不自动切换；`Ctrl+C` / 输入结束取消整个任务。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>

Homebrew 的发现、健康检查、安装路径选择与复检均封装在每个相关脚本自己的函数中。

Python 入口在各自文件内封装完整的 Homebrew → Python → 虚拟环境自检流程；独立复制脚本不需要额外的环境支持文件或同步工具。
