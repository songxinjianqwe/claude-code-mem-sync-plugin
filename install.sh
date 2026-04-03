#!/usr/bin/env bash
# install.sh - 安装 memory-sync 插件到 ~/.claude/
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
CONFIG_FILE="$CLAUDE_HOME/memory-sync-config.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[install]${NC} $*"; }
ok()   { echo -e "${GREEN}[ok]${NC}     $*"; }

# ── 1. 读取或配置仓库设置 ─────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo " Claude Code MemSync Plugin 安装"
echo "════════════════════════════════════════"
echo ""

if [ -f "$CONFIG_FILE" ]; then
    existing_remote=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('mem_sync_remote',''))" 2>/dev/null)
    existing_repo=$(python3 -c "import json; d=json.load(open('$CONFIG_FILE')); print(d.get('mem_sync_repo',''))" 2>/dev/null)
    info "检测到已有配置："
    info "  远程仓库: $existing_remote"
    info "  本地路径: $existing_repo"
    echo ""
    read -r -p "是否使用已有配置？[Y/n] " use_existing
    use_existing="${use_existing:-Y}"
    if [[ "$use_existing" =~ ^[Nn] ]]; then
        existing_remote=""
        existing_repo=""
    fi
fi

if [ -z "${existing_remote:-}" ]; then
    echo "请输入你的记忆同步 GitHub 仓库地址（SSH 格式）："
    echo "  示例: git@github.com:yourname/my-claude-memory.git"
    read -r -p "仓库地址: " MEM_SYNC_REMOTE
    if [ -z "$MEM_SYNC_REMOTE" ]; then
        echo "错误: 仓库地址不能为空"
        exit 1
    fi

    default_repo="$HOME/dev/java/my-claude-memory"
    read -r -p "本地仓库路径 [回车使用 $default_repo]: " MEM_SYNC_REPO
    MEM_SYNC_REPO="${MEM_SYNC_REPO:-$default_repo}"

    # 写入配置文件
    python3 -c "
import json
config = {
    'mem_sync_remote': '$MEM_SYNC_REMOTE',
    'mem_sync_repo': '$MEM_SYNC_REPO'
}
json.dump(config, open('$CONFIG_FILE', 'w'), indent=2)
print('配置已保存')
"
    ok "配置已写入 $CONFIG_FILE"
else
    MEM_SYNC_REMOTE="$existing_remote"
    MEM_SYNC_REPO="$existing_repo"
fi

echo ""

# ── 2. 安装 slash commands ────────────────────────────────────────
info "安装 slash commands..."
mkdir -p "$CLAUDE_HOME/commands/memory-sync"
cp "$PLUGIN_DIR/commands/memory-sync/push.md" "$CLAUDE_HOME/commands/memory-sync/push.md"
cp "$PLUGIN_DIR/commands/memory-sync/pull.md" "$CLAUDE_HOME/commands/memory-sync/pull.md"
ok "commands 已安装 → $CLAUDE_HOME/commands/memory-sync/"

# ── 3. 初始化记忆同步仓库 ─────────────────────────────────────────
if [ ! -d "$MEM_SYNC_REPO/.git" ]; then
    info "初始化记忆同步仓库: $MEM_SYNC_REPO"
    mkdir -p "$MEM_SYNC_REPO"
    cd "$MEM_SYNC_REPO"
    git init
    git remote add origin "$MEM_SYNC_REMOTE"
    ok "仓库已初始化 → $MEM_SYNC_REPO"
else
    ok "记忆同步仓库已存在，跳过初始化"
fi

# ── 4. 配置 SessionStart hook ─────────────────────────────────────
SETTINGS_FILE="$CLAUDE_HOME/settings.json"
info "配置 SessionStart hook..."

if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

python3 - <<PYEOF
import json

path = '$SETTINGS_FILE'
with open(path) as f:
    settings = json.load(f)

hook_cmd = "bash $PLUGIN_DIR/scripts/session-start.sh"

hooks = settings.setdefault('hooks', {})
session_start = hooks.setdefault('SessionStart', [])

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
