#!/bin/bash
# Stop hook: 作業終了時、未コミットの変更があれば Claude に /commit を実行させる。
# 変更が無いターン（純粋な Q&A など）では何もしない。
# stop_hook_active=true（commit 実行後の再停止）はそのまま許可し、無限ループを防ぐ。
#
# dirty 判定は hook input の cwd（セッションが実際に作業している場所）が属する
# git repo に対して行う。CLAUDE_PROJECT_DIR 固定だと、worktree で作業する
# セッションが main checkout の（他セッション由来の）dirt を拾って誤検知するため。
#
# 再発火抑制: 前回 block した時と working tree の状態が同一なら再 block しない。
# /commit が意図的に残した out-of-scope の dirt（未追跡ファイル等）で、以降の
# 全ターンの Stop がブロックされ続けるのを防ぐ。
#
# 読み取り専用セッション抑制: transcript にファイル変更ツール（Write / Edit /
# NotebookEdit、サブエージェント含む）の使用が無ければ block しない。調査 / Q&A
# セッションが他セッション由来の dirt（意図的に残した WIP 等）で /commit を
# 催促されるのを防ぐ。Bash リダイレクト等による書き込みは検出できないが許容する。

input=$(cat)

# すでにこの Stop hook 起因で継続中なら、停止を許可してループを断つ。
if printf '%s' "$input" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
  exit 0
fi

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)

cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || exit 0

# git リポジトリ外、または未コミット変更が無ければ何もしない。
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
status=$(git status --porcelain 2>/dev/null)
[ -n "$status" ] || exit 0

# このセッションがファイル変更ツールを一度も使っていなければ block しない。
# tool_use ブロックの生の JSON 列にだけマッチさせる（会話本文中の言及は
# JSON エスケープされて "\"name\"..." になるため誤検知しない）。
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  mutation_pattern='"type":"tool_use","id":"[^"]*","name":"(Write|Edit|NotebookEdit)"'
  mutated=0
  if grep -qE "$mutation_pattern" "$transcript" 2>/dev/null; then
    mutated=1
  else
    for agent_transcript in "${transcript%.jsonl}"/subagents/*.jsonl; do
      [ -f "$agent_transcript" ] || continue
      if grep -qE "$mutation_pattern" "$agent_transcript" 2>/dev/null; then
        mutated=1
        break
      fi
    done
  fi
  [ "$mutated" = 1 ] || exit 0
fi

# 前回 block 時と同一状態なら再 block しない（repo が変われば hash も変わる）。
toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
state_file="${TMPDIR:-/tmp}/claude-commit-on-stop-${session_id}"
state_hash=$(printf '%s\n%s' "$toplevel" "$status" | shasum | cut -d' ' -f1)
if [ -f "$state_file" ] && [ "$(cat "$state_file" 2>/dev/null)" = "$state_hash" ]; then
  exit 0
fi
printf '%s' "$state_hash" >"$state_file" 2>/dev/null

# 停止をブロックし /commit を実行させる。
printf '%s' '{"decision":"block","reason":"未コミットの変更があります。/commit スキルを使って、トピックごとに分割しつつ作業内容をコミットしてください。完了したらそのまま終了して構いません（push / PR は /commit の手順に従う）。"}'
exit 0
