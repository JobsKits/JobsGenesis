# `JobsTerminalOpener`

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font>

`JobsTerminalOpener` 是一个 [**Swift**](https://www.swift.org/) macOS App + Finder Sync Extension 工程，用来把“用终端打开”放到 Finder 右键一级菜单区域。

## 一、适用场景 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 在 Finder 中右键任意一个本地文件或文件夹。
- 点击一级右键菜单里的 `用终端打开`。
- 如果选中项是普通文件夹，会用系统 `Terminal.app` 打开该文件夹。
- 如果选中项是文件或包文件，会用系统 `Terminal.app` 打开它所在的父目录。
- 当前入口只处理单个选中项；多选时不展示菜单，避免打开结果不明确。

## 二、运行方式 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

1. 用 [**Xcode**](https://developer.apple.com/xcode) 打开 `JobsTerminalOpener.xcodeproj`。
2. 选择 `JobsTerminalOpener` Scheme，直接运行主 App。
3. Xcode 构建阶段会自动注册并启用 `com.jobs.JobsTerminalOpener.FinderSyncExtension`，成功后会重启 Finder 刷新右键菜单缓存。
4. 回到 Finder，右键任意文件或文件夹，点击 `用终端打开`。
5. 首次重新安装后，构建阶段可能会等待几十秒，用来等 `pluginkit` 从空状态异步登记到可启用状态。

## 三、实现边界 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- Finder Sync Extension 可以进入 Finder 右键一级菜单区域，但最终位置由 macOS 决定，不能保证排在系统菜单项前面。
- 扩展默认监控 `/`，用于覆盖 Finder 中任意位置的文件和文件夹右键菜单。
- 扩展不读取文件内容，只读取 Finder 传入的本地 `file://` URL，计算目标目录后生成临时 `.command` 脚本，再交给 `Terminal.app` 打开。
- 临时脚本会 `cd` 到目标目录并 `exec` 用户当前 shell，用来保证每次点击都新开一个 Terminal 窗口，不复用正在执行任务的现有窗口。
- Finder Sync Extension 保留 App Sandbox；本机自用版通过 `com.apple.security.temporary-exception.files.absolute-path.read-only` 给 `/` 增加只读例外。
- 菜单入口只在 Finder 选中单个本地项目时出现。

## 四、排查说明 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 右键菜单未出现：
  - 确认 `JobsTerminalFinderSync.entitlements` 保留了 `com.apple.security.app-sandbox`；Finder Sync Extension 去掉 sandbox 后可能无法被 `pluginkit` 登记出来。
  - 确认系统设置中 Finder 扩展已经启用，或点击 App 内的 `重新启用扩展`。
  - 重新打开 Finder 窗口。
  - 重新编译后构建阶段会重新启用扩展，并自动重启 Finder。
  - 也可以执行下面命令确认扩展已启用，输出行前面有 `+` 表示启用：

    ```shell
    pluginkit -m -p com.apple.FinderSync -A -v | grep JobsTerminalOpener
    ```

  - 如果已经注册但没有 `+`，执行下面命令启用：

    ```shell
    pluginkit -e use -i com.jobs.JobsTerminalOpener.FinderSyncExtension
    ```

- 点击后没有打开 Terminal：
  - 确认 Finder 中只选中了一个本地文件或文件夹。
  - 确认系统存在 `Terminal.app`。
  - 确认 `JobsTerminalFinderSync.entitlements` 里有 `com.apple.security.temporary-exception.files.absolute-path.read-only`，并包含 `/`。
  - 修改 entitlements 后必须重新运行 `JobsTerminalOpener.xcodeproj` 主 App，让扩展重新签名、注册并启用。
  - 确认菜单来自 `JobsTerminalOpener`，不是旧服务或其它同名工具。
  - 重新点击 App 内的 `重新启用扩展`，再重启 Finder。

- 查看扩展调试日志：

  ```shell
  log stream --predicate 'process == "JobsTerminalFinderSync"' --style compact
  ```

  ```shell
  tail -n 200 "$HOME/Library/Containers/com.jobs.JobsTerminalOpener.FinderSyncExtension/Data/Library/Application Support/JobsTerminalFinderSync/FinderSync.log"
  ```

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
