---
description: Make one or more commits from the current working tree, splitting by topic so each commit covers a single cohesive change, then ask whether to push / open a PR / enable auto-merge
model: opus
allowed-tools: Read, Edit, Write, AskUserQuestion, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git checkout:*), Bash(git restore:*), Bash(git stash:*), Bash(git rm:*), Bash(git mv:*), Bash(git show:*), Bash(git rev-parse:*), Bash(git config get:*), Bash(git push:*), Bash(sed:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh pr merge:*), Bash(gh repo view:*)
argument-hint: [グループ分けのヒント — 例: "2 commits" / "license と UI を分割" / "1コミットで"]
---

Turn the current working tree into commits — one per topic — then ask the user how far to take it: push only, push + open PR, or push + open PR + enable auto-merge. The final number N may be 1 or many; that's decided after surveying the diff. Every intermediate state must compile and pass whatever pre-commit hooks the repo has configured (e.g. lefthook, husky, pre-commit framework, git hooks under `.git/hooks/`). Do not skip hooks.

This is **not** a vanilla `git commit` wrapper. It analyses the diff, groups by topic, produces N commits where N ≥ 1, and finishes by asking whether/how far to publish. The **grouping decision is announced in plain text and acted on without confirmation** (the user has expressed standing approval to commit on whatever proposal lands; they can interrupt mid-flight if they disagree). The **publish step requires explicit user choice** via `AskUserQuestion`.

`$ARGUMENTS` may carry a hint (e.g. `2 commits`, `split license vs UI`, `everything in one commit`, `1コミットで`). Treat it as a directive that overrides the auto-detected grouping. If the hint conflicts with what the diff supports (e.g. `1 commit` requested but the diff is two unrelated topics), surface the conflict in the announcement and follow the hint anyway.

## 1. Survey

Run these in parallel:

- `git status` — modified + untracked files
- `git diff --stat` — file-level scope
- `git log -10 --oneline` — match the project's commit-message style and trailer convention
- `git log -1 --format=%B` — see the body shape (subject + body + trailer) used in recent commits
- `git diff` on each file that looks like it spans multiple topics

Also detect the project's verification commands once, by inspecting (in priority order) `package.json` scripts, `Makefile`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc. Look for typecheck / test / lint / format scripts. You'll use whichever exists; if none, skip the verification step but say so.

Goal: understand scope, identify themes, and know how to verify each intermediate state.

### Snapshot the WIP via stash (safety net)

**Skip this step if §2 will decide single-topic** — there's no risk of destroying mixed WIP. **Required if the survey shows multi-topic or mixed-file content**, before any destructive op in §3.

Capture the current working tree atomically so the split can't accidentally destroy uncommitted work:

```bash
git stash push -u -m "commit-split: $(date +%FT%T)" && git stash apply
```

- `-u` includes untracked files (modified + new + binary all caught in one shot — no per-file cp to forget).
- The immediate `git stash apply` reapplies the snapshot so the working tree is unchanged; `stash@{0}` now mirrors it as a safety net.
- Survives `git stash drop` via reflog for 90 days. Inspectable any time via `git stash show -p stash@{0}`.

From this point on, treat `stash@{0}` as the canonical "what WIP looked like at the start" — you can selectively pull files from it during the split (see §3) without worrying about which files you remembered to back up.

If the stash push fails (e.g. nothing to stash because the survey was on a clean tree), abort the skill — there's nothing to commit.

## 2. Announce the grouping

Decide whether the diff is **single-topic** or **multi-topic**, announce the plan in plain text, and proceed to step 3 immediately. Do **not** call `AskUserQuestion` for grouping confirmation — the user has standing approval; they will interrupt if they disagree.

### Single-topic

Announce as `"1 commit で行きます: <subject line>"` and go to step 3.

### Multi-topic

Categorize the changes into 2–5 logical groups. Each group must:

- Be a **single coherent topic** — a reviewer should understand the commit on its own
- Have a **stable order** — earlier commits should not break compile/test for later ones
- Have a **subject line** that matches the project's convention spotted in `git log` (Conventional Commits — `feat:`, `fix:`, `chore:`, `docs:`, with a scope where natural)

Announce in plain text. For each group, list:

- Subject line
- Files entirely owned by this group
- Files **partially** owned (will need partial staging via the technique below)

Then go straight to step 3.

### When unsure

If the diff might be one topic or two, lean toward proposing the split — finer granularity is easier to review than retroactively splitting one commit. (If the user prefers to collapse, they will say so; auto-collapsing silently destroys reviewer signal.)

## 3. Execute each commit, in order

For each file:

- **Entirely in this commit** → stage with `git add <path>`.
- **Spans multiple commits** → use the **revert → reapply-from-stash** technique below.

### Revert → reapply-from-stash (for mixed files)

Relies on the §1 stash. `stash@{0}` already mirrors every modified + untracked file in its final WIP state, so there's nothing to back up per-file. For each commit:

1. **First commit on that file**: revert to HEAD with `git checkout HEAD -- path/to/file`, then apply only this commit's slice using the Edit tool. For bulk word-swaps with no false-match risk, sed is faster — `sed -i '' -e 's/A/B/g'` on macOS / BSD, `sed -i -e 's/A/B/g'` on Linux / GNU. Use Edit for anything structural.
2. **Middle commits**: apply the additive slice on top of the previous state via Edit.
3. **Last commit on that file**: `git checkout stash@{0} -- path/to/file` to restore the final WIP state. Avoids redoing edits, and works identically for text and binaries.

After applying each slice, run the project's typecheck / test / build (whatever you detected in §1) before committing — the intermediate state must compile and pass.

**If a destructive op goes sideways mid-flight**: `git checkout stash@{0} -- .` restores the entire WIP from the stash. The stash isn't consumed until §4, so this rescue is always available.

Cross-file constraint: if Commit A renames an exported symbol / i18n key and Commit B updates the call sites, **both must land together** — either fold them into one commit, or revert the call-site files to HEAD for the intermediate state and put them in the rename commit.

### Stage and commit

