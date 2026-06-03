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
