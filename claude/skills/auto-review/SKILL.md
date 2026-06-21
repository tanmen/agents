---
name: auto-review
description: Judge whether running /code-review is warranted on the current diff, run it if so, judge whether each finding requires action, apply the fixes that do, then either loop back into another review automatically when obviously warranted (capped at 3 passes) or gate the next pass with AskUserQuestion. Use when the user wants the full "decide → review → fix → maybe re-review" loop done in one shot — e.g. "/auto-review", "コードレビューしておいて", "レビューと修正お願い".
---

# /auto-review — judge, review, fix, maybe re-review

Drive the full review loop so the user doesn't have to re-explain it each time:

1. Decide whether running `/code-review` is warranted at all
2. If warranted, run it via the `code-review` skill
3. Judge per finding whether it requires action in this change
4. Apply the fixes for findings worth addressing
5. If another review pass is obviously warranted, loop back to Step 2 automatically (cap 3 iterations). Otherwise ask via `AskUserQuestion`

## What to do

### Step 1 — Decide whether /code-review is warranted

Run `git status --porcelain` and `git diff --stat` (vs. the base branch if on a feature branch, otherwise vs. `HEAD`) to see what's pending.

Skip the review and tell the user "レビュー対象なし" when:

- Working tree is clean AND the current branch has no commits beyond the base branch
- Changes are pure formatting (whitespace, prettier output) or generated files only
- Only docs / config string edits with no code semantics changed

Otherwise proceed.

### Step 2 — Run /code-review

Invoke the `code-review` skill via the Skill tool. Pick effort:

- Tiny diff (< ~50 lines, 1–2 files) → `low`
- Default → `medium`
- Touches risky areas (auth, IPC boundaries, DB migrations, security-sensitive code paths) → `high`
- **Never** use `ultra` on the user's behalf — it's a paid cloud review and must be user-initiated

Do NOT pass `--fix`. We want raw findings here so we can judge them per-item in Step 3.

**Reading the result**: `code-review` emits findings one per line, or the literal `(none)` when nothing qualifies. The literal `(none)` reads like a terminal end-of-turn output, but it is **not** — it is just the inner skill's "no findings" signal. Do NOT stop the turn here. Continue into Step 3 (which collapses to "対応すべき指摘なし") and then Step 5's "No findings at all" branch, and emit your own closing sentence before ending the turn (see Step 5 for the exact requirement).

### Step 3 — Judge each finding

For every finding the review produces, decide and state in one line:

- `Fix: <finding>` — address now
- `Skip: <finding> — <reason>` — defer or discard

**Address now** when:

- Correctness bug (wrong logic, off-by-one, a null/undefined path that can actually fire, broken edge case)
- Security issue (injection, leaked secret, unsafe IPC boundary)
- Clear simplification with no behavioral change and low risk
- A regression the reviewer is confident about

**Skip / defer** when:

- Style / taste preference with no concrete bug
- "Could consider" / "might want to" speculative suggestions
- Refactor that expands scope well beyond the current change
- The reviewer flagged something that's actually intentional in this codebase — check `CLAUDE.md` / existing patterns before discarding

If you're uncertain on a finding, lean toward Fix when the change is small and reversible, lean toward Skip when the fix would balloon scope.

### Step 4 — Apply the fixes

Edit the relevant files directly. Don't bundle unrelated cleanups. After fixing:

- Run the relevant test runner if a fix touched testable code (in this repo: `pnpm test:react <path>` / `pnpm test:electron <path>`)
- Run lint/format if many files changed (`pnpm lint` / `pnpm format`)

If no findings were worth addressing, skip this step and note "対応すべき指摘なし".

### Step 5 — Re-review automatically when obvious, otherwise ask

First decide whether the situation is **obvious enough to just loop back to Step 2 without asking**:

**Just re-review (no AskUserQuestion)** when:

- The fix introduced substantial new logic (new branches, new error paths, non-trivial refactor) that itself deserves a review pass
- A correctness finding was fixed in a way that's likely to have analogous issues nearby — re-reviewing is the cheapest way to confirm
- The previous review was at `low` effort and uncovered a real bug, suggesting `medium`/`high` on the post-fix tree would find more

When auto-looping, cap at **3 iterations total** to avoid runaway. If you'd hit iteration 4, stop and ask instead.

**Otherwise, ask via `AskUserQuestion`** (header: `次のアクション`). Tailor the options to what actually happened:

- **Fixes were minor / mechanical** → recommend stopping:
  - `ここで止める (Recommended)`
  - `念のためもう一度 /code-review`
  - `/commit に進む`
- **Findings existed but were all skipped** → confirm direction:
  - `この判断のまま進める (Recommended)`
  - `やはり一部の指摘に対応する`
- **No findings at all** (= `code-review` returned the literal `(none)`) → don't ask, but you **must** emit a closing sentence of your own such as `指摘なし。 ここで止める。` before ending the turn. The inner skill's `(none)` on its own reads as terminal output to both the user and the model, so without an explicit outer-skill closing line, the turn appears to cut off mid-task (the user sees only `(none)` followed by Stop-hook output). The closing sentence is the signal that the outer skill ran to completion.

If the user picks "もう一度 /code-review", loop back to Step 2. If they pick `/commit`, hand off to the `commit` skill.

When auto-looping, briefly state why ("修正で新規ロジックが増えたので再 review に入る" 等) before re-entering Step 2, so the user can interrupt if they disagree.

## Don't

- Don't run `/code-review ultra` automatically — it costs money and requires explicit user intent
- Don't pass `--fix` to `/code-review` — that bypasses the per-finding judgment that's the whole point of this skill
- Don't auto-commit the fixes. Let the user invoke `/commit` (or pick it from the AskUserQuestion options)
- Don't re-run `/code-review` past 3 iterations without asking the user. Auto-looping is fine when obviously warranted (Step 5), but cap at 3 to avoid runaway
- Don't lecture the user about findings you decided to skip. One line per skipped finding is enough
- Don't expand the review scope beyond the current diff (no "while we're here, let's also refactor X")

## Why this skill exists

The user repeatedly types out the same multi-step instruction: "decide whether to review, run it if so, decide which findings to fix, fix those, then ask whether to re-review." Bundling it into one skill removes the round-trip and makes the `AskUserQuestion` gate at the end consistent so the loop doesn't run unattended.
