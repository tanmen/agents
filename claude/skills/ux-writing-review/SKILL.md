---
name: ux-writing-review
description: Measurement-driven UX writing review & rewrite loop — harvest ALL user-facing copy (i18n/locale files, or hardcoded strings, or rendered text), check every string against objective rules (buttons = 動詞+目的語 predicting the outcome, errors = 何が起きた+どうすればいい, terminology consistency / 用語の揺れ detection, 敬体・常体 mixing, double negatives, length budgets, leaked internal jargon), rewrite the violations, verify each rewrite IN CONTEXT via screenshots (truncation/overflow), and persist docs/ux/glossary.md as the terminology source of truth. Use when the user wants copy improved — e.g. 「文言を簡略化して」「文言を見直して」「マイクロコピーを改善して」「エラーメッセージを分かりやすくして」「用語を統一して」「ボタンの文言を直して」. NOT for visual legibility/contrast (→ readability-review), element placement (→ flow-layout), journey restructuring (→ journey-redesign), or broad heuristic audits (→ design-review).
---

# /ux-writing-review — harvest, rule-check, rewrite, verify in context

Copy problems hide in plain sight because each string looks fine alone — the violations are **relational** (the same concept named three ways, 敬体 here and 常体 there) or **functional** (a button that doesn't predict its outcome, an error that names the problem but not the way out). So this skill harvests the full copy inventory first and checks it against named rules; a finding without a rule, the current string, and its location is not allowed. Then it rewrites and **verifies every rewrite in the rendered screen**, because copy length changes break layouts and tone reads differently in context.

Scope is words only. Hand off when the problem is something else:

- The text is hard to *see* (contrast, size) → `readability-review`
- The text is in the wrong *place* or the screen needs restructuring → `flow-layout`
- The *steps* are in the wrong order → `journey-redesign`

## Step 0 — Scope and ground truth

`$ARGUMENTS` may name screens, a string category (エラーメッセージだけ等), or specific terms. Empty → all user-facing copy of the primary screens.

Locate the copy's source of truth and say which mode applies:

1. **i18n/locale files** (`locales/`, `*.po`, `messages.*`, `ja.json`…) — best case: harvest by parsing them
2. **Hardcoded strings** in JSX/templates — harvest by grep over component files
3. **Neither reachable** (server-driven copy, CMS) — harvest from rendered pages via Playwright; flag that fixes need the CMS side

Read `docs/ux/glossary.md` if it exists — established terms there are law, not findings. Also read project CLAUDE.md / contribution docs for a defined tone (ですます調 etc.). Get a running preview for Step 4's context verification; artifacts go under `.playwright-mcp/ux-writing/` (gitignored).

## Step 1 — Harvest the inventory

Build the copy inventory: every user-facing string with its location (`file:line` or i18n key) and category:

- ボタン・アクション / ラベル・見出し / エラー・警告 / empty state / 説明・オンボーディング / 通知・トースト

Exclude: log messages, code comments, test fixtures, legal text (ToS/privacy — flagged later but never rewritten). For large apps, state the count and, if over ~300 strings, propose narrowing by category or screen rather than silently sampling — no silent caps.

## Step 2 — Rule check

Check every inventoried string. Each finding: rule, current string, location, severity (高 blocks understanding / 中 slows or misleads / 低 polish), and a proposed rewrite.

**Per-string (functional) rules:**

| Rule | Violation example | Pass example |
|---|---|---|
| ボタンは動詞+目的語で結果を予測させる | 「OK」「はい」 on a destructive dialog | 「ノートを削除」 |
| エラーは「何が起きた」+「どうすればいい」の2要素 | 「エラーが発生しました (E1042)」 | 「保存できませんでした。通信を確認して再試行してください」 |
| 二重否定・受動態の連鎖を避ける | 「無効化しない設定にしない」 | 「常に有効にする」 |
| 内部用語・実装語彙を漏らさない | 「user_id が null です」「APIエラー」 | ユーザーの語彙で言い換え |
| 長さ予算 | button > ~10 全角 / toast > ~40 全角 / 切り捨て発生 | fits without truncation |
| empty state は次の行動を示す | 「データがありません」 | 「最初のノートを作成しましょう」+ CTA |

**Cross-string (relational) rules — run over the whole inventory:**

- **用語の揺れ**: build a concept→terms map and flag concepts with 2+ terms (削除/消去/破棄、ログイン/サインイン…). Detect candidates by grouping near-synonyms and strings attached to the same action/entity.
- **敬体・常体の混在**: classify each string's register; flag surfaces that mix (一つの画面・一つのカテゴリ内での混在を高、アプリ全体での不統一を中).
- **同一アクションの不統一**: the same operation labeled differently on different screens.

A candidate finding that lacks the rule + location gets dropped, not hedged. Don't invent tone-of-voice violations beyond the project's own defined tone — taste-level rewording with no rule behind it is out of scope.

## Step 3 — Judge each finding

One line each, auto-review style:

- `Fix: <finding>` — objective rule violation with a safe rewrite
- `Skip: <finding> — <reason>` — legal text, brand-voice term confirmed in glossary/CLAUDE.md, meaning would change, or CMS-side string this repo can't edit

**Meaning is sacred**: a rewrite simplifies wording, never weakens or alters what is claimed (especially warnings and destructive confirmations — when in doubt, Skip with the reason).

## Step 4 — Rewrite and verify in context

Apply Fix items at the copy's source of truth (i18n file or component). One concern per edit; don't slip markup or layout changes in.

Then verify **in the rendered screen**: screenshot every screen whose strings changed (`.playwright-mcp/ux-writing/<screen>-after.png`, plus 375px viewport for length-sensitive strings) and check: no truncation/overflow/wrap breakage, the string reads correctly next to its neighbors, dynamic interpolations (counts, names) still compose grammatically. A rewrite that breaks layout loops back to a shorter rewrite — **cap 2 rewrite-verify passes**, then report what's stuck.

## Step 5 — Persist the glossary

Write/update `docs/ux/glossary.md` — the terminology source of truth consumed by future reviews:

```markdown
| 用語 | 意味 | 使わない同義語 | 備考 |
|---|---|---|---|
| 削除 | データを完全に取り除く | 消去, 破棄 | 確認ダイアログ必須の操作 |
```

Include only terms that were actually contested (揺れが見つかった or user-decided), not the whole vocabulary. New entries from this run are decisions — list them in the report so the user can veto.

## Step 6 — Report

- Before/after table of changed strings (current → new, rule, location)
- Cross-string results: 統一した用語 (and the glossary entries added), register decision applied
- Skipped findings with reasons, one line each
- After-screenshot paths proving context verification

## Don't

- Don't change meaning, weaken warnings, or soften destructive confirmations — Skip instead
- Don't touch legal text (ToS, privacy, compliance wording) — flag only
- Don't emit a finding without rule + current string + location, and don't rewrite on pure taste
- Don't claim a rewrite is done without the in-context screenshot — length changes break layouts silently
- Don't translate between languages or add new locales — same-language rewriting only
- Don't override `docs/ux/glossary.md` or a project-defined tone — established terms win over this skill's defaults
- Don't silently sample a large inventory — narrow scope explicitly instead
- Don't auto-commit; let the user invoke `/commit`

## Why this skill exists

「文言を分かりやすくして」 otherwise produces taste-based rewording: a handful of strings polished in isolation, terminology drift untouched, layouts silently broken by longer strings, and the same 揺れ reintroduced next month. Forcing harvest → named rule → rewrite → in-context screenshot makes copy review falsifiable, and the persisted glossary makes the terminology decisions durable across sessions.
