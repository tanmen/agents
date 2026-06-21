# agents

Claude Code のグローバル設定（`~/.claude/`）を version 管理するための個人 dotfiles リポジトリ。
特定プロジェクトに紐づかない CLAUDE.md・設定・スラッシュコマンド・サブエージェント・skill をここで一元管理し、
**symlink でこのリポジトリを正（source of truth）として** `~/.claude/` に反映する。

## 構成

```
claude/                       # ~/.claude/ にミラーされる中身
  CLAUDE.md                   # グローバル指示（全プロジェクト共通）
  settings.json               # 権限 / テーマ / effortLevel など（マシン固有パスは含めない）
  statusline-command.sh       # ステータスライン表示スクリプト
  commands/                   # カスタムスラッシュコマンド（commit, sync-main）
  agents/                     # カスタムサブエージェント（config-improver, project-modernizer）
  skills/                     # 自作の UX/レビュー系 skill（計10）
install.sh                    # claude/ を ~/.claude/ に symlink する冪等インストーラ
```

### 管理対象外（あえて入れていない）

- **プラグイン / marketplace 由来の skill**: `claude` のプラグイン機構で再インストールできるものは追跡しない。
  - `frontend-design` / `stripe`: 公式 marketplace の plugin。
  - Cloudflare 系（`cloudflare` / `wrangler` / `durable-objects` / `agents-sdk` /
    `cloudflare-email-service` / `sandbox-sdk` / `turnstile-spin` / `web-perf` /
    `workers-best-practices`）: 公式 marketplace の `cloudflare@claude-plugins-official`
    （出所 `github.com/cloudflare/skills`）でまとめて入る。新マシンでは
    `claude plugin install cloudflare@claude-plugins-official` で導入する。
- **マシン固有 / 機微なファイル**: `history.jsonl`・`sessions/`・`projects/`・`plugins/cache/` など `~/.claude/` 配下の動的データ。
- **マシン固有パス**: `settings.json` の `CLAUDE_CODE_TMPDIR`（任意なので削除。既定はシステム一時dir）と
  ステータスラインのパスは `~`（シェル展開）で記述しポータブルにしてある。env 値は変数展開されないため、
  どうしてもマシン別の tmpdir が必要なら settings.json ではなくシェルの profile で
  `export CLAUDE_CODE_TMPDIR=...` する。

## 使い方

### 新しいマシンでセットアップ

```sh
git clone git@github.com:tanmen/agents.git ~/Projects/agents
~/Projects/agents/install.sh
```

`install.sh` は `claude/` の各項目を `~/.claude/` 配下に symlink する。
既に実体ファイルがある場合は `~/.claude-config-backup-<timestamp>/` に退避してから張り直すので、上書き事故は起きない。冪等なので再実行も安全。

### 編集フロー

このリポジトリが正。`~/.claude/CLAUDE.md` などは `claude/` 配下への symlink なので、
**どちらを編集しても同じ実体**。変更したら通常どおり commit する。

```sh
cd ~/Projects/agents
# claude/ 配下を編集
git add -A && git commit
```

### skill / command / agent を追加したとき

`claude/skills/<name>/`（または `commands/`・`agents/`）に追加してから `install.sh` を再実行すると、
新規項目ぶんの symlink が `~/.claude/` に張られる。
