#!/usr/bin/env bash
#
# Resolve JIRA ticket details and emit them as step outputs.
#
# Reads (env):
#   INPUT_KEY, INPUT_SUMMARY, INPUT_DESCRIPTION  - values from the trigger
#   JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN    - used only when fetching from JIRA
#   GITHUB_OUTPUT, GITHUB_RUN_ID                 - provided by GitHub Actions
#
# Writes (step outputs): key, summary, description, branch
set -euo pipefail

KEY="${INPUT_KEY:-}"
if [ -z "$KEY" ]; then
  echo "::error::No JIRA ticket key was provided."
  exit 1
fi

SUMMARY="${INPUT_SUMMARY:-}"
DESCRIPTION="${INPUT_DESCRIPTION:-}"

# Fetch from JIRA only when summary or description is missing.
if [ -z "$SUMMARY" ] || [ -z "$DESCRIPTION" ]; then
  if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
    echo "::error::summary/description missing and JIRA_* secrets are not configured."
    exit 1
  fi

  echo "Fetching $KEY from JIRA..."
  # API v2 returns description as plain wiki-markup text (simpler than ADF v3).
  HTTP=$(curl -sS -w '%{http_code}' -o issue.json \
    -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    -H "Accept: application/json" \
    "$JIRA_BASE_URL/rest/api/2/issue/$KEY?fields=summary,description")

  if [ "$HTTP" != "200" ]; then
    echo "::error::JIRA API returned HTTP $HTTP for $KEY"
    cat issue.json || true
    exit 1
  fi

  [ -z "$SUMMARY" ] && SUMMARY=$(jq -r '.fields.summary // ""' issue.json)
  [ -z "$DESCRIPTION" ] && DESCRIPTION=$(jq -r '.fields.description // ""' issue.json)
  rm -f issue.json
fi

if [ -z "$DESCRIPTION" ]; then
  echo "::error::Ticket $KEY has no description to work from."
  exit 1
fi

# Slugged branch name, unique per run.
SLUG=$(printf '%s' "$KEY" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/-\+/-/g; s/^-//; s/-$//')
BRANCH="jira/${SLUG}-${GITHUB_RUN_ID}"

{
  echo "key=$KEY"
  echo "summary=$SUMMARY"
  echo "branch=$BRANCH"
} >> "$GITHUB_OUTPUT"

# Multiline values via heredoc delimiters.
{
  echo "description<<__JIRA_EOF__"
  echo "$DESCRIPTION"
  echo "__JIRA_EOF__"
} >> "$GITHUB_OUTPUT"
