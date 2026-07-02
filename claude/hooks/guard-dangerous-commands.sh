#!/bin/bash
# PreToolUse(Bash) hook: 危険コマンドのガード。
#
# - force push → deny。settings.json の deny ルール（prefix / glob 一致）は
#   分解できない複合コマンド（sh -c '...' や xargs 経由など）を取りこぼし得る
#   ため、コマンド文字列全体への文中一致で補完する。--force-with-lease は
#   regex にマッチしないので通る（allow ルールとも整合）。
# - rm -rf → ask。ビルド成果物の掃除（rm -rf out 等）のような正当な用途が
#   実際にあるため、ハード deny せずユーザー確認に落とす。prefix 一致の
#   ask ルール (rm -r*) が届かない位置（パイプ・xargs の後段など）でも
#   最低限 ask になることを保証する。

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push([[:space:]]+[^[:space:]]+)*[[:space:]]+(--force([[:space:]]|$)|-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$))'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:"git push --force / -f は禁止しています（必要なら --force-with-lease を使う）"}}'
  exit 0
fi

if printf '%s' "$cmd" | grep -qE '(^|[[:space:];|&])rm[[:space:]]+-[a-zA-Z]*(r[a-zA-Z]*f|f[a-zA-Z]*r)[a-zA-Z]*([[:space:]]|$)'; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:"rm -rf を含むコマンドです。削除対象のパスを確認してください"}}'
  exit 0
fi

exit 0
