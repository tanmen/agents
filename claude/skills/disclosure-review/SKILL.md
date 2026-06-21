---
name: disclosure-review
description: Information-density & progressive-disclosure review and fix loop — measure how much information competes at first glance (visible interactive elements, top-level chunks, choices per decision point), build a frequency×visibility tier map (high-frequency info stays visible, secondary info moves behind tooltips/popovers/dialogs/sheets/drawers/accordions chosen by a surface-fit table), apply the re-tiering with the project's existing overlay components, then verify BOTH directions — at-rest density went down AND the interaction cost of frequent tasks did not go up — plus WCAG 1.4.13 / focus / Escape checks on every new overlay. Grounded in progressive disclosure (Nielsen), details-on-demand (Shneiderman), Hick's law, chunking (Cowan 4±1), information scent (Pirolli), interaction cost. Use when the user wants the at-a-glance information amount reduced/controlled — e.g. 「情報量を減らして」「パッと見をすっきりさせて」「ごちゃごちゃしているので整理して」「詳細はツールチップやドロワーに逃がして」「段階的開示にして」. NOT for placement/scan-path of what stays visible (→ flow-layout), step/journey re-sequencing (→ journey-redesign), copy shortening (→ ux-writing-review), or pixel-level legibility (→ readability-review).
---

# /disclosure-review — tier the information, then prove both directions

A cluttered screen and an over-hidden screen are the same failure in opposite directions: information sitting at the wrong **visibility tier** for its usage frequency. This skill measures the at-rest density, assigns every information item a tier, moves demoted items behind the right on-demand surface — and then proves the cure didn't poison the frequent path, because hiding is never free (interaction cost; out of sight, out of mind).

Lane boundaries — this skill decides **what is visible at rest and behind which surface the rest lives**; it does not decide where visible things sit:

- Arranging/placing what remains visible, page/step splitting → `flow-layout` (run it AFTER this skill when both are needed: tier first, then place)
- Which steps exist in what order → `journey-redesign`
- Making individual strings shorter → `ux-writing-review` (demoting a paragraph behind a 「詳細」 disclosure is this skill; rewriting it is not)
- Contrast/size of what's shown → `readability-review`

## Step 0 — Scope, scenarios, component inventory

`$ARGUMENTS` may name screens or a complaint. Empty → the app's primary screens.

- Read `docs/ux/scenarios.md` if present — **frequency × importance per scenario is the input that decides tiers**. Absent → offer `/ux-discovery`, or derive frequency rankings from the UI itself (primary nav, defaults) and mark every tier decision 要検証.
- Inventory the project's existing overlay primitives now: Tooltip / Popover / Dialog / Sheet / Drawer / Accordion / disclosure components (component library, design system, or shadcn-style `components/ui`). Fixes must reuse these. If a needed surface type has no existing component, say so at the gate — don't pull a new dependency silently.
- Get a running preview reachable by Playwright MCP. Artifacts go under `.playwright-mcp/disclosure/` (gitignored).

## Step 1 — Capture and inventory the visible information

Screenshot each target screen (default + 375px) to `.playwright-mcp/disclosure/<screen>-before.png`. Then via `browser_evaluate`, inventory what competes at rest, per screen and per viewport-above-the-fold:

- visible interactive elements (buttons, links, inputs)
- top-level visual chunks (distinct groups at the first hierarchy level)
- choices at each single decision point (items in one toolbar/menu/row of actions)
- text blocks visible without interaction, with rough length
- already-hidden surfaces (existing tooltips/menus/drawers) and what's inside them

Every later claim about density cites these counts.

## Step 2 — Measure and judge against named criteria

**a. Density (is too much visible?)** — flag with the count + the named basis; these are conventions, not laws, so pair each with the scenario evidence:

| Check | Guideline | Authority |
|---|---|---|
| Top-level chunks per screen | > 5 competing groups → flag | chunking, Cowan 4±1 |
| Choices at one decision point | > 7 undifferentiated options → flag | Hick's law / Miller |
| Primary-scenario relevance | visible items irrelevant to the top scenarios' goals → demotion candidates | progressive disclosure (Nielsen) |
| Always-visible detail text | paragraphs of reference/help text at rest → demotion candidates | details-on-demand (Shneiderman) |

**b. Over-hiding (is the wrong thing hidden?)** — the symmetric check, same severity scale:

- Information or actions needed in a high-frequency scenario sitting ≥ 2 interactions deep, or inside hover-only surfaces (touch can't hover) — interaction cost violation
- A hidden surface whose trigger label doesn't predict its content (weak information scent — the user can't know to look there)
- Essential content (errors, prices, destructive consequences) inside a tooltip — essential info may never be hover-only

**c. Surface misfit and mechanics (is the hiding done right?)** — against the surface-fit table (Step 3) plus measurable mechanics:

