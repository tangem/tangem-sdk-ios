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
