---
name: readability-review
description: Measurement-driven legibility review & fix loop for UI that is hard to read — capture rendered screens, MEASURE concrete values (contrast ratio, font size, line-height, line length, tap-target size) via Playwright, compare against named thresholds (WCAG 2.2, typographic conventions), fix at the CSS/design-token level only, then re-screenshot and re-measure to prove each fix numerically (capped at 3 passes). Use when the user says the UI is hard to read/see and wants it fixed — e.g. 「見にくいので直して」「見やすくして」「可読性を上げて」「文字が読みづらい」「コントラストを直して」「詰まって見える」. NOT for layout restructuring / page splitting (→ flow-layout), full heuristic audits (→ design-review), or aesthetic redesign (→ frontend-design).
---

# /readability-review — measure, judge, fix, re-measure

Legibility problems ("見にくい") almost always decompose into measurable violations: low contrast, small text, tight leading, overlong lines, cramped targets, color-only distinctions. So this skill **measures first and judges second** — a finding without a measured value, a named threshold, and an evidence screenshot is not allowed in Layer 1 output. Then it fixes, and **proves each fix by re-measuring**, never by claiming.

Scope is deliberately narrow: **CSS / design-token level changes only** (color, size, spacing, typography). Hand off when the problem is something else:

- Layout restructuring, page/step splitting, element placement, scan paths → `flow-layout`
- Broad heuristic audit across the whole UX canon → `design-review`
- Look-and-feel / aesthetic redesign → `frontend-design`

State the handoff in one line if you detect mid-review that the real problem is out of scope (e.g. "the contrast is fine; the issue is that 3 competing CTAs sit above the fold" → flow-layout territory). Finish the in-scope findings anyway.

## Step 0 — Scope and target states

`$ARGUMENTS` may name a screen, component, or route. Empty → the app's primary screens.

Decide the **state matrix** to capture. Legibility failures concentrate in non-default states, so always include, when the app supports them:

- default (light)
- dark mode — the most common place hard-coded grays break
- narrow viewport (375px wide) — wrapping, truncation, reflow (WCAG 1.4.10)
- a dense-data state (long list, long strings) if the screen renders user data

Also locate the styling ground truth now: design tokens / theme file / Tailwind config / CSS variables. Fixes in Step 5 must target these, not scatter literals. Note the file paths.

State scope + state matrix + token file in a few lines before proceeding.

## Step 1 — Capture rendered screens

Source-only review cannot see contrast or density. Get rendered screens saved to disk:

1. A running preview reachable by Playwright MCP → `browser_navigate`, set viewport per state, `browser_take_screenshot` to `.playwright-mcp/readability/<screen>-<state>-before.png`. Drive the UI (`browser_click` / `browser_evaluate`) to reach each state; toggle dark mode via the app's own switch or `browser_evaluate` on the documentElement class/media emulation.
2. No preview available → ask the user to start one, or render the component in a throwaway harness (then remove it). User-provided screenshots are acceptable evidence for Layer 2 but cannot feed Layer 1 measurement — say so.

If `.playwright-mcp/` is not in the repo's `.gitignore`, add it before the first screenshot.

## Step 2 — Layer 1: programmatic measurement

For each captured state, run measurements via `browser_evaluate`. Two passes:

**a. axe-core for contrast.** Inject axe (`https://cdn.jsdelivr.net/npm/axe-core@latest/axe.min.js`) and run with `runOnly: ['color-contrast']` — it composites translucent backgrounds correctly, which naive foreground/background reads get wrong. Collect: selector, fg/bg hex, computed ratio, required ratio.

**b. Custom typography/target script.** Write a `browser_evaluate` script that walks visible elements and reports, per violation:

| Check | Threshold | Authority |
|---|---|---|
| Body text size | ≥ 16px (flag 14–15px as 中, < 14px as 高) | platform convention |
| Body line-height | ≥ 1.5 (CJK body: prefer ≥ 1.7) | WCAG 1.4.12 |
| Line length | ≤ 75ch Latin / ≤ 40 full-width chars CJK | typographic convention |
| Interactive target size | ≥ 24×24px hard floor, < 44×44px flagged as 中 | WCAG 2.5.8 / 2.5.5, HIG |
| Adjacent target spacing | ≥ 8px gap when either target < 44px | WCAG 2.5.8 |
| Distinct body font sizes on screen | ≤ 4 (more → inconsistent scale, 中) | type-scale convention |
| Text clipped/overflowing at 375px | none | WCAG 1.4.10 |

