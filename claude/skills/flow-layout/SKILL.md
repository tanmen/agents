---
name: flow-layout
description: Scenario-driven attention-flow & layout optimization. Define the user's concrete scenarios, simulate the gaze/scan path per screen (F / Z / Gutenberg / layer-cake patterns + visual weight), quantify gaze travel cost (fixations-to-goal, regressions, distractor pull), AND check the orthogonal second axis — information structure / glanceability (is the screen understandable at a glance without prose: category encoding, visual hierarchy, grouping, data-to-form fit, self-evidence), gated by a 5-second test. Then redesign page/step splitting and the placement of buttons & components so the primary action sits on the scan terminus, gaze movement is minimized, AND the structure reads at a glance. Consumes the scenarios + 5-second answer keys from ux-discovery (docs/ux/scenarios.md) when present. Generative — produces a concrete before/after HTML wireframe (rendered/screenshotted, not ASCII) + placement spec, and (gated) applies the code edits. Works on existing UI (screenshots) or greenfield from scenarios alone. Use when the user wants to improve 導線・視線の流れ・ボタンや要素の配置・ページの分け方・レイアウト設計・画面遷移の使い勝手, or says 「導線を見直して」「配置を最適化して」「視線の流れを見て」「ページの分け方を考えて」「レイアウトを設計し直して」「使いやすくするために配置を変えて」. For a broad heuristic audit across the whole UX canon (Nielsen, ethics, a11y, content…) use design-review; for visual aesthetics / look-and-feel generation use frontend-design.
---

# /flow-layout — scenario → gaze → placement & page-split (generative)

Given concrete user scenarios, this skill **simulates where the eye goes on each screen**, **measures how far it has to travel** to reach the goal, and then **rearranges placement and splits pages** so the primary action lands on the natural scan terminus with the least gaze movement. It **produces a new layout** (before/after **HTML wireframe** + placement spec) and, on approval, edits the code — it does not stop at critique.

**Lane** (keep these distinct, cross-link when one fits better):
- **flow-layout** (this) — one axis, deep & generative: *scenario → attention → spatial layout, page/step split, placement*. Optimizes the **path of the eye and the structure of the screens**.
- **design-review** — broad heuristic audit across the whole UX canon (15 lenses, ethics, a11y, content). Critique-first, names principles. Use it for a *wide* pass; use this for *layout/flow surgery*.
- **frontend-design** — visual aesthetics (type, color, motion, atmosphere). This skill decides *where things go and how the screen is split*; frontend-design decides *how it looks*. Hand off to it for the visual layer.

---

## Step 0 — Mode & scope

`$ARGUMENTS` may name a target (a screen, a flow like "signup→first value", a component) and/or a device.

Pick the **mode** (state which + why, one line):
- **improve** — an existing UI to rework. Default when there's running code / screenshots / a repo.
- **plan** — greenfield: no UI yet, design the layout & page-split from scenarios before code exists. The output is a spec/wireframe to hand to frontend-design.

If the user hasn't said, infer from whether a renderable UI exists, and state your assumption.

Pick the **scope** (state it + the scenario list in one line before proceeding):
- **target given** (`$ARGUMENTS` names a screen / flow / component) → focus there under its dominant scenario; flag cross-cutting issues you pass.
- **no target → ask which scenarios to run.** Read the ranked scenarios from `docs/ux/scenarios.md` and present them via `AskUserQuestion` (multiSelect; options = the top scenarios with their *frequency × importance*, plus an 「重要シナリオおまかせ（上位3）」 choice). Run only what the user picks; each picked scenario is analyzed independently (fan-out, per the guardrail below). **Skip the ask and default to the top ~3** when the user already named the scenario(s)/flow, said 「全部 / おまかせ」, or only one scenario exists. If `docs/ux/scenarios.md` is absent there's nothing to choose from — offer to run `/ux-discovery` first, or ask the user to name the top scenario inline. Covering several scenarios is the heavier *wide* pass (like design-review's deep mode) — say so.

