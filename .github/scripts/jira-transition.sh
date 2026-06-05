#!/usr/bin/env bash
#
# Transition a JIRA ticket to a target status by name.
#
# JIRA transitions are addressed by transition id, not status name, and the
# available transitions depend on the ticket's current status — so we look up the
# transition whose destination matches TARGET_STATUS, then execute it.
#
# Reads (env):
#   JIRA_BASE_URL, JIRA_EMAIL, JIRA_API_TOKEN
#   TICKET_KEY      - the ticket to transition
#   TARGET_STATUS   - destination status name (e.g. "In Progress", "Dev Review")
#
# Best-effort: a transition failure warns but does not fail the workflow, so a
# successful implementation is never lost over a ticket-state hiccup.
set -uo pipefail

if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
  echo "::warning::JIRA_* secrets not configured; cannot move $TICKET_KEY to '$TARGET_STATUS'."
  exit 0
fi

AUTH=(-u "$JIRA_EMAIL:$JIRA_API_TOKEN")
BASE="$JIRA_BASE_URL/rest/api/2/issue/$TICKET_KEY/transitions"

# 1. List the transitions available from the ticket's current status.
HTTP=$(curl -sS -w '%{http_code}' -o transitions.json "${AUTH[@]}" \
  -H "Accept: application/json" "$BASE")

if [ "$HTTP" != "200" ]; then
  echo "::warning::Could not list transitions for $TICKET_KEY (HTTP $HTTP)."
  cat transitions.json || true
  rm -f transitions.json
  exit 0
fi

# 2. Find the transition whose destination status matches TARGET_STATUS
#    (case-insensitively).
TRANSITION_ID=$(jq -r --arg s "$TARGET_STATUS" \
  'first(.transitions[] | select(((.to.name // "") | ascii_downcase) == ($s | ascii_downcase)) | .id) // ""' transitions.json)
rm -f transitions.json

if [ -z "$TRANSITION_ID" ]; then
  echo "::warning::No available transition to '$TARGET_STATUS' for $TICKET_KEY from its current status."
  exit 0
fi

# 3. Execute the transition.
HTTP=$(curl -sS -w '%{http_code}' -o transition-result.json "${AUTH[@]}" \
  -X POST -H "Accept: application/json" -H "Content-Type: application/json" \
  --data "{\"transition\":{\"id\":\"$TRANSITION_ID\"}}" "$BASE")

if [ "$HTTP" = "204" ]; then
  echo "Transitioned $TICKET_KEY to '$TARGET_STATUS'."
else
  echo "::warning::Failed to transition $TICKET_KEY to '$TARGET_STATUS' (HTTP $HTTP)."
  cat transition-result.json || true
fi
rm -f transition-result.json
exit 0
