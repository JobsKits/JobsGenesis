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

⚠️ 注意：
运行后将会：彻底清空现有的子模块，并提交一笔清理记录。
请确保你已经备份或不再需要原有子模块的数据。

------------------------------------------------------------
按下 [回车] 键继续，或 Ctrl+C 取消。
EOF
  read -r
}

# —— 简易语义输出（避免外部依赖） ——
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
  # 先把现状纳入暂存，避免后续操作依赖失败（无变更时不报错）
  git add . || true
  git status
}

# 3)仅删除子模块目录，并清理索引中的 gitlink（mode=160000）
# - 不修改 .gitmodules（仅读取 path）
# - 不删除 .git/modules/*（如需删除：PURGE_GIT_MODULES=1）
purge_all_submodules() {
  info_echo "仅清理子模块目录 + 索引 gitlink（不改 .gitmodules；.git/modules 可选清理）..."

  # --- 收集子模块路径：优先 .gitmodules 的 path ---
  local paths=()
  if [[ -f .gitmodules ]]; then
    while IFS= read -r p; do
      [[ -n "$p" ]] && paths+=("$p")
    done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
  fi

  # --- 补充：从索引里找 gitlink(160000) 的路径 ---
  while IFS= read -r p; do
    [[ -n "$p" ]] && paths+=("$p")
  done < <(git ls-files -s 2>/dev/null | awk '$1==160000 {print $4}')

  # --- 去重 ---
  if [[ ${#paths[@]} -eq 0 ]]; then
    info_echo "未发现子模块路径，跳过。"
    return 0
  fi
  local uniq_paths=()
  typeset -A __seen
  local _p
  for _p in "${paths[@]}"; do
    if [[ -z "${__seen[$_p]:-}" ]]; then
      uniq_paths+=("$_p"); __seen[$_p]=1
    fi
  done

  info_echo "将处理以下子模块目录（共 ${#uniq_paths[@]} 个）："
  local i=1; for _p in "${uniq_paths[@]}"; do echo "  $i) $_p"; ((i++)); done

  # --- 逐个处理：删目录 + 清理索引 gitlink（不中断）---
  set +e
  local removed=0 failed=0 cleared=0 modules_removed=0
  for _p in "${uniq_paths[@]}"; do
    # 1) 删除工作区目录
    if [[ -e "$_p" ]]; then
      warn_echo "删除子模块目录：$_p"
      rm -rf -- "$_p"
      if [[ -e "$_p" ]]; then
        error_echo "删除失败：$_p"; ((failed++))
      else
        ((removed++))
      fi
    else
      info_echo "目录不存在（跳过）：$_p"
    fi

    # 2) 若索引中存在 gitlink，则清理（避免 'already exists in the index'）
    if git ls-files -s -- "$_p" | awk '$1==160000 {exit 0} {exit 1}'; then
      warn_echo "清理索引 gitlink：$_p"
      git rm -f --cached -- "$_p" >/dev/null 2>&1
      if git ls-files -s -- "$_p" | awk '$1==160000 {exit 0} {exit 1}'; then
        error_echo "索引 gitlink 清理失败：$_p"; ((failed++))
      else
        ((cleared++))
      fi
    fi

    # 3) 可选：删除 .git/modules/<name>，避免后续 re-add 报本地仓库已存在
    if [[ "${PURGE_GIT_MODULES:-0}" == "1" ]]; then
      # 尝试根据 .gitmodules 映射到名字；若无则用路径（Git 常用路径名作为 modules 目录名）
      local name
      name="$(git config -f .gitmodules --get-regexp "^submodule\..*\.path$" 2>/dev/null \
              | awk -v p="$_p" '$2==p{print $1}' \
              | sed -E 's/^submodule\.([^.]*)\.path/\1/' )"
      [[ -z "$name" ]] && name="$_p"
      name="${name#/}"  # 去掉可能的前导斜杠

      if [[ -d ".git/modules/$name" ]]; then
        warn_echo "删除 .git/modules/$name"
        rm -rf -- ".git/modules/$name"
        [[ -d ".git/modules/$name" ]] || ((modules_removed++))
      fi
    fi
  done
  set -e

  success_echo "处理完成：删除目录 $removed/${#uniq_paths[@]}；清理索引 gitlink $cleared 个；.git/modules 清理 $modules_removed 个（受 PURGE_GIT_MODULES 控制）。"
  info_echo "提示：若要重新拉取子模块，可执行：git submodule update --init --recursive"
}

# 4) 确保 .gitmodules 在“当前脚本运行目录”（且该目录就是仓库根）
ensure_gitmodules_here() {
  # 已是 Git 仓库时，校验顶层目录
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local top
    top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "${top:-}" && "$top" != "$PWD" ]]; then
      error_echo "当前目录不是仓库根目录：top-level = $top （.gitmodules 必须在仓库根）"
      exit 1
    fi
  fi

  if [[ ! -e .gitmodules ]]; then
    printf "# Auto-created by script on %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > .gitmodules
    info_echo "已创建空的 .gitmodules 于：$PWD"
  elif [[ -L .gitmodules || -d .gitmodules ]]; then
    local bak=".gitmodules.bak.$(date +%s)"
    mv .gitmodules "$bak"
    printf "# Auto-recreated by script on %s (backup: %s)\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$bak" > .gitmodules
    warn_echo "检测到异常的 .gitmodules（目录/符号链接），已备份为 $bak 并重建为常规文件"
  fi

  git add .gitmodules 2>/dev/null || true
}

# 5) 添加子模块（此时就在拉取远端）
add_submodules() {
  git submodule add -b main https://github.com/295060456/JobsCommand-Flutter.git  ./JobsGenesis@JobsCommand.Flutter
  git submodule add -b main https://github.com/295060456/JobsCommand-iOS.git      ./JobsGenesis@JobsCommand.iOS
  git submodule add -b main https://github.com/295060456/JobsCommand-Gits.git     ./JobsGenesis@JobsCommand.Gits
  git submodule add -b main https://github.com/295060456/JobsCommand-Others.git   ./JobsGenesis@JobsCommand.Others
  git submodule add -b main https://github.com/295060456/JobsSh.git               ./JobsGenesis@JobsSh
}

# 6) 同步子模块记录
sync_submodules() {
  git submodule sync
}

# 7) 提交 .gitmodules 及目录占位
commit_gitmodules_and_dirs() {
  git add .gitmodules */ 2>/dev/null || true
  git commit -m "同步文件" || info_echo "无变更可提交，跳过 commit"
}

# 8) 获取并发数（macOS 优先，用于 submodule --jobs）
get_ncpu() {
  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu
  else
    echo 1
  fi
}

# 9) 首次拉取子模块内容（并发）
submodule_init_update() {
  git submodule update --init --recursive --jobs="$(get_ncpu)"
}

# 10) 让全部子模块按“各自的 branch”前移到远端最新
submodule_ff_remote_merge() {
  git submodule update --remote --merge --recursive --jobs="$(get_ncpu)"
}

# 11) 配置当前 Git 仓库的 remote（交互式，兼容 zsh）
ensure_git_remote() {
  local remote_name="${1:-origin}"
  local remote_url=""

  # 如果已经存在远程仓库，直接提示并返回
  if git remote get-url "$remote_name" >/dev/null 2>&1; then
    info_echo "已存在 git remote [$remote_name] -> $(git remote get-url "$remote_name")"
    return 0
  fi

  while true; do
    # ✅ 在 zsh 里用 read '?prompt:'，在 bash 里用 read -p
    if [ -n "${ZSH_VERSION:-}" ]; then
      read "?请输入Git远程仓库地址: " remote_url
    else
      read -p "请输入Git远程仓库地址: " remote_url
    fi

    if [[ -z "${remote_url:-}" ]]; then
      warn_echo "输入为空，请重新输入"
      continue
    fi

    # 验证远程是否可访问
    if git ls-remote "$remote_url" >/dev/null 2>&1; then
      git remote add "$remote_name" "$remote_url"
      success_echo "已成功配置 git remote [$remote_name] -> $remote_url"
      break
    else
      error_echo "无法访问 $remote_url，请检查地址是否正确"
    fi
  done
}

# 12) 记录子模块新的 SHA 到父仓，并尽量让子模块处于分支 HEAD（避免 detached HEAD）
record_and_normalize_submodules() {
  info_echo "标准化子模块分支并固化 gitlink 到父仓……"

  # 尽量让每个子模块处于 main 分支（若存在）
  git submodule foreach '
    set -e
    # 有 main 分支就切过去并同步
    if git show-ref --verify --quiet refs/heads/main; then
      git checkout main >/dev/null 2>&1 || true
      git pull --ff-only || true
    else
      # 尝试创建 main 跟踪 origin/main
      if git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
        git checkout -B main --track origin/main || true
        git pull --ff-only || true
      fi
    fi
  '

  # 取出所有子模块路径，提交到父仓，使父仓记录最新 gitlink
  local paths
  paths=($(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}'))
  if [[ ${#paths[@]} -gt 0 ]]; then
    git add "${paths[@]}" 2>/dev/null || true
  fi

  git commit -m "chore: bump submodules to latest remote" || info_echo "无子模块前移需要固化，跳过 commit"
  success_echo "子模块最新提交已固化到父仓（若有变更）"
}

# ================================== main（只调用函数） ==================================
main() {
  show_intro_and_wait              # 自述信息 + 等待用户确认
  cd_to_script_dir                 # 切到脚本所在目录
  ensure_repo_initialized          # 初始化父仓（幂等）
  purge_all_submodules             # ✅ 运行前：先删除本文件夹下所有子模块（含索引与 .git/modules）
  ensure_gitmodules_here           # 确保 .gitmodules 在当前目录（且为仓库根），必要时创建/修复
  add_submodules                   # 添加子模块（立即拉取）
  sync_submodules                  # 同步子模块记录
  commit_gitmodules_and_dirs       # 提交 .gitmodules 及目录占位
  submodule_init_update            # 首次拉取子模块内容（并发）
  submodule_ff_remote_merge        # 让全部子模块按“各自的 branch”前移到远端最新
  record_and_normalize_submodules  # ✅ 固化子模块 SHA 到父仓，并尽量在 main 分支上
  ensure_git_remote                # 配置 remote（可交互）
}

main "$@"