**Precision guardrail — fan out, don't blend.** This skill's power is a *single sharp optimization target* per screen (the goal element on the scan terminus). Optimizing one screen for several scenarios at once averages them into the flat, undifferentiated layout this skill exists to kill — precision drops. So in wide scope, **analyze each scenario independently (its own goal element, its own before/after)**. Where 2+ important scenarios contest the *same* screen, make the **conflict a first-class finding** and resolve it structurally (role-based / separate view / progressive disclosure / mode switch), never by compromise. For many scenarios or an explicit 「精度高く / deep」, **fan out one sub-agent per scenario** (`general-purpose`, runs Steps 3–5 for its scenario only — one sharp target keeps precision high), then merge: dedupe screens two scenarios share and rank the combined fixes. Don't spawn the panel for 1–2 scenarios.

## Step 1 — Define the scenarios (mandatory, FIRST — this is the spine)

**No layout reasoning happens without a concrete scenario and its goal element.** Generic "make it usable" produces generic results — that is exactly why a broad review feels ineffective here. Anchor everything to 1–3 named scenarios.

**Source the scenarios — don't re-derive them ad hoc:**
- If **`docs/ux/scenarios.md`** exists (the `ux-discovery` artifact), **read it and use it as the spine** — its personas, prioritized job stories, **goal elements**, and **5-second-test answer keys** are the authoritative input for Steps 3–5. Don't reinvent them.
- If it doesn't exist: for anything beyond a tiny tweak, **offer to run `/ux-discovery` first** (it produces exactly this input). If the user declines or it's a quick pass, **infer the top scenario inline and label it `質低・要検証`** — and note the 5-second answer key is your assumption, not researched.

Each scenario you work from must carry a **job story**: *"When [situation], the user wants to [motivation], so they can [outcome]."* and the fields that change the layout:

- **Who** — expertise (first-timer vs. power user), so recognition-vs-recall and density change.
- **Context** — **device** (mobile thumb-zone vs. desktop mouse-travel — placement depends on this), urgency, one-shot vs. habitual, frequency.
- **The goal element** — the single control/content that *completes* this scenario (the "Buy" button, the answer, the "Next" step). This is the **target the eye must reach**; everything in Steps 3–4 is measured against it.
- **Trigger → steps → success** — the rough sequence of screens this scenario crosses.

