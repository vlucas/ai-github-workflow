#!/usr/bin/env bash
#
# Add a comment to a JIRA ticket.
#
# Reads (env):
#   JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
#   TICKET_KEY  - the ticket to comment on
#   COMMENT     - the comment body (plain text)
#
# Best-effort: a failure warns but does not fail the workflow, so a successful
# PR is never lost over a commenting hiccup.
set -uo pipefail

if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
  echo "::warning::JIRA_* secrets not configured; cannot comment on $TICKET_KEY."
  exit 0
fi

if [ -z "${COMMENT:-}" ]; then
  echo "::warning::No comment body provided; skipping JIRA comment on $TICKET_KEY."
  exit 0
fi

# Build the JSON payload with jq so the body is escaped correctly.
PAYLOAD=$(jq -n --arg b "$COMMENT" '{body: $b}')

HTTP=$(curl -sS -w '%{http_code}' -o comment-result.json \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -X POST -H "Accept: application/json" -H "Content-Type: application/json" \
  --data "$PAYLOAD" \
  "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_KEY/comment")

if [ "$HTTP" = "201" ]; then
  echo "Commented on $TICKET_KEY."
else
  echo "::warning::Failed to comment on $TICKET_KEY (HTTP $HTTP)."
  cat comment-result.json || true
fi
rm -f comment-result.json
exit 0
