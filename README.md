# Todo app

TanStack React DB todo example backed by SQLite.

## Setup

```bash
pnpm install
pnpm db:push
pnpm dev
```

Open http://localhost:5173

The SQLite database file is created at `data/todo.db`.

## Scripts

- `pnpm dev` — start the Vite dev server
- `pnpm db:push` — run database migrations
- `pnpm db:generate` — generate a new migration after schema changes
- `pnpm db:studio` — open Drizzle Studio
- `pnpm build` — production build

## JIRA → Claude → PR automation

`.github/workflows/jira-to-pr.yml` is a webhook-triggered workflow that takes a
JIRA ticket, hands the description to a Claude Code agent to implement, and opens
a pull request with the result.

Trigger it via GitHub's `repository_dispatch` webhook (e.g. from a JIRA automation
rule):

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <GITHUB_TOKEN_WITH_REPO_SCOPE>" \
  https://api.github.com/repos/vlucas/ai-github-workflow/dispatches \
  -d '{"event_type":"jira-ticket","client_payload":{"key":"PROJ-123"}}'
```

If only `key` is provided, the workflow fetches the summary and description from
the JIRA REST API. You can also pass `summary` and `description` directly in the
payload, or run it manually from the Actions tab (`workflow_dispatch`).

Required repository secrets:

- `ANTHROPIC_API_KEY` — Anthropic API key for Claude Code
- `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` — used to read the ticket,
  check its status, and transition it

### Ticket status flow

The workflow keeps the JIRA ticket's status in sync with the work:

1. **Guard** — a run only proceeds if the ticket is currently in
   **Selected for Development**. This is the loop-prevention mechanism: because
   the workflow itself changes the ticket's status, any re-triggered dispatch
   sees a different status and skips instead of looping.
2. **In Progress** — set when implementation begins.
3. **Dev Review** — set once a PR is opened.

The status names are configurable at the top of the workflow
(`REQUIRED_STATUS`, `IN_PROGRESS_STATUS`, `DONE_STATUS`). Status transitions are
best-effort — if JIRA can't be updated the run logs a warning but still produces
the PR. For manual runs you can tick the `force` input to bypass the guard.

### Token usage and cost reporting

The agent runs with Claude Code's JSON output, so each run captures its token
counts (input/output/cache) and dollar cost. The figures are added to the PR
description and the Actions job summary.

### Customising the agent's context

`.github/claude-context.md` is prepended to the prompt on every run. Edit it to
give the agent durable, project-specific context and instructions (conventions,
where things live, hard rules) without touching any scripts.

### Post-work checks

After the agent finishes, `.github/scripts/verify.sh` runs typecheck, lint,
tests, and build. Each check only runs if the project supports it (e.g. lint is
skipped until an ESLint config exists, tests until a `test` script exists), so it
stays correct as the project grows. The results are added to the PR description
and the Actions job summary; if any check fails the PR is still opened (for human
review) but the workflow run is marked failed.

### Maintaining the workflow

Each step's logic lives in its own script under `.github/scripts/`, so they can
be linted and run locally:

| Script | Purpose |
| --- | --- |
| `jira-status.sh` | Loop-prevention guard: proceed only if the ticket is in the required status |
| `resolve-ticket.sh` | Read payload / fetch ticket details from JIRA |
| `jira-transition.sh` | Move the ticket to a target status by name |
| `create-branch.sh` | Create the working branch |
| `run-claude.sh` | Prepend context, run the Claude Code agent, capture token usage and cost |
| `verify.sh` | Run typecheck / lint / tests / build |
| `check-changes.sh` | Detect whether the agent changed anything |
| `commit-and-push.sh` | Commit and push the branch |
| `open-pr.sh` | Open the pull request with the verification report |
