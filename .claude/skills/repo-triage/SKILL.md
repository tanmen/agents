---
name: repo-triage
description: Inventory your own GitHub repositories, classify the half-finished / abandoned / unclear-maintenance ones by concrete signals, recommend a disposition for each (keep / document / make-private / archive / delete), then execute the approved cleanup with safe gating — non-destructive edits and archive in batches, delete one-by-one with explicit confirmation. Targets your own non-fork repos (public + private); forks, org repos, and already-archived repos are out of scope unless the user widens it. Use when the user wants to tidy up their GitHub account — e.g. 「GitHub の repo を整理したい」「作りかけで放置してる repository を片付けたい」「メンテするか分からない repo をどうにかしたい」「使ってない repo を archive / 削除したい」「repo を棚卸しして」.
---

# repo-triage — GitHub の作りかけ / 放置 repo を棚卸しして処分する

Survey the user's own repositories, decide the fate of each one with evidence, and carry
out the approved cleanup safely. The destructive bias is **least-destructive-that-fits**:
prefer `archive` (reversible) over `delete` (irreversible), and never act before the user
has seen the report and approved.

**Default scope** (chosen by the user; widen only if they ask): their own **non-fork**
repos, both public and private. **Excluded**: forks, organization repos, already-archived
repos.

**Default action level**: report → approve → execute. Non-destructive edits + `archive`
run in batches after one confirmation; `delete` is confirmed **one repo at a time**.

---

## 0. Preflight

1. `gh auth status` — confirm there is an authenticated account and capture the login
   (this is the `owner` used everywhere below). If not logged in, stop and tell the user
   to run `gh auth login`.
2. Note the token scopes printed by `gh auth status`. `delete` needs the `delete_repo`
   scope. Do **not** refresh it now — only when the user actually reaches a delete (§6),
   so the inventory pass never asks for elevated scope it might not use.

## 1. Inventory (read-only)

Pull every in-scope repo in one call. `--source` excludes forks, `--no-archived` excludes
archived; omitting `--visibility` returns both public and private:

```bash
gh repo list "$OWNER" --source --no-archived --limit 1000 \
  --json name,nameWithOwner,description,url,visibility,isPrivate,isEmpty,pushedAt,updatedAt,createdAt,primaryLanguage,stargazerCount,forkCount,diskUsage,defaultBranchRef,licenseInfo,repositoryTopics
```

If `gh` rejects a JSON field, it prints the valid field list — drop the unknown field and
retry. (Note: `gh repo list` has no open-issue-count field; if you need it, fetch per repo
via `gh api "repos/$OWNER/$REPO" --jq .open_issues_count`.) Keep the raw JSON; you will
compute signals from it.

## 2. Compute signals (no extra calls)

For each repo derive, from the JSON above:

- `ageSincePush` — months since `pushedAt` (the freshness signal)
- `hasDescription` — non-empty `description`
- `hasTopics` — `repositoryTopics` non-empty
- `hasLicense` — `licenseInfo` present
- `isEmpty`, `diskUsage` (~0 KB ⇒ effectively empty)
- `dependents` — `stargazerCount + forkCount` (if > 0, **others rely on it** — never a
  silent delete; downgrade the recommendation and warn)
- `throwawayName` — name matches `^(test|tmp|temp|wip|untitled|sample|demo|foo|bar|hello|new-?repo|my-?repo)` or similar disposable patterns

## 3. Enrich only the borderline candidates

Only for repos that look incomplete (missing description, throwaway name, very stale, or
empty) gather a couple of cheap extra signals — skip this for clearly-active repos to keep
the pass fast:

- README present? `gh api "repos/$OWNER/$REPO/readme" --silent` (exit 0 = yes, 404 = no)
- Any release? `gh api "repos/$OWNER/$REPO/releases?per_page=1" --jq 'length'`
- Approx commit count: `gh api "repos/$OWNER/$REPO/commits?per_page=1" -i` and read the
  `page=<N>... rel="last"` number from the `Link` header (absent ⇒ ≤ 1 commit)

Run these in parallel across candidates where possible.

## 4. Classify + recommend a disposition

