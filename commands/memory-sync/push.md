# /memory-sync:push

将本地所有记忆文件推送到 GitHub 远程仓库的当前设备分支。

## 执行步骤

1. 运行 push 脚本：
   ```bash
   PLUGIN_SCRIPTS=$(find ~/.claude/plugins/cache/claude-code-mem-sync-plugin -name "push.sh" 2>/dev/null | sort -V | tail -1 | xargs dirname) && bash "$PLUGIN_SCRIPTS/push.sh"
   ```

2. 告知用户推送结果（成功/失败/无变更）。