- WCAG 1.4.13 on every hover/focus surface: dismissable (Esc), hoverable (pointer can move onto it), persistent (no timeout)
- Overlay mechanics: Escape closes, focus moves in and returns, background scroll handled, reachable on touch and keyboard

Each finding: 高 (blocks the primary scenario or violates 1.4.13) / 中 (slows) / 低 (polish), with the count or observed behavior + screenshot path. No count/observation → drop the finding.

## Step 3 — The tier map and surface choices

Assign every inventoried item a tier from its frequency × importance (scenario-grounded; mark 要検証 where frequency is assumed):

| Tier | Rule | Where it lives |
|---|---|---|
| 1 常時表示 | needed in the top scenarios' main path | on the screen (placement → flow-layout) |
| 2 ワンアクション開示 | regularly needed, not always | popover / accordion / 「詳細」 disclosure / drawer |
| 3 要求時のみ | occasional, reference, edge-case | dialog / sheet / secondary page |
| 補足ヒント | helpful but never essential | tooltip (and only this goes in tooltips) |

Surface-fit rules for demoted items (Material/HIG conventions): **tooltip** = one-line supplemental hint, no interaction inside, never essential; **popover** = small contextual detail, light interaction; **dialog/modal** = a blocking decision or confirmation, one job; **sheet** (mobile) = contextual subtask without leaving the screen; **drawer** = supplementary list/detail keeping page context; **accordion/show-more** = optional long-form content in reading flow. Misfits to call out: forms inside tooltips, simple confirms occupying full pages, navigation buried in modals.

Every demotion names its trigger label and checks it carries scent (the label must predict the content — if no honest label exists, the item probably belongs visible). Output: a before/after tier table (item, current tier, proposed tier, surface, trigger label, 確証度).

## Step 4 — Gate

`AskUserQuestion`, options in Japanese:

- 「高頻度シナリオ基準で適用(おまかせ)」 (Recommended)
- 「Tier 移動を選んで適用」 — then a follow-up multiSelect listing the demotions/promotions
- 「提案だけでよい(自分で実装)」

Skip the gate when the user already said おまかせ/全部, or is running unattended (then apply 高-severity items only). If a needed surface component doesn't exist in the project, surface that decision here.

## Step 5 — Apply

- Reuse the Step 0 component inventory — project primitives, project tokens, no new dependencies without the gate's approval.
- Demotions move content as-is; don't rewrite it while moving (→ `ux-writing-review`). Promotions (un-hiding over-hidden items) place minimally and note that final placement is `flow-layout`'s job.
- Wire each new overlay correctly from the start: Escape, focus management, touch/keyboard reachability, 1.4.13 for hover surfaces — these are findings-in-waiting otherwise.
- One tier-move per edit; don't bundle a restyle into a demotion.

## Step 6 — Verify both directions, loop if needed

The point of the skill — a density fix that taxes the frequent path is a failure:

1. **Density re-count**: re-run the Step 1 inventory; emit before/after counts per screen (chunks, interactive elements, choices per decision point) ✅/❌ against the Step 2 flags
2. **Interaction-cost walk**: drive the top scenarios via Playwright; for each piece of information/action used in them, count interactions-to-reach before vs after — frequent-path cost must not increase ❌ if it did
3. **Mechanics check** on every new/changed overlay: Escape, focus return, touch reachability, 1.4.13 triple
4. Re-screenshot to `.playwright-mcp/disclosure/<screen>-after.png`; quick 5-second re-test on the after-screenshot (the de-densified screen should now answer ①②③ faster, not slower)

Failures loop back to Step 5 — **cap 3 passes**, then report remaining ❌ rows honestly. Close with: the tier table as applied, before/after density counts, the interaction-cost table, mechanics results, after-screenshot paths, and handoffs (flow-layout for placement of the surviving tier-1 set) in one line each.

## Don't

- Don't hide by feel — every demotion cites the tier rule + frequency evidence (or 要検証), every density flag cites a count
- Don't put essential or interactive content in tooltips, and don't create hover-only paths to anything a touch user needs
- Don't demote anything used in a top scenario's main path, whatever the density win
- Don't ship an overlay without Escape/focus/touch/1.4.13 wiring
- Don't rewrite copy while moving it, re-place the visible remainder (→ flow-layout), or restyle (→ frontend-design)
- Don't add a new overlay library when the project has primitives — and never silently
- Don't claim success without the Step 6 both-direction numbers; don't loop past 3 passes
- Don't auto-commit; let the user invoke `/commit`

## Why this skill exists

「ごちゃごちゃしてるので整理して」 otherwise produces one-directional cleanup: things get hidden until the screenshot looks calm, frequent actions quietly cost two extra clicks, tooltips carry essential info that touch users never see, and nobody measured any of it. Forcing inventory → frequency-based tiers → surface-fit rules → both-direction verification makes density work falsifiable, and the symmetric over-hiding checks keep "less visible" from silently becoming "less usable".
