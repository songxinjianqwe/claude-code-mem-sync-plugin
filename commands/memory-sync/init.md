# /memory-sync:init

初始化记忆同步配置：设置 GitHub 仓库地址和本地路径。

## 执行步骤

1. 运行 init 脚本：
   ```bash
   PLUGIN_SCRIPTS=$(find ~/.claude/plugins/cache/claude-code-mem-sync-plugin -name "init.sh" 2>/dev/null | sort -V | tail -1 | xargs dirname) && bash "$PLUGIN_SCRIPTS/init.sh"
   ```

2. 告知用户初始化结果。
