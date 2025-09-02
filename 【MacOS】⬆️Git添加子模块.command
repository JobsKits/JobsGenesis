#!/usr/bin/env zsh
set -euo pipefail

# ============================ Git 子模块批量管理（模块化调用） ============================

# —— 自述 & 用户确认 ——
show_intro_and_wait() {
  cat <<'EOF'
📘 脚本说明
------------------------------------------------------------
本脚本用于批量管理 Git 子模块，包含以下流程：
  1. 切换到脚本所在目录，并确保这是 Git 仓库根目录
  2. 删除当前仓库下所有已存在的子模块（包括 .gitmodules 配置）
  3. 重新添加预定义的子模块
  4. 同步子模块配置并首次拉取
  5. 将子模块前移到远端分支最新，并【固化到父仓】记录最新 SHA
  6. 配置远程仓库（交互式输入）
  7. 确保父仓在 main 分支，并自动 pull --rebase + push 到远端

⚠️ 注意：
运行后将会：彻底清空现有的子模块，并提交一笔清理记录。
请确保你已经备份或不再需要原有子模块的数据。

------------------------------------------------------------
按下 [回车] 键继续，或 Ctrl+C 取消。
EOF
  read -r
}

# —— 简易语义输出 ——
info_echo()    { echo "ℹ️  $*"; }
success_echo() { echo "✅ $*"; }
warn_echo()    { echo "⚠️  $*"; }
error_echo()   { echo "❌ $*" >&2; }

# 1) 切到脚本所在目录
cd_to_script_dir() {
  local script_path
  script_path="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
  cd "$script_path"
}

# 2) 初始化父仓（幂等）
ensure_repo_initialized() {
  git init
  git add . || true
  git status
}

# 3) 删除子模块
purge_all_submodules() {
  info_echo "清理子模块目录 + 索引 gitlink + .gitmodules + .git/modules"
  local paths=()
  if [[ -f .gitmodules ]]; then
    while IFS= read -r p; do [[ -n "$p" ]] && paths+=("$p"); done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
  fi
  while IFS= read -r p; do [[ -n "$p" ]] && paths+=("$p"); done < <(git ls-files -s 2>/dev/null | awk '$1==160000 {print $4}')

  local uniq_paths=()
  typeset -A __seen
  for _p in "${paths[@]:-}"; do
    [[ -z "${__seen[$_p]:-}" ]] && uniq_paths+=("$_p") && __seen[$_p]=1
  done

  set +e
  for _p in "${uniq_paths[@]:-}"; do
    [[ -e "$_p" ]] && rm -rf -- "$_p" && echo "✅ 已删除：$_p"
    git rm -f --cached -- "$_p" >/dev/null 2>&1 || true
    [[ -d ".git/modules/$_p" ]] && rm -rf ".git/modules/$_p" && echo "🗂️  已删除子模块仓库：.git/modules/$_p"
  done
  set -e

  printf "# Reset by purge_all_submodules on %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > .gitmodules
  git add .gitmodules || true
  git commit -m "chore: reset submodules" >/dev/null 2>&1 || info_echo "无变更可提交"
}

# 4) 确保 .gitmodules 正常
ensure_gitmodules_here() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local top; top="$(git rev-parse --show-toplevel)"
    [[ "$top" != "$PWD" ]] && { error_echo "当前目录不是仓库根目录"; exit 1; }
  fi
  [[ ! -e .gitmodules ]] && echo "# Auto-created" > .gitmodules
  git add .gitmodules || true
}

# 5) 添加子模块
add_submodules() {
  git submodule add -b main https://github.com/295060456/JobsCommand-Flutter.git  ./JobsGenesis@JobsCommand.Flutter
  git submodule add -b main https://github.com/295060456/JobsCommand-iOS.git      ./JobsGenesis@JobsCommand.iOS
  git submodule add -b main https://github.com/295060456/JobsCommand-Gits.git     ./JobsGenesis@JobsCommand.Gits
  git submodule add -b main https://github.com/295060456/JobsCommand-Others.git   ./JobsGenesis@JobsCommand.Others
  git submodule add -b main https://github.com/295060456/JobsSh.git               ./JobsGenesis@JobsSh
  git submodule add -b main https://github.com/295060456/SourceTree.sh            ./JobsGenesis@JobsCommand.SourceTree
}

# 6) 同步子模块
sync_submodules() { git submodule sync; }

# 7) 提交 .gitmodules
commit_gitmodules_and_dirs() {
  git add .gitmodules */ || true
  git commit -m "同步文件" || info_echo "无变更可提交"
}

# 8) 获取并发数
get_ncpu() { command -v sysctl >/dev/null 2>&1 && sysctl -n hw.ncpu || echo 1; }

# 9) 拉取子模块
submodule_init_update() { git submodule update --init --recursive --jobs="$(get_ncpu)"; }

# 10) 前移子模块
submodule_ff_remote_merge() { git submodule update --remote --merge --recursive --jobs="$(get_ncpu)"; }

# 11) 配置 remote
ensure_git_remote() {
  local remote_name="${1:-origin}"
  if git remote get-url "$remote_name" >/dev/null 2>&1; then
    info_echo "已存在 git remote [$remote_name] -> $(git remote get-url "$remote_name")"
    return
  fi
  local remote_url=""
  while true; do
    read "?请输入Git远程仓库地址: " remote_url
    [[ -z "$remote_url" ]] && { warn_echo "输入为空"; continue; }
    if git ls-remote "$remote_url" >/dev/null 2>&1; then
      git remote add "$remote_name" "$remote_url"
      success_echo "已成功配置 [$remote_name] -> $remote_url"
      break
    else
      error_echo "无法访问 $remote_url"
    fi
  done
}

# 12) 固化子模块
record_and_normalize_submodules() {
  git submodule foreach '
    set -e
    if git show-ref --verify --quiet refs/heads/main; then
      git checkout main || true
      git pull --ff-only || true
    elif git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
      git checkout -B main --track origin/main || true
      git pull --ff-only || true
    fi
  '
  local paths; paths=($(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk "{print \$2}"))
  [[ ${#paths[@]} -gt 0 ]] && git add "${paths[@]}"
  git commit -m "chore: bump submodules to latest remote" || info_echo "无变更可提交"
  success_echo "子模块最新提交已固化到父仓"
}

# 13) 确保父仓在 main
ensure_parent_branch() {
  local branch="${1:-main}"
  if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
    if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
      git checkout -B "$branch" --track "origin/$branch"
    else
      git checkout -B "$branch"
    fi
  else
    git checkout "$branch"
  fi
}

# 14) 父仓拉取 & 推送
parent_pull_rebase() {
  local branch; branch="$(git rev-parse --abbrev-ref HEAD)"
  git fetch origin || true
  if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
    git pull --rebase origin "$branch" || git pull --no-rebase origin "$branch" || true
  fi
}
parent_push() {
  local branch; branch="$(git rev-parse --abbrev-ref HEAD)"
  git push -u origin "$branch"
}

# ================================== main ==================================
main() {
  show_intro_and_wait
  cd_to_script_dir
  ensure_repo_initialized
  ensure_git_remote               # 提前配置远端，后面才能 pull/push
  purge_all_submodules
  ensure_gitmodules_here
  add_submodules
  sync_submodules
  commit_gitmodules_and_dirs
  submodule_init_update
  submodule_ff_remote_merge
  record_and_normalize_submodules
  ensure_parent_branch main       # ✅ 确保在 main
  parent_pull_rebase              # ✅ 与远端 main 对齐
  parent_push                     # ✅ 推送更新
}

main "$@"
