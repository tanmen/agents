#!/bin/bash
# SessionEnd hook: セッション終了時、いた場所が .claude/worktrees/ 配下の git worktree なら削除する。
# 安全設計:
#   - --force は付けない → 未コミット変更・未追跡ファイルがあれば git worktree remove が拒否し、worktree はそのまま残る（作業ロスト防止）。
#   - /clear・/resume では削除しない（セッションは継続/切替のため）。
#   - 削除対象から cd で抜けてから実行。失敗時は何もせず終了（残った worktree は `git worktree list` で確認して手動で片付ける）。

input=$(cat)

reason=$(printf '%s' "$input" | jq -r '.reason // "other"' 2>/dev/null)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)

# セッションが真に終了するときだけ掃除する（clear/resume は対象外）。
case "$reason" in
  logout | prompt_input_exit | other) ;;
  *) exit 0 ;;
esac

[ -n "$cwd" ] || exit 0
case "$cwd" in
  */.claude/worktrees/*) ;;
  *) exit 0 ;;
esac

# cwd が属する worktree のトップと、元リポジトリのルートを求める。
wt_top=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
case "$wt_top" in
  */.claude/worktrees/*) ;;
  *) exit 0 ;;
esac
main_root=${wt_top%%/.claude/worktrees/*}
[ -d "$main_root" ] || exit 0

# 削除対象を cwd に握ったままだと消せないので、元リポジトリへ移動してから安全削除。
cd "$main_root" 2>/dev/null || exit 0
git -C "$main_root" worktree remove "$wt_top" >/dev/null 2>&1 || true
exit 0
