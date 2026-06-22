#!/bin/bash
# 清理无远程分支的本地分支及其 worktree
# 用法: ./cleanup_orphan_branches.sh [仓库路径]

set -e

REPO_PATH="${1:-.}"
cd "$REPO_PATH"
REPO_NAME=$(basename "$(pwd)")

echo "========================================"
echo "仓库: $REPO_NAME"
echo "========================================"

# 获取当前分支，确保最后切回来（如果需要）
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# 建立分支->worktree映射
: >/tmp/wt_map.txt
git worktree list --porcelain | awk '
  /^worktree / { path = substr($0, 10) }
  /^branch refs\/heads\// {
    branch = $0
    sub(/^branch refs\/heads\//, "", branch)
    print branch "|" path
  }
' >/tmp/wt_map.txt

# 收集需要删除的分支
ORPHAN_BRANCHES=()
echo "检查本地分支状态..."
echo ""
while IFS='|' read -r branch upstream track; do
  if [ -z "$upstream" ] && [ -z "$track" ]; then
    echo "  ✓ $branch - 无上游分支，待清理"
    ORPHAN_BRANCHES+=("$branch")
  elif [ "$track" = "[gone]" ]; then
    echo "  ✓ $branch - 远程分支已删除，待清理"
    ORPHAN_BRANCHES+=("$branch")
  elif [ -n "$upstream" ]; then
    # 检查分支名是否与上游分支名匹配
    upstream_branch="${upstream#origin/}"
    if [ "$branch" != "$upstream_branch" ]; then
      echo "  ○ $branch -> $upstream ($track) - 追踪其他分支，可能已完成"
    else
      echo "  · $branch -> $upstream ($track) - 正常"
    fi
  else
    echo "  · $branch - 正常"
  fi
done < <(git for-each-ref --format='%(refname:short)|%(upstream:short)|%(upstream:track)' refs/heads/)
echo ""

if [ ${#ORPHAN_BRANCHES[@]} -eq 0 ]; then
  echo "没有需要清理的无远程分支的本地分支。"
  echo ""
  echo "提示: 如果有分支追踪 origin/master 但远程已无对应分支，"
  echo "      这些可能是已合并的 feature 分支，可手动检查删除。"
  echo ""
  exit 0
fi

echo "发现 ${#ORPHAN_BRANCHES[@]} 个需要删除的分支:"
for branch in "${ORPHAN_BRANCHES[@]}"; do
  echo "  - $branch"
done

echo ""
read -r -p "确认删除以上分支及其 worktree 吗？[y/N] " confirm
echo ""
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "已取消清理。"
  exit 0
fi

# 先切换到 master/main 分支（如果当前在待删除分支上）
if printf '%s\n' "${ORPHAN_BRANCHES[@]}" | grep -qx "$CURRENT_BRANCH"; then
  # 尝试切换到 master，如果不存在则尝试 main
  if git show-ref --verify --quiet refs/heads/master; then
    git checkout master >/dev/null 2>&1
    echo "已切换到 master 分支以释放当前分支。"
  elif git show-ref --verify --quiet refs/heads/main; then
    git checkout main >/dev/null 2>&1
    echo "已切换到 main 分支以释放当前分支。"
  else
    echo "警告: 当前在待删除分支 $CURRENT_BRANCH 上，但未找到 master/main 分支。跳过删除当前分支。"
  fi
fi

# 删除分支及其 worktree
for branch in "${ORPHAN_BRANCHES[@]}"; do
  # 检查是否有 worktree
  wt_path=$(awk -F'|' -v b="$branch" '$1==b {print $2}' /tmp/wt_map.txt)

  if [ -n "$wt_path" ]; then
    echo "删除 worktree: $wt_path (分支: $branch)"
    # 如果 worktree 路径仍然存在，尝试移除
    if [ -d "$wt_path" ]; then
      git worktree remove -f "$wt_path" 2>/dev/null || {
        echo "  git worktree remove 失败，尝试强制删除目录..."
        rm -rf "$wt_path"
        git worktree prune
      }
    else
      echo "  worktree 目录已不存在，执行 prune..."
      git worktree prune
    fi
  fi

  # 如果分支仍然存在则删除
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "删除本地分支: $branch"
    git branch -D "$branch"
  fi
done

echo ""
