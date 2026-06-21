---
name: ux-discovery
description: Grounded scenario & user-context discovery — the upstream "who/what-for" pass that feeds design. Mines REAL project evidence (PRD/README/docs, e2e tests, routes & nav, UI copy & empty states, data model & auth roles, issues/PRs/CHANGELOG, analytics if reachable) to produce a prioritized set of lightweight personas + Jobs-To-Be-Done scenarios, each with its goal element, success definition, and a **5-second-test answer key** (the 3 things a first-time user must grasp without reading prose). Strictly separates evidence from assumption (marks 要検証) and never fabricates research. Persists to `docs/ux/scenarios.md` as the single source of truth consumed by flow-layout, design-review, and frontend-design. Lightweight by default, deep on request. Use before laying out / reviewing a UI, or when the user says 「ユーザシナリオを洗い出して」「誰のための画面か整理して」「ペルソナとジョブを定義して」「シナリオ調査して」「5秒テストの正解を決めて」「使う人と目的をはっきりさせて」.
---

# /ux-discovery — grounded scenario & user-context discovery

The **Discover / Define** half of the work (Double Diamond): *who is this for, what job are they hiring it to do, and how do we know they succeeded* — before deciding **how to lay it out** (`flow-layout`), **how to review it** (`design-review`), or **how it looks** (`frontend-design`). All three consume the artifact this skill writes: `flow-layout` takes the goal elements + 5-second answer keys as its optimization targets, `design-review` grounds its journey/JTBD/onboarding lenses in it, and `frontend-design` (via the global CLAUDE.md bridge) keeps the goal element and 5-second keys on top of its visual hierarchy.

**The one rule that makes this trustworthy: do not fabricate research.** An LLM asked to "research users" will invent confident personas — that poisons every downstream decision. This skill only derives scenarios from **real, citable project evidence**, and where evidence runs out it says so explicitly and marks the gap `要検証`. Naming what you *can't* know is the job, not a failure of it.

## Step 0 — Scope & depth (state in one line)

- **lightweight** (default) — the top 1 scenario + the persona behind it, derived in one pass. Right for a single screen/flow or before a focused `flow-layout` run. Don't run heavy discovery for a button tweak.
- **deep** — full persona spectrum + all primary scenarios ranked, with an evidence audit. For a whole-product definition, a greenfield kickoff, or when the user asks for thoroughness.

Also state the **source mode**: **mine** (evidence exists in the repo/docs) or **elicit** (greenfield / no artifacts → ask the user structured questions). Default to mine when sources exist; fall back to elicit only for the gaps.

## Step 1 — Gather evidence (mine mode)

Sweep these sources, strongest signal first. **Tag every finding with where it came from** — that tag travels into the artifact.

1. **Stated intent** — PRD, README, `docs/`, design docs. What the team says the product is for.
2. **e2e / integration tests** — they encode *real, intended user flows* in executable form (often the truest signal, and usually overlooked). `*.spec.*`, `*.e2e.*`, Playwright/Cypress specs.
3. **Routes & navigation / IA** — the app's own map of what users do (router config, nav/menu structure, sitemap).
4. **UI copy in context** — page titles, primary button labels, empty states, onboarding, error messages. The product describing its own jobs in its own words.
5. **Data model & auth** — schema/entities = *what users manage*; roles/permissions = *who the personas are*.
6. **Issues / PRs / CHANGELOG / commit history** — what's been prioritized and what real pain was reported.
7. **Analytics / logs / support tickets** — real behavior & frequency, *if* reachable (files or an MCP server). Usually absent → record "no behavioral data available" and mark frequency claims `要検証`.
8. **Marketing / landing copy** — who the product is positioned and sold to.

If little/no evidence exists (**elicit mode**), ask the user a tight set instead of guessing: *who uses this · what triggers them · the one outcome they want · device & context · how often · what "success" looks like on screen · the riskiest assumption you're making about them.* Keep it short; offer to proceed on stated assumptions.

## Step 2 — Personas (lightweight, evidence-backed)

