# Project context for the Claude agent

This file is prepended to the prompt on every automated JIRA-to-PR run. Edit it
to give the agent more explicit, durable context and instructions. Keep it
focused — everything here is sent on every call.

## What this project is

A TanStack Start (React 19) "Todo" application backed by SQLite via Drizzle ORM,
using TanStack DB / Query for client-side data. Package manager is **pnpm**.

## Where things live

- `src/routes/` — file-based routes. API routes live under `src/routes/api/`.
- `src/components/` — React components (e.g. `TodoApp.tsx`).
- `src/db/` — Drizzle schema (`schema.ts`), validation (`validation.ts`), and the
  DB client (`index.ts`).
- `src/lib/` — collections, API helpers, and shared utilities.
- `drizzle/` — generated SQL migrations. Do **not** hand-edit these.
- `scripts/migrate.ts` — applies migrations (`pnpm db:push`).

## Conventions

- TypeScript is strict (see `tsconfig.json`): no unused locals, no unchecked
  index access, no implicit returns. Write code that passes `tsc --noEmit`.
- Use the `@/*` path alias for imports from `src` (e.g. `import { db } from "@/db"`).
- Match the style, naming, and patterns of the surrounding files.
- Prefer the existing data-access helpers in `src/lib` and `src/db` over ad-hoc
  queries.

## Database changes

- If you change `src/db/schema.ts`, generate a migration with
  `pnpm db:generate` rather than editing files in `drizzle/` by hand.

## Hard rules

- Keep the change focused and minimal; do not touch unrelated files.
- Do not add dependencies unless the ticket clearly requires it; if you do,
  update `package.json` and let the lockfile be regenerated.
- Do NOT run git commands, commit, push, or open a pull request — the workflow
  handles all git operations. Only edit the working tree.
- Your change must pass typecheck and build. These are verified automatically
  after you finish, so make sure the project still compiles.
