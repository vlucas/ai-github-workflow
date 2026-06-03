import { createFileRoute } from '@tanstack/react-router'
import { json } from '@tanstack/react-start'
import { eq } from 'drizzle-orm'
import { db } from '../../db'
import { config } from '../../db/schema'
import { validateUpdateConfig } from '../../db/validation'

export const Route = createFileRoute(`/api/config/$id`)({
  server: {
    handlers: {
      GET: async ({ params }) => {
        try {
          const id = Number(params.id)
          const [row] = await db
            .select()
            .from(config)
            .where(eq(config.id, id))

          if (!row) {
            return json({ error: `Config not found` }, { status: 404 })
          }

          return json(row)
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
      PUT: async ({ params, request }) => {
        try {
          const id = Number(params.id)
          const body = await request.json()
          const configData = validateUpdateConfig(body)

          const [updatedConfig] = await db
            .update(config)
            .set({ ...configData, updated_at: new Date() })
            .where(eq(config.id, id))
            .returning()

          if (!updatedConfig) {
            return json({ error: `Config not found` }, { status: 404 })
          }

          return json({ config: updatedConfig })
        } catch (error) {
          console.error(`Error updating config:`, error)
          return json(
            {
              error: `Failed to update config`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
      DELETE: async ({ params }) => {
        try {
          const id = Number(params.id)
          const [deleted] = await db
            .delete(config)
            .where(eq(config.id, id))
            .returning({ id: config.id })

          if (!deleted) {
            return json({ error: `Config not found` }, { status: 404 })
          }

          return json({ success: true })
        } catch (error) {
          console.error(`Error deleting config:`, error)
          return json(
            {
              error: `Failed to delete config`,
              details: error instanceof Error ? error.message : String(error),
            },
            { status: 500 },
          )
        }
      },
    },
  },
})
