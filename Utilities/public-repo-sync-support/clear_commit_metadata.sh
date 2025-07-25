#!/usr/bin/env bash

git filter-repo --replace-refs delete-no-add --force \
--commit-callback '
import os
commit.author_name = b"Tangem Bot"
commit.author_email = b"mobile@tangem.com"
commit.committer_name = b"Tangem Bot"
commit.committer_email = b"mobile@tangem.com"
commit.message = b"'${RELEASE_TAG}'"
'
