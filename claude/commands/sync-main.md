---
description: Catch the current branch up with the latest upstream main/master — fetch, rebase (or merge), resolve conflicts, verify, and offer to push
model: opus
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, AskUserQuestion, Bash(git fetch:*), Bash(git rebase:*), Bash(git merge:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(git add:*), Bash(git push:*), Bash(git rev-parse:*), Bash(gh pr view:*), Bash(gh pr checks:*)
---

Bring the current branch up to date with the repository's default branch (origin/main or origin/master), resolving any conflicts along the way. This is the recurring "main に別の PR がマージされたのでコンフリクト解消してほしい" workflow as a single command.

`$ARGUMENTS` may carry a hint: a base branch name (e.g. `develop`), or `merge` to force merge instead of rebase.

## 1. Survey (run in parallel)

- `git rev-parse --abbrev-ref HEAD` — current branch. If on main/master itself, just `git pull --ff-only` and stop.
- `git status --porcelain` — if the working tree is dirty, stop and tell the user what's uncommitted. Do NOT auto-stash; mixing WIP into a rebase is how work gets lost. (「作業ツリーに未コミットの変更があります。先に /commit するか退避してください」)
- `git fetch origin` then `git rev-parse origin/HEAD` (fall back to checking `origin/main` vs `origin/master`) — determine the base branch unless `$ARGUMENTS` named one.
- `git log --oneline HEAD..origin/<base>` and `git log --oneline origin/<base>..HEAD` — how far behind/ahead. If not behind at all, report 「すでに最新です」 and stop.
- `gh pr view --json number,url 2>/dev/null` — note if a PR exists for this branch (affects the push step).

## 2. Rebase (default) or merge

Default to `git rebase origin/<base>`. Use merge instead only when `$ARGUMENTS` says `merge`, or the branch has merge commits already (rebase would flatten them) — say which you chose and why in one line.

## 3. Resolve conflicts

For each conflicted file, read the conflict in full and resolve by intent, not by side:

- Understand what the main-side change and the branch-side change were each trying to do (`git log --oneline -3 origin/<base> -- <file>` and the branch commits touching it help).
- If both sides are mechanical/independent (imports, list entries, lockfiles), combine them.
- For lockfiles (`pnpm-lock.yaml`, `package-lock.json`): take the base side, then re-run the install command to regenerate.
- If the two sides genuinely contradict (same behavior changed in different directions), stop and ask the user with `AskUserQuestion`, showing both intents in the option descriptions — do not silently pick one.

After resolving each file: `git add <file>`, then `git rebase --continue` (repeat per commit). Never `git rebase --skip` — a skipped commit is silent data loss; if a commit becomes truly empty because main already contains it, explain that and use `git rebase --continue` after confirming the empty state is expected (git will prompt; `--allow-empty-message` style flags are not needed).

If the rebase goes irrecoverably sideways, `git rebase --abort` restores the starting state — say so and report what went wrong.

## 4. Verify

Detect the project's check commands (package.json scripts / Makefile etc., same priority as /commit) and run typecheck + tests (+ lint if cheap). Conflict resolution that compiles but breaks tests is not done — fix or report.

## 5. Push

After a rebase, the branch requires `git push --force-with-lease` (history was rewritten). This is allowed but always confirmed: ask via `AskUserQuestion`:

- 「push する (--force-with-lease)」 (Recommended; label it 「push する」 plain if step 2 used merge — merge needs no force)
- 「push しない」

Never plain `--force`. If the push is rejected because the remote moved again (lease failure), re-run from step 1 rather than overriding.

## 6. Report

2–4 lines: base branch, rebase/merge, how many commits replayed, conflicts resolved (file list), verification results, push status (+ PR URL if one exists).
