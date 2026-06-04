# Jobs [**Codex**](https://openai.com/codex) 工作规约

![Jobs出品，必属精品](https://picsum.photos/1500/400)

[toc]

---

## 🔥 <font id=前言>前言</font> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

> 这份文件是 Jobs 本机 [**Codex**](https://openai.com/codex) 的长期工作约定。默认优先服务 MacOS 原生 Shell / `.sh` / `.command` 脚本、[**Markdown**](https://markdown.cn) 文档、[**CocoaPods**](https://cocoapods.org/) `*.podspec`，并纳入 [**CodeGraph**](https://github.com/colbymchenry/codegraph) 索引使用、OC 本地 Pods 拆分、[**Swift**](https://www.swift.org/)、[**Python**](https://www.python.org)、[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 的写作规范。

## 一、总原则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

- 默认使用中文沟通，语气直接、清楚、偏工程实用；可以保留一点 Jobs 风格，但不要为了热闹牺牲可读性。
- 对用户默认称呼为“哥”。例如回复“写好了，放在这个目录”时，应写成“哥，写好了，放在这个目录”。
- 先读现有仓库和同类文件，再动手改。优先复用 `/Users/jobs/Documents/Github/JobsConfigOS`、`/Users/jobs/Documents/Github/JobsGenesis`、`/Users/jobs/Documents/Github/JobsDocs/🔥Shell脚本代码片段.md/Shell脚本代码片段.md`、`/Users/jobs/Documents/JobsOCBaseConfigDemo/JobsByPods` 的现成风格。
- 默认只改用户要求范围内的文件。遇到已有改动，不回滚、不覆盖、不顺手重构。
- 接到散落旧脚本、旧笔记、压缩包整理类任务时，目标不是机械搬运，而是按 Jobs 规范优化代码结构、统一交互、补齐 README、防误触和日志。
- 注释要精简扼要，只解释“为什么这样做”或“这段负责什么”。不要给每行显而易见的赋值写冗长注释。
- 不主动执行有副作用的大命令，除非用户明确要求或当前任务必须验证。包括但不限于 `sudo`、`rm -rf`、`chmod -R`、`git reset --hard`、`git clean`、`brew upgrade`、`pod install`、`flutter clean`、`xcodebuild`。
- 批量处理文件时默认跳过 `.git`、`node_modules`、`Pods`、`.dart_tool`、`build`、`DerivedData`。
- 最终回复要短而准：说明改了哪个文件、核心内容、是否验证。除非用户要求，不要创建提交，不要推送，不要改远程仓库。

## 二、MacOS Shell 脚本（`.sh` / `.command`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 2.1、脚本基座

- 新写或升级脚本时，默认使用：

  ```shell
  #!/bin/zsh
  ```

- 默认添加：

  ```shell
  setopt NO_NOMATCH
  ```

- 脚本路径和日志路径按 Jobs 标准写法：

  ```shell
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
  SCRIPT_PATH="${SCRIPT_DIR}/$(basename -- "$0")"
  SCRIPT_BASENAME=$(basename "$0" | sed 's/\.[^.]*$//')
  LOG_FILE="/tmp/${SCRIPT_BASENAME}.log"
  : > "$LOG_FILE"
  ```

- 脚本必须结构化、模块化：基础路径、彩色日志、通用交互、路径处理、环境检查、业务逻辑分块写函数，最后只在 `main` 里编排调用。

  ```shell
  main() {
    # 主流程统一收口。
  }

  main "$@"
  ```

- 优先写原生 Shell，能用 MacOS 自带工具解决就不引入 [**Python**](https://www.python.org) / [**Node.js**](https://nodejs.org/) / [**Ruby**](https://www.ruby-lang.org/) 依赖。
- 涉及批量文件处理时，使用 `find ... -print0` + `while IFS= read -r -d ''`，路径必须全程加引号，兼容空格、中文、括号和特殊符号。
- 涉及文本替换时，优先使用 `grep -Fq`；复杂替换可以使用 `perl`，避免脆弱的 `sed` 转义。

### 2.2、彩色日志

- 新脚本默认带这一组函数；已有脚本按原风格补齐即可。

  ```shell
  log()            { echo -e "$1" | tee -a "$LOG_FILE"; }
  color_echo()     { log "\033[1;32m$1\033[0m"; }         # 正常绿色输出
  info_echo()      { log "\033[1;34mℹ $1\033[0m"; }       # 信息
  success_echo()   { log "\033[1;32m✔ $1\033[0m"; }       # 成功
  warn_echo()      { log "\033[1;33m⚠ $1\033[0m"; }       # 警告
  warm_echo()      { log "\033[1;33m$1\033[0m"; }         # 温馨提示
  note_echo()      { log "\033[1;35m➤ $1\033[0m"; }       # 说明
  error_echo()     { log "\033[1;31m✖ $1\033[0m"; }       # 错误
  err_echo()       { log "\033[1;31m$1\033[0m"; }         # 错误纯文本
  debug_echo()     { log "\033[1;35m🐞 $1\033[0m"; }      # 调试
  highlight_echo() { log "\033[1;36m🔹 $1\033[0m"; }      # 高亮
  gray_echo()      { log "\033[0;90m$1\033[0m"; }         # 次要信息
  bold_echo()      { log "\033[1m$1\033[0m"; }            # 加粗
  underline_echo() { log "\033[4m$1\033[0m"; }            # 下划线
  ```

- 终端输出和日志落盘必须同步，排查时能直接看 `/tmp/脚本名.log`。
- 成功、警告、错误要有明确前缀。失败分支不要静默吞掉，至少输出失败命令或目标路径。

### 2.3、交互约定

- `.command` 双击脚本优先显示同目录 `README.md`，用户按回车后继续，`Ctrl+C` 取消。

  ```shell
  show_readme_and_wait() {
    local readme_path="${SCRIPT_DIR}/README.md"
    clear
    if [[ -f "$readme_path" ]]; then
      highlight_echo "============================== README.md =============================="
      cat "$readme_path" | tee -a "$LOG_FILE"
      highlight_echo "======================================================================="
    else
      warn_echo "未找到 README.md，继续执行内置流程说明。"
    fi
    echo ""
    read -r "?👉 已阅读自述文件，按回车继续执行；按 Ctrl+C 取消：" _
  }
  ```

- 普通安装 / 更新 / 升级 / 自检类操作统一为：直接回车跳过，输入任意字符后回车执行。
- 只要涉及“升级 / 更新 / upgrade / update”，都必须遵守这条规则；不要写成“回车执行升级，输入任意字符跳过”。

  ```shell
  ask_any_to_run() {
    local message="$1"
    local answer=""
    read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
    [[ -n "$answer" ]]
  }
  ```

- 危险操作必须要求输入 `YES`，不能把回车设计成执行。

  ```shell
  confirm_yes() {
    echo ""
    warn_echo "⚠ $1"
    gray_echo "危险操作必须输入 YES 后回车；其它输入一律取消。"
    local input=""
    IFS= read -r "input?➤ "
    [[ "$input" == "YES" ]]
  }
  ```

- 用户拖入路径时，必须去除首尾引号、回车，并兼容多个路径。

  ```shell
  strip_outer_quotes() {
    local value="$1"
    value="${value%$'\r'}"
    value="${value%$'\n'}"
    value="${value#\"}"
    value="${value%\"}"
    value="${value#\'}"
    value="${value%\'}"
    print -r -- "$value"
  }
  ```

### 2.4、[**Homebrew**](https://brew.sh/) / MacOS 环境

- [**Homebrew**](https://brew.sh/) 相关脚本必须识别 Apple Silicon 和 Intel：

  ```shell
  get_cpu_arch() {
    [[ "$(uname -m)" == "arm64" ]] && echo "arm64" || echo "x86_64"
  }
  ```

- 查找 `brew` 时按顺序兼容：`command -v brew`、`/opt/homebrew/bin/brew`、`/usr/local/bin/brew`。
- 写入 shellenv 时必须防重复追加，使用明显的 header / footer 块。
- 写入配置后要让当前终端立即生效：`eval "$shellenv_cmd"`。
- 已安装 [**Homebrew**](https://brew.sh/) 时，不自动执行 `brew update && brew upgrade && brew cleanup && brew doctor && brew -v`，必须询问用户。
- 涉及 CLT、[**Xcode**](https://developer.apple.com/xcode/)、[**CocoaPods**](https://cocoapods.org/)、[**Flutter**](https://flutter.dev/)、[**Android Studio**](https://developer.android.com/studio?hl=zh-c)、[**Java**](https://www.java.com/)、[**Ruby**](https://www.ruby-lang.org/)、[**Node.js**](https://nodejs.org/) 等工具链时，先检查再执行，失败时输出下一步排查方向。

### 2.5、批量脚本 / 压缩包输出

- 当用户要求整理脚本并输出压缩文件时，最终结构必须是“每个脚本一个文件夹”。
- 文件夹名使用脚本完整文件名，包含后缀，例如：

  ```text
  【MacOS】⚙️运行授权.command/
  ├── 【MacOS】⚙️运行授权.command
  └── README.md
  ```

- 文件夹内除了脚本本体，必须生成同风格 `README.md`。
- 如果原始输入是散落脚本，整理时优先保留原脚本名；只在明显错误、重复或不符合 Jobs 命名时，才做最小必要改名。
- 批量升级脚本时，默认做结构优化：统一 `#!/bin/zsh`、路径变量、彩色日志、README 阻塞、防误触、`main "$@"`、[**Homebrew**](https://brew.sh/) 自检和升级交互。
- 输出压缩包前应做静态检查和结构检查；无法执行 MacOS 专属命令时，README 或最终说明里写清楚“未实际执行”。

### 2.6、Shell 验证

- Shell 脚本优先做静态检查：

  ```shell
  zsh -n '脚本名.command'
  ```

- 修改 `.command` 后确认 shebang、`SCRIPT_DIR` / `LOG_FILE`、`main "$@"`、路径引号、危险操作 `YES` 确认、普通升级动作不是默认执行。


### 2.7、脚本运行策略与自检定义

- 所有可独立运行的脚本，执行真实业务逻辑前必须先打印自述说明，再等待用户回车确认；用户未回车前不得继续往下执行。`.command` 优先读取同目录 `README.md`，没有 `README.md` 时必须输出内置说明。

  ```shell
  show_script_intro_and_wait() {
    # 执行前展示脚本用途，让用户确认不是误触。
    clear
    highlight_echo "============================== 脚本自述 =============================="
    note_echo "当前脚本：${SCRIPT_PATH}"
    note_echo "脚本用途：这里写清楚当前脚本准备做什么、会影响哪些文件或环境。"
    warn_echo "继续前请确认已经理解脚本影响范围；按 Ctrl+C 可以取消。"
    highlight_echo "======================================================================="
    echo ""
    read -r "?👉 确认继续执行请按回车；按 Ctrl+C 取消：" _
  }
  ```

- 新写脚本时优先参考 [**JobsDocs Shell 脚本代码片段**](https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md)，但不要机械复制；必须结合当前脚本职责做最小必要改造。
- 每个方法 / 函数都要写简短注释，说明这段函数负责什么；注释服务维护，不写无意义的逐行翻译。
- `main` 是唯一流程收口点，里面同样要写清楚主流程编排注释，最后固定：

  ```shell
  main() {
    # 主流程统一收口：先展示自述，再做环境检查，最后执行真实业务逻辑。
    show_script_intro_and_wait
    check_environment
    run_business
  }

  main "$@"
  ```

- 自检类脚本的定义统一为：检测目标是否存在；如果已经存在，则进入升级 / 更新逻辑；如果没有检测到已安装，则安装最新版本。
- 自检、安装、升级都必须先检查再执行，并遵守交互确认：普通动作不能默认执行，危险动作必须输入 `YES`。
- 新写或升级脚本继续统一使用 `#!/bin/zsh`，不要退回 `#!/bin/bash`；除非目标环境明确不是 MacOS / zsh。


## 三、Git 仓库规则 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 3.1、🌍JobsMacEnvVarConfigs 仓库

- 处理 `🌍JobsMacEnvVarConfigs` 仓库时，先分清根目录入口脚本和 `scripts/` 下的解耦脚本，不要把二者混成一类。
- `scripts/` 是存放解耦脚本代码的目录；这里面的脚本主文件名对应终端里的命令名，脚本文件统一以 `.command` 作为后缀。
- `scripts/` 下每一个具体的 `*.command` 脚本，都必须由同名文件夹包裹，并且每个脚本文件夹内都必须放置这个脚本对应的 `README.md`。

  ```text
  scripts/
  ├── install.command/
  │   ├── install.command
  │   └── README.md
  └── update.command/
      ├── update.command
      └── README.md
  ```

- `scripts/install.command` 和与 `scripts/` 平级的 `install.command` 不是同一个职责：

  | 入口位置 | 核心职责 | 处理原则 |
  | -------- | -------- | -------- |
  | `scripts/install.command` | 利用 `zsh` 配置安装 MacOS 系统的各种自定义依赖。 | 面向依赖安装和本机环境构建。 |
  | `install.command` | 将 `JobsMacEnvVarConfigs` 内容同步到系统。 | 主要瞄准终端 `zsh` 配置同步。 |

- `scripts/update.command` 是全员升级入口；凡是 `scripts/install.command` 新增、删除或调整安装能力，都必须同步更新 `scripts/update.command`，保持安装与升级能力平行，不允许只改安装不改升级。
- 写或改这个仓库的脚本时，要随时对照 `install.command` 和 `update.command`：安装负责“从无到有”，升级负责“已有环境持续更新”，两者覆盖的工具链和交互顺序应尽量一致。

## 四、[**Markdown**](https://markdown.cn) 文档（`*.md`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 4.1、整体风格

- Jobs 的 `.md` 文档默认使用中文技术笔记风格，结构清楚、标题醒目、能直接复制命令执行。
- 修改 `AGENTS.md` 本身时，也必须反哺本文件：把它当成普通 [**Markdown**](https://markdown.cn) 技术文档同步套用本章规则，专有名词按固定链接表补链，归属于上一条的补充内容必须右缩进。
- `*.md` 文档头部必须有图形化展示。默认使用 2D 封面；只有文档主题明确需要空间感、地球、模型、三维可视化时，才使用 3D 效果。2D 和 3D 二选一，不要在同一篇文档头部堆叠两套封面。

  - 2D 封面统一使用 [**Picsum**](https://picsum.photos) 随机图，当前固定代码如下：

    ```markdown
    ![Jobs出品，必属精品](https://picsum.photos/1500/400)
    ```

  - 3D 效果统一使用 `iframe`，当前固定代码如下：

    ```html
    <iframe
      src="https://dragonir.github.io/3d/#/earth"
      title="Jobs出品，必属精品"
      width="100%"
      height="400"
      style="border:0; display:block;"
      allowfullscreen>
    </iframe>
    ```

  - 常规 Markdown / README / AGENTS 文档优先使用 2D 封面，兼容性最好；如果目标平台不支持 `iframe`，3D 效果必须回退为 2D 封面。

  ```markdown
  # `标题`

  ![Jobs出品，必属精品](https://picsum.photos/1500/400)

  [toc]

  ---
  ```

- `前言` 是二级标题，但不参与中文序号：

  ```markdown
  ## 🔥 <font id=前言>前言</font>
  ```

- 正文二级标题优先使用中文编号：`## 一、...`、`## 二、...`。
- 三级标题使用阿拉伯编号：`### 2.1、...`、`### 2.2、...`。
- 长文档可以保留锚点和上下跳转链接：

  ```markdown
  ## 一、升级标准 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

  <a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
  ```

### 4.2、代码块与缩进

- 命令示例统一使用 fenced code block，并标注语言。
- 凡是内容属于上一条说明的补充、示例或展开，都必须向右缩进两个空格，让视觉层级归属于上一条；包括代码块、表格、引用、图片、[**Mermaid**](https://mermaid.js.org) 流程图、子列表。
- bullet 下方的代码块必须缩进两个空格，让代码块视觉上归属于这条说明；不要让代码块顶到页面左边。

  ````markdown
  - 只要涉及“升级 / 更新 / upgrade / update”，都必须遵守这条规则。

    ```shell
    ask_any_to_run() {
      local message="$1"
      local answer=""
      read -r "?${message}（直接回车跳过；输入任意字符后回车执行）：" answer
      [[ -n "$answer" ]]
    }
    ```
  ````

- bullet 下方的表格必须写成上一条的子内容：上一条 bullet 结束后保留空行，表格每一行源码都以两个空格开头，格式必须像下面这样，不要顶格写表格。

  ````markdown
  - 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

    | 推荐写法                            | 识别别名          | 固定链接                  |
    | ----------------------------------- | ----------------- | ------------------------- |
    | [**Markdown**](https://markdown.cn) | `Markdown` / `md` | `https://markdown.cn`     |
    | [**Mermaid**](https://mermaid.js.org) | `Mermaid`         | `https://mermaid.js.org`  |
  ````

- [**Markdown**](https://markdown.cn) 中的路径、命令、文件名、变量名都用反引号包起来，例如 `LOG_FILE`、`/tmp/脚本名.log`、`README.md`。

### 4.3、外链、表格与流程图

- 能外链的第三方工具、框架、语言、平台，优先用官方链接，并按 Jobs 文档习惯写成 `[**名称**](URL)`，例如 [**Homebrew**](https://brew.sh/)、[**Flutter**](https://flutter.dev/)、[**CocoaPods**](https://cocoapods.org/)、[**Mermaid**](https://mermaid.js.org)。
- 标题、表格、正文第一次出现第三方名词时可以直接加链接；代码块、命令、路径、文件名里的字面量不要加链接。
- 表格用于阶段说明、参数说明、目录统计、命令清单；表头短一点，内容能扫读。
- 复杂流程优先使用 [**Mermaid**](https://mermaid.js.org)。
- 对用户有风险的地方要写明白，不要藏在代码块后面。危险动作必须在文档里说明确认方式，例如“必须输入 `YES` 才会继续”。
- 文档语气可以保留 Jobs 风格短句，例如“Jobs出品，必属精品”“我是有底线的”，但正文要优先服务操作，不堆装饰。

### 4.3.1、专有名词固定超链接

- 写 [**Markdown**](https://markdown.cn) / README / AGENTS 这类技术文档时，遇到下表里的专有名词，正文第一次出现时优先写成 `[**名称**](URL)`；需要强调或便于点击时，后续也可以继续加链接。
- 同一个工具有多个常见写法时，正文优先使用“推荐写法”；括号里的别名只用于识别，不强行改代码块里的命令。
- 代码块、命令、路径、文件名、变量名里的字面量不要加超链接，例如 `brew install fzf`、`Podfile`、`python3`、`go-task/tap/go-task`。
- 如果用户明确给了新的官方链接，以用户最新指定为准，顺手更新这张表。

  | 推荐写法                                                               | 识别别名                                              | 固定链接                                           |
  | ------------------------------------------------------------------ | ------------------------------------------------- | ---------------------------------------------- |
  | [**Markdown**](https://markdown.cn)                                | `Markdown` / `md`                                 | `https://markdown.cn`                          |
  | [**Swift**](https://www.swift.org/)                                | `Swift`                                           | `https://www.swift.org/`                       |
  | [**SnapKit**](https://github.com/SnapKit/SnapKit)                   | `SnapKit`                                         | `https://github.com/SnapKit/SnapKit`           |
  | [**Dart**](https://dart.dev)                                       | `Dart`                                            | `https://dart.dev`                             |
  | [**Flutter**](https://flutter.dev/)                                | `Flutter`                                         | `https://flutter.dev/`                         |
  | [**Ruby**](https://www.ruby-lang.org)                              | `Ruby`                                            | `https://www.ruby-lang.org`                    |
  | [**Homebrew**](https://brew.sh/)                                   | `Homebrew` / `brew`                               | `https://brew.sh/`                             |
  | [**Gem**](https://rubygems.org/)                                   | `Gem` / `gem` / `RubyGems`                        | `https://rubygems.org/`                        |
  | [**CocoaPods**](https://cocoapods.org/)                            | `CocoaPods` / `Cocoapods` / `pod`                 | `https://cocoapods.org/`                       |
  | [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) | `Objective-C` / `OC`                             | `https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html` |
  | [**git-lfs**](https://git-lfs.com/)                                | `git-lfs` / `Git LFS`                             | `https://git-lfs.com/`                         |
  | [**gh**](https://formulae.brew.sh/formula/gh)                      | `gh` / `GitHub CLI`                               | `https://formulae.brew.sh/formula/gh`          |
  | [**nushell**](https://www.nushell.sh/)                             | `nushell` / `nu`                                  | `https://www.nushell.sh/`                      |
  | [**rbenv**](https://formulae.brew.sh/formula/rbenv)                | `rbenv`                                           | `https://formulae.brew.sh/formula/rbenv`       |
  | [**Node.js**](https://nodejs.org)                                  | `node` / `Node.js`                                | `https://nodejs.org`                           |
  | [**jenv**](https://www.jenv.be)                                    | `jenv`                                            | `https://www.jenv.be`                          |
  | [**fvm**](https://fvm.app)                                         | `fvm`                                             | `https://fvm.app`                              |
  | [**pnpm**](https://pnpm.io/)                                       | `pnpm`                                            | `https://pnpm.io/`                             |
  | [**Python**](https://www.python.org)                               | `python` / `python3` / `Python`                   | `https://www.python.org`                       |
  | [**fastlane**](https://fastlane.tools)                             | `fastlane`                                        | `https://fastlane.tools`                       |
  | [**MySQL**](https://www.mysql.com)                                 | `mysql` / `MySQL`                                 | `https://www.mysql.com`                        |
  | [**Hugo**](https://gohugo.io)                                      | `hugo` / `Hugo`                                   | `https://gohugo.io`                            |
  | [**OpenJDK**](https://openjdk.org)                                 | `openjdk` / `OpenJDK`                             | `https://openjdk.org`                          |
  | [**yt-dlp**](https://ytdlp.online)                                 | `yt-dlp`                                          | `https://ytdlp.online`                         |
  | [**FFmpeg**](https://ffmpeg.org)                                   | `ffmpeg` / `FFmpeg`                               | `https://ffmpeg.org`                           |
  | [**go-task**](https://formulae.brew.sh/formula/go-task)            | `go-task` / `tap/go-task` / `go-task/tap/go-task` | `https://formulae.brew.sh/formula/go-task`     |
  | [**uv**](https://formulae.brew.sh/formula/uv)                      | `uv`                                              | `https://formulae.brew.sh/formula/uv`          |
  | [**fzf**](https://formulae.brew.sh/formula/fzf)                    | `fzf`                                             | `https://formulae.brew.sh/formula/fzf`         |
  | [**lazygit**](https://lazygit.dev)                                 | `lazygit`                                         | `https://lazygit.dev`                          |
  | [**dufs**](https://formulae.brew.sh/formula/dufs)                  | `dufs`                                            | `https://formulae.brew.sh/formula/dufs`        |
  | [**Codex**](https://openai.com/codex)                              | `codex` / `Codex`                                 | `https://openai.com/codex`                     |
  | [**CodeGraph**](https://github.com/colbymchenry/codegraph)          | `codegraph` / `CodeGraph`                        | `https://github.com/colbymchenry/codegraph`    |
  | [**Mermaid**](https://mermaid.js.org)                              | `Mermaid`                                         | `https://mermaid.js.org`                       |
  | [**Picsum**](https://picsum.photos)                                | `Picsum` / `picsum.photos`                       | `https://picsum.photos`                       |
  | [**Hammerspoon**](https://www.hammerspoon.org)                     | `Hammerspoon`                                     | `https://www.hammerspoon.org`                  |
  | [**VLC**](https://www.videolan.org/vlc)                            | `VLC`                                             | `https://www.videolan.org/vlc`                 |
  | [**trex**](https://formulae.brew.sh/cask/trex)                     | `trex`                                            | `https://formulae.brew.sh/cask/trex`           |
  | [**Visual Studio Code**](https://code.visualstudio.com)            | `Visual Studio Code` / `VS Code` / `code`         | `https://code.visualstudio.com`                |
  | [**Android Studio**](https://developer.android.com/studio?hl=zh-c) | `Android Studio`                                  | `https://developer.android.com/studio?hl=zh-c` |
  | [**GitHub**](https://github.com)                                   | `GitHub` / `github`                               | `https://github.com`                           |
  | [**Xcode**](https://developer.apple.com/xcode)                     | `Xcode`                                           | `https://developer.apple.com/xcode`            |
  | [**pip**](https://pip.pypa.io)                                     | `pip`                                             | `https://pip.pypa.io`                          |
  | [**JobsKits**](https://github.com/JobsKits)                        | `JobsKits`                                        | `https://github.com/JobsKits`                  |
  | [**JobsDocs Shell 脚本代码片段**](https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md) | `Shell脚本代码片段` / `JobsDocs 脚本片段`        | `https://github.com/JobsKits/JobsDocs/blob/main/🔥Shell脚本代码片段.md/Shell脚本代码片段.md` |

### 4.4、README 固定内容

- 每个可双击脚本目录优先放同名脚本和 `README.md`。
- README 用中文说明，适合用户双击前先看懂：用途、适用场景、执行前检查、操作流程、是否有风险、日志位置、常见问题。
- 技术文档优先包含这些块，按需要取舍：`前言`、`适用场景`、`运行方式`、`执行前检查`、`脚本执行命令`、`流程图`、`日志文件`、`常见问题`、`风险说明`、`未执行声明`。

## 五、[**CocoaPods**](https://cocoapods.org/) Podspec 文件（`*.podspec`） <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 5.1、适用范围

- 本规范来自 `/Users/jobs/Documents/JobsOCBaseConfigDemo/JobsByPods` 下 69 个 `*.podspec` 的现有写法。
- 适用于 Jobs 本地管理的 [**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) Pods、`Extra` 扩展 Pods、聚合 Pods，以及 `ManualByOCPods@Pods` 下手动托管的第三方 Pods。
- 新增或升级 podspec 时，先看同类 Pod 的现有写法，再按本规范收口。不要凭空换一套 [**CocoaPods**](https://cocoapods.org/) 风格。

### 5.2、整体结构

- 自研 Pod / Extra Pod 优先使用同目录 `JobsPodspecKit.rb`：

  ```ruby
  require_relative 'JobsPodspecKit'

  Pod::Spec.new do |spec|
    support_context = JobsPodspecKitForPodName.build_support_context(
      podspec_dir: File.expand_path(File.dirname(__FILE__)),
      support_dir: 'Support',
      support_dependencies: []
    )

    # spec 元信息
    # source / platform / subspec / dependencies / xcconfig
  end
  ```

- 字段顺序优先保持稳定：`require_relative`、`support_context`、`name`、`version`、`summary`、`description`、`homepage`、`license`、`author`、`platform`、`requires_arc`、`source`、`default_subspecs`、根入口文件、`Support` / `Core`、`exclude_files`、`frameworks`、`dependency`、`xcconfig`。
- 字段对齐按现有风格即可：

  ```ruby
  spec.name             = 'JobsBaseUI'
  spec.version          = '1.0.0'
  spec.summary          = 'Base UI component library for Jobs projects.'
  spec.platform         = :ios, '12.0'
  spec.requires_arc     = true
  spec.source           = { :path => '.' }
  spec.default_subspecs = 'Core'
  ```

### 5.3、基础信息与 source

- 自研 Pod 的 `homepage` 可以使用 `https://example.local/PodName`；已经有真实 Git 地址的 Pod 保留真实地址。
- 自研 Pod 作者默认：`spec.author = { 'Jobs' => 'lg295060456@gmail.com' }`。
- 第三方 Manual Pod 保留原作者、原 homepage、原 license；只做本地托管适配，不抹掉来源信息。
- iOS 最低版本默认：`spec.platform = :ios, '12.0'`。
- Objective-C Pod 默认：`spec.requires_arc = true`。
- 本地管理的 Pod 默认：`spec.source = { :path => '.' }`。
- 需要模拟远程 tag 或聚合仓库时，才使用：`spec.source = { :git => "file://#{__dir__}", :tag => spec.version.to_s }`。
- 第三方 Manual Pod 如果保留上游源码声明，可以继续使用：`spec.source = { :git => 'https://github.com/owner/repo.git', :tag => spec.version.to_s }`。

### 5.4、入口头文件 / Core / Support

- 有根入口头文件时，根层只暴露入口头：

  ```ruby
  spec.source_files        = 'PodName.h'
  spec.public_header_files = 'PodName.h'
  ```

- 默认业务代码进入 `Core`：

  ```ruby
  spec.default_subspecs = 'Core'

  spec.subspec 'Core' do |ss|
    JobsPodspecKitForPodName.add_dynamic_support_dependencies(ss, spec, support_context)

    ss.source_files        = 'Core/**/*.{h,m,mm}'
    ss.public_header_files = 'Core/**/*.h'
    ss.resources           = 'Core/**/*.{png,jpg,jpeg,gif,webp,xcassets,bundle,json,plist,xib,storyboard,strings,stringsdict}'
  end
  ```

- 有 `Support` 目录时，自研 Pod 优先用 `JobsPodspecKitForPodName.add_support_subspec(spec, support_context)` 镜像真实目录。
- `Core` 依赖 `Support` 时，优先使用 `JobsPodspecKitForPodName.add_dynamic_support_dependencies(ss, spec, support_context)`。
- 如果某个 Support 子路径必须显式依赖，可以只补最小必要项，例如 `ss.dependency 'JobsOCDefs/Support/UIKit'`。

### 5.5、资源、排除与依赖

- 源码扩展默认覆盖 `h,m,mm`。
- 资源扩展默认覆盖 `png,jpg,jpeg,gif,webp,svg,pdf,json,plist,bundle,xib,nib,storyboard,xcassets,strings,stringsdict,ttf,otf,mp4,aiff`。
- `source_files` 只匹配源码和头文件；图片、xib、bundle、json、plist 等进入 `resources`，不要混在源码 glob 里。
- 自研 Pod 优先调用 `JobsPodspecKitForPodName.apply_standard_exclude_files(spec)`。
- Manual Pod 没有 `JobsPodspecKit` 时，要手写完整排除清单，至少覆盖 macOS 垃圾文件、Git / SVN、[**CocoaPods**](https://cocoapods.org/)、[**Xcode**](https://developer.apple.com/xcode/)、Demo / Example / Test、文档截图、CI / 临时 / 压缩包。
- `frameworks` 使用数组，按现有 Jobs 风格多行写。
- 依赖优先一行一个，放在 `frameworks` 后或对应 subspec 内。有版本约束时使用 [**CocoaPods**](https://cocoapods.org/) 原生写法，例如 `spec.dependency 'lottie-ios', '~> 2.5.3'`。
- 聚合 Pod 依赖很多时，可以先定义 `common_dependencies`，再用 lambda 统一添加。

### 5.6、xcconfig 与校验

- 自研 Pod 默认使用 `JobsPodspecKitForPodName.apply_standard_xcconfig(spec)`。
- 标准配置应包含 `DEFINES_MODULE`、`HEADER_SEARCH_PATHS`、`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`。
- 只有确实需要链接 Objective-C Category 时，才补 `'OTHER_LDFLAGS' => '$(inherited) -ObjC'`。
- 如果某个 Pod 头文件搜索路径必须收窄，可以像 `JobsAPIs` 一样显式指定 `Core` / `Support`，不要无脑扩大。
- podspec 注释同样精简扼要，只解释目录策略、动态 Support、风险依赖、特殊 xcconfig。
- 需要校验时优先使用：

  ```shell
  pod lib lint PodName.podspec --allow-warnings --verbose
  ```

- 本地集成排查优先：

  ```shell
  pod install --no-repo-update
  ```

- 如果当前机器环境不适合实际执行 `pod`，至少做 [**Ruby**](https://www.ruby-lang.org) 语法检查：

  ```shell
  ruby -c PodName.podspec
  ```

- 修改 podspec 后要重点检查：`spec.name` 是否和文件名一致、入口头是否真实存在、`Core` / `Support` glob 是否命中、依赖是否形成循环、资源是否被错误放进 `source_files`。


### 5.7、`JobsPodspecKit.rb` / 样例 `*.podspec` 蒸馏规则

- `JobsPodspecKit.rb` 不是普通工具脚本，而是本地 Pod 的 podspec 基座。新增 Pod 时优先复制同类 Pod 的 `JobsPodspecKit.rb`，并把模块名改成当前 Pod 对应的 `JobsPodspecKitForPodName`，不要把多个 Pod 的模块名混用。
- `build_support_context` 负责扫描 `Support` 真实磁盘目录，把每一级有效文件夹收集成 `Support` subspec 路径，并跳过隐藏目录、`Pods`、Demo / Example / Test、文档截图、构建产物、`__MACOSX`、`.bundle`、`.xcassets` 等不该成为 subspec 的目录。
- `add_support_subspec(spec, support_context)` 负责把 `Support` 目录镜像成真实 subspec 树：每个子目录设置 `header_mappings_dir`，直接源码进入 `source_files`，直接头文件进入 `private_header_files`，资源进入 `resources`；没有直接命中文件时用 `preserve_paths` 保留目录。
- `add_dynamic_support_dependencies(ss, spec, support_context)` 负责让 `Core` 自动依赖所有扫描到的 `Support` subspec。新增、删除、移动 `Support` 子目录后，`pod install` 应能动态反映真实目录结构，不要手写一长串易过期的固定路径。
- `build_file_support_context` / `add_file_support_dependencies` 适合更细的文件级 Support 依赖：只收集真正有源码或资源的路径；如果没有收集到子路径，则回退依赖根 `Support`。
- `apply_standard_exclude_files(spec)` 用统一排除清单兜底，至少覆盖 macOS 垃圾文件、Git / SVN、[**CocoaPods**](https://cocoapods.org/)、[**Xcode**](https://developer.apple.com/xcode) 工程、Demo / Example / Test、文档截图、CI、临时缓存、日志、备份和压缩包。
- `apply_standard_xcconfig(spec)` 是默认收口点。标准 `pod_target_xcconfig` 包含 `DEFINES_MODULE`、`HEADER_SEARCH_PATHS`、`CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES`；标准 `user_target_xcconfig` 指向 `$(PODS_ROOT)/Headers/Public/PodName/**`。确需覆盖时只覆盖最小项，不要无意识扩大或删掉头文件搜索路径。
- 样例 `JobsTimeUtils.podspec` 的结构可以作为新 Pod 模板：先 `require_relative 'JobsPodspecKit'`，再构造 `support_context`，再写基础信息、`spec.source = { :path => '.' }`、`spec.default_subspecs = 'Core'`、入口头文件存在性判断、`spec.header_dir`、`frameworks`、逐行 `dependency`、`add_support_subspec`、`Core` subspec、标准排除和标准 `xcconfig`。
- 样例里 `Core` 的 `source_files` 只收 `Core/**/*.{h,m,mm}`，`public_header_files` 只收 `Core/**/*.h`，资源单独进入 `resources`。后续新增资源扩展时，优先同步 `JobsPodspecKit.rb` 的扩展白名单和 podspec 的 `resources`，避免资源被误塞进源码 glob。
- `spec.header_dir = 'PodName'` 要和 Pod 名保持一致。根入口头文件只在真实存在时暴露，避免新建 Pod 初期因为入口头缺失直接 lint 失败。

## 六、[**Objective-C**](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html) / 本地 Pods 工程规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 6.1、工程背景与目录边界

- 本规范默认服务 Jobs 的 OC 工程，尤其是把原工程里的本地代码逐步提取为本地管理 Pods 的场景。
- 所有本地管理的 Pod 默认位于项目根目录 `JobsByPods` 文件夹下，每个 Pod 文件夹命名统一为 `Pod名@Pods`。
- 外源性 Pod 本地化后，统一放入 `JobsByPods/ManualByOCPods@Pods` 管辖。第三方来源信息要保留，只做本地托管适配，不抹掉上游痕迹。
- `JobsByOCPods` 是最初提取出来的本地 Pod，也是后续本地 Pods 分离时的源头参照。遇到缺文件、缺宏、缺分类、缺辅助类时，优先回到 `JobsByOCPods` 找源头，再迁移到目标 Pod 的合适位置。
- 工程最初能完整编译通过的前提，是尚未把部分本地写法提取成多个本地 Pod。拆分后，每个 Pod 实际上成为独立工程，只是通过同一个 `xcworkspace` 协同管理，因此编译器会提高跨域访问门槛，暴露头文件、模块化、依赖边界和循环引用问题。
- 处理编译错误时，不要只追求“先编过”。要判断错误是不是由本地 Pod 化后的边界变化引起：头文件暴露层级、`Core` / `Support` 归属、podspec 依赖、聚合头、`HEADER_SEARCH_PATHS`、循环依赖，都要一起看。

### 6.2、`Core` / `Support` 文件夹职责

- 每个本地 Pod 默认必须有 `Core` 文件夹；`Support` 文件夹按需存在，不强制创建空目录。
- `Core` 里放准备随着这个 Pod 向外暴露的核心能力。`Core` 代码的头文件通常进入 `public_header_files`，是使用方能看到的 API 边界。
- `Support` 里放辅助 `Core` 的实现细节、兼容代码、内部分类、桥接文件、局部宏和非公开工具。`Support` 不是为了给外部随便引用，而是为了减少 Pod 之间的横向耦合。
- 某个 Pod 缺文件时，最合理路径不是立刻新增跨 Pod 引用，而是去源头 `JobsByOCPods` 寻找，迁移到当前 Pod 的 `Support` 文件夹下，并按既定目录格式放入。
- 能放进当前 Pod `Support` 解决的，不要轻易加新的 Pod 依赖。只有该能力确实属于独立公共能力、多个 Pod 都应该复用时，才考虑拆成独立 Pod 或依赖已有 Pod。
- `Core` / `Support` 的真实磁盘目录结构必须能在 [**Xcode**](https://developer.apple.com/xcode) / Pods 工程里显示出来。新增、删除、移动目录后，通过 `JobsPodspecKit.rb` 动态映射，`pod install` 后应反映真实目录结构。

### 6.3、头文件引用边界

- `Core` 文件夹下的文件用到 `Core` 文件夹下的文件，引用写在 `*.h`。这是公开 API 边界内部的正常暴露。
- `Support` 文件夹下的文件用到 `Support` 文件夹下的文件，引用写在 `*.h`。这是内部辅助层之间的正常依赖。
- `Core` 文件夹下的文件用到 `Support` 文件夹下的文件，引用写在 `*.m`，避免把内部实现细节泄露到公开头文件。
- 用到其他 Pod 时，一律优先保护性写法 + 聚合头文件，避免本地路径、Pods Header 映射和模块化状态不一致导致编译失败。
- 如果某个 Pod 已经提供聚合头，外部引用必须引入聚合头，不要因为当前只用到其中一个协议、宏、分类或类，就绕开聚合头单独引入内部子头。聚合头是这个 Pod 对外承诺的头文件边界，子头只是聚合头内部组织细节。
- 禁止用“补一个更具体的子头 import”来掩盖 podspec 依赖、公开头暴露、modulemap、`HEADER_SEARCH_PATHS` 或循环依赖问题。例如已经引入 `JobsOCProtocols/JobsBaseProtocolHeader.h` 时，不要再为了 `BaseProtocol` 单独引入 `JobsOCProtocols/BaseProtocol.h`；如果 `BaseProtocol` 仍未声明，应排查 `JobsOCProtocols` 的直接依赖、聚合头导出、Pod 生成物和模块边界。

  ```objc
  #if __has_include(<JobsOCDefs/JobsDefines.h>)
  #import <JobsOCDefs/JobsDefines.h>
  #else
  #import "JobsDefines.h"
  #endif
  ```

- 不要在公开头里写脆弱的相对路径，例如 `../../xxx.h`。如果必须靠搜索路径才能找到，要回到 podspec / `JobsPodspecKit.rb` / `header_mappings_dir` / 聚合头设计上修正。
- 头文件放置的核心判断：公开 API 所需的最小依赖可以进入 `*.h`；实现细节、兼容分支、内部分类、只在方法体里使用的类型，优先留在 `*.m`。

### 6.4、本地 Pod 拆分策略

- 拆 Pod 前先确认职责边界：这个能力是公共基础能力、业务 UI、工具分类、模型、宏定义、资源包，还是某个 Pod 的内部辅助实现。职责没分清，不要急着建新 Pod。
- 从 `JobsByOCPods` 分离能力时，优先保持原始文件命名、注释风格和调用方式，先完成边界收口，再考虑小范围整理。
- 新 Pod 目录必须使用 `Pod名@Pods`，内部至少包含 `Core`、`Pod名.podspec`、必要时包含 `Support`、`JobsPodspecKit.rb`、`README.md`、入口头 `Pod名.h`。
- 能用 `Support` 消化的跨域访问问题，优先迁移到当前 Pod `Support`；确实属于可复用公共能力时，才新增 Pod 依赖。
- 每次新增、删除或调整 Pod 依赖，都要同步检查直接依赖和第二层以下间接依赖。不要只看当前 podspec 里写了什么，还要看它依赖的 Pod 又依赖了谁。
- 严禁用“互相依赖”解决编译问题。出现循环依赖时，要把公共部分下沉到更底层 Pod，或把内部实现移动到 `Support`，而不是继续堆 `dependency`。

### 6.5、Pod README 同步规则

- 每个本地 Pod 都应有自己的 `README.md`，因为每个 Pod 本质上都是相对独立的工程。
- 只要更新 Pod 的 `Core`、`Support`、podspec、依赖、资源、入口头、公开 API，就要同步更新该 Pod 的 `README.md`。
- Pod README 按本文档 `4.4、README 固定内容` 的格式写，至少说明：用途、适用场景、目录结构、`Core` / `Support` 边界、公开能力、内部辅助能力、依赖关系、引用方式、资源说明、验证方式、风险说明。
- README 不要只写口号。它要能帮助后续排查：这个 Pod 为什么存在、哪些文件是公开的、哪些文件只是内部支撑、缺文件时应该回哪里找、修改依赖后要看哪个报告。

### 6.6、依赖报告与循环引用校正

- Pod 之间的上下依赖关系，会在每次 `pod install` 时通过脚本挂载加载：

  ```text
  ScriptsByPods/【MacOS】🔍查询Xcode工程依赖关系.command/【MacOS】🔍查询Xcode工程依赖关系.command
  ```

- 依赖报告生成物位于：

  ```text
  PodspecDependencyReport
  ```

- 修改或增删本地管理的子 Pod 依赖后，必须查看 `PodspecDependencyReport`，校正上下依赖关系，重点排查循环引用。
- 不能只看第一层依赖。有些风险藏在第二层、第三层或聚合 Pod 之后，需要沿报告仔细甄别。
- 能生成 `PodspecDependencyReport`，说明对应时间点 `pod install` 已执行成功，依赖关系至少在当时是正常的。后续排查“什么时候还正常”时，可以把报告生成时间作为关键节点。
- 如果依赖报告显示链路过长或边界混乱，优先通过下沉公共能力、迁移内部文件到 `Support`、减少公开头引用来修正，而不是继续扩大 `HEADER_SEARCH_PATHS`。

### 6.7、`ScriptsByPods` 脚本约定

- `ScriptsByPods` 存放适用于整个当前工程的脚本，其中一部分会挂载到 `pod install` 后自动运行。
- 因为 [**CocoaPods**](https://cocoapods.org/) 本身使用 [**Ruby**](https://www.ruby-lang.org) 生态，Pod 相关脚本优先使用原生 Shell + Ruby。除非确实没法低成本实现，不要引入 [**Python**](https://www.python.org)、Node.js 或其他额外运行环境。
- 能在 Shell 里稳定完成的路径处理、文件扫描、日志输出、交互确认，不要强行换语言。能在 Ruby 里直接读 podspec / Podfile / CocoaPods 上下文的，不要绕远路。
- 脚本仍然遵守本文 `二、MacOS Shell 脚本` 的基座规则：`#!/bin/zsh`、路径变量、彩色日志、README 阻塞、防误触、`main "$@"`、危险操作 `YES` 确认、静态检查。

## 七、[**Swift**](https://www.swift.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

### 7.1、文件基座与依赖导入

- [**Swift**](https://www.swift.org/) 文件最顶层优先写系统基础框架判断，再引入 Jobs 本地 Pod 化框架；不要把 `UIKit` / `AppKit` 分散到业务代码中。

  ```swift
  #if os(OSX)
  import AppKit
  #elseif os(iOS) || os(tvOS)
  import UIKit
  #endif

  import JobsByUIKit
  import JobsSwiftBlock
  ```

- 控制器统一继承 `BaseVC`。除非项目已有更具体的 Jobs 基类，否则不要直接继承 `UIViewController`。
- 本地 Pod 化框架默认按项目既有能力引入：`JobsByUIKit` 提供 UI / 链式调用 / 导航栏等能力，`JobsSwiftBlock` 提供闭包封装能力。缺依赖时先检查 `Podfile` / 本地 Pods，不要在业务文件里绕开封装重新实现。

### 7.2、代码块 + 懒加载写法

- UI 属性优先使用“代码块闭包 + `lazy var`”的形式创建，初始化、基础配置、事件绑定尽量收口在同一个代码块里，避免在 `viewDidLoad` 里堆散代码。

  ```swift
  private lazy var demoView: UIView = {
      let view = UIView()
      view.backgroundColor = .clear
      return view
  }()
  ```

- 懒加载代码块里只做对象创建、基础属性和轻量事件绑定；涉及布局、网络、复杂业务状态时，放到独立方法里，避免闭包变成第二个 `viewDidLoad`。
- 需要使用 `self` 的闭包要明确引用策略：UI 初始化闭包尽量不捕获 `self`；事件闭包默认 `[weak self]`，布局闭包按项目现有生命周期可使用 `[unowned self]`。

### 7.3、[**SnapKit**](https://github.com/SnapKit/SnapKit) 与 `byAddTo` 约束写法

- 约束默认使用 [**SnapKit**](https://github.com/SnapKit/SnapKit)，不要混用原生 `NSLayoutConstraint`、`frame` 魔法值和散落约束。
- 约束写进 Jobs 自己封装的 `byAddTo` API 里，添加视图和布局约束同步完成。

  ```swift
  demoView.byAddTo(view) { [unowned self] make in
      if view.jobs_hasVisibleTopBar() {
          make.top.equalTo(self.gk_navigationBar.snp.bottom).offset(10)
          make.left.right.bottom.equalToSuperview()
      } else {
          make.edges.equalToSuperview()
      }
  }
  ```

- 外层需要通过 `xxx.byVisible(YES)` 触发可见 / 唤醒时，按项目现有 API 调用；不要为了临时显示视图绕开封装直接改 `isHidden`。

  ```swift
  demoView.byVisible(YES)
  ```

- 约束优先表达“相对关系”，不要写死屏幕尺寸。遇到导航栏、顶部栏、底部安全区，优先使用现有封装方法判断，例如 `jobs_hasVisibleTopBar()`、`gk_navigationBar.snp.bottom`。

### 7.4、导航栏配置写法

- 导航栏统一使用 Jobs 自己封装的 `jobsSetupGKNav` API；简单页面只关心标题时使用简化配置。

  ```swift
  jobsSetupGKNav(title: "这里写标题")
  ```

- 复杂页面使用完整配置，把左右按钮、图片、点按、追加点按、长按等行为直接挂到链式 API 上，避免散落到多个选择器方法里。

  ```swift
  jobsSetupGKNav(
      title: "Demo 列表",
      leftButton: UIButton.sys()
          .byFrame(CGRect(x: 0, y: 0, width: 32.w, height: 32.h))
          .byImage("list.bullet".sysImg, for: .normal)
          .byImage("list.bullet".sysImg, for: .selected)
          .onTap { [weak self] sender in
              guard let self else { return }
              sender.isSelected.toggle()
              self.jobsSideDrawer?.toggleDrawer()
          }
          .onTapAppend { sender in
              print("追加的点按事件")
          }
          .onLongPress(minimumPressDuration: 0.8) { btn, gr in
              if gr.state == .began {
                  btn.alpha = 0.6
                  print("长按开始 on \(btn)")
              } else if gr.state == .ended || gr.state == .cancelled {
                  btn.alpha = 1.0
                  print("长按结束")
              }
          }
          .onLongPressAppend(minimumPressDuration: 0.8) { btn, gr in
              print("追加的长按事件")
          },
      rightButtons: [
          UIButton.sys()
              .byImage("moon.circle.fill".sysImg, for: .normal)
              .byImage("moon.circle.fill".sysImg, for: .selected)
              .onTap { sender in
                  sender.isSelected.toggle()
                  guard let ws = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let win = ws.windows.first else { return }
                  win.overrideUserInterfaceStyle =
                      (win.overrideUserInterfaceStyle == .dark) ? .light : .dark
              },
          UIButton.sys()
              .byImage("globe".sysImg, for: .normal)
              .byImage("globe".sysImg, for: .selected)
              .onTap { [weak self] sender in
                  guard let self else { return }
                  sender.isSelected.toggle()
                  tableView.reloadData()
              }
      ]
  )
  ```

- 导航栏按钮事件默认用闭包表达。普通点按用 `.onTap`，追加点按用 `.onTapAppend`，普通长按用 `.onLongPress`，追加长按用 `.onLongPressAppend`。
- 事件闭包里先处理 `guard let self else { return }`，再写业务逻辑；不要在按钮链式配置里塞过长业务代码，复杂逻辑下沉到独立方法。

### 7.5、控制器组织方式

- `viewDidLoad` 只做主流程编排：导航栏配置、视图唤醒、数据绑定、首屏请求。不要把子视图创建、约束、事件、业务判断全部堆进去。
- 推荐控制器结构按职责分块：系统导入、本地框架导入、类声明、懒加载属性、生命周期、导航栏配置、UI 装配、事件响应、业务方法。
- 视图创建、`byAddTo` 约束、`byVisible(YES)` 唤醒、`jobsSetupGKNav` 导航栏配置，应保持 Jobs 项目现有链式风格，除非用户明确要求切换成原生写法。

## 八、[**Python**](https://www.python.org/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

<!--
后续补充 Python 规范时，在这里继续写：

- 脚本入口
- argparse / click 等命令行约定
- pathlib / subprocess 使用边界
- 日志与异常处理
- 虚拟环境与依赖管理
- 格式化 / lint / 测试
-->

## 九、[**Dart**](https://dart.dev) / [**Flutter**](https://flutter.dev/) 写作规范 <a href="#前言" style="font-size:17px; color:green;"><b>🔼</b></a> <a href="#🔚" style="font-size:17px; color:green;"><b>🔽</b></a>

<!--
后续补充 Dart / Flutter 规范时，在这里继续写：

- Dart 命名与目录结构
- 页面 / Widget 拆分
- 状态管理
- 路由
- 资源管理
- iOS / Android 打包脚本
- CocoaPods / Gradle / Flutter SDK 版本处理
- 代码生成与自动化脚本约定
-->

<a id="🔚" href="#前言" style="font-size:17px; color:green; font-weight:bold;">我是有底线的➤点我回到首页</a>
