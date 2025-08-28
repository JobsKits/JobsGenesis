#!/usr/bin/env zsh
set -euo pipefail

# ================================== 工具函数 ==================================
# 实用 echo（简单语义输出）
info()    { print -- "ℹ️  $*"; }
ok()      { print -- "✅ $*"; }
warn()    { print -- "⚠️  $*"; }
err()     { print -- "❌ $*"; }

# 获取脚本所在目录并切过去
script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
cd "$script_path"

# 检测 git 版本是否 >= 2.8（--jobs 出现在 2.8）
need_git="2.8.0"
have_git="$(git --version | awk '{print $3}')"
verlte() { [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; }
if ! verlte "$need_git" "$have_git"; then
  warn "Git 版本 $have_git 低于 $need_git，'--jobs' 不可用，将降级为串行更新。"
  JOBS_FLAG=()
else
  # CPU 并发数（macOS / Linux 兼容）
  if command -v sysctl >/dev/null 2>&1; then
    cpu="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
  elif command -v nproc >/dev/null 2>&1; then
    cpu="$(nproc 2>/dev/null || echo 1)"
  else
    cpu=1
  fi
  JOBS_FLAG=(--jobs="$cpu")
fi

# ================================== 预提交（确保后续流程能走通） ==================================
info "暂存当前改动（如有）..."
git add -A

# 这里不自动 commit；只有子模块指针变化后我们再统一提交一次。
# 如果你希望无论如何都 commit 一次，请解除下行注释：
# git commit -m "chore: preflight snapshot" || true

# ================================== 初始化 / 同步子模块配置 ==================================
info "初始化并递归同步子模块..."
git submodule update --init --recursive
git submodule sync --recursive

# ================================== 检查 .gitmodules 的 branch 配置 ==================================
if [[ -f .gitmodules ]]; then
  info "检查子模块的跟踪分支设置（.gitmodules 中的 branch=）..."
  missing=()
  while IFS= read -r path; do
    # 取该 path 的 branch
    branch="$(git config -f .gitmodules "submodule.${path}.branch" || true)"
    if [[ -z "${branch:-}" ]]; then
      missing+=("$path")
    fi
  done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path' | awk '{print $2}')

  if (( ${#missing[@]} )); then
    warn "以下子模块未配置 'branch='（将使用各自 remote 的默认分支，可能不是你想要的）："
    for p in "${missing[@]}"; do
      print -- "   - $p"
    done
    warn "如需固定： git submodule set-branch --branch <main|develop|...> <path> ；然后再次运行本脚本。"
  else
    ok "所有子模块均已配置 branch。"
  fi
else
  warn "未找到 .gitmodules，仓库似乎没有子模块。"
fi

# ================================== 前移全部子模块到各自跟踪分支最新 ==================================
info "拉取并前移所有子模块到各自跟踪分支的最新（--remote --merge）..."
# 说明：
# --remote  从远端抓取对应跟踪分支
# --merge   在子模块工作树执行合并（相当于把最新指向 checkout 下来）
# --recursive 递归处理子模块的子模块
git submodule update --remote --merge --recursive "${JOBS_FLAG[@]}" || {
  err "子模块前移失败。请检查网络或冲突。"
  exit 1
}

# ================================== 提交父仓库里的“子模块指针变化” ==================================
info "提交父仓库中的子模块指针变更..."
# 把 .gitmodules 和所有子模块 path 加入暂存
git add .gitmodules $(git config -f .gitmodules --get-regexp '^submodule\..*\.path' | awk '{print $2}') 2>/dev/null || true

# 仅当有变更时提交
if ! git diff --cached --quiet; then
  git commit -m "chore(submodule): bump all submodules to latest"
  ok "已提交子模块指针变更。"
else
  info "无指针变更需要提交。"
fi

# ================================== 推送父仓库到上游 ==================================
# 取当前分支与上游设置（若无上游则直接推默认的 origin <branch>）
current_branch="$(git rev-parse --abbrev-ref HEAD)"
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"

if [[ -n "${upstream:-}" ]]; then
  info "推送到上游：$upstream ..."
  git push
else
  warn "当前分支没有设置上游，将推送到 origin/${current_branch} 并设置为上游。"
  git push -u origin "$current_branch"
fi

# ================================== 打印父仓库与子模块分支 + hash 摘要 ==================================
print
ok "摘要：父仓库与子模块已更新并推送。以下为各自分支与提交哈希："
print -- "----------------------------------------------------------------"
full_hash="$(git rev-parse HEAD)"
short_hash="$(git rev-parse --short HEAD)"
print -- "📦 PARENT: ${current_branch} @ ${short_hash}  (full: ${full_hash})"

# 子模块摘要
if [[ -f .gitmodules ]]; then
  git submodule foreach --recursive '
    b="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(detached)")";
    sh="$(git rev-parse --short HEAD 2>/dev/null || echo "-")";
    fh="$(git rev-parse HEAD 2>/dev/null || echo "-")";
    printf "  └─ %s: %s @ %s  (full: %s)\n" "$name" "$b" "$sh" "$fh"
  ' | sed "s/^/ /"
else
  print -- "  └─ (no submodules)"
fi
print -- "----------------------------------------------------------------"
ok "完成。"
