# /memory-sync:init

初始化记忆同步配置：设置 GitHub 仓库地址和本地路径。

## 用法

```
/memory-sync:init <remote_url> [local_repo_path]
```

- `remote_url`：GitHub 仓库 SSH 地址，如 `git@github.com:yourname/my-claude-memory.git`
- `local_repo_path`（可选）：本地仓库存放路径，默认 `~/.claude-memory-sync`

## 执行步骤

1. 从用户输入中提取 `remote_url` 和可选的 `local_repo_path` 参数。

2. 运行 init 脚本，将参数传入：
   ```bash
   PLUGIN_SCRIPTS=$(find ~/.claude/plugins/cache/claude-code-mem-sync-plugin -name "init.sh" 2>/dev/null | sort -V | tail -1 | xargs dirname) && bash "$PLUGIN_SCRIPTS/init.sh" "<remote_url>" "<local_repo_path>"
   ```

3. 告知用户初始化结果。
