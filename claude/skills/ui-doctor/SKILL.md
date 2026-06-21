---
name: ui-doctor
description: Triage-then-dispatch umbrella for vague "this UI is hard to use/see" complaints — capture the rendered screens, run a CHEAP diagnosis across six axes (A: physical legibility, B: structure/layout/flow, C: behavior/state-feedback, D: journey/story, E: copy/wording, F: information density/disclosure), rate each axis with evidence, then dispatch only the broken axes to the specialist skills (readability-review / flow-layout / journey-redesign / ux-writing-review / disclosure-review / design-review, with ux-discovery upstream when scenarios are missing) in the correct order, fix axis-C issues inline, and close with a unified per-axis before/after report. Use when the user complains without naming an axis — e.g. 「なんか見にくい」「使いにくいので改善して」「どこが悪いか分からないけど直して」「全体的にレビューして改善して」. NOT when the complaint already names one axis: 文字が読みづらい/コントラスト → readability-review, 導線・配置・ページ分割 → flow-layout, オンボーディング・ステップの流れ → journey-redesign, 文言・用語 → ux-writing-review, 情報量・ごちゃつき・段階的開示 → disclosure-review, ヒューリスティック監査だけ → design-review.
---

# /ui-doctor — diagnose across axes, then dispatch the specialists

A vague 「見にくい」「使いにくい」 decomposes into six independent axes, each owned by a specialist skill:

| Axis | What breaks | Specialist |
|---|---|---|
| **A. 文字・視覚** | contrast, font size, leading, line length, target size, density | `readability-review` (measure → fix → re-measure) |
| **B. 構造・レイアウト** | hierarchy, grouping, scan path, page/step splitting, 5-second test | `flow-layout` (+ `ux-discovery` upstream) |
| **C. ふるまい** | state feedback (loading/saved/error), motion overload, responsive breakage | this skill, inline (+ `design-review` for the wide canon) |
| **D. ストーリー** | steps in the wrong order, asks before value, dead ends, no resume | `journey-redesign` (walk → re-sequence → re-walk) |
| **E. 文言** | ambiguous labels, unhelpful errors, terminology drift, register mixing | `ux-writing-review` (harvest → rule-check → rewrite) |
| **F. 情報量・開示** | too much at rest, over-hiding of frequent info, tooltip/dialog/sheet misuse | `disclosure-review` (tier → re-surface → both-direction verify) |

This skill is the **dispatcher, not a duplicate specialist**. Its own measurement is deliberately shallow — just enough evidence to decide which axes are broken and in what order to treat them. Depth lives in the dispatched skills.

If the user's complaint already names a single axis, don't run triage theater: say which specialist owns it in one line and invoke that skill directly.

## Step 0 — Scope and preview

`$ARGUMENTS` may name screens, routes, or a complaint. Empty → the app's primary screens.

