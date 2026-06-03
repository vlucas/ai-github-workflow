import { createFileRoute } from '@tanstack/react-router'
import { json } from '@tanstack/react-start'
import { db } from '../../db'
import { config } from '../../db/schema'
import { validateInsertConfig } from '../../db/validation'

export const Route = createFileRoute(`/api/config`)({
  server: {
    handlers: {
      GET: async () => {
        try {
          const rows = await db.select().from(config)
          return json(rows)
        } catch (error) {
          console.error(`Error fetching config:`, error)
          return json(
            {
              error: `Failed to fetch config`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
      POST: async ({ request }) => {
        try {
          const body = await request.json()
          const configData = validateInsertConfig(body)
          const [newConfig] = await db
            .insert(config)
            .values(configData)
            .returning()

          return json({ config: newConfig }, { status: 201 })
        } catch (error) {
          console.error(`Error creating config:`, error)
          return json(
            {
              error: `Failed to create config`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
    },
  },
})
