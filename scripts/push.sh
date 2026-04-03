#!/usr/bin/env bash
# push.sh - 将本地记忆文件推送到远程仓库的当前设备分支
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

info "设备标识: $DEVICE_ID"
info "目标分支: $DEVICE_BRANCH"

# ── 检查是否已初始化 ──────────────────────────────────────────────
if [ ! -f "$CONFIG_FILE" ] || [ -z "$MEM_SYNC_REMOTE" ]; then
    err "尚未初始化，请先运行 /memory-sync:init 完成配置"
    exit 1
fi

# ── 确保仓库存在 ──────────────────────────────────────────────────
if [ ! -d "$MEM_SYNC_REPO/.git" ]; then
    err "记忆同步仓库不存在: $MEM_SYNC_REPO"
    err "请先运行 /memory-sync:init 初始化仓库"
    exit 1
fi

cd "$MEM_SYNC_REPO"

# ── 切到设备分支（没有就新建）────────────────────────────────────
git fetch origin 2>/dev/null || true
if git ls-remote --exit-code --heads origin "$DEVICE_BRANCH" &>/dev/null; then
    git checkout "$DEVICE_BRANCH" 2>/dev/null || git checkout -B "$DEVICE_BRANCH" "origin/$DEVICE_BRANCH"
else
    git checkout -B "$DEVICE_BRANCH"
fi

# ── 复制记忆文件到仓库 ────────────────────────────────────────────
DEVICE_DIR="$MEM_SYNC_REPO/$DEVICE_ID"
mkdir -p "$DEVICE_DIR/projects"

# 1. 全局 CLAUDE.md
if [ -f "$GLOBAL_CLAUDE_MD" ]; then
    cp "$GLOBAL_CLAUDE_MD" "$DEVICE_DIR/CLAUDE.md"
    ok "已复制全局 CLAUDE.md"
fi

# 2. 各项目下的 CLAUDE.md 和 memory/
if [ -d "$PROJECTS_DIR" ]; then
    for project_dir in "$PROJECTS_DIR"/*/; do
        project_name=$(basename "$project_dir")
        copied=0

        # 项目下的 CLAUDE.md（从项目实际路径推导）
        # project_name 形如 -Users-songxinjian-dev-java-my-ai-playground
        actual_path=$(echo "$project_name" | sed 's|^-||' | tr '-' '/')
        project_claude_md="/$actual_path/CLAUDE.md"
        if [ -f "$project_claude_md" ]; then
            mkdir -p "$DEVICE_DIR/projects/$project_name"
            cp "$project_claude_md" "$DEVICE_DIR/projects/$project_name/CLAUDE.md"
            copied=$((copied + 1))
        fi

        # 项目下的 memory/ 目录
        memory_dir="$project_dir/memory"
        if [ -d "$memory_dir" ]; then
            mkdir -p "$DEVICE_DIR/projects/$project_name/memory"
            cp -r "$memory_dir/." "$DEVICE_DIR/projects/$project_name/memory/"
            copied=$((copied + 1))
        fi

        if [ $copied -gt 0 ]; then
            ok "已复制项目: $project_name"
        fi
    done
fi

# ── 提交并推送 ────────────────────────────────────────────────────
git add -A

if git diff --cached --quiet; then
    ok "没有变更，跳过推送"
    exit 0
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "sync: $DEVICE_ID @ $TIMESTAMP"
git push -f origin "$DEVICE_BRANCH"

TODAY=$(date '+%Y-%m-%d')
set_last_push_date "$TODAY"

ok "推送完成 → $DEVICE_BRANCH"
