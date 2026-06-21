# 言語設定

ユーザーへの応答は常に日本語で行うこと。コード内のコメントや識別子はプロジェクトの慣習に従い、必要に応じて英語のままで構わない。

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