Derive only the personas the evidence supports — typically 1–3. Each: a one-line identity, their **expertise** (first-timer vs. power user → drives recognition-vs-recall & density), and the **source** it's grounded in (e.g. "admin role in `schema.prisma` + onboarding screen"). No demographics theater. Anything not in evidence is labeled a hypothesis with `要検証`.

## Step 3 — Scenarios (JTBD job stories), prioritized

For each scenario write a **job story** and the fields that downstream design needs:

- **Job story** — *"When [situation], the user wants to [motivation], so they can [outcome]."*
- **Context** — **device** (mobile/desktop — placement depends on it), urgency, one-shot vs. habitual, frequency.
- **Goal element** — the single control/content that *completes* this scenario (the target the eye must reach in `flow-layout`).
- **Success** — what on screen tells the user they succeeded.
- **Screens crossed** — the rough sequence (trigger → steps → success).
- **Priority** — *frequency × importance*. The downstream layout optimizes the top scenario without pessimizing the rest, so this ranking matters.

## Step 4 — The 5-second-test answer key (per key screen)

This is the acceptance criteria `flow-layout`'s glanceability gate scores against. For each key screen, state the **3 things a first-time user must be able to say in ~5 seconds, without reading body text**:

1. **これは何の画面か** (what this screen is)
2. **一番大事なものは何か** (what's most important here — usually tied to the goal element)
3. **次に何をすればいいか** (the next action)

If the answer can only come from reading prose, the future design fails the gate — that's the whole point of writing the key now, before any layout exists.

## Step 5 — Evidence vs. assumption (honesty pass)

Split every claim into **根拠あり** (cite the source) vs. **仮説（要検証）** (state the validation method: user interview · analytics · first-click test · 5-user usability test · card sort). List the **open questions** the evidence couldn't answer. A thin-but-honest artifact beats a rich fabricated one.

## Step 6 — Write the artifact (the contract)

Write to **`docs/ux/scenarios.md`** (follow the project's docs convention if it differs; create the dir if needed). This file is meant to be **committed** — it's a shared source of truth, not a scratch file. If it already exists, **merge/update** rather than clobber (preserve human edits; note what you changed).

Use this schema:

```markdown
# UX シナリオ（single source of truth）
更新: <date> ｜ 深さ: lightweight/deep ｜ 出典モード: mine/elicit

## ペルソナ
- **初見の管理者** — 習熟: 低。根拠: roles テーブル + onboarding 画面。頻度=低（仮説・要検証）

## シナリオ（頻度×重要度で順位）
### S1 [主] 月末の請求を確定する
- job: When 月末締めのとき, wants to 未確定の請求を一括で確定したい, so 締め作業を終えられる
- context: desktop / 緊急度:高 / 月1回・習熟あり
- goal要素: 「一括確定」ボタン
- 成功: 確定済み件数が画面で増えるのが見える
- 経由画面: 請求一覧 → 確認ダイアログ → 完了
- 5秒テストの正解キー（請求一覧画面）:
  ① これは=今月の請求一覧 ② 一番大事=未確定の件数 ③ 次=一括確定
- 根拠: `invoices` ルート + e2e `confirm-invoices.spec.ts`。緊急度=高 は仮説（要検証）

## 未解決の問い（要検証）
- 実際の利用頻度: アナリティクス未接続 → first-click / analytics で検証
```

Then report a short summary to the user: the personas, the ranked scenarios (one line each), and the top 3 open questions. Note that `flow-layout` / `design-review` / `frontend-design` will read this file.

## Rules
- **Never fabricate.** Every persona/scenario claim is either tagged with a real source or marked `仮説（要検証）` with a validation method. No invented demographics or confident frequencies.
- **Lightweight by default.** Don't run a full discovery for a small change — top scenario + persona is enough; deepen only on scope or request.
- **The artifact is the contract.** Keep the schema stable so `flow-layout` (goal element + 5-second answer key), `design-review`, and `frontend-design` can consume it. Update, don't clobber.
- **Evidence over imagination.** Prefer e2e tests, routes, schema, and real copy to speculation. When the source is thin, say so — that gap *is* the deliverable.
- **You define, you don't design.** Output scenarios & acceptance keys, not layouts or visuals. Hand those to `flow-layout` / `frontend-design`.
