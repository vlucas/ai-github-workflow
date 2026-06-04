#!/usr/bin/env bash
#
# Detect whether Claude produced any changes in the working tree.
#
# Reads (env): GITHUB_OUTPUT, TICKET_KEY
# Writes (step output): changed=true|false
set -euo pipefail

if [ -n "$(git status --porcelain)" ]; then
  echo "changed=true" >> "$GITHUB_OUTPUT"
else
  echo "changed=false" >> "$GITHUB_OUTPUT"
  echo "::warning::Claude made no changes for ${TICKET_KEY}."
fi
