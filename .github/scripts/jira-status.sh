#!/usr/bin/env bash
#
# Loop-prevention guard: only allow work to start when the ticket is currently
# in the required status. Emits proceed=true|false as a step output so the
# implement job can decide whether to run.
#
# This is what stops the workflow from triggering itself in a loop: when we move
# the ticket to "In Progress" / "Dev Review", any re-triggered run sees a status
# other than the required one and skips.
#
# Reads (env):
#   JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
#   TICKET_KEY        - the ticket to inspect
#   REQUIRED_STATUS   - status the ticket must be in (e.g. "Selected for Development")
#   FORCE             - optional "true" to bypass the guard (manual runs)
#   GITHUB_OUTPUT     - provided by GitHub Actions
#
# Always exits 0; the caller acts on the `proceed` output.
set -uo pipefail

emit() { echo "proceed=$1" >> "$GITHUB_OUTPUT"; }

if [ -z "${TICKET_KEY:-}" ]; then
  echo "::error::No JIRA ticket key was provided."
  emit false
  exit 0
fi

if [ "${FORCE:-}" = "true" ]; then
  echo "FORCE set — bypassing the status guard for $TICKET_KEY."
  emit true
  exit 0
fi

if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
  echo "::error::JIRA_* secrets are not configured; cannot check ticket status."
  emit false
  exit 0
fi

HTTP=$(curl -sS -w '%{http_code}' -o status.json \
  -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_KEY?fields=status")

if [ "$HTTP" != "200" ]; then
  echo "::error::JIRA API returned HTTP $HTTP for $TICKET_KEY"
  cat status.json || true
  rm -f status.json
  emit false
  exit 0
fi

CURRENT=$(jq -r '.fields.status.name // ""' status.json)
rm -f status.json

# Compare case-insensitively so "in progress" == "In Progress".
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

echo "Current status of $TICKET_KEY: '$CURRENT' (required: '$REQUIRED_STATUS')"
if [ "$(lower "$CURRENT")" = "$(lower "$REQUIRED_STATUS")" ]; then
  emit true
else
  echo "::notice::Skipping $TICKET_KEY — status '$CURRENT' is not '$REQUIRED_STATUS'."
  emit false
fi
