---
name: journey-redesign
description: Generative journey/story surgery — WALK the current journey step-by-step via Playwright (recording steps, demanded inputs/decisions, and where value first becomes visible), evaluate the sequence against named narrative principles (value-before-ask, progressive disclosure, goal-gradient, peak-end, Tesler's law, Hick's law, error recovery), then propose and (gated) apply a re-sequenced journey — remove/merge/reorder/defer steps. Strictly separates evidence from hypothesis: without analytics/funnel data, ordering claims are marked 要検証, never asserted. Consumes docs/ux/scenarios.md (ux-discovery output) when present. Use when the user wants the flow/story/onboarding restructured — e.g. 「ストーリーを再設計して」「オンボーディングを見直して」「導入の流れを組み直して」「ステップを減らして」「サインアップまでの体験を改善して」「離脱を減らしたい」. NOT for within-screen placement/page-internal layout (→ flow-layout), broad heuristic audit (→ design-review), copy rewriting (→ ux-writing-review), or visual styling (→ frontend-design).
---

# /journey-redesign — walk the story, then re-sequence it

A journey problem is a **sequence** problem: steps in the wrong order, asks before value, complexity dumped on the user, dead ends with no resume. This skill operates one altitude above `flow-layout`: flow-layout decides what goes where *within* a screen; this skill decides **which screens/steps exist and in what order**. Hand off accordingly:

- Within-screen placement, scan paths, where the CTA sits → `flow-layout`
- Visual styling of the resulting screens → `frontend-design`
- The words on each step → `ux-writing-review`
- Defining who the user is and what the scenarios are → `ux-discovery` (upstream of this skill)

**Evidence discipline (the core rule):** a journey's "correct" order is ultimately an empirical question. Findings grounded in observable structure (step counts, inputs demanded before value appears, dead ends) are evidence. Claims about what users *prefer* or *where they drop off* are hypotheses unless analytics back them — mark them 要検証 with what data would confirm them. Never fabricate user research.

## Step 0 — Pick the journey and gather ground truth

`$ARGUMENTS` may name a journey (onboarding, checkout, first-note creation…). Otherwise:

- Read `docs/ux/scenarios.md`. Present the ranked scenarios via `AskUserQuestion` (multiSelect; options = top scenarios with frequency × importance, plus 「最重要シナリオおまかせ」). Skip the ask when the user already named the journey or only one scenario exists.
- `docs/ux/scenarios.md` absent → offer to run `/ux-discovery` first, or have the user describe the journey's goal in one line and proceed (mark the scenario itself 要検証).

Ask once whether funnel/analytics data exists (どの段階で離脱が多いか分かるデータはありますか). If reachable, read it — it upgrades hypotheses to evidence. If not, say you are operating in hypothesis mode and continue.

Get a running preview reachable by Playwright MCP; without one, the walk degrades to source-reading (routes, guards, form fields) — say so. Artifacts go under `.playwright-mcp/journey-redesign/` (gitignored).

## Step 1 — Walk and record the current journey

Drive the journey end-to-end via Playwright as a first-time user would (fresh state where possible: cleared storage / incognito context / a new test account). Screenshot every step to `.playwright-mcp/journey-redesign/<journey>-step<NN>.png`. Record per step:

| Field | What to capture |
|---|---|
| 画面/状態 | route or modal, screenshot path |
| 要求される入力 | form fields, choices, permissions demanded here |
| 要求される判断 | decisions the user must make (plan choice, settings…) and how many options (Hick) |
| 価値の可視性 | is the product's value visible *yet* on this step? (the first such step = value moment) |
| 行き止まり | can the user leave and resume? what happens on error/back? |

Also record: total steps to goal, total fields before the value moment, and any step where the journey forks or silently fails. The output of this step is the **current journey map** — a markdown table (never ASCII-art diagrams), one row per step.

## Step 2 — Evaluate the sequence against named principles

Judge the recorded sequence. Every finding cites the principle, the step number, and the recorded evidence; tag each 証拠あり or 要検証 (+ what data would confirm it):

