#!/usr/bin/env bash
#
# Install Claude Code and run the agent against the ticket description.
# Claude only edits the working tree; the workflow handles git/PR.
#
# Reads (env):
#   ANTHROPIC_API_KEY
#   TICKET_KEY, TICKET_SUMMARY, TICKET_DESCRIPTION
#   CONTEXT_FILE  - optional path to a markdown file prepended to the prompt
#                   (default: .github/claude-context.md)
set -euo pipefail

npm install -g @anthropic-ai/claude-code

# Project context fed to the model before the ticket itself. Edit the markdown
# file to change the standing instructions without touching this script.
CONTEXT_FILE="${CONTEXT_FILE:-.github/claude-context.md}"
CONTEXT=""
if [ -f "$CONTEXT_FILE" ]; then
  echo "Including context from $CONTEXT_FILE"
  CONTEXT=$(cat "$CONTEXT_FILE")
else
  echo "::warning::Context file $CONTEXT_FILE not found; proceeding without it."
fi

PROMPT=$(cat <<EOF
${CONTEXT}

---

You are working in this repository to implement a JIRA ticket.

Ticket: ${TICKET_KEY}
Summary: ${TICKET_SUMMARY}

Description:
${TICKET_DESCRIPTION}

Implement the change described above, following the project context and
conventions stated above. Keep the change focused and minimal, and do NOT run
git or open a pull request — just edit the working tree.
EOF
)

claude -p "$PROMPT" \
  --permission-mode acceptEdits \
  --allowedTools "Edit,Write,Read,Glob,Grep,Bash" \
  --max-turns 40
