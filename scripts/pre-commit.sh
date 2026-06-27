#!/usr/bin/env bash

# Install with: $ cp scripts/pre-commit.sh .git/hooks/pre-commit

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "${REPO_ROOT}"
make check
