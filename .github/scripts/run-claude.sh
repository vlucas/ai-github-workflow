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
#   USAGE_REPORT  - optional path; a markdown token/cost report is written here
#                   and appended to the job summary
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
Title: ${TICKET_SUMMARY}

Description:
${TICKET_DESCRIPTION}

Use BOTH the title and the description above to understand what needs to be
fixed — the title states the goal and the description provides the detail. If the
description is empty or sparse, rely on the title. Then implement the change,
following the project context and conventions stated above. Keep the change
focused and minimal, and do NOT run git or open a pull request — just edit the
working tree.
EOF
)

# Run the agent with JSON output so we can capture token usage and cost. The
# final result object is the only thing on stdout in this mode.
RESULT_JSON=$(mktemp)
set +e
claude -p "$PROMPT" \
  --output-format json \
  --permission-mode acceptEdits \
  --allowedTools "Edit,Write,Read,Glob,Grep,Bash" \
  --max-turns 40 > "$RESULT_JSON"
CLAUDE_EXIT=$?
set -e

# Echo what the agent reported so it's still visible in the run logs.
if jq -e . "$RESULT_JSON" >/dev/null 2>&1; then
  jq -r '.result // ""' "$RESULT_JSON"

  COST=$(jq -r '.total_cost_usd // 0' "$RESULT_JSON")
  IN=$(jq -r '.usage.input_tokens // 0' "$RESULT_JSON")
  OUT=$(jq -r '.usage.output_tokens // 0' "$RESULT_JSON")
  CACHE_W=$(jq -r '.usage.cache_creation_input_tokens // 0' "$RESULT_JSON")
  CACHE_R=$(jq -r '.usage.cache_read_input_tokens // 0' "$RESULT_JSON")
  TURNS=$(jq -r '.num_turns // 0' "$RESULT_JSON")
  DUR_MS=$(jq -r '.duration_ms // 0' "$RESULT_JSON")

  COST_FMT=$(printf '%.4f' "$COST" 2>/dev/null || echo "$COST")
  TOTAL=$((IN + OUT + CACHE_W + CACHE_R))
  DUR_S=$(awk "BEGIN { printf \"%.1f\", ${DUR_MS}/1000 }" 2>/dev/null || echo "?")

  REPORT=$(cat <<EOF
## Claude Code usage

| Metric | Value |
| --- | --- |
| Total cost (USD) | \$${COST_FMT} |
| Input tokens | ${IN} |
| Output tokens | ${OUT} |
| Cache creation tokens | ${CACHE_W} |
| Cache read tokens | ${CACHE_R} |
| Total tokens | ${TOTAL} |
| Turns | ${TURNS} |
| Duration | ${DUR_S}s |
EOF
)

  echo "$REPORT"
  [ -n "${USAGE_REPORT:-}" ] && printf '%s\n' "$REPORT" > "$USAGE_REPORT"
  [ -n "${GITHUB_STEP_SUMMARY:-}" ] && printf '%s\n' "$REPORT" >> "$GITHUB_STEP_SUMMARY"
else
  echo "::warning::Could not parse Claude result JSON; skipping usage report."
  cat "$RESULT_JSON" || true
fi

rm -f "$RESULT_JSON"

# Preserve the agent's exit status so a failed run still fails the workflow.
exit "$CLAUDE_EXIT"
