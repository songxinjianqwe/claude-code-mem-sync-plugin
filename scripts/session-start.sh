#!/usr/bin/env bash
# session-start.sh - SessionStart hook 脚本
# 1. 异步 push 本地记忆（每天只跑一次）
# 2. 检测其他设备是否有新内容，有则提示

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TODAY=$(date '+%Y-%m-%d')
LAST_PUSH_DATE=$(get_last_sync_date)

# ── 异步 push（每天首次）─────────────────────────────────────────
if [ "$LAST_PUSH_DATE" != "$TODAY" ]; then
    nohup bash "$SCRIPT_DIR/push.sh" >> /tmp/memory-sync-push.log 2>&1 &
    # 不等待，继续往下走
fi

# ── 检测其他设备是否有新内容 ─────────────────────────────────────
if [ ! -d "$MEM_SYNC_REPO/.git" ]; then
    exit 0
fi

cd "$MEM_SYNC_REPO"
git fetch origin --quiet 2>/dev/null || exit 0

HAS_NEW=0
NEW_DEVICES=()

while IFS= read -r branch; do
    branch=$(echo "$branch" | sed 's|origin/||' | xargs)
    if [ "$branch" = "$DEVICE_BRANCH" ] || [[ "$branch" != device/* ]]; then
        continue
    fi

    other_device=$(echo "$branch" | sed 's|device/||')
    last_commit=$(get_last_pulled_commit "$other_device")
    latest_commit=$(git rev-parse "origin/$branch" 2>/dev/null || echo "")

    if [ -z "$latest_commit" ]; then
        continue
    fi

    if [ -z "$last_commit" ] || [ "$last_commit" != "$latest_commit" ]; then
        HAS_NEW=1
        NEW_DEVICES+=("$other_device")
    fi
done < <(git branch -r | grep "origin/device/")

if [ $HAS_NEW -eq 1 ]; then
    echo ""
    echo "💡 检测到以下设备有新的记忆内容：${NEW_DEVICES[*]}"
    echo "   运行 /memory-sync:pull 进行合并"
    echo ""
fi
