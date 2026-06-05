#!/usr/bin/env bash
#
# Open a pull request for the implemented ticket.
#
# Reads (env):
#   GH_TOKEN                         - auth for the gh CLI
#   BRANCH, GITHUB_REF_NAME          - head and base branches
#   TICKET_KEY, TICKET_SUMMARY, TICKET_DESCRIPTION
#   JIRA_BASE_URL                    - optional, used to link back to the ticket
#   VERIFY_REPORT                    - optional path to the verification report
#   VERIFY_PASSED                    - optional "true"/"false" check result
#   USAGE_REPORT                     - optional path to the token/cost report
set -euo pipefail

JIRA_LINK=""
if [ -n "${JIRA_BASE_URL:-}" ]; then
  JIRA_LINK="**JIRA:** ${JIRA_BASE_URL}/browse/${TICKET_KEY}"$'\n\n'
fi

# Headline status from the post-work checks, if available.
STATUS_LINE=""
case "${VERIFY_PASSED:-}" in
  true)  STATUS_LINE="**Checks:** ✅ passed"$'\n\n' ;;
  false) STATUS_LINE="**Checks:** ❌ failed — review the report below before merging"$'\n\n' ;;
esac

# Full verification report, if the verify step produced one.
VERIFY_SECTION=""
if [ -n "${VERIFY_REPORT:-}" ] && [ -f "$VERIFY_REPORT" ]; then
  VERIFY_SECTION=$'\n\n---\n\n'"$(cat "$VERIFY_REPORT")"
fi

# Token usage and cost report, if the agent step produced one.
USAGE_SECTION=""
if [ -n "${USAGE_REPORT:-}" ] && [ -f "$USAGE_REPORT" ]; then
  USAGE_SECTION=$'\n\n---\n\n'"$(cat "$USAGE_REPORT")"
fi

BODY="${JIRA_LINK}${STATUS_LINE}Automated implementation of **${TICKET_KEY}** by Claude Code.

## Ticket
${TICKET_DESCRIPTION}${VERIFY_SECTION}${USAGE_SECTION}

---
🤖 Generated from a JIRA webhook. Please review before merging."

gh pr create \
  --base "${GITHUB_REF_NAME}" \
  --head "$BRANCH" \
  --title "${TICKET_KEY}: ${TICKET_SUMMARY}" \
  --body "$BODY"
