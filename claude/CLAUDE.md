# この設定の実体（symlink 構成）

`~/.claude/` 直下の `CLAUDE.md` / `settings.json` / `statusline-command.sh`、および `commands/` `agents/` `skills/` `hooks/` `rules/` 配下の各項目は、`~/Projects/agents/claude/` への symlink（`install.sh` が張る）。**編集するときは実体 `~/Projects/agents/claude/...` を直接編集する**（symlink 経由の Write は拒否されることがある）。hook / rule / command を新規追加するときも agents リポジトリ側に置き、`install.sh` を再実行するか同形式の symlink を張る。

# 言語設定

ユーザーへの応答は常に日本語で行うこと。コード内のコメントや識別子はプロジェクトの慣習に従い、必要に応じて英語のままで構わない。

# パッケージマネージャ

Node.js プロジェクトのセットアップ・依存追加・スクリプト実行・単発ツール実行は **基本的に pnpm を使う**（`npm` / `yarn` ではなく `pnpm install` / `pnpm add` / `pnpm run` / `pnpm dlx`）。新規プロジェクトの初期化も pnpm を前提にする。

ただし、対象プロジェクトが既に別のパッケージマネージャを採用している場合（`package-lock.json` / `yarn.lock` / `bun.lockb` の存在、`package.json` の `packageManager` フィールド、project の CLAUDE.md の明示など）は **そのプロジェクトの方式を優先**する。lockfile が混在する事故を避けるため、既存リポジトリで断りなく pnpm に乗り換えない。

# 作業ブランチの起点

新しい作業（feature / fix の実装など、コード変更を伴うもの）を始めるときは、必ず **upstream の最新を起点**にする。古い base から派生したまま実装を始めて、後から大きな rebase / conflict が出るのを避けるため。

- 作業ブランチを切る前に default branch（`main`、なければ `develop` / `master`）を `git fetch` し、その**最新コミットから**新しいブランチを生やす。ブランチ作成を伴うときは `/branch` skill を優先して使う（upstream の default branch から生やす挙動）。
- default branch に checkout してから作業を始める場合は、**checkout 後に必ず `git pull`（fast-forward）して local を upstream の最新に追従させてから**ブランチを切る／作業する。local の `main`/`develop` が古いまま派生すると、結局同じ rebase / conflict 問題が起きるため。
- default branch の名前はプロジェクトごとに違う。`git remote show origin` の HEAD 等で確認し、`develop` 運用のリポジトリでは develop を起点にする。
- すでに古い branch 上にいる／現在の作業が古い base から派生している場合は、`sync-main` skill 等で upstream の最新に追従してから進める。

## ブランチ名・worktree 名の規約

コード変更を伴う作業を始めるときは、最新の main / develop からブランチを切り、worktree を作成する。その際の命名は以下に統一する:

- **ブランチ名は `feature/<作業内容>` に統一**する（例: `feature/add-login`、`feature/fix-score-rounding`）。fix / refactor / chore など作業の種別を問わず、すべて `feature/` プレフィックスで揃える。`<作業内容>` は内容が分かる kebab-case の短い英語にする。
- **worktree 名（`EnterWorktree` の `name` ＝ ディレクトリ名）はブランチ名ではなく作業名**にする。`feature/` プレフィックスは付けず、作業内容そのものを名前にする（例: ブランチが `feature/add-login` なら worktree 名は `add-login`）。
- ただし対象リポジトリに独自のブランチ命名規約がある場合（CONTRIBUTING / project CLAUDE.md の明示、既存ブランチが一貫した別パターン など）は、そのプロジェクトの方式を優先する。

# Skill / slash command の言語

`.claude/commands/` / `.claude/skills/` / `~/.claude/commands/` などに置く **Claude への指示文は英語で書く**。理由: `stage` / `subject line` / `pre-commit hook` / `HEREDOC` のような技術語彙の連想が英語のほうがブレず、組み込み skill や公式 docs ともレジストリが揃うため。日本語で書くと精度が落ちる傾向がある。

ただし以下は日本語のままにする:

- ユーザーに見える文字列（`AskUserQuestion` のオプション、`statusMessage`、出力するコミットメッセージ規約 など）
- プロジェクト文書の literal な日本語見出し（例: `docs/store/info.md` の「説明」「単一用途」「権限が必要な理由」など、grep のキーとして指している固有名詞）

# frontend-design skill のデフォルト運用

以下のいずれかに該当する場合は、まず `frontend-design` skill (`/frontend-design:frontend-design`) の起動を検討する。generic な AI 美学（Inter / 紫グラデ / 凡庸な layout / Space Grotesk への収斂）を回避し、プロジェクト固有の aesthetic を持たせるため。

- **新規 frontend を作るとき**: 新規 component / 新規 page / greenfield プロジェクトの起ち上げ
- **デザイン改善を要望されたとき**: 「デザインを改善して」「見た目をよくして」「リデザインして」「UI を刷新して」など、既存 UI のデザイン品質を上げる意図が示されているケース。skill 名が明示されていなくても起動してよい

**対象外（呼ばない）**:

