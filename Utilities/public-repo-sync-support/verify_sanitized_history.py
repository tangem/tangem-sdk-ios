#!/usr/bin/env python3

# Pre-push gate for the public repo sync: fails if the repo contains any refs beyond the
# sanitized synced branch and lightweight tags (stray branches, remote-tracking refs or
# annotated tags would leak private data if pushed), or if any path anywhere in the
# published history still matches the deletion patterns (e.g. because the patterns were
# not applied).
#
# Reads the synced branch name from `SYNCED_BRANCH` (set by the sync workflow).

import os
import subprocess
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from clear_sensitive_data_patterns import should_remove_file


def git_lines(*args):
    result = subprocess.run(["git", *args], capture_output=True, text=True, check=True)

    return result.stdout.splitlines()


def collect_paths():
    # `--name-only` with an empty format yields every path ever touched by any commit reachable from any ref;
    # `-m` includes merge commits, `-z` keeps non-ASCII paths unquoted so the deletion patterns can match them
    result = subprocess.run(["git", "log", "--all", "-m", "--name-only", "--format=", "-z"], capture_output=True, check=True)

    return set(filter(None, result.stdout.decode("utf-8", errors="surrogateescape").replace("\n", "\0").split("\0")))


def main():
    synced_branch_ref = f"refs/heads/{os.environ['SYNCED_BRANCH']}"

    # Ref validation: the synced branch plus lightweight tags, nothing else
    refs = git_lines("for-each-ref", "--format=%(refname) %(objecttype)")
    ref_names = [line.split(" ")[0] for line in refs]
    if synced_branch_ref not in ref_names:
        print(f"::error::The synced branch {synced_branch_ref} is missing from the repo to publish")
        return 1

    unexpected_refs = []
    for line in refs:
        ref, object_type = line.split(" ")
        if ref == synced_branch_ref:
            continue

        if not ref.startswith("refs/tags/") or object_type != "commit":
            unexpected_refs.append(f"{ref} ({object_type})")

    if unexpected_refs:
        print(f"::error::Unexpected refs in the repo to publish: {unexpected_refs} (expected {synced_branch_ref} and lightweight tags only)")
        return 1

    # Git history validation
    violations = [path for path in sorted(collect_paths()) if should_remove_file(path)]
    if violations:
        print(f"::error::{len(violations)} paths matching the deletion patterns survived the history rewrite (full list in the step log)")
        for violation in violations:
            print(f"  {violation}")
        return 1

    print(f"Verified {synced_branch_ref} and {len(ref_names) - 1} tags: ref set is as expected, no files match the deletion patterns.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
