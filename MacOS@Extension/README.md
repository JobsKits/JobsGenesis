# `MacOS@Extension`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

`MacOS@Extension` 用来收纳 Jobs 本机自用的 [**Swift**](https://www.swift.org/) macOS App + Finder Sync Extension 工程。当前目录下有三个 Finder 右键增强入口：打开 Git 远程地址、复制文件或文件夹绝对路径、用终端打开文件或文件夹所在目录。

## 一、工程索引 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

| 工程 | 入口文案 | 核心用途 | 打开方式 |
| --- | --- | --- | --- |
| `./JobsGitRemoteOpener` | `打开 Git 远程地址` | 右键 Git 仓库文件夹，打开 `remote` 对应网页。 | `./JobsGitRemoteOpener/JobsGitRemoteOpener.xcodeproj` |
| `./JobsPathCopier` | `复制绝对路径` | 右键任意一个本地文件或文件夹，把绝对路径写入剪贴板。 | `./JobsPathCopier/JobsPathCopier.xcodeproj` |
| `./JobsTerminalOpener` | `用终端打开` | 右键任意一个本地文件或文件夹，用 `Terminal.app` 打开目标目录。 | `./JobsTerminalOpener/JobsTerminalOpener.xcodeproj` |

## 二、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 2.1、批量选择安装

1. 确认本机已经安装 [**fzf**](https://formulae.brew.sh/formula/fzf)。

   ```shell
   brew install fzf
   ```

2. 双击根目录脚本 `./【MacOS】🧩安装Finder扩展.command`。
3. 脚本打印内置自述后，按回车进入 `fzf` 选择界面。
4. 按 `Tab` 多选需要安装的功能，或选择 `全选｜安装全部 Finder 扩展`。
5. 按 `Enter` 后脚本会调用 `xcodebuild` 构建选中的 App，注册并启用 Finder Sync Extension，最后重启 Finder 刷新右键菜单缓存。

### 2.2、单工程手动运行

1. 进入目标工程目录。
2. 用 [**Xcode**](https://developer.apple.com/xcode) 打开对应 `.xcodeproj`。
3. 选择同名 Scheme 运行主 App。
4. App 或 Xcode Build Phase 会注册并启用 Finder Sync Extension。
5. 回到 Finder，右键符合条件的文件或文件夹，点击对应一级菜单入口。

## 三、维护边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 每个扩展工程保持独立目录、独立 `.xcodeproj`、独立 Bundle ID 和独立卸载脚本。
- Finder Sync Extension 菜单位置由 macOS 决定，本目录只保证扩展注册、启用和菜单动作逻辑。
- 新增同类工程时优先沿用 `JobsGitRemoteOpener` 的主 App 注册流程、Build Phase 启用脚本和 README 结构。
- 根目录只做工程索引；每个工程的具体使用、排查和卸载说明写在各自 `README.md`。

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