Stage explicit paths for this commit. Untracked files outside the current group should stay untracked. (`git add -A` / `git add .` is fine only when you've verified the working tree is fully one topic — see Rules.)

Use a HEREDOC for the message and end with the project's standard trailer (copy whatever `git log` shows, e.g. `Co-Authored-By: ...`):

```bash
git commit -m "$(cat <<'EOF'
<subject ≤ 70 chars>

<body explaining the why, not just the what — bullet points OK>

<trailer line(s)>
EOF
)"
```

If a pre-commit hook fails, **fix the underlying cause** (re-format, re-lint, fix typecheck) and re-stage as a new commit. Don't reach for `--amend` here specifically — a failed hook means the commit did **not** happen, so `--amend` would silently rewrite the *previous* commit instead. (See Rules for `--no-verify` / `--amend` policy in general.)

## 4. Verify

After the last commit:

- `git log --oneline -<N+2>` — show the new commits in order
- `git status` — confirm only out-of-scope dirt remains (call it out so the user knows)
- Drop the §1 safety-net stash **only if** the working tree now matches the user's intended final state (compare `git diff stash@{0}` — should be empty for in-scope files, may show out-of-scope dirt that was never meant to be committed). Identify the right entry via the message before dropping:
  ```bash
  git stash list | grep "commit-split:"   # confirm stash@{0} is the one you pushed
  git stash drop stash@{0}
  ```
  If anything looks off, leave the stash in place — the user can inspect or `git stash apply` later.

Report each commit's SHA + subject and call out anything left unstaged (plus whether the safety-net stash was dropped or kept).

## 5. Ask how far to publish

After §4, ask the user via **`AskUserQuestion`** what to do with the new commits. The set of options depends on the branch and tooling available.

### Detect context first (silent)

- Current branch: `git rev-parse --abbrev-ref HEAD`
- Whether `gh` is on PATH: `command -v gh >/dev/null && echo yes` (single test, no output to user)
- Whether a PR already exists for this branch: `gh pr view --json url,number,autoMergeRequest 2>/dev/null` — non-zero exit = no PR yet
- Repo merge strategies allowed: `gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed` (only if user is likely to enable auto-merge)

### Options to present

**On a feature branch** with `gh` available (3 options, single-select):

- `"push + PR 作成 + auto-merge 有効"` (Recommended) — push, create PR if not yet existing, enable auto-merge (the PR auto-merges once branch protection checks pass)
- `"push + PR 作成"` — push, create PR if not yet existing, but leave merging to manual review
- `"push しない"` — stop here

**On a feature branch** without `gh` (2 options): `"push する"` (Recommended) / `"push しない"`.

**On `main` / `master`** (2 options, prepend `"⚠ <branch> への直接 push です — "` to the question text):

- `"push する"` — direct push to default branch
- `"push しない"` (Recommended) — stop here

**If a PR already exists** on a feature branch (3 options, replace "PR 作成" with the existing PR's URL):

- `"push + auto-merge 有効 (PR #<n>)"` (Recommended) — push and enable auto-merge on the existing PR
- `"push のみ (PR #<n> はそのまま)"` — push to the existing PR's branch, leave merge state untouched
- `"push しない"` — stop here

### Mechanics

**Push**: `git push` (or `git push -u origin <branch>` if upstream missing — detect via `git rev-parse --abbrev-ref --symbolic-full-name @{u}` failing). Never `--force` / `--force-with-lease` from this command. If the push fails because of divergence, surface the error and stop — the user decides how to reconcile.

**PR creation** (if user chose a "PR 作成" option AND no PR exists):

- Title: derive from the latest commit's subject (drop the Conventional Commits prefix only if the result still reads cleanly; otherwise keep the prefix). Cap at 70 chars.
- Body: for single-commit PRs, use the commit body verbatim (skip the trailer line). For multi-commit PRs, build a Summary section as a bullet list — one bullet per commit subject — followed by the body of any commit that has substantive context.
- Match the project's recent PR description style if visible (`gh pr list --state merged --limit 3 --json body` if you need a sample). Do not auto-append a "Generated with Claude Code" footer unless the project's recent PRs have one.

Run via HEREDOC:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

**Auto-merge** (if user chose an "auto-merge 有効" option):

- Pick the merge strategy in priority `merge` → `squash` → `rebase`, based on what `gh repo view --json ...` reports as allowed. If multiple are allowed, prefer the one matching recent merges (`git log --merges -5 --format=%s` — `Merge pull request` style indicates merge-commit; squash + rebase leave no merge commit so check commit message conventions).
- Run `gh pr merge --auto --<strategy> --delete-branch <PR>`. The command is idempotent — if auto-merge is already enabled it reports that and exits 0. `--delete-branch` is safe with auto-merge (only deletes on actual merge); omit it only if the user has indicated they keep merged branches.
- If `gh pr merge` errors with "auto-merge is not enabled on this repository", report that to the user and stop — they need to enable it in repo settings. Do not silently fall back to immediate merge.

### Report

If everything succeeds, report in 1–2 lines: pushed SHA(s), PR URL (newly created or pre-existing), and whether auto-merge is queued. If a step failed, quote the most relevant 3–5 lines of output and stop.

## Rules

- **Write commit messages in Japanese** — subject description and body. Keep the Conventional Commits prefix (`feat:`, `fix:`, `chore:`, `docs:`) and trailer lines (`Co-Authored-By: ...`) in English. This overrides the project-style match in §2 even when the repo's existing `git log` is in English. Example: `feat(extension): 字幕の発言者を匿名化する`.
- One `git commit` per Bash call — each intermediate state needs validation
- `git checkout HEAD -- <path>` and `git checkout stash@{0} -- <path>` are the documented technique for the §3 split — not flagged as destructive **provided the §1 stash exists**. Without the stash, `git checkout HEAD -- <path>` permanently destroys WIP and must be avoided.
- Avoid by default (and tell the user before reaching for one): `git add -A` / `git add .`, `--no-verify`, `--amend` on already-pushed commits, `git reset --hard`, `git checkout .`. Each silently throws away work or skips the safety net the project set up. Fine when the user explicitly opts in (e.g. local fixup `--amend` before any push, or `git add -A` when the working tree is unambiguously one topic).
- Leave files the user didn't intend for this split alone (different topic = different session).
- §5 handles publish confirmation (push / PR / auto-merge). Never `--force` / `--force-with-lease` unless the user explicitly asks in plain text (the §5 options do not include force push). Never enable auto-merge with a strategy that contradicts repo settings or recent merge history — pick from what `gh repo view` reports as allowed.
