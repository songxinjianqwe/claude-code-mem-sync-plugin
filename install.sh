#!/usr/bin/env bash
# install.sh - 安装 memory-sync 插件到 ~/.claude/
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
MEM_SYNC_REPO="${MEM_SYNC_REPO:-$HOME/dev/java/my-claude-code-mem-sharing}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[install]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC}     $*"; }

# ── 1. 安装 slash commands ────────────────────────────────────────
info "安装 slash commands..."
mkdir -p "$CLAUDE_HOME/commands/memory-sync"
cp "$PLUGIN_DIR/commands/memory-sync/push.md" "$CLAUDE_HOME/commands/memory-sync/push.md"
cp "$PLUGIN_DIR/commands/memory-sync/pull.md" "$CLAUDE_HOME/commands/memory-sync/pull.md"
ok "commands 已安装 → $CLAUDE_HOME/commands/memory-sync/"

# ── 2. 初始化记忆同步仓库 ─────────────────────────────────────────
if [ ! -d "$MEM_SYNC_REPO/.git" ]; then
    info "初始化记忆同步仓库: $MEM_SYNC_REPO"
    mkdir -p "$MEM_SYNC_REPO"
    cd "$MEM_SYNC_REPO"
    git init
    git remote add origin git@github.com:songxinjianqwe/my-claude-code-mem-sharing.git
    ok "仓库已初始化"
else
    ok "记忆同步仓库已存在，跳过初始化"
fi

# ── 3. 配置 SessionStart hook ─────────────────────────────────────
SETTINGS_FILE="$CLAUDE_HOME/settings.json"
info "配置 SessionStart hook..."

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

# 用 python3 安全地修改 JSON
python3 - <<PYEOF
import json, os

path = '$SETTINGS_FILE'
with open(path) as f:
    settings = json.load(f)

hook_cmd = "bash $PLUGIN_DIR/scripts/session-start.sh"

hooks = settings.setdefault('hooks', {})
session_start = hooks.setdefault('SessionStart', [])

# 检查是否已存在
already = any(
    h.get('command') == hook_cmd
    for entry in session_start
    for h in entry.get('hooks', [])
)

if not already:
    session_start.append({
        "matcher": "",
        "hooks": [{"type": "command", "command": hook_cmd}]
    })
    with open(path, 'w') as f:
        json.dump(settings, f, indent=2)
    print("SessionStart hook 已添加")
else:
    print("SessionStart hook 已存在，跳过")
PYEOF

ok "SessionStart hook 配置完成"

echo ""
echo "════════════════════════════════════════"
echo " 安装完成！"
echo ""
echo " 可用命令："
echo "   /memory-sync:push  — 推送本地记忆到 GitHub"
echo "   /memory-sync:pull  — 拉取其他设备记忆并合并"
echo "════════════════════════════════════════"
