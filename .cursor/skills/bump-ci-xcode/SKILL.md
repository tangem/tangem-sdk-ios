---
name: bump-ci-xcode
description: Bump the CI Xcode version - create the Jira ticket, update .xcode-version, .ios-sim-runtime and the Fastfile test device, and open a PR to develop
argument: version - Target Xcode version (e.g., 26.5 or 26.4.1)
---

# Bump CI Xcode Version

This skill automates the recurring chore of moving CI to a new Xcode version. It creates the Jira ticket, updates the version files in the repository root plus the hardcoded test device in `fastlane/Fastfile`, and opens a PR to `develop`.

## How CI consumes the version

- `.xcode-version` — single line with the Xcode version. On CI the `xcodes` action in `fastlane/Fastfile`'s `before_all` selects the toolchain from it (unless an explicit `xcode_version_override` is passed to the lane), and `.github/workflows/update-localizations.yml` uses it in a cache key.
- `.ios-sim-runtime` — two lines: simulator device name (line 1) and iOS simulator runtime version (line 2). CI does not read this file; it feeds the manual `xcodebuild` commands documented in AGENTS.md → Build & Test Commands.
- `fastlane/Fastfile` — `TEST_DEVICE` at the top hardcodes `'<device name> (<runtime version>)'` and is what `bundle exec fastlane test` actually runs on, both locally and on CI. **This is the one that breaks the build if it's missed**, and it must stay consistent with `.ios-sim-runtime`.

Both version files end with a **trailing newline** — preserve it when editing.

Unlike `tangem-app-ios`, this repository builds only on GitHub-hosted runners (`macos-*`), so there is no IT Ops ticket and no self-hosted runner to provision. The constraint is different: the requested Xcode version and simulator runtime must be present on the runner image the workflows pin (see `runs-on` in `.github/workflows/`). Check the [runner-images release notes](https://github.com/actions/runner-images) before picking a version, and bump the image in the workflows if the version needs a newer one.

## Prerequisites

- Jira MCP configured and authenticated
- GitHub MCP configured and authenticated

## Steps

### 1. Parse Arguments and Read Current State

- Extract the target version from `$ARGUMENTS` (e.g., `26.5`).
- Read `.xcode-version` to get the current version for the ticket description and commit message.
- Read `.ios-sim-runtime` to get the current device name and runtime version.
- Read `TEST_DEVICE` in `fastlane/Fastfile` and confirm it matches `.ios-sim-runtime`. If it already drifted, say so — that's a pre-existing bug worth mentioning in the PR.

### 2. Create the Jira Ticket

AGENTS.md is the single source of truth here: the required-field checklist (Stream, Story Points, QA Notes), sprint, cloudId, field IDs and the ADF caveats all live there, and the QA-note shorthand for a change with zero runtime impact comes from the `write-qa-notes` skill. Only what is specific to this task is listed below.

- **Summary:** `Bump CI Xcode version to <version>`
- **Description** (ADF): what moves from `<current>` to `<version>`, and which files carry it.
- **Story Points (`customfield_10025`):** `2`
- This change never ships in the binary, so QA Notes are the one-line "no QA needed" shorthand.
- Assign to the current user via a follow-up `editJiraIssue` call (the create-time shorthand is silently dropped) and verify.
- Transition the ticket to `In Progress`.

### 3. Create the Branch

```bash
git fetch origin develop
git checkout -b IOS-NNNNN_bump_ci_xcode_<version_snake_case> origin/develop
git push -u origin IOS-NNNNN_bump_ci_xcode_<version_snake_case>
```

Push immediately so the branch tracks its own remote instead of `origin/develop`.

### 4. Update the Version Files

- `.xcode-version`: replace the content with the new version, keeping the trailing newline.
- `.ios-sim-runtime`: keep line 1 (device name) as-is unless the device is also changing, set line 2 to the new runtime version, keep the trailing newline.
- `fastlane/Fastfile`: update `TEST_DEVICE` to `'<device name> (<runtime version>)'` so it matches `.ios-sim-runtime`.

```bash
printf '<version>\n' > .xcode-version
printf '<device name>\n<runtime version>\n' > .ios-sim-runtime
```

AGENTS.md documents these files by reference rather than repeating the numbers, so it needs no edit — but if you changed a `runs-on` image, update the per-workflow list in its `Git & CI` section, which spells out that the workflows are deliberately not on the same image.

**Patch releases caveat:** patch versions of Xcode (e.g., 26.4 → 26.4.1) usually do not ship a new simulator runtime. In that case leave `.ios-sim-runtime` and `TEST_DEVICE` untouched. If unsure, bump them and watch the CI run on the PR — roll back if simulator selection fails.

### 5. Commit and Push

Single commit, GPG-signed (repo requirement):

- Subject: `IOS-NNNNN Bump CI Xcode version to <version>`
- Body: one or two sentences on the why (builds and tests must select the new toolchain and simulator runtime).

Verify the signature with `git log --show-signature -1` before pushing.

### 6. Open the PR

Invoke the `create-pr` skill with `develop` as the target.

Watch the `Tests` workflow on the PR before asking anyone to merge — a wrong runtime or device name surfaces there as a simulator-selection failure, not as a test failure.

### 7. Report Result

Output:
- The Jira ticket key and URL
- The PR URL
- Whether the `Tests` workflow passed on the new toolchain
