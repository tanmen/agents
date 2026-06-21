---
name: branch
description: Create a new branch from the latest upstream main (or master). Use when the user wants a fresh branch cut from origin's default branch — e.g. "/branch feature/foo", "新しく feature/bar というブランチを切って", "main から fix/baz を生やして". Fetches the base branch and creates the new branch from it.
model: haiku
allowed-tools: Bash(git fetch:*), Bash(git checkout:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git show-ref:*), Bash(git status:*), Bash(git branch:*), Bash(git switch:*), Bash(git for-each-ref:*)
---

# Branch

Create a new branch from the latest upstream main/master.

## Hard rule: one command per Bash call

Run **each git command as its own Bash call**. Do **NOT** chain commands with `&&`, `;`, or `||`, and do **NOT** use `echo` / `printf` / redirections.

Why: this skill's `allowed-tools` whitelists single git subcommands (`Bash(git status:*)` etc.). A compound command, or any non-git token like `echo`, does not match those static rules, so the harness falls back to the permission **auto-classifier**. That path re-serializes the previous assistant turn and corrupts its `thinking` block, which hard-stops the session with `400 ... thinking blocks ... cannot be modified`. Keeping every call to a single whitelisted git command avoids the classifier entirely.

## Steps

1. **Snapshot state** — run these as **three separate Bash calls** (they're independent, so issue them in parallel in one turn):
   - `git symbolic-ref refs/remotes/origin/HEAD --short` → upstream default branch (e.g. `origin/main`). If it errors, fall back to `origin/main`.
   - `git status --porcelain` → working-tree cleanliness (empty = clean).
   - `git branch --list <name>` → prints the branch if it already exists, nothing if not. (Single command — do not append `&& echo ...`.)
2. **Decide base** — derive the upstream default from step 1 (strip the `origin/` prefix). Never assume `main` blindly if `master` is the real default.
3. **Guard** — if the target branch already exists (step 1 printed it) or the working tree is dirty, warn the user and stop unless they've already said it's fine.
4. **Create** — two separate Bash calls:
   - `git fetch origin <base>`
   - `git checkout -b <name> --no-track origin/<base>`

   **Why `--no-track`**: starting a branch from a remote-tracking ref (`origin/<base>`) makes git auto-set the new branch's upstream to `origin/<base>` (e.g. `origin/main`), so `git status` / `git push` then track `origin/main` instead of the branch's own remote. `--no-track` uses `origin/<base>` only as the start point and leaves the upstream unset, so the first `git push -u` later binds it to `origin/<name>`.
5. **Report** — run `git rev-parse --short HEAD` (its own call), then confirm the new branch, its base, and the short SHA in one line.

Now create a branch following the steps above for: $ARGUMENTS
