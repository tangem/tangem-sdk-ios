#!/usr/bin/env bash

git rm -r --cached .github || true
git rm -r --cached .gitmodules || true
git rm -r --cached .jira || true
git rm -r --cached .bundle || true
git rm -r --cached fastlane || true
git rm -r --cached Utilities || true
git rm -r --cached swiftgen.yml || true
git rm -r --cached .swiftformat || true
git rm -r --cached .tools-version || true
git rm -r --cached .travis.yml || true
git rm -r --cached Gemfile* || true
git rm -r --cached .ios-sim-runtime || true

# Agent configuration and skills: they document internal Jira field ids, team slugs and workflows
git rm -r --cached .claude || true
git rm -r --cached .cursor || true
git rm -r --cached .codex || true
git rm -r --cached .cursorignore || true
git rm -r --cached .mcp.json || true
git rm -r --cached AGENTS.md || true
git rm -r --cached CLAUDE.md || true