- ラベル変更・コピー修正・bug fix・spacing 微調整など、デザイン品質ではなく細部の修正が目的の作業 — skill の "pick a fresh BOLD tone" 指示と作業の動機がズレる
- frontend を持たない repo

**既存 design language との優先順位**:

skill 内の指示文（_"NEVER converge on common choices"_ / _"vary aesthetics across generations"_ / _"Inter / Roboto / system fonts は使うな"_ など）はすべて **project CLAUDE.md と既存の design tokens / primitives より下位**。既に aesthetic が確立しているプロジェクトでは、ユーザーが明示せずとも project の慣習を優先する（skill の "fresh tone" 指示は greenfield のためのデフォルトと解釈する）。

**`docs/ux/scenarios.md` があるときの連携（ux-discovery bridge）**:

frontend-design を起動する前に `docs/ux/scenarios.md`（`ux-discovery` skill の成果物）の有無を確認し、あれば読んでから生成する。aesthetic の選択（tone / type / color / motion）は frontend-design の自由のままだが、**情報の主役と導線はシナリオに従う**:

- 対象画面に対応するシナリオの**ゴール要素**を視覚的に最も目立たせる（hierarchy の頂点に置く）
- **5秒テストの正解キー**（①これは何の画面か ②一番大事なものは何か ③次に何をすればいいか）が、本文を読まなくても成立する視覚階層にする
- `flow-layout` の配置仕様（before/after・配置テーブル）が同セッションや成果物にあれば、**そのレイアウトを土台に見た目だけを載せる**。frontend-design 側でレイアウトを組み直さない（再配置・ページ分割は flow-layout の領分）

# 日本語 UI テキストの改行

日本語 UI テキストの改行品質（文節折り返し・孤立行防止・measure）の詳細ルールは `~/.claude/rules/jp-line-break.md` にある（tsx / css 等を読むと自動ロードされる）。既存ファイルを読まずに新規 frontend ファイルをゼロから生成するときも、同ルールを読み込んで適用すること。

# UI の区切りを説明テキストで表現しない

UI 上のセクション・領域の区切りは **ビジュアル（border・背景色・余白・タイポグラフィ階層）だけで表現**し、「ここから〜」「ここまで」「以下は〜です」のような**位置を説明するメタテキストを置かない**。理由: border 等の視覚的な区切りがあれば境界は伝わるので、説明テキストは情報として重複しノイズになる。

- セクションにラベルが必要な場合は、内容そのものの名前を見出しとして置く（例: 「レビュー」「関連作品」）。「ここからレビューです」のような位置説明文にしない
- テキストで補足しないと区切りが伝わらないと感じたら、テキストを足すのではなく、区切りのビジュアル（コントラスト・余白・階層）を強くする方向で解決する

# 指示文へのフィードバック (prompt tips)

ユーザーの指示文（このターンのメッセージ）に対するフィードバックを応答末尾に添える。ただし**このターンで実際に支障があった場合のみ**。具体的には以下のいずれかが実際に起きたターンに限る:

- 曖昧さ・主語抜け・誤字変換ミスのせいで、二通りの解釈から**推測で選んで進めた**（どう読んだかを添える）
- 情報不足で**確認の往復や手戻りが実際に発生した**
- 指示を誤読しかけた／誤読した

出さないケース（過去ログで多すぎたパターン）:

- 一発で意図どおり動けたターン。「〜と添えてもらえるとさらに速い」型の仮定的な改善提案は書かない
- 指示文を褒めるだけの tips（「この粒度を今後も踏襲して」など）

目安: 大半のターンでは何も書かない。形式は応答末尾に `---` で区切ったあと `**指示文 tips**` の見出しで 1〜3 行。長文にしない。タスク本体の応答にこの指摘を混ぜず、tips があっても作業は通常どおり進める。同種の指摘を繰り返しそうなら auto memory に保存し、保存済みの指摘は再掲しない。

# UI プレビューを ASCII アートで描かない

UI モック・レイアウト案・画面構成のプレビューを ASCII アート（罫線 / box drawing）でターミナルに描かない。日本語環境のターミナルでは全角幅の混在で罫線が崩れて読めない。代わりに:

- HTML ファイルとして書き出し、playwright MCP でスクリーンショットを撮って見せる（flow-layout skill と同じ方式）
- それが過剰な場面では、markdown の箇条書きやテーブルで構造を説明する（markdown table は崩れないので可）

# Playwright MCP のスクリーンショット配置

`playwright` MCP server を経由して撮影したスクリーンショットやコンソールログは、プロジェクトルート直下の `.playwright-mcp/` ディレクトリに配置すること（リポジトリには .gitignore 経由でコミット除外する）。理由: ルート直下にバラ撒くと `git status` のノイズが増え、`/commit` のスナップショットや diff 確認の邪魔になるため。

具体的には:
- `browser_take_screenshot` の `filename` を指定する際は `.playwright-mcp/<descriptive-name>.png` の形にする（必要ならサブディレクトリも切る）。
- `.playwright-mcp/` が `.gitignore` に登録されていないリポジトリでは、最初のスクリーンショット撮影前に登録するか、ユーザーに登録を提案する。
