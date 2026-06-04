#!/usr/bin/env bash
#
# Create the working branch for the ticket implementation.
#
# Reads (env): BRANCH
set -euo pipefail

git config user.name "claude-bot"
git config user.email "claude-bot@users.noreply.github.com"
git checkout -b "$BRANCH"