- **Value-before-ask** — does the journey demand signup/fields/permissions before showing what the product does? Count fields-before-value-moment.
- **Progressive disclosure** — are advanced options forced into the critical path instead of deferred?
- **Goal gradient** — is progress visible, and do later steps get lighter (not heavier) toward the goal?
- **Peak-end** — what is the journey's emotional peak and its final step? Does it end on a success state or on bureaucracy?
- **Tesler's law** — complexity that must exist somewhere: is it carried by the system (defaults, inference) or dumped on the user (manual config)?
- **Hick's law** — steps demanding a choice among many undifferentiated options.
- **Error recovery / resumability** — interrupted mid-journey: is progress kept? Is there a way back without restarting?

Severity: 高 (likely abandonment point) / 中 (friction) / 低 (polish). A finding with neither a recorded observation nor data behind it gets dropped, not hedged.

## Step 3 — Redesign the sequence

Propose the new journey as a **before/after journey map** (two markdown tables or one with old→new columns). Allowed operations: remove a step, merge steps, reorder, defer an ask to after the value moment, split an overloaded step, add a missing state (resume point, success peak). For each change:

- which finding it resolves (principle + step)
- 確証度: 証拠あり / 要検証 — and for 要検証, the metric that would validate it (e.g. step-2 completion rate)
- what it does NOT change (scope honesty)

Keep the proposal at sequence altitude: name what each step contains, not where elements sit on the screen — within-screen composition is `flow-layout`'s output, offer it as the next pass for reshaped steps.

## Step 4 — Gate

`AskUserQuestion`, options in Japanese:

- 「提案を適用(ルーティング・ステップ構成を編集)」
- 「提案だけでよい(自分で実装)」
- 「flow-layout に引き渡して画面内も設計」
- 「主要な変更だけ適用」

Skip the gate when the user already said 全部直して/おまかせ, or is running unattended (then apply 高-severity changes only).

## Step 5 — Apply (if chosen)

Edit at the sequence level: routing, step order, guards/redirects, which fields appear on which step, deferred-ask wiring. Preserve the project's components and styling — you are re-sequencing, not redesigning screens (new/reshaped screens get a one-line stub faithful to existing patterns, then hand to `flow-layout` / `frontend-design`).

Verify by **re-walking**: drive the new journey end-to-end with Playwright from fresh state, screenshot each step, and confirm (a) it completes, (b) step count and fields-before-value match the proposal, (c) no new dead end appeared. A re-walk failure loops back — cap 2 apply-walk passes, then report what's left honestly.

## Step 6 — Report

- Before/after journey map, with the two headline numbers: ステップ数 and 価値が見えるまでの入力数 (before → after)
- Per-change: principle resolved, 確証度
- **検証バックログ**: every 要検証 item with the metric that would confirm it — this is the A/B / analytics to-do list, state plainly that these are hypotheses
- After-screenshot paths; handoffs (flow-layout for screen internals, ux-writing-review for step copy) in one line each

## Don't

- Don't assert user behavior without data — structural observations are evidence, preference/drop-off claims are 要検証
- Don't fabricate research, personas, or funnel numbers
- Don't redesign within-screen layout or styling — hand off to `flow-layout` / `frontend-design`
- Don't draw journey maps as ASCII-art flowcharts — markdown tables only
- Don't walk the journey as a logged-in power user — first-time fresh state, or say why not
- Don't apply sequence changes without a re-walk proving the new journey completes
- Don't auto-commit; let the user invoke `/commit`

## Why this skill exists

「オンボーディングを見直して」 otherwise produces armchair journey advice — generic step-reduction tips asserted as fact, never walked, never verified. Forcing walk → named principle → re-sequence → re-walk makes the story redesign falsifiable, and the evidence/hypothesis split keeps it honest when no analytics exist. Sequence altitude keeps it from colliding with flow-layout (within-screen) and ux-discovery (who/what-for).
