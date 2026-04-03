#!/usr/bin/env bash
# update-state.sh - merge 确认后更新 state 文件中的 commit hash
# 用法: update-state.sh <device_id> <commit_hash>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

DEVICE="$1"
COMMIT="$2"
TODAY=$(date '+%Y-%m-%d')

set_last_pulled_commit "$DEVICE" "$COMMIT" "$TODAY"
ok "已更新 $DEVICE 的 last_pulled_commit → $COMMIT"
