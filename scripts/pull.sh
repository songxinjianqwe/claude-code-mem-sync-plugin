#!/usr/bin/env bash
# pull.sh - 从其他设备分支拉取记忆文件并展示 diff，等待用户确认后 merge
# 注意：实际的 AI merge 由 Claude 执行，本脚本只负责展示 diff 内容
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ ! -d "$MEM_SYNC_REPO/.git" ]; then
    err "记忆同步仓库不存在: $MEM_SYNC_REPO"
    exit 1
fi

cd "$MEM_SYNC_REPO"

info "设备标识: $DEVICE_ID"
info "正在 fetch 远程分支..."
git fetch origin 2>/dev/null || { err "fetch 失败，请检查网络和 SSH 配置"; exit 1; }

# ── 找出所有非本设备的分支 ────────────────────────────────────────
OTHER_BRANCHES=()
while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's|origin/||' | xargs)
    if [ "$branch" != "$DEVICE_BRANCH" ] && [[ "$branch" == device/* ]]; then
        OTHER_BRANCHES+=("$branch")
    fi
done < <(git branch -r | grep "origin/device/")

if [ ${#OTHER_BRANCHES[@]} -eq 0 ]; then
    info "没有发现其他设备的分支，无需 merge"
    exit 0
fi

info "发现 ${#OTHER_BRANCHES[@]} 个其他设备: ${OTHER_BRANCHES[*]}"
echo ""

TODAY=$(date '+%Y-%m-%d')
HAS_DIFF=0

# ── 逐设备展示 diff ───────────────────────────────────────────────
for branch in "${OTHER_BRANCHES[@]}"; do
    other_device=$(echo "$branch" | sed 's|device/||')
    last_commit=$(get_last_pulled_commit "$other_device")
    latest_commit=$(git rev-parse "origin/$branch" 2>/dev/null || echo "")

    if [ -z "$latest_commit" ]; then
        warn "分支 $branch 无法获取最新 commit，跳过"
        continue
    fi

    echo "════════════════════════════════════════"
    echo "  设备: $other_device"
    echo "════════════════════════════════════════"

    if [ -z "$last_commit" ]; then
        info "首次合并，展示全量内容"
        # 全量展示该设备目录下的文件列表
        git show "origin/$branch:$other_device/" 2>/dev/null || \
            git ls-tree -r --name-only "origin/$branch" | grep "^$other_device/" | head -50
        echo ""
        # 展示全局 CLAUDE.md 内容
        echo "--- 对方的全局 CLAUDE.md ---"
        git show "origin/$branch:$other_device/CLAUDE.md" 2>/dev/null || echo "(无)"
        echo ""
        # 展示 memory 文件列表
        echo "--- 对方的 memory 文件 ---"
        git ls-tree -r --name-only "origin/$branch" | grep "memory/" | head -30
        echo ""
    elif [ "$last_commit" = "$latest_commit" ]; then
        ok "无新变更，跳过"
        echo ""
        continue
    else
        info "增量 diff: $last_commit → $latest_commit"
        git diff "$last_commit" "origin/$branch" -- "$other_device/" 2>/dev/null || \
            git diff "$last_commit".."origin/$branch" 2>/dev/null | head -300
        echo ""
    fi

    HAS_DIFF=1

    # 写入临时文件供 Claude 读取
    DIFF_FILE="/tmp/memory_sync_diff_${other_device}.txt"
    if [ -z "$last_commit" ]; then
        git show "origin/$branch:$other_device/CLAUDE.md" > "$DIFF_FILE" 2>/dev/null || echo "" > "$DIFF_FILE"
        # 追加所有 memory 文件内容
        while IFS= read -r f; do
            echo "" >> "$DIFF_FILE"
            echo "=== $f ===" >> "$DIFF_FILE"
            git show "origin/$branch:$f" >> "$DIFF_FILE" 2>/dev/null || true
        done < <(git ls-tree -r --name-only "origin/$branch" | grep "memory/")
    else
        git diff "$last_commit".."origin/$branch" > "$DIFF_FILE" 2>/dev/null || echo "" > "$DIFF_FILE"
    fi

    # 记录待更新的 commit（交给 Claude 确认后调用 update-state.sh 更新）
    echo "$other_device $latest_commit $TODAY" >> /tmp/memory_sync_pending_commits.txt

done

if [ $HAS_DIFF -eq 0 ]; then
    ok "所有设备均无新变更"
    exit 0
fi

echo ""
echo "════════════════════════════════════════"
echo " diff 已展示完毕，diff 文件保存在 /tmp/memory_sync_diff_*.txt"
echo " 请由 Claude 分析上述内容并与用户确认 merge 方案"
echo "════════════════════════════════════════"
