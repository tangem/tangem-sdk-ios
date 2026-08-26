---
description: Create a pull request from the current branch to a target branch with proper formatting, Jira link, and reviewers
argument: target_branch - The branch to merge into (e.g., develop, release/5.33)
argument: --draft - Optional flag to create a draft PR instead of a ready for review PR
---

# Create Pull Request

Create a pull request from the current branch to the target branch specified in `$ARGUMENTS`.

If `--draft` flag is present, create a draft PR (skips reviewer assignment).

## Steps

### 1. Gather Information

First, parse `$ARGUMENTS` to extract:
- `target_branch`: The branch name (excluding any flags)
- `is_draft`: `true` if `--draft` flag is present

Run these in parallel:

**Git commands:**
```bash
# Get current branch name
git rev-parse --abbrev-ref HEAD

# Get commits on this branch vs target (use target_branch, not raw $ARGUMENTS)
git log <target_branch>..HEAD --oneline

# Get diff stats
git diff <target_branch>..HEAD --stat
```

### 2. Extract Issue Number

From the branch name (e.g., `IOS-12800_description`), extract:
- Issue number: `IOS-XXXXX`
- PR title: `IOS-XXXXX Short description` — identical to the commit subject

### 3. Check the SDK Version Was Bumped

Only when the target is `develop`.

```bash
git show origin/develop:VERSION
cat VERSION
grep "s.version" TangemSdk.podspec
```

If `VERSION` still matches `origin/develop`, `check-tag` will fail the PR. Ask which component to bump — hotfix by default — then set it in both `VERSION` (keep the trailing newline) and `s.version`, identical, and commit before opening the PR.

### 4. Push Branch to Remote

Ensure the current branch is pushed to the remote:

```bash
git push -u origin HEAD
```

### 5. Create PR via GitHub MCP

Use the `mcp__github__create_pull_request` tool with these parameters:
- `owner`: `tangem-developments`
- `repo`: `tangem-sdk-ios`
- `title`: `IOS-XXXXX Short description`
- `head`: current branch name
- `base`: target branch from `$ARGUMENTS` (excluding `--draft` flag)
- `body`: must include the Jira link on its own line:
  ```
  [IOS-XXXXX](https://tangem.atlassian.net/browse/IOS-XXXXX)
  ```
  Write the rest per the PR description style in AGENTS.md, and de-key any other ticket you reference (see "Don't drag unrelated tickets into the merge").
- `draft`: `true` if `--draft` flag is present in `$ARGUMENTS`, otherwise omit or set to `false`

### 6. Request Copilot Review (skip if draft)

**Skip this step if the PR was created as a draft.**

Use the `mcp__github__request_copilot_review` tool with:
- `owner`: `tangem-developments`
- `repo`: `tangem-sdk-ios`
- `pullNumber`: PR number from step 5

### 7. Assign Human Reviewers (skip if draft)

**Skip this step if the PR was created as a draft.**

If the reviewers are already dictated by the task — the user named them, or an invoking skill requires specific people — assign them right away without asking.

Otherwise never pick reviewers on your own initiative — ask with the `AskUserQuestion` tool: "Assign human reviewers to the PR?" with options:
- "`ios-core`" — a review request to the team that owns this repository; GitHub then auto-assigns two of its members, round-robin, per the team's review-assignment settings
- "Don't assign"
- "Another team" — a different ios-team sub-team, same round-robin behaviour
- "Specific people" — the user names the logins (often arrives as an "Other" free-text answer)

Then:
- "`ios-core`" → pass `tangem-developments/ios-core` in `reviewers`.
- "Don't assign" → leave the PR without human reviewers.
- "Another team" → unless the user already named it, list the sub-teams and ask which one (`ios-admin` is not a review team — never offer or assign it):

  ```bash
  gh api orgs/tangem-developments/teams/ios-team/teams --jq '.[].slug | select(. != "ios-admin")'
  ```

  Pass the team as `tangem-developments/<team-slug>` in `reviewers`.
- "Specific people" → pass their GitHub logins in `reviewers`.

Prefer a team over naming individuals: requesting a team is what engages GitHub's round-robin auto-assignment, so review load rotates instead of landing on whoever was picked by hand.

Use the `mcp__github__update_pull_request` tool to add reviewers:
- `owner`: `tangem-developments`
- `repo`: `tangem-sdk-ios`
- `pullNumber`: PR number from step 5
- `reviewers`: GitHub logins and/or `tangem-developments/<team-slug>` entries

### 8. Report Result

Output the PR URL and confirm:
- Whether the PR was created as a draft or ready for review
- If not a draft: whether human reviewers were assigned (and whom) or skipped per the user's choice