- Get a running preview reachable by Playwright MCP. None running → ask the user to start one (suggest `! <dev command>`). User-provided screenshots alone allow axis-B/E judgment but cripple axis-A measurement and axis-C/D interaction checks — say so and proceed with what's possible.
- Read `docs/ux/scenarios.md` if present (scenarios + 5-second answer keys feed axes B and D; frequency × importance feeds axis F's tiering). Note whether it exists — its absence changes the dispatch plan. Read `docs/ux/glossary.md` if present (feeds axis E).
- Ensure `.playwright-mcp/` is gitignored; artifacts go under `.playwright-mcp/ui-doctor/`.

## Step 1 — Capture

For each target screen, screenshot via Playwright MCP to `.playwright-mcp/ui-doctor/<screen>-<state>.png`: default, dark mode (if supported), 375px viewport. Keep it to the primary screens — this is triage, not the specialist's full state matrix.

## Step 2 — Triage each axis (cheap, bounded)

**Axis A — spot measurement (one pass, no fix loop):**
Inject axe-core, run `color-contrast` only; plus one `browser_evaluate` collecting body font sizes, line-heights, and sub-24px interactive targets. Record the 3–5 worst violations with measured values. Do NOT expand into the full readability-review matrix — that's the specialist's job.

**Axis B — 5-second test + structure glance:**
Against each screen's screenshot, answer the 5-second keys: ①何の画面か ②一番大事なものは何か ③次に何をすればいいか. Use the answer keys from `docs/ux/scenarios.md` when present; otherwise answer from the screen itself and mark the keys 要検証. Note hierarchy/grouping failures visible in the screenshot (one line each, no full Gestalt audit).

**Axes C & D — one walk of the main flow (shared):**
Drive the primary scenario once via Playwright, end-to-end, recording for both axes from the same walk:

- *C (behavior):* is there feedback for loading/success/error states; does anything move on its own (auto-carousel, scroll-jack); does 375px mid-flow produce horizontal scroll or overlap. Console errors count as evidence.
- *D (story):* count steps to the goal, count inputs demanded before the product's value is first visible, note any dead end (no way back/resume) and any step demanding a heavy decision. Three numbers + dead-end list — no full journey map; that's `journey-redesign`'s Step 1.

**Axis F — density spot-count (one `browser_evaluate`, no tier map):**
On each primary screen, count: top-level visual chunks, visible interactive elements, and choices at the busiest single decision point (flag >5 chunks / >7 choices as candidates, per Cowan/Hick). Plus two spot checks from the shared walk: is any primary-scenario action buried ≥2 interactions deep or hover-only; does one sampled tooltip/menu violate WCAG 1.4.13 (no Esc dismiss, vanishes on hover-toward). Do NOT build the frequency×visibility tier map — that's `disclosure-review`'s Step 3.

**Axis E — copy sampling (~10 strings, no harvest):**
Sample across buttons, error messages, and empty states from the captured screens. Check: do buttons predict their outcome (動詞+目的語); do errors say 何が起きた+どうすればいい; quick grep for obvious terminology drift (e.g. 削除/消去 on the same entity); 敬体・常体 mixing within one screen. Do NOT build the full inventory — that's `ux-writing-review`'s Step 1.

**Verdict per axis:** `重大` (blocks the user) / `軽微` (slows the user) / `問題なし`, each with 1–2 evidence lines (measured value, screenshot path, or observed behavior). An axis verdict without evidence is not allowed — downgrade to 問題なし instead of guessing.

## Step 3 — Diagnosis report and dispatch plan

Present a compact table: axis, verdict, top evidence, owning skill. Then the **treatment order** — order matters because later steps measure what earlier steps changed:

1. `ux-discovery` — only if axis B or D is broken AND `docs/ux/scenarios.md` is missing (the downstream skills need scenarios to aim at)
2. `journey-redesign` — axis D (re-sequences which screens/steps exist, so it precedes any within-screen work)
3. `disclosure-review` — axis F (decides WHAT is visible at rest on each surviving screen; tiering before placement, or flow-layout would arrange items about to be demoted)
4. `flow-layout` — axis B (arranges the tier-1 set that survived step 3 within each screen)
5. Axis C inline fixes — this skill (see Step 5)
6. `ux-writing-review` — axis E (copy is written against the settled structure; its length checks would be wasted on screens about to be reshaped)
7. `frontend-design` — opt-in only (never auto-dispatched; aesthetics has no evidence-based verdict, so it is not a triage axis). When chosen at the gate, it runs HERE: after structure and copy settle, before pixel measurement
8. `readability-review` — axis A, always LAST among fixes (it measures the final rendered pixels, including the final copy and any restyle)
9. `design-review` — optional wide audit, critique-only, offered when the user wants the full canon pass

Skip every skill whose axis is 問題なし. If all six axes pass, say so with the evidence and stop — do not invent work.

## Step 4 — Gate

`AskUserQuestion` (multiSelect), options in Japanese, built from the flagged axes only, e.g.:

- 「重大の軸だけ治療(おまかせ)」 (Recommended)
- 「軽微も含めて全部」
- 「診断レポートだけでよい(自分で対応)」
- 「広い監査(design-review)も追加」
- 「見た目の刷新(frontend-design)も追加」 — only offer this option when the screens look generically unstyled or the user's complaint hints at look-and-feel; choosing it follows the global CLAUDE.md frontend-design rules (existing design language wins over "fresh tone")

Skip the gate and default to 重大-only when the user already said おまかせ/全部直して, or is running unattended.

## Step 5 — Execute

Invoke each chosen specialist via the Skill tool, **sequentially in the Step 3 order**, passing scoped args (the target screens + the triage evidence so the specialist doesn't re-discover it). Let each specialist run its own loop and caps; don't re-do or second-guess its measurements.

Axis-C findings have no fix-loop specialist, so fix them inline here:

- Missing loading/disabled/success feedback → add the state at the component level, following the project's existing patterns (find an existing async button/form first and mirror it)
- Responsive overflow/overlap at 375px → fix the offending layout rule; if the real cure is restructuring, route it into the flow-layout pass instead
- Self-moving UI → honor `prefers-reduced-motion`, remove autoplay or add controls

After inline fixes: re-walk the Step 2 flow, re-screenshot, confirm each fix by observation. Cap 2 fix passes for axis C; report what remains.

## Step 6 — Unified report

Close with one report the user can read without having watched the run:

- Per-axis: verdict before → state after, with the specialist's own before/after evidence (readability-review's measurement table, flow-layout's wireframe/screenshots, journey-redesign's step-count delta, ux-writing-review's string table, disclosure-review's density + interaction-cost tables, axis-C re-walk results)
- After-screenshot paths
- Remaining items: anything skipped at the gate, capped out, critique-only (design-review findings), or 要検証 (journey hypotheses awaiting data), each with its owning skill in one line

## Don't

- Don't deep-dive during triage — Step 2 is bounded to spot checks; depth belongs to the dispatched specialists
- Don't run specialists for axes rated 問題なし, and don't run all six "to be thorough"
- Don't violate the treatment order — journey before disclosure, disclosure before layout, layout before copy, copy before pixel measurement; earlier passes invalidate later measurements when reversed
- Don't duplicate a specialist's work inline (e.g. hand-fixing contrast or rewriting copy here); dispatch it
- Don't emit an axis verdict without evidence (measured value, screenshot path, or observed behavior)
- Don't auto-commit; let the user invoke `/commit`
- Don't restyle or redesign aesthetics inline or auto-dispatch `frontend-design` — it runs only when explicitly chosen at the gate (or asked for), in the Step 3 slot before readability-review

## Why this skill exists

The specialists each need the user to already know which axis is broken (「コントラストを直して」「導線を見直して」「オンボーディングを組み直して」「文言を統一して」「情報量を減らして」). Real complaints arrive as 「なんか見にくい」. Without a triage front door, that either picks one specialist by luck or runs everything at full depth. This skill spends a cheap diagnosis pass to route the complaint, enforces the journey → disclosure → layout → copy → pixels treatment order, and covers the behavior axis the specialists leave between them.
