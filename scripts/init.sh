#!/usr/bin/env bash
# init.sh - 初始化记忆同步配置（仓库地址、本地路径）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo ""
echo "════════════════════════════════════════"
echo " Claude Code MemSync 初始化配置"
echo "════════════════════════════════════════"
echo ""

# ── 检查已有配置 ──────────────────────────────────────────────────
if [ -f "$CONFIG_FILE" ]; then
    existing_remote=$(_read_config mem_sync_remote "")
    existing_repo=$(_read_config mem_sync_repo "")
    if [ -n "$existing_remote" ]; then
        info "检测到已有配置："
        info "  远程仓库: $existing_remote"
        info "  本地路径: $existing_repo"
        echo ""
        read -r -p "是否重新配置？[y/N] " redo
        redo="${redo:-N}"
        if [[ ! "$redo" =~ ^[Yy] ]]; then
            ok "使用已有配置，无需重新初始化"
            exit 0
        fi
    fi
fi

# ── 输入仓库地址 ──────────────────────────────────────────────────
echo "请输入你的记忆同步 GitHub 仓库地址（SSH 格式）："
echo "  示例: git@github.com:yourname/my-claude-memory.git"
read -r -p "仓库地址: " new_remote
if [ -z "$new_remote" ]; then
    err "仓库地址不能为空"
    exit 1
fi

default_repo="$HOME/.claude-memory-sync"
read -r -p "本地仓库路径 [回车使用 $default_repo]: " new_repo
new_repo="${new_repo:-$default_repo}"

# ── 写入配置文件 ──────────────────────────────────────────────────
python3 -c "
import json
config = {
    'mem_sync_remote': '$new_remote',
    'mem_sync_repo': '$new_repo'
}
json.dump(config, open('$CONFIG_FILE', 'w'), indent=2)
"
ok "配置已保存 → $CONFIG_FILE"

# ── 初始化本地 Git 仓库 ───────────────────────────────────────────
if [ ! -d "$new_repo/.git" ]; then
    mkdir -p "$new_repo"
    cd "$new_repo"
    git init
    git remote add origin "$new_remote"
    ok "本地仓库已初始化 → $new_repo"
else
    ok "本地仓库已存在，跳过初始化"
fi

echo ""
ok "初始化完成！现在可以使用 /memory-sync:push 和 /memory-sync:pull"
