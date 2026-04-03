# Claude Code MemSync Plugin

在多台设备之间同步 Claude Code 的记忆文件（CLAUDE.md、memory/）。

## 工作原理

- 每台设备在 GitHub 仓库中维护自己的独立分支（`device/<hostname>_<subnet>`）
- push 时只 force push 自己的分支，不影响其他设备
- pull 时读取其他设备的分支，用 AI 判断哪些内容值得合并到全局 CLAUDE.md
- 增量合并：记录每次 pull 的 commit hash，下次只看新增的 diff

## 同步内容

- `~/.claude/CLAUDE.md` — 全局规则
- `~/.claude/projects/*/memory/` — 各项目的记忆文件
- `<project>/CLAUDE.md` — 各项目的规则文件

## 安装

```bash
git clone git@github.com:songxinjianqwe/claude-code-mem-sync-plugin.git ~/dev/java/claude-code-mem-sync-plugin
bash ~/dev/java/claude-code-mem-sync-plugin/install.sh
```

## 使用

| 命令 | 说明 |
|------|------|
| `/memory-sync:push` | 推送本地记忆到 GitHub |
| `/memory-sync:pull` | 拉取其他设备记忆，AI 分析后与你确认合并 |

SessionStart hook 每天首次开会话时自动：
1. 后台异步 push 本地记忆
2. 检测其他设备是否有新内容，有则提示你运行 `/memory-sync:pull`

## 要求

- macOS / Linux
- Git + SSH 已配置（能访问 GitHub）
- Python 3（用于解析 JSON state 文件）