Assign each repo exactly one tier and disposition. Thresholds are defaults — if the user
gave their own (e.g. 「1年以上放置を対象に」) use theirs.

| Tier | Signals | 推奨 disposition |
|---|---|---|
| **active** | pushed < 6mo **and** has README + description | `keep`（触らない） |
| **valuable but undocumented** | `dependents > 0` or real code, but no README/description/topics | `document`（README/説明/topic を足す。隠さない） |
| **finished, idle** | has README/releases but no push > 12mo | `archive`（read-only 凍結・可逆） |
| **half-finished (作りかけ)** | no README **or** no description **or** no releases **or** ≤ a few commits, public | `make-private` か `archive`（中身次第） |
| **empty / throwaway** | `isEmpty` / `diskUsage ≈ 0` / ≤ 1 commit / throwaway name, **and** `dependents == 0` | `delete`（不可逆） |

Rules for the mapping:

- Prefer the **least destructive** disposition that fits. Prefer `archive` over `delete`.
- `dependents > 0` ⇒ never recommend `delete`; recommend `archive` (or `document`) and
  flag「★ 他者が star/fork 済み」.
- A private half-finished repo that's just personal scratch and empty ⇒ `delete` is fine;
  if it has real (if rough) code ⇒ `archive`.
- Anything you're unsure about ⇒ default to `archive`, never `delete`.

## 5. Present the triage report (日本語・ユーザー向け)

Output a markdown report (tables, **not** ASCII box art). Group by recommended disposition,
most actionable first. For each repo show: name, visibility, 最終push（相対）, 主要シグナル,
推奨, 一行の理由. Lead with a short「まず対処すべき」list (e.g. empty repos + obvious
throwaways). Summarize counts per disposition.

Optionally offer to write the full report to a file (e.g. `repo-triage-report.md` in the
cwd) if the list is long — ask before writing.

## 6. Execute the approved dispositions (gated)

Ask via **AskUserQuestion** which disposition groups to apply (let the user also exclude
individual repos). Then run them in this order — least destructive first:

1. **document** — confirm the concrete change per repo first, then:
   - description: `gh repo edit "$OWNER/$REPO" --description "<text>"`
   - topics: `gh repo edit "$OWNER/$REPO" --add-topic "<t1>,<t2>"`
   - README: create via `gh api --method PUT "repos/$OWNER/$REPO/contents/README.md"`
     with base64 content + a commit message (or push a commit). Show the README body for
     approval before writing.
2. **make-private** — `gh repo edit "$OWNER/$REPO" --visibility private --accept-visibility-change-consequences`. Batch after one confirmation.
3. **archive** — `gh repo archive "$OWNER/$REPO" --yes`. Reversible later via
   `gh repo unarchive`. Batch after one confirmation.
4. **delete** — last, and **one repo at a time**:
   - Ensure the `delete_repo` scope exists; if not: tell the user to run
     `gh auth refresh -h github.com -s delete_repo`, then continue.
   - For each repo, restate what is lost (age, last push, stars/forks, that it is
     **irreversible**) and get an explicit per-repo confirmation (AskUserQuestion, or have
     them type the repo name). Only then `gh repo delete "$OWNER/$REPO" --yes`.
   - Never batch-delete. Never delete a repo with `dependents > 0` without a loud,
     separate warning and re-confirmation.

After each batch, report what changed (repo + action + result).

## Safety rules

- **Report before action.** Never run a write/destructive `gh` command before §5 + §6
  approval.
- Prefer `archive` (reversible) over `delete` (irreversible). When unsure, `archive`.
- `dependents > 0` (star/fork): never silent-delete — warn and downgrade.
- Stay within the surveyed `OWNER`. Don't touch forks, org repos, or already-archived
  repos unless the user explicitly widened the scope.
- One destructive `gh` command per Bash call; re-read the target `nameWithOwner` right
  before running it.
- `delete` requires the `delete_repo` scope — request it only at the moment it's needed.
- If the user widens scope to **org repos**, treat every disposition as higher-risk
  (others are affected) and require extra confirmation even for `archive`.
