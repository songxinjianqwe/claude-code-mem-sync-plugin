#!/usr/bin/env bash
# init.sh - 初始化记忆同步配置
# 用法: init.sh <remote_url> [local_repo_path]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

NEW_REMOTE="${1:-}"
NEW_REPO="${2:-$HOME/.claude-memory-sync}"

echo ""
echo "════════════════════════════════════════"
echo " Claude Code MemSync 初始化配置"
echo "════════════════════════════════════════"
echo ""

# ── 检查参数 ──────────────────────────────────────────────────────
if [ -z "$NEW_REMOTE" ]; then
    # 已有配置则展示
    if [ -f "$CONFIG_FILE" ]; then
        existing_remote=$(_read_config mem_sync_remote "")
        if [ -n "$existing_remote" ]; then
            ok "已有配置："
            ok "  远程仓库: $existing_remote"
            ok "  本地路径: $(_read_config mem_sync_repo '')"
            echo ""
            echo "如需重新配置，请传入新的仓库地址："
            echo "  /memory-sync:init git@github.com:yourname/your-repo.git [本地路径]"
            exit 0
        fi
    fi
    err "缺少仓库地址参数"
    echo ""
    echo "用法: /memory-sync:init <remote_url> [local_repo_path]"
    echo "示例: /memory-sync:init git@github.com:yourname/my-claude-memory.git"
    exit 1
fi

# ── 写入配置文件 ──────────────────────────────────────────────────
python3 -c "
import json
config = {
    'mem_sync_remote': '$NEW_REMOTE',
    'mem_sync_repo': '$NEW_REPO'
}
json.dump(config, open('$CONFIG_FILE', 'w'), indent=2)
"
ok "配置已保存 → $CONFIG_FILE"
ok "  远程仓库: $NEW_REMOTE"
ok "  本地路径: $NEW_REPO"

# ── 初始化本地 Git 仓库 ───────────────────────────────────────────
if [ ! -d "$NEW_REPO/.git" ]; then
    mkdir -p "$NEW_REPO"
    cd "$NEW_REPO"
    git init
    git remote add origin "$NEW_REMOTE"
    ok "本地仓库已初始化 → $NEW_REPO"
else
    # 检查 remote 是否一致，不一致则更新
    existing_remote=$(cd "$NEW_REPO" && git remote get-url origin 2>/dev/null || echo "")
    if [ "$existing_remote" != "$NEW_REMOTE" ]; then
        cd "$NEW_REPO"
        git remote set-url origin "$NEW_REMOTE"
        ok "已更新远程仓库地址"
    else
        ok "本地仓库已存在，跳过初始化"
    fi
fi

echo ""
ok "初始化完成！现在可以使用 /memory-sync:push 和 /memory-sync:pull"