**Rank** scenarios by *frequency × importance* (use the artifact's ranking if present). In **target scope**, optimize for the top scenario and verify the rest aren't pessimized (state the trade-off). In **wide scope** (Step 0), carry forward the scenarios the user picked (default top ~3) and analyze each **independently** in Steps 3–5 (one before/after per scenario) — do not merge them into a single averaged layout.

## Step 2 — Build the canvas (a region map you can reason over spatially)

Spatial claims need a spatial artifact — never reason about placement from imagination alone.

- **improve mode**: capture the **rendered** screens (this matters more than source). In order of preference:
  1. **User screenshots** (best signal).
  2. **Running preview via Playwright MCP** — `browser_navigate` + `browser_take_screenshot` to `.playwright-mcp/<screen>-<state>.png`. Use a realistic viewport **matching the scenario's device**. Capture the states the scenario actually hits.
  3. **Component harness** — render the real component with data mocked, screenshot, then remove.
  4. **Code-only fallback** — read the JSX/markup + styles and reconstruct the layout; **state that placement findings are inferred from code, not seen**.
- **plan mode**: there is no UI — sketch the proposed regions directly from the scenario.

Either way, end Step 2 with a **region map** per key screen: a coarse grid (e.g. header / hero / main / aside / footer, or a 3×3) listing **what sits in each region** and its **visual weight** (size, contrast, color, motion, isolation). This map — not the pixels — is what Steps 3–4 operate on.

## Step 3 — Analyze on two axes (per scenario × screen)

Two metrics must **both** hold — they're orthogonal, and optimizing only the first is the classic trap: a fast-to-traverse but *flat, undifferentiated* screen, where every kind of information looks the same and you end up explaining it with prose.
- **3A 経路 (path)** — how *little* the eye must travel to reach the goal (視線の移動量).
- **3B 構造 (structure)** — whether the screen is understandable *at a glance, without reading prose* (一目瞭然性 / glanceability).

### 3A. 経路 (path) — gaze / scan cost — 視線の移動量

For each screen the top scenario touches, predict the eye's route and **measure it**:

1. **Entry fixation** — where does the eye land first? Driven by **visual weight**: size · contrast · warm/saturated color · position (top-left in LTR, optical center) · faces · motion · **isolation (Von Restorff)**. Name the winner.
2. **Scan model** — pick the one that fits the layout type, don't assume F by default:
   - **F-pattern** — text/list/feed-heavy screens (eye runs along top, then down the left, scanning right in decreasing depth).
   - **Z-pattern** — sparse screens / landing pages with few elements (top-left → top-right → diagonal → bottom-right).
   - **Gutenberg diagram** — evenly-weighted dense screens: primary optical area = top-left, **terminal area = bottom-right** (where the eye exits → put the commit action there), with two weak "fallow" corners.
   - **Layer-cake** — scannable headings/sections (eye hops heading to heading).
   - **Spotted / commitment** — search tasks where the eye hunts a known target, ignoring the rest.
3. **Scan sequence** — write the ordered fixations from entry to the **goal element** (Step 1).
4. **Gaze cost** (the metric — lower is better):
   - **Fixations-to-goal** — how many stops before the eye reaches the goal element. Aim for #1–2 on its screen for the primary scenario, or the pattern's terminus for "read-then-act" flows.
   - **Travel** — sum of saccade lengths, in region-map units (short / medium / long).
   - **Regressions** — backward jumps (eye returns to an already-scanned region). Each one is a friction signal: misleading information scent, weak grouping, or the goal not where the pattern predicts.
   - **Distractor pull** — high-weight elements *off* the goal path that steal fixations (competing CTAs, ads, decorative motion, second primary button).
5. **Direction cues** — do faces / arrows / leading lines / whitespace funnels point *toward* the goal, or away?

**Verdict (3A) per screen**: is the goal element on the natural scan terminus at minimal cost? Where is the friction (high fixation count / regressions / distractor pull)? Note that gaze cost is a **model-based estimate, not eye-tracking** — if certainty matters, label it `要検証` (5-user test / first-click test / heatmap tool).

### 3B. 構造 (structure) — glanceability — 一目で分かるか

Path tells you nothing about whether the screen *communicates*. Check whether the structure is visible **without prose**. Six checks (cite the model; keep to these — this is not a full canon audit, that's `design-review`):

1. **カテゴリの符号化** *(Bertin の視覚変数 / preattentive attributes (Ware) / Tufte)* — are *different kinds* of information distinguishable **without reading** them (by position, color, shape, size, container)? If everything shares one treatment, the user must read to classify → prose dependence. Use **redundant coding** (色＋アイコン＋語) for states.
2. **視覚的階層（squint test）** — squint at the screen: do primary / secondary / tertiary separate by weight? A clean scan path over a *flat* hierarchy still forces reading everything.
3. **グルーピング＝意味** *(Gestalt: proximity / common region)* — related items bound (proximity, card, divider, shared whitespace); unrelated ones separated. 「情報が混ざる」 is a grouping failure — fix it **spatially**, not with labels.
4. **データ⇄形の一致** *(information design / Tufte data-ink)* — does the form mirror the data's shape? comparison→side-by-side, hierarchy→nesting/indent, sequence→timeline, tabular→table. A mismatch is what forces explanatory copy. Strip chartjunk / redundant chrome.
5. **自己説明性 (show-don't-tell)** *(Norman: affordance / signifier; Krug)* — can the user tell what's clickable / editable / where they are *without* tooltips or paragraphs? If copy is *carrying* the meaning rather than *confirming* it, the form failed.
6. **signal-to-noise / 段階的開示** — showing everything at once *is* the mixing. Default to the essentials; reveal detail on demand. Remove noise (duplicate info, decorative borders, over-chrome).

**5-second test (the gate)** — score the screen against its **answer key** (from `docs/ux/scenarios.md` Step 4, or your labeled assumption): can a first-time user, *without reading body text*, state in ~5s ① これは何の画面か ② 一番大事なものは何か ③ 次に何をすればいいか? **If any answer requires reading prose → fail.** A failed gate is a **構造 finding**, not a copy problem — the fix is encoding / hierarchy / grouping / form, not more words.

## Step 4 — Redesign moves (the toolbox; every move cites a model AND a measurable effect)

Choose moves that cut the gaze cost / step count (3A) or make the structure legible (3B). Four groups:

**A. Placement (配置)** — *Fitts · Gestalt · visual hierarchy · Von Restorff · thumb-zone*
- Put the **primary action on the scan terminus** (Z bottom-right / Gutenberg terminal / end of the F's relevant row); one primary action per screen — demote the rest.
- **Raise the goal's weight, lower the distractors'** (size/contrast) so it wins the entry fixation or sits unmissable on the path.
- **Group related controls by proximity** (Gestalt) so the eye treats them as one unit — kills regressions caused by scattered related fields.
- **Fitts**: primary targets large and near the eye's resting point; **separate destructive actions** from primary by distance (and add an undo/confirm) so a mis-click can't be catastrophic.
- **Align to a grid** — misalignment causes the eye to re-fixate; alignment lets it flow.
- **Device**: mobile → primary action in the **thumb-zone** (bottom reach arc); desktop → minimize mouse travel from the content to its action. Reachability follows the scenario's device from Step 1.
- Add **direction cues** (a face/arrow/leading line) to funnel the eye to the goal.

**B. Page / step split (ページの分け方)** — *Miller · progressive disclosure · goal-gradient*
- **Chunk** content into ~5–9 units (Miller); hide secondary detail behind **progressive disclosure**.
- **Single page vs. wizard** — split into steps when: many fields, sequential dependency, high error/commit cost, or each step needs focus. Keep one page when: the user needs an **overview**, must **compare**, or the task is short. Decide explicitly per scenario.
- **Above-the-fold budget** — for each scenario, what must be visible without scroll? Put the goal (or a clear path to it) there.
- When you split, **show progress** (goal-gradient / Zeigarnik) and **carry context forward** — never drop the user's prior input between steps.

**C. Cross-screen flow (導線)** — *information scent · journey continuity*
- **Minimize the screen count on the top scenario's happy path** — every extra screen is gaze + decision cost.
- Nav/link labels carry honest **information scent** (predict what's behind them) so the user finds, not wanders.
- No dead-ends or double-backs; each screen says what's next.

**D. Structure / encoding (構造の可視化)** — *visual variables · Gestalt · information design* (fixes 3B failures)
- **Encode categories** so kinds of info differ pre-attentively — give each a consistent color/shape/container; don't make the label do the sorting.
- **Build hierarchy** — size/weight/contrast so primary > secondary > tertiary passes the squint test; demote chrome.
- **Group by meaning** — proximity / common region / dividers so related fields read as one unit and unrelated ones visibly separate.
- **Match form to data** — pick the structure that mirrors the data (table / nesting / timeline / side-by-side) instead of a generic stack that needs captions.
- **Cut noise** — progressive disclosure for secondary detail; remove redundant chrome to raise signal. Every cut should make the 5-second answer *easier*.

State the trade-off when a move helps one axis but hurts the other (e.g. denser packing cuts gaze travel but blurs categories), or helps the top scenario but touches a secondary one. **Both axes must end up satisfied — never buy a shorter scan path with a less legible structure, or vice versa.**

## Step 5 — Output (before/after, concrete & measurable)

**Render the layout preview as HTML, never ASCII.** ASCII boxes collapse under full-width Japanese (がたがた) — don't use them. The preview is a **low-fidelity grey-box wireframe** (it argues *placement, scan path, structure* — not aesthetics; that's frontend-design's job).

Per key screen:

1. Write a **self-contained HTML wireframe** to `.playwright-mcp/flow-layout/<screen>.html` (inline CSS, no external deps, system JP font). **Before and After side by side**, each in a viewport frame, showing:
   - one positioned **box per region/element**, sized & shaded for **visual weight**, with a Japanese label;
   - **category encoding** by box color/border so 3B is visible at a glance (different kinds look different);
   - the **goal element** marked (accent outline);
   - the **scan path** as numbered badges ①②③… in fixation order over the boxes;
   - a **metrics panel** under each frame: 経路 (fixation/travel/regression) ・ 構造 (カテゴリ分離/階層/5秒テスト ◯✕) ・ 削減.
2. **Render & screenshot it so the user sees it inline.** Playwright MCP **blocks `file://`**, so serve the dir over a throwaway local server (`python3 -m http.server <port>` in the background, pick a free port) and `browser_navigate` to `http://localhost:<port>/<screen>.html`, then `browser_take_screenshot` (`fullPage`) — its `filename` is relative to the **project root**, so pass `.playwright-mcp/flow-layout/<screen>.png`. Read the PNG back to show it, then stop the server. (No Playwright → just give the user the HTML file path to open.) Both files sit under the gitignored `.playwright-mcp/`.
3. Keep the **placement spec as a Markdown table** (tables render cleanly — leave them as text).

For **plan mode**: render only the After frame as the proposed wireframe.

In **all-scenarios scope**: produce one before/after set (HTML + spec) **per scenario**, dedupe any screen two scenarios share (analyze it once, note both scenarios + their conflict), and lead with a single cross-scenario **「最初に直す3つ」** ranked by severity × reach.

Markdown wrapper for the written report (the visual goes in the HTML/PNG above):
````
## レイアウト改善: <対象>
（モード: improve / plan ｜ 対象デバイス: … ｜ 見た方法: スクショ / 起動プレビュー / コードのみ）
プレビュー: .playwright-mcp/flow-layout/<screen>.png  （HTML: …/<screen>.html）

### シナリオ（最適化の軸）
1. [主] When … , wants to … , so … 。ゴール要素: <X>（頻度×重要度: 高）

### 配置仕様（element → from → to → 根拠）
| 要素 | 現在 | 変更後 | 根拠（モデル＋効果） |
|---|---|---|---|
| 主CTA | 中段に埋没 | Z終端(右下) | Z-pattern終端／fixation 5→2 |
| 状態表示 | 文字のみ | 色＋アイコン＋語 | 符号化／5秒テスト ✕→◯ |
| 12項目フォーム | 1ページ | 3ステップ×4＋進捗 | Miller/分割／goal-gradient |
````

**HTML wireframe skeleton** (copy this, then position the boxes to match the real layout — keep it grey-box / low-fi):
```html
<!doctype html><html lang="ja"><meta charset="utf-8"><title>flow-layout</title>
<style>
 :root{font-family:system-ui,"Hiragino Kaku Gothic ProN","Noto Sans JP",sans-serif}
 body{margin:0;padding:24px;background:#f5f5f7;color:#1d1d1f}
 h1{font-size:16px;margin:0 0 16px} .row{display:flex;gap:32px;flex-wrap:wrap} .col{flex:1;min-width:340px}
 .col h2{font-size:13px;color:#666;margin:0 0 8px}
 .vp{position:relative;width:100%;aspect-ratio:16/10;background:#fff;border:1px solid #d2d2d7;border-radius:8px;overflow:hidden}
 .box{position:absolute;border:1px solid #c7c7cc;border-radius:6px;background:#f0f0f3;font-size:11px;padding:6px 8px;box-sizing:border-box}
 /* category encoding（3B）: 種類ごとに色を変える */
 .nav{background:#eef;border-color:#bcd} .data{background:#fff} .action{background:#e8f6ec;border-color:#9bd5ab} .meta{background:#faf6e8;border-color:#e6d79a}
 /* visual weight: 大きい/濃いほど primary */
 .w-hi{font-weight:700;font-size:13px;box-shadow:0 1px 3px rgba(0,0,0,.12)} .goal{outline:2px solid #ff6a00;outline-offset:1px}
 .gaze{position:absolute;width:20px;height:20px;border-radius:50%;background:#ff6a00;color:#fff;font-size:11px;font-weight:700;display:grid;place-items:center;transform:translate(-50%,-50%);z-index:5}
 .metrics{margin-top:10px;font-size:12px;line-height:1.7} .pass{color:#1a8f3c;font-weight:700} .fail{color:#c0392b;font-weight:700}
</style>
<h1>画面: 請求一覧</h1>
<div class="row">
 <div class="col"><h2>Before</h2>
  <div class="vp">
   <div class="box nav"   style="left:0;top:0;width:100%;height:12%">ヘッダ / ナビ</div>
   <div class="box data"  style="left:3%;top:16%;width:60%;height:70%">請求テーブル（全項目が同じ見た目で混在）</div>
   <div class="box meta"  style="left:66%;top:16%;width:31%;height:40%">補足・説明テキスト</div>
   <div class="box action w-hi goal" style="left:66%;top:60%;width:31%;height:14%">一括確定</div>
   <span class="gaze" style="left:8%;top:8%">1</span><span class="gaze" style="left:33%;top:50%">2</span>
   <span class="gaze" style="left:80%;top:36%">3</span><span class="gaze" style="left:82%;top:67%">4</span>
  </div>
  <div class="metrics">経路: fixation <b>4</b> / travel 長 / regression 1<br>構造: カテゴリ分離 弱 / 階層 flat / 5秒テスト <span class="fail">✕</span>（未確定件数が読まないと不明）</div>
 </div>
 <div class="col"><h2>After</h2>
  <div class="vp">
   <div class="box nav"  style="left:0;top:0;width:100%;height:12%">ヘッダ / ナビ</div>
   <div class="box meta w-hi" style="left:3%;top:16%;width:94%;height:14%">未確定 12件 / 確定済 88件（サマリ最上部）</div>
   <div class="box data" style="left:3%;top:33%;width:94%;height:42%">請求テーブル（状態を色＋アイコンで符号化）</div>
   <div class="box action w-hi goal" style="left:70%;top:80%;width:27%;height:12%">一括確定</div>
   <span class="gaze" style="left:50%;top:23%">1</span><span class="gaze" style="left:83%;top:86%">2</span>
  </div>
  <div class="metrics">経路: fixation <b>2</b> / travel 短 / regression 0<br>構造: カテゴリ分離 強 / 階層 明 / 5秒テスト <span class="pass">◯</span><br>削減: fixation 4→2、件数を最上部へ、状態を色符号化</div>
 </div>
</div>
</html>
```

Keep every number honest and model-based.

## Step 6 — Apply (gated)

Layout changes touch real markup, so don't auto-apply. Ask via `AskUserQuestion`:
- 「主要シナリオ分だけ適用」 / 「提案を全部適用」 / 「提案だけでよい（自分で実装）」 / 「frontend-design に渡して実装」

If an apply option is chosen: edit the markup/styles to realize the placement spec (**preserve the project's design tokens & aesthetic — you are moving things and re-splitting screens, not restyling**; restyling is frontend-design's job). Then run the project's typecheck/build, and **re-screenshot the changed screens** to show the after-state. Verify the new scan path actually holds in the rendered result.

In **plan mode** with no code: offer to invoke `frontend-design` to implement the proposed layout, or scaffold it.

## Reference models (cite these — the spatially-relevant subset)

**Scan / reading** — F-pattern, Z-pattern, Gutenberg diagram (primary optical / terminal / fallow areas), layer-cake, spotted/commitment pattern (Nielsen Norman Group eye-tracking). **Visual weight** — size · contrast · color · position/optical-center · faces · motion · isolation (Von Restorff). **Serial position** — first & last items are remembered/seen; place key items at the ends.

**Placement** — Fitts's Law (target size × distance; separate destructive from primary). Gestalt (proximity, similarity, common region, alignment) for grouping. Hick's Law (fewer competing choices → faster). Thumb-zone / reachability (Hoober) for mobile.

**Structure / page-split** — Miller (chunk ~5–9). Progressive disclosure (Krug, Nielsen). Goal-gradient & Zeigarnik (progress on split flows). Above-the-fold budgeting. Information scent / foraging (Pirolli & Card) for cross-screen nav.

**Legibility / encoding (3B — glanceability)** — Bertin's visual variables; preattentive attributes (Ware); redundant coding (color＋icon＋word). Tufte: data-ink, chartjunk, data-to-form fit. Gestalt used as *meaning* (proximity, common region) not decoration. Norman: affordance & signifier; Krug self-evidence. Squint test + the **5-second test** as the glanceability gate.

**Framing** — Jobs-To-Be-Done job stories (anchor every scenario). Squint test (does the visual hierarchy match the information hierarchy?).

## Rules
- **Scenario first, always — sourced, not guessed.** No placement claim without a named scenario and its goal element. Read `docs/ux/scenarios.md` (`ux-discovery`) when it exists; otherwise infer the top scenario and label it `質低・要検証`. The eye is measured against *that* goal.
- **Both axes must hold.** Optimize path (gaze cost) **and** structure (glanceability). A fast scan path over a flat, undifferentiated screen is a fail; shrinking gaze travel by cramming so categories blur is a fail. **The 5-second test is a mandatory gate before emitting the After** — if an answer needs prose, the layout isn't done.
- **Scope = sharp by default, wide by fan-out.** With a target, optimize the top scenario and don't pessimize the rest. With no target, **ask which scenarios to run** (`AskUserQuestion`; default to the top ~3 if the user defers or only one exists), then analyze each picked scenario **independently** — never blend several into one averaged layout (that recreates the flat screen this skill fights). Surface same-screen scenario conflicts as findings and resolve them structurally; state every trade-off.
- **Every move cites a model AND a measurable effect** (fixations / regressions / step count / target size) — never a vague "improve UX". This is the difference from a taste call.
- **Spatial claims need the rendered layout or an explicit region map.** Code-only → build the map from the markup and say findings are inferred, not seen. Don't hallucinate placement.
- **Gaze cost is a reasoned estimate, not data.** Label `要検証: <method>` when certainty matters (first-click / 5-user test / heatmap tool).
- **Stay in lane.** You change *placement, page-split, flow, and structural legibility* — not the visual style (→ frontend-design) and not a broad heuristic audit (→ design-review). The 3B checks are the focused subset that makes a layout self-evident; if broad UX/ethics/a11y/content issues surface beyond that, note them in one line and point to `/design-review`.
- **Respect the project's design tokens & CLAUDE.md** when applying. Moving and re-splitting must keep the established aesthetic.
- **Previews are HTML, never ASCII** (ASCII breaks under full-width Japanese). Low-fi grey-box only — styling is frontend-design's job. Save the HTML + its screenshot under `.playwright-mcp/flow-layout/` (gitignored); remove any throwaway harness when done.
