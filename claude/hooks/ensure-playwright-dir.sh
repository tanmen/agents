#!/bin/bash
# PostToolUse(EnterWorktree) hook: 入った先の worktree に .playwright-mcp/ を先回りで作成する。
# スクリーンショットの配置規約（CLAUDE.md）は .playwright-mcp/ 配下だが、worktree 新規作成
# 直後はディレクトリが存在せず、playwright MCP は mkdir してくれないため保存が ENOENT で
# 失敗する（eromani で 4 worktree ×計6回再発した実績あり）。

input=$(cat)

# hook input の cwd は EnterWorktree 完了後のセッション cwd（＝新しい worktree）。
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  mkdir -p "$cwd/.playwright-mcp" 2>/dev/null
fi

# 保険: cwd が切替前だった場合に備え、tool_response 内の worktree パスにも作成する。
wt=$(printf '%s' "$input" | grep -o '"[^"]*/\.claude/worktrees/[^"]*"' | head -1 | tr -d '"')
if [ -n "$wt" ]; then
  root=${wt%%/.claude/worktrees/*}/.claude/worktrees/$(printf '%s' "${wt#*/.claude/worktrees/}" | cut -d/ -f1)
  [ -d "$root" ] && mkdir -p "$root/.playwright-mcp" 2>/dev/null
fi

exit 0
