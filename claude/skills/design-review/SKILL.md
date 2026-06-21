---
name: design-review
description: General-purpose heuristic design review grounded in the established UX / IA / product-design canon — Nielsen's 10 heuristics, Norman, Shneiderman, the Laws of UX (Hick, Fitts, Jakob, Miller, Tesler, Doherty, Peak-End, Goal-Gradient…), the Polar-Bear IA model, Gestalt, Jobs-To-Be-Done, service blueprint / journey mapping, cognitive load theory, behavioral design & ethics (nudge, Fogg B=MAP, Cialdini, dark-pattern check), emotional design, calm technology, content/UX-writing, information design (Tufte), and WCAG 2.2. Runs single-pass (quick) or fans out to a panel of specialist sub-agents (deep) like code-review for higher precision. Use when the user asks for a design review, UX review, IA review, usability critique, accessibility/ethics check, or says 「デザインをレビューして」「情報設計の観点で見て」「UX レビュー」「使い勝手を見て」. Produces severity-rated findings (Nielsen 0–4 scale) grouped by lens, each citing the principle it violates and a concrete fix, plus 「最初に直す3つ」. It critiques against named principles — it does not redesign unless asked.
---

# /design-review — heuristic evaluation against the design canon

A **heuristic evaluation** (Nielsen/Molich's method): inspect the UI against a fixed, broad set of established principles, rate each problem's severity, and report. Every finding is anchored to a **named, industry-standard principle** — not personal taste. Always cite the principle.

General-purpose — works on any web/desktop UI. It **critiques**; it applies fixes only on request (Step 6). For a from-scratch redesign, use `frontend-design`. For a **focused, generative** pass on *scenario-driven gaze flow, component placement, and page/step splitting* (the 視線の移動量・配置・ページの分け方 axis), use `flow-layout` instead — it simulates the scan path and rebuilds the layout rather than auditing the whole canon.

## Step 0 — Scope and review depth

`$ARGUMENTS` may name a target (screen, a flow like "signup→first value", a component) and/or a depth keyword.

**Scope**: empty → survey the app's primary screens + the main end-to-end flow. A target → focus there; still flag cross-cutting issues you pass.

**Depth** — pick one, state which and why:
- **quick** (single-pass) — *you* walk every lens yourself (Step 3A). Default for a single component / small screen / fast pass.
- **deep** (specialist panel) — fan out to sub-agents, one per lens-group, then merge (Step 3B). Default for a whole-app review, a multi-screen flow, or when the user asks for precision ("しっかり" / "deep" / "agent で" / "ultra" / "精度高く"). Costs more (several cold agents) — only enter deep mode when scope or the user warrants it; never silently for a tiny review.

State the chosen scope + depth in one line before proceeding.

**Scenario ground truth**: if `docs/ux/scenarios.md` exists (the `ux-discovery` artifact), read it first and use its personas, ranked job stories, goal elements, and 5-second-test answer keys as the factual basis for the user/task-dependent lenses (2 ジャーニー, 3 JTBD, 15 オンボーディング) — don't invent job stories when researched ones exist, and cite the file in those findings. Pass the relevant scenario lines to sub-agents in deep mode. If it's missing and the review is whole-app scale, suggest `/ux-discovery` in one line (don't block).

## Step 1 — Capture the rendered UI (do not skip; feeds both modes)

Source-only review misses what matters most (hierarchy, density, alignment, contrast). Get the rendered screens **saved to disk** so they can be re-read (and handed to sub-agents in deep mode). Prefer, in order:

1. **User-provided screenshots** — best signal. If they live in the chat only, also note them; sub-agents can't see chat images, so for deep mode save copies under `.playwright-mcp/`.
2. **A running preview Playwright MCP can reach** (`http://localhost:…`) — `browser_navigate` + `browser_take_screenshot` to `.playwright-mcp/<screen>-<state>.png`. Realistic viewport. Capture the **key states** (default, empty, loading, error) — drive the UI (`browser_click`/`browser_evaluate`) to reach them.
3. **Component-level** — render the real component in a throwaway harness with its data/IPC layer mocked, serve, screenshot to `.playwright-mcp/`, then remove. (Use when the app can't be screenshotted directly — e.g. an Electron renderer.)
4. **Code-only fallback** — read component + styles; **state in the report that visual findings are limited**. Don't invent visual problems you didn't see.

Record: the **screenshot file paths** (with what screen/state each is) and the **relevant source paths**. This bundle is the shared input for every lens / specialist.

## Step 2 — The lens catalog (shared truth for both modes)

Apply every **Core** lens. Apply a **Conditional** lens when its trigger is in scope; else write `対象外（該当なし）`. **Depth follows severity** — spend effort where problems cluster. Behavioral guesses get `要検証: <method>` (card sort / tree test / usability test / first-click).

| # | Lens | Core/Cond. | 中核原則 | 専門家 |
|---|---|---|---|---|
| 1 | 情報設計 (IA) | Core | Rosenfeld & Morville; Information Foraging; Miller | P1 |
| 2 | サービス／ジャーニー全体 | Cond.（全体/複数画面） | Service blueprint; journey map; moments of truth | P1 |
| 3 | タスクフロー (JTBD) | Core | Jobs-To-Be-Done; Krug; Norman's gulfs | P2 |
| 4 | インタラクション & マイクロインタラクション | Core | Hick, Fitts, Doherty, Postel; Saffer | P2 |
| 5 | 認知負荷 | Core | Cognitive Load Theory; Miller; Tesler | P2 |
| 6 | 行動デザインと倫理 | Core | Nudge; Fogg B=MAP; Cialdini; dark-pattern check | P2 |
| 7 | 状態設計（エッジ状態） | Core | Nielsen #1/#9 | P3 |
| 8 | ビジュアル階層 | Core | Gestalt; CRAP; Aesthetic-Usability | P4 |
| 9 | コンテンツ・UX ライティング | Core | Plain language; voice & tone; microcopy | P4 |
| 10 | 情報の可視化 (Information Design) | Cond.（データ/グラフ） | Tufte; data-ink; chart honesty | P4 |
| 11 | 感情・トーン・注意の尊重 | Cond.（ブランド/通知/中断） | Norman 3 levels; Calm Technology | P4 |
| 12 | 一貫性・デザインシステム | Core | Jakob; Nielsen #4; Atomic Design | P1 |
| 13 | 信頼・安全性 | Cond.（破壊的/不可逆操作） | Nielsen #5/#9; Peak-End; reversibility | P3 |
| 14 | アクセシビリティ | Core | WCAG 2.2 POUR; Inclusive Design | P5 |
| 15 | モチベーション・オンボーディング | Core | Goal-Gradient; Zeigarnik; Serial Position; HEART | P5 |

### 構造とナビゲーション
**1. 情報設計 (IA)** — *Rosenfeld & Morville; Information Foraging; Miller*
- Four systems (**organization / labeling / navigation / search**); exact vs. ambiguous schemes; faceted where many-to-many is real — does the UI convey which? Labeling: one concept = one term. Wayfinding: always know *where I am* / *what's reachable*. **Information scent** — do labels predict what's behind them; can the user *find*, not only scroll? Miller — chunk into ~5–9. Validate: card sort / tree test.

**2. サービス／ジャーニー全体** *(Cond.: whole-app or multi-screen flow)* — *service blueprint; journey map*
- Map the journey across screens **and sessions**. Where does it **double back, dead-end, or drop context**? **Moments of truth** (first run, commit, result) designed deliberately? Front-stage vs. back-stage — is long processing made visible (status/progress) so the user isn't stranded?

### 流れと行動
**3. タスクフロー (JTBD)** — *Jobs-To-Be-Done; Krug; Norman's gulfs*
- Job story: "When [situation], I want to [motivation], so I can [outcome]." Is the **terminal step** present (confirm / undo / restore)? **Gulf of Execution** (how to act?) / **Gulf of Evaluation** (what happened?). Krug — self-evident steps; users **satisfice**.

**4. インタラクション & マイクロインタラクション** — *Hick, Fitts, Doherty, Postel; Saffer; Nielsen; Shneiderman*
- **Hick** (too many choices?), **Fitts** (target size/distance, crowded hit areas?), **Doherty** (<400 ms, optimistic UI/skeletons), **Postel** (forgiving inputs). **Microinteractions** (Saffer: trigger→rules→feedback→loops) — immediate proportionate feedback per action. Nielsen #1/#3(undo)/#5/#6; Shneiderman (closure, reversal, locus of control).

**5. 認知負荷** — *Cognitive Load Theory; Miller; Tesler*
- Strip **extraneous load** (irrelevant choices, redundant steps, noise), preserve **intrinsic** content. **Recognition over recall** across steps. **Tesler** — does the system absorb irreducible complexity (smart defaults) instead of dumping it on the user?

**6. 行動デザインと倫理** — *nudge; Fogg B=MAP; Cialdini; deceptive design*
- **Choice architecture** — defaults/ordering make the easy path serve the **user's** goal. **Fogg (B=MAP)** — at the action moment, prompt present + action easy + motivation addressed. **Cialdini** used honestly. **Dark-pattern audit (mandatory)**: no confirmshaming / forced continuity / sneaking / obstruction / fake urgency / misdirection / hidden costs — flag any as 🔴/🟠; manipulation is a defect even when it converts.

### 状態
**7. 状態設計（エッジ状態）** — *Nielsen #1/#9*
- Are **empty / loading / error / partial-failure / no-permission / offline** states designed, not just the happy path? Does each say what to do next (plain, constructive)? The **empty state** is an onboarding moment.

### 表現
**8. ビジュアル階層** — *Gestalt; CRAP; Aesthetic-Usability*
- Visual hierarchy matches information hierarchy (squint test). **Gestalt** (proximity/similarity/common region/alignment) groups & separates — misalignment reads as "broken". **CRAP**; type scale & measure (~45–75 chars); consistent grid (8-pt); color carries meaning (≈60-30-10). Polish must not mask friction.

**9. コンテンツ・UX ライティング** — *plain language; voice & tone; microcopy*
- Labels/buttons/errors **plain, specific, action-oriented**. Consistent **voice & tone**, calmer at risky moments. Microcopy **prevents** errors (inline hints) rather than explaining after.

**10. 情報の可視化** *(Cond.: charts/dashboards/data tables)* — *Tufte*
- **Honest encoding** (axes, proportions, no chartjunk); maximize data-ink; does the chart make the comparison the user needs easy? Tables: numeric right-align, scannable, sane sort/precision defaults.

**11. 感情・トーン・注意の尊重** *(Cond.: brand-sensitive, or notifications/interruptions)* — *Norman 3 levels; Calm Technology*
- **Visceral / behavioral / reflective** — intended emotion delivered at each level? **Calm technology** — respects attention (no needless interruptions / notification spam / attention-grabbing motion); sits in the periphery until needed.

### 横断品質
**12. 一貫性・デザインシステム** — *Jakob; Nielsen #4; Atomic Design*
- **Internal** (same concept → same component/word/place) & **external** (Jakob — platform/web conventions). Are repeated elements the *same* component, or drifted near-duplicates?

**13. 信頼・安全性** *(Cond.: destructive/irreversible actions)* — *Nielsen #5/#9; Peak-End; reversibility*
- Safety model **visible to the user** (preview, risk-proportional confirmation, undo) — not merely true in code. **Peak-End** — invest in the commit moment + result screen.

**14. アクセシビリティ** — *WCAG 2.2 POUR; Inclusive Design*
- Contrast **4.5:1** body / **3:1** large & non-text (1.4.3/1.4.11); **target ≥ 24×24px** (2.5.8); keyboard reachable, visible focus, no traps; **not color alone** (1.4.1). Inclusive Design persona spectrum (situational/temporary too).

**15. モチベーション・オンボーディング** — *Goal-Gradient; Zeigarnik; Serial Position; HEART*
- Show **progress/completion/momentum** (Goal-Gradient, Zeigarnik). **Serial Position / Von Restorff** — place & isolate the key action. Fast path to the **aha moment**. Optionally frame with **HEART** (Goals→Signals→Metrics).

## Step 3 — Execute the review (pick A or B from Step 0)

### 3A. Quick (single-pass)
Walk every applicable lens yourself against the captured screens + source. Produce findings in the Step 4 shape. Go to Step 4.

### 3B. Deep (specialist panel — fan-out, like code-review)
One sub-agent per specialist owns a lens-group, so each reviews with a single focused mindset (real design teams split this way → higher precision). **Launch all five in parallel** (multiple `Agent` calls in one message, `subagent_type: general-purpose`). Each agent **reports only — never edits code**.

| Specialist | Lenses | 担当 |
|---|---|---|
| **P1 構造アーキテクト** | 1, 2, 12 | IA・ジャーニー・一貫性 |
| **P2 行動・インタラクション** | 3, 4, 5, 6 | フロー・操作・認知負荷・倫理 |
| **P3 状態・信頼** | 7, 13 | エッジ状態・安全性 |
| **P4 表現** | 8, 9, 10, 11 | ビジュアル・文言・データ可視化・感情 |
| **P5 アクセシビリティ・動機** | 14, 15 | a11y・オンボーディング |

Give each agent this prompt (fill the braces; `{skill_path}` = the absolute path to this very SKILL.md — this is a global skill, so it's `~/.claude/skills/design-review/SKILL.md`, expanded to a real absolute path):

```
You are a focused design reviewer: {specialist name}, owning lenses {#s}.
Read the lens definitions in {skill_path} (Step 2,
lenses {#s}) — that is your checklist; cite those named principles.

Look at the rendered UI by Reading these screenshot files (they are images):
{paths}. You may capture additional states with Playwright if a lens needs one
not provided, but reuse the saved shots first.
Source files: {paths}. Scope under review: {one line}.

For YOUR lenses only, return findings in EXACTLY this line format:
<🔴|🟠|🟡|⚪> [<lens#> · <principle>] <screen/location> — <observation>。なぜ → <impact>。直し方 → <fix> (file:line)
Then a 「良い点」 list (1–3) and, for any conditional lens, 「対象外（該当なし）」.
Severity = Nielsen 0–4 (frequency × impact × persistence). Cite a named
principle in every finding. Behavioral guesses get 要検証: <method>.
Do NOT modify any files. Report only.
```

Then **you (orchestrator) merge**:
- Collect all agents' findings. **Dedupe** cross-domain overlaps (one issue can surface in two lenses — keep once, cross-tag the lenses).
- **Re-rank globally** by severity; pick the global 「最初に直す3つ」.
- Synthesize a combined 「良い点」 (drop duplicates).
- If an agent failed / returned nothing, note it and (optionally) cover that lens-group yourself before reporting — don't silently drop lenses.

## Step 4 — Severity (Nielsen scale)

severity ≈ frequency × impact × persistence. User-facing labels:

| 表示 | Nielsen | 意味 |
|---|---|---|
| 🔴 **致命** | 4 catastrophe | blocks the job / loses data / actively misleads / manipulates — must fix |
| 🟠 **重要** | 3 major | most users hit real friction or confusion — high priority |
| 🟡 **軽微** | 2 minor | noticeable rough edge — low priority |
| ⚪ **好み** | 1 cosmetic | taste/polish — fix if time permits |

Finding line: `<severity> [<lens#> · <principle>] <location> — <observation>。なぜ → <impact>。直し方 → <fix> (file:line)`. Name the principle (`Hick's Law`, `Gestalt: proximity`, `Nielsen #1`, `WCAG 1.4.3`, `dark pattern: confirmshaming`). No vague "improve UX".

## Step 5 — Report (Japanese, user-facing)

```
## デザインレビュー: <対象>
（深さ: quick / deep・専門家パネル ｜ 見た方法: スクショ / 起動プレビュー / harness / コードのみ）

### 最初に直す3つ
1. …  2. …  3. …   ← 致命・重要から、効果の大きい順

### 観点別の指摘
**1. 情報設計** … （Core lens は全て。指摘ゼロは「問題なし」一行。Conditional は「対象外（該当なし）」）
…

### 良い点
（壊さないために残すべき判断を 1〜3 行）
```

Lead with 「最初に直す3つ」. Cover every Core lens; mark Conditional ones applied or `対象外`. Always include 良い点.

## Step 6 — Offer to fix (gated)

Do **not** auto-apply (design fixes are subjective). Ask via `AskUserQuestion`: 「致命・重要だけ直す」 / 「指摘を全部直す」 / 「報告だけでよい」. If a fix option is chosen, apply only those findings, run the project's typecheck/build, and re-screenshot the changed screens to show the after-state. (Fixing is always done by you, the orchestrator — the review sub-agents never edit.)

## Reference canon (cite these in findings)

**Laws of UX** (Yablonski) — Hick · Fitts · Jakob · Miller · Tesler · Doherty (<400 ms) · Postel · Peak-End · Goal-Gradient · Zeigarnik · Serial Position · Von Restorff · Aesthetic-Usability · Prägnanz + Gestalt.

**Heuristic sets** — Nielsen's 10 (status · real-world match · control & freedom/undo · consistency · error prevention · recognition>recall · flexibility · minimalist · error recovery · help). Shneiderman's 8 Golden Rules. Norman (affordance · signifier · mapping · feedback · constraints · conceptual model; Gulfs of Execution/Evaluation; 7 stages of action).

**IA & service** — Rosenfeld & Morville (organization / labeling / navigation / search; exact vs. ambiguous; hierarchy / hypertext / faceted). Information Foraging & **scent** (Pirolli & Card). Service blueprint · journey map · moments of truth · front/back stage. Validate: card sort · tree test · first-click.

**Behavior & ethics** — Jobs-To-Be-Done & job stories (Christensen, Ulwick, Moesta). Krug — *Don't Make Me Think*, satisficing. Cognitive Load Theory (intrinsic/extraneous/germane). Nudge & choice architecture (Thaler & Sunstein). Fogg **B = MAP**. Cialdini's 6 (reciprocity · commitment · social proof · authority · liking · scarcity). **Dark patterns** (Brignull) — confirmshaming, forced continuity, sneaking, obstruction, misdirection, fake urgency. Hooked (Eyal) — habit loops, use ethically.

**Expression** — Gestalt; CRAP (Robin Williams); typographic measure/scale; 8-pt grid; squint test. Content design / UX writing (plain language, voice & tone). Emotional design — visceral/behavioral/reflective (Norman). Calm Technology (Weiser/Case). Information design & data-ink (Tufte); Bertin's visual variables.

**System & accessibility** — Design systems / Atomic Design (Brad Frost). WCAG 2.2 POUR, A/AA/AAA; contrast 4.5:1 / 3:1; target 24px (2.5.8); not-color-alone (1.4.1). Microsoft Inclusive Design — persona spectrum.

**Process / measurement** — Design Thinking; Double Diamond; Human-Centered Design (ISO 9241-210); Lean UX; Design Sprint. Heuristic evaluation · cognitive walkthrough · usability testing (~5 users). HEART + Goals-Signals-Metrics; SUS; North Star.

## Rules
- Every finding cites a named principle — that's what separates this from taste.
- Reviewing ≠ redesigning. Report first; change code only at Step 6 on the user's choice.
- **Deep mode is opt-in** (scope or explicit ask) — don't spawn a 5-agent panel for a tiny review. Review sub-agents **report only; never edit**.
- One finding = one concrete, locatable problem; behavioral guesses are labeled `要検証`.
- The **dark-pattern audit (lens 6) is never skipped** — manipulation is a defect even when it converts.
- Don't manufacture visual findings you couldn't see — if code-only, scope the claim.
- Respect the project's established design language (its CLAUDE.md / tokens). A finding must improve *this* product, not push it toward a generic aesthetic. The canon serves the product.
- Save screenshots under `.playwright-mcp/`; remove throwaway harnesses when done.
