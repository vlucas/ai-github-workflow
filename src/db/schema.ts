import { integer, sqliteTable, text } from 'drizzle-orm/sqlite-core'

export const todos = sqliteTable(`todos`, {
  id: integer(`id`).primaryKey({ autoIncrement: true }),
  text: text(`text`).notNull(),
  completed: integer(`completed`, { mode: `boolean` }).notNull().default(false),
  created_at: integer(`created_at`, { mode: `timestamp` })
    .notNull()
    .$defaultFn(() => new Date()),
  updated_at: integer(`updated_at`, { mode: `timestamp` })
    .notNull()
    .$defaultFn(() => new Date()),
})

export type Todo = typeof todos.$inferSelect
export type NewTodo = typeof todos.$inferInsert

export const config = sqliteTable(`config`, {
  id: integer(`id`).primaryKey({ autoIncrement: true }),
  key: text(`key`).notNull().unique(),
  value: text(`value`).notNull(),
  created_at: integer(`created_at`, { mode: `timestamp` })
    .notNull()
    .$defaultFn(() => new Date()),
  updated_at: integer(`updated_at`, { mode: `timestamp` })
    .notNull()
    .$defaultFn(() => new Date()),
})

export type Config = typeof config.$inferSelect
export type NewConfig = typeof config.$inferInsert
