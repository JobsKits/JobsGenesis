#!/usr/bin/env zsh

# ✅ 补 PATH：兼容 Homebrew/macOS/Linux 常见安装位
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
command -v git >/dev/null 2>&1 || { echo "❌ git not found in PATH: $PATH" >&2; exit 127; }

# 一次性把全部子模块前移到各自跟踪分支的最新

# 终端执行目录转向目前脚本所在目录
script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
cd "$script_path"

# 先将目前的改动，做一次提交，否则后续流程无法走通
git add .

# 初始化 & 同步
git submodule update --init --recursive
# 同步配置到 .git/config
git submodule sync --recursive

#（可选，提速）并发更新
# 让全部子模块按“各自的 branch”前移
git submodule update --remote --merge --recursive --jobs=$(sysctl -n hw.ncpu)

# 提交父仓库里的“子模块指针变化”
git add .gitmodules $(git config -f .gitmodules --get-regexp '^submodule\..*\.path' | awk '{print $2}')
git commit -m "chore(submodule): bump all submodules to latest"
git push

# ✅ 打印当前分支与哈希
echo "📦 branch: $(git rev-parse --abbrev-ref HEAD)"
echo "🔐 short : $(git rev-parse --short HEAD)"
echo "🔗 full  : $(git rev-parse HEAD)"
