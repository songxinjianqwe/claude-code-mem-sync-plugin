#!/usr/bin/env bash
# common.sh - 公共函数和配置

# ── 路径配置 ──────────────────────────────────────────────────────
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
GLOBAL_CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
PROJECTS_DIR="$CLAUDE_HOME/projects"
STATE_FILE="$CLAUDE_HOME/memory-sync-state.json"
CONFIG_FILE="$CLAUDE_HOME/memory-sync-config.json"

# 从配置文件读取仓库设置（环境变量可覆盖）
_read_config() {
    local key="$1"
    local default="$2"
    if [ -f "$CONFIG_FILE" ]; then
        python3 -c "
import json
try:
    d = json.load(open('$CONFIG_FILE'))
    print(d.get('$key', '$default'))
except:
    print('$default')
" 2>/dev/null
    else
        echo "$default"
    fi
}

# 记忆同步本地仓库路径
MEM_SYNC_REPO="${MEM_SYNC_REPO:-$(_read_config mem_sync_repo "$HOME/dev/java/my-claude-code-mem-sharing")}"
# 远程 GitHub 仓库地址（SSH）
MEM_SYNC_REMOTE="${MEM_SYNC_REMOTE:-$(_read_config mem_sync_remote "")}"

# ── 设备标识 ──────────────────────────────────────────────────────
get_device_id() {
    local hostname
    hostname=$(hostname -s 2>/dev/null || hostname)

    # 取硬件 UUID 前 8 位作为设备唯一标识（macOS）
    local hw_id
    hw_id=$(system_profiler SPHardwareDataType 2>/dev/null | awk '/Hardware UUID/{print $3}' | cut -c1-8)

    # Linux fallback: 用 machine-id
    if [ -z "$hw_id" ]; then
        hw_id=$(cat /etc/machine-id 2>/dev/null | cut -c1-8)
    fi

    if [ -z "$hw_id" ]; then
        hw_id="unknown"
    fi

    echo "${hostname}_${hw_id}"
}

DEVICE_ID=$(get_device_id)
DEVICE_BRANCH="device/${DEVICE_ID}"

# ── state 文件操作 ────────────────────────────────────────────────
get_last_pulled_commit() {
    local device="$1"
    if [ ! -f "$STATE_FILE" ]; then
        echo ""
        return
    fi
    # 用 python3 解析 JSON（避免依赖 jq）
    python3 -c "
import json, sys
try:
    d = json.load(open('$STATE_FILE'))
    print(d.get('$device', {}).get('last_pulled_commit', ''))
except:
    print('')
" 2>/dev/null
}

set_last_pulled_commit() {
    local device="$1"
    local commit="$2"
    local today="$3"
    python3 -c "
import json, os
path = '$STATE_FILE'
try:
    d = json.load(open(path)) if os.path.exists(path) else {}
except:
    d = {}
if '$device' not in d:
    d['$device'] = {}
d['$device']['last_pulled_commit'] = '$commit'
d['$device']['last_pulled_date'] = '$today'
json.dump(d, open(path, 'w'), indent=2)
" 2>/dev/null
}

get_last_sync_date() {
    if [ ! -f "$STATE_FILE" ]; then
        echo ""
        return
    fi
    python3 -c "
import json
try:
    d = json.load(open('$STATE_FILE'))
    print(d.get('last_push_date', ''))
except:
    print('')
" 2>/dev/null
}

set_last_push_date() {
    local today="$1"
    python3 -c "
import json, os
path = '$STATE_FILE'
try:
    d = json.load(open(path)) if os.path.exists(path) else {}
except:
    d = {}
d['last_push_date'] = '$today'
json.dump(d, open(path, 'w'), indent=2)
" 2>/dev/null
}

# ── 颜色输出 ──────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[sync]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}   $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
err()   { echo -e "${RED}[err]${NC}  $*"; }
