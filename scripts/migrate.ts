import Database from 'better-sqlite3'
import { drizzle } from 'drizzle-orm/better-sqlite3'
import { migrate } from 'drizzle-orm/better-sqlite3/migrator'
import { mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'

const dbPath = resolve(process.env.SQLITE_DB_PATH ?? `./data/todo.db`)

mkdirSync(dirname(dbPath), { recursive: true })

const sqlite = new Database(dbPath)
const db = drizzle(sqlite)

console.log(`Running migrations against ${dbPath}...`)
migrate(db, { migrationsFolder: `./drizzle` })
console.log(`Migrations completed!`)
sqlite.close()
