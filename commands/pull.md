# /memory-sync:pull

从 GitHub 拉取其他设备的记忆文件，与用户确认后合并到本地。

## 执行步骤

1. 定位插件脚本目录并运行 pull 脚本展示 diff：
   ```bash
   PLUGIN_SCRIPTS=$(find ~/.claude/plugins/cache/claude-code-mem-sync-plugin -name "pull.sh" 2>/dev/null | sort -V | tail -1 | xargs dirname) && bash "$PLUGIN_SCRIPTS/pull.sh"
   ```

2. 读取 `/tmp/memory_sync_diff_*.txt` 中的内容，分析每个设备的变更：
   - 对比对方的 `CLAUDE.md` 与本地 `~/.claude/CLAUDE.md`，找出新增/修改/删除的条目
   - 分析 memory/ 文件，判断每条记忆是否具有通用价值（与项目无关的经验、规范、偏好）

3. 向用户展示合并方案：
   - 列出"建议合并到全局 CLAUDE.md"的条目（去重）
   - 列出"建议忽略"的条目（项目专属内容）
   - 等待用户确认

4. 用户确认后执行合并：
   - 将确认的条目写入 `~/.claude/CLAUDE.md`
   - 对每个设备更新 state 文件：
     ```bash
     PLUGIN_SCRIPTS=$(find ~/.claude/plugins/cache/claude-code-mem-sync-plugin -name "update-state.sh" 2>/dev/null | sort -V | tail -1 | xargs dirname) && bash "$PLUGIN_SCRIPTS/update-state.sh" <device_id> <commit_hash>
     ```
   - 清理临时文件：`rm -f /tmp/memory_sync_diff_*.txt /tmp/memory_sync_pending_commits.txt`

5. 告知用户合并完成情况。