Use `getComputedStyle` + `getBoundingClientRect`; skip `visibility:hidden` / zero-size elements; for line length measure rendered chars per line, not source text length.

**Output format (Layer 1 finding — all fields mandatory):**

```
- [高] 本文コントラスト不足 — `.note-meta`: #9CA3AF on #FFFFFF = 2.54:1（必要 4.5:1 / WCAG 1.4.3）
  根拠: .playwright-mcp/readability/notes-default-before.png ／ 該当: src/styles/tokens.css:42
```

A candidate finding missing the measured value or the screenshot path gets dropped, not hedged.

## Step 3 — Layer 2: judgment-based legibility (screenshots)

Now look at the screenshots. This layer is explicitly judgment-based — separate it in the report under 「判断ベースの指摘」 and anchor each finding to a named principle:

- **Visual hierarchy** — is there exactly one clear primary element per screen? (Gestalt figure/ground; CRAP contrast)
- **Grouping** — do related items read as groups via proximity/whitespace, or does everything sit at uniform spacing? (Gestalt proximity)
- **Density** — text walls without paragraph spacing, tables without row breathing room (cognitive load)
- **Alignment** — mixed alignments creating ragged scan lines (CRAP alignment)
- **Color-only distinction** — state/category encoded by hue alone (WCAG 1.4.1; verify against the screenshot, e.g. error states)

No invented problems: every Layer 2 finding must point at something visible in a named screenshot file. Severity: 高 (blocks reading) / 中 (slows reading) / 低 (polish).

## Step 4 — Judge each finding

One line per finding, auto-review style:

- `Fix: <finding>` — measurable violation, or Layer 2 finding fixable at CSS/token level
- `Skip: <finding> — <reason>` — taste-level, requires DOM/layout restructuring (note the handoff skill), or intentional per the project's design language (check project CLAUDE.md / tokens before deciding)

Lean Fix for Layer 1 threshold violations — they are objective. Lean Skip when the fix would restructure markup.

## Step 5 — Apply fixes (CSS / tokens only)

- Prefer editing the design tokens / theme found in Step 0; touch component styles only when the violation is component-local. Never scatter hex/px literals when a token exists.
- Fixing contrast: keep the project's hue, adjust lightness until the ratio passes — don't swap to a foreign palette.
- One concern per edit; don't bundle a spacing rework into a contrast fix.
- Don't change copy, markup structure, or component composition.

## Step 6 — Verify by re-measuring, loop if needed

This step is the point of the skill. For every state captured in Step 1:

1. Re-screenshot to `.playwright-mcp/readability/<screen>-<state>-after.png`
2. Re-run the Step 2 measurements
3. Emit a before/after table: check, measured-before, measured-after, threshold, ✅/❌

A fix counts as done only when the re-measured number passes. If new violations appeared (e.g. a token change broke dark mode) or a fix didn't take (specificity, inline style), loop back to Step 5 — **cap 3 passes total**. At the cap, report remaining ❌ rows honestly with what blocked them.

Close with: the before/after table, the after-screenshot paths, Layer 2 fixes confirmed visually against the after-screenshots, and skipped findings with their handoff skill in one line each.

## Don't

- Don't emit a Layer 1 finding without a measured value + threshold + screenshot path — drop it instead
- Don't claim a fix worked without the re-measured number from Step 6
- Don't restructure DOM/markup, move elements, split pages, or change copy — hand off to `flow-layout` / `frontend-design`
- Don't introduce colors/fonts outside the project's existing palette and type choices — this skill makes the existing design legible, it doesn't redesign
- Don't fix only the default state — every captured state must pass, dark mode included
- Don't auto-commit; let the user invoke `/commit`
- Don't loop past 3 measure-fix passes; report remaining failures instead

## Why this skill exists

"見にくいので直して" otherwise produces impression-based review ("やや窮屈に感じます") and unverified fixes. Forcing measure → named threshold → fix → re-measure makes findings falsifiable and fixes provable, and the narrow CSS/token scope keeps it from colliding with flow-layout / design-review / frontend-design.
